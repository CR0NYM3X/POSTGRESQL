
# Particiones 

### ¿Qué es la partición de tablas?

Imagina que tienes una mesa muy grande llena de papeles. Si necesitas encontrar un papel específico, puede ser muy difícil y tardado buscar en toda la mesa. Ahora, si divides esa mesa en varias secciones más pequeñas y organizas los papeles por secciones, encontrar lo que buscas será mucho más fácil y rápido. Eso es básicamente lo que hace la partición de tablas en PostgreSQL.


### Objetivo

El objetivo principal es mejorar el rendimiento y la eficiencia. Al dividir una tabla grande en partes más pequeñas, las consultas pueden ejecutarse más rápido porque hay menos datos que revisar.
También facilita el mantenimiento, como hacer copias de seguridad o eliminar datos antiguos.

### Ventajas

1. **Mejor rendimiento**: Las consultas pueden ser más rápidas porque solo buscan en una partición específica.
2. **Mantenimiento más fácil**: Puedes archivar o eliminar datos antiguos sin afectar el resto de la tabla.
3. **Optimización del espacio**: Puedes almacenar datos menos usados en medios de almacenamiento más baratos y lentos, usando los tablespace.

### Desventajas

1. **Complejidad**: Configurar y gestionar particiones puede ser más complicado que manejar una tabla simple.
2. **Limitaciones**: No todas las consultas se benefician de la partición, y en algunos casos, puede no haber una mejora significativa en el rendimiento³.
3. **Rendimiento de Inserción**: Insertar datos puede ser más lento si PostgreSQL necesita determinar a qué partición pertenece cada fila. Esto puede ser mitigado con una buena planificación y configuración.
4. **Limitaciones en las Claves Primarias y Unicidad**: Como ya viste, las claves primarias y las restricciones de unicidad deben incluir todas las columnas de partición, lo que puede no ser ideal en todos los casos.
5. **Mantenimiento**: Las operaciones de mantenimiento, como VACUUM y ANALYZE, deben ejecutarse en cada partición individualmente, lo que puede aumentar el tiempo y los recursos necesarios para el mantenimiento de la base de datos.
6. **Creación de particiones manualmente** si decides hacer particiones por fecha, tendras que crear particiones de manera manual, al menos que generes una tarea programada que cree la particion o puedes usar la extension pg_partman  que te ayuda con la creacion  automatica de tus particiones
7.  



### ¿Qué se Particiona Comúnmente?

En bases de datos, las tablas que contienen grandes volúmenes de datos y que se consultan frecuentemente suelen ser las candidatas principales para particionamiento. Algunos ejemplos comunes incluyen:

1. **Tablas de Transacciones**: Como ventas, pedidos, registros de logs, etc.
2. **Tablas Históricas**: Datos históricos que se acumulan con el tiempo, como registros de auditoría.
3. **Tablas de Datos Temporales**: Datos que se dividen naturalmente por tiempo, como datos de sensores o registros de eventos.


 

### Tipos de Particionamiento

PostgreSQL soporta varios tipos de particionamiento:

1. **Particionamiento por Rango**: Divide los datos en rangos continuos. Por ejemplo, particionar por fechas.
   ```sql
   PARTITION BY RANGE (fecha);
   ```

2. **Particionamiento por Lista**: Divide los datos en base a valores específicos. Por ejemplo, particionar por región o categoría.
   ```sql
   PARTITION BY LIST (region);
   ```

3. **Particionamiento por Hash**: Divide los datos en base a un valor hash de una columna. Útil para distribuir datos de manera uniforme.
   ```sql
   PARTITION BY HASH (id);
   ```

4. **Particionamiento por Clave**: Similar al particionamiento por hash, pero basado en una clave específica.
   ```sql
   PARTITION BY KEY (id);
   ```

 

 
--- 
### Particionar vs. Crear Tablas Separadas

#### Crear Tablas Separadas

Si decides crear tablas separadas para cada año, tendrías algo así:

- `ventas_2023`
- `ventas_2024`
- `ventas_2025`

Cada vez que insertas un nuevo registro, decides manualmente en qué tabla debe ir. Esto puede funcionar, pero tiene algunas desventajas:

