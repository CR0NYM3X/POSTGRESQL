# Descripción rápida de los type:
se utilizan para definir nuevos tipos de datos compuestos personalizados. Estos tipos personalizados pueden contener múltiples campos con diferentes tipos de datos
Estos son los tipos que existen <br>
`('integer','date','text','smallint','character varying','character','numeric','bigint')`

 
**Donde se usan los type**
1. Se usa mucho en funciones para definir los parametros o el tipo de dato que va retornar, que se se usa como un arrego 
2. En las columnas de las tablas.



# Ejemplos de uso:

 
1. **Tipo Compuesto**:
   ```sql
   -- Crear el tipo compuesto
   CREATE TYPE my_type AS (x int, y int);

   -- Uso del tipo compuesto con `::`
   SELECT ROW(1, 2)::my_type;
   ```

2. **Tipo de Enumeración**:
   ```sql
   -- Crear el tipo de enumeración
   CREATE TYPE mood AS ENUM ('happy', 'sad', 'neutral');

   -- Uso del tipo de enumeración con `::`
   SELECT 'happy'::mood;
   ```

3. **Tipo de Rango**:
   ```sql
   -- Crear el tipo de rango
   CREATE TYPE int4range AS RANGE (
       subtype = int4
   );

   -- Uso del tipo de rango con `::`
   SELECT '[1,10]'::int4range;
   ```

4. **Tipo de Array**:
   ```sql
   -- Crear el tipo de array (no es necesario crear explícitamente)
   -- Uso del tipo de array con `::`
   SELECT ARRAY[1, 2, 3]::int[];
   ```
 

 


  

# Consultar los type

Con esta query puedes saber el nombre del type y que datos te pide 
```
SELECT 	n.nspname AS esquema,
		t.typname AS tipo_nombre,
       a.attname AS campo_nombre,
       format_type(a.atttypid, a.atttypmod) AS tipo_campo
FROM pg_type t
JOIN pg_attribute a ON a.attrelid = t.typrelid
JOIN pg_namespace n ON t.typnamespace = n.oid
WHERE n.nspname= 'public' 
and t.typname = 'my_name_type'
 order by n.nspname,t.typname  ;

```

# Saber que objeto usa el type
```
#Para saber que tablas  usa el type:
SELECT table_name FROM information_schema.columns WHERE data_type = 'mi_tipo';

#Para saber que Función usa el type:

SELECT
    r.routine_type, -- Este especifica si es una function o un PROCEDURE 
    -- r.specific_name AS function_identifier,
    r.routine_name AS function_name,
    p.parameter_name AS name_parameter,
    p.ordinal_position AS parameter_position,
    p.data_type AS parameter_type,
    CASE
        WHEN p.parameter_mode = 'IN' THEN 'Input'
        WHEN p.parameter_mode = 'OUT' THEN 'Output'
        WHEN p.parameter_mode = 'INOUT' THEN 'Input/Output'
        ELSE 'Unknown'
    END AS parameter_mode,
    r.data_type AS return_type, 
	r.type_udt_name return_type_user
FROM information_schema.routines r
JOIN information_schema.parameters p
    ON r.specific_name = p.specific_name
    AND r.specific_schema = p.specific_schema
WHERE r.specific_schema = 'public'  -- Cambia 'public' al esquema deseado
and ( p.data_type = 'my_type_name' or 
	  r.data_type  =  'my_type_name' or --- si el type fue creado va aparecer USER-DEFINED 
	  r.type_udt_name =  'my_type_name'  )
ORDER BY r.routine_name, p.ordinal_position limit 10;


----------

select proname as funcion,t.typname 
	from pg_proc p 
left join pg_type t on t.oid = p.prorettype 
left join pg_namespace n on p.pronamespace = n.oid 
where n.nspname = 'public'
and  t.typname = 'my_type_name'
limit 1;


```




# Crear un Type
Supongamos que deseamos crear un tipo de datos para representar información de contacto, que incluye el nombre, el número de teléfono y la dirección de correo electrónico.
```
-- Paso 1: Conectarse a la base de datos.

-- Paso 2: Crear un nuevo tipo de datos llamado "tipo_contacto".
CREATE TYPE tipo_contacto AS (
    nombre VARCHAR(100),
    telefono VARCHAR(15),
    email VARCHAR(100)
);

-- Paso 3: Crear una tabla que utiliza el tipo de datos personalizado.
CREATE TABLE contactos (
    id SERIAL PRIMARY KEY,
    detalles_contacto tipo_contacto
);

-- Paso 4: Insertar datos en la tabla.
INSERT INTO contactos (detalles_contacto) VALUES (
    ROW('Juan Pérez', '555-123-4567', 'juan@example.com')
);
INSERT INTO contactos (detalles_contacto) VALUES (
    ROW('Ana Gómez', '555-987-6543', 'ana@example.com')
);

-- Paso 5: Consultar los datos.
SELECT * FROM contactos;

```

