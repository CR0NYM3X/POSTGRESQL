 

### 1. `'SMART'` (El Mantenimiento Quirúrgico Diario)

* **¿Para qué sirve?:** Es el modo **inteligente y autónomo**. En lugar de procesar toda la base de datos a ciegas, lee la telemetría interna del motor (`pg_stat_user_tables`) y selecciona **única y exclusivamente las tablas que están "sucias" o desfasadas**.
* **Criterio de selección:**
* Ignora la "morralla" (tablas con menos de `p_min_rows` modificaciones; por defecto **1,000** filas).
* Evalúa si sufrieron alta volatilidad (cambios mayor a `p_threshold_pct`; por defecto **5%**).
* O si sufrieron un volumen masivo absoluto (más de **50,000** modificaciones sin importar el porcentaje).


* **Caso de uso ideal:** **Mantenimiento nocturno programado de rutina** (vía `pg_cron` a la 1:00 AM o 2:00 AM). Procesa lo que se ensució en el día en cuestión de minutos, ahorrando ciclos de CPU y lecturas de disco SSD.

---

### 2. `'ALL'` (El Mantenimiento Masivo de Catálogo)

* **¿Para qué sirve?:** Ejecuta un `ANALYZE` **sobre absolutamente todas las tablas de usuario** existentes en el catálogo, sin importar si sufrieron cambios o no.
* **Criterio de selección:** Lee `pg_stat_user_tables` completo y ordena las tablas para procesar primero las que tienen mayor volumen de filas modificadas y vivas.
* **Caso de uso ideal:** Mantenimientos profundos de **fin de semana** o ventanas de mantenimiento generales donde se requiere forzar la actualización del 100% de los histogramas del optimizador de la base de datos.
 
### 3. `'PRELOAD'` (La Recuperación de Emergencia en Fases)

* **¿Para qué sirve?:** Emula el flag `--analyze-in-stages` del binario de Linux `vacuumdb`. Ejecuta **3 pasadas consecutivas de `ANALYZE` por cada tabla**, manipulando dinámicamente el parámetro `default_statistics_target`:
1. *Fase 1 (`target = 1`):* Muestra ultra rápida para dar un mapa básico de inmediato.
2. *Fase 2 (`target = 10`):* Muestra media para ajustar histogramas.
3. *Fase 3 (`RESET target`):* Análisis profundo definitivo (target por defecto del servidor, usualmente 100).


* **Caso de uso ideal:** **Exclusivo para escenarios post-desastre:** inmediatamente después de una restauración de base de datos (Point-in-Time Recovery), post-migración de servidor o al levantar un entorno desde cero, permitiendo que el planificador de consultas tenga estadísticas útiles de inmediato sin esperar a que termine un análisis completo.

 
### 📋 RESUMEN TÁCTICO DE INVOCACIÓN

```sql
-- 1. Mantenimiento Diario Autónomo (Recomendado)
CALL public.sp_orchestrate_maintenance(p_job_type => 'SMART', p_parallel_workers => 4, p_verbose => TRUE);

-- 2. Mantenimiento Masivo de Fin de Semana
CALL public.sp_orchestrate_maintenance(p_job_type => 'ALL', p_parallel_workers => 8, p_verbose => FALSE);

-- 3. Mantenimiento de Emergencia Post-Restauración
CALL public.sp_orchestrate_maintenance(p_job_type => 'PRELOAD', p_parallel_workers => 8, p_verbose => TRUE);

```

---

### 1. LAS TABLAS DE ESTADO (ESQUEMA PUBLIC)

**Habla Marcos (Arquitectura):**
Tal como pediste, usaremos dos tablas estandarizadas en `public`.

```sql
-- 1. TABLA PADRE: Orquestación Global
-- DROP TABLE IF EXISTS public.maintenance_jobs CASCADE;
-- TRUNCATE TABLE public.maintenance_jobs RESTART IDENTITY ;
CREATE TABLE public.maintenance_jobs (
    job_id SERIAL PRIMARY KEY,
    job_type VARCHAR(20) NOT NULL,       
    maintenance_action VARCHAR(20) DEFAULT 'ANALYZE', 
    threshold_pct NUMERIC DEFAULT 0.05,  
    parallel_workers INT NOT NULL,       
    status VARCHAR(20) DEFAULT 'INITIALIZING',
    started_at TIMESTAMPTZ DEFAULT clock_timestamp(),
    ended_at TIMESTAMPTZ
);

-- 2. TABLA HIJA: Trazabilidad Forense por Tabla (CON TELEMETRÍA Y SLOTS)
-- DROP TABLE IF EXISTS public.maintenance_tasks CASCADE;
-- TRUNCATE TABLE public.maintenance_tasks RESTART IDENTITY ;
CREATE TABLE public.maintenance_tasks (
    task_id SERIAL PRIMARY KEY,
    job_id INT NOT NULL REFERENCES public.maintenance_jobs(job_id) ON DELETE CASCADE,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    total_filas BIGINT,                  -- n_live_tup
    filas_afectadas BIGINT,              -- n_mod_since_analyze
    drift_pct NUMERIC(5,2),              -- Estándar Internacional
    status VARCHAR(20) DEFAULT 'PENDING', 
    slot_id BIGINT,                         -- <--- COLUMNA CRÍTICA DE GESTIÓN DE HILOS
    child_pid BIGINT,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    error_log TEXT
);


SELECT * FROM public.maintenance_tasks;
SELECT * FROM public.maintenance_jobs;
```

