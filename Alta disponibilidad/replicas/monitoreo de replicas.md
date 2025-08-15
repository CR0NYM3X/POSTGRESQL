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
  
   

 # Ver retraso de replica standby en KB
 ```
-- Puedes calcular cuántos bytes y  calcular el tamaño del WALs retenido y que puedes dividir entre 1024 para obtener KB.
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

