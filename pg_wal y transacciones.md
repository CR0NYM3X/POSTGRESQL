Para determinar si un servidor Postgre```sql es muy transaccional, es decir, si maneja un gran número de transacciones por segundo (TPS), puedes realizar las siguientes acciones:

### 1. **Monitorear las transacciones por segundo (TPS):**
   Utiliza la vista pg_stat_database para ver las estadísticas de transacciones:

  ```sql
   SELECT datname,
          numbackends AS "Conexiones",
          xact_commit + xact_rollback AS "Transacciones Totales",
          xact_commit AS "Transacciones Completadas",
          xact_rollback AS "Transacciones Revertidas"
   FROM pg_stat_database
   WHERE datname = 'nombre_de_tu_base_de_datos';
  ```
   - **xact_commit**: Transacciones exitosas.
   - **xact_rollback**: Transacciones que han sido revertidas.
   - **numbackends**: Conexiones actuales a la base de datos.

   Puedes calcular el número de transacciones por segundo dividiendo el número de transacciones totales por el tiempo que ha estado en ejecución el servidor.

### 2. **Monitorear la tasa de escrituras y lecturas:**
   El tráfico de I/O es otro buen indicador de la carga transaccional. Usa la vista pg_stat_bgwriter:

  ```sql
   select * from pg_stat_bgwriter;
  ```
   Aquí puedes ver cuántas escrituras se están haciendo en segundo plano, lo que puede correlacionarse con la cantidad de transacciones.

### 3. **Verificar las estadísticas de WAL (Write-Ahead Logging):**
   El WAL es un buen indicador de la actividad transaccional, ya que cada transacción genera entradas en los registros WAL. Usa la siguiente consulta para verificar:

  ```sql
   SELECT SUM(wal_bytes) / (1024 * 1024) AS wal_size_mb    FROM pg_stat_wal;
  ```

   Esto te mostrará el tamaño total de los archivos WAL generados, lo cual puede darte una idea de cuántas transacciones están ocurriendo.

### 4. **Monitorear el sistema en tiempo real:**
   Puedes usar herramientas como pg_stat_statements o pg_activity para monitorear las transacciones y la actividad en tiempo real.

### 5. **Análisis de logs:**
   Configura log_min_duration_statement para registrar todas las consultas que superen un umbral de tiempo. Revisar estos logs puede ayudar a identificar patrones de alta carga transaccional.

### 6. **Verificar la replicación:**
   Si usas replicación, monitorear el pg_stat_replication también puede proporcionar información sobre la carga transaccional, especialmente si hay un retraso en la replicación.

Si observas un número elevado de transacciones por segundo o un alto volumen de I/O, es probable que tu servidor esté manejando una carga transaccional significativa.


--- 


### **1. Concepto de WAL**
El Write-Ahead Logging (WAL) es un método estándar para asegurar la integridad de los datos. La idea central es que los cambios en los archivos de datos (donde residen las tablas e índices) deben escribirse solo después de que esos cambios se hayan registrado en los archivos WAL¹.

### **2. Estructura de los Archivos WAL**
- **Segmentos**: Los archivos WAL se almacenan en el directorio `pg_wal` como un conjunto de archivos de segmento, normalmente de 16 MB cada uno⁴.
- **Páginas**: Cada segmento se divide en páginas, normalmente de 8 kB cada una⁴.

### **3. Proceso de Generación de WAL**
1. **Registro de Transacciones**: Cuando se ejecuta una transacción, los cambios no se escriben inmediatamente en el disco. En su lugar, se registran primero en un archivo WAL³.
2. **Número de Secuencia de Registro (LSN)**: Cada registro en el WAL tiene un Número de Secuencia de Registro (LSN), que es un desplazamiento en bytes dentro del WAL. Este número aumenta de manera monótona con cada nuevo registro⁴.
3. **Flushing**: Los registros WAL se escriben primero en el buffer compartido y luego se vacían (flush) al almacenamiento permanente¹.

### **4. Checkpoints**
- **Definición**: Los checkpoints son puntos en los que se garantiza que los archivos de datos se han actualizado con toda la información escrita antes de ese checkpoint².
- **Proceso**: Durante un checkpoint, todas las páginas de datos sucias se vacían al disco y se escribe un registro especial de checkpoint en el archivo WAL².

### **5. Archiving y Recuperación**
- **Archiving**: Si el archivado de WAL está habilitado, los archivos WAL se copian a una ubicación de archivo antes de ser eliminados de `pg_wal`¹.
- **Recuperación**: En caso de un fallo, PostgreSQL puede usar los registros WAL para rehacer (redo) cualquier cambio que no se haya aplicado a los archivos de datos³.

### **6. Configuración de WAL**
- **checkpoint_timeout**: Define el intervalo de tiempo entre checkpoints. El valor predeterminado es de 5 minutos².
- **max_wal_size**: Establece el tamaño máximo de los archivos WAL antes de que se fuerce un checkpoint. El valor predeterminado es de 1 GB².

### **7. Herramientas de Limpieza**
- **pg_archivecleanup**: Esta herramienta elimina los archivos WAL antiguos que ya no son necesarios¹.

### **Beneficios del WAL**
- **Integridad de Datos**: Asegura que los cambios se puedan recuperar en caso de un fallo.
- **Rendimiento**: Reduce el número de escrituras en disco, ya que solo el archivo WAL necesita ser vaciado para garantizar que una transacción se ha comprometido¹.





### **1. Inicio de una Transacción**
- **BEGIN**: El usuario puede iniciar explícitamente una transacción utilizando el comando `BEGIN`².
- **Implícito**: Si no se utiliza `BEGIN`, PostgreSQL trata cada comando SQL individual como una transacción implícita, es decir, cada comando tiene un `BEGIN` y `COMMIT` implícitos alrededor¹.

### **2. Ejecución de Comandos SQL**
Durante una transacción, el usuario puede ejecutar múltiples comandos SQL como `INSERT`, `UPDATE`, `DELETE`, etc. Estos comandos se registran en el archivo WAL (Write-Ahead Logging) para asegurar la durabilidad y consistencia de los datos².

### **3. Generación de Registros WAL**
- **Registro de Cambios**: Cada cambio realizado por los comandos SQL se registra primero en el archivo WAL antes de aplicarse a los archivos de datos¹.
- **Número de Secuencia de Registro (LSN)**: Cada registro en el WAL tiene un Número de Secuencia de Registro (LSN), que es un desplazamiento en bytes dentro del WAL¹.

### **4. Confirmación de la Transacción**
- **COMMIT**: Para finalizar y confirmar una transacción, el usuario debe ejecutar el comando `COMMIT`. Esto asegura que todos los cambios registrados en el WAL se apliquen permanentemente a los archivos de datos².
- **ROLLBACK**: Si se desea deshacer todos los cambios realizados durante la transacción, se puede utilizar el comando `ROLLBACK`².

### **5. Checkpoints y Flushing**
- **Checkpoints**: Durante un checkpoint, PostgreSQL asegura que todos los cambios registrados en el WAL hasta ese punto se hayan aplicado a los archivos de datos¹.
- **Flushing**: Los registros WAL se escriben primero en el buffer compartido y luego se vacían (flush) al almacenamiento permanente¹.




 las transacciones que solo contienen consultas (es decir, solo comandos `SELECT`) también cuentan como transacciones, pero no generan archivos WAL (Write-Ahead Logging). Aquí te explico por qué:

### **1. Naturaleza de las Consultas**
- **Lectura**: Las consultas `SELECT` solo leen datos y no modifican el estado de la base de datos¹.
- **No Generan WAL**: Dado que no hay cambios que registrar, no se generan entradas en los archivos WAL¹.

### **2. Transacciones Implícitas y Explícitas**
- **Implícitas**: Cada comando SQL en PostgreSQL se ejecuta dentro de una transacción implícita si no se especifica lo contrario. Esto incluye las consultas `SELECT`².
- **Explícitas**: Puedes agrupar varias consultas `SELECT` dentro de una transacción explícita utilizando `BEGIN` y `COMMIT`, pero esto sigue sin generar archivos WAL².

### **3. Beneficios de las Transacciones de Solo Lectura**
- **Consistencia**: Aseguran que todas las consultas dentro de la transacción vean un estado consistente de la base de datos.
- **Aislamiento**: Pueden utilizar niveles de aislamiento como `REPEATABLE READ` o `SERIALIZABLE` para evitar lecturas inconsistentes¹.







En PostgreSQL, la generación de archivos WAL (Write-Ahead Logging) sigue un proceso técnico específico para asegurar la integridad de los datos. Aquí te explico cómo funciona:

### **1. Registro de Cambios**
Cada vez que se realiza una transacción en la base de datos, PostgreSQL primero registra los cambios en un archivo WAL antes de aplicarlos a los archivos de datos. Esto asegura que, en caso de un fallo, los cambios puedan ser recuperados⁴.

### **2. Estructura del WAL**
Los registros WAL se agregan secuencialmente a los archivos WAL. Cada registro contiene información sobre las modificaciones realizadas, como inserciones, actualizaciones o eliminaciones⁶.

### **3. Número de Secuencia de Registro (LSN)**
Cada registro en el WAL tiene un Número de Secuencia de Registro (LSN), que es un desplazamiento en bytes dentro del WAL. Este número aumenta de manera monótona con cada nuevo registro⁸.

### **4. Flushing y Checkpoints**
- **Flushing**: Los registros WAL se escriben primero en el buffer compartido y luego se vacían (flush) al almacenamiento permanente.
- **Checkpoints**: Durante un checkpoint, PostgreSQL asegura que todos los cambios registrados en el WAL hasta ese punto se hayan aplicado a los archivos de datos. Esto permite eliminar o reciclar los archivos WAL antiguos⁴.

### **5. Archiving**
Si el archivado de WAL está habilitado, los archivos WAL se copian a una ubicación de archivo antes de ser eliminados de la carpeta `pg_wal`⁴.

### **6. Recuperación**
En caso de un fallo, PostgreSQL puede usar los registros WAL para rehacer (redo) cualquier cambio que no se haya aplicado a los archivos de datos, asegurando así la integridad de la base de datos⁴.

Este proceso permite a PostgreSQL mantener la consistencia y durabilidad de los datos, incluso en caso de fallos del sistema.



En caso de un fallo, PostgreSQL entra automáticamente en modo de recuperación para restaurar la base de datos a su último estado consistente utilizando los archivos WAL (Write-Ahead Logging). Aquí te explico cómo funciona:









### **Recuperación Automática**
1. **Detección del Fallo**: Cuando PostgreSQL se reinicia después de un fallo, detecta automáticamente que no se cerró correctamente.
2. **Reproducción de WAL**: PostgreSQL lee los archivos WAL y reaplica todas las transacciones confirmadas que no se habían escrito en los archivos de datos antes del fallo³.
3. **Consistencia**: Este proceso asegura que la base de datos vuelva a un estado consistente, aplicando todos los cambios necesarios registrados en los archivos WAL³.

### **Intervención del Administrador**
En la mayoría de los casos, la recuperación automática es suficiente. Sin embargo, hay situaciones donde el administrador puede necesitar intervenir:
- **Archiving y PITR (Point-In-Time Recovery)**: Si tienes configurado el archivado continuo de WAL, puedes necesitar restaurar desde un backup y luego reproducir los archivos WAL hasta un punto específico en el tiempo¹.
- **Configuraciones Especiales**: En configuraciones avanzadas, como la replicación o el uso de servidores en espera (standby), el administrador puede necesitar ajustar configuraciones o iniciar manualmente ciertos procesos².

En resumen, PostgreSQL maneja la mayoría de los fallos automáticamente, pero tener una buena estrategia de backup y recuperación puede ser crucial para situaciones más complejas.




# Cuando se eliminan los archivos wal

En PostgreSQL, los archivos WAL (Write-Ahead Logging) se eliminan de la carpeta `pg_wal` cuando ya no son necesarios para la recuperación de datos. Esto puede suceder en varias situaciones:

1. **Archiving**: Si tienes configurado el archivado de WAL, PostgreSQL moverá los archivos WAL a una ubicación de archivo especificada y luego los eliminará de `pg_wal`¹.
2. **Checkpointing**: Durante un punto de control (checkpoint), PostgreSQL determina qué archivos WAL ya no son necesarios para la recuperación y los elimina².
3. **Retention Policy**: Puedes configurar políticas de retención para mantener solo un número específico de archivos WAL o archivos de un cierto período de tiempo².






Los checkpoints en PostgreSQL son una parte crucial del sistema de gestión de transacciones y recuperación de datos.  

### ¿Para Qué Sirven los Checkpoints?
1. **Persistencia de Datos**: Los checkpoints aseguran que todos los datos en memoria se escriban en disco. Esto incluye datos modificados y registros de transacciones (WAL - Write-Ahead Logging).
2. **Recuperación de Fallos**: En caso de un fallo del sistema, los checkpoints permiten que PostgreSQL recupere los datos hasta el último checkpoint, minimizando la pérdida de datos.
3. **Optimización del Rendimiento**: Ayudan a gestionar la carga de I/O al distribuir las escrituras en disco de manera más uniforme.

### ¿Cuándo Usar Checkpoints?
1. **Antes de un Backup**: Ejecutar un checkpoint antes de realizar un backup asegura que todos los datos recientes estén escritos en disco, garantizando la consistencia del backup.
2. **Mantenimiento Programado**: Durante periodos de mantenimiento o baja actividad, forzar un checkpoint puede ayudar a reducir la carga de I/O durante las horas pico.
3. **Recuperación Planificada**: Antes de realizar operaciones críticas que puedan requerir una recuperación rápida en caso de fallo.

### Importancia de los Checkpoints
1. **Consistencia de Datos**: Garantizan que los datos en memoria se sincronicen con los datos en disco, manteniendo la integridad de la base de datos.
2. **Reducción del Tiempo de Recuperación**: Al tener datos recientes escritos en disco, el tiempo necesario para recuperar la base de datos después de un fallo se reduce significativamente.
3. **Gestión de Recursos**: Ayudan a gestionar el uso de recursos del sistema, especialmente la I/O, evitando picos de carga que puedan afectar el rendimiento.

### Ejemplo de Uso
Para ejecutar un checkpoint manualmente:
```sql
CHECKPOINT;
```

### Consideraciones
- **Impacto en el Rendimiento**: Forzar un checkpoint puede causar una carga significativa de I/O, por lo que es recomendable hacerlo durante periodos de baja actividad.
- **Configuración**: La frecuencia de los checkpoints puede configurarse en el archivo `postgresql.conf` mediante los parámetros `checkpoint_timeout`, `checkpoint_completion_target`, y otros.



El **checkpoint record** en PostgreSQL es una entrada específica en el registro de escritura anticipada (WAL) que marca el inicio de un checkpoint. Este registro contiene información crucial sobre el estado de la base de datos en el momento del checkpoint, incluyendo:

1. **Posición del WAL**: Indica la posición exacta en el WAL donde comienza el checkpoint.
2. **Información de Redo**: Proporciona la posición desde la cual se debe comenzar a aplicar los registros WAL durante la recuperación.
3. **Estado de los Buffers**: Detalla el estado de los buffers de la base de datos en el momento del checkpoint.
4. **Información de Transacciones**: Incluye detalles sobre las transacciones activas y sus estados.
5- **Contenido**: Contiene información crucial sobre el estado de la base de datos en el momento del checkpoint, como la posición exacta en el WAL, el estado de los buffers y detalles de las transacciones activas.
6- **Función**: Ayuda a PostgreSQL a saber desde dónde comenzar a aplicar los cambios registrados en el WAL durante la recuperación, minimizando el tiempo de recuperación y asegurando la consistencia de los datos.

### Función del Checkpoint Record

El checkpoint record es esencial para la recuperación de la base de datos. En caso de un fallo, PostgreSQL utiliza este registro para determinar desde dónde debe comenzar a aplicar los cambios registrados en el WAL para restaurar la base de datos a un estado consistente. Esto ayuda a minimizar el tiempo de recuperación y asegura que todos los datos confirmados hasta el último checkpoint estén presentes en el disco¹.

### ¿Dónde se Ubica?

El checkpoint record se almacena en los archivos WAL, que generalmente se encuentran en la carpeta `pg_wal` dentro del directorio de datos de PostgreSQL. No es un archivo separado, sino una entrada dentro de estos archivos WAL.



 



# Herramientas que nos ayudan con los wal 



### 1. `pg_resetwal -f -D /sysx/data`
**Propósito**: Este comando se utiliza para resetear el Write-Ahead Log (WAL) y otra información de control almacenada en el archivo `pg_control`. Es una herramienta de último recurso para recuperar un servidor de base de datos que no puede arrancar debido a la corrupción de estos archivos¹.

**Cuándo Usarlo**:
- **Último Recurso**: Solo debe usarse cuando el servidor no puede arrancar debido a la corrupción del WAL.
- **Previo Respaldo**: Siempre respalda tus datos antes de usar este comando, ya que puede llevar a la pérdida de datos.

**Importancia**:
- **Recuperación**: Permite que un servidor corrupto vuelva a arrancar.
- **Riesgo**: Puede resultar en pérdida de datos o inconsistencias, por lo que debe usarse con precaución².



### 2. `pg_controldata -D /sysx/data | grep "REDO WAL file"`
**Propósito**: Este comando muestra información de pg_control sobre un clúster de base de datos PostgreSQL. Incluye detalles inicializados durante `initdb`, como la versión del catálogo, información sobre el WAL y el procesamiento de checkpoints⁴.

pg_control es un archivo binario de 8 KB que contiene información crucial sobre el estado interno del servidor. Este archivo almacena datos sobre varios aspectos del servidor, como el punto de control más reciente y parámetros fundamentales establecidos por initdb
Ruta: /sysx/data14/global/pg_control

**Cuándo Usarlo**:
- **Diagnóstico**: Para obtener información detallada sobre el estado del clúster de base de datos.
- **Mantenimiento**: Útil para verificar la configuración y el estado del sistema antes de realizar operaciones críticas.

**Importancia**:
- **Transparencia**: Proporciona una visión clara del estado y configuración del clúster.
- **Mantenimiento**: Ayuda en la resolución de problemas y en la planificación de tareas de mantenimiento.

```sql
 select * from pg_control_system();