---

### 2. EL CEREBRO: ORQUESTADOR Y GENERADOR DE CÓDIGO CRUDO

 
```sql
-- DROP PROCEDURE IF EXISTS public.sp_orchestrate_maintenance(VARCHAR, INT, BOOLEAN, NUMERIC, INT);

-- ============================================================================
-- 2. RECONSTRUCCIÓN DEL ORQUESTADOR (VANGUARD V5.2) - pg_background >= 2.0
-- ============================================================================
CREATE OR REPLACE PROCEDURE public.sp_orchestrate_maintenance(
    p_job_type VARCHAR,                  -- 1. 'SMART', 'ALL', 'PRELOAD'
    p_parallel_workers INT,              -- 2. Cantidad de hilos paralelos
    p_verbose BOOLEAN DEFAULT FALSE,     -- 3. Diagnóstico visual en tiempo real
    p_threshold_pct NUMERIC DEFAULT 0.05,-- 4. Umbral (0.05 = 5%).
    p_min_rows INT DEFAULT 1000          -- 5. Límite de modificaciones
)
LANGUAGE plpgsql AS $$
DECLARE
    v_job_id INT;
    v_task_id INT;
    v_schema TEXT;
    v_table TEXT;
    v_handle public.pg_background_handle; -- Tipo compuesto oficial (pid int4, cookie int8)
    v_active_workers INT;
    v_pending_tasks INT;
    v_total_tasks INT;
    v_raw_sql TEXT;
    v_start_time TIMESTAMPTZ := clock_timestamp();
    r_finished RECORD;                  -- Variable de registro para bucles
BEGIN
    SET client_min_messages = notice;
    IF p_verbose THEN
        RAISE INFO '=========================================================';
        RAISE INFO '[DBA SQUAD] INICIANDO ORQUESTADOR VANGUARD V5.2 (OFICIAL)';
        RAISE INFO 'TIPO: % | ACCIÓN: ANALYZE | HILOS: % | UMBRAL: %%%', p_job_type, p_parallel_workers, (p_threshold_pct * 100);
        RAISE INFO '=========================================================';
    END IF;

    -- 1. Crear Job Padre
    INSERT INTO public.maintenance_jobs (job_type, maintenance_action, threshold_pct, parallel_workers, status)
    VALUES (p_job_type, 'ANALYZE', p_threshold_pct, p_parallel_workers, 'RUNNING')
    RETURNING job_id INTO v_job_id;
    COMMIT;

    -- 2. Poblar Cola
    IF p_job_type = 'SMART' THEN
        INSERT INTO public.maintenance_tasks (
            job_id, schema_name, table_name, total_filas, filas_afectadas, drift_pct
        )
        SELECT 
            v_job_id, schemaname, relname, n_live_tup, COALESCE(n_mod_since_analyze, 0),
            ROUND((COALESCE(n_mod_since_analyze, 0)::numeric / NULLIF(n_live_tup, 0)) * 100, 2)
        FROM pg_stat_user_tables
        WHERE COALESCE(n_mod_since_analyze, 0) >= p_min_rows
          AND (
              (COALESCE(n_mod_since_analyze, 0)::numeric / NULLIF(n_live_tup, 0)) >= p_threshold_pct 
              OR COALESCE(n_mod_since_analyze, 0) >= 50000 
          )
        ORDER BY COALESCE(n_mod_since_analyze, 0) DESC;
    ELSE
        INSERT INTO public.maintenance_tasks (
            job_id, schema_name, table_name, total_filas, filas_afectadas, drift_pct
        )
        SELECT 
            v_job_id, schemaname, relname, n_live_tup, COALESCE(n_mod_since_analyze, 0),
            ROUND((COALESCE(n_mod_since_analyze, 0)::numeric / NULLIF(n_live_tup, 0)) * 100, 2)
        FROM pg_stat_user_tables
        ORDER BY COALESCE(n_mod_since_analyze, 0) DESC, n_live_tup DESC;
    END IF;
    COMMIT;

    SELECT COUNT(*) INTO v_total_tasks FROM public.maintenance_tasks WHERE job_id = v_job_id;
    
    IF p_verbose THEN
        RAISE INFO '[+] JOB ID Asignado: %', v_job_id;
        RAISE INFO '[+] Total de tablas que requieren intervención: %', v_total_tasks;
        RAISE INFO '---------------------------------------------------------';
    END IF;

    IF v_total_tasks = 0 THEN
        IF p_verbose THEN RAISE INFO '[✓] El sistema está óptimo. Ninguna tabla superó los umbrales.'; END IF;
        UPDATE public.maintenance_jobs SET status = 'COMPLETED', ended_at = clock_timestamp() WHERE job_id = v_job_id;
        COMMIT;
        RETURN;
    END IF;

    -- 3. BUCLE PRINCIPAL (Monitoreo y Despacho)
    LOOP
        -- A. RECOLECTOR DE MEMORIA OFICIAL
        FOR r_finished IN 
            SELECT task_id, child_pid, slot_id
            FROM public.maintenance_tasks 
            WHERE job_id = v_job_id AND status IN ('SUCCESS', 'FAILED') AND child_pid IS NOT NULL
        LOOP
            BEGIN
                -- Libera la memoria consumida usando la firma (pid, cookie)
                PERFORM public.pg_background_detach(r_finished.child_pid::INT, r_finished.slot_id::BIGINT);
            EXCEPTION WHEN OTHERS THEN
                NULL; -- Ignorar si ya fue liberado
            END;

            UPDATE public.maintenance_tasks SET child_pid = NULL, slot_id = NULL WHERE task_id = r_finished.task_id;
            COMMIT;
        END LOOP;

        -- B. DETECTOR DE ZOMBIS
        WITH zombis AS (
            UPDATE public.maintenance_tasks
            SET status = 'FAILED', ended_at = clock_timestamp(), error_log = 'Process died or aborted before completion.'
            WHERE job_id = v_job_id AND status = 'RUNNING'
              AND child_pid NOT IN (SELECT pid FROM pg_stat_activity WHERE backend_type = 'pg_background')
            RETURNING task_id
        )
        SELECT count(*) FROM zombis INTO v_task_id; 
        
        IF p_verbose AND v_task_id > 0 THEN RAISE INFO '[X] ALERTA: Se detectaron y purgaron % procesos zombis.', v_task_id; END IF;
        COMMIT;

        -- C. REPORTE VISUAL
        IF p_verbose THEN
            FOR v_schema, v_table, v_task_id IN 
                SELECT schema_name, table_name, task_id FROM public.maintenance_tasks 
                WHERE job_id = v_job_id AND status = 'SUCCESS' AND ended_at >= (clock_timestamp() - INTERVAL '1.5 seconds')
            LOOP
                RAISE INFO '   [✓] ÉXITO -> Tabla: %.% (Task ID: %)', v_schema, v_table, v_task_id;
            END LOOP;
        END IF;

        -- D. CONTEO DE ESTADO
        SELECT COUNT(*) INTO v_active_workers FROM public.maintenance_tasks WHERE job_id = v_job_id AND status = 'RUNNING';
        SELECT COUNT(*) INTO v_pending_tasks FROM public.maintenance_tasks WHERE job_id = v_job_id AND status = 'PENDING';

        IF v_active_workers = 0 AND v_pending_tasks = 0 THEN EXIT; END IF;

        -- E. DESPACHADOR DE TAREAS CON API V2.0 NATIVA
        WHILE v_active_workers < p_parallel_workers AND v_pending_tasks > 0 LOOP
            SELECT task_id, schema_name, table_name INTO v_task_id, v_schema, v_table
            FROM public.maintenance_tasks
            WHERE job_id = v_job_id AND status = 'PENDING' ORDER BY task_id ASC LIMIT 1;

            IF v_task_id IS NOT NULL THEN
                UPDATE public.maintenance_tasks SET status = 'RUNNING', started_at = clock_timestamp() WHERE task_id = v_task_id;
                COMMIT;

                v_raw_sql := 'SET maintenance_work_mem = ''8GB''; SET max_parallel_maintenance_workers = 4; SET vacuum_cost_delay = 0; ';

                IF p_job_type = 'PRELOAD' THEN
                    v_raw_sql := v_raw_sql || format('SET default_statistics_target = 1; ANALYZE %I.%I; ', v_schema, v_table);
                    v_raw_sql := v_raw_sql || format('SET default_statistics_target = 10; ANALYZE %I.%I; ', v_schema, v_table);
                    v_raw_sql := v_raw_sql || format('RESET default_statistics_target; ANALYZE %I.%I; ', v_schema, v_table);
                ELSE
                    v_raw_sql := v_raw_sql || format('ANALYZE %I.%I; ', v_schema, v_table);
                END IF;

                v_raw_sql := v_raw_sql || format('UPDATE public.maintenance_tasks SET status = ''SUCCESS'', ended_at = clock_timestamp() WHERE task_id = %s;', v_task_id);

                -- Retorno directo al tipo pg_background_handle
                v_handle := public.pg_background_launch(v_raw_sql);

                -- Guardamos pid (int4) y cookie (int8) en campos BIGINT
                UPDATE public.maintenance_tasks 
                SET child_pid = v_handle.pid, 
                    slot_id   = v_handle.cookie 
                WHERE task_id = v_task_id;
                COMMIT;

                IF p_verbose THEN 
                    -- RAISE INFO '   [>] LANZANDO -> Hilo PID % (Cookie %) asignado a Tabla: %.%', v_handle.pid, v_handle.cookie, v_schema, v_table;
                    RAISE INFO '   [>] LANZANDO -> Hilo PID %  asignado a Tabla: %.%', v_handle.pid,  v_schema, v_table; 
                END IF;

                v_active_workers := v_active_workers + 1;
                v_pending_tasks := v_pending_tasks - 1;
            END IF;
        END LOOP;
        PERFORM pg_sleep(1);
    END LOOP;

    -- 4. FIN DE OPERACIONES
    UPDATE public.maintenance_jobs SET status = 'COMPLETED', ended_at = clock_timestamp() WHERE job_id = v_job_id;
    COMMIT;

    IF p_verbose THEN
        RAISE INFO '---------------------------------------------------------';
        RAISE INFO '[DBA SQUAD] ORQUESTACIÓN FINALIZADA CON ÉXITO.';
        RAISE INFO 'Tiempo Total: %', (clock_timestamp() - v_start_time);
        RAISE INFO '=========================================================';
    END IF;
END;
$$;
 
```