# Eliminar un type 
```
DROP TYPE tipo_contacto;
```


# Alter 
```
ALTER TYPE tipo_contacto  ADD ATTRIBUTE direccion VARCHAR(200);

ALTER TABLE nombre_de_la_tabla ALTER COLUMN columna_de_tipo_contacto TYPE tipo_contacto;
```


# info extra
*******  **Busca Type en el inventario** ******
```
 select relkind,relname  from  pg_class   where relname ilike  '%type_nuevo_123%';

----- relkind --- 
 'r' ->  'TABLE'
 'm' -> 'MATERIALIZED_VIEW'
 'i' -> 'INDEX'
 'S' -> 'SEQUENCE'
 'v' -> 'VIEW'
 'c' -> 'TYPE'

 ```




# En PostgreSQL, el espacio que ocupan los caracteres depende de la codificación utilizada, en este ejemplo se usara el UTF-8.

**Caracteres ASCII** (A-Z, a-z, 0-9, y símbolos básicos): Ocupan 2 byte y  longitud 1 , por cada uno.
**Caracteres con Acentos y Diacríticos** (Á, é, ñ, etc.): Generalmente ocupan 3 bytes  y  longitud 2  en UTF-8.
**Caracteres Especiales** (€, ¥, etc.): Pueden ocupar entre 3 o 4 bytes y longitud casi siempre en  dependiendo del carácter específico.


 
### 1. Tipos Numéricos
- **Enteros - Integer (int, int2, int4, int8)**
  - **Límites**:
    - `int2 (Alias: Smallint)`: -32,768 a 32,767
    - `int4 (Alias: int, Integer)`: -2,147,483,648 a 2,147,483,647
    - `int8 (Alias: Bigint)`: -9,223,372,036,854,775,808 a 9,223,372,036,854,775,807
  - **Espacio en memoria**:
    - `smallint`: 2 bytes
    - `integer`: 4 bytes
    - `bigint`: 8 bytes
  - **Desventajas**: Limitados en rango y no adecuados para valores decimales.

- **Secuencias - Serial (serial, bigserial)**
  - **Límites**: Mismos que `integer` y `bigint`.
  - **Espacio en memoria**: Mismos que `integer` y `bigint`.


### Tipos de Punto Flotante (Decimales)

1. **FLOAT4 (REAL)**
   - **Descripción**: Almacena números de punto flotante de precisión simple.
   - **Rango**: Aproximadamente ±1.18e-38 a ±3.4e+38.
   - **Precisión**: Hasta 6 dígitos decimales.
   - **Espacio en Memoria**: 4 bytes.
   - **Desventajas**:
     - Menor precisión con FLOAT8.
     - Puede haber errores de redondeo en operaciones aritméticas debido a la precisión limitada.

2. **FLOAT8 (FLOAT o DOUBLE PRECISION)**
   - **Descripción**: Almacena números de punto flotante de doble precisión.
   - **Rango**: Aproximadamente ±2.23e-308 a ±1.8e+308.
   - **Precisión**: Hasta 15 dígitos decimales.
   - **Espacio en Memoria**: 8 bytes.
   - **Desventajas**:
     - Ocupa más espacio en memoria comparado con FLOAT4.
     - Aunque tiene mayor precisión, todavía puede haber errores de redondeo en operaciones aritméticas.
	 - utilizan más recursos en términos de memoria y rendimiento

3. **Numeric (numeric, decimal) son igual**
  -  sintaxis es NUMERIC(p, s), donde p es la precisión total (el número máximo de dígitos) y s es la escala (el número de dígitos a la derecha del punto decimal).
  - **Límites**: Depende de la precisión especificada.
  - **Espacio en memoria**: Variable, depende de la precisión y escala.
  - **Desventajas**: Más lentos y consumen más espacio en comparación con los enteros.


