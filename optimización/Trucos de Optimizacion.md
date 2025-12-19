

# Consultas que parecen perfectas… pero no lo son: los JOINs que arruinan tu performance [[Ref]](https://medium.com/@Rohan_Dutt/how-to-write-sql-queries-that-prevent-cardinality-explosions-in-multi-way-joins-b41ba236acac)

 
### **1. JOIN sobre columnas con tipos diferentes (implícito CAST)**

*   **Razón:** Si las columnas tienen tipos distintos (ej. `INT` vs `VARCHAR`), el motor hace conversión en cada comparación → **no usa índice**.
*   **Ejemplo del problema:**
    ```sql
    SELECT * 
    FROM pedidos p
    JOIN clientes c ON p.id_cliente = c.id_cliente::text;
    ```
    Parece correcto, pero el CAST rompe el índice.
*   **Solución:**
    *   Asegurar tipos iguales en diseño.
    *   O usar CAST en la columna más pequeña y crear índice funcional:
        ```sql
        CREATE INDEX idx_clientes_id_text ON clientes((id_cliente::text));
        ```



### **2. JOIN con función en la condición**

*   **Razón:** Usar funciones en la columna del JOIN invalida el índice.
*   **Ejemplo del problema:**
    ```sql
    SELECT * 
    FROM ventas v
    JOIN productos p ON LOWER(v.codigo) = LOWER(p.codigo);
    ```
    Parece bien para case-insensitive, pero fuerza **full scan**.
*   **Solución:**
    *   Crear índice funcional:
        ```sql
        CREATE INDEX idx_productos_lower ON productos(LOWER(codigo));
        ```
    *   Evitar aplicar función en ambas columnas.



### **3. JOIN con OR en la condición**

*   **Razón:** Condiciones con `OR` en el `ON` hacen que el optimizador no use índices eficientemente.
*   **Ejemplo del problema:**
    ```sql
    SELECT * 
    FROM clientes c
    JOIN pedidos p ON c.id_cliente = p.id_cliente OR c.email = p.email_cliente;
    ```
*   **Solución:**
    *   Separar en dos consultas y unir con `UNION ALL`:
        ```sql
        SELECT ... FROM clientes c JOIN pedidos p ON c.id_cliente = p.id_cliente
        UNION ALL
        SELECT ... FROM clientes c JOIN pedidos p ON c.email = p.email_cliente;
        ```



### **4. JOIN con ORDER BY en columna no indexada**

*   **Razón:** Si ordenas por una columna que no está indexada después de un JOIN grande, el motor hace **sort costoso en memoria**.
*   **Ejemplo del problema:**
    ```sql
    SELECT c.nombre, p.total
    FROM clientes c
    JOIN pedidos p ON c.id_cliente = p.id_cliente
    ORDER BY p.fecha_pedido;
    ```
*   **Solución:**
    ```sql
    CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido);
    ```



### **5. JOIN con subconsulta no correlacionada mal optimizada**

*   **Razón:** Subconsultas en el `ON` o `WHERE` que parecen simples pueden generar **Nested Loop gigante**.
*   **Ejemplo del problema:**
    ```sql
    SELECT c.nombre, p.total
    FROM clientes c
    JOIN pedidos p ON c.id_cliente = p.id_cliente
    WHERE p.total > (SELECT AVG(total) FROM pedidos);
    ```
    Parece bien, pero el optimizador recalcula el AVG muchas veces.
*   **Solución:**
    ```sql
    WITH avg_total AS (SELECT AVG(total) AS promedio FROM pedidos)
    SELECT c.nombre, p.total
    FROM clientes c
    JOIN pedidos p ON c.id_cliente = p.id_cliente
    CROSS JOIN avg_total
    WHERE p.total > avg_total.promedio;
    ```
 

### ✅ **¿Qué riesgos hay si no haces JOINs inteligentes?**

Si no consideras la cardinalidad y haces JOINs incorrectos, puedes tener:

1.  **Duplicación masiva de datos**
    *   Si haces un JOIN sin condiciones correctas, puedes multiplicar filas (efecto “cartesiano”).
    *   Ejemplo: `SELECT * FROM clientes JOIN pedidos;` sin `ON` → millones de combinaciones.

2.  **Resultados incorrectos**
    *   Datos inflados, totales erróneos, reportes falsos.
    *   Ejemplo: sumas que deberían dar 100, terminan en 10,000 por duplicación.

3.  **Problemas de rendimiento**
    *   JOINs mal diseñados pueden generar consultas lentísimas, bloqueos y alto consumo de CPU/memoria.

4.  **Riesgo de inconsistencias**
    *   Si no respetas la cardinalidad, puedes mostrar datos que no tienen relación real (errores lógicos).

5.  **Impacto en integridad y seguridad**
    *   JOINs incorrectos pueden exponer datos que no deberían relacionarse, afectando privacidad.
 

