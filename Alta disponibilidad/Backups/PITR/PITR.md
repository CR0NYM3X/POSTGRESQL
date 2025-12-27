
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


### Tipos de archivados?
* **archive_command:** Es un proceso "pasivo". Solo archiva cuando el WAL está completo. Si el servidor explota a mitad de un WAL, pierdes esos últimos minutos de transacciones.
* **pg_receivewal:** Es un proceso "activo". Se comporta como una réplica; va escribiendo el WAL en tu repositorio de backups al mismo tiempo que el servidor principal.

 
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

 
# **Notas sobre PITR en PostgreSQL:**
la recuperación en PostgreSQL es un proceso de "Redo" (Rehacer), no de "Undo" (Deshacer).

Cuando trabajas con **Point-In-Time Recovery (PITR)** en PostgreSQL, el tiempo **solo avanza hacia adelante**, nunca retrocede.  
Por ejemplo:

*   Puedes restaurar la base de datos al punto de las **14:00** y, si no es el momento exacto que necesitas, avanzar a las **14:10** sin tener que borrar todo ni restaurar nuevamente el backup completo.
*   Sin embargo, **no puedes restaurar a las 14:00 y luego intentar retroceder a las 13:40**, porque los datos ya aplicados se escribieron en disco y no se pueden deshacer.

 
**¿Qué pasa con los WAL que no se usan en el PITR?**

*   Los archivos WAL que **no se usaron durante la restauración** y permanecen en el directorio `pg_wal` no generan conflictos.
*   Por ejemplo, si tienes segmentos con timeline `00000001` y realizas una recuperación hasta cierto punto, al **promover el servidor** se crea una **nueva línea de tiempo** (por ejemplo `00000002`).
*   A partir de ese momento, los nuevos WAL comenzarán con `00000002`, por lo que **no se interpondrán** con los anteriores.
*   Esto permite mantener los WAL antiguos como referencia o para auditoría, sin afectar la operación del servidor restaurado.

 
 



---
# Laboratorio PITR

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
mkdir -p /sysx/data16/DATANEW/{db_productiva,db_pruebas,backup_wal,backup_db}

chown postgres:postgres /sysx/data16/DATANEW/db_productiva 
chown postgres:postgres /sysx/data16/DATANEW/db_pruebas 
chown postgres:postgres /sysx/data16/DATANEW/backup_wal
chown postgres:postgres /sysx/data16/DATANEW/backup_db

```

### 2. Configuración e Inicio de la Instancia Productiva

Inicializa la base de datos y configura el archivado de logs.

```bash
# Inicializar el DATA 
/usr/pgsql-17/bin/initdb -E UTF-8 -D /sysx/data16/DATANEW/db_productiva --data-checksums 

# Configurar parámetros críticos de PITR
echo "
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /sysx/data16/DATANEW/backup_wal/%f.gz && gzip < %p > /sysx/data16/DATANEW/backup_wal/%f.gz' #  al archivarlo lo guarda compreso para ahorrar espacio
archive_timeout = '1 h' 
port = 5598
track_commit_timestamp = on
log_line_prefix = '<%t [%x-%v] %r %a %d %u %p %c %i>'
logging_collector = on
log_min_messages  = 'warning'
log_min_error_statement = 'warning'
log_statement = 'all'
" >> /sysx/data16/DATANEW/db_productiva/postgresql.auto.conf

# Iniciar
/usr/pgsql-17/bin/pg_ctl start -D /sysx/data16/DATANEW/db_productiva  # -o "-p 5598"

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
pg_basebackup -h localhost -p 5598 -U postgres -D /sysx/data16/DATANEW/backup_db -Ft -Xs -P -c fast -v -Z server-gzip:9



```

### 4. Simulación del Incidente (Punto Crítico)

Aquí es donde registramos el tiempo exacto antes de la "catástrofe".

```bash
# ver la transacción actual 
psql -p 5598 -d test -c "SELECT txid_current();"

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

-- Descomprimir   
gunzip -c /sysx/data16/DATANEW/backup_wal/000000010000000000000003.gz > /tmp/000000010000000000000003

