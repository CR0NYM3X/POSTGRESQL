
# timescaledb
 
# **Marcos (Arquitecto Senior): Arquitectura y Flujo de Fuego (Data Flow)**

Olvida las tablas tradicionales. En TimescaleDB, la arquitectura se divide en dos dimensiones: el **Plano Lógico** (lo que tú y tus aplicaciones ven) y el **Plano Físico** (cómo se almacena realmente en el disco y la RAM).

### Los 3 Conceptos Nucleares

1. **Hipertabla (Hypertable):** Es una ilusión, un "holograma". Es una tabla virtual que actúa como el enrutador principal. Tú envías todos tus `INSERT` y `SELECT` aquí. Nunca te preocupas por dónde caen los datos físicamente.
2. **Chunks (Fragmentos):** Son las tablas reales y físicas ocultas en el sistema operativo. Cada Chunk almacena un rango de tiempo específico (por ejemplo, todos los datos del lunes). Cuando el lunes termina, TimescaleDB sella ese Chunk y crea uno nuevo para el martes.
3. **Chunk Exclusion (Exclusión de Fragmentos):** Es la capacidad del motor de ignorar archivos físicos completos al leer. Si pides datos de "hoy", el motor ni siquiera voltea a ver los Chunks del mes pasado. No los lee, no usa I/O, no consume CPU.

### El Flujo de Ejecución (El viaje de un INSERT)

Cuando tu sensor dispara un dato hacia la base de datos, el flujo interno es estricto y secuencial:

1. **Intercepción del Dato:** Plano Lógico.
El cliente ejecuta un `INSERT INTO metricas_sensores`. El motor de TimescaleDB intercepta la transacción antes de que PostgreSQL intente escribirla en el disco tradicional.


2. **Lectura del Timestamp:** Motor de Enrutamiento.
El motor lee obligatoriamente la columna de tiempo (ej. `2023-10-25 14:30:00`). Esta es la coordenada de aterrizaje.


3. **Resolución de Chunk:** Gestión en Memoria.
TimescaleDB busca si ya existe un Chunk físico abierto para ese día. Si no existe (porque acaba de cambiar el día), lo crea al vuelo en milisegundos sin bloquear la tabla maestra.


4. **Escritura en Memoria (Indexación B-Tree):** Plano Físico.
El dato se escribe *únicamente* en el Chunk activo. Como este Chunk es nuevo y pequeño, todo su índice cabe perfectamente en la memoria RAM. El disco casi ni se entera. Por esto puede absorber cientos de miles de registros por segundo.






---
**Marcos (Arquitecto Senior): La Anatomía de TimescaleDB**

Para entender TimescaleDB, primero debes olvidar el concepto de una tabla relacional tradicional. TimescaleDB **no es un motor nuevo**, es una extensión nativa que transforma a PostgreSQL en un monstruo diseñado para **series de tiempo (Time-Series Data)**.

Su magia radica en la **Hipertabla (Hypertable)**. Lógicamente, tú ves y consultas una sola tabla gigante. Pero físicamente, TimescaleDB está despedazando esa tabla en pequeños bloques invisibles llamados **Chunks**, particionados automáticamente por rangos de tiempo (y opcionalmente por otra llave, como el ID de un dispositivo).

### Cuándo USAR TimescaleDB (Escenarios de Fuego)

* **IoT y Telemetría:** Sensores enviando métricas cada segundo (temperatura, GPS, RPM).
* **Sistemas Financieros (Tick Data):** Precios de acciones, criptomonedas o transacciones masivas registradas por microsegundo.
* **Monitoreo y Logs:** Almacenamiento masivo de eventos de servidores o tráfico de red.
* **La regla de oro:** Tu carga de trabajo es 95% `INSERT` (Append-only), tus consultas siempre filtran por un rango de tiempo, y casi nunca haces `UPDATE` o `DELETE` a registros individuales.

### Cuándo NO USAR TimescaleDB

