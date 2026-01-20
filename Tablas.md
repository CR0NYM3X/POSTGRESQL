# Objetivo:
Aprenderemos todo lo que se puede hacer con una tabla [documentacion oficial para crear tablas](https://www.postgresql.org/docs/current/sql-createtable.html)



### informacion de tabla 
 ```sql
---- saber el tipo de las columnas 
SELECT attname, format_type(atttypid, atttypmod)
FROM pg_attribute
WHERE attrelid = 'empleados'::regclass
AND attnum > 0
AND NOT attisdropped;


select relname as tabla ,
 pg_table_size(c.oid)/(1024*1024) table_size_MB ,
 pg_indexes_size(c.oid) /(1024*1024)  as indexes_size_MB ,
 pg_total_relation_size(c.oid) /(1024*1024)   as total_size_MB
 

,(pg_stat_file(pg_relation_filepath(c.oid))).modification as fecha_creacion ,pg_catalog.pg_get_userbyid( relowner) as Owner ,nspname as schema ,

 reltuples::bigint as cnt_tupas
 ,pg_stat_get_dead_tuples(c.oid)		as tupas_muertas
 ,pg_stat_get_live_tuples(c.oid) 		as tuplas_vivas
	
 ,pg_stat_get_tuples_inserted(c.oid)	as tuplas_insert
 ,pg_stat_get_tuples_updated(c.oid) 	as tuplas_update
 ,pg_stat_get_tuples_deleted(c.oid) 	as tuplas_delete
 ,pg_stat_get_tuples_fetched(c.oid)    as tuplas_recuperadas
 ,pg_stat_get_tuples_returned(c.oid)  as tuplas_retornadas
  
 from pg_class as c  left join pg_namespace as n on n.oid= c.relnamespace where relkind =  'r'  AND relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname NOT LIKE 'pg_%' AND nspname != 'information_schema')  order by pg_total_relation_size(c.oid) desc ;
 ```  

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

--- Crear una tabla sin especificar los type de los campos 
create table public.nombre_de_la_tabla  as select * from my_tabla_test;

---- crear una tabla con un select es igual que el "CREATE con AS "
select * into nombre_de_la_tabla from my_tabla_test;

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

UPDATE employees
SET salary = salary * 1.1
FROM departments
WHERE employees.department_id = departments.id
AND departments.name = 'Sales';


UPDATE employees
SET salary = salary * 1.1
FROM employees e
JOIN departments d ON e.department_id = d.id
WHERE d.name = 'Sales'
AND employees.id = e.id;

Se utiliza un JOIN explícito entre employees y departments en la condición ON e.department_id = d.id
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

# Agregar un Constraint a una columna 
 ``` 
ALTER TABLE usuarios
ADD CONSTRAINT unique_email UNIQUE (email);
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
truncate nombre_de_la_tabla RESTART IDENTITY;  -- esto Elimina toda la informacion de una tabla y tambien reinicia la secuencia.
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


### Tipos de CONSTRAINTS
Los CONSTRAINTS (restricciones) son reglas que se aplican a las columnas de una tabla para asegurar la integridad y validez de los datos
```SQL 
1. **NOT NULL**: Asegura que una columna no pueda tener valores nulos.
   
   CREATE TABLE productos (
       producto_id SERIAL PRIMARY KEY,
       nombre VARCHAR(100) NOT NULL
   );
   

2. **UNIQUE**: Garantiza que todos los valores en una columna sean únicos.
   
   CREATE TABLE usuarios (
       usuario_id SERIAL PRIMARY KEY,
       email VARCHAR(100) UNIQUE
   );
   

3. **PRIMARY KEY**: Combina `NOT NULL` y `UNIQUE`. Identifica de manera única cada fila en una tabla.
   
   CREATE TABLE ordenes (
       orden_id SERIAL PRIMARY KEY,
       fecha DATE NOT NULL
   );
   

4. **FOREIGN KEY**: Asegura la integridad referencial entre dos tablas.
   
   CREATE TABLE detalles_orden (
       detalle_id SERIAL PRIMARY KEY,
       orden_id INT, ---- tambien se puede hacer asi : orden_id INT REFERENCES customers(orden_id)
       producto_id INT,
       CONSTRAINT fk_orden
           FOREIGN KEY(orden_id) 
           REFERENCES ordenes(orden_id),
       CONSTRAINT fk_producto
           FOREIGN KEY(producto_id) 
           REFERENCES productos(producto_id)  MATCH SIMPLE
	        ON UPDATE NO ACTION
	        ON DELETE NO ACTION
   );
   ---- ON UPDATE NO ACTION: si intentas actualizar el valor  PostgreSQL no permitirá la actualización si hay filas , se generará un error y la actualización no se realizará.   Estas restricciones aseguran la integridad referencial, evitando que se queden referencias “rotas” en la tabla que contiene la clave foránea.

5. **CHECK**: Verifica que los valores en una columna cumplan con una condición específica.
   
   CREATE TABLE empleados (
       empleado_id SERIAL PRIMARY KEY,
       salario NUMERIC CHECK (salario > 0)
   );

	ALTER TABLE nombre_de_la_tabla
	ADD CONSTRAINT nombre_de_la_columna_no_vacia CHECK (nombre_de_la_columna <> '');
 
 
6. **EXCLUSION**: Asegura que, para un conjunto de columnas, no haya dos filas que cumplan con una condición específica.
	CREATE TABLE reservas (
		reserva_id SERIAL PRIMARY KEY,
		recurso_id INT,
		periodo TSTZRANGE,
		EXCLUDE USING GIST (recurso_id WITH =, periodo WITH &&)
	);
```

# Restricción de Integridad Referencial (Foreign Key):

La **integridad relacional** (o integridad referencial) es un conjunto de reglas que asegura que las relaciones entre las tablas de una base de datos permanezcan consistentes. Su objetivo principal es evitar "datos huérfanos"; es decir, registros que apuntan a algo que ya no existe.

En PostgreSQL, esto se logra principalmente mediante el uso de **Foreign Keys** (Llaves Foráneas).

 
## Cómo funciona la integridad relacional

Imagina que tienes dos tablas: **Clientes** y **Pedidos**. La integridad relacional garantiza que:

1. No puedas crear un pedido para un cliente que no existe.
2. No puedas borrar a un cliente si todavía tiene pedidos asociados (a menos que decidas borrarlos también en cascada).
3. Si cambias el ID de un cliente, ese cambio se refleje en sus pedidos.

 

## Conceptos clave

* **Primary Key (Llave Primaria):** El identificador único de una fila (ej. `id_cliente`).
* **Foreign Key (Llave Foránea):** Una columna en una tabla que hace referencia a la Llave Primaria de otra tabla (ej. `cliente_id` dentro de la tabla Pedidos).

## Ejemplos prácticos en PostgreSQL

### 1. Creación de tablas con integridad

Aquí definimos que la columna `autor_id` en la tabla `libros` debe existir obligatoriamente en la tabla `autores`.

```sql
CREATE TABLE autores (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL
);

CREATE TABLE libros (
    id SERIAL PRIMARY KEY,
    titulo TEXT NOT NULL,
    autor_id INTEGER REFERENCES autores(id) -- Aquí se establece la integridad
);

```

### 2. Restricción de Inserción

Si intentas ejecutar lo siguiente en una base de datos vacía:

```sql
INSERT INTO libros (titulo, autor_id) VALUES ('Cien años de soledad', 99);

```

**Resultado:** PostgreSQL lanzará un error porque el autor con ID `99` no existe. La integridad relacional bloquea la operación para evitar datos basura.

### 3. Acciones en Cascada (`ON DELETE CASCADE`)

A veces quieres que, si eliminas un autor, se borren automáticamente todos sus libros. Esto se define al crear la llave foránea:

```sql
CREATE TABLE libros (
    id SERIAL PRIMARY KEY,
    titulo TEXT NOT NULL,
    autor_id INTEGER REFERENCES autores(id) ON DELETE CASCADE
);

```

| Acción | Descripción |
| --- | --- |
| **RESTRICT / NO ACTION** | (Por defecto) Impide borrar el registro padre si tiene hijos. |
| **CASCADE** | Borra automáticamente los registros hijos cuando se borra el padre. |
| **SET NULL** | Si el padre se borra, la referencia en el hijo se pone como nula. |
 

## ¿Por qué es importante?

Sin integridad relacional, tu base de datos perdería su fiabilidad rápidamente. Tendrías facturas sin dueño, comentarios en posts que ya no existen o usuarios vinculados a suscripciones inexistentes, lo que causaría errores críticos en cualquier aplicación.

### Acciones de Integridad Referencial

| Acción | Comportamiento al Borrar/Actualizar el Padre | Caso de Uso Típico |
| --- | --- | --- |
| **`NO ACTION`** | Produce un error indicando que la eliminación o actualización viola la restricción. Es el comportamiento por defecto si no especificas nada. | Cuando la seguridad de los datos es crítica y nada debe borrarse si hay dependencias. |
| **`RESTRICT`** | Similar a `NO ACTION`, pero la validación no se puede aplazar al final de una transacción; ocurre inmediatamente. | Para asegurar que no existan cambios temporales que rompan la integridad. |
| **`CASCADE`** | Si se borra el padre, se borran los hijos. Si se actualiza el ID del padre, se actualiza automáticamente en los hijos. | Relaciones fuertes, como un "Post" y sus "Comentarios" o un "Pedido" y sus "Detalles". |
| **`SET NULL`** | Las columnas de la llave foránea en los hijos se ponen en `NULL`. (Requiere que la columna permita nulos). | Cuando quieres conservar el registro hijo pero ya no está asociado al padre (ej. un producto descatalogado). |
| **`SET DEFAULT`** | Las columnas de la llave foránea en los hijos se cambian a su valor por defecto definido. | Cuando quieres reasignar registros huérfanos a un usuario o categoría "Genérica". |
 

### Ejemplo de sintaxis completa

Así es como se ve la implementación de estas acciones al crear una tabla:

```sql
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER,
    -- Definición de la llave foránea con acciones
    CONSTRAINT fk_cliente
        FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id)
        ON DELETE CASCADE    -- Si borro al cliente, borro sus pedidos
        ON UPDATE SET NULL   -- Si cambio el ID del cliente, pongo NULL en pedidos
);

