![Diagrama](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Alta%20disponibilidad/Sistemas%20Distribuidos/img/diagrama.png)


### 1. El Gran Error: "Saber" no es "Tener" (Metadatos vs. Datos)

Imagina una biblioteca con 10 pasillos. En la entrada hay un mapa (Metadatos) que dice: *"Los libros de historia están en el Pasillo 5"*.

* Si el Pasillo 5 se incendia (el nodo falla), el mapa de la entrada sigue diciendo que ahí están los libros... **¡pero los libros ya se quemaron!**
* El hecho de que el Coordinador y los demás Workers tengan la tabla interna (el mapa) solo sirve para saber a quién preguntarle. Si ese "quién" no responde y no tiene un reemplazo, los datos se perdieron.

Ahí es donde entra **Patroni**. Patroni no se encarga de saber dónde están los datos, se encarga de que **siempre haya una copia física (un espejo)** de cada pasillo.

### 2. ¿Cómo se evita la pérdida de datos? (La solución que buscabas)

En un sistema profesional con Citus + Patroni, un "Nodo" no es una sola máquina. Es un **Grupo de Alta Disponibilidad**.

* **Nodo Worker 1:** No es una CPU, son dos (Líder y Seguidor).
* **Nodo Worker 2:** Son dos (Líder y Seguidor).

Si el **Líder del Worker 1** se apaga, **no se pierden los datos** porque el **Seguidor** tiene una copia exacta en tiempo real (gracias a la replicación por streaming que gestiona Patroni). Patroni detecta la caída, convierte al Seguidor en nuevo Líder y le avisa a los demás: *"Ey, el Worker 1 ahora vive en esta otra IP"*.

---

### 3. ¿Para qué sirve un "Nuevo Coordinador"?

Mencionas que ahora todos los nodos pueden escribir y leer (Citus 11+). Es cierto, pero el **Coordinador** sigue teniendo tareas que los workers no suelen hacer:

1. **Punto de entrada único:** Tu aplicación (tu código en Java, Python, etc.) necesita una IP a la cual conectarse. No puedes darle 50 IPs de workers. El Coordinador (o un Balanceador frente a él) es esa puerta.
2. **Operaciones Globales:** Hay comandos (como crear una tabla distribuida o cambiar el esquema) que solo se pueden ejecutar en el nodo que tiene el rol de líder de metadatos.

Si se cae el Coordinador y no tienes HA (Patroni), tu aplicación se queda "ciega": no sabe a quién conectarse, aunque todos los workers estén vivos y con los datos intactos.

---

### 4. Resumen: ¿Para qué sirve cada cosa entonces?

| Herramienta | Su función real | ¿Qué pasa si no está? |
| --- | --- | --- |
| **Citus** | Pica la tabla en pedacitos (shards) y los reparte en Workers. | No puedes guardar archivos de Terabytes porque no caben en un solo disco. |
| **Tablas Internas (Metadatos)** | Es el "mapa" para que los nodos sepan a quién pedirle cada pedacito. | Los nodos tendrían que adivinar dónde están los datos (imposible). |
| **Patroni** | Mantiene una **copia exacta** de cada nodo en otra máquina. | **Si un nodo falla, los datos se pierden para siempre.** |

**En conclusión:** Usas Citus para que tu base de datos sea **gigante y rápida**, pero usas Patroni para que sea **segura**. Sin Patroni, estás jugando a la ruleta rusa con tus datos: el día que un disco falle o un servidor se apague, ese "pedazo" de tu base de datos desaparecerá y tu tabla quedará incompleta.

 ---

# Arquitectura 
Para lograr una arquitectura de 3 nodos que sea realmente de **Alta Disponibilidad (HA)** y resistente a desastres (**DR**), debemos ser estratégicos. Si solo tenemos 3 máquinas físicas, no podemos tener 3 coordinadores y 6 workers independientes, por lo que usaremos una **arquitectura cruzada**.

En esta topología, cada servidor físico ejecutará varios roles (instancias de Postgres) para asegurar que, si cae un servidor, el "espejo" de los datos esté en otro.

### 1. Diagrama de la Arquitectura

### 2. Capas de la Topología

Aquí te explico cómo fluye la conexión desde tu app hasta el dato:

#### **Capa A: Balanceo y Entrada (HAProxy)**

* **Función:** Es la IP única a la que se conecta tu aplicación.
* **Inteligencia:** HAProxy no solo pasa tráfico; le pregunta a Patroni: *"¿Quién es el líder actual?"*. Si el líder del Coordinador cae y Patroni promueve al standby, HAProxy redirige el tráfico a la nueva IP automáticamente.

#### **Capa B: Gestión de Conexiones (PgBouncer)**

* **Función:** Citus abre muchas conexiones entre nodos. Sin PgBouncer, saturarías la memoria de los servidores.
* **Ubicación:** Se suele instalar en cada nodo o justo después de HAProxy para "reciclar" conexiones y que Postgres no sufra.

