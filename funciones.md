# Objetivo
Aprenderemos lo básico de funciones 

# Descripcion rápida de funciones
Una función en PostgreSQL (o en cualquier sistema de gestión de bases de datos) sirve para encapsular un conjunto de instrucciones SQL y lógica de negocio en una unidad lógica y reutilizable. <br>

Las funciones devuelven un valor, ya sea un valor escalar o una tabla, y pueden utilizarse en una consulta SQL como si fueran una columna.

**Ventajas  de usar funciones:**
<br> Su capacidad única de poder usarse dentro de una cláusula WHERE o en cualquier parte de un SELECT incluso dentro de los index. Esto es algo que un procedimiento NUNCA podrá hacer.
- **`Reutilización de Código:`** Puedes encapsular lógica compleja en funciones y reutilizarla en múltiples consultas o procedimientos almacenados.
- **`Seguridad:`** Las funciones permiten controlar el acceso a datos al definir permisos específicos para su ejecución.
- **`Rendimiento:`** PostgreSQL optimiza la ejecución de funciones y las incorpora en planes de consulta para mejorar el rendimiento de las consultas.

**Ventajas  de usar PROCEDIMIENTO ALMACENADO:**
 Su capacidad única de manejar transacciones (COMMIT/ROLLBACK). Esto es algo que una función NUNCA podrá hacer.

# Tipos de funciones  
```sql
IN: Solo entra.
OUT: Solo sale.
INOUT: Entra y sale.


**Funciones SQL**: Estas funciones están escritas en el lenguaje SQL y son ideales para operaciones simples y directas.
/*no necesitas el bloque BEGIN...END porque sql es un lenguaje de consulta directa.  */ 

CREATE FUNCTION my_function() RETURNS text AS $$
   SELECT 'Hello, World!';
$$ LANGUAGE sql;



**Funciones PL/pgSQL**: Estas funciones utilizan el lenguaje procedural PL/pgSQL, que es más potente y permite estructuras de control como bucles y condiciones.

   CREATE FUNCTION increment_by_one(x integer) RETURNS integer AS $$
   BEGIN
       RETURN x + 1;
   END;
   $$ LANGUAGE plpgsql;


**Funciones de ventana**: Estas funciones realizan cálculos sobre un conjunto de filas relacionadas con la fila actual, sin agruparlas en una sola fila de salida.
 
   SELECT depname, empno, salary, 
          avg(salary) OVER (PARTITION BY depname) AS avg_salary
   FROM empsalary;
 

**Funciones agregadas**: Realizan cálculos sobre un conjunto de valores y devuelven un solo valor.

   SELECT avg(salary) FROM empsalary;
 

. **Funciones de trigger**: Estas funciones se ejecutan automáticamente en respuesta a ciertos eventos en una tabla o vista.
 
   CREATE FUNCTION log_update() RETURNS trigger AS $$
   BEGIN
       INSERT INTO log_table VALUES (NEW.*);
       RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;
 

```





# Ejemplos de uso


### Ver el contenido de la funcion junto con el create

```
SELECT pg_get_functiondef('fun_actualiza_datos'::regproc);
SELECT pg_get_functiondef(f.oid) FROM pg_catalog.pg_proc f    WHERE f.proname = 'fun_actualiza_datos';
```

### Guardar en un archivo la funcion bien estructurada con los CREATE OR REPLACE 
```
psql mydbatest -c "SELECT pg_get_functiondef('fun_actualiza_datos'::regproc)" | grep -Ev "pg_get_functiondef|rows\)|row\)" > /tmp/fun_TI.txt && sed -i 's/\\r//g'  /tmp/fun_TI.txt
```

### Guardar en un archivo la funcion,  sin el CREATE
```
copy (select  prosrc  from  pg_proc  wHERE proname ilike '%fun_actualiza_datos%'  ) to '/tmp/fun_TI.txt' WITH CSV HEADER;
```

### Parámetros para agregar al crear una funcion

