### Conceptos : 
**`La caché`** es un área de almacenamiento temporal que se utiliza para guardar datos que se acceden con frecuencia. Su objetivo principal es mejorar la velocidad y eficiencia del acceso a esos datos. Al almacenar información en la caché, los sistemas pueden recuperar datos rápidamente sin tener que acceder a la fuente original, que puede ser más lenta.



### **1. ¿Cómo funciona el caché en PostgreSQL?**
PostgreSQL usa dos capas de caché:
- **Buffer cache de PostgreSQL (`shared_buffers`)**: Memoria RAM reservada para almacenar bloques de datos e índices.
- **Caché del sistema operativo (OS cache)**: Memoria que el SO usa para almacenar archivos accedidos recientemente, incluyendo los archivos de datos de PostgreSQL.

Cuando ejecutas una consulta:
1. PostgreSQL busca los datos en `shared_buffers`.
2. Si no están allí, los lee del disco, pero el SO puede guardarlos en su caché.
3. En consultas posteriores:
   - Si los datos siguen en `shared_buffers` (u OS cache), se accede rápidamente.
   - Si han sido desplazados por otros datos (por falta de espacio), se leen de nuevo del disco
   
 


### 1. **Caching en el Sistema Operativo**
   - **Cache de disco (Page Cache):** Cuando se accede a datos por primera vez, el sistema operativo tiene que leerlos desde el disco, lo cual es un proceso lento. Sin embargo, una vez que esos datos se han leído, el sistema operativo suele mantenerlos en la memoria (`page cache`), de modo que las subsecuentes lecturas de los mismos datos no requieren acceso a disco y son mucho más rápidas. Este es uno de los factores clave que hace que las consultas repetidas sean más rápidas.

### 2. **Cache de PostgreSQL**
   - **Shared Buffers:** PostgreSQL tiene su propia memoria RAM de caché interna llamada "shared buffers". Cuando ejecutas una consulta, PostgreSQL almacena en esta caché las páginas de datos y los índices que ha utilizado. En las ejecuciones posteriores de la consulta, si los datos ya están en `shared buffers`, se pueden acceder directamente desde la memoria, sin necesidad de realizar costosas operaciones de lectura de disco.
   - **Cache de planificación:** PostgreSQL también puede almacenar en caché ciertos planes de ejecución para consultas preparadas o consultas parametrizadas. Si una consulta idéntica se ejecuta nuevamente, PostgreSQL puede reutilizar el plan de ejecución almacenado en caché, evitando la necesidad de recompilarlo, lo cual ahorra tiempo.

```SQL
### Usos de la Memoria Compartida en PostgreSQL

1. **Buffers Compartidos (shared_buffers)**:
   - **Objetivo**: Almacenar en memoria RAM en caché los datos más frecuentemente accedidos para reducir el número de lecturas y escrituras en disco.
   - **Beneficio**: Mejora el rendimiento al disminuir la latencia de acceso a los datos.

2. **Memoria para Locks (lock tables)**:
   - **Objetivo**: Gestionar los bloqueos de las tablas y filas para asegurar la consistencia y la integridad de los datos durante las transacciones concurrentes.
   - **Beneficio**: Permite que múltiples transacciones se ejecuten de manera segura sin interferencias.

3. **Estructuras de Control de Procesos (process control structures)**:
   - **Objetivo**: Mantener información sobre los procesos y las conexiones activas.
   - **Beneficio**: Facilita la coordinación y la comunicación entre los diferentes procesos del servidor PostgreSQL.

4. **Memoria para el Sistema de Registro de Transacciones (WAL buffers)**:
   - **Objetivo**: Almacenar temporalmente los registros de transacciones antes de escribirlos en el disco.
   - **Beneficio**: Aumenta la eficiencia de las operaciones de escritura y mejora la recuperación en caso de fallos.
 ```

### 3. **Warmup de Índices**
   - **Acceso a índices:** La primera vez que se consulta una tabla, PostgreSQL puede necesitar cargar los índices correspondientes en memoria para utilizarlos en la consulta. Una vez que los índices están cargados en la caché, las futuras consultas que requieran esos índices se beneficiarán del acceso más rápido.

