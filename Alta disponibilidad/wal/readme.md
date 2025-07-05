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

# Extras
```
tantor@centraldata# select proname from pg_proc where proname ilike '%wal%';
+-------------------------------+
|            proname            |
+-------------------------------+
| pg_ls_waldir                  |
| pg_stat_get_wal_senders       |
| pg_stat_get_wal_receiver      |
| pg_stat_get_wal               |
| pg_current_wal_lsn            |
| pg_current_wal_insert_lsn     |
| pg_current_wal_flush_lsn      |
| pg_walfile_name_offset        |
| pg_walfile_name               |
| pg_split_walfile_name         |
| pg_wal_lsn_diff               |
| pg_last_wal_receive_lsn       |
| pg_last_wal_replay_lsn        |
| pg_is_wal_replay_paused       |
| pg_get_wal_replay_pause_state |
| pg_get_wal_resource_managers  |
| pg_switch_wal                 |
| pg_wal_replay_pause           |
| pg_wal_replay_resume          |
+-------------------------------+
(19 rows)

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