1. **Gestión Manual**: Tienes que gestionar manualmente en qué tabla insertar cada registro.
2. **Consultas Complejas**: Si necesitas hacer una consulta que abarque varios años, tienes que unir varias tablas, lo que puede ser complicado y lento.
3. **Mantenimiento**: El mantenimiento de múltiples tablas puede ser más complicado y propenso a errores.
4.- **Podrias crear una vista** esto es lento 

#### Particionar una Tabla

Cuando particionas una tabla en PostgreSQL, tienes una tabla principal y varias particiones que PostgreSQL gestiona automáticamente. Por ejemplo:

- Tabla principal: `ventas`
- Particiones: `ventas_2023`, `ventas_2024`, `ventas_2025`

PostgreSQL se encarga de insertar los registros en la partición correcta sin que tú tengas que preocuparte por ello. Las ventajas son:

1. **Gestión Automática**: PostgreSQL decide automáticamente en qué partición insertar cada registro basado en las reglas que configures.
2. **Consultas Simplificadas**: Puedes hacer consultas en la tabla principal `ventas` y PostgreSQL se encargará de buscar en las particiones correctas.
3. **Mantenimiento Simplificado**: El mantenimiento es más sencillo porque todo está centralizado en la tabla principal y sus particiones.

--- 
# Ejemplos de Tablas particionadas con Tablespaces

**Para esste ejemplo se utilizo esta versión**
```sql
postgres@postgres# select version();
+---------------------------------------------------------------------------------------------------------+
|                                                 version                                                 |
+---------------------------------------------------------------------------------------------------------+
| PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit |
+---------------------------------------------------------------------------------------------------------+
(1 row)
Time: 0.450 ms
```sql

> [!IMPORTANT]
> En el caso de que quieras particionar una tabla que ya existe, es necesario crear nueva tabla particionada, migrar todos los datos a la tabla particionada y renombrar las tablas una vez migrados los datos 


### Beneficios del Uso de Tablespaces

- **Distribución de Carga**: Puedes distribuir los datos en diferentes discos para mejorar el rendimiento.
- **Gestión de Almacenamiento**: Facilita la gestión del almacenamiento y el mantenimiento de la base de datos.

### Consideraciones

- **Planificación**: Asegúrate de planificar bien la distribución de los tablespaces para evitar problemas de rendimiento.
- **Mantenimiento**: Realiza mantenimiento regular en cada tablespace para asegurar un rendimiento óptimo.

 
### Paso 1:. **Crear las carpetas de los Tablespaces**:
Se pueden guardar en diferentes discos si asi se requiere 
   ```sh
	mkdir /tmp/particion_psql
	mkdir /tmp/particion_psql/ventas_2020
	mkdir /tmp/particion_psql/ventas_2021
	mkdir /tmp/particion_psql/ventas_2022
	mkdir /tmp/particion_psql/ventas_2023
	mkdir /tmp/particion_psql/ventas_2024
   ```

### Paso 2: **Crear Tablespaces**:
   ```sql
   CREATE TABLESPACE ts_2020 LOCATION '/tmp/particion_psql/ventas_2020';
   CREATE TABLESPACE ts_2021 LOCATION '/tmp/particion_psql/ventas_2021';
   CREATE TABLESPACE ts_2022 LOCATION '/tmp/particion_psql/ventas_2022';
   CREATE TABLESPACE ts_2023 LOCATION '/tmp/particion_psql/ventas_2023';
   CREATE TABLESPACE ts_2024 LOCATION '/tmp/particion_psql/ventas_2024';
   ```

### Paso 3: Crear la tabla principal 

```sql
-- Crear la tabla principal con la clave primaria que incluye la columna de partición

CREATE TABLE public.ventas (
    id SERIAL,
    fecha DATE NOT NULL,
    producto VARCHAR(100),
    cantidad INT,
    precio DECIMAL(10, 2),
    PRIMARY KEY (id, fecha)
) PARTITION BY RANGE (fecha);

-- [NOTA] -> Si no colocas como primary key la columna que quieres particionar te marcara el siguiente error 

/*ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "ventas" lacks column "fecha" which is part of the partition key.
Time: 4.522 ms*/


```

