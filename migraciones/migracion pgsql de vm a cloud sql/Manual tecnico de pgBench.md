# Plan Maestro de Benchmarking y Auditoría de Estrés: Cloud SQL PostgreSQL (Enterprise Plus)

**Arquitectura del Laboratorio de Pruebas**

| Componente | Rol | Especificaciones Clave |
| --- | --- | --- |
| **Origen (Cliente)** | Generador de Carga | VM GCP `n2d-standard-96` (96 vCPUs, 384 GB RAM). Red optimizada con `ulimit -n 65535` y `net.ipv4.ip_local_port_range`. |
| **Destino (Servidor)** | Cloud SQL Auditado | PostgreSQL 15.18 Enterprise Plus (`db-perf-optimized-N-16`, 16 vCPUs, 128 GB RAM). Caché de datos: 750 GB (NVMe SSD local). Almacenamiento: 600 GB SSD. Límites Físicos: 25,000 IOPS Máx (Lectura/Escritura), Throughput Disco: 1,200 MB/s Lectura / 600 MB/s Escritura, Throughput Red: 2,000 MB/s. |




### Fase 1: Tuning del Origen (Evitar el colapso del atacante)

Si disparamos miles de hilos concurrentes, tu VM de 96 cores se asfixiará a nivel de red (Linux) antes de que Cloud SQL sufra. Ejecuta esto en tu máquina cliente (Origen) para desbloquear el límite de sockets TCP:

```bash
# 1. Ampliar límite de archivos (sockets) abiertos por el sistema
ulimit -n 65535

# 2. Habilitar todo el espectro de puertos efímeros para conexiones de salida
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

```


### Diccionario de Parámetros de `pgbench` (Armería del DBA)

Para operar la herramienta con precisión, aquí tienes el desglose exacto de cada parámetro que usaremos en las pruebas y su propósito operativo:

* **`-i` (Initialize):** Ordena a `pgbench` crear la estructura base. Genera 4 tablas estándar (`pgbench_accounts`, `pgbench_branches`, `pgbench_tellers`, `pgbench_history`).
* **`-s` (Scale):** Multiplicador de tamaño. 1 factor de escala = 100,000 filas (aprox. 15 MB). Un `-s 5000` genera 500 millones de filas (aprox. 75 GB de datos puros más índices).
* **`-F` (Fillfactor):** Porcentaje de llenado de cada bloque de disco (1-100). Usar `-F 90` deja un 10% vacío en cada página de memoria, evitando que futuros `UPDATEs` masivos fragmenten la tabla y generen bloqueos.
* **`-c` (Clients):** Número de clientes concurrentes atacando la base de datos simultáneamente. Simula el tráfico real.
* **`-j` (Jobs/Threads):** Hilos de procesamiento en tu máquina atacante (Origen). Debe ser igual o menor a tus 96 vCPUs para repartir la carga de lanzar conexiones.
* **`-T` (Time):** Duración de la prueba en segundos.
* **`-S` (Select-only):** Fuerza a que la prueba solo haga lecturas. Excelente para probar el límite estricto de la CPU y la RAM sin tocar el disco.
* **`-C` (Connect):** Cierra y abre la conexión TCP por cada transacción. Simula el peor escenario posible de una aplicación mal diseñada (sin pool de conexiones).
* **`-M` (Protocol):** Modo de envío de consultas. `prepared` pre-compila la consulta (lo óptimo en producción), mientras que `simple` envía el texto plano cada vez (más pesado para el parser de Postgres).

---

### Fase 1: Sembrado Seguro de Datos (Control de Costos)

**Ajuste Crítico de Facturación:** Cloud SQL cobra automáticamente si el disco se auto-expande. Tu disco es de 600 GB. Durante un test de estrés de escritura, PostgreSQL genera archivos temporales masivos (WAL - Write Ahead Logs) que pueden consumir fácilmente 100-200 GB adicionales en minutos.
Para **garantizar 0 dólares en sobrecargos**, no crearemos 300 GB de datos. Crearemos **75 GB** (Escala 5000). Esto deja 525 GB libres para que los WAL operen sin activar el auto-escalado de Google.

