PostgreSQL Anonymizer es una extensión diseñada para ocultar o reemplazar información personalmente identificable (PII) o datos sensibles en una base de datos PostgreSQL. Esto es crucial para garantizar la privacidad de los datos y cumplir con regulaciones como GDPR.  

### ¿Para qué sirve PostgreSQL Anonymizer?

1. **Protección de Datos Sensibles**:
   - Oculta o reemplaza PII y datos sensibles para proteger la privacidad de los usuarios.
   - Facilita el cumplimiento de regulaciones de privacidad como GDPR.

2. **Compartir Datos de Forma Segura**:
   - Permite crear dumps de bases de datos anonimizados para compartir datos con equipos internos o terceros sin exponer información sensible.

3. **Pruebas y Desarrollo**:
   - Facilita la creación de entornos de prueba y desarrollo con datos realistas pero anonimizados, evitando el uso de datos sensibles en estos entornos.



### Enmascaramiento Dinámico
El enmascaramiento dinámico oculta datos sensibles en tiempo real cuando se accede a ellos desde la base de datos. Los datos originales permanecen intactos, pero los usuarios ven versiones enmascaradas o alteradas según sus permisos.

#### Casos de uso:
1. **Acceso controlado**: Permite a los usuarios acceder a datos sin revelar información sensible, ideal para entornos donde diferentes roles necesitan ver diferentes niveles de detalle.
2. **Seguridad en tiempo real**: Protege los datos sensibles de accesos no autorizados sin necesidad de modificar los datos originales.


### Enmascaramiento Estático
El enmascaramiento estático reemplaza datos  sensibles reales  con información falsa, Este proceso ocurre una vez y   se utilizan para pruebas, desarrollo y análisis.

#### Casos de uso:
1. **Pruebas y desarrollo**: Permite a los desarrolladores y testers trabajar con datos que parecen reales sin comprometer la privacidad.
2. **Compartir datos**: Facilita compartir datos con proveedores, socios y equipos offshore sin exponer información sensible.



---


#### Limitaciones de la anonimización
```
El sistema de enmascaramiento dinámico solo funciona con un esquema (por defecto, público).
Si aplica de 3 a 4 reglas en una tabla, el tiempo de respuesta para los usuarios enmascarados es aproximadamente entre un 20% y un 30% más lento que para los usuarios normales.
La longitud máxima de una regla de enmascaramiento es de 1024 caracteres.
Las reglas de enmascaramiento NO SE HEREDAN ! Si ha dividido una tabla en varias particiones, debe declarar las reglas de enmascaramiento para cada partición.
El enmascaramiento estático destruirá permanentemente sus datos originales.
Enmascarar columnas de identidad es complicado. Si una columna de identidad se define como GENERATED ALWAYS, el enmascaramiento estático no funcionará en ella. Tenga en cuenta que las columnas de identidad se utilizan con mayor frecuencia para claves sustitutas (también conocidas como "claves sin hechos") y, en general, no es necesario enmascarar estas claves. Sin embargo, si realmente necesita enmascarar una columna de identidad, puede redefinirla como GENERATED DEFAULT.

```

#### Requisito Validar si esta habilitado el SELinux
```
postgres@SERVER-TEST /sysx/data $ sestatus 
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   permissive
Mode from config file:          permissive
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33


```
 

#### Requisitos disponibilidad de extensiones pgcrypto y tsm_system_rows
```sql

-- Validar que esten instalados 
select * from pg_available_extensions where name in('tsm_system_rows','pgcrypto');

+-----------------+-----------------+-------------------+------------------------------------------------------------+
|      name       | default_version | installed_version |                          comment                           |
+-----------------+-----------------+-------------------+------------------------------------------------------------+
| pgcrypto        | 1.3             | 1.3               | cryptographic functions                                    |
| tsm_system_rows | 1.0             | 1.0               | TABLESAMPLE method which accepts number of rows as a limit |
+-----------------+-----------------+-------------------+------------------------------------------------------------+
(2 rows)


```

 
# Ejemplos Prácticos


### Paso 1: Crear la base de datos y el usuario

Primero, crea un nuevo usuario y una nueva base de datos:

```sql
-- Conéctate a PostgreSQL como superusuario
psql -p 5412 -U postgres -d postgres

-- Crear un nuevo usuario
CREATE USER mi_usuario WITH PASSWORD 'mi_contraseña';

-- Crear una nueva base de datos
CREATE DATABASE mi_base_de_datos OWNER mi_usuario;

-- Conceder PERMISO PARA QUE SE PUEDA CONETAR a mi_base_de_datos
GRANT CONNECT ON DATABASE mi_base_de_datos TO mi_usuario;


```

### Paso 2: Conectarse a la nueva base de datos

Conéctate a la nueva base de datos y darle permiso al nuevo usuario:

