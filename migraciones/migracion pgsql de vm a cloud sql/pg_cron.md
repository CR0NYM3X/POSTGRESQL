
### 2. Análisis del Parámetro `cron.use_background_workers` (`pg_cron`)

#### **¿Para qué sirve?**

El parámetro **`cron.use_background_workers`** controla el mecanismo interno que utiliza la extensión `pg_cron` para ejecutar las tareas programadas (*jobs*) dentro de PostgreSQL.

Determina si las tareas se ejecutan como **procesos de fondo nativos del motor** (*Background Workers*) o si se ejecutan abriendo **conexiones de red/socket tradicionales** (vía libpq) hacia la base de datos.

---

#### **Diferencias Técnicas: `off` vs `on**`

| Característica | `cron.use_background_workers = off` *(Valor Actual)* | `cron.use_background_workers = on` |
| --- | --- | --- |
| **Mecanismo de Ejecución** | Conexiones de Red / Socket (`libpq`). | Procesos de Fondo Nativos (*Background Workers*). |
| **Uso de Conexiones (`max_connections`)** | **Consume slots de conexión.** Cada tarea activa utiliza una conexión como si fuera un cliente externo. | **No consume slots de conexión.** Utiliza ranuras reservadas del sistema operativo/kernel. |
| **Límite de Concurrencia** | Limitado por `cron.max_running_jobs` y la disponibilidad de conexiones (`max_connections`). | Limitado por el parámetro del motor **`max_worker_processes`**. |
| **Autenticación y Red** | Requiere que el motor acepte conexiones locales (sockets/TCP) a través de `pg_hba.conf` y el parámetro `cron.host`. | Ejecución directa en memoria RAM; no pasa por la capa de red ni requiere validación de `pg_hba.conf`. |
| **Sobrecarga (Overhead)** | Mayor latencia al iniciar la tarea por el proceso de *handshake* y apertura de sesión. | Ejecución casi instantánea con menor consumo de recursos por tarea. |
 

### 🛡️ Dictamen del Escuadrón (Marcos / Pedro)

1. **Si se mantiene en `off`:** Es la configuración más compatible en entornos administrados (como Cloud SQL / RDS). Sin embargo, si lanzas muchas tareas programadas simultáneas, puedes saturar el límite de conexiones de tu base de datos (`max_connections`), afectando a los usuarios o aplicaciones externas.
2. **Si se cambia a `on`:** Optimiza el rendimiento y libera slots de conexión. Para activarlo, es obligatorio verificar previamente que el parámetro nativo **`max_worker_processes`** de PostgreSQL tenga suficiente margen/espacio disponible para albergar los procesos de `pg_cron` sin asfixiar otros procesos de fondo del motor (como el *autovacuum* o la replicación).


# Ejemplo conf:

```text
postgres@centraldata# select name,setting, context from pg_settings where name ilike '%cron%';
+-----------------------------+---------------+------------+
|            name             |    setting    |  context   |
+-----------------------------+---------------+------------+
| cloudsql.enable_pg_cron     | on            | postmaster |
| cron.database_name          | db_test       | postmaster |
| cron.enable_superuser_jobs  | off           | superuser  |
| cron.host                   | localhost     | postmaster |
| cron.launch_active_jobs     | on            | sighup     |
| cron.log_min_messages       | warning       | sighup     |
| cron.log_run                | on            | postmaster |
| cron.log_statement          | on            | postmaster |
| cron.max_running_jobs       | 5             | postmaster |
| cron.timezone               | GMT           | postmaster |
| cron.use_background_workers | on            | postmaster |
+-----------------------------+---------------+------------+

```