```bash
# Inicialización segura (75 GB de datos)
/usr/pgsql-15/bin/pgbench -i -s 5000 -F 90 -U postgres -h [IP_CLOUD_SQL] db_stress

```

---

### Fase 2: Flujo de Pruebas de Estrés

#### Prueba 1: Saturación de CPU (Solo Lectura)

Mide el límite de procesamiento del motor cuando los datos ya viven en la RAM y en la Caché de 750 GB. El disco no participa.

* **Comando:**
```bash
/usr/pgsql-15/bin/pgbench -c 500 -j 90 -T 300 -S -M prepared -U postgres -h [IP_CLOUD_SQL] db_stress

```
* **Qué observar:** Los TPS deberían ser extremadamente altos (decenas de miles). La latencia debe mantenerse por debajo de 5 ms. Si subes a `-c 1500` y los TPS se estancan, has llegado al límite de tus 16 vCPUs.




#### Prueba 2: Estrés de IOPS y Escritura (TPC-B Standard)

Al tener 128 GB de RAM + 750 GB de Caché, las *lecturas* nunca tocarán el SSD de red de 600 GB. Esta prueba inyecta `UPDATEs` e `INSERTs` forzando a Cloud SQL a escribir en los discos remotos, probando tu límite de 25,000 IOPS y 600 MB/s.

* **Comando:**
```bash
/usr/pgsql-15/bin/pgbench -c 500 -j 90 -T 300 -M prepared -U postgres -h [IP_CLOUD_SQL] db_stress

```
* **Qué observar:** Monitoriza la métrica de IOPS en la consola de Google Cloud. Tu límite físico es de 25,000 IOPS. Si la desviación estándar (`latency stddev`) se dispara por encima del promedio, tus discos están ahogados o el servidor está sufriendo por el proceso de *Checkpointing* o *WAL writing*.



#### Prueba 3: Estrés de Concurrencia y Red (Avalancha)

Evalúa cómo el servidor maneja el agotamiento de memoria por conexión (TCP Handshake) obligando a desconectar/conectar en cada petición.

* **Comando:**
```bash
/usr/pgsql-15/bin/pgbench -c 1500 -j 90 -T 300 -C -M simple -U postgres -h [IP_CLOUD_SQL] db_stress

```

* **Qué observar:** Esto suele destruir el rendimiento (TPS bajos) debido al costo computacional del "TCP Handshake" y la autenticación. Sirve para justificar si necesitas un *Connection Pooler* (como PgBouncer) frente a la base de datos.


---

### Catálogo Maestro de Umbrales (Cómo leer los resultados)

Esta matriz es tu guía forense. Compara los resultados que arroja la terminal de `pgbench` y las gráficas de Google Cloud Platform (GCP) contra estos valores para dictaminar la salud del sistema.

#### 1. Métricas de pgbench (Terminal)

| Métrica | ¿Qué indica? | Nivel Diamante (Óptimo) | Nivel Normal | Nivel Crítico (Cuello de Botella) | Acción si es Crítico |
| --- | --- | --- | --- | --- | --- |
| **TPS (Transacciones por Segundo)** | Volumen de rendimiento puro del servidor. | Escala linealmente al subir clientes (`-c`). | Se estabiliza en un tope. | Cae drásticamente al sumar más clientes. | Llegaste al techo de las 16 vCPUs. Toca escalar hardware o afinar consultas. |
| **Latency average (Lectura)** | Tiempo de respuesta en consultas `SELECT` (Prueba 1). | `< 2 ms` | `2 ms - 10 ms` | `> 20 ms` | Faltan índices o la CPU está al 100%. |
| **Latency average (Escritura)** | Tiempo de respuesta con `UPDATE/INSERT` (Prueba 2). | `< 15 ms` | `15 ms - 50 ms` | `> 100 ms` | El disco de 600 GB de Cloud SQL no da abasto. |
| **Latency stddev (Desviación)** | Estabilidad del sistema. Diferencia entre la petición más rápida y la más lenta. | `stddev` es < 20% del `average`. | `stddev` es < 50% del `average`. | `stddev` > `average` (Picos de lag masivos). | Sistema inestable. Presencia severa de "Row locks" (bloqueos) o discos saturados por Checkpoints. |
| **Failed transactions** | Errores puros. Deadlocks o conexiones rechazadas. | `0` | `0` | `> 0` | Si >0, el parámetro `max_connections` se desbordó o hay interbloqueos en el diseño de las tablas. |

