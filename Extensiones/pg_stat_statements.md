## ❓ 4. ¿Qué es `pg_stat_statements`?

Es una extensión oficial de PostgreSQL que **registra estadísticas agregadas de ejecución de sentencias SQL**, incluyendo:

*   Número de ejecuciones
*   Tiempo total y promedio
*   Lecturas de disco
*   Errores
*   Uso de CPU

## ⚖️ 5. Ventajas y Desventajas

**Ventajas:**

*   No requiere modificar las aplicaciones
*   Bajo impacto en rendimiento
*   Permite análisis histórico de consultas
*   Compatible con herramientas como `pgBadger`



## 🧊 ¿Qué son los **bloques temporales**?

Son bloques que PostgreSQL **crea y usa temporalmente** cuando una operación (como `ORDER BY`, `JOIN`, `GROUP BY`, `DISTINCT`) **no cabe en la memoria asignada (`work_mem`)**. Entonces:

- PostgreSQL escribe los datos intermedios en disco → `temp_blks_written`.
- Luego los lee para continuar la operación → `temp_blks_read`.

Esto **no tiene nada que ver con las tablas o índices**, sino con **procesamiento interno** de la consulta.

---


## 📌 Ejemplo práctico

Supón que ejecutas:

```sql
SELECT * FROM productos ORDER BY precio DESC;
```

- Si la tabla `productos` está en caché → `shared_blks_hit` sube.
- Si no está en caché → `shared_blks_read` sube.
- Si el ordenamiento excede `work_mem` → PostgreSQL usa disco temporal:
  - Escribe los datos → `temp_blks_written`.
  - Luego los lee para ordenarlos → `temp_blks_read`.
 
---- 

## 🧪 ¿Cuándo se usan los bloques locales?
> Estos bloques **no se comparten entre sesiones**, por eso tienen su propio conjunto de estadísticas.

Los bloques locales se usan cuando trabajas con:

- **Tablas temporales** (`CREATE TEMP TABLE`)
- **Funciones que generan tablas** (`RETURNS TABLE`)
- **Operaciones internas de funciones PL/pgSQL**
- **Consultas que usan estructuras internas no compartidas**


 ## 🧠 ¿Qué son los bloques *locales* vs *compartidos*?

| Tipo de bloque | ¿Dónde se almacenan? | ¿Quién los usa? | ¿Ejemplos comunes? |
|----------------|----------------------|------------------|---------------------|
| **Shared (compartidos)** | En el **buffer compartido** (`shared_buffers`) | Todas las sesiones | Tablas normales, índices, vistas, etc. |
| **Local (locales)** | En el **buffer local** de cada sesión | Solo la sesión actual | Tablas temporales, funciones con `RETURNS TABLE`, operaciones internas de funciones PL/pgSQL. |

---
### 📌 Recomendaciones adicionales:
- Asegúrate de tener habilitada la extensión:
  ```sql
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
  ```
- En `postgresql.conf`, verifica:
  ```conf
  shared_preload_libraries = 'pg_stat_statements'

  select name,setting from pg_settings where name ilike  '%pg_stat_statements%';
  ```

### 🔧 Parámetros de configuración de `pg_stat_statements`

| Parámetro | Valor | Descripción |
|----------|-------|-------------|
| **`pg_stat_statements.max`** | `5000` | Número máximo de sentencias únicas que se almacenarán en la vista `pg_stat_statements`. Si se excede este número, las menos utilizadas se eliminarán para hacer espacio. Un valor más alto permite monitorear más consultas, pero consume más memoria compartida. |
| **`pg_stat_statements.save`** | `on` | Si está activado (`on`), las estadísticas se guardan al apagar el servidor y se restauran al reiniciar. Esto permite conservar el historial de consultas entre reinicios. |
| **`pg_stat_statements.track`** | `top` | Define qué tipo de sentencias se rastrean: <br> - `top`: solo las sentencias SQL de nivel superior (no las internas de funciones). <br> - `all`: incluye también las sentencias internas dentro de funciones. <br> - `none`: no rastrea ninguna sentencia. |
| **`pg_stat_statements.track_planning`** | `off` | Si está activado (`on`), también se rastrea el tiempo de planificación de las consultas (no solo su ejecución). Esto es útil para detectar consultas con planes costosos, pero puede aumentar la sobrecarga. |
| **`pg_stat_statements.track_utility`** | `on` | Permite rastrear comandos utilitarios como `CREATE`, `DROP`, `VACUUM`, etc. Activarlo es útil para auditar operaciones administrativas que también pueden impactar el rendimiento. |

 

### 🧠 Recomendaciones prácticas

