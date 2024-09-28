# Servidor donde se instalará la herramienta 

### Version de Postgresql: 
```sql
select version();
+---------------------------------------------------------------------------------------------------------+
|                                                 version                                                 |
+---------------------------------------------------------------------------------------------------------+
| PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit |
+---------------------------------------------------------------------------------------------------------+
(1 row)
```

### Extensiones que se usan: 
```sql
select extname,extversion from pg_extension ;
+--------------------+------------+
|      extname       | extversion |
+--------------------+------------+
| plpgsql            | 1.0        |
| tds_fdw            | 2.0.3      |
| dblink             | 1.2        |
| pgcrypto           | 1.3        |
| pg_stat_statements | 1.10       |
| pg_trgm            | 1.6        |
| pg_auth_mon        | 1.1        |
| pgstattuple        | 1.5        |
| pg_cron            | 1.6        |
+--------------------+------------+
```

# PRIVILEGIOS NECESARIOS
```

--------------- PSQL  --------------
---> Crea un archivo /tmp/script.sql    y guarda el sql  
 
DO $$
BEGIN
    -- Verificar si el usuario existe
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'systest') THEN
        -- Crear el usuario
        create user systest with password '123123' ;
    END IF;
	
	IF    current_database()  = 'postgres' THEN
        -- Crear el usuario
        grant pg_monitor to systest;
        grant pg_stat_scan_tables to systest;
        grant pg_read_all_stats to systest;
        grant pg_read_all_settings to systest;
        grant pg_read_server_files to systest;
        grant pg_execute_server_program to systest;
        grant pg_execute_server_program to systest;  --  must be superuser or a member of the pg_execute_server_program role to COPY to or from an external program

    END IF;

    execute '    GRANT CONNECT ON DATABASE "' ||  current_database()  || '" TO systest';
    GRANT USAGE ON SCHEMA public TO systest;
    grant execute on all functions  in schema pg_catalog   to   systest; ---- permission denied for function pg_stat_file 
    grant select on all tables in schema pg_catalog   to   systest; --- permission denied for view pg_hba_file_rules
 
END $$;



 
# Guarda todas las base de datos en la variable result
result=$(psql -p 5415  -tAX -c "select datname  from pg_database where not datname in('template1','template0');" )

# Recorre la lista de base de datos 
for base in $result
do
    # Instala la funcion
    echo   $(psql -p 5415 -tAX -f /tmp/script.sql -d $base) " - Base de datos: " $base 
done





--------------- MSQL  --------------
USE [master]
GO
GRANT SHOWPLAN TO [systest];
GRANT VIEW ANY ERROR LOG  TO [systest]
GRANT VIEW SERVER SECURITY AUDIT  TO [systest]
GRANT VIEW ANY DATABASE  TO [systest]
GRANT VIEW ANY SECURITY DEFINITION  TO [systest]
GRANT VIEW ANY PERFORMANCE DEFINITION  TO [systest]
GRANT VIEW ANY DEFINITION  TO [systest]
GRANT VIEW SERVER SECURITY STATE  TO [systest]
GRANT VIEW SERVER PERFORMANCE STATE  TO [systest]
GRANT VIEW SERVER STATE  TO [systest]
grant select  ON DATABASE::master TO [sysappdynamics]  --- este por permisos de  object 'sysaltfiles' para ver los discos 
GRANT execute on [dbo].[sp_help_revlogin]   to [systest] --- este es para el permiso del proc sp_help_revlogin para ver los login

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'new_login')
BEGIN
    CREATE LOGIN [systest] WITH PASSWORD=N'123123', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
END
 
use msdb
go 
grant select  ON DATABASE::msdb TO [systest] --- este me pide permiso en la msdb
GRANT SHOWPLAN TO [sysappdynamics]; --- este para ver que no marque error al ver los jobs y backups 

execute SYS.sp_MSforeachdb 'use [?];  CREATE USER [systest] FOR LOGIN [systest]'
```


## futuras Actualizaciones : 
  - Particiones en las tablas
  - Hacer la funcion  fun_exec_failed_query
  - Hacer una funcion que genere reportes de objetos
  - Hacer una funcion que valide cambios en la cantidad de objetos
  - Hacer una funcion que valide los servidores que no se han escaneado por completo ya se son nuevos
  - Crear diagrama de flujo
  - Crear diagrama de entidad relación
  - Crear manuales
  - Backup automaticos
  - Validación para cuando ejecuta gather_server_data de manera manual sin antes ejecutar la funcion fun_test_connection 
  - Agregar más query stats de monitoreo


----- 27/09/2024 ------
  - agregar en la funcion fdw_conf.gather_server_data que elimine los datos del id_exec  actual para que no se repitan los datos 
  - ver la opcion de mejorar la forma de crear las tablas con la extension fdw_tds ver si es mejor crearlas cadas vez que se conecta y ver el tema de la contraseña 
  - modificar la fun exec_query_server para que la db lo inserte de manera automatica sin necesidad de consultar en la query, ver si es opcional 
  - En la funcion fdw_conf.exec_query_server ver la posibilidad de modificar la la columna db en las consultas ejecutadas en los servidores remotos y lo inserte de manera automatica
  - modificar la funcion exec_query_server para que permita consular tablas super pesadas con millones de registros activando el conteo de filas y ir consultando en partes las filas  
  - Hacer un trigger , cuando inserten  en la tabla ctl_querys , este realizara  la tabla particionada   fdw_conf.ctl_querys  
  - Agregarle la columna table_name en la tabla fdw_conf.ctl_querys 
  
 



    ```sql
    --- Agregar la recetas 
    --- Estadísticas de Tablas y base de datos y index 
    --- consultas con tiempos altos o pegadas y locks 
    --- info de mantenimientos 
    SELECT spcname, pg_tablespace_location(oid) AS location FROM pg_tablespace;
    ```
    
  


### Configuraciones de la herramienta
```SQL
postgres@auditoria# select name,setting,unit from  fdw_conf.project_settings;
+-------------------+-----------------+------+
|       name        |     setting     | unit |
+-------------------+-----------------+------+
| version           | 1.0             | NULL |
| statement_timeout | 1200000         | ms   |
| lock_timeout      | 1200000         | ms   |
| row_limit         | 50000           | NULL |
| dbms_supported    | PSQL            | NULL |
| dbms_supported    | MSSQL           | NULL |
| proyect_name      | SQLMeta Tracker | NULL |
+-------------------+-----------------+------+
(7 rows)
```