* **Sistemas OLTP Transaccionales:** ERPs, CRMs, inventarios, carritos de compra. Si los datos cambian constantemente de estado (ej. un pedido que pasa de "Pendiente" a "Pagado"), TimescaleDB destruirá tu rendimiento.
* **Datos sin un eje de tiempo estricto:** Si tu tabla no tiene una columna de fecha/hora como llave principal absoluta, no uses esta extensión.
* **Volúmenes pequeños:** Si tu tabla nunca va a superar los 10 millones de registros, el particionamiento nativo de PostgreSQL es suficiente. TimescaleDB brilla cuando hablamos de **cientos de millones o billones de filas**.

---

**Pedro (Desarrollo Core): La Forja del Código**

Suficiente teoría. Así es como se construye y se explota a nivel de motor. El código debe ser quirúrgico.

**1. Activación de la Extensión**

```sql
-- Se ejecuta una sola vez por base de datos, con privilegios altos.
CREATE EXTENSION IF NOT EXISTS timescaledb;

```

**2. Creación de la Hipertabla**
Primero creas una tabla estándar en PostgreSQL. El único requisito innegociable es que tenga una columna de tiempo.

```sql
CREATE TABLE metricas_sensores (
    tiempo TIMESTAMPTZ NOT NULL,
    sensor_id INT NOT NULL,
    temperatura DOUBLE PRECISION,
    cpu_usage DOUBLE PRECISION
);

-- La transformación: Convertimos la tabla en una Hipertabla.
-- El chunk_time_interval es crítico (por defecto es 7 días).
SELECT create_hypertable('metricas_sensores', 'tiempo', chunk_time_interval => INTERVAL '1 day');

```

**3. Análisis y Consultas (El verdadero poder)**
TimescaleDB nos regala funciones analíticas exclusivas. La más letal es `time_bucket()`. Sirve para agrupar millones de registros en ventanas de tiempo exactas sin hacer subconsultas complejas.

*Ejemplo: Obtener el promedio de temperatura en bloques de 15 minutos.*

```sql
SELECT 
    time_bucket('15 minutes', tiempo) AS bloque_15m,
    sensor_id,
    AVG(temperatura) AS temp_promedio,
    MAX(cpu_usage) AS pico_cpu
FROM metricas_sensores
WHERE tiempo > NOW() - INTERVAL '24 hours'
GROUP BY bloque_15m, sensor_id
ORDER BY bloque_15m DESC;

```

---

**Mauricio (QA y Mantenimiento): Estándares de Retención y Compresión**

Si solo insertas datos y nunca los limpias, te vas a quedar sin disco. En un estándar de Grado Diamante, la base de datos debe limpiarse sola.

**1. Políticas de Compresión (Ahorro del 90% de disco)**
TimescaleDB puede comprimir *chunks* antiguos volviéndolos de solo lectura.

```sql
-- Habilitar compresión en la hipertabla
ALTER TABLE metricas_sensores SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'sensor_id'
);

-- Comprimir automáticamente datos más antiguos de 7 días
SELECT add_compression_policy('metricas_sensores', INTERVAL '7 days');

```

**2. Políticas de Retención (Destrucción controlada)**
No usamos `DELETE`. Usamos políticas nativas que destruyen el *chunk* completo a nivel de archivo (I/O rapidísimo).

```sql
-- Eliminar físicamente cualquier dato más antiguo de 6 meses
SELECT add_retention_policy('metricas_sensores', INTERVAL '6 months');

```

---


### 🔍 8.6 Monitoreo interno

```sql
-- Ver chunks existentes
SELECT * FROM timescaledb_information.chunks WHERE hypertable_name = 'sensores';

-- Ver uso de compresión
SELECT * FROM timescaledb_information.compressed_chunk_stats;
```

***

### 🧭 8.7 Indexación avanzada

```sql
-- Indexar por dispositivo y tiempo
CREATE INDEX ON sensores (dispositivo_id, timestamp DESC);

-- Indexar por temperatura para búsquedas rápidas
CREATE INDEX ON sensores (temperatura);
```

***

### 🔄 8.8 Reordenamiento de chunks

```sql
-- Crear política de reordenamiento
SELECT add_reorder_policy('sensores', 'timestamp');
```

---