```sh
 \c mi_base_de_datos

--- DARLE PERMISOS DE LECTURA EN TODAS LAS TABLAS
grant select on all tables in schema public to mi_usuario;

```

### Paso 3: Instalar la extensión `anon`

Instala la extensión `anon` y sus dependencias:

```sql
/*Se usa cascade cualquier otra extensión o dependencia requerida por anon también se instale automáticamente.*/
CREATE EXTENSION IF NOT EXISTS anon CASCADE;
```

### Paso 4: Precargar la librería

Configura la base de datos para precargar la librería `anon`:

```sql

--  Configura la base de datos para que la extensión anon esté disponible en todas las sesiones
ALTER DATABASE mi_base_de_datos SET session_preload_libraries = 'anon';

-- [No afecta si no lo ejecuta] - Permite que los datos sensibles sean enmascarados automáticamente y en tiempo real cuando se accede a ellos, sin necesidad de modificar las consultas SQL existentes
--- ALTER DATABASE mi_base_de_datos SET anon.transparent_dynamic_masking TO true;

\c mi_base_de_datos

--  aplicar una etiqueta de seguridad que indica que el rol mi_usuario debe tener acceso a datos enmascarados. verá los datos enmascarados en lugar de los datos originales
SECURITY LABEL FOR anon ON ROLE mi_usuario IS 'MASKED';



```

### Paso 5: Inicializar la extensión

Inicializa la extensión `anon`:

```sql

-- Carga un conjunto de datos predeterminados de datos aleatorios (como nombres, ciudades, etc.) y prepara el sistema para aplicar reglas de enmascaramiento
SELECT anon.init(); 

-- Permite que los datos sean enmascarados en tiempo real cuando se accede a ellos. Esto es útil para proteger datos sensibles mientras se permite el acceso a usuarios con roles específicos
SELECT anon.start_dynamic_masking();

-- Validar el estado de la extensión
SELECT anon.is_initialized();
```

### Paso 6: Crear la tabla `usuarios`

Crea una tabla llamada `usuarios`:

```sql
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    correo VARCHAR(100)
);
```

### Paso 7: Insertar datos en la tabla `usuarios`

Inserta algunos datos en la tabla `usuarios`:

```sql
INSERT INTO usuarios (nombre, correo) VALUES
('Juan Pérez', 'juan.perez@example.com'),
('Ana Gómez', 'ana.gomez@example.com'),
('Luis Martínez', 'luis.martinez@example.com');


postgres@mi_base_de_datos# select * from usuarios;
+----+---------------+---------------------------+
| id |    nombre     |          correo           |
+----+---------------+---------------------------+
|  1 | Juan Pérez    | juan.perez@example.com    |
|  2 | Ana Gómez     | ana.gomez@example.com     |
|  3 | Luis Martínez | luis.martinez@example.com |
+----+---------------+---------------------------+


```

### Paso 8: Configurar las reglas de anonimización

Configura las reglas de anonimización para la tabla `usuarios` utilizando etiquetas de seguridad:

```sql
SECURITY LABEL FOR anon ON COLUMN usuarios.nombre IS 'MASKED WITH FUNCTION anon.fake_last_name()';
SECURITY LABEL FOR anon ON COLUMN usuarios.correo IS 'MASKED WITH FUNCTION anon.fake_email()';

-- En caso de ocuparlo
-- SECURITY LABEL FOR anon ON COLUMN usuarios.nombre IS 'MASKED WITH VALUE NULL';
```



### Paso 9: Verificar los datos anonimizados

Verifica que los datos en la tabla `usuarios` han sido anonimizados:

```sql
\c - mi_usuario

SET client_min_messages=DEBUG;

select * from usuarios;

LOG:  statement: select * from usuarios;
LOG:  duration: 130.909 ms
+----+---------+------------------------+
| id | nombre  |         correo         |
+----+---------+------------------------+
|  1 | Barch   | rapfelav@bloomberg.com |
|  2 | Carmine | jspadottobn@apache.org |
|  3 | Gentle  | gautinl7@newsvine.com  |
+----+---------+------------------------+
(3 rows)


\c - postgres

-------  Se crea el usuario superuser para validar si importa si aun así se anonimizan los datos 
postgres@mi_base_de_datos# alter user mi_usuario with superuser;
ALTER ROLE
Time: 1.112 ms

postgres@mi_base_de_datos# \c - mi_usuario
psql (17.4, server 12.22)
You are now connected to database "mi_base_de_datos" as user "mi_usuario".

 
mi_usuario@mi_base_de_datos# SET client_min_messages=DEBUG;
LOG:  duration: 0.132 ms
SET
Time: 0.246 ms


mi_usuario@mi_base_de_datos# select * from usuarios;
LOG:  statement: select * from usuarios;
LOG:  duration: 129.190 ms
+----+----------+--------------------------+
| id |  nombre  |          correo          |
+----+----------+--------------------------+
|  1 | Godlove  | aburnupg6@gravatar.com   |
|  2 | Golojuch | egardbk@cafepress.com    |
|  3 | Pitcak   | lcoalesz@kickstarter.com |
+----+----------+--------------------------+
(3 rows)

```



