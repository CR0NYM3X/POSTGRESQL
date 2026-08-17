
# 🚀 MANUAL VANGUARD: AUDITORÍA DE ESTRÉS Y BENCHMARKING DE POSTGRESQL

## 🛡️ FASE 1: PREPARANDO LA ARTILLERÍA (El Sistema Operativo)


Si vas a simular a 2,000 usuarios atacando una base de datos simultáneamente, tu máquina cliente (la VM de 98 CPUs) debe poder abrir 2,000 conexiones de red al mismo tiempo. El problema es que **Linux, por seguridad, tiene límites por defecto muy bajos para evitar ataques de denegación de servicio (DDoS).**



#### PASO 1: Capturar el Estado Actual (Antes del ataque)

Ejecuta estos dos comandos y **anota mentalmente o copia en un bloc de notas los números que te devuelven**.

1. **Ver tu límite actual de archivos abiertos:**
```bash
ulimit -n

```


*(Te devolverá un número, generalmente `1024` o `4096`).*
2. **Ver tu rango actual de puertos efímeros de red:**
```bash
sysctl net.ipv4.ip_local_port_range
```


*(Te devolverá dos números, por lo general algo como: `net.ipv4.ip_local_port_range = 32768  60999`).*

#### PASO 2: Armar el Cañón (El cambio temporal)

Ahora sí, aplicas los comandos para darle poder absoluto a tu `pgbench`:

```bash
ulimit -n 65535
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

```



1. **`ulimit -n 65535` (Descriptores de Archivo):** En Linux, todo es un archivo. Una conexión de red (Socket TCP) consume un "File Descriptor". Por defecto, Linux suele limitar esto a `1024` por usuario. Si intentas lanzar 2,000 clientes con `pgbench`, al llegar al cliente 1025 Linux matará el proceso diciendo *"Too many open files"*. Este comando le dice a Linux: *"Permíteme abrir hasta 65,535 conexiones simultáneas"*.
2. **`sysctl -w net.ipv4...` (Puertos Efímeros):** Cuando un cliente se conecta a PostgreSQL (puerto 5432), el cliente necesita usar un puerto de salida temporal (efímero). Si Linux solo tiene configurados 10,000 puertos efímeros y tú lanzas millones de transacciones muy rápido, agotarás los puertos y el `pgbench` fallará por falta de red, falseando tu prueba. Este comando le da a tu máquina un arsenal de más de 64,000 puertos disponibles para disparar conexiones sin ahogarse.

---

## 💥 FASE 2: ESCENARIO A - DESTRUCCIÓN DE UNA BASE DE DATOS NUEVA (TPC-B)

En este escenario, queremos medir la fuerza bruta del servidor (CPU, Memoria y Disco). Usaremos el estándar de la industria llamado **TPC-B** (Transacciones que incluyen `SELECT`, `UPDATE` y `INSERT` en una misma transacción).

### Paso 1: Inicialización (Creación del campo de batalla)

Crearemos una base de datos desde cero con un volumen de datos que exceda la RAM para forzar el uso del disco duro.

```bash
# Se ejecuta en el cliente:
/usr/pgsql-15/bin/pgbench -i -s 1000 -F 90 -U postgres -h [IP_CLOUD_SQL] db_nueva

```

* `-i`: Inicializa las tablas estándar (`pgbench_accounts`, `pgbench_branches`, `pgbench_history`, `pgbench_tellers`).
* `-s 1000`: Factor de escala. Cada escala equivale a 100,000 filas. Esto crea **100 millones de filas** (aprox. 15 GB).
* `-F 90`: Deja 10% de espacio vacío en los bloques para que los futuros `UPDATEs` no fragmenten la tabla instantáneamente.

### Paso 2: El Ataque (Lectura y Escritura Masiva)

Simularemos a 500 clientes concurrentes realizando operaciones de compra/venta durante 5 minutos (300 segundos).

