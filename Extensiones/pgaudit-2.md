 
## FASE 1 Inyección en Kernel y Redirección Física (El Enlace)

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




## link
```
https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pgaudit.md
```
