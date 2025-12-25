 
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

# Ver la hora y wal actuales 
psql -p 5598 -c "SELECT 
    CLOCK_TIMESTAMP(), -- Hora
    pg_walfile_name(pg_current_wal_lsn()), -- nombre de wal actual
    pg_current_wal_lsn(), -- LSN del wal actual - Hasta dónde hemos generado WAL (puede estar en memoria ).
    pg_current_wal_flush_lsn() , -- es el ultimo LSN que ha sido flushed (escrito físicamente en disco pg_wal). - Hasta dónde hemos asegurado WAL en disco
    pg_current_wal_insert_lsn(); --  Marca el LSN que se ha insertado en el buffer WAL (aún no garantizado en disco)."

 
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
psql -p 5598 -d test -c "SELECT  pg_xact_commit_timestamp(xmin) as fecha_modifico, pg_xact_commit_timestamp(xmax) as fecha_elimino,* FROM pg_dirtyread('inventarios')  AS t(tableoid oid, ctid tid, xmin xid, xmax xid, cmin cid, cmax cid, dead boolean, id int,producto TEXT , stock INT );"

+-------------------------------+-------------------------------+----------+--------+------+------+------+------+------+----+-----------------+-------+
|        fecha_modifico         |         fecha_elimino         | tableoid |  ctid  | xmin | xmax | cmin | cmax | dead | id |    producto     | stock |
+-------------------------------+-------------------------------+----------+--------+------+------+------+------+------+----+-----------------+-------+
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,1)  |  739 |  752 |    0 |    0 | t    |  1 | Producto_1      |    16 |
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,2)  |  739 |  752 |    0 |    0 | t    |  2 | Producto_2      |    72 |
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,3)  |  739 |  752 |    0 |    0 | t    |  3 | Producto_3      |    89 |
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,4)  |  739 |  752 |    0 |    0 | t    |  4 | Producto_4      |     9 |
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,5)  |  739 |  752 |    0 |    0 | t    |  5 | Producto_5      |    80 |
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,6)  |  739 |  752 |    0 |    0 | t    |  6 | Producto_6      |    17 |
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,7)  |  739 |  752 |    0 |    0 | t    |  7 | Producto_7      |    74 |
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,8)  |  739 |  752 |    0 |    0 | t    |  8 | Producto_8      |    50 |
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,9)  |  739 |  752 |    0 |    0 | t    |  9 | Producto_9      |    66 |
| 2025-12-24 17:37:24.311426-07 | 2025-12-24 17:53:45.880038-07 |    16386 | (0,10) |  739 |  752 |    0 |    0 | t    | 10 | Producto_10     |    16 |
| 2025-12-24 17:37:40.15701-07  | 2025-12-24 17:53:45.880038-07 |    16386 | (0,11) |  740 |  752 |    0 |    0 | t    | 11 | Ultimo_Registro |   999 |
+-------------------------------+-------------------------------+----------+--------+------+------+------+------+------+----+-----------------+-------+
(11 rows)




------------------------------------------------------------------------------------------------------------------------------
------------------------------------------ OPCION #3 [ Revisar los wals ] ---------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

--- NOTA - Es importante colocar el binario correcto del pg_waldump de lo contrario puede marcar el error "pg_waldump: error: could not find a valid record after 0/5000000"

ls -lhtr /sysx/data16/DATANEW/db_productiva/pg_wal
ls -lhtr  /sysx/data16/DATANEW/backup_wal

-- Buscamos el OID de la tabla en este caso es =  16386 
psql -p 5598 -d test -c "SELECT oid, relname  FROM pg_class WHERE relname = 'inventarios';"

--- Aqui buscamos el LSN  que genero el ultimo insert = 0/03007100 
$PGBIN17/pg_waldump /sysx/data16/DATANEW/backup_wal/000000010000000000000003  |  grep 16386 | grep -Ei "INSERT"
rmgr: Heap        len (rec/tot):     54/   738, tx:        740, lsn: 0/03007100, prev 0/030050F0, desc: INSERT off: 11, flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0 FPW


