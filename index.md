
# INDEX
Un índice es una estructura de datos que almacena una referencia a los datos en una tabla, permitiendo que las búsquedas y otras operaciones sean mucho más rápidas. Piensa en un índice como el índice de un libro, que te permite encontrar rápidamente la página donde se menciona un tema específico.


## Impacto diferente en las operaciones de `INSERT`, `UPDATE` y `DELETE` en comparación con las consultas `SELECT`.

### Impacto de los Índices en `INSERT`

1. **Rendimiento de `INSERT`, `UPDATE` y `DELETE`**: Cada vez que insertas una nueva fila en una tabla con índices, PostgreSQL también debe actualizar esos índices. Esto significa que cuantos más índices tenga una tabla, más tiempo tomará cada operación de inserción³⁴.
2. **Espacio en Disco**: Los índices ocupan espacio adicional en disco. Si tienes muchos índices, el tamaño total de la base de datos puede aumentar significativamente².
3. **Balance**: Es importante encontrar un equilibrio entre tener suficientes índices para mejorar el rendimiento de las consultas `SELECT` y no tener tantos que ralenticen las operaciones de inserción y actualización³.

### Estrategias para Mitigar el Impacto

1. **Índices Necesarios**: Crea solo los índices que realmente necesitas para mejorar el rendimiento de tus consultas más frecuentes.
2. **Índices Diferidos**: Si estás realizando una gran cantidad de inserciones, considera deshabilitar temporalmente los índices y reconstruirlos después de completar las inserciones masivas.
3. **Monitoreo y Ajuste**: Usa herramientas como `EXPLAIN` y `ANALYZE` para monitorear el rendimiento de tus consultas y ajustar los índices según sea necesario.
 

 
# Tipos de índices en PostgreSQL:
```SQL

SELECT clm1, clm2, clm3
FROM tb1
WHERE col4 = 'comida'
AND col5 != 'rojo'
ORDER BY clm3;

CREATE INDEX idx_tb1_col4_col5_clm3
ON tb1 (col4, col5)
INCLUDE (clm1, clm2, clm3);

		 
col4 y col5 son las claves del índice (columnas principales para la búsqueda).
clm1, clm2 y clm3 están en INCLUDE, para que el índice pueda cubrir la consulta completamente sin necesidad de ir a la tabla base.
Ventaja: Mejora el rendimiento al evitar el acceso a la tabla principal, ya que todos los datos necesarios están en el índice.

## Índice B-Tree

### Descripción
El índice B-Tree es el tipo de índice más común y se utiliza para ordenar y buscar datos rápidamente.

### Cuándo Usarlo
- Cuando necesitas buscar datos que están ordenados.
- Para consultas que utilizan operadores como `<`, `<=`, `=`, `>=`, `>`.

### Cuándo No Usarlo
- No es ideal para datos que cambian con mucha frecuencia.
- No es eficiente para búsquedas de igualdad en datos muy grandes.

### Escenario de Uso
- **Escenario**: Una tabla de empleados donde necesitas buscar empleados por su salario.
- **Operadores**: `<`, `<=`, `=`, `>=`, `>`

## Índice Hash

### Descripción
El índice Hash es útil para búsquedas de igualdad, es decir, cuando buscas un valor específico.

### Cuándo Usarlo
- Cuando necesitas buscar un valor exacto.
- Ideal para columnas con valores únicos.

### Cuándo No Usarlo
- No es adecuado para búsquedas de rango (por ejemplo, valores entre X e Y).
- No se puede usar para ordenar datos.

### Escenario de Uso
- **Escenario**: Una tabla de usuarios donde necesitas buscar un usuario por su ID.
- **Operadores**: `=`

## Índice GiST

### Descripción
El índice GiST (Generalized Search Tree) es flexible y puede ser utilizado para una variedad de tipos de datos y consultas.

### Cuándo Usarlo
- Para datos geométricos o de texto.
- Cuando necesitas realizar búsquedas complejas, como proximidad o similitud.

### Cuándo No Usarlo
- No es tan rápido como B-Tree para búsquedas simples.
- Puede ser más complejo de configurar y mantener.

### Escenario de Uso
- **Escenario**: Una tabla de ubicaciones donde necesitas buscar puntos cercanos a una ubicación específica.
- **Operadores**: `&&`, `@>`, `<@`, `~`, `~*`

## Índice GIN

### Descripción
El índice GIN (Generalized Inverted Index) es ideal para búsquedas de texto completo y datos que contienen múltiples valores.

### Cuándo Usarlo
- Para columnas que contienen arrays o documentos JSON.
- Ideal para búsquedas de texto completo.

### Cuándo No Usarlo
- No es eficiente para búsquedas de igualdad simples.
- Puede consumir más espacio en disco.

### Escenario de Uso
- **Escenario**: Una tabla de artículos donde necesitas buscar artículos que contienen ciertas palabras clave.
- **Operadores**: `@>`, `<@`, `&&`

## Índice BRIN

### Descripción
El índice BRIN (Block Range INdex) es eficiente para grandes tablas donde los datos están ordenados físicamente.

### Cuándo Usarlo
- Para tablas muy grandes con datos ordenados.
- Ideal para consultas que escanean grandes rangos de datos.

### Cuándo No Usarlo
- No es adecuado para tablas pequeñas.
- No es eficiente para búsquedas de igualdad.

### Escenario de Uso
- **Escenario**: Una tabla de registros de sensores donde los datos están ordenados por fecha y hora.
- **Operadores**: `<`, `<=`, `=`, `>=`, `>`

## Índice SP-GiST

### Descripción
El índice SP-GiST (Space-Partitioned Generalized Search Tree) permite la creación de índices para datos que pueden ser particionados en el espacio, como datos geométricos.

### Cuándo Usarlo
- Para datos espaciales o geométricos.
- Ideal para consultas que requieren particionamiento del espacio, como puntos en un mapa.

### Cuándo No Usarlo
- No es adecuado para datos que no se benefician del particionamiento espacial.
- Puede ser más complejo de configurar y mantener.

### Escenario de Uso
- **Escenario**: Una tabla de ubicaciones geográficas donde necesitas buscar áreas específicas.
- **Operadores**: `&&`, `@>`, `<@`, `~`, `~*`

## Extensión Bloom

### Descripción
La extensión Bloom permite la creación de índices Bloom, que son útiles para columnas con muchos valores distintos.

### Cuándo Usarlo
- Para tablas con muchas columnas y valores distintos.
- Ideal para consultas que involucran múltiples columnas.

### Cuándo No Usarlo
- No es eficiente para búsquedas de igualdad simples.
- Puede consumir más espacio en disco.

### Escenario de Uso
- **Escenario**: Una tabla de productos donde necesitas buscar productos que cumplen con múltiples criterios.
- **Operadores**: `=`, `&&`

https://www.yugabyte.com/blog/postgresql-like-query-performance-variations/#c-collation-or-text_pattern_ops
 ```


# Índices Compuestos vs. Índices No Compuestos  
| Característica               | Índices No Compuestos                  | Índices Compuestos                        |
|------------------------------|----------------------------------------|-------------------------------------------|
| **Número de Columnas**       | Una sola columna                       | Dos o más columnas                        |
| **Uso en Consultas**         | Ideal para consultas que filtran por una sola columna | Ideal para consultas que filtran por múltiples columnas en el orden indexado |
| **Orden de las Columnas**    | No aplica                              | El orden de las columnas es importante, siempre se tiene que usar la primera columna que se coloco en el indice ya que de lo contrario el plan de ejecucion no usara el indice  |
| **Rendimiento**              | Menos costoso en términos de espacio y mantenimiento | Puede mejorar el rendimiento de consultas complejas, pero más costoso en términos de espacio y mantenimiento |
| **Ejemplo de Creación**      | `CREATE INDEX idx_columna ON tabla(columna);` | `CREATE INDEX idx_compuesto ON tabla(columna1, columna2);` |
| **Cuándo Usar**              | Consultas que filtran por una sola columna | Consultas que filtran por múltiples columnas y el orden de filtrado es importante |
| **Cuándo No Usar**           |  Consultas que solo filtran por una columna o el orden de las columnas no es relevante  |Consultas que requieren filtrar por múltiples columnas | 


### Consideraciones Antes de Crear un Índice Compuesto en PostgreSQL

1. **Consultas Comunes**:
   - Evalúa si las consultas más frecuentes filtran por múltiples columnas en el orden en que planeas crear el índice compuesto.
   - Ejemplo: Si las consultas suelen filtrar por `fecha` y `cliente_id`, un índice compuesto en `(fecha, cliente_id)` puede ser beneficioso.

2. **Orden de las Columnas**:
   - El orden de las columnas en el índice es crucial. Un índice en `(columna1, columna2)` es útil para consultas que filtran por `columna1` o por `columna1` y `columna2`, pero no para consultas que solo filtran por `columna2`, siempre se tiene que usar la primera columna que se coloco en el indice ya que de lo contrario el plan de ejecucion no usara el indice, no importa si agregas mas columnas, si las columnas estan revueltas, pero siempre debes de usar la primera columna del indice ya que si no se coloca la primera columna, no se usara el indice que creaste  y generara mas costo realizar la consulta 

3. **Espacio en Disco**:
   - Los índices compuestos ocupan más espacio en disco que los índices simples. Asegúrate de que el beneficio en rendimiento justifique el espacio adicional.

