### Estructura del WAL

- **Segmentos WAL**:  
  Cada archivo WAL tiene un tamaño fijo (por defecto **16 MB**) y se almacena en el directorio `pg_wal/`.

- **Nombre del archivo**:  
  Los archivos tienen nombres como `00000001000000000000000A`, que representan:
  - Número de línea de tiempo
  - Número de archivo lógico
  - Número de segmento

- **Registros WAL**:  
  Dentro de cada segmento hay múltiples registros WAL que describen operaciones como `INSERT`, `UPDATE`, `DELETE`, `COMMIT`, etc.

- **Log Sequence Number (LSN)**:  
  Cada registro tiene un identificador único llamado **LSN**, que indica su posición en el WAL. Ejemplo: `0/3000020`.

---

###  ¿Cómo se almacena?

- Los registros WAL se escriben primero en **buffers en memoria**.
- Al hacer `COMMIT`, se **flushean** (escriben) al disco en el archivo WAL.
- Luego, PostgreSQL aplica los cambios a los archivos de datos reales.

Esto permite que, en caso de caída del sistema, se puedan **reproducir los cambios** desde el WAL y recuperar el estado exacto.

---

###  ¿Cómo se interpreta?

- PostgreSQL interpreta los WAL durante:
  - **Recuperación** (por ejemplo, después de un crash o en PITR).
  - **Replicación** (streaming entre primario y réplica).
- Cada registro contiene:
  - Tipo de operación (`XLOG_INSERT`, `XLOG_UPDATE`, etc.)
  - Página afectada
  - Datos modificados
- Puedes inspeccionar los WAL con herramientas como:
  ```bash
  pg_waldump /ruta/al/archivo_wal
  ```

---



### ¿Qué es `pg_waldump`?

Es una utilidad de línea de comandos que permite **ver el contenido de los archivos WAL en formato legible para humanos**. Es ideal para depurar, auditar o entender qué transacciones ocurrieron en un segmento específico.

---

### Ejemplo básico de uso

Supongamos que tienes un archivo WAL llamado `00000001000000000000000A` en tu directorio `pg_wal`. Puedes inspeccionarlo así:

```bash
pg_waldump /ruta/a/pg_wal/00000001000000000000000A
```

Esto mostrará una lista de registros como:

```
rmgr: Heap        len (rec/tot):  54/  54, tx: 1234, lsn: 0/3000020, desc: INSERT off 3
rmgr: Transaction len (rec/tot):  34/  34, tx: 1234, lsn: 0/3000050, desc: COMMIT
```

---

### Opciones útiles

| Opción | Descripción |
|--------|-------------|
| `--start=LSN` | Comienza a leer desde un LSN específico |
| `--end=LSN`   | Detiene la lectura en un LSN específico |
| `--limit=N`   | Muestra solo N registros |
| `--rmgr=Heap` | Filtra por tipo de operación (ej. Heap, Transaction, Btree) |
| `--timeline=N` | Inspecciona una línea de tiempo específica |

Ejemplo para ver solo los primeros 10 registros:

```bash
pg_waldump --limit=10 /ruta/a/pg_wal/00000001000000000000000A
```


-----------------

 

###  Estructura del nombre de un archivo WAL

Un archivo WAL típico tiene un nombre como:

```
00000001000000760000007D
```

Este nombre está compuesto por **24 caracteres hexadecimales** divididos en tres partes:

| Parte | Longitud | Significado |
|-------|----------|-------------|
| `00000001` | 8 dígitos | **Timeline ID** (línea de tiempo) |
| `00000076` | 8 dígitos | **Número de archivo lógico alto** |
| `0000007D` | 8 dígitos | **Número de segmento dentro del archivo lógico** |

---

### ️ ¿Qué es cada parte?

- **Timeline ID (`00000001`)**  
  Identifica la línea de tiempo actual. Cambia cuando haces una recuperación o promoción. Es útil para distinguir entre ramas de historia en la base de datos.

- **Número lógico alto (`00000076`)**  
  Representa la parte alta del **Log Sequence Number (LSN)**. Cada archivo WAL cubre 16 MB, y este número indica en qué parte de la secuencia estás.

- **Número de segmento (`0000007D`)**  
  Es la parte baja del LSN. Junto con el número lógico alto, define la posición exacta del archivo en la secuencia.

---

###  ¿Cómo saber la secuencia actual?

Puedes usar esta consulta para ver el LSN actual:

```sql
SELECT pg_current_wal_lsn();
```

Ejemplo de resultado:

```
76/7D000028
```

Esto significa:
- `76` → parte alta del LSN
- `7D000028` → parte baja

Para convertir esto en nombre de archivo WAL:

```sql
SELECT pg_walfile_name(pg_current_wal_lsn());
```

Resultado:

```
00000001000000760000007D
```

###  ¿Cómo se interpreta la secuencia?

- Los archivos WAL se generan secuencialmente.
- Si tienes varios archivos como:
  ```
  00000001000000760000007D
  00000001000000760000007E
  00000001000000760000007F
  ```
  Estás viendo una progresión en el segmento (`7D`, `7E`, `7F`...).

- Cuando el segmento llega a `FFFFFFFF`, el número lógico alto (`76`) se incrementa.


---
 

###  ¿Qué contiene `pg_wal/archive_status`?
Esta carpeta guarda **archivos de estado** que indican si un segmento WAL ha sido archivado correctamente o no y no contienen información.

- **`*.ready`** → El archivo WAL está **listo para ser archivado**.
- **`*.done`** → El archivo WAL **ya fue archivado con éxito**.

