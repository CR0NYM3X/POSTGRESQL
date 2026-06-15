

## 🎯 ¿Para qué sirve hacer réplicas en PostgreSQL?
Las réplicas pueden ser sincrónicas (alta disponibilidad) o asincrónicas (recuperación ante desastres).

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




----------------------------------------------------------------------------------------------------------------------------------------------------------------

CAP Theorem → En bases de datos distribuidas, puedes tener Consistencia (C), Disponibilidad (A) o Tolerancia a Particiones (P), pero nunca las tres simultáneamente.
----------------------------------------------------------------------------------------------------------------------------------------------------------------

Un Data Warehouse es un sistema de almacenamiento y gestión de datos diseñado para facilitar el análisis y la toma de decisiones en una organización. Funciona como un repositorio central donde se integran y estructuran grandes volúmenes de información provenientes de múltiples fuentes.

```

## **Raft** y **Paxos** 
 Raft y Paxos son algoritmos de *consenso distribuido*, diseñados para que múltiples nodos en un sistema lleguen a un acuerdo sobre un valor, incluso si algunos fallan o se desconectan. Son fundamentales en bases de datos distribuidas, sistemas de archivos y clústeres de alta disponibilidad.

 

## ¿Qué significa el consenso en términos generales?  
es simplemente ponerse de acuerdo. En el mundo de los sistemas distribuidos, el consenso es el mecanismo (estrictamente matemático y algorítmico) mediante el cual un grupo de servidores independientes logra estar de acuerdo sobre una única verdad absoluta, incluso si la red falla, hay latencia o algunos de los servidores explotan literalmente. Se usa en algoritmos Como Raft, Paxos y Etcd, que permiten que los servidores acuerden quién es el líder.


En sistemas distribuidos basados en consenso (como Raft), el Factor de Replicación siempre debe ser un número impar ($3, 5, 7...$) para evitar empates a la hora de votar por un líder. Por lo tanto, por ejemplo si tienes 6 nodos, lo correcto y óptimo es configurar tu clúster con un Factor de Replicación de 5 (RF=5), dejando el sexto nodo como reserva activa (hot spare) para absorber la carga si otro nodo muere.

###  **¿Qué es Paxos?**

- Propuesto por Leslie Lamport en los años 80.
- Es un algoritmo robusto pero **difícil de entender e implementar**.
- Usa tres roles:
  - **Proposers**: proponen valores.
  - **Acceptors**: aceptan o rechazan propuestas.
  - **Learners**: aprenden el valor acordado.
- Funciona por medio de rondas de propuestas y promesas, buscando que **una mayoría (quórum)** acepte un valor.

 *Ventaja:* muy tolerante a fallos.  
 *Desventaja:* complejo, propenso a errores de implementación.


###️ **¿Qué es Raft?**

- Diseñado en 2013 por Diego Ongaro y John Ousterhout como una alternativa más **entendible** a Paxos.
- Usa un enfoque **basado en liderazgo**:
  - Un nodo es elegido como **líder**.
  - Los demás son **seguidores**.
  - Si el líder falla, se realiza una **elección** para elegir uno nuevo.
- El líder recibe las operaciones y las **replica en todos los nodos**.

 *Ventaja:* más fácil de implementar y razonar.  
*Desventaja:* no es tolerante a fallos bizantinos (no protege contra nodos maliciosos).


---

### 🔑 ¿Qué es el quórum (mayoría)?

Es el número mínimo de nodos que deben estar de acuerdo para tomar decisiones.  (por ejemplo, etcd)**   deben estar **activos y en acuerdo** para que se puedan tomar decisiones críticas de manera segura.  
La fórmula universal es *`(N / 2) + 1`*   para saber cual es el Quórum Requerido. la N = Nodo. 

En el mundo de los sistemas distribuidos y la programación, esta fórmula utiliza división de números enteros. Esto significa que si el resultado de la división tiene un decimal (como 1.5), el sistema simplemente descarta el decimal (se queda con el 1) y luego le suma el 1 de la fórmula.

Ejemplo clásico: en un clúster de 3 nodos etcd, **se necesita al menos 2 funcionando** para tener quórum. Herramientas como etcd exige quorum y si no hay mayoría (quorum) de nodos disponibles no aceptará escrituras ni permitirá elecciones de líder 

### 📌 Reglas clave:

- El **quórum se calcula sobre los nodos consenso como etcd**, **no sobre los servidores PostgreSQL**.
- Siempre necesitas al menos **una mayoría de nodos etcd funcionales** para que Patroni pueda tomar decisiones críticas como un failover.
- **Debe ser siempre un número impar** para facilitar la mayoría.
- Fórmula: Para para saber cuantos nodos ocupo en total , para permitirme N cantidad nodos caidos, _f_ fallos → necesitas **2×f + 1** nodos etcd.
- Fórmula: Para para saber cuantos nodos  pueden fallar  **(RF - 1 ) / 2**  RF = Factor de replicación


### 🧠 ¿Por qué es tan importante?

Porque sin quórum:

- No se puede promover una réplica a primario.
- El sistema entra en estado de seguridad (failover bloqueado).
- Se evita el *split-brain* (dos nodos creyéndose líderes al mismo tiempo).


### Configuración de nodos etcd y tolerancia a fallos

| # Nodos etcd | Quórum necesario | Fallos tolerables | ¿Cuándo usarlo?                              |
|--------------|------------------|-------------------|----------------------------------------------|
| 1 (no recomendado) | 1                | 0                 | Solo para pruebas locales – ❌ Punto único de fallo |
| 3 (ideal mínimo)   | 2                | 1                 | Producción básica                            |
| 5                 | 3                | 2                 | Alta disponibilidad en múltiples zonas       |
| 7                 | 4                | 3                 | Infraestructura crítica o multinube          |
 
  
### 🧠 **¿Cuándo deberías considerar aumentar los nodos de consenso?**
Saber cuándo aumentar el número de nodos en tu clúster de consenso (como etcd) no depende de cuántos servidores PostgreSQL tengas, sino de cuánto Fallos de consenso estás dispuesto a tolerar y qué tan crítica es tu infraestructura y en un sistema donde se prestan fallos comunes.

1. **Cuando necesitas tolerar más fallos**
   - Si actualmente tienes 3 nodos etcd, solo puedes tolerar 1 caída.
   - Si quieres tolerar 2 fallos simultáneos, necesitas 5 nodos.

 ---

# Conocimiento esencial para diseñar arquitecturas distribuidas eficientes.  

- Ley de Amdahl
- Ley de Gunther
- Fórmula de latencia en redes distribuidas
- Fórmula de Throughput
- Fórmula de Consistencia Teorema CAP
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
### **📌 Teorema CAP - Fórmula de Consistencia  – Equilibrio en sistemas distribuidos**  

📍 **Fórmula general**  
El **Teorema CAP** establece que un sistema distribuido **puede garantizar solo dos de tres propiedades**,  pero nunca las tres simultáneamente.:  

$$  C + A + P \neq 3 $$  

## Ejemplos

Imagina que tienes un sistema compuesto por **5 servidores distribuidos en diferentes partes del mundo** (por ejemplo: el Servidor A en América, el Servidor E en Asia, y otros tres repartidos en Europa y Oceanía). Todos están conectados por cables de red y deben trabajar en equipo para simular que son una sola gran base de datos.

Aquí es donde entran las tres reglas del Teorema de CAP:
 

## La "C" de CAP: Consistencia (Consistency)
`Todos los nodos ven los mismos datos al mismo tiempo.`
En el contexto de sistemas distribuidos, la Consistencia significa **Consistencia de Réplica** (técnicamente llamada *Linealizabilidad*). Significa que todos los nodos del sistema ven exactamente la misma información al mismo tiempo, actuando como si fueran un solo servidor central.

* **Llevado a tu ejemplo:** Si un usuario en Alemania se conecta al Servidor A y cambia su foto de perfil, esa actualización viaja inmediatamente por la red. Si un milisegundo después, otro usuario en Japón se conecta al Servidor E para ver ese perfil, el Servidor E **tiene la obligación de mostrarle la foto nueva**. No se permiten retrasos ni "datos viejos". O el sistema muestra la verdad absoluta y más reciente en todos lados, o prefiere no mostrar nada.
 

## La "A" de CAP: Disponibilidad (Availability)
`Cada petición recibe una respuesta (éxito o fallo).`
En los sistemas distribuidos, la Disponibilidad significa que **cualquier nodo del sistema que esté encendido y reciba una solicitud debe darte una respuesta válida (no un error), sin importar el estado del resto de los servidores.**

* **Llevado a tu ejemplo:** Un usuario en Japón se conecta al Servidor E para leer un dato, mientras que el Servidor A en Alemania está saturado o incomunicado. Que el sistema sea "Disponible" significa que el Servidor E **tiene que responderle** al usuario de Japón inmediatamente. No se le permite decirle: *"Espera, no te puedo responder porque estoy bloqueado validando si Alemania tiene datos nuevos"*, ni tampoco arrojarle un error 500. El servidor responde con lo que tiene a la mano en ese instante.
* **El truco:** El teorema dice que el nodo te va a responder siempre, pero **no te garantiza** que te responda con el dato más fresco del mundo si hay problemas de comunicación. Prioriza el "estar activo" por encima de la verdad absoluta.

 

## La "P" de CAP: Tolerancia a Particiones (Partition Tolerance)
`El sistema sigue funcionando aunque se rompa la comunicación entre servidores.`
Aquí está el núcleo físico de todo. Una **Partición** es una forma elegante de decir: **"Se rompió el cable de red que unía a los servidores"**. Los servidores siguen vivos, encendidos y funcionando, pero ya no pueden hablar entre sí debido a un fallo en la comunicación.

Que un sistema tenga Tolerancia a Particiones significa que **el sistema completo no se desmorona ni se apaga si la red falla entre algunos de sus nodos.** El servicio sigue operando aunque la red se rompa y los servidores queden divididos en "islas".

* **Llevado a tu ejemplo:** Imagina que un tiburón muerde un cable submarino en el océano y el Servidor A (América) ya no se puede comunicar con el Servidor E (Asia). Estás ante una Partición de Red. Si tu sistema tolera particiones, los usuarios en América pueden seguir usando el Servidor A y los usuarios en Asia pueden seguir usando el Servidor E. El sistema "tolera" vivir en el caos temporal de la desconexión.
 

## El Verdadero Secreto del Teorema: La "P" no es opcional

Muchos libros antiguos explican CAP diciendo: *"Elige dos de tres (puedes elegir CA, CP o AP)"*. **Eso es un mito de la vieja escuela.**

En el mundo real de las redes (internet, fibra óptica, satélites), los cables se rompen, los routers fallan y el lag ocurre de forma inevitable. Por lo tanto, **la "P" (Tolerancia a Particiones) es obligatoria**. No puedes elegir un sistema "CA" (Consistente y Disponible sin Tolerancia a Particiones), a menos que metas tus 5 servidores dentro de la misma computadora física... y en ese momento, dejaría de ser un sistema distribuido.

Así que el dilema real en el día a día de un ingeniero de datos, cuando ocurre la inevitable partición ($P$), se reduce a una decisión binaria:

* **¿Eliges Consistencia (CP)?:** Si el Servidor A y el Servidor E no pueden hablar por la falla de red, prefieres **bloquear o rechazar** las solicitudes en el Servidor E antes de arriesgarte a entregar un dato desactualizado. Sacrificas la Disponibilidad (el usuario verá un error) para asegurar que nadie lea mentiras.
* **¿Eliges Disponibilidad (AP)?:** Prefieres que el Servidor E le responda al usuario con lo que tiene guardado en su memoria local (aunque sea un dato viejo), porque para tu negocio es peor mostrar una pantalla de error. Sacrificas la Consistencia en favor de mantener el sistema siempre andando.  lo que te lleva al mundo BASE

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


 
### Parámetros de solo lectura
```SQL
select name,setting,context from pg_settings where name like '%read%';
```

### ** `default_transaction_read_only`**
- **Función:** Define si las transacciones por defecto serán de solo lectura (`on`) o permitirán modificaciones (`off`).
- **Uso común:** Se puede configurar globalmente en `postgresql.conf` o a nivel de sesión con:
  ```sql
  SET default_transaction_read_only = on;
  ```
- **Ejemplo:** Si está en `on`, cualquier intento de `INSERT`, `UPDATE` o `DELETE` generará un error "ERROR:  cannot execute UPDATE in a read-only transaction".

### ** `transaction_read_only`**
- **Función:** Indica si la transacción actual es de solo lectura (`on`) o permite modificaciones (`off`).
- **Uso común:** Se puede activar dentro de una transacción con:
  ```sql
  BEGIN;
  SET TRANSACTION READ ONLY;
  ```
- **Ejemplo:** Si una transacción se inicia con `READ ONLY`, no podrá modificar datos hasta que se cierre.

# 🔧 ¿Qué son los modos de espera en PostgreSQL?

Son configuraciones de servidores secundarios que replican los datos del servidor principal (master o primary) y están listos para entrar en acción si el principal falla. Se dividen en tres tipos:

### ✅ ¿Cuál elegir?

Depende de tus necesidades:

| Necesidad | Recomendación |
|-----------|----------------|
| Bajo costo, tolerancia a tiempo de recuperación | Cold Standby |
| Recuperación moderada sin consultas | Warm Standby |
| Alta disponibilidad y consultas en tiempo real | Hot Standby |

 
 

### 🧊 1. **Modo en frío (Cold Standby)**

- **Qué es**: El servidor de respaldo está **apagado o sin sincronización activa**. Solo se activa manualmente cuando el principal falla.
- **Ventajas**: Simple y barato.
- **Desventajas**: Tiempo de recuperación largo, posible pérdida de datos recientes.
- **Ejemplo de uso**: Restaurar desde un backup y aplicar WALs (Write-Ahead Logs).

 

### 🌥️ 2. **Modo templado (Warm Standby)**

- **Qué es**: El servidor de respaldo está **encendido y aplicando WALs**, pero **no acepta conexiones**.
- **Ventajas**: Recuperación más rápida que el modo en frío.
- **Desventajas**: No se puede consultar hasta que se promueve como principal.
- **Ejemplo de uso**: Usar `pg_standby` para aplicar logs continuamente.

 

### 🔥 3. **Modo caliente (Hot Standby)**

- **Qué es**: El servidor de respaldo está **activo, replicando en tiempo real** y **acepta consultas de solo lectura**.
- **Ventajas**: Alta disponibilidad, balanceo de carga para consultas.
- **Desventajas**: Requiere configuración más avanzada.
- **Ejemplo de uso**: Configurar `streaming replication` con `hot_standby = on`.

---

 
## 🧠 **Criterios para decidir si clusterizar PostgreSQL con réplicas**

### 1. **Alta disponibilidad (HA)**
- **¿Tu aplicación no puede tolerar caídas del servicio?**
  - Si el servidor principal falla, necesitas un *failover automático* hacia un servidor réplica.
  - Ideal en entornos críticos como bancos, e-commerce, salud, etc.

**Indicadores:**
- SLA alto (99.99% o más).
- Usuarios conectados 24/7.
- Pérdida de datos o tiempo de inactividad es costosa.

 
### 2. **Escalabilidad de lectura**
- **¿Tienes muchas consultas de solo lectura?**
  - Las réplicas pueden distribuir la carga de lectura (reportes, dashboards, APIs).
  - El *primary* se enfoca en escrituras, mientras las *replicas* manejan lecturas.

**Indicadores:**
- Consultas pesadas de lectura.
- Muchos usuarios concurrentes.
- Uso intensivo de BI o analítica.

 
### 3. **Tolerancia a fallos y recuperación ante desastres (DR)**
- **¿Necesitas protegerte contra pérdida total del servidor principal?**
  - Réplicas en otra región o datacenter permiten recuperación rápida.
  - Se puede usar *replicación asíncrona* para evitar latencia.

**Indicadores:**
- Requisitos de continuidad del negocio.
- Políticas de recuperación ante desastres.
- Infraestructura distribuida geográficamente.

 

### 4. **Mantenimiento sin interrupciones**
- **¿Requieres aplicar parches, actualizaciones o mantenimiento sin afectar el servicio?**
  - Puedes hacer *switch-over* a una réplica mientras mantienes el nodo principal.

**Indicadores:**
- Ventanas de mantenimiento limitadas.
- Requisitos de operación continua.

 

### 5. **Carga de trabajo intensiva o variable**
- **¿Tu servidor tiene picos de carga que afectan el rendimiento?**
  - Las réplicas ayudan a absorber la carga en momentos críticos.

**Indicadores:**
- Variabilidad en el tráfico.
 

### 6. **Requisitos de auditoría o replicación lógica**
- **¿Necesitas replicar solo ciertas tablas o realizar transformaciones?**
  - PostgreSQL permite replicación lógica para casos específicos.

**Indicadores:**
- Integración con otros sistemas.
- Migración progresiva.
- Auditoría de cambios.


 ---

 # Streaming vs. Log Shipping

### 1. Replicación por Streaming vs. Log Shipping

Existen dos formas de enviar datos, y es vital no mezclarlas:

* **Log Shipping (Basado en archivos):** Este es el que tú imaginabas. Espera a que el archivo de 16 MB se llene, se cierre y entonces el `archive_command` lo copia al servidor secundario. Esto genera un retraso (lag) de varios segundos o minutos.
* **Streaming Replication (Basado en registros):** En cuanto haces un `INSERT` o `UPDATE`, se genera un pequeño **registro WAL** (de unos pocos bytes o KB). El proceso `WalSender` en el primario lee ese registro **directamente de la memoria (WAL Buffers)** o del disco y lo envía por la red al instante.

### 2. ¿Se escribe primero en disco o se envía?

Depende de tu configuración, pero normalmente suceden casi al mismo tiempo. El flujo es el siguiente:

1. **Transacción:** Tú ejecutas un `COMMIT`.
2. **WAL Buffer:** El cambio se escribe en la memoria RAM del servidor primario (WAL Buffers).
3. **Escritura Local:** El proceso `WAL Writer` escribe ese cambio en el archivo WAL del disco duro del primario.
4. **Streaming:** El proceso `WalSender` toma ese cambio y lo manda por la red al servidor secundario.
5. **Recepción:** El secundario recibe el trozo de datos, lo guarda en su propio WAL y lo aplica.

 
### 4. ¿Qué pasa si el secundario es lento?

Si tu secundario no puede procesar los datos tan rápido como llegan, los archivos WAL de 16 MB empezarán a acumularse en la carpeta `pg_wal` del servidor primario.

PostgreSQL no borrará esos archivos de 16 MB hasta que:

1. Hayan sido archivados con éxito (si tienes `archive_mode` activo).
2. **El servidor secundario confirme que ya los recibió** (si usas **Replication Slots**).

> **Ojo:** Si el secundario se desconecta y usas un Slot de replicación, el primario seguirá guardando archivos de 16 MB indefinidamente hasta llenar el disco. ¡Ten cuidado con eso!


---


# Restringe las escritura y trabaja de solo lectura 
Solo lectura: Puedes hacer SELECT.
Prohibido modificar: Si intentas hacer un INSERT, UPDATE, DELETE o DROP, la base de datos te lanzará un error inmediatamente.
Protección de sesión: Se aplica a todas las transacciones de la sesión a menos que se cambie manualmente.

Error que manda si quieres hacer alguna modificacion 
**ERROR:  cannot execute DELETE in a read-only transaction**
```

