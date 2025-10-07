
# inicializar postgresql
```sql
/usr/pgsql-15/bin/initdb -E UTF-8 -D /sysx/data    --data-checksums  &>/dev/null

  
# checksum 
sirve para  Detectar corrupción a tiempo y puede salvarte de un desastre. PostgreSQL calcula una suma de verificación para cada bloque de datos que escribe en disco. Luego, al leer ese bloque, verifica que la suma coincida. Si no coincide, detecta corrupción silenciosa (por ejemplo, por fallos de hardware o discos defectuosos).  Puedes usarla como parte de un proceso de mantenimiento o verificación periódica.

--- Cuando usarlo pg_checksums---
- Antes o después de una migración.
- Antes de hacer un pg_basebackup o un pg_upgrade.
- Después de un fallo de hardware o corte de energía.
- Como parte de un mantenimiento programado. 
- Verificaciones periódicas en entornos críticos.

# el servidor debe estar apagado completamente, ya que necesita acceso exclusivo a los archivos de datos para usar la herramienta pg_checksums.
 $PGBIN16/pg_ctl stop -D /sysx/data16/DATANEW/data_maestro
 

# Verificar integridad
$PGBIN16/pg_checksums -D /sysx/data16/DATANEW/data_maestro --check --progress

45/45 MB (100%) computed
Checksum operation completed
Files scanned:   1857
Blocks scanned:  5826
Bad checksums:  0
Data checksum version: 1

# Activar o desactivar checksum
$PGBIN16/pg_checksums -D /sysx/data16/DATANEW/data_esclavo62 --enable --progress 
$PGBIN16/pg_checksums -D /sysx/data16/DATANEW/data_esclavo62 --disable --progress 
``` 

### Postmaster 
``` 
Objetivo del Postmaster
El postmaster es responsable de:

Iniciar el servidor: Es el primer proceso que se ejecuta al iniciar PostgreSQL.
Gestionar conexiones: Escucha las conexiones entrantes y crea un nuevo proceso de servidor (llamado postgres) para cada conexión2.
Supervisar procesos: Monitorea los procesos del servidor y toma medidas si alguno falla.

https://dba.stackexchange.com/questions/345601/what-does-postmaster-do-in-postgresql

[postgres@server_test ~]$ $PGBIN16/pg_ctl status -D $PGDATA16
pg_ctl: server is running (PID: 587297)
/usr/pgsql-16/bin/postgres "-D" "/sysx/data16"



[postgres@server_test ~]$ cat  /sysx/data16/postmaster.pid
587297 --> El PID (Process ID) del proceso postmaster.
/sysx/data16 -->  El directorio de datos de PostgreSQL.
1741823615 --> El ID de la instancia de PostgreSQL.
5416 --> El puerto en el que PostgreSQL está escuchando  .
/run/postgresql -->  El directorio donde se almacenan los archivos de socket.
*   -->  Indica que no hay un archivo de socket específico.
18446744071562068402     65594  -->  Información adicional sobre el sistema operativo y el tiempo de inicio.
ready   --> Estado actual del servidor, indicando que está listo para aceptar conexiones.
``` 
 




## VER LAS CONFIGURACIONES DESDE LA DB
```sql
select * from pg_settings; --- ver valores de los parametros 
select * from pg_config --- Ver rutas de binarios 
select current_setting('search_path'); --- ver configuraciones 
show statement_timeout; --- ver parametros  individual
SHOW ALL-- Ver todos los  parametros

select  name,setting,boot_val,reset_val,context  from pg_settings  where name = 'statement_timeout'; -- ver todos los parametros pero aqui estoy filtrando
	name: El nombre del parámetro de configuración.
	setting: El valor actual del parámetro.
	boot_val: El valor predeterminado del parámetro al iniciar el servidor por primera vez.
	reset_val: El valor al que se restablece el parámetro si se usa el comando RESET.
	context: El contexto en el que se puede cambiar el parámetro (por ejemplo, postmaster, sighup, backend, superuser).

``` 




# Formas de cambiar parametros 
```sql
 
############ Asignar parámetros a una Base de datos  ############
\c postgres

-- Establecer statement_timeout a 10 segundos
ALTER DATABASE postgres SET statement_timeout = '10s';

-- Validar configuraciones
 SELECT d.datname, r.rolname, s.setconfig FROM pg_db_role_setting s LEFT JOIN pg_database d ON s.setdatabase = d.oid LEFT  JOIN pg_roles r ON s.setrole = r.oid;

--- Quitar parámetro 
ALTER DATABASE postgres RESET statement_timeout;



############ Asignar parámetros a una Base de datos y especificando el usuario ############
-- Establecer statement_timeout a 10 segundos
 ALTER ROLE angel IN DATABASE postgres SET statement_timeout = '5s';

-- Validar configuraciones
 SELECT d.datname, r.rolname, s.setconfig FROM pg_db_role_setting s LEFT JOIN pg_database d ON s.setdatabase = d.oid LEFT  JOIN pg_roles r ON s.setrole = r.oid;

--- Quitar parámetro 
 ALTER ROLE angel IN DATABASE postgres RESET statement_timeout ;
 
 
 
 
############  Asignar parámetros a nivel Usuario, Roles o Grupos  ############
-- Asignando un limite de work_mem  al usuario angel 
alter user angel SET work_mem = '4MB'; 

-- Validar las configuraciones 
select usename,useconfig from pg_shadow where usename = 'angel';

-- Quitar el parámetro
ALTER ROLE angel RESET work_mem;-- quitarlo 




############  Asignar parámetros a nivel Sesion/Transaccion ############ 
-- Cambiar el nivel de mensajes del cliente a 'log' para la sesión actual
SET client_min_messages TO 'log';

--  Cambiar el nivel de mensajes del cliente a 'log'y Al colocar "LOCAL" solo es para la transacción actual
BEGIN;
SET LOCAL client_min_messages TO 'log';
-- Aquí irían tus operaciones SQL
COMMIT;
 

### Usando `pg_catalog.set_config`
-- Cambiar el nivel de mensajes del cliente a 'log' para la sesión actual
SELECT pg_catalog.set_config('client_min_messages', 'log', false);

-- Cambiar el nivel de mensajes del cliente a 'log' solo para la transacción actual
BEGIN;
PERFORM pg_catalog.set_config('client_min_messages', 'log', true);
-- Aquí irían tus operaciones SQL
COMMIT;



############  Asignar parámetros una tabla  ############
-- Asignarle parametros de vacum para el ejemplo 
ALTER TABLE tabla_ejemplo_autovacuum SET (
    autovacuum_vacuum_insert_scale_factor = 0.05,
    autovacuum_vacuum_insert_threshold = 200
);

-- Validar las configuraciones 
SELECT c.relname AS table_name,o.option_name,o.option_value FROM pg_class c JOIN  pg_namespace n ON n.oid = c.relnamespace JOIN pg_options_to_table(c.reloptions) o ON true WHERE
c.relname = 'tabla_ejemplo_autovacuum';

-- Quitar el parámetro
ALTER TABLE tabla_ejemplo_autovacuum RESET (
    autovacuum_vacuum_insert_scale_factor ,
    autovacuum_vacuum_insert_threshold 
);

############  Asignar parámetros una Funcion  ############
 -- Asignarle parametros al crear la funcion  
CREATE OR REPLACE FUNCTION mi_funcion()
RETURNS void AS $$
BEGIN
    -- Lógica de la función
END;
$$ LANGUAGE plpgsql
SET work_mem = '64MB'; 

-- tambien puede agregarle  parametros una vez creada la func
alter FUNCTION mi_funcion() SET work_mem = '64MB';

-- Validar las configuraciones 
select proname,proconfig from pg_proc where proname = 'mi_funcion';

-- Quitar el parámetro
alter FUNCTION mi_funcion() RESET work_mem;

```

# En el contexto del versionado  
```
1. **Versión mayor (Major)**: El primer número (X) indica cambios importantes que pueden no ser compatibles con versiones anteriores. Ejemplo: 1.0.0, 2.0.0.

2. **Versión menor (Minor)**: El segundo número (Y) indica la adición de nuevas funcionalidades que son compatibles con versiones anteriores. Ejemplo: 1.1.0, 1.2.0.

3. **Revisión o parche (Patch)**: El tercer número (Z) indica correcciones de errores y mejoras menores que no afectan la compatibilidad. Ejemplo: 1.1.1,  

En tu ejemplo de versión '10.20', el '10' sería la versión mayor y el '20' sería la versión menor. Si hubiera un tercer número, como en '10.20.1', ese sería el parche.
 ```


### Configuraciones de parametros en objetos 
```
ALTER DATABASE test_query SET maintenance_work_mem = '256MB';


SELECT
    d.datname AS database_name,
    r.rolname AS role_name,
    s.setconfig AS settings
FROM
    pg_db_role_setting s
LEFT  JOIN
    pg_database d ON s.setdatabase = d.oid
LEFT JOIN
    pg_roles r ON s.setrole = r.oid ;

 

ALTER TABLE ventas SET (
    autovacuum_enabled = true,
    autovacuum_vacuum_threshold = 50,
);

------- VER LAS TABLAS  QUE TIENEN PARÁMETROS 
SELECT c.relname AS table_name,o.option_name,o.option_value FROM pg_class c JOIN  pg_namespace n ON n.oid = c.relnamespace JOIN pg_options_to_table(c.reloptions) o ON true;



CREATE OR REPLACE FUNCTION mi_funcion()
RETURNS void AS $$
BEGIN
    -- Lógica de la función
END;
$$ LANGUAGE plpgsql
SET work_mem = '64MB'
SET statement_timeout = '5min';


------- VER LAS FUNCIONES QUE TIENEN PARÁMETROS 
SELECT nspname, proname, proargtypes, prosecdef as "SECURITY DEFINER", p.proleakproof as "LEAKPROOF" , rolname as "OWNER", proconfig AS "PARAMETERS SETTING" FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
JOIN pg_authid a ON a.oid = p.proowner 
WHERE    proconfig IS NOT NULL  ;
 

```

## archivos   conf
```sql
postgresql.conf
postgresql.auto.conf

``` 

> [!IMPORTANT]
> lOS PARAMETROS QUE ESTAN COMENTADOS CON '#' EL VALOR QUE TIENEN ES EL QUE SE CARGA POR DEFAULT, SI QUIERES QUE TENGA OTRO VALOR DIFERENTE AL DAFAUL SOLO DESCOMENTA Y COLOCA EL NUEVO VALOR


 
## FILE LOCATIONS
 
```sql

data_directory = '/data'
otras rutas del data :
DATA: /var/lib/pgsql/16/data
BINARIOS: /usr/local/pgsql/bin/
BINARIOS: /usr/pgsql/bin/

-- Socket unix
/var/run/postgresql/ o /tmp/

hba_file = '/config/pg_hba.conf'
ident_file = '/config/pg_ident.conf'

```



