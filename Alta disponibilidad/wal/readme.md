# **WAL** significa **Write-Ahead Logging**.  
En pocas palabras:

*   **Qué es:** Es un mecanismo que registra en un archivo especial todas las operaciones que modifican datos **antes** de aplicarlas a la base de datos.
*   **Para qué sirve:**
    1.  **Recuperación ante fallos:** Si el servidor se cae, PostgreSQL puede reconstruir el estado consistente leyendo el WAL.
    2.  **Replicación:** Se usa para enviar cambios a réplicas (streaming replication).
    3.  **Integridad:** Garantiza que las transacciones sean atómicas y duraderas (ACID).
    4. **Punto de recuperación en el tiempo (PITR)**: Se puede restaurar la base de datos a un momento específico en el pasado.

Piensa en el WAL como un “diario o Bitácora” donde PostgreSQL apunta todo antes de hacerlo, para poder rehacer o deshacer cambios si algo sale mal.

 

---


### Estructura del WAL

- **Segmentos WAL**:  
  Cada archivo WAL tiene un tamaño fijo (por defecto **16 MB**) y se almacena en el directorio `pg_wal/` o  (anteriormente pg_xlog en versiones previas a la 10) 

- **Nombre del archivo**:  
  Los archivos tienen nombres como `00000001000000000000000A`, que representan:
    - 1 - TimeLineID (8 caracteres): Identifica la historia del clúster. Cada recuperación PITR que implica una divergencia en la historia (abrir la base de datos en un punto pasado) incrementa este ID, protegiendo contra la sobreescritura de la         historia original.

    - 2 - Número de Archivo Lógico (8 caracteres): Parte alta de la dirección.

    - 3 - Desplazamiento del Segmento (8 caracteres): Parte baja de la dirección.

- **Registros WAL**:  
  Dentro de cada segmento hay múltiples registros WAL que describen operaciones como `INSERT`, `UPDATE`, `DELETE`, `COMMIT`, etc.

- **Log Sequence Number (LSN)**:  
  Cada registro tiene un identificador único llamado **LSN**, que indica su posición dentro del WAL. Ejemplo: `0/3000020`.
   Mientras que los humanos pensamos en términos de tiempo ("recuperar hasta las 14:30"), PostgreSQL piensa en LSN ("recuperar hasta el byte 0/3000060").

---

###  ¿Cómo se almacena?

- Los registros WAL se escriben primero en **Wal buffers en memoria**.
- Al hacer `COMMIT`, se **flushean** (escriben) al disco en el archivo WAL dendro de pg_wal.
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




----

 
### 🛡️ `SELECT pg_control_checkpoint();`

📌 **¿Qué hace?**  
Devuelve información sobre el **último checkpoint registrado** en el archivo `pg_control`.

🔍 **¿Para qué sirve?**
- Verifica cuándo ocurrió el último checkpoint.
- Muestra el LSN de checkpoint y redo point.
- Indica el timeline ID actual del clúster.
- Ayuda a diagnosticar si la recuperación alcanzó el punto esperado.

🧪 **Ejemplo de uso en PITR:**
Después de recuperar un backup base, esta función confirma si el estado es consistente y en qué momento finalizó la aplicación de WALs.
 

### 🔄 `SELECT pg_control_recovery();`

📌 **¿Qué hace?**  
Entrega detalles sobre la **configuración de recuperación** usada durante el último arranque del clúster.

🔍 **¿Para qué sirve?**
- Muestra el tipo de recuperación: por tiempo, LSN, nombre, etc.
- Indica si el servidor fue promovido o aún está en modo recuperación.
- Es útil para auditar qué parámetros se usaron (`recovery_target_time`, `restore_command`, etc.).

⚠️ **Solo tiene datos si el clúster inició en modo recovery.** Si ya fue promovido, puede devolver valores vacíos.
 


---
 
### 🗂️ Archivo `.backup`

