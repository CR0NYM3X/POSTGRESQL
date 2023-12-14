/* 
		Consulta: BPD-Tamaño_BD
La ejecución muestra el listado de Bases de Datos que se encuentran dentro de la instancia, consultando unicamente 
la capa de información propia de ésta. La consulta extrae la siguiente informacion: 
- Nombre de la base de datos
- Tamaño (en megas)
- Fecha de creacion

*/

/*SELECT pg_database.datname as Nombre_BD, pg_size_pretty(pg_database_size(pg_database.datname)) AS Tamano_MB, 
(pg_stat_file('base/'||oid ||'/PG_VERSION')).modification as Fecha_Creacion
FROM pg_database*/




COPY (SELECT pg_database.datname as Nombre_BD, pg_size_pretty(pg_database_size(pg_database.datname)) AS Tamano_MB, 
(pg_stat_file('base/'||oid ||'/PG_VERSION')).modification as Fecha_Creacion
FROM pg_database) TO '/tmp/receta/3_TamanoBase.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);


/*  
 psql -c "SELECT pg_database.datname as Nombre_BD, pg_size_pretty(pg_database_size(pg_database.datname)) AS Tamano_MB,  (pg_stat_file('base/'||oid ||'/PG_VERSION')).modification as Fecha_Creacion FROM pg_database"  | grep -v "+" | tr "|" "," > /tmp/receta/3_TamanoBase.csv
 
 */