

# 🛡️ PostgreSQL Audit (pgAudit) Guide

## 1. ¿Qué es pgAudit?

**pgAudit** La extensión nació originalmente en 2ndQuadrant (una de las empresas más influyentes en la historia de PostgreSQL, ahora parte de EDB). (PostgreSQL Audit Extension) es una extensión de código abierto diseñada para proporcionar registros de auditoría detallados y granulares en PostgreSQL.

A diferencia del registro (logging) estándar de PostgreSQL, que está orientado a la depuración y resolución de errores, **pgAudit está diseñado para cumplir con requisitos de seguridad y cumplimiento (compliance)**.

## 2. ¿Para qué sirve?

Sirve para registrar **quién hizo qué, cuándo y dónde** en la base de datos. Permite capturar:

* **Lecturas (READ):** SELECT y COPY de tablas.
* **Escrituras (WRITE):** INSERT, UPDATE, DELETE y TRUNCATE.
* **Cambios de Estructura (DDL):** CREATE, ALTER y DROP de objetos.
* **Gestión de Privilegios (ROLE):** GRANT, REVOKE y comandos de roles.
* **Funciones:** Ejecución de funciones y procedimientos almacenados.

---

## 3. Ventajas de usar pgAudit

| Ventaja | Descripción |
| --- | --- |
| **Granularidad** | Puedes auditar solo tablas específicas o solo ciertos tipos de comandos. |
| **Transparencia** | Los registros incluyen el texto completo de la consulta SQL ejecutada. |
| **Integridad** | Los logs se generan a nivel de sesión, lo que dificulta que un usuario malintencionado oculte sus huellas. |
| **Bajo impacto** | Está altamente optimizado para minimizar el impacto en el rendimiento. |

---

## 4. Estándares y Políticas que ayuda a cumplir

El uso de pgAudit es fundamental para que las empresas obtengan certificaciones internacionales de seguridad:

* **PCI-DSS:** Requisito 10 (Rastrear y monitorear todo el acceso a los recursos de red y datos de tarjetas).
* **SOC2:** Para auditorías de disponibilidad, integridad de procesamiento y confidencialidad.
* **HIPAA:** Seguridad de datos de salud, requiriendo registros de auditoría sobre quién accede a la información sensible de pacientes.
* **GDPR:** Para demostrar quién ha accedido o modificado datos personales de ciudadanos de la UE.
* **SOX:** Requisitos de control interno para la integridad de datos financieros.

---

## 5. Ejemplo de Caso de Uso Real: "El empleado curioso"

### Escenario

En un hospital, una base de datos almacena registros médicos de celebridades. Existe una política que prohíbe a los empleados consultar registros que no estén asignados a sus pacientes actuales.

### Configuración con pgAudit

Configuramos pgAudit para que registre todos los accesos a la tabla `historial_medico` bajo la clase `READ`.

```sql
-- Configuración en postgresql.conf o por sesión
SET pgaudit.log = 'read';
SET pgaudit.log_catalog = off;
SET pgaudit.log_parameter = on;

```

### El Incidente

Un enfermero intenta curiosear el historial de una celebridad ejecutando:
`SELECT diagnostico FROM historial_medico WHERE nombre = 'Lionel Messi';`

### Resultado en el Log

pgAudit generará una línea de log estructurada:

```text
AUDIT: SESSION,1,1,READ,SELECT,TABLE,public.historial_medico,
"SELECT diagnostico FROM historial_medico WHERE nombre = 'Lionel Messi';",<none>

```

**Beneficio:** El oficial de seguridad puede revisar estos logs semanalmente y detectar que un usuario consultó datos de una persona sin autorización, teniendo la **evidencia exacta** de la consulta para tomar medidas disciplinarias.
 
## Pro-Tip herramientas recomendadas  :

1. **pgAudit:** Genera el dato.
2. **pgauditlogtofile:** Separa el dato en un archivo limpio.
3. **pg_permissions:** Audita los permisos preventivamente.
4. **pgaudit_analyze**  Este es el compañero más directo. Es un script diseñado específicamente para leer los logs generados por pgAudit e insertarlos en una base de datos para su análisis posterior.
 

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

# Links
```
pgaudit -> https://github.com/pgaudit/pgaudit
pgauditlogtofile -> https://github.com/df7cb/pgauditlogtofile
https://github.com/pgaudit/pgaudit_analyze

https://supabase.com/docs/guides/database/extensions/pgaudit


https://neon.com/blog/postgres-logging-vs-pgaudit
```

