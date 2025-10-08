
### **Conocer las diferencias clave entre Oracle y PostgreSQL**
Antes de migrar, es fundamental entender cómo difieren:

| Aspecto | Oracle | PostgreSQL |
|--------|--------|------------|
| Tipos de datos | Muy específicos (e.g. `NUMBER`, `VARCHAR2`) | Más estándar (e.g. `NUMERIC`, `VARCHAR`) |
| Procedimientos | PL/SQL | PL/pgSQL |
| Secuencias | `SEQUENCE`, `TRIGGERS` para autoincremento | `SERIAL`, `BIGSERIAL`, `IDENTITY` |
| Funciones | Paquetes, funciones, procedimientos | Funciones (con o sin retorno) |
| Particiones | Avanzadas, con subtipos | Mejoradas desde PG 10+ |
| Índices | Bitmap, Function-based, etc. | B-tree, GIN, GiST, BRIN |
| Seguridad | Roles, perfiles, auditoría | Roles, políticas, RLS, extensiones |

 
## 🧭 1. Índice

1.  Objetivo
2.  Requisitos
3.  ¿Qué es ora2pg?
4.  Ventajas y Desventajas
5.  Casos de uso
6.  Simulación de empresa y problema
7.  Estructura semántica
8.  Visualización técnica
9.  Procedimiento completo
    *   Instalación de ora2pg
    *   Conexión a Oracle
    *   Exportación de esquema
    *   Migración de datos
    *   Validación y ajustes
10. Consideraciones finales
11. Buenas prácticas
12. Recomendaciones
13. Bibliografía

***

## 🎯 2. Objetivo

Este manual tiene como objetivo guiarte paso a paso en la migración de una base de datos Oracle a PostgreSQL utilizando la herramienta **ora2pg**, simulando un entorno real de empresa, con comandos ejecutables, configuraciones y visualizaciones técnicas.

***

## 🧰 3. Requisitos

*   Conocimientos básicos de Oracle y PostgreSQL
*   Herramientas como "Oracle SQL Developer"  y PgAdmin
*   Acceso a una base de datos Oracle (puede ser local o remota)
*   PostgreSQL instalado (versión 13+ recomendada)
*   Sistema operativo Linux (Ubuntu/Debian/CentOS)
*   Perl instalado (ora2pg está escrito en Perl)
*   Conexión de red entre Oracle y el host donde se ejecuta ora2pg
*   Usuario con privilegios de lectura en Oracle

***

## ❓ 4. ¿Qué es ora2pg?

**ora2pg** es una herramienta de código abierto que permite migrar esquemas, datos y funciones desde Oracle a PostgreSQL. Convierte automáticamente objetos como tablas, índices, secuencias, vistas, funciones PL/SQL, triggers, etc.

***

## ⚖️ 5. Ventajas y Desventajas

**Ventajas:**

*   Automatiza gran parte del proceso
*   Compatible con grandes volúmenes de datos
*   Permite migraciones parciales
*   Genera reportes de compatibilidad

**Desventajas:**

*   No convierte todo el PL/SQL complejo
*   Requiere ajustes manuales en funciones y triggers
*   No migra paquetes ni procedimientos almacenados complejos sin intervención

***


## ✅ **¿Qué sí hace Ora2Pg?**

1. **Extrae estructuras de Oracle**:
   - Tablas, índices, secuencias, vistas, sinónimos, constraints, etc.
2. **Convierte tipos de datos Oracle a PostgreSQL**.
3. **Migra datos** (opcional, puedes exportar solo estructura o estructura + datos).
4. **Convierte funciones y procedimientos PL/SQL a PL/pgSQL** (con limitaciones).
5. **Genera scripts SQL listos para ejecutar en PostgreSQL**.
6. **Evalúa el esfuerzo de migración** (modo `migration assessment`).
7. **Soporta migración de particiones, triggers, grants, y más**.
8. **Permite personalizar la migración con filtros y configuraciones avanzadas**.

---

## ❌ **¿Qué no hace Ora2Pg?**

