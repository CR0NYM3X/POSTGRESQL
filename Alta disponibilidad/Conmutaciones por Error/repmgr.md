
### **Repmgr**
Es una herramienta de código abierto para la gestión de replicación y failover en PostgreSQL. Fue desarrollada originalmente por 2ndQuadrant, que luego fue adquirida por EnterpriseDB (EDB)

### 📌 **Objetivo**
Este documento describe el proceso de **instalación, configuración y administración** de un clúster de **PostgreSQL** utilizando **Repmgr** para garantizar alta disponibilidad y failover automático.  


### ¿Para qué sirve un Witness Node?
Evita divisiones en el clúster (split-brain). ✅ Confirma el estado de los nodos maestro y standby en caso de falla. ✅ Ayuda a decidir si el failover debe ocurrir y cuál nodo debe ser promovido.
1️⃣ Monitorea los nodos maestro y standby. 2️⃣ En caso de caída del maestro, ayuda a validar la promoción del standby. 3️⃣ Evita que ambos nodos crean que son maestros, garantizando una transición correcta.
💡 Es como un árbitro en un partido: no juega, pero decide quién gana en caso de empate.

📌 **¿Qué características tiene el Witness Node?**  
✅ **No almacena datos del clúster** → No replica registros WAL ni tiene una copia de la base de datos.  
✅ **Solo sirve como árbitro** → Valida si el primario realmente ha fallado antes de permitir un failover.  
✅ **Tiene una instalación mínima de PostgreSQL** → Solo necesita la base `repmgr` para validar el estado del clúster.  

📌 **¿Cuáles son los riesgos sin Witness?**  
❌ **Split-brain** → Si la red falla o se presentan problemas en el primario y hay mas de un esclavo/standby , todos los standby podrian optar por cambiarse a primario.
❌ **Failover innecesario** → No hay consenso externo para evitar decisiones erróneas.  
❌ **Posibles inconsistencias** → Si el antiguo primario tiene transacciones sin replicar, pueden perderse.  

**[NOTA]**  
- **Cada standby actúa por separado**, sin compartir información entre ellos.  
- Si varios standby están activos y detectan que el primario ha fallado, **cada uno puede intentar promoverse a nuevo primario** si no hay un mecanismo de consenso.  




# Ejemplo de replicas y failover con Repmgr en entorno local

### Requisito 

**Extension instalada**
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

**configurar SSH entre nodos**
Repmgr necesita SSH para ejecutar comandos remotos y coordinar failover/switchover. ✅ Sin SSH, muchas de sus funciones serían manuales en cada nodo, perdiendo automatización.

### Crear carpetas data 
```bash
mkdir -p /sysx/data16/DATANEW/data_maestro
mkdir -p /sysx/data16/DATANEW/data_esclavo1
mkdir -p /sysx/data16/DATANEW/data_esclavo2
mkdir -p /sysx/data16/DATANEW/data_esclavo3
```

### Crear repmgr.conf  para el nodo maestro
```
cp /etc/repmgr/16/repmgr.conf  /etc/repmgr/16/maestro_repmgr.conf
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

# configurar nodo maestro 

### Configurar postgresql.conf 
```
listen_addresses = '*'
port=55160
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


### Configurar en el maestro un slot para cada nodo esclavo 
```
SELECT * FROM pg_create_physical_replication_slot('repmgr_slot_1');
SELECT * FROM pg_create_physical_replication_slot('repmgr_slot_2');
SELECT * FROM pg_create_physical_replication_slot('repmgr_slot_3');

-- Esto en caso de querer eliminar el slot 
-- SELECT pg_drop_replication_slot('repmgr_slot_1');
```



### Configurar maestro_repmgr.conf  
vim /etc/repmgr/16/maestro_repmgr.conf
```
node_id=1
node_name='pgmaster'
conninfo='host=127.0.0.1 port=55160 user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/sysx/data16/DATANEW/data_maestro'
pg_bindir='/usr/pgsql-16/bin/'

pid_file='/etc/repmgr/16/maestro_repmgr.pid'
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
standby_disconnect_on_failover=true # Indica que los standby deben desconectarse del maestro si este falla y otro nodo es promovido.  Importancia: Muy útil, evita que los standby intenten seguir replicando desde un nodo caído. 
primary_visibility_consensus=true # hace que **Repmgr consulte al Witness antes de decidir Importancia: Esencial en clusters con Witness Node, ayuda a evitar failovers innecesarios.
repmgrd_service_start_command='/usr/pgsql-17/bin/repmgrd -f /etc/repmgr/16/maestro_repmgr.conf' # inicia el demonio repmgrd
repmgrd_service_stop_command='pkill -f repmgrd' # inicia el demonio repmgrd
```

