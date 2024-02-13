# Descripción Rápida de Sequences:
Las Sequences se utilizan para generar valores autoincrementales, como claves primarias en una tabla

### Ejemplos de uso:

### Buscar secuencias 
select c.relname FROM pg_class c WHERE c.relkind = 'S'; <br>
SELECT schemaname, sequencename  FROM pg_sequences WHERE schemaname = 'public';<br>
  SELECT * FROM information_schema.sequences;<br>
  \ds

  
### Ejecutar una secuencia
SELECT nextval('mi_secuencia');

### Crear una secuencia
CREATE SEQUENCE mi_secuencia START 1 INCREMENT 1;

### Usar una secuencia 
-- Crear la tabla clientes y asignar la secuencia 1 a la columna id_cliente
CREATE TABLE clientes (
   id_cliente integer DEFAULT nextval('secuencia1') PRIMARY KEY,
   nombre VARCHAR(50),
   apellido VARCHAR(50)
);

### Restablecer secuencias 
Supongamos que tienes una secuencia llamada "mi_secuencia" y deseas reiniciarla al valor 1:
ALTER SEQUENCE mi_secuencia RESTART WITH 1;

-- Restablecer la secuencia "mi_secuencia" a su valor predeterminado
SELECT setval('mi_secuencia', (SELECT max(id) FROM mi_tabla));

--- Cambiar el valor actual de la secuencia:
ALTER SEQUENCE mi_secuencia RESTART;

---- Cambiar el incremento de la secuencia:
ALTER SEQUENCE mi_secuencia INCREMENT BY 2;


---- Cambiar el valor máximo y mínimo de la secuencia:
ALTER SEQUENCE mi_secuencia MAXVALUE 1000;
ALTER SEQUENCE mi_secuencia MINVALUE 1;

--- Reiniciar el ciclo de la secuencia: | Si la secuencia llega al valor máximo (MAXVALUE) o al valor mínimo (MINVALUE), puedes reiniciarla al valor inicial utilizando CYCLE o NO CYCLE. Por ejemplo:
ALTER SEQUENCE mi_secuencia CYCLE;


### eliminar una secuencia 

DROP SEQUENCE mi_secuencia;
