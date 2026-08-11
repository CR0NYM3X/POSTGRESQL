 
# Guía Práctica de Optimización en PostgreSQL: Bloat y Fragmentación



## 1. Métricas e Índices de Decisión

Para tomar la decisión con datos medibles, nos enfocamos en dos métricas clave:

* **% de Bloat:** Qué porcentaje del espacio físico actual son datos "muertos" o páginas vacías.
* **Espacio Desperdiciado en GB/MB:** El tamaño real retenido por el motor que podría liberarse al sistema operativo.

### Criterios Medibles

| Métrica | Acción Recomendada | Razón Técnica |
| --- | --- | --- |
| **Tabla < 20% Bloat** | VACUUM normal / Ninguna | El motor maneja bien este nivel de fragmentación. Reescribir no justifica el uso de I/O. |
| **Índice > 30% Bloat** *(Tabla limpia)* | `REINDEX CONCURRENTLY` | CRÍTICO si el índice supera los 5–10 GB. Las lecturas en disco (buffer hits) se disparan innecesariamente. Se arregla en caliente. |
| **Tabla > 40-50% Bloat** *(Y > 10 GB desperdiciados)* | `pg_repack` (Producción) o `VACUUM FULL` (Ventana) | CRÍTICO. Estás pagando por almacenamiento innecesario y escaneos de tabla (Seq Scan) extremadamente lentos. |

---

## 2. Consultas para Medir la Fragmentación

Para obtener estos números en PostgreSQL, puedes consultar las vistas de estadísticas del sistema o utilizar la extensión oficial `pgstattuple` (incluida en PostgreSQL contrib) que lee los bloques directamente.

### Método preciso: Extensión `pgstattuple`

```sql
-- Activar la extensión (solo una vez)
CREATE EXTENSION IF NOT EXISTS pgstattuple;

-- 1. Medir bloat de la TABLA
SELECT 
    table_len AS tamaño_total_bytes,
    pg_size_pretty(table_len) AS tamaño_total,
    dead_tuple_len AS bytes_muertos,
    pg_size_pretty(dead_tuple_len) AS espacio_desperdiciado,
    round(free_percent, 2) AS pct_espacio_libre_bloat
FROM pgstattuple('nombre_de_tu_tabla');

-- 2. Medir bloat del ÍNDICE
SELECT 
    binary_upgrade_satisfy_undo AS _dummy, -- Ignorar
    index_size AS tamaño_indice_bytes,
    pg_size_pretty(index_size) AS tamaño_indice,
    pg_size_pretty(leaf_fragmentation) AS fragmentacion,
    round((100.0 * (1.0 - (leaf_density / 100.0)))::numeric, 2) AS pct_bloat_estimado
FROM pgstatindex('nombre_de_tu_indice');

```

---

## 3. Laboratorio Real Paso a Paso

Ejecuta este laboratorio en una base de datos de pruebas para simular ambos escenarios y ver las métricas en acción.

### Paso A: Preparar el escenario

```sql
CREATE EXTENSION IF NOT EXISTS pgstattuple;

-- Crear tabla de prueba
CREATE TABLE laboratorio_pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INT,
    estado TEXT,
    fecha TIMESTAMP DEFAULT clock_timestamp()
);

-- Crear índices
CREATE INDEX idx_pedidos_cliente ON laboratorio_pedidos(cliente_id);
CREATE INDEX idx_pedidos_estado ON laboratorio_pedidos(estado);

-- Insertar 1,000,000 de registros
INSERT INTO laboratorio_pedidos (cliente_id, estado)
SELECT 
    (random() * 50000)::int,
    CASE WHEN random() < 0.8 THEN 'COMPLETADO' ELSE 'PENDIENTE' END
FROM generate_series(1, 1000000);

```

---

### ESCENARIO 1: Solo el ÍNDICE está crítico → Usar `REINDEX`

Simulamos un patrón de alta actualización (`UPDATE`) en la columna indexada `estado`:

```sql
-- Forzamos actualización constante del estado
UPDATE laboratorio_pedidos SET estado = 'PROCESANDO' WHERE estado = 'PENDIENTE';
UPDATE laboratorio_pedidos SET estado = 'FINALIZADO' WHERE estado = 'PROCESANDO';

-- Corremos VACUUM normal (limpia los túbulos muertos de la TABLA, pero deja el ÍNDICE inflado)
VACUUM laboratorio_pedidos;

```

#### Medición tras la operación:

