
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

---

## ⚠️ Limitaciones y consideraciones antes de migrar

### 1. **Compatibilidad de tipos de datos**
- Algunas conversiones pueden fallar si los tipos no son compatibles.
- Es posible definir reglas de casting personalizadas en el archivo de configuración.

### 2. **Longitud de nombres**
- PostgreSQL tiene un límite de 63 caracteres para nombres de objetos (tablas, columnas, etc.).
- pgloader puede truncar nombres largos automáticamente, lo que puede causar conflictos [2](https://www.percona.com/blog/migrating-from-mysql-to-postgresql-using-pgloader/).

### 3. **Dependencias y relaciones**
- Las relaciones complejas entre tablas deben estar bien definidas.
- pgloader puede tener problemas si hay claves foráneas circulares o mal estructuradas.

### 4. **Migración de funciones, procedimientos y triggers**
- **No migra funciones ni procedimientos almacenados** automáticamente.
- Estos deben migrarse manualmente y adaptarse a PL/pgSQL si vienen de otro motor.

### 5. **Vistas y materializadas**
- Las vistas pueden migrarse como estructuras, pero no siempre se migran con lógica completa.
- Las vistas materializadas deben refrescarse manualmente en PostgreSQL.

### 6. **Extensiones y objetos especiales**
- No migra extensiones específicas del origen (como funciones de Oracle o SQL Server).
- Debes revisar si hay objetos no compatibles con PostgreSQL.

### 7. **Errores y registros**
- pgloader genera archivos `reject.dat` y `reject.log` para registrar errores de carga.
- Es importante revisarlos después de la migración para validar integridad.

---

## 🧪 Recomendaciones antes de usar pgloader

1. **Audita tu base de datos origen**: identifica tipos de datos, relaciones, funciones y vistas.
2. **Define reglas de casting** si hay tipos personalizados.
3. **Haz pruebas con bases pequeñas** antes de migrar entornos grandes.
4. **Revisa nombres largos** y objetos especiales.
5. **Valida la integridad post-migración** con scripts de comparación.
6. **Documenta todo el proceso** para futuras migraciones o auditorías.

---
 

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
