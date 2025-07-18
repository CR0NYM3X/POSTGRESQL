
---
# Índice 


- [Buscar un usuario role](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#buscar-un-usuario-o-role)
- [Crear un usuario](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#crear-un-usuario)
- [Comentar un usuario](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#comentar-un-usuario)
- [Eliminar un usuario](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#eliminar-un-usuario)
- [Cambiar passowd  de usuario](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#cambiar-passowd)
- [Cambiar la fecha de expiracion](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#cambiar-la-fecha-de-expiracion-de-acceso)
- [Habilitar o Desabilitar un usuario para conectarse a la base de datos](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#habilitar-o-desabilitar-un-usuario-para-conectarse-a-la-base-de-datos)
- [Limitar el número de conexion por usuario](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#limitar-el-n%C3%BAmero-de-conexion-por-usuario)
- [Ver la cantidad y tipo de privilegios de un usuario](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#ver-la-cantidad-y-tipo-de--privilegios-de-un-usuario)
- [Asignar o Cambiar de owner en la base de datos y los objetos](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#asignar-o-cambiar-owner-en-la-base-de-datos-y-los-objetos)
- [Asignar o Remover SuperUser a un usuario](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#agregar-y-quitar-super-usuario-a-un-usuariorole)
- [Asignar Permisos lógicos SELECT, UPDATE, DELETE etc](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#asignar-permisos-l%C3%B3gicos-select-update-delete-etc)
- [Revokar o eliminar Permisos lógicos SELECT, UPDATE, DELETE etc](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#revokar-o-eliminar-permisos-a-objetos-funciones-tablas-type-view-index-sequence-triggers)
- [Asignar acceso por IP a la base de datos, nivel sistema operativo](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#asignar-acceso-por-ip-a-la-base-de-datos-nivel-sistema-operativo)
- [Ver si hay un error en el archivo pg_hba.conf](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#ver-si-hay-un-error-en-el-archivo-pg_hbaconf)
- [Ver todos los privilegios que se tienen en todas las base de datos](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#ver-todos-los-privilegios-que-se-tienen-en-todas-las-base-de-datos)
- [Asignar permisos de lectura en tablas versiones v8.1](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#asignar-permisos-de-lectura-en-tablas-versiones-v81)
- [Asignar permisos de execución en funciones psql v8.1](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#asignar-permisos-de-execuci%C3%B3n-en-funciones--psql--v81)
- [Asignar todos los permisos en las tablas en todas la bases de datos, versiones v9.0](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#asignar-todos-los-permisos-en-las-tablas-en-todas-la-bases-de-datos-versiones--v90)
- [Grupos lógicos en postgresql](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#grupos--l%C3%B3gicos--en-postgresql)

	- [Ver los grupos existentes](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#ver-los-grupos-existentes)
	- [Crear un grupo](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#crear-un-grupo)
	- [Agregar un usuario a un grupo](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#agregar--un-usuario-a-un-grupo)
	- [Eliminar un grupo](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#eliminar-un-grupo)
	- [Ver los miembros de un grupo específico](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#ver-los-miembros-de-un-grupo-espec%C3%ADfico)
	- [Ejemplos de grupos](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#ejemplos-de-grupos)

 - [ Reporte de usuarios con privilegio Elevados](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#reporte-de-usuarios-con-privilegio-elevados-en-servidor-postgresql)
---

# Objetivo:
Es aprender a crear usuarios, administrar y asignarle los permisos necesarios para el uso de la base de datos.


# Descripcion rápida de usuarios, Accesos y Permisos:
Es necesario aclarar que las querys pueden variar dependiendo la version de la db<br>
**1.** `Los usuarios` en una base de datos son entidades que permiten a las personas o aplicaciones acceder y trabajar con los datos almacenados en la base de datos. <br>
**2.** `El acceso` se refiere a la forma en que los usuarios y las aplicaciones se conectan y operan en la base de datos. <br>
**3.** `Los permisos` son reglas que determinan qué acciones pueden realizar los usuarios y los roles en la base de datos.

# Ejemplos de uso:

CRUD = Create, Read, Update, Delete


### Ver con que usuario estoy conectado a la base de datos 
```sql
--- id del proceso actual 
pg_backend_pid()

-- Vez el id de la transaccion 
SELECT txid_current();

SELECT proname, proowner, pg_get_userbyid(proowner) AS owner_name
FROM pg_proc;

/* ves que con que usuario iniciaste session */
SELECT session_user;

/* ves  que usuario estas usando actualmente en caso de usar un "SET ROLE" */
SELECT current_user;

/* Sirve para cambiar de usuario */
---  Permite al usuario ejecutar querys temporalmente con todos permisos nivel servidor como granulares de otro rol  (solo ocupas ser miembro del role)
 SET ROLE test_user;

-- regresarme al rol original; 
RESET ROLE; 

/* Cambiar de session  */
--> Permite al usuario cambiar temporalmente de usuario /identidad en la session  (solo los superusuarios)
SET SESSION AUTHORIZATION user_local; 

--- Regresar al usuario original (solo superusuario puede hacerlo)
RESET SESSION AUTHORIZATION ; 


----- conclusion ----
SET ROLE:
	Cambia el rol activo y los permisos, pero no la identidad de la sesión.
	Usado para cambiar temporalmente los permisos dentro de una sesión.

SET SESSION AUTHORIZATION:
	Cambia tanto la identidad como los permisos de la sesión.
	Requiere ser superusuario o el usuario original para cambiar de vuelta
```


### Cambiar la identidad de un usuario
te permite cambiar temporalmente la identidad de usuario durante una sesión de base de datos. 

```sql
ALTER ROLE test_pass SET SESSION AUTHORIZATION  postgres;

ALTER ROLE test_pass RESET SESSION AUTHORIZATION;

```



### Cambiarle el nombre al usuario postgres
Al realizar el cambio del nombre el usuario postgresql no afecta nada, pero por seguridad tienes que crear otro superuser, esto se desactiva ya que alguien puede hacer intento de login con ese usuario y saturar el servidor si no se tiene validado
,al realizar el cambio tambien todos los objetos que fueron creados por el usuario postgres se cambian al nuevo
```sql
/*******  Paso #1 CREAR UN USUARIO SUPERUSER ************\
create user sysadmin with superuser;

/*******  Paso #2 desactivar el login ************\
create user postgres with nologin;

/*******  Paso #2 RENOMBRAR EL USUARIO postgres ************\
ALTER USER postgres RENAME TO postgres_old;

```


###  Buscar un usuario o role
```sql
 \du+ "testuserdba"    -- descripción general

--- estas son vistas 
 select * from pg_user where usename ilike '%testuserdba%';  -- descripción general
 select * from pg_roles where rolname ilike '%testuserdba%';  -- Puedes ver el limite de conexiones por usuario en el campo: rolconnlimit

--- este es una tabla para los roles
 select * from pg_authid where rolname ilike '%testuserdba%';  -- Puedes ver el limite de conexiones por usuario  en el campo: rolconnlimit

** Cosas que debes de saber de pg_authid
1.- si creas un usuario, este usuario va aparecer en la tabla pg_authid, pero si creas un rol no va aparecer en la tabla pg_shadow,
 almenos que al rol le coloque el permiso de login, entonces si va aparecer en la tabla pg_shadow


--- Este es una tabla para los usuarios 
 select * from pg_shadow where usename ilike '%testuserdba%';  -- Aqui puedes ver el hash de la contraseña

**Columnas de pg_shadow:
 usecreatedb,  -- Permiso para crear bases de datos 
 usesuper,     -- Es super usuario tiene todos los permisos
 userepl,      -- Permisos para realizar tareas de replicación, como conectarse a una base de datos secundaria 
 usebypassrls, -- Se brinca la seguridad de las tablas | Row Level Security
 valuntil,     -- Vida util que tiene un usuario, como fecha de expiracion
 useconfig     -- Es donde se muestra si le asignan un rol al usuario


 ```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Crear un usuario:
[NOTA] Entre usuario pueden heredar sus permisos, es igual con los roles, ellos pueden heredar sus permisos con los usuario y otros roles, pero nunca podra un usuario heredar sus permisos 
a un role 

**Ejemplo de uso NOINHERIT** <br><br>
cuando esta en en true quiere decir que el usuario tiene la capacidad de heredar sus permisos , solo se puede heredar permisos nivel granulares no admin

test_role1 con permisos a la tabla clientes en la base de datos test_dba<br>
test_role2 con permiso a la tabla empleados en la base de datos test_dba <br>
test_user -- test_role2 hereda sus permisos al test_user<br><br>

Esto convierte al test_role2 en padre y el test_role1 en secundario 


si el role **"test_role2"** esta en `true` en la tabla `pg_roles` en la columan `rolinherit` esto quiere decir que el usuario **"test_user"** <br>
va tener permisos en las tablas clientes y  empleados  en la base de datos test_dba<br><br>

si el role **"test_role2"** esta en `true` en la tabla `pg_roles` en la columan `rolinherit`, esto quiere decir que el usuario **"test_user"** <br>
solo va tener permisos en la tabla empleados, que solo son los permisos del  **"test_role2"** ya que le estas quitando los permisos de los roles secundarios<br> 
y solo esta tomando los permisos del rol padre



```sql

CREATE USER "testuserdba"; -- crear un user
CREATE role "testuserdba";  -- crear un role  
CREATE USER "testuserdba" login VALID UNTIL  '2023-11-15'; --- fecha de expiracion  
CREATE USER testuserdba WITH PASSWORD '123456789'; -- no se recomienda colocar el password en con el create, por que en los log o el historial  puedes ver la contraseña

#Parametros para usar después de WITH
    SUPERUSER | NOSUPERUSER
    | CREATEDB | NOCREATEDB
    | CREATEROLE | NOCREATEROLE
    | INHERIT | NOINHERIT
    | LOGIN | NOLOGIN
    | REPLICATION | NOREPLICATION
    | BYPASSRLS | NOBYPASSRLS
    | CONNECTION LIMIT connlimit
    | [ ENCRYPTED ] PASSWORD 'password' | PASSWORD NULL
    | VALID UNTIL 'timestamp'
    | IN ROLE role_name [, ...]
    | IN GROUP role_name [, ...]
    | ROLE role_name [, ...]
    | ADMIN role_name [, ...]
    | USER role_name [, ...]
    | SYSID uid

```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Comentar un usuario 
```sql
  COMMENT ON ROLE testuserdba IS 'Esta es la descripción del usuario.';
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)
 
### Eliminar un usuario 
```sql
 drop user testuserdba;
 drop role testuserdba;
 ```

 

<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Cambiar passowd
```sql
\password testuserdba 
ALTER USER "testuserdba" PASSWORD '12345'
ALTER USER "testuserdba" PASSWORD 'md5a3cc0871123278d59269d85dbbd772893';  
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Cambiar la fecha de expiracion de acceso:
```sql
ALTER USER "testuserdba" WITH VALID UNTIL '2023-11-11';
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)


### Habilitar o Desabilitar un usuario para conectarse a la base de datos 
**`LOGIN`**  Habilita al usuario para iniciar sesión en el sistema de base de datos <br>
**`NOLOGIN`** significa que este rol de usuario no puede iniciar sesión en el sistema de base de datos. En otras palabras, no se permite que este usuario se autentique en PostgreSQL y realice conexiones.
```sql
  ALTER ROLE "my_user" NOLOGIN;

  ALTER ROLE "my_user" LOGIN;
```
  <br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)
  

### Limitar el número de conexion por usuario:
```sql
ALTER USER testuserdba WITH CONNECTION LIMIT 2;
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Ver la cantidad y tipo de  privilegios de un usuario:
**`grantor:`** Esta columna indica el rol (usuario o grupo de roles) que otorga los permisos.

**`grantee:`** Esta columna indica el rol (usuario o grupo de roles) que recibe los permisos.


```sql
# saber los privilegios granulaers de las tablas en una sola base de datos : 

select  current_database(),'' as usuario,'Cnt_total_tablas' as privilege_type,count(*) as Total_Privilege
  from  information_schema.tables
WHERE table_schema='public' 
union all 
select  current_database(),grantee,privilege_type,count(*)
  from information_schema.table_privileges
where  table_schema= 'public' and grantee in('MYUSUARIO') group by grantee, privilege_type;


# # saber los privilegios granulaers de las tablas  en todas las base de datos :
psql -tAc "select '\c ' || datname || CHR(10) || 'select  current_database(), table_schema as Esquema,'''' as usuario,''Cnt_total_tablas'' as privilege_type,count(*) as Total_Privilege
  from  information_schema.tables
WHERE  not table_schema  in(''pg_catalog'', ''information_schema'') group by table_schema
union all 
select  current_database(),table_schema,grantee,privilege_type,count(*)
  from information_schema.table_privileges
where not table_schema in(''pg_catalog'', ''information_schema'') and grantee in(''my_usert_test'') group by grantee, privilege_type,table_schema; ' from pg_database where not datname in('postgres','template1','template0')" | sed -e 's/+//g' | psql

# Para Funciones y Procedimientos Almacenados :
# Para Triggers
# Para Schemas:
# Para Sequences.:
# Para Type:
# Para view:
# Para index:

# Tambien se puede usar la siguiente tabla y vistas 
SELECT grantee,table_schema,table_name,privilege_type FROM information_schema.role_table_grants WHERE grantee='my_user';
SELECT grantee,table_schema,table_name,privilege_type FROM information_schema.table_privileges where grantee = ''
SELECT * FROM information_schema.usage_privileges where not grantee in('PUBLIC','postgres') and grantee = ''; -- PERMISOS USAGE


# ver Permisos
\df *privilege
SELECT  has_schema_privilege('user_Test', 'public', 'CREATE') AS tiene_permiso; -- para esquemas 
SELECT has_sequence_privilege('tipo_personal', 'select'); --  para secuencias 
SELECT has_type_privilege('tipo_personal', 'select'); --  para los permisos granulares


postgres@postgres# select distinct  proname from pg_proc where proname  ilike 'has\_%' order by  proname ;
+------------------------------------+
|              proname               |
+------------------------------------+
| has_any_column_privilege           |
| has_column_privilege               |
| has_database_privilege             |
| has_foreign_data_wrapper_privilege |
| has_function_privilege             |
| has_language_privilege             |
| has_parameter_privilege            |
| has_schema_privilege               |
| has_sequence_privilege             |
| has_server_privilege               |
| has_table_privilege                |
| has_tablespace_privilege           |
| has_type_privilege                 |
+------------------------------------+


# Permisos de esquemas
SELECT r.rolname AS grantor,
             e.rolname AS grantee,
             nspname,
             privilege_type,
             is_grantable -- esto te dice si el usuario le coloco la opcion " WITH GRANT OPTION;" al otorgar el permiso
        FROM pg_namespace
JOIN LATERAL (SELECT *
                FROM aclexplode(nspacl) AS x) a
          ON true
        JOIN pg_authid e
          ON a.grantee = e.oid
        JOIN pg_authid r
          ON a.grantor = r.oid 
       WHERE   not nspname ilike 'pg_%'   and e.rolname != 'postgres' /*and privilege_type = 'CREATE' */ ;

 ---- VERSIONES  < 9   |     UC= USAGE, CREATE
    select * from  (select nspname as schema,  unnest(nspacl)::text as user_ FROM pg_namespace WHERE
 not nspname ilike 'pg_%'  and nspname  != 'information_schema' ) as a where user_ ilike '%sysbiblioteca=%';


# Permisos de base de datos
select r.rolname AS grantor,e.rolname AS grantee,datname,privilege_type,is_grantable from pg_database 
JOIN LATERAL (SELECT *
                FROM aclexplode(datacl) AS x) a
     ON true
         JOIN pg_authid e
          ON a.grantee = e.oid
        JOIN pg_authid r
          ON a.grantor = r.oid  
where  e.rolname != 'postgres'  /* and privilege_type in( 'TEMPORARY','CREATE') */ ;

 ---- VERSIONES  < 9  | CTc = CREATE, TEMPORARY , CONNECT 
	select * from (select datname,unnest(datacl)::text as user_ from pg_database)as a where user_ ilike '%MY_USER=%';




 # permisos TABLES:
	COPY ( select grantee,table_schema,table_name,privilege_type , Descripcion_Tipo_Objeto from    information_schema.table_privileges as a
	left join ( select  relname,case cls.relkind when 'r' then 'TABLE'
	when 'm' then 'MATERIALIZED_VIEW'
	when 'i' then 'INDEX'
	when 'S' then 'SEQUENCE'
	when 'v' then 'VIEW'
	when 'c' then 'TYPE'
	else cls.relkind::text end as Descripcion_Tipo_Objeto
	from pg_class as cls ) as b  on b.relname = a.table_name  
	 where not grantee in('PUBLIC','postgres') and grantee  IN('MY_USER')  ORDER BY grantee,table_name ) TO '/tmp/TBL_PERMISOS.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);

#  permisos SEQUENCES:
 SELECT relname, relacl
	FROM pg_class
	WHERE relkind = 'S'
	  AND relacl is not null
	  AND relnamespace IN (
		  SELECT oid
		  FROM pg_namespace
		  WHERE nspname NOT LIKE 'pg_%' AND nspname != 'information_schema'
	);

 ---- VERSIONES  < 9  | rwU= SELECT,UPDATE,USAGE
	select * from  (SELECT relname  as Secuencias,  unnest(relacl)::text as user_  FROM pg_class WHERE relkind = 'S'
	AND relacl is not null  AND relnamespace IN ( SELECT oid FROM pg_namespace WHERE nspname NOT LIKE 'pg_%'
	AND nspname != 'information_schema') ) as a where user_ ilike '%sysgenexus=%';

#  permisos View
    SELECT relname, relacl
	FROM pg_class
	WHERE relkind = 'v' and relacl::text ilike '%MY_USER%';


#  permiso FUNCTIONS: 
		  	COPY ( SELECT  a.routine_schema ,grantee, a.routine_name , b.routine_type, privilege_type FROM information_schema.routine_privileges as a
	left join information_schema.routines  as b on a.routine_name=b.routine_name
	where not a.grantee in('PUBLIC','postgres') and grantee in('MY_USER') ORDER BY grantee ) TO '/tmp/fun_PERMISOS.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);

 
#  permiso Type: 
	select typname,typacl,nsp.nspname esquema from pg_type as pgt  left JOIN pg_namespace nsp ON pgt.typnamespace = nsp.oid  where typacl::text ilike '%,usuario_empleado=%' limit 1;
	
	SELECT relname, relacl 	FROM pg_class WHERE relkind = 'c' and relname= 'vista_empleados';


 # trigger: ---  select trigger_name, 'TRIGGER' as type_object  ,trigger_schema, null as user_name ,null as privilege_type FROM information_schema.triggers group by trigger_schema,trigger_name

 # Index: --- este tampoco se puede


 ###################  PERMISOS LVL SERV ################### 
select CASE WHEN usename!= '' THEN 'USER' ELSE 'ROLE' END as TYPE_USER ,rolname
,rolsuper_,rolinherit_,rolcreaterole_,rolcreatedb_,rolcanlogin_,rolreplication_ 
-- ,rolbypassrls_
-- ,rolcatupdate_
from 
(select rolname,
CASE WHEN rolsuper='t' THEN 1 ELSE 0 END as rolsuper_,
CASE WHEN rolinherit='t' THEN 1 ELSE 0 END as rolinherit_,
CASE WHEN rolcreaterole='t' THEN 1 ELSE 0 END as rolcreaterole_,
CASE WHEN rolcreatedb='t' THEN 1 ELSE 0 END as rolcreatedb_,
CASE WHEN rolcanlogin='t' THEN 1 ELSE 0 END as rolcanlogin_,
CASE WHEN rolreplication='t' THEN 1 ELSE 0 END as rolreplication_
-- ,CASE WHEN rolcatupdate='t' THEN 1 ELSE 0 END as rolcatupdate_
-- ,CASE WHEN rolbypassrls='t' THEN 1 ELSE 0 END as rolbypassrls_

 from pg_authid where not rolname in('postgres','pg_signal_backend') and not rolname ilike '%pg_%')a left join pg_shadow on usename=rolname 
 where  rolname in('My_user' ) /*AND (rolsuper_ != 0 or rolcreaterole_ != 0 or rolcreatedb_ != 0 or rolreplication_ != 0 or rolbypassrls_ != 0) */  ;

```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)



### Asignar o cambiar owner en la base de datos y los objetos  

> [!WARNING]
> **DROP OWNED BY myusertest;**  Este elimina todos objetos al que el usuario era owner 

> [!IMPORTANT]
> Cuando un usuario/role crea un objeto, automáticamente se coloca ese usuario como owner en el objeto, almenos que lo cambie
> Al ser owner de un objeto esto te da la libertar de hacer lo que quieras con ese objeto incluso borrarlo

```sql
--- Este elimina los objetos del usuario 
DROP OWNED BY myusertest;

#Esta consulta se utiliza para cambiar el propietario de todos los objetos dentro de una base de datos específica al nuevo propietario:
REASSIGN OWNED BY "my_user_old_owner" to "my_user_new_owner";  

#Cambiar el Propietario de una Base de Datos:
alter DATABASE nombre_de_basedatos OWNER TO nuevo_propietario;
 
#Cambiar el Propietario de una Tabla:
ALTER TABLE nombre_de_tabla OWNER TO nuevo_propietario;
 
#Cambiar el Propietario de una Función:
ALTER FUNCTION nombre_de_funcion(argumentos) OWNER TO nuevo_propietario;

#Cambiar el Propietario de un Trigger:
ALTER TABLE nombre_de_tabla OWNER TO nuevo_propietario;

# Cambiar el Propietario de un Tipo (Type):
ALTER TYPE nombre_de_tipo OWNER TO nuevo_propietario;

#. Cambiar el Propietario de una Vista:
ALTER VIEW nombre_de_vista OWNER TO nuevo_propietario;

#Cambiar el Propietario de una Secuencia (Sequence):
ALTER SEQUENCE nombre_de_secuencia OWNED BY nuevo_propietario;

#Cambiar el Propietario de un Esquema (Schema):
ALTER SCHEMA nombre_de_esquema OWNER TO nuevo_propietario;



```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

# Saber todos los owner 

```SQL

SELECT NAME,rolname AS OWNER,Descripcion_Tipo_Objeto FROM  
(
/* OWNER DE OBJETOS */
select a.relname AS NAME, a.relowner AS OWNER,
case a.relkind when 'r' then 'TABLE'
when 'm' then 'MATERIALIZED_VIEW'
when 'i' then 'INDEX'
when 'S' then 'SEQUENCE'
when 'v' then 'VIEW'
when 'c' then 'TYPE'
else a.relkind::text end as Descripcion_Tipo_Objeto from pg_class as a
WHERE relnamespace in(SELECT oid FROM pg_namespace where not nspname in('pg_catalog','information_schema','pg_toast'))
UNION ALL 
/*OWNER DE FUNCIONES */
SELECT proname, proowner, 'FUNCTION' FROM pg_proc WHERE pronamespace in(SELECT oid FROM pg_namespace where not nspname in('pg_catalog','information_schema','pg_toast'))

union all 
/*OWNER DE BASE DE DATOS */ 
 SELECT datname,datdba, 'DATABASE'   FROM pg_database 
 
union all
/* OWNER DE LOS SCHEMAS */
SELECT nspname,nspowner, 'SCHEMA' FROM pg_namespace where not nspname in('pg_catalog','information_schema','pg_toast') 
 
) AS A  left join pg_authid as b on  OWNER = b.oid  
WHERE  NOT b.oid  in(select oid from pg_authid where rolname = 'postgres');


/*OPCION #2 | https://www.red-gate.com/simple-talk/homepage/postgresql-basics-object-ownership-and-default-privileges/*/
SELECT n.nspname as "Schema",
  c.relname as "Name",
  CASE c.relkind 
  	WHEN 'r' THEN 'table' 
  	WHEN 'v' THEN 'view' 
  	WHEN 'm' THEN 'materialized view' 
  	WHEN 'i' THEN 'index' 
  	WHEN 'S' THEN 'sequence' 
  	WHEN 't' THEN 'TOAST table' 
  	WHEN 'f' THEN 'foreign table' 
  	WHEN 'p' THEN 'partitioned table' 
  	WHEN 'I' THEN 'partitioned index' END as "Type",
  pg_catalog.pg_get_userbyid(c.relowner) as "Owner"
FROM pg_catalog.pg_class c
     LEFT JOIN pg_catalog.pg_namespace n 
         ON n.oid = c.relnamespace
     LEFT JOIN pg_catalog.pg_am am 
         ON am.oid = c.relam
WHERE c.relkind IN ('r','p','v','m','S','f','')
      AND n.nspname <> 'pg_catalog'
      AND n.nspname !~ '^pg_toast'
      AND n.nspname <> 'information_schema'
  AND pg_catalog.pg_table_is_visible(c.oid)
ORDER BY 1,2;



```




### Agregar y Quitar super Usuario a un usuario/role
```sql
ALTER user  "sysutileria" WITH SUPERUSER; 
ALTER USER "sysutileria" WITH NOSUPERUSER;
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)


### Ejecutar los permisos en todas las base de datos 
psql -tAc "select '\c ' || datname ||  CHR(10) || '**GRANT SELECT  ON ALL TABLES IN SCHEMA public TO \\"myuser\\";**' from pg_database where not datname in('postgres','template1','template0')"  | sed -e 's/\+//g' | psql 

### Asignar Permisos lógicos SELECT, UPDATE, DELETE etc:
*El privilegio **`USAGE`** solo sirve para Secuencias, Esquemas  y Funciones,  el privilegio USAGE no permite modificar, solo para consultar las estructuras de los objetos*

**WITH GRANT OPTION** Si usas esto al final de cada grant, esto lo que le estas diciendo es que quieres que tenga el permiso de otorgar ese permiso a otros usuarios  usando *grant* 
https://www.postgresql.org/docs/current/ddl-priv.html#PRIVILEGE-ABBREVS-TABLE
```SQL
# DEFAULT:
/* otorgará automáticamente el derecho de SELECT en todas las tablas futuras creadas en el esquema "mi_esquema" al usuario "mi_usuario",
tu puedes decidir que permiso se otrogará mofidicando el grant  */
ALTER DEFAULT PRIVILEGES IN SCHEMA mi_esquema GRANT SELECT ON TABLES TO mi_usuario;

# VER LOS DEFAULT 
	SELECT
	    nsp.nspname AS schema,
	    CASE defacl.defaclobjtype
	        WHEN 'r' THEN 'Tabla'
	        WHEN 'S' THEN 'Secuencia'
	        WHEN 'f' THEN 'Función'
	        ELSE 'Otro'
	    END AS "Tipo de object",
		r.rolname AS grantor,
		e.rolname AS grantee,
	    acl.privilege_type AS privilege
	FROM
	    pg_default_acl defacl
	JOIN LATERAL (SELECT *
	FROM aclexplode(defacl.defaclacl) AS x) as   acl
	  ON true
	JOIN pg_authid e
	  ON acl.grantee = e.oid
	JOIN pg_authid r
	  ON acl.grantor = r.oid 
	JOIN
	    pg_namespace nsp ON defacl.defaclnamespace = nsp.oid;

# DATABASE: [Nota] - el create te permite crear indices, y crear los objetoso solo de ese indice
  GRANT CONNECT,CREATE, TEMPORARY ON DATABASE "tu_base_de_datos" TO "testuserdba";
  grant all privileges on database tu_bd to tu_usuario;

# TABLES:
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "testuserdba";
  grant SELECT, UPDATE, DELETE, INSERT, REFERENCES, TRIGGER, TRUNCATE, RULE on all tables in schema public to "testuserdba";
  GRANT REFERENCES ON tabla_referenciada TO usuario_o_rol; -- sirve  crear claves foráneas que hacen referencia a una tabla
  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA CLINICA TO dba WITH GRANT OPTION;  -- este se usa si quieres que el rol quiere heredar con grant
 GRANT TRIGGER ON  TABLE empleados  TO usuario_empleado;

# SEQUENCES:
GRANT select ON table my_seuencia_test TO my_user_test; -- versiones 8.0
  GRANT USAGE, SELECT,UPDATE ON SEQUENCE mi_secuencia TO testuserdba;
GRANT ALL PRIVILEGES ON ALL sequences IN SCHEMA public TO "testuserdba";

# SCHEMA:  [Nota] - el create te permite crear objetos dentro de un schema
  GRANT CREATE ON SCHEMA public TO mi_rol; ---  permite al usuario crear y modificar objetos en el esquema público
  GRANT USAGE ON SCHEMA public TO testuserdba; - otorga permisos para ver la estructura de los objetos de un esquea
  GRANT ALL PRIVILEGES ON SCHEMA mi_esquema TO mi_usuario; -- te da el permiso usage y create 

# FUNCTIONS  :
  grant ALL PRIVILEGES  on all functions in schema public to "testuserdba";
  grant execute on all functions in schema public to "testuserdba";
  GRANT EXECUTE ON FUNCTION public.fun_obtenercontactoscopiaweb(int, varchar) TO "testuserdba";

# PROCEDURE:
  GRANT EXECUTE ON PROCEDURE  mi_procedure() TO usuario_empleado;

# trigger:
  -- SE LES DA PERMISOS DE FUNCIONES YA QUE EL TRIGGER EJECUTA FUNCIONES

# Index:
  --- PARA LOS INDEX NO SE DA PERMISOS 

# Type:
  GRANT USAGE ON TYPE mi_tipo_de_dato TO mi_usuario;

# View:
  GRANT SELECT ON mi_vista TO mi_usuario;
```


# Roles del sistema postgresql predefinidos 
Estos son roles predifinidos que se pueden asignar a un usuario en caso de ocuparlos
Documentación oficial [22.5. Predefined Roles
](https://www.postgresql.org/files/documentation/pdf/15/postgresql-15-A4.pdf)

**pg_read_all_data** Leer todos los datos (tablas, vistas, secuencias), como si tuviera SELECT derechos sobre esos objetos <br>
**pg_write_all_data**  Escriba todos los datos (tablas, vistas, secuencias), como si tuviera INSERT,ACTUALIZAR y ELIMINAR derechos sobre esos objeto <br>
**pg_read_all_settings** Leer todas las variables de configuración, incluso aquellas que normalmente solo son visibles a los superusuarios.  <br>
**pg_read_all_stats**  Lea todas las vistas de pg_stat_* y utilice varias extensiones relacionadas con estadísticas, incluso aquellas que normalmente son visibles solo para superusuarios. <br>
**pg_stat_scan_tables**  Ejecutar funciones de monitoreo que puedan tomar ACCESS SHARE <br>
**pg_monitor**  Leer/ejecutar varias vistas y funciones de monitoreo. este papel
es miembro de pg_read_all_settings, pg_read_all_stats y pg_stat_scan_tables <br>
**pg_database_owner**   None. Membership consists, implicitly, of the current database owner. <br>
**pg_signal_backend** Señalar a otro servidor para que cancele una consulta o finalice su sesión.  <br>
**pg_read_server_files** Permitir la lectura de archivos desde cualquier ubicación a la que pueda acceder la base de datos
el servidor con COPIA y otras funciones de acceso a archivos  <br>
**pg_write_server_files**  Permitir escribir en archivos en cualquier ubicación a la que pueda acceder la base de datos
el servidor con COPIA y otras funciones de acceso a archivos <br>
**pg_execute_server_program** Permitir la ejecución de programas en el servidor de base de datos como usuario
La base de datos se ejecuta como con COPY y otras funciones que permiten ejecutar un programa del lado del servidor.  <br>
**pg_checkpoint** Permitir ejecutar el comando CHECKPOINT.


<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Revokar o eliminar Permisos a objetos: [Funciones, Tablas, type, view, index, sequence, triggers]:  


```sql
Remove Owner Database
REVOKE OWNERSHIP ON DATABASE 'mydbatest' FROM "testuserdba";

# DEFAULT:
   ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM "jose_test";

# DATABASE:
	REVOKE ALL PRIVILEGES ON DATABASE mytestdba FROM "jose_test";

# TABLES:
  	REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "testuserdba";
  	REVOKE ALL PRIVILEGES ON TABLE nombre_de_tabla FROM nombre_del_rol;
  	REVOKE ALL ON TABLE my_tabla FROM PUBLIC; --- para versiones 8
  	REVOKE ALL ON TABLE my_tabla FROM postgres; --- para versiones 8

# SEQUENCES:
  	REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM "testuserdba";
  	REVOKE ALL PRIVILEGES ON SEQUENCE nombre_de_secuencia FROM nombre_del_rol;

# SCHEMA :
	REVOKE ALL PRIVILEGES ON SCHEMA nombre_del_esquema FROM nombre_del_rol;
  

# FUNCTIONS:
	revoke execute on all functions in schema public from testuserdba;
	REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM "testuserdba";
	REVOKE ALL PRIVILEGES ON FUNCTION nombre_de_funcion(int, varchar) FROM nombre_del_rol;

# Index:
	-- NO TINE PARA QUITAR PERMISOS PORQUE A LOS INDEX NO SE OTORGA PERMISOS 

# Type:
	REVOKE ALL PRIVILEGES ON TYPE nombre_del_tipo FROM nombre_del_rol;

# View:
	REVOKE ALL PRIVILEGES ON VIEW nombre_de_vista FROM nombre_del_rol;

# trigger:
	-- SE QUITA EL PERMISO PERO DE LA FUNCION QUE USA EL TRIGGER

```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Asignar acceso por IP a la base de datos, nivel sistema operativo:
`pg_hba.conf` Este archivo se utiliza para definir las políticas de autenticación y controlar quién puede conectarse a la base de datos, desde dónde pueden conectarse y qué métodos de autenticación deben utilizarse para la conexión. <br>

| TYPE | DATABASE |USER | ADDRESS | METHOD | 
|--------------|--------------|--------------|--------------|--------------|
| host    | mydbatest    | myusertest    | 192.168.1.0/32    | md5   |
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Ver si hay un error en el archivo pg_hba.conf
```sql
select * from pg_hba_file_rules where error is not null; ---- si no muestra registros, todo esta bien, si muestra registros en el campo "line_number" te dira la linea que presenta el error
select * from pg_hba_file_rules  where address  in('10.0.30.5');
select * from pg_hba_file_rules  where user_name in('{testuserdba}');
select * from pg_hba_file_rules  where  database   in('{testuserdba}');
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)




## Ver todos los privilegios que se tienen en todas las base de datos:
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)


### Asignar permisos de lectura en tablas versiones v8.1 
- `Opción #1`<br>
psql codigos -t -c "SELECT 'grant select on table ' || table_name || ' to ' || CHR(34) || '90092916' || CHR(34) || ';' as qweads FROM information_schema.tables WHERE table_schema='public' order by table_name;" |  psql codigos  

- `Opción #2`<br>
psql   **`mydba`** -t   -c "\dt" | grep -v '-' | grep -v 'rela' | grep -v 'Name' | awk '{print " SELECT ON TABLE "$3 " FROM **`myusertest`**;" }' > /tmp/usuarios.sql && psql snisef < /tmp/usuarios.sql
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Asignar permisos de execución en funciones  psql  v8.1 
 psql **my_dba_test** -tA -c "SELECT 'GRANT EXECUTE ON FUNCTION '|| proname || '(' || pg_catalog.oidvectortypes(proargtypes) || ')' || ' to ' || CHR(34) || '**myuser_test**' || CHR(34) || ';' as qweads FROM pg_proc where proname in(SELECT routine_name FROM information_schema.routines WHERE routine_type = 'FUNCTION' AND specific_schema = 'public') " | psql **my_dba_test**
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

###  Asignar todos los permisos en las tablas en todas la bases de datos, versiones  v9.0
select	'\\c ' || datname || ';' || CHR(10) || 'grant select on all tables in schema public to **`"myusertest"`**;'
|| CHR(10) || 'GRANT CONNECT ON DATABASE "'|| datname ||'" TO  **`"myusertest"`**;'  as qweads from pg_database where not datname ilike 'template%' and not datname ilike 'postgres';
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)


---


# Grupos  lógicos  en postgresql: 
son conjuntos lógicos de roles de usuarios que se utilizan para simplificar la administración de permisos y la gestión de roles en una base de datos. <br> Los grupos permiten asignar permisos a un conjunto de usuarios de una manera más eficiente, en lugar de otorgar permisos individuales a cada usuario.

**Permisos que No Puedes Heredar**
```
Privilegios Superuser:
	No puedes heredar el permiso de superusuario (SUPERUSER). Esto debe ser asignado explícitamente por un administrador y confiere permisos completos sobre la base de datos, lo cual puede ser riesgoso.

Roles Inherentes de Administrador:
	Privilegios específicos del sistema como CREATEROLE (permiso para crear nuevos roles) y CREATEDB (permiso para crear nuevas bases de datos) no se heredan automáticamente y deben ser concedidos explícitamente
```

# Crear un usuario y asignarlo a un grupo 
 ```sql
 CREATE USER nuevo_usuario4 WITH PASSWORD 'tu_contraseña' USER admin_role, read_only;
 CREATE USER nuevo_usuario5 WITH PASSWORD 'tu_password' IN GROUP  admin_role, read_only;
 CREATE USER nuevo_usuario9 WITH PASSWORD 'tu_password' IN ROLE admin_role, read_only;
```

### Ver los grupos existentes:
```sql
SELECT * FROM pg_group;
```

### Crear un grupo
```sql
CREATE GROUP mi_grupo;
```
    


### Asignarle un rol o grupo  a un usuario
Este es un ejemplo de un rol para crear tablas;
```SQL
CREATE ROLE tabla_creator;
GRANT CREATE ON SCHEMA public TO tabla_creator;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO tabla_creator;
 

-- Agregar al usuario al grupo 
GRANT tabla_creator TO my_usuario2;

grant test_role to USER_TEST WITH ADMIN OPTION; --- ES COMO EL WITH GRANT OPTION, LE CONCEDE AL USUARIO TAMBIEN OTORGAR ESTE PERMISO A OTROS USUARIOS
 
 
```
  
### Eliminar un grupo 
```sql
  DROP GROUP mi_grupo;
``` 
 
### Ver los miembros de un grupo específico:
La tabla pg_auth_members sirve para mostrar si un usuario esta en un grupo o rol
```sql
select  roleid::regrole AS group_name, member::regrole AS member_name,grantor::regrole   FROM pg_auth_members WHERE roleid = 'mi_grupo';

select usename, rolname from pg_user join pg_auth_members on (pg_user.usesysid=pg_auth_members.member) 
join pg_roles on (pg_roles.oid=pg_auth_members.roleid) 
```



### retirarle los permisos a un usuario de un grupo o role
```
--- Si no funciona esta opcion utilizas la otra query
REVOKE role_a, role_b FROM my_user;

delete from  pg_auth_members where member= 33303009 /*pg_user.usesysid*/ and roleid=33445429 /*pg_roles.oid*/;
```


### Ejemplos de grupos 
```sql
#Asignación de permisos: Imagina que tienes una base de datos con múltiples tablas y deseas dar a un conjunto de usuarios
#los mismos permisos en varias tablas. En lugar de otorgar permisos a cada usuario individualmente, puedes crear un grupo
# y asignar permisos al grupo. Luego, simplemente agregas a los usuarios al grupo y heredarán los permisos del grupo.

-- Crear un grupo y otorgar permisos
CREATE GROUP grupo_ventas;
GRANT SELECT, INSERT, UPDATE ON tabla_ventas TO grupo_ventas;

-- Agregar usuarios al grupo
ALTER ROLE usuario1 IN GROUP grupo_ventas;
ALTER ROLE usuario2 IN GROUP grupo_ventas;


#Control de acceso: Los grupos también se pueden utilizar para controlar el acceso a ciertos recursos de la base de datos.
# Por ejemplo, puedes restringir el acceso a una aplicación específica a través de un grupo y luego agregar o eliminar
#usuarios de ese grupo según sea necesario.


-- Crear un grupo para la aplicación de informes
CREATE GROUP app_informes;

-- Otorgar permisos de acceso a la aplicación al grupo
GRANT CONNECT ON DATABASE mydb TO app_informes;

-- Agregar o quitar usuarios de la aplicación del grupo según sea necesario
ALTER ROLE usuario1 IN GROUP app_informes;

``` 

# Info Extra

### Reporte de usuarios con privilegio Elevados en servidor postgresql
Esta query se ejecuta en la terminal de linux y realiza 3 archivos usando como delimitador el tabulador, Files:  **"/tmp/info_server.csv" , "/tmp/privilege_server.csv" y "/tmp/grant.csv"**<br>
**`[Nota]`** En caso de que no  se pegue completo en la terminal de linux , tienes que quitar los comentarios que estan con #

**`[Nota]`**  en las versiones 8 de psql, los campos: **rolreplication, rolbypassrls** se colocó por defaul en 0 ya que en esta  version, estos campos no existen y en la version > 9 el campo  **rolcatupdate** también se colocó por defaul 0, ya que ese campo no existe 

```
#   saber si un usuario esta en un grupo 
psql -c "select usename, rolname from pg_user join pg_auth_members on (pg_user.usesysid=pg_auth_members.member) join pg_roles on (pg_roles.oid=pg_auth_members.roleid) ;" &&  echo " info server" &&

# Header: IP	Hostname	Version PSQL	Cantidad DBA
echo -e "IP\tHostname\tVersion PSQL\tCantidad DBA" >  /tmp/info_server.csv   && echo -e "$(if result0000001=$(hostname -I 2>/dev/null); then echo $(hostname -I | awk '{print  $1}'); else echo $(hostname -i | awk '{print  $1}'); fi)\t$(hostname)\t$(psql -V)\t$(psql -tc "select  count(*) from pg_database where not datname in('postgres','template1','template0');")" >> /tmp/info_server.csv && echo "" && cat /tmp/info_server.csv && 

# Header: IP SERVER	TYPE_USER	User	rolsuper	rolinherit	rolcreaterole	rolcreatedb	rolcanlogin	rolreplication	rolbypassrls	rolcatupdate
  echo $(if [[ -z $(psql -tc "select column_name  from information_schema.columns where table_name = 'pg_authid' and column_name='rolbypassrls'") ]]; then   echo   $(psql -c "CREATE TEMP TABLE tabla_temporal2  as  select * from  (select * from (select CASE WHEN usename!= '' THEN 'USER' ELSE 'ROLE' END as TYPE_USER ,rolname ,rolsuper_,rolinherit_,rolcreaterole_,rolcreatedb_,rolcanlogin_,0 as rolreplication,0 as rolbypassrls,rolcatupdate from  (select rolname, CASE WHEN rolsuper='t' THEN 1 ELSE 0 END as rolsuper_, CASE WHEN rolinherit='t' THEN 1 ELSE 0 END as rolinherit_, CASE WHEN rolcreaterole='t' THEN 1 ELSE 0 END as rolcreaterole_, CASE WHEN rolcreatedb='t' THEN 1 ELSE 0 END as rolcreatedb_, CASE WHEN rolcanlogin='t' THEN 1 ELSE 0 END as rolcanlogin_, CASE WHEN rolcatupdate='t' THEN 1 ELSE 0 END as rolcatupdate  from pg_authid where not rolname in('postgres','pg_signal_backend') and not rolname ilike '%pg_%')a left join pg_shadow on usename=rolname  where  (rolsuper_ != 0 or rolcreaterole_ != 0 or rolcreatedb_ != 0 or rolcatupdate != 0) )a order by TYPE_USER)a ; copy tabla_temporal2 to '/tmp/privilege_server.csv' WITH  CSV DELIMITER '|';" && sed -i 's/|/\t/g' /tmp/privilege_server.csv &&  sed -i "s/^/$(if result0000001=$(hostname -I 2>/dev/null); then echo $(hostname -I | awk '{print  $1}'); else echo $(hostname -i | awk '{print  $1}'); fi)\t/" /tmp/privilege_server.csv);   else    echo $(psql -c "copy (select CASE WHEN usename!= '' THEN 'USER' ELSE 'ROLE' END as TYPE_USER ,rolname ,rolsuper_,rolinherit_,rolcreaterole_,rolcreatedb_,rolcanlogin_,rolreplication_,rolbypassrls_,0 as rolcatupdate from  (select rolname, CASE WHEN rolsuper='t' THEN 1 ELSE 0 END as rolsuper_, CASE WHEN rolinherit='t' THEN 1 ELSE 0 END as rolinherit_, CASE WHEN rolcreaterole='t' THEN 1 ELSE 0 END as rolcreaterole_, CASE WHEN rolcreatedb='t' THEN 1 ELSE 0 END as rolcreatedb_, CASE WHEN rolcanlogin='t' THEN 1 ELSE 0 END as rolcanlogin_, CASE WHEN rolreplication='t' THEN 1 ELSE 0 END as rolreplication_, CASE WHEN rolbypassrls='t' THEN 1 ELSE 0 END as rolbypassrls_  from pg_authid where not rolname in('postgres','pg_signal_backend') and not rolname ilike '%pg_%')a left join pg_shadow on usename=rolname   where  (rolsuper_ != 0 or rolcreaterole_ != 0 or rolcreatedb_ != 0 or rolreplication_ != 0 or rolreplication_ != 0)) to '/tmp/privilege_server.csv' WITH (FORMAT CSV, DELIMITER '|');" && sed -i 's/|/\t/g' /tmp/privilege_server.csv && sed -i "s/^/$(hostname -I | awk '{print  $1}')\t/" /tmp/privilege_server.csv); fi;) && echo -e "IP SERVER\tTYPE_USER\tUser\trolsuper\trolinherit\trolcreaterole\trolcreatedb\trolcanlogin\trolreplication\trolbypassrls\trolcatupdate"  | cat - /tmp/privilege_server.csv > temp1234560 && mv temp1234560 /tmp/privilege_server.csv &&

# Headers: IP SERVER	DB	USERS	SELECT	UPDATE	DELETE	INSERT	REFERENCES	TRIGGER	TRUNCATE	RULE
psql    -t -c "select  chr(92)||'c ' || datname || CHR(10) ||  ' select * from (select  db, user_ ,sum(select_ ) as select,sum( update_ ) as update,sum( delete_ ) as delete,sum( insert_ ) as insert,sum( references_ ) as references,sum( trigger_ ) as trigger,sum( truncate_ ) as truncate,sum( rule_) as rule  from (select  current_database() as db ,grantee as user_ ,CASE WHEN privilege_type='||CHR(39)||'SELECT'||CHR(39)||' THEN count(*) ELSE 0 END as SELECT_,CASE WHEN  privilege_type='||CHR(39)||'UPDATE'||CHR(39)||' THEN count(*)  ELSE 0 END as UPDATE_,CASE WHEN privilege_type='||CHR(39)||'DELETE'||CHR(39)||' THEN count(*)  ELSE 0 END as DELETE_,CASE WHEN privilege_type='||CHR(39)||'INSERT'||CHR(39)||' THEN count(*)  ELSE 0 END as INSERT_,CASE WHEN privilege_type='||CHR(39)||'REFERENCES'||CHR(39)||' THEN count(*)  ELSE 0 END as REFERENCES_, CASE WHEN privilege_type='||CHR(39)||'TRIGGER'||CHR(39)||' THEN count(*)  ELSE 0 END as TRIGGER_, CASE WHEN privilege_type='||CHR(39)||'TRUNCATE'||CHR(39)||' THEN count(*)  ELSE 0 END as TRUNCATE_, CASE WHEN privilege_type='||CHR(39)||'RULE'||CHR(39)||' THEN count(*)  ELSE 0 END as RULE_   from information_schema.table_privileges where  table_schema= '||CHR(39)||'public'||CHR(39)||'  and not grantee = '||CHR(39)||'postgres'||CHR(39)||'   group  by grantee, privilege_type)a group by  db,user_)a where (update != 0 or delete != 0 or insert != 0 or trigger != 0 or  truncate != 0 or rule != 0) ;'  from pg_database where not datname in('postgres','template1','template0') ; "  | sed -e 's/\+//g' | psql -t   | grep -Ev "You are now connected|conectado a la base de datos" | sed -e '/^$/d' | sed -e 's/|/\t/g' > /tmp/grant.csv &&  sed -i "s/^/$(if result0000001=$(hostname -I 2>/dev/null); then echo $(hostname -I | awk '{print  $1}'); else echo $(hostname -i | awk '{print  $1}'); fi)\t/" /tmp/grant.csv && echo -e "IP SERVER\tDB\tUSERS\tSELECT\tUPDATE\tDELETE\tINSERT\tREFERENCES\tTRIGGER\tTRUNCATE\tRULE"  | cat - /tmp/grant.csv > /tmp/temp1234560 && mv /tmp/temp1234560 /tmp/grant.csv
```

**Opciones #1 :** Si quieres que de los 3 archivos se genere sólo 1 archivo, puedes usar la siguiente consulta Y generará el archivo **/tmp/Reporte.csv**
```
cat  /tmp/info_server.csv  > /tmp/Reporte.csv && echo ""  >>  /tmp/Reporte.csv  &&   echo ""  >>  /tmp/Reporte.csv  && cat /tmp/privilege_server.csv  >>   /tmp/Reporte.csv  && echo ""  >>  /tmp/Reporte.csv  &&  echo ""  >>  /tmp/Reporte.csv &&  cat  /tmp/grant.csv  >>   /tmp/Reporte.csv  && echo ""  >>  /tmp/Reporte.csv
```

**Opciones #2 :** También si tienes un servidor, donde quieres que se centren los archivos, puedes usar la siguiente consulta
```
# Renombrar el archivo reportes.csv para colocar la ip del servidor  como nombre y extension .csv
mv /tmp/Reporte.csv /tmp/$(if result0000001=$(hostname -I 2>/dev/null); then echo $(hostname -I | awk '{print  $1}'); else echo $(hostname -i | awk '{print  $1}'); fi).csv 

# Enviar el archivo al servidor  a la carpeta Reportes_servidores
scp  /tmp/$(if result0000001=$(hostname -I 2>/dev/null); then echo $(hostname -I | awk '{print  $1}'); else echo $(hostname -i | awk '{print  $1}'); fi).csv  10.44.1.55/tmp/Reportes_servidores 
```


**Opciones #3 :** si quieres guardar la información, en una base de datos remota, realiza lo siguientes pasos: <br>
1 - Verificar la conexion en el servidor origen al servidor donde se va guardar la info 
 ```
 telnet  10.55.10.55 5432
```

2 - Crear las tablas 
```
CREATE TABLE public.info_server (id serial PRIMARY KEY, IP VARCHAR (100), HOSTNAME VARCHAR (255), VERSION_PSQL VARCHAR (255), CANTIDAD_DB INT );
CREATE TABLE public.privilege_server (id serial PRIMARY KEY,IP VARCHAR (100),TYPE_USER VARCHAR (50),USER_ VARCHAR (50),rolsuper BIT,rolinherit BIT,rolcreaterole BIT,rolcreatedb BIT,rolcanlogin BIT,rolreplication BIT,rolbypassrls BIT,rolcatupdate BIT);
CREATE TABLE public.grant_logic (id serial PRIMARY KEY,    IP VARCHAR (100),DB VARCHAR (255),  USER_ VARCHAR (255),SELECT_ INT,UPDATE_ INT,DELETE_ INT,INSERT_ INT,REFERENCES_ INT,TRIGGER_  INT,TRUNCATE_ INT,RULE_ INT  );
```

3 - Generaramos el archivo **/tmp/Reporte_insert.csv**  que va  generar un copy stdin
```
echo "COPY info_server ( IP, HOSTNAME , VERSION_PSQL , CANTIDAD_DB  ) FROM stdin;"  > /tmp/Reporte_insert.csv &&  cat  /tmp/info_server.csv | grep -v "Cantidad DBA"   >> /tmp/Reporte_insert.csv &&  echo "\." >>  /tmp/Reporte_insert.csv  && echo "" >> /tmp/Reporte_insert.csv &&
echo "COPY privilege_server ( IP ,TYPE_USER,USER_ ,rolsuper ,rolinherit ,rolcreaterole ,rolcreatedb ,rolcanlogin ,rolreplication ,rolbypassrls ,rolcatupdate   ) FROM stdin;"  >> /tmp/Reporte_insert.csv &&  cat  /tmp/privilege_server.csv | grep -v "rolbypassrls"   >> /tmp/Reporte_insert.csv &&  echo "\." >>  /tmp/Reporte_insert.csv &&  echo "" >> /tmp/Reporte_insert.csv &&
echo "COPY grant_logic (IP,DB,USER_ ,SELECT_ ,UPDATE_ ,DELETE_ ,INSERT_ ,REFERENCES_ ,TRIGGER_  ,TRUNCATE_ ,RULE_  ) FROM stdin;"  >> /tmp/Reporte_insert.csv && cat  /tmp/grant.csv  | grep -v "TRUNCATE"  >> /tmp/Reporte_insert.csv &&  echo "\." >>  /tmp/Reporte_insert.csv && echo "" >> /tmp/Reporte_insert.csv 
```

4 - Ejecutamos el archivo remotamente, para que se realice el copy en las tablas
```
psql -h 10.44.55.100 -U postgresql -p MY_passowrd_secret -d db_reportes -f /tmp/Reporte_insert.csv
```

5- Consultar la información en las tablas 
```
psql -p 5435 -c "select * from info_server;  select * from grant_logic;  select * from privilege_server;"
```

# saber todos los permisos en versiones >= 9
```sql
select * from (
	select    
	   name_object
	   ,type_object
	   ,schema
	--   ,acl_
	  ,e.rolname as user_name
	  ,privilege_type
	--  ,is_grantable
	  
	  from (
	 select relname as name_object, 
	  case cls.relkind when 'r' then 'TABLE'
	when 'm' then 'MATERIALIZED_VIEW'
	when 'i' then 'INDEX'
	when 'S' then 'SEQUENCE'
	when 'v' then 'VIEW'
	when 'c' then 'TYPE'
	else cls.relkind::text end as type_object 
	 ,nspname as schema /*,relnamespace */
	 ,coalesce(  relacl , typacl)  as acl_


		from pg_class as cls
	left join pg_namespace nmp on nmp.oid= relnamespace
	left join pg_type as tp  on relname= typname 
	
	where  nspname != 'information_schema' and not nspname ilike 'pg_%'  ) as z
	left JOIN LATERAL (SELECT *  FROM aclexplode( acl_ ) AS x) a  ON true
	left JOIN pg_authid e ON a.grantee = e.oid 
	
 	--where e.rolname is not null   and name_object = 'tramongrafica' 
	 -- order by  type_object desc   
	 
	
 union all  
  SELECT 	a.routine_name as name_object
			, b.routine_type as type_object
			,a.routine_schema as schema
			,grantee as user_name
			, privilege_type  as privilege
			
		FROM information_schema.routine_privileges as a
	left join information_schema.routines  as b on a.routine_name=b.routine_name
	where /*not a.grantee in('PUBLIC','postgres') and*/ not  a.specific_schema in('information_schema','pg_catalog','pg_toast') 

  union all
   select trigger_name, 'TRIGGER' as type_object  ,trigger_schema, null as user_name ,null as privilege_type 
   FROM information_schema.triggers group by trigger_schema,trigger_name
   
	)as a   where not user_name in('PUBLIC','postgres', '' )   limit 10 ;
 
```



#  todos los permisos en una sola tabla , testeado en versiones  10 - 16.3
PERMISOS DE LOS OBJETOS : TABLAS , VISTAS,  ESCHEMAS, BASES DE DATOS, FUNCIONES, SECUENCIAS, TYPPES 
```sql 

select * from (


/* PERMISOS EN TABLAS Y VISTAS  */

select 
	inet_server_addr() as ip_server
	,a.grantor
	,grantee
	,table_type  as type
	,a.table_schema as schema_name
	,a.table_name as object_name
	
	,privilege_type
	,is_grantable::boolean

 from information_schema.table_privileges as a 
left join  information_schema.tables as b on a.table_name=b.table_name

 where not grantee in('PUBLIC','postgres')  


union all


/* PERMISOS EN ESCHEMAS  */ 

SELECT 
			inet_server_addr() as ip_server,
			r.rolname AS grantor,
             e.rolname AS grantee,
			 'SCHEMA' as type,
			 null,
             nspname as   object_name, 
             privilege_type,
             is_grantable  
        FROM pg_namespace
JOIN LATERAL (SELECT *
                FROM aclexplode(nspacl) AS x) a
          ON true
        JOIN pg_authid e
          ON a.grantee = e.oid
        JOIN pg_authid r
          ON a.grantor = r.oid 
       WHERE   not nspname ilike 'pg_%'   and e.rolname != 'postgres'   
	   
	   

union all


/* PERMISOS DE BASES DE DATOS   */ 	   


select 
	inet_server_addr() as ip_server
	,r.rolname AS grantor
	,e.rolname AS grantee
	,'DATABASE' as type
	,NULL
	,datname AS object_name
	,privilege_type
	,is_grantable 
from pg_database 
JOIN LATERAL (SELECT *
                FROM aclexplode(datacl) AS x) a
     ON true
         JOIN pg_authid e
          ON a.grantee = e.oid
        JOIN pg_authid r
          ON a.grantor = r.oid  
where  e.rolname != 'postgres'    





union all



/* PERMISOS DE FUNCIONES   */ 	   



SELECT  
 inet_server_addr() as ip_server
 ,grantor
 ,grantee
 ,b.routine_type as type 
 ,a.routine_schema  as schema
 ,a.routine_name as object_name
 ,privilege_type
 ,is_grantable::boolean
FROM information_schema.routine_privileges as a
	left join information_schema.routines  as b on a.routine_name=b.routine_name
	where not a.grantee in('PUBLIC','postgres')   




union all


/* PERMISOS DE SECUENCIAS   */ 	   



SELECT 
	 inet_server_addr() as ip_server
	 ,r.rolname AS grantor
     ,e.rolname AS grantee
	 ,'SEQUENCE' as  type 
	 ,nspname as schema 
	 ,relname as object_name
	,privilege_type
	,is_grantable
FROM pg_class as cl
	LEFT JOIN pg_namespace as nm ON cl.relnamespace = nm.oid
	JOIN LATERAL (SELECT *
                FROM aclexplode(relacl) AS x) a
          ON true
         JOIN pg_authid e
          ON a.grantee = e.oid
        JOIN pg_authid r
          ON a.grantor = r.oid 
 
	WHERE relkind = 'S'
	  AND relacl is not null
	  AND not nspname ilike 'pg_%'   
	  AND e.rolname != 'postgres' 
 



union all



/* PERMISOS DE TYPES   */ 	   

	
	select 
            inet_server_addr() as ip_server
            ,r.rolname AS grantor
            ,e.rolname AS grantee
            ,'TYPE' AS type
            ,nsp.nspname esquema 
            ,typname as object_name 
            ,privilege_type
            ,is_grantable
	from pg_type as pgt  	
	left JOIN pg_namespace nsp ON pgt.typnamespace = nsp.oid   
	JOIN LATERAL (SELECT *
                FROM aclexplode(typacl) AS x) a
          ON true
         JOIN pg_authid e
          ON a.grantee = e.oid
        JOIN pg_authid r
          ON a.grantor = r.oid 
	
	where  typacl is not null  
			AND not nspname ilike 'pg_%'  
			AND not nspname in('pg_catalog','information_schema')
			AND e.rolname != 'postgres'

) as a order by type, schema_name;

```


#  todos los permisos en una sola tabla , testeado en version 8 
```SQL 




select 
	inet_server_addr() as ip_server
	,inet_server_port() as port
	,current_database() db
	,* from 
 
(
 

	select grantor,grantee,object_type,schema,object_name,privilege_type,is_grantable from 
	(select * ,
		case  
		WHEN  letter_privilege like  '%r*%' and privilege_type = 'SELECT' 		  then true
		WHEN  letter_privilege like  '%a*%' and privilege_type = 'INSERT' 		  then true
		WHEN  letter_privilege like  '%w*%' and privilege_type = 'UPDATE' 		  then true
		WHEN  letter_privilege like  '%d*%' and privilege_type = 'DELETE'		  then true
		WHEN  letter_privilege like  '%D*%' and privilege_type = 'TRUNCATE' 	  then true
		WHEN  letter_privilege like  '%x*%' and privilege_type = 'REFERENCES'	  then true
		WHEN  letter_privilege like  '%t*%' and privilege_type = 'TRIGGER'		  then true
		WHEN  letter_privilege like  '%C*%' and privilege_type = 'CREATE' 		  then true
		WHEN  letter_privilege like  '%c*%' and privilege_type = 'CONNECT' 		  then true
		WHEN  letter_privilege like  '%T*%' and privilege_type = 'TEMPORARY' 	  then true
		WHEN  letter_privilege like  '%X*%' and privilege_type = 'EXECUTE' 		  then true
		WHEN  letter_privilege like  '%U*%' and privilege_type = 'USAGE' 		  then true
		WHEN  letter_privilege like  '%s*%' and privilege_type = 'SET' 			  then true
		WHEN  letter_privilege like  '%A*%' and privilege_type = 'ALTER SYSTEM'   then true
		else  false
		end as is_grantable 
		from 	
		(select * from 	
		(select  
				
				grantor
				,grantee
				,object_type
				,schema
				,object_name
				,letter_privilege
				,unnest(string_to_array(( 
					CASE  WHEN letter_privilege like '%r%' THEN 'SELECT' 		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%a%' THEN 'INSERT' 		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%w%' THEN 'UPDATE' 		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%d%' THEN 'DELETE'		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%D%' THEN 'TRUNCATE' 		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%x%' THEN 'REFERENCES'	ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%t%' THEN 'TRIGGER'		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%C%' THEN 'CREATE' 		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%c%' THEN 'CONNECT' 		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%T%' THEN 'TEMPORARY' 	ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%X%' THEN 'EXECUTE' 		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%U%' THEN 'USAGE' 		ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%s%' THEN 'SET' 			ELSE '' END || ',' || 
					CASE  WHEN letter_privilege like '%A%' THEN 'ALTER SYSTEM' ELSE '' END   
				) , ',')) as privilege_type
				
			  
		from (
			SELECT 
				schema
				,object_name
				,object_type
				,split_part( split_part(array_to_string(relacl , ', ') , ', ', generate_series(1, length(array_to_string(relacl , ', ') ) - length( replace(array_to_string(relacl , ', ') , ', ', '')) + 1))  , '/', 2) AS grantor
				,split_part(split_part( split_part(array_to_string(relacl , ', ') , ', ', generate_series(1, length(array_to_string(relacl , ', ') ) - length(replace(array_to_string(relacl , ', ') , ', ', '')) + 1))  , '/', 1), '=', 1) as grantee 
				,split_part(split_part( split_part(array_to_string(relacl , ', ') , ', ', generate_series(1, length(array_to_string(relacl , ', ') ) - length(replace(array_to_string(relacl , ', ') , ', ', '')) + 1))  , '/', 1), '=', 2) as letter_privilege  
			FROM 
				( select * from (
				 
					 
					 ---- ESQUEMAS 
					select null as schema, nspname as object_name, 'SCHEMA' as object_type, nspacl  AS relacl FROM pg_namespace where not nspname in( 'information_schema','pg_catalog') and nspacl is not null 
					 
					 
					 union all 
					 
					 --- BASE DE DATOS 
					 select null as schema,datname as object_name,'DATABASE' AS object_type , datacl    from pg_database where datacl is not null  
					 
					 
					 union all 
					
					select * from 
					(
					
					------ TABLAS,VIEW,INDEX,SEQUENCES,TYPE,ETC
					SELECT 
						nspname as schema
						,relname AS object_name
						,CASE 
							--WHEN (nc.oid = pg_my_temp_schema()) THEN 'LOCAL TEMPORARY'::text
							WHEN relkind= 'r' THEN 'TABLE'
							WHEN relkind= 'p' THEN 'TABLE'
							WHEN relkind= 'i' THEN 'INDEX'
							WHEN relkind= 'S' THEN 'SEQUENCE'
							WHEN relkind= 'v' THEN 'VIEW'
							WHEN relkind= 'm' THEN 'MATERIALIZED VIEW'
							WHEN relkind= 'c' THEN 'type'
							WHEN relkind= 't' THEN 'TOAST TABLE'
							WHEN relkind= 'f' THEN 'FOREIGN TABLE'
							WHEN relkind= 'p' THEN 'PARTITIONED FOREIGN'
							WHEN relkind= 'I' THEN 'PARTITIONED INDEX'
							ELSE 'other'
						END AS object_type
						, relacl  as privileges 
					FROM pg_class as cl
					left join pg_type as pty on  cl.oid = pty.typrelid 
					left join pg_namespace as nc on   cl.relnamespace= nc.oid

					 WHERE relacl is not null and not nspname in( 'information_schema','pg_catalog','pg_toast')  and not nspname ilike 'pg_temp%' 
					 and relkind in('r' ,'p' ,'i' ,'S' ,'v' ,'m' ,'t' ,'f' ,'p' ,'I')
					 
					 union all 
					 
					 ------ FUNCIONES 
					  SELECT 
								--p.oid,
								n.nspname as  schema,
								p.proname as object_name ,

								(
								CASE
								  WHEN p.proisagg THEN 'agg'
								  WHEN p.proiswindow THEN 'window'
								  WHEN p.prorettype = 'pg_catalog.trigger'::pg_catalog.regtype THEN 'trigger'
								  ELSE 'FUNCTION'
								END  )::information_schema.character_data AS object_type,
								p.proacl as privileges
					   FROM pg_proc as p
					   left join pg_namespace as n on    p.pronamespace = n.oid where  p.proacl is not null and  not nspname in( 'information_schema','pg_catalog','pg_toast')  and not nspname ilike 'pg_temp%'
					 
					 
					 
					 ) as a    
				 
				 
				 
						) as g   
				)  as v
			
			) as f where not grantee in('',  'postgres','PUBLIC','pg_database_owner') 
		) as a where privilege_type != ''
		) as b ) as x ) as d order by grantee ;

```












### obtener los usuarios del pg_hba
Obtener el usuario y el comentario que tiene despues del md5  del archivo pg_hba.conf

```
cat /syst/data/pg_hba.conf | grep -E "usuario1|usuario2|usuario3|usuario4|usuario5" | grep -Ev "^#" | grep "#" | awk '{print " Usuario : " $3  , substr($0, index($0,  "md5"))}' | sed -e 's/md5//g'
```
ejemplo:<br>
 Usuario : usuario1  # Este usuario se agrego en el 2021 y es de nuevo ingreso

### obtener los usuarios que se le vencio su vida util 
```
 select * from pg_shadow where valuntil::date >= CURRENT_DATE - INTERVAL '6 months' and valuntil::date < now()::date order by valuntil;
```


# para que sirven los depend 

**pg_depend:** se utiliza para rastrear las dependencias entre objetos dentro de una base de datos específica.<br>
**pg_shdepend:** se utiliza para rastrear las dependencias entre objetos compartidos a nivel de clúster, como roles, bases de datos y tablas del sistema.

```
----------- EJEMPLO DE MENSAJE DE ERROR -----------
postgres@test_fun# drop user gerente;
ERROR:  role "gerente" cannot be dropped because some objects depend on it
DETAIL:  owner of function fun_cleeantable(character,integer)
Time: 0.539 ms

 

SELECT 
    b.datname,
    a.classid,
    n.nspname AS esquema,
    d.name_obj,
    a.objsubid,
    a.refclassid,
    c.rolname AS rol_dependiente,
    CASE
        WHEN a.refclassid = 'pg_class'::regclass THEN (SELECT relname FROM pg_class WHERE oid = a.refobjid)
        WHEN a.refclassid = 'pg_proc'::regclass THEN (SELECT proname FROM pg_proc WHERE oid = a.refobjid)
        ELSE 'Otro tipo de objeto'
    END AS objeto_referenciado
FROM 
    pg_shdepend AS a
LEFT JOIN 
    pg_database AS b ON a.dbid = b.oid
LEFT JOIN 
    pg_roles AS c ON a.refobjid = c.oid
LEFT JOIN 
    (SELECT oid, relname AS name_obj, relnamespace AS namespace_oid FROM pg_class 
     UNION ALL 
     SELECT oid, proname AS name_obj, pronamespace AS namespace_oid FROM pg_proc) AS d 
    ON a.objid = d.oid
LEFT JOIN 
    pg_namespace AS n ON d.namespace_oid = n.oid
WHERE 
    c.rolname = 'gerente';


+-------+---------+-------+----------+------------+----------+---------+
| dbid  | classid | objid | objsubid | refclassid | refobjid | deptype |
+-------+---------+-------+----------+------------+----------+---------+
| 18149 |    1255 | 18213 |        0 |       1260 |    18214 | o       |
+-------+---------+-------+----------+------------+----------+---------+




 
postgres@test_fun# SELECT * FROM pg_depend   WHERE objid = 18215;
+---------+-------+----------+------------+----------+-------------+---------+
| classid | objid | objsubid | refclassid | refobjid | refobjsubid | deptype |
+---------+-------+----------+------------+----------+-------------+---------+
|    1255 | 18215 |        0 |       2615 |     2200 |           0 | n       |
|    1255 | 18215 |        0 |       2612 |    13133 |           0 | n       |
+---------+-------+----------+------------+----------+-------------+---------+
(2 rows)
 
 ```

# OTROS PERMISOS
 ```
####### BUSCAR TABLAS QUE ALMACENAN LOS ACL ####### 

--- Encontrar todos los ACL 
select distinct table_schema,table_name,column_name from information_schema.columns where column_name ilike '%acl%';
select table_schema,table_name from information_schema.tables where table_name ilike '%acl%';

 
####### PERMISOS A PARAMETROS ####### 

[NOTA] -> SOLO FUNCIONA APARTIR DE LA VERSION 15 

select * from  pg_catalog.pg_parameter_acl ;

GRANT SET ON PARAMETER log_statement TO ale;
GRANT ALTER SYSTEM ON PARAMETER log_statement TO ale;

REVOKE SET ON PARAMETER log_statement FROM ale;
REVOKE ALTER SYSTEM ON PARAMETER log_statement FROM ale;


####### PERMISOS A NIVEL COLUMNA ####### 


--- Consultar los permisos 
select *from information_schema.column_privileges where grantee  = 'analista_datos' limit 10;


--- Otorgar los permisos 
GRANT SELECT (nombre, edad), UPDATE (nombre, edad) ON TABLE empleados TO analista_datos;

  

####### PERMISOS DE MANTENIMIENTO SOLO A TABLAS  ####### 
 
 
--- realizar varias tareas de mantenimiento en una tabla o un esquema. como : VACUUM,REINDEX,ANALYZE,CLUSTER
GRANT MAINTAIN ON TABLE table_name TO role_name;


####### PERMISOS A LOS TIPOS DE DATOS DOMAIN ####### 
 

----Un dominio : tipo de datos que puede tener restricciones adicionales y se utiliza para garantizar la consistencia y la validez de los datos
GRANT USAGE ON DOMAIN phone_number TO app_user;

 ```

## Bibliografía:

https://www.postgresql.org/files/documentation/pdf/15/postgresql-15-A4.pdf
<br>https://www.postgresql.org/docs/current/sql-grant.html






## Formas de usar INHERIT 

```

### Paso 1: Crear la base de datos y las tablas
Primero, creamos una base de datos y una tabla simple para nuestros ejemplos:

CREATE DATABASE ejemplo_inherit;
\c ejemplo_inherit

CREATE TABLE datos (
    id SERIAL PRIMARY KEY,
    info TEXT
);

INSERT INTO datos (info) VALUES ('Registro 1'), ('Registro 2'), ('Registro 3');


### Paso 2: Crear roles y usuarios
Creamos varios roles y usuarios con diferentes configuraciones de `INHERIT`:

-- Crear roles
CREATE ROLE rol_inherit INHERIT;
CREATE ROLE rol_noinherit NOINHERIT;
CREATE ROLE rol_inherit_false;
CREATE ROLE rol_set_true;
CREATE ROLE rol_set_false;

-- Crear usuarios
CREATE ROLE usuario_inherit LOGIN INHERIT;
CREATE ROLE usuario_noinherit LOGIN NOINHERIT;
CREATE ROLE usuario_inherit_false LOGIN NOINHERIT;
CREATE ROLE usuario_set_true LOGIN NOINHERIT;
CREATE ROLE usuario_set_false LOGIN NOINHERIT;


### Paso 3: Otorgar permisos y roles
Otorgamos permisos y roles a los usuarios con diferentes configuraciones:

-- Otorgar permisos a los roles
GRANT SELECT ON datos TO rol_inherit;
GRANT SELECT ON datos TO rol_noinherit;
GRANT SELECT ON datos TO rol_inherit_false;
GRANT SELECT ON datos TO rol_set_true;
GRANT SELECT ON datos TO rol_set_false;

-- Otorgar roles a los usuarios
GRANT rol_inherit TO usuario_inherit;
GRANT rol_noinherit TO usuario_noinherit;
GRANT rol_inherit_false TO usuario_inherit_false WITH INHERIT FALSE;
GRANT rol_set_true TO usuario_set_true WITH INHERIT FALSE SET TRUE;
GRANT rol_set_false TO usuario_set_false WITH INHERIT FALSE SET FALSE;


### Paso 4: Verificar los privilegios
Ahora verificamos cómo afectan estas configuraciones a los privilegios de los usuarios.

#### Usuario con `INHERIT`

\c - usuario_inherit
SELECT * FROM datos;  -- Debería funcionar porque hereda los privilegios de rol_inherit


#### Usuario con `NOINHERIT`

\c - usuario_noinherit
SELECT * FROM datos;  -- No debería funcionar porque no hereda los privilegios de rol_noinherit


#### Usuario con `WITH INHERIT FALSE`

\c - usuario_inherit_false
SELECT * FROM datos;  -- No debería funcionar porque no hereda los privilegios de rol_inherit_false


#### Usuario con `WITH INHERIT FALSE SET TRUE`

\c - usuario_set_true
SELECT * FROM datos;  -- No debería funcionar porque no hereda los privilegios de rol_set_true

SET ROLE rol_set_true;
SELECT * FROM datos;  -- Debería funcionar porque ahora tiene los privilegios de rol_set_true


#### Usuario con `WITH INHERIT FALSE SET FALSE`

\c - usuario_set_false
SELECT * FROM datos;  -- No debería funcionar porque no hereda los privilegios de rol_set_false

SET ROLE rol_set_false;
SELECT * FROM datos;  -- No debería funcionar porque no puede usar SET ROLE para adquirir los privilegios de rol_set_false


### Resumen
- **usuario_inherit**: Hereda automáticamente los privilegios de `rol_inherit`.
- **usuario_noinherit**: No hereda automáticamente los privilegios de `rol_noinherit`.
- **usuario_inherit_false**: No hereda automáticamente los privilegios de `rol_inherit_false`.
- **usuario_set_true**: No hereda automáticamente los privilegios de `rol_set_true`, pero puede usar `SET ROLE` para adquirirlos.
- **usuario_set_false**: No hereda automáticamente los privilegios de `rol_set_false` y no puede usar `SET ROLE` para adquirirlos.




SELECT 
    r.rolname AS role_name,
    m.member AS member_oid,
    u.rolname AS member_name,
    m.admin_option,
    m.inherit_option,
    m.set_option
FROM 
    pg_auth_members m
JOIN 
    pg_roles r ON m.roleid = r.oid
JOIN 
    pg_roles u ON m.member = u.oid;
	


- **admin_option**: Le otorga el permiso al miembro poder hacer grant o revoke sobre el rol.
- **inherit_option**: Indica si el miembro hereda automáticamente los privilegios del rol.
- **set_option**: Indica si el miembro puede usar `SET ROLE` para adquirir los privilegios del rol .

SELECT rolname, rolinherit FROM pg_roles WHERE rolname = 'postgres'; 


```