```sql
-- Revisar la TABLA
SELECT pg_size_pretty(table_len) AS tamaño_tabla, round(free_percent, 2) AS pct_bloat 
FROM pgstattuple('laboratorio_pedidos');
-- Resultado típico: Tamaño Tabla = 65 MB | Bloat = 2.1% (TABLA SANA)

-- Revisar el ÍNDICE de 'estado'
SELECT pg_size_pretty(index_size) AS tamaño_indice, 
       round((100.0 * (1.0 - (leaf_density / 100.0)))::numeric, 2) AS pct_bloat
FROM pgstatindex('idx_pedidos_estado');
-- Resultado típico: Tamaño Índice = 48 MB | Bloat = 68.5% (ÍNDICE CRÍTICO)

```

#### Diagnóstico con números:

* **Tabla:** 65 MB (Bloat 2.1%) $\rightarrow$ La tabla está compacta.
* **Índice:** 48 MB (Bloat 68.5%) $\rightarrow$ El índice mide casi igual que la tabla debido al reordenamiento constante.

#### Solución:

```sql
-- NO hagas VACUUM FULL (bloquearía la tabla innecesariamente).
-- Haz solo REINDEX:
REINDEX INDEX CONCURRENTLY idx_pedidos_estado;

```

---

### ESCENARIO 2: La TABLA entera está crítica → Usar `VACUUM FULL` / `pg_repack`

Simulamos la eliminación masiva de datos antiguos (`DELETE` del 70% de la tabla):

```sql
-- Borramos 700,000 filas
DELETE FROM laboratorio_pedidos WHERE id <= 700000;

-- Corremos un VACUUM estándar para marcar las páginas como reutilizables
VACUUM laboratorio_pedidos;

```

#### Medición tras la operación:

```sql
-- Revisar la TABLA
SELECT 
    pg_size_pretty(table_len) AS tamaño_tabla, 
    pg_size_pretty(dead_tuple_len) AS desperdiciado,
    round(free_percent, 2) AS pct_bloat 
FROM pgstattuple('laboratorio_pedidos');
-- Resultado típico: Tamaño Tabla = 65 MB | Desperdiciado = 45 MB | Bloat = 69.2% (CRÍTICO)

-- Revisar los ÍNDICES
SELECT pg_size_pretty(index_size) AS tamaño_indice
FROM pgstatindex('idx_pedidos_cliente');
-- Resultado típico: Tamaño Índice = 28 MB

```

#### Diagnóstico con números:

* La tabla físicamente sigue midiendo 65 MB, aunque solo contiene 300,000 filas (debería medir ~19 MB).
* El 69.2% de la tabla es espacio desperdiciado en disco.
* `AUTOVACUUM` o `VACUUM` normal no le devolverán esos 45 MB al sistema operativo.

#### Solución:

```sql
-- Si tienes una ventana de mantenimiento (bloquea la tabla por completo):
VACUUM FULL laboratorio_pedidos;

```

```bash
-- Si estás en PRODUCCIÓN y no puedes permitirte downtime:
-- (Requiere instalar el paquete pg_repack en el SO)
$ pg_repack -h localhost -d tu_base_datos -t laboratorio_pedidos

```

Al finalizar el `VACUUM FULL`, la tabla bajará automáticamente de 65 MB a 19 MB, e internamente habrá recreado todos sus índices sin requerir pasos adicionales.

---

---

# Umbrales Cuantitativos e Inspección de Motor

Para determinar el estado de tu base de datos con precisión, los DBA utilizan tres zonas de decisión basadas en dos factores principales: el porcentaje de fragmentación (Bloat %) y el tamaño absoluto del espacio desperdiciado en disco.

A continuación tienes la tabla de umbrales cuantitativos y la explicación técnica de lo que se valida internamente en el motor.

## 1. Umbrales Medibles: Tabla vs. Índice

### TABLA (Espacio Muerto / Páginas Vacías)

| Estado | % de Bloat | Espacio Desperdiciado | Acción Técnica Recomendada | Impacto en Producción |
| --- | --- | --- | --- | --- |
| **Normal** | 0% - 20% | Indiferente | Ninguna. Dejar trabajar al AUTOVACUUM normal. | Mínimo. Comportamiento esperado por el fillfactor. |
| **Acción** | 20% - 40% | > 5 GB | Ajustar parámetros de AUTOVACUUM a nivel de tabla (hacerlo más agresivo). | Degradación leve en Sequential Scans. |
| **Crítico** | > 40% - 50% | > 10 GB - 20 GB | `pg_repack` (en caliente) o `VACUUM FULL` (ventana de mantenimiento). | Alto. Lecturas de disco infladas, costo I/O masivo, desperdicio de almacenamiento. |

