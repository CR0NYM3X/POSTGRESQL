# Objetivo:
Es aprender a crear usuarios, administrar y asignarle los permisos necesarios para el uso de la base de datos.

# Descripcion rápida de usuarios, Accesos y Permisos:
**1.** `Los usuarios` en una base de datos son entidades que permiten a las personas o aplicaciones acceder y trabajar con los datos almacenados en la base de datos. <br>
**2.** `El acceso` se refiere a la forma en que los usuarios y las aplicaciones se conectan y operan en la base de datos. <br>
**3.** `Los permisos` son reglas que determinan qué acciones pueden realizar los usuarios y los roles en la base de datos.

# Ejemplos de uso:

CRUD = Create, Read, Update, Delete


### Formas de Consultar o Buscar un usuario/role
 \du+ "testuserdba" <br>
 select * from pg_user		where usename ilike '%testuserdba%';<br>
 select * from pg_roles		where rolname ilike '%testuserdba%';<br>
 select * from pg_authid	where rolname ilike '%testuserdba%'; <br>
 select * from pg_shadow	where usename ilike '%testuserdba%';
 

### Crear un usuario:
CREATE USER "testuserdba"; <br>
CREATE USER "testuserdba" login VALID UNTIL  '2023-11-15'; --- fecha de expiracion <br>
CREATE USER testuserdba WITH PASSWORD '123456789';

### Comentar un usuario 
  COMMENT ON ROLE testuserdba IS 'Esta es la descripción del usuario.';
 
### Eliminar un usuario 
 drop user testuserdba;<br>
 drop role testuserdba;
 
 

### Cambiar passowrd
\password testuserdba<br>
ALTER USER "testuserdba" PASSWORD '12345'<br>
ALTER USER "testuserdba" PASSWORD 'md5a3cc0871123278d59269d85dbbd772893';  


### Cambiar la fecha de expiracion:
ALTER USER "testuserdba" WITH VALID UNTIL '2023-11-11';


### Agregar como owner a los objetos  
ALTER TABLE public.mitablanew OWNER TO testuserdba;<br>
ALTER DATABASE mydba  OWNER TO testuserdba;


### Ver privilegios de un usuario:

select grantee as usuario, table_catalog as DBA,string_agg(privilege_type, ' ') as privilegio  from information_schema.table_privileges  where grantee= 'testuserdba' group by  grantee,table_catalog  limit 10;


### Colocar super Usuario a un usuario/role
ALTER user  "sysutileria" WITH SUPERUSER; 
ALTER USER "sysutileria" WITH NOSUPERUSER;

### Asignar Permisos a objetos: [Funciones, Tablas, type, view, index, sequence, triggers]:



