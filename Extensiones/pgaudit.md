

# 🛡️ PostgreSQL Audit (pgAudit) Guide

## 1. ¿Qué es pgAudit?

**pgAudit** (*PostgreSQL Audit Extension*) es una extensión de código abierto diseñada para proporcionar registros de auditoría detallados y granulares en PostgreSQL. Fue desarrollada originalmente por 2ndQuadrant (ahora parte de EnterpriseDB).

A diferencia del registro (*logging*) estándar de PostgreSQL diseñado para la depuración y resolución de errores, **pgAudit está optimizado para cumplir con requisitos de seguridad y cumplimiento normativo (compliance)**.

> **Importante:** pgAudit escribe sus eventos en el mismo archivo de logs de PostgreSQL. Si no se configura adecuadamente, puede generar mucho "ruido" o duplicar información de registro.


## ¿Para qué sirve?

Sirve para registrar **quién hizo qué, cuándo y dónde** en la base de datos. Permite clasificar y auditar los siguientes tipos de comandos:

| Clase | Sentencias capturadas |
| :--- | :--- |
| **READ** | `SELECT` y `COPY` (desde una relación/consulta). |
| **WRITE** | `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE` y `COPY` (hacia una relación). |
| **FUNCTION** | Llamadas a funciones y bloques `DO`. |
| **ROLE** | Sentencias de roles y privilegios (`GRANT`, `REVOKE`, `CREATE/ALTER/DROP ROLE`). |
| **DDL** | Cambios de estructura (todo el DDL no cubierto en `ROLE`). |
| **MISC / MISC_SET** | Comandos de mantenimiento y configuración (`VACUUM`, `SET`, `SET ROLE`, etc.). |
| **ALL** | Incluye todas las clases anteriores. |

> **Sintaxis de configuración (`pgaudit.log`):**
> * Puedes combinar varias clases separándolas por comas: `'read, write, ddl'`.
> * El prefijo `-` sirve para **excluir** una clase específica. 
> * **Ejemplo:** `'all, -misc'` audita **todo** excepto comandos de mantenimiento (`MISC`).



## 1. Estructura del Registro de Log (Formato de Auditoría)

Cada línea generada por `pgAudit` en los archivos de log de PostgreSQL sigue una estructura estándar con prefijo `AUDIT:`. A continuación se detallan los campos que componen un registro de auditoría:

| Campo | Descripción | Ejemplo / Valores |
| --- | --- | --- |
| **AUDIT_TYPE** | Tipo de auditoría activada. | `SESSION` (por tipo de comando) u `OBJECT` (por objeto específico). |
| **STATEMENT_ID** | Identificador único y secuencial de la sentencia dentro de la sesión. Representa la llamada enviada desde el cliente. | `1`, `2`, `3`... |
| **SUBSTATEMENT_ID** | Identificador secuencial para sub-consultas dentro de la sentencia principal (ej. llamadas a funciones internas). | `1`, `2`... |
| **CLASS** | Categoría del comando auditado. | `READ`, `WRITE`, `DDL`, `ROLE`, `FUNCTION`, `MISC`. |
| **COMMAND** | Tipo de instrucción ejecutada por PostgreSQL. | `SELECT`, `INSERT`, `ALTER TABLE`, `CREATE ROLE`. |
| **OBJECT_TYPE** | Tipo de objeto sobre el que se aplica la instrucción. | `TABLE`, `INDEX`, `VIEW`, `ROLE`, etc. *(si aplica)*. |
| **OBJECT_NAME** | Nombre completamente cualificado del objeto (`esquema.tabla` o nombre de entidad). | `public.cuentas`, `esquema.usuarios`. |
| **STATEMENT** | La sentencia SQL exacta que se ejecutó en la base de datos. | `SELECT * FROM cuentas WHERE id = 1;` |
| **PARAMETER** | Parámetros enviados si la consulta es preparada (`pgaudit.log_parameter = on`). | `'valor_1', 100` o `<none>` / `<not logged>`. |

> **Nota:** Un mismo `STATEMENT_ID` o `SUBSTATEMENT_ID` puede generar múltiples entradas de log si la consulta afecta a más de una tabla u objeto de forma simultánea.


## Estándares y Políticas que ayuda a cumplir

El uso de pgAudit es fundamental para que las empresas obtengan certificaciones internacionales de seguridad:

* **PCI-DSS:** Requisito 10 (Rastrear y monitorear todo el acceso a los recursos de red y datos de tarjetas).
* **SOC2:** Para auditorías de disponibilidad, integridad de procesamiento y confidencialidad.
* **HIPAA:** Seguridad de datos de salud, requiriendo registros de auditoría sobre quién accede a la información sensible de pacientes.
* **GDPR:** Para demostrar quién ha accedido o modificado datos personales de ciudadanos de la UE.
* **SOX:** Requisitos de control interno para la integridad de datos financieros.




## Formas de Auditar en pgAudit

pgAudit se puede aplicar en diferentes **niveles de alcance** y en dos **modos distintos**: **Sesión** (por tipo de comando) u **Objetos** (por tabla específica).


### 1. Niveles de Auditoría de Sesión

Audita según la clase de comando (`READ`, `WRITE`, `DDL`, etc.). Se evalúa de lo general a lo particular.

> **REGLA DE ORO:** La configuración más específica sobrescribe a la general. Si un nivel superior no quiere auditar por defecto, debe estar vacío o en `none`/`''`.

#### A. Nivel Global (`postgresql.conf`)

Aplica para absolutamente todo el servidor PostgreSQL.

```ini
# postgresql.conf
pgaudit.log = 'ddl, role'   # Solo audita DDL y Roles a nivel global

```

#### B. Nivel Base de Datos (`ALTER DATABASE`)

Aplica solo a las conexiones en una BD específica.

* **Condición:** Si no quieres auditar todo el servidor de forma global, en `postgresql.conf` debe estar apagado: `pgaudit.log = ''` (o `none`).

```sql
-- Solo audita escrituras dentro de la BD de finanzas
ALTER DATABASE bd_finanzas SET pgaudit.log = 'write';

```

#### C. Nivel Rol / Usuario (`ALTER ROLE`)

Aplica a usuarios específicos. Es ideal para **casos excepcionales**:

* **Caso 1: Reducir ruido (Ej. Usuario ETL)**
Si un proceso ETL hace miles de inserciones por minuto y no quieres saturar el log, puedes **desactivarle la auditoría solo a él**:
```sql
-- Apaga el logging para el usuario de la ETL aunque la BD tenga auditoría
ALTER ROLE usuario_etl SET pgaudit.log = 'none';

```


* **Caso 2: Monitorear un usuario de riesgo (Ej. Desarrollador)**
Si un desarrollador entra a producción, le auditas **todo** lo que haga sin afectar al resto de los usuarios:
```sql
-- Audita absolutamente todo lo que ejecute el usuario de desarrollo
ALTER ROLE sysdesarrollo SET pgaudit.log = 'all';

```




### 2. Auditoría de Objetos (Por Tabla/Columna)

En lugar de auditar por comandos o usuarios, auditas **una tabla en específico** (por ejemplo, la tabla `tarjetas_credito`), independientemente de quién la consulte.

#### Requisitos para que funcione:

1. En `postgresql.conf`, la auditoría de sesión **NO** debe capturar esa operación (o idealmente estar en `pgaudit.log = ''`), de lo contrario duplicarás logs.
2. Debes definir un **rol auditor** en `postgresql.conf` mediante `pgaudit.role`.