```sql
------ Tipos de SECURITY:
SECURITY DEFINER: Ejecuta la función con los privilegios del propietario de la función en lugar del usuario que la llama.
SECURITY INVOKER: Ejecuta la función con los privilegios del usuario que la llama (este es el valor predeterminado).

--- Tipos de Volatility :
	VOLATILE: La función puede devolver resultados diferentes incluso con los mismos parámetros de entrada. Se asume por defecto.
		y por lo tanto, no puede ser optimizada por el planificador de consultas.
	STABLE: La función devuelve los mismos resultados para las mismas entradas dentro de una sola consulta.
	IMMUTABLE: La función siempre devuelve los mismos resultados para las mismas entradas, independientemente de cuándo se llame.


LANGUAGE: Especifica el lenguaje en el que está escrita la función (por ejemplo, plpgsql, sql, c, etc.).
RETURNS: Define el tipo de dato que devuelve la función.
COST: Estima el costo de ejecución de la función, lo que puede influir en el planificador de consultas.
ROWS: Especifica el número estimado de filas que devuelve una función que retorna un conjunto.
SET: Permite establecer parámetros de configuración específicos para la duración de la función.
STRICT: La función no se llama si alguno de sus argumentos es nulo.
RETURNS NULL ON NULL INPUT: Similar a STRICT, pero más explícito.

LEAKPROOF: Indica que la función no revela información sobre sus argumentos a través de canales laterales.
	 no debe revelar información sobre sus argumentos a través de mensajes de error u otros medios.
	Esto es crucial para evitar que usuarios no autorizados obtengan información sensible.

--- PARALLEL: Define si la función puede ser ejecutada en paralelo  
	PARALLEL SAFE: La función es segura para ser ejecutada en paralelo ,
		solo aplica para  Las funciones que solo leen datos.
	PARALLEL RESTRICTED: La función puede ser ejecutada en paralelo, pero con ciertas restricciones ,
		solo aplica para Acceso a tablas temporales o conexiones de cliente.
	PARALLEL UNSAFE: La función no es segura para ser ejecutada en paralelo ,
		solo aplica para Funciones que modifican datos (usando INSERT, UPDATE, DELETE).

WINDOW: Indica que la función es una función de ventana.
SUPPORT: Especifica una función de soporte para optimizaciones

COST 100: El parámetro COST establece un costo estimado para la función, que el planificador de consultas de PostgreSQL
 usa para decidir el plan de ejecución más eficiente. El valor por defecto es 100, pero puedes ajustarlo para reflejar
mejor el costo relativo de la función en comparación con otras operaciones

SET statement_timeout = '5min'; --- nos permite configurar parametros en la funcion 
```


### Configurarle parametros en las funciones
```

CREATE OR REPLACE FUNCTION mi_funcion()
RETURNS void AS $$
BEGIN
    -- Lógica de la función
END;
$$ LANGUAGE plpgsql
SET work_mem = '64MB'
SET search_path = 'mi_esquema'
SET statement_timeout = '5min';
```


### EJEMPLO DE UNA FUNCION BIEN DOCUMENTADA Y ESTRUCTURADA

