# PgBouncer

Para entender la potencia de **PgBouncer**, hay que entender primero el "talón de Aquiles" de PostgreSQL: cada vez que alguien se conecta a Postgres, la base de datos tiene que crear un **proceso nuevo en el sistema operativo (un "fork")**.

Crear un proceso es caro: consume memoria (unos 10MB por conexión) y tiempo de CPU. Si tienes 2,000 usuarios conectándose y desconectándose cada segundo, tu servidor gastará más energía gestionando procesos que resolviendo tus consultas SQL.

Aquí es donde entra PgBouncer para "salvar el día".

 

## 1. ¿Qué es PgBouncer y qué lo hace tan potente?

Es un **gestor de conexiones (connection pooler) ligero**. Actúa como un intermediario o "repartidor".

**Lo que lo hace potente es su arquitectura:**
A diferencia de Postgres, PgBouncer **no abre un proceso por usuario**. Utiliza una técnica llamada **I/O asíncrono (basado en `libevent`)**. Un solo proceso de PgBouncer puede gestionar miles de conexiones de red simultáneas consumiendo apenas unos pocos megabytes de RAM.

 

## 2. ¿Cómo establece la conexión con PostgreSQL? (¿Procesos o Conexiones?)

Esta es la clave de tu duda:

* **Desde la App a PgBouncer:** Se abren **conexiones de red (sockets)**. La app cree que está hablando con Postgres, pero está hablando con PgBouncer. Pueden ser miles.
* **Desde PgBouncer a Postgres:** PgBouncer abre **conexiones reales** (que en Postgres se ven como procesos). Pero abre **pocas** y las mantiene abiertas.

**¿Cómo funciona el truco?**
Imagina un banco con 1,000 clientes (apps) pero solo 5 cajeros (conexiones a Postgres). PgBouncer es la **fila**. Cuando un cliente termina de hacer su depósito, PgBouncer no cierra la conexión con el cajero; simplemente le pasa el siguiente cliente de la fila a ese mismo cajero. El cajero (Postgres) nunca se entera de que cambió de cliente, él solo ve trabajo continuo.

 
## 3. ¿Cómo hace la conexión con anticipación?

PgBouncer no espera a que llegue un usuario para ir a "tocarle la puerta" a Postgres. Él puede mantener un "retén" de conexiones listas.

Esto se configura con el parámetro **`min_pool_size`**.

* Si pones `min_pool_size = 10`, en cuanto arranques PgBouncer, él irá a Postgres y abrirá 10 conexiones aunque no haya ningún usuario conectado.
* **Ventaja:** Cuando llegue el primer usuario real, la conexión ya está "caliente" y establecida. El usuario entra instantáneamente.

 
## 4. ¿Se ocupa un usuario previamente configurado?

**Sí.** Para que PgBouncer pueda abrir esas conexiones con anticipación, necesita saber **cómo loguearse** en Postgres. 


## 1. (El concepto de Pool)

PgBouncer no crea un solo gran "almacén" de conexiones. Crea pequeños "compartimentos" llamados **Pools**. Cada pool se define por la pareja `(Usuario, Base de Datos)`.

* Si entra `juan` a `db_test` -> Pool A (5 conexiones fijas).
* Si entra `maria` a `db_test` -> Pool B (otras 5 conexiones fijas).

 
## 2. ¿Cómo cambiar este comportamiento?

Tienes tres caminos dependiendo de qué tanta "agresividad" quieras en el reciclaje de conexiones:
 

### Opción A: Desactivar o reducir el "Pre-abierto"

Si quieres que PgBouncer sea más conservador y no abra conexiones "por si acaso", cambia el valor en el `.ini`:

* **`min_pool_size = 0`**: PgBouncer solo abrirá conexiones cuando un usuario las pida. Si no hay nadie conectado, hay 0 conexiones hacia Postgres. Es lo más ahorrador de RAM.
* **`min_pool_size = 1`**: Mantendrá solo una conexión por pool. Es un buen equilibrio para que el primer usuario no sienta latencia, pero sin saturar el backend.

### Opción B: Consolidación mediante "User Remapping"

Esta es la forma de **forzar a que todos usen el mismo pool**. Como vimos antes, si en la sección `[databases]` especificas un usuario fijo, PgBouncer mezclará a todos los usuarios en un solo grupo de conexiones. no importa con que usuario el cliente se conecte, postgres siempre vera que se conecto   el mismo usuario del pool que especificaste por ejemplo user_pool1

```ini
[databases]
db_test = host=10.168.1.100 port=5432 dbname=db_test user=user_pool1 password=...

```

* **Resultado:** No importa si entran 1,000 usuarios diferentes, PgBouncer solo mirará el pool de `db_master` y mantendrá solo 5 conexiones en total hacia Postgres (según tu `min_pool_size`).

### Opción C: Ajustar el tiempo de vida (`server_idle_timeout`)

Si decides mantener un `min_pool_size` alto, puedes configurar qué tan rápido se deben cerrar las conexiones que sobran:

* **`server_idle_timeout = 60`**: Si una conexión del pool lleva más de 60 segundos sin usarse y hay más conexiones de las que indica `min_pool_size`, PgBouncer la cerrará para liberar RAM en el servidor de Postgres.



### C. La forma transparente (User Mapping)

Si quieres que PgBouncer respete el usuario que viene desde la App:

1. Necesitas un archivo llamado **`userlist.txt`**.
2. Dentro pones: `"mi_usuario_app" "clave123"`.
3. Cuando PgBouncer necesita abrir una conexión con anticipación para `mi_usuario_app`, lee ese archivo, toma la clave y se conecta a Postgres.
 
### Resumen de Ventajas y Desventajas

