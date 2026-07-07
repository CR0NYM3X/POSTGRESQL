
 
 La **replicación lógica** se introdujo a partir de la versión 10 y permite copiar datos **a nivel de tabla**  desde una base de datos origen hacia otra base de datos (puede estar en el mismo servidor o en otro), **en tiempo real y de forma selectiva**. solo se replica el DML y no el DDL  A diferencia de la replicación física que si lo hace y copia todo el clúster. en la version 16 en adelante se introdujo el uso de repica de tipo activo-activo pero este tiene problemas cuando se actualiza la misma fila casi al mismo  tiempo este envia toda la fila completa en vez de enviar solo la columna modificada.

---

## 🧠 ¿Cómo funciona la replicación lógica?
en la **replicación lógica** de PostgreSQL, no se usa la base de datos `replication`. A diferencia de la **replicación física**, donde se clona el almacenamiento completo de la base de datos, la replicación lógica trabaja a nivel de **publicaciones y suscripciones**.

1. **El servidor origen (publisher)** registra los cambios en el WAL con `wal_level = logical`.
2. Se crea un **slot de replicación lógica** que captura los cambios.
3. Se define una **publicación** (`CREATE PUBLICATION`) que especifica qué tablas se replicarán.
4. En el servidor destino (subscriber), se crea una **suscripción** (`CREATE SUBSCRIPTION`) que se conecta al origen y aplica los cambios.

---


### 📌 **Ejemplo de replicación unidireccional**

 **Cómo funciona:**  
1️⃣ En el servidor **primario**, los empleados registran clientes nuevos. 2️⃣ Los datos se envían al servidor secundario. 3️⃣ En el **secundario**, los analistas pueden leer la información Y modificar datos pero estos cambios no afectan el primario.  

### 📌 **Ejemplo de replicación bidireccional**

 **Cómo funciona:**  
1️⃣ La oficina A registra un pedido nuevo. 2️⃣ Automáticamente, la base de datos de la oficina B recibe el pedido. 3️⃣ Si en la oficina B actualizan el estado del pedido, la oficina A también ve el cambio.  


---

# Plugins 
los plugins de salida se utilizan para la replicación lógica y permiten convertir los cambios en el WAL (Write-Ahead Log) a formatos específicos, como JSON o texto plano.

## **pgoutput**
✅ Es el plugin **oficial** de PostgreSQL, integrado directamente .  
✅ Funciona con **publicaciones y suscripciones**, sin necesidad de procesos externos.  
✅ **Replica datos automáticamente**, sin transformar la salida en JSON como `wal2json`.  
✅ Permite replicar unidireccional varias tablas en diferentes suscriptores de forma eficiente.  


##  **wal2json**
Es un **plugin de salida** que  decodifica  cambios en PostgreSQL y convierte los cambios del Write-Ahead Log (**WAL**) en **formato JSON**. Es útil para **capturar eventos de la base de datos en tiempo real** y enviarlos a otros sistemas, como motores de streaming, procesamiento de datos o integraciones con APIs. wal2json no necesita shared_preload_libraries porque es un decodificador lógico de WAL que se carga dinámicamente cuando se usa un replication slot

```conf
 /sysx/data11/DATANEW/17 $ rpm -qa | grep wal2json
wal2json_16-2.6-1PGDG.rhel8.x86_64
wal2json_17-2.6-2PGDG.rhel8.x86_64
```

### 📌 **¿Para qué sirve `wal2json`?**
✅ **Captura de cambios en tiempo real** (CDC)  
✅ **Integración con sistemas externos** (Kafka, RabbitMQ, etc.)  
✅ **Monitoreo de modificaciones en la base de datos**  
✅ **Auditoría y trazabilidad de datos**  
✅ **Migración de datos entre sistemas heterogéneos**


### 📌 **¿Se puede usar para replicar una tabla en un servidor maestro/publication ?**
No es un mecanismo nativo de replicación lógica en PostgreSQL. Sin embargo, se puede usar para capturar los cambios en una tabla en el servidor publicador y enviarlos al suscriptor, aunque necesitarás un proceso externo que interprete los eventos y los aplique en el servidor destino.


##  **test_decoding**
Es un **módulo de prueba** para la decodificación lógica en PostgreSQL. No está diseñado para uso en producción, sino como un **ejemplo** para desarrollar plugins de salida personalizados.

--- 

## **pglogical**
Es una extensión para **replicación lógica bidireccional** en PostgreSQL. Es una alternativa avanzada a la replicación lógica nativa y ofrece características adicionales como **replicación bidireccional**, **filtrado de datos**, y **actualización entre versiones de PostgreSQL**.

### 📌 **Características principales de `pglogical`**
✅ **Replicación lógica avanzada** → Permite replicar datos entre servidores PostgreSQL sin necesidad de replicación física.  
✅ **Replicación bidireccional** → Soporta sincronización entre múltiples servidores.  
✅ **Filtrado de datos** → Puedes replicar solo ciertas tablas o columnas.  
✅ **Migración entre versiones** → Facilita la actualización de PostgreSQL sin downtime.  
 
