**Pgpool-II** es una herramienta intermedia (middleware) que se coloca entre tus aplicaciones cliente y uno o varios servidores **PostgreSQL**. Su propósito es mejorar el rendimiento, la disponibilidad y la escalabilidad de tu base de datos sin necesidad de modificar tu aplicación ni PostgreSQL. 

 
###   ¿Qué puede hacer Pgpool-II?

#### **1. Pooling de Conexiones**
- Reutiliza conexiones existentes a PostgreSQL para evitar el costo de abrir/cerrar conexiones constantemente.
- Mejora el rendimiento en aplicaciones con muchas conexiones concurrentes.

#### **2. Balanceo de Carga**
- Distribuye automáticamente las consultas **SELECT** entre múltiples réplicas de PostgreSQL.
- Reduce la carga del servidor maestro y mejora la escalabilidad de lectura.

#### **3. Alta Disponibilidad (HA)**
- Detecta fallos en los nodos y puede redirigir las conexiones a nodos disponibles.
- Con el módulo **Watchdog**, puede gestionar una IP virtual (VIP) y evitar puntos únicos de falla.

#### **4. Failover Automático**
- Si el nodo maestro falla, Pgpool-II puede promover una réplica a maestro automáticamente.
- También puede ejecutar scripts personalizados para manejar la conmutación por error.

#### **5. Recuperación en Línea**
- Permite reintegrar nodos fallidos al clúster sin detener el servicio.
- Usa scripts como `recovery_1st_stage` y `recovery_2nd_stage`.

#### **6. Caché de Consultas en Memoria**
- Puede almacenar resultados de consultas SELECT en memoria.
- Si se repite la misma consulta, responde desde la caché sin consultar a PostgreSQL.

#### **7. Administración vía PCP y SQL**
- Usa comandos como `pcp_attach_node`, `pcp_node_info`, etc., para administrar nodos.
- Con la extensión `pgpool_adm`, puedes ejecutar estas acciones desde SQL.

#### **8. Control de Conexiones Excedidas**
- Si se alcanza el límite de conexiones, puede ponerlas en cola en lugar de rechazarlas inmediatamente.

#### **9. Soporte para Replicación y Paralelismo**
- Puede trabajar en modos de replicación nativa, streaming replication o consultas paralelas.

 
###   ¿Qué no hace Pgpool-II?
- No reemplaza a PostgreSQL.
- No realiza balanceo de carga de escritura (solo lectura).
- No es un sistema de respaldo ni de monitoreo por sí solo (aunque puede integrarse con ellos).


### NOTAS 

- Cuando Pgpool-II está balanceando consultas, las **sentencias SELECT** se envían a réplicas (nodos esclavos), mientras que las de modificación (DML) van al nodo maestro.  Pgpool-II detecta que no es un SELECT**, y por defecto **lo enruta al nodo maestro** (el único que acepta escrituras).

- Pgpool-II no requiere PostgreSQL instalado en el mismo servidor donde se ejecuta
 
- Puedes instalar Pgpool-II en el mismo servidor donde corre PostgreSQL, y de hecho, es bastante común en entornos de desarrollo o laboratorios de prueba. pero no se recomienda en servidores productivos ya que compiten por CPU, RAM y disco. En producción, esto puede degradar el rendimiento.

- Si Pgpool-II **solo se usará como balanceador de carga**, **no necesitas configuraciones de failover, HA ni recuperación de nodos**.  
✅ **Enfócate en balanceo de carga** → `load_balance_mode = on`  
❌ **Desactiva failover y watchdog**  
❌ **Ignora comandos PCP de recuperación**  

- **No necesitas instalar extensiones en postgresql si solo usas:**. **Balanceo de carga** ,  **Pooling de conexiones** , **Routing de consultas de lectura/escritura**
-   **sí necesitas extensiones si usas:** <br>
     **1. Recuperación en línea (Online Recovery)** Para que Pgpool-II pueda ejecutar scripts de recuperación automática y reintegrar nodos fallidos, necesitas instalar la extensión pgpool_recovery.Esta extensión permite que los scripts como `recovery_1st_stage` y `recovery_2nd_stage` funcionen correctamente desde Pgpool-II.  <br>
      **2. Administración PgPool vía SQL** Si quieres ejecutar comandos PCP desde SQL  puedes instalar pgpool_adm, te permite administrar Pgpool-II desde una sesión SQL, sin tener que usar comandos externos como pcp_node_info o pcp_attach_node.

