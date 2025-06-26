# Objetivo:
Aprenderemos a monitorear un postgresql para asi lograr optimizar y tener una alta disponibilidad

# Descripcion rápida:
Monitorear una base de datos es una práctica importante en la administración de sistemas de bases de datos por varias razones:

**`Rendimiento:`** El monitoreo de la base de datos permite identificar cuellos de botella, consultas lentas o problemas de rendimiento. Esto es crucial para garantizar que la base de datos funcione de manera eficiente y responda rápidamente a las solicitudes de los usuarios y aplicaciones.

**`Disponibilidad:`**  La monitorización ayuda a garantizar la disponibilidad continua de la base de datos. Permite detectar problemas de hardware, fallos del sistema operativo o problemas de red que pueden afectar la accesibilidad de la base de datos.

**`Seguridad:`**  El monitoreo puede ayudar a identificar intentos de acceso no autorizado o actividades sospechosas en la base de datos, lo que contribuye a la seguridad de los datos.

**`Detección temprana de problemas:`**  La monitorización proactiva permite detectar y resolver problemas antes de que afecten negativamente a los usuarios finales. Esto puede incluir alertas sobre espacio en disco insuficiente, problemas de índices o errores en el registro de transacciones.

**`Optimización de consultas:`**  Al analizar las consultas que se ejecutan en la base de datos, puedes identificar oportunidades de optimización para mejorar la eficiencia y reducir los tiempos de respuesta.

**`Aprendizaje y mejora continua:`**  El monitoreo continuo proporciona información valiosa sobre el comportamiento de la base de datos y las interacciones de los usuarios. Esto puede utilizarse para aprender y mejorar el diseño y la eficiencia de la base de datos con el tiempo.

---
**Pasos a seguir en caso de solicitar una revision del servidor y Base de datos:**

para Verificar el estatus del servidor y DBA realizamos los siguientes pasos:  <br>
-  .- Validar el espacio de los discos duros, tambien monitorear el comportamiento de escritura y lectura <br>
-  .- Monitorear el procesador y la memoria Ram, verificando el comportamiento de escritura y lectura  <br>
- 3 .- Validar maximo de conexiones y cuantas conexiones hay en ese momento y eliminar consultas bloqueadas <br>
-  .- Verificar el tiempo que tiene encendido el servidor <br>
- 5 .- realizar Reindexacion , vacum full  en caso de requerirse <br>
- 6 .- Ver el tamaño de las base de datos, tablas y tratar de optimizar como la db y tb <br>
- 7 .- Validar los tiempo de ejecucion de una consulta y compararlos con dias anteriores  <br>

```sql
Detectar tablas que no tienen index
Index que no se usan
Detectar index duplicados
Detectar index que faltan/ columna sin index
Detectar index basura
Detectar index compuestos
         *** Estos solo son útiles solo si la consulta utiliza las columnas que agregaste al index compuestos que son más de una columna 
Índices GIN y GiST
Índices Bloat (Fragmentados)
```



# Querys más utilizadas 
```sql


 
-- ********* Query ver conexiones con alto consumo de CPU  *********

# Obtener PIDs de procesos postgres y su % de memoria
PG_PIDS=$(ps -C postgres -o pid=,%mem=,size=,%cpu= --sort=-%mem | awk '{print $","$","$3","$}')

# Generar lista de PIDs para la query SQL (ej: "3,.3;5678,5.6")
PG_PIDS_LIST=$(echo "$PG_PIDS" | tr '\n' ';' | sed 's/;$//')

# Ejecutar query en PostgreSQL con el % de memoria
psql -p $(grep "port =" /sysx/data/postgresql.conf | awk '{print $3}') -U  postgres -c "
WITH process_mem AS (
  SELECT split_part(data, ',', )::int AS pid,
         split_part(data, ',', )::float AS mem_percent,
		 split_part(data, ',', 3)::float AS mem_kb,
		 split_part(data, ',', )::float AS cpu_percent
  FROM (SELECT unnest(string_to_array('$PG_PIDS_LIST', ';')) AS data) AS t
)
SELECT 
  -- pg_terminate_backend(pid), -- Cerrar conexiones tener cuidado de tumbar procesos de prostgresql importantes
  a.pid,
  --a.backend_type,
  a.state,
  a.usename,
  -- a.datname,
  a.client_addr,
  --a.backend_start,
  --a.query_start,
  NOW() - a.query_start AS duracion_exec,
  -- a.application_name,
  pm.mem_percent || '%' AS mem,
  mem_kb || ' KB' AS mem_kb,
  cpu_percent || '%' cpu
  ----,query
FROM pg_stat_activity a
LEFT JOIN process_mem pm ON a.pid = pm.pid
WHERE a.pid <> pg_backend_pid()  -- Excluir la propia conexión
	 AND backend_type = 'client backend' -- Excluir procesos inernos de postgres
	 AND pm.mem_percent IS NOT NULL 
	 -- AND state ~* 'idle' -- filtrar solo conexiones inactivas o zombies 
ORDER BY pm.mem_percent DESC, pm.cpu_percent DESC;
-- ORDER BY pm.cpu_percent DESC;
-- ORDER BY  (NOW() - a.query_start) DESC
"



-- ********* Query ver conexiones activas con altos tiempos de 5 min. *********

select  
	pid,
	backend_type,
	datname,
	usename,
	client_addr,
	state,
	--query_start,
	application_name,
	(now()- query_start)  as time_run, 
	state
	--,query
FROM pg_stat_activity
WHERE backend_type = 'client backend' 
	  AND state ~* 'active'
	  AND pid != pg_backend_pid()  
	  AND (now() - query_start) > interval '5 minutes' 
ORDER BY (now() - query_start) desc;


 
-- ********* Query que pueden ayudar a monitorear la lectura y escritura en disco *********

--- Opcion #
SELECT 
    schemaname,
    relname,
    heap_blks_read,       -- Bloques leídos (desde disco)
    heap_blks_hit,        -- Bloques en caché
    idx_blks_read,        -- Bloques de índices leídos
    idx_blks_hit
FROM pg_statio_all_tables
WHERE schemaname NOT LIKE 'pg_%'
ORDER BY heap_blks_read DESC
LIMIT 0;  -- Top 0 tablas con más I/O de lectura




--- Opcion #
SELECT
    queryid,
    query,
    (shared_blks_read + temp_blks_read) * current_setting('block_size')::int / 0 AS total_read_kb,
    (shared_blks_written + temp_blks_written) * current_setting('block_size')::int / 0 AS total_write_kb
FROM pg_stat_statements
ORDER BY total_read_kb DESC -- Top 0 querys con más I/O de lectura
LIMIT 0;


--- Opcion #3
SELECT
    a.pid,
    a.query,
    a.query_start,
    --pg_size_pretty(pg_temp_files_size(a.pid)) AS temp_files_size,
    (pg_stat_statements.shared_blks_read * 8) || ' KB' AS read_io,
    (pg_stat_statements.shared_blks_written * 8) || ' KB' AS write_io
FROM pg_stat_activity a
JOIN pg_stat_statements ON a.query_id = pg_stat_statements.queryid 
order by pg_stat_statements.shared_blks_r






-- ********* OTROSSSSSSS *********

 SELECT 
    checkpoints_timed,   -- Checkpoints iniciados por tiempo
    checkpoints_req,     -- Checkpoints forzados por operaciones
    buffers_checkpoint,  -- Buffers escritos durante checkpoints
    buffers_clean       -- Buffers escritos por el Background Writer
FROM pg_stat_bgwriter;


SELECT 
    archived_count,     -- Número de WAL archivados exitosamente
    last_archived_wal,  -- Último archivo WAL archivado
    last_failed_wal,    -- Último WAL que falló al archivarse
    failed_count        -- Total de fallos de archivado
FROM pg_stat_archiver;


--- estadísticas detalladas sobre las operaciones de lectura/escritura (I/O) en PostgreSQL, desglosadas por tipo de operación (backend, checkpoints, autovacuum, etc.).
SELECT * FROM pg_stat_io 
WHERE reads > 0 OR writes > 0 
ORDER BY reads DESC;

```