#### Ejemplo Práctico:

```ini
# 1. En postgresql.conf
pgaudit.log = 'none'              # Desactivamos auditoría de sesión general
pgaudit.role = 'auditor_pgaudit'  # Definimos el rol auditor

```

```sql
-- 2. En la base de datos: Creamos el rol y asignamos qué tabla auditar
CREATE ROLE auditor_pgaudit NOLOGIN;

-- Solo registrará cuando alguien lea o modifique la tabla 'tarjetas_credito'
GRANT SELECT, UPDATE ON TABLE tarjetas_credito TO auditor_pgaudit;

```


### Resumen de interacción entre niveles:

| Si quieres auditar a nivel... | En `postgresql.conf` debe haber: | Comando para activarlo: |
| --- | --- | --- |
| **Global** | `pgaudit.log = 'ddl, write'` | Directo en `postgresql.conf` |
| **Base de Datos** | `pgaudit.log = ''` | `ALTER DATABASE bd_app SET pgaudit.log = 'write';` |
| **Excepción de Usuario** | *(Cualquiera)* | `ALTER ROLE usuario_etl SET pgaudit.log = 'none';` |
| **Tabla Específica** | `pgaudit.log = ''`<br> <br>`pgaudit.role = 'auditor'` | `GRANT SELECT ON tabla TO auditor;` |


 
## 🛑 Lo que "nadie te dice" sobre `CREATE EXTENSION pgaudit`

En PostgreSQL, existe una confusión gigante entre cargar el motor (`shared_preload_libraries`) y activar la extensión (`CREATE EXTENSION`).

### La Gran Regla:

> **Cargar la extensión en `shared_preload_libraries` afecta a TODO el cluster (a todas las bases de datos). Pero ejecutar `CREATE EXTENSION pgaudit` solo afecta a la Base de Datos donde se ejecuta el comando.**



## 1. ¿Cuándo SÍ y cuándo NO ejecutar `CREATE EXTENSION`?

### 🟢 ¿Cuándo DEBES ejecutarlo?

Debes ejecutar `CREATE EXTENSION pgaudit;` en una base de datos si necesitas:

1. **Auditar eventos DDL** (`CREATE`, `ALTER`, `DROP` de tablas, funciones, etc.).
2. **Auditar eventos de Roles** (`GRANT`, `REVOKE`, `CREATE ROLE`, etc.).

**¿Por qué?** Porque estas auditorías dependen de los **Event Triggers** y **funciones C** que la extensión instala en el catálogo local de esa base de datos (como viste en tu salida `\dx+`). Sin esos 4 objetos, **no se auditará el DDL en esa BD específica**.

### 🔴 ¿Cuándo NO DEBES ejecutarlo (o es innecesario)?

1. **Si solo te interesa auditar DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`).**
* **El secreto:** `pgAudit` puede registrar lecturas y escrituras sin necesidad de correr `CREATE EXTENSION`. El motor en C intercepta las consultas a nivel de memoria global gracias a `shared_preload_libraries`.


2. **En bases de datos de sistema o plantillas (como `template1` o `postgres`).**
* A menos que quieras auditar los DDLs que ocurren dentro de `postgres` o `template1`, **no lo instales ahí**. Instálalo únicamente en las bases de datos de aplicación/negocio.


3. **Pensando que al ejecutarlo en `postgres` ya cubriste todo el servidor.**
* **FALSO.** Si tienes 5 bases de datos (`db_ventas`, `db_rrhh`, etc.) y solo ejecutas `CREATE EXTENSION pgaudit` en `db_ventas`, **las otras 4 bases de datos NO auditarán DDLs**, aunque tengas configurado `pgaudit.log = 'all'` en `postgresql.conf`.



## 2. ¿En qué afecta ejecutar `CREATE EXTENSION pgaudit`?

### A. Impacto en Rendimiento en Sentencias DDL

Cada vez que alguien ejecuta un `CREATE TABLE`, `ALTER TABLE` o `DROP TABLE`:

* PostgreSQL detiene la ejecución normal para invocar los **Event Triggers** (`pgaudit_ddl_command_end`).
* La función evalúa el comando en memoria y escribe el log de auditoría.
* **Afectación:** En operaciones DDL intensivas (por ejemplo, scripts de migración masivos, frameworks de ORM que crean tablas temporales constantemente), notará una **pequeña latencia extra** por cada instrucción DDL.

### B. Dependencia de Respaldo y Restauración (`pg_dump` / `pg_restore`)

* Al incluir objetos dentro del catálogo de la BD, `pg_dump` incluirá la instrucción `CREATE EXTENSION pgaudit;` en los archivos de respaldo.
* **El riesgo:** Si intentas restaurar ese dump en un servidor PostgreSQL que **NO** tiene compilada/instalada la librería física de `pgaudit` en el sistema operativo, **la restauración fallará**.

### C. Bloqueos durante la instalación / eliminación

* Ejecutar `CREATE EXTENSION` requiere un bloqueo de catálogo (`AccessExclusiveLock` breve). En bases de datos en producción con miles de transacciones por segundo, ejecutarlo de golpe podría causar una ligera pausa mientras obtiene el candado.


## 💡 Resumen Técnico para tu Documentación

```
                     ┌──────────────────────────────────────────────┐
                     │          shared_preload_libraries            │
                     │          (Carga el código en C)              │
                     └──────────────────────┬───────────────────────┘
                                            │
               ┌────────────────────────────┴────────────────────────────┐
               ▼                                                         ▼
    Auditoría DML (SELECT, INSERT...)                       Auditoría DDL y ROLES
    --------------------------------                        ---------------------
    • Funciona de forma GLOBAL.                             • Requiere 'CREATE EXTENSION pgaudit'
    • NO requiere objetos en la BD.                           en CADA Base de Datos donde 
    • Bajo consumo en memoria C.                              se quiera monitorear DDL.
                                                            • Instala Event Triggers locales.

```



## Registro de ejemplo - diferencias al ejecutar "CREATE EXTENSION"
```
-------------------------  ejemplo # 1  -------------------------

--- No se ejecuto  "CREATE EXTENSION"  - no lleno la columna object_type y object_name 
"2026-07-27 08:56:46.200588571 MST","postgres","db_test","2239243","[local]","6a677fa5.222b0b","DROP TABLE","2/3","765","00000","SESSION","2","1","DDL","DROP TABLE","","","drop table tb,<not logged>",,,,,,,,,"psql",,,,,,,

--- Se ejecuto  "CREATE EXTENSION" - se lleno la columna object_type y object_name
"2026-07-27 09:10:42.554204475 MST","postgres","db_test","2239963","[local]","6a6781b8.222ddb","DROP TABLE","8/9","770","00000","SESSION","8","1","DDL","DROP TABLE","TABLE","public.tb","drop table tb,<not logged>",,,,,,,,,"psql",,,,,,,



-------------------------  ejemplo # 2  -------------------------


--- No se ejecuto  "CREATE EXTENSION" - no se lleno la columna object_type  
"2026-08-02 16:58:41.831309950 MST","postgres","postgres","3114859","[local]","6a6fd98a.2f876b","CREATE ROLE","0/5","887","00000","SESSION","3","1","ROLE","CREATE ROLE","","","create user jose,<not logged>",,,,,,,,,"psql",,,,,,,
"2026-08-02 16:58:44.614635068 MST","postgres","postgres","3114859","[local]","6a6fd98a.2f876b","GRANT","0/6","888","00000","SESSION","4","1","ROLE","GRANT","","","\"grant select,insert,update,delete,truncate on table hash_source to jose\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-08-02 16:58:48.788945221 MST","postgres","postgres","3114859","[local]","6a6fd98a.2f876b","REVOKE","0/7","889","00000","SESSION","5","1","ROLE","REVOKE","","","\"revoke update,delete,truncate on table hash_source from jose\",<not logged>",,,,,,,,,"psql",,,,,,,



