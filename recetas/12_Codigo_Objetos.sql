/* 
		Consulta: BPD-Codigo Objetos
La ejecución extrae el código de los SP y Vistas que se tienen dentro de la base de datos, respetando su respectiva linea 
de codificación, consultando unicamente la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Esquema
- Objeto
- Tipo_Objeto
- Linea	

*/
/*

select t1.nspname as Esquema, proname as Objeto, 'f' as Tipo_Objeto, prosrc as Linea
from pg_proc t0
left join pg_namespace t1 on t0.pronamespace = t1.oid 
where 
proisstrict = false and t1.nspname not in('information_schema', 'pg_catalog')
order by 1, 2;

*/



COPY (select t1.nspname as Esquema, proname as Objeto, 'f' as Tipo_Objeto, prosrc as Linea
from pg_proc t0
left join pg_namespace t1 on t0.pronamespace = t1.oid 
where 
proisstrict = false and t1.nspname not in('information_schema', 'pg_catalog')
order by 1, 2) TO '/tmp/receta/12_Codigo_Objetos.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);


/*

 psql -c "select t1.nspname as Esquema, proname as Objeto, 'f' as Tipo_Objeto, prosrc as Linea from pg_proc t0 left join pg_namespace t1 on t0.pronamespace = t1.oid  where  proisstrict = false and t1.nspname not in('information_schema', 'pg_catalog') order by 1, 2" | grep -v "+" | tr "|" "," > /tmp/receta/12_Codigo_Objetos.csv

*/


 
 
 