| Limitación | Detalle |
|------------|---------|
| 🔧 **No convierte todo el código PL/SQL complejo** | Procedimientos muy complejos, paquetes, cursores anidados, excepciones personalizadas, etc., pueden requerir **reescritura manual**. |
| 📦 **No migra paquetes (`PACKAGE`) ni tipos definidos por el usuario (`OBJECT TYPE`)** | Estos deben migrarse manualmente o con herramientas adicionales. |
| 🔄 **No mantiene lógica de negocio 100% funcional** | Algunas funciones pueden comportarse diferente en PostgreSQL. Se requiere **validación y pruebas**. |
| 🔐 **No migra usuarios, roles ni privilegios de forma completa** | Solo puede exportar algunos `GRANT`, pero no gestiona usuarios ni contraseñas. |
| 🧩 **No migra dependencias externas** | Jobs de Oracle (DBMS_SCHEDULER), enlaces a otras bases (`DBLINK`), integraciones con otros sistemas, etc., deben manejarse aparte. |
| 🧠 **No optimiza automáticamente el rendimiento en PostgreSQL** | La estructura migrada puede necesitar **ajustes de índices, particiones, estadísticas, etc.** |
| 📊 **No migra reportes, formularios ni aplicaciones Oracle Forms/Reports** | Solo trabaja con la base de datos, no con herramientas externas. |

---

## 🛠️ ¿Qué puedes usar junto con Ora2Pg?

- **SQL Developer**: Para exportar objetos complejos o revisar dependencias.
- **pgAdmin / DBeaver**: Para importar y validar en PostgreSQL.
- **Scripts personalizados**: Para migrar usuarios, jobs, o lógica no soportada.
- **Testing automatizado**: Para validar que los resultados en PostgreSQL sean correctos.

## 🏢 6. Simulación de empresa y problema

**Empresa:** AgroTech Sinaloa\
**Problema:** La empresa tiene un sistema de gestión de cultivos en Oracle 11g y desea migrarlo a PostgreSQL para reducir costos y mejorar la integración con herramientas modernas.

***
 

## 🛠️ 8. Procedimiento completo

### 🔹 Instalación de ora2pg

```bash
sudo apt update
sudo apt install ora2pg -y

#Instalar DBI
 apt-get install cpanminus 
cpanm DBI 

#Instalar DBD::Oracle y DBD::Pg
 cpanm DBD::Oracle 
cpanm DBD::Pg 

#Instalar ora2pg
 tar xjf ora2pg-xxtar.bz2 
cd ora2pg-xx/ 
perl Makefile.PL 
make && make install

```

### 🔹 Configuración de conexión a Oracle

Editamos el archivo de configuración:

```bash
sudo nano /etc/ora2pg/ora2pg.conf
```

Configuramos:

```ini 
ORACLE_DSN = localhost:1521/ORCL -- - dbi:Oracle:host=10.0.1.2;sid=DB_SID;port=1522
ORACLE_USER = oracle_user
ORACLE_PWD = oracle_password

PG_DSN = localhost:5432/postgres --- dbi:Pg:dbname=ora2pg_db;host=10.23.14.50;port=5432
PG_USER = postgres_user
PG_PWD = postgres_password

EXPORT_SCHEMA = YES
EXPORT_DATA = YES
TYPE = TABLE


```



### 🔹 Simulación de esquema en Oracle

Supongamos que tenemos esta tabla:

```sql
CREATE TABLE cultivos (
    id NUMBER PRIMARY KEY,
    nombre VARCHAR2(100),
    fecha_siembra DATE,
    hectareas NUMBER
);
```

### 🔹 Exportación del esquema

```bash
ora2pg -c /etc/ora2pg/ora2pg.conf -t TABLE -o cultivos.sql
```

**Simulación de salida:**

```sql
CREATE TABLE cultivos (
    id integer PRIMARY KEY,
    nombre varchar(100),
    fecha_siembra date,
    hectareas numeric
);
```

### 🔹 Migración de datos

```bash
ora2pg -c /etc/ora2pg/ora2pg.conf -t COPY -o cultivos_data.sql
```

**Simulación de salida:**

```sql
COPY cultivos (id, nombre, fecha_siembra, hectareas) FROM stdin;
1   Maíz    2023-03-15  12.5
2   Trigo   2023-04-01  8.0
\.
```

### 🔹 Importación en PostgreSQL

```bash
psql -U postgres -d agrotech_db -f cultivos.sql
psql -U postgres -d agrotech_db -f cultivos_data.sql
```

### 🔹 Validación

```sql
SELECT * FROM cultivos;
```

**Simulación de salida:**

| id | nombre | fecha\_siembra | hectareas |
| -- | ------ | -------------- | --------- |
| 1  | Maíz   | 2023-03-15     | 12.5      |
| 2  | Trigo  | 2023-04-01     | 8.0       |