**Rodrigo (El Gatekeeper): La Prueba de Fuego y Riesgos Operativos**

El equipo te ha pintado la herramienta de maravilla, pero yo estoy aquí para decirte dónde vas a estrellar el servidor si operas como un amateur. Lee esto con cuidado:

| Ventaja Táctica | El Riesgo Oculto (Desventaja) |
| --- | --- |
| **Ingesta Masiva:** Permite miles de `INSERT` por segundo porque solo escribe en el *chunk* más reciente en memoria. | **Memoria RAM Asfixiada:** Si configuras tus *chunks* muy grandes (ej. 1 mes), el *chunk* activo y sus índices no cabrán en la RAM. Tu servidor empezará a usar el disco (Swap) y el rendimiento caerá a cero en minutos. |
| **Consultas Históricas Rápidas:** El motor descarta automáticamente los *chunks* que no entran en tu `WHERE tiempo BETWEEN...`. | **Consultas sin Tiempo:** Si haces un `SELECT` sin filtrar por la columna de tiempo, TimescaleDB tendrá que escanear físicamente todos los *chunks* de la historia. Bloquearás los recursos de I/O del servidor. |
| **Compresión Extrema:** Datos históricos pasan de pesar Terabytes a Gigabytes. | **Inmutabilidad:** Modificar un dato comprimido es carísimo. Si requieres hacer `UPDATE` sobre un registro de hace 3 meses que ya está comprimido, el motor tiene que descomprimir el bloque, alterar y volver a comprimir. |

**Mi veredicto final:** TimescaleDB es un arma de precisión. Si la usas para series de tiempo puras, afinando el tamaño de tus *chunks* para que equivalgan al 25% de tu memoria RAM disponible, serás imparable. Si intentas meter aquí tus tablas de usuarios o facturas, yo mismo apagaré tu servidor.



----


# El Reporte de Impacto

 
### 1. Lecturas Analíticas (SELECT SUM, AVG, MAX)

* **Velocidad:** **BRUTALMENTE MÁS RÁPIDO (Hasta 100x).**
* **¿Por qué?** Porque el disco duro tiene que leer muchísimos menos Megabytes. Como los datos están comprimidos por columnas, I/O (la velocidad de lectura del disco) deja de ser un cuello de botella. Consultar meses de historia toma milisegundos.

### 2. Búsqueda de un registro individual (SELECT * WHERE id = 5)

* **Velocidad:** **MÁS LENTO.**
* **¿Por qué?** Si necesitas ver *todas* las columnas de un solo registro específico, el formato columnar es tu enemigo. El motor tiene que ir a buscar el fragmento de la columna A, luego el de la B, luego el de la C, descomprimirlos en memoria y "armar" la fila de nuevo para mostrártela.

### 3. Inserciones nuevas (INSERT)

* **Velocidad:** **INVARIABLE (Súper Rápido).**
* **¿Por qué?** Porque tú **nunca insertas datos en un Chunk comprimido**. Las inserciones nuevas caen siempre en el Chunk "activo" del día de hoy (que está descomprimido y vive en memoria RAM). La compresión solo ocurre sobre el pasado (datos históricos).

### 4. Modificaciones o Borrados (UPDATE / DELETE)

* **Velocidad:** **CATASTRÓFICAMENTE LENTO (O directamente bloqueado).**
* **¿Por qué?** Esta es la regla de hierro que tumba servidores. No puedes modificar un dato que está comprimido. Si intentas hacer un `UPDATE` a un registro de hace tres meses, TimescaleDB tiene que:
1. Pausar tu consulta.
2. Leer el bloque entero del disco.
3. Descomprimir el bloque completo en la RAM.
4. Aplicar tu `UPDATE`.
5. Volver a comprimir todo el bloque.
6. Escribirlo de nuevo en el disco.



Esto disparará tu uso de CPU al 100% y colapsará las operaciones de los demás usuarios.

**Mi veredicto final:** Comprimir te hace volar a la velocidad de la luz si tu objetivo es **leer históricos y hacer cálculos matemáticos (Dashboards, Reportes, Gráficas)**. Pero si intentas tratar esos datos comprimidos como si fueran una tabla normal donde puedes editar y borrar a tu antojo, el motor te va a castigar severamente.



