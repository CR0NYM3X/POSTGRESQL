
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

postgres@postgres# select  *  from fdw_log_postgres where command_tag ilike '%fatal:%' order by log_time desc ;
+-[ RECORD 1 ]---------+------------------------------------+
| log_time             | 2024-11-19 12:58:58 MST            |
| remote_host_and_port | NULL                               |
| application_name     | NULL                               |
| database_name        | NULL                               |
| user_name            | NULL                               |
| process_id           | 3263704                            |
| session_id           | 673cee01.31ccd8                    |
| command_tag          | FATAL:  could not load pg_hba.conf |
+----------------------+------------------------------------+


postgres@postgres# select  *  from fdw_log_postgres where command_tag ilike '%error:%' order by log_time desc ;
+-[ RECORD 1 ]---------+-------------------------------------------------------------------------------------------------------------------+
| log_time             | 2024-11-19 13:03:09 MST                                                                                           |
| remote_host_and_port | [local]                                                                                                           |
| application_name     | psql                                                                                                              |
| database_name        | postgres                                                                                                          |
| user_name            | postgres                                                                                                          |
| process_id           | 3263760                                                                                                           |
| session_id           | 673cee0c.31cd10                                                                                                   |
| command_tag          | idleLOG:  statement: select  *  from fdw_log_postgres where command_tag ilike '%error:%' order by log_time desc ; |
+-[ RECORD 2 ]---------+-------------------------------------------------------------------------------------------------------------------+
| log_time             | 2024-11-19 12:59:09 MST                                                                                           |
| remote_host_and_port | [local]                                                                                                           |
| application_name     | psql                                                                                                              |
| database_name        | postgres                                                                                                          |
| user_name            | postgres                                                                                                          |
| process_id           | 3263760                                                                                                           |
| session_id           | 673cee0c.31cd10                                                                                                   |
| command_tag          | idleERROR:  syntax error at or near q at character 56                                                             |
+-[ RECORD 3 ]---------+-------------------------------------------------------------------------------------------------------------------+
| log_time             | 2024-11-19 12:58:40 MST                                                                                           |
| remote_host_and_port | [local]                                                                                                           |
| application_name     | psql                                                                                                              |
| database_name        | postgres                                                                                                          |
| user_name            | postgres                                                                                                          |
| process_id           | 3263658                                                                                                           |
| session_id           | 673cedd4.31ccaa                                                                                                   |
| command_tag          | idleERROR:  syntax error at or near q at character 56                                                             |
+-[ RECORD 4 ]---------+-------------------------------------------------------------------------------------------------------------------+
| log_time             | 2024-11-19 12:57:14 MST                                                                                           |
| remote_host_and_port | [local]                                                                                                           |
| application_name     | psql                                                                                                              |
| database_name        | postgres                                                                                                          |
| user_name            | postgres                                                                                                          |
| process_id           | 3262927                                                                                                           |
| session_id           | 673cec90.31c9cf                                                                                                   |
| command_tag          | TRUNCATE TABLEERROR:  cannot truncate foreign table fdw_log_postgres                                              |
+----------------------+-------------------------------------------------------------------------------------------------------------------+

```

Auditorias:
 https://github.com/pgaudit/pgaudit/tree/master
 https://www.crunchydata.com/blog/pgaudit-auditing-database-operations-part-1
 https://severalnines.com/blog/how-to-audit-postgresql-database/




