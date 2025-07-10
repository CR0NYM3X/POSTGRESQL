
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
wal_level = replica
archive_mode = on
archive_command = 'cp %p /sysx/data16/DATANEW/backup_wal/%f'
max_wal_senders = 5
wal_keep_size = 512MB
port=5599
```

 

Iniciar PostgreSQL:

```bash
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/PITR
```

 
#### 2.  Forzar archivo de WAL
Fuerza a PostgreSQL a cerrar el archivo WAL actual y comenzar uno nuevo, incluso si el archivo actual no está lleno.
Garantiza que el archivo WAL actual se archive completamente, útil para que el backup esté consistente.
```bash


SELECT now(),pg_walfile_name(pg_current_wal_lsn()),pg_current_wal_lsn(),pg_current_wal_insert_lsn();
-- Asegurar que el archivo WAL que marca el inicio del respaldo sea archivado inmediatamente y se cree el .backup
SELECT pg_switch_wal();
SELECT now(),pg_walfile_name(pg_current_wal_lsn()),pg_current_wal_lsn(),pg_current_wal_insert_lsn();
```

#### 3.   Crear backup base

```bash
 /usr/pgsql-16/bin/pg_basebackup -D /sysx/data16/DATANEW/backup_base -F p -U postgres -Xs -P -v -h 127.0.0.1 -p 5519
```

Asegúrate de tener la variable de entorno `PGPASSWORD` o `.pgpass` configurada para la autenticación.

 


 
# 🧪 Generar y validar datos antes y después del PITR

### 1.   Crear tabla de prueba

Antes de hacer el backup base:

```sql
CREATE TABLE laboratorio_pitr (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    creado_en TIMESTAMP DEFAULT now()
);
```

 

### 2.   Insertar datos de prueba

Inserta algunos registros con marcas de tiempo distintas:

```sql
-- Insertar a la 1pm 
INSERT INTO laboratorio_pitr (nombre, creado_en) VALUES
('registro_1', '2025-07-08 07:45:00'),
('registro_2', '2025-07-08 07:50:00');


postgres@postgres# SELECT now(),pg_walfile_name(pg_current_wal_lsn()),pg_current_wal_lsn(),pg_current_wal_insert_lsn();
+-------------------------------+--------------------------+--------------------+
|              now              |     pg_walfile_name      | pg_current_wal_lsn |
+-------------------------------+--------------------------+--------------------+
| 2025-07-10 11:36:33.027786-07 | 000000010000000000000004 | 0/4031EE8          |
+-------------------------------+--------------------------+--------------------+

SELECT pg_create_restore_point('punto_laboratorio');

-- ejecutar  después de insertar   datos y te ayuda a forzar que se archive el WAL donde está ese evento importante, y puedas usarlo como referencia durante la recuperación.
postgres@postgres# SELECT pg_switch_wal();
+---------------+
| pg_switch_wal |
+---------------+
| 0/4031F00     |
+---------------+
postgres@postgres# SELECT now(),pg_walfile_name(pg_current_wal_lsn()),pg_current_wal_lsn(),pg_current_wal_insert_lsn();
+-------------------------------+--------------------------+--------------------+
|              now              |     pg_walfile_name      | pg_current_wal_lsn |
+-------------------------------+--------------------------+--------------------+
| 2025-07-10 11:36:35.582515-07 | 000000010000000000000004 | 0/5000000          |
+-------------------------------+--------------------------+--------------------+



```

 

### 3.  Validar antes del desastre

```sql
postgres@postgres# SELECT * FROM laboratorio_pitr ORDER BY id;
+----+------------+---------------------+
| id |   nombre   |      creado_en      |
+----+------------+---------------------+
|  1 | registro_1 | 2025-07-08 07:45:00 |
|  2 | registro_2 | 2025-07-08 07:50:00 |
+----+------------+---------------------+
```

Deberías ver los dos registros.

 
 

 

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
restore_command = 'cp /sysx/data16/DATANEW/backup_wal/%f %p'
recovery_target_time = '2025-07-08 08:00:00'  # ⏰ Ajusta según tu objetivo
# recovery_target_lsn = 'BBE/697CACC0' # Esto si quiere restaurar un lsn en especifico
# recovery_target_name = 'punto_laboratorio' # Se puede usar si quieres restaurar con algun nombre y usaste la fun pg_create_restore_point
recovery_target_action = 'promote'
recovery_target_timeline = '1'

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
psql -U postgres -c "SELECT pg_is_in_recovery();"
```

