
### 🔄 **Flujo de manejo de conexiones persistentes con PgBouncer y PostgreSQL**

Este diagrama muestra cómo **PgBouncer**, un pool de conexiones para PostgreSQL, gestiona las conexiones entre los **clientes** y el **servidor PostgreSQL** de forma eficiente. El objetivo es **optimizar el uso de conexiones backend** sin que el cliente note la diferencia.

---

### 🧠 **Paso a paso del flujo**

1. **🔗 Conexión persistente del cliente a PgBouncer**  
   El cliente (una aplicación, por ejemplo) establece una conexión persistente con PgBouncer. Esta conexión no se cierra entre transacciones, lo que permite reutilizarla.

2. **📥 PgBouncer solicita una conexión backend**  
   Cuando el cliente inicia una transacción (`BEGIN`, una consulta SQL, etc.), PgBouncer necesita una conexión real a PostgreSQL. Entonces, **toma una conexión libre del pool** (por ejemplo, `ConnX`).

3. **🔄 Asignación temporal de ConnX al cliente**  
   PgBouncer **asigna temporalmente** esa conexión backend (`ConnX`) al cliente solo durante la duración de la transacción.

4. **⚙️ Ejecución de la transacción**  
   - El cliente envía la instrucción SQL.
   - PgBouncer la reenvía a PostgreSQL usando `ConnX`.
   - PostgreSQL procesa la instrucción y devuelve el resultado por `ConnX`.

5. **📤 Reenvío del resultado al cliente**  
   PgBouncer recibe el resultado desde PostgreSQL y lo **reenvía al cliente**.

6. **✅ Finalización de la transacción**  
   El cliente envía `COMMIT` o `ROLLBACK`. PgBouncer lo reenvía a PostgreSQL usando `ConnX`, y PostgreSQL confirma la finalización.

7. **🏁 Transacción concluida**  
   La transacción ha terminado correctamente.

8. **🔁 Liberación de ConnX al pool**  
   PgBouncer **libera la conexión backend** (`ConnX`) y la devuelve al pool para que pueda ser usada por otro cliente.

9. **📬 Confirmación al cliente**  
   El cliente recibe la confirmación del `COMMIT` o `ROLLBACK`.

10. **🔄 Cliente sigue conectado a PgBouncer**  
    Aunque la conexión backend fue liberada, **la conexión entre el cliente y PgBouncer permanece activa**, lista para futuras transacciones.
 

### 🧩 ¿Por qué es importante este flujo?

- **PgBouncer actúa como intermediario inteligente**, reutilizando conexiones backend para múltiples clientes.
- Esto **reduce el consumo de recursos** en PostgreSQL, especialmente en sistemas con muchos clientes concurrentes.
- PgBouncer permite **escalar mejor** las aplicaciones sin saturar el servidor de base de datos.

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

 
# 🔁 PgBouncer `pool_mode`: tipos, diferencias y cuándo usar cada uno

PgBouncer no es solo “un pool”, sino que **cambia el modelo de conexión** a PostgreSQL dependiendo del `pool_mode`.

***

## 🧠 Concepto base (imprescindible)

PgBouncer **separa**:

*   🔹 **Sesión del cliente** (psql / app)
*   🔹 **Conexión backend a PostgreSQL**

👉 Según el `pool_mode`, **cómo y cuándo** se asigna un backend **cambia completamente**.

***

## 📌 Tipos de `pool_mode`

PgBouncer tiene **3 modos**:

1.  `session`
2.  `transaction`
3.  `statement`

Vamos uno por uno.

***

## 1️⃣ `pool_mode = session` (más seguro, más predecible)

### 🔍 ¿Cómo funciona?

*   Un cliente obtiene **una conexión backend dedicada**
*   La conserva **hasta que se desconecta**
*   Cuando el cliente se va ➜ PgBouncer **cierra o libera** el backend

```text
Cliente ──────────► Backend PostgreSQL
```

***

### ✅ ¿Qué SÍ funciona aquí?

*   ✅ TEMP TABLE
*   ✅ `SET` / `RESET`
*   ✅ `search_path`
*   ✅ Cursores
*   ✅ Prepared statements
*   ✅ `LISTEN / NOTIFY`
*   ✅ Comportamiento idéntico a conectar directo a Postgres

***

### ❌ ¿Desventajas?

*   ❌ Menor capacidad de escalado
*   ❌ Más conexiones concurrentes a PostgreSQL

***

### ✅ ¿Cuándo usarlo?

Usa `session` cuando:

✔ Usas **TEMP TABLE**  
✔ Usas **SECURITY DEFINER**  
✔ Esperas sesiones limpias y aisladas  
✔ Prefieres **seguridad y predictibilidad**  
✔ Tu carga no es extrema