#### **Capa C: El Cerebro (etcd / DCS)**

* **Función:** Es una base de datos de "consenso". Los 3 nodos de etcd se mantienen de acuerdo sobre quién es el líder. Si un servidor se desconecta, etcd vota por el nuevo jefe.

#### **Capa D: Base de Datos (Citus + Patroni)**

Aquí es donde ocurre la magia. Para aprovechar 3 nodos al máximo, repartimos los roles así:

| Servidor Físico 1 | Servidor Físico 2 | Servidor Físico 3 |
| --- | --- | --- |
| **Coordinador (Líder)** | Coordinador (Standby) | etcd (Voto 3) |
| Worker 1 (Standby) | **Worker 1 (Líder)** | Worker 2 (Standby) |
| etcd (Voto 1) | etcd (Voto 2) | **Worker 2 (Líder)** |

---

### 3. ¿Cómo funciona el DR (Disaster Recovery) aquí?

Si el **Servidor Físico 2** explota (falla de hardware):

1. **Detección:** El clúster de **etcd** nota que el servidor 2 no responde.
2. **Failover del Worker:** Patroni en el **Servidor Físico 3** nota que su "Worker 2" debe ser el nuevo líder. Se promueve a sí mismo.
3. **Failover del Coordinador:** Si el Coordinador estaba ahí, el standby del **Servidor 1** toma el mando.
4. **Reconfiguración:** Patroni actualiza el mapa de Citus (`pg_dist_node`). Ahora todos los nodos saben que para escribir en el "pedazo de datos 2" deben ir al Servidor 3.
5. **Transparencia:** HAProxy cambia la ruta. Tu aplicación solo nota una pequeña pausa de 2-5 segundos, pero **no pierde datos y no deja de funcionar**.

### 4. Recomendación de experto para 2026:

Aunque Citus 11+ permite que todos los nodos sean coordinadores (Metadata Sync), en entornos de producción críticos con solo 3 nodos, se recomienda mantener un **Coordinador Primario claro** para tareas administrativas y usar los Workers para la carga pesada de datos.

---

# Desafios 
montar **Citus con HA (Alta Disponibilidad) real** es un "rompecabezas" de muchas piezas. Lo que viste en el diagrama anterior es la arquitectura ideal "de libro", pero aterrizemos a la realidad de tus 3 servidores y por qué mencionaste a **YugabyteDB** como una salvación.

Aquí te aclaro los puntos clave:

### 1. ¿Dónde quedó Patroni?

Patroni no es un servidor aparte, es un **agente (un programa)** que instalas dentro de cada servidor de base de datos.

* **La Replica** es el "clon" de los datos.
* **Patroni** es el "chofer" que decide: "El jefe murió, ahora tú, replica, eres el nuevo jefe".

Si no tienes Patroni, tienes réplicas "mudas" que no saben cuándo activarse solas.

### 2. ¿Necesitas 6 servidores para Citus?

**Técnicamente, sí**, si quieres separar todo físicamente. Para tener 3 nodos de Citus y que cada uno tenga su réplica (HA), necesitarías 6 instancias de Postgres.

* Si intentas meter el Líder y su propia Réplica en el mismo servidor físico, y ese servidor se quema, **pierdes ambos**. No hay HA.
* Por eso, para tener HA real en Citus con solo 3 servidores físicos, tendrías que cruzar las réplicas (el Líder del Worker 1 en el Servidor A y su Réplica en el Servidor B). **Es una pesadilla de administrar.**

### 3. Por qué tienes razón: YugabyteDB es la solución "limpia"

Tu instinto es correcto. Si quieres **3 nodos físicos**, que todos puedan escribir/leer, y que si uno muere no pase nada, **YugabyteDB es mucho mejor que Citus** por una razón sencilla:

> **YugabyteDB ya trae el "Patroni" y el "Citus" integrados en su ADN.**

#### Comparación Real:

| Característica | Citus + Patroni + HAProxy | YugabyteDB |
| --- | --- | --- |
| **Instalación** | Tienes que configurar 4 o 5 programas distintos. | Es un solo binario/programa. |
| **Nodos necesarios** | Mínimo 6 para HA real (o 3 muy complejos). | **3 nodos exactos** y ya tienes HA nativa. |
| **Balanceo** | Necesitas HAProxy/PgBouncer externo. | Tiene un "Smart Driver" que balancea solo. |
| **Fallas** | Si cae el coordinador, hay que esperar el failover. | Si cae un nodo, el cluster ni se entera, sigue operando. |

### Conclusión y mi recomendación

Si no quieres convertirte en un administrador de sistemas experto solo para tener una base de datos distribuida: **Vete por YugabyteDB.**

**¿Por qué?**

1. En **3 servidores**, YugabyteDB te da replicación automática (Factor de Replicación 3).
2. No necesitas configurar Patroni; el protocolo Raft (el corazón de Yugabyte) ya maneja las fallas por ti.
3. Se comporta como un Postgres 100% puro para tu aplicación.
 
