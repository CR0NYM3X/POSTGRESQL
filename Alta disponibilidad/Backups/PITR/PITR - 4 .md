 
### 1. Preparación del Entorno

Limpia y prepara las rutas necesarias.

```bash
clear
clear
# Detener servicios si existen
pg_ctl stop -D /sysx/data16/DATANEW/db_productiva
pg_ctl stop -D /sysx/data16/DATANEW/db_pruebas

# Limpiar y crear directorios
rm -r /sysx/data16/DATANEW/*
mkdir -p /sysx/data16/DATANEW/{db_productiva,db_pruebas,backup_wal}

```

### 2. Configuración e Inicio de la Instancia Productiva

Inicializa la base de datos y configura el archivado de logs.

```bash
initdb -D /sysx/data16/DATANEW/db_productiva --data-checksums

# Configurar parámetros críticos de PITR
echo "
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /sysx/data16/DATANEW/backup_wal/%f && cp %p /sysx/data16/DATANEW/backup_wal/%f'
port = 5598
track_commit_timestamp = on
log_line_prefix = '<%t [%x-%v] %r %a %d %u %p %c %i>'
logging_collector = on
log_min_messages  = 'warning'
log_min_error_statement = 'warning'
log_statement = 'all'
" >> /sysx/data16/DATANEW/db_productiva/postgresql.auto.conf

# Iniciar
pg_ctl -D /sysx/data16/DATANEW/db_productiva start -o "-p 5598" start

```

### 3. Generación de Datos y Backup Base

Crea la tabla y realiza el backup que servirá como semilla para la recuperación.

```bash
# Crear datos iniciales
psql -p 5598 -c "CREATE DATABASE test;"
psql -p 5598 -d test -c "
CREATE TABLE inventarios (id SERIAL PRIMARY KEY, producto TEXT NOT NULL, stock INT, fecha_hora TIMESTAMP DEFAULT clock_timestamp());
INSERT INTO inventarios(producto, stock) SELECT 'Producto_' || i, (random()*100)::INT FROM generate_series(1,10) AS i;
"

# Generar el Backup Base (Semilla)
pg_basebackup -h localhost -p 5598 -U postgres -D /sysx/data16/DATANEW/db_pruebas -Fp -Xs -P -c fast -v

```

### 4. Simulación del Incidente (Punto Crítico)

Aquí es donde registramos el tiempo exacto antes de la "catástrofe".

```bash
# ver la transacción actual 
SELECT txid_current();

# 1. Insertar registro que queremos salvar (Ultimo_Registro)
psql -p 5598 -d test -c "INSERT INTO inventarios(producto, stock) VALUES ('Ultimo_Registro', 999);"
psql -p 5598  -c "SELECT clock_timestamp();"
# Supongamos que el tiempo devuelto es: '2025-12-22 16:52:01.031-07'

# Ver los registros
psql -p 5598 -d test -c "select * from inventarios;"

# Crear un punto de restauración 
SELECT pg_create_restore_point('test_pirt');

# 2. IMPORTANTE: Forzar el archivado del WAL actual para que llegue a /backup_wal/
psql -p 5598 -d test -c "SELECT pg_switch_wal();"

# 3. EL INCIDENTE: Borrado accidental
psql -p 5598 -d test -c "DELETE FROM inventarios; SELECT clock_timestamp();"
# Supongamos que esto ocurrió a las: '2025-12-22 16:53:45.238-07'

# 4. Forzar archivado del WAL del borrado (para que el motor vea el fin de la historia)
psql -p 5598 -d test -c "SELECT pg_switch_wal();"

# Ver los registros
psql -p 5598 -d test -c "select * from inventarios;"

```

### Monitorear Log
```
cd /sysx/data16/DATANEW/db_pruebas/log
tail -f postgresql-Mon.log
```

## Fromas de descubrir a que punto en el tiempo restaurar
Existen varias formas de restaurar las cuales pueden ser: Por tiempo, nombre de backup ,  TimeLine, Por LSN o XID
```sql
psql -p 5599 -d test -c "SELECT pg_xact_commit_timestamp(xmin) as fecha_mov,xmin as XID, * FROM inventarios WHERE producto='Ultimo_Registro';"

pg_waldump /sysx/data16/DATANEW/backup_wal/000000010000000000000004 | grep 'desc: COMMIT'

psql -p 5598 -c "CREATE EXTENSION IF NOT EXISTS pageinspect;"
psql -p 5598 -c "CREATE EXTENSION pg_dirtyread;"
SELECT  pg_xact_commit_timestamp(xmin),* FROM pg_dirtyread('inventarios')  AS t(tableoid oid, ctid tid, xmin xid, xmax xid, cmin cid, cmax cid, dead boolean, id int,producto TEXT , stock INT,  fecha_hora TIMESTAMP );

```

### 5. Restauración en la Instancia de Pruebas

Configuramos la instancia `db_pruebas` para que se detenga justo después del insert, pero antes del delete.


```bash
# Configurar la recuperación en db_pruebas
echo "
port = 5599
restore_command = 'cp /sysx/data16/DATANEW/backup_wal/%f %p'
recovery_target_time = '2025-12-22 16:52:01.031-07' # Aqui va la fecha del ultimo insert
# recovery_target_name = 'test_pirt' # Se puede usar si quieres restaurar con algun nombre y usaste la fun pg_create_restore_point
# recovery_target_lsn = 'BBE/697CACC0' # Esto si quiere restaurar un lsn en especifico
# recovery_target_xid = ''
# recovery_target_timeline = '1'
# recovery_target_action = 'promote'


hot_standby = on
" >> /sysx/data16/DATANEW/db_pruebas/postgresql.auto.conf

# Crear archivo de señal para que PostgreSQL sepa que debe recuperar
touch /sysx/data16/DATANEW/db_pruebas/recovery.signal

# Iniciar la instancia de pruebas
pg_ctl -D /sysx/data16/DATANEW/db_pruebas start

```

6. Verificación de Resultados 

Si el laboratorio es exitoso, al consultar la base de datos en el puerto **5599**, el registro "Ultimo_Registro" debe existir y los demás datos deben estar presentes, ignorando el `DELETE`.

```bash
# Revisar registros
psql -p 5599 -d test -c "SELECT * FROM inventarios WHERE producto = 'Ultimo_Registro';"

# Revisar si esta en modo recuperación [ t = modo recuperación. | f = la recuperación ya terminó y el servidor fue promovido ]
psql -p 5599 -d test -c "SELECT pg_is_in_recovery();" 


ls -lhtr /sysx/data16/DATANEW/db_productiva/pg_wal
ls -lhtr /sysx/data16/DATANEW/db_pruebas/pg_wal
ls -lhtr /sysx/data16/DATANEW/backup_wal/
```


---




# ....
### 
```sql
```
