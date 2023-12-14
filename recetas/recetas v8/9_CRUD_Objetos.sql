/* 
		Consulta: BPD-CRUD_Objetos
La ejecución muestra en listado el conteo de las sentencias CRUD, para obtener el número que estas sentencias son 
utilizadas, consultando unicamente la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Esquema
- Objeto
- Tipo
- Lineas_Totales
- Lineas_Vacias
- Lineas_Comentadas
- Commits
- Rollbacks
- Selects	
- IFS	
- Selects2 (Select*)	
- Deletes	
- Updates	
- Inserts	
- Excepciones	
- Whiles	
- Fors	
- Loops	
- Cursores

*/

select Usuario AS Esquema, Objeto, 'f' as Tipo, count(*) as Lineas_Totales,
sum(case when LENGTH(Linea) = 0 then 1 else 0 end) as Lineas_Vacias,
sum(case when Linea like '--%' then 1 else 0 end) as Lineas_Comentadas,
sum(case when UPPER(Linea) like 'COMMIT %' then 1 else 0 end) as Commits,
sum(case when UPPER(Linea) like 'ROLLBACK %' then 1 else 0 end) as Rollbacks,
sum(case when UPPER(Linea) like '%SELECT *%' then 1 else 0 end) as Selects,
sum(case when UPPER(Linea) like '%IF%' AND UPPER(Linea) not like '%END IF%'  then 1 else 0 end) as IFS,
sum(case when UPPER(Linea) like '%SELECT%' and UPPER(Linea) not like '%SELECT *%' then 1 else 0 end) as Selects2,
sum(case when UPPER(Linea) like '%DELETE %' then 1 else 0 end) as Deletes,
sum(case when UPPER(Linea) like '%UPDATE %' then 1 else 0 end) as Updates,
sum(case when UPPER(Linea) like '%INSERT %' then 1 else 0 end) as Inserts,
sum(case when UPPER(Linea) like '%EXCEPTION %' OR UPPER(Linea) like '%TRY%' then 1 else 0 end) as Excepciones,
sum(case when UPPER(Linea) like '%WHILE %' then 1 else 0 end) as Whiles,
sum(case when UPPER(Linea) like '%FOR %' then 1 else 0 end) as Fors,
sum(case when UPPER(Linea) like '%LOOP %' AND UPPER(Linea) not like '%END LOOP%'  then 1 else 0 end) as Loops,
sum(case when UPPER(Linea) like '%Cursor %' then 1 else 0 end) as Cursores
from 
(
select t1.nspname as Usuario, proname as Objeto, prosrc as Linea

from pg_proc t0
left join pg_namespace t1 on t0.pronamespace = t1.oid
where 
proisstrict = false
and t1.nspname not in('information_schema', 'pg_catalog')
)t1
group by usuario, objeto
ORDER BY 1, 3, 2;