---



### 🎮 EL MODO DE USO: DOS ESCENARIOS TÁCTICOS

#### 1. El Bisturí (Prueba Visual en tu Consola)

Lo lanzas con `TRUE` en tu DBeaver, se queda "trabado", pero te va imprimiendo un log hermoso en la pestaña de mensajes:

```sql
--- TU CONSOLA SE BLOQUEADA  hasta que termine de procesar todas las tablas.

CALL public.sp_orchestrate_maintenance(
    p_job_type         => 'SMART', 
    p_parallel_workers => 4, 
    p_verbose          => TRUE,
    p_threshold_pct    => 0.05, 
    p_min_rows         => 1000  -- <-- ¡ESTA ES LA CLAVE PARA TU LABORATORIO!
);

```

**Resultado Visual Esperado:**

```text
INFO:  =========================================================
INFO:  [DBA SQUAD] INICIANDO ORQUESTADOR DE MANTENIMIENTO VANGUARD
INFO:  TIPO: SMART | ACCIÓN: ANALYZE | HILOS: 4 | UMBRAL: %5.00 | MIN CAMBIOS: 1000
INFO:  =========================================================
INFO:  [+] JOB ID Asignado: 2
INFO:  [+] Total de tablas que requieren intervención: 5
INFO:  ---------------------------------------------------------
INFO:     [>] LANZANDO -> Hilo 56479 asignado a Tabla: public.lab_sesiones (Task ID: 6)
INFO:     [>] LANZANDO -> Hilo 56480 asignado a Tabla: public.lab_carritos (Task ID: 7)
INFO:     [>] LANZANDO -> Hilo 56481 asignado a Tabla: public.lab_pedidos (Task ID: 8)
INFO:     [>] LANZANDO -> Hilo 56482 asignado a Tabla: public.lab_logs_auditoria (Task ID: 9)
INFO:     [✓] ÉXITO -> Tabla: public.lab_carritos (Task ID: 7)
INFO:     [✓] ÉXITO -> Tabla: public.lab_logs_auditoria (Task ID: 9)
INFO:     [✓] ÉXITO -> Tabla: public.lab_pedidos (Task ID: 8)
INFO:     [✓] ÉXITO -> Tabla: public.lab_sesiones (Task ID: 6)
INFO:     [>] LANZANDO -> Hilo 56483 asignado a Tabla: public.lab_inventario (Task ID: 10)
INFO:     [✓] ÉXITO -> Tabla: public.lab_inventario (Task ID: 10)
INFO:  ---------------------------------------------------------
INFO:  [DBA SQUAD] ORQUESTACIÓN FINALIZADA CON ÉXITO.
INFO:  Tiempo Total: 00:00:02.036088
INFO:  =========================================================
```

