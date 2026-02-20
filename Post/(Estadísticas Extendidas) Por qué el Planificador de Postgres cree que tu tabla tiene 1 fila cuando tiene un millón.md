# (Estadísticas Extendidas) Por qué el Planificador de Postgres cree que tu tabla tiene 1 fila cuando tiene un millón.

### 🎭 Fase 2: El Plato Fuerte

Elegiremos el título: **"La mentira de la independencia: Por qué el Planificador de Postgres necesita terapia de pareja para tus columnas."**

#### 1. Introducción Técnica (El Contexto de Negocios)

PostgreSQL es un motor **Open Source (Licencia PostgreSQL)** que utiliza un Optimizador Basado en Costos (CBO). Para decidir si usa un *Index Scan* o un *Sequential Scan*, el planificador utiliza estadísticas recolectadas por el proceso de `AUTOVACUUM/ANALYZE`.

Por defecto, Postgres asume que las columnas son **independientes**. Si filtras por `país = 'España'` y `ciudad = 'Madrid'`, el planificador multiplica las probabilidades por separado. Pero en el mundo real, estas columnas están correlacionadas. Las **Estadísticas Extendidas** (introducidas en la versión 10) permiten al motor entender estas relaciones, optimizando drásticamente los planes de ejecución en consultas complejas.


### 📍 ¿Para qué sirven? (El mundo sin estadísticas)

Imagina que tienes una biblioteca con **1 millón de libros**.
Tu jefe te pide: *"Tráeme todos los libros de Cocina que sean de Autores Franceses"*.

Si Postgres **no tuviera estadísticas**, no sabría si hay 10 libros o 500,000.

* **Si cree que hay 10:** Irá a buscarlos caminando (usará un **Índice**, que es rápido para pocos datos).
* **Si cree que hay 500,000:** Sacará un carrito de carga y recorrerá todos los pasillos (hará un **Sequential Scan**, que es más eficiente para volúmenes masivos).

**El problema:** Si el planificador estima mal (cree que hay 10 pero en realidad hay 500,000), intentará traer medio millón de libros "caminando". Resultado: **Tu consulta se queda colgada y el servidor explota.**


#### 3. El "Deep Dive" (Lo bueno, lo malo y lo feo)

* **Ventajas (Power-ups):** * **Estimaciones de selectividad precisas:** Evita que el planificador elija un *Nested Loop* cuando debería usar un *Hash Join*.
* **Control de granularidad:** Con `SET STATISTICS`, puedes decirle a Postgres que sea más meticuloso con una columna específica sin afectar el rendimiento global del `ANALYZE`.


* **Casos de uso reales:**
* Sistemas de logística (Relación entre Código Postal, Ciudad y Provincia).
* E-commerce con jerarquías de productos (Categoría -> Subcategoría).
* Consultas con múltiples cláusulas `WHERE` sobre columnas que siempre "van juntas".


* **Consideraciones de experto:** * No abuses. Crear estadísticas extendidas para todo añade carga al proceso de mantenimiento.
* `SET STATISTICS` (el comando de tu prompt) aumenta el tamaño del "histograma" de una sola columna, pero no ayuda con la correlación entre dos columnas; para eso necesitas `CREATE STATISTICS`.



#### 4. Laboratorio de Código (Manos a la obra)

```sql
-- Caso 1: Aumentar la precisión de una columna específica (Histograma más grande)
-- Por defecto es 100. Subirlo a 500 ayuda con columnas muy diversas (High Cardinality).
ALTER TABLE ventas ALTER COLUMN id_transaccion SET STATISTICS 500;

-- Caso 2: El problema de la correlación (Ciudad y País)
CREATE TABLE ubicaciones (
    id serial PRIMARY KEY,
    pais text,
    ciudad text
);

-- Insertamos datos donde Madrid siempre es España
-- ... (asumamos 1 millón de filas)

-- Si hacemos esto, el planificador fallará en la cuenta:
EXPLAIN ANALYZE SELECT * FROM ubicaciones WHERE pais = 'España' AND ciudad = 'Madrid';

-- ¡LA SOLUCIÓN! Creamos estadísticas de dependencia funcional
CREATE STATISTICS s_pais_ciudad_dep ON pais, ciudad FROM ubicaciones;

-- También podemos capturar valores comunes en conjunto (N-distinct)
CREATE STATISTICS s_pais_ciudad_ndist ON (pais, ciudad) FROM ubicaciones;

-- ¡No olvides ejecutar esto para que surta efecto!
ANALYZE ubicaciones;
```
 

