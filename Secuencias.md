BUSCAR PAR QUE SIRVE currval

# Descripción Rápida de Sequences:
Las Sequences se utilizan para generar valores autoincrementales, como claves primarias en una tabla

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
SELECT setval('mi_secuencia', (SELECT max(id) FROM mi_tabla));

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
