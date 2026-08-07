 
### FASE 1: RE-ESTRUCTURACIÓN DE LA BITÁCORA (Gobernanza)

Para cumplir con tu regla de "solo hacer rollback a lo que el script movió", necesitamos modificar el diccionario de datos. Agregamos la bandera booleana `granted_by_script`. Si ya era miembro, esta bandera será `FALSE` y el Rollback la ignorará por completo.

```sql
-- 1. Crear la tabla de bitácora e historial de auditoría (Versión 2.0 - State Aware)
-- DROP TABLE  public.audit_role_memberships;
CREATE TABLE IF NOT EXISTS public.audit_role_memberships (
    target_user TEXT NOT NULL,         -- Usuario que recibe el poder (ej. postgres)
    granted_role TEXT NOT NULL,        -- Rol/Usuario evaluado
    is_active BOOLEAN NOT NULL,        -- TRUE si es miembro actualmente, FALSE si no lo es o falló
    granted_by_script BOOLEAN NOT NULL DEFAULT FALSE, -- TRUE solo si ESTE script le dio el GRANT
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- Fecha de primera detección
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- Última fecha de modificación
    error_message TEXT,                -- Registro de excepciones o estados (Preexistente / OK / ERROR)
    PRIMARY KEY (target_user, granted_role)
);

COMMENT ON TABLE public.audit_role_memberships 
IS 'Bitácora oficial de DBA SQUAD. Registra preexistencias y permite un Rollback Quirúrgico.';

```

---

