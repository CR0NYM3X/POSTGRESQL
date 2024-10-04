


 # Saber el tipo 
```sql

postgres@postgres# 
select			
	pg_typeof('holaaa')
	,pg_typeof(1)
	,pg_typeof(1.2)
	,pg_typeof(1.588888)
	,pg_typeof(array['a','b'])
	,pg_typeof(array[1,2])
	,pg_typeof(true)
	,pg_typeof('2024-08-01'::date);

+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| pg_typeof | pg_typeof | pg_typeof | pg_typeof | pg_typeof | pg_typeof | pg_typeof | pg_typeof |
+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
| unknown   | integer   | numeric   | numeric   | text[]    | integer[] | boolean   | date      |
+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+
(1 row)


```


```sql
--- Expresiones regulares
SELECT * FROM productos WHERE nombre ~* 'man';

--- Like
SELECT * FROM productos WHERE nombre ILIKE '%man%';

```


 
--- Tipos de JOIN: 
 
 
 
 
```sql

SELECT Abs(20) AS AbsNum; ---- esta función siempre te retorna un positivo
SELECT sign(20) AS AbsNum; --- esta función siempre te retorana 1 si es número es positvo y si es negativo te retorna -1
SELECT * from mupaquetes where fec_fechamovto::date between '20210501' and '20210531' 29555 BETWEEN num_dcfinicial AND num_dcffinal


CAST ('10' AS INTEGER); convertir string a int --- O  (idu_valorconfiguracion)::INT
select round(random()*10) ---- random 
select round(random()* (3-1)  +1 )
SELECT to_char((3::float/2::float), 'FM999999999.00')
select (3::float/2::float)
SELECT round((3/2)::numeric,2 ) -- ponerle 2 decimal en 00
select TRUNC(5, 3) ---> agrega 3 decimales  trunc 5.000
select ceiling(12.34) -- redondea todo hacia arriba
select floor(12.23) --  redondea todo hacia abajo
select cast(52.55 as decimal(18,2) ) -- le permite dejar 2 decimales y el 18 es la precisión o el redodeo





```sql

########## CONDICIONEALES IF ########## 

DO $$
BEGIN
    -- Declarar una variable
    DECLARE
        valor INTEGER := 10;
    BEGIN
        -- Usar IF para verificar una condición
        IF valor = 10 THEN
            RAISE NOTICE 'El valor es 10';
        -- Usar ELSIF para otra condición
        ELSIF valor = 20 THEN
            RAISE NOTICE 'El valor es 20';
        -- Usar ELSE para cualquier otra condición
        ELSE
            RAISE NOTICE 'El valor no es ni 10 ni 20';
        END IF;
    END;
END $$;

########## CONDICIONEALES CASE WHEN ##########

---- funciona como switch 
select 
      CASE 'p'
          WHEN 'a' THEN 'agg'
          WHEN 'w' THEN 'window'
          WHEN 'p' THEN 'proc'
          ELSE 'func'
      END as Type;

--- funciona como if 
SELECT title, length,
       CASE
           WHEN length > 0 AND length <= 50 THEN 'Corto'
           WHEN length > 50 AND length <= 120 THEN 'Medio'
           WHEN length > 120 THEN 'Largo'
           ELSE 'Desconocido'
       END AS duracion
FROM film
ORDER BY title;


DO $$
DECLARE
    a INT := 2;
BEGIN
    CASE 
        WHEN a = 1 THEN RAISE NOTICE 'El número es 1';
        WHEN a = 2 THEN RAISE NOTICE 'El número es 2';
        ELSE RAISE NOTICE 'El número no es 1 ni 2';
    END CASE;
END;
$$;





 **Bucle FOR:** Mejor para conjuntos de datos pequeños y para casos donde la simplicidad es prioritaria.
 
 **Ventajas:**
**Simplicidad:** Es más sencillo de implementar para tareas simples.
**Desempeño para conjuntos pequeños:** Para conjuntos de datos relativamente pequeños, el rendimiento es adecuado.

**Desventajas:**
**Uso de memoria:** Carga todo el conjunto de resultados en la memoria, lo que puede no ser ideal para conjuntos de datos grandes.
**Menor control:** No permite un control tan fino sobre el flujo de ejecución y el manejo de grandes volúmenes de datos.
 
 
**Cursor:** Ideal para conjuntos de datos grandes y donde se requiere un manejo más eficiente de memoria y control sobre el proceso de recuperación de datos.

**Ventajas:**
**Manejo eficiente de memoria:** Los cursores no cargan todo el conjunto de resultados en memoria a la vez. Solo mantienen una fila en memoria, lo que es ideal para conjuntos de datos grandes.
**Control fino:** Ofrecen más control sobre el proceso de recuperación de datos y pueden ser más eficientes cuando se manejan grandes volúmenes de datos.

**Desventajas:**
**Complejidad adicional:** La implementación y manejo de cursores es más compleja comparada con un bucle FOR.
**Overhead:** Puede haber más overhead asociado con el uso de cursores en comparación con bucles FOR para conjuntos de datos pequeños.




########## BUCLES WHILE ########## 

DO $$
DECLARE
    n INT := 5;
    contador INT := 0;
BEGIN
    WHILE contador < n LOOP
        RAISE NOTICE 'Contador: %', contador;
        contador := contador + 1;
    END LOOP;
END;
$$;


DO $$
DECLARE
    contador INT := 0;
BEGIN
    LOOP
        -- Aquí va el código que deseas ejecutar en cada iteración
        RAISE NOTICE 'Contador: %', contador;

        -- Incrementa el contador
        contador := contador + 1;

        -- Condición de salida
        EXIT WHEN contador >= 10;
    END LOOP;
END $$;


########## BUCLES FOR ########## 

 do $$
DECLARE
    -- Declarar variables para almacenar los resultados
    columnas RECORD;
