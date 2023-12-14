/* 
		Consulta: BPD-Codigo Objetos
La ejecución extrae el código de los SP y Vistas que se tienen dentro de la base de datos, respetando su respectiva linea 
de codificación, consultando unicamente la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Esquema
- Objeto
- Tipo_Objeto
- Numero_Linea
- Linea	

*/
/*
select Esquema, Objeto, 'F' AS Tipo_Objeto, ROW_NUMBER () OVER (PARTITION BY objeto,fila) as Numero_Linea, Linea
from (
select t1.nspname as Esquema, proname as Objeto, regexp_split_to_table(prosrc, E'\n') as Linea,
ROW_NUMBER () OVER (PARTITION BY proname) as Fila
from pg_proc t0
left join pg_namespace t1 on t0.pronamespace = t1.oid 
where 
proisstrict = false
and t1.nspname not in('information_schema', 'pg_catalog')
)d
order by 1, 2;


*/





COPY (select Esquema, Objeto, 'F' AS Tipo_Objeto, ROW_NUMBER () OVER (PARTITION BY objeto,fila) as Numero_Linea, Linea
from (
select t1.nspname as Esquema, proname as Objeto, regexp_split_to_table(prosrc, E'\n') as Linea,
ROW_NUMBER () OVER (PARTITION BY proname) as Fila
from pg_proc t0
left join pg_namespace t1 on t0.pronamespace = t1.oid 
where 
proisstrict = false
and t1.nspname not in('information_schema', 'pg_catalog')
)d
order by 1, 2) TO '/tmp/receta/12_Codigo_Objetos_numlinea.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);



 
 
/*
 
 psql -c "select Esquema, Objeto, 'F' AS Tipo_Objeto, ROW_NUMBER () OVER (PARTITION BY objeto,fila) as Numero_Linea, Linea from ( select t1.nspname as Esquema, proname as Objeto, regexp_split_to_table(prosrc, E'\n') as Linea,ROW_NUMBER () OVER (PARTITION BY proname) as Fila from pg_proc t0 left join pg_namespace t1 on t0.pronamespace = t1.oid  where  proisstrict = false and t1.nspname not in('information_schema', 'pg_catalog') )d order by 1, 2" | grep -v "+" | tr "|" "," > /tmp/receta/12_Codigo_Objetos_numlinea.csv
 
 
 */