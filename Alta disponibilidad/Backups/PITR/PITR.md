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

--- 

###  ¿Qué contiene `pg_wal/archive_status`?
Esta carpeta guarda **archivos de estado** que indican si un segmento WAL ha sido archivado correctamente o no y no contienen información.

- **`*.ready`** → El archivo WAL está **listo para ser archivado**.
- **`*.done`** → El archivo WAL **ya fue archivado con éxito**.

Por ejemplo:
```bash
000000010000000000000002.ready
000000010000000000000003.done
```


###  ¿Cómo se usa en el proceso de archivado?

1. Cuando se llena un archivo WAL, PostgreSQL crea un archivo `*.ready` en `pg_wal/archive_status`.
2. El proceso de archivado (`archive_command`) se ejecuta y copia el archivo WAL al destino configurado.
3. Si el comando tiene éxito (retorna 0), PostgreSQL cambia el archivo a `*.done`.
4. Si falla, el archivo `*.ready` permanece y PostgreSQL lo volverá a intentar más tarde.

###  ¿Por qué es importante?

- Permite a PostgreSQL **saber qué archivos ya fueron archivados** y cuáles aún están pendientes.
- Evita que se **reciclen o eliminen archivos WAL** antes de ser archivados.
- Es esencial para **Point-in-Time Recovery (PITR)** y replicación.

---



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
