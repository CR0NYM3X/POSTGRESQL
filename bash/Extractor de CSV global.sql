DO $$
DECLARE
    -- CONFIGURACIÓN: Lista original de bases de datos
    dbs_objetivo TEXT[] :=  ARRAY['db_test'];
    -- Array auxiliar para reconstruir la lista solo con las existentes
    dbs_filtradas TEXT[] := ARRAY[]::TEXT[];
    
    db_actual TEXT;
    db_existe BOOLEAN;
    dblink_instalado_previamente BOOLEAN;
    csv_path TEXT;
    conn_str TEXT;

    -- Variables para datos de red
    v_socket TEXT;
    v_port TEXT;

    -- VARIABLES SOLICITADAS
    v_folder_name TEXT := '123123123123'; -- Puedes modificar el nombre de la carpeta aquí
    v_query_exec TEXT := 'SELECT table_name FROM information_schema.tables WHERE table_schema = ''public'' ORDER BY table_name';
BEGIN
     set client_min_messages = notice;

    -- 1. REVISAR E INSTALAR DBLINK SI ES NECESARIO
    SELECT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'dblink') INTO dblink_instalado_previamente;

    IF NOT dblink_instalado_previamente THEN
        CREATE EXTENSION dblink;
        RAISE NOTICE 'Extension dblink no encontrada. Se ha instalado temporalmente.';
    ELSE
        RAISE NOTICE 'Extension dblink ya estaba instalada. Se mantendrá al finalizar.';
    END IF;

    -- 2. PRIMER FOREACH: VALIDACIÓN Y FILTRADO
    -- Solo notifica las que NO existen y actualiza el array de trabajo
    FOREACH db_actual IN ARRAY dbs_objetivo LOOP
        SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = db_actual) INTO db_existe;
        
        IF db_existe THEN
            dbs_filtradas := array_append(dbs_filtradas, db_actual);
        ELSE
            RAISE NOTICE 'ADVERTENCIA: La base de datos "%" NO existe. Eliminada de la lista.', db_actual;
        END IF;
    END LOOP;

    -- Actualizamos la lista principal con la filtrada
    dbs_objetivo := dbs_filtradas;

    -- 3. SEGUNDO FOREACH: EJECUCIÓN DE TAREA
    -- Este bloque solo se ejecuta si hay bases de datos válidas
    IF array_length(dbs_objetivo, 1) IS NOT NULL THEN
        
        -- Obtener datos de red (Se obtienen una vez para eficiencia)
        SELECT replace(setting, ' ', '') INTO v_socket FROM pg_settings WHERE name = 'unix_socket_directories';
        SELECT setting INTO v_port FROM pg_settings WHERE name = 'port';

        -- Crear la carpeta en /tmp usando un comando de shell (Requiere permisos de superusuario)
        EXECUTE format('COPY (SELECT 1) TO PROGRAM %L', 'mkdir -p /tmp/' || v_folder_name);
        RAISE NOTICE 'Carpeta de destino asegurada en: /tmp/%', v_folder_name;

        FOREACH db_actual IN ARRAY dbs_objetivo LOOP
            BEGIN
                RAISE NOTICE 'Conectando y procesando base de datos: %...', db_actual;
                
                -- Ruta actualizada con la variable de carpeta
                csv_path := '/tmp/' || v_folder_name || '/' || db_actual || '.csv';
                
                -- Nueva forma de conexión solicitada
                conn_str := format('dbname=%L host=%s port=%s user=postgres', db_actual, v_socket, v_port);

                -- Ejecutar exportación usando v_query_exec
                PERFORM dblink_exec(conn_str, 
                    format('COPY (%s) TO %L WITH (FORMAT CSV, HEADER)', v_query_exec, csv_path)
                );

                RAISE NOTICE 'EXITO: Datos de "%" exportados correctamente en %', db_actual, csv_path;

            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'ERROR: Fallo en conexión o ejecución en "%". Detalles: %', db_actual, SQLERRM;
            END;
        END LOOP;
    ELSE
        RAISE NOTICE 'No se encontraron bases de datos válidas para procesar.';
    END IF;

    -- 4. LIMPIEZA: DESINSTALAR DBLINK SI FUE INSTALADO POR ESTA FUNCIÓN
    IF NOT dblink_instalado_previamente THEN
        DROP EXTENSION dblink;
        RAISE NOTICE 'Extension dblink desinstalada para restaurar el estado original.';
    END IF;

END $$;
