
# pg_partman 
Es una herramienta poderosa y flexible para administrar particiones en PostgreSQL

# Conociendo la herramienta: 

#### 🔑 Parámetros importantes:

 
```sql
--- CREANDO LA HERRAMIENTA
CREATE SCHEMA partman;
CREATE EXTENSION pg_partman SCHEMA partman;




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
5. **partition_interval**: Intervalo de partición,     como '1 day', '1 month', '10' (para ID).
6. **partition_type**:   solo soporta range (para tiempo o ID).
7. **premake**: Número de particiones futuras que se deben crear de antemano.
8. **automatic_maintenance**: Estado del mantenimiento automático (activado o desactivado).
9. **template_table**: Tabla plantilla cuyas propiedades se heredarán en las particiones.
10. **retention**: establecer el período de tiempo durante el cual deseas retener las particiones.
11. **retention_schema**: Esquema en el que se deben almacenar las particiones retenidas.
12. **retention_keep_index**: Indica si se deben mantener los índices de las particiones retenidas.
13. **retention_keep_table**: controla si las tablas hijas (particiones) que ya no están dentro del rango de retención deben conservarse o eliminarse físicamente del sistema.
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

-> FUNCION MÁS USADA (create_parent):
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
4. **p_type (text DEFAULT 'range')**: Tipo de partición; por defecto es 'range' o list.
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

# Ejemplo
```SQL



 -- # Utilizar un proceso de pg_partman para los mantenimientos automaticos 
[postgres@pg ~]$ vim data/postgresql.conf
shared_preload_libraries = 'pg_partman_bgw' # Ejecuta automáticamente partman.run_maintenance() sobre todas las tablas registradas en partman.part_config que tengan automatic_maintenance = true.



--- CONFIGURACIONES 
postgres@test# select name,setting from pg_settings where name ilike '%pg_partman_bgw%';

pg_partman_bgw.dbname = 'mi_base' #   Lista de bases de datos donde se ejecutará el mantenimiento.
pg_partman_bgw.interval = 1800 # Intervalo en segundos entre ejecuciones (por defecto: 3600 = 1 hora).
pg_partman_bgw.role = 'postgres' # Rol con el que se ejecuta el mantenimiento (por defecto: postgres).
pg_partman_bgw.analyze = on # Si se debe ejecutar ANALYZE después del mantenimiento (ON/OFF).
pg_partman_bgw.jobmon = off # Si se debe registrar en pg_jobmon (ON/OFF).


---- yo prefiero pg_cron. usar pg_partman_bgw en caso de no querer usar pg_partman_bgw porque ya se tiene pg_cron
 CREATE EXTENSION pg_cron;

  SELECT cron.schedule_in_database(
    'create-partitions-workshops',
    '@monthly',
    $$CALL partman.run_maintenance_proc()$$,
    'workshops');


-- # Crear esquema 
CREATE SCHEMA IF NOT EXISTS parman; 


-- # Crear la extension.
CREATE EXTENSION pg_partman SCHEMA parman;

-- # Crear tabla de ejemplo 
CREATE TABLE user_activities (
    activity_id serial,
    activity_time TIMESTAMPTZ NOT NULL,
    activity_type TEXT NOT NULL,
    content_id INT NOT NULL,
    user_id INT NOT NULL,
    PRIMARY KEY (activity_id, activity_time)
)
PARTITION BY RANGE (activity_time);


-- # Crea una tabla template que se usara para crear las particiones
CREATE TABLE public.user_activities_template (LIKE public.user_activities INCLUDING ALL); -- INCLUDING DEFAULTS INCLUDING CONSTRAINTS


-- # Configuración Inicial.
SELECT partman.create_parent(	p_parent_table  => 'public.user_activities'
								,p_control  => 'activity_time'
								,p_interval => '1 month'
								,p_type => 'range' 
								,p_premake => 3
								,p_start_partition  => (CURRENT_DATE + '1 month'::interval)::text
								,p_default_table := false
								,p_template_table := 'public.user_activities_template'
								,p_automatic_maintenance  => 'on'
							);


-- # Validamos las particiones 	
\d+ user_activities


-- # Actualizar campos 
update partman.part_config	
	set retention = '24 months',
	infinite_time_partitions = true,
	retention_keep_table = false
where   parent_table = 'public.user_activities';

 

select * from partman.part_config;
 
  
-- # Crear particion manual
SELECT partman.create_partition_time( p_parent_table => 'public.user_activities',  p_partition_times =>  array['2025-01-28'::date + INTERVAL '9 months']  );

 
-- # Ver las nombres  de las aprticiones hijas
SELECT * from partman.show_partitions( 'public.user_activities');
select * from  partman.show_partition_info('public.user_activities_p20250301'); 


-- # Aplicar mantenimientos , es el encargado de crear las nuevas particiones y depurar las que sean necesarias:
-- Ideal para los CRON, solo para las tablas automatic_maintenance = true
  CALL partman.run_maintenance_proc();

select * from   partman.run_maintenance();
SELECT partman.run_maintenance('public.mi_tabla', p_analyze := true);

 
 