### [Cuidado] Remplazar datos originales con las regas.
```sql
-- Reemplaza los datos originales con valores anonimizados de acuerdo con las reglas definidas. Una vez aplicado, los datos originales ya no se pueden recuperar
postgres@mi_base_de_datos# SELECT anon.anonymize_database();
+--------------------+
| anonymize_database |
+--------------------+
| t                  |
+--------------------+
(1 row)

Time: 290.828 ms

postgres@mi_base_de_datos# select * from usuarios;
+----+------------+------------------------+
| id |   nombre   |         correo         |
+----+------------+------------------------+
|  1 | Lesmeister | hjekyll4b@va.gov       |
|  2 | Eeds       | cmarczyk1i@webnode.com |
|  3 | Noth       | jcarpenterk6@desdev.cn |
+----+------------+------------------------+
(3 rows)

``` 

# Reglas de enmascaramiento
``` 
-- mostrar todas las reglas de enmascaramiento declaradas 
SELECT * FROM anon.pg_masking_rules;

+-[ RECORD 1 ]-----+--------------------------------------------+
| attrelid         | 28491                                      |
| attnum           | 2                                          |
| relnamespace     | public                                     |
| relname          | usuarios                                   |
| attname          | nombre                                     |
| format_type      | character varying(100)                     |
| col_description  | MASKED WITH FUNCTION anon.fake_last_name() |
| masking_function | anon.fake_last_name()                      |
| masking_value    | NULL                                       |
| priority         | 100                                        |
| masking_filter   | anon.fake_last_name()                      |
+-[ RECORD 2 ]-----+--------------------------------------------+
| attrelid         | 28491                                      |
| attnum           | 3                                          |
| relnamespace     | public                                     |
| relname          | usuarios                                   |
| attname          | correo                                     |
| format_type      | character varying(100)                     |
| col_description  | MASKED WITH FUNCTION anon.fake_email()     |
| masking_function | anon.fake_email()                          |
| masking_value    | NULL                                       |
| priority         | 100                                        |
| masking_filter   | anon.fake_email()                          |
+------------------+--------------------------------------------+
``` 

 
### Eliminar los ejemplos 
```sql

--  detiene el enmascaramiento dinámico de datos para todos los usuarios y sesiones.
SELECT anon.stop_dynamic_masking();

-- Desactivar la extensión anon, anon en la sesión actual
SELECT anon.unload();

-- desactiva el enmascaramiento de datos para la sesión actual.
select anon.mask_disable();

-- remover todas las reglas 
SELECT anon.remove_masks_for_all_columns();
SELECT anon.remove_masks_for_all_roles();
 

\c postgres postgres
drop DATABASE mi_base_de_datos;
revoke select on all tables in schema public from mi_usuario;
drop user mi_usuario;

SECURITY LABEL FOR anon ON ROLE bob IS NULL;
SECURITY LABEL FOR anon ON ROLE mi_usuario IS NULL;
``` 

### Datos extras 
```

# Crear varias politicas de enmascaramiento en caso de requerirse 
ALTER DATABASE db_test SET anon.masking_policies TO 'devtests, analytics';
SECURITY LABEL FOR devtests ON COLUMN player.name IS 'MASKED WITH FUNCTION anon.fake_last_name()';

```


