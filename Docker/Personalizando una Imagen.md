 

## 📂 1. Estructura del Proyecto

Primero, crea una carpeta para organizar tus archivos. Es vital separar la configuración del Dockerfile.

```text
mi-postgres-custom/
├── custom-postgres.conf  <-- Configuración de rendimiento
├── Dockerfile            <-- Receta de la imagen
└── docker-compose.yml    <-- Para pruebas locales

```

---

## 🛠️ 2. El archivo de configuración (`custom-postgres.conf`)

En este archivo definimos los parámetros de memoria y logs que mencionaste. Crea este archivo y pega lo siguiente:

```ini
# ===== Memoria / Planner =====
shared_buffers = '1GB'                 # ejemplo para un host con ~4-8GB de RAM; ajusta al 25% aprox. [10](https://www.postgresql.org/docs/current/runtime-config-resource.html)
work_mem = '32MB'                      # por operación (ajusta según concurrencia)
maintenance_work_mem = '512MB'         # VACUUM/CREATE INDEX; más alto que work_mem
effective_cache_size = '4GB'           # estimación del cache total (buffers + SO), no asigna memoria [11](https://postgresqlco.nf/doc/en/param/effective_cache_size/)

# ===== Conexiones =====
max_connections = 200

# ===== WAL / Durabilidad (ejemplo básico) =====
wal_level = replica
synchronous_commit = on

# ===== Logging (log collector, formato y rotación) =====
logging_collector = on                 # habilita el colector de logs [7](https://www.postgresql.org/docs/current/runtime-config-logging.html)
log_destination = 'stderr'             # puedes usar 'stderr,csvlog' o 'stderr,jsonlog' si procesas logs [7](https://www.postgresql.org/docs/current/runtime-config-logging.html)
log_directory = 'log'                  # relativo a PGDATA (se crea log/) [7](https://www.postgresql.org/docs/current/runtime-config-logging.html)
log_filename = 'postgresql-%Y-%m-%d.log'
log_line_prefix = '%m [%p] user=%u,db=%d '   # timestamp, pid, usuario y db
log_truncate_on_rotation = on
log_rotation_age = '1d'                # rotación diaria [8](https://postgresqlco.nf/doc/en/param/log_rotation_age/)[9](https://pgpedia.info/l/log_rotation_age.html)
log_rotation_size = '0'                # sin rotación por tamaño (pon 10MB si lo requieres) [12](https://runebook.dev/en/docs/postgresql/runtime-config-logging/GUC-LOG-ROTATION-AGE)
log_min_duration_statement = 500ms     # log de queries > 500ms (ajusta a tu SLO)
log_checkpoints = on
log_connections = on
log_disconnections = on

# ===== Otros ajustes útiles =====
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all


```

---

## 🐳 3. El Dockerfile (La Receta)

Este archivo toma la imagen oficial y le "inyecta" tu configuración para que sea parte de la imagen permanentemente.

```dockerfile
# Usamos la versión estable 16
FROM postgres:16

# Autor (Opcional)
LABEL maintainer="tu-nombre@ejemplo.com"

# 1. Copiamos nuestro archivo de configuración a una ruta interna
# No lo ponemos en /var/lib/postgresql/data porque esa carpeta se sobreescribe con volúmenes
COPY custom-postgres.conf /etc/postgresql/postgresql.conf

# 2. Ajustamos permisos para que el usuario 'postgres' sea dueño del archivo
RUN chown postgres:postgres /etc/postgresql/postgresql.conf

# 3. Indicamos a Postgres que use ESTE archivo de configuración al iniciar
# El comando "-c config_file=..." es la clave de la portabilidad
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]

```

---

## 🚀 4. Construcción y Portabilidad

Para que esta imagen funcione en otro servidor, primero debes "empaquetarla".

**Paso A: Construir la imagen localmente**
Ejecuta esto en tu terminal dentro de la carpeta:

```bash
docker build -t mi-postgres-optimizada:v1 .

```

**Paso B: ¿Cómo llevarla a otro servidor?**
Tienes dos opciones:

1. **Subirla a un Registro:** Usar Docker Hub (`docker push`).
2. **Exportar a un archivo:** Si el otro servidor no tiene internet:
```bash
docker save mi-postgres-optimizada:v1 > mi-postgres.tar
# En el otro servidor:
docker load < mi-postgres.tar

```



---

## 🧪 5. Prueba de Funcionamiento (Docker Compose)

Para verificar que los parámetros de memoria y logs se aplicaron realmente, usa este `docker-compose.yml`:

```yaml
services:
  db-prueba:
    image: mi-postgres-optimizada:v1 # Usamos la imagen que acabas de crear
    container_name: postgres-test
    environment:
      POSTGRES_PASSWORD: password123
    ports:
      - "6432:5432"
    volumes:
      # Los datos persisten, pero la configuración ya viene DENTRO de la imagen
      - pgdata_test:/var/lib/postgresql/data

volumes:
  pgdata_test:

```

### Comandos para verificar la configuración:

Una vez que el contenedor esté corriendo (`docker-compose up -d`), ejecuta estos comandos para confirmar que tu imagen personalizada funciona:

1. **Verificar `shared_buffers`:**
```bash
docker exec -it postgres-test psql -U postgres -c "SHOW shared_buffers;"

```


*Debería responder: `256MB`.*
2. **Verificar si los logs están activos:**
```bash
docker exec -it postgres-test psql -U postgres -c "SHOW logging_collector;"

```


*Debería responder: `on`.*

---

### Resumen del Flujo Correcto

1. **Configuras** el archivo `.conf` con los requerimientos técnicos.
2. **Construyes** la imagen con el `Dockerfile` (esto congela la configuración).
3. **Distribuyes** la imagen (vía Registry o archivo `.tar`).
4. **Despliegas** en el servidor destino sabiendo que, sin importar los parámetros del comando `run`, la base de datos siempre iniciará optimizada.
 