### 2. Tipos de Caracteres
- **Character (char, varchar, text)**
  - **Límites**:
    - `char(n)`: Fijo a n caracteres.
    - ` character varying(n) `: (Alias: varchar) Hasta n caracteres.
    - `text`: Ilimitado caracteres 1GB.
  - **Espacio en memoria**:
    - `char(n)`: n bytes
    - ` character varying(n)`: generalmente 1 byte para la longitud + 4 bytes de header por fila
    - `text`: Longitud de la cadena + 1 o 4 bytes de sobrecarga
  - **Desventajas**: `char` puede desperdiciar espacio debido a su longitud fija.

### 3. Tipos de Fecha y Hora
- **Date, Time, Timestamp**
  - **Límites**:
    - `date`: 4713 AC a 5874897 DC
    - `timestamp`: 4713 AC a 294276 DC
  - **Espacio en memoria**:
    - `date`: 4 bytes
    - `time`: 8 bytes
    - `timestamp`: 8 bytes
  - **Desventajas**: Complejidad en el manejo de zonas horarias.

### 4. Tipos Booleanos
- **Boolean**
  - **Límites**: `true`, `false`, `NULL`
  - **Espacio en memoria**: 1 byte
  - **Desventajas**: Limitado a verdadero/falso.

### 5. Tipos de Datos Binarios
- **Bytea**
  - **Límites**: Ilimitado.
  - **Espacio en memoria**: Variable, depende del tamaño de los datos.
  - **Desventajas**: Manejo complejo y puede consumir mucho espacio.

### 6. Tipos JSON y XML
- **JSON, JSONB, XML**
  - **Límites**: Ilimitado.
  - **Espacio en memoria**: Variable, depende del tamaño de los datos.
  - **Desventajas**: Más lentos en comparación con tipos nativos.
 
###   Comparativa entre `json` y `jsonb` en PostgreSQL

| 🧩 Característica                  | 📝 `json` (Texto plano)                          | ⚙️ `jsonb` (Binario optimizado)                     |
|-----------------------------------|--------------------------------------------------|-----------------------------------------------------|
| **Formato de almacenamiento**     | Texto tal cual se recibe                         | Binario estructurado y optimizado                   |
| **Validación**                    | Verifica que sea JSON válido                     | También valida, pero lo transforma internamente     |
| **Orden de claves**               | Se conserva exactamente                          | Se pierde (las claves se ordenan internamente)      |
| **Claves duplicadas**             | Se conservan todas                               | Se elimina duplicados, se conserva la última        |
| **Consultas internas**            | Lentas y limitadas                               | Rápidas y eficientes                                |
| **Modificaciones**                | No permite operaciones internas                  | Permite funciones como `jsonb_set`, `||`, `-`       |
| **Indexación**                    | Limitada                                         | Compatible con índices GIN y otros                  |
| **Tamaño de almacenamiento**      | Más pequeño si no se consulta                    | Puede ser más grande por el procesamiento binario   |
| **Operadores disponibles**        | Solo básicos (`->`, `->>`)                       | Todos: `->`, `->>`, `#>`, `#>>`, `@>`, `<@`, `?`, `?|`, `?&`, `||`, `-`, `jsonb_set`, etc. |
| **Uso recomendado**               | Almacenar JSON como texto sin procesar           | Consultas, búsquedas, modificaciones y rendimiento  |



###   ¿Qué significa que **se conservan o se pierden las claves duplicadas**?

En JSON estándar (como el tipo `json` en PostgreSQL), **puedes tener claves duplicadas** en un objeto. Aunque no es recomendable, es técnicamente válido. PostgreSQL con tipo `json` **almacena el texto tal cual**, sin procesarlo, por lo que **sí conserva las claves duplicadas**.

En cambio, el tipo `jsonb` **procesa y normaliza** el JSON al convertirlo en binario. Durante ese proceso, **elimina las claves duplicadas**, conservando **solo la última**.



### 7. Otros Tipos
- **UUID**
  - **Límites**: Ilimitado.
  - **Espacio en memoria**: 16 bytes
  - **Desventajas**: Más grandes que los enteros y pueden ser menos eficientes en términos de rendimiento.

- **Array**
  - **Límites**: Depende del tipo de dato.
  - **Espacio en memoria**: Variable, depende del tamaño y tipo de los elementos.
  - **Desventajas**: Complejidad en consultas y manejo.
 
 

 
 `CHAR` y `VARCHAR` en PostgreSQL:

### `CHAR`

#### Ventajas:
1. **Longitud Fija**: Ideal para datos que siempre tienen la misma longitud, como códigos de país o códigos de producto.
2. **Rendimiento en Comparaciones**: Puede ser ligeramente más rápido en comparaciones debido a la longitud fija.

