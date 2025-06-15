
### **Repmgr**
Es una herramienta de código abierto para la gestión de replicación y failover en PostgreSQL. Fue desarrollada originalmente por 2ndQuadrant, que luego fue adquirida por EnterpriseDB (EDB)

### 📌 **Objetivo**
Este documento describe el proceso de **instalación, configuración y administración** de un clúster de **PostgreSQL** utilizando **Repmgr** para garantizar alta disponibilidad y failover automático.  


### ¿Para qué sirve un Witness Node?
Es el concsenso de las replicas y evita divisiones en el clúster (split-brain). ✅ Confirma el estado de los nodos maestro y standby en caso de falla. ✅ Ayuda a decidir si el failover debe ocurrir y cuál nodo debe ser promovido.
1️⃣ Monitorea los nodos maestro y standby. 2️⃣ En caso de caída del maestro, ayuda a validar la promoción del standby. 3️⃣ Evita que ambos nodos crean que son maestros, garantizando una transición correcta.
💡 Es como un árbitro en un partido: no juega, pero decide quién gana en caso de empate.

📌 **¿Qué características tiene el Witness Node?**  
✅ **No almacena datos del clúster** → No replica registros WAL ni tiene una copia de la base de datos.  
✅ **Solo sirve como árbitro** → Valida si el primario realmente ha fallado antes de permitir un failover.  
✅ **Tiene una instalación mínima de PostgreSQL** → Solo necesita la base `repmgr` para validar el estado del clúster.  

📌 **¿Cuáles son los riesgos sin Witness?**  
❌ **Split-brain** → Si la red falla o se presentan problemas en algun esclavo, podrian por cambiarse de esclavo a primario y quererse reintegrar.
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
mkdir -p /sysx/data16/DATANEW/data_esclavo61
mkdir -p /sysx/data16/DATANEW/data_esclavo62
mkdir -p /sysx/data16/DATANEW/data_esclavo63
```

### Crear repmgr.conf  para el nodo maestro
[NOTA] -> Podemos copiar el conf original o hacer uno vacio en nuestro caso preferimos hacer uno vacio 
```
touch /etc/repmgr/16/maestro_repmgr.conf

#Copiar el conf del original lo cual no usaremos
#cp /etc/repmgr/16/repmgr.conf  /etc/repmgr/16/maestro_repmgr.conf
```

### Crear log repmgr para cada nodo 
```
touch  /etc/repmgr/16/maestro_repmgr.log
touch  /etc/repmgr/16/esclavo61_repmgr.log
touch  /etc/repmgr/16/esclavo62_repmgr.log
touch  /etc/repmgr/16/esclavo63_repmgr.log
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
SELECT * FROM pg_create_physical_replication_slot('repmgr_slot_61');
SELECT * FROM pg_create_physical_replication_slot('repmgr_slot_62');
SELECT * FROM pg_create_physical_replication_slot('repmgr_slot_63');

-- Esto en caso de querer eliminar el slot 
-- SELECT pg_drop_replication_slot('repmgr_slot_61');
```

### Validar los slot 
```
postgres@postgres# SELECT slot_name, plugin, slot_type, active, active_pid FROM pg_replication_slots;
+----------------+--------+-----------+--------+------------+
|   slot_name    | plugin | slot_type | active | active_pid |
+----------------+--------+-----------+--------+------------+
| repmgr_slot_61 | NULL   | physical  | f      |       NULL |
| repmgr_slot_62 | NULL   | physical  | f      |       NULL |
| repmgr_slot_63 | NULL   | physical  | f      |       NULL |
+----------------+--------+-----------+--------+------------+
(3 rows)
```


### Configurar maestro_repmgr.conf  
vim /etc/repmgr/16/maestro_repmgr.conf
```SQL
node_id=60
node_name='pgmaster'
conninfo='host=127.0.0.1 port=55160 user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/sysx/data16/DATANEW/data_maestro'
pg_bindir='/usr/pgsql-16/bin/'

