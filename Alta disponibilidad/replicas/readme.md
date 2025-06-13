 
## 🎯 ¿Para qué sirve hacer réplicas en PostgreSQL?

### ✅ 1. **Alta disponibilidad (High Availability)**
- La replicación permite que una base de datos esté disponible incluso si el servidor principal falla. Los datos se copian a uno o más servidores de réplica, que pueden asumir el rol del servidor principal en caso de fallo.


### ✅ 2. **Balanceo de carga (Load Balancing)**
- Las réplicas pueden ser utilizadas para distribuir la carga de trabajo, permitiendo que las consultas de solo lectura se ejecuten en los servidores de réplica, aliviando la carga del servidor principal.

### ✅ 3. **Recuperación ante desastres (Disaster Recovery)**
- En caso de un desastre, las réplicas pueden ser utilizadas para restaurar rápidamente los datos y minimizar el tiempo de inactividad.

### ✅ 4. **Análisis sin afectar producción**
- Puedes hacer análisis pesados o pruebas en una réplica sin afectar el rendimiento del servidor principal.

### ✅ 5. **Migraciones o actualizaciones**
- Puedes usar una réplica lógica para migrar datos entre versiones diferentes de PostgreSQL o hacia otro sistema.

### ✅ 6. **Integración con otros sistemas**
- La replicación lógica permite enviar cambios en tiempo real a sistemas como Kafka, Elasticsearch, BigQuery, etc.

---

## 🔄 ¿Cuándo usar cada tipo?

| Objetivo | Tipo de réplica recomendada | ¿Por qué? |
|---------|------------------------------|-----------|
| Alta disponibilidad | **Streaming (física)** | Réplica exacta del servidor, lista para tomar el control. |
| Balanceo de carga | **Streaming (física)** | Ideal para consultas de solo lectura. |
| Análisis o BI | **Lógica** | Puedes replicar solo ciertas tablas. |
| Integración con otros sistemas | **Lógica** | Permite enviar cambios en formato JSON o eventos. |
| Migración entre versiones | **Lógica** | Compatible entre versiones distintas. |

### 🔍 Comparación: Replicación en Streaming vs. Replicación Lógica

 

| **Característica**             | **Replicación en Streaming (Física)**                              | **Replicación Lógica**                                                                 |
|-------------------------------|---------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| **Nivel de replicación**      | A nivel de bloque de disco (físico)                                | A nivel de cambios en filas y tablas (lógico)                                         |
| **Uso del WAL**               | Se transmite tal cual, binario                                     | Se decodifica el WAL en cambios lógicos (INSERT, UPDATE, DELETE)                     |
| **Requiere estructura idéntica** | Sí (mismo esquema, extensiones, etc.)                              | No necesariamente (puede haber diferencias en tablas, columnas, etc.)                |
| **Flexibilidad**              | Limitada                                                           | Alta (puedes replicar solo algunas tablas, transformar datos, etc.)                  |
| **Casos de uso**              | Alta disponibilidad, failover                                      | Integración, migraciones, replicación parcial, multi-master (con herramientas externas) |
| **Transmisión del WAL**       | Se transmite el WAL completo en formato binario a cada réplica     | Cada suscriptor recibe solo los cambios relevantes del publicar, y ya decodificados desde el WAL usando el plugin lógico (pgoutput, wal2json, etc.)       |
 

---
 
### 🔹 **Failover**
El **failover** ocurre cuando el **nodo primario** falla inesperadamente y un nodo **standby** se convierte automáticamente en el nuevo **nodo primario**.  
✅ Se activa de manera automática en sistemas configurados con monitoreo y failover.  
✅ Evita la caída total del servicio.  
✅ Se usa en escenarios de emergencia cuando el servidor principal deja de funcionar.  
Ejemplo de comando manual:
 
### 🔹 **Switchover**
El **switchover** es un proceso planificado en el que el nodo **primario** y uno **standby** intercambian roles de forma controlada.  
✅ Se realiza sin que haya fallos en el sistema.  
✅ Se usa para mantenimiento o actualizaciones del nodo primario.  
✅ Permite cambiar de líder sin interrupciones.  
 

💡 **Diferencia clave:**  
- **Failover** = Evento inesperado, ocurre por una falla.  
- **Switchover** = Cambio intencional y programado.


---

