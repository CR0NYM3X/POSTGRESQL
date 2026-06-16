# Laboratorio de Referencia — Clúster PostgreSQL 16 de Alta Disponibilidad
## Patroni + etcd + HAProxy/Keepalived + pgBackRest
### Manual de implementación para entornos críticos financieros

**Versión del documento:** 1.0
**Audiencia:** Equipos de DBA, SRE e Infraestructura
**Alcance:** Diseño, despliegue, configuración y operación de un clúster PostgreSQL de 5 nodos con 2 réplicas síncronas (lectura balanceada) y 2 réplicas asíncronas dedicadas (backup/reporting), gobernado por Patroni sobre un clúster etcd de 3 nodos aislado.

---

## 0. Resumen ejecutivo

Este documento describe, nodo por nodo y parámetro por parámetro, un laboratorio que reproduce un entorno productivo crítico (sector financiero) compuesto por:

- **1 clúster etcd de 3 nodos** (quórum impar, tolera 1 caída) que actúa como **DCS** (Distributed Configuration Store) — el "cerebro" que Patroni usa para elección de líder, locks distribuidos y propagación de configuración.
- **1 clúster PostgreSQL de 5 nodos** gestionado por **Patroni**:
  - 1 **Primary** (maestro, lectura/escritura).
  - 2 **Réplicas síncronas** (quorum commit) — garantizan **RPO≈0** y son candidatas a failover automático. Entran al balanceador de **solo lectura**.
  - 2 **Réplicas asíncronas** — dedicadas a **backups (pgBackRest)**, **reporting/BI** y **auditoría**. Quedan **excluidas** del pool de lectura aplicativo porque pueden desfasarse (replication lag) y **no participan en elecciones de failover**.
- **2 balanceadores HAProxy + Keepalived (VIP)** en alta disponibilidad, con *health checks* contra la **REST API de Patroni** (no contra PostgreSQL directamente), separando el tráfico de escritura (al primary) del tráfico de lectura (a las síncronas).
- **pgBackRest** como motor de backups físicos/incrementales/diferenciales con repositorio en un nodo dedicado (o storage S3-compatible).

Esta arquitectura sigue el patrón documentado oficialmente por Patroni y es el mismo patrón usado en bancos y fintechs: DCS aislado en hardware/VMs separadas de PostgreSQL, quórum impar en etcd, `synchronous_mode` con quorum commit en Postgres 16, y balanceo de lectura basado en *tags* (`noloadbalance`) para excluir nodos no aptos.

> **Nota de alcance.** Este manual es una *plantilla de referencia* con IPs, hostnames y rangos de ejemplo (RFC1918, documentados explícitamente como tales). Antes de llevarlo a producción financiera real se debe: (1) sustituir IPs/hostnames por los del entorno real, (2) pasar por el comité de seguridad/cumplimiento (PCI-DSS / ISO 27001 / regulación local), (3) validar con un *pentest* y un *DR drill* documentado, y (4) ajustar capacidades (CPU/RAM/IOPS) según *benchmark* real de carga (pgbench / carga aplicativa).

---

## 1. Arquitectura general

### 1.1 Diagrama lógico

```
                                 ┌──────────────────────────┐
                                 │   Aplicaciones / Clientes │
                                 └────────────┬──────────────┘
                                              │
                       ┌──────────────────────┴───────────────────────┐
                       │                                                │
              VIP Escritura 10.10.30.10                       VIP Lectura 10.10.30.11
              (puerto 5000 -> primary)                        (puerto 5001 -> sync replicas)
                       │                                                │
        ┌──────────────┴───────────────┐                ┌───────────────┴──────────────┐
        │   lb01 (HAProxy+Keepalived)   │                │   lb02 (HAProxy+Keepalived)   │
        │        10.10.30.21            │◄──VRRP (peer)─►│        10.10.30.22            │
        └──────────────┬────────────────┘                └───────────────┬───────────────┘
                       │  health-check REST API Patroni (puerto 8008)     │
        ┌──────────────┼────────────────────────────────────────────────┼───────────────┐
        │              │                                                  │               │
        ▼              ▼                                                  ▼               ▼
   ┌─────────┐   ┌─────────┐                                        ┌─────────┐    ┌─────────┐
   │ pg-pri01│   │ pg-syn01│                                        │ pg-syn02│    │         │
   │ PRIMARY │   │ SYNC #1 │                                        │ SYNC #2 │    │         │
   │10.10.10.│   │10.10.10.│                                        │10.10.10.│    │         │
   │   11    │   │   12    │                                        │   13    │    │         │
   └────┬────┘   └────┬────┘                                        └────┬────┘    └─────────┘
        │  WAL streaming (sync, quorum=1 de 2)                            │
        │◄─────────────────────────────────────────────────────────────►│
        │
        │  WAL streaming (async, best-effort)
        ├───────────────────────────────┐
        ▼                                ▼
   ┌─────────┐                     ┌─────────┐
   │ pg-asy01│                     │ pg-asy02│
   │ ASYNC#1 │                     │ ASYNC#2 │
   │ Backup/ │                     │Reporting│
   │ pgBackR.│                     │   /BI   │
   │10.10.10.│                     │10.10.10.│
   │   14    │                     │   15    │
   └─────────┘                     └─────────┘

        Plano de control (DCS) — RED AISLADA 10.10.20.0/24
   ┌─────────┐        ┌─────────┐        ┌─────────┐
   │ etcd01  │◄──────►│ etcd02  │◄──────►│ etcd03  │
   │10.10.20.│        │10.10.20.│        │10.10.20.│
   │   11    │        │   12    │        │   13    │
   └─────────┘        └─────────┘        └─────────┘
   Todos los pg-* y lb-* hablan con los 3 etcd por el puerto 2379 (cliente)
   etcd habla entre sí por el puerto 2380 (peer)
```

### 1.2 Principios de diseño aplicados

| Principio | Cómo se aplica en este laboratorio |
|---|---|
| **Aislamiento del DCS** | etcd corre en 3 VMs propias, sin colocar (co-locar) con PostgreSQL. Si un nodo Postgres muere, etcd no se ve afectado, y viceversa. Esto evita el escenario de incidente real documentado: *"un clúster Patroni donde el DCS era un único nodo etcd que cayó junto con el primary"*. |
| **Quórum impar** | 3 nodos etcd tolera la caída de 1 sin perder quórum (2/3). Nunca usar un número par de nodos etcd (riesgo de *split-brain* en partición de red). |
| **Separación síncrono/asíncrono** | Las réplicas síncronas garantizan cero pérdida de transacciones confirmadas (RPO≈0) y son las únicas candidatas a promoción automática. Las asíncronas existen para aislar cargas pesadas (backup full, reportes, ETL) que no deben competir por recursos con el tráfico transaccional ni arriesgar la latencia de commit del primary. |
| **Quorum commit (Postgres ≥10)** | En vez de síncrona estricta a un nodo fijo, se usa `synchronous_mode` con `synchronous_node_count: 1` sobre el conjunto `{pg-syn01, pg-syn02}`: el primary espera confirmación de **al menos 1 de las 2** síncronas. Esto reduce la latencia de cola (peor caso) frente a fijar siempre el mismo nodo, y sigue tolerando la caída de una síncrona sin bloquear escrituras. |
| **Balanceo basado en rol y tags, no en IP fija** | El balanceador nunca apunta a una IP de Postgres fija como "el primary"; consulta la REST API de Patroni (`/primary`, `/replica`, `/sync`) en cada nodo. Los nodos asíncronos llevan `tags: {noloadbalance: true}` para quedar excluidos del pool de lectura aplicativo aun si alguien los agrega por error al backend de HAProxy. |
| **VIP en capa de balanceo, no en capa de datos** | La IP virtual (VIP) vive en HAProxy/Keepalived, no en PostgreSQL. Patroni puede opcionalmente gestionar una VIP por nodo, pero en este diseño se delega 100% al par HAProxy+Keepalived para separar responsabilidades. |
| **pg_rewind habilitado** | Permite reincorporar automáticamente un primary caído como réplica tras divergencia de timeline, sin necesidad de re-clonar el nodo completo (`pg_basebackup`), reduciendo el MTTR. |
| **Backups fuera de la ruta crítica** | pgBackRest corre contra `pg-asy01` (réplica asíncrona dedicada), nunca contra el primary ni las síncronas, para no impactar la latencia transaccional con I/O de backup. |

---

## 2. Inventario de infraestructura (VMs, IPs, hostnames)

### 2.1 Convenciones

- Todas las IPs son del rango privado **RFC1918** y son **ilustrativas**; en el despliegue real se deben sustituir por las asignadas por el equipo de Networking/IPAM de la organización.
- Se utilizan **3 segmentos de red** separados (idealmente 3 VLANs distintas con ACLs entre ellas):
  - `10.10.10.0/24` → **Red de datos PostgreSQL** (clientes, streaming replication).
  - `10.10.20.0/24` → **Red del DCS (etcd)** — aislada, solo hablan con ella los nodos pg-* (cliente etcd) y lb-* (consulta opcional) y los propios etcd entre sí.
  - `10.10.30.0/24` → **Red de balanceo / front-end aplicativo** — es la única red que las aplicaciones deben poder alcanzar.
- DNS interno recomendado (zona `pg.bancoejemplo.local`, sustituir por dominio real) para no depender de IPs hardcodeadas en cadenas de conexión.

### 2.2 Tabla maestra de nodos

