# Descripción rápida de los type:
se utilizan para definir nuevos tipos de datos compuestos personalizados. Estos tipos personalizados pueden contener múltiples campos con diferentes tipos de datos
Estos son los tipos que existen <br>
`('integer','date','text','smallint','character varying','character','numeric','bigint')`

 
**Donde se usan los type**
1. Se usa mucho en funciones para definir los parametros o el tipo de dato que va retornar, que se se usa como un arrego 
2. En las columnas de las tablas.



# Ejemplos de uso:



1. **Tipo compuesto (Composite Type)**:
   - Un tipo compuesto es similar al tipo de fila de una tabla. Puedes especificar una lista de nombres de atributos y sus tipos de datos. Por ejemplo:
     ```sql
     CREATE TYPE mi_tipo AS (
         columna1 integer,
         columna2 text
     );
     ``` 

2. **Tipo enumerado (Enum Type)**:
   - Los tipos enumerados son útiles cuando deseas limitar los valores posibles de una columna a un conjunto específico. Por ejemplo:
     ```sql
     CREATE TYPE estado_civil AS ENUM ('Soltero', 'Casado', 'Divorciado');
     ``` 

3. **Tipo de rango (Range Type)**:
   - Los tipos de rango representan un rango de valores. Puedes crear uno especificando un subtipo y, opcionalmente, una clase de operadores. Por ejemplo:
     ```sql
     CREATE TYPE rango_edades AS RANGE (
         SUBTYPE = integer,
         SUBTYPE_OPCLASS = int4range_ops
     );
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
- **Integer (int, int2, int4, int8)**
  - **Límites**:
    - `int2 (Alias: Smallint)`: -32,768 a 32,767
    - `int4 (Alias: int, Integer)`: -2,147,483,648 a 2,147,483,647
    - `int8 (Alias: Bigint)`: -9,223,372,036,854,775,808 a 9,223,372,036,854,775,807
  - **Espacio en memoria**:
    - `smallint`: 2 bytes
    - `integer`: 4 bytes
    - `bigint`: 8 bytes
  - **Desventajas**: Limitados en rango y no adecuados para valores decimales.

- **Serial (serial, bigserial)**
  - **Límites**: Mismos que `integer` y `bigint`.
  - **Espacio en memoria**: Mismos que `integer` y `bigint`.
  - **Desventajas**: No se puede reutilizar el valor una vez eliminado.

- **Numeric (numeric, decimal) son igual **
  -  sintaxis es NUMERIC(p, s), donde p es la precisión total (el número máximo de dígitos) y s es la escala (el número de dígitos a la derecha del punto decimal).
  - **Límites**: Depende de la precisión especificada.
  - **Espacio en memoria**: Variable, depende de la precisión y escala.
  - **Desventajas**: Más lentos y consumen más espacio en comparación con los enteros.

### 2. Tipos de Caracteres
- **Character (char, varchar, text)**
  - **Límites**:
    - `char(n)`: Fijo a n caracteres.
    - `varchar(n)`: Hasta n caracteres.
    - `text`: Ilimitado.
  - **Espacio en memoria**:
    - `char(n)`: n bytes
    - `varchar(n)`: Longitud de la cadena + 1 o 4 bytes de sobrecarga
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







