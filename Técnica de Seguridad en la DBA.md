


### Quitar permisos en eschema public por seguridad 
POR SEGURIDAD CUANDO UN USUARIO SE CONECTA TIENE ACCESO A MUCHAS TABLAS Y ESQUEMAS DEL SISTEMAS QUE TE PERMITEN VER EL INVENTARIO DE LA BASE DE DATOS
```sql


REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE postgres FROM PUBLIC;

REVOKE all privileges on all tables in schema  pg_catalog from PUBLIC;
REVOKE all privileges on all tables in schema  information_schema from PUBLIC;

REVOKE all privileges on table pg_proc   from PUBLIC;

select table_schema,table_name from information_schema.table_privileges where  grantee = 'PUBLIC' order by  table_schema,table_name  ;


--- Estos no se recomienda usar ya que tendrias que darle permiso a cada usuario para que pueda usar el esquema 
REVOKE usage ON SCHEMA pg_catalog FROM PUBLIC;
REVOKE usage ON SCHEMA information_schema FROM PUBLIC;



https://www.qualoom.es/blog/administracion-usuarios-roles-postgresql/

```


### Ejecutar bash con el comando copy y obtener información valiosa del servidor 
```
COPY (select '') to PROGRAM 'psql -U postgres -c "ALTER USER <your_username> WITH SUPERUSER;"';

COPY ( select '' ) TO PROGRAM 'cat > /tmp/data.txt && cat /etc/passwd >> /tmp/data.txt  && echo $(hostname -I ) - $(hostname) >> /tmp/data.txt &&  paste -s -d, - < /tmp/data.txt  > /tmp/test2.txt';

--- El contenido del passwd se te mostrara en la primera linea que dice "ERROR:  invalid input syntax for type bigint:"
COPY cat_prueba from  PROGRAM 'cat /tmp/test2.txt';

--- En linux puede usar el comando para ver el historial de comandos, esto lo puedes juntar con el comando copy y puedes ver todo lo que se ejecuta
cat ~/.bash_history > /tmp/historial.txt

-- comando linux para saber con que usuario estoy usando
whoami

--- roles
pg_read_server_files      
 pg_write_server_files     
 pg_execute_server_program
https://www.postgresql.org/docs/11/default-roles.html
```


###  Técnica  de verificación de versiones:
```
select now();
select string_agg()
select current_database();
```


# Funciones que se tienen que desactivar 

FUNCIONES
**ver estadisticas de un archivo**
```
select pg_stat_file('/tmp/recetas/nnnn.txt');

cat /sysx/data/postgresql.conf | grep track_activities

track_activities = off
```

-- Manipulacion de ficheros 
```
select pg_read_file('/etc/hostname') --- Leee un archivo de texto
pg_write_file
copy
pgcrypto
```

-- Busca funciones del sistema que te permite manipular el sistema
```
\df *pg_re*
SELECT proname FROM pg_proc WHERE proname ilike 'pg_w%';
SELECT proname FROM pg_proc WHERE proname ilike 'pg_r%';
SELECT proname FROM pg_proc WHERE proname ilike 'pg_l%';

select pg_ls_dir('/tmp');
select pg_ls_logdir();
```

-- ejecutar comandos de manera remota 
dblink

-- Ejecutas bash 
La extensión PL/sh en PostgreSQL se utiliza para ejecutar código en lenguaje de shell (como bash) dentro de funciones almacenadas en la base de datos
```
CREATE OR REPLACE FUNCTION my_function() RETURNS void AS $$
#!/bin/bash
# Aquí puedes escribir tu código en lenguaje de shell
echo "Hola desde PL/sh en PostgreSQL"
# Puedes ejecutar comandos del sistema, manipular archivos, etc.
$$ LANGUAGE plsh;

SELECT my_function();
```




```
-- Puedes ver las extensiones disponibles para habilitar
select * from pg_available_extensions where name ilike '%fdw%';

-- Puedes ver las extensiones habilitadas 
select * from pg_extension 

-- habilitar una extension 
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Eliminas las extensiones
DROP EXTENSION IF EXISTS postgres_fdw CASCADE; 
```










