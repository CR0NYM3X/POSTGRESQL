 
### ¿Qué es TimescaleDB?

TimescaleDB es una extensión de PostgreSQL diseñada para manejar datos de series temporales. Esto significa que puedes aprovechar todas las capacidades de PostgreSQL junto con funcionalidades avanzadas específicas para datos temporales.

### Series Temporales

Cuando hablamos de series temporales, nos referimos a datos que se registran en intervalos de tiempo específicos. Estos datos suelen incluir una marca temporal y pueden ser utilizados para analizar tendencias a lo largo del tiempo. Ejemplos comunes de series temporales incluyen:

- **Datos de sensores**: Temperatura, humedad, presión, etc., registrados en intervalos regulares.
- **Logs de aplicaciones**: Eventos y errores registrados con marcas temporales.
- **Datos financieros**: Precios de acciones, volúmenes de transacciones, etc., registrados minuto a minuto.
- **Métricas de rendimiento**: Uso de CPU, memoria, tráfico de red, etc., monitoreados continuamente.
- **Monitoreo de sistemas**: Analizar métricas de rendimiento en intervalos de segundos o minutos.
- **IoT**: Registrar y analizar datos de sensores en intervalos de segundos, minutos o días.
 

### ¿Por qué es tan poderoso?

TimescaleDB tiene varias características clave que lo hacen destacar:

1. **Hypertables**: Estas son tablas que se particionan automáticamente en función del tiempo o de una clave arbitraria. Esto optimiza el almacenamiento y la recuperación de datos de series temporales, permitiendo manejar grandes volúmenes de datos de manera eficiente.

2. **Consultas SQL completas**: Puedes usar consultas SQL estándar para analizar datos de series temporales, combinando la facilidad de uso de los DBMS relacionales con la escalabilidad de los sistemas NoSQL.

3. **Agregaciones continuas**: Permite crear vistas materializadas que se actualizan continuamente, facilitando el cálculo de agregaciones en tiempo real.

4. **Compresión de datos**: Ofrece compresión avanzada para reducir el almacenamiento de datos históricos sin perder eficiencia en las consultas.

5. **Políticas de retención**: Puedes configurar políticas para eliminar automáticamente datos antiguos, ayudando a gestionar el almacenamiento de manera eficiente.

### El secreto de TimescaleDB

El verdadero secreto de TimescaleDB radica en su capacidad para combinar la robustez y familiaridad de PostgreSQL con optimizaciones específicas para datos de series temporales. Esto incluye:

- **Partición automática**: Los datos se distribuyen automáticamente entre las tablas particionadas, mejorando el rendimiento de las consultas.
- **Índices optimizados**: Utiliza índices almacenados en RAM para acelerar la inserción y consulta de datos.
- **Escalabilidad**: Puede manejar grandes volúmenes de datos de manera eficiente, ideal para aplicaciones como monitoreo de sistemas, plataformas de negociación y recopilación de métricas de sensores.

--- 

## 📘 1. Índice

1.  Objetivo
2.  Requisitos
3.  Ventajas y Desventajas
4.  Casos de Uso
5.  Simulación de Problema Empresarial
6.  Estructura Semántica
7.  Visualizaciones
8.  Procedimientos Técnicos Avanzados
    *   Configuración inicial (`shared_preload_libraries`)
    *   Creación correcta de hypertable
    *   Continuous Aggregates
    *   Políticas de compresión
    *   Retención de datos
    *   Monitoreo con `timescaledb_information`
    *   Indexación avanzada
    *   Reordenamiento de chunks
    *   Multinode TimescaleDB (introducción)
9.  Sección Final
10. Bibliografía

***

## 🎯 2. Objetivo

Implementar y dominar funcionalidades avanzadas de TimescaleDB para optimizar el rendimiento, almacenamiento y análisis de grandes volúmenes de datos temporales en PostgreSQL.

***

## ⚙️ 3. Requisitos

*   PostgreSQL 12+
*   TimescaleDB instalado
*   Acceso a consola con privilegios de superusuario
*   Editor de configuración (`vim`, `nano`, etc.)
*   Conocimientos básicos de SQL y administración de PostgreSQL

***

## ✅ 4. Ventajas y ❌ Desventajas

**Ventajas:**

*   Compresión automática de datos históricos
*   Agregación continua sin necesidad de recalcular
*   Políticas automatizadas de mantenimiento
*   Monitoreo interno de chunks y hypertables
*   Compatible con SQL estándar

**Desventajas:**

*   Algunas funciones avanzadas requieren versión Enterprise
*   Continuous Aggregates no actualizan datos en tiempo real
*   Requiere configuración adicional (`shared_preload_libraries`)

***

## 🧪 5. Simulación de Problema Empresarial

**Empresa:** *ClimaSat MX*\
**Problema:** Reciben 100,000 registros por hora de sensores climáticos. Necesitan mantener datos recientes sin perder rendimiento y generar reportes agregados por hora y día.\
**Solución:** Usar compresión, agregados continuos y políticas de retención con TimescaleDB.

***

## 🧠 6. Estructura Semántica

*   **Hypertables**: Tablas particionadas por tiempo
*   **Chunks**: Segmentos internos por rango temporal
*   **Continuous Aggregates**: Vistas que se actualizan automáticamente
*   **Policies**: Reglas programadas para compresión y retención
*   **timescaledb\_information**: Esquema interno para monitoreo
*   **Reorder Policies**: Reorganización de chunks para optimizar lectura

***