#### Desventajas:
1. **Espacio Desperdiciado**: Siempre ocupa el espacio definido, incluso si la cadena es más corta, lo que puede resultar en un uso ineficiente del almacenamiento.
2. **Relleno de Espacios**: Las cadenas más cortas se rellenan con espacios en blanco, lo que puede complicar las comparaciones y manipulaciones de datos.

#### Limitaciones:
1. **Flexibilidad**: Menos flexible para datos de longitud variable.
2. **No se Puede Definir sin Longitud**: Siempre requiere una longitud fija, no se puede definir sin especificar `n`.

### `VARCHAR`

#### Ventajas:
1. **Eficiencia en Espacio**: Solo utiliza el espacio necesario para almacenar la cadena más un byte adicional para la longitud.
2. **Flexibilidad**: Ideal para datos de longitud variable, como nombres o descripciones.

#### Desventajas:
1. **Rendimiento en Comparaciones**: Puede ser ligeramente más lento en comparaciones debido a la longitud variable.
2. **Gestión de Longitud**: Si no se define un límite, puede llevar a problemas de gestión de datos si se almacenan cadenas extremadamente largas.

#### Limitaciones:
1. **Longitud Máxima**: Aunque es muy grande, hay un límite teórico en la longitud máxima que puede almacenar.
2. **Sobrecarga de Longitud**: Cada cadena almacena un byte adicional para la longitud, lo que puede ser una ligera sobrecarga en comparación con `CHAR`.

### Espacio y Rendimiento

#### Espacio:
- **`CHAR`**: Siempre ocupa el espacio definido, lo que puede resultar en desperdicio si las cadenas son más cortas. Por ejemplo, `CHAR(50)` siempre ocupará 50 bytes, incluso si solo almacena una cadena de 10 caracteres.
- **`VARCHAR`**: Utiliza solo el espacio necesario para la cadena más un byte adicional para la longitud. Por ejemplo, una cadena de 10 caracteres en `VARCHAR` ocupará 11 bytes.

#### Rendimiento:
- **`CHAR`**: Puede ser más rápido en operaciones de comparación debido a la longitud fija, pero este beneficio es generalmente mínimo y depende del contexto de uso.
- **`VARCHAR`**: Puede ser ligeramente más lento en comparaciones debido a la longitud variable, pero es más eficiente en términos de espacio, lo que puede compensar cualquier pérdida de rendimiento en muchos casos.
 