```
 
/*********************************************************
 @Function: fun_ejemplo
 @Creation Date: 24/01/2025
 @Description: Genera Errores dependiendo del valor.
 @Parameters:
   - @p_gen_exception (INT): Num para generar un error.
 
 @Returns: VOID - Total sales for the given period.
 @Author: CR0NYM3X

 ---------------- HISTORY ----------------
 @Date: 24/01/2025
 @Change: Se agrego un ELSEIF.
 @Author: CR0NYM3X


 ---------------- LOG ----------------
 CREATE SCHEMA IF NOT EXISTS log;
 
 
 -- DROP TABLE log.functions;
 -- TRUNCATE TABLE log.functions RESTART IDENTITY ;
 CREATE TABLE IF NOT EXISTS log.functions (
		log_id SERIAL PRIMARY KEY,          -- Identificador único para cada registro de log
		status VARCHAR(10) NOT NULL,        -- Estado del log (e.g., 'FAILED')
		db_name TEXT NOT NULL,              -- Nombre de la base de datos
		fun_name TEXT NOT NULL,             -- Nombre de la función
		ip_client INET,                     -- Dirección IP del cliente
		user_name TEXT NOT NULL,            -- Nombre del usuario
		query TEXT NOT NULL,                -- Consulta ejecutada
		msg TEXT,                           -- Mensaje de error
		start_time TIMESTAMP,             -- Hora de inicio de la ejecución
		date_insert TIMESTAMP DEFAULT clock_timestamp()  -- Fecha y hora de inserción del log
	);
 
	SELECT * FROM log.functions;

 ---------------- EXAMPLE USAGE ----------------
 -- To remove the function:
 -- DROP FUNCTION fun_ejemplo(INT);

 -- To call the function:
 -- SELECT fun_ejemplo(1);
 
 
*********************************************************/


CREATE OR REPLACE FUNCTION public.fun_ejemplo( p_gen_exception INT DEFAULT 1 ) 
RETURNS VOID AS 

$$
DECLARE
    
	-- Guarda el parametro en la variable 
	v_gen_exception INT := p_gen_exception ;
	
	v_start_time timestamp;
	v_msg TEXT := '';
	v_status VARCHAR(15) := 'successful';

BEGIN
	v_start_time := clock_timestamp(); 
 
	-- Validacion de parametro 
	IF v_gen_exception = 1 THEN
		v_status := 'failed';
		SELECT 1/0;
	ELSEIF v_gen_exception = 2 THEN
		v_status := 'failed';
		RAISE  EXCEPTION 'ID_LINE:1L SE INTENTO DIVIR A 0';
	ELSE		
		RAISE  NOTICE E'\n HOLA MUNDO!!!! ';
		
	END IF;
	
	
	INSERT INTO log.functions( status, db_name, fun_name, ip_client, user_name, query, msg,  start_time, date_insert)
									SELECT v_status, current_database(), 'public.fun_ejemplo', coalesce( host(inet_client_addr()) , '127.0.0.1')::INET, session_user, current_query() , v_msg , v_start_time, clock_timestamp();	
	RETURN;
	
-- MANEJOR DE ERRORES
EXCEPTION 
	WHEN OTHERS THEN
		v_msg := v_msg || ' ID_EXCEP:10E ' || SQLSTATE || ' Error: ' || SQLERRM;
		RAISE NOTICE E'\r%',v_msg ;		
		INSERT INTO log.functions( status, db_name, fun_name, ip_client, user_name, query, msg,  start_time, date_insert)
									SELECT v_status, current_database(), 'public.fun_ejemplo', coalesce( host(inet_client_addr()) , '127.0.0.1')::INET, session_user, current_query() , v_msg , v_start_time, clock_timestamp();
		
	WHEN QUERY_CANCELED  THEN
		v_msg := v_msg || ' ID_EXCEP:10E ' || SQLSTATE || ' Error:' || SQLERRM;
		RAISE NOTICE E'\r%',v_msg ;		
		INSERT INTO log.functions( status, db_name, fun_name, ip_client, user_name, query, msg, start_time, date_insert)
									SELECT v_status, current_database(), 'public.fun_ejemplo', coalesce( host(inet_client_addr()) , '127.0.0.1')::INET, session_user, current_query() , v_msg , v_start_time, clock_timestamp();
	
END;
$$ 
LANGUAGE plpgsql  
SECURITY DEFINER
SET client_min_messages = 'notice'
SET statement_timeout = 0
SET lock_timeout = 0 ;


 


 

```