#### 2. Métricas Físicas (Consola de Cloud SQL / GCP)

| Métrica a Monitorear en GCP | Función | Límite Físico del Servidor | Umbral de Alerta Temprana | Diagnóstico si llegas al 100% |
| --- | --- | --- | --- | --- |
| **Uso de CPU** | Procesamiento de consultas y gestión de conexiones. | 16 vCPUs | `> 85%` sostenido. | Las consultas son ineficientes o hay demasiados clientes activos al mismo tiempo. |
| **IOPS de Escritura** | Cantidad de operaciones de entrada/salida por segundo hacia el SSD. | 25,000 IOPS | `> 20,000 IOPS` | El disco es demasiado pequeño para la carga transaccional. (En GCP, aumentar tamaño de disco aumenta IOPS). |
| **Rendimiento (Throughput) de Disco** | Velocidad de transferencia de datos pesados al disco. | 600 MB/s (Escritura) | `> 480 MB/s` | Se está escribiendo demasiada data en bruto. El sistema está perdiendo tiempo volcando WALs al disco. |
| **Throughput de Red** | Ancho de banda entre tu Origen (VM) y el Destino (Cloud SQL). | 2,000 MB/s | `> 1,600 MB/s` | Estás intentando extraer "SELECTs" demasiado pesados (ej. extrayendo tablas enteras en lugar de paginar). |





---

### Fase 4: Evaluación de Límites Físicos (Matriz de Resultados)

Al finalizar cada ronda de las pruebas anteriores, cruza la salida de terminal de `pgbench` con el monitoreo en la consola de GCP.

1. **Rendimiento de Red (Throughput):** Cloud SQL tiene un límite de procesamiento de red de 2,000 MB/s. Si durante las pruebas de Solo Lectura tus gráficas en GCP tocan este techo, la base de datos no puede enviar los datos más rápido, independientemente de la CPU.
2. **Límite de Disco (MB/s):** La escritura está limitada entre 528.0 y 600.0 MB/s. Si en la Prueba 2 (TPC-B) el disco llega a 600 MB/s, tu cuello de botella será el tamaño del disco (en GCP, a mayor disco, mayores IOPS/Throughput).
3. **Deadlocks y Bloqueos:** Si implementas un script customizado (como el de la "Tienda Virtual") y observas un incremento en `failed transactions`, el límite no es el hardware, sino el diseño del esquema (falta de índices o contención por actualización de la misma fila).








 ----
# **límite de conexiones sin colapsar el servicio**

 Para llevar a PostgreSQL a su **límite de conexiones sin colapsar el servicio** y obtener una gráfica clara con el punto de degradación, el volumen máximo sostenible y la reserva operacional de emergencia, la **Prueba 3 (Estrés de Concurrencia y Red)** es la que se debe adaptar.

La versión estática actual con `-c 1500` solo te dará una "fotografía" en ese punto, pero no te dirá **dónde empezó a degradarse la latencia**. Para graficar la curva de saturación real, debemos sustituirla por una **Prueba Escalonada de Conexiones (Step-Load Test)**.
 

### Nueva Prueba 3: Escalabilidad y Límite de Conexiones (Step-Load Test)

En lugar de ejecutar un solo comando `pgbench`, ejecutaremos un bucle en bash que incrementa gradualmente la cantidad de clientes (`-c`). Esto guardará los resultados en un archivo CSV para generar la gráfica que necesitas.

#### 1. Script de Automatización (`escalabilidad_conexiones.sh`)

Crea y ejecuta este script en la máquina cliente (Origen):