# Test de tipos de datos 

 ```SQL
CREATE TABLE caracter_char_n 	(  clm varchar(1) );
CREATE TABLE caracter_varchar_n (  clm varchar(1) );
CREATE TABLE caracter_varchar 	(  clm varchar );
CREATE TABLE caracter_text 		(  clm text );

 

postgres@postgres# select	pg_relation_filepath('caracter_char_n') 
		,pg_relation_filepath('caracter_varchar_n')
		,pg_relation_filepath('caracter_varchar')
		,pg_relation_filepath('caracter_text');
 
+----------------------+----------------------+----------------------+----------------------+
| pg_relation_filepath | pg_relation_filepath | pg_relation_filepath | pg_relation_filepath |
+----------------------+----------------------+----------------------+----------------------+
| base/5/449950        | base/5/449953        | base/5/449956        | base/5/449961        |
+----------------------+----------------------+----------------------+----------------------+
(1 row)



postgres@postgres# select 	pg_catalog.pg_relation_size('caracter_char_n')
		,pg_catalog.pg_relation_size('caracter_varchar_n')
		,pg_catalog.pg_relation_size('caracter_varchar')
		,pg_catalog.pg_relation_size('caracter_text');

+------------------+------------------+------------------+------------------+
| pg_relation_size | pg_relation_size | pg_relation_size | pg_relation_size |
+------------------+------------------+------------------+------------------+
|             0 	|             0 	|             0 	|             0 |
+------------------+------------------+------------------+------------------+


postgres@postgres# \q

[postgres@SERVER_TEST 5]$ pwd
/sysx/data16/base/5


[postgres@SERVER_TEST 5]$ ls -lhtr | grep -E '449950|449953|449956|449961'
-rw-------. 1 postgres postgres     0 Sep 23 15:16 449950
-rw-------. 1 postgres postgres     0 Sep 23 15:16 449953
-rw-------. 1 postgres postgres     0 Sep 23 15:16 449956
-rw-------. 1 postgres postgres     0 Sep 23 15:16 449961



[postgres@SERVER_TEST 5]$ psql -p 5416

 


insert into caracter_char_n 	values ('A');
insert into caracter_varchar_n  values ('A');
insert into caracter_varchar 	values ('A');
insert into caracter_text	 	values ('A');


--- bytes , al parecer cuando los creas y le generas los primeros datos , se generan por default con 8KB
postgres@postgres# select 	pg_catalog.pg_relation_size('caracter_char_n')
		,pg_catalog.pg_relation_size('caracter_varchar_n')
		,pg_catalog.pg_relation_size('caracter_varchar')
		,pg_catalog.pg_relation_size('caracter_text');
+------------------+------------------+------------------+------------------+
| pg_relation_size | pg_relation_size | pg_relation_size | pg_relation_size |
+------------------+------------------+------------------+------------------+
|             8192 |             8192 |             8192 |             8192 |
+------------------+------------------+------------------+------------------+
(1 row)


postgres@postgres# \q
[postgres@SERVER_TEST 5]$ ls -lhtr | grep -E '449950|449953|449956|449961'
-rw-------. 1 postgres postgres  8.0K Sep 23 15:24 449950
-rw-------. 1 postgres postgres  8.0K Sep 23 15:24 449953
-rw-------. 1 postgres postgres  8.0K Sep 23 15:24 449956
-rw-------. 1 postgres postgres  8.0K Sep 23 15:24 449961


[postgres@SERVER_TEST 5]$ psql -p 5416


postgres@postgres# SELECT clm, pg_column_size(clm ) AS tamaño_en_bytes, LENGTH(clm  )  AS longitud_caracteres , octet_length(clm)   FROM caracter_char_n;
+-----+-----------------+---------------------+--------------+
| clm | tamaño_en_bytes | longitud_caracteres | octet_length |
+-----+-----------------+---------------------+--------------+
| A   |               2 |                   1 |            1 |
+-----+-----------------+---------------------+--------------+
(1 row)


postgres@postgres# SELECT clm, pg_column_size(clm ) AS tamaño_en_bytes, LENGTH(clm  )  AS longitud_caracteres , octet_length(clm)   FROM caracter_varchar_n;
+-----+-----------------+---------------------+--------------+
| clm | tamaño_en_bytes | longitud_caracteres | octet_length |
+-----+-----------------+---------------------+--------------+
| A   |               2 |                   1 |            1 |
+-----+-----------------+---------------------+--------------+




drop table caracteres ; 
DROP TABLE caracter_char_n 	;
DROP TABLE caracter_varchar_n ;
DROP TABLE caracter_varchar 	;
DROP TABLE caracter_text 		;






-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------



### Paso 1: Crear la Tabla

 
CREATE TABLE caracteres (
    caracter text
);
 


### Insertar datos 
 

---- Paso 2: Insertar Caracteres ASCII
INSERT INTO caracteres (caracter) VALUES 
('A'), ('B'), ('C'), ('D'), ('E'), ('F'), ('G'), ('H'), ('I'), ('J'), ('K'), ('L'), ('M'), ('N'), ('O'), ('P'), ('Q'), ('R'), ('S'), ('T'), ('U'), ('V'), ('W'), ('X'), ('Y'), ('Z'),
('a'), ('b'), ('c'), ('d'), ('e'), ('f'), ('g'), ('h'), ('i'), ('j'), ('k'), ('l'), ('m'), ('n'), ('o'), ('p'), ('q'), ('r'), ('s'), ('t'), ('u'), ('v'), ('w'), ('x'), ('y'), ('z'),
('0'), ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'), ('8'), ('9'),
(' '), ('!'), ('"'), ('#'), ('$'), ('%'), ('&'), ('''') , ('('), (')'), ('*'), ('+'), (','), ('-'), ('.'), ('/'), (':'), (';'), ('<'), ('='), ('>'), ('?'), ('@'), ('['), ('\'), (']'), ('^'), ('_'), ('`'), ('{'), ('|'), ('}'), ('~');

 
--- Paso 3: Insertar Caracteres con Acentos y Diacríticos 
INSERT INTO caracteres (caracter) VALUES 
('Á'), ('É'), ('Í'), ('Ó'), ('Ú'), ('Ü'), ('Ñ'),
('á'), ('é'), ('í'), ('ó'), ('ú'), ('ü'), ('ñ');


--- Paso 4: Insertar Caracteres Especiales
INSERT INTO caracteres (caracter) VALUES 
('€'), ('¥'), ('£'), ('¢'), ('©'), ('®'), ('™'), ('§'), ('¶'), ('•'),('€');
 
INSERT INTO caracteres (caracter) VALUES ('Hola, ¿cómo estás?');


