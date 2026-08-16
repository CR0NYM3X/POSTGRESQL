# PG_CRON
 Es una extensión para PostgreSQL que permite programar y ejecutar tareas periódicas directamente desde la base de datos, similar a cómo funciona cron en sistemas Unix12.

> **Desventaja:** Solo permite la ejecución de código sql dentro de la base de datos, por lo que no puedes ejecutar script a nivel servidor, como  bash 

---
Aquí tienes el esquema completo adaptado exactamente a tu formato visual:

```text
 ┌───────────── min (0 - 59)
 │   ┌────────────── hour (0 - 23)
 │   │ ┌─────────────── day of month (1 - 31) or last day of the month ($)
 │   │ │ ┌──────────────── month (1 - 12)
 │   │ │ │ ┌───────────────── day of week (0 - 6) ( 0 It is Sunday. )
 │   │ │ │ │                  Saturday, or use names; 7 is also Sunday)
 │   │ │ │ │
 │   │ │ │ │
 00 06 * * *
 │  │  │ │ │
 │  │  │ │ └── Todos los días de la semana (Lunes a Domingo)
 │  │  │ └──── Todos los meses del año (Enero a Diciembre)
 │  │  └────── Todos los días del mes (del 1 al 31)
 │  └───────── A las 06 horas (6:00 AM)
 └──────────── En el minuto 00

 0 = Domingo
 1 = Lunes
 2 = Martes
 3 = Miércoles
 4 = Jueves
 5 = Viernes
 6 = Sábado
 7 = Domingo (equivalente a 0)

```
---

### Ejemplos de uso 

> [!IMPORTANT]
> Es importante poner atencion a la hora estandar que configuras en el cron, ya que la query se va ejecutar a la hora estandar y no ha la hora del servidor



```sql

--- Ver los parametros que se pueden configurar con PG_CRON
select * from pg_available_extensions where name ilike '%cron%';

-- /************  add to postgresql.conf *************\
shared_preload_libraries = 'pg_cron,pg_stat_statements'
cron.database_name = 'postgres'
cron.host = '/tmp' # Connect via a unix domain socket:
cron.timezone = 'MST' -# Este es un estandar asi que debes de saber que hora es en el estandar 


----- Crear la Extension
CREATE EXTENSION pg_cron;
-- drop EXTENSION pg_cron;
GRANT USAGE ON SCHEMA cron TO postgres;

---- Ver si se creao la extension 
select * from pg_extension;

--- Ver los parametros que se pueden configurar con PG_CRON
SELECT name, setting, short_desc FROM pg_settings WHERE name LIKE 'cron%' ORDER BY name;


--- Ver la hora en linux  
date -u
/usr/bin/timedatectl

--- Obtener una zona horaria y su abreviacion
select * from pg_timezone_names where abbrev = 'MST';
select * from pg_timezone_names where abbrev ilike '%UTC%';


---- Ver la hora en posgresql
SELECT current_timestamp AT TIME ZONE 'Mexico/General';
SELECT current_timestamp AT TIME ZONE 'GMT';
SELECT current_timestamp AT TIME ZONE 'UTC';
SELECT current_timestamp AT TIME ZONE 'MST'; --- este me sirve a mi

--------- Convertir hora MST a GMT
  SELECT 
 ( now()::date || ' ' || 
 '18:00:00'  /* <---- AQUI COLOCAR LA HORA QUE QUIERES EJECUTAR EL CRON */
 )::timestamp AT TIME ZONE 'MST' AT TIME ZONE 'GMT' as "hora convertida a GMT" 
,current_timestamp AT TIME ZONE 'MST' as "hora actual MST"
,current_timestamp AT TIME ZONE 'GMT' as "hora Estandar GMT"
, (current_timestamp AT TIME ZONE 'GMT'  ) - (current_timestamp AT TIME ZONE 'MST'  )  as "Diferencia de horas "
 ;




--- la hora UTC y GMT es la misma 
UTC (Tiempo Universal Coordinado): El estándar de tiempo actual.
GMT (Greenwich Mean Time): Hora del Meridiano de Greenwich.
EST (Eastern Standard Time): Hora Estándar del Este (UTC-5).
CST (Central Standard Time): Hora Estándar Central (UTC-6).
MST (Mountain Standard Time): Hora Estándar de la Montaña (UTC-7).
PST (Pacific Standard Time): Hora Estándar del Pacífico (UTC-8).
CET (Central European Time): Hora Central Europea (UTC+1).
EET (Eastern European Time): Hora de Europa Oriental (UTC+2).
IST (India Standard Time): Hora Estándar de la India (UTC+5:30).
JST (Japan Standard Time): Hora Estándar de Japón (UTC+9).
AEST (Australian Eastern Standard Time): Hora Estándar del Este de Australia (UTC+10).



-- View active jobs
select * from cron.job;
select (coalesce(end_time, now()) - start_time) as duration , * from  cron.job_run_details  order by start_time::date  desc , jobid limit 100  ;--- puedes tener estatus  running | FAILED | successful

---- agregar una tarea/job, si hacer un nuevo job y dejas el mismo nombre , suplantaras el anterior 
SELECT cron.schedule('create_copy', '32 14 * * *', ' COPY  ( select name,setting from pg_settings)  TO ''/tmp/pg_settings-25072024.csv'' ; ');

---- especificar los parametros del job a los que se va conectar
select cron.schedule_in_database('create_copy', '32 14 * * *', ' COPY  ( select name,setting from pg_settings)  TO ''/tmp/pg_settings-25072024.csv'' ; ' , 'db_tienda', 'user_test', true );

---- modificar un job 
select cron.alter_job(job_id bigint, schedule text DEFAULT NULL::text, command text DEFAULT NULL::text, database text DEFAULT NULL::text, username text DEFAULT NULL::text, active boolean DEFAULT NULL::boolean )

--- Eliminar jobs
SELECT cron.unschedule(1); --- colocar id 
SELECT cron.unschedule('create_copy' ); --- colocar nombre del job 

-- Eliminar todo 
truncate cron.job_run_details RESTART IDENTITY;
truncate  cron.job RESTART IDENTITY;

--- Reiniciar las secuencias, esto en caso de haber realizado un trunquear
  ALTER SEQUENCE cron.runid_seq RESTART WITH 1;
  ALTER SEQUENCE cron.jobid_seq RESTART WITH 1;

--- Reiniciar las secuencias, esto en caso de haber realizado un delete 
SELECT setval('cron.jobid_seq', COALESCE((SELECT max(jobid) FROM cron.job),1));
SELECT setval('cron.runid_seq', COALESCE((SELECT max(runid) FROM cron.job_run_details),1));



----- BIBLIOGRAFÍAS -----
https://www.sobyte.net/post/2022-02/postgresql-time-task/
https://github.com/citusdata/pg_cron
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL_pg_cron.html
https://supabase.com/docs/guides/database/extensions/pg_cron
https://www.alibabacloud.com/help/en/rds/apsaradb-rds-for-postgresql/use-the-pg-cron-extension-to-configure-scheduled-tasks
https://www.citusdata.com/blog/2023/10/26/making-postgres-tick-new-features-in-pg-cron/

```