```

### ¿Cuál elegir?

* Usa **`CASCADE`** si el hijo no tiene sentido sin el padre.
* Usa **`SET NULL`** si el hijo debe persistir de forma independiente (como registros históricos).
* Usa **`NO ACTION`** (por defecto) si quieres una protección total contra eliminaciones accidentales.





# MATCH
El parámetro `MATCH` define cómo se comporta PostgreSQL cuando una llave foránea tiene múltiples columnas (llaves compuestas) y alguna de ellas contiene un valor nulo (`NULL`).

 

## Los 3 tipos de MATCH en PostgreSQL

Existen tres variantes principales para manejar la concordancia de llaves foráneas:

### 1. MATCH SIMPLE (El valor por defecto)

Es el que aparece en tu código. Permite que **algunas** de las columnas de la llave foránea sean nulas. Si una de las columnas es `NULL`, PostgreSQL deja de validar la integridad para esa fila específica.

* **Regla:** Si cualquier columna de la llave foránea es nula, se considera que la restricción se cumple (no se busca el valor en la tabla padre).
* **Para qué sirve:** Para permitir registros "huérfanos parciales" donde la relación es opcional.

### 2. MATCH FULL

Es mucho más estricto. No permite mezclar valores con nulos.

* **Regla:** O todas las columnas de la llave foránea son válidas (existen en la tabla padre) o **todas** deben ser `NULL`. No se permite que una columna tenga un ID y la otra sea nula.
* **Para qué sirve:** Para asegurar que la relación sea "todo o nada".

### 3. MATCH PARTIAL

Está definido en el estándar SQL, pero **PostgreSQL no lo soporta actualmente**. Su intención era permitir que, si algunas columnas son nulas, se validaran las que sí tienen valores.

 

## Comparativa con un ejemplo de Llave Compuesta

Imagina una tabla que usa `sucursal_id` y `vendedor_id` como llave para identificar a un empleado.

| Valor en Tabla Hija | MATCH SIMPLE | MATCH FULL |
| --- | --- | --- |
| `(1, 10)` | **Válido** (si existe en padre) | **Válido** (si existe en padre) |
| `(NULL, NULL)` | **Válido** | **Válido** |
| `(1, NULL)` | **Válido** (No verifica nada) | **Error** (No permite mezcla) |

 

## ¿Por qué aparece en tu código?

En tu caso, como `producto_id` es una sola columna:

* Si `producto_id` es `5`, PostgreSQL verifica que el producto 5 exista.
* Si `producto_id` es `NULL`, PostgreSQL simplemente ignora la validación y permite insertar el registro.

En la práctica, la mayoría de los desarrolladores no escriben `MATCH SIMPLE` explícitamente porque es el comportamiento estándar, pero herramientas de modelado de bases de datos (como pgAdmin o DBeaver) lo suelen generar automáticamente al exportar el código SQL.



### Ejemplo columna compuesta 

Esto ocurre cuando para identificar de forma única un registro en la tabla "padre", no basta con una sola columna, sino que se necesita la combinación de dos o más. A esto se le llama **Llave Primaria Compuesta**.

Cuando la tabla "hija" hace referencia a esa combinación, la **Llave Foránea también debe ser compuesta**.

Aquí es donde entra el dilema de los nulos y el `MATCH SIMPLE`.

 
### Ejemplo: Sistema de Inventario por Sucursal

Imagina que tienes una cadena de tiendas. Un producto puede tener el mismo código, pero estar en diferentes sucursales.

#### 1. Tabla Padre: `inventario_sucursal`

Para identificar un lote de productos, necesitas saber la **sucursal** y el **producto**.

| sucursal_id (PK) | producto_id (PK) | stock |
| --- | --- | --- |
| 1 (Norte) | 101 (Camisa) | 50 |
| 2 (Sur) | 101 (Camisa) | 30 |


### Tabla Padre de Referencia: `inventario_sucursal`

Esta tabla es la que une a las sucursales con los productos, permitiendo gestionar el stock específico de cada lugar.

```sql
CREATE TABLE inventario_sucursal (
    sucursal_id INT,
    producto_id INT,
    stock INT DEFAULT 0,
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Definimos la llave primaria compuesta necesaria para la referencia
    PRIMARY KEY (sucursal_id, producto_id)
);