+--------------------+--------------------+---------------------+--------------------------+
| pg_control_version | catalog_version_no |  system_identifier  | pg_control_last_modified |
+--------------------+--------------------+---------------------+--------------------------+
|               1300 |          202107181 | 7381508807802424143 | 2024-09-19 10:29:53-07   |
+--------------------+--------------------+---------------------+--------------------------+
```


### 3. `pg_archivecleanup`

### ¿Para Qué Sirve `pg_archivecleanup`?
1. **Limpieza de Archivos WAL**: Elimina archivos WAL antiguos que ya no son necesarios, liberando espacio en disco.
2. **Gestión de Archivos en Servidores Standby**: Se puede configurar para limpiar archivos WAL en servidores standby, asegurando que solo se mantengan los archivos necesarios para la recuperación¹.

### Cuándo Usarlo
1. **Mantenimiento Regular**: Para evitar que los archivos WAL se acumulen y ocupen demasiado espacio en disco.
2. **Configuración de Servidores Standby**: Como parte del comando `archive_cleanup_command` en la configuración de un servidor standby.
3. **Modo de Prueba (Dry Run)**: Para ver qué archivos serían eliminados sin realmente eliminarlos, usando la opción `-n`.
4. **Modo de Eliminación (Delete)**: Para eliminar realmente los archivos WAL antiguos, usando la opción `-d`.

### Ejemplos de Uso

1. **Modo de Prueba (Dry Run)**:
   ```sh
   pg_archivecleanup -n /ruta/al/archivo 00000001000000000000001E
   ```
   Esto listará los archivos WAL que serían eliminados sin realizar ninguna acción.

2. **Modo de Eliminación (Delete)**:
   ```sh
   pg_archivecleanup -d /ruta/al/archivo 00000001000000000000001E
   ```
   Esto eliminará los archivos WAL que son más antiguos que el archivo especificado².

### Importancia
1. **Optimización del Almacenamiento**: Ayuda a mantener el uso del disco bajo control al eliminar archivos WAL innecesarios.
2. **Recuperación Eficiente**: Asegura que solo se mantengan los archivos WAL necesarios para la recuperación, mejorando la eficiencia del sistema.
3. **Mantenimiento Sencillo**: Facilita la gestión de archivos WAL en servidores standby y en configuraciones de alta disponibilidad.

### Configuración en un Servidor Standby
Para configurar `pg_archivecleanup` en un servidor standby, puedes agregar la siguiente línea a tu archivo `postgresql.conf`:
```sh
archive_cleanup_command = 'pg_archivecleanup /ruta/al/archivo %r'
```
Esto asegurará que los archivos WAL antiguos se limpien automáticamente durante la recuperación.




### 4. `pg_waldump`

### ¿Para Qué Sirve `pg_waldump`?
1. **Depuración**: Permite a los administradores de bases de datos y desarrolladores ver los registros WAL en un formato legible, lo que facilita la identificación de problemas.
2. **Educación**: Ayuda a entender cómo funciona el sistema de WAL en PostgreSQL, proporcionando una visión detallada de las operaciones internas.
3. **Auditoría**: Puede ser utilizado para auditar las operaciones realizadas en la base de datos.

### Cuándo Usarlo
1. **Depuración de Problemas**: Cuando necesitas investigar problemas específicos relacionados con la replicación o la recuperación de datos.
2. **Análisis de Rendimiento**: Para analizar cómo se están registrando las transacciones y optimizar el rendimiento.
3. **Educación y Aprendizaje**: Para aprender más sobre el funcionamiento interno de PostgreSQL y cómo se gestionan las transacciones.

### Ejemplos de Uso



1. **Mostrar Registros WAL desde un Segmento Específico**:
   ```sh
   pg_waldump /ruta/al/archivo 00000001000000000000001E
   ```

2. **Mostrar Información Detallada sobre Bloques de Respaldo**:
   ```sh
   pg_waldump -b /ruta/al/archivo
   ```

3. **Seguir Nuevos Registros WAL en Tiempo Real**:
   ```sh
   pg_waldump -f /ruta/al/archivo
   ```

### Opciones Comunes
- **`-b`**: Muestra información detallada sobre los bloques de respaldo.
- **`-f`**: Sigue nuevos registros WAL en tiempo real.
- **`-n`**: Limita el número de registros mostrados.
- **`-r`**: Muestra solo los registros generados por un administrador de recursos específico¹.




[postgres@SERVER_TEST pg_wal]$ pwd
/sysx/data14/pg_wal

[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 16M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 18 18:36 000000010000000000000008    <---- Archivo Wal, Checkpoint Record 


------- Esto pasa si quieres dumpear el wal Checkpoint Record 
[postgres@SERVER_TEST pg_wal]$ pg_waldump 000000010000000000000008
pg_waldump: error: could not find a valid record after 0/8000000

------- Esto pasa si quieres Eliminar el archivo wal  Checkpoint Record 
[postgres@SERVER_TEST pg_wal]$ pg_archivecleanup -d  /sysx/data14/pg_wal  000000010000000000000008
pg_archivecleanup: keeping WAL file "/sysx/data14/pg_wal/000000010000000000000008" and later







### Parámetros checkpoints y su Función

1. **`log_checkpoints = on`**
   - **Función**: Habilita el registro de información sobre los checkpoints en los logs del servidor.
   - **Recomendación**: Útil para monitoreo y diagnóstico. Habilítalo si necesitas información detallada sobre el rendimiento y comportamiento del sistema.

2. **`checkpoint_timeout = 5min`**
   - **Función**: Define el tiempo máximo entre checkpoints automáticos. El valor predeterminado es 5 minutos¹.
   - **Recomendación**: Un valor más bajo puede reducir el tiempo de recuperación después de un fallo, pero incrementa la carga de I/O. Ajusta según la carga de trabajo y la capacidad de I/O de tu sistema.

3. **`checkpoint_completion_target = 0.9`**
   - **Función**: Especifica el porcentaje del tiempo entre checkpoints que se debe usar para completar la escritura de datos. Un valor de 0.9 significa que el 90% del tiempo entre checkpoints se usará para escribir datos².
   - **Recomendación**: Un valor alto (como 0.9) distribuye la carga de I/O de manera más uniforme, reduciendo picos de carga. Es adecuado para sistemas con alta carga de trabajo.

4. **`checkpoint_flush_after = 256kB`**
   - **Función**: Define la cantidad de datos escritos antes de forzar una operación de flush al disco².
   - **Recomendación**: Un valor de 256kB es un buen punto de partida. Ajusta según el rendimiento de tu sistema de almacenamiento.

5. **`checkpoint_warning = 30s`**
   - **Función**: Genera una advertencia en el log si un checkpoint tarda más de este tiempo en completarse².
   - **Recomendación**: Mantén este valor bajo para recibir alertas tempranas sobre posibles problemas de rendimiento.

### Recomendaciones Generales

- **Monitoreo Regular**: Habilitar `log_checkpoints` y ajustar `checkpoint_warning` te ayudará a identificar y resolver problemas de rendimiento rápidamente.
- **Balance de I/O**: Ajusta `checkpoint_timeout` y `checkpoint_completion_target` para equilibrar la carga de I/O y minimizar el impacto en el rendimiento.
- **Pruebas y Ajustes**: Realiza pruebas en tu entorno específico para encontrar la configuración óptima. Cada sistema puede tener diferentes necesidades y capacidades.
 
 
 
 
```sql
 postgres@postgres# select name,setting from pg_settings where name ilike '%archive%';