### ⚠️ **¿Cuándo usar `pglogical` en lugar de la replicación lógica nativa?**
- Si necesitas **replicación bidireccional** entre servidores.  
- Si quieres **filtrar datos** en la replicación.  
- Si estás **migrando entre versiones de PostgreSQL** sin downtime.  

---


## 📦 Ejemplo real: replicación lógica entre dos bases PostgreSQL


### 🔧 Paso 1: Configurar el servidor origen/Publicador

**1.1. Asegúrate de tener:**

```conf

wal_level = logical  # Se usa para replicación lógica, permitiendo la captura de cambios específicos.
max_wal_senders = 10 # Define el número máximo de procesos que pueden enviar datos de replicación.
max_wal_size = 1GB
min_wal_size = 80MB

max_replication_slots = 10  # Número máximo de slots permitidos



# Parámetros Extras que quisas quieres configurar
  # checkpoint_timeout = 30min   # Si el tiempo de checkpoint es muy bajo, PostgreSQL ejecutará checkpoints muy frecuentes, lo que puede afectar el rendimiento. ✔ Si el tiempo es muy alto, se acumularán muchos cambios antes de cada checkpoint, lo que aumentará el consumo de memoria.

  # checkpoint_completion_target = 0.9

  # wal_sender_timeout = 30000 # Intervalo de tiempo en milisegundos para enviar keep-alive a las réplicas
  # wal_receiver_timeout = 30000  # Tiempo máximo de espera antes de cancelar la conexión con el publicador
  # max_slot_wal_keep_size = 2048   # Tamaño máximo en MB de WAL retenido por cada replication slot (Evita crecimiento excesivo) o -1 para ilimitado
  # commit_delay = 100 # Tasa de commits por cada registro WAL para evitar acumulaciones
```

**1. Reiniciar el servicio**
```sql
 pg_ctl restart -D /sysx/data11/DATANEW/17
```


**1. Crear Base de datos de pruebas**
```sql
create database test_db_master;

\c test_db_master
```


**1. Crear tabla de pruebas:**

```sql

-- truncate clientes RESTART IDENTITY ;  
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,  -- Identificador único autoincremental
    nombre VARCHAR(100) NOT NULL,  -- Nombre del cliente
    email VARCHAR(255) UNIQUE,  -- Correo electrónico único
    fecha_registro TIMESTAMP DEFAULT NOW()  -- Fecha de registro automática
);
 

INSERT INTO clientes (nombre, email, fecha_registro)  
SELECT 
    'Cliente ' || id,  
    'cliente' || id || '@example.com',  
    NOW() - (id || ' days')::INTERVAL  -- Cada fecha será distinta, restando días según el ID
FROM generate_series(1, 100) AS id;

select * from clientes;
```

**1.2. Crear una publicación:**

```sql
 CREATE PUBLICATION pub_clientes FOR TABLE clientes;


-- OR, to replicate selected tables from anywhere
-- CREATE PUBLICATION my_selected_tables_pub FOR TABLE my_schema.table1, another_schema.table2;

-- OR, for specific DML operations (less common for full migration)
-- CREATE PUBLICATION my_inserts_only_pub FOR TABLE my_table WITH (publish = 'insert');

-- Creas la publicación indicando que incluya todo el catálogo:
CREATE PUBLICATION mi_publicacion_global FOR ALL TABLES;
```

**Validar status publicacion**
```sql
select * from pg_publication_tables;
```


**Creación de un replication slot lógico**
```sql
SELECT * FROM pg_create_logical_replication_slot('mi_slot', 'pgoutput'); --  slot_name , plugin name pgoutput o wal2json o test_decoding

-- cuando usar  pg_recvlogical tambien manda crear el slot 
-- pg_recvlogical -h 127.0.0.1 -p 5417 -d test_db_master -U postgres --slot mi_slot --create-slot -P wal2json

```

**Validar status slots**
```sql
-- Verifica si hay slots de replicación lógica activos
SELECT slot_name, plugin, slot_type, active, active_pid FROM pg_replication_slots;

	slot_type = physical → Réplica física (streaming)
	slot_type = logical → Réplica lógica
	plugin = wal2json o pgoutput → Lógica
	plugin = (null) → Física

```

---

### 🔧 Paso 2: Configurar el servidor destino/suscriptor


**[Conf Opcional] -  postgresql.conf (Suscriptor)**
```sql
max_logical_replication_workers = 10  # O más, <= max_worker_processes 
max_sync_workers_per_subscription = 5  # O más, <= max_logical_replication_workers 
max_worker_processes = 20            # Asegúrese de que esto sea suficiente para todos los trabajadores
```


**2.1. Crear la tabla `clientes` con la misma estructura.**
```sql
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,  -- Identificador único autoincremental
    nombre VARCHAR(100) NOT NULL,  -- Nombre del cliente
    email VARCHAR(255) UNIQUE,  -- Correo electrónico único
    fecha_registro TIMESTAMP DEFAULT NOW()  -- Fecha de registro automática
);
```

**2.2. Crear la suscripción:**