| Hostname | Rol | IP (red datos) | IP (red DCS) | IP (red balanceo) | vCPU | RAM | Disco datos | Disco WAL/log | OS |
|---|---|---|---|---|---|---|---|---|---|
| `etcd01` | DCS — nodo 1 | — | 10.10.20.11 | — | 2 | 4 GB | 40 GB SSD | — | Ubuntu 22.04 LTS |
| `etcd02` | DCS — nodo 2 | — | 10.10.20.12 | — | 2 | 4 GB | 40 GB SSD | — | Ubuntu 22.04 LTS |
| `etcd03` | DCS — nodo 3 | — | 10.10.20.13 | — | 2 | 4 GB | 40 GB SSD | — | Ubuntu 22.04 LTS |
| `pg-pri01` | PostgreSQL **PRIMARY** | 10.10.10.11 | 10.10.20.21 (cliente etcd) | — | 8 | 32 GB | 500 GB NVMe (RAID10) | 100 GB NVMe dedicado | Ubuntu 22.04 LTS |
| `pg-syn01` | Réplica **SÍNCRONA #1** (lectura) | 10.10.10.12 | 10.10.20.22 (cliente etcd) | — | 8 | 32 GB | 500 GB NVMe (RAID10) | 100 GB NVMe dedicado | Ubuntu 22.04 LTS |
| `pg-syn02` | Réplica **SÍNCRONA #2** (lectura) | 10.10.10.13 | 10.10.20.23 (cliente etcd) | — | 8 | 32 GB | 500 GB NVMe (RAID10) | 100 GB NVMe dedicado | Ubuntu 22.04 LTS |
| `pg-asy01` | Réplica **ASÍNCRONA #1** (Backups) | 10.10.10.14 | 10.10.20.24 (cliente etcd) | — | 4 | 16 GB | 1 TB SATA/SSD | 50 GB | Ubuntu 22.04 LTS |
| `pg-asy02` | Réplica **ASÍNCRONA #2** (Reporting/BI) | 10.10.10.15 | 10.10.20.25 (cliente etcd) | — | 8 | 32 GB | 500 GB SSD | 50 GB | Ubuntu 22.04 LTS |
| `lb01` | HAProxy + Keepalived (MASTER VRRP) | 10.10.10.21 | — | 10.10.30.21 | 2 | 4 GB | 20 GB | — | Ubuntu 22.04 LTS |
| `lb02` | HAProxy + Keepalived (BACKUP VRRP) | 10.10.10.22 | — | 10.10.30.22 | 2 | 4 GB | 20 GB | — | Ubuntu 22.04 LTS |

> **Nota:** los nodos `pg-*` tienen interfaz en la red de datos (10.10.10.0/24, donde escuchan PostgreSQL/Patroni y por donde fluye el streaming replication) **y** una segunda interfaz en la red DCS (10.10.20.0/24) por la cual actúan como *clientes* de etcd. Esto es clave: **los nodos Postgres NUNCA deben estar en la misma VLAN de gestión del etcd como peers**, solo como clientes del puerto 2379.

### 2.3 IPs virtuales (VIP) de servicio

| VIP | Puerto | Apunta a | Uso |
|---|---|---|---|
| `10.10.30.10` | `5000` | Nodo con rol **primary** (vía Patroni REST `/primary`) | Cadena de conexión de **escritura** de la aplicación (`host=10.10.30.10 port=5000`) |
| `10.10.30.11` | `5001` | Nodos con rol **réplica síncrona y con `noloadbalance:false`** (vía Patroni REST `/read-only-sync` o `/replica`) | Cadena de conexión de **solo lectura** balanceada de la aplicación (`host=10.10.30.11 port=5001`) |

> Las réplicas asíncronas (`pg-asy01`, `pg-asy02`) **no tienen entrada** en ninguna VIP aplicativa. Se acceden de forma **directa y explícita** por su IP/hostname (`pg-asy01.pg.bancoejemplo.local:5432`, `pg-asy02.pg.bancoejemplo.local:5432`) solo desde las herramientas autorizadas (pgBackRest, motor de BI), nunca desde el pool genérico de la aplicación transaccional.

### 2.4 Puertos utilizados (referencia para firewall)

| Puerto | Protocolo | Servicio | Origen permitido | Destino |
|---|---|---|---|---|
| `5432` | TCP | PostgreSQL (datos/streaming) | `pg-*` (todos, para replicación), `lb01`/`lb02` (para proxy), DBAs (bastión) | `pg-*` |
| `8008` | TCP | Patroni REST API | `lb01`, `lb02`, `pg-*` (entre sí), monitoreo | `pg-*` |
| `2379` | TCP | etcd — API cliente | `pg-*`, `lb01`/`lb02` (opcional, solo lectura de estado) | `etcd-*` |
| `2380` | TCP | etcd — comunicación *peer* (Raft) | `etcd-*` (solo entre los 3 nodos etcd) | `etcd-*` |
| `5000` | TCP | HAProxy frontend escritura | Aplicaciones | `lb01`/`lb02` (VIP) |
| `5001` | TCP | HAProxy frontend lectura | Aplicaciones | `lb01`/`lb02` (VIP) |
| `7000` | TCP | HAProxy stats/admin (interno) | Red de management/monitoreo | `lb01`/`lb02` |
| `112` | VRRP (IP protocol) | Keepalived VRRP | `lb01` ↔ `lb02` únicamente | — |
| `22` | TCP | SSH administrativo | Subred de bastión/jump-host **únicamente** | Todos |
| `9187` | TCP | postgres_exporter (Prometheus) | Servidor de monitoreo | `pg-*` |
| `9100` | TCP | node_exporter (Prometheus) | Servidor de monitoreo | Todos |

---

## 3. Diseño de red y reglas de firewall

### 3.1 Segmentación (mínimo viable para entorno financiero)

1. **VLAN/Subred APP** (`10.10.30.0/24`): donde viven las VIP de HAProxy. Es la **única** subred alcanzable desde la red de aplicaciones/microservicios.
2. **VLAN/Subred DATA** (`10.10.10.0/24`): donde viven los 5 nodos PostgreSQL y los balanceadores (segunda interfaz). Solo deben llegar aquí: los propios nodos pg-* (replicación), los balanceadores (proxy), y el bastión de DBAs.
3. **VLAN/Subred DCS** (`10.10.20.0/24`): donde viven los 3 etcd. Solo deben llegar aquí: los 5 nodos pg-* (como clientes etcd, puerto 2379) y los propios etcd entre sí (puerto 2380). **Las aplicaciones y balanceadores NO deben tener ruta a esta subred.**
4. **VLAN/Subred MGMT** (ej. `10.10.40.0/24`, bastión): origen permitido para SSH (22) hacia todas las demás, y para scraping de Prometheus (9100/9187/8008-stats).

### 3.2 Matriz de reglas de firewall (iptables/nftables o Security Groups)

> Aplicar el principio de **menor privilegio**: todo lo no listado se deniega por defecto (`DROP`/`DENY` por defecto, *whitelist* explícita).

**En cada nodo `etcd0{1,2,3}` (10.10.20.0/24):**

```
# Permitir cliente etcd (2379) SOLO desde nodos PostgreSQL
-A INPUT -p tcp -s 10.10.10.0/24 --dport 2379 -j ACCEPT
# Permitir peer etcd (2380) SOLO entre los 3 nodos etcd
-A INPUT -p tcp -s 10.10.20.11 --dport 2380 -j ACCEPT
-A INPUT -p tcp -s 10.10.20.12 --dport 2380 -j ACCEPT
-A INPUT -p tcp -s 10.10.20.13 --dport 2380 -j ACCEPT
# SSH solo desde bastión de administración
-A INPUT -p tcp -s 10.10.40.0/24 --dport 22 -j ACCEPT
# Métricas (node_exporter) solo desde servidor de monitoreo
-A INPUT -p tcp -s 10.10.40.5 --dport 9100 -j ACCEPT
# Resto: DROP
-A INPUT -j DROP
```

**En cada nodo `pg-*` (10.10.10.0/24):**

```
# Replicación + conexiones cliente PostgreSQL: desde otros pg-* (replicación)
-A INPUT -p tcp -s 10.10.10.0/24 --dport 5432 -j ACCEPT
# Conexiones cliente desde balanceadores (proxy hacia primary/sync)
-A INPUT -p tcp -s 10.10.10.21 --dport 5432 -j ACCEPT
-A INPUT -p tcp -s 10.10.10.22 --dport 5432 -j ACCEPT
# Conexión directa autorizada SOLO a nodos asíncronos desde herramientas de backup/BI
# (regla específica solo en pg-asy01/pg-asy02, ver nota abajo)
# REST API de Patroni: entre nodos pg-* (para el "watchdog" cruzado) y desde balanceadores
-A INPUT -p tcp -s 10.10.10.0/24 --dport 8008 -j ACCEPT
-A INPUT -p tcp -s 10.10.10.21 --dport 8008 -j ACCEPT
-A INPUT -p tcp -s 10.10.10.22 --dport 8008 -j ACCEPT
# Cliente etcd: SALIDA hacia 10.10.20.0/24 puerto 2379 (regla de OUTPUT/egress)
-A OUTPUT -p tcp -d 10.10.20.0/24 --dport 2379 -j ACCEPT
# SSH solo desde bastión
-A INPUT -p tcp -s 10.10.40.0/24 --dport 22 -j ACCEPT
# Métricas
-A INPUT -p tcp -s 10.10.40.5 --dport 9100 -j ACCEPT
-A INPUT -p tcp -s 10.10.40.5 --dport 9187 -j ACCEPT
-A INPUT -j DROP
```

> **Regla adicional solo en `pg-asy01`:** permitir conexión PostgreSQL (5432) desde el servidor de respaldos (si pgBackRest corre en una VM separada) o, si pgBackRest corre localmente en `pg-asy01`, no se requiere regla extra de red (conexión local vía socket Unix).
> **Regla adicional solo en `pg-asy02`:** permitir conexión PostgreSQL (5432) desde la subred del motor de BI/Reporting (ej. `10.10.50.0/24`), **nunca** desde la subred de aplicaciones transaccionales (`10.10.30.0/24`).

**En cada balanceador `lb01`/`lb02`:**

