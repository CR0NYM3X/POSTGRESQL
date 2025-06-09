
### **Repmgr**
Es una herramienta de código abierto para la gestión de replicación y failover en PostgreSQL. Fue desarrollada originalmente por 2ndQuadrant, que luego fue adquirida por EnterpriseDB (EDB)


### ¿Para qué sirve un Witness Node?
Evita divisiones en el clúster (split-brain). ✅ Confirma el estado de los nodos maestro y standby en caso de falla. ✅ Ayuda a decidir si el failover debe ocurrir y cuál nodo debe ser promovido.
1️⃣ Monitorea los nodos maestro y standby. 2️⃣ En caso de caída del maestro, ayuda a validar la promoción del standby. 3️⃣ Evita que ambos nodos crean que son maestros, garantizando una transición correcta.
💡 Es como un árbitro en un partido: no juega, pero decide quién gana en caso de empate.


### 📌 **Objetivo**
Este documento describe el proceso de **instalación, configuración y administración** de un clúster de **PostgreSQL** utilizando **Repmgr** para garantizar alta disponibilidad y failover automático.  


# Ejemplo de replicas y failover con Repmgr en entorno local

### Requisito 

```bash
-- Validar si se tiene instalada la extension desde postgresql 
select * from pg_available_extensions where name = 'repmgr';
+-[ RECORD 1 ]------+------------------------------------+
| name              | repmgr                             |
| default_version   | 5.5                                |
| installed_version | NULL                               |
| comment           | Replication manager for PostgreSQL |
+-------------------+------------------------------------+

# Validar si se tiene instalada la extension desde linux 
$ rpm -qa | grep repmgr
repmgr_16-5.5.0-1PGDG.rhel8.x86_64
```


### Crear carpetas data 
```bash
mkdir -p /sysx/data16/DATANEW/data_maestro
mkdir -p /sysx/data16/DATANEW/data_esclavo1
mkdir -p /sysx/data16/DATANEW/data_esclavo2
mkdir -p /sysx/data16/DATANEW/data_esclavo3
```

### Crear repmgr.conf  para cada nodo
```
cp /etc/repmgr/16/repmgr.conf  /etc/repmgr/16/maestro_repmgr.conf
cp /etc/repmgr/16/repmgr.conf  /etc/repmgr/16/esclavo1_repmgr.conf
cp /etc/repmgr/16/repmgr.conf  /etc/repmgr/16/esclavo2_repmgr.conf
cp /etc/repmgr/16/repmgr.conf  /etc/repmgr/16/esclavo3_repmgr.conf
```

### Crear log repmgr para cada nodo 
```
touch  /etc/repmgr/16/maestro_repmgr.log
touch  /etc/repmgr/16/esclavo1_repmgr.log
touch  /etc/repmgr/16/esclavo2_repmgr.log
touch  /etc/repmgr/16/esclavo3_repmgr.log
```

/etc/repmgr/16.2/repmgr.log

### Iniciarlizar el data del servidor maestro
```bash
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_maestro  --data-checksums  &>/dev/null
```

## configurar nodo maestro 

### Configurar postgresql.conf 
```
listen_addresses = '*'
port=55161
max_wal_senders = 10
max_replication_slots = 10
wal_level = 'replica'
hot_standby = on
archive_mode = on
archive_command = '/bin/true'
shared_preload_libraries = 'repmgr'
wal_log_hints = on
```

### Iniciar el servicio
```
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_maestro
```

### Crear el usuario y la base de datos 
la contraseña se coloca la que quieras 
```
CREATE USER repmgr WITH REPLICATION SUPERUSER PASSWORD '123123';
CREATE DATABASE repmgr OWNER repmgr;
```

### Agregar los permisos en `pg_hba.conf`:
```
local   replication     repmgr                                     trust
host    replication     repmgr             127.0.0.1/32            trust
```

### Recargar configuraciones 
esto para que postgresql tome las nuevas configuraciones agregadas en el pg_hba
```
/usr/pgsql-16/bin/pg_ctl reload -D /sysx/data16/DATANEW/data_maestro
```

