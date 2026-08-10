 

## 📌 ¿Qué es el Cache Hit Ratio en PostgreSQL?

El **Cache Hit Ratio** (o tasa de aciertos de caché) es una métrica clave que mide la frecuencia con la que PostgreSQL encuentra los datos solicitados directamente en la memoria RAM (`shared_buffers`), en lugar de tener que realizar una lectura física en el disco duro.

```
                  ┌─────────────────────────────────┐
                  │   Consulta SQL enviada por el   │
                  │             usuario             │
                  └────────────────┘────────────────┘
                                   │
                                   ▼
                  ┌─────────────────────────────────┐
                  │    ¿Página de datos en RAM?     │
                  │        (shared_buffers)         │
                  └────────┬───────────────┬────────┘
                           │               │
                 Sí (Hit)  │               │ No (Miss)
                           ▼               ▼
            ┌───────────────────┐     ┌───────────────────┐
            │ Respuesta de RAM  │     │  Lectura I/O de   │
            │  (~Instantánea)   │     │  Disco / SO (~ms) │
            └───────────────────┘     └───────────────────┘

```

### Fórmula de Cálculo

$$
\text{Cache Hit Ratio (\%)} = \left( \frac{\text{blks}\_\text{hit}}{\text{blks}\_\text{hit} + \text{blks}\_\text{read}} \right) \times 100
$$

* **`blks_hit`**: Número de bloques/páginas encontrados en la memoria RAM.
* **`blks_read`**: Número de bloques/páginas que tuvieron que leerse del disco.

---

## 🚀 ¿Por qué es una métrica crítica?

* **Diferencia brutal de rendimiento:** La lectura en RAM es entre **100 y 1,000 veces más rápida** que en un SSD/NVMe (y hasta miles de veces más rápida que en un disco mecánico tradicional).
* **Diagnóstico de cuellos de botella:** Una caída drástica suele alertar sobre:
* Un valor insuficiente en la configuración de `shared_buffers`.
* Consultas ineficientes (*Sequential Scans* masivos) que están barragando (expulsando) datos útiles de la memoria para cargar tablas completas.


* **Sistemas OLTP vs. OLAP:**
* **OLTP (Transaccional):** Se busca mantener un objetivo saludable **superior al 99%**.
* **OLAP (Analítico):** Es habitual ver ratios más bajos debido al procesamiento masivo de grandes volúmenes de datos históricos.



---

## 🔍 Consultas para Monitoreo

### 1. A nivel de Base de Datos

Obtiene el porcentaje global de aciertos de la base de datos actual:

```sql
SELECT 
  datname,
  blks_hit,
  blks_read,
  ROUND(blks_hit::numeric / NULLIF(blks_hit + blks_read, 0) * 100, 2) AS cache_hit_ratio
FROM pg_stat_database
WHERE datname = current_database();

```

### 2. A nivel de Tablas

Identifica qué tablas generan más lecturas en disco frente a accesos a caché:

```sql
SELECT 
  relname AS tabla,
  heap_blks_hit AS hits,
  heap_blks_read AS lecturas_disco,
  ROUND(heap_blks_hit::numeric / NULLIF(heap_blks_hit + heap_blks_read, 0) * 100, 2) AS cache_hit_ratio
FROM pg_statio_user_tables
ORDER BY heap_blks_read DESC;

```

### 3. A nivel de Consulta Individual

Analiza el impacto en disco/RAM de un `SELECT` específico activando la opción `BUFFERS`:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM usuarios WHERE email = 'ejemplo@correo.com';

```

**Lectura del resultado:**

```text
Buffers: shared hit=4 read=1

