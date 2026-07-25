 
### 1. Script de Ajuste de Parámetros (`SET` / `ALTER SYSTEM`)
 

```sql
-- =============================================================================
-- DBA SQUAD: CONFIGURACIÓN DE PARÁMETROS DE AUDITORÍA (pgaudit / Cloud SQL)
-- =============================================================================

-- Activa la extensión de auditoría global en el motor (Requiere reinicio del servicio)
ALTER SYSTEM SET cloudsql.enable_pgaudit = 'on';

-- Formato del prefijo de traza: incluye timestamp, PID, contador de sesión, BD y usuario
ALTER SYSTEM SET cloudsql.audit_log_line_prefix = '%m [%p]: [%l-1] db=%d,user=%u';

-- Tamaños de bloque de memoria (90 KB) para gestionar logs de auditoría extensos
ALTER SYSTEM SET cloudsql.pgaudit_chunksize = '92160';

-- Define la categoría general de eventos a auditar (se mantiene deshabilitada por defecto)
ALTER SYSTEM SET pgaudit.log = 'none';

-- Registra consultas que acceden o modifican el catálogo/diccionario de datos (Seguridad Anti-Typosquatting)
ALTER SYSTEM SET pgaudit.log_catalog = 'off';

-- Desactiva la salida de mensajes de auditoría hacia el cliente para evitar fugas de información
ALTER SYSTEM SET pgaudit.log_client = 'off';

-- Establece el nivel de severidad de la bitácora en 'log' para el sistema operativo
ALTER SYSTEM SET pgaudit.log_level = 'log';

-- Desactiva el registro plano de parámetros en consultas para proteger datos sensibles (PII)
ALTER SYSTEM SET pgaudit.log_parameter = 'off';

-- Evita el registro detallado por cada relación/tabla individual en operaciones masivas
ALTER SYSTEM SET pgaudit.log_relation = 'off';

-- Desactiva el registro de filas afectadas individualmente para no saturar el almacenamiento
ALTER SYSTEM SET pgaudit.log_rows = 'off';

-- Fuerza el registro de todas las sentencias ejecutadas por superusuarios (Trazabilidad Forense)
ALTER SYSTEM SET pgaudit.log_statement = 'on';

-- Registra cada iteración de sentencia sin omitir repeticiones dentro de la misma sesión
ALTER SYSTEM SET pgaudit.log_statement_once = 'off';

-- Permite definir un rol específico de auditoría (vacío por defecto para cobertura transversal)
ALTER SYSTEM SET pgaudit.role = '';

-- Aplicar cambios en caliente para parámetros con contexto 'sighup'
SELECT pg_reload_conf();

```
