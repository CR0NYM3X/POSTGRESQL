# Objetivo
Es aprender todo lo que podemos hacer solo con la base de datos 

# Ejemplos 

### Crear una base de datos:
    CREATE DATABASE "mytestdba" WITH TEMPLATE = template0 ENCODING = 'SQL_ASCII' LC_COLLATE = 'C' LC_CTYPE = 'en_US';

### Cambiar el nombre a una base de datos:
    ALTER DATABASE "mytestdba" RENAME TO "myoldtestdba";

## Borrar una base de datos 
**Es importante que cuando se borre una base de datos no este nadie conectado, y para esto puede usar metodos de monitoreo para validar primero que no este nadie conectado**

        Drop databases "mydbatest"
 
### Consutar los nombres de las base de datos:
     \l  
     select datname from pg_database:

### Ver el tamaño de la base de datos:

-  **ver el tamaño y una descripción más completa de la base de datos**
    - \l+ 

- **ver el tamaño de todas las base de datos :**
    - SELECT  datname, pg_size_pretty(pg_database_size( datname)) AS size FROM pg_database;

- **ver especificamente una base de datos :**
    - SELECT  datname, pg_size_pretty(pg_database_size( datname)) AS size FROM pg_database where datname = 'mydbatest' ;
 

### Cambiar la ruta de archivo, donde se guarda la base de datos:
        ALTER DATABASE mydbatest SET TABLESPACE my_tablespace_test;

 ## saber el tipo de encoding 
        select datname, pg_encoding_to_char(encoding)  from pg_database;