```sql
CREATE SUBSCRIPTION sub_clientes
CONNECTION 'host=127.0.0.1 dbname=test_db_master user=postgres port=5517'
PUBLICATION pub_clientes
WITH (enabled=false, slot_name = 'mi_slot', create_slot = false, copy_data = true, streaming = true , origin = 'none' );


enabled=false -> la suscripción se crea, pero no empieza a recibir datos hasta que la conexión se habilite manualmente con ENABLE
create_slot = true: Crea el slot automáticamente si no existe.
slot_name: Asigna un replication slot para asegurar retención de WAL.
streaming = true: Habilita la recepción en tiempo real, reduciendo latencia.
copy_data = true :  se copian todos los datos actuales de las tablas en la publicación. ✅ Si copy_data = false → Solo se replican los cambios futuros y no se copian los datos ya existentes.
publish='insert,delete' -> Se usa para indicar que es lo que va trasmitir 

```

### **origin=none** 
Es clave para evitar bucles infinitos en la replicación de datos entre nodos. Este parámetro permite definir cómo se manejan los cambios en la replicación y evitar que los datos replicados vuelvan al nodo de origen. Sin origin, los cambios podrían replicarse indefinidamente en un bucle.

Los datos generados localmente (ejecución directa de SQL) no tendrán un origen de replicación , y los datos replicados desde otra fuente sí lo tendrán. Con esta información, se encontró una manera de replicar únicamente los cambios realizados por comandos SQL, y no los de la replicación.

Las opciones disponibles para `origin` son:
- **`none`** – Solo envía los cambios que no tienen un origen asociado.
- **`any`** – Envía todos los cambios, independientemente de su origen.


**2.2. Habilitar la suscripción:**
```sql
ALTER SUBSCRIPTION sub_clientes ENABLE; -- Activa la suscripción si estaba deshabilitada.
ALTER SUBSCRIPTION sub_clientes REFRESH PUBLICATION; -- sincronizar la suscripción con el publicador en caso de que haya cambios en las publicaciones
```

**Validar estatus de subscripciones**
```
-- Ver suscripciones activas
SELECT * FROM pg_subscription;
SELECT * FROM pg_stat_subscription;
```

### **Escuchar cambios desde un slot lógico**
Si quieres recibir los cambios en tiempo real, puedes usar `pg_recvlogical`, una herramienta de PostgreSQL:

```bash
# Iniciar la replicación lógica y recibir cambios en tiempo real 
 pg_recvlogical -h 127.0.0.1 -p 5517 -d test_db_master -U postgres --slot mi_slot --start -o pretty-print=1 -o add-msg-prefixes=wal2json -f -

 pg_recvlogical -h 127.0.0.1 -P 5517 -U postgres -d test_db_master --slot mi_slot --start -o pretty-print=1 -f -

Usa -o pretty-print=1 para formatear la salida en JSON legible.
Usa -o add-msg-prefixes=wal2json para agregar prefijos a los mensajes replicados.
-f - indica que la salida se mostrará directamente en la terminal.


-- START_REPLICATION SLOT mi_slot LOGICAL WITH (origin = 'none');

```


### **Verificar los cambios sin iniciar captura en tiempo real**
Recuperar los cambios almacenados en un replication slot lógico, en el servidor publicador.
```sql
-- Esta funcion devuelve una salida en texto plano, Muestra los ultimos 10 cambios y se usa cuando el plugin es wal2json.
SELECT * FROM pg_logical_slot_get_changes('mi_slot', NULL, 10);

-- Esta funcion devuelve una salida en bynario,  y se usa cuando el plugin es pgoutput. esta funcion la procesa y no podras ver mas los mismos datos 
SELECT * FROM pg_logical_slot_get_binary_changes('mi_slot', NULL, NULL, 'proto_version', '1', 'publication_names', 'pub_clientes');

-- Esta funcion nos permite consumir los datos sin procesarlos y podemos visualizarlos varias veces 
SELECT get_byte(data, 1), encode(substr(data, 24, 23), 'escape')  FROM pg_logical_slot_peek_binary_changes('mi_slot', NULL, NULL, 'proto_version', '1', 'publication_names', 'pub_clientes', 'messages', 'true') ;
```

### **Enviar mensaje desde el servidor publicador a los suscriptores**
enviar eventos personalizados en la replicación lógica.  Si necesitas comunicarse con sistemas externos sin modificar la base de datos.
```sql
SELECT pg_logical_emit_message(true, 'wal2json', 'HOLAAA ESTOY USANDO EL PLUGIN wal2json');
SELECT pg_logical_emit_message(true, 'pgoutput', 'HOLAAA ESTOY USANDO EL PLUGIN pgoutput');
```



### **Insertar registros en servidor publicador**
```sql
INSERT INTO clientes (nombre, email, fecha_registro)  
SELECT 
    'Cliente ' || id,  
    'cliente' || id || '@example4.com',  
    NOW() - (id || ' days')::INTERVAL  -- Cada fecha será distinta, restando días según el ID
FROM generate_series(1, 10) AS id;

select * from clientes;
```