BEGIN
    -- Ejecutar la consulta y almacenar los resultados en las variables
    FOR columnas IN
        EXECUTE 'select table_schema,table_name,table_type from information_schema.tables limit 10 ;'
    LOOP
        -- Insertar los valores en la tabla destino
        RAISE NOTICE '% - % - % ', columnas.table_schema, columnas.table_name, columnas.table_type;
    END LOOP;
END;
$$ ;



 do $$
DECLARE
    -- Declarar variables para almacenar los resultados
    var1 text;
    var2 TEXT;
    var3 text;
BEGIN
    -- Ejecutar la consulta y almacenar los resultados en las variables
    FOR var1, var2, var3 IN
        EXECUTE 'select table_schema,table_name,table_type from information_schema.tables limit 10 ;'
    LOOP
        -- Insertar los valores en la tabla destino
        RAISE NOTICE '% - % - % ', var1, var2, var3;
    END LOOP;
END;
$$ ;






DO $$
DECLARE
    i INT;
BEGIN
    FOR i IN 1..5 LOOP
        RAISE NOTICE 'Valor de i: %', i;
    END LOOP;
END;
$$;



 


########## BUCLES FOREACH  ########## 
---- el FOREACH solo sirve para recorrer arrays 
DO $$
DECLARE
    nombres TEXT[] := ARRAY['Juan', 'María', 'Pedro'];
    nombre TEXT;
BEGIN
    FOREACH nombre IN ARRAY nombres LOOP
        RAISE NOTICE 'Nombre: %', nombre;
    END LOOP;
END;
$$;

########## BUCLES CURSORES  ########## 


START TRANSACTION ISOLATION LEVEL REPEATABLE READ
DECLARE c1 CURSOR FOR SELECT id, fecha, cliente_id, producto_id, cantidad, precio FROM public.ventas;
FETCH 10000 FROM c1 --- cada vez que ejecutes este comando estara recorriendo 10000 lineas 
COMMIT TRANSACTION


DO $$
DECLARE
    nombre_cur CURSOR FOR
        select table_schema,table_name, table_type from information_schema.tables  where not table_schema in('pg_catalog','information_schema') and table_type = 'FOREIGN' ;
    table_schema varchar(255);
    table_name varchar(255);
	table_type varchar(255);
BEGIN
    OPEN nombre_cur; -- Abrir el cursor
    
    LOOP
        FETCH nombre_cur INTO table_schema, table_name,table_type; -- Obtener el siguiente conjunto de resultados
        
        EXIT WHEN NOT FOUND; -- Salir del bucle si no hay más resultados
        
        -- Procesar la fila actual
        RAISE NOTICE 'table_schema: %, table_name: %, table_type: %', table_schema, table_type, table_type;
    END LOOP;
    
    CLOSE nombre_cur; -- Cerrar el cursor
END;
$$;

/*
FOUND  : Se utiliza para verificar si una operación afectó alguna fila o si una consulta devolvió algún resultado.
FOUND = TRUE: La operación encontró o afectó al menos una fila.
FOUND = FALSE: La operación no encontró ni afectó ninguna fila.

*/


-----------

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    edad INTEGER
);

INSERT INTO usuarios (nombre, edad) VALUES
    ('Juan', 25),
    ('María', 30),
    ('Pedro', 28),
    ('Ana', 35);

CREATE OR REPLACE FUNCTION guardar_usuarios_en_tabla() RETURNS VOID AS $$
DECLARE
    usuario_row RECORD;
BEGIN
    -- Borramos la tabla temporal si ya existe
    DROP TABLE IF EXISTS temp_usuarios;

    -- Creamos una tabla temporal para almacenar los resultados
    CREATE TEMP TABLE temp_usuarios (
        nombre VARCHAR(100),
        edad INTEGER
    );

    -- Insertamos los datos de la tabla usuarios en la tabla temporal
    FOR usuario_row IN SELECT * FROM usuarios LOOP
        INSERT INTO temp_usuarios (nombre, edad) VALUES (usuario_row.nombre, usuario_row.edad);
    END LOOP;

    -- Puedes hacer cualquier otra operación con la tabla temporal aquí si lo deseas

END;
$$ LANGUAGE plpgsql;

--https://sqltemuco.wordpress.com/2016/09/26/recorrer-cursores-con-postgresql/
```



# Crear uniones entre tablas 
```sql

PSQL > 9 
select * from (VALUES ('r', 'SELECT'), ('w', 'UPDATE'), ('a', 'INSERT'), ('d', 'DELETE'), ('x', 'REFERENCES')) AS acl_privs(acl, privilege_type);

PSQL > 8 
select  'r' as acl , 'SELECT' as privilege_type union all
select  'w', 'UPDATE' union all 
select   'd', 'DELETE' ;

```



## Ver los objetos 
```
select relkind,relname  from  pg_class   
when 'r' then 'TABLE'
when 'm' then 'MATERIALIZED_VIEW'
when 'i' then 'INDEX'
when 'S' then 'SEQUENCE'
when 'v' then 'VIEW'
when 'c' then 'TYPE'
```






# Manuales  PDF 
```sql
https://wiki.postgresql.org/images/c/c5/Afinamiento_de_la_base_de_datos.pdf


----- MANUALES DE AUTENTICACION EN POSTGRESQL ------ 
https://info.enterprisedb.com/rs/069-ALB-339/images/Security-best-practices-2020.pdf?_ga=2.241796162.1507359552.1601965382-378383403.1546583698
https://postgresconf.org/system/events/document/000/000/183/pgconf_us_v4.pdf | pagina 37/68 ssl 
https://paquier.xyz/content/materials/20180531_pgcon_auth.pdf


# PostgreSQL Security Technical Implementation Guide
https://www.crunchydata.com/files/stig/PGSQL-STIG-v1r1.pdf

https://www.depesz.com/
```

### Fechas 
```sql
--- saber la fecha
select CLOCK_TIMESTAMP()   -- 2022-11-30 16:36:18 hora

--- colocar formato a la fecha
SELECT TO_DATE('October 09, 2012', 'Month DD, YYYY');

--- darle formato a la hora 
SELECT TO_TIMESTAMP('10:00:00', 'HH24:MI:SS')::TIME AS formatted_time;