-- aqui le decimos que nos muestre unicamente cuatro lineas despues de lsn 0/03007100 y encontramos la hora que se hizo el insert 2025-12-24 17:37:40.157010
-- Nota si nos damos cuenta la secuencia es en la primera linea lsn: 0/03007100 y en la segunda linea esta como  prev 0/03007100 y luego el lsn: 0/030073E8 el cual se encuentra en la tercera linea como  prev 0/030073E8 asi sucesivamente
$PGBIN17/pg_waldump /sysx/data16/DATANEW/backup_wal/000000010000000000000003 --limit=4 --start=0/03007100
rmgr: Heap        len (rec/tot):     54/   738, tx:        740, lsn: 0/03007100, prev 0/030050F0, desc: INSERT off: 11, flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0 FPW
rmgr: Btree       len (rec/tot):     53/   313, tx:        740, lsn: 0/030073E8, prev 0/03007100, desc: INSERT_LEAF off: 11, blkref #0: rel 1663/16384/16393 blk 1 FPW
rmgr: Transaction len (rec/tot):     34/    34, tx:        740, lsn: 0/03007528, prev 0/030073E8, desc: COMMIT 2025-12-24 17:37:40.157010 MST
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/03007550, prev 0/03007528, desc: RUNNING_XACTS nextXid 741 latestCompletedXid 740 oldestRunningXid 741


--- Tambien podemos buscar los delete en este caso ya se habia rotado el wal por lo que debe estar en el 000000010000000000000004 los delete 
 $PGBIN17/pg_waldump /sysx/data16/DATANEW/backup_wal/000000010000000000000004   |  grep 16386  |   grep -Ei "DELETE"
rmgr: Heap        len (rec/tot):     59/   743, tx:        752, lsn: 0/04000168, prev 0/04000130, desc: DELETE xmax: 752, off: 1, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0 FPW
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/04000450, prev 0/04000168, desc: DELETE xmax: 752, off: 2, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/04000488, prev 0/04000450, desc: DELETE xmax: 752, off: 3, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/040004C0, prev 0/04000488, desc: DELETE xmax: 752, off: 4, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/040004F8, prev 0/040004C0, desc: DELETE xmax: 752, off: 5, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/04000530, prev 0/040004F8, desc: DELETE xmax: 752, off: 6, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/04000568, prev 0/04000530, desc: DELETE xmax: 752, off: 7, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/040005A0, prev 0/04000568, desc: DELETE xmax: 752, off: 8, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/040005D8, prev 0/040005A0, desc: DELETE xmax: 752, off: 9, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/04000610, prev 0/040005D8, desc: DELETE xmax: 752, off: 10, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/04000648, prev 0/04000610, desc: DELETE xmax: 752, off: 11, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0


-- con esto podemos saber que el delete se confirmo en el wal a las 2025-12-24 17:53:45.880038 esto en la segunda linea despues de "desc: COMMIT"
$PGBIN17/pg_waldump /sysx/data16/DATANEW/backup_wal/000000010000000000000004 --limit=4 --start=0/04000648
rmgr: Heap        len (rec/tot):     54/    54, tx:        752, lsn: 0/04000648, prev 0/04000610, desc: DELETE xmax: 752, off: 11, infobits: [KEYS_UPDATED], flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0
rmgr: Transaction len (rec/tot):     34/    34, tx:        752, lsn: 0/04000680, prev 0/04000648, desc: COMMIT 2025-12-24 17:53:45.880038 MST
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/040006A8, prev 0/04000680, desc: RUNNING_XACTS nextXid 753 latestCompletedXid 752 oldestRunningXid 753
rmgr: XLOG        len (rec/tot):     24/    24, tx:          0, lsn: 0/040006E0, prev 0/040006A8, desc: SWITCH



------------------------------------------------------------------------------------------------------------------------------
------------------------------------------ EXTRA [ REVISAR CUANDO SE HIZO EL ULTIMO CHECKPOINT  ] ---------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

psql -X -p 5598 -d test -c "SELECT pg_walfile_name(checkpoint_lsn),checkpoint_lsn,pg_walfile_name(redo_lsn),redo_lsn, checkpoint_time FROM pg_control_checkpoint();"
     pg_walfile_name      | checkpoint_lsn |     pg_walfile_name      | redo_lsn  |    checkpoint_time
--------------------------+----------------+--------------------------+-----------+------------------------
 000000010000000000000005 | 0/500DCC8      | 000000010000000000000005 | 0/500DC38 | 2025-12-24 17:57:25-07
(1 row)


---


```

### 5. Restauración en la Instancia de Pruebas

Configuramos la instancia `db_pruebas` para que se detenga justo después del insert, pero antes del delete.


```bash
# Configurar la recuperación en db_pruebas
echo "
port = 5599
restore_command = 'cp /sysx/data16/DATANEW/backup_wal/%f %p'
recovery_target_time = '2025-12-24 17:50:00' # Aqui podemos poner la fecha del ultimo insert o unos minutos antes de que se ejecutara el delete que fue a las 2025-12-24 17:53:45
# recovery_target_name = 'test_pirt' # Se puede usar si quieres restaurar con algun nombre y usaste la fun pg_create_restore_point
# recovery_target_lsn = '0/03007528' # se coloca el lsn donde se inserto o uno antes del delete 
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