### Registrar el nodo primario en repmgr:
```bash
repmgr -f /etc/repmgr/16/maestro_repmgr.conf primary register
```


### Mostrar estado del clúster:
```bash
repmgr -f /etc/repmgr/16/maestro_repmgr.conf cluster show

 ID | Name     | Role    | Status    | Upstream | Location | Priority | Timeline | Connection string                                              
----+----------+---------+-----------+----------+----------+----------+----------+-----------------------------------------------------------------------
 1  | pgmaster | primary | * running |          | default  | 100      | 1        | host=127.0.0.1 port=55160 user=repmgr dbname=repmgr connect_timeout=2
```



# Configurar nodos esclavos 

### configurar los repmgr.conf de los esclavos
Esto lo hacemos ya que caso todos los parámetros configurados son los mismo unicamente cambia la data y los puertos, esto solo porque lo hacemos de modo local en un entorno ya más real cambia hasta la ip
```bash
cp maestro_repmgr.conf  /etc/repmgr/16/esclavo1_repmgr.conf
cp maestro_repmgr.conf  /etc/repmgr/16/esclavo2_repmgr.conf
cp maestro_repmgr.conf  /etc/repmgr/16/esclavo3_repmgr.conf
```


### Cambiar algunos valores 
```bash 
sed -i 's/maestro/esclavo1/g; s/55160/55161/g; s/node_id=1/node_id=2/g; s/pgmaster/pgslave1/g' /etc/repmgr/16/esclavo1_repmgr.conf
sed -i 's/maestro/esclavo2/g; s/55160/55162/g; s/node_id=1/node_id=3/g; s/pgmaster/pgslave2/g' /etc/repmgr/16/esclavo2_repmgr.conf
sed -i 's/maestro/esclavo3/g; s/55160/55163/g; s/node_id=1/node_id=4/g; s/pgmaster/pgslave3/g' /etc/repmgr/16/esclavo3_repmgr.conf
```

### Simular Clonar el data_maestro en los esclavos 1 ,2 y 3:
Esto se hace para validar si hay algun error simulando la ejecución sin hacer cambios reales en los archivos o el sistema 
```bash
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo1_repmgr.conf standby clone --dry-run
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo2_repmgr.conf standby clone --dry-run
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo3_repmgr.conf standby clone --dry-run
```bash


### Clonar el data_maestro en los esclavos 1 ,2 y 3:
```bash
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo1_repmgr.conf standby clone
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo2_repmgr.conf standby clone
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo3_repmgr.conf standby clone
```

### Configurar los nombre de slot en cada nodo esclavo
```
sed -i 's/repmgr_slot_1/repmgr_slot_1/g; s/pgmaster/pgslave1/g' /sysx/data16/DATANEW/data_esclavo1/postgresql.auto.conf
sed -i 's/repmgr_slot_1/repmgr_slot_2/g; s/pgmaster/pgslave2/g' /sysx/data16/DATANEW/data_esclavo2/postgresql.auto.conf
sed -i 's/repmgr_slot_1/repmgr_slot_3/g; s/pgmaster/pgslave3/g' /sysx/data16/DATANEW/data_esclavo3/postgresql.auto.conf
```

### Agregar un puerto diferente para cada nodo esclavo
```
echo "port = 55161" >> /sysx/data16/DATANEW/data_esclavo1/postgresql.auto.conf
echo "port = 55162" >> /sysx/data16/DATANEW/data_esclavo2/postgresql.auto.conf
echo "port = 55163" >> /sysx/data16/DATANEW/data_esclavo3/postgresql.auto.conf
```

###  Iniciar PostgreSQL en todos los esclavos:
```bash
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_esclavo1
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_esclavo2
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_esclavo3
```

### Registrar los esclavos en repmgr:
```bash
repmgr -f /etc/repmgr/16/esclavo1_repmgr.conf standby register
repmgr -f /etc/repmgr/16/esclavo2_repmgr.conf standby register
repmgr -f /etc/repmgr/16/esclavo3_repmgr.conf standby register
```


