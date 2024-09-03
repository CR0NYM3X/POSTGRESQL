 
### ¿Qué es un plan de ejecución?
Un plan de ejecución muestra cómo PostgreSQL va a escanear las tablas involucradas en una consulta, ya sea mediante un escaneo secuencial, un escaneo de índice, etc. También muestra qué algoritmos de unión se utilizarán si hay múltiples tablas involucradas¹.


 
### Tipos de Plan de Ejecución

1. **Seq Scan (Sequential Scan)**:
   - **Descripción**: Un sequential scan ocurre cuando PostgreSQL examina todas las filas de una tabla, una por una, para encontrar las filas que coinciden con una consulta. 
   - **Uso**: Este tipo de escaneo se utiliza cuando:No existe un índice adecuado para la columna o columnas que se están consultando.PostgreSQL determina que es más eficiente escanear toda la tabla que utilizar un índice .
   - **Ejemplo**:
     ```plaintext
     Seq Scan on empleados  (cost=0.00..1.01 rows=1 width=32)
     ```

2. **Index Scan**:
   - **Descripción**: Utiliza un índice para buscar filas específicas.
   - **Uso**: Se utiliza cuando hay un índice adecuado y el planificador estima que es más eficiente que un escaneo secuencial.
   - **Ejemplo**:
     ```plaintext
     Index Scan using idx_salario on empleados  (cost=0.13..8.15 rows=1 width=32)
     ```

3. **Bitmap Index Scan**:
   - **Descripción**: Escanea un índice y crea un mapa de bits de las páginas que contienen las filas deseadas.
   - **Uso**: Eficiente para consultas que devuelven muchas filas dispersas.
   - **Ejemplo**:
     ```plaintext
     Bitmap Index Scan on idx_salario  (cost=0.00..5.04 rows=101 width=0)
     ```

4. **Bitmap Heap Scan**:
   - **Descripción**: Utiliza el mapa de bits creado por un `Bitmap Index Scan` para leer las filas de la tabla.
   - **Uso**: Se usa en combinación con `Bitmap Index Scan`.
   - **Ejemplo**:
     ```plaintext
     Bitmap Heap Scan on empleados  (cost=4.12..12.15 rows=101 width=32)
     ```

5. **Nested Loop**:
   - **Descripción**: Para cada fila de la tabla externa, busca filas coincidentes en la tabla interna.
   - **Uso**: Eficiente para conjuntos de datos pequeños o cuando las tablas están bien indexadas.
   - **Ejemplo**:
     ```plaintext
     Nested Loop  (cost=0.00..20.00 rows=10 width=64)
     ```

6. **Hash Join**:
   - **Descripción**: Crea una tabla hash en memoria para una de las tablas y luego busca filas coincidentes en la otra tabla.
   - **Uso**: Eficiente para grandes conjuntos de datos sin índices adecuados.
   - **Ejemplo**:
     ```plaintext
     Hash Join  (cost=10.00..30.00 rows=100 width=64)
     ```

7. **Merge Join**:
   - **Descripción**: Combina filas de dos tablas ordenadas.
   - **Uso**: Eficiente cuando ambas tablas están ordenadas por las columnas de unión.
   - **Ejemplo**:
     ```plaintext
     Merge Join  (cost=15.00..35.00 rows=100 width=64)
     ```

8. **Sort**:
   - **Descripción**: Ordena las filas de una tabla.
   - **Uso**: Se utiliza cuando la consulta requiere un orden específico.
   - **Ejemplo**:
     ```plaintext
     Sort  (cost=5.00..10.00 rows=100 width=32)
     ```

# seq_page_cost

El parámetro `seq_page_cost` en PostgreSQL es una configuración que establece la estimación del planificador sobre el costo de recuperar una página de disco durante un escaneo secuencial¹. Este costo se mide en unidades arbitrarias y por defecto está establecido en 1.0².

### ¿Por qué es importante `seq_page_cost`?
El valor de `seq_page_cost` influye en las decisiones del planificador de consultas sobre si utilizar un escaneo secuencial o un índice. Un valor más bajo de `seq_page_cost` hace que los escaneos secuenciales parezcan más baratos, lo que puede llevar al planificador a preferirlos sobre los escaneos de índice³.

### Ajuste de `seq_page_cost`
Puedes ajustar este parámetro para optimizar el rendimiento de tus consultas. Por ejemplo, si tu sistema tiene un almacenamiento rápido (como SSDs), podrías reducir el valor de `seq_page_cost` para reflejar el menor costo de lectura de páginas de disco:
```sql
SET seq_page_cost = 0.5;
```
 


#  Comando EXPLAIN
Para ver el plan de ejecución de una consulta, se utiliza el comando `EXPLAIN`. Por ejemplo:
```sql
EXPLAIN SELECT * FROM empleados WHERE salario = 50000.00;
```
Este comando muestra el plan de ejecución sin ejecutar la consulta, pero si lo cuenta la tabla pg_stat_user_tables en la columna seq_scan.


