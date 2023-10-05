
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


- [Mapeo de usuario atraves de FDW](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios,%20accesos%20y%20permisos.md#mapeo-de-usuario-para-permitir-que-un-usuario-local-acceda-a-una-base-de-datos-remota-a-trav%C3%A9s-de-foreign-data-wrapper-fdw)
	- [Crear la tabla de mapeo de usuario](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios,%20accesos%20y%20permisos.md#creaci%C3%B3n-de-la-tabla-de-mapeo-de-usuario)
	- [Hacer que no pida password al autenticarse con FDW](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios,%20accesos%20y%20permisos.md#hacer-que-no-pida-password-al-autenticarse-con-fdw)
	
	- [Configuración del servidor extranjero](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios,%20accesos%20y%20permisos.md#configuraci%C3%B3n-del-servidor-extranjero)
	
	- [Creación de una tabla externa](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios,%20accesos%20y%20permisos.md#creaci%C3%B3n-de-una-tabla-externa)

- [Grupos lógicos en postgresql](https://github.com/CR0NYM3X/POSTGRESQL/edit/main/usuarios%2C%20accesos%20y%20permisos.md#grupos--l%C3%B3gicos--en-postgresql)

	- [Ver los grupos existentes](https://github.com/CR0NYM3X/POSTGRESQL/edit/main/usuarios%2C%20accesos%20y%20permisos.md#ver-los-grupos-existentes)
	- [Crear un grupo](https://github.com/CR0NYM3X/POSTGRESQL/edit/main/usuarios%2C%20accesos%20y%20permisos.md#crear-un-grupo)
	- [Agregar un usuario a un grupo](https://github.com/CR0NYM3X/POSTGRESQL/edit/main/usuarios%2C%20accesos%20y%20permisos.md#agregar--un-usuario-a-un-grupo)
	- [Eliminar un grupo](https://github.com/CR0NYM3X/POSTGRESQL/edit/main/usuarios%2C%20accesos%20y%20permisos.md#eliminar-un-grupo)
	- [Ver los miembros de un grupo específico](https://github.com/CR0NYM3X/POSTGRESQL/edit/main/usuarios%2C%20accesos%20y%20permisos.md#ver-los-miembros-de-un-grupo-espec%C3%ADfico)
	- [Ejemplos de grupos](https://github.com/CR0NYM3X/POSTGRESQL/edit/main/usuarios%2C%20accesos%20y%20permisos.md#ejemplos-de-grupos)
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


###  Buscar un usuario o role
```sh
 \du+ "testuserdba"    -- descripción general
 select * from pg_user where usename ilike '%testuserdba%';  -- descripción general
 select * from pg_roles where rolname ilike '%testuserdba%';  -- Puedes ver el limite de conexiones por usuario en el campo: rolconnlimit
 select * from pg_authid where rolname ilike '%testuserdba%';  -- Puedes ver el limite de conexiones por usuario  en el campo: rolconnlimit
 select * from pg_shadow where usename ilike '%testuserdba%';  -- Aqui puedes ver el hash de la contraseña  
 ```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Crear un usuario:
```sh
CREATE USER "testuserdba"; -- es lo mismo role que user
CREATE role "testuserdba";  -- es lo mismo role que user
CREATE USER "testuserdba" login VALID UNTIL  '2023-11-15'; --- fecha de expiracion  
CREATE USER testuserdba WITH PASSWORD '123456789'; -- no se recomienda colocar el password en con el create, por que en los log o el historial  puedes ver la contraseña
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
select '' as usuario,'Cnt_total_tablas' as privilege_type,count(*) as Total_Privilege
  from  information_schema.tables
WHERE table_schema='public' 
union all 
select grantee,privilege_type,count(*)
  from information_schema.table_privileges
where  table_schema= 'public' and grantee in('MYUSUARIO') group by grantee, privilege_type;

```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)



### Asignar o cambiar owner en la base de datos y los objetos  
```sh
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



### Agregar y Quitar super Usuario a un usuario/role
```sh
ALTER user  "sysutileria" WITH SUPERUSER; 
ALTER USER "sysutileria" WITH NOSUPERUSER;
```
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Asignar Permisos lógicos SELECT, UPDATE, DELETE etc:
*El privilegio **`USAGE`** solo sirve para Secuencias, Esquemas  y Funciones,  el privilegio USAGE no permite modificar, solo para consultar o ejecutar*

```sh
DATABASE:
  GRANT CONNECT ON DATABASE "tiendavirtual" TO "testuserdba";
  grant all privileges on database tu_bd to tu_usuario;

TABLES:
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "testuserdba";
  grant SELECT, UPDATE, DELETE, INSERT, REFERENCES, TRIGGER, TRUNCATE, RULE on all tables in schema public to "testuserdba";

SEQUENCES:
  GRANT ALL PRIVILEGES ON ALL sequences IN SCHEMA public TO "testuserdba";
  GRANT USAGE ON SEQUENCE nombre_secuencia TO testuserdba;
  GRANT USAGE, SELECT ON SEQUENCE mi_secuencia TO testuserdba;

SCHEMA:
  GRANT USAGE ON SCHEMA public TO testuserdba;
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
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Revokar o eliminar Permisos a objetos: [Funciones, Tablas, type, view, index, sequence, triggers]:  

```sh
Remove Owner Database
REVOKE OWNERSHIP ON DATABASE 'mydbatest' FROM "testuserdba";

DATABASE:
  REVOKE ALL PRIVILEGES ON DATABASE mytestdba FROM "92096883";

TABLES:
  revoke all on all tables in schema public from "testuserdba";
  REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "testuserdba";
  REVOKE ALL PRIVILEGES ON TABLE nombre_de_tabla FROM nombre_del_rol;

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
psql **`mydba`** -c "SELECT 'grant select on table ' || table_name ||   ' to ' || CHR(34) || **`'myusertest'`** ||  CHR(34) || ';' as qweads FROM information_schema.tables WHERE table_schema='public' order by table_name;" | grep -v '-' | grep -v 'rela' | grep -v 'Name' | grep -v 'rows)' | grep -v 'table_name' | grep -v 'qweads'  > /tmp/dbaaplicaciones.sql &&  psql **`mydba`** < /tmp/dbaaplicaciones.sql

- `Opción #2`<br>
psql   **`mydba`**   -c "\dt" | grep -v '-' | grep -v 'rela' | grep -v 'Name' | awk '{print " SELECT ON TABLE "$3 " FROM **`myusertest`**;" }' > /tmp/usuarios.sql && psql snisef < /tmp/usuarios.sql
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

### Asignar permisos de execución en funciones  psql  v8.1 
 psql **`mydba`** -c "SELECT  'GRANT EXECUTE ON FUNCTION '|| proname || '(' || pg_catalog.oidvectortypes(proargtypes) || ')' ||  ' to ' || CHR(34) || **`'myusertest'`** ||  CHR(34) || ';'   as qweads FROM pg_proc where proname in(SELECT routine_name FROM information_schema.routines WHERE routine_type = 'FUNCTION' AND specific_schema = 'public')  "  | grep -v '-' | grep -v 'rela' | grep -v 'Name' | grep -v 'rows)' | grep -v 'table_name' | grep -v 'qweads'  > /tmp/funciones.sql %%  psql **`mydbatest`** < /tmp/funciones.sql
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)

###  Asignar todos los permisos en las tablas en todas la bases de datos, versiones  v9.0
select	'\\c ' || datname || ';' || CHR(10) || 'grant select on all tables in schema public to **`"myusertest"`**;'
|| CHR(10) || 'GRANT CONNECT ON DATABASE "'|| datname ||'" TO  **`"myusertest"`**;'  as qweads from pg_database where not datname ilike 'template%' and not datname ilike 'postgres';
<br> [**Regresar al Índice**](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#%C3%ADndice)







--- 

# Mapeo de usuario para permitir que un usuario local acceda a una base de datos remota a través de Foreign Data Wrapper (FDW).
Supongamos que tenemos una base de datos local llamada "mydb" y queremos configurar una conexión FDW para acceder a una base de datos remota en un servidor diferente. A continuación, se muestra cómo podríamos configurar pg_user_mapping para este escenario:


## Creación de la tabla de mapeo de usuario:
Primero, creamos una entrada en la tabla pg_user_mapping. Supongamos que tenemos un usuario local llamado "usuario_local" y queremos mapearlo a un usuario remoto "usuario_remoto" en el servidor remoto con la dirección IP "192.168.1.100". Aquí está el SQL para crear la entrada de mapeo:

```sh
INSERT INTO pg_user_mapping (usename, srvname, umoptions)
VALUES ('usuario_local', 'servidor_remoto', '{"user":"usuario_remoto", "password":"contrasena_remota"}');
```

- `usename:` Es el nombre de usuario local en la base de datos actual.
- `srvname:` Es el nombre del servidor remoto que ya debe estar configurado en PostgreSQL.
- `umoptions:` Aquí especificamos las opciones de mapeo, incluyendo el nombre de usuario remoto y su contraseña para la autenticación en el servidor remoto.


## Hacer que no pida password al autenticarse con FDW
UPDATE pg_user_mapping SET umoptions='{user=my_user , password_required=false}' where umuser=123456


## Configuración del servidor extranjero:

Antes de configurar pg_user_mapping, debes asegurarte de que el servidor extranjero esté configurado en PostgreSQL. Puedes hacerlo utilizando SQL similar al siguiente:

```sh
CREATE SERVER servidor_remoto
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host '192.168.1.100', dbname 'basedatos_remota', port '5432');
```
Esto define el servidor remoto y especifica su dirección IP, el nombre de la base de datos remota y el puerto.

## Creación de una tabla externa:
Una vez que hayas configurado el mapeo de usuario y el servidor remoto, puedes crear una tabla externa en la base de datos local que se relacione con una tabla en la base de datos remota utilizando el Foreign Data Wrapper. Esto permitirá acceder a datos remotos como si estuvieran en la base de datos local.
```sh
CREATE FOREIGN TABLE tabla_externa (
    id integer,
    nombre character varying
)
SERVER servidor_remoto
OPTIONS (table_name 'tabla_remota');
```

Aquí, tabla_externa es una tabla en la base de datos local que se conecta a tabla_remota en el servidor remoto.

Este es un ejemplo básico de cómo configurar pg_user_mapping para permitir que un usuario local acceda a una base de datos remota a través de FDW en PostgreSQL. Ten en cuenta que la seguridad es importante, y en un entorno de producción, deberías asegurarte de que las credenciales de usuario estén protegidas adecuadamente.

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
```sh
SELECT roleid::regrole AS group_name, member::regrole AS member_name FROM pg_auth_members WHERE roleid = 'mi_grupo';
```


### Ejemplos de grupos 
```sh
#Asignación de permisos: Imagina que tienes una base de datos con múltiples tablas y deseas dar a un conjunto de usuarios los mismos permisos en varias tablas. En lugar de otorgar permisos a cada usuario individualmente, puedes crear un grupo y asignar permisos al grupo. Luego, simplemente agregas a los usuarios al grupo y heredarán los permisos del grupo.

-- Crear un grupo y otorgar permisos
CREATE GROUP grupo_ventas;
GRANT SELECT, INSERT, UPDATE ON tabla_ventas TO grupo_ventas;

-- Agregar usuarios al grupo
ALTER ROLE usuario1 IN GROUP grupo_ventas;
ALTER ROLE usuario2 IN GROUP grupo_ventas;


#Control de acceso: Los grupos también se pueden utilizar para controlar el acceso a ciertos recursos de la base de datos. Por ejemplo, puedes restringir el acceso a una aplicación específica a través de un grupo y luego agregar o eliminar usuarios de ese grupo según sea necesario.


-- Crear un grupo para la aplicación de informes
CREATE GROUP app_informes;

-- Otorgar permisos de acceso a la aplicación al grupo
GRANT CONNECT ON DATABASE mydb TO app_informes;

-- Agregar o quitar usuarios de la aplicación del grupo según sea necesario
ALTER ROLE usuario1 IN GROUP app_informes;

``` 