### FASE 2: EL MOTOR DE INYECCIÓN Y AUDITORÍA (`DO $$`)

 
```sql
DO $$
DECLARE
    -- =========================================================================
    -- 1. PARÁMETROS DE CONFIGURACIÓN PRINCIPAL
    -- =========================================================================
    v_target_user TEXT := 'postgres';
    v_mode TEXT := 'GRANT'; -- Cambia a 'ROLLBACK' cuando necesites reversa

    -- =========================================================================
    -- 2. LISTAS DE INCLUSIÓN Y EXCLUSIÓN (Control Total del Usuario)
    -- =========================================================================
    v_included_users_only TEXT[] := ARRAY[]::TEXT[]; 

    v_excluded_users_grant TEXT[] := ARRAY[
        'cloudsqladmin'
    ];

    v_excluded_users_rollback TEXT[] := ARRAY[
        'cloudsqladmin', 'cloudsqlsuperuser'
    ];

    -- Variables internas
    r RECORD;
    v_sql TEXT;
    v_procesados INT := 0;
    v_fallidos INT := 0;
    v_err_msg TEXT;
    v_is_already_member BOOLEAN;
BEGIN
    -- =========================================================================
    -- FASE 1: SINCRONIZACIÓN ABSOLUTA DEL CATÁLOGO 
    -- =========================================================================
    INSERT INTO public.audit_role_memberships (target_user, granted_role, is_active, granted_by_script, error_message)
    SELECT 
        v_target_user, 
        roles.rolname, 
        EXISTS (
            SELECT 1 
            FROM pg_catalog.pg_auth_members am
            JOIN pg_catalog.pg_roles m ON am.member = m.oid
            WHERE am.roleid = roles.oid AND m.rolname = v_target_user
        ), 
        FALSE, 
        'INFO: Sincronización base del catálogo.'
    FROM pg_catalog.pg_roles roles
    WHERE roles.rolname != v_target_user
    ON CONFLICT (target_user, granted_role) 
    DO UPDATE SET 
        is_active = EXCLUDED.is_active,
        updated_at = CURRENT_TIMESTAMP,
        error_message = 'INFO: Cambio de estado detectado en sincronización.'
    WHERE public.audit_role_memberships.is_active != EXCLUDED.is_active;

    -- =========================================================================
    -- FASE 1.5: CAZAFANTASMAS (Sincronización de roles eliminados manualmente)
    -- =========================================================================
    UPDATE public.audit_role_memberships
    SET 
        error_message = 'INFO: El rol fue eliminado del motor (DROP manual detectado).',
        is_active = FALSE,
        granted_by_script = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE target_user = v_target_user
      AND granted_role NOT IN (SELECT rolname FROM pg_catalog.pg_roles)
      AND error_message != 'INFO: El rol fue eliminado del motor (DROP manual detectado).';

    -- =========================================================================
    -- FASE 2: EJECUCIÓN TÁCTICA Y TOMA DE DECISIONES
    -- =========================================================================
    IF v_mode = 'GRANT' THEN
        FOR r IN 
            SELECT rolname FROM pg_catalog.pg_roles WHERE rolname != v_target_user
        LOOP
            BEGIN
                IF array_length(v_included_users_only, 1) > 0 AND NOT (r.rolname = ANY(v_included_users_only)) THEN
                    UPDATE public.audit_role_memberships SET error_message = 'INFO: Ignorado (Fuera de lista de inclusión)' WHERE target_user = v_target_user AND granted_role = r.rolname;
                    CONTINUE;
                END IF;

                IF (r.rolname = ANY(v_excluded_users_grant)) THEN
                    UPDATE public.audit_role_memberships SET error_message = 'INFO: Ignorado (Regla de Exclusión definida por el usuario)' WHERE target_user = v_target_user AND granted_role = r.rolname;
                    CONTINUE;
                END IF;

                SELECT is_active INTO v_is_already_member 
                FROM public.audit_role_memberships 
                WHERE target_user = v_target_user AND granted_role = r.rolname;

                IF NOT v_is_already_member THEN
                    v_sql := format('GRANT %I TO %I;', r.rolname, v_target_user);
                    EXECUTE v_sql;
                    
                    UPDATE public.audit_role_memberships 
                    SET is_active = TRUE, granted_by_script = TRUE, updated_at = CURRENT_TIMESTAMP, error_message = 'OK: GRANT otorgado por script'
                    WHERE target_user = v_target_user AND granted_role = r.rolname;
                    
                    v_procesados := v_procesados + 1;
                ELSE
                    UPDATE public.audit_role_memberships 
                    SET error_message = 'INFO: Membresía preexistente confirmada.'
                    WHERE target_user = v_target_user AND granted_role = r.rolname AND granted_by_script = FALSE;
                END IF;

            EXCEPTION WHEN OTHERS THEN
                v_err_msg := SQLERRM;
                v_fallidos := v_fallidos + 1;
                UPDATE public.audit_role_memberships 
                SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP, error_message = 'ERROR CRÍTICO: ' || v_err_msg
                WHERE target_user = v_target_user AND granted_role = r.rolname;
            END;
        END LOOP;
        
        RAISE NOTICE '=== FASE DE GRANT FINALIZADA === | Otorgados Nuevos: % | Fallidos: %', v_procesados, v_fallidos;

    ELSIF v_mode = 'ROLLBACK' THEN
        FOR r IN 
            SELECT granted_role FROM public.audit_role_memberships 
            WHERE target_user = v_target_user 
              AND is_active = TRUE 
              AND granted_by_script = TRUE 
        LOOP
            BEGIN
                IF array_length(v_included_users_only, 1) > 0 AND NOT (r.granted_role = ANY(v_included_users_only)) THEN
                    CONTINUE;
                END IF;

                IF (r.granted_role = ANY(v_excluded_users_rollback)) THEN
                    CONTINUE;
                END IF;

                v_sql := format('REVOKE %I FROM %I;', r.granted_role, v_target_user);
                EXECUTE v_sql;

                UPDATE public.audit_role_memberships 
                SET is_active = FALSE, granted_by_script = FALSE, updated_at = CURRENT_TIMESTAMP, error_message = 'OK: ROLLBACK EXITOSO. Permiso revocado.'
                WHERE target_user = v_target_user AND granted_role = r.granted_role;
                
                v_procesados := v_procesados + 1;

            EXCEPTION WHEN OTHERS THEN
                v_err_msg := SQLERRM;
                v_fallidos := v_fallidos + 1;
                UPDATE public.audit_role_memberships 
                SET updated_at = CURRENT_TIMESTAMP, error_message = 'ERROR ROLLBACK: ' || v_err_msg
                WHERE target_user = v_target_user AND granted_role = r.granted_role;
            END;
        END LOOP;
        
        RAISE NOTICE '=== ROLLBACK QUIRÚRGICO FINALIZADO === | Revocados: % | Fallidos: %', v_procesados, v_fallidos;

    ELSE
        RAISE EXCEPTION 'Modo de ejecución inválido ("%"). Usa "GRANT" o "ROLLBACK".', v_mode;
    END IF;
END $$;
```