+---------------------------+------------+
|           name            |  setting   |
+---------------------------+------------+
| archive_cleanup_command   |            |
| archive_command           | (disabled) |
| archive_library           |            |
| archive_mode              | off        |
| archive_timeout           | 0          |
| max_standby_archive_delay | 30000      |
+---------------------------+------------+

archive_command = "scp %f replica:/usr/share/wal_archive:%r"
archive_cleanup_command = 'pg_archivecleanup /usr/share/wal_archive %r'
archive_cleanup_command = 'pg_archivecleanup -d /mnt/standby/archive %r 2>>cleanup.log'



postgres@postgres# select name,setting,unit from pg_settings where name ilike '%wal%';
+-------------------------------+-----------+------+
|             name              |  setting  | unit |
+-------------------------------+-----------+------+
| max_slot_wal_keep_size        | -1        | MB   |
| max_wal_senders               | 10        | NULL |
| max_wal_size                  | 2048      | MB   |
| min_wal_size                  | 1024      | MB   |
| track_wal_io_timing           | off       | NULL |
| wal_block_size                | 8192      | NULL |
| wal_buffers                   | 2048      | 8kB  |
| wal_compression               | off       | NULL |
| wal_consistency_checking      |           | NULL |
| wal_decode_buffer_size        | 524288    | B    |
| wal_init_zero                 | on        | NULL |
| wal_keep_size                 | 0         | MB   |
| wal_level                     | replica   | NULL |
| wal_log_hints                 | off       | NULL |
| wal_receiver_create_temp_slot | off       | NULL |
| wal_receiver_status_interval  | 10        | s    |
| wal_receiver_timeout          | 60000     | ms   |
| wal_recycle                   | on        | NULL |
| wal_retrieve_retry_interval   | 5000      | ms   |
| wal_segment_size              | 16777216  | B    |
| wal_sender_timeout            | 60000     | ms   |
| wal_skip_threshold            | 2048      | kB   |
| wal_sync_method               | fdatasync | NULL |
| wal_writer_delay              | 200       | ms   |
| wal_writer_flush_after        | 128       | 8kB  |
+-------------------------------+-----------+------+