## # CONNECTIONS AND AUTHENTICATION 


```sql

 listen_addresses = '*'  ## enable all other computers to connect 
 port = 5432

max_connections = 1000


superuser_reserved_connections = 3  # (change requires restart) Reserva de Conexiones: El valor de superuser_reserved_connections especifica cuántas de las conexiones totales (definidas por max_connections) están reservadas para los superusuarios. Por ejemplo, si max_connections está establecido en 100 y superuser_reserved_connections en 3, entonces 97 conexiones estarán disponibles para todos los usuarios, mientras que 3 conexiones estarán reservadas exclusivamente para superusuarios. Esto garantiza que los superusuarios siempre puedan conectarse a la base de datos incluso cuando el número máximo de conexiones permitidas 



unix_socket_directories =  '/var/run/postgresql/'  # POR DEFAULT POSTGRESQL CREA ETOS ARCHIVOS EN LA TMP Y EN /RUN/POSTGRESQL	

/*
Archivo: s.pgsql.5432
-- Propósito  --
Comunicación Local: Permite que las aplicaciones locales se conecten a PostgreSQL sin necesidad de utilizar una conexión de red TCP/IP.  son generalmente más seguras y rápidas que las conexiones TCP/IP para aplicaciones locales
Ubicación:  /var/run/postgresql/ o /tmp/
Nombre :  archivo de socket incluye el puerto en el que está corriendo PostgreSQL

Archivo: s.pgsql.5432.lock
Ubicación:  /var/run/postgresql/ o /tmp/
Contenido: PID,  directorio del data,  puerto ,  directorio de sockets. 
-- Propósito  --
tilizado por PostgreSQL para gestionar el control de acceso y asegurar que no haya múltiples instancias del servidor PostgreSQL intentando utilizar el mismo puerto al mismo tiempo.
*/




unix_socket_permissions = 0777		# begin with 0 to use octal notation



  

- **`tcp_keepalives_idle`**: Define el tiempo de inactividad (en segundos) antes de que se envíe el primer mensaje keepalive. Útil para evitar desconexiones inesperadas en redes con periodos de baja actividad.
- **`tcp_keepalives_interval`**: Establece el intervalo entre paquetes keepalive después de que se haya enviado el primero. Es útil en entornos con conexiones intermitentes o redes con posibles caídas frecuentes.
- **`tcp_keepalives_count`**: Especifica cuántos paquetes keepalive deben fallar antes de que la conexión se cierre. Ideal para garantizar la estabilidad en conexiones remotas con latencias variables.
 
Si la red es **estable** y el usuario simplemente ejecutó una consulta (`SELECT version();`) sin cerrar la conexión, estos parámetros de **TCP keepalive** realmente **no tendrían impacto significativo** en el comportamiento de PostgreSQL.  

2. **Los parámetros `tcp_keepalives_*` solo detectan conexiones caídas**  
   - Keepalive **no es un mecanismo para cerrar conexiones inactivas**, sino para detectar si el otro extremo sigue respondiendo.
   - Si la red es estable y el cliente sigue ahí, estos parámetros no intervienen porque no hay fallos de conectividad que detectar.

3. **¿Cuándo sí serían útiles?**  
   - Si la conexión estuviera en riesgo de **desconectarse por problemas de red**, estos parámetros podrían ayudar a mantener la sesión activa.
   - También son útiles en **conexiones remotas o inestables**, donde puede haber cortes sin que PostgreSQL lo detecte inmediatamente y los cierra.
 

```


# - Authentication -


```

authentication_timeout = 3min # 1s-600s Cantidad máxima de tiempo permitido para completar la autenticación del cliente. Si un posible cliente no ha completado el protocolo de autenticación en este tiempo, el servidor cierra la conexión. Esto evita que los clientes colgados ocupen una conexión indefinidamente

password_encryption = scram-sha-256	# scram-sha-256 or md5 # cambia el metodo crifrado de contraseñas de los usuarios

scram_iterations = 10000 # hace que la autenticación sea más lenta., pero en un escenario donde se expusieron las contraseñas de los usuarios login, Esto significa que los atacantes necesitarían mucho más tiempo y recursos computacionales para descifrar las contraseñas de los usuarios, lo que reduce en gran medida la probabilidad de éxito de un ataque


client_connection_check_interval = 10
**Escenario crítico donde se debe usar client_connection_check_interval:**
Imagina una aplicación en la que la disponibilidad y la confiabilidad son críticas. una conexión persistente
con la base de datos PostgreSQL para operar. Es esencial que la aplicación detecte y maneje rápidamente las
desconexiones o fallas en las conexiones con la base de datos para evitar pérdidas de datos o interrupciones
 del servicio. Esto asegura que el servidor PostgreSQL verifique regularmente el estado de las conexiones de
 los clientes y tome medidas rápidas si se detecta una desconexión o fallo. 

**Escenario donde no es necesario usar client_connection_check_interval:**
En entornos donde la aplicación no requiere una conexión persistente con la base de datos o donde las desconexiones
 de los clientes no representan un riesgo crítico para la integridad de los datos o la disponibilidad del servicio


```





## RESOURCE USAGE (except WAL)

```
PostgreSQL usa memoria compartida para shared_buffers, por lo que debes asegurarte que los valores del kernel lo permitan.
###  Tamaños maximos y minimos en    bytes
cat /proc/sys/kernel/shmmax
cat /proc/sys/kernel/shmall

shared_buffers = 128MB  /* -- 25% a 40% de la RAM total si el servidor es dedicado a PostgreSQL. Nunca más del 50% para evitar que el sistema operativo se quede sin memoria.
Es el parámetro que define cuánta memoria RAM PostgreSQL usará para almacenar páginas de datos en memoria antes de acceder al disco. Es uno de los más importantes para el rendimiento.
https://www.postgresql.org/docs/9.1/runtime-config-resource.html
En versiones de PostgreSQL anteriores a 8.4, el valor máximo debe ser 2,5 GB,



--- Ver la memoria RAM 
free -m 

Ver cantidad de procesadores 
cat /proc/cpuinfo
*/

temp_buffers = 10MB # Estos son buffers locales de sesión que se usan solo para acceder a tablas temporales.  https://www.postgresql.org/docs/current/runtime-config-resource.html

max_prepared_transactions = 0 -- en caos de que requiera transacciones en paralelo habilitarlo

work_mem = 4MB  /*es un parámetro de configuración de PostgreSQL que especifica la cantidad de memoria que utilizarán las operaciones de ordenación internas  ORDER BY, DISTINCT, subconsultas IN y JOINS y las tablas hash antes de escribir en archivos de disco temporales, En un servidor dedicado podemos usar un 2-4% del total de nuestra memoria si tenemos solamente unas pocas sesiones (clientes) grandes. Como valor inicial podemos usar 8 Mbytes e ir aumentando progresivamente hasta tener un buen equilibrio entre uso de memoria y generación de temp files link : https://dbasinapuros.com/como-saber-si-esta-bien-ajustado-el-parametro-work_mem-de-postgresql/
otros dicen que tambien se calcula  Total RAM * 0.25 / max_connections */

maintenance_work_mem = 16MB  /*Usada en operaciones del tipo VACUUM, ANALYZE, CREATE INDEX, ALTER TABLE, ADD FOREIGN KEY. Su valor dependerá mucho del tamaño de nuestras bases de datos. Por ejemplo, en un servidor con Gbytes de memoria, podemos usar 256MB como valor inicial. La fórmula es 1/16 de nuestra memoria RAM. link: https://docs.aws.amazon.com/es_es/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum.html*/
/*  para los hosts grandes, defina el parámetro maintenance_work_mem en un valor comprendido entre uno y dos gigabytes, Para los hosts extremadamente grandes, defina el parámetro en un valor comprendido entre dos y cuatro gigabytes  , este parámetro depende de la carga de trabajo. */

autovacuum_work_mem = -1   El valor predeterminado es -1, lo que indica que se debe utilizar el valor de mantenimiento_work_mem en su lugar.

#shared_memory_type = mmap		# the default is the first option
# dynamic_shared_memory_type = posix # the default 



#min_dynamic_shared_memory = 0MB	# (change requires restart)

#temp_file_limit = -1

# - Cost-Based Vacuum Delay -

vacuum_cost_delay = 100			# 0-100 milliseconds (0 disables)
#vacuum_cost_page_hit = 1		# 0-10000 credits
#vacuum_cost_page_miss = 2		# 0-10000 credits
#vacuum_cost_page_dirty = 20		# 0-10000 credits
vacuum_cost_limit = 2000		# 1-10000 credits

# - Background Writer -

#bgwriter_delay = 200ms			# 10-10000ms between rounds
#bgwriter_lru_maxpages = 100		# max buffers written/round, 0 disables
#bgwriter_lru_multiplier = 2.0		# 0-10.0 multiplier on buffers scanned/round
#bgwriter_flush_after = 0		# measured in pages, 0 disables

effective_io_concurrency = 100		# 1-1000; 0 disables prefetching



# Esta configuracion se tomo de un servidor dedicado con un cpu que tiene 16 hilos 
max_worker_processes = 14		# (change requires restart) se recomienda usar el total de hilos menos 1 o 2  para reservar procesos del sistema esto en caso de que el servidor sea dedicado a base de datos  , 
max_parallel_workers = 14		#  se recomienda colocar igual o 3/4 del parámetro max_worker_processes 
max_parallel_workers_per_gather = 8	#  se recomienda colocar 1/2 de parámetro max_parallel_workers
max_parallel_maintenance_workers = 4    # se recomienda colocar  1/2  de max_parallel_workers_per_gather


******** Ejemplo ******** 
 reduce el tiempo de ejecución , Imagina que tienes una tabla muy grande y quieres buscar todas las filas que cumplen con una condición específica.
 En lugar de que un solo proceso lea toda la tabla, PostgreSQL puede dividir esta tarea entre varios
procesos de trabajo. Cada proceso lee una parte de la tabla y busca las filas que cumplen con la condición.
 Luego, el proceso principal reúne todos los resultados parciales y los presenta como un único conjunto de resultados.

 
1. **`max_worker_processes`**: Este parámetro establece el número máximo de procesos de trabajo en
segundo plano que el sistema puede soportar.  Incluye todos los tipos de procesos de trabajo,
 no solo los paralelos. Esto abarca procesos de replicación, procesos de mantenimiento y cualquier
 otro proceso en segundo plano que PostgreSQL pueda necesitar.

2. **`max_parallel_workers`**: debe ser menor o igual al valor de max_worker_processes y
Este parámetro define el número total de trabajadores paralelos que el sistema puede usar en
cualquier momento.

3. **`max_parallel_workers_per_gather`**: Define el número máximo de trabajadores paralelos
que se pueden usar para una sola Consulta/operación . Está limitado por el valor
de `max_parallel_workers`.

4. **`max_parallel_maintenance_workers`**: Establece el número máximo de trabajadores paralelos
que se pueden usar para operaciones de mantenimiento, como la creación de índices. También está
limitado por `max_parallel_workers`


```





