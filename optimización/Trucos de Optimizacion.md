

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


---

#  **No usar `SELECT *`**
 Razones técnicas fundamentales por las que, a pesar de que la página se cargue completa en memoria, `SELECT *` sigue siendo una mala práctica de arquitectura y rendimiento.
 
### 1. El "Efecto TOAST" (El I/O oculto)

Aquí es donde falla tu teoría de que "todo está en la página". PostgreSQL tiene un límite de tamaño para las filas en una página de 8KB. Si tienes columnas grandes (como `TEXT` largo, `JSONB` pesado o `BYTEA`), Postgres usa una técnica llamada **TOAST** (*The Oversized-Attribute Storage Technique*).

* **Cómo funciona:** Postgres mueve los datos grandes a una tabla "oculta" aparte.
* **El problema:** Si haces `SELECT *`, obligas a Postgres a ir a buscar esos datos a la tabla TOAST (I/O extra). Si solo haces `SELECT id, nombre`, Postgres **ni siquiera toca** los datos pesados, ahorrando muchísimos recursos de disco y memoria.

### 2. Index-Only Scans (El "Santo Grial" del performance)

Esta es la razón más pesada en arquitectura. Si tu consulta solo pide columnas que ya están en un **índice**, PostgreSQL puede responderte **sin tocar la tabla (el Heap)**.

* **Con `SELECT id` (siendo ID indexado):** Postgres lee el índice y te da la respuesta. Es ultra rápido.
* **Con `SELECT *`:** Forzosamente tiene que ir a la tabla para traer las columnas que no están en el índice. Esto convierte una consulta de microsegundos en una de milisegundos.

### 3. El costo de "Serialización" y Red

Aunque la página de 8KB esté en la memoria RAM (Buffer Cache), esos datos tienen que viajar al **cliente** (tu aplicación en Python, Java, Node, etc.).

* **CPU:** Postgres tiene que "empaquetar" cada columna en el protocolo de red. Más columnas = más ciclos de CPU en el servidor.
* **Ancho de Banda:** Si tu tabla tiene 50 columnas y solo usas 2, estás enviando un 95% de "basura" por el cable. En una red de nube (AWS/Azure) donde la latencia es ley, enviar megabytes extra de datos innecesarios satura la tarjeta de red y ralentiza la aplicación.
* **Memoria en el Cliente:** Tu aplicación tiene que "desempaquetar" y guardar en su propia RAM (objetos de lenguaje) todas esas columnas que no va a usar, lo cual puede causar problemas de *Garbage Collection* o falta de memoria.

### 4. Mantenimiento y Evolución (Arquitectura)

Este punto no es de performance de CPU, sino de **resiliencia del sistema**:

* **Contratos:** Si tu aplicación usa `SELECT *`, y mañana alguien agrega una columna de tipo `GEOMETRY` o un `JSONB` de 10MB a esa tabla, tu aplicación **heredará ese peso automáticamente** y podría colapsar o volverse lenta sin que tú hayas cambiado una sola línea de código en el backend.

---

### Resumen para tus alumnos:

| Nivel | ¿Importa `SELECT *`? | ¿Por qué? |
| --- | --- | --- |
| **Disco/Páginas** | **Poco** | Tienes razón: se lee el bloque de 8KB completo del disco a la RAM. |
| **TOAST** | **Mucho** | Traer columnas grandes requiere leer archivos extra que no están en la página principal. |
| **Índices** | **Crítico** | `SELECT *` rompe la posibilidad de usar *Index-Only Scans*. |
| **Red** | **Mucho** | El tráfico de red y la serialización crecen linealmente con el número de columnas. |

> **Conclusión:** Tu lógica sobre la carga de páginas en el Buffer Cache es correcta para datos "pequeños" y ya cargados, pero en el panorama completo de la arquitectura, los costos de TOAST, red y pérdida de optimizaciones de índice hacen que `SELECT *` sea un enemigo del escalado.



### Index-Only Scan

Para un arquitecto de bases de datos, entender el **Index-Only Scan** es como descubrir un "atajo mágico". Es una de las optimizaciones más potentes de PostgreSQL porque permite que la base de datos responda una consulta **sin tocar la tabla (el Heap)**.

 

### 1. La diferencia fundamental

