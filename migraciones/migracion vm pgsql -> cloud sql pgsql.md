 
## 1. Consideraciones Iniciales y Limitaciones Conocidas

Antes de tocar un solo byte de datos, debemos alinear nuestras expectativas técnicas y operativas.

### Consideraciones Clave

* **IOPS y Rendimiento de Almacenamiento:** En Cloud SQL, el rendimiento (IOPS y ancho de banda) escala según el tamaño del disco y la cantidad de vCPUs. Aunque nuestra base de datos pesa 800 GB, recomiendo aprovisionar un disco SSD de al menos **1.5 TB a 2 TB** de inicio para garantizar suficientes IOPS durante la fase de importación masiva y dejar espacio para el crecimiento (autocrecimiento habilitado).
* **Ventana de Inactividad (Downtime):** ¿El negocio tolera 4-8 horas de inactividad o requerimos un downtime cercano a cero? Esto definirá si usamos un enfoque **Offline** (basado en `pg_dump`/`pg_restore`) o **Online** (usando *Database Migration Service* - DMS con CDC y *pglogical*).
* **Topología de Red:** La instancia de Cloud SQL debe desplegarse con una IP Privada dentro de su VPC. La comunicación desde su entorno origen (On-Premise u otra nube) debe asegurarse a través de Cloud VPN o Cloud Interconnect.

### Limitaciones Conocidas de Cloud SQL

* **Privilegios de Superusuario:** En Cloud SQL, no se otorgan privilegios absolutos de `superuser` (como `postgres`). En su lugar, Google provee el rol `cloudsqlsuperuser`. Esto significa que si tienen extensiones muy específicas o código que requiere permisos absolutos de superusuario en el origen, deberemos refactorizar o usar alternativas.
* **Extensiones Soportadas:** Cloud SQL soporta más de 100 extensiones de PostgreSQL (como `PostGIS`, `pg_stat_statements`, `pgcrypto`), pero no soporta extensiones personalizadas (escritas en C) no listadas en su documentación oficial. Debemos validar las extensiones instaladas (`SELECT * FROM pg_extension;`).

---

## 2. Herramientas Recomendadas (Nativas y Open Source)

Para este tamaño (800 GB), utilizaremos una combinación de herramientas para optimizar tiempos y validar datos:

* **Google Cloud Storage (GCS):** Actuará como nuestro área de *staging* (almacenamiento intermedio) para los archivos de volcado.
* **pg_dump / pg_dumpall:** Herramientas nativas de PostgreSQL. `pg_dumpall` (solo para roles/usuarios) y `pg_dump` con el formato de directorio (`-Fd`) o personalizado (`-Fc`) para soportar exportación en paralelo.
* **pg_restore:** Para la importación paralela en destino.
* **pgBouncer (Open Source):** Altamente recomendado implementarlo frente a Cloud SQL si su aplicación abre cientos de conexiones concurrentes. Cloud SQL tiene un límite de conexiones basado en la RAM.
* **pgBadger (Open Source):** Analizador de logs de PostgreSQL que usaremos en la post-migración para auditar el rendimiento y detectar consultas lentas (slow queries).
* **DBeaver / DataGrip:** Clientes SQL recomendados para la corroboración visual y ejecución de scripts de validación de objetos.

---

## 3. Plan de Trabajo Paso a Paso

Este proyecto se dividirá en cuatro fases críticas.

### Fase 1: Pre-Migración (Preparación, Análisis y Sizing)

En esta fase auditamos el origen y preparamos el terreno en Google Cloud.

1. **Auditoría del Entorno Origen:**
* Inventario de objetos: Contabilizar tablas, vistas, triggers, funciones, secuencias y tamaño de índices (`pg_size_pretty`).
* Auditoría de usuarios y roles.
* Identificación de tablas grandes (Bloat) o Tablas con datos LOBs (Large Objects) que suelen enlentecer la exportación.


