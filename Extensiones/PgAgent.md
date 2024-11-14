# PgAgent

### Automatización de Tareas Remotas, local:
  -	Permite la programación de tareas Ejecutando código SQL  o Batch repetitivas como respaldos, mantenimiento y ejecución de scripts, lo cual ahorra tiempo y reduce errores humanos.

### Interfaz Gráfica con pgAdmin:
  -	Puedes gestionar los trabajos a través de una interfaz gráfica amigable en pgAdmin, lo que facilita la creación, edición y monitoreo de trabajos.

### Monitoreo y Logging:
  -	Registra el estado de ejecución de los trabajos en una tabla, lo que facilita el monitoreo y la detección de errores. Además, los detalles de la ejecución y los errores se pueden revisar fácilmente.

### Flexibilidad en la Programación:
  -	Puedes programar tareas para que se ejecuten a intervalos específicos, en ciertos días de la semana, fechas concretas, etc., proporcionando gran flexibilidad en la planificación.

  ---

# Ejemplos 
  
## Configuración de PgAgent

```sql

-- /****** VALIDAR LOS PGAGENT DISPONIBLES ******\
[postgres@TEST_SERVER ]$ ls -lhtr /usr/bin | grep -i pgagent
-rwxr-xr-x. 1 root root     399K Nov 18  2022 pgagent_14
-rwxr-xr-x. 1 root root     399K Nov 18  2022 pgagent_15
-rwxr-xr-x. 1 root root     399K Sep 13  2023 pgagent_16


-- /****** CREAR EL USUARIO PGAGENT Y CREAMOS LA EXTENSION pgagent  ******\
[postgres@TEST_SERVER ~]$ psql -p 5416 -d postgres -U postgres -h 127.0.0.1
Password for user postgres:

 🐘 Current Host Server Date Time : Wed Nov 13 18:27:43 MST 2024

psql (16.4)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.


postgres@postgres# CREATE EXTENSION pgagent;
CREATE EXTENSION
Time: 46.130 ms

postgres@postgres# create user pgagent with password '8PjXd5gmux5U7XdTtOahsblrNAwHE0!#';
CREATE ROLE
Time: 10.869 ms
postgres@postgres# grant connect on database postgres to pgagent;
GRANT
Time: 1.580 ms
postgres@postgres# grant all privileges on all tables in schema  pg_catalog to pgagent;
GRANT
Time: 9.463 ms
postgres@postgres# grant all privileges on all tables in schema  information_schema to pgagent;
GRANT
Time: 4.770 ms
postgres@postgres# GRANT USAGE ON SCHEMA pgagent TO pgagent;
GRANT
Time: 1.219 ms
postgres@postgres# GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pgagent TO pgagent;
GRANT
Time: 1.029 ms
postgres@postgres# GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA pgagent TO pgagent;
GRANT
Time: 0.739 ms
postgres@postgres# GRANT  TEMPORARY ON DATABASE postgres TO pgagent;
GRANT
Time: 0.810 ms
postgres@postgres# grant pg_execute_server_program to  pgagent;
GRANT ROLE
Time: 1.604 ms



-- /****** MODIFICAMOS DE AUTENTICACIÓN A PEER  EN ARCHIVO PG_HBA.CONF ******\
[postgres@TEST_SERVER ]$ vim /sysx/data16/pg_hba.conf

# TYPE  DATABASE        USER            ADDRESS                 METHOD
#local   all             all                                     peer # "local" is for Unix domain socket connections only
host    all             all             127.0.0.1/32            scram-sha-256


-- /****** MODIFICAMOS PGPASS PARA QUE PUEDA AUTENTICARSE SIN CONTRASEÑA ******\
touch /home/postgres/.pgpass
chmod 0600 /home/postgres/.pgpass

[postgres@TEST_SERVER ~]$ echo "127.0.0.1:5416:postgres:pgagent:YkLPv4NWNT+5QsE.s/+3t*NPwCBc1d" >> /home/postgres/.pgpass
[postgres@TEST_SERVER ~]$ cat /home/postgres/.pgpass
127.0.0.1:5416:postgres:pgagent:YkLPv4NWNT+5QsE.s/+3t*NPwCBc1d



-- /****** INICIAR EL SERVICIO DE PGAGENT ******\ 
[postgres@TEST_SERVER ~]$ pgagent_16   hostaddr=127.0.0.1 port=5416 dbname=postgres user=pgagent -l 2 -s /sysx/data16/pg_log/pgagent_16.log
[postgres@TEST_SERVER ~]$ cat /sysx/data16/pg_log/pgagent_16.log
Wed Nov 13 18:24:57 2024 DEBUG: Creating primary connection
Wed Nov 13 18:24:57 2024 DEBUG: Parsing connection information...
Wed Nov 13 18:24:57 2024 DEBUG: Creating DB connection: user=pgagent dbname=postgres hostaddr=127.0.0.1 port=5416 dbname=postgres
Wed Nov 13 18:24:57 2024 DEBUG: Database sanity check
Wed Nov 13 18:24:57 2024 DEBUG: Clearing zombies
Wed Nov 13 18:24:57 2024 DEBUG: Checking for jobs to run
Wed Nov 13 18:24:57 2024 DEBUG: Sleeping...


-- /****** VALIDAMOS SE HAYA INICIADO EL SERVICIO  ******\
-- [NOTA] : En caso de requerir contraseña puedes usar el parametro password= pero por seguridad no se coloca 
[postgres@TEST_SERVER ~]$ ps -fea | grep pga
postgres 2415142       1  0 18:24 pts/7    00:00:00 pgagent_16 hostaddr=127.0.0.1 port=5416 dbname=postgres user=pgagent -l 2 -s /sysx/data16/pg_log/pgagent_16.log
postgres 2415144 2222739  0 18:24 ?        00:00:00 postgres: pgagent postgres 127.0.0.1(38764) idle
postgres 2415209 2406452  0 18:25 pts/7    00:00:00 grep --color=auto pga


-- /****** VALIDAMOS QUE NO HAYA MARCADO ERROR  ******\ 
tail -f /sysx/data16/pg_log/pgagent_16.log # Valida el log de pgagent
tail -f postgresql-241113.log # Valida el log de postgres

 


```

