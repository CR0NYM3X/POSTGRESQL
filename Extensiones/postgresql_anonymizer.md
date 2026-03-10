# PostgreSQL Anonymizer
Es una extensión diseñada para ocultar o reemplazar información personalmente identificable (PII) o datos sensibles en una base de datos PostgreSQL. Esto es crucial para garantizar la privacidad de los datos y cumplir con regulaciones como GDPR.  

### ¿Para qué sirve PostgreSQL Anonymizer?

1. **Protección de Datos Sensibles**:
   - Oculta o reemplaza PII y datos sensibles para proteger la privacidad de los public.usuarios.
   - Facilita el cumplimiento de regulaciones de privacidad como GDPR.

2. **Compartir Datos de Forma Segura**:
   - Permite crear dumps de bases de datos anonimizados para compartir datos con equipos internos o terceros sin exponer información sensible.

3. **Pruebas y Desarrollo**:
   - Facilita la creación de entornos de prueba y desarrollo con datos realistas pero anonimizados, evitando el uso de datos sensibles en estos entornos.

# 6 métodos  diferentes:


### 1. Anonymous Dumps (Exportación Anónima)

Es como sacar una fotocopia de toda la oficina, pero la fotocopiadora **tacha automáticamente** los nombres antes de que el papel salga por la bandeja.

* **Para qué sirve:** Cuando necesitas enviarle la base de datos a un proveedor externo o a un analista para que trabaje en su propia computadora.
* **Resultado:** Un archivo `.sql` que ya nace "limpio".

### 2. Static Masking (Enmascaramiento Estático)

Aquí no hay copias. Entras a la bóveda original y **borras permanentemente** los datos reales con un marcador negro.

* **Para qué sirve:** Ideal para preparar entornos de **Pre-producción o QA**. Clonas tu base de producción, ejecutas el enmascaramiento estático y listo: ese entorno ya no tiene datos reales que puedan filtrarse.
* **Riesgo:** ¡Cuidado! Si lo haces en producción, pierdes los datos originales para siempre.

### 3. Dynamic Masking (Enmascaramiento Dinámico)

Es un **filtro mágico** en los ojos del usuario. Si un administrador mira la tabla, ve todo. Si un usuario "marcado" mira la misma tabla, el motor de base de datos le muestra asteriscos o nombres falsos en tiempo real.

* **Para qué sirve:** Para que los empleados de soporte vean los datos suficientes para trabajar, pero no la tarjeta de crédito del cliente, **dentro de la misma base de datos activa**.

### 4. Replica Masking (Réplica Anónima)

Imagina que tienes una base de datos secundaria que se sincroniza con la principal. Este método hace que, mientras los datos viajan de la principal a la secundaria, **se transformen** por el camino.

* **Para qué sirve:** Tener un servidor de reportes o "espejo" donde los datos siempre están actualizados pero son 100% anónimos.

### 5. Masking Views (Vistas de Enmascaramiento)

En lugar de tocar las tablas, creas "ventanas" (vistas) especiales. Si miras por la ventana `usuarios_publicos`, ves datos falsos; si miras por la ventana `usuarios_root`, ves los reales.

* **Para qué sirve:** Es una forma ligera y estándar de SQL para exponer datos a aplicaciones sin darles acceso a las tablas base.

### 6. Masking Data Wrappers (Enmascaramiento de Datos Externos)

PostgreSQL puede conectarse a otras bases de datos (Oracle, MySQL, archivos CSV) mediante *Foreign Data Wrappers*. Este método aplica las reglas de anonimato a esos datos que **ni siquiera están en Postgres**.

* **Para qué sirve:** Para consultar una fuente externa (un Excel o un servidor viejo) y asegurarte de que lo que importas ya venga anonimizado desde la conexión.



### Resumen para tu examen o práctica:

| Método | ¿Cambia los datos originales? | ¿Dónde se usa? |
| --- | --- | --- |
| **Anonymous Dump** | No | Para compartir archivos `.sql`. |
| **Static** | **SÍ** | En bases de datos de prueba/QA. |
| **Dynamic** | No | En producción, según el rol del usuario. |
| **Replica** | No (en la fuente) | En servidores de backup o lectura. |
| **Views** | No | Para capas de abstracción en apps. |

 
---

  
### 1. El Flujo de Trabajo: ¿Dónde ocurre la "magia"?

`anon` utiliza una característica nativa de PostgreSQL llamada **Dynamic Masking** basada en el motor de **Vistas (Views)** y el **Search Path**. No es un proxy (como un servidor intermedio), sino que vive dentro del proceso de la base de datos.

#### El "Engaño" del Search Path:

1. **Crea un esquema oculto** (llamado `mask`) que contiene "vistas" con el mismo nombre que tus tablas originales.
2. **Modifica el `search_path**` del usuario. Normalmente, tú buscas en `public`. Al activar `anon`, el sistema te obliga a mirar primero en el esquema `mask`.
3. **Resultado:** Cuando escribes `SELECT * FROM empleado`, no estás consultando la tabla real; estás consultando una **Vista de Enmascaramiento** que `anon` generó automáticamente.
 

---


#### Limitaciones de la anonimización
```
El sistema de enmascaramiento dinámico solo funciona con un esquema (por defecto, público).
Si aplica de 3 a 4 reglas en una tabla, el tiempo de respuesta para los public.usuarios enmascarados es aproximadamente entre un 20% y un 30% más lento que para los public.usuarios normales.
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

-- Permite que los datos sean enmascarados en tiempo real cuando se accede a ellos. Esto es útil para proteger datos sensibles mientras se permite el acceso a public.usuarios con roles específicos
SELECT anon.start_dynamic_masking();

-- Validar el estado de la extensión
SELECT anon.is_initialized();
```

### Paso 6: Crear la tabla `public.usuarios`

Crea una tabla llamada `public.usuarios`:

```sql
CREATE TABLE public.usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    correo VARCHAR(100)
);
```

### Paso 7: Insertar datos en la tabla `public.usuarios`

Inserta algunos datos en la tabla `public.usuarios`:

```sql
INSERT INTO public.usuarios (nombre, correo) VALUES
('Juan Pérez', 'juan.perez@example.com'),
('Ana Gómez', 'ana.gomez@example.com'),
('Luis Martínez', 'luis.martinez@example.com');


postgres@mi_base_de_datos# select * from public.usuarios;
+----+---------------+---------------------------+
| id |    nombre     |          correo           |
+----+---------------+---------------------------+
|  1 | Juan Pérez    | juan.perez@example.com    |
|  2 | Ana Gómez     | ana.gomez@example.com     |
|  3 | Luis Martínez | luis.martinez@example.com |
+----+---------------+---------------------------+


```

### Paso 8: Configurar las reglas de anonimización

Configura las reglas de anonimización para la tabla `public.usuarios` utilizando etiquetas de seguridad:

```sql
SECURITY LABEL FOR anon ON COLUMN public.usuarios.nombre IS 'MASKED WITH FUNCTION anon.fake_last_name()';
SECURITY LABEL FOR anon ON COLUMN public.usuarios.correo IS 'MASKED WITH FUNCTION anon.fake_email()';

-- En caso de ocuparlo
-- SECURITY LABEL FOR anon ON COLUMN public.usuarios.nombre IS 'MASKED WITH VALUE NULL';
```



### Paso 9: Verificar los datos anonimizados

Verifica que los datos en la tabla `public.usuarios` han sido anonimizados:

```sql
\c - mi_usuario

SET client_min_messages=DEBUG;

select * from public.usuarios;

LOG:  statement: select * from public.usuarios;
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


mi_usuario@mi_base_de_datos# select * from public.usuarios;
LOG:  statement: select * from public.usuarios;
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

postgres@mi_base_de_datos# select * from public.usuarios;
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
| relname          | public.usuarios                                   |
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
| relname          | public.usuarios                                   |
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
-- desenmascarar un rol
SECURITY LABEL FOR anon ON ROLE mi_usuario IS NULL;

-- Quitarle parámetros predifinidos
ALTER ROLE mi_usuario RESET search_path;

--  detiene el enmascaramiento dinámico de datos para todos los public.usuarios y sesiones.
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

---


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

http://github.com/google/security-research/security/advisories/GHSA-468r-mhwc-vxjc

https://medium.com/@muhammet.kurtoglu/open-source-data-masking-with-postgresql-99eec468c914
https://docs.yugabyte.com/stable/additional-features/pg-extensions/extension-pganon/

```


---



# Experto en PostgreSQL + Anonimización

Excelente pregunta. La respuesta corta es: **el proceso es el mismo**, pero hay consideraciones importantes cuando trabajas con tablas existentes. Te lo explico en detalle:

---

## ¿Cómo funciona `postgresql_anonymizer`?

La extensión usa **Security Labels** (etiquetas de seguridad) aplicadas a columnas para definir las reglas de enmascaramiento. Esto aplica igual para tablas nuevas o existentes.

---

## Tablas NUEVAS vs Tablas EXISTENTES

### ✅ Tabla Nueva — flujo típico de laboratorio
```sql
-- 1. Crear tabla
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    email TEXT,
    telefono TEXT
);

-- 2. Aplicar etiquetas de anonimización
SECURITY LABEL FOR anon ON COLUMN clientes.nombre
    IS 'MASKED WITH FUNCTION anon.fake_first_name()';

SECURITY LABEL FOR anon ON COLUMN clientes.email
    IS 'MASKED WITH FUNCTION anon.fake_email()';

-- 3. Insertar datos
INSERT INTO clientes VALUES (1, 'Juan Pérez', 'juan@mail.com', '555-1234');
```

---

### ⚠️ Tabla EXISTENTE — lo que cambia

Cuando la tabla ya tiene datos, el proceso de etiquetar es idéntico, pero debes tener cuidado con **3 puntos clave**:

#### 1. Las etiquetas se aplican igual (sin diferencia de sintaxis)
```sql
-- Tabla que ya existe con datos reales
SECURITY LABEL FOR anon ON COLUMN empleados.nombre
    IS 'MASKED WITH FUNCTION anon.fake_first_name()';

SECURITY LABEL FOR anon ON COLUMN empleados.salario
    IS 'MASKED WITH VALUE 0';

SECURITY LABEL FOR anon ON COLUMN empleados.dni
    IS 'MASKED WITH FUNCTION anon.partial(dni, 2, ''****'', 0)';
```

#### 2. Debes inicializar la extensión correctamente
```sql
-- Esto es crítico y a veces se omite en labs
SELECT anon.init();

-- Activar anonimización dinámica
SELECT anon.start_dynamic_masking();
```

#### 3. Los datos originales NO se tocan automáticamente
La extensión tiene **3 modos** — esto es lo que más confunde:

| Modo | ¿Toca datos originales? | Uso ideal |
|------|------------------------|-----------|
| **Dynamic Masking** | ❌ No, crea vistas enmascaradas | Usuarios con rol `masked` ven datos falsos |
| **Static Masking** | ✅ Sí, sobreescribe la tabla | Anonimizar antes de entregar dump |
| **Anonymized Dump** | Genera dump anonimizado | Exportar sin tocar producción |

---

## Flujo completo para tabla existente