#### 5. La Verdad Desnuda (Lo que nadie te cuenta)

* **Costo de ANALYZE:** Si subes el `SET STATISTICS` a 10,000 en todas las columnas, tu `ANALYZE` pasará de durar segundos a minutos, bloqueando recursos de CPU y I/O.
* **No son mágicas:** Las estadísticas extendidas solo ayudan con las cláusulas `WHERE` y `GROUP BY`. No van a arreglar una consulta mal escrita con funciones en el `WHERE` que invalidan los índices.
* **Mantenimiento:** Al ser objetos adicionales en el catálogo, a veces los desarrolladores olvidan que existen al migrar esquemas.

#### 6. Conclusión y Call to Action (CTA)

El planificador de Postgres es brillante, pero a veces necesita que le expliques cómo se relacionan tus datos en la vida real. Si tus consultas se vuelven lentas "de la nada" a pesar de tener índices, es hora de mirar las estimaciones de filas.

 
### 🛠️ Las dos herramientas que pusiste en el prompt:

#### 1. `ALTER TABLE ... SET STATISTICS 500;`

**¿Qué es?** Es aumentar la "resolución" de la foto de una columna.

* **Por defecto (100):** Postgres toma una muestra pequeña de la columna. Es como una foto pixelada.
* **A 500 o más:** Es como pasar de una foto vieja a una en 4K.
* **¿Para qué sirve?** Para columnas con datos muy variados (ej. apellidos, IDs aleatorios). Si Postgres falla al contar cuántos "García" hay, le subes las estadísticas para que mire con más lupa esa columna específica.

#### 2. `CREATE STATISTICS ... ON a1, a2`

**¿Qué es?** Es enseñarle a Postgres que dos columnas **están relacionadas**.

* **El error clásico:** Postgres cree que las columnas son independientes. Si buscas `Marca = 'Ferrari'` y `Modelo = 'Testarossa'`, Postgres piensa: *"Hay pocos Ferraris y hay pocos Testarossas, así que la combinación de ambos debe ser casi cero"*.
* **La realidad:** Si es un Testarossa, **siempre** es un Ferrari. La probabilidad no se multiplica, es la misma.
* **¿Para qué sirve?** Para que el planificador no subestime la cantidad de resultados cuando filtras por varias cosas a la vez que tienen sentido entre sí (Ciudad/País, Marca/Modelo, Mes/Estación del año).

 

### 📉 La Diferencia en el Planificador

| Sin Estadísticas Extendidas | Con Estadísticas Extendidas |
| --- | --- |
| El motor "adivina" el número de filas. | El motor "sabe" cuántas filas hay. |
| Elige el camino lento (Sequential Scan) por error. | Elige el camino rápido (Index Scan). |
| **CPU al 100%** y usuarios quejándose. | **Respuesta en milisegundos.** |

 

### 💡 En resumen:

Esas líneas de código sirven para que el "cerebro" de Postgres deje de adivinar y empiece a calcular con precisión. Si el cerebro sabe cuántos datos vienen, elegirá siempre la ruta más corta.
 


#### 7. Referencias

* [PostgreSQL Documentation: CREATE STATISTICS](https://www.postgresql.org/docs/current/sql-createstatistics.html)
* [PostgreSQL Documentation: ALTER TABLE ... SET STATISTICS](https://www.postgresql.org/docs/current/sql-altertable.html)
* [The Internals of PostgreSQL: Statistics](https://www.interdb.jp/pg/pgsql03.html)
* [Reducing row count estimation errors in PostgreSQL](https://dev.to/shinyakato_/reducing-row-count-estimation-errors-in-postgresql-54ok)

 