### DISCARD Liberar recursos en session
```sql
afectará únicamente a la sesión específica de PostgreSQL desde la cual se ejecuta el comando, y no tendrá ningún efecto en otras sesiones o conexiones activas en el servidor.
liberar todos los recursos internos
- Cierra las conexiones activas
- Restablece la autorización
- Resetea configuraciones
- Libera planes de consulta en caché
- Limpia datos temporales

DISCARD ALL;
DISCARD TEMP;
DISCARD PLANS;
DISCARD SEQUENCES;
 
-- Establece el tiempo de espera de consultas a 5 segundos
SET statement_timeout = '5s';

-- Restablece statement_timeout a su valor predeterminado
RESET statement_timeout;
 
RESET ALL;

```

```sql
-- falta por investigar 
indices  perdidos que hacen falta
indices que no se usan
indices que se usan mucho
indices desfragmentados 
cache_hit 
bloat


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


En **PostgreSQL**, el término **"bloat"** se refiere al crecimiento innecesario del tamaño de las tablas y los índices. Esto puede afectar el rendimiento de las consultas y aumentar el uso de espacio en disco. Permíteme explicarte más detalladamente:

- **¿Por qué se genera bloat?**
 En PostgreSQL, el término “bloat” se refiere a la condición donde el tamaño de las tablas y/o índices crece más de lo necesario, lo que resulta en un rendimiento más lento de las consultas y un uso incrementado del espacio en disco. Esto ocurre debido a cómo PostgreSQL maneja las operaciones de actualización y eliminación bajo su sistema de control de concurrencia multiversión (MVCC).

Cuando se realiza una operación de UPDATE o DELETE, PostgreSQL no elimina físicamente esas filas del disco. En el caso de un UPDATE, marca las filas afectadas como invisibles e inserta nuevas versiones de esas filas. Con DELETE, simplemente marca las filas afectadas como invisibles. Estas filas invisibles también se conocen como filas muertas o tuplas muertas.

Con el tiempo, estas tuplas muertas pueden acumularse y ocupar un espacio significativo en el disco, lo que puede degradar el rendimiento de la base de datos. Para detectar y resolver el bloat, se pueden utilizar herramientas como pgstattuple, que es un módulo de extensión que proporciona una imagen clara del bloat real en tablas e índices

  - Las filas "muertas" (sin transacciones activas o pasadas que las consulten) contribuyen al bloat. Si no se realiza una acción de **vacuum**, la base de datos crecerá indefinidamente, ya que los registros no se eliminan, sino que quedan "muertos".

- **Impacto del bloat en el rendimiento:**
  - El bloat afecta el rendimiento porque las páginas de las tablas e índices cargan más filas muertas, lo que resulta en más operaciones de E/S innecesarias.
  - Los escaneos secuenciales también pasan por filas muertas, consumiendo memoria innecesariamente.

- **Tuning del autovacuum:**
  - Configurar correctamente el **autovacuum** es esencial. Este servicio realiza acciones de vacuum en tablas e índices según ciertas condiciones, evitando afectar el funcionamiento normal de la base de datos.


 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 
 Sistemas de almacenamiento en caché, un **"hit"** se refiere a una operación exitosa de búsqueda o acceso a un elemento almacenado en la memoria caché o en una estructura de datos. Aquí tienes algunos ejemplos:

. **Cache Hit (Acertado en caché):**
   - Cuando un sistema busca un valor (como una página web, una fila de una tabla de base de datos o un archivo) en la memoria caché y lo encuentra allí, se considera un **cache hit**.
   - Esto significa que no es necesario acceder al almacenamiento principal (como un disco duro o una base de datos) para recuperar el valor, lo que mejora significativamente el rendimiento y la velocidad de acceso.

. **Page Cache Hit (Acertado en la caché de páginas):**
   - En sistemas operativos, el **page cache** almacena copias de páginas de archivos en memoria RAM para acelerar el acceso a esos archivos.
   - Un **page cache hit** ocurre cuando una aplicación solicita una página de archivo y esa página ya está en el caché de páginas, evitando la necesidad de leerla desde el disco.

3. **Database Cache Hit (Acertado en la caché de la base de datos):**
   - En bases de datos, se almacenan en caché resultados de consultas, índices y otros datos para acelerar las operaciones.
   - Un **database cache hit** ocurre cuando una consulta busca datos que ya están en la caché de la base de datos, evitando la necesidad de acceder a los datos en el almacenamiento físico.

```

# Ejemplos de uso:

<!--  ################################################################### MONITOREO #################################################################################### -->
---
$$ 
MONITOREO 
$$


## Consulta todo en una sola query:
```sh

[NOTA] los estatus son :
idle in transaction : esto es porque realizo un begin y no ha realizado nada 
idle:  esto es porque esta inactivo pero esta conectado, no esta consultando ni ejecutando nada 
ative : Esto quiere decir que esta ejecutando una query

echo "IP" && hostname -I && postgres --version && echo "Numero máximo de conexiones" && psql -At -c "show max_connections;" && echo "Numero de conexiones" && ps -ef | grep -i postgres -wc  && echo "Numero de conexiones en idle" &&  ps -ef | grep -i idle -wc && echo "Unidades" && df -lh&& echo "Mostrar BD Postgres " && psql postgres -c "\\l+" && echo " -- Fecha" && date && echo " -- Mostrar procesos" && psql -xc "select  query,pid,datname,usename,client_addr,query_start,state,application_name,CAST((now()-query_start) as varchar(8)) as time_run, state FROM pg_stat_activity WHERE query != '<IDLE>' AND TRIM(state)!='idle' and pid != pg_backend_pid() ORDER BY query_start ASC;"
```

## Ver el estatus de postgresql 
```sh
systemctl status postgresql  
service postgresql status 
pg_isready 
ps aux | grep postgres
ps aux | grep data -- este te sirve para saber que binarios esta utilizando 
```

