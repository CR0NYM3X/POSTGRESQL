
 
El archivado continuo de WAL es útil para:
- **Recuperación ante fallos**: Permite restaurar la base de datos a un estado anterior mediante la reproducción de los registros archivados.
- **Replicación**: Se pueden enviar los archivos WAL a servidores de réplica para mantener una copia actualizada de la base de datos.
- **Punto de recuperación en el tiempo (PITR)**: Se puede restaurar la base de datos a un momento específico en el pasado.

 
# pasos que sigue PostgreSQL cuando se realiza una modificación de datos, como un `INSERT`, `UPDATE` o `DELETE`:

### 1. Recepción de la Consulta
El cliente envía la consulta SQL al servidor PostgreSQL.

### 2. Análisis y Planificación
1. **Parser**: La consulta se analiza sintácticamente para convertirla en una estructura de árbol de análisis.
2. **Rewriter**: Si hay reglas definidas, se aplican en esta etapa para modificar la consulta.
3. **Planner/Optimizer**: El planificador genera un plan de ejecución óptimo para la consulta, considerando estadísticas y costos.

### 3. Ejecución del Plan
1. **Inicio de la Transacción**: Si la consulta es parte de una transacción, se asegura que la transacción esté iniciada.
2. **Ejecución del Plan**: El plan de ejecución se lleva a cabo. Para un `INSERT`, se añaden nuevas filas; para un `UPDATE`, se modifican las filas existentes; y para un `DELETE`, se eliminan las filas correspondientes.

### 4. Registro en el WAL (Write-Ahead Log)
1. **Generación de Entradas WAL**: Se generan entradas en el WAL para cada modificación. Estas entradas registran los cambios antes de que se escriban en las tablas.
2. **Flujo de WAL**: Las entradas WAL se envían al disco y, si está configurado, a los servidores de réplica.

### 5. Modificación de Datos en Memoria
1. **Buffers de Memoria**: Los cambios se aplican primero en los buffers de memoria compartida.
2. **Dirty Buffers**: Los buffers modificados se marcan como "sucios" (dirty) y se programan para ser escritos en disco más tarde.

### 6. Checkpoints
1. **Checkpoints Periódicos**: PostgreSQL realiza checkpoints periódicos para asegurar que los datos en memoria se escriban en disco.
2. **Sincronización de WAL y Datos**: Durante un checkpoint, se asegura que todas las entradas WAL hasta ese punto se hayan aplicado a las tablas en disco.

### 7. Confirmación de la Transacción
1. **Commit**: Si la consulta es parte de una transacción, se realiza un commit, asegurando que todos los cambios sean permanentes.
2. **Liberación de Recursos**: Se liberan los recursos utilizados por la transacción.

### 8. Replicación y Archivado
1. **Replicación**: Si hay servidores de réplica configurados, las entradas WAL se envían a estos servidores para mantener la consistencia.
2. **Archivado**: Las entradas WAL se archivan según la configuración de archivado continuo.

### 9. Mantenimiento y Vacío
1. **Vacuum**: PostgreSQL realiza operaciones de mantenimiento como `VACUUM` para recuperar espacio y actualizar estadísticas.
2. **Autovacuum**: El proceso `autovacuum` se ejecuta automáticamente para mantener la base de datos en buen estado.

---


# Hacer una transaccion
**`[NOTA]`** Cada sesión puede tener su propia transacción independiente. Por lo tanto, si ejecutas un BEGIN en una sesión y no lo cierras, solo afectará a esa sesión específica. Otras sesiones no se verán afectadas por la transacción no cerrada en la primera sesión. <br><br>
 
El **begin o start** Permite que las transacciones/operaciones sean aisladas y transparentes unas de otras, esto quiere decir que si una sesion nueva se abre, no va detectar los cambios realizados en el cuando se incia el begin como son los insert,update,delete etc, 
 ```
BEGIN TRANSACTION  ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION ISOLATION LEVEL REPEATABLE READ;
 ```
El **commit**  se usa para guardar los cambios que se realizaron, como los insert,detelete, etc y estas seguro de que todo salio bien
 ```
COMMIT:
 ```
el **rollback** se usa en caso de que algo salio mal  y no quieres que se guarden los cambios entonces puedes hacer los rollback completo o un un rollback punto de guardado
 ```
rollback;
ROLLBACK TO SAVEPOINT my_savepoint;
 ```

el **savepoint** sirve para hacer un punto de guardado, en caso de realizar varios cambios en un begin 
 ```
savepoint my_name_savepoint;

-- tiene el propósito de destruir el punto de guardado 
RELEASE SAVEPOINT my_savepoint;
 ```

--- 

###  `PREPARE TRANSACTION` 

`PREPARE TRANSACTION` te permite asegurarte de que las operaciones críticas que involucran múltiples sistemas se completen de manera coherente, sin riesgo de que una parte se ejecute y otra no, lo que podría llevar a inconsistencias.

### ¿Dónde Aplicarlo?

- **Transacciones Bancarias**: Transferencias entre cuentas en diferentes bancos.
1. **Sistemas distribuidos**: Donde necesitas coordinar una transacción a través de múltiples bases de datos o servicios.
2. **Aplicaciones con middleware**: Que requieren confirmar o deshacer transacciones en múltiples fuentes de datos.
3. **Transacciones complejas**: Que necesitan ser preparadas antes de su confirmación final.


1. **Habilitar PREPARE TRANSACTION**:
```sql
postgres@postgres#* PREPARE TRANSACTION 'transaccion_123';
ERROR:  prepared transactions are disabled
HINT:  Set max_prepared_transactions to a nonzero value.
Time: 0.419 ms

postgres@postgres# set max_prepared_transactions =50;
ERROR:  parameter "max_prepared_transactions" cannot be changed without restarting the server
Time: 0.502 ms

--- una vez ya configurado en el archivo postgresql.conf
postgres@postgres# show max_prepared_transactions;
+---------------------------+
| max_prepared_transactions |
+---------------------------+
| 4                         |
+---------------------------+




################# PREGUNTAS #################
¿Si cierro la sesión una vez que realizo el PREPARE TRANSACTION, se cancela?
Respuesta: No, aunque cierres la sesión donde se generó el PREPARE TRANSACTION, puedes hacer el COMMIT o ROLLBACK en otra sesión sin problemas. La transacción preparada permanece en espera hasta que sea confirmada o revertida.

¿Se abre otro proceso al momento de hacer el PREPARE?
Respuesta: No, se monitoreó la cantidad de conexiones desde la vista pg_stat_activity y no se detectó un incremento en la cantidad de procesos. El PREPARE no abre un nuevo proceso, simplemente marca la transacción actual como preparada.

¿Esto bloquea?
Respuesta: Sí, aunque se salga del BEGIN y parezca que no va a bloquear, en realidad sí lo hace. La tabla se bloquea y la transacción preparada se queda esperando a que sea confirmada (COMMIT) o rechazada (ROLLBACK). Durante este tiempo, las operaciones que intenten acceder a los recursos bloqueados se verán afectadas.

¿Si cuando realizo el PREPARE TRANSACTION se reinicia o se recarga PostgreSQL, pierdo la transacción?
Respuesta: No, las transacciones preparadas se guardan en el disco y son resilientes a reinicios o recargas de PostgreSQL. Cuando el servidor vuelve a estar disponible, las transacciones preparadas seguirán existiendo y podrás hacer el COMMIT o ROLLBACK de esas transacciones.

¿Qué pasa si ejecuto el mismo PREPARE dos veces?
Respuesta: si quieres usar el mismo prepare  dos veces, causará un error porque una transacción con ese nombre ya existe , generara el siguiente error "ERROR:  transaction identifier "transferencia_prepare_db_test" is already in use
Time: 0.391 ms"

################# TERMINAL #1 #################



-- conectarnos a la db test 
postgres@test# \c test
psql (16.6, server 14.15)
You are now connected to database "test" as user "postgres".


-- Crear la tabla
-- drop table important_data;
postgres@test# CREATE TABLE IF NOT EXISTS important_data (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT clock_timestamp()
);
CREATE TABLE
Time: 0.701 ms


-- Insertar registros
postgres@test# INSERT INTO important_data (name, description) VALUES
('First Item', 'important item.'),
('Second Item', 'important item.'),
('Third Item', 'important item.'),
('Fourth Item', 'important item.');
INSERT 0 4
Time: 1.760 ms


 

postgres@test# BEGIN;
BEGIN
Time: 0.213 ms
postgres@test#*
postgres@test#* SELECT pg_backend_pid(),current_database(),clock_timestamp();
+----------------+------------------+-------------------------------+
| pg_backend_pid | current_database |        clock_timestamp        |
+----------------+------------------+-------------------------------+
|          24571 | test             | 2025-01-24 15:38:52.560835-07 |
+----------------+------------------+-------------------------------+
(1 row)

Time: 0.305 ms
postgres@test#*
postgres@test#* update important_data set name = 'Jose Maria' where id = 1;
UPDATE 1
Time: 0.484 ms
postgres@test#*
postgres@test#* PREPARE TRANSACTION 'transferencia_prepare_db_test';
PREPARE TRANSACTION
Time: 1.435 ms


-- Consultar los datos  
postgres@test# SELECT * FROM important_data;
+----+-------------+-----------------+----------------------------+
| id |    name     |   description   |         created_at         |
+----+-------------+-----------------+----------------------------+
|  1 | First Item  | important item. | 2025-01-24 15:34:09.267672 |
|  2 | Second Item | important item. | 2025-01-24 15:34:09.267833 |
|  3 | Third Item  | important item. | 2025-01-24 15:34:09.267839 |
|  4 | Fourth Item | important item. | 2025-01-24 15:34:09.267841 |
+----+-------------+-----------------+----------------------------+
(4 rows)

Time: 0.396 ms


################# TERMINAL #2 #################


-- conectarnos a la db test 
postgres@test# \c test
psql (16.6, server 14.15)
You are now connected to database "test" as user "postgres".


postgres@test# SELECT pg_backend_pid(),current_database(),clock_timestamp();
+----------------+------------------+-------------------------------+
| pg_backend_pid | current_database |        clock_timestamp        |
+----------------+------------------+-------------------------------+
|          24519 | test             | 2025-01-24 15:40:33.842792-07 |
+----------------+------------------+-------------------------------+
(1 row)

Time: 0.419 ms

postgres@test#  select * from pg_catalog.pg_prepared_statements;
+------+-----------+--------------+-----------------+----------+---------------+--------------+
| name | statement | prepare_time | parameter_types | from_sql | generic_plans | custom_plans |
+------+-----------+--------------+-----------------+----------+---------------+--------------+
+------+-----------+--------------+-----------------+----------+---------------+--------------+
(0 rows)

Time: 0.420 ms

-- Validar los prepares pendientes 
postgres@test#  select * from pg_catalog.pg_prepared_xacts;
+-------------+-------------------------------+-------------------------------+----------+----------+
| transaction |              gid              |           prepared            |  owner   | database |
+-------------+-------------------------------+-------------------------------+----------+----------+
|        2464 | transferencia_prepare_db_test | 2025-01-24 15:40:34.842792-07 | postgres | test     |
+-------------+-------------------------------+-------------------------------+----------+----------+
(1 row)

Time: 0.735 ms


-- Consultar los datos 
postgres@test# SELECT * FROM important_data;
+----+-------------+-----------------+----------------------------+
| id |    name     |   description   |         created_at         |
+----+-------------+-----------------+----------------------------+
|  1 | First Item  | important item. | 2025-01-24 15:34:09.267672 |
|  2 | Second Item | important item. | 2025-01-24 15:34:09.267833 |
|  3 | Third Item  | important item. | 2025-01-24 15:34:09.267839 |
|  4 | Fourth Item | important item. | 2025-01-24 15:34:09.267841 |
+----+-------------+-----------------+----------------------------+
(4 rows)

Time: 0.296 ms

postgres@test# BEGIN;
BEGIN
Time: 0.233 ms

-- No se puede hacer commit o rollback a un prepare,  dentro de un begin.
postgres@test#* COMMIT PREPARED 'transferencia_prepare_db_test';
ERROR:  COMMIT PREPARED cannot run inside a transaction block
Time: 0.291 ms

postgres@test#! rollback;
ROLLBACK
Time: 0.293 ms


-- confirma con COMMIT o rechaza con ROLLBACK desde otra session
postgres@test# COMMIT PREPARED 'transferencia_prepare_db_test';
COMMIT PREPARED
Time: 1.118 ms

-- Como vemos realizo los cambios
postgres@test# SELECT * FROM important_data;
+----+-------------+-----------------+----------------------------+
| id |    name     |   description   |         created_at         |
+----+-------------+-----------------+----------------------------+
|  2 | Second Item | important item. | 2025-01-24 15:34:09.267833 |
|  3 | Third Item  | important item. | 2025-01-24 15:34:09.267839 |
|  4 | Fourth Item | important item. | 2025-01-24 15:34:09.267841 |
|  1 | Jose Maria  | important item. | 2025-01-24 15:34:09.267672 |
+----+-------------+-----------------+----------------------------+
(4 rows)

Time: 0.648 ms

 
 


 

```


### Ejemplo uso de Transacciones
 ```sql
postgres@postgres# create table personas
 (  id     integer
 , nombre character varying(100)
 , edad   integer
 , ciudad character varying(100) );
CREATE TABLE
Time: 2.290 ms


postgres@postgres# insert into personas values
 (  1 ,'Juan' , 28 ,'Culiacán' ),
 (  2 ,'Ana'  , 35 ,'Mazatlán' ),
 (  3 ,'Luis' , 22 ,'Guadalajara' );
INSERT 0 3
Time: 2.562 ms


postgres@postgres# select *from personas;
+----+--------+------+-------------+
| id | nombre | edad |   ciudad    |
+----+--------+------+-------------+
|  1 | Juan   |   28 | Culiacán    |
|  2 | Ana    |   35 | Mazatlán    |
|  3 | Luis   |   22 | Guadalajara |
+----+--------+------+-------------+
(3 rows)



postgres@postgres# START TRANSACTION ISOLATION LEVEL Serializable ;
START TRANSACTION
Time: 0.389 ms
postgres@postgres#*

postgres@postgres#*  savepoint hice_un_update_1;
SAVEPOINT
Time: 0.381 ms
postgres@postgres#* update personas set nombre= 'Panfilo' where id = 1 ;
UPDATE 1
Time: 1.687 ms

postgres@postgres#* select * from personas;
+----+---------+------+-------------+
| id | nombre  | edad |   ciudad    |
+----+---------+------+-------------+
|  2 | Ana     |   35 | Mazatlán    |
|  3 | Luis    |   22 | Guadalajara |
|  1 | Panfilo |   28 | Culiacán    |
+----+---------+------+-------------+
(3 rows)


postgres@postgres#* savepoint hice_un_update_2;
SAVEPOINT
Time: 0.364 ms

postgres@postgres#* update personas set nombre= 'Pedro' where id = 1 ;
UPDATE 1
Time: 0.891 ms


postgres@postgres#* select * from personas;
+----+--------+------+-------------+
| id | nombre | edad |   ciudad    |
+----+--------+------+-------------+
|  2 | Ana    |   35 | Mazatlán    |
|  3 | Luis   |   22 | Guadalajara |
|  1 | Pedro  |   28 | Culiacán    |
+----+--------+------+-------------+
(3 rows)


postgres@postgres#* savepoint hice_un_delete;
SAVEPOINT
Time: 0.303 ms


postgres@postgres#* delete  from personas   where id = 1 ;
DELETE 1
Time: 0.471 ms


postgres@postgres#*  select * from personas;
+----+--------+------+-------------+
| id | nombre | edad |   ciudad    |
+----+--------+------+-------------+
|  2 | Ana    |   35 | Mazatlán    |
|  3 | Luis   |   22 | Guadalajara |
+----+--------+------+-------------+
(2 rows)



postgres@postgres#* savepoint hice_un_insert;
SAVEPOINT
Time: 0.288 ms

postgres@postgres#* insert into personas values(4,'Maria',50,'Monterrey');
INSERT 0 1
Time: 0.456 ms


postgres@postgres#*  select * from personas;
+----+--------+------+-------------+
| id | nombre | edad |   ciudad    |
+----+--------+------+-------------+
|  2 | Ana    |   35 | Mazatlán    |
|  3 | Luis   |   22 | Guadalajara |
|  4 | Maria  |   50 | Monterrey   |
+----+--------+------+-------------+
(3 rows)
 
 
postgres@postgres#* ROLLBACK TO SAVEPOINT hice_un_delete;
ROLLBACK
Time: 0.395 ms

--- Se Regresa el "hice_un_delete"
postgres@postgres#* select * from personas;
+----+--------+------+-------------+
| id | nombre | edad |   ciudad    |
+----+--------+------+-------------+
|  2 | Ana    |   35 | Mazatlán    |
|  3 | Luis   |   22 | Guadalajara |
|  1 | Pedro  |   28 | Culiacán    |
+----+--------+------+-------------+
(3 rows)


postgres@postgres# commit;
COMMIT
Time: 0.434 ms


postgres@postgres#* select * from personas;
+----+--------+------+-------------+
| id | nombre | edad |   ciudad    |
+----+--------+------+-------------+
|  2 | Ana    |   35 | Mazatlán    |
|  3 | Luis   |   22 | Guadalajara |
|  1 | Pedro  |   28 | Culiacán    |
+----+--------+------+-------------+
(3 rows)
 ```



 --- 

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
El Write-Ahead Logging (WAL/ Registro de escritura anticipada) es un mecanismo de registro que garantiza la integridad de los datos y la recuperación ante fallos. Funciona registrando todas las modificaciones realizadas en la base de datos antes de que se confirmen en el almacenamiento físico.

### **2. Estructura de los Archivos WAL**
- **Segmentos**: Los archivos WAL se almacenan en el directorio `pg_wal` como un conjunto de archivos de segmento, normalmente de 16 MB cada uno⁴.
- **Páginas**: Cada segmento se divide en páginas, normalmente de 8 kB cada una⁴.

### **3. Proceso de Generación de WAL**
1. **Registro de Transacciones**: Cuando se ejecuta una transacción, los cambios no se escriben inmediatamente en el disco. En su lugar, se registran primero en un archivo WAL.
2. **Número de Secuencia de Registro (LSN)**: Cada registro en el WAL tiene un Número de Secuencia de Registro (LSN), que es un desplazamiento en bytes dentro del WAL. Este número aumenta de manera monótona con cada nuevo registro.
3. **Flushing**: Los registros WAL se escriben primero en el buffer compartido.

### **4. Checkpoints**
- **Definición**: Los checkpoints son puntos en los que se garantiza que los archivos de datos se han actualizado con toda la información escrita antes de ese checkpoint.
- **Proceso**: Durante un checkpoint, todas las páginas de datos sucias se vacían al disco y se escribe un registro especial de checkpoint en el archivo WAL.

### **5. Archiving y Recuperación**
- **Archiving**: Si el archivado de WAL está habilitado, los archivos WAL se copian a una ubicación de archivo antes de ser eliminados de `pg_wal`.
- **Recuperación**: En caso de un fallo inesperadamente, postgres usa los registros WAL para reestablecer el estado más reciente de la base de datos y descartar las transacciones no confirmadas.


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
**Propósito**: Este comando se utiliza para resetear el Write-Ahead Log (WAL). Es una herramienta de último recurso para recuperar un servidor de base de datos que no puede arrancar debido a la corrupción de estos archivos.