--- Se ejecuto  "CREATE EXTENSION"  - se lleno la columna object_type  
"2026-08-02 16:56:51.166091355 MST","postgres","postgres","3114729","[local]","6a6fd92b.2f86e9","CREATE ROLE","0/5","881","00000","SESSION","1","1","ROLE","CREATE ROLE","","","create user jose,<not logged>",,,,,,,,,"psql",,,,,,,
"2026-08-02 16:57:10.023647312 MST","postgres","postgres","3114729","[local]","6a6fd92b.2f86e9","GRANT","0/6","882","00000","SESSION","2","1","ROLE","GRANT","TABLE","","\"grant select,insert,update,delete,truncate on table hash_source to jose\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-08-02 16:57:41.573106970 MST","postgres","postgres","3114729","[local]","6a6fd92b.2f86e9","REVOKE","0/7","883","00000","SESSION","3","1","ROLE","REVOKE","TABLE","","\"revoke update,delete,truncate on table hash_source from jose\",<not logged>",,,,,,,,,"psql",,,,,,,



-------------------------  ejemplo # 3 -------------------------

--- No se ejecuto  "CREATE EXTENSION" -
"2026-08-02 17:07:39.707744809 MST","postgres","postgres","3115524","[local]","6a6fdb9f.2f8a04","SELECT","0/5","0","00000","SESSION","4","1","READ","SELECT","","","select * from hash_source limit 1,<not logged>",,,,,,,,,"psql",,,,,,,
"2026-08-02 17:08:07.141972784 MST","postgres","postgres","3115524","[local]","6a6fdb9f.2f8a04","UPDATE","0/6","0","00000","SESSION","5","1","WRITE","UPDATE","","","update hash_source set username = 'otro' where username = 'admin_app',<not logged>",,,,,,,,,"psql",,,,,,,
"2026-08-02 17:08:27.332897431 MST","postgres","postgres","3115524","[local]","6a6fdb9f.2f8a04","DELETE","0/7","0","00000","SESSION","6","1","WRITE","DELETE","","","delete from hash_source where username = 'otro',<not logged>",,,,,,,,,"psql",,,,,,,


--- Se ejecuto  "CREATE EXTENSION"
"2026-08-02 17:10:13.078909602 MST","postgres","postgres","3115852","[local]","6a6fdc62.2f8b4c","SELECT","0/2","0","00000","SESSION","1","1","READ","SELECT","","","select * from hash_source limit 1,<not logged>",,,,,,,,,"psql",,,,,,,
"2026-08-02 17:10:28.655157481 MST","postgres","postgres","3115852","[local]","6a6fdc62.2f8b4c","UPDATE","0/3","0","00000","SESSION","2","1","WRITE","UPDATE","","","update hash_source set username = 'otro' where username =   'qa_user',<not logged>",,,,,,,,,"psql",,,,,,,
"2026-08-02 17:10:34.750177966 MST","postgres","postgres","3115852","[local]","6a6fdc62.2f8b4c","DELETE","0/4","0","00000","SESSION","3","1","WRITE","DELETE","","","delete from hash_source where username = 'otro',<not logged>",,,,,,,,,"psql",,,,,,,