```sql
-- 1. Instalar (si no está)
CREATE EXTENSION IF NOT EXISTS anon CASCADE;
SELECT anon.init();

-- 2. Etiquetar columnas de tu tabla existente
SECURITY LABEL FOR anon ON COLUMN empleados.nombre
    IS 'MASKED WITH FUNCTION anon.fake_last_name()';

SECURITY LABEL FOR anon ON COLUMN empleados.email
    IS 'MASKED WITH FUNCTION anon.fake_email()';

-- 3A. OPCIÓN: Enmascaramiento dinámico
-- Crear un rol que solo vea datos enmascarados
CREATE ROLE analista LOGIN PASSWORD 'pass';
SECURITY LABEL FOR anon ON ROLE analista IS 'MASKED';
SELECT anon.start_dynamic_masking();
-- El analista conectado verá datos falsos, tú sigues viendo los reales

-- 3B. OPCIÓN: Enmascaramiento estático (¡IRREVERSIBLE!)
-- Reemplaza los datos reales permanentemente
SELECT anon.anonymize_table('empleados');
-- ó para toda la base:
SELECT anon.anonymize_database();

-- 3C. OPCIÓN: Dump anonimizado (recomendado para producción)
-- Desde terminal:
-- pg_dump_anon -h localhost -U postgres mi_base > dump_anonimizado.sql
```

---

## 🔑 Resumen de diferencias prácticas

| Aspecto | Tabla Nueva | Tabla Existente |
|---|---|---|
| Sintaxis `SECURITY LABEL` | Igual | **Igual** |
| Datos existentes en riesgo | No aplica | ⚠️ Cuidado con modo estático |
| `anon.init()` necesario | Sí | Sí |
| Verificar tipos de dato | No crítico | **Importante** — función debe coincidir con tipo |

---

## ⚠️ Error más común en tablas existentes

```sql
-- Si tu columna es INTEGER y aplicas una función que retorna TEXT:
SECURITY LABEL FOR anon ON COLUMN empleados.edad
    IS 'MASKED WITH FUNCTION anon.fake_first_name()'; -- ❌ Error de tipo

-- Correcto para enteros:
SECURITY LABEL FOR anon ON COLUMN empleados.edad
    IS 'MASKED WITH VALUE 0';
-- o:
    IS 'MASKED WITH FUNCTION anon.random_int_between(20,65)';
```

---

¿Quieres que profundice en alguno de los 3 modos, o tienes una estructura de tabla específica con la que estás trabajando?


........................................................................................................................................








# Enmascaramiento Dinámico — Tus datos originales 100% seguros



Este es exactamente el modo que necesitas: **Dynamic Masking**. Los datos reales **nunca se tocan**.



---



## ¿Qué hace internamente la extensión?



```

┌─────────────────────────────────────────────────────────┐

│ BASE DE DATOS │

│ │

│ tabla: empleados (datos REALES, intactos) │

│ ┌─────────────────────────────────────────┐ │

│ │ id │ nombre │ email │ │

│ │ 1 │ Juan Pérez │ juan@empresa.com │ │

│ │ 2 │ Ana García │ ana@empresa.com │ │

│ └─────────────────────────────────────────┘ │

│ │ │

│ │ La extensión crea automáticamente │

│ ▼ │

│ vista: mask.empleados (datos FALSOS) │

│ ┌─────────────────────────────────────────┐ │

│ │ id │ nombre │ email │ │

│ │ 1 │ Robert Fox │ fake@example.org │ │

│ │ 2 │ Lisa Moore │ other@sample.net │ │

│ └─────────────────────────────────────────┘ │

│ │

│ Usuario ROL NORMAL → ve tabla real │

│ Usuario ROL MASKED → ve solo la vista enmascarada │

└─────────────────────────────────────────────────────────┘

```



---



## Flujo de trabajo completo paso a paso



### PASO 1 — Preparar la extensión

```sql

CREATE EXTENSION IF NOT EXISTS anon CASCADE;

SELECT anon.init(); -- Carga los datos falsos (nombres, emails, etc.)

```



### PASO 2 — Etiquetar las columnas sensibles de tu tabla existente