```
# Frontend escritura/lectura: SOLO desde subred de aplicaciones
-A INPUT -p tcp -s 10.10.30.0/24 --dport 5000 -j ACCEPT
-A INPUT -p tcp -s 10.10.30.0/24 --dport 5001 -j ACCEPT
# VRRP entre los dos balanceadores únicamente
-A INPUT -p vrrp -s 10.10.10.21 -j ACCEPT
-A INPUT -p vrrp -s 10.10.10.22 -j ACCEPT
# Stats de HAProxy solo desde monitoreo
-A INPUT -p tcp -s 10.10.40.5 --dport 7000 -j ACCEPT
-A INPUT -p tcp -s 10.10.40.0/24 --dport 22 -j ACCEPT
-A INPUT -j DROP
```

### 3.3 Reglas explícitamente prohibidas (controles de cumplimiento)

- **Prohibido** exponer el puerto `5432` directamente a la subred de aplicaciones (`10.10.30.0/24`); las apps **solo** hablan con las VIP (5000/5001) en HAProxy.
- **Prohibido** que la subred de aplicaciones (`10.10.30.0/24`) tenga ruta hacia la subred DCS (`10.10.20.0/24`).
- **Prohibido** habilitar autenticación `trust` en `pg_hba.conf` para cualquier origen distinto de `127.0.0.1/32` y `::1/128` (uso interno de extensiones/herramientas locales bien controladas). Todo lo demás debe usar `scram-sha-256`.
- **Prohibido** usar el usuario `postgres` (superusuario) como usuario aplicativo. Las aplicaciones deben conectar con un rol de mínimo privilegio (ver sección 7).

---

## 4. Clúster etcd (DCS) — 3 nodos aislados

### 4.1 Por qué 3 nodos y por qué aislados

- **Quórum impar:** con 3 nodos, el clúster etcd tolera la pérdida de **1** nodo y sigue operando (2 de 3 = quórum). Con 5 nodos toleraría 2, pero para este laboratorio (acorde a lo solicitado) se usan 3, que es el mínimo recomendado en cualquier guía de producción de Patroni/etcd.
- **Aislamiento físico/lógico:** etcd es extremadamente sensible a la latencia de disco (usa `fsync` en cada escritura de su WAL Raft) y a la latencia de red entre sus miembros. Si comparte hardware con PostgreSQL, un pico de I/O de Postgres puede degradar a etcd, lo que a su vez puede disparar *falsos failovers* en todo el clúster Postgres. Por eso se exige que estas 3 VMs sean independientes, idealmente en **hosts físicos distintos** y, si es posible, en **3 zonas de disponibilidad (AZ) distintas**.
- Es el mismo patrón que documenta la comunidad: *"para producción, ejecutar al menos tres nodos de consenso en infraestructura separada para evitar fallas correlacionadas"*Etcd, Consul, or ZooKeeper maintain the cluster state, manage leader locks, and distribute configuration. For production, run at least three consensus nodes on separate infrastructure to avoid correlated failures.

### 4.2 Versión recomendada

- **etcd v3.5.x** (última release estable de la serie 3.5 al momento de implementar; verificar siempre la página oficial de releases de `etcd-io/etcd` antes de fijar versión exacta en producción).
- Protocolo de API: **v3** (obligatorio; Patroni requiere la API v3, no v2).

### 4.3 Instalación (los 3 nodos: `etcd01`, `etcd02`, `etcd03`)

```bash
# Ejecutar en CADA uno de los 3 nodos etcd
ETCD_VER=v3.5.17   # Verificar última versión estable 3.5.x antes de fijar
DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download

cd /tmp
curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o etcd.tar.gz
tar xzvf etcd.tar.gz
sudo mv etcd-${ETCD_VER}-linux-amd64/etcd /usr/local/bin/
sudo mv etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/
sudo mv etcd-${ETCD_VER}-linux-amd64/etcdutl /usr/local/bin/

sudo mkdir -p /var/lib/etcd        # Directorio de datos (debe estar en disco rápido/SSD dedicado)
sudo mkdir -p /etc/etcd
sudo useradd --system --home /var/lib/etcd --shell /bin/false etcd
sudo chown -R etcd:etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd        # Permisos restrictivos: solo el usuario etcd puede leer su propio WAL
```

### 4.4 Archivo de configuración `/etc/etcd/etcd.conf.yml`

A continuación, la configuración para **`etcd01`** (10.10.20.11). Para `etcd02`/`etcd03` se cambian únicamente `name`, las IPs de `listen-*` y `initial-advertise/advertise-client-urls` por las propias de cada nodo; `initial-cluster` es **idéntico en los 3** nodos.

```yaml
# /etc/etcd/etcd.conf.yml  (nodo etcd01 - 10.10.20.11)

name: 'etcd01'                                   # Nombre único del miembro dentro del clúster Raft
data-dir: '/var/lib/etcd'                        # Directorio donde etcd guarda su WAL y snapshots. DEBE estar en disco SSD/NVMe dedicado.

# --- Direcciones de escucha (qué interfaces acepta conexiones) ---
listen-peer-urls: 'https://10.10.20.11:2380'      # Interfaz por la que este nodo escucha tráfico Raft de los OTROS etcd
listen-client-urls: 'https://10.10.20.11:2379,https://127.0.0.1:2379'  # Interfaz por la que escucha a los CLIENTES (nodos pg-*)

# --- Direcciones anunciadas (qué dirección comunica a los demás para que lo contacten) ---
initial-advertise-peer-urls: 'https://10.10.20.11:2380'  # Dirección que este nodo anuncia a sus peers para comunicación Raft
advertise-client-urls: 'https://10.10.20.11:2379'         # Dirección que este nodo anuncia a los clientes (debe ser alcanzable desde la red DATA)

# --- Bootstrap del clúster (idéntico en los 3 nodos en el arranque inicial) ---
initial-cluster: 'etcd01=https://10.10.20.11:2380,etcd02=https://10.10.20.12:2380,etcd03=https://10.10.20.13:2380'
initial-cluster-token: 'etcd-cluster-pgha-prod'   # Token único del clúster; evita que dos clústeres etcd distintos se mezclen si comparten red
initial-cluster-state: 'new'                      # 'new' SOLO en el bootstrap inicial. Para añadir un miembro a un clúster ya existente, usar 'existing'

# --- Seguridad de transporte: TLS mutuo (mTLS) obligatorio en entorno financiero ---
client-transport-security:
  cert-file: '/etc/etcd/pki/etcd01-client.crt'
  key-file: '/etc/etcd/pki/etcd01-client.key'
  client-cert-auth: true                          # Exige certificado válido también a los CLIENTES (mTLS), no solo cifrado
  trusted-ca-file: '/etc/etcd/pki/ca.crt'
  auto-tls: false                                  # NUNCA usar autotls en producción: los certificados deben ser emitidos por la CA interna

peer-transport-security:
  cert-file: '/etc/etcd/pki/etcd01-peer.crt'
  key-file: '/etc/etcd/pki/etcd01-peer.key'
  peer-client-cert-auth: true                      # Exige mTLS también entre los propios nodos etcd (Raft)
  trusted-ca-file: '/etc/etcd/pki/ca.crt'
  auto-tls: false

# --- Parámetros de rendimiento y consistencia (tuning de producción) ---
heartbeat-interval: 100                            # ms entre heartbeats Raft del líder a sus seguidores. 100ms es el valor recomendado para LAN de baja latencia (<1ms RTT entre nodos)
election-timeout: 1000                              # ms antes de que un seguidor inicie una nueva elección si no oye al líder. Regla etcd: election-timeout >= 5 * heartbeat-interval
quota-backend-bytes: 8589934592                     # 8 GiB - límite de tamaño de la base de datos backend (bbolt). Evita crecimiento descontrolado del DCS
auto-compaction-mode: 'periodic'                    # Compacta automáticamente el historial de revisiones (evita que el WAL crezca indefinidamente)
auto-compaction-retention: '1h'                      # Conserva 1 hora de historial antes de compactar; suficiente para Patroni, que no necesita histórico largo
snapshot-count: 10000                                # Cada 10000 escrituras Raft, fuerza un snapshot (acelera el arranque de nodos que se reincorporan)

# --- Logging ---
log-level: 'info'                                    # info en producción; 'debug' solo temporalmente para troubleshooting
logger: 'zap'
log-outputs: ['/var/log/etcd/etcd.log']

# --- Métricas (para Prometheus) ---
metrics: 'extensive'                                 # Expone métricas detalladas en :2379/metrics para el exporter de Prometheus

# --- Identificación del miembro (anti split-brain en reemplazo de nodos) ---
strict-reconfig-check: true                          # Rechaza cambios de configuración que dejarían al clúster sin quórum válido
enable-v2: false                                      # Deshabilita la API v2 obsoleta; Patroni usa exclusivamente v3
```

> **Sobre TLS/mTLS:** en un entorno financiero real, **mTLS entre etcd y sus clientes/peers es obligatorio**, no opcional. La PKI interna del banco debe emitir certificados para cada nodo (`etcd0{1,2,3}-peer`, `etcd0{1,2,3}-client`) firmados por una CA interna (`ca.crt`), con rotación periódica (ej. cada 90 días) gestionada por Vault/cert-manager o el sistema de gestión de secretos corporativo. Este manual asume que ya existe esa PKI; el detalle de su emisión está fuera de alcance, pero **no se debe desplegar en producción sin ella**.

### 4.5 Unit de systemd `/etc/systemd/system/etcd.service`

```ini
[Unit]
Description=etcd distributed key-value store
Documentation=https://etcd.io/docs/
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=etcd
Group=etcd
ExecStart=/usr/local/bin/etcd --config-file /etc/etcd/etcd.conf.yml
Restart=on-failure                     # Reinicia automáticamente solo ante fallo del proceso, no ante stop manual
RestartSec=5
LimitNOFILE=65536                      # etcd puede mantener muchas conexiones/file descriptors abiertos bajo carga
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now etcd
```

### 4.6 Verificación del clúster etcd