## Ver Máximo o Límite conexiones 

- Límite de Conexiones por postgresql:
```sh
show max_connections; 
cat  /sysf/data/postgresql.conf | grep max_connections
```

- Límite de Conexiones por Base de datos:
```sh
select  datname,datconnlimit from pg_database; -- si es - es ilimitado, si tiene algún número se especificó un límite  
```

- Límite de Conexiones por Usuario:
```sh
select  rolname,rolconnlimit from pg_authid ; -- si es - es ilimitado, si tiene algún número se especificó un límite  
```

## Ver la cantidad total de conexiones

- Ver el total de conexiones  Activas y Inactivas nivel Base de datos:
```sh
  select  count(*)  FROM pg_stat_activity; -- el total de conexiones Activas y Inactivas en todas las base de datos 
  select  count(*)  FROM pg_stat_activity WHERE pg_stat_activity.datname = 'MYDBATEST'; --- el total de conexiones realizadas que tiene una base de datos 
  select  count(*)  FROM pg_stat_activity WHERE pg_stat_activity.usename = 'myusertest'; --- el total de conexiones realizadas que tiene un usuario
```

- Saber las cantidades de conexiones **`activas`** en un postgresql version > 9 nivel Base de datos:
```sh
select  count(*) pid FROM pg_stat_activity WHERE  TRIM(state)!='idle';
```
- Saber las cantidades de conexiones **`activas`** en un postgresql version <9 nivel Base de datos:
```sh
select   count(*)  FROM pg_stat_activity where  current_query  !=  '<IDLE>' ;
```
-  Saber las cantidades de conexiones **`Inactivas`** en un postgresql version > 9 nivel Base de datos:
```sh
select  count(*) pid FROM pg_stat_activity WHERE  TRIM(state) ='idle';
```

- Ver el total de conexiones **`activas`** nivel S.O:
```sh
  ps -fea | grep -i postgresql -wc --- Este checa todas las conexiones de todas las bases de datos 
  ps -fea | grep -i MYDBATEST -wc  --- este solo verifica las conexiones de la base de datos que se especificó
  ps -fea | grep  "postgres: usertest" | grep -v "color"  --- este solo verifica las conexiones de usuario que se especificó
```

- Ver el total de conexiones **`Inactivas`** nivel S.O
```sh
 ps -fea | grep -i idle -wc
```

## Verificar conexiones que tienen consultas con tiempo de ejecucion alto

Estatus: `"IDLE"` se refiere a un estado en el que una conexión a la base de datos se encuentra inactiva. Esto significa que la conexión está establecida, pero no se está ejecutando ninguna consulta o transacción en ese momento. Las conexiones "idle" son comunes en entornos de bases de datos donde varios clientes se conectan y desconectan de la base de datos.<br>

Estatus: `"Active"` se refiere a el estado de una conexión a base de datos que se encuentra activa y que en ese preciso momento está realizando una consulta o movimiento.

Es importante entender el concepto de conexiones "idle" en PostgreSQL porque pueden consumir recursos del sistema, como conexiones TCP/IP y memoria, incluso cuando no están realizando ninguna tarea activa. Por lo tanto, es fundamental administrar y controlar estas conexiones para evitar problemas de rendimiento y recursos agotados.


. Configuración en postgresql.conf:

Puedes configurar el tiempo máximo que una conexión puede permanecer inactiva antes de ser terminada automáticamente. Esto se hace mediante el parámetro idle_in_transaction_session_timeout en el archivo de configuración postgresql.conf. Por ejemplo:

`idle_in_transaction_session_timeout = 60000  # 60 segundos (valor en milisegundos)`

 

```
3. Ver las conexiones que tengan más de 5 minutos en postgresql 8
```sh
  psql -xc  "SELECT procpid ,  usename, pg_stat_activity.query_start, now() - pg_stat_activity.query_start AS query_time, current_query FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes' and  current_query  !=  '<IDLE>';"
```


## Cerrar conexiones Activas o IDLE
**Opción # Cerrar solo una conexiones, nivel S.O**<br>
Cerrar Conexiones IDLE nivel S.O:
   ```sh
     Kill 356 -- El número es el PID de la conexión 
```
**Opción # Cerrar solo una conexiones, nivel Base de datos**<br>
```sh
select  pg_terminate_backend(356)  -- El número 356 es el PID de la conexión a cerrar
```

**Opción #3 Cerrar todas las conexiones IDLE nivel S.O**<br>
   ```sh
     ps -ef | grep idle | awk '{print " kill " $}' | bash 
```
**Opción # Cerrar todas las conexiones IDLE nivel Base de datos**<br>
```sh
select  pg_terminate_backend (pg_stat_activity.pid) FROM pg_stat_activity WHERE  pg_stat_activity.datname = 'MYDBATEST';
```


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


## Buscar bloqueos 
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
AccessShareLock: Permite a otros procesos leer el objeto pero no modificarlo.
RowShareLock: Permite a otros procesos leer y bloquear filas, pero no cambiar la estructura de la tabla.
RowExclusiveLock: Permite a otros procesos leer y bloquear filas, pero no cambiar la estructura de la tabla.
ShareUpdateExclusiveLock: Bloquea los vaciados de tabla pero permite lecturas y modificaciones de fila.
ShareLock: Permite que otros procesos lean el objeto pero no modificarlo o bloquearlo en un nivel superior.
ShareRowExclusiveLock: Permite que otros procesos lean el objeto pero no modificarlo o bloquearlo en un nivel superior.



## granted: (indica si el bloqueo ha sido concedido o no)
true: El bloqueo ha sido concedido y el proceso que lo solicitó tiene actualmente el control del recurso.
false: El bloqueo no ha sido concedido todavía. El proceso que lo solicitó está esperando a que el recurso se desbloquee. esto es como un wait que esta en espera 


SELECT 
    a.pid,
	a.datname as db_name,
	CASE
		WHEN c.relkind= 'r' THEN 'TABLE'
		WHEN c.relkind= 'p' THEN 'PARTITIONED TABLE'
		WHEN c.relkind= 'i' THEN 'INDEX'
		WHEN c.relkind= 'S' THEN 'SEQUENCE'
		WHEN c.relkind= 'v' THEN 'VIEW'
		WHEN c.relkind= 'm' THEN 'MATERIALIZED VIEW'
		WHEN c.relkind= 'c' THEN 'type'
		WHEN c.relkind= 't' THEN 'TOAST TABLE'
		WHEN c.relkind= 'f' THEN 'FOREIGN TABLE'
		WHEN c.relkind= 'p' THEN 'PARTITIONED FOREIGN'
		WHEN c.relkind= 'I' THEN 'PARTITIONED INDEX'
	END as obj_type,
	nm.nspname as obj_schema, 
    c.relname AS table_name,    l.page ,  l.tuple AS tupla,
	A.CLIENT_ADDR AS CLI_ADDR,
	a.usename,
	a.state,
    l.locktype,
    l.mode,
	a.query,
    case when l.granted then 'NO WAIT' ELSE 'WAIT OBJECT' END AS status_wait,
    a.wait_event_type,
    --a.wait_event,
    -- a.backend_start as user_start,
    a.query_start
    --a.state_change
FROM 
    pg_locks l
LEFT JOIN 
    pg_stat_activity a ON l.pid = a.pid
LEFT JOIN 
    pg_class c ON l.relation = c.oid   --and relkind   IN ('r','t','v','m','f','p')
LEFT JOIN 
	pg_namespace as nm ON c.relnamespace = nm.oid
WHERE   l.PID !=   pg_backend_pid() 
		AND c.relkind <> 'i'
		-- AND NOT granted --- Estos son puros PID que estan esperando que un proceso sea liberado
ORDER BY
	a.pid,
	c.relkind, 
	c.relname , 
    a.query_start asc     ;




select    l.mode AS bloqueo_modo,  l.granted AS concedido,  l.pid AS proceso_id,  a.usename AS usuario,  l.relation::regclass AS tabla,  l.page AS pagina,  l.tuple AS tupla FROM  pg_locks l JOIN   pg_stat_activity a ON l.pid = a.pid WHERE   NOT l.granted;


```