# WRITE-AHEAD LOG


```sql



# Para elegir este metodo utiliza el siguiente comando colocando la ruta donde se guardan los logs "pg_test_fsync -f /var/lib/postgresql/data/test.out -s 10"
#wal_sync_method = fsync                # the default is the first option
                                        # supported by the operating system:
                                        #   open_datasync
                                        #   fdatasync (default on Linux and FreeBSD)
                                        #   fsync
                                        #   fsync_writethrough
                                        #   open_sync


max_wal_size = 2GB  # Tamaño máximo de WAL antes de forzar checkpoint.
min_wal_size = 1GB


checkpoint_timeout = 20min		# aseguran que los datos en memoria se escriban en disco
checkpoint_completion_target = 0.9
checkpoint_flush_after = 256kB		# measured in pages, 0 disables
checkpoint_warning = 30s		# 0 disables




effective_cache_size = 4GB  /*Cuando PostgreSQL planea cómo ejecutar una consulta, necesita estimar cuanto de la data necesaria ya está almacenada en caché y cuánta tendrá que leer desde el disco. Esta estimación afecta significativamente la eficiencia de la ejecución de la consulta.
En un servidor dedicado podemos empezar con un 50% del total  e nuestra memoria. Como máximo  unos 75% del total. Por ejemplo, en un servidor con 4Gbytes de memoria, podemos usar 2048MB como valor inicial. effective_cache_size = 2048MB*/

checkpoint_segments = 3		/*# in logfile segments, min 1, 16MB each Este parámetro es muy importante en bases de datos con numerosas operaciones de escritura (insert,update,delete). Para empezar podemos empezar con un valor de 64. En grandes bases de datos con muchos  bytes de datos escritos podemos aumentar este valor hasta 128-256. checkpoint_segments = 64*/


 
wal_buffers = 16MB  --  define la cantidad de memoria dedicada a almacenar los registros de WAL antes de que sean escritos a disco. Configurar adecuadamente este parámetro puede mejorar significativamente el rendimiento de bases de datos con altas tasas de escritura al reducir la frecuencia de escritura de los registros WAL a disco. Al ajustar wal_buffers, es importante considerar la carga de trabajo, la memoria disponible y realizar pruebas para encontrar el valor óptimo para tu sistema.


```

# REPLICATION
```
# hot_standby = on

```

# QUERY TUNING
```

```

## Configurar los datos que guarda en el LOG

```sql

# DOC OFICIAL:  https://www.postgresql.org/docs/current/runtime-config-logging.html

log_destination = 'stderr' # Esto genera
logging_collector = on # esto habilita el log 

log_directory = '/sysx/pg_log' #  Directorio donde se va guardar el log 
log_filename = 'postgresql-%y%m%d.log'
log_file_mode = 0600

log_rotation_age = 1d
log_rotation_size = 0  # 0 disables.
log_truncate_on_rotation = ON  # Este elimina el log si ya existe

log_min_messages = info  ## si quieres que capture muchas cosas coloca info , pero lo recomendado para empresas es colocar warning para que guarde solo cosas importantes,  , el nivel de detalle esta en orden, por ejemplo el debug5 muestra mucha información de mas,no recomendado , PANIC muestra bien poca información 

se organizan de menor a mayor prioridad. Aquí está la jerarquía y Cada nivel incluye todos los niveles que le siguen.
 Cuanto más alto sea el nivel, menos mensajes se enviarán al registro.
	DEBUG5: El nivel más bajo, utilizado para mensajes de depuración detallados.
	DEBUG4: Mensajes de depuración de nivel 4.
	DEBUG3: Mensajes de depuración de nivel 3.
	DEBUG2: Mensajes de depuración de nivel 2.
	DEBUG1: Mensajes de depuración de nivel 1.
	INFO: Mensajes informativos.
	NOTICE: Mensajes de advertencia o información importante.
	WARNING: Advertencias que no son errores críticos.
	ERROR: Errores que no abortan la transacción actual.
	LOG: Mensajes de registro (pueden incluir niveles anteriores).
	FATAL: Errores fatales que abortan la transacción.
	PANIC: El nivel más alto, utilizado para errores graves que requieren una acción inmediata.


log_min_error_statement = info


log_min_duration_statement = 0 #  0 captura todo, -1 lo desabilita y no guarda consultas en duración, se configura en milisegundo ejmplo 1000 = 1sg y sirve para decirle que guarde en el log las consultas que tarden >= que el tiempo que le especificamos, en este caso le decimos que capture todo


#log_autovacuum_min_duration = 0 #-1 disables 

#log_checkpoints = on
log_connections = on
log_disconnections = on
log_duration = on

log_hostname = off --
cuando un cliente se conecta a la base de datos, PostgreSQL intenta determinar el nombre del host asociado con la dirección IP del cliente. Esto se hace para registrar el nombre del host en los registros de conexión.
Sin embargo, esta resolución de nombres de host puede tener un impacto en el rendimiento. Si tu configuración de resolución de nombres de host es lenta o ineficiente, podría afectar negativamente el tiempo necesario para establecer una conexión. Por lo tanto, es importante considerar cómo está configurada la resolución de nombres de host en tu entorno.
En resumen, si tienes una configuración de resolución de nombres de host que es rápida y eficiente, no debería haber un problema significativo. Pero si la resolución de nombres de host es lenta, podrías experimentar una penalización en el rendimiento al habilitar log_hostname.
La resolución de nombres de host generalmente recae en el sistema operativo o en los servidores DNS (Domain Name System). Cuando un cliente intenta conectarse a un servidor, el sistema operativo o el servidor DNS se encarga de traducir el nombre del host (como “www.ejemplo.com”) en una dirección IP (como “192.168.1.1”). 


log_error_verbosity = verbose	
	- terse registra solo la información básica sobre el error.
	- default proporciona información adicional, como el contexto de la consulta actual.
	- verbose : [NO RECOMIENDO] La salida VERBOSE incluye el código de error SQLSTATE (consulte también el Apéndice A) y el nombre del archivo del código fuente, el nombre de la función y el 
          número de línea que generó el error.

log_line_prefix = '<%t %r %a %d %u %p %c %i>'
# special values:
# asi obtiene el parámetro %C el  session ID
SELECT to_hex(trunc(EXTRACT(EPOCH FROM backend_start))::integer) || '.' || to_hex(pid) FROM pg_stat_activity;
					#   %a = application name
					#   %u = user name
					#   %d = database name
					#   %r = remote host and port
					#   %h = remote host
					#   %p = process ID
					#   %t = timestamp without milliseconds
					#   %m = timestamp with milliseconds
					#   %n = timestamp with milliseconds (as a Unix epoch)
					#   %i = command tag
					#   %e = SQL state
					#   %c = session ID
					#   %l = session line number
					#   %s = session start timestamp
					#   %v = virtual transaction ID
					#   %x = transaction ID (0 if none)
					#   %q = stop here in non-session
					#        processes
					#   %% = '%'
					# e.g. '<%u%%%d> '

log_lock_waits = on #   cuando una consulta intenta escribir en una fila mientras otra consulta está leyendo o escribiendo en la misma fila. Cuando una consulta está esperando a que se libere un recurso bloqueado por otra consulta, se dice que está esperando un bloqueo. El parámetro log_lock_waits en postgresql.conf permite registrar información sobre estas situaciones, lo que puede ayudar en el diagnóstico y resolución de problemas de rendimiento.

log_statement = 'all'
	/*********** Otras opciones *************
	none: No se registra ninguna consulta.
	ddl: Solo se registran las consultas de definición de datos (DDL), como CREATE, ALTER, DROP, etc.
	mod: Solo se registran las consultas de modificación de datos (DML), como INSERT, UPDATE, DELETE, etc.
	all: Se registran todas las consultas, tanto DDL como DML.*/

log_temp_files = 0  # controla si se debe registrar información sobre la creación y eliminación de archivos temporales en PostgreSQL. |  -1 disables, 0 logs all temp files | puede indicar falta de memoria de trabajo (work_mem) o consultas mal optimizadas. temp_files: número de archivos temporales creados (por ejemplo, para ordenamientos grandes, operaciones con DISTINCT, GROUP BY, ORDER BY, etc.). temp_bytes: tamaño total de esos archivos.  tabla pg_stat_database 

log_timezone = 'America/mazatlan' # configura la hora del log

```



## Estadísticas de tiempo de ejecución 
```SQL
 track_activities = on: Imagina que tienes una base de datos PostgreSQL que utilizan múltiples usuarios para realizar consultas y transacciones. Al activar este parámetro, la base de datos registrará qué consultas se están ejecutando, quién las está ejecutando y cuánto tiempo están tardando. Esto te ayuda a monitorear la actividad en tiempo real y a detectar problemas de rendimiento o posibles actividades sospechosas.

 track_activity_query_size = 2048: Este parámetro te permite limitar la cantidad en bytes que se registran sobre cada consulta. Por ejemplo, si tienes una query muy largas, en el log no se va ver completa ya parecera recortada, o puedes aumentar este parametros a un valor como 10000 para que se guarde toda la query completa y no recorte las query con muchos caracteres

stats_temp_directory = 'pg_stat_tmp'

 track_counts = on: ¿Quieres saber cuántas filas están siendo afectadas por tus consultas de inserción, actualización o eliminación? Al activar este parámetro, PostgreSQL registrará automáticamente el número de filas afectadas por cada tipo de comando, lo que te proporciona información valiosa sobre el rendimiento de tu base de datos y la eficacia de tus operaciones de manipulación de datos.

 track_io_timing = off: Si estás preocupado por el rendimiento de las operaciones de lectura y escritura en tu base de datos, puedes activar este parámetro para que PostgreSQL registre el tiempo que tarda en realizar operaciones de entrada/salida en el disco. Esto te ayuda a identificar cuellos de botella de E/S y a optimizar el rendimiento de tu sistema de almacenamiento. esto nos permite visualizar los valores en las columnas blk_read_time y blk_write_time en la tabla pg_stat_database

 track_wal_io_timing = off: Similar al parámetro anterior, pero específico para el registro de escritura de registros de WAL. Al activarlo, PostgreSQL registrará el tiempo que tarda en escribir los registros de WAL en disco, lo que te permite evaluar el rendimiento de la escritura de registros y optimizar la configuración de tu sistema de registro.

 track_functions = 'all' :  # none, pl, all Si tienes funciones almacenadas (procedimientos almacenados) en tu base de datos, puedes usar este parámetro para controlar si deseas rastrear las llamadas a estas funciones. Puedes elegir entre no rastrear ninguna función, rastrear solo las funciones escritas en PL/pgSQL o rastrear todas las funciones, según tus necesidades de monitoreo y análisis.

stats_fetch_consistency = cache:  # cache, none, snapshotEste parámetro te permite controlar la consistencia de las estadísticas que PostgreSQL recupera de la base de datos. Por ejemplo, puedes configurarlo para utilizar estadísticas en caché para consultas de rendimiento rápidas o una instantánea actualizada de las estadísticas para análisis más precisos. Esto te ayuda a equilibrar el rendimiento y la precisión al realizar consultas de estadísticas.


```