```bash
# Ejecutar desde cualquiera de los 3 nodos etcd, una vez los 3 servicios están arriba
export ETCDCTL_API=3
etcdctl --endpoints=https://10.10.20.11:2379,https://10.10.20.12:2379,https://10.10.20.13:2379 \
  --cacert=/etc/etcd/pki/ca.crt --cert=/etc/etcd/pki/etcd01-client.crt --key=/etc/etcd/pki/etcd01-client.key \
  endpoint health --cluster
# Salida esperada: los 3 endpoints deben responder "is healthy"

etcdctl --endpoints=https://10.10.20.11:2379,https://10.10.20.12:2379,https://10.10.20.13:2379 \
  --cacert=/etc/etcd/pki/ca.crt --cert=/etc/etcd/pki/etcd01-client.crt --key=/etc/etcd/pki/etcd01-client.key \
  member list -w table
# Debe listar etcd01, etcd02, etcd03, con isLeader=true en exactamente UNO de ellos
```

### 4.7 Checklist de aceptación del DCS antes de continuar

- [ ] Los 3 nodos responden `healthy` en `endpoint health --cluster`.
- [ ] Existe exactamente 1 líder Raft (`member list` muestra `isLeader=true` en solo un nodo).
- [ ] mTLS validado: una conexión sin certificado de cliente válido es rechazada.
- [ ] `systemctl status etcd` con `enabled` (arranque automático tras reboot) en los 3 nodos.
- [ ] Latencia de red entre los 3 nodos etcd verificada (`ping`/`hping3`) y **menor a 5 ms** RTT (idealmente mismo datacenter/AZs cercanas; latencias altas degradan `heartbeat-interval`/`election-timeout` y disparan elecciones espurias).
- [ ] Backup del directorio `/var/lib/etcd` (snapshot) incluido en el plan de respaldos de infraestructura (no es lo mismo que el backup de PostgreSQL, pero su pérdida total deja a Patroni sin DCS).
## 5. PostgreSQL 16 + Patroni en los 5 nodos

### 5.1 Versión y paquetes

- **PostgreSQL 16.x** (última minor estable de la rama 16 al momento del despliegue — verificar en `postgresql.org/support/versioning` antes de fijar la versión exacta).
- **Patroni 4.1.x** (requiere Python ≥3.8 y el conector `psycopg2` o `psycopg` v3).
- Repositorio oficial **PGDG** (PostgreSQL Global Development Group), no el paquete genérico de Ubuntu (que suele ir desactualizado).

### 5.2 Instalación base (ejecutar en los 5 nodos `pg-*`)

```bash
# 1. Repositorio oficial PGDG
sudo apt update
sudo apt install -y curl ca-certificates gnupg
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
  --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
  https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list'
sudo apt update

# 2. Instalar PostgreSQL 16 SIN inicializar el clúster (Patroni se encarga del initdb)
sudo apt install -y postgresql-16 postgresql-client-16 postgresql-contrib-16

# 3. Detener y deshabilitar el servicio nativo: Patroni controla el ciclo de vida de postgres,
#    NUNCA debe haber un systemd "postgresql.service" compitiendo con Patroni por iniciar/detener el motor.
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# 4. pgBackRest (se usará en pg-asy01 como repositorio de backups, y como agente en todos los nodos)
sudo apt install -y pgbackrest

# 5. Patroni + dependencias Python
sudo apt install -y python3-pip python3-venv
sudo python3 -m venv /opt/patroni-venv
sudo /opt/patroni-venv/bin/pip install --upgrade pip
sudo /opt/patroni-venv/bin/pip install patroni[etcd3] psycopg2-binary
# El extra [etcd3] instala el cliente python-etcd3 necesario para hablar el protocolo etcd v3 (gRPC)
```

### 5.3 Estructura de directorios y permisos

```bash
sudo mkdir -p /data/postgresql/16/main      # PGDATA - en el disco NVMe dedicado de datos
sudo mkdir -p /data/postgresql/16/wal       # pg_wal en disco separado (reduce contención I/O entre WAL y datos)
sudo mkdir -p /etc/patroni
sudo mkdir -p /var/log/patroni
sudo chown -R postgres:postgres /data/postgresql /var/log/patroni
sudo chmod 700 /data/postgresql/16/main     # PostgreSQL exige 0700 en PGDATA, o rechaza arrancar
```

### 5.4 Generación de certificados TLS para PostgreSQL (cliente-servidor y replicación)

```bash
# En entorno financiero: TLS obligatorio también para conexiones de aplicación y de replicación.
# Certificados emitidos por la CA interna (ejemplo de nombres de archivo esperados por postgresql.conf):
#   /etc/postgresql/pki/server.crt
#   /etc/postgresql/pki/server.key   (permisos 0600, propietario postgres)
#   /etc/postgresql/pki/ca.crt
```

---

### 5.5 Configuración de Patroni — Nodo `pg-pri01` (Primary inicial)

> **Importante sobre roles:** en Patroni **ningún nodo se marca como "primary" de forma estática** en el YAML. El rol es dinámico: Patroni elige al líder vía el lock en etcd. El archivo siguiente corresponde al nodo que se usará para el **bootstrap inicial** del clúster (es decir, el primer nodo que se levanta y que inicializa la base de datos); tras el primer arranque, cualquier nodo puede terminar siendo primary tras un failover. La diferencia real entre nodos está en los **tags** (ver 5.7 y 5.8) que determinan si un nodo es candidato síncrono, asíncrono, o excluido de balanceo.

Archivo: `/etc/patroni/patroni.yml` en **`pg-pri01`** (10.10.10.11):