---

 

-----------




### FASE 3: AUTOMATIZACIÓN EN `pg_cron` (Ejecución Nocturna)

*A cargo de Samuel (S.O. y Automatización)*

Conéctate a la base de datos `postgres` como `cloudsqlsuperuser` y programa la tarea para que se ejecute **todos los días a las 02:00 AM**:

```sql
SELECT cron.schedule(
    'Mantenimiento_Membresias_Seguras', -- Nombre de la tarea
    '0 2 * * *',                          -- Expresión Cron (02:00 AM diario)
    $script_cron$
DO $$
DECLARE
    -- =========================================================================
    -- 1. PARÁMETROS PRINCIPALES
    -- =========================================================================
    v_target_user TEXT := 'postgres';
    
    -- =========================================================================
    -- 2. FILTROS
    -- =========================================================================
    v_included_users_only TEXT[] := ARRAY[]::TEXT[]; 
    v_excluded_users_grant TEXT[] := ARRAY['cloudsqladmin'];

    -- =========================================================================
    -- 3. VARIABLES INTERNAS
    -- =========================================================================
    r RECORD;
    v_sql TEXT;
    v_procesados INT := 0;
BEGIN
    -- =========================================================================
    -- FASE 1: CAZAFANTASMAS (Sincronización de roles eliminados manualmente)
    -- =========================================================================
    UPDATE public.audit_role_memberships
    SET 
        error_message = 'INFO: El rol fue eliminado del motor (DROP manual detectado).',
        is_active = FALSE,
        granted_by_script = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE target_user = v_target_user
      AND granted_role NOT IN (SELECT rolname FROM pg_catalog.pg_roles)
      AND error_message != 'INFO: El rol fue eliminado del motor (DROP manual detectado).';

    -- =========================================================================
    -- FASE 2: MOTOR DELTA INTELIGENTE (Procesa roles nuevos o revocados)
    -- =========================================================================
    FOR r IN 
        SELECT roles.rolname, roles.oid 
        FROM pg_catalog.pg_roles roles
        LEFT JOIN public.audit_role_memberships arm 
          ON roles.rolname = arm.granted_role AND arm.target_user = v_target_user
        WHERE roles.rolname != v_target_user 
          AND (
              -- CASO A: El rol no existe en nuestra bitácora (100% Nuevo)
              arm.granted_role IS NULL 
              
              -- CASO B: Está en la bitácora, pero físicamente NO somos miembros 
              OR NOT EXISTS (          
                  SELECT 1 FROM pg_catalog.pg_auth_members am
                  JOIN pg_catalog.pg_roles m ON am.member = m.oid
                  WHERE am.roleid = roles.oid AND m.rolname = v_target_user
              )
          )
    LOOP
        BEGIN
            -- 1. Registrar intención en la bitácora
            INSERT INTO public.audit_role_memberships (target_user, granted_role, is_active, granted_by_script, error_message)
            VALUES (v_target_user, r.rolname, FALSE, FALSE, 'INFO: Evaluación Delta iniciada.')
            ON CONFLICT (target_user, granted_role) 
            DO UPDATE SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP;

            -- 2. Filtros de Exclusión
            IF array_length(v_included_users_only, 1) > 0 AND NOT (r.rolname = ANY(v_included_users_only)) THEN
                UPDATE public.audit_role_memberships SET error_message = 'INFO: Ignorado (Fuera de lista de inclusión)' WHERE target_user = v_target_user AND granted_role = r.rolname;
                CONTINUE;
            END IF;

            IF (r.rolname = ANY(v_excluded_users_grant)) THEN
                UPDATE public.audit_role_memberships SET error_message = 'INFO: Ignorado (Regla de Exclusión)' WHERE target_user = v_target_user AND granted_role = r.rolname;
                CONTINUE;
            END IF;

            -- 3. Ejecución del GRANT
            v_sql := format('GRANT %I TO %I;', r.rolname, v_target_user);
            EXECUTE v_sql;
            
            UPDATE public.audit_role_memberships 
            SET is_active = TRUE, granted_by_script = TRUE, updated_at = CURRENT_TIMESTAMP, error_message = 'OK: GRANT otorgado por script (Cron Nocturno)'
            WHERE target_user = v_target_user AND granted_role = r.rolname;
            
            v_procesados := v_procesados + 1;

        EXCEPTION WHEN OTHERS THEN
            UPDATE public.audit_role_memberships 
            SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP, error_message = 'ERROR CRÍTICO: ' || SQLERRM
            WHERE target_user = v_target_user AND granted_role = r.rolname;
        END;
    END LOOP;
    
    -- El cron de PostgreSQL captura los RAISE LOG en sus propios archivos de registro sin inundar la consola
    RAISE LOG '=== CAZADOR NOCTURNO FINALIZADO === Roles procesados/reparados: %', v_procesados;
END $$;
    $script_cron$
);

```