### 4. **Autovacuum y Estadísticas**
   - **Recolección de estadísticas:** Durante las primeras ejecuciones, PostgreSQL puede realizar operaciones de recolección de estadísticas (como las ejecutadas por `ANALYZE`), lo que podría añadir un pequeño retraso inicial. Una vez que las estadísticas están actualizadas, PostgreSQL puede optimizar mejor las futuras consultas, lo que se traduce en un rendimiento más rápido.

### 5. **Compilación de Expresiones**
   - **Compilación de expresiones y funciones:** PostgreSQL puede compilar ciertas expresiones o funciones la primera vez que se utilizan en una consulta. En ejecuciones posteriores, las versiones compiladas de estas expresiones pueden ser reutilizadas, lo que reduce el tiempo de procesamiento.

### 6. **Cache de Procedimientos y Funciones**
   - **Procedimientos almacenados y funciones:** Si estás utilizando procedimientos almacenados o funciones, la primera ejecución podría involucrar cierta inicialización que ya no es necesaria en futuras ejecuciones, haciéndolas más rápidas.

### 7. **Impacto del Plan de Ejecución**
   - **Reutilización de planes de ejecución:** En algunas situaciones, PostgreSQL puede reutilizar un plan de ejecución previamente generado si considera que sigue siendo óptimo para la consulta repetida. Esto ahorra el tiempo que se emplearía en la optimización de la consulta.

### 8. **Optimización del Sistema Operativo y Hardware**
   - **Efecto de la RAM y CPU:** Si el sistema tiene suficiente memoria RAM, más datos y procesos pueden mantenerse en memoria, lo que reduce el acceso a disco y mejora el rendimiento de las consultas repetidas. Además, los cálculos realizados por la CPU pueden ser más rápidos al usar cachés internas del procesador que aprovechan las instrucciones previamente ejecutadas.


 --- 
PostgreSQL utiliza varios tipos de memoria para diferentes propósitos a lo largo de su funcionamiento. Cada tipo de memoria está diseñada para manejar distintos aspectos del procesamiento de consultas, manejo de datos, y optimización del rendimiento. Aquí te detallo los principales tipos de memoria utilizados por PostgreSQL y cuándo se usan:

### 1. **Shared Buffers**
   - **Descripción:** Es la memoria RAM compartida donde PostgreSQL almacena las páginas de datos e índices que se utilizan con frecuencia. Esta memoria es común para todas las conexiones y es gestionada de manera centralizada.
   - **Uso:** Cuando una consulta accede a datos de una tabla o un índice, PostgreSQL primero busca esos datos en los `shared buffers`. Si los datos no están allí, se leen desde el disco y se almacenan en los `shared buffers` para futuras consultas. Esto reduce el tiempo de acceso a disco en operaciones subsecuentes.

### 2. **WAL Buffers**
   - **Descripción:** Es un área de memoria donde PostgreSQL almacena temporalmente los registros del Write-Ahead Logging (WAL) antes de escribirlos en el disco.
   - **Uso:** Durante una transacción, cuando se realizan cambios en la base de datos, PostgreSQL genera registros WAL que describen esos cambios. Estos registros primero se colocan en los `WAL buffers` antes de ser escritos en los archivos WAL en disco. El uso de estos buffers optimiza el rendimiento al permitir que varios cambios se acumulen en la memoria antes de ser escritos de una sola vez.

### 3. **Work_mem**
   - **Descripción:** Es la memoria utilizada para operaciones de consulta específicas, como ordenamientos (`sorts`), operaciones de hash, y merges de joins. Cada operación puede utilizar hasta la cantidad de memoria especificada por el parámetro `work_mem`.
   - **Uso:** Durante la ejecución de consultas que requieren ordenar grandes conjuntos de datos o realizar operaciones de agrupamiento o unión, PostgreSQL asigna memoria de `work_mem` para esas operaciones. Si el tamaño de los datos excede el valor de `work_mem`, PostgreSQL utilizará almacenamiento temporal en disco, lo que puede ralentizar la operación.

### 4. **Maintenance_work_mem**
   - **Descripción:** Es una memoria dedicada a tareas de mantenimiento, como la creación de índices, el autovacuum, y la recolección de estadísticas.
   - **Uso:** Durante operaciones de mantenimiento como `VACUUM`, `ANALYZE`, o la creación de índices, PostgreSQL utiliza esta memoria para optimizar dichas operaciones. Al asignar más memoria a `maintenance_work_mem`, estas tareas pueden completarse más rápidamente.