### Configurar maestro_repmgr.conf  
```
node_id=1
node_name='pgmaster'
conninfo='host=127.0.0.1 port=55161 user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/sysx/data16/DATANEW/data_maestro'
pg_bindir='/usr/pgsql-16/bin/'

service_start_command   = '/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_maestro'
service_stop_command    = '/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_maestro'
service_restart_command  = '/usr/pgsql-16/bin/pg_ctl restart  -D /sysx/data16/DATANEW/data_maestro'
service_reload_command   = '/usr/pgsql-16/bin/pg_ctl reload -D /sysx/data16/DATANEW/data_maestro'
service_promote_command = '/usr/pgsql-16/bin/pg_ctl promote -D /sysx/data16/DATANEW/data_maestro' 

failover=automatic # Promueve a maestro automaticamente , si quieres manual "repmgr standby promote "
promote_command='/usr/pgsql-16/bin/repmgr standby promote -f /etc/repmgr/16/maestro_repmgr.conf --log-to-file' # un standby se convierte en maestro. y registra en log 
follow_command='/usr/pgsql-16/bin/repmgr standby follow -f /etc/repmgr/16/maestro_repmgr.conf --log-to-file --upstream-node-id=%n' #  Asegura que los standby sigan al nuevo maestro después de un failover.
monitor_interval_secs=2 # Establece cada cuántos segundos repmgrd verifica el estado de los nodos. 
reconnect_attempts=6  # Define cuántas veces repmgrd intentará reconectar al maestro antes de activar un failover.
reconnect_interval=8  # Establece el intervalo de tiempo (segundos) entre cada intento de reconexión.
connection_check_type = 'query' # es el metodo de validacion
log_file='/etc/repmgr/16/maestro_repmgr.log' 
log_level='INFO'
monitoring_history=yes # Guarda un registro histórico del estado de los nodos, útil para auditoría y diagnósticos. 
priority=100 # Esto en caso de fallos para tomar quien sera el maestro 
use_replication_slots=true # Activa el uso de Replication Slots, que aseguran que un standby no pierda datos de WAL 
log_status_interval=20 # Define cada cuántos segundos repmgrd guarda información de estado en los logs 
standby_disconnect_on_failover=true # Indica que los standby deben desconectarse del maestro si este falla y otro nodo es promovido. 🔹 Importancia: Muy útil, evita que los standby intenten seguir replicando desde un nodo caído. 
# primary_visibility_consensus=true # Requiere que un consenso en el clúster confirme la visibilidad del maestro antes de considerar un failover. 🔹 Importancia: Esencial en clusters con Witness Node, ayuda a evitar failovers innecesarios.
repmgrd_service_start_command='/usr/pgsql-17/bin/repmgrd -f /etc/repmgr/16/maestro_repmgr.conf' # inicia el demonio repmgrd
repmgrd_service_stop_command='pkill -f repmgrd' # inicia el demonio repmgrd
```

Registrar el nodo primario:
```bash
repmgr -f /etc/repmgr/16/maestro_repmgr.conf primary register
```


Mostrar estado del clúster:
```bash
repmgr -f /etc/repmgr/16/maestro_repmgr.conf cluster show

 ID | Name     | Role    | Status    | Upstream | Location | Priority | Timeline | Connection string                                              
----+----------+---------+-----------+----------+----------+----------+----------+-----------------------------------------------------------------------
 1  | pgmaster | primary | * running |          | default  | 100      | 1        | host=127.0.0.1 port=55161 user=repmgr dbname=repmgr connect_timeout=2
```


## configurar nodos esclavos 

### Clonar el data_maestro para los esclavos:
```bash
repmgr -h 127.0.0.1 -p 55161 -U repmgr -d repmgr -f /etc/repmgr/16.2/repmgr.conf standby clone --dry-run
repmgr -h 127.0.0.1 -p 55161 -U repmgr -d repmgr -f /etc/repmgr/16.2/repmgr.conf standby clone
```


### Verificar conexión con el nodo primario:
```bash
psql 'host=127.0.0.1 port=55161 user=repmgr dbname=repmgr connect_timeout=2'
```

###  Iniciar PostgreSQL en el esclavo1:
```bash
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_esclavo1
```

### Registrar el esclavo1:
```bash
repmgr -f /etc/repmgr.conf standby register
```