| Ventaja | Desventaja |
| --- | --- |
| **Ahorro de RAM masivo:** Puedes pasar de gastar 10GB en conexiones a solo 200MB. | **Punto de falla único:** Si PgBouncer se cae, nadie entra (por eso se suele usar en Alta Disponibilidad). |
| **Velocidad:** Elimina el tiempo de "handshake" de login en cada consulta. | **Incompatibilidad:** En modo transacción, no puedes usar algunas funciones (como `LISTEN/NOTIFY`). |
| **Protección:** Evita que una ráfaga de tráfico tumbe a Postgres por falta de RAM. | **Configuración extra:** Tienes que mantener el archivo de usuarios sincronizado. |


### 1. ¿Qué es mejor: Especificar el pool o dejar el `min_pool_size = 5`?

En tu escenario de **miles de conexiones**, dejar `min_pool_size = 5` por cada usuario es, en términos técnicos, **una "trampa" de recursos**.

#### El problema del "Pool por Usuario" (Transparente)

Como no especificas un `user=` en la sección `[databases]`, PgBouncer crea un pool independiente para cada pareja `(Usuario, DB)`.

* Si tienes **1,000 usuarios** distintos:
.
* **Resultado:** Saturarás la RAM y el CPU de tu PostgreSQL solo manteniendo esas conexiones "abiertas" sin hacer nada. Estás anulando el beneficio de usar PgBouncer.

#### La recomendación: "Un solo Pool Grande" (Remapping)

Para escalabilidad masiva, lo mejor es **especificar el pool** (Remapping) usando un usuario fijo hacia la base de datos.

| Estrategia | Ventaja | Desventaja |
| --- | --- | --- |
| **Por Usuario (`min=5`)** | Auditoría total (sabes quién hizo qué). | **Riesgo de saturación explosiva.** Difícil de predecir cuánta RAM consumirá. |
| **Pool Único (Remapping)** | **Rendimiento predecible.** 1,000 usuarios de la App usan solo 100 conexiones reales de Postgres. | Pierdes el nombre del usuario real en los logs de Postgres (todos se ven como `db_master`). |

> **Veredicto:** Si tienes miles de usuarios, **especifica el pool**. Es mejor tener un pool consolidado de, por ejemplo, 100 o 200 conexiones que sirvan a todos, que tener miles de pools minúsculos de 5 conexiones cada uno.
 
  
 

### ¿Cómo explota el rendimiento esto?

Al tener las conexiones "pre-abiertas" (`min_pool_size`), eliminas la latencia de creación de procesos. Y al usar **Transaction Pooling**, permites que 10 conexiones reales de Postgres sirvan a 1,000 usuarios de tu aplicación web, porque la mayoría del tiempo el usuario está leyendo la página, no ejecutando una consulta.


--- 

 
## Flujo Semántico: Escenario de Autenticación Dinámica

### Fase 1: La Petición del Cliente (Handshake Inicial)

1. **Cliente (App):** Intenta abrir una conexión enviando: `Usuario: juan`, `DB: db_test`, `Password: ****`.
2. **PgBouncer:** Recibe la conexión en el puerto `6432`.
3. **PgBouncer (Búsqueda Local):** Revisa en el archivo `userlist.txt` el usuario juan y el hash de la contraseña esto evita estar consultando al servidor postgres por su hash y es mas rápido.
* **Resultado:** No encuentra la contraseña de `juan`. Pero nota que tiene configurado un `auth_user`.



### Fase 2: La Acción del "Guardia" (`auth_user`)

4. **PgBouncer:** Busca la contraseña del `pgbouncer_auth_user` en el `userlist.txt`, ojo la contraseña tiene que estar en md5 en el usarlist.txt no en hash schram-sha-256 de lo contrario te marcara el siguiente error `failed: FATAL:  server login failed: wrong password type`.
* **Resultado:** Éxito. PgBouncer ahora sabe su propia "identidad secreta".


5. **PgBouncer -> PostgreSQL:** Abre una conexión interna ultra rápida al servidor de base de datos usando el `pgbouncer_auth_user`.
6. **PgBouncer -> PostgreSQL (Query):** Ejecuta la consulta configurada:
` SELECT usename, passwd from public.get_auth('juan');`

### Fase 3: La Verdad de la Base de Datos

7. **PostgreSQL:** Procesa la función `public.get_auth`. Verifica en sus tablas internas (`pg_shadow`) y le devuelve a PgBouncer el hash de la contraseña de `juan`.
8. **PgBouncer:** Recibe el hash. Ahora, PgBouncer realiza el cálculo matemático (SCRAM-SHA-256) contra la contraseña que el cliente envió originalmente en el Paso 1.

 

### Fase 4: Establecimiento y Remapping (El Embudo)

9. **Validación Exitosa:** PgBouncer le dice al **Cliente**: "Bienvenido, tus credenciales son correctas".
10. **PgBouncer (Routing):** Ahora PgBouncer mira la sección `[databases]`.
* **Si hay User Remapping:** PgBouncer toma la consulta de `juan` y la mete en el pool del usuario `app_runtime` (el usuario potente que definimos).
* **Si NO hay Remapping:** PgBouncer abre una conexión a Postgres como `juan`.


11. **PostgreSQL:** Recibe la consulta real, la ejecuta y devuelve los resultados a PgBouncer.
12. **PgBouncer -> Cliente:** Entrega los datos al cliente.

 

### Fase 5: El Fin del Ciclo (Reciclaje)

13. **Cliente (App):** Envía un `COMMIT` o termina su consulta (en `pool_mode = transaction`).
14. **PgBouncer:** **¡No cierra la conexión con Postgres!** Simplemente corta el vínculo con el cliente `juan` y deja la conexión de servidor libre y "caliente".
15. **Siguiente Cliente:** Cuando llega `pedro`, PgBouncer repite el proceso de validación, pero reutiliza la misma conexión física que dejó `juan` para hablar con Postgres.

 

## Resumen del Ciclo de Vida Técnicamente

| Actor | Acción Principal | Herramienta Clave |
| --- | --- | --- |
| **Cliente** | Solicita acceso | Credenciales SCRAM |
| **PgBouncer** | Coordina la confianza | `auth_user` |
| **userlist.txt** | Valida al Pooler | Contraseña del `auth_user` |
| **PostgreSQL** | Valida al Usuario | Función `public.lookup()` |
| **Pooler Engine** | Recicla la conexión | `pool_mode = transaction` |
 