- 🔹 Se genera automáticamente cuando ejecutas un **`pg_basebackup`** con la opción de streaming WAL (`-Xs`).
- 🔹 Marca **el punto exacto en el WAL** donde inicia un respaldo base.
- 🔹 Sirve para que PostgreSQL sepa **dónde empezar a aplicar los WALs** durante una recuperación.

 **Sin este archivo, PITR puede fallar** si no hay un punto de inicio válido para el proceso de recuperación.

---

### 🗂️ Archivos `.history`
- 🔹 se genera tambien cuando haces un PITR
- 🔹 Se generan cuando hay un **cambio de línea de tiempo (timeline)**. Por ejemplo, al promover un servidor en recuperación.
- 🔹 Contienen información sobre **cómo se dividieron las líneas de tiempo** y cuál era la anterior.
- 🔹 Ayudan a PostgreSQL a entender la evolución de los WALs en escenarios de replicación o PITR avanzados.

 **Es útil en recuperaciones donde se necesita seguir una timeline específica**, como `recovery_target_timeline = 'latest'`.



---

## 🧭 ¿Qué es una Timeline en PostgreSQL?

Una “timeline” en PostgreSQL es como una *rama en un árbol de historia* de la base de datos. Cada vez que haces una restauración, o promocionas una réplica a servidor principal, PostgreSQL genera una nueva **línea de tiempo** para evitar conflictos entre archivos WAL antiguos y nuevos.

Imagina esto:

- Timeline 1: el mundo original
- Timeline 2: el universo alterno que creaste al restaurar a un punto anterior
- Timeline 3: el universo alterno del alterno, si restauras otra vez

 
## ️ ¿Para qué sirve `recovery_target_timeline`?

Te dice **cuál de esas líneas de tiempo** quieres usar al recuperar los datos. Sin esto, PostgreSQL no sabrá si debe seguir los WAL antiguos, nuevos o de restauraciones previas.

 

##  Los valores disponibles y su uso

| Valor                         | ¿Qué hace?                                                                 | ¿Cuándo usarlo?                                                              |
|------------------------------|-----------------------------------------------------------------------------|------------------------------------------------------------------------------|
| `1`, `2`, `3`, etc.          | Recupera desde una **timeline específica**. 🛠️ Debes tener el archivo `.history`. | 🧪 Escenarios avanzados con múltiples promociones o restauraciones.          |
| `'current'`                  | Recupera usando la **misma timeline** en la que se creó el backup base.     | ✅ Restauración simple, sin promociones previas ni múltiples timelines.       |
| `'latest'`                   | Recupera usando la **última timeline disponible** en los archivos WAL.      | 🧲 Restauraciones después de una promoción anterior (por ejemplo, PITR luego de PITR). |

 

## ️ ¿Qué pasa si usas el valor equivocado?

- Si usas `1` pero no tienes el archivo `00000001.history`, **el servidor NO inicia**.
- Si usas `'latest'` pero los archivos `.history` están incompletos, PostgreSQL **se detiene en recuperación** sin promoción.
- Si usas `'current'` pero hubo promociones previas, te quedarás **atascado en la timeline equivocada** y no verás los datos más recientes.
 

##  Ejemplo típico de uso

### Escenario básico
🔹 Solo tienes un backup base y los archivos WAL → usa `'current'`.

### Escenario con promoción
🔸 Restauraste antes, promoviste el clúster, y ahora quieres hacer otra recuperación → usa `'latest'`.

### Escenario controlado
🔸 Quieres restaurar **exactamente** a la timeline `2` porque hiciste una réplica → usa `recovery_target_timeline = '2'` y asegúrate que esté el `.history`.
 
---


 # redo_lsn 
 
En **PostgreSQL**, el **`redo_lsn`** (también llamado *REDO location* o *redo start LSN*) es **la posición en el WAL (Write-Ahead Log)** desde la cual el servidor debe **comenzar a aplicar (“rehacer”)** los registros de WAL durante una **recuperación** (por ejemplo, después de un crash o al iniciar un *standby* desde un backup).

### ¿Qué representa exactamente?

*   Es el **LSN (Log Sequence Number)** asociado al **último checkpoint** que el servidor consideró **completado de forma consistente**.
*   A partir de ese `redo_lsn`, PostgreSQL **reproduce** los cambios del WAL (operaciones de inserción, actualización, borrado, creación de índices, etc.) necesarios para **dejar las páginas de datos coherentes** después de un reinicio inesperado, o al **reconstruir** un servidor desde un backup + archivos WAL.

