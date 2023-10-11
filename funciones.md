# Objetivo
Aprenderemos lo básico de funciones 

# Descripcion rápida de los esquemas
Una función en PostgreSQL (o en cualquier sistema de gestión de bases de datos) sirve para encapsular un conjunto de instrucciones SQL y lógica de negocio en una unidad lógica y reutilizable.

**Ventajas  de usar funciones:**
- **`Reutilización de Código:`** Puedes encapsular lógica compleja en funciones y reutilizarla en múltiples consultas o procedimientos almacenados.
- **`Seguridad:`** Las funciones permiten controlar el acceso a datos al definir permisos específicos para su ejecución.

- **`Rendimiento:`** PostgreSQL optimiza la ejecución de funciones y las incorpora en planes de consulta para mejorar el rendimiento de las consultas.



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


### Crear una Función:

```
-- Definición de la función
CREATE OR REPLACE FUNCTION calcular_precio_total(p_id INT, p_cantidad INT)
RETURNS NUMERIC AS
$$
DECLARE

    -- Aquí se declaran las variables locales
    v_precio_unitario NUMERIC;
    v_precio_total NUMERIC;
BEGIN
    -- Obtener el precio unitario del producto
    SELECT precio_unitario INTO v_precio_unitario FROM productos WHERE id = p_id;
    
    -- Calcular el precio total
    v_precio_total := v_precio_unitario * p_cantidad;
    
    -- Devolver el resultado
    RETURN v_precio_total;
END;
$$ LANGUAGE plpgsql;

# Forma de ejecutar la función
SELECT calcular_precio_total(1, 5); -- Calcula el precio total del producto con ID 1 y cantidad 5

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









