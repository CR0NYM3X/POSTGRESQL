/* 
		Consulta: BPD-Usuarios Roles
La ejecución muestra en listado de todos los usuarios que se encuentran a nivel instancia los permisos con los que cuenta,
consultando unicamente la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Nombre_Usuario
- Tipo_Rol
*/

SELECT u.usename AS Nombre_Usuario,
CASE WHEN u.usesuper AND u.usecreatedb THEN CAST('superuser; create
database' AS pg_catalog.text)
WHEN u.usesuper THEN CAST('superuser' AS pg_catalog.text)
WHEN u.usecreatedb THEN CAST('create database' AS pg_catalog.text)
ELSE CAST('' AS pg_catalog.text) END AS Tipo_Rol
FROM pg_catalog.pg_user u
ORDER BY 1;