/* 
		Consulta: Inventario Objetos
La ejecución del inventario de objetos son lecturas que extraen informacion de la estructura de la Base de Datos 
consultando la capa de información propia de ésta. La consulta extrae la siguiente informacion: 
- Esquema
- Nombre (nombre del objeto)
- Tipo_Objeto
- Descripcion_Tipo_Objeto
- Fecha_Creacion
- Fecha_Modificacion
- Parametros (de las funciones/procedimientos)
*/

/*
select nsp.nspname as Esquema ,cls.relname as Nombre, cls.relkind as Tipo_Objecto
,case cls.relkind when 'r' then 'TABLE'
when 'm' then 'MATERIALIZED_VIEW'
when 'i' then 'INDEX'
when 'S' then 'SEQUENCE'
when 'v' then 'VIEW'
when 'c' then 'TYPE'
else cls.relkind::text end as Descripcion_Tipo_Objeto, NULL as Fecha_Creacion, NULL as Fecha_Modificacion, NULL as Parametros
from pg_class cls
join pg_roles rol on rol.oid = cls.relowner
join pg_namespace nsp on nsp.oid = cls.relnamespace
where nsp.nspname not in ('information_schema', 'pg_catalog') and nsp.nspname not like 'pg_toast%'

union all

select n.nspname as Esquema, p.proname as Nombre, 'f' as Tipo_Objecto, 'FUNCTION' as Descripcion_Tipo_Objeto, NULL as Fecha_Creacion, NULL as Fecha_Modificacion, PROARGNAMES AS Parametros
from pg_proc p
left join pg_namespace n on p.pronamespace = n.oid
left join pg_language l on p.prolang = l.oid
left join pg_type t on t.oid = p.prorettype 
where n.nspname not in ('pg_catalog', 'information_schema')
order by 1, 2;
*/

COPY (select nsp.nspname as Esquema ,cls.relname as Nombre, cls.relkind as Tipo_Objecto
,case cls.relkind when 'r' then 'TABLE'
when 'm' then 'MATERIALIZED_VIEW'
when 'i' then 'INDEX'
when 'S' then 'SEQUENCE'
when 'v' then 'VIEW'
when 'c' then 'TYPE'
--when 'r' then 'TABLE'

else cls.relkind::text end as Descripcion_Tipo_Objeto, NULL as Fecha_Creacion, NULL as Fecha_Modificacion, NULL as Parametros
from pg_class cls
join pg_roles rol on rol.oid = cls.relowner
join pg_namespace nsp on nsp.oid = cls.relnamespace
where nsp.nspname not in ('information_schema', 'pg_catalog') and nsp.nspname not like 'pg_toast%'

union all

select n.nspname as Esquema, p.proname as Nombre, 'f' as Tipo_Objecto, 'FUNCTION' as Descripcion_Tipo_Objeto, NULL as Fecha_Creacion, NULL as Fecha_Modificacion, PROARGNAMES AS Parametros
from pg_proc p
left join pg_namespace n on p.pronamespace = n.oid
left join pg_language l on p.prolang = l.oid
left join pg_type t on t.oid = p.prorettype 
where n.nspname not in ('pg_catalog', 'information_schema')
order by 1, 2) TO '/tmp/receta/1_Inventario_Objetos.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);





/*

 psql -c "select nsp.nspname as Esquema ,cls.relname as Nombre, cls.relkind as Tipo_Objecto ,case cls.relkind when 'r' then 'TABLE' when 'm' then 'MATERIALIZED_VIEW' when 'i' then 'INDEX' when 'S' then 'SEQUENCE' when 'v' then 'VIEW' when 'c' then 'TYPE' else cls.relkind::text end as Descripcion_Tipo_Objeto, NULL as Fecha_Creacion, NULL as Fecha_Modificacion, NULL as Parametros from pg_class cls join pg_roles rol on rol.oid = cls.relowner join pg_namespace nsp on nsp.oid = cls.relnamespace where nsp.nspname not in ('information_schema', 'pg_catalog') and nsp.nspname not like 'pg_toast%' union all select n.nspname as Esquema, p.proname as Nombre, 'f' as Tipo_Objecto, 'FUNCTION' as Descripcion_Tipo_Objeto, NULL as Fecha_Creacion, NULL as Fecha_Modificacion, PROARGNAMES AS Parametros from pg_proc p left join pg_namespace n on p.pronamespace = n.oid left join pg_language l on p.prolang = l.oid left join pg_type t on t.oid = p.prorettype  where n.nspname not in ('pg_catalog', 'information_schema') order by 1, 2" | grep -v "+" | tr "|" "," > /tmp/receta/1_Inventario_Objetos.csv
 
 */