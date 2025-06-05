### Replicación Física (Physical Replication)
Esta replicación se basa en la copia de los archivos de datos binarios (WAL - Write-Ahead Logging)  se envían en tiempo real desde el servidor principal a los servidores de réplica/Secundarios mediante una conexión persistente

- **Objetivo**: Mantener una copia exacta de la base de datos principal (primaria) en una o más bases de datos secundarias (réplicas).
- **Funcionamiento**: Utiliza los archivos de registro de escritura adelantada (WAL) para enviar cambios en tiempo real desde la base de datos primaria a las réplicas.




### Archivos que se usan en replica
```sql
1.- **`recovery.conf`** en versiones anteriores de PostgreSQL se utilizaba para configurar la recuperación de bases de datos a partir de una copia de seguridad base. En él, se especificaban parámetros importantes como `restore_command` y `recovery_target_time` o `recovery_target_name`¹. Sin embargo, a partir de PostgreSQL 12, este archivo ha sido reemplazado por el archivo `recovery.signal`. Aquí están las diferencias clave:

2. **`recovery.signal`**:
    - Es un archivo vacío que indica al servidor PostgreSQL que debe iniciar una recuperación.
    - Se crea al inicio de la recuperación y se elimina automáticamente al finalizar.
    - Cumple la función de bandera para activar el modo de recuperación.

3. **`postgresql.conf`**:
    - Ahora contiene los parámetros de recuperación.
    - Configura opciones como `restore_command`, `recovery_target`, y más.
    - Los cambios se realizan en este archivo, no en `recovery.conf`.
```

# Ejemplo de replica striming

## Configuración de servidor maestro

### Crear un usuario con permisos REPLICATION
El parámetro REPLICATION en la sentencia CREATE USER en PostgreSQL sirve para otorgar permisos especiales al usuario, permitiéndole realizar tareas de replicación dentro del sistema de bases de datos.

```SQL
CREATE USER user_replicador WITH REPLICATION PASSWORD '123123';

-- Tambien se puede usar 
# createuser --replication -P -e user_replicador -p 5516  
```

### configuración de postgresql.conf
```SQL

listen_addresses = '*'
max_replication_slots = 10

max_standby_archive_delay -1 
max_standby_streaming_delay: -1 

wal_log_hints = on
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB
max_wal_senders =  5 
wal_keep_size = 1000 
hot_standby = off  #  OFF =PRINCIPAL  ON  =SOPORTE

# archive_mode = on
# archive_timeout = 0
# archive_command = 'cp %p /path/to/archive/%f' 

-- Replicación sincrónica si quieres activar
# synchronous_commit = on 
# synchronous_standby_names = '*' 
```

### configuración de pg_hba.conf
```
host    replication     user_replicador            127.0.0.1/32            scram-sha-256
```

### Reiniciar servidor para recargar configuraciones
```
pg_ctl restart -D /sysx/data11/DATANEW/16
```

### Crear un slot 
Para habilitar la replicación física, se utiliza una característica llamada "replication slots" (ranuras de replicación), que permiten que el servidor principal mantenga un registro de los cambios necesarios para replicar. 
```SQL
SELECT * FROM pg_create_physical_replication_slot('repl_slot');

-- Esto en caso de querer eliminar el slot 
-- SELECT pg_drop_replication_slot('repl_slot');
```

---


## Configuración de servidor Secundario/Replica



```SQL
nohup  pg_basebackup -U postgres -h 10.28.230.123 -R -P -X stream -c fast -D /tmp/data16-replica/ &

# Esperar a que el proceso de pg_basebackup termine
pg_basebackup_pid=$(ps -ef | grep postgres | grep pg_basebackup | grep -v grep | awk '{print $2}')
while kill -0 "$pg_basebackup_pid" 2>/dev/null; do
    sleep 60
done

```

```SQL
sed -i 's/hot_standby = off/hot_standby = on/g' /sysx/data/postgresql.conf
```

```SQL
pg_ctl start -D /sysx/data/ -o -i
```


recovery.conf  o en el postgresql.auto.conf

ls -lhtra | grep standby.signal

```SQL
recovery_target_timeline = 'latest'
primary_conninfo = 'host=172.31.14.134 port=5432 user=replica password=passwd application_name=pgslave1'
restore_command = 'cp /var/lib/postgresql/12/main/archive/%f %p'
primary_slot_name = 'my_replication_slot'
```






