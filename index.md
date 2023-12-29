

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
