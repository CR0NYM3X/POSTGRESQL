

```SQL
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