#### 2. Modos Ejecuta y Suelta


**MÉTODO 1: EL FANTASMA MANUAL (Vía pg_background_launch)**
```sql
SELECT pid 
FROM public.pg_background_launch(
    'CALL public.sp_orchestrate_maintenance(
        p_job_type         => ''SMART'', 
        p_parallel_workers => 4, 
        p_verbose          => FALSE, -- 👈 EL SILENCIADOR (Vital para modo fantasma)
        p_threshold_pct    => 0.05, 
        p_min_rows         => 1000
    );'
);
```

**MÉTODO 2: LA AUTOMATIZACIÓN ABSOLUTA (Vía pg_cron)**
```SQL
SELECT cron.schedule_in_database(
    'vanguard_smart_analyze', -- Nombre del trabajo en Cron
    '0 2 * * *',              -- Expresión Cron: Todos los días a las 02:00 AM
    $$ 
    CALL public.sp_orchestrate_maintenance(
        p_job_type         => 'SMART', 
        p_parallel_workers => 4, 
        p_verbose          => FALSE, -- Silencioso, porque a las 2 AM nadie está mirando
        p_threshold_pct    => 0.05, 
        p_min_rows         => 1000
    ); 
    $$,
    'tiendavirtual',          -- Base de datos objetivo
    'postgres',               -- Usuario ejecutor
    true                      -- Activo
);
```

 ----

# 🧪 LABORATORIO VANGUARD: POLÍGONO DE TIRO SQL

Ejecuta este script completo en tu entorno de desarrollo/pruebas.

