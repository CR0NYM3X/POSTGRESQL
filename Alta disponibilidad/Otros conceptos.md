 
### ¿Qué es el p99?

El **p99** representa el **Percentil 99**. Es una métrica estadística utilizada para medir la latencia (el tiempo de respuesta) de tus consultas o transacciones.

* **Significado técnico:** El 99% de las peticiones se completaron en ese tiempo o menos.
* **El 1% restante:** Solo el 1% de las peticiones tardaron más que ese valor.

### ¿Por qué no usamos el Promedio (Average)?

El promedio es "mentiroso" en bases de datos. Si tienes 99 consultas que tardan 10ms y una que se bloquea y tarda 10 segundos, el promedio subirá drásticamente, pero no te dirá la verdad sobre la experiencia de la mayoría, ni te mostrará claramente que tienes un "outlier" (valor atípico) peligroso.

### Comparativa de Percentiles en PostgreSQL

| Métrica | Lo que nos dice | Importancia en HADR |
| --- | --- | --- |
| **p50 (Mediana)** | El tiempo "típico". El 50% de los usuarios vive aquí. | Salud general del sistema. |
| **p95** | El umbral de buen servicio. | Es el estándar para SLAs (Service Level Agreements). |
| **p99** | **El peor escenario común.** | Aquí detectamos bloqueos de disco (I/O spikes), esperas de locks o saturación de red en replicación. |
| **Max** | La consulta más lenta de todas. | Útil para debuggear fallos catastróficos puntuales. |

---

### ¿Por qué es crítico en HADR y Replicación?

En un entorno de alta disponibilidad con PostgreSQL, el p99 es vital por estas razones:

1. **Replicación Sincrónica:** Si usas `synchronous_commit = on`, el p99 de tus escrituras en el nodo primario depende totalmente del p99 de la red y del disco en el nodo standby. Si el p99 de la red sube, toda tu aplicación se siente lenta.
2. **Checkpoint Spikes:** PostgreSQL escribe datos al disco en ciclos (checkpoints). Un p99 alto suele revelar que el almacenamiento no está soportando bien el flujo de escritura durante estos ciclos.
3. **Tail Latency:** En HADR, queremos que la recuperación sea predecible. Si el p99 de la aplicación es inconsistente, es señal de que hay contención de recursos que podría causar un failover innecesario.

> **Regla de oro:** Un sistema sano tiene un p99 lo más cercano posible al p95. Si hay mucha distancia entre ellos, tienes un sistema "inestable" o con "colas" (queuing) intermitentes.

 
--- 



### ¿Qué significa QPS?

**QPS** son las siglas de **Queries Per Second** (Consultas por Segundo). Es la métrica reina para medir el **Throughput** o rendimiento de tu servidor de PostgreSQL.

Indica cuántas peticiones está procesando tu base de datos en un segundo exacto. En el mundo de HADR, esto se divide usualmente en dos flujos:

1. **Read QPS:** Consultas de lectura (`SELECT`).
2. **Write QPS:** Consultas de escritura (`INSERT`, `UPDATE`, `DELETE`).

 
### ¿Por qué es fundamental para un experto en HADR?

En una arquitectura de alta disponibilidad, el QPS es el termómetro para tomar decisiones críticas:

* **Dimensionamiento (Scaling):** Si tu nodo primario llega a su límite de QPS (digamos, 5,000 QPS) y el uso de CPU está al 90%, es hora de implementar **Read Replicas** para desviar el tráfico de lectura.
* **Detección de Anomalías:** Si de repente el QPS cae a cero pero las conexiones siguen abiertas, probablemente tienes un **Deadlock** masivo o un problema de red entre el balanceador de carga y la base de datos.
* **Planificación de Failover:** Al hacer un failover (pasar del primario al standby), debemos estar seguros de que el nodo secundario tiene la capacidad de soportar el mismo nivel de QPS que el primario sin degradar el p99.
 
### La relación tóxica: QPS vs. Latencia (p99)

Como especialista, siempre analizo estas dos métricas juntas. Existe un punto de inflexión llamado **Punto de Saturación**:

1. A medida que aumentas el **QPS** (más carga), la latencia suele mantenerse estable.
2. Llega un momento en que el hardware (CPU/Disco) no da más.
3. En ese punto, el **QPS se estanca** (o baja) y el **p99 se dispara** (latencia infinita).

### ¿Cómo medirlo en PostgreSQL?

PostgreSQL no te da un "velocímetro" de QPS en tiempo real por defecto, pero lo calculamos usando la vista `pg_stat_database`.

Una forma rápida de estimarlo es restando el total de transacciones en un intervalo de tiempo:

Donde  es el contador acumulado de transacciones exitosas.

 
### Diferencia clave: QPS vs. TPS

A veces verás **TPS** (Transactions Per Second).

* **QPS:** Cuenta cada sentencia individual.
* **TPS:** Cuenta bloques de transacciones (`BEGIN` ... `COMMIT`). En aplicaciones que agrupan muchas operaciones en una sola transacción, el QPS será mucho más alto que el TPS.
 