```

### ¿Por qué es necesario esto?

Cuando usas una llave foránea que apunta a dos columnas (`sucursal_ref`, `producto_ref`), SQL exige que la tabla destino tenga una restricción de **UNIQUE** o **PRIMARY KEY** exactamente sobre esas mismas dos columnas.



#### 2. Tabla Hija: `ventas_detalle`

Aquí es donde registras qué vendiste. La llave foránea debe apuntar a ambas columnas para saber de qué sucursal salió el producto.

```sql

CREATE TABLE ventas_detalle (
    venta_id SERIAL PRIMARY KEY,
    sucursal_ref INT,
    producto_ref INT,
    FOREIGN KEY (sucursal_ref, producto_ref) 
        REFERENCES inventario_sucursal (sucursal_id, producto_id)
        MATCH SIMPLE -- <--- Aquí está el detalle
);

```
 


 
### ¿Qué pasa con los valores NULL en este ejemplo?

Si intentas insertar datos en `ventas_detalle`, el comportamiento de `MATCH SIMPLE` será el siguiente:

#### Caso A: Valores completos

`INSERT INTO ventas_detalle (sucursal_ref, producto_ref) VALUES (1, 101);`

* **Resultado:** **Válido**. PostgreSQL busca en la tabla padre si existe la combinación (1, 101). Como existe, lo permite.

#### Caso B: Valores inexistentes

`INSERT INTO ventas_detalle (sucursal_ref, producto_ref) VALUES (1, 999);`

* **Resultado:** **Error**. La combinación (1, 999) no existe en la tabla padre.

#### Caso C: Un valor es NULL (El efecto de MATCH SIMPLE)

`INSERT INTO ventas_detalle (sucursal_ref, producto_ref) VALUES (1, NULL);`

* **Resultado:** **Válido**.
* **¿Por qué?** Porque en `MATCH SIMPLE`, si **al menos una** de las columnas de la llave foránea es `NULL`, PostgreSQL **deja de verificar** la integridad. No le importa que la `sucursal_ref = 1` exista o no; al ver un `NULL`, simplemente "deja pasar" el registro.

 
### ¿Por qué esto puede ser un problema?

Si usas `MATCH SIMPLE`, podrías terminar con filas que tienen una sucursal asignada pero no un producto, o viceversa, rompiendo la lógica de tu negocio.

**Cómo evitarlo:**

1. **Usar `NOT NULL`:** Definir las columnas de la llave foránea como `NOT NULL` para obligar a que siempre haya datos.
2. **Usar `MATCH FULL`:** Si usas `MATCH FULL`, el **Caso C** daría error. Te obligaría a que o ambos sean valores válidos, o ambos sean `NULL`, pero nunca uno sí y el otro no.




 

```sql

