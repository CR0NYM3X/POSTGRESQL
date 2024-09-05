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


``` 




