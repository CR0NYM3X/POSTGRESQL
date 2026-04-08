### Secreto de YugabyteDB
Es que combina **Sharding** con **Replicación Distribuida** de forma automática. Aquí te explico por qué no se pierde la información:

### 1. El Shard no es único: es un "Tablet Group"

En YugabyteDB, un **Shard** (llamado *Tablet*) no existe en un solo nodo. Cada tablet tiene varias copias (normalmente 3) repartidas en el clúster.

* **Sharding (Distribución):** Divide la tabla en pedazos para que un solo nodo no tenga que procesar todo.
* **Replicación (Redundancia):** Crea copias de cada uno de esos pedazos en nodos distintos.

### 2. Ejemplo práctico: 3 Nodos y 3 Shards

Imagina que tienes una tabla de "Usuarios" dividida en 3 Shards (A, B y C) en un clúster de 3 nodos con un Factor de Replicación de 3 (RF=3):

| Nodo 1 | Nodo 2 | Nodo 3 |
| --- | --- | --- |
| **Shard A (Líder)** | Shard A (Copia) | Shard A (Copia) |
| Shard B (Copia) | **Shard B (Líder)** | Shard B (Copia) |
| Shard C (Copia) | Shard C (Copia) | **Shard C (Líder)** |

### 3. ¿Qué pasa si el Nodo 1 explota?

Si el Nodo 1 desaparece, se lleva consigo el **Líder del Shard A**. Pero, como puedes ver en la tabla de arriba:

1. **La información NO se perdió:** El Nodo 2 y el Nodo 3 todavía tienen copias exactas del Shard A.
2. **Elección de nuevo líder:** En menos de 3 segundos, los Nodos 2 y 3 se ponen de acuerdo y uno de ellos dice: *"Yo ahora soy el nuevo Líder del Shard A"*.
3. **Continuidad:** Tu aplicación sigue consultando los datos de los usuarios del Shard A conectándose a los nodos que quedaron vivos.


### 4. ¿Cuándo sí perderías información?

Para que realmente perdieras información en una configuración estándar (RF=3), tendrían que fallar **2 nodos al mismo tiempo**.

* Si fallan 2 de 3, pierdes el **quórum** (la mayoría necesaria para validar datos).
* En ese caso, el nodo sobreviviente entraría en modo "solo lectura" o se bloquearía para evitar inconsistencias, ya que no puede garantizar que tiene la versión más reciente de la verdad.

> **Nota Importante:** Esto es lo que diferencia a YugabyteDB de un sistema de sharding manual o básico. En otros sistemas, si el shard se pierde, el DBA tiene que restaurar un backup. En YugabyteDB, el sistema "sabe" que la información está duplicada y se recupera solo.

 
---

## 1. El concepto de "Tablet" (Shard + Replicación)

Cuando creas una tabla en YugabyteDB, la base de datos hace lo siguiente:

1. **Sharding Automático:** Divide la tabla en pedazos lógicos llamados **Tablets**. Por ejemplo, si tienes 1 millón de usuarios, el Tablet 1 tiene los IDs del 1 al 333k, el Tablet 2 del 334k al 666k, etc.
2. **Replicación Nativa:** En lugar de guardar ese Tablet 1 en un solo disco, YugabyteDB crea un **Grupo de Raft** para ese tablet.
* Si tu Factor de Replicación (RF) es 3, el sistema crea **3 copias físicas** de ese mismo Tablet 1.



### Visualización de la Arquitectura

Imagina un clúster de 3 nodos. La distribución se ve así:

| Nodo 1 | Nodo 2 | Nodo 3 |
| --- | --- | --- |
| **Tablet 1 (Líder)** | Tablet 1 (Seguidor) | Tablet 1 (Seguidor) |
| Tablet 2 (Seguidor) | **Tablet 2 (Líder)** | Tablet 2 (Seguidor) |
| Tablet 3 (Seguidor) | Tablet 3 (Seguidor) | **Tablet 3 (Líder)** |

* **Sharding:** Los datos están repartidos (T1, T2, T3).
* **Replicación:** Cada tablet tiene 3 copias distribuidas para que ningún nodo sea el único dueño de la información.
 

## 2. ¿Cómo interactúan en el día a día?

### Para Escribir (Consenso):

Cuando envías un `INSERT` al Tablet 1:

1. La solicitud llega al **Líder** del Tablet 1 (en el Nodo 1).
2. El Líder le dice a los **Seguidores** (en Nodo 2 y 3): *"Oigan, guarden este dato"*.
3. En cuanto **uno** de los seguidores responde "Listo", ya hay **Quórum** (2 de 3).
4. El Líder confirma la escritura al usuario. **El dato está replicado antes de que la base de datos te diga "OK".**

### Para Escalar (Auto-balancing):

Si añades un **Nodo 4**, YugabyteDB se da cuenta de que los otros 3 nodos están "pesados". Entonces, mueve algunos Tablets (con sus copias) al nuevo nodo de forma automática. El Sharding y la Replicación se mueven juntos.
 

## 3. Comparativa rápida: ¿Por qué es diferente a otros?

* **PostgreSQL Estándar:** Haces replicación de *toda* la base de datos (todo o nada). No hay sharding nativo.
* **Citus:** Hace sharding (divide tablas), pero para la replicación suele depender de que cada nodo tenga su propia "réplica" de Postgres aparte (usando herramientas como Patroni).
* **YugabyteDB:** El motor de almacenamiento (**DocDB**) ya sabe que cada pedazo de dato debe estar copiado en 3 sitios por defecto. Es "sharding replicado" desde su ADN.

 
### En resumen

