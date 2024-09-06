
# INDEX
Un índice es una estructura de datos que almacena una referencia a los datos en una tabla, permitiendo que las búsquedas y otras operaciones sean mucho más rápidas. Piensa en un índice como el índice de un libro, que te permite encontrar rápidamente la página donde se menciona un tema específico, se utilizan cuando se usa el `SELECT`

## Impacto diferente en las operaciones de `INSERT`, `UPDATE` y `DELETE` en comparación con las consultas `SELECT`.

### Impacto de los Índices en `INSERT`

1. **Rendimiento de `INSERT`**: Cada vez que insertas una nueva fila en una tabla con índices, PostgreSQL también debe actualizar esos índices. Esto significa que cuantos más índices tenga una tabla, más tiempo tomará cada operación de inserción³⁴.
2. **Espacio en Disco**: Los índices ocupan espacio adicional en disco. Si tienes muchos índices, el tamaño total de la base de datos puede aumentar significativamente².
3. **Balance**: Es importante encontrar un equilibrio entre tener suficientes índices para mejorar el rendimiento de las consultas `SELECT` y no tener tantos que ralenticen las operaciones de inserción y actualización³.

### Estrategias para Mitigar el Impacto

1. **Índices Necesarios**: Crea solo los índices que realmente necesitas para mejorar el rendimiento de tus consultas más frecuentes.
2. **Índices Diferidos**: Si estás realizando una gran cantidad de inserciones, considera deshabilitar temporalmente los índices y reconstruirlos después de completar las inserciones masivas.
3. **Monitoreo y Ajuste**: Usa herramientas como `EXPLAIN` y `ANALYZE` para monitorear el rendimiento de tus consultas y ajustar los índices según sea necesario.
 

 
# Tipos de índices en PostgreSQL:
```SQL
    1. Índices B-Tree: B-tree son ideales para consultas que utilizan operadores de comparación estándar. Son los más comunes y se utilizan para columnas que tienen valores repetidos, como las columnas de nombres, fechas y números. Proporcionan una búsqueda rápida en logaritmo de tiempo.
    2. Índices Hash: Adecuados para igualdad de búsqueda exacta. Sin embargo, no funcionan bien con rangos y consultas de rango.
    3. Índices GIN y GiST: Son utilizados para tipos de datos más complejos como texto y geometría, JSONB, arrays, permitiendo búsquedas y comparaciones más avanzadas, se usa en los ilike
    4. Índices SP-GiST: Útiles para tipos de datos con estructuras jerárquicas o multidimensionales.

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


# Usar CLUSTER
El propósito de este comando es mejorar el rendimiento de las consultas que utilizan un indice.  agrupa  la tabla el índice indicado, los datos se almacenan físicamente en el orden del índice, lo que puede acelerar las búsquedas y mejorar la eficiencia de las consultas.

```SQL
	-- configurarle un cluster a una tabla
	ALTER TABLE IF EXISTS public.table_test CLUSTER ON idx_table_test;

  	-- Indicas que ejecute los clusteres 
 	cluster;
``` 


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

### Renombrar index
	ALTER INDEX fdw_conf.fdw_confunique_ctl_dbms RENAME TO idx_unique_ctl_dbms;

-- indices : 
https://dbasinapuros.com/tipos-de-indices-en-postgresql/

https://dbalifeeasy.com/2020/10/04/how-to-identify-fragmentation-in-postgresql-rds/ 
