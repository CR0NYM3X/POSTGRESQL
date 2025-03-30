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
- 1 .- Validar el espacio de los discos duros, tambien monitorear el comportamiento de escritura y lectura <br>
- 2 .- Monitorear el procesador y la memoria Ram, verificando el comportamiento de escritura y lectura  <br>
- 3 .- Validar maximo de conexiones y cuantas conexiones hay en ese momento y eliminar consultas bloqueadas <br>
- 4 .- Verificar el tiempo que tiene encendido el servidor <br>
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


En **PostgreSQL**, el término **"bloat"** se refiere al crecimiento innecesario del tamaño de las tablas y los índices. Esto puede afectar el rendimiento de las consultas y aumentar el uso de espacio en disco¹. Permíteme explicarte más detalladamente:

- **¿Por qué se genera bloat?**
 En PostgreSQL, el término “bloat” se refiere a la condición donde el tamaño de las tablas y/o índices crece más de lo necesario, lo que resulta en un rendimiento más lento de las consultas y un uso incrementado del espacio en disco1. Esto ocurre debido a cómo PostgreSQL maneja las operaciones de actualización y eliminación bajo su sistema de control de concurrencia multiversión (MVCC).

Cuando se realiza una operación de UPDATE o DELETE, PostgreSQL no elimina físicamente esas filas del disco. En el caso de un UPDATE, marca las filas afectadas como invisibles e inserta nuevas versiones de esas filas. Con DELETE, simplemente marca las filas afectadas como invisibles. Estas filas invisibles también se conocen como filas muertas o tuplas muertas.

Con el tiempo, estas tuplas muertas pueden acumularse y ocupar un espacio significativo en el disco, lo que puede degradar el rendimiento de la base de datos. Para detectar y resolver el bloat, se pueden utilizar herramientas como pgstattuple, que es un módulo de extensión que proporciona una imagen clara del bloat real en tablas e índices

  - Las filas "muertas" (sin transacciones activas o pasadas que las consulten) contribuyen al bloat. Si no se realiza una acción de **vacuum**, la base de datos crecerá indefinidamente, ya que los registros no se eliminan, sino que quedan "muertos"¹.

- **Impacto del bloat en el rendimiento:**
  - El bloat afecta el rendimiento porque las páginas de las tablas e índices cargan más filas muertas, lo que resulta en más operaciones de E/S innecesarias.
  - Los escaneos secuenciales también pasan por filas muertas, consumiendo memoria innecesariamente¹.

- **Tuning del autovacuum:**
  - Configurar correctamente el **autovacuum** es esencial. Este servicio realiza acciones de vacuum en tablas e índices según ciertas condiciones, evitando afectar el funcionamiento normal de la base de datos¹.


 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 
 Sistemas de almacenamiento en caché, un **"hit"** se refiere a una operación exitosa de búsqueda o acceso a un elemento almacenado en la memoria caché o en una estructura de datos. Aquí tienes algunos ejemplos:

1. **Cache Hit (Acertado en caché):**
   - Cuando un sistema busca un valor (como una página web, una fila de una tabla de base de datos o un archivo) en la memoria caché y lo encuentra allí, se considera un **cache hit**.
   - Esto significa que no es necesario acceder al almacenamiento principal (como un disco duro o una base de datos) para recuperar el valor, lo que mejora significativamente el rendimiento y la velocidad de acceso.

2. **Page Cache Hit (Acertado en la caché de páginas):**
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
select  datname,datconnlimit from pg_database; -- si es -1 es ilimitado, si tiene algún número se especificó un límite  
```

- Límite de Conexiones por Usuario:
```sh
select  rolname,rolconnlimit from pg_authid ; -- si es -1 es ilimitado, si tiene algún número se especificó un límite  
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


1. Configuración en postgresql.conf:

Puedes configurar el tiempo máximo que una conexión puede permanecer inactiva antes de ser terminada automáticamente. Esto se hace mediante el parámetro idle_in_transaction_session_timeout en el archivo de configuración postgresql.conf. Por ejemplo:

