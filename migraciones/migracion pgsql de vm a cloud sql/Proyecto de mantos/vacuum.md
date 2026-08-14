 

### 🏛️ FASE 1: DESPLIEGUE MUESTRA (DDL & MOTOR CORREGIDO)


```sql
-- =============================================================================
-- DBA SQUAD: INFRAESTRUCTURA MAESTRA DE MANTENIMIENTO
-- =============================================================================

-- 1. EXTENSIONES REQUERIDAS
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pg_background;

-- 2. TABLAS MAESTRAS Y TELEMETRÍA
CREATE TABLE IF NOT EXISTS public.maintenance_jobs (
    job_id SERIAL PRIMARY KEY,
    job_type VARCHAR(50) NOT NULL,        
    maintenance_action VARCHAR(20) NOT NULL, 
    threshold_pct NUMERIC DEFAULT 0.05,  
    parallel_workers INT NOT NULL,        
    tables_processed INT NOT NULL DEFAULT 0, -- Métrica O(1) en RAM
    status VARCHAR(30) DEFAULT 'INITIALIZING',
    started_at TIMESTAMPTZ DEFAULT clock_timestamp(),
    ended_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.vacuum_tasks (
    task_id SERIAL PRIMARY KEY,
    job_id INT NOT NULL REFERENCES public.maintenance_jobs(job_id) ON DELETE CASCADE,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    n_live_tup BIGINT,
    n_dead_tup BIGINT,
    dead_pct NUMERIC(5,2),
    status VARCHAR(30) DEFAULT 'PENDING',
    child_pid INT,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    error_log TEXT
);

CREATE TABLE IF NOT EXISTS public.maintenance_filters (
    filter_id SERIAL PRIMARY KEY,
    schema_name VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    is_ignored BOOLEAN NOT NULL DEFAULT FALSE,        -- ESCUDO BLACKLIST
    force_maintenance BOOLEAN NOT NULL DEFAULT FALSE, -- PASE VIP
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by VARCHAR(100) DEFAULT current_user,
    CONSTRAINT uq_maintenance_filters_schema_table UNIQUE (schema_name, table_name)
);

CREATE TABLE IF NOT EXISTS public.vacuum_full_triage (
    triage_id BIGSERIAL PRIMARY KEY,
    evaluation_week DATE NOT NULL DEFAULT date_trunc('week', current_date),
    schema_name VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    approx_scanned BOOLEAN NOT NULL DEFAULT FALSE,
    approx_evaluated_at TIMESTAMPTZ,
    approx_table_len BIGINT,
    approx_dead_tuple_percent NUMERIC(5,2),
    approx_free_percent NUMERIC(5,2),
    approx_scanned_percent NUMERIC(5,2),
    deep_scanned BOOLEAN NOT NULL DEFAULT FALSE,
    deep_evaluated_at TIMESTAMPTZ,
    deep_table_len BIGINT,
    deep_dead_tuple_percent NUMERIC(5,2),
    deep_free_percent NUMERIC(5,2),
    CONSTRAINT uq_triage_week_schema_table UNIQUE (evaluation_week, schema_name, table_name)
);

-- 3. ÍNDICE CRÍTICO DE ESCALABILIDAD (Revisado por Arquitectura)
CREATE INDEX IF NOT EXISTS idx_vacuum_tasks_job_id ON public.vacuum_tasks(job_id);

-- =============================================================================
-- PROCEDIMIENTO 1: RADAR DE TRIAGE DOMINICAL
-- =============================================================================
CREATE OR REPLACE PROCEDURE public.sp_populate_vacuum_triage(
    p_scope VARCHAR DEFAULT 'ALL_USER',
    p_free_pct_threshold NUMERIC DEFAULT 15.00,
    p_free_mb_threshold NUMERIC DEFAULT 1024.00,
    p_dead_pct_threshold NUMERIC DEFAULT 20.00,
    p_min_table_mb NUMERIC DEFAULT 0.00,
    p_verbose BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    r_table RECORD; r_approx RECORD; r_deep RECORD;
    v_week DATE := date_trunc('week', current_date)::DATE;
    v_processed INT := 0; v_sniped INT := 0;
    v_approx_free_mb NUMERIC;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgstattuple') THEN
        RAISE EXCEPTION 'CRÍTICO: La extensión "pgstattuple" no está instalada.';
    END IF;

    IF p_verbose THEN
        RAISE INFO '=========================================================';
        RAISE INFO '[DBA SQUAD] RADAR DE TRIAGE DOMINICAL INICIADO';
        RAISE INFO 'SCOPE: % | MIN MB: %', p_scope, p_min_table_mb;
        RAISE INFO '=========================================================';
    END IF;

    FOR r_table IN (
        SELECT c.oid AS table_oid, n.nspname AS schema_name, c.relname AS table_name
        FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        LEFT JOIN public.maintenance_filters mf ON mf.schema_name = n.nspname AND mf.table_name = c.relname
        WHERE c.relkind IN ('r', 'm')
          AND n.nspname <> 'pg_toast'
          AND pg_relation_size(c.oid) >= (p_min_table_mb * 1024 * 1024)
          AND (
              (p_scope = 'CUSTOM_LIST' AND mf.force_maintenance = TRUE) OR
              (p_scope IN ('SMART_USER', 'ALL_USER') AND n.nspname NOT IN ('pg_catalog', 'information_schema')) OR
              (p_scope IN ('SMART_SYSTEM_USER', 'ALL_SYSTEM_USER')) OR
              (p_scope = 'ALL_SYSTEM' AND n.nspname IN ('pg_catalog', 'information_schema'))
          )
    ) LOOP
        BEGIN
            SELECT * INTO r_approx FROM pgstattuple_approx(r_table.table_oid);

            INSERT INTO public.vacuum_full_triage (
                evaluation_week, schema_name, table_name, approx_scanned, approx_evaluated_at, approx_table_len, approx_dead_tuple_percent, approx_free_percent, approx_scanned_percent
            ) VALUES (
                v_week, r_table.schema_name, r_table.table_name, TRUE, clock_timestamp(), r_approx.table_len, r_approx.dead_tuple_percent, r_approx.approx_free_percent, r_approx.scanned_percent
            ) ON CONFLICT (evaluation_week, schema_name, table_name) DO UPDATE SET
                approx_scanned = TRUE, approx_evaluated_at = clock_timestamp(), approx_table_len = EXCLUDED.approx_table_len, approx_dead_tuple_percent = EXCLUDED.approx_dead_tuple_percent, approx_free_percent = EXCLUDED.approx_free_percent, approx_scanned_percent = EXCLUDED.approx_scanned_percent;

            v_processed := v_processed + 1;
            v_approx_free_mb := (r_approx.table_len * (r_approx.approx_free_percent / 100.0)) / 1024 / 1024;

            IF r_approx.approx_free_percent >= p_free_pct_threshold
               OR v_approx_free_mb >= p_free_mb_threshold
               OR r_approx.dead_tuple_percent >= p_dead_pct_threshold
            THEN
                SELECT * INTO r_deep FROM pgstattuple(r_table.table_oid);
                UPDATE public.vacuum_full_triage SET
                    deep_scanned = TRUE, deep_evaluated_at = clock_timestamp(), deep_table_len = r_deep.table_len, deep_dead_tuple_percent = r_deep.dead_tuple_percent, deep_free_percent = r_deep.free_percent
                WHERE evaluation_week = v_week AND schema_name = r_table.schema_name AND table_name = r_table.table_name;

                v_sniped := v_sniped + 1;
            END IF;

        EXCEPTION WHEN OTHERS THEN
            IF p_verbose THEN RAISE WARNING 'Error analizando %.%: %', r_table.schema_name, r_table.table_name, SQLERRM; END IF;
        END;
        COMMIT;
    END LOOP;

    IF p_verbose THEN
        RAISE INFO '[✓] TRIAGE FINALIZADO. Evaluadas: %, Escaneos profundos: %', v_processed, v_sniped;
    END IF;
END;
$$;

-- =============================================================================
-- PROCEDIMIENTO 2: ORQUESTADOR PRINCIPAL
-- =============================================================================
CREATE OR REPLACE PROCEDURE public.sp_orchestrate_vacuum(
    p_scope VARCHAR DEFAULT 'SMART_USER',
    p_profile VARCHAR DEFAULT 'BALANCED',
    p_parallel_workers INT DEFAULT 4,
    p_cutoff_time TIME DEFAULT NULL,
    p_verbose BOOLEAN DEFAULT FALSE,
    p_threshold_pct NUMERIC DEFAULT 0.05,
    p_min_dead_tup INT DEFAULT 5000
)
LANGUAGE plpgsql AS $$
DECLARE
    v_job_id INT; v_task_id INT; v_schema TEXT; v_table TEXT; v_child_pid INT;
    v_active_workers INT; v_pending_tasks INT; v_total_tasks INT; v_raw_sql TEXT;
    v_effective_workers INT := p_parallel_workers; r_finished RECORD; v_last_job_id INT;
    v_success_count INT := 0; 
BEGIN
    IF p_profile IN ('VACUUM_FULL', 'SMART_VACUUM_FULL') THEN v_effective_workers := 1; END IF;

    INSERT INTO public.maintenance_jobs (job_type, maintenance_action, threshold_pct, parallel_workers, status)
    VALUES (p_scope || '_' || p_profile, 'VACUUM', p_threshold_pct, v_effective_workers, 'RUNNING') RETURNING job_id INTO v_job_id;
    COMMIT;

    SELECT MAX(job_id) INTO v_last_job_id FROM public.maintenance_jobs WHERE job_type = (p_scope || '_' || p_profile) AND maintenance_action = 'VACUUM' AND job_id < v_job_id;

    INSERT INTO public.vacuum_tasks (job_id, schema_name, table_name, n_live_tup, n_dead_tup, dead_pct)
    SELECT v_job_id, st.schemaname, st.relname, st.n_live_tup, st.n_dead_tup, ROUND(COALESCE(vft.deep_free_percent, (st.n_dead_tup::numeric / NULLIF(st.n_live_tup + st.n_dead_tup, 0)) * 100), 2)
    FROM pg_stat_all_tables st
    LEFT JOIN public.vacuum_tasks prev_t ON prev_t.job_id = v_last_job_id AND prev_t.schema_name = st.schemaname AND prev_t.table_name = st.relname
    LEFT JOIN public.maintenance_filters mf ON mf.schema_name = st.schemaname AND mf.table_name = st.relname
    LEFT JOIN public.vacuum_full_triage vft ON vft.schema_name = st.schemaname AND vft.table_name = st.relname AND vft.evaluation_week = date_trunc('week', current_date)::DATE
    WHERE st.schemaname <> 'pg_toast' AND COALESCE(mf.is_ignored, FALSE) = FALSE
      AND (
          (p_scope = 'CUSTOM_LIST' AND mf.force_maintenance = TRUE) OR
          (p_scope IN ('SMART_USER', 'ALL_USER') AND st.schemaname NOT IN ('pg_catalog', 'information_schema')) OR
          (p_scope IN ('SMART_SYSTEM_USER', 'ALL_SYSTEM_USER')) OR
          (p_scope = 'ALL_SYSTEM' AND st.schemaname IN ('pg_catalog', 'information_schema'))
      )
      AND (
          (p_profile = 'SMART_VACUUM_FULL' AND vft.deep_scanned = TRUE AND vft.deep_free_percent >= (p_threshold_pct * 100)) OR
          (p_profile <> 'SMART_VACUUM_FULL' AND p_scope LIKE 'SMART%' AND st.n_dead_tup >= p_min_dead_tup AND ((st.n_dead_tup::numeric / NULLIF(st.n_live_tup + st.n_dead_tup, 0)) >= p_threshold_pct OR st.n_dead_tup >= 100000)) OR
          (p_profile <> 'SMART_VACUUM_FULL' AND p_scope NOT LIKE 'SMART%')
      )
    ORDER BY CASE WHEN prev_t.status = 'SKIPPED_TIME_LIMIT' THEN 0 ELSE 1 END ASC, CASE WHEN p_profile = 'SMART_VACUUM_FULL' THEN COALESCE(vft.deep_free_percent, 0) ELSE 0 END DESC, COALESCE(st.last_vacuum, '1970-01-01'::timestamptz) ASC, st.n_dead_tup DESC;
    COMMIT;

    SELECT COUNT(*) INTO v_total_tasks FROM public.vacuum_tasks WHERE job_id = v_job_id;
    IF v_total_tasks = 0 THEN
        UPDATE public.maintenance_jobs SET status = 'COMPLETED', ended_at = clock_timestamp(), tables_processed = 0 WHERE job_id = v_job_id;
        IF p_verbose THEN RAISE INFO '[!] No hay tablas candidatas que cumplan los filtros actuales.'; END IF;
        COMMIT; RETURN;
    END IF;

    LOOP
        FOR r_finished IN (
            SELECT task_id, child_pid, schema_name, table_name 
            FROM public.vacuum_tasks 
            WHERE job_id = v_job_id AND status = 'RUNNING' 
            AND child_pid NOT IN (SELECT pid FROM pg_stat_activity WHERE backend_type = 'pg_background')
        ) LOOP
            BEGIN
                PERFORM * FROM public.pg_background_result(r_finished.child_pid) AS (result TEXT);

                UPDATE public.vacuum_tasks 
                SET status = 'SUCCESS', ended_at = clock_timestamp(), child_pid = NULL 
                WHERE task_id = r_finished.task_id;
                
                v_success_count := v_success_count + 1;
                IF p_verbose THEN RAISE INFO '    [✓] TAREA COMPLETADA -> %.%', r_finished.schema_name, r_finished.table_name; END IF;

            EXCEPTION WHEN OTHERS THEN
                UPDATE public.vacuum_tasks 
                SET status = 'FAILED', ended_at = clock_timestamp(), error_log = SQLERRM, child_pid = NULL 
                WHERE task_id = r_finished.task_id;
                
                IF p_verbose THEN RAISE WARNING '    [X] FALLO EN %.%: %', r_finished.schema_name, r_finished.table_name, SQLERRM; END IF;
            END;
            COMMIT;
        END LOOP;

        IF p_cutoff_time IS NOT NULL AND LOCALTIME >= p_cutoff_time THEN
            UPDATE public.vacuum_tasks SET status = 'SKIPPED_TIME_LIMIT', error_log = 'Cutoff Time' WHERE job_id = v_job_id AND status = 'PENDING'; 
            COMMIT;
        END IF;

        SELECT COUNT(*) INTO v_active_workers FROM public.vacuum_tasks WHERE job_id = v_job_id AND status = 'RUNNING';
        SELECT COUNT(*) INTO v_pending_tasks FROM public.vacuum_tasks WHERE job_id = v_job_id AND status = 'PENDING';
        
        IF v_active_workers = 0 AND v_pending_tasks = 0 THEN EXIT; END IF;

        WHILE v_active_workers < v_effective_workers AND v_pending_tasks > 0 LOOP
            IF p_cutoff_time IS NOT NULL AND LOCALTIME >= p_cutoff_time THEN EXIT; END IF;

            SELECT task_id, schema_name, table_name INTO v_task_id, v_schema, v_table FROM public.vacuum_tasks WHERE job_id = v_job_id AND status = 'PENDING' ORDER BY task_id ASC LIMIT 1;
            IF v_task_id IS NOT NULL THEN
                UPDATE public.vacuum_tasks SET status = 'RUNNING', started_at = clock_timestamp() WHERE task_id = v_task_id; COMMIT;

                IF p_profile = 'LIGHT' THEN v_raw_sql := format('VACUUM (SKIP_LOCKED ON, INDEX_CLEANUP OFF) %I.%I;', v_schema, v_table);
                ELSIF p_profile = 'BALANCED' THEN v_raw_sql := format('VACUUM (INDEX_CLEANUP AUTO) %I.%I;', v_schema, v_table);
                ELSIF p_profile = 'AGGRESSIVE' THEN v_raw_sql := format('VACUUM (INDEX_CLEANUP AUTO, PARALLEL 4, ANALYZE) %I.%I;', v_schema, v_table);
                ELSIF p_profile IN ('VACUUM_FULL', 'SMART_VACUUM_FULL') THEN v_raw_sql := format('VACUUM FULL %I.%I;', v_schema, v_table); END IF;

                v_child_pid := public.pg_background_launch(v_raw_sql);
                UPDATE public.vacuum_tasks SET child_pid = v_child_pid WHERE task_id = v_task_id; COMMIT;

                IF p_verbose THEN RAISE INFO '    [>] LANZANDO [%] PID % -> %.%', p_profile, v_child_pid, v_schema, v_table; END IF;
                v_active_workers := v_active_workers + 1; v_pending_tasks := v_pending_tasks - 1;
            END IF;
        END LOOP;
        PERFORM pg_sleep(1);
    END LOOP;

    IF EXISTS (SELECT 1 FROM public.vacuum_tasks WHERE job_id = v_job_id AND status = 'SKIPPED_TIME_LIMIT') THEN
        UPDATE public.maintenance_jobs SET status = 'COMPLETED_WITH_CUTOFF', ended_at = clock_timestamp(), tables_processed = v_success_count WHERE job_id = v_job_id;
    ELSE
        UPDATE public.maintenance_jobs SET status = 'COMPLETED', ended_at = clock_timestamp(), tables_processed = v_success_count WHERE job_id = v_job_id;
    END IF;
    COMMIT;
    
    IF p_verbose THEN RAISE INFO '[✓] ORQUESTACIÓN FINALIZADA. Job % | Procesadas: % / %', v_job_id, v_success_count, v_total_tasks; END IF;
END;
$$;

```

---

