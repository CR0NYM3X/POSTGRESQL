# Objetivo:
Aprender el funcionamiento de los esquemas y asi poder practicarlos para dominar el tema

# Descripcion rápida de los esquemas:
Los esquemas en PostgreSQL (y en otros sistemas de gestión de bases de datos) son una característica fundamental que ayuda a organizar y gestionar las bases de datos de manera más eficiente y segura, estas son sus  ventajas:


- **Organización de datos:**
  - *Los esquemas permiten organizar los objetos de la base de datos en grupos lógicos. *

- **Aislamiento de nombres:**

- **Seguridad y control de acceso:**
	- *Los esquemas también se utilizan para administrar la seguridad y los permisos en la base de datos. Puedes asignar permisos de acceso a un esquema específico y sus objetos a roles de usuario*

- **Mantenimiento y migración:**
	- *son útiles durante las operaciones de mantenimiento y migración de la base de datos. Puedes realizar copias de seguridad y restauraciones de esquemas individuales, lo que facilita la administración de bases de datos complejas.*

- **Escalabilidad:**
- **Organización de proyectos:**

# Ejemplos de uso:

## Consultar todos los esquemas que hay 
```sh 
SELECT nspname AS schema_name FROM pg_namespace ORDER BY schema_name;
```

## Creación de un nuevo esquema: 
```sh
CREATE SCHEMA mi_esquema;
```

## Eliminación de un esquema y sus objetos:
```sh
DROP SCHEMA mi_esquema CASCADE;
```

## Saber que Objetos tiene mi esquema
- Esta query es para Table, View, Index, Sequence, Foreign Table, etc
```sh
SELECT * FROM (SELECT  n.nspname AS schema_name, c.relname AS object_name,
    CASE c.relkind
        WHEN 'r' THEN 'Table'
        WHEN 'v' THEN 'View'
        WHEN 'i' THEN 'Index'
        WHEN 'S' THEN 'Sequence'
        WHEN 'f' THEN 'Foreign Table'
        WHEN 'p' THEN 'Partitioned Table'
        WHEN 'I' THEN 'Partitioned Index'
    END AS object_type
FROM pg_class c
INNER JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public')a --- Remplazamos el public por el esquema que queremos buscar
ORDER BY schema_name, object_type, object_name;
```

- Esta query es solo para Funciones 
```sh
SELECT 
    p.proname AS function_name,
    pg_catalog.pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_catalog.pg_get_function_result(p.oid) AS return_type
FROM 
    pg_catalog.pg_namespace AS n
    JOIN pg_catalog.pg_proc AS p ON p.pronamespace = n.oid
WHERE 
    n.nspname = 'mi_esquema';
```
	