## Mantenimientos 
```sql

 autovacuum = on: Este parámetro controla si PostgreSQL debe ejecutar automáticamente el proceso de vaciado de tablas (autovacuum). Cuando está activado (on), PostgreSQL monitorea el nivel de actividad en las tablas y ejecuta el vaciado automáticamente según sea necesario para prevenir la fragmentación y optimizar el rendimiento de la base de datos.

 autovacuum_max_workers = 3: # Puedes asignar 1 worker por cada 3 o 4 núcleos, Determina el número máximo de procesos autovacuum que pueden ejecutarse simultáneamente. Esto controla la cantidad de recursos del sistema que se asignan al vaciado automático de tablas. Ajustar este valor te permite equilibrar la carga del sistema con la necesidad de mantener las tablas limpias y optimizadas.
    - **Explicación**: Si tienes muchas tablas grandes, aumentar este número puede ayudar a mantenerlas optimizadas.

 autovacuum_naptime = 1min: Define cuánto tiempo debe esperar el autovacuum antes de volver a ejecutar una nueva ronda de limpieza y análisis.
  - **Explicación**: Cada minuto, PostgreSQL revisará si alguna tabla necesita ser limpiada o analizada.

  autovacuum_vacuum_threshold = 10000: Este valor indica el número mínimo de tuplas que deben haber cambiado en una tabla antes de que PostgreSQL ejecute el vaciado automático en ella. Si el número de tuplas cambiadas desde el último vaciado es inferior a este umbral, el vaciado automático no se ejecutará en esa tabla. Ajustar este valor te permite controlar cuándo se activa el proceso de vaciado automático en función de la actividad en la tabla.
   - **Explicación**: Si al menos 50 filas han sido modificadas, PostgreSQL ejecutará `VACUUM` para limpiar la tabla.

  autovacuum_vacuum_insert_threshold = 1000: Similar al parámetro anterior, pero específico para la inserción de nuevas tuplas en una tabla. Este valor controla cuántas tuplas nuevas deben agregarse antes de que PostgreSQL ejecute el vaciado automático en la tabla. Ajustar este valor te permite controlar cuándo se activa el vaciado automático en función de la cantidad de inserciones en la tabla.

  autovacuum_analyze_threshold = 5000: Determina el número mínimo de tuplas que deben haber cambiado en una tabla antes de que PostgreSQL ejecute el proceso de análisis automático en ella. El análisis automático actualiza las estadísticas de la tabla, lo que ayuda al planificador de consultas a tomar decisiones más eficientes. Ajustar este valor te permite controlar cuándo se activa el proceso de análisis automático en función de la actividad en la tabla.
   - **Explicación**: Si al menos 50 filas han sido modificadas, PostgreSQL ejecutará `ANALYZE` para actualizar las estadísticas de la tabla.

  autovacuum_vacuum_scale_factor = 0.4: Este factor se utiliza para determinar el tamaño de la tabla en relación con el umbral de vaciado antes de que se ejecute el vaciado automático. Por ejemplo, si el umbral de vaciado es 100 y el factor de escala es 0.2, el vaciado automático se activará cuando el tamaño de la tabla sea al menos el 20% del umbral. Ajustar este valor te permite adaptar el comportamiento de vaciado automático a las características específicas de tus tablas.,Fracción del número total de tuplas en la tabla que, cuando se modifica o elimina, desencadena un VACUUM. En este caso, es 0.2 (20%).
    - **Explicación**: Si tienes una tabla con 1000 filas, y este parámetro es 0.2, PostgreSQL ejecutará `VACUUM` después de que se modifiquen 250 filas (50 + 0.2 * 1000).

 autovacuum_vacuum_insert_scale_factor = 0.4: Especifica una fracción del tamaño de la tabla que se debe agregar autovacuum_vacuum_insert_thresholdal decidir si se activará un VACUUM.
  - **Explicación**: ( autovacuum_vacuum_insert_thresholdal + ( autovacuum_vacuum_insert_scale_factor * autovacuum_vacuum_insert_thresholdal  ) ) = 1000 + ( 0.4 * 1000 ) = 1,400


 autovacuum_analyze_scale_factor = 0.2: Similar a los parámetros anteriores, pero específico para el número de cambios en una tabla en relación con el umbral de análisis antes de que se ejecute el análisis automático. Ajustar este valor te permite controlar cuándo se activa el análisis automático en función de la actividad en la tabla. Fracción del número total de tuplas en la tabla que, cuando se modifica o elimina, desencadena un ANALYZE. En este caso, es 0.1 (10%).
  - **Explicación**: Si tienes una tabla con 1000 filas, y este parámetro es 0.1, PostgreSQL ejecutará `ANALYZE` después de que se modifiquen 150 filas (50 + 0.1 * 1000).

  autovacuum_freeze_max_age = 200000000: Este parámetro controla la edad máxima en transacciones antes de que se realice un vaciado automático de congelación de tuplas. Las tuplas congeladas son aquellas que han sido marcadas como inmutables y no cambian. Ajustar este valor te permite controlar cuándo se ejecuta el vaciado automático de congelación para evitar la acumulación de datos obsoletos en la base de datos.

 autovacuum_multixact_freeze_max_age = 400000000: Similar al parámetro anterior, pero específico para la edad máxima en transacciones para la congelación de multixactos. Los multixactos son conjuntos de transacciones que modifican las mismas tuplas. Ajustar este valor te permite controlar cuándo se ejecuta el vaciado automático de congelación de multixactos para evitar la acumulación de datos obsoletos en la base de datos.

  autovacuum_vacuum_cost_delay = -1 : Este parámetro controla cuánto tiempo PostgreSQL espera entre cada paso del vaciado automático. Un valor más alto reduce la carga en el sistema, pero ralentiza el proceso de vaciado automático, mientras que un valor más bajo acelera el vaciado automático pero aumenta la carga en el sistema.

  autovacuum_vacuum_cost_limit = -1: Este parámetro controla el costo máximo que PostgreSQL está dispuesto a gastar en el vaciado automático. Un valor negativo significa que no hay límite en el costo del vaciado automático. Ajustar este valor te permite controlar cuántos recursos del sistema se asignan al vaciado automático en función de las necesidades y la capacidad de tu sistema.

Función autovacuum_vacuum_cost_limit Y autovacuum_vacuum_cost_delay: Durante la ejecución de un VACUUM,
PostgreSQL acumula un “costo” basado en las operaciones realizadas. Cuando este costo acumulado supera
el límite definido por autovacuum_vacuum_cost_limit, el proceso de autovacuum se suspende por el tiempo
especificado en autovacuum_vacuum_cost_delay antes de continuar. Esto ayuda a distribuir la carga del
VACUUM a lo largo del tiempo, reduciendo el impacto en el rendimiento del sistema

   **Ejemplo**:
   - Si tienes una tabla con 10,000 tuplas:
     - `autovacuum_vacuum_threshold` = 50
     - `autovacuum_vacuum_scale_factor` = 0.2
     - **Cálculo**: 50 + (0.2 * 50) = 50 + 10 = 60
     - **Resultado**: El VACUUM se ejecutará cuando se hayan modificado o eliminado al menos 60 tuplas.
 
   **Ejemplo**:
   - Si tienes una tabla con 10,000 tuplas:
     - `autovacuum_analyze_threshold` = 50
     - `autovacuum_analyze_scale_factor` = 0.1
     - **Cálculo**: 50 + (0.1 * 50) = 50 + 5 = 55
     - **Resultado**: El ANALYZE se ejecutará cuando se hayan modificado o eliminado al menos 55  tuplas.

 
   **Ejemplo**:
   - Si tienes una tabla con 10,000 tuplas:
     - `autovacuum_vacuum_insert_threshold` = 200
     - `autovacuum_vacuum_insert_scale_factor` = 0.05
     - **Cálculo**: 200 + (0.05 * 200) = 200 + 10 = 210
     - **Resultado**: El VACUUM se ejecutará cuando se hayan insertado al menos 210 tuplas.

--- https://www.postgresql.org/docs/current/runtime-config-autovacuum.html








############# también estan estos parámetros que son de mantenimientos pero se encuentran en otras categorías 
-------- categoria:  RESOURCE USAGE (except WAL)  --------

maintenance_io_concurrency
maintenance_work_mem
autovacuum_work_mem
max_parallel_maintenance_workers
vacuum_cost_delay 
vacuum_cost_page_hit
vacuum_cost_page_miss
vacuum_cost_page_dirty
vacuum_cost_limit

-------- categoria: REPORTING AND LOGGING --------
log_autovacuum_min_duration =
					
-------- categoria:  CLIENT CONNECTION DEFAULTS --------
| `vacuum_freeze_min_age` | Edad mínima para congelar una fila | 50,000,000 |
| `vacuum_freeze_table_age` | Edad de la tabla para iniciar congelación | 150,000,000 |
| `autovacuum_freeze_max_age` | Edad máxima antes de forzar autovacuum | 200,000,000 |


vacuum_failsafe_age  
vacuum_multixact_freeze_table_age  
vacuum_multixact_freeze_min_age  
vacuum_multixact_failsafe_age

-------- categoria: REPLICATION --------
vacuum_defer_cleanup_age  


```



