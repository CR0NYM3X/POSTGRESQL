


# **PLAN MAESTRO DE MIGRACIÓN: PostgreSQL (GCP VM) a Cloud SQL Enterprise (800 GB)**

## 1. Consideraciones Iniciales, Seguridad y Limitaciones Conocidas

Antes de intervenir los datos, debemos alinear las expectativas operativas, las barreras físicas del hardware y las normativas de seguridad de la infraestructura en Google Cloud.

### Consideraciones Clave de Arquitectura y Rendimiento

* **IOPS y Rendimiento de Almacenamiento:** En Cloud SQL, el rendimiento (IOPS y ancho de banda) escala proporcionalmente según el tamaño del disco y la cantidad de vCPUs. Aunque nuestra base de datos pesa 800 GB, es imperativo aprovisionar un disco SSD de al menos **1.5 TB a 2 TB** de inicio. Esto garantizará los IOPS máximos necesarios durante la fase de importación masiva y dejará espacio operativo para el crecimiento (Autocrecimiento habilitado).
* **Ventana de Inactividad (Downtime):** El negocio debe definir su tolerancia operativa. Si se toleran 4-8 horas de inactividad, procederemos con un enfoque **Offline/Semi-Offline** (basado en `pg_dump`/`pg_restore` en paralelo). Si se requiere un downtime cercano a cero, pivotaremos a una estrategia **Online** (Database Migration Service - DMS con CDC).
* **Topología de Red y Seguridad (Zero Trust):** La instancia de Cloud SQL debe desplegarse con una IP Privada dentro de su VPC. La comunicación desde el entorno origen (VM en GCP) debe realizarse a través de **Private Services Access (Acceso Privado a Servicios)**. Se aplicarán reglas de firewall estrictas (VPC Firewall Rules) para que solo la Máquina Bastión y las subredes de las aplicaciones puedan alcanzar el puerto 5432.
* **Encriptación (CMEK):** Para cumplir con normativas corporativas, se recomienda gestionar la encriptación en reposo mediante Customer-Managed Encryption Keys (CMEK) a través de Google Cloud KMS, en lugar de las llaves por defecto de Google.

### Limitaciones Conocidas y Restricciones de Cloud SQL

* **Privilegios de Superusuario:** Cloud SQL es un servicio gestionado; por seguridad, no otorga privilegios absolutos de `superuser` (como el rol nativo `postgres`). En su lugar, Google provee el rol `cloudsqlsuperuser`. Cualquier código heredado, función o extensión que dependa de permisos absolutos de superusuario en el origen deberá ser refactorizado.
* **Extensiones Soportadas:** Cloud SQL soporta más de 100 extensiones de PostgreSQL (como `PostGIS`, `pg_stat_statements`, `pgcrypto`), pero bloquea extensiones personalizadas (escritas en C) no listadas en su documentación oficial. Es obligatorio ejecutar `SELECT * FROM pg_extension;` en el origen y cruzar la lista contra el catálogo de GCP antes de iniciar.

---

## 2. Toolstack y Ecosistema de Migración Recomendado

Para dominar una base de datos de 800 GB, el uso exclusivo de la consola gráfica es insuficiente. Utilizaremos herramientas nativas de alto rendimiento:

* **Terraform / IaC (Infraestructura como Código):** Para desplegar la instancia de Cloud SQL, la red y el bucket de forma predecible, auditable y sin errores humanos (*ClickOps*).
* **Google Cloud Storage (GCS):** Actuará como nuestro área de *staging* inmutable para los archivos de volcado. Se configurará en la misma región que Cloud SQL para evitar costos de egreso de red y latencia.
* **pg_dump / pg_dumpall:** `pg_dumpall` para exportar exclusivamente roles/usuarios. `pg_dump` con el formato de directorio (`-Fd`) para soportar exportación fraccionada y paralelismo masivo.
* **pg_restore:** Motor de inyección de datos para la importación paralela en el destino.
* **Máquina Bastión de Alta Capacidad:** Instancia temporal de Compute Engine (ej. `n2-standard-16`) optimizada a nivel de Kernel (Sysctl) para ejecutar `pg_restore` sin estrangulamiento de red.
* **pgBouncer (Open Source):** Altamente recomendado para implementarse frente a Cloud SQL si la aplicación abre cientos de conexiones concurrentes. Cloud SQL posee límites de conexiones basados en la RAM disponible.
* **pgBadger & Cloud SQL Query Insights:** Analizadores de rendimiento que usaremos en la post-migración para auditar tiempos de respuesta y cazar consultas lentas.
* **DBeaver / DataGrip:** Clientes SQL para la corroboración forense y ejecución de scripts de validación de objetos.