### Promover un servidor a primario 
 un servidor secundario puede ser promovido a primario para evitar interrupciones en el servicio. ya que una vez que se promueve un servidor secundario a primario, 
 el antiguo servidor primario (que ahora es secundario) perderá su estatus de primario y no podrá recibir escrituras hasta que se restablezca la replicación y se configure nuevamente como primario.
```
#Promover servidor
/usr/local/pgsql/bin/pg_ctl promote -D /sysx/data/

#Cambiar hot_standby a off en postgresql.conf
sed -i 's/hot_standby = off/hot_standby = on/g' /sysx/data/postgresql.conf

```

### Herramientas y técnicas adicionales
```
1. **pgpool-II**:
   - Una herramienta que proporciona balanceo de carga, replicación y conmutación por error para PostgreSQL.

2. **Slony-I**:
   - Un sistema de replicación maestro-esclavo para PostgreSQL que permite replicar datos entre múltiples servidores.

3. **Bucardo**:
   - Una herramienta de replicación multi-maestro que permite la replicación bidireccional entre múltiples servidores PostgreSQL
   
4.- **pg_stat_replication**
   - Vista interna de PostgreSQL que muestra el estado de las conexiones de replicación.

5.- **repmgr**
   - Es una herramienta de código abierto diseñada para administrar la replicación y el failover en un grupo de servidores PostgreSQL

6.- **Patroni**: es una herramienta que facilita la implementación de soluciones de alta disponibilidad (HA)  soporta varios almacenes de configuración distribuidos como ZooKeeper, etcd, Consul o Kubernetes permite configurar y gestionar clusters de PostgreSQL con replicación y failover automáticos, asegurando que tu base de datos esté siempre disponible incluso en caso de fallos

7.- **pg_receivewal**:
	Se usa para recibir en tiempo real los archivos WAL (Write-Ahead Logging) desde el servidor primario, almacenándolos en un disco sin necesidad de un servidor de base de datos activo. Es útil para configuraciones de respaldo y recuperación.

8.- **pg_rewind**:
	Sirve para sincronizar un servidor PostgreSQL que estuvo desactualizado con otro, copiando solo los cambios necesarios en lugar de hacer una restauración completa. Se usa en escenarios de failover o recuperación tras un split-brain.
```

# Conceptos que se usan en las replicas 
```sql
**"pg_wal"** se refiere a la carpeta o directorio donde se almacena el registro de transacciones, también conocido como "Write-Ahead Log" o WAL por sus siglas en inglés. El registro de transacciones es una característica fundamental en los sistemas de gestión de bases de datos para garantizar la durabilidad y la integridad de los datos, incluso en casos de fallos o caídas del sistema. <br>

- **Activo-Activo**:  En PostgreSQL 16, se ha mejorado la replicación lógica para permitir una configuración Activo-Activo, donde dos instancias de PostgreSQL pueden recibir escrituras simultáneamente y sincronizar los cambios entre ellas.
En este modelo, todos los nodos están operativos y procesan solicitudes y cambios simultáneamente. Esto permite distribuir la carga de trabajo entre múltiples servidores, mejorando el rendimiento y la disponibilidad. Si un nodo falla, los demás continúan funcionando sin interrupciones.

- **Activo-Pasivo**: Aquí, solo un nodo está activo y maneja las solicitudes, mientras que otro nodo permanece en espera (pasivo). Si el nodo activo falla, el pasivo puede toma el control mediante failover. Este enfoque es más simple y garantiza estabilidad, pero no aprovecha los recursos del nodo pasivo hasta que sea necesario.
```


# Preguntas frecuentes 

``` 
¿Se puede usar Streaming Replication Sin Slot?
  R: En muchas situaciones, puedes operar una replicación por streaming sin usar replication slots, especialmente si tienes una red estable y las réplicas están configuradas para mantenerse relativamente cerca del primario en términos de sincronización.

¿Qué son las slots/ranuras de replicación?
Una ranura de replicación es una característica de PostgreSQL que garantiza que el servidor maestro conserve los registros WAL requeridos por las réplicas incluso cuando están desconectadas del maestro.
Si el servidor de reserva deja de funcionar, el maestro puede controlar el retraso del servidor de reserva y conservar los archivos WAL que necesita hasta que el servidor de reserva se vuelva a conectar. Luego, los archivos WAL se decodifican y se reproducen en el duplicado.

```


