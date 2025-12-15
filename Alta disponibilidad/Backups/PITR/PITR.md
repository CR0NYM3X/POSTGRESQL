
##   ¿Qué es exactamente PITR en PostgreSQL?

**PITR (Point-In-Time Recovery)** es una técnica de recuperación que permite restaurar una base de datos PostgreSQL a un momento específico en el pasado. Es especialmente útil para:

- Recuperarse de errores humanos (como un `DROP TABLE`)
- Revertir cambios no deseados
- Restaurar tras corrupción o fallos

 
##   ¿Cómo funciona PITR?

PITR se basa en **dos componentes esenciales**:

| Componente         | Descripción                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| **Backup base**    | Una copia completa del directorio de datos (`data_directory`) en un momento determinado. Se hace **una sola vez** como punto de partida. |
| **Archivos WAL**   | Archivos de registro de transacciones (**Write-Ahead Logs**) que PostgreSQL genera constantemente. Se deben **archivar de forma continua** para poder reproducir los cambios posteriores al backup base. |

 
## 🔁 **Flujo de PITR (Recuperación a un Punto en el Tiempo)**

### 🧱 Etapas del flujo de PITR:

1. 📦 **Backup base completo**
   - Se toma con `pg_basebackup` o similar.
   - Refleja el estado completo del clúster.

2. 🔁 **Archivado continuo de WALs**
   - PostgreSQL guarda todos los cambios incrementales en los WALs.
   - Se configuran con `archive_mode` y `archive_command`.

3. 💥 **Ocurre un incidente**
   - Puede ser corrupción, error humano, eliminación de datos, etc.

4. 🧯 **Restaura el backup base**
   - Se reestablecen los archivos del backup en un nuevo data_directory.

5. ▶️ **Reproduce los WALs hasta el punto deseado**
   - PostgreSQL aplica los cambios hasta el `recovery_target_time` configurado.

6. ✅ **Promociona el clúster**
   - Una vez alcanzado el punto objetivo, se elimina `recovery.signal` y el sistema vuelve a estar en producción.

---


### ¿Qué pasa al iniciar el servicio en modo recuperación?

- PostgreSQL **entra en modo recuperación** y comienza a **reproducir los archivos WAL** desde el backup base hasta el punto de recuperación que definiste (`recovery_target_time`, por ejemplo).
- Durante este proceso:
  - El servidor **no acepta conexiones de escritura**.
  - Puede aceptar **conexiones de solo lectura**, pero **solo si ya alcanzó un estado consistente** (esto depende de la configuración y del momento exacto del WAL replay).
  - El sistema **no está completamente restaurado** hasta que se alcanza el punto objetivo.

 

###  ¿Cuándo se considera “restaurado”?

- Cuando PostgreSQL alcanza el `recovery_target_time`, ejecuta la acción definida en `recovery_target_action` (como `promote`).
- En ese momento:
  - El servidor **sale del modo recuperación**.
  - Se **promueve** y comienza a aceptar conexiones normales (lectura y escritura).
  - Se elimina el archivo `recovery.signal` automáticamente.

---
###  **Conclusión del problema**
El error se generó "FATAL: recovery ended before configured recovery target was reached y mensajes de `cannot stat` para WAL faltantes."

1.  **`recovery_target_time` inalcanzable**
    *   El tiempo solicitado (`12:51:29`) era **anterior al checkpoint del backup** (12:51:36) y al LSN inicial del `pg_basebackup`.
    *   En PITR, solo puedes avanzar **hacia adelante** desde el punto donde inicia la recuperación (redo LSN). Nunca retroceder.

2.  **Falta de segmentos WAL posteriores al backup**
    *   Después del backup, realizaste operaciones (`INSERT 'Ultimo_Registro'` y `DELETE`) pero **no se archivó el WAL actual** porque no se llenó el segmento.
	*    siempre procura finalizar con un pg_switch_wal() lo cual finaliza el wal actual sin importar si se lleno los 16MB y usa otro 
    *   Sin el archivo `00000003`, el servidor no puede reproducir esos cambios ni alcanzar el tiempo deseado.


---

# Laboratorio 


##   Laboratorio PITR con PostgreSQL 16 — Rutas 100% personalizadas