---



# Restart , start 
 ```
grep -Ei "process up|process up" pgbouncer.log


/usr/bin/pgbouncer  /etc/pgbouncer/pgbouncer.ini
/usr/bin/pgbouncer -v   -d /etc/pgbouncer/pgbouncer.ini ## iniciar el servicio en segundo plano
/usr/bin/pgbouncer -v  -R -d /etc/pgbouncer/pgbouncer.ini ## hacer reload
/usr/bin/pgbouncer -u angel  /etc/pgbouncer/pgbouncer.ini ## ver si esta un usuario

tail -f /var/log/pgbouncer/pgbouncer.log

 
psql -p 5411 -U postgres -d pgbouncer -h 127.0.0.1
 
 postgres@pgbouncer# SHOW HELP;
NOTICE:  Console usage
DETAIL:
        SHOW HELP|CONFIG|DATABASES|POOLS|CLIENTS|SERVERS|USERS|VERSION
        SHOW PEERS|PEER_POOLS
        SHOW FDS|SOCKETS|ACTIVE_SOCKETS|LISTS|MEM|STATE
        SHOW DNS_HOSTS|DNS_ZONES
        SHOW STATS|STATS_TOTALS|STATS_AVERAGES|TOTALS
        SET key = arg
        RELOAD
        PAUSE [<db>]
        RESUME [<db>]
        DISABLE <db>
        ENABLE <db>
        RECONNECT [<db>]
        KILL <db>
        SUSPEND
        SHUTDOWN
        SHUTDOWN WAIT_FOR_SERVERS|WAIT_FOR_CLIENTS
        WAIT_CLOSE [<db>]
SHOW
Time: 0.313 ms



Comandos Básicos
show pools: Muestra las conexiones agrupadas por base de datos y usuario.
show clients: Lista las conexiones de cliente actuales.
show servers: Lista las conexiones de servidor actuales.
show databases: Muestra las bases de datos configuradas en PgBouncer.
show config: Muestra la configuración actual de PgBouncer.
show stats: Muestra estadísticas generales de PgBouncer.
show help: Muestra todos los comandos disponibles.

Comandos Administrativos
reload: Recarga la configuración de PgBouncer sin reiniciar el servicio.
pause: Pausa todas las nuevas conexiones entrantes.
resume: Reanuda las conexiones después de pausar.
shutdown: Detiene PgBouncer.
reconnect: Reconecta todas las conexiones abiertas a los servidores de base de datos.


 ```

# Version
 ```
[postgres@server_test pgbouncer]$ /usr/bin/pgbouncer  -V
PgBouncer 1.23.1
libevent 2.1.8-stable
adns: c-ares 1.13.0
tls: OpenSSL 1.1.1k  FIPS 25 Mar 2021
systemd: yes
 ```
 



 
 

#  pg_hba.conf

 ```

# Es dejar esta linea ya que si dejas el trust en modo local el usuario se podra conectar y no validara la caducidad de los usaurios 
 host    all             all                     127.0.0.1/32                    trust



chmod 777 /tmp/data16-cyberark/pg_hba.conf
sudo chown pgbouncer:pgbouncer /tmp/data16-cyberark/pg_hba.conf


 ```

#  sudo -l
 ```ssh

[postgres@host_server pgbouncer]$ sudo -l
(root) NOPASSWD: /bin/systemctl restart pgbouncer
    (root) NOPASSWD: /bin/systemctl reload pgbouncer
    (root) NOPASSWD: /bin/systemctl start pgbouncer
    (root) NOPASSWD: /bin/systemctl stop pgbouncer
    (root) NOPASSWD: /bin/systemctl status pgbouncer
 ```


# pgbouncer.service 
 ```ssh
vim /lib/systemd/system/pgbouncer.service
[Unit]
Description=A lightweight connection pooler for PostgreSQL
Documentation=man:pgbouncer(1)
After=syslog.target network.target

[Service]
RemainAfterExit=yes

User=pgbouncer
Group=pgbouncer

# Path to the init file
Environment=BOUNCERCONF=/etc/pgbouncer/pgbouncer.ini

ExecStart=/usr/bin/pgbouncer -q ${BOUNCERCONF}
ExecReload=/usr/bin/pgbouncer -R -q ${BOUNCERCONF}



# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=300

[Install]
WantedBy=multi-user.target
 ```

# funcion 
 ```
\c postgres

CREATE OR REPLACE FUNCTION pgbouncer.get_auth(p_usename text)   
  RETURNS TABLE(username text, password text)                    
  LANGUAGE plpgsql                                               
  SECURITY DEFINER                                               
 AS $function$                                                   
 BEGIN                                                           
     RAISE WARNING 'PgBouncer auth request: %', p_usename;       
                                                                 
     RETURN QUERY                                                
     SELECT usename::TEXT, passwd::TEXT FROM pg_catalog.pg_shadow
      WHERE usename = p_usename;                                 
 END;                                                            
 $function$

 revoke execute on funciton pgbouncer.get_auth( text) from PUBLIC;

 ```

# pgbouncer --help 
 ```
[postgres@host_server pgbouncer]$ /usr/bin/pgbouncer --help
/usr/bin/pgbouncer is a connection pooler for PostgreSQL.

Usage:
  /usr/bin/pgbouncer [OPTION]... CONFIG_FILE

Options:
  -d, --daemon         run in background (as a daemon)
  -q, --quiet          run quietly
  -R, --reboot         do an online reboot
  -u, --user=USERNAME  assume identity of USERNAME
  -v, --verbose        increase verbosity
  -V, --version        show version, then exit
  -h, --help           show this help, then exit

Report bugs to <https://github.com/pgbouncer/pgbouncer/issues>.
PgBouncer home page: <https://www.pgbouncer.org/>
 ```



# userlist.txt 
 ```
"angel" "md5edd007a589341ce2ecc0de654a7abe97"
 
 ```

--- 

### 🔍 Fragmento de configuración:

```ini
;; any, trust, plain, md5, cert, hba, pam
auth_type = hba
auth_file = /etc/pgbouncer/userlist.txt
auth_hba_file = /sysx/data/pg_hba.conf
auth_query = SELECT * FROM pgbouncer.get_auth($1)
```

 
### ✅ ¿Qué tipo de autenticación se está usando?

La clave está en esta línea:

```ini
auth_type = hba
```

Esto indica que **PgBouncer está usando autenticación tipo `hba`**, lo cual significa que se comportará de forma similar al archivo `pg_hba.conf` de PostgreSQL. Es decir, **la autenticación se define por reglas en un archivo externo**, en este caso:

```ini
auth_hba_file = /sysx/data/pg_hba.conf
```

Este archivo debe contener reglas como:

```
# Ejemplo de regla en pg_hba.conf estilo
host    all     all     0.0.0.0/0       md5
```



### 📁 ¿Qué rol tiene `auth_file`?

```ini
auth_file = /etc/pgbouncer/userlist.txt
```

Este archivo se usa **solo si el tipo de autenticación lo requiere**, por ejemplo en `plain` o `md5`. En tu caso, como estás usando `hba`, **solo se usa si alguna regla del `auth_hba_file` lo indica** (por ejemplo, si una línea dice `auth_method = md5`, entonces se buscará el usuario y contraseña en `userlist.txt`).

 
### 🧠 ¿Y qué hace `auth_query`?

```ini
auth_query = SELECT * FROM pgbouncer.get_auth($1)
```

Este se usa **solo si alguna regla en el `auth_hba_file` especifica `auth_method = trust` o `auth_method = md5` y además se quiere obtener la contraseña desde la base de datos** en lugar de `userlist.txt`.

 

### 🔎 ¿Cómo saber qué método se usa realmente?

Debes revisar el contenido de:

```bash
cat /sysx/data/pg_hba.conf
```

Ahí verás líneas como:

```
host    all     all     192.168.1.0/24    md5
host    all     all     127.0.0.1/32      trust
```

Cada línea define el método de autenticación (`md5`, `trust`, `cert`, etc.) para un rango de IPs, usuarios y bases de datos.

--- 