### Definicion de parametros  parametros de postgresql.conf
```sql
archive_mode: Habilita el envío de registros WAL a un archivo de respaldo externo.
archive_command: Define cómo y dónde almacenar los registros WAL fuera del servidor.
restore_command: Define cómo el servidor esclavo recupera registros WAL faltantes para mantener la replicación.

synchronous_commit  : PostgreSQL garantiza que una transacción no se considera confirmada hasta que el servidor principal y al menos un servidor de réplica síncrono hayan escrito la información en su almacenamiento.
synchronous_standby_names  : Este parámetro define qué servidores de réplica funcionan como "standby" síncronos. El valor ' * ' significa que cualquier servidor de réplica puede actuar como síncrono.

max_standby_archive_delay -1  -> Esto evita que las consultas en la réplica sean canceladas, pero puede generar un retraso significativo en la sincronización de datos.
max_standby_streaming_delay: -1  --> Si se establece en -1, la réplica nunca cancelará consultas en ejecución debido a conflictos con los datos replicados, lo que puede generar una acumulación de cambios pendientes.

wal_keep_size
wal_log_hints: Este parámetro es requerido para que el servicio pg_rewind sea capaz de sincronizar con el servidor primario.
wal_level: Establece el nivel de registro WAL necesario  y se utiliza este parámetro para habilitar la réplica streaming. Los posibles valores son “minimal”, “logical” o “replica”.
max_wal_size: Es usado para especificar el tamaño máximo del archivo WAL.
hot_standby:  el modo de hot standby permite conexiones de solo lectura en un servidor de espera mientras se recupera de un estado de archivo o se replica desde el servidor principal. Esto es útil para tareas de replicación y restauración precisa de copias de seguridad. OFF =PRINCIPAL  ON  =SOPORTE
  
max_wal_sender: especifica el número máximo con los servidores en espera.

    • max_wal_senders: Define el número máximo de conexiones que el servidor principal puede aceptar desde réplicas.

El parámetro wal_keep_segments fue reemplazado por wal_keep_size a partir de PostgreSQL 13.
    • wal_keep_segments: (Versiones anteriores a PostgreSQL 13): Definía la cantidad de segmentos WAL a mantener en disco.
    • wal_keep_size (PostgreSQL 13 en adelante): Define el tamaño total en MB o GB de los archivos WAL que se conservarán.

    • hot_standby: Habilita el modo de réplica en caliente, permitiendo consultas de solo lectura en la réplica.
    • primary_conninfo: Especifica cómo la réplica se conectará al servidor principal.
    • recovery_target_timeline: Configura la réplica para seguir la línea de tiempo más reciente para la recuperación.
    • trigger_file: Define la ubicación de un archivo que, cuando se crea, detiene la recuperación y permite que la réplica funcione como servidor principal. definimos la ruta en la que se creará el fichero del trigger standby.
	
standby_mode activa el modo standby en nuestro servidor standby.  modo de solo-lectura a todos los datos disponibles en el servidor esclavo 


Pgpass:  es un archivo bastante útil que nos evitará la tarea de escribir el password para la conexión a una base de datos POSTGRESQL durante las labores de backup.


max_replication_slots: Si este parámetro se establece en 0, no se habilitarán las ranuras de replicación. Debe especificar una ranura distinta de 0 (predeterminada) si está utilizando versiones de PostgreSQL anteriores a la 10 y 10 para PostgreSQL 10. Esta variable indica cuántas ranuras de replicación están permitidas. El servidor no se iniciará si establece la variable en un valor menor que la cantidad total de ranuras de replicación disponibles.
wal_level: Debe ser una réplica o superior (una réplica es el valor predeterminado). La configuración hot_standby o el archivo se asignarán a una réplica. Una réplica es suficiente para una ranura de replicación física. Se recomiendan ranuras de replicación lógicas.
max_wal_senders: Se establece en 10 de forma predeterminada; 0 en la versión 9.6 indica que la replicación está deshabilitada. Se recomienda establecerlo en al menos 16.
hot_standby: Debe estar habilitado en versiones anteriores a la 10, ya que está deshabilitado de manera predeterminada. Esto es fundamental para los nodos en espera porque, cuando está habilitado, puede conectarse y ejecutar consultas durante el modo de recuperación o en espera.
primary_slot_name:  Esta variable se configura en recovery.confel nodo de reserva. Esta es la ranura que el receptor o el nodo de reserva utilizarán al conectarse al transmisor (o principal)
full_page_writes= on  -- garantizar que las páginas de datos sean escritas de manera completa en el WAL

nohup : En resumen, nohup permite que un proceso continúe ejecutándose incluso después de cerrar la terminal o salir de la sesión, lo que es útil para evitar que los procesos se detengan accidentalmente
pg_basebackup :  copia de seguridad de un clúster de bases de datos PostgreSQL en ejecución, Proporcito : copias de backup sin afectar a otros clientes ,  recuperación en un punto específico en el tiempo,  iniciar un servidor de réplica mediante log-shipping o replicación en streaming,  Requisitos :  permisos de REPLICACIÓN o sea un superusuario. 
	-U postgres: Especifica el nombre de usuario (postgres) para conectarse al servidor PostgreSQL.
	-h 10.49.123.199: Indica la dirección IP o el nombre de host del servidor PostgreSQL al que se conectará.
	-R: Señala que la copia de seguridad está destinada a la replicación (para un servidor de réplica).
	-P: Muestra información de progreso durante la copia de seguridad.
	-X stream: Utiliza la replicación en streaming como método de copia de seguridad.
	-c fast: Configura la velocidad de conexión como rápida.
	-D /sysx/data/: Especifica el directorio de destino donde se almacenarán los archivos de copia de seguridad.


pg_stat_progress_basebackup:  esta vista te informará sobre el progreso de la copia de seguridad mientras pg_basebackup está en curso.


```

