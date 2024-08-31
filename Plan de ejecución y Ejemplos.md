 
### ¿Qué es un plan de ejecución?
Un plan de ejecución muestra cómo PostgreSQL va a escanear las tablas involucradas en una consulta, ya sea mediante un escaneo secuencial, un escaneo de índice, etc. También muestra qué algoritmos de unión se utilizarán si hay múltiples tablas involucradas¹.


 
### Tipos de Plan de Ejecución

1. **Seq Scan (Sequential Scan)**:
   - **Descripción**: Escaneo secuencial de todas las filas de una tabla.
   - **Uso**: Se utiliza cuando no hay índices disponibles o cuando el planificador estima que un escaneo secuencial es más eficiente.
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
   SET enable_seqscan = OFF;
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
-- Crear la tabla
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
| seq_scan            | 1                             | <------------- 
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
| n_tup_ins           | 20                            | <-------------
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



postgres@postgres# select * from pg_indexes where tablename = 'empleados';
+------------+-----------+----------------+------------+-------------------------------------------------------------------------+
| schemaname | tablename |   indexname    | tablespace |                                indexdef                                 |
+------------+-----------+----------------+------------+-------------------------------------------------------------------------+
| public     | empleados | empleados_pkey | NULL       | CREATE UNIQUE INDEX empleados_pkey ON public.empleados USING btree (id) |
+------------+-----------+----------------+------------+-------------------------------------------------------------------------+



postgres@postgres# CREATE INDEX idx_salario ON public.empleados( salario  );
CREATE INDEX
Time: 2.477 ms

postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+------------------------------+
| relid               | 375623                       |
| schemaname          | public                       |
| relname             | empleados                    |
| seq_scan            | 2                            |   <-------------
| last_seq_scan       | 2024-08-30 18:12:02.95301-07 |
| seq_tup_read        | 20                           |   <-------------
| idx_scan            | 0                            |
| last_idx_scan       | NULL                         |
| idx_tup_fetch       | 0                            |
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

postgres@postgres# CREATE INDEX idx_puesto ON public.empleados( puesto );
CREATE INDEX
Time: 2.147 ms
postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 3                             | <-------------
| last_seq_scan       | 2024-08-30 18:13:55.387233-07 |
| seq_tup_read        | 40                            | <-------------
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



postgres@postgres# select * from pg_indexes where tablename = 'empleados';
+------------+-----------+----------------+------------+-------------------------------------------------------------------------+
| schemaname | tablename |   indexname    | tablespace |                                indexdef                                 |
+------------+-----------+----------------+------------+-------------------------------------------------------------------------+
| public     | empleados | empleados_pkey | NULL       | CREATE UNIQUE INDEX empleados_pkey ON public.empleados USING btree (id) |
| public     | empleados | idx_salario  | NULL       | CREATE INDEX idx_salario ON public.empleados USING btree (salario)    |
| public     | empleados | idx_puesto     | NULL       | CREATE INDEX idx_puesto ON public.empleados USING btree (puesto)        |
+------------+-----------+----------------+------------+-------------------------------------------------------------------------+
(3 rows)

Time: 1.211 ms



postgres@postgres# select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan | last_idx_scan | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| 375623 |     375627 | public     | empleados | empleados_pkey |        0 | NULL          |            0 |             0 |
| 375623 |     375629 | public     | empleados | idx_salario  |        0 | NULL          |            0 |             0 |
| 375623 |     375630 | public     | empleados | idx_puesto     |        0 | NULL          |            0 |             0 |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+



postgres@postgres#  select * from empleados;
+----+------------------+---------------+----------+
| id |      nombre      |    puesto     | salario  |
+----+------------------+---------------+----------+
|  1 | Juan Pérez       | Desarrollador | 50000.00 |
|  2 | María López      | Analista      | 45000.00 |
|  3 | Carlos Sánchez   | Gerente       | 60000.00 |
|  4 | Ana Gómez        | Diseñadora    | 40000.00 |
|  5 | Luis Fernández   | Desarrollador | 52000.00 |
|  6 | Laura Martínez   | Analista      | 47000.00 |
|  7 | Pedro García     | Gerente       | 62000.00 |
|  8 | Sofía Rodríguez  | Diseñadora    | 42000.00 |
|  9 | Miguel Torres    | Desarrollador | 51000.00 |
| 10 | Lucía Ramírez    | Analista      | 46000.00 |
| 11 | Jorge Hernández  | Gerente       | 61000.00 |
| 12 | Elena Díaz       | Diseñadora    | 41000.00 |
| 13 | Raúl Morales     | Desarrollador | 53000.00 |
| 14 | Isabel Ruiz      | Analista      | 48000.00 |
| 15 | Fernando Jiménez | Gerente       | 63000.00 |
| 16 | Patricia Ortiz   | Diseñadora    | 43000.00 |
| 17 | Andrés Castro    | Desarrollador | 54000.00 |
| 18 | Marta Vega       | Analista      | 49000.00 |
| 19 | Ricardo Soto     | Gerente       | 64000.00 |
| 20 | Carmen Silva     | Diseñadora    | 44000.00 |
+----+------------------+---------------+----------+




