
 En PITR, solo puedes avanzar hacia adelante desde el punto donde inicia la recuperación (redo LSN). Nunca retroceder. 

### Eliminarios laboratirio existentes
```sql
cd /sysx/data16/DATANEW/
pg_ctl stop -D /sysx/data16/DATANEW/db_productiva
pg_ctl stop -D /sysx/data16/DATANEW/db_pruebas
rm -r /sysx/data16/DATANEW/*
```

### Crear carpetas de laboratirio 
```sql
mkdir -p /sysx/data16/DATANEW/{db_productiva,db_pruebas,backup_wal}
ls 
```


### Inicializar la data de DB productiva
```sql
initdb -D /sysx/data16/DATANEW/db_productiva
```


### Configurar el postgresql.conf
```sql
echo "
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /sysx/data16/DATANEW/backup_wal/%f && cp %p /sysx/data16/DATANEW/backup_wal/%f'
port=5599
log_min_messages  = 'warning'
log_min_error_statement = 'warning'
log_statement = 'all'
track_commit_timestamp=on
log_line_prefix = '<%t [%x-%v] %r %a %d %u %p %c %i>'
" >>  /sysx/data16/DATANEW/db_productiva/postgresql.auto.conf

ls -lhtr /sysx/data16/DATANEW/db_productiva/pg_wal
cat  /sysx/data16/DATANEW/db_productiva/postgresql.auto.conf
```


### Iniciar la DB Productiva
```sql
pg_ctl -D /sysx/data16/DATANEW/db_productiva -o "-p 5598" start
```

### Crear DB Test y Tablas 
```sql
psql -p 5598 -c "CREATE DATABASE test;"
psql -p 5598 -d test -c "
CREATE TABLE inventarios (
    id SERIAL PRIMARY KEY,
    producto TEXT NOT NULL,
    stock INT NOT NULL,
    fecha_hora TIMESTAMP DEFAULT clock_timestamp()
);
SELECT clock_timestamp();

INSERT INTO inventarios(producto, stock)
SELECT 'Producto_' || i, (random()*100)::INT
FROM generate_series(1,10) AS i;
SELECT clock_timestamp();
"

ls -lhtr /sysx/data16/DATANEW/db_productiva/pg_wal
```

### Rotar Wal y validar fecha y hora 
```sql
psql -p 5598 -d test -c "
SELECT COUNT(*) FROM inventarios; -- Debe mostrar 100
SELECT clock_timestamp(); -- Hora de inserción

select pg_walfile_name(pg_current_wal_lsn());
SELECT pg_switch_wal();

select pg_walfile_name(pg_current_wal_lsn());
SELECT clock_timestamp();
"

ls -lh /sysx/data16/DATANEW/backup_wal/

```

### Hacer Backup Fisico de la DB Productiva en db pruebas
```sql
pg_basebackup -h localhost -p 5598 -U postgres -D /sysx/data16/DATANEW/db_pruebas -Fp -Xs -P -c fast -v
```


### Insertar un registro extra 
```sql
ls -lhtr /sysx/data16/DATANEW/db_productiva/pg_wal
ls -lhtr /sysx/data16/DATANEW/db_pruebas/pg_wal
ls -lhtr /sysx/data16/DATANEW/backup_wal/

psql -p 5598 -d test -c "
INSERT INTO inventarios(producto, stock) VALUES ('Ultimo_Registro', 999);
SELECT clock_timestamp(); -- Hora exacta
select pg_walfile_name(pg_current_wal_lsn());
SELECT pg_switch_wal();
select pg_walfile_name(pg_current_wal_lsn());
"
psql -p 5598 -d test -c " SELECT clock_timestamp(); "

psql -p 5598 -d test -c "SELECT pg_xact_commit_timestamp(xmin),* FROM inventarios WHERE producto = 'Ultimo_Registro';"

```

### [Incidente] - Borrar todos los registros 
```sql

psql -p 5598 -d test -c "
DELETE FROM inventarios;
SELECT COUNT(*) FROM inventarios;
SELECT clock_timestamp();
select pg_walfile_name(pg_current_wal_lsn());
SELECT pg_switch_wal();
select pg_walfile_name(pg_current_wal_lsn());
"
 psql -p 5598 -d test -c " SELECT clock_timestamp(); "  

```

### Configurar restauración en db pruebas
```sql
echo "
restore_command = 'cp /sysx/data16/DATANEW/backup_wal/%f %p'
recovery_target_time = '2025-12-22 15:40:36.231953-07'
#recovery_target_lsn = '0/4002418' #
log_min_messages  = 'warning'
log_min_error_statement = 'warning'
log_statement = 'all'
" >> /sysx/data16/DATANEW/db_pruebas/postgresql.auto.conf
cat /sysx/data16/DATANEW/db_pruebas/postgresql.auto.conf

touch /sysx/data16/DATANEW/db_pruebas/recovery.signal

psql -p 5598 -d test -c "SELECT * FROM inventarios;"
```

### Monitorear LOG
```sql
cd /sysx/data16/DATANEW/db_pruebas/log
tail -f postgresql-Mon.log
```

### Iniciar Intancia de db pruebaas y validar registros 
```sql
pg_ctl -D /sysx/data16/DATANEW/db_pruebas start
psql -p 5599 -d test -c "SELECT pg_xact_commit_timestamp(xmin),* FROM inventarios WHERE producto = 'Ultimo_Registro';"
```

----