SELECT DATE_PART('hour', '2024-08-19 12:34:56'::timestamp) AS hora;

---- restar o sumar dias en fechas
SELECT CAST(now() AS DATE)
SELECT NOW() + INTERVAL '7 hours';
select now() +  ( 7 ||' hours')::INTERVAL;
SELECT CAST(now() AS DATE) + CAST('-1 days' AS INTERVAL);
SELECT  now()::date  + CAST('1 days' AS INTERVAL);
SELECT timestamp'2009-12-31 12:31:50' - INTERVAL '30 minutes' AS nueva_hora_llegada --- sumar o restar minutos 
SELECT TO_TIMESTAMP('10:00:00', 'HH24:MI:SS')::TIME  + INTERVAL '20 hours' ;

---- Sacar los días MES
select EXTRACT(DAY FROM now()::date)
select EXTRACT(MONTH FROM now()::date) 
select EXTRACT(YEAR  FROM now()::date) 
select EXTRACT(HOURS  FROM now())

select extract(hour  from  timestamp'2009-12-31 12:25:50');
select extract(minute from  timestamp'2009-12-31 12:25:50');
select extract(second from  timestamp'2009-12-31 12:25:50');
select EXTRACT(MILLISECOND FROM ( var_clock_end  - var_clock_start ) )::NUMERIC(50,4)


SELECT 
    EXTRACT(epoch FROM TIMESTAMP '2024-01-01 12:01:00') - 
    EXTRACT(epoch FROM TIMESTAMP '2024-01-01 12:00:00') AS segundos_entre_fechas; --- 60.000000 
	
select round(1000 * EXTRACT(epoch FROM '2024-01-01 12:01:00'::TIMESTAMP - '2024-01-01 12:00:00'::TIMESTAMP), 3); ---- 60000.000 

select age(timestamp '2011-10-01 ', timestamp '2011-11-01') --- saber los días que pasan 
select ('2011-11-01'::date -  '2011-12-028'::date)--- saber los días que pasan  

select to_char( timestamp'2009-12-31 11:25:50' , 'HH12:MI:SS') >  '12:26:52'


--- se utiliza para truncar una fecha o un valor de tipo timestamp a una precisión específica.
SELECT DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day' AS ultimo_dia_me

### Ejemplo 1: Truncar a la hora
Supongamos que tienes un `timestamp` y quieres truncarlo a la hora más cercana:
SELECT DATE_TRUNC('hour', TIMESTAMP '2024-09-24 16:34:59') AS truncado_a_la_hora; --- 2024-09-24 16:00:00

### Ejemplo 2: Truncar al día
Si quieres truncar un `timestamp` al inicio del día:
SELECT DATE_TRUNC('day', TIMESTAMP '2024-09-24 16:34:59') AS truncado_al_dia; --- 2024-09-24 00:00:00

### Ejemplo 3: Truncar al mes
Para truncar un `timestamp` al inicio del mes:
SELECT DATE_TRUNC('month', TIMESTAMP '2024-09-24 16:34:59') AS truncado_al_mes; --- 2024-09-01 00:00:00

### Ejemplo 4: Truncar al año
Si necesitas truncar un `timestamp` al inicio del año:
SELECT DATE_TRUNC('year', TIMESTAMP '2024-09-24 16:34:59') AS truncado_al_ano; ---2024-01-01 00:00:00

### Ejemplo 5: Truncar a la semana
Para truncar un `timestamp` al inicio de la semana (considerando que la semana empieza el lunes):
SELECT DATE_TRUNC('week', TIMESTAMP '2024-09-24 16:34:59') AS truncado_a_la_semana; --- 2024-09-23 00:00:00

### Ejemplo 6: Truncar al trimestre
Para truncar un `timestamp` al inicio del trimestre:
SELECT DATE_TRUNC('quarter', TIMESTAMP '2024-09-24 16:34:59') AS truncado_al_trimestre; --- 2024-07-01 00:00:00



SELECT DATE_ADD('2018-12-31 23:59:59'::timestamp, INTERVAL '1 day'); -- Resultado: 2019-01-01 23:59:59
SELECT DATE_PART('month', TIMESTAMP '2017-09-30'); -- Resultado: 9
SELECT DATE_PART('year', TIMESTAMP '2017-01-01'); -- Resultado: 2017
SELECT DATE_PART('century', TIMESTAMP '2017-01-01'); -- Resultado: 21

 
```

 

### realizar insert ,  en caso de error no finalizar la transaccion 
```sql
DO $$
BEGIN
    BEGIN;

    -- Tus 1000 INSERTs
    INSERT INTO tu_tabla (columna1, columna2) VALUES (valor1, valor2);
    INSERT INTO tu_tabla (columna1, columna2) VALUES (valor3, valor4);
    -- ... más INSERTs ...

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE NOTICE 'Se ha producido un error, se ha revertido la transacción.';
END;
$$;
```



### string_agg y array_agg 
```sql
--- versiones nuevas > 10
string_agg(columnsname,',')

--- versiones 8 
 array_to_string(array_agg(c.attname), ', ') AS column_names

```

### Arrays 
```sql


SELECT * FROM unnest(ARRAY['a', 'b', 'c']) WITH ORDINALITY;
+--------+------------+
| unnest | ordinality |
+--------+------------+
| a      |          1 |
| b      |          2 |
| c      |          3 |
+--------+------------+


select array['hola','aaaa','jabon']; --- {hola,aaaa,jabon}
select '{hola,aaaa,jabon}'::text[];  --- {hola,aaaa,jabon}


SELECT string_to_array('8192 bytes', ' ') ; -- {8192,bytes} (Convierte un string en un array ) 
select array_to_string( '{8192,bytes}'::text[] , ' --  '); --- 8192 --  bytes  (Convierte un array en un string)

---- convertir el array en filas 
SELECT    unnest('{8192,bytes}'::text[]) ;
select    unnest(array[ 822, 823, 2782, 2994, 2171,509,722, 1428,106,107,108 ])  codigo)a 