```sql
-- ============================================================================
-- DBA SQUAD: VANGUARD BLACK-OPS - LABORATORIO DE CAOS SINTÉTICO
-- ============================================================================
SET autovacuum = off;

BEGIN;

-- ----------------------------------------------------------------------------
-- FASE 1: CREACIÓN DE ESTRUCTURAS (10 Tablas)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS public.lab_clientes, public.lab_productos, public.lab_pedidos, 
                     public.lab_detalle_pedidos, public.lab_pagos, public.lab_envios, 
                     public.lab_inventario, public.lab_carritos, public.lab_sesiones, 
                     public.lab_logs_auditoria CASCADE;

CREATE TABLE public.lab_clientes (id SERIAL PRIMARY KEY, nombre TEXT, estatus TEXT);
CREATE TABLE public.lab_productos (id SERIAL PRIMARY KEY, sku TEXT, precio NUMERIC);
CREATE TABLE public.lab_pedidos (id SERIAL PRIMARY KEY, cliente_id INT, total NUMERIC, estado TEXT);
CREATE TABLE public.lab_detalle_pedidos (id SERIAL PRIMARY KEY, pedido_id INT, cantidad INT);
CREATE TABLE public.lab_pagos (id SERIAL PRIMARY KEY, pedido_id INT, monto NUMERIC, metodo TEXT);
CREATE TABLE public.lab_envios (id SERIAL PRIMARY KEY, pedido_id INT, guia TEXT, estado TEXT);
CREATE TABLE public.lab_inventario (id SERIAL PRIMARY KEY, producto_id INT, stock INT);
CREATE TABLE public.lab_carritos (id SERIAL PRIMARY KEY, cliente_id INT, fecha_creacion TIMESTAMP);
CREATE TABLE public.lab_sesiones (id SERIAL PRIMARY KEY, token TEXT, ultima_actividad TIMESTAMP);
CREATE TABLE public.lab_logs_auditoria (id SERIAL PRIMARY KEY, evento TEXT, fecha TIMESTAMP);

ALTER TABLE public.lab_clientes SET (autovacuum_enabled = false);
ALTER TABLE public.lab_productos SET (autovacuum_enabled = false);
ALTER TABLE public.lab_pedidos SET (autovacuum_enabled = false);
ALTER TABLE public.lab_detalle_pedidos SET (autovacuum_enabled = false);
ALTER TABLE public.lab_pagos SET (autovacuum_enabled = false);
ALTER TABLE public.lab_envios SET (autovacuum_enabled = false);
ALTER TABLE public.lab_inventario SET (autovacuum_enabled = false);
ALTER TABLE public.lab_carritos SET (autovacuum_enabled = false);
ALTER TABLE public.lab_sesiones SET (autovacuum_enabled = false);
ALTER TABLE public.lab_logs_auditoria SET (autovacuum_enabled = false);

-- ----------------------------------------------------------------------------
-- FASE 2: INYECCIÓN DE VOLUMEN (20,000 filas por tabla para superar filtro de 10k)
-- ----------------------------------------------------------------------------
INSERT INTO public.lab_clientes (nombre, estatus) SELECT 'Cliente ' || i, 'ACTIVO' FROM generate_series(1, 20000) i;
INSERT INTO public.lab_productos (sku, precio) SELECT 'SKU-' || i, RANDOM() * 1000 FROM generate_series(1, 20000) i;
INSERT INTO public.lab_pedidos (cliente_id, total, estado) SELECT i, RANDOM() * 500, 'NUEVO' FROM generate_series(1, 20000) i;
INSERT INTO public.lab_detalle_pedidos (pedido_id, cantidad) SELECT i, 1 FROM generate_series(1, 20000) i;
INSERT INTO public.lab_pagos (pedido_id, monto, metodo) SELECT i, 100, 'TARJETA' FROM generate_series(1, 20000) i;
INSERT INTO public.lab_envios (pedido_id, guia, estado) SELECT i, 'GUIA-'||i, 'PREPARANDO' FROM generate_series(1, 20000) i;
INSERT INTO public.lab_inventario (producto_id, stock) SELECT i, 100 FROM generate_series(1, 20000) i;
INSERT INTO public.lab_carritos (cliente_id, fecha_creacion) SELECT i, NOW() FROM generate_series(1, 20000) i;
INSERT INTO public.lab_sesiones (token, ultima_actividad) SELECT md5(i::text), NOW() FROM generate_series(1, 20000) i;
INSERT INTO public.lab_logs_auditoria (evento, fecha) SELECT 'LOGIN', NOW() FROM generate_series(1, 20000) i;

COMMIT;

-- ----------------------------------------------------------------------------
-- FASE 3: ESTABILIZACIÓN DEL MOTOR (Punto Cero)
-- Hacemos un ANALYZE masivo para que el motor ponga n_mod_since_analyze en 0.
-- ----------------------------------------------------------------------------
ANALYZE public.lab_clientes;
ANALYZE public.lab_productos;
ANALYZE public.lab_pedidos;
ANALYZE public.lab_detalle_pedidos;
ANALYZE public.lab_pagos;
ANALYZE public.lab_envios;
ANALYZE public.lab_inventario;
ANALYZE public.lab_carritos;
ANALYZE public.lab_sesiones;
ANALYZE public.lab_logs_auditoria;

-- ----------------------------------------------------------------------------
-- FASE 4: SIMULACIÓN DE CAOS TRANSACCIONAL (El paso del tiempo)
-- ----------------------------------------------------------------------------
BEGIN;

-- 1. lab_sesiones (90% de cambio) -> ALTA PRIORIDAD. Expira sesiones viejas.
UPDATE public.lab_sesiones SET ultima_actividad = NOW() WHERE id <= 18000;

-- 2. lab_carritos (50% de cambio) -> ALTA PRIORIDAD. Borrado masivo de carritos abandonados.
DELETE FROM public.lab_carritos WHERE id <= 10000;

-- 3. lab_pedidos (15% de cambio) -> MEDIA PRIORIDAD. Pedidos que pasaron a ENVIADO.
UPDATE public.lab_pedidos SET estado = 'ENVIADO' WHERE id <= 3000;

-- 4. lab_logs_auditoria (10% de cambio) -> MEDIA PRIORIDAD. Inserción de nuevos logs.
INSERT INTO public.lab_logs_auditoria (evento, fecha) SELECT 'CLICK', NOW() FROM generate_series(20001, 22000);

-- 5. lab_inventario (6% de cambio) -> BAJA PRIORIDAD. Apenas pasa el umbral del 5%.
UPDATE public.lab_inventario SET stock = stock - 1 WHERE id <= 1200;

-- ================== TABLAS TRAMPA (DEBEN SER IGNORADAS) ==================

-- 6. lab_clientes (2% de cambio) -> IGNORADA. No llega al umbral del 5%.
UPDATE public.lab_clientes SET estatus = 'INACTIVO' WHERE id <= 400;

-- 7. lab_productos (0% de cambio) -> IGNORADA. El catálogo no mutó hoy.
-- (Sin operaciones DML)

COMMIT;

```

