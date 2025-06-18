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


###  ¿Cómo se usa?

1. **Define usuarios en `pcp.conf`**  
   Este archivo contiene usuarios y contraseñas para autenticar comandos PCP:
   ```bash
   echo "admin:$(pg_md5 tu_contraseña)" >> /etc/pgpool-II/pcp.conf
   ```

2. **Configura `.pcppass` en el home del usuario `postgres`**  
   Para evitar que te pida contraseña cada vez:
   ```bash
   echo "localhost:9898:admin:tu_contraseña" > ~/.pcppass
   chmod 600 ~/.pcppass
   ```

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


## ** Crear los archivos conf**
cd /etc/pgpool-II/
```bash
mkdir -p  /etc/pgpool-II/info # Aqui se guardaran todos los logs y sockets etc.
cp /etc/pgpool-II/pgpool.conf.sample /etc/pgpool-II/pgpool.conf
cp /etc/pgpool-II/pool_hba.conf.sample /etc/pgpool-II/pool_hba.conf
cp /etc/pgpool-II/pcp.conf.sample /etc/pgpool-II/pcp.conf
```



### 🔹 **Parámetros clave pgpool.conf**

```ini

########### Configuracion inicial ###########
listen_addresses = '*'             # IP de Pgpool-II
port = 9999                        # Puerto de Pgpool-II
backend_clustering_mode = 'streaming_replication' # Modo de replicación
socket_dir = '/etc/pgpool-II/info'
unix_socket_directories = '/etc/pgpool-II/info'
unix_socket_permissions = 0600
pid_file_name = '/etc/pgpool-II/info/pgpool.pid'

enable_pool_hba = on               # Activar autenticación basada en host
pool_passwd = 'pool_passwd'                       
allow_clear_text_frontend_auth = on

# Permite la administración remota de Pgpool-II mediante comandos PCP
pcp_listen_addresses = '*' 
pcp_port = 9898
pcp_socket_dir = '/etc/pgpool-II/info'


########### Configuracion Log ###########
log_destination = 'stderr'
logdir = '/etc/pgpool-II/info/'
log_destination = 'stderr'
log_line_prefix = '%m: %a pid %p: '
log_connections = on
log_disconnections = on
log_pcp_processes = on
log_statement = on
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
health_check_period = 0  # Desactiva monitoreo de servidores. donde Verifica si el servidor PostgreSQL está vivo (es decir, si responde a una conexión básica).


########### Habilitar balanceo de carga  ###########
# Objetivo :  Consultas de solo lectura** se distribuirán según el peso asignado. y el Maestro solo manejará escrituras**, asegurando consistencia.  

load_balance_mode = on
replicate_select = off
master_slave_mode = on
master_slave_sub_mode = 'stream'
max_pool = 4

backend_hostname0 = '192.168.1.11'
backend_port0 = 5432
backend_weight0 = 1
backend_data_directory0 = '/sysx/data11-1'
backend_application_name0 = 'server0'
backend_flag0 = 'DISALLOW_TO_FAILOVER' --- ALWAYS_MASTER

backend_hostname1 = '192.168.1.12'
backend_port1 = 5432
backend_weight1 = 1
backend_data_directory0 = '/sysx/data11-2'
backend_application_name0 = 'server1'
backend_flag1 = 'DISALLOW_TO_FAILOVER'

backend_hostname2 = '192.168.1.13'
backend_port2 = 5432
backend_weight2 = 1
backend_data_directory0 = '/sysx/data11-3'
backend_application_name0 = 'server2'
backend_flag2 = 'DISALLOW_TO_FAILOVER'


###########  - Streaming - ########### 
sr_check_period = 5 # Verifica el retraso de replicación (WAL lag) entre el nodo primario y los nodos standby.
sr_check_user = 'postgres' # usuario que usará para conectarse a los nodos y hacer la verificación.
sr_check_password = 'mi_contrasena_perrona'  # contraseña que  usará para autenticarse al hacer la verificación.
sr_check_database = 'postgres'  # base de datos a la que Pgpool se conectará para hacer la verificación.
delay_threshold = 10240 # Este valor (en KB) define el umbral de retraso aceptable entre el nodo primario y los standby. Si un nodo standby tiene más de 10 MB (10240 KB) de retraso en la replicación, Pgpool lo considerará como "demasiado atrasado" y puede excluirlo del balanceo de carga o marcarlo como no apto.


########### Habilitar Caché de Consultas para Acelerar PostgreSQL ###########
# Objetivo :  - Se **almacenan en memoria** consultas repetidas. Reduce la carga en PostgreSQL , mejorar el rendimiento . Beneficioso para aplicaciones con **alto volumen de consultas similares**. 
# grep cache  pgpool.conf

connection_cache = on
memory_cache_enabled = on
cache_expiration = 600  # Caché de consultas por 10 minutos
cache_size = 64MB       # Tamaño total del caché en memoria


########### **Optimizar sesiones y conexiones** ###########
# Objetivo : Evita apertura/cierre frecuente de conexiones.  Mejora el rendimiento en cargas pesadas.

num_init_children = 100  # Número de conexiones iniciales
child_life_time = 300    # Tiempo de vida de una conexión en segundos
connection_life_time = 600 # Límite máximo de vida de una conexión
process_management_mode = dynamic


```

---

## ** 1. Iniciar Pgpool-II con binarios en 192.168.1.10**

```bash
# comando para iniciar pgpool
pgpool -n -d -f  /etc/pgpool-II/pgpool.conf  -F /etc/pgpool-II/pcp.conf -a /etc/pgpool-II/pool_hba.conf
o
pgpool -n

**Explicación:**
- `-n`: Evita que Pgpool-II se ejecute en segundo plano.
- `-d`: Activa modo depuración para obtener información adicional.
- `-f`: Ruta al archivo de configuración de Pgpool-II.
- `-F`: Ruta al archivo de configuración de PCP que define los usuarios y contraseñas que pueden ejecutar comandos administrativos en Pgpool-II.
- `-a`: Ruta al archivo de autenticación `pool_hba.conf` similar a pg_hba.conf en PostgreSQL y define cómo los clientes pueden autenticarse en Pgpool-II

# Ejemplo de pool_hba.conf
host    all     all     192.168.1.0/24    md5

# Ejemplo de pcp.conf
pgpool_admin:md5e99a18c428cb38d5f260853678922e03
 
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
