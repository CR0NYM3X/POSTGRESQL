# Objetivo:
Aprenderemos todo lo que se puede hacer con una tabla [documentacion oficial para crear tablas](https://www.postgresql.org/docs/current/sql-createtable.html)



# Ejemplos:

## Cambiar la ruta de archivo, donde se guarda la base de datos:
 ```sh
ALTER TABLE my_table SET TABLESPACE my_tablespace;
```

## Saber la cantidad de filas de una tabla
 ```sh

#Para tablas que tienen pocos registros:
select count(*) from my_tabla;

#En caso de que la tabla tenga millones de registros puedes usar la siguiente consulta: 
select relname as tabla,reltuples::bigint as cnt_filas   from pg_class where relname in('my_tabla#1','my_tabla#2') ;
```
## Buscar tablas :
 ```sh
\dt  'mytabla_de_prueba'
SELECT * FROM pg_tables where schemaname = 'public'  and tablename ilike '%mytabla_de_prueba%' ;
SELECT * FROM information_schema.tables WHERE table_schema='public' and table_name ilike  '%mytabla_de_prueba%' ;
```

## Saber el Tamaño de las tablas :
 - **Con esta query puedes ver el tamaño de la tabla:**
 ```sh
SELECT pg_size_pretty(pg_total_relation_size('mytbtest')) AS size;
```
- **Con esta query puedes ver el tamaño de la tabla:**
```sh
 \dt+ ctl_configuracion
```

 - **Con esta query puedes ver  el tamaño de la tabla pero mas específico:**
 ```sh
SELECT schemaname AS table_schema,
relname AS table_name,
pg_size_pretty (pg_total_relation_size(relid)) AS total_size,
pg_size_pretty (pg_relation_size(relid)) AS data_size,
pg_size_pretty (pg_total_relation_size(relid) - pg_relation_size(relid))
AS external_size
FROM pg_catalog.pg_statio_user_tables where relname='asuntos' -- tabla
ORDER BY pg_total_relation_size(relid) DESC,
pg_relation_size(relid) DESC;
```
## Ver el nombre y descripcion de las columnas de una tabla:
 ```sh
\d my_tabla

 select  a.column_name, is_nullable, data_type, udt_name, character_maximum_length, column_default,b.constraint_name  
   FROM information_schema.columns  a  
   left join (SELECT constraint_name,table_name,column_name FROM information_schema.key_column_usage ) b on a.table_name=b.table_name and a.column_name = b.column_name    
where a.table_name= 'mytabla'  order by ordinal_position ;
```

## Crear una tabla :

```sh
CREATE TABLE public.nombre_de_la_tabla (
    id serial PRIMARY KEY,
    nombre VARCHAR (255),
    edad INT
);
```
  - **`public.nombre_de_la_tabla`** colocamos el schema.mi_tabla si no se coloca el esquema por default es el esquema public
  - **`id serial PRIMARY KEY`** *crea una columna llamada "id" que es una clave primaria (primary key) y se incrementa automáticamente (serial) cada vez que se inserta una fila.* <br>
- **`nombre VARCHAR(255)`** *crea una columna llamada "nombre" con un tipo de dato VARCHAR que puede almacenar hasta 255 caracteres.*<br>
- **`edad INT`** *crea una columna llamada "edad" con un tipo de dato INT para almacenar números enteros.
si quieres saber más sobre los tipos de datos puedes consultar la página oficial de [postgresql](https://www.postgresql.org/docs/8.1/datatype.html)*


## Crear una tabla temporal :
Las tablas temporales se utilizan para almacenar datos temporales durante la ejecución de una sesión y se eliminan automáticamente al finalizar la sesión o cuando ya no son necesarias
```
-- Crear una tabla temporal
CREATE TEMP TABLE nombre_de_la_tabla (
    columna1 tipo_de_dato,
    columna2 tipo_de_dato,
    -- Puedes agregar más columnas según tus necesidades
);


CREATE TEMPORARY TABLE mi_tabla_temporal AS
SELECT nombre, edad
FROM personas
WHERE ciudad = 'Nueva York';
```

###  CTE  subconsultas con WITH
 Define subconsultas nombradas y reutilizables dentro de una consulta principal <br>

 [Nota] Los CTE existen solo dentro de la consulta en la que se definen. No se pueden acceder desde fuera de esa consulta ni se mantienen después de la ejecución de la consulta, esto quiere decir que una vez ejecutada las tablas ya no existen 
```
 WITH vers1 AS (
    SELECT version() ver
), 
time123 AS (
    SELECT now() tim2
) 
SELECT * FROM time123; --- me retorna la hora 
```

## Insertar información en una tabla:
 ```sh
INSERT INTO nombre_de_la_tabla (nombre, edad) VALUES ('Juan', 30);
 ```

## Actualizar la información de una tabla:
 ```sh
UPDATE nombre_de_la_tabla SET edad = 35 WHERE nombre = 'Juan';
```

## Renombrar una tabla:
 ```sh
alter table my_old_tabla rename to my_new_tabla;
 ```

## Renombrar la columna de una tabla:
 ```sh
ALTER TABLE nombre_de_la_tabla RENAME COLUMN nombre_anterior TO nuevo_nombre;
 ``` 

## Cambiar el tipo de datos de una columna:
 ```sh
ALTER TABLE mi_tabla ALTER COLUMN mi_columna TYPE integer;
 ``` 

## Agregar una restricción a una columna:
 ```sh
ALTER TABLE nombre_de_la_tabla ALTER COLUMN nombre_de_la_columna SET NOT NULL;
 ``` 


## Cambiar de esquema
 ```sh
ALTER TABLE public.libros SET SCHEMA biblioteca;

crear el esquema y agregarlo
Public, information_schema , pg_catalog

 ```

### Agregar una columna nueva

 ```
ALTER TABLE mi_tabla
ADD COLUMN nueva_columna INTEGER;
 ```

## Eliminar la informacion de una tabla
 ```sh

DELETE FROM nombre_de_la_tabla WHERE nombre = 'Juan';  -- este elimina informacion especificamente
truncate nombre_de_la_tabla -- esto Elimina toda la informacion de una tabla.
Delete nombre_de_la_tabla -- esto tambien elimina la informacion pero no es recomendado.
 ```

## Eliminar una columna:
 ```sh
ALTER TABLE mi_tabla DROP COLUMN columna_a_eliminar;
 ```

## Eliminar una tabla
 ```sh
drop table "mitabla"
```

# info extra


### Ejemplo encriptacion con PG_CRYPTO

- **1.-** CRAR EXTENSION 
```
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

- **2.-** Crea una base de datos si no tienes una 
```
CREATE DATABASE ejemplo_pg_crypto;
```

- **3.-** conecta a esa base de datos: 
```
\c ejemplo_pg_crypto;
```

- **4.-** crea una tabla donde almacenaremos información encriptada:  
```
CREATE TABLE informacion_secreta (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    datos_encriptados BYTEA
);
```

- **5.-**  encriptar y almacenar datos en la tabla   
```
INSERT INTO informacion_secreta (nombre, datos_encriptados)
VALUES (
    'Usuario 1',
    pgp_sym_encrypt('Informacion secreta del Usuario 1', 'mi_password_poderosa')
),
(
    'Usuario 2',
    pgp_sym_encrypt('Informacion secreta del Usuario 2', 'mi_password_poderosa')
),
(
    'Usuario 3',
    pgp_sym_encrypt('Informacion secreta del Usuario 3', 'mi_password_poderosa')
);
```

- **6.-**  Desencriptar datos   
```
SELECT id, nombre, pgp_sym_decrypt(datos_encriptados, 'mi_password_poderosa') AS datos_desencriptados
FROM informacion_secreta;
```