**`CREATE OR REPLACE FUNCTION:`** Esto es parte de la declaración de la función que indica que estás creando una nueva función o reemplazando una existente si ya existe con el mismo nombre.<br>
**`nombre_de_la_funcion:`** Aquí debes proporcionar un nombre significativo para tu función.<br>
**`parámetros_de_entrada:`** Puedes especificar los parámetros de entrada que la función aceptará. Estos pueden incluir nombres y tipos de datos.<br>
**`RETURNS tipo_de_dato_de_retorno:`** Define el tipo de dato que la función devolverá como resultado.<br>
**`$$:`** Esto marca el comienzo del bloque de código PL/pgSQL.<br>
**`DECLARE:`** En esta sección, puedes declarar variables locales que se utilizarán dentro de la función. Las variables se declaran con su nombre y tipo de dato.<br>
**`BEGIN:`** Marca el inicio del cuerpo de la función. Aquí es donde colocas las instrucciones SQL y la lógica de negocio de la función.<br>
**`END:`** Marca el Final del cuerpo de la función.<br>
**`RETURN:`** Indica qué valor o variable se devolverá como resultado de la función.<br>
**`$$:`** Marca el final del bloque de código PL/pgSQL.<br>
**`LANGUAGE plpgsql:`** Define el lenguaje utilizado para escribir la función, que en este caso es PL/pgSQL.


### Eliminar una función:
```
DROP FUNCTION IF EXISTS calcular_promedio_ventas();
```

### para ver los parámetros de una funcion :VOLATILE SECURITY DEFINER PARALLEL UNSAFE
```
select provolatile,proparallel,security_type  FROM pg_proc a inner join information_schema.routines b on a.proname = b.routine_name where a.proname = 'fun_actualiza_datos';
```

###  para ver los privilegios de las funciones 
```
SELECT routines.routine_name, routines.specific_name, routine_type, grantee, privilege_type FROM information_schema.routines LEFT JOIN information_schema.routine_privileges ON routines.specific_name = routine_privileges.specific_name WHERE grantee = 'nombre_del_usuario' AND routine_name = 'fun_actualiza_datos';
```