### **`watchdog` en Pgpool-II**
El **watchdog** es un **subproceso de Pgpool-II** que agrega **Alta Disponibilidad (HA)**. Su función principal es **monitorear el estado de Pgpool-II** y **manejar el failover automático** en caso de fallos.

**¿Qué hace el watchdog?**
- **Monitorea la salud de Pgpool-II**, enviando consultas a PostgreSQL.
- **Detecta fallos** en el servicio y **promueve otro nodo** como activo.
- **Gestiona direcciones IP virtuales (VIP)** para que el servicio siga disponible.
- **Evita el problema de "split-brain"**, asegurando que solo un Pgpool-II sea el activo.




### 🔧 ¿Para qué sirve PCP?
significa **Pgpool Control Protocol**, y es el conjunto de comandos que te permite **administrar Pgpool-II remotamente** a través de la red o desde línea de comandos.

Con PCP puedes:

- Ver el estado de los nodos (`pcp_node_info`, `pcp_node_count`)
- Adjuntar o desconectar nodos (`pcp_attach_node`, `pcp_detach_node`)
- Promover un nodo standby a maestro (`pcp_promote_node`)
- Recuperar nodos (`pcp_recovery_node`)
- Ver procesos internos de Pgpool (`pcp_proc_info`, `pcp_proc_count`)
- Recargar configuración o detener Pgpool (`pcp_reload_config`, `pcp_stop_pgpool`)
- Consultar parámetros (`pcp_pool_status`)
- Ver estado del watchdog (`pcp_watchdog_info`)


3. **Ejecuta comandos PCP**  
   Por ejemplo, para ver los nodos:
   ```bash
   pcp_node_info -h localhost -p 9898 -U admin -n 0 -w
   ```
 
###  ¿Es obligatorio usar PCP?

No, pero **es muy útil** si quieres administrar Pgpool-II sin reiniciar el servicio o si estás en un entorno distribuido. Incluso puedes integrarlo con scripts o monitoreo.
---

 ###  ¿Qué es una Virtual IP (VIP)?
Es una **dirección IP flotante o secundaria** que **no está atada a un servidor físico específico**, sino que puede **moverse entre servidores** según sea necesario.


###  ¿Para qué sirve en Pgpool-II?
Cuando tienes **varios servidores Pgpool-II** (por ejemplo, tres nodos pgpool con watchdog), el VIP permite que:

- **Los clientes (aplicaciones)** siempre se conecten a **una sola IP fija**, sin importar qué servidor Pgpool-II esté activo.
- Si el Pgpool-II principal falla, **otro nodo toma el control del VIP automáticamente**, gracias al **watchdog**.
- Esto evita tener que reconfigurar las aplicaciones o balanceadores externos cuando hay un failover.


###  ¿Cuándo **no** necesitas un VIP?

- Si solo tienes **una instancia de Pgpool-II**, no necesitas VIP.
- Si usas un **balanceador externo (como HAProxy o un NLB en la nube)**, el VIP puede ser innecesario porque el balanceador ya gestiona el tráfico.
 


### Rutas de pgpool 
```
--- Directorio de cofiguracion 
ls -lhtr /etc/pgpool-II/ # Directorio generico de pgpool
ls -lhtr /etc/pgpool-II-13 # Se recomienda usar el directorio enfocado a la versión de postgresql, ya que cuenta con script personalizados  para la versión

--- binarios de la herramienta
ls -lhtr /usr/pgpool-13/bin

-- Archivos que se configuran 
vim /etc/pgpool-II-13/pgpool.conf.sample
vim /etc/pgpool-II-13/pgpool.conf.sample-stream
```

## **Laboratorio**

### DATAS de postgres a usar 
```bash
/sysx/data16/DATANEW/data_maestro
/sysx/data16/DATANEW/data_secundario1
/sysx/data16/DATANEW/data_secundario2
```


