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

 

### Cambiar passowrd
```sh
\password testuserdba 
ALTER USER "testuserdba" PASSWORD '12345'
ALTER USER "testuserdba" PASSWORD 'md5a3cc0871123278d59269d85dbbd772893';  
```sh

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
ALTER TABLE public.mitablanew OWNER TO testuserdba;<br>
ALTER DATABASE mydba  OWNER TO testuserdba;
```

### Ver privilegios de un usuario:
```sh
select grantee as usuario, table_catalog as DBA,string_agg(privilege_type, ' ') as privilegio
  from information_schema.table_privileges
where grantee= 'testuserdba' group by  grantee,table_catalog  limit 10;
```

### Agregar y Quitar super Usuario a un usuario/role
```sh
ALTER user  "sysutileria" WITH SUPERUSER; 
ALTER USER "sysutileria" WITH NOSUPERUSER;
```

### Asignar Permisos a objetos: [Funciones, Tablas, type, view, index, sequence, triggers]:

`Base de datos`:
```sh
GRANT CONNECT ON DATABASE "tiendavirtual" TO "testuserdba";
grant all privileges on database tu_bd to tu_usuario;
```

`Tablas`:
```sh
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "testuserdba";
grant SELECT, UPDATE, DELETE, INSERT, REFERENCES, TRIGGER, TRUNCATE, RULE on all tables in schema public to "testuserdba";
```

`Sequences`:
```sh
GRANT ALL PRIVILEGES ON ALL sequences IN SCHEMA public TO "testuserdba";
GRANT USAGE ON SEQUENCE nombre_secuencia TO testuserdba; 
```

`Esquemas`:
```sh
GRANT USAGE ON SCHEMA public TO testuserdba;
GRANT USAGE, SELECT ON SEQUENCE mi_secuencia TO testuserdba;
```

`Funciones`:
```sh
grant ALL PRIVILEGES  on all functions in schema public to "testuserdba";
grant execute on all functions in schema public to "testuserdba";
GRANT EXECUTE ON FUNCTION public.fun_obtenercontactoscopiaweb(int, varchar) TO "testuserdba";
```

`Indice`:
```sh
GRANT CREATE ON TABLE mi_tabla TO mi_usuario;
```

`Type`:
```sh
GRANT USAGE ON TYPE mi_tipo_de_dato TO mi_usuario;
```

`View`:
```sh
GRANT SELECT ON mi_vista TO mi_usuario;
```

`trigger`:
```sh
GRANT EXECUTE ON FUNCTION mi_trigger_function() TO mi_usuario;
```

### Revokar o eliminar Permisos a objetos: [Funciones, Tablas, type, view, index, sequence, triggers]:


