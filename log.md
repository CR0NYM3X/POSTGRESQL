
cat /sysd/datad/postgresql.conf | grep log_

#  SYSLOG
```sql
https://documentation.solarwinds.com/en/success_center/loggly/content/admin/postgresql-logs.htm
https://gist.github.com/ceving/4eae4437d793ae4752b8582253872067

```

# Trabajar con los  logs compresos 
```sql

comprimir
tar -czvf archivo_comprimido.tar.gz archivo_o_directorio

descomprimir
tar -xzvf archivo_comprimido.tar.gz

*** Buscar informacion sin descomprimir archivo ***
tar --to-stdout -xf postgresql-05.tar.gz | grep -a fun_test -B20 > /tmp/logs_cp/postgresql-05.txt
tar -O -xzf  postgresql-250101.tar.gz

zcat postgresql-05.tar.gz | grep -a fun_test -B20

*** Obtener log desde un rango de fechas  ***
sed -n '/2023-07-25 11:23:56/,/2023-07-25 11:24:08/p' postgresql.log   > postgresql_new.log


***  saltos de lines  *** 
  -B, --before-context=NUM  print NUM lines of leading context
  -A, --after-context=NUM   print NUM lines of trailing context
grep filtro -A5 -B5 postgresql.log > /tmp/log_guia

***  Buscar por número de lineas  *** 
sed -n 184941,202414p postgresql-11.log
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



# Filtros 
```sql
# El parametro tiene que estar configurado de esta forma
log_line_prefix  = <%t %r %a %d %u %p %c %i>


************ CANTIDAD DE INTENTOS FALLIDOS POR CONTRASEÑAS ************
cat  postgresql-250312.log   | grep -Ei failed | grep -Ei password  | awk '{print "IP: " $4 " DB:" $6 " User:" $7}'   | sed 's/(.*)//g' | sort  | uniq -c




************ MONITOREAR TODAS LAS CONEXIONES DE POSTGRESQL ************
--- Mensajes del log
<2025-04-04 12:02:10 MST 192.29.249.242(55776) [unknown] [unknown] [unknown] 494973 67f02cb2.78d7d >LOG:  connection received: host=192.29.249.242 port=55776
<2025-04-04 12:02:10 MST 192.29.249.242(55776) [unknown] db_test tantor 494973 67f02cb2.78d7d authentication>LOG:  connection authenticated: identity="tantor" method=scram-sha-256 (/sysx/data16/pg_hba.conf:146)
<2025-04-04 12:02:10 MST 192.29.249.242(55776) [unknown] db_test tantor 494973 67f02cb2.78d7d authentication>LOG:  connection authorized: user=tantor database=db_test application_name=TEST_APP
<2025-04-04 12:04:35 MST 192.29.249.242(56269) [unknown] postgresc postgres 495383 67f02d43.78f17 authentication>FATAL:  no pg_hba.conf entry for host "192.29.249.242", user "postgres", database "postgresc", no encryption
<2025-04-03 10:44:49 MST 192.44.164.40(60330) [unknown] db_test user_test 1181741 67eec911.12082d authentication>FATAL:  password authentication failed for user "user_test"
<2025-03-24 20:43:50 MST [local] [unknown] db_test postgres 3413860 67e22676.341764 authentication>DETAIL:  Connection matched file "/sysx/data16/pg_hba.conf" line 123: "local   all             all                                     ident map=new_name"

 

	DROP TABLE IF EXISTS tmp_con_validations_1;
 
	create temporary table  tmp_con_validations_1
	(	
		con_date TIMESTAMP,
		ip_address VARCHAR(45),
		app_name VARCHAR(50),
		db_name VARCHAR(50),
		user_name VARCHAR(50),
		session_id VARCHAR(50),
		event_type VARCHAR(50),
		status VARCHAR(50),
		msg TEXT
	); 
	
	
	COPY tmp_con_validations_1 from  PROGRAM $$ 
	
	tar --to-stdout -xf /sysx/data16/pg_log/postgresql-$(date -d "yesterday" +"%y%m%d").tar.gz | grep -aE "authentication>|connection received:"     | awk  ' {   gsub(/\(.*\)/, "", $4); gsub(/[<\[\]]/, ""); gsub(">", "?"); print $1 " " $2  "?" $4 "?" $5 "?" $6 "?" $7 "?" $9 "?" $10 "?"  substr($0, index($0,$11))} ' 
	 
	$$ WITH (FORMAT CSV,DELIMITER '?');  
	
	
	select * from  tmp_con_validations_1;

```

Auditorias:
 https://github.com/pgaudit/pgaudit/tree/master
 https://www.crunchydata.com/blog/pgaudit-auditing-database-operations-part-1
 https://severalnines.com/blog/how-to-audit-postgresql-database/