## ⚠️ Consideraciones

- La **replicación física** es más simple y rápida, pero menos flexible.
- La **replicación lógica** es más flexible (puedes elegir tablas), pero requiere más configuración.
- Ambas pueden coexistir si configuras `wal_level = logical`.

 

## 🔍 Niveles de `wal_level` en PostgreSQL

### 1. `minimal`
- **¿Qué hace?**  
  Registra solo lo estrictamente necesario para la recuperación ante fallos.
- **Uso típico:**  
  Operaciones de carga masiva (`COPY`, `INSERT`) cuando no se necesita replicación ni puntos de recuperación avanzados.
- **Ventajas:**  
  - Menor volumen de WAL.
  - Mejor rendimiento en operaciones masivas.
- **Desventajas:**  
  - No permite replicación.
  - No se puede usar para backups PITR (Point-In-Time Recovery).

---

### 2. `replica` (antes llamado `archive`)
- **¿Qué hace?**  
  Registra suficiente información para replicación física y recuperación PITR.
- **Uso típico:**  
  Replicación física entre servidores PostgreSQL (standby).
- **Ventajas:**  
  - Permite replicación física.
  - Compatible con herramientas de backup como `pg_basebackup`.
- **Desventajas:**  
  - No permite replicación lógica.
  - Más volumen de WAL que `minimal`.

---

### 3. `logical`
- **¿Qué hace?**  
  Registra todos los cambios necesarios para replicación lógica (como `wal2json`, `pgoutput`, etc.).
- **Uso típico:**  
  - Replicación lógica.
  - Integración con sistemas externos (Kafka, Debezium, etc.).
  - Captura de datos en cambio (CDC).
- **Ventajas:**  
  - Permite replicación lógica y física.
  - Ideal para arquitecturas orientadas a eventos.
- **Desventajas:**  
  - Mayor volumen de WAL.
  - Puede impactar el rendimiento si no se gestiona bien.

 

# Conceptos que se usan en las replicas 
```sql

Maestro/Primario
Esclavo/secundario/standby

- **Activo-Activo**:  En PostgreSQL 16, se ha mejorado la replicación lógica para permitir una configuración Activo-Activo, donde dos instancias de PostgreSQL pueden recibir escrituras simultáneamente y sincronizar los cambios entre ellas.
En este modelo, todos los nodos están operativos y procesan solicitudes y cambios simultáneamente. Esto permite distribuir la carga de trabajo entre múltiples servidores, mejorando el rendimiento y la disponibilidad. Si un nodo falla, los demás continúan funcionando sin interrupciones.

- **Activo-Pasivo**: Aquí, solo un nodo está activo y maneja las solicitudes, mientras que otro nodo permanece en espera (pasivo). Si el nodo activo falla, el pasivo puede toma el control mediante failover. Este enfoque es más simple y garantiza estabilidad, pero no aprovecha los recursos del nodo pasivo hasta que sea necesario.

El **split-brain** es un problema que ocurre en sistemas de alta disponibilidad y replicación, cuando dos nodos **pierden comunicación entre sí**, pero **ambos creen que son el primario** al mismo tiempo.
----------------------------------------------------------------------------------------------------------------------------------------------------------------
El **quórum** es el número mínimo de nodos que deben estar **de acuerdo** para tomar decisiones dentro de un clúster distribuido, como el failover en PostgreSQL con **Repmgr**, **Patroni**, o sistemas como **etcd/Consul**.  

  **¿Cómo funciona el quórum en alta disponibilidad?**  
  **1. Se requiere mayoría (más del 50%)**  
- Si tienes 5 nodos en total, **al menos 3 deben estar activos y en consenso** para tomar decisiones.  
- Evita que un solo nodo pueda decidir unilateralmente.  

  **2. Impide problemas de split-brain**  
- Si un primario falla y no hay quórum, **no se elige un nuevo primario** hasta que haya consenso.  
- Protege contra la promoción accidental de múltiples primarios.  


  **Ejemplo real de quórum en PostgreSQL con 3 nodos**  
  *Si tienes 3 nodos (`pgmaster`, `pgslave1`, `pgslave2`) y `pgmaster` falla:*  
-  Si **solo `pgslave1` sigue activo**, no hay quórum y no ocurre failover.  
-  Si **`pgslave1` y `pgslave2` siguen activos**, hay quórum y uno de ellos se promueve a primario.  
----------------------------------------------------------------------------------------------------------------------------------------------------------------

¿Qué significa el consenso en términos generales?  Es un acuerdo entre múltiples participantes → Un grupo debe tomar una decisión colectiva basada en reglas claras.  Evita que haya decisiones individuales incorrectas → Por ejemplo, en replicación de bases de datos, un nodo no puede decidir solo convertirse en primario sin confirmación de los demás.  Se usa en algoritmos de failover y gestión de sistemas distribuidos → Como Raft, Paxos y Etcd, que permiten que los servidores acuerden quién es el líder.
----------------------------------------------------------------------------------------------------------------------------------------------------------------

CAP Theorem → En bases de datos distribuidas, puedes tener Consistencia (C), Disponibilidad (A) o Tolerancia a Particiones (P), pero nunca las tres simultáneamente.
----------------------------------------------------------------------------------------------------------------------------------------------------------------

Un Data Warehouse es un sistema de almacenamiento y gestión de datos diseñado para facilitar el análisis y la toma de decisiones en una organización. Funciona como un repositorio central donde se integran y estructuran grandes volúmenes de información provenientes de múltiples fuentes.

```