4. **Costos de Mantenimiento**:
   - Considera el costo de mantenimiento del índice. Las actualizaciones en las columnas indexadas pueden ser más costosas en términos de tiempo y recursos.

5. **Rendimiento de Consultas**:
   - Un índice compuesto puede mejorar el rendimiento de consultas complejas, pero solo si las consultas utilizan todas las columnas en el orden especificado.
   - Ejemplo: Un índice en `(fecha ASC, cliente_id DESC)` es útil para consultas que ordenan por `fecha ASC` y `cliente_id DESC`.

 
7. **Espacio Adicional y Fragmentación**:
   - Los índices ordenados pueden requerir más espacio y pueden aumentar la fragmentación. Evalúa si esto es aceptable para tu caso de uso.

 

# Lógica de la indexación:
Cuando se crea un índice en PostgreSQL, el motor de la base de datos crea una estructura de datos adicional que contiene valores de la columna indexada y los punteros a las ubicaciones de los registros correspondientes en la tabla principal. Esto permite que las búsquedas sean mucho más eficientes, ya que PostgreSQL no necesita escanear toda la tabla, sino que puede saltar directamente a las ubicaciones relevantes a través del índice.
Es importante tener en cuenta que mientras que los índices aceleran las consultas de búsqueda, también tienen un costo en términos de rendimiento de escritura, ya que cada vez que se inserta, actualiza o elimina un registro, el índice debe actualizarse para reflejar esos cambios.

# ¿Qué es la reindexación en PostgreSQL?
La reindexación en PostgreSQL es un proceso en el que se reconstruyen los índices existentes en una tabla para mejorar su rendimiento y eficiencia. A medida que una base de datos se utiliza y cambia, los índices pueden volverse fragmentados y desorganizados, lo que afecta negativamente el rendimiento de las consultas. La reindexación ayuda a resolver este problema al reconstruir los índices, eliminando la fragmentación y mejorando la eficiencia de las búsquedas.

# Por qué es importante la reindexación?
La reindexación es importante porque los índices desorganizados pueden llevar a consultas lentas y degradación general del rendimiento de la base de datos. Con el tiempo, a medida que los datos se insertan, actualizan y eliminan, los índices pueden perder eficiencia. La reindexación periódica garantiza que los índices estén optimizados para la consulta y mantiene el rendimiento de la base de datos en un nivel óptimo.

# Borar un index
	DROP INDEX IF EXISTS public.index_emp_nombre ;


## Usar CLUSTER
El propósito de este comando es mejorar el rendimiento de las consultas que utilizan un indice.  agrupa  la tabla el índice indicado, los datos se almacenan físicamente en el orden del índice, lo que puede acelerar las búsquedas y mejorar la eficiencia de las consultas.

```SQL
	-- configurarle un cluster a una tabla
	ALTER TABLE IF EXISTS public.table_test CLUSTER ON idx_table_test;

  	-- Indicas que ejecute los clusteres 
 	cluster;
```



 
# ¿Para qué sirve `CREATE INDEX CONCURRENTLY`?

1. **Evitar bloqueos**:
   - A diferencia del comando `CREATE INDEX` estándar, que bloquea la tabla para operaciones de escritura mientras se crea el índice, `CREATE INDEX CONCURRENTLY` permite que las operaciones de escritura continúen. Esto es especialmente útil en bases de datos de producción donde no se puede permitir el tiempo de inactividad.

2. **Proceso en segundo plano**:
   - El índice se crea en segundo plano, lo que puede llevar más tiempo que un índice creado de manera estándar, pero permite que la base de datos siga siendo accesible para los usuarios.

3. **Uso típico**:
   - Es ideal para tablas grandes donde el tiempo de creación del índice podría ser significativo y el bloqueo de la tabla no es una opción viable.

### Ejemplo de uso

```sql
CREATE INDEX CONCURRENTLY idx_clustered_fecha ON pedidos (fecha desc );
```

### Consideraciones

- **Rendimiento**: La creación concurrente de índices puede ser más lenta que la creación estándar debido a la necesidad de manejar las operaciones de escritura en curso.
- **Fallos**: Si la creación del índice falla, puede dejar la tabla en un estado inconsistente, por lo que es importante revisar los logs y asegurarse de que el índice se haya creado correctamente.

Este comando es muy útil para mantener la disponibilidad de la base de datos mientras se realizan tareas de mantenimiento importantes¹.

 