```bash
#!/bin/bash
# Script para hallar el punto de degradación y límite de conexiones
HOST="[IP_CLOUD_SQL]"
USER="postgres"
DB="db_stress"
LOG_FILE="limite_conexiones_resultado.csv"

# Encabezado del archivo CSV para graficar
echo "Clientes_Concurrentes,TPS_Sin_Conexion,Latencia_Media_ms,Failed_Transactions" > $LOG_FILE

# Incrementos de conexiones (ej. desde 100 hasta 2000 usuarios)
for clientes in 100 250 500 750 1000 1250 1500 1750 2000; do
    echo "=========================================="
    echo "Probando con $clientes usuarios concurrentes..."
    echo "=========================================="
    
    # -j se ajusta a 90 hilos, -T ejecuta cada escalón por 60 segundos
    OUTPUT=$(/usr/pgsql-15/bin/pgbench -c $clientes -j 90 -T 60 -M prepared -P 10 -U $USER -h $HOST $DB 2>&1)
    
    # Extracción de métricas clave con awk/grep
    TPS=$(echo "$OUTPUT" | grep "tps =" | head -n 1 | awk '{print $3}')
    LAT=$(echo "$OUTPUT" | grep "latency average =" | awk '{print $4}')
    FAIL=$(echo "$OUTPUT" | grep "number of failed transactions:" | awk '{print $5}')
    FAIL=${FAIL:-0} # Si es nulo, poner 0
    
    # Guardar en CSV
    echo "$clientes,$TPS,$LAT,$FAIL" >> $LOG_FILE
    
    # Pausa de enfriamiento entre picos de carga (10 segundos)
    sleep 10
done

echo "Prueba finalizada. Resultados guardados en $LOG_FILE"

```

---

### Interpretación de la Gráfica y Definición de Umbrales

Al procesar los datos de `limite_conexiones_resultado.csv` en Excel, Cloud Monitoring o Grafana, la gráfica revelará tres puntos críticos:

```text
TPS (Rendimiento) / Latencia (ms)
  ^
  |        [Punto A: Techo Sostenible]
  |               / \
  |              /   \____ Latencia se dispara (Punto B: Límite Operativo)
  |  TPS        /     \
  |  Aumenta   /       \____ TPS caen por contención de memoria/locks
  |           /
  +------------------------------------------------------------> Clientes Concurrentes

```

#### Cómo definir tus zonas de capacidad:

1. **Zona Verde (Límite Máximo Sostenible - Punto A):** Es el número de clientes donde los **TPS alcanzan su pico máximo** y la latencia promedio se mantiene por debajo de **15 ms**.
2. **Zona Amarilla (Punto de Degradación - Punto B):** Si pasas de (por ejemplo) 800 a 1,200 clientes y los TPS no aumentan pero la latencia salta de **15 ms a 120 ms**, has alcanzado la degradación. La CPU o los bloques de memoria por conexión (*work_mem*) están saturados.
3. **Zona Roja (Colapso de Conexiones):** Punto donde empiezan a aparecer `Failed transactions > 0` o errores de tipo `FATAL: sorry, too many clients already`.

---

### Configuración del Límite Operativo y Conexiones de Emergencia

Para garantizar la estabilidad operacional y reservar acceso exclusivo para administradores/DBAs durante un pico crítico de tráfico, ajustaremos dos parámetros directos en PostgreSQL dentro de la consola de **Cloud SQL**:

```sql
-- 1. Definir el límite máximo absoluto permitido según tu prueba (Punto A)
-- Ejemplo: Si la degradación inició a los 1,000 usuarios, fija el máximo ahí.
ALTER SYSTEM SET max_connections = '1000';

-- 2. Reservar conexiones exclusivas para el usuario superusuario/admin (Emergencia)
-- Permite que hasta 20 administradores puedan entrar AUNQUE la base de datos esté llena.
ALTER SYSTEM SET reserved_connections = '20';

```

#### Regla de Configuración Operativa

* **Punto de corte en Aplicación (Max Connections):** $980$ conexiones para el pool de usuarios/aplicación.
* **Reserva de Emergencia (`reserved_connections`):** $20$ conexiones para el usuario administrador/DBA.
* **Capacidad Total en Servidor (`max_connections`):** $1000$ conexiones en total.

> **Nota Técnica:** En PostgreSQL 15, `reserved_connections` reemplaza el comportamiento antiguo de reservar slots automáticamente a superusuarios, asegurando que ante una saturación masiva siempre dispongas de esas 20 conexiones limpias para entrar a diagnosticar (`pg_stat_activity`), matar procesos colgados o ajustar parámetros sin que el servidor te rechace la entrada.