---

### La Verdad sobre la Compresión

**Mauricio (QA y Mantenimiento):**
Respuesta corta: **Se comprime TODA la tabla (todas las columnas)**.

No te confundas. El comando `segmentby = 'sensor_id'` NO significa que solo el ID se va a comprimir. Significa que el motor usará el `sensor_id` como la **regla de agrupación** antes de aplastar los datos.

Funciona así:

1. TimescaleDB toma un bloque de tiempo (ej. los datos de ayer).
2. Lee tu instrucción `segmentby = 'sensor_id'`.
3. Separa todos los registros del Sensor 1, luego los del Sensor 2, etc.
4. Una vez agrupados, toma **cada columna individualmente** (la columna tiempo, la columna temperatura, la columna CPU, etc.) y las comprime convirtiéndolas en diccionarios o deltas matemáticos.

¿Por qué importa esto? Porque cuando haces un `SELECT temperatura FROM metricas WHERE sensor_id = 1`, el motor ni siquiera descomprime la columna del CPU o la del tiempo. Va directo al bloque comprimido del Sensor 1, extrae solo la matriz de "temperatura" y te la entrega. **Comprime todo, pero lo aísla para que leas solo lo que necesitas.**
 

## Glosario de Arquitectura en Trinchera (Preguntas Frecuentes)

**Marcos (Arquitectura Senior):**
He diseñado arquitecturas para entornos de telemetría que ingieren gigabytes por hora. Aquí están las preguntas estructurales que definen si tu sistema vivirá años o morirá en semanas.

### 1. ¿Cuál es el tamaño perfecto para el `chunk_time_interval`?

**Respuesta de Arquitectura:** El tamaño de tu Chunk activo (el que está recibiendo inserciones hoy) y todos sus índices **deben caber obligatoriamente en el 25% de la memoria RAM** de tu servidor.

* *El error amateur:* Dejar el valor por defecto (7 días) en un servidor pequeño que recibe millones de registros al día. El Chunk crecerá a 10 GB, tu RAM se llenará, el servidor usará la paginación del disco duro (Swap) y tu base de datos se congelará.

### 2. ¿Puedo usar Llaves Foráneas (Foreign Keys) en una Hipertabla?

**Respuesta de Arquitectura:** Sí, pero con restricciones tácticas. Puedes tener una tabla normal de `clientes` o `dispositivos` y hacer que tu Hipertabla apunte a ellas. Lo que **NO puedes hacer** es que una tabla normal apunte hacia la Hipertabla.

* *La regla:* Las Hipertablas referencian catálogos estáticos; los catálogos nunca referencian Hipertablas.

### 3. Consultar meses de historia consume mucha CPU para mis Dashboards. ¿Cómo lo resuelvo?

**Respuesta de Arquitectura:** Usando **Continuous Aggregates (Vistas Materializadas Continuas)**. No pones a tu Grafana o tu PowerBI a sumar millones de filas cada vez que el usuario recarga la página. Creas un *Continuous Aggregate* que pre-calcula los promedios cada hora y los guarda en segundo plano. Tus Dashboards leen de esta vista pre-calculada, respondiendo en milisegundos sin tocar los Chunks originales.

### 4. ¿Qué pasa con los respaldos y la replicación cuando se comprime o se crea un Chunk nuevo?

**Intervención de Javier (Alta Disponibilidad):** Aquí es donde los sistemas colapsan. Cuando TimescaleDB comprime un Chunk histórico (digamos de 50 GB a 5 GB), internamente está reescribiendo la tabla. Esto genera una avalancha masiva de transacciones (*Write-Ahead Logs* o WAL). Si tus réplicas de solo lectura o tus respaldos no tienen una red lo suficientemente rápida, se van a desincronizar y generarás un rezago destructivo (*Replication Lag*). La compresión debe programarse en horas de bajo tráfico.

### 5. ¿Eliminar datos viejos bloquea la tabla productiva?

