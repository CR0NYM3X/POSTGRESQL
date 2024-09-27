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
grant pg_monitor to systest;
grant pg_stat_scan_tables to systest;
grant pg_read_all_stats to systest;
grant pg_read_all_settings to systest;
grant pg_read_server_files to systest;
grant pg_execute_server_program to systest;
GRANT CONNECT ON DATABASE tu_base_de_datos TO systest
GRANT USAGE ON SCHEMA public TO systest;


--------------- MSQL  --------------
USE [master]
GO

GRANT VIEW ANY ERROR LOG  TO [systest]
GRANT VIEW SERVER SECURITY AUDIT  TO [systest]
GRANT VIEW ANY DATABASE  TO [systest]
GRANT VIEW ANY SECURITY DEFINITION  TO [systest]
GRANT VIEW ANY PERFORMANCE DEFINITION  TO [systest]
GRANT VIEW ANY DEFINITION  TO [systest]
GRANT VIEW SERVER SECURITY STATE  TO [systest]
GRANT VIEW SERVER PERFORMANCE STATE  TO [systest]
GRANT VIEW SERVER STATE  TO [systest]

GRANT execute on [dbo].[sp_help_revlogin]   to [systest]

CREATE LOGIN [systest] WITH PASSWORD=N'123123', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

use msdb
go 
grant select  ON DATABASE::msdb TO [systest]
GRANT SHOWPLAN TO [sysappdynamics];

execute SYS.sp_MSforeachdb 'use [?];  CREATE USER [systest] FOR LOGIN [systest]'
```


## futuras Actualizaciones : 
  - Particiones en las tablas
  - Hacer la funcion  fun_exec_failed_query
  - Hacer una funcion que genere reportes de objetos
  - Hacer una funcion que valide cambios en la cantidad de objetos
  - Hacer una funcion que valide los servidores que no se han escaneado por completo ya se son nuevos
  - Hacer un trigger para la tabla ctl_querys , cuando ingresen un servidor realice un test
  - Crear diagrama de flujo
  - Crear diagrama de entidad relación
  - Crear manuales
  - Backup automaticos
  - Validación para cuando ejecuta gather_server_data de manera manual sin antes ejecutar la funcion fun_test_connection 
  - Agregar más query de monitoreo
    ```sql
    --- Agregar la recetas 
    --- Estadísticas de Tablas y base de datos y index 
    --- consultas con tiempos altos o pegadas y locks 
    --- info de mantenimientos 
    SELECT spcname, pg_tablespace_location(oid) AS location FROM pg_tablespace;
    ```
    
  




