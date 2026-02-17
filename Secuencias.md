BUSCAR PAR QUE SIRVE currval

# Descripción Rápida de Sequences:
Las Sequences se utilizan para generar valores autoincrementales, como claves primarias en una tabla

[NOTA] --> Los cambios en las secuencias son permanentes y no se ven afectados por las transacciones. Esto es útil para garantizar que los valores generados por secuencias (como identificadores únicos) no se reutilicen, proporcionando consistencia y unicidad en la generación de claves primarias, entre otros usos. 

 por ejemplo Las operaciones de secuencia (NEXTVAL, CURRVAL, SETVAL, etc.) no son transaccionales. Esto significa que los cambios en las secuencias se mantienen incluso si la transacción en la que se realizaron esos cambios se deshace con un ROLLBACK

### Ejemplos de uso:

### Buscar secuencias 
```sql
\ds
select c.relname FROM pg_class c WHERE c.relkind = 'S'; 
SELECT schemaname, sequencename  FROM pg_sequences WHERE schemaname = 'public';
SELECT * FROM information_schema.sequences;
```

### Saber en que valor esta la secuencia 
```sql
select currval('public.test_seq'::regclass);

select sequencename,increment_by,last_value from pg_sequences where sequencename = 'ctl_querys2_id_seq';
```

### Ejecutar una secuencia

```sql

--- al ejecutar la secuencia va aumentar la secuencia que estas ejecutando
select nextval('public.ctl_querys2_id_seq'::regclass);
```

### Crear una secuencia
```sql
CREATE SEQUENCE mi_secuencia START 1 INCREMENT 1;

CREATE SEQUENCE public.ctl_querys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
```

### Consultar información de la secuencias 
```sql
postgres@postgres# select * from public.ctl_querys_id_seq;
+------------+---------+-----------+
| last_value | log_cnt | is_called |
+------------+---------+-----------+
|          1 |       0 | f         |
+------------+---------+-----------+
(1 row)
```

### Asignar una secuencia a una columna 
```sql
CREATE TABLE clientes (
   id_cliente integer DEFAULT nextval('secuencia1') PRIMARY KEY,
   nombre VARCHAR(50),
   apellido VARCHAR(50)
);
```

### Restablecer secuencias 
```sql
-- Supongamos que tienes una secuencia llamada "mi_secuencia" , cuando se ejecute la secuencia empezara desde 10 
ALTER SEQUENCE mi_secuencia RESTART WITH 10;

-- Restablecer la secuencia a un valor predeterminado, no se puede reiniciar a 0
-- Este se usa en caso de haber realizado un delete
-- suponiendo que el id que retorna es 10, entonces cuando se ejecute la secuencia insertara el id 11
SELECT setval('public.mi_secuencia', (SELECT max(id) FROM mi_tabla));

--- Reiniciar la secuencia, desde el valor por defaul por ejemplo si es un primarykey reainicia desde 0
-- Este se usa en caso de haber realizado un truncate
ALTER SEQUENCE mi_secuencia RESTART;

---- Cambiar el incremento de la secuencia:
ALTER SEQUENCE mi_secuencia INCREMENT BY 2;


---- Cambiar el valor máximo y mínimo de la secuencia:
ALTER SEQUENCE mi_secuencia MAXVALUE 1000;
ALTER SEQUENCE mi_secuencia MINVALUE 1;
```

### Reiniciar el ciclo de la secuencia:
Si la secuencia llega al valor máximo (MAXVALUE) o al valor mínimo (MINVALUE), puedes reiniciarla al valor inicial utilizando CYCLE o NO CYCLE. Por ejemplo:
```sql
ALTER SEQUENCE mi_secuencia CYCLE;
```

### eliminar una secuencia 
```sql
DROP SEQUENCE mi_secuencia;
```

 



