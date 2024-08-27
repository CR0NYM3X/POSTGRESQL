1. **Crear el esquema `cdc`**:
   ```sql
   create schema cdc ;
   ```

1. **Crear la tabla `clientes`**:
   ```sql
   CREATE TABLE public.clientes (
      id SERIAL PRIMARY KEY,
      nombre VARCHAR(100),
      email VARCHAR(100),
      telefono VARCHAR(20),
      direccion TEXT
   );
   
   select * from public.clientes ; 
   
  
   ```

2. **Crear la tabla de auditoría `cc_clientes`**:
   ```sql

   CREATE TABLE cdc.clientes (
   	id SERIAL PRIMARY KEY,
   	operacion varchar(100),
   	usuario varchar(100),
   	ip_cliente varchar(100),
   	query text,
   	valor_anterior JSONB,
   	valor_nuevo JSONB,
   	fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   
   select * from cdc.clientes ; 
   ```

3. **Crear la función de auditoría**:
   ```sql

   ----------- FUNCION PARA MONITOREAR LAS ACCIONES:  INSERT, UPDATE, DELETE  
   
   CREATE OR REPLACE FUNCTION cdc.registrar_cambios_clientes()
   RETURNS TRIGGER AS $$
   DECLARE
       cambios_anterior JSONB := '{}';
       cambios_nuevo JSONB := '{}';
       columna TEXT;
       valor_anterior TEXT;
       valor_nuevo TEXT;
   BEGIN
       -- Para operaciones de DELETE
       IF TG_OP = 'DELETE' THEN
           cambios_anterior := to_jsonb(OLD);
           INSERT INTO cdc.clientes (operacion, valor_anterior, valor_nuevo, usuario, ip_cliente,query)
           VALUES ('DELETE', cambios_anterior, NULL, current_user, inet_client_addr(),current_query());
           RETURN OLD;
       END IF;
   
       -- Para operaciones de INSERT
       IF TG_OP = 'INSERT' THEN
           cambios_nuevo := to_jsonb(NEW);
           INSERT INTO cdc.clientes (operacion, valor_anterior, valor_nuevo, usuario, ip_cliente,query)
           VALUES ('INSERT', NULL, cambios_nuevo, current_user, inet_client_addr(),current_query());
           RETURN NEW;
       END IF;
   
       -- Para operaciones de UPDATE
       IF TG_OP = 'UPDATE' THEN
           FOR columna IN
               SELECT column_name
               FROM information_schema.columns
               WHERE table_name = 'clientes' and table_schema='public'
           LOOP
               EXECUTE 'SELECT ($1).' || columna INTO valor_anterior USING OLD;
               EXECUTE 'SELECT ($1).' || columna INTO valor_nuevo USING NEW;
               IF valor_anterior IS DISTINCT FROM valor_nuevo THEN
                   cambios_anterior := jsonb_set(cambios_anterior, ARRAY[columna], to_jsonb(valor_anterior));
                   cambios_nuevo := jsonb_set(cambios_nuevo, ARRAY[columna], to_jsonb(valor_nuevo));
               END IF;
           END LOOP;
   		
   		-- row_to_json(NEW)
   		
           INSERT INTO cdc.clientes (operacion, valor_anterior, valor_nuevo, usuario, ip_cliente,query)
           VALUES ('UPDATE', cambios_anterior, cambios_nuevo, current_user, inet_client_addr(),current_query());
           RETURN NEW;
       END IF;
   
       RETURN NULL;
   END;
   $$ LANGUAGE plpgsql;

   -----------FUNCION PARA MONITOREAR LAS ACCIONES: TRUNCATE
   
   CREATE OR REPLACE FUNCTION trigger_function_name()
   RETURNS TRIGGER AS
   $$
   BEGIN
       INSERT INTO cdc.clientes(operacion, valor_anterior, valor_nuevo, usuario, ip_cliente, fecha,query)
       VALUES ('TRUNCATE', NULL, NULL, current_user, inet_client_addr(), CURRENT_TIMESTAMP,current_query());    
       RETURN NULL;
   END;
   $$
   LANGUAGE plpgsql;

    ----------- FUNCION PARA MONITOREAR LAS ACCIONES: DROP TABLE Y ALTER TABLE 
       
   CREATE OR REPLACE FUNCTION cdc.registrar_ddl()
   RETURNS event_trigger   AS $$
   DECLARE
       -- obj record;
   	var_object_identity varchar;
   BEGIN
   
   
   	SELECT object_identity INTO var_object_identity FROM pg_catalog.pg_event_trigger_ddl_commands();
   	
   	 
   	
   	IF --tg_tag in('DROP TABLE','ALTER TABLE') AND 
   		var_object_identity = 'public.clientes' then
   		
   		INSERT INTO cdc.clientes(operacion, valor_anterior, valor_nuevo, usuario, ip_cliente, fecha,query)
   		VALUES (TG_TAG, NULL, NULL, current_user, inet_client_addr(), CURRENT_TIMESTAMP,current_query());
   	
   	END IF;
   
   	
   END;
   $$ LANGUAGE plpgsql;

   ```

