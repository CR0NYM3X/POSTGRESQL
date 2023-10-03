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

1 .- Verificar el estatus del servidor y DBA <br>
2 .- Validar tamaños de los discos duros <br>
3 .- Monitorear el procesador y la memoria Ram  <br>
4 .- Validar maximo de conexiones y cuantas conexiones hay en ese momento y eliminar consultas bloqueadas <br>
5 .- Verificar el tiempo que tiene encendido el servidor <br>
6 .- realizar Reindexacion , vacum full  en caso de requerirse <br>
7 .- Ver el tamaño de las base de datos y tablas y tratar de optimizar como la db y tb <br>
8 .- Validar los tiempo de ejecucion de una query y compararlos con dias anteriores  <br>



**`Optimización de consultas lentas:`**
Caso: Un sistema de comercio electrónico tiene consultas que están tomando mucho tiempo en ejecutarse, lo que afecta el rendimiento del sitio web.
Solución: Utiliza herramientas como EXPLAIN y EXPLAIN ANALYZE para analizar el plan de ejecución de las consultas lentas. Identifica cuellos de botella, utiliza índices adecuados, ajusta las consultas y, si es necesario, considera denormalizar la estructura de datos para mejorar el rendimiento.

**`Recuperación después de fallos:`**
Caso: La base de datos experimenta un fallo en el disco, lo que resulta en la corrupción de algunos archivos.
Solución: Usa la herramienta pg_resetxlog para intentar recuperar la base de datos a un estado consistente. Si esto no funciona, restaura una copia de seguridad y aplica los registros de transacciones (WAL logs) para llevar la base de datos al estado más actualizado posible.

**`Gestión de espacio en disco:`**
Caso: El espacio en disco disponible para la base de datos se está agotando rápidamente.
Solución: es una herramienta externa que ayuda a optimizar y reorganizar las tablas en una base de datos PostgreSQL sin bloquear la tabla para operaciones DML (Data Manipulation Language) durante un tiempo significativo. para evitar llenar el disco con archivos de registro innecesarios. ---> pg_repack [opciones] nombre_base_de_datos --table: Permite especificar una tabla específica para ser reorganizada.  --no-order: Realiza la reorganización sin tratar de ordenar las filas. --quiet: Ejecuta pg_repack en modo silencioso.

**`Copias de seguridad y restauración:`**
Caso: Se necesita realizar una copia de seguridad completa y restaurar la base de datos en caso de pérdida de datos.
Solución: Emplea herramientas como pg_dump para realizar copias de seguridad y pg_restore para restaurar la base de datos. Configura una estrategia de copia de seguridad regular y verifica la capacidad de restaurar desde las copias de seguridad en un entorno de prueba.

**`Monitoreo de rendimiento en tiempo real:`**
Caso: Se requiere supervisar el rendimiento de la base de datos en tiempo real para detectar problemas rápidamente.
Solución: Utiliza herramientas como pg_stat_statements para analizar el rendimiento de las consultas, y herramientas de monitoreo como pg_stat_monitor o soluciones de terceros como pgAdmin para obtener métricas en tiempo real sobre el rendimiento y la actividad de la base de datos.

**`Resolución de bloqueos y conflictos:`**
Caso: Los usuarios informan de bloqueos y conflictos al intentar acceder a ciertos registros simultáneamente.
Solución: Utiliza las vistas pg_locks y pg_stat_activity para identificar los bloqueos actuales y las transacciones en conflicto. Luego, usa técnicas como aumentar el nivel de aislamiento de transacción o reescribir consultas para evitar bloqueos.



# Ejemplos de uso:



## Consulta todo en una sola query:
```sh
echo "IP" && hostname -I && postgres --version && echo "Numero máximo de conexiones" && psql -At -c "show max_connections;" && echo "Numero de conexiones" && ps -ef | grep -i postgres -wc  && echo "Numero de conexiones en idle" &&  ps -ef | grep -i idle -wc && echo "Unidades" && df -lh&& echo "Mostrar BD Postgres " && psql postgres -c "\\l+" && echo " -- Fecha" && date && echo " -- Mostrar procesos" && psql -xc "SELECT query,pid,datname,usename,client_addr,query_start,state,application_name,CAST((now()-query_start) as varchar(8)) as time_run, state FROM pg_stat_activity WHERE query != '<IDLE>' AND TRIM(state)!='idle' ORDER BY query_start ASC;"
```

## Ver el estatus de postgresql 
```sh
systemctl status postgresql  
service postgresql status 
pg_isready 
ps aux | grep postgres
ps aux | grep data -- este te sirve para saber que binarios esta utilizando 
```

## Vacum
VACUUM FULL;  -->  liberar espacio en disco ocupado por registros eliminados y para prevenir la fragmentación. 
VACUUM ANALYZE;

## Reindex
REINDEX DATABASE $DB_NAME;
REINDEX TABLE nombre_de_tabla;


ANALYZE; ---> actualizar las estadísticas de la base de datos.
pg_repack -U $DB_USER -d $DB_NAME --> Esta herramienta se utiliza para reorganizar físicamente las tablas y sus índices, reduciendo la fragmentación y mejorando el rendimiento.
ALTER TABLE tabla_nombre SET (pg_prewarm.compress=true);



-- Muestra el tiempo de ejecucion de una consulta
EXPLAIN select version(); --  para analizar el plan de ejecución de una consulta
EXPLAIN ANALYZE  select version();


## Ver maximas conexiones que permite el postgresql
show max_connections; -- cat  /sysx/data/postgresql.conf | grep max_connections


## Buscar procesos trabados 

idle" se refiere a un estado en el que una conexión a la base de datos se encuentra inactiva. Esto significa que la conexión está establecida, pero no se está ejecutando ninguna consulta o transacción en ese momento. Las conexiones "idle" son comunes en entornos de bases de datos donde varios clientes se conectan y desconectan de la base de datos.

Es importante entender el concepto de conexiones "idle" en PostgreSQL porque pueden consumir recursos del sistema, como conexiones TCP/IP y memoria, incluso cuando no están realizando ninguna tarea activa. Por lo tanto, es fundamental administrar y controlar estas conexiones para evitar problemas de rendimiento y recursos agotados.


1. Configuración en postgresql.conf:

Puedes configurar el tiempo máximo que una conexión puede permanecer inactiva antes de ser terminada automáticamente. Esto se hace mediante el parámetro idle_in_transaction_session_timeout en el archivo de configuración postgresql.conf. Por ejemplo:

`idle_in_transaction_session_timeout = 60000  # 60 segundos (valor en milisegundos)`

psql -xc "SELECT query,pid,datname,usename,client_addr,query_start,state,application_name,CAST((now()-query_start) as varchar(8)) as time_run, state FROM pg_stat_activity WHERE query != '<IDLE>' AND TRIM(state)!='idle' ORDER BY query_start ASC;"

SELECT  count(*)  FROM pg_stat_activity where  current_query  !=  '<IDLE>' limit 5;

SELECT count(*) pid FROM pg_stat_activity WHERE query != '<IDLE>' AND TRIM(state)!='idle'; --> significa que la conexión está abierta pero no está realizando ninguna operación en ese momento.

## Buscar bloqueos 
SELECT   l.mode AS bloqueo_modo,  l.granted AS concedido,  l.pid AS proceso_id,  a.usename AS usuario,  l.relation::regclass AS tabla,  l.page AS pagina,  l.tuple AS tupla FROM  pg_locks l JOIN   pg_stat_activity a ON l.pid = a.pid WHERE   NOT l.granted;

## Cerrar procesos Trabados o IDLE

--- aqui  podemos ver los clientes  que estan conectados a db SAJ  desde linux
: ps -fea | grep MYDBA  

--cerrar los procesos con linux
 ps -ef | grep idle | awk '{print " kill " $2}' | bash 