---

### 🔄 ¿Qué pasa ahora?

- Cada vez que se hace un `INSERT`, `UPDATE` o `DELETE` en `ventas` en `db_origen`, el cambio se replica automáticamente 
- Puedes usar esto para análisis en tiempo real, backups distribuidos, o sincronización entre regiones.

---

## ✅ Ventajas

- Replicación **selectiva** (solo las tablas que necesitas).
- Compatible con **versiones diferentes** de PostgreSQL (en algunos casos).
- Útil para **migraciones**, **auditoría**, **ETL en tiempo real**.

---

## ⚠️ Desventajas

- No replica DDL (cambios en estructura).
- Requiere claves primarias o `REPLICA IDENTITY FULL`.
- Puede haber **retrasos** si el destino no consume rápido.
- Más compleja de configurar que la replicación física.



 
## 🧩 ¿Qué es un *replication slot* (slot de replicación)?

Un **slot de replicación** es una estructura que PostgreSQL usa para **mantener los cambios del WAL disponibles** hasta que un suscriptor (cliente de replicación) los haya recibido y procesado.
conclusion : Evita que PostgreSQL elimine archivos WAL que aún no han sido leídos por un suscriptor. Sin un replication slot, los registros WAL podrían eliminarse antes de que la réplica o cliente los capture, causando pérdida de datos en la sincronización.

### 🔧 ¿Para qué sirve?

- Evita que PostgreSQL elimine archivos WAL que aún no han sido enviados a un suscriptor.
- Garantiza que el suscriptor no pierda datos si se desconecta temporalmente.
- Actúa como un "marcador" de hasta dónde ha leído el cliente de replicación.
- Permite que la replicación se reanude desde el punto exacto donde se quedó.


---

## 🔄 ¿En qué tipos de replicación se usa?

| Tipo de replicación | ¿Usa replication slot? | Tipo de slot |
|---------------------|------------------------|--------------|
| **Streaming (física)** | ✅ Sí | `physical` |
| **Lógica (logical)**   | ✅ Sí | `logical` |

---

## 🧠 ¿Cuál es la diferencia?

- **Slot físico**: usado en replicación **streaming física** (standby servers). No necesita plugin.
- **Slot lógico**: usado en replicación **lógica** (como con `wal2json`, `pgoutput`). Requiere plugin.


 
### Otros valores:

| Valor de `wal_level` | ¿Permite replicación física? | ¿Permite replicación lógica? |
|----------------------|------------------------------|-------------------------------|
| `minimal`            | ❌ No                        | ❌ No                         |
| `replica`            | ✅ Sí                        | ❌ No                         |
| `logical`            | ✅ Sí                        | ✅ Sí                         |
 
 
 
  

## 🔄 ¿Se puede hacer replicación sin slot?

### 🔹 **Replicación física (streaming):**

- **Sí se puede hacer sin slot**, pero:
  - Solo si usas **replicación en modo archivo (archiving)** o configuraciones especiales.
  - **No es recomendable** porque si el standby se desconecta, puede perder WALs y requerir re-sincronización completa.

✅ **Lo ideal:** usar **slot físico** para garantizar continuidad.

---

### 🔹 **Replicación lógica:**

- **No se puede hacer sin slot.**
  - La replicación lógica **requiere obligatoriamente un slot lógico** para funcionar.
  - Es el mecanismo que permite rastrear los cambios en el WAL para convertirlos en eventos lógicos (como JSON).

---



## Validaciones extras 
```sql

ALTER SUBSCRIPTION sub_clientes DISABLE;

-- Verifica si el plugin wal2json está instalado
rpm -qla | grep wal2json

-- Verifica si hay procesos de replicación activos
SELECT * FROM pg_stat_wal_receiver; --- comando para ver lo que se recibe y saber cual es el servidor principal
SELECT * FROM pg_stat_replication;  --- comando para ver en el serv principal las ip serv soporte y ver la columna sync_state  puede tener el valor  async  y sync
SELECT slot_name, spill_txns, spill_count, spill_bytes, total_txns, total_bytes FROM pg_stat_replication_slots;
 
-- Verifica si hay funciones
SELECT proname FROM pg_proc WHERE proname LIKE '%slot%';


-- Borrar todo de la replica logica
	DROP SUBSCRIPTION my_subscription;
	DROP PUBLICATION my_publication;
	SELECT pg_drop_replication_slot('mi_slot');

-- Tablas 
 select proname from pg_proc where proname ilike '%slot%';
 select table_schema,table_name from information_schema.tables where table_name ilike '%slot%';
 
 select proname from pg_proc where proname ilike '%wal%';
 select table_schema,table_name from information_schema.tables where table_name ilike '%wal%';


select table_schema,table_name from information_schema.tables where table_name ilike '%publi%';
+--------------+--------------------------+
| table_schema |        table_name        |
+--------------+--------------------------+
| pg_catalog   | pg_publication           |
| pg_catalog   | pg_publication_namespace |
| pg_catalog   | pg_publication_rel       |
| pg_catalog   | pg_publication_tables    |
+--------------+--------------------------+

 select table_schema,table_name from information_schema.tables where table_name ilike '%subscription%';
+--------------+----------------------------+
| table_schema |         table_name         |
+--------------+----------------------------+
| pg_catalog   | pg_subscription            |
| pg_catalog   | pg_subscription_rel        |
| pg_catalog   | pg_stat_subscription       |
| pg_catalog   | pg_stat_subscription_stats |
+--------------+----------------------------+


 select name,setting from pg_settings  where name ilike '%wal%';
 select name,setting from pg_settings  where name ilike '%slot%';

SET logical_decoding_work_mem to '64kB';


-- Si retorna true, significa que el servidor está en modo standby (réplica).
-- Si retorna false, significa que el servidor es el primario y acepta escrituras
select pg_is_in_recovery();


SELECT slot_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(),restart_lsn)) AS lag, active from pg_replication_slots WHERE slot_type='logical';

```