### **Crear el usuario en mi servidor maestro**
Este usuario lo utilizara pgpool para monitorear el estado de los servidores 
```SQL
create user pgpool_monitor with password  '123123';
GRANT pg_monitor TO pgpool_monitor;
GRANT pg_read_all_stats TO pgpool_monitor;
GRANT pg_read_all_settings TO pgpool_monitor;


---- validar si ya pertenece a los roles 
SELECT 
  r1.rolname AS rol_asignado, 
  r2.rolname AS miembro
FROM 
  pg_auth_members m
JOIN 
  pg_roles r1 ON m.roleid = r1.oid
JOIN 
  pg_roles r2 ON m.member = r2.oid
WHERE 
  r2.rolname = 'pgpool_monitor';
```


## ** Crear los archivos conf**
cd /etc/pgpool-II/
```bash
mkdir -p  /etc/pgpool-II/info # Aqui se guardaran todos los logs y sockets etc.
mkdir -p /etc/pgpool-II/info/oiddir

cp /etc/pgpool-II/pgpool.conf.sample /etc/pgpool-II/pgpool.conf
cp /etc/pgpool-II/pool_hba.conf.sample /etc/pgpool-II/pool_hba.conf
cp /etc/pgpool-II/pcp.conf.sample /etc/pgpool-II/pcp.conf
```

## agregar linea a pool_hba.conf
Controla si Pgpool-II debe usar el archivo pool_hba.conf para autenticar conexiones de clientes, al estilo de cómo PostgreSQL usa su pg_hba.conf. 
esto sirve para centralizar las autenticaciones cuando se manejan varios nodos postgresql y no estar configurando cada servidor postgresql por separado
- Esto es útil si quieres que Pgpool-II filtre conexiones antes de que lleguen a PostgreSQL.
```bash
local   all         all                               trust
```

## agregar linea a pcp.conf
Este archivo define los usuarios y contraseñas que pueden conectarse para ejecutar comandos administrativos PCP y se configura donde se tiene instalado el pgpool
```bash
### generar contraseña en md5 
postgres@lvt-pruebas-dba /etc/pgpool-II $ /usr/pgpool-13/bin/pg_md5 mi_password123
d910bec38754da22001aaa3b006f203a

### Agregar el usuario pgpool con contraseña: mi_password123
echo pgpool:$(/usr/pgpool-13/bin/pg_md5 mi_password123) >> /etc/pgpool-II/pcp.conf
```

## **Configura `.pcppass` en el home del usuario `postgres`**  
   Esto permite que no tengas que escribir la contraseña cada vez que usas un comando pcp_. pcp leerá este archivo para autenticarte automáticamente.
   ```bash
   ## El archivo .pcppass se debe configurar en el servidor (o máquina) donde vas a ejecutar los comandos pcp_, si ejecutas los comandos en un servidor remoto entonces ahi tienes que crear el archivo
   echo "127.0.0.1:9898:pgpool:mi_password123" > ~/.pcppass
   chmod 600 ~/.pcppass
   ```


### 🔹 **Parámetros clave pgpool.conf**

