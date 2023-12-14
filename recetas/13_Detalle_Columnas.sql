/* 
		Consulta: BPD-Columnas
La ejecución extrae el detalle de cada columna que se encuentra dentro de la Base de Datos, consultando unicamente 
la capa de información propia de ésta. La consulta extrae la siguiente informacion: 
- Esquema
- Tabla	
- Columna	
- Llave_Primaria	
- Llave_Foranea	
- Indices	
- Contraints	
- Tipo_Dato	
- Longitud	
- Valor_Default	
- Acepta_Nulo	
*/
/*
select t0.table_schema as Esquema, t0.table_name as Tabla, t0.column_name as Columna, t1.constraint_name as Llave_Primaria, t2.constraint_name as Llave_Foranea,
(select string_agg(i.relname, ',') from pg_class t, pg_class i, pg_index ix,pg_attribute a
where t.oid = ix.indrelid and i.oid = ix.indexrelid and a.attrelid = t.oid and a.attnum = ANY(ix.indkey) and t.relkind = 'r'
and t.relname = t0.table_name and a.attname = t0.column_name) as Indices,

(select string_agg(tt4.constraint_name, ',') from INFORMATION_SCHEMA.constraint_column_usage tt4
inner join pg_namespace tt5 on tt4.constraint_schema = tt5.nspname
inner join pg_constraint tt6 on tt5.oid = tt6.connamespace and tt4.constraint_name = tt6.conname
where tt6.contype in ('c', 'u', 'x') and t0.table_schema = tt4.table_schema and t0.table_name = tt4.table_name and t0.column_name = tt4.column_name) as Constraints,
t0.data_type as Tipo_Dato, t0.character_maximum_length as Longitud, t0.column_default as Valor_Default, 
case when t0.is_nullable <> 'NO' then 'SI' else 'NO' end as Acepta_Nulos

from INFORMATION_SCHEMA.columns t0
left join (
select tt0.table_schema, tt0.table_name, tt0.column_name, tt1.constraint_name
from information_schema.key_column_usage tt0
left join information_schema.table_constraints tt1 on tt0.constraint_name = tt1.constraint_name and tt0.constraint_schema = tt1.constraint_schema
where tt1.constraint_type = 'PRIMARY KEY') t1 on t0.table_schema = t1.table_schema and t0.table_name = t1.table_name and t0.column_name = t1.column_name
left join (
select tt2.table_schema, tt2.table_name, tt2.column_name, tt3.constraint_name
from information_schema.key_column_usage tt2
left join information_schema.table_constraints tt3 on tt2.constraint_name = tt3.constraint_name and tt2.constraint_schema = tt3.constraint_schema
where tt3.constraint_type = 'FOREIGN KEY') t2 on t0.table_schema = t2.table_schema and t0.table_name = t2.table_name and t0.column_name = t2.column_name
where t0.table_schema = 'public'
order by 1, 2, t0.ordinal_position;
*/