4. **Crear los triggers**:
   ```sql
   
   CREATE TRIGGER trigger_cambios_clientes
   AFTER INSERT OR UPDATE OR DELETE ON clientes
   FOR EACH ROW
   EXECUTE FUNCTION cdc.registrar_cambios_clientes();


   CREATE TRIGGER trigger_name
   BEFORE TRUNCATE ON clientes
   FOR EACH STATEMENT
   EXECUTE FUNCTION trigger_function_name();


   CREATE  EVENT TRIGGER trigger_ddl_clientes
   ON ddl_command_end
   WHEN TAG IN ('DROP TABLE', 'ALTER TABLE')
   EXECUTE FUNCTION cdc.registrar_ddl();
   
   --- Validar los trigers 
   select * from pg_catalog.pg_trigger;                       
   select * from pg_catalog.pg_event_trigger;  
   ```

5. **TEST**:
    ```sql
    INSERT INTO public.clientes (nombre, email, telefono, direccion)  VALUES ('Juan Pérez', 'juan.perez@example.com', '555-1234', 'Calle Falsa 123');
    UPDATE public.clientes SET nombre = 'Mario García', email = 'Mario.garcia@example.com', telefono = '555-5678', direccion = 'Avenida Siempre Viva 742' WHERE id = 1;
    DELETE FROM public.clientes  WHERE id = 1;
    truncate public.clientes RESTART IDENTITY ;
    alter table clientes add column jose int;
    alter table clientes drop column jose  ;

    select * from public.clientes ;
    
   --- en caso de que quieras eliminar los registros que se auditarion
    truncate cdc.clientes RESTART IDENTITY ;
    
    --- consultar valores del json 
   postgres@postgres# select valor_nuevo->>'email', valor_nuevo->>'nombre'  from cdc.clientes ;
   +--------------------------+--------------+
   |         ?column?         |   ?column?   |
   +--------------------------+--------------+
   | juan.perez@example.com   | Juan Pérez   |
   | Mario.garcia@example.com | Mario García |
   | NULL                     | NULL         |
   | NULL                     | NULL         |
   | NULL                     | NULL         |
   | NULL                     | NULL         |
   +--------------------------+--------------+


    
   postgres@postgres#  select * from cdc.clientes ;
   +-[ RECORD 1 ]---+--------------------------------------------------------------------------------------------------------------------------------
   
   | id             | 1
                                        |
   | operacion      | INSERT
                                        |
   | usuario        | postgres
                                        |
   | ip_cliente     | NULL
                                        |
   | query          | INSERT INTO public.clientes (nombre, email, telefono, direccion)  VALUES ('Juan Pérez', 'juan.perez@example.com', '555-1234', '
   Calle Falsa 123');                   |
   | valor_anterior | NULL
                                        |
   | valor_nuevo    | {"id": 1, "email": "juan.perez@example.com", "nombre": "Juan Pérez", "telefono": "555-1234", "direccion": "Calle Falsa 123"}
                                        |
   | fecha          | 2024-08-27 16:02:08.320008
                                        |
   +-[ RECORD 2 ]---+--------------------------------------------------------------------------------------------------------------------------------
   
   | id             | 2
                                        |
   | operacion      | UPDATE
                                        |
   | usuario        | postgres
                                        |
   | ip_cliente     | NULL
                                        |
   | query          | UPDATE public.clientes SET nombre = 'Mario García', email = 'Mario.garcia@example.com', telefono = '555-5678', direccion = 'Ave
   nida Siempre Viva 742' WHERE id = 1; |
   | valor_anterior | {"email": "juan.perez@example.com", "nombre": "Juan Pérez", "telefono": "555-1234", "direccion": "Calle Falsa 123"}
                                        |
   | valor_nuevo    | {"email": "Mario.garcia@example.com", "nombre": "Mario García", "telefono": "555-5678", "direccion": "Avenida Siempre Viva 742"
   }                                    |
   | fecha          | 2024-08-27 16:02:08.322721
                                        |
   +-[ RECORD 3 ]---+--------------------------------------------------------------------------------------------------------------------------------
   
   | id             | 3
                                        |
   | operacion      | DELETE
                                        |
   | usuario        | postgres
                                        |
   | ip_cliente     | NULL
                                        |
   | query          | DELETE FROM public.clientes  WHERE id = 1;
                                        |
   | valor_anterior | {"id": 1, "email": "Mario.garcia@example.com", "nombre": "Mario García", "telefono": "555-5678", "direccion": "Avenida Siempre
   Viva 742"}                           |
   | valor_nuevo    | NULL
                                        |
   | fecha          | 2024-08-27 16:02:08.327443
                                        |
   +-[ RECORD 4 ]---+--------------------------------------------------------------------------------------------------------------------------------
   
   | id             | 4
                                        |
   | operacion      | TRUNCATE
                                        |
   | usuario        | postgres
                                        |
   | ip_cliente     | NULL
                                        |
   | query          | truncate public.clientes RESTART IDENTITY ;
                                        |
   | valor_anterior | NULL
                                        |
   | valor_nuevo    | NULL
                                        |
   | fecha          | 2024-08-27 16:02:08.328626
                                        |
   +-[ RECORD 5 ]---+--------------------------------------------------------------------------------------------------------------------------------
   
   | id             | 6
                                        |
   | operacion      | ALTER TABLE
                                        |
   | usuario        | postgres
                                        |
   | ip_cliente     | NULL
                                        |
   | query          | alter table clientes add column jose int;
                                        |
   | valor_anterior | NULL
                                        |
   | valor_nuevo    | NULL
                                        |
   | fecha          | 2024-08-27 16:03:09.226196
                                        |
   +-[ RECORD 6 ]---+--------------------------------------------------------------------------------------------------------------------------------
   
   | id             | 7
                                        |
   | operacion      | ALTER TABLE
                                        |
   | usuario        | postgres
                                        |
   | ip_cliente     | NULL
                                        |
   | query          | alter table clientes drop column jose  ;
                                        |
   | valor_anterior | NULL
                                        |
   | valor_nuevo    | NULL
                                        |
   | fecha          | 2024-08-27 16:03:22.244068
                                        |
   +----------------+--------------------------------------------------------------------------------------------------------------------------------

    ```



### Información    
```
NEW: Representa el nuevo registro que se va a insertar o actualizar en la tabla.
Se utiliza en triggers BEFORE INSERT, AFTER INSERT, BEFORE UPDATE y AFTER UPDATE.

OLD: Representa el registro antiguo que está siendo actualizado o eliminado.
Se utiliza en triggers BEFORE UPDATE, AFTER UPDATE, BEFORE DELETE y AFTER DELETE.
```




### Bibliografía
```sql
auditorias con pgaudit: https://www.postgresql.org/message-id/attachment/41749/pgaudit-v2-03.patch

--- https://www.postgresql.org/docs/current/functions-event-triggers.html
--- Event Triggers --> https://doc.rockdata.net/features/event-triggers/ 

https://estuary.dev/postgresql-triggers/#:~:text=PostgreSQL%20can%20fire%20triggers%20for,set%20as%20the%20trigger%20action..
```