---

## 3. Plan de Ejecución Táctica (Las 5 Fases Críticas)

### Fase 1: Pre-Migración (Preparación, Sizing y Gobernanza)

En esta fase auditamos el origen y preparamos el terreno en Google Cloud de forma hermética.

1. **Auditoría Forense del Entorno Origen:**
* **Inventario:** Contabilizar tablas, vistas, triggers, funciones, secuencias y tamaño de índices (`pg_size_pretty`).
* **Limpieza previa:** Identificar tablas con fragmentación severa (*Bloat*) o datos LOBs (Large Objects) que enlentecen la exportación.
* **Auditoría de usuarios y roles.**


2. **Sizing y Despliegue en Cloud SQL (IaC):**
* Desplegar la instancia con la versión exacta o superior (ej. PostgreSQL 14 o 15).
* **Recursos base recomendados:** 16 a 32 vCPUs, 64 GB a 128 GB de RAM, 1.5 TB SSD (io2 / hyperdisk recomendado para la carga masiva).


3. **Tuning del Bastión de Migración (Sistema Operativo):**
* Configurar una VM de Compute Engine en la misma zona de disponibilidad.
* Ajustar los buffers TCP del kernel Linux (`sysctl -w net.ipv4.tcp_window_scaling=1`) para garantizar máxima transferencia hacia Cloud SQL.


4. **Tuning del Motor para Importación (¡Crítico!):**
* **Recomendación de oro:** En la instancia destino, **deshabilitar temporalmente los respaldos automatizados, el archivado WAL y la Alta Disponibilidad (HA)**. Esto evita la replicación sincrónica masiva, acelerando la inserción hasta en un 40%.
* Ajustar flag `maintenance_work_mem` a un valor extremo (ej. 4GB u 8GB) para acelerar la creación de índices concurrentes.
* Reducir la agresividad del `autovacuum` temporalmente mediante Database Flags.

5 **Configuración de Red y Seguridad:**
* Habilitar Acceso Privado a Servicios (Private Services Access).
* Configurar reglas de firewall y asegurar la conectividad entre el origen (o máquina bastión) y Cloud SQL.



### Fase 2: Pruebas y Simulacro (Dry-Run / PoC)

Ningún proyecto pasa a producción sin un simulacro táctico verificado.

1. **Ejecución del "Dry Run":**
* Migraremos una copia íntegra del entorno a Cloud SQL siguiendo los pasos técnicos.
* Este proceso entregará la **tasa de transferencia exacta**, permitiendo firmar el SLA del tiempo de *downtime* real con el negocio.


2. **Testeo y Pruebas de Carga:**
* Conectar entornos de QA/Staging a la instancia migrada.
* Validar latencias de red (ping/traceroute/telnet desde los servidores de aplicación).
* Ejecutar un benchmark simulado (`pgbench`) para confirmar que los IOPS del disco SSD soportan los picos transaccionales.



### Fase 3: Migración de Producción (El "Cutover")

Procedimiento para la ventana de inactividad aprobada.

1. **Compuerta de Cierre (Go/No-Go):**
* Bajar los servicios de las aplicaciones (modo mantenimiento).
* Drenar (kill) todas las conexiones existentes en la BD origen para asegurar consistencia estática y evitar escrituras huérfanas o transacciones fantasmas.


2. **Transferencia de Roles/Usuarios:**
* Extraer perfiles mediante `pg_dumpall -r`, excluyendo roles del sistema legacy, e inyectar en Cloud SQL vía `psql`.


3. **Exportación Paralela de los Datos (800 GB):**
* Utilizar el formato de directorio (`-Fd`).
* *Comando:* `pg_dump -U postgres -h [IP_ORIGEN] -d [NOMBRE_DB] -Fd -j 8 -f /ruta/al/dump_dir` (8 núcleos simultáneos atacando las tablas más pesadas).


4. **Tránsito hacia Cloud Storage:**
* Sincronizar directorios usando `gsutil -m rsync` hacia el bucket GCS regional.


