
# INDEX
La indexación es un proceso en el que se crea una estructura adicional que almacena los valores de una columna específica de una tabla en un formato optimizado para la búsqueda rápida. Esto permite que las consultas que involucran esa columna sean mucho más eficientes, ya que no se requiere recorrer toda la tabla para encontrar los datos.

# Tipos de índices en PostgreSQL:
    1. Índices B-Tree: Son los más comunes y se utilizan para columnas que tienen valores repetidos, como las columnas de nombres, fechas y números. Proporcionan una búsqueda rápida en logaritmo de tiempo.
    2. Índices Hash: Adecuados para igualdad de búsqueda exacta. Sin embargo, no funcionan bien con rangos y consultas de rango.
    3. Índices GIN y GiST: Son utilizados para tipos de datos más complejos como texto y geometría, permitiendo búsquedas y comparaciones más avanzadas.
    4. Índices SP-GiST: Útiles para tipos de datos con estructuras jerárquicas o multidimensionales.
    5. Índices GIN y GiST a tiempo completo: Están diseñados para búsquedas de texto y búsqueda de texto completo.


# Lógica de la indexación:
Cuando se crea un índice en PostgreSQL, el motor de la base de datos crea una estructura de datos adicional que contiene valores de la columna indexada y los punteros a las ubicaciones de los registros correspondientes en la tabla principal. Esto permite que las búsquedas sean mucho más eficientes, ya que PostgreSQL no necesita escanear toda la tabla, sino que puede saltar directamente a las ubicaciones relevantes a través del índice.
Es importante tener en cuenta que mientras que los índices aceleran las consultas de búsqueda, también tienen un costo en términos de rendimiento de escritura, ya que cada vez que se inserta, actualiza o elimina un registro, el índice debe actualizarse para reflejar esos cambios.



# ¿Qué es la reindexación en PostgreSQL?
La reindexación en PostgreSQL es un proceso en el que se reconstruyen los índices existentes en una tabla para mejorar su rendimiento y eficiencia. A medida que una base de datos se utiliza y cambia, los índices pueden volverse fragmentados y desorganizados, lo que afecta negativamente el rendimiento de las consultas. La reindexación ayuda a resolver este problema al reconstruir los índices, eliminando la fragmentación y mejorando la eficiencia de las búsquedas.

# Por qué es importante la reindexación?
La reindexación es importante porque los índices desorganizados pueden llevar a consultas lentas y degradación general del rendimiento de la base de datos. Con el tiempo, a medida que los datos se insertan, actualizan y eliminan, los índices pueden perder eficiencia. La reindexación periódica garantiza que los índices estén optimizados para la consulta y mantiene el rendimiento de la base de datos en un nivel óptimo.



# CREAR INDEX 
```SQL
CREATE INDEX [ IF NOT EXISTS ] nombre_del_indice ON nombre_de_tabla (columna1, columna2, ...);
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





-- indices : 
https://dbasinapuros.com/tipos-de-indices-en-postgresql/

https://dbalifeeasy.com/2020/10/04/how-to-identify-fragmentation-in-postgresql-rds/ 
