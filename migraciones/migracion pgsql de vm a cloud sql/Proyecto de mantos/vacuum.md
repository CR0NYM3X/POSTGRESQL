 

## 💎 1. PROPUESTA DE NOMENCLATURA Y PARÁMETROS

Para mantener la **Homologación de Grado Diamante**, dividiremos la configuración en 3 dimensiones claras en lugar de nombres largos y rígidos:

1. **`p_scope` (Alcance de Objetivos):** Define **qué** catálogo se procesará.
2. **`p_profile` (Intensidad / Perfil de Vacuum):** Carga de trabajo y opciones de PostgreSQL.
3. **`p_cutoff_time` (Freno por Ventana de Tiempo):** Límite estricto de reloj.


---

### 🌐 A. ALCANCE DE OBJETIVOS (`p_scope`)

| Nombre Propuesto | Nombre Original | Descripción Operativa |
| --- | --- | --- |
| **`SMART_USER`** | `SMART_USERS_TABLES` | Evalúa y procesa **únicamente las tablas del usuario** que superen los umbrales de tuplas muertas (`n_dead_tup`). |
| **`SMART_SYSTEM_USER`** | `SMART_ALL_TABLES` | Evalúa y procesa **tablas del usuario + catálogo del sistema** (`pg_catalog`, `information_schema`) que requieran mantenimiento. |
| **`ALL_USER`** | `USERS_TABLES` | Toma el **100% de las tablas de usuario** sin filtros de umbral. |
| **`ALL_SYSTEM`** | `SYSTEM_TABLES` | Toma única y exclusivamente el catálogo interno del sistema (pg_catalog, information_schema, pg_toast) ignorando por completo las tablas del usuario.|
| **`ALL_SYSTEM_USER`** | `ALL_TABLES` | Toma el **100% de todo el servidor** (Usuario + Sistema [pg_catalog y information_schema ] ) sin filtros. |


### ⚡ B. PERFILES DE INTENSIDAD DE VACUUM (`p_profile`)

Estandarizamos los nombres de los perfiles y sus banderas nativas en PostgreSQL:

| Perfil Propuesto | Comandos Nativo Generado | Características Operativas | Hilos Permitidos |
| --- | --- | --- | --- |
| **`LIGHT`** (o `FAST`) | `VACUUM (SKIP_LOCKED ON, INDEX_CLEANUP OFF)` | Ultra rápido. Si la tabla está bloqueada por otra consulta, **la salta de inmediato sin esperar**. No limpia índices. | Paralelo (N Workers) |
| **`BALANCED`** (o `NORMAL`) | `VACUUM (INDEX_CLEANUP AUTO)` | Mantenimiento estándar balanceado. Limpieza de tuplas muertas e índices de forma segura. | Paralelo (N Workers) |
| **`AGGRESSIVE`** (o `HEAVY`) | `VACUUM (INDEX_CLEANUP AUTO, PARALLEL 4, ANALYZE)` | Mantenimiento profundo. Usa sub-hilos paralelos por tabla y actualiza estadísticas estadísticas en la misma pasada. | Paralelo (N Workers) |
| **`FULL_COMPACTION`** (o `FULL`) | `VACUUM FULL` | Reconstrucción física de tablas de bajo nivel. devuelva espacio en disco al S.O. | **OBLIGADO A 1 WORKER** *(Forzado por el orquestador)* |

> **⚠️ Advertencia de Rodrigo (Gatekeeper):** Si el usuario solicita `p_profile => 'FULL_COMPACTION'`, el orquestador **forzará automáticamente `p_parallel_workers := 1**`, ignorando el valor enviado. Ejecutar múltiples `VACUUM FULL` en paralelo sobrecargará los discos SSD y bloqueará las tablas con exclusividad total (`ACCESS EXCLUSIVE`).

---

## 🧠 2. EL MOTOR DE CONTINUIDAD Y PRIORIZACIÓN (Carryover Engine)

**Habla Marcos (Arquitecto Senior):**

Para lograr que el domingo a las 4:00 AM el orquestador sepa exactamente cuáles 400 tablas se quedaron pendientes la semana pasada, implementamos el **Algoritmo de Priorización de Continuidad**.

### ¿Cómo calcula el orden de las tablas en la cola?

En lugar de ordenar simplemente por `n_dead_tup DESC`, la consulta de inserción calcula un **Peso de Prioridad**:

1. **Prioridad 1 (Tablas Incompletas/Expiradas):** Busca en la tabla `public.vacuum_tasks` la última ejecución con la misma firma (`job_type` + `scope` + `profile`) que se hayan quedado en estatus `'SKIPPED_TIME_LIMIT'` o `'PENDING'`.
2. **Prioridad 2 (Tiempo transcurrido desde el último Vacuum):** Evalúa la vista `pg_stat_user_tables.last_vacuum` y prioriza las tablas que llevan **más tiempo sin recibir mantenimiento**.
3. **Prioridad 3 (Volumen de tuplas muertas):** Ordena por la cantidad de tuplas muertas (`n_dead_tup DESC`).

```sql
ORDER BY 
    -- 1° Las que se quedaron pendientes en la última ejecución similar
    CASE WHEN t_prev.status = 'SKIPPED_TIME_LIMIT' THEN 0 ELSE 1 END ASC,
    -- 2° Las que llevan más tiempo sin VACUUM (o nunca han recibido uno)
    COALESCE(st.last_vacuum, '1970-01-01'::timestamptz) ASC,
    -- 3° Mayor cantidad de tuplas muertas
    st.n_dead_tup DESC

```

---

## ⏱️ 3. MANEJO DE LA VENTANA DE TIEMPO (Cutoff Time)

**Habla Pedro (Desarrollo Core):**

Añadimos el parámetro `p_cutoff_time TIME` (ejemplo: `'06:00:00'::TIME`).

### Lógica de control en el bucle principal:

En cada iteración del bucle principal (antes de despachar un nuevo hilo), el procedimiento evalúa:

```sql
IF p_cutoff_time IS NOT NULL AND LOCALTIME >= p_cutoff_time THEN
    -- 1. Detiene la asignación de NUEVAS tareas
    -- 2. Deja que los hilos RUNNING que ya están en ejecución terminen limpiamente
    -- 3. Actualiza las tareas PENDING que no alcanzaron a salir a estatus 'SKIPPED_TIME_LIMIT'
    -- 4. Marca el Job Padre como 'COMPLETED_WITH_CUTOFF'
    EXIT;
END IF;

```

---

## 🗄️ 4. NUEVOS ESTATUS DE AUDITORÍA EN LAS TABLAS

Para identificar exactamente qué pasó con cada proceso en los paneles de control, agregamos los siguientes estados estándar:

* **Estatus en `public.maintenance_jobs` (Padre):**
* `'COMPLETED'` -> Finalizó el 100% de las tablas dentro de la ventana.
* `'COMPLETED_WITH_CUTOFF'` -> Llegó a la hora límite (ej. 6:00 AM), detuvo el lanzamiento de nuevas tareas y esperó a que los hilos activos terminaran.


* **Estatus en `public.vacuum_tasks` (Hija):**
* `'SUCCESS'` -> Vacuum ejecutado exitosamente.
* `'RUNNING'` -> En ejecución activa.
* `'FAILED'` -> Explotó o se convirtió en zombi.
* `'SKIPPED_TIME_LIMIT'` -> **Nueva:** La tarea estaba en cola pero no se lanzó porque el reloj alcanzó la hora límite (`p_cutoff_time`).



---

## 🛡️ 5. DDL Y PROCEDIMIENTO VANGUARD VACUUM CON ESTADO Y VENTANA DE TIEMPO

### A. Estructura de Tablas Homologada

```sql
-- TABLA HIJA EXCLUSIVA PARA VACUUM (Soporta Ventanas de Tiempo y Priorización)
CREATE TABLE IF NOT EXISTS public.vacuum_tasks (
    task_id SERIAL PRIMARY KEY,
    job_id INT NOT NULL REFERENCES public.maintenance_jobs(job_id) ON DELETE CASCADE,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    n_live_tup BIGINT,
    n_dead_tup BIGINT,
    dead_pct NUMERIC(5,2),
    status VARCHAR(25) DEFAULT 'PENDING', -- 'PENDING', 'RUNNING', 'SUCCESS', 'FAILED', 'SKIPPED_TIME_LIMIT'
    child_pid INT,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    error_log TEXT
);

```

### B. Procedimiento Armado (`sp_orchestrate_vacuum`)