### Extra 
```
-- ==============================================================================
-- 1. PERMISOS A NIVEL DE ESQUEMA (Contenedor principal)
-- ==============================================================================

-- USAGE: Permite al usuario entrar al esquema y "ver" que los objetos existen.
GRANT USAGE ON SCHEMA pglogical TO migration_admin;

-- ALL: Da control total sobre el esquema (crear tablas, alterarlo, etc.) para que la extensión opere.
GRANT ALL ON SCHEMA pglogical TO migration_admin;


-- ==============================================================================
-- 2. PERMISOS DE LECTURA (SELECT) EN METADATOS Y MONITOREO
-- ==============================================================================

-- pglogical.tables: Vista que lista todas las tablas configuradas para replicar en el sistema.
GRANT SELECT ON pglogical.tables TO migration_admin;

-- pglogical.depend: Rastrea dependencias internas para evitar borrar tablas activas en la réplica.
GRANT SELECT ON pglogical.depend TO migration_admin;

-- pglogical.local_node: Identifica la identidad y el rol de este servidor específico (si es proveedor o cliente).
GRANT SELECT ON pglogical.local_sync_status TO migration_admin;

-- pglogical.local_sync_status: Muestra el estado de sincronización en tiempo real de cada tabla (si está copiando o lista).
GRANT SELECT ON pglogical.local_sync_status TO migration_admin;

-- pglogical.node: Catálogo general que registra todos los servidores (nodos) involucrados en la red de replicación.
GRANT SELECT ON pglogical.node TO migration_admin;

-- pglogical.node_interface: Almacena las cadenas de conexión (IPs, puertos, usuarios) para comunicarse con otros nodos.
GRANT SELECT ON pglogical.node_interface TO migration_admin;

-- pglogical.queue: Cola de mensajes internos para enviar comandos especiales (como cambios de estructura DDL) a los destinos.
GRANT SELECT ON pglogical.queue TO migration_admin;

-- pglogical.replication_set: Lista los grupos lógicos de replicación creados (por ejemplo, el grupo 'default').
GRANT SELECT ON pglogical.replication_set TO migration_admin;

-- pglogical.replication_set_seq: Tabla intermedia que asocia qué secuencias (campos autoincrementables) van en cada grupo.
GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;

-- pglogical.replication_set_table: Tabla intermedia que asocia exactamente qué tablas físicas pertenecen a qué grupo de réplica.
GRANT SELECT ON pglogical.replication_set_table TO migration_admin;

-- pglogical.sequence_state: Guarda el estado y el último valor numérico de las secuencias para que no se dupliquen IDs.
GRANT SELECT ON pglogical.sequence_state TO migration_admin;

-- pglogical.subscription: Registra los datos de las suscripciones activas (solo contiene datos si este nodo recibe información).
GRANT SELECT ON pglogical.subscription TO migration_admin;

```

---

# Requisitos y Desventajas

La herramienta que elegiste, `pglogical`, es un arma excelente para este trabajo porque permite migraciones con *downtime* casi nulo, pero si no conoces sus puntos ciegos operativos, el proyecto colapsará antes de tocar la nube.


### ⚙️ FASE 1: Requisitos de Infraestructura y Motor (Habla Javier)

Para que `pglogical` pueda extraer la información en vivo sin destruir el rendimiento de tu servidor, necesitamos modificar el núcleo operativo de tu base de datos On-Premise.

* **Parámetros Críticos de Memoria (Reclaman Reinicio):**
* `wal_level = logical`: Absolutamente obligatorio. Le dice al motor que guarde el detalle lógico de cada transacción, no solo bloques físicos.
* `max_worker_processes`: Debes aumentarlo. `pglogical` lanza múltiples hilos de fondo por cada suscripción. Si este límite se topa, tu base de datos abortará conexiones legítimas.
* `max_replication_slots`: Mínimo 1 por cada base de datos que vayas a mover, pero te exijo configurar al menos 5 para tener margen de maniobra.
* `max_wal_senders`: Debe ser al menos igual al número de slots más tus procesos de respaldo físico actuales.
* `shared_preload_libraries`: Debes incluir `'pglogical'` en este parámetro en el archivo `postgresql.conf`.