### Habilitar el demonio `repmgrd` en **todos los nodos**:
repmgrd detecta fallos revisando conexión, replicación y proceso del primario. ✅ Si el primario falla, ejecuta promote_command en el standby más apto. ✅ Los demás standby siguen al nuevo primario automáticamente con follow_command.
```bash
repmgrd -f /etc/repmgr/16.2/repmgr.conf -d --verbose # Ejecutar el demonio en segundo plano 
```







### Monitoreo de estado en PostgreSQL 
```
ps -fea | grep repmgrd

------------------------------
SELECT * FROM pg_stat_wal_receiver; # En **nodo esclavo**, verificar estado de WAL: 
SELECT * FROM pg_stat_replication; # En **nodo maestro**, revisar la replicación:

SELECT pg_catalog.pg_is_in_recovery(); -- TRUE = Secunradrio | False = maestro

SELECT pg_last_wal_receive_lsn(); # Devuelve el último LSN (Log Sequence Number) que el standby ha recibido del maestro.
SELECT pg_current_wal_lsn(); # Devuelve el último LSN generado por el nodo en el que se ejecuta la consulta. 🔹 En el maestro, muestra el WAL más reciente que se está generando. 🔹 En un standby, muestra el WAL más reciente reproducido localmente.


repmgr -f /etc/repmgr/16.2/repmgr.conf cluster show --verbose


repmgr -f /etc/repmgr/16/repmgr.conf cluster crosscheck
repmgr -f /etc/repmgr/16/repmgr.conf cluster event --event=standby_register




------------------------------------------------
postgres@repmgr# \dt repmgr.*

-- Almacena eventos importantes en el clúster de Repmgr. ✅ Registra fallos, cambios de roles, switchover y promociones de standby. ✅ Se usa para auditoría y monitoreo de cambios en la replicación.
SELECT * FROM repmgr.events ORDER BY event_timestamp DESC LIMIT 5;

-- Guarda registros de salud del clúster recopilados por repmgrd. ✅ Contiene el estado de cada nodo en intervalos de tiempo definidos. ✅ Útil para diagnósticos y análisis de rendimiento del clúster.
SELECT * FROM repmgr.monitoring_history  LIMIT 10;

-- Contiene la lista de nodos en el clúster de replicación. ✅ Define si un nodo es maestro o standby, además de su configuración.
SELECT * FROM repmgr.nodes;

-- Se usa en configuración con Witness Node para coordinar el failover. ✅ Almacena las "rondas de votación" en el proceso de elección del nuevo maestro.
SELECT * FROM repmgr.voting_term;


```


### Info Extras 
```
## 🔹 **7. Prueba de failover y switchover**
✅ **Para failover manual** (si el primario falla):
  repmgr standby promote

✅ **Para switchover planificado** (intercambiar roles):
  repmgr -f /etc/repmgr.conf standby switchover --force

✅ **Monitorear eventos en el clúster**:
  repmgr -f /etc/repmgr.conf cluster event --event=standby_register

✅ **Verificar conexiones** entre nodos:
  repmgr cluster crosscheck

✅ **Eliminar un nodo** del clúster:
  repmgr primary unregister -f /etc/repmgr.conf --node-id=1
```


## Bibliografía
```
https://www.repmgr.org/docs/current/index.html
https://www.repmgr.org/docs/current/configuration.html
https://www.repmgr.org/docs/current/configuration-file.html#CONFIGURATION-FILE-FORMAT

https://www.enterprisedb.com/postgres-tutorials/how-implement-repmgr-postgresql-automatic-failover?lang=en
https://medium.com/@fekete.jozsef.joe/create-a-highly-available-postgresql-cluster-in-linux-using-repmgr-and-keepalived-9d72aa9ef42f
https://medium.com/@muhilhamsyarifuddin/postgresql-ha-with-repmgr-and-keepalived-f466bb6aa437
https://medium.com/@humzaarshadkhan/postgresql-12-replication-and-failover-with-repmgr-6ffcbe24e342
https://medium.com/@mattbiondis/postgresql-streaming-replication-using-repmgr-master-slave-c742141bc3fd

```
