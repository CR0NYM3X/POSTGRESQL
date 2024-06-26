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

# Ejemplos de uso:

<!--  ################################################################### MONITOREO #################################################################################### -->
---
$$ 
MONITOREO 
$$


## Consulta todo en una sola query:
```sh
echo "IP" && hostname -I && postgres --version && echo "Numero máximo de conexiones" && psql -At -c "show max_connections;" && echo "Numero de conexiones" && ps -ef | grep -i postgres -wc  && echo "Numero de conexiones en idle" &&  ps -ef | grep -i idle -wc && echo "Unidades" && df -lh&& echo "Mostrar BD Postgres " && psql postgres -c "\\l+" && echo " -- Fecha" && date && echo " -- Mostrar procesos" && psql -xc "select  query,pid,datname,usename,client_addr,query_start,state,application_name,CAST((now()-query_start) as varchar(8)) as time_run, state FROM pg_stat_activity WHERE query != '<IDLE>' AND TRIM(state)!='idle' ORDER BY query_start ASC;"
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

2. Ver las conexiones **`activas`** y identificar cual esta generando bloques en base al tiempo que tiene ejecutandose, y cerrar la conexión con el PID:
```sh
 psql -xc  "select  query,pid,datname,usename,client_addr,query_start,state,application_name,CAST((now()-query_start) as varchar(8)) as time_run, state FROM pg_stat_activity WHERE query != '<IDLE>' AND TRIM(state)!='idle' and usename != 'postgres' ORDER BY query_start ASC;"
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




## Buscar bloqueos 
select    l.mode AS bloqueo_modo,  l.granted AS concedido,  l.pid AS proceso_id,  a.usename AS usuario,  l.relation::regclass AS tabla,  l.page AS pagina,  l.tuple AS tupla FROM  pg_locks l JOIN   pg_stat_activity a ON l.pid = a.pid WHERE   NOT l.granted;




## Mostrar el tiempo de ejecucion de una consulta en el momento
EXPLAIN select  version();  <br>
EXPLAIN ANALYZE  select  version();



## Todos los stat para monitorear 
```sh

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
 select  * from  pg_stat_archiver;
 select  * from  pg_stat_bgwriter;
 select  * from  pg_stat_monitor;
 select  * from  pg_statistic;
 select  * from  pg_statistic_ext;
 select  * from  pg_stats;
 select  * from  pg_prepared_statements;
 select  * from  pg_stat_subscription;
 select  * from  pg_stat_ssl;


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


## Vacum [documentación Oficial](https://www.postgresql.org/docs/current/sql-vacuum.html)

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
example=# \dt+
                          List of relations
 Schema |       Name       | Type  |  Owner   |  Size   | Description 
--------+------------------+-------+----------+---------+-------------
 public | pgbench_accounts | table | postgres | 641 MB  | 
 public | pgbench_branches | table | postgres | 40 kB   | 
 public | pgbench_history  | table | postgres | 0 bytes | 
 public | pgbench_tellers  | table | postgres | 56 kB   | 
(4 rows)

  createdb testdb
 pgbench -U postgres -h 127.0.0.1 -i -s 70 prueba
 pgbench -U postgres - h127.0.0.1 -p 5432  -c 500 -j 20 -T 1800 prueba

  
  pgbench -i -s <escala> testdb
    - -i: Esta opción indica a pgbench que inicialice la base de datos con datos de prueba.
    -s <escala>: Esta opción determina la escala de los datos generados. La escala indica el factor multiplicativo en relación con el tamaño predeterminado de la base de datos. Por ejemplo, -s 10 generará datos de prueba diez veces más grandes que el tamaño predeterminado.

pgbench -c <clientes> -j <hilos> -T <tiempo> testdb
    -c <clientes>: Esta opción especifica el número de clientes simultáneos que se simularán durante la prueba.
    -j <hilos>: Esta opción especifica el número de hilos (o conexiones) a utilizar.
    -T <tiempo>: Esta opción especifica la duración de la prueba en segundos.
    -t  Number of transactions each client runs. Default is 10.

-------- BIBLIOGRAFÍAS ---------------
https://www.postgresql.org/docs/current/pgbench.html
https://medium.com/@c.ucanefe/pgbench-load-test-166bdfb5c75a
https://juantrucupei.wordpress.com/2017/11/30/uso-de-pgbench-para-pruebas-stress-postgresql/
 ```