# Conocimiento esencial para diseñar arquitecturas distribuidas eficientes.  

- Ley de Amdahl
- Ley de Gunther
- Fórmula de latencia en redes distribuidas
- Fórmula de Throughput
- Fórmula de Consistencia CAP
- Teorema de Brewer (PACELC)
- Ley de Little
- Fórmula de escalabilidad de Gustafson
---

### **📌 Ley de Amdahl – Límite de aceleración en paralelización**  

📍 **Fórmula general**  

$$  S = \frac{1}{(1 - P) + \frac{P}{N}}  $$

📍 **Significado de cada variable**  
- **S (Speedup)** → **Variable**: Es el resultado final de cuánto mejora el rendimiento del sistema.  
- **P (Parallelizable Fraction)** → **Variable**: Porcentaje del sistema que puede ejecutarse en paralelo.  
- **N (Number of Processors)** → **Variable**: Cantidad de nodos o procesadores usados en paralelo.  
- **(1 - P)** → **Constante**: Representa la parte del sistema que **siempre será secuencial** y no se puede paralelizar.  

📍 **Ejemplo práctico**  
Supongamos que queremos procesar un conjunto de datos en PostgreSQL:  
- **El 80% de la tarea puede ejecutarse en paralelo** (`P = 0.8`).  
- **Usaremos 4 servidores** (`N = 4`).  

Aplicamos la fórmula:  

$$ S = \frac{1}{(1 - 0.8) + \frac{0.8}{4}} $$  

$$ S = \frac{1}{0.2 + 0.2} $$

$$ S = \frac{1}{0.4} = 2.5 $$

📌 **Conclusión**  
Aunque agreguemos **4 nodos**, el sistema solo se vuelve **2.5 veces más rápido**, porque aún hay una fracción **(1 - P)** que nunca podrá paralelizarse. Este principio es clave en sistemas distribuidos: más servidores no siempre significan más velocidad.

---

### **📌 Ley de Gunther – Límite de escalabilidad en un sistema**  

📍 **Fórmula general**  

$$ X(N) = \frac{N}{1 + \sigma (N - 1)} $$

📍 **Significado de cada variable**  
- **X(N) (Rendimiento escalado)** → **Variable**: Resultado final de cuánto mejora el rendimiento real del sistema con `N` nodos.  
- **N (Number of Nodes)** → **Variable**: Cantidad de servidores en el sistema distribuido.  
- **σ (Contention Factor)** → **Variable**: Porcentaje de contención por recursos compartidos en el sistema.  
- **El número "1" en el denominador** → **Constante**: Representa la ejecución sin contención.  

📍 **Ejemplo práctico**  
Supongamos que queremos **ampliar un clúster de bases de datos** con Citus:  
- **Tenemos 10 nodos** (`N = 10`).  
- **La contención causada por comunicación es 30%** (`σ = 0.3`).  

Aplicamos la fórmula:  

$$ X(10) = \frac{10}{1 + 0.3 (10 - 1)} $$

$$ X(10) = \frac{10}{1 + 2.7} $$

