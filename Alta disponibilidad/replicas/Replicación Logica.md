
 La **replicación lógica** se introdujo a partir de la versión 10 y permite copiar datos **a nivel de tabla** desde una base de datos origen hacia otra base de datos (que puede estar en el mismo servidor o en otro), **en tiempo real y de forma selectiva**. A diferencia de la replicación física, no copia todo el clúster, sino solo los cambios en ciertas tablas.

---

## 🧠 ¿Cómo funciona la replicación lógica?
en la **replicación lógica** de PostgreSQL, no se usa la base de datos `replication`. A diferencia de la **replicación física**, donde se clona el almacenamiento completo de la base de datos, la replicación lógica trabaja a nivel de **publicaciones y suscripciones**.

1. **El servidor origen (publisher)** registra los cambios en el WAL con `wal_level = logical`.
2. Se crea un **slot de replicación lógica** que captura los cambios.
3. Se define una **publicación** (`CREATE PUBLICATION`) que especifica qué tablas se replicarán.
4. En el servidor destino (subscriber), se crea una **suscripción** (`CREATE SUBSCRIPTION`) que se conecta al origen y aplica los cambios.

---

## 📦 Ejemplo real: replicación lógica entre dos bases PostgreSQL

### 🎯 Escenario:
Tienes una base de datos principal (`db_origen`) y quieres replicar en tiempo real solo la tabla `ventas` hacia otra base (`db_destino`) para análisis o backup.

---

### 🔧 Paso 1: Configurar el servidor origen/Publicador



**1.1. wal2json**
es un decodificador de cambios en PostgreSQL que te permite transformar los registros **WAL** en formato **JSON**, lo que facilita la replicación lógica. Aquí están los pasos clave para configurarla.
wal2json no necesita shared_preload_libraries porque es un decodificador lógico de WAL que se carga dinámicamente cuando se usa un replication slot

```conf
 /sysx/data11/DATANEW/17 $ rpm -qa | grep wal2json
wal2json_16-2.6-1PGDG.rhel8.x86_64
wal2json_17-2.6-2PGDG.rhel8.x86_64
```

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
```

**Creación de un replication slot lógico**
```sql
SELECT * FROM pg_create_logical_replication_slot('mi_slot', 'pgoutput'); --  slot_name , plugin name pgoutput o wal2json
```

---

### 🔧 Paso 2: Configurar el servidor destino/suscriptor

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
WITH (enabled=false, slot_name = 'mi_slot', create_slot = false, copy_data = true, streaming = true );

enabled=false -> la suscripción se crea, pero no empieza a recibir datos hasta que la conexión se habilite manualmente con ENABLE
create_slot = true: Crea el slot automáticamente si no existe.
slot_name: Asigna un replication slot para asegurar retención de WAL.
streaming = true: Habilita la recepción en tiempo real, reduciendo latencia.
copy_data = true :  se copian todos los datos actuales de las tablas en la publicación. ✅ Si copy_data = false → Solo se replican los cambios futuros y no se copian los datos ya existentes.


```


**2.2. Habilitar la suscripción:**
```sql
ALTER SUBSCRIPTION sub_clientes ENABLE; -- Activa la suscripción si estaba deshabilitada.
ALTER SUBSCRIPTION sub_clientes REFRESH PUBLICATION; -- sincronizar la suscripción con el publicador en caso de que haya cambios en las publicaciones


```



### **Escuchar cambios desde un slot lógico**
Si quieres recibir los cambios en tiempo real, puedes usar `pg_recvlogical`, una herramienta de PostgreSQL:

```bash
pg_recvlogical -d mi_base -S mi_slot  -P wal2json --start -f -


$ pg_recvlogical -d postgres --slot test_slot --create-slot -P wal2json
$ pg_recvlogical -d postgres --slot test_slot --start -o pretty-print=1 -o add-msg-prefixes=wal2json -f -

```


# Verificar los cambios sin iniciar captura en tiempo real
Recuperar los cambios almacenados en un replication slot lógico.

```sql
-- los últimos 10 cambios:
SELECT * FROM pg_logical_slot_get_changes('mi_slot', NULL, 10);
```

# Enviar mensaje desde el servidor publicador a los suscriptores
enviar eventos personalizados en la replicación lógica.  Si necesitas comunicarse con sistemas externos sin modificar la base de datos.
```sql
SELECT pg_logical_emit_message(true, 'wal2json', 'this message will be delivered');
SELECT pg_logical_emit_message(true, 'pgoutput', 'this message will be filtered');
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

## 🧠 Resumen final

| Tipo de replicación | ¿Requiere slot? | Tipo de slot | ¿Puede funcionar sin slot? |
|---------------------|------------------|--------------|-----------------------------|
| Física (streaming)  | Opcional (pero recomendado) | `physical` | Sí, pero con riesgo de pérdida de datos |
| Lógica              | ✅ Obligatorio   | `logical`    | ❌ No                        |

 



## Validaciones extras 
```sql

-- Verifica si el plugin wal2json está instalado
SELECT * FROM pg_available_extensions WHERE name = 'wal2json';

-- Verifica si hay slots de replicación lógica activos
SELECT slot_name, plugin, slot_type, active FROM pg_replication_slots;

	slot_type = physical → Réplica física (streaming)
	slot_type = logical → Réplica lógica
	plugin = wal2json o pgoutput → Lógica
	plugin = (null) → Física

-- Verifica si hay procesos de replicación activos
SELECT * FROM pg_stat_wal_receiver; --- comando para ver lo que se recibe y saber cual es el servidor principal
SELECT * FROM pg_stat_replication;  --- comando para ver en el serv principal las ip serv soporte y ver la columna sync_state  puede tener el valor  async  y sync

 
-- Verifica si hay funciones
SELECT proname FROM pg_proc WHERE proname LIKE '%slot%';


-- Ver suscripciones activas
SELECT * FROM pg_subscription;
SELECT * FROM pg_stat_subscription;


 
-- Borrar todo de la replica logica
	DROP SUBSCRIPTION my_subscription;
	DROP PUBLICATION my_publication;
	SELECT pg_drop_replication_slot('mi_slot');

-- Tablas 
 select proname from pg_proc where proname ilike '%slot%';
 select table_schema,table_name from information_schema.tables where table_name ilike '%slot%';
 
 select proname from pg_proc where proname ilike '%wal%';
 select table_schema,table_name from information_schema.tables where table_name ilike '%wal%';
 
 select name,setting from pg_settings  where name ilike '%wal%';
 select name,setting from pg_settings  where name ilike '%slot%';

```




## Bibliografía
```
https://github.com/eulerto/wal2json
https://www.postgresql.org/docs/current/sql-createsubscription.html
https://www.postgresql.org/docs/current/logical-replication-subscription.html

```