**Cuándo Usarlo**:
- **Último Recurso**: Solo debe usarse cuando el servidor no puede arrancar debido a la corrupción del WAL.
- **Previo Respaldo**: Siempre respalda tus datos antes de usar este comando, ya que puede llevar a la pérdida de datos, si tienes configurado el parametro archive_mode,archive_command cuando uses pg_resetwal estos se van archivar

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

postgres@postgres# select *from  pg_control_checkpoint();
+-[ RECORD 1 ]---------+--------------------------+
| checkpoint_lsn       | 1/A0000028               |
| redo_lsn             | 1/A0000028               |
| redo_wal_file        | 0000000100000001000000A0 |
| timeline_id          | 1                        |
| prev_timeline_id     | 1                        |
| full_page_writes     | t                        |
| next_xid             | 0:1084                   |
| next_oid             | 17277                    |
| next_multixact_id    | 1                        |
| next_multi_offset    | 0                        |
| oldest_xid           | 726                      |
| oldest_xid_dbid      | 1                        |
| oldest_active_xid    | 0                        |
| oldest_multi_xid     | 1                        |
| oldest_multi_dbid    | 1                        |
| oldest_commit_ts_xid | 0                        |
| newest_commit_ts_xid | 0                        |
| checkpoint_time      | 2024-09-20 10:17:38-07   |
+----------------------+--------------------------+


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
archive_command = 'cp %p /path/to/archive/%f'
archive_cleanup_command = 'pg_archivecleanup /usr/share/wal_archive %r'
archive_cleanup_command = 'pg_archivecleanup -d /mnt/standby/archive %r 2>>cleanup.log'



postgres@postgres#  select name,setting from pg_settings where name ilike '%checkpoint%';
+------------------------------+---------+
|             name             | setting |
+------------------------------+---------+
| checkpoint_completion_target | 0.9     |
| checkpoint_flush_after       | 32      |
| checkpoint_timeout           | 300     |
| checkpoint_warning           | 30      |
| log_checkpoints              | on      |
+------------------------------+---------+



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

forzar la creación de un nuevo archivo WAL (Write-Ahead Logging). PostgreSQL crea un nuevo archivo WAL cuando el archivo actual alcanza su tamaño máximo (por defecto, 16MB).
SELECT pg_switch_wal();  

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

postgres@postgres# select proname  from pg_proc where proname ilike '%checkpoint%';
+----------------------------------------------+
|                   proname                    |
+----------------------------------------------+
| pg_stat_get_bgwriter_timed_checkpoints       |
| pg_stat_get_bgwriter_requested_checkpoints   |
| pg_stat_get_bgwriter_buf_written_checkpoints |
| pg_stat_get_checkpoint_write_time            |
| pg_stat_get_checkpoint_sync_time             |
| pg_control_checkpoint                        |
+----------------------------------------------+


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








