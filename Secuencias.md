BUSCAR PAR QUE SIRVE currval

# Descripción Rápida de Sequences:
Las Sequences se utilizan para generar valores autoincrementales, como claves primarias en una tabla

### Ejemplos de uso:

### Buscar secuencias 
```sql
\ds
select c.relname FROM pg_class c WHERE c.relkind = 'S'; 
SELECT schemaname, sequencename  FROM pg_sequences WHERE schemaname = 'public';
SELECT * FROM information_schema.sequences;
```

### Saber en que valor esta la secuencia 
```sql
select sequencename,increment_by,last_value from pg_sequences where sequencename = 'ctl_querys2_id_seq';
```

### Ejecutar una secuencia
```sql

--- al ejecutar la secuencia sabes va sumar la siguiente secuencia 
select nextval('fdw_conf.ctl_querys2_id_seq'::regclass);
```

### Crear una secuencia
```sql
CREATE SEQUENCE mi_secuencia START 1 INCREMENT 1;

CREATE SEQUENCE fdw_conf.ctl_querys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
```

### Asignar una secuencia a una columna 
```sql
CREATE TABLE clientes (
   id_cliente integer DEFAULT nextval('secuencia1') PRIMARY KEY,
   nombre VARCHAR(50),
   apellido VARCHAR(50)
);
```

### Restablecer secuencias 
```sql
-- Supongamos que tienes una secuencia llamada "mi_secuencia" , cuando se ejecute la secuencia empezara desde 10 
ALTER SEQUENCE mi_secuencia RESTART WITH 10;

-- Restablecer la secuencia a un valor predeterminado, no se puede reiniciar a 0
-- Este se usa en caso de haber realizado un delete
-- suponiendo que el id que retorna es 10, entonces cuando se ejecute la secuencia insertara el id 11
SELECT setval('mi_secuencia', (SELECT max(id) FROM mi_tabla));

--- Reiniciar la secuencia, desde el valor por defaul por ejemplo si es un primarykey reainicia desde 0
-- Este se usa en caso de haber realizado un truncate
ALTER SEQUENCE mi_secuencia RESTART;

---- Cambiar el incremento de la secuencia:
ALTER SEQUENCE mi_secuencia INCREMENT BY 2;


---- Cambiar el valor máximo y mínimo de la secuencia:
ALTER SEQUENCE mi_secuencia MAXVALUE 1000;
ALTER SEQUENCE mi_secuencia MINVALUE 1;
```

### Reiniciar el ciclo de la secuencia:
Si la secuencia llega al valor máximo (MAXVALUE) o al valor mínimo (MINVALUE), puedes reiniciarla al valor inicial utilizando CYCLE o NO CYCLE. Por ejemplo:
```sql
ALTER SEQUENCE mi_secuencia CYCLE;
```

### eliminar una secuencia 
```sql
DROP SEQUENCE mi_secuencia;
```