### Paso 4: **Crear esquema prttb**:
crear un esquema para guardar las tablas particionadas y no juntarlas con la public
```sql
create schema prttb  ;
```
### Paso 5: **Crear Particiones  y Asignar Tablespaces**:
Creamos las particiones de la tabla ventas en el esquema prttb, con su rango de fecha por año y le asignamos el Tablespaces 
```sql
CREATE TABLE prttb.ventas_2020 PARTITION OF ventas FOR VALUES FROM ('2020-01-01') TO ('2021-01-01') TABLESPACE  ts_2020;
CREATE TABLE prttb.ventas_2021 PARTITION OF ventas FOR VALUES FROM ('2021-01-01') TO ('2022-01-01') TABLESPACE  ts_2021;
CREATE TABLE prttb.ventas_2022 PARTITION OF ventas FOR VALUES FROM ('2022-01-01') TO ('2023-01-01') TABLESPACE  ts_2022;
CREATE TABLE prttb.ventas_2023 PARTITION OF ventas FOR VALUES FROM ('2023-01-01') TO ('2024-01-01') TABLESPACE  ts_2023;
CREATE TABLE prttb.ventas_2024 PARTITION OF ventas FOR VALUES FROM ('2024-01-01') TO ('2025-01-01') TABLESPACE  ts_2024;

-- [NOTA] -> Cuando llega un nuevo año, necesitas crear una nueva partición para ese año en tu tabla particionada, o usar partman. 
```

### Paso 6: Insertar registros en las particiones

```sql
-- Insertar registros en la partición de 2020
INSERT INTO ventas (fecha, producto, cantidad, precio) VALUES
('2020-03-15', 'Producto A', 10, 100.00),
('2020-07-22', 'Producto B', 5, 50.00);

-- Insertar registros en la partición de 2021
INSERT INTO ventas (fecha, producto, cantidad, precio) VALUES
('2021-01-10', 'Producto C', 20, 200.00),
('2021-11-05', 'Producto D', 7, 70.00);

-- Insertar registros en la partición de 2022
INSERT INTO ventas (fecha, producto, cantidad, precio) VALUES
('2022-04-18', 'Producto E', 15, 150.00),
('2022-09-30', 'Producto F', 8, 80.00);

-- Insertar registros en la partición de 2023
INSERT INTO ventas (fecha, producto, cantidad, precio) VALUES
('2023-02-25', 'Producto G', 12, 120.00),
('2023-08-14', 'Producto H', 6, 60.00);

-- Insertar registros en la partición de 2024
INSERT INTO ventas (fecha, producto, cantidad, precio) VALUES
('2024-05-20', 'Producto I', 18, 180.00),
('2024-12-01', 'Producto J', 9, 90.00);
```

### Paso 7: Consultar los datos

```sql
postgres@postgres# \dt
                List of relations
+--------+--------+-------------------+----------+
| Schema |  Name  |       Type        |  Owner   |
+--------+--------+-------------------+----------+
| public | ventas | partitioned table | postgres |
+--------+--------+-------------------+----------+
(1 row)


postgres@postgres# select table_schema,table_name,table_type  from information_schema.tables where table_schema in('public','prttb') order by table_schema;
+--------------+-------------+------------+
| table_schema | table_name  | table_type |
+--------------+-------------+------------+
| prttb        | ventas_2020 | BASE TABLE |
| prttb        | ventas_2021 | BASE TABLE |
| prttb        | ventas_2022 | BASE TABLE |
| prttb        | ventas_2023 | BASE TABLE |
| prttb        | ventas_2024 | BASE TABLE |
| public       | ventas      | BASE TABLE |
+--------------+-------------+------------+
(6 rows)

Time: 1.020 ms


postgres@postgres# select * from prttb.ventas_2020;
+----+------------+------------+----------+--------+
| id |   fecha    |  producto  | cantidad | precio |
+----+------------+------------+----------+--------+
|  1 | 2020-03-15 | Producto A |       10 | 100.00 |
|  2 | 2020-07-22 | Producto B |        5 |  50.00 |
+----+------------+------------+----------+--------+


postgres@postgres# select * from public.ventas;
+----+------------+------------+----------+--------+
| id |   fecha    |  producto  | cantidad | precio |
+----+------------+------------+----------+--------+
|  1 | 2020-03-15 | Producto A |       10 | 100.00 |
|  2 | 2020-07-22 | Producto B |        5 |  50.00 |
|  3 | 2021-01-10 | Producto C |       20 | 200.00 |
|  4 | 2021-11-05 | Producto D |        7 |  70.00 |
|  5 | 2022-04-18 | Producto E |       15 | 150.00 |
|  6 | 2022-09-30 | Producto F |        8 |  80.00 |
|  7 | 2023-02-25 | Producto G |       12 | 120.00 |
|  8 | 2023-08-14 | Producto H |        6 |  60.00 |
|  9 | 2024-05-20 | Producto I |       18 | 180.00 |
| 10 | 2024-12-01 | Producto J |        9 |  90.00 |
+----+------------+------------+----------+--------+


```


