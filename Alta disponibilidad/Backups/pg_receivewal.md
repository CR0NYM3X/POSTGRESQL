
**pg_receivewal** – Herramienta de PostgreSQL para la captura en tiempo real de registros WAL. Permite:  
- **Streaming de WAL** desde un servidor PostgreSQL activo.  
- **Almacenamiento local de WAL** para recuperación Point-in-Time Recovery (**PITR**).  
- **Evita la espera de segmentos completos**, mejorando la eficiencia.  
- **Uso en entornos de alta disponibilidad** para mantener réplicas actualizadas.  
- **Compatibilidad con replication slots** para evitar pérdida de datos.  

## pg_receivewal

Esta es una herramienta fundamental para cualquier DBA que busque **RPO = 0 (Zero Data Loss)**. Mientras que el `archive_command` espera a que un archivo WAL de 16MB se llene para copiarlo, `pg_receivewal` se conecta por red y **recibe los cambios en tiempo real**, bit a bit, conforme ocurren.

 
### 1. El concepto: ¿Por qué usarlo si ya tengo `archive_command`?

* **archive_command:** Es un proceso "pasivo". Solo archiva cuando el WAL está completo. Si el servidor explota a mitad de un WAL, pierdes esos últimos minutos de transacciones.
* **pg_receivewal:** Es un proceso "activo". Se comporta como una réplica; va escribiendo el WAL en tu repositorio de backups al mismo tiempo que el servidor principal.

 
### 2. Requisitos previos

Para que funcione, necesitas que el servidor de origen permita conexiones de replicación:

1. **En `postgresql.conf`:**
* `max_wal_senders = 10` (mínimo 1 para esta herramienta).
* `wal_level = replica` o superior.


2. **En `pg_hba.conf`:**
* Debes permitir la conexión tipo `replication` para el usuario que vayas a usar.


```text
host  replication  postgres  127.0.0.1/32  trust

```


 

### 3. Uso básico de `pg_receivewal`

Supongamos que quieres guardar los WALs en `/opt/postgresql/wal_stream`.

#### Paso A: Crear el directorio

```bash
mkdir -p /opt/postgresql/wal_stream
chown postgres:postgres /opt/postgresql/wal_stream

```


 
### 4. Uso profesional (Con Slots de Replicación)

En el modo simple, si apagas `pg_receivewal` por una hora, el servidor principal podría borrar los WALs que faltan. Para evitar esto, usamos un **Replication Slot**. El servidor principal "guardará" los WALs hasta que `pg_receivewal` confirme que los recibió.

**Comando recomendado:**

```bash
 # 1. Crear el slot con pg_receivewal (solo se hace una vez), en la h se coloca el valor del parametro unix_socket_directories
pg_receivewal -h /tmp -p 5432 -U postgres --slot=slot_backup --create-slot

# tambien puedes  crear el slot directo  usando la funcion sin necesidad de pg_receivewal
psql -c "select * from pg_create_physical_replication_slot('slot_backup');"

# ver slot
psql -c "select * from pg_replication_slots;"


# 2. Iniciar la recepción continua , nos conectamos con unix-socket
pg_receivewal -h /tmp -p 5432 -U postgres -D /opt/postgresql/wal_stream --slot=slot_backup --synchronous --verbose --compress=9
```

| Parámetro | Función |
| --- | --- |
| **`-D`** | Directorio de destino donde se guardarán los archivos WAL. |
| **`--slot`** | Nombre del slot de replicación para no perder rastro del flujo. |
| **`--synchronous`** | Envía confirmación de escritura al servidor inmediatamente. |
| **`--nloop`** | Si la conexión se cae, intenta reconectar automáticamente. |

 
### 5. Cómo se ven los archivos

Al entrar a tu carpeta `/wal_stream`, verás algo curioso:

* Archivos de 16MB normales (ej. `000000010000000000000005`).
* Un archivo con extensión **`.partial`**.

```bash
postgres@vm-test:~$ ls -lhtr /opt/postgresql/wal_stream
total 1.7M
-rw------- 1 postgres postgres 1.7M Dec 28 00:24 000000010000000000000001.gz
-rw------- 1 postgres postgres   73 Dec 28 00:24 000000010000000000000002.gz.partial
```

> **Nota técnica:** El archivo `.partial` es el WAL que se está llenando "ahora mismo". En cuanto se completa, `pg_receivewal` le quita el sufijo `.partial` y empieza uno nuevo. Para tu PITR, si el servidor principal muere, podrías renombrar manualmente el último `.partial` y usarlo para recuperar hasta el último segundo.

 
### 6. Ejecución en segundo plano (Background)

Como `pg_receivewal` es un proceso que "no termina" (se queda escuchando), en producción se suele correr con `&` o como un servicio de `systemd`.

```bash
pg_receivewal -h localhost -p 5598 -D /ruta/destino --slot=mi_slot --nloop > receivewal.log 2>&1 &
```

### ¿Cómo te ayuda esto en tu laboratorio de PITR?

Si estás haciendo el laboratorio y usas `pg_receivewal`, ya no dependes de que se ejecute el `archive_command`. Puedes forzar un cambio de datos y ver cómo el archivo aparece instantáneamente en tu carpeta de backup.
 

--- 



 
### 1. Desventajas de `pg_receivewal`

`pg_receivewal` es una herramienta potente pero "peligrosa" si no se monitorea correctamente. No es un sustituto total del archivado tradicional, sino un complemento.
Aunque ofrece **RPO = 0** (no perder ni un solo dato), tiene "letra pequeña" que puede tumbar tu base de datos:

* **Riesgo de llenar el disco (El peligro del Slot):** Si usas un *Replication Slot* (lo cual es lo recomendado para no perder datos) y el proceso `pg_receivewal` se detiene (por falla de red o del servidor de backup), el servidor principal **empezará a acumular WALs infinitamente** en su carpeta `pg_wal` esperando a que el receptor vuelva. Si no tienes alertas, el disco del servidor principal se llenará y la base de datos se detendrá.
* **Gestión de archivos `.partial`:** El archivo WAL que se está recibiendo en vivo tiene la extensión `.partial`. Si el servidor principal muere, ese archivo no se puede usar para recuperación hasta que lo renombres manualmente eliminando el sufijo.
* **No hay compresión "al vuelo":** A diferencia del `archive_command` donde puedes meter un `gzip`, `pg_receivewal` recibe el flujo binario tal cual. Si quieres comprimir, debes correr un proceso extra (como un `cron`) en el servidor de destino para comprimir los archivos que ya se cerraron.
* **Dependencia de la red:** Al ser una conexión de replicación constante, cualquier inestabilidad en la red puede generar desconexiones frecuentes, lo que llena los logs de errores.

 

### 2. ¿Cuándo usarlo y cuándo no?

| Escenario | ¿Usar `pg_receivewal`? | Razón |
| --- | --- | --- |
| **Producción Crítica (Banca, Pagos)** | **SÍ** | No puedes permitirte perder ni 1 segundo de transacciones (RPO=0). |
| **Repositorio de Backups Remoto** | **SÍ** | Para sacar los logs del servidor principal lo antes posible. |
| **Archivado Local (mismo disco)** | **NO** | Es redundante e innecesario; para eso usa un simple `archive_command` con `cp`. |
| **Entornos con poco monitoreo** | **NO** | El riesgo de llenar el disco por un slot "colgado" es demasiado alto si nadie vigila. |
| **Bases de Datos con poco tráfico** | **NO** | Si tu base genera un WAL cada 2 horas, el `archive_command` es suficiente. |

 

### 3. Alternativas Superiores (Lo que usamos los expertos)

En el mundo real de las empresas, rara vez usamos `pg_receivewal` "a pelo". Usamos herramientas que gestionan el archivado, la compresión y la limpieza de forma automática:

#### A. pgBackRest (El estándar de oro)

Es la herramienta más recomendada actualmente.

* **Ventaja:** Permite archivado paralelo, compresión ZSTD (rapidísima), y puede usar tanto `archive_command` como streaming. Es extremadamente robusto.
* **Por qué es mejor:** Si falla, sabe reintentar de forma inteligente y gestiona los archivos de backup de forma mucho más eficiente que `pg_receivewal`.

#### B. WAL-G

Es el sucesor de WAL-E, muy popular en entornos de nube (AWS S3, Azure Blob, Google Cloud Storage).

* **Ventaja:** Está escrito en Go y es increíblemente rápido comprimiendo y subiendo WALs a la nube.

#### C. Barman (Backup and Recovery Manager)

Es un servidor de administración de backups externo.

* **Ventaja:** Puede usar `pg_receivewal` internamente pero te da una interfaz y herramientas para gestionar el PITR de forma mucho más sencilla.

 

### Resumen de experto

Si estás en un laboratorio, `pg_receivewal` es genial para aprender. En **producción**, mi recomendación es:

1. Usa **`archive_command`** con un script sólido para el día a día.
2. Usa una herramienta como **pgBackRest** para gestionar la complejidad.
3. Solo añade `pg_receivewal` si tu negocio te exige **Cero Pérdida de Datos** y tienes un equipo de monitoreo 24/7 que vigile los *Replication Slots*.



----

## Help de pg_receivewal
```bash
pg_receivewal --help

pg_receivewal receives PostgreSQL streaming write-ahead logs.

Usage:
  pg_receivewal [OPTION]...

Options:
  -D, --directory=DIR    receive write-ahead log files into this directory
  -E, --endpos=LSN       exit after receiving the specified LSN
      --if-not-exists    do not error if slot already exists when creating a slot
  -n, --no-loop          do not loop on connection lost
      --no-sync          do not wait for changes to be written safely to disk
  -s, --status-interval=SECS
                         time between status packets sent to server (default: 10)
  -S, --slot=SLOTNAME    replication slot to use
      --synchronous      flush write-ahead log immediately after writing
  -v, --verbose          output verbose messages
  -V, --version          output version information, then exit
  -Z, --compress=METHOD[:DETAIL]
                         compress as specified
  -?, --help             show this help, then exit

Connection options:
  -d, --dbname=CONNSTR   connection string
  -h, --host=HOSTNAME    database server host or socket directory
  -p, --port=PORT        database server port number
  -U, --username=NAME    connect as specified database user
  -w, --no-password      never prompt for password
  -W, --password         force password prompt (should happen automatically)

Optional actions:
      --create-slot      create a new replication slot (for the slot's name see --slot)
      --drop-slot        drop the replication slot (for the slot's name see --slot)

```
 

## Links
```bash
https://www.scalingpostgres.com/tutorials/postgresql-wal-archiving-pg-receivewal/
https://www.cybertec-postgresql.com/en/never-lose-a-postgresql-transaction-with-pg_receivewal/
https://www.opsdash.com/blog/postgresql-replication-slots.html
 documentación oficial -> https://www.postgresql.org/docs/current/app-pgreceivewal.html

```