```bash
/usr/pgsql-15/bin/pgbench -c 500 -j 50 -T 300 -M prepared -P 10 -U postgres -h [IP_CLOUD_SQL] db_nueva

```

#### 📊 SALIDA SIMULADA DEL COMANDO (Y CÓMO LEERLA)

```text
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1000
query mode: prepared
number of clients: 500
number of threads: 50
duration: 300 s
number of transactions actually processed: 2,450,000
latency average = 61.224 ms
latency stddev = 15.340 ms
initial connection time = 450.122 ms
tps = 8166.666667 (without initial connection time)

```

**Habla Rodrigo (Gatekeeper - Análisis Forense):**

¿Cómo evalúas esta salida? Un administrador novato vería "8000 TPS" y celebraría. Nosotros vemos más allá:

* **`tps = 8166` (Transacciones Por Segundo):** Es la métrica reina del volumen. El servidor está resolviendo más de 8,000 operaciones bancarias completas por segundo. **Veredicto: Excelente para 16 CPUs.**
* **`latency average = 61.224 ms`:** Es el tiempo que tarda **un** cliente en recibir respuesta.
* *< 10 ms:* Grado Diamante (El servidor va sobrado).
* *10 ms - 50 ms:* Operación Normal en la Nube.
* *> 100 ms:* **Peligro.** La base de datos está sufriendo bloqueos severos o el disco no da abasto. Aquí, 61 ms indica que el disco (I/O) está empezando a sufrir bajo los 500 clientes.


* **`latency stddev = 15.340 ms` (Desviación Estándar):** Esta es la métrica de **estabilidad**. Significa que la mayoría de transacciones tardan 61 ms ± 15 ms (entre 46 y 76 ms).
* *¿Cuándo está mal?* Si la media fuera 60 ms y el `stddev` fuera de **300 ms**, significa que el sistema es inestable: algunas peticiones responden en 5 ms y otras se quedan congeladas por 1 segundo por culpa de los bloqueos (*locks*).



---

## 🎯 FASE 3: ESCENARIO B - ATAQUE QUIRÚRGICO A UNA BASE DE DATOS EXISTENTE

**Tú lo pediste:** *"No quiero crear una BD de prueba, quiero usar la mía con mis propias consultas"*.

Para esto, `pgbench` te permite inyectar tus propios scripts `.sql`. Vamos a probar un sistema real de "Tienda Virtual" que ya existe.

### Paso 1: Diseñar el archivo de prueba (Custom Script)

Crea un archivo llamado `prueba_tienda.sql` en tu terminal Linux:

```sql
-- archivo: prueba_tienda.sql
-- Usamos variables aleatorias para que PostgreSQL no cachee la misma respuesta
\set id_producto random(1, 1000000)
\set id_usuario random(1, 50000)

BEGIN;
  -- 1. Consulta compleja (Lectura)
  SELECT precio, stock FROM catalogo_productos WHERE id_producto = :id_producto;
  
  -- 2. Modificación (Escritura)
  UPDATE catalogo_productos SET stock = stock - 1 WHERE id_producto = :id_producto AND stock > 0;
  
  -- 3. Inserción (Escritura)
  INSERT INTO historial_compras (id_usuario, id_producto, fecha) VALUES (:id_usuario, :id_producto, now());
COMMIT;

```

### Paso 2: Ejecutar el ataque con tu script

No usamos el flag `-i` porque tu base de datos ya existe. Usaremos el flag `-f` para decirle a `pgbench` que ejecute **tu** script.

```bash
/usr/pgsql-15/bin/pgbench -c 200 -j 20 -T 120 -f prueba_tienda.sql -n -P 5 -U postgres -h [IP_CLOUD_SQL] db_tienda_real

```

*(Nota: usamos `-n` para que pgbench no intente hacerle VACUUM a las tablas estándar que no existen).*

#### 📊 SALIDA SIMULADA DEL COMANDO

