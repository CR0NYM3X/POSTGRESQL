# PG_CRON
 Es una extensión para PostgreSQL que permite programar y ejecutar tareas periódicas directamente desde la base de datos, similar a cómo funciona cron en sistemas Unix12.

> **Desventaja:** Solo permite la ejecución de código sql dentro de la base de datos, por lo que no puedes ejecutar script a nivel servidor, como  bash 

### Ejemplos de uso 

> [!IMPORTANT]
> Es importante poner atencion a la hora estandar que configuras en el cron, ya que la query se va ejecutar a la hora estandar y no ha la hora del servidor



```sql

--- Ver los parametros que se pueden configurar con PG_CRON
select * from pg_available_extensions where name ilike '%cron%';

-- /************  add to postgresql.conf *************\
shared_preload_libraries = 'pg_cron,pg_stat_statements'
cron.database_name = 'postgres'
cron.host = '/tmp' # Connect via a unix domain socket:
cron.timezone = 'MST' -# Este es un estandar asi que debes de saber que hora es en el estandar 


----- Crear la Extension
CREATE EXTENSION pg_cron;
-- drop EXTENSION pg_cron;
GRANT USAGE ON SCHEMA cron TO postgres;

---- Ver si se creao la extension 
select * from pg_extension;

--- Ver los parametros que se pueden configurar con PG_CRON
SELECT name, setting, short_desc FROM pg_settings WHERE name LIKE 'cron%' ORDER BY name;


--- Ver la hora en linux  
date -u
/usr/bin/timedatectl

---- Ver la hora en posgresql
SELECT current_timestamp AT TIME ZONE 'GMT';
SELECT current_timestamp AT TIME ZONE 'UTC';
SELECT current_timestamp AT TIME ZONE 'MST'; --- este es mi estandar  

--------- Convertir hora MST a GMT
  SELECT 
 ( now()::date || ' ' || 
 '18:00:00'  /* <---- AQUI COLOCAR LA HORA QUE QUIERES EJECUTAR EL CRON */
 )::timestamp AT TIME ZONE 'MST' AT TIME ZONE 'GMT' as "hora convertida a GMT" 
,current_timestamp AT TIME ZONE 'MST' as "hora actual MST"
,current_timestamp AT TIME ZONE 'GMT' as "hora Estandar GMT"
, (current_timestamp AT TIME ZONE 'GMT'  ) - (current_timestamp AT TIME ZONE 'MST'  )  as "Diferencia de horas "
 ;



--- la hora UTC y GMT es la misma 
UTC (Tiempo Universal Coordinado): El estándar de tiempo actual.
GMT (Greenwich Mean Time): Hora del Meridiano de Greenwich.
EST (Eastern Standard Time): Hora Estándar del Este (UTC-5).
CST (Central Standard Time): Hora Estándar Central (UTC-6).
MST (Mountain Standard Time): Hora Estándar de la Montaña (UTC-7).
PST (Pacific Standard Time): Hora Estándar del Pacífico (UTC-8).
CET (Central European Time): Hora Central Europea (UTC+1).
EET (Eastern European Time): Hora de Europa Oriental (UTC+2).
IST (India Standard Time): Hora Estándar de la India (UTC+5:30).
JST (Japan Standard Time): Hora Estándar de Japón (UTC+9).
AEST (Australian Eastern Standard Time): Hora Estándar del Este de Australia (UTC+10).



-- View active jobs
select * from cron.job;
select start_time,end_time, (start_time - end_time ) as duracion ,* from cron.job_run_details order by start_time desc ;--- puedes tener estatus  running | FAILED | successful

---- agregar una tarea/job, si hacer un nuevo job y dejas el mismo nombre , suplantaras el anterior 
SELECT cron.schedule('create_copy', '32 14 * * *', ' COPY  ( select name,setting from pg_settings)  TO ''/tmp/pg_settings-25072024.csv'' ; ');

---- especificar los parametros del job a los que se va conectar
select cron.schedule_in_database('create_copy', '32 14 * * *', ' COPY  ( select name,setting from pg_settings)  TO ''/tmp/pg_settings-25072024.csv'' ; ' , 'db_tienda', 'user_test', true );

---- modificar un job 
select cron.alter_job(job_id bigint, schedule text DEFAULT NULL::text, command text DEFAULT NULL::text, database text DEFAULT NULL::text, username text DEFAULT NULL::text, active boolean DEFAULT NULL::boolean )

--- Eliminar jobs
SELECT cron.unschedule(1); --- colocar id 
SELECT cron.unschedule('create_copy' ); --- colocar nombre del job 

-- Eliminar todo 
truncate cron.job_run_details RESTART IDENTITY;
truncate  cron.job RESTART IDENTITY;

--- Reiniciar las secuencias, esto en caso de haber realizado un trunquear
  ALTER SEQUENCE cron.runid_seq RESTART WITH 1;
  ALTER SEQUENCE cron.jobid_seq RESTART WITH 1;

--- Reiniciar las secuencias, esto en caso de haber realizado un delete 
SELECT setval('cron.jobid_seq', COALESCE((SELECT max(jobid) FROM cron.job),1));
SELECT setval('cron.runid_seq', COALESCE((SELECT max(runid) FROM cron.job_run_details),1));



----- BIBLIOGRAFÍAS -----
https://www.sobyte.net/post/2022-02/postgresql-time-task/
https://github.com/citusdata/pg_cron
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL_pg_cron.html
https://supabase.com/docs/guides/database/extensions/pg_cron
https://www.alibabacloud.com/help/en/rds/apsaradb-rds-for-postgresql/use-the-pg-cron-extension-to-configure-scheduled-tasks
https://www.citusdata.com/blog/2023/10/26/making-postgres-tick-new-features-in-pg-cron/

```