# Index en particiones 
 **Herencia Automática de Índices:** A partir de PostgreSQL 11, cuando creas un índice en la tabla principal, este automáticamente se propaga a todas las particiones existentes y futuras. Sin embargo, si estás usando una versión anterior o si ya tienes la tabla particionada, deberás crear los índices en cada partición manualmente.

 **Índices Globales:** A partir de PostgreSQL 15, se introducen los índices globales para tablas particionadas, lo que permite crear un índice único que abarca todas las particiones. Si estás utilizando una versión que soporta índices globales y te resulta útil para tu caso, podrías considerarlos.

**[NOTA]** Si creas un index y despues creas una particion nueva, este index se creara de manera automatica.

```sql
postgres@postgres# CREATE INDEX   schemas_idx ON public.ventas (   fecha,producto  );
CREATE INDEX
Time: 7.692 ms

postgres@postgres# select *from pg_indexes where not schemaname in('pg_catalog','information_schema') and indexname ilike '%ventas%'  ;
+------------+-------------+--------------------------------+------------+------------------------------------------------------------------------
| schemaname |  tablename  |           indexname            | tablespace |                                            indexdef
+------------+-------------+--------------------------------+------------+------------------------------------------------------------------------
| public     | ventas      | ventas_pkey                    | NULL       | CREATE UNIQUE INDEX ventas_pkey ON ONLY public.ventas USING btree (id,fecha)                    
| public     | ventas_2020 | ventas_2020_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2020_pkey ON public.ventas_2020 USING btree(id, fecha)               
| public     | ventas_2021 | ventas_2021_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2021_pkey ON public.ventas_2021 USING btree(id, fecha)               
| public     | ventas_2022 | ventas_2022_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2022_pkey ON public.ventas_2022 USING btree(id, fecha)               
| public     | ventas_2023 | ventas_2023_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2023_pkey ON public.ventas_2023 USING btree(id, fecha)               
| public     | ventas_2024 | ventas_2024_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2024_pkey ON public.ventas_2024 USING btree(id, fecha)               
| public     | ventas_2020 | ventas_2020_fecha_producto_idx | NULL       | CREATE INDEX ventas_2020_fecha_producto_idx ON public.ventas_2020 USING btree (fecha, producto) 
| public     | ventas_2021 | ventas_2021_fecha_producto_idx | NULL       | CREATE INDEX ventas_2021_fecha_producto_idx ON public.ventas_2021 USING btree (fecha, producto) 
| public     | ventas_2022 | ventas_2022_fecha_producto_idx | NULL       | CREATE INDEX ventas_2022_fecha_producto_idx ON public.ventas_2022 USING btree (fecha, producto) 
| public     | ventas_2023 | ventas_2023_fecha_producto_idx | NULL       | CREATE INDEX ventas_2023_fecha_producto_idx ON public.ventas_2023 USING btree (fecha, producto) 
| public     | ventas_2024 | ventas_2024_fecha_producto_idx | NULL       | CREATE INDEX ventas_2024_fecha_producto_idx ON public.ventas_2024 USING btree (fecha, producto) 
+------------+-------------+--------------------------------+------------+------------------------------------------------------------------------

postgres@postgres# CREATE TABLE prttb.ventas_2025 PARTITION OF ventas FOR VALUES FROM ('2025-01-01') TO ('2026-01-01') TABLESPACE  ts_2024;
CREATE TABLE
Time: 3.828 ms

postgres@postgres# select *from pg_indexes where not schemaname in('pg_catalog','information_schema') and indexname ilike '%ventas%';
+------------+-------------+--------------------------------+------------+------------------------------------------------------------------------
| schemaname |  tablename  |           indexname            | tablespace |                                            indexdef
+------------+-------------+--------------------------------+------------+------------------------------------------------------------------------
| public     | ventas      | ventas_pkey                    | NULL       | CREATE UNIQUE INDEX ventas_pkey ON ONLY public.ventas USING btree (id,fecha)                  |
| prttb      | ventas_2020 | ventas_2020_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2020_pkey ON prttb.ventas_2020 USING btree (id, fecha)              |
| prttb      | ventas_2021 | ventas_2021_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2021_pkey ON prttb.ventas_2021 USING btree (id, fecha)              |
| prttb      | ventas_2022 | ventas_2022_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2022_pkey ON prttb.ventas_2022 USING btree (id, fecha)              |
| prttb      | ventas_2023 | ventas_2023_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2023_pkey ON prttb.ventas_2023 USING btree (id, fecha)              |
| prttb      | ventas_2024 | ventas_2024_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2024_pkey ON prttb.ventas_2024 USING btree (id, fecha)              |
| prttb      | ventas_2020 | ventas_2020_fecha_producto_idx | NULL       | CREATE INDEX ventas_2020_fecha_producto_idx ON prttb.ventas_2020 USINGbtree (fecha, producto) |
| prttb      | ventas_2021 | ventas_2021_fecha_producto_idx | NULL       | CREATE INDEX ventas_2021_fecha_producto_idx ON prttb.ventas_2021 USINGbtree (fecha, producto) |
| prttb      | ventas_2022 | ventas_2022_fecha_producto_idx | NULL       | CREATE INDEX ventas_2022_fecha_producto_idx ON prttb.ventas_2022 USINGbtree (fecha, producto) |
| prttb      | ventas_2023 | ventas_2023_fecha_producto_idx | NULL       | CREATE INDEX ventas_2023_fecha_producto_idx ON prttb.ventas_2023 USINGbtree (fecha, producto) |
| prttb      | ventas_2024 | ventas_2024_fecha_producto_idx | NULL       | CREATE INDEX ventas_2024_fecha_producto_idx ON prttb.ventas_2024 USINGbtree (fecha, producto) |
| prttb      | ventas_2025 | ventas_2025_pkey               | NULL       | CREATE UNIQUE INDEX ventas_2025_pkey ON prttb.ventas_2025 USING btree (id, fecha)              |
| prttb      | ventas_2025 | ventas_2025_fecha_producto_idx | NULL       | CREATE INDEX ventas_2025_fecha_producto_idx ON prttb.ventas_2025 USING btree (fecha, producto) |
+------------+-------------+--------------------------------+------------+------------------------------------------------------------------------

```



 # como se guardan los archivos TABLESPACE 
   ```sql
	[postgres@server_redhat tmp]$ du particion_psql
	8       particion_psql/ventas_2020/PG_16_202307071/5
	8       particion_psql/ventas_2020/PG_16_202307071
	8       particion_psql/ventas_2020
	8       particion_psql/ventas_2021/PG_16_202307071/5
	8       particion_psql/ventas_2021/PG_16_202307071
	8       particion_psql/ventas_2021
	8       particion_psql/ventas_2022/PG_16_202307071/5
	8       particion_psql/ventas_2022/PG_16_202307071
	8       particion_psql/ventas_2022
	8       particion_psql/ventas_2023/PG_16_202307071/5
	8       particion_psql/ventas_2023/PG_16_202307071
	8       particion_psql/ventas_2023
	8       particion_psql/ventas_2024/PG_16_202307071/5
	8       particion_psql/ventas_2024/PG_16_202307071
	8       particion_psql/ventas_2024
	40      particion_psql
   ```