$$ X(10) = \frac{10}{3.7} = 2.7 $$

📌 **Conclusión**  
Aunque agregamos **10 nodos**, el rendimiento **solo se multiplica por 2.7** debido a la contención de recursos compartidos. Esto demuestra que simplemente agregar más servidores no siempre es la mejor estrategia sin optimización.

---

### **📌 Fórmula de latencia en redes distribuidas**  

📍 **Fórmula general**  

$$ L = RTT + \frac{S}{B} $$

📍 **Significado de cada variable**  
- **L (Latency)** → **Variable**: Tiempo total que tarda una operación en completarse en el sistema distribuido.  
- **RTT (Round Trip Time)** → **Constante**: Tiempo de ida y vuelta de los paquetes en la red.  
- **S (Size of Message)** → **Variable**: Tamaño del dato que se transmite en la red.  
- **B (Bandwidth)** → **Variable**: Velocidad de transmisión de la red (Mbps).  

📍 **Ejemplo práctico**  
Si tenemos una conexión donde:  
- **RTT es 50 ms** (`RTT = 50`).  
- **El mensaje tiene 5 MB** (`S = 5000 KB`).  
- **El ancho de banda es 100 Mbps** (`B = 100000 KB/s`).  

Aplicamos la fórmula:  

$$ L = 50 + \frac{5000}{100000} $$

$$ L = 50 + 0.05 = 50.05 ms $$

📌 **Conclusión**  
La latencia total es **50.05 ms**, y lo que más afecta el rendimiento es el **RTT**, que es una constante del sistema. Aunque se aumente el ancho de banda, el tiempo mínimo de ida y vuelta **siempre será 50 ms**.


 
---
 

### **📌 Fórmula de Throughput – Capacidad del sistema para procesar operaciones**  

📍 **Fórmula general**  

$$ T = \frac{N}{L} $$  

📍 **Significado de cada variable**  
- **T (Throughput)** → **Variable**: Indica cuántas operaciones por segundo puede manejar el sistema.  
- **N (Number of Transactions)** → **Variable**: Es la cantidad total de operaciones que el sistema debe procesar.  
- **L (Latency per Transaction)** → **Variable**: Tiempo que toma cada operación en completarse.  

📍 **Valores constantes:**  
✅ **La estructura de la ecuación** → Siempre será una **división entre cantidad de operaciones y su latencia**, ya que el concepto de rendimiento no cambia.  

📍 **Ejemplo práctico**  
Imaginemos que tenemos un sistema distribuido con **10,000 operaciones** (`N = 10,000`) y cada transacción tarda **500 ms** (`L = 0.5 segundos`). Aplicamos la fórmula:  

$$ T = \frac{10,000}{0.5} $$  

$$ T = 20,000 \text{ operaciones/segundo} $$  

📌 **Conclusión**  
Este sistema es capaz de procesar **20,000 operaciones por segundo**. Si queremos mejorar el rendimiento, podemos:  
- **Reducir la latencia (`L`)** optimizando consultas.  
- **Aumentar la cantidad de nodos** para procesar más transacciones en paralelo.  


---
### **📌 Fórmula de Consistencia CAP – Equilibrio en sistemas distribuidos**  

📍 **Fórmula general**  
El **Teorema CAP** establece que un sistema distribuido **puede garantizar solo dos de tres propiedades**:  

$$  C + A + P \neq 3 $$  

Donde:  
- **C (Consistency)** → **Variable**: Garantiza que todos los nodos ven los mismos datos al mismo tiempo.  
- **A (Availability)** → **Variable**: Asegura que cada solicitud recibe una respuesta, incluso si algunos nodos fallan.  
- **P (Partition Tolerance)** → **Constante**: El sistema sigue funcionando a pesar de fallos en la red.  

📍 **Ejemplo práctico**  
Supongamos que tenemos una base de datos distribuida y ocurre una **falla de red**.  
- Si priorizamos **Consistencia (C) y Partición (P)**, el sistema **rechazará algunas solicitudes** para garantizar datos correctos.  
- Si priorizamos **Disponibilidad (A) y Partición (P)**, el sistema **seguirá respondiendo**, pero algunos datos pueden estar desactualizados.  