**Querys que pueden servir**
```sql

SELECT * FROM pg_replication_slots;
select * from pg_stat_activity 
select * from pg_stat_progress_basebackup;
SELECT * FROM pg_stat_wal_receiver; --- comando para ver lo que se recibe y saber cual es el servidor principal
SELECT * FROM pg_stat_replication;  --- comando para ver en el serv principal las ip serv soporte y ver la columna sync_state  puede tener el valor  async  y sync
SELECT CASE WHEN pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn()   THEN 0  ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp()) END AS log_delay;

SELECT pid, usename, application_name, state
, pg_current_wal_lsn() AS current_lsn
, sent_lsn
, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)) AS sent_diff
, write_lsn
, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), write_lsn)) AS write_diff
, replay_lsn
, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS replay_diff
, write_lag, flush_lag, replay_lag
FROM pg_stat_replication
ORDER BY application_name, pid;

select specific_schema, routine_name  from  information_schema.routines  where routine_name ilike '%repli%';
| pg_catalog      | pg_get_replica_identity_index          |
| pg_catalog      | pg_stat_get_replication_slot           |
| pg_catalog      | pg_stat_reset_replication_slot         |
| pg_catalog      | pg_copy_physical_replication_slot      |
| pg_catalog      | pg_copy_physical_replication_slot      |
| pg_catalog      | pg_drop_replication_slot               |
| pg_catalog      | pg_get_replication_slots               |
| pg_catalog      | pg_copy_logical_replication_slot       |
| pg_catalog      | pg_copy_logical_replication_slot       |
| pg_catalog      | pg_copy_logical_replication_slot       |
| pg_catalog      | pg_replication_slot_advance            |
| pg_catalog      | pg_replication_origin_drop             |
| pg_catalog      | pg_replication_origin_oid              |
| pg_catalog      | pg_replication_origin_progress         |
| pg_catalog      | pg_replication_origin_session_is_setup |
| pg_catalog      | pg_replication_origin_session_progress |
| pg_catalog      | pg_replication_origin_session_setup    |
| pg_catalog      | pg_replication_origin_xact_reset       |
| pg_catalog      | pg_replication_origin_xact_setup       |
| pg_catalog      | pg_create_logical_replication_slot     |
| pg_catalog      | pg_replication_origin_advance          |
| pg_catalog      | pg_replication_origin_create           |
| pg_catalog      | pg_replication_origin_session_reset    |
| pg_catalog      | pg_show_replication_origin_status      |
| pg_catalog      | pg_create_physical_replication_slot    


select specific_schema, routine_name  from  information_schema.routines  where routine_name ilike '%wal%';
| pg_catalog      | pg_stat_get_wal_senders       |
| pg_catalog      | pg_stat_get_wal_receiver      |
| pg_catalog      | pg_stat_get_wal               |
| pg_catalog      | pg_current_wal_lsn            |
| pg_catalog      | pg_current_wal_insert_lsn     |
| pg_catalog      | pg_current_wal_flush_lsn      |
| pg_catalog      | pg_walfile_name_offset        |
| pg_catalog      | pg_walfile_name               |
| pg_catalog      | pg_split_walfile_name         |
| pg_catalog      | pg_wal_lsn_diff               |
| pg_catalog      | pg_last_wal_receive_lsn       |
| pg_catalog      | pg_last_wal_replay_lsn        |
| pg_catalog      | pg_is_wal_replay_paused       |
| pg_catalog      | pg_get_wal_replay_pause_state |
| pg_catalog      | pg_get_wal_resource_managers  |
| pg_catalog      | pg_switch_wal                 |
| pg_catalog      | pg_wal_replay_pause           |
| pg_catalog      | pg_wal_replay_resume          |
| pg_catalog      | pg_ls_waldir                  |


 select specific_schema, routine_name  from  information_schema.routines  where routine_name ilike '%backup%';
| pg_catalog      | pg_backup_start |
| pg_catalog      | pg_backup_stop  |

```



