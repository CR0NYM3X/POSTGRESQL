Presionar para ir al final[^1].<br>

[Sección 1](#test-contenido)

# Objetivo:
Es aprender a crear usuarios, administrar y asignarle los permisos necesarios para el uso de la base de datos.

# Descripcion rápida de usuarios, Accesos y Permisos:
Es necesario aclarar que las querys pueden variar dependiendo la version de la db<br>
**1.** `Los usuarios` en una base de datos son entidades que permiten a las personas o aplicaciones acceder y trabajar con los datos almacenados en la base de datos. <br>
**2.** `El acceso` se refiere a la forma en que los usuarios y las aplicaciones se conectan y operan en la base de datos. <br>
**3.** `Los permisos` son reglas que determinan qué acciones pueden realizar los usuarios y los roles en la base de datos.

# Ejemplos de uso:

CRUD = Create, Read, Update, Delete


### Formas de Consultar o Buscar un usuario/role
```sh
 \du+ "testuserdba"    -- descripción general
 select * from pg_user where usename ilike '%testuserdba%';  -- descripción general
 select * from pg_roles where rolname ilike '%testuserdba%';  -- Puedes ver el limite de conexiones por usuario en el campo: rolconnlimit
 select * from pg_authid where rolname ilike '%testuserdba%';  -- Puedes ver el limite de conexiones por usuario  en el campo: rolconnlimit
 select * from pg_shadow where usename ilike '%testuserdba%';  -- Aqui puedes ver el hash de la contraseña  
 ```

### Crear un usuario:
```sh
CREATE USER "testuserdba"; -- es lo mismo role que user
CREATE role "testuserdba";  -- es lo mismo role que user
CREATE USER "testuserdba" login VALID UNTIL  '2023-11-15'; --- fecha de expiracion  
CREATE USER testuserdba WITH PASSWORD '123456789'; -- no se recomienda colocar el password en con el create, por que en los log o el historial  puedes ver la contraseña
```

### Comentar un usuario 
```sh
  COMMENT ON ROLE testuserdba IS 'Esta es la descripción del usuario.';
```
 
### Eliminar un usuario 
```sh
 drop user testuserdba;
 drop role testuserdba;
 ```

### Cambiar passowd
```sh
\password testuserdba 
ALTER USER "testuserdba" PASSWORD '12345'
ALTER USER "testuserdba" PASSWORD 'md5a3cc0871123278d59269d85dbbd772893';  
```

### Cambiar la fecha de expiracion:
```sh
ALTER USER "testuserdba" WITH VALID UNTIL '2023-11-11';
```

### Limitar el número de conexion por usuario:
```sh
ALTER USER testuserdba WITH CONNECTION LIMIT 2;
```

### Agregar owner a los objetos  
```sh
ALTER TABLE public.mitablanew OWNER TO testuserdba; 
ALTER DATABASE mydba  OWNER TO testuserdba;
```

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



### Agregar y Quitar super Usuario a un usuario/role
```sh
ALTER user  "sysutileria" WITH SUPERUSER; 
ALTER USER "sysutileria" WITH NOSUPERUSER;

REASSIGN OWNED BY "testuserdba" to postgres; -- Cambiar de owner
REVOKE OWNERSHIP ON DATABASE 'mydbatest' FROM "testuserdba";  -- quita el owner de un usuario en la base de datos mydbatest
```

### Asignar Permisos lógicos a objetos: [Funciones, Tablas, type, view, index, sequence, triggers]:
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

# test contenido
Contenido de la sección 1...

### Revokar o eliminar Permisos a objetos: [Funciones, Tablas, type, view, index, sequence, triggers]:  [^1]

```sh
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

### Asignar Permisos a la base de datos, nivel sistema operativo:
`pg_hba.conf` Este archivo se utiliza para definir las políticas de autenticación y controlar quién puede conectarse a la base de datos, desde dónde pueden conectarse y qué métodos de autenticación deben utilizarse para la conexión. <br>

| TYPE | DATABASE |USER | ADDRESS | METHOD | 
|--------------|--------------|--------------|--------------|--------------|
| host    | mydbatest    | myusertest    | 192.168.1.0/32    | md5   |

### Ver si hay un error en el archivo pg_hba.conf
```sh
select * from pg_hba_file_rules where error is not null; ---- si no muestra registros, todo esta bien, si muestra registros en el campo "line_number" te dira la linea que presenta el error
select * from pg_hba_file_rules  where address  in('10.0.30.5');
select * from pg_hba_file_rules  where user_name in('{testuserdba}');
select * from pg_hba_file_rules  where  database   in('{testuserdba}');
```

---



## Ver todos los privilegios que se tienen en todas las base de datos:



### Asignar permisos de lectura en tablas versiones v8.1 
- `Opción #1`<br>
psql **`mydba`** -c "SELECT 'grant select on table ' || table_name ||   ' to ' || CHR(34) || **`'myusertest'`** ||  CHR(34) || ';' as qweads FROM information_schema.tables WHERE table_schema='public' order by table_name;" | grep -v '-' | grep -v 'rela' | grep -v 'Name' | grep -v 'rows)' | grep -v 'table_name' | grep -v 'qweads'  > /tmp/dbaaplicaciones.sql &&  psql **`mydba`** < /tmp/dbaaplicaciones.sql

- `Opción #2`<br>
psql   **`mydba`**   -c "\dt" | grep -v '-' | grep -v 'rela' | grep -v 'Name' | awk '{print " SELECT ON TABLE "$3 " FROM **`myusertest`**;" }' > /tmp/usuarios.sql && psql snisef < /tmp/usuarios.sql

### Asignar permisos de execución en funciones  psql  v8.1 
 psql **`mydba`** -c "SELECT  'GRANT EXECUTE ON FUNCTION '|| proname || '(' || pg_catalog.oidvectortypes(proargtypes) || ')' ||  ' to ' || CHR(34) || **`'myusertest'`** ||  CHR(34) || ';'   as qweads FROM pg_proc where proname in(SELECT routine_name FROM information_schema.routines WHERE routine_type = 'FUNCTION' AND specific_schema = 'public')  "  | grep -v '-' | grep -v 'rela' | grep -v 'Name' | grep -v 'rows)' | grep -v 'table_name' | grep -v 'qweads'  > /tmp/funciones.sql %%  psql **`mydbatest`** < /tmp/funciones.sql


###  Asignar todos los permisos en las tablas en todas la bases de datos, versiones  v9.0
select	'\\c ' || datname || ';' || CHR(10) || 'grant select on all tables in schema public to **`"myusertest"`**;'
|| CHR(10) || 'GRANT CONNECT ON DATABASE "'|| datname ||'" TO  **`"myusertest"`**;'  as qweads from pg_database where not datname ilike 'template%' and not datname ilike 'postgres';




[^1]: Presionar para ir al inicio 