```sql

-- Tu tabla "empleados" ya existe con datos reales, solo agregas etiquetas

SECURITY LABEL FOR anon ON COLUMN empleados.nombre

    IS 'MASKED WITH FUNCTION anon.fake_first_name()';



SECURITY LABEL FOR anon ON COLUMN empleados.email

    IS 'MASKED WITH FUNCTION anon.fake_email()';



SECURITY LABEL FOR anon ON COLUMN empleados.salario

    IS 'MASKED WITH VALUE 0';

```

> Las etiquetas son **metadata** — no modifican ningún dato, solo describen reglas.



### PASO 3 — Crear el rol que verá los datos enmascarados

```sql

CREATE ROLE analista LOGIN PASSWORD 'password_seguro';



-- Marcar ese rol como "enmascarado"

SECURITY LABEL FOR anon ON ROLE analista IS 'MASKED';



-- Darle acceso a la tabla

GRANT SELECT ON empleados TO analista;

```



### PASO 4 — Activar el enmascaramiento dinámico

```sql

SELECT anon.start_dynamic_masking();

```

> En este momento la extensión crea el schema `mask` y las vistas automáticamente.



### PASO 5 — Verificar que todo funciona

```sql

-- Conéctate como superusuario → ves datos REALES

SELECT nombre, email FROM empleados;

-- Resultado: Juan Pérez | juan@empresa.com ✅ real



-- Conéctate como "analista" → ves datos FALSOS

SELECT nombre, email FROM empleados;

-- Resultado: Robert Fox | fake@example.org ✅ enmascarado

```



---



## Lo que ocurre internamente cuando ejecutas `start_dynamic_masking()`



```

1. Crea el schema "mask" en tu base de datos

       └─→ schema mask {

               vista mask.empleados,

               vista mask.clientes,

               ... (una por cada tabla etiquetada)

           }



2. Cada vista aplica las funciones definidas en SECURITY LABEL

       └─→ CREATE VIEW mask.empleados AS

               SELECT id,

                      anon.fake_first_name() AS nombre,

                      anon.fake_email() AS email,

                      0 AS salario

               FROM public.empleados;



3. Redirige al rol MASKED automáticamente

       └─→ Cuando "analista" hace SELECT en empleados,

           PostgreSQL lo redirige a mask.empleados

           sin que el usuario lo sepa

```



---



## ¿Se necesita algo especial para tablas existentes?



**No.** El proceso es idéntico. Las `SECURITY LABEL` son solo anotaciones que PostgreSQL almacena en el catálogo del sistema. No importa si la tabla tiene 0 o 10 millones de filas — los datos nunca se leen ni modifican al etiquetar.



---



## Comandos útiles de mantenimiento



```sql

-- Ver qué columnas tienen etiquetas aplicadas

SELECT objoid::regclass, label 

FROM pg_seclabel 

WHERE provider = 'anon';



-- Si agregas una nueva columna sensible después

SECURITY LABEL FOR anon ON COLUMN empleados.telefono

    IS 'MASKED WITH FUNCTION anon.fake_phone_number()';

-- Luego refrescar las vistas:

SELECT anon.mask_update();



-- Detener el enmascaramiento dinámico (si algún día lo necesitas)

SELECT anon.stop_dynamic_masking();

```



---



## Garantía de seguridad de tus datos



| Acción | ¿Toca datos originales? |

|---|---|

| `SECURITY LABEL` | ❌ Nunca |

| `anon.init()` | ❌ Nunca |

| `start_dynamic_masking()` | ❌ Nunca |

| Rol `analista` hace SELECT | ❌ Solo lee la vista |

| Tú (superuser) haces SELECT | ✅ Ves datos reales |



¿Tienes ya definida la estructura de tu tabla? Si me la compartes te genero el script exacto listo para ejecutar.



...................................................................................................................................