### ÍNDICE (Desalineación B-Tree / Páginas Fragmentadas)

| Estado | % de Bloat | Espacio Desperdiciado | Acción Técnica Recomendada | Impacto en Producción |
| --- | --- | --- | --- | --- |
| **Normal** | 0% - 25% | Indiferente | Ninguna. Las estructuras B-Tree reservan espacio para inserciones futuras. | Óptimo. |
| **Acción** | 25% - 45% | > 2 GB | Monitorear frecuencia de UPDATE/DELETE en las columnas indexadas. | El índice ocupa más RAM Shared Buffers de los necesarios. |
| **Crítico** | > 45% - 50% | > 5 GB | `REINDEX INDEX CONCURRENTLY <nombre>` | Muy Alto. Búsquedas lentas, el planificador (Query Planner) puede ignorar el índice y cambiar a Seq Scan. |

> **Nota sobre la escala:** La regla del tamaño absoluto es clave. Un bloat del 80% en una tabla de 10 MB (desperdicio de 8 MB) es irrelevante y no requiere acción. Un bloat del 35% en una tabla de 1 Terabyte (desperdicio de 350 GB) es crítico.

---

## 2. ¿Qué es lo que realmente se valida e inspecciona?

Cuando ejecutas las funciones de inspección (`pgstattuple` y `pgstatindex`), estás auditando la estructura física a nivel de bloques/páginas en el disco (páginas de 8 KB por defecto en PostgreSQL).

### A. Lo que se valida en la TABLA (`pgstattuple`)

* **`live_tuple_len` vs `dead_tuple_len` (Túbulos vivos vs. muertos):**
* **Túbulo vivo:** Registro actual y accesible por transacciones activas.
* **Túbulo muerto:** Versión antigua de una fila eliminada con `DELETE` o modificada con `UPDATE` que ya no es visible para ninguna transacción.


* **`free_space` / `free_percent` (Espacio libre internamente):**
* Mide cuánto espacio dentro de los bloques de 8 KB está vacío pero retenido por el archivo de la tabla (`relfilenode`).


* **¿Por qué se degrada?**
* Las lecturas completas de tabla (Sequential Scans) deben leer todos los bloques del disco, incluidos los que solo contienen espacio muerto. Si tu tabla tiene 50% de bloat, el disco trabaja el doble para leer la misma cantidad de información.



### B. Lo que se valida en el ÍNDICE B-Tree (`pgstatindex`)

* **`leaf_density` (Densidad de hojas):**
* Indica qué tan llenas están las páginas hoja del árbol B-Tree. Un índice recién creado tiene una densidad cercana al 90%-95%. Con el tiempo y las modificaciones, la densidad cae por debajo del 50%.


* **`leaf_fragmentation` (Fragmentación del árbol):**
* Porcentaje de páginas del índice cuyas claves adyacentes no están en páginas contiguas del disco, obligando a lecturas aleatorias (random I/O).


* **`tree_height` (Altura del árbol B-Tree):**
* Si la altura del árbol pasa de 3 a 4 o 5 niveles debido al hinchazón, cada consulta que use ese índice requerirá más lecturas de bloques para encontrar la clave.


* **¿Por qué se degrada?**
* Cuando se borra una fila de la tabla, el puntero en el índice no se elimina inmediatamente; queda marcado. Además, si el índice no está balanceado, la memoria caché (RAM) de PostgreSQL se llena de páginas de índices semivacías.



---

## 3. Resumen Ejecutivo de Regla de Decisión

```text
                                  [¿CUÁL ES EL PROBLEMA?]
                                             |
            +--------------------------------+--------------------------------+
            |                                                                 |
   [Bloat en la TABLA]                                               [Bloat en el ÍNDICE]
            |                                                                 |
  ¿Es > 40% Y desperdicia                                           ¿Es > 45% Y desperdicia
        > 10 GB?                                                          > 5 GB?
       /        \                                                        /        \
     SÍ          NO                                                    SÍ          NO
    /              \                                                  /              \
¿Puedes programar   Ajustar AUTOVACUUM                       REINDEX CONCURRENTLY   Dejar trabajar
   downtime?        a nivel de tabla                          al índice afectado    al AUTOVACUUM
    /      \                                                 (en caliente, 0 downtime) (no requiere acción)
  SÍ        NO
  /          \
VACUUM FULL  pg_repack
(Bloqueo total) (En caliente)

```

