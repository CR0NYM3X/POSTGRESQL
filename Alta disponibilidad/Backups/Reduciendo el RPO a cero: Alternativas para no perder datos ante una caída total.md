# Reduciendo el RPO a cero: Alternativas para no perder datos ante una caída total.


 
el RPO (Recovery Point Objective): la cantidad de datos que te puedes permitir perder. Vamos a desglosar exactamente qué pasa con ese tercer WAL, cómo te recuperas y qué herramientas existen para mitigar este riesgo.

 

### ¿Qué pasa con el WAL que no ha rotado?

Exactamente como dices. Mientras el archivo WAL activo no alcance su tamaño máximo (usualmente 16MB) o no sea rotado manualmente (con `pg_switch_wal()`), **no se va a archivar**. El comando `archive_command` se dispara *únicamente* cuando el archivo se cierra y se crea/recicla uno nuevo. Durante ese tiempo, ese WAL vive exclusivamente en el directorio `pg_wal` (o `pg_xlog` en versiones antiguas) de tu servidor de base de datos.

### ¿Qué pasa si ocurre una incidencia en ese momento?

Supongamos que tienes 2 WALs seguros en tu repositorio de backups y el 3.º está a la mitad en tu servidor de base de datos. El mecanismo de recuperación depende enteramente del **tipo de incidencia**:

#### Escenario 1: Caída del servicio (Crash) pero el disco sobrevive

Si el servidor se reinicia abruptamente por falta de memoria, un apagón eléctrico o un *kill -9*, **no pierdes nada**.

* **Mecanismo:** Al arrancar de nuevo, PostgreSQL entra automáticamente en modo *Crash Recovery*. Leerá el directorio local `pg_wal`, encontrará ese tercer archivo WAL (que estaba a la mitad) y aplicará (re-ejecutará) todas las transacciones confirmadas (*commits*) para dejar la base de datos consistente.

#### Escenario 2: Pérdida total del disco o servidor (Desastre total)

Si el disco donde vive `pg_wal` se corrompe, se quema o el servidor es irrecuperable, **pierdes todas las transacciones que estaban en ese tercer WAL**.

* **Mecanismo de recuperación (PITR):** Tendrás que restaurar tu backup base y aplicar los WAL archivados (los 2 primeros). Las transacciones del tercer WAL se habrán perdido irremediablemente. Esto significa que tu RPO fue igual al tiempo que tardó en llenarse ese tercer WAL.
 
### ¿Cómo evito esperar a que el WAL rote? (Mecanismos y Herramientas)

Para evitar que tu RPO dependa del volumen de tráfico (que define qué tan rápido se llenan los 16MB), existen mecanismos nativos y herramientas modernas.

#### 1. Forzar la rotación por tiempo (Mecanismo Nativo)

Puedes configurar el parámetro `archive_timeout` en `postgresql.conf`.

* **¿Qué hace?** Si lo configuras, por ejemplo, en `archive_timeout = 5min`, PostgreSQL forzará la rotación del WAL cada 5 minutos, incluso si no ha llegado a los 16MB.
* **Pros:** Garantiza que tu pérdida máxima de datos (RPO) en caso de desastre total sea de 5 minutos.
* **Contras:** Si hay muy poco tráfico, generarás muchos archivos WAL pequeños, lo que puede saturar tu sistema de archivado de basura y complicar la gestión de archivos.

#### 2. Streaming Replication y WAL Streaming (La verdadera solución)

En lugar de depender de que se "empaquete" el archivo de 16MB para enviarlo (basado en archivos), puedes usar el **protocolo de replicación de PostgreSQL** para enviar los registros del WAL *bloque por bloque* casi en tiempo real (basado en red).

**Herramientas que usan Streaming para Backups:**

* **`pg_receivewal` (Nativa de PostgreSQL):**
Es una utilidad de línea de comandos que se conecta al servidor como si fuera una réplica. Recibe los registros WAL en tiempo real y los escribe en otro servidor. Si el servidor principal explota, `pg_receivewal` tendrá los datos casi hasta el último milisegundo antes de la caída.
* **pgBackRest:**
Es, hoy en día, el estándar de oro para backups en PostgreSQL. Aunque soporta el archivado clásico, también soporta configuración asíncrona y puede integrarse fuertemente con la infraestructura para minimizar la pérdida de datos.
* **Barman (Backup and Recovery Manager):**
Creado por 2ndQuadrant (ahora EDB), Barman tiene una funcionalidad llamada **WAL Streaming**. Utiliza exactamente el mismo principio que `pg_receivewal`: se conecta a tu PostgreSQL y se "trae" el WAL en tiempo real a tu servidor de backups. Esto logra un RPO de prácticamente cero (RPO = 0) sin generar cientos de archivos pequeños inútiles.
 