--- Aqui buscamos el LSN  que genero el ultimo insert = 0/03007100 
$PGBIN17/pg_waldump /tmp/000000010000000000000003  |  grep 16386 | grep -Ei "INSERT"
rmgr: Heap        len (rec/tot):     54/   738, tx:        740, lsn: 0/03007100, prev 0/030050F0, desc: INSERT off: 11, flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0 FPW


-- aqui le decimos que nos muestre unicamente cuatro lineas despues de lsn 0/03007100 y encontramos la hora que se hizo el insert 2025-12-24 17:37:40.157010
-- Nota si nos damos cuenta la secuencia es en la primera linea lsn: 0/03007100 y en la segunda linea esta como  prev 0/03007100 y luego el lsn: 0/030073E8 el cual se encuentra en la tercera linea como  prev 0/030073E8 asi sucesivamente
$PGBIN17/pg_waldump /tmp/000000010000000000000003 --limit=4 --start=0/03007100
rmgr: Heap        len (rec/tot):     54/   738, tx:        740, lsn: 0/03007100, prev 0/030050F0, desc: INSERT off: 11, flags: 0x00, blkref #0: rel 1663/16384/16386 blk 0 FPW
rmgr: Btree       len (rec/tot):     53/   313, tx:        740, lsn: 0/030073E8, prev 0/03007100, desc: INSERT_LEAF off: 11, blkref #0: rel 1663/16384/16393 blk 1 FPW
rmgr: Transaction len (rec/tot):     34/    34, tx:        740, lsn: 0/03007528, prev 0/030073E8, desc: COMMIT 2025-12-24 17:37:40.157010 MST
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/03007550, prev 0/03007528, desc: RUNNING_XACTS nextXid 741 latestCompletedXid 740 oldestRunningXid 741


-- Descomprimir   
gunzip -c /sysx/data16/DATANEW/backup_wal/000000010000000000000004.gz > /tmp/000000010000000000000004

--- Tambien podemos buscar los delete en este caso ya se habia rotado el wal por lo que debe estar en el 000000010000000000000004 los delete 
 $PGBIN17/pg_waldump /tmp/000000010000000000000004   |  grep 16386  |   grep -Ei "DELETE"
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
$PGBIN17/pg_waldump /tmp/000000010000000000000004 --limit=4 --start=0/04000648
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


------------------ Borrar los wal de la temporales 

rm /tmp/000000010000000000000001
rm /tmp/000000010000000000000002
rm /tmp/000000010000000000000003
rm /tmp/000000010000000000000004

---


```

### 5. Restauración en la Instancia de Pruebas

Configuramos la instancia `db_pruebas` para que se detenga justo después del insert, pero antes del delete.


```bash
tar -xzf /sysx/data16/DATANEW/backup_db/base.tar.gz -C /sysx/data16/DATANEW/db_pruebas && echo "Extracción de base.tar finalizada con éxito"
tar -xf /sysx/data16/DATANEW/backup_db/pg_wal.tar -C /sysx/data16/DATANEW/db_pruebas/pg_wal

# Configurar la recuperación en db_pruebas
echo "
port = 5599
restore_command = 'gunzip < /sysx/data16/DATANEW/backup_wal/%f.gz > %p' # Descomprime cada wal con gunzip y lo usa para la restauración
recovery_target_time = '2025-12-26 14:36:42' # Aqui podemos poner la fecha del ultimo insert o unos minutos antes de que se ejecutara el delete que fue a las 2025-12-24 17:53:45
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
# Información Extra

###  **Error comun**
El error se generó "FATAL: recovery ended before configured recovery target was reached y mensajes de `cannot stat` para WAL faltantes."

1.  **`recovery_target_time` inalcanzable**
    *   El tiempo solicitado (`12:51:29`) era **anterior al checkpoint del backup** (12:51:36) y al LSN inicial del `pg_basebackup`.
    *   En PITR, solo puedes avanzar **hacia adelante** desde el punto donde inicia la recuperación (redo LSN). Nunca retroceder.