## CLIENT CONNECTION DEFAULTS
```sql
default_transaction_isolation = 'read committed'

---------------- NIVELES DE AISLAMIENTO  ----------------
1. **Read Uncommitted (No Comprobado)**: segun esto permite lecturas sucias pero no es verdad, aunque pongas este valor
no tendra efectos, en realidad  estara red committed ; 

2. **Read Committed (Confirmado)**:
   - Es el nivel de aislamiento predeterminado en PostgreSQL.
   - Evita lecturas sucias, pero permite lecturas no repetibles y fantasma.
   - Escenario real: Adecuado para la mayoría de las aplicaciones donde la consistencia no es crítica.

3. **Repeatable Read (Lectura Repetible)**:
   - Evita lecturas sucias y no repetibles, pero permite lecturas fantasma.
   - Útil cuando la integridad de los datos es crucial.
   - Escenario real: Sistemas financieros o de inventario donde la coherencia es fundamental.

4. **Serializable (Serializable)**:
   - Ofrece el nivel más alto de aislamiento.
   - Evita lecturas no repetibles y fantasma.
   - Puede afectar el rendimiento debido a bloqueos más estrictos.
   - Escenario real: Transacciones críticas, como transferencias bancarias o reservas de asientos.



# por seguridad desabilitarlo, no es bueno mostrar errores a los clienes, Este es lo que le va mostrar al cliente al momento que pase algun error, puedes controlas que le vas a mostrar   
client_min_messages = warning		# valores en orden de detalle:
					#   debug5
					#   debug4
					#   debug3
					#   debug2
					#   debug1
					#   log
					#   notice (Default)
					#   warning
					#   error (por seguridad colocar este si el cliente puede ver los errores)


#row_security = on  # activa el , Row-Level Security (RLS) permite definir políticas de seguridad a nivel de fila para controlar el acceso a datos específicos según el usuario o el rol.  
#search_path = '"$user", public'  # esto le indica a en que esquema buscar el objeto , en caso de que no se especifique en la query

#######  parametros importantes ######
deadlock_timeout = '2s';   		 #  este determina cuanto tiempo puede esperar un deadlock para que sea cancelado uno de las dos tracciones 
statement_timeout = 0			# in milliseconds, 0 is disabled -- Este parámetro controla cuánto tiempo puede ejecutarse una consulta antes de que se cancele automáticamente.
lock_timeout = 0			# in milliseconds, 0 is disabled -- Determina cuánto tiempo una transacción debe esperar para tener acceso a un objeto  bloqueado antes de ser cancelada automáticamente 
idle_in_transaction_session_timeout = 0	# in milliseconds, 0 is disabled -- controla cuánto tiempo una "idle in transaction" puede permanecer inactiva antes de ser terminada automáticamente.
idle_session_timeout = 0  		# in milliseconds, 0 is disabled -- esto controla el tiempo máximo de un cliente puede estar inactivo, despues de eso lo desconecta.


client_encoding = 'UTF8'	 # establece la codificación (conjunto de caracteres) que se utiliza para la comunicación entre el cliente (como psql) y el servidor PostgreSQL	





datestyle = 'iso, ymd'  #  permite configura el formato de la  fecha, por defaul es "mdy"  = "mm-dd-yyyy", nosotros usamos ymd
intervalstyle = postgres # se utiliza para definir el formato de salida y la interpretación de los intervalos de tiempo. Este parámetro afecta cómo se muestran y se interpretan los intervalos en las consultas.

### Valores posibles de `IntervalStyle`

1. **`postgres`**:
   - Formato tradicional de PostgreSQL.
   - Ejemplo: `@ 1 day 2 hours`

2. **`postgres_verbose`**:
   - Formato detallado de PostgreSQL.
   - Ejemplo: `@ 1 day 2 hours 0 mins 0.00 secs`

3. **`sql_standard`**:
   - Formato estándar SQL.
   - Ejemplo: `1 02:00:00`

4. **`iso_8601`**:
   - Formato ISO 8601.
   - Ejemplo: `P1DT2H` (1 día y 2 horas)



------------------ Tiempo --------------- 
 SELECT * from pg_timezone_names;  --- ver las zonas que existen 
 SHOW TIMEZONE;
 SELECT CURRENT_TIMESTAMP;
	timezone = 'America/mazatlan'	 # postgresql.conf 


 --- Configurar en idioma ingles en_US.UTF-8 si quieres españo en_ES.UTF-8
	lc_messages = 'en_US.UTF-8' # locale for system error message
	lc_monetary = 'en_US.UTF-8' # locale for monetary formatting
	lc_numeric = 'en_US.UTF-8' # locale for number formatting
	lc_time = 'en_US.UTF-8' # locale for time formatting

-- select datname,datcollate,datctype from pg_database;
-- en linux puedes ver el idioma con el comando: locale

--- esto le indica a postgres como edbe de indezar y realizar busquedas de texto cumpletos (full text), asegurando que se apliquen las reglas de token y diccionario adecuadas 
default_text_search_config = 'pg_catalog.english'


------- Shared Library Preloading --------

#local_preload_libraries = ''
#session_preload_libraries = ''
shared_preload_libraries = 'pg_stat_statements'		# (change requires restart)


 
```
 


 # LOCK MANAGEMENT
```
#deadlock_timeout = 1s

max_locks_per_transaction = 128  # controla el número promedio de bloqueos de objetos (como tablas) que se pueden asignar por cada transacción

Ventajas:
	Mayor capacidad de bloqueos: Permite manejar transacciones más complejas que requieren múltiples bloqueos simultáneamente2
	Mejor rendimiento en cargas de trabajo intensivas: En entornos con muchas transacciones concurrentes, aumentar este valor puede mejorar el rendimiento al reducir la contención de bloqueos3

Desventajas:
	Uso de memoria: Aumentar este valor también incrementa el uso de memoria compartida, lo que puede llevar a problemas de memoria si no se configura adecuadamente4
	Riesgo de fragmentación: Un valor demasiado alto puede llevar a una fragmentación de la tabla de bloqueos, afectando el rendimiento5


Escenarios reales:
	Entorno de alta concurrencia: En un sistema con muchas transacciones concurrentes, como un sistema de reservas de vuelos, aumentar max_locks_per_transaction puede ayudar a manejar mejor la carga.
	Transacciones complejas: En aplicaciones que realizan transacciones complejas que involucran múltiples tablas y operaciones, un valor más alto puede prevenir errores de bloqueo.
	Crecimiento del sistema: A medida que tu base de datos crece y la cantidad de transacciones aumenta, puede ser necesario ajustar este valor para mantener el rendimiento.



```

# extras conf
```
standard_conforming_strings = on


# CONFIG FILE INCLUDES
# Este parámetro te permite incluir un archivo de configuración solo si existe en la ubicación especificada.
 Si el archivo no existe, PostgreSQL continuará sin errores. Por ejemplo:

include_if_exists = '/ruta/a/tu/archivo.conf'

```

 # Base de datos 
```
----- crear la extension --------
 create extension pg_stat_statements;
```
 
# inicializar y reinicios del servicio 



  ```sql
Comandos para aplicar reload : 
	pg_ctl reload -D /sysx/data16
	SELECT pg_reload_conf();

Querys para validar el ultimo reload : 
	select pg_postmaster_start_time()::timestamp AS uptime_psql ,pg_conf_load_time()::timestamp as last_time_reload;

Archivo : postgresql.conf 

	Escenario : 
		Se modifican dos parámetros en el archivo postgresql.conf uno correctamente y el otro se deja algo mal y se realiza un reload.
		
	Comportamiento: 
		postgresql realizara los cambios de los parametros que no marcan error y deja mensaje del cambio en el log, de los parametros que marcan error no aplica los cambios y deja mensaje en el log
	
	Mensaje de logs: 

		Señal recibida de reload: 
			<2025-03-03 15:50:08 MST     1346779 67aa5411.148cdb >LOG:  received SIGHUP, reloading configuration files

		Modificacion correcta : 
			<2025-03-03 15:42:09 MST     1346779 67aa5411.148cdb >LOG:  parameter "password_encryption" changed to "md5"

		Modificacion erronea : 
			<2025-03-03 15:48:21 MST     1346779 67aa5411.148cdb >LOG:  invalid value for parameter "max_connections": "100p"
			
		Mensaje final:
			<2025-03-03 14:42:48 MST     1346779 67aa5411.148cdb >LOG:  configuration file "/sysx/data14/postgresql.conf" contains errors; unaffected changes were applied

		Mensaje Alternativo:
			2025-04-08 16:33:39.259 MST  LOG:  configuration file "/sysx/data11/DATANEW/11/postgresql.conf" contains errors; no changes were applied

Archivo : pg_hba.conf
	Escenario : 
		Se modifican dos parámetros en el archivo ph_hba.conf uno correctamente y el otro se deja algo mal y se realiza un reload.
		
	Comportamiento:
		postgresql no aplica ningun cambio y deja mensaje en el log.
		
	Mensaje de logs:
	
		Señal recibida de reload: 
			<2025-03-03 15:50:08 MST     1346779 67aa5411.148cdb >LOG:  received SIGHUP, reloading configuration files

		Modificacion correcta : No deja  mensaje de cambios correctos. 

		Modificacion erronea : 
			<2025-03-03 15:42:09 MST     1346779 67aa5411.148cdb >CONTEXT:  line 93 of configuration file "/sysx/data14/pg_hba.conf"
			
		Mensaje final:
			<2025-03-03 14:46:30 MST     1346779 67aa5411.148cdb >LOG:  pg_hba.conf was not reloaded





# realizar reinicios
pg_ctl start -D $PGDATA
pg_ctl stop  -D $PGDATA
pg_ctl reload   -D $PGDATA
select pg_reload_conf();

pg_ctl restart   -D $PGDATA

# conectarse 
psql -p $PGPORT -U $PGUSER -d $PGDATABASE -c "select 1;"
   ```



# Modificar el postgresql.conf con query
   ```sql
select * from pg_settings;
select * from pg_config

show config_file;

#Ejemplo
show log_directory ;
alter system set log_directory TO '/path/to/log/'

   ```


## emp Files Separation
PostgreSQL uses temp files for the sorting operation in a query if allocated
work memory is not sufficient. By default, it creates temp files in the “pgsql_
tmp” directory under $PGDATA/base. However, you can create a tablespace
and use it for temp file operations. You can use the following steps.
en la pagina 23 -> viene esta información https://www.cherrycreekeducation.com/bbk/b/Apress_PostgreSQL_Configuration.pdf
 ```sql
postgres=# create tablespace for_temp_files location '/tmp';
CREATE TABLESPACE
postgres=#
postgres=# alter system set temp_tablespaces to '/tmp';
ALTER SYSTEM
postgres=#
postgres=# select pg_reload_conf();
Chapter 1 Best Ways to Install PostgreSQL
24
 pg_reload_conf
----------------
 t
(1 row)
postgres=# show temp_tablespaces ;
 temp_tablespaces
------------------
 "/tmp"
(1 row)
postgres=#

```

## Colocar un menu de ayuda en psql

El archivo psqlrc del usuario se encuentra o se puede crear en el directorio de inicio del usuario.<br>
nosotros creamos uno -> 
https://github.com/CR0NYM3X/POSTGRESQL/blob/main/.psqlrc

