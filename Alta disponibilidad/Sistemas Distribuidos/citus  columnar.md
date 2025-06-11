**Almacenamiento columnar con citus**  
   - Citus permite **almacenar datos en formato columnar**, lo que mejora la compresión y acelera consultas analíticas.  
   - En lugar de guardar datos fila por fila, se almacenan por columna, reduciendo el uso de disco y mejorando el rendimiento en agregaciones.  
   - Este enfoque es útil en análisis de grandes volúmenes de datos.  

Aunque **Citus Columnar** almacena los datos en formato columnar internamente, la estructura visual en PostgreSQL sigue siendo la misma que en almacenamiento tradicional. Cuando consultas la tabla, los resultados **se presentan en filas y columnas**, como cualquier otra tabla en PostgreSQL.

Lo que cambia es **cómo los datos se organizan y se leen** detrás de escena:
- En almacenamiento tradicional, PostgreSQL **almacena y recupera filas completas**, lo que puede hacer que agregaciones y análisis sean más lentos.
- En Citus Columnar, los datos **se guardan por columna**, permitiendo acceder solo a las columnas necesarias, lo que mejora el rendimiento en consultas analíticas.


 # **desventajas y consideraciones** que debes tener en cuenta antes de implementarlo:

📌 **Desventajas del almacenamiento columnar**  
- **Menor rendimiento en operaciones OLTP**: No es ideal para cargas de trabajo transaccionales con muchas inserciones y actualizaciones individuales.  
- **Mayor latencia en escrituras**: Las actualizaciones requieren modificar múltiples columnas separadas, lo que puede aumentar el tiempo de procesamiento.  
- **Complejidad en la administración**: Requiere ajustes específicos para optimizar consultas y almacenamiento.  
- **Mayor consumo de memoria en ciertas consultas**: Algunas operaciones pueden requerir más recursos debido a la forma en que los datos se almacenan y procesan.  
- **No siempre es más rápido**: En conjuntos de datos pequeños, el almacenamiento tradicional puede ser más eficiente.  

📌 **Consideraciones antes de usar almacenamiento columnar**  
- **Evalúa el tipo de carga de trabajo**: Si tu aplicación requiere muchas lecturas analíticas, columnar puede ser beneficioso.  
- **Optimiza la compresión**: Usar `LZ4` puede mejorar el rendimiento y reducir el uso de almacenamiento.  
- **Configura correctamente la distribución de datos**: Elegir la columna de distribución adecuada es clave para evitar cuellos de botella.  
- **Prueba con datos reales**: Antes de migrar completamente, realiza pruebas de rendimiento con tu carga de trabajo específica.  
 
 

# laboratorio profesional 
genere **alto estrés** en PostgreSQL y demuestre los beneficios de **Citus Columnar**, seguiremos estos pasos:

### **1. Configuración del entorno**
- **Instalar PostgreSQL y Citus** en un entorno distribuido con al menos **3 nodos**.
- **Activar la extensión Citus** en el nodo coordinador:
  ```sql
  CREATE EXTENSION citus;
  ```
- **Configurar nodos de trabajo** y distribuir shards.

### **2. Creación de tablas con almacenamiento tradicional y columnar**
- **Tabla tradicional**:
  ```sql
  CREATE TABLE ventas_filas (
      id SERIAL PRIMARY KEY,
      producto TEXT,
      cantidad INT,
      precio NUMERIC,
      fecha TIMESTAMP
  );
  ```
- **Tabla columnar**:
  ```sql
  CREATE TABLE ventas_columnar (
      id SERIAL PRIMARY KEY,
      producto TEXT,
      cantidad INT,
      precio NUMERIC,
      fecha TIMESTAMP
  ) USING columnar;
  ```
- Configura la compresión:
  ```sql
  ALTER TABLE ventas_columnar SET (columnar.compression = 'lz4');

  --- soporte en compresion 
  LZ4: Ofrece una compresión rápida con bajo consumo de CPU, ideal para mejorar la velocidad de lectura sin afectar el rendimiento.
  zstd: Proporciona una mayor tasa de compresión que LZ4, útil para reducir el uso de almacenamiento en grandes volúmenes de datos.

  ```

- Consulta las opciones de columnar
   ```
  SELECT * FROM columnar.options;
  postgres@postgres# SELECT * FROM columnar.options;
  +-----------------+-----------------------+------------------+-------------+-------------------+
  |    relation     | chunk_group_row_limit | stripe_row_limit | compression | compression_level |
  +-----------------+-----------------------+------------------+-------------+-------------------+
  | ventas          |                 10000 |           150000 | zstd        |                 3 |
  | ventas_columnar |                 10000 |           150000 | lz4         |                 3 |
  +-----------------+-----------------------+------------------+-------------+-------------------+
  (2 rows)
  ```
  
### **3. Generación de carga masiva**
- Insertar **millones de registros** en ambas tablas:
  ```sql
  INSERT INTO ventas_filas (producto, cantidad, precio, fecha)
  SELECT 'Laptop', generate_series(1, 5000000), random()*2000, now();
  ```
  ```sql
  INSERT INTO ventas_columnar (producto, cantidad, precio, fecha)
  SELECT 'Laptop', generate_series(1, 5000000), random()*2000, now();
  ```

### **4. Pruebas de estrés**
- **Consulta agregada en tabla tradicional**:
  ```sql
  SELECT AVG(precio) FROM ventas_filas;
  ```
- **Consulta agregada en tabla columnar**:
  ```sql
  SELECT AVG(precio) FROM ventas_columnar;
  ```
- **Comparación de tiempos** con `EXPLAIN ANALYZE`.