```ini

########### Configuracion inicial ###########
listen_addresses = '*'             # IP de Pgpool-II
port = 9999                        # Puerto de Pgpool-II
backend_clustering_mode = 'streaming_replication' # Modo de replicación
 
unix_socket_directories = '/etc/pgpool-II/info' # en la version especifica de pgpool por ejemplo pgpool-II-13 el parametro es socket_dir 
unix_socket_permissions = 0600
pid_file_name = '/etc/pgpool-II/info/pgpool.pid'

### Proteger tu clúster PostgreSQL desde la entrada, permitiendo que Pgpool-II controle quién puede conectarse y cómo autentica cada usuario.
enable_pool_hba = on               # controla si Pgpool-II debe usar el archivo pool_hba.conf para autenticar conexiones en la herramienta pgpool para administracion
pool_passwd  = 'pool_passwd'     # Le indica el nombre del archivo donde se almacenan las contraseñas hash (md5) de los usuarios. Solo se usa cuando en pool_hba.conf defines métodos como md5 o scram-sha-256. valide usuarios y contraseñas antes de reenviar la conexión al servidor PostgreSQL. es importante aclarar que esto no remplaza a la autenticacion y validaciones que hace  postgresql 
authentication_timeout = 1min # tiempo limite para acompletar la autenticación.
allow_clear_text_frontend_auth = off # en este caso se desactivo pero si esta en on esto Permite que Pgpool-II acepte contraseñas en texto plano desde el cliente si el método en pool_hba.conf es password. 

# Permite la administración remota de Pgpool-II mediante comandos PCP
pcp_listen_addresses = '*' 
pcp_port = 9898
pcp_socket_dir = '/etc/pgpool-II/info'


########### Configuracion Log ###########

logdir = '/etc/pgpool-II/info/'
log_destination = 'stderr'
log_line_prefix = '%m: %a pid %p: '
log_connections = on
log_disconnections = on
log_pcp_processes = on
log_statement = on # este parametro registra las consultas en el log hay que tener cuidado ya que puede ocupar mucho espacio en   disco si es muy transacional
client_min_messages = warning
log_min_messages = warning 


logging_collector = on
log_directory = '/etc/pgpool-II/info/'
log_filename = 'pgpool-%Y-%m-%d_%H%M%S.log'
log_file_mode = 0600
log_truncate_on_rotation = on
log_rotation_age = 1d

########### Desactivar failover ###########
# Objetivo :  - Evita cualquier intento de cambiar roles entre servidores. y se enfocará exclusivamente en distribuir carga.

failover_command = '' # Desactiva el failover automático
auto_failback = off # Evita la recuperación automática de nodos



########### Habilitar balanceo de carga  ###########
# Objetivo :  Consultas de solo lectura** se distribuirán según el peso asignado. y el Maestro solo manejará escrituras**, asegurando consistencia.  

load_balance_mode = on
replicate_select = off # off -> envía los SELECT solo a un nodo | on -> pgpool-II envía los SELECT a todos los nodos, como si fueran escrituras.

backend_hostname0 = '127.0.0.1'
backend_port0 = 55160
backend_weight0 = 1
# backend_data_directory0 = '/sysx/data11-1' # Esto sirve para saber dónde está ubicado físicamente el clúster de datos de cada nodo y Ejecutar scripts de recuperación (recovery_1st_stage_command, recovery_2nd_stage_command
backend_flag0 = 'ALLOW_TO_FAILOVER' --- ALWAYS_MASTER
backend_application_name0 = 'server0'

backend_hostname1 = '127.0.0.1'
backend_port2 = 55161
backend_weight1 = 1
#backend_data_directory1 = '/sysx/data11-3'
backend_flag1 = 'ALLOW_TO_FAILOVER'
backend_application_name1 = 'server2'

backend_hostname2 = '127.0.0.1'
backend_port2 = 55162
backend_weight2 = 1
#backend_data_directory0 = '/sysx/data11-3'
backend_flag2 = 'ALLOW_TO_FAILOVER'
backend_application_name0 = 'server2'


###########  - Streaming - ###########
# Objetivo : Cuando tienes load_balance_mode = on, Pgpool reparte consultas SELECT entre las réplicas. Pero si una réplica está muy atrasada, podrías obtener datos desactualizados.Pgpool mide el retraso de replicación (en bytes) cada sr_check_period segundos. 
Si el retraso supera el delay_threshold, deja de enviar consultas a esa réplica hasta que se ponga al día.

sr_check_period = 5 # Verifica el retraso de replicación (WAL lag) entre el nodo primario y los nodos standby.
sr_check_user = 'pgpool_monitor' # usuario que usará para conectarse a los nodos y hacer la verificación.
sr_check_password = '123123'  # contraseña que  usará para autenticarse al hacer la verificación.
sr_check_database = 'postgres'  # base de datos a la que Pgpool se conectará para hacer la verificación.
delay_threshold = 10240 # Este valor (en KB) define el umbral de retraso aceptable entre el nodo primario y los standby. Si un nodo standby tiene más de 10 MB (10240 KB) de retraso en la replicación, Pgpool lo considerará como "demasiado atrasado" y puede excluirlo del balanceo de carga o marcarlo como no apto.


###########  - Monitoreo de nodos postgresql - ###########
# Objetivo : permite detectar si alguno de los nodos PostgreSQL se ha caído o está inaccesible, y así evitar enviarle consultas.


health_check_period = 10               # Intervalo (segundos) entre cada verificación de salud de los backends
health_check_timeout = 5               # Tiempo máximo (segundos) para que la conexión responda antes de considerarla fallida
health_check_user = 'pgpool_monitor'           # Usuario que Pgpool usará para conectarse al backend y hacer el health check
health_check_password = '123123'  # Contraseña del usuario para el health check (también puede ir en pool_passwd)
health_check_database = 'postgres'     # Base de datos usada para conectarse durante el chequeo (puede ser cualquier base válida)
health_check_max_retries = 3           # Número de reintentos antes de marcar el nodo como "caído"
health_check_retry_delay = 2           # Espera (segundos) entre reintentos fallidos
connect_timeout = 5000                 # Tiempo máximo (milisegundos) para conectar con un nodo PostgreSQL



########### Habilitar Caché de Consultas para Acelerar PostgreSQL ###########
# Objetivo :  - Se **almacenan en memoria** consultas repetidas. Reduce la carga en PostgreSQL , mejorar el rendimiento . Beneficioso para aplicaciones con **alto volumen de consultas similares**. 
# grep cache  pgpool.conf

connection_cache = on
memory_cache_enabled = on
relcache_size = 300       # cuántas entradas puede almacenar la caché de relaciones (relcache), que es una caché interna que Pgpool usa para evitar consultar repetidamente las tablas del sistema de PostgreSQL. Se estima que cada tabla puede generar unas 10 entradas en la relcache. > Entonces, si usas 30 tablas activamente: > 30 × 10 = 300 → deberías subir relcache_size a al menos 300.
##cache_expiration = 600  # Caché de consultas por 10 minutos

memqcache_oiddir = '/etc/pgpool-II/info/oiddir'



########### **Optimizar sesiones y conexiones** ###########
# Objetivo : Evita apertura/cierre frecuente de conexiones.  Mejora el rendimiento en cargas pesadas.

max_pool = 4 # Pgpool-II funciona como un intermediario entre tus clientes y PostgreSQL. Para mejorar el rendimiento, mantiene conexiones abiertas (en caché) hacia el backend. Pero no puede guardar infinitas conexiones, y ahí entra max_pool Cada proceso hijo de Pgpool-II puede mantener hasta max_pool conexiones activas en caché
##El número total de conexiones posibles desde Pgpool a PostgreSQL es: num_init_children × max_pool . 
##Por ejemplo: num_init_children = 32 max_pool = 4 -> ️ Pgpool podría abrir hasta 128 conexiones simultáneas al backend.

num_init_children = 100  # Número de conexiones iniciales
child_life_time = 5min    # Tiempo de vida de una conexión 
### connection_life_time = 600 # Límite máximo de vida de una conexión
process_management_mode = dynamic # define cómo se gestionan los procesos hijos que atienden las conexiones de los clientes.
	# 'static'   # (por defecto) Crea todos los procesos hijos al arrancar
	# 'dynamic'  # Crea procesos según demanda y elimina los que sobran

```

