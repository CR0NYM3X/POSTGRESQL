## Configurar los datos que guarda en el LOG

Por ejemplo, si solo deseas registrar consultas de modificación de datos, puedes configurar log_statement de la siguiente manera en tu archivo postgresql.conf:
```sql
log_statement = 'mod'
/*********** Otras opciones *************
none: No se registra ninguna consulta.
ddl: Solo se registran las consultas de definición de datos (DDL), como CREATE, ALTER, DROP, etc.
mod: Solo se registran las consultas de modificación de datos (DML), como INSERT, UPDATE, DELETE, etc.
all: Se registran todas las consultas, tanto DDL como DML.*/

log_destination
 
```
 

## Mantenimientos 
## Memorias 

```sql
work_mem = 4MB  /*es un parámetro de configuración de PostgreSQL que especifica la cantidad de memoria que utilizarán las operaciones de ordenación internas  ORDER BY, DISTINCT, subconsultas IN y JOINS y las tablas hash antes de escribir en archivos de disco temporales, En un servidor dedicado podemos usar un 2-4% del total de nuestra memoria si tenemos solamente unas pocas sesiones (clientes) grandes. Como valor inicial podemos usar 8 Mbytes e ir aumentando progresivamente hasta tener un buen equilibrio entre uso de memoria y generación de temp files link : https://dbasinapuros.com/como-saber-si-esta-bien-ajustado-el-parametro-work_mem-de-postgresql/ */

maintenance_work_mem = 16MB  /*Usada en operaciones del tipo VACUUM, ANALYZE, CREATE INDEX, ALTER TABLE, ADD FOREIGN KEY. Su valor dependerá mucho del tamaño de nuestras bases de datos. Por ejemplo, en un servidor con Gbytes de memoria, podemos usar 256MB como valor inicial. La fórmula es 1/16 de nuestra memoria RAM. link: https://docs.aws.amazon.com/es_es/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum.html*/
/*  para los hosts grandes, defina el parámetro maintenance_work_mem en un valor comprendido entre uno y dos gigabytes, Para los hosts extremadamente grandes, defina el parámetro en un valor comprendido entre dos y cuatro gigabytes  , este parámetro depende de la carga de trabajo. */

effective_cache_size = 4GB  /*Parámetro usado por el 'query planner' de nuestro motor de bases de datos para optimizar la lectura de datos. En un servidor dedicado podemos empezar con un 50% del total  e nuestra memoria. Como máximo  unos 2/3 (66%) del total. Por ejemplo, en un servidor con 4Gbytes de memoria, podemos usar 2048MB como valor inicial. effective_cache_size = 2048MB*/

checkpoint_segments = 3		/*# in logfile segments, min 1, 16MB each Este parámetro es muy importante en bases de datos con numerosas operaciones de escritura (insert,update,delete). Para empezar podemos empezar con un valor de 64. En grandes bases de datos con muchos  bytes de datos escritos podemos aumentar este valor hasta 128-256. checkpoint_segments = 64*/

shared_buffers = 128MB  /*  Default min  128kB reasonable starting value for shared_buffers is 25% of the memory in your system. Link: https://www.postgresql.org/docs/9.1/runtime-config-resource.html*/

Configuración del kernel en linux: kernel.shmmax = 1/3 de la RAM disponible en bytes

```

## Tiempos 
```sql
 SELECT * from pg_timezone_names; 
 SHOW TIMEZONE;
 ALTER DATABASE postgres SET timezone TO 'Europe/Berlin';
 SELECT CURRENT_TIMESTAMP;
	timezone = 'US/Eastern'	 # postgresql.conf 
 
 
 These settings are initialized by initdb, but they can be changed.
	lc_messages = 'en_US.UTF-8' # locale for system error message
	lc_monetary = 'en_US.UTF-8' # locale for monetary formatting
	lc_numeric = 'en_US.UTF-8' # locale for number formatting
	lc_time = 'en_US.UTF-8' # locale for time formatting
```