### ¿Por Qué Monitorear las Secuencias?
Es crucial para asegurar que las secuencias automáticas, como las usadas en columnas de tipo `SERIAL` o `BIGSERIAL`, no se queden sin valores disponibles. Aquí te explico por qué y cómo hacerlo:
```sql
1. **Evitar Desbordamientos**: Las secuencias tienen un límite máximo. Si no se monitorean, pueden alcanzar este límite y causar errores en las inserciones futuras.
2. **Rendimiento**: Monitorear las secuencias puede ayudar a identificar problemas de rendimiento relacionados con la generación de valores únicos.
3. **Consistencia de Datos**: Asegura que los valores generados sean únicos y no se repitan, manteniendo la integridad de los datos.

### ¿Cómo Monitorearlas?
Puedes usar las vistas del sistema y funciones específicas para monitorear las secuencias:

1. **Ver el Estado y Porcentaje  de las Secuencias**:
SELECT
	seqs.relname AS sequence,
	format_type(s.seqtypid, NULL) sequence_datatype,
CONCAT(tbls.relname, '.', attrs.attname) AS owned_by,
	format_type(attrs.atttypid, atttypmod) AS column_datatype,
	pg_sequence_last_value(seqs.oid::regclass) AS last_sequence_value,
TO_CHAR((
	CASE WHEN format_type(s.seqtypid, NULL) = 'smallint' THEN
		(pg_sequence_last_value(seqs.relname::regclass) / 32767::float)
	WHEN format_type(s.seqtypid, NULL) = 'integer' THEN
		(pg_sequence_last_value(seqs.relname::regclass) / 2147483647::float)
	WHEN format_type(s.seqtypid, NULL) = 'bigint' THEN
		(pg_sequence_last_value(seqs.relname::regclass) / 9223372036854775807::float)
	END) * 100, 'fm9999999999999999999990D00%') AS sequence_percent,
TO_CHAR((
	CASE WHEN format_type(attrs.atttypid, NULL) = 'smallint' THEN
		(pg_sequence_last_value(seqs.relname::regclass) / 32767::float)
	WHEN format_type(attrs.atttypid, NULL) = 'integer' THEN
		(pg_sequence_last_value(seqs.relname::regclass) / 2147483647::float)
	WHEN format_type(attrs.atttypid, NULL) = 'bigint' THEN
		(pg_sequence_last_value(seqs.relname::regclass) / 9223372036854775807::float)
	END) * 100, 'fm9999999999999999999990D00%') AS column_percent
FROM
	pg_depend d
	JOIN pg_class AS seqs ON seqs.relkind = 'S'
		AND seqs.oid = d.objid
	JOIN pg_class AS tbls ON tbls.relkind = 'r'
		AND tbls.oid = d.refobjid
	JOIN pg_attribute AS attrs ON attrs.attrelid = d.refobjid
		AND attrs.attnum = d.refobjsubid
	JOIN pg_sequence s ON s.seqrelid = seqs.oid
WHERE
	d.deptype = 'a'
	AND d.classid = 1259;


2. **Ver el Estado**:
SELECT schemaname,sequencename,cycle ,data_type, data_type ,last_value, max_value FROM pg_sequences  where sequencename = 'empleados_id_seq';

3. Secuencia Cíclica:
Si la secuencia está configurada como cíclica (CYCLE), al alcanzar su límite máximo,
la secuencia reiniciará y comenzará desde el valor mínimo definido. Esto permite continuar
 generando valores, pero puede llevar a duplicaciones si no se gestiona adecuadamente.




# Escenario: Secuencia Alcanzando su Límite Máximo

postgres@postgres# CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100)
);
CREATE TABLE
Time: 5.958 ms


postgres@postgres# \d empleados
                                     Table "public.empleados"
+--------+------------------------+-----------+----------+---------------------------------------+
| Column |          Type          | Collation | Nullable |                Default                |
+--------+------------------------+-----------+----------+---------------------------------------+
| id     | integer                |           | not null | nextval('empleados_id_seq'::regclass) |
| nombre | character varying(100) |           |          |                                       |
+--------+------------------------+-----------+----------+---------------------------------------+
Indexes:
    "empleados_pkey" PRIMARY KEY, btree (id)



postgres@postgres# ALTER SEQUENCE empleados_id_seq MAXVALUE 5;
ALTER SEQUENCE
Time: 11.216 ms


postgres@postgres# SELECT * FROM empleados_id_seq;
+------------+---------+-----------+
| last_value | log_cnt | is_called |
+------------+---------+-----------+
|          1 |       0 | f         |
+------------+---------+-----------+
(1 row)


postgres@postgres# \x
Expanded display is on.

postgres@postgres# select * from pg_sequences where sequencename = 'empleados_id_seq';
+-[ RECORD 1 ]--+------------------+
| schemaname    | public           |
| sequencename  | empleados_id_seq |
| sequenceowner | postgres         |
| data_type     | integer          |
| start_value   | 1                |
| min_value     | 1                |
| max_value     | 5                |
| increment_by  | 1                |
| cycle         | f                |
| cache_size    | 1                |
| last_value    | NULL             |
+---------------+------------------+
Time: 0.821 ms


postgres@postgres# select * from information_schema.sequences where sequence_name= 'empleados_id_seq';
+-[ RECORD 1 ]------------+------------------+
| sequence_catalog        | postgres         |
| sequence_schema         | public           |
| sequence_name           | empleados_id_seq |
| data_type               | integer          |
| numeric_precision       | 32               |
| numeric_precision_radix | 2                |
| numeric_scale           | 0                |
| start_value             | 1                |
| minimum_value           | 1                |
| maximum_value           | 5                |
| increment               | 1                |
| cycle_option            | NO               |
+-------------------------+------------------+
Time: 1.234 ms


truncate table empleados RESTART IDENTITY ;


postgres@postgres# INSERT INTO empleados (nombre) VALUES ('Juan'),('Ana') ,('Luis') ,('Maria'),('Carlos');
INSERT 0 5
Time: 1.433 ms



postgres@postgres# select schemaname,sequencename,max_value ,last_value from pg_sequences where last_value   >= max_value ;
+------------+------------------+-----------+------------+
| schemaname |   sequencename   | max_value | last_value |
+------------+------------------+-----------+------------+
| public     | empleados_id_seq |         5 |          5 |
+------------+------------------+-----------+------------+
(1 row)


postgres@postgres# SELECT schemaname,sequencename,cycle ,data_type, data_type ,last_value, max_value FROM pg_sequences  where sequencename = 'empleados_id_seq';
+------------+------------------+-------+-----------+-----------+------------+-----------+
| schemaname |   sequencename   | cycle | data_type | data_type | last_value | max_value |
+------------+------------------+-------+-----------+-----------+------------+-----------+
| public     | empleados_id_seq | f     | integer   | integer   |          5 |         5 |
+------------+------------------+-------+-----------+-----------+------------+-----------+
(1 row)



postgres@postgres# INSERT INTO empleados (nombre) VALUES ('Pedro');
ERROR:  nextval: reached maximum value of sequence "empleados_id_seq" (5)
Time: 0.434 ms

postgres@postgres# ALTER SEQUENCE empleados_id_seq MAXVALUE 1000;
ALTER SEQUENCE
Time: 12.505 ms


postgres@postgres# INSERT INTO empleados (nombre) VALUES ('Pedro');
INSERT 0 1
Time: 1.129 ms
 

postgres@postgres# select * from empleados;
+----+--------+
| id | nombre |
+----+--------+
|  1 | Juan   |
|  2 | Ana    |
|  3 | Luis   |
|  4 | Maria  |
|  5 | Carlos |
|  6 | Pedro  |
+----+--------+
(6 rows)
```