- Si estás en un entorno crítico, mantener `pg_stat_statements.save = on` es muy útil para análisis históricos.
- Para bases de datos con muchas funciones, considera usar `track = all` si necesitas visibilidad completa.
- Si estás investigando problemas de rendimiento en el **planificador**, activa `track_planning`.
- Aumenta `pg_stat_statements.max` si tienes muchas consultas distintas y necesitas un monitoreo más amplio.

--- 

# Descripción de cada columna 
### 🔍 **Identificadores de contexto**
| Columna              | Descripción |
|----------------------|-------------|
| `userid`             | ID del usuario que ejecutó la consulta. Se refiere a `pg_authid.oid`. |
| `dbid`               | ID de la base de datos donde se ejecutó la consulta. Se refiere a `pg_database.oid`. |
| `toplevel`           | Booleano que indica si la consulta fue ejecutada como una consulta de nivel superior (no dentro de una función o procedimiento). |
| `queryid`            | Identificador hash de la consulta normalizada. Ayuda a agrupar consultas similares. |
| `query`              | Texto de la consulta normalizada (sin valores literales). |

 

### 📊 **Estadísticas de planificación**
| Columna              | Descripción |
|----------------------|-------------|
| `plans`              | Número de veces que se generó un plan de ejecución para esta consulta. |
| `total_plan_time`    | Tiempo total (en milisegundos) dedicado a planear la consulta. |
| `min_plan_time`      | Tiempo mínimo de planificación registrado. |
| `max_plan_time`      | Tiempo máximo de planificación registrado. |
| `mean_plan_time`     | Tiempo promedio de planificación. |
| `stddev_plan_time`   | Desviación estándar del tiempo de planificación. |

 

### ⚙️ **Estadísticas de ejecución**
| Columna              | Descripción |
|----------------------|-------------|
| `calls`              | Número total de veces que se ejecutó la consulta. |
| `total_exec_time`    | Tiempo total (en milisegundos) dedicado a ejecutar la consulta. |
| `min_exec_time`      | Tiempo mínimo de ejecución registrado. |
| `max_exec_time`      | Tiempo máximo de ejecución registrado. |
| `mean_exec_time`     | Tiempo promedio de ejecución. |
| `stddev_exec_time`   | Desviación estándar del tiempo de ejecución. |
| `rows`               | Número total de filas retornadas por la consulta. |


### 📦 **Estadísticas de bloques compartidos**
| Columna              | Descripción |
|----------------------|-------------|
| `shared_blks_hit`    |  Número de bloques que fueron encontrados en caché (buffer pool). Esto es ideal, ya que evita lecturas desde disco.  |
| `shared_blks_read`   | Número de bloques que no estaban en caché y tuvieron que ser leídos desde disco. Alto valor = posible falta de memoria o consultas que acceden a muchos datos. |
| `shared_blks_dirtied`| Bloques que fueron modificados por la consulta (por ejemplo, en un UPDATE o INSERT). Se marcan como "sucios" porque deben escribirse eventualmente al disco.|
| `shared_blks_written`| Bloques que fueron escritos físicamente al disco como resultado de la consulta. Esto puede ocurrir inmediatamente o durante un checkpoint. |



### 🧱 **Estadísticas de bloques locales**
| Columna              | Descripción |
|----------------------|-------------|
| `local_blks_hit`     | Bloques locales encontrados en caché. |
| `local_blks_read`    | Bloques locales leídos desde disco. |
| `local_blks_dirtied` | Bloques locales modificados. |
| `local_blks_written` | Bloques locales escritos a disco. |


### 🧊 **Bloques temporales**
| Columna              | Descripción |
|----------------------|-------------|
| `temp_blks_read`     | Bloques temporales leídos desde disco. |
| `temp_blks_written`  | Bloques temporales escritos a disco. |


### ⏱️ **Tiempos de acceso a bloques**
| Columna              | Descripción |
|----------------------|-------------|
| `blk_read_time`      | Tiempo total leyendo bloques (en ms). |
| `blk_write_time`     | Tiempo total escribiendo bloques (en ms). |
| `temp_blk_read_time` | Tiempo leyendo bloques temporales. |
| `temp_blk_write_time`| Tiempo escribiendo bloques temporales. |



### 🔁 **Escritura en WAL (Write-Ahead Logging)**
| Columna              | Descripción |
|----------------------|-------------|
| `wal_records`        | Número de registros WAL generados. |
| `wal_fpi`            | Número de imágenes completas de página (FPI) escritas en WAL. |
| `wal_bytes`          | Total de bytes escritos en WAL. |