---

### 🔍 CÓMO EJECUTAR LA PRUEBA TÁCTICA

#### PASO 1: Verifica la Telemetría (El Radar)

Antes de disparar el orquestador, corre esta consulta para ver qué es lo que el motor de PostgreSQL está detectando. Aquí verás exactamente las matemáticas que usará nuestro orquestador:

```sql
SELECT 
    relname AS nombre_tabla,
    n_live_tup AS filas_vivas,
    n_mod_since_analyze AS filas_modificadas,
    ROUND((n_mod_since_analyze::numeric / NULLIF(n_live_tup, 0)) * 100, 2) AS change_pct
FROM pg_stat_user_tables
WHERE relname LIKE 'lab_%'
ORDER BY change_pct DESC NULLS LAST;

```

**Salida esperada**
```
+---------------------+-------------+-------------------+------------+
|    nombre_tabla     | filas_vivas | filas_modificadas | change_pct |
+---------------------+-------------+-------------------+------------+
| lab_carritos        |       10000 |             10000 |     100.00 |
| lab_sesiones        |       20000 |             18000 |      90.00 |
| lab_pedidos         |       20000 |              3000 |      15.00 |
| lab_logs_auditoria  |       22000 |              2000 |       9.09 |
| lab_inventario      |       20000 |              1200 |       6.00 |
| lab_clientes        |       20000 |               400 |       2.00 |
| lab_envios          |       20000 |                 0 |       0.00 |
| lab_pagos           |       20000 |                 0 |       0.00 |
| lab_detalle_pedidos |       20000 |                 0 |       0.00 |
| lab_productos       |       20000 |                 0 |       0.00 |
+---------------------+-------------+-------------------+------------+
```



#### PASO 2: Dispara el Orquestador Vanguard (Modo Visual)

Ahora, activa el arma. Pídele 4 hilos paralelos, un umbral del 5% (0.05) y enciende el modo visual (`TRUE`):

```sql
CALL public.sp_orchestrate_maintenance(
    p_job_type         => 'SMART', 
    p_parallel_workers => 4, 
    p_verbose          => TRUE,
    p_threshold_pct    => 0.05, 
    p_min_rows         => 1000  -- <-- ¡ESTA ES LA CLAVE PARA TU LABORATORIO!
);
```

#### PASO 2: Verifica la Telemetría 
Corroborar la información
```sql
SELECT 
    relname AS nombre_tabla,
    n_live_tup AS filas_vivas,
    n_mod_since_analyze AS filas_modificadas,
    ROUND((n_mod_since_analyze::numeric / NULLIF(n_live_tup, 0)) * 100, 2) AS change_pct
FROM pg_stat_user_tables
WHERE relname LIKE 'lab_%'
ORDER BY change_pct DESC NULLS LAST;

```

**Salida esperada**
```
+---------------------+-------------+-------------------+------------+
|    nombre_tabla     | filas_vivas | filas_modificadas | change_pct |
+---------------------+-------------+-------------------+------------+
| lab_clientes        |       20000 |               400 |       2.00 |
| lab_productos       |       20000 |                 0 |       0.00 |
| lab_pedidos         |       20000 |                 0 |       0.00 |
| lab_detalle_pedidos |       20000 |                 0 |       0.00 |
| lab_pagos           |       20000 |                 0 |       0.00 |
| lab_envios          |       20000 |                 0 |       0.00 |
| lab_inventario      |       20000 |                 0 |       0.00 |
| lab_carritos        |       10000 |                 0 |       0.00 |
| lab_sesiones        |       20000 |                 0 |       0.00 |
| lab_logs_auditoria  |       22000 |                 0 |       0.00 |
+---------------------+-------------+-------------------+------------+
```

## Monitorear
 

### 1. MONITOREO EN VIVO DESDE `pg_stat_activity`

*(Monitorea la actividad del sistema operativo, el proceso Padre y los procesos Hijos en la memoria RAM del servidor)*

```sql
SELECT 
    pid,
    backend_type,
    usename,
    client_addr,
    state,
    clock_timestamp() - query_start AS duracion_actual,
    query
FROM pg_catalog.pg_stat_activity
WHERE (backend_type = 'pg_background' OR query ILIKE '%sp_orchestrate_maintenance%')
  AND pid <> pg_backend_pid()
ORDER BY query_start ASC;

```

---

### 2. MONITOREO FORENSE DESDE `public.maintenance_tasks`

*(Monitorea el progreso de la cola, qué tabla está corriendo, cuál terminó, cuál falló y el porcentaje de cambio/desfase)*