repmgrd_pid_file='/etc/repmgr/16/maestro_repmgr.pid'
service_start_command   = '/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_maestro'
service_stop_command    = '/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_maestro'
service_restart_command  = '/usr/pgsql-16/bin/pg_ctl restart  -D /sysx/data16/DATANEW/data_maestro'
service_reload_command   = '/usr/pgsql-16/bin/pg_ctl reload -D /sysx/data16/DATANEW/data_maestro'
service_promote_command = '/usr/pgsql-16/bin/pg_ctl promote -D /sysx/data16/DATANEW/data_maestro' 
repmgrd_service_start_command='/usr/pgsql-17/bin/repmgrd -f /etc/repmgr/16/maestro_repmgr.conf' # inicia el demonio repmgrd
repmgrd_service_stop_command='pkill -f repmgrd' # inicia el demonio repmgrd

failover=automatic # Promueve a maestro automaticamente , si quieres manual "repmgr standby promote "
promote_command='/usr/pgsql-16/bin/repmgr standby promote -f /etc/repmgr/16/maestro_repmgr.conf --log-to-file' # un standby se convierte en maestro. y registra en log 
follow_command='/usr/pgsql-16/bin/repmgr standby follow -f /etc/repmgr/16/maestro_repmgr.conf --log-to-file --upstream-node-id=%n' #  Asegura que los standby sigan al nuevo maestro después de un failover.
standby_disconnect_on_failover=true # Indica que los standby deben desconectarse del maestro si este falla y otro nodo es promovido.  evita que los standby intenten seguir replicando desde un nodo caído. 
monitor_interval_secs=2 # Establece cada cuántos segundos repmgrd verifica el estado de los nodos. 
reconnect_attempts=6  # Define cuántas veces repmgrd intentará reconectar al maestro antes de activar un failover.
reconnect_interval=8  # Establece el intervalo de tiempo (segundos) entre cada intento de reconexión.
connection_check_type = 'query' # es el metodo de validacion

primary_visibility_consensus=true # Antes de hacer failover, cada standby consulta a los demás para confirmar que realmente el primario está caído. Si está en false, cada standby toma decisiones individuales, aumentando el riesgo de split-brain.
child_nodes_connected_include_witness=true #  si los standby pierden comunicación con el primario, pero aún ven al Witness, pueden asumir que la red aún está operativa y que la falla es solo del primario, no de todo el sistema. Si está en false, los standby solo consideran otros standby y el primario para decidir si están conectados.
witness_sync_interval=15 # define la frecuencia con la que el Witness Node sincroniza su información con los demás nodos del clúster.
child_nodes_disconnect_command='/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_maestro' # permite ejecutar comandos personalizados cuando un nodo se desconecta . en este caso mandamos apagarlo

log_file='/etc/repmgr/16/maestro_repmgr.log' 
log_level='INFO'
log_status_interval=20 # Define cada cuántos segundos repmgrd guarda información de estado en los logs

monitoring_history=yes # Guarda un registro histórico del estado de los nodos, útil para auditoría y diagnósticos. 
priority=100 # Esto en caso de fallos para tomar quien sera el maestro 
use_replication_slots=true # Activa el uso de Replication Slots, que aseguran que un standby no pierda datos de WAL 

ssh_options='-q -o ConnectTimeout=10'

replication_type='physical'
location='default'
```

**[NOTA]** -> el parámetro **primary_visibility_consensus=true** # solo aplica en entornos con varios standby,  no evita el failover en caso de no tener alcanse con el Witness Node, solo mejora la validación entre esclavos para reducir el riesgo de split-brain. y su función es evitar que múltiples standby se promuevan al mismo tiempo con el witness node 


### Registrar el nodo primario en repmgr:
```bash
repmgr -f /etc/repmgr/16/maestro_repmgr.conf primary register --force
```


### Mostrar estado del clúster:
```bash
repmgr -f /etc/repmgr/16/maestro_repmgr.conf cluster show

 ID | Name     | Role    | Status    | Upstream | Location | Priority | Timeline | Connection string                                              