--- 
## 1. El estándar SQL (GENERATED) vs. el "estilo Postgres"

Las secuencias tradicionales vinculadas a una columna mediante `SERIAL` son una implementación propia de Postgres. Por otro lado, `GENERATED ALWAYS AS IDENTITY` sigue el **estándar SQL:2003**.

* **SERIAL:** Crea una secuencia independiente y la vincula de forma algo "floja" a la tabla.
* **IDENTITY:** La secuencia está integrada formalmente en la definición de la columna.

## 2. El problema del "Permiso de Modificación"

`GENERATED` no permite modificar el ID fácilmente. Hay dos sabores para esto:

1. **`GENERATED BY DEFAULT AS IDENTITY`**: Te permite insertar tu propio valor si lo deseas (útil para migraciones), pero si no lo haces, usa la secuencia.
2. **`GENERATED ALWAYS AS IDENTITY`**: Bloquea cualquier intento de insertar un valor manual a menos que uses un comando forzado (`OVERRIDING SYSTEM VALUE`).

**¿Por qué esto es mejor?**
Porque evita errores humanos y de lógica. En un sistema robusto, la **Llave Primaria Subrogada** (el ID) nunca debería ser manipulada manualmente. Si permites que cualquiera inserte IDs a mano en una columna con secuencia, tarde o temprano la secuencia se desincronizará y obtendrás el famoso error:
`duplicate key value violates unique constraint`.