### Mostrar estado del clústers: :
```bash
repmgr -f /etc/repmgr/16/maestro_repmgr.conf cluster show
 ID | Name     | Role    | Status    | Upstream | Location | Priority | Timeline | Connection string                                              
----+----------+---------+-----------+----------+----------+----------+----------+-----------------------------------------------------------------------
 1  | pgmaster | primary | * running |          | default  | 100      | 1        | host=127.0.0.1 port=55160 user=repmgr dbname=repmgr connect_timeout=2
 2  | pgslave1 | standby |   running | pgmaster | default  | 100      | 1        | host=127.0.0.1 port=55161 user=repmgr dbname=repmgr connect_timeout=2
 3  | pgslave2 | standby |   running | pgmaster | default  | 100      | 1        | host=127.0.0.1 port=55162 user=repmgr dbname=repmgr connect_timeout=2
 4  | pgslave3 | standby |   running | pgmaster | default  | 100      | 1        | host=127.0.0.1 port=55163 user=repmgr dbname=repmgr connect_timeout=2
```




### Habilitar el demonio `repmgrd` en **todos los nodos**:
Ejecutar el demonio en segundo plano  , repmgrd detecta fallos revisando conexión, replicación y proceso del primario. ✅ Si el primario falla, ejecuta promote_command en el standby más apto. ✅ Los demás standby siguen al nuevo primario automáticamente con follow_command.
```bash
repmgrd -f  /etc/repmgr/16/maestro_repmgr.conf -d --verbose
repmgrd -f  /etc/repmgr/16/esclavo1_repmgr.conf -d --verbose
repmgrd -f  /etc/repmgr/16/esclavo2_repmgr.conf -d --verbose
repmgrd -f  /etc/repmgr/16/esclavo3_repmgr.conf -d --verbose
```


### Validar demonios repmgrd
```bash
 ps -fea | grep repmgr.conf
postgres 2343245       1  0 15:54 ?        00:00:00 repmgrd -f /etc/repmgr/16/maestro_repmgr.conf -d --verbose
postgres 2392684       1  0 15:55 ?        00:00:00 repmgrd -f /etc/repmgr/16/esclavo1_repmgr.conf -d --verbose
postgres 2413464       1  0 15:56 ?        00:00:00 repmgrd -f /etc/repmgr/16/esclavo2_repmgr.conf -d --verbose
postgres 2413486       1  0 15:56 ?        00:00:00 repmgrd -f /etc/repmgr/16/esclavo3_repmgr.conf -d --verbose
postgres 2484680 1679705  0 15:58 pts/9    00:00:00 grep --color=auto repmgr.conf
```


# Insertar datos en maestro 
psql -p 55160
```SQL
-- Crear la base de datos
CREATE DATABASE prueba_db;

-- conectarse a la db
\c  prueba_db;

-- Crear la tabla
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,  -- En PostgreSQL, usa SERIAL; en MySQL, usa AUTO_INCREMENT
    nombre VARCHAR(50) NOT NULL,
    edad INT NOT NULL
);

-- Insertar algunos datos
INSERT INTO usuarios (nombre, edad) VALUES
('Ana', 25),
('Carlos', 30),
('María', 22),
('Juan', 28);
```

### Validar datos en los tres nodos esclavos
```SQL
postgres@SERVER-TEST /sysx/data16/DATANEW/data_maestro/log $ psql -X -p 55161 -d prueba_db -c "select * from usuarios limit 1"
 id | nombre | edad
----+--------+------
  1 | Ana    |   25
(1 row)

postgres@SERVER-TEST /sysx/data16/DATANEW/data_maestro/log $ psql -X -p 55162 -d prueba_db -c "select * from usuarios limit 1"
 id | nombre | edad
----+--------+------
  1 | Ana    |   25
(1 row)

postgres@SERVER-TEST /sysx/data16/DATANEW/data_maestro/log $ psql -X -p 55163 -d prueba_db -c "select * from usuarios limit 1"
 id | nombre | edad
----+--------+------
  1 | Ana    |   25
(1 row)
```




# Hacer pruebas de switchover automatico 
El standby más actualizado o más nuevo se convierte en nuevo primario
```bash
-- ejecutar el switchover en el nodo que quieres promover a primario, es decir, en uno de los standby
  repmgr -f  /etc/repmgr/16/esclavo2_repmgr.conf standby switchover --force
```

# Hacer pruebas de failover automatico 