## Mostrar el tiempo de ejecucion de una consulta en el momento
EXPLAIN para obtener el plan de ejecución de una consulta, lo que te ayudará a entender cómo PostgreSQL planea ejecutar la consulta:
```sql
EXPLAIN select  version();  <br>
EXPLAIN ANALYZE  select  version();

EXPLAIN (FORMAT JSON, ANALYZE true, VERBOSE false, COSTS false, TIMING false, BUFFERS true, SUMMARY false, SETTINGS false, WAL false) select * from public.psql_tasa_crecimiento_db;

https://www.postgresql.org/docs/current/sql-explain.html
https://www.postgresql.org/docs/current/using-explain.html

```


## Todos los stat para monitorear 
```sh
TODOS LOS STATS 
https://www.postgresql.org/docs/8./monitoring-stats.html

## Consultas:
-- Proporciona estadísticas sobre las consultas ejecutadas en la base de datos,  el número de veces que una consulta se ha ejecutado y el tiempo total que ha pasado en la caché.
 como tiempos de ejecución y frecuencia de uso. Ayuda a identificar consultas lentas o ineficientes para optimizar el rendimiento.

select   total_exec_time, min_exec_time,max_exec_time ,calls FROM pg_stat_statements where query ilike '%select %' and not query ilike '%GRANT%' ORDER BY total_plan_time DESC, calls desc limit 0;
select   query, calls, total_time, rows, mean_time FROM pg_stat_statements ORDER BY total_time DESC;



## Usuarios :
select  * from  pg_stat_activity;
select  * from  pg_stat_get_activity;
 
 
## Replication:
select  * from  pg_replication_origin_status; -- Puedes monitorear el estado de la replicación y verificar la sincronización de los orígenes de replicación.
select  * from  pg_stat_replication;
select  * from  pg_stat_wal_receiver;

 ## Base de datos: 
 select  * from  pg_stat_database_conflicts;

---- Podemos ver cauntas conexiones se realizaron, cuantas tuplas han sido afectadas  con update,detele, insert etc 
select  datname AS database_name,
       pg_size_pretty(pg_database_size(datname)) AS size,
       numbackends AS num_connections,
       xact_commit AS transactions_committed,
       xact_rollback AS transactions_rolled_back,
       blks_read AS blocks_read,
       blks_hit AS blocks_hit,
       tup_returned AS tuples_returned,
       tup_fetched AS tuples_fetched,
       tup_inserted AS tuples_inserted,
       tup_updated AS tuples_updated,
       tup_deleted AS tuples_deleted,
       stats_reset AS statistics_reset
FROM pg_stat_database;  -- Mostrar el tamaño y estadísticas de todas las bases de datos:


 ## Tablas: 
 select  * from  pg_stat_all_tables;
 select  * from  pg_stat_xact_all_tables;
 select  * from  pg_stat_sys_tables;
 select  * from  pg_stat_xact_sys_tables;
 select  * from  pg_stat_xact_user_tables;
 select  * from  pg_statio_all_tables;
 select  * from  pg_statio_sys_tables;
 select  * from  pg_statio_user_tables;


---- AQui podemos ver cuantas tuplas han sido afectadas  con update,detele, insert etc 
select  schemaname || '.' || relname AS table_full_name,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) AS size,
       pg_size_pretty(pg_relation_size(schemaname || '.' || relname)) AS table_size,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname) - pg_relation_size(schemaname || '.' || relname)) AS index_size,
       pg_total_relation_size(schemaname || '.' || relname) - pg_relation_size(schemaname || '.' || relname) AS "index_overhead_bytes"
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname || '.' || relname) DESC; --- Obtener información sobre el tamaño y estado de las tablas:  


## Index:
 select  * from  pg_stat_all_indexes;
 select  * from  pg_stat_sys_indexes;
 select  * from  pg_statio_user_indexes;
 select  * from  pg_statio_all_indexes;
 select  * from  pg_statio_sys_indexes;

  pg_index                      | BASE TABLE |
  pg_indexes                    | VIEW       |
  pg_stat_progress_create_index | VIEW       |

select  relname, indexrelname, idx_scan, idx_tup_read
  FROM pg_stat_user_indexes
WHERE idx_scan > 0 AND idx_tup_read < 000; -- Monitoreo de la fragmentación de índices: PostgreSQL almacena información sobre la fragmentación de índices en la vista pg_stat_user_indexes. Puedes usar esta vista para verificar el nivel de fragmentación de tus índices.

 
## Sequences:
select  * from  pg_statio_all_sequences;
select  * from  pg_statio_sys_sequences;
select  * from  pg_statio_user_sequences;
  
 ## Vacum:
 select  * from   pg_stat_progress_vacuum
 
 ## Function:
 select  * from   pg_stat_user_functions;
 select  * from   pg_stat_xact_user_function;
 
 ## Extras:
 select  * from  pg_stat_archiver; -- Monitorea el proceso que archiva los archivos WAL (Write-Ahead Logs) en un sistema de replicación o backup Verifica la salud del archivado: Detecta si hay retrasos o fallos. , Útil para replicación: Asegura que los réplicas estén al día. ,Muestra el último WAL archivado: Clave para recuperación ante desastres.


 select  * from  pg_stat_bgwriter; -- Proporciona métricas sobre el proceso Background Writer, que escribe páginas de memoria ("buffers sucios") en disco para reducir la carga durante checkpoints. Optimiza , checkpoints: Ayuda a ajustar checkpoint_timeout y max_wal_size. ,Diagnostica presión de escritura: Si hay muchos buffers escritos durante checkpoints., Mejora estabilidad: Evita picos de I/O al distribuir escrituras.


 select  * from  pg_statistic;
 select  * from  pg_statistic_ext;
 select  * from  pg_stats;
 select  * from  pg_prepared_statements;
 select  * from  pg_stat_subscription;
 select  * from  pg_stat_ssl;

select  * from  pg_stat_progress_basebackup
select  * from   pg_stat_progress_copy

```








