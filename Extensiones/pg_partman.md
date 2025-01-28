
# pg_partman 
Es una herramienta poderosa y flexible para administrar particiones en PostgreSQL

# Conociendo la herramienta: 

 
```sql

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

```



Referencias: 
- https://github.com/pgpartman/pg_partman
- https://medium.com/@sajawalhamza252/database-partitioning-made-easy-an-in-depth-look-at-pg-partman-for-postgresql-c899b8e0ae80
- https://www.percona.com/blog/postgresql-partitioning-made-easy-using-pg_partman-timebased/
- https://neon.tech/docs/extensions/pg_partman
- https://medium.com/@ramkisan.chourasiya/partitioning-in-postgresql-using-pg-partman-10070feafd81
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL_Partitions.html
- https://www.crunchydata.com/blog/native-partitioning-with-postgres