### Funciones que pueden servir 
``` 
postgres@mi_base_de_datos# select proname from pg_proc JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE nspname = 'anon' and  proname ilike '%fake%';
+------------------------+
|        proname         |
+------------------------+
| fake_first_name        |
| fake_last_name         |
| fake_email             |
| fake_city_in_country   |
| fake_city              |
| fake_region_in_country |
| fake_region            |
| fake_country           |
| fake_company           |
| fake_iban              |
| fake_siren             |
| fake_siret             |
+------------------------+
(12 rows)



postgres@mi_base_de_datos# select proname from pg_proc  JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE nspname = 'anon' and  proname ilike '%random%';
+--------------------------+
|         proname          |
+--------------------------+
| random                   |
| gen_random_bytes         |
| gen_random_uuid          |
| random_string            |
| random_zip               |
| random_date_between      |
| random_date              |
| random_int_between       |
| random_bigint_between    |
| random_phone             |
| random_hash              |
| random_in                |
| random_first_name        |
| random_last_name         |
| random_email             |
| random_city_in_country   |
| random_city              |
| random_region_in_country |
| random_region            |
| random_country           |
| random_company           |
| random_iban              |
| random_siren             |
| random_siret             |
+--------------------------+
(24 rows)


postgres@mi_base_de_datos# select table_type,table_schema,table_name from information_schema.tables where table_schema  = 'anon' order by table_type,table_name;
+------------+--------------+----------------------+
| table_type | table_schema |      table_name      |
+------------+--------------+----------------------+
| BASE TABLE | anon         | city                 |
| BASE TABLE | anon         | company              |
| BASE TABLE | anon         | config               |
| BASE TABLE | anon         | email                |
| BASE TABLE | anon         | first_name           |
| BASE TABLE | anon         | iban                 |
| BASE TABLE | anon         | identifier           |
| BASE TABLE | anon         | identifiers_category |
| BASE TABLE | anon         | last_name            |
| BASE TABLE | anon         | lorem_ipsum          |
| BASE TABLE | anon         | secret               |
| BASE TABLE | anon         | siret                |
| VIEW       | anon         | pg_identifiers       |
| VIEW       | anon         | pg_masked_roles      |
| VIEW       | anon         | pg_masking_rules     |
| VIEW       | anon         | pg_masks             |
+------------+--------------+----------------------+
(16 rows)


-- Las funciones "pseudo" se utiliza para generar datos ficticias pero deterministas. para un mismo valor de entrada, siempre se generará el mismo valor de salida. 
postgres@mi_base_de_datos# select proname from pg_proc  JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE nspname = 'anon' and  proname ilike '%pseudo%';
+-------------------+
|      proname      |
+-------------------+
| pseudo_first_name |
| pseudo_last_name  |
| pseudo_email      |
| pseudo_city       |
| pseudo_region     |
| pseudo_country    |
| pseudo_company    |
| pseudo_iban       |
| pseudo_siren      |
| pseudo_siret      |
+-------------------+
(10 rows)

postgres@mi_base_de_datos# SELECT anon.pseudo_email('example@example.com');
+------------------------------+
|         pseudo_email         |
+------------------------------+
| ahonscha@creativecommons.org |
+------------------------------+
(1 row)



 
### Uso de la función partial(ov , prefix ,  padding , suffix )
- **anon.partial_***: Estas funciones permiten enmascarar parcialmente los datos, por ejemplo, mostrando solo una parte de un número de teléfono o una dirección de correo electrónico  

La función partial tiene los siguientes argumentos:
- ov: El valor original que quieres anonimizar.
- prefix: Número de caracteres del inicio que quieres mantener visibles.
- padding: Texto que quieres usar para reemplazar los caracteres ocultos.
- suffix: Número de caracteres del final que quieres mantener visibles.
 

postgres@mi_base_de_datos#  select proname from pg_proc  JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE nspname = 'anon' and  proname ilike '%partial%';
+---------------+
|    proname    |
+---------------+
| partial       |
| partial_email |
+---------------+

postgres@mi_base_de_datos# SELECT anon.partial('Jose Maria Perez Lopez', 2, '******', 2);
+------------+
|  partial   |
+------------+
| Jo******ez |
+------------+
(1 row)


postgres@mi_base_de_datos# select * from anon.partial_email('example@example.com');
+-----------------------+
|     partial_email     |
+-----------------------+
| ex******@ex******.com |
+-----------------------+
(1 row)




``` 

## Bibliografias
```
https://postgresql-anonymizer.readthedocs.io/en/stable/
https://www.postgresql.org/docs/18/sql-security-label.html

enmascaramiento Dinamico -> https://postgresql-anonymizer.readthedocs.io/en/latest/dynamic_masking/
enmascaramiento estático -> https://postgresql-anonymizer.readthedocs.io/en/latest/static_masking/

https://access.crunchydata.com/documentation/postgresql-anonymizer/latest/install/

# Free 
Anonymization & Data Masking for CloudSQL PostgreSQL -> https://blog.searce.com/anonymization-data-masking-for-cloudsql-postgresql-3f03f8d1099e
Data Anonymization (PostgreSQL) -> https://medium.com/@manasapriyamvadamannava/data-anonymization-postgresql-faacba76dfe0
Data anonymisation in AWS RDS PostgreSQL with AWS DMS & Terraform -> https://medium.com/@dedicatted/data-anonymisation-in-aws-rds-postgresql-with-aws-dms-terraform-049e33ebc0c2

# Payment 
Data Anonymization on AWS for RDS or Aurora PostgreSQL: A Practical Approach Using pgcrypto -> https://medium.com/@shaileshkumarmishra/data-anonymization-on-aws-for-rds-or-aurora-postgresql-a-practical-approach-using-pgcrypto-c243c89d9803

Postgres Security 101: PostgreSQL Settings (6/8) -> https://ozwizard.medium.com/postgres-security-101-postgresql-settings-6-8-889f7c486e2b

```
