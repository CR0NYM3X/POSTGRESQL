
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
```
SELECT session_user;
SELECT current_user;
```

###  Buscar un usuario o role
```sh
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
```sh
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
```sh
  COMMENT ON ROLE testuserdba IS 'Esta es la descripción del usuario.';
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)
 
### Eliminar un usuario 
```sh
 drop user testuserdba;
 drop role testuserdba;
 ```

### Eliminar usuarios que tienen permisos en toda las base de datos
 ```
psql -t -c "select '\c ' || datname || chr(10) || 'drop OWNED by '|| chr(34)|| 'MYUSER_TEST'|| chr(34) || ';' from pg_database where not datname in('template1','template0','postgres');" | sed -e 's/\+//g'  | psql  | psql -c 'drop user "MYUSER_TEST";'
 ```

<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Cambiar passowd
```sh
\password testuserdba 
ALTER USER "testuserdba" PASSWORD '12345'
ALTER USER "testuserdba" PASSWORD 'md5a3cc0871123278d59269d85dbbd772893';  
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Cambiar la fecha de expiracion de acceso:
```sh
ALTER USER "testuserdba" WITH VALID UNTIL '2023-11-11';
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)


### Habilitar o Desabilitar un usuario para conectarse a la base de datos 
**`LOGIN`**  Habilita al usuario para iniciar sesión en el sistema de base de datos <br>
**`NOLOGIN`** significa que este rol de usuario no puede iniciar sesión en el sistema de base de datos. En otras palabras, no se permite que este usuario se autentique en PostgreSQL y realice conexiones.
```sh
  ALTER ROLE "my_user" NOLOGIN;

  ALTER ROLE "my_user" LOGIN;
```
  <br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)
  

### Limitar el número de conexion por usuario:
```sh
ALTER USER testuserdba WITH CONNECTION LIMIT 2;
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Ver la cantidad y tipo de  privilegios de un usuario:

```sh
# Para Tablas : 

select  current_database(),'' as usuario,'Cnt_total_tablas' as privilege_type,count(*) as Total_Privilege
  from  information_schema.tables
WHERE table_schema='public' 
union all 
select  current_database(),grantee,privilege_type,count(*)
  from information_schema.table_privileges
where  table_schema= 'public' and grantee in('MYUSUARIO') group by grantee, privilege_type;

# Para Funciones y Procedimientos Almacenados :
# Para Triggers
# Para Schemas:
# Para Sequences.:
# Para Type:
# Para view:
# Para index:

# Tambien se puede usar la siguiente tabla 
SELECT grantee,table_schema,table_name,privilege_type FROM information_schema.role_table_grants WHERE grantee='my_user';
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)



### Asignar o cambiar owner en la base de datos y los objetos  
```sh
--- Quita el owner a los objetos para que te permita eliminar un usuario
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



# Saber la cantidad de owner que tiene un usuario

```
--- Para ver los owner de la dba
SELECT datname, rolname userOwner FROM pg_database JOIN pg_roles ON pg_database.datdba = pg_roles.oid;

--- los owner de las tablas 
SELECT  'cnt_tb_total -> ' tableowner,count(*) cnt_tb_owner FROM pg_tables where schemaname = 'public'
union all
(SELECT  tableowner, count(*) cnt_tb_owner FROM pg_tables where schemaname = 'public' group by tableowner order by tableowner,count(*));


--- los owner de las funciones 
select 'cnt_fun_total ' owner ,count(*)  cnt_fun_owner FROM pg_proc where   prorettype != 0 and pronamespace in(select oid from pg_namespace where nspname = 'public')
union all
(SELECT  rolname,count(*)   FROM pg_proc JOIN pg_roles ON pg_proc.proowner = pg_roles.oid where  prorettype != 0 and  pronamespace in(select oid from pg_namespace where nspname = 'public') group by rolname order by rolname,count(*));

```




