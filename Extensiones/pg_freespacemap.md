
## 📘 **Índice**

1.  Objetivo
2.  Requisitos
3.  ¿Qué es pg\_freespacemap?
4.  Ventajas y Desventajas
5.  Casos de Uso
6.  Escenario Simulado
7.  Estructura Semántica
8.  Visualización del Proceso
9.  Procedimiento Completo
    *   Instalación
    *   Creación de datos ficticios
    *   Uso de pg\_freespacemap
    *   Interpretación de resultados
    *   Mantenimiento
10. Consideraciones y Buenas Prácticas
11. Bibliografía

***

### ✅ **1. Objetivo**

Aprender a instalar y usar la extensión **pg\_freespacemap** para inspeccionar el espacio libre en páginas de tablas e índices en PostgreSQL, optimizando almacenamiento y detectando fragmentación.

***

### ✅ **2. Requisitos**

*   PostgreSQL ≥ 13 (idealmente 15 o superior)
*   Acceso como superusuario o rol con permisos para instalar extensiones
*   Sistema operativo Linux (simulación en Ubuntu)
*   Base de datos con tablas que tengan datos insertados y borrados

***

### ✅ **3. ¿Qué es pg\_freespacemap?**

Es una extensión que permite consultar el **Free Space Map (FSM)**, una estructura interna que PostgreSQL usa para saber cuánto espacio libre hay en cada página de una tabla o índice.\
Esto es útil para:

*   Detectar fragmentación
*   Planificar operaciones de **VACUUM** o **REINDEX**
*   Optimizar almacenamiento

***

### ✅ **4. Ventajas y Desventajas**

**Ventajas:**

*   Permite análisis granular del espacio libre
*   Ayuda a reducir bloat y mejorar rendimiento
*   Fácil de instalar y usar

**Desventajas:**

*   Solo lectura, no corrige problemas
*   Puede ser costoso en tablas muy grandes

***

### ✅ **5. Casos de Uso**

*   Auditoría de espacio libre antes de un **VACUUM FULL**
*   Diagnóstico de tablas con alto bloat
*   Planificación de mantenimiento en bases críticas

***

### ✅ **6. Escenario Simulado**

**Empresa ficticia:** *RetailX*\
Problema: La tabla `ventas` ha sufrido muchas eliminaciones y sospechamos fragmentación. Queremos saber cuánto espacio libre hay en sus páginas.

***

### ✅ **7. Estructura Semántica**

*   Extensión: `pg_freespacemap`
*   Función principal: `pg_freespacemap_relations` y `pg_freespacemap_pages`
*   Parámetros: `relid` (OID de la tabla), `blkno` (número de bloque)

***
 

## ✅ **9. Procedimiento Completo**

### 🔹 **Instalación**

```sql
CREATE EXTENSION pg_freespacemap;


postgres@test# \dx+ pg_freespacemap
  Objects in extension "pg_freespacemap"
+----------------------------------------+
|           Object description           |
+----------------------------------------+
| function pg_freespace(regclass)        |
| function pg_freespace(regclass,bigint) |
+----------------------------------------+


```
 

### 🔹 **Creación de datos ficticios**

```sql
-- DROP table ventas ;
CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    producto TEXT,
    cantidad INT,
    precio NUMERIC(10,2)
);

INSERT INTO ventas (producto, cantidad, precio)
SELECT 'Producto ' || i, (random()*100)::INT, (random()*500)::NUMERIC(10,2)
FROM generate_series(1, 10000) AS i;



```



### 🔹 **Consultar espacio libre**
 

```sql

-- *   `blkno`: número de bloque |   `avail`: bytes libres en esa página
SELECT count(*) ,avail FROM pg_freespace('ventas') ;
+-------+-------+
| blkno | avail |
+-------+-------+
|     0 |     0 |
|     1 |     0 |
|     2 |     0 |
|     3 |     0 |
|     4 |     0 |
|     5 |     0 |
|     6 |     0 |
|     7 |     0 |
|     8 |     0 |
|     9 |     0 |
+-------+-------+
(10 rows)

-- cantidad de 
 SELECT count(*)  FROM pg_freespace('ventas') ;
+-------+
| count |
+-------+
|    74 |
+-------+
(1 row)


-- relpages = Cantidad de paginas | catndidad de tuplas 
SELECT relname, relpages,reltuples, pg_relation_size(relname::regclass) as size_bytes FROM pg_class  WHERE relname = 'ventas';
+---------+----------+-----------+------------+
| relname | relpages | reltuples | size_bytes |
+---------+----------+-----------+------------+
| ventas  |        0 |        -1 |     606208 |
+---------+----------+-----------+------------+
(1 row)


--- Hacer el primer mantenimiento para actualizar las estadisticas 
postgres@test# ANALYZE ventas ;
ANALYZE
Time: 76.255 ms
 

    SELECT relname, relpages,reltuples, pg_relation_size(relname::regclass) as size_bytes FROM pg_class  WHERE relname = 'ventas';
+---------+----------+-----------+------------+
| relname | relpages | reltuples | size_bytes |
+---------+----------+-----------+------------+
| ventas  |       74 |     10000 |     606208 |
+---------+----------+-----------+------------+
(1 row)


```

 