## 📊 7. Visualización de Arquitectura



***

## 🛠️ 8. Procedimientos Técnicos Avanzados

### 🔧 8.1 Configuración inicial (`shared_preload_libraries`)

```bash
# Editar archivo de configuración
sudo nano /etc/postgresql/14/main/postgresql.conf

# Buscar y modificar línea:
shared_preload_libraries = 'timescaledb'

# Guardar y salir

# Reiniciar servicio
sudo systemctl restart postgresql
```

#### Simulación de salida esperada:

```text
Restart successful
```

***

### 🧱 8.2 Creación correcta de hypertable

```sql
-- Crear tabla con clave primaria compuesta
CREATE TABLE sensores (
    dispositivo_id INT,
    temperatura FLOAT,
    humedad FLOAT,
    timestamp TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (dispositivo_id, timestamp)
);

-- Activar extensión
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Convertir a hypertable
SELECT create_hypertable('sensores', 'timestamp');
```

#### Simulación de salida esperada:

```text
create_hypertable
-------------------
(1 row)
```

***

### 🔁 8.3 Continuous Aggregates

```sql
-- Crear vista agregada por hora
CREATE MATERIALIZED VIEW sensores_por_hora
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', timestamp) AS hora,
    dispositivo_id,
    avg(temperatura) AS temp_promedio,
    avg(humedad) AS humedad_promedio
FROM sensores
GROUP BY hora, dispositivo_id;
```

***

### 🧼 8.4 Compresión automática

```sql
-- Activar compresión
ALTER TABLE sensores SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'dispositivo_id'
);

-- Crear política de compresión para datos mayores a 7 días
SELECT add_compression_policy('sensores', INTERVAL '7 days');
```

***

### 🧹 8.5 Retención de datos

```sql
-- Eliminar datos mayores a 30 días automáticamente
SELECT add_retention_policy('sensores', INTERVAL '30 days');
```

***

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

***

### 🌐 8.9 Introducción a Multinode TimescaleDB

```text
Multinode permite distribuir hypertables entre múltiples nodos PostgreSQL.
Ideal para entornos con millones de registros por segundo.

Requiere configuración de nodos "access node" y "data nodes".
```

***

## 🔚 9. Sección Final

### ✅ Consideraciones

*   `shared_preload_libraries` es obligatorio para que TimescaleDB funcione correctamente
*   Las políticas se ejecutan por background workers
*   Continuous Aggregates no muestran datos recientes hasta que se refrescan

### 📝 Notas

*   Puedes refrescar vistas manualmente con `REFRESH MATERIALIZED VIEW`
*   Las políticas se pueden eliminar con `remove_compression_policy`

### 💡 Consejos

*   Usa `EXPLAIN ANALYZE` para medir rendimiento
*   Aplica compresión solo a datos que no cambian

### 🧪 Buenas Prácticas

*   Indexa por columnas de filtro frecuentes
*   Usa `time_bucket()` en dashboards

### 🔄 Otros Tipos

*   Puedes usar `data retention` para eliminar datos antiguos automáticamente
*   `Reorder policies` para optimizar chunks

### 📊 Tabla Comparativa

| Función                  | PostgreSQL | TimescaleDB |
| ------------------------ | ---------- | ----------- |
| Compresión automática    | ❌          | ✅           |
| Agregados continuos      | ❌          | ✅           |
| Retención programada     | ❌          | ✅           |
| Monitoreo interno        | ❌          | ✅           |
| Reordenamiento de chunks | ❌          | ✅           |

***

## 📚 10. Bibliografía

*   <https://docs.timescale.com/>
*   <https://www.postgresql.org/docs/>
*   <https://github.com/timescale>


# Bibliografias 
```
https://github.com/timescale/timescaledb
https://www.timescale.com/

# Free
TimeScaleDB — An introduction to time-series databases -> https://medium.com/dataengineering-and-algorithms/timescaledb-an-introduction-to-time-series-databases-3438d275e88e
Step-by-step process of how to install TimescaleDB with PostgreSQL on AWS Ubuntu EC2 -> https://medium.com/@mudasirhaji/step-by-step-process-of-how-to-install-timescaledb-with-postgresql-on-aws-ubuntu-ec2-ddc939dd819c
TimescaleDB: The Essential Guide Start With Time-Series Data -> https://medium.com/@pratiyush1/timescaledb-the-essential-guide-start-with-time-series-data-ce6423ff70c3
Handling Billions of Rows in PostgreSQL -> https://medium.com/timescale/handling-billions-of-rows-in-postgresql-80d3bd24dabb
TimescaleDB vs. Postgres for time-series: 20x higher inserts, 2000x faster deletes, 1.2x-14,000x faster queries -> https://medium.com/timescale/timescaledb-vs-6a696248104e
Continuous Aggregates & Policies with TimescaleDB in PostgreSQL ->  https://medium.com/@anowerhossain97/continuous-aggregates-policies-with-timescaledb-in-postgresql-0ad375a73abd
How I Save System Stat Data in PostgreSQL Using TimescaleDB  -> https://levelup.gitconnected.com/how-i-save-system-stat-data-in-postgresql-using-timescaledb-64e09d54eb1c

# Payment
https://ozwizard.medium.com/managing-time-series-data-using-timescaledb-on-postgres-3752654252d0
Time-Series Data with TimescaleDB and PostgreSQL -> https://medium.com/@tihomir.manushev/time-series-data-with-timescaledb-and-postgresql-3ac9127db90c
```