# EJEMPLOS DE CREACION DE INDEX Y CLUSTER
```SQL

-- Crear la tabla
postgres@auditoria# CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,  -- indisprimary
    cliente_id INT,
    producto_id INT,
    cantidad INT,
    precio DECIMAL,
    fecha TIMESTAMP,
    estado VARCHAR(20),
    email VARCHAR(100),
    nombre VARCHAR(100)
);
CREATE TABLE
Time: 59.525 ms


-- Insertar datos en la tabla pedidos
INSERT INTO pedidos (cliente_id, producto_id, cantidad, precio, fecha, estado, email, nombre)
VALUES
(1, 101, 2, 19.99, '2024-08-01 10:00:00', 'pendiente', 'cliente1@example.com', 'Juan Pérez'),
(2, 102, 1, 49.99, '2024-08-02 11:30:00', 'completado', 'cliente2@example.com', 'María López'),
(3, 103, 5, 9.99, '2024-08-03 14:45:00', 'pendiente', 'cliente3@example.com', 'Carlos García'),
(4, 104, 3, 29.99, '2024-08-04 09:15:00', 'cancelado', 'cliente4@example.com', 'Ana Martínez'),
(5, 105, 4, 15.99, '2024-08-05 16:00:00', 'pendiente', 'cliente5@example.com', 'Luis Fernández');


postgres@auditoria# select * from pedidos;
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
| id | cliente_id | producto_id | cantidad | precio |        fecha        |   estado   |        email         |     nombre     |
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
|  1 |          1 |         101 |        2 |  19.99 | 2024-08-01 10:00:00 | pendiente  | cliente1@example.com | Juan Pérez     |
|  2 |          2 |         102 |        1 |  49.99 | 2024-08-02 11:30:00 | completado | cliente2@example.com | María López    |
|  3 |          3 |         103 |        5 |   9.99 | 2024-08-03 14:45:00 | pendiente  | cliente3@example.com | Carlos García  |
|  4 |          4 |         104 |        3 |  29.99 | 2024-08-04 09:15:00 | cancelado  | cliente4@example.com | Ana Martínez   |
|  5 |          5 |         105 |        4 |  15.99 | 2024-08-05 16:00:00 | pendiente  | cliente5@example.com | Luis Fernández |
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+


--> Crear un índice indisclustered en la columna fecha
--> Este comando realiza la operación de agrupamiento inmediatamente, reordenando físicamente las filas de la tabla pedidos según el índice idx_clustered_fecha.

postgres@auditoria# CREATE INDEX idx_clustered_fecha ON pedidos (fecha desc );
CREATE INDEX
Time: 3.221 ms

postgres@auditoria# CLUSTER pedidos USING idx_clustered_fecha;  -- indisclustered
CLUSTER
Time: 29.073 ms



postgres@auditoria# select indexrelid::regclass,indrelid::regclass,* from pg_index where indexrelid::regclass = 'idx_clustered_fecha'::regclass ;
+-[ RECORD 1 ]--------+---------------------+
| indexrelid          | idx_clustered_fecha |
| indrelid            | pedidos             |
| indexrelid          | 382265              |
| indrelid            | 382257              |
| indnatts            | 1                   |
| indnkeyatts         | 1                   |
| indisunique         | f                   |
| indnullsnotdistinct | f                   |
| indisprimary        | f                   |
| indisexclusion      | f                   |
| indimmediate        | t                   |
| indisclustered      | t                   | <--- indisclustered
| indisvalid          | t                   |
| indcheckxmin        | f                   |
| indisready          | t                   |
| indislive           | t                   |
| indisreplident      | f                   |
| indkey              | 6                   |
| indcollation        | 0                   |
| indclass            | 3128                |
| indoption           | 3                   |
| indexprs            | NULL                |
| indpred             | NULL                |
+---------------------+---------------------+


 
postgres@auditoria# select * from pedidos;
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
| id | cliente_id | producto_id | cantidad | precio |        fecha        |   estado   |        email         |     nombre     |
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
|  5 |          5 |         105 |        4 |  15.99 | 2024-08-05 16:00:00 | pendiente  | cliente5@example.com | Luis Fernández |
|  4 |          4 |         104 |        3 |  29.99 | 2024-08-04 09:15:00 | cancelado  | cliente4@example.com | Ana Martínez   |
|  3 |          3 |         103 |        5 |   9.99 | 2024-08-03 14:45:00 | pendiente  | cliente3@example.com | Carlos García  |
|  2 |          2 |         102 |        1 |  49.99 | 2024-08-02 11:30:00 | completado | cliente2@example.com | María López    |
|  1 |          1 |         101 |        2 |  19.99 | 2024-08-01 10:00:00 | pendiente  | cliente1@example.com | Juan Pérez     |
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
(5 rows)



postgres@auditoria# drop INDEX  idx_clustered_fecha;
DROP INDEX
Time: 7.612 ms


---> Aunque borres el index Cluster, la tabla seguira ordenada 
postgres@auditoria#  select * from pedidos;
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
| id | cliente_id | producto_id | cantidad | precio |        fecha        |   estado   |        email         |     nombre     |
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
|  5 |          5 |         105 |        4 |  15.99 | 2024-08-05 16:00:00 | pendiente  | cliente5@example.com | Luis Fernández |
|  4 |          4 |         104 |        3 |  29.99 | 2024-08-04 09:15:00 | cancelado  | cliente4@example.com | Ana Martínez   |
|  3 |          3 |         103 |        5 |   9.99 | 2024-08-03 14:45:00 | pendiente  | cliente3@example.com | Carlos García  |
|  2 |          2 |         102 |        1 |  49.99 | 2024-08-02 11:30:00 | completado | cliente2@example.com | María López    |
|  1 |          1 |         101 |        2 |  19.99 | 2024-08-01 10:00:00 | pendiente  | cliente1@example.com | Juan Pérez     |
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
(5 rows)





postgres@auditoria# select * from pg_stat_user_indexes where relname = 'pedidos';
+--------+------------+------------+---------+--------------+----------+---------------+--------------+---------------+
| relid  | indexrelid | schemaname | relname | indexrelname | idx_scan | last_idx_scan | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+---------+--------------+----------+---------------+--------------+---------------+
| 382275 |     382281 | public     | pedidos | pedidos_pkey |        0 | NULL          |            0 |             0 |
+--------+------------+------------+---------+--------------+----------+---------------+--------------+---------------+
(1 row)



--->  Este comando establece el índice pedidos_pkey como el índice de agrupamiento predeterminado para la tabla pedidos.  No realiza la operación de agrupamiento inmediatamente. Simplemente indica que, en futuras operaciones de agrupamiento (cuando se use el comando CLUSTER sin especificar un índice), PostgreSQL utilizará este índice.

postgres@auditoria# ALTER TABLE IF EXISTS public.pedidos CLUSTER ON pedidos_pkey;
ALTER TABLE
Time: 1.476 ms

postgres@auditoria# cluster;
CLUSTER
Time: 29.078 ms


postgres@auditoria# select * from pedidos;
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
| id | cliente_id | producto_id | cantidad | precio |        fecha        |   estado   |        email         |     nombre     |
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
|  1 |          1 |         101 |        2 |  19.99 | 2024-08-01 10:00:00 | pendiente  | cliente1@example.com | Juan Pérez     |
|  2 |          2 |         102 |        1 |  49.99 | 2024-08-02 11:30:00 | completado | cliente2@example.com | María López    |
|  3 |          3 |         103 |        5 |   9.99 | 2024-08-03 14:45:00 | pendiente  | cliente3@example.com | Carlos García  |
|  4 |          4 |         104 |        3 |  29.99 | 2024-08-04 09:15:00 | cancelado  | cliente4@example.com | Ana Martínez   |
|  5 |          5 |         105 |        4 |  15.99 | 2024-08-05 16:00:00 | pendiente  | cliente5@example.com | Luis Fernández |
+----+------------+-------------+----------+--------+---------------------+------------+----------------------+----------------+
(5 rows)

Time: 0.680 ms








---->  Crear un índice único en la columna email
postgres@auditoria# CREATE UNIQUE INDEX idx_unique_email ON pedidos (email,nombre); -- indisunique
CREATE INDEX
Time: 2.987 ms

postgres@auditoria# select indexrelid::regclass,indrelid::regclass,* from pg_index where indexrelid::regclass = 'idx_unique_email'::regclass ;
+-[ RECORD 1 ]--------+------------------+
| indexrelid          | idx_unique_email |
| indrelid            | pedidos          |
| indexrelid          | 382307           |
| indrelid            | 382275           |
| indnatts            | 1                |
| indnkeyatts         | 1                |
| indisunique         | t                | <--- Indica que es unico 
| indnullsnotdistinct | f                |
| indisprimary        | f                |
| indisexclusion      | f                |
| indimmediate        | t                |
| indisclustered      | f                |
| indisvalid          | t                |
| indcheckxmin        | f                |
| indisready          | t                |
| indislive           | t                |
| indisreplident      | f                |
| indkey              | 8                |
| indcollation        | 100              |
| indclass            | 3126             |
| indoption           | 0                |
| indexprs            | NULL             |
| indpred             | NULL             |
+---------------------+------------------+


postgres@auditoria# insert into pedidos(email,nombre) select 'cliente1@example.com','Juan Pérez';
ERROR:  duplicate key value violates unique constraint "idx_unique_email"
DETAIL:  Key (email, nombre)=(cliente1@example.com, Juan Pérez) already exists.
Time: 0.680 ms






----> Crear un índice normal en la columna precio y verificar su validez
CREATE INDEX idx_valido ON pedidos (precio);


postgres@auditoria# explain analyze select * from pedidos where precio = 19.99;;
+----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                      |
+----------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_valido on pedidos  (cost=0.13..8.15 rows=1 width=550) (actual time=0.062..0.064 rows=1 loops=1) | <-- Indico ue uso el index idx_valido
|   Index Cond: (precio = 19.99)                                                                                       |
| Planning Time: 0.075 ms                                                                                              |
| Execution Time: 0.079 ms                                                                                             |
+----------------------------------------------------------------------------------------------------------------------+
(4 rows)


postgres@auditoria# SELECT * FROM pg_index WHERE indexrelid = 'idx_valido'::regclass AND indisvalid;  
+-[ RECORD 1 ]--------+--------+
| indexrelid          | 382309 |
| indrelid            | 382275 |
| indnatts            | 1      |
| indnkeyatts         | 1      |
| indisunique         | f      |
| indnullsnotdistinct | f      |
| indisprimary        | f      |
| indisexclusion      | f      |
| indimmediate        | t      |
| indisclustered      | f      |
| indisvalid          | t      | ---> indisvalid: Indica si el índice es válido para ser utilizado por el optimizador de consultas. Un índice puede ser inválido si está en proceso de creación o si ha fallado una operación de mantenimiento.
| indcheckxmin        | f      |
| indisready          | t      |
| indislive           | t      |
| indisreplident      | f      |
| indkey              | 5      |
| indcollation        | 0      |
| indclass            | 3125   |
| indoption           | 0      |
| indexprs            | NULL   |
| indpred             | NULL   |
+---------------------+--------+

 
 
 
 
----> Crear Índice Compuestos, es muy importante que las columnas del indice se usen en la consulta, principalmente la primera columna del indice
--- ya que puede haber ocasiones en las que no use el indice 
postgres@auditoria# explain analyze select * from pedidos where precio = 9.99 and fecha = '2024-08-03 14:45:00';
+----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                      |
+----------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_valido on pedidos  (cost=0.13..8.15 rows=1 width=550) (actual time=0.017..0.019 rows=1 loops=1) |
|   Index Cond: (precio = 9.99)                                                                                        |
|   Filter: (fecha = '2024-08-03 14:45:00'::timestamp without time zone)                                               |
| Planning Time: 0.086 ms                                                                                              |
| Execution Time: 0.035 ms                                                                                             |
+----------------------------------------------------------------------------------------------------------------------+
(5 rows)

postgres@auditoria# CREATE INDEX   idx_Compuestos_pedidos ON pedidos USING btree (precio ASC , fecha desc,estado );
CREATE INDEX
Time: 2.902 ms

postgres@auditoria# explain analyze select * from pedidos where precio = 9.99 and fecha = '2024-08-03 14:45:00' and estado = 'pendiente';
+-------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                QUERY PLAN                                                                 |
+-------------------------------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_compuestos_pedidos on pedidos  (cost=0.13..8.15 rows=1 width=550) (actual time=0.017..0.018 rows=1 loops=1)          |
|   Index Cond: ((precio = 9.99) AND (fecha = '2024-08-03 14:45:00'::timestamp without time zone) AND ((estado)::text = 'pendiente'::text)) |
| Planning Time: 0.251 ms                                                                                                                   |
| Execution Time: 0.034 ms                                                                                                                  |
+-------------------------------------------------------------------------------------------------------------------------------------------+
(4 rows)


postgres@auditoria# explain analyze select * from pedidos where precio = 9.99 ;
+----------------------------------------------------------------------------------------------------------------------------------+
|                                                            QUERY PLAN                                                            |
+----------------------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_compuestos_pedidos on pedidos  (cost=0.13..8.15 rows=1 width=550) (actual time=0.021..0.023 rows=1 loops=1) |
|   Index Cond: (precio = 9.99)                                                                                                    |
| Planning Time: 0.109 ms                                                                                                          |
| Execution Time: 0.084 ms                                                                                                         |
+----------------------------------------------------------------------------------------------------------------------------------+
(4 rows)




 

----->  Crear un índice de expresión basado en la longitud de la columna nombre

postgres@auditoria# explain analyze select length(nombre),* from pedidos where length(nombre) >= 13;
+-----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                       |
+-----------------------------------------------------------------------------------------------------------------------+
| Seq Scan on pedidos  (cost=10000000000.00..10000000001.08 rows=2 width=554) (actual time=0.016..0.018 rows=2 loops=1) |
|   Filter: (length((nombre)::text) >= 13)                                                                              |
|   Rows Removed by Filter: 3                                                                                           |
| Planning Time: 0.080 ms                                                                                               |
| Execution Time: 0.039 ms                                                                                              |
+-----------------------------------------------------------------------------------------------------------------------+
(5 rows)


postgres@auditoria# CREATE INDEX idx_expr_length ON pedidos ((length(nombre)));  -- indexprs
CREATE INDEX
Time: 2.362 ms

postgres@auditoria# explain analyze select length(nombre),* from pedidos where length(nombre) >= 13;
+---------------------------------------------------------------------------------------------------------------------------+
|                                                        QUERY PLAN                                                         |
+---------------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_expr_length on pedidos  (cost=0.13..8.17 rows=2 width=554) (actual time=0.031..0.033 rows=2 loops=1) |
|   Index Cond: (length((nombre)::text) >= 13)                                                                              |
| Planning Time: 0.381 ms                                                                                                   |
| Execution Time: 0.058 ms                                                                                                  |
+---------------------------------------------------------------------------------------------------------------------------+
(4 rows)


---- La columna indexprs ya no es null esto quiere decir que es un index con expresiones 
postgres@auditoria# SELECT * FROM pg_index WHERE indexrelid = 'idx_expr_length'::regclass ;
+-[ RECORD 1 ]--------+--------+
| indexrelid          | 382310 |
| indrelid            | 382275 |
| indnatts            | 1      |
| indnkeyatts         | 1      |
| indisunique         | f      |
| indnullsnotdistinct | f      |
| indisprimary        | f      |
| indisexclusion      | f      |
| indimmediate        | t      |
| indisclustered      | f      |
| indisvalid          | t      |
| indcheckxmin        | f      |
| indisready          | t      |
| indislive           | t      |
| indisreplident      | f      |
| indkey              | 0      |
| indcollation        | 0      |
| indclass            | 1978   |
| indoption           | 0      |
| indexprs            | ({FUNCEXPR :funcid 1317 :funcresulttype 23 :funcretset false :funcvariadic false :funcformat 0 :funccollid 0 :inputcollid
100 :args ({RELABELTYPE :arg {VAR :varno 1 :varattno 9 :vartype 1043 :vartypmod 104 :varcollid 100 :varnullingrels (b) :varlevelsup 0 :varnosyn 1
:varattnosyn 9 :location 49} :resulttype 25 :resulttypmod -1 :resultcollid 100 :relabelformat 2 :location -1}) :location 42}) |   
| indpred             | NULL   |
+---------------------+--------+






----->  Crear un índice parcial/Condicional en la columna fecha para los pedidos en estado 'pendiente'
--- Un índice parcial es un índice que solo incluye las filas que cumplen con una condición específica.
postgres@auditoria# CREATE INDEX idx_parcial_pendiente ON pedidos (fecha) WHERE estado = 'pendiente';
CREATE INDEX
Time: 3.191 ms


postgres@auditoria# explain analyze select * from pedidos where estado =  'completado';
+-----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                       |
+-----------------------------------------------------------------------------------------------------------------------+
| Seq Scan on pedidos  (cost=10000000000.00..10000000001.07 rows=1 width=554) (actual time=0.014..0.016 rows=1 loops=1) |
|   Filter: ((estado)::text = 'completado'::text)                                                                       |
|   Rows Removed by Filter: 4                                                                                           |
| Planning Time: 0.103 ms                                                                                               |
| Execution Time: 0.033 ms                                                                                              |
+-----------------------------------------------------------------------------------------------------------------------+
(5 rows)

postgres@auditoria# explain analyze select * from pedidos where estado =  'pendiente';
+---------------------------------------------------------------------------------------------------------------------------------+
|                                                           QUERY PLAN                                                            |
+---------------------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_parcial_pendiente on pedidos  (cost=0.13..8.15 rows=1 width=554) (actual time=0.077..0.081 rows=3 loops=1) |
| Planning Time: 0.115 ms                                                                                                         |
| Execution Time: 0.103 ms                                                                                                        |
+---------------------------------------------------------------------------------------------------------------------------------+
(3 rows)


---- La columna indpred no se encuentra vacia, por lo cual es un indice parcial
postgres@auditoria#  SELECT * FROM pg_index WHERE indexrelid = 'idx_parcial_pendiente'::regclass ;
+-[ RECORD 1 ]--------+--------+
| indexrelid          | 382311 |
| indrelid            | 382275 |
| indnatts            | 1      |
| indnkeyatts         | 1      |
| indisunique         | f      |
| indnullsnotdistinct | f      |
| indisprimary        | f      |
| indisexclusion      | f      |
| indimmediate        | t      |
| indisclustered      | f      |
| indisvalid          | t      |
| indcheckxmin        | f      |
| indisready          | t      |
| indislive           | t      |
| indisreplident      | f      |
| indkey              | 6      |
| indcollation        | 0      |
| indclass            | 3128   |
| indoption           | 0      |
| indexprs            | NULL   |
| indpred             | {OPEXPR :opno 98 :opfuncid 67 :opresulttype 16 :opretset false :opcollid 0 :inputcollid 100 :args ({RELABELTYPE :arg {VAR
:varno 1 :varattno 7 :vartype 1043 :vartypmod 24 :varcollid 100 :varnullingrels (b) :varlevelsup 0 :varnosyn 1 :varattnosyn 7 :location 60} :resul
ttype 25 :resulttypmod -1 :resultcollid 100 :relabelformat 2 :location -1} {CONST :consttype 25 :consttypmod -1 :constcollid 100 :constlen -1 :con
stbyval false :constisnull false :location 69 :constvalue 13 [ 52 0 0 0 112 101 110 100 105 101 110 116 101 ]}) :location 67} |
+---------------------+--------+


 

postgres@auditoria# select * from pg_stat_user_indexes where relname = 'pedidos';
+--------+------------+------------+---------+------------------------+----------+-------------------------------+--------------+---------------+
| relid  | indexrelid | schemaname | relname |      indexrelname      | idx_scan |         last_idx_scan         | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+---------+------------------------+----------+-------------------------------+--------------+---------------+
| 382275 |     382281 | public     | pedidos | pedidos_pkey           |        0 | NULL                          |            0 |             0 |
| 382275 |     382308 | public     | pedidos | idx_unique_email       |        0 | NULL                          |            0 |             0 |
| 382275 |     382309 | public     | pedidos | idx_valido             |        6 | 2024-09-03 18:17:49.489201-07 |            6 |             6 |
| 382275 |     382310 | public     | pedidos | idx_expr_length        |        2 | 2024-09-03 18:16:51.096757-07 |            4 |             4 |
| 382275 |     382314 | public     | pedidos | idx_compuestos_pedidos |        4 | 2024-09-03 18:23:01.715724-07 |            6 |             6 |
+--------+------------+------------+---------+------------------------+----------+-------------------------------+--------------+---------------+
(5 rows)



postgres@auditoria# select * from pg_indexes where tablename = 'pedidos';
| schemaname | tablename |       indexname       | tablespace |                                                      indexdef
+------------+-----------+-----------------------+------------+---------------------------------------------------------------------------------------------------------------------+
| public     | pedidos   | pedidos_pkey           | NULL       | CREATE UNIQUE INDEX pedidos_pkey ON public.pedidos USING btree (id)             |
| public     | pedidos   | idx_unique_email       | NULL       | CREATE UNIQUE INDEX idx_unique_email ON public.pedidos USING btree (email, nombre)             |
| public     | pedidos   | idx_valido             | NULL       | CREATE INDEX idx_valido ON public.pedidos USING btree (precio)              |
| public     | pedidos   | idx_expr_length        | NULL       | CREATE INDEX idx_expr_length ON public.pedidos USING btree (length((nombre)::text))            |
| public     | pedidos   | idx_compuestos_pedidos | NULL       | CREATE INDEX idx_compuestos_pedidos ON public.pedidos USING btree (precio, fechaDESC, estado) |
+------------+-----------+-----------------------+------------+---------------------------------------------------------------------------------------------------------------------+


postgres@auditoria# drop index idx_unique_email;
DROP INDEX
Time: 12.255 ms
postgres@auditoria# drop index idx_valido;
DROP INDEX
Time: 9.470 ms
postgres@auditoria# drop index idx_expr_length;
DROP INDEX
Time: 9.584 ms
postgres@auditoria# drop index idx_compuestos_pedidos;
DROP INDEX
Time: 8.255 ms





-------> Crear un index   GIN con la extension trigram  para los ilike 

/* CREAREMOS UN INDICE NORMAL */
postgres@auditoria#  CREATE INDEX   idx_pedidos ON pedidos USING btree (estado );
CREATE INDEX
Time: 2.679 ms



postgres@auditoria# explain analyze select * from pedidos where  estado ilike  '%pen%' ;
+-----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                       |
+-----------------------------------------------------------------------------------------------------------------------+
| Seq Scan on pedidos  (cost=10000000000.00..10000000001.06 rows=1 width=550) (actual time=0.018..0.025 rows=3 loops=1) | <-- COMO VEMOS NO USO EL INDEX 
|   Filter: ((estado)::text ~~* '%pen%'::text)                                                                          |
|   Rows Removed by Filter: 2                                                                                           |
| Planning Time: 0.414 ms                                                                                               |
| Execution Time: 0.044 ms                                                                                              |
+-----------------------------------------------------------------------------------------------------------------------+
(5 rows)



postgres@auditoria# CREATE EXTENSION pg_trgm;
CREATE EXTENSION
Time: 62.879 ms

postgres@auditoria# CREATE INDEX idx_estado_trgm ON pedidos USING GIN (estado gin_trgm_ops);
CREATE INDEX
Time: 2.783 ms


postgres@auditoria# explain analyze select * from pedidos where  estado ilike  '%pen%' ;
+------------------------------------------------------------------------------------------------------------------------+
|                                                       QUERY PLAN                                                       |
+------------------------------------------------------------------------------------------------------------------------+
| Bitmap Heap Scan on pedidos  (cost=8.53..12.54 rows=1 width=550) (actual time=0.035..0.038 rows=3 loops=1)             |
|   Recheck Cond: ((estado)::text ~~* '%pen%'::text)                                                                     |
|   Heap Blocks: exact=1                                                                                                 |
|   ->  Bitmap Index Scan on idx_estado_trgm  (cost=0.00..8.53 rows=1 width=0) (actual time=0.010..0.010 rows=3 loops=1) | <--- AQUI SI USO EL INDEX 
|         Index Cond: ((estado)::text ~~* '%pen%'::text)                                                                 |
| Planning Time: 0.258 ms                                                                                                |
| Execution Time: 0.062 ms                                                                                               |
+------------------------------------------------------------------------------------------------------------------------+
(7 rows)



postgres@auditoria# drop index idx_estado_trgm;
DROP INDEX
Time: 8.139 ms





----->  Indices  para los like 
----- Crear El índice  text_pattern_ops en PostgreSQL se utiliza con índices B-Tree principalmente para mejorar el rendimiento de las consultas que involucran patrones de búsqueda con LIKE o expresiones regulares en columnas de tipo text, varchar o char.
--- no sirve para los ilike 
--- si tus consultas utilizan operadores de comparación estándar como <, <=, >, >=, este índice no será útil
---  Si tu base de datos usa la configuración regional “C”, no necesitas text_pattern_ops porque un índice con la clase de operador predeterminada ya es adecuado para consultas de patrones1.


postgres@auditoria#  explain analyze select * from pedidos where  estado like  'pen%' ;
+-----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                       |
+-----------------------------------------------------------------------------------------------------------------------+
| Seq Scan on pedidos  (cost=10000000000.00..10000000001.06 rows=1 width=550) (actual time=0.008..0.010 rows=3 loops=1) |
|   Filter: ((estado)::text ~~ 'pen%'::text)                                                                            |
|   Rows Removed by Filter: 2                                                                                           |
| Planning Time: 0.115 ms                                                                                               |
| Execution Time: 0.027 ms                                                                                              |
+-----------------------------------------------------------------------------------------------------------------------+
(5 rows)
Time: 0.580 ms


postgres@auditoria#  explain analyze SELECT * FROM pedidos WHERE estado ~ '^pendi';
+-----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                       |
+-----------------------------------------------------------------------------------------------------------------------+
| Seq Scan on pedidos  (cost=10000000000.00..10000000001.06 rows=1 width=550) (actual time=0.021..0.028 rows=3 loops=1) |
|   Filter: ((estado)::text ~ '^pendi'::text)                                                                           |
|   Rows Removed by Filter: 2                                                                                           |
| Planning Time: 0.088 ms                                                                                               |
| Execution Time: 0.046 ms                                                                                              |
+-----------------------------------------------------------------------------------------------------------------------+
(5 rows)




postgres@auditoria# CREATE INDEX idx_pedidos_text_pattern_ops ON pedidos(estado text_pattern_ops);  -- C collation or text_pattern_ops
CREATE INDEX
Time: 2.966 ms

 
postgres@auditoria# explain analyze select * from pedidos where  estado like  'pen%' ;
+----------------------------------------------------------------------------------------------------------------------------------------+
|                                                               QUERY PLAN                                                               |
+----------------------------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_pedidos_text_pattern_ops on pedidos  (cost=0.13..8.15 rows=1 width=550) (actual time=0.015..0.017 rows=3 loops=1) | <--- usa el index
|   Index Cond: (((estado)::text ~>=~ 'pen'::text) AND ((estado)::text ~<~ 'peo'::text))                                                 |
|   Filter: ((estado)::text ~~ 'pen%'::text)                                                                                             |
| Planning Time: 0.180 ms                                                                                                                |
| Execution Time: 0.033 ms                                                                                                               |
+----------------------------------------------------------------------------------------------------------------------------------------+
(5 rows)
Time: 0.665 ms

postgres@auditoria# explain analyze select * from pedidos where  estado like  '%pen%' ;
+-----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                       |
+-----------------------------------------------------------------------------------------------------------------------+
| Seq Scan on pedidos  (cost=10000000000.00..10000000001.06 rows=1 width=550) (actual time=0.014..0.017 rows=3 loops=1) | <--- no usa el index
|   Filter: ((estado)::text ~~ '%pen%'::text)                                                                           |
|   Rows Removed by Filter: 2                                                                                           |
| Planning Time: 0.077 ms                                                                                               |
| Execution Time: 0.035 ms                                                                                              |
+-----------------------------------------------------------------------------------------------------------------------+
(5 rows)
Time: 0.628 ms

postgres@auditoria# explain analyze select * from pedidos where  estado like  '%pen' ;
+-----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                       |
+-----------------------------------------------------------------------------------------------------------------------+
| Seq Scan on pedidos  (cost=10000000000.00..10000000001.06 rows=1 width=550) (actual time=0.013..0.014 rows=0 loops=1) | <--- no usa el index
|   Filter: ((estado)::text ~~ '%pen'::text)                                                                            |
|   Rows Removed by Filter: 5                                                                                           |
| Planning Time: 0.061 ms                                                                                               |
| Execution Time: 0.027 ms                                                                                              |
+-----------------------------------------------------------------------------------------------------------------------+
(5 rows)
Time: 0.475 ms

postgres@auditoria#  explain analyze SELECT * FROM pedidos WHERE estado ~ '^pendi';
+----------------------------------------------------------------------------------------------------------------------------------------+
|                                                               QUERY PLAN                                                               |
+----------------------------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_pedidos_text_pattern_ops on pedidos  (cost=0.13..8.15 rows=1 width=550) (actual time=0.031..0.036 rows=3 loops=1) | <--- usa el index
|   Index Cond: (((estado)::text ~>=~ 'pendi'::text) AND ((estado)::text ~<~ 'pendj'::text))                                             |
|   Filter: ((estado)::text ~ '^pendi'::text)                                                                                            |
| Planning Time: 0.100 ms                                                                                                                |
| Execution Time: 0.054 ms                                                                                                               |
+----------------------------------------------------------------------------------------------------------------------------------------+
(5 rows)

Time: 0.567 ms




postgres@auditoria# drop index idx_pedidos_text_pattern_ops ;
DROP INDEX
Time: 8.022 ms



--- Indice  Full-Text Search 

postgres@auditoria# CREATE INDEX idx_pedidos_gin ON pedidos USING GIN (to_tsvector('spanish', estado));
CREATE INDEX
Time: 30.887 ms


postgres@auditoria# explain analyze SELECT * FROM pedidos WHERE to_tsvector('spanish', estado) @@ to_tsquery('spanish','pen');
+------------------------------------------------------------------------------------------------------------------------+
|                                                       QUERY PLAN                                                       |
+------------------------------------------------------------------------------------------------------------------------+
| Bitmap Heap Scan on pedidos  (cost=8.51..12.78 rows=1 width=550) (actual time=0.015..0.016 rows=3 loops=1)             |
|   Recheck Cond: (to_tsvector('spanish'::regconfig, (estado)::text) @@ '''pendient'''::tsquery)                         |
|   Heap Blocks: exact=1                                                                                                 |
|   ->  Bitmap Index Scan on idx_pedidos_gin  (cost=0.00..8.51 rows=1 width=0) (actual time=0.010..0.010 rows=3 loops=1) |
|         Index Cond: (to_tsvector('spanish'::regconfig, (estado)::text) @@ '''pendient'''::tsquery)                     |
| Planning Time: 0.098 ms                                                                                                |
| Execution Time: 0.035 ms                                                                                               |
+------------------------------------------------------------------------------------------------------------------------+


postgres@auditoria# explain analyze  SELECT * FROM pedidos WHERE to_tsvector('spanish', estado) @@ plainto_tsquery('spanish','conte');
+------------------------------------------------------------------------------------------------------------------------+
|                                                       QUERY PLAN                                                       |
+------------------------------------------------------------------------------------------------------------------------+
| Bitmap Heap Scan on pedidos  (cost=8.51..12.78 rows=1 width=550) (actual time=0.013..0.014 rows=0 loops=1)             | <--- no retorno resultados rows=0
|   Recheck Cond: (to_tsvector('spanish'::regconfig, (estado)::text) @@ '''cont'''::tsquery)                             |
|   ->  Bitmap Index Scan on idx_pedidos_gin  (cost=0.00..8.51 rows=1 width=0) (actual time=0.010..0.010 rows=0 loops=1) |
|         Index Cond: (to_tsvector('spanish'::regconfig, (estado)::text) @@ '''cont'''::tsquery)                         |
| Planning Time: 0.123 ms                                                                                                |
| Execution Time: 0.042 ms                                                                                               |
+------------------------------------------------------------------------------------------------------------------------+
(6 rows)


-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

### Crear la Tabla y el Índice para columnas type array 

Creamos la tabla y el índice GIN como antes:

--- drop table mi_tabla;

CREATE TABLE mi_tabla (
    id SERIAL PRIMARY KEY,
    mi_array INTEGER[]
);



### Insertar Datos de Prueba

INSERT INTO mi_tabla (mi_array)
SELECT array_agg((random() * 100)::int)
FROM generate_series(1, 10000) AS s(i),
     generate_series(1, 10) AS t(j)
GROUP BY s.i;


--- truncate table mi_tabla RESTART IDENTITY ; 



### Consultas de Prueba

Ahora, puedes realizar consultas para verificar la eficiencia del índice.

postgres@postgres#  SELECT * FROM mi_tabla WHERE mi_array && ARRAY[10, 20, 30] limit 10;
+----+---------------------------------+
| id |            mi_array             |
+----+---------------------------------+
|  3 | {56,88,20,65,21,84,12,77,43,66} |
|  4 | {42,14,76,68,15,20,72,93,43,97} |
|  5 | {55,49,17,58,83,74,10,49,52,22} |
|  7 | {81,43,75,65,1,58,24,30,62,16}  |
| 14 | {39,3,37,20,58,88,11,54,50,80}  |
| 15 | {30,76,91,23,48,28,43,50,22,77} |
| 19 | {68,10,32,83,66,34,60,56,94,5}  |
| 21 | {45,73,58,79,35,20,51,36,84,38} |
| 25 | {49,92,40,10,32,34,39,92,94,81} |
| 31 | {60,76,88,20,59,88,63,5,52,26}  |
+----+---------------------------------+
(10 rows)


postgres@postgres# explain analyze SELECT * FROM mi_tabla WHERE mi_array && ARRAY[10, 20, 30];
+----------------------------------------------------------------------------------------------------------+
|                                                QUERY PLAN                                                |
+----------------------------------------------------------------------------------------------------------+
| Seq Scan on mi_tabla  (cost=0.00..320.85 rows=235 width=36) (actual time=0.029..3.365 rows=2594 loops=1) |
|   Filter: (mi_array && '{10,20,30}'::integer[])                                                          |
|   Rows Removed by Filter: 7406                                                                           |
| Planning Time: 0.061 ms                                                                                  |
| Execution Time: 3.463 ms                                                                                 |
+----------------------------------------------------------------------------------------------------------+
(5 rows)


 
postgres@postgres#  CREATE INDEX  index_mi_tabla ON mi_tabla(  mi_array );
CREATE INDEX
Time: 26.363 ms

postgres@postgres# explain analyze SELECT * FROM mi_tabla WHERE mi_array && ARRAY[10, 20, 30];
+----------------------------------------------------------------------------------------------------------+
|                                                QUERY PLAN                                                |
+----------------------------------------------------------------------------------------------------------+
| Seq Scan on mi_tabla  (cost=0.00..249.00 rows=149 width=36) (actual time=0.025..3.263 rows=2594 loops=1) |
|   Filter: (mi_array && '{10,20,30}'::integer[])                                                          |
|   Rows Removed by Filter: 7406                                                                           |
| Planning Time: 0.201 ms                                                                                  |
| Execution Time: 3.380 ms                                                                                 |
+----------------------------------------------------------------------------------------------------------+
(5 rows)


postgres@postgres# CREATE INDEX idx_mi_array ON mi_tabla USING GIN (mi_array);
CREATE INDEX
Time: 25.851 ms
postgres@postgres# explain analyze SELECT * FROM mi_tabla WHERE mi_array && ARRAY[10, 20, 30];
+---------------------------------------------------------------------------------------------------------------------------+
|                                                        QUERY PLAN                                                         |
+---------------------------------------------------------------------------------------------------------------------------+
| Bitmap Heap Scan on mi_tabla  (cost=30.90..163.23 rows=149 width=36) (actual time=0.304..0.939 rows=2594 loops=1)         |
|   Recheck Cond: (mi_array && '{10,20,30}'::integer[])                                                                     |
|   Heap Blocks: exact=124                                                                                                  |
|   ->  Bitmap Index Scan on idx_mi_array  (cost=0.00..30.86 rows=149 width=0) (actual time=0.284..0.284 rows=2594 loops=1) | <--- uso el index idx_mi_array
|         Index Cond: (mi_array && '{10,20,30}'::integer[])                                                                 |
| Planning Time: 0.202 ms                                                                                                   |
| Execution Time: 1.045 ms                                                                                                  | <--- Mejoro el resultado 
+---------------------------------------------------------------------------------------------------------------------------+
(7 rows)




-- Buscar filas que contengan el valor 50 en el array
EXPLAIN ANALYZE
SELECT * FROM mi_tabla WHERE mi_array @> ARRAY[50];

-- Buscar filas que contengan los valores 20 y 30 en el array
EXPLAIN ANALYZE
SELECT * FROM mi_tabla WHERE mi_array @> ARRAY[20, 30];

-- Buscar filas que contengan cualquier valor del array [10, 20, 30]
EXPLAIN ANALYZE
SELECT * FROM mi_tabla WHERE mi_array && ARRAY[10, 20, 30];


### Operadores de Array en PostgreSQL

1. **Contiene (`@>`)**:
   Verifica si el array de la columna contiene todos los elementos del array proporcionado.

   SELECT * FROM mi_tabla WHERE mi_array @> ARRAY[1, 2];
  

2. **Está contenido (`<@`)**:
   Verifica si todos los elementos del array de la columna están contenidos en el array proporcionado.

   SELECT * FROM mi_tabla WHERE ARRAY[1, 2] <@ mi_array;
  

3. **Superposición (`&&`)**:
   Verifica si hay algún elemento común entre el array de la columna y el array proporcionado.

   SELECT * FROM mi_tabla WHERE mi_array && ARRAY[1, 2];
  

4. **Igualdad (`=`)**:
   Verifica si dos arrays son iguales.

    SELECT * FROM mi_tabla WHERE mi_array = ARRAY[1, 2, 3];
  

5. **Desigualdad (`<>`)**:
   Verifica si dos arrays son diferentes.
   
   SELECT * FROM mi_tabla WHERE mi_array <> ARRAY[1, 2, 3];
  

6. **Concatenación (`||`)**:
   Concatenar dos arrays.
   
   SELECT mi_array || ARRAY[4, 5, 6] FROM mi_tabla;
  

7. **Acceso por índice (`[]`)**:
   Acceder a un elemento específico del array por su índice (los índices empiezan en 1).
   
   SELECT mi_array[1] FROM mi_tabla;
  

8. **Longitud del array (`array_length`)**:
   Obtener la longitud del array.
   
   SELECT array_length(mi_array, 1) FROM mi_tabla;


-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------


### Índices para Columnas JSON en PostgreSQL


 
#### Crear la Tabla y los Índices

-- drop table mi_tabla;

 -- Crear una tabla con una columna JSON
CREATE TABLE mi_tabla (
    id SERIAL PRIMARY KEY,
    mi_json JSONB
);



-- Crear un índice GIN
CREATE INDEX idx_mi_json_gin ON mi_tabla USING GIN (mi_json);

-- Crear un índice BTREE en un campo específico del JSON
CREATE INDEX idx_mi_json_btree ON mi_tabla ((mi_json->>'nombre'));


#### Insertar Datos de Prueba

INSERT INTO mi_tabla (mi_json)
SELECT jsonb_build_object(
    'nombre', 'Nombre' || s.i,
    'edad', (random() * 100)::int,
    'hobbies', jsonb_agg('Hobby' || t.j)
)
FROM generate_series(1, 10000) AS s(i),
     generate_series(1, 5) AS t(j)
GROUP BY s.i;



#### Consultas de Prueba

postgres@postgres# select * from mi_tabla limit 10;
+----+-----------------------------------------------------------------------------------------------------+
| id |                                               mi_json                                               |
+----+-----------------------------------------------------------------------------------------------------+
|  1 | {"edad": 69, "nombre": "Nombre6114", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]} |
|  2 | {"edad": 80, "nombre": "Nombre4790", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]} |
|  3 | {"edad": 46, "nombre": "Nombre273", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]}  |
|  4 | {"edad": 42, "nombre": "Nombre3936", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]} |
|  5 | {"edad": 96, "nombre": "Nombre5761", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]} |
|  6 | {"edad": 49, "nombre": "Nombre5468", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]} |
|  7 | {"edad": 94, "nombre": "Nombre7662", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]} |
|  8 | {"edad": 49, "nombre": "Nombre4326", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]} |
|  9 | {"edad": 9, "nombre": "Nombre2520", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]}  |
| 10 | {"edad": 45, "nombre": "Nombre9038", "hobbies": ["Hobby1", "Hobby2", "Hobby3", "Hobby4", "Hobby5"]} |
+----+-----------------------------------------------------------------------------------------------------+
(10 rows)


-- Buscar registros donde el JSON contiene un campo específico
postgres@postgres# EXPLAIN ANALYZE SELECT * FROM mi_tabla WHERE mi_json @> '{"nombre": "Nombre4326"}';
+-------------------------------------------------------------------------------------------------------+
|                                              QUERY PLAN                                               |
+-------------------------------------------------------------------------------------------------------+
| Seq Scan on mi_tabla  (cost=0.00..499.39 rows=245 width=36) (actual time=0.017..2.647 rows=1 loops=1) |
|   Filter: (mi_json @> '{"nombre": "Nombre4326"}'::jsonb)                                              |
|   Rows Removed by Filter: 9999                                                                        |
| Planning Time: 0.048 ms                                                                               |
| Execution Time: 2.662 ms                                                                              |
+-------------------------------------------------------------------------------------------------------+
(5 rows)


-- Buscar registros donde el campo 'nombre' es 'Ana'
postgres@postgres# EXPLAIN ANALYZE SELECT * FROM mi_tabla WHERE mi_json->>'nombre' = 'Nombre4326';
+-------------------------------------------------------------------------------------------------------+
|                                              QUERY PLAN                                               |
+-------------------------------------------------------------------------------------------------------+
| Seq Scan on mi_tabla  (cost=0.00..560.66 rows=123 width=36) (actual time=0.039..2.399 rows=1 loops=1) |
|   Filter: ((mi_json ->> 'nombre'::text) = 'Nombre4326'::text)                                         |
|   Rows Removed by Filter: 9999                                                                        |
| Planning Time: 0.051 ms                                                                               |
| Execution Time: 2.419 ms                                                                              |
+-------------------------------------------------------------------------------------------------------+
(5 rows)


1. **Índice GIN (Generalized Inverted Index)**: Es muy eficiente para consultas que buscan elementos dentro de un JSON.
postgres@postgres# CREATE INDEX idx_mi_json_gin ON mi_tabla USING GIN (mi_json);
CREATE INDEX
Time: 69.341 ms



postgres@postgres# EXPLAIN ANALYZE SELECT * FROM mi_tabla WHERE mi_json @> '{"nombre": "Nombre4326"}';
+---------------------------------------------------------------------------------------------------------------------------+
|                                                        QUERY PLAN                                                         |
+---------------------------------------------------------------------------------------------------------------------------+
| Bitmap Heap Scan on mi_tabla  (cost=22.04..188.78 rows=100 width=36) (actual time=0.060..0.061 rows=1 loops=1)            |
|   Recheck Cond: (mi_json @> '{"nombre": "Nombre4326"}'::jsonb)                                                            |
|   Heap Blocks: exact=1                                                                                                    |
|   ->  Bitmap Index Scan on idx_mi_json_gin  (cost=0.00..22.02 rows=100 width=0) (actual time=0.053..0.053 rows=1 loops=1) |
|         Index Cond: (mi_json @> '{"nombre": "Nombre4326"}'::jsonb)                                                        |
| Planning Time: 0.244 ms                                                                                                   |
| Execution Time: 0.083 ms                                                                                                  |
+---------------------------------------------------------------------------------------------------------------------------+
(7 rows)



2. **Índice BTREE**:  Útil para consultas que comparan valores específicos dentro de un JSON.
postgres@postgres# CREATE INDEX idx_mi_jsonb_nombre ON mi_tabla ((mi_json->>'nombre'));
CREATE INDEX
Time: 38.801 ms


postgres@postgres# EXPLAIN ANALYZE SELECT * FROM mi_tabla WHERE mi_json->>'nombre' = 'Nombre4326';
+-----------------------------------------------------------------------------------------------------------------------------+
|                                                         QUERY PLAN                                                          |
+-----------------------------------------------------------------------------------------------------------------------------+
| Bitmap Heap Scan on mi_tabla  (cost=4.67..120.24 rows=50 width=36) (actual time=0.027..0.028 rows=1 loops=1)                |
|   Recheck Cond: ((mi_json ->> 'nombre'::text) = 'Nombre4326'::text)                                                         |
|   Heap Blocks: exact=1                                                                                                      |
|   ->  Bitmap Index Scan on idx_mi_jsonb_nombre  (cost=0.00..4.66 rows=50 width=0) (actual time=0.021..0.021 rows=1 loops=1) |
|         Index Cond: ((mi_json ->> 'nombre'::text) = 'Nombre4326'::text)                                                     |
| Planning Time: 0.073 ms                                                                                                     |
| Execution Time: 0.045 ms                                                                                                    |
+-----------------------------------------------------------------------------------------------------------------------------+
(7 rows)



-- Acceder a un campo específico
SELECT mi_json->'nombre' AS nombre FROM mi_tabla;

-- Acceder a un campo específico como texto
SELECT mi_json->>'edad' AS edad FROM mi_tabla;

-- Acceder a un elemento de un array JSON
SELECT mi_json#>'{hobbies, 0}' AS primer_hobby FROM mi_tabla;

-- Verificar si un objeto JSON contiene otro objeto JSON
SELECT * FROM mi_tabla WHERE mi_json @> '{"nombre": "Juan"}';

-- Verificar si una clave existe en el objeto JSON
SELECT * FROM mi_tabla WHERE mi_json ? 'edad';

-- Verificar si alguna de las claves en el array existe en el objeto JSON
SELECT * FROM mi_tabla WHERE mi_json ?| array['nombre', 'apellido'];

-- Verificar si todas las claves en el array existen en el objeto JSON
SELECT * FROM mi_tabla WHERE mi_json ?& array['nombre', 'edad'];




### Explicación de los Índices

- **GIN**: Este índice es ideal para consultas que buscan elementos dentro de un JSON, como `@>` y `?`.
- **BTREE**: Este índice es útil para consultas que comparan valores específicos dentro de un JSON, como `->>`.
 


+-----------------------------------------------------------------------------------------------------------------------+
+-----------------------------------------------------------------------------------------------------------------------+
+-----------------------------------------------------------------------------------------------------------------------+




### Paso 1: Crear la Tabla

Primero, creamos la tabla con las columnas necesarias:


CREATE TABLE mi_tabla (
    id SERIAL PRIMARY KEY,
    ip_server VARCHAR(15),
    port INTEGER,
    id_procesos INTEGER[]
);


### Paso 2: Insertar Datos de Prueba

Usamos `generate_series` para insertar miles de registros en la tabla. En este ejemplo, cada array contendrá 10 números aleatorios entre 1 y 100.

-- truncate table mi_tabla RESTART IDENTITY ;

INSERT INTO mi_tabla (ip_server, port, id_procesos)
SELECT 
    '10.50.50.' || (random() * 255)::int,
    (random() * 10000)::int,
    ARRAY(
        SELECT (random() * 100)::int
        FROM generate_series(1, 10)
    )
FROM generate_series(1, 500000);





### Paso 4: Ejecutar la Consulta

postgres@postgres# select * from mi_tabla limit 10;
+----+--------------+------+---------------------------------+
| id |  ip_server   | port |           id_procesos           |
+----+--------------+------+---------------------------------+
|  1 | 10.50.50.79  | 1189 | {73,10,74,56,74,77,32,88,58,59} |
|  2 | 10.50.50.162 | 1484 | {73,10,74,56,74,77,32,88,58,59} |
|  3 | 10.50.50.163 |  624 | {73,10,74,56,74,77,32,88,58,59} |
|  4 | 10.50.50.169 | 1078 | {73,10,74,56,74,77,32,88,58,59} |
|  5 | 10.50.50.166 | 1662 | {73,10,74,56,74,77,32,88,58,59} |
|  6 | 10.50.50.66  | 8563 | {73,10,74,56,74,77,32,88,58,59} |
|  7 | 10.50.50.168 | 2301 | {73,10,74,56,74,77,32,88,58,59} |
|  8 | 10.50.50.254 |  186 | {73,10,74,56,74,77,32,88,58,59} |
|  9 | 10.50.50.112 | 9524 | {73,10,74,56,74,77,32,88,58,59} |
| 10 | 10.50.50.215 | 8881 | {73,10,74,56,74,77,32,88,58,59} |
+----+--------------+------+---------------------------------+
(10 rows)


postgres@postgres# EXPLAIN ANALYZE SELECT * FROM mi_tabla WHERE ip_server = '10.50.50.2'   AND port = 8798   AND id_procesos @> ARRAY[10, 20, 30]; 
];+---------------------------------------------------------------------------------------------------------------------+
|                                                     QUERY PLAN                                                      |
+---------------------------------------------------------------------------------------------------------------------+
| Seq Scan on mi_tabla  (cost=0.00..375.73 rows=1 width=59) (actual time=3.285..3.287 rows=0 loops=1)                 |
|   Filter: ((id_procesos @> '{10,20,30}'::integer[]) AND ((ip_server)::text = '10.50.50.2'::text) AND (port = 8798)) |
|   Rows Removed by Filter: 10000                                                                                     |
| Planning Time: 0.184 ms                                                                                             |
| Execution Time: 3.301 ms                                                                                            |
+---------------------------------------------------------------------------------------------------------------------+
(5 rows)


postgres@postgres# CREATE INDEX idx_ip_port ON mi_tabla (ip_server, port);
CREATE INDEX
Time: 31.895 ms


postgres@postgres# CREATE INDEX idx_id_procesos ON mi_tabla USING GIN (id_procesos);
CREATE INDEX
Time: 16.186 ms


postgres@postgres# EXPLAIN ANALYZE SELECT * FROM mi_tabla WHERE ip_server = '10.50.50.2'   AND port = 8798   AND id_procesos @> ARRAY[10, 20, 30];
+-----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                       |
+-----------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_ip_port on mi_tabla  (cost=0.42..8.44 rows=1 width=81) (actual time=0.022..0.022 rows=0 loops=1) |
|   Index Cond: (((ip_server)::text = '10.50.50.2'::text) AND (port = 8798))                                            |
|   Filter: (id_procesos @> '{10,20,30}'::integer[])                                                                    |
| Planning Time: 0.118 ms                                                                                               |
| Execution Time: 0.036 ms                                                                                              |
+-----------------------------------------------------------------------------------------------------------------------+












```



