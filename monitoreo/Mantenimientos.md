# Mantenimiento #1 -  Bload y Fragmentacion indices

## Sin extensión

### 1. Script Nivel DBA para medir Fragmentación de TABLAS

Ejecuta este script para ver cuánto espacio físico están desperdiciando tus tablas. Filtra automáticamente las tablas mayores a 1 MB y las ordena de mayor a menor fragmentación.

```sql
WITH constants AS (
    SELECT current_setting('block_size')::numeric AS bs, 
           24 AS tuple_hdr -- Tamaño de la cabecera de fila en Postgres
),
bloat_info AS (
    SELECT
        ma.schemaname,
        ma.relname AS tabla,
        ma.relpages * constants.bs AS tamaño_real,
        (ma.reltuples * (constants.tuple_hdr + ma.avg_width)) AS tamaño_ideal
    FROM (
        SELECT
            n.nspname AS schemaname,
            c.relname,
            c.relpages,
            c.reltuples,
            COALESCE(SUM(s.avg_width), 0) AS avg_width
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        LEFT JOIN pg_stats s ON s.schemaname = n.nspname AND s.tablename = c.relname
        WHERE c.relkind = 'r' AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        GROUP BY n.nspname, c.relname, c.relpages, c.reltuples
    ) ma CROSS JOIN constants
)
SELECT
    schemaname || '.' || tabla AS nombre_tabla,
    pg_size_pretty(tamaño_real) AS tamaño_real,
    pg_size_pretty(tamaño_ideal::numeric) AS tamaño_ideal_estimado,
    pg_size_pretty((tamaño_real - tamaño_ideal)::numeric) AS espacio_desperdiciado,
    CASE 
        WHEN tamaño_real > tamaño_ideal AND tamaño_real > 0 THEN 
            round(((tamaño_real - tamaño_ideal) / tamaño_real * 100)::numeric, 2)
        ELSE 0 
    END AS porcentaje_bloat
FROM bloat_info
WHERE tamaño_real > 1024 * 1024 -- Ignorar tablas de menos de 1MB
ORDER BY porcentaje_bloat DESC;

```
 

### 2. Script Nivel DBA para medir Fragmentación de ÍNDICES (B-Tree)

Los índices se fragmentan más rápido que las tablas. Este script analiza la densidad de las hojas del árbol B (B-Tree) y te dice exactamente qué índices necesitan un `REINDEX CONCURRENTLY`.

```sql
WITH btree_index_atts AS (
    SELECT 
        n.nspname, 
        i.relname AS index_name, 
        i.reltuples, 
        i.relpages, 
        idx.indrelid, 
        i.oid AS indexrelid,
        t.relname AS tablename,
        regexp_split_to_table(idx.indkey::text, ' ')::smallint AS attnum
    FROM pg_index idx
    JOIN pg_class i ON i.oid = idx.indexrelid
    JOIN pg_class t ON t.oid = idx.indrelid
    JOIN pg_namespace n ON n.oid = i.relnamespace
    JOIN pg_am am ON i.relam = am.oid
    WHERE am.amname = 'btree' 
      AND i.relpages > 0 
      AND n.nspname NOT IN ('pg_catalog','information_schema')
),
index_item_sizes AS (
    SELECT
        ind_atts.nspname, 
        ind_atts.index_name, 
        ind_atts.tablename, 
        ind_atts.reltuples, 
        ind_atts.relpages, 
        current_setting('block_size')::numeric AS bs,
        SUM(s.avg_width) AS avg_width
    FROM btree_index_atts ind_atts
    JOIN pg_attribute a ON a.attrelid = ind_atts.indrelid AND a.attnum = ind_atts.attnum
    JOIN pg_stats s ON s.schemaname = ind_atts.nspname AND s.tablename = ind_atts.tablename AND s.attname = a.attname
    GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT
    nspname || '.' || index_name AS nombre_indice,
    tablename AS tabla_pertenece,
    pg_size_pretty(relpages * bs) AS tamaño_real,
    pg_size_pretty((reltuples * (avg_width + 8))::numeric) AS tamaño_ideal_estimado,
    CASE 
        WHEN (relpages * bs) > (reltuples * (avg_width + 8)) AND (relpages * bs) > 0 THEN 
            round((((relpages * bs) - (reltuples * (avg_width + 8))) / (relpages * bs) * 100)::numeric, 2)
        ELSE 0 
    END AS porcentaje_bloat_indice
FROM index_item_sizes
WHERE (relpages * bs) > 1024 * 1024 -- Ignorar índices menores a 1MB
ORDER BY porcentaje_bloat_indice DESC;

```
 