```text
transaction type: Custom Script: prueba_tienda.sql
query mode: simple
number of clients: 200
number of threads: 20
duration: 120 s
number of transactions actually processed: 185,000
number of failed transactions: 154 (0.083%)
latency average = 129.729 ms
latency stddev = 315.112 ms
tps = 1541.666667 (without initial connection time)

```

**Habla Rodrigo (El Veredicto Crítico):**

Esta salida tiene todas las banderas rojas de una arquitectura enferma. ¡Acompáñame a destrozar este resultado!

1. **`number of failed transactions: 154`:** En el Escenario A, esto no existía. Aquí fallaron 154 operaciones. ¿Por qué? Porque 200 usuarios intentaron comprar el mismo `:id_producto` exactamente en el mismo milisegundo y se generaron **Deadlocks (Interbloqueos)**. Tu aplicación no está lista para alta concurrencia.
2. **`latency average = 129.729 ms`:** Inaceptable para una transacción de 3 pasos. Tienes un cuello de botella.
3. **`latency stddev = 315.112 ms` (ALERTA ROJA):** La desviación estándar es *mayor* que el promedio. Esto significa que mientras algunos usuarios logran comprar en 20 ms, otros se quedan colgados viendo una pantalla de carga durante **casi medio segundo** esperando a que se libere el `UPDATE` de la tabla de inventario.
4. **`tps = 1541`:** Tus TPS colapsaron. Las 16 CPUs de tu servidor están ociosas (al 20%), pero tu sistema va lento porque los procesos están haciendo fila esperando a que se liberen los candados (*Row-level locks*) de la tabla `catalogo_productos`.

---

## 📋 LA TABLA DE DIAGNÓSTICO DEL DBA SQUAD

Para que tú mismo evalúes tus pruebas, usa esta matriz de decisiones corporativas:

| Métrica de pgbench | Estado Sano (Grado Diamante) | Estado Enfermo (Cuello de Botella) | ¿Dónde revisar si está mal? |
| --- | --- | --- | --- |
| **Failed transactions** | `0` (Cero absoluto) | `> 0` | Revisar logs de PostgreSQL por **Deadlocks**. Revisar límites de conexiones (`max_connections`). |
| **Latency average** | `< 25 ms` para RW<br>

<br>`< 5 ms` para Read-Only | `> 100 ms` | Revisar IOPS de tu disco en Cloud SQL. Si es lectura, te faltan índices. |
| **Latency stddev** | Mucho menor que el promedio (ej. Avg 15ms, Stddev 2ms) | Mayor que el promedio (Sube en picos erráticos) | Hay bloqueos transaccionales severos, o puntos de estrangulamiento en tu red (Throttling del Cloud). |
| **TPS** | Sube linealmente conforme agregas más clientes (`-c`). | Se estanca o **baja** cuando agregas más clientes. | Llegaste al límite físico de la RAM o CPU. Tu servidor ya no da más. |

---

**Sofía:**
Este es un plan de fuego real. Tienes la herramienta (`pgbench`), la preparación del servidor, los comandos destructivos y la capacidad forense para leer lo que arroja la pantalla.

Cuando dispares tu cañón de 98 CPUs contra la nube, recuerda subir la concurrencia (`-c`) paso a paso: primero 50, luego 200, luego 500, hasta que veas que los **TPS** dejan de subir y la **Latencia** se dispara. ¡Ese es el techo físico de tu arquitectura!