COPY (select t0.table_schema as Esquema, t0.table_name as Tabla, t0.column_name as Columna, t1.constraint_name as Llave_Primaria, t2.constraint_name as Llave_Foranea,
(select string_agg(i.relname, ',') from pg_class t, pg_class i, pg_index ix,pg_attribute a
where t.oid = ix.indrelid and i.oid = ix.indexrelid and a.attrelid = t.oid and a.attnum = ANY(ix.indkey) and t.relkind = 'r'
and t.relname = t0.table_name and a.attname = t0.column_name) as Indices,

(select string_agg(tt4.constraint_name, ',') from INFORMATION_SCHEMA.constraint_column_usage tt4
inner join pg_namespace tt5 on tt4.constraint_schema = tt5.nspname
inner join pg_constraint tt6 on tt5.oid = tt6.connamespace and tt4.constraint_name = tt6.conname
where tt6.contype in ('c', 'u', 'x') and t0.table_schema = tt4.table_schema and t0.table_name = tt4.table_name and t0.column_name = tt4.column_name) as Constraints,
t0.data_type as Tipo_Dato, t0.character_maximum_length as Longitud, t0.column_default as Valor_Default, 
case when t0.is_nullable <> 'NO' then 'SI' else 'NO' end as Acepta_Nulos

from INFORMATION_SCHEMA.columns t0
left join (
select tt0.table_schema, tt0.table_name, tt0.column_name, tt1.constraint_name
from information_schema.key_column_usage tt0
left join information_schema.table_constraints tt1 on tt0.constraint_name = tt1.constraint_name and tt0.constraint_schema = tt1.constraint_schema
where tt1.constraint_type = 'PRIMARY KEY') t1 on t0.table_schema = t1.table_schema and t0.table_name = t1.table_name and t0.column_name = t1.column_name
left join (
select tt2.table_schema, tt2.table_name, tt2.column_name, tt3.constraint_name
from information_schema.key_column_usage tt2
left join information_schema.table_constraints tt3 on tt2.constraint_name = tt3.constraint_name and tt2.constraint_schema = tt3.constraint_schema
where tt3.constraint_type = 'FOREIGN KEY') t2 on t0.table_schema = t2.table_schema and t0.table_name = t2.table_name and t0.column_name = t2.column_name
where t0.table_schema = 'public'
order by 1, 2, t0.ordinal_position) TO '/tmp/receta/13_Detalle_Columnas.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);


/*
 psql -c "select t0.table_schema as Esquema, t0.table_name as Tabla, t0.column_name as Columna, t1.constraint_name as Llave_Primaria, t2.constraint_name as Llave_Foranea, (select string_agg(i.relname, ',') from pg_class t, pg_class  i, pg_index ix,pg_attribute a where t.oid = ix.indrelid and i.oid = ix.indexrelid and a.attrelid = t.oid and a.attnum = ANY(ix.indkey) and t.relkind = 'r' and t.relname = t0.table_name and a.attname = t0.column_name) as Indices, (select string_agg(tt4.constraint_name, ',') from INFORMATION_SCHEMA.constraint_column_usage tt4 inner join pg_namespace tt5 on tt4.constraint_schema = tt5.nspname inner join pg_constraint tt6 on tt5.oid = tt6.connamespace and tt4.constraint_name = tt6.conname where tt6.contype in ('c', 'u', 'x') and t0.table_schema = tt4.table_schema and t0.table_name = tt4.table_name and t0.column_name = tt4.column_name) as  Constraints, t0.data_type as Tipo_Dato, t0.character_maximum_length as Longitud, t0.column_default as Valor_Default,  case when t0.is_nullable <> 'NO' then 'SI' else 'NO' end as Acepta_Nulos from  INFORMATION_SCHEMA.columns t0 left join ( select tt0.table_schema, tt0.table_name, tt0.column_name, tt1.constraint_name from information_schema.key_column_usage tt0 left join information_schema.table_constraints tt1 on  tt0.constraint_name = tt1.constraint_name and tt0.constraint_schema = tt1.constraint_schema where tt1.constraint_type = 'PRIMARY KEY') t1 on t0.table_schema = t1.table_schema and t0.table_name = t1.table_name and  t0.column_name = t1.column_name  left join ( select tt2.table_schema, tt2.table_name, tt2.column_name, tt3.constraint_name from information_schema.key_column_usage tt2 left join information_schema.table_constraints tt3 on  tt2.constraint_name = tt3.constraint_name and tt2.constraint_schema = tt3.constraint_schema where tt3.constraint_type = 'FOREIGN KEY') t2 on t0.table_schema = t2.table_schema and t0.table_name = t2.table_name and  t0.column_name = t2.column_name where t0.table_schema = 'public' order by 1, 2, t0.ordinal_position" | grep -v "+" | tr "|" "," > /tmp/receta/13_Detalle_Columnas.csv
 
 
 */