YugabyteDB no copia "nodos enteros", copia **tablets individuales**. Esto permite que, si un nodo falla, el trabajo de recuperar los datos se reparta entre todos los nodos restantes del clúster, haciendo que la recuperación sea muchísimo más rápida que en sistemas tradicionales.


--- 

 

## 🛡️ YugabyteDB: Seguridad Nativa de Punta a Punta

YugabyteDB no depende de la infraestructura externa para proteger los datos; integra el cifrado en su propia arquitectura de base de datos distribuida.

### 1. Cifrado en Tránsito (Protección del Movimiento)
* **Comunicación Interna (Nodo-a-Nodo):** Cifra el tráfico de replicación (Raft) nativamente. Si alguien intercepta la red interna, no verá nada.
* **Conexión Externa (Cliente-a-Nodo):** Compatible con **TLS/SSL** para APIs de Postgres (YSQL) y Cassandra (YCQL).
* **Autenticación Mutua (mTLS):** El servidor también valida la identidad del cliente mediante certificados.
* **Zero-Downtime:** Rotación de certificados sin necesidad de reiniciar el clúster.

 

### 2. Cifrado en Reposo (Protección del Almacenamiento)
* **A nivel de Archivo (Granular):** Cifra directamente los archivos de datos (SSTables) y logs (WAL) usando **AES-256**.
* **Independencia del Disco:** Los datos están protegidos aunque se extraiga el disco físico o se mueva el archivo entre nubes (AWS/GCP/Azure).
* **Jerarquía de Claves (KMS):** Integración nativa con **AWS KMS, Azure Vault, Google KMS y HashiCorp Vault**. Una *Master Key* protege las llaves internas del clúster.
* **Rotación en un clic:** Cambia las llaves desde la consola o API de forma asíncrona y sin afectar el rendimiento.


 

### 3. Integración y Acceso (Ecosistema)
* **Herencia SQL/NoSQL:** Usa drivers y métodos estándar como **LDAP, GSSAPI y SCRAM-SHA-256**.
* **RBAC Nativo:** Control de acceso granular basado en roles directamente en el motor.
* **Cumplimiento Facilitado:** Diseño alineado con **Zero Trust**, ideal para normativas **PCI-DSS, HIPAA y GDPR**.

 
### 🚀 ¿Por qué es diferente a las demás?

| Característica | Ventaja Clave |
| :--- | :--- |
| **Rendimiento** | Impacto mínimo (< 5%) gracias a optimización por hardware (**AES-NI**). |
| **Escalabilidad** | El cifrado acompaña al dato mientras este se fragmenta (sharding) por el clúster. |
| **Facilidad** | Todo es nativo; no requiere software de terceros ni expertos en criptografía. |

**En conclusión:** Es una fortaleza digital donde el dato nace, viaja y descansa bajo llave de forma automática y transparente.
---

 
### 1. El Formato por Defecto: Almacenamiento de Filas
YugabyteDB almacena los datos en un motor llamado **DocDB** (basado en RocksDB). A diferencia de las bases de datos de columnas (como ClickHouse), YugabyteDB está optimizado para **OLTP**, lo que significa que prioriza el acceso rápido a registros completos.

* **Lógica de almacenamiento:** Cada fila de una tabla SQL se convierte en un "documento" dentro de DocDB.
* **Estructura Key-Value:** Internamente, cada columna de una fila solía almacenarse como un par clave-valor independiente, pero esto ha evolucionado.

### 2. Evolución: "Packed Rows" (Filas Empaquetadas)
Para mejorar el rendimiento (que es la debilidad típica de los sistemas distribuidos), YugabyteDB introdujo una optimización llamada **Packed Rows**, que ahora es el estándar:

* **Antes:** Una fila con 10 columnas se guardaba como 10 entradas distintas en el motor de almacenamiento.
* **Ahora (Default):** Toda la fila se "empaqueta" en un **solo par clave-valor**. Esto reduce drásticamente el espacio en disco y acelera las lecturas de registros completos, ya que solo se necesita una operación de búsqueda para recuperar toda la fila.

### 3. Comparativa de Almacenamiento


| Característica | YugabyteDB (Por defecto) | Bases de Datos Columnares (OLAP) |
| :--- | :--- | :--- |
| **Tipo** | **Orientado a Filas** (Optimizado) | Orientado a Columnas |
| **Estructura** | DocDB / LSM-Tree | Archivos Parquet / Columnar |
| **Punto fuerte** | Inserciones y lecturas de filas individuales (Updates/Inserts rápidos). | Agregaciones masivas (SUM, AVG) sobre una sola columna en millones de filas. |
| **Caso de uso** | Aplicaciones transaccionales, apps móviles, banca. | Business Intelligence y Data Warehousing. |

### 4. ¿Existe opción de columnas?
Actualmente, YugabyteDB **no ofrece un motor columnar nativo** por defecto para su almacenamiento principal. Sin embargo, permite:
* **Índices cubrientes:** Puedes crear índices que incluyan ciertas columnas para simular la velocidad de lectura de un motor columnar en consultas específicas.
* **Integración con OLAP:** Se recomienda usar conectores para exportar datos a sistemas como Snowflake o ClickHouse si el análisis columnar es el objetivo principal.
 
**Conclusión oficial:** YugabyteDB utiliza un almacenamiento **orientado a filas empaquetadas** por defecto para maximizar la eficiencia en cargas de trabajo transaccionales y de alta concurrencia.

 



## Links
```
https://docs.yugabyte.com/stable/architecture/docdb-replication/
```