**Respuesta de Arquitectura:** **Absolutamente no.** Esta es la mayor ventaja física. Si usas un `DELETE FROM tabla WHERE fecha < hace_un_año`, PostgreSQL tiene que escanear fila por fila, marcarlas como borradas, generar bloqueos y luego pasar un proceso de limpieza (*Vacuum*). Tarda horas y destruye el rendimiento.
Con TimescaleDB usamos `drop_chunks()`. El motor simplemente le dice al sistema operativo Linux: *"Borra este archivo físico del disco"*. Es una operación `O(1)`. Libera cientos de gigabytes en un milisegundo sin bloquear un solo `INSERT`.

 




---

#  **Protocolo Operativo Táctico: Telemetría de Flotas Frigoríficas (IoT)**.

Este escenario simula la ingesta de sensores de temperatura de camiones. Si la temperatura sube, la carga se pudre. El orden de ejecución es crítico. Ejecuta esto paso a paso en tu servidor.


1. **Fase 1: Forja de la Hipertabla e Índices:** Arquitecto Marcos.
El error número uno es crear la tabla, llenarla de datos y *luego* intentar convertirla. En TimescaleDB, la estructura se blinda en vacío.

```sql
-- 1. Activación del Motor
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- 2. Creación de la Tabla Estándar
CREATE TABLE telemetria_flota (
    tiempo        TIMESTAMPTZ       NOT NULL,
    camion_id     VARCHAR(50)       NOT NULL,
    temperatura   DOUBLE PRECISION  NOT NULL,
    rpm_motor     INT               NOT NULL,
    nivel_bateria DOUBLE PRECISION
);

-- 3. Transformación a Hipertabla (El corazón de la extensión)
-- Asignamos chunks de 1 día. Regla: El chunk de 1 día debe caber en el 25% de tu RAM.
SELECT create_hypertable(
    'telemetria_flota', 
    'tiempo', 
    chunk_time_interval => INTERVAL '1 day'
);

-- 4. Creación de Índices Tácticos
-- TimescaleDB crea un índice automático en "tiempo". 
-- Nosotros creamos uno compuesto para optimizar filtros específicos por camión.
CREATE INDEX idx_telemetria_camion_tiempo 
ON telemetria_flota (camion_id, tiempo DESC);

```


2. **Fase 2: Ingesta Masiva y Mutación (DML):** Ingeniero Pedro.
Vamos a inyectar 100,000 registros simulando el tráfico de 5 camiones durante los últimos 30 días, generados cada 2 minutos.

```sql
-- 1. Inserción Masiva (Simulación de Telemetría)
INSERT INTO telemetria_flota (tiempo, camion_id, temperatura, rpm_motor, nivel_bateria)
SELECT
    gen_tiempo,
    'TRK-' || (random() * 4 + 1)::INT, -- 5 camiones diferentes
    (random() * 15) - 5,               -- Temperatura entre -5 y 10 grados
    (random() * 3000 + 500)::INT,      -- RPM del motor
    random() * 100                     -- Batería
FROM generate_series(
    NOW() - INTERVAL '30 days', 
    NOW(), 
    INTERVAL '2 minutes'
) AS gen_tiempo;

-- 2. Actualización (UPDATE)
-- Regla de fuego: SÍ puedes hacer UPDATE en el Chunk ACTIVO (datos de hoy).
-- NUNCA hagas UPDATE en chunks comprimidos del pasado.
UPDATE telemetria_flota 
SET temperatura = 0.0 
WHERE camion_id = 'TRK-1' 
  AND tiempo > NOW() - INTERVAL '1 hour' 
  AND temperatura > 5.0;

-- 3. Borrado (DELETE Manual)
-- Solo para purga de errores en el chunk activo.
DELETE FROM telemetria_flota 
WHERE tiempo > NOW() - INTERVAL '1 hour' 
  AND rpm_motor > 5000; -- Borrar lecturas anómalas

```


3. **Fase 3: Analítica y Reparación (Gapfilling):** Ingeniero Mauricio.
Los sensores fallan y dejan "huecos" en los reportes. Usaremos las funciones avanzadas que viste en el catálogo: `time_bucket` y `locf` (Last Observation Carried Forward).