```

### El análisis de tu log (CSV)

Si observamos las columnas 16 y 17 de tu formato CSV, que corresponden a **`object_type`** y **`object_name`**, la diferencia salta a la vista:

**1. Sin la extensión creada (Solo con la librería en memoria):**

> `"DDL", "DROP TABLE", "", "", "drop table tb,<not logged>"`

El hook principal de Postgres (`ProcessUtility_hook`) interceptó que se ejecutó un comando DDL de tipo `DROP TABLE`, pero se quedó "ciego" respecto a qué objeto exacto y en qué esquema sucedió, por lo que dejó los campos vacíos (`""`, `""`).

**2. Con la extensión instalada:**

> `"DDL", "DROP TABLE", "TABLE", "public.tb", "drop table tb,<not logged>"`

Aquí el contexto forense es perfecto. Te dice exactamente que se eliminó una `"TABLE"` y su nombre completamente cualificado: `"public.tb"`.



### ¿Por qué sucede esto exactamente? (Tu deducción técnica)

Como bien intuiste, cargar la librería en el `postgresql.conf` solo inyecta el código C en el motor. Pero cuando ejecutas `CREATE EXTENSION pgaudit;` en una base de datos, PostgreSQL ejecuta un script SQL interno que crea **Event Triggers** (Disparadores de Eventos).

Si revisas el código fuente de pgAudit, al instalar la extensión se crean específicamente estos dos disparadores:

1. **`pgaudit_ddl_command_end`**: Se dispara con el evento `ddl_command_end` y utiliza la función interna `pg_catalog.pg_event_trigger_ddl_commands()`. Esto permite auditar qué se creó o alteró, extrayendo el OID, el esquema y el nombre exacto del objeto recién procesado.
2. **`pgaudit_sql_drop`**: Se dispara con el evento `sql_drop` y utiliza `pg_catalog.pg_event_trigger_dropped_objects()`. Esta es vital porque, cuando haces un `DROP`, el objeto **ya no existe** en el catálogo de Postgres para cuando el log se va a escribir. Esta función permite recuperar la información del objeto (esquema, nombre, tipo) justo en el momento en que está siendo destruido.

### Conclusión para tu entorno de producción

Tu prueba confirma la regla de oro de pgAudit:

Si tienes configurado `pgaudit.log = 'ddl'` (o `'all'` como en tu caso) de manera global, **debes ejecutar `CREATE EXTENSION pgaudit;` en absolutamente todas las bases de datos** de tu clúster donde te interese saber *qué* se modificó o eliminó. Si no lo haces, los auditores de seguridad te rechazarán el log porque un `DROP TABLE` sin saber qué tabla fue eliminada es inútil para un análisis forense.

 

---

# 1. ¿Qué es pgauditlogtofile?

Es un **complemento (addon)** para pgAudit. Mientras que pgAudit se encarga de *generar* los registros de auditoría (quién leyó qué, quién borró qué), por defecto PostgreSQL envía esos registros al mismo archivo de log donde van los errores del sistema, los inicios de sesión y las consultas lentas.

**pgauditlogtofile sirve para separar la auditoría del log principal.** Envía todos los datos de pgAudit a un archivo de texto independiente.

### 2. ¿Para qué sirve realmente? (Beneficios)

* **Limpieza:** Evita que el log de errores de Postgres se llene con miles de líneas de auditoría, lo que facilita encontrar errores reales del servidor.
* **Seguridad:** Puedes tener un archivo de auditoría con permisos de sistema de archivos restringidos, separado de los logs normales.
* **Rotación automática:** Permite rotar los archivos de auditoría cada cierto tiempo (por ejemplo, cada hora o cada día) sin afectar al log principal de la base de datos.
* **Fácil ingesta:** Si usas herramientas como Splunk, ELK Stack (Elasticsearch) o Datadog, es mucho más fácil leer un archivo que contiene *solo* auditoría que uno que mezcla errores, advertencias y auditoría.
 
### 3. Ejemplo de un caso de uso real

Imagina que trabajas en el departamento de TI de un **Banco**.

#### El Escenario:

Tienes una base de datos con una tabla llamada `cuentas_clientes`. Por regulaciones bancarias (como PCI-DSS o GDPR), estás obligado a registrar cada vez que alguien consulta el saldo de un cliente.

#### El Problema sin pgauditlogtofile:

1. Activas **pgAudit** y empieza a registrar cada `SELECT` en la tabla de cuentas.
2. Tu servidor tiene mucho tráfico, por lo que el archivo `postgresql.log` crece 10GB al día.
3. Cuando ocurre un error real en la base de datos (por ejemplo, un disco lleno o un crash), el administrador no puede encontrar el error porque hay un "ruido" inmenso de miles de registros de auditoría mezclados.

#### La Solución con pgauditlogtofile:

Configuras la extensión para que:

* El log de errores siga yendo a `/var/log/postgresql/postgresql.log`.
* Toda la auditoría se guarde en `/var/log/audit/banco_audit-%Y%m%d.log`.

**Resultado:**

* **Cumplimiento legal:** Tienes tus archivos de auditoría limpios y listos para el auditor.
* **Operatividad:** El DBA puede ver los errores del servidor rápidamente en el log normal.
* **Seguridad:** El equipo de seguridad tiene acceso de "solo lectura" a la carpeta `/var/log/audit/`, pero no necesitan entrar a ver los logs del sistema de la base de datos.

### Diferencias clave:

| Característica | pgAudit | pgauditlogtofile |
| --- | --- | --- |
| **Función** | Decide **QUÉ** se audita (SELECTs, INSERTs, etc). | Decide **DÓNDE** se guarda físicamente esa auditoría. |
| **Dependencia** | Independiente. | Requiere que pgAudit esté instalado y funcionando. |
| **Destino** | El log estándar de PostgreSQL (`stderr`, `syslog`). | Un archivo `.log` dedicado e independiente. |

**En resumen:** Usa **pgAudit** para generar la información y **pgauditlogtofile** para que esa información no sea un caos y sea fácil de administrar por separado.


---



# 1. Propósitos Distintos log vs pgaudit

* **Logging Nativo:** Está diseñado para **operaciones y resolución de problemas (troubleshooting)**. Te dice si una consulta fue lenta, si hubo un error o si se perdió una conexión. Es una herramienta para DBAs.
* **pgAudit:** Está diseñado para **cumplimiento y auditoría**. Su objetivo es proporcionar un rastro detallado de "quién hizo qué y cuándo" para satisfacer auditorías gubernamentales o financieras.

### 2. Diferencias Técnicas Clave

El artículo destaca 5 áreas donde pgAudit supera al logging estándar:

* **Estructura y Claridad:** Mientras que el log nativo es verboso y desordenado, pgAudit genera líneas con el prefijo `AUDIT:` y un formato CSV consistente que facilita su análisis por herramientas externas (como SIEMs).
* **Seguridad de Datos (Redacción):** El logging nativo puede exponer contraseñas en texto plano en los archivos de log (ej. al ejecutar `CREATE USER`). **pgAudit redacta automáticamente** información sensible, sustituyéndola por `<REDACTED>`.
* **Categorización de Operaciones:** pgAudit etiqueta cada acción explícitamente como `READ`, `WRITE`, `DDL` o `ROLE`. Esto permite que un auditor busque rápidamente "todos los accesos de lectura a datos sensibles" sin tener que interpretar cada consulta SQL manualmente.
* **Rastreo de Sesiones:** Incluye IDs de sesión y contadores de sentencias que permiten reconstruir exactamente el flujo de consultas de un usuario, facilitando la forense digital.
* **Granularidad:** Permite auditar objetos específicos (Tablas) o sesiones completas, lo que ayuda a balancear el nivel de detalle vs. el impacto en el rendimiento.

### 3. Mejores Prácticas mencionadas

Neon recomienda no quedarse solo con la generación de logs, sino:

1. **Centralizar:** Enviar los logs a un repositorio externo (Splunk, ELK, Datadog).
2. **Alertar:** Configurar alertas automáticas ante actividades sospechosas.
3. **Retener:** Mantener los logs por periodos largos (HIPAA exige 6 años).

---


 
# Ejemplos 

Para que `pgaudit` intercepte las consultas y `pgauditlogtofile` secuestre esos mensajes antes de que toquen el log principal, debes modificar el archivo `postgresql.conf` con los siguientes parámetros a nivel de sistema e interceptor.

### 1. Parámetros de Inyección en Memoria (PostgreSQL Core)
```sql
# ==============================================================================
# CONFIGURACIÓN RECOMENDADA EN PRODUCCIÓN: pgAudit + pgauditlogtofile
# ==============================================================================

# 1. CARGA DE LIBRERÍAS (Requiere reiniciar el servicio)
shared_preload_libraries = 'pgaudit, pgauditlogtofile'

# 2. ALMACENAMIENTO Y FORMATO DE LOGS
# Se recomienda usar formato JSON para integraciones limpias con Datadog, ELK o SIEM.
pgaudit.log_directory = '/var/log/postgresql/audit'   # Ruta absoluta recomendada
pgaudit.log_filename = 'audit-%Y%m%d_%H%M.log'        # Archivos fechados
pgaudit.log_format = 'json'                           # 'json' o 'csv' según tu colector
pgaudit.log_file_mode = '0600'                        # Solo lectura/escritura para usuario postgres

# 3. ROTACIÓN Y MANTENIMIENTO
pgaudit.log_rotation_age = 1440                       # Rotación diaria (1440 min)
pgaudit.log_autoclose_minutes = 10                    # Cierra manejadores inactivos tras 10 min

# 4. COMPRESIÓN (Optimización de Disco y CPU)
# LZ4 ofrece compresión nativa ultrarrápida con menor consumo de CPU que gzip.
pgaudit.log_compression = 'lz4'                       # 'off', 'lz4' o 'zstd'
pgaudit.log_compression_level = 0                     # 0 usa la velocidad/compresión por defecto

# 5. AUDITORÍA DE CONEXIONES Y SESIONES
pgaudit.log_connections = on                          # Intercepta eventos de inicio de sesión
pgaudit.log_disconnections = on                       # Intercepta eventos de cierre de sesión