postgres@postgres#  select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 4                             |  <-------------
| last_seq_scan       | 2024-08-30 18:16:04.190653-07 |
| seq_tup_read        | 60                            |  <-------------
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



postgres@postgres#  select * from empleados limit 1;
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)

Time: 0.429 ms
postgres@postgres#  select * from empleados limit 1;
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)

Time: 0.445 ms
postgres@postgres#  select * from empleados limit 1;
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)

Time: 0.438 ms
postgres@postgres#  select * from empleados limit 1;
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)

Time: 0.459 ms

postgres@postgres#  select * from empleados limit 1;
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)

Time: 0.459 ms


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados' limit 1;
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 9                             | <-------------
| last_seq_scan       | 2024-08-30 18:17:40.397044-07 |
| seq_tup_read        | 65                            | <-------------
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


postgres@postgres#  select * from empleados where nombre =  'Juan Pérez';
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)

postgres@postgres#  select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan | last_idx_scan | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| 375623 |     375627 | public     | empleados | empleados_pkey |        0 | NULL          |            0 |             0 |
| 375623 |     375629 | public     | empleados | idx_empleados  |        0 | NULL          |            0 |             0 |
| 375623 |     375630 | public     | empleados | idx_puesto     |        0 | NULL          |            0 |             0 |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+


postgres@postgres#  select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+------------------------------+
| relid               | 375623                       |
| schemaname          | public                       |
| relname             | empleados                    |
| seq_scan            | 10                           | <-------------
| last_seq_scan       | 2024-08-30 18:19:23.96692-07 |
| seq_tup_read        | 85                           |  <------------- para encontrarlo tuvo que leer los 20 registros 
| idx_scan            | 0                            |
| last_idx_scan       | NULL                         |
| idx_tup_fetch       | 0                            |
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
 



postgres@postgres# select * from empleados where puesto =  'Desarrollador';
+----+----------------+---------------+----------+
| id |     nombre     |    puesto     | salario  |
+----+----------------+---------------+----------+
|  1 | Juan Pérez     | Desarrollador | 50000.00 |
|  5 | Luis Fernández | Desarrollador | 52000.00 |
|  9 | Miguel Torres  | Desarrollador | 51000.00 |
| 13 | Raúl Morales   | Desarrollador | 53000.00 |
| 17 | Andrés Castro  | Desarrollador | 54000.00 |
+----+----------------+---------------+----------+

postgres@postgres#  select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan | last_idx_scan | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| 375623 |     375627 | public     | empleados | empleados_pkey |        0 | NULL          |            0 |             0 |
| 375623 |     375629 | public     | empleados | idx_empleados  |        0 | NULL          |            0 |             0 |
| 375623 |     375630 | public     | empleados | idx_puesto     |        0 | NULL          |            0 |             0 |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 11                            |  <------------- 
| last_seq_scan       | 2024-08-30 18:21:50.294104-07 |
| seq_tup_read        | 105                           |  <------------- otra vez leyo todo
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


postgres@postgres# select * from empleados where salario  = 50000.00;
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+


postgres@postgres# select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan | last_idx_scan | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| 375623 |     375627 | public     | empleados | empleados_pkey |        0 | NULL          |            0 |             0 |
| 375623 |     375629 | public     | empleados | idx_empleados  |        0 | NULL          |            0 |             0 |
| 375623 |     375630 | public     | empleados | idx_puesto     |        0 | NULL          |            0 |             0 |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 12                            | <------------- 
| last_seq_scan       | 2024-08-30 18:27:25.868185-07 |
| seq_tup_read        | 125                           | <-------------  sigue sin usar index y sigue leyendo los 20 registros
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