```
touch ~/.psqlrc

\set ON_ERROR_STOP on -- Si ocurre un error en cualquier parte del script, psql detiene la ejecución inmediatamente y sale con un código de estado no nulo 
\set ON_ERROR_STOP off  -- psql continúa ejecutando el script incluso si se produce un error.

%[%033[1;31m%]   Esto agrega color al texto. En este caso, 033[1;31m representa rojo.
%[%033[0m%]     restablece el color a la configuración predeterminada. 

%M: Nombre del servidor (por ejemplo, trident).
%n: Nombre del usuario (por ejemplo, john).
%/: Nombre de la base de datos actual (por ejemplo, orange).
%R: Número de puerto (por ejemplo, 5432).
%#: Símbolo => o -> según si es el prompt principal o secundario.
%# : '#' if superuser, '>' otherwise

%x: Indicador de transacción (por ejemplo, * si hay una transacción activa).
%m - host name of the db server, truncated at the first dot, or [local] (if over Unix socket)
%> - port where db server is listening
%~ - like %/ but the output is ~ if the database is the default

\set PROMPT1 '%[%033[1;31m%]%/%[%033[0m%]%[%033[1;32m%]%#%x%[%033[0m%] '
\set PROMPT1 ' %[%033[1;31m%]%n%[%033[0m%]%[%033[1;32m%]@%[%033[0m%]%[%033[1;31m%]%/%[%033[0m%]%#%x'
\set PROMPT2 ' %n@%/  %#%x'


PROMPT1: Es el prompt principal que se muestra cuando estás listo para ingresar una consulta.
PROMPT2:  Es el prompt secundario que aparece cuando tienes una consulta incompleta o necesitas continuar una línea.



--    In prompt1:
--         = normally
--         ^ if in single-line mode
--         ! if the session is disconnected from the database
--      In prompt2:
--         the sequence is replaced by -, *, a single quote, a double quote,
--         or a dollar sign, depending on whether psql expects more input
--         because the command wasn't terminated yet
-- %x : Transaction status:
--           an empty string when not in a transaction block,
--         * when in a transaction block
--         ! when in a failed transaction block,
--         ? when the transaction state is indeterminate (for example, because there is no connection).
-- %[...%] : terminal control characters



/* ANSI control sequences http://www.termsys.demon.co.uk/vtansi.htm
Display Attribute   FG / BG Color
0 Reset ALL         30 / 40 Black
1 Bright            31 / 41 Red
2 Dim               32 / 42 Green
4 Underscore        33 / 43 Yellow
5 Blink             34 / 44 Blue
7 Reverse           35 / 45 Magenta
8 Hidden            36 / 46 Cyan
                    37 / 47 White
                    39 / 49 Default
 



*/



para encontrar mas parametros para configurar el psqlrc puedes consultar las paginas 

https://gist.github.com/verfriemelt-dot-org/2e0136d62cbfeb7ce67f14b0731512b0#file-psqlrc-L35 
https://gist.github.com/segeljakt/d38ac5a3166131dd4b4ce8fc73da72f0 
https://gist.github.com/magat/9533c7043503912fc71bc099890e04fd
https://gist.github.com/begriffs/761c04e44b68b75c8d4886b97a1a34bd
https://gist.github.com/mateusmedeiros/134c58a37fc537305b17ae1f52755237
https://gist.github.com/gregorg/d079a56022f93c042231#file-psqlrc-L86
https://gist.github.com/whalesalad/5b25f2086c7a8c8e4728f3b948e0cd95
https://gist.github.com/jaytaylor/e5aa89c8f3aaab3f576f 

o aqui en la pagina 33 https://www.cherrycreekeducation.com/bbk/b/Apress_PostgreSQL_Configuration.pdf   



```



## Autenticaciones PG_HBA.conf PEER and IDENT
**`[NOTA]`** Solo sirve para el modo **local** no para el **host** 
1. **peer:** Con el método peer, PostgreSQL confía en la autenticación del sistema operativo local para verificar la identidad del cliente. Cuando un cliente se conecta al servidor desde el mismo equipo , PostgreSQL compara el nombre de usuario del cliente con el nombre de usuario del sistema operativo. Si hay una coincidencia, se permite la conexión sin solicitar una contraseña adicional.

2. **ident:** El método ident también depende del sistema operativo para verificar la identidad del cliente, pero en lugar de comparar el nombre de usuario de PostgreSQL con el del sistema operativo, ident realiza una consulta al demonio ident.conf del sistema operativo para obtener información sobre el usuario que intenta conectarse. Luego, PostgreSQL compara esta información con la configuración en el archivo pg_hba.conf. Si hay una coincidencia, se permite la conexión.

```sql

# "local" is for Unix domain socket connections only
local all all peer

For ident auth, pg_hba.conf entry looks like the following:
local db_clientes user_admin  ident map=my_ident_map
local db_clientes user_admin  peer map=my_ident_map # Este es en el caso por ejemplo que se cambio el nombre del usuario postgres

An $PGDATA/ident.conf file looks like the following:
# MAPNAME 	SYSTEM-USERNAME 	PG-USERNAME
  my_ident_map 	 my_os_user 		user_admin



Pagina 71 -> https://www.cherrycreekeducation.com/bbk/b/Apress_PostgreSQL_Configuration.pdf
```


## Configuracion de archivos   variables de entorno
```sql
archivos importantes :

ls -lhtra /home/postgres

.bash_profile # guardar las variables de entorno persistentes 
.psql_history # historial de comandos de postgresql 
.bash_history # historial de comandos de bash de linux


# bash_profile Ejemplo de variables de entorno , cambiar rutas 

LD_LIBRARY_PATH=/usr/pgsql-17/lib:$LD_LIBRARY_PATH
export PATH=/usr/pgsql-16/bin:$PATH

export PGPORT=5432
export PGDATA=/sysx/data
export pg_config=/usr/local/pgsql/bin/pg_config
export MANPATH=$MANPATH:/usr/local/pgsql/man
export PGDATABASE=postgres
export PGUSER=postgres
export PGLOG=/pglog
export LD_LIBRARY_PATH

https://www.postgresql.org/docs/11/libpq-envars.html
1. PGHOST: Especifica el nombre de host de la máquina donde se ejecuta el servidor de PostgreSQL.
2. PGPORT: Especifica el número de puerto en el que el servidor PostgreSQL está escuchando para las conexiones entrantes.
3. PGUSER: Especifica el nombre del usuario de PostgreSQL que se utilizará para conectarse al servidor.
4. PGPASSWORD: Utilizado para especificar la contraseña del usuario de PostgreSQL al conectar desde herramientas o scripts.
5. PGDATABASE: Especifica el nombre de la base de datos a la que se conectará el cliente.
6. PGCLIENTENCODING: Define la codificación de caracteres que se utilizará en las conexiones del cliente.
7. PGSERVICE: Utilizado para especificar el nombre de un servicio definido en el archivo pg_service.conf.
8. PGSSLMODE: Define si se deben usar conexiones SSL para cifrar la comunicación entre el cliente y el servidor.


/************ RECARGAR EL ARCHIVO SIN NECESIDAD DE CERRAR LA TERMINAL ***********\
source ~/.bash_profile
. ~/.bash_profile

******************************************************************
vim .vimrc

" Configurar colores para comentarios
highlight Comment ctermfg=blue
set ignorecase


******************************************************************
 
source ~/.bash_profile


# https://robotmoon.com/bash-prompt-generator/
export PS1="\[\e[38;5;196m\]\u\[\e[38;5;202m\]@\[\e[38;5;208m\]\h \[\e[38;5;220m\]\w \[\033[0m\]$ "

# Alternativas 
#PS1="\[\033[0;36m\]\u@\h:\w\$ \[\033[0m\]" #  Texto en cyan (azul claro) 
#PS1="\[\033[1;33m\]\u@\h:\w\$ \[\033[0m\]" #  Texto en amarillo brillante 
#PS1="\[\033[1;32;40m\]\u@\h:\w\$ \[\033[0m\]" #  Texto en verde con fondo negro 
#PS1="\[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \[\033[1;33m\]\$ \[\033[0m\]" #  Prompt con usuario@host en verde y ruta en azul, pero texto de entrada en amarillo
#PS1="\[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ \[\033[0;36m\]" #  `usuario@host` en **verde brillante**.   ruta` en **azul brillante* y El texto después del `$` será cyan (azul claro)
#PS1="\[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[38;5;11m\]\w\[\033[0m\] \$ \[\e[38;5;33m\] "

# https://www.postgresql.org/message-id/CAB7nPqRaacwcaANOYY3Hxd3T0No5RdZXyqM5HB6fta%2BCoDLOEg%40mail.gmail.com
# https://ascii.co.uk/art/elephant 
# https://emojicombos.com/elephant-ascii-art
# https://www.asciiart.eu/animals/elephants

# https://www.asciiart.eu/image-to-ascii 
# https://www.ascii-art-generator.org/es.html
# https://www.creativefabrica.com/es/tools/ascii-art-generator/


echo -e "\033[38;2;50;100;255m 
⠀⠀⠀⠀⠀⣠⣴⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠙⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠋⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣿⣶⣤⣄⣉⣉⠙⠛⠛⠛⠛⠛⠛⠋⣉⣉⣠⣤⣶⣿⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣄⡉⠛⠻⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠟⠛⢉⣠⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣿⣿⣿⣶⣶⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣶⣶⣿⣿⣿⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣶⣤⣈⡉⠛⠛⠻⠿⠿⠿⠿⠿⠿⠟⠛⠛⢉⣁⣤⣶⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣷⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠙⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠟⠋⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠛⠛⠛⠛⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀\033[0m"


# Slonik la mascota de PostgreSQL
cat<<'EOF'
  +------------------------+
  |   ____  ______  ___    |
  |  /    )/      \/   \   |
  | (     / __    _\    )  |
  |  \    (/ o)  ( o)   )  |
  |   \_  (_  )   \ )  /   |
  |     \  /\_/    \)_/    |
  |      \/  //|  |\\      |
  |          v |  | v      |
  |            \__/        |
  |  PostgreSQL            |
  +------------------------+
EOF


#echo -e "\033[38;2;255;0;0m⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠶⢤⠶⡄
#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠣⡀⡽⠁\033[0m"
#echo -e "\033[38;2;255;255;0m⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠲⡚⢚⠀
#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⢸⠀
#⠀⠀⠀⠀⠀⠀⠀⠀⡞⠋⠑⢦⡠⠤⠶⠦⣄⠀⠀⠀⠀⠀⡴⠁⡘⠀
#⠀⠀⠀⠀⠀⣠⠒⠈⠉⠒⠲⠁⠀⠀⠀⠀⠈⠓⠦⠤⠴⠋⠀⡰⠁⠀
#⠀⠀⠀⠀⠀⡇⢀⠖⠚⠛⠋⡇⠀⠀⠀⠀⠀⢀⡄⠀⠀⡠⠞⠀⠀⠀
#⠀⠀⠀⠀⠀⣧⠈⢆⠀⠀⢀⡇⠀⠀⠀⠀⠀⡤⢯⢠⠎⠀⠀⠀⠀⠀
#⠀⠀⠀⠀⠀⠘⢇⠀⠑⠒⠊⢠⠖⠀⠀⠀⠀⠑⢊⡟⠀⠀⠀⠀⠀⠀
#⠀⠀⠀⠀⠀⠀⢈⡗⠤⠀⠴⠃⠀⢀⣀⣀⣀⠴⠊⠀⠀⠀⠀⠀⠀⠀
#⠀⠀⠀⠀⢀⡔⠁⠀⠀⠀⠀⠀⠀⠀⢠⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#⠀⠀⠀⢰⠟⠀⠀⠀⠢⠄⣀⡤⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#⢶⡦⢠⡇⠀⠀⠀⠀⠀⠀⢨⣿⡆⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#⠈⠓⠚⢇⠀⠀⠀⠀⠀⠀⢹⠋⠀⠀⣸⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#⠀⠀⠀⠀⠁⢒⡒⠂⠈⠉⠞⠓⠚⠙⠴⠃\033[0m"