# archivo pgbouncer.ini

 ```
;;;
;;; PgBouncer configuration file
;;;

;; database name = connect string
;;
;; connect string params:
;;   dbname= host= port= user= password= auth_user=
;;   client_encoding= datestyle= timezone=
;;   pool_size= reserve_pool= max_db_connections=
;;   pool_mode= connect_query= application_name=
[databases]
* = host=127.0.0.1 port=5416 client_encoding=UTF8 datestyle=ISO dbname=postgres auth_user=postgres

;; foodb over Unix socket
;foodb =

;; redirect bardb to bazdb on localhost
;bardb = host=localhost dbname=bazdb

;; access to dest database will go with single user
;forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'

;; use custom pool sizes
;nondefaultdb = pool_size=50 reserve_pool=10

;; use auth_user with auth_query if user not present in auth_file
;; auth_user must exist in auth_file
; foodb = auth_user=bar

;; fallback connect string
;* = host=testserver

;; User-specific configuration
[users]

;user1 = pool_mode=transaction max_user_connections=10

;; Configuration section
[pgbouncer]

;;;
;;; Administrative settings
;;;

logfile = /pglogs/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid

;;;
;;; Where to wait for clients
;;;

;; IP address or * which means all IPs
listen_addr = *
listen_port = 5432

;; Unix socket is also used for -R.
;; On Debian it should be /var/run/postgresql
unix_socket_dir = /tmp
;unix_socket_mode = 0777
;unix_socket_group =

;;;
;;; TLS settings for accepting clients
;;;

;; disable, allow, require, verify-ca, verify-full
;client_tls_sslmode = disable

;; Path to file that contains trusted CA certs
;client_tls_ca_file = <system default>

;; Private key and cert to present to clients.
;; Required for accepting TLS connections from clients.
;client_tls_key_file =
;client_tls_cert_file =

;; fast, normal, secure, legacy, <ciphersuite string>
;client_tls_ciphers = fast

;; all, secure, tlsv1.0, tlsv1.1, tlsv1.2, tlsv1.3
;client_tls_protocols = all

;; none, auto, legacy
;client_tls_dheparams = auto

;; none, auto, <curve name>
;client_tls_ecdhcurve = auto

;;;
;;; TLS settings for connecting to backend databases
;;;

;; disable, allow, require, verify-ca, verify-full
;server_tls_sslmode = disable

;; Path to that contains trusted CA certs
;server_tls_ca_file = <system default>

;; Private key and cert to present to backend.
;; Needed only if backend server require client cert.
;server_tls_key_file =
;server_tls_cert_file =

;; all, secure, tlsv1.0, tlsv1.1, tlsv1.2, tlsv1.3
;server_tls_protocols = all

;; fast, normal, secure, legacy, <ciphersuite string>
;server_tls_ciphers = fast

;;;
;;; Authentication settings
;;;

;; any, trust, plain, md5, cert, hba, pam
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt

;; Path to HBA-style auth config
;auth_hba_file =

;; Query to use to fetch password from database.  Result
;; must have 2 columns - username and password hash.
;auth_query = SELECT usename, passwd FROM pg_shadow WHERE usename=$1

;;;
;;; Users allowed into database 'pgbouncer'
;;;

;; comma-separated list of users who are allowed to change settings
admin_users = postgres

;; comma-separated list of users who are just allowed to use SHOW command
stats_users = stats, postgres, sysnagios

;;;
;;; Pooler personality questions
;;;

;; When server connection is released back to pool:
;;   session      - after client disconnects (default)
;;   transaction  - after transaction finishes
;;   statement    - after statement finishes
pool_mode = transaction

;; Query for cleaning connection immediately after releasing from
;; client.  No need to put ROLLBACK here, pgbouncer does not reuse
;; connections where transaction is left open.
server_reset_query = DISCARD ALL

;; Whether server_reset_query should run in all pooling modes.  If it
;; is off, server_reset_query is used only for session-pooling.
;server_reset_query_always = 0

;; Comma-separated list of parameters to ignore when given in startup
;; packet.  Newer JDBC versions require the extra_float_digits here.
ignore_startup_parameters = extra_float_digits,geqo,lc_monetary

;; When taking idle server into use, this query is run first.
;server_check_query = select 1

;; If server was used more recently that this many seconds ago,
; skip the check query.  Value 0 may or may not run in immediately.
;server_check_delay = 30

;; Close servers in session pooling mode after a RECONNECT, RELOAD,
;; etc. when they are idle instead of at the end of the session.
;server_fast_close = 0

;; Use <appname - host> as application_name on server.
application_name_add_host = 1

;; Period for updating aggregated stats.
stats_period = 60

;;;
;;; Connection limits
;;;

;; Total number of clients that can connect
max_client_conn = 40000

;; Default pool size.  20 is good number when transaction pooling
;; is in use, in session pooling it needs to be the number of
;; max clients you want to handle at any moment
default_pool_size = 2000

;; Minimum number of server connections to keep in pool.
min_pool_size = 5

; how many additional connection to allow in case of trouble
reserve_pool_size = 1000

;; If a clients needs to wait more than this many seconds, use reserve
;; pool.
reserve_pool_timeout = 2

;; How many total connections to a single database to allow from all
;; pools
;max_db_connections = 0
;max_user_connections = 0

;; If off, then server connections are reused in LIFO manner
;server_round_robin = 0

;;;
;;; Logging
;;;

;; Syslog settings
;syslog = 0
;syslog_facility = daemon
;syslog_ident = pgbouncer

;; log if client connects or server connection is made
log_connections = 0

;; log if and why connection was closed
log_disconnections = 0

;; log error messages pooler sends to clients
log_pooler_errors = 1

;; write aggregated stats into log
;log_stats = 1

;; Logging verbosity.  Same as -v switch on command line.
verbose = 0

;;;
;;; Timeouts
;;;

;; Close server connection if its been connected longer.
;server_lifetime = 3600

;; Close server connection if its not been used in this time.  Allows
;; to clean unnecessary connections from pool after peak.
server_idle_timeout = 300

;; Cancel connection attempt if server does not answer takes longer.
server_connect_timeout = 30

;; If server login failed (server_connect_timeout or auth failure)
;; then wait this many second.
;server_login_retry = 15

;; Dangerous.  Server connection is closed if query does not return in
;; this time.  Should be used to survive network problems, _not_ as
;; statement_timeout. (default: 0)
;query_timeout = 0

;; Dangerous.  Client connection is closed if the query is not
;; assigned to a server in this time.  Should be used to limit the
;; number of queued queries in case of a database or network
;; failure. (default: 120)
query_wait_timeout = 120

;; Dangerous.  Client connection is closed if no activity in this
;; time.  Should be used to survive network problems. (default: 0)
;client_idle_timeout = 0

;; Disconnect clients who have not managed to log in after connecting
;; in this many seconds.
;client_login_timeout = 60

;; Clean automatically created database entries (via "*") if they stay
;; unused in this many seconds.
; autodb_idle_timeout = 3600

;; How long SUSPEND/-R waits for buffer flush before closing
;; connection.
;suspend_timeout = 10

;; Close connections which are in "IDLE in transaction" state longer
;; than this many seconds.
idle_transaction_timeout = 1200

;;;
;;; Low-level tuning options
;;;

;; buffer for streaming packets
;pkt_buf = 4096

;; man 2 listen
;listen_backlog = 128

;; Max number pkt_buf to process in one event loop.
;sbuf_loopcnt = 5

;; Maximum PostgreSQL protocol packet size.
;max_packet_size = 2147483647

;; networking options, for info: man 7 tcp

;; Linux: Notify program about new connection only if there is also
;; data received.  (Seconds to wait.)  On Linux the default is 45, on
;; other OS'es 0.
;tcp_defer_accept = 0

;; In-kernel buffer size (Linux default: 4096)
;tcp_socket_buffer = 0

;; whether tcp keepalive should be turned on (0/1)
;tcp_keepalive = 1

;; The following options are Linux-specific.  They also require
;; tcp_keepalive=1.

;; Count of keepalive packets
;tcp_keepcnt = 0

;; How long the connection can be idle before sending keepalive
;; packets
;tcp_keepidle = 0

;; The time between individual keepalive probes
;tcp_keepintvl = 0

;; DNS lookup caching time
;dns_max_ttl = 15

;; DNS zone SOA lookup period
;dns_zone_check_period = 0

;; DNS negative result caching time
;dns_nxdomain_ttl = 15

;;;
;;; Random stuff
;;;

;; Hackish security feature.  Helps against SQL injection: when PQexec
;; is disabled, multi-statement cannot be made.
;disable_pqexec = 0

;; Config file to use for next RELOAD/SIGHUP
;; By default contains config file from command line.
;conffile

;; Windows service name to register as.  job_name is alias for
;; service_name, used by some Skytools scripts.
;service_name = pgbouncer
;job_name = pgbouncer

;; Read additional config from other file
;%include /etc/pgbouncer/pgbouncer-other.ini


 ```