### Opciones de EXPLAIN
- **ANALYZE**: Ejecuta la consulta y muestra estadísticas de tiempo real, incluyendo el tiempo total y el número de filas devueltas.
  ```sql
  EXPLAIN  (VERBOSE,ANALYZE, COSTS , TIMING  , BUFFERS , FORMAT TEXT)   select * from empleados where salario  = 50000.00;
  ```
- **VERBOSE**: Muestra información adicional sobre el plan.
- **COSTS**: Incluye los costos estimados de inicio y total de cada nodo del plan.
- **BUFFERS**: Muestra el uso de buffers, solo cuando ANALYZE está habilitado.
- **TIMING**: Incluye el tiempo real de inicio y el tiempo gastado en cada nodo.
- **FORMAT**: Especifica el formato de salida del plan (TEXT, XML, JSON, YAML).

 

### Ejemplo de Salida
```plaintext
postgres@postgres# EXPLAIN  (VERBOSE,ANALYZE, COSTS , TIMING  , BUFFERS , FORMAT TEXT)   select * from empleados where salario  = 50000.00;
+-------------------------------------------------------------------------------------------------------------+
|                                                 QUERY PLAN                                                  |
+-------------------------------------------------------------------------------------------------------------+
| Seq Scan on public.empleados  (cost=0.00..13.50 rows=1 width=256) (actual time=0.014..0.020 rows=1 loops=1) |
|   Output: id, nombre, puesto, salario                                                                       |
|   Filter: (empleados.salario = 50000.00)                                                                    |
|   Rows Removed by Filter: 19                                                                                |
|   Buffers: shared hit=1                                                                                     |
| Planning Time: 0.055 ms                                                                                     |
| Execution Time: 0.057 ms                                                                                    |
+-------------------------------------------------------------------------------------------------------------+
(7 rows)

Time: 0.483 ms


```
En este ejemplo:
- **Seq Scan** indica un escaneo secuencial.
- **cost=0.00..1.01** muestra el costo de inicio y el costo total.
- **rows=1** es el número estimado de filas que coinciden con la condición.
- **width=32** es el tamaño estimado de cada fila.
 
 
 
 
# Razones por las cuales PostgreSQL podría no estar utilizando un índice. 

1. **Tamaño de la Tabla**: Si la tabla es pequeña, PostgreSQL puede decidir que un escaneo secuencial es más eficiente que usar un índice¹.

2. **Estadísticas Desactualizadas**: Las estadísticas de la tabla pueden estar desactualizadas, lo que lleva a PostgreSQL a tomar decisiones subóptimas. Puedes actualizar las estadísticas con el comando `ANALYZE`:
   ```sql
   ANALYZE empleados;
   ```

3. **Precisión del Valor**: Asegúrate de que el valor en tu consulta coincida exactamente con el valor almacenado. Pequeñas diferencias en la precisión pueden hacer que el índice no se utilice².

4. **Configuración del Planificador**: Algunas configuraciones del servidor pueden influir en la decisión del planificador de consultas. Puedes intentar forzar el uso del índice con:
   ```sql
   SET enable_seqscan = OFF; -- [NOTA] en caso de desactivarlo, y no tener indices, postgresql seguira usando el seq_scan, esto solo es en caso de que tenga al menmos 1 indices, lo forzar a que use el indice en vez del seq_scan
   SELECT * FROM empleados WHERE salario = 50000.00;
   ```

5. **Condiciones de la Consulta**: Si la consulta no está bien optimizada para usar el índice, PostgreSQL puede optar por no utilizarlo. Por ejemplo, si estás utilizando funciones en la columna indexada, el índice no se utilizará:
   ```sql
   SELECT * FROM empleados WHERE salario::text = '50000.00';
   ```

6. **Tipo de Índice**: Asegúrate de que el tipo de índice sea adecuado para tu consulta. En la mayoría de los casos, un índice B-tree es suficiente, pero si estás utilizando otro tipo de índice, podría no ser el más eficiente³.

7. **Index Bloat**: Si el índice está fragmentado o tiene mucho "bloat", puede ser menos eficiente. En este caso, podrías considerar reconstruir el índice:
   ```sql
   REINDEX INDEX idx_salario;
   ```

8. **Estimaciones de Costos**: PostgreSQL puede estimar que el costo de usar el índice es mayor que el de un escaneo secuencial. Esto puede deberse a estadísticas incorrectas o a una configuración del planificador que no refleja la realidad¹.






# ¿Qué es `enable_seqscan`?

`enable_seqscan` es un parámetro de configuración en PostgreSQL que controla si el planificador de consultas debe usar escaneos secuenciales. Por defecto, este parámetro está activado (`on`), lo que permite al planificador elegir escaneos secuenciales cuando lo considere más eficiente¹.

