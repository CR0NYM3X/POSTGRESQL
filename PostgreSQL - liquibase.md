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



# Links
```sql

https://medium.com/@lahsaini/tame-your-database-a-hands-on-liquibase-course-for-postgresql-91412d17a772

```
