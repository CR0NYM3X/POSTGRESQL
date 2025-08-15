### 🔍 **Causas por las que un slot puede estar reteniendo mucho WAL**

1. **📉 Replicación lenta o pausada**
   - El proceso que consume el slot (como Debezium, pglogical, etc.) está funcionando lentamente o está detenido.
   - Esto hace que PostgreSQL no pueda eliminar los WAL antiguos, ya que el slot aún los necesita.

2. **⏸️ Slot inactivo**
   - El slot está definido pero **no tiene un consumidor activo** (`active = false`).
   - PostgreSQL seguirá reteniendo WAL indefinidamente, lo que puede llenar el disco si no se gestiona.

3. **🔁 Transacciones largas**
   - Si el consumidor del slot está procesando una transacción muy larga, el `restart_lsn` no avanza hasta que se confirme.
   - Esto puede causar acumulación de WAL.

4. **🧱 Problemas de red o conectividad**
   - Si el sistema que consume el slot está en otra red o nube y tiene problemas de conexión, puede retrasarse en leer los datos.

5. **⚙️ Configuración incorrecta**
   - No se han definido límites o alertas para el tamaño del WAL retenido.
   - No se están monitoreando los slots activamente.
  
### 🛠️ ¿Cómo evitar que un slot se vuelva pesado?

- Monitorea regularmente el `restart_lsn` y compáralo con `pg_current_wal_lsn()`.
- Elimina slots inactivos con `SELECT pg_drop_replication_slot('slot_name');` si ya no se usan.
- Asegúrate de que el consumidor esté activo y procesando datos.
- Usa herramientas como `pg_stat_replication` para ver el estado de los consumidores.
- Configura alertas si el WAL retenido supera cierto umbral (por ejemplo, 1 GB).


## 🧠 Análisis de cada función

| Función | ¿Qué mide? | ¿Sirve para medir retraso? | ¿Por qué? |
|--------|-------------|----------------------------|-----------|
| `pg_current_wal_lsn()` | Último LSN visible en el sistema | ✅ Sí | Representa el punto más avanzado del WAL que el sistema reconoce. |
| `pg_current_wal_insert_lsn()` | Último LSN insertado en el WAL (aún no escrito) | ⚠️ No recomendado | Puede incluir datos aún no visibles ni comprometidos. |
| `pg_current_wal_flush_lsn()` | Último LSN confirmado como escrito en disco | ✅ Sí | Representa el punto seguro y duradero del WAL. |


 # Ver retraso de replica standby en KB
 ```
-- Puedes calcular cuántos bytes y  calcular el tamaño del WALs retenido y que puedes dividir entre 1024 para obtener KB.
--  DBAs avanzados prefieren confirmed_flush_lsn para monitoreo en tiempo real.

SELECT
    slot_name,
    plugin,
    slot_type,
    active,
    pg_current_wal_flush_lsn() AS current_flush_lsn,
    confirmed_flush_lsn,
    pg_current_wal_flush_lsn() - confirmed_flush_lsn AS wal_lag_bytes
FROM 
    pg_replication_slots
WHERE 
    confirmed_flush_lsn IS NOT NULL;

-- Administradores de infraestructura usan restart_lsn para evitar problemas de almacenamiento.
SELECT slot_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(),restart_lsn)) AS lag, active from pg_replication_slots WHERE slot_type='logical';



```