Para entenderlo, primero debemos recordar cómo funciona un **Index Scan** normal (el estándar):

1. **Busca en el índice:** Encuentra la entrada (por ejemplo, el ID 500).
2. **Obtiene el puntero:** El índice le dice: "Esa fila está en la Página A, Fila 12".
3. **Va al Heap (La tabla):** Postgres tiene que saltar al disco/memoria para leer la fila completa en la tabla y verificar si la fila es visible para tu transacción (MVCC) y traer el resto de las columnas.

En un **Index-Only Scan**, Postgres hace esto:

1. **Busca en el índice:** Encuentra la entrada.
2. **Responde directamente:** Como el índice ya contiene la columna que pediste, y Postgres sabe que la fila es válida, **no salta a la tabla**. Devuelve el dato inmediatamente desde el índice.

 

### 2. El requisito secreto: El "Visibility Map" (Mapa de Visibilidad)

Tus alumnos podrían preguntar: *"¿Cómo sabe Postgres si una fila ha sido borrada o actualizada por otra transacción si no lee la tabla?"* (Recuerda el sistema MVCC).

Aquí entra un componente de arquitectura clave: **El Visibility Map (VM)**.

* El VM es un archivo pequeño que rastrea qué páginas de la tabla solo contienen filas que son visibles para todos.
* Si la página en la tabla está marcada como **"all-visible"** en el mapa, Postgres confía en el índice y completa el **Index-Only Scan**.
* Si la página ha tenido cambios recientes y no es "all-visible", Postgres se ve obligado a ir a la tabla para verificar la visibilidad, perdiendo la optimización.

 

### 3. Ejemplo práctico para tu clase

Imagina esta tabla de usuarios con 10 millones de filas:

```sql
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    email TEXT,
    fecha_registro TIMESTAMP,
    -- ... otras 20 columnas pesadas
);

CREATE INDEX idx_usuarios_email ON usuarios(email);

```

#### Caso A: El error del `SELECT *`

```sql
SELECT * FROM usuarios WHERE email = 'profe@ejemplo.com';

```

* **Postgres piensa:** "Tengo el email en el índice, pero el usuario quiere el nombre, la fecha y otras 20 columnas que NO están en el índice. **Tengo que ir a la tabla forzosamente**".
* **Resultado:** Index Scan (más lento).

#### Caso B: La eficiencia del Index-Only Scan

```sql
SELECT email FROM usuarios WHERE email = 'profe@ejemplo.com';

```

* **Postgres piensa:** "Busco el email y el usuario solo me pide el email. ¡Ya lo tengo todo en el índice! No necesito leer la tabla".
* **Resultado:** **Index-Only Scan** (ultra rápido, cero I/O en la tabla).



### 4. ¿Por qué es importante para el performance?

1. **Ahorro de I/O:** Evitas el "Random I/O" de saltar del índice a la tabla. El índice es mucho más pequeño y suele estar siempre en la RAM (Buffer Cache).
2. **Menos contención:** Al no leer la tabla, reduces la carga en el sistema de almacenamiento.
3. **Sinergia con VACUUM:** Para que el *Visibility Map* esté actualizado, el **autovacuum** debe correr con frecuencia. Si el vacuum no limpia, no hay Index-Only Scans.

### Resumen para tus alumnos:

> "Un Index-Only Scan es cuando el índice se vuelve la base de datos misma para esa consulta. Si pides solo lo que indexaste, Postgres no tiene que trabajar doble yendo a la tabla. Por eso el `SELECT *` es el enemigo de esta optimización: obliga a la base de datos a dejar de leer el índice (pequeño y rápido) para ir a buscar basura a la tabla (grande y lenta)".

--- 
# On-Premise - Cloud [Link](https://www.scalingpostgres.com/episodes/398-latency-killing-performance/)

Este post de **Cybertec** es una pieza fundamental para tu curso de arquitectura, porque explica por qué una base de datos puede ser lenta aunque el procesador (CPU) sea el más rápido del mundo. El culpable: **La latencia.**

Aquí tienes el resumen desglosado para que lo expliques a tus alumnos:

### 1. El Objetivo del Post