2. **Sizing (Dimensionamiento) en Cloud SQL:**
* Crear la instancia de Cloud SQL para PostgreSQL con la versión exacta o superior (ej. PostgreSQL 14 o 15).
* Aprovisionar recursos: Ejemplo recomendado para iniciar: 16 a 32 vCPUs, 64 GB a 128 GB de RAM, 1.5 TB SSD.


3. **Configuración de Red y Seguridad:**
* Habilitar Acceso Privado a Servicios (Private Services Access).
* Configurar reglas de firewall y asegurar la conectividad entre el origen (o máquina bastión) y Cloud SQL.


4. **Tuning para Importación (¡Crítico!):**
* **Recomendación de oro:** En la instancia Cloud SQL destino, **deshabilitar temporalmente los respaldos automatizados y la Alta Disponibilidad (HA)**. Esto evita la replicación sincrónica y el archivado de WALs durante la carga masiva, acelerando la inserción hasta en un 40%.
* Ajustar `maintenance_work_mem` a un valor alto (ej. 2GB o 4GB) en las *database flags* de Cloud SQL para acelerar la creación de índices.
* Deshabilitar o reducir la agresividad del `autovacuum` temporalmente.



### Fase 2: Pruebas y Migraciones Controladas (Prueba de Concepto - PoC)

Nunca vamos a producción sin un simulacro exacto.

1. **Ejecución de un "Dry Run" (Migración de prueba):**
* Migraremos una copia del entorno de producción a Cloud SQL siguiendo exactamente los mismos pasos técnicos.
* Esto nos dará la **tasa de transferencia exacta** y nos permitirá calcular el tiempo exacto de *downtime* para la ventana de paso a producción (Cutover).


2. **Testeo de Aplicaciones:**
* Conectar los entornos de QA/Staging a la instancia Cloud SQL migrada.
* Validar latencias de red (ping/traceroute desde los servidores de aplicación hacia la IP de Cloud SQL).
* Ejecutar pruebas de carga para confirmar que los IOPS de la nueva instancia soportan el tráfico.



### Fase 3: Migración de Producción (El "Cutover")

Asumiendo que requerimos migración de tipo *Offline* o semi-offline con las herramientas de importación/exportación de Google y PostgreSQL.

1. **Establecimiento de Ventana de Mantenimiento:**
* Bajar los servicios de las aplicaciones (modo mantenimiento).
* Mata (kill) todas las conexiones existentes en la base de datos origen para asegurar consistencia estática y evitar escrituras huérfanas.


2. **Exportación de Roles/Usuarios:**
* Usaremos `pg_dumpall -r` para extraer los roles de la base de datos origen y los aplicaremos inmediatamente en Cloud SQL mediante el cliente `psql`. *Nota: Se deben filtrar roles de superusuario propios del sistema de su entorno anterior*.


3. **Exportación Paralela de los Datos (El Dump de 800 GB):**
* Para 800 GB, el formato SQL plano es ineficiente. Usaremos el formato de directorio (`-Fd`) que permite paralelismo.
* *Comando de ejemplo:* `pg_dump -U postgres -h [IP_ORIGEN] -d [NOMBRE_DB] -Fd -j 8 -f /ruta/al/dump_dir`
* El parámetro `-j 8` utiliza 8 núcleos simultáneos para exportar las tablas más grandes en paralelo.


4. **Transferencia de Archivos a Google Cloud:**
* Usaremos `gsutil -m rsync` o `gsutil -m cp` para subir los directorios a un bucket de **Cloud Storage (GCS)** que debe estar *exactamente en la misma región* que la instancia de Cloud SQL.