✅ **Buenas prácticas para JOINs inteligentes:**

*   Analiza la cardinalidad antes de diseñar la consulta.
*   Usa claves primarias y foráneas correctamente.
*   Evita `CROSS JOIN` salvo que sea necesario.
*   Usa `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN` según el caso.
*   Filtra con condiciones claras (`ON` y `WHERE`).

 


---
# Los indices en columnas que estan en Group By sirven o no?

Decir que un índice en un `GROUP BY` "no sirve de nada" es incorrecto. De hecho, un índice bien diseñado es **crucial** para optimizar un `GROUP BY`.

Vamos a desglosarlo para que entiendas la mecánica interna de PostgreSQL y puedas rebatir con argumentos técnicos superiores (o conceder la victoria elegantemente).

### ¿Por qué un índice SÍ ayuda al GROUP BY?

Para que la base de datos pueda agrupar filas por `producto`, necesita poner todos los "relojes" juntos, todos los "zapatos" juntos, etc.

PostgreSQL tiene principalmente dos estrategias para hacer esto:

1. **HashAggregate (Sin Índice):**
* Lee toda la tabla desordenada (Sequential Scan).
* Crea una tabla hash en memoria RAM.
* Va metiendo cada fila en su "cubeta" correspondiente.
* **Problema:** Consume mucha memoria (`work_mem`). Si la tabla es gigante, se desborda al disco y se vuelve lentísimo.


2. **GroupAggregate (Con Índice):**
* Un índice B-Tree guarda los datos **ya ordenados**.
* PostgreSQL recorre el índice. Como ya viene ordenado (A, A, A, B, B, C...), sabe que en cuanto cambia de "A" a "B", ya terminó de sumar las "A".
* **Ventaja:** No necesita memoria para ordenar ni hacer hash. Es un flujo continuo (streaming). El primer resultado sale casi instantáneamente.



---

### La prueba del delito (Comparación técnica)

Supongamos tu tabla `inventario` con millones de filas.

#### Escenario 1: Tu postura (Sin Índice o Índice ignorado)

Postgres hará esto:

```text
-> HashAggregate
   -> Seq Scan on inventario

```

*Costo:* Leer todo el disco + Costo de CPU para armar el hash.

#### Escenario 2: La postura del DBA (Índice en `producto`)

Si creas `CREATE INDEX idx_producto ON inventario(producto);`
Postgres *podría* hacer esto:

```text
-> GroupAggregate
   -> Index Scan on idx_producto

```

*Costo:* Lee el índice ordenado. Pero ojo, **aquí tienes un punto a tu favor:** Si el índice solo tiene `producto`, Postgres tiene que ir a la tabla principal (Heap) a buscar el valor de `cantidad` para sumarlo. Si la tabla es muy grande, hacer esos saltos es lento y Postgres podría preferir no usar el índice.

#### Escenario 3: La técnica Maestra (Covering Index)

Aquí es donde tú puedes ganar el debate proponiendo la **solución real**.
Si creas el índice así:

```sql
CREATE INDEX idx_producto_covering ON inventario (producto) INCLUDE (cantidad);

```

O así (índice compuesto):

```sql
CREATE INDEX idx_producto_cantidad ON inventario (producto, cantidad);

```

Ocurre la magia llamada **Index Only Scan**.

1. Postgres va al índice.
2. El índice ya está ordenado por `producto` (perfecto para el Group By).
3. El índice *también* contiene el valor de `cantidad`.
4. **Resultado:** Postgres **nunca toca la tabla**. Resuelve la consulta leyendo solo el índice, que es mucho más pequeño y rápido.

### Resumen del Veredicto

| Argumento | Validez | Explicación |
| --- | --- | --- |
| **"El índice no sirve de nada" (Tú)** | ❌ Incorrecto | Un índice evita la operación de ordenamiento (Sort) que es muy costosa. |
| **"El índice sí sirve" (DBA)** | ✅ Correcto | Permite usar `GroupAggregate` en lugar de `HashAggregate`. |
| **"El índice optimizado" (Tú + Conocimiento)** | 🚀 Experto | Un índice con `INCLUDE` o compuesto permite un `Index Only Scan`, que es la forma más rápida posible. |

### ¿Cuándo tendrías razón tú?

Tú tendrías razón **solo si la cardinalidad es muy baja**.
Ejemplo: Si tu tabla tiene 1 millón de filas pero solo hay 2 tipos de productos ("A" y "B").
En ese caso, usar un índice es más lento que leer toda la tabla de golpe, y el planificador de Postgres ignorará el índice del DBA. Pero en un inventario normal (muchos productos distintos), el índice gana.

### Paso siguiente sugerido

Para demostrar dominio del tema, te sugiero que no le digas "tenías razón", sino que le digas:
*"Tenías razón en que el índice ayuda a evitar el sort, pero si solo indexamos la columna del grupo, el salto al Heap es costoso. 
