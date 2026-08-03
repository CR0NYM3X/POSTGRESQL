
Aquí tienes el artículo detallado, estructurado y enriquecido con la experiencia del "trincheras" que todo DBA y Data Engineer de PostgreSQL necesita conocer.

# Dominando lo Imposible: Guía Definitiva para Migrar Tablas de 5TB en PostgreSQL

Mover una base de datos de unos cuantos gigabytes es una tarea rutinaria. Pero cuando te enfrentas a una tabla monolítica de **5 Terabytes**, las reglas del juego cambian por completo. En esta escala, los comandos tradicionales dejan de ser herramientas y se convierten en cuellos de botella.

Si alguna vez has intentado hacer un volcado masivo con el comando nativo `COPY`, te habrás dado cuenta de una dura realidad: **`COPY` es inherentemente *single-threaded***. Procesar 5TB de forma secuencial, fila por fila, a través de un solo proceso, no solo es ineficiente, sino operativamente inviable.

En este artículo, desglosaremos las arquitecturas, herramientas y secretos oscuros que los expertos utilizan para mover volúmenes masivos de datos entre servidores PostgreSQL, exprimiendo al máximo el paralelismo, el ancho de banda y la I/O de disco.

---

## Fase 1: Preparando el Campo de Batalla (Tuning Extremo)

El error de novato más común es tener la mejor herramienta de extracción, pero inyectar los datos en un servidor PostgreSQL destino con la configuración "por defecto". Si vas a inyectar 5TB, el servidor destino debe convertirse temporalmente en un agujero negro de datos.

### Lo que los manuales dicen:

* **Deshabilitar índices y constraints:** Elimina todos los índices (salvo la PK temporalmente si es necesaria para particionar) y re-créalos al final.
* **Apagar Triggers:** Usa `ALTER TABLE ... DISABLE TRIGGER ALL`.
* **Relajar el WAL:** Aumenta `max_wal_size` a 50GB o 100GB, y el `checkpoint_timeout` a 1 hora para evitar que el disco colapse haciendo checkpoints cada 5 minutos.

### Los trucos de experto (Lo que NO te cuentan):

1. **El salvavidas `UNLOGGED`:** Cambia la tabla destino temporalmente con `ALTER TABLE nombre SET UNLOGGED`. Esto desactiva la escritura en el WAL para esa tabla. La inyección de datos volará. Al terminar, ejecutas `ALTER TABLE nombre SET LOGGED`. *Advertencia: Si el servidor crashea durante la carga, perderás la tabla, pero en una migración, simplemente reiniciarías el proceso.*
2. **Apagar AutoVacuum para esa tabla:** Durante una carga de 5TB, el demonio de *autovacuum* intentará analizar y limpiar la tabla en medio del proceso, robando I/O crucial. Desactívalo temporalmente: `ALTER TABLE nombre SET (autovacuum_enabled = false)`.
3. **`maintenance_work_mem` al máximo:** Cuando llegue el momento de recrear los índices de esos 5TB, querrás darle a Postgres toda la RAM disponible (ej. el 50% de la RAM total del servidor).

---

## Fase 2: El Arsenal de Extracción e Inyección

Existen dos escuelas de pensamiento para este trabajo: las herramientas "Postgres-Nativas" y los enfoques modernos apoyados en "Tecnologías Analíticas".

### 1. El Enfoque Nativo de Alto Rendimiento

Para migraciones directas (Postgres a Postgres), la comunidad confía en herramientas que implementan la división de trabajo (Chunking).

* **pg_copydb:** Es actualmente el estándar de oro de la comunidad. Se conecta a ambos servidores, utiliza los índices de la tabla origen para dividir los 5TB en rangos manejables y abre un pool de conexiones para ejecutar múltiples sentencias `COPY` simultáneas.
* **pg_bulkload:** Un veterano endurecido. Su magia radica en que **se salta los `shared_buffers**` de PostgreSQL. Escribe directamente en las páginas del sistema de archivos. Es brutalmente rápido, pero requiere instalación de extensiones en el servidor.
* **Replicación Lógica (El camino del Zero-Downtime):** Si el sistema origen no puede apagarse, esta es la única vía. Copia un snapshot inicial y luego transmite el WAL. (Postgres 16+ ya permite aplicar transacciones en el destino en paralelo).

### 2. El Enfoque Ninja: El Ecosistema ClickHouse

