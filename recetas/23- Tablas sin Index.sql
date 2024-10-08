---  Encuentra tablas que no tienen index, el primary key no cuenta 

 
select 
	a.table_schema
	,a.table_name
	--,table_type
	,pg_catalog.pg_relation_size(a.table_schema || '.'|| a.table_name) as table_size_kb
	,case when indexname is null then false else true end as if_has_index
	,case when constraint_name is null then false else true end as if_has_primary_key 
from information_schema.tables as a 
left join 
	(select 
		schemaname
		,tablename
		,indexname 
	from pg_indexes 
	where schemaname not in('pg_catalog','information_schema') 
		and indexname not in(	select 
									constraint_name  
								from information_schema.table_constraints  
								where  constraint_type ='PRIMARY KEY' 
									and constraint_schema  not in('pg_catalog','information_schema') 
							)  
	) as b on  b.schemaname = a.table_schema and a.table_name= b.tablename 
left join 	(	select 
					table_schema
					,table_name
					,constraint_name 
				from information_schema.table_constraints  
				where  constraint_type ='PRIMARY KEY'
			) as c on a.table_schema = c.table_schema and a.table_name = c.table_name
where a.table_schema not in('pg_catalog','information_schema') 
	and table_type = 'BASE TABLE' 
	and indexname is null
order by pg_catalog.pg_relation_size(a.table_schema || '.'|| a.table_name) desc ;
 