5. **Importación Paralela Masiva desde el Bastión:**
* Descargar dump al Bastión de alta velocidad.
* *Comando:* `pg_restore -U [USUARIO] -h [IP_CLOUDSQL] -d [NOMBRE_DB] -Fd -j 16 /ruta/al/dump_dir` (Inyección e indexación con 16 hilos simultáneos).



### Fase 4: Post-Migración, Estabilización y Go-Live

Mover 800GB no es el final; las siguientes 4 horas son de estabilización crítica.

1. **Reversión de Tuning y Blindaje de HA:**
* **Rehabilitar de inmediato:** Respaldos automatizados y Alta Disponibilidad (Regional HA).
* **Tomar Backup Base On-Demand:** Asegurar un punto de restauración puro ("Post-Migración Limpia").
* Definir ventana de mantenimiento de GCP en horario de bajo tráfico.


2. **Validación Criptográfica y de Objetos:**
* Conteo masivo (`pg_stat_user_tables`), tamaño de catálogo (`pg_database_size`) y verificación del estado de todas las secuencias (`last_value`) para prevenir errores de inserción de llaves primarias.


3. **Estabilización del Optimizador (Vital):**
* Cloud SQL ignora la distribución de estos 800GB nuevos. Ejecutar `VACUUM (ANALYZE);` en toda la base de datos es obligatorio para que el *Query Planner* reconstruya sus estadísticas y no ejecute escaneos secuenciales destructivos.
* Agendar reconstrucción de índices fragmentados (`REINDEX INDEX CONCURRENTLY`) fuera de horas pico.


 **4. Tuning de Flags y Dimensionamiento de Memoria (VLDB):**
> Cloud SQL auto-configura ciertos parámetros basándose en la RAM aprovisionada, pero para una base de datos de 800 GB bajo estrés real, no confiamos en los valores por defecto. Validaremos y ajustaremos los siguientes *Database Flags* críticos:
> | Flag de Cloud SQL | Acción Recomendada / Validación | Propósito Estratégico |
> | --- | --- | --- |
> | **shared_buffers** | Validar que esté al ~32% de la RAM total. | Es la memoria principal de PostgreSQL. Si Cloud SQL no la asigna correctamente, la ajustaremos para evitar lecturas excesivas a disco SSD. |
> | **work_mem** | Ajustar mediante fórmula: `(RAM Total - shared_buffers) / max_connections` | Controla la RAM para operaciones `ORDER BY` y `JOIN` complejos. Un valor muy bajo fuerza la escritura de archivos temporales en disco (lentitud extrema); un valor muy alto provoca *Out of Memory (OOM)*. |
> | **effective_cache_size** | Configurar al ~70% de la RAM total. | No consume memoria real, pero le dice al *Query Planner* cuánta RAM tiene el sistema operativo para caché, forzándolo a usar índices en lugar de escaneos secuenciales. |
> | **max_connections** | Limitar estrictamente (ej. 200 - 500) | A mayor cantidad de conexiones permitidas, más RAM base se desperdicia. Si la app exige 2,000 conexiones, forzaremos el uso de **PgBouncer** (Connection Pooler) frente a Cloud SQL. |
> | **autovacuum_vacuum_scale_factor** | Reducir a 0.02 o 0.05 | Dispara limpiezas más frecuentes pero ligeras, evitando tormentas de I/O en tablas masivas. |
> | **autovacuum_analyze_scale_factor** | Reducir a 0.01 o 0.02 | Mantiene las estadísticas frescas en tablas de alta mutación. |
| **pg_stat_statements.track** | 'all' (Temporal) | Captura telemetría de rendimiento para Cloud SQL Insights. |

 


**5. Observabilidad, Logging y Monitoreo (Cloud-Native):**
  El ecosistema de base de datos no es una caja negra. Antes de dar luz verde a las aplicaciones, implementaremos la siguiente arquitectura de observabilidad utilizando la suite de operaciones de GCP:
  * **Cloud Monitoring (Métricas Centrales):** Crearemos un Dashboard personalizado (`Metrics Explorer`) anclado a 4 señales doradas: Uso de CPU, Latencia de Disco (IOPS/Throughput en volúmenes SSD), RAM disponible y Número de Transacciones Activas/En Espera (Locks).
  * **Cloud Logging (Centralización de Bitácoras):** Configuraremos los flags `log_min_duration_statement` (ej. 1000ms) y `log_lock_waits` (on) para que Cloud Logging ingeste automáticamente todas las consultas lentas y bloqueos transaccionales. Toda esta telemetría se retendrá por 30 días en caliente, y se enviará mediante un *Log Sink* hacia un bucket de Cloud Storage (Cold Storage) para auditoría anual.
  * **pgAudit (Auditoría Normativa - Opcional/Recomendado):** Si el cliente maneja datos PII o financieros, activaremos la extensión `pgAudit` (soportada por Cloud SQL) para registrar de manera inmutable quién ejecutó comandos `DDL` (creación/destrucción de tablas) o alteraciones críticas de roles.
  * **Cloud SQL Query Insights:** Habilitaremos el flag `pg_stat_statements.track` en valor 'all'. Esta herramienta nos dará un mapa visual del consumo de CPU a nivel de *query individual*, permitiéndonos detectar de inmediato si una consulta de la aplicación se está comportando de forma anómala tras la migración.
  
  
