

# 🧪 Manual Técnico: Acelerando el Acceso a Datos con `pg_prewarm` en PostgreSQL



## 1. 📑 Índice

1.  Objetivo
2.  Requisitos
3.  ¿Qué es `pg_prewarm`?
4.  Ventajas y Desventajas
5.  Casos de Uso
6.  Simulación de Escenario Empresarial
7.  Estructura Semántica
8.  Visualización del Flujo
9.  Laboratorio Paso a Paso
    *   Instalación de `pg_prewarm`
    *   Creación de tabla con 100,000 registros
    *   Consultas con y sin `pg_prewarm`
    *   Comparación de tiempos
10. Consideraciones Finales
11. Buenas Prácticas
12. Bibliografía



## 2. 🎯 Objetivo

Demostrar cómo la extensión `pg_prewarm` puede mejorar el rendimiento de consultas en PostgreSQL al precargar datos en el búfer compartido, evitando lecturas desde disco.



## 3. 🧰 Requisitos

*   PostgreSQL 12 o superior
*   Acceso como superusuario (`postgres`)
*   SO: Linux (preferentemente Ubuntu/Debian)
*   Extensión `pg_prewarm` instalada
*   Herramienta de monitoreo opcional: `pg_stat_statements`



## 4. ❓ ¿Qué es `pg_prewarm`?

Es una extensión que permite precargar bloques de datos en la memoria compartida de PostgreSQL (buffer cache), lo que ayuda a evitar que el rendimiento sea lento justo después de reiniciar el servidor, ya que normalmente la caché se pierde.


## 5. ⚖️ Ventajas y Desventajas

| Ventajas                               | Desventajas                                                  |
| -------------------------------------- | ------------------------------------------------------------ |
| Reduce tiempos de respuesta iniciales  | Requiere memoria RAM disponible                              |
| Útil tras reinicios o vaciado de caché | No es automático (requiere configuración o ejecución manual) |
| Fácil de usar con `pg_prewarm()`       | No sustituye un buen diseño de índices                       |



## 6. 🧩 Casos de Uso

*   Sistemas con reinicios frecuentes (por mantenimiento o fallos)
*   Consultas críticas que deben responder rápido desde el arranque
*   Dashboards o reportes que acceden a grandes volúmenes de datos



## 7. 🏢 Simulación Empresarial

**Empresa:** AgroData S.A.\
**Problema:** Tras reinicios del servidor, los reportes de ventas tardan mucho en cargar.\
**Solución:** Usar `pg_prewarm` para precargar la tabla `ventas` y su índice principal.



## 8. 🧠 Estructura Semántica
```mermaid
graph TD
    A[PostgreSQL] --> B[pg_prewarm]
    B --> C[Shared Buffers]
    C --> D[Tabla: ventas]
    C --> E[Índice: idx_fecha]
    F[Consulta SELECT] --> C 
```



## 9. 🧪 Laboratorio Paso a Paso

### 🔹 9.1 Instalación de `pg_prewarm`

```bash
-- Como superusuario
CREATE EXTENSION IF NOT EXISTS pg_prewarm;
```

📌 *Simulación de salida:*

    CREATE EXTENSION



### 🔹 9.2 Crear tabla con 100,000 registros

```sql
DROP TABLE IF EXISTS ventas;

CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    producto TEXT,
    cantidad INT,
    precio NUMERIC
);

-- Insertar 100,000 registros aleatorios
INSERT INTO ventas (fecha, producto, cantidad, precio)
SELECT
    CURRENT_DATE - (random() * 365)::int,
    'Producto_' || (random() * 100)::int,
    (random() * 10)::int + 1,
    round((random() * 1000)::numeric, 2)
FROM generate_series(1, 100000);
```

📌 *Simulación de salida:*

    INSERT 0 100000



### 🔹 9.3 Crear índice para acelerar consultas

```sql
CREATE INDEX idx_fecha ON ventas(fecha);
```



### 🔹 9.4 Vaciar caché del sistema operativo (solo si tienes acceso root)

```bash
# ⚠️ Solo en entornos de prueba
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
```



### 🔹 9.5 Ejecutar consulta sin `pg_prewarm`

```sql
EXPLAIN ( ANALYZE true, VERBOSE true, COSTS true, TIMING true, BUFFERS true,  SETTINGS true, WAL true)  SELECT * FROM ventas WHERE fecha = CURRENT_DATE - INTERVAL '30 days';
```