---


### ¿Qué pasa si se cae el nodo maestro y solo se usa balanceador de pgpool?
✅ Opción 1: reiniciar o recargar Pgpool-II
	Modificas pgpool.conf para actualizar el orden de los nodos (backend_hostnameX)
	Reinicias Pgpool o ejecutas pgpool reload

✅ Opción 2: usar comandos pcp_ o extensión pgpool_adm
	Puedes usar pcp_promote_node, pcp_detach_node, etc., para actualizar Pgpool en caliente.
	O si usas la extensión pgpool_adm, lo haces vía SQL.

```

---- Opcion con comando pcp 
pcp_detach_node -h localhost -U admin -n 0 -p 9898 -w # Marca como inactivo el nodo 0 anterior 
pcp_promote_node -h localhost -U admin -n 1 -p 9898 -w # Promociona manualmente el nuevo maestro en Pgpool-II:
pcp_attach_node -h localhost -U admin -n 0 -p 9898 -w # (Opcional) Adjunta nuevamente el nodo que cayó si se reintegró: 

---- Opcion con comando SQL 
CREATE EXTENSION pgpool_adm;
SELECT * FROM pcp_node_info(9898, 'admin', 'tu_clave', 0); # Ver los nodos 
SELECT pcp_detach_node(9898, 'admin', 'tu_clave', 0); # Desconectar un nodo: 
SELECT pcp_promote_node(9898, 'admin', 'tu_clave', 1); # Promover un nodo: 

```



