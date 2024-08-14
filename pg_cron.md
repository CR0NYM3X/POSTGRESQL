

### Ejemplos de uso 

```sql

/************  add to postgresql.conf *************\
shared_preload_libraries = 'pg_cron,pg_stat_statements'
cron.database_name = 'postgres'
cron.host = '/tmp' # Connect via a unix domain socket:
cron.timezone = 'GMT' -# Este es un estandar asi que debes de saber que hora es en el estandar 

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


CREATE EXTENSION pg_cron;
-- drop EXTENSION pg_cron;
GRANT USAGE ON SCHEMA cron TO postgres;


--- Eliminar una job
SELECT cron.unschedule(1); --- colocar id 
SELECT cron.unschedule('create_copy' ); --- colocar nombre del job 

-- View active jobs
select * from cron.job;
select * from cron.job_run_details order by start_time desc ;

---- agregar una tarea/job
SELECT cron.schedule('create_copy', '32 14 * * *', ' COPY  ( select name,setting from pg_settings)  TO ''/tmp/pg_settings-25072024.csv'' ; ');

---- especificar los parametros del job a los que se va conectar
select cron.schedule_in_database('create_copy', '32 14 * * *', ' COPY  ( select name,setting from pg_settings)  TO ''/tmp/pg_settings-25072024.csv'' ; ' , 'db_tienda', 'user_test', true );

---- modificar un job 
select cron.alter_job(job_id bigint, schedule text DEFAULT NULL::text, command text DEFAULT NULL::text, database text DEFAULT NULL::text, username text DEFAULT NULL::text, active boolean DEFAULT NULL::boolean )

--- ver configuraciones de cron
SELECT name, setting, short_desc FROM pg_settings WHERE name LIKE 'cron%' ORDER BY name;

select * from pg_available_extensions where name ilike '%cron%';

 select * from pg_extension;

https://www.sobyte.net/post/2022-02/postgresql-time-task/
https://github.com/citusdata/pg_cron
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL_pg_cron.html
https://supabase.com/docs/guides/database/extensions/pg_cron
https://www.alibabacloud.com/help/en/rds/apsaradb-rds-for-postgresql/use-the-pg-cron-extension-to-configure-scheduled-tasks
https://www.citusdata.com/blog/2023/10/26/making-postgres-tick-new-features-in-pg-cron/

```