📌 *Simulación de salida:*

    Seq Scan on ventas  (cost=0.00..2000.00 rows=100 width=32)
    Execution Time: 120.456 ms



### 🔹 9.6 Precargar tabla con `pg_prewarm`

```sql
SELECT pg_prewarm('ventas');
```

📌 *Simulación de salida:*

    pg_prewarm
    ------------
    100000



### 🔹 9.7 Ejecutar nuevamente la consulta

```sql
EXPLAIN ( ANALYZE true, VERBOSE true, COSTS true, TIMING true, BUFFERS true,  SETTINGS true, WAL true)  SELECT * FROM ventas WHERE fecha = CURRENT_DATE - INTERVAL '30 days';
```

📌 *Simulación de salida:*

    Seq Scan on ventas  (cost=0.00..2000.00 rows=100 width=32)
    Execution Time: 15.234 ms

✅ ¡Reducción significativa del tiempo de respuesta!


### Ejemplos
```sql
pg_ctl restart -D /sysx/data16/DATANEW/test

EXPLAIN ( ANALYZE true, VERBOSE true, COSTS true, TIMING true, BUFFERS true,  SETTINGS true, WAL true)  SELECT * FROM ventas WHERE fecha = CURRENT_DATE - INTERVAL '30 days';

postgres@postgres# EXPLAIN ( ANALYZE true, VERBOSE true, COSTS true, TIMING true, BUFFERS true,  SETTINGS true, WAL true)  SELECT * FROM ventas WHERE fecha = CURRENT_DATE - INTERVAL '30 days';
+----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                      |
+----------------------------------------------------------------------------------------------------------------------+
| Bitmap Heap Scan on public.ventas  (cost=6.40..544.19 rows=271 width=29) (actual time=0.058..0.276 rows=260 loops=1) |
|   Output: id, fecha, producto, cantidad, precio                                                                      |
|   Recheck Cond: (ventas.fecha = (CURRENT_DATE - '30 days'::interval))                                                |
|   Heap Blocks: exact=213                                                                                             |
|   Buffers: shared hit=215                                                                                            |
|   ->  Bitmap Index Scan on idx_fecha  (cost=0.00..6.33 rows=271 width=0) (actual time=0.030..0.030 rows=260 loops=1) |
|         Index Cond: (ventas.fecha = (CURRENT_DATE - '30 days'::interval))                                            |
|         Buffers: shared hit=2                                                                                        |
| Planning Time: 0.089 ms                                                                                              |
| Execution Time: 0.302 ms                                                                                             |
+----------------------------------------------------------------------------------------------------------------------+
(10 rows)

Time: 0.764 ms


postgres@postgres# select * from pg_statio_user_tables where relname ='ventas';
+-[ RECORD 1 ]----+--------+
| relid           | 16477  |
| schemaname      | public |
| relname         | ventas |
| heap_blks_read  | 4227   |
| heap_blks_hit   | 114039 |
| idx_blks_read   | 36     |
| idx_blks_hit    | 199916 |
| toast_blks_read | 0      |
| toast_blks_hit  | 0      |
| tidx_blks_read  | 0      |
| tidx_blks_hit   | 0      |
+-----------------+--------+
```



## 10. 🧠 Consideraciones Finales

*   `pg_prewarm` no es mágico: solo ayuda si los datos precargados son realmente consultados.
*   Puedes automatizarlo con un `cron` o al iniciar PostgreSQL.



## 11. ✅ Buenas Prácticas

*   Precarga solo lo necesario (tablas críticas o índices)
*   Monitorea el uso de memoria (`shared_buffers`)
*   Combínalo con `pg_stat_statements` para identificar qué precargar

--- 


### 🔍 ¿Qué pasa si solo haces esto?

1. **Instalas la extensión `pg_prewarm`.**
2. **Ejecutas `SELECT pg_prewarm('ventas');`**
   - Esto **precarga los bloques de la tabla `ventas` en la caché compartida** en ese momento.
3. **Dejas el servidor funcionando por un rato.**
   - PostgreSQL usa esa caché para acelerar lecturas.
4. **Reinicias el servidor y lo dejas apagado por dos días.**
5. **Lo enciendes nuevamente.**