### Resumen de tu plan de acción

Si quieres proteger ese "tercer WAL" activo frente a una pérdida total de disco:

1. **A corto plazo:** Configura `archive_timeout` a un valor aceptable para tu negocio (ej. 5 o 10 minutos) si estás usando solo `archive_command`.
2. **A largo plazo (Mejor Práctica):** Implementa una herramienta como **Barman con WAL Streaming** o **pgBackRest**, o monta una réplica de base de datos usando *Streaming Replication*.



---


 
# La Diferencia Fundamental: ¿Cómo viaja la información?

Para entender la diferencia, imagina que estás enviando documentos importantes a una bóveda de seguridad.

* **WAL Archivado (Basado en archivos):** Es como enviar cajas por mensajería. PostgreSQL va llenando un archivo (la caja) con las transacciones. Esta caja tiene un tamaño fijo, normalmente de 16MB. Solo cuando la caja se llena por completo, se cierra (rota) y se ejecuta el `archive_command` para enviarla a tu almacenamiento seguro (S3, NFS, etc.).
* **WAL Streaming (Basado en red):** Es como tener una tubería directa a la bóveda. No esperas a que se llene ninguna caja. A medida que las transacciones ocurren en la memoria y se escriben en el disco local, se envían casi de inmediato, bloque por bloque a través de la red, utilizando el protocolo de replicación de PostgreSQL.
 


 
 
## Ventajas y Desventajas

### 1. WAL Archivado Clásico (`archive_command` tradicional)

**Ventajas:**

* **Simplicidad extrema:** Es muy fácil de configurar; basta con un simple script en bash, AWS CLI o rsync.
* **Desacoplamiento:** El servidor de backup no necesita estar conectado todo el tiempo. Simplemente recibe los archivos cuando están listos.
* **Almacenamiento económico:** Ideal para mandar los archivos empaquetados y comprimidos directamente a almacenamiento en frío (Cold Storage).

**Desventajas:**

* **RPO mayor a cero:** Si el servidor explota, pierdes todo lo que estaba en el archivo WAL que aún no se había llenado (el famoso "tercer WAL" del que hablábamos antes).
* **Dependencia del tráfico:** Si hay pocas transacciones, el archivo tardará mucho en llenarse. Forzar la rotación con `archive_timeout` genera una avalancha de archivos pequeños que son ineficientes de gestionar.

### 2. WAL Streaming (`pg_receivewal` / Herramientas modernas de red)

**Ventajas:**

* **RPO casi cero:** La pérdida de datos en caso de desastre total es mínima (milisegundos o nula si usas replicación síncrona), ya que los datos viajan en tiempo real.
* **No hay archivos a medias:** Al enviar bloque por bloque, proteges las transacciones instantáneamente.
* **Gestión eficiente:** No necesitas jugar con `archive_timeout` ni generar miles de archivos residuales en periodos de bajo tráfico.

**Desventajas:**

* **Requiere conexión continua:** Necesita una conexión de red activa, constante y estable entre el servidor principal y el repositorio de backups.
* **Mayor complejidad:** Requiere configurar roles de replicación, `pg_hba.conf` y gestionar *Replication Slots* para evitar que el servidor principal borre los WALs si la red se cae.

### 3. El Enfoque Nube / Alto Rendimiento: WAL-G (La opción más usada en contenedores y Cloud)

*Nota: Por defecto, WAL-G utiliza el mecanismo de archivado (`wal-push`), pero altamente vitaminado, aunque también soporta streaming.*

**Ventajas:**