* **Permisos de Red y Conectividad (Reglas de Lucas):** El servidor en la nube (Suscriptor) debe tener línea de vista directa (TCP/IP) hacia el puerto 5432 (o el que uses) de tu máquina On-Premise (Publicador).
* **Privilegios de Usuario (Reglas de Diego):** Necesitas un rol dedicado para la replicación con el atributo `REPLICATION`. Por estándares de confianza cero, no uses al superusuario `postgres` para esto.

### 📐 FASE 2: Requisitos de Estructura de Datos (Habla Marcos)

`pglogical` no lee los datos como archivos crudos, lee estructuras lógicas. Si tu diseño de datos es débil, la herramienta se negará a operar.

* **Llaves Primarias (Primary Keys) Obligatorias:** Este es un requisito inquebrantable. Cada tabla que desees replicar **DEBE** tener una llave primaria o una restricción de unicidad declarada como `REPLICA IDENTITY UNIQUE`. Si una tabla carece de esto, las operaciones `UPDATE` y `DELETE` fallarán en el destino porque el motor no sabrá qué fila modificar.
* **Instalación de la Extensión:** Debes instalar los binarios de `pglogical` a nivel de sistema operativo (con `apt` o `yum`) en ambos nodos, y luego ejecutar `CREATE EXTENSION pglogical;` en la base de datos origen y en la de destino.
* **Esquema Pre-existente:** Antes de encender la sincronización, el servidor en la nube debe tener creadas las bases de datos, los roles y la estructura vacía de las tablas (el DDL).


### 🚨 FASE 3: Desventajas y Vectores de Falla Crítica (Habla Rodrigo - El Gatekeeper)

Aquí es donde los desarrolladores novatos destruyen clústeres. `pglogical` no hace magia; es estrictamente un replicador de DML (Data Manipulation Language). Si asumes que es un espejo perfecto, fracasarás.

* **El DDL NO se Replica:** Si en el origen ejecutas un `ALTER TABLE`, `CREATE INDEX`, `TRUNCATE` o añades una nueva columna, **este cambio no viajará a la nube**. Debes coordinar y ejecutar manualmente los cambios estructurales primero en el destino y luego en el origen para no romper la replicación.
* **Las Secuencias (SERIAL/IDENTITY) son Estáticas:** La replicación lógica traslada el número insertado en la fila, pero **no sincroniza el estado del objeto de la secuencia**. Cuando hagas el *Switchover* (el corte final) para que tu aplicación empiece a escribir en la nube, si no actualizas manualmente las secuencias, tendrás colisiones de llave primaria masivas e inmediatas (`duplicate key value violates unique constraint`).
* **Sin Soporte para Large Objects:** Si tu base de datos utiliza la antigua API de `pg_largeobject` para guardar archivos binarios, `pglogical` los ignorará por completo.
* **Fragilidad ante Conflictos Lógicos:** Si un desarrollador o administrador inserta o borra una fila manualmente en el servidor de la Nube mientras la replicación está activa, generarás un conflicto. El hilo de `pglogical` chocará, se detendrá y comenzará a acumular lag.

### 💣 FASE 4: El Escenario de Desastre (Habla Héctor)

Mi responsabilidad es alertarte sobre cómo esta herramienta puede matar tu servidor principal si no la monitoreas.

* **Saturación de Disco por Caída de Red (Replication Slots):** Cuando el nodo On-Premise y la Nube pierden conexión (por un fallo del ISP o un firewall mal configurado), el *Replication Slot* le ordena al servidor origen: *"No borres los archivos WAL (Logs de transacciones), el suscriptor de la nube no los ha leído"*. Si la caída de red dura varias horas y tu sistema es altamente transaccional, tu disco duro On-Premise se llenará al 100% y **tu base de datos en producción se detendrá abruptamente**. Es mandatorio monitorear la vista `pg_replication_slots` y el tamaño de `pg_wal`.

 
---

#  **6 cosas críticas antes de migrar**:

* **Tablas sin llave primaria:** Encuentra los objetos que van a bloquear o hacer fallar la replicación de `pglogical`.
* **Columnas con secuencias automáticas:** Detecta qué contadores debes sincronizar manualmente en la nube para evitar choques de IDs.
* **Tamaño total en disco:** Mide el peso real de la tabla para calcular el tiempo de bloqueo al crearle la Llave Primaria.
* **Volumen de inserciones, actualizaciones y borrados:** Identifica si la tabla recibe transacciones en vivo o si es data histórica inactiva.
* **Total de escaneos secuenciales y por índice:** Cuantifica qué tan seguido lee tu aplicación esa tabla para medir su criticidad.
  