📌 **Conclusión**  
No es posible tener **las tres propiedades al mismo tiempo**. Cada sistema debe elegir entre **CP (consistencia y tolerancia a fallos)** o **AP (disponibilidad y tolerancia a fallos)** según sus necesidades.  

---
### **📌 Teorema de Brewer (PACELC) – Extensión del CAP Theorem**  
El **PACELC Theorem** es una extensión del **CAP Theorem**, que introduce un nuevo concepto clave en sistemas distribuidos: **latencia**.  

📌 **¿Qué significa PACELC?**  
El acrónimo representa:  
- **P** → **Partitioning** (Partición en la red).  
- **A** → **Availability** (Disponibilidad).  
- **C** → **Consistency** (Consistencia).  
- **E** → **Else** (Si no hay partición).  
- **L** → **Latency** (Latencia).  
- **C** → **Consistency** (Consistencia).  

📍 **Fórmula conceptual**  
Si hay **partición en la red**, el sistema debe elegir entre **Consistencia (C) o Disponibilidad (A)**.  
Si **no hay partición**, el sistema debe elegir entre **Latencia baja (L) o Consistencia (C)**.  

📌 **Importancia:**  
Este teorema amplía el **CAP Theorem**, agregando la dimensión de **latencia** en sistemas distribuidos.  

📌 **¿Cómo funciona PACELC?**  
El teorema establece dos escenarios:  
1. **Si hay una partición en la red (P)** → Se debe elegir entre **Disponibilidad (A) o Consistencia (C)** (como en el CAP Theorem).  
2. **Si no hay partición (Else - E)** → Se debe elegir entre **Latencia baja (L) o Consistencia (C)**.  

📌 **Ejemplo práctico**  
- **Google Spanner** prioriza **consistencia** en todo momento (**PC/EC**).  
- **Cassandra** prioriza **disponibilidad y baja latencia** (**PA/EL**).  

📌 **Importancia**  
PACELC mejora el CAP Theorem al considerar **rendimiento y latencia**, lo que es crucial en bases de datos distribuidas y aplicaciones en la nube.  

📌 **Dónde se usa:**  
- Diseño de **bases de datos distribuidas** como Cassandra, Spanner y Citus.  
- Evaluación de **arquitecturas de microservicios**.  
- Optimización de **sistemas de almacenamiento en la nube**.  

--- 
 
### **📌 Ley de Little – Relación entre tiempo de respuesta y concurrencia**  
📍 **Fórmula general**  

$$ L = \lambda W $$
 
📍 **Significado de cada variable**  
- **L (Longitud de la cola)** → **Variable**: Número promedio de solicitudes en espera en el sistema.  
- **λ (Tasa de llegada)** → **Variable**: Cantidad de solicitudes que llegan por unidad de tiempo.  
- **W (Tiempo de espera promedio)** → **Variable**: Tiempo que cada solicitud pasa en el sistema.  

📌 **Importancia:**  
Ayuda a calcular **cuánto tráfico puede manejar un sistema distribuido** antes de que se vuelva lento.  

📌 **Dónde se usa:**  
- Diseño de **balanceo de carga** en servidores.  
- Optimización de **colas de procesamiento** en bases de datos.  
- Evaluación de **rendimiento en APIs** y sistemas web.  

---

 
### **📌 Fórmula de escalabilidad de Gustafson – Corrección de la Ley de Amdahl**  
📍 **Fórmula general**  

$$  S = N - (1 - P) (N - 1) $$  

📍 **Significado de cada variable**  
- **S (Speedup)** → **Variable**: Aceleración del sistema con paralelización.  
- **N (Number of Processors)** → **Variable**: Número de nodos o procesadores usados.  
- **P (Parallelizable Fraction)** → **Variable**: Porcentaje del sistema que puede ejecutarse en paralelo.  

📌 **Importancia:**  
Corrige la **Ley de Amdahl**, mostrando que **más nodos pueden mejorar el rendimiento** si el problema se escala correctamente.  

📌 **Dónde se usa:**  
- Diseño de **clusters de computación distribuida**.  
- Optimización de **procesamiento en paralelo** en bases de datos.  
- Evaluación de **rendimiento en sistemas de Big Data**.  


---


 

## Bibliografía 
```
https://www.youtube.com/watch?v=kW8xT_cgEMM
https://medium.com/@c.ucanefe/patroni-ha-proxy-feed1292d23f
```
