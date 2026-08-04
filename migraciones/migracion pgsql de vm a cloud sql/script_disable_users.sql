


DROP TABLE IF EXISTS public.dba_login_state_backup;

CREATE TABLE public.dba_login_state_backup (
    rolname TEXT PRIMARY KEY,
    original_can_login BOOLEAN,
    was_modified BOOLEAN, -- NUEVA COLUMNA: Check exacto de si el script le hizo un ALTER
    backup_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


DO $$
DECLARE
    -- 1. USUARIO ACTUAL (Automático)
    v_current_user TEXT := current_user;
    
    -- 2. MODO DE OPERACIÓN:
    --    TRUE  = Modo Mantenimiento (Respalda, bloquea y tumba conexiones).
    --    FALSE = Modo Rollback (Restaura SOLO a los que se les modificó el acceso).
    v_lock_mode BOOLEAN := TRUE; 
    
    -- 3. GESTIÓN DE CONEXIONES ACTIVAS:
    v_kill_connections BOOLEAN := TRUE;
    
    -- 4. EXCLUSIONES: Lista estricta de usuarios de sistema e IAM
    v_excluded_users TEXT[] := ARRAY[
        'cloudsqlsuperuser', 'cloudsqlreplica', 'cloudsqlobservability', 
        'cloudsqlimportexport', 'cloudsqlconnpooladmin', 'cloudsqlagent', 'cloudsqladmin',
        'cloudsqliamgroup', 'cloudsqliamgroupserviceaccount', 'cloudsqliamgroupuser',
        'cloudsqliamserviceaccount', 'cloudsqliamuser', 'cloudsqllogical', 
        'cloudsqlinactiveuser', 'cloudsqliamworkforceidentity',
        'pg_database_owner', 'pg_read_all_data', 'pg_write_all_data', 'pg_monitor',
        'pg_read_all_settings', 'pg_read_all_stats', 'pg_stat_scan_tables',
        'pg_read_server_files', 'pg_write_server_files', 'pg_execute_server_program',
        'pg_signal_backend', 'pg_checkpoint',
        'postgres'
    ];
    
    -- 5. INCLUSIÓN SELECTIVA (Opcional)
    v_selective_users TEXT[] := ARRAY[]::TEXT[];
    
    -- Variables internas
    r RECORD;
    v_sql TEXT;
    v_killed_count INT;
    v_remaining_connections INT;
BEGIN
    IF v_lock_mode THEN
        RAISE NOTICE '=== INICIANDO RESPALDO Y BLOQUEO DE USUARIOS ===';
        
        TRUNCATE TABLE public.dba_login_state_backup;
        
        FOR r IN 
            SELECT rolname, rolcanlogin 
            FROM pg_catalog.pg_roles 
            WHERE rolname != v_current_user
              AND NOT (rolname = ANY(v_excluded_users))
              AND rolname NOT LIKE 'pg_%'
              AND (cardinality(v_selective_users) = 0 OR rolname = ANY(v_selective_users))
        LOOP
            -- Evaluamos si el usuario será modificado (Solo si tiene LOGIN se le aplicará NOLOGIN)
            -- Si r.rolcanlogin es TRUE, was_modified será TRUE. Si es FALSE, was_modified será FALSE.
            EXECUTE format('INSERT INTO public.dba_login_state_backup (rolname, original_can_login, was_modified) VALUES (%L, %L, %L)', 
                            r.rolname, r.rolcanlogin, r.rolcanlogin);

            IF r.rolcanlogin THEN
                v_sql := format('ALTER ROLE %I NOLOGIN;', r.rolname);
                EXECUTE v_sql;
                RAISE NOTICE '  [MODIFICADO] Aplicado NOLOGIN a %', r.rolname;
                
                -- Proceso de Kill
                IF v_kill_connections THEN
                    WITH killed AS (
                        SELECT pg_terminate_backend(pid) 
                        FROM pg_stat_activity 
                        WHERE usename = r.rolname AND pid != pg_backend_pid()
                    )
                    SELECT count(*) INTO v_killed_count FROM killed;
                    
                    IF v_killed_count > 0 THEN
                        RAISE NOTICE '    -> Terminando % conexión(es)...', v_killed_count;
                        PERFORM pg_sleep(1.5); 
                        
                        SELECT count(*) INTO v_remaining_connections 
                        FROM pg_stat_activity 
                        WHERE usename = r.rolname AND pid != pg_backend_pid();
                        
                        IF v_remaining_connections > 0 THEN
                            RAISE WARNING '    [FALLO] % aún tiene % proceso(s) activos.', r.rolname, v_remaining_connections;
                        ELSE
                            RAISE NOTICE '    [ÉXITO] Conexiones terminadas.';
                        END IF;
                    END IF;
                END IF;
            ELSE
                RAISE NOTICE '  [OMITIDO] El usuario % ya era NOLOGIN. No se modificó.', r.rolname;
            END IF;
        END LOOP;
        RAISE NOTICE '=== MANTENIMIENTO APLICADO Y RESPALDADO ===';

    ELSE
        -- ============================================================================
        -- MODO ROLLBACK: Restaura SOLO a los usuarios que marcamos como "was_modified"
        -- ============================================================================
        RAISE NOTICE '=== INICIANDO RESTAURACIÓN ESTRICTA ===';
        
        FOR r IN 
            SELECT rolname, original_can_login 
            FROM public.dba_login_state_backup
            WHERE was_modified = TRUE  -- Filtro clave de seguridad
        LOOP
            -- Solo entra aquí si el usuario fue alterado por nuestro script
            IF r.original_can_login THEN
                v_sql := format('ALTER ROLE %I LOGIN;', r.rolname);
                EXECUTE v_sql;
                RAISE NOTICE 'Restaurado -> % recuperó su acceso (LOGIN)', r.rolname;
            ELSE
                -- Por seguridad de integridad (aunque lógicamente was_modified asegura que era LOGIN)
                v_sql := format('ALTER ROLE %I NOLOGIN;', r.rolname);
                EXECUTE v_sql;
                RAISE NOTICE 'Mantenido -> % se queda sin acceso (NOLOGIN)', r.rolname;
            END IF;
        END LOOP;
        
        RAISE NOTICE '=== ROLLBACK COMPLETADO CON ÉXITO ===';
    END IF;
END $$;