----+----------+---------+-----------+----------+----------+----------+----------+-----------------------------------------------------------------------
 60  | pgmaster | primary | * running |          | default  | 100      | 1        | host=127.0.0.1 port=55160 user=repmgr dbname=repmgr connect_timeout=2
```



# Configurar nodos esclavos 

### configurar los repmgr.conf de los esclavos
Esto lo hacemos ya que caso todos los parámetros configurados son los mismo unicamente cambia la data y los puertos, esto solo porque lo hacemos de modo local en un entorno ya más real cambia hasta la ip
```bash
cp /etc/repmgr/16/maestro_repmgr.conf  /etc/repmgr/16/esclavo61_repmgr.conf
cp /etc/repmgr/16/maestro_repmgr.conf  /etc/repmgr/16/esclavo62_repmgr.conf
cp /etc/repmgr/16/maestro_repmgr.conf  /etc/repmgr/16/esclavo63_repmgr.conf
```

# Editar linea en conf de servidor maestro
Esto se realiza en caso de que se llegue a caer no levante no siga a las nuevas replicas porque se va desincronizar y necesita interacion manual
```bash
vim /etc/repmgr/16/maestro_repmgr.conf
follow_command='false'
```

### Cambiar algunos valores 
```bash 
sed -i 's/maestro/esclavo61/g; s/55160/55161/g; s/node_id=60/node_id=61/g; s/pgmaster/pgslave61/g' /etc/repmgr/16/esclavo61_repmgr.conf
sed -i 's/maestro/esclavo62/g; s/55160/55162/g; s/node_id=60/node_id=62/g; s/pgmaster/pgslave62/g' /etc/repmgr/16/esclavo62_repmgr.conf
sed -i 's/maestro/esclavo63/g; s/55160/55163/g; s/node_id=60/node_id=63/g; s/pgmaster/pgslave63/g' /etc/repmgr/16/esclavo63_repmgr.conf
```

### Simular Clonar el data_maestro en los esclavos 1 ,2 y 3:
Esto se hace para validar si hay algun error simulando la ejecución sin hacer cambios reales en los archivos o el sistema 
```bash
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo61_repmgr.conf standby clone --dry-run
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo62_repmgr.conf standby clone --dry-run
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo63_repmgr.conf standby clone --dry-run
```


### Clonar el data_maestro en los esclavos 1 ,2 y 3:
```bash
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo61_repmgr.conf standby clone
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo62_repmgr.conf standby clone
repmgr -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -f /etc/repmgr/16/esclavo63_repmgr.conf standby clone
```


### Agregar un puerto diferente para cada nodo esclavo
```
echo "port = 55161" >> /sysx/data16/DATANEW/data_esclavo61/postgresql.auto.conf
echo "port = 55162" >> /sysx/data16/DATANEW/data_esclavo62/postgresql.auto.conf
echo "port = 55163" >> /sysx/data16/DATANEW/data_esclavo63/postgresql.auto.conf
```

###  Iniciar PostgreSQL en todos los esclavos:
```bash
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_esclavo61
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_esclavo62
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_esclavo63
```

### Registrar los esclavos en repmgr:
```bash
repmgr -f /etc/repmgr/16/esclavo61_repmgr.conf standby register
repmgr -f /etc/repmgr/16/esclavo62_repmgr.conf standby register
repmgr -f /etc/repmgr/16/esclavo63_repmgr.conf standby register
```


### Mostrar estado del clústers: :
```bash
repmgr -f /etc/repmgr/16/maestro_repmgr.conf cluster show
 ID | Name      | Role    | Status    | Upstream | Location | Priority | Timeline | Connection string                                             