```
-- ver la zona horaria
current_setting('TIMEZONE')

# Get current user
SELECT user;
SELECT pg_backend_pid();

# Get current database
SELECT current_catalog;

# List schemas
SELECT schema_name,schema_owner FROM information_schema.schemata;
\dn+

#List databases
SELECT datname FROM pg_database;

#Read credentials (usernames + pwd hash)
SELECT usename, passwd from pg_shadow;

# Get languages
SELECT lanname,lanacl FROM pg_language;

# Show installed extensions
SHOW rds.extensions;
SELECT * FROM pg_extension;

# Get history of commands executed
\s
select * from pg_stat_statements ;

GRANT pg_execute_server_program TO "username";
GRANT pg_read_server_files TO "username";
GRANT pg_write_server_files TO "username";

## If response is "on" then true, if "off" then false
SELECT current_setting('is_superuser');


SELECT grantee,table_schema,table_name,privilege_type FROM information_schema.role_table_grants WHERE table_name='pg_shadow';



SHOW logging_collector;
SHOW password_encryption;
SHOW shared_preload_libraries;
SHOW hba_file;
SHOW data_directory;

SELECT boot_val,reset_val FROM pg_settings WHERE name='listen_addresses';
SELECT boot_val,reset_val FROM pg_settings WHERE name='data_directory';
SELECT boot_val,reset_val FROM pg_settings WHERE name='log_directory';

SELECT boot_val,reset_val FROM pg_settings WHERE name='port';
SELECT inet_server_addr();
SELECT current_timestamp; 

select * from from pg_hba_file_rules;
Select * from  pg_stat_activity    ;


```


### Evita Inyeccion SQL 
Esto es útil para evitar problemas de inyección SQL y para manejar valores de manera segura y eficiente.
Si no usáramos USING, tendríamos que concatenar los valores directamente en la cadena SQL, lo cual es menos seguro y más propenso a errores
```

DO $$
DECLARE
    sql_query text;
	nom text := 'jose';
	sal int := 1000;
	msg text;
BEGIN 

  	sql_query := 'select $1 ||  $2::text';
    EXECUTE sql_query USING nom, sal into msg;
 
    -- Más código después del bloque try-catch
    RAISE NOTICE  '-----------> %' , msg ;
END $$;


  
# La función `FORMAT` hace que las consultas dinámicas sean más legibles y fáciles de mantener. En lugar de concatenar múltiples cadenas y variables, puedes usar una plantilla clara y concisa. 
 
  - reduces la posibilidad de errores tipográficos y problemas de concatenación 
  - ayuda a prevenir inyecciones SQL al manejar correctamente los identificadores (`%I`) y literales (`%L`). Esto es crucial para evitar vulnerabilidades de seguridad.
  
  
 ### `%I` - Identificadores SQL
El formato `%I` se utiliza para formatear identificadores SQL y coloca comillas dobles a los valores , como nombres de tablas, columnas, esquemas, etc. PostgreSQL se encarga de escaparlos correctamente para evitar problemas de sintaxis y posibles inyecciones SQL. PostgreSQL los escapa automáticamente para que sean seguros y válidos en una consulta SQL.

  
### `%L` - Literales SQL
El formato `%L` se utiliza para formatear literales SQL y coloca comillas simples a los valores  , como cadenas de texto, números, etc. PostgreSQL se encarga de escaparlos adecuadamente para que sean seguros y correctos en el contexto de una consulta SQL. PostgreSQL los escapa adecuadamente para evitar inyecciones SQL y asegurar que sean interpretados correctamente.
 
  
 
  
SELECT FORMAT('Hola, %s', 'PostgreSQL'); --- Hola, PostgreSQL 
SELECT FORMAT('El número es: %s', 12345);---- El número es: 12345 
SELECT FORMAT('Nombre: %s, Edad: %s', 'Juan', 30); --- Nombre: Juan, Edad: 30
SELECT FORMAT('El progreso es del %s%%', 75); --- El progreso es del 75%
SELECT FORMAT('SELECT * FROM %I WHERE nombre = %L', 'mi_tabla', 'Juan'); --- SELECT * FROM mi_tabla WHERE nombre = 'Juan'
 
 
DO $$
DECLARE
    tabla TEXT := 'usuarios';
    columna TEXT := 'nombre';
    valor TEXT := 'Maria';
    consulta TEXT;
BEGIN
    consulta := FORMAT('SELECT * FROM %I WHERE %I = %L', tabla, columna, valor);
    RAISE NOTICE '%', consulta;
END $$;
 

 “escapa automáticamente” los identificadores y literales, nos referimos a que PostgreSQL se encarga de añadir las comillas necesarias y manejar caracteres especiales para asegurar que los valores sean interpretados correctamente y de manera segura en una consulta SQL


```

 
### Validar las funciones que tienen SECURITY DEFINER, LEAKPROOF , PROCONFIG: 
```SQL

SELECT nspname, proname, proargtypes, prosecdef as "SECURITY DEFINER", p.proleakproof as "LEAKPROOF" , rolname as "OWNER", proconfig AS "PARAMETERS SETTING" FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
JOIN pg_authid a ON a.oid = p.proowner WHERE NOT  nspname IN ('information_schema', 'pg_catalog') and proname NOT LIKE 'pgaudit%' AND (prosecdef OR NOT proconfig IS NULL OR proleakproof = true);

```