### Monitoreo del Uso de Espacio
   ```sql
  SELECT pg_tablespace_size('ts_2020');
   ```

### copias de seguridad regulares de tus tablespaces para proteger tus datos.

```sh
-- Backup de un tablespace específico
pg_basebackup -D /path/to/backup -T /path/to/tablespace=/path/to/backup/tablespace
```
### Test, crear una particion con un rango de fechas que ya existe 
```sql

postgres@postgres# CREATE TABLE prttb.ventas_raras PARTITION OF ventas FOR VALUES FROM ('2024-01-01') TO ('2025-01-01')  ;
ERROR:  partition "ventas_raras" would overlap partition "ventas_2024"
LINE 1: ...ventas_raras PARTITION OF ventas FOR VALUES FROM ('2024-01-0...
                                                             ^
Time: 2.796 ms

postgres@postgres# CREATE TABLE prttb.ventas_raras PARTITION OF ventas FOR VALUES FROM ('2024-01-01') TO ('2024-01-01')  ;
ERROR:  empty range bound specified for partition "ventas_raras"
LINE 1: ...ventas_raras PARTITION OF ventas FOR VALUES FROM ('2024-01-0...
                                                             ^
DETAIL:  Specified lower bound ('2024-01-01') is greater than or equal to upper bound ('2024-01-01').
Time: 1.050 ms
 
postgres@postgres# CREATE TABLE prttb.ventas_raras PARTITION OF ventas FOR VALUES FROM ('2025-01-01') TO ('2024-01-01')  ;
ERROR:  empty range bound specified for partition "ventas_raras"
LINE 1: ...ventas_raras PARTITION OF ventas FOR VALUES FROM ('2025-01-0...
                                                             ^
DETAIL:  Specified lower bound ('2025-01-01') is greater than or equal to upper bound ('2024-01-01').
Time: 1.058 ms
 
``` 