----+-----------+---------+-----------+----------+----------+----------+----------+-----------------------------------------------------------------------
 60 | pgmaster  | primary | * running |          | default  | 100      | 1        | host=127.0.0.1 port=55160 user=repmgr dbname=repmgr connect_timeout=2
 61 | pgslave61 | standby |   running | pgmaster | default  | 100      | 1        | host=127.0.0.1 port=55161 user=repmgr dbname=repmgr connect_timeout=2
 62 | pgslave62 | standby |   running | pgmaster | default  | 100      | 1        | host=127.0.0.1 port=55162 user=repmgr dbname=repmgr connect_timeout=2
 63 | pgslave63 | standby |   running | pgmaster | default  | 100      | 1        | host=127.0.0.1 port=55163 user=repmgr dbname=repmgr connect_timeout=2
```




### Habilitar el demonio `repmgrd` en **todos los nodos**:
Ejecutar el demonio en segundo plano  , repmgrd detecta fallos revisando conexión, replicación y proceso del primario. ✅ Si el primario falla, ejecuta promote_command en el standby más apto. ✅ Los demás standby siguen al nuevo primario automáticamente con follow_command.
```bash
repmgrd -f  /etc/repmgr/16/maestro_repmgr.conf -d --verbose
repmgrd -f  /etc/repmgr/16/esclavo61_repmgr.conf -d --verbose
repmgrd -f  /etc/repmgr/16/esclavo62_repmgr.conf -d --verbose
repmgrd -f  /etc/repmgr/16/esclavo63_repmgr.conf -d --verbose
```


### Validar demonios repmgrd
```bash
 ps -fea | grep repmgr.conf
postgres 2343245       1  0 15:54 ?        00:00:00 repmgrd -f /etc/repmgr/16/maestro_repmgr.conf -d --verbose
postgres 2392684       1  0 15:55 ?        00:00:00 repmgrd -f /etc/repmgr/16/esclavo61_repmgr.conf -d --verbose
postgres 2413464       1  0 15:56 ?        00:00:00 repmgrd -f /etc/repmgr/16/esclavo62_repmgr.conf -d --verbose
postgres 2413486       1  0 15:56 ?        00:00:00 repmgrd -f /etc/repmgr/16/esclavo63_repmgr.conf -d --verbose
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

select * from usuarios;
```

### Validar datos en los tres nodos esclavos
```SQL
psql -X -p 55160 -d prueba_db -c "select * from usuarios limit 1"
psql -X -p 55161 -d prueba_db -c "select * from usuarios limit 1"
psql -X -p 55162 -d prueba_db -c "select * from usuarios limit 1"
psql -X -p 55163 -d prueba_db -c "select * from usuarios limit 1"
```


# Hacer pruebas de switchover automatico 
El standby más actualizado o más nuevo se convierte en nuevo primario, en este caso como no configuramos el ssh entonces no se podra usar el modo de switchover, en caso de si tener ssh configurado se tiene que hacer el switchover y depues el follow en todos los nodos para que sigan al nuevo primario
```bash
-- ejecutar el switchover en el nodo esclavo/standby que quieres promover a primario.
postgres@SERVER-TEST /sysx/data16/DATANEW $   repmgr -f  /etc/repmgr/16/esclavo62_repmgr.conf standby switchover  --siblings-follow --dry-run 
NOTICE: executing switchover on node "pgslave62" (ID: 62)
WARNING: unable to connect to remote host "127.0.0.1" via SSH
ERROR: unable to connect via SSH to host "127.0.0.1", user ""
```


# Hacer pruebas de failover automatico 
```
# 1.- Solo ocupas dar de baja el primario y durante un rato veras que algun esclavo se convertira en maestro 
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_maestro/

# 2.- conectate a cualquier esclavo
postgres@SERVER-TEST ~ $ psql -p 55163 -d repmgr -c " select node_id,active,type,slot_name from repmgr.nodes; "
+---------+--------+---------+----------------+
| node_id | active |  type   |   slot_name    |
+---------+--------+---------+----------------+
|      60 | f      | primary | repmgr_slot_60 |
|      61 | t      | primary | repmgr_slot_61 |
|      62 | t      | standby | repmgr_slot_62 |
|      63 | t      | standby | repmgr_slot_63 |
+---------+--------+---------+----------------+
(4 rows)
```


# Configurar un Witness Node 
```bash
# Creamos la carpeta 
mkdir -p /sysx/data16/DATANEW/data_witness