# 6. TELEMETRÍA DE EJECUCIÓN (Avanzado / Opcional)
pgaudit.log_execution_time = off                      # Poner 'on' solo si necesitas auditar latencias
pgaudit.log_execution_memory = off                    # Poner 'on' solo si haces auditoría de recursos
```
---


### 🏛️ DICTAMEN TÁCTICO: El Motor (C) vs. El Diccionario (SQL)

**Marcos (Arquitectura) y Diego (Seguridad de Datos):**

Para entender esto, debes saber que pgAudit está dividido en dos partes que operan en niveles diferentes del servidor:

**1. El Hook a Nivel de Kernel (La Librería C)**
Cuando tú agregas `shared_preload_libraries = 'pgaudit'` en `postgresql.conf` y reinicias, estás inyectando el código C compilado directamente en las venas (la memoria compartida) de toda la instancia de PostgreSQL. **Este motor de intercepción ya está vivo y escuchando absolutamente todo el tráfico de la instancia**, independientemente de las bases de datos que tengas.

**2. Los Objetos SQL (CREATE EXTENSION)**
Cuando ejecutas `CREATE EXTENSION pgaudit;` dentro de una base de datos específica, solo estás instalando los objetos lógicos (vistas, funciones y permisos) que pgAudit necesita para hacer **Auditoría de Precisión (Object Auditing)** usando `pgaudit.role`.
 

### 🚨 EL RIESGO DE LA AUDITORÍA DE SESIÓN (Session Auditing)

Aquí está el secreto letal que justifica el uso de `ALTER DATABASE`:

El parámetro `pgaudit.log = 'write, ddl'` controla la **Auditoría de Sesión**. Este tipo de auditoría es procesada directamente por el *Hook de C en la memoria*, **NO requiere que la extensión lógica esté instalada con `CREATE EXTENSION` para funcionar.**

* **Si lo pones en `postgresql.conf` (Global):** El *Hook* despertará y comenzará a registrar los `write` y `ddl` de **TODAS** las bases de datos de tu instancia (la de tarjetas, la de pruebas, la de monitoreo). No le importará en lo absoluto que no hayas ejecutado `CREATE EXTENSION` en ellas. Esto colapsará el I/O de tu disco.
* **Si usas `ALTER DATABASE base_datos_banco SET pgaudit.log = 'write, ddl';`:** Le estás dando una orden de aislamiento al motor. Le estás diciendo al *Hook* global: *"Ignora todas las conexiones de la instancia. Solo enciende tus sensores de auditoría de sesión cuando el usuario esté conectado a esta base de datos específica"*.



---


 
## FASE 2: Manual de Hardening Forense (PostgreSQL Core & pgAudit)

**Clasificación de Documento:** C-Nivel (Crítico / Confidencial)
**Propósito:** Cumplimiento PCI DSS Req. 10 (Rastreo y Monitoreo) y mitigación de fuga de datos en texto plano.

### I. Arquitectura Forense: Core Logs (El Cimiento)

Esta matriz gobierna cómo PostgreSQL escribe su bitácora nativa.

| Parámetro | Valor Exigido | Justificación Táctica (PCI DSS) |
| --- | --- | --- |
| **logging_collector** | `on` | Obligatorio. Atrapa los logs en un proceso de fondo. Si está en `off`, los logs se pierden o inundan la consola del SO. |
| **log_directory** | `pg_log` | Aísla físicamente los logs del core de datos (`pg_wal` y base). |
| **log_file_mode** | `0600` | **Crítico.** Solo el usuario `postgres` puede leer. Bloquea que un usuario comprometido del SO lea la bitácora. |
| **log_filename** | `postgresql-%y%m%d.log` | Facilita la rotación diaria y la recolección automatizada por agentes SIEM. |
| **log_truncate_on_rotation** | `on` | Previene que discos duros se saturen sobrescribiendo archivos viejos (depende de `log_rotation_age`). |
| **log_rotation_age** | `1440` | Forzar rotación cada 24 horas. Evita archivos de 50GB imposibles de analizar. |
| **log_rotation_size** | `0` | Apagado. Nunca rotar por tamaño; rompe la secuencia cronológica para el SIEM. |
| **log_timezone** | `America/Mazatlan` | Sincronización NTP exacta. Un log sin hora correcta es inválido en un juicio o auditoría. |
| **log_line_prefix** | `<%t %r %a %d %u %p %c %i>` | **Crítico.** (Tiempo, IP, App, BD, Usuario, PID). El auditor buscará esta cadena exacta. |
| **log_connections** | `on` | **PCI Req. 10.** Registra quién entra y desde dónde. |
| **log_disconnections** | `on` | **PCI Req. 10.** Permite calcular el tiempo de exposición de la sesión. |
| **log_checkpoints** | `on` | Rastreabilidad de IOPS; vital para correlacionar caídas de rendimiento. |
| **log_lock_waits** | `on` | Detecta bloqueos mayores a 1s (Deadlocks o queries asesinos). |
| **log_error_verbosity** | `default` | Detalle justo. `verbose` fugaría código interno del motor. |
| **log_min_messages** | `warning` | Filtra ruido innecesario (INFO/NOTICE) que saturaría el disco. |
| **log_min_error_statement** | `error` | Registra el query fallido, pero el parámetro siguiente impide fuga de datos. |
| **log_parameter_max_length_on_error** | `0` | **Crítico.** Si un INSERT falla, evita que el valor (ej. la tarjeta) se imprima en el log de error. |
| **log_statement** | `ddl` | **Veto de Seguridad.** Cambiado de `all` a `ddl`. (Explicación detallada abajo). |
| **log_temp_files** | `1024` | Audita queries pesados (ej. `ORDER BY` sin índice) que escriben más de 1MB a disco. |

*(Nota: Los parámetros estadísticos y de muestreo como `log_executor_stats`, `log_min_duration_sample`, etc., deben permanecer en `off` o `-1` para no penalizar el rendimiento del servidor).*

 

### II. Arquitectura de Blindaje: pgAudit & pgAuditLogToFile (El Escudo)

Esta matriz gobierna la auditoría fina. `pgaudit` vigila, y `pgauditlogtofile` extrae los registros hacia un archivo separado, evitando contaminar el log principal.

| Parámetro | Valor Exigido | Justificación Táctica (PCI DSS) |
| --- | --- | --- |
| **pgaudit.log** | `write, ddl, role` | Audita INSERT/UPDATE/DELETE (`write`), cambios de estructura (`ddl`) y cambios de permisos (`role`). |
| **pgaudit.log_parameter** | `off` | **Regla de Oro PCI.** Jamás guarda el valor inyectado en el query (protege PAN/CVV). |
| **pgaudit.log_level** | `log` | Clasificación segura para el SIEM. |
| **pgaudit.log_catalog** | `off` | Modificado a OFF. Si está en ON, audita las consultas internas de Postgres. Genera gigabytes de ruido inútil. |
| **pgaudit.log_client** | `off` | Evita que el mensaje "Audit:..." se imprima en la pantalla del atacante o del desarrollador. |
| **pgaudit.log_statement** | `on` | Imprime la estructura del query auditado. |
| **pgaudit.log_statement_once** | `off` | Obliga a imprimir cada ejecución en rutinas masivas, no solo un resumen. |
| **pgaudit.log_parameter_max_size** | `0` | Refuerza físicamente a `log_parameter = off`. |
| **pgaudit.log_relation** | `off` | Apagado. Evita registrar masivamente cada tabla tocada en un JOIN complejo. |
| **pgaudit.log_rows** | `off` | Apagado. Evita inundar el disco con el conteo de filas afectadas. |
| **pgaudit.role** | `auditor_role` | Asigna un rol específico. Permite auditar tablas vinculadas a este rol, no toda la base. |

 
### III. Análisis de Impacto y Estrategia

**Rodrigo (Gatekeeper) responde a tu pregunta:**
*"¿Si guardo `log_statement = ddl` y `pgaudit.log = ddl`, se va a duplicar la información?"*

**Respuesta Directa:** Sí, se va a duplicar el registro del DDL (ej. `CREATE TABLE`). El log nativo lo guardará, y el archivo de pgAudit también.
**Veredicto:** **Se acepta la duplicidad.** En entornos críticos, preferimos tener un DDL duplicado (que ocurre rara vez en producción) a apagar el `log_statement` del motor base. Si pgAudit falla por un error de librerías, el motor base seguirá siendo tu respaldo legal para rastrear quién borró una tabla. La redundancia en eventos estructurales es una táctica defensiva, no un error.

#### 1. Malas Prácticas Comunes (Lo que NO debes hacer)

* **Activar `log_statement = all`:** Reprobatorio automático PCI. Guarda números de tarjeta en texto plano.
* **Activar `pgaudit.log_catalog = on`:** El motor consulta sus propias tablas internas (catálogo) miles de veces por segundo. Auditar esto paralizará tu disco (I/O Wait) y saturará tu SIEM con ruido.
* **Dejar `log_file_mode` por defecto (0640 o 0644):** Permite que cualquier usuario del sistema operativo (un becario o un atacante) lea los logs de la base de datos.
* **Rotación por Tamaño (`log_rotation_size > 0`):** Crea archivos como `log.1`, `log.2` a mitad del día, rompiendo la secuencialidad que exigen las herramientas de análisis forense (SIEM).

#### 2. Limitantes y Requisitos

* **Requisito de Infraestructura:** El uso de `logging_collector` y `pgauditlogtofile` requiere que el disco físico donde reside `pg_log` tenga alta capacidad de I/O (IOPS) y monitoreo de espacio estricto. Si este disco se llena, PostgreSQL puede detenerse en seco.
* **Requisito de Retención (PCI Req 10.7):** Los logs diarios deben ser recolectados por un SIEM y retenidos por al menos 1 año, con 3 meses de disponibilidad inmediata.
* **Limitante de Rendimiento:** Aunque pgAudit está optimizado, auditar cada transacción (`write`) añade latencia (overhead). Samuel (Infraestructura) debe monitorear el consumo de CPU y los tiempos de espera de disco (I/O Wait).

#### 3. Tipos de Auditoría Soportados por esta Configuración

* **PCI DSS (Sector Financiero):** Pasa sin observaciones. Demuestra protección de datos del titular (no hay tarjetas en el log) y trazabilidad completa (conexiones y comandos DDL/DML).
* **ISO 27001 (Seguridad de la Información):** Cumple con los controles de registro de eventos, protección de la información de registro y sincronización de relojes.
* **Auditorías Forenses Internas:** Permite reconstruir líneas de tiempo exactas (quién se conectó, qué ejecutó, desde qué IP y a qué hora exacta).
 

> **DICTAMEN FINAL DEL SQUAD:**
> Esta configuración no solo "funciona"; es una arquitectura forense diseñada para ser letal contra intrusiones internas y completamente transparente ante un auditor externo. Aplica la matriz, reinicia el motor y entrega el sistema.




---

 

##    ¿Para qué sirve `pgaudit.role`?

**Diego (Seguridad de Datos)** y **Mauricio (Gobierno)** exigen el uso de este parámetro porque es la diferencia entre un bombardeo a ciegas y un ataque quirúrgico.

* **El Problema Operativo:** Si activas pgAudit a nivel global (`pgaudit.log = 'all'`), el motor auditará **cada tabla, cada vista y cada fila** de la base de datos. Esto genera un "ruido" masivo, satura los discos de I/O en horas, y le cuesta a la empresa miles de dólares en almacenamiento SIEM inútil.
* **El Objetivo de `pgaudit.role`:** Te permite crear un rol "fantasma" o maestro (por ejemplo, `rol_auditor_pci`). Su función no es iniciar sesión, sino actuar como una **etiqueta de vigilancia**.
* **¿Cómo funciona?** Le asignas permisos a ese rol **solo sobre las tablas críticas** (ej. `GRANT SELECT, INSERT ON tabla_tarjetas TO rol_auditor_pci;`). Al configurar `pgaudit.role = 'rol_auditor_pci'` en `postgresql.conf`, pgAudit **ignorará el resto de la base de datos** y solo registrará las transacciones que toquen los objetos vinculados a ese rol. Es vigilancia asimétrica y de precisión absoluta.

 

## 📖 GLOSARIO TÁCTICO: Preguntas Frecuentes del DBA Squad y la Comunidad

Este es el interrogatorio al que **Rodrigo (Gatekeeper)** somete a cualquier equipo que intenta implementar pgAudit. Úsalo para defender tu arquitectura.

### I. Ciberseguridad y Fuga de Datos

**Q1: "Si pgAudit intercepta el query, ¿por qué los números de tarjeta no se guardan en el archivo físico?"**

> **Valeria (Normativa):** Porque aplicamos la *Regla de Oro* (`pgaudit.log_parameter = off`). pgAudit está diseñado nativamente para separar la estructura de la consulta (el *Statement*) de las variables (los *Parameters*). Si un desarrollador usa consultas parametrizadas (`INSERT INTO tarjetas VALUES ($1, $2)`), el motor imprimirá exactamente eso en el log: `$1 y $2`. El dato real se procesa en RAM y muere ahí, cumpliendo con PCI DSS.

**Q2: "¿Puede un atacante o un DBA malicioso apagar pgAudit para borrar sus huellas?"**

> **Diego (Seguridad):** A nivel de base de datos, no. Para apagar pgAudit o quitarlo de `shared_preload_libraries`, se requiere acceso de superusuario (`postgres`) **y** un reinicio total del servicio a nivel del sistema operativo. Ese reinicio dispara alertas inmediatas en el balanceador de carga y en el SIEM. Es un sistema a prueba de sabotaje interno.

**Q3: "¿Por qué no usamos simplemente el log nativo con `log_statement = all` en vez de instalar extensiones de terceros?"**

> **Rodrigo (Gatekeeper):** Porque el log nativo es "tonto" en términos de enmascaramiento. Si pones `log_statement = all`, escribirá las consultas operativas en texto plano directamente al disco, exponiendo contraseñas, PANs y CVVs. Eso es una violación de Nivel 1 en cualquier auditoría. pgAudit es obligatorio en entornos regulados precisamente por su capacidad de ofuscación.

 
### II. Infraestructura y Tolerancia a Fallos

**Q4: "Si configuramos `pgauditlogtofile` para enviar la auditoría a un directorio separado, ¿qué pasa si ese disco se llena?"**

> **Samuel (S.O. Linux) y Javier (Disponibilidad):** Si el directorio físico configurado en `pgauditlogtofile.log_directory` llega al 100% de capacidad, el sistema operativo (Linux) bloqueará las escrituras. Como la auditoría de PostgreSQL es síncrona por diseño de seguridad, **la base de datos detendrá todas las transacciones nuevas** (se colgará) para evitar operar sin ser auditada. Por eso, el directorio de logs debe estar monitoreado agresivamente con alertas al 70% y 85% de capacidad.

**Q5: "¿Activar pgAudit degradará el rendimiento de mi base de datos transaccional (CPU/RAM)?"**

> **Marcos (Arquitectura):** Sí, todo proceso de auditoría genera un *overhead* (latencia). Sin embargo, con nuestra matriz de hardening, el impacto es inferior al 5%. Al mantener `pgaudit.log_catalog = off` (evitando auditar los metadatos internos) y usar `pgaudit.role` para focalizar la vigilancia, reducimos el I/O en un 90% comparado con una configuración novata.

 

### III. Comportamiento y Anomalías del Log

**Q6: "Estoy viendo consultas duplicadas de creación de tablas (`CREATE TABLE`). Una en el log principal y otra en el log de auditoría. ¿Es un error?"**

> **Mauricio (QA-SQL):** No, es redundancia táctica intencional. Mantuvimos `log_statement = ddl` en el motor base. Los eventos de manipulación de estructura (DDL) son raros pero destructivos. Preferimos tener una doble bitácora forense de quién alteró o borró una tabla, por si el archivo de pgAudit sufre alguna inconsistencia externa.

**Q7: "¿Qué significa el mensaje `LOG: AUDIT: SESSION,1,1,DDL,CREATE ROLE...` y cómo lo lee mi SIEM?"**

> **Lucas (Integración):** pgAudit utiliza un formato CSV inyectado dentro del log. Los valores separados por comas representan: `Tipo de auditoría (SESSION u OBJECT)`, `ID de transacción`, `Sub-ID`, `Clase de comando (DDL/WRITE)` y `El comando exacto`. Esta estructura predecible es la que permite a QRadar o Splunk parsear los datos matemáticamente usando expresiones regulares (Regex) sin requerir intervención humana.

**Q8: "¿Por qué no auditamos los comandos SELECT si también pueden exfiltrar datos?"**

> **Valeria (Normativa):** Auditar el 100% de los `SELECT` en un Core Bancario satura el sistema operativo en menos de 24 horas. PCI DSS exige rastrear el *acceso* a la base (conexiones) y las *modificaciones* (DML/DDL). Si necesitas auditar quién lee una tabla ultasecreta (como una bóveda de llaves de cifrado), usas `pgaudit.role` exclusivamente sobre esa tabla con el permiso de lectura, manteniendo el resto del sistema libre de fricción.



### IV. Cuestiones Arquitectónicas y Operativas (Precisión de Fuego)

**8. Si configuro `DDL, DML, READ, ROLE` en `pgaudit.log` de forma global, ¿esto auditará todas las bases de datos de mi instancia?**

> **Rodrigo (Gatekeeper):** Sí. Si configuras `pgaudit.log = 'ddl, write, read, role'` directamente en el archivo `postgresql.conf`, le estás dando una orden global al kernel. Esto significa que el motor auditará **cada tabla, de cada esquema, de todas las bases de datos** dentro de esa instancia.
> *Nota Crítica:* Esto generará un colapso de infraestructura (*I/O Bottleneck*). El motor escribirá un registro en disco por cada simple `SELECT 1` o lectura interna, congelando la base de datos por latencia de escritura y costando una fortuna en almacenamiento SIEM. Además, `DML` no existe en la sintaxis de pgAudit; las clases correctas son `write` (INSERT, UPDATE, DELETE) y `read` (SELECT).
> **Diego (Seguridad de Datos) añade:** Para evitar saturar el servidor, usa tácticas de aislamiento. No configures esto en `postgresql.conf`. Aplica las reglas a nivel de Base de Datos (`ALTER DATABASE`) o, preferentemente, a nivel de Tabla usando el parámetro `pgaudit.role`.

 
**9. ¿Para qué sirve el parámetro `pgaudit.role` y cuál es su objetivo principal?**

> **Diego (Seguridad de Datos):** Es la diferencia entre un bombardeo a ciegas y un ataque quirúrgico. Su objetivo es permitirte crear un rol "fantasma" o maestro (por ejemplo, `rol_auditor_pci`) cuya función no es iniciar sesión, sino actuar como una **etiqueta de vigilancia**.
> Le asignas permisos a ese rol **solo sobre las tablas críticas** (ej. `GRANT SELECT, INSERT ON tabla_tarjetas TO rol_auditor_pci;`). Al configurar `pgaudit.role = 'rol_auditor_pci'` en `postgresql.conf`, pgAudit ignorará el resto de la base de datos y solo registrará las transacciones que toquen los objetos vinculados a ese rol. Es vigilancia de precisión absoluta.


---



### 📚 Casos de Uso Comunes en Producción y sus Configuraciones

Para todos los casos de uso asumiremos que `pgaudit` y `pgauditlogtofile` ya están en `shared_preload_libraries` en tu `postgresql.conf`.



#### Caso 1: Mínimo Impacto / Cumplimiento Básico de Seguridad (Solo DDL y Cambios de Roles)

* **Objetivo:** Registrar únicamente cuándo se crean/modifican/eliminan tablas, funciones, vistas o cuando se modifican usuarios, contraseñas y permisos. No audita lecturas ni escrituras de datos (`SELECT`, `INSERT`, `UPDATE`).
* **Ventaja:** Cero impacto apreciable en el rendimiento (IOPS) y archivos de log muy pequeños.

**Configuración (`postgresql.conf`):**

```ini
# En el archivo de configuración global
pgaudit.log = 'ddl, role'