```

* `shared hit=4`: 4 bloques se leyeron directamente desde la RAM.
* `shared read=1`: 1 bloque requirió una lectura física del disco.

---

## 🛠️ Acciones para mejorar un Ratio bajo

| Problema | Solución / Recomendación |
| --- | --- |
| **Memoria dedicada insuficiente** | Ajustar `shared_buffers`. En servidores dedicados, el valor estándar suele configurarse en torno al **25% de la RAM total** (rara vez más del 40-50%). |
| **Escaneos completos de tablas** | Crear y optimizar **índices** para evitar *Sequential Scans* que limpien la memoria sin necesidad. |
| **Uso de disco en ordenamientos** | Incrementar `work_mem` para evitar que operaciones de `ORDER BY`, `GROUP BY` o `DISTINCT` se escriban en archivos temporales del disco. |


---

## 🚦 Los Estados del Cache Hit Ratio

El impacto del porcentaje depende de la **naturaleza de tu sistema**:

* **OLTP (Transaccional):** Aplicaciones web, APIs, tiendas en línea. Muchas lecturas/escrituras rápidas de pocos registros.
* **OLAP (Analítico / BI):** Reportes, Data Warehouses. Consultas pesadas sobre millones de filas.

### 📊 Tabla de Evaluación por Estado

| Estado | OLTP (Aplicaciones Web) | OLAP (Analítica / Reportes) | Diagnóstico |
| --- | --- | --- | --- |
| 🟢 **Excelente / Óptimo** | **> 99%** | **> 90%** | La RAM cubre casi la totalidad del tráfico. Respuestas ultrarrápidas. |
| 🟡 **Aceptable / Precaución** | **95% – 98.9%** | **75% – 89.9%** | El sistema funciona bien, pero está al límite. Puede haber ralentizaciones esporádicas. |
| 🔴 **Crítico / Alerta** | **< 95%** | **< 75%** | Cuello de botella severo. El disco duro está estrangulando el rendimiento. |

---

## 🎯 ¿Qué significan estos datos en la práctica?

### 🟢 Estado Óptimo (> 99% en OLTP)

* **Significado:** Más de 99 de cada 100 bloques de datos solicitados se entregan directamente desde la RAM.
* **Sensación del usuario:** Las consultas tardan milisegundos o microsegundos.
* **Acción requerida:** Ninguna. Mantener el monitoreo.

### 🟡 Estado de Precaución (95% - 98%)

* **Significado:** Tu sistema empieza a apoyarse en el disco de forma recurrente. Un 95% significa que **1 de cada 20 lecturas va a disco**.
* **Causa común:** Crecimiento natural de los datos o consultas no optimizadas que entran a producción.
* **Acción requerida:** Revisar índices faltantes o considerar aumentar ligeramente la memoria `shared_buffers`.

### 🔴 Estado Crítico (< 95%)

* **Significado:** Estás sufriendo I/O de disco constante. Si cae por debajo del 90%, el sistema responderá notablemente lento.
* **Causa común:**
1. Un *Sequential Scan* (escaneo completo) de una tabla gigante expulsó toda la caché útil.
2. La memoria RAM asignada a PostgreSQL (`shared_buffers`) es ridículamente pequeña para el tamaño actual de tu base de datos.


* **Acción requerida:** Diagnóstico de emergencia (ver sección de escenarios).

---

## 💡 Los 3 Mitos que te pueden confundir al leer los datos

Para no interpretar mal los números, ten en cuenta estas 3 trampas comunes:

### 1. "Mi base de datos acaba de reiniciar y el ratio está en 20%"

* **No te asustes:** Cuando PostgreSQL se reinicia, la RAM está **vacía**. Necesita un tiempo de *Warm-up* (calentamiento) para ir cargando los datos más usados. Evalúa el ratio únicamente después de unas horas de tráfico normal.

### 2. "Tengo 99% de Cache Hit, pero mis consultas siguen lentas"

* **Ojo con las tablas pequeñas:** Si tienes una consulta que lee un millón de filas directamente de la RAM porque la tabla cabe completa en memoria, tu Cache Hit será del **100%**, pero la CPU trabajará a tope procesando ese millón de filas. El Cache Hit mide **I/O de disco**, no eficiencia del código SQL.

### 3. "PostgreSQL dice que lee de disco (`blks_read`), pero el servidor va rápido"

* PostgreSQL reporta como `blks_read` cualquier bloque que **él** no tenía en su propia memoria (`shared_buffers`). Sin embargo, el **sistema operativo (Linux)** tiene su propia caché en RAM. Muchas veces `blks_read` lee de la RAM del SO y no del disco físico real. Aun así, sigue siendo más lento que el `shared_buffer` nativo.

---

## 🛠️ Guía Rápida de Diagnóstico: ¿Qué hacer si está mal?

Si al ejecutar tu consulta ves que estás en **Estado Crítico**, sigue estos tres pasos en orden:

```
                  ┌─────────────────────────────────┐
                  │      Ratio en Estado Crítico    │
                  └────────────────┬────────────────┘
                                   │
                                   ▼
                  ┌─────────────────────────────────┐
                  │    1. Revisa tablas específicas │
                  │       (pg_statio_user_tables)   │
                  └────────────────┬────────────────┘
                                   │
                                   ▼
             ┌─────────────────────┴─────────────────────┐
             │                                           │
             ▼                                           ▼
┌───────────────────────────┐               ┌───────────────────────────┐
│ Una tabla tiene miles de  │               │ Muchas tablas sufren      │
│ lecturas en disco         │               │ lecturas en disco         │
└────────────┬──────────────┘               └────────────┬──────────────┘
             │                                           │
             ▼                                           ▼
┌───────────────────────────┐               ┌───────────────────────────┐
│ Solución:                 │               │ Solución:                 │
│ Falta un ÍNDICE en esa    │               │ Aumentar `shared_buffers` │
│ tabla.                    │               │ (RAM del servidor).       │
└───────────────────────────┘               └───────────────────────────┘

```

1. **Si es una tabla aislada:** Es un problema de **indexación**. Hay un `SELECT` haciendo escaneos masivos que "barren" la caché.
2. **Si son todas las tablas:** Es un problema de **hardware/configuración**. Le falta memoria a PostgreSQL para el tamaño global de tus datos activos.