# Inicializamos el data 
/usr/pgsql-16/bin/initdb -E UTF-8 -D  /sysx/data16/DATANEW/data_witness  --data-checksums  &>/dev/null

# Cambiar el puerto del witness
echo "port = 55199" >> /sysx/data16/DATANEW/data_witness/postgresql.auto.conf
echo "shared_preload_libraries = 'repmgr'"  >> /sysx/data16/DATANEW/data_witness/postgresql.auto.conf

# levantar el servicio
/usr/pgsql-16/bin/pg_ctl start -D /sysx/data16/DATANEW/data_witness

# Crear el usuario 
CREATE USER repmgr WITH REPLICATION SUPERUSER PASSWORD '123123';
CREATE DATABASE repmgr OWNER repmgr;
 

# agregar al pg_hba.conf 
local   replication     repmgr                                     trust
host    replication     repmgr             127.0.0.1/32            trust

# recargar  las configuraciones 
/usr/pgsql-16/bin/pg_ctl reload -D /sysx/data16/DATANEW/data_maestro

# Creamos el conf
touch /etc/repmgr/16/witness_repmgr.conf

# agrega la siguientes lineas en witness_repmgr.conf
node_id=99
node_name='pgwitness'
conninfo='host=127.0.0.1 port=55199 user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/sysx/data16/DATANEW/data_witness'
pg_bindir='/usr/pgsql-16/bin/'
repmgrd_pid_file='/etc/repmgr/16/witness_repmgr.pid'
log_file='/etc/repmgr/16/witness_repmgr.log' 
log_level='INFO'
log_status_interval=20  
monitoring_history=yes
location='Witness'
connection_check_type = 'query'


# Registrar el Witness Node en repmgr
/usr/pgsql-15/bin/repmgr -f /etc/repmgr/16/witness_repmgr.conf witness register -h 127.0.0.1 -p 55160 -U repmgr -d repmgr -F

# Levantar el demonio de repmgrd
repmgrd -f /etc/repmgr/16/witness_repmgr.conf  -d --verbose

# Validar estatus de Witness
repmgr -f  /etc/repmgr/16/witness_repmgr.conf cluster show

 ID | Name      | Role    | Status    | Upstream | Location | Priority | Timeline | Connection string                                             
----+-----------+---------+-----------+----------+----------+----------+----------+-----------------------------------------------------------------------
 60 | pgmaster  | primary | * running |          | default  | 100      | 1        | host=127.0.0.1 port=55160 user=repmgr dbname=repmgr connect_timeout=2
 61 | pgslave61 | standby |   running | pgmaster | default  | 100      | 1        | host=127.0.0.1 port=55161 user=repmgr dbname=repmgr connect_timeout=2
 62 | pgslave62 | standby |   running | pgmaster | default  | 100      | 1        | host=127.0.0.1 port=55162 user=repmgr dbname=repmgr connect_timeout=2
 63 | pgslave63 | standby |   running | pgmaster | default  | 100      | 1        | host=127.0.0.1 port=55163 user=repmgr dbname=repmgr connect_timeout=2
 99 | pgwitness | witness | * running | pgmaster | Witness  | 0        | n/a      | host=127.0.0.1 port=55199 user=repmgr dbname=repmgr connect_timeout=2


# Ver el estado de los nodos desde postgresql
postgres@SERVER-TEST /sysx/data16/DATANEW/data_witness $ psql -p 55199 -d repmgr -c " select node_id,node_name,active,type,slot_name from repmgr.nodes; "
postgres@repmgr# select node_id,node_name,active,type,slot_name from repmgr.nodes;
+---------+-----------+--------+---------+----------------+
| node_id | node_name | active |  type   |   slot_name    |
+---------+-----------+--------+---------+----------------+
|      60 | pgmaster  | t      | primary | repmgr_slot_60 |
|      61 | pgslave61 | t      | standby | repmgr_slot_61 |
|      62 | pgslave62 | t      | standby | repmgr_slot_62 |
|      63 | pgslave63 | t      | standby | repmgr_slot_63 |
|      99 | pgwitness | t      | witness | NULL           |
+---------+-----------+--------+---------+----------------+