## 3. Gestión de Permisos y Propiedad

Con las secuencias antiguas (`SERIAL`), si querías dar permisos a un usuario para insertar en una tabla, a veces olvidabas darle permisos de `USAGE` sobre la secuencia asociada (que es un objeto aparte).

Con **Identity Columns**:

* La secuencia pertenece 100% a la columna.
* Si borras la columna, la secuencia desaparece.
* Si otorgas permisos sobre la tabla, la gestión de la identidad va incluida de forma más natural.

## 4. Facilidad de Administración

Si intentas copiar una estructura de tabla con `SERIAL`, a veces la secuencia no se copia como esperas o sigue apuntando a la secuencia de la tabla original. Las Identity Columns son mucho más "limpias" al momento de generar scripts de estructura (DDL).



### Tabla Comparativa Rápida

| Característica | SERIAL (Secuencia tradicional) | GENERATED ALWAYS AS IDENTITY |
| --- | --- | --- |
| **Estándar SQL** | No (Propietario de Postgres) | **Sí (Estándar)** |
| **Gestión de Secuencia** | Objeto separado | Integrado en la columna |
| **Protección de Datos** | Fácil de romper accidentalmente | **Alta protección contra inserts manuales** |
| **Limpieza** | Deja objetos "huérfanos" a veces | Muy limpia y vinculada |



### Mi recomendación como experto:

Usa **`GENERATED BY DEFAULT AS IDENTITY`** si necesitas flexibilidad para migraciones de datos (donde ya traes IDs de otro sistema).

Usa **`GENERATED ALWAYS AS IDENTITY`** para aplicaciones nuevas donde quieras garantizar la integridad total de tus llaves primarias y evitar que un desarrollador despistado inserte un ID manualmente y rompa el contador.


 
## 2. ¿Qué hace Postgres "por debajo"? (El funcionamiento interno)

Cuando ejecutas un `GENERATED ALWAYS AS IDENTITY`, Postgres realiza tres acciones automáticas en su motor interno:

### A. Crea un objeto de Secuencia Vinculado

Postgres crea un objeto `SEQUENCE` de forma implícita. A diferencia de las secuencias antiguas, esta secuencia está **fuertemente ligada** a la columna. Si haces un `DROP TABLE`, la secuencia se elimina automáticamente sin dejar "basura" en la base de datos.

### B. Define la Propiedad de "Dependencia"

En las tablas de sistema (específicamente en `pg_depend`), Postgres marca que la secuencia existe *únicamente* para servir a esa columna. Esto es lo que permite que, al hacer un `INSERT`, el motor sepa que debe llamar a `nextval()` internamente.

### C. Activa el "Escudo de Protección" (Check de Sistema)

Aquí es donde ocurre la diferencia real con `SERIAL`. El motor de Postgres añade una validación en el parser de SQL:

* Si el usuario intenta incluir la columna `id` en su `INSERT`, Postgres revisa si la columna es `ALWAYS`.
* Si lo es, lanza un error **antes** de intentar siquiera tocar el disco, protegiendo la integridad del contador.

 
## 3. Comparativa de estructuras internas

Si pudiéramos ver el "esqueleto" de lo que Postgres construye, se vería así:

| Característica | Con `BIGSERIAL` | Con `BIGINT GENERATED ALWAYS` |
| --- | --- | --- |
| **Columna base** | `BIGINT` | `BIGINT` |
| **Default** | `nextval('tabla_id_seq')` | *(Ninguno visible, es interno)* |
| **Propiedad** | Es solo un valor por defecto. | Es una **restricción de identidad**. |
| **Metadatos** | Almacenado en `pg_attrdef`. | Almacenado en `pg_attribute` (attidentity). |
 