# Test, realizar un insert con una fecha no definida.

Si intentas insertar un registro con una fecha que no está cubierta por ninguna de las particiones existentes, PostgreSQL generará un error. Esto se debe a que no hay una partición definida para manejar esa fecha.

```sql
postgres@postgres# INSERT INTO public.ventas (fecha, producto, cantidad, precio) VALUES ('2025-01-10', 'Producto C', 20, 200.00);
ERROR:  no partition of relation "ventas" found for row
DETAIL:  Partition key of the failing row contains (fecha) = (2025-01-10).
Time: 0.440 ms


INSERT INTO prttb.ventas_2020 (fecha, producto, cantidad, precio) VALUES ('2025-05-20', 'Producto Z', 18, 180.00);
ERROR:  new row for relation "ventas_2020" violates partition constraint
DETAIL:  Failing row contains (12, 2024-05-20, Producto Z, 18, 180.00).
Time: 0.543 ms

-- [NOTA] Para evitar este error, debes crear una nueva partición que cubra el rango de fechas que incluye el año 2025.

```


# Test  insertar directamente en la particion  
Insertar directamente en una particion es una mala practica 

**Desventajas de Insertar Directamente en la Partición**

1. **Pérdida de Abstracción**: Una de las ventajas de las particiones es que puedes tratar la tabla principal como una abstracción que maneja automáticamente la distribución de los datos. Insertar directamente en una partición rompe esta abstracción y puede complicar el mantenimiento y la administración.

2. **Errores Humanos**: Es más fácil cometer errores al insertar datos directamente en una partición específica, como insertar en la partición incorrecta o no actualizar las particiones adecuadamente cuando cambian los rangos de datos.

3. **Compatibilidad y Portabilidad**: El código que inserta directamente en particiones específicas puede ser menos portable y más difícil de mantener, especialmente si cambias el esquema de particionamiento en el futuro.