### Paso 5: Hacer las pruebas de espacio 
postgres@postgres# SELECT caracter, pg_column_size(caracter ) AS tamaño_en_bytes, LENGTH(caracter  )  AS longitud_caracteres , octet_length(caracter)  FROM caracteres ;
+--------------------+-----------------+---------------------+--------------+
|      caracter      | tamaño_en_bytes | longitud_caracteres | octet_length |
+--------------------+-----------------+---------------------+--------------+
| A                  |               2 |                   1 |            1 |
| B                  |               2 |                   1 |            1 |
| C                  |               2 |                   1 |            1 |
| D                  |               2 |                   1 |            1 |
| E                  |               2 |                   1 |            1 |
| F                  |               2 |                   1 |            1 |
| G                  |               2 |                   1 |            1 |
| H                  |               2 |                   1 |            1 |
| I                  |               2 |                   1 |            1 |
| J                  |               2 |                   1 |            1 |
| K                  |               2 |                   1 |            1 |
| L                  |               2 |                   1 |            1 |
| M                  |               2 |                   1 |            1 |
| N                  |               2 |                   1 |            1 |
| O                  |               2 |                   1 |            1 |
| P                  |               2 |                   1 |            1 |
| Q                  |               2 |                   1 |            1 |
| R                  |               2 |                   1 |            1 |
| S                  |               2 |                   1 |            1 |
| T                  |               2 |                   1 |            1 |
| U                  |               2 |                   1 |            1 |
| V                  |               2 |                   1 |            1 |
| W                  |               2 |                   1 |            1 |
| X                  |               2 |                   1 |            1 |
| Y                  |               2 |                   1 |            1 |
| Z                  |               2 |                   1 |            1 |
| a                  |               2 |                   1 |            1 |
| b                  |               2 |                   1 |            1 |
| c                  |               2 |                   1 |            1 |
| d                  |               2 |                   1 |            1 |
| e                  |               2 |                   1 |            1 |
| f                  |               2 |                   1 |            1 |
| g                  |               2 |                   1 |            1 |
| h                  |               2 |                   1 |            1 |
| i                  |               2 |                   1 |            1 |
| j                  |               2 |                   1 |            1 |
| k                  |               2 |                   1 |            1 |
| l                  |               2 |                   1 |            1 |
| m                  |               2 |                   1 |            1 |
| n                  |               2 |                   1 |            1 |
| o                  |               2 |                   1 |            1 |
| p                  |               2 |                   1 |            1 |
| q                  |               2 |                   1 |            1 |
| r                  |               2 |                   1 |            1 |
| s                  |               2 |                   1 |            1 |
| t                  |               2 |                   1 |            1 |
| u                  |               2 |                   1 |            1 |
| v                  |               2 |                   1 |            1 |
| w                  |               2 |                   1 |            1 |
| x                  |               2 |                   1 |            1 |
| y                  |               2 |                   1 |            1 |
| z                  |               2 |                   1 |            1 |
| 0                  |               2 |                   1 |            1 |
| 1                  |               2 |                   1 |            1 |
| 2                  |               2 |                   1 |            1 |
| 3                  |               2 |                   1 |            1 |
| 4                  |               2 |                   1 |            1 |
| 5                  |               2 |                   1 |            1 |
| 6                  |               2 |                   1 |            1 |
| 7                  |               2 |                   1 |            1 |
| 8                  |               2 |                   1 |            1 |
| 9                  |               2 |                   1 |            1 |
|                    |               2 |                   1 |            1 |
| !                  |               2 |                   1 |            1 |
| "                  |               2 |                   1 |            1 |
| #                  |               2 |                   1 |            1 |
| $                  |               2 |                   1 |            1 |
| %                  |               2 |                   1 |            1 |
| &                  |               2 |                   1 |            1 |
| '                  |               2 |                   1 |            1 |
| (                  |               2 |                   1 |            1 |
| )                  |               2 |                   1 |            1 |
| *                  |               2 |                   1 |            1 |
| +                  |               2 |                   1 |            1 |
| ,                  |               2 |                   1 |            1 |
| -                  |               2 |                   1 |            1 |
| .                  |               2 |                   1 |            1 |
| /                  |               2 |                   1 |            1 |
| :                  |               2 |                   1 |            1 |
| ;                  |               2 |                   1 |            1 |
| <                  |               2 |                   1 |            1 |
| =                  |               2 |                   1 |            1 |
| >                  |               2 |                   1 |            1 |
| ?                  |               2 |                   1 |            1 |
| @                  |               2 |                   1 |            1 |
| [                  |               2 |                   1 |            1 |
| \                  |               2 |                   1 |            1 |
| ]                  |               2 |                   1 |            1 |
| ^                  |               2 |                   1 |            1 |
| _                  |               2 |                   1 |            1 |
| `                  |               2 |                   1 |            1 |
| {                  |               2 |                   1 |            1 |
| |                  |               2 |                   1 |            1 |
| }                  |               2 |                   1 |            1 |
| ~                  |               2 |                   1 |            1 |
| Á                  |               3 |                   2 |            2 |
| É                  |               3 |                   2 |            2 |
| Í                  |               3 |                   2 |            2 |
| Ó                  |               3 |                   2 |            2 |
| Ú                  |               3 |                   2 |            2 |
| Ü                  |               3 |                   2 |            2 |
| Ñ                  |               3 |                   2 |            2 |
| á                  |               3 |                   2 |            2 |
| é                  |               3 |                   2 |            2 |
| í                  |               3 |                   2 |            2 |
| ó                  |               3 |                   2 |            2 |
| ú                  |               3 |                   2 |            2 |
| ü                  |               3 |                   2 |            2 |
| ñ                  |               3 |                   2 |            2 |
| €                  |               4 |                   3 |            3 |
| ¥                  |               3 |                   2 |            2 |
| £                  |               3 |                   2 |            2 |
| ¢                  |               3 |                   2 |            2 |
| ©                  |               3 |                   2 |            2 |
| ®                  |               3 |                   2 |            2 |
| ™                  |               4 |                   3 |            3 |
| §                  |               3 |                   2 |            2 |
| ¶                  |               3 |                   2 |            2 |
| •                  |               4 |                   3 |            3 |
| €                  |               4 |                   3 |            3 |
| Hola, ¿cómo estás? |              22 |                  21 |           21 |
+--------------------+-----------------+---------------------+--------------+

	

truncate table caracteres;
drop table caracteres;

 ```




