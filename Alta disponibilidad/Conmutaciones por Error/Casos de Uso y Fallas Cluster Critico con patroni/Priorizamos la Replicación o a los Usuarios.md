
### 🚨 El Dilema del Standby: ¿Priorizamos la Replicación o a los Usuarios?

**Habla Javier (Alta Disponibilidad):**

Cuando tienes una réplica de solo lectura (*standby*), ocurren dos cosas en paralelo:

1. **Un usuario está ejecutando una consulta larga de lectura** (por ejemplo, un reporte de ventas en la réplica).
2. **El servidor primario envía transacciones nuevas** para ser aplicadas en la réplica via replicación física.

¿Qué pasa si la transacción que viene del primario necesita eliminar o modificar datos que el usuario está leyendo en ese preciso instante en la réplica? Ocurre un **conflicto de replicación**.

PostgreSQL tiene dos opciones: **matar la consulta del usuario** para mantener la réplica 100% al día, o **hacer esperar a la replicación** (lo que genera un retraso o *replication lag*). Aquí es donde entran estos dos parámetros, actuando como el **tiempo límite (timeout) que espera la réplica antes de cancelar la consulta del usuario**.

---

### ⚔️ LA DIFERENCIA TÉCNICA CLAVE

Ambos parámetros controlan cuánto tiempo máximo (900 segundos / 15 minutos en tu configuración) la réplica dejará "en pausa" la aplicación de datos nuevos antes de **desconectar violentamente la consulta del usuario** que está causando el conflicto. La diferencia es **el canal por donde llegan esos datos desde el primario**:

```
                              ┌─── Archivos WAL (WAL Archive) ───► max_standby_archive_delay
SERVIDOR PRIMARIO ────────────┤
                              └─── Transmisión en Vivo (Stream) ──► max_standby_streaming_delay

```

#### 1. `max_standby_archive_delay = 900s` (Replicación por Archivo / WAL Archive)

* **¿Cómo llegan los datos?:** La réplica obtiene los datos leyendo **archivos WAL completos** desde un repositorio de archivos (por ejemplo, un bucket de Google Cloud Storage o una carpeta compartida de respaldos).
* **¿Qué hace?:** Define que si un archivo WAL entrante entra en conflicto con una consulta que un usuario está corriendo en la réplica, el motor esperará **hasta 900 segundos** antes de cancelar la consulta del usuario para aplicar el archivo.
* **Contexto típico:** Ocurre principalmente durante la recuperación ante desastres (DRP), restauración desde respaldos o en arquitecturas de replicación asíncrona basada en archivos.

#### 2. `max_standby_streaming_delay = 900s` (Replicación por Streaming en Vivo)

* **¿Cómo llegan los datos?:** La réplica recibe las transacciones **en tiempo real y milisegundo a milisegundo** a través de una conexión de red directa TCP (*Streaming Replication*) con el servidor primario.
* **¿Qué hace?:** Define que si una transacción en vivo transmitida por la red entra en conflicto con la consulta de un usuario en la réplica, el motor esperará **hasta 900 segundos** antes de matar la consulta del usuario.
* **Contexto típico:** Es el escenario del día a día en entornos de Alta Disponibilidad (HA) con nodos secundarios de lectura.

---

### 📊 TABLA COMPARATIVA DIRECTA

| Parámetro | Canal de Origen de Datos | Sensibilidad al Tráfico en Vivo | Impacto si se alcanza el tiempo (900s) |
| --- | --- | --- | --- |
| **`max_standby_archive_delay`** | Archivos WAL empaquetados (`pg_wal` / Repositorio). | Baja / Media (Restauración diferida). | Se cancela la consulta del usuario para aplicar el archivo WAL acumulado. |
| **`max_standby_streaming_delay`** | Conexión TCP en vivo directamente desde el primario. | **Crítica** (Afecta el *Replication Lag* en tiempo real). | Se cancela la consulta del usuario para evitar que la réplica se atrase con respecto al primario. |

---

### 💡 El Veredicto de Javier y Héctor

> "Al dejar ambos parámetros en `900s` (15 minutos), estás protegiendo a tus analistas o usuarios que ejecutan reportes pesados en la réplica para que no se les desconecte a la primera de cambio.
> Sin embargo, la contraparte es que tu réplica puede acumular hasta **15 minutos de retraso en los datos (*replication lag*)** si hay consultas largas bloqueando la replicación. Si en esos 15 minutos tu servidor primario explota y necesitas promover la réplica a primario, tendrás que esperar a que aplique los 15 minutos de datos acumulados."
>
> 