> En términos simples: **`redo_lsn` indica “desde aquí empiezo a rehacer”** tras el último checkpoint válido.

### ¿En qué situaciones es importante?

1.  **Crash recovery**  
    Al arrancar después de una caída, el motor lee el WAL **desde `redo_lsn`** para **reaplicar** los cambios no persistidos completamente en disco.
2.  **Backups físicos y PITR (Point-In-Time Recovery)**  
    Al restaurar, el `redo_lsn` del checkpoint incluido en el backup permite saber **desde qué punto del WAL** se deben **reproducir** los registros para alcanzar el estado consistente.
3.  **Servidores en standby / réplicas físicas**  
    Durante la reproducción de WAL en un *hot standby*, el `redo_lsn` de su último checkpoint marca el punto base para continuar la **aplicación del WAL**.

### ¿Dónde lo puedo ver?

Tienes varias formas:

*   **Herramienta de línea de comando `pg_controldata`** (desde el directorio de datos):
    ```bash
    pg_controldata /ruta/al/datadir | grep -i "REDO location"
	SELECT checkpoint_lsn, checkpoint_time, redo_lsn FROM pg_control_checkpoint();

    ```
    Verás algo como:  
    `Latest checkpoint's REDO location: 0/3F2A1C8`


### Relación con otros LSNs (para no confundir)

*   **`restart_lsn`** (en slots de replicación): punto mínimo de WAL que se debe **retener** para que un consumidor (replicación/logical decoding) no pierda datos.
*   **`replay_lsn` / `received_lsn` / `flush_lsn`** (en vistas de replicación): posiciones **dinámicas** que indican hasta dónde la réplica **ha recibido/flush/reproducido** WAL.
*   **`redo_lsn`**: **estático en el contexto del último checkpoint**; marca el **punto de inicio** del *redo*.

### Ejemplo interpretativo

Si el último checkpoint quedó en el LSN `0/5000000`, pero hay operaciones posteriores registradas en WAL que aún no estaban totalmente persistidas en disco, al arrancar, PostgreSQL iniciará el **proceso de redo** desde `0/5000000` y **aplicará** todas las entradas de WAL posteriores hasta alcanzar un estado consistente.




#  diferencia entre **`checkpoint_lsn`** y **`redo_lsn`** en PostgreSQL.

En tu captura se ven dos columnas:

*   **`checkpoint_lsn` = C76/6919AF80**
*   **`redo_lsn` = C76/6919AF48**

### **¿Qué significa `checkpoint_lsn`?**

*   Es el **LSN (Log Sequence Number)** donde se **escribió el último checkpoint** en el WAL.
*   Representa el **punto exacto en el WAL donde se registró el checkpoint** (el inicio del registro del checkpoint).
*   Este valor indica **dónde está el registro del checkpoint en el WAL**, no necesariamente desde dónde comienza el proceso de recuperación.

### **¿Cómo se relaciona con `redo_lsn`?**

*   **`redo_lsn`**: Es el LSN desde el cual PostgreSQL debe **comenzar a aplicar los registros WAL** durante la recuperación (el inicio del *REDO*).
*   **`checkpoint_lsn`**: Es el LSN donde se **escribió el checkpoint en el WAL** (el registro del checkpoint mismo).

En tu caso:

*   `redo_lsn` (C76/6919AF48) es **menor** que `checkpoint_lsn` (C76/6919AF80), lo cual es normal porque el proceso de recuperación empieza **antes** del registro del checkpoint para garantizar consistencia.

### **Resumen práctico**

*   **`redo_lsn`** = “Desde aquí empiezo a rehacer cambios”.
*   **`checkpoint_lsn`** = “Aquí está el registro del checkpoint en el WAL”.



---