# Configurar un Witness Node 




### Monitoreo de estado en PostgreSQL 
```SQL
 
-- Verifica si hay slots de replicación lógica activos
	slot_type = physical → Réplica física (streaming)
	slot_type = logical → Réplica lógica
	plugin = wal2json o pgoutput → Lógica
	plugin = (null) → Física

postgres@postgres# SELECT slot_name, plugin, slot_type, active, active_pid FROM pg_replication_slots;
+---------------+--------+-----------+--------+------------+
|   slot_name   | plugin | slot_type | active | active_pid |
+---------------+--------+-----------+--------+------------+
| repmgr_slot_1 | NULL   | physical  | t      |    1907055 |
| repmgr_slot_2 | NULL   | physical  | t      |    1907250 |
| repmgr_slot_3 | NULL   | physical  | t      |    1947350 |
+---------------+--------+-----------+--------+------------+
(3 rows)



-- Validar info como datos enviados
SELECT slot_name, spill_txns, spill_count, spill_bytes, total_txns, total_bytes FROM pg_stat_replication_slots;




------------------------------
SELECT * FROM pg_stat_wal_receiver; -- En **nodo esclavo**, verificar estado de WAL:

postgres@postgres# SELECT * FROM pg_stat_wal_receiver;
+-[ RECORD 1 ]----------+-------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------+
| pid                   | 1907054                                             |
| status                | streaming                                             |
| receive_start_lsn     | 0/D000000                                             |
| receive_start_tli     | 1                                             |
| written_lsn           | 0/F0365F0                                             |
| flushed_lsn           | 0/F0365F0                                             |
| received_tli          | 1                                             |
| last_msg_send_time    | 2025-06-09 16:01:25.81917-07                                             |
| last_msg_receipt_time | 2025-06-09 16:01:25.819236-07                                             |
| latest_end_lsn        | 0/F0365F0                                             |
| latest_end_time       | 2025-06-09 16:01:25.81917-07                                             |
| slot_name             | repmgr_slot_1                                             |
| sender_host           | 127.0.0.1                                             |
| sender_port           | 55160                                             |
| conninfo              | user=repmgr passfile=/home/postgres/.pgpass channel_binding=prefer connect_timeout=2 dbname=replication host=127.0.0.1 p
ort=55160 application_name=pgslave1 fallback_application_name=walreceiver sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_proto
col_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable |




SELECT * FROM pg_stat_replication; -- En **nodo maestro**, revisar la replicación:
postgres@postgres# SELECT * FROM pg_stat_replication;
+-[ RECORD 1 ]-----+-------------------------------+
| pid              | 1947350                       |
| usesysid         | 16384                         |
| usename          | repmgr                        |
| application_name | pgslave3                      |
| client_addr      | 127.0.0.1                     |
| client_hostname  | NULL                          |
| client_port      | 26402                         |
| backend_start    | 2025-06-09 15:43:15.271468-07 |
| backend_xmin     | NULL                          |
| state            | streaming                     |
| sent_lsn         | 0/F034A80                     |
| write_lsn        | 0/F034A80                     |
| flush_lsn        | 0/F034A80                     |
| replay_lsn       | 0/F034A80                     |
| write_lag        | 00:00:00.000299               |
| flush_lag        | 00:00:00.000674               |
| replay_lag       | 00:00:00.000676               |
| sync_priority    | 0                             |
| sync_state       | async                         |
| reply_time       | 2025-06-09 16:01:01.230519-07 |
+-[ RECORD 2 ]-----+-------------------------------+
| pid              | 1907055                       |
| usesysid         | 16384                         |
| usename          | repmgr                        |
| application_name | pgslave1                      |
| client_addr      | 127.0.0.1                     |
| client_hostname  | NULL                          |
| client_port      | 40782                         |
| backend_start    | 2025-06-09 15:42:09.750765-07 |
| backend_xmin     | NULL                          |
| state            | streaming                     |
| sent_lsn         | 0/F034A80                     |
| write_lsn        | 0/F034A80                     |
| flush_lsn        | 0/F034A80                     |
| replay_lsn       | 0/F034A80                     |
| write_lag        | 00:00:00.000444               |
| flush_lag        | 00:00:00.000827               |
| replay_lag       | 00:00:00.000877               |
| sync_priority    | 0                             |
| sync_state       | async                         |
| reply_time       | 2025-06-09 16:01:01.230701-07 |
+-[ RECORD 3 ]-----+-------------------------------+
| pid              | 1907250                       |
| usesysid         | 16384                         |
| usename          | repmgr                        |
| application_name | pgslave2                      |
| client_addr      | 127.0.0.1                     |
| client_hostname  | NULL                          |
| client_port      | 40788                         |
| backend_start    | 2025-06-09 15:42:10.123774-07 |
| backend_xmin     | NULL                          |
| state            | streaming                     |
| sent_lsn         | 0/F034A80                     |
| write_lsn        | 0/F034A80                     |
| flush_lsn        | 0/F034A80                     |
| replay_lsn       | 0/F034A80                     |
| write_lag        | 00:00:00.000234               |
| flush_lag        | 00:00:00.000675               |
| replay_lag       | 00:00:00.000685               |
| sync_priority    | 0                             |
| sync_state       | async                         |
| reply_time       | 2025-06-09 16:01:01.230548-07 |
+------------------+-------------------------------+



SELECT pg_catalog.pg_is_in_recovery(); -- TRUE = Secunradrio | False = maestro

SELECT application_name, replay_lsn FROM pg_stat_replication ORDER BY replay_lsn DESC;
SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(); -- Para revisar qué standby tiene el WAL más reciente:
SELECT pg_last_wal_receive_lsn(); # Devuelve el último LSN (Log Sequence Number) que el standby ha recibido del maestro.
SELECT pg_current_wal_lsn(); # Devuelve el último LSN generado por el nodo en el que se ejecuta la consulta. 🔹 En el maestro, muestra el WAL más reciente que se está generando. 🔹 En un standby, muestra el WAL más reciente reproducido localmente.





postgres@SERVER-TEST /sysx/data16/DATANEW $ repmgr -f /etc/repmgr/16/repmgr.conf cluster crosscheck
INFO: connecting to database
 Name     | ID | 1 | 2 | 3 | 4
----------+----+---+---+---+---
 pgmaster | 1  | * | * | * | *
 pgslave1 | 2  | ? | ? | ? | ?
 pgslave2 | 3  | ? | ? | ? | ?
 pgslave3 | 4  | ? | ? | ? | ?
WARNING: following problems detected:
  node 2 inaccessible via SSH
  node 3 inaccessible via SSH
  node 4 inaccessible via SSH


postgres@SERVER-TEST /sysx/data16/DATANEW $ repmgr -f /etc/repmgr/16/repmgr.conf cluster event --event=standby_register
 Node ID | Name     | Event            | OK | Timestamp           | Details
---------+----------+------------------+----+---------------------+-------------------------------------------------------
 4       | pgslave3 | standby_register | t  | 2025-06-09 15:44:01 | standby registration succeeded; upstream node ID is 1
 3       | pgslave2 | standby_register | t  | 2025-06-09 15:43:57 | standby registration succeeded; upstream node ID is 1
 2       | pgslave1 | standby_register | t  | 2025-06-09 15:43:34 | standby registration succeeded; upstream node ID is 1


--- verify the replication status
SELECT client_addr AS client, usename AS user, application_name AS name,
 state, sync_state AS mode,
 (pg_wal_lsn_diff(pg_current_wal_lsn(),sent_lsn) / 1024)::bigint as pending,
 (pg_wal_lsn_diff(sent_lsn,write_lsn) / 1024)::bigint as write,
 (pg_wal_lsn_diff(write_lsn,flush_lsn) / 1024)::bigint as flush,
 (pg_wal_lsn_diff(flush_lsn,replay_lsn) / 1024)::bigint as replay,
 (pg_wal_lsn_diff(pg_current_wal_lsn(),replay_lsn))::bigint / 1024 as total_lag
 FROM pg_stat_replication;
+-----------+--------+----------+-----------+-------+---------+-------+-------+--------+-----------+
|  client   |  user  |   name   |   state   | mode  | pending | write | flush | replay | total_lag |
+-----------+--------+----------+-----------+-------+---------+-------+-------+--------+-----------+
| 127.0.0.1 | repmgr | pgslave3 | streaming | async |       0 |     0 |     0 |      0 |         0 |
| 127.0.0.1 | repmgr | pgslave1 | streaming | async |       0 |     0 |     0 |      0 |         0 |
| 127.0.0.1 | repmgr | pgslave2 | streaming | async |       0 |     0 |     0 |      0 |         0 |
+-----------+--------+----------+-----------+-------+---------+-------+-------+--------+-----------+


------------------------------------------------
psql -p 55160 -d repmgr

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

## Verificar conexión con el nodo primario:
psql 'host=127.0.0.1 port=55160 user=repmgr dbname=repmgr connect_timeout=2'
*************************

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
  repmgr primary unregister -f /etc/repmgr/16/maestro_repmgr.conf --node-id=1 # Eliminar primario 
  repmgr standby unregister -f /etc/repmgr.conf --node-id=3 # Eliminar algun secundario

  DELETE FROM repmgr.nodes where node_id = 1 ;

************************************


postgres@CDPLR8BDPSDBA02 /sysx/data16/DATANEW/data_maestro/log $ repmgr --help
repmgr: replication management tool for PostgreSQL

Usage:
    repmgr [OPTIONS] primary {register|unregister}
    repmgr [OPTIONS] standby {register|unregister|clone|promote|follow|switchover}
    repmgr [OPTIONS] node    {status|check|rejoin|service}
    repmgr [OPTIONS] cluster {show|event|matrix|crosscheck|cleanup}
    repmgr [OPTIONS] witness {register|unregister}
    repmgr [OPTIONS] service {status|pause|unpause}
    repmgr [OPTIONS] daemon  {start|stop}

  Execute "repmgr {primary|standby|node|cluster|witness|service} --help" to see command-specific options

General options:
  -?, --help                          show this help, then exit
  -V, --version                       output version information, then exit
  --version-number                    output version number, then exit

General configuration options:
  -b, --pg_bindir=PATH                path to PostgreSQL binaries (optional)
  -f, --config-file=PATH              path to the repmgr configuration file
  -F, --force                         force potentially dangerous operations to happen

Database connection options:
  -d, --dbname=DBNAME                 database to connect to (default: "postgres")
  -h, --host=HOSTNAME                 database server host
  -p, --port=PORT                     database server port (default: "5432")
  -U, --username=USERNAME             database user name to connect as (default: "postgres")

Node-specific options:
  -D, --pgdata=DIR                    location of the node's data directory
  --node-id                           specify a node by id (only available for some operations)
  --node-name                         specify a node by name (only available for some operations)

Logging options:
  --dry-run                           show what would happen for action, but don't execute it
  -L, --log-level                     set log level (overrides configuration file; default: NOTICE)
  --log-to-file                       log to file (or logging facility) defined in repmgr.conf
  -q, --quiet                         suppress all log output apart from errors
  -t, --terse                         don't display detail, hints and other non-critical output
  -v, --verbose                       display additional log output (useful for debugging)



```