5. **Importación Paralela a Cloud SQL:**
* A diferencia de la importación desde la consola de GCP que usa un solo hilo de ejecución, recomiendo usar una máquina virtual (Compute Engine) de gran tamaño en la misma VPC como "Bastión de Migración", y desde ahí ejecutar `pg_restore`.
* *Comando de ejemplo:* `pg_restore -U [USUARIO] -h [IP_CLOUDSQL] -d [NOMBRE_DB] -Fd -j 16 /ruta/al/dump_dir`
* Con `-j 16`, estaremos inyectando datos y reconstruyendo múltiples índices simultáneamente, cortando los tiempos de carga en una fracción respecto a un método secuencial.



### Fase 4: Post-Migración, Corroboración y Estabilización (Go-Live)

La base de datos está en Cloud SQL, pero el trabajo de un experto aún no termina. **¡Felicidades por la migración!** Mover una base de datos de 800GB a Cloud SQL es un hito importante. Como especialista en GCP, te confirmo que el trabajo no termina cuando los datos aterrizan; las primeras 48 horas son críticas para estabilizar el rendimiento.

Cuando haces una migración masiva, PostgreSQL recibe los datos de golpe, lo que a menudo deja la base de datos desordenada y al planeador de consultas "ciego". Aquí tienes el plan de mantenimiento exacto que debes ejecutar, dividido entre tareas nativas de PostgreSQL y configuraciones específicas de Cloud SQL:

1. **Configuración Core en GCP y Backups Inmediatos:**
* **Reconfiguración de Alta Disponibilidad y Respaldo:** Inmediatamente tras finalizar la carga, **rehabilitamos los respaldos automatizados** y activamos la **Alta Disponibilidad (Regional HA)**. Esto reiniciará la instancia temporalmente pero la dejará lista para producción.
* **Toma un Backup On-Demand:** Acabas de lograr una migración exitosa. Antes de tocar cualquier configuración adicional, ve a la pestaña "Copias de seguridad" (Backups) y crea una manual. Las automáticas son excelentes, pero tener el punto exacto "post-migración limpia" te salvará de dolores de cabeza.
* **Define tu Ventana de Mantenimiento:** GCP parcheará tu instancia (actualizaciones de SO o de motor menor) de forma rutinaria. Esto requiere un reinicio corto. Configura la ventana de mantenimiento en el horario de menor tráfico de tu negocio para que el reinicio pase desapercibido.


2. **Corroboración y Validación de Objetos:**
* Ejecutar scripts comparativos entre Origen y Destino:
* Conteo masivo de filas: `SELECT relname, n_live_tup FROM pg_stat_user_tables;`
* Validación de tamaños: `SELECT pg_size_pretty(pg_database_size('mi_base'));`
* Comparación de secuencias (`last_value`) para asegurar que las nuevas inserciones no generen errores de llave primaria duplicada.




3. **Tareas Inmediatas a Nivel PostgreSQL (Optimización):**
Si acabas de terminar la migración y los datos ya están ahí, haz esto antes de liberar la base de datos a producción:
* **Ejecuta VACUUM ANALYZE (Vital):** Esto es absolutamente crítico. Tras una migración, Cloud SQL no conoce la distribución de los datos. Al insertar 800GB de datos, el motor no tiene estadísticas actualizadas sobre la distribución de esos datos. Si tus aplicaciones empiezan a consultar ahora, PostgreSQL tomará decisiones de ejecución pésimas (como hacer sequential scans en lugar de usar índices, lo que hará que la aplicación vaya terriblemente lenta). Conéctate a tu base de datos y ejecuta: `VACUUM (ANALYZE);` para que el optimizador de consultas de PostgreSQL (Query Planner) genere planes de ejecución eficientes.
* **Reconstruye índices fragmentados:** Dependiendo de cómo migraste (si fue con herramientas de replicación lógica como Datastream o si hubo muchos UPDATES durante la carga), tus índices pueden estar "hinchados" (bloat). Si notas lentitud tras el ANALYZE, planea ejecutar `REINDEX INDEX CONCURRENTLY nombre_indice;` en tus tablas más grandes fuera de horas pico.


