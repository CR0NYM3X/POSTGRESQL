
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

CREATE FUNCTION public.lookup (
   INOUT p_user     name,
   OUT   p_password text
) RETURNS record
   LANGUAGE sql SECURITY DEFINER SET search_path = pg_catalog AS
$$SELECT usename, passwd FROM pg_shadow WHERE usename = p_user$$;
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




# Bibliografías 

 ```
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