```yaml
name: pg-pri01                              # Nombre único del nodo dentro del clúster Patroni (debe ser único, igual al hostname por convención)
namespace: /db/                             # Prefijo de claves en etcd bajo el cual Patroni guarda el estado del clúster (permite multi-clúster en el mismo etcd)
scope: pgha-prod                            # Nombre del clúster PostgreSQL. Todos los 5 nodos DEBEN compartir el mismo "scope" para pertenecer al mismo clúster

restapi:
  listen: 10.10.10.11:8008                  # Interfaz donde Patroni expone su REST API (usada por HAProxy para health-checks y por patronictl)
  connect_address: 10.10.10.11:8008
  # En entorno financiero, habilitar TLS también en la REST API:
  certfile: /etc/patroni/pki/pg-pri01.crt
  keyfile: /etc/patroni/pki/pg-pri01.key
  cafile: /etc/patroni/pki/ca.crt
  verify_client: optional                   # 'required' si se exige mTLS también para consultar la REST API (recomendado en prod)

etcd3:
  hosts:
    - 10.10.20.11:2379                      # Lista de endpoints del clúster etcd (los 3 nodos). Patroni puede hablar con cualquiera
    - 10.10.20.12:2379
    - 10.10.20.13:2379
  protocol: https
  cacert: /etc/patroni/pki/ca.crt
  cert: /etc/patroni/pki/pg-pri01-etcd-client.crt
  key: /etc/patroni/pki/pg-pri01-etcd-client.key

bootstrap:
  # dcs: configuración GLOBAL del clúster que Patroni escribe en etcd la PRIMERA vez.
  # Tras el bootstrap, estos valores se gestionan con `patronictl edit-config`, NO editando este YAML.
  dcs:
    ttl: 30                                 # Segundos que el lock del líder vive en el DCS sin renovación antes de considerarse expirado. Si el líder no renueva el lock en este tiempo, se dispara una nueva elección
    loop_wait: 10                           # Segundos entre iteraciones del bucle de control (HA loop) de Patroni. Cada 10s Patroni revisa el estado del clúster y del DCS
    retry_timeout: 10                       # Segundos máximos para reintentar una operación contra el DCS antes de declarar timeout
    maximum_lag_on_failover: 1048576        # 1 MiB - en modo ASÍNCRONO, una réplica con más de este lag (bytes) NO es candidata a failover. No aplica a nodos en synchronous_mode (estos se gobiernan por el mecanismo de quorum, no por este valor)
    master_start_timeout: 300               # Segundos que Patroni espera a que el primary inicie antes de declararlo fallido e iniciar failover
    synchronous_mode: true                  # ACTIVA el modo síncrono de Patroni: el primary NO confirma commits hasta tener ACK de las réplicas síncronas requeridas. Es el mecanismo que garantiza RPO≈0 para este clúster
    synchronous_mode_strict: false          # Si fuera 'true', el primary se BLOQUEARÍA por completo (no aceptaría escrituras) si NINGUNA réplica síncrona está disponible. En 'false' (recomendado aquí), si ambas síncronas caen, el primary degrada a operar sin espera síncrona en vez de detener el servicio — prioriza DISPONIBILIDAD sobre durabilidad estricta en el caso extremo de perder las 2 síncronas a la vez. Evaluar con el área de riesgo/cumplimiento si su apetito de riesgo exige 'true' (preferir consistencia sobre disponibilidad)
    synchronous_node_count: 1               # Número de réplicas síncronas que deben confirmar el commit (quorum commit). Con 2 réplicas candidatas (pg-syn01, pg-syn02) y este valor en 1, el primary espera ACK de AL MENOS 1 de las 2 — tolera la caída de una síncrona sin bloquear escrituras, y sigue garantizando que el nodo promovido en failover nunca pierda una transacción confirmada
    postgresql:
      use_pg_rewind: true                   # Permite reintegrar un primary caído como réplica usando pg_rewind en vez de re-clonar todo el nodo. Reduce drásticamente el tiempo de recuperación tras failover
      use_slots: true                       # Usa REPLICATION SLOTS físicos para cada réplica: garantiza que el primary retenga el WAL necesario mientras una réplica esté caída temporalmente, evitando que se quede "demasiado atrás" y deba re-clonarse
      parameters:
        # --- Memoria ---
        shared_buffers: 8GB                  # ~25% de RAM (32GB) - caché de páginas de PostgreSQL. Punto de partida estándar; ajustar tras benchmark de carga real
        effective_cache_size: 24GB           # ~75% de RAM - estimación de cuánta caché del OS + shared_buffers está disponible; orienta al planner para decidir entre scan secuencial e índice
        work_mem: 64MB                       # Memoria por operación de ordenamiento/hash POR CONEXIÓN. Cuidado: se multiplica por conexiones concurrentes y por operaciones paralelas dentro de una misma query
        maintenance_work_mem: 1GB            # Memoria para VACUUM, CREATE INDEX, etc. Mayor valor acelera mantenimiento
        # --- WAL y durabilidad (CRÍTICO para RPO/RTO) ---
        wal_level: replica                   # Mínimo requerido para streaming replication. 'logical' solo si se necesita replicación lógica adicional (no es el caso base aquí)
        max_wal_senders: 10                  # Máximo de procesos walsender simultáneos (uno por cada réplica conectada + backups en streaming). Con 4 réplicas + márgenes para backup, 10 da holgura
        max_replication_slots: 10            # Máximo de slots de replicación (uno por réplica + margen para slots temporales de backup)
        wal_keep_size: 2GB                   # WAL retenido adicionalmente además de los slots, como red de seguridad ante problemas de slot
        synchronous_commit: on               # 'on' es obligatorio para que el modo síncrono de Patroni tenga efecto real: el commit del cliente espera confirmación de fsync en la síncrona requerida. (Patroni gestiona dinámicamente synchronous_standby_names; este parámetro debe permanecer 'on')
        full_page_writes: on                 # OBLIGATORIO en 'on'. Protege contra páginas parcialmente escritas en caso de caída del sistema operativo/hardware (con full_page_writes=off se arriesga corrupción tras crash)
        checkpoint_timeout: 15min             # Frecuencia máxima de checkpoint. Checkpoints más espaciados reducen I/O pero aumentan el tiempo de recuperación tras crash
        checkpoint_completion_target: 0.9     # Distribuye la escritura del checkpoint a lo largo del 90% del intervalo, evitando picos de I/O
        max_wal_size: 4GB                     # Tamaño que dispara un checkpoint anticipado si se supera entre checkpoints programados
        min_wal_size: 1GB
        archive_mode: on                      # OBLIGATORIO para backups con pgBackRest (necesita los segmentos de WAL archivados, no solo streaming)
        archive_command: 'pgbackrest --stanza=pgha-prod archive-push %p'   # Comando que pgBackRest usa para archivar cada segmento WAL completado
        archive_timeout: 60                   # Fuerza el cierre/archivado de un segmento WAL cada 60s aunque no esté lleno, acotando el RPO máximo del archivado continuo
        # --- Conexiones ---
        max_connections: 300                  # Ajustar según el número real de conexiones de la capa de aplicación + pool (PgBouncer recomendado delante de esto en producción real)
        # --- Autovacuum (crítico en sistemas transaccionales de alto volumen) ---
        autovacuum: on
        autovacuum_max_workers: 6
        autovacuum_vacuum_scale_factor: 0.05  # Dispara autovacuum con solo 5% de filas muertas (más agresivo que el 20% por defecto), apropiado para tablas grandes con alta tasa de escritura típicas en banca
        autovacuum_analyze_scale_factor: 0.02
        # --- Logging (auditoría — requisito típico de cumplimiento financiero) ---
        logging_collector: on
        log_destination: 'csvlog'
        log_directory: '/var/log/postgresql'
        log_filename: 'postgresql-%Y-%m-%d.log'
        log_rotation_age: '1d'
        log_min_duration_statement: 1000      # Loguea toda sentencia que tarde más de 1000ms (1s) — ayuda a detectar queries lentas sin saturar el log con todo el tráfico
        log_connections: on                   # Auditoría: registra cada conexión entrante (usuario, base, origen)
        log_disconnections: on
        log_line_prefix: '%m [%p] %q%u@%d '
        log_checkpoints: on
        log_lock_waits: on                    # Útil para detectar contención/bloqueos en transacciones financieras concurrentes
        # --- SSL/TLS ---
        ssl: on
        ssl_cert_file: '/etc/postgresql/pki/server.crt'
        ssl_key_file: '/etc/postgresql/pki/server.key'
        ssl_ca_file: '/etc/postgresql/pki/ca.crt'
        ssl_min_protocol_version: 'TLSv1.2'   # Prohíbe TLS 1.0/1.1, obsoletos e inseguros — requisito estándar PCI-DSS
        password_encryption: scram-sha-256    # Algoritmo de hash de contraseñas; scram-sha-256 es el estándar moderno (NO usar md5)
        shared_preload_libraries: 'pg_stat_statements'   # Habilita la extensión de estadísticas de queries, esencial para diagnóstico de performance en producción

  # initdb: parámetros usados SOLO la primera vez que se inicializa la base, en el nodo que hace bootstrap
  initdb:
    - encoding: UTF8
    - data-checksums                        # Habilita checksums de página: detecta corrupción de datos en disco/memoria. OBLIGATORIO en sistemas financieros críticos (tiene un costo de CPU marginal, ampliamente justificado)
    - locale: en_US.UTF-8

  # pg_hba.conf que Patroni escribirá durante el bootstrap (luego administrable vía patronictl o archivo directo + reload)
  pg_hba:
    - local   all             postgres                                peer
    - local   all             all                                     scram-sha-256
    - hostssl replication     replicator      10.10.10.0/24            scram-sha-256   # Solo replicación, solo TLS, solo desde la red de datos PG
    - hostssl all             app_user        10.10.30.0/24            scram-sha-256   # Tráfico aplicativo (en la práctica llega vía balanceador, pero la regla cubre origen real si se NATea o no)
    - hostssl all             app_user        10.10.10.21/32           scram-sha-256   # lb01
    - hostssl all             app_user        10.10.10.22/32           scram-sha-256   # lb02
    - hostssl all             bi_reader       10.10.50.0/24            scram-sha-256   # Solo aplica en pg-asy02, ver 5.8 (se incluye aquí por consistencia documental)
    - hostssl all             dba_admin       10.10.40.0/24            scram-sha-256   # Bastión de DBAs
    - host    all             all             0.0.0.0/0                reject          # Regla de cierre explícita: deniega cualquier otro origen no listado arriba

  # Usuarios creados durante el bootstrap (las contraseñas reales NUNCA deben ir en texto plano en este archivo
  # en producción: usar variables de entorno, Vault, o patroni.yml con permisos 0600 + secret manager)
  users:
    admin:
      password: "${PATRONI_ADMIN_PASSWORD}"   # Inyectado vía variable de entorno desde el gestor de secretos
      options:
        - createrole
        - createdb

postgresql:
  listen: 10.10.10.11:5432,127.0.0.1:5432
  connect_address: 10.10.10.11:5432
  data_dir: /data/postgresql/16/main
  bin_dir: /usr/lib/postgresql/16/bin
  pgpass: /tmp/pgpass_pg-pri01                  # Archivo .pgpass temporal usado internamente por Patroni para conexiones de replicación/superusuario
  authentication:
    replication:
      username: replicator
      password: "${PATRONI_REPLICATOR_PASSWORD}"
    superuser:
      username: postgres
      password: "${PATRONI_SUPERUSER_PASSWORD}"
    rewind:                                      # Credenciales específicas para pg_rewind (requerido desde Patroni 2.0+ para separar privilegios de rewind del superusuario)
      username: rewind_user
      password: "${PATRONI_REWIND_PASSWORD}"
  parameters:
    unix_socket_directories: '/var/run/postgresql'
  create_replica_methods:
    - basebackup                                # Método usado para clonar una réplica nueva/reconstruida: pg_basebackup estándar vía streaming desde el líder actual
  basebackup:
    max-rate: '100M'                            # Limita el ancho de banda del basebackup a 100MB/s para no saturar la red/disco del primary mientras clona una réplica nueva
    checkpoint: 'fast'

tags:
  nofailover: false        # false = este nodo SÍ puede ser elegido como nuevo líder en un failover (aplica al rol bootstrap; en operación esto se evalúa dinámicamente según quién sea primary/sync/async)
  noloadbalance: false      # false = este nodo SÍ puede recibir tráfico de solo-lectura cuando actúe como réplica (no aplica mientras es primary)
  clonefrom: false          # No se usa este nodo como fuente preferente de clonado para nodos cascada
  nosync: false             # false = este nodo SÍ puede ser elegido como síncrono
```

> **Variables de entorno:** las contraseñas (`${PATRONI_ADMIN_PASSWORD}`, etc.) deben inyectarse vía `/etc/patroni/patroni.env` (cargado por el unit de systemd con `EnvironmentFile=`), nunca escritas en texto plano en `patroni.yml`. Ese archivo `.env` debe tener permisos `0600` y propietario `postgres`, y en producción real debe poblarse desde un gestor de secretos (HashiCorp Vault, AWS Secrets Manager, etc.), no a mano.

---

### 5.6 Diferencias por nodo: `pg-syn01` y `pg-syn02` (réplicas síncronas)

Los archivos `patroni.yml` de `pg-syn01` (10.10.10.12) y `pg-syn02` (10.10.10.13) son **prácticamente idénticos** al de `pg-pri01`, salvo:

1. `name`, `restapi.listen`, `restapi.connect_address`, `postgresql.listen`, `postgresql.connect_address` → usan la IP/hostname propio de cada nodo.
2. La sección `bootstrap.dcs` **NO se repite tal cual**: solo el nodo que hace el bootstrap inicial la define con efecto real; en los demás nodos esa sección existe en el YAML por completitud/idempotencia, pero el valor que realmente gobierna el clúster es el que está en el DCS (etcd) tras el primer arranque, gestionado luego vía `patronictl edit-config`.
3. **Tags** (la diferencia funcionalmente importante):

```yaml
# Tags en pg-syn01 y pg-syn02
tags:
  nofailover: false       # Son candidatas legítimas a ser promovidas como nuevo líder
  noloadbalance: false     # SÍ deben recibir tráfico de lectura balanceado (son el pool de lectura "fresco")
  clonefrom: false
  nosync: false            # SÍ son elegibles como síncronas (son, de hecho, las únicas 2 elegibles en este diseño)
```

No se requiere ninguna marca adicional para "forzar" que sean las síncronas: con `synchronous_node_count: 1` y solo estos 2 nodos teniendo `nosync: false` (los asíncronos lo tendrán en `true`, ver 5.8), Patroni automáticamente restringe el pool de candidatas síncronas a `{pg-syn01, pg-syn02}`.