4. **Tuning de Flags para una BD de 800GB:**
Las bases de datos grandes requieren un trato especial con el Autovacuum. Por defecto, PostgreSQL dispara un vacuum cuando el 20% de una tabla cambia. En una tabla de 100GB, eso significa esperar a que cambien 20GB de datos, lo cual generará un pico masivo de I/O cuando el vacuum finalmente ocurra. Revisa y ajusta estos Database Flags en tu instancia de Cloud SQL:

| Flag | Acción Recomendada | Propósito |
| --- | --- | --- |
| **autovacuum_vacuum_scale_factor** | Reducir a 0.02 o 0.05 | Dispara limpiezas más frecuentes pero más ligeras. |
| **autovacuum_analyze_scale_factor** | Reducir a 0.01 o 0.02 | Mantiene las estadísticas frescas en tablas con mucha mutación. |
| **maintenance_work_mem** | Aumentar al máximo permitido | Acelera los procesos de VACUUM y creación de índices. |
| **work_mem** | Ajustar según tu memoria RAM | Evita que las consultas complejas escriban archivos temporales en disco. |

5. **Cambio de Cadenas de Conexión, Pruebas Iniciales y PgBouncer:**
* Actualizar las variables de entorno de la aplicación para apuntar a la IP de Cloud SQL (o usar el Cloud SQL Auth Proxy).
* Realizar *Smoke Tests* básicos desde la app (Logins, consultas de reportes complejos).
* **Nota de experto:** Si tu instancia tiene más de 100 conexiones concurrentes, considera usar **PgBouncer** (connection pooling). A diferencia de MySQL, PostgreSQL asigna un proceso de sistema operativo por cada conexión, lo que consume mucha RAM. Cloud SQL soporta PgBouncer nativo o puedes desplegarlo en un contenedor.


6. **Monitoreo y Go-Live:**
* Levantar servicios al usuario final.
* **Activa Cloud SQL Query Insights:** Ve a la configuración de la instancia y enciende Query Insights. Es gratuito y es la mejor herramienta de GCP para detectar qué consultas están consumiendo tu CPU o leyendo demasiado de disco. Habilitar `pg_stat_statements` (previamente configurado en flags) y revisar **Cloud SQL Insights / Query Insights** para cazar las consultas más lentas durante las primeras 48 horas.



---

## 4. Tipos de Migración Alternativos: "Zero Downtime" (DMS)

Si durante nuestro *discovery* determinamos que el negocio no puede permitirse el tiempo que tarda el volcado paralelo y la restauración de 800 GB, mi recomendación experta es pivotar hacia una **Migración Online o Continua**.

En este escenario, configuramos **Google Cloud Database Migration Service (DMS)**:

1. Habilitamos la decodificación lógica (`wal_level = logical`) y la extensión `pglogical` en el servidor origen.
2. DMS toma un snapshot inicial y lo migra en segundo plano mientras su producción sigue operando.
3. DMS mantiene los sistemas sincronizados aplicando continuamente los cambios (CDC - Change Data Capture).
4. El *Cutover* (Downtime) se reduce únicamente a los minutos que tarda la aplicación en desconectarse del origen y reconectarse a Cloud SQL.

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
Importa y exporta mediante pg_dump, pg_dumpall y pg_restore : https://docs.cloud.google.com/sql/docs/postgres/import-export/import-export-dmp?hl=es-419
Recomendaciones para la importación y exportación de datos : https://docs.cloud.google.com/sql/docs/postgres/import-export?hl=es-419
Importa y exporta archivos en paralelo: https://docs.cloud.google.com/sql/docs/postgres/import-export/import-export-parallel?hl=es-419

Configuraciones DMS -> https://docs.cloud.google.com/database-migration/docs/postgres/configure-source-database?hl=es-419
Limitaciones de pglogial -> https://github.com/2ndQuadrant/pglogical#limitations-and-restrictions
Limitaciones conocidas - DMS  https://docs.cloud.google.com/database-migration/docs/postgres/known-limitations?hl=es-419

```