***

## ✅ 9. Consideraciones

*   Verifica compatibilidad de tipos de datos
*   Revisa funciones PL/SQL manualmente
*   Usa `EXPORT_TYPE` para migrar por partes (TABLE, VIEW, FUNCTION, etc.)

***

## 🧠 10. Buenas prácticas

*   Realiza pruebas en entorno de staging
*   Usa control de versiones para scripts generados
*   Documenta cada paso de la migración

***

## 💡 11. Recomendaciones


 # La opción `-t SHOW_REPORT`
se utiliza para **generar un informe detallado del análisis de una base de datos Oracle antes de migrarla a PostgreSQL**. Este informe no realiza ninguna migración, sino que **evalúa el esfuerzo necesario** para llevar a cabo la migración.

### ¿Qué incluye el reporte generado por `ora2pg -t SHOW_REPORT`?

El informe muestra:

- **Número de objetos** en la base de datos Oracle (tablas, vistas, funciones, procedimientos, triggers, etc.).
- **Compatibilidad** de esos objetos con PostgreSQL.
- **Estimación del esfuerzo** de migración (en puntos de complejidad).
- **Problemas potenciales** como tipos de datos incompatibles, funciones PL/SQL que requieren reescritura, etc.
- **Recomendaciones** para ajustar la configuración de ora2pg antes de iniciar la migración real.

### ¿Para qué sirve?

Este comando es ideal para:

- **Auditoría previa** a la migración.
- **Planificación del proyecto** de migración.
- **Identificación de obstáculos técnicos**.
- **Estimación de tiempos y recursos** necesarios.

### Ejemplo de uso:

```bash
ora2pg -t SHOW_REPORT -c /etc/ora2pg/ora2pg.conf
ora2pg -t SHOW_REPORT -c ora2pg.conf --dump_as_html | Set-Content -Path "report.html" -Encoding utf8

```

***

---
# Extra info

## 🛠 ¿Cómo usa ora2pg el CDC?

Ora2pg puede usar **LogMiner** para leer los redo logs y extraer los cambios. Esto requiere:

- Activar `ARCHIVELOG`.
- Configurar `SUPPLEMENTAL LOGGING`.
- Otorgar permisos para acceder a vistas como `V$LOGMNR_CONTENTS`.

Pero **no es en tiempo real**. Ora2pg puede ejecutar un proceso que:

1. Se conecta a Oracle.
2. Lee los logs desde un punto anterior.
3. Extrae los cambios.
4. Genera archivos `.sql` para aplicar en PostgreSQL.

Este proceso puede **automatizarse con cron o scripts**, pero no es una replicación continua como lo haría una herramienta de streaming.

 
---
# objetos que forman parte del esquema y la estructura de la base de datos Oracle


### 🔹 **Objetos de almacenamiento**
- **Tables**: Almacenan datos estructurados.
- **Indexes**: Mejoran el rendimiento de las consultas.
- **Materialized Views**: Vistas que almacenan datos físicamente.
- **Clusters**: Agrupan tablas que comparten columnas comunes.
- **Partitions**: Dividen tablas grandes en partes más manejables.


### 🔹 **Objetos de programación**
- **Procedures**: Bloques de código PL/SQL que realizan tareas específicas.
- **Functions**: Similar a los procedimientos, pero devuelven un valor.
- **Packages**: Agrupan procedimientos, funciones y variables relacionadas.
- **Triggers**: Ejecutan código automáticamente ante eventos DML o DDL.
- **Types**: Definen tipos de datos personalizados (usados en objetos y colecciones).
- **Libraries**: Referencias a código externo (por ejemplo, C).


### 🔹 **Objetos de seguridad**
- **Users**: Cuentas de acceso a la base de datos.
- **Roles**: Conjuntos de permisos que se pueden asignar a usuarios.
- **Profiles**: Configuran límites y políticas de uso para usuarios.
- **Synonyms**: Alias para objetos de base de datos.
- **Grants**: Permisos otorgados sobre objetos.


### 🔹 **Objetos de metadatos y administración**
- **Schemas**: Colecciones de objetos propiedad de un usuario.
- **Tablespaces**: Espacios físicos de almacenamiento.
- **Sequences**: Generan valores numéricos únicos (usados en claves primarias).
- **Database Links**: Conexiones a otras bases de datos Oracle.
- **Jobs**: Tareas programadas (usando DBMS_SCHEDULER o DBMS_JOB).