# ¿Cómo redirige y qué ve el superusuario?



## ¿Cómo hace la redirección?



La magia está en **`search_path`**. PostgreSQL busca los objetos en orden de schemas.



```

Cuando "analista" se conecta, la extensión le asigna:

search_path = mask, public



Entonces cuando ejecuta:

SELECT * FROM empleados;



PostgreSQL busca "empleados" en este orden:

  1. ¿Existe mask.empleados? → ✅ SÍ → usa esa (la vista falsa)

  2. ¿Existe public.empleados? → nunca llega aquí



El usuario nunca supo que fue redirigido.

```



Internamente la extensión hace esto al activar el rol enmascarado:



```sql

-- Lo que anon hace automáticamente al rol "analista"

ALTER ROLE analista SET search_path = mask, public;



-- Por eso cuando analista escribe esto:

SELECT * FROM empleados;



-- PostgreSQL en realidad ejecuta esto:

SELECT * FROM mask.empleados; -- la vista con datos falsos

```



---



## ¿Qué pasa si el analista intenta saltarse la redirección?



```sql

-- Analista intenta acceder directo a la tabla real

SELECT * FROM public.empleados;



-- Resultado: ERROR — permiso denegado

-- Porque el GRANT solo fue sobre "empleados" (que para él es la vista)

-- Nunca tuvo GRANT sobre public.empleados directamente

```



---



## ¿Qué ve el Superusuario?



Aquí viene algo **muy importante** que mucha gente no sabe:



```

┌─────────────────────────────────────────────────┐

│ SUPERUSUARIO │

│ │

│ Su search_path es el normal: │

│ search_path = public │

│ │

│ SELECT * FROM empleados; │

│ └→ busca en public.empleados │

│ └→ ve los datos REALES siempre │

│ │

│ El superusuario NUNCA es redirigido │

│ aunque tenga SECURITY LABEL de MASKED │

└─────────────────────────────────────────────────┘

```



```sql

-- Como superusuario siempre ves esto:

SELECT nombre, email FROM empleados;



-- nombre | email

-- ------------|------------------

-- Juan Pérez | juan@empresa.com ← REAL

-- Ana García | ana@empresa.com ← REAL



-- Incluso si quisieras ver la vista enmascarada,

-- tendrías que ser explícito:

SELECT nombre, email FROM mask.empleados;



-- nombre | email

-- ------------|------------------

-- Robert Fox | fake@example.org ← FALSO

```



---



## Resumen visual del flujo completo



```

┌──────────────┐ search_path = mask, public

│ analista │──────→ SELECT * FROM empleados

└──────────────┘ │

                                ▼

                    Encuentra mask.empleados primero

                                │

                                ▼

                    ┌─────────────────────┐

                    │ Vista enmascarada │ ← datos falsos

                    └─────────────────────┘

                                │

                    (internamente lee public.empleados

                     y aplica las funciones anon.*)

                                │

                                ▼

                    Retorna datos falsos al analista





┌──────────────┐ search_path = public

│ superusuario│──────→ SELECT * FROM empleados

└──────────────┘ │

                                ▼

                    Encuentra public.empleados directo

                                │

                                ▼

                    ┌─────────────────────┐

                    │ Tabla original │ ← datos reales

                    └─────────────────────┘

```



---



## Punto clave de seguridad



| Usuario | search_path | Ve |

|---|---|---|

| `analista` (MASKED) | `mask, public` | Datos falsos |

| `superusuario` | `public` | Datos reales |

| Otro rol sin MASKED | `public` | Datos reales (o error si no tiene GRANT) |



> El enmascaramiento dinámico **no protege contra el superusuario** — es por diseño. Si necesitas ocultar datos incluso al DBA, la solución es **cifrado a nivel de columna**, que es otro tema.



¿Te queda alguna duda sobre el flujo o quieres saber cómo manejar roles intermedios que no son super pero tampoco son masked?
