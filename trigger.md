# Que es un Triggers : 
[Documentación oficial de triggers](https://www.postgresql.org/docs/current/sql-createtrigger.html)

Un trigger es como un recordatorio automático que le dices a una base de datos para que haga algo específico cada vez que algo particular sucede. Imagínalo como una especie de "si pasa esto, haz aquello".

# Tipos de Triggers

**`BEFORE Triggers:`** Estos se ejecutan antes de que se realice la operación que los activa. Se utilizan comúnmente para validar o modificar los datos antes de que se inserten, 
actualicen o eliminen en la tabla. Por ejemplo, puedes usar un trigger BEFORE INSERT para verificar que ciertos campos cumplan ciertas condiciones antes de agregar una nueva fila a la tabla.

**`AFTER Triggers:`** Estos se ejecutan después de que se completa la operación que los activa. Se usan para realizar acciones adicionales una vez que se ha realizado la operación principal en la tabla. 
Por ejemplo, puedes usar un trigger AFTER UPDATE para registrar los cambios realizados en una fila en una tabla de registro de cambios.

**Los triggers en PostgreSQL pueden ser a nivel de fila (FOR EACH ROW) o a nivel de instrucción (FOR EACH STATEMENT):**


A nivel de fila (FOR EACH ROW): Se ejecutan una vez por cada fila afectada por la operación que activa el trigger. Esto significa que si una instrucción UPDATE afecta a 5 filas, un trigger a nivel de fila se ejecutará 5 veces, una vez para cada fila. <br>
A nivel de instrucción (FOR EACH STATEMENT): Se ejecutan una vez por cada instrucción que active el trigger, independientemente del número de filas afectadas. Por ejemplo, si una instrucción DELETE afecta a 100 filas, un trigger a nivel de instrucción se
ejecutará una sola vez para esa instrucción DELETE.

**`INSTEAD OF Triggers:`** Estos triggers se utilizan en vistas. En lugar de ejecutar la operación de modificación (INSERT, UPDATE, DELETE) en la vista, el trigger INSTEAD OF puede proporcionar una lógica personalizada para determinar cómo deben manipularse 
los datos en las tablas subyacentes que conforman la vista.

**`DEFERRABLE Triggers:`** Estos triggers están relacionados con las restricciones de tiempo de las transacciones. Permiten que el disparo del trigger se retrase hasta que se complete la transacción, si la restricción de tiempo lo permite.

**`NON-DEFERRABLE Triggers:`** En contraste con los triggers deferrables, estos se ejecutan inmediatamente, sin importar si la transacción aún no se ha completado.

**`CONSTRAINT Triggers:`** Estos triggers se utilizan para asegurar la integridad de los datos. Se ejecutan en respuesta a una acción que viola una restricción definida en la base de datos, por ejemplo, una restricción UNIQUE o FOREIGN KEY

**`TRUNCATE Triggers:`** Estos triggers se activan cuando se ejecuta la instrucción TRUNCATE en una tabla. Un trigger de este tipo te permite realizar acciones personalizadas antes o después de truncar una tabla, como por ejemplo, limpiar datos de otras tablas relacionadas.

**`EVENT TRIGGER:`** A diferencia de los triggers que responden a operaciones en las tablas (INSERT, UPDATE, DELETE), los EVENT TRIGGERS se activan por eventos a nivel del sistema de la base de datos, como la creación de una tabla, un cambio en la configuración del servidor,
entre otros. Permiten reaccionar a eventos de base de datos que no están relacionados directamente con las operaciones CRUD en las tablas.

# Ejemplo de uso de trigger tipo eventos :

### consultar trigger
```sql
select * from pg_trigger where tgname = 'trigger_do_nothing' limit 1;

--- puedes ver que tiene un trigger
SELECT event_object_schema, event_object_table, trigger_name, action_statement, action_orientation
FROM information_schema.triggers
WHERE trigger_name = 'trigger_do_nothing';
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
```
# extra:
auditorias con pgaudit: https://www.postgresql.org/message-id/attachment/41749/pgaudit-v2-03.patch

### Bibliografías: 
https://www.postgresql.org/docs/current/plpgsql-trigger.html <br>
Libro PDF de Postgresql tambien viene sobre los triggers: https://www.postgresql.org/files/documentation/pdf/15/postgresql-15-A4.pdf <br>
Lista de comandos soportados Event trigger:   https://www.postgresql.org/docs/current/event-trigger-matrix.html <br>

How to Use Event Triggers in PostgreSQL:  https://www.enterprisedb.com/postgres-tutorials/how-use-event-triggers-postgresql <br>