### ¿Para qué sirve?

- **Escaneo secuencial**: Es el método por defecto para leer una tabla completa. PostgreSQL lee todas las filas de la tabla una por una.
- **Escaneo por índice**: Utiliza un índice para encontrar filas específicas de manera más eficiente, especialmente útil para consultas que buscan un subconjunto pequeño de filas.

### ¿Cuándo desactivar `enable_seqscan`?

Desactivar `enable_seqscan` (`SET enable_seqscan = off;`) puede ser útil en situaciones específicas:

1. **Forzar el uso de índices**: Si sabes que un índice debería ser más eficiente para una consulta específica, pero PostgreSQL sigue eligiendo un escaneo secuencial, puedes desactivar `enable_seqscan` para forzar el uso del índice.
2. **Pruebas y optimización**: Durante el proceso de optimización de consultas, puedes desactivar `enable_seqscan` para comparar el rendimiento de diferentes planes de ejecución y asegurarte de que los índices se están utilizando correctamente.

### Ver estatus de `enable_seqscan` y otras conf de plan de ejecucion 
```sql
-- Deshabilitar el escaneo secuencial
SET enable_seqscan = off;

select name,short_desc from pg_settings where short_desc ilike '%plan%' ;
select name,short_desc from pg_settings where category ilike '%plan%' ;
```



# Ver estadisticas de tablas y sus index 
 ```sql
 select * from pg_stat_user_indexes where relname = 'empleados';
 select * from pg_stat_user_tables where relname =  'empleados';
```