# Extras 

 ```

-------------------------- pool_mode = transaction --------------------------
session
Qué es: Mantiene la conexión durante toda la sesión del cliente.

Cuándo usarlo: Ideal cuando necesitas una conexión persistente, como en aplicaciones que mantienen el estado de la sesión.

Cuándo no usarlo: No es eficiente si tienes muchas conexiones cortas, ya que mantiene las conexiones abiertas, consumiendo recursos.

transaction
Qué es: Mantiene la conexión solo durante una transacción.

Cuándo usarlo: Útil para aplicaciones con muchas transacciones cortas. Libera conexiones rápidamente, optimizando recursos.

Cuándo no usarlo: Evita usarlo si necesitas mantener el estado más allá de una transacción.

statement
Qué es: Mantiene la conexión solo durante la ejecución de una declaración individual.

Cuándo usarlo: Ideal para aplicaciones que emiten declaraciones únicas y frecuentes.

Cuándo no usarlo: No es adecuado para transacciones complejas o aplicaciones que dependen de mantener el estado.


--------------------------------------------------------------------------------------------------------

auth_query = SELECT usename, passwd FROM pg_shadow WHERE usename = $1


;;max_client_conn: Número máximo de conexiones de cliente que PgBouncer permitirá.
max_client_conn = 100

;;default_pool_size: Número de conexiones de servidor que mantendrá en el grupo de conexiones por defecto.
default_pool_size = 20

;;min_pool_size: Número mínimo de conexiones de servidor que PgBouncer intentará mantener disponibles.
min_pool_size = 2

server_reset_query: Consulta SQL que se ejecutará para restablecer las conexiones del servidor antes de devolverlas al grupo.
server_reset_query = 'DISCARD ALL'


 ```
---

# Tipos de Pooling

PgBouncer es una herramienta esencial para gestionar conexiones en PostgreSQL, especialmente cuando tienes muchas aplicaciones o usuarios conectándose al mismo tiempo. Su funcionamiento se basa en tres modos de "pooleo" (`pool_mode`), cada uno con un nivel de agresividad distinto para reciclar las conexiones.

Aquí tienes el detalle de cada uno:
 
 
## 1. Session Pooling (Modo Sesión)

Es el modo más conservador y el que viene por defecto. Cuando una aplicación se conecta, PgBouncer le asigna una conexión del servidor y **esa aplicación se queda con ella hasta que se desconecta voluntariamente**.

* **Ventajas:** * Total compatibilidad: Soporta todas las funciones de PostgreSQL (tablas temporales, comandos `SET`, `LISTEN/NOTIFY`, `PREPARE`, etc.).
* Es transparente para la aplicación; se comporta exactamente como si estuvieras conectado directamente a la base de datos.


* **Desventajas:**
* Poca eficiencia de escala: Si tienes 500 usuarios conectados "en espera" (idle), gastarás 500 conexiones reales en el servidor de PostgreSQL.


* **Cuándo usarlo:** Para tareas administrativas, scripts de migración o aplicaciones que no pueden vivir sin funciones de sesión.
* **Cuándo NO usarlo:** En aplicaciones web con miles de usuarios concurrentes donde el servidor de BD tiene recursos limitados (RAM/CPU).

 
## 2. Transaction Pooling (Modo Transacción)

Es el modo **más utilizado y recomendado** para la mayoría de los casos. Aquí, PgBouncer le entrega una conexión a la aplicación **solo mientras dure una transacción** (`BEGIN` ... `COMMIT/ROLLBACK`). En cuanto termina la transacción, la conexión vuelve al pool para que otro usuario la use.

* **Ventajas:**
* Extrema eficiencia: Puedes tener 5,000 clientes conectados a PgBouncer, pero solo 50 conexiones reales en Postgres, siempre que no todos lancen transacciones al mismo milisegundo.
* Reduce drásticamente el consumo de memoria en el servidor de base de datos.


* **Desventajas:**
* Rompe funciones de sesión: No puedes usar `SET` (a menos que uses `SET LOCAL`), no funcionan los `ADVISORY LOCKS` de sesión y el uso de `PREPARE` requiere configuraciones especiales en versiones recientes.


* **Cuándo usarlo:** Aplicaciones web, microservicios y cualquier entorno de alta concurrencia.
* **Cuándo NO usarlo:** Si tu aplicación depende fuertemente de variables de sesión que deben persistir entre diferentes transacciones.
 

## 3. Statement Pooling (Modo Sentencia)

Es el modo más agresivo. La conexión se devuelve al pool **inmediatamente después de cada consulta SQL individual**.

* **Ventajas:**
* Máximo aprovechamiento de las conexiones del servidor.


* **Desventajas:**
* **No permite transacciones multi-sentencia**: Si intentas hacer un `BEGIN`, PgBouncer dará un error o la siguiente instrucción caerá en una conexión distinta, rompiendo la lógica.


* **Cuándo usarlo:** Solo si tu aplicación funciona exclusivamente en modo `autocommit` (una sola consulta a la vez) y necesitas una escala masiva.
* **Cuándo NO usarlo:** En el 99% de las aplicaciones modernas, ya que la mayoría usa transacciones (aunque sea de forma implícita).

 
### Tabla Comparativa de Resumen

| Característica | Session | Transaction | Statement |
| --- | --- | --- | --- |
| **Reciclaje de conexión** | Al desconectarse | Al terminar transacción | Al terminar cada query |
| **Escalabilidad** | Baja | **Muy Alta** | Máxima |
| **Tablas temporales** | Sí | No (solo dentro de la trans.) | No |
| **Comandos SET** | Sí | Solo `SET LOCAL` | No |
| **Recomendado para** | Admin / Migraciones | **Producción / Web** | Casos muy específicos |

 
## ¿Cuál es el recomendado?

En la gran mayoría de los escenarios de producción, se recomienda el **`pool_mode = transaction`**.

Este modo ofrece el mejor balance entre ahorro de recursos y funcionalidad. Permite que tu base de datos respire al mantener un número bajo de conexiones reales (que son costosas en memoria para PostgreSQL), mientras que tus aplicaciones pueden escalar casi sin límites.

### Recomendación Pro:

Si tu aplicación principal necesita **Transaction Mode** para escalar, pero tienes un par de tareas de mantenimiento que requieren **Session Mode**, puedes configurar **dos pools diferentes** en el mismo archivo `pgbouncer.ini` apuntando a la misma base de datos, cada uno con un modo distinto.

--- 
 
# Qué pasa si tengo miles de usuario intentando conectarse al mismo tiempo ?

Lo que parece como una posible "desventaja" es, en realidad, el escenario donde PgBouncer brilla, pero tiene matices importantes sobre cómo gestiona ese tráfico masivo.