```sql
-- Reporte analítico: Promedio de temperatura por hora de los últimos 2 días.
-- time_bucket_gapfill rellenará las horas donde el camión no envió datos (ej. apagado).
-- locf() tomará la última temperatura conocida y la arrastrará al hueco.

SELECT 
    time_bucket_gapfill('1 hour', tiempo) AS bloque_hora,
    camion_id,
    ROUND(AVG(temperatura)::numeric, 2) AS temp_promedio,
    ROUND(locf(AVG(temperatura))::numeric, 2) AS temp_reparada
FROM telemetria_flota
WHERE tiempo > NOW() - INTERVAL '2 days'
  AND tiempo < NOW()
  AND camion_id = 'TRK-1'
GROUP BY bloque_hora, camion_id
ORDER BY bloque_hora DESC;

```


4. **Fase 4: Continuous Aggregates (Vistas Materializadas):** Ingeniero Javier.
Tus Dashboards (Grafana/PowerBI) no pueden consultar la hipertabla en crudo; destruirían la CPU. Construimos una Vista Materializada Continua.

```sql
-- 1. Crear la Vista (Se calcula automáticamente en segundo plano)
CREATE MATERIALIZED VIEW reporte_horario_camiones
WITH (timescaledb.continuous) AS
SELECT 
    time_bucket('1 hour', tiempo) AS bloque_hora,
    camion_id,
    AVG(temperatura) AS temp_promedio,
    MAX(rpm_motor) AS max_rpm
FROM telemetria_flota
GROUP BY bloque_hora, camion_id;

-- 2. Configurar la Política de Refresco Automático
-- Le ordenamos que recalcule los datos desde hace 3 días hasta hace 1 hora,
-- y que ejecute este trabajo cada hora.
SELECT add_continuous_aggregate_policy('reporte_horario_camiones',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);

```


5. **Fase 5: Compresión y Retención (Supervivencia de Disco):** Arquitecto Héctor.
Si no ejecutas esto, el servidor morirá sin espacio en 6 meses. Esta es la automatización del mantenimiento.

```sql
-- 1. Activar Compresión Columnar
-- Usamos segmentby = camion_id para que el algoritmo agrupe y comprima al 95%.
-- orderby = tiempo DESC (requerido para eficiencia).
ALTER TABLE telemetria_flota SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'camion_id',
    timescaledb.compress_orderby = 'tiempo DESC'
);

-- 2. Política de Compresión Automática
-- Todo dato más viejo de 7 días se congela y se comprime.
SELECT add_compression_policy('telemetria_flota', INTERVAL '7 days');

-- 3. Política de Retención (El destructor de Chunks)
-- En lugar de un lento DELETE, TimescaleDB borrará el archivo físico
-- completo del sistema operativo para datos más viejos de 1 año.
SELECT add_retention_policy('telemetria_flota', INTERVAL '1 year');

```


---

### 🛡️ El Veredicto Final (Rodrigo - Gatekeeper)

Has ejecutado un entorno corporativo. Aquí tienes mis 3 advertencias de homologación sobre lo que acabas de hacer:

1. **La Trampa del `end_offset` en Vistas Continuas:** En el Paso 4 configuramos `end_offset => INTERVAL '1 hour'`. Esto es vital. Si lo pones en `0`, la vista intentará materializar datos que *todavía están llegando*, bloqueando las inserciones de tus sensores en tiempo real.
2. **Prohibición de Cambios Estructurales Post-Compresión:** Una vez que el Paso 5 empiece a comprimir datos (después de 7 días), **NO puedes hacer un `ALTER TABLE telemetria_flota ADD COLUMN...**`. TimescaleDB te bloqueará. Para alterar la tabla, tendrías que detener la compresión y descomprimir los datos. Diseña tu modelo de datos bien desde el día cero.
3. **Monitoreo de Trabajos en Segundo Plano:** Viste funciones como `bgw_job_stat` en tu escaneo. Las políticas de retención, compresión y vistas continuas son "Background Workers". Si el servidor se queda sin RAM, PostgreSQL matará estos procesos silenciosamente. Monitorea periódicamente ejecutando `SELECT * FROM timescaledb_information.jobs;` para verificar que tus políticas no estén fallando.



