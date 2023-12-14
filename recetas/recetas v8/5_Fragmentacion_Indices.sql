/* 
		Consulta: BPD-Fragmentacion_indices
La ejecución muestra el listado de los indices que se encuentran fragmentados, derivado a los constantes movimientos 
que existen en la operacion dentro de la base de datos, consultando unicamente la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Script_Fragmentacion
- Tabla
- Registros
- Porcentaje_Fragmentacion		

*/

select 'REINDEX INDEX ' || indexrelname || ';' as Script_Fragmentacion, t1.relname as Tabla, t1.reltuples AS Registros,
case when idx_blks_hit = 0 then 0 else ((idx_blks_hit - idx_blks_read) / cast((idx_blks_hit) as float))*100 end as Porcentaje_Fragmentacion
from pg_statio_all_indexes t0
inner join pg_class t1 on t0.relname = t1.relname
LEFT JOIN pg_namespace t2 ON t2.oid = t1.relnamespace
where schemaname = 'public'
order by 3;