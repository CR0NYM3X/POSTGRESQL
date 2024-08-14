
SELECT pg_current_logfile() <br>
select * from pg_ls_logdir()  <br>

 select * from pg_file_settings where name ='port';  <br>
 select * from pg_settings  <br>
 
 select * from pg_hba_file_rules  <br>
 Select * from pg_config  <br> 
 
 


CAST ('10' AS INTEGER); convertir string a int --- O  (idu_valorconfiguracion)::INT
select replace('test string','st','**') --, te** **ring
SELECT numerador / NULLIF(denominador, 0) AS resultado

--- Tipos de JOIN: 
CROSS join --> Es como juntar 2 tablas con una coma ","  --- > https://www.postgresql.org/docs/current/queries-table-expressions.html

 SELECT regexp_replace('Hola 123 mu,ndo', '[a-zA-Z0-9\s]', '', 'g') --- quitar letras y números 
 
select CLOCK_TIMESTAMP()   -- 2022-11-30 16:36:18 hora
select unnest(array['Enero', 'Febrero', 'Marzo', 'Abril','Mayo','Junio']) --  Convertir columnas a filas
select round(random()*10) ---- random 
select round(random()* (3-1)  +1 )
SELECT to_char((3::float/2::float), 'FM999999999.00')
select (3::float/2::float)

SELECT round((3/2)::numeric,2 ) -- ponerle 2 decimal en 00
select TRUNC(5, 3) ---> agrega 3 decimales  trunc 5.000


select ceiling(12.34) -- redondea todo hacia arriba
select floor(12.23) --  redondea todo hacia abajo
select cast(52.55 as decimal(18,2) ) -- le permite dejar 2 decimales y el 18 es la precisión o el redodeo

Quitar el utlimo caracter
```sql
substring(fecha_registro::text, 1, 4)
select 	substring('arwdDxt' FROM 1 FOR length('arwdDxt') - 1); -- > V  8
select LEFT('arwdDxt', LENGTH('arwdDxt') - 1); -- > V 8
```sql

SELECT Abs(20) AS AbsNum; ---- esta función siempre te retorna un positivo
SELECT sign(20) AS AbsNum; --- esta función siempre te retorana 1 si es número es positvo y si es negativo te retorna -1

select lpad('Hola Mundo',20,'-'); -- retorna '----------Hola Mundo'. tambien hay rpad que hace lo mismo pero al reves

lower(string): | upper('Hola'); ----- Convertir a mayúsculas o minúsculas 

---- restar o sumar dias en fechas
SELECT CAST(now() AS DATE)
SELECT CAST(now()::date AS DATE) + CAST('-1 days' AS INTERVAL);
SELECT  now()::date  + CAST('1 days' AS INTERVAL);

---- Sacar los días MES
select EXTRACT(DAY FROM now()::date)
select EXTRACT(MONTH FROM now()::date) 
select EXTRACT(YEAR  FROM now()::date) 
select EXTRACT(HOURS  FROM now()) 

select age(timestamp '2011-10-01 ', timestamp '2011-11-01') --- saber los días que pasan 
select ('2011-11-01'::date -  '2011-12-028'::date)--- saber los días que pasan  

select to_char( timestamp'2009-12-31 11:25:50' , 'HH12:MI:SS') >  '12:26:52'
SELECT timestamp'2009-12-31 12:31:50' - INTERVAL '30 minutes' AS nueva_hora_llegada --- sumar o restar minutos 


  select extract(hour  from  timestamp'2009-12-31 12:25:50');
 select extract(minute from  timestamp'2009-12-31 12:25:50');
select extract(second from  timestamp'2009-12-31 12:25:50');





select  concat( ' hola ' , SL , 'Mundo'   )   from   (  select E'\r\n' SL  )a
select concat ( 'hola ',CHR(13),CHR(10) , 'mundo'  ) --  concat( E'homa \r\n mundo')   -------- Generar saltos de linea
select regexp_replace(columna, E'[\\n\\r]+', ' ', 'g' ) as columna_nueva  ----- Eliminar saltos de linea
select nullif('','a')
-------- Cambiar nulos a ceros :  select coalesce(  pagotargeta , 0)
select encode(E''::bytea, 'hex') -- https://www.educba.com/postgresql,encode/

select encode( '', 'hex') -- https://www.postgresql.org/docs/8.2/functions-string.html
select encode('asdasd', 'base64');
select decode('MTExMQ==', 'base64')::text
char_length(trim(imei)) ------ Saber el tamaño de caracteres 
REPLACE(' text ', ' ', ''); ----- eliminar todos los espacios
replace(replace(replace(trim(descripcion),' ','<>'),'><',''),'<>',' ') -- con esto quita todos los espacios y los cambia por 1 espacio

select 'aaaa'||  CHR(10) || 'hola' -- salto de linea
 CHR(39)  ------- Comilla simple
  CHR(34)  ------- Comilla dobles
 CHR(9) --- tab

coalesce(  max(campoNull  ) , 0)  ----- Cambiar un campo null a 0
select substring(nombre, 1, 2) from nombres; ----- Estraer los caracteres especificos

SELECT * from mupaquetes where fec_fechamovto::date between '20210501' and '20210531'
29555 BETWEEN num_dcfinicial AND num_dcffinal 

