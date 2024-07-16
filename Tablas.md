# Objetivo:
Aprenderemos todo lo que se puede hacer con una tabla [documentacion oficial para crear tablas](https://www.postgresql.org/docs/current/sql-createtable.html)


# saber cuando se creo una tabla
 ```sql 
select (pg_stat_file(pg_relation_filepath('test_fun'))).modification;

 select table_schema,table_name,table_type from information_schema.tables order by table_type;
 ```

# Ejemplos:

###  Información sobre los métodos de acceso disponibles en tu base de datos
 ```sql 
select * from pg_catalog.pg_am;

---- COLUMNAS ---- 
oid: El identificador único (OID) del método de acceso.
amname: El nombre del método de acceso.
amhandler: El manejador (handler) asociado al método de acceso.
amtype: El tipo de método de acceso. En este caso, 't' indica un tipo de método de acceso de tabla (table access method) y
 'i' indica un tipo de método de acceso de índice (index access method).

---- REGISTROS  ---- 
heap: Este es el método de acceso predeterminado utilizado para las tablas almacenadas como heaps,
lo que significa que las filas se almacenan en el orden en que se insertan en la tabla.
btree: Este método de acceso se utiliza para los índices de tipo B-tree, que son muy eficientes
para consultas de igualdad y rangos.
hash: Este método de acceso se utiliza para los índices de tipo hash, que son eficientes para consultas
de igualdad pero no para consultas de rango.
gist: Este método de acceso se utiliza para los índices de tipo GiST (Generalized Search Tree), que
permiten la indexación de tipos de datos no convencionales.
gin: Este método de acceso se utiliza para los índices de tipo GIN (Generalized Inverted Index), que
son útiles para la indexación de arrays y tipos de datos compuestos.
spgist: Este método de acceso se utiliza para los índices de tipo SP-GiST (Space-Partitioned Generalized
Inverted Search Tree), que son similares a los índices GiST pero están diseñados para manejar cargas de trabajo con patrones de consulta específicos.
brin: Este método de acceso se utiliza para los índices de tipo BRIN (Block Range INdexes), que son
eficientes para la indexación de grandes tablas con datos ordenados en bloques.

 ```

## Cambiar la ruta de archivo, donde se guarda la base de datos:
 ```sql
ALTER TABLE my_table SET TABLESPACE my_tablespace;
```

## Saber la cantidad de filas de una tabla
 ```sql

#Para tablas que tienen pocos registros:
select count(*) from my_tabla;

#En caso de que la tabla tenga millones de registros puedes usar la siguiente consulta: 
select relname as tabla,reltuples::bigint as cnt_filas   from pg_class where relname in('my_tabla#1','my_tabla#2') ;
```
## Buscar tablas y saber sus owners :
 ```sql
\dt  'mytabla_de_prueba'
SELECT tableowner,* FROM pg_tables where schemaname = 'public'  and tablename ilike '%mytabla_de_prueba%' ;
SELECT * FROM information_schema.tables WHERE table_schema='public' and table_name ilike  '%mytabla_de_prueba%' ;
```

## Saber el Tamaño de las tablas :
 - **Con esta query puedes ver el tamaño de la tabla:**
 ```sql
SELECT pg_size_pretty(pg_total_relation_size('mytbtest')) AS size;

---- estas funciones retornan el tamaño fisco en bytes por lo que lo puedes dividir por (1024*1024) y tendras
---- el valor en mega 
pg_relation_size('MY_tabla')   --- este puedes ver el tamaño de un indice o de una tabla
pg_table_size('MY_tabla')  --- este puedes ver el tamaño   de una tabla
pg_indexes_size('MY_tabla')   --- este puedes ver el tamaño   de una index
pg_total_relation_size('MY_tabla') --- este puedes ver el tamaño  total = tabla + index


```
- **Con esta query puedes ver el tamaño de la tabla:**
```sql
 \dt+ ctl_configuracion
```

 - **Con esta query puedes ver  el tamaño de la tabla pero mas específico:**
 ```sql
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
 ```sql
\d my_tabla

 select  a.column_name, is_nullable, data_type, udt_name, character_maximum_length, column_default,b.constraint_name  
   FROM information_schema.columns  a  
   left join (SELECT constraint_name,table_name,column_name FROM information_schema.key_column_usage ) b on a.table_name=b.table_name and a.column_name = b.column_name    
where a.table_name= 'mytabla'  order by ordinal_position ;
```

## Crear una tabla :

```sql
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
 ```sql
INSERT INTO nombre_de_la_tabla (nombre, edad) VALUES ('Juan', 30);
 ```

## Actualizar la información de una tabla:
 ```sql
UPDATE nombre_de_la_tabla SET edad = 35 WHERE nombre = 'Juan';
```

## Actualizar la información de una tabla, haciendo la union de una tabla  :
 ```sql
UPDATE tabla1
SET columna1 = valor_nuevo
FROM tabla2
WHERE tabla1.columna_id = tabla2.columna_id
```

## Actualizar la información de una tabla, haciendo la union de dos tabla  :
 ```sql
UPDATE tabla1
SET columna1 = valor_nuevo
FROM tabla2
INNER JOIN tabla3 ON tabla1.columna_id = tabla2.columna_id
WHERE alguna_condicion;
```



## Renombrar una tabla:
 ```sql
alter table my_old_tabla rename to my_new_tabla;
 ```

## Renombrar la columna de una tabla:
 ```sql
ALTER TABLE nombre_de_la_tabla RENAME COLUMN nombre_anterior TO nuevo_nombre;
 ``` 

## Cambiar el tipo de datos de una columna:
 ```sql
ALTER TABLE mi_tabla ALTER COLUMN mi_columna TYPE integer;
 ``` 

## Agregar una restricción a una columna:
 ```sql
ALTER TABLE nombre_de_la_tabla ALTER COLUMN nombre_de_la_columna SET NOT NULL;
 ``` 


## Cambiar de esquema
 ```sql
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
 ```sql

DELETE FROM nombre_de_la_tabla WHERE nombre = 'Juan';  -- este elimina informacion especificamente
truncate nombre_de_la_tabla -- esto Elimina toda la informacion de una tabla.
Delete nombre_de_la_tabla -- esto tambien elimina la informacion pero no es recomendado.
 ```

## Eliminar una columna:
 ```sql
ALTER TABLE mi_tabla DROP COLUMN columna_a_eliminar;
 ```

## Eliminar una tabla
 ```sql
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



### Particionar tablas 
```sql
/* 
--- La logica de PARTITION parace como si hicieramos varias vistas para una tabla y
---  con un simple filtro where en la fecha, pero es mejor que esto: 

#######  Ventajas  ########

1.- Si realizas cambios en una tabla PARTITION surje efecto en la principal, por ejemplo si haces 
un truncate o un update en la tabla ventas_julio_septiembre se hara automáticamente en la tabla ventas

2.- Almacenamiento físico: Con el particionamiento, los datos se almacenan físicamente en tablas separadas, 

3.- Rendimiento: El particionamiento puede mejorar el rendimiento de las consultas al permitir
 que PostgreSQL acceda directamente a la partición relevante en lugar de tener que escanear toda la tabla. 

4.- Mantenimiento y escalabilidad: El particionamiento facilita la administración de datos y
 puede mejorar la escalabilidad al distribuir los datos entre particiones.

*/

-- PASO #1 CREAR LA TABLA PRINCIPAL

CREATE TABLE ventas (
    id SERIAL,
    fecha DATE,
    cantidad INTEGER,
    PRIMARY KEY (fecha, id) -- Asegúrate de incluir la columna de particionamiento en la clave primaria
) PARTITION BY RANGE (fecha);

/* ---- SI NO AGREGAR PRIMARY KEY EN LA FECHA APARECE ESTE ERROR 

ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "ventas" lacks column "fecha" which is part of the partition key.

*/

-- PASO #2 CREAR LA TABLA PARTICIONES 

CREATE TABLE ventas_enero_marzo PARTITION OF ventas
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE ventas_abril_junio PARTITION OF ventas
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE ventas_julio_septiembre PARTITION OF ventas
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE ventas_octubre_diciembre PARTITION OF ventas
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');
	
	-- PASO #3  INSERTAR LA INFORMACIÓN 
	
	INSERT INTO ventas (fecha, cantidad) VALUES
    ('2024-01-15', 100),
    ('2024-03-25', 150),
    ('2024-05-10', 200),
    ('2024-07-02', 180),
    ('2024-09-12', 250),
    ('2024-11-20', 300);
	
/*  --- SI INTENTAS INSERTAR LA INFORMACION ANTES DE CREAR LAS TABLAS PARTICIONES ----
ERROR:  no partition of relation "ventas" found for row
DETAIL:  Partition key of the failing row contains (fecha) = (2024-05-10).
*/
	
	
	-- PASO #4 TEST CONSULTAR 
select * from ventas;
select * from ventas_enero_marzo;
select * from ventas_abril_junio;
select * from ventas_julio_septiembre;
select * from ventas_octubre_diciembre;

	-- PASO #5 TEST DE TRUNCATE
truncate table ventas;
truncate table ventas_enero_marzo;
truncate table ventas_abril_junio;
truncate table ventas_julio_septiembre;
truncate table ventas_octubre_diciembre;

	-- PASO #6 TEST DE DROP TABLAS
drop table ventas_enero_marzo;
drop table ventas_abril_junio;
drop table ventas_julio_septiembre;
drop table ventas_octubre_diciembre;

-- PASO #7  muestra la estructura de particiones de una tabla particionada, incluidas todas las particiones y subparticiones
SELECT * FROM pg_partition_tree('ventas_abril_junio');

```