<!--  ################################################################### OPTIMIZACIÓN  #################################################################################### -->

---

 
$$ 
OPTIMIZACIÓN 
$$

## Parametros del postgresql.conf para una buena optimización 
cat /sysx/data/postgresql.conf | grep -Ei "shared_buffers|effective_cache_size|work_mem|maintenance_work_mem|temp_buffers|max_connections" <br>

`shared_buffers:` Controla la cantidad de memoria compartida utilizada para almacenar bloques de datos en la caché. Es una configuración importante para mejorar el rendimiento. Puedes encontrarla en la sección de memoria.<br>

`effective_cache_size:` Indica cuánta memoria se espera que esté disponible para la caché en total, incluyendo la memoria compartida y la memoria del sistema operativo. También se encuentra en la sección de memoria.<br>

`work_mem y maintenance_work_mem:` Estas configuraciones controlan la cantidad de memoria asignada a operaciones de clasificación y mantenimiento respectivamente.<br>

`temp_buffers:` Define cuánta memoria se usa para operaciones temporales.<br>

`max_connections:` Limita el número máximo de conexiones simultáneas a la base de datos, lo que puede afectar la cantidad de memoria utilizada por las conexiones en caché.


# Mantenimientos : 

**Recomendacion de frecuencia de mantenimientos, esto depende que transaccional es tu servidor**
| Mantenimiento  | Hora de Ejecución | Frecuencia | Motivo |
|----------------|-------------------|------------|--------|
| `ANALYZE`      | :00 AM           | Diario     | Mantiene las estadísticas actualizadas para un rendimiento óptimo de las consultas. |
| Backup         | :00 AM           | Diario     | Asegura la recuperación ante desastres mediante copias de seguridad regulares. |
| `VACUUM`       | :00 AM           | Semanal/Diario    | Libera espacio ocupado por tuplas muertas y mantiene la base de datos en buen estado sin causar interrupciones significativas. |
| `VACUUM FULL`  | 3:00 AM           | Mensual/Semanal    | Bloquea objetos, Recupera espacio en disco y compacta las tablas, pero debe usarse con moderación debido a su impacto en el rendimiento. |
| `REINDEX`      | 5:00 AM          | Mensual/Semanal    | Bloquea objetos, Reconstruye los índices para mejorar el rendimiento de las consultas, minimizando la interrupción del servicio. |
| `CLUSTER`      | 6:00 AM           | Trimestral/semanal | Reorganiza las tablas basándose en un índice, mejorando el rendimiento de las consultas que utilizan ese índice. |




 
 En PostgreSQL, algunos comandos de mantenimiento pueden bloquear las tablas mientras se ejecutan. Aquí tienes una lista de los más comunes:

. **VACUUM FULL**: Este comando recupera espacio en disco y compacta las tablas, pero requiere un bloqueo exclusivo en la tabla, lo que impide cualquier otra operación (lecturas y escrituras) mientras se ejecuta.

. **REINDEX**: Este comando reconstruye los índices de una tabla o base de datos. Durante su ejecución, los índices afectados están bloqueados, lo que puede afectar el rendimiento de las consultas que dependen de esos índices.

3. **CLUSTER**: Este comando reorganiza físicamente una tabla según el orden de un índice especificado. Requiere un bloqueo exclusivo en la tabla, impidiendo otras operaciones mientras se ejecuta.

. **ALTER TABLE**: Algunas operaciones de `ALTER TABLE`, como agregar o eliminar columnas, pueden requerir un bloqueo exclusivo en la tabla, impidiendo otras operaciones hasta que se complete.

5. **DROP TABLE**: Eliminar una tabla también requiere un bloqueo exclusivo, lo que impide cualquier otra operación en la tabla mientras se ejecuta.

### Recomendaciones

- **Planificación**: Programa estos comandos durante períodos de baja actividad para minimizar el impacto en los usuarios.
- **Monitoreo**: Utiliza herramientas de monitoreo para identificar cuándo es necesario ejecutar estos comandos y para minimizar el tiempo de bloqueo.



  
## ¿Qué hace `CLUSTER`?

. **Reorganización Física**: `CLUSTER` ordena las filas de una tabla en el disco según el orden de un índice específico. Esto puede mejorar el rendimiento de las consultas que se benefician de un acceso secuencial a los datos⁵.
. **Mejora del Rendimiento**: Al ordenar físicamente las filas, las consultas que utilizan el índice especificado pueden ser más rápidas, ya que los datos relacionados están más cerca unos de otros en el disco⁵.

### ¿Cuándo usar `CLUSTER`?

- **Consultas Frecuentes**: Es útil cuando tienes consultas que frecuentemente acceden a los datos en el orden del índice.
- **Tablas Grandes**: Puede ser beneficioso para tablas grandes donde el acceso secuencial a los datos puede mejorar significativamente el rendimiento.

### Consideraciones

- **Bloqueo Exclusivo**: `CLUSTER` requiere un bloqueo exclusivo en la tabla, lo que significa que otras operaciones no pueden ocurrir mientras se ejecuta⁵.
- **Espacio en Disco**: La operación puede requerir espacio adicional en disco, ya que PostgreSQL crea una nueva copia de la tabla ordenada⁵.
- **Planificación**: Es recomendable ejecutar `CLUSTER` durante períodos de baja actividad para minimizar el impacto en los usuarios.

### Ejemplo de Uso

```sql
CLUSTER my_table USING my_index;
```
 

## Reindex [documentación oficial](https://www.postgresql.org/docs/current/sql-reindex.html)
Se utiliza para reconstruir los índices de una tabla o base de datos. La principal razón para utilizar REINDEX es mantener o mejorar el rendimiento de las consultas en la base de datos y una des las ventajas son: <br>

**`Fragmentación de índices:`** Con el tiempo, los índices de una tabla pueden volverse fragmentados debido a las inserciones, actualizaciones y eliminaciones de registros. La fragmentación puede hacer que las consultas sean más lentas. REINDEX reconstruye los índices para eliminar la fragmentación y restaurar el rendimiento.

**`Recuperación de índices dañados:`** Si un índice se daña debido a una falla del sistema, un cierre abrupto de la base de datos u otras circunstancias, REINDEX puede ayudar a restaurar la integridad de los índices.

**`Mantenimiento preventivo:`** Realizar un REINDEX periódicamente como parte del mantenimiento de la base de datos puede ayudar a evitar problemas de rendimiento en el futuro. Esto es especialmente importante en bases de datos que experimentan un alto volumen de cambios en los datos.

**`Optimización del rendimiento:`** En ocasiones, puede ser beneficioso realizar un REINDEX después de realizar cambios importantes en la estructura de la tabla o en los datos, como la eliminación masiva de registros o la reorganización de datos. Esto puede ayudar a optimizar el rendimiento de las consultas.