Aquí te explico qué sucede técnicamente cuando miles de usuarios intentan entrar al mismo tiempo:

  
### 1. El concepto de "Cola de Espera" (Queuing)

A diferencia de PostgreSQL (que si llega al límite lanza un error de inmediato), PgBouncer actúa como un **amortiguador**.

* **Si tienes 5,000 usuarios** intentando conectarse pero solo **100 conexiones** reales a la base de datos (`default_pool_size = 100`):
* PgBouncer aceptará las 5,000 conexiones de red (siempre que tu configuración `max_client_conn` lo permita).
* Pondrá a los usuarios en una **cola interna**.
* A medida que las transacciones terminan (en modo `transaction`), la conexión se libera y se le entrega al siguiente usuario en la cola en milisegundos.



### 2. ¿Qué pasa si la cola es demasiado grande? (Desventajas reales)

Aunque PgBouncer evita que la base de datos muera, si el volumen es excesivo, podrías enfrentar estos problemas:

* **Latencia de Aplicación:** El usuario no verá un error de "Conexión rechazada", pero su consulta tardará más en responder porque está esperando su turno en la cola de PgBouncer.
* **Timeouts:** Si el tiempo de espera en la cola supera el `timeout` configurado en tu aplicación (o el `query_wait_timeout` de PgBouncer), la aplicación cortará la conexión pensando que la base de datos no responde.
* **Cuello de botella de CPU (Single-thread):** Históricamente, PgBouncer es **monohilo** (usa un solo núcleo del procesador). Aunque es extremadamente eficiente, si tienes una avalancha de miles de conexiones *nuevas* con SSL/TLS al mismo segundo, el proceso de "handshake" puede saturar ese núcleo de CPU.

 

### 3. Cómo manejar miles de usuarios (Buenas Prácticas 2026)

Si esperas miles de conexiones concurrentes, debes ajustar estos parámetros en tu `pgbouncer.ini`:

| Parámetro | Recomendación para miles de usuarios |
| --- | --- |
| **`max_client_conn`** | Súbelo a **5000** o **10000**. Es el límite total de usuarios "colgados" del pooler. |
| **`default_pool_size`** | Manténlo bajo (ej. **100-200**). Contra más bajo, más rápido responde Postgres, pero la cola será más larga. |
| **`reserve_pool_size`** | Configura un pequeño extra (ej. **20**) que solo se use cuando la cola esté muy llena. |
| **`ulimit -n`** | **Crucial:** Aumenta los límites de archivos abiertos en el Sistema Operativo (Linux), de lo contrario PgBouncer no podrá abrir miles de sockets. |

### 4. La solución definitiva: Escalado Horizontal

Si un solo PgBouncer se queda corto por el límite de CPU monohilo, la estrategia moderna es usar **múltiples instancias de PgBouncer** escuchando en el mismo puerto mediante una opción llamada `SO_REUSEPORT`. Esto permite que el tráfico se distribuya entre varios núcleos de CPU.
 

### Resumen: ¿Cuándo es un problema real?

* **Es una ventaja si:** Los usuarios hacen consultas rápidas. PgBouncer reciclará las conexiones tan rápido que nadie notará la espera.
* **Es una desventaja si:** Los usuarios abren transacciones muy largas (ej. reportes pesados). En ese caso, la cola no avanza, los 5,000 usuarios se quedan esperando y tu sistema se siente "congelado".

**Mi recomendación:** Usa siempre **`pool_mode = transaction`** para estos casos de alta concurrencia y asegúrate de que tus queries estén optimizadas (índices correctos) para que salgan rápido de la conexión y dejen paso al siguiente.

 
---
# Configuración potente para pgbouncer 

Para llevar a PostgreSQL y tu sistema operativo al límite de su capacidad en 2026, no basta con subir los números; hay que hacer que el sistema trabaje **en armonía**. Si configuras un parámetro muy alto sin ajustar el resto, crearás un cuello de botella en otro lugar (el famoso efecto "cobija corta").

Aquí tienes el "Blueprint" de una configuración inteligente dividida en los tres niveles de poder:

 

## Nivel 1: El Sistema Operativo (Linux Tuning)

Antes de tocar Postgres, debes preparar la pista de aterrizaje. Sin esto, el SO limitará a la base de datos.

* **Límites de Archivos (`ulimit`):** Postgres abre un archivo por cada tabla e índice, y un socket por cada conexión.
* *Configuración:* En `/etc/security/limits.conf`, sube `nofile` a **65535** o más para el usuario `postgres`.


* **Huge Pages (Páginas Gigantes):** Por defecto, Linux usa páginas de 4KB. Para bases de datos grandes, esto satura el "TLB cache" de la CPU.
* **Inteligencia:** Configura `huge_pages = try` en Postgres y reserva las páginas en el kernel (`vm.nr_hugepages`). Esto puede darte un **10-15%** de mejora de rendimiento bruto en CPU.


* **Swappiness:** No querrás que Postgres use el disco como RAM.
* *Configuración:* `vm.swappiness = 1`. No lo pongas en 0, para permitir que el SO mueva procesos secundarios, pero proteja a Postgres.


* **Transparent Huge Pages (THP):** **¡Apágalo!** Es el enemigo #1 de las bases de datos OLTP porque causa latencias aleatorias.

 
## Nivel 2: PostgreSQL Core (`postgresql.conf`)

Aquí es donde optimizas cómo Postgres consume el hardware.

| Parámetro | Configuración "Inteligente" | Por qué es vital |
| --- | --- | --- |
| **`shared_buffers`** | **25% a 30%** de la RAM total | Es el "caché de trabajo". No pongas más del 40%, ya que Postgres también depende del caché del SO. |
| **`work_mem`** | **Cálculo:**  | Es la RAM por cada operación de ordenamiento/join. Si es muy bajo, usa disco; si es muy alto, el OOM-Killer matará a Postgres. |
| **`maintenance_work_mem`** | **5%** de la RAM total | Acelera la creación de índices y el VACUUM. |
| **`effective_cache_size`** | **75%** de la RAM total | No reserva memoria; solo le dice al planificador cuánta RAM hay disponible en total (incluyendo el caché del SO). |
| **`max_worker_processes`** | Igual al número de CPUs lógicas | Permite que Postgres use paralelismo real para consultas pesadas. |

 

