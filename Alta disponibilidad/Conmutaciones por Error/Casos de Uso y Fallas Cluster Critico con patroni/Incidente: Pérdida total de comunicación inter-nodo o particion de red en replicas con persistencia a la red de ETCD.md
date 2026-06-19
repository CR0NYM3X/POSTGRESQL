
### Incidente: Pérdida total de comunicación inter-nodo o particion de red en replicas con persistencia a la red de ETCD.md

* **Condición inicial:** Se corta exclusivamente la red dedicada al tráfico entre los servidores de la base de datos (aislando la replicación de PostgreSQL y las conexiones directas entre nodos). Sin embargo, la red de gestión/administración sigue intacta, lo que significa que **los 3 nodos pueden comunicarse individualmente con el clúster de etcd (DCS)**. No hay una caída de procesos, sino una partición de red selectiva en el plano de datos.

Este escenario es fascinante desde la perspectiva de sistemas distribuidos. Es una **partición de red asimétrica (Data Plane Partition)**. A diferencia de un apagón total, aquí los nodos no están "muertos", simplemente están "ciegos" entre sí, pero siguen teniendo un "árbitro" común (`etcd`).

Para un entorno Fintech con requerimientos estrictos de **RPO = 0** y **RTO = 0**, este tipo de fallos activa las defensas más profundas del motor de la base de datos y del orquestador. Esto es lo que sucede cronológicamente:

---

## 1. Cronología del Fallo y Comportamiento del Clúster

### Fase 1: Estado del Maestro y el Bloqueo Inmediato de Escrituras

* **Persistencia del Liderazgo en etcd:** El nodo Maestro puede hablar con `etcd`, por lo que sigue renovando exitosamente su llave de líder (`/service/cluster_name/leader`). Para `etcd`, el Maestro sigue siendo el rey legítimo.
* **Colapso de la Replicación:** En el motor de PostgreSQL, el proceso maestro nota instantáneamente que las conexiones de sus réplicas (`walsender`) se han cortado abruptamente.
* **El Mecanismo de Salvaguarda Bancaria (SyncRep Lock):** Como tu arquitectura implementa las buenas prácticas de alta disponibilidad síncrona (`synchronous_mode_strict: true`), PostgreSQL **congela inmediatamente todas las transacciones de escritura**. El Maestro no permitirá que ningún `COMMIT` de la aplicación se consolide porque es físicamente incapaz de recibir el ACK de la réplica síncrona.

### Fase 2: Comportamiento de las Réplicas en el Aislamiento

* **Fallo de Sincronización:** Las réplicas (tanto la síncrona como la asíncrona) ven que su proceso `walreceiver` no puede conectarse al puerto `5432` del Maestro.
* **Reporte al DCS:** Los Patroni de las réplicas siguen vivos y reportan su estado a `etcd`. Informan que están saludables como procesos, pero que **han perdido el flujo de replicación** y su *Lag* (retraso de WAL) empieza a crecer de forma indefinida.
* **Bloqueo de Promoción:** Aunque las réplicas ven que el maestro no les envía datos, **ninguna de las dos intentará promoverse a maestro**. ¿Por qué? Porque consultan a `etcd` y el DCS les confirma de forma segura: *"El maestro actual sigue vivo y renovando su contrato de líder"*. Esto elimina por completo el riesgo de un *Split-Brain* (fuerza bruta de dos maestros escribiendo).

### Fase 3: Postura de Seguridad Extrema (Autodegradación)

En la banca, dejar un maestro congelado indefinidamente esperando una réplica muerta puede tumbar las capas de aplicación (saturnismo por conexiones). Si configuraste el clúster con la directiva de alta seguridad de Patroni:

```yaml
demote_on_replica_failure: true

```

* **La Democión Voluntaria:** Al pasar el tiempo límite sin recibir una sola conexión de réplica, Patroni en el Maestro toma la decisión *fail-secure*: **libera voluntariamente la llave de líder en etcd y degrada su propio PostgreSQL local a modo Read-Only**.
* **Resultado en el DCS:** El clúster se queda con 0 maestros. Si una réplica intenta tomar el liderazgo en `etcd`, Patroni bloqueará la elección porque el nodo no cumple con los criterios de sincronía o historial de WAL válidos al no poder comunicarse con el resto. El clúster entero entra en un estado seguro de **Solo Lectura global**.

---

## 2. Impacto en la Capa de Acceso (HAProxy y PgBouncer)

* **HAProxy:** Si los balanceadores de carga HAProxy están en una red que sí puede ver a los nodos (la misma red de `etcd`), interrogarán el puerto `8008` de Patroni.
* Si el Maestro se autodegradó, el endpoint `/primary` devolverá un error `503`. HAProxy cerrará el pool de escrituras.
* Si el Maestro sigue reteniendo el liderazgo congelado, HAProxy lo mantendrá activo, pero las aplicaciones experimentarán una ralentización total (Timeouts) a nivel de base de datos debido al bloqueo de los commits.


