

# Ejemplos de uso 
```

/************  add to postgresql.conf *************\
shared_preload_libraries = 'pg_cron'
cron.database_name = 'postgres'
cron.host = '/tmp' # Connect via a unix domain socket:

CREATE EXTENSION pg_cron;
GRANT USAGE ON SCHEMA cron TO postgres;


-- View active jobs
select * from cron.job;
elect * from cron.job_run_details order by start_time desc limit 5;


https://www.sobyte.net/post/2022-02/postgresql-time-task/
https://github.com/citusdata/pg_cron
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL_pg_cron.html
https://supabase.com/docs/guides/database/extensions/pg_cron
https://www.alibabacloud.com/help/en/rds/apsaradb-rds-for-postgresql/use-the-pg-cron-extension-to-configure-scheduled-tasks
https://www.citusdata.com/blog/2023/10/26/making-postgres-tick-new-features-in-pg-cron/

```