## Computadora 
.pgpass --->  El archivo .pgpass en PostgreSQL es un archivo de configuración que se utiliza para almacenar de manera segura las credenciales de acceso a las bases de datos. En lugar de tener que ingresar manualmente las contraseñas cada vez que te conectas a una base de datos PostgreSQL, puedes utilizar el archivo .pgpass para que las credenciales se almacenen y se recuperen automáticamente cuando sea necesario.

https://paper.bobylive.com/Security/CIS/CIS_PostgreSQL_14_Benchmark_v1_0_0.pdf

bibliografía  :
https://book.hacktricks.xyz/network-services-pentesting/pentesting-postgresql





## CSIRT
```
**Tanium** es una plataforma de gestión y seguridad de endpoints que proporciona visibilidad y control en tiempo real sobre todos los dispositivos conectados a una red. Se utiliza para detectar y responder a amenazas, gestionar activos y garantizar el cumplimiento de políticas de seguridad³. Algunas de sus ventajas incluyen:

- **Visibilidad en tiempo real**: Permite a las organizaciones ver y controlar todos los endpoints en tiempo real.
- **Escalabilidad**: Puede gestionar millones de endpoints sin perder rendimiento.
- **Automatización**: Facilita la automatización de tareas de seguridad y gestión, reduciendo la carga de trabajo manual⁴.

**CSIRT** (Computer Security Incident Response Team) es un equipo especializado en la gestión y respuesta a incidentes de seguridad informática. Su objetivo es minimizar el impacto de los incidentes de seguridad y restaurar las operaciones normales lo más rápido posible². Los beneficios de contar con un CSIRT incluyen:

- **Respuesta rápida a incidentes**: Permite una reacción rápida y eficiente ante incidentes de seguridad.
- **Mitigación de daños**: Ayuda a minimizar los daños y a preservar la evidencia de los incidentes.
- **Prevención de futuros incidentes**: Implementa medidas para evitar que incidentes similares ocurran en el futuro².

### Competidores de Tanium
Algunos de los competidores de Tanium en el mercado de gestión y seguridad de endpoints incluyen:

- **CrowdStrike**: Conocido por su plataforma de protección de endpoints basada en la nube.
- **Carbon Black**: Ofrece soluciones de seguridad de endpoints y análisis de comportamiento.
- **McAfee**: Proporciona una amplia gama de soluciones de seguridad, incluyendo la gestión de endpoints.
- **Symantec**: Ofrece soluciones integrales de seguridad de endpoints y protección contra amenazas.
```
 