- Medición de reducción de I/O:
```sql
  postgres@postgres# SELECT pg_size_pretty(pg_relation_size('ventas_columnar'));
+----------------+
| pg_size_pretty |
+----------------+
| 71 MB          |
+----------------+
(1 row)

Time: 9.937 ms
postgres@postgres# SELECT pg_size_pretty(pg_relation_size('ventas_filas'));
+----------------+
| pg_size_pretty |
+----------------+
| 326 MB         |
+----------------+
(1 row)
```
 



### **5. Evaluación de rendimiento**
- **Medir uso de CPU y memoria** en cada nodo.
- **Comparar tiempos de respuesta** entre almacenamiento tradicional y columnar.
- **Analizar reducción de I/O** en almacenamiento columnar.

### Info extra 
```
 postgres@postgres# select table_schema,table_name,table_type from information_schema.tables where table_schema = 'columnar';
+--------------+-------------+------------+
| table_schema | table_name  | table_type |
+--------------+-------------+------------+
| columnar     | storage     | VIEW       |
| columnar     | options     | VIEW       |
| columnar     | stripe      | VIEW       |
| columnar     | chunk_group | VIEW       |
| columnar     | chunk       | VIEW       |
+--------------+-------------+------------+


postgres@postgres# select name,setting, context from pg_settings where name ilike '%citus%' order by context;
+----------------------------------------------------+-----------------+-------------------+
|                        name                        |     setting     |      context      |
+----------------------------------------------------+-----------------+-------------------+
| citus.version                                      | 13.1.0          | internal          |
| citus.stat_tenants_limit                           | 100             | postmaster        |
| citus.max_worker_nodes_tracked                     | 2048            | postmaster        |
| citus.max_background_task_executors                | 4               | sighup            |
| citus.local_shared_pool_size                       | 50              | sighup            |
| citus.enable_statistics_collection                 | off             | sighup            |
| citus.background_task_queue_interval               | 5000            | sighup            |
| citus.max_shared_pool_size                         | 100             | sighup            |
| citus.max_background_task_executors_per_node       | 1               | sighup            |
| citus.recover_2pc_interval                         | 60000           | sighup            |
| citus.desired_percent_disk_available_after_move    | 10              | sighup            |
| citus.defer_shard_delete_interval                  | 15000           | sighup            |
| citus.distributed_deadlock_detection_factor        | 2               | sighup            |
| citus.node_conninfo                                | sslmode=require | sighup            |
| citus.cpu_priority_for_logical_replication_senders | inherit         | superuser         |
| citus.local_hostname                               | localhost       | superuser         |
| citus.cpu_priority                                 | 0               | superuser         |
| citus.skip_constraint_validation                   | off             | superuser         |
| citus.stat_statements_track                        | none            | superuser         |
| citus.enable_stat_counters                         | off             | superuser         |
| citus.stat_tenants_track                           | none            | superuser         |
| citus.max_client_connections                       | -1              | superuser         |
| citus.superuser                                    |                 | superuser         |
| citus.max_high_priority_background_processes       | 2               | superuser         |
| citus.use_secondary_nodes                          | never           | superuser-backend |
| citus.cluster_name                                 | default         | superuser-backend |
| citus.node_connection_timeout                      | 30000           | user              |
| citus.propagate_set_commands                       | none            | user              |
| citus.remote_task_check_interval                   | 10              | user              |
| citus.shard_count                                  | 32              | user              |
| citus.shard_replication_factor                     | 1               | user              |
| citus.show_shards_for_app_name_prefixes            |                 | user              |
| citus.skip_jsonb_validation_in_copy                | on              | user              |
| citus.stat_tenants_log_level                       | off             | user              |
| citus.stat_tenants_period                          | 60              | user              |
| citus.stat_tenants_untracked_sample_rate           | 1               | user              |
| citus.task_assignment_policy                       | greedy          | user              |
| citus.task_executor_type                           | adaptive        | user              |
| citus.use_citus_managed_tables                     | off             | user              |
| citus.values_materialization_threshold             | 100             | user              |
| citus.worker_min_messages                          | notice          | user              |
| citus.writable_standby_coordinator                 | off             | user              |
| citus.multi_task_query_log_level                   | off             | user              |
| citus.coordinator_aggregation_strategy             | row-gather      | user              |
| citus.count_distinct_error_rate                    | 0               | user              |
| citus.defer_drop_after_shard_move                  | on              | user              |
| citus.defer_drop_after_shard_split                 | on              | user              |
| citus.enable_binary_protocol                       | on              | user              |
| citus.enable_change_data_capture                   | off             | user              |
| citus.enable_create_database_propagation           | off             | user              |
| citus.enable_create_role_propagation               | on              | user              |
| citus.enable_deadlock_prevention                   | on              | user              |
| citus.enable_local_execution                       | on              | user              |
| citus.enable_local_reference_table_foreign_keys    | on              | user              |
| citus.enable_repartition_joins                     | off             | user              |
| citus.enable_schema_based_sharding                 | off             | user              |
| citus.explain_all_tasks                            | off             | user              |
| citus.explain_analyze_sort_method                  | execution-time  | user              |
| citus.limit_clause_row_fetch_count                 | -1              | user              |
| citus.local_table_join_policy                      | auto            | user              |
| citus.log_remote_commands                          | off             | user              |
| citus.max_adaptive_executor_pool_size              | 16              | user              |
| citus.max_cached_connection_lifetime               | 600000          | user              |
| citus.max_cached_conns_per_worker                  | 1               | user              |
| citus.max_intermediate_result_size                 | 1048576         | user              |
| citus.max_matview_size_to_auto_recreate            | 1024            | user              |
| citus.multi_shard_modify_mode                      | parallel        | user              |
| citus.all_modifications_commutative                | off             | user              |
+----------------------------------------------------+-----------------+-------------------+
(68 rows)



```
