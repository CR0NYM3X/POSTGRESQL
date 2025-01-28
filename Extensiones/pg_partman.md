
# pg_partman 
Es una herramienta poderosa y flexible para administrar particiones en PostgreSQL

# Conociendo la herramienta: 

 
```sql
--- CREANDO LA HERRAMIENTA
CREATE SCHEMA partman;
CREATE EXTENSION pg_partman SCHEMA partman;


--- CONFIGURACIONES 
postgres@test# select name,setting from pg_settings where name ilike '%pg_partman_bgw%';
+---------------------------------+----------+
|              name               | setting  |
+---------------------------------+----------+
| pg_partman_bgw.analyze          | off      |
| pg_partman_bgw.dbname           |          |
| pg_partman_bgw.interval         | 3600     |
| pg_partman_bgw.jobmon           | on       |
| pg_partman_bgw.maintenance_wait | 0        |
| pg_partman_bgw.role             | postgres |
+---------------------------------+----------+
(6 rows)

Time: 1.604 ms



--- TABLAS
postgres@test# select table_name from information_schema.tables  where table_schema = 'partman';
+-----------------+
|   table_name    |
+-----------------+
| table_privs     |
| part_config     |
| part_config_sub |
+-----------------+

 
-> TABLA MÁS USADA (part_config):
Define cómo se deben crear y gestionar las particiones, incluyendo el intervalo de particionamiento (diario, semanal, mensual)
Almacena parámetros que permiten la creación automática de particiones futuras y el purgado de particiones antiguas basadas en los valores configurados
Facilita el mantenimiento de las particiones al permitir la configuración de opciones como la ejecución automática de comandos VACUUM y ANALYZE en las particiones

--- COLUMNAS 
1. **parent_table**: Nombre de la tabla principal que está siendo particionada.
2. **control**: Columna de control utilizada para la partición, generalmente una fecha o un ID.
3. **time_encoder**: Codificador de tiempo que se va a utilizar.
4. **time_decoder**: Decodificador de tiempo que se va a utilizar.
5. **partition_interval**: Intervalo de partición, por ejemplo, `daily`, `weekly`, `monthly`, etc.
6. **partition_type**: Tipo de partición (`range`, `list`, `hash`, etc.).
7. **premake**: Número de particiones futuras que se deben crear de antemano.
8. **automatic_maintenance**: Estado del mantenimiento automático (activado o desactivado).
9. **template_table**: Tabla plantilla cuyas propiedades se heredarán en las particiones.
10. **retention**: Configuración de retención de particiones antiguas, especificando cuándo se deben eliminar.
11. **retention_schema**: Esquema en el que se deben almacenar las particiones retenidas.
12. **retention_keep_index**: Indica si se deben mantener los índices de las particiones retenidas.
13. **retention_keep_table**: Indica si se deben mantener las tablas de particiones que se eliminan según la configuración de retención.
14. **epoch**: Época utilizada para calcular el inicio de las particiones.
15. **constraint_cols**: Columnas en las que se aplican restricciones de integridad.
16. **optimize_constraint**: Indica si se deben optimizar las restricciones en las particiones.
17. **infinite_time_partitions**: Indica si las particiones de tiempo deben ser infinitas.
18. **datetime_string**: Cadena de formato de fecha y hora.
19. **jobmon**: Indica si se debe habilitar la monitorización de trabajos.
20. **sub_partition_set_full**: Indica si el conjunto de sub-particiones está completo.
21. **undo_in_progress**: Indica si una operación de deshacer (undo) está en progreso.
22. **inherit_privileges**: Indica si se deben heredar los privilegios en las particiones.
23. **constraint_valid**: Indica si las restricciones son válidas.
24. **ignore_default_data**: Indica si se deben ignorar los datos predeterminados.
25. **date_trunc_interval**: Intervalo utilizado para truncar las fechas, como `month`, `day`.
26. **maintenance_order**: Orden en el que se deben realizar las operaciones de mantenimiento.
27. **retention_keep_publication**: Indica si se deben mantener las publicaciones de las particiones retenidas.
28. **maintenance_last_run**: Fecha y hora de la última ejecución de mantenimiento.
 



--- FUNCIONES 
postgres@test# select distinct proname from pg_proc where pronamespace in(select oid from pg_namespace where nspname ='partman') order by 1 ;
+-----------------------------------+
|              proname              |
+-----------------------------------+
| apply_cluster                     |
| apply_constraints                 |
| apply_privileges                  |
| autovacuum_off                    |
| autovacuum_reset                  |
| calculate_time_partition_info     |
| check_automatic_maintenance_value |
| check_control_type                |
| check_default                     |
| check_epoch_type                  |
| check_name_length                 |
| check_partition_type              |
| check_subpart_sameconfig          |
| check_subpartition_limits         |
| create_parent                     |
| create_partition_id               |
| create_partition_time             |
| create_sub_parent                 |
| drop_constraints                  |
| drop_partition_id                 |
| drop_partition_time               |
| dump_partitioned_table_definition |
| inherit_replica_identity          |
| inherit_template_properties       |
| partition_data_id                 |
| partition_data_proc               |
| partition_data_time               |
| partition_gap_fill                |
| reapply_constraints_proc          |
| reapply_privileges                |
| run_analyze                       |
| run_maintenance                   |
| run_maintenance_proc              |
| show_partition_info               |
| show_partition_name               |
| show_partitions                   |
| stop_sub_partition                |
| undo_partition                    |
| undo_partition_proc               |
| uuid7_time_decoder                |
| uuid7_time_encoder                |
+-----------------------------------+
(41 rows)

Time: 1.533 ms
postgres@test#

-> FUNCION MÁS USADA (part_config):
CREATE FUNCTION  create_parent(
    p_parent_table text
    , p_control text
    , p_interval text
    , p_type text DEFAULT 'range'
    , p_epoch text DEFAULT 'none'
    , p_premake int DEFAULT 4
    , p_start_partition text DEFAULT NULL
    , p_default_table boolean DEFAULT true
    , p_automatic_maintenance text DEFAULT 'on'
    , p_constraint_cols text[] DEFAULT NULL
    , p_template_table text DEFAULT NULL
    , p_jobmon boolean DEFAULT true
    , p_date_trunc_interval text DEFAULT NULL
    , p_control_not_null boolean DEFAULT true
    , p_time_encoder text DEFAULT NULL
    , p_time_decoder text DEFAULT NULL
)

--- PARÁMETROS
1. **p_parent_table (text)**: Nombre de la tabla principal (parent table) que se va a crear.
2. **p_control (text)**: Columna de control que se utilizará para la partición.
3. **p_interval (text)**: Intervalo de partición, por ejemplo, puede ser 'daily', 'weekly', 'monthly', etc.
4. **p_type (text DEFAULT 'range')**: Tipo de partición; por defecto es 'range'.
5. **p_epoch (text DEFAULT 'none')**: Define el tiempo de epoch, que puede ser 'none' o una especificación de tiempo.
6. **p_premake (int DEFAULT 4)**: Número de particiones futuras que se crearán de antemano.
7. **p_start_partition (text DEFAULT NULL)**: Fecha o valor de inicio para la primera partición.
8. **p_default_table (boolean DEFAULT true)**: Indica si se debe crear una tabla por defecto para manejar valores fuera del rango.
9. **p_automatic_maintenance (text DEFAULT 'on')**: Activa o desactiva el mantenimiento automático.
10. **p_constraint_cols (text[] DEFAULT NULL)**: Columnas que tendrán restricciones de integridad.
11. **p_template_table (text DEFAULT NULL)**: Nombre de una tabla plantilla (template table) cuyas propiedades se heredarán en las particiones.
12. **p_jobmon (boolean DEFAULT true)**: Indica si se debe habilitar la monitorización de trabajos.
13. **p_date_trunc_interval (text DEFAULT NULL)**: Intervalo que se utilizará para truncar las fechas, por ejemplo, 'month', 'day'.
14. **p_control_not_null (boolean DEFAULT true)**: Indica si la columna de control debe permitir valores NULL.
15. **p_time_encoder (text DEFAULT NULL)**: Codificador de tiempo que se utilizará.
16. **p_time_decoder (text DEFAULT NULL)**: Decodificador de tiempo que se utilizará.




```



Referencias: 
- https://github.com/pgpartman/pg_partman
- https://medium.com/@sajawalhamza252/database-partitioning-made-easy-an-in-depth-look-at-pg-partman-for-postgresql-c899b8e0ae80
- https://www.percona.com/blog/postgresql-partitioning-made-easy-using-pg_partman-timebased/
- https://neon.tech/docs/extensions/pg_partman
- https://medium.com/@ramkisan.chourasiya/partitioning-in-postgresql-using-pg-partman-10070feafd81
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL_Partitions.html
- https://www.crunchydata.com/blog/native-partitioning-with-postgres
