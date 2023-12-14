/* 
		Consulta: BPD-Porcentaje_Llaves
La ejecución muestra el porcentaje sobre el total del numero de llaves, el porcentaje de tablas que si se tienen y los que
no, consultando unicamente la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Total_tablas_BD
- Tablas_sin_Llave
- Porcentaje_Sin_Llaves
- Tipo

*/
/*
select tot_tab.A as Total_tablas_BD, Tablas_sin_PK.B as Tablas_Sin_Llave, ((Tablas_sin_PK.B * 100)/ tot_tab.A) AS Porcentaje_sin_Llaves, 'Llave Primaria' as Tipo
from 
(select COUNT(*) as A 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE'
 )tot_tab,
(select COUNT(*) as B 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE' AND
T0.TABLE_NAME  NOT IN (
SELECT TABLE_NAME FROM information_schema.table_constraints t1 
WHERE t1.table_schema NOT IN ('pg_catalog', 'information_schema') AND t1.constraint_type = 'PRIMARY KEY'))Tablas_sin_PK
	
union all

select tot_tab.A as Total_tablas_BD, Tablas_sin_FK.B as Tablas_Sin_Llave, ((Tablas_sin_FK.B * 100)/ tot_tab.A) AS Porcentaje_sin_Llaves, 'Llave Foranea' as Tipo
from 
(select COUNT(*) as A 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE'
 )tot_tab,
(select COUNT(*) as B 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE' AND
T0.TABLE_NAME  NOT IN (
SELECT TABLE_NAME FROM information_schema.table_constraints t1 
WHERE t1.table_schema NOT IN ('pg_catalog', 'information_schema') AND t1.constraint_type = 'FOREIGN KEY'))Tablas_sin_FK
	
union all

select tot_tab.A as Total_tablas_BD, Tablas_sin_IDX.B as Tablas_Sin_Llave, ((Tablas_sin_IDX.B * 100)/ tot_tab.A) AS Porcentaje_sin_Llaves, 'Indices' as Tipo
from 
(select COUNT(*) as A 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE'
 )tot_tab,
	
(select COUNT(*) as B 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE' AND
T0.TABLE_NAME  NOT IN (
SELECT TABLENAME FROM pg_indexes t1 
WHERE t1.schemaname NOT IN ('pg_catalog', 'information_schema')
	))Tablas_sin_IDX;
	*/
	
	
	
	
COPY (select tot_tab.A as Total_tablas_BD, Tablas_sin_PK.B as Tablas_Sin_Llave, ((Tablas_sin_PK.B * 100)/ tot_tab.A) AS Porcentaje_sin_Llaves, 'Llave Primaria' as Tipo
from 
(select COUNT(*) as A 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE'
 )tot_tab,
(select COUNT(*) as B 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE' AND
T0.TABLE_NAME  NOT IN (
SELECT TABLE_NAME FROM information_schema.table_constraints t1 
WHERE t1.table_schema NOT IN ('pg_catalog', 'information_schema') AND t1.constraint_type = 'PRIMARY KEY'))Tablas_sin_PK
	
union all

select tot_tab.A as Total_tablas_BD, Tablas_sin_FK.B as Tablas_Sin_Llave, ((Tablas_sin_FK.B * 100)/ tot_tab.A) AS Porcentaje_sin_Llaves, 'Llave Foranea' as Tipo
from 
(select COUNT(*) as A 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE'
 )tot_tab,
(select COUNT(*) as B 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE' AND
T0.TABLE_NAME  NOT IN (
SELECT TABLE_NAME FROM information_schema.table_constraints t1 
WHERE t1.table_schema NOT IN ('pg_catalog', 'information_schema') AND t1.constraint_type = 'FOREIGN KEY'))Tablas_sin_FK
	
union all

select tot_tab.A as Total_tablas_BD, Tablas_sin_IDX.B as Tablas_Sin_Llave, ((Tablas_sin_IDX.B * 100)/ tot_tab.A) AS Porcentaje_sin_Llaves, 'Indices' as Tipo
from 
(select COUNT(*) as A 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE'
 )tot_tab,
	
(select COUNT(*) as B 
from information_schema.tables t0
where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE' AND
T0.TABLE_NAME  NOT IN (
SELECT TABLENAME FROM pg_indexes t1 
WHERE t1.schemaname NOT IN ('pg_catalog', 'information_schema')
	))Tablas_sin_IDX) TO '/tmp/receta/7_Porcentaje_Llaves.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);
	
	
	
/*
	
 psql -c "select tot_tab.A as Total_tablas_BD, Tablas_sin_PK.B as Tablas_Sin_Llave, ((Tablas_sin_PK.B * 100)/ tot_tab.A) AS Porcentaje_sin_Llaves, 'Llave Primaria' as Tipo from  (select COUNT(*) as A from information_schema.tables t0 where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE'  )tot_tab,(select COUNT(*) as B from information_schema.tables t0 where t0.table_schema NOT IN ('pg_catalog','information_schema') and t0.table_type = 'BASE TABLE' AND T0.TABLE_NAME  NOT IN (SELECT TABLE_NAME FROM information_schema.table_constraints t1 WHERE t1.table_schema NOT IN ('pg_catalog','information_schema') AND t1.constraint_type = 'PRIMARY KEY'))Tablas_sin_PK union all select tot_tab.A as Total_tablas_BD, Tablas_sin_FK.B as Tablas_Sin_Llave, ((Tablas_sin_FK.B * 100)/ tot_tab.A) AS Porcentaje_sin_Llaves, 'Llave Foranea' as Tipo from  (select COUNT(*) as A from information_schema.tables t0 where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE'  )tot_tab, (select COUNT(*) as B from information_schema.tables t0 where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE' AND T0.TABLE_NAME  NOT IN ( SELECT TABLE_NAME FROM  information_schema.table_constraints t1 WHERE t1.table_schema NOT IN ('pg_catalog', 'information_schema') AND t1.constraint_type = 'FOREIGN KEY'))Tablas_sin_FK union all select tot_tab.A as Total_tablas_BD, Tablas_sin_IDX.B as Tablas_Sin_Llave, ((Tablas_sin_IDX.B * 100)/ tot_tab.A) AS Porcentaje_sin_Llaves, 'Indices' as Tipo from  (select COUNT(*) as A  from information_schema.tables t0 where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE'  )tot_tab, (select COUNT(*) as B from information_schema.tables t0 where t0.table_schema NOT IN ('pg_catalog', 'information_schema') and t0.table_type = 'BASE TABLE' AND T0.TABLE_NAME  NOT IN ( SELECT TABLENAME FROM pg_indexes t1  WHERE t1.schemaname NOT IN ('pg_catalog', 'information_schema') 	))Tablas_sin_IDX" | grep -v "+" | tr "|" "," > /tmp/receta/7_Porcentaje_Llaves.csv
	
	
*/