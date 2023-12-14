/*select tab.table_schema,
       tab.table_name
from information_schema.tables tab
left join information_schema.table_constraints tco 
          on tab.table_schema = tco.table_schema
          and tab.table_name = tco.table_name 
          and tco.constraint_type = 'FOREIGN KEY'
where tab.table_type = 'BASE TABLE'
      and tab.table_schema not in ('pg_catalog', 'information_schema')
      and tco.constraint_name is null
order by table_schema,
         table_name;
		 
		 
		 */
		 
		 
		 
		 
		 
		 
		 COPY (select tab.table_schema,
       tab.table_name
from information_schema.tables tab
left join information_schema.table_constraints tco 
          on tab.table_schema = tco.table_schema
          and tab.table_name = tco.table_name 
          and tco.constraint_type = 'FOREIGN KEY'
where tab.table_type = 'BASE TABLE'
      and tab.table_schema not in ('pg_catalog', 'information_schema')
      and tco.constraint_name is null
order by table_schema,
         table_name) TO '/tmp/receta/16_Tablas_sin_FK.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);
		 
		 /*
		 
 psql -c "select tab.table_schema, tab.table_name from information_schema.tables tab left join information_schema.table_constraints tco on tab.table_schema = tco.table_schema and tab.table_name = tco.table_name and tco.constraint_type = 'FOREIGN KEY' where tab.table_type = 'BASE TABLE' and tab.table_schema not in ('pg_catalog', 'information_schema') and tco.constraint_name is null order by table_schema, table_name " | grep -v "+" | tr "|" "," > /tmp/receta/16_Tablas_sin_FK.csv
 
 */