[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_ctl stop -D $PGDATA14
waiting for server to shut down.... done
server stopped

[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_resetwal -f -D $PGDATA14
Write-ahead log reset

[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-19 15:05:18 MST     1687430 66eca01e.19bf86 >LOG:  redirecting log output to logging collector process
<2024-09-19 15:05:18 MST     1687430 66eca01e.19bf86 >HINT:  Future log output will appear in directory "pg_log".
 done
server started


[postgres@SERVER_TEST pg_wal]$ cd /sysx/data14/pg_wal


[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 16M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 13:21 00000001000000000000005B
[postgres@SERVER_TEST pg_wal]$



[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump -f  00000001000000000000005B
rmgr: XLOG        len (rec/tot):    114/   114, tx:          0, lsn: 0/5B000028, prev 0/00000000, desc: CHECKPOINT_SHUTDOWN redo 0/5B000028; tli 1; prev tli 1; fpw true; xid 0:1011; oid 17060; multi 1; offset 0; oldest xid 726 in DB 1; oldest multi 1 in DB 1; oldest/newest commit timestamp xid: 0/0; oldest running xid 0; shutdown
rmgr: XLOG        len (rec/tot):     54/    54, tx:          0, lsn: 0/5B0000A0, prev 0/5B000028, desc: PARAMETER_CHANGE max_connections=100 max_worker_processes=8 max_wal_senders=10 max_prepared_xacts=0 max_locks_per_xact=64 wal_level=replica wal_log_hints=off track_commit_timestamp=off
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B0000D8, prev 0/5B0000A0, desc: RUNNING_XACTS nextXid 1011 latestCompletedXid 1010 oldestRunningXid 1011


[postgres@SERVER_TEST pg_log]$ $PGBIN14/psql -X -p 5414  -c   "create database test_checkpoint;"
CREATE DATABASE


rmgr: XLOG        len (rec/tot):     30/    30, tx:          0, lsn: 0/5B000110, prev 0/5B0000D8, desc: NEXTOID 25252
rmgr: Heap        len (rec/tot):     54/  4722, tx:       1011, lsn: 0/5B000130, prev 0/5B000110, desc: INSERT off 19 flags 0x00, blkref #0: rel 1664/0/1262 blk 0 FPW
rmgr: Btree       len (rec/tot):     53/   569, tx:       1011, lsn: 0/5B0013A8, prev 0/5B000130, desc: INSERT_LEAF off 17, blkref #0: rel 1664/0/2671 blk 1 FPW
rmgr: Btree       len (rec/tot):     53/   433, tx:       1011, lsn: 0/5B0015E8, prev 0/5B0013A8, desc: INSERT_LEAF off 17, blkref #0: rel 1664/0/2672 blk 1 FPW
rmgr: Standby     len (rec/tot):     54/    54, tx:          0, lsn: 0/5B0017A0, prev 0/5B0015E8, desc: RUNNING_XACTS nextXid 1012 latestCompletedXid 1010 oldestRunningXid 1011; 1 xacts: 1011
rmgr: Standby     len (rec/tot):     54/    54, tx:          0, lsn: 0/5B0017D8, prev 0/5B0017A0, desc: RUNNING_XACTS nextXid 1012 latestCompletedXid 1010 oldestRunningXid 1011; 1 xacts: 1011
rmgr: XLOG        len (rec/tot):    114/   114, tx:          0, lsn: 0/5B001810, prev 0/5B0017D8, desc: CHECKPOINT_ONLINE redo 0/5B0017A0; tli 1; prev tli 1; fpw true; xid 0:1012; oid 25252; multi 1; offset 0; oldest xid 726 in DB 1; oldest multi 1 in DB 1; oldest/newest commit timestamp xid: 0/0; oldest running xid 1011; online
rmgr: Database    len (rec/tot):     42/    42, tx:       1011, lsn: 0/5B001888, prev 0/5B001810, desc: CREATE copy dir 1663/1 to 1663/17060
rmgr: Standby     len (rec/tot):     54/    54, tx:          0, lsn: 0/5B0018B8, prev 0/5B001888, desc: RUNNING_XACTS nextXid 1012 latestCompletedXid 1010 oldestRunningXid 1011; 1 xacts: 1011
rmgr: XLOG        len (rec/tot):    114/   114, tx:          0, lsn: 0/5B0018F0, prev 0/5B0018B8, desc: CHECKPOINT_ONLINE redo 0/5B0018B8; tli 1; prev tli 1; fpw true; xid 0:1012; oid 25252; multi 1; offset 0; oldest xid 726 in DB 1; oldest multi 1 in DB 1; oldest/newest commit timestamp xid: 0/0; oldest running xid 1011; online
rmgr: Transaction len (rec/tot):     66/    66, tx:       1011, lsn: 0/5B001968, prev 0/5B0018F0, desc: COMMIT 2024-09-19 13:28:13.820813 MST; inval msgs: catcache 21; sync
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B0019B0, prev 0/5B001968, desc: RUNNING_XACTS nextXid 1012 latestCompletedXid 1011 oldestRunningXid 1012




[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "CREATE TABLE ventas (    id SERIAL PRIMARY KEY ,    fecha DATE,    cliente_id INTEGER,    producto_id INTEGER,    cantidad INTEGER,    precio NUMERIC);"
CREATE TABLE



rmgr: Standby     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B0019E8, prev 0/5B0019B0, desc: LOCK xid 1012 db 17060 rel 17061
rmgr: Storage     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B001A18, prev 0/5B0019E8, desc: CREATE base/17060/17061
rmgr: Heap        len (rec/tot):     54/   874, tx:       1012, lsn: 0/5B001A48, prev 0/5B001A18, desc: INSERT off 2 flags 0x01, blkref #0: rel 1663/17060/1259 blk 0 FPW
rmgr: Btree       len (rec/tot):     53/  2393, tx:       1012, lsn: 0/5B001DB8, prev 0/5B001A48, desc: INSERT_LEAF off 115, blkref #0: rel 1663/17060/2662 blk 2 FPW
rmgr: Btree       len (rec/tot):     53/  4065, tx:       1012, lsn: 0/5B002730, prev 0/5B001DB8, desc: INSERT_LEAF off 103, blkref #0: rel 1663/17060/2663 blk 2 FPW
rmgr: Btree       len (rec/tot):     53/  3693, tx:       1012, lsn: 0/5B003718, prev 0/5B002730, desc: INSERT_LEAF off 180, blkref #0: rel 1663/17060/3455 blk 4 FPW
rmgr: Heap2       len (rec/tot):     61/  7217, tx:       1012, lsn: 0/5B0045A0, prev 0/5B003718, desc: MULTI_INSERT 3 tuples flags 0x03, blkref #0: rel 1663/17060/1249 blk 16 FPW
rmgr: Btree       len (rec/tot):     53/  4125, tx:       1012, lsn: 0/5B0061F0, prev 0/5B0045A0, desc: INSERT_LEAF off 108, blkref #0: rel 1663/17060/2658 blk 14 FPW
rmgr: Btree       len (rec/tot):     53/  7673, tx:       1012, lsn: 0/5B007210, prev 0/5B0061F0, desc: INSERT_LEAF off 379, blkref #0: rel 1663/17060/2659 blk 9 FPW
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B009028, prev 0/5B007210, desc: INSERT_LEAF off 109, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B009070, prev 0/5B009028, desc: INSERT_LEAF off 380, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B0090B0, prev 0/5B009070, desc: INSERT_LEAF off 108, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B0090F8, prev 0/5B0090B0, desc: INSERT_LEAF off 381, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Heap2       len (rec/tot):    830/   830, tx:       1012, lsn: 0/5B009138, prev 0/5B0090F8, desc: MULTI_INSERT 6 tuples flags 0x02, blkref #0: rel 1663/17060/1249 blk 16
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B009478, prev 0/5B009138, desc: INSERT_LEAF off 108, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B0094C0, prev 0/5B009478, desc: INSERT_LEAF off 379, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B009500, prev 0/5B0094C0, desc: INSERT_LEAF off 112, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B009548, prev 0/5B009500, desc: INSERT_LEAF off 379, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B009588, prev 0/5B009548, desc: INSERT_LEAF off 108, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B0095D0, prev 0/5B009588, desc: INSERT_LEAF off 379, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B009610, prev 0/5B0095D0, desc: INSERT_LEAF off 113, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B009658, prev 0/5B009610, desc: INSERT_LEAF off 379, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B009698, prev 0/5B009658, desc: INSERT_LEAF off 108, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B0096E0, prev 0/5B009698, desc: INSERT_LEAF off 379, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B009720, prev 0/5B0096E0, desc: INSERT_LEAF off 114, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B009768, prev 0/5B009720, desc: INSERT_LEAF off 379, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Heap2       len (rec/tot):     57/  8205, tx:       1012, lsn: 0/5B0097A8, prev 0/5B009768, desc: MULTI_INSERT 1 tuples flags 0x03, blkref #0: rel 1663/17060/2608 blk 54 FPW
rmgr: Btree       len (rec/tot):     53/  5797, tx:       1012, lsn: 0/5B00B7D0, prev 0/5B0097A8, desc: INSERT_LEAF off 198, blkref #0: rel 1663/17060/2673 blk 42 FPW
rmgr: Btree       len (rec/tot):     53/  5937, tx:       1012, lsn: 0/5B00CE90, prev 0/5B00B7D0, desc: INSERT_LEAF off 95, blkref #0: rel 1663/17060/2674 blk 48 FPW
rmgr: Sequence    len (rec/tot):     99/    99, tx:       1012, lsn: 0/5B00E5E0, prev 0/5B00CE90, desc: LOG rel 1663/17060/17061, blkref #0: rel 1663/17060/17061 blk 0
rmgr: Heap        len (rec/tot):    104/   104, tx:       1012, lsn: 0/5B00E648, prev 0/5B00E5E0, desc: INSERT+INIT off 1 flags 0x00, blkref #0: rel 1663/17060/2224 blk 0
rmgr: Btree       len (rec/tot):     90/    90, tx:       1012, lsn: 0/5B00E6B0, prev 0/5B00E648, desc: NEWROOT lev 0, blkref #0: rel 1663/17060/5002 blk 1, blkref #2: rel 1663/17060/5002 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B00E710, prev 0/5B00E6B0, desc: INSERT_LEAF off 1, blkref #0: rel 1663/17060/5002 blk 1
rmgr: Standby     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B00E750, prev 0/5B00E710, desc: LOCK xid 1012 db 17060 rel 17062
rmgr: Storage     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B00E780, prev 0/5B00E750, desc: CREATE base/17060/17062
rmgr: Heap        len (rec/tot):     54/  8162, tx:       1012, lsn: 0/5B00E7B0, prev 0/5B00E780, desc: INSERT off 43 flags 0x01, blkref #0: rel 1663/17060/1247 blk 13 FPW
rmgr: Btree       len (rec/tot):     53/  4813, tx:       1012, lsn: 0/5B0107B0, prev 0/5B00E7B0, desc: INSERT_LEAF off 236, blkref #0: rel 1663/17060/2703 blk 2 FPW
rmgr: Btree       len (rec/tot):     53/  6137, tx:       1012, lsn: 0/5B011A80, prev 0/5B0107B0, desc: INSERT_LEAF off 166, blkref #0: rel 1663/17060/2704 blk 2 FPW
rmgr: Heap2       len (rec/tot):     57/  6921, tx:       1012, lsn: 0/5B013298, prev 0/5B011A80, desc: MULTI_INSERT 1 tuples flags 0x03, blkref #0: rel 1663/17060/2608 blk 64 FPW
rmgr: Btree       len (rec/tot):     53/  2269, tx:       1012, lsn: 0/5B014DC0, prev 0/5B013298, desc: INSERT_LEAF off 78, blkref #0: rel 1663/17060/2673 blk 40 FPW
rmgr: Btree       len (rec/tot):     53/  5321, tx:       1012, lsn: 0/5B0156A0, prev 0/5B014DC0, desc: INSERT_LEAF off 187, blkref #0: rel 1663/17060/2674 blk 52 FPW
rmgr: Heap        len (rec/tot):    211/   211, tx:       1012, lsn: 0/5B016B88, prev 0/5B0156A0, desc: INSERT+INIT off 1 flags 0x00, blkref #0: rel 1663/17060/1247 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B016C60, prev 0/5B016B88, desc: INSERT_LEAF off 236, blkref #0: rel 1663/17060/2703 blk 2
rmgr: Btree       len (rec/tot):     53/  6945, tx:       1012, lsn: 0/5B016CA0, prev 0/5B016C60, desc: INSERT_LEAF off 63, blkref #0: rel 1663/17060/2704 blk 4 FPW
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1012, lsn: 0/5B0187E0, prev 0/5B016CA0, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/2608 blk 64
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B018838, prev 0/5B0187E0, desc: INSERT_LEAF off 78, blkref #0: rel 1663/17060/2673 blk 40
rmgr: Btree       len (rec/tot):     53/  4117, tx:       1012, lsn: 0/5B018880, prev 0/5B018838, desc: INSERT_LEAF off 144, blkref #0: rel 1663/17060/2674 blk 50 FPW
rmgr: Heap        len (rec/tot):    203/   203, tx:       1012, lsn: 0/5B019898, prev 0/5B018880, desc: INSERT off 3 flags 0x00, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B019968, prev 0/5B019898, desc: INSERT_LEAF off 116, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B0199A8, prev 0/5B019968, desc: INSERT_LEAF off 103, blkref #0: rel 1663/17060/2663 blk 2
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B0199F0, prev 0/5B0199A8, desc: INSERT_LEAF off 181, blkref #0: rel 1663/17060/3455 blk 4
rmgr: Heap2       len (rec/tot):    180/   180, tx:       1012, lsn: 0/5B019A30, prev 0/5B0199F0, desc: MULTI_INSERT 1 tuples flags 0x00, blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap2       len (rec/tot):     65/  2901, tx:       1012, lsn: 0/5B019AE8, prev 0/5B019A30, desc: MULTI_INSERT 5 tuples flags 0x03, blkref #0: rel 1663/17060/1249 blk 54 FPW
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01A658, prev 0/5B019AE8, desc: INSERT_LEAF off 117, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01A698, prev 0/5B01A658, desc: INSERT_LEAF off 388, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01A6D8, prev 0/5B01A698, desc: INSERT_LEAF off 117, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01A720, prev 0/5B01A6D8, desc: INSERT_LEAF off 389, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01A760, prev 0/5B01A720, desc: INSERT_LEAF off 117, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01A7A8, prev 0/5B01A760, desc: INSERT_LEAF off 390, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01A7E8, prev 0/5B01A7A8, desc: INSERT_LEAF off 120, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01A830, prev 0/5B01A7E8, desc: INSERT_LEAF off 391, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01A870, prev 0/5B01A830, desc: INSERT_LEAF off 117, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01A8B8, prev 0/5B01A870, desc: INSERT_LEAF off 392, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01A8F8, prev 0/5B01A8B8, desc: INSERT_LEAF off 121, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01A940, prev 0/5B01A8F8, desc: INSERT_LEAF off 393, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Heap2       len (rec/tot):    830/   830, tx:       1012, lsn: 0/5B01A980, prev 0/5B01A940, desc: MULTI_INSERT 6 tuples flags 0x02, blkref #0: rel 1663/17060/1249 blk 54
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01ACC0, prev 0/5B01A980, desc: INSERT_LEAF off 119, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01AD08, prev 0/5B01ACC0, desc: INSERT_LEAF off 388, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01AD48, prev 0/5B01AD08, desc: INSERT_LEAF off 124, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01AD90, prev 0/5B01AD48, desc: INSERT_LEAF off 388, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01ADD0, prev 0/5B01AD90, desc: INSERT_LEAF off 119, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01AE18, prev 0/5B01ADD0, desc: INSERT_LEAF off 388, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01AE58, prev 0/5B01AE18, desc: INSERT_LEAF off 125, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01AEA0, prev 0/5B01AE58, desc: INSERT_LEAF off 388, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01AEE0, prev 0/5B01AEA0, desc: INSERT_LEAF off 119, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01AF28, prev 0/5B01AEE0, desc: INSERT_LEAF off 388, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01AF68, prev 0/5B01AF28, desc: INSERT_LEAF off 126, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01AFB0, prev 0/5B01AF68, desc: INSERT_LEAF off 388, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1012, lsn: 0/5B01AFF0, prev 0/5B01AFB0, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/2608 blk 64
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01B048, prev 0/5B01AFF0, desc: INSERT_LEAF off 199, blkref #0: rel 1663/17060/2673 blk 42
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01B090, prev 0/5B01B048, desc: INSERT_LEAF off 96, blkref #0: rel 1663/17060/2674 blk 48
rmgr: Heap        len (rec/tot):    512/   512, tx:       1012, lsn: 0/5B01B0D8, prev 0/5B01B090, desc: INSERT+INIT off 1 flags 0x00, blkref #0: rel 1663/17060/2604 blk 0
rmgr: Btree       len (rec/tot):     90/    90, tx:       1012, lsn: 0/5B01B2D8, prev 0/5B01B0D8, desc: NEWROOT lev 0, blkref #0: rel 1663/17060/2656 blk 1, blkref #2: rel 1663/17060/2656 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01B338, prev 0/5B01B2D8, desc: INSERT_LEAF off 1, blkref #0: rel 1663/17060/2656 blk 1
rmgr: Btree       len (rec/tot):     90/    90, tx:       1012, lsn: 0/5B01B378, prev 0/5B01B338, desc: NEWROOT lev 0, blkref #0: rel 1663/17060/2657 blk 1, blkref #2: rel 1663/17060/2657 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01B3D8, prev 0/5B01B378, desc: INSERT_LEAF off 1, blkref #0: rel 1663/17060/2657 blk 1
rmgr: Heap        len (rec/tot):     54/    54, tx:       1012, lsn: 0/5B01B418, prev 0/5B01B3D8, desc: LOCK off 47: xid 1012: flags 0x00 LOCK_ONLY EXCL_LOCK , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):    194/   194, tx:       1012, lsn: 0/5B01B450, prev 0/5B01B418, desc: UPDATE off 47 xmax 1012 flags 0x00 ; new off 26 xmax 0, blkref #0: rel 1663/17060/1249 blk 54, blkref #1: rel 1663/17060/1249 blk 16
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01B518, prev 0/5B01B450, desc: INSERT_LEAF off 124, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01B558, prev 0/5B01B518, desc: INSERT_LEAF off 395, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1012, lsn: 0/5B01B598, prev 0/5B01B558, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/2608 blk 64
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01B5F0, prev 0/5B01B598, desc: INSERT_LEAF off 200, blkref #0: rel 1663/17060/2673 blk 42
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01B638, prev 0/5B01B5F0, desc: INSERT_LEAF off 188, blkref #0: rel 1663/17060/2674 blk 52
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1012, lsn: 0/5B01B680, prev 0/5B01B638, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/2608 blk 64
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01B6D8, prev 0/5B01B680, desc: INSERT_LEAF off 201, blkref #0: rel 1663/17060/2673 blk 42
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01B720, prev 0/5B01B6D8, desc: INSERT_LEAF off 187, blkref #0: rel 1663/17060/2674 blk 52
rmgr: Standby     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B01B768, prev 0/5B01B720, desc: LOCK xid 1012 db 17060 rel 17066
rmgr: Storage     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B01B798, prev 0/5B01B768, desc: CREATE base/17060/17066
rmgr: Heap        len (rec/tot):    203/   203, tx:       1012, lsn: 0/5B01B7C8, prev 0/5B01B798, desc: INSERT off 4 flags 0x00, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01B898, prev 0/5B01B7C8, desc: INSERT_LEAF off 117, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     53/  3325, tx:       1012, lsn: 0/5B01B8D8, prev 0/5B01B898, desc: INSERT_LEAF off 71, blkref #0: rel 1663/17060/2663 blk 5 FPW
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01C5F0, prev 0/5B01B8D8, desc: INSERT_LEAF off 182, blkref #0: rel 1663/17060/3455 blk 4
rmgr: Heap2       len (rec/tot):    440/   440, tx:       1012, lsn: 0/5B01C630, prev 0/5B01C5F0, desc: MULTI_INSERT 3 tuples flags 0x02, blkref #0: rel 1663/17060/1249 blk 54
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01C7E8, prev 0/5B01C630, desc: INSERT_LEAF off 130, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01C830, prev 0/5B01C7E8, desc: INSERT_LEAF off 401, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01C870, prev 0/5B01C830, desc: INSERT_LEAF off 131, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01C8B8, prev 0/5B01C870, desc: INSERT_LEAF off 402, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01C8F8, prev 0/5B01C8B8, desc: INSERT_LEAF off 130, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01C940, prev 0/5B01C8F8, desc: INSERT_LEAF off 403, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Heap2       len (rec/tot):    830/   830, tx:       1012, lsn: 0/5B01C980, prev 0/5B01C940, desc: MULTI_INSERT 6 tuples flags 0x02, blkref #0: rel 1663/17060/1249 blk 54
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01CCC0, prev 0/5B01C980, desc: INSERT_LEAF off 133, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01CD08, prev 0/5B01CCC0, desc: INSERT_LEAF off 401, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01CD48, prev 0/5B01CD08, desc: INSERT_LEAF off 134, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01CD90, prev 0/5B01CD48, desc: INSERT_LEAF off 401, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01CDD0, prev 0/5B01CD90, desc: INSERT_LEAF off 133, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01CE18, prev 0/5B01CDD0, desc: INSERT_LEAF off 401, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01CE58, prev 0/5B01CE18, desc: INSERT_LEAF off 135, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01CEA0, prev 0/5B01CE58, desc: INSERT_LEAF off 401, blkref #0: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01CEE0, prev 0/5B01CEA0, desc: INSERT_LEAF off 133, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):    800/   800, tx:       1012, lsn: 0/5B01CF28, prev 0/5B01CEE0, desc: SPLIT_R level 0, firstrightoff 364, newitemoff 401, postingoff 0, blkref #0: rel 1663/17060/2659 blk 9, blkref #1: rel 1663/17060/2659 blk 10
rmgr: Btree       len (rec/tot):     61/   273, tx:       1012, lsn: 0/5B01D248, prev 0/5B01CF28, desc: INSERT_UPPER off 9, blkref #0: rel 1663/17060/2659 blk 3 FPW, blkref #1: rel 1663/17060/2659 blk 9
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01D360, prev 0/5B01D248, desc: INSERT_LEAF off 136, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01D3A8, prev 0/5B01D360, desc: INSERT_LEAF off 38, blkref #0: rel 1663/17060/2659 blk 10
rmgr: Storage     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B01D3E8, prev 0/5B01D3A8, desc: CREATE base/17060/17067
rmgr: Standby     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B01D418, prev 0/5B01D3E8, desc: LOCK xid 1012 db 17060 rel 17067
rmgr: Heap        len (rec/tot):    203/   203, tx:       1012, lsn: 0/5B01D448, prev 0/5B01D418, desc: INSERT off 5 flags 0x00, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01D518, prev 0/5B01D448, desc: INSERT_LEAF off 118, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     88/    88, tx:       1012, lsn: 0/5B01D558, prev 0/5B01D518, desc: INSERT_LEAF off 72, blkref #0: rel 1663/17060/2663 blk 5
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01D5B0, prev 0/5B01D558, desc: INSERT_LEAF off 183, blkref #0: rel 1663/17060/3455 blk 4
rmgr: Heap2       len (rec/tot):    310/   310, tx:       1012, lsn: 0/5B01D5F0, prev 0/5B01D5B0, desc: MULTI_INSERT 2 tuples flags 0x02, blkref #0: rel 1663/17060/1249 blk 54
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01D728, prev 0/5B01D5F0, desc: INSERT_LEAF off 139, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01D770, prev 0/5B01D728, desc: INSERT_LEAF off 47, blkref #0: rel 1663/17060/2659 blk 10
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B01D7B0, prev 0/5B01D770, desc: INSERT_LEAF off 140, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B01D7F8, prev 0/5B01D7B0, desc: INSERT_LEAF off 48, blkref #0: rel 1663/17060/2659 blk 10
rmgr: Heap        len (rec/tot):     54/  8014, tx:       1012, lsn: 0/5B01D838, prev 0/5B01D7F8, desc: INSERT off 35 flags 0x01, blkref #0: rel 1663/17060/2610 blk 0 FPW
rmgr: Btree       len (rec/tot):     53/  3213, tx:       1012, lsn: 0/5B01F7A0, prev 0/5B01D838, desc: INSERT_LEAF off 156, blkref #0: rel 1663/17060/2678 blk 1 FPW
rmgr: Btree       len (rec/tot):     53/  3213, tx:       1012, lsn: 0/5B020448, prev 0/5B01F7A0, desc: INSERT_LEAF off 156, blkref #0: rel 1663/17060/2679 blk 1 FPW
rmgr: Heap2       len (rec/tot):    121/   121, tx:       1012, lsn: 0/5B0210D8, prev 0/5B020448, desc: MULTI_INSERT 2 tuples flags 0x02, blkref #0: rel 1663/17060/2608 blk 64
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B021158, prev 0/5B0210D8, desc: INSERT_LEAF off 200, blkref #0: rel 1663/17060/2673 blk 42
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B0211A0, prev 0/5B021158, desc: INSERT_LEAF off 190, blkref #0: rel 1663/17060/2674 blk 52
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B0211E8, prev 0/5B0211A0, desc: INSERT_LEAF off 201, blkref #0: rel 1663/17060/2673 blk 42
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B021230, prev 0/5B0211E8, desc: INSERT_LEAF off 191, blkref #0: rel 1663/17060/2674 blk 52
rmgr: XLOG        len (rec/tot):     49/   137, tx:       1012, lsn: 0/5B021278, prev 0/5B021230, desc: FPI , blkref #0: rel 1663/17060/17067 blk 0 FPW
rmgr: Heap        len (rec/tot):    188/   188, tx:       1012, lsn: 0/5B021308, prev 0/5B021278, desc: INPLACE off 4, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap        len (rec/tot):    188/   188, tx:       1012, lsn: 0/5B0213C8, prev 0/5B021308, desc: INPLACE off 5, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap        len (rec/tot):     80/    80, tx:       1012, lsn: 0/5B021488, prev 0/5B0213C8, desc: HOT_UPDATE off 3 xmax 1012 flags 0x60 ; new off 6 xmax 0, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1012, lsn: 0/5B0214D8, prev 0/5B021488, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/2608 blk 64
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B021530, prev 0/5B0214D8, desc: INSERT_LEAF off 200, blkref #0: rel 1663/17060/2673 blk 42
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B021578, prev 0/5B021530, desc: INSERT_LEAF off 189, blkref #0: rel 1663/17060/2674 blk 52
rmgr: Storage     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B0215C0, prev 0/5B021578, desc: CREATE base/17060/17068
rmgr: Standby     len (rec/tot):     42/    42, tx:       1012, lsn: 0/5B0215F0, prev 0/5B0215C0, desc: LOCK xid 1012 db 17060 rel 17068
rmgr: Heap        len (rec/tot):    203/   203, tx:       1012, lsn: 0/5B021620, prev 0/5B0215F0, desc: INSERT off 7 flags 0x00, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B0216F0, prev 0/5B021620, desc: INSERT_LEAF off 119, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B021730, prev 0/5B0216F0, desc: INSERT_LEAF off 105, blkref #0: rel 1663/17060/2663 blk 2
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B021778, prev 0/5B021730, desc: INSERT_LEAF off 184, blkref #0: rel 1663/17060/3455 blk 4
rmgr: Heap2       len (rec/tot):    180/   180, tx:       1012, lsn: 0/5B0217B8, prev 0/5B021778, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/1249 blk 54
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B021870, prev 0/5B0217B8, desc: INSERT_LEAF off 141, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B0218B0, prev 0/5B021870, desc: INSERT_LEAF off 49, blkref #0: rel 1663/17060/2659 blk 10
rmgr: Heap        len (rec/tot):    197/   197, tx:       1012, lsn: 0/5B0218F0, prev 0/5B0218B0, desc: INSERT off 41 flags 0x00, blkref #0: rel 1663/17060/2610 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B0219B8, prev 0/5B0218F0, desc: INSERT_LEAF off 156, blkref #0: rel 1663/17060/2678 blk 1
rmgr: Btree       len (rec/tot):     64/    64, tx:       1012, lsn: 0/5B0219F8, prev 0/5B0219B8, desc: INSERT_LEAF off 157, blkref #0: rel 1663/17060/2679 blk 1
rmgr: Heap        len (rec/tot):     54/  3350, tx:       1012, lsn: 0/5B021A38, prev 0/5B0219F8, desc: INSERT off 12 flags 0x01, blkref #0: rel 1663/17060/2606 blk 2 FPW
rmgr: Btree       len (rec/tot):     53/  2253, tx:       1012, lsn: 0/5B022768, prev 0/5B021A38, desc: INSERT_LEAF off 108, blkref #0: rel 1663/17060/2579 blk 1 FPW
rmgr: Btree       len (rec/tot):     53/  5117, tx:       1012, lsn: 0/5B023038, prev 0/5B022768, desc: INSERT_LEAF off 107, blkref #0: rel 1663/17060/2664 blk 1 FPW
rmgr: Btree       len (rec/tot):     53/  5541, tx:       1012, lsn: 0/5B024450, prev 0/5B023038, desc: INSERT_LEAF off 108, blkref #0: rel 1663/17060/2665 blk 1 FPW
rmgr: Btree       len (rec/tot):     53/  2253, tx:       1012, lsn: 0/5B0259F8, prev 0/5B024450, desc: INSERT_LEAF off 106, blkref #0: rel 1663/17060/2666 blk 1 FPW
rmgr: Btree       len (rec/tot):     53/  2253, tx:       1012, lsn: 0/5B0262E0, prev 0/5B0259F8, desc: INSERT_LEAF off 108, blkref #0: rel 1663/17060/2667 blk 1 FPW
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1012, lsn: 0/5B026BB0, prev 0/5B0262E0, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/2608 blk 64
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B026C08, prev 0/5B026BB0, desc: INSERT_LEAF off 207, blkref #0: rel 1663/17060/2673 blk 42
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B026C50, prev 0/5B026C08, desc: INSERT_LEAF off 191, blkref #0: rel 1663/17060/2674 blk 52
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1012, lsn: 0/5B026C98, prev 0/5B026C50, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/2608 blk 64
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B026CF0, prev 0/5B026C98, desc: INSERT_LEAF off 203, blkref #0: rel 1663/17060/2673 blk 42
rmgr: Btree       len (rec/tot):     53/  4201, tx:       1012, lsn: 0/5B026D38, prev 0/5B026CF0, desc: INSERT_LEAF off 107, blkref #0: rel 1663/17060/2674 blk 30 FPW
rmgr: XLOG        len (rec/tot):     49/   137, tx:       1012, lsn: 0/5B027DA8, prev 0/5B026D38, desc: FPI , blkref #0: rel 1663/17060/17068 blk 0 FPW
rmgr: Heap        len (rec/tot):    188/   188, tx:       1012, lsn: 0/5B027E38, prev 0/5B027DA8, desc: INPLACE off 6, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap        len (rec/tot):    188/   188, tx:       1012, lsn: 0/5B027EF8, prev 0/5B027E38, desc: INPLACE off 7, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1012, lsn: 0/5B027FB8, prev 0/5B027EF8, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/2608 blk 64
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B028028, prev 0/5B027FB8, desc: INSERT_LEAF off 199, blkref #0: rel 1663/17060/2673 blk 42
rmgr: Btree       len (rec/tot):     72/    72, tx:       1012, lsn: 0/5B028070, prev 0/5B028028, desc: INSERT_LEAF off 192, blkref #0: rel 1663/17060/2674 blk 52
rmgr: Heap        len (rec/tot):     68/    68, tx:       1012, lsn: 0/5B0280B8, prev 0/5B028070, desc: HOT_UPDATE off 1 xmax 1012 flags 0x20 ; new off 2 xmax 0, blkref #0: rel 1663/17060/2224 blk 0
rmgr: Transaction len (rec/tot):   1925/  1925, tx:       1012, lsn: 0/5B028100, prev 0/5B0280B8, desc: COMMIT 2024-09-19 13:29:06.643535 MST; inval msgs: catcache 55 catcache 51 catcache 50 catcache 51 catcache 50 catcache 51 catcache 50 catcache 7 catcache 6 catcache 32 catcache 19 catcache 51 catcache 50 catcache 51 catcache 50 catcache 51 catcache 50 catcache 51 catcache 50 catcache 7 catcache 6 catcache 7 catcache 6 catcache 32 catcache 51 catcache 50 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 76 catcache 75 catcache 76 catcache 75 catcache 51 catcache 50 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 55 catcache 51 catcache 50 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 snapshot 2608 relcache 17062 relcache 17068 relcache 17068 relcache 17062 snapshot 2608 relcache 17062 snapshot 2608 relcache 17066 relcache 17067 relcache 17067 relcache 17066 snapshot 2608 relcache 17066 relcache 17062 snapshot 2608 snapshot 2608 relcache 17062 relcache 17061 snapshot 2608
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B028888, prev 0/5B028100, desc: RUNNING_XACTS nextXid 1013 latestCompletedXid 1012 oldestRunningXid 1013




 
[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "INSERT INTO ventas ( fecha, cliente_id, producto_id, cantidad, precio) SELECT  NOW() - INTERVAL '1 day' * (RANDOM() * 1000)::int, (RANDOM() * 1000)::int, (RANDOM() * 100)::int, (RANDOM() * 10)::int, (RANDOM() * 100)::numeric  FROM generate_series(1, 10); select * from ventas; "
INSERT 0 10

rmgr: Heap2       len (rec/tot):     56/    56, tx:          0, lsn: 0/5B0288C0, prev 0/5B028888, desc: PRUNE latestRemovedXid 0 nredirected 0 ndead 1, blkref #0: rel 1663/17060/1249 blk 16
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B0288F8, prev 0/5B0288C0, desc: RUNNING_XACTS nextXid 1013 latestCompletedXid 1012 oldestRunningXid 1013
rmgr: Sequence    len (rec/tot):     99/    99, tx:       1013, lsn: 0/5B028930, prev 0/5B0288F8, desc: LOG rel 1663/17060/17061, blkref #0: rel 1663/17060/17061 blk 0
rmgr: Heap        len (rec/tot):     88/    88, tx:       1013, lsn: 0/5B028998, prev 0/5B028930, desc: INSERT+INIT off 1 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     90/    90, tx:       1013, lsn: 0/5B0289F0, prev 0/5B028998, desc: NEWROOT lev 0, blkref #0: rel 1663/17060/17068 blk 1, blkref #2: rel 1663/17060/17068 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028A50, prev 0/5B0289F0, desc: INSERT_LEAF off 1, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Heap        len (rec/tot):     88/    88, tx:       1013, lsn: 0/5B028A90, prev 0/5B028A50, desc: INSERT off 2 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028AE8, prev 0/5B028A90, desc: INSERT_LEAF off 2, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Heap        len (rec/tot):     88/    88, tx:       1013, lsn: 0/5B028B28, prev 0/5B028AE8, desc: INSERT off 3 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028B80, prev 0/5B028B28, desc: INSERT_LEAF off 3, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Heap        len (rec/tot):     86/    86, tx:       1013, lsn: 0/5B028BC0, prev 0/5B028B80, desc: INSERT off 4 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028C18, prev 0/5B028BC0, desc: INSERT_LEAF off 4, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Heap        len (rec/tot):     88/    88, tx:       1013, lsn: 0/5B028C58, prev 0/5B028C18, desc: INSERT off 5 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028CB0, prev 0/5B028C58, desc: INSERT_LEAF off 5, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Heap        len (rec/tot):     88/    88, tx:       1013, lsn: 0/5B028CF0, prev 0/5B028CB0, desc: INSERT off 6 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028D48, prev 0/5B028CF0, desc: INSERT_LEAF off 6, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Heap        len (rec/tot):     88/    88, tx:       1013, lsn: 0/5B028D88, prev 0/5B028D48, desc: INSERT off 7 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028DE0, prev 0/5B028D88, desc: INSERT_LEAF off 7, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Heap        len (rec/tot):     88/    88, tx:       1013, lsn: 0/5B028E20, prev 0/5B028DE0, desc: INSERT off 8 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028E78, prev 0/5B028E20, desc: INSERT_LEAF off 8, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Heap        len (rec/tot):     88/    88, tx:       1013, lsn: 0/5B028EB8, prev 0/5B028E78, desc: INSERT off 9 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028F10, prev 0/5B028EB8, desc: INSERT_LEAF off 9, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Heap        len (rec/tot):     88/    88, tx:       1013, lsn: 0/5B028F50, prev 0/5B028F10, desc: INSERT off 10 flags 0x00, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1013, lsn: 0/5B028FA8, prev 0/5B028F50, desc: INSERT_LEAF off 10, blkref #0: rel 1663/17060/17068 blk 1
rmgr: Transaction len (rec/tot):     34/    34, tx:       1013, lsn: 0/5B028FE8, prev 0/5B028FA8, desc: COMMIT 2024-09-19 13:30:04.995277 MST
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B029010, prev 0/5B028FE8, desc: RUNNING_XACTS nextXid 1014 latestCompletedXid 1013 oldestRunningXid 1014








[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "delete from ventas where id >= 7; select * from ventas; "
DELETE 4


rmgr: Heap        len (rec/tot):     54/    54, tx:       1014, lsn: 0/5B029048, prev 0/5B029010, desc: DELETE off 7 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/17062 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1014, lsn: 0/5B029080, prev 0/5B029048, desc: DELETE off 8 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/17062 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1014, lsn: 0/5B0290B8, prev 0/5B029080, desc: DELETE off 9 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/17062 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1014, lsn: 0/5B0290F0, prev 0/5B0290B8, desc: DELETE off 10 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/17062 blk 0
rmgr: Transaction len (rec/tot):     34/    34, tx:       1014, lsn: 0/5B029128, prev 0/5B0290F0, desc: COMMIT 2024-09-19 13:31:45.395943 MST
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B029150, prev 0/5B029128, desc: RUNNING_XACTS nextXid 1015 latestCompletedXid 1014 oldestRunningXid 1015




[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "update ventas set producto_id = 5050 where id <= 2; select * from ventas; "
UPDATE 2
 id |   fecha    | cliente_id | producto_id | cantidad |      precio
----+------------+------------+-------------+----------+------------------
  3 | 2022-01-03 |        313 |          49 |        9 | 54.7796239938034
  4 | 2024-05-11 |        306 |          89 |        8 |  70.444649478393
  5 | 2022-12-15 |        834 |          17 |        7 | 34.1966019941825
  6 | 2022-10-08 |         86 |           1 |        6 | 39.7199323921129
  1 | 2022-03-04 |        339 |        5050 |        4 | 27.1322501550163
  2 | 2024-06-04 |         36 |        5050 |        2 | 73.8933668489125
(6 rows)




rmgr: Heap        len (rec/tot):     72/    72, tx:       1015, lsn: 0/5B029188, prev 0/5B029150, desc: HOT_UPDATE off 1 xmax 1015 flags 0x60 ; new off 11 xmax 0, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Heap        len (rec/tot):     72/    72, tx:       1015, lsn: 0/5B0291D0, prev 0/5B029188, desc: HOT_UPDATE off 2 xmax 1015 flags 0x60 ; new off 12 xmax 0, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Transaction len (rec/tot):     34/    34, tx:       1015, lsn: 0/5B029218, prev 0/5B0291D0, desc: COMMIT 2024-09-19 13:33:49.142672 MST
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B029240, prev 0/5B029218, desc: RUNNING_XACTS nextXid 1016 latestCompletedXid 1015 oldestRunningXid 1016





[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "truncate table ventas; select * from ventas; "
TRUNCATE TABLE
 id | fecha | cliente_id | producto_id | cantidad | precio
----+-------+------------+-------------+----------+--------
(0 rows)

rmgr: Heap        len (rec/tot):     72/    72, tx:       1015, lsn: 0/5B029188, prev 0/5B029150, desc: HOT_UPDATE off 1 xmax 1015 flags 0x60 ; new off 11 xmax 0, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Heap        len (rec/tot):     72/    72, tx:       1015, lsn: 0/5B0291D0, prev 0/5B029188, desc: HOT_UPDATE off 2 xmax 1015 flags 0x60 ; new off 12 xmax 0, blkref #0: rel 1663/17060/17062 blk 0
rmgr: Transaction len (rec/tot):     34/    34, tx:       1015, lsn: 0/5B029218, prev 0/5B0291D0, desc: COMMIT 2024-09-19 13:33:49.142672 MST
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B029240, prev 0/5B029218, desc: RUNNING_XACTS nextXid 1016 latestCompletedXid 1015 oldestRunningXid 1016
rmgr: Standby     len (rec/tot):     42/    42, tx:       1016, lsn: 0/5B029278, prev 0/5B029240, desc: LOCK xid 1016 db 17060 rel 17062
rmgr: Storage     len (rec/tot):     42/    42, tx:       1016, lsn: 0/5B0292A8, prev 0/5B029278, desc: CREATE base/17060/17070
rmgr: Heap        len (rec/tot):    123/   123, tx:       1016, lsn: 0/5B0292D8, prev 0/5B0292A8, desc: UPDATE off 6 xmax 1016 flags 0x60 ; new off 8 xmax 0, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1016, lsn: 0/5B029358, prev 0/5B0292D8, desc: INSERT_LEAF off 117, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1016, lsn: 0/5B029398, prev 0/5B029358, desc: INSERT_LEAF off 104, blkref #0: rel 1663/17060/2663 blk 2
rmgr: Btree       len (rec/tot):     64/    64, tx:       1016, lsn: 0/5B0293E0, prev 0/5B029398, desc: INSERT_LEAF off 185, blkref #0: rel 1663/17060/3455 blk 4
rmgr: Standby     len (rec/tot):     42/    42, tx:       1016, lsn: 0/5B029420, prev 0/5B0293E0, desc: LOCK xid 1016 db 17060 rel 17066
rmgr: Storage     len (rec/tot):     42/    42, tx:       1016, lsn: 0/5B029450, prev 0/5B029420, desc: CREATE base/17060/17071
rmgr: Heap        len (rec/tot):    123/   123, tx:       1016, lsn: 0/5B029480, prev 0/5B029450, desc: UPDATE off 4 xmax 1016 flags 0x60 ; new off 9 xmax 0, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1016, lsn: 0/5B029500, prev 0/5B029480, desc: INSERT_LEAF off 119, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     80/    80, tx:       1016, lsn: 0/5B029540, prev 0/5B029500, desc: INSERT_LEAF off 72, blkref #0: rel 1663/17060/2663 blk 5
rmgr: Btree       len (rec/tot):     64/    64, tx:       1016, lsn: 0/5B029590, prev 0/5B029540, desc: INSERT_LEAF off 186, blkref #0: rel 1663/17060/3455 blk 4
rmgr: Standby     len (rec/tot):     42/    42, tx:       1016, lsn: 0/5B0295D0, prev 0/5B029590, desc: LOCK xid 1016 db 17060 rel 17068
rmgr: Storage     len (rec/tot):     42/    42, tx:       1016, lsn: 0/5B029600, prev 0/5B0295D0, desc: CREATE base/17060/17072
rmgr: Heap        len (rec/tot):     94/    94, tx:       1016, lsn: 0/5B029630, prev 0/5B029600, desc: UPDATE off 7 xmax 1016 flags 0x60 ; new off 10 xmax 0, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1016, lsn: 0/5B029690, prev 0/5B029630, desc: INSERT_LEAF off 122, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1016, lsn: 0/5B0296D0, prev 0/5B029690, desc: INSERT_LEAF off 107, blkref #0: rel 1663/17060/2663 blk 2
rmgr: Btree       len (rec/tot):     64/    64, tx:       1016, lsn: 0/5B029718, prev 0/5B0296D0, desc: INSERT_LEAF off 187, blkref #0: rel 1663/17060/3455 blk 4
rmgr: XLOG        len (rec/tot):     49/   137, tx:       1016, lsn: 0/5B029758, prev 0/5B029718, desc: FPI , blkref #0: rel 1663/17060/17072 blk 0 FPW
rmgr: Standby     len (rec/tot):     42/    42, tx:       1016, lsn: 0/5B0297E8, prev 0/5B029758, desc: LOCK xid 1016 db 17060 rel 17067
rmgr: Storage     len (rec/tot):     42/    42, tx:       1016, lsn: 0/5B029818, prev 0/5B0297E8, desc: CREATE base/17060/17073
rmgr: Heap        len (rec/tot):     94/    94, tx:       1016, lsn: 0/5B029848, prev 0/5B029818, desc: UPDATE off 5 xmax 1016 flags 0x60 ; new off 11 xmax 0, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1016, lsn: 0/5B0298A8, prev 0/5B029848, desc: INSERT_LEAF off 121, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     88/    88, tx:       1016, lsn: 0/5B0298E8, prev 0/5B0298A8, desc: INSERT_LEAF off 74, blkref #0: rel 1663/17060/2663 blk 5
rmgr: Btree       len (rec/tot):     64/    64, tx:       1016, lsn: 0/5B029940, prev 0/5B0298E8, desc: INSERT_LEAF off 188, blkref #0: rel 1663/17060/3455 blk 4
rmgr: XLOG        len (rec/tot):     49/   137, tx:       1016, lsn: 0/5B029980, prev 0/5B029940, desc: FPI , blkref #0: rel 1663/17060/17073 blk 0 FPW
rmgr: Standby     len (rec/tot):     78/    78, tx:          0, lsn: 0/5B029A10, prev 0/5B029980, desc: LOCK xid 1016 db 17060 rel 17068 xid 1016 db 17060 rel 17062 xid 1016 db 17060 rel 17067 xid 1016 db 17060 rel 17066
rmgr: Standby     len (rec/tot):     54/    54, tx:          0, lsn: 0/5B029A60, prev 0/5B029A10, desc: RUNNING_XACTS nextXid 1017 latestCompletedXid 1015 oldestRunningXid 1016; 1 xacts: 1016
rmgr: Transaction len (rec/tot):    361/   361, tx:       1016, lsn: 0/5B029A98, prev 0/5B029A60, desc: COMMIT 2024-09-19 13:35:50.285460 MST; rels: base/17060/17067 base/17060/17068 base/17060/17066 base/17060/17062; inval msgs: catcache 51 catcache 50 catcache 51 catcache 50 catcache 51 catcache 50 catcache 51 catcache 50 relcache 17066 relcache 17067 relcache 17067 relcache 17062 relcache 17068 relcache 17068 relcache 17066 relcache 17062



[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "alter table ventas rename to ventas_new; select * from ventas; "
ALTER TABLE
ERROR:  relation "ventas" does not exist
LINE 1: ...er table ventas rename to ventas_new; select * from ventas;
                                                               ^

rmgr: Standby     len (rec/tot):     42/    42, tx:       1018, lsn: 0/5B02A090, prev 0/5B02A058, desc: LOCK xid 1018 db 17060 rel 17062
rmgr: Heap        len (rec/tot):     82/    82, tx:       1018, lsn: 0/5B02A0C0, prev 0/5B02A090, desc: UPDATE off 8 xmax 1018 flags 0x60 KEYS_UPDATED ; new off 13 xmax 0, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1018, lsn: 0/5B02A118, prev 0/5B02A0C0, desc: INSERT_LEAF off 119, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1018, lsn: 0/5B02A158, prev 0/5B02A118, desc: INSERT_LEAF off 107, blkref #0: rel 1663/17060/2663 blk 2
rmgr: Btree       len (rec/tot):     64/    64, tx:       1018, lsn: 0/5B02A1A0, prev 0/5B02A158, desc: INSERT_LEAF off 187, blkref #0: rel 1663/17060/3455 blk 4
rmgr: Heap        len (rec/tot):     54/    54, tx:       1018, lsn: 0/5B02A1E0, prev 0/5B02A1A0, desc: LOCK off 43: xid 1018: flags 0x00 LOCK_ONLY EXCL_LOCK KEYS_UPDATED , blkref #0: rel 1663/17060/1247 blk 13
rmgr: Heap        len (rec/tot):    230/   230, tx:       1018, lsn: 0/5B02A218, prev 0/5B02A1E0, desc: UPDATE off 43 xmax 1018 flags 0x00 KEYS_UPDATED ; new off 4 xmax 0, blkref #0: rel 1663/17060/1247 blk 14, blkref #1: rel 1663/17060/1247 blk 13
rmgr: Btree       len (rec/tot):     64/    64, tx:       1018, lsn: 0/5B02A300, prev 0/5B02A218, desc: INSERT_LEAF off 240, blkref #0: rel 1663/17060/2703 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1018, lsn: 0/5B02A340, prev 0/5B02A300, desc: INSERT_LEAF off 168, blkref #0: rel 1663/17060/2704 blk 2
rmgr: Heap        len (rec/tot):     82/    82, tx:       1018, lsn: 0/5B02A388, prev 0/5B02A340, desc: UPDATE off 1 xmax 1018 flags 0x60 KEYS_UPDATED ; new off 5 xmax 0, blkref #0: rel 1663/17060/1247 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1018, lsn: 0/5B02A3E0, prev 0/5B02A388, desc: INSERT_LEAF off 238, blkref #0: rel 1663/17060/2703 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1018, lsn: 0/5B02A420, prev 0/5B02A3E0, desc: INSERT_LEAF off 65, blkref #0: rel 1663/17060/2704 blk 4
rmgr: Transaction len (rec/tot):     38/    38, tx:       1018, lsn: 0/5B02A468, prev 0/5B02A420, desc: ABORT 2024-09-19 13:38:42.675070 MST
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B02A490, prev 0/5B02A468, desc: RUNNING_XACTS nextXid 1019 latestCompletedXid 1018 oldestRunningXid 1019



[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "alter table ventas rename to ventas_new; select * from ventas_new; "
ALTER TABLE


rmgr: Standby     len (rec/tot):     42/    42, tx:       1019, lsn: 0/5B02A4C8, prev 0/5B02A490, desc: LOCK xid 1019 db 17060 rel 17062
rmgr: Heap        len (rec/tot):     82/    82, tx:       1019, lsn: 0/5B02A4F8, prev 0/5B02A4C8, desc: UPDATE off 8 xmax 1019 flags 0x60 KEYS_UPDATED ; new off 14 xmax 0, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Btree       len (rec/tot):     64/    64, tx:       1019, lsn: 0/5B02A550, prev 0/5B02A4F8, desc: INSERT_LEAF off 120, blkref #0: rel 1663/17060/2662 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1019, lsn: 0/5B02A590, prev 0/5B02A550, desc: INSERT_LEAF off 108, blkref #0: rel 1663/17060/2663 blk 2
rmgr: Btree       len (rec/tot):     64/    64, tx:       1019, lsn: 0/5B02A5D8, prev 0/5B02A590, desc: INSERT_LEAF off 188, blkref #0: rel 1663/17060/3455 blk 4
rmgr: Heap        len (rec/tot):     54/    54, tx:       1019, lsn: 0/5B02A618, prev 0/5B02A5D8, desc: LOCK off 43: xid 1019: flags 0x00 LOCK_ONLY EXCL_LOCK KEYS_UPDATED , blkref #0: rel 1663/17060/1247 blk 13
rmgr: Heap        len (rec/tot):    230/   230, tx:       1019, lsn: 0/5B02A650, prev 0/5B02A618, desc: UPDATE off 43 xmax 1019 flags 0x00 KEYS_UPDATED ; new off 6 xmax 0, blkref #0: rel 1663/17060/1247 blk 14, blkref #1: rel 1663/17060/1247 blk 13
rmgr: Btree       len (rec/tot):     64/    64, tx:       1019, lsn: 0/5B02A738, prev 0/5B02A650, desc: INSERT_LEAF off 242, blkref #0: rel 1663/17060/2703 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1019, lsn: 0/5B02A778, prev 0/5B02A738, desc: INSERT_LEAF off 169, blkref #0: rel 1663/17060/2704 blk 2
rmgr: Heap        len (rec/tot):     82/    82, tx:       1019, lsn: 0/5B02A7C0, prev 0/5B02A778, desc: UPDATE off 1 xmax 1019 flags 0x60 KEYS_UPDATED ; new off 7 xmax 0, blkref #0: rel 1663/17060/1247 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1019, lsn: 0/5B02A818, prev 0/5B02A7C0, desc: INSERT_LEAF off 239, blkref #0: rel 1663/17060/2703 blk 2
rmgr: Btree       len (rec/tot):     72/    72, tx:       1019, lsn: 0/5B02A858, prev 0/5B02A818, desc: INSERT_LEAF off 66, blkref #0: rel 1663/17060/2704 blk 4
rmgr: Transaction len (rec/tot):    210/   210, tx:       1019, lsn: 0/5B02A8A0, prev 0/5B02A858, desc: COMMIT 2024-09-19 13:38:59.432403 MST; inval msgs: catcache 51 catcache 50 catcache 50 catcache 76 catcache 75 catcache 75 catcache 76 catcache 75 catcache 75 relcache 17062
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B02A978, prev 0/5B02A8A0, desc: RUNNING_XACTS nextXid 1020 latestCompletedXid 1019 oldestRunningXid 1020




[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "alter table ventas_new add column new_column int; select * from ventas_new; "
ALTER TABLE
 id | fecha | cliente_id | producto_id | cantidad | precio | new_column
----+-------+------------+-------------+----------+--------+------------
(0 rows)


rmgr: Standby     len (rec/tot):     42/    42, tx:       1020, lsn: 0/5B02A9B0, prev 0/5B02A978, desc: LOCK xid 1020 db 17060 rel 17062
rmgr: Heap2       len (rec/tot):    180/   180, tx:       1020, lsn: 0/5B02A9E0, prev 0/5B02A9B0, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/17060/1249 blk 54
rmgr: Btree       len (rec/tot):     72/    72, tx:       1020, lsn: 0/5B02AA98, prev 0/5B02A9E0, desc: INSERT_LEAF off 125, blkref #0: rel 1663/17060/2658 blk 14
rmgr: Btree       len (rec/tot):     64/    64, tx:       1020, lsn: 0/5B02AAE0, prev 0/5B02AA98, desc: INSERT_LEAF off 38, blkref #0: rel 1663/17060/2659 blk 10
rmgr: Heap        len (rec/tot):     79/    79, tx:       1020, lsn: 0/5B02AB20, prev 0/5B02AAE0, desc: HOT_UPDATE off 14 xmax 1020 flags 0x60 ; new off 15 xmax 0, blkref #0: rel 1663/17060/1259 blk 0
rmgr: Transaction len (rec/tot):    130/   130, tx:       1020, lsn: 0/5B02AB70, prev 0/5B02AB20, desc: COMMIT 2024-09-19 13:40:16.390701 MST; inval msgs: catcache 7 catcache 6 catcache 51 catcache 50 relcache 17062
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B02ABF8, prev 0/5B02AB70, desc: RUNNING_XACTS nextXid 1021 latestCompletedXid 1020 oldestRunningXid 1021



[postgres@SERVER_TEST pg_log]$  psql -X -p 5414 -d test_checkpoint -c "drop table ventas_new;   "
DROP TABLE



rmgr: Standby     len (rec/tot):     42/    42, tx:       1021, lsn: 0/5B02AC30, prev 0/5B02ABF8, desc: LOCK xid 1021 db 17060 rel 17062
rmgr: Standby     len (rec/tot):     42/    42, tx:       1021, lsn: 0/5B02AC60, prev 0/5B02AC30, desc: LOCK xid 1021 db 17060 rel 17066
rmgr: Standby     len (rec/tot):     42/    42, tx:       1021, lsn: 0/5B02AC90, prev 0/5B02AC60, desc: LOCK xid 1021 db 17060 rel 17061
rmgr: Standby     len (rec/tot):     42/    42, tx:       1021, lsn: 0/5B02ACC0, prev 0/5B02AC90, desc: LOCK xid 1021 db 17060 rel 17068
rmgr: Standby     len (rec/tot):     42/    42, tx:       1021, lsn: 0/5B02ACF0, prev 0/5B02ACC0, desc: LOCK xid 1021 db 17060 rel 17067
rmgr: Heap2       len (rec/tot):     56/    56, tx:       1021, lsn: 0/5B02AD20, prev 0/5B02ACF0, desc: PRUNE latestRemovedXid 1019 nredirected 0 ndead 1, blkref #0: rel 1663/17060/1247 blk 13
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AD58, prev 0/5B02AD20, desc: DELETE off 41 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2610 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AD90, prev 0/5B02AD58, desc: DELETE off 38 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02ADC8, prev 0/5B02AD90, desc: DELETE off 10 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AE00, prev 0/5B02ADC8, desc: DELETE off 123 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AE38, prev 0/5B02AE00, desc: DELETE off 12 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2606 blk 2
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AE70, prev 0/5B02AE38, desc: DELETE off 122 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AEA8, prev 0/5B02AE70, desc: DELETE off 35 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2610 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AEE0, prev 0/5B02AEA8, desc: DELETE off 36 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AF18, prev 0/5B02AEE0, desc: DELETE off 37 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AF50, prev 0/5B02AF18, desc: DELETE off 11 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AF88, prev 0/5B02AF50, desc: DELETE off 119 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AFC0, prev 0/5B02AF88, desc: DELETE off 120 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02AFF8, prev 0/5B02AFC0, desc: DELETE off 35 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B030, prev 0/5B02AFF8, desc: DELETE off 34 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B068, prev 0/5B02B030, desc: DELETE off 33 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B0A0, prev 0/5B02B068, desc: DELETE off 32 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B0D8, prev 0/5B02B0A0, desc: DELETE off 31 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B110, prev 0/5B02B0D8, desc: DELETE off 30 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B148, prev 0/5B02B110, desc: DELETE off 27 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B180, prev 0/5B02B148, desc: DELETE off 28 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B1B8, prev 0/5B02B180, desc: DELETE off 29 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B1F0, prev 0/5B02B1B8, desc: DELETE off 9 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B228, prev 0/5B02B1F0, desc: DELETE off 121 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B260, prev 0/5B02B228, desc: DELETE off 1 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2604 blk 0
rmgr: Heap        len (rec/tot):     79/    79, tx:       1021, lsn: 0/5B02B298, prev 0/5B02B260, desc: HOT_UPDATE off 26 xmax 1021 flags 0x60 ; new off 40 xmax 0, blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B2E8, prev 0/5B02B298, desc: DELETE off 117 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B320, prev 0/5B02B2E8, desc: DELETE off 118 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B358, prev 0/5B02B320, desc: DELETE off 7 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1247 blk 14
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B390, prev 0/5B02B358, desc: DELETE off 115 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B3C8, prev 0/5B02B390, desc: DELETE off 6 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1247 blk 14
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B400, prev 0/5B02B3C8, desc: DELETE off 114 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B438, prev 0/5B02B400, desc: DELETE off 46 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B470, prev 0/5B02B438, desc: DELETE off 45 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B4A8, prev 0/5B02B470, desc: DELETE off 43 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B4E0, prev 0/5B02B4A8, desc: DELETE off 42 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B518, prev 0/5B02B4E0, desc: DELETE off 41 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B550, prev 0/5B02B518, desc: DELETE off 40 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B588, prev 0/5B02B550, desc: DELETE off 37 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B5C0, prev 0/5B02B588, desc: DELETE off 38 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B5F8, prev 0/5B02B5C0, desc: DELETE off 39 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 16
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B630, prev 0/5B02B5F8, desc: DELETE off 2 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B668, prev 0/5B02B630, desc: DELETE off 2 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2224 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B6A0, prev 0/5B02B668, desc: DELETE off 89 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B6D8, prev 0/5B02B6A0, desc: DELETE off 124 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B710, prev 0/5B02B6D8, desc: DELETE off 25 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B748, prev 0/5B02B710, desc: DELETE off 24 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B780, prev 0/5B02B748, desc: DELETE off 23 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B7B8, prev 0/5B02B780, desc: DELETE off 22 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B7F0, prev 0/5B02B7B8, desc: DELETE off 21 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B828, prev 0/5B02B7F0, desc: DELETE off 20 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B860, prev 0/5B02B828, desc: DELETE off 40 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B898, prev 0/5B02B860, desc: DELETE off 15 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B8D0, prev 0/5B02B898, desc: DELETE off 16 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B908, prev 0/5B02B8D0, desc: DELETE off 17 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B940, prev 0/5B02B908, desc: DELETE off 18 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B978, prev 0/5B02B940, desc: DELETE off 19 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B9B0, prev 0/5B02B978, desc: DELETE off 39 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1249 blk 54
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02B9E8, prev 0/5B02B9B0, desc: DELETE off 15 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/1259 blk 0
rmgr: Heap        len (rec/tot):     54/    54, tx:       1021, lsn: 0/5B02BA20, prev 0/5B02B9E8, desc: DELETE off 116 flags 0x00 KEYS_UPDATED , blkref #0: rel 1663/17060/2608 blk 64
rmgr: Transaction len (rec/tot):   1797/  1797, tx:       1021, lsn: 0/5B02BA58, prev 0/5B02BA20, desc: COMMIT 2024-09-19 13:41:48.437736 MST; rels: base/17060/17070 base/17060/17061 base/17060/17071 base/17060/17073 base/17060/17072; inval msgs: catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 51 catcache 50 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 51 catcache 50 catcache 55 catcache 76 catcache 75 catcache 76 catcache 75 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 51 catcache 50 catcache 32 catcache 7 catcache 6 catcache 7 catcache 6 catcache 51 catcache 50 catcache 19 catcache 32 catcache 7 catcache 6 catcache 51 catcache 50 relcache 17062 snapshot 2608 relcache 17061 snapshot 2608 snapshot 2608 snapshot 2608 relcache 17062 snapshot 2608 relcache 17066 snapshot 2608 relcache 17067 relcache 17066 snapshot 2608 snapshot 2608 relcache 17068 relcache 17062 snapshot 2608
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B02C178, prev 0/5B02BA58, desc: RUNNING_XACTS nextXid 1022 latestCompletedXid 1021 oldestRunningXid 1022



 





[postgres@SERVER_TEST pg_log]$ $PGBIN14/pg_controldata -D $PGDATA14
pg_controldata: error: could not open file "/sysx/data/global/pg_control" for reading: No such file or directory
[postgres@SERVER_TEST pg_log]$ pg_controldata -D /sysx/data14
pg_control version number:            1300
Catalog version number:               202107181
Database system identifier:           7381508807802424143
Database cluster state:               in production
pg_control last modified:             Thu 19 Sep 2024 01:28:13 PM MST
Latest checkpoint location:           0/5B0018F0
Latest checkpoint's REDO location:    0/5B0018B8
Latest checkpoint's REDO WAL file:    00000001000000000000005B
Latest checkpoint's TimeLineID:       1
Latest checkpoint's PrevTimeLineID:   1
Latest checkpoint's full_page_writes: on
Latest checkpoint's NextXID:          0:1012
Latest checkpoint's NextOID:          25252
Latest checkpoint's NextMultiXactId:  1
Latest checkpoint's NextMultiOffset:  0
Latest checkpoint's oldestXID:        726
Latest checkpoint's oldestXID's DB:   1
Latest checkpoint's oldestActiveXID:  1011
Latest checkpoint's oldestMultiXid:   1
Latest checkpoint's oldestMulti's DB: 1
Latest checkpoint's oldestCommitTsXid:0
Latest checkpoint's newestCommitTsXid:0
Time of latest checkpoint:            Thu 19 Sep 2024 01:28:13 PM MST
Fake LSN counter for unlogged rels:   0/3E8
Minimum recovery ending location:     0/0
Min recovery ending loc's timeline:   0
Backup start location:                0/0
Backup end location:                  0/0
End-of-backup record required:        no
wal_level setting:                    replica
wal_log_hints setting:                off
max_connections setting:              100
max_worker_processes setting:         8
max_wal_senders setting:              10
max_prepared_xacts setting:           0
max_locks_per_xact setting:           64
track_commit_timestamp setting:       off
Maximum data alignment:               8
Database block size:                  8192
Blocks per segment of large relation: 131072
WAL block size:                       8192
Bytes per WAL segment:                16777216
Maximum length of identifiers:        64
Maximum columns in an index:          32
Maximum size of a TOAST chunk:        1996
Size of a large-object chunk:         2048
Date/time type storage:               64-bit integers
Float8 argument passing:              by value
Data page checksum version:           0
Mock authentication nonce:            93f8792f52798067b0cee85475ba6ed9ee6cc3d6aa17d8d7c1eacdf535ced484




[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "CHECKPOINT;"
CHECKPOINT


rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B02C1B0, prev 0/5B02C178, desc: RUNNING_XACTS nextXid 1022 latestCompletedXid 1021 oldestRunningXid 1022
rmgr: XLOG        len (rec/tot):    114/   114, tx:          0, lsn: 0/5B02C1E8, prev 0/5B02C1B0, desc: CHECKPOINT_ONLINE redo 0/5B02C1B0; tli 1; prev tli 1; fpw true; xid 0:1022; oid 25252; multi 1; offset 0; oldest xid 726 in DB 1; oldest multi 1 in DB 1; oldest/newest commit timestamp xid: 0/0; oldest running xid 1022; online
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 0/5B02C260, prev 0/5B02C1E8, desc: RUNNING_XACTS nextXid 1022 latestCompletedXid 1021 oldestRunningXid 1022




[postgres@SERVER_TEST pg_log]$ $PGBIN14/pg_controldata -D $PGDATA14
pg_control version number:            1300
Catalog version number:               202107181
Database system identifier:           7381508807802424143
Database cluster state:               in production
pg_control last modified:             Thu 19 Sep 2024 01:45:48 PM MST
Latest checkpoint location:           0/5B02C1E8
Latest checkpoint's REDO location:    0/5B02C1B0
Latest checkpoint's REDO WAL file:    00000001000000000000005B   <---- Este es el archivo donde se hizo el checkpoint 
Latest checkpoint's TimeLineID:       1
Latest checkpoint's PrevTimeLineID:   1
Latest checkpoint's full_page_writes: on
Latest checkpoint's NextXID:          0:1022
Latest checkpoint's NextOID:          25252
Latest checkpoint's NextMultiXactId:  1
Latest checkpoint's NextMultiOffset:  0
Latest checkpoint's oldestXID:        726
Latest checkpoint's oldestXID's DB:   1
Latest checkpoint's oldestActiveXID:  1022
Latest checkpoint's oldestMultiXid:   1
Latest checkpoint's oldestMulti's DB: 1
Latest checkpoint's oldestCommitTsXid:0
Latest checkpoint's newestCommitTsXid:0
Time of latest checkpoint:            Thu 19 Sep 2024 01:45:48 PM MST
Fake LSN counter for unlogged rels:   0/3E8
Minimum recovery ending location:     0/0
Min recovery ending loc's timeline:   0
Backup start location:                0/0
Backup end location:                  0/0
End-of-backup record required:        no
wal_level setting:                    replica
wal_log_hints setting:                off
max_connections setting:              100
max_worker_processes setting:         8
max_wal_senders setting:              10
max_prepared_xacts setting:           0
max_locks_per_xact setting:           64
track_commit_timestamp setting:       off
Maximum data alignment:               8
Database block size:                  8192
Blocks per segment of large relation: 131072
WAL block size:                       8192
Bytes per WAL segment:                16777216
Maximum length of identifiers:        64
Maximum columns in an index:          32
Maximum size of a TOAST chunk:        1996
Size of a large-object chunk:         2048
Date/time type storage:               64-bit integers
Float8 argument passing:              by value
Data page checksum version:           0
Mock authentication nonce:            93f8792f52798067b0cee85475ba6ed9ee6cc3d6aa17d8d7c1eacdf535ced484




[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "CREATE TABLE ventas (
     id SERIAL PRIMARY KEY ,
     fecha DATE,
     cliente_id INTEGER,
     producto_id INTEGER,
     cantidad INTEGER,
     precio NUMERIC
 );

 INSERT INTO ventas ( fecha, cliente_id, producto_id, cantidad, precio)
 SELECT
       NOW() - INTERVAL '1 day' * (RANDOM() * 1000)::int,
       (RANDOM() * 1000)::int,
       (RANDOM() * 100)::int,
       (RANDOM() * 10)::int,
       (RANDOM() * 100)::numeric
   FROM generate_series(1, 190000);"
CREATE TABLE
INSERT 0 190000




[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 32M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 13:55 00000001000000000000005B
-rw-------. 1 postgres postgres 16M Sep 19 13:55 00000001000000000000005C

  

[postgres@SERVER_TEST pg_wal]$ pg_archivecleanup -n  /sysx/data14/pg_wal 00000001000000000000005B
[postgres@SERVER_TEST pg_wal]$ pg_archivecleanup -n  /sysx/data14/pg_wal 00000001000000000000005C
/sysx/data14/pg_wal/00000001000000000000005B
[postgres@SERVER_TEST pg_wal]$



[postgres@SERVER_TEST pg_wal]$  psql -X -p 5414 -d test_checkpoint -c "CHECKPOINT;"
CHECKPOINT
[postgres@SERVER_TEST pg_wal]$
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_controldata -D $PGDATA14
pg_control version number:            1300
Catalog version number:               202107181
Database system identifier:           7381508807802424143
Database cluster state:               in production
pg_control last modified:             Thu 19 Sep 2024 01:59:21 PM MST
Latest checkpoint location:           0/5C2776B8
Latest checkpoint's REDO location:    0/5C277680
Latest checkpoint's REDO WAL file:    00000001000000000000005C <---- ahora esta en este archivo 
Latest checkpoint's TimeLineID:       1
Latest checkpoint's PrevTimeLineID:   1
Latest checkpoint's full_page_writes: on
Latest checkpoint's NextXID:          0:1027
Latest checkpoint's NextOID:          25252
Latest checkpoint's NextMultiXactId:  1
Latest checkpoint's NextMultiOffset:  0
Latest checkpoint's oldestXID:        726
Latest checkpoint's oldestXID's DB:   1
Latest checkpoint's oldestActiveXID:  1027
Latest checkpoint's oldestMultiXid:   1
Latest checkpoint's oldestMulti's DB: 1
Latest checkpoint's oldestCommitTsXid:0
Latest checkpoint's newestCommitTsXid:0
Time of latest checkpoint:            Thu 19 Sep 2024 01:59:21 PM MST
Fake LSN counter for unlogged rels:   0/3E8
Minimum recovery ending location:     0/0
Min recovery ending loc's timeline:   0
Backup start location:                0/0
Backup end location:                  0/0
End-of-backup record required:        no
wal_level setting:                    replica
wal_log_hints setting:                off
max_connections setting:              100
max_worker_processes setting:         8
max_wal_senders setting:              10
max_prepared_xacts setting:           0
max_locks_per_xact setting:           64
track_commit_timestamp setting:       off
Maximum data alignment:               8
Database block size:                  8192
Blocks per segment of large relation: 131072
WAL block size:                       8192
Bytes per WAL segment:                16777216
Maximum length of identifiers:        64
Maximum columns in an index:          32
Maximum size of a TOAST chunk:        1996
Size of a large-object chunk:         2048
Date/time type storage:               64-bit integers
Float8 argument passing:              by value
Data page checksum version:           0
Mock authentication nonce:            93f8792f52798067b0cee85475ba6ed9ee6cc3d6aa17d8d7c1eacdf535ced484
[postgres@SERVER_TEST pg_wal]$



[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 32M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 13:55 00000001000000000000005D
-rw-------. 1 postgres postgres 16M Sep 19 13:59 00000001000000000000005C



[postgres@SERVER_TEST pg_wal]$  pg_archivecleanup -n  /sysx/data14/pg_wal 00000001000000000000005C
[postgres@SERVER_TEST pg_wal]$  pg_archivecleanup -n  /sysx/data14/pg_wal 00000001000000000000005D
/sysx/data14/pg_wal/00000001000000000000005C


[postgres@SERVER_TEST pg_wal]$ pg_archivecleanup -d  /sysx/data14/pg_wal 00000001000000000000005D
pg_archivecleanup: keeping WAL file "/sysx/data14/pg_wal/00000001000000000000005D" and later
pg_archivecleanup: removing file "/sysx/data14/pg_wal/00000001000000000000005C"




[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_ctl stop -D $PGDATA14
waiting for server to shut down.... done
server stopped
[postgres@SERVER_TEST pg_wal]$


----- CORROMPI LOS WALS 
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-19 14:05:00 MST     1683505 66ec91fc.19b031 >LOG:  redirecting log output to logging collector process
<2024-09-19 14:05:00 MST     1683505 66ec91fc.19b031 >HINT:  Future log output will appear in directory "pg_log".
. stopped waiting
pg_ctl: could not start server
Examine the log output.



[postgres@SERVER_TEST pg_log]$ cat postgresql-240919.log | tail  -n 10
<2024-09-19 15:00:59 MST     1686893 66ec9f1b.19bd6d >LOG:  listening on IPv4 address "0.0.0.0", port 5414
<2024-09-19 15:00:59 MST     1686893 66ec9f1b.19bd6d >LOG:  listening on IPv6 address "::", port 5414
<2024-09-19 15:00:59 MST     1686893 66ec9f1b.19bd6d >LOG:  listening on Unix socket "/run/postgresql/.s.PGSQL.5414"
<2024-09-19 15:00:59 MST     1686893 66ec9f1b.19bd6d >LOG:  listening on Unix socket "/tmp/.s.PGSQL.5414"
<2024-09-19 15:00:59 MST     1686895 66ec9f1b.19bd6f >LOG:  database system was shut down at 2024-09-19 14:04:51 MST
<2024-09-19 15:00:59 MST     1686895 66ec9f1b.19bd6f >LOG:  invalid primary checkpoint record
<2024-09-19 15:00:59 MST     1686895 66ec9f1b.19bd6f >PANIC:  could not locate a valid checkpoint record           
<2024-09-19 15:01:00 MST     1686893 66ec9f1b.19bd6d >LOG:  startup process (PID 1686895) was terminated by signal 6: Aborted
<2024-09-19 15:01:00 MST     1686893 66ec9f1b.19bd6d >LOG:  aborting startup due to startup process failure
<2024-09-19 15:01:00 MST     1686893 66ec9f1b.19bd6d >LOG:  database system is shut down











 

[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl stop -D $PGDATA14
waiting for server to shut down.... done
server stopped

[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_resetwal -f -D $PGDATA14
Write-ahead log reset


[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-19 15:29:10 MST     1689854 66eca5b6.19c8fe >LOG:  redirecting log output to logging collector process
<2024-09-19 15:29:10 MST     1689854 66eca5b6.19c8fe >HINT:  Future log output will appear in directory "pg_log".
 done
server started


[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 16M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:29 000000010000000000000091

 
[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "DROP TABLE ventas; CREATE TABLE ventas (
     id SERIAL PRIMARY KEY ,
     fecha DATE,
     cliente_id INTEGER,
     producto_id INTEGER,
     cantidad INTEGER,
     precio NUMERIC
 );

 INSERT INTO ventas ( fecha, cliente_id, producto_id, cantidad, precio)
 SELECT
       NOW() - INTERVAL '1 day' * (RANDOM() * 1000)::int,
       (RANDOM() * 1000)::int,
       (RANDOM() * 100)::int,
       (RANDOM() * 10)::int,
       (RANDOM() * 100)::numeric
   FROM generate_series(1, 190000);"
DROP TABLE
CREATE TABLE
INSERT 0 190000

 
[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 32M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:29 000000010000000000000091
-rw-------. 1 postgres postgres 16M Sep 19 15:29 000000010000000000000092



[postgres@SERVER_TEST pg_wal]$
[postgres@SERVER_TEST pg_wal]$
[postgres@SERVER_TEST pg_wal]$  psql -X -p 5414 -d test_checkpoint -c "CHECKPOINT;"
CHECKPOINT


[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 32M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:29 000000010000000000000093
-rw-------. 1 postgres postgres 16M Sep 19 15:29 000000010000000000000092

 


[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_waldump -f  000000010000000000000093 | wc -l
pg_waldump: fatal: could not find a valid record after 0/93000000
0


[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_waldump  000000010000000000000092 | wc -l
pg_waldump: fatal: error in WAL record at 0/92CBE1F8: invalid record length at 0/92CBE230: wanted 24, got 0
172188


[postgres@SERVER_TEST pg_wal]$  psql -X -p 5414 -d test_checkpoint -c "CHECKPOINT;"
CHECKPOINT


[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 32M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:29 000000010000000000000093
-rw-------. 1 postgres postgres 16M Sep 19 15:34 000000010000000000000092



[postgres@SERVER_TEST pg_wal]$ pg_archivecleanup -n  /sysx/data14/pg_wal 000000010000000000000092
[postgres@SERVER_TEST pg_wal]$
[postgres@SERVER_TEST pg_wal]$ pg_archivecleanup -n  /sysx/data14/pg_wal 000000010000000000000093
/sysx/data14/pg_wal/000000010000000000000092


[postgres@SERVER_TEST pg_wal]$ pg_archivecleanup -d  /sysx/data14/pg_wal 000000010000000000000093
pg_archivecleanup: keeping WAL file "/sysx/data14/pg_wal/000000010000000000000093" and later
pg_archivecleanup: removing file "/sysx/data14/pg_wal/000000010000000000000092"

[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 16M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:29 000000010000000000000093


[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_ctl restart -D $PGDATA14
waiting for server to shut down.... done
server stopped
waiting for server to start....<2024-09-19 15:35:52 MST     1690515 66eca748.19cb93 >LOG:  redirecting log output to logging collector process
<2024-09-19 15:35:52 MST     1690515 66eca748.19cb93 >HINT:  Future log output will appear in directory "pg_log".
. stopped waiting
pg_ctl: could not start server
Examine the log output.




 
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_resetwal -f -D $PGDATA14
Write-ahead log reset


[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-19 15:36:09 MST     1690616 66eca759.19cbf8 >LOG:  redirecting log output to logging collector process
<2024-09-19 15:36:09 MST     1690616 66eca759.19cbf8 >HINT:  Future log output will appear in directory "pg_log".

 done
server started




[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 16M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:36 000000010000000000000094




[postgres@SERVER_TEST pg_log]$ psql -X -p 5414 -d test_checkpoint -c "DROP TABLE ventas; CREATE TABLE ventas (
     id SERIAL PRIMARY KEY ,
     fecha DATE,
     cliente_id INTEGER,
     producto_id INTEGER,
     cantidad INTEGER,
     precio NUMERIC
 );

 INSERT INTO ventas ( fecha, cliente_id, producto_id, cantidad, precio)
 SELECT
       NOW() - INTERVAL '1 day' * (RANDOM() * 1000)::int,
       (RANDOM() * 1000)::int,
       (RANDOM() * 100)::int,
       (RANDOM() * 10)::int,
       (RANDOM() * 100)::numeric
   FROM generate_series(1, 190000);"
DROP TABLE
CREATE TABLE
INSERT 0 190000



[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 32M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:36 000000010000000000000094
-rw-------. 1 postgres postgres 16M Sep 19 15:36 000000010000000000000095




[postgres@SERVER_TEST pg_wal]$  psql -X -p 5414 -d test_checkpoint -c "CHECKPOINT;"
CHECKPOINT
[postgres@SERVER_TEST pg_wal]$
 
[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 32M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:36 000000010000000000000096
-rw-------. 1 postgres postgres 16M Sep 19 15:39 000000010000000000000095



[postgres@SERVER_TEST pg_wal]$ psql -X -p 5414 -d test_checkpoint -c "
 INSERT INTO ventas ( fecha, cliente_id, producto_id, cantidad, precio)
 SELECT
       NOW() - INTERVAL '1 day' * (RANDOM() * 1000)::int,
       (RANDOM() * 1000)::int,
       (RANDOM() * 100)::int,
       (RANDOM() * 10)::int,
       (RANDOM() * 100)::numeric
   FROM generate_series(1, 1900000);"
INSERT 0 10

[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 48M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:41 000000010000000000000095
-rw-------. 1 postgres postgres 16M Sep 19 15:41 000000010000000000000096
-rw-------. 1 postgres postgres 16M Sep 19 15:41 000000010000000000000097

[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_waldump  000000010000000000000095 | wc -l
215954
[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_waldump  000000010000000000000096 | wc -l
216271
[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_waldump  000000010000000000000097 | wc -l
pg_waldump: fatal: error in WAL record at 0/9799C8C8: invalid record length at 0/9799C900: wanted 24, got 0
129918


[postgres@SERVER_TEST pg_wal]$ psql -X -p 5414 -d test_checkpoint -c "CHECKPOINT;"
CHECKPOINT


[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 48M
drwx------. 2 postgres postgres   6 Jun 17 09:24 archive_status
-rw-------. 1 postgres postgres 16M Sep 19 15:41 000000010000000000000098
-rw-------. 1 postgres postgres 16M Sep 19 15:41 000000010000000000000099
-rw-------. 1 postgres postgres 16M Sep 19 15:43 000000010000000000000097


pg_waldump: fatal: error in WAL record at 0/979BB790: invalid record length at 0/979BB7C8: wanted 24, got 0
131512
[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_waldump  000000010000000000000098 | wc -l
pg_waldump: fatal: could not find a valid record after 0/98000000
0
[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_waldump  000000010000000000000099 | wc -l
pg_waldump: fatal: could not find a valid record after 0/99000000
0



[postgres@SERVER_TEST pg_wal]$  pg_archivecleanup -n  /sysx/data14/pg_wal 000000010000000000000097
[postgres@SERVER_TEST pg_wal]$
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_controldata -D $PGDATA14
pg_control version number:            1300
Catalog version number:               202107181
Database system identifier:           7381508807802424143
Database cluster state:               in production
pg_control last modified:             Thu 19 Sep 2024 03:43:35 PM MST
Latest checkpoint location:           0/9799C938
Latest checkpoint's REDO location:    0/9799C900
Latest checkpoint's REDO WAL file:    000000010000000000000097
Latest checkpoint's TimeLineID:       1
Latest checkpoint's PrevTimeLineID:   1
Latest checkpoint's full_page_writes: on
Latest checkpoint's NextXID:          0:1052
Latest checkpoint's NextOID:          25367
Latest checkpoint's NextMultiXactId:  1
Latest checkpoint's NextMultiOffset:  0
Latest checkpoint's oldestXID:        726
Latest checkpoint's oldestXID's DB:   1
Latest checkpoint's oldestActiveXID:  1052
Latest checkpoint's oldestMultiXid:   1
Latest checkpoint's oldestMulti's DB: 1
Latest checkpoint's oldestCommitTsXid:0
Latest checkpoint's newestCommitTsXid:0
Time of latest checkpoint:            Thu 19 Sep 2024 03:43:35 PM MST
Fake LSN counter for unlogged rels:   0/3E8
Minimum recovery ending location:     0/0
Min recovery ending loc's timeline:   0
Backup start location:                0/0
Backup end location:                  0/0
End-of-backup record required:        no
wal_level setting:                    replica
wal_log_hints setting:                off
max_connections setting:              100
max_worker_processes setting:         8
max_wal_senders setting:              10
max_prepared_xacts setting:           0
max_locks_per_xact setting:           64
track_commit_timestamp setting:       off
Maximum data alignment:               8
Database block size:                  8192
Blocks per segment of large relation: 131072
WAL block size:                       8192
Bytes per WAL segment:                16777216
Maximum length of identifiers:        64
Maximum columns in an index:          32
Maximum size of a TOAST chunk:        1996
Size of a large-object chunk:         2048
Date/time type storage:               64-bit integers
Float8 argument passing:              by value
Data page checksum version:           0
Mock authentication nonce:            93f8792f52798067b0cee85475ba6ed9ee6cc3d6aa17d8d7c1eacdf535ced484







``` 



### Bilbiografia :

https://www.percona.com/blog/postgresql-wal-retention-and-clean-up-pg_archivecleanup/
















# Eliminacion de archivos wal

``` 
Método 1: Usar el comando pg_controldata

Este comando te permite obtener información sobre el estado de tu base de datos, incluyendo el último punto de control (checkpoint).

1. Ejecuta pg_controldata: En tu servidor, ejecuta el siguiente comando para obtener información detallada:

pg_controldata /var/lib/postgresql/data

Esto te dará una salida como la siguiente:

Latest checkpoint's REDO location: 0/4000020
Latest checkpoint's TimeLineID: 1
Latest checkpoint's NextOID: 123456

En este caso, el punto importante es el REDO location: 0/4000020. Este valor indica el último archivo WAL que contiene información necesaria para la recuperación.


2. Interpretar el REDO location: El valor 0/4000020 se refiere a un archivo WAL específico. Los archivos WAL tienen nombres en formato hexadecimal, como 000000010000000000000040. Esto corresponde al segmento 000000010000000000000040 (los primeros caracteres corresponden a la línea de tiempo y los siguientes son el número del archivo).

Si listamos los archivos WAL en el directorio pg_wal, obtendremos algo así:

ls /var/lib/postgresql/data/pg_wal

Supongamos que la salida es:

00000001000000000000003E
00000001000000000000003F
000000010000000000000040
000000010000000000000041

El archivo 000000010000000000000040 es el más reciente usado en el último checkpoint.

Los archivos 00000001000000000000003E y 00000001000000000000003F son anteriores al último checkpoint y pueden ser eliminados si ya no se necesitan para replicación o recuperación.



3. Eliminar los archivos WAL antiguos: Si estás seguro de que los archivos anteriores al checkpoint ya no son necesarios (por ejemplo, si tienes backups recientes o replicación actualizada), puedes eliminarlos con:

rm /var/lib/postgresql/data/pg_wal/00000001000000000000003E
rm /var/lib/postgresql/data/pg_wal/00000001000000000000003F



Método 2: Usar pg_stat_replication para verificaciones de replicación

Si estás usando replicación, primero verifica que los nodos secundarios hayan replicado los WAL antiguos antes de eliminarlos. Usa esta consulta para verificar el estado de la replicación:

SELECT application_name, replay_lsn 
FROM pg_stat_replication;

El valor replay_lsn indica hasta qué punto los nodos secundarios han replicado los WAL.

Asegúrate de que el valor replay_lsn es igual o mayor al último archivo WAL que estás considerando eliminar.


Ejemplo resumido:

Archivos WAL actuales:

00000001000000000000003E
00000001000000000000003F
000000010000000000000040  (último checkpoint)
000000010000000000000041

Puedes eliminar los archivos 00000001000000000000003E y 00000001000000000000003F si:

Ya no son necesarios para restauración o replicación.

El último checkpoint fue en 000000010000000000000040.



Consideraciones finales:

Siempre asegúrate de tener backups válidos antes de eliminar cualquier archivo WAL.

Si usas archivado WAL (archive_mode = on), asegúrate de que los archivos que vas a eliminar ya hayan sido archivados exitosamente.

``` 




# Ejemplo de lo que pasa cuando se corrompe un wal o se elimina un wal no confirmado con checkpoint
```sql


--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

EVIDENCIA DE LOGS CUANDO DETIENES EL SERVICIO POSTGRESQL DE DISTINTAS FORMAS

--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

------------ APAGANDO EL SERVICIO POSTGRESQL DE MANERA NORMAL CON pg_ctl------------
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl stop -D $PGDATA14
waiting for server to shut down.... done
server stopped

****** LOG ******
<2024-09-20 12:38:14 MST     1744708 66edcf07.1a9f44 >LOG:  received fast shutdown request
<2024-09-20 12:38:14 MST     1744708 66edcf07.1a9f44 >LOG:  aborting any active transactions
<2024-09-20 12:38:14 MST     1744708 66edcf07.1a9f44 >LOG:  background worker "logical replication launcher" (PID 1744717) exited with exit code 1
<2024-09-20 12:38:14 MST     1744711 66edcf08.1a9f47 >LOG:  shutting down
<2024-09-20 12:38:14 MST     1744711 66edcf08.1a9f47 >LOG:  checkpoint starting: shutdown immediate
<2024-09-20 12:38:14 MST     1744711 66edcf08.1a9f47 >LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 1 recycled; write=0.020 s, sync=0.003 s, total=0.031 s; sync files=2, longest=0.002 s, average=0.002 s; distance=16383 kB, estimate=16383 kB
<2024-09-20 12:38:14 MST     1744708 66edcf07.1a9f44 >LOG:  database system is shut down



[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-20 12:39:46 MST     1744854 66edcf82.1a9fd6 >LOG:  redirecting log output to logging collector process
<2024-09-20 12:39:46 MST     1744854 66edcf82.1a9fd6 >HINT:  Future log output will appear in directory "pg_log".
 done
server started

****** LOG ******
<2024-09-20 12:39:46 MST     1744854 66edcf82.1a9fd6 >LOG:  starting PostgreSQL 14.13 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit
<2024-09-20 12:39:46 MST     1744854 66edcf82.1a9fd6 >LOG:  listening on IPv4 address "0.0.0.0", port 5414
<2024-09-20 12:39:46 MST     1744854 66edcf82.1a9fd6 >LOG:  listening on IPv6 address "::", port 5414
<2024-09-20 12:39:46 MST     1744854 66edcf82.1a9fd6 >LOG:  listening on Unix socket "/run/postgresql/.s.PGSQL.5414"
<2024-09-20 12:39:46 MST     1744854 66edcf82.1a9fd6 >LOG:  listening on Unix socket "/tmp/.s.PGSQL.5414"
<2024-09-20 12:39:46 MST     1744856 66edcf82.1a9fd8 >LOG:  database system was shut down at 2024-09-20 12:38:14 MST
<2024-09-20 12:39:46 MST     1744854 66edcf82.1a9fd6 >LOG:  database system is ready to accept connections



------------ MATANDO EL PROCESO CON KILL ------------
@ Cuando usas kill sin especificar una señal, por defecto envía la señal SIGTERM. PostgreSQL maneja SIGTERM como una solicitud para un apagado ordenado

[postgres@SERVER_TEST pg_wal]$ kill  $(head -1  $PGDATA14/postmaster.pid)
[postgres@SERVER_TEST pg_wal]$
 
 ****** LOG ******
<2024-09-20 12:43:14 MST     1744963 66edd039.1aa043 >LOG:  received smart shutdown request
<2024-09-20 12:43:14 MST     1744963 66edd039.1aa043 >LOG:  background worker "logical replication launcher" (PID 1744972) exited with exit code 1
<2024-09-20 12:43:14 MST     1744966 66edd039.1aa046 >LOG:  shutting down
<2024-09-20 12:43:14 MST     1744966 66edd039.1aa046 >LOG:  checkpoint starting: shutdown immediate
<2024-09-20 12:43:14 MST     1744966 66edd039.1aa046 >LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 1 recycled; write=0.019 s, sync=0.002 s, total=0.026 s; sync files=2, longest=0.001 s, average=0.001 s; distance=16384 kB, estimate=16384 kB
<2024-09-20 12:43:14 MST     1744963 66edd039.1aa043 >LOG:  database system is shut down



[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-20 12:43:33 MST     1745014 66edd065.1aa076 >LOG:  redirecting log output to logging collector process
<2024-09-20 12:43:33 MST     1745014 66edd065.1aa076 >HINT:  Future log output will appear in directory "pg_log".
 done
server started

****** LOG ******
<2024-09-20 12:43:33 MST     1745014 66edd065.1aa076 >LOG:  starting PostgreSQL 14.13 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit
<2024-09-20 12:43:33 MST     1745014 66edd065.1aa076 >LOG:  listening on IPv4 address "0.0.0.0", port 5414
<2024-09-20 12:43:33 MST     1745014 66edd065.1aa076 >LOG:  listening on IPv6 address "::", port 5414
<2024-09-20 12:43:33 MST     1745014 66edd065.1aa076 >LOG:  listening on Unix socket "/run/postgresql/.s.PGSQL.5414"
<2024-09-20 12:43:34 MST     1745014 66edd065.1aa076 >LOG:  listening on Unix socket "/tmp/.s.PGSQL.5414"
<2024-09-20 12:43:34 MST     1745016 66edd066.1aa078 >LOG:  database system was shut down at 2024-09-20 12:43:14 MST
<2024-09-20 12:43:34 MST     1745014 66edd065.1aa076 >LOG:  database system is ready to accept connections


------------ MATANDO EL PROCESO CON KILL CON SIGQUIT ------------
@ Cuando usas kill -QUIT, envías la señal SIGQUIT. Apagado Inmediato: PostgreSQL maneja SIGQUIT como una solicitud para un apagado inmediato.  

[postgres@SERVER_TEST pg_wal]$ kill -QUIT $(head -1  $PGDATA14/postmaster.pid)
[postgres@SERVER_TEST pg_wal]$

---- Tambien puedes lograr lo mismo usando "-m i"
[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_ctl stop -D $PGDATA14 -m i
waiting for server to shut down.... done
server stopped


****** LOG ******
<2024-09-20 12:40:32 MST     1744854 66edcf82.1a9fd6 >LOG:  received immediate shutdown request
<2024-09-20 12:40:32 MST     1744854 66edcf82.1a9fd6 >LOG:  database system is shut down



[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-20 12:41:34 MST     1744891 66edcfed.1a9ffb >LOG:  redirecting log output to logging collector process
<2024-09-20 12:41:34 MST     1744891 66edcfed.1a9ffb >HINT:  Future log output will appear in directory "pg_log".
 done
server started

****** LOG ******
<2024-09-20 12:41:34 MST     1744891 66edcfed.1a9ffb >LOG:  starting PostgreSQL 14.13 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit
<2024-09-20 12:41:34 MST     1744891 66edcfed.1a9ffb >LOG:  listening on IPv4 address "0.0.0.0", port 5414
<2024-09-20 12:41:34 MST     1744891 66edcfed.1a9ffb >LOG:  listening on IPv6 address "::", port 5414
<2024-09-20 12:41:34 MST     1744891 66edcfed.1a9ffb >LOG:  listening on Unix socket "/run/postgresql/.s.PGSQL.5414"
<2024-09-20 12:41:34 MST     1744891 66edcfed.1a9ffb >LOG:  listening on Unix socket "/tmp/.s.PGSQL.5414"
<2024-09-20 12:41:34 MST     1744893 66edcfee.1a9ffd >LOG:  database system was interrupted; last known up at 2024-09-20 12:39:46 MST
<2024-09-20 12:41:34 MST     1744893 66edcfee.1a9ffd >LOG:  database system was not properly shut down; automatic recovery in progress
<2024-09-20 12:41:34 MST     1744893 66edcfee.1a9ffd >LOG:  redo starts at 1/B50000A0
<2024-09-20 12:41:34 MST     1744893 66edcfee.1a9ffd >LOG:  invalid record length at 1/B50000D8: wanted 24, got 0
<2024-09-20 12:41:34 MST     1744893 66edcfee.1a9ffd >LOG:  redo done at 1/B50000A0 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
<2024-09-20 12:41:34 MST     1744893 66edcfee.1a9ffd >LOG:  checkpoint starting: end-of-recovery immediate
<2024-09-20 12:41:34 MST     1744893 66edcfee.1a9ffd >LOG:  checkpoint complete: wrote 0 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.020 s, sync=0.001 s, total=0.026 s; sync files=0, longest=0.000 s, average=0.000 s; distance=0 kB, estimate=0 kB
<2024-09-20 12:41:34 MST     1744891 66edcfed.1a9ffb >LOG:  database system is ready to accept connections







--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

ESCENARIO DONDE SE NO BORRA EL ARCHIVO WAL DONDE SE GUARDO LA MODIFICACION Y SE DETIENE EL SERVICIO POSTGRESQL
DE FORMA IMEDIATA

--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 97M
-rw-------. 1 postgres postgres  16M Sep 20 12:51 0000000100000001000000BE
-rw-------. 1 postgres postgres  16M Sep 20 12:52 0000000100000001000000BF
-rw-------. 1 postgres postgres  16M Sep 20 12:56 0000000100000001000000BA
-rw-------. 1 postgres postgres  16M Sep 20 12:56 0000000100000001000000BB
-rw-------. 1 postgres postgres  16M Sep 20 12:56 0000000100000001000000BC
-rw-------. 1 postgres postgres  16M Sep 20 12:56 0000000100000001000000BD
drwx------. 2 postgres postgres 4.0K Sep 20 12:56 archive_status


[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_controldata -D $PGDATA14 | grep REDO
Latest checkpoint's REDO location:    1/BA000028
Latest checkpoint's REDO WAL file:    0000000100000001000000BA


[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump  0000000100000001000000BE | wc -l
pg_waldump: fatal: could not find a valid record after 1/BE000000
0
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump  0000000100000001000000BF | wc -l
pg_waldump: fatal: could not find a valid record after 1/BF000000
0
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump  0000000100000001000000BA | wc -l
213376
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump  0000000100000001000000BB | wc -l
215976
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump  0000000100000001000000BC | wc -l
216307
[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump  0000000100000001000000BD | wc -l
pg_waldump: fatal: error in WAL record at 1/BD96F220: invalid record length at 1/BD96F258: wanted 24, got 0
127460



[postgres@SERVER_TEST pg_wal]$ psql -X -p 5414 -c "create table personas
(  id     integer                
, nombre character varying(100) 
, edad   integer                
, ciudad character varying(100) );

insert into personas values
(  1 ,'Juan' , 28 ,'Culiacán' ),
(  2 ,'Ana'  , 35 ,'Mazatlán' ),
(  3 ,'Luis' , 22 ,'Guadalajara' );

select *from personas;"
CREATE TABLE
INSERT 0 3
 id | nombre | edad |   ciudad
----+--------+------+-------------
  1 | Juan   |   28 | Culiacán
  2 | Ana    |   35 | Mazatlán
  3 | Luis   |   22 | Guadalajara
(3 rows)




[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_controldata -D $PGDATA14 | grep REDO
Latest checkpoint's REDO location:    1/BA000028
Latest checkpoint's REDO WAL file:    0000000100000001000000BA




[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_ctl stop -D $PGDATA14 -m i
waiting for server to shut down.... done
server stopped

****** LOG ******
<2024-09-20 12:59:08 MST     1745734 66edd373.1aa346 >LOG:  received immediate shutdown request
<2024-09-20 12:59:08 MST     1745734 66edd373.1aa346 >LOG:  database system is shut down

[postgres@SERVER_TEST pg_wal]$ psql -p 5414
psql: error: connection to server on socket "/run/postgresql/.s.PGSQL.5414" failed: No such file or directory
        Is the server running locally and accepting connections on that socket?



[postgres@SERVER_TEST pg_wal]$
[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-20 13:00:22 MST     1746155 66edd456.1aa4eb >LOG:  redirecting log output to logging collector process
<2024-09-20 13:00:22 MST     1746155 66edd456.1aa4eb >HINT:  Future log output will appear in directory "pg_log".
 done
server started

****** LOG ******
<2024-09-20 13:00:22 MST     1746155 66edd456.1aa4eb >LOG:  starting PostgreSQL 14.13 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit
<2024-09-20 13:00:22 MST     1746155 66edd456.1aa4eb >LOG:  listening on IPv4 address "0.0.0.0", port 5414
<2024-09-20 13:00:22 MST     1746155 66edd456.1aa4eb >LOG:  listening on IPv6 address "::", port 5414
<2024-09-20 13:00:22 MST     1746155 66edd456.1aa4eb >LOG:  listening on Unix socket "/run/postgresql/.s.PGSQL.5414"
<2024-09-20 13:00:22 MST     1746155 66edd456.1aa4eb >LOG:  listening on Unix socket "/tmp/.s.PGSQL.5414"
<2024-09-20 13:00:22 MST     1746157 66edd456.1aa4ed >LOG:  database system was interrupted; last known up at 2024-09-20 12:56:35 MST
<2024-09-20 13:00:22 MST     1746157 66edd456.1aa4ed >LOG:  database system was not properly shut down; automatic recovery in progress
<2024-09-20 13:00:22 MST     1746157 66edd456.1aa4ed >LOG:  redo starts at 1/BA0000A0
<2024-09-20 13:00:22 MST     1746157 66edd456.1aa4ed >LOG:  invalid record length at 1/BD987598: wanted 24, got 0
<2024-09-20 13:00:22 MST     1746157 66edd456.1aa4ed >LOG:  redo done at 1/BD987560 system usage: CPU: user: 0.47 s, system: 0.06 s, elapsed: 0.56 s
<2024-09-20 13:00:22 MST     1746157 66edd456.1aa4ed >LOG:  checkpoint starting: end-of-recovery immediate
<2024-09-20 13:00:23 MST     1746157 66edd456.1aa4ed >LOG:  checkpoint complete: wrote 2172 buffers (0.3%); 0 WAL file(s) added, 0 removed, 3 recycled; write=0.042 s, sync=0.002 s, total=0.052 s; sync files=56, longest=0.001 s, average=0.001 s; distance=58909 kB, estimate=58909 kB
<2024-09-20 13:00:23 MST     1746155 66edd456.1aa4eb >LOG:  database system is ready to accept connections


[postgres@SERVER_TEST pg_wal]$  psql -X -p 5414 -c "select * from personas;"
 id | nombre | edad |   ciudad
----+--------+------+-------------
  1 | Juan   |   28 | Culiacán
  2 | Ana    |   35 | Mazatlán
  3 | Luis   |   22 | Guadalajara
(3 rows)


[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_controldata -D $PGDATA14 | grep REDO
Latest checkpoint's REDO location:    1/BD987598
Latest checkpoint's REDO WAL file:    0000000100000001000000BD






 

--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

ESCENARIO DONDE SE BORRA EL ARCHIVO WAL DONDE SE GUARDO LA MODIFICACION Y SE DETIENE EL SERVICIO POSTGRESQL
DE FORMA IMEDIATA

--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl stop -D $PGDATA14
waiting for server to shut down.... done
server stopped

[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_resetwal -f -D $PGDATA14
Write-ahead log reset

[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-20 13:16:17 MST     1747522 66edd811.1aaa42 >LOG:  redirecting log output to logging collector process
<2024-09-20 13:16:17 MST     1747522 66edd811.1aaa42 >HINT:  Future log output will appear in directory "pg_log".
 done
server started


[postgres@SERVER_TEST pg_wal]$ psql -X  -p 5414 -d postgres  -c "\dt"
Did not find any relations.


[postgres@SERVER_TEST pg_wal]$  ls -lhtr
total 17M
drwx------. 2 postgres postgres 4.0K Sep 20 13:56 archive_status
-rw-------. 1 postgres postgres  16M Sep 20 13:56 0000000100000001000000EF




[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_controldata -D $PGDATA14 | grep REDO
Latest checkpoint's REDO location:    1/E5000028
Latest checkpoint's REDO WAL file:    0000000100000001000000EF

[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump 0000000100000001000000EF
rmgr: XLOG        len (rec/tot):    114/   114, tx:          0, lsn: 1/EA000028, prev 0/00000000, desc: CHECKPOINT_SHUTDOWN redo 1/EA000028; tli 1; prev tli 1; fpw true; xid 0:1149; oid 74689; multi 1; offset 0; oldest xid 726 in DB 1; oldest multi 1 in DB 1; oldest/newest commit timestamp xid: 0/0; oldest running xid 0; shutdown
rmgr: XLOG        len (rec/tot):     54/    54, tx:          0, lsn: 1/EA0000A0, prev 1/EA000028, desc: PARAMETER_CHANGE max_connections=100 max_worker_processes=8 max_wal_senders=10 max_prepared_xacts=0 max_locks_per_xact=64 wal_level=replica wal_log_hints=off track_commit_timestamp=off
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 1/EA0000D8, prev 1/EA0000A0, desc: RUNNING_XACTS nextXid 1149 latestCompletedXid 1148 oldestRunningXid 1149
pg_waldump: fatal: error in WAL record at 1/EA0000D8: invalid record length at 1/EA000110: wanted 24, got 0


[postgres@SERVER_TEST pg_wal]$ psql -X  -p 5414 -d postgres  -c "SELECT pg_switch_wal(); "
 pg_switch_wal
---------------
 1/EF000128
(1 row)


[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_controldata -D $PGDATA14 | grep REDO
Latest checkpoint's REDO location:    1/EA000028
Latest checkpoint's REDO WAL file:    0000000100000001000000EF




[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 33M
-rw-------. 1 postgres postgres  16M Sep 20 13:54 0000000100000001000000EF
-rw-------. 1 postgres postgres  16M Sep 20 13:54 0000000100000001000000F0
drwx------. 2 postgres postgres 4.0K Sep 20 13:54 archive_status



[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump 0000000100000001000000F0
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 1/EB000028, prev 1/EA000110, desc: RUNNING_XACTS nextXid 1149 latestCompletedXid 1148 oldestRunningXid 1149
pg_waldump: fatal: error in WAL record at 1/EB000028: invalid record length at 1/EB000060: wanted 24, got 0

   


[postgres@SERVER_TEST pg_wal]$ psql -X -p 5414 -d postgres -c " create table personas
 (  id     integer
 , nombre character varying(100)
 , edad   integer
 , ciudad character varying(100) );

 insert into personas values
 (  1 ,'Juan' , 28 ,'Culiacán' ),
 (  2 ,'Ana'  , 35 ,'Mazatlán' ),
 (  3 ,'Luis' , 22 ,'Guadalajara' );
 
 select * from personas;"
DROP TABLE
CREATE TABLE
INSERT 0 3
 id | nombre | edad |   ciudad
----+--------+------+-------------
  1 | Juan   |   28 | Culiacán
  2 | Ana    |   35 | Mazatlán
  3 | Luis   |   22 | Guadalajara
(3 rows)


[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 33M
-rw-------. 1 postgres postgres  16M Sep 20 13:48 0000000100000001000000EF
-rw-------. 1 postgres postgres  16M Sep 20 13:51 0000000100000001000000F0


[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_controldata -D $PGDATA14 | grep REDO
Latest checkpoint's REDO location:    1/E5000028
Latest checkpoint's REDO WAL file:    0000000100000001000000EF




[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_waldump  0000000100000001000000F0
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 1/F0000028, prev 1/EF000110, desc: RUNNING_XACTS nextXid 1150 latestCompletedXid 1149 oldestRunningXid 1150
rmgr: XLOG        len (rec/tot):     30/    30, tx:          0, lsn: 1/F0000060, prev 1/F0000028, desc: NEXTOID 82881
rmgr: Standby     len (rec/tot):     42/    42, tx:       1150, lsn: 1/F0000080, prev 1/F0000060, desc: LOCK xid 1150 db 13748 rel 74689
rmgr: Storage     len (rec/tot):     42/    42, tx:       1150, lsn: 1/F00000B0, prev 1/F0000080, desc: CREATE base/13748/74689
rmgr: Heap        len (rec/tot):     54/  4938, tx:       1150, lsn: 1/F00000E0, prev 1/F00000B0, desc: INSERT off 65 flags 0x00, blkref #0: rel 1663/13748/1247 blk 17 FPW
rmgr: Btree       len (rec/tot):     53/  4133, tx:       1150, lsn: 1/F0001430, prev 1/F00000E0, desc: INSERT_LEAF off 202, blkref #0: rel 1663/13748/2703 blk 4 FPW
rmgr: Btree       len (rec/tot):     53/  7225, tx:       1150, lsn: 1/F0002470, prev 1/F0001430, desc: INSERT_LEAF off 173, blkref #0: rel 1663/13748/2704 blk 4 FPW
rmgr: Heap2       len (rec/tot):     57/  3369, tx:       1150, lsn: 1/F00040C8, prev 1/F0002470, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/13748/2608 blk 67 FPW
rmgr: Btree       len (rec/tot):     53/  4257, tx:       1150, lsn: 1/F0004DF8, prev 1/F00040C8, desc: INSERT_LEAF off 149, blkref #0: rel 1663/13748/2673 blk 5 FPW
rmgr: Btree       len (rec/tot):     53/  7533, tx:       1150, lsn: 1/F0005EA0, prev 1/F0004DF8, desc: INSERT_LEAF off 266, blkref #0: rel 1663/13748/2674 blk 1 FPW
rmgr: Heap        len (rec/tot):    211/   211, tx:       1150, lsn: 1/F0007C28, prev 1/F0005EA0, desc: INSERT off 66 flags 0x00, blkref #0: rel 1663/13748/1247 blk 17
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F0007D00, prev 1/F0007C28, desc: INSERT_LEAF off 202, blkref #0: rel 1663/13748/2703 blk 4
rmgr: Btree       len (rec/tot):     53/  8237, tx:       1150, lsn: 1/F0007D40, prev 1/F0007D00, desc: INSERT_LEAF off 86, blkref #0: rel 1663/13748/2704 blk 1 FPW
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1150, lsn: 1/F0009D88, prev 1/F0007D40, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/13748/2608 blk 67
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F0009DE0, prev 1/F0009D88, desc: INSERT_LEAF off 149, blkref #0: rel 1663/13748/2673 blk 5
rmgr: Btree       len (rec/tot):     53/  1457, tx:       1150, lsn: 1/F0009E28, prev 1/F0009DE0, desc: INSERT_LEAF off 49, blkref #0: rel 1663/13748/2674 blk 4 FPW
rmgr: Heap        len (rec/tot):     54/  3514, tx:       1150, lsn: 1/F000A3F8, prev 1/F0009E28, desc: INSERT off 91 flags 0x00, blkref #0: rel 1663/13748/1259 blk 6 FPW
rmgr: Btree       len (rec/tot):     53/  7993, tx:       1150, lsn: 1/F000B1B8, prev 1/F000A3F8, desc: INSERT_LEAF off 395, blkref #0: rel 1663/13748/2662 blk 2 FPW
rmgr: Btree       len (rec/tot):     53/  7981, tx:       1150, lsn: 1/F000D110, prev 1/F000B1B8, desc: INSERT_LEAF off 100, blkref #0: rel 1663/13748/2663 blk 1 FPW
rmgr: Btree       len (rec/tot):     53/  1973, tx:       1150, lsn: 1/F000F058, prev 1/F000D110, desc: INSERT_LEAF off 94, blkref #0: rel 1663/13748/3455 blk 5 FPW
rmgr: Heap2       len (rec/tot):     63/  7403, tx:       1150, lsn: 1/F000F810, prev 1/F000F058, desc: MULTI_INSERT 4 tuples flags 0x02, blkref #0: rel 1663/13748/1249 blk 94 FPW
rmgr: Btree       len (rec/tot):     53/  2801, tx:       1150, lsn: 1/F0011518, prev 1/F000F810, desc: INSERT_LEAF off 99, blkref #0: rel 1663/13748/2658 blk 25 FPW
rmgr: Btree       len (rec/tot):     53/  1173, tx:       1150, lsn: 1/F0012028, prev 1/F0011518, desc: INSERT_LEAF off 54, blkref #0: rel 1663/13748/2659 blk 16 FPW
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F00124C0, prev 1/F0012028, desc: INSERT_LEAF off 100, blkref #0: rel 1663/13748/2658 blk 25
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F0012508, prev 1/F00124C0, desc: INSERT_LEAF off 55, blkref #0: rel 1663/13748/2659 blk 16
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F0012548, prev 1/F0012508, desc: INSERT_LEAF off 99, blkref #0: rel 1663/13748/2658 blk 25
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F0012590, prev 1/F0012548, desc: INSERT_LEAF off 56, blkref #0: rel 1663/13748/2659 blk 16
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F00125D0, prev 1/F0012590, desc: INSERT_LEAF off 99, blkref #0: rel 1663/13748/2658 blk 25
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F0012618, prev 1/F00125D0, desc: INSERT_LEAF off 57, blkref #0: rel 1663/13748/2659 blk 16
rmgr: Heap2       len (rec/tot):    700/   700, tx:       1150, lsn: 1/F0012658, prev 1/F0012618, desc: MULTI_INSERT 5 tuples flags 0x00, blkref #0: rel 1663/13748/1249 blk 94
rmgr: Heap2       len (rec/tot):     57/  7037, tx:       1150, lsn: 1/F0012918, prev 1/F0012658, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/13748/1249 blk 93 FPW
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F00144B0, prev 1/F0012918, desc: INSERT_LEAF off 100, blkref #0: rel 1663/13748/2658 blk 25
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F00144F8, prev 1/F00144B0, desc: INSERT_LEAF off 54, blkref #0: rel 1663/13748/2659 blk 16
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F0014538, prev 1/F00144F8, desc: INSERT_LEAF off 104, blkref #0: rel 1663/13748/2658 blk 25
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F0014580, prev 1/F0014538, desc: INSERT_LEAF off 54, blkref #0: rel 1663/13748/2659 blk 16
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F00145C0, prev 1/F0014580, desc: INSERT_LEAF off 100, blkref #0: rel 1663/13748/2658 blk 25
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F0014608, prev 1/F00145C0, desc: INSERT_LEAF off 54, blkref #0: rel 1663/13748/2659 blk 16
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F0014648, prev 1/F0014608, desc: INSERT_LEAF off 105, blkref #0: rel 1663/13748/2658 blk 25
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F0014690, prev 1/F0014648, desc: INSERT_LEAF off 54, blkref #0: rel 1663/13748/2659 blk 16
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F00146D0, prev 1/F0014690, desc: INSERT_LEAF off 100, blkref #0: rel 1663/13748/2658 blk 25
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F0014718, prev 1/F00146D0, desc: INSERT_LEAF off 54, blkref #0: rel 1663/13748/2659 blk 16
rmgr: Btree       len (rec/tot):     72/    72, tx:       1150, lsn: 1/F0014758, prev 1/F0014718, desc: INSERT_LEAF off 106, blkref #0: rel 1663/13748/2658 blk 25
rmgr: Btree       len (rec/tot):     64/    64, tx:       1150, lsn: 1/F00147A0, prev 1/F0014758, desc: INSERT_LEAF off 54, blkref #0: rel 1663/13748/2659 blk 16
rmgr: Heap2       len (rec/tot):     85/    85, tx:       1150, lsn: 1/F00147E0, prev 1/F00147A0, desc: MULTI_INSERT 1 tuples flags 0x02, blkref #0: rel 1663/13748/2608 blk 67
rmgr: Btree       len (rec/tot):     53/  7617, tx:       1150, lsn: 1/F0014838, prev 1/F00147E0, desc: INSERT_LEAF off 269, blkref #0: rel 1663/13748/2673 blk 4 FPW
rmgr: Btree       len (rec/tot):     53/  6301, tx:       1150, lsn: 1/F0016618, prev 1/F0014838, desc: INSERT_LEAF off 108, blkref #0: rel 1663/13748/2674 blk 48 FPW
rmgr: Heap2       len (rec/tot):    144/   144, tx:       1150, lsn: 1/F0017EB8, prev 1/F0016618, desc: PRUNE latestRemovedXid 1149 nredirected 0 ndead 43, blkref #0: rel 1663/13748/1249 blk 94
rmgr: Heap        len (rec/tot):     81/    81, tx:       1150, lsn: 1/F0017F48, prev 1/F0017EB8, desc: INSERT+INIT off 1 flags 0x00, blkref #0: rel 1663/13748/74689 blk 0
rmgr: Heap        len (rec/tot):     77/    77, tx:       1150, lsn: 1/F0017FA0, prev 1/F0017F48, desc: INSERT off 2 flags 0x00, blkref #0: rel 1663/13748/74689 blk 0
rmgr: Heap        len (rec/tot):     83/    83, tx:       1150, lsn: 1/F0017FF0, prev 1/F0017FA0, desc: INSERT off 3 flags 0x00, blkref #0: rel 1663/13748/74689 blk 0
rmgr: Transaction len (rec/tot):    501/   501, tx:       1150, lsn: 1/F0018060, prev 1/F0017FF0, desc: COMMIT 2024-09-20 13:57:07.584304 MST; inval msgs: catcache 76 catcache 75 catcache 76 catcache 75 catcache 51 catcache 50 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 catcache 7 catcache 6 snapshot 2608 relcache 74689
rmgr: Standby     len (rec/tot):     50/    50, tx:          0, lsn: 1/F0018258, prev 1/F0018060, desc: RUNNING_XACTS nextXid 1151 latestCompletedXid 1150 oldestRunningXid 1151
pg_waldump: fatal: error in WAL record at 1/F0018258: invalid record length at 1/F0018290: wanted 24, got 0






--- Este archivo que vamos eliminar tiene mas lineas esto quiere decir que aqui se guardo 
[postgres@SERVER_TEST pg_wal]$ rm 0000000100000001000000F0
[postgres@SERVER_TEST pg_wal]$

pg_archivecleanup -n /sysx/data14/pg_wal

[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 17M
-rw-------. 1 postgres postgres  16M Sep 20 13:56 0000000100000001000000EF
drwx------. 2 postgres postgres 4.0K Sep 20 13:56 archive_status





[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_ctl stop -D $PGDATA14 -m i
waiting for server to shut down.... done
server stopped


****** LOG ******
<2024-09-20 13:11:20 MST     1746155 66edd456.1aa4eb >LOG:  received immediate shutdown request
<2024-09-20 13:11:20 MST     1746155 66edd456.1aa4eb >LOG:  database system is shut down


[postgres@SERVER_TEST pg_wal]$ psql -p 5414 -d postgres
psql: error: connection to server on socket "/run/postgresql/.s.PGSQL.5414" failed: No such file or directory
        Is the server running locally and accepting connections on that socket?




[postgres@SERVER_TEST pg_wal]$ $PGBIN14/pg_ctl start -D $PGDATA14
waiting for server to start....<2024-09-20 13:12:40 MST     1747141 66edd738.1aa8c5 >LOG:  redirecting log output to logging collector process
<2024-09-20 13:12:40 MST     1747141 66edd738.1aa8c5 >HINT:  Future log output will appear in directory "pg_log".
 done
server started


****** LOG ******
<2024-09-20 13:58:29 MST     1750181 66ede1f5.1ab4a5 >LOG:  starting PostgreSQL 14.13 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit
<2024-09-20 13:58:29 MST     1750181 66ede1f5.1ab4a5 >LOG:  listening on IPv4 address "0.0.0.0", port 5414
<2024-09-20 13:58:29 MST     1750181 66ede1f5.1ab4a5 >LOG:  listening on IPv6 address "::", port 5414
<2024-09-20 13:58:29 MST     1750181 66ede1f5.1ab4a5 >LOG:  listening on Unix socket "/run/postgresql/.s.PGSQL.5414"
<2024-09-20 13:58:29 MST     1750181 66ede1f5.1ab4a5 >LOG:  listening on Unix socket "/tmp/.s.PGSQL.5414"
<2024-09-20 13:58:29 MST     1750183 66ede1f5.1ab4a7 >LOG:  database system was interrupted; last known up at 2024-09-20 13:56:09 MST
<2024-09-20 13:58:29 MST     1750183 66ede1f5.1ab4a7 >LOG:  database system was not properly shut down; automatic recovery in progress
<2024-09-20 13:58:29 MST     1750183 66ede1f5.1ab4a7 >LOG:  redo starts at 1/EF0000A0
<2024-09-20 13:58:29 MST     1750183 66ede1f5.1ab4a7 >LOG:  redo done at 1/EF000110 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
<2024-09-20 13:58:29 MST     1750183 66ede1f5.1ab4a7 >LOG:  checkpoint starting: end-of-recovery immediate
<2024-09-20 13:58:29 MST     1750183 66ede1f5.1ab4a7 >LOG:  checkpoint complete: wrote 0 buffers (0.0%); 0 WAL file(s) added, 0 removed, 1 recycled; write=0.020 s, sync=0.001 s, total=0.047 s; sync files=0, longest=0.000 s, average=0.000 s; distance=16384 kB, estimate=16384 kB
<2024-09-20 13:58:29 MST     1750181 66ede1f5.1ab4a5 >LOG:  database system is ready to accept connections

[postgres@SERVER_TEST pg_wal]$ ls -lhtr
total 33M
-rw-------. 1 postgres postgres  16M Sep 20 13:56 0000000100000001000000F1
-rw-------. 1 postgres postgres  16M Sep 20 13:58 0000000100000001000000F0
drwx------. 2 postgres postgres 4.0K Sep 20 13:58 archive_status

[postgres@SERVER_TEST pg_wal]$  $PGBIN14/pg_controldata -D $PGDATA14 | grep REDO
Latest checkpoint's REDO location:    1/F0000028
Latest checkpoint's REDO WAL file:    0000000100000001000000F0



[postgres@SERVER_TEST pg_wal]$  psql -X -p 5414 -d postgres -c "\dt"
Did not find any relations.


[postgres@SERVER_TEST pg_wal]$ psql -X -p 5414 -d postgres  -c "select * from personas;"
ERROR:  relation "personas" does not exist
LINE 1: select * from personas;
                      ^

 
``` 

## La escritura en disco puede ocurrir por varios eventos:  
  - Cuando se ejecuta un `COMMIT` con `synchronous_commit = on`.  
  - Cuando el **fsync** obliga al sistema operativo a confirmar la escritura.  
  - En cada **checkpoint**, PostgreSQL transfiere los cambios acumulados desde memoria al disco.  


### **1. `synchronous_commit` → ¿Cuándo se considera confirmada una transacción?**
📌 **Este parámetro controla si PostgreSQL espera a que los datos sean escritos en disco antes de confirmar (`COMMIT`).**  
- Si está en `on`, cada transacción solo se confirma después de que PostgreSQL garantiza que los datos están seguros en el WAL  antes de devolver éxito.
- Si está en `off`, Si está en OFF, el sistema no espera la escritura en el disco y devuelve éxito inmediatamente, confiando en que la escritura en el WAL se hará en segundo plano.


### **2. `fsync` → ¿Los datos realmente llegan al disco físico?**
📌 **Este parámetro fuerza que PostgreSQL asegure que los datos sean grabados en disco antes de continuar.**  
- Si está en `on`, PostgreSQL usa el sistema operativo para verificar que los cambios se han escrito en el disco físico.  
- Si está en `off`, PostgreSQL **no espera** confirmación del disco y confía en que el sistema operativo maneje la escritura cuando lo crea conveniente.  



### **1. Background Writer**  
El **background writer** es un proceso en PostgreSQL que trabaja en segundo plano para escribir páginas modificadas de memoria al disco. Este proceso intenta minimizar la carga de los checkpoints distribuyendo la escritura de datos de manera más uniforme.


Puedes ajustar su comportamiento en `postgresql.conf`:
```bash
bgwriter_delay = 200ms  # Tiempo entre escrituras
bgwriter_lru_maxpages = 100 # Máximo de páginas escritas en cada ciclo
```
Así, el **background writer** ayuda a reducir la cantidad de datos que deben ser escritos en cada checkpoint.



# Cuando un WAL deja de ser necesario ? 
Los WAL se vuelven innecesarios cuando se completa un checkpoint, las réplicas ya los aplicaron, no están retenidos por wal_keep_size o ningún replication slot los requiere.


Aspectos internos de MVCC en Postgres -> https://medium.com/@rohanjnr44/internals-of-mvcc-in-postgres-hidden-costs-of-updates-vs-inserts-381eadd35844
---

## 🔄 Flujo de vida del `wal_buffers` en PostgreSQL

### 🧩 1. **Inicio de una transacción**
- Un cliente realiza una operación que modifica datos (INSERT, UPDATE, DELETE).
- PostgreSQL **no escribe directamente en disco**, sino que:
  - Modifica la página en `shared_buffers`.
  - Genera un **registro WAL** que describe el cambio.

 

### 🧠 2. **Generación del registro WAL**
- El registro WAL se crea en memoria.
- Este registro se **almacena temporalmente en `wal_buffers`**, que es una zona de memoria compartida.

> 🔸 `wal_buffers` es como una “sala de espera” para los registros WAL antes de que se escriban en disco.

 
### 📤 3. **Escritura del WAL al disco**
- El proceso **WAL Writer** se ejecuta periódicamente (cada `wal_writer_delay`) y:
  - Toma los registros de `wal_buffers`.
  - Los escribe en los archivos WAL en disco (`pg_wal/`).
- También se escribe el WAL si:
  - Se hace `COMMIT`.
  - Se alcanza el tamaño máximo de `wal_buffers`.
  - Se genera un checkpoint.

 

### 🔐 4. **Sincronización y durabilidad**
- Antes de confirmar una transacción (`COMMIT`), PostgreSQL **sincroniza el WAL** al disco (fsync).
- Esto garantiza que el cambio esté registrado de forma duradera, incluso si el sistema falla.

 
### 🧹 5. **Vaciamiento de `wal_buffers`**
- Una vez que los registros se escriben en disco, `wal_buffers` se vacía.
- Se reutiliza para nuevos registros WAL.

 
## 📌 ¿Por qué es importante `wal_buffers`?

- **Evita escrituras frecuentes al disco** → mejora el rendimiento.
- **Permite agrupar registros WAL** → reduce I/O.
- **Es crítico para la durabilidad** → asegura que los cambios no se pierdan.

 
## ⚙️ Parámetros relacionados

| Parámetro | Descripción |
|----------|-------------|
| `wal_buffers` | Tamaño del buffer en memoria para registros WAL. |
| `wal_writer_delay` | Tiempo entre ejecuciones del WAL Writer. |
| `wal_level` | Nivel de detalle del WAL (`minimal`, `replica`, `logical`). |
| `commit_delay` | Tiempo que espera PostgreSQL antes de escribir el WAL en disco tras un COMMIT. |


## 🧠 Comparación con `shared_buffers`

| Concepto | `shared_buffers` | `wal_buffers` |
|---------|------------------|---------------|
| Contenido | Páginas de datos (bloques de 8KB) | Registros WAL (cambios en datos) |
| Uso | Lectura y escritura de datos | Registro de cambios para durabilidad |
| Escritura | Por background writer o checkpoints | Por WAL writer |
| Objetivo | Rendimiento de acceso a datos | Seguridad y recuperación ante fallos |


---




 

## **wal\_buffers**

Servir como un área de memoria intermedia (buffer) para los registros WAL antes de que se escriban físicamente en disco.

**Dicho simple:**  
 acelera las escrituras y reduce I/O al evitar que cada cambio tenga que ir directo al disco.


### **¿Qué es exactamente wal\_buffers?**

`wal_buffers` define cuánta memoria RAM usa PostgreSQL para almacenar temporalmente los WAL records generados por:

*   INSERT
*   UPDATE
*   DELETE
*   DDL (CREATE, ALTER, etc.)
*   Transacciones en general

***

### **Flujo simplificado**

    Cambios en datos
       ↓
    WAL record
       ↓
    wal_buffers (RAM)
       ↓
    pg_wal (disco)
       ↓
    Replica / Crash recovery

***

### **¿Por qué existe?**

**Sin wal\_buffers:**

*   Cada cambio tendría que escribir WAL directo a disco
*   Mucho I/O pequeño y lento
*   Menor throughput

**Con wal\_buffers:**

*   Se agrupan múltiples WAL records en memoria
*   Se escriben en bloques más grandes
*   Mejor rendimiento, especialmente en cargas intensivas de escritura

***

### **¿Cuándo se vacía el wal\_buffers?**

El contenido de `wal_buffers` se escribe a disco cuando ocurre alguno de estos eventos:

1.  COMMIT
2.  Se llenan los wal\_buffers
3.  Checkpoint
4.  Background writer / WAL writer
5.  fsync forzado (seguridad)

⚠️ **Ojo:**  
El COMMIT no se considera exitoso hasta que el WAL esté fsync en disco (según `synchronous_commit`).

***

### **Tamaño y valor por defecto**

Por defecto:

    wal_buffers = -1

PostgreSQL lo ajusta automáticamente (≈ 3% de `shared_buffers`, con límites).

**Valores comunes manuales:**

*   wal\_buffers = 16MB
*   wal\_buffers = 32MB
*   wal\_buffers = 64MB

***

### **¿Cuándo conviene aumentar wal\_buffers?**

Aumentarlo ayuda cuando hay alta tasa de INSERT/UPDATE, cargas tipo:

*   OLTP intenso
*   Ingesta masiva
*   TimescaleDB
*   Zabbix / monitoreo

**Ves waits como:**

*   WALWrite
*   WALSync

Ejemplo recomendado en servidores medianos/grandes:

    wal_buffers = 32MB

***

### **Relación con replicación streaming (importante para ti)**

*   El WAL sale primero de wal\_buffers → pg\_wal
*   La réplica nunca lee de wal\_buffers, solo de los WAL ya escritos
*   Un wal\_buffers muy pequeño puede:
    *   Retrasar escrituras
    *   Aumentar latencia de replicación indirectamente

***

### **Comparación rápida (SQL Server)**

| SQL Server              | PostgreSQL          |
| ----------------------- | ------------------- |
| Log Buffer              | wal\_buffers        |
| LDF                     | pg\_wal             |
| Commit espera log flush | synchronous\_commit |

***

### **Conclusión corta**

> wal\_buffers existe para mejorar el rendimiento de escritura agrupando registros WAL en memoria antes de escribirlos a disco, reduciendo I/O y latencia de commit.

 



 
---
### **1️⃣ ¿Qué es un buffer en PostgreSQL?**

Un **buffer** es memoria controlada directamente por PostgreSQL para una función específica.

**Características:**

*   Está dentro del proceso de PostgreSQL
*   Tiene un propósito concreto
*   PostgreSQL decide qué entra, cuándo sale y cómo se sincroniza

**Ejemplos importantes:**

| Buffer                 | Para qué sirve                    |
| ---------------------- | --------------------------------- |
| shared\_buffers        | Páginas de datos e índices        |
| wal\_buffers           | Registros WAL antes de ir a disco |
| temp\_buffers          | Tablas temporales                 |
| work\_mem              | Sort, hash, joins                 |
| maintenance\_work\_mem | VACUUM, CREATE INDEX              |

📌 Un buffer **no es “memoria libre”**, es memoria reservada y gestionada por PostgreSQL.


---


###  **Background Writer** y **WAL Writer** 
son dos procesos internos que trabajan para optimizar la escritura en disco y mantener la consistencia.  
Así, cuando llega el checkpoint, hay menos trabajo pendiente → evita picos de I/O.


###  **Background Writer**

*   **Qué es:**  
    Es un proceso que se encarga de escribir periódicamente las páginas modificadas (dirty pages) que están en **shared\_buffers** hacia el disco.

*   **Para qué sirve:**
    *   Reduce la carga de escritura durante los checkpoints.
    *   Evita que las consultas tengan que esperar a que se escriban páginas en disco.
    *   Mejora la estabilidad del rendimiento en cargas intensivas.

**Flujo simplificado:**

    Datos modificados → shared_buffers → Background Writer → Disco

 
###  **WAL Writer**

*   **Qué es:**  
    Es el proceso que escribe los registros WAL que están en **wal\_buffers** hacia los archivos WAL en disco (**pg\_wal**).

*   **Para qué sirve:**
    *   Garantiza la durabilidad (ACID) de las transacciones.
    *   Reduce la latencia de commit al vaciar wal\_buffers en segundo plano.
    *   Es clave para replicación y recuperación ante fallos.

**Flujo simplificado:**

    Cambios → WAL record → wal_buffers → WAL Writer → pg_wal (disco)

###  **¿Cuándo se activan?**

*   **Background Writer:**  
    Corre en intervalos definidos por `bgwriter_delay` (por defecto 200ms) y según la cantidad de páginas sucias.

*   **WAL Writer:**  
    Corre en intervalos definidos por `wal_writer_delay` (por defecto 200ms) o cuando `wal_buffers` está lleno.