**6. Activación de Servicios (Go-Live) y Enrutamiento:**
  * Actualizar cadenas de conexión o registros DNS internos para que las aplicaciones apunten al *Cloud SQL Auth Proxy* o IP Privada de la nueva instancia.
  * Monitoreo intensivo de "Día Cero": El DBA Squad vigilará activamente los dashboards de *Cloud Monitoring* y *Query Insights* durante las primeras 48 horas operativas para ajustar dinámicamente el planificador de consultas.
  * Monitorear a través de **Cloud SQL Query Insights** durante las primeras 48 horas para aislar consultas no optimizadas.





### Fase 5: Plan de Contingencia (Rollback)

Si durante la Fase 3 se detecta una corrupción irreversible o los tiempos superan el SLA del negocio, se ejecutará el plan de aborto:

1. Las aplicaciones nunca escribieron en el nuevo Cloud SQL, por lo que el Origen mantiene el 100% de la verdad de los datos.
2. Se revoca el modo mantenimiento en las aplicaciones.
3. Se reconectan los servicios al servidor origen (GCP VM) original.
4. Se destruye y recrea la instancia Cloud SQL para un intento futuro tras analizar la autopsia del fallo.

---

## 4. Estrategia Alternativa: Migración "Zero-Downtime" (DMS)

Si la alta gerencia determina que una ventana de 3-5 horas es inaceptable, el escuadrón pivotará hacia una **Migración Continua** usando **Google Cloud Database Migration Service (DMS)**:

1. **Preparación del Origen:** Habilitar decodificación lógica (`wal_level = logical`) y extensión `pglogical` en el servidor origen. *Requisito estricto: Todas las tablas transaccionales deben tener Primary Keys.*
2. **Sincronización de Snapshot:** DMS extraerá un snapshot inicial y lo cargará en Cloud SQL mientras su producción sigue operando normalmente.
3. **Change Data Capture (CDC):** DMS captura cada transacción nueva (INSERT/UPDATE/DELETE) y la replica en Cloud SQL en tiempo real.
4. **Cutover Quirúrgico:** El downtime se reduce a los **2-5 minutos** que tardan las aplicaciones en reiniciar sus servicios, desconectarse de la VM origen y apuntar sus variables de red hacia Cloud SQL. (Nota: Las secuencias deben sincronizarse manualmente en el instante del cutover).

---
## Nota de experto: 
 - Si tu instancia tiene más de 100 conexiones concurrentes, considera usar PgBouncer (connection pooling). A diferencia de MySQL, PostgreSQL asigna un proceso de sistema operativo por cada conexión, lo que consume mucha RAM. Cloud SQL soporta PgBouncer nativo o puedes desplegarlo en un contenedor.

 - Habilitar pg_stat_statements (previamente configurado en flags) y revisar Cloud SQL Insights / Query Insights para cazar las consultas más lentas durante las primeras 48 horas.

---
 
## Recomendaciones Finales como Arquitecto

* **Evite Importar Extensiones Automáticamente:** Los comandos de exportación (`pg_dump`) suelen incluir la sentencia `CREATE EXTENSION`. Si la extensión no está soportada o el usuario no tiene permisos suficientes, la restauración fallará. Se recomienda excluir extensiones del dump (`--exclude-table=spatial_ref_sys` en caso de PostGIS, por ejemplo) y crearlas manualmente en Cloud SQL antes de la importación de datos.
* **Gestión de Logs:** Durante la importación, el volumen de logs transaccionales (WALs) generados será masivo. Asegúrense de no tener activas herramientas de auditoría per-query en Cloud SQL durante la carga, ya que saturará el disco.