## Nivel 3: Gestión Explosiva con PgBouncer

Para gestionar miles de conexiones sin que el servidor colapse por el costo de "context switching" (el costo de la CPU de saltar entre 5,000 procesos), PgBouncer es obligatorio.

### La Configuración Maestra:

1. **`pool_mode = transaction`**: Es el único modo que te permitirá escalar a miles de usuarios reales.
2. **`max_client_conn = 10000`**: Capacidad de red para recibir a los usuarios.
3. **`default_pool_size = (CPUs \times 2) + (\text{Discos SSD})`**: Esta es la fórmula mágica. No necesitas 1,000 conexiones a la BD; necesitas que las que tengas sean ultra rápidas. Tener 100 conexiones reales procesando constantemente es mejor que 2,000 esperando en fila de CPU.
4. **`so_reuseport = 1`**: En versiones recientes, permite que múltiples procesos de PgBouncer escuchen en el mismo puerto, eliminando el cuello de botella del monohilo.

 

## El "Cálculo de Oro" para no morir en el intento

Si tienes un servidor con **64GB de RAM** y quieres 5,000 usuarios concurrentes vía PgBouncer:

1. **Postgres `max_connections**`: Ponlo en **200** o **300**. (PgBouncer se encargará del resto).
2. **`shared_buffers`**: **16GB**.
3. **`work_mem`**:



Configura `work_mem = 64MB`. Esto garantiza que incluso en el peor escenario de carga, tu servidor no se quedará sin RAM.

> **Nota Crítica:** Si usas **SSD o NVMe**, asegúrate de bajar `random_page_cost` a **1.1**. El valor por defecto (4.0) es de la época de los discos mecánicos y hace que Postgres ignore tus índices.

 


---
# Permisos 
 
### 1. Ver permisos en formato de lista (Simbólico)

Ejecuta el siguiente comando:

```bash
ls -l /etc/pgbouncer/userlist.txt

```

**Cómo interpretarlo:**

* Si ves `-rw-------`, tiene **600** (Lectura/Escritura solo para el dueño).
* Si ves `-rw-r--r--`, tiene **644** (Lectura para todos, lo cual es un riesgo si tienes la clave en texto plano).
* Si ves `-r--------`, tiene **400** (Solo lectura para el dueño).

### 2. Ver permisos en formato numérico (Octal)

Este es el método más directo para confirmar si es **600** exactamente:

```bash
stat -c "%a %n" /etc/pgbouncer/userlist.txt

ejemplo salida:
600 /etc/pgbouncer/userlist.txt

```

* **Resultado esperado:** Debería devolverte algo como `600 /etc/pgbouncer/userlist.txt`.

 

### 3. ¿Cómo corregirlos si son "más de 600"?

Si el resultado fue mayor (por ejemplo, 644 o 755), significa que otros usuarios del servidor podrían leer tu archivo `userlist.txt` y ver la contraseña del `pgbouncer_auth_user`.

Para dejarlo con la seguridad recomendada, ejecuta:

```bash
# Cambiar el dueño al usuario del servicio
sudo chown pgbouncer:pgbouncer /etc/pgbouncer/userlist.txt

# Restringir permisos a 600
sudo chmod 600 /etc/pgbouncer/userlist.txt

```
 

# Bibliografías 

 ```
Desmitificando PgBouncer: Explorando la agrupación de transacciones en el código fuente -> https://medium.com/@CoyoteLeo/demystifying-pgbouncer-exploring-transaction-pooling-in-source-code-33c759686a8a


PgBouncer -> https://medium.com/@CoyoteLeo/supercharge-your-postgresql-with-pgbouncer-a-comprehensive-guide-to-performance-and-efficiency-d2456c0ca289

reinicios continuos de PgBouncer -> https://medium.com/@CoyoteLeo/the-sigterm-vs-sigint-trade-off-a-deep-dive-into-pgbouncer-rolling-restarts-4f57c5cbfcb2

https://medium.com/@mohllal/database-connection-pooling-with-pgbouncer-2877c55cf3df
https://medium.com/@jramcloud1/postgresql-17-log-analysis-made-easy-complete-guide-to-setting-up-and-using-pgbadger-befb8e453433
https://medium.com/@Mahdi_ramadhan/handling-postgresql-connection-pooling-dee3849d0299

https://engineering.adjust.com/post/pgbouncer_authentication_layer/
https://medium.com/swlh/pgbouncer-installation-configuration-and-use-cases-for-better-performance-1806316f3a22
https://postgrespro.com/docs/postgrespro/12/pgbouncer


https://docs.vmware.com/en/VMware-Greenplum/7/greenplum-database/admin_guide-access_db-topics-pgbouncer.html
https://docs.vmware.com/en/VMware-Greenplum/7/greenplum-database/utility_guide-ref-pgbouncer-ini.html
https://www.cybertec-postgresql.com/en/pgbouncer-authentication-made-easy/
https://www.percona.com/blog/configuring-pgbouncer-for-multi-port-access/


https://dev.to/dm8ry/using-pgbouncer-to-improve-performance-and-reduce-the-load-on-postgresql-47k8
https://www.pgbouncer.org/config.html#generic-settings
https://www.pgbouncer.org/
https://access.crunchydata.com/documentation/pgbouncer/latest/pdf/pgbouncer.pdf
https://get.enterprisedb.com/docs/Tutorial_All_PPSS_pgBouncer.pdf
https://devcenter.heroku.com/articles/best-practices-pgbouncer-configuration
https://www.enterprisedb.com/postgres-tutorials/pgbouncer-authquery-and-authuser-pro-tips
https://www.enterprisedb.com/blog/pgbouncer-tutorial-installing-configuring-and-testing-persistent-postgresql-connection-pooling
 

https://www.scaleway.com/en/docs/tutorials/install-pgbouncer/


```