# Creación de JOB 
```sql

  

postgres@postgres# select now();
+-------------------------------+
|              now              |
+-------------------------------+
| 2024-11-05 12:25:00.278068-07 |
+-------------------------------+
(1 row)

-- Creating a new job
INSERT INTO pgagent.pga_job(
    jobjclid, jobname, jobdesc, jobhostagent, jobenabled
) VALUES (
    1::integer, 'TEST_JOB_2024'::text, ''::text, ''::text, true
) ;


-- Steps
-- Inserting a step (jobid: NULL)
INSERT INTO pgagent.pga_jobstep (
    jstjobid, jstname, jstenabled, jstkind,
    jstconnstr, jstdbname, jstonerror,
    jstcode, jstdesc
) VALUES (
    4, 'TEST_JOB_STEPS'::text, true, 's'::character(1),
    ''::text, 'postgres'::name, 'f'::character(1),
    ' COPY (select ''hola mundoooo!!!!!'') to PROGRAM ''cat > /tmp/filetest.txt'' WITH (FORMAT CSV);'::text, ''::text
) ;

-- Schedules
-- Inserting a schedule
INSERT INTO pgagent.pga_schedule(
    jscjobid, jscname, jscdesc, jscenabled,
    jscstart,     jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths
) VALUES (
    4, 'TEST_JOB_SCHEDULES'::text, ''::text, true,
    '2024-11-05 12:27:18 -07:00'::timestamp with time zone, 
    -- Minutes
    '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}'::bool[]::boolean[],
    -- Hours
    '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}'::bool[]::boolean[],
    -- Week days
    '{f,f,f,f,f,f,f}'::bool[]::boolean[],
    -- Month days
    '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}'::bool[]::boolean[],
    -- Months
    '{f,f,f,f,f,f,f,f,f,f,f,f}'::bool[]::boolean[]
) ;
 


postgres@postgres# select * from pgagent.pga_job       ;
+-[ RECORD 1 ]-+-------------------------------+
| jobid        | 4                             |
| jobjclid     | 1                             |
| jobname      | TEST_JOB_2024                 |
| jobdesc      |                               |
| jobhostagent |                               |
| jobenabled   | t                             |
| jobcreated   | 2024-11-05 12:26:16.870925-07 |
| jobchanged   | 2024-11-05 12:26:16.870925-07 |
| jobagentid   | NULL                          |
| jobnextrun   | 2024-11-05 12:32:00-07        |
| joblastrun   | 2024-11-05 12:30:03.384425-07 |
+--------------+-------------------------------+
Time: 1.265 ms

postgres@postgres# select * from pgagent.pga_jobstep   ;
+-[ RECORD 1 ]---------------------------------------------------------------------------------------------+
| jstid      | 3                                                                                           |
| jstjobid   | 4                                                                                           |
| jstname    | TEST_JOB_STEPS                                                                              |
| jstdesc    |                                                                                             |
| jstenabled | t                                                                                           |
| jstkind    | s                                                                                           |
| jstcode    |  COPY (select 'hola mundoooo!!!!!') to PROGRAM 'cat > /tmp/filetest.txt' WITH (FORMAT CSV); |
| jstconnstr |                                                                                             |
| jstdbname  | postgres                                                                                    |
| jstonerror | f                                                                                           |
| jscnextrun | NULL                                                                                        |
+------------+---------------------------------------------------------------------------------------------+
Time: 0.610 ms

postgres@postgres# select * from pgagent.pga_schedule  ;
+-[ RECORD 1 ]-+---------------------------------------------------------------------------------------------------------------------------+
| jscid        | 3                                                                                                                         |
| jscjobid     | 4                                                                                                                         |
| jscname      | TEST_JOB_SCHEDULES                                                                                                        |
| jscdesc      |                                                                                                                           |
| jscenabled   | t                                                                                                                         |
| jscstart     | 2024-11-05 12:27:18-07                                                                                                    |
| jscend       | NULL                                                                                                                      |
| jscminutes   | {f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f} |
| jschours     | {f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}                                                                         |
| jscweekdays  | {f,f,f,f,f,f,f}                                                                                                           |
| jscmonthdays | {f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}                                                         |
| jscmonths    | {f,f,f,f,f,f,f,f,f,f,f,f}                                                                                                 |
+--------------+---------------------------------------------------------------------------------------------------------------------------+
Time: 0.784 ms




postgres@postgres#  select * from pgagent.pga_joblog    ;
+-------+----------+-----------+-------------------------------+-----------------+
| jlgid | jlgjobid | jlgstatus |           jlgstart            |   jlgduration   |
+-------+----------+-----------+-------------------------------+-----------------+
|     1 |        4 | s         | 2024-11-05 12:28:03.389578-07 | 00:00:00.024947 |
+-------+----------+-----------+-------------------------------+-----------------+
(1 row)

Time: 0.368 ms
 
postgres@postgres#  select * from pgagent.pga_jobsteplog;
+-------+----------+----------+-----------+-----------+-------------------------------+-----------------+-----------+
| jslid | jsljlgid | jsljstid | jslstatus | jslresult |           jslstart            |   jslduration   | jsloutput |
+-------+----------+----------+-----------+-----------+-------------------------------+-----------------+-----------+
|     1 |        1 |        3 | s         |         1 | 2024-11-05 12:28:03.393489-07 | 00:00:00.019052 |           |
+-------+----------+----------+-----------+-----------+-------------------------------+-----------------+-----------+
(1 row)



[postgres@TEST_SERVER ]$ cat /tmp/filetest.txt
hola mundoooo!!!!!

 

```


