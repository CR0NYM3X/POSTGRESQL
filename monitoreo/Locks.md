### ¿Qué es un bloqueo?
Un **bloqueo** es una restricción temporal que impide que múltiples transacciones accedan simultáneamente a los mismos datos de una manera que pueda causar conflictos. Por ejemplo, si una transacción está modificando una fila, otra transacción no debería poder leerla o modificarla hasta que la primera termine.
 

### ¿Por qué se generan los bloqueos?
Los bloqueos se generan automáticamente por PostgreSQL cuando se ejecutan operaciones que podrían entrar en conflicto entre sí. Algunas razones comunes incluyen:

- **Lectura o escritura simultánea** sobre los mismos datos.
- **Actualizaciones o eliminaciones** de registros.
- **Transacciones largas** que mantienen recursos ocupados.
- **Índices o constraints** que requieren consistencia durante operaciones complejas.
 
### Tipos de bloqueos en PostgreSQL
PostgreSQL maneja varios niveles de bloqueo, entre ellos:

- **Row-level locks**: bloqueos a nivel de fila (por ejemplo, `SELECT FOR UPDATE`).
- **Table-level locks**: bloqueos a nivel de tabla (por ejemplo, `LOCK TABLE`).
- **Advisory locks**: bloqueos explícitos definidos por el usuario para coordinar procesos.
 
### ¿Qué beneficios tienen los bloqueos?
Aunque pueden parecer un obstáculo, los bloqueos son **esenciales** para:

1. ✅ **Evitar condiciones de carrera**: donde dos transacciones intentan modificar los mismos datos al mismo tiempo.
2. ✅ **Mantener la integridad de los datos**: asegurando que las reglas de negocio y constraints se respeten.
3. ✅ **Garantizar el aislamiento de transacciones**: uno de los principios ACID.
4. ✅ **Evitar lecturas sucias o inconsistentes**: especialmente en niveles de aislamiento más estrictos.
 
### ¿Y los inconvenientes?
- Si no se gestionan bien, pueden causar **bloqueos en cadena** o **deadlocks**.
- Las **transacciones largas** pueden mantener bloqueos por mucho tiempo, afectando el rendimiento.
- Es importante monitorear y optimizar el uso de bloqueos para evitar cuellos de botella.


## Conceptos
```sql

## Locktype: (indica el tipo de objeto que está bloqueado)
relation: Bloqueo sobre una relación (tabla o índice).
extend: Bloqueo de extensión para reservar espacio en la tabla.
page: Bloqueo de página dentro de una relación.
tuple: Bloqueo de tupla (fila) dentro de una página.
transactionid: Bloqueo sobre un ID de transacción.
virtualxid: Bloqueo sobre un ID de transacción virtual.
object: Bloqueo sobre un objeto en el catálogo del sistema.
userlock: Bloqueo definido por el usuario.
advisory: Bloqueo consultivo, utilizado para sincronización de aplicaciones.


## mode  (indica el tipo de bloqueo que se ha solicitado o que se mantiene sobre un objeto)
ExclusiveLock: Bloquea algunas operaciones de lectura, Impide que otros puedan modificar la tabla
AccessExclusiveLock: Bloquea todas las operaciones sobre la tabla, incluyendo las lecturas y las modificaciones.
AccessShareLock: Permite a otros procesos leer el objeto , pero no cambiar la estructura de la tabla.
RowShareLock: Permite a otros procesos leer y bloquear filas, pero no cambiar la estructura de la tabla.
RowExclusiveLock: Permite a otros procesos leer y bloquear filas, pero no cambiar la estructura de la tabla.
ShareUpdateExclusiveLock: Bloquea los vaciados de tabla pero permite lecturas y modificaciones de fila.
ShareLock: Permite que otros procesos lean el objeto pero no modificarlo o bloquearlo en un nivel superior.
ShareRowExclusiveLock: Permite que otros procesos lean el objeto pero no modificarlo o bloquearlo en un nivel superior.



## granted: (indica si el bloqueo ha sido concedido o no)
true: El bloqueo ha sido concedido y el proceso que lo solicitó tiene actualmente el control del recurso.
false: El bloqueo no ha sido concedido todavía. El proceso que lo solicitó está esperando a que el recurso se desbloquee. esto es como un wait que esta en espera
```


# Ejemplo real

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



### 🧪 2. Insertar datos de ejemplo

```sql
INSERT INTO empleados (nombre, salario) VALUES
('Ana', 10000),
('Luis', 12000),
('Carlos', 11000);
```



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


### 🔍 5.  Sesión 3 -  Monitorear procesos que pueden bloquear 

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


--- 

## manipular bloqueos 
```sql

LOCK TABLE nombre_de_la_tabla IN ACCESS SHARE MODE;
LOCK TABLE nombre_de_la_tabla IN ACCESS EXCLUSIVE MODE;
LOCK TABLE nombre_de_la_tabla IN EXCLUSIVE MODE;
LOCK TABLE nombre_de_la_tabla IN ROW EXCLUSIVE MODE;
LOCK TABLE nombre_de_la_tabla IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE nombre_de_la_tabla IN ROW SHARE MODE;
LOCK TABLE nombre_de_la_tabla IN SHARE MODE;
LOCK TABLE nombre_de_la_tabla IN SHARE UPDATE EXCLUSIVE MODE;
 


BEGIN;
LOCK TABLE fdw_conf.scan_rules_query IN  ACCESS EXCLUSIVE MODE;
delete from fdw_conf.scan_rules_query where id =  ; 
COMMIT;
```


## Ejemplo de un log con registros de locks
```
Parametros que registran esto :
log_statement = 'all'
log_lock_waits = on

.- El proceso 70937 esta esperando un objeto bloqueado , y quiere colocarse en AccessShareLock de un objeto compartidos a nivel global en PostgreSQL y ha estado esperando por 000.076 milisegundos.
<05-0-0 00:00:05 MST     70937 6780c57.9577e >LOG:  process 70937 still waiting for AccessShareLock on relation 965 of database 0 after 000.076 ms


.- Estos procesos (67550, 67533, 675358, 67536) son los que actualmente tienen el bloqueo que el proceso 70937 y Estos procesos (70980, 70937) están en la cola de espera
<05-0-0 00:00:05 MST     70937 6780c57.9577e >DETAIL:  Processes holding the lock: 67550, 67533, 675358, 67536. Wait queue: 70980, 70937.

3.- El proceso 70937 que finalmente ha adquirido el bloqueo AccessShareLock a esperado 76687.60 milisegundos (.3 horas))
<05-0-0 0:07:5 MST     70937 6780c57.9577e >LOG:  process 70937 acquired AccessShareLock on relation 965 of database 0 after 76687.60 ms
```

