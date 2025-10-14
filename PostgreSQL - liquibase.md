### 🧠 ¿Qué es Liquibase?

Liquibase es una herramienta de **control de versiones para bases de datos**. Así como Git controla versiones de código, Liquibase controla versiones de **esquemas de base de datos**: tablas, columnas, índices, procedimientos, funciones, etc.


### 🎯 ¿Cuál es su objetivo?

El objetivo principal de Liquibase es:

- **Automatizar** y **rastrear** los cambios en la estructura de la base de datos.
- **Evitar errores humanos** al aplicar cambios manuales.
- **Sincronizar entornos** (desarrollo, pruebas, producción).
- **Auditar** qué cambios se hicieron, cuándo y por quién.
- **Integrarse con CI/CD** para despliegues automáticos.


### 🛢️ ¿Qué motor de base de datos usa?

Liquibase **no tiene su propio motor de base de datos**. Es una herramienta que **se conecta a motores existentes**. Soporta muchos, incluyendo:

- PostgreSQL ✅
- Oracle ✅
- MySQL ✅
- SQL Server ✅
- DB2, H2, SQLite, MariaDB, entre otros.


### 🧰 ¿Dónde te puede servir?

Liquibase es útil en:

- Proyectos con **equipos grandes** donde varios desarrolladores modifican la base de datos.
- **Migraciones** entre versiones o motores.
- **DevOps** y despliegues automatizados.
- **Auditoría** de cambios en producción.
- **Rollback** de cambios si algo falla.

### 📌 ¿Cuál es el objetivo de este archivo changelog?

El objetivo principal es **definir los cambios que se deben aplicar a la base de datos** de forma estructurada, versionada y automatizada. Es como un "script evolutivo" que describe cómo debe transformarse la base de datos a lo largo del tiempo.

### 📦 ¿Cómo funciona?

Liquibase usa archivos llamados **"changelogs"** que describen los cambios en formato:

- **YAML** (muy legible y usado en DevOps)
- **XML** (más estructurado, común en Java)
- **JSON** (útil si trabajas con APIs)
- **SQL** (si prefieres escribir directamente los comandos)

Ejemplo en YAML:

```yaml
databaseChangeLog:
  - changeSet:
      id: 1
      author: admin
      changes:
        - createTable:
            tableName: empleados
            columns:
              - column:
                  name: id
                  type: int
                  autoIncrement: true
                  constraints:
                    primaryKey: true
              - column:
                  name: nombre
                  type: varchar(255)
```

Este archivo puede ejecutarse en cualquier entorno y Liquibase se encargará de aplicar el cambio **solo si no se ha aplicado antes**.


### 🧪 Ejemplo de uso real

**Caso: Migración controlada en una empresa**

Una empresa tiene una base de datos PostgreSQL en producción. El equipo de desarrollo necesita agregar una nueva columna `email` a la tabla `clientes`.

1. El desarrollador crea un changelog en YAML con el cambio.
2. Liquibase lo ejecuta en desarrollo.
3. Se prueba el cambio.
4. Se aprueba y se despliega automáticamente en producción usando Jenkins + Liquibase.
5. Si algo falla, se puede hacer rollback.


### ✅ Ventajas

- Compatible con múltiples motores.
- Fácil de integrar en pipelines CI/CD.
- Control de versiones de esquema.
- Rollback automático.
- Auditable y trazable.



### 📁 ¿Dónde se guardan los **changelogs**?

Los changelogs son **archivos de texto plano** que tú mismo creas y gestionas. Se guardan en el **repositorio del proyecto**, junto con el código fuente, por ejemplo:

```
/mi-proyecto/
├── src/
├── liquibase/
│   ├── changelog.yaml
│   ├── changelog.sql
│   └── changelog.xml
├── pom.xml (si usas Maven)
└── README.md
```

Puedes tener **uno o varios changelogs**, organizados por fecha, módulo, versión, etc. Liquibase los lee y aplica los cambios en la base de datos.


---


### 🔁 ¿Qué es CI/CD?

**CI/CD** significa:

- **CI (Integración Continua)**: Automatiza la integración de cambios en el código. Cada vez que alguien hace un cambio, se prueba y valida automáticamente.
- **CD (Entrega/Despliegue Continuo)**: Automatiza el despliegue de esos cambios a producción u otros entornos.

Liquibase se integra perfectamente en pipelines CI/CD como:

- **Jenkins**
- **GitLab CI**
- **GitHub Actions**
- **Azure DevOps**
- **CircleCI**

Esto permite que los cambios en la base de datos se apliquen automáticamente cuando se hace un *push* al repositorio, manteniendo todos los entornos sincronizados.
 
### 🧪 Ejemplo de uso en CI/CD

Supongamos que tienes un proyecto en GitHub con una base de datos PostgreSQL. Cuando haces un cambio en el archivo `changelog.yaml`, se dispara un pipeline en GitHub Actions que:

1. Ejecuta pruebas unitarias.
2. Valida el changelog con Liquibase.
3. Aplica los cambios en la base de datos de desarrollo.
4. Si todo está bien, los despliega en producción.


## 🧪 Ejemplo real de pipeline para DBA

