/* 
		Consulta: BPD-Tamaño_Tablas
La ejecución muestra el listado de todas las tablas que se encuentran dentro de la Base de Datos, consultando unicamente 
la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Nombre_Esquema
- Nombre_Tabla
- Numero_Registros
- MB_Totales		

*/
/*
SELECT nspname AS Nombre_Esquema, relname AS Nombre_Tabla, c.reltuples AS Numero_Registros, CAST(pg_total_relation_size(c.oid) AS float)/1024/1024 AS MB_Totales
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE nspname = 'public' and relkind = 'r'

*/




COPY (SELECT nspname AS Nombre_Esquema, relname AS Nombre_Tabla, c.reltuples AS Numero_Registros, CAST(pg_total_relation_size(c.oid) AS float)/1024/1024 AS MB_Totales
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE nspname = 'public' and relkind = 'r') TO '/tmp/receta/6_TamanoTablas.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);


/*

 psql -c "SELECT nspname AS Nombre_Esquema, relname AS Nombre_Tabla, c.reltuples AS Numero_Registros, CAST(pg_total_relation_size(c.oid) AS float)/1024/1024 AS MB_Totales FROM pg_class c LEFT JOIN pg_namespace n ON n.oid = c.relnamespace WHERE nspname = 'public' and relkind = 'r'" | grep -v "+" | tr "|" "," > /tmp/receta/6_TamanoTablas.csv
 
 */