postgres@postgres# select proname  from pg_proc where proname ilike '%wal%';
+-------------------------------+
|            proname            |
+-------------------------------+
| pg_stat_get_wal_senders       |
| pg_stat_get_wal_receiver      |
| pg_stat_get_wal               |
| pg_current_wal_lsn            |
| pg_current_wal_insert_lsn     |
| pg_current_wal_flush_lsn      |
| pg_walfile_name_offset        |
| pg_walfile_name               |
| pg_wal_lsn_diff               |
| pg_last_wal_receive_lsn       |
| pg_last_wal_replay_lsn        |
| pg_is_wal_replay_paused       |
| pg_get_wal_replay_pause_state |
| pg_switch_wal                 |
| pg_wal_replay_pause           |
| pg_wal_replay_resume          |
| pg_ls_waldir                  |
+-------------------------------+

postgres@postgres# select * from pg_stat_archiver ;
+----------------+-------------------+--------------------+--------------+-----------------+------------------+------------------------------+
| archived_count | last_archived_wal | last_archived_time | failed_count | last_failed_wal | last_failed_time |         stats_reset          |
+----------------+-------------------+--------------------+--------------+-----------------+------------------+------------------------------+
|              0 | NULL              | NULL               |            0 | NULL            | NULL             | 2024-06-17 09:24:42.22773-07 |
+----------------+-------------------+--------------------+--------------+-----------------+------------------+------------------------------+
(1 row)