(5 rows)




```

 

#### 🔧 **3. Re-sincronizar un nodo (Maestro o Esclavo) que presento problemas**
Asegúrate de tener habilitado en tu configuración (wal_log_hints = on).
Si el nodo ha estado fuera de línea por mucho tiempo, es probable que necesite ser re-sincronizado. Puedes hacerlo con:
```bash
repmgr node rejoin -f /etc/repmgr.conf --force-rewind
```

- `--force-rewind`: Usa `pg_rewind` para sincronizar el nodo con el primario actual.
- Esto es más rápido que una re-clonación completa y conserva la configuración existente.

---

#### 🧪 **4. Verifica que el nodo se haya reintegrado correctamente**
Después de la reintegración, vuelve a ejecutar:

```bash
repmgr cluster show
```

El nodo debería aparecer como **"standby"** y en estado **"running"**.

 

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




************************************************************************************************************************************************************************


postgres@postgres# SELECT * FROM pg_stat_wal_receiver; -- En **nodo esclavo**, verificar estado de WAL:
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


************************************************************************************************************************************************************************

postgres@postgres# SELECT * FROM pg_stat_replication;  -- En **nodo maestro**, revisar la replicación:
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

pid: Identificador del proceso en el servidor que maneja la replicación del standby.
usesysid: Identificador del usuario de la base de datos que está gestionando la conexión de replicación.
usename: Nombre del usuario que administra la replicación.
application_name: Nombre del cliente de replicación, indicando el nodo standby que está conectado.
client_addr: Dirección IP del standby que recibe los datos desde el primario.
client_hostname: Nombre del host del standby si está configurado, de lo contrario muestra null.
client_port: Puerto utilizado por el standby para conectarse al primario.
backend_start: Fecha y hora en que la sesión de replicación fue iniciada por el standby.
backend_xmin: Indica el ID de la transacción mínima del backend, usada para gestionar la limpieza de datos antiguos.
state: Estado de la replicación; si es "streaming", significa que el standby está recibiendo cambios en tiempo real.
sent_lsn: Último Log Sequence Number (LSN) enviado por el primario al standby.
write_lsn: Último LSN escrito en el disco del standby.
flush_lsn: Último LSN confirmado como almacenado de manera segura en el disco del standby.
replay_lsn: Último LSN que ha sido aplicado por el standby.
write_lag: Retraso desde que el primario envía el WAL hasta que el standby lo escribe en su disco.
flush_lag: Retraso desde que el WAL es escrito hasta que se confirma como almacenado en el disco del standby.
replay_lag: Retraso desde que el WAL es almacenado hasta que es aplicado en el standby.
sync_priority: Nivel de prioridad del standby en caso de ser elegido como primario, relevante en la replicación síncrona.
sync_state: Estado de sincronización del standby; si es "async", indica que la replicación es asíncrona y no espera confirmaciones del standby antes de completar una transacción.
reply_time: Hora de la última respuesta del standby hacia el primario, usada para verificar su disponibilidad.


************************************************************************************************************************************************************************

SELECT pg_catalog.pg_is_in_recovery(); -- TRUE = Secunradrio | False = maestro
SELECT application_name, replay_lsn FROM pg_stat_replication ORDER BY replay_lsn DESC;
SELECT pg_current_wal_lsn(); # Devuelve el último LSN  WAL más reciente generado por el nodo maestro  . en el esclavo parecera el error "ERROR:  recovery is in progress.  HINT:  WAL control functions cannot be executed during recovery." 

****************************************************************************************************************************************
-- Verificar desfase entre primario y standby (sincronización de WAL)
-- Si pg_last_wal_receive_lsn es más reciente que pg_last_wal_replay_lsn, hay retraso en la reproducción del WAL. 🔹 Si pg_last_wal_receive_lsn es NULL, el nodo no está recibiendo registros WAL.

SELECT pg_last_wal_receive_lsn() /* Devuelve el último LSN (Log Sequence Number) que el standby ha recibido del maestro.*/
   , pg_last_wal_replay_lsn(); 

Para determinar cuál es más reciente entre `pg_last_wal_receive_lsn` y `pg_last_wal_replay_lsn`, debes interpretar la representación en formato **LSN (Log Sequence Number)**.  

  **Cómo comparar valores LSN en PostgreSQL**  
 **Cada LSN tiene la forma `X/Y`, donde:**  
- `X` → Número del segmento del WAL.  
- `Y` → Posición dentro del segmento.  
 **El LSN más reciente tendrá un número mayor en `X` o en `Y`.**  

  **Ejemplo de comparación:**  
  *Si tienes estos valores:*  

	pg_last_wal_receive_lsn = 0/80000A0
	pg_last_wal_replay_lsn  = 0/8000080
 
  **`0/80000A0` es más reciente que `0/8000080`, porque `A0` es mayor que `80` en hexadecimal.**  

  **Cómo verificar si el desfase es grande**  
  Ejecuta esta consulta en PostgreSQL:  
	SELECT pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn());
 
  Esto devolverá la diferencia en bytes entre ambos LSN.  
  **Si la diferencia es grande, el standby está retrasado en la replicación.**  
****************************************************************************************************************************************


 
postgres@SERVER-TEST /sysx/data16/DATANEW $ repmgr -f /etc/repmgr/16/witness_repmgr.conf cluster crosscheck
INFO: connecting to database
INFO: connecting to database
 Name      | ID | 60 | 61 | 62 | 63 | 99
-----------+----+----+----+----+----+----
 pgmaster  | 60 | ?  | ?  | ?  | ?  | ?
 pgslave61 | 61 | ?  | ?  | ?  | ?  | ?
 pgslave62 | 62 | ?  | ?  | ?  | ?  | ?
 pgslave63 | 63 | ?  | ?  | ?  | ?  | ?
 pgwitness | 99 | ?  | ?  | ?  | ?  | ?
WARNING: following problems detected:
  node 60 inaccessible via SSH
  node 61 inaccessible via SSH
  node 62 inaccessible via SSH
  node 63 inaccessible via SSH
  node 99 inaccessible via SSH



postgres@SERVER-TEST /sysx/data16/DATANEW $ repmgr -f /etc/repmgr/16/witness_repmgr.conf cluster event --event=standby_register
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
SELECT * FROM repmgr.nodes order by node_id desc ;

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


###  funcionamiento de un failover automático 
El **failover automático** ocurre cuando el primario **falla completamente** y uno de los standby es **promovido automáticamente** a nuevo primario por `repmgrd`.🚀  
```
📌 **¿Cuándo sucede el failover automático?**  
✅ **1. Repmgrd detecta que el primario no responde**  
- Si el primario no responde tras varios intentos (`reconnect_attempts` y `reconnect_interval`), se considera caído.  
- Ejecuta validaciones con `pg_isready`, `PQping()` y consultas a `pg_stat_replication`.  

