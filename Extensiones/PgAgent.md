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

-- /****** MODIFICAMOS DE AUTENTICACIÓN A PEER  EN ARCHIVO PG_HBA.CONF ******\
[postgres@TEST_SERVER ]$ vim /sysx/data16/pg_hba.conf

# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     peer # "local" is for Unix domain socket connections only
host    all             all             127.0.0.1/32            peer # IPv4 local connections:


-- /****** INICIAR EL SERVICIO DE PGAGENT ******\ 
[postgres@TEST_SERVER ]$ pgagent_16 hostaddr=127.0.0.1 port=5416 dbname=postgres user=postgres  -s /sysx/data16/pg_log/pgagent_16.log


pgagent_16 service=pgagent -s /sysx/data16/pg_log/pgagent_16.log

-- /****** VALIDAMOS SE HAYA INICIADO EL SERVICIO  ******\
-- [NOTA] : En caso de requerir contraseña puedes usar el parametro password=
[postgres@TEST_SERVER ]$ ps -fea | grep pga
postgres 1560617       1  0 11:47 pts/4    00:00:00 pgagent_16 hostaddr=127.0.0.1 port=5416 dbname=postgres user=postgres -s /sysx/data16/pg_log/pgagent_16.log


-- /****** VALIDAMOS QUE NO HAYA MARCADO ERROR  ******\ 
[postgres@TEST_SERVER ]$ cat /sysx/data16/pg_log/pgagent_16.log  | wc -l
0


-- /****** NOS CONECTAMOS A LA DB POSTGRES  ******\ 
[postgres@TEST_SERVER ]$ psql -h 127.0.0.1 -p 5416 -d postgres -U postgres

-- /****** CREAMOS LA EXTENSION  ******\ 
postgres@postgres# CREATE EXTENSION pgagent;
CREATE EXTENSION
Time: 46.130 ms


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


  # Bibliografía:

  
```
https://www.tencentcloud.com/document/product/409/41792
https://github.com/pgadmin-org/pgagent/tree/master

https://stackoverflow.com/questions/76300566/how-configure-pgagent-in-ubuntu22-04


```