--- aqui   podemos ver los clientes  que estan conectados a db SAJ  desde la base de datos 
select pid,client_addr, state  FROM pg_stat_activity WHERE pg_stat_activity.datname = 'merca360';

--cerrar los procesos con DBa
SELECT pg_terminate_backend (pg_stat_activity.pid) FROM pg_stat_activity WHERE  pg_stat_activity.datname = 'SAJ'; 






## Todos los stat para monitorear 
```sh
 pg_statistic
 pg_replication_origin_status
 pg_statio_all_indexes
 pg_statistic_ext
 pg_stats
 pg_prepared_statements
 pg_statio_sys_indexes
 pg_stat_all_tables
 pg_stat_xact_all_tables
 pg_stat_sys_tables
 pg_stat_xact_sys_tables
 
 --- Obtener información sobre el tamaño y estado de las tablas: 

SELECT schemaname || '.' || relname AS table_full_name,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) AS size,
       pg_size_pretty(pg_relation_size(schemaname || '.' || relname)) AS table_size,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname) - pg_relation_size(schemaname || '.' || relname)) AS index_size,
       pg_total_relation_size(schemaname || '.' || relname) - pg_relation_size(schemaname || '.' || relname) AS "index_overhead_bytes"
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname || '.' || relname) DESC;

 
 pg_stat_xact_user_tables
 pg_statio_all_tables
 pg_statio_sys_tables
 pg_statio_user_tables
 pg_stat_all_indexes
 pg_stat_sys_indexes
 pg_stat_user_indexes
 pg_statio_user_indexes
 pg_statio_all_sequences
 pg_statio_sys_sequences
 pg_statio_user_sequences
 pg_stat_activity
 pg_stat_get_activity
 pg_stat_replication
 pg_stat_wal_receiver
 pg_stat_subscription
 pg_stat_ssl
 

 -- Mostrar el tamaño y estadísticas de todas las bases de datos:

SELECT datname AS database_name,
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
FROM pg_stat_database;

 
 
 pg_stat_database_conflicts
 pg_stat_user_functions
 pg_stat_xact_user_functions
 pg_stat_archiver
 pg_stat_bgwriter
 pg_stat_progress_vacuum
pg_stat_monitor

Proporciona estadísticas sobre las consultas ejecutadas en la base de datos,  el número de veces que una consulta se ha ejecutado y el tiempo total que ha pasado en la caché. como tiempos de ejecución y frecuencia de uso. Ayuda a identificar consultas lentas o ineficientes para optimizar el rendimiento.

->   SELECT    total_exec_time, min_exec_time,max_exec_time ,calls FROM pg_stat_statements where query ilike '%select%' and not query ilike '%GRANT%' ORDER BY total_plan_time DESC, calls desc limit 10;  

SELECT query, calls, total_time, rows, mean_time FROM pg_stat_statements ORDER BY total_time DESC;


```



## Parametros del postgresql.conf para una buena optimización 
cat /sysx/data/postgresql.conf | grep -Ei "shared_buffers|effective_cache_size|work_mem|maintenance_work_mem|temp_buffers|max_connections" <br>

`shared_buffers:` Controla la cantidad de memoria compartida utilizada para almacenar bloques de datos en la caché. Es una configuración importante para mejorar el rendimiento. Puedes encontrarla en la sección de memoria.<br>

`effective_cache_size:` Indica cuánta memoria se espera que esté disponible para la caché en total, incluyendo la memoria compartida y la memoria del sistema operativo. También se encuentra en la sección de memoria.<br>

`work_mem y maintenance_work_mem:` Estas configuraciones controlan la cantidad de memoria asignada a operaciones de clasificación y mantenimiento respectivamente.<br>

`temp_buffers:` Define cuánta memoria se usa para operaciones temporales.<br>

`max_connections:` Limita el número máximo de conexiones simultáneas a la base de datos, lo que puede afectar la cantidad de memoria utilizada por las conexiones en caché.