```
\dx+ timescaledb
select name,setting from pg_settings where name ilike '%timesca%' order by name;
```



---


 
**Marcos (Arquitecto Senior): La Matemática de los Hilos (Slots)**

PostgreSQL tiene un número máximo de "ranuras" (*slots*) para procesos de fondo, definido por `max_worker_processes` (por defecto viene en 8, un chiste para un entorno de telemetría).

TimescaleDB necesita sus propias ranuras para poder ejecutar la compresión, el borrado (retención) y recalcular tus vistas. Ese límite lo define `timescaledb.max_background_workers`.

**La Regla Estructural de Fuego:**
El parámetro global de PostgreSQL (`max_worker_processes`) debe ser obligatoriamente **mayor** a la suma de todas las herramientas que exigen hilos.

Esta es la fórmula de Grado Diamante que usamos para calcularlo:

> `max_worker_processes` = `timescaledb.max_background_workers` + `max_parallel_workers` + `Margen de Seguridad (3 a 5)`

* **`timescaledb.max_background_workers`:** Recomiendo configurarlo en **8**. Esto le permite a TimescaleDB comprimir varias hipertablas al mismo tiempo y actualizar tus Vistas Continuas sin hacer fila.
* **`max_parallel_workers`:** (Por defecto 8). Son los hilos que usa PostgreSQL para dividir un simple `SELECT` pesado en varias partes y leerlas al mismo tiempo.
* **Margen de Seguridad:** Necesitas dejar al menos 3 a 5 hilos libres para que PostgreSQL pueda ejecutar procesos internos lógicos o de replicación.

**El Cálculo para tu Servidor (Ejemplo Táctico):**
Si quieres 8 hilos para TimescaleDB y mantienes 8 para consultas paralelas, tu cálculo es: `8 + 8 + 5 = 21`.
Por lo tanto, tu `max_worker_processes` debe ser **21**.

 

**Samuel (Administrador de S.O. Linux): Despliegue y Reinicio Físico**

Marcos te dio los números. Yo te voy a decir cómo inyectarlos en el servidor sin destruirlo. Presta mucha atención, porque **cambiar estos parámetros altera la asignación de memoria RAM compartida (Shared Memory) a nivel del kernel de Linux**.

**Paso 1: Audita tu estado actual**
Ejecuta esto en tu cliente SQL para ver cómo estás operando ahora mismo:

```sql
SHOW max_worker_processes;
SHOW max_parallel_workers;
SHOW timescaledb.max_background_workers;

```

**Paso 2: La Modificación del Archivo Físico**
Entra a la terminal de tu servidor Linux por SSH y edita el archivo maestro `postgresql.conf`. (Si no sabes dónde está, ejecuta `SHOW config_file;` en SQL).

Abre el archivo con tu editor (nano/vim) y ajusta las líneas exactas:

```ini
# Ubica o agrega estas líneas en postgresql.conf
max_worker_processes = 25              # El total general de PostgreSQL
max_parallel_workers = 8               # Límite para consultas pesadas
timescaledb.max_background_workers = 8 # El límite exclusivo para TimescaleDB

```

**Paso 3: El Reinicio Crítico (La Trampa Mortal)**
Aquí es donde caen los novatos. El 90% de los parámetros en PostgreSQL se pueden aplicar en caliente ejecutando un simple `SELECT pg_reload_conf();`.

**ESTOS PARÁMETROS NO.**
Si haces un `reload`, el motor ignorará el cambio y tus políticas de compresión seguirán fallando. Tienes que reiniciar el servicio completo de PostgreSQL a nivel del sistema operativo. Esto provocará una interrupción (*downtime*) de un par de segundos. Debes hacerlo en una ventana de mantenimiento programada.

```bash
# Ejecutar como usuario root o sudo en tu servidor Linux
systemctl restart postgresql

```

 
