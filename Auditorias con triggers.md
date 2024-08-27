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
       cliente_id INT,
       operacion VARCHAR(10),
       fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       usuario VARCHAR(50),
       datos JSONB
   );
   
   select * from cdc.clientes ; 
   ```

3. **Crear la función de auditoría**:
   ```sql
   CREATE OR REPLACE FUNCTION cdc.fn_auditar_clientes() RETURNS TRIGGER AS $$
   BEGIN
       IF (TG_OP = 'INSERT') THEN
           INSERT INTO cdc.clientes (cliente_id, operacion, usuario, datos)
           VALUES (NEW.id, 'INSERT', current_user, row_to_json(NEW));
           RETURN NEW;
       ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO cdc.clientes (cliente_id, operacion, usuario, datos)
           VALUES (NEW.id, 'UPDATE', current_user, row_to_json(NEW));
           RETURN NEW;
       ELSIF (TG_OP = 'DELETE') THEN
           INSERT INTO cdc.clientes (cliente_id, operacion, usuario, datos)
           VALUES (OLD.id, 'DELETE', current_user, row_to_json(OLD));
           RETURN OLD;
       END IF;
       RETURN NULL;
   END;
   $$ LANGUAGE plpgsql;
   ```

4. **Crear los triggers**:
   ```sql
   CREATE TRIGGER trg_auditar_clientes_insert
   AFTER INSERT ON clientes
   FOR EACH ROW EXECUTE FUNCTION cdc.fn_auditar_clientes();

   CREATE TRIGGER trg_auditar_clientes_update
   AFTER UPDATE ON clientes
   FOR EACH ROW EXECUTE FUNCTION cdc.fn_auditar_clientes();

   CREATE TRIGGER trg_auditar_clientes_delete
   AFTER DELETE ON clientes
   FOR EACH ROW EXECUTE FUNCTION cdc.fn_auditar_clientes();
   
   --- Validar los trigers 
   select tgname from pg_trigger;
   ```

5. **TEST**:
    ```sql
    INSERT INTO public.clientes (nombre, email, telefono, direccion)  VALUES ('Juan Pérez', 'juan.perez@example.com', '555-1234', 'Calle Falsa 123');
       
    UPDATE public.clientes SET nombre = 'Mario García', email = 'Mario.garcia@example.com', telefono = '555-5678', direccion = 'Avenida Siempre Viva 742' WHERE id = 1;
    		
    
    DELETE FROM public.clientes  WHERE id = 1;

    truncate public.clientes RESTART IDENTITY ;
    truncate cdc.clientes RESTART IDENTITY ;
 

    select * from public.clientes ;
    select * from cdc.clientes ; 
    
    --- consultar valores del json 
    select datos->>'email', datos->>'nombre'  from cc_clientes WHERE ID =1;
    
    
     
    
     
    
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

https://estuary.dev/postgresql-triggers/#:~:text=PostgreSQL%20can%20fire%20triggers%20for,set%20as%20the%20trigger%20action..
```
