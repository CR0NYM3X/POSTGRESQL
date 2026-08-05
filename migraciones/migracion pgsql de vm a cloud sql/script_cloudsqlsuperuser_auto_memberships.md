

### FASE 1: La Estructura de Auditoría  

Primero, creamos el esquema y la tabla de bitácora (*State Table*). Esta tabla será nuestra fuente de verdad. Registrará quién fue agregado, cuándo, y si la membresía está activa.

```sql
-- 1. Crear un esquema dedicado a la administración interna (Mejor práctica)
CREATE SCHEMA IF NOT EXISTS dba_admin;

-- 2. Crear la tabla de estado y bitácora
CREATE TABLE IF NOT EXISTS dba_admin.audit_role_memberships (
    target_user TEXT NOT NULL,       -- El usuario que recibe el poder (ej. cloudsqlsuperuser)
    granted_role TEXT NOT NULL,      -- El usuario del cual nos hicimos miembros
    is_active BOOLEAN NOT NULL,      -- TRUE si fue agregado por el script, FALSE si se hizo rollback
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- Cuándo se agregó por primera vez
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, -- Última fecha de actualización (Rollback/Re-Grant)
    PRIMARY KEY (target_user, granted_role)
);

-- Comentario para el diccionario de datos
COMMENT ON TABLE dba_admin.audit_role_memberships IS 'Bitácora de DBA SQUAD para automatización de membresías y Rollback';

```

---

### FASE 2: El Motor Lógico (Por Pedro - Desarrollo Core)

Este procedimiento almacenado recibe el modo (`GRANT` o `ROLLBACK`). Usa `ON CONFLICT` (Upsert) para mantener la tabla actualizada sin duplicar registros, y `pg_has_role()` para jamás ejecutar código redundante.

```sql
CREATE OR REPLACE PROCEDURE dba_admin.sp_auto_manage_memberships(
    p_target_user TEXT DEFAULT 'cloudsqlsuperuser',
    p_mode TEXT DEFAULT 'GRANT' -- Opciones válidas: 'GRANT', 'ROLLBACK'
)
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    v_sql TEXT;
    -- Exclusiones estrictas. Usamos pg_roles para incluir roles sin login (NOLOGIN)
    v_excluded_users TEXT[] := ARRAY[
        'cloudsqlsuperuser', 'cloudsqladmin', 'postgres', 
        'pg_database_owner', 'pg_read_all_data', 'pg_write_all_data', 'pg_monitor'
    ];
    v_registros_procesados INT := 0;
BEGIN
    IF p_mode = 'GRANT' THEN
        -- ========================================================
        -- MODO GRANT: Hacerse miembro de todos los que falten
        -- ========================================================
        FOR r IN 
            SELECT rolname 
            FROM pg_catalog.pg_roles 
            WHERE rolname != p_target_user
              AND NOT (rolname = ANY(v_excluded_users))
              AND rolname NOT LIKE 'pg_%'
        LOOP
            -- VALIDACIÓN TÁCTICA: ¿Ya somos miembros?
            -- Retorna TRUE si p_target_user ya es miembro de r.rolname
            IF NOT pg_has_role(p_target_user, r.rolname, 'MEMBER') THEN
                
                -- 1. Ejecutar la acción
                v_sql := format('GRANT %I TO %I;', r.rolname, p_target_user);
                EXECUTE v_sql;
                
                -- 2. Actualizar Bitácora (Upsert: Inserta si no existe, actualiza si ya existía pero estaba en FALSE)
                INSERT INTO dba_admin.audit_role_memberships (target_user, granted_role, is_active, updated_at)
                VALUES (p_target_user, r.rolname, TRUE, CURRENT_TIMESTAMP)
                ON CONFLICT (target_user, granted_role) 
                DO UPDATE SET is_active = TRUE, updated_at = CURRENT_TIMESTAMP;
                
                v_registros_procesados := v_registros_procesados + 1;
                RAISE INFO 'GRANT EJECUTADO: % es ahora miembro de %', p_target_user, r.rolname;
            END IF;
        END LOOP;
        
        RAISE NOTICE 'PROCESO GRANT FINALIZADO. Nuevos miembros agregados: %', v_registros_procesados;

    ELSIF p_mode = 'ROLLBACK' THEN
        -- ========================================================
        -- MODO ROLLBACK: Revocar SOLO lo que nosotros agregamos
        -- ========================================================
        FOR r IN 
            SELECT granted_role 
            FROM dba_admin.audit_role_memberships 
            WHERE target_user = p_target_user AND is_active = TRUE
        LOOP
            -- VALIDACIÓN: Verificar si AÚN somos miembros antes de revocar (evita errores si alguien lo quitó manual)
            IF pg_has_role(p_target_user, r.granted_role, 'MEMBER') THEN
                
                -- 1. Ejecutar reversión
                v_sql := format('REVOKE %I FROM %I;', r.granted_role, p_target_user);
                EXECUTE v_sql;
                
                -- 2. Marcar en la bitácora como inactivo
                UPDATE dba_admin.audit_role_memberships 
                SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP
                WHERE target_user = p_target_user AND granted_role = r.granted_role;
                
                v_registros_procesados := v_registros_procesados + 1;
                RAISE INFO 'ROLLBACK EJECUTADO: % ya NO es miembro de %', p_target_user, r.granted_role;
            END IF;
        END LOOP;
        
        RAISE NOTICE 'PROCESO ROLLBACK FINALIZADO. Permisos revocados: %', v_registros_procesados;

    ELSE
        RAISE EXCEPTION 'Modo de ejecución inválido (%). Usa "GRANT" o "ROLLBACK".', p_mode;
    END IF;
END;
$$;

```

---

### FASE 3: Orquestación y Pruebas (Cómo usarlo)

**1. Para ejecutarlo manualmente y que asimile a todos los usuarios actuales:**

```sql
CALL dba_admin.sp_auto_manage_memberships('cloudsqlsuperuser', 'GRANT');

```

*Si lo ejecutas 5 veces seguidas, las últimas 4 veces terminará en 0 milisegundos y dirá `Nuevos miembros agregados: 0`, garantizando eficiencia absoluta.*

**2. Para consultar tu bitácora de auditoría:**

```sql
SELECT target_user, granted_role, is_active, created_at, updated_at 
FROM dba_admin.audit_role_memberships
ORDER BY updated_at DESC;

```

**3. Para ejecutar el botón del pánico (Rollback):**
Si algo sale mal o la auditoría de seguridad te exige deshacer los permisos:

```sql
CALL dba_admin.sp_auto_manage_memberships('cloudsqlsuperuser', 'ROLLBACK');

```

---

### FASE 4: Automatización Nocturna en GCP (Por Samuel)

Como solicitaste, el objetivo final es que esta tarea vigile en las noches si alguien creó un usuario nuevo durante el día. En Cloud SQL usamos la extensión `pg_cron`.

Conectado como `cloudsqlsuperuser` a la base de datos principal (`postgres`), programa la tarea para que corra **todos los días a las 2:00 AM**:

```sql
-- Asegurar que la extensión existe
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Programar la ejecución nocturna
SELECT cron.schedule(
    'Mantenimiento_Membresias_CloudSQL', -- Nombre de la tarea
    '0 2 * * *',                         -- A las 2:00 AM todos los días
    $$ CALL dba_admin.sp_auto_manage_memberships('cloudsqlsuperuser', 'GRANT'); $$
);

```
