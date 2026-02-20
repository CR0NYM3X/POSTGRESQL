# Que es un Triggers : 
[Documentación oficial de triggers](https://www.postgresql.org/docs/current/sql-createtrigger.html)

Un trigger es como un recordatorio automático que le dices a una base de datos para que haga algo específico cada vez que algo particular sucede. Imagínalo como una especie de "si pasa esto, haz aquello".

# Tipos de Triggers

**`BEFORE Triggers:`** Estos se ejecutan antes de que se realice la operación que los activa. Se utilizan comúnmente para validar o modificar los datos antes de que se inserten, 
actualicen o eliminen en la tabla. Por ejemplo, puedes usar un trigger BEFORE INSERT para verificar que ciertos campos cumplan ciertas condiciones antes de agregar una nueva fila a la tabla.

**`AFTER Triggers:`** Estos se ejecutan después de que se completa la operación que los activa. Se usan para realizar acciones adicionales una vez que se ha realizado la operación principal en la tabla. 
Por ejemplo, puedes usar un trigger AFTER UPDATE para registrar los cambios realizados en una fila en una tabla de registro de cambios.

**Los triggers en PostgreSQL pueden ser a nivel de fila (FOR EACH ROW) o a nivel de instrucción (FOR EACH STATEMENT):**


A nivel de fila **`(FOR EACH ROW)`** : Se ejecutan una vez por cada fila afectada por la operación que activa el trigger. Esto significa que si una instrucción UPDATE afecta a 5 filas, un trigger a nivel de fila se ejecutará 5 veces, una vez para cada fila. <br>


A nivel de instrucción **`(FOR EACH STATEMENT)`** : Se usan mucho para auditar objetos, Se ejecutan una vez por cada instrucción que active el trigger, independientemente del número de filas afectadas. Por ejemplo, si una instrucción DELETE afecta a 100 filas, un trigger a nivel de instrucción se ejecutará una sola vez para esa instrucción DELETE.

**`INSTEAD OF Triggers:`** Estos triggers se utilizan en vistas. En lugar de ejecutar la operación de modificación (INSERT, UPDATE, DELETE) en la vista, el trigger INSTEAD OF puede proporcionar una lógica personalizada para determinar cómo deben manipularse 
los datos en las tablas subyacentes que conforman la vista.

**`DEFERRABLE Triggers:`** Estos triggers están relacionados con las restricciones de tiempo de las transacciones. Permiten que el disparo del trigger se retrase hasta que se complete la transacción, si la restricción de tiempo lo permite.

**`NON-DEFERRABLE Triggers:`** En contraste con los triggers deferrables, estos se ejecutan inmediatamente, sin importar si la transacción aún no se ha completado.

**`CONSTRAINT Triggers:`** Estos triggers se utilizan para asegurar la integridad de los datos. Se ejecutan en respuesta a una acción que viola una restricción definida en la base de datos, por ejemplo, una restricción UNIQUE o FOREIGN KEY

**`TRUNCATE Triggers:`** Estos triggers se activan cuando se ejecuta la instrucción TRUNCATE en una tabla. Un trigger de este tipo te permite realizar acciones personalizadas antes o después de truncar una tabla, como por ejemplo, limpiar datos de otras tablas relacionadas.

**`EVENT TRIGGER:`** A diferencia de los triggers que responden a operaciones en las tablas (INSERT, UPDATE, DELETE), los EVENT TRIGGERS se activan por eventos a nivel del sistema de la base de datos, como la creación de una tabla, un cambio en la configuración del servidor,
entre otros. Permiten reaccionar a eventos de base de datos que no están relacionados directamente con las operaciones CRUD en las tablas.

```
Evento	Momento de Activación	Uso Principal
ddl_command_start:	Antes de la ejecución de un comando DDL	 , Validaciones y auditorías previas
ddl_command_end:	Después de la ejecución de un comando DDL	, Registro y cambios posteriores
sql_drop:	Al ejecutar un comando DROP	,Registro de eliminaciones
table_rewrite:	Al reescribir una tabla por cambios estructurales importantes	, Monitoreo de cambios de gran impacto
```

--- 

### las variables TG_ son variables especiales disponibles dentro de las funciones de trigger.
```
TG_EVENT text # Muestra el tipo de trigger como por ejemplo ddl_command_end 
TG_TAG text # Te muestra el tipo de acion como el CREATE
```

### Registros te permiten acceder a los valores
 Registros te permiten acceder a los valores de las filas antes y después de una operación de modificación, lo que es útil para validar datos, mantener integridad referencial, o realizar auditorías. 

- **`NEW`**: Representa el nuevo registro que se va a insertar o actualizar en la tabla. Se utiliza en triggers `BEFORE INSERT`, `AFTER INSERT`, `BEFORE UPDATE` y `AFTER UPDATE`.
- **`OLD`**: Representa el registro antiguo que está siendo actualizado o eliminado. Se utiliza en triggers `BEFORE UPDATE`, `AFTER UPDATE`, `BEFORE DELETE` y `AFTER DELETE`.



# Ejemplo de uso de trigger tipo eventos :

### Eliminar un trigger
```sql
DROP TRIGGER mi_trigger ON mi_tabla;
```

### consultar trigger
```sql
select * from pg_trigger where tgname = 'trigger_do_nothing' limit 1;

--- puedes ver que tiene un trigger
SELECT event_object_schema, event_object_table, trigger_name, action_statement, action_orientation
FROM information_schema.triggers
WHERE trigger_name = 'trigger_do_nothing';

  select * from pg_catalog.pg_trigger;                       
  select * from pg_catalog.pg_event_trigger;                  
  select * from information_schema.triggers;                  
  select * from information_schema.triggered_update_columns;  
														    

```

### 1.- Creamos la tabla

```
CREATE TABLE auditoria_usuarios  (
    id SERIAL PRIMARY KEY,
    fecha timestamp DEFAULT current_timestamp,
    usuario text,
    ip text,
    operacion text,
    consulta text
);
```

2.- Creamos la funcion que va realizar el insert en la tabla
```
CREATE OR REPLACE FUNCTION trigger_auditoria_usuarios()
RETURNS event_trigger
AS $$

DECLARE

  audit_query TEXT;
  r RECORD;

BEGIN
  
  INSERT INTO auditoria_usuarios (usuario, ip, operacion, consulta) VALUES (current_user, inet_client_addr(), tg_tag, current_query());
--- Se intento colocar este campo pero no guarda la ip : (select client_addr  FROM pg_stat_activity where query = current_query())
--- tampoco funciono SELECT inet_server_addr();  y  SELECT inet_client_addr();
  
END;
$$ LANGUAGE plpgsql;
```

### Creamos el trigger 
```
CREATE EVENT TRIGGER user_ddl_trigger
ON ddl_command_end
WHEN TAG IN ('DROP TABLE')
EXECUTE FUNCTION  trigger_auditoria_usuarios();

--- BIBLIOGRAFÍA
--- https://www.postgresql.org/docs/current/event-trigger-matrix.html
```


### Activar y desactivar 
 ```sql 
ALTER TABLE nombre_tabla DISABLE TRIGGER ALL;
ALTER TABLE nombre_tabla DISABLE TRIGGER nombre_trigger;


ALTER TABLE nombre_tabla ENABLE TRIGGER ALL;
ALTER TABLE nombre_tabla ENABLE TRIGGER nombre_trigger;

 SET session_replication_role = replica;

```
 
 ### 🧠 Valores session_replication_role

| Valor | Descripción |
|-------|-------------|
| `origin` | Valor por defecto. Se ejecutan todos los triggers y reglas normalmente. |
| `replica` | Se **desactivan los triggers y reglas** marcados como `FOR EACH ROW` que no sean `ALWAYS`. Útil para replicación. |
| `local` | Se ejecutan solo los triggers marcados como `ALWAYS`. Los demás se omiten. |



### EJEMPLO DE TRIGGER
Este trigger cuando hacen un insert en la tabla clientes tambien va y lo realiza en la tabla datos_generales
```SQL

/************  Primero, creamos las tablas ************\

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100),
    telefono VARCHAR(20),
    direccion VARCHAR(200)
);

CREATE TABLE datos_generales (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100)
);
 


/************ creamos el trigger y la función asociada ************\ 
 
CREATE OR REPLACE FUNCTION sync_datos_generales()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO datos_generales (id, nombre, email)
        VALUES (NEW.id, NEW.nombre, NEW.email);
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE datos_generales
        SET nombre = NEW.nombre, email = NEW.email
        WHERE id = NEW.id;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        DELETE FROM datos_generales
        WHERE id = OLD.id;
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_sync
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION sync_datos_generales();


/************  Crear reglas para restringir operaciones ************\ 
### Crear reglas para restringir operaciones
 
CREATE RULE restrict_insert AS
ON INSERT TO datos_generales
DO INSTEAD NOTHING;

CREATE RULE restrict_update AS
ON UPDATE TO datos_generales
DO INSTEAD NOTHING;

CREATE RULE restrict_delete AS
ON DELETE TO datos_generales
DO INSTEAD NOTHING;

-- No hay una regla directa para TRUNCATE, pero puedes revocar permisos
REVOKE TRUNCATE ON datos_generales FROM PUBLIC;
 
 
 

/************ Insertar un nuevo cliente ************\ 

 
 
INSERT INTO clientes (nombre, email, telefono, direccion)
VALUES ('Juan Pérez', 'juan.perez@example.com', '555-1234', 'Calle Falsa 123');
 

/************ Actualizar la información de un cliente ************\ 
 
UPDATE clientes
SET nombre = 'Juan A. Pérez', email = 'juan.a.perez@example.com'
WHERE id = 1;
 

/************ Eliminar un cliente ************\ 
 
 
DELETE FROM clientes
WHERE id = 1;
 
 
/************ Verificar los cambios en `datos_generales` ************\ 

SELECT * FROM datos_generales;

```
 

#### Actualizar las secuencias al hacer un delete 
 ```sql 
CREATE TABLE empleados (
    empleado_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);


INSERT INTO empleados (nombre) VALUES ('Juan Pérez'), ('María López');

CREATE OR REPLACE FUNCTION ajustar_secuencia() RETURNS TRIGGER AS $$
BEGIN

  	BEGIN
		PERFORM setval('empleados_empleado_id_seq', (SELECT coalesce(  max(empleado_id) , 1)   FROM empleados));
		EXCEPTION
		 WHEN OTHERS THEN  
			insert into   fdw_conf.log_msg_error(obj_name,type_object,msg) select  'ajustar_secuencia()', 'TRIGGER FUNCTION' , SQLERRM;

	END;
   
    	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ajustar_secuencia
AFTER DELETE ON empleados
FOR EACH STATEMENT
EXECUTE FUNCTION ajustar_secuencia();

DELETE FROM empleados WHERE empleado_id = 1;

INSERT INTO empleados (nombre) VALUES ('Juan Pérez'), ('María López');
select * from empleados;
 ```  


### Limpíar datos antes de insertarlos 
 ```sql

--- CREAR TABLA
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255)
);


--- CREAR FUNCION 
CREATE OR REPLACE FUNCTION clean_spaces()
RETURNS TRIGGER AS $$
BEGIN
    NEW.nombre := TRIM(BOTH FROM NEW.nombre);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


--- CREAR TRIGGER
CREATE TRIGGER clean_spaces_before_insert
BEFORE INSERT ON clientes
FOR EACH ROW
EXECUTE FUNCTION clean_spaces();

--- TEST

insert into clientes(nombre) select '   mariaaaaaaa    ';
SELECT * FROM clientes;


 ```  




# extra:
 ```sql
postgres@postgres# select proname from pg_proc where proname ilike '%trigger%';
+---------------------------------------+
|                proname                |
+---------------------------------------+
| suppress_redundant_updates_trigger    |
| pg_get_triggerdef                     |
| pg_trigger_depth                      |
| trigger_in                            |
| trigger_out                           |
| event_trigger_in                      |
| event_trigger_out                     |
| pg_get_triggerdef                     |
| tsvector_update_trigger               |
| tsvector_update_trigger_column        |
| pg_event_trigger_dropped_objects      |
| pg_event_trigger_table_rewrite_oid    |
| pg_event_trigger_table_rewrite_reason |
| pg_event_trigger_ddl_commands         |
| trigger_function_name                 |
| trigger_auditoria_usuarios            |
+---------------------------------------+
(16 rows)

Time: 1.743 ms
postgres@postgres#


 --- Event Trigger Functions  https://www.postgresql.org/docs/current/functions-event-triggers.html
 ```


### Bibliografías: 
 --- Event Trigger Functions  https://www.postgresql.org/docs/current/functions-event-triggers.html
 ```
https://www.postgresql.org/docs/current/event-triggers.html
https://www.postgresql.org/docs/current/plpgsql-trigger.html
Libro PDF de Postgresql tambien viene sobre los triggers: https://www.postgresql.org/files/documentation/pdf/15/postgresql-15-A4.pdf <br>
Lista de comandos soportados Event trigger:   https://www.postgresql.org/docs/17/event-trigger-matrix.html 

Trigger Before, after  https://www.postgresql.org/docs/current/sql-createtrigger.html <br> 

How to Use Event Triggers in PostgreSQL:  https://www.enterprisedb.com/postgres-tutorials/how-use-event-triggers-postgresql <br>

 --- Event Trigger Functions  https://www.postgresql.org/docs/current/functions-event-triggers.html
 ```
 