---

### 5.7 Diferencias por nodo: `pg-asy01` y `pg-asy02` (réplicas asíncronas — backup/reporting)

Archivo `patroni.yml` en **`pg-asy01`** (10.10.10.14) y **`pg-asy02`** (10.10.10.15): mismo esqueleto que el primary, con estos cambios clave:

```yaml
tags:
  nofailover: true        # CRÍTICO: estos nodos NUNCA deben ser promovidos a líder. Al estar en modo asíncrono pueden tener lag de datos; promoverlos arriesgaría pérdida de transacciones confirmadas. nofailover:true los EXCLUYE por completo de la elección de líder
  noloadbalance: true       # CRÍTICO: estos nodos quedan EXCLUIDOS del balanceador de lectura aplicativo. La REST API de Patroni responderá 503 al endpoint /replica para ellos, así que aunque alguien los agregue por error al backend de HAProxy, el health-check los marcará como "down" y HAProxy nunca les enviará tráfico
  nosync: true              # CRÍTICO: excluye a este nodo del pool de candidatos a réplica SÍNCRONA. Permanece en modo asíncrono (streaming best-effort, sin que el primary espere su ACK para confirmar commits)
  clonefrom: false
```

Adicionalmente, en estos dos nodos se ajustan parámetros de `postgresql.parameters` orientados a su uso específico:

**`pg-asy01` (dedicado a pgBackRest):**

```yaml
    parameters:
      # ... (mismos parámetros base de la sección 5.5) ...
      shared_buffers: 2GB          # Menor: este nodo no sirve consultas analíticas pesadas, solo soporta el streaming + backups
      max_wal_senders: 5            # Solo necesita atender su propia conexión de replicación + backups en streaming si aplica
      hot_standby_feedback: on      # Evita que VACUUM en el primary elimine filas que este standby aún podría necesitar para queries largas (relevante si se ejecutan validaciones de backup con consultas)
```

**`pg-asy02` (dedicado a Reporting/BI):**

```yaml
    parameters:
      # ... (mismos parámetros base de la sección 5.5) ...
      shared_buffers: 8GB           # Mayor: este nodo SÍ sirve consultas analíticas pesadas (reportes, BI)
      work_mem: 256MB                # Las consultas de reporting suelen requerir más memoria de ordenamiento/agregación
      max_parallel_workers_per_gather: 4   # Habilita paralelismo de consultas, típico en cargas analíticas (no recomendado subir esto en el primary ni en las síncronas, donde se prioriza baja latencia transaccional)
      hot_standby_feedback: on        # Evita conflictos de cancelación de queries largas de reporting causados por VACUUM en el primary
      max_standby_streaming_delay: 30s # Da margen antes de cancelar una query de reporting larga por conflicto de replay del WAL
```

> **Por qué `nosync: true` y no simplemente "no ponerlos en la lista"**: Patroni, por defecto, considera a **todas** las réplicas conectadas como candidatas síncronas (modo "todas elegibles" desde PostgreSQL 9.6+) salvo que se les marque explícitamente `nosync: true`. Si no se pusiera este tag, existiría el riesgo de que, ante la caída simultánea de `pg-syn01` y `pg-syn02`, Patroni promoviera automáticamente a un nodo asíncrono al rol síncrono, lo cual rompería el límite de carga/aislamiento que el cliente pidió explícitamente (los asíncronos no deben mezclarse con el tráfico transaccional). Ver además la sección 8 (runbook) para el procedimiento manual a seguir en ese escenario extremo.

### 5.8 `pg_hba.conf` — Reglas específicas adicionales en `pg-asy02`

Por ser el nodo de Reporting/BI, `pg-asy02` requiere una regla de acceso adicional que **no debe replicarse** a ningún otro nodo del clúster:

```
hostssl  all   bi_reader   10.10.50.0/24   scram-sha-256   # Subred del motor de BI/Reporting. Rol bi_reader con acceso SOLO LECTURA (ver rol en sección 7)
```

Este acceso **no existe** en `pg-pri01`, `pg-syn01`, `pg-syn02` ni `pg-asy01`: el usuario `bi_reader` solo puede conectarse, en todo el clúster, a `pg-asy02`.

---

### 5.9 Unit de systemd para Patroni (idéntico en los 5 nodos, salvo el `name` interno)

`/etc/systemd/system/patroni.service`:

```ini
[Unit]
Description=Patroni PostgreSQL HA orchestrator
Documentation=https://patroni.readthedocs.io
After=network-online.target etcd.target
Wants=network-online.target

[Service]
Type=simple
User=postgres
Group=postgres
EnvironmentFile=-/etc/patroni/patroni.env       # Carga las contraseñas/secretos (el '-' inicial hace que no falle si el archivo no existe, aunque en prod SIEMPRE debe existir)
ExecStart=/opt/patroni-venv/bin/patroni /etc/patroni/patroni.yml
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
TimeoutSec=30
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now patroni
```

> **Orden de arranque del clúster completo (bootstrap inicial):**
> 1. Levantar y validar los 3 nodos `etcd*` (sección 4).
> 2. Arrancar Patroni **primero en `pg-pri01`** (este será quien haga `initdb` y se convierta en el primer líder).
> 3. Verificar con `patronictl -c /etc/patroni/patroni.yml list` que `pg-pri01` aparece como `Leader` / `running`.
> 4. Arrancar Patroni en `pg-syn01`, `pg-syn02`, `pg-asy01`, `pg-asy02` (en cualquier orden); cada uno detectará que ya existe un líder en el DCS y se unirá como réplica, clonándose automáticamente vía `pg_basebackup` desde el líder.
> 5. Confirmar con `patronictl list` que los 5 nodos aparecen, con los roles y `Sync state` esperados (ver sección 6.4).

### 5.10 Verificación rápida post-bootstrap

```bash
patronictl -c /etc/patroni/patroni.yml list

# Salida esperada (ejemplo ilustrativo):
# + Cluster: pgha-prod (73248...) ------+---------+----+-----------+
# | Member    | Host          | Role         | State   | TL | Lag in MB |
# +-----------+---------------+--------------+---------+----+-----------+
# | pg-pri01  | 10.10.10.11   | Leader       | running |  1 |           |
# | pg-syn01  | 10.10.10.12   | Sync Standby | running |  1 |         0 |
# | pg-syn02  | 10.10.10.13   | Sync Standby | running |  1 |         0 |
# | pg-asy01  | 10.10.10.14   | Replica      | running |  1 |         2 |
# | pg-asy02  | 10.10.10.15   | Replica      | running |  1 |         5 |
# +-----------+---------------+--------------+---------+----+-----------+
```
## 6. Balanceadores: HAProxy + Keepalived

### 6.1 Por qué HAProxy consultando la REST API de Patroni (y no un balanceador "a ciegas" por IP)

El balanceador **nunca** debe decidir quién es el primary inspeccionando PostgreSQL directamente o, peor, con una IP fija. Patroni expone una **REST API** (puerto 8008) en cada nodo con endpoints de salud específicos por rol, documentados oficialmente: `GET /primary` devuelve 200 solo en el líder; `GET /replica` devuelve 200 en réplicas sanas con `noloadbalance:false`; `GET /sync` devuelve 200 solo en réplicas síncronas; `GET /async` devuelve 200 solo en asíncronasGET /synchronous or GET /sync: returns HTTP status code 200 only when the Patroni node is running as a synchronous standby. ... GET /asynchronous or GET /async: returns HTTP status code 200 only when the Patroni node is running as an asynchronous standby.. HAProxy usa estos endpoints como **health-check HTTP**, de forma que el enrutamiento se ajusta automáticamente en segundos tras cualquier failover, sin tocar configuración.

### 6.2 Instalación (en `lb01` y `lb02`)

```bash
sudo apt update
sudo apt install -y haproxy keepalived
```

### 6.3 Configuración HAProxy `/etc/haproxy/haproxy.cfg` (idéntica en `lb01` y `lb02`)

```
global
    log /dev/log local0
    log /dev/log local1 notice
    maxconn 4000                        # Máximo de conexiones concurrentes totales del proceso HAProxy
    daemon
    user haproxy
    group haproxy

defaults
    log     global
    mode    tcp                          # Balanceo a nivel TCP (no HTTP) para el tráfico PostgreSQL real: el protocolo de PG no es HTTP
    retries 2
    timeout connect 4s
    timeout client  30m                  # Conexiones de base de datos pueden permanecer abiertas mucho tiempo (pool de la app); timeout generoso
    timeout server  30m
    timeout check   5s

# --- Página de estadísticas, SOLO accesible desde red de monitoreo (ver firewall 3.3) ---
listen stats
    bind 10.10.10.21:7000                # Cambiar a 10.10.10.22 en lb02
    mode http
    stats enable
    stats uri /
    stats refresh 10s
    stats auth admin:${HAPROXY_STATS_PASSWORD}    # Credencial inyectada por variable de entorno/secret manager, nunca en texto plano en el repo

# ======================= FRONTEND/BACKEND DE ESCRITURA =======================
# Solo debe existir UN nodo "UP" aquí en todo momento: el primary actual.
frontend pg_write_front
    bind 10.10.30.10:5000                 # VIP de escritura (gestionada por Keepalived, ver 6.4)
    default_backend pg_write_back

backend pg_write_back
    option httpchk GET /primary           # Patroni responde 200 SOLO en el nodo que es Leader actual
    http-check expect status 200
    default-server inter 3s fall 3 rise 2  # Chequea cada 3s; marca DOWN tras 3 fallos consecutivos (9s); marca UP tras 2 éxitos consecutivos
    server pg-pri01 10.10.10.11:5432 check port 8008
    server pg-syn01 10.10.10.12:5432 check port 8008
    server pg-syn02 10.10.10.13:5432 check port 8008
    # NOTA: se listan los 3 candidatos posibles a primary (los únicos con nofailover:false).
    # El health-check /primary garantiza que SOLO el que realmente es líder reciba tráfico,
    # sin importar cuál de los 3 sea en cada momento tras un failover.
    # pg-asy01 y pg-asy02 NUNCA se listan aquí: tienen nofailover:true y nunca serán primary.

# ======================= FRONTEND/BACKEND DE LECTURA (solo réplicas síncronas) =======================
frontend pg_read_front
    bind 10.10.30.11:5001                 # VIP de lectura
    default_backend pg_read_back

backend pg_read_back
    balance roundrobin                     # Reparte el tráfico de lectura entre las réplicas síncronas disponibles
    option httpchk GET /read-only-sync     # 200 en réplicas SÍNCRONAS sanas (también seguro incluirlo así: si ambas cayeran, este endpoint NO incluye asíncronas, así que el pool de lectura quedaría correctamente vacío en vez de degradar a datos desfasados sin que nadie lo decida explícitamente)
    http-check expect status 200
    default-server inter 3s fall 3 rise 2
    server pg-syn01 10.10.10.12:5432 check port 8008
    server pg-syn02 10.10.10.13:5432 check port 8008
    # pg-asy01 y pg-asy02 NUNCA se listan aquí. Aunque por error se agregaran, su tag
    # noloadbalance:true hace que /read-only-sync y /replica respondan 503 igualmente
    # (defensa en profundidad: doble control, por configuración Y por health-check).
```