## Ver tareas 
```
SELECT jobid, jobname, schedule, command 
FROM cron.job 
WHERE jobname = 'Mantenimiento_Membresias_Seguras';
```

* **Para ver el historial de ejecuciones de `pg_cron`:**
```sql
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;

```

---

### FASE 4: MANTENIMIENTO LIGERO Y TUNING DE AUTOVACUUM (Zero Downtime)

 
---

### 📊 CONSULTAS DE AUDITORÍA Y MONITOREO

* **Para ver los errores capturados por el script:**
```sql
SELECT target_user, granted_role, is_active, updated_at, error_message 
FROM public.audit_role_memberships 
WHERE error_message LIKE 'ERROR%'
ORDER BY updated_at DESC;

```


* **Para ver la bitácora completa de asignaciones:**
```sql
SELECT * FROM public.audit_role_memberships ORDER BY updated_at DESC;
```




## Ver los roles a los que eres miembro
```sql
SELECT 
    r.rolname AS rol_principal,
    m.rolname AS miembro_asignado,
    c.rolname AS asignado_por
FROM pg_auth_members a
JOIN pg_roles r ON a.roleid = r.oid
JOIN pg_roles m ON a.member = m.oid
JOIN pg_roles c ON a.grantor = c.oid
where m.rolname  = 'postgres'
ORDER BY rol_principal, miembro_asignado;
```
---


## Probar herramienta 
```sql

create user  nuevo_usuario_admin;
create user  nuevo_usuario_admin2;
create user  nuevo_usuario_admin3;


CREATE TABLE public.instancias_cloud_sql (
    id SERIAL PRIMARY KEY,
    nombre_instancia VARCHAR(100) NOT NULL,
    edicion VARCHAR(50) NOT NULL, -- Enterprise / Enterprise Plus
    tiene_ha BOOLEAN DEFAULT false,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO public.instancias_cloud_sql (nombre_instancia, edicion, tiene_ha) 
VALUES 
    ('psql-ec-hcl-be-tvirtual-dev05', 'Enterprise', false),
    ('csql-postgres-ec-gcobranza-prod-01', 'Enterprise', true),
    ('csql-postgres-core-prod-02', 'Enterprise Plus', true);


ALTER TABLE public.instancias_cloud_sql OWNER TO nuevo_usuario_admin;

alter table public.instancias_cloud_sql add COLUMN num int;

revoke all privileges on all tables in schema public from  nuevo_usuario_admin;
revoke all privileges on all tables in schema public from  nuevo_usuario_admin2;
revoke all privileges on all tables in schema public from  nuevo_usuario_admin3;

drop table public.instancias_cloud_sql1;
drop table public.instancias_cloud_sql2;
drop table public.instancias_cloud_sql3;


drop user  nuevo_usuario_admin;
drop user  nuevo_usuario_admin2;
drop user  nuevo_usuario_admin3;

```

 
