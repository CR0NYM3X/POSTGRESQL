 
# 🐘 PostgreSQL Cheat Sheet: Consultas Frecuentes para DBA y Diagnóstico

Este documento contiene una recopilación de snippets de código SQL esenciales para la administración, monitoreo, análisis de espacio y gestión de permisos en PostgreSQL.

---

## 📌 Tabla de Contenidos

* [1. Monitoreo y Sesiones Activas](https://www.google.com/search?q=%231-monitoreo-y-sesiones-activas)
* [2. Análisis de Espacio y Almacenamiento](https://www.google.com/search?q=%232-an%C3%A1lisis-de-espacio-y-almacenamiento)
* [3. Inventario de Objetos del Sistema](https://www.google.com/search?q=%233-inventario-de-objetos-del-sistema)
* [4. Seguridad y Roles](https://www.google.com/search?q=%234-seguridad-y-roles)
* [5. Mantenimiento y Configuración del Sistema](https://www.google.com/search?q=%235-mantenimiento-y-configuraci%C3%B3n-del-sistema)

---

## 1. Monitoreo y Sesiones Activas

### 🔍 Ver Consultas Activas en Tiempo Real (`pg_stat_activity`)

Muestra las consultas que se están ejecutando actualmente en la base de datos, excluyendo la conexión actual.

```sql
SELECT 
    pid, 
    usename AS usuario, 
    datname AS base_datos, 
    client_addr AS ip_cliente, 
    application_name AS aplicacion, 
    age(clock_timestamp(), query_start) AS duracion, 
    wait_event_type || ':' || wait_event AS evento_espera, 
    left(query, 100) AS query_recortada,
    query
FROM pg_stat_activity 
WHERE state = 'active' 
  AND pid != pg_backend_pid()
ORDER BY query_start ASC;

```

---

## 2. Análisis de Espacio y Almacenamiento

### 💾 Tamaño Global por Base de Datos

Lista todas las bases de datos de la instancia ordenadas desde la más pesada a la más ligera.

```sql
SELECT 
    d.datname AS base_de_datos,
    pg_catalog.pg_get_userbyid(d.datdba) AS dueño,
    pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname)) AS tamaño_legible,
    pg_catalog.pg_database_size(d.datname) AS tamaño_en_bytes
FROM pg_catalog.pg_database d
ORDER BY pg_catalog.pg_database_size(d.datname) DESC;

```

### 📊 Tamaño Detallado de Tablas vs. Índices (Recomendado)

Desglosa el espacio de cada tabla separando el peso de los **datos**, los **índices** y el **peso total**.

```sql
SELECT 
    schemaname AS esquema,
    tablename AS tabla,
    pg_size_pretty(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename))) AS tamano_total,
    pg_size_pretty(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename))) AS tamano_tabla,
    pg_size_pretty(pg_indexes_size(quote_ident(schemaname) || '.' || quote_ident(tablename))) AS tamano_indices
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)) DESC;

```

### 📈 Tamaño de Tablas y Estimación de Filas Rápidas

Consulta ligera basada en estadísticas para obtener el total de filas estimadas (`live_tuples`).

```sql
SELECT 
    nspname AS esquema,
    relname AS tabla,
    pg_catalog.pg_size_pretty(pg_catalog.pg_total_relation_size(c.oid)) AS tamaño_total,
    pg_catalog.pg_stat_get_live_tuples(c.oid) AS filas_estimadas
FROM pg_catalog.pg_class c
LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND c.relkind = 'r'
  AND pg_catalog.pg_total_relation_size(c.oid) > 0
ORDER BY pg_catalog.pg_total_relation_size(c.oid) DESC;

```

---

## 3. Inventario de Objetos del Sistema

### 📦 Resumen General de Objetos por Esquema

Muestra un conteo completo de objetos (tablas, vistas, funciones, procedimientos, secuencias, etc.) agrupados por cada esquema del usuario.

```sql
SELECT 
    n.nspname AS esquema,
    (SELECT count(*) FROM pg_class WHERE relnamespace = n.oid AND relkind IN ('r', 'p')) AS tablas,
    (SELECT count(*) FROM pg_class WHERE relnamespace = n.oid AND relkind = 'v') AS vistas,
    (SELECT count(*) FROM pg_class WHERE relnamespace = n.oid AND relkind = 'm') AS vistas_materializadas,
    (SELECT count(*) FROM pg_class WHERE relnamespace = n.oid AND relkind = 'S') AS secuencias,
    (SELECT count(*) FROM pg_proc WHERE pronamespace = n.oid AND prokind IN ('f', 'a', 'w')) AS funciones,
    (SELECT count(*) FROM pg_proc WHERE pronamespace = n.oid AND prokind = 'p') AS procedimientos,
    (SELECT count(*) FROM pg_extension WHERE extnamespace = n.oid) AS extensiones,
    (SELECT count(*) 
     FROM pg_type t 
     WHERE t.typnamespace = n.oid 
       AND t.typtype IN ('b', 'c', 'd', 'e', 'r', 'm')
       AND t.typname NOT LIKE '\_%'
       AND (t.typrelid = 0 OR (SELECT relkind FROM pg_class WHERE oid = t.typrelid) = 'c')
    ) AS tipos
FROM pg_namespace n
WHERE n.nspname NOT LIKE 'pg_toast%' 
  AND n.nspname NOT LIKE 'pg_temp%'
  AND n.nspname NOT IN ('information_schema', 'pg_catalog') 
ORDER BY n.nspname;

```

---

## 4. Seguridad y Roles

### 👥 Jerarquía y Asignación de Roles / Permisos

Muestra la relación entre roles superiores (grupos) y los miembros asignados, indicando quién otorgó el permiso.

```sql
SELECT 
    r.rolname AS rol_principal,
    m.rolname AS miembro_asignado,
    c.rolname AS asignado_por
FROM pg_auth_members a
JOIN pg_roles r ON a.roleid = r.oid
JOIN pg_roles m ON a.member = m.oid
JOIN pg_roles c ON a.grantor = c.oid
ORDER BY rol_principal, miembro_asignado;

```

### 🔐 Cambiar Propietario (Owner) de una Base de Datos

```sql
-- Transferir propiedad a Cloud SQL Superuser
ALTER DATABASE db_test OWNER TO cloudsqlsuperuser;

-- Transferir propiedad al usuario estándar
ALTER DATABASE db_test OWNER TO postgres2;

```

---

## 5. Mantenimiento y Configuración del Sistema

### 🛠️ Consultar Parámetros de Keepalive y Red

Muestra la configuración activa del sistema referente a tiempos de espera y detección de conexiones muertas.

```sql
SELECT name, setting 
FROM pg_settings 
WHERE name ILIKE '%keepalives%';

```

### ⚡ Recrear una Base de Datos desde Cero

> ⚠️ **Atención:** Esto eliminará la base de datos de forma permanente antes de crearla de nuevo.

```sql
DROP DATABASE IF EXISTS db_test;
CREATE DATABASE db_test;

```
