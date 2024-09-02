 
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


