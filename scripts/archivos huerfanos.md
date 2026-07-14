 
Las funciones nativas de PostgreSQL (`pg_ls_dir` y `pg_stat_file`) leen el directorio de forma relativa a tu `PGDATA`, por lo que no necesitamos salirnos a bash.

Aquí tienes el bloque anónimo en PL/pgSQL. Lo que hace es:

1. Obtiene el `OID` de tu base de datos actual.
2. Lee todo el contenido de `base/<tu_OID>/`.
3. Limpia los sufijos de los archivos (archivos segmentados `.1`, mapas de espacio `_fsm`, mapas de visibilidad `_vm`).
4. Busca ese nodo base en `pg_class`.
5. Si no está o empieza con la letra `t` (temporal de vacuum), lo marca como huérfano y lo guarda en una tabla persistente para que la analicemos.

Ejecuta este bloque tal cual en tu consola conectada a la base de datos afectada:

```sql
DO $$
DECLARE
    v_oid_db oid;
    v_ruta_base text;
    v_archivo text;
    v_relfilenode_base text;
    v_relname text;
    v_estado text;
    v_tamano bigint;
BEGIN
    -- 1. Obtener OID de la base de datos actual
    SELECT oid INTO v_oid_db FROM pg_database WHERE datname = current_database();
    v_ruta_base := 'base/' || v_oid_db;

    -- 2. Crear tabla persistente de resultados
    CREATE TABLE IF NOT EXISTS analisis_archivos_huerfanos (
        archivo text,
        relfilenode_base text,
        tabla_relacionada text,
        estado text,
        tamano_mb numeric
    );
    -- Limpiar ejecuciones previas
    TRUNCATE analisis_archivos_huerfanos;

    -- 3. Recorrer el directorio físico
    FOR v_archivo IN SELECT * FROM pg_ls_dir(v_ruta_base) LOOP
        -- Ignorar archivos del sistema
        IF v_archivo IN ('PG_VERSION', 'pg_internal.init') THEN
            CONTINUE;
        END IF;

        -- 4. Lógica de detección
        -- Si empieza con 't', es basura garantizada de un proceso fallido
        IF v_archivo LIKE 't%' THEN
            v_estado := 'HUÉRFANO TEMPORAL (Resto de Vacuum)';
            v_relfilenode_base := NULL;
            v_relname := 'NINGUNA';
        ELSE
            -- Extraer solo los números base antes de cualquier sufijo (.1, _fsm, etc)
            v_relfilenode_base := substring(v_archivo from '^[0-9]+');
            
            IF v_relfilenode_base IS NOT NULL THEN
                -- Buscar el nodo en el catálogo. (El fallback a oid es por tablas de sistema viejo)
                SELECT relname INTO v_relname 
                FROM pg_class 
                WHERE relfilenode = v_relfilenode_base::oid 
                   OR (relfilenode = 0 AND oid = v_relfilenode_base::oid);

                IF FOUND THEN
                    v_estado := 'VÁLIDO';
                ELSE
                    v_estado := 'HUÉRFANO FÍSICO (No existe en pg_class)';
                    v_relname := 'NINGUNA';
                END IF;
            ELSE
                v_estado := 'DESCONOCIDO';
                v_relname := 'N/A';
            END IF;
        END IF;

        -- 5. Obtener tamaño en disco y guardar
        -- Se captura la excepción si el archivo fue borrado milisegundos antes de leer su tamaño
        BEGIN
            SELECT size INTO v_tamano FROM pg_stat_file(v_ruta_base || '/' || v_archivo);
            
            INSERT INTO analisis_archivos_huerfanos 
            VALUES (
                v_archivo, 
                v_relfilenode_base, 
                v_relname, 
                v_estado, 
                round((v_tamano * 1.0) / 1024 / 1024, 2)
            );
        EXCEPTION WHEN OTHERS THEN
            -- Archivo no accesible, lo saltamos
            CONTINUE;
        END;
    END LOOP;
END $$;

```

---

## Cómo leer los resultados

Una vez que termine de ejecutarse (tardará unos segundos dependiendo de cuántos archivos tengas), ejecuta esta consulta para revelar exactamente a los culpables, ordenados del más pesado al más ligero:

```sql
SELECT 
    estado,
    archivo,
    tamano_mb,
    relfilenode_base
FROM analisis_archivos_huerfanos 
WHERE estado LIKE 'HUÉRFANO%'
ORDER BY tamano_mb DESC;

```

> **Qué debes buscar:** Deberías ver uno o varios archivos en la parte superior de la lista con un estado "HUÉRFANO..." y un tamaño inmenso (ej. múltiples archivos de 1024 MB o uno gigantesco, sumando cerca de 95,000 MB).
