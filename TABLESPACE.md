# Objetivo:
Es aprender lo basico de Tablespace y poder dominar el tema, para poder trabajar  con esa funcionalidad, [Documentacion oficial de tablespace](https://www.postgresql.org/search/?q=TABLESPACE)


# Descripcion rápida de los esquemas:
Un **`tablespace`** es una ubicación física en el sistema de archivos donde se almacenan los datos de las tablas y los índices de una base de datos. <br>
Los tablespaces permiten a los administradores de bases de datos tener un mayor control sobre la ubicación y distribución de los datos en el almacenamiento subyacente. <br>
Esto puede ser útil en situaciones donde se necesita administrar diferentes tipos de almacenamiento o cuando se desea optimizar el rendimiento o la organización de los datos.  <br>
Esto quiere decir que en un ejemplo real, puedes tener dos base de datos como: DBTIENDA Y DBCLIENTES y asignarle un tablespace a cada base de datos para que cada base de datos se guarde en disco duros diferente.

**[NOTA]** Los esquemas no se pueden integrar con tablespace

# Ejemplos de uso:


### ver los tablespace existentes
    SELECT spcname, pg_tablespace_location(oid) AS location FROM pg_tablespace;

### saber el tamaño de un tablespace
    SELECT pg_tablespace_size('ts_2020');

### Crear un tablespace
    CREATE TABLESPACE my_test_tablespace   LOCATION '/path/to/tablespace/directory';

### Eliminar un TABLESPACE
    DROP TABLESPACE nombre_tablespace;

### Agregar un tablespace a Base de datos 
```sql
    CREATE DATABASE mi_base_de_datos TABLESPACE my_test_tablespace;

    ALTER DATABASE db1 SET TABLESPACE my_test_tablespace;
```

### Agregar un tablespace a un tabla 
    CREATE TABLE public.mi_tabla (id SERIAL PRIMARY KEY,nombre VARCHAR(100)) TABLESPACE my_test_tablespace;
    
    ALTER TABLE my_table SET TABLESPACE my_test_tablespace;
    

### Agregar un tablespace a un index
    CREATE INDEX mi_indice ON public.mi_tabla (nombre) TABLESPACE my_test_tablespace;

    alter index my_index set tablespace my_test_tablespace;


### Renombrar un TABLESPACE
    ALTER TABLESPACE tablespace_name  RENAME TO new_name;

### Cambiar de owner 
    ALTER TABLESPACE tablespace_name OWNER TO new_owner;