4. **Consultas y Mantenimiento**: Las consultas y las operaciones de mantenimiento pueden volverse más complicadas si los datos no están distribuidos correctamente entre las particiones.

 
```SQL 
postgres@postgres# INSERT INTO prttb.ventas_2020 (fecha, producto, cantidad, precio) VALUES ('2020-05-20', 'Producto Z', 18, 180.00);
INSERT 0 1
Time: 0.929 ms

postgres@postgres#  select * from prttb.ventas_2020;
+----+------------+------------+----------+--------+
| id |   fecha    |  producto  | cantidad | precio |
+----+------------+------------+----------+--------+
|  1 | 2020-03-15 | Producto A |       10 | 100.00 |
|  2 | 2020-07-22 | Producto B |        5 |  50.00 |
| 11 | 2020-05-20 | Producto Z |       18 | 180.00 |
+----+------------+------------+----------+--------+
(3 rows)

Time: 0.328 ms
postgres@postgres# select * from public.ventas;
+----+------------+------------+----------+--------+
| id |   fecha    |  producto  | cantidad | precio |
+----+------------+------------+----------+--------+
|  1 | 2020-03-15 | Producto A |       10 | 100.00 |
|  2 | 2020-07-22 | Producto B |        5 |  50.00 |
| 11 | 2020-05-20 | Producto Z |       18 | 180.00 |
|  3 | 2021-01-10 | Producto C |       20 | 200.00 |
|  4 | 2021-11-05 | Producto D |        7 |  70.00 |
|  5 | 2022-04-18 | Producto E |       15 | 150.00 |
|  6 | 2022-09-30 | Producto F |        8 |  80.00 |
|  7 | 2023-02-25 | Producto G |       12 | 120.00 |
|  8 | 2023-08-14 | Producto H |        6 |  60.00 |
|  9 | 2024-05-20 | Producto I |       18 | 180.00 |
| 10 | 2024-12-01 | Producto J |        9 |  90.00 |
+----+------------+------------+----------+--------+
(11 rows)

Time: 0.370 ms


```



# Plan de ejecución 

```sql

postgres@postgres# EXPLAIN ANALYZE SELECT * FROM public.ventas ;
+----------------------------------------------------------------------------------------------------------------------+
|                                                      QUERY PLAN                                                      |
+----------------------------------------------------------------------------------------------------------------------+
| Append  (cost=0.00..5.15 rows=10 width=246) (actual time=0.009..0.021 rows=11 loops=1)                               |
|   ->  Seq Scan on ventas_2020 ventas_1  (cost=0.00..1.02 rows=2 width=246) (actual time=0.009..0.009 rows=3 loops=1) |
|   ->  Seq Scan on ventas_2021 ventas_2  (cost=0.00..1.02 rows=2 width=246) (actual time=0.002..0.002 rows=2 loops=1) |
|   ->  Seq Scan on ventas_2022 ventas_3  (cost=0.00..1.02 rows=2 width=246) (actual time=0.003..0.003 rows=2 loops=1) |
|   ->  Seq Scan on ventas_2023 ventas_4  (cost=0.00..1.02 rows=2 width=246) (actual time=0.001..0.002 rows=2 loops=1) |
|   ->  Seq Scan on ventas_2024 ventas_5  (cost=0.00..1.02 rows=2 width=246) (actual time=0.001..0.002 rows=2 loops=1) |
| Planning Time: 0.134 ms                                                                                              |
| Execution Time: 0.039 ms                                                                                             |
+----------------------------------------------------------------------------------------------------------------------+
(8 rows)

Time: 0.474 ms



postgres@postgres# EXPLAIN ANALYZE SELECT * FROM public.ventas WHERE fecha = '2023-02-25' AND producto = 'Producto G';
+--------------------------------------------------------------------------------------------------------------+
|                                                  QUERY PLAN                                                  |
+--------------------------------------------------------------------------------------------------------------+
| Seq Scan on ventas_2023 ventas  (cost=0.00..1.03 rows=1 width=246) (actual time=0.011..0.012 rows=1 loops=1) |
|   Filter: ((fecha = '2023-02-25'::date) AND ((producto)::text = 'Producto G'::text))                         |
|   Rows Removed by Filter: 1                                                                                  |
| Planning Time: 0.157 ms                                                                                      |
| Execution Time: 0.029 ms                                                                                     |
+--------------------------------------------------------------------------------------------------------------+
(5 rows)


```