***



### 🔹 **Eliminar registros para generar espacio libre**

```sql
    DELETE FROM ventas WHERE id <= 1000;
DELETE 1000
Time: 2.970 ms

    SELECT relname, relpages,reltuples, pg_relation_size(relname::regclass) as size_bytes FROM pg_class  WHERE relname = 'ventas';
+---------+----------+-----------+------------+
| relname | relpages | reltuples | size_bytes |
+---------+----------+-----------+------------+
| ventas  |       74 |     10000 |     606208 |
+---------+----------+-----------+------------+
(1 row)


```

### 🔹 **Volvemos a consultar espacio libre**
 
```sql
  SELECT * FROM pg_freespace('ventas') where avail != 0 LIMIT 10;
+-------+-------+
| blkno | avail |
+-------+-------+
+-------+-------+
(0 rows)

```


### 🔹 **Hacer el primer mantenimiento**
```sql
        VACUUM ventas;
VACUUM
Time: 32.997 ms

       SELECT relname, relpages,reltuples, pg_relation_size(relname::regclass) as size_bytes FROM pg_class  WHERE relname = 'ventas';
+---------+----------+-----------+------------+
| relname | relpages | reltuples | size_bytes |
+---------+----------+-----------+------------+
| ventas  |       74 |      9000 |     606208 |
+---------+----------+-----------+------------+
(1 row)




SELECT 
    relname AS tabla,
    last_vacuum,        -- Último VACUUM manual
    last_autovacuum,    -- Último VACUUM automático
    last_analyze,       -- Último ANALYZE manual
    last_autoanalyze,   -- Último ANALYZE automático
    n_live_tup          -- Estimación de filas vivas
FROM pg_stat_user_tables
WHERE relname = 'ventas';

+--------+-------------------------------+-----------------+-------------------------------+------------------+------------+
| tabla  |          last_vacuum          | last_autovacuum |         last_analyze          | last_autoanalyze | n_live_tup |
+--------+-------------------------------+-----------------+-------------------------------+------------------+------------+
| ventas | 2026-01-05 14:40:16.973065-07 | NULL            | 2026-01-05 14:39:15.615488-07 | NULL             |       9000 |
+--------+-------------------------------+-----------------+-------------------------------+------------------+------------+
(1 row)



```



### 🔹 **Volvemos a consultar espacio libre**
 
```sql
     SELECT * FROM pg_freespace('ventas') where avail != 0 LIMIT 10;
+-------+-------+
| blkno | avail |
+-------+-------+
|     0 |  8160 |
|     1 |  8160 |
|     2 |  8160 |
|     3 |  8160 |
|     4 |  8160 |
|     5 |  8160 |
|     6 |  8160 |
|     7 |  2688 |
|    73 |  3840 |
+-------+-------+
(9 rows)
```

## Consultamos las tuplas 
```


 SELECT relname, relpages,reltuples, pg_relation_size(relname::regclass) as size_bytes FROM pg_class  WHERE relname = 'ventas';
+---------+----------+-----------+------------+
| relname | relpages | reltuples | size_bytes |
+---------+----------+-----------+------------+
| ventas  |       74 |      9000 |     606208 |
+---------+----------+-----------+------------+
(1 row)

-- OTRA FORMA DE REVISAR -- SELECT pg_relation_size('ventas') as size_bytes, pg_relation_size('ventas')  / current_setting('block_size')::int AS total_pages;


```

### 🔹 **Hacer el segundo mantenimiento**
```
    VACUUM FULL ventas;
VACUUM
Time: 36.166 ms


     SELECT relname, relpages,reltuples, pg_relation_size(relname::regclass) as size_bytes FROM pg_class  WHERE relname = 'ventas';
+---------+----------+-----------+------------+
| relname | relpages | reltuples | size_bytes |
+---------+----------+-----------+------------+
| ventas  |       67 |      9000 |     548864 |
+---------+----------+-----------+------------+
(1 row)

Time: 0.643 ms


     SELECT * FROM pg_freespace('ventas') where avail != 0 LIMIT 10;
+-------+-------+
| blkno | avail |
+-------+-------+
+-------+-------+
(0 rows)


-- Hacemos el tercer mantenimiento 
  VACUUM  ventas;
VACUUM
Time: 144.408 ms

-- volvemos a consultar 
      SELECT * FROM pg_freespace('ventas') where avail != 0 LIMIT 10;
+-------+-------+
| blkno | avail |
+-------+-------+
|    66 |  6720 |
+-------+-------+
(1 row)

Time: 0.683 ms


```

***

## ✅ **10. Consideraciones y Buenas Prácticas**

*   No usar en producción sin planificar, puede ser costoso
*   Ideal para auditorías periódicas
*   Combinar con `pgstattuple` para análisis más completo

***

## ✅ **11. Bibliografía**

*   <https://www.postgresql.org/docs/current/pgfreespacemap.html>
*   Experiencia en entornos críticos (consultoría DBA)