###  Asignar los privilegios a funciones 
Para realizar esta actividad podemos consultar el archivo [usuarios, accesos y permisos.md](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/usuarios%2C%20accesos%20y%20permisos.md#asignar-permisos-l%C3%B3gicos-select-update-delete-etc)





### ver todos los parámetros de una funcion 
```
\df *pg_fun*

#Ver los parámetros de una función
SELECT
    r.specific_name AS function_identifier,
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
    r.data_type AS return_type
FROM information_schema.routines r
JOIN information_schema.parameters p
    ON r.specific_name = p.specific_name
    AND r.specific_schema = p.specific_schema
WHERE r.specific_schema = 'public'  -- Cambia 'public' al esquema deseado
and r.routine_name = 'fun_actualiza_datos'  
ORDER BY r.routine_name, p.ordinal_position;

#Vemos todas las funciones y sus parámetros 
SELECT   proname , proargnames, pg_catalog.oidvectortypes(proargtypes)  FROM pg_proc where proname in(SELECT routine_name FROM information_schema.routines WHERE routine_type = 'FUNCTION' AND specific_schema = 'public') 

```


# info Extra

La tabla information_schema.routines contiene información sobre las rutinas almacenadas, como funciones y procedimientos almacenados en la base de datos. Algunos de los campos importantes en esta tabla son:

**`specific_name:`** El nombre único de la rutina. <br>
**`routine_name:`** El nombre de la rutina.<br>
**`routine_type:`** Indica si es una función o un procedimiento.<br>
**`data_type:`** El tipo de datos que devuelve la rutina.<br>
```

SELECT routine_name, routine_type, data_type FROM information_schema.routines WHERE specific_schema = 'public';
```

La tabla information_schema.parameters contiene información sobre los parámetros de entrada y salida de las rutinas almacenadas en la base de datos. Algunos de los campos importantes en esta tabla son:

**`specific_name:`** El nombre único de la rutina a la que pertenecen los parámetros.<br>
**`parameter_name:`** El nombre del parámetro.<br>
**`data_type:`** El tipo de datos del parámetro.<br>
**`ordinal_position:`** La posición del parámetro en la lista de parámetros de la rutina.<br>
```
SELECT parameter_name, data_type, ordinal_position FROM information_schema.parameters WHERE specific_name = 'nombre_unico_de_la_funcion';
```

# try catch función anónima/bloque anónimo
los bloque anónimo o función anónima transitoria en PostgreSQL. Estos bloques se ejecutan usando la instrucción DO y permiten ejecutar código PL/pgSQL sin necesidad de crear una función permanente.
```SQL

variables predefinidas para obtener información sobre el error que ocurrió.
SQLERRM:  Contiene el mensaje de error asociado con el error que ocurrió.
SQLSTATE:  Contiene el código de estado SQL (SQLSTATE) del error que ocurrió. Este es un código estándar de cinco caracteres que identifica el tipo de error.
 

DO $$
DECLARE
  text_var1 text;
  text_var2 text;
  text_var3 text;
BEGIN
    -- Bloque de código donde puede ocurrir una excepción
    BEGIN
        -- Intenta ejecutar una operación que genere un error (por ejemplo, dividir por cero)
        PERFORM 1 / 0; -- Esto generará un error de división por cero

	-- PARA GENERAR UN ERROR PUEDES USAR RAISE:
	--- RAISE EXCEPTION '  ESTE MENSAJE DE ERROR  ';
    EXCEPTION
        WHEN division_by_zero THEN
            -- Captura la excepción específica de división por cero
            RAISE NOTICE 'Error de división por cero capturado: %', SQLERRM;

	  GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
	                          text_var2 = PG_EXCEPTION_DETAIL,
	                          text_var3 = PG_EXCEPTION_HINT;
    END;
    
    -- Más código después del bloque try-catch
    RAISE NOTICE  'Operación después del bloque try-catch';
END $$;


********** RAISE ********** 

 la instrucción RAISE se utiliza para generar mensajes de error, advertencias o excepciones. 
 
   RAISE EXCEPTION 'Este es un mensaje de error personalizado';
   También puedes incluir un estado de STATE:
   RAISE EXCEPTION 'Error personalizado' STATE '99000';
  
2. **RAISE NOTICE**: Se utiliza para emitir un mensaje de advertencia o información. Estos mensajes no detienen la ejecución del código.
   RAISE NOTICE 'Esto es un mensaje de advertencia o información %', SQLERRM;
  
3. **RAISE WARNING**: Similar a RAISE NOTICE, pero a menudo se utiliza para situaciones menos críticas. También se usa para emitir advertencias.
   RAISE WARNING 'Advertencia: Esto es una advertencia';
  
4. **RAISE DEBUG**: Se utiliza para emitir mensajes de depuración. Estos mensajes son útiles durante el desarrollo o para diagnósticos.
   RAISE DEBUG 'Mensaje de depuración: Esto es un mensaje de depuración';
  
5. **RAISE INFO**: Se utiliza para emitir mensajes informativos. Estos mensajes son útiles para registrar información detallada durante la ejecución.  
   RAISE INFO 'Mensaje informativo: Esto es un mensaje informativo';
  
6. **RAISE LOG**: Se utiliza para registrar mensajes en el registro de eventos de Postgre (log). Esto es útil para auditoría y seguimiento.

   RAISE LOG 'Mensaje para el registro: Esto se registrará en el registro de eventos';



********** DIAGNOSTICS que se pueden usar **********


GET DIAGNOSTICS filas_afectadas = ROW_COUNT  ---> Este se usa despues de usar execute   https://www.postgresql.org/docs/16/plpgsql-statements.html#PLPGSQL-STATEMENTS-DIAGNOSTICS 
GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT; ----> este se usa cuando un execute marca error y estas dentro de un EXCEPTION  https://www.postgresql.org/docs/16/plpgsql-control-structures.html#PLPGSQL-EXCEPTION-DIAGNOSTICS

********** EXCEPCIÓN QUE SE PUEDEN USAR **********
 

 PostgreSQL Error Codes --- https://www.postgresql.org/docs/current/errcodes-appendix.html

[NOTA] La condición especial OTHERS coincide con todos los tipos de error excepto QUERY_CANCELED y ASSERT_FAILURE.

 WHEN query_canceled THEN
 	RAISE NOTICE 'La consulta fue cancelada porque excedió el tiempo límite de 5 segundos';
 WHEN unique_violation THEN
    RAISE NOTICE 'Violación de unicidad: El producto con ID 1 ya existe.';
  WHEN foreign_key_violation THEN
    RAISE NOTICE 'Violación de clave foránea.';
  WHEN check_violation THEN
    RAISE NOTICE 'Violación de restricción CHECK.';
  WHEN not_null_violation THEN
    RAISE NOTICE 'Violación de restricción NOT NULL.';
  WHEN division_by_zero THEN
    RAISE NOTICE 'División por cero.';
  WHEN invalid_cursor_state THEN
    RAISE NOTICE 'Estado de cursor inválido.';
  WHEN invalid_text_representation THEN
    RAISE NOTICE 'Representación de texto inválida.';
  WHEN numeric_value_out_of_range THEN
    RAISE NOTICE 'Valor numérico fuera de rango.';
  WHEN deadlock_detected THEN
    RAISE NOTICE 'Interbloqueo detectado.';
  WHEN syntax_error THEN
    RAISE NOTICE 'Error de sintaxis.';
  WHEN insufficient_privilege THEN
    RAISE NOTICE 'Privilegios insuficientes.';
  WHEN program_limit_exceeded THEN
    RAISE NOTICE 'Límite de programa excedido.';
  WHEN OTHERS THEN
    RAISE NOTICE 'Ocurrió un error: %', SQLERRM;
END $$;

https://www.postgresql.org/docs/current/plpgsql-errors-and-messages.html
https://www.postgresql.org/docs/current/plpgsql-control-structures.html
https://www.postgresqltutorial.com/postgresql-plpgsql/postgresql-exception/



```




# Ejemplos de funciones
```sql
CREATE OR REPLACE FUNCTION verificar_ip_puerto(ip INET, puerto INTEGER)
RETURNS INTEGER AS $$
BEGIN


    IF ip IS NOT NULL AND puerto IS NOT NULL THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
	
	
END;
$$ LANGUAGE plpgsql;


SELECT verificar_ip_puerto('192.168.1.1', 5432);





CREATE OR REPLACE FUNCTION usar_valores_tabla()
RETURNS VOID AS $$
DECLARE
    var_columna1 tipo_columna1;
    var_columna2 tipo_columna2;
BEGIN
    -- Selecciona los valores de la tabla y los guarda en variables
    SELECT columna1, columna2 INTO var_columna1, var_columna2
    FROM tabla_test
    LIMIT 1;

    -- Aquí puedes usar las variables para cualquier operación que necesites
    RAISE NOTICE 'Valor de columna1: %, Valor de columna2: %', var_columna1, var_columna2;

    -- Ejemplo de uso en otra función
    PERFORM verificar_ip_puerto(var_columna1::INET, var_columna2::INTEGER);
END;
$$ LANGUAGE plpgsql;
```


# función que retorne múltiples valores utilizando un tipo compuesto o un registro 
Esto te retorna valores como si fuera una tabla y puedes trabajar con ellos como si fuera una tabla puedes aplicarles where ,order, group , etc 
```sql
--/*********** OPCIÓN #1 Usando un Tipo Compuesto ***********\

-- Primero, crea un tipo compuesto que defina la estructura de los valores que deseas retornar:


CREATE TYPE mi_tipo_compuesto AS (
    mi_entero INT,
    mi_texto VARCHAR
);


-- Luego, crea una función que retorne este tipo compuesto:

 
CREATE OR REPLACE FUNCTION mi_funcion_compuesta() 
RETURNS mi_tipo_compuesto 
AS $$
DECLARE
    resultado mi_tipo_compuesto;
BEGIN
    -- Asigna valores a los campos del tipo compuesto
    resultado.mi_entero := 42;
    resultado.mi_texto := 'Hola, mundo';
    
    -- Retorna el tipo compuesto
    RETURN resultado;
END;
$$ LANGUAGE plpgsql;

 select  * from mi_funcion_compuesta() ;

--/***********  OPCIÓN #2 Usando un Registro ***********\

-- Alternativamente, puedes usar un registro para retornar múltiples valores sin definir un tipo compuesto:

 
CREATE OR REPLACE FUNCTION mi_funcion_registro()
RETURNS TABLE(mi_entero INT, mi_texto VARCHAR)
AS $$
BEGIN
    -- Retorna los valores directamente, asegurando que el tipo de dato sea VARCHAR
    RETURN QUERY SELECT 42, 'Hola, mundo'::VARCHAR;
END;
$$ LANGUAGE plpgsql;

 select  * from mi_funcion_registro();

```

### Agregar alias a los parámetros 
```
CREATE OR REPLACE FUNCTION ejemplo_funcion(parametro INTEGER)
RETURNS INTEGER AS $$
DECLARE
    parametro_alias ALIAS FOR $1; -- Alias para el parámetro
    parametro INTEGER; -- Variable local con el mismo nombre
BEGIN
    -- Asignar valor a la variable local
    parametro := parametro_alias + 10;

    -- Usar el alias del parámetro
    RETURN parametro_alias * parametro;
END;
$$ LANGUAGE plpgsql;
```

### FUNCIONES QUE RETORNAN TABLAS VARIABLES 
```
CREATE OR REPLACE FUNCTION ejecutar_consulta_dinamica(consulta TEXT)
RETURNS SETOF RECORD AS $$
BEGIN
	
    RETURN QUERY EXECUTE consulta;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM ejecutar_consulta_dinamica('select schemaname::varchar,tablename::varchar,tableowner::varchar from pg_tables limit 10')  AS t(schemaname varchar,tablename varchar, tableowner varchar);
```



# TIPS
```
----- 	EJECUTAR UNA FUNCION 
perform mssql.fun_test_connection(); -- Se usa cuando quieres ejecutar una consulta SELECT pero no te interesa el resultado. Es útil para ejecutar funciones que tienen efectos secundarios (como modificar datos) pero cuyos resultados no necesitas procesar.

SELECT mssql.fun_test_connection(); --- Se usa cuando quieres recuperar datos y hacer algo con ellos, como almacenarlos en una variable o devolverlos como resultado de la función. Si usas SELECT sin especificar un destino para los datos (como una variable), obtendrás un error porque PostgreSQL no sabe qué hacer con los resultados.

---- Ejecutar una funcion y guardar el resultado en variable
var1 : =  mssql.fun_test_connection();

--- DECLARAR UNA VARIABLE CON UN TIPO DE MULTIPLES COLUMNAS Y TAMAÑO
columnas RECORD;

--- ejecutar querys 
EXECUTE 'select version()'

--- guardar la ejecucion en una variable
EXECUTE 'select version()'  into valor_query ;

--- puedes retornar sin necesidad  retornar a fuerzas un valor 
RETURN ;

--- no retornar nada
RETURNS VOID

--- Salir del bucle    
   EXIT;


--- USAR FOUND
FOUND es una variable especial que se utiliza para verificar el resultado de la última sentencia SQL ejecutada.
	Es particularmente útil para saber si una consulta afectó a alguna fila o no

¿Cuándo se Establece FOUND?
FOUND se establece en TRUE si:
	Una consulta SELECT INTO o PERFORM encuentra al menos una fila.
	Una sentencia INSERT, UPDATE, DELETE o FETCH afecta al menos una fila.
FOUND se establece en FALSE en caso contrario


--- Herramienta
es muy útil para obtener información sobre la ejecución(INSERT, UPDATE, DELETE, o MERGE) dentro de funciones
GET DIAGNOSTICS filas_afectadas = ROW_COUNT;

```


https://postgresconf.org/system/events/document/000/001/086/plpgsql.pdf
<br> https://www.postgresql.org/docs/current/sql-createfunction.html

<br> https://www.postgresql.org/docs/16/plpgsql-statements.html
