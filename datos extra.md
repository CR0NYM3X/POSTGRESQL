
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

substring(fecha_registro::text, 1, 4)

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