`idle_in_transaction_session_timeout = 60000  # 60 segundos (valor en milisegundos)`

 

```
3. Ver las conexiones que tengan más de 5 minutos en postgresql 8
```sh
  psql -xc  "SELECT procpid ,  usename, pg_stat_activity.query_start, now() - pg_stat_activity.query_start AS query_time, current_query FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes' and  current_query  !=  '<IDLE>';"
```


## Cerrar conexiones Activas o IDLE
**Opción #1 Cerrar solo una conexiones, nivel S.O**<br>
Cerrar Conexiones IDLE nivel S.O:
   ```sh
     Kill 123456 -- El número es el PID de la conexión 
```
**Opción #2 Cerrar solo una conexiones, nivel Base de datos**<br>
```sh
select  pg_terminate_backend(123456)  -- El número 123456 es el PID de la conexión a cerrar
```

**Opción #3 Cerrar todas las conexiones IDLE nivel S.O**<br>
   ```sh
     ps -ef | grep idle | awk '{print " kill " $2}' | bash 
```
**Opción #4 Cerrar todas las conexiones IDLE nivel Base de datos**<br>
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
delete from fdw_conf.scan_rules_query where id = 1 ; 
COMMIT;
```


## Ejemplo de un log con registros de locks
```
Parametros que registran esto :
log_statement = 'all'
log_lock_waits = on

1.- El proceso 2709374 esta esperando un objeto bloqueado , y quiere colocarse en AccessShareLock de un objeto compartidos a nivel global en PostgreSQL y ha estado esperando por 1000.076 milisegundos.
<2025-01-10 00:00:05 MST     2709374 6780c574.29577e >LOG:  process 2709374 still waiting for AccessShareLock on relation 2965 of database 0 after 1000.076 ms


2.- Estos procesos (2675150, 2675331, 2675358, 2675364) son los que actualmente tienen el bloqueo que el proceso 2709374 y Estos procesos (2709280, 2709374) están en la cola de espera
<2025-01-10 00:00:05 MST     2709374 6780c574.29577e >DETAIL:  Processes holding the lock: 2675150, 2675331, 2675358, 2675364. Wait queue: 2709280, 2709374.

3.- El proceso 2709374 que finalmente ha adquirido el bloqueo AccessShareLock a esperado 7661187.620 milisegundos (2.13 horas))
<2025-01-10 02:07:45 MST     2709374 6780c574.29577e >LOG:  process 2709374 acquired AccessShareLock on relation 2965 of database 0 after 7661187.620 ms
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
```