## **DBA SQUAD: REPORTE TÁCTICO DE ARQUITECTURA Y SEGURIDAD**



### 🛡️ Análisis de Seguridad y Comportamiento del Motor (`pg_cron`)

Excelente observación sobre el comportamiento del motor. Como **Directora de Calidad y Producto (Sofía)**, he convocado a **Pedro** (Desarrollo Core), **Diego** (Seguridad de Datos) y **Samuel** (S.O. Linux) para desglosar quirúrgicamente qué ocurre bajo el capó cuando alternas este parámetro.
 

### 1. Comportamiento en `off`: Conexión vía Red (`libpq` / Sockets)

Cuando el parámetro está desactivado (`cron.use_background_workers = off`), `pg_cron` actúa como si fuera una **aplicación cliente externa**:

```
[Proceso pg_cron] ---> (Red / Socket UNIX) ---> [Handshake pg_hba.conf] ---> [Autenticación Rol] ---> [Sesión Backend]

```

* **Autenticación y Permisos:** Utiliza el usuario explícito con el que fue programada la tarea mediante la función `cron.schedule()` o `cron.schedule_in_database()`.
* **Validación de Capa de Red (`pg_hba.conf`):** PostgreSQL evalúa las reglas de `pg_hba.conf` para la interfaz declarada en `cron.host` (por defecto `/tmp` o `localhost`). El usuario configurado **debe** tener permisos explícitos para conectarse desde ese origen.
* **Consumo de Conexiones:** Cada tarea activa abre un socket que consume una ranura real dentro de la tabla de conexiones globales (`max_connections`).

 
### 2. Comportamiento en `on`: Procesos de Fondo Nativos (*Background Workers*)

Cuando cambias el parámetro a activado (`cron.use_background_workers = on`), la arquitectura abandona por completo la capa de red y pasa a ejecutarse **en la memoria compartida del motor**:

```
[Proceso pg_cron] ---> (Memoria Compartida / Dynamic Background Worker) ---> [Llamada Interna al Motor] ---> [Ejecución Directa]

```

#### **¿Cómo funciona el tema del usuario y la seguridad?**