* **Velocidad y Paralelismo extremo:** WAL-G satura intencionalmente la CPU y la red para comprimir y enviar múltiples archivos WAL al mismo tiempo. Es insuperable en tiempos de recuperación (RTO).
* **Backups Delta (Incrementales por bloque):** A diferencia de las herramientas clásicas, WAL-G es capaz de escanear y enviar solo las páginas (bloques) de datos que cambiaron, ahorrando muchísimo espacio en la nube.
* **Integración Cloud Nativa:** Está diseñado para hablar directamente con S3, Google Cloud Storage o Azure Blob Storage sin necesidad de herramientas intermedias, gestionando su propia retención.

**Desventajas:**

* **RPO mayor a cero (por defecto):** Si solo usas su configuración más popular (`wal-push`), sigues esperando a que el archivo WAL de 16MB rote. Para bajar el RPO a cero, tienes que configurar obligatoriamente su demonio de streaming secundario (`wal-receive`), lo que suma complejidad.
* **Consumo intensivo de recursos:** Su mayor ventaja es su debilidad. Si no limitas adecuadamente el consumo de WAL-G (throttling), su agresivo paralelismo puede robarle recursos de CPU y disco a tu base de datos principal durante un backup.
* **Curva de aprendizaje:** Configurar WAL-G implica manejar múltiples variables de entorno y entender bien su arquitectura, siendo menos intuitivo al principio que un simple comando de copiado.






## Cuadro Comparativo: Archivado vs Streaming

| Característica | WAL Archivado (Archivo) | WAL Streaming (Red) |
| --- | --- | --- |
| **Mecanismo de envío** | Archivos completos (usualmente 16MB) | Flujo continuo de bloques en tiempo real |
| **Pérdida de datos (RPO)** | Minutos u horas (depende del volumen de tráfico) | Cercano a Cero (Milisegundos) |
| **Complejidad de Configuración** | Baja (Scripts simples o comandos de copia) | Media/Alta (Configuración de replicación y slots) |
| **Uso de Red** | Ráfagas (envía 16MB de golpe) | Constante y fluido (ancho de banda bajo pero continuo) |
| **Riesgo ante desastre total** | Alto (Se pierde el archivo activo no rotado) | Muy bajo (Los bloques ya están en el servidor destino) |
| **Herramientas representativas** | `cp`, `rsync`, AWS CLI (S3) | `pg_receivewal`, Barman, WAL-G (`wal-receive`) |
 

## ¿Cuál es mejor y cuándo usar cada uno? (Casos de Uso Reales)

La respuesta honesta de la industria es que **ninguno es estrictamente mejor que el otro de forma aislada; de hecho, en arquitecturas empresariales (Enterprise), se usan JUNTOS.** Sin embargo, si nos enfocamos en el RPO, el Streaming es superior.

### Caso de Uso 1: El enfoque "Económico y Tolerante" (Uso de WAL Archivado)

Imagina un sistema de Data Warehouse interno, un ERP de recursos humanos o una base de datos de reportes que se actualiza por lotes (batch) cada par de horas.

* **Por qué usarlo:** Si el servidor muere y pierdes 10 o 15 minutos de datos, no hay impacto crítico en el negocio, ya que puedes volver a correr el proceso batch. Configuras un `archive_command` enviando los WALs a un bucket S3 de bajo costo. Es barato, fácil de mantener y cumple su función.

### Caso de Uso 2: Misión Crítica y Transaccional (Uso de WAL Streaming)

Imagina el carrito de compras de un e-commerce en Black Friday, un sistema de pagos bancarios o una aplicación SaaS de alta concurrencia.

* **Por qué usarlo:** Perder 5 minutos de transacciones significa cientos de clientes a los que se les cobró pero su orden no se registró. Aquí **debes** usar WAL Streaming (con herramientas como Barman o `pg_receivewal`). La protección continua garantiza que la transacción esté segura casi en el mismo instante en que el usuario hace clic en "Comprar".

### Caso de Uso 3: El Estándar de Oro (El enfoque Híbrido)

Las herramientas modernas como **pgBackRest** o **Barman** recomiendan configurar ambos.

* **El mecanismo:** Utilizas WAL Streaming como tu línea de defensa principal para mantener el RPO en cero. Pero dejas el WAL Archivado (`archive_command`) configurado como un "paracaídas de emergencia" (fallback). Si el proceso de streaming se cae por un problema de red, PostgreSQL seguirá empaquetando los archivos y los enviará mediante el comando de archivado, asegurando que tu disco no se llene y que no te quedes sin respaldos.