### 📁 Estructura de rutas

| Propósito                         | Ruta                                                  |
|----------------------------------|--------------------------------------------------------|
| Binarios de PostgreSQL           | `/usr/pgsql-16/bin`                                    |
| Directorio de datos activo       | `/sysx/data16/DATANEW/PITR`                            |
| Directorio de WALs archivados    | `/sysx/data16/DATANEW/backup_wal`                 |
| Backup base (pg_basebackup)      | `/sysx/data16/DATANEW/backup_base`                     |

### Crear directorios y agregarlo como dueño
```
mkdir -p /sysx/data16/DATANEW/backup_base 
mkdir -p /sysx/data16/DATANEW/backup_wal 
mkdir -p /sysx/data16/DATANEW/PITR

chown postgres:postgres /sysx/data16/DATANEW/backup_base 
chown postgres:postgres  /sysx/data16/DATANEW/backup_wal 
chown postgres:postgres  /sysx/data16/DATANEW/PITR
```

### Iniciar el DATA
```
/usr/pgsql-16/bin/initdb -E UTF-8 -D /sysx/data16/DATANEW/PITR --data-checksums
```


###   Configuración y ejecución del laboratorio

#### 1.   Configura el `postgresql.conf`

Ubicado en `/sysx/data16/DATANEW/PITR/postgresql.conf`:

```conf
echo "
wal_level = replica
archive_mode = on
archive_command = 'cp %p /sysx/data16/DATANEW/backup_wal/%f'
max_wal_senders = 5
wal_keep_size = 512MB
port=5599
" >>  /sysx/data16/DATANEW/PITR/postgresql.auto.conf
```

 

Iniciar PostgreSQL:

```bash
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/PITR
```

 
#### 2.  Forzar archivo de WAL
Fuerza a PostgreSQL a cerrar el archivo WAL actual y comenzar uno nuevo, incluso si el archivo actual no está lleno.
Garantiza que el archivo WAL actual se archive completamente, útil para que el backup esté consistente.
```bash


SELECT CLOCK_TIMESTAMP(),pg_walfile_name(pg_current_wal_lsn()),pg_current_wal_lsn(),pg_current_wal_insert_lsn();
-- Asegurar que el archivo WAL que marca el inicio del respaldo sea archivado inmediatamente y se cree el .backup
SELECT pg_switch_wal();
SELECT CLOCK_TIMESTAMP(),pg_walfile_name(pg_current_wal_lsn()),pg_current_wal_lsn(),pg_current_wal_insert_lsn();
```

#### 3.   Crear backup base

```bash
 /usr/pgsql-16/bin/pg_basebackup -D /sysx/data16/DATANEW/backup_base -F p -U postgres -Xs -P -v -h 127.0.0.1 -p 5599 -c fast
```

Asegúrate de tener la variable de entorno `PGPASSWORD` o `.pgpass` configurada para la autenticación.

 


 
# 🧪 Generar y validar datos antes y después del PITR

### 1.   Crear tabla de prueba

Antes de hacer el backup base:

```sql
CREATE TABLE wal_tracking (
    id SERIAL PRIMARY KEY,
    fecha TIMESTAMP NOT NULL,
    wal_file_name TEXT NOT NULL,
    wal_lsn TEXT NOT NULL,
    wal_insert_lsn TEXT NOT NULL,
    pg_current_wal_flush_lsn  TEXT NOT NULL
);
```

 

### 2.   Insertar datos de prueba

Inserta algunos registros con marcas de tiempo distintas:

```sql
-- Insertar a la 1pm 

INSERT INTO wal_tracking (fecha, wal_file_name, wal_lsn, wal_insert_lsn,pg_current_wal_flush_lsn)
SELECT 
    CLOCK_TIMESTAMP(),
    pg_walfile_name(pg_current_wal_lsn()),
    pg_current_wal_lsn(),
    pg_current_wal_insert_lsn(),
    pg_current_wal_flush_lsn()
	FROM generate_series(1, 5) AS gs where pg_sleep(5) is not null;
	
postgres@postgres# select * from wal_tracking;
+----+----------------------------+--------------------------+-----------+----------------+--------------------------+
| id |           fecha            |      wal_file_name       |  wal_lsn  | wal_insert_lsn | pg_current_wal_flush_lsn |
+----+----------------------------+--------------------------+-----------+----------------+--------------------------+
|  1 | 2025-07-10 14:20:00.121288 | 000000010000000000000003 | 0/302FEA0 | 0/302FEA0      | 0/302FEA0                |
|  2 | 2025-07-10 14:20:05.126869 | 000000010000000000000003 | 0/3030078 | 0/3030078      | 0/3030078                |
|  3 | 2025-07-10 14:20:10.132004 | 000000010000000000000003 | 0/3030078 | 0/3030138      | 0/3030078                |
|  4 | 2025-07-10 14:20:15.137129 | 000000010000000000000003 | 0/3030078 | 0/30301F8      | 0/3030078                |
|  5 | 2025-07-10 14:20:20.140877 | 000000010000000000000003 | 0/30302F0 | 0/30302F0      | 0/30302F0                |
+----+----------------------------+--------------------------+-----------+----------------+--------------------------+
(5 rows)


SELECT pg_create_restore_point('punto_laboratorio');

-- ejecutar  después de insertar   datos y te ayuda a forzar que se archive el WAL donde está ese evento importante, y puedas usarlo como referencia durante la recuperación.
postgres@postgres# SELECT pg_switch_wal();
+---------------+
| pg_switch_wal |
+---------------+
| 0/3078AD0     |
+---------------+
(1 row)


postgres@postgres# SELECT CLOCK_TIMESTAMP(),pg_walfile_name(pg_current_wal_lsn()),pg_current_wal_lsn(),pg_current_wal_insert_lsn(),pg_current_wal_flush_lsn();
+-------------------------------+--------------------------+--------------------+---------------------------+--------------------------+
|        clock_timestamp        |     pg_walfile_name      | pg_current_wal_lsn | pg_current_wal_insert_lsn | pg_current_wal_flush_lsn |
+-------------------------------+--------------------------+--------------------+---------------------------+--------------------------+
| 2025-07-10 14:20:57.542894-07 | 000000010000000000000004 | 0/4000060          | 0/4000060                 | 0/4000060                |
+-------------------------------+--------------------------+--------------------+---------------------------+--------------------------+
(1 row)


 
pg_walfile_name()  convierte un LSN (Log Sequence Number) en el nombre del archivo físico WAL correspondiente.
pg_current_wal_lsn() te dirá el punto desde donde empezará la próxima escritura.
pg_current_wal_insert_lsn() te muestra hasta dónde ya se insertaron los datos en la memoria.
pg_current_wal_flush_lsn() te muestra hasta dónde esos datos ya están escritos en el disco duro (persistencia completa).

```

 
 
#  Simular desastre

# Deneter el servico y borrar el DATA
```bash
# Deneter el servicio
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/PITR

# Borrar los directorios del DATA de postgresql
rm -r /sysx/data16/DATANEW/PITR/*
```


#### 2.   Restaurar con PITR

Copia el backup al directorio de datos:

```bash
cp -r /sysx/data16/DATANEW/backup_base/* /sysx/data16/DATANEW/PITR/
```

Crea `recovery.signal`:

```bash
touch /sysx/data16/DATANEW/PITR/recovery.signal
```

Agrega en `postgresql.auto.conf` o `postgresql.conf`:

```conf
echo "
restore_command = 'cp /sysx/data16/DATANEW/backup_wal/%f %p'
recovery_target_time = '2025-07-10 14:20:05.126869'  # ⏰ Ajusta según tu objetivo
# recovery_target_lsn = 'BBE/697CACC0' # Esto si quiere restaurar un lsn en especifico
# recovery_target_name = 'punto_laboratorio' # Se puede usar si quieres restaurar con algun nombre y usaste la fun pg_create_restore_point
recovery_target_action = 'promote'
recovery_target_timeline = '1'
" >>  /sysx/data16/DATANEW/PITR/postgresql.auto.conf
```

Permisos:

```bash
chown -R postgres:postgres /sysx/data16/DATANEW/PITR
```

en otra terminal monitorear el log 
```bash
  tail -f /sysx/data16/DATANEW/PITR/log/postgresql-Thu.log
```



