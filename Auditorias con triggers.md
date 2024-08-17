
1. **Crear la tabla `clientes`**:
   ```sql
   CREATE TABLE clientes (
       id SERIAL PRIMARY KEY,
       nombre VARCHAR(100),
       email VARCHAR(100),
       telefono VARCHAR(20),
       direccion TEXT
   );
   
   select * from clientes ; 
   
  
   ```

2. **Crear la tabla de auditoría `cc_clientes`**:
   ```sql
   CREATE TABLE cc_clientes (
       id SERIAL PRIMARY KEY,
       cliente_id INT,
       operacion VARCHAR(10),
       fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       usuario VARCHAR(50),
       datos JSONB
   );
   
   select * from cc_clientes ; 
   ```

3. **Crear la función de auditoría**:
   ```sql
   CREATE OR REPLACE FUNCTION fn_auditar_clientes() RETURNS TRIGGER AS $$
   BEGIN
       IF (TG_OP = 'INSERT') THEN
           INSERT INTO cc_clientes (cliente_id, operacion, usuario, datos)
           VALUES (NEW.id, 'INSERT', current_user, row_to_json(NEW));
           RETURN NEW;
       ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO cc_clientes (cliente_id, operacion, usuario, datos)
           VALUES (NEW.id, 'UPDATE', current_user, row_to_json(NEW));
           RETURN NEW;
       ELSIF (TG_OP = 'DELETE') THEN
           INSERT INTO cc_clientes (cliente_id, operacion, usuario, datos)
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
   FOR EACH ROW EXECUTE FUNCTION fn_auditar_clientes();

   CREATE TRIGGER trg_auditar_clientes_update
   AFTER UPDATE ON clientes
   FOR EACH ROW EXECUTE FUNCTION fn_auditar_clientes();

   CREATE TRIGGER trg_auditar_clientes_delete
   AFTER DELETE ON clientes
   FOR EACH ROW EXECUTE FUNCTION fn_auditar_clientes();
   
   --- Validar los trigers 
   select tgname from pg_trigger;
   ```

5. **TEST**:
    ```sql
    INSERT INTO clientes (nombre, email, telefono, direccion)  VALUES ('Juan Pérez', 'juan.perez@example.com', '555-1234', 'Calle Falsa 123');
       
    UPDATE clientes SET nombre = 'Juan Pérez García', email = 'juan.perez.garcia@example.com', telefono = '555-5678', direccion = 'Avenida Siempre Viva 742' WHERE id = 1;
    		
    
    DELETE FROM clientes  WHERE id = 4;
    
    select * from clientes ;
    select * from cc_clientes ;
    
    --- consultar valores del json 
    select datos->>'email', datos->>'nombre'  from cc_clientes WHERE ID =1;
    
    
     
    
     
    
    ```