---
### Info extra 
```
select * from pg_available_extensions where name ilike '%pool%';
postgres@postgres# \dx+ pgpool_adm
                 Objects in extension "pgpool_adm"
+------------------------------------------------------------------+
|                        Object description                        |
+------------------------------------------------------------------+
| function pcp_attach_node(integer,text)                           |
| function pcp_attach_node(integer,text,integer,text,text)         |
| function pcp_detach_node(integer,boolean,text)                   |
| function pcp_detach_node(integer,boolean,text,integer,text,text) |
| function pcp_health_check_stats(integer,text)                    |
| function pcp_health_check_stats(integer,text,integer,text,text)  |
| function pcp_node_count(text)                                    |
| function pcp_node_count(text,integer,text,text)                  |
| function pcp_node_info(integer,text)                             |
| function pcp_node_info(integer,text,integer,text,text)           |
| function pcp_pool_status(text)                                   |
| function pcp_pool_status(text,integer,text,text)                 |
+------------------------------------------------------------------+
```

## ** 1. Iniciar Pgpool-II con binarios**

```bash
# comando para iniciar pgpool
pgpool -f  /etc/pgpool-II/pgpool.conf  -F /etc/pgpool-II/pcp.conf -a /etc/pgpool-II/pool_hba.conf
o
pgpool -n

**Explicación:**
- `-n`: Evita que Pgpool-II se ejecute en segundo plano, en este caso no se uso.
- `-d`: Activa modo depuración para obtener información adicional, en este caso no se uso.
- `-f`: Ruta al archivo de configuración de Pgpool-II.
- `-F`: Ruta al archivo de configuración de PCP que define los usuarios y contraseñas que pueden ejecutar comandos administrativos en Pgpool-II.
- `-a`: Ruta al archivo de autenticación `pool_hba.conf` similar a pg_hba.conf en PostgreSQL y define cómo los clientes pueden autenticarse en Pgpool-II

```



## **Pruebas de conexion**
```bash
-- Probando conexiones , veras que el puerto variara
psql -h 127.0.0.1 -p 9999 -U postgres  -d test_db_master -c "select current_setting('port'),* from clientes limit 1;"

---- ver distribución de carga
psql -h 192.168.1.10 -p 9999 -U postgres -c "SHOW POOL_NODES;"

--- Para ver **cuántas conexiones hay activas** en Pgpool-II: 
psql -p 9999 -c "SHOW POOL_PROCESSES;"

---- Muestra información de monitoreo de failover y carga de nodos.
pcp_watchdog_info -h 127.0.0.1 -p 9999 -U pgpool_user


---- Ver estatus de nodos de pgpool , se coloca -w para que no pida password, estos datos ya esta configurado en el archivo pcppass
postgres@lvt-pruebas-dba /etc/pgpool-II $ pcp_node_info -h 127.0.0.1 -p 9898 -U pgpool -a -w 
Password:
127.0.0.1 55160 2 0.333333 up up primary primary 0 none none 2025-06-19 15:46:05
127.0.0.1 55161 2 0.333333 up up standby standby 0 none none 2025-06-19 15:46:05
127.0.0.1 55162 2 0.333333 up up standby standby 0 none none 2025-06-19 15:46:05

postgres@lvt-pruebas-dba /etc/pgpool-II $ pcp_node_info -h 127.0.0.1 -p 9898 -U pgpool -w  -n 0
Password:
127.0.0.1 55160 2 0.333333 up up primary primary 0 none none 2025-06-19 15:46:05
postgres@lvt-pruebas-dba-cln /etc/pgpool-II $



```


### Pruebas de caidas 
```bash
bajaremos el servicio del puerto 55161
pg_ctl stop -D /sysx/data16/DATANEW/data_secundario1



```