El autor busca demostrar con datos reales que la diferencia de rendimiento entre tener servidores físicos propios (**On-Premise**) y usar la nube (**Cloud**) no se debe a la potencia del equipo, sino a la **distancia física y lógica** que recorren los datos.

### 2. El Problema: Latencia vs. Rendimiento

El post explica que en PostgreSQL, la mayoría de las operaciones (especialmente las escrituras) dependen de qué tan rápido el disco le diga a la base de datos: *"Ya guardé la información"*.

* **En la nube (Cloud):** Tu base de datos y tu disco (almacenamiento) **no están en el mismo lugar**. Están conectados por una red interna. Cada vez que haces un `COMMIT`, el dato debe viajar por esa red, guardarse y enviar una confirmación de vuelta.
* **En servidores físicos (On-Premise):** El disco suele estar conectado directamente a la placa base (bus local). El viaje es casi instantáneo.

### 3. Conceptos Clave para tu clase

#### A. Latencia de Red (El "Ping")

El post muestra que en la nube, el simple hecho de enviar un paquete de un servidor a otro añade milisegundos que en un servidor físico no existen.

* **Dato para alumnos:** Si una consulta hace 100 viajes de red pequeños, y cada uno tarda 1ms, la consulta tardará 100ms solo en "viajes", sin contar el procesamiento.

#### B. Latencia de Disco (El problema del WAL)

PostgreSQL usa el **WAL (Write Ahead Log)**. Para que una transacción sea segura, el WAL debe escribirse en el disco de forma síncrona.

* En **On-premise** con discos NVMe, esto tarda unos **pocos microsegundos**.
* En **Cloud** (usando almacenamiento en red como AWS EBS), esto puede tardar **milisegundos**.
* **Conclusión:** La nube puede ser **10 o 50 veces más lenta** en escrituras pesadas debido a esta arquitectura.

#### C. Rendimiento (Throughput) vs. Latencia

El post aclara que la nube es excelente en *Throughput* (puede mover mucha información a la vez), pero es mala en *Latencia* (qué tan rápido responde una sola petición). Para una base de datos transaccional, la latencia es mucho más importante.

### 4. La Solución / Recomendaciones

El post no dice que la nube sea mala, sino que como arquitecto debes saber elegir:

1. **Si necesitas velocidad extrema:** Usa servidores físicos o instancias de nube con "Local NVMe" (como el post de PlanetScale Metal que vimos antes).
2. **Si usas nube estándar:** Debes optimizar tu código para hacer **menos viajes al servidor** (usar procedimientos almacenados, reducir el número de commits pequeños, o usar conexiones persistentes).



### Resumen Ejecutivo para tu curso:

> "La nube es como pedir comida por delivery: puedes pedir mucha comida (Throughput), pero siempre tardará en llegar porque tiene que viajar por la calle (Red). Tener el servidor físico es como cocinar en tu propia cocina: es inmediato porque todo está a la mano."

 
 


---

# shared_buffers

El parámetro `shared_buffers` no es una "isla"; su configuración impacta y depende directamente de otros valores dentro de PostgreSQL y de la configuración del núcleo (kernel) de Linux.

Aquí te detallo cómo se relaciona con el ecosistema del servidor para que puedas ajustarlo correctamente:



## 1. Relación con otros parámetros de PostgreSQL

`shared_buffers` determina cuánta memoria RAM reserva PostgreSQL para su propia caché de datos. Si lo mueves, debes considerar estos otros:

* **`max_connections`**: Cada conexión consume una cantidad pequeña pero acumulativa de memoria RAM. Si subes mucho los `shared_buffers` y también tienes un `max_connections` muy alto, podrías quedarte sin RAM para los procesos individuales.
* **`work_mem`**: Esta es la memoria para operaciones de ordenamiento (sort) y uniones (hash joins). A diferencia de `shared_buffers`, que es global, `work_mem` se asigna **por cada operación dentro de una consulta**. Si asignas el 80% de tu RAM a `shared_buffers`, no dejarás espacio para que `work_mem` funcione, provocando que las consultas usen el disco (lento) o que el sistema colapse (OOM Killer).
* **`effective_cache_size`**: No reserva memoria, pero le dice al optimizador cuánta memoria crees que hay disponible en total (incluyendo la caché del Sistema Operativo). Típicamente se configura al **50% - 75%** de la RAM total.
* **`huge_pages`**: Si tu `shared_buffers` es mayor a unos pocos gigabytes, es casi obligatorio usar Huge Pages en Linux para mejorar el rendimiento y reducir la sobrecarga de la CPU al gestionar tablas de páginas grandes.
 