### ❌ Resultado: **NO se mantiene el efecto**

La precarga que hiciste con `pg_prewarm('ventas')` **se pierde completamente** al reiniciar el servidor. Esto se debe a que:

- La caché compartida de PostgreSQL **no persiste entre reinicios**.
- `pg_prewarm` por sí sola **no guarda ni restaura automáticamente** los bloques precargados.
- Para que se mantenga el efecto, necesitas **activar `autoprewarm`**, que es el componente que guarda el estado de la caché y lo restaura al iniciar.

## ❌ ¿Cuándo **no funciona**?

- Si **solo instalas la extensión** y usas `pg_prewarm()` sin configurar `shared_preload_libraries`, **no se activa el modo automático**.
- Si **reinicias el servidor**, todo lo que se precargó manualmente **se pierde**.
- Si no tienes permisos para modificar `postgresql.conf` o reiniciar el servidor con preload activo, **no se puede usar `autoprewarm`**.

 
## ✅ ¿Cuándo **sí funciona**?

### 1. **Modo manual**
- Usas directamente `SELECT pg_prewarm('mi_tabla');`
- Esto **precarga los bloques de esa tabla en la caché compartida**.
- **Funciona inmediatamente**, pero **solo mientras el servidor esté encendido**.
- **No persiste** tras reinicio.

### 2. **Modo automático (`autoprewarm`)**
- Requiere configuración en `postgresql.conf`:
  ```conf
  shared_preload_libraries = 'pg_prewarm'
   pg_prewarm.autoprewarm = true
   pg_prewarm.autoprewarm_interval = 300s

   select name,setting,context from pg_settings where name ilike '%prewarm%';

  
   ### Validar si el proceso se esta ejecutando 
   postgres@server-test /sysx/data16/DATANEW/test $ ps -fea |grep prewarm
   postgres 2827296 2827288  0 13:50 ?        00:00:00 postgres: autoprewarm leader
   postgres 2828143 2798750  0 13:51 pts/10   00:00:00 grep --color=auto prewarm
  
   autoprewarm_start_worker()
   	¿Qué hace? Inicia el proceso de fondo que se encarga de recuperar automáticamente los bloques que estaban en caché antes del reinicio.

  ```
- PostgreSQL guarda periódicamente qué bloques están en caché.
- Al reiniciar el servidor, el proceso `autoprewarm` **restaura automáticamente** esos bloques en la caché.
- Puedes forzar el guardado con `SELECT autoprewarm_dump_now();`


--- 

 

# verificar si realmente está cargando los datos en memoria
Para verificar si la extensión `pg_prewarm` realmente está cargando los datos en memoria y si los clientes están beneficiándose de ello, puedes seguir estos pasos técnicos y prácticos:


### ✅ 2. **Consulta el caché compartido (`pg_buffercache`)**
Instala y usa la extensión `pg_buffercache` para ver si los bloques de tu tabla están realmente en memoria:

```sql
-- Instalar la extensión si no está activa
CREATE EXTENSION IF NOT EXISTS pg_buffercache;


-- Consulta para ver cuántos bloques/Paginas de 8KB de tu tabla están en caché
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
    AND n.nspname NOT LIKE 'pg_toast_temp_%'
GROUP BY
    n.nspname, c.relname
ORDER BY
    buffers DESC;

```

Esto te dirá cuántos bloques de la tabla están actualmente en el buffer pool.
 

### ✅ 3. **Mide el impacto en los tiempos de respuesta**
Puedes comparar los tiempos de ejecución de una consulta antes y después de usar `pg_prewarm`:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM ventas WHERE ...;
```

Fíjate en:

- `Buffers: shared hit` → indica que los datos vinieron del caché.
- `Buffers: shared read` → indica que los datos vinieron del disco.

Idealmente, después de `pg_prewarm`, deberías ver más "hits" y menos "reads".

 
### ✅ 4. **Verifica el efecto en los clientes**
Para saber si los clientes están beneficiándose:

- **Monitorea el tiempo de respuesta** de las consultas desde la aplicación.
- Usa herramientas como **pg_stat_statements** para ver si las consultas frecuentes están mejorando:

```sql
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time
FROM
    pg_stat_statements
WHERE
    query LIKE '%ventas%'
ORDER BY
    total_exec_time DESC;