**`Restauración de la consistencia:`** Si se detectan problemas de consistencia en los índices, como duplicados incorrectos, REINDEX puede ayudar a restablecer la consistencia



**REINDEX de una tabla específica:**
``` sh
REINDEX TABLE table_name;
```

**REINDEX de toda la base de datos**
``` sh
REINDEX DATABASE database_name;
```

**REINDEX un index **
``` sh
REINDEX INDEX public.idx_psql_tables_columns_;
```

## Vacum [documentación Oficial](https://www.postgresql.org/docs/current/sql-vacuum.html)


## Comparación

| Característica       | `VACUUM`                          | `VACUUM FULL`                     |
|----------------------|-----------------------------------|-----------------------------------|
| **Eliminación de tuplas muertas** | Sí                                | Sí                                |
| **Compactación de espacio**       | No                                | Sí                                |
| **Reducción del tamaño del archivo** | No                                | Sí                                |
| **Requiere bloqueo exclusivo**    | No                                | Sí                                |
| **Tiempo de ejecución**           | Rápido                            | Lento                             |
| **Impacto en el rendimiento**     | Bajo                              | Alto                              |

Elimina las tuplas marcadas como obsoletas o muertas por transacciones anteriores. Cuando se insertan, actualizan o eliminan datos en una base de datos, PostgreSQL no elimina físicamente las tuplas obsoletas de inmediato; simplemente las marca como obsoletas. El comando VACUUM libera el espacio ocupado por estas tuplas obsoletas, lo que ayuda a reducir el tamaño de la base de datos y a mejorar el rendimiento.
```sh
VACUUM;
  ```


es un comando combinado que ayuda a mantener la base de datos PostgreSQL en un estado más óptimo, eliminando tuplas obsoletas y actualizando las estadísticas para mejorar el rendimiento de las consultas
  ```sh 
  VACUUM ANALYZE;
 ```

Recupera espacio inmediatamente eliminando las filas obsoletas y compactando la tabla. Este proceso bloquea la tabla durante su ejecución.
  ```sh
VACUUM FULL table_name;  -- individual
VACUUM FULL VERBOSE ANALYZE -- en todas las tablas 
  ```

Congela todas las filas de la tabla, lo que es útil cuando se necesita garantizar que una tabla no cambie para realizar copias de seguridad.
  ```sh
VACUUM FREEZE table_name; -- individual
VACUUM FREEZE;  -- completa
  ```

## ANALYZE

Actualiza las estadísticas de la tabla, lo que puede ayudar al planificador de consultas a tomar decisiones más informadas.
  ```sh
ANALYZE table_name; --- individual
ANALYZE VERBOSE; -- actualiza las estadisticas de todas las tablas 
  ```

## Tools de optimización:

[Documentación Oficial PG_REPACK](https://github.com/reorg/pg_repack) <br>
[Documentación Extra](https://pgxn.org/dist/pg_repack/doc/pg_repack.html) <br>
pg_repack -U $DB_USER -d $DB_NAME --> Esta herramienta se utiliza para reorganizar físicamente las tablas y sus índices, reduciendo la fragmentación y mejorando el rendimiento.


# Herramienta pgbench de test de optimización 

 ```
hay que jugar con el parametro shared_buffers  hasta encontrar lo mejor

example=# \dt+
                          List of relations
 Schema |       Name       | Type  |  Owner   |  Size   | Description 
--------+------------------+-------+----------+---------+-------------
 public | pgbench_accounts | table | postgres | 6 MB  | 
 public | pgbench_branches | table | postgres | 0 kB   | 
 public | pgbench_history  | table | postgres | 0 bytes | 
 public | pgbench_tellers  | table | postgres | 56 kB   | 
( rows)

  createdb db_prueba
 pgbench -U postgres -h 7.0.0. -i -s 70 db_prueba
 pgbench -S -C -n  -U postgres -h 7.0.0. -p 53  -c 500 -j 0 -T 800 db_prueba

  
  pgbench -i -s <escala> testdb
    - -i: Esta opción indica a pgbench que inicialice la base de datos con datos de prueba.
    -s <escala>: Esta opción determina la escala de los datos generados. La escala indica el factor multiplicativo en relación con el tamaño predeterminado de la base de datos. Por ejemplo, -s 0 generará datos de prueba diez veces más grandes que el tamaño predeterminado.


# PRUEBA BÁSICA
pgbench -n -U postgres -h 7.0.0. -p 53  -c 500 -j 0 -T 800 db_prueba

# PRUEBA PERSONALIZADA
pgbench -n -U postgres -h 7.0.0. -p 53  -c 500 -j 0 -t 0000 db_prueba -f script.sql



~]$ pgbench -?
pgbench is a benchmarking tool for PostgreSQL.

Usage:
  pgbench [OPTION]... [DBNAME]

Initialization options:
  -i, --initialize         invokes initialization mode
  -I, --init-steps=[dtgGvpf]+ (default "dtgvp")
                           run selected initialization steps
  -F, --fillfactor=NUM     set fill factor
  -n, --no-vacuum          do not run VACUUM during initialization
  -q, --quiet              quiet logging (one message each 5 seconds)
  -s, --scale=NUM          scaling factor
  --foreign-keys           create foreign key constraints between tables
  --index-tablespace=TABLESPACE
                           create indexes in the specified tablespace
  --partition-method=(range|hash)
                           partition pgbench_accounts with this method (default: range)
  --partitions=NUM         partition pgbench_accounts into NUM parts (default: 0)
  --tablespace=TABLESPACE  create tables in the specified tablespace
  --unlogged-tables        create tables as unlogged tables

Options to select what to run:
  -b, --builtin=NAME[@W]   add builtin script NAME weighted at W (default: )
                           (use "-b list" to list available scripts)
  -f, --file=FILENAME[@W]  add script FILENAME weighted at W (default: )
  -N, --skip-some-updates  skip updates of pgbench_tellers and pgbench_branches
                           (same as "-b simple-update")
  -S, --select-only        perform SELECT-only transactions
                           (same as "-b select-only")

Benchmarking options:
  -c, --client=NUM         number of concurrent database clients (default: )
  -C, --connect            establish new connection for each transaction
  -D, --define=VARNAME=VALUE
                           define variable for use by custom script
  -j, --jobs=NUM           number of threads (default: )
  -l, --log                write transaction times to log file
  -L, --latency-limit=NUM  count transactions lasting more than NUM ms as late
  -M, --protocol=simple|extended|prepared
                           protocol for submitting queries (default: simple)
  -n, --no-vacuum          do not run VACUUM before tests
  -P, --progress=NUM       show thread progress report every NUM seconds
  -r, --report-per-command report latencies, failures, and retries per command
  -R, --rate=NUM           target rate in transactions per second
  -s, --scale=NUM          report this scale factor in output
  -t, --transactions=NUM   number of transactions each client runs (default: 0)
  -T, --time=NUM           duration of benchmark test in seconds
  -v, --vacuum-all         vacuum all four standard tables before tests
  --aggregate-interval=NUM aggregate data over NUM seconds
  --failures-detailed      report the failures grouped by basic types
  --log-prefix=PREFIX      prefix for transaction time log file
                           (default: "pgbench_log")
  --max-tries=NUM          max number of tries to run transaction (default: )
  --progress-timestamp     use Unix epoch timestamps for progress
  --random-seed=SEED       set random seed ("time", "rand", integer)
  --sampling-rate=NUM      fraction of transactions to log (e.g., 0.0 for %)
  --show-script=NAME       show builtin script code, then exit
  --verbose-errors         print messages of all errors

Common options:
  -d, --debug              print debugging output
  -h, --host=HOSTNAME      database server host or socket directory
  -p, --port=PORT          database server port number
  -U, --username=USERNAME  connect as specified database user
  -V, --version            output version information, then exit
  -?, --help               show this help, then exit

Report bugs to <pgsql-bugs@lists.postgresql.org>.
PostgreSQL home page: <https://www.postgresql.org/>








-------- BIBLIOGRAFÍAS ---------------
Existe la tool pgingester, que es más para metodos de ingestión(inserción)  link referencias : https://medium.com/timescale/benchmarking-postgresql-batch-ingest-5fbe097de

https://www.postgresql.org/docs/current/pgbench.html
https://medium.com/@c.ucanefe/pgbench-load-test-66bdfb5c75a
https://juantrucupei.wordpress.com/07//30/uso-de-pgbench-para-pruebas-stress-postgresql/
 ```

#  MONITOREAR ERRORES EN ARCHIVOS IMPORTANTES
 ```SQL 
select  'select * from '||specific_schema|| '.' || routine_name || '() limit ;' from information_schema.routines where specific_name ilike '%stat%' group by routine_name, specific_schema  ;


select 'select * from '||table_schema || '.'|| table_name || ' limit  ;'from information_schema.tables where table_name ilike '%stat%'
group by table_name,table_schema;



-- archivo postgresql.conf - valida en tiempo real si  hay errores 
select * from pg_catalog.pg_file_settings where error is not null; 
select * from pg_show_all_file_settings() where error is not null;

select *from pg_settings  ; 
select * from pg_show_all_settings() where pending_restart != 'f';

 

-- archivo pg_hba 
select * from pg_catalog.pg_reload_conf() ; -- hacer un reload 

select * from pg_catalog.pg_hba_file_rules() limit ; 
select * from pg_catalog.pg_hba_file_rules where error is not null;
 

---- ident - valida en tiempo real  
select * from pg_catalog.pg_ident_file_mappings where error is not null;


--- extras 
select * from pg_catalog.pg_db_role_setting ;


--- monitoreo 
select * from pg_catalog.pg_stat_database_conflicts limit 0 ;
 ```


### Tablas  que sirven
 ```sql
 SELECT relname AS table_name,
       n_tup_ins AS rows_inserted,
       n_tup_upd AS rows_updated,
       n_tup_del AS rows_deleted,
       n_live_tup AS live_rows,
       n_dead_tup AS dead_rows,
	   last_vacuum,
	   last_autoanalyze,
       last_autovacuum,
       last_autoanalyze
FROM pg_stat_user_tables;
 
 --- tablas que no se usan 
SELECT relname
FROM pg_stat_user_tables
WHERE seq_scan = 0 AND idx_scan = 0;

---- monitorea el timepo de ejecucion y cantidad de ejecucion, de todas las base de datos 
select * from pg_stat_statements;

select 	* from pg_stat_database;
select 	* from pg_stat_user_indexes
SELECT  * from pg_stat_user_tables order by schemaname,relname;
select 	* from pg_stat_user_functions
 ```

# CREAR TABLAS CON MUCHOS REGISTROS 
 ```sql
create table test (id numeric, name varchar, fecha date);
insert into test (select generate_series(,0000000), ‘name-‘||generate_series(,0000000), now() + interval ‘’ minute);
explain analyze select * from test where id > 00 and id <= 50;

 ```





#  LLVM en PostgreSQL
 ```sql
El paquete LLVM para PostgreSQL se utiliza principalmente para habilitar 
la compilación Just-In-Time (JIT) de consultas. Aquí te explico en detalle:

### ¿Qué es LLVM en PostgreSQL?

LLVM (Low-Level Virtual Machine) es un conjunto de herramientas de compilación que
 permite la optimización y generación de código en tiempo de ejecución. En PostgreSQL,
 LLVM se utiliza para la compilación JIT de ciertas consultas SQL, lo que puede mejorar significativamente el rendimiento de las consultas que son intensivas en CPU.

### Ventajas de usar LLVM en PostgreSQL

. **Mejora del rendimiento**: La compilación JIT puede acelerar las consultas SQL al 
convertir el código interpretado en código nativo optimizado. Esto es especialmente útil para consultas complejas y repetitivas.
. **Optimización dinámica**: LLVM permite optimizaciones en tiempo de ejecución, 
lo que significa que puede adaptar el código generado a las condiciones específicas de la consulta y el entorno.
3. **Reducción de la latencia**: Al compilar partes de la consulta en código nativo, 
se reduce el tiempo de ejecución, lo que puede ser crucial para aplicaciones que requieren respuestas rápidas.

### Desventajas de usar LLVM en PostgreSQL

. **Sobrecarga inicial**: La compilación JIT introduce una sobrecarga inicial, ya que
 el código debe ser compilado antes de ser ejecutado. Esto puede no ser beneficioso para consultas simples o de corta duración.
. **Complejidad adicional**: Habilitar y configurar LLVM puede añadir complejidad al 
sistema de base de datos, lo que puede requerir conocimientos adicionales y ajustes finos.
3. **Uso de recursos**: La compilación JIT puede consumir más recursos del sistema, 
como CPU y memoria, lo que podría afectar el rendimiento general si no se gestiona adecuadamente.

### ¿Cuándo usar LLVM en PostgreSQL?

- **Consultas intensivas en CPU**: Si tienes consultas que realizan muchas operaciones 
aritméticas o de procesamiento de datos, la compilación JIT puede ofrecer mejoras significativas.
- **Consultas repetitivas**: Para consultas que se ejecutan frecuentemente, la sobrecarga 
inicial de la compilación JIT se amortiza con el tiempo, resultando en un rendimiento mejorado.
- **Entornos de alto rendimiento**: En aplicaciones donde el rendimiento es crítico, como 
en análisis de datos en tiempo real, la compilación JIT puede ser muy beneficiosa.

 

 ```




 


### **¿Qué es HOT?**  [[Ref-1]](https://www.cybertec-postgresql.com/en/hot-updates-in-postgresql-for-better-performance/)[[Ref-2]](https://medium.com/@nikolaykudinov/deep-dive-into-postgresqls-hot-updates-the-story-behind-heap-only-tuples-f569360d9c) 
HOT (**Heap Only Tuple**) fue introducido en **PostgreSQL 8.3** y se maneja de forma automática. Permite que los registros sean actualizados sin modificar los índices, lo que mejora el rendimiento en bases de datos.

### **Beneficios de usar HOT**  
- Reduce la sobrecarga en actualizaciones al evitar escrituras innecesarias en índices.  
- Disminuye el consumo de I/O, ya que los índices no necesitan ser modificados.  
- Optimiza el rendimiento en tablas con alta concurrencia de actualizaciones.  
- Previene la fragmentación de índices (**bloat**), evitando reescrituras innecesarias.  

### **Desventajas de HOT**  
- Solo funciona cuando la columna modificada **no está indexada**. Si la columna tiene un índice, PostgreSQL **no puede usar HOT** y la actualización afectará el índice.  
- Requiere espacio disponible en la página. Si la página está llena, el sistema usará una actualización tradicional sin HOT.

---

### **Ejemplo 1: Modificación de una columna sin índice**  
Cuando una columna no tiene índice, PostgreSQL puede aplicar HOT para optimizar la actualización:  
1. Se crea una nueva versión del registro dentro de la misma página, sin modificar el índice.  
2. El **ctid** cambia, apuntando a la nueva versión del registro.  
3. La página mantiene un enlace interno entre la versión antigua y la nueva, evitando escrituras adicionales en el índice.

---

### **Ejemplo 2: Modificación de una columna con índice**  
Si la columna que se modifica está indexada, PostgreSQL **no puede usar HOT** y sigue otro proceso:  
1. Se genera una nueva versión del registro.  
2. El índice debe actualizarse para reflejar el nuevo valor.  
3. Se crea una nueva entrada en el índice, lo que implica más operaciones de I/O.  
4. El **ctid** cambia y apunta a una nueva ubicación sin enlace interno.

---

### **Consideraciones para optimizar el uso de HOT**  
- **Evita indexar columnas que cambian con frecuencia**, para que PostgreSQL pueda aplicar HOT.  
- **Ajusta el `fillfactor`** al crear la tabla, dejando espacio libre en cada página (ejemplo: `fillfactor=80`).  
- **Monitorea el uso de HOT con `pageinspect`** para verificar si las actualizaciones realmente lo están aprovechando.  
- **Ejecuta `VACUUM` regularmente**, ya que aunque HOT optimiza las escrituras, las versiones antiguas de los registros siguen ocupando espacio hasta que se libera.


### Cuando usarlo 
- Si la tabla es mayormente de solo lectura, mantener fillfactor = 100 es lo más eficiente. 
- Si la tabla tiene muchas actualizaciones, reducirlo 80 0 90 puede ser beneficioso para evitar reubicaciones de registros

### Ejemplo de ajustes : 


### **Creación de la tabla con un fillfactor óptimo**
Para mejorar la eficiencia, podríamos configurar el `fillfactor` en **80** en lugar del valor predeterminado (**100**). Esto permite que cada página tenga un 20% de espacio libre,  permitiendo futuras actualizaciones dentro de la misma página.

```sql
CREATE TABLE ejemplo (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    descripcion TEXT
) WITH (fillfactor = 80);

ALTER TABLE mi_tabla SET (fillfactor = 80);
```


### **Qué pasa si el fillfactor es 100**
Si hubiésemos definido la tabla con `fillfactor=100`, cada página se llenaría completamente, sin espacio para modificaciones. En ese caso, PostgreSQL **no podría usar HOT** y tendría que mover el registro a otra página, incrementando el costo de I/O.

🔹 **Fillfactor alto (100)** → Más eficiencia en lecturas pero peor rendimiento en actualizaciones.  
🔹 **Fillfactor optimizado (80)** → Mejor rendimiento en tablas con muchos `UPDATE`.


### **Impacto negativo de un `fillfactor` menor (ejemplo: 80%)**  
 **Más páginas necesarias:** Como cada página deja un 20% de espacio libre, la tabla ocupará más páginas en el almacenamiento.  
 **Posible impacto en lecturas secuenciales:** Si la tabla se consulta con `SELECT * FROM`, el acceso a más páginas puede ralentizar la lectura, especialmente en bases de datos grandes.  
 **Mayor consumo de almacenamiento:** Si la tabla tiene millones de registros, el espacio desperdiciado puede afectar el tamaño total de la base de datos.  

 Sin embargo, **el beneficio de mejorar actualizaciones** puede superar estos costos en bases de datos con cambios frecuentes. **Todo depende del caso de uso.**  









 
# **Stats target**
El parámetro **Stats target** define el número de muestras que PostgreSQL toma para generar estadísticas sobre una columna. Estas estadísticas son cruciales para que el optimizador de consultas elija el plan de ejecución más eficiente. Puedes ajustar este parámetro para mejorar el rendimiento de las consultas:

- **Valor por defecto**: 00
- **Rango**: 0 a 0,000
 
```sql
 ALTER TABLE ventas ALTER COLUMN precio SET STATISTICS 500;
```
 
 
 
 
 
 
   

# Monitoreo de Write and Reads 
proporcionar información detallada sobre las operaciones de entrada/salida (E/S) que realiza la base de datos. operaciones de lectura y escritura en el disco. 
```
 
SELECT
    backend_type,
    object,
    context,
    reads,
    read_time,
    writes,
    write_time,
    hits,
    evictions
FROM pg_stat_io;




```



# (single-user mode) Modo usuario unico 

El modo de usuario único en PostgreSQL (single-user mode) es una configuración especial que te permite ejecutar el servidor de base de datos como un único proceso y conectar solo una sesión a la vez.

**Objetivo :**
El principal objetivo del modo de usuario único es realizar tareas de mantenimiento, recuperación o depuración de la base de datos en un entorno controlado. Este modo es útil cuando necesitas realizar cambios críticos en la base de datos y no quieres que otras conexiones interfieran.

```
# Ejemplo para ejecutar un script 
 /usr/pgsql-5/bin/postgres  --single  -D /sysx/data -F -c exit_on_error=true postgres < /path/to/recovery_script.sql 

# conectarte y ejceutar comandos 
[postgres@TEST_SERVER data5]$  /usr/pgsql-5/bin/postgres  --single  -D /sysx/data  -F -c exit_on_error=true postgres

PostgreSQL stand-alone backend 5.8
backend> select version();
<0--5 3::09 MST     769 6737aad9.9930b >LOG:  statement: select version();

         : version     (typeid = 5, len = -, typmod = -, byval = f)
        ----
         : version = "PostgreSQL 5.8 on x86_6-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 005 (Red Hat 8.5.0-), 6-bit" (typeid = 5, len = -, typmod = -, byval = f)
        ----
<0--5 3::09 MST     769 6737aad9.9930b >LOG:  duration: .93 ms
backend>
```
 
https://postgresconf.org/system/events/document/000/00/3/Troubleshoot_PG_Perf-070.pdf
