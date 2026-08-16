 
# Troubleshooting: Identificación y Causa Raíz de Bloqueos en PostgreSQL

**Objetivo:** Identificar el proceso originador (*Líder del Bloqueo* o *Blocker*) cuando la base de datos presenta retención de consultas, encolamiento de sesiones y procesos detenidos a la espera de un recurso asignado a otra transacción.

---

### Paso 1: Monitoreo inicial de eventos de espera por Locks

El primer paso ante un reporte de lentitud o colgado en la base de datos es identificar si las consultas están activas o si se encuentran en un evento de espera de tipo `Lock`.

**Consulta ejecutada:**

```sql
SELECT 
    pid,
    usename,
    client_addr,
    application_name,
    now() - query_start AS duracion_query,
    state,
    wait_event_type,
    wait_event,
    left(query, 80) AS query_corta
FROM pg_stat_activity
WHERE wait_event_type = 'Lock'
ORDER BY duracion_query DESC;

```

**Resultado obtenido:**

```text
  pid  |  usename  |  client_addr  |   application_name   | duracion_query | state  | wait_event_type | wait_event |                   query_corta
-------+-----------+---------------+----------------------+----------------+--------+-----------------+------------+--------------------------------------------------
 20410 | usr_batch | 192.168.10.45 | Worker_Ingestion_Svc | 00:14:22       | active | Lock            | relation   | UPDATE ordenes_procesamiento SET estado = ...
 20411 | usr_batch | 192.168.10.45 | Worker_Ingestion_Svc | 00:14:20       | active | Lock            | relation   | UPDATE ordenes_procesamiento SET estado = ...
 20412 | usr_batch | 192.168.10.45 | Worker_Ingestion_Svc | 00:13:58       | active | Lock            | relation   | INSERT INTO ordenes_procesamiento (id, fecha)...

```

* **Análisis:** Existen múltiples consultas con más de 14 minutos detenidas. El parámetro `wait_event_type = 'Lock'` con `wait_event = 'relation'` confirma que los procesos no están ejecutando trabajo en CPU ni I/O, sino esperando la liberación de un candado a nivel de tabla.

### Paso 2: Identificar transacciones inactivas con transacciones abiertas (`idle in transaction`)

Un patrón común en problemas de bloqueos es una sesión que solicitó un candado exclusivo pero no cerró la transacción (`COMMIT` o `ROLLBACK`) y quedó esperando interacción del usuario o cliente.

**Consulta ejecutada:**

```sql
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    now() - xact_start AS tiempo_en_transaccion,
    now() - state_change AS tiempo_inactivo,
    query AS ultima_query_ejecutada
FROM pg_stat_activity
WHERE state LIKE 'idle in transaction%'
ORDER BY xact_start ASC;

```

**Resultado obtenido:**

```text
  pid  |   usename   |    application_name    |  client_addr  |        state        | tiempo_en_transaccion | tiempo_inactivo |              ultima_query_ejecutada
-------+-------------+------------------------+---------------+---------------------+-----------------------+-----------------+--------------------------------------------------
 10852 | usr_analyst | DBeaver 23.0 - Session | 192.168.10.12 | idle in transaction | 00:48:12              | 00:45:02        | ALTER TABLE ordenes_procesamiento ADD COLUMN...

```

* **Análisis:** Se detecta la sesión **PID 10852** en estado `idle in transaction` con una transacción abierta desde hace 48 minutos. La última consulta ejecutada fue un `ALTER TABLE`, la cual requiere un bloqueo exclusivo para ejecutarse.

### Paso 3: Rastreo de la cadena de dependencia (Árbol de Bloqueos)

Para confirmar formalmente que el **PID 10852** es la causa raíz directa del encolamiento del resto de los PIDs, se reconstruye el árbol jerárquico de bloqueos utilizando la función `pg_blocking_pids()`.

**Consulta ejecutada:**

```sql
WITH RECURSIVE lock_tree AS (
    SELECT 
        pid AS blocker_pid,
        pid AS blocked_pid,
        0 AS depth,
        ARRAY[pid] AS path
    FROM pg_stat_activity
    WHERE array_length(pg_blocking_pids(pid), 1) IS NULL 
      AND pid IN (SELECT unnest(pg_blocking_pids(pid)) FROM pg_stat_activity)

    UNION ALL

    SELECT 
        lt.blocker_pid,
        a.pid AS blocked_pid,
        lt.depth + 1,
        lt.path || a.pid
    FROM pg_stat_activity a
    JOIN lock_tree lt ON lt.blocked_pid = ANY(pg_blocking_pids(a.pid))
)
SELECT 
    repeat('  ', depth) || blocked_pid AS pid_tree,
    a.usename,
    a.application_name,
    a.state,
    a.wait_event_type,
    a.wait_event,
    now() - a.xact_start AS duracion_transaccion,
    a.query
FROM lock_tree lt
JOIN pg_stat_activity a ON lt.blocked_pid = a.pid
ORDER BY lt.path;

```

