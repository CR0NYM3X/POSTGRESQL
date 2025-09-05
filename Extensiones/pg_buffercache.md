- **pg_buffercache**: Permite monitorear en tiempo real el uso del buffer cache para entender mejor cómo se está utilizando la memoria y ajustar configuraciones en consecuencia. La caché de búfer almacena datos en la memoria para acelerar las consultas. Si la caché está bien optimizada, las consultas se ejecutarán más rápido al evitar accesos frecuentes al disco. 


### 🔍 ¿Qué es el buffer en PostgreSQL?

El **buffer pool** es una zona de memoria compartida donde PostgreSQL almacena páginas de datos que han sido leídas desde disco. Esto permite que futuras lecturas sean más rápidas si los datos ya están en memoria.


 #  **descripción breve y clara de cada columna** 

| **Columna**           | **Descripción** |
|-----------------------|-----------------|
| `bufferid`            | Identificador único del búfer dentro del pool de búferes. |
| `relfilenode`         | Identificador del archivo físico que representa la relación (tabla o índice). |
| `reltablespace`       | ID del tablespace donde se encuentra la relación. |
| `reldatabase`         | ID de la base de datos a la que pertenece la relación. |
| `relforknumber`       | Tipo de fork del archivo: `main`, `fsm`, `vm`, etc. (por ejemplo, datos principales, mapa de espacio libre, mapa de visibilidad). |
| `relblocknumber`      | Número de bloque dentro del archivo de la relación. |
| `isdirty`             | Indica si el bloque ha sido modificado en memoria pero aún no se ha escrito al disco (`true` = sucio). |
| `usagecount`          | Contador de uso del búfer, usado por el algoritmo de reemplazo LRU para decidir qué páginas expulsar. |
| `pinning_backends`    | Número de procesos que actualmente tienen "fijado" el búfer, lo que impide que sea reemplazado. |


# **`isdirty`** 
indica si una página en el búfer ha sido modificada (es decir, está "sucia") pero **aún no ha sido escrita al disco**.

### ¿Qué significa esto en términos prácticos?

Cuando PostgreSQL modifica datos (por ejemplo, al hacer un `UPDATE` o `INSERT`), no escribe inmediatamente esos cambios al disco. En lugar de eso:

1. **Modifica la página en memoria (el búfer)**.
2. Marca esa página como **dirty** (`isdirty = true`).
3. Eventualmente, el proceso de **checkpoint** o el **background writer** escribe esa página al disco.

### ¿Para qué sirve `isdirty`?

Este campo es útil para:

- **Diagnóstico de rendimiento**: Si muchas páginas están sucias, puede indicar que hay muchas escrituras pendientes, lo cual podría afectar el rendimiento o la recuperación ante fallos.
- **Monitoreo de actividad**: Ayuda a entender qué tan activo está el sistema en términos de escritura.
- **Optimización de configuración**: Puede guiar ajustes en parámetros como `checkpoint_timeout`, `bgwriter_delay`, etc.

  


### 📦 ¿Qué hace `pg_buffercache`?

La extensión `pg_buffercache` te da acceso a una vista llamada `pg_buffercache`, que muestra:

- Qué páginas están actualmente en el buffer.
- A qué tabla o índice pertenecen.
- Cuántas veces han sido usadas.
- Si están sucias (modificadas pero no escritas a disco).


--- 

### ⏱️ ¿Es en tiempo real?

✅ **Sí.** Cada vez que consultas `pg_buffercache`, estás viendo el **estado actual del buffer en ese momento**.  
❌ **No guarda historial.** Si quieres ver cómo cambia con el tiempo, necesitas recolectar datos periódicamente (por ejemplo, con Prometheus o scripts personalizados).
 

### 🧠 ¿Cómo se usa en la práctica?

- Diagnóstico de rendimiento: ver si las tablas más consultadas están en memoria.
- Optimización de consultas: identificar si tus índices están siendo usados.
- Tuning de parámetros: ajustar `shared_buffers` según el uso real.

