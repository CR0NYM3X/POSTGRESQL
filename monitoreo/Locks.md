1. **Creación de la tabla `empleados`**
2. **Inserción de datos de ejemplo**
3. **Simulación del bloqueo con dos sesiones**
4. **Consultas para monitorear el bloqueo**


### 🧱 1. Crear la tabla `empleados`

```sql
CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    salario NUMERIC(10, 2)
);
```

---

### 🧪 2. Insertar datos de ejemplo

```sql
INSERT INTO empleados (nombre, salario) VALUES
('Ana', 10000),
('Luis', 12000),
('Carlos', 11000);
```

---

### 🔄 3. Simular el bloqueo

#### 🧵 Sesión 1:

```sql
BEGIN;
select pg_backend_pid();
UPDATE empleados SET salario = salario + 1000 WHERE id = 1;
-- No hacer COMMIT aún
```

#### 🧵 Sesión 2 (en otra conexión):

```sql
BEGIN;
select pg_backend_pid();
UPDATE empleados SET salario = salario + 500 WHERE id = 1;
-- Esta sesión quedará bloqueada esperando a que la Sesión 1 libere el recurso
```

---

### 🔍 4.  Sesión 3 Monitorear el bloqueo - Validar procesos bloqueados

```sql
SELECT
  blocked_locks.pid AS blocked_pid,
  blocked_locks.mode AS blocked_mode,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_locks.mode AS blocking_mode,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_query,
  blocking_activity.query AS blocking_query,
  now() - blocked_activity.query_start AS blocked_duration,
  now() - blocking_activity.query_start AS blocking_duration
FROM pg_catalog.pg_locks blocked_locks
LEFT JOIN pg_catalog.pg_stat_activity blocked_activity
  ON blocked_activity.pid = blocked_locks.pid
LEFT JOIN pg_catalog.pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
  AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
  AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
  AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
  AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
  AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
  AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
  AND blocking_locks.pid != blocked_locks.pid
LEFT JOIN pg_catalog.pg_stat_activity blocking_activity
  ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted ;
``` 


### 🔍 5.  Sesión 4 -  Monitorear procesos que pueden bloquear 

```sql
SELECT  
  DISTINCT
  a.pid              
 ,a.datname                
 ,a.usename          
 ,a.client_addr         
 ,a.application_name 
 ,now() - a.query_start AS time_run 
 ,a.state_change     
 ,a.wait_event_type  
 ,a.wait_event       
 ,a.state                         
 ,a.query            
 ,a.backend_type
 ,b.mode AS lock_mode 
FROM pg_stat_activity AS a 
LEFT JOIN pg_catalog.pg_locks AS b ON a.pid = b.pid
WHERE 
      a.pid <> pg_backend_pid()
	  AND state <> 'idle'
	  --AND b.mode ilike '%Exclusive%'
	  AND b.mode in('AccessExclusiveLock','RowExclusiveLock'); 

```