✅ **2. Se elige el standby más actualizado para promoverlo**  
- Repmgr **elige el standby con mayor avance en los registros WAL**.  
- Si `priority` está configurado en `repmgr.conf`, el standby con mayor prioridad es elegido.  

✅ **3. Se ejecuta automáticamente el comando `standby promote`**  
📌 **Ejemplo del proceso en logs:**  

[INFO] node 2 appears to be the most up-to-date standby
[NOTICE] promoting standby to primary

🔹 En este punto, el standby ya **ha asumido el rol de primario**.  

✅ **4. Los demás standby siguen al nuevo primario**  
📌 **¿Se ejecuta `standby follow` manualmente?**  
❌ **No es necesario hacerlo manualmente**, ya que `repmgrd` ejecuta automáticamente el comando:  
	repmgr standby follow -f /etc/repmgr.conf --upstream-node-id=%n

🔹 Esto ajusta la replicación para que **los standby sigan al nuevo primario sin intervención manual**.

```

###  Reintegrar un maestro que presento fallo 
Cuando un **antiguo primario** vuelve a la red después de un failover: **sigue creyendo que es el primario** ya que en sus tabla repmgr.nodes no esta actualizada y dice que el sigue siendo el primario y esta activo , pero en realidad ha sido reemplazado. Si el antiguo primario vuelve y tiene transacciones que el nuevo primario no tiene, no puede simplemente reconectarse sin riesgo de inconsistencias y para evitar conflictos de datos.
```
📌 **¿Qué hacer en este caso?**  