### 🧠 **JIT (Just-In-Time Compilation)**
| Columna                  | Descripción |
|--------------------------|-------------|
| `jit_functions`          | Número de funciones JIT compiladas. |
| `jit_generation_time`    | Tiempo total generando código JIT. |
| `jit_inlining_count`     | Número de funciones JIT que fueron inlined. |
| `jit_inlining_time`      | Tiempo total de inlining. |
| `jit_optimization_count` | Número de optimizaciones JIT aplicadas. |
| `jit_optimization_time`  | Tiempo total de optimización. |
| `jit_emission_count`     | Número de veces que se emitió código JIT. |
| `jit_emission_time`      | Tiempo total de emisión de código JIT. |


---- 
# Consultas muy utilizadas 


### 🧩 **1. Ver las consultas más costosas**
```sql
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```
- **Objetivo**: Identificar las consultas que consumen más tiempo total.



### 🔁 **2. Consultas más ejecutadas**
```sql
SELECT query, calls
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;
```
- **Objetivo**: Ver qué consultas se ejecutan con mayor frecuencia.



### ⚡ **3. Consultas con mayor tiempo promedio**
```sql
SELECT query, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```
- **Objetivo**: Detectar consultas lentas en promedio.



### 📊 **4. Consultas que retornan más filas**
```sql
SELECT query, rows
FROM pg_stat_statements
ORDER BY rows DESC
LIMIT 10;
```
- **Objetivo**: Ver qué consultas generan más carga por volumen de datos.



### 🧮 **5. Estadísticas generales**
```sql
SELECT 
  sum(calls) AS total_calls,
  sum(total_time) AS total_exec_time,
  sum(rows) AS total_rows
FROM pg_stat_statements;
```
- **Objetivo**: Obtener una visión general del uso del servidor.



### 🧹 **6. Limpiar estadísticas**
```sql
SELECT pg_stat_statements_reset();
```
- **Objetivo**: Reiniciar las estadísticas para comenzar un nuevo monitoreo.



## 2️⃣ **7.  Consultas que están leyendo muchos datos desde disco (y casi no usan la caché) **
Tambien son consultas que usan más CPU (requiere `track_io_timing = on`)**

```sql
SELECT
    userid,
    dbid,
    queryid,
    query,
    calls,
    shared_blks_read,
    local_blks_read,
    shared_blks_hit,
    (shared_blks_read + local_blks_read) AS total_disk_reads,
    total_exec_time
FROM
    pg_stat_statements
WHERE
    shared_blks_read > 0 OR local_blks_read > 0
ORDER BY
    total_disk_reads DESC
LIMIT 10;

```
- **Objetivo**: Analizar el impacto en el sistema de I/O.


## 1️⃣ **Consultas que están generando muchos archivos temporales (`temp_files`)**

> Aunque `pg_stat_statements` **no tiene una columna directa llamada `temp_files`**, puedes inferir el uso de archivos temporales observando las columnas `temp_blks_read` y `temp_blks_written`.

```sql
SELECT
    userid,
    dbid,
    queryid,
    query,
    calls,
    temp_blks_read,
    temp_blks_written,
    temp_blks_read + temp_blks_written AS total_temp_blks,
    total_exec_time
FROM
    pg_stat_statements
WHERE
    temp_blks_read > 0 OR temp_blks_written > 0
ORDER BY
    total_temp_blks DESC
LIMIT 10;
```


## 1️⃣ **Consulta que tardan mucho en ser leidas desde disco**

> Aunque `pg_stat_statements` **no tiene una columna directa llamada `temp_files`**, puedes inferir el uso de archivos temporales observando las columnas `temp_blks_read` y `temp_blks_written`.

 requiere track_io_timing = on: Si estás preocupado por el rendimiento de las operaciones de lectura y escritura en tu base de datos, puedes activar este parámetro para que PostgreSQL registre el tiempo que tarda en realizar operaciones de entrada/salida en el disco. Esto te ayuda a identificar cuellos de botella de E/S y a optimizar el rendimiento de tu sistema de almacenamiento. esto nos permite visualizar los valores en las columnas blk_read_time y blk_write_time en la tabla pg_stat_database

```sql
SELECT
  query,
  blk_read_time,
  shared_blks_read,
  local_blks_read,
  temp_blks_read,
  blk_read_time,          
  blk_write_time,         
  temp_blk_read_time,     
  temp_blk_write_time    
 
  calls
FROM
  pg_stat_statements
WHERE
  blk_read_time > 0
ORDER BY
  blk_read_time DESC
LIMIT 10;
```



### 🧭 **8. Consultas por usuario**
```sql
SELECT userid, dbid, query, calls
FROM pg_stat_statements
ORDER BY userid, calls DESC;
```
- **Objetivo**: Ver qué usuarios están ejecutando más consultas.



--- 

### Links
  ```
<https://www.postgresql.org/docs/current/pgstatstatements.html>
 <https://github.com/darold/pgbadger>
 <https://wiki.postgresql.org/wiki/Performance_Optimization>
   ```