### ¿Cómo interpretar estos resultados como un profesional?

* **Bloat 0% - 15%:** Estado normal. PostgreSQL necesita este porcentaje de espacio vacío natural para acomodar las nuevas actualizaciones (`UPDATE`) sin tener que pedirle más disco duro al sistema operativo inmediatamente. **No hagas nada.**
* **Bloat 20% - 30%:** Advertencia. El `autovacuum` podría no estar corriendo lo suficientemente rápido o la tabla tiene mucha actividad.
* **Bloat > 40%:** **Acción requerida.** Aquí es donde debes ejecutar tu `VACUUM FULL` (para tablas) o tu `REINDEX CONCURRENTLY` (para índices). Estás leyendo gigabytes de aire vacío cada vez que haces un `SELECT`.

> **Advertencia de Exactitud:** Dado que estos scripts utilizan la vista `pg_stats` (las estadísticas del planificador), **su precisión depende de que el autovacuum esté al día**. Si una tabla no ha recibido un `ANALYZE` recientemente, el cálculo de *tamaño ideal* será incorrecto. Siempre es recomendable que el mantenimiento nocturno de `VACUUM ANALYZE` que ya configuraste haya pasado antes de confiar en estas métricas.

## Con extensión

### 1. Activar la Extensión (Solo una vez)

Antes de ejecutar los scripts, asegúrate de habilitar la extensión en tu base de datos `tiendavirtual`.

```sql
CREATE EXTENSION IF NOT EXISTS pgstattuple;

```
 

### 2. Tablero de Fragmentación de Tablas (`pgstattuple`)

Esta consulta utiliza un escaneo lateral (`CROSS JOIN LATERAL`) para pasarle dinámicamente todas tus tablas de usuario a la función.

> **⚠️ Advertencia de I/O:** `pgstattuple` lee **toda la tabla en el disco**. Si tienes tablas de 500 GB, esta consulta tardará y consumirá recursos. He agregado un filtro para ignorar tablas pequeñas y he limitado a mostrar el "Top 20" de las más fragmentadas para proteger tu entorno.

```sql
SELECT
    c.relname AS tabla,
    pg_size_pretty(st.table_len) AS tamaño_total,
    st.tuple_percent AS tuplas_vivas_pct,
    st.dead_tuple_percent AS tuplas_muertas_pct,
    st.free_percent AS espacio_vacio_pct,
    pg_size_pretty(st.free_space) AS gb_desperdiciados
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN LATERAL pgstattuple(c.oid) st
WHERE c.relkind = 'r' 
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND c.relpages > 128 -- Filtra tablas menores a ~1MB para no saturar
ORDER BY st.free_percent DESC
LIMIT 20;

```

#### ¿Cómo leer este tablero?

* **`espacio_vacio_pct` (Free Percent):** Es el indicador clave. Si este número es **mayor a 20% - 30%** en una tabla muy grande, estás frente a un problema de "bloat". Ese es el espacio que recuperarás haciendo tu `VACUUM FULL`.
* **`tuplas_muertas_pct` (Dead Tuple Percent):** Muestra la basura que aún no ha sido limpiada por el autovacuum.
* **`gb_desperdiciados`:** Te dice exactamente cuántos Megabytes o Gigabytes físicos vas a liberar al disco si corres el mantenimiento.
 

### 3. Tablero de Fragmentación de Índices (`pgstatindex`)

Esta función es exclusiva para evaluar la salud física de los árboles B-Tree. Es mucho más rápida que leer las tablas completas.

