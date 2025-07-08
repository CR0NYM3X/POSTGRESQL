
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

 
## 🔄 Flujo resumido del proceso PITR

1. 🔧 **Configuras PostgreSQL** para que archive los WALs (`archive_mode = on`).
2. 📸 **Tomas un backup base** con `pg_basebackup` y lo guardas en un lugar seguro.
3. 🔁 **PostgreSQL sigue funcionando** y generando archivos WAL que se copian a un directorio externo.
4. 💥 Si ocurre un desastre, **restauras el backup base**.
5. 🕰 Luego, **PostgreSQL reproduce los WALs** hasta el punto en el tiempo que tú defines (`recovery_target_time`).
6. ✅ El sistema queda en el estado exacto que tenía en ese momento.

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
| Directorio de WALs archivados    | `/sysx/data16/DATANEW/PITR/backup_wal`                 |
| Backup base (pg_basebackup)      | `/sysx/data16/DATANEW/base_backup`                     |

---

###   Configuración y ejecución del laboratorio

#### 1.   Configura el `postgresql.conf`

Ubicado en `/sysx/data16/DATANEW/PITR/postgresql.conf`:

```conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /sysx/data16/DATANEW/PITR/backup_wal/%f'
max_wal_senders = 5
wal_keep_size = 512MB
```

Crea carpeta de WALs:

```bash
mkdir -p /sysx/data16/DATANEW/PITR/backup_wal
chown postgres:postgres /sysx/data16/DATANEW/PITR/backup_wal
```

Reinicia PostgreSQL:

```bash
/usr/pgsql-16/bin/pg_ctl restart -D /sysx/data16/DATANEW/PITR
```

---

#### 2.   Crear backup base

```bash
/usr/pgsql-16/bin/pg_basebackup -D /sysx/data16/DATANEW/base_backup -F p -U replication -Xs -P -v -h localhost
```

Asegúrate de tener la variable de entorno `PGPASSWORD` o `.pgpass` configurada para la autenticación.

---

#### 3.  Forzar archivo de WAL
Fuerza a PostgreSQL a cerrar el archivo WAL actual y comenzar uno nuevo, incluso si el archivo actual no está lleno.
Garantiza que el archivo WAL actual se archive completamente, útil para que el backup esté consistente.
```bash
psql -U postgres -c "SELECT pg_switch_wal();"
```

---

#### 4.   Simular desastre

```bash
sudo systemctl stop postgresql-16
rm -rf /sysx/data16/DATANEW/PITR/*
```

---

#### 5.   Restaurar con PITR

Copia el backup al directorio de datos:

```bash
cp -r /sysx/data16/DATANEW/base_backup/* /sysx/data16/DATANEW/PITR/
```

Crea `recovery.signal`:

```bash
touch /sysx/data16/DATANEW/PITR/recovery.signal
```

Agrega en `postgresql.auto.conf` o `postgresql.conf`:

```conf
restore_command = 'cp /sysx/data16/DATANEW/PITR/backup_wal/%f %p'
recovery_target_time = '2025-07-08 08:00:00'  # ⏰ Ajusta según tu objetivo
```

Permisos:

```bash
chown -R postgres:postgres /sysx/data16/DATANEW/PITR
```

Inicia la base:

```bash
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/PITR
```

Verifica estado:

```bash
psql -U postgres -c "SELECT pg_is_in_recovery();"
```

 
## 🧪 Generar y validar datos antes y después del PITR

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
INSERT INTO laboratorio_pitr (nombre, creado_en) VALUES
('registro_1', '2025-07-08 07:45:00'),
('registro_2', '2025-07-08 07:50:00'),
('registro_3', '2025-07-08 08:05:00');  -- Este debería desaparecer si haces PITR a las 08:00
```

 

### 3.  Validar antes del desastre

```sql
SELECT * FROM laboratorio_pitr ORDER BY id;
```

Deberías ver los tres registros.

 

### 4.  Simular desastre y aplicar PITR

Haz PITR con:

```conf
recovery_target_time = '2025-07-08 08:00:00'
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



```

 
---


### Info Extra
```
-- Fuerza a PostgreSQL a cerrar el archivo WAL actual y comenzar uno nuevo, incluso si el archivo actual no está lleno. Garantiza que el archivo WAL actual se archive completamente, útil para que el backup esté consistente.
pg_switch_wal()

-- te permite reanudar la recuperación si PostgreSQL se detuvo en un punto específico (por ejemplo, al alcanzar recovery_target_time con recovery_target_action = 'pause').
pg_wal_replay_resume()
```