```


##  Firewall iptables
```
-A INPUT -s 192.168.0.0/24 -m state --state NEW -m tcp -p tcp --dport 5432 -j ACCEPT
```


### lEVANTAR EL SERVICIO AUTOMATICAMENTE 
**systemd** archivo de configuración utilizado , Este archivo define cómo se debe iniciar, detener y reiniciar el servicio de PostgreSQL

```
/********** Validar si existe el archivo , si no, hay que configurar el archivo  **********/
/lib/systemd/system/postgresql.service

--- PARÁMETROS ----
User: Especifica el usuario con el que se ejecutará el servicio, en este caso postgres.
ExecStart: Comando utilizado para iniciar el servicio. En este ejemplo, usa pg_ctl para iniciar PostgreSQL, indicando el directorio de datos, el archivo de registro y otros parámetros.
ExecStop: Comando utilizado para detener el servicio de manera ordenada.
ExecReload: Comando utilizado para recargar la configuración del servicio sin interrumpirlo.


/********** Verificar si el Servicio Está Habilitado para el Inicio Automático **********/
systemctl is-active postgresql.service
systemctl is-enabled postgresql.service
systemctl is-failed postgresql.service
sudo systemctl status postgresql.service


/**********  Habilitar el Servicio para el Inicio Automático **********/
sudo systemctl enable postgresql


/********** Validar si se inicio automaticamente el servicio  **********/
journalctl -u postgresql


https://github.com/CR0NYM3X/POSTGRESQL/blob/main/postgresql.service.md

------------------- OTRAS OPCIONES  ---------------------

vim  /etc/rc.local 
su - postgres -c "/usr/pgsql-12/bin/pg_ctl start -D /sysx/data/ -o -i" /etc/rc.local


crontab -e
@reboot /ruta/completa/a/tu_script.sh


Puedes colocar un script en /etc/init.d/ 
/etc/init.d/ 

```

### Colocar el archivo de configuración (postgresql.conf, pg_hba.conf y pg_ident)
```
/usr/pgsql/bin/pg_ctl  -o -i -D /ruta/nueva/DATA -c config_file=/ruta/nueva/postgresql.conf

```

### Conexto de cada parámetro 
```


new_postgres@template1# select distinct context from pg_settings ;
+-------------------+
|      context      |
+-------------------+
| postmaster        |
| superuser-backend |
| user              |
| internal          |
| backend           |
| sighup            |
| superuser         |
+-------------------+
(7 rows)


 

select name,setting,context from pg_settings  where context  = 'internal';
1. **internal**: Estos parámetros no pueden ser cambiados directamente; reflejan valores determinados internamente. Algunos pueden ajustarse recompilando el servidor con diferentes opciones de configuración o cambiando opciones suministradas a `initdb`.
mensaje de error si intentar modificar en session "cannot be changed"

select name,setting,context from pg_settings  where context  = 'postmaster';
2. **postmaster**:(neceista Restart) Estos parámetros solo pueden aplicarse cuando el servidor se inicia, por lo que cualquier cambio requiere reiniciar el servidor. Los valores para estos parámetros suelen almacenarse en el archivo `postgresql.conf` o pasarse en la línea de comandos al iniciar el servidor. , error al intentar cambiar en session " cannot be changed without restarting the server"

select name,setting,context from pg_settings  where context  = 'backend';
3. **backend**: (neceista restart)  Estos parámetros requieren de un reinicio ya que aparecen este mensaje al intentar modificarlos usando SET en la session "cannot be set after connection start"

select name,setting,context from pg_settings  where context  = 'superuser-backend';
4. **superuser-backend**: (neceista restart) Estos parámetros requieren de un reinicio ya que aparecen este mensaje al intentar modificarlos usando SET en la session "cannot be set after connection start"

select name,setting,context from pg_settings  where context  = 'user';
5. **user** (Reload, Session con SET ): Cualquier usuario puede cambiar estos parámetros en cualquier momento, y los cambios solo afectan a la sesión que realiza el cambio, igual se pueden cambiar desde postgresql.conf y hacer un reload

select name,setting,context from pg_settings  where context  = 'superuser';
6. **superuser** (Reload, Session con SET ): Solo los superusuarios en la session pueden cambiar estos parámetros y requieren de recarga de configuraciones con reload.

select name,setting,context from pg_settings  where context  = 'sighup';
7. **sighup**: (Reload ) Los cambios en estos parámetros pueden hacerse en `postgresql.conf` sin necesidad de reiniciar el servidor, pero requieren enviar una señal SIGHUP al proceso postmaster para que los cambios surtan efecto.
	no se pueden hacer cambios dentro de la sesion ya que marca error "cannot be changed now"



https://www.postgresql.org/docs/current/sql-set-role.html
https://www.postgresql.org/docs/current/view-pg-settings.html
https://www.enterprisedb.com/blog/understanding-postgres-parameter-context




 
---> Solo se puede de la version 15 en adeltante 

DO $$
DECLARE
    param_name text;
BEGIN
    FOR param_name IN 
        SELECT name 
        FROM pg_settings 
        WHERE context = 'user' -- Parámetros modificables por usuarios
    LOOP
        EXECUTE format('REVOKE SET ON PARAMETER %I FROM test', param_name);
    END LOOP;
END $$;

 
  
```
## 🧠 Escenario 1: **Alta escritura, pocas conexiones**

### Objetivo: Optimizar **I/O de escritura**, mantener estabilidad con pocas conexiones.

### 🔧 Parámetros recomendados:

| Parámetro | Valor sugerido | Explicación |
|----------|----------------|-------------|
| `wal_writer_delay` | `10ms` o menos | Reduce el tiempo entre escrituras al WAL. |
| `commit_delay` | `0` o bajo | Evita retrasos innecesarios en commits. |
| `synchronous_commit` | `off` (si puedes tolerar pérdida mínima) | Mejora rendimiento al no esperar confirmación de WAL. |
| `wal_buffers` | `16MB` o más | Mejora rendimiento en escrituras intensivas. |
| `checkpoint_timeout` | `15min` o más | Menos checkpoints, menos I/O. |
| `checkpoint_completion_target` | `0.9` | Distribuye mejor el trabajo del checkpoint. |
| `effective_io_concurrency` | `200` (si usas SSD) | Mejora paralelismo en operaciones de disco. |
| `max_connections` | `50` o menos | No necesitas muchas conexiones. |
| `shared_buffers` | 25–40% de RAM | Mejora caché de escritura. |
| `work_mem` | `4MB` o más | Mejora operaciones intermedias en escritura. |
| `bgwriter_delay, bgwriter_lru_maxpages, bgwriter_lru_multiplier` | `Ajustar si hay muchas conexiones escribiendo` | Mejora el rendimiento del background writer en entornos con alta concurrencia. |
 

## 🔍 Escenario 2: **Muchas conexiones, muchas lecturas**

### Objetivo: Optimizar **lectura concurrente**, mantener estabilidad con alto tráfico.

### 🔧 Parámetros recomendados:

| Parámetro | Valor sugerido | Explicación |
|----------|----------------|-------------|
| `max_connections` | `200–500` según hardware | Soporta muchas conexiones simultáneas. |
| `shared_buffers` | 40–50% de RAM | Mejora caché de lectura. |
| `effective_cache_size` | 70–80% de RAM | Ayuda al planner a usar índices eficientemente. |
| `work_mem` | `2–4MB` por conexión | Mejora operaciones como `ORDER BY`, `JOIN`. |
| `parallel_workers` | `4–8` o más | Mejora consultas paralelas. |
| `max_parallel_workers_per_gather` | `2–4` | Mejora rendimiento de consultas grandes. |
| `random_page_cost` | `1.1` (si usas SSD) | Incentiva uso de índices. |
| `autovacuum_max_workers` | `5–10` | Mantiene estadísticas actualizadas. |
| `pg_stat_statements` | `on` | Para monitorear y optimizar consultas. |
| `max_files_per_process` | `1000 a 2000` | Cada conexión puede abrir archivos. Aumentar si hay muchas conexiones activas. |
 
## 📈 Tabla basada en cantidad de conexiones
  

| Nivel de carga | Conexiones simultáneas | CPU recomendada | RAM recomendada | Disco recomendado | ¿Usar pool? | Comentario |
|----------------|------------------------|------------------|------------------|--------------------|-------------|------------|
| Baja           | 1 - 50                 | 2 vCPU           | 4 GB             | SSD 100 GB         | No necesario | PostgreSQL puede manejarlo bien |
| Media          | 51 - 200               | 4 vCPU           | 8 GB             | SSD 250 GB         | Recomendado  | Mejora eficiencia y estabilidad |
| Alta           | 201 - 500              | 8 vCPU           | 16 GB            | SSD NVMe 500 GB    | Necesario    | Evita saturación y mejora rendimiento |
| Crítica        | > 500                  | 16+ vCPU         | 32+ GB           | SSD NVMe 1 TB+     | Obligatorio  | PostgreSQL no escala bien sin pooling |

> ⚠️ **Nota importante**: PostgreSQL no escala bien con miles de conexiones. Se recomienda usar **connection pooling** con herramientas como **PgBouncer** o **Odyssey** para manejar cargas altas sin saturar el servidor.


 
## 📈 Tabla basada en TPS 
 

| Nivel de carga | Transacciones por segundo (TPS) | CPU recomendada | RAM recomendada | Disco recomendado |
|----------------|-------------------------------|------------------|------------------|--------------------|
| Baja           | 0 - 50                        | 2 vCPU           | 4 GB             | SSD 100 GB         |
| Media          | 51 - 500                      | 4 vCPU           | 8 GB             | SSD 250 GB         |
| Alta           | 501 - 5000                    | 8 vCPU           | 16 GB            | SSD NVMe 500 GB    |
| Crítica        | > 5000                        | 16+ vCPU         | 32+ GB           | SSD NVMe 1 TB+     |



## 🔍 ¿Qué pasa cuando hay muchas conexiones en PostgreSQL?

PostgreSQL usa un modelo de **procesos por conexión**:

- Cada conexión activa crea un **proceso independiente** en el sistema operativo.
- Estos procesos consumen **memoria**, **CPU** y **recursos de I/O**.
- No hay un *thread pool* o *event loop* como en otros motores (por ejemplo, MySQL con `thread pooling` o servidores web como Nginx).

### ⚠️ Problemas cuando hay muchas conexiones:

1. **Consumo excesivo de memoria**: Cada proceso tiene buffers, estructuras internas, y puede usar `work_mem`, `temp_buffers`, etc.
2. **Context switching**: El sistema operativo tiene que cambiar entre procesos constantemente, lo que degrada el rendimiento.
3. **Bloqueos y contención**: Más procesos compiten por recursos compartidos (locks, buffers, disco).
4. **Latencia elevada**: Aumenta el tiempo de respuesta por sobrecarga del sistema.
5. **Riesgo de crash**: Si se supera el límite de procesos del sistema operativo o de PostgreSQL (`max_connections`), el servidor puede volverse inestable.



## 🧠 ¿Cómo ayuda el *pooling*?

| Sin Pooling | Con Pooling |
|-------------|-------------|
| Cada cliente crea una conexión | Las conexiones se reutilizan |
| Alto consumo de recursos | Bajo consumo de recursos |
| Riesgo de saturación | Control de concurrencia |
| Latencia alta | Latencia baja |
| Difícil escalar | Fácil escalar horizontalmente |
 
## 📌 Ejemplo práctico

Supón que tienes 1000 clientes web que hacen consultas ocasionales. Sin pooling, PostgreSQL tendría 1000 procesos activos. Con PgBouncer, puedes tener solo 50 conexiones activas y reutilizarlas, reduciendo el consumo de memoria y CPU drásticamente.
 
 
 
## 🧠 ¿Cuándo se recomienda usar *connection pooling*?

Aquí tienes los **criterios más comunes** para decidir si necesitas un pool de conexiones como **PgBouncer** o **Odyssey**:

---

### ✅ 1. **Cuando tienes muchas conexiones simultáneas**
- Si tu aplicación genera **más de 100 conexiones activas** al mismo tiempo, ya es recomendable usar un pool.
- PostgreSQL por defecto tiene `max_connections = 100`, pero aumentar este valor no siempre es eficiente.

---

### ✅ 2. **Cuando usas aplicaciones web o microservicios**
- Frameworks como Django, Laravel, Node.js, etc., tienden a abrir muchas conexiones por cada petición.
- En arquitecturas de microservicios, cada servicio puede abrir su propia conexión, lo que escala rápidamente.

---

### ✅ 3. **Cuando las conexiones están inactivas mucho tiempo**
- Si tienes conexiones que se abren pero no hacen nada (esperando al usuario, por ejemplo), estás desperdiciando recursos.
- El pool cierra o reutiliza esas conexiones automáticamente.

---

### ✅ 4. **Cuando el TPS (transacciones por segundo) es bajo pero hay muchas conexiones**
- Ejemplo: 500 conexiones activas pero solo 20 TPS. Esto indica que muchas conexiones están ociosas.
- El pool permite que esas 20 TPS se manejen con solo 10-20 conexiones reales.

---

### ✅ 5. **Cuando tienes problemas de rendimiento por saturación**
- Si ves errores como `too many connections`, `out of memory`, o el sistema se vuelve lento, es momento de usar pooling.

---

### ✅ 6. **Cuando quieres limitar el impacto de clientes mal diseñados**
- Algunos clientes no cierran conexiones correctamente o hacen reconexiones constantes.
- El pool actúa como intermediario y protege al servidor.

### Bibliografias 
```
https://medium.com/@jramcloud1/04-postgresql-17-performance-tuning-checkpoints-explained-4972e78f4e56
https://medium.com/@wasiualhasib/optimizing-postgresql-performance-how-the-fill-factor-setting-improve-i-o-performance-00091e5c951c