## Todos los stat para monitorear 
```sh
TODOS LOS STATS 
https://www.postgresql.org/docs/8.4/monitoring-stats.html

## Consultas:
-- Proporciona estadísticas sobre las consultas ejecutadas en la base de datos,  el número de veces que una consulta se ha ejecutado y el tiempo total que ha pasado en la caché.
 como tiempos de ejecución y frecuencia de uso. Ayuda a identificar consultas lentas o ineficientes para optimizar el rendimiento.

select   total_exec_time, min_exec_time,max_exec_time ,calls FROM pg_stat_statements where query ilike '%select %' and not query ilike '%GRANT%' ORDER BY total_plan_time DESC, calls desc limit 10;
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
WHERE idx_scan > 0 AND idx_tup_read < 1000; -- Monitoreo de la fragmentación de índices: PostgreSQL almacena información sobre la fragmentación de índices en la vista pg_stat_user_indexes. Puedes usar esta vista para verificar el nivel de fragmentación de tus índices.

 
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
| `ANALYZE`      | 4:00 AM           | Diario     | Mantiene las estadísticas actualizadas para un rendimiento óptimo de las consultas. |
| Backup         | 1:00 AM           | Diario     | Asegura la recuperación ante desastres mediante copias de seguridad regulares. |
| `VACUUM`       | 2:00 AM           | Semanal/Diario    | Libera espacio ocupado por tuplas muertas y mantiene la base de datos en buen estado sin causar interrupciones significativas. |
| `VACUUM FULL`  | 3:00 AM           | Mensual/Semanal    | Bloquea objetos, Recupera espacio en disco y compacta las tablas, pero debe usarse con moderación debido a su impacto en el rendimiento. |
| `REINDEX`      | 5:00 AM          | Mensual/Semanal    | Bloquea objetos, Reconstruye los índices para mejorar el rendimiento de las consultas, minimizando la interrupción del servicio. |
| `CLUSTER`      | 6:00 AM           | Trimestral/semanal | Reorganiza las tablas basándose en un índice, mejorando el rendimiento de las consultas que utilizan ese índice. |




 
 En PostgreSQL, algunos comandos de mantenimiento pueden bloquear las tablas mientras se ejecutan. Aquí tienes una lista de los más comunes:

1. **VACUUM FULL**: Este comando recupera espacio en disco y compacta las tablas, pero requiere un bloqueo exclusivo en la tabla, lo que impide cualquier otra operación (lecturas y escrituras) mientras se ejecuta¹.

2. **REINDEX**: Este comando reconstruye los índices de una tabla o base de datos. Durante su ejecución, los índices afectados están bloqueados, lo que puede afectar el rendimiento de las consultas que dependen de esos índices¹.

3. **CLUSTER**: Este comando reorganiza físicamente una tabla según el orden de un índice especificado. Requiere un bloqueo exclusivo en la tabla, impidiendo otras operaciones mientras se ejecuta¹.

4. **ALTER TABLE**: Algunas operaciones de `ALTER TABLE`, como agregar o eliminar columnas, pueden requerir un bloqueo exclusivo en la tabla, impidiendo otras operaciones hasta que se complete¹.

5. **DROP TABLE**: Eliminar una tabla también requiere un bloqueo exclusivo, lo que impide cualquier otra operación en la tabla mientras se ejecuta¹.

### Recomendaciones

- **Planificación**: Programa estos comandos durante períodos de baja actividad para minimizar el impacto en los usuarios.
- **Monitoreo**: Utiliza herramientas de monitoreo para identificar cuándo es necesario ejecutar estos comandos y para minimizar el tiempo de bloqueo.



  
## ¿Qué hace `CLUSTER`?

1. **Reorganización Física**: `CLUSTER` ordena las filas de una tabla en el disco según el orden de un índice específico. Esto puede mejorar el rendimiento de las consultas que se benefician de un acceso secuencial a los datos⁵.
2. **Mejora del Rendimiento**: Al ordenar físicamente las filas, las consultas que utilizan el índice especificado pueden ser más rápidas, ya que los datos relacionados están más cerca unos de otros en el disco⁵.

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
REINDEX INDEX public.idx_psql_tables_columns_4;
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
VACUUM FULL -- en todas las tablas 
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
 public | pgbench_accounts | table | postgres | 641 MB  | 
 public | pgbench_branches | table | postgres | 40 kB   | 
 public | pgbench_history  | table | postgres | 0 bytes | 
 public | pgbench_tellers  | table | postgres | 56 kB   | 
(4 rows)

  createdb db_prueba
 pgbench -U postgres -h 127.0.0.1 -i -s 70 db_prueba
 pgbench -S -C -n  -U postgres -h 127.0.0.1 -p 5432  -c 500 -j 20 -T 1800 db_prueba

  
  pgbench -i -s <escala> testdb
    - -i: Esta opción indica a pgbench que inicialice la base de datos con datos de prueba.
    -s <escala>: Esta opción determina la escala de los datos generados. La escala indica el factor multiplicativo en relación con el tamaño predeterminado de la base de datos. Por ejemplo, -s 10 generará datos de prueba diez veces más grandes que el tamaño predeterminado.


# PRUEBA BÁSICA
pgbench -n -U postgres -h 127.0.0.1 -p 5432  -c 500 -j 20 -T 1800 db_prueba

# PRUEBA PERSONALIZADA
pgbench -n -U postgres -h 127.0.0.1 -p 5432  -c 500 -j 20 -t 10000 db_prueba -f script.sql



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
  -b, --builtin=NAME[@W]   add builtin script NAME weighted at W (default: 1)
                           (use "-b list" to list available scripts)
  -f, --file=FILENAME[@W]  add script FILENAME weighted at W (default: 1)
  -N, --skip-some-updates  skip updates of pgbench_tellers and pgbench_branches
                           (same as "-b simple-update")
  -S, --select-only        perform SELECT-only transactions
                           (same as "-b select-only")

Benchmarking options:
  -c, --client=NUM         number of concurrent database clients (default: 1)
  -C, --connect            establish new connection for each transaction
  -D, --define=VARNAME=VALUE
                           define variable for use by custom script
  -j, --jobs=NUM           number of threads (default: 1)
  -l, --log                write transaction times to log file
  -L, --latency-limit=NUM  count transactions lasting more than NUM ms as late
  -M, --protocol=simple|extended|prepared
                           protocol for submitting queries (default: simple)
  -n, --no-vacuum          do not run VACUUM before tests
  -P, --progress=NUM       show thread progress report every NUM seconds
  -r, --report-per-command report latencies, failures, and retries per command
  -R, --rate=NUM           target rate in transactions per second
  -s, --scale=NUM          report this scale factor in output
  -t, --transactions=NUM   number of transactions each client runs (default: 10)
  -T, --time=NUM           duration of benchmark test in seconds
  -v, --vacuum-all         vacuum all four standard tables before tests
  --aggregate-interval=NUM aggregate data over NUM seconds
  --failures-detailed      report the failures grouped by basic types
  --log-prefix=PREFIX      prefix for transaction time log file
                           (default: "pgbench_log")
  --max-tries=NUM          max number of tries to run transaction (default: 1)
  --progress-timestamp     use Unix epoch timestamps for progress
  --random-seed=SEED       set random seed ("time", "rand", integer)
  --sampling-rate=NUM      fraction of transactions to log (e.g., 0.01 for 1%)
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
https://www.postgresql.org/docs/current/pgbench.html
https://medium.com/@c.ucanefe/pgbench-load-test-166bdfb5c75a
https://juantrucupei.wordpress.com/2017/11/30/uso-de-pgbench-para-pruebas-stress-postgresql/
 ```

