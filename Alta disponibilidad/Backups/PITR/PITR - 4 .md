 
### 1. Preparación del Entorno

Limpia y prepara las rutas necesarias.

```bash
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
initdb -D /sysx/data16/DATANEW/db_productiva

# Configurar parámetros críticos de PITR
echo "
wal_level = replica
archive_mode = on
archive_command = 'test ! -f /sysx/data16/DATANEW/backup_wal/%f && cp %p /sysx/data16/DATANEW/backup_wal/%f'
port = 5598
track_commit_timestamp = on
log_line_prefix = '<%t %x %r %a %d %u %p %c %i>'
logging_collector = on
log_directory = 'log'
" >> /sysx/data16/DATANEW/db_productiva/postgresql.auto.conf

# Iniciar
pg_ctl -D /sysx/data16/DATANEW/db_productiva start

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
# 1. Insertar registro que queremos salvar (Ultimo_Registro)
psql -p 5598 -d test -c "INSERT INTO inventarios(producto, stock) VALUES ('Ultimo_Registro', 999);"
psql -p 5598  -c "SELECT clock_timestamp();"
# Supongamos que el tiempo devuelto es: '2025-12-22 16:52:01.031-07'

# 2. IMPORTANTE: Forzar el archivado del WAL actual para que llegue a /backup_wal/
psql -p 5598 -d test -c "SELECT pg_switch_wal();"

# 3. EL INCIDENTE: Borrado accidental
psql -p 5598 -d test -c "DELETE FROM inventarios; SELECT clock_timestamp();"
# Supongamos que esto ocurrió a las: '2025-12-22 16:53:45.238-07'

# 4. Forzar archivado del WAL del borrado (para que el motor vea el fin de la historia)
psql -p 5598 -d test -c "SELECT pg_switch_wal();"

```

### 5. Restauración en la Instancia de Pruebas

Configuramos la instancia `db_pruebas` para que se detenga justo después del insert, pero antes del delete.

```bash
# Configurar la recuperación en db_pruebas
echo "
port = 5599
restore_command = 'cp /sysx/data16/DATANEW/backup_wal/%f %p'
recovery_target_time = '2025-12-22 17:55:42.979165-07'
recovery_target_action = 'promote'
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
psql -p 5599 -d test -c "SELECT count(*) FROM inventarios WHERE producto = 'Ultimo_Registro';"

```

**¿Por qué este sí funciona?**

1. 
**Archivado Manual:** Al usar `pg_switch_wal()` después del borrado, aseguras que el archivo que contiene el tiempo objetivo realmente exista en `/backup_wal/`.


2. **Target Action:** Al usar `recovery_target_action = 'promote'`, la base de datos se abre automáticamente para lectura/escritura una vez que alcanza el tiempo deseado.

3. Al usar recovery_target_action = 'promote', le ordenas explícitamente: "En cuanto llegues al tiempo que te pedí, deja de ser una base de datos en recuperación y conviértete en una base de datos normal (lectura/escritura)".