**Resultado obtenido:**

```text
 pid_tree |   usename   |    application_name    |        state        | wait_event_type | wait_event | duracion_transaccion |                      query
----------+-------------+------------------------+---------------------+-----------------+------------+----------------------+--------------------------------------------------
 10852    | usr_analyst | DBeaver 23.0 - Session | idle in transaction | Client          | ClientRead | 00:48:12             | ALTER TABLE ordenes_procesamiento ADD COLUMN...
   20410  | usr_batch   | Worker_Ingestion_Svc   | active              | Lock            | relation   | 00:14:22             | UPDATE ordenes_procesamiento SET estado = ...
   20411  | usr_batch   | Worker_Ingestion_Svc   | active              | Lock            | relation   | 00:14:20             | UPDATE ordenes_procesamiento SET estado = ...

```

* **Análisis:** Confirmado. El **PID 10852** encabeza la jerarquía. Al no haber nada por encima de él, este proceso es el **Líder del Bloqueo** (*Root Blocker*) que retiene a las consultas secundarias (**20410**, **20411**).

### Paso 4: Inspección del tipo de Lock en `pg_locks`

Analizamos los tipos de candados solicitados y concedidos en la tabla afectada (`ordenes_procesamiento`) para entender la incompatibilidad entre las sentencias.

**Consulta ejecutada:**

```sql
SELECT 
    l.pid,
    a.usename,
    l.locktype,
    l.mode,
    l.granted,
    c.relname AS tabla_afectada,
    a.query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
LEFT JOIN pg_class c ON l.relation = c.oid
WHERE l.pid IN (10852, 20410)
ORDER BY l.granted ASC, l.pid;

```

**Resultado obtenido:**

```text
  pid  |   usename   | locktype |        mode         | granted |   tabla_afectada      |                      query
-------+-------------+----------+---------------------+---------+-----------------------+--------------------------------------------------
 20410 | usr_batch   | relation | RowExclusiveLock    | f       | ordenes_procesamiento | UPDATE ordenes_procesamiento SET estado = ...
 10852 | usr_analyst | relation | AccessExclusiveLock | t       | ordenes_procesamiento | ALTER TABLE ordenes_procesamiento ADD COLUMN...

```

* **Análisis:**
* El PID **10852** sostiene un candado tipo `AccessExclusiveLock` con estado concedido (`granted = t`). Este es el nivel más alto de bloqueo en PostgreSQL.
* El PID **20410** requiere un candado `RowExclusiveLock` para su operación DML (`UPDATE`), pero es marcado como retenido (`granted = f`) porque `RowExclusiveLock` es incompatible con `AccessExclusiveLock`.



### Paso 5: Liberación de recursos retenidos

Para remover el bloqueo y restablecer el flujo normal en la tabla, se procede a finalizar la sesión del proceso bloqueador raíz.

**Comando ejecutado:**

```sql
-- Finalizar la sesión que mantiene retenido el bloqueo
SELECT pg_terminate_backend(10852);

```

**Resultado obtenido:**

```text
 pg_terminate_backend 
----------------------
 t
(1 row)

```

* **Análisis:** La sesión raíz fue cerrada. Los bloqueos dependientes se liberaron de forma instantánea y las transacciones DML encoladas continuaron su procesamiento normal.

---

### Conclusión del Análisis de Bloqueos

1. **Causa Raíz:** Una consulta DDL (`ALTER TABLE`) iniciada interactivamente desde una herramienta cliente (`DBeaver`) obtuvo un bloqueo `AccessExclusiveLock` sobre la tabla `ordenes_procesamiento`. La sesión no envió una instrucción de término (`COMMIT`/`ROLLBACK`) y permaneció en estado `idle in transaction`.
2. **Efecto:** Todas las operaciones concurrentes de lectura/escritura sobre la tabla `ordenes_procesamiento` quedaron encoladas indefinidamente en eventos de espera de tipo `Lock`.
3. **Solución Aplicada:** Terminación explícita del backend con `pg_terminate_backend(10852)`.
4. **Recomendación Técnica:** Implementar la variable de configuración `idle_in_transaction_session_timeout` en el archivo `postgresql.conf` (ejemplo: `5min`) para cancelar automáticamente cualquier transacción inactiva que retenga recursos.