✅ **1. Verifica si el antiguo primario sigue creyendo que es líder**  
Ejecuta en `pgmaster` (antiguo primario):  
	SELECT pg_is_in_recovery();

🔹 **Si el resultado es `false`**, significa que **pgmaster cree que sigue siendo primario**, aunque ya no lo es.  
🔹 Para que se reintegre, **debes convertirlo en standby manualmente**.  

✅ **2. Desregistrar el antiguo primario de Repmgr**  
Ejecuta en `pgmaster`:  
	repmgr -f /etc/repmgr.conf standby unregister

🔹 Esto **elimina su estado antiguo y lo prepara para volver a replicar desde el nuevo primario**.  


✅ **3. Clonar `pgmaster` desde el nuevo primario si hay inconsistencia**  
Si el nuevo primario (`pgslave1`) ya tiene transacciones que `pgmaster` no tiene, puede rechazar su reintegración.  
Para asegurarte de que `pgmaster` está actualizado, clónalo desde el nuevo líder:  
	repmgr -h pgslave1 -U repmgr -d repmgr -f /etc/repmgr.conf standby clone --force

🔹 Esto **descarga una copia completa de los datos actualizados**.  


✅ **4. Registrar `pgmaster` como standby y seguir al nuevo primario**  
Ejecuta en `pgmaster`:  
	repmgr -f /etc/repmgr.conf standby register # Registrar primario 
	repmgr -f /etc/repmgr.conf standby follow --upstream-node-id=<nuevo_primario_id> # Sigue al nuevo primario 

🔹 Ahora `pgmaster` replicará desde `pgslave1`, y ya no intentará actuar como primario.  
```

### Borrar todo el laboratorio
```
# Detener el servicio 
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_maestro
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_esclavo61
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_esclavo62
/usr/pgsql-16/bin/pg_ctl stop -D /sysx/data16/DATANEW/data_esclavo63

# Borrar los data 
rm -r /sysx/data16/DATANEW/data_maestro
rm -r /sysx/data16/DATANEW/data_esclavo61
rm -r /sysx/data16/DATANEW/data_esclavo62
rm -r /sysx/data16/DATANEW/data_esclavo63

# borrar los archivos  generados de repmgr
rm  /etc/repmgr/16/maestro_repmgr.conf
rm  /etc/repmgr/16/esclavo61_repmgr.conf
rm  /etc/repmgr/16/esclavo62_repmgr.conf
rm  /etc/repmgr/16/esclavo63_repmgr.conf
rm  /etc/repmgr/16/maestro_repmgr.pid
rm  /etc/repmgr/16/esclavo61_repmgr.pid
rm  /etc/repmgr/16/esclavo62_repmgr.pid
rm  /etc/repmgr/16/esclavo63_repmgr.pid
rm  /etc/repmgr/16/esclavo63_repmgr.log
rm  /etc/repmgr/16/esclavo61_repmgr.log
rm  /etc/repmgr/16/esclavo62_repmgr.log
rm  /etc/repmgr/16/maestro_repmgr.log
```


## Bibliografía
```
https://www.repmgr.org/docs/current/index.html
https://www.repmgr.org/docs/current/configuration.html
https://www.repmgr.org/docs/current/configuration-file.html#CONFIGURATION-FILE-FORMAT
https://www.repmgr.org/docs/4.2/repmgr-witness-register.html
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