### Límites de Memoria Compartida (Kernel Parameters)

En versiones modernas de PostgreSQL (9.3+), el uso de memoria compartida es más flexible, pero en sistemas muy cargados o versiones antiguas, debes revisar el archivo `/etc/sysctl.conf`:

* **`kernel.shmmax`**: Es el tamaño máximo de un solo segmento de memoria compartida. Debe ser mayor que tu `shared_buffers`.
* **`kernel.shmall`**: Es la cantidad total de memoria compartida permitida en el sistema (en páginas).

### Huge Pages (Páginas Grandes)

Si configuras `shared_buffers` con un valor alto (ej. 16GB o más), el kernel de Linux gastará mucha CPU gestionando páginas estándar de 4KB. Configurar **Huge Pages** (generalmente de 2MB) permite que el kernel gestione esa memoria de forma mucho más eficiente.

* Debes reservar las páginas en Linux: `vm.nr_hugepages`.
* Y activar el parámetro en Postgres: `huge_pages = try` o `on`.

### Swappiness

* **`vm.swappiness`**: Se recomienda bajar este valor a **1** o **10**. Esto evita que Linux mueva datos de la RAM (de tus buffers) al disco (swap) prematuramente, lo cual destruiría el rendimiento de tu base de datos.



Estos parámetros son **configuraciones del núcleo (kernel) de Linux** y se gestionan fuera de PostgreSQL, directamente en el sistema operativo. Tienes dos formas de hacerlo: una temporal (para probar) y una permanente (para que no se pierda al reiniciar).

Aquí te explico cómo y dónde hacerlo:



## 1. Configuración Permanente (Recomendado)

Para que los cambios persistan después de un reinicio, debes editar el archivo `/etc/sysctl.conf` o crear un archivo nuevo en `/etc/sysctl.d/`.

### Pasos:

1. Abre el archivo con privilegios de administrador:
```bash
sudo nano /etc/sysctl.conf

```


2. Ve al final del archivo y agrega las líneas con los valores que necesites. Por ejemplo:
```text
# Optimización para PostgreSQL
vm.swappiness = 10
vm.nr_hugepages = 4096
kernel.shmmax = 18446744073709551615
kernel.shmall = 18446744073709551615

```


3. Guarda el archivo y cierra (`Ctrl+O`, `Enter`, `Ctrl+X`).
4. **Carga los cambios inmediatamente** sin reiniciar el servidor con este comando:
```bash
sudo sysctl -p

```

 

## 2. Configuración Temporal (Para pruebas)

Si solo quieres probar el impacto en el rendimiento sin comprometer el próximo inicio del sistema, puedes usar el comando `sysctl -w`:

```bash
sudo sysctl -w vm.swappiness=10
sudo sysctl -w vm.nr_hugepages=4096

```

*Nota: Estos valores se borrarán si el servidor se apaga o se reinicia.*



## 3. ¿Cómo saber qué valores poner?

No se trata de poner números al azar, especialmente con las **Huge Pages**. Aquí te doy una guía rápida:

### Para `vm.swappiness`:

* **Valor 60 (Default):** Linux mueve datos a la swap con frecuencia. Malo para bases de datos.
* **Valor 1 a 10:** Recomendado para PostgreSQL. Le dice al kernel: "No uses el disco a menos que sea estrictamente necesario".

### Para `vm.nr_hugepages`:

Este valor depende totalmente de tu `shared_buffers`. Si pones un número muy pequeño, Postgres no arrancará; si pones uno muy grande, desperdiciarás RAM que nadie más podrá usar.

**La fórmula básica es:**


> **Ejemplo:** Si tu `shared_buffers` es de 8GB ( KB):
>  páginas.



## 4. Verificación

Después de aplicar los cambios, puedes verificar que el sistema los tomó correctamente con:

* **Para ver swappiness:** `cat /proc/sys/vm/swappiness`
* **Para ver páginas grandes:** `grep Huge /proc/meminfo`

 