# TIPOS DE DATOS DOMAINS 
```SQL

  -- Crear el dominio 'phone_number'
CREATE DOMAIN phone_number AS VARCHAR(15)
CHECK (VALUE ~ '^\+?[0-9\s\-]+$');

-- Crear la tabla 'empleados' que usa el dominio 'phone_number'
CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    telefono phone_number
);

-- Insertar datos en la tabla 'empleados'
INSERT INTO empleados (nombre, telefono) VALUES ('Juan Perez', '+52 123-456-7890');

-- Esta inserción fallará debido a la restricción del dominio
-- INSERT INTO empleados (nombre, telefono) VALUES ('Ana Gomez', '1234567890');

-- Consultar datos en la tabla 'empleados'
SELECT * FROM empleados;

-- Puedes otorgar permisos a otors usuarios para que ellos puedan usar el DOMAIN
GRANT USAGE ON DOMAIN phone_number TO app_user;


---------------------  Validar correo corportativo ---------------------
CREATE DOMAIN email_corporativo AS text
  CHECK (VALUE LIKE '%@miempresa.com');

CREATE TABLE clientes (
  correo email_corporativo
);

CREATE TABLE empleados (
  correo email_corporativo
);


--------------------- valida RFC ---------------------

-- Función que valida RFC
CREATE OR REPLACE FUNCTION fn_valida_rfc(valor text)
RETURNS boolean AS $$
BEGIN
  RETURN valor ~ '^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Dominio que usa la función
CREATE DOMAIN rfc_mx AS text
  CHECK (fn_valida_rfc(VALUE));


```



