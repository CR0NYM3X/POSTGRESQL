
cat /sysd/datad/postgresql.conf | grep log_

#  SYSLOG
```sql
https://documentation.solarwinds.com/en/success_center/loggly/content/admin/postgresql-logs.htm
https://gist.github.com/ceving/4eae4437d793ae4752b8582253872067

```

# Leer el log desde la base de datos 
```sql


log_destination = 'stderr'
log_filename = 'postgresql.log'
log_truncate_on_rotation = off
log_line_prefix = '%t@%r@%a@%d@%u@%p@%c@%i'


pg_ctl reload -D $PGDATA15





\c postgres 
CREATE EXTENSION file_fdw;

CREATE SERVER log_postgres
FOREIGN DATA WRAPPER file_fdw;



CREATE FOREIGN TABLE fdw_log_postgres (
   log_time TEXT,
   remote_host_and_port TEXT,
   application_name TEXT,
   database_name TEXT,
   user_name TEXT,
   process_id TEXT,
   session_id TEXT,
   command_tag TEXT
)
SERVER log_postgres
OPTIONS (filename '/sysx/data15/pg_log/postgresql.log', format 'csv', delimiter '@', header 'false');


\det 

 -- drop foreign table fdw_log_postgres;

postgres@postgres# select  * from fdw_log_postgres order by log_time desc limit 10 ; ;
+-[ RECORD 1 ]---------+----------------------------------------------------------------------------------------+
| log_time             | 2024-11-19 12:55:13 MST                                                                |
| remote_host_and_port | [local]                                                                                |
| application_name     | psql                                                                                   |
| database_name        | postgres                                                                               |
| user_name            | postgres                                                                               |
| process_id           | 3262927                                                                                |
| session_id           | 673cec90.31c9cf                                                                        |
| command_tag          | idleLOG:  statement: select  * from fdw_log_postgres order by log_time desc limit 10 ; |
+-[ RECORD 2 ]---------+----------------------------------------------------------------------------------------+
| log_time             | 2024-11-19 12:55:10 MST                                                                |
| remote_host_and_port | [local]                                                                                |
| application_name     | psql                                                                                   |
| database_name        | postgres                                                                               |
| user_name            | postgres                                                                               |
| process_id           | 3262927                                                                                |
| session_id           | 673cec90.31c9cf                                                                        |
| command_tag          | idleLOG:  duration: 0.067 ms                                                           |
+-[ RECORD 3 ]---------+----------------------------------------------------------------------------------------+
| log_time             | 2024-11-19 12:55:10 MST                                                                |
| remote_host_and_port | [local]                                                                                |
| application_name     | [unknown]                                                                              |
| database_name        | [unknown]                                                                              |
| user_name            | [unknown]                                                                              |
| process_id           | 3263456                                                                                |
| session_id           | 673ced1e.31cbe0                                                                        |
| command_tag          | LOG:  connection received: host=[local]                                                |
+-[ RECORD 4 ]---------+----------------------------------------------------------------------------------------+
| log_time             | 2024-11-19 12:55:10 MST                                                                |
| remote_host_and_port | [local]                                                                                |
| application_name     | psql                                                                                   |
| database_name        | postgres                                                                               |
| user_name            | postgres                                                                               |
| process_id           | 3262927                                                                                |
| session_id           | 673cec90.31c9cf                                                                        |
| command_tag          | idleLOG:  statement: ;                                                                 |
+-[ RECORD 5 ]---------+----------------------------------------------------------------------------------------+



```

# Habilita el recolector de logs.
logging_collector = on


log_statement = 'all'

'none': No se registrarán declaraciones SQL (por defecto).
'ddl': Solo se registrarán declaraciones que modifican la estructura de la base de datos, como CREATE, ALTER, DROP, etc.
'mod': Se registrarán declaraciones que modifican datos, como INSERT, UPDATE y DELETE.
'read': Se registrarán declaraciones SELECT y COPY FROM.


# Configura la carpeta donde se almacenarán los logs.
log_directory = '/ruta/a/la/carpeta/pg_log'

# Configura el formato del nombre del archivo de log.
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'    # Nombre del archivo de registro

# Retención de logs basada en el tamaño.
log_rotation_size = 10MB  # Ajusta el tamaño según tus necesidades.

# Define la zona horaria utilizada para registrar la fecha y la hora en los archivos de log
log_timezone = 'America/Mazatlan'

# Establece los permisos del archivo de log. En este caso, se establece en 0600, 
log_file_mode = 0600

# Cuando esta opción está activada (on), indica que los archivos de log deben truncarse (vaciar) al realizar una rotación. La rotación ocurre cuando se alcanza un tamaño máximo (configurado por log_rotation_size) o después de un cierto período
log_truncate_on_rotation = on


Auditorias:
 https://github.com/pgaudit/pgaudit/tree/master
 https://www.crunchydata.com/blog/pgaudit-auditing-database-operations-part-1
 https://severalnines.com/blog/how-to-audit-postgresql-database/