https://medium.com/@jramcloud1/postgresql-17-kernel-tuning-guide-managing-system-parameters-for-optimal-performance-fe097de1dcdb
https://blog.devops.dev/10-must-know-postgresql-performance-settings-1001aa1e668c
https://www.cybertec-postgresql.com/en/services/postgresql-optimization-security/postgresql-performance-tuning/
https://medium.com/@jramcloud1/postgresql-17-performance-tuning-how-to-find-kill-and-analyze-long-running-and-blocked-queries-f1bbe30a8804
https://medium.com/@jramcloud1/13-postgresql-17-performance-tuning-indexing-and-its-impact-on-performance-17293afdba96
https://medium.com/@ankush.thavali/the-ultimate-guide-to-postgresql-performance-tuning-0d8134256125

https://medium.com/@mydbopsdatabasemanagement/postgresql-performance-tuning-key-parameter-best-practices-for-2025-508965aa934e
https://medium.com/@noeldsn/understanding-postgresql-memory-usage-and-performance-tuning-bcc02b5a9c2e
https://levelup.gitconnected.com/sql-performance-tuning-in-prisma-orm-postgresql-for-beginners-9b60e4d1041d
https://medium.com/@raymondafuye/rds-postgresql-performance-optimization-through-shared-buffers-parameter-tuning-bed8dd257f95
https://medium.com/@akshaygupta.live/postgresql-query-performance-tuning-tips-75ebe1483cdd

https://medium.com/@yuvrajkakkar1/master-postgresql-blazing-fast-increase-performance-with-practical-tips-a1c9301559be
https://techblog.quantela.com/unleashing-postgresql-performance-a-comprehensive-guide-to-tuning-34a78b7a1da0
https://medium.com/@burakkocakeu/optimizing-postgresql-database-performance-908f309a4156
https://blog.devgenius.io/10-best-practices-for-optimizing-postgresql-performance-a655a6c91073
https://medium.com/@jramcloud1/02-postgresql-performance-tuning-understanding-postgresql-shared-buffers-for-performance-tuning-0a61086edee7
https://medium.com/@jramcloud1/19-postgresql-17-performance-tuning-gin-generalized-inverted-index-757c7a670b92
https://medium.com/@jramcloud1/06-postgresql-17-performance-tuning-utility-processes-explained-bee2e8be9902
https://medium.com/@jramcloud1/07-postgresql-17-performance-tuning-understanding-vacuum-in-detail-4914a06073fe
https://medium.com/@jramcloud1/17-postgresql-17-performance-tuning-using-partial-indexes-f78fe8b06c68
https://nidhig631.medium.com/ways-to-optimize-and-improve-postgresql-performance-47d1b1189454


https://www.cybertec-postgresql.com/en/services/postgresql-optimization-security/postgresql-performance-tuning/

PostgreSQL Configuration Tuning: Best Practices and Tools for Production-Ready Performance : 
https://medium.com/@ukhore/postgresql-configuration-tuning-best-practices-and-tools-for-production-ready-performance-ac121eb37061
https://medium.com/@itsmerob/supercharging-postgresql-5-powerful-techniques-for-enhanced-performance-and-scalability-692362eebd0a

------- AQUI PODRAS ENCONTRAR TODOS LOS  PARAMETRO
https://www.postgresql.org/docs/17/admin.html <br>
https://pgpedia.info/ <br>
https://postgresqlco.nf/doc/en/param/?q=password_encryption#

Doc Man: 
/usr/pgsql-16/share/man/man1/psql.1


 ---------> PDF  CONFIGURACION PSQL  <--------------

[Recomendado LVL #1 ] https://www.postgresql.org/docs/current/runtime-config.html
 
[Recomendado #2 ]--> PostgreSQL Configuration Best Practices for Performance and Security
https://www.cherrycreekeducation.com/bbk/b/Apress_PostgreSQL_Configuration.pdf

[Recomendado #3  ] -- Este tiene varios temas como  PITR, respaldos, configuraciones etc, etc
[Recomendado #4  ] https://www.visibilidadweb.unam.mx/capacitacion/perfilesTIC/responsableTIC/Manual-Curso-Basico-Postgres 

 [Recomendado #5  ] https://www.postgresql.org/docs/current/runtime-config.html

 [LVL recomendación 0 ]   https://wiki.postgresql.org/images/5/59/FlexiblePostgreSQLConfiguration.pdf
 [LVL recomendación 0 ]  https://ubuntu.com/server/docs/install-and-configure-postgresql

-- Todos los parametros de postgresql.conf
https://pgdash.io/blog/postgres-configuration-cheatsheet.html
https://helpcenter.netwrix.com/bundle/StealthDEFEND_2.7/page/Content/StealthDEFEND/Installation_Guide/Configure_the_Postgres.conf_File/Configure_the_Postgres.conf_File.htm





  --------->  PDF SECURITY - PSQL   <--------------
  [LVL recomendación 1 ] https://repository.unad.edu.co/bitstream/handle/10596/36746/ilovepdf_merged.pdf?sequence=3&isAllowed=y
  [LVL recomendación 2] https://www.postgresql.eu/events/pgconfeu2023/sessions/session/4707/slides/444/P-DBI-E-20231214-PostgreSQL_security_with_demo.pdf
  [LVL recomendación 0] https://www.crunchydata.com/files/stig/PGSQL-STIG-v1r1.pdf
  [LVL recomendación 0]   https://rcci.uci.cu/?journal=rcci&page=article&op=viewFile&path[]=96&path[]=90

 
 --------->  postgresql.conf DE PRUBEAS <--------------
 https://github.com/postgres/postgres/blob/master/src/backend/utils/misc/postgresql.conf.sample
 https://gist.github.com/sbrohme/3295547
 https://gist.github.com/64kramsystem/d780ce0f8dff7b90847b2728f506cdea


 --------->  test instalación <--------------

https://gist.github.com/franklinbr/f968e832fb5f95250259f2a6031644fa
https://gist.github.com/arcolife/d8e747f9bfafe841b3a25def91ed1afe
https://gist.github.com/djyoda/5d243f7beddbe6f4d8a9
https://gist.github.com/ryanguill/7928937

 --------->  CONFIGURACIÓN DE PARAMETROS ONLINE <--------------
https://pgtune.leopard.in.ua/
https://pgtuner.onrender.com/
https://www.pgconfig.org/#/?max_connections=100&pg_version=16&environment_name=WEB&total_ram=4&cpus=2&drive_type=SSD&arch=x86-64&os_type=linux
https://pgconfigurator.cybertec.at/

 --------->  DESCARGAR POSTGRESQL REDHAT <--------------
https://www.postgresql.org/download/linux/redhat/
 

.. PACKETES....
postgresql-client	libraries and client binaries
postgresql-server	core database server
postgresql-contrib	additional supplied modules
postgresql-devel	libraries and headers for C language development

```