### 5. **Temp_buffers**
   - **Descripción:** Es la memoria dedicada a almacenar temporalmente datos de tablas temporales durante una sesión de base de datos.
   - **Uso:** Cuando una consulta utiliza tablas temporales (creadas con `CREATE TEMPORARY TABLE`), PostgreSQL almacena los datos de esas tablas en `temp_buffers`. Esto permite un acceso rápido y evita escribir inmediatamente esos datos en disco, a menos que se exceda la memoria asignada.

### 6. **Temp File Storage**
   - **Descripción:** Aunque no es un tipo de memoria en sí, es importante mencionar el uso de archivos temporales en disco que actúan como extensión de la memoria cuando ciertas operaciones exceden los límites de `work_mem` o `temp_buffers`.
   - **Uso:** Si una operación como un ordenamiento o una operación hash necesita más memoria de la disponible en `work_mem`, PostgreSQL crea archivos temporales en el disco para manejar el exceso de datos. Estos archivos se eliminan automáticamente una vez completada la operación.

### 7. **Cache del Sistema Operativo (Page Cache)**
   - **Descripción:** Esta es la memoria utilizada por el sistema operativo para almacenar en caché los datos que se leen desde el disco. Aunque no es gestionada directamente por PostgreSQL, juega un papel crucial en el rendimiento general de la base de datos.
   - **Uso:** Cuando PostgreSQL accede a los datos en disco, el sistema operativo puede mantener una copia de esos datos en su `page cache`. Las futuras lecturas de esos datos pueden ser servidas directamente desde la memoria del sistema operativo, evitando el acceso físico al disco.

### 8. **Memory Contexts**
   - **Descripción:** PostgreSQL maneja múltiples contextos de memoria para gestionar eficientemente la asignación y liberación de memoria a lo largo del ciclo de vida de una consulta o proceso. Cada contexto de memoria es un grupo de memoria usado para diferentes propósitos dentro de una conexión o proceso en PostgreSQL.
   - **Uso:** Durante la ejecución de una consulta, PostgreSQL puede crear varios contextos de memoria para almacenar datos temporales, resultados intermedios, o información estructural como planes de consulta. Estos contextos ayudan a gestionar la memoria de manera eficiente y a liberar todos los recursos una vez que ya no son necesarios.

### 9. **Session Memory (Backend Memory)**
   - **Descripción:** Cada conexión de cliente (backend) en PostgreSQL tiene su propia memoria privada que se usa para manejar variables de sesión, almacenamiento temporal y el estado de la sesión.
   - **Uso:** Esta memoria se utiliza para gestionar aspectos específicos de la sesión de un usuario, como el manejo de variables de entorno de la sesión, caché de resultados de funciones, o el almacenamiento de resultados intermedios que no se compartirán entre otras conexiones.
 
# Monitoreo de buffer

La caché de búfer almacena datos en la memoria para acelerar las consultas. Si la caché está bien optimizada, las consultas se ejecutarán más rápido al evitar accesos frecuentes al disco.

