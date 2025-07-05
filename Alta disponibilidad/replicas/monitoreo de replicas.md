### Estructura del WAL

- **Segmentos WAL**:  
  Cada archivo WAL tiene un tamaño fijo (por defecto **16 MB**) y se almacena en el directorio `pg_wal/`.

- **Nombre del archivo**:  
  Los archivos tienen nombres como `00000001000000000000000A`, que representan:
  - Número de línea de tiempo
  - Número de archivo lógico
  - Número de segmento

- **Registros WAL**:  
  Dentro de cada segmento hay múltiples registros WAL que describen operaciones como `INSERT`, `UPDATE`, `DELETE`, `COMMIT`, etc.

- **Log Sequence Number (LSN)**:  
  Cada registro tiene un identificador único llamado **LSN**, que indica su posición en el WAL. Ejemplo: `0/3000020`.

---

###  ¿Cómo se almacena?

- Los registros WAL se escriben primero en **buffers en memoria**.
- Al hacer `COMMIT`, se **flushean** (escriben) al disco en el archivo WAL.
- Luego, PostgreSQL aplica los cambios a los archivos de datos reales.

Esto permite que, en caso de caída del sistema, se puedan **reproducir los cambios** desde el WAL y recuperar el estado exacto.

---

###  ¿Cómo se interpreta?

- PostgreSQL interpreta los WAL durante:
  - **Recuperación** (por ejemplo, después de un crash o en PITR).
  - **Replicación** (streaming entre primario y réplica).
- Cada registro contiene:
  - Tipo de operación (`XLOG_INSERT`, `XLOG_UPDATE`, etc.)
  - Página afectada
  - Datos modificados
- Puedes inspeccionar los WAL con herramientas como:
  ```bash
  pg_waldump /ruta/al/archivo_wal
  ```

---



### ¿Qué es `pg_waldump`?

Es una utilidad de línea de comandos que permite **ver el contenido de los archivos WAL en formato legible para humanos**. Es ideal para depurar, auditar o entender qué transacciones ocurrieron en un segmento específico.

---

### Ejemplo básico de uso

Supongamos que tienes un archivo WAL llamado `00000001000000000000000A` en tu directorio `pg_wal`. Puedes inspeccionarlo así:

```bash
pg_waldump /ruta/a/pg_wal/00000001000000000000000A
```

Esto mostrará una lista de registros como:

```
rmgr: Heap        len (rec/tot):  54/  54, tx: 1234, lsn: 0/3000020, desc: INSERT off 3
rmgr: Transaction len (rec/tot):  34/  34, tx: 1234, lsn: 0/3000050, desc: COMMIT
```

---

### Opciones útiles

| Opción | Descripción |
|--------|-------------|
| `--start=LSN` | Comienza a leer desde un LSN específico |
| `--end=LSN`   | Detiene la lectura en un LSN específico |
| `--limit=N`   | Muestra solo N registros |
| `--rmgr=Heap` | Filtra por tipo de operación (ej. Heap, Transaction, Btree) |
| `--timeline=N` | Inspecciona una línea de tiempo específica |

Ejemplo para ver solo los primeros 10 registros:

```bash
pg_waldump --limit=10 /ruta/a/pg_wal/00000001000000000000000A
```


-----------------

 

###  Estructura del nombre de un archivo WAL

Un archivo WAL típico tiene un nombre como:

```
00000001000000760000007D
```

Este nombre está compuesto por **24 caracteres hexadecimales** divididos en tres partes:

| Parte | Longitud | Significado |
|-------|----------|-------------|
| `00000001` | 8 dígitos | **Timeline ID** (línea de tiempo) |
| `00000076` | 8 dígitos | **Número de archivo lógico alto** |
| `0000007D` | 8 dígitos | **Número de segmento dentro del archivo lógico** |

---

### ️ ¿Qué es cada parte?

- **Timeline ID (`00000001`)**  
  Identifica la línea de tiempo actual. Cambia cuando haces una recuperación o promoción. Es útil para distinguir entre ramas de historia en la base de datos.

- **Número lógico alto (`00000076`)**  
  Representa la parte alta del **Log Sequence Number (LSN)**. Cada archivo WAL cubre 16 MB, y este número indica en qué parte de la secuencia estás.

- **Número de segmento (`0000007D`)**  
  Es la parte baja del LSN. Junto con el número lógico alto, define la posición exacta del archivo en la secuencia.

---

###  ¿Cómo saber la secuencia actual?

Puedes usar esta consulta para ver el LSN actual:

```sql
SELECT pg_current_wal_lsn();
```

Ejemplo de resultado:

```
76/7D000028
```

Esto significa:
- `76` → parte alta del LSN
- `7D000028` → parte baja

Para convertir esto en nombre de archivo WAL:

```sql
SELECT pg_walfile_name(pg_current_wal_lsn());
```

Resultado:

```
00000001000000760000007D
```

###  ¿Cómo se interpreta la secuencia?

- Los archivos WAL se generan secuencialmente.
- Si tienes varios archivos como:
  ```
  00000001000000760000007D
  00000001000000760000007E
  00000001000000760000007F
  ```
  Estás viendo una progresión en el segmento (`7D`, `7E`, `7F`...).

- Cuando el segmento llega a `FFFFFFFF`, el número lógico alto (`76`) se incrementa.



 # Ver retraso de replica standby en KB
 ```
---  Esto te da el retraso en bytes de una replica, que puedes dividir entre 1024 para obtener KB.
 SELECT application_name,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS delay_bytes
FROM pg_stat_replication;

--Puedes calcular cuántos bytes
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

--------
### Validar walls  
herramienta para ver que es lo que contiene los wall 
 
pg_waldump  --- 
pg_waldump /var/lib/pgsql/data/pg_wal/0000000100000002000000C9


Saber hasta dónde se ha escrito (pg_current_wal_lsn())
Hasta dónde se ha flusheado (pg_current_wal_flush_lsn())
Hasta dónde se ha replicado (pg_last_wal_receive_lsn())

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


----------- herramientas
https://github.com/CR0NYM3X/POSTGRESQL/blob/main/pg_wal%20y%20transacciones.md#3-pg_archivecleanup
pg_archivecleanup


********** SOLUCION RAPIDA **********
# pg_resetwal :  partir de PostgreSQL 10 , se utiliza para restablecer los archivos WAL, borrando los archivos wall, Este comando es útil en situaciones
# específicas donde los archivos WAL se han corrompido o  Es una herramienta de último recurso para intentar que un servidor de base de datos dañado vuelva a arrancar
# pg_resetxlog : hasta la versión 9.6 tiene el mismo objetivo que pg_resetwal

pg_resetwal -f -D /sysx/data
pg_resetxlog -f -D  /sysx/data


********** Alternativa **********
1.- Se ejecuta este comando para validar el el utimo archivo wal en uso
/rutabinario/bin/pg_controldata -D /rutadata/data | grep "REDO WAL"
 
 
2.- (A partir de que se le indica el último wal utilizado, hace la depuración de forma
regresiva para los archivos ya leídos pero que seguían conservando.) 
Una vez que se obtiene el dato se ejecuta el siguiente comando:

/rutabinario/bin/pg_archivecleanup /RUTADIRECTORIOWAL/0000000100000440000000E9



¿Qué hacen realmente?
pg_backup_start(): Marca el inicio del respaldo en el WAL y prepara el servidor para que puedas copiar los archivos del clúster de forma segura.

pg_backup_stop(): Marca el final del respaldo y asegura que todos los cambios estén registrados.

```