Mencionar ClickHouse para migrar PostgreSQL suena extraño, pero los arquitectos de datos modernos saben que su motor de lectura es de otro planeta. ClickHouse utiliza **Vectorized Query Execution**, leyendo Postgres por bloques en RAM en lugar de fila por fila.

* **PeerDB (por ClickHouse):** Diseñado específicamente para resolver el problema del snapshot lógico de Postgres (que suele ser single-threaded). PeerDB implementa un *Parallel Snapshotting* real, dividiendo la tabla y moviéndola a velocidades que saturan las tarjetas de red de 10Gbps.
* **clickhouse-local + Parquet:** El método táctico. Ejecutas el binario independiente de ClickHouse en el servidor origen. Lo usas para leer Postgres en paralelo y volcarlo a archivos **Parquet**.
* *La gran ventaja:* 5TB de datos transaccionales en Postgres se comprimen típicamente a 800GB - 1TB en Parquet gracias a la compresión columnar. Mover 1TB por la red es infinitamente más rápido. Luego, inyectas esos archivos al destino.



---

## Análisis Comparativo: ¿Cuál elegir?

| Herramienta | Ventajas | Desventajas | Preferencia de la Comunidad |
| --- | --- | --- | --- |
| **pg_copydb** | Diseño nativo para Postgres. Paralelismo impecable. Fácil de reanudar si falla. | No comprime los datos en tránsito (requiere mucho ancho de banda). | **Alta.** Es la herramienta "Go-to" moderna para migraciones heterogéneas Postgres-Postgres. |
| **PeerDB** | Velocidad absurda gracias a su paralelismo lógico y físico. Perfecto para replicación continua. | Requiere montar la infraestructura de PeerDB. | **Creciente.** Está ganando terreno rápidamente en entornos corporativos de alta demanda. |
| **clickhouse-local** (Vía Parquet) | Reduce radicalmente el tamaño de los datos en red. No requiere instalar bases de datos intermedias. | Requiere scripting manual y orquestación (pasos de exportar, mover, importar). | **Media.** Es un "secreto a voces" entre Data Engineers para movimientos ad-hoc muy pesados. |
| **pg_bulkload** | Velocidad de escritura en disco insuperable (bypass de buffers). | Difícil de instalar en entornos gestionados (RDS, Cloud SQL). | **Baja-Media.** Relegada a servidores bare-metal u *on-premise*. |

---

## Secretos de las Trincheras: Lo que casi siempre sale mal

Si es tu primera vez lidiando con esta escala, aquí tienes los errores que te costarán días de trabajo:

1. **La trampa del `CREATE INDEX CONCURRENTLY`:** Todos recomiendan usarlo para no bloquear la tabla al finalizar. **Falso en este escenario.** Si estás en una ventana de mantenimiento y nadie está usando la tabla destino, usar el `CREATE INDEX` estándar es dramáticamente más rápido. El modo concurrente hace múltiples pasadas sobre la tabla (doblando el I/O) y puede fallar silenciosamente dejando índices inválidos.
2. **El síndrome de la Secuencia Huérfana:** Copiaste 5TB de datos. Excelente. La aplicación se conecta e intenta insertar un nuevo registro y falla con un *Constraint Violation*. ¿Por qué? Olvidaste actualizar los contadores de tus secuencias (`SERIAL` o secuencias conectadas a `IDENTITY`). Siempre ejecuta `SELECT setval(...)` después de la migración.
3. **El planificador ciego:** Inyectaste 5TB en una tabla que antes estaba vacía. Si ejecutas una consulta, Postgres podría intentar un *Sequential Scan* masivo porque sus estadísticas dicen que la tabla está vacía. **Obligatorio:** Ejecutar un `ANALYZE nombre_tabla` tan pronto termine la inyección de datos para actualizar el mapa del planificador.
4. **Saturación del IOPS en Cloud:** Si estás migrando hacia AWS (EBS) o Azure, recuerda que el almacenamiento tiene un límite de IOPS y Throughput basado en el tamaño del disco o provisionado. Puedes tener 100 hilos corriendo en `pg_copydb`, pero si tu disco de red hace cuello de botella a 250MB/s, la migración se detendrá ahí. En la nube, a veces sale a cuenta provisionar un disco exageradamente rápido (io2) solo por las 24 horas de la migración y luego hacer un downgrade.

## Conclusión del Experto