Inicia la base:

```bash
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/PITR
```

Verifica estado:

```bash
psql -p 5599 -U postgres -c "SELECT pg_is_in_recovery();"
```

Salida del log 
```
2025-07-10 14:23:12.196 MST [496327] LOG:  starting PostgreSQL 16.9 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-26), 64-bit
2025-07-10 14:23:12.199 MST [496327] LOG:  listening on IPv6 address "::1", port 5599
2025-07-10 14:23:12.199 MST [496327] LOG:  listening on IPv4 address "127.0.0.1", port 5599
2025-07-10 14:23:12.200 MST [496327] LOG:  listening on Unix socket "/run/postgresql/.s.PGSQL.5599"
2025-07-10 14:23:12.202 MST [496327] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5599"
2025-07-10 14:23:12.206 MST [496331] LOG:  database system was interrupted; last known up at 2025-07-10 14:19:06 MST
2025-07-10 14:23:12.242 MST [496331] LOG:  starting point-in-time recovery to 2025-07-10 14:20:05.126869-07
2025-07-10 14:23:12.242 MST [496331] LOG:  starting backup recovery with redo LSN 0/2000028, checkpoint LSN 0/2000060, on timeline ID 1
2025-07-10 14:23:12.259 MST [496331] LOG:  restored log file "000000010000000000000002" from archive
2025-07-10 14:23:12.278 MST [496331] LOG:  redo starts at 0/2000028
2025-07-10 14:23:12.295 MST [496331] LOG:  restored log file "000000010000000000000003" from archive
2025-07-10 14:23:12.307 MST [496331] LOG:  completed backup recovery with redo LSN 0/2000028 and end LSN 0/2000100
2025-07-10 14:23:12.307 MST [496331] LOG:  consistent recovery state reached at 0/2000100
2025-07-10 14:23:12.307 MST [496327] LOG:  database system is ready to accept read-only connections
2025-07-10 14:23:12.309 MST [496331] LOG:  recovery stopping before commit of transaction 731, time 2025-07-10 14:20:20.140998-07
2025-07-10 14:23:12.309 MST [496331] LOG:  redo done at 0/30303B0 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.03 s
2025-07-10 14:23:12.309 MST [496331] LOG:  last completed transaction was at log time 2025-07-10 14:19:18.956055-07
cp: cannot stat '/sysx/data16/DATANEW/backup_wal/00000002.history': No such file or directory
2025-07-10 14:23:12.315 MST [496331] LOG:  selected new timeline ID: 2
cp: cannot stat '/sysx/data16/DATANEW/backup_wal/00000001.history': No such file or directory
2025-07-10 14:23:12.353 MST [496331] LOG:  archive recovery complete
2025-07-10 14:23:12.354 MST [496329] LOG:  checkpoint starting: end-of-recovery immediate wait
2025-07-10 14:23:12.363 MST [496329] LOG:  checkpoint complete: wrote 55 buffers (0.3%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.004 s, sync=0.002 s, total=0.010 s; sync files=43, longest=0.001 s, average=0.001 s; distance=16576 kB, estimate=16576 kB; lsn=0/30303B0, redo lsn=0/30303B0
2025-07-10 14:23:12.368 MST [496327] LOG:  database system is ready to accept connections
```



### 5.   Validar después del PITR

Una vez que PostgreSQL arranque tras la recuperación:

```sql
psql -p 5599 -U postgres -c "SELECT * FROM wal_tracking ORDER BY id;"
```
 

---

# borrar datos del laboratorio 
```bash
rm -r /sysx/data16/DATANEW/backup_base 
rm -r /sysx/data16/DATANEW/backup_wal 
rm -r /sysx/data16/DATANEW/PITR
```