📌 **Recomendado para entornos críticos y sensibles**

***

## 2️⃣ `pool_mode = transaction` (el más usado, el más peligroso si no se entiende)

### 🔍 ¿Cómo funciona?

*   Cada **transacción** obtiene un backend
*   Al terminar la transacción (`COMMIT/ROLLBACK`), el backend se **devuelve al pool**
*   El siguiente cliente puede recibir **ese mismo backend**

```text
Cliente A ── TX ──► Backend #1
Cliente B ── TX ──► Backend #1 (reusado)
```

***

### ✅ ¿Qué SÍ funciona?

*   ✅ Queries simples
*   ✅ OLTP clásico
*   ✅ Transacciones cortas
*   ✅ Alto volumen de conexiones

***

### ❌ ¿Qué NO funciona bien?

*   ❌ TEMP TABLE (heredan estado)
*   ❌ `SET search_path`
*   ❌ `SET ROLE`
*   ❌ Session variables
*   ❌ Cursor persistente
*   ❌ Código con estado de sesión

***

### ⚠️ Riesgos reales

*   Contaminación entre usuarios
*   Hijacking con `pg_temp`
*   Comportamiento no determinista
*   Bugs intermitentes difíciles de reproducir

***

### ✅ ¿Cuándo usarlo?

Usa `transaction` cuando:

✔ Aplicación **stateless**
✔ SOLO SQL puro por transacción
✔ NO usas TEMP TABLE
✔ NO usas funciones basadas en sesión
✔ Necesitas **alta concurrencia**

📌 **Es el modo más común en microservicios**, pero también el que más incidentes genera si se usa mal.

***

## 3️⃣ `pool_mode = statement` (el más extremo, casi nunca recomendado)

### 🔍 ¿Cómo funciona?

*   Cada **statement individual** usa un backend
*   Entre statements el backend puede cambiar

```text
SELECT → Backend #1
INSERT → Backend #7
UPDATE → Backend #3
```

***

### ✅ ¿Qué SÍ funciona?

*   ✅ SELECTs simples
*   ✅ Cargas muy controladas
*   ✅ Workloads extremadamente simples

***

### ❌ ¿Qué NO funciona?

*   ❌ Transacciones
*   ❌ TEMP TABLE
*   ❌ Funciones complejas
*   ❌ Prepared statements
*   ❌ Cualquier cosa con estado

***

### ✅ ¿Cuándo usarlo?

🟡 **Casi nunca**

Solo si:

*   Conoces exactamente tus queries
*   No usas transacciones
*   Quieres máxima reutilización
*   Estás dispuesto a aceptar muchas limitaciones

***

## 📊 Comparativa rápida (clara)

| Característica           | session | transaction       | statement |
| ------------------------ | ------- | ----------------- | --------- |
| TEMP TABLE               | ✅       | ❌                 | ❌         |
| search\_path persistente | ✅       | ❌                 | ❌         |
| Seguridad                | 🔒 Alta | ⚠️ Media          | ⚠️ Baja   |
| Escalabilidad            | Media   | Alta              | Muy alta  |
| Debug / predictibilidad  | ✅       | ❌                 | ❌         |
| Uso recomendado          | ✅ Sí    | ✅ Sí (con reglas) | ❌ No      |

***

## 🧠 Regla de oro (léela dos veces)

> **Si tu código espera “estado de sesión”, NO uses `transaction` ni `statement`.**

Esto incluye:

*   TEMP TABLE
*   `SECURITY DEFINER`
*   `search_path`
*   Variables de configuración

***

## 🔐 Recomendación profesional (alineada a todo lo que viste)

Basado en:

*   Hijacking
*   SECURITY DEFINER
*   pg\_temp
*   copy\_conf
*   Funciones privilegiadas

### ✅ Reglas claras

*   Usa **`session`** para:
    *   Funciones sensibles
    *   Administración
    *   Exportación (`COPY`)
*   Usa **`transaction`** solo para:
    *   Apps simples
    *   Queries cortas
    *   Sin estado de sesión
*   **Nunca mezcles TEMP + transaction**

***

## ✅ Configuración ejemplo recomendada

```ini
[databases]
app_db = host=127.0.0.1 dbname=app_db pool_mode=session
```

O incluso **dos pools distintos**:

*   Uno `session` para admin / funciones
*   Uno `transaction` para la app

***

## 🧠 Conclusión

*   PgBouncer **no es transparente**
*   `pool_mode` define **qué garantías tienes**
*   Elegir mal **rompe seguridad y lógica**
*   Tu molestia con las TEMP es **una señal correcta**

👉 **El problema no es PgBouncer, es usar el modo equivocado para el tipo de aplicación.**
 


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
