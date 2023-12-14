/* 
		Consulta: BPD-Roles
La ejecución muestra en listado de los roles en la base de datos asi como usuarios pertenecientes a dihoc roles, 
consultando unicamente la capa de información propia de ésta. 
La consulta extrae la siguiente informacion: 
- Nombre_Usuario
- Miembros_Rol				

*/

SELECT r.rolname, r.rolsuper, r.rolinherit,
   r.rolcreaterole, r.rolcreatedb, r.rolcanlogin,
   r.rolconnlimit,
   ARRAY(SELECT b.rolname
         FROM pg_catalog.pg_auth_members m
         JOIN pg_catalog.pg_roles b ON (m.roleid = b.oid)
         WHERE m.member = r.oid) as memberof
FROM pg_catalog.pg_roles r
ORDER BY 1;