```

 


### 🔍 ¿Qué puedes ver con `pg_statio_user_tables`?

- **`heap_blks_read`**: bloques leídos desde disco.
- **`heap_blks_hit`**: bloques leídos desde el caché (shared buffers).

 

### ✅ Consulta recomendada

```sql
SELECT
    relname,
    heap_blks_read,
    heap_blks_hit,
    ROUND(100.0 * heap_blks_hit / NULLIF(heap_blks_hit + heap_blks_read, 0), 2) AS hit_ratio
FROM
    pg_statio_user_tables
WHERE
    relname = 'ventas';
```

Esto te da:

- El nombre de la tabla.
- Cuántos bloques se leyeron desde disco vs. desde caché.
- El **porcentaje de aciertos en caché** (`hit_ratio`), que debería aumentar si `pg_prewarm` está funcionando correctamente.

 

### 🔄 ¿Cómo interpretar los resultados?

- Si `heap_blks_hit` es alto y `heap_blks_read` es bajo → ✅ los datos están siendo servidos desde memoria.
- Si `heap_blks_read` sigue alto → ❌ puede que el prewarm no esté funcionando como esperas, o que el caché se esté limpiando por presión de memoria.

 

### 🧠 Tip adicional

Puedes combinar esta vista con `pg_stat_user_tables` para ver también:

- Número de `seq_scan` y `idx_scan`.
- Cantidad de `n_tup_ins`, `n_tup_upd`, `n_tup_del`.

Esto te ayuda a entender si la tabla está siendo accedida frecuentemente y cómo.


--- 

# **PostgreSQL no obtiene buen rendimiento de la caché**

Cuando **PostgreSQL no obtiene buen rendimiento de la caché** (es decir, del **buffer pool** gestionado por `shared_buffers`), toma varias acciones para mantener la operación, aunque esto puede afectar el rendimiento general. Aquí te explico qué hace y cómo lo maneja:

---

### 🔄 1. **Evicción de páginas**
Si el búfer está lleno y necesita cargar una nueva página, PostgreSQL usa un algoritmo tipo **LRU (Least Recently Used)** modificado para **reemplazar páginas menos usadas**. Si una página está sucia (`isdirty = true`), primero se escribe al disco antes de ser reemplazada.

---

### 📉 2. **Aumento de lecturas desde disco**
Cuando la caché no es suficiente, PostgreSQL **lee más frecuentemente desde el disco**, lo cual es mucho más lento que leer desde memoria. Esto puede causar:

- Mayor latencia en consultas.
- Más carga de I/O en el sistema operativo.
- Posible saturación de discos si hay muchas operaciones concurrentes.

---

### 🧠 3. **Uso de caché del sistema operativo**
Además de `shared_buffers`, PostgreSQL **se apoya en la caché del sistema operativo** (page cache). Si `shared_buffers` no rinde, el SO puede ayudar, pero esto depende de la configuración de memoria total y del uso por otros procesos.

---

### 🧰 4. **Recomendaciones para mejorar el rendimiento de caché**

- **Aumentar `shared_buffers`**: Si tienes suficiente RAM, puedes asignar más memoria a PostgreSQL.
- **Optimizar consultas**: Evitar `seq scan` innecesarios, usar índices adecuados.
- **Usar `pg_stat_statements`** para identificar consultas costosas.
- **Monitorear con `pg_buffercache`**: Ver qué relaciones están ocupando más espacio y si hay muchas páginas sucias.
- **Configurar `effective_cache_size`** correctamente para ayudar al planner a estimar mejor.


 


## 12. 📚 Bibliografía
```sql
*   <https://www.postgresql.org/docs/current/pgprewarm.html>
*   <https://wiki.postgresql.org/wiki/Performance_Optimization>
*   https://www.cybertec-postgresql.com/en/prewarming-postgresql-i-o-caches/
https://www.cybrosys.com/research-and-development/postgres/how-to-improve-postgresql-performance-using-pgprewarm-caching-techniques
https://www.postgresql.org/docs/current/pgprewarm.html

https://medium.com/@wasiualhasib/postgresql-hybrid-transactional-analytical-processing-using-25292f106239
https://ismailyenigul.medium.com/pg-prewarm-extention-to-pre-warming-the-buffer-cache-in-postgresql-7e033b9a386d
```