```sql

############ IDENTITY ############

GENERATED ALWAYS: El valor se genera automáticamente y no puedes insertar manualmente en esa columna (a menos que uses OVERRIDING SYSTEM VALUE en la consulta).
GENERATED BY DEFAULT: Puedes proporcionar manualmente un valor durante la inserción, y solo se genera automáticamente si no proporcionas uno.

-- drop table empleados; 

CREATE TABLE empleados (
    id INTEGER GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR(100),
    horas_trabajadas INT,
    salario_por_hora DECIMAL(10, 2)
);



-- Inserción normal, PostgreSQL generará automáticamente el valor de 'id'
INSERT INTO empleados (nombre, horas_trabajadas, salario_por_hora) 
VALUES ('Juan Perez', 40, 15.00);

-- Frozando escribir manualmente con OVERRIDING
INSERT INTO empleados (id, nombre, horas_trabajadas, salario_por_hora) 
OVERRIDING SYSTEM VALUE 
VALUES (100, 'Maria Gomez', 35, 18.50);





*********************************************************
 


-- drop table empleados ;
 
CREATE TABLE empleados (
    id BIGINT GENERATED ALWAYS AS IDENTITY (
        START WITH 1000  
        INCREMENT BY 10  
        MINVALUE 1000 
        MAXVALUE 10000
        CYCLE  
    ),
    nombre VARCHAR(100),
    horas_trabajadas INT,
    salario_por_hora DECIMAL(10, 2),

    salario_total DECIMAL(10, 2) GENERATED ALWAYS AS (horas_trabajadas * salario_por_hora) STORED
--- esto lo usa mejor que usar simplemeten "DEFAULT" ya que te permite usar las mismas columnas y en 
-- El uso de STORED se recomienda para las columnas que generan algun calculo por default y esto mejora el rendimiento ya que no tiene que calcular cada vez que se consulta porque lo guardado en disco
-- esto permite  generarle indices 
);


postgres@testnew# \d empleados
                                                             Table "public.empleados"
+------------------+------------------------+-----------+----------+-----------------------------------------------------------------------------+
|      Column      |          Type          | Collation | Nullable |                                   Default                                   |
+------------------+------------------------+-----------+----------+-----------------------------------------------------------------------------+
| id               | bigint                 |           | not null | generated always as identity                                                |
| nombre           | character varying(100) |           |          |                                                                             |
| horas_trabajadas | integer                |           |          |                                                                             |
| salario_por_hora | numeric(10,2)          |           |          |                                                                             |
| salario_total    | numeric(10,2)          |           |          | generated always as ((horas_trabajadas::numeric * salario_por_hora)) stored |
+------------------+------------------------+-----------+----------+-----------------------------------------------------------------------------+





postgres@testnew# SELECT * FROM pg_sequences WHERE schemaname = 'public';
+-[ RECORD 1 ]--+------------------+
| schemaname    | public           |
| sequencename  | empleados_id_seq |
| sequenceowner | postgres         |
| data_type     | integer          |
| start_value   | 100              |
| min_value     | 1                |
| max_value     | 2147483647       |
| increment_by  | 10               |
| cycle         | f                |
| cache_size    | 1                |
| last_value    | NULL             |
+---------------+------------------+


postgres@testnew# select * from empleados_id_seq;
+------------+---------+-----------+
| last_value | log_cnt | is_called |
+------------+---------+-----------+
|        100 |       0 | f         |
+------------+---------+-----------+
(1 row)



select 
is_identity 
,identity_generation 
,identity_start 
,identity_increment 
,identity_maximum 
,identity_minimum 
,identity_cycle 
from information_schema.columns where table_name= 'empleados' and column_name = 'id';




INSERT INTO empleados (nombre, horas_trabajadas, salario_por_hora) VALUES ('Juan Perez', 40, 15.00);
INSERT INTO empleados (nombre, horas_trabajadas, salario_por_hora) VALUES ('Maria Gomez', 35, 18.50);
INSERT INTO empleados (nombre, horas_trabajadas, salario_por_hora) VALUES ('Luis Martinez', 45, 20.00);


postgres@postgres# SELECT * FROM empleados;
+----+---------------+------------------+------------------+---------------+
| id |    nombre     | horas_trabajadas | salario_por_hora | salario_total |
+----+---------------+------------------+------------------+---------------+
|  1 | Juan Perez    |               40 |            15.00 |        600.00 |
|  2 | Maria Gomez   |               35 |            18.50 |        647.50 |
|  3 | Luis Martinez |               45 |            20.00 |        900.00 |
+----+---------------+------------------+------------------+---------------+
(3 rows)





update empleados set salario_total = 100.00  where id = 3;
ERROR:  column "salario_total" can only be updated to DEFAULT
DETAIL:  Column "salario_total" is a generated column.
Time: 0.591 ms


postgres@testnew# insert into empleados(salario_total) values ('647.50');
ERROR:  cannot insert a non-DEFAULT value into column "salario_total"
DETAIL:  Column "salario_total" is a generated column.
Time: 0.452 ms


------------------------------------------------------------------------------------------

-- Caso A: La versión flexible (Ideal para migraciones)
CREATE TABLE productos_migracion (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY,
    nombre TEXT
);

-- Caso B: La versión estricta (Ideal para integridad total)
CREATE TABLE productos_nuevos (
    id BIGINT  GENERATED ALWAYS AS IDENTITY,
    nombre TEXT
);

-- 1. Inserción normal (Postgres genera el ID)
INSERT INTO productos_migracion (nombre) VALUES ('Laptop');

-- 2. Inserción manual (Postgres te permite "saltarte" la secuencia)
INSERT INTO productos_migracion (id, nombre) VALUES (500, 'Monitor Curvo');

-- Ver resultados
SELECT * FROM productos_migracion;


-- 1. Inserción normal (Funciona perfecto)
INSERT INTO productos_nuevos (nombre) VALUES ('Teclado Mecánico');
INSERT INTO productos_nuevos (nombre) VALUES ('PC');

-- 2. Intento de inserción manual (ESTO VA A FALLAR)
INSERT INTO productos_nuevos (id, nombre) VALUES (10, 'Mouse Gamer');



-- Forzando el valor en una columna ALWAYS
INSERT INTO productos_nuevos (id, nombre) 
OVERRIDING SYSTEM VALUE 
VALUES (99, 'Webcam 4K');

SELECT * FROM productos_nuevos;


------------------------------------------------------------------------------------------

https://www.postgresql.org/docs/current/ddl-generated-columns.html

```




 
# Desventajas de Los UUID (Universally Unique Identifiers)  

