


# CREAR INDEX 
```SQL
CREATE INDEX [ IF NOT EXISTS ] nombre_del_indice ON nombre_de_tabla (columna1, columna2, ...);
```


```SQL

select pg_indexes_size(index_name);


select * from pg_index limit 1;


-- Obtener información sobre los índices y su tamaño:
SELECT schemaname || '.' || indexname AS index_full_name,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || indexname)) AS size
FROM pg_indexes ORDER BY pg_total_relation_size(schemaname || '.' || indexname) DESC;


-- Mostrar el tamaño y uso de los índices en cada tabla
SELECT schemaname || '.' || tablename AS table_full_name,
       indexname AS index_name,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || indexrelname)) AS index_size,
       idx_scan AS index_scans
FROM pg_indexes
JOIN pg_stat_user_indexes ON pg_indexes.schemaname = pg_stat_user_indexes.schemaname AND pg_indexes.indexrelname = pg_stat_user_indexes.indexrelname
ORDER BY pg_total_relation_size(schemaname || '.' || indexrelname) DESC;
```

```SQL
CREATE EXTENSION pgstattuple;

- **Funciones disponibles**:
  - `pgstattuple(regclass)` devuelve información sobre la longitud física de una relación, el porcentaje de tuplas "muertas" y otros datos relevantes. Esto puede ayudarte a determinar si es necesario realizar un vaciado de la tabla¹.
  - `pgstattuple(text)` es similar a la función anterior, pero permite especificar la relación de destino como texto. Sin embargo, esta función quedará obsoleta en futuras versiones¹.
  - `pgstatindex(regclass)` proporciona información sobre un índice de árbol B¹.

- **Columnas de salida**:
  - `table_len`: Longitud física de la relación en bytes.
  - `tuple_count`: Número de tuplas vivas.
  - `tuple_len`: Longitud total de tuplas activas en bytes.
  - `tuple_percent`: Porcentaje de tuplas vivas.
  - `dead_tuple_count`: Número de tuplas muertas.
  - `dead_tuple_len`: Longitud total de tuplas muertas en bytes.
  - `dead_tuple_percent`: Porcentaje de tuplas muertas.
  - `free_space`: Espacio libre total en bytes.
  - `free_percent`: Porcentaje de espacio libre¹.


SELECT t0.indexrelid::regclass as Indice, t5.tablename as Tabla, t1.reltuples as Registros, t4.leaf_fragmentation as Porcentaje_Fragmentacion 
/* ,case t1.relkind when 'r' then 'TABLE'
when 'm' then 'MATERIALIZED_VIEW'
when 'i' then 'INDEX'
when 'S' then 'SEQUENCE'
when 'v' then 'VIEW'
when 'c' then 'TYPE'
else t1.relkind::text end as Descripcion_Tipo_Objeto */ 
FROM pg_index AS t0
   JOIN pg_class AS t1 ON t0.indexrelid = t1.oid /* and relnamespace  in( SELECT oid   FROM pg_namespace  WHERE nspname = 'public') */ 
   JOIN pg_opclass AS t2 ON t0.indclass[0] = t2.oid
   JOIN pg_am as t3 ON t2.opcmethod = t3.oid
   CROSS JOIN LATERAL pgstatindex(t0.indexrelid) AS t4
   left join pg_indexes t5 on t1.relname = t5.indexname
WHERE t1.relkind = 'i' AND t3.amname = 'btree' and t4.leaf_fragmentation >=0
```


https://dbalifeeasy.com/2020/10/04/how-to-identify-fragmentation-in-postgresql-rds/ 