Este documento establece un marco técnico sólido. Nuestro siguiente paso ideal sería agendar una reunión técnica de 2 horas para revisar la matriz de dependencias, permisos de red del entorno de origen y definir la fecha para nuestra Prueba de Concepto (PoC).


### Tiempos Reales de Restauración (.sql) basados en Benchmarks de la Industria

| Tamaño de BD | 4 vCPU / 16GB RAM (Ancho de banda bajo) | 8 vCPU / 32GB RAM (Ancho de banda medio) | 16 vCPU / 64GB RAM (Ancho de banda alto) | 32 vCPU / 128GB RAM (Ancho de banda máximo) | 64 vCPU / 256GB RAM (Ancho de banda máximo) |
| --- | --- | --- | --- | --- | --- |
| **10 GB** | ~ 15 a 18 min | ~ 12 min | ~ 10 min | ~ 8 a 9 min | ~ 8 min |
| **100 GB** | ~ 3.5 horas | ~ 2.2 horas | ~ 1.6 horas | ~ 1.3 horas | ~ 1.2 horas |
| **500 GB** | ~ 18 horas | ~ 12.5 horas | ~ 9 horas | ~ 7.5 horas | ~ 7 horas |
| **1 TB** | ~ 42 horas | ~ 28 horas | ~ 19 horas | ~ 15.5 horas | ~ 14.5 horas |
| **2 TB** | *Falla (OOM)* | ~ 58 horas | ~ 40 horas | ~ 32 horas | ~ 29 horas |
| **5 TB** | *Falla* | *Falla* | ~ 110 horas | ~ 85 horas | ~ 78 horas |
| **7.5 TB** | *Falla* | *Falla* | *Falla (I/O Límite)* | ~ 130 horas | ~ 118 horas |
| **10 TB** | *Falla* | *Falla* | *Falla* | ~ 175 horas (7 días) | ~ 160 horas |



### Tiempos Reales de Restauración (-Fc / -Fd usando pg_restore -j)

| Tamaño de BD | 4 vCPU / 16GB RAM (-j 4) | 8 vCPU / 32GB RAM (-j 8) | 16 vCPU / 64GB RAM (-j 16) | 32 vCPU / 128GB RAM (-j 32) | 64 vCPU / 256GB RAM (-j 64) |
| --- | --- | --- | --- | --- | --- |
| **10 GB** | ~ 4 min | ~ 3 min | ~ 2 min | ~ 1 min | ~ 1 min |
| **100 GB** | ~ 45 min | ~ 25 min | ~ 15 min | ~ 10 min | ~ 8 min |
| **500 GB** | ~ 4 horas | ~ 2.2 horas | ~ 1.3 horas | ~ 55 min | ~ 45 min |
| **1 TB** | ~ 8.5 horas | ~ 4.5 horas | ~ 2.5 horas | ~ 1.8 horas | ~ 1.5 horas |
| **2 TB** | ~ 17 horas | ~ 9 horas | ~ 5 horas | ~ 3.5 horas | ~ 2.8 horas |
| **5 TB** | *Riesgo de OOM* | ~ 24 horas | ~ 13 horas | ~ 9 horas | ~ 7.5 horas |
| **7.5 TB** | *Falla* | ~ 38 horas | ~ 20 horas | ~ 14 horas | ~ 11.5 horas |
| **10 TB** | *Falla* | ~ 52 horas | ~ 28 horas | ~ 19 horas | ~ 15 horas |


# Ref
```
Solución de problemas : https://docs.cloud.google.com/sql/docs/postgres/troubleshooting?hl=es-419
Importa y exporta mediante pg_dump, pg_dumpall y pg_restore : https://docs.cloud.google.com/sql/docs/postgres/import-export/import-export-dmp?hl=es-419
Recomendaciones para la importación y exportación de datos : https://docs.cloud.google.com/sql/docs/postgres/import-export?hl=es-419
Importa y exporta archivos en paralelo: https://docs.cloud.google.com/sql/docs/postgres/import-export/import-export-parallel?hl=es-419

Configuraciones DMS -> https://docs.cloud.google.com/database-migration/docs/postgres/configure-source-database?hl=es-419
Limitaciones de pglogial -> https://github.com/2ndQuadrant/pglogical#limitations-and-restrictions
Limitaciones conocidas - DMS  https://docs.cloud.google.com/database-migration/docs/postgres/known-limitations?hl=es-419

```