```SQL

select pg_indexes_size(index_name);


select * from pg_index limit 1;


-- Obtener información sobre los índices y su tamaño:
SELECT schemaname || '.' || indexname AS index_full_name,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || indexname)) AS size
FROM pg_indexes ORDER BY pg_total_relation_size(schemaname || '.' || indexname) DESC;


-- Mostrar el tamaño y uso de los índices en cada tabla
SELECT schemaname || '.' || tablename AS table_full_name,
       indexname AS index_name,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || indexrelname)) AS index_size,
       idx_scan AS index_scans
FROM pg_indexes
JOIN pg_stat_user_indexes ON pg_indexes.schemaname = pg_stat_user_indexes.schemaname AND pg_indexes.indexrelname = pg_stat_user_indexes.indexrelname
ORDER BY pg_total_relation_size(schemaname || '.' || indexrelname) DESC;
```

```SQL
CREATE EXTENSION pgstattuple;

- **Funciones disponibles**:
  - `pgstattuple(regclass)` devuelve información sobre la longitud física de una relación, el porcentaje de tuplas "muertas" y otros datos relevantes. Esto puede ayudarte a determinar si es necesario realizar un vaciado de la tabla¹.
  - `pgstattuple(text)` es similar a la función anterior, pero permite especificar la relación de destino como texto. Sin embargo, esta función quedará obsoleta en futuras versiones¹.
  - `pgstatindex(regclass)` proporciona información sobre un índice de árbol B¹.

- **Columnas de salida**:
  - `table_len`: Longitud física de la relación en bytes.
  - `tuple_count`: Número de tuplas vivas.
  - `tuple_len`: Longitud total de tuplas activas en bytes.
  - `tuple_percent`: Porcentaje de tuplas vivas.
  - `dead_tuple_count`: Número de tuplas muertas.
  - `dead_tuple_len`: Longitud total de tuplas muertas en bytes.
  - `dead_tuple_percent`: Porcentaje de tuplas muertas.
  - `free_space`: Espacio libre total en bytes.
  - `free_percent`: Porcentaje de espacio libre¹.


SELECT t0.indexrelid::regclass as Indice, t5.tablename as Tabla, t1.reltuples as Registros, t4.leaf_fragmentation as Porcentaje_Fragmentacion 
/* ,case t1.relkind when 'r' then 'TABLE'
when 'm' then 'MATERIALIZED_VIEW'
when 'i' then 'INDEX'
when 'S' then 'SEQUENCE'
when 'v' then 'VIEW'
when 'c' then 'TYPE'
else t1.relkind::text end as Descripcion_Tipo_Objeto */ 
FROM pg_index AS t0
   JOIN pg_class AS t1 ON t0.indexrelid = t1.oid /* and relnamespace  in( SELECT oid   FROM pg_namespace  WHERE nspname = 'public') */ 
   JOIN pg_opclass AS t2 ON t0.indclass[0] = t2.oid
   JOIN pg_am as t3 ON t2.opcmethod = t3.oid
   CROSS JOIN LATERAL pgstatindex(t0.indexrelid) AS t4
   left join pg_indexes t5 on t1.relname = t5.indexname
WHERE t1.relkind = 'i' AND t3.amname = 'btree' and t4.leaf_fragmentation >=0
```