---- Convierte varias filas array en una sola fila es como el string_agg pero en arrays 
select array_agg(test_array) from (SELECT  '{8192,bytes}'::text[] as test_array union all select   '{9999,bytes}'::text[] ) as a ;


--- buscar un valor en un arreglo
SELECT * FROM mi_tabla WHERE 'perro' = ANY(mi_array);

 

1. **array_append**: Añade un elemento al final de un array.
   SELECT array_append(ARRAY[1, 2, 3], 4); -- Resultado: {1,2,3,4}
   

 **array_prepend**: Añade un elemento al inicio de un array.
 SELECT array_prepend(0, ARRAY[1, 2, 3]); -- Resultado: {0,1,2,3}
 

 **array_cat**: Concatena dos arrays.
 SELECT array_cat(ARRAY[1, 2], ARRAY[3, 4]); -- Resultado: {1,2,3,4}
 
  **||**: Concatena dos arrays.
 SELECT ARRAY[1, 2] || ARRAY[3, 4]; -- Resultado: {1,2,3,4}
   

 **array_length**: Devuelve la longitud de un array en una dimensión específica.
 SELECT array_length(ARRAY[1, 2, 3], 1); -- Resultado: 3
 

 **array_remove**: Elimina todas las ocurrencias de un valor específico en un array.
 SELECT array_remove(ARRAY[1, 2, 3, 2], 2); -- Resultado: {1,3}
 

 **array_replace**: Reemplaza todas las ocurrencias de un valor específico en un array con otro valor.
 SELECT array_replace(ARRAY[1, 2, 3, 2], 2, 5); -- Resultado: {1,5,3,5}
select array_replace( '{server=10.10.10.12,version=1.1}'::text[], 'version=1.1', 'version=2.0')
 

 **unnest**: Expande un array en una serie de filas
 SELECT unnest(ARRAY[1, 2, 3]); -- Resultado: 1, 2, 3 (en filas separadas)
 
 **@>**: Verifica si el primer array contiene al segundo
 SELECT ARRAY[1, 2, 3] @> ARRAY[2]; -- Resultado: true
 

 **<@**: Verifica si el primer array está contenido en el segundo.
 SELECT ARRAY[1, 2] <@ ARRAY[1, 2, 3]; -- Resultado: true
 

 **&&**: Verifica si dos arrays tienen elementos en común.
 SELECT ARRAY[1, 2, 3] && ARRAY[2, 4]; -- Resultado: true
 

 **array_agg**: Agrega los valores de una columna en un array
 SELECT array_agg(column_name) FROM table_name;
 

 **array_dims**: Devuelve una cadena que representa las dimensiones del array
 SELECT array_dims(ARRAY[1, 2, 3]); -- Resultado: [1:3]
 

 **array_fill**: Crea un array con un valor específico y dimensiones dadas.
 SELECT array_fill(0, ARRAY[3]); -- Resultado: {0,0,0}
 

 **array_position**: Devuelve la posición de la primera ocurrencia de un valor en un array.
 SELECT array_position(ARRAY[1, 2, 3, 2], 2); -- Resultado: 2

 **array_positions**: Devuelve un array con todas las posiciones de un valor en un array.
 SELECT array_positions(ARRAY[1, 2, 3, 2], 2); -- Resultado: {2,4}
 

 **array_to_string**: Convierte un array en una cadena de texto, separando los elementos con un delimitador.
 SELECT array_to_string(ARRAY[1, 2, 3], ','); -- Resultado: '1,2,3'

 **string_to_array**: Convierte una cadena de texto en un array, utilizando un delimitador.
 SELECT string_to_array('1,2,3', ','); -- Resultado: {1,2,3}

 **array_upper**: Devuelve el índice superior de una dimensión específica del array. 
 SELECT array_upper(ARRAY[1, 2, 3], 1); -- Resultado: 3

 **array_lower**: Devuelve el índice inferior de una dimensión específica del array.
 SELECT array_lower(ARRAY[1, 2, 3], 1); -- Resultado: 1
 
```


### Trabajando con strings

```SQL


---  devuelve todas las coincidencias de una expresión regular en una cadena de texto
SELECT regexp_matches('Learning #PostgreSQL #REGEXP_MATCHES', '#([A-Za-z0-9_]+)', 'g'); --- {PostgreSQL}   {REGEXP_MATCHES} 

--- solo devuelve la primera coincidencia encontrada
SELECT regexp_match('Learning #PostgreSQL #REGEXP_MATCHES', '#([A-Za-z0-9_]+)'); --- {PostgreSQL}

select array_to_string(regexp_match(replace(' asdasd asda asd czx10.59.64.255cas wasd as ',' ',''), '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'),',') as ip_original

###  Prefijos en texto 
--- Los escapes como la E  permiten incluir caracteres especiales en las cadenas de texto: 
SELECT E'Esta es una línea \n y esta es otra línea \t hola  \' ';



--- **`U&`**: Indica una cadena Unicode con escapes de estilo Unicode.
   SELECT U&'\0041\0042\0043'; -- Resulta en 'ABC'
  
-- **`B`**: Indica una cadena binaria.
 
   SELECT B'101010'; -- Resulta en el valor binario 101010
 

-- **`$$`**: Delimitadores de dólar para cadenas de texto que pueden incluir comillas simples sin necesidad de escape.
SELECT $$O'Reilly$$; -- Resulta en 'O'Reilly'
 





--- convertir string a Hex
 select encode( 'a', 'hex') ;

----- Convertir a mayúsculas o minúsculas 
select lower('HOLA');  --> Hola
select  upper('Hola'); --> HOLA


---- divide en partes un string, colocando un delimitador y indica que parte quieres que retorne
SELECT SPLIT_PART('A,B,C', ',', 3); --- C

--- convierte en filas el texto 
SELECT regexp_split_to_table('INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER', ','); -- > V 9 
SELECT split_part('texto1,texto2,texto3', ',', generate_series(1, length('texto1,texto2,texto3') - length(replace('texto1,texto2,texto3', ',', '')) + 1)) AS columna_individual; ---  < V9