### 1. **Fragmentación de Índices**
Los UUID son valores aleatorios y no secuenciales, lo que significa que cada nuevo UUID insertado puede ir a cualquier parte del índice. Esto provoca una fragmentación significativa, ya que los índices no pueden mantener una estructura ordenada y eficiente.

### 2. **Localidad de Datos**
Debido a su naturaleza aleatoria, los UUIDs no tienen buena localidad de datos. Esto significa que los datos no se almacenan físicamente cerca unos de otros en el disco, lo que puede llevar a una mayor cantidad de operaciones de entrada/salida (IOPS) y reducir la eficiencia del caché.

### 3. **Tamaño de los UUID**
Los UUID suelen ser más grandes que los identificadores numéricos secuenciales (como los `BIGINT`), ocupando más espacio en los índices y en las tablas. Esto puede aumentar el tamaño total de la base de datos y reducir el rendimiento.

### 4. **Impacto en la Memoria**
La aleatoriedad de los UUIDs puede forzar a los índices a cargar más páginas en la memoria, lo que puede deteriorar la relación de aciertos del caché cuando el tamaño del índice excede la memoria disponible.

### Ejemplo de Problema
En bases de datos como PostgreSQL, los UUIDs pueden causar que los índices de hojas sean igualmente probables de ser golpeados, forzando todo el índice a estar en memoria y afectando negativamente el rendimiento.

### Alternativas
- **Identificadores Secuenciales:** Usar identificadores secuenciales (`AUTO_INCREMENT` o `SERIAL`) puede mejorar la eficiencia de los índices.
- **UUIDs con Timestamp:** Algunos tipos de UUID (como UUID v1) incluyen un componente de timestamp, lo que puede mejorar la localidad de datos y reducir la fragmentación.


 

### ¿Cuál deberías elegir?
 
#### Elija números enteros incrementales si:
- Su aplicación utiliza una única base de datos.
- Prioriza la legibilidad, la simplicidad y el alto rendimiento.
- Tiene requisitos de seguridad moderados.

#### Elija UUID si:
- Estás trabajando con sistemas distribuidos o microservicios.
- La seguridad y la singularidad global son cruciales.
- Su aplicación requiere sincronización o fusión de datos frecuente.

Ref: https://medium.com/databases-in-simple-words/uuid-vs-auto-increment-integer-for-ids-what-you-should-choose-20c9cc968600 
 