El buffer pool es una zona de memoria compartida donde PostgreSQL almacena páginas de datos que han sido leídas desde disco. Esto permite que futuras lecturas sean más rápidas si los datos ya están en memoria.

### Funciones 
```sql

Entiendo que puede ser confuso interpretar los resultados de `pg_buffercache_usage_counts()`.  

- **usage_count**: Indica cuántas veces se ha accedido a un búfer específico. Un valor más alto significa que el búfer se ha utilizado más frecuentemente.
- **buffers**: Muestra el número de búferes que tienen el mismo `usage_count`.
- **dirty**: Indica si el búfer ha sido modificado (1) o no (0) desde que fue cargado en la caché. Un búfer "dirty" necesita ser escrito de nuevo al disco.
- **pinned**: Muestra cuántos procesos están actualmente utilizando el búfer. Un búfer "pinned" no puede ser desalojado de la caché.

Por ejemplo, si ves una fila con `usage_count` de 3, `buffers` de 10, `dirty` de 2 y `pinned` de 1, significa que hay 10 búferes que se han accedido 3 veces, de los cuales 2 han sido modificados y 1 está siendo utilizado actualmente por un proceso.


SELECT * FROM public.pg_buffercache_usage_counts();
+-------------+---------+-------+--------+
| usage_count | buffers | dirty | pinned |
+-------------+---------+-------+--------+
|           0 |  318374 |     0 |      0 |
|           1 |  402554 |     1 |      0 |
|           2 |  118520 |     1 |      0 |
|           3 |  161084 |     0 |      0 |
|           4 |    1172 |     0 |      0 |
|           5 |   46872 |    57 |      0 |
+-------------+---------+-------+--------+





Vamos a desglosar los resultados de `pg_buffercache_summary()` con las unidades de medida:

- **buffers_used**: Indica el número total de búferes que están actualmente en uso. En tu caso, todos los 1,048,576 búferes están en uso.
- **buffers_unused**: Muestra el número de búferes que no están siendo utilizados. Aquí, el valor es 0, lo que significa que no hay búferes sin usar.
- **buffers_dirty**: Indica cuántos de los búferes en uso han sido modificados y necesitan ser escritos de nuevo al disco. Tienes 59 búferes "dirty".
- **buffers_pinned**: Muestra cuántos búferes están actualmente "pinned" por algún proceso, lo que significa que no pueden ser desalojados de la caché. En tu caso, no hay búferes "pinned".
- **usagecount_avg**: Es el promedio del recuento de uso de todos los búferes. Un valor más alto indica que los búferes se están utilizando más frecuentemente. Aquí, el promedio es aproximadamente 1.3 accesos por búfer.




 select * from public.pg_buffercache_summary();
+--------------+----------------+---------------+----------------+--------------------+
| buffers_used | buffers_unused | buffers_dirty | buffers_pinned |   usagecount_avg   |
+--------------+----------------+---------------+----------------+--------------------+
|      1048576 |              0 |            59 |              0 | 1.2988033294677734 |
+--------------+----------------+---------------+----------------+--------------------+
```

### Ejemplos 
```sql

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
		 
		
		
		-- Ejemplo 2: Esto te dirá cuántos bloques/Paginas de 8KB de la tabla están actualmente en el buffer pool.
		SELECT
			n.nspname AS esquema,
			c.relname,
			count(*) AS buffers
		 
		FROM
			pg_buffercache b
		JOIN
			pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
		JOIN
			pg_database d ON b.reldatabase = d.oid
		JOIN
			pg_namespace n ON c.relnamespace = n.oid
		WHERE
			n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
			AND n.nspname NOT LIKE 'pg_temp_%'
			AND n.nspname NOT LIKE 'pg_toast_temp_%'   and not isdirty
		GROUP BY
			n.nspname, c.relname
		ORDER BY
			buffers DESC;


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

# Referencia 
```sql
https://medium.com/@linz07m/postgresql-buffer-cache-how-it-helps-with-faster-queries-94e377c0d3cf
https://tomasz-gintowt.medium.com/postgresql-extensions-pg-buffercache-b38b0dc08000
https://www.postgresql.org/docs/16/pgbuffercache.html
```