-- Cuenta la cantidad de caracteres 
SELECT LENGTH('Hola Mundo'); ---> 10
select char_length('Hola Mundo'); ---> 10

--- Elimina los espacios de la izq y derecha
select trim('  hola   '); ---> hola

--- eliminar caracter al principio
select  TRIM(LEADING ',' FROM ',holaaaaaa');


----- concatenar/juntar columnas 
SELECT CONCAT(animal, ' ', comida, ' ', color) AS columna_concatenada FROM (select 'PERRO' as animal,'LECHE' as  comida, 'ROJO' as color) as b;
SELECT  animal ||  ' ' ||  comida ||  ' ' ||  color  AS columna_concatenada FROM (select 'PERRO' as animal,'LECHE' as  comida, 'ROJO' as color) as b;

---- Retorna la pocicion 
SELECT POSITION('com' IN 'example.com');  ---> 9  

---- Remplaza texto 
select replace('test string','st','**') --> te** **ring

---  extraer una subcadena de una cadena de texto dada
select substring('hola mundo', 1, 4); ---> hola 
select substring('hola mundo', 5); ---> mundo

select substring('arwdDxt' FROM 1 FOR length('arwdDxt') - 1); -- >  arwdDx
 SELECT SUBSTRING('Hola Mundo' FROM 6);  --- Extraer una subcadena desde una posición específica:  Mundo
 SELECT SUBSTRING('Hola Mundo' FROM 1 FOR 4);  ---> Extraer una subcadena con una longitud específica:  Hola
 SELECT SUBSTRING('abc123def'  FROM '[0-9]+'); ---> Usar con expresiones regulares : 123
 select substring('select * from colaboradores order by 1;'FROM 'from .*');

SUBSTRING(cadena [FROM posición_inicial] [FOR longitud])
 
- **cadena**: La cadena de texto de la cual deseas extraer la subcadena.
- **posición_inicial**: (Opcional) La posición desde donde comenzar a extraer. Si se omite, comienza desde el primer carácter.
- **longitud**: (Opcional) El número de caracteres a extraer. Si se omite, extrae hasta el final de la cadena.


 ---- Extraer texto 
 SELECT LEFT('Hola Mundo', 6);  ---> Hola M 

   --- Encoding 
   SELECT encode('Hola mundo', 'base64'); ---> SG9sYSBtdW5kbw== 
   SELECT encode('Hola mundo', 'escape'); ---> Hola\040mundo 
   SELECT encode('Hola mundo', 'hex');  ---> 486f6c61206d756e646f 
   
   --- Decoding  
   SELECT convert_from(decode('SG9sYSBtdW5kbw==', 'base64'), 'UTF8');
   SELECT convert_from(decode('Hola\040mundo', 'escape'), 'UTF8');
   SELECT convert_from(decode('486f6c61206d756e646f', 'hex'), 'UTF8');
   SELECT convert_from('\\xe4', 'LATIN1'); 

# String Functions and Operators 
https://www.postgresql.org/docs/8.2/functions-string.html

 

--- Agregale al princio o al final una cierta cantidad de caracteres 
select lpad('Hola Mundo',20,'-'); ---> '----------Hola Mundo'
select rpad('Hola Mundo',20,'-'); ---> 'Hola Mundo----------'


--- Saltos de linea 
select   'hola ' || CHR(13)|| CHR(10)  ||  'mundo'  
select   E'homa \r\n mundo' ;


---- Remplazar 

select regexp_replace(E'homa \r\n mundo', E'[\\n\\r]+', ' ', 'g' ) ;   ----- Eliminar saltos de linea  : homa   mundo 
select REPLACE('Hola mundo', ' ', '');   --->  Elimina espacios :  Holamundo 
select replace(replace(replace(trim(' hola            mundo       grande'),' ','<>'),'><',''),'<>',' '); -- en caso de tener mas 1 un espacio lo replaza por 1 espacio : "hola mundo grande"
 SELECT regexp_replace('Hola 123 mu,ndo', '[a-zA-Z0-9\s]', '', 'g') --- quitar letras y números 

SELECT regexp_replace('maria ,     ,    \nABC', '(?i)(maria\s*),\s*,\s*([a-zA-Z]+)', '\1 \2', 'g'); --- 



--- si el parametro 1 es igual al parametro 2 retorna null en caso de no, retorna el param1
select nullif('aaa','aaa')  --- Null


---- En caso de que el parametro 1 sea null retornara el valor del parametro 2 
select coalesce(  pagotargeta , 0) 

--- convertir string a ascii
SELECT ASCII('\');

----convertir ascii  a string
select CHR(10); -- salto de linea
select CHR(39); -- Comilla simple
select CHR(34); -- Comilla dobles
select CHR(9) ; -- tab



**Funciones de JSON**: Estas funciones permiten trabajar con datos en formato JSON. Por ejemplo, `jsonb_array_elements`, `jsonb_each`.
   SELECT jsonb_each('{"a":1, "b":2}');

**Funciones de rango**: Estas funciones permiten trabajar con tipos de datos de rango. Por ejemplo, `range_merge`, `range_intersect`.
   SELECT range_merge(int4range(1, 5), int4range(3, 10));

 **Funciones de búsqueda de texto**: Estas funciones permiten realizar búsquedas de texto completo. Por ejemplo, `to_tsvector`, `to_tsquery`.
   SELECT to_tsvector('The quick brown fox');


select cast('1' as integer);
select cast('10000000000' as integer);
select cast('10000000000' as bigint);
select cast('abc' as integer);
select cast('1' as text);
select cast('true' as boolean);

```


### generar una serie de valores dentro de un intervalo especificado. P
```SQL
SELECT generate_series('2024-01-01'::date  /* INICIO */ , '2024-01-10'::date  /* FIN */, '1 day'  /* INTERVALO */); --- inicio, fin, intervalo
```


### Dividir letras 
```sql
WITH RECURSIVE letters AS (
    SELECT 1 AS position, SUBSTRING('abcd', 1, 1) AS letter
    UNION ALL
    SELECT position + 1, SUBSTRING('abcd', position + 1, 1)
    FROM letters
    WHERE position < LENGTH('abcd')
)
SELECT letter
FROM letters;

+--------+
| letter |
+--------+
| a      |
| b      |
| c      |
| d      |
+--------+


```


### json


```sql
CREATE TABLE ejemplo (
    id serial PRIMARY KEY,
    nombre text,
    edad int
);


INSERT INTO ejemplo (nombre, edad)
SELECT nombre, edad
FROM json_populate_recordset(NULL::ejemplo, '[{"nombre": "Juan", "edad": 30}, {"nombre": "Ana", "edad": 25}]');




-----------------------

CREATE TABLE ejemplo (
    id serial PRIMARY KEY,
    datos json
);


INSERT INTO ejemplo (datos) VALUES 
('[{"nombre": "Juan", "edad": 30}, {"nombre": "Ana", "edad": 25}]');



SELECT *
FROM json_to_recordset(
    (SELECT datos FROM ejemplo WHERE id = 1)
) AS x(nombre text, edad int);




```



###  Recorrer una tabla grande 
```sql
postgres@auditoria# select id,ip_server from cat_server order by id  limit 5 offset 0;
+----+---------------+
| id |   ip_server   |
+----+---------------+
|  1 | 10.28.228.238 |
|  2 | 10.31.128.16  |
|  3 | 10.28.228.23  |
|  4 | 10.28.228.30  |
|  5 | 10.30.123.26  |
+----+---------------+
(5 rows)

``` 




### ¿Qué son las funciones de ventana?

Las funciones de ventana en PostgreSQL son una herramienta poderosa para realizar cálculos sobre un conjunto de filas relacionadas con la fila actual, sin reducir el número de filas en el resultado. Aquí te dejo una explicación detallada y algunos ejemplos avanzados:

```sql
### Componentes de las funciones de ventana

1. **OVER Clause**: Define el marco de la ventana.
2. **PARTITION BY**: Divide las filas en particiones.
3. **ORDER BY**: Ordena las filas dentro de cada partición.
4. **Frame Specification**: Define el rango de filas sobre el cual se realiza el cálculo.

### Ejemplos Avanzados

#### 1. Ranking Functions
Estas funciones asignan un rango a cada fila dentro de una partición.


SELECT empno, salary, 
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM employees;


#### 2. Aggregate Functions
Estas funciones realizan cálculos agregados sobre el marco de la ventana.


SELECT department, empno, salary, 
       AVG(salary) OVER (PARTITION BY department) AS avg_salary
FROM employees;


#### 3. Lead and Lag Functions
Permiten acceder a datos de filas anteriores o posteriores sin necesidad de auto-joins.


SELECT empno, salary, 
       LAG(salary, 1) OVER (ORDER BY empno) AS prev_salary,
       LEAD(salary, 1) OVER (ORDER BY empno) AS next_salary
FROM employees;


#### 4. Window Frame Specification
Permite definir un rango específico de filas para el cálculo.


SELECT empno, salary, 
       SUM(salary) OVER (ORDER BY empno 
                         ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS moving_sum
FROM employees;


### Uso Avanzado

#### 1. Cálculo de Percentiles
Puedes calcular percentiles utilizando funciones de ventana.


SELECT empno, salary, 
       PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) AS percentile_rank
FROM employees;


#### 2. Primer y Último Valor
Accede al primer o último valor en el marco de la ventana.


SELECT empno, salary, 
       FIRST_VALUE(salary) OVER (PARTITION BY department ORDER BY salary) AS first_salary,
       LAST_VALUE(salary) OVER (PARTITION BY department ORDER BY salary 
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_salary
FROM employees;


# usar el row partition

SELECT 
    columna1,
    columna2,
    ROW_NUMBER() OVER (PARTITION BY columna1 ORDER BY columna2) AS numero_fila
FROM 
    tu_tabla;
```



### ¿Para qué sirve `CREATE STATISTICS`?
```sql

El comando `CREATE STATISTICS` en PostgreSQL se utiliza para crear estadísticas personalizadas sobre una o más columnas de una tabla. Estas estadísticas ayudan al optimizador de consultas a tomar decisiones más informadas sobre los planes de ejecución, lo que puede mejorar significativamente el rendimiento de las consultas.


1. **Mejorar el rendimiento de las consultas**:
   - Al proporcionar estadísticas adicionales, el optimizador puede estimar mejor la selectividad de las condiciones de las consultas, lo que resulta en planes de ejecución más eficientes.

2. **Estadísticas multicolumna**:
   - Puedes crear estadísticas sobre combinaciones de columnas que el optimizador no puede inferir automáticamente. Esto es útil cuando las columnas tienen una correlación significativa.

3. **Tipos de estadísticas**:
   - **NDISTINCT**: Estima el número de valores distintos en una combinación de columnas.
   - **Dependencies**: Captura dependencias entre columnas.
   - **MCE (Most Common Elements)**: Identifica los elementos más comunes en una combinación de columnas.

### Ejemplo de uso
 
CREATE STATISTICS stats_name (ndistinct, dependencies)
ON (columna1, columna2)
FROM nombre_de_la_tabla;
 

En este ejemplo, se crean estadísticas `NDISTINCT` y `Dependencies` sobre las columnas `columna1` y `columna2` de `nombre_de_la_tabla`.

### Ver estadísticas creadas

Para ver las estadísticas creadas, puedes consultar la vista `pg_statistic_ext`:
 
SELECT * FROM pg_statistic_ext WHERE stxname = 'stats_name';
 

Estas estadísticas pueden ser especialmente útiles en tablas grandes o en consultas complejas donde las estimaciones precisas son cruciales para el rendimiento¹.

 
[PostgreSQL Documentation](https://www.postgresql.org/docs/current/sql-createstatistics.html)
```


### ¿Para qué sirve `MERGE INTO`?
```sql
El comando `MERGE INTO` en SQL se utiliza para combinar datos de una tabla de origen con una tabla de destino. Este comando permite realizar operaciones de inserción, actualización o eliminación en la tabla de destino basándose en las coincidencias encontradas con la tabla de origen. Es especialmente útil para sincronizar dos tablas, asegurando que la tabla de destino refleje los cambios en la tabla de origen.
 

1. **Sincronización de tablas**:
   - Inserta nuevas filas en la tabla de destino si no existen en la tabla de origen.
   - Actualiza las filas existentes en la tabla de destino si coinciden con las filas de la tabla de origen.
   - Elimina las filas de la tabla de destino si no existen en la tabla de origen.

2. **Operaciones condicionales**:
   - Puedes especificar condiciones para determinar cuándo insertar, actualizar o eliminar filas.

### Ejemplo de uso
 
MERGE INTO tabla_destino AS destino
USING tabla_origen AS origen
ON destino.id = origen.id
WHEN MATCHED THEN
    UPDATE SET destino.columna1 = origen.columna1
WHEN NOT MATCHED THEN
    INSERT (id, columna1) VALUES (origen.id, origen.columna1);
 

En este ejemplo:
- Si una fila en `tabla_origen` coincide con una fila en `tabla_destino` (basado en la columna `id`), se actualiza la fila en `tabla_destino`.
- Si no hay coincidencia, se inserta una nueva fila en `tabla_destino`.
 ```



 # uso de FILTER
 Se utiliza para aplicar condiciones a funciones de agregación, permitiendo que solo las filas que cumplen con ciertas condiciones sean incluidas en los cálculos.
 por ejemplo las funciones  COUNT, SUM , MIN, MAX son funcion agregada 
```sql 

SELECT 
    COUNT(*) AS total_ventas,
    COUNT(*) FILTER (where precio = 99.8429332268752) AS precio_99,
	COUNT(*) FILTER (where fecha = '2022-06-05') AS fecha_filtrada
FROM ventas;


+--------------+-----------+----------------+
| total_ventas | precio_99 | fecha_filtrada |
+--------------+-----------+----------------+
|    499999999 |         1 |         501385 |
+--------------+-----------+----------------+
(1 row)

Time: 18101.188 ms (00:18.101)
```
 


# Ejemplos de JOINS


```sql

### Tablas de Ejemplo

Vamos a crear dos tablas: `clientes` y `pedidos`.

 
CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(50)
);

CREATE TABLE pedidos (
    id_pedido SERIAL PRIMARY KEY,
    id_cliente INT,
    producto VARCHAR(50),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

INSERT INTO clientes (nombre) VALUES ('Juan'), ('Ana'), ('Luis');
INSERT INTO pedidos (id_cliente, producto) VALUES (1, 'Laptop'), (2, 'Teléfono'), (2, 'Tablet');



postgres@postgres# select * from clientes;
+------------+--------+
| id_cliente | nombre |
+------------+--------+
|          1 | Juan   |
|          2 | Ana    |
|          3 | Luis   |
+------------+--------+
(3 rows)

Time: 0.742 ms
postgres@postgres# select * from pedidos;
+-----------+------------+----------+
| id_pedido | id_cliente | producto |
+-----------+------------+----------+
|         1 |          1 | Laptop   |
|         2 |          2 | Teléfono |
|         3 |          2 | Tablet   |
+-----------+------------+----------+
(3 rows)




### Tipos de Joins

1. **INNER JOIN**
   - **Descripción**: Devuelve las filas que tienen coincidencias en ambas tablas.
   - **Ejemplo**:
    
     SELECT clientes.nombre, pedidos.producto FROM clientes
     INNER JOIN pedidos ON clientes.id_cliente = pedidos.id_cliente;
     
   - **Resultado**:
	+--------+----------+
	| nombre | producto |
	+--------+----------+
	| Juan   | Laptop   |
	| Ana    | Teléfono |
	| Ana    | Tablet   |
	+--------+----------+
	(3 rows)
     

2. **LEFT JOIN (o LEFT OUTER JOIN)**
   - **Descripción**: Devuelve todas las filas de la tabla izquierda y las filas coincidentes de la tabla derecha. Las filas sin coincidencias en la tabla derecha tendrán valores NULL.
   - **Ejemplo**:
    
     SELECT clientes.nombre, pedidos.producto FROM clientes
     LEFT JOIN pedidos ON clientes.id_cliente = pedidos.id_cliente;
     
   - **Resultado**:
	+--------+----------+
	| nombre | producto |
	+--------+----------+
	| Juan   | Laptop   |
	| Ana    | Teléfono |
	| Ana    | Tablet   |
	| Luis   | NULL     |
	+--------+----------+
	(4 rows)
     

3. **RIGHT JOIN (o RIGHT OUTER JOIN)**
   - **Descripción**: Devuelve todas las filas de la tabla derecha y las filas coincidentes de la tabla izquierda. Las filas sin coincidencias en la tabla izquierda tendrán valores NULL.
   - **Ejemplo**:
    
     SELECT clientes.nombre, pedidos.producto FROM clientes
     RIGHT JOIN pedidos ON clientes.id_cliente = pedidos.id_cliente;
     
   - **Resultado**:
	+--------+----------+
	| nombre | producto |
	+--------+----------+
	| Juan   | Laptop   |
	| Ana    | Teléfono |
	| Ana    | Tablet   |
	+--------+----------+
	(3 rows)

     

4. **FULL JOIN (o FULL OUTER JOIN)**
   - **Descripción**: Devuelve todas las filas cuando hay una coincidencia en una de las tablas. Las filas sin coincidencias en cualquiera de las tablas tendrán valores NULL.
   - **Ejemplo**:
    
     SELECT clientes.nombre, pedidos.producto FROM clientes
     FULL JOIN pedidos ON clientes.id_cliente = pedidos.id_cliente;
     
   - **Resultado**:
	+--------+----------+
	| nombre | producto |
	+--------+----------+
	| Juan   | Laptop   |
	| Ana    | Teléfono |
	| Ana    | Tablet   |
	| Luis   | NULL     |
	+--------+----------+

     

5. **CROSS JOIN**
   - **Descripción**: Devuelve el producto cartesiano de las dos tablas, es decir, todas las combinaciones posibles de filas.
  
  - **Ejemplo**:
    
     SELECT clientes.nombre, pedidos.producto FROM clientes CROSS JOIN pedidos;
     
   - **Resultado**:
	+--------+----------+
	| nombre | producto |
	+--------+----------+
	| Juan   | Laptop   |
	| Juan   | Teléfono |
	| Juan   | Tablet   |
	| Ana    | Laptop   |
	| Ana    | Teléfono |
	| Ana    | Tablet   |
	| Luis   | Laptop   |
	| Luis   | Teléfono |
	| Luis   | Tablet   |
	+--------+----------+
	(9 rows)
     

6. **SELF JOIN**
   - **Descripción**: Es un join de una tabla consigo misma. Útil para comparar filas dentro de la misma tabla.
   - **Ejemplo**:
    
     SELECT c1.nombre AS cliente1, c2.nombre AS cliente2
     FROM clientes c1
     JOIN clientes c2 ON c1.id_cliente <> c2.id_cliente;
     
   - **Resultado**:
	+----------+----------+
	| cliente1 | cliente2 |
	+----------+----------+
	| Juan     | Ana      |
	| Juan     | Luis     |
	| Ana      | Juan     |
	| Ana      | Luis     |
	| Luis     | Juan     |
	| Luis     | Ana      |
	+----------+----------+
	(6 rows)
     
 
 

7. **LATERAL JOIN**
	- **Descripción**: Permite que una subconsulta en la cláusula FROM haga referencia a columnas de tablas anteriores en la misma cláusula FROM.
	- **Ejemplo**:
 
	  SELECT c.nombre, p.producto
	  FROM clientes c,
	  LATERAL (
		SELECT producto
		FROM pedidos p
		WHERE p.id_cliente = c.id_cliente
	  ) p;
	  
	- **Resultado**:
	+--------+----------+
	| nombre | producto |
	+--------+----------+
	| Juan   | Laptop   |
	| Ana    | Teléfono |
	| Ana    | Tablet   |
	+--------+----------+
	(3 rows)

  

8. **NATURAL JOIN**
	- **Descripción**: Realiza un join basado en todas las columnas con el mismo nombre en ambas tablas.
	- **Ejemplo**:
	 
	  SELECT *
	  FROM clientes
	  NATURAL JOIN pedidos;
	  
	- **Resultado**:
	+------------+--------+-----------+----------+
	| id_cliente | nombre | id_pedido | producto |
	+------------+--------+-----------+----------+
	|          1 | Juan   |         1 | Laptop   |
	|          2 | Ana    |         2 | Teléfono |
	|          2 | Ana    |         3 | Tablet   |
	+------------+--------+-----------+----------+

	  

9. **SEMI JOIN**
	- **Descripción**: Devuelve las filas de la primera tabla donde existen filas coincidentes en la segunda tabla, pero no devuelve las filas de la segunda tabla.
	- **Ejemplo**:
	 
	  SELECT c.nombre
	  FROM clientes c
	  WHERE EXISTS (
		SELECT 1
		FROM pedidos p
		WHERE p.id_cliente = c.id_cliente
	  );
	  
	- **Resultado**:
	+--------+
	| nombre |
	+--------+
	| Juan   |
	| Ana    |
	+--------+
	(2 rows)

  

10. **ANTI JOIN**
	- **Descripción**: Devuelve las filas de la primera tabla donde no existen filas coincidentes en la segunda tabla.
	- **Ejemplo**:
	 
	  SELECT c.nombre
	  FROM clientes c
	  WHERE NOT EXISTS (
		SELECT 1
		FROM pedidos p
		WHERE p.id_cliente = c.id_cliente
	  );
	  
	- **Resultado**:
	+--------+
	| nombre |
	+--------+
	| Luis   |
	+--------+
	(1 row)


```



## View tables using TOAST
```
SELECT
		c.relname AS source_table_name,
		c.relpages AS source_table_number_of_pages,
		c.reltuples AS source_table_number_of_tuples,
		c.reltoastrelid AS toast_table_oid,
		t.relname AS toast_table_name,
		t.relpages AS toast_table_number_of_pages,
		t.reltuples AS toast_table_number_of_tuples
	 FROM
		pg_class c
		JOIN pg_class t ON c.reltoastrelid = t.oid
	 WHERE
		t.relpages > 0;
--- https://www.crunchydata.com/postgres-tips#view-tables-using-toast
```


## Are you close to overflowing an integer?
```
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



--- https://www.crunchydata.com/postgres-tips#are-you-close-to-overflowing-an-integer 

```





# Ver las definiciones de los objetos 
```
postgres@postgres# select proname  from pg_proc where proname ilike '%pg_get_%' and  proname ilike '%def%'  group by proname;
+-------------------------------------+
|               proname               |
+-------------------------------------+
| pg_get_constraintdef                |
| pg_get_function_arg_default         |
| pg_get_functiondef                  |
| pg_get_indexdef                     |
| pg_get_partition_constraintdef      |
| pg_get_partkeydef                   |
| pg_get_ruledef                      |
| pg_get_statisticsobjdef             |
| pg_get_statisticsobjdef_columns     |
| pg_get_statisticsobjdef_expressions |
| pg_get_triggerdef                   |
| pg_get_viewdef                      |
+-------------------------------------+
(12 rows)
```


# Apagado de emergencia

```
1. **Apagado Ordenado**:
- **Uso de `SIGQUIT`**: Debe usarse solo en situaciones de emergencia debido a los riesgos de pérdida de datos no confirmados y la necesidad de una recuperación más extensa.
 

2. **Apagado Inmediato**:
   ```sh
   kill -QUIT <PID>
   ```
```
 

 
