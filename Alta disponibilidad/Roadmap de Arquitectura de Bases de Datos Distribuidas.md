# 🗺️ Roadmap de Arquitectura de Bases de Datos Distribuidas

Bienvenido a mi hoja de ruta personal para dominar la arquitectura de bases de datos distribuidas a un nivel profesional (Senior/Principal). Este repositorio documenta mi progreso a través de los fundamentos matemáticos, físicos y teóricos que rigen los sistemas a gran escala.

---

## 1. Teoremas Fundamentales y Modelos Teóricos
Estos son los pilares matemáticos y lógicos que definen qué se puede y qué no se puede hacer en un sistema distribuido.

- [ ] **Teorema de CAP (Teorema de Brewer):** Consistencia, Disponibilidad y Tolerancia al Particionamiento. Analiza por qué no puedes tener las tres.
- [ ] **Teorema PACELC:** La extensión de CAP que explica el comportamiento del sistema cuando *no* hay particiones (el trade-off entre Latencia y Consistencia).
- [ ] **Modelos de Consistencia (Consistency Models):** - [ ] Consistencia Estricta (Strict) y Linealizabilidad (Linearizability).
  - [ ] Consistencia Secuencial y Causal.
  - [ ] Consistencia Eventual (Eventual Consistency) y Monotonic Read/Write.
- [ ] **Modelos de Fallos (Fault Models):** Fallos por caída (*Crash-stop*), recuperación (*Crash-recovery*) y Fallos Bizantinos (*Byzantine faults*).

---

## 2. Algoritmos de Consenso y Replicación
Cómo logran múltiples nodos ponerse de acuerdo en un dato real sin un nodo central que controle todo.

- [ ] **Algoritmos de Consenso Fuertes:** **Raft** y **Paxos** (y sus variantes como Multi-Paxos). Obligatorio dominar cómo funcionan a nivel interno.
- [ ] **Replicación Líder-Seguidor (Leader-Follower / Master-Slave):** Replicación síncrona vs. asíncrona y el problema del retraso de replicación (*Replication Lag*).
- [ ] **Replicación Multi-Líder y Sin Líder (Leaderless):** El modelo de Dynamo (utilizado por Cassandra/DynamoDB) y cómo maneja las lecturas/escrituras con quórum ($W + R > N$).

---

## 3. Tiempo, Orden y Coordinación
En sistemas distribuidos, el tiempo físico es un enemigo porque los relojes de las máquinas se desfasan.

- [ ] **Relojes Lógicos:** Relojes de Lamport y Vectores de Versión (*Vector Clocks*) para determinar el orden causal de los eventos.
- [ ] **TrueTime de Google:** Cómo el uso de relojes atómicos y GPS permite consistencia externa (usado en Google Spanner).
- [ ] **Algoritmos de Elección de Líder:** Algoritmo del Matón (*Bully Algorithm*) y Algoritmo de Anillo (*Ring Algorithm*).

---

## 4. Transacciones Distribuidas y Reglas de Consistencia
Cómo asegurar que una operación que toca múltiples bases de datos sea segura.

- [ ] **Propiedades ACID vs. Propiedades BASE:** El choque cultural entre bases de datos relacionales tradicionales y NoSQL.
- [ ] **Protocolo de Compromiso de Dos Fases (2PC - Two-Phase Commit):** Cómo funciona y por qué es un cuello de botella bloqueante.
- [ ] **Protocolo de Tres Fases (3PC):** Intentos de solucionar el bloqueo de 2PC.
- [ ] **Patrón SAGA:** Coreografía vs. Orquestación para manejar transacciones largas y compensatorias en microservicios sin bloquear recursos.
- [ ] **Control de Concurrencia Multiversión (MVCC):** Cómo las bases de datos permiten lecturas y escrituras simultáneas sin bloquearse.

---

## 5. Estrategias de Particionamiento y Distribución de Datos
Cómo romper una base de datos gigante en pedazos manejables.

- [ ] **Sharding (Particionamiento Horizontal):** Estrategias basadas en rangos, hash y directorios.
- [ ] **Hasing Consistente (Consistent Hashing):** La fórmula matemática para distribuir datos en un anillo de nodos minimizando la reorganización cuando un nodo entra o sale (fundamental para DynamoDB, Cassandra, Memcached).
- [ ] **Hotspots de Datos:** Identificación y mitigación de nodos que reciben demasiado tráfico (*celebrity problem*).

---

## 6. Estructuras de Datos Internas de Almacenamiento
Un arquitecto debe saber cómo escribe la base de datos en el disco para predecir su rendimiento.

- [ ] **LSM-Trees (Log-Structured Merge-Trees):** Optimizados para escrituras masivas (Cassandra, RocksDB, InfluxDB).
- [ ] **B-Trees y B+ Trees:** Optimizados para lecturas y consultas por rango (PostgreSQL, MySQL, Oracle).
- [ ] **Write-Ahead Logging (WAL):** El mecanismo de persistencia y recuperación ante fallos en el disco.

---

## 7. Políticas de Resiliencia, Tolerancia a Fallos y Red
Las redes fallan constantemente (falacias de la computación distribuida). Debes saber cómo diseñar para el caos.

- [ ] **Estrategias de Reintento y Backoff Exponencial con Jitter:** Cómo evitar tumbar tu propia base de datos tras una caída.
- [ ] **Rompe-circuitos (Circuit Breakers):** Protección de cascada de fallos.
- [ ] **Detección de Fallos por Conjetura ($\Phi$-Accrual Failure Detector):** Cómo las bases de datos deciden matemáticamente si un nodo vecino está muerto o solo lento.
- [ ] **Gossip Protocols:** Cómo los nodos comparten información de salud y topología de la red de forma descentralizada.