#  MONITOREAR ERRORES EN ARCHIVOS IMPORTANTES
 ```SQL 
select  'select * from '||specific_schema|| '.' || routine_name || '() limit 1;' from information_schema.routines where specific_name ilike '%stat%' group by routine_name, specific_schema  ;


select 'select * from '||table_schema || '.'|| table_name || ' limit 1 ;'from information_schema.tables where table_name ilike '%stat%'
group by table_name,table_schema;



-- archivo postgresql.conf - valida en tiempo real si  hay errores 
select * from pg_catalog.pg_file_settings where error is not null; 
select * from pg_show_all_file_settings() where error is not null;

select *from pg_settings  ; 
select * from pg_show_all_settings() where pending_restart != 'f';

 

-- archivo pg_hba 
select * from pg_catalog.pg_reload_conf() ; -- hacer un reload 

select * from pg_catalog.pg_hba_file_rules() limit 1; 
select * from pg_catalog.pg_hba_file_rules where error is not null;
 

---- ident - valida en tiempo real  
select * from pg_catalog.pg_ident_file_mappings where error is not null;


--- extras 
select * from pg_catalog.pg_db_role_setting ;


--- monitoreo 
select * from pg_catalog.pg_stat_database_conflicts limit 10 ;
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
insert into test (select generate_series(1,10000000), ‘name-‘||generate_series(1,10000000), now() + interval ‘1’ minute);
explain analyze select * from test where id > 100 and id <= 150;

 ```