## Links
```
pgbench de test de optimización -> https://github.com/CR0NYM3X/POSTGRESQL/blob/fe4f18ffc5cc79162eb4d11a8d8abaf2d1e61a22/monitoreo/Monitoreo%2C%20optimizaci%C3%B3n%20y%20mantenimientos.md#herramienta-pgbench-de-test-de-optimizaci%C3%B3n

-------- BIBLIOGRAFÍAS ---------------
Existe la tool pgingester, que es más para metodos de ingestión(inserción)  link referencias : https://medium.com/timescale/benchmarking-postgresql-batch-ingest-5fbe097de

https://www.postgresql.org/docs/current/pgbench.html
https://medium.com/@c.ucanefe/pgbench-load-test-66bdfb5c75a
https://juantrucupei.wordpress.com/07//30/uso-de-pgbench-para-pruebas-stress-postgresql/

```


### Help de PgBench

```SQL
/usr/pgsql-15/bin/pgbench --help 
pgbench is a benchmarking tool for PostgreSQL.

Usage:
  pgbench [OPTION]... [DBNAME]

Initialization options:
  -i, --initialize         invokes initialization mode
  -I, --init-steps=[dtgGvpf]+ (default "dtgvp")
                           run selected initialization steps
  -F, --fillfactor=NUM     set fill factor
  -n, --no-vacuum          do not run VACUUM during initialization
  -q, --quiet              quiet logging (one message each 5 seconds)
  -s, --scale=NUM          scaling factor
  --foreign-keys           create foreign key constraints between tables
  --index-tablespace=TABLESPACE
                           create indexes in the specified tablespace
  --partition-method=(range|hash)
                           partition pgbench_accounts with this method (default: range)
  --partitions=NUM         partition pgbench_accounts into NUM parts (default: 0)
  --tablespace=TABLESPACE  create tables in the specified tablespace
  --unlogged-tables        create tables as unlogged tables

Options to select what to run:
  -b, --builtin=NAME[@W]   add builtin script NAME weighted at W (default: 1)
                           (use "-b list" to list available scripts)
  -f, --file=FILENAME[@W]  add script FILENAME weighted at W (default: 1)
  -N, --skip-some-updates  skip updates of pgbench_tellers and pgbench_branches
                           (same as "-b simple-update")
  -S, --select-only        perform SELECT-only transactions
                           (same as "-b select-only")

Benchmarking options:
  -c, --client=NUM         number of concurrent database clients (default: 1)
  -C, --connect            establish new connection for each transaction
  -D, --define=VARNAME=VALUE
                           define variable for use by custom script
  -j, --jobs=NUM           number of threads (default: 1)
  -l, --log                write transaction times to log file
  -L, --latency-limit=NUM  count transactions lasting more than NUM ms as late
  -M, --protocol=simple|extended|prepared
                           protocol for submitting queries (default: simple)
  -n, --no-vacuum          do not run VACUUM before tests
  -P, --progress=NUM       show thread progress report every NUM seconds
  -r, --report-per-command report latencies, failures, and retries per command
  -R, --rate=NUM           target rate in transactions per second
  -s, --scale=NUM          report this scale factor in output
  -t, --transactions=NUM   number of transactions each client runs (default: 10)
  -T, --time=NUM           duration of benchmark test in seconds
  -v, --vacuum-all         vacuum all four standard tables before tests
  --aggregate-interval=NUM aggregate data over NUM seconds
  --failures-detailed      report the failures grouped by basic types
  --log-prefix=PREFIX      prefix for transaction time log file
                           (default: "pgbench_log")
  --max-tries=NUM          max number of tries to run transaction (default: 1)
  --progress-timestamp     use Unix epoch timestamps for progress
  --random-seed=SEED       set random seed ("time", "rand", integer)
  --sampling-rate=NUM      fraction of transactions to log (e.g., 0.01 for 1%)
  --show-script=NAME       show builtin script code, then exit
  --verbose-errors         print messages of all errors

Common options:
  -d, --debug              print debugging output
  -h, --host=HOSTNAME      database server host or socket directory
  -p, --port=PORT          database server port number
  -U, --username=USERNAME  connect as specified database user
  -V, --version            output version information, then exit
  -?, --help               show this help, then exit

Report bugs to <pgsql-bugs@lists.postgresql.org>.
```