## Configuración en base de datos 
```sql
  ------------ En base de datos ---------
  
  create extension pg_stat_statements;
  ```

## Configuración en base de datos 
```sql
-------------- settings IMPORTANT -------------------------
 listen_addresses = '*'  ## enable all other computers to connect 
 max_connections = 100
 port = 5432
 password_encryption = scram-sha-256		# md5 or scram-sha-256
 shared_preload_libraries = 'pg_stat_statements'
 
 
 ```

## Otra configuración
 ```sql
------------ other config -----------------
  datestyle = 'iso, mdy'
  
  #work_mem = 4MB ## Total RAM * 0.25 / max_connections

Variables:
PGDATA
  ```



  ```sql 

port = 5432
listen_addresses = '*'
max_connections = 100
shared_buffers = 128MB
dynamic_shared_memory_type = posix
max_wal_size = 1GB
min_wal_size = 80MB
log_timezone = 'Etc/UTC'
datestyle = 'iso, mdy'
timezone = 'Etc/UTC'

#locale settings
lc_messages = 'en_US.utf8'			# locale for system error message
lc_monetary = 'en_US.utf8'			# locale for monetary formatting
lc_numeric = 'en_US.utf8'			# locale for number formatting
lc_time = 'en_US.utf8'				# locale for time formatting

default_text_search_config = 'pg_catalog.english'


data_directory = '/data'
hba_file = '/config/pg_hba.conf'
ident_file = '/config/pg_ident.conf'
  ```






 

## Bibliofragías 
```
 ---------> PDF  CONFIGURACION PSQL  <--------------
 

 https://www.postgresql.org/docs/current/runtime-config.html
 https://wiki.postgresql.org/images/5/59/FlexiblePostgreSQLConfiguration.pdf

-- Este tiene varios temas como  PITR, respaldos, configuraciones etc, etc
 https://www.visibilidadweb.unam.mx/capacitacion/perfilesTIC/responsableTIC/Manual-Curso-Basico-Postgres 
 
 https://ubuntu.com/server/docs/install-and-configure-postgresql

-- Todos los parametros 
https://pgdash.io/blog/postgres-configuration-cheatsheet.html

--> PostgreSQL Configuration Best Practices for Performance and Security
https://www.cherrycreekeducation.com/bbk/b/Apress_PostgreSQL_Configuration.pdf


https://helpcenter.netwrix.com/bundle/StealthDEFEND_2.7/page/Content/StealthDEFEND/Installation_Guide/Configure_the_Postgres.conf_File/Configure_the_Postgres.conf_File.htm

https://fast.fujitsu.com/hubfs/_Global/Manuals/V12onZ-OperationGuide.pdf
https://www.postgresql.fastware.com/hubfs/_Global/Manuals/V12onZ-InstallationAndSetupGuideForServer.pdf?hsLang=en-us
https://www.postgresql.fastware.com/hubfs/_Global/Manuals/V12onZSP1-SecurityOperationGuide.pdf

https://supabase.com/docs/guides/platform/custom-postgres-config

  --------->  PDF SECURITY - PSQL   <--------------
 https://www.crunchydata.com/files/stig/PGSQL-STIG-v1r1.pdf
 https://rcci.uci.cu/?journal=rcci&page=article&op=viewFile&path[]=96&path[]=90
 https://www.postgresql.eu/events/pgconfeu2023/sessions/session/4707/slides/444/P-DBI-E-20231214-PostgreSQL_security_with_demo.pdf
 
 https://repository.unad.edu.co/bitstream/handle/10596/36746/ilovepdf_merged.pdf?sequence=3&isAllowed=y
 
 
 --------->  postgresql.conf DE PRUBEAS <--------------
 https://github.com/postgres/postgres/blob/master/src/backend/utils/misc/postgresql.conf.sample
 https://gist.github.com/sbrohme/3295547
 https://gist.github.com/64kramsystem/d780ce0f8dff7b90847b2728f506cdea
```