# Otras validaciones
```
-- Verifica si el plugin wal2json está instalado
rpm -qla | grep wal2json

-- Verifica si hay procesos de replicación activos
SELECT * FROM pg_stat_wal_receiver; --- comando para ver lo que se recibe y saber cual es el servidor principal
SELECT * FROM pg_stat_replication;  --- comando para ver en el serv principal las ip serv soporte y ver la columna sync_state  puede tener el valor  async  y sync
SELECT slot_name, spill_txns, spill_count, spill_bytes, total_txns, total_bytes FROM pg_stat_replication_slots;



-- Si retorna true, significa que el servidor está en modo standby (réplica).
-- Si retorna false, significa que el servidor es el primario y acepta escrituras
select pg_is_in_recovery();


-- Verifica si hay slots de replicación lógica activos
SELECT slot_name, plugin, slot_type, active, active_pid FROM pg_replication_slots;

	slot_type = physical → Réplica física (streaming)
	slot_type = logical → Réplica lógica
	plugin = wal2json o pgoutput → Lógica
	plugin = (null) → Física

SELECT slot_name, spill_txns, spill_count, spill_bytes, total_txns, total_bytes FROM pg_stat_replication_slots;

-- Verifica si hay procesos de replicación activos
SELECT * FROM pg_stat_wal_receiver; --- comando para ver lo que se recibe y saber cual es el servidor principal
SELECT * FROM pg_stat_replication;  --- comando para ver en el serv principal las ip serv soporte y ver la columna sync_state  puede tener el valor  async  y sync
	write_lag -> Indica cuánto tiempo tarda la réplica en escribir los datos del WAL que recibe desde el primario.
	flush_lag -> Indica cuánto tiempo tarda la réplica en flushear (asegurar en disco) los datos del WAL que ya ha escrito. 
	replay_lag ->  Indica cuánto tiempo tarda la réplica en aplicar los cambios del WAL a las tablas, es decir, que los datos sean realmente visibles para las consultas.

ps -fea | grep walreceiver
ps -fea | grep walsender
ps -fea | grep stream



-- ver los archivos WAL presentes en el servidor
SELECT name,pg_size_pretty(sum(size)) AS size,modification FROM pg_ls_waldir() group by  name,modification;

select * from pg_stat_activity 
select * from pg_stat_progress_basebackup;
SELECT CASE WHEN pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn()   THEN 0  ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp()) END AS log_delay;

SELECT pid, usename, application_name, state
, pg_current_wal_lsn() AS current_lsn
, sent_lsn
, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)) AS sent_diff
, write_lsn
, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), write_lsn)) AS write_diff
, replay_lsn
, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS replay_diff
, write_lag, flush_lag, replay_lag
FROM pg_stat_replication
ORDER BY application_name, pid;



select specific_schema, routine_name  from  information_schema.routines  where routine_name ilike '%wal%';
| pg_catalog      | pg_stat_get_wal_senders       |
| pg_catalog      | pg_stat_get_wal_receiver      |
| pg_catalog      | pg_stat_get_wal               |
| pg_catalog      | pg_current_wal_lsn            |
| pg_catalog      | pg_current_wal_insert_lsn     |
| pg_catalog      | pg_current_wal_flush_lsn      |
| pg_catalog      | pg_walfile_name_offset        |
| pg_catalog      | pg_walfile_name               |
| pg_catalog      | pg_split_walfile_name         |
| pg_catalog      | pg_wal_lsn_diff               |
| pg_catalog      | pg_last_wal_receive_lsn       |
| pg_catalog      | pg_last_wal_replay_lsn        |
| pg_catalog      | pg_is_wal_replay_paused       |
| pg_catalog      | pg_get_wal_replay_pause_state |
| pg_catalog      | pg_get_wal_resource_managers  |
| pg_catalog      | pg_switch_wal                 |
| pg_catalog      | pg_wal_replay_pause           |
| pg_catalog      | pg_wal_replay_resume          |
| pg_catalog      | pg_ls_waldir                  |


select * from pg_control_checkpoint();

```


### 📋 **Funcion de `pg_control_checkpoint()`**

| **Columna**               | **Descripción** |
|---------------------------|-----------------|
| `checkpoint_lsn`          | LSN donde se escribió el último checkpoint en el WAL. |
| `redo_lsn`                | LSN desde donde debe comenzar la recuperación si hay fallo. Puede ser anterior al `checkpoint_lsn`. |
| `redo_wal_file`           | Archivo WAL que contiene el `redo_lsn`. Útil para identificar qué archivo se necesita para recuperación. |
| `timeline_id`             | ID de la línea de tiempo actual. Cambia en eventos como failover. |
| `prev_timeline_id`        | ID de la línea de tiempo anterior. |
| `full_page_writes`        | Indica si se están escribiendo páginas completas en el WAL (`t` = true). Mejora la recuperación ante fallos. |
| `next_xid`                | Próximo ID de transacción que se asignará. |
| `next_oid`                | Próximo OID (Object Identifier) que se asignará a objetos como tablas. |
| `next_multixact_id`       | Próximo ID de multitransacción (usado en bloqueos compartidos). |
| `next_multi_offset`       | Offset dentro del multixact actual. |
| `oldest_xid`              | ID de transacción más antigua que aún puede afectar el sistema (usado para VACUUM). |
| `oldest_xid_dbid`         | ID de la base de datos que contiene el `oldest_xid`. |
| `oldest_active_xid`       | ID de la transacción activa más antigua. |
| `oldest_multi_xid`        | ID de multitransacción más antigua aún relevante. |
| `oldest_multi_dbid`       | ID de la base de datos que contiene el `oldest_multi_xid`. |
| `oldest_commit_ts_xid`    | ID de transacción más antigua con marca de tiempo de commit. |
| `newest_commit_ts_xid`    | ID de transacción más reciente con marca de tiempo de commit. |
| `checkpoint_time`         | Fecha y hora en que se realizó el último checkpoint. |

 
## 📊 Tabla `pg_replication_slots`