###  Comandos extras 
```
 ---- Ver procesos ejecutandose de pgpool
ps -ef | grep pgpool

---- recargar pool_hba.conf sin reiniciar Pgpool-II:
pgpool -a /etc/pgpool-II/pool_hba.conf reload

---- Detener Pgpool-II con binarios
/usr/bin/pgpool -f /etc/pgpool-II/pgpool.conf -m fast stop  # detiene Pgpool-II sin esperar a que las conexiones terminen.
pkill -f pgpool

--- Ver la version 
pgpool -v

-- Ver la ruta del binario
which pgpool

 

--- Ver todos los parámetros que le pueden colocar listas de filtrado
grep list  /etc/pgpool-II/pgpool.conf.sample


 

------- Configurar watchdog ------------

wd_hostname = '10.0.0.163'
delegate_IP = '10.0.0.163'
wd_heartbeat_port = 9694
wd_lifecheck_dbname = 'postgres'
wd_lifecheck_user = 'pgpool'

# en caso de no querer usarlo 
use_watchdog = off       # Desactiva la función de alta disponibilidad
delegate_IP = ''         # No se necesita una IP virtual
wd_heartbeat_port = 0    # No se enviarán "heartbeats" entre nodos Pgpool-II


📝 **Explicación:**  
- `use_watchdog = on`: Activa el watchdog.  
- `delegate_IP`: IP virtual que se transfiere en caso de failover.  
- `wd_lifecheck_dbname`: Base de datos usada para verificar la salud del sistema.  
- `wd_lifecheck_user`: Usuario que ejecuta las verificaciones.  



-------- Reintrega un servidor a pg-pool en caso de que haya fallado y ya se haya recuperado --------

# postgres2
$ /usr/pgsql-13/bin/pg_ctl -D /data1/pgsql/13/data -m immediate stop
$ pcp_recovery_node -h 10.0.0.163 -p 9898 -U pgpool -n 1 -w

# postgres3
$ /usr/pgsql-13/bin/pg_ctl -D /data1/pgsql/13/data -m immediate stop
$ pcp_recovery_node -h 10.0.0.163 -p 9898 -U pgpool -n 1 -w



----------

### 📚 Valores disponibles de `backend_clustering_mode`
Determina el **modo de operación del clúster** y afecta cómo se manejan las consultas, la replicación, el balanceo de carga y el failover.

| **Valor**               | **Descripción** |
|-------------------------|-----------------|
| `streaming_replication` | Usa la replicación nativa de PostgreSQL (modo más común). Pgpool-II enruta SELECTs a réplicas y DMLs al maestro. Ideal para HA y balanceo de lectura. |
| `native_replication`    | Pgpool-II replica los datos manualmente a todos los nodos. No usa la replicación de PostgreSQL. Puede causar inconsistencias si no se configura bien. |
| `logical_replication`   | Usa replicación lógica de PostgreSQL. Útil para replicar subconjuntos de datos o entre versiones distintas. |
| `snapshot_isolation`    | Usa técnicas de snapshot para garantizar consistencia de lectura entre nodos. Más complejo, pero útil si necesitas consistencia fuerte. |
| `raw`                   | Pgpool-II actúa como proxy sin lógica de replicación ni balanceo. Todas las consultas van al primer nodo. Útil para pruebas o configuraciones personalizadas. |

 

```


### Info extras