---

---

# Conceptos Técnicos: Bloat vs. Fragmentación

Es totalmente comprensible la confusión. Los términos Bloat (Hinchazón/Espacio Muerto) y Fragmentación a menudo se usan como sinónimos en el lenguaje cotidiano de bases de datos, pero en PostgreSQL no son exactamente lo mismo, y además afectan de forma distinta a la Tabla vs. los Índices.

Aquí tienes el desglose claro de cada concepto y cómo aplica en cada caso:

## 1. BLOAT (Espacio Muerto / Hinchazón)

El Bloat es aire o basura. Es espacio físico que tu archivo en disco está ocupando, pero que no contiene datos útiles en este momento.

* **En la TABLA:**
* **Qué es:** Son filas (*tuples*) "muertas". Cuando haces un `UPDATE` o `DELETE`, PostgreSQL no borra la fila en el disco inmediatamente por temas de concurrencia. La marca como "muerta".
* **El problema:** Tu tabla física mide 100 GB, pero solo 40 GB son datos vivos. Tienes 60 GB de Bloat. Las lecturas secuenciales tienen que leer los 100 GB completos.


* **En el ÍNDICE:**
* **Qué es:** Punteros hacia filas muertas que ya no existen, o entradas marcadas como eliminadas dentro del árbol B-Tree.
* **El problema:** El índice pesa 20 GB cuando debería pesar 4 GB, ocupando memoria RAM de la caché (Shared Buffers) inútilmente.



---

## 2. FRAGMENTACIÓN

La Fragmentación no es espacio vacío, sino desorden en la estructura física.

* **En la TABLA:**
* Prácticamente no es un factor crítico en PostgreSQL moderno a nivel de filas, porque la tabla es una estructura tipo Heap (un saco de datos sin orden particular).


* **En el ÍNDICE (Aquí es donde sí importa):**
* **Qué es:** Los índices B-Tree organizan las claves de forma lógica (ej. de la A a la Z) en páginas de 8 KB. Con las inserciones y borrados, las páginas se dividen (*page splits*).
* **El problema:** La página que tiene la letra "B" termina en el bloque 5 del disco, y la página que tiene la letra "C" termina en el bloque 9,000. Aunque no haya tanto espacio muerto (bloat), el índice está desordenado, obligando al disco a hacer saltos aleatorios (Random I/O) muy lentos en lugar de lecturas continuas.



---

## Cuadro comparativo: Tabla vs. Índice

| Concepto | En la TABLA (Heap) | En el ÍNDICE (B-Tree) |
| --- | --- | --- |
| **¿Qué es el BLOAT?** | Filas viejas/muertas tras un `UPDATE` o `DELETE` que no se han limpiado. | Páginas del índice que quedaron medio vacías o con referencias obsoletas. |
| **¿Qué es la FRAGMENTACIÓN?** | No afecta tanto (PostgreSQL escribe filas donde encuentra espacio disponible). | Hojas del árbol B-Tree desordenadas en disco que rompen la lectura secuencial. |
| **¿Cómo afecta el rendimiento?** | Vuelve lentas las búsquedas completas de tabla (Seq Scan). | Vuelve lentas las búsquedas por índice (Index Scan) y gasta memoria RAM extra. |
| **¿Cómo se soluciona?** | `VACUUM FULL` (bloquea) o `pg_repack` (en caliente). | `REINDEX CONCURRENTLY` (en caliente) o `VACUUM FULL`. |

---

## En resumen

* **Cuando hablo de BLOAT en la TABLA:** Me refiero a que la tabla física es gigante porque está llena de registros borrados que `VACUUM` normal no ha podido devolverle al sistema operativo.
* **Cuando hablo de BLOAT / FRAGMENTACIÓN en el ÍNDICE:** Me refiero a que el árbol B-Tree se volvió ineficiente, desordenado o enorme, haciendo que las búsquedas específicas se alienten.

Es por esto que puedes tener una **TABLA impecable** (sin bloat) porque el `AUTOVACUUM` limpia las filas muertas a tiempo, pero tener un **ÍNDICE inflado/fragmentado** (con bloat) porque la estructura en árbol quedó desequilibrada tras miles de actualizaciones. En ese escenario exacto es cuando solo usas `REINDEX`.