* **PgBouncer:** Absorberá el impacto inicial encolando las peticiones de los microservicios bancarios hasta saturar su límite, actuando como un dique de contención para que la ráfaga de reintentos de la aplicación no destruya los sockets del sistema operativo de los nodos de datos.

---

## 3. Estado de los Componentes Periféricos

* **pgAudit:** Excelente comportamiento. Al congelarse las escrituras o pasar el clúster a modo *Read-Only*, toda consulta de lectura que se intente realizar en cualquiera de los tres nodos seguirá siendo auditada de forma local y enviada al syslog centralizado, garantizando que el incidente de red no genere "puntos ciegos" de seguridad.
* **pgBackRest:** Si el proceso de archivado de WALs (`archive_command`) estaba empujando datos a un repositorio externo a través de la red inter-nodo que se rompió, el archivado se detendrá, acumulando los archivos WAL en el directorio `pg_wal` del Maestro. PostgreSQL protegerá estos archivos para no perder el historial de auditoría física hasta que se llene el disco o se recupere la red.

---

## 4. Próximas Pasos Operativos y de Diagnóstico para el DBA (Runbook de Emergencia)

Este es un problema puramente de infraestructura de red (Networking). El DBA debe trabajar en conjunto con el equipo de infraestructura bajo el siguiente procedimiento:

### Paso 1: Diagnóstico de la Partición Asimétrica

El DBA notará un comportamiento extraño: `patronictl list` muestra a los tres nodos en la tabla (porque hay `etcd`), pero la replicación está rota.

```bash
# Ejecutar en el Maestro para confirmar el aislamiento de datos
psql -c "SELECT application_name, state, sync_state FROM pg_stat_replication;"

```

*Si la consulta regresa 0 filas, pero `patronictl list` muestra a los nodos como "running", se confirma el diagnóstico de cable de replicación cortado.*

### Paso 2: Identificar la Interfaz de Red Afectada

Revisar las interfaces de red del servidor asignadas al streaming de datos (por ejemplo, si usas una interfaz dedicada `eth1` para replicación y `eth0` para `etcd`):

```bash
ip route
ping -I eth1 <IP_REPLICA_SINCRONA>

```

*Comprobar caídas de switches virtuales (vSwitch), fallas en el etiquetado de VLANs de datos, o una actualización errónea de políticas en los firewalls perimetrales del Data Center.*

### Paso 3: Mitigación de Emergencia (Si la reparación de red toma horas)

Si el core bancario necesita restablecer las operaciones de escritura de inmediato y el comité de riesgos aprueba operar temporalmente sin alta disponibilidad real (asumiendo un RPO dinámico temporal):

1. Forzar el modo asíncrono temporal en Patroni para desbloquear los commits en el maestro:
```bash
patronictl -c /etc/patroni/patroni.yml edit-config
# Cambiar temporalmente a:
# synchronous_mode: false

```


2. Aplicar los cambios (`patronictl reload`). El Maestro ignorará la ausencia de las réplicas y liberará las transacciones congeladas. La Fintech vuelve a transaccionar, pero en modo de nodo único vulnerable.

### Paso 4: Normalización y Sincronización Post-Incidente

Una vez que el equipo de redes repara el canal inter-nodo:

1. Reactivar el modo síncrono en la configuración si fue desactivado en el paso 3.
2. Patroni reconectará las réplicas. Al haber estado el cable cortado pero los procesos vivos, las réplicas medirán el *Lag* acumulado.
3. Debido a que el Maestro siguió avanzando (o acumuló transacciones), las réplicas utilizarán el streaming nativo de WALs para ponerse al día. Si existió una divergencia de líneas de tiempo por la democión, Patroni ejecutará `pg_rewind` automáticamente para asegurar que las réplicas se acoplen perfectamente sin corrupción de datos.

---

## Resumen Ejecutivo para tu Cliente

> "Si se corta la comunicación de datos entre los servidores pero se mantiene el acceso a `etcd`, la arquitectura entra en un estado de **Aislamiento Seguro (Fail-Secure)**. Gracias a la configuración síncrona estricta de nivel bancario, el Maestro congelará las escrituras de inmediato para garantizar un **RPO = 0**, impidiendo que se pierda la consistencia de los datos. No existirá riesgo de *Split-Brain* porque las réplicas ven en `etcd` que el maestro sigue reclamando el trono. El sistema sacrificará temporalmente la disponibilidad (RTO) bloqueando los commits o degradándose a Solo Lectura, prefiriendo la seguridad del dinero de los clientes sobre la continuidad de una red defectuosa."