# Eliminando particion

```SQL
postgres@postgres# select *from public.ventas order by fecha;
+----+------------+------------+----------+--------+
| id |   fecha    |  producto  | cantidad | precio |
+----+------------+------------+----------+--------+
|  1 | 2020-03-15 | Producto A |       10 | 100.00 |
| 13 | 2020-05-20 | Producto Z |       18 | 180.00 |
|  2 | 2020-07-22 | Producto B |        5 |  50.00 |
|  3 | 2021-01-10 | Producto C |       20 | 200.00 |
|  4 | 2021-11-05 | Producto D |        7 |  70.00 |
|  5 | 2022-04-18 | Producto E |       15 | 150.00 |
|  6 | 2022-09-30 | Producto F |        8 |  80.00 |
|  7 | 2023-02-25 | Producto G |       12 | 120.00 |
|  8 | 2023-08-14 | Producto H |        6 |  60.00 |
|  9 | 2024-05-20 | Producto I |       18 | 180.00 |
| 10 | 2024-12-01 | Producto J |        9 |  90.00 |
+----+------------+------------+----------+--------+
(11 rows)

Time: 0.621 ms
postgres@postgres#
postgres@postgres# drop table prttb.ventas_2023;
DROP TABLE
Time: 3.158 ms
postgres@postgres#
postgres@postgres# select *from public.ventas order by fecha;
+----+------------+------------+----------+--------+
| id |   fecha    |  producto  | cantidad | precio |
+----+------------+------------+----------+--------+
|  1 | 2020-03-15 | Producto A |       10 | 100.00 |
| 13 | 2020-05-20 | Producto Z |       18 | 180.00 |
|  2 | 2020-07-22 | Producto B |        5 |  50.00 |
|  3 | 2021-01-10 | Producto C |       20 | 200.00 |
|  4 | 2021-11-05 | Producto D |        7 |  70.00 |
|  5 | 2022-04-18 | Producto E |       15 | 150.00 |
|  6 | 2022-09-30 | Producto F |        8 |  80.00 |
|  9 | 2024-05-20 | Producto I |       18 | 180.00 |
| 10 | 2024-12-01 | Producto J |        9 |  90.00 |
+----+------------+------------+----------+--------+
(9 rows)

Time: 0.755 ms
postgres@postgres#
```


# Eliminando tabla principal
Cuando eliminas la tabla principal o tabla particionada como quieras llamarle , también se eliminan todas sus particiones 
```sql
postgres@postgres# \dt
                          List of relations
+--------+---------------------------+-------------------+----------+
| Schema |           Name            |       Type        |  Owner   |
+--------+---------------------------+-------------------+----------+
| public | ventas                    | partitioned table | postgres |
+--------+---------------------------+-------------------+----------+
(7 rows)

postgres@postgres#  select table_schema,table_name,table_type  from information_schema.tables where table_schema in('public','prttb') order by table_schema,table_name;3
+--------------+-------------+------------+
| table_schema | table_name  | table_type |
+--------------+-------------+------------+
| prttb        | ventas_2020 | BASE TABLE |
| prttb        | ventas_2021 | BASE TABLE |
| prttb        | ventas_2022 | BASE TABLE |
| prttb        | ventas_2023 | BASE TABLE |
| prttb        | ventas_2024 | BASE TABLE |
| prttb        | ventas_2025 | BASE TABLE |
| public       | ventas      | BASE TABLE |
+--------------+-------------+------------+
(7 rows)

Time: 1.377 ms


postgres@postgres# drop table public.ventas;
DROP TABLE
Time: 4.481 ms
 
postgres@postgres# \dt
                    List of relations
+--------+---------------------------+-------+----------+
| Schema |           Name            | Type  |  Owner   |
+--------+---------------------------+-------+----------+
+--------+---------------------------+-------+----------+
(0 row)

postgres@postgres#  select table_schema,table_name,table_type  from information_schema.tables where table_schema in('public','prttb') order by table_schema,table_name;3
+--------------+------------+------------+
| table_schema | table_name | table_type |
+--------------+------------+------------+
+--------------+------------+------------+
(0 rows)


```