Esta tabla contiene información sobre los **slots de replicación**, que son mecanismos para retener WAL hasta que los consumidores (como réplicas o procesos de análisis) lo hayan leído.

### 📌 Descripción de columnas

| Columna | Tipo | Descripción |
|--------|------|-------------|
| `slot_name` | `name` | Nombre único del slot de replicación. |
| `plugin` | `name` | Nombre del plugin usado (solo en replicación lógica). |
| `slot_type` | `text` | Tipo de slot: `physical` o `logical`. |
| `datoid` | `oid` | OID de la base de datos asociada (solo en lógica). |
| `database` | `name` | Nombre de la base de datos (solo lógica). |
| `temporary` | `boolean` | Si el slot es temporal (se elimina al cerrar la sesión). |
| `active` | `boolean` | Si el slot está siendo usado actualmente. |
| `active_pid` | `integer` | PID del proceso que lo está usando (si está activo). |
| `xmin` | `xid` | Mínimo XID retenido por el slot (solo lógica). |
| `catalog_xmin` | `xid` | Mínimo XID del catálogo retenido (solo lógica). |
| `restart_lsn` | `pg_lsn` | Punto desde el cual se puede reiniciar la replicación. |
| `confirmed_flush_lsn` | `pg_lsn` | Último LSN confirmado por el consumidor (solo lógica). |

 
 
## 📊 Tabla: `pg_stat_wal_receiver`

Esta vista muestra el estado del proceso que **recibe los WAL desde el servidor primario** en una réplica física.

### 📌 Descripción de columnas

| Columna | Tipo | Descripción |
|--------|------|-------------|
| `pid` | `integer` | ID del proceso del receptor WAL. |
| `status` | `text` | Estado actual del receptor (`streaming`, `stopped`, etc.). |
| `receive_start_lsn` | `pg_lsn` | LSN donde comenzó a recibir datos. |
| `receive_start_tli` | `integer` | Timeline ID donde comenzó la recepción. |
| `written_lsn` | `pg_lsn` | Último LSN escrito en disco por el receptor. |
| `flushed_lsn` | `pg_lsn` | Último LSN confirmado como escrito en disco. |
| `received_lsn` | `pg_lsn` | Último LSN recibido desde el primario. |
| `latest_end_lsn` | `pg_lsn` | Último LSN reportado por el primario como disponible. |
| `latest_end_time` | `timestamp with time zone` | Hora del último LSN disponible en el primario. |
| `slot_name` | `text` | Nombre del slot de replicación usado (si aplica). |
| `sender_host` | `text` | IP o hostname del servidor primario. |
| `sender_port` | `integer` | Puerto del servidor primario. |
| `conninfo` | `text` | Cadena de conexión usada para conectarse al primario. |
| `sync_priority` | `integer` | Prioridad de sincronización (si hay múltiples réplicas). |
| `sync_state` | `text` | Estado de sincronización: `async`, `sync`, `quorum`. |



## 📊 Tabla: `pg_stat_replication`

Esta vista muestra el estado de las **réplicas conectadas al servidor primario**.

### 📌 Descripción de columnas

| Columna | Tipo | Descripción |
|--------|------|-------------|
| `pid` | `integer` | ID del proceso de backend que maneja la réplica. |
| `usesysid` | `oid` | ID del rol que inició la conexión de replicación. |
| `usename` | `name` | Nombre del rol que inició la conexión. |
| `application_name` | `text` | Nombre de la aplicación (configurado en `primary_conninfo`). |
| `client_addr` | `inet` | Dirección IP del cliente (réplica). |
| `client_hostname` | `text` | Hostname del cliente (si está disponible). |
| `client_port` | `integer` | Puerto del cliente. |
| `backend_start` | `timestamp with time zone` | Hora en que se inició el proceso de backend. |
| `backend_xmin` | `xid` | Mínimo XID retenido por el backend (replicación lógica). |
| `state` | `text` | Estado actual: `streaming`, `catchup`, `startup`, etc. |
| `sent_lsn` | `pg_lsn` | Último LSN enviado al cliente. |
| `write_lsn` | `pg_lsn` | Último LSN escrito por el cliente. |
| `flush_lsn` | `pg_lsn` | Último LSN confirmado como escrito por el cliente. |
| `replay_lsn` | `pg_lsn` | Último LSN que el cliente ha aplicado. |
| `write_lag` | `interval` | Diferencia entre `sent_lsn` y `write_lsn`. |
| `flush_lag` | `interval` | Diferencia entre `sent_lsn` y `flush_lsn`. |
| `replay_lag` | `interval` | Diferencia entre `sent_lsn` y `replay_lsn`. |
| `sync_priority` | `integer` | Prioridad de sincronización. |
| `sync_state` | `text` | Estado de sincronización: `async`, `sync`, `quorum`. |