Por ejemplo:
```bash
000000010000000000000002.ready
000000010000000000000003.done
```


###  ¿Cómo se usa en el proceso de archivado?

1. Cuando se llena un archivo WAL, PostgreSQL crea un archivo `*.ready` en `pg_wal/archive_status`.
2. El proceso de archivado (`archive_command`) se ejecuta y copia el archivo WAL al destino configurado.
3. Si el comando tiene éxito (retorna 0), PostgreSQL cambia el archivo a `*.done`.
4. Si falla, el archivo `*.ready` permanece y PostgreSQL lo volverá a intentar más tarde.

###  ¿Por qué es importante?

- Permite a PostgreSQL **saber qué archivos ya fueron archivados** y cuáles aún están pendientes.
- Evita que se **reciclen o eliminen archivos WAL** antes de ser archivados.
- Es esencial para **Point-in-Time Recovery (PITR)** y replicación.

---

 

# Extras
```
tantor@centraldata#  select name,setting,context from pg_settings where name ilike '%wal%' order by context;
             name              |  setting  |  context
-------------------------------+-----------+------------
 wal_block_size                | 8192      | internal
 wal_segment_size              | 16777216  | internal
 wal_decode_buffer_size        | 524288    | postmaster
 wal_log_hints                 | off       | postmaster
 wal_buffers                   | 2048      | postmaster
 max_wal_senders               | 10        | postmaster
 wal_level                     | replica   | postmaster
 wal_writer_flush_after        | 128       | sighup
 max_wal_size                  | 2048      | sighup
 min_wal_size                  | 1024      | sighup
 wal_receiver_create_temp_slot | off       | sighup
 wal_receiver_status_interval  | 10        | sighup
 wal_receiver_timeout          | 60000     | sighup
 wal_retrieve_retry_interval   | 5000      | sighup
 wal_sync_method               | fdatasync | sighup
 wal_writer_delay              | 200       | sighup
 max_slot_wal_keep_size        | -1        | sighup
 wal_keep_size                 | 30720     | sighup
 wal_compression               | off       | superuser
 wal_recycle                   | on        | superuser
 wal_consistency_checking      |           | superuser
 wal_init_zero                 | on        | superuser
 track_wal_io_timing           | off       | superuser
 wal_sender_timeout            | 60000     | user
 wal_skip_threshold            | 2048      | user
(25 rows)


----------- herramientas
https://github.com/CR0NYM3X/POSTGRESQL/blob/main/pg_wal%20y%20transacciones.md#3-pg_archivecleanup
pg_archivecleanup

--------
### Validar walls  
herramienta para ver que es lo que contiene los wall 
 
pg_waldump  --- 
pg_waldump /var/lib/pgsql/data/pg_wal/0000000100000002000000C9

pg_ls_waldir()
pg_last_wal_receive_lsn()
pg_last_wal_replay_lsn()
Saber hasta dónde se ha escrito (pg_current_wal_lsn())
Hasta dónde se ha flusheado (pg_current_wal_flush_lsn())
Hasta dónde se ha replicado (pg_last_wal_receive_lsn())

********** SOLUCION RAPIDA **********
# pg_resetwal :  partir de PostgreSQL 10 , se utiliza para restablecer los archivos WAL, borrando los archivos wall, Este comando es útil en situaciones
# específicas donde los archivos WAL se han corrompido o  Es una herramienta de último recurso para intentar que un servidor de base de datos dañado vuelva a arrancar
# pg_resetxlog : hasta la versión 9.6 tiene el mismo objetivo que pg_resetwal

pg_resetwal -f -D /sysx/data
pg_resetxlog -f -D  /sysx/data


********** Alternativa **********
1.- Se ejecuta este comando para validar el el utimo archivo wal en uso
/rutabinario/bin/pg_controldata -D /rutadata/data | grep "REDO WAL"
 
 
2.- (A partir de que se le indica el último wal utilizado, hace la depuración de forma
regresiva para los archivos ya leídos pero que seguían conservando.) 
Una vez que se obtiene el dato se ejecuta el siguiente comando:

/rutabinario/bin/pg_archivecleanup /RUTADIRECTORIOWAL/0000000100000440000000E9



¿Qué hacen realmente?
pg_backup_start(): Marca el inicio del respaldo en el WAL y prepara el servidor para que puedas copiar los archivos del clúster de forma segura.

pg_backup_stop(): Marca el final del respaldo y asegura que todos los cambios estén registrados.

```



##  `max_wal_size`
Este parámetro establece el **tamaño máximo total** que puede alcanzar el conjunto de archivos WAL acumulados en el directorio `pg_wal/`, antes de que PostgreSQL decida realizar un **checkpoint automático**.
> Es decir, **la suma** de todos los archivos `.wal` acumulados, **no el tamaño de cada archivo individual**.


##  Ejemplo ilustrativo

Con `wal_segment_size = 16MB` y `max_wal_size = 2GB`:

```bash
2GB / 16MB = 128 archivos WAL
```

→ PostgreSQL acumulará hasta 128 archivos WAL antes de forzar un checkpoint (a menos que se dispare uno por tiempo o manualmente).



## `wal_keep_size`?

(PostgreSQL 13 en adelante): Define el tamaño total en MB o GB de los archivos WAL que se conservarán. controla cuánto espacio mínimo (en megabytes) de archivos WAL se deben conservar en el directorio pg_wal, incluso si ya no son necesarios para la recuperación local. no borra ni recicla archivos WAL hasta que al menos se hayan acumulado X megabytes de ellos. en caso de llegar al limite definido empieza a reciclar o borrar