# ver index y sus columnas 
```sql
		SELECT
    t.relname AS table_name,
    i.relname AS index_name,
    a.attname AS column_name
FROM
    pg_class t,
    pg_class i,
    pg_index ix,
    pg_attribute a
WHERE
    t.oid = ix.indrelid
    AND i.oid = ix.indexrelid
	
    AND a.attrelid = t.oid
    AND a.attnum = ANY(ix.indkey)
 
ORDER BY
    i.relname;

```

# amcheck 
La extensión amcheck en PostgreSQL es una herramienta poderosa para verificar la integridad de las estructuras de índice en tu base de datos. Esencialmente, está diseñada para detectar corrupción en las páginas de índice, lo cual es crucial para mantener la integridad de tus datos.

```
-- Verificar un índice B-Tree para problemas estructurales
SELECT bt_index_check('mi_indice');

-- Verificar un índice B-Tree y sus relaciones padre-hijo
SELECT bt_index_parent_check('mi_indice');

```

### Renombrar index
	ALTER INDEX fdw_conf.fdw_confunique_ctl_dbms RENAME TO idx_unique_ctl_dbms;

-- indices : 
https://dbasinapuros.com/tipos-de-indices-en-postgresql/

https://dbalifeeasy.com/2020/10/04/how-to-identify-fragmentation-in-postgresql-rds/ 