SET default_transaction_read_only = on;
ALTER DATABASE mi_base_de_datos SET default_transaction_read_only = on;

-- en replica es diferente 
El modo "Hot Standby" manda
Cuando configuras una réplica, activas el parámetro hot_standby = on. En el momento en que el servidor arranca como réplica, PostgreSQL pone internamente todas las sesiones en modo lectura.
Si tú intentas consultar el valor de default_transaction_read_only en la réplica, verás que está en on, aunque tú no lo hayas escrito en el archivo de configuración.
```

## Bibliografía 
```
- Best Practices for Postgres Database Replication -> https://medium.com/timescale/best-practices-for-postgres-database-replication-b5ed69caf96d

PostgreSQL High-Availability Architectures -> https://www.cybertec-postgresql.com/en/postgresql-high-availability-architectures/
Escalado de bases de datos con replicación, particionamiento y fragmentación -> https://medium.com/@vinodbokare0588/scaling-databases-with-replication-partitioning-and-sharding-4d0a006adfe3

https://www.youtube.com/watch?v=kW8xT_cgEMM
https://medium.com/@c.ucanefe/patroni-ha-proxy-feed1292d23f


https://www.geeksforgeeks.org/paxos-vs-raft-algorithm-in-distributed-systems/
https://dev.to/pragyasapkota/consensus-algorithms-paxos-and-raft-37ab
Patroni -> https://medium.com/@joaovic32/demystifying-high-availability-postgresql-with-patroni-and-pgpool-ii-on-ubuntu-428c91a55b1a

https://www.postgresql.org/docs/current/warm-standby.html#STREAMING-REPLICATION
https://www.postgresql.org/docs/18/high-availability.html
```