#  LLVM en PostgreSQL
 ```sql
El paquete LLVM para PostgreSQL se utiliza principalmente para habilitar 
la compilación Just-In-Time (JIT) de consultas. Aquí te explico en detalle:

### ¿Qué es LLVM en PostgreSQL?

LLVM (Low-Level Virtual Machine) es un conjunto de herramientas de compilación que
 permite la optimización y generación de código en tiempo de ejecución. En PostgreSQL,
 LLVM se utiliza para la compilación JIT de ciertas consultas SQL, lo que puede mejorar significativamente el rendimiento de las consultas que son intensivas en CPU¹.

### Ventajas de usar LLVM en PostgreSQL

1. **Mejora del rendimiento**: La compilación JIT puede acelerar las consultas SQL al 
convertir el código interpretado en código nativo optimizado. Esto es especialmente útil para consultas complejas y repetitivas¹.
2. **Optimización dinámica**: LLVM permite optimizaciones en tiempo de ejecución, 
lo que significa que puede adaptar el código generado a las condiciones específicas de la consulta y el entorno².
3. **Reducción de la latencia**: Al compilar partes de la consulta en código nativo, 
se reduce el tiempo de ejecución, lo que puede ser crucial para aplicaciones que requieren respuestas rápidas².

### Desventajas de usar LLVM en PostgreSQL

1. **Sobrecarga inicial**: La compilación JIT introduce una sobrecarga inicial, ya que
 el código debe ser compilado antes de ser ejecutado. Esto puede no ser beneficioso para consultas simples o de corta duración².
2. **Complejidad adicional**: Habilitar y configurar LLVM puede añadir complejidad al 
sistema de base de datos, lo que puede requerir conocimientos adicionales y ajustes finos¹.
3. **Uso de recursos**: La compilación JIT puede consumir más recursos del sistema, 
como CPU y memoria, lo que podría afectar el rendimiento general si no se gestiona adecuadamente².

### ¿Cuándo usar LLVM en PostgreSQL?

- **Consultas intensivas en CPU**: Si tienes consultas que realizan muchas operaciones 
aritméticas o de procesamiento de datos, la compilación JIT puede ofrecer mejoras significativas.
- **Consultas repetitivas**: Para consultas que se ejecutan frecuentemente, la sobrecarga 
inicial de la compilación JIT se amortiza con el tiempo, resultando en un rendimiento mejorado.
- **Entornos de alto rendimiento**: En aplicaciones donde el rendimiento es crítico, como 
en análisis de datos en tiempo real, la compilación JIT puede ser muy beneficiosa.

 

 ```




 

### ¿Qué es HOT?

HOT (Heap-Only Tuple) es una técnica que permite realizar actualizaciones en las filas de una tabla sin necesidad de modificar los índices asociados a esas filas. Esto es posible cuando:

1. **No se modifican las columnas indexadas**: La actualización no afecta a ninguna columna que esté referenciada por un índice.
2. **Espacio libre en la página**: Hay suficiente espacio libre en la página que contiene la fila original para almacenar la nueva versión de la fila⁴.

### ¿Cómo se usa HOT?

Para aprovechar la técnica HOT, PostgreSQL realiza las siguientes optimizaciones:

1. **Evita nuevas entradas en los índices**: Cuando se actualiza una fila y se cumplen las condiciones mencionadas, no se crean nuevas entradas en los índices. Esto reduce significativamente el costo de las actualizaciones.
2. **Elimina versiones antiguas**: Las versiones antiguas de las filas actualizadas pueden ser eliminadas durante las operaciones normales, sin necesidad de operaciones de vacuum periódicas⁴.

### Beneficios de HOT

- **Mejora el rendimiento**: Al reducir la necesidad de actualizar los índices, las operaciones de actualización son más rápidas y eficientes.
- **Menor fragmentación**: Al eliminar las versiones antiguas de las filas de manera más eficiente, se reduce la fragmentación de las tablas.

