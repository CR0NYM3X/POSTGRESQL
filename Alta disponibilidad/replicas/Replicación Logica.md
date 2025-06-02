
 La **replicación lógica** en PostgreSQL permite copiar datos **a nivel de tabla** desde una base de datos origen hacia otra base de datos (que puede estar en el mismo servidor o en otro), **en tiempo real y de forma selectiva**. A diferencia de la replicación física, no copia todo el clúster, sino solo los cambios en ciertas tablas.

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

### 🔧 Paso 1: Configurar el servidor origen

**1.1. Asegúrate de tener:**

```conf
wal_level = logical
max_replication_slots = 4
max_wal_senders = 4
```

**1.2. Crear una publicación:**

```sql
CREATE PUBLICATION pub_ventas FOR TABLE ventas;
```

**Creación de un replication slot lógico**
```sql
SELECT * FROM pg_create_logical_replication_slot('mi_slot', 'pgoutput'); --  slot_name , plugin name
```

---

### 🔧 Paso 2: Configurar el servidor destino

**2.1. Crear la tabla `ventas` con la misma estructura.**

**2.2. Crear la suscripción:**

```sql
CREATE SUBSCRIPTION sub_ventas
CONNECTION 'host=ip_del_origen dbname=db_origen user=replicador password=secreta port=5432'
PUBLICATION pub_ventas;
WITH (slot_name = 'mi_slot');
```

---

### 🔄 ¿Qué pasa ahora?

- Cada vez que se hace un `INSERT`, `UPDATE` o `DELETE` en `ventas` en `db_origen`, el cambio se replica automáticamente en `db_destino`.
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
SELECT * FROM pg_stat_replication;


-- Verifica la configuración del servidor
SHOW wal_level;
SHOW max_replication_slots;
SHOW max_wal_senders;


-- Verifica si hay funciones
SELECT proname FROM pg_proc WHERE proname LIKE '%slot%';


-- Ver suscripciones activas
SELECT * FROM pg_subscription;

-- Ver conexiones de replicación en el servidor publicador
SELECT * FROM pg_stat_replication;
```


## Bibliografía
```


```