# Problemas


## 1  Tengo una tabla que tiene millones de registros y cuando realizo una consulta con filtro no usa el index 

```SQL
postgres@auditoria#  select name,setting from pg_settings where name in('server_version','enable_seqscan','random_page_cost','seq_page_cost','cpu_tuple_cost','cpu_index_tuple_cost','effective_cache_size','work_mem','default_statistics_target','max_parallel_workers_per_gather');
+---------------------------------+---------+
|              name               | setting |
+---------------------------------+---------+
| cpu_index_tuple_cost            | 0.005   |
| cpu_tuple_cost                  | 0.01    |
| default_statistics_target       | 1000    |
| effective_cache_size            | 1048576 |
| enable_seqscan                  | on      |
| max_parallel_workers_per_gather | 8       |
| random_page_cost                | 4       |
| seq_page_cost                   | 1       |
| server_version                  | 16.4    |
| work_mem                        | 262144  |
+---------------------------------+---------+
(10 rows)


postgres@postgres# SELECT count(*) FROM psql.tables_columns WHERE id_exec = 75;
+----------+
|  count   |
+----------+
| 11746156 |
+----------+
(1 row)

  
postgres@auditoria# EXPLAIN (ANALYZE) SELECT * FROM psql.tables_columns WHERE id_exec = 75;
+--------------------------------------------------------------------------------------------------------------------------------+
|                                                           QUERY PLAN                                                           |
+--------------------------------------------------------------------------------------------------------------------------------+
| Seq Scan on tables_columns  (cost=0.00..409646.25 rows=11746420 width=175) (actual time=0.021..2346.802 rows=11746156 loops=1) |
|   Filter: (id_exec = 75)                                                                                                       |
|   Rows Removed by Filter: 264                                                                                                  |
| Planning Time: 0.097 ms                                                                                                        |
| Execution Time: 2752.621 ms                                                                                                    |
+--------------------------------------------------------------------------------------------------------------------------------+
(5 rows)

Time: 2753.226 ms (00:02.753)

 


postgres@auditoria# set enable_seqscan = off;
SET
Time: 0.724 ms
postgres@auditoria#   explain analyze  select * from psql.tables_columns   where  id_exec = 75;
+-------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                            QUERY PLAN
+-------------------------------------------------------------------------------------------------------------------------------------------------
 
| Index Scan using idx_psql_tables_columns_10 on tables_columns  (cost=0.43..508137.79 rows=11746420 width=175) (actual time=0.024..2102.699 rows=
11746156 loops=1) |
|   Index Cond: (id_exec = 75)
                  |
| Planning Time: 0.116 ms
                  |
| Execution Time: 2521.252 ms
                  |
+-------------------------------------------------------------------------------------------------------------------------------------------------
 
(4 rows)

Time: 2522.325 ms (00:02.522)




####### Parametros que quiero ajustar pero no funciona 

SET seq_page_cost = 1.0;
SET random_page_cost = 1.0
SET cpu_tuple_cost = 0.01;
SET cpu_index_tuple_cost = 0.005;
SET effective_cache_size = '4GB';
SET work_mem = '256MB';
SET default_statistics_target = 1000;
SET max_parallel_workers_per_gather = 4;



ALTER TABLE foo_history ALTER foo_id SET STATISTICS 1000;
default_statistics_target = 100    # range 1-10000



-- index y sus  validar tamaños 
postgres@auditoria#  select pg_size_pretty(pg_relation_size(schemaname || '.' || indexname )),* from pg_indexes where tablename = 'tables_columns' and schemaname = 'psql' order by   pg_relation_size(schemaname || '.' || indexname ) desc;

+-[ RECORD 1 ]---+--------------------------------------------------------------------------------------------------------------------------------
-----------------+
| pg_size_pretty | 1156 MB
                 |
| schemaname     | psql
                 |
| tablename      | tables_columns
                 |
| indexname      | idx_psql_tables_columns_3
                 |
| tablespace     | NULL
                 |
| indexdef       | CREATE INDEX idx_psql_tables_columns_3 ON psql.tables_columns USING btree (id_exec, ip_server, port, db, table_name, column_nam
e)               |
+-[ RECORD 2 ]---+--------------------------------------------------------------------------------------------------------------------------------
-----------------+
| pg_size_pretty | 1156 MB
                 |
| schemaname     | psql
                 |
| tablename      | tables_columns
                 |
| indexname      | idx_psql_tables_columns_4
                 |
| tablespace     | NULL
                 |
| indexdef       | CREATE INDEX idx_psql_tables_columns_4 ON psql.tables_columns USING btree (((date_insert)::date), ip_server, port, db, table_na
me, column_name) |
+-[ RECORD 3 ]---+--------------------------------------------------------------------------------------------------------------------------------
-----------------+
| pg_size_pretty | 252 MB
                 |
| schemaname     | psql
                 |
| tablename      | tables_columns
                 |
| indexname      | table_columns_pkey
                 |
| tablespace     | NULL
                 |
| indexdef       | CREATE UNIQUE INDEX table_columns_pkey ON psql.tables_columns USING btree (id)
                 |
+-[ RECORD 4 ]---+--------------------------------------------------------------------------------------------------------------------------------
-----------------+
| pg_size_pretty | 78 MB
                 |
| schemaname     | psql
                 |
| tablename      | tables_columns
                 |
| indexname      | idx_psql_tables_columns_10
                 |
| tablespace     | NULL
                 |
| indexdef       | CREATE INDEX idx_psql_tables_columns_10 ON psql.tables_columns USING btree (id_exec)
                 |
+----------------+----

```
