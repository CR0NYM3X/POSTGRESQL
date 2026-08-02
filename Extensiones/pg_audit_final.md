

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