2.  **Falta de segmentos WAL posteriores al backup**
    *   Después del backup, realizaste operaciones (`INSERT 'Ultimo_Registro'` y `DELETE`) pero **no se archivó el WAL actual** porque no se llenó el segmento.
	*    siempre procura finalizar con un pg_switch_wal() lo cual finaliza el wal actual sin importar si se lleno los 16MB y usa otro 
    *   Sin el archivo `00000003`, el servidor no puede reproducir esos cambios ni alcanzar el tiempo deseado.



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


### **¿Para qué se usa pg_controldata?**
sirve para mostrar información interna del clúster de base de datos, especialmente del archivo pg_control. Este archivo contiene metadatos críticos sobre el estado del clúster.


*   **Verificar el estado del clúster** (si está en modo normal, recuperación, etc.).
*   **Consultar la versión de PostgreSQL** y el formato del clúster.
*   **Obtener información sobre el último checkpoint**, como:
    *   LSN del último checkpoint.
    *   Fecha y hora del último checkpoint.
*   **Identificar el timeline actual** (muy útil en PITR).
*   **Verificar parámetros internos** como tamaño de bloques, tamaño de WAL, etc.

```
pg_controldata -D /sysx/data16/DATANEW/db_pruebas

pg_control version number:            1700
Catalog version number:               202406281
Database system identifier:           7587588177156489861
Database cluster state:               in archive recovery
pg_control last modified:             Wed 24 Dec 2025 06:43:31 PM MST
Latest checkpoint location:           0/40000B8
Latest checkpoint's REDO location:    0/4000060
Latest checkpoint's REDO WAL file:    000000010000000000000004
Latest checkpoint's TimeLineID:       1
Latest checkpoint's PrevTimeLineID:   1
Latest checkpoint's full_page_writes: on
Latest checkpoint's NextXID:          0:752
Latest checkpoint's NextOID:          24576
Latest checkpoint's NextMultiXactId:  1
Latest checkpoint's NextMultiOffset:  0
Latest checkpoint's oldestXID:        730
Latest checkpoint's oldestXID's DB:   1
Latest checkpoint's oldestActiveXID:  752
Latest checkpoint's oldestMultiXid:   1
Latest checkpoint's oldestMulti's DB: 1
Latest checkpoint's oldestCommitTsXid:738
Latest checkpoint's newestCommitTsXid:751
Time of latest checkpoint:            Wed 24 Dec 2025 05:52:24 PM MST
 

SELECT * from  pg_control_checkpoint(); -- Validar información sobre el último checkpoint registrado en el archivo pg_control 
SELECT * from   pg_control_recovery(); -- detalles sobre la configuración de recuperación usada durante el último arranque del clúster. si ya se recupero no devolverá nada
```

---
# Archivos dentro de pg_wal 

- `000000010000000000000003.backup` → punto donde comenzó el backup base.
- `00000002.history` → el sistema fue promovido al timeline 2.

```
postgres@lvt-pruebas-dba-cln /sysx/data16/DATANEW/db_productiva/pg_wal $ ls -lhtr /sysx/data16/DATANEW/db_productiva/pg_wal
total 33M
drwx------. 2 postgres postgres   6 Dec 24 17:37 summaries
-rw-------. 1 postgres postgres 338 Dec 24 17:37 000000010000000000000002.00000028.backup
-rw-------. 1 postgres postgres 16M Dec 24 17:54 000000010000000000000006
drwx------. 2 postgres postgres  67 Dec 24 17:57 archive_status
-rw-------. 1 postgres postgres 16M Dec 24 17:57 000000010000000000000005
postgres@lvt-pruebas-dba-cln /sysx/data16/DATANEW/db_productiva/pg_wal $ ls -lhtr /sysx/data16/DATANEW/db_pruebas/pg_wal
total 33M
drwx------. 2 postgres postgres  10 Dec 24 17:37 summaries
-rw-------. 1 postgres postgres 16M Dec 26 12:41 000000010000000000000004
-rw-r-----. 1 postgres postgres  50 Dec 26 12:41 00000002.history
drwx------. 2 postgres postgres  84 Dec 26 12:41 archive_status
-rw-r-----. 1 postgres postgres 16M Dec 26 12:41 000000020000000000000004
postgres@lvt-pruebas-dba-cln /sysx/data16/DATANEW/db_productiva/pg_wal $ ls -lhtr /sysx/data16/DATANEW/backup_wal/
total 65M
-rw-------. 1 postgres postgres 16M Dec 24 17:37 000000010000000000000001
-rw-------. 1 postgres postgres 16M Dec 24 17:37 000000010000000000000002
-rw-------. 1 postgres postgres 338 Dec 24 17:37 000000010000000000000002.00000028.backup
-rw-------. 1 postgres postgres 16M Dec 24 17:50 000000010000000000000003
-rw-------. 1 postgres postgres 16M Dec 24 17:54 000000010000000000000004
-rw-r-----. 1 postgres postgres  50 Dec 26 12:41 00000002.history

```