******************** CREANDO TABLAS ****************

CREATE TABLE fruit_catalog (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

 
-- RESTRICT : No permitirá la eliminación del registro en la tabla de catálogo si existen registros en la tabla de órdenes que lo referencian.
CREATE TABLE fruit_orders_restrict (
    id SERIAL PRIMARY KEY,
    fruit_id INTEGER REFERENCES fruit_catalog(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL
);


-- CASCADE: Al eliminar un registro en la tabla de catálogo, todos los registros en la tabla de órdenes que lo referencian también serán eliminados.
CREATE TABLE fruit_orders_cascade (
    id SERIAL PRIMARY KEY,
    fruit_id INTEGER REFERENCES fruit_catalog(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL
);


--- SET NULL: Establece los valores referenciados a NULL.
CREATE TABLE fruit_orders_set_null (
    id SERIAL PRIMARY KEY,
    fruit_id INTEGER REFERENCES fruit_catalog(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL
);


--- SET DEFAULT: Al eliminar un registro en la tabla de catálogo, se establecerá un valor por defecto en las columnas correspondientes en la tabla de órdenes.
CREATE TABLE fruit_orders_set_default (
    id SERIAL PRIMARY KEY,
    fruit_id INTEGER DEFAULT 1 REFERENCES fruit_catalog(id) ON DELETE SET DEFAULT ,
    quantity INTEGER NOT NULL
);


--- ON UPDATE,DELETE NO ACTION: Impide actualizaciones que afectarían la integridad referencial.
CREATE TABLE fruit_orders (
    id SERIAL PRIMARY KEY,
    fruit_id INTEGER REFERENCES fruit_catalog(id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
    quantity INTEGER NOT NULL
);


******************** INSERTANDO REGISTROS  ****************

INSERT INTO fruit_catalog (name) VALUES ('Banana'), ('Apple'), ('Orange');

postgres@angel# select * from fruit_catalog;
+----+--------+
| id |  name  |
+----+--------+
|  1 | Banana |
|  2 | Apple  |
|  3 | Orange |
+----+--------+
(3 rows)


 
-- Insertar en la tabla con RESTRICT
INSERT INTO fruit_orders_restrict (fruit_id, quantity) VALUES (1, 10), (2, 20);

-- Insertar en la tabla con CASCADE
INSERT INTO fruit_orders_cascade (fruit_id, quantity) VALUES (1, 10), (3, 30);

-- Insertar en la tabla con SET NULL
INSERT INTO fruit_orders_set_null (fruit_id, quantity) VALUES (2, 15), (3, 25);

-- Insertar en la tabla con SET DEFAULT
INSERT INTO fruit_orders_set_default (fruit_id, quantity) VALUES (3, 35);

INSERT INTO fruit_orders (fruit_id, quantity) VALUES (1, 10), (2, 15), (3, 20);


******************** PRUEBAS ****************

UPDATE fruit_catalog SET id = 4 WHERE id = 1;

1.---------------
DELETE FROM fruit_catalog WHERE id = 1;

postgres@angel# DELETE FROM fruit_catalog WHERE id = 1;
ERROR:  update or delete on table "fruit_catalog" violates foreign key constraint "fruit_orders_restrict_fruit_id_fkey" on table "fruit_orders_restrict"
DETAIL:  Key (id)=(1) is still referenced from table "fruit_orders_restrict".
Time: 0.869 ms


2.---------------
DELETE FROM fruit_catalog WHERE id = 3;


DELETE FROM fruit_catalog WHERE id = 2;
postgres@angel# SELECT *FROM fruit_orders_set_null;
+----+----------+----------+
| id | fruit_id | quantity |
+----+----------+----------+
|  2 |        3 |       25 |
|  1 |     NULL |       15 |
+----+----------+----------+
(2 rows)


3.---------------

DELETE FROM fruit_catalog WHERE id = 3;
postgres@angel# DELETE FROM fruit_catalog WHERE id = 3;
ERROR:  update or delete on table "fruit_catalog" violates foreign key constraint "fruit_orders_fruit_id_fkey" on table "fruit_orders"
DETAIL:  Key (id)=(3) is still referenced from table "fruit_orders".
Time: 0.918 ms

 






******************** BORRANDO  TABLAS ****************
DROP TABLE fruit_catalog CASCADE;
DROP TABLE  fruit_orders_restrict CASCADE;
DROP TABLE  fruit_orders_cascade CASCADE;
DROP TABLE  fruit_orders_set_null CASCADE;
DROP TABLE  fruit_orders_set_default CASCADE;
DROP TABLE  fruit_orders CASCADE;




 
 

 


```

### crear una llave foránea en PostgreSQL
```sql


### Paso 1: Crear las Tablas
Primero, necesitas crear las tablas que estarán relacionadas. Por ejemplo, vamos a crear una tabla `clientes` y una tabla `pedidos`.


CREATE TABLE clientes (
    cliente_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE pedidos (
    pedido_id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    cliente_id INT,
    CONSTRAINT fk_cliente
        FOREIGN KEY(cliente_id) 
        REFERENCES clientes(cliente_id)
);
 

### Paso 2: Insertar Datos en las Tablas
Ahora, vamos a insertar algunos datos en las tablas.
 
INSERT INTO clientes (nombre) VALUES ('Juan Pérez'), ('María López');

INSERT INTO pedidos (fecha, cliente_id) VALUES ('2024-08-08', 1), ('2024-08-09', 2);
 

### Paso 3: Verificar la Relación
Puedes verificar que la relación se ha establecido correctamente consultando las tablas.
 
SELECT * FROM clientes;
SELECT * FROM pedidos;


##### Ejemplo por si ya existe la tabla 

ALTER TABLE pedidos
ADD CONSTRAINT fk_cliente
	FOREIGN KEY (cliente_id) 
	REFERENCES clientes(cliente_id);

--- multiples columnas 
ALTER TABLE fdw_conf.blacklist_server
ADD CONSTRAINT fk_cat_server
	FOREIGN KEY (ip_server, port)
	REFERENCES public.cat_server (ip_server, port);
```




### Tablas `UNLOGGED`

Las tablas `UNLOGGED` son tablas que no generan registros WAL (Write-Ahead Log). Esto las hace mucho más rápidas para operaciones de escritura, pero con algunas desventajas:

- **Ventajas**:
  - **Rendimiento**: Las operaciones de escritura son significativamente más rápidas porque no se generan registros WAL.
  - **Menos Impacto de `VACUUM`**: Menos cambios de `VACUUM` porque no se generan registros WAL.

- **Desventajas**:
  - **No Durabilidad**: Los datos en tablas `UNLOGGED` no son duraderos y se perderán en caso de un fallo del sistema.
  - **No Replicación**: No se pueden usar en réplicas lógicas o físicas.
  - **Truncamiento Automático**: Las tablas se truncan automáticamente después de un fallo del sistema.

```sql
-- Crear una tabla UNLOGGED
CREATE UNLOGGED TABLE table_unlogged (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    valor INT
);

insert into table_unlogged(nombre,valor) select 
    'name'|| (RANDOM() * 1000)::text,
    (RANDOM() * 100)::int
FROM generate_series(1, 10000);



-- Convertir una tabla existente a UNLOGGED
ALTER TABLE table_unlogged SET UNLOGGED;

-- Revertir a LOGGED
ALTER TABLE table_unlogged SET LOGGED;

select * from table_unlogged ; 


select * from information_schema.tables where table_name = 'table_unlogged';  
select * from pg_tables where tablename = 'table_unlogged' ;  

SELECT 
    relname AS table_name,
	relpersistence,
    CASE 
        WHEN relpersistence = 'p' THEN 'Persistent'
        WHEN relpersistence = 'u' THEN 'Unlogged'
        WHEN relpersistence = 't' THEN 'Temporary'
        ELSE 'Unknown'
    END AS table_type
FROM 
    pg_class
WHERE 
    relname= 'table_unlogged' ;
	
```








# Alter con using 

 
Para cambiar una columna de tipo `boolean` a `integer` en PostgreSQL, necesitas especificar cómo se deben convertir los valores booleanos a enteros. Esto se hace utilizando la cláusula `USING`. Aquí tienes cómo puedes hacerlo:

```sql
"ERROR:  column "status" cannot be cast automatically to type integer
HINT:  You might need to specify "USING status::integer". 

ALTER TABLE fdw_conf.cat_dbs
ALTER COLUMN status TYPE integer
USING status::integer;
 

En este caso, `status::integer` convierte los valores `true` y `false` a `1` y `0`, respectivamente¹(https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-change-column-type/)²(https://barcelonageeks.com/postgresql-cambiar-tipo-de-columna/).

Si prefieres especificar manualmente la conversión, puedes usar una expresión más detallada en la cláusula `USING`. Por ejemplo:

 
ALTER TABLE fdw_conf.cat_dbs
ALTER COLUMN status TYPE integer
USING CASE
    WHEN status = true THEN 1
    WHEN status = false THEN 0
    ELSE NULL
END;
 
 
```

----
# Duplicar tabla 
Aquí tienes un ejemplo completo en PostgreSQL donde:

1.  **Creamos una tabla original con datos**.
2.  **Duplicamos la tabla con toda su estructura (índices, restricciones, defaults)**.
3.  **Copiamos los datos a la nueva tabla**.

***

###  Paso 1: Crear la tabla original con datos

```sql
-- Crear tabla original
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) UNIQUE,
    fecha_registro DATE DEFAULT CURRENT_DATE
);

-- Insertar datos de ejemplo
INSERT INTO clientes (nombre, correo)
VALUES
('Juan Pérez', 'juan@example.com'),
('Ana López', 'ana@example.com'),
('Carlos Ruiz', 'carlos@example.com');
```

***

### Paso 2: Duplicar la estructura completa (incluyendo índices y restricciones)

```sql
CREATE TABLE clientes_backup (LIKE clientes INCLUDING ALL);
```

Esto crea `clientes_backup` con:

*   Las mismas columnas.
*   Índices (incluye el `PRIMARY KEY` y el `UNIQUE`).
*   Restricciones (`NOT NULL`).
*   Defaults (`fecha_registro` con `CURRENT_DATE`).

***

###  Paso 3: Copiar los datos

```sql
INSERT INTO clientes_backup SELECT * FROM clientes;
```

Ahora `clientes_backup` tiene la misma estructura y los mismos datos que `clientes`.

 
### 🔍 Verificación rápida

```sql
SELECT * FROM clientes_backup;
```

 

💡 **Tip avanzado:** Si quieres que esto sea **automático y parametrizable**, puedo crearte una **función en PL/pgSQL** que reciba:

*   Nombre de la tabla original.
*   Nombre de la tabla destino.
*   Opción para copiar solo estructura o estructura + datos.
 