```sql
SELECT
    i.relname AS indice,
    t.relname AS tabla,
    pg_size_pretty(si.index_size) AS tamaño_indice,
    si.avg_leaf_density AS densidad_hojas_pct,
    si.leaf_fragmentation AS fragmentacion_pct,
    si.empty_pages AS paginas_completamente_vacias
FROM pg_class i
JOIN pg_index idx ON idx.indexrelid = i.oid
JOIN pg_class t ON t.oid = idx.indrelid
JOIN pg_namespace n ON n.oid = i.relnamespace
JOIN pg_am am ON i.relam = am.oid
CROSS JOIN LATERAL pgstatindex(i.oid::regclass) si
WHERE i.relkind = 'i' 
  AND am.amname = 'btree'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND i.relpages > 128 -- Solo índices mayores a ~1MB
ORDER BY si.avg_leaf_density ASC
LIMIT 20;

```

#### ¿Cómo leer este tablero?

Aquí la lógica es a la inversa: buscamos los números más bajos de densidad.

* **`densidad_hojas_pct` (Average Leaf Density):** Un índice sano tiene una densidad de **85% a 90%**. Si tienes índices con densidad **menor al 65%**, el planificador de consultas de Postgres está leyendo muchísimas páginas vacías. **Estos son los índices que debes pasar por tu tarea de `REINDEX CONCURRENTLY`.**
* **`fragmentacion_pct`:** Si es superior al 20-30%, significa que los datos están dispersos físicamente en el disco, haciendo que las búsquedas tarden más tiempo.
* **`paginas_completamente_vacias`:** Páginas del índice que se quedaron vacías tras un borrado masivo pero que no se han devuelto al sistema.




---
 

# Mantenimiento #2 -  los más comunes
 

### 1. Índices Inválidos (La basura del `CONCURRENTLY`)

Como implementaste el `REINDEX CONCURRENTLY`, debes saber esto: si el proceso de reconstrucción falla a la mitad (por un deadlock, un reinicio del servidor o un timeout), **PostgreSQL no borra el índice a medio hacer**. Lo deja marcado como `INVALID`.

* **El problema:** La base de datos no puede usar este índice para acelerar consultas, pero **sí lo sigue actualizando** con cada `INSERT` o `UPDATE`, consumiendo CPU y disco para nada.
* **El mantenimiento:** Identificarlos y borrarlos (`DROP INDEX nombre;`), para luego volver a crearlos/reindexarlos.


* **Si es `t` (True):** El índice es completamente válido. PostgreSQL lo tomará en cuenta para optimizar y acelerar tus consultas.
* **Si es `f` (False):** El índice está incompleto o "roto". El planificador de consultas lo ignorará por completo al hacer un `SELECT`.


### ¿Qué pasa si el `REINDEX CONCURRENTLY` falla a la mitad?

Si por alguna razón el mantenimiento falla (se cancela la consulta, se reinicia el servidor, o hay un interbloqueo/deadlock):

1. **Estás a salvo:** Tu índice original **nunca dejó de funcionar** y seguirá siendo válido (`indisvalid = t`). Tu Llave Primaria sigue protegiendo la integridad de tu tabla.
2. **Queda basura:** El "clon" a medio construir se quedará abandonado en tu base de datos con un nombre terminado en `_ccnew` (ej. `mi_indice_ccnew`) y con `indisvalid = f`.
3. **Tu trabajo:** Como DBA o experto, solo tendrás que buscar ese índice `_ccnew` inválido y hacerle un `DROP INDEX mi_indice_ccnew` manual para liberar el espacio desperdiciado.

> **Regla de oro:** Nunca hagas un `REINDEX` normal (sin `CONCURRENTLY`) en un entorno de producción para una tabla con tráfico. El `REINDEX` tradicional bloquea la tabla por completo (lock exclusivo); nadie podrá escribir ni leer en ella hasta que termine.




**Script de auditoría:**

```sql
SELECT n.nspname AS esquema, i.relname AS indice_invalido, c.relname AS tabla
FROM pg_class c
JOIN pg_index x ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE x.indisvalid = false;

```

### 2. Índices "Zombies" (No utilizados)

Cada índice que creas en una tabla acelera el `SELECT`, pero **ralentiza cada `INSERT`, `UPDATE` y `DELETE**`. A menudo, los desarrolladores crean índices que el planificador de consultas jamás utiliza, o que dejaron de usarse tras una actualización de la aplicación.