# Extra información
```
pg_controldata -D /sysx/data16/DATANEW/PITR

postgres@lvt-pruebas-dba-cln /sysx/data16/DATANEW $ cat backup_wal/000000010000000000000002.00000028.backup
START WAL LOCATION: 0/2000028 (file 000000010000000000000002)
STOP WAL LOCATION: 0/2000100 (file 000000010000000000000002)
CHECKPOINT LOCATION: 0/2000060
BACKUP METHOD: streamed
BACKUP FROM: primary
START TIME: 2025-07-10 18:29:47 MST
LABEL: pg_basebackup base backup
START TIMELINE: 1
STOP TIME: 2025-07-10 18:29:47 MST
STOP TIMELINE: 1

postgres@lvt-pruebas-dba-cln /sysx/data16/DATANEW $ cat backup_wal/00000004.history
1 0/4030378     before 2025-07-10 18:30:45.455757-07

SELECT * from  pg_control_checkpoint(); -- Validar información sobre el último checkpoint registrado en el archivo pg_control 
SELECT * from   pg_control_recovery(); -- detalles sobre la configuración de recuperación usada durante el último arranque del clúster. si ya se recupero no devolverá nada
```

---

 
### 🗂️ Archivo `.backup`

- 🔹 Se genera automáticamente cuando ejecutas un **`pg_basebackup`** con la opción de streaming WAL (`-Xs`).
- 🔹 Marca **el punto exacto en el WAL** donde inicia un respaldo base.
- 🔹 Sirve para que PostgreSQL sepa **dónde empezar a aplicar los WALs** durante una recuperación.

 **Sin este archivo, PITR puede fallar** si no hay un punto de inicio válido para el proceso de recuperación.

---

### 🗂️ Archivos `.history`

- 🔹 Se generan cuando hay un **cambio de línea de tiempo (timeline)**. Por ejemplo, al promover un servidor en recuperación.
- 🔹 Contienen información sobre **cómo se dividieron las líneas de tiempo** y cuál era la anterior.
- 🔹 Ayudan a PostgreSQL a entender la evolución de los WALs en escenarios de replicación o PITR avanzados.

 **Es útil en recuperaciones donde se necesita seguir una timeline específica**, como `recovery_target_timeline = 'latest'`.



- `000000010000000000000003.backup` → punto donde comenzó el backup base.
- `00000002.history` → el sistema fue promovido al timeline 2.

---




---

# Como validar si ya se restauro.

### 1. Usa `pg_is_in_recovery()`

Ejecuta esta consulta:

```sql
SELECT pg_is_in_recovery();
```

- Si devuelve `TRUE`, el servidor **sigue en modo recuperación**.
- Si devuelve `FALSE`, la recuperación **ya terminó** y el servidor fue promovido.

###  2. Revisa los logs del servidor

Busca mensajes como:

- `recovery stopping before commit of transaction...`
- `pausing at the end of recovery`
- `database system is ready to accept connections`

Puedes usar:

```bash
tail -n 100 /ruta/a/pg_log/postgresql.log
```

Esto te mostrará si el servidor alcanzó el `recovery_target_time` y si se promovió automáticamente.


###  3. Verifica si el archivo `recovery.signal` aún existe

Si el archivo `recovery.signal` **ya no está en el directorio de datos**, significa que PostgreSQL **salió del modo recuperación**.

```bash
ls /sysx/8850696_V2/data/recovery.signal
```

- Si **no existe**, la recuperación terminó.
- Si **existe**, el servidor sigue en recuperación.



###  4. Consulta el estado de promoción

Si usaste `recovery_target_action = 'promote'`, PostgreSQL debería haberse promovido automáticamente al alcanzar el punto deseado. Pero si configuraste `pause`, entonces debes ejecutar manualmente:

```sql

SELECT pg_wal_replay_resume(); -- sirve para reanudar la reproducción de los archivos WAL (Write-Ahead Log) cuando el servidor está en modo recuperación y ha sido pausado.
pg_wal_replay_pause() -- para detener temporalmente la reproducción de WAL.
```

--- 

## Como buscar si se tienen los wal de una fecha o hora 
```
ls -lh /sysx/8850696_V2/pg_backup/ | grep "23:00"
SELECT name, size, modification FROM pg_ls_waldir();
SELECT * FROM pg_ls_dir('pg_wal/archive_status') WHERE pg_ls_dir ~ '^[0-9A-F]{24}\\.ready$';
```

## Monitorear el archivado 
```
SELECT * FROM pg_stat_archiver;
ls /sysx/data/pg_wal/archive_status/
```



Para el recovery se puede utlizar esto 