Salida del log 
```

2025-07-10 12:04:16.558 MST [455015] LOG:  starting PostgreSQL 16.9 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-26), 64-bit
2025-07-10 12:04:16.560 MST [455015] LOG:  listening on IPv6 address "::1", port 5519
2025-07-10 12:04:16.560 MST [455015] LOG:  listening on IPv4 address "127.0.0.1", port 5519
2025-07-10 12:04:16.561 MST [455015] LOG:  listening on Unix socket "/run/postgresql/.s.PGSQL.5519"
2025-07-10 12:04:16.563 MST [455015] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5519"
2025-07-10 12:04:16.566 MST [455019] LOG:  database system was interrupted while in recovery at log time 2025-07-10 11:59:27 MST
2025-07-10 12:04:16.566 MST [455019] HINT:  If this has occurred more than once some data might be corrupted and you might need to choose an earlier recovery target.
cp: cannot stat '/sysx/data16/DATANEW/backup_wal/00000002.history': No such file or directory
2025-07-10 12:04:16.612 MST [455019] LOG:  starting point-in-time recovery to "punto_laboratorio"
2025-07-10 12:04:16.628 MST [455019] LOG:  restored log file "000000010000000000000003" from archive
2025-07-10 12:04:16.647 MST [455019] LOG:  redo starts at 0/3000028
2025-07-10 12:04:16.665 MST [455019] LOG:  restored log file "000000010000000000000004" from archive
2025-07-10 12:04:16.679 MST [455019] LOG:  consistent recovery state reached at 0/3000100
2025-07-10 12:04:16.679 MST [455015] LOG:  database system is ready to accept read-only connections
2025-07-10 12:04:16.697 MST [455019] LOG:  restored log file "000000010000000000000005" from archive
cp: cannot stat '/sysx/data16/DATANEW/backup_wal/000000010000000000000006': No such file or directory
2025-07-10 12:04:16.719 MST [455019] LOG:  recovery stopping at restore point "punto_laboratorio", time 2025-07-10 11:59:47.693563-07
2025-07-10 12:04:16.719 MST [455019] LOG:  redo done at 0/4031E70 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.07 s
2025-07-10 12:04:16.719 MST [455019] LOG:  last completed transaction was at log time 2025-07-10 11:59:38.623946-07
2025-07-10 12:04:16.735 MST [455019] LOG:  restored log file "000000010000000000000004" from archive
cp: cannot stat '/sysx/data16/DATANEW/backup_wal/00000002.history': No such file or directory
2025-07-10 12:04:16.756 MST [455019] LOG:  selected new timeline ID: 2
cp: cannot stat '/sysx/data16/DATANEW/backup_wal/00000001.history': No such file or directory
2025-07-10 12:04:16.796 MST [455019] LOG:  archive recovery complete
2025-07-10 12:04:16.797 MST [455017] LOG:  checkpoint starting: end-of-recovery immediate wait
2025-07-10 12:04:16.805 MST [455017] LOG:  checkpoint complete: wrote 56 buffers (0.3%); 0 WAL file(s) added, 0 removed, 1 recycled; write=0.004 s, sync=0.002 s, total=0.009 s; sync files=43, longest=0.001 s, average=0.001 s; distance=16583 kB, estimate=16583 kB; lsn=0/4031ED8, redo lsn=0/4031ED8
2025-07-10 12:04:16.811 MST [455015] LOG:  database system is ready to accept connections
```


 

### 5.   Validar después del PITR

Una vez que PostgreSQL arranque tras la recuperación:

```sql
SELECT * FROM laboratorio_pitr ORDER BY id;
```

**Resultado esperado:**

| id | nombre      | creado_en           |
|----|-------------|---------------------|
| 1  | registro_1  | 2025-07-08 07:45:00 |
| 2  | registro_2  | 2025-07-08 07:50:00 |

> El `registro_3` **no debería aparecer**, ya que fue insertado después del `recovery_target_time`.

---

# borrar datos del laboratorio 
```bash
rm -r /sysx/data16/DATANEW/backup_base 
rm -r /sysx/data16/DATANEW/backup_wal 
rm -r /sysx/data16/DATANEW/PITR
```


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