-- # Eliminar todo de pruebas 
drop table user_activities;
delete  from  partman.part_config;
```
--- 
# Info Extra

### ¿Para qué sirve `retention_keep_table`?

- **Cuando está en `true` (valor por defecto):**
  - Las particiones que ya no están dentro del rango de retención **se desvinculan del conjunto de particiones activas**, pero **no se borran físicamente** de la base de datos.
  - Esto permite conservar los datos antiguos por si se necesitan más adelante, pero ya no forman parte del conjunto activo que pg_partman mantiene.

- **Cuando está en `false`:**
  - Las particiones fuera del rango de retención **se eliminan completamente** del sistema (se ejecuta `DROP TABLE`).
  - Esto libera espacio en disco de forma inmediata y evita que los datos antiguos sigan ocupando recursos.
  
  
 
  
### 🔍 ¿Para qué sirve?
 
Si activas `infinite_time_partitions = true`, entonces:

- **pg_partman seguirá creando nuevas particiones de tiempo automáticamente**, aunque no haya datos nuevos que las necesiten.
- Esto es útil en sistemas donde **se espera que lleguen datos en el futuro** y quieres que las particiones ya estén listas para evitar retrasos o errores.

### 📊 Tabla 1: Valores válidos para `p_type`

| Valor de `p_type` | Tipo de partición | Descripción técnica | Requiere campo tipo... |
|-------------------|-------------------|----------------------|-------------------------|
| `'time'`          | Por tiempo        | Crea particiones basadas en fechas o timestamps | `timestamp`, `date` |
| `'id'`            | Por entero        | Crea particiones basadas en rangos de IDs | `integer`, `bigint` |

---

### 📊 Tabla 2: Valores válidos para `p_interval` según `p_type`

#### 🔹 Si `p_type = 'time'`

| Valor de `p_interval` | Intervalo temporal | Descripción | Ejemplo de partición |
|------------------------|--------------------|-------------|-----------------------|
| `'hourly'`             | Cada hora          | Crea una partición por cada hora | `eventos_p2025_10_10_00` |
| `'daily'`              | Cada día           | Crea una partición por día | `eventos_p2025_10_10` |
| `'weekly'`             | Cada semana        | Crea una partición por semana | `eventos_p2025_w41` |
| `'monthly'`            | Cada mes           | Crea una partición por mes | `eventos_p2025_10` |
| `'quarterly'`          | Cada trimestre     | Crea una partición por trimestre | `eventos_p2025_q4` |
| `'yearly'`             | Cada año           | Crea una partición por año | `eventos_p2025` |



#### 🔹 Si `p_type = 'id'`

| Valor de `p_interval` | Rango de IDs por partición | Descripción | Ejemplo de partición |
|------------------------|----------------------------|-------------|-----------------------|
| `'100'`                | Cada 100 IDs               | Crea una partición por cada 100 registros | `eventos_p0000000100` |
| `'1000'`               | Cada 1000 IDs              | Ideal para tablas con muchos inserts | `eventos_p0000010000` |
| `'10000'`              | Cada 10,000 IDs            | Útil para grandes volúmenes | `eventos_p0000100000` |
| `'100000'`             | Cada 100,000 IDs           | Para datos masivos | `eventos_p0001000000` |
 



## Referencias: 
```
Declarative Partitioning in PostgreSQL: Migrating and Automating with pg_partman and pg_cron -> https://medium.com/@golaneduard1/declarative-partitioning-in-postgresql-migrating-and-automating-with-pg-partman-and-pg-cron-b6d978abb507


Database Partitioning Made Easy: An In-Depth Look at Pg_partman for PostgreSQL -> https://medium.com/@sajawalhamza252/database-partitioning-made-easy-an-in-depth-look-at-pg-partman-for-postgresql-c899b8e0ae80
Benefits of pg_partman: Efficient Partition Management in PostgreSQL -> https://medium.com/@wasiualhasib/benefits-of-pg-partman-efficient-partition-management-in-postgresql-afebccbb663e
Mastering Time-Based Partitioning and Automated Database Maintenance in PostgreSQL Using pg_partman and pg_cron -> https://towardsdev.com/mastering-time-based-partitioning-and-automated-database-maintenance-in-postgresql-using-pg-partman-ce7630001b94

Utilizing pg_partman for automating deletion of aging records in PostgreSQL -> https://medium.com/@sidhardha.ayachithula/utilizing-pg-partman-for-automated-time-to-live-ttl-record-deletion-in-postgresql-b6bf6a5f1938
Divide And Partition: pg_partman online partitioning gotchas -> https://medium.com/fresha-data-engineering/divide-and-partition-pg-partman-online-partitioning-gotchas-042b1af626a5

PostgresSQL data partitioning -> https://arashitov.medium.com/postgressql-data-partitioning-e977b887a8cc
Advanced Table Partitioning in PostgreSQL: A Deep Dive (includes introduction of pg_partman) -> https://medium.com/@arunseetharaman/advanced-table-partitioning-in-postgresql-a-deep-dive-includes-introduction-of-pg-partman-3e0f1f39b5ca
- https://github.com/pgpartman/pg_partman
- https://www.percona.com/blog/postgresql-partitioning-made-easy-using-pg_partman-timebased/

- https://neon.tech/docs/extensions/pg_partman
- https://medium.com/@ramkisan.chourasiya/partitioning-in-postgresql-using-pg-partman-10070feafd81
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL_Partitions.html
- https://www.crunchydata.com/blog/native-partitioning-with-postgres

https://www.postgresql.org/docs/current/datatype-datetime.html

```