### Agregar y Quitar super Usuario a un usuario/role
```sh
ALTER user  "sysutileria" WITH SUPERUSER; 
ALTER USER "sysutileria" WITH NOSUPERUSER;
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)


### Asignarle un rol a un usuario
Este es un ejemplo de un rol para crear tablas;
```
CREATE ROLE tabla_creator;
GRANT CREATE ON SCHEMA public TO tabla_creator;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO tabla_creator;

ALTER USER mi_user2 SET ROLE tabla_creator;
GRANT rol_name1 TO user12;
GRANT tabla_creator TO my_usuario2;

REVOKE role_a, role_b FROM my_user;
```

### Asignar Permisos lógicos SELECT, UPDATE, DELETE etc:
*El privilegio **`USAGE`** solo sirve para Secuencias, Esquemas  y Funciones,  el privilegio USAGE no permite modificar, solo para consultar o ejecutar*

```sh
DATABASE:
  GRANT CONNECT ON DATABASE "tiendavirtual" TO "testuserdba";
  grant all privileges on database tu_bd to tu_usuario;

TABLES:
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "testuserdba";
  grant SELECT, UPDATE, DELETE, INSERT, REFERENCES, TRIGGER, TRUNCATE, RULE on all tables in schema public to "testuserdba";
  GRANT REFERENCES ON tabla_referenciada TO usuario_o_rol; -- sirve  crear claves foráneas que hacen referencia a una tabla
  GRANT ALTER ON TABLE nombre_de_tabla TO my_user_new;
  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA CLINICA TO dba WITH GRANT OPTION;  -- este se usa si quieres que el rol quiere heredar con grant


SEQUENCES:
  GRANT ALL PRIVILEGES ON ALL sequences IN SCHEMA public TO "testuserdba";
  GRANT USAGE ON SEQUENCE nombre_secuencia TO testuserdba;
  GRANT USAGE, SELECT ON SEQUENCE mi_secuencia TO testuserdba;

SCHEMA:
  GRANT USAGE ON SCHEMA public TO testuserdba; - otorga permisos para ver la estructura de los objetos de un esquea
  GRANT ALL PRIVILEGES ON SCHEMA mi_esquema TO mi_usuario;
  GRANT SELECT ON SCHEMA mi_esquema TO mi_rol;
  ALTER DEFAULT PRIVILEGES IN SCHEMA mi_esquema GRANT SELECT ON TABLES TO mi_usuario; -- Esto otorgará automáticamente el derecho de SELECT en todas las tablas futuras creadas en el esquema "mi_esquema" al usuario "mi_usuario".  

FUNCTIONS:
  grant ALL PRIVILEGES  on all functions in schema public to "testuserdba";
  grant execute on all functions in schema public to "testuserdba";
  GRANT EXECUTE ON FUNCTION public.fun_obtenercontactoscopiaweb(int, varchar) TO "testuserdba";

Index:
  GRANT CREATE ON TABLE mi_tabla TO mi_usuario;

Type:
  GRANT USAGE ON TYPE mi_tipo_de_dato TO mi_usuario;

View:
  GRANT SELECT ON mi_vista TO mi_usuario;

trigger:
  GRANT EXECUTE ON FUNCTION mi_trigger_function() TO mi_usuario;

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


```sh
Remove Owner Database
REVOKE OWNERSHIP ON DATABASE 'mydbatest' FROM "testuserdba";

DATABASE:
  REVOKE ALL PRIVILEGES ON DATABASE mytestdba FROM "92096883";

TABLES:
  REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "testuserdba";
  REVOKE ALL PRIVILEGES ON TABLE nombre_de_tabla FROM nombre_del_rol;
  REVOKE ALL ON TABLE my_tabla FROM PUBLIC; --- para versiones 8
  REVOKE ALL ON TABLE my_tabla FROM postgres; --- para versiones 8

SEQUENCES:
  REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM "testuserdba";
  REVOKE ALL PRIVILEGES ON SEQUENCE nombre_de_secuencia FROM nombre_del_rol;

SCHEMA :
  REVOKE ALL PRIVILEGES ON SCHEMA nombre_del_esquema FROM nombre_del_rol;
  

FUNCTIONS:
  revoke execute on all functions in schema public from testuserdba;
  REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM "testuserdba";
  REVOKE ALL PRIVILEGES ON FUNCTION nombre_de_funcion(int, varchar) FROM nombre_del_rol;

Index:
  REVOKE ALL PRIVILEGES ON INDEX nombre_del_indice FROM nombre_del_rol;

Type:
  REVOKE ALL PRIVILEGES ON TYPE nombre_del_tipo FROM nombre_del_rol;

View:
  REVOKE ALL PRIVILEGES ON VIEW nombre_de_vista FROM nombre_del_rol;

trigger:
  REVOKE ALL PRIVILEGES ON TRIGGER nombre_del_disparador FROM nombre_del_rol;

```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Asignar acceso por IP a la base de datos, nivel sistema operativo:
`pg_hba.conf` Este archivo se utiliza para definir las políticas de autenticación y controlar quién puede conectarse a la base de datos, desde dónde pueden conectarse y qué métodos de autenticación deben utilizarse para la conexión. <br>