select  sign(  -10 ) ---- no importa el valor siempre retorna 1 o -1 /  si el argumento es un valor positivo devuelve 1;-1 si es negativo y si es 0, 0. Ejemplo:






--- convertir en una columna un array
```sql
select    unnest(array[ 822, 823, 2782, 2994, 2171,509,722, 1428,106,107,108 ])  codigo)a 
```


```sql

########## CONDICIONEALES IF ########## 

DO $$
DECLARE
    a INT := 5;
    resultado VARCHAR;
BEGIN
    IF a > 0 THEN
        resultado := 'El número es positivo.';
    ELSE
        resultado := 'El número es negativo o cero.';
    END IF;

    RAISE NOTICE '%', resultado;
END;
$$;

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


# join


```sql
# INNER JOIN: Devuelve filas cuando hay al menos una coincidencia en ambas tablas.

SELECT * FROM tabla1 INNER JOIN tabla2 ON tabla1.columna = tabla2.columna;

/* LEFT JOIN (o LEFT OUTER JOIN): Devuelve todas las filas de la tabla izquierda y las filas
 coincidentes de la tabla derecha. Si no hay coincidencias, se devuelven NULL para las columnas de la tabla derecha. */ 

SELECT * FROM tabla1 LEFT JOIN tabla2 ON tabla1.columna = tabla2.columna;

/* RIGHT JOIN (o RIGHT OUTER JOIN): Devuelve todas las filas de la tabla derecha y las filas coincidentes
de la tabla izquierda. Si no hay coincidencias, se devuelven NULL para las columnas de la tabla izquierda. */ 

SELECT * FROM tabla1 RIGHT JOIN tabla2 ON tabla1.columna = tabla2.columna;

/* FULL JOIN (o FULL OUTER JOIN): Devuelve todas las filas cuando hay una coincidencia
en una de las tablas. Devuelve NULL en las columnas de la tabla que no tiene una coincidencia. */

SELECT * FROM tabla1  FULL JOIN tabla2 ON tabla1.columna = tabla2.columna;

/*
CROSS JOIN: Devuelve el producto cartesiano de las filas de las tablas involucradas, es decir,
combina cada fila de la primera tabla con cada fila de la segunda tabla.
 */
SELECT * FROM tabla1 CROSS JOIN tabla2;

/* LEFT JOIN LATERAL: Combina cada fila de la primera tabla con el resultado de aplicar una
 expresión de tabla a cada fila de la segunda tabla, pero solo devuelve filas de la primera tabla
incluso si no hay coincidencias en la expresión de tabla. */ 

SELECT * FROM tabla1 LEFT JOIN LATERAL funcion_tabla2(tabla1.columna) AS tabla2_resultado ON true;

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

# trabajando con texto 
```sql

/* DIVIDE EN COLUMNAS UN TEXTO */
select split_part('hola = mundo','=' , 1 ); --> Return: "hola"
select split_part('hola = mundo','=' , 2 ); --> Return: "mundo"

SELECT split_part('texto1,texto2,texto3', ',', generate_series(1, length('texto1,texto2,texto3') - length(replace('texto1,texto2,texto3', ',', '')) + 1)) AS columna_individual; ---  < V9

SELECT regexp_split_to_table('INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER', ','); -- > V 9

/* REMPLZA  EL TEXTO */
select replace('hola = mundo','=' , ''); --> Return: 'hola   mundo'

/* CONVIERTE EN TEXTO UN ARRAY */
SELECT array_to_string( ARRAY['Juan', 'María', 'Pedro']  , ' - ');

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

# usar el row partition
```sql
SELECT 
    columna1,
    columna2,
    ROW_NUMBER() OVER (PARTITION BY columna1 ORDER BY columna2) AS numero_fila
FROM 
    tu_tabla;
```


# como hacer un RollBack en la base de datos
**`[NOTA]`** Cada sesión puede tener su propia transacción independiente. Por lo tanto, si ejecutas un BEGIN en una sesión y no lo cierras, solo afectará a esa sesión específica. Otras sesiones no se verán afectadas por la transacción no cerrada en la primera sesión. <br><br>



El **begin** Permite que las transacciones/operaciones sean aisladas y transparentes unas de otras, esto quiere decir que si una sesion nueva se abre, no va detectar los cambios realizados en el cuando se incia el begin como son los insert,update,delete etc, 
 ```
BEGIN TRANSACTION;
 ```
El **commit**  se usa para guardar los cambios que se realizaron, como los insert,detelete, etc y estas seguro de que todo salio bien
 ```
COMMIT:
 ```
el **rollback** se usa en caso de que algo salio mal  y no quieres que se guarden los cambios entonces puedes hacer los rollback completo o un un rollback punto de guardado
 ```
rollback;
rollback my_name_savepoint;
 ```

el **savepoint** sirve para hacer un punto de guardado, en caso de realizar varios cambios en un begin 
 ```
savepoint my_name_savepoint;
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
SELECT TO_DATE('October 09, 2012', 'Month DD, YYYY');
```


### Manejo de strings 
```
split_part('16.0.4135.4', '.',1)
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

---- convertir el array en columnas 
SELECT
    id,
    unnest(mi_array) AS elemento
FROM
    mi_tabla;


--- buscar un resultado en un arreglo
SELECT *
FROM mi_tabla
WHERE 'perro' = ANY(mi_array);
```
