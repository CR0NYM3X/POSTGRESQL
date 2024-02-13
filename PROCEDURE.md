
# Descripción rápida de PROCEDURE:
[documentación Oficial](https://www.postgresql.org/docs/current/sql-createprocedure.html) <br>
Los procedimientos almacenados son muy útiles para realizar tareas complejas, actualizar datos, o realizar cualquier operación que requiera una secuencia de comandos SQL.<br>
Los procedimientos almacenados no devuelven valores directamente; en cambio, pueden realizar operaciones de actualización, inserción, eliminación, etc.

# Ejemplos de uso:

### Ver el contenido de la funcion junto con el create

```
SELECT pg_get_functiondef('fun_actualiza_datos'::regproc);
SELECT pg_get_functiondef(f.oid) FROM pg_catalog.pg_proc f    WHERE f.proname = 'fun_actualiza_datos';
```

# ver la existencia de una procedimiento
```
SELECT routine_name
FROM information_schema.routines
WHERE routine_name = 'nombre_del_procedimiento';
```

### ver todos los parámetros de una funcion 
```
#Ver los parámetros de una función
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
and r.routine_name = 'Proc_actualiza_datos'  
ORDER BY r.routine_name, p.ordinal_position;

#Vemos todas las funciones y sus parámetros 
SELECT   proname , proargnames, pg_catalog.oidvectortypes(proargtypes)  FROM pg_proc where proname in(SELECT routine_name FROM information_schema.routines WHERE routine_type = 'FUNCTION' AND specific_schema = 'public') 

```


### Crear un procedimiento Almacenado:

**`Crear`**
```
CREATE OR REPLACE PROCEDURE mi_procedure()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Código del procedimiento aquí
    -- Este ejemplo no hace nada
    NULL;
END;
$$;
```

**`Consultar`**
```
CALL insert_data(1, 2);
```


### Alters
```
ALTER PROCEDURE insert_data(integer, integer) RENAME TO insert_record;
```

### Eliminar un procedimiento
```
DROP PROCEDURE do_db_maintenance;
```