1. **Bypass de `pg_hba.conf` (Sin Capa de Red):**
Al no utilizar conexiones TCP ni sockets de red tradicionales, **`pg_cron` ignora por completo el archivo `pg_hba.conf**`. No hay validación de IP, ni de método de autenticación (md5, scram-sha-256, trust), ni de reglas de acceso a nivel de red.
2. **Conservación de la Identidad del Rol (RBAC / Privilegios de Base de Datos):**
A pesar de no usar la red, el motor **sí respeta la identidad del usuario que programó la tarea**. Internamente, el *Background Worker* ejecuta un cambio de contexto de seguridad implícito (`SetCurrentRoleId` / `InitializeSessionUserId`) asignando el ID de usuario (*OID*) registrado en la tabla `cron.job`.
3. **Verificación de Permisos a Nivel de Objetos:**
Si creaste un usuario con permisos limitados (por ejemplo, `usr_cron_limitado`), el *Background Worker* se ejecutará estrictamente con los privilegios de ese usuario:
* **Si la tarea intenta un `DELETE`:** Y el usuario solo tiene `SELECT`, la consulta **fallará por permisos insuficientes** directamente en la máquina de estados de PostgreSQL.
* **Seguridad de Esquemas:** Se respetan las listas de control de acceso (ACLs) y las políticas de seguridad a nivel de filas (RLS).

 

### 📊 Tabla Comparativa de Seguridad y Operación

| Métrica / Dimensión | `cron.use_background_workers = off` | `cron.use_background_workers = on` |
| --- | --- | --- |
| **Paso por `pg_hba.conf**` | **SÍ.** Si el usuario/host no está en `pg_hba.conf`, la tarea falla con `FATAL: no pg_hba.conf entry`. | **NO.** Inicia directo en memoria. Bypass total del filtro de red. |
| **Identidad del Usuario** | Rol registrado en la tarea (`cron.job.username`). | Rol registrado en la tarea (`cron.job.username`). |
| **Control de Acceso (RBAC)** | Valida permisos de tablas, funciones y esquemas. | Valida permisos de tablas, funciones y esquemas. |
| **Impacto en Conexiones** | Ocupa ranuras de `max_connections`. | Ocupa ranuras de `max_worker_processes`. |
| **Riesgo de Seguridad** | Expuesto a bloqueos por fallos de red o contraseña. | Requiere control estricto de quién tiene acceso a la tabla `cron.job`. |



#### **Diferencias Técnicas: `off` vs `on**`

| Característica | `cron.use_background_workers = off` *(Valor Actual)* | `cron.use_background_workers = on` |
| --- | --- | --- |
| **Mecanismo de Ejecución** | Conexiones de Red / Socket (`libpq`). | Procesos de Fondo Nativos (*Background Workers*). |
| **Uso de Conexiones (`max_connections`)** | **Consume slots de conexión.** Cada tarea activa utiliza una conexión como si fuera un cliente externo. | **No consume slots de conexión.** Utiliza ranuras reservadas del sistema operativo/kernel. |
| **Límite de Concurrencia** | Limitado por `cron.max_running_jobs` y la disponibilidad de conexiones (`max_connections`). | Limitado por el parámetro del motor **`max_worker_processes`**. |
| **Autenticación y Red** | Requiere que el motor acepte conexiones locales (sockets/TCP) a través de `pg_hba.conf` y el parámetro `cron.host`. | Ejecución directa en memoria RAM; no pasa por la capa de red ni requiere validación de `pg_hba.conf`. |
| **Sobrecarga (Overhead)** | Mayor latencia al iniciar la tarea por el proceso de *handshake* y apertura de sesión. | Ejecución casi instantánea con menor consumo de recursos por tarea. |
 

 
### ⚠️ Dictamen de Riesgo y Recomendación del Escuadrón

> **Veto de Seguridad (Diego):**
> "Al activar `cron.use_background_workers = on`, la seguridad se desplaza por completo de la red a la base de datos. Como se salta `pg_hba.conf`, **debes asegurar que la tabla `cron.job` esté blindada**. Si un usuario malicioso logra escribir directamente en `cron.job` asignándole el usuario `postgres`, el *Background Worker* se ejecutará como superusuario sin pedir contraseña ni validar origen de red."

#### **Checklist de Auditoría para Activar `use_background_workers = on`:**

1. Revocar permisos de modificación sobre el esquema `cron` al público:
```sql
REVOKE ALL ON SCHEMA cron FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA cron FROM PUBLIC;

```


2. Garantizar que solo los usuarios administradores autorizados puedan ejecutar `cron.schedule()`.
3. Verificar que el parámetro global de PostgreSQL **`max_worker_processes`** tenga margen libre para soportar las tareas concurrentes configuradas en `cron.max_running_jobs`.


