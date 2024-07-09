# Objetivo
Es aprender todo lo que podemos hacer solo con la base de datos 

# Ejemplos 

### Ver a que base de datos estoy conectado
          select  current_database();

### Consutar los nombres de las base de datos:
     \l  
     select datname from pg_database;

### Crear una base de datos:
```sql
    CREATE DATABASE "mytestdba" WITH TEMPLATE = template0 ENCODING = 'SQL_ASCII' LC_COLLATE = 'C' LC_CTYPE = 'en_US';
    
    **Parametros adicionales que le puedes agregar en el with**
       OWNER = postgesql
       ENCODING = 'UTF8' 
       LC_CTYPE = 'en_US.UTF-8'; especifica las reglas de clasificación de caracteres (mayúsculas/minúsculas) y afecta a las operaciones de búsqueda y comparación.
       LC_COLLATE = 'en_US.UTF-8'  determina cómo se ordenan y comparan las cadenas de caracteres en consultas y operaciones de ordenamiento.
       TABLESPACE = pg_default
       CONNECTION LIMIT = -1;  --- El -1 quiere decir que son conexiones elimitadas 

/******************** TIPOS DE ENCODING ********************\
1. **UTF-8**:
   - **Recomendado**: Es ampliamente utilizado y compatible con una amplia gama de caracteres.
   - Almacena caracteres Unicode y es eficiente en términos de espacio.
   - Adecuado para aplicaciones multilingües y sitios web internacionales.

2. **LATIN1 (ISO 8859-1)**:
   - Utilizado principalmente en Europa occidental.
   - Compatible con caracteres en inglés, alemán, francés, español, etc.
   - No admite caracteres Unicode.

3. **LATIN2 (ISO 8859-2)**:
   - Utilizado en Europa central y del este.
   - Incluye caracteres adicionales como letras acentuadas y diacríticas.
   - No admite caracteres Unicode.

4. **EUC_JP**:
   - Codificación extendida UNIX para japonés.
   - Adecuada para almacenar texto en japonés.

5. **KOI8R**:
   - Utilizado para el ruso (cirílico).
   - No admite caracteres Unicode.
```

### Cambiar el nombre a una base de datos:
    ALTER DATABASE "mytestdba" RENAME TO "myoldtestdba";

## Borrar una base de datos 
**Es importante que cuando se borre una base de datos no este nadie conectado, y para esto puede usar metodos de monitoreo para validar primero que no este nadie conectado**

        Drop databases "mydbatest"

### Ver el limite de conexiones que se permiten por Base de datos:
        select datname,datconnlimit from pg_database; -- si es -1 es ilimitado, si tiene algún número se especificó un límite  

### Ver el tamaño de la base de datos:

-  **ver el tamaño y una descripción más completa de la base de datos**
    - \l+ 

- **ver el tamaño de todas las base de datos :**
    - select * from (SELECT  datname, pg_size_pretty(pg_database_size( datname)) AS size, (pg_stat_file('base/'||oid ||'/PG_VERSION')).modification as Fecha_Creacion FROM pg_database)a order by size;

- **ver especificamente una base de datos :**
    - SELECT  datname, pg_size_pretty(pg_database_size( datname)) AS size FROM pg_database where datname = 'mydbatest' ;
 

### Cambiar la ruta de archivo, donde se guarda la base de datos:
        ALTER DATABASE mydbatest SET TABLESPACE my_tablespace_test;

 ## saber el tipo de encoding 
        select datname, pg_encoding_to_char(encoding)  from pg_database;
        SHOW server_encoding;
        show client_encoding;
        SHOW lc_messages;