postgres@postgres#  select * from empleados where id= 15 ;
+----+------------------+---------+----------+
| id |      nombre      | puesto  | salario  |
+----+------------------+---------+----------+
| 15 | Fernando Jiménez | Gerente | 63000.00 |
+----+------------------+---------+----------+
(1 row)

Time: 0.505 ms
postgres@postgres# select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan | last_idx_scan | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+
| 375623 |     375627 | public     | empleados | empleados_pkey |        0 | NULL          |            0 |             0 |
| 375623 |     375629 | public     | empleados | idx_empleados  |        0 | NULL          |            0 |             0 |
| 375623 |     375630 | public     | empleados | idx_puesto     |        0 | NULL          |            0 |             0 |
+--------+------------+------------+-----------+----------------+----------+---------------+--------------+---------------+

postgres@postgres#  select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 13                            | <------------- 
| last_seq_scan       | 2024-08-30 18:34:52.565472-07 |
| seq_tup_read        | 145                           | <------------- 
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



postgres@postgres#  SET enable_seqscan = off;
SET
Time: 0.361 ms


postgres@postgres#  select * from empleados where id= 15 ;
+----+------------------+---------+----------+
| id |      nombre      | puesto  | salario  |
+----+------------------+---------+----------+
| 15 | Fernando Jiménez | Gerente | 63000.00 |
+----+------------------+---------+----------+
(1 row)

Time: 0.438 ms
postgres@postgres# select * from empleados where salario  = 50000.00;
+----+------------+---------------+----------+
| id |   nombre   |    puesto     | salario  |
+----+------------+---------------+----------+
|  1 | Juan Pérez | Desarrollador | 50000.00 |
+----+------------+---------------+----------+
(1 row)

Time: 0.485 ms


postgres@postgres#  select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan |         last_idx_scan         | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| 375623 |     375627 | public     | empleados | empleados_pkey |        1 | 2024-08-30 19:12:22.142953-07 |            1 |             1 |
| 375623 |     375629 | public     | empleados | idx_empleados  |        1 | 2024-08-30 19:12:28.687695-07 |            1 |             1 |
| 375623 |     375630 | public     | empleados | idx_puesto     |        0 | NULL                          |            0 |             0 |
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
(3 rows)

Time: 1.341 ms


postgres@postgres#  select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 17                            |
| last_seq_scan       | 2024-08-30 18:58:49.00407-07  |
| seq_tup_read        | 225                           |
| idx_scan            | 2                             |
| last_idx_scan       | 2024-08-30 19:12:28.687695-07 |
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



postgres@postgres# select * from empleados where puesto =  'Desarrollador';
+----+----------------+---------------+----------+
| id |     nombre     |    puesto     | salario  |
+----+----------------+---------------+----------+
|  1 | Juan Pérez     | Desarrollador | 50000.00 |
|  5 | Luis Fernández | Desarrollador | 52000.00 |
|  9 | Miguel Torres  | Desarrollador | 51000.00 |
| 13 | Raúl Morales   | Desarrollador | 53000.00 |
| 17 | Andrés Castro  | Desarrollador | 54000.00 |
+----+----------------+---------------+----------+

postgres@postgres# select * from pg_stat_user_indexes where relname = 'empleados';
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| relid  | indexrelid | schemaname |  relname  |  indexrelname  | idx_scan |         last_idx_scan         | idx_tup_read | idx_tup_fetch |
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+
| 375623 |     375627 | public     | empleados | empleados_pkey |        1 | 2024-08-30 19:12:22.142953-07 |            1 |             1 |
| 375623 |     375629 | public     | empleados | idx_empleados  |        1 | 2024-08-30 19:12:28.687695-07 |            1 |             1 |
| 375623 |     375630 | public     | empleados | idx_puesto     |        1 | 2024-08-30 19:14:32.612748-07 |            5 |             5 |
+--------+------------+------------+-----------+----------------+----------+-------------------------------+--------------+---------------+


postgres@postgres# select * from pg_stat_user_tables where relname =  'empleados';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 375623                        |
| schemaname          | public                        |
| relname             | empleados                     |
| seq_scan            | 17                            |
| last_seq_scan       | 2024-08-30 18:58:49.00407-07  |
| seq_tup_read        | 225                           |
| idx_scan            | 3                             |
| last_idx_scan       | 2024-08-30 19:14:32.612748-07 |
| idx_tup_fetch       | 7                             |
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


```
