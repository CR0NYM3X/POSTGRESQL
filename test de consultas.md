 # Test de index en tablas grandes 
```sql
postgres@postgres# CREATE TABLE ventas (
    id SERIAL PRIMARY KEY ,
    fecha DATE,
    cliente_id INTEGER,
    producto_id INTEGER,
    cantidad INTEGER,
    precio NUMERIC
);
CREATE TABLE
Time: 5.363 ms


postgres@postgres# INSERT INTO ventas ( fecha, cliente_id, producto_id, cantidad, precio)
postgres-# SELECT
postgres-#     NOW() - INTERVAL '1 day' * (RANDOM() * 1000)::int,
postgres-#     (RANDOM() * 1000)::int,
postgres-#     (RANDOM() * 100)::int,
postgres-#     (RANDOM() * 10)::int,
postgres-#     (RANDOM() * 100)::numeric
postgres-# FROM generate_series(1, 500000000);
INSERT 0 500000000
Time: 2168710.545 ms (36:08.711) --> 36.14 Min


postgres@postgres# \dt+ ventas
                                    List of relations
+--------+--------+-------+----------+-------------+---------------+-------+-------------+
| Schema |  Name  | Type  |  Owner   | Persistence | Access method | Size  | Description |
+--------+--------+-------+----------+-------------+---------------+-------+-------------+
| public | ventas | table | postgres | permanent   | heap          | 32 GB |             |
+--------+--------+-------+----------+-------------+---------------+-------+-------------+


postgres@postgres# select * from ventas limit 5;
+----+------------+------------+-------------+----------+------------------+
| id |   fecha    | cliente_id | producto_id | cantidad |      precio      |
+----+------------+------------+-------------+----------+------------------+
|  1 | 2023-06-28 |        438 |          34 |        4 | 61.4929175298549 |
|  2 | 2022-10-13 |        667 |          35 |        7 |  57.816286121425 |
|  3 | 2022-06-18 |         13 |          78 |        6 | 40.5579568930936 |
|  4 | 2022-05-16 |        465 |          38 |        0 | 95.9020711269063 |
|  5 | 2023-02-06 |        692 |          10 |        2 | 33.4089523243713 |
+----+------------+------------+-------------+----------+------------------+
(5 rows)



postgres@postgres# explain analyze select * from ventas where producto_id =  4;
+------------------------------------------------------------------------------------------------------------------------------------+
|                                                             QUERY PLAN                                                             |
+------------------------------------------------------------------------------------------------------------------------------------+
| Gather  (cost=1000.00..4998631.12 rows=2105787 width=52) (actual time=0.638..13495.132 rows=5003369 loops=1)                       |
|   Workers Planned: 8                                                                                                               |
|   Workers Launched: 8                                                                                                              |
|   ->  Parallel Seq Scan on ventas  (cost=0.00..4787052.42 rows=263223 width=52) (actual time=0.078..13449.838 rows=555930 loops=9) |
|         Filter: (producto_id = 4)                                                                                                  |
|         Rows Removed by Filter: 54999626                                                                                           |
| Planning Time: 0.076 ms                                                                                                            |
| Execution Time: 13685.493 ms                                                                                                       |
+------------------------------------------------------------------------------------------------------------------------------------+
(8 rows)


postgres@postgres# select * from pg_stat_user_tables where relname = 'ventas';
+-[ RECORD 1 ]--------+-------------------------------+
| relid               | 384911                        |
| schemaname          | public                        |
| relname             | ventas                        |
| seq_scan            | 21                            |
| last_seq_scan       | 2024-09-04 15:21:33.602964-07 |
| seq_tup_read        | 1000000006                    |
| idx_scan            | 0                             |
| last_idx_scan       | NULL                          |
| idx_tup_fetch       | 0                             |
| n_tup_ins           | 500000000                     |
| n_tup_upd           | 0                             |
| n_tup_del           | 0                             |
| n_tup_hot_upd       | 0                             |
| n_tup_newpage_upd   | 0                             |
| n_live_tup          | 500000000                     |
| n_dead_tup          | 0                             |
| n_mod_since_analyze | 500000000                     |
| n_ins_since_vacuum  | 500000000                     |
| last_vacuum         | NULL                          |
| last_autovacuum     | NULL                          |
| last_analyze        | NULL                          |
| last_autoanalyze    | NULL                          |
| vacuum_count        | 0                             |
| autovacuum_count    | 0                             |
| analyze_count       | 0                             |
| autoanalyze_count   | 0                             |
+---------------------+-------------------------------+



postgres@postgres# CREATE INDEX  index_ventas ON public.ventas( cliente_id, producto_id ,cantidad );
CREATE INDEX
Time: 291871.245 ms (04:51.871)



postgres@postgres# explain analyze select * from ventas where cliente_id =  667 and producto_id = 35 and cantidad  = 7  ;
+---------------------------------------------------------------------------------------------------------------------------+
|                                                        QUERY PLAN                                                         |
+---------------------------------------------------------------------------------------------------------------------------+
| Index Scan using index_ventas on ventas  (cost=0.57..257.99 rows=63 width=52) (actual time=0.143..0.903 rows=502 loops=1) |
|   Index Cond: ((cliente_id = 667) AND (producto_id = 35) AND (cantidad = 7))                                              |
| Planning Time: 0.079 ms                                                                                                   |
| Execution Time: 0.938 ms                                                                                                  |
+---------------------------------------------------------------------------------------------------------------------------+
(4 rows)



postgres@postgres# explain analyze select * from ventas where cliente_id =  667 and producto_id = 35   ;
+------------------------------------------------------------------------------------------------------------------------------+
|                                                          QUERY PLAN                                                          |
+------------------------------------------------------------------------------------------------------------------------------+
| Bitmap Heap Scan on ventas  (cost=176.70..48233.34 rows=12500 width=52) (actual time=1.855..24.716 rows=4997 loops=1)        |
|   Recheck Cond: ((cliente_id = 667) AND (producto_id = 35))                                                                  |
|   Heap Blocks: exact=4995                                                                                                    |
|   ->  Bitmap Index Scan on index_ventas  (cost=0.00..173.57 rows=12500 width=0) (actual time=1.032..1.032 rows=4997 loops=1) |
|         Index Cond: ((cliente_id = 667) AND (producto_id = 35))                                                              |
| Planning Time: 0.076 ms                                                                                                      |
| Execution Time: 25.032 ms                                                                                                    |
+------------------------------------------------------------------------------------------------------------------------------+
(7 rows)



postgres@postgres# explain analyze  select * from ventas where cliente_id =  667    ;
+-----------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                  QUERY PLAN                                                                   |
+-----------------------------------------------------------------------------------------------------------------------------------------------+
| Gather  (cost=29331.57..4699726.49 rows=2500000 width=52) (actual time=284.578..1183.004 rows=499618 loops=1)                                 | <--- Nada eficiente 
|   Workers Planned: 7                                                                                                                          |
|   Workers Launched: 7                                                                                                                         |
|   ->  Parallel Bitmap Heap Scan on ventas  (cost=28331.57..4448726.49 rows=357143 width=52) (actual time=279.583..900.257 rows=62452 loops=8) |
|         Recheck Cond: (cliente_id = 667)                                                                                                      |
|         Heap Blocks: exact=55484                                                                                                              |
|         ->  Bitmap Index Scan on index_ventas  (cost=0.00..27706.57 rows=2500000 width=0) (actual time=136.879..136.880 rows=499618 loops=1)  |
|               Index Cond: (cliente_id = 667)                                                                                                  |
| Planning Time: 0.075 ms                                                                                                                       |
| Execution Time: 1200.899 ms                                                                                                                   |
+-----------------------------------------------------------------------------------------------------------------------------------------------+
(10 rows)



postgres@postgres# explain analyze select * from ventas where   producto_id = 35 and cantidad  = 7  ;
+---------------------------------------------------------------------------------------------------------------------------------+
|                                                           QUERY PLAN                                                            |
+---------------------------------------------------------------------------------------------------------------------------------+
| Gather  (cost=1000.00..5068744.00 rows=12500 width=52) (actual time=0.724..20523.681 rows=499280 loops=1)                       |
|   Workers Planned: 8                                                                                                            |
|   Workers Launched: 8                                                                                                           |
|   ->  Parallel Seq Scan on ventas  (cost=0.00..5066494.00 rows=1562 width=52) (actual time=4.103..20477.073 rows=55476 loops=9) |
|         Filter: ((producto_id = 35) AND (cantidad = 7))                                                                         |
|         Rows Removed by Filter: 55500080                                                                                        |
| Planning Time: 0.076 ms                                                                                                         |
| Execution Time: 20545.733 ms                                                                                                    |
+---------------------------------------------------------------------------------------------------------------------------------+
(8 rows)




postgres@postgres#  CREATE INDEX  index_ventas_fecha ON public.ventas( fecha );
CREATE INDEX
Time: 194740.262 ms (03:14.740)
postgres@postgres#




postgres@postgres# explain analyze select * from ventas where fecha = '2022-10-13'  ;
+-------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                     QUERY PLAN
+-------------------------------------------------------------------------------------------------------------------------------------------------
| Gather  (cost=28839.57..4699234.49 rows=2500000 width=52) (actual time=324.720..40747.527 rows=499310 loops=1)
|   Workers Planned: 7
|   Workers Launched: 7
|   ->  Parallel Bitmap Heap Scan on ventas  (cost=27839.57..4448234.49 rows=357143 width=52) (actual time=304.548..40665.469 rows=62414 loops=8)
|         Recheck Cond: (fecha = '2022-10-13'::date)
|         Heap Blocks: exact=61033
|         ->  Bitmap Index Scan on index_ventas_fecha  (cost=0.00..27214.57 rows=2500000 width=0) (actual time=167.584..167.584 rows=499310 loops=1) |
|               Index Cond: (fecha = '2022-10-13'::date)
| Planning Time: 8.241 ms  
| Execution Time: 40771.744 ms
+-------------------------------------------------------------------------------------------------------------------------------------------------
(10 rows)


Time: 40788.206 ms (00:40.788)
postgres@postgres# explain analyze select * from ventas where fecha = '2022-10-13'  ;
+-------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                     QUERY PLAN
+----------------------------------------------------------------------------------------------------------------------------------------------------+
| Gather  (cost=28839.57..4699234.49 rows=2500000 width=52) (actual time=308.946..1112.975 rows=499310 loops=1)   |
|   Workers Planned: 7   |
|   Workers Launched: 7   |
|   ->  Parallel Bitmap Heap Scan on ventas  (cost=27839.57..4448234.49 rows=357143 width=52) (actual time=302.615..1005.798 rows=62414 loops=8)  |
|         Recheck Cond: (fecha = '2022-10-13'::date)   |
|         Heap Blocks: exact=68286   |
|         ->  Bitmap Index Scan on index_ventas_fecha  (cost=0.00..27214.57 rows=2500000 width=0) (actual time=145.996..145.997 rows=499310 loops=1) |
|               Index Cond: (fecha = '2022-10-13'::date)
| Planning Time: 0.101 ms   |
| Execution Time: 1131.128 ms  |
+----------------------------------------------------------------------------------------------------------------------------------------------------+
(10 rows)



postgres@postgres# explain analyze select * from ventas where fecha = '2022-10-13'  ;
+-------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                     QUERY PLAN
+-------------------------------------------------------------------------------------------------------------------------------------------------
---+
| Gather  (cost=28839.57..4699234.49 rows=2500000 width=52) (actual time=426.213..1237.512 rows=499310 loops=1)
|   Workers Planned: 7
|   Workers Launched: 7
|   ->  Parallel Bitmap Heap Scan on ventas  (cost=27839.57..4448234.49 rows=357143 width=52) (actual time=420.449..1131.740 rows=62414 loops=8)
|         Recheck Cond: (fecha = '2022-10-13'::date)
|         Heap Blocks: exact=69048
|         ->  Bitmap Index Scan on index_ventas_fecha  (cost=0.00..27214.57 rows=2500000 width=0) (actual time=186.249..186.249 rows=499310 loops=1) |
|               Index Cond: (fecha = '2022-10-13'::date)
| Planning Time: 0.106 ms
| Execution Time: 1256.034 ms
+-------------------------------------------------------------------------------------------------------------------------------------------------
---+
(10 rows)



 
``` 