### Ejemplo de uso

Para aumentar la probabilidad de que las actualizaciones sean HOT, puedes ajustar el parámetro `fillfactor` de una tabla. Este parámetro determina el porcentaje de espacio que se deja libre en cada página para futuras actualizaciones.

```sql
CREATE TABLE ejemplo (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    descripcion TEXT
) WITH (fillfactor = 70);

ALTER TABLE mi_tabla SET (fillfactor = 70);

```
 

### Desventajas de la técnica HOT

Aunque la técnica HOT (Heap-Only Tuple) ofrece varias ventajas, también tiene algunas desventajas:

1. **Limitaciones en las actualizaciones**: HOT solo se puede utilizar cuando las columnas actualizadas no están indexadas. Si necesitas actualizar columnas que están indexadas, no podrás beneficiarte de HOT¹.
2. **Espacio en la página**: Para que HOT funcione, debe haber suficiente espacio libre en la página que contiene la fila original. Si las páginas están llenas, las actualizaciones no podrán aprovechar HOT¹.
3. **Complejidad en el mantenimiento**: Aunque HOT reduce la necesidad de operaciones de vacuum, aún es necesario realizar mantenimiento periódico para evitar la acumulación de versiones antiguas de filas².

### Cuándo usar HOT

HOT es especialmente útil en los siguientes escenarios:

- **Actualizaciones frecuentes**: Si tu aplicación realiza muchas actualizaciones en columnas no indexadas, HOT puede mejorar significativamente el rendimiento.
- **Tablas grandes**: En tablas con muchas filas, HOT puede reducir la sobrecarga de las actualizaciones al evitar la creación de nuevas entradas en los índices.
- **Espacio libre en páginas**: Si puedes ajustar el `fillfactor` para dejar espacio libre en las páginas, aumentarás la probabilidad de que las actualizaciones sean HOT.

### Cuándo no usar HOT

Evita depender de HOT en los siguientes casos:

- **Actualizaciones en columnas indexadas**: Si necesitas actualizar columnas que están indexadas, HOT no será aplicable.
- **Páginas llenas**: Si las páginas de tus tablas están constantemente llenas, HOT no podrá ser utilizado de manera efectiva.
- **Requerimientos de rendimiento específicos**: En algunos casos, la complejidad añadida de gestionar HOT puede no justificar los beneficios, especialmente si las actualizaciones son poco frecuentes.
 






 
# **Stats target**
El parámetro **Stats target** define el número de muestras que PostgreSQL toma para generar estadísticas sobre una columna. Estas estadísticas son cruciales para que el optimizador de consultas elija el plan de ejecución más eficiente. Puedes ajustar este parámetro para mejorar el rendimiento de las consultas:

- **Valor por defecto**: 100
- **Rango**: 0 a 10,000¹
 
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
 /usr/pgsql-15/bin/postgres  --single  -D /sysx/data -F -c exit_on_error=true postgres < /path/to/recovery_script.sql 

# conectarte y ejceutar comandos 
[postgres@TEST_SERVER data15]$  /usr/pgsql-15/bin/postgres  --single  -D /sysx/data  -F -c exit_on_error=true postgres

PostgreSQL stand-alone backend 15.8
backend> select version();
<2024-11-15 13:11:09 MST     2724619 6737aad9.29930b >LOG:  statement: select version();

         1: version     (typeid = 25, len = -1, typmod = -1, byval = f)
        ----
         1: version = "PostgreSQL 15.8 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit" (typeid = 25, len = -1, typmod = -1, byval = f)
        ----
<2024-11-15 13:11:09 MST     2724619 6737aad9.29930b >LOG:  duration: 1.493 ms
backend>
```
 
https://postgresconf.org/system/events/document/000/002/232/Troubleshoot_PG_Perf-04172024.pdf