```
select pg_current_wal_lsn(), pg_current_wal_insert_lsn(),pg_current_wal_flush_lsn() ;

pg_current_wal_lsn() te dirá el punto desde donde empezará la próxima escritura.
pg_current_wal_insert_lsn() te muestra hasta dónde ya se insertaron los datos en la memoria.
pg_current_wal_flush_lsn() te muestra hasta dónde esos datos ya están escritos en el disco duro (persistencia completa).
```




---

 

# El Checklist de PostgreSQL para la eliminación de un WAL

Para que un archivo WAL individual sea candidato a eliminación, el motor calcula el **LSN mínimo requerido** por todo el sistema. Evaluará los siguientes componentes en este orden estricto de dependencias:

### Paso 1: El Punto de Redo (Checkpoint)

PostgreSQL localiza la ubicación de Redo del último Checkpoint completado con éxito.

* **La regla:** Cualquier WAL que contenga transacciones *posteriores* al punto de Redo no se puede tocar, ya que es necesario para la recuperación en caso de un fallo de energía (*Crash Recovery*). Los WALs *anteriores* califican para pasar al siguiente filtro.

### Paso 2: El Estado del Archivado (`archive_command` / `archive_library`)

Si el parámetro `archive_mode` está en `on` u `always`, entra en juego el proceso `archiver`.

* **La regla:** El motor revisa el directorio `pg_wal/archive_status/`. Si un WAL tiene un archivo asociado con extensión `.ready`, significa que aún no se ha ejecutado con éxito el `archive_command`.
* **El freno:** PostgreSQL **jamás** borrará un WAL en estado `.ready`. El archivo debe cambiar a estado `.done` (confirmación de que el script de archivado devolvió un código `0`). Si tu almacenamiento NFS/S3 de backups se cae, los WALs se congelan aquí.

### Paso 3: Las Réplicas Activas (`Replication Slots`)

Si utilizas *Replication Slots* para tus nodos secundarios (lo cual es mandatorio en Fintech para evitar pérdida de datos):

* **La regla:** El motor consulta la vista `pg_replication_slots` y busca el `restart_lsn` más antiguo entre todos los slots activos. El primario debe conservar todos los WALs desde ese LSN hacia adelante.
* **La excepción crítica:** Aquí es donde entra tu parámetro anterior: si el atraso de una réplica supera los límites físicos configurados en `max_slot_wal_keep_size`, PostgreSQL "invalida" ese slot deliberadamente, liberando la protección sobre esos WALs para salvar al nodo primario.

### Paso 4: La Reserva Mínima de Seguridad (`wal_keep_size`)

Una vez superadas las limitantes de Checkpoints, Archivados y Slots, el motor aplica una última regla de colchón por configuración:

* **La regla:** PostgreSQL mantendrá en el directorio `pg_wal` la cantidad de archivos necesarios para cubrir el tamaño estipulado en `wal_keep_size` (en tu caso, 128MB). Esto sirve como salvavidas para réplicas tradicionales que no usan slots y sufren desconexiones cortas.

 

## La Decisión Final: ¿Eliminar o Reciclar?

Una vez que un grupo de archivos WAL ha superado con éxito los 4 filtros anteriores, PostgreSQL determina que ya no son necesarios. Sin embargo, no los borra del disco inmediatamente. Aplica la siguiente lógica de optimización de I/O:

```
¿El número de WALs actuales en pg_wal es MENOR que min_wal_size?
       |
       +---> SÍ: El archivo se RECICLA (Se le cambia el nombre al formato del siguiente WAL futuro).
       |         Esto evita el overhead de crear archivos a nivel de sistema operativo.
       |
       +---> NO: ¿Supera la estimación de max_wal_size para el próximo ciclo?
                  |
                  +---> SÍ: El archivo se ELIMINA físicamente del disco (os_unlink).
 

### Resumen para Operaciones Bancarias

Si tu `archive_command` falla, o si una réplica con un slot configurado con `max_slot_wal_keep_size = -1` se congela, el flujo se detiene por completo en el **Paso 2** o **Paso 3**. PostgreSQL ignorará por completo el límite de tu `max_wal_size (256GB)` y seguirá acumulando archivos hasta agotar el almacenamiento, priorizando la integridad de los datos sobre la disponibilidad del sistema.