> **Decisión de diseño importante:** se usó `/read-only-sync` (incluye primary + síncronas) en vez de `/sync` puro (solo síncronas, excluye primary) deliberadamente, para que el pool de lectura no quede vacío si momentáneamente solo el primary está "sano" como candidato de lectura durante una transición. Si el cliente prefiere que el primary **nunca** reciba tráfico de lectura (para no competir con el tráfico de escritura), cambiar a `option httpchk GET /sync` estrictamente.

### 6.4 Configuración Keepalived (VIP de alta disponibilidad de los propios balanceadores)

**`lb01`** — `/etc/keepalived/keepalived.conf` (rol MASTER):

```
vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"   # Verifica que el proceso haproxy esté vivo
    interval 2                              # Cada 2 segundos
    weight 2                                 # Suma 2 puntos de prioridad si el chequeo pasa
}

vrrp_instance VI_WRITE {
    state MASTER                             # lb01 arranca como MASTER de esta VIP
    interface eth0                            # Interfaz de red donde se asocia la VIP
    virtual_router_id 51                      # Identificador único del grupo VRRP (debe coincidir en lb01 y lb02, y ser distinto de otros VRRP en la misma red)
    priority 150                               # Mayor prioridad = preferencia como MASTER
    advert_int 1                                # Intervalo de anuncios VRRP en segundos
    authentication {
        auth_type PASS
        auth_pass ${VRRP_AUTH_PASS}            # Password compartida VRRP, inyectada por secret manager
    }
    virtual_ipaddress {
        10.10.30.10/24                          # VIP de ESCRITURA
    }
    track_script {
        chk_haproxy
    }
}

vrrp_instance VI_READ {
    state MASTER
    interface eth0
    virtual_router_id 52                       # ID distinto al de VI_WRITE
    priority 150
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass ${VRRP_AUTH_PASS_READ}
    }
    virtual_ipaddress {
        10.10.30.11/24                          # VIP de LECTURA
    }
    track_script {
        chk_haproxy
    }
}
```

**`lb02`** — mismo archivo, pero con `state BACKUP` y `priority 100` (menor que `lb01`) en ambos bloques `vrrp_instance`. Todo lo demás (virtual_router_id, virtual_ipaddress, auth_pass) debe ser **idéntico** entre ambos nodos.

> Con esta configuración, si `lb01` cae o su HAProxy deja de responder, `chk_haproxy` falla, la prioridad efectiva de `lb01` baja, y `lb02` asume ambas VIP automáticamente en ~2-3 segundos. Esto da alta disponibilidad también en la capa de balanceo, no solo en la capa de datos.

```bash
sudo systemctl enable --now haproxy
sudo systemctl enable --now keepalived
```

---

## 7. Seguridad: roles, autenticación y cumplimiento

### 7.1 Roles de PostgreSQL (principio de mínimo privilegio)

| Rol | Tipo | Uso | Dónde puede conectar |
|---|---|---|---|
| `postgres` | Superusuario | Administración interna de Patroni únicamente. **Nunca** usado por aplicaciones | Solo local (socket Unix) en cada nodo |
| `replicator` | Rol de replicación (`REPLICATION LOGIN`) | Streaming replication entre nodos | Solo entre nodos `pg-*` (red 10.10.10.0/24) |
| `rewind_user` | Privilegios específicos para `pg_rewind` (`EXECUTE` sobre funciones de control, `pg_monitor`) | Reintegración de nodos tras failover | Solo local/entre nodos `pg-*` |
| `app_user` | Rol aplicativo, `LOGIN`, permisos `SELECT/INSERT/UPDATE/DELETE` solo sobre los esquemas de negocio (sin `SUPERUSER`, sin `CREATEDB`, sin `CREATEROLE`) | Tráfico transaccional de la aplicación | Vía VIP de escritura (5000) y VIP de lectura (5001) únicamente |
| `bi_reader` | Rol de solo lectura (`SELECT` únicamente, sin `INSERT/UPDATE/DELETE`) | Consultas de reporting/BI | Solo directo a `pg-asy02` (10.10.10.15), nunca vía VIP |
| `dba_admin` | Rol administrativo con privilegios elevados pero nominal (no genérico `postgres`), con auditoría reforzada | Operación y mantenimiento por DBAs | Solo desde el bastión (10.10.40.0/24), con MFA en el bastión |

```sql
-- Ejemplo de creación de roles (ejecutar una sola vez en el primary; se replica automáticamente)
CREATE ROLE app_user WITH LOGIN PASSWORD '...' CONNECTION LIMIT 200;
GRANT CONNECT ON DATABASE core_banking TO app_user;
GRANT USAGE ON SCHEMA banking TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA banking TO app_user;

CREATE ROLE bi_reader WITH LOGIN PASSWORD '...' CONNECTION LIMIT 50;
GRANT CONNECT ON DATABASE core_banking TO bi_reader;
GRANT USAGE ON SCHEMA banking TO bi_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA banking TO bi_reader;
ALTER ROLE bi_reader SET default_transaction_read_only = on;   -- Defensa adicional: aunque conectara por error a un nodo "escribible", el rol fuerza solo-lectura a nivel de sesión
```

### 7.2 Controles adicionales recomendados (no opcionales en banca)

- **Rotación de contraseñas/certificados:** todas las credenciales (`replicator`, `rewind_user`, `app_user`, VRRP, etcd mTLS) deben rotar periódicamente vía el gestor de secretos corporativo, nunca manualmente "cuando alguien se acuerde".
- **Auditoría extendida:** instalar `pgaudit` además de `pg_stat_statements` si el área de cumplimiento exige trazabilidad por sentencia y por usuario (típico requisito SOX/PCI-DSS en banca).
- **Cifrado en reposo:** además del TLS en tránsito ya configurado, evaluar cifrado de disco a nivel de volumen (LUKS, o cifrado nativo del proveedor de nube/SAN) para los discos de datos de los 5 nodos.
- **Separación de funciones:** los DBAs que operan el clúster no deberían ser los mismos que aprueban los cambios de configuración en el comité de cambios (control de 4 ojos), especialmente para cambios en `synchronous_mode_strict` o en la topología de failover.
- **Hardening de SO:** deshabilitar login por password en SSH (solo claves), `fail2ban` en el bastión, CIS Benchmark para Ubuntu 22.04 aplicado a las 10 VMs.

---

## 8. Backups con pgBackRest (en `pg-asy01`)

### 8.1 Por qué en `pg-asy01` y no en el primary

Ejecutar backups full/incrementales contra el primary o las síncronas competiría por I/O justo con el tráfico transaccional y, en el caso de las síncronas, podría introducir latencia adicional en el camino crítico de confirmación de commits. Al apuntar pgBackRest a `pg-asy01` (asíncrona, `nofailover:true`, fuera del pool de lectura), el backup queda completamente aislado del camino crítico, alineado con el patrón documentado de arquitecturas Patroni+etcd+Barman/pgBackRest de referenciaWith synchronous replication, controlled leader election and cross-region backup in place, the business can operate with confidence in its database infrastructure. ... This PostgreSQL High Availability architecture delivers production-grade resilience while maintaining strict data integrity and recovery guarantees..

### 8.2 Configuración `/etc/pgbackrest/pgbackrest.conf` en `pg-asy01`

```ini
[global]
repo1-path=/backup/pgbackrest                  # Ruta del repositorio de backups (idealmente un volumen/almacenamiento separado, o repo-type=s3 contra storage objeto)
repo1-retention-full=4                           # Conserva los últimos 4 backups FULL (ajustar según política de retención del banco, p.ej. 30 días)
repo1-retention-diff=14                          # Conserva 14 backups diferenciales
process-max=4                                     # Paralelismo para acelerar backup/restore
compress-type=zst                                 # Compresión zstd: buen balance velocidad/ratio
start-fast=true                                    # Fuerza un checkpoint inmediato al iniciar el backup (acelera el arranque del backup, a costa de un pico breve de I/O)
log-level-console=info
log-level-file=detail

[pgha-prod]
pg1-path=/data/postgresql/16/main
pg1-port=5432
pg1-socket-path=/var/run/postgresql
```

### 8.3 Programación recomendada (cron o, preferentemente, orquestador corporativo de jobs)

```bash
# Backup FULL semanal (domingo 02:00, ventana de bajo tráfico)
0 2 * * 0 pgbackrest --stanza=pgha-prod --type=full backup

# Backup INCREMENTAL diario (lunes a sábado, 02:00)
0 2 * * 1-6 pgbackrest --stanza=pgha-prod --type=incr backup

# Verificación de integridad del repositorio (semanal)
0 4 * * 0 pgbackrest --stanza=pgha-prod check
```