```

*(No requiere ejecutar ningún comando SQL en las bases de datos).*


#### Caso 2: Auditoría por Base de Datos Crítica (Entorno Multi-tenant)

* **Objetivo:** Tienes 10 bases de datos en la misma instancia, pero solo la base de datos `orders` (que procesa pagos) necesita auditar lecturas y escrituras por normativa PCI-DSS. Las otras 9 bases de datos no deben generar logs extra de auditoría.

**Paso 1: Configurar nivel global bajo (`postgresql.conf`)**

```ini
# No poner 'all' globalmente
pgaudit.log = 'ddl, role' 

```

*(Luego ejecuta `SELECT pg_reload_conf();`)*

**Paso 2: Aplicar la regla granular en la base de datos específica**

```sql
-- Conectado a la instancia de Postgres:
ALTER DATABASE orders SET pgaudit.log = 'read, write, ddl, role';

```

* **Resultado:** Las bases de datos normales solo auditarán cambios de estructura (`ddl, role`), mientras que `orders` registrará también todos los `SELECT`, `INSERT`, `UPDATE` y `DELETE`.



#### Caso 3: Auditoría por Objeto / Tabla Sensible (Reducción Máxima de Log)

* **Objetivo:** En la base de datos `orders` hay millones de transacciones por minuto en tablas temporales o de métricas que **no** quieres auditar. Solo necesitas auditar quién consulta o modifica la tabla `public.tarjetas_credito`.

**Paso 1: Configuración en `postgresql.conf**`

```ini
pgaudit.log = 'none' # O dejas solo 'ddl, role'

