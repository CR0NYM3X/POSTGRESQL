# Descripción rápida de los type:
se utilizan para definir nuevos tipos de datos compuestos personalizados. Estos tipos personalizados pueden contener múltiples campos con diferentes tipos de datos
Estos son los tipos que existen <br>
`('integer','date','text','smallint','character varying','character','numeric','bigint')`

 
**Donde se usan los type**
1. Se usa mucho en funciones para definir los parametros o el tipo de dato que va retornar, que se se usa como un arrego 
2. En las columnas de las tablas.



# Ejemplos de uso:

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