### 8.4 Parámetros clave de recuperación (RPO/RTO objetivo)

| Métrica | Objetivo en este diseño | Cómo se logra |
|---|---|---|
| **RPO transaccional** (pérdida máxima de transacciones confirmadas ante caída del primary) | ≈0 | `synchronous_mode: true` + `synchronous_node_count: 1` sobre `pg-syn01`/`pg-syn02` |
| **RPO de backup** (pérdida máxima ante destrucción total del clúster, incluido DCS) | ≤ `archive_timeout` (60s) + frecuencia de backup incremental | `archive_command` continuo hacia pgBackRest + `archive_timeout: 60` |
| **RTO de failover automático** (tiempo de indisponibilidad de escritura ante caída del primary) | Segundos a low-doble-dígito (típicamente `ttl` + `loop_wait`, ≈30-40s en el peor caso) | Patroni + etcd con los parámetros de la sección 4.4/5.5 |
| **RTO de recuperación total desde backup** (pérdida total del datacenter/clúster) | Depende de tamaño de datos y ancho de banda de restore; debe medirse con un *DR drill* real | `pgbackrest restore` desde `pg-asy01` o desde el repositorio remoto |

---

## 9. Monitoreo

### 9.1 Componentes mínimos recomendados

- **postgres_exporter** (puerto 9187) en los 5 nodos `pg-*`: expone métricas de PostgreSQL (conexiones, locks, replicación, autovacuum) a Prometheus.
- **node_exporter** (puerto 9100) en las 10 VMs: métricas de sistema operativo (CPU, RAM, disco, red).
- **Patroni REST API** (`/metrics` o estado vía `/cluster`) integrable directamente como *target* de Prometheus para visualizar el estado del clúster (líder actual, lag de cada réplica, estado de sync).
- **etcd `/metrics`** (sección 4.4, `metrics: extensive`): vital para vigilar latencia de Raft, tamaño del DCS, y detectar degradación del DCS antes de que cause falsos failovers.
- **Alertas críticas mínimas:** cambio de líder (failover), pérdida de quórum etcd, lag de réplica síncrona > umbral, lag de réplica asíncrona creciendo sin límite, fallo de backup pgBackRest, certificados TLS próximos a expirar.

---

## 10. Runbooks operativos

### 10.1 Failover automático (caída del primary)

1. Patroni en cada réplica detecta, vía el lock TTL en etcd, que el líder no renovó su lock (transcurridos `ttl`=30s sin renovación).
2. Se dispara una elección: solo los nodos con `nofailover:false` (es decir, `pg-syn01` y `pg-syn02`; nunca los `pg-asy*`) participan.
3. Gracias al modo quorum commit, Patroni garantiza que el nodo promovido es uno que tiene **todas las transacciones confirmadas** (ninguna pérdida de datos en el camino síncrono).
4. El nodo ganador ejecuta `pg_promote`; los demás reconfiguran su `primary_conninfo` para apuntar al nuevo líder.
5. HAProxy detecta el cambio en segundos (health-check `/primary` cada 3s) y reenruta automáticamente el tráfico de escritura sin intervención manual.
6. **Acción humana requerida:** validar causa raíz de la caída del primary original; si vuelve a estar disponible, Patroni (con `use_pg_rewind: true`) lo reincorporará automáticamente como réplica, pero el equipo de DBA debe confirmar que no hay corrupción subyacente antes de declarar el incidente cerrado.

### 10.2 Failover manual planificado (mantenimiento)

```bash
patronictl -c /etc/patroni/patroni.yml switchover --master pg-pri01 --candidate pg-syn01
# Patroni realiza un cambio de líder CONTROLADO: drena conexiones, asegura que pg-syn01
# esté 100% al día antes de promoverlo, y solo entonces conmuta. Cero pérdida de datos.
```

### 10.3 Procedimiento si caen simultáneamente `pg-syn01` y `pg-syn02`

Este es el escenario extremo donde, con `synchronous_mode_strict: false`, el primary seguirá aceptando escrituras pero **sin garantía de durabilidad síncrona** (degradado a comportamiento asíncrono de facto). Procedimiento:

1. Alertas críticas deben disparar inmediatamente (lag=0 candidatos síncronos disponibles).
2. **No promover automáticamente** a `pg-asy01`/`pg-asy02` a síncrono: requiere decisión humana documentada, porque rompe el aislamiento de carga que el negocio definió.
3. Si el negocio decide que es aceptable temporalmente (ventana de incidente), un DBA senior puede, de forma manual y documentada en el ticket de incidente, quitar el tag `nosync` de uno de los asíncronos vía `patronictl edit-config`, restaurándolo apenas se recupere alguno de los nodos síncronos originales.
4. Esta acción manual queda **fuera del comportamiento automático por diseño** — es intencional para evitar que el sistema mezcle, sin supervisión, tráfico de reporting/backup con el rol crítico de durabilidad síncrona.

### 10.4 Pérdida de un nodo etcd

- Con 3 nodos, la pérdida de 1 **no afecta** la disponibilidad del clúster Postgres (el DCS sigue con quórum 2/3).
- Acción: reemplazar el nodo caído lo antes posible (mismo día, ventana de mantenimiento) para no operar con tolerancia a fallos reducida (perder un segundo nodo etcd dejaría sin quórum y **bloquearía** toda elección de líder Postgres, aunque el primary actual seguiría sirviendo tráfico hasta que necesite renovar su lock).
- **Nunca** reiniciar más de un nodo etcd a la vez en mantenimiento programado.

---

## 11. Checklist final de aceptación antes de producción

- [ ] Los 3 nodos etcd responden sanos y con mTLS validado (sección 4.7).
- [ ] `patronictl list` muestra los 5 nodos con los roles esperados: 1 Leader, 2 Sync Standby, 2 Replica (async).
- [ ] `synchronous_mode: true`, `synchronous_node_count: 1`, y los tags `nosync:true`/`nofailover:true`/`noloadbalance:true` confirmados en `pg-asy01`/`pg-asy02` vía `patronictl show-config`.
- [ ] Prueba de **switchover controlado** ejecutada en ventana de prueba, sin pérdida de datos verificada (comparar LSN antes/después).
- [ ] Prueba de **failover forzado** (matar el proceso del primary) ejecutada, con medición real de RTO.
- [ ] HAProxy: confirmado que el pool de escritura siempre tiene exactamente 1 backend `UP`, y el pool de lectura nunca incluye a `pg-asy01`/`pg-asy02`.
- [ ] Keepalived: prueba de caída de `lb01`, confirmando migración de ambas VIP a `lb02` en menos de 5 segundos.
- [ ] Backup pgBackRest: al menos 1 backup FULL y 1 restore de prueba completados exitosamente en ambiente de prueba (no asumir que un backup es válido sin haberlo restaurado).
- [ ] Firewall: matriz de la sección 3.2 aplicada y verificada con escaneo de puertos desde cada subred (confirmar que lo prohibido en 3.3 efectivamente está bloqueado).
- [ ] Roles de PostgreSQL (sección 7.1) creados con privilegios mínimos verificados (intentar y confirmar que `bi_reader` no puede hacer `INSERT`, que `app_user` no puede `DROP TABLE` fuera de su esquema, etc.).
- [ ] Certificados TLS (etcd mTLS, Postgres SSL, Patroni REST API) emitidos por la CA interna, con fecha de expiración registrada y alerta de rotación configurada.
- [ ] Documentado y aprobado por el comité de cambios/seguridad el procedimiento de la sección 10.3 (degradación ante pérdida de ambas síncronas).
- [ ] *DR drill* completo ejecutado al menos una vez: restauración desde backup en infraestructura aislada, con RTO/RPO medidos y comparados contra los objetivos de la sección 8.4.
- [ ] Plan de capacidad validado con `pgbench` o carga real simulada, confirmando que `shared_buffers`, `work_mem`, `max_connections` y el dimensionamiento de CPU/RAM/IOPS de la tabla 2.2 son adecuados para el volumen transaccional real del banco (los valores de este manual son punto de partida, no destino final).

---

## 12. Referencias y fuentes consultadas

- Documentación oficial de Patroni — *Replication modes* (synchronous_mode, quorum commit): patroni.readthedocs.io/en/latest/replication_modes.html
- Documentación oficial de Patroni — *REST API* (endpoints `/primary`, `/replica`, `/sync`, `/async`): patroni.readthedocs.io/en/latest/rest_api.html
- Documentación oficial de Patroni — *YAML Configuration Settings* (tags: `nofailover`, `noloadbalance`, `nosync`, `failover_priority`): patroni.readthedocs.io/en/latest/yaml_configuration.html
- Repositorio oficial de Patroni (GitHub: zalando/patroni — patroni/patroni): patrones de `maximum_lag_on_failover` y replicación síncrona/asíncrona.
- Documentación oficial de etcd (etcd.io/docs): parámetros de `etcd.conf.yml`, TLS/mTLS, `heartbeat-interval`/`election-timeout`.
- Documentación oficial de pgBackRest (pgbackrest.org): configuración de stanzas, retención, `archive-push`.
- Documentación oficial de PostgreSQL 16 (postgresql.org/docs/16): parámetros de `postgresql.conf` (WAL, autovacuum, SSL, logging).
- Artículos de arquitectura de referencia sobre HA con Patroni/etcd/Barman/pgBackRest en entornos productivos multi-nodo (Blue Crystal Solutions; Learnomate Technologies) — usados como validación de patrones de diseño (aislamiento del DCS, balanceo basado en health-check de Patroni, separación de backups del camino crítico).

> **Recordatorio final:** este documento es una plantilla de ingeniería de referencia. Antes de su uso en producción financiera real, debe pasar por: revisión de seguridad, revisión de cumplimiento regulatorio (local e internacional según jurisdicción del banco), pruebas de carga con tráfico representativo, y al menos un ciclo completo de *game day* / *DR drill* documentado y firmado por los responsables de Riesgo Tecnológico e Infraestructura.
