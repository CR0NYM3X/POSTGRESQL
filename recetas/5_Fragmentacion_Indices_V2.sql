/* 
		Consulta: BPD-Fragmentacion_indices
La ejecución muestra el listado de los indices que se encuentran fragmentados, derivado a los constantes movimientos 
que existen en la operacion dentro de la base de datos, consultando unicamente la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Indice
- Tabla
- Registros
- Porcentaje_Fragmentacion		

*/

CREATE EXTENSION pgstattuple;

COPY (SELECT t0.indexrelid::regclass as Indice, t5.tablename as Tabla, t1.reltuples as Registros, t4.leaf_fragmentation as Porcentaje_Fragmentacion
FROM pg_index AS t0
   JOIN pg_class AS t1 ON t0.indexrelid = t1.oid
   JOIN pg_opclass AS t2 ON t0.indclass[0] = t2.oid
   JOIN pg_am as t3 ON t2.opcmethod = t3.oid
   CROSS JOIN LATERAL pgstatindex(t0.indexrelid) AS t4
   left join pg_indexes t5 on t1.relname = t5.indexname
WHERE t1.relkind = 'i' AND t3.amname = 'btree' and t4.leaf_fragmentation >=0
) TO '/tmp/receta/5_Fragmentacion_Indices_V2.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);





drop EXTENSION pgstattuple;