# Log Shipping
la forma estándar de replicar en PostgreSQL antes de la versión 9.0. A esta configuración se le suele llamar **"Warm Standby"** (aunque si permites consultas, se convierte en Hot Standby).

En este modelo, el servidor secundario está en un estado de recuperación constante, esperando a que aparezcan archivos de 16 MB en una carpeta compartida para procesarlos.

---

## 1. Ventajas y Desventajas

| Característica | Log Shipping (Archivos) | Streaming Replication (Tiempo Real) |
| --- | --- | --- |
| **Pérdida de datos (RPO)** | **Alta.** Puedes perder hasta 16 MB de datos (el último archivo que no se ha cerrado). | **Mínima.** Casi cero pérdida. |
| **Carga de Red** | **Baja/Ráfagas.** Envía archivos grandes de vez en cuando. Ideal para enlaces lentos. | **Constante.** Requiere una conexión estable y permanente. |
| **Complejidad** | Muy simple de configurar (solo necesitas mover archivos). | Requiere configurar permisos, slots y conexiones activas. |
| **Uso de Lectura** | El secundario suele estar en "pausa" mientras aplica el log. | El secundario permite consultas mientras recibe datos. |

### ¿Cuándo usarlo?

* Cuando el ancho de banda entre servidores es muy limitado o inestable.
* Como **segunda capa de protección**: Tener una réplica por streaming para HA (Alta disponibilidad) y un "Warm Standby" vía Log Shipping en otra región geográfica para DR (Desastre).
* Para crear una **réplica con retraso (Delayed Standby)**: Útil para recuperarte si alguien borra una tabla por error en el primario (puedes detener la réplica antes de que procese el error).

### ¿Cuándo NO usarlo?

* Si necesitas que el secundario esté 100% al día para balancear carga de lectura.
* Si el negocio no permite perder ni un solo segundo de transacciones.

---

## 2. El Proceso (Cómo funciona)

El flujo se basa en un "buzón de correo" (una carpeta en disco, un servidor S3, un NAS, etc.):

1. **Primario:** Llena un archivo WAL de 16 MB.
2. **Primario:** Ejecuta el `archive_command` que copia ese archivo al "buzón".
3. **Secundario:** Intenta leer del "buzón" usando un comando llamado `restore_command`.
4. **Secundario:** Si encuentra un archivo nuevo, lo aplica y vuelve a pedir el siguiente. Si no hay nada, espera unos segundos.

---

## 3. Laboratorio Rápido (Configuración básica)

Imagina que tienes una carpeta compartida por NFS entre ambos servidores en `/mnt/server_wals/`.

### En el Servidor PRIMARIO (`postgresql.conf`):

```ini
wal_level = replica
archive_mode = on
# El comando copia el archivo al buzón
archive_command = 'test ! -f /mnt/server_wals/%f && cp %p /mnt/server_wals/%f'

```

### En el Servidor SECUNDARIO:

1. Primero, debes hacer una copia base (`pg_basebackup`) del primario.
2. En el archivo de configuración (en versiones modernas es en `postgresql.conf`, antes era `recovery.conf`):

```ini
# Le dice al secundario cómo traer archivos del buzón
restore_command = 'cp /mnt/server_wals/%f %p'
# Mantener el servidor en modo lectura mientras recupera (Hot Standby)
hot_standby = on

```

3. Crea un archivo vacío llamado `standby.signal` en el directorio de datos (data directory) del secundario para que sepa que debe arrancar en modo recuperación.

---

## 4. El problema del "Archivo Incompleto"

Como mencionaste antes, el problema de este método es que si el archivo de 16 MB no se llena, el primario no lo enviará. Para mitigar esto, puedes configurar en el **Primario**:

`archive_timeout = 600` (esto fuerza el cierre y archivado del WAL cada 10 minutos, incluso si no está lleno).
 
---

# recuperación sin fin

Normalmente, asociamos la palabra "recuperación" con arreglar algo que se rompió o restaurar un backup una sola vez. Pero en el mundo de las bases de datos, **la recuperación es un estado, no solo un evento.**

Aquí está el "secreto" de cómo PostgreSQL logra estar en recuperación constante sin apagarse:



## 1. El estado "Standby": Una recuperación sin fin

Cuando arrancas un PostgreSQL normal, el proceso busca archivos WAL para asegurarse de que los datos están integrados (esto es la recuperación de toda la vida). Si no encuentra más archivos, abre la base de datos para escritura y listo.

Sin embargo, cuando creas un archivo llamado **`standby.signal`** en la carpeta de datos, le estás dando una instrucción especial al motor:

> *"Entra en modo recuperación, pero **no salgas de él** aunque termines de procesar los archivos que tienes. Quédate esperando el siguiente."*

### El "Bucle Infinito" del `restore_command`

PostgreSQL entra en un ciclo lógico que funciona así:

1. **Ejecuta el `restore_command`:** "¿Hay un archivo llamado `000000010000000000000005` en el buzón?"
2. **Si lo encuentra:** Lo trae, lo aplica a los datos y vuelve al paso 1 para buscar el `...006`.
3. **Si NO lo encuentra:** El `restore_command` devuelve un error (un código distinto de cero).
4. **En lugar de morir**, PostgreSQL dice: *"Ok, no hay nada nuevo. Me duermo 5 segundos y vuelvo a preguntar"*.



## 2. Diferencias entre tipos de Recuperación

Es importante distinguir qué está pasando en el procesador:

| Tipo de Recuperación | Cuándo ocurre | ¿Cuándo termina? |
|  |  |  |
| **Crash Recovery** | Tras un apagón o fallo de energía. | Cuando procesa el último WAL disponible en el disco local. |
| **Archive Recovery** | Cuando restauras un backup manual. | Cuando procesa todos los archivos que le diste. |
| **Standby (Log Shipping)** | **Siempre que el servidor sea una réplica.** | **Nunca.** Solo termina si tú borras el archivo `standby.signal` o haces un "Promote" (ascenderlo a primario). |



## 3. ¿Cómo sabe PostgreSQL que debe seguir usando el comando?

Todo depende de la presencia del archivo **`standby.signal`** (en versiones 12 o superiores) o del archivo **`recovery.conf`** (en versiones antiguas).

* **Si el archivo existe:** PostgreSQL se comporta como un "lector de logs". Su única misión en la vida es ejecutar el `restore_command` una y otra vez.
* **Si el archivo NO existe:** PostgreSQL asume que es un servidor independiente y permite que los usuarios inserten o borren datos.



## 4. ¿Y los usuarios pueden ver los datos mientras se recupera?

Aquí es donde entra el parámetro que mencionamos antes: **`hot_standby = on`**.

* Si `hot_standby` está en **OFF**: El servidor está "mudo". Está recuperando datos constantemente pero no deja que nadie se conecte. (Esto se llama **Warm Standby**).
* Si `hot_standby` está en **ON**: PostgreSQL permite conexiones de **solo lectura**. El proceso de recuperación sigue aplicando los WALs en segundo plano mientras los usuarios consultan los datos que van llegando.



### Un ejemplo del comando en acción

Si tu `restore_command` es algo como:
`restore_command = 'cp /mnt/archive/%f %p'`

Cuando el servidor secundario necesita el siguiente archivo, el sistema operativo intenta ejecutar ese `cp`. Si el archivo aún no ha sido enviado por el primario, el comando `cp` fallará. PostgreSQL verá ese fallo, descansará un momento y volverá a intentar el `cp` más tarde. Es un proceso de "reintento infinito".

 