```

********************** backend_flag1 **********************

1. **ALLOW_TO_FAILOVER**  
   - Permite que el nodo participe en el proceso de failover si el maestro falla.
   - Si el nodo se desconecta, Pgpool-II intentará promover otro nodo como maestro.

2. **DISALLOW_TO_FAILOVER**  
   - Evita que el nodo participe en el failover.
   - Útil para servidores que solo deben actuar como réplicas de lectura y nunca como maestros.

3. **ALWAYS_PRIMARY**  
   - Indica que este nodo siempre debe ser el maestro.
   - Si el nodo se desconecta, Pgpool-II no intentará promover otro nodo.


********************** backend_weight0 **********************

define el peso relativo de un servidor backend en el balanceo de carga. Su objetivo es distribuir las consultas de solo lectura entre los servidores de PostgreSQL según la prioridad asignada. Cuanto mayor sea el valor, más consultas de lectura recibirá ese backend. Si el valor es 0, el backend no participará en el balanceo de carga. Los valores pueden ser enteros o decimales, permitiendo ajustes precisos.


********************** Directorios  **********************

# Se recomienda usar el pgpool de version y no el generico 
postgres@lvt-pruebas-dba-cln ~ $ ls -lhtr /etc/pgpool-II-13
total 252K
-rwxrwxr-x. 1 root postgres  712 Sep 28  2020 recovery_2nd_stage.sample
-rwxrwxr-x. 1 root postgres 2.8K Sep 28  2020 recovery_1st_stage.sample
-rwxrwxr-x. 1 root postgres 3.4K Sep 28  2020 pool_hba.conf.sample
-rwxrwxr-x. 1 root postgres 1.1K Sep 28  2020 pgpool_remote_start.sample
-rwxrwxr-x. 1 root postgres  43K Sep 28  2020 pgpool.conf.sample-stream
-rwxrwxr-x. 1 root postgres  43K Sep 28  2020 pgpool.conf.sample-replication
-rwxrwxr-x. 1 root postgres  43K Sep 28  2020 pgpool.conf.sample-master-slave
-rwxrwxr-x. 1 root postgres  42K Sep 28  2020 pgpool.conf.sample-logical
-rwxrwxr-x. 1 root postgres  43K Sep 28  2020 pgpool.conf.sample
-rwxrwxr-x. 1 root postgres  858 Sep 28  2020 pcp.conf.sample
-rwxrwxr-x. 1 root postgres 6.5K Sep 28  2020 follow_master.sh.sample
-rwxrwxr-x. 1 root postgres 2.7K Sep 28  2020 failover.sh.sample


postgres@lvt-pruebas-dba-cln ~ $ ls -lhtr /usr/pgpool-13/bin
total 2.7M
-rwxr-xr-x. 1 root root 9.1K Sep 28  2020 watchdog_setup
-rwxr-xr-x. 1 root root  34K Sep 28  2020 pgpool_setup
-rwxr-xr-x. 1 root root  25K Sep 28  2020 pgproto
-rwxr-xr-x. 1 root root 2.0M Sep 28  2020 pgpool
-rwxr-xr-x. 1 root root 106K Sep 28  2020 pg_md5
-rwxr-xr-x. 1 root root 111K Sep 28  2020 pg_enc
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_watchdog_info
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_stop_pgpool
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_recovery_node
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_promote_node
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_proc_info
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_proc_count
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_pool_status
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_node_info
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_node_count
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_detach_node
-rwxr-xr-x. 1 root root  30K Sep 28  2020 pcp_attach_node
```


## Bibliografía
```
PostgreSQL High Availability complete setup using pgpool as LoadBalancer between nodes -> https://tarunratan.medium.com/1-simplifying-postgresql-high-availability-with-pgpool-83f492841681
Introduction to Database Clustering using PostgreSQL , Docker and Pgpool-II -> https://medium.com/@tirthraj2004/introduction-to-database-clustering-using-postgresql-docker-and-pgpool-ii-ac2a7bf96a5f
Configuration the PostgreSQL database for metadata using PGPool on lab environment -> https://awslife.medium.com/configuration-the-postgresql-database-for-metadata-using-pgpool-on-lab-environment-f30367562916
PostgreSQL pgpool -> https://kimdubi.github.io/postgresql/postgresql_pgpool/
Pgpool Installation + Connection Test With Python -> https://medium.com/@c.ucanefe/pgpool-installation-connection-test-with-python-c2ef7501a174
Step By Step: Use pgpool to achieve load balance & separation of read/write on Mac -> https://zzdjk6.medium.com/step-by-step-use-pgpool-to-achieve-load-balance-separation-of-read-write-on-mac-e1b8b21af159
PgPool: How to setup PostgreSQL Load Balancer on Kubernetes Cluster -> https://8grams.medium.com/pgpool-how-to-setup-postgresql-load-balancer-on-kubernetes-cluster-b5f4eb06cde3
PGPOOL PostgreSQL — SSL Configuration to Connect Database -> https://demirhuseyinn-94.medium.com/postgresql-ssl-configuration-to-connect-database-114f867d96e0
High Availability in Postgres ->  https://medium.com/@usman.khan9805/high-availibility-in-postgres-3210fb232f82
“Relation does not exist”- Understanding Pgpool-II Connection pooling -> https://medium.com/@ashish15/relation-does-not-exist-understanding-pgpool-ii-connection-pooling-25d60aab77fe
Pgpool-II + Watchdog Setup Example -> https://www.pgpool.net/docs/latest/en/html/example-cluster.html

https://blog.disy.net/postgres-ha-pgpool/
https://www.pgpool.net/docs/latest/en/html/pcp-commands.html


https://www.pgpool.net/docs/latest/en/html/tutorial.html
https://www.pgpool.net/mediawiki/index.php/Documentation
https://www.pgpool.net/docs/latest/en/html/runtime-config-backend-settings.html

```