# Info Extra
```sql
postgres@postgres# \df pgagent.*

postgres@postgres# select table_schema,table_name,table_type from information_schema.tables where table_schema = 'pgagent';
+--------------+----------------+------------+
| table_schema |   table_name   | table_type |
+--------------+----------------+------------+
| pgagent      | pga_exception  | BASE TABLE |
| pgagent      | pga_joblog     | BASE TABLE |
| pgagent      | pga_jobsteplog | BASE TABLE |
| pgagent      | pga_jobclass   | BASE TABLE |
| pgagent      | pga_job        | BASE TABLE |
| pgagent      | pga_jobagent   | BASE TABLE |
| pgagent      | pga_jobstep    | BASE TABLE |
| pgagent      | pga_schedule   | BASE TABLE |
+--------------+----------------+------------+
(8 rows)


--- Aqui estan los mensajes de errores 
select * from pgagent.pga_joblog    ;
select * from pgagent.pga_jobsteplog; 

select * from pgagent.pga_exception ;
select * from pgagent.pga_jobclass  ;
select * from pgagent.pga_job       ;
select * from pgagent.pga_jobstep   ;
select * from pgagent.pga_schedule  ;
select * from pgagent.pga_jobagent  ;
 



-- /****** VALIDAMOS LA AYUDA DEL PGAGENT ******\ 
[postgres@TEST_SERVER ~]$ pgagent_16 --help
PostgreSQL Scheduling Agent
Version: 4.2.2
Usage:
pgagent_16 [options] <connect-string>
options:
-v (display version info and then exit)
-f run in the foreground (do not detach from the terminal)
-t <poll time interval in seconds (default 10)>
-r <retry period after connection abort in seconds (>=10, default 30)>
-s <log file (messages are logged to STDOUT if not specified>
-l <logging verbosity (ERROR=0, WARNING=1, DEBUG=2, default 0)>

```


## Info extra
```

----- quitar los permisos ----------
revoke connect on database postgres from pgagent;
revoke all privileges on all tables in schema  pg_catalog from pgagent;
revoke all privileges on all tables in schema  information_schema from pgagent;
revoke USAGE ON SCHEMA pgagent from pgagent;
revoke ALL PRIVILEGES ON ALL TABLES IN SCHEMA pgagent from pgagent;
revoke ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA pgagent from pgagent;
revoke TEMPORARY ON DATABASE postgres from pgagent;
revoke pg_execute_server_program from  pgagent;
```

  # Bibliografía:

  
```
https://www.tencentcloud.com/document/product/409/41792
https://github.com/pgadmin-org/pgagent/tree/master

https://stackoverflow.com/questions/76300566/how-configure-pgagent-in-ubuntu22-04


```