### 🔹 **Objetos de consulta y vista**
- **Views**: Consultas guardadas como objetos reutilizables.
- **Synonyms**: Alias para acceder a objetos sin usar el nombre completo.
- **Cursors**: Permiten recorrer resultados de una consulta.


### 🔹 **Objetos XML y JSON**
- **XMLType**: Tipo de dato para almacenar XML.
- **JSON Data**: Desde Oracle 12c, soporte nativo para JSON.


### 🔹 **Otros objetos**
- **Directories**: Referencias a ubicaciones del sistema de archivos.
- **External Tables**: Tablas que leen datos desde archivos externos.
- **Object Types**: Tipos definidos por el usuario para programación orientada a objetos.

---
# links
```
Ora2Pg tool introduction -> https://pankajconnect.medium.com/ora2pg-tool-introduction-48253d06d889

01 - Standard Operating Procedure (SOP) Oracle to PostgreSQL Migration using Ora2Pg -> https://medium.com/@jramcloud1/01-standard-operating-procedure-sop-oracle-to-postgresql-migration-using-ora2pg-7a5d5a36dd8b
02 - Oracle to PostgreSQL Migration with Ora2Pg -> https://medium.com/@jramcloud1/02-oracle-to-postgresql-migration-with-ora2pg-8a99591eb918

Why Migrate from Oracle to PostgreSQL -> https://medium.com/@abdelhaak/why-migrate-from-oracle-to-postgresql-9634fb82439c
Oracle to PostgreSQL Migration using Ora2Pg “Part 1” -> https://medium.com/@abdelhaak/hands-on-lab-migrating-your-oracle-database-to-postgresql-with-ora2pg-ab2c89b1d5ec
Oracle to PostgreSQL Migration using Ora2Pg “Part 2” -> https://medium.com/@abdelhaak/migrating-your-oracle-database-to-postgresql-with-ora2pg-hands-on-lab-part-2-c0ba8b471bcb 
Oracle to PostgreSQL Migration using Ora2Pg “Part 3” -> https://medium.com/@abdelhaak/migrating-your-oracle-database-to-postgresql-with-ora2pg-hands-on-lab-part-3-76e547f39b96

DMS | Oracle to PostgreSQL- Part 1 of 4 -> https://blog.searce.com/dms-oracle-to-postgresql-part-1-of-4-ae853f2ccc35
DMS | Oracle to PostgreSQL — Part 2 of 4 -> https://blog.searce.com/dms-oracle-to-postgresql-part-2-of-4-d88799c5f9a
DMS | Oracle to PostgreSQL - Part 3 of 4 -> https://blog.searce.com/dms-oracle-to-postgresql-part-3-of-4-4342c8864d73
DMS | Oracle to PostgreSQL — Part 4 of 4 -> https://blog.searce.com/dms-oracle-to-postgresql-part-4-of-4-49ea8effd1c0




Case Study: Migrating from Oracle 19c to PostgreSQL 16 using Ora2PG -> https://medium.com/@datapatrolt/case-study-migrating-from-oracle-19c-to-postgresql-16-using-ora2pg-a0ef2dde81cc
Oracle to Postgres : The Database Darwinism -> https://drunkdba.medium.com/oracle-to-postgres-the-database-darwinism-194390c5833d
Ora2pg GCP  -> https://technoshow91.medium.com/ora2pg-1d108fe10821

Important Ora2pg config variables -> https://medium.com/@abhijitgm5/configure-your-ora2pg-config-file-b82f7f46f6c5
migrate-oracle-postgres-using-ora2pg -> https://github.com/GoogleCloudPlatform/community/blob/master/archived/migrate-oracle-postgres-using-ora2pg/index.md

Oracle DB migration to Azure Database for Postgres (PG) -> https://medium.com/@chbasani/oracle-db-migration-to-azure-database-for-postgres-pg-69ee8ce34e07
Oracle to Postgres Migration Guide for Azure -> https://techcommunity.microsoft.com/blog/adforpostgresql/new-oracle-to-postgres-migration-guide-for-azure/2055303

*   <https://ora2pg.darold.net/>
*    https://github.com/darold/ora2pg
*   <https://www.postgresql.org/docs/>
*   <https://www.enterprisedb.com/>


```




 


