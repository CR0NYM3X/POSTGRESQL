

**pg_rewind** – Herramienta para sincronizar servidores PostgreSQL después de una divergencia. Permite:  
- **Restauración rápida de un nodo primario degradado** sin necesidad de un respaldo completo.  
- **Sincronización de datos entre servidores** tras un failover.  
- **Uso eficiente de WAL** para identificar y aplicar cambios mínimos.  
- **Reducción del tiempo de recuperación** en entornos de alta disponibilidad.  
- **Evita la necesidad de reconstrucción completa del clúster**.  


# laboratorio
Este laboratorio está diseñado para que comprendas y domines **`pg_rewind`**, una herramienta crucial en entornos de Alta Disponibilidad (HA). Su función principal es sincronizar un servidor que ha divergido de la línea de tiempo de su primario, evitando tener que realizar un `pg_basebackup` completo (ahorrando tiempo y red).

---

## 1. Conceptos y Requisitos Previos

Antes de iniciar, es vital configurar PostgreSQL para que guarde la información necesaria para el "rebobinado".

### Parámetros de Configuración (`postgresql.conf`)

Para que `pg_rewind` funcione, ambos servidores deben tener:

| Parámetro | Valor | Descripción |
| --- | --- | --- |
| `wal_log_hints` | `on` | Escribe el contenido completo de cada página en el WAL la primera vez que se modifica (necesario si no usas checksums). |
| `full_page_writes` | `on` | Requerido por defecto para la integridad de datos. |
| `wal_level` | `replica` o superior | Necesario para replicación. |

> [!IMPORTANT]
> Alternativamente, puedes inicializar el clúster con **data checksums** habilitados (`initdb -k`), lo cual elimina la necesidad estricta de `wal_log_hints = on`, aunque se recomienda tener ambos.

---

## 2. Escenario del Laboratorio

Simularemos un **Failover**:

1. El **Nodo A** es el Primario original.
2. El **Nodo B** es el Standby.
3. El Nodo A falla. El Nodo B se promociona a Primario.
4. El Nodo A regresa, pero ha "divergido" (tiene datos que el B no tiene o viceversa).
5. Usaremos `pg_rewind` para reintegrar al Nodo A como Standby del B.

---

## 3. Guía Paso a Paso

### Paso 1: Preparación del Entorno

Asegúrate de tener dos instancias corriendo. En este ejemplo, usaremos los puertos 5432 (Nodo A) y 5433 (Nodo B).

**En ambos nodos (`postgresql.conf`):**

```ini
wal_log_hints = on
max_wal_senders = 10
wal_level = replica
hot_standby = on

```

### Paso 2: Crear el Escenario de Divergencia

1. **En el Nodo A (Primario):** Crea una tabla y mete datos.
```sql
CREATE TABLE test_rewind (id int, data text);
INSERT INTO test_rewind VALUES (1, 'Datos originales del Primario A');

```


2. **Simular Falla del Nodo A:** Apaga el servicio.
```bash
pg_ctl -D /ruta/al/nodoA stop -m fast

```


3. **Promover el Nodo B (Standby):** Ahora el B es el nuevo Primario.
```bash
pg_ctl -D /ruta/al/nodoB promote

```


4. **Generar Divergencia en el Nodo B:** Inserta datos en el nuevo primario.
```sql
INSERT INTO test_rewind VALUES (2, 'Nuevos datos generados en el Nodo B');

```


5. **Divergencia "Sucia" en el Nodo A (Opcional pero recomendado para la práctica):** Arranca el Nodo A un momento, inserta un dato localmente (rompiendo la línea de tiempo) y apágalo de nuevo.
```bash
pg_ctl -D /ruta/al/nodoA start
psql -p 5432 -c "INSERT INTO test_rewind VALUES (3, 'Dato que causa conflicto en A');"
pg_ctl -D /ruta/al/nodoA stop -m fast

```



---

### Paso 3: Ejecución de `pg_rewind`

Ahora el Nodo A y el Nodo B tienen historias diferentes. El Nodo A no puede seguir al B simplemente con replicación normal.

**Sintaxis:**
`pg_rewind --target-pgdata=[Directorio_A] --source-server='[Conn_String_B]'`

**Ejecución:**

```bash
pg_rewind \
    --target-pgdata=/var/lib/postgresql/data_A \
    --source-server='host=127.0.0.1 port=5433 user=postgres dbname=postgres' \
    --progress

```

> [!TIP]
> Si el comando falla por permisos, asegúrate de que el usuario del sistema que ejecuta `pg_rewind` tenga acceso de lectura/escritura a los archivos de datos de la instancia apagada.

---

### Paso 4: Reconfiguración y Reinicio

Una vez que `pg_rewind` termina, el Nodo A está sincronizado con el B, pero está configurado como una instancia independiente. Debes convertirlo en Standby.

1. Crea el archivo `standby.signal` en el Nodo A:
```bash
touch /var/lib/postgresql/data_A/standby.signal

```


2. Configura el `primary_conninfo` en el `postgresql.conf` (o `postgresql.auto.conf`) del Nodo A para que apunte al B:
```ini
primary_conninfo = 'host=127.0.0.1 port=5433 user=replicador password=tu_pass'

```


3. Inicia el Nodo A:
```bash
pg_ctl -D /var/lib/postgresql/data_A start

```



---

## 4. Consideraciones Críticas

* **Servidor Objetivo Apagado:** El servidor que vas a "rebobinar" (`--target-pgdata`) **debe estar apagado** de forma limpia. Si hubo un crash, inícialo y deténlo normalmente antes de usar `pg_rewind`.
* **WALs Disponibles:** El servidor origen (`--source-server`) debe conservar los segmentos WAL generados desde el momento de la divergencia. Si se han borrado, `pg_rewind` fallará.
* **Solo Datos:** `pg_rewind` solo copia bloques de datos modificados. No copia archivos de configuración (`.conf`) ni certificados SSL de la carpeta de datos por defecto, lo cual es bueno porque mantiene la identidad del nodo.

---

## 5. Tabla de Verificación (Checklist)

| Tarea | Estado |
| --- | --- |
| `wal_log_hints` activo antes del incidente | [ ] |
| Servidor objetivo detenido | [ ] |
| Conectividad entre nodos permitida en `pg_hba.conf` | [ ] |
| `standby.signal` creado tras el rewind | [ ] | 


---

## Help de pg_rewind
```ini
pg_rewind  --help

pg_rewind resynchronizes a PostgreSQL cluster with another copy of the cluster.

Usage:
  pg_rewind [OPTION]...

Options:
  -c, --restore-target-wal       use "restore_command" in target configuration to
                                 retrieve WAL files from archives
  -D, --target-pgdata=DIRECTORY  existing data directory to modify
      --source-pgdata=DIRECTORY  source data directory to synchronize with
      --source-server=CONNSTR    source server to synchronize with
  -n, --dry-run                  stop before modifying anything
  -N, --no-sync                  do not wait for changes to be written
                                 safely to disk
  -P, --progress                 write progress messages
  -R, --write-recovery-conf      write configuration for replication
                                 (requires --source-server)
      --config-file=FILENAME     use specified main server configuration
                                 file when running target cluster
      --debug                    write a lot of debug messages
      --no-ensure-shutdown       do not automatically fix unclean shutdown
      --sync-method=METHOD       set method for syncing files to disk
  -V, --version                  output version information, then exit
  -?, --help                     show this help, then exit

Report bugs to <pgsql-bugs@lists.postgresql.org>.
PostgreSQL home page: <https://www.postgresql.org/>
```