# Parametros importantes 
```
postgres@postgres# select name,setting from pg_settings where name ilike '%recov%';
+-----------------------------+---------+
|            name             | setting |
+-----------------------------+---------+
| log_recovery_conflict_waits | off     |
| recovery_end_command        |         |
| recovery_init_sync_method   | fsync   |
| recovery_min_apply_delay    | 0       |
| recovery_prefetch           | try     |
| recovery_target             |         |
| recovery_target_action      | pause   |
| recovery_target_inclusive   | on      |
| recovery_target_lsn         |         |
| recovery_target_name        |         |
| recovery_target_time        |         |
| recovery_target_timeline    | latest  |
| recovery_target_xid         |         |
| trace_recovery_messages     | log     |
+-----------------------------+---------+
(14 rows)

postgres=# select name,setting from pg_settings where name ilike '%archive%';
+---------------------------+------------+
|           name            |  setting   |
+---------------------------+------------+
| archive_cleanup_command   |            |
| archive_command           | (disabled) |
| archive_library           |            |
| archive_mode              | off        |
| archive_timeout           | 0          |
| max_standby_archive_delay | 30000      |
+---------------------------+------------+
(6 rows)


postgres@postgres#  select name,setting,context from pg_settings where name ilike '%wal%' order by context;
+-------------------------------+-----------+------------+
|             name              |  setting  |  context   |
+-------------------------------+-----------+------------+
| wal_segment_size              | 16777216  | internal   |
| wal_block_size                | 8192      | internal   |
| wal_log_hints                 | off       | postmaster |
| wal_level                     | replica   | postmaster |
| max_wal_senders               | 10        | postmaster |
| wal_buffers                   | 2048      | postmaster |
| wal_writer_flush_after        | 128       | sighup     |
| max_wal_size                  | 2048      | sighup     |
| min_wal_size                  | 1024      | sighup     |
| wal_keep_size                 | 0         | sighup     |
| wal_receiver_status_interval  | 10        | sighup     |
| wal_receiver_timeout          | 60000     | sighup     |
| wal_retrieve_retry_interval   | 5000      | sighup     |
| wal_sync_method               | fdatasync | sighup     |
| wal_writer_delay              | 200       | sighup     |
| max_slot_wal_keep_size        | -1        | sighup     |
| wal_receiver_create_temp_slot | off       | sighup     |
| wal_init_zero                 | on        | superuser  |
| wal_consistency_checking      |           | superuser  |
| wal_compression               | off       | superuser  |
| wal_recycle                   | on        | superuser  |
| wal_skip_threshold            | 2048      | user       |
| wal_sender_timeout            | 60000     | user       |
+-------------------------------+-----------+------------+
```

---

## 🗂️ Estructura recomendada para organizar tus backups

```bash
/backup_base/
├── 2025/
│   ├── 07/
│   │   ├── 01/
│   │   │   └── base.tar.gz
│   │   ├── 15/
│   │   │   └── base.tar.gz
│   │   └── wal/
│   │       ├── 01/
│   │       ├── 02/
│   │       └── ...
│   └── 08/
│       └── ...
```

### ¿Qué contiene cada carpeta?

- `/backup_base/2025/07/01/` → Backup base del 1 de julio
- `/backup_base/2025/07/wal/01/` → WALs generados el 1 de julio
- `/backup_base/2025/07/wal/02/` → WALs del 2 de julio, y así sucesivamente

## Contexto de tu infraestructura

- Tienes un **servidor PostgreSQL (origen)** y un **servidor central de respaldo (destino)** con mucho almacenamiento.
- El directorio en el servidor de respaldo es: `/mnt/backup/backup_base/`.
- Quieres copiar cada WAL en cuanto se genera, usando `scp`.

 

##   Requisitos previos

Antes de configurar el `archive_command`, asegúrate de:

1. Tener acceso SSH sin contraseña desde el servidor PostgreSQL hacia el servidor central:
   - Genera las claves:
     ```bash
     ssh-keygen -t rsa
     ssh-copy-id postgres@servidor-respaldo
     ```

2. Que el usuario de PostgreSQL (`postgres`) tenga permisos para ejecutar `scp`.

3. Que el directorio remoto exista: `/mnt/backup/backup_base/wal/YYYY-MM-DD/`