```
---> 1.- Buscar sí la columna con secuencia pero sin pk tiene algun duplicado: esto para poder crear la columna en PK.
---> 2.- Cambiar la a columna en PK en el serv migrado.
---> 3.- Actualizar secuencias manualmente, ya que no se actualiza de manera automatica.

COPY (
    
    WITH tablas_sin_pk AS (
        -- 1. Aislamos todas las tablas de usuario que no tienen un constraint tipo 'p' (Primary Key)
        -- Traemos 'c.reltuples' para obtener el total de filas estimado sin hacer COUNT(*)
        SELECT
            c.oid,
            n.nspname AS esquema,
            c.relname AS tabla,
            c.reltuples::bigint AS total_filas_estimado
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r' 
        AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
        AND NOT EXISTS (
            SELECT 1
            FROM pg_constraint con
            WHERE con.conrelid = c.oid
                AND con.contype = 'p'
        )
    ),
    columnas_con_secuencia AS (
        -- 2. Buscamos columnas que utilicen DEFAULT nextval() o que sean tipo IDENTITY nativo
        SELECT
            a.attrelid,
            a.attname AS columna_secuencia,
            pg_get_expr(d.adbin, d.adrelid) AS expresion_defecto
        FROM pg_attribute a
        LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
        WHERE a.attnum > 0
        AND NOT a.attisdropped
        AND (
            (d.adbin IS NOT NULL AND pg_get_expr(d.adbin, d.adrelid) ILIKE '%nextval%')
            OR a.attidentity IN ('a', 'd')
        )
    )
    -- 3. Integramos todo con las estadísticas de uso operativo, tamaño físico y conteo de filas
    SELECT
        tsp.esquema,
        tsp.tabla,
        tsp.total_filas_estimado, -- NUEVA COLUMNA AGREGADA DESDE PG_CLASS
        pg_size_pretty(pg_total_relation_size(tsp.oid)) AS tamano_total,
        COALESCE(ccs.columna_secuencia, 'Sin Secuencia') AS columna,
        CASE 
            WHEN ccs.columna_secuencia IS NOT NULL THEN 'SI' 
            ELSE 'NO' 
        END AS tiene_secuencia,
        ps.n_tup_ins AS filas_insertadas,
        ps.n_tup_upd AS filas_actualizadas,
        ps.n_tup_del AS filas_borradas,
        ps.seq_scan AS escaneos_secuenciales,
        ps.idx_scan AS escaneos_por_indice,
        (COALESCE(ps.seq_scan, 0) + COALESCE(ps.idx_scan, 0)) AS total_escaneos,
        COALESCE(TO_CHAR(ps.last_autovacuum, 'YYYY-MM-DD HH24:MI:SS'), 'Nunca') AS ultimo_autovacuum
    FROM tablas_sin_pk tsp
    LEFT JOIN columnas_con_secuencia ccs ON tsp.oid = ccs.attrelid
    LEFT JOIN pg_stat_user_tables ps ON tsp.oid = ps.relid
    ORDER BY 
        tiene_secuencia DESC,
        total_escaneos DESC,
        pg_total_relation_size(tsp.oid) DESC,
        ps.n_tup_ins DESC NULLS LAST, 
        tsp.esquema, 
        tsp.tabla 

) TO '/tmp/auditoria_deuda_tecnica.csv' WITH CSV HEADER DELIMITER ',';



```


 

## El Problema: ¿Qué pasa con las tablas sin Primary Key?

La replicación lógica (`pglogical` o nativa) funciona leyendo los cambios del WAL (Write-Ahead Log) y aplicándolos en el destino. Para hacer un `INSERT`, no hay problema. El caos empieza con los **`UPDATE`** y **`DELETE`**.

Si modificas o borras una fila, PostgreSQL necesita una forma inequívoca de saber *cuál* fila debe modificar en la base de datos de destino. Si no hay Primary Key (o un índice único equivalente):

1. **En `pglogical`:** Directamente **no se replicarán los `UPDATE` ni los `DELETE**` para esa tabla. La extensión no soporta la estrategia de respaldo `REPLICA IDENTITY FULL` de manera nativa (o genera errores/comportamiento indefinido según la versión exacta).
2. **En PostgreSQL Nativo / Cloud SQL:** Si intentas hacer un `UPDATE` o `DELETE` en la tabla origen, la base de datos arrojará un error inmediato bloqueando la transacción (`ERROR: cannot update table "nombre" because it does not have a replica identity`).

> ⚠️ **Excepción:** Si tu tabla es estrictamente de "solo inserción" (Append-only, como logs o históricos de auditoría) donde **nunca** se ejecuta un `UPDATE` ni un `DELETE`, la replicación funcionará. Pero si alguien o un proceso borra o edita algo, la replicación se romperá o ignorará el cambio.

---

## Soluciones Técnicas

Si no puedes agregar una Primary Key real por restricciones de la aplicación, tienes dos alternativas:

1. **Definir un Índice Único como Replica Identity:** Si la tabla tiene una combinación de columnas únicas que no aceptan nulos (`NOT NULL`), puedes decirle a Postgres que use ese índice para identificarse:
```sql
ALTER TABLE mi_tabla REPLICA IDENTITY USING INDEX mi_indice_unico;

```


2. **REPLICA IDENTITY FULL (Solo para Replicación Nativa de Postgres, no recomendado en pglogical):** Esto obliga a Postgres a usar **toda la fila completa** como llave.
```sql
ALTER TABLE mi_tabla REPLICA IDENTITY FULL;

```