### Ejemplos de cast y dominios 
```
---************************ EJEMPLO DE CREACION DE CAST ************************

-- la FUNCION ROW ES  COMO UN TIPO DE DATO record


begin ; 

-- Definir un tipo de dato compuesto
CREATE TYPE my_type AS (x int, y int);

-- Crear una función de conversión
 
CREATE OR REPLACE FUNCTION my_type_to_text(my_type) RETURNS text AS $$
BEGIN
    RETURN '(' || $1.x || ',' || $1.y || ') XXXXXXXXXXXXXXXX';
END; $$ LANGUAGE plpgsql;

-- Crear un CAST que utilice la función de conversión
CREATE CAST (my_type AS text) WITH FUNCTION my_type_to_text(my_type);
 
 

CREATE TABLE my_table (
    id serial,
    data my_type
);


INSERT INTO my_table (data) VALUES (ROW(1, 2));


SELECT (data).x, (data).y , CAST(data AS text) as dato_cast , data  FROM my_table;

 
SELECT CAST(ROW(1, 2)::my_type AS text);


DROP TYPE my_type;
DROP FUNCTION my_type_to_text(my_type);
DROP CAST (my_type AS text);

rollback ; 



---************************ EJEMPLO DE CREACION DE DOMINIOS ************************
un tipo de dato personalizado que te permite aplicar restricciones y reglas específicas.

begin ; 

CREATE DOMAIN positive_integer AS int
CHECK (VALUE > 0);


CREATE TABLE my_table_dominio (
    id serial PRIMARY KEY,
    positive_value positive_integer
);


-- Insertar un valor válido
INSERT INTO my_table_dominio (positive_value) VALUES (10);

-- Intentar insertar un valor no válido
INSERT INTO my_table_dominio (positive_value) VALUES (-5);
-- Esto dará un error: ERROR:  value for domain positive_integer violates check constraint


ALTER DOMAIN positive_integer ADD CONSTRAINT value_less_than_hundred CHECK (VALUE < 100);


DROP DOMAIN positive_integer;


rollback ; 
```
---

 
# Tipos de datos de tamaño fijo en PostgreSQL
En PostgreSQL sí existen tipos de datos **de tamaño fijo**, lo que significa que **ocupan el mismo espacio en disco sin importar la longitud del valor que insertes** (dentro de sus límites). Aquí están los principales:

1.  **INTEGER / SMALLINT / BIGINT**
    *   **Tamaño fijo:**
        *   `SMALLINT` → 2 bytes
        *   `INTEGER` → 4 bytes
        *   `BIGINT` → 8 bytes
    *   **Ejemplo:**
        ```sql
        CREATE TABLE ejemplo (id INTEGER);
        ```



2.  **NUMERIC con precisión fija**
    *   Si defines `NUMERIC(10,2)`, PostgreSQL reserva espacio para esa precisión, aunque el valor sea pequeño.
    *   **Nota:** Internamente puede variar un poco, pero es prácticamente fijo para la precisión definida.



3.  **CHAR(n)** (carácter fijo)
    *   **Tamaño fijo:** `n` bytes (más 1 byte de padding).
    *   Si defines `CHAR(10)`:
        *   `'A'` ocupa **10 bytes** (rellena con espacios).
        *   `'ABCDEFGHIJ'` también ocupa **10 bytes**.
    *   **Ejemplo:**
        ```sql
        CREATE TABLE ejemplo (codigo CHAR(10));
        ```



4.  **DATE, TIME, TIMESTAMP**
    *   **DATE:** 4 bytes
    *   **TIME:** 8 bytes
    *   **TIMESTAMP:** 8 bytes
    *   No importa si la fecha es `2025-01-01` o `1900-01-01`, siempre ocupa lo mismo.



5.  **BOOLEAN**
    *   **Tamaño fijo:** 1 byte (`TRUE` o `FALSE`).



6.  **Tipos internos como OID**
    *   **OID:** 4 bytes (identificadores internos).

 
8. **UUID en PostgreSQL**

*   **Tamaño fijo:** **16 bytes** (128 bits).
*   **Qué es:** Un identificador universal único (RFC 4122).
*   **Comportamiento:**
    *   No importa si el valor es `00000000-0000-0000-0000-000000000000` o `550e8400-e29b-41d4-a716-446655440000`, **siempre ocupa 16 bytes**.
*   **Ejemplo:**
    ```sql
    CREATE TABLE ejemplo_uuid (id UUID DEFAULT gen_random_uuid());
    SELECT pg_column_size(id) FROM ejemplo_uuid;
    ```
    Resultado: `16`.



### ❌ Tipos que **NO** son de tamaño fijo

*   `VARCHAR(n)` y `TEXT`: ocupan espacio proporcional a la longitud del texto (más overhead).
*   `BYTEA`: depende del tamaño del binario.

 
### ✅ Resumen actualizado de tipos fijos

| Tipo      | Tamaño fijo |
| --------- | ----------- |
| SMALLINT  | 2 bytes     |
| INTEGER   | 4 bytes     |
| BIGINT    | 8 bytes     |
| BOOLEAN   | 1 byte      |
| DATE      | 4 bytes     |
| TIME      | 8 bytes     |
| TIMESTAMP | 8 bytes     |
| CHAR(n)   | n bytes     |
| UUID      | 16 bytes    |


 

```
JSON: https://medium.com/team-resilience/odc-supercharge-your-advanced-sql-with-postgresql-json-functions-6ca3e9520a56

```