## Bibliografía
```
https://www.repmgr.org/docs/current/index.html
https://www.repmgr.org/docs/current/configuration.html
https://www.repmgr.org/docs/current/configuration-file.html#CONFIGURATION-FILE-FORMAT
Witness Node # https://www.repmgr.org/docs/current/repmgrd-network-split.html

https://www.datavail.com/blog/postgresql-high-availability-setup-using-repmgr-with-witness/
https://www.enterprisedb.com/postgres-tutorials/how-implement-repmgr-postgresql-automatic-failover?lang=en
https://medium.com/@fekete.jozsef.joe/create-a-highly-available-postgresql-cluster-in-linux-using-repmgr-and-keepalived-9d72aa9ef42f
https://medium.com/@muhilhamsyarifuddin/postgresql-ha-with-repmgr-and-keepalived-f466bb6aa437
https://medium.com/@humzaarshadkhan/postgresql-12-replication-and-failover-with-repmgr-6ffcbe24e342
https://medium.com/@mattbiondis/postgresql-streaming-replication-using-repmgr-master-slave-c742141bc3fd

Part1 - PostgreSQL16 High Availability Lab Setup  -> https://www.youtube.com/watch?v=Az6GE5Y5usg&list=PLpm71E6Qw2tCIakNQNQKoxhSOJP3PpNhQ
Administrar la replicación y la conmutación por error en un clúster PostgreSQL 16 con repmgr -> https://www.youtube.com/watch?v=p_yvt0jLz4Q
Implementacion de FailOver en Postgresql paso a paso desde cero -> https://www.youtube.com/watch?v=w0JDD9kne4E&t=1015s
Alta disponibilidad con Pgpool y repmgr -> https://www.youtube.com/watch?v=LqTc9pOs-1k
```