### Cosas Extras
```sql

### Validar walls  
herramienta para ver que es lo que contiene los wall 
 
pg_waldump  --- 
pg_waldump /var/lib/pgsql/data/pg_wal/0000000100000002000000C9
 
# Ejecutar pg_basebackup en segundo plano usando un archivo de salida /home/postgres/nohup.out
nohup  pg_basebackup -U postgres -h 10.28.230.123 -R -P -X stream -c fast -D /tmp/data16-replica/ &

# Esperar a que el proceso de pg_basebackup termine
pg_basebackup_pid=$(ps -ef | grep postgres | grep pg_basebackup | grep -v grep | awk '{print $2}')
while kill -0 "$pg_basebackup_pid" 2>/dev/null; do
    sleep 60
done


# Permisos 
touch ~/.pgpass
chmod 0600 ~/.pgpass
mkdir /tmp/archive_wal
chown -R postgres:postgres /tmp/archive_wal
chmod 777 /tmp/archive_wal



```





**BIBLIOGRAFIAS**
```sql
 https://www.postgresql.fastware.com/blog/two-phase-commits-for-logical-replication-publications-subscriptions

[ pg_ctl restart -D /sysx/data11/DATANEW/17](https://docs.google.com/document/d/1dhRb2ZCVfBXCU9HAfG-1NfK4IXQUJFeL/edit

******* Rango de 1-10 dependiendo de lo bueno que es la documentacion
https://es.linux-console.net/?p=322#gsc.tab=0 ---- 10 
https://hevodata.com/learn/postgresql-streaming-replication/ --- 10
https://gist.github.com/encoreshao/cf919b300497ca863d54383455578906 ----- 10
https://gist.github.com/kpirliyev/c840e32df1619ab5875911286521c75b --- 9
https://gist.github.com/hiren-serpentcs/e23137b06b67a50c5774be76b9247390 ---- 8
https://gist.github.com/farhad0085/391258c40ff86da093945db63a48badf ----- 7
https://gist.github.com/cristianrasch/4f08b914088b5bc99c2d6466749acaa9 ---- 7
https://gist.github.com/tcpipuk/f68fb199ea8b1c1bdf48833fde86b418 --- docker replication califi 6
https://gist.github.com/vvitad/4157ab5928b751b89fc6cd63aed3c4a7 ----- calificacion 5
https://gist.github.com/anilpratti/434bcefaa9f10ca1d99b8bcd20bcb145 --- 3 
https://gist.github.com/dolezel/050f26769ec4c03f0ad075c7be2b3bc9 --- script 
https://momjian.us/main/writings/pgsql/hot_streaming_rep.pdf
https://www.postgresql.eu/events/pgconfeu2023/sessions/session/4773/slides/427/A%20journey%20into%20postgresql%20logical%20replication.pdf
https://p2d2.cz/files/PostgreSQL_LogicalReplication_LessonsLearned_v08.pdf
https://kinsta.com/blog/postgresql-replication/

https://emiliopm.com/2014/03/replicacion-en-postgresql/
https://e-mc2.net/blog/hot-standby-y-streaming-replication/#:~:text=Ficheros%20WAL%3A%20PostgreSQL%20utiliza%20los,en%20la%20base%20de%20datos.

What is WAL - https://www.postgresql.org/docs/13.0/wal-intro.html
Streaming Replication - https://www.postgresql.org/docs/13/warm-standby.html#STREAMING-REPLICATION
Replication Slots - https://hevodata.com/learn/postgresql-replication-slots/
)
```

