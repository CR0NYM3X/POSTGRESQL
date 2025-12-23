La extensión `pgstattuple` en PostgreSQL proporciona varias funciones útiles para obtener estadísticas a nivel de tupla (fila) y página, lo que puede ayudarte a evaluar la fragmentación y el uso del espacio en tus tablas e índices. Aquí te explico las principales funciones que puedes utilizar con `pgstattuple`:

### 1. `pgstattuple(regclass)`

Esta función devuelve estadísticas detalladas sobre una tabla específica. Incluye información sobre la longitud física de la tabla, el número de tuplas vivas y muertas, el espacio libre, y más. Aquí tienes un ejemplo de cómo usarla:

```sql
SELECT * FROM pgstattuple('nombre_de_tu_tabla');
```

#### Columnas de Salida:
- **table_len**: Longitud total de la tabla en bytes.
- **tuple_count**: Número de tuplas vivas.
- **tuple_len**: Longitud total de las tuplas vivas en bytes.
- **tuple_percent**: Porcentaje de tuplas vivas.
- **dead_tuple_count**: Número de tuplas muertas.
- **dead_tuple_len**: Longitud total de las tuplas muertas en bytes.
- **dead_tuple_percent**: Porcentaje de tuplas muertas.
- **free_space**: Espacio libre total en bytes.
- **free_percent**: Porcentaje de espacio libre⁴.

### 2. `pgstattuple_approx(regclass)`

Esta función proporciona una versión aproximada de las estadísticas, evitando un escaneo completo de la tabla. Es útil para obtener una visión rápida sin el costo de rendimiento de un escaneo completo.

```sql
SELECT * FROM pgstattuple_approx('nombre_de_tu_tabla');
```

### 3. `pgstatindex(regclass)`

Esta función devuelve estadísticas sobre un índice específico, incluyendo la altura del árbol B, el número de páginas, el número de tuplas, y más. Es útil para evaluar la eficiencia de los índices.

```sql
SELECT * FROM pgstatindex('nombre_de_tu_indice');
```

#### Columnas de Salida:
- **version**: Versión del índice.
- **tree_level**: Nivel del árbol B.
- **index_size**: Tamaño del índice en bytes.
- **root_block_no**: Número de bloque raíz.
- **internal_pages**: Número de páginas internas.
- **leaf_pages**: Número de páginas hoja.
- **empty_pages**: Número de páginas vacías.
- **deleted_pages**: Número de páginas eliminadas.
- **avg_leaf_density**: Densidad promedio de las páginas hoja.
- **leaf_fragmentation**: Fragmentación de las páginas hoja⁵.

### Ejemplo Completo

Aquí tienes un ejemplo completo de cómo usar estas funciones:

```sql
-- Instalar la extensión
CREATE EXTENSION IF NOT EXISTS pgstattuple;

-- Obtener estadísticas detalladas de una tabla
SELECT * FROM pgstattuple('ventas');

-- Obtener estadísticas aproximadas de una tabla
SELECT * FROM pgstattuple_approx('ventas');

-- Obtener estadísticas de un índice
SELECT * FROM pgstatindex('idx_ventas_cliente');
```

### Uso Práctico

Estas funciones son especialmente útiles para:
- **Identificar tablas e índices fragmentados**: Puedes determinar si es necesario realizar un `VACUUM` o `REINDEX`.
- **Optimizar el rendimiento**: Al entender cómo se utilizan las páginas y las tuplas, puedes tomar decisiones informadas sobre la optimización de tu base de datos.
- **Monitorear el uso del espacio**: Mantener un control sobre el espacio libre y las tuplas muertas puede ayudarte a gestionar mejor los recursos de almacenamiento.


---



##   Interpretación rápida y acciones

*   **Tablas:**
    *   `pct_bloat` alto → considera `VACUUM` (o `VACUUM FULL` si el espacio es crítico; ojo bloqueo).
    *   Bloat recurrente por muchos `UPDATE` → reduce `FILLFACTOR` (p.ej. 90–95) para dar espacio en página.

*   **Índices BTREE:**
    *   `pct_paginas_borradas` alto → **REINDEX \[CONCURRENTLY]**.
    *   `avg_leaf_density` bajo → **CLUSTER** sobre el índice o reconsiderar el patrón de inserción/ordenamiento.

*   **TOAST:** alto `pct_bloat_toast` → revisar columnas `TEXT/BYTEA` grandes, estrategias de actualización y VACUUM.

*   **Operativa:**
    *   Ejecuta las versiones **approx** en horas hábiles; usa las **exactas** para confirmar en ventanas de baja carga.
    *   Excluye `pg_catalog`, `information_schema` y (si gustas) `pg_toast` en barridos generales.

---

# Bloat de todas las tablas (exacto)
```sql
WITH t AS (
  SELECT c.oid, n.nspname AS schema_name, c.relname AS table_name
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
    AND n.nspname NOT IN ('pg_catalog','information_schema')
),
s AS (
  SELECT t.schema_name, t.table_name, (pgstattuple(t.oid)).*
  FROM t
)
SELECT schema_name, table_name,
       table_len, tuple_len, dead_tuple_len, free_space,
       ROUND(100.0 * (dead_tuple_len + free_space) / NULLIF(table_len,0), 2) AS pct_bloat
FROM s
ORDER BY pct_bloat DESC;
```


# Top-N tablas para VACUUM (por tuplas muertas)
```sql
WITH s AS (
  SELECT n.nspname AS schema_name, c.relname AS table_name,
         (pgstattuple_approx(c.oid)).*
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
    AND n.nspname NOT IN ('pg_catalog','information_schema')
)
SELECT schema_name, table_name,
       dead_tuple_count, dead_tuple_len,
       ROUND(100.0 * dead_tuple_len / NULLIF(table_len,0), 2) AS pct_muertas
FROM s
WHERE dead_tuple_count > 0
ORDER BY pct_muertas DESC
LIMIT 20;
```


# Bloat en TOAST (datos grandes)
```sql
WITH toast_map AS (
  SELECT nsp.nspname AS schema_name,
         rel.relname  AS table_name,
         rel.reltoastrelid AS toast_oid
  FROM pg_class rel
  JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
  WHERE rel.relkind = 'r' AND rel.reltoastrelid <> 0
),
stats AS (
  SELECT schema_name, table_name, (pgstattuple(toast_oid)).*
  FROM toast_map
)
SELECT schema_name, table_name,
       ROUND(100.0 * (dead_tuple_len + free_space) / NULLIF(table_len,0), 2) AS pct_bloat_toast,
       table_len, free_space, dead_tuple_len
FROM stats
ORDER BY pct_bloat_toast DESC;
```



