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


### Qué significa cada columna
```sql
postgres@db_destination# SELECT * FROM pgstattuple_approx('produccion_diaria');
+-----------+-----------------+--------------------+------------------+----------------------+------------------+----------------+--------------------+-------------------+---------------------+
| table_len | scanned_percent | approx_tuple_count | approx_tuple_len | approx_tuple_percent | dead_tuple_count | dead_tuple_len | dead_tuple_percent | approx_free_space | approx_free_percent |
+-----------+-----------------+--------------------+------------------+----------------------+------------------+----------------+--------------------+-------------------+---------------------+
|     49152 |               0 |                999 |            44224 |    89.97395833333333 |                0 |              0 |                  0 |              4928 |  10.026041666666666 |
+-----------+-----------------+--------------------+------------------+----------------------+------------------+----------------+--------------------+-------------------+---------------------+
(1 row)

Time: 0.404 ms
postgres@db_destination# SELECT * FROM pgstattuple('produccion_diaria');
+-----------+-------------+-----------+---------------+------------------+----------------+--------------------+------------+--------------+
| table_len | tuple_count | tuple_len | tuple_percent | dead_tuple_count | dead_tuple_len | dead_tuple_percent | free_space | free_percent |
+-----------+-------------+-----------+---------------+------------------+----------------+--------------------+------------+--------------+
|     49152 |         999 |     35964 |         73.17 |                0 |              0 |                  0 |       5024 |        10.22 |
+-----------+-------------+-----------+---------------+------------------+----------------+--------------------+------------+--------------+
(1 row)
```

Cuando ejecutas `pgstattuple('tabla')`, el motor entra al disco duro y escanea byte por byte cada bloque físico de la tabla. Esta es la traducción exacta de lo que te está reportando:

| Columna | Significado Matemático y Físico | El Diagnóstico del DBA SQUAD |
| --- | --- | --- |
| **`table_len`** | Tamaño físico total de la tabla en el disco duro (en bytes). | Es el límite de tu contenedor. Todo lo que pasa adentro debe sumar este número. |
| **`tuple_count`** | Cantidad de filas **vivas** y útiles. | Tus datos reales. Lo que le importa a la aplicación. |
| **`tuple_len`** | Suma total en bytes del peso de tus filas vivas. | El "Payload" o carga útil. Es lo que realmente pesan tus datos puros sin la estructura de PostgreSQL. |
| **`tuple_percent`** | Porcentaje de la tabla ocupado por filas vivas (`tuple_len / table_len * 100`). | **Eficiencia de almacenamiento.** Si es del 90%, tu disco se usa excelente. Si es del 10%, estás quemando dinero en AWS/GCP para guardar aire. |
| **`dead_tuple_count`** | Cantidad de filas **muertas** (basura dejada por `UPDATEs` o `DELETEs`). | El tamaño del cementerio. Si este número sube rápido, tu Autovacuum no está dando abasto. |
| **`dead_tuple_len`** | Suma total en bytes del peso de la basura. | La cantidad física de disco duro que estás desperdiciando en cadáveres. |
| **`dead_tuple_percent`** | Porcentaje de la tabla ocupado por filas muertas. | **Nivel de Toxicidad.** Si supera el 20%, el rendimiento de tus consultas (`Seq Scans`) se está degradando severamente. |
| **`free_space`** | Cantidad de bytes completamente vacíos y listos para recibir nuevos `INSERTs`. | Espacio reciclado por el VACUUM o bloques físicos que aún no se han llenado. |
| **`free_percent`** | Porcentaje de la tabla que es puro espacio vacío y libre (`(free_space / table_len) * 100`). | **Índice de Cráteres.** Un porcentaje muy alto aquí indica que borraste muchos datos, pero Linux aún no ha recuperado ese espacio físico. |

---

### 🏛️ EL MISTERIO DEL "IMPUESTO OCULTO" (El Overhead)



Si sumas `tuple_percent` (vivos) + `dead_tuple_percent` (muertos) + `free_percent` (espacio libre), **jamás te dará el 100%**.

Siempre faltará un porcentaje (generalmente entre el 1% y el 5%). Este es el **Overhead Estructural**.
El disco duro no solo guarda tus datos. Para que el motor sepa dónde está cada cosa a la velocidad de la luz, PostgreSQL cobra un impuesto de espacio en cada bloque de 8 KB que incluye:

* Las cabeceras de los bloques (*Page Headers*).
* Los punteros de memoria (*Line Pointers*).
* El *Padding* (espacios en blanco para que el procesador pueda leer en saltos de 8 bytes).

Ese porcentaje fantasma es el costo de mantener la arquitectura interna de la base de datos funcionando.

---

### ⚔️ LAS REGLAS DE INTERVENCIÓN (Cuándo entrar en pánico)


No corras comandos forenses si no sabes qué decisión tomar con los resultados. Te voy a dar la doctrina de VANGUARD para leer estos porcentajes y tomar acción táctica:

**1. El Escenario Sano (Operación Normal):**

* `tuple_percent`: > 70%
* `dead_tuple_percent`: < 5%
* `free_percent`: < 15%
* **Veredicto:** No toques nada. Tu base de datos está respirando perfectamente. El Autovacuum está haciendo su trabajo.

**2. Alerta de Asfixia (Autovacuum Ahogado):**

* `dead_tuple_percent`: **> 15%**
* **Veredicto:** Tienes un problema de fragmentación activa. Tus procesos de borrado o actualización son más rápidos que tus procesos de limpieza.
* **Acción:** Dispara un `VACUUM` manual de inmediato para convertir ese `dead_tuple` en `free_space`, o afina los parámetros `autovacuum_vacuum_cost_limit` para darle más velocidad a la recolección de basura.

**3. El Colapso de Inflación (Table Bloat Crítico):**

* `free_percent`: **> 40%** (y el `tuple_percent` es muy bajo).
* **Veredicto:** Tienes una base de datos "queso gruyer". Está llena de agujeros gigantes. Hiciste un `DELETE` masivo, el VACUUM limpió las tuplas muertas y las convirtió en espacio libre, pero **Linux no ha recuperado esos Gigabytes**. Tus respaldos y escaneos son ineficientes.
* **Acción:** Necesitas recuperar ese espacio físico al sistema operativo. El VACUUM estándar no sirve aquí. Tienes que usar artillería pesada.




**JAMÁS ejecutes `pgstattuple('tabla_gigante')` en un servidor en producción.**
Como te explicó Pedro, este comando escanea la tabla físicamente byte por byte. Si le haces esto a una tabla de 5 Terabytes, vas a asfixiar los discos duros de tu servidor haciendo un *Sequential Scan* masivo solo para satisfacer tu curiosidad matemática.

Por eso existe **`pgstattuple_approx`**.. Lee el mapa del FSM en milisegundos, no toca los discos de datos, y aunque te da un número ligeramente redondeado hacia abajo (4,928 en lugar de 5,024), te entrega el 99% de precisión con un **0% de impacto en el rendimiento** de tus clientes.





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