# Test index y plan de ejecucion 
  ```sql
postgres@postgres#  show enable_seqscan ;
+----------------+
| enable_seqscan |
+----------------+
| on             |
+----------------+
(1 row)


postgres@postgres#  CREATE TABLE empleados (
     id SERIAL PRIMARY KEY,
     nombre VARCHAR(50),
     puesto VARCHAR(50),
     salario DECIMAL(10, 2)
 );
CREATE TABLE
Time: 4.350 ms


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 1                             | <------ al crear la tabla y no insertar, empieza con 1
| last_seq_scan       | 2024-08-30 18:10:58.751702-07 |
| seq_tup_read        | 0                             |
| idx_scan            | 0                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 0                             |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 0                             |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 0                             |
| n_ins_since_vacuum  | 0                             |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+



postgres@postgres# INSERT INTO empleados (nombre, puesto, salario) VALUES
 ('Juan Pérez', 'Desarrollador', 50000.00),
 ('María López', 'Analista', 45000.00),
 ('Carlos Sánchez', 'Gerente', 60000.00),
 ('Ana Gómez', 'Diseñadora', 40000.00),
 ('Luis Fernández', 'Desarrollador', 52000.00),
 ('Laura Martínez', 'Analista', 47000.00),
 ('Pedro García', 'Gerente', 62000.00),
 ('Sofía Rodríguez', 'Diseñadora', 42000.00),
 ('Miguel Torres', 'Desarrollador', 51000.00),
 ('Lucía Ramírez', 'Analista', 46000.00),
 ('Jorge Hernández', 'Gerente', 61000.00),
 ('Elena Díaz', 'Diseñadora', 41000.00),
 ('Raúl Morales', 'Desarrollador', 53000.00),
 ('Isabel Ruiz', 'Analista', 48000.00),
 ('Fernando Jiménez', 'Gerente', 63000.00),
 ('Patricia Ortiz', 'Diseñadora', 43000.00),
 ('Andrés Castro', 'Desarrollador', 54000.00),
 ('Marta Vega', 'Analista', 49000.00),
 ('Ricardo Soto', 'Gerente', 64000.00),
 ('Carmen Silva', 'Diseñadora', 44000.00);
INSERT 0 20
Time: 1.843 ms


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 1                             |  
| last_seq_scan       | 2024-08-30 18:10:58.751702-07 |
| seq_tup_read        | 0                             |
| idx_scan            | 0                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 20                            | <-------- aparecen que inserte 20 reg
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 20                            | <------------- 
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 20                            | <-------------
| n_ins_since_vacuum  | 20                            | <-------------
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+

Time: 1.137 ms



postgres@postgres#  select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan | last_idx_scan | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| 378890 |     378894 | public     | empleados | empleados_pkey |        0 | NULL          |            0 |             0 |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+



postgres@postgres# select * from empleados where nombre = 'Juan Pérez';
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 378883                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 2                             | <--- usa el seq_scan, escaneo toda la tabla porque no hay indices   
| last_seq_scan       | 2024-09-02 09:53:06.645501-07 |
| seq_tup_read        | 20                            | < -- indica la cantidad de filas leydas 
| idx_scan            | 0                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 20                            |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 20                            |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 20                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+



postgres@postgres# CREATE INDEX idx_salario ON public.empleados( salario );
CREATE INDEX
Time: 33.725 ms
postgres@postgres# CREATE INDEX idx_puesto ON public.empleados( nombre );
CREATE INDEX
Time: 3.307 ms



postgres@postgres#  select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 378908                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 4                             | <-- Al crear indices aumenta el seq_scan
| last_seq_scan       | 2024-09-02 10:12:22.592939-07 |
| seq_tup_read        | 60                            | <-- Igual aumentaron 20 por cada index
| idx_scan            | 0                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 20                            |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 20                            |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 20                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+




postgres@postgres#  select * from empleados where nombre = 'Juan Pérez';
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)

Time: 0.778 ms
postgres@postgres#  select * from empleados where salario =  45000.00;
+----+-------------+----------+----------+
| id |   nombre    |  puesto  | salario  |
+----+-------------+----------+----------+
|  2 | María López | Analista | 45000.00 |
+----+-------------+----------+----------+
(1 row)

Time: 1.094 ms



postgres@postgres#  select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 378908                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 6                             | <-- Aunque ya creamos los indices sigue usando el seq_scan , esto porque es una tabla chica
| last_seq_scan       | 2024-09-02 10:14:58.345934-07 |
| seq_tup_read        | 100                           | <-- y aumento 20 cada select 
| idx_scan            | 0                             | <-- no aumento porque no se uso index
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 20                            |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 20                            |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 20                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+

Time: 1.203 ms


postgres@postgres# select * from pg_stat_user_indexes where relname = 'empleados'; -- Los indx_scan estan en 0 porque no se usaron
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan | last_idx_scan | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| 378908 |     378912 | public     | empleados | empleados_pkey |        0 | NULL          |            0 |             0 | 
| 378908 |     378914 | public     | empleados | idx_salario    |        0 | NULL          |            0 |             0 |
| 378908 |     378915 | public     | empleados | idx_puesto     |        0 | NULL          |            0 |             0 |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+



postgres@postgres# EXPLAIN  (VERBOSE,ANALYZE, COSTS , TIMING  , BUFFERS , FORMAT TEXT)   select * from empleados where salario  = 50000.00;
+------------------------------------------------------------------------------------------------------------+
|                                                 QUERY PLAN                                                 |
+------------------------------------------------------------------------------------------------------------+
| Seq Scan on public.empleados  (cost=0.00..1.25 rows=1 width=106) (actual time=0.012..0.016 rows=1 loops=1) | <-- El plan de ejecucion decide mejor usar el seq_scan debido a menor costo en vez de usar los indices
|   Output: id, nombre, puesto, salario                                                                      |
|   Filter: (empleados.salario = 50000.00)                                                                   |
|   Rows Removed by Filter: 19                                                                               |
|   Buffers: shared hit=1                                                                                    |
| Query Identifier: -3825491996829677275                                                                     |
| Planning Time: 0.063 ms                                                                                    |
| Execution Time: 0.028 ms                                                                                   |
+------------------------------------------------------------------------------------------------------------+
(8 rows)

Time: 0.469 ms



postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 378947                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 7                             | <-- Si hacemos el EXPLAIN tambien no genero un seq_scan
| last_seq_scan       | 2024-09-02 10:26:29.83269-07  |
| seq_tup_read        | 120                           |
| idx_scan            | 1                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 1                             |
| n_tup_ins           | 20                            |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 20                            |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 20                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+




postgres@postgres# SET enable_seqscan = off; -- Forzamos el plan de ejecucion a usar indices 
SET
Time: 0.333 ms



postgres@postgres#  select * from empleados where nombre = 'Juan Pérez';
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)

Time: 0.778 ms
postgres@postgres#  select * from empleados where salario =  45000.00;
+----+-------------+----------+----------+
| id |   nombre    |  puesto  | salario  |
+----+-------------+----------+----------+
|  2 | María López | Analista | 45000.00 |
+----+-------------+----------+----------+
(1 row)

Time: 1.094 ms





postgres@postgres#  select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 378956                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 7                             | 
| last_seq_scan       | 2024-09-02 10:27:46.662017-07 |
| seq_tup_read        | 120                           |
| idx_scan            | 2                             | <-- ahora si utilizo los indices, porque lo desativamos el seq_scan
| last_idx_scan       | 2024-09-02 10:28:10.201423-07 |
| idx_tup_fetch       | 2                             |
| n_tup_ins           | 20                            |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 20                            |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 20                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+


postgres@postgres#  select * from pg_stat_user_indexes where relname = 'empleados'; -- el idx_scan aumento a 1 ya que se escaneo una vez 
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan |         last_idx_scan         | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| 378956 |     378960 | public     | empleados | empleados_pkey |        0 | NULL                          |            0 |             0 |
| 378956 |     378962 | public     | empleados | idx_salario    |        1 | 2024-09-02 10:28:10.201423-07 |            1 |             1 | <-- 
| 378956 |     378963 | public     | empleados | idx_puesto     |        1 | 2024-09-02 10:28:06.168474-07 |            1 |             1 |
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+





postgres@postgres# select * from empleados where nombre ilike '%Carlosssssssssssssss%'  ;
(0 rows)

Time: 0.603 ms


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 378956                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 8                             | <-- aunque no retorno nada el select , si aumento 
| last_seq_scan       | 2024-09-02 10:33:24.941175-07 | <-- y leyo todas las filas 
| seq_tup_read        | 140                           |
| idx_scan            | 2                             |
| last_idx_scan       | 2024-09-02 10:28:10.201423-07 |
| idx_tup_fetch       | 2                             |
| n_tup_ins           | 20                            |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 20                            |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 20                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+

 
 
 
 postgres@log_monitor# select * from empleados where nombre ilike '%Carlos%' ;
+----+----------------+----------+----------+
| id |     nombre     |  puesto  | salario  |
+----+----------------+----------+----------+
|  3 | Carlos Sánchez | Gerente  | 60000.00 |
+----+----------------+----------+----------+
(3 rows)

Time: 1.155 ms


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 378983                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 9                             | <-- Como vemos aunque esta descativado mejor opto por usar seq_scan en vez de indices 
| last_seq_scan       | 2024-09-02 10:39:57.339037-07 |
| seq_tup_read        | 160                           |
| idx_scan            | 2                             |
| last_idx_scan       | 2024-09-02 10:39:09.044659-07 |
| idx_tup_fetch       | 2                             |
| n_tup_ins           | 20                            |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 20                            |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 20                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+




postgres@postgres# CREATE EXTENSION pg_trgm;
CREATE EXTENSION
Time: 7.278 ms
postgres@postgres# CREATE INDEX idx_nombre_trgm ON empleados USING GIN (nombre gin_trgm_ops);
CREATE INDEX
Time: 1.801 ms


postgres@postgres# CREATE INDEX idx_empleados_nombre_trgm ON empleados USING GIN (nombre gin_trgm_ops);
CREATE INDEX
Time: 1.623 ms


postgres@log_monitor# select * from empleados where nombre ilike '%Carlos%' ;
+----+----------------+----------+----------+
| id |     nombre     |  puesto  | salario  |
+----+----------------+----------+----------+
|  3 | Carlos Sánchez | Gerente  | 60000.00 |
+----+----------------+----------+----------+
(3 rows)

Time: 1.155 ms


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 379300                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 10                            |
| last_seq_scan       | 2024-09-02 12:04:59.90553-07  |
| seq_tup_read        | 180                           |
| idx_scan            | 3                             | <-- Ahora si utilizo index 
| last_idx_scan       | 2024-09-02 12:05:09.795682-07 |
| idx_tup_fetch       | 3                             |
| n_tup_ins           | 20                            |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 20                            |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 20                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+




postgres@postgres# EXPLAIN  (VERBOSE,ANALYZE, COSTS , TIMING  , BUFFERS , FORMAT TEXT) select * from empleados where nombre ilike '%Carlos%';
+-----------------------------------------------------------------------------------------------------------------------------------+
|                                                            QUERY PLAN                                                             |
+-----------------------------------------------------------------------------------------------------------------------------------+
| Bitmap Heap Scan on public.empleados  (cost=21.80..25.81 rows=1 width=106) (actual time=0.021..0.022 rows=1 loops=1)              |
|   Output: id, nombre, puesto, salario                                                                                             |
|   Recheck Cond: ((empleados.nombre)::text ~~* '%Carlos%'::text)                                                                   |
|   Heap Blocks: exact=1                                                                                                            |
|   Buffers: shared hit=6                                                                                                           |
|   ->  Bitmap Index Scan on idx_empleados_nombre_trgm  (cost=0.00..21.80 rows=1 width=0) (actual time=0.012..0.012 rows=1 loops=1) |
|         Index Cond: ((empleados.nombre)::text ~~* '%Carlos%'::text)                                                               |
|         Buffers: shared hit=5                                                                                                     |
| Query Identifier: 7810701116106580756                                                                                             |
| Planning:                                                                                                                         |
|   Buffers: shared hit=2                                                                                                           |
| Planning Time: 0.096 ms                                                                                                           |
| Execution Time: 0.043 ms                                                                                                          |
+-----------------------------------------------------------------------------------------------------------------------------------+
(13 rows)

Time: 0.603 ms

 

 
postgres@postgres#  select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+-----------------+----------+-------------------------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname   | idx_scan |         last_idx_scan         | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+-----------------+----------+-------------------------------+--------------+---------------+
| 379300 |     379304 | public     | empleados | empleados_pkey  |        0 | NULL                          |            0 |             0 |
| 379300 |     379306 | public     | empleados | idx_salario     |        1 | 2024-09-02 12:02:26.712063-07 |            1 |             1 |
| 379300 |     379307 | public     | empleados | idx_puesto      |        1 | 2024-09-02 12:02:23.894723-07 |            1 |             1 |
| 379300 |     379308 | public     | empleados | idx_empleados_nombre_trgm  |        2 | 2024-09-02 12:05:59.723364-07 |            2 |             0 | <-- Ahora usa este index
+--------+------------+------------+-----------+-----------------+----------+-------------------------------+--------------+---------------+
(4 rows)

Time: 1.444 ms


postgres@postgres# drop index idx_salario;
DROP INDEX
Time: 9.215 ms
postgres@postgres# drop index idx_puesto;;
DROP INDEX
Time: 8.153 ms
postgres@postgres# drop index idx_empleados_nombre_trgm ;
DROP INDEX
Time: 7.942 ms



postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+------------------------------+
| relid               | 379300                       |
| schemaname          | public                       |
| relname             | empleados                    |
| seq_scan            | 10                           |
| last_seq_scan       | 2024-09-02 12:04:59.90553-07 |
| seq_tup_read        | 180                          |
| idx_scan            | 0                            | <-- Se eliminaron la cantidad de scan porque eliminamos los indices 
| last_idx_scan       | NULL                         |
| idx_tup_fetch       | 2                            |
| n_tup_ins           | 20                           |
| n_tup_upd           | 0                            |
| n_tup_del           | 0                            |
| n_tup_hot_upd       | 0                            |
| n_tup_newpage_upd   | 0                            |
| n_live_tup          | 20                           |
| n_dead_tup          | 0                            |
| n_mod_since_analyze | 20                           |
| n_ins_since_vacuum  | 20                           |
| last_vacuum         | NULL                         |
| last_autovacuum     | NULL                         |
| last_analyze        | NULL                         |
| last_autoanalyze    | NULL                         |
| vacuum_count        | 0                            |
| autovacuum_count    | 0                            |
| analyze_count       | 0                            |
| autoanalyze_count   | 0                            |
+---------------------+------------------------------+




postgres@postgres# delete from empleados where id >= 10 ;
DELETE 11
Time: 1.186 ms
postgres@postgres#  select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 379300                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 10                            |
| last_seq_scan       | 2024-09-02 12:04:59.90553-07  |
| seq_tup_read        | 180                           |
| idx_scan            | 1                             | <-- Utilizo index para el delete
| last_idx_scan       | 2024-09-02 12:18:50.215356-07 |
| idx_tup_fetch       | 13                            |
| n_tup_ins           | 20                            |
| n_tup_upd           | 0                             |
| n_tup_del           | 11                            |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 9                             |
| n_dead_tup          | 11                            |
| n_mod_since_analyze | 31                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+

Time: 1.199 ms



postgres@postgres#  select * from pg_stat_user_indexes where relname = 'empleados'; 
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan |         last_idx_scan         | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| 379300 |     379304 | public     | empleados | empleados_pkey |        1 | 2024-09-02 12:18:50.215356-07 |           11 |            11 | <- Utilizo el index empleados_pkey 
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
(1 row)

Time: 1.582 ms



postgres@postgres# update empleados set salario = 40000.00 where id = 5;
UPDATE 1
Time: 1.167 ms


postgres@postgres#  select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 379300                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 10                            |
| last_seq_scan       | 2024-09-02 12:04:59.90553-07  |
| seq_tup_read        | 180                           |
| idx_scan            | 2                             |
| last_idx_scan       | 2024-09-02 12:22:30.587368-07 |
| idx_tup_fetch       | 14                            |
| n_tup_ins           | 20                            |
| n_tup_upd           | 1                             |
| n_tup_del           | 11                            |
| n_tup_hot_upd       | 1                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 9                             |
| n_dead_tup          | 12                            |
| n_mod_since_analyze | 32                            |
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+

postgres@postgres#  select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan |         last_idx_scan         | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| 379300 |     379304 | public     | empleados | empleados_pkey |        2 | 2024-09-02 12:22:30.587368-07 |           12 |            12 |
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
(1 row)




postgres@postgres# select relname as tabla,reltuples::bigint as cnt_filas   from pg_class where relname = 'empleados' ;
+-----------+-----------+
|   tabla   | cnt_filas |
+-----------+-----------+
| empleados |        20 |
+-----------+-----------+
(1 row)

Time: 0.577 ms




postgres@postgres# ANALYZE empleados;
ANALYZE
Time: 4.698 ms



postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 379300                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 10                            |
| last_seq_scan       | 2024-09-02 12:04:59.90553-07  |
| seq_tup_read        | 180                           |
| idx_scan            | 2                             |
| last_idx_scan       | 2024-09-02 12:22:30.587368-07 |
| idx_tup_fetch       | 14                            |
| n_tup_ins           | 20                            |
| n_tup_upd           | 1                             |
| n_tup_del           | 11                            |
| n_tup_hot_upd       | 1                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 9                             |
| n_dead_tup          | 12                            |
| n_mod_since_analyze | 0                             | <-- se coloco 0 
| n_ins_since_vacuum  | 20                            |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | 2024-09-02 12:26:11.074278-07 | <--- Colo fecha del ultimo analyze
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 1                             | <-- Se sumo 1
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+




postgres@postgres# select relname as tabla,reltuples::bigint as cnt_filas   from pg_class where relname = 'empleados' ;
+-----------+-----------+
|   tabla   | cnt_filas |
+-----------+-----------+
| empleados |         9 |
+-----------+-----------+
(1 row)




postgres@postgres# SELECT pg_relation_size('public.empleados') AS tamaño;
+--------+
| tamaño |
+--------+
|   8192 |
+--------+
(1 row)




postgres@postgres# vacuum empleados;
VACUUM
Time: 1.094 ms


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 379300                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 10                            |
| last_seq_scan       | 2024-09-02 12:04:59.90553-07  |
| seq_tup_read        | 180                           |
| idx_scan            | 2                             |
| last_idx_scan       | 2024-09-02 12:22:30.587368-07 |
| idx_tup_fetch       | 14                            |
| n_tup_ins           | 20                            |
| n_tup_upd           | 1                             |
| n_tup_del           | 11                            |
| n_tup_hot_upd       | 1                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 9                             |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 0                             |
| n_ins_since_vacuum  | 0                             | <-- se coloco 0  
| last_vacuum         | 2024-09-02 12:29:55.650217-07 |
| last_autovacuum     | NULL                          |
| last_analyze        | 2024-09-02 12:26:11.074278-07 | <-- Se coloco la fecha del ultimo vaccum 
| last_autoanalyze    | NULL                          |
| vacuum_count        | 1                             | <-- Se sumo 1
| autovacuum_count    | 0                             |
| analyze_count       | 1                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+

Time: 1.512 ms







postgres@postgres# create table test_ren (id numeric  , name varchar, fecha timestamp);
CREATE TABLE
Time: 3.099 ms
 
postgres@postgres# insert into test_ren (select generate_series(1,10000000), 'name-'||generate_series(1,10000000), now() + interval '1 minute');
INSERT 0 10000000


postgres@postgres# SELECT pg_size_pretty(pg_relation_size('public.test_ren')) AS tamaño;
+--------+
| tamaño |
+--------+
| 574 MB |
+--------+


postgres@postgres# explain analyze select * from test_ren where id > 100 and id <= 150;
+------------------------------------------------------------------------------------------------------------------------------+
|                                                          QUERY PLAN                                                          |
+------------------------------------------------------------------------------------------------------------------------------+
| Gather  (cost=1000.00..99829.30 rows=29776 width=72) (actual time=0.613..435.627 rows=50 loops=1)                            |
|   Workers Planned: 4                                                                                                         |
|   Workers Launched: 4                                                                                                        |
|   ->  Parallel Seq Scan on test_ren  (cost=0.00..95851.70 rows=7444 width=72) (actual time=329.410..414.049 rows=10 loops=5) |
|         Filter: ((id > '100'::numeric) AND (id <= '150'::numeric))                                                           |
|         Rows Removed by Filter: 1999990                                                                                      |
| Planning Time: 0.059 ms                                                                                                      |
| Execution Time: 435.650 ms                                                                                                   |
+------------------------------------------------------------------------------------------------------------------------------+
(8 rows)





postgres@postgres# create table test_ren2 (id numeric primary key, name varchar, fecha timestamp);
CREATE TABLE
Time: 3.099 ms
 

postgres@postgres# insert into test_ren2 (select generate_series(1,100000000), 'name-'||generate_series(1,100000000), now() + interval '1 minute');
INSERT 0 10000000
Time: 37568.173 ms (00:37.568)


postgres@postgres#  CREATE INDEX idx_test_ren2 ON public.test_ren2( name );
CREATE INDEX
Time: 22373.994 ms (00:22.374)


postgres@postgres# SELECT pg_size_pretty(pg_relation_size('public.test_ren2')) AS tamaño;
+--------+
| tamaño |
+--------+
| 5744 MB |
+--------+


postgres@postgres# explain (VERBOSE,ANALYZE, COSTS , TIMING  , BUFFERS , FORMAT TEXT)  select * from test_ren2 where name = 'name-1000';
+---------------------------------------------------------------------------------------------------------------------------------+
|                                                           QUERY PLAN                                                            |
+---------------------------------------------------------------------------------------------------------------------------------+
| Index Scan using idx_test_ren2 on public.test_ren2  (cost=0.43..8.45 rows=1 width=26) (actual time=0.035..0.037 rows=1 loops=1) |
|   Output: id, name, fecha                                                                                                       |
|   Index Cond: ((test_ren2.name)::text = 'name-1000'::text)                                                                      |
|   Buffers: shared hit=4                                                                                                         |
| Query Identifier: -6236392808936392905                                                                                          |
| Planning Time: 0.081 ms                                                                                                         |
| Execution Time: 0.055 ms                                                                                                        |
+---------------------------------------------------------------------------------------------------------------------------------+



postgres@postgres# select * from pg_stat_user_tables where relname =  'test_ren2';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 379434                        |
| schemaname          | public                        |
| relname             | test_ren2                     |
| seq_scan            | 1                             |
| last_seq_scan       | 2024-09-02 15:57:11.750776-07 |
| seq_tup_read        | 0                             |
| idx_scan            | 0                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 100000001                     |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 100000000                     |
| n_dead_tup          | 1                             |
| n_mod_since_analyze | 100000000                     |
| n_ins_since_vacuum  | 100000001                     |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+





postgres@postgres# delete from test_ren2 where id >= 1000;
DELETE 99999001
Time: 103848.778 ms (01:43.849)


postgres@postgres# SELECT pg_size_pretty(pg_relation_size('public.test_ren2')) AS tamaño;
+--------+
| tamaño |
+--------+
| 5744 MB |
+--------+


 

postgres@postgres# select * from pg_stat_user_tables where relname =  'test_ren2';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 379434                        |
| schemaname          | public                        |
| relname             | test_ren2                     |
| seq_scan            | 2                             |
| last_seq_scan       | 2024-09-02 16:04:51.195357-07 |
| seq_tup_read        | 100000000                     |
| idx_scan            | 0                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 100000001                     |
| n_tup_upd           | 0                             |
| n_tup_del           | 99999001                      |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 999                           |
| n_dead_tup          | 99999002                      |  <---- cantidad de filas usadas 
| n_mod_since_analyze | 199999001                     | <---- deja las tuplas muertas 
| n_ins_since_vacuum  | 100000001                     |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+

  

 


postgres@postgres# VACUUM FULL test_ren2;
VACUUM
Time: 17937.319 ms (00:17.937)


 postgres@postgres# select * from pg_stat_user_tables where relname =  'test_ren2';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 379434                        |
| schemaname          | public                        |
| relname             | test_ren2                     |
| seq_scan            | 6                             |
| last_seq_scan       | 2024-09-02 16:07:50.346114-07 |
| seq_tup_read        | 252471278                     |
| idx_scan            | 0                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 100000001                     |
| n_tup_upd           | 0                             |
| n_tup_del           | 99999001                      |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 999                           |
| n_dead_tup          | 99999002                      | <-- Siguen las tuplas muertas 
| n_mod_since_analyze | 199999001                     |
| n_ins_since_vacuum  | 100000001                     |
| last_vacuum         | NULL                          | <-- no se conto el vacuum full 
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+



postgres@postgres# SELECT pg_size_pretty(pg_relation_size('public.test_ren2')) AS tamaño;
+-[ RECORD 1 ]---+
| tamaño | 56 kB |
+--------+-------+



postgres@postgres#  delete from test_ren3 where id >= 1000;
DELETE 99999001
Time: 83691.847 ms (01:23.692)

postgres@postgres# SELECT pg_size_pretty(pg_relation_size('public.test_ren3')) AS tamaño;
+-[ RECORD 1 ]-----+
| tamaño | 5744 MB |
+--------+---------+



postgres@postgres# vacuum test_ren3;
VACUUM
Time: 4086980.088 ms (01:08:06.980)


postgres@postgres# SELECT pg_size_pretty(pg_relation_size('public.test_ren3')) AS tamaño;
+-[ RECORD 1 ]---+
| tamaño | 56 kB |
+--------+-------+


postgres@postgres#  select * from pg_stat_user_tables where relname =  'test_ren3';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 379441                        |
| schemaname          | public                        |
| relname             | test_ren3                     |
| seq_scan            | 2                             |
| last_seq_scan       | 2024-09-02 16:10:58.449345-07 |
| seq_tup_read        | 100000000                     |
| idx_scan            | 0                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 100000000                     |
| n_tup_upd           | 0                             |
| n_tup_del           | 99999001                      |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 999                           |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 0                             |
| n_ins_since_vacuum  | 0                             |
| last_vacuum         | 2024-09-02 17:19:25.435126-07 |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | 2024-09-02 17:19:43.335175-07 |
| vacuum_count        | 1                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 1                             |
+---------------------+-------------------------------+



----------- Test index compuestos 



  ```