postgres@postgres# select * from pg_stat_bgwriter ;
+-[ RECORD 1 ]----------+------------------------------+
| checkpoints_timed     | 7239                         |
| checkpoints_req       | 170                          |
| checkpoint_write_time | 325632                       |
| checkpoint_sync_time  | 634                          |
| buffers_checkpoint    | 228487                       |
| buffers_clean         | 0                            |
| maxwritten_clean      | 0                            |
| buffers_backend       | 213940                       |
| buffers_backend_fsync | 0                            |
| buffers_alloc         | 228618                       |
| stats_reset           | 2024-06-17 09:24:42.22773-07 |
+-----------------------+------------------------------+


postgres@postgres# select * from pg_stat_wal;
+-------------+---------+------------+------------------+-----------+----------+----------------+---------------+------------------------------+
| wal_records | wal_fpi | wal_bytes  | wal_buffers_full | wal_write | wal_sync | wal_write_time | wal_sync_time |         stats_reset          |
+-------------+---------+------------+------------------+-----------+----------+----------------+---------------+------------------------------+
|    39370363 |    2185 | 3046490522 |            18772 |     20220 |     1403 |              0 |             0 | 2024-06-17 09:24:42.22773-07 |
+-------------+---------+------------+------------------+-----------+----------+----------------+---------------+------------------------------+
(1 row)



postgres@postgres# select * from pg_walfile_name(pg_current_wal_lsn());
+--------------------------+
|     pg_walfile_name      |
+--------------------------+
| 00000001000000010000005F |
+--------------------------+
(1 row)

Time: 0.484 ms
 
 
postgres@postgres# select pg_ls_waldir();
+--------------------------------------------------------------+
|                         pg_ls_waldir                         |
+--------------------------------------------------------------+
| (00000001000000010000004C,16777216,"2024-09-19 17:41:50-07") |
| (00000001000000010000004D,16777216,"2024-09-19 17:42:20-07") |
| (00000001000000010000004E,16777216,"2024-09-19 17:42:21-07") |


``` 


# EJEMPLO   WAL Y CHECKPOINT
```SQL








``` 



### Bilbiografia :

https://www.percona.com/blog/postgresql-wal-retention-and-clean-up-pg_archivecleanup/