* **El problema:** Son puro lastre. Ocupan RAM, I/O de disco y espacio físico.
* **El mantenimiento:** Identificarlos y eliminarlos.

**Script de auditoría:**

```sql
SELECT schemaname, relname AS tabla, indexrelname AS indice, 
       pg_size_pretty(pg_relation_size(i.indexrelid)) AS tamano, idx_scan AS escaneos
FROM pg_stat_user_indexes i
JOIN pg_index x ON i.indexrelid = x.indexrelid
WHERE idx_scan = 0 -- Cero usos
  AND x.indisunique IS FALSE -- Ignorar llaves primarias/únicas (son obligatorias)
ORDER BY pg_relation_size(i.indexrelid) DESC;

```

*(Ojo: Asegúrate de que tu base de datos lleve un par de semanas sin reiniciarse antes de ejecutar esto, ya que las estadísticas de uso se reinician si el servidor se apaga).*

### 3. Peligro de Wraparound (Edad de Transacciones)

PostgreSQL utiliza identificadores numéricos para cada transacción (XID). El límite es de ~2.1 billones. Si te acercas a ese límite, PostgreSQL **se apagará automáticamente** para proteger tus datos y entrará en modo de solo lectura (un evento catastrófico llamado *Transaction ID Wraparound*).

* **El problema:** Aunque tienes `autovacuum` y crons programados, si por alguna razón una tabla gigantesca nunca logra terminar su Vacuum, su "edad" (age) seguirá creciendo.
* **El mantenimiento:** Monitorear que la edad máxima nunca se acerque a los 2 billones (2,000,000,000).

**Script de auditoría:**

```sql
SELECT datname AS base_de_datos, 
       age(datfrozenxid) AS edad_transacciones, 
       round((age(datfrozenxid)::numeric / 2147483648) * 100, 2) AS porcentaje_peligro
FROM pg_database
ORDER BY edad_transacciones DESC;

```

*(Si el porcentaje supera el 50% - 60%, es momento de investigar qué tabla está bloqueando el Vacuum).*

### 4. Slots de Replicación Abandonados

Si alguna vez utilizaste réplicas de lectura en Cloud SQL, herramientas de migración (DMS), o CDC (Change Data Capture como Debezium), PostgreSQL crea un "Slot de replicación".

* **El problema:** Si el servicio que leía esos datos se desconecta permanentemente, el Slot se queda esperando a que vuelva, y **PostgreSQL dejará de borrar los archivos WAL (Transaction Logs)**. En cuestión de días o semanas, tu disco de Cloud SQL se llenará al 100% y la base de datos colapsará.
* **El mantenimiento:** Eliminar los slots que estén inactivos.

**Script de auditoría:**

```sql
SELECT slot_name, plugin, slot_type, active, 
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS espacio_wal_retenido
FROM pg_replication_slots
WHERE active = false;

```

*(Si encuentras uno inactivo reteniendo Gigabytes, bórralo con `SELECT pg_drop_replication_slot('nombre_del_slot');`).*







---

# Mantenimiento #3 - 



### 1. Detección de Bloqueos en Tiempo Real (Locks & Blocks)

Esta versión es mucho más limpia y segura. Te dice exactamente qué consultas están encoladas y qué proceso (PID) las está bloqueando.

* **¿Para qué sirve?** Detectar cuellos de botella transaccionales. Si el mantenimiento "choca" con la operación, lo verás aquí.
* **Acción de mantenimiento:** Si un PID bloquea el sistema, debes matarlo con `SELECT pg_terminate_backend(PID_bloqueador);` y optimizar esa transacción en tu código.

```sql
SELECT 
    pid AS pid_bloqueado, 
    usename AS usuario, 
    pg_blocking_pids(pid) AS pids_bloqueadores,
    state AS estado, 
    now() - query_start AS tiempo_espera,
    query AS consulta_bloqueada
FROM pg_stat_activity
WHERE array_length(pg_blocking_pids(pid), 1) > 0;

```

---

### 2. Tablas sin Índices (Escaneos Secuenciales Masivos)

Esta consulta busca tablas gigantescas donde PostgreSQL está leyendo fila por fila porque no encuentra un índice útil o porque los que tiene no sirven para las consultas actuales.

* **¿Para qué sirve?** Encontrar tablas que están consumiendo todo el I/O del disco.
* **Acción de mantenimiento:** Si una tabla grande tiene un uso de índice menor al 10%, necesitas auditar las consultas de tu aplicación y crear índices nuevos (`CREATE INDEX`).

```sql
SELECT 
    relname AS tabla, 
    seq_scan AS escaneos_secuenciales, 
    idx_scan AS escaneos_por_indice,
    round((idx_scan::numeric / (idx_scan + seq_scan)) * 100, 2) AS porcentaje_uso_indice,
    n_live_tup AS filas_estimadas
FROM pg_stat_user_tables
WHERE seq_scan > 0 
  AND (idx_scan + seq_scan) > 10000 
  AND n_live_tup > 100000 -- Solo tablas con más de 100k registros
ORDER BY porcentaje_uso_indice ASC;

```

---

### 3. Agotamiento de Llaves Primarias (Secuencias)

Si tienes IDs de tipo `INTEGER` (límite de 2.1 billones), esta consulta te avisa si estás a punto de quedarte sin números. Si el ID llega a su límite, los `INSERT` fallarán y la tienda dejará de vender.

* **¿Para qué sirve?** Prevención de desastres por límites de tipos de datos.
* **Acción de mantenimiento:** Si una secuencia supera el 80% o 90%, debes planificar un mantenimiento de ventana larga (downtime) para cambiar el tipo de dato de la columna de `INT` a `BIGINT`.

```sql
SELECT 
    sequencename AS secuencia, 
    data_type AS tipo_dato, 
    last_value AS valor_actual, 
    max_value AS limite_maximo,
    round((last_value::numeric / max_value::numeric) * 100, 2) AS porcentaje_usado
FROM pg_sequences
WHERE last_value IS NOT NULL
ORDER BY porcentaje_usado DESC;

```

---

### 4. Derrame a Disco por Falta de Memoria (Temp Files)

Cuando PostgreSQL realiza un `ORDER BY`, `GROUP BY` o un `JOIN` muy pesado y no cabe en la memoria RAM asignada, escribe "archivos temporales" en el disco, lo cual es lentísimo.

* **¿Para qué sirve?** Medir la eficiencia de tus consultas pesadas.
* **Acción de mantenimiento:** Si ves que estos números crecen rápidamente todos los días, debes optimizar las consultas problemáticas o aumentar el parámetro de configuración `work_mem` en tu instancia de Cloud SQL.

```sql
SELECT 
    datname AS base_de_datos, 
    temp_files AS cantidad_archivos_temporales, 
    pg_size_pretty(temp_bytes) AS disco_usado_historico
FROM pg_stat_database
WHERE temp_files > 0
ORDER BY temp_bytes DESC;

```

---

### 5. Eficiencia de la Memoria Caché (Cache Hit Ratio)

Te indica qué porcentaje de los datos se están leyendo desde la memoria RAM (rapidísimo) frente a los que se tienen que ir a buscar al disco duro (lento).

* **¿Para qué sirve?** Saber si tu base de datos necesita más RAM o si los índices están funcionando.
* **Acción de mantenimiento:** Un servidor sano en producción debe tener un *Cache Hit Ratio* superior al **98%**. Si tu métrica baja del 90%, significa que tus índices están muy fragmentados o que necesitas subir de plan tu instancia en Cloud SQL (más memoria RAM) y aumentar el parámetro `shared_buffers`.

```sql
SELECT 
    datname AS base_de_datos, 
    blks_hit AS lecturas_en_ram,
    blks_read AS lecturas_en_disco,
    round((blks_hit::numeric / nullif(blks_hit + blks_read, 0)) * 100, 2) AS porcentaje_cache_hit
FROM pg_stat_database
WHERE (blks_hit + blks_read) > 0;

```


---


# Mantenimiento #4 - 
 

### 1. Índices Duplicados o Redundantes (El asesino silencioso)

A veces, por falta de comunicación entre desarrolladores o por migraciones repetidas, se crean múltiples índices que apuntan exactamente a las mismas columnas y en el mismo orden.

* **¿Para qué sirve?** Encontrar índices que hacen exactamente lo mismo. Cada índice duplicado duplica el tiempo de escritura (INSERT/UPDATE) y desperdicia disco sin aportar ningún beneficio a las lecturas.
* **Acción de mantenimiento:** Eliminar (`DROP INDEX`) todos menos uno de los índices del grupo.

```sql
SELECT 
    indrelid::regclass AS nombre_tabla,
    array_agg(indexrelid::regclass) AS indices_duplicados,
    indkey AS columnas_indexadas
FROM pg_index
GROUP BY indrelid, indkey, indclass, indpred
HAVING count(*) > 1;

```

 
### 2. Tablas "Sobre-Indexadas" (Index Overkill)

Una regla general en bases de datos transaccionales (OLTP) como tu tienda virtual es que **los índices de una tabla no deberían pesar mucho más que los datos mismos**.

* **¿Para qué sirve?** Identificar tablas donde se han creado tantos índices que el costo de mantenerlos supera ampliamente el beneficio de leer la tabla.
* **Acción de mantenimiento:** Si la proporción (`proporcion_indice_tabla`) es superior a `2.0` o `3.0` (los índices pesan el triple que la tabla), debes auditar la tabla, cruzarlo con la query de "Índices no utilizados" y borrar los innecesarios.

```sql
SELECT 
    relname AS tabla,
    pg_size_pretty(pg_relation_size(relid)) AS tamano_datos,
    pg_size_pretty(pg_indexes_size(relid)) AS tamano_todos_los_indices,
    round(pg_indexes_size(relid)::numeric / nullif(pg_relation_size(relid), 0), 2) AS proporcion_indice_tabla
FROM pg_catalog.pg_stat_user_tables
WHERE pg_relation_size(relid) > 1024 * 1024 -- Ignorar menores a 1MB
ORDER BY proporcion_indice_tabla DESC;

```
 
### 3. Conexiones Zombis (`Idle in Transaction`)

Este es el **enemigo número 1 del `VACUUM**`. Si una aplicación abre una transacción (`BEGIN;`), hace una consulta y se olvida de cerrarla con `COMMIT` o `ROLLBACK`, la conexión se queda en estado `idle in transaction`.

* **¿Para qué sirve?** Mientras exista una conexión en este estado, el autovacuum de PostgreSQL **no podrá borrar ninguna tupla muerta** en toda la base de datos, lo que generará un *bloat* masivo incontrolable.
* **Acción de mantenimiento:** Matar los procesos atascados (`SELECT pg_terminate_backend(pid);`) y, lo más importante, obligar a los desarrolladores de la tienda virtual a revisar por qué su código no está cerrando las transacciones.

```sql
SELECT 
    pid, 
    usename AS usuario, 
    client_addr AS ip_origen,
    now() - state_change AS tiempo_inactivo, 
    query AS ultima_consulta_ejecutada
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND now() - state_change > interval '15 minutes' -- Alerta: más de 15 min atascado
ORDER BY tiempo_inactivo DESC;

```

 
### 4. Tablas donde el Autovacuum fue "Derrotado"

Hay tablas que tienen tantas escrituras por segundo que el proceso de `autovacuum` se ejecuta, pero nunca logra alcanzar la velocidad a la que se genera la basura.

* **¿Para qué sirve?** Detectar tablas conflictivas que están asfixiando al recolector de basura de Postgres.
* **Acción de mantenimiento:** Si ves tablas aquí con alta frecuencia, necesitas hacer un mantenimiento de configuración (Tuning): modificar los parámetros de la tabla (`ALTER TABLE tu_tabla SET (autovacuum_vacuum_scale_factor = 0.05);`) para que el vacuum pase más rápido y más agresivamente solo en esa tabla.

```sql
SELECT 
    relname AS tabla, 
    n_live_tup AS tuplas_vivas,
    n_dead_tup AS tuplas_muertas,
    last_autovacuum AS ultimo_autovacuum,
    round((n_dead_tup::numeric / nullif(n_live_tup + n_dead_tup, 0)) * 100, 2) AS porcentaje_basura
FROM pg_stat_user_tables
WHERE n_dead_tup > 50000 
  AND (last_autovacuum IS NULL OR last_autovacuum < now() - interval '1 day')
ORDER BY porcentaje_basura DESC;

```

 



---

# Mantenimiento #4 - 