```SQL

--- consulta para obtener las tablas con mayor uso de la buffer cache, junto con su tamaño en caché y su tamaño total en disco
--- 3. **Bloques de 8 kB**: PostgreSQL divide los datos en bloques de 8 kB. `COUNT(*) * 8192` calcula el espacio usado en la caché.

SELECT
    n.nspname AS schema_name
    ,c.relname AS table_name
    ,pg_size_pretty(COUNT(*) * 8192) AS buffer_size -- Tamaño en caché (legible)
    --,COUNT(*) * 8192 AS buffer_bytes                -- Tamaño en bytes
    ,pg_size_pretty(pg_relation_size(c.oid)) AS total_size_on_disk -- Tamaño en disco (legible)
    --,pg_relation_size(c.oid) AS total_bytes_on_disk  -- Tamaño en bytes
    --,ROUND((COUNT(*) * 8192 * 100.0) / pg_relation_size(c.oid), 2) AS cache_percent  -- porcentaje de la tabla en caché
FROM
    pg_buffercache b
JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE
    b.reldatabase = (SELECT oid FROM pg_database WHERE datname = current_database())
    AND c.relkind = 'r' -- Solo tablas (excluye índices, vistas, etc.)
GROUP BY
    n.nspname, c.relname, c.oid
ORDER BY
    pg_relation_size(c.oid) DESC
	limit 10;
	
	
 ----------------------------------------------------

bufferid: ID del búfer.
relfilenode: Número de nodo de archivo de la relación.
reltablespace: OID del espacio de tabla de la relación.
reldatabase: OID de la base de datos de la relación.
relforknumber: Número de bifurcación dentro de la relación.
relblocknumber: Número de página dentro de la relación.
isdirty: ¿Está sucia la página? (true/false).
usagecount: Recuento de acceso de barrido de reloj.
pinning_backends: Número de backends que fijan este búfe


 --- Ejemplo 1: Ver el estado completo de la caché de búfer
		SELECT * FROM pg_buffercache LIMIT 10;
		 
		
		
		-- Ejemplo 2: Contar la cantidad de búferes usados por cada relación 
		SELECT c.relname, count(*) AS buffers
		FROM pg_buffercache b
		JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
		GROUP BY c.relname
		ORDER BY buffers DESC;

--- Ejemplo 3: Verificar si hay páginas sucias en la caché
SELECT count(*) AS dirty_buffers
FROM pg_buffercache
WHERE isdirty;

--- Ejemplo 4: Obtener el recuento de búferes según su contador de uso
SELECT usagecount, count(*) AS buffers
FROM pg_buffercache
GROUP BY usagecount
ORDER BY usagecount;


--- Ejemplo 5: Resumen del estado de la caché de búfer
SELECT * FROM pg_buffercache_summary();

--- 
select * from  public.pg_buffercache_usage_counts()


----
SELECT current_database() as db_name, n.nspname, c.relname, count(*) AS buffers
             FROM pg_buffercache b JOIN pg_class c
             ON b.relfilenode = pg_relation_filenode(c.oid) AND
                b.reldatabase IN (0, (SELECT oid FROM pg_database
                                      WHERE datname = current_database()))
             JOIN pg_namespace n ON n.oid = c.relnamespace and n.nspname ='public'
             GROUP BY n.nspname, c.relname
             ORDER BY 4 DESC
             LIMIT 10;
 
			 
https://medium.com/@dmitry.romanoff/optimizing-postgresql-buffer-cache-automating-analysis-with-a-bash-script-2afd7b9da508


------------

https://www.metisdata.io/blog/debugging-low-cache-hit-ratio

SELECT
    	c.relname,
    	pg_size_pretty(count(*) * 8192) as buffered,
    	round(100.0 * count(*) / ( SELECT setting FROM pg_settings WHERE name='shared_buffers')::integer,1) AS buffers_percent,
    	round(100.0 * count(*) * 8192 / pg_relation_size(c.oid),1) AS percent_of_relation
FROM pg_class c
INNER JOIN pg_buffercache b ON b.relfilenode = c.relfilenode
INNER JOIN pg_database d ON (b.reldatabase = d.oid AND d.datname = current_database())
WHERE pg_relation_size(c.oid) > 0
GROUP BY c.oid, c.relname
ORDER BY 3 DESC
LIMIT 10;



```



 
1. **`select * from pg_stat_io;`**
   - **Descripción:** Esta vista ofrece estadísticas sobre las operaciones de entrada/salida (I/O) realizadas por las consultas en la base de datos. Te permite monitorear el rendimiento de las consultas en términos de I/O.

2. **`select * from pg_stat_archiver;`**
   - **Descripción:** Esta vista proporciona información sobre la actividad del proceso de archivado en PostgreSQL. Te permite monitorear el estado del archiver, como la cantidad de archivos de WAL archivados y cualquier error que haya ocurrido durante el proceso de archivado.

3. **`select * from pg_stat_bgwriter;`**
   - **Descripción:** Esta vista ofrece estadísticas sobre la actividad del proceso de escritura en segundo plano (background writer). Te permite monitorear el rendimiento del escritor en segundo plano, como la cantidad de buffers escritos, el tiempo dedicado a escribir, y otros aspectos relacionados.

4. **`select * from pg_backend_memory_contexts;`**
   - **Descripción:** Esta vista proporciona información sobre el uso de memoria por parte de los procesos en segundo plano de PostgreSQL. Te permite monitorear cómo se está utilizando la memoria y detectar posibles problemas de memoria en la base de datos.

5. **`select * from pg_shmem_allocations;`**
   - **Descripción:** Esta vista ofrece información sobre las asignaciones de memoria compartida en PostgreSQL. Te permite monitorear cómo se está utilizando la memoria compartida y asegurarte de que los recursos de memoria se están gestionando adecuadamente.



 
