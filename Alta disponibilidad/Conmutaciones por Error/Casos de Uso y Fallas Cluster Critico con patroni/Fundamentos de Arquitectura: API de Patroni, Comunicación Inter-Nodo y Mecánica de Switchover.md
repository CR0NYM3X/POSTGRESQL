# Fundamentos de Arquitectura: API de Patroni, Comunicación Inter-Nodo y Mecánica de Switchover

El corazón de la automatización en Patroni es su **API REST**, la cual actúa como el sistema nervioso del clúster.

A continuación, resolvemos detalladamente tus dudas arquitectónicas bajo los estándares de documentación oficial.

 

## 1. La API REST de Patroni: Objetivo, Alcance y Límites

El objetivo principal de la API REST de Patroni (que por defecto corre en el puerto `8008`) es proporcionar una **interfaz de abstracción desacoplada del motor de la base de datos**. Permite a componentes externos (como HAProxy) y a herramientas de administración (`patronictl`) conocer el estado de PostgreSQL y gestionar su ciclo de vida sin necesidad de abrir conexiones SQL.

### Qué SE PUEDE hacer a través de la API:

* **Health Checks de Alta Velocidad:** Exponer endpoints ligeros (`/primary`, `/replica`, `/health`) para que HAProxy sepa en milisegundos a dónde enrutar el tráfico. Deuelven un estado HTTP puro (200 OK o 503 Service Unavailable).
* **Orquestación Manual Dinámica:** Ejecutar tareas administrativas en caliente mediante peticiones POST/PUT (ej. `/reload` para aplicar cambios de `postgresql.conf` sin reiniciar, o `/restart` para programar un reinicio controlado).
* **Control de Emergencia (Modo Pausa):** Congelar la automatización del clúster invocando el endpoint `/pause`. Esto es vital en la banca para realizar mantenimientos mayores sin que Patroni intente hacer un failover falso.
* **Inyección de Configuraciones Globales:** Modificar el comportamiento del clúster en tiempo real editando la llave de configuración centralizada en `etcd` a través del endpoint `/config`.

### Qué NO SE PUEDE hacer a través de la API:

* **Transaccionar Datos:** La API de Patroni no procesa consultas SQL (`SELECT`, `INSERT`). El tráfico de dinero de tu aplicación Fintech viaja estrictamente por el puerto de PostgreSQL (`5432`) o PgBouncer (`6432`).
* **Bypassear el DCS (etcd):** No puedes usar la API para forzar a un nodo a ser maestro si `etcd` dice lo contrario. Si `etcd` está caído o el nodo no tiene el quórum del DCS, la API REST se autoprotege y entra en modo restringido/lectura.
* **Ejecutar Comandos de Sistema Operativo (`root`):** La API solo tiene alcance sobre el ecosistema de PostgreSQL y Patroni. No puedes usarla para reiniciar el servidor físico, alterar interfaces de red o modificar el firewall.
* **Autenticación Multitenant Nativa Avanzada:** La API no cuenta con un sistema nativo de usuarios y roles complejos (RBAC). Se protege mediante certificados TLS mutuos (mTLS). Por seguridad bancaria, **nunca debe ser expuesta a redes públicas**.

 

## 2. ¿Entre nodos Patroni se hablan directamente? (Mecanismo de Comunicación)

La respuesta corta es: **No para tomar decisiones de liderazgo, pero Sí para verificar el estado de los datos.**

Patroni sigue una arquitectura de **"Shared Nothing" (Nada Compartido)** basada en un DCS (`etcd`).

### El Árbitro Central (`etcd`):

Los nodos Patroni no se preguntan entre sí: *"¿Oye, tú eres el maestro?"*. En su lugar, todos los nodos miran constantemente a `etcd`. Quien posea la llave `/service/cluster_name/leader` en el DCS es el maestro legítimo. La comunicación del estado de salud del clúster es **Nodo $\leftrightarrow$ etcd**, nunca Nodo $\leftrightarrow$ Nodo.

### Cuándo SÍ se hablan directamente por API REST:

Existen momentos críticos donde los demonios de Patroni abren conexiones HTTP directas entre sus puertos `8008`:

1. **Durante un Failover/Elección:** Cuando el maestro muere y la llave de líder queda libre, las réplicas sobrevivientes se hablan directamente a través de sus APIs REST para consultar mutuamente sus posiciones exactas del WAL (`pg_catalog.pg_last_wal_replay_lsn()`). Esto lo hacen para asegurar que el nodo que se postule en `etcd` sea realmente el que tiene menos *Lag* (protegiendo el RPO=0).
2. **Durante el Bootstrap (Clonación Inicial):** Cuando una réplica nueva se une al clúster, el Patroni de ese nodo consulta la API del maestro para obtener las credenciales temporales o el flujo para que herramientas como `pg_basebackup` o `pgBackRest` inicien la copia física de los datos.



## 3. ¿Se puede hacer un Switchover desde cualquier nodo y cómo es posible?

**Sí, se puede ejecutar un switchover (mantenimiento programado / cambio de roles controlado) desde absolutamente cualquier nodo del clúster**, e incluso desde una máquina externa de administración, siempre y cuando se cumpla una condición: que la herramienta `patronictl` tenga conectividad hacia el clúster de `etcd` o hacia la API de cualquiera de los nodos.

### ¿Cómo es esto posible? (Flujo Interno)

Cuando un DBA ejecuta el comando desde, por ejemplo, la **Réplica Asíncrona**:

```bash
patronictl -c /etc/patroni/patroni.yml switchover

```

El proceso no ocurre de forma local en ese servidor, sino que sigue una coreografía distribuida:

1. **Interrupción en el DCS:** La herramienta `patronictl` se conecta a `etcd` (o a la API REST local, la cual actúa como proxy) y crea una llave especial de intención de cambio llamada `/service/cluster_name/failover`. En ella especifica el nombre del maestro actual y, opcionalmente, el candidato elegido para ser el nuevo líder (la réplica síncrona).
2. **Recepción en el Maestro:** El Patroni del nodo Maestro (que monitorea activamente a `etcd`) detecta de inmediato la aparición de la llave de switchover.
3. **Paso Abrupto pero Seguro (Graceful Demotion):** El maestro detiene ordenadamente la recepción de nuevas escrituras, realiza un `CHECKPOINT` en PostgreSQL para asegurar que todo esté en disco, espera a que la réplica síncrona reciba los últimos bytes del WAL, cierra sus conexiones y **elimina voluntariamente su llave de líder en etcd**.
4. **Ascenso del Candidato:** El Patroni de la réplica síncrona elegida ve que la llave de líder está libre y que hay una instrucción de switchover activa. Procede a promover su base de datos local a modo `Read-Write` y reclama el trono en `etcd`.
5. **Alineación de Red:** HAProxy detecta el cambio de HTTP 200 en el nuevo endpoint `/primary` y redirige el flujo transaccional.

Gracias a este diseño desacoplado, el DBA no necesita estar logueado físicamente en la máquina del maestro para realizar ventanas de mantenimiento, lo que eleva la seguridad operativa al restringir los accesos directos al nodo de producción más crítico.