*¡Cuidado!* Esto causa un impacto masivo en el rendimiento (Performance Penalty) porque en cada `UPDATE` o `DELETE`, el nodo destino tiene que hacer un *Sequential Scan* (escanear toda la tabla fila por fila) para encontrar el registro.

---

## Documentación Oficial

Para soportar esto con la documentación técnica de respaldo, aquí tienes los enlaces oficiales:

### 1. Documentación Oficial de `pglogical` (EnterpriseDB / 2ndQuadrant)

En la sección de limitaciones explícitas de `pglogical`, se especifica que requiere obligatoriamente una Primary Key o un índice válido para `UPDATE` y `DELETE`, y aclara que `REPLICA IDENTITY FULL` no es una opción viable de forma nativa para ellos:

* [EDB Docs - pglogical Limitations and restrictions](https://www.enterprisedb.com/docs/supported-open-source/pglogical2/limitations-and-restrictions/)
> *"PRIMARY KEY or REPLICA IDENTITY required. UPDATEs and DELETEs cannot be replicated for tables that lack a PRIMARY KEY or other valid replica identity..."*



### 2. Documentación Oficial de Google Cloud SQL (PostgreSQL)

Google Cloud SQL utiliza tanto la replicación nativa como `pglogical` dependiendo de tu configuración. En sus guías de arquitectura (como AlloyDB/Cloud SQL con entornos pglogical) especifican la recomendación crítica de las llaves primarias:

* [Google Cloud Docs - About the pglogical extension / Implementations](https://docs.cloud.google.com/alloydb/omni/linux/current/docs/about-pglogical)
> *"It is recommended that all replication tables must have a primary key... Tables that don't have primary keys, are static in nature, and are never UPDATED or DELETED, and supports only INSERTS."*



### 3. Documentación Core de PostgreSQL (Restricciones de Replicación Lógica)

Dado que Cloud SQL y `pglogical` corren sobre el motor de Postgres, las reglas de restricción del motor aplican siempre. La documentación oficial de Postgres explica el comportamiento del error por falta de identidad de réplica:

* [PostgreSQL Official Documentation - Logical Replication Restrictions](https://www.postgresql.org/docs/current/logical-replication-restrictions.html)
> *"If a table juxtaposed for replication lacks a primary key or a suitable unique index, replicating UPDATE or DELETE operations is not possible under the default replica identity."*

 
---

## Bibliografía
```

https://github.com/2ndQuadrant/pglogical

Réplicas de lectura de PostgreSQL: guía completa para comprenderlas, implementarlas y decidir cuándo las necesita -> https://medium.com/@jleonro/postgresql-read-replicas-complete-guide-to-understanding-implementing-and-deciding-when-you-need-c870f615930b

[PostgreSQL Replication Deep Dive] - https://medium.com/@danielonthenet/postgresql-replication-deep-dive-53b593243f3f

[Multi-Master] Active Active in Postgres 16 -> https://www.crunchydata.com/blog/active-active-postgres-16

Bidirectional Logical Replication in PostgreSQL 16 -> https://www.mydbops.com/blog/bidirectional-logical-replication-in-postgresql-16

wal2json -> https://github.com/eulerto/wal2json
CREATE SUBSCRIPTION -> https://www.postgresql.org/docs/current/sql-createsubscription.html
29.2. Subscription  -> https://www.postgresql.org/docs/current/logical-replication-subscription.html

Mastering PostgreSQL Logical Replication -> https://medium.com/@syedfahadkhalid93/mastering-postgresql-logical-replication-your-definitive-guide-for-seamless-upgrades-and-b619c3a23e3f
Streaming Logical Changes with wal2json in a PostgreSQL Patroni Cluster -> https://medium.com/@pawanpg0963/streaming-logical-changes-with-wal2json-in-a-postgresql-patroni-cluster-4ed2b3442f3e
Getting postgres logical replication changes using pgoutput plugin -> https://medium.com/@film42/getting-postgres-logical-replication-changes-using-pgoutput-plugin-b752e57bfd58
Replicación lógica con Postgres y pglogical -> https://davidcasr.medium.com/replicaci%C3%B3n-l%C3%B3gica-con-postgres-y-pglogical-91897ac79769

https://neon.com/docs/extensions/wal2json
https://amitkapila16.blogspot.com/2021/09/logical-replication-improvements-in.html

29.3. Logical Replication Failover -> https://www.postgresql.org/docs/17/logical-replication-failover.html?source=post_page-----4ed2b3442f3e---------------------------------------
47.1. Logical Decoding Examples -> https://www.postgresql.org/docs/17/logicaldecoding-example.html?source=post_page-----4ed2b3442f3e---------------------------------------
Chapter 48. Logical Decoding -> https://www.postgresql.org/docs/12/logicaldecoding.html
https://www.postgresql.org/docs/current/test-decoding.html

F.43. test_decoding  -> https://www.highgo.ca/2019/08/22/an-overview-of-logical-replication-in-postgresql/
```