| TYPE | DATABASE |USER | ADDRESS | METHOD | 
|--------------|--------------|--------------|--------------|--------------|
| host    | mydbatest    | myusertest    | 192.168.1.0/32    | md5   |
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Ver si hay un error en el archivo pg_hba.conf
```sh
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
 psql **`mydba`** -c "SELECT  'GRANT EXECUTE ON FUNCTION '|| proname || '(' || pg_catalog.oidvectortypes(proargtypes) || ')' ||  ' to ' || CHR(34) || **`'myusertest'`** ||  CHR(34) || ';'   as qweads FROM pg_proc where proname in(SELECT routine_name FROM information_schema.routines WHERE routine_type = 'FUNCTION' AND specific_schema = 'public')  "  | grep -v '-' | grep -v 'rela' | grep -v 'Name' | grep -v 'rows)' | grep -v 'table_name' | grep -v 'qweads'  > /tmp/funciones.sql %%  psql **`mydbatest`** < /tmp/funciones.sql
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

###  Asignar todos los permisos en las tablas en todas la bases de datos, versiones  v9.0
select	'\\c ' || datname || ';' || CHR(10) || 'grant select on all tables in schema public to **`"myusertest"`**;'
|| CHR(10) || 'GRANT CONNECT ON DATABASE "'|| datname ||'" TO  **`"myusertest"`**;'  as qweads from pg_database where not datname ilike 'template%' and not datname ilike 'postgres';
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)


---


# Grupos  lógicos  en postgresql: 
son conjuntos lógicos de roles de usuarios que se utilizan para simplificar la administración de permisos y la gestión de roles en una base de datos. Los grupos permiten asignar permisos a un conjunto de usuarios de una manera más eficiente, en lugar de otorgar permisos individuales a cada usuario.


### Ver los grupos existentes:
```sh
SELECT * FROM pg_group;
```

### Crear un grupo
```sh
CREATE GROUP mi_grupo;
```
    
### Agregar  un usuario a un grupo
```sh
  GRANT mi_grupo TO mi_usuario;
```
  
### Eliminar un grupo 
```sh
  DROP GROUP mi_grupo;
``` 
 
### Ver los miembros de un grupo específico:
La tabla pg_auth_members sirve para mostrar si un usuario esta en un grupo o rol
```sh
select  roleid::regrole AS group_name, member::regrole AS member_name,grantor::regrole   FROM pg_auth_members WHERE roleid = 'mi_grupo';


select usename, rolname from pg_user join pg_auth_members on (pg_user.usesysid=pg_auth_members.member) 
join pg_roles on (pg_roles.oid=pg_auth_members.roleid) 
```

### retirarle los permisos a un usuario de un grupo o role
```
--- Si no funciona esta opcion utilizas la otra query
REVOKE user12 FROM rol_name1;

delete from  pg_auth_members where member= 33303009 /*pg_user.usesysid*/ and roleid=33445429 /*pg_roles.oid*/;
```


### Ejemplos de grupos 
```sh
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

## Bibliografía:

https://www.postgresql.org/files/documentation/pdf/15/postgresql-15-A4.pdf