```sql
SELECT 
    t.task_id,
    j.job_type,
    j.maintenance_action AS accion,
    t.schema_name || '.' || t.table_name AS tabla_objetivo,
    t.total_filas,
    t.filas_afectadas,
    t.drift_pct AS porcentaje_desfase,
    t.status AS estatus_tarea,
    t.child_pid,
    COALESCE(t.ended_at, clock_timestamp()) - t.started_at AS duracion,
    COALESCE(t.error_log, 'Ninguno') AS detalle_error
FROM public.maintenance_tasks t
JOIN public.maintenance_jobs j ON t.job_id = j.job_id
WHERE t.job_id = (SELECT MAX(job_id) FROM public.maintenance_jobs)
ORDER BY t.task_id ASC;

select * from public.maintenance_jobs;

select * from public.maintenance_tasks;

```




# Para pg_background 1.4 

```SQL
CREATE OR REPLACE PROCEDURE public.sp_orchestrate_maintenance(
    p_job_type VARCHAR,                  -- 1. 'SMART', 'ALL', 'PRELOAD'
    p_parallel_workers INT,              -- 2. Cantidad de hilos paralelos
    p_verbose BOOLEAN DEFAULT FALSE,     -- 3. Diagnóstico visual en tiempo real
    p_threshold_pct NUMERIC DEFAULT 0.05,-- 4. Umbral (0.05 = 5%).
    p_min_rows INT DEFAULT 1000          -- 5. Límite de modificaciones
)
LANGUAGE plpgsql AS $$
DECLARE
    v_job_id INT;
    v_task_id INT;
    v_schema TEXT;
    v_table TEXT;
    v_child_pid INT;                     -- En v1.4 pg_background_launch retorna directamente INT (PID)
    v_active_workers INT;
    v_pending_tasks INT;
    v_total_tasks INT;
    v_raw_sql TEXT;
    v_start_time TIMESTAMPTZ := clock_timestamp();
    r_finished RECORD;                  -- Variable de registro para bucles
BEGIN
    SET client_min_messages = notice;
    IF p_verbose THEN
        RAISE INFO '=========================================================';
        RAISE INFO '[DBA SQUAD] INICIANDO ORQUESTADOR VANGUARD (PG_BACKGROUND 1.4)';
        RAISE INFO 'TIPO: % | ACCIÓN: ANALYZE | HILOS: % | UMBRAL: %%%', p_job_type, p_parallel_workers, (p_threshold_pct * 100);
        RAISE INFO '=========================================================';
    END IF;

    -- 1. Crear Job Padre
    INSERT INTO public.maintenance_jobs (job_type, maintenance_action, threshold_pct, parallel_workers, status)
    VALUES (p_job_type, 'ANALYZE', p_threshold_pct, p_parallel_workers, 'RUNNING')
    RETURNING job_id INTO v_job_id;
    COMMIT;

    -- 2. Poblar Cola
    IF p_job_type = 'SMART' THEN
        INSERT INTO public.maintenance_tasks (
            job_id, schema_name, table_name, total_filas, filas_afectadas, drift_pct
        )
        SELECT 
            v_job_id, schemaname, relname, n_live_tup, COALESCE(n_mod_since_analyze, 0),
            ROUND((COALESCE(n_mod_since_analyze, 0)::numeric / NULLIF(n_live_tup, 0)) * 100, 2)
        FROM pg_stat_user_tables
        WHERE COALESCE(n_mod_since_analyze, 0) >= p_min_rows
          AND (
              (COALESCE(n_mod_since_analyze, 0)::numeric / NULLIF(n_live_tup, 0)) >= p_threshold_pct 
              OR COALESCE(n_mod_since_analyze, 0) >= 50000 
          )
        ORDER BY COALESCE(n_mod_since_analyze, 0) DESC;
    ELSE
        INSERT INTO public.maintenance_tasks (
            job_id, schema_name, table_name, total_filas, filas_afectadas, drift_pct
        )
        SELECT 
            v_job_id, schemaname, relname, n_live_tup, COALESCE(n_mod_since_analyze, 0),
            ROUND((COALESCE(n_mod_since_analyze, 0)::numeric / NULLIF(n_live_tup, 0)) * 100, 2)
        FROM pg_stat_user_tables
        ORDER BY COALESCE(n_mod_since_analyze, 0) DESC, n_live_tup DESC;
    END IF;
    COMMIT;

    SELECT COUNT(*) INTO v_total_tasks FROM public.maintenance_tasks WHERE job_id = v_job_id;
    
    IF p_verbose THEN
        RAISE INFO '[+] JOB ID Asignado: %', v_job_id;
        RAISE INFO '[+] Total de tablas que requieren intervención: %', v_total_tasks;
        RAISE INFO '---------------------------------------------------------';
    END IF;

    IF v_total_tasks = 0 THEN
        IF p_verbose THEN RAISE INFO '[✓] El sistema está óptimo. Ninguna tabla superó los umbrales.'; END IF;
        UPDATE public.maintenance_jobs SET status = 'COMPLETED', ended_at = clock_timestamp() WHERE job_id = v_job_id;
        COMMIT;
        RETURN;
    END IF;

    -- 3. BUCLE PRINCIPAL (Monitoreo y Despacho)
    LOOP
        -- A. RECOLECTOR DE MEMORIA (PG_BACKGROUND 1.4)
        -- Se ejecuta pg_background_detach pasando únicamente el PID (INT)
        FOR r_finished IN 
            SELECT task_id, child_pid
            FROM public.maintenance_tasks 
            WHERE job_id = v_job_id AND status IN ('SUCCESS', 'FAILED') AND child_pid IS NOT NULL
        LOOP
            BEGIN
                PERFORM public.pg_background_detach(r_finished.child_pid::INT);
            EXCEPTION WHEN OTHERS THEN
                NULL; -- Ignorar si el PID ya fue desvinculado
            END;

            UPDATE public.maintenance_tasks SET child_pid = NULL WHERE task_id = r_finished.task_id;
            COMMIT;
        END LOOP;

        -- B. DETECTOR DE ZOMBIS
        WITH zombis AS (
            UPDATE public.maintenance_tasks
            SET status = 'FAILED', ended_at = clock_timestamp(), error_log = 'Process died or aborted before completion.'
            WHERE job_id = v_job_id AND status = 'RUNNING'
              AND child_pid NOT IN (SELECT pid FROM pg_stat_activity WHERE backend_type = 'pg_background')
            RETURNING task_id
        )
        SELECT count(*) FROM zombis INTO v_task_id; 
        
        IF p_verbose AND v_task_id > 0 THEN RAISE INFO '[☠️] ALERTA: Se detectaron y purgaron % procesos zombis.', v_task_id; END IF;
        COMMIT;

        -- C. REPORTE VISUAL
        IF p_verbose THEN
            FOR v_schema, v_table, v_task_id IN 
                SELECT schema_name, table_name, task_id FROM public.maintenance_tasks 
                WHERE job_id = v_job_id AND status = 'SUCCESS' AND ended_at >= (clock_timestamp() - INTERVAL '1.5 seconds')
            LOOP
                RAISE INFO '   [✓] ÉXITO -> Tabla: %.% (Task ID: %)', v_schema, v_table, v_task_id;
            END LOOP;
        END IF;

        -- D. CONTEO DE ESTADO
        SELECT COUNT(*) INTO v_active_workers FROM public.maintenance_tasks WHERE job_id = v_job_id AND status = 'RUNNING';
        SELECT COUNT(*) INTO v_pending_tasks FROM public.maintenance_tasks WHERE job_id = v_job_id AND status = 'PENDING';

        IF v_active_workers = 0 AND v_pending_tasks = 0 THEN EXIT; END IF;

        -- E. DESPACHADOR DE TAREAS (PG_BACKGROUND 1.4 NATIVO)
        WHILE v_active_workers < p_parallel_workers AND v_pending_tasks > 0 LOOP
            SELECT task_id, schema_name, table_name INTO v_task_id, v_schema, v_table
            FROM public.maintenance_tasks
            WHERE job_id = v_job_id AND status = 'PENDING' ORDER BY task_id ASC LIMIT 1;

            IF v_task_id IS NOT NULL THEN
                UPDATE public.maintenance_tasks SET status = 'RUNNING', started_at = clock_timestamp() WHERE task_id = v_task_id;
                COMMIT;

                v_raw_sql := 'SET maintenance_work_mem = ''8GB''; SET max_parallel_maintenance_workers = 4; SET vacuum_cost_delay = 0; ';

                IF p_job_type = 'PRELOAD' THEN
                    v_raw_sql := v_raw_sql || format('SET default_statistics_target = 1; ANALYZE %I.%I; ', v_schema, v_table);
                    v_raw_sql := v_raw_sql || format('SET default_statistics_target = 10; ANALYZE %I.%I; ', v_schema, v_table);
                    v_raw_sql := v_raw_sql || format('RESET default_statistics_target; ANALYZE %I.%I; ', v_schema, v_table);
                ELSE
                    v_raw_sql := v_raw_sql || format('ANALYZE %I.%I; ', v_schema, v_table);
                END IF;

                v_raw_sql := v_raw_sql || format('UPDATE public.maintenance_tasks SET status = ''SUCCESS'', ended_at = clock_timestamp() WHERE task_id = %s;', v_task_id);

                -- En pg_background v1.4, launch retorna un escalar INT directamente
                v_child_pid := public.pg_background_launch(v_raw_sql);

                UPDATE public.maintenance_tasks 
                SET child_pid = v_child_pid 
                WHERE task_id = v_task_id;
                COMMIT;

                IF p_verbose THEN 
                    RAISE INFO '   [>] LANZANDO -> Hilo PID % asignado a Tabla: %.%', v_child_pid, v_schema, v_table; 
                END IF;

                v_active_workers := v_active_workers + 1;
                v_pending_tasks := v_pending_tasks - 1;
            END IF;
        END LOOP;
        PERFORM pg_sleep(1);
    END LOOP;

    -- 4. FIN DE OPERACIONES
    UPDATE public.maintenance_jobs SET status = 'COMPLETED', ended_at = clock_timestamp() WHERE job_id = v_job_id;
    COMMIT;

    IF p_verbose THEN
        RAISE INFO '---------------------------------------------------------';
        RAISE INFO '[DBA SQUAD] ORQUESTACIÓN FINALIZADA CON ÉXITO.';
        RAISE INFO 'Tiempo Total: %', (clock_timestamp() - v_start_time);
        RAISE INFO '=========================================================';
    END IF;
END;
$$;
```