# Test de autovacuum


```sql
 

postgres@postgres# drop table ejemplo_autovacuum;
DROP TABLE
Time: 13.007 ms


postgres@postgres# CREATE TABLE ejemplo_autovacuum (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE
Time: 5.365 ms


postgres@postgres# select  name,setting,unit from pg_settings where name in('autovacuum','autovacuum_naptime','autovacuum_vacuum_threshold','autovacuum_analyze_threshold','autovacuum_vacuum_scale_factor','autovacuum_analyze_scale_factor','autovacuum_vacuum_insert_scale_factor','autovacuum_vacuum_insert_threshold')   ;
+---------------------------------------+---------+------+
|                 name                  | setting | unit |
+---------------------------------------+---------+------+
| autovacuum                            | on      | NULL |
| autovacuum_analyze_scale_factor       | 0.2     | NULL |
| autovacuum_analyze_threshold          | 50000   | NULL |
| autovacuum_naptime                    | 300     | s    | <--- 300 seg = 5 min
| autovacuum_vacuum_insert_scale_factor | 0.2     | NULL |
| autovacuum_vacuum_insert_threshold    | 100000  | NULL |
| autovacuum_vacuum_scale_factor        | 0.4     | NULL |
| autovacuum_vacuum_threshold           | 100000  | NULL |
+---------------------------------------+---------+------+

(8 rows)

----> Esto para que el vacum se ejecute cada 5s y para que las pruebas sean mas rápido , una vez finalizada las pruebas se regresa a su valor original
postgres@postgres# alter system set autovacuum_naptime = 5;
ALTER SYSTEM
Time: 3.298 ms

postgres@postgres# select pg_reload_conf();
+----------------+
| pg_reload_conf |
+----------------+
| t              |
+----------------+
(1 row)


Time: 0.443 ms
postgres@postgres# show autovacuum_naptime;
+--------------------+
| autovacuum_naptime |
+--------------------+
| 30s                |
+--------------------+
(1 row)



/*  configurarle  autovacuum a una sola tabla */
postgres@postgres#  ALTER TABLE ejemplo_autovacuum SET (
    autovacuum_vacuum_threshold = 50,
    autovacuum_analyze_threshold = 60,
    autovacuum_vacuum_scale_factor = 0.2,
    autovacuum_analyze_scale_factor = 0.1
    autovacuum_vacuum_insert_scale_factor = 0.05,
    autovacuum_vacuum_insert_threshold = 200
);
ALTER TABLE
Time: 2.606 ms



postgres@postgres# SELECT c.relname AS table_name,o.option_name,o.option_value FROM pg_class c JOIN  pg_namespace n ON n.oid = c.relnamespace JOIN pg_options_to_table(c.reloptions) o ON true WHERE c.relname = 'ejemplo_autovacuum';	
+--------------------+---------------------------------------+--------------+
|     table_name     |              option_name              | option_value |
+--------------------+---------------------------------------+--------------+
| ejemplo_autovacuum | autovacuum_enabled                    | true         |
| ejemplo_autovacuum | autovacuum_vacuum_threshold           | 50           |
| ejemplo_autovacuum | autovacuum_analyze_threshold          | 50           |
| ejemplo_autovacuum | autovacuum_vacuum_scale_factor        | 0.2          |
| ejemplo_autovacuum | autovacuum_analyze_scale_factor       | 0.1          |
| ejemplo_autovacuum | autovacuum_vacuum_insert_scale_factor | 0.05         |
| ejemplo_autovacuum | autovacuum_vacuum_insert_threshold    | 200          |
+--------------------+---------------------------------------+--------------+
(7 rows)



postgres@postgres# select * from pg_stat_activity where query ilike '%VACUUM%' and not pid = pg_backend_pid() and state != 'idle';
(0 rows)


postgres@postgres# SELECT * FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+-[ RECORD 1 ]--------+------------------------------+
| relid               | 388756                       |
| schemaname          | public                       |
| relname             | ejemplo_autovacuum           |
| seq_scan            | 1                            |
| last_seq_scan       | 2024-09-05 09:58:51.79725-07 |
| seq_tup_read        | 0                            |
| idx_scan            | 0                            |
| last_idx_scan       | NULL                         |
| idx_tup_fetch       | 0                            |
| n_tup_ins           | 0                            |
| n_tup_upd           | 0                            |
| n_tup_del           | 0                            |
| n_tup_hot_upd       | 0                            |
| n_tup_newpage_upd   | 0                            |
| n_live_tup          | 0                            |
| n_dead_tup          | 0                            |
| n_mod_since_analyze | 0                            |
| n_ins_since_vacuum  | 0                            |
| last_vacuum         | NULL                         |
| last_autovacuum     | NULL                         |
| last_analyze        | NULL                         |
| last_autoanalyze    | NULL                         |
| vacuum_count        | 0                            |
| autovacuum_count    | 0                            |
| analyze_count       | 0                            |
| autoanalyze_count   | 0                            |
+---------------------+------------------------------+

 

/******** VALIDAREMOS EL autovacuum_analyze_threshold  ********/
-----> Detonante: Cuando la tabla es nueva valida el parámetro autovacuum_analyze_threshold , en este caso su valor es de 50 y cuando la columna n_mod_since_analyze de la tabla pg_stat_user_tables supera ese valor, entonces ahi es cuando ejecuta el autoanalyze y coloca 0 en la columna n_mod_since_analyze
-----> Detonante tablas existentes: Cuando la tabla ya tiene registros y se ejecutan (insert, update o delete ) se va llenando la columna n_mod_since_analyze de la tabla pg_stat_user_tables , postgresql realiza el calculo siguiente n_mod_since_analyze > ( autovacuum_analyze_threshold + ( autovacuum_analyze_scale_factor + autovacuum_analyze_threshold ) ) y en caso de que   supere ese valor, entonces detonará el autoanalyze  y coloca 0 en la columna n_mod_since_analyze
---		En este ejemplo quedaria asi: 60 + (0.1 * 60) = 66 

postgres@postgres#   INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 60) AS s(i);
INSERT 0 65

postgres@postgres# SELECT n_mod_since_analyze,last_autoanalyze,autoanalyze_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+---------------------+------------------+-------------------+
| n_mod_since_analyze | last_autoanalyze | autoanalyze_count |
+---------------------+------------------+-------------------+
|                  50 | NULL             |                 0 |
+---------------------+------------------+-------------------+
(1 row)


postgres@postgres# INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 1) AS s(i);
INSERT 0 1
Time: 1.149 ms
 
 
postgres@postgres# SELECT n_mod_since_analyze,last_autoanalyze,autoanalyze_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+---------------------+-------------------------------+-------------------+
| n_mod_since_analyze |       last_autoanalyze        | autoanalyze_count |
+---------------------+-------------------------------+-------------------+
|                   0 | 2024-09-05 15:17:02.283175-07 |                 1 | <--- Aqui ya supero el valor 60 que estaba en autovacuum_analyze_threshold
+---------------------+-------------------------------+-------------------+



postgres@postgres# INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 66) AS s(i);
INSERT 0 65
Time: 3.130 ms

postgres@postgres# SELECT n_mod_since_analyze,last_autoanalyze,autoanalyze_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+---------------------+-------------------------------+-------------------+
| n_mod_since_analyze |       last_autoanalyze        | autoanalyze_count |
+---------------------+-------------------------------+-------------------+
|                  65 | 2024-09-05 15:25:19.214434-07 |                 1 |
+---------------------+-------------------------------+-------------------+


postgres@postgres# INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 1) AS s(i);
INSERT 0 1
Time: 0.872 ms



postgres@postgres# SELECT n_mod_since_analyze,last_autoanalyze,autoanalyze_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';   
 +---------------------+------------------------------+-------------------+
| n_mod_since_analyze |       last_autoanalyze       | autoanalyze_count |
+---------------------+------------------------------+-------------------+
|                   0 | 2024-09-05 15:29:36.16516-07 |                 2 | <--- Aqui ya supero los 66 del calculo autovacuum_analyze_scale_factor y autovacuum_analyze_threshold
+---------------------+------------------------------+-------------------+
(1 row)




/******** VALIDAREMOS EL autovacuum_vacuum_insert_threshold  ********/
-----> Detonante en tablas nuevas: Cuando la tabla es nueva valida el parámetro autovacuum_vacuum_insert_threshold , en este caso su valor es de 200 y cuando supera ese valor, entonces ahi es cuando ejecuta el autovacuum_vacuum
-----> Detonante tablas existentes: Cuando la tabla ya tiene registros y ejecutan insert, se va llenando la columna n_ins_since_vacuum de la tabla pg_stat_user_tables , postgresql realiza el calculo siguiente  n_ins_since_vacuum > (  autovacuum_vacuum_insert_threshold  + ( n_live_tup * autovacuum_vacuum_insert_scale_factor  )) y en caso de que  supere ese valor entonces  realizará el autovacuum y reiniciara el contador colocandolo en 0 en la columna n_ins_since_vacuum


postgres@postgres# drop table ejemplo_autovacuum;
DROP TABLE
Time: 13.007 ms

postgres@postgres# CREATE TABLE ejemplo_autovacuum (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE
Time: 5.365 ms

postgres@postgres#  ALTER TABLE ejemplo_autovacuum SET (
    autovacuum_vacuum_threshold = 50,
    autovacuum_analyze_threshold = 60,
    autovacuum_vacuum_scale_factor = 0.2,
    autovacuum_analyze_scale_factor = 0.1,
    autovacuum_vacuum_insert_scale_factor = 0.05,
    autovacuum_vacuum_insert_threshold = 200
);
ALTER TABLE
Time: 2.606 ms


postgres@postgres# INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 200) AS s(i);
INSERT 0 200
Time: 2.088 ms


postgres@postgres#  SELECT n_live_tup,n_ins_since_vacuum,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+------------+--------------------+-----------------+------------------+
| n_live_tup | n_ins_since_vacuum | last_autovacuum | autovacuum_count |
+------------+--------------------+-----------------+------------------+
|        200 |                200 | NULL            |                0 |
+------------+--------------------+-----------------+------------------+
(1 row)



postgres@postgres# drop table ejemplo_autovacuum;
DROP TABLE
Time: 13.007 ms

postgres@postgres# CREATE TABLE ejemplo_autovacuum (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE
Time: 5.365 ms

postgres@postgres#  ALTER TABLE ejemplo_autovacuum SET (
    autovacuum_vacuum_threshold = 50,
    autovacuum_analyze_threshold = 60,
    autovacuum_vacuum_scale_factor = 0.2,
    autovacuum_analyze_scale_factor = 0.1,
    autovacuum_vacuum_insert_scale_factor = 0.05,
    autovacuum_vacuum_insert_threshold = 200
);
ALTER TABLE
Time: 2.606 ms



postgres@postgres# INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 201) AS s(i);
INSERT 0 200
Time: 2.088 ms


postgres@postgres#  SELECT n_live_tup,n_ins_since_vacuum,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+------------+--------------------+-------------------------------+------------------+
| n_live_tup | n_ins_since_vacuum |        last_autovacuum        | autovacuum_count |
+------------+--------------------+-------------------------------+------------------+
|        201 |                  0 | 2024-09-05 16:25:30.217864-07 |                1 | <--- Aqui ya detono el vacum insert ya que supero los 200 la primera vez
+------------+--------------------+-------------------------------+------------------+
(1 row)


 
postgres@postgres#   INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 211) AS s(i);
INSERT 0 211



postgres@postgres# SELECT n_live_tup,n_ins_since_vacuum,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+------------+--------------------+-------------------------------+------------------+
| n_live_tup | n_ins_since_vacuum |        last_autovacuum        | autovacuum_count |
+------------+--------------------+-------------------------------+------------------+
|        412 |                  0 | 2024-09-05 16:27:05.624818-07 |                2 |
+------------+--------------------+-------------------------------+------------------+
(1 row)


postgres@postgres#  INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 222) AS s(i);
INSERT 0 222
Time: 1.962 ms


postgres@postgres# SELECT n_live_tup,n_ins_since_vacuum,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+------------+--------------------+-------------------------------+------------------+
| n_live_tup | n_ins_since_vacuum |        last_autovacuum        | autovacuum_count |
+------------+--------------------+-------------------------------+------------------+
|        634 |                  0 | 2024-09-05 16:27:50.828172-07 |                3 |
+------------+--------------------+-------------------------------+------------------+
(1 row)



postgres@postgres# INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 232) AS s(i);
INSERT 0 232
Time: 3.050 ms

postgres@postgres# SELECT n_live_tup,n_ins_since_vacuum,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+------------+--------------------+-------------------------------+------------------+
| n_live_tup | n_ins_since_vacuum |        last_autovacuum        | autovacuum_count |
+------------+--------------------+-------------------------------+------------------+
|        866 |                  0 | 2024-09-05 16:28:25.931134-07 |                4 |
+------------+--------------------+-------------------------------+------------------+
(1 row)




postgres@postgres# INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 243) AS s(i);
INSERT 0 243

postgres@postgres# SELECT n_live_tup,n_ins_since_vacuum,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+------------+--------------------+-------------------------------+------------------+
| n_live_tup | n_ins_since_vacuum |        last_autovacuum        | autovacuum_count |
+------------+--------------------+-------------------------------+------------------+
|       1109 |                243 | 2024-09-05 16:28:25.931134-07 |                4 |
+------------+--------------------+-------------------------------+------------------+
(1 row)



postgres@postgres# INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 13) AS s(i);
INSERT 0 13
Time: 2.059 ms


postgres@postgres# SELECT n_live_tup,n_ins_since_vacuum,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+------------+--------------------+-------------------------------+------------------+
| n_live_tup | n_ins_since_vacuum |        last_autovacuum        | autovacuum_count |
+------------+--------------------+-------------------------------+------------------+
|       1122 |                  0 | 2024-09-05 16:31:01.540741-07 |                5 |
+------------+--------------------+-------------------------------+------------------+
(1 row)




92

/******** VALIDAREMOS EL autovacuum_vacuum_threshold (UPDATE/DELETE) ********/
-----> Detonante tablas existentes: Cuando usas consultas UPDATE o DELETE se va sumando la cantidad modificada en la columna n_dead_tup de la tabla pg_stat_user_tables , Postgresql realiza el calculo siguiente  n_dead_tup > (  autovacuum_vacuum_threshold  + ( n_live_tup * autovacuum_vacuum_scale_factor  )) y  si supera ese valor entonces  realizará el autovacuum y reiniciara el contador colocandolo en 0 la columna n_dead_tup  



postgres@postgres# drop table ejemplo_autovacuum;
DROP TABLE
Time: 13.007 ms

postgres@postgres# CREATE TABLE ejemplo_autovacuum (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE
Time: 5.365 ms

postgres@postgres#  ALTER TABLE ejemplo_autovacuum SET (
    autovacuum_vacuum_threshold = 50,
    autovacuum_analyze_threshold = 60,
    autovacuum_vacuum_scale_factor = 0.2,
    autovacuum_analyze_scale_factor = 0.1,
    autovacuum_vacuum_insert_scale_factor = 0.05,
    autovacuum_vacuum_insert_threshold = 200
);
ALTER TABLE
Time: 2.606 ms



postgres@postgres#  INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 759) AS s(i);
INSERT 0 759
Time: 4.048 ms


postgres@postgres#  SELECT n_tup_upd,n_tup_del, n_dead_tup,n_live_tup,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+-----------+-----------+------------+------------+-------------------------------+------------------+
| n_tup_upd | n_tup_del | n_dead_tup | n_live_tup |        last_autovacuum        | autovacuum_count |
+-----------+-----------+------------+------------+-------------------------------+------------------+
|         0 |         0 |          0 |        759 | 2024-09-05 17:10:13.028556-07 |                1 | <--- ya lleva 1 porque insertamos pero no ese no cuenta porque no se activo por el update o delete, se activo por el insert
+-----------+-----------+------------+------------+-------------------------------+------------------+

749*.2


postgres@postgres# update ejemplo_autovacuum set descripcion = 'desc_test' where id <= 200 ;
UPDATE 200
Time: 3.307 ms


postgres@postgres# SELECT n_tup_upd,n_tup_del, n_dead_tup,n_live_tup,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+-----------+-----------+------------+------------+-------------------------------+------------------+
| n_tup_upd | n_tup_del | n_dead_tup | n_live_tup |        last_autovacuum        | autovacuum_count |
+-----------+-----------+------------+------------+-------------------------------+------------------+
|       200 |         0 |        200 |        759 | 2024-09-05 17:10:13.028556-07 |                1 |
+-----------+-----------+------------+------------+-------------------------------+------------------+
(1 row)


postgres@postgres# update ejemplo_autovacuum set descripcion = 'desc_test' where id <= 2 ;                                                        
UPDATE 1
Time: 1.446 ms



postgres@postgres# SELECT n_tup_upd,n_tup_del, n_dead_tup,n_live_tup,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+-----------+-----------+------------+------------+-------------------------------+------------------+
| n_tup_upd | n_tup_del | n_dead_tup | n_live_tup |        last_autovacuum        | autovacuum_count |
+-----------+-----------+------------+------------+-------------------------------+------------------+
|       202 |         0 |          0 |        759 | 2024-09-05 17:15:23.850084-07 |                2 | <-- se activo la el autovacuum
+-----------+-----------+------------+------------+-------------------------------+------------------+
(1 row)



postgres@postgres# update ejemplo_autovacuum set descripcion = 'desc_test' where id <= 202 ;
UPDATE 202
Time: 2.247 ms

postgres@postgres# SELECT n_tup_upd,n_tup_del, n_dead_tup,n_live_tup,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+-----------+-----------+------------+------------+-------------------------------+------------------+
| n_tup_upd | n_tup_del | n_dead_tup | n_live_tup |        last_autovacuum        | autovacuum_count |
+-----------+-----------+------------+------------+-------------------------------+------------------+
|       404 |         0 |          0 |        759 | 2024-09-05 17:16:59.257597-07 |                3 | 
+-----------+-----------+------------+------------+-------------------------------+------------------+
(1 row)



postgres@postgres# update ejemplo_autovacuum set descripcion = 'desc_test' where id <= 201 ;
UPDATE 201
Time: 1.890 ms


postgres@postgres# delete from  ejemplo_autovacuum  where id  = 700;
DELETE 1
Time: 1.064 ms



postgres@postgres# SELECT n_tup_upd,n_tup_del, n_dead_tup,n_live_tup,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+-----------+-----------+------------+------------+-------------------------------+------------------+
| n_tup_upd | n_tup_del | n_dead_tup | n_live_tup |        last_autovacuum        | autovacuum_count |
+-----------+-----------+------------+------------+-------------------------------+------------------+
|       605 |         1 |          0 |        758 | 2024-09-05 17:18:25.494262-07 |                4 |
+-----------+-----------+------------+------------+-------------------------------+------------------+
(1 row)




postgres@postgres#  INSERT INTO ejemplo_autovacuum (nombre, descripcion) SELECT 'Nombre ' || i, 'Descripción ' || i FROM generate_series(1, 500) AS s(i);
INSERT 0 500
Time: 3.054 ms



postgres@postgres# update ejemplo_autovacuum set descripcion = 'desc_test' where id <= 202 ;
UPDATE 202
Time: 2.557 ms




postgres@postgres# SELECT n_tup_upd,n_tup_del, n_dead_tup,n_live_tup,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+-----------+-----------+------------+------------+-------------------------------+------------------+
| n_tup_upd | n_tup_del | n_dead_tup | n_live_tup |        last_autovacuum        | autovacuum_count |
+-----------+-----------+------------+------------+-------------------------------+------------------+
|       807 |         1 |        202 |       1258 | 2024-09-05 17:18:50.497318-07 |                5 |
+-----------+-----------+------------+------------+-------------------------------+------------------+
(1 row)



postgres@postgres# update ejemplo_autovacuum set descripcion = 'desc_test' where id <= 99 ;                                                       
UPDATE 99
Time: 2.133 ms

postgres@postgres# SELECT n_tup_upd,n_tup_del, n_dead_tup,n_live_tup,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+-----------+-----------+------------+------------+-------------------------------+------------------+
| n_tup_upd | n_tup_del | n_dead_tup | n_live_tup |        last_autovacuum        | autovacuum_count |
+-----------+-----------+------------+------------+-------------------------------+------------------+
|       906 |         1 |        301 |       1258 | 2024-09-05 17:18:50.497318-07 |                5 |
+-----------+-----------+------------+------------+-------------------------------+------------------+
(1 row)




postgres@postgres# update ejemplo_autovacuum set descripcion = 'desc_test' where id <= 1 ;                                                        
UPDATE 1
Time: 1.728 ms



postgres@postgres# SELECT n_tup_upd,n_tup_del, n_dead_tup,n_live_tup,last_autovacuum,autovacuum_count FROM pg_stat_user_tables WHERE relname = 'ejemplo_autovacuum';
+-----------+-----------+------------+------------+-------------------------------+------------------+
| n_tup_upd | n_tup_del | n_dead_tup | n_live_tup |        last_autovacuum        | autovacuum_count |
+-----------+-----------+------------+------------+-------------------------------+------------------+
|       907 |         1 |          0 |       1258 | 2024-09-05 17:20:40.904491-07 |                6 |
+-----------+-----------+------------+------------+-------------------------------+------------------+
(1 row)








----> RESTABLECER LOS VALORES autovacuum DE UNA TABLA 
ALTER TABLE ejemplo_autovacuum RESET (
    autovacuum_vacuum_threshold,
    autovacuum_analyze_threshold,
    autovacuum_vacuum_scale_factor,
    autovacuum_analyze_scale_factor,
    autovacuum_vacuum_insert_scale_factor,
    autovacuum_vacuum_insert_threshold
);


``` 