```sql
CREATE OR REPLACE PROCEDURE public.sp_orchestrate_vacuum(
    p_scope VARCHAR DEFAULT 'SMART_USER',-- 1. 'SMART_USER', 'SMART_SYSTEM_USER', 'ALL_USER', 'ALL_SYSTEM_USER', 'ALL_SYSTEM'
    p_profile VARCHAR DEFAULT 'BALANCED',-- 2. 'LIGHT', 'BALANCED', 'AGGRESSIVE', 'FULL_COMPACTION'
    p_parallel_workers INT DEFAULT 4,   -- 3. Cantidad de hilos paralelos
    p_cutoff_time TIME DEFAULT NULL,    -- 4. Hora límite de detención (ej. '06:00:00'::TIME)
    p_verbose BOOLEAN DEFAULT FALSE,    -- 5. Diagnóstico visual
    p_threshold_pct NUMERIC DEFAULT 0.05,-- 6. Umbral tuplas muertas (% de bloat)
    p_min_dead_tup INT DEFAULT 5000     -- 7. Mínimo de tuplas muertas
)
LANGUAGE plpgsql AS $$
DECLARE
    v_job_id INT;
    v_task_id INT;
    v_schema TEXT;
    v_table TEXT;
    v_child_pid INT;
    v_active_workers INT;
    v_pending_tasks INT;
    v_total_tasks INT;
    v_raw_sql TEXT;
    v_effective_workers INT := p_parallel_workers;
    v_start_time TIMESTAMPTZ := clock_timestamp();
    r_finished RECORD;
    v_last_job_id INT;
BEGIN
    -- Forzar a 1 solo worker si se solicita FULL_COMPACTION para proteger el servidor
    IF p_profile = 'FULL_COMPACTION' THEN
        v_effective_workers := 1;
    END IF;

    IF p_verbose THEN
        RAISE INFO '=========================================================';
        RAISE INFO '[DBA SQUAD] ORQUESTADOR VACUUM V1.4 STATEFUL & TIME-AWARE';
        RAISE INFO 'SCOPE: % | PERFIL: % | HILOS: % | HORA LÍMITE: %', 
                   p_scope, p_profile, v_effective_workers, COALESCE(p_cutoff_time::text, 'SIN LÍMITE');
        RAISE INFO '=========================================================';
    END IF;

    -- 1. Registrar el Job Padre
    INSERT INTO public.maintenance_jobs (job_type, maintenance_action, threshold_pct, parallel_workers, status)
    VALUES (p_scope || '_' || p_profile, 'VACUUM', p_threshold_pct, v_effective_workers, 'RUNNING')
    RETURNING job_id INTO v_job_id;
    COMMIT;

    -- 2. Buscar el último Job similar para identificar si quedaron tablas pendientes (SKIPPED_TIME_LIMIT)
    SELECT MAX(job_id) INTO v_last_job_id
    FROM public.maintenance_jobs
    WHERE job_type = (p_scope || '_' || p_profile)
      AND maintenance_action = 'VACUUM'
      AND job_id < v_job_id;

    -- 3. Poblar la cola priorizando pendientes anteriores y excluyendo pg_toast
    INSERT INTO public.vacuum_tasks (
        job_id, schema_name, table_name, n_live_tup, n_dead_tup, dead_pct
    )
    SELECT 
        v_job_id, 
        st.schemaname, 
        st.relname, 
        st.n_live_tup, 
        st.n_dead_tup,
        ROUND((st.n_dead_tup::numeric / NULLIF(st.n_live_tup + st.n_dead_tup, 0)) * 100, 2)
    FROM pg_stat_all_tables st
    LEFT JOIN public.vacuum_tasks prev_t ON prev_t.job_id = v_last_job_id 
                                        AND prev_t.schema_name = st.schemaname 
                                        AND prev_t.table_name = st.relname
    WHERE 
        -- EXCLUSIÓN RIGUROSA: pg_toast NUNCA se procesa directamente
        st.schemaname <> 'pg_toast'
        AND (
            -- SMART_USER / ALL_USER: Solo tablas de usuario
            (p_scope IN ('SMART_USER', 'ALL_USER') AND st.schemaname NOT IN ('pg_catalog', 'information_schema'))
            OR 
            -- SMART_SYSTEM_USER / ALL_SYSTEM_USER: Usuario + Sistema
            (p_scope IN ('SMART_SYSTEM_USER', 'ALL_SYSTEM_USER'))
            OR
            -- ALL_SYSTEM: Única y exclusivamente catálogo interno del sistema
            (p_scope = 'ALL_SYSTEM' AND st.schemaname IN ('pg_catalog', 'information_schema'))
        )
        AND
        -- Filtro por Umbral (Aplica únicamente en modos SMART)
        (
            p_scope NOT LIKE 'SMART%'
            OR
            (
                st.n_dead_tup >= p_min_dead_tup
                AND (
                    (st.n_dead_tup::numeric / NULLIF(st.n_live_tup + st.n_dead_tup, 0)) >= p_threshold_pct 
                    OR st.n_dead_tup >= 100000 
                )
            )
        )
    ORDER BY 
        -- PRIORIDAD 1: Tablas omitidas en la ejecución anterior por hora límite
        CASE WHEN prev_t.status = 'SKIPPED_TIME_LIMIT' THEN 0 ELSE 1 END ASC,
        -- PRIORIDAD 2: Tablas con más tiempo sin recibir VACUUM
        COALESCE(st.last_vacuum, '1970-01-01'::timestamptz) ASC,
        -- PRIORIDAD 3: Mayor volumen de tuplas muertas
        st.n_dead_tup DESC;
    COMMIT;

    SELECT COUNT(*) INTO v_total_tasks FROM public.vacuum_tasks WHERE job_id = v_job_id;
    
    IF p_verbose THEN
        RAISE INFO '[+] JOB ID Asignado: %', v_job_id;
        RAISE INFO '[+] Total de tablas en cola para intervención: %', v_total_tasks;
        RAISE INFO '---------------------------------------------------------';
    END IF;

    IF v_total_tasks = 0 THEN
        IF p_verbose THEN RAISE INFO '[✓] El sistema está limpio. Ninguna tabla requiere intervención.'; END IF;
        UPDATE public.maintenance_jobs SET status = 'COMPLETED', ended_at = clock_timestamp() WHERE job_id = v_job_id;
        COMMIT;
        RETURN;
    END IF;

    -- 4. BUCLE PRINCIPAL DE DESPACHO
    LOOP
        -- A. RECOLECTOR DE MEMORIA (PG_BACKGROUND 1.4)
        FOR r_finished IN 
            SELECT task_id, child_pid FROM public.vacuum_tasks 
            WHERE job_id = v_job_id AND status IN ('SUCCESS', 'FAILED') AND child_pid IS NOT NULL
        LOOP
            BEGIN 
                PERFORM public.pg_background_detach(r_finished.child_pid::INT); 
            EXCEPTION WHEN OTHERS THEN 
                NULL; 
            END;

            UPDATE public.vacuum_tasks SET child_pid = NULL WHERE task_id = r_finished.task_id;
            COMMIT;
        END LOOP;

        -- B. DETECTOR DE ZOMBIS
        WITH zombis AS (
            UPDATE public.vacuum_tasks
            SET status = 'FAILED', ended_at = clock_timestamp(), error_log = 'Process died or aborted before completion.'
            WHERE job_id = v_job_id AND status = 'RUNNING'
              AND child_pid NOT IN (SELECT pid FROM pg_stat_activity WHERE backend_type = 'pg_background')
            RETURNING task_id
        )
        SELECT count(*) FROM zombis INTO v_task_id; 
        COMMIT;

        -- C. EVALUACIÓN DE HORA LÍMITE (Cutoff Time)
        IF p_cutoff_time IS NOT NULL AND LOCALTIME >= p_cutoff_time THEN
            IF p_verbose THEN
                RAISE INFO '---------------------------------------------------------';
                RAISE INFO '[⏹] HORA LÍMITE ALCANZADA (%). Deteniendo lanzamientos...', p_cutoff_time;
                RAISE INFO '---------------------------------------------------------';
            END IF;

            -- Marcar las tareas PENDING pendientes como SKIPPED_TIME_LIMIT
            UPDATE public.vacuum_tasks 
            SET status = 'SKIPPED_TIME_LIMIT', error_log = 'Omitido por alcanzar la hora limite de la ventana de mantenimiento.'
            WHERE job_id = v_job_id AND status = 'PENDING';
            COMMIT;
        END IF;

        -- D. CONTEO DE ESTADO
        SELECT COUNT(*) INTO v_active_workers FROM public.vacuum_tasks WHERE job_id = v_job_id AND status = 'RUNNING';
        SELECT COUNT(*) INTO v_pending_tasks FROM public.vacuum_tasks WHERE job_id = v_job_id AND status = 'PENDING';

        IF v_active_workers = 0 AND v_pending_tasks = 0 THEN EXIT; END IF;

        -- E. DESPACHADOR DE TAREAS
        WHILE v_active_workers < v_effective_workers AND v_pending_tasks > 0 LOOP
            
            -- Freno de emergencia por hora límite
            IF p_cutoff_time IS NOT NULL AND LOCALTIME >= p_cutoff_time THEN
                EXIT;
            END IF;

            SELECT task_id, schema_name, table_name INTO v_task_id, v_schema, v_table
            FROM public.vacuum_tasks
            WHERE job_id = v_job_id AND status = 'PENDING' ORDER BY task_id ASC LIMIT 1;

            IF v_task_id IS NOT NULL THEN
                UPDATE public.vacuum_tasks SET status = 'RUNNING', started_at = clock_timestamp() WHERE task_id = v_task_id;
                COMMIT;

                -- CONSTRUCCIÓN DINÁMICA DEL COMANDO VACUUM SEGÚN EL PERFIL
                v_raw_sql := 'SET maintenance_work_mem = ''8GB''; SET vacuum_cost_delay = 0; ';
                
                IF p_profile = 'LIGHT' THEN
                    v_raw_sql := v_raw_sql || format('VACUUM (SKIP_LOCKED ON, INDEX_CLEANUP OFF) %I.%I; ', v_schema, v_table);
                ELSIF p_profile = 'BALANCED' THEN
                    v_raw_sql := v_raw_sql || format('VACUUM (INDEX_CLEANUP AUTO) %I.%I; ', v_schema, v_table);
                ELSIF p_profile = 'AGGRESSIVE' THEN
                    v_raw_sql := v_raw_sql || format('VACUUM (INDEX_CLEANUP AUTO, PARALLEL 4, ANALYZE) %I.%I; ', v_schema, v_table);
                ELSIF p_profile = 'FULL_COMPACTION' THEN
                    v_raw_sql := v_raw_sql || format('VACUUM FULL %I.%I; ', v_schema, v_table);
                END IF;

                v_raw_sql := v_raw_sql || format('UPDATE public.vacuum_tasks SET status = ''SUCCESS'', ended_at = clock_timestamp() WHERE task_id = %s;', v_task_id);

                -- pg_background 1.4: Asignación escalar directamente a INT
                v_child_pid := public.pg_background_launch(v_raw_sql);

                UPDATE public.vacuum_tasks SET child_pid = v_child_pid WHERE task_id = v_task_id;
                COMMIT;

                IF p_verbose THEN 
                    RAISE INFO '   [>] LANZANDO [%] -> Hilo PID % asignado a Tabla: %.%', p_profile, v_child_pid, v_schema, v_table; 
                END IF;

                v_active_workers := v_active_workers + 1;
                v_pending_tasks := v_pending_tasks - 1;
            END IF;
        END LOOP;
        PERFORM pg_sleep(1);
    END LOOP;

    -- 5. Actualizar Estatus Final del Job Padre
    IF EXISTS (SELECT 1 FROM public.vacuum_tasks WHERE job_id = v_job_id AND status = 'SKIPPED_TIME_LIMIT') THEN
        UPDATE public.maintenance_jobs SET status = 'COMPLETED_WITH_CUTOFF', ended_at = clock_timestamp() WHERE job_id = v_job_id;
    ELSE
        UPDATE public.maintenance_jobs SET status = 'COMPLETED', ended_at = clock_timestamp() WHERE job_id = v_job_id;
    END IF;
    COMMIT;

    IF p_verbose THEN
        RAISE INFO '---------------------------------------------------------';
        RAISE INFO '[DBA SQUAD] ORQUESTACIÓN DE VACUUM FINALIZADA.';
        RAISE INFO 'Tiempo Total: %', (clock_timestamp() - v_start_time);
        RAISE INFO '=========================================================';
    END IF;
END;
$$;
```

---

## 🎮 EJEMPLO DE INVOCACIÓN (DOMINGO A LAS 4:00 AM)

Invocas el Vacuum para tablas de usuario en modo balanceado con 8 hilos, pero con orden explícita de detener lanzamientos a las 06:00 AM:

```sql
CALL public.sp_orchestrate_vacuum(
    p_scope            => 'SMART_USER',
    p_profile          => 'BALANCED',
    p_parallel_workers => 8,
    p_cutoff_time      => '06:00:00'::TIME, -- 👈 Si dan las 6:00 AM, frena limpio
    p_verbose          => TRUE
);

```

### ¿Qué sucederá el siguiente domingo a las 4:00 AM cuando se ejecute de nuevo?

1. Consultará la tabla `maintenance_jobs` y detectará que el Job anterior terminó como `'COMPLETED_WITH_CUTOFF'`.
2. Tomará las tablas marcadas con `'SKIPPED_TIME_LIMIT'` y **las colocará al principio de la fila**.
3. Las procesará primero y luego continuará con las demás tablas ordenadas por antigüedad de Vacuum y volumen de tuplas muertas.