##  Diseño del `archive_command` con clasificación por fecha

Usaremos una solución intermedia: un script local que organiza por fecha y hace el `scp`.

###   `/usr/local/bin/archive_wal_scp.sh`

```bash
#!/bin/bash

# Variables
FECHA=$(date +%F)
ARCHIVO="$1"
DESTINO="$2"

# Extrae solo el nombre del archivo WAL
FNAME=$(basename "$ARCHIVO")

# Ruta remota
REMOTE_DIR="postgres@servidor-respaldo:/mnt/backup/backup_base/wal/${FECHA}"

# Enviar archivo
scp "$ARCHIVO" "$REMOTE_DIR/$FNAME"
```

Dale permisos de ejecución:

```bash
chmod +x /usr/local/bin/archive_wal_scp.sh
```

---

##  Configuración del `archive_command` en `postgresql.conf`

```conf
archive_mode = on
archive_command = '/usr/local/bin/archive_wal_scp.sh %p %f'
```

> ✅ `%p` es la ruta local del WAL generado  
> ✅ `%f` es solo el nombre del archivo WAL, útil para clasificar


# cron para que cree subcarpetas con fecha para pg_basebackup:

```bash
DATE=$(date +\%Y/\%m/\%d)
DEST="/mnt/backup/backup_base/${DATE}"
mkdir -p "$DEST"
pg_basebackup -D "$DEST" -F tar -U replication -Xs -P
```


---


## ⚠️ Desventajas de usar `scp` directo en `archive_command`

###   1. **Bloqueo si hay lentitud en la red**
- PostgreSQL **espera a que `archive_command` termine** antes de marcar el WAL como archivado.
- Si hay **latencia**, caídas o lentitud en la red, el archivo WAL no se considera archivado, y eso puede:
  - Llenar el `pg_wal` y bloquear nuevas escrituras
  - Generar retrasos o detener el motor

> Esto es **crítico** si tienes alto volumen de escritura.

 

###  2. **Sin reintentos ni verificación automática**
- `scp` **no tiene lógica de reintentos** por sí solo.
- Si por cualquier razón el envío falla, **PostgreSQL volverá a intentar**, pero no sabrá si el archivo se subió incompleto o no.
- No hay verificación de checksum ni confirmación de integridad.

 

###  3. **Sin control de concurrencia ni gestión de archivos**
- Si múltiples archivos WAL se envían a la vez:
  - Puedes saturar la conexión SSH
  - Tienes múltiples procesos `scp` abiertos
- No tienes control de rotación, limpieza o índice de respaldo.

 

###  4. **Escalabilidad limitada**
- Funciona bien en entornos pequeños.
- Pero en bases de datos con mucha actividad de escritura y múltiples WAL por minuto, puede volverse un cuello de botella.
- Herramientas especializadas como **pgBackRest** o **Barman** solucionan este problema con buffers, verificación de archivos, y recuperación eficiente.

 

##  ¿Alternativas?

| Opción           | Ventajas                                                  |
|------------------|-----------------------------------------------------------|
| `rsync` en tareas batch | Permite sincronizar varias WALs en una sola operación |
| `pgBackRest`      | Reintentos automáticos, compresión, cifrado, retención   |
| `wal-g`           | Envío asíncrono, integración con cloud (S3, etc)         |

 

##  En resumen

> Usar `scp` dentro del `archive_command` es simple y funcional, pero **no es resiliente** ni escalable por sí solo.  
> Es mejor usarlo solo si:  
> - Tienes baja carga de escritura  
> - Red confiable y rápida  
> - Supervisas constantemente el resultado


---

## ¿Qué es una timeline en PostgreSQL?

Cada vez que un servidor en recuperación es **promovido** (se convierte en primario), PostgreSQL inicia una **nueva línea de tiempo**. Esto se hace para evitar conflictos con WALs anteriores y mantener un historial claro de eventos.

Ejemplo:  
- Timeline 1: base original  
- Timeline 2: recuperación o promoción  
- Timeline 3: otro failover o restauración  
Esto se refleja en los archivos `.history` y en los nombres WAL, como `00000002.history` o `000000010000000000000005`.
 

##   ¿Para qué sirve `recovery_target_timeline`?