```

**Paso 2: Crear el rol de auditoría y la extensión (SQL)**

```sql
-- 1. Conéctate a la base de datos 'orders'
\c orders

-- 2. Crea la extensión (AQUÍ SÍ ES OBLIGATORIO)
CREATE EXTENSION pgaudit;

-- 3. Crea un rol de auditoría (sin permisos de login)
CREATE ROLE auditor_objetos NOLOGIN;

-- 4. Otorga al rol permisos sobre la tabla que quieres auditar
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.tarjetas_credito TO auditor_objetos;

-- 5. Configura pgaudit para que use ese rol en la base de datos
ALTER DATABASE orders SET pgaudit.role = 'auditor_objetos';

```

* **Resultado:** Cada vez que *cualquier usuario* ejecute un `SELECT` o `UPDATE` sobre la tabla `tarjetas_credito`, `pgaudit` lo registrará. Todas las demás tablas del sistema serán ignoradas por la auditoría, ahorrando gigabytes de almacenamiento en disco.



#### Caso 4: Excluir Usuarios de Servicio / Procesos Batch (Evitar Colapso de Logs)

* **Objetivo:** Quieres auditar las lecturas y escrituras de todos los usuarios humanos, pero tienes un usuario de aplicación (`app_etl` o `monitoring_user`) que ejecuta 50,000 consultas por segundo de reportes automáticos y está llenando el disco.

**Paso 1: Configurar la regla general para la base de datos (`postgresql.conf` o `ALTER DATABASE`)**

```ini
pgaudit.log = 'read, write, ddl'

