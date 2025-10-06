
## 🛠️ ¿Qué es pgloader?

**pgloader** es una herramienta **open source** diseñada para migrar datos desde múltiples fuentes hacia PostgreSQL. Soporta motores como:

- **MySQL**
- **SQLite**
- **Microsoft SQL Server**
- **CSV, DBF, IXF, archivos ZIP/TAR/GZ**
- **Otros PostgreSQL**

Utiliza el protocolo `COPY` de PostgreSQL para una carga rápida y eficiente [1](https://pgloader.readthedocs.io/en/latest/index.html).

---

## ✅ ¿Qué puede migrar pgloader?

- **Esquemas**: tablas, columnas, tipos de datos, índices, claves primarias y foráneas.
- **Datos**: registros completos, con transformaciones en tiempo real.
- **Tipos de datos**: realiza conversiones automáticas entre tipos incompatibles.
- **Secuencias e índices**: puede recrearlos en el destino.
- **Transformaciones**: permite modificar datos al vuelo (casting, limpieza, proyecciones).
- **Carga paralela**: mejora el rendimiento en migraciones grandes.
 
## ✅ Ventajas de pgloader (para contexto)

- Migración automática de esquemas y datos
- Conversión de tipos entre motores
- Carga paralela optimizada
- Transformaciones básicas en vuelo
- Soporte para múltiples fuentes (MySQL, SQLite, CSV, etc.)

 

## ❌ ¿Qué NO hace pgloader?

Aquí tienes una lista detallada de las funciones que **pgloader no cubre**:

### 1. **No migra procedimientos almacenados**
- MySQL usa SQL/PSM, mientras que PostgreSQL usa PL/pgSQL.
- Las funciones, triggers y procedimientos deben ser **reescritos manualmente**.

### 2. **No migra funciones definidas por el usuario**
- Cualquier lógica embebida en funciones debe ser exportada y adaptada.

### 3. **No migra eventos programados (event scheduler)**
- PostgreSQL no tiene un equivalente directo; se recomienda usar `pg_cron` o tareas externas.

### 4. **No migra privilegios ni roles personalizados**
- Los permisos (`GRANT`, `REVOKE`) deben ser reconstruidos en PostgreSQL.

### 5. **No migra configuraciones del servidor MySQL**
- Variables como `sql_mode`, `innodb_buffer_pool_size`, etc., no tienen equivalentes automáticos.

### 6. **No migra vistas materializadas**
- Las vistas deben ser recreadas manualmente, especialmente si dependen de funciones.

### 7. **No migra claves externas con ON UPDATE CASCADE**
- PostgreSQL requiere definición explícita y puede tener diferencias semánticas.

### 8. **No migra índices FULLTEXT**
- PostgreSQL usa `GIN` o `TSVECTOR`, que deben configurarse manualmente.

### 9. **No migra tipos específicos como ENUM, SET, BLOB**
- Aunque puede convertirlos a `TEXT` o `BYTEA`, no respeta la semántica original.

### 10. **No realiza validaciones de integridad post-migración**
- No compara checksums, ni verifica consistencia entre origen y destino.
 
## 🧩 Casos de uso reales donde pgloader **no es suficiente**

- Migraciones de sistemas bancarios con lógica compleja en procedimientos
- Aplicaciones con uso intensivo de `FULLTEXT SEARCH`
- Sistemas que dependen de eventos programados para tareas internas
- Bases con estructuras de seguridad avanzadas (roles, permisos, auditoría)

 

## 📌 Cuándo usar pgloader

- Migraciones iniciales de datos estructurados
- Proyectos donde la lógica se reescribirá desde cero
- Entornos donde se puede validar manualmente la integridad
 

## 🚫 Cuándo NO usar pgloader (solo)

- Cuando se requiere migración completa de lógica de negocio
- En entornos regulados donde se necesita trazabilidad completa
- Si se necesita migrar funciones, triggers o procedimientos automáticamente

 

## 🧪 Competencias o tecnologías alternativas

| Herramienta       | ¿Migra lógica? | ¿GUI? | ¿Validación? |
|-------------------|----------------|-------|--------------|
| pgloader          | ❌             | ❌    | ❌           |
| MySQL Workbench   | ✅ (exporta)   | ✅    | ❌           |
| ora2pg            | ✅             | ❌    | ✅           |
| AWS DMS           | ✅ (limitado)  | ✅    | ✅           |

 

## 🧠 Consideraciones antes y después

**Antes:**
- Identificar objetos no migrables
- Exportar procedimientos y funciones
- Documentar dependencias

**Después:**
- Validar integridad de datos
- Reescribir lógica en PL/pgSQL
- Configurar roles y seguridad
 

## 📝 Notas importantes

- pgloader es excelente para migrar **datos**, pero no para migrar **comportamiento**.
- Requiere complementarse con scripts manuales o herramientas adicionales.


# 🏢 Manual de Migración Empresarial de MySQL a PostgreSQL con pgloader

***

## 1. 📑 Índice

1.  Objetivo
2.  Requisitos
3.  ¿Qué es pgloader?
4.  Ventajas y Desventajas
5.  Casos de Uso
6.  Simulación de Empresa
7.  Estructura Semántica
8.  Visualización del Flujo
9.  Procedimientos Técnicos
    *   Instalación
    *   Preparación de Entornos
    *   Configuración de Red
    *   Script pgloader
    *   Ejecución
    *   Validación
    *   Mantenimiento
10. Consideraciones
11. Buenas Prácticas
12. Recomendaciones
13. Tabla Comparativa
14. Bibliografía

***

## 2. 🎯 Objetivo

Guiar a un equipo técnico en la migración de una base de datos empresarial desde **MySQL 5.7** hacia **PostgreSQL 15**, utilizando `pgloader`, con enfoque en rendimiento, integridad de datos y automatización.

***

## 3. 🧰 Requisitos

*   PostgreSQL 15 instalado en servidor destino
*   MySQL 5.7 o superior en servidor origen
*   Acceso SSH a ambos servidores
*   Red abierta entre ambos (puertos 3306 y 5432)
*   pgloader instalado en el servidor de migración
*   Usuario con permisos de lectura en MySQL y escritura en PostgreSQL
*   Espacio en disco suficiente para logs y backups

***

## 4. 📖 ¿Qué es pgloader?

`pgloader` es una herramienta de migración automática que permite importar datos desde MySQL, SQLite, MS SQL Server y otros formatos hacia PostgreSQL, con conversión de tipos, creación de esquemas y carga paralela.

***

## 5. ⚙️ Ventajas y Desventajas

**Ventajas**

*   Migración automática de esquemas y datos
*   Conversión de tipos entre motores
*   Carga paralela y optimizada
*   Soporte para transformaciones en vuelo

**Desventajas**

*   No migra procedimientos almacenados
*   No tiene interfaz gráfica
*   Requiere ajustes post-migración para funciones específicas

***

## 6. 🏢 Simulación de Empresa

**Empresa**: *Finanzas Globales S.A.*\
**Contexto**:

*   1 TB de datos en MySQL
*   50 tablas, 10 millones de registros en promedio
*   Uso intensivo de `DATETIME`, `TEXT`, `ENUM`, `BLOB`
*   Requieren migrar a PostgreSQL para aprovechar particionamiento, JSONB y funciones analíticas

***

## 7. 🧬 Estructura Semántica



***

## 8. 🛰️ Visualización del Flujo



***

## 9. 🛠️ Procedimientos Técnicos

### 🔧 Instalación de pgloader

```bash
sudo apt-get update
sudo apt-get install pgloader
```

### 🧪 Preparación de Entornos

#### MySQL (origen)

```sql
CREATE DATABASE clientes;
USE clientes;
CREATE TABLE transacciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT,
  monto DECIMAL(10,2),
  fecha DATETIME,
  descripcion TEXT
);
```

#### PostgreSQL (destino)

```sql
CREATE DATABASE clientes_pg;
```

### 🌐 Configuración de Red

*   Asegurar que el servidor PostgreSQL escuche en `0.0.0.0` (`postgresql.conf`)
*   Permitir IP del servidor de migración en `pg_hba.conf`
*   Verificar conectividad:

```bash
telnet postgres_host 5432
telnet mysql_host 3306
```

***

### 📄 Script `pgloader`

Archivo: `migracion_empresarial.load`

```lisp
LOAD DATABASE
     FROM mysql://usuario_mysql:clave@mysql_host/clientes
     INTO postgresql://usuario_pg:clave@pg_host/clientes_pg

 WITH include no drop, create tables, create indexes, reset sequences,
      data only, batch rows = 50000, concurrency = 4

 SET work_mem to '256MB', maintenance_work_mem to '1GB'

 CAST type datetime to timestamptz using zero-dates-to-null,
      type text to text using utf8-to-utf8

 BEFORE LOAD DO
 $$ CREATE SCHEMA IF NOT EXISTS migracion $$;
```

***

### ▶️ Ejecución

```bash
pgloader migracion_empresarial.load
```

**Simulación de salida:**

    2025-10-06T09:00:00.000000Z INFO Starting pgloader
    2025-10-06T09:00:01.000000Z INFO Parsing commands
    2025-10-06T09:00:02.000000Z INFO Migrating transacciones
    2025-10-06T09:00:10.000000Z INFO Loaded 10,000,000 rows in 8m 32s
    2025-10-06T09:00:11.000000Z INFO Finished loading 50 tables

***

### ✅ Validación

```sql
-- PostgreSQL
SELECT COUNT(*) FROM migracion.transacciones;
```

```sql
-- MySQL
SELECT COUNT(*) FROM clientes.transacciones;
```

Comparar resultados. También puedes usar `CHECKSUM` o `hashes` para validar integridad.

***

### 🔄 Mantenimiento

*   Reindexar tablas grandes:
    ```sql
    REINDEX TABLE migracion.transacciones;
    ```
*   Analizar estadísticas:
    ```sql
    ANALYZE VERBOSE migracion.transacciones;
    ```

***

## 10. 🧠 Consideraciones

*   pgloader no migra triggers ni procedimientos
*   Revisar tipos como `ENUM`, `SET`, `BLOB`
*   Validar zonas horarias en `DATETIME`

***

## 11. ✅ Buenas Prácticas

*   Ejecutar en entorno de staging primero
*   Usar `pg_stat_statements` para monitorear rendimiento
*   Documentar cada paso y cambios de tipo

***

## 12. 💡 Recomendaciones

*   Para procedimientos almacenados, usar herramientas como `MySQL Workbench` para exportar y reescribir en PL/pgSQL
*   Considerar `pg_partman` para particionar tablas grandes post-migración

***

## 13. 📊 Tabla Comparativa

| Característica   | MySQL     | PostgreSQL                     |
| ---------------- | --------- | ------------------------------ |
| Tipos de datos   | Limitados | Avanzados (JSONB, ARRAY, etc.) |
| Particionamiento | Manual    | Declarativo                    |
| Procedimientos   | SQL/PSM   | PL/pgSQL, PL/Python            |
| Índices          | Básicos   | Multicolumna, GIN, GiST        |
| Seguridad        | Básica    | Avanzada (RLS, certificados)   |

***

## 14. 📚 Bibliografía
```
Migrate a MySQL database to PostgreSQL using pgLoader  -> https://medium.com/@acosetov/migrate-a-mysql-database-to-postgresql-using-pgloader-5d943b9fc51c
Migrating MySQL to PostgreSQL using pgloader -> https://medium.com/@rizqinur2010/migrating-mysql-to-postgresql-using-pgloader-e2eb22befa4e
Migrating MySQL to PostgreSQL Using Docker and pgLoader -> https://jay75chauhan.medium.com/migrating-mysql-to-postgresql-using-docker-and-pgloader-e3726124ed80
Data migration using PgLoader with Materialized Views -> https://blog.devops.dev/data-migration-using-pgloader-with-materialized-views-3526e37f0606
Migrate your MySQL database to Postgres with Supabase, Hasura & pgloader -> https://medium.com/@adi_myth/migrate-your-mysql-database-to-postgres-with-supabase-hasura-pgloader-3ef63bedd38
Migrate Postgres DBs across cloud providers with pgloader -> https://piaverous.medium.com/a-migration-story-a546eb8131cb
Converting from MySQL to Postgres with pgloader, for Heroku -> https://medium.com/@nathanwillson/converting-from-mysql-to-postgres-with-pgloader-for-heroku-b1212c6ad932


*   <https://pgloader.io>
*   <https://www.postgresql.org/docs/>
*   <https://dev.mysql.com/doc/>
*   <https://wiki.postgresql.org/wiki/Migrating_from_MySQL_to_PostgreSQL>
```