Cuando realizas una recuperación, PostgreSQL necesita saber **hasta qué línea de tiempo debe leer los archivos WAL**. Si no lo especificas correctamente, podrías quedarte corto en archivos o terminar en una timeline equivocada.

 

##   Valores posibles

| Valor                      | ¿Qué hace?                                                                 |
|----------------------------|----------------------------------------------------------------------------|
| `'latest'`                | 🧭 Recupera usando la **última línea de tiempo disponible** en los archivos `.history`. Útil si hubo promociones o réplicas. |
| `'current'`               | 🕒 Recupera **usando la misma línea de tiempo** en la que se hizo el backup base. No sigue `.history`. |
| `'N'` (por ejemplo `'1'`) | 🔢 Recupera en la **timeline específica N**. Necesitas el archivo `0000000N.history` en `restore_command`. |


###   Recomendaciones

- Si tu entorno es simple (solo un backup y un set de WALs), puedes usar `'current'`.
- Si has hecho **recuperaciones múltiples** o promociones de servidores, mejor usa `'latest'`.
- Si estás haciendo restauración en clústeres distribuidos o escenarios avanzados, puedes usar un número específico (pero asegúrate de tener el `.history` correspondiente archivado).

--- 

## ✅ `recovery_target_action = 'pause'`

###  ¿Qué hace?

- Detiene la recuperación **justo al llegar al punto indicado**.
- El servidor queda en **modo recuperación suspendida**, no se promueve, no acepta escrituras.
- Sirve para **verificar el estado antes de continuar**, revisar registros, hacer auditoría o decidir si quieres avanzar más.

### ¿Cuándo usarlo?

- Si estás haciendo restauraciones exploratorias o forenses.
- Cuando quieres validar si un dato ya existe sin consolidar la promoción.
- si vas hacer varias restauraciones con los mismos wal.

 

## ✅ `recovery_target_action = 'promote'`

###  ¿Qué hace?

- Promueve automáticamente el servidor una vez que llega al punto de recuperación.
- Elimina el archivo `recovery.signal`.
- Cambia de línea de tiempo.
- El servidor empieza a aceptar **escrituras**, es considerado normal.

###  ¿Cuándo usarlo?

- Una vez que encontraste el momento ideal de recuperación.
- Quieres dejar el clúster en funcionamiento como primario.
- Estás listo para salir del modo recuperación definitivamente.

---



### Info Extra
```
-- Fuerza a PostgreSQL a cerrar el archivo WAL actual y comenzar uno nuevo, incluso si el archivo actual no está lleno. Garantiza que el archivo WAL actual se archive completamente, útil para que el backup esté consistente.
pg_switch_wal()

-- te permite reanudar la recuperación si PostgreSQL se detuvo en un punto específico (por ejemplo, al alcanzar recovery_target_time con recovery_target_action = 'pause').
pg_wal_replay_resume()
```




## Bibliografias
```
https://www.highgo.ca/2021/10/01/postgresql-14-continuous-archiving-and-point-in-time-recovery/
https://www.highgo.ca/2023/05/09/various-restoration-techniques-using-postgresql-point-in-time-recovery/
https://www.highgo.ca/2020/10/01/postgresql-wal-archiving-and-point-in-time-recovery/
https://medium.com/@dickson.gathima/pitr-in-postgresql-using-pg-basebackup-and-wal-6b5c4a7273bb
https://shivendrasingh243.medium.com/postgresql-backup-point-in-time-recovery-e5b3527a94b2
https://medium.com/@sajawalhamza252/unlocking-data-consistency-with-postgres-14-lsn-based-point-in-time-recovery-a-comprehensive-guide-22b46ca567eb
https://blog.devgenius.io/setup-continuous-archiving-and-point-in-time-recovery-pitr-with-postgresql-db-7e670523e8e4
https://www.pivert.org/point-in-time-recovery-pitr-of-postgresql-database/
https://github.com/MBmousavi/PostgreSQL-Point-In-Time-Recovery
https://habr.com/ru/companies/otus/articles/786216/
https://www.youtube.com/watch?v=4az6P3ePQ8E
https://www.youtube.com/watch?v=qRvlJUUPpKU



```
