 
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
pg_ctl -D /sysx/data16/DATANEW/db_productiva start -o "-p 5598" 

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

# Supongamos que el tiempo devuelto es: '2025-12-22 16:52:01.031-07'

# Ver los registros
psql -p 5598 -d test -c "select pg_xact_commit_timestamp(xmin) as fecha_mov,ctid,xmin,xmax,* from inventarios;"

# Crear un punto de restauración 
psql -p 5598 -d test -c "SELECT pg_create_restore_point('test_pirt');"

# 2. IMPORTANTE: Forzar el archivado del WAL actual para que llegue a /backup_wal/
psql -p 5598 -d test -c "SELECT pg_switch_wal();"

# 3. EL INCIDENTE: Borrado accidental
psql -p 5598 -d test -c "DELETE FROM inventarios; "
psql -p 5598  -c "SELECT clock_timestamp();"
# Supongamos que esto ocurrió a las: '2025-12-22 16:53:45.238-07'

# 4. Forzar archivado del WAL del borrado (para que el motor vea el fin de la historia)
psql -p 5598 -d test -c "SELECT pg_switch_wal();"

# Ver los registros
psql -p 5598 -d test -c "select pg_xact_commit_timestamp(xmin) as fecha_mov,ctid,xmin,xmax,* from inventarios;"

```

### Monitorear Log
```
cd /sysx/data16/DATANEW/db_pruebas/log
tail -f postgresql-Mon.log
```

## Fromas de descubrir a que punto en el tiempo restaurar
Existen varias formas de restaurar las cuales pueden ser: Por tiempo, nombre de backup ,  TimeLine, Por LSN o XID
```sql
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------ OPCION #1 [ Revisar el log ] ------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------

-- saber a que hora se inserto el ultimo registro y la hora que se hizo el incidente 
grep -Ei "insert|delete" /sysx/data16/DATANEW/db_productiva/log/postgresql-Tue.log
<2025-12-23 18:48:36 MST [0-12/2] [local] psql test postgres 2313885 694b4674.234e9d idle>LOG:  statement: INSERT INTO inventarios(producto, stock) VALUES ('Ultimo_Registro', 999);
<2025-12-23 18:50:35 MST [0-17/2] [local] psql test postgres 2314381 694b46eb.23508d idle>LOG:  statement: DELETE FROM inventarios;



------------------------------------------------------------------------------------------------------------------------------
------------------------------------------ OPCION #2 [ Extension pg_dirtyread ] ------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- Nos permite hacer lecturas sucias y revisar los registros modificados o eliminados
-- esto se debe hacer antes de que se genere un vaccum de lo contrario se eliminaran y no servira esta opcion

psql -p 5598 -d test -c "CREATE EXTENSION IF NOT EXISTS pageinspect;"
psql -p 5598 -d test -c "CREATE EXTENSION pg_dirtyread;"

-- Obtener el XID con la columna xmin o tener la fecha en la que se modifico en este caso se inserto 
psql -p 5598 -d test -c "SELECT  pg_xact_commit_timestamp(xmin) as fecha_modifico,* FROM pg_dirtyread('inventarios')  AS t(tableoid oid, ctid tid, xmin xid, xmax xid, cmin cid, cmax cid, dead boolean, id int,producto TEXT , stock INT,  fecha_hora TIMESTAMP );"

+-------------------------------+----------+--------+------+------+------+------+------+----+-----------------+-------+----------------------------+
|   pg_xact_commit_timestamp    | tableoid |  ctid  | xmin | xmax | cmin | cmax | dead | id |    producto     | stock |         fecha_hora         |
+-------------------------------+----------+--------+------+------+------+------+------+----+-----------------+-------+----------------------------+
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,1)  |  750 |  752 |    0 |    0 | t    |  1 | Producto_1      |    39 | 2025-12-23 18:47:07.03874  |
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,2)  |  750 |  752 |    0 |    0 | t    |  2 | Producto_2      |    87 | 2025-12-23 18:47:07.038905 |
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,3)  |  750 |  752 |    0 |    0 | t    |  3 | Producto_3      |    98 | 2025-12-23 18:47:07.038914 |
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,4)  |  750 |  752 |    0 |    0 | t    |  4 | Producto_4      |    84 | 2025-12-23 18:47:07.038916 |
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,5)  |  750 |  752 |    0 |    0 | t    |  5 | Producto_5      |    66 | 2025-12-23 18:47:07.038918 |
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,6)  |  750 |  752 |    0 |    0 | t    |  6 | Producto_6      |    54 | 2025-12-23 18:47:07.03892  |
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,7)  |  750 |  752 |    0 |    0 | t    |  7 | Producto_7      |    85 | 2025-12-23 18:47:07.038922 |
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,8)  |  750 |  752 |    0 |    0 | t    |  8 | Producto_8      |    99 | 2025-12-23 18:47:07.038924 |
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,9)  |  750 |  752 |    0 |    0 | t    |  9 | Producto_9      |    13 | 2025-12-23 18:47:07.038926 |
| 2025-12-23 18:47:07.03894-07  |    16390 | (0,10) |  750 |  752 |    0 |    0 | t    | 10 | Producto_10     |    76 | 2025-12-23 18:47:07.038929 |
| 2025-12-23 18:48:36.639435-07 |    16390 | (0,11) |  751 |  752 |    0 |    0 | t    | 11 | Ultimo_Registro |   999 | 2025-12-23 18:48:36.639283 |
+-------------------------------+----------+--------+------+------+------+------+------+----+-----------------+-------+----------------------------+



------------------------------------------------------------------------------------------------------------------------------
------------------------------------------ OPCION #3 [ Revisar los wals ] ---------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

--- NOTA - Es importante colocar el binario correcto del pg_waldump de lo contrario puede marcar el error "pg_waldump: error: could not find a valid record after 0/5000000"

ls -lhtr /sysx/data16/DATANEW/db_productiva/pg_wal
ls -lhtr  /sysx/data16/DATANEW/backup_wal

$PGBIN17/pg_waldump /sysx/data16/DATANEW/backup_wal/000000010000000000000004 | grep 'desc: COMMIT'
rmgr: Transaction len (rec/tot):     34/    34, tx:        752, lsn: 0/040002C8, prev 0/04000290, desc: COMMIT 2025-12-23 18:50:36.001208 MST


$PGBIN17/pg_waldump /sysx/data16/DATANEW/db_productiva/pg_wal/000000010000000000000005 | grep 'desc: COMMIT'

---


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
psql -p 5599 -d test -c "select pg_xact_commit_timestamp(xmin) as fecha_mov,ctid,xmin,xmax,* from inventarios;"

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
