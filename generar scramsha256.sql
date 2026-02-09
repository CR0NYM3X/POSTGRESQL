/*
 @Function: auth.fn_generate_scram_sha256
 @Creation Date: 09/02/2026
 @Description: Genera un hash compatible con SCRAM-SHA-256 para contraseñas de PostgreSQL 
                basado en RFC 5802 y la implementación nativa del motor.
 @Parameters:
   - @p_password (text): Contraseña en texto plano a hashear.
   - @p_iterations (integer): Número de iteraciones (default 4096 según estándar PG).
 @Returns: text - Cadena de hash formateada para SCRAM-SHA-256.
 @Author: CR0NYM3X
 ---------------- HISTORY ----------------
 @Date: 09/02/2026
 @Change: Creación inicial siguiendo plantilla corporativa y lógica de stackoverflow/github.
 @Author: CR0NYM3X
*/



---------------- COMMENT ----------------
COMMENT ON FUNCTION auth.fn_generate_scram_sha256(text, integer) IS
'Genera un hash SCRAM-SHA-256 compatible con el catálogo pg_authid.
- Parámetros: p_password (texto plano), p_iterations (iteraciones, defecto 4096).
- Retorno: text (formato SCRAM-SHA-256$<iter>:<salt>$<stored>:<server>).
- Volatilidad: VOLATILE (debido a la generación de salt aleatorio).
- Seguridad: SECURITY INVOKER.
- Notas: Requiere extensión pgcrypto cargada en el esquema public o dedicado.';


---------------- LOG ----------------
CREATE SCHEMA IF NOT EXISTS logs;

CREATE TABLE IF NOT EXISTS logs.functions (
    log_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status        text NOT NULL CHECK (status IN ('successful','failed')),
    db_name       text NOT NULL,
    fun_name      text NOT NULL,
    ip_client     inet,
    user_name     text NOT NULL,
    query         text,
    msg           text,
    start_time    timestamptz NOT NULL,
    date_insert   timestamptz NOT NULL DEFAULT clock_timestamp(),
    app_name      text,
    txid          bigint DEFAULT txid_current()
);


-- drop FUNCTION auth.fn_generate_scram_sha256(text,int);
CREATE OR REPLACE FUNCTION auth.fn_generate_scram_sha256(
    p_password text,
    p_iterations integer DEFAULT 4096
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
    -- Diagnóstico
    ex_message   text; 
    v_start_time timestamptz := clock_timestamp();
    v_status     text;

    -- Variables Cripto
    v_salt          bytea;
    v_salted_pass   bytea;
    v_client_key    bytea;
    v_stored_key    bytea;
    v_server_key    bytea;
    v_ui            bytea;
    v_i             integer;
    v_j             integer;
    
    -- Buffer para XOR
    v_xor_result    bytea;
    
    -- Inserción Log
    v_insert_log text := $sql$
        INSERT INTO logs.functions (fun_name, db_name, ip_client, user_name, start_time, status, msg)
        VALUES ('auth.fn_generate_scram_sha256', current_database(), 
                COALESCE(inet_client_addr(), '127.0.0.1'::inet), session_user, $1, $2, $3)
    $sql$;
BEGIN
    -- 1. Preparación inicial
    IF p_password IS NULL THEN RAISE EXCEPTION 'La contraseña no puede ser NULL'; END IF;
    
    v_salt := public.gen_random_bytes(16);

    -- 2. Implementación de Hi(P, S, i) 
    -- U1 = HMAC(P, S || INT(1))
    v_ui := public.hmac(p_password::bytea, v_salt || '\x00000001'::bytea, 'sha256');
    v_salted_pass := v_ui;

    -- Iteraciones PBKDF2
    FOR v_i IN 2..p_iterations LOOP
        v_ui := public.hmac(p_password::bytea, v_ui, 'sha256');
        
        -- XOR MANUAL BYTE A BYTE (Seguro para todas las versiones de PG)
        v_xor_result := '\x'::bytea;
        FOR v_j IN 0..31 LOOP
            v_xor_result := v_xor_result || 
                set_byte('\x00'::bytea, 0, 
                    get_byte(v_salted_pass, v_j) # get_byte(v_ui, v_j)
                );
        END LOOP;
        v_salted_pass := v_xor_result;
    END LOOP;

    -- 3. Derivación de claves SCRAM finales
    v_client_key := public.hmac(v_salted_pass, 'Client Key'::bytea, 'sha256');
    v_stored_key := public.digest(v_client_key, 'sha256');
    v_server_key := public.hmac(v_salted_pass, 'Server Key'::bytea, 'sha256');

    -- 4. Registro y Salida
    v_status := 'successful';
    EXECUTE v_insert_log USING v_start_time, v_status, 'Hash generado exitosamente (XOR manual)';

    RETURN format('SCRAM-SHA-256$%s:%s$%s:%s', 
                  p_iterations, 
                  encode(v_salt, 'base64'), 
                  encode(v_stored_key, 'base64'), 
                  encode(v_server_key, 'base64'));

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS ex_message = MESSAGE_TEXT;
        EXECUTE v_insert_log USING v_start_time, 'failed', ex_message;
        RAISE EXCEPTION 'Error crítico en SCRAM: %', ex_message;
END;
$func$;


-- Ajuste de Search Path
ALTER FUNCTION auth.fn_generate_scram_sha256(text, integer) SET search_path TO public, pg_temp;
 
REVOKE ALL ON FUNCTION auth.fn_generate_scram_sha256(text, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth.fn_generate_scram_sha256(text, integer) TO tu_usuario_aplicacion;


-- Hash generado por nuestra función
SELECT auth.fn_generate_scram_sha256('password123');

 
 



create user user_test with password 'SCRAM-SHA-256$4096:ucpFwphz7WGSLDVc5YgB0A==$ePTMKjWcZxiFNs4gEYLyQeY1z8sn2dnyaA7/cFGV3Do=:a3QgEGKhNYby4NzezPTPnd0vSS6qb06jhZ6UUfPXWPc=';

alter user user_test with encrypted password 'SCRAM-SHA-256$4096:wbmK0FEWvVHN9NY1ZZo3PA==$wNBFwGn0zpdN9Bo+S9X8LL8x8zSQnpaxAQwBGnGeKz8=:0z/F95O9qRGWM/mRNfbZiv6AUyt2dMQEBy63KqeaPfA=';

alter user user_test with  password 'password123';


select usename,passwd from pg_shadow  where usename = 'user_test';


PGPASSWORD='password123' psql -h 127.0.0.1 -p 5432 -d postgres -U user_test