Imagina que estás trabajando en un proyecto donde cada semana se agregan nuevas columnas a tablas en PostgreSQL. El pipeline podría hacer lo siguiente:

1. **Detectar cambios** en el archivo `changelog.yaml` de Liquibase.
2. **Ejecutar pruebas** para validar que el cambio no rompe nada.
3. **Aplicar el cambio** en la base de datos de desarrollo.
4. **Notificar** si todo salió bien.
5. **Desplegar** el cambio en producción automáticamente si se aprueba.

Esto lo puedes hacer con herramientas como:

- **GitHub Actions**
- **Jenkins**
- **GitLab CI**
- **Azure DevOps**


## 🚀 ¿Qué es un *pipeline*?

Un **pipeline** es una **secuencia automatizada de pasos** que se ejecutan uno tras otro para lograr un objetivo técnico, como:

- Compilar código
- Ejecutar pruebas
- Validar cambios
- Desplegar aplicaciones o bases de datos

Es como una **línea de producción** en una fábrica, pero para software.

 
## 🧰 ¿Para qué sirve?

Sirve para:

- **Automatizar tareas repetitivas**
- **Evitar errores humanos**
- **Asegurar calidad** antes de que algo llegue a producción
- **Reducir tiempos** de entrega
- **Sincronizar equipos** de desarrollo, QA y operaciones

---

Tanto **Flyway** como **Liquibase** son herramientas líderes para la **gestión de migraciones de bases de datos**, pero tienen diferencias clave que pueden hacer que una sea mejor que otra dependiendo del contexto de tu proyecto.

Aquí tienes una **comparación clara y profesional**:

| Característica                  | **Flyway**                                      | **Liquibase**                                   |
|--------------------------------|--------------------------------------------------|--------------------------------------------------|
| **Lenguaje de migración**      | Principalmente SQL (también Java opcional)       | SQL, XML, YAML, JSON                             |
| **Facilidad de uso**           | Muy simple, ideal para empezar rápido            | Más complejo, pero más flexible                  |
| **Control de versiones**       | Basado en nombres de archivo (`V1__init.sql`)    | Usa un `changelog` con identificadores únicos    |
| **Integración CI/CD**          | Excelente, muy usado en DevOps                   | También muy bueno, con más opciones avanzadas    |
| **Validación de cambios**      | Básica                                           | Avanzada (checksums, rollback, diff, etc.)       |
| **Rollback de migraciones**    | No soportado directamente                        | Sí, permite definir rollback por cada cambio     |
| **Soporte para múltiples DBs** | Muy bueno                                        | Excelente, con más funciones específicas por DB  |
| **Auditoría y seguimiento**    | Tabla `flyway_schema_history`                    | Tabla `DATABASECHANGELOG` con más metadatos      |
| **Curva de aprendizaje**       | Baja                                             | Media a alta                                     |
| **Licencia**                   | Open Source + versión Enterprise                 | Open Source + versión Enterprise                 |

# Links
```sql

https://www.liquibase.com/download-community

Tame Your Database: A Hands-On Liquibase Course for PostgreSQL -> https://medium.com/@lahsaini/tame-your-database-a-hands-on-liquibase-course-for-postgresql-91412d17a772
Understanding Liquibase, a devops tool for database schema change management -> https://medium.com/@dnyanesh.bandbe88/understanding-liquibase-a-devops-tool-for-database-schema-change-management-37840027c0ca
Database Change Management Made Easy with Liquibase and PostgreSQL -> https://medium.com/@sonichigo/database-change-management-made-easy-with-liquibase-and-postgresql-87da66b0c9c7
Introduction to Liquibase and Bootstrapping & maintaining a Postgres DB using Liquibase and Spring Boot -> https://medium.com/@youjithdeelake/introduction-to-liquibase-and-bootstrapping-maintaining-a-postgres-db-using-liquibase-and-spring-d33e1f701ca9
jOOQ code generator with Postgres Database and Liquibase -> https://medium.com/@sahilseth/jooq-code-generator-with-postgres-database-and-liquibase-f9c27d7470e7
Liquibase plugin with Postgres & Hibernate -> https://medium.com/@a.a.lechner/liquibase-plugin-with-postgres-hibernate-e3a33a45b1cf
CI/CD pipeline to automate database deployments using Liquibase and GitLab -> https://jithinjayaprakash.medium.com/ci-cd-pipeline-to-automate-database-deployments-using-liquibase-and-gitlab-1242885cb138
Liquibase — Why every DBA should use it -> https://fabriciojorge.medium.com/liquibase-why-every-dba-should-use-it-ad49b85a7231
Mastering Database Version Control with Liquibase in Spring Boot Applications — Part II -> https://medium.com/@javedalikhan50/mastering-database-version-control-with-liquibase-in-spring-boot-applications-part-ii-aff9f011d514
 
 
 ¡Domina Liquibase en minutos! Guía práctica de comandos esenciales -> https://www.youtube.com/watch?v=-lJX_r4GrBU
 Liquibase - Versionado de Bases de Datos | Martin Britez e Indiana Lozano -> https://www.youtube.com/watch?v=fUXdTfkT_RQ

```