Para una tabla regular de 5TB donde se permite una ventana de mantenimiento, la combinación ganadora hoy en día es utilizar **pg_copydb** combinado con el modo **UNLOGGED** en el destino, y todo el tuning de `max_wal_size` ajustado.

Si el ancho de banda entre tus servidores es un problema real, la ruta de extraer con **clickhouse-local hacia Parquet**, transferir los archivos comprimidos, y usar `COPY` en paralelo desde los archivos Parquet en el destino, te ahorrará horas o incluso días de transferencia de red.





-----
------
-----


¡Hola! Tienes un excelente instinto. Como experto en migraciones, te confirmo que **estás en lo correcto**: el comando nativo `COPY` es inherentemente *single-threaded* (utiliza un solo hilo) y procesa los datos de forma secuencial. Por lo tanto, usar un simple `COPY` o `\copy` para una tabla de 5TB tomaría una eternidad.

Incluso en las versiones más recientes de PostgreSQL (como la 16, 17 o en desarrollo), aunque se ha mejorado muchísimo el paralelismo en consultas (`SELECT`), creación de índices y replicación lógica, un comando `COPY FROM` directo hacia una tabla regular (no particionada) sigue operando en un solo proceso. Para lograr paralelismo, la estrategia es dividir los datos y usar múltiples conexiones.

A continuación, te detallo las herramientas más robustas y eficientes en la industria para mover una tabla de este calibre:

## Herramientas para Migración Paralela

Para transferir 5TB rápidamente, necesitamos herramientas que dividan la tabla en "chunks" (trozos) y abran múltiples conexiones simultáneas.

| Herramienta | Cómo funciona | Cuándo usarla |
| --- | --- | --- |
| **pg_copydb** | Es la herramienta "State of the Art" actualmente. Se conecta al origen y al destino, divide la tabla grande en bloques (usando el índice primario) y lanza múltiples procesos `COPY` en paralelo. | Es la opción #1 si estás migrando directamente de un servidor PostgreSQL a otro. |
| **pg_bulkload** | Una extensión de alto rendimiento que se salta los *shared_buffers* de PostgreSQL y escribe directamente en los bloques de datos. | Ideal si ya tienes los 5TB exportados en archivos planos gigantescos y buscas la máxima velocidad de inyección. |
| **GNU Parallel + Split** | Un enfoque "hazlo tú mismo". Divides tu archivo CSV gigante en docenas de archivos pequeños y usas `GNU Parallel` para ejecutar múltiples comandos `\copy` simultáneos. | Útil si el servidor de destino tiene restricciones severas y no puedes instalar herramientas externas. |
| **Replicación Lógica** | Sincroniza los datos en segundo plano copiando el estado inicial y luego transmitiendo los cambios en tiempo real. (PostgreSQL 16+ ya permite aplicar estas transacciones en paralelo). | Obligatorio si necesitas migrar los 5TB sin tiempo de inactividad (*Zero-Downtime Migration*). |

---

## Estrategias Críticas para Cargar 5TB

Independientemente de la herramienta que elijas, si vas a inyectar 5TB de golpe en el servidor destino, debes preparar la base de datos para una carga masiva. De lo contrario, el rendimiento colapsará:

* **Deshabilita los índices y constraints:** Los índices ralentizan las inserciones masivas enormemente. Elimina todos los índices (excepto quizás la llave primaria si la usas para particionar la carga) y vuelve a crearlos usando `CREATE INDEX CONCURRENTLY` una vez que los datos estén cargados.
* **Desactiva los Triggers:** Si la tabla destino tiene triggers (disparadores), desactívalos con `ALTER TABLE ... DISABLE TRIGGER ALL` durante la migración.
* **Ajusta el WAL (Write-Ahead Log):** Incrementa drásticamente `max_wal_size` (ej. a 50GB o más) y `checkpoint_timeout` (ej. a 30min o 1h) en tu archivo de configuración `postgresql.conf` para evitar que el disco se sature haciendo checkpoints continuos.
* **Considera tablas UNLOGGED:** Si es seguro hacerlo, puedes cambiar la tabla temporalmente a `UNLOGGED`. Esto evita que PostgreSQL escriba cada inserción en el WAL de transacciones, haciendo la copia mucho más rápida. Al terminar, la vuelves a cambiar a `LOGGED`.









https://oneuptime.com/blog/post/2026-01-25-load-millions-rows-copy-postgresql/view
https://github.com/dimitri/pgcopydb