```

**Paso 2: Sobrescribir y desactivar la auditoría para el usuario automatizado (SQL)**

```sql
-- Desactivar pgaudit únicamente para el usuario de ETL/Sistema
ALTER ROLE app_etl SET pgaudit.log = 'none';
ALTER ROLE monitoring_user SET pgaudit.log = 'none';

```

* **Resultado:** Si un Administrador o un Usuario de negocio consulta la base de datos, queda registrado en `audit-YYYYMMDD.log`. Si el proceso automatizado `app_etl` ejecuta millones de operaciones, `pgaudit` lo omite, protegiendo tus IOPS.





--- 
# Un mini lab


```sql


-- 1. Crear la tabla de pruebas
CREATE TABLE public.clientes_demo (
    cliente_id      BIGSERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    pais            VARCHAR(50) DEFAULT 'México',
    saldo           NUMERIC(10,2) DEFAULT 0.00,
    activo          BOOLEAN DEFAULT TRUE,
    fecha_registro  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Insertar registros de prueba
INSERT INTO public.clientes_demo (nombre, email, pais, saldo, activo, fecha_registro) VALUES
('Ana García',         'ana.garcia@example.com',        'México',    1250.50, true,  '2026-01-15 09:30:00+00'),
('Carlos Mendoza',    'carlos.mendoza@example.com',    'Colombia',    450.00, true,  '2026-02-01 11:15:00+00'),
('Lucía Fernández',   'lucia.f@example.com',           'España',     3200.00, true,  '2026-02-20 14:45:00+00'),
('Mateo Silva',       'mateo.silva@example.com',       'Chile',        0.00, false, '2026-03-05 08:10:00+00'),
('Sofia López',       'sofia.lopez@example.com',       'México',     890.75, true,  '2026-03-12 16:20:00+00'),
('Javier Torres',     'javier.t@example.com',          'Argentina', 15000.00, true,  '2026-04-01 10:00:00+00'),
('Elena Gómez',       'elena.gomez@example.com',       'México',      120.00, false, '2026-04-18 17:30:00+00'),
('Diego Ramírez',     'diego.ramirez@example.com',     'Perú',       2340.10, true,  '2026-05-02 12:05:00+00'),
('Valeria Morales',   'valeria.m@example.com',         'Colombia',   5600.80, true,  '2026-06-10 15:50:00+00'),
('Gabriel Castro',    'gabriel.castro@example.com',    'México',        0.00, true,  '2026-07-01 09:00:00+00');



-- Ver todos los registros
SELECT * FROM public.clientes_demo;

-- Ver clientes con saldo positivo ordenados de mayor a menor
SELECT cliente_id, nombre, pais, saldo 
FROM public.clientes_demo 
WHERE saldo > 0 AND activo = true 
ORDER BY saldo DESC;


ALTER DATABASE db_test SET pgaudit.role = 'auditor_objetos';


GRANT SELECT, INSERT, UPDATE, DELETE,truncate ON TABLE  public.clientes_demo  TO auditor_objetos;


INSERT INTO public.clientes_demo (nombre, email, pais, saldo, activo) 
VALUES ('Diego Luna', 'diego.luna@example.com', 'México', 500.00, true);

SELECT cliente_id, nombre, email, saldo, activo 
FROM public.clientes_demo 
WHERE email = 'diego.luna@example.com';

UPDATE public.clientes_demo 
SET saldo = 750.50, 
    activo = false 
WHERE email = 'diego.luna@example.com';


DELETE FROM public.clientes_demo 
WHERE email = 'diego.luna@example.com';



-----------   al hacer el  create extension pgaudit
"2026-07-27 09:57:21.517360139 MST","postgres","db_test","2242608","[local]","6a678b02.223830","INSERT","3/27","0","00000","OBJECT","6","1","WRITE","INSERT","TABLE","public.clientes_demo","\"INSERT INTO public.clientes_demo (nombre, email, pais, saldo, activo) \nVALUES ('Diego Luna', 'diego.luna@example.com', 'México', 500.00, true)\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:57:26.560043957 MST","postgres","db_test","2242608","[local]","6a678b02.223830","SELECT","3/28","0","00000","OBJECT","7","1","READ","SELECT","TABLE","public.clientes_demo","\"SELECT cliente_id, nombre, email, saldo, activo \nFROM public.clientes_demo \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:57:30.317838359 MST","postgres","db_test","2242608","[local]","6a678b02.223830","UPDATE","3/29","0","00000","OBJECT","8","1","WRITE","UPDATE","TABLE","public.clientes_demo","\"UPDATE public.clientes_demo \nSET saldo = 750.50, \n    activo = false \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:57:30.319536264 MST","postgres","db_test","2242608","[local]","6a678b02.223830","DELETE","3/30","0","00000","OBJECT","9","1","WRITE","DELETE","TABLE","public.clientes_demo","\"DELETE FROM public.clientes_demo \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,




-----------   sin hacer el create extension pgaudit
"2026-07-27 09:58:14.741479819 MST","postgres","db_test","2243499","[local]","6a678e16.223bab","INSERT","0/2","0","00000","OBJECT","1","1","WRITE","INSERT","TABLE","public.clientes_demo","\"INSERT INTO public.clientes_demo (nombre, email, pais, saldo, activo) \nVALUES ('Diego Luna', 'diego.luna@example.com', 'México', 500.00, true)\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:58:18.699763510 MST","postgres","db_test","2243499","[local]","6a678e16.223bab","SELECT","0/3","0","00000","OBJECT","2","1","READ","SELECT","TABLE","public.clientes_demo","\"SELECT cliente_id, nombre, email, saldo, activo \nFROM public.clientes_demo \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:58:21.627828066 MST","postgres","db_test","2243499","[local]","6a678e16.223bab","UPDATE","0/4","0","00000","OBJECT","3","1","WRITE","UPDATE","TABLE","public.clientes_demo","\"UPDATE public.clientes_demo \nSET saldo = 750.50, \n    activo = false \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:58:24.680708170 MST","postgres","db_test","2243499","[local]","6a678e16.223bab","DELETE","0/5","0","00000","OBJECT","4","1","WRITE","DELETE","TABLE","public.clientes_demo","\"DELETE FROM public.clientes_demo \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,

```







 

---

## Pro-Tip herramientas recomendadas  :

1. **pgAudit:** Genera el dato.
2. **pgauditlogtofile:** Separa el dato en un archivo limpio.
3. **pg_permissions:** Audita los permisos preventivamente.
4. **pgaudit_analyze**  Este es el compañero más directo. Es un script diseñado específicamente para leer los logs generados por pgAudit e insertarlos en una base de datos para su análisis posterior.
 




# Links
```
pg_audit vs log_statement = all --> https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Post/pg_audit%20vs%20log_statement%20%3D%20all%20.md

https://www.pgaudit.org/
https://github.com/pgaudit/pgaudit

---------
https://dbadevops.com/database-auditing-using-pgaudit/

pgauditlogtofile -> https://github.com/fmbiete/pgauditlogtofile
https://github.com/pgaudit/pgaudit_analyze
https://hey-dba.com/articles/implementing-pgaudit-in-postgresql-your-databases-all-seeing-eye/
https://supabase.com/docs/guides/database/extensions/pgaudit

https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Post/pg_audit%20vs%20log_statement%20%3D%20all%20.md
https://neon.com/blog/postgres-logging-vs-pgaudit


```