### 🗂️ Archivo `.backup`

- 🔹 Se genera automáticamente cuando ejecutas un **`pg_basebackup`** con la opción de streaming WAL (`-Xs`).
- 🔹 Marca **el punto exacto en el WAL** donde inicia un respaldo base.
- 🔹 Sirve para que PostgreSQL sepa **dónde empezar a aplicar los WALs** durante una recuperación.

 **Sin este archivo, PITR puede fallar** si no hay un punto de inicio válido para el proceso de recuperación.
```
postgres@lvt-pruebas-dba-cln /sysx/data16/DATANEW/db_productiva/pg_wal $  cat /sysx/data16/DATANEW/backup_wal/000000010000000000000002.00000028.backup
START WAL LOCATION: 0/2000028 (file 000000010000000000000002)
STOP WAL LOCATION: 0/2000120 (file 000000010000000000000002)
CHECKPOINT LOCATION: 0/2000080
BACKUP METHOD: streamed
BACKUP FROM: primary
START TIME: 2025-12-24 17:37:24 MST
LABEL: pg_basebackup base backup
START TIMELINE: 1
STOP TIME: 2025-12-24 17:37:24 MST
STOP TIMELINE: 1
```


### 🗂️ Archivos `.history`

- 🔹 Se generan cuando hay un **cambio de línea de tiempo (timeline)**. Por ejemplo, al promover un servidor en recuperación.
- 🔹 Contienen información sobre **cómo se dividieron las líneas de tiempo** y cuál era la anterior.
- 🔹 Ayudan a PostgreSQL a entender la evolución de los WALs en escenarios de replicación o PITR avanzados.

 **Es útil en recuperaciones donde se necesita seguir una timeline específica**, como `recovery_target_timeline = 'latest'`.
```
postgres@lvt-pruebas-dba-cln /sysx/data16/DATANEW/db_productiva/pg_wal $ cat /sysx/data16/DATANEW/backup_wal/00000002.history
1       0/4000680       before 2025-12-24 17:53:45.880038-07
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



 
## **¿Qué es `backup_manifest`?**
Introducido en la versión 13 y cumple una función muy importante para la verificación de integridad de los backups.

Es un archivo **JSON** que se genera automáticamente cuando realizas un **base backup** con `pg_basebackup` (o usando el protocolo de backup nativo).  
Este archivo describe **todo el contenido del backup**,  Se guarda **dentro del directorio del backup** que creaste con `pg_basebackup`, incluyendo:

*   Lista de archivos y directorios.
*   Tamaño de cada archivo.
*   Checksums (SHA256 por defecto) para verificar integridad.
*   Información del timeline y LSN del backup.
 

### **¿Por qué es importante?**

*   Permite **verificar que el backup está completo y sin corrupción** antes de usarlo para restauración.
*   Puedes usar el comando:

```bash
pg_verifybackup /ruta/del/backup
```


## Bibliografias
```
https://mkyong.com/database/postgresql-point-in-time-recovery-incremental-backup/?source=post_page-----b5a8e06571a6---------------------------------------
https://www.scalingpostgres.com/tutorials/postgresql-backup-point-in-time-recovery/

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

https://www.youtube.com/watch?v=eea96aYrtOQ
https://www.youtube.com/watch?v=4az6P3ePQ8E
https://www.youtube.com/watch?v=qRvlJUUPpKU

```

