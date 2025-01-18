
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

3. **Particionamiento por hash sharding**: Divide los datos en base a un valor hash de una columna. Útil para distribuir datos de manera uniforme.
   ```sql
   PARTITION BY HASH (id);
   ```

4. **Particionamiento por Clave**: Similar al particionamiento por hash, pero basado en una clave específica.
   ```sql
   PARTITION BY KEY (id);
   ```

  
### Comparación: Particiones vs. Tabla de Historial

| **Criterio**               | **Particiones**                                                                 | **Tabla de Historial**                                                                 |
|----------------------------|---------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| **Rendimiento de Consultas** | Alta eficiencia en consultas que se benefician de la partición de datos. Las consultas que filtran por la columna de partición (por ejemplo, fecha) son mucho más rápidas. | Mejora el rendimiento al mantener la tabla principal más pequeña, pero las consultas históricas pueden ser más lentas. |
| **Mantenimiento**          | Simplifica el mantenimiento al permitir operaciones en particiones específicas (por ejemplo, eliminación de datos antiguos). | Requiere tareas programadas para mover datos a la tabla de historial y truncar la tabla principal. |
| **Complejidad de Implementación** | Requiere una planificación cuidadosa y una configuración inicial más compleja. | Más sencillo de implementar, especialmente si ya tienes experiencia con tareas programadas. |
| **Flexibilidad**           | Muy flexible para manejar grandes volúmenes de datos y permite operaciones eficientes en subconjuntos de datos. | Menos flexible en términos de rendimiento para consultas históricas, pero más fácil de gestionar en términos de implementación. |
| **Espacio en Disco**       | Puede requerir más espacio en disco debido a la necesidad de mantener múltiples particiones activas. | Puede ser más eficiente en términos de espacio si los datos históricos se archivan adecuadamente. |
| **Escalabilidad**          | Altamente escalable, ideal para sistemas con crecimiento continuo de datos. | Escalable, pero puede requerir ajustes frecuentes en las tareas programadas para manejar el crecimiento de datos. |
| **Disponibilidad de Datos** | Los datos están siempre disponibles en la tabla principal, lo que facilita el acceso a datos recientes y antiguos. | Los datos históricos están separados, lo que puede requerir consultas adicionales para acceder a ellos. |
| **Ejemplo de Uso**         | Ideal para aplicaciones que requieren acceso rápido a datos recientes y un manejo eficiente de grandes volúmenes de datos. | Adecuado para aplicaciones donde los datos históricos se consultan con menos frecuencia y se necesita mantener la tabla principal ligera. |

### Recomendación
- **Particiones**: Si tu prioridad es el rendimiento y la escalabilidad a largo plazo, las particiones son la mejor opción. Son ideales para sistemas con un crecimiento continuo de datos y donde las consultas a datos recientes son frecuentes.
- **Tabla de Historial**: Si buscas una solución más sencilla y tu carga de trabajo no es extremadamente alta, una tabla de historial con tareas programadas puede ser suficiente. Esta opción es más fácil de implementar y mantener, especialmente si los datos históricos no se consultan con frecuencia.

--- 
### Particionar vs. Crear Tablas Separadas


| **Criterio**               | **Particiones**                                                                 | **Crear Tablas Separadas**                                                                 |
|----------------------------|---------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| **Rendimiento de Consultas** | Alta eficiencia en consultas que se benefician de la eliminación de particiones no necesarias. Las consultas que filtran por la columna de partición son mucho más rápidas². | Puede ser menos eficiente, ya que las consultas pueden necesitar acceder a múltiples tablas, lo que aumenta la complejidad y el tiempo de ejecución. |
| **Mantenimiento**          | Simplifica el mantenimiento al permitir operaciones en particiones específicas (por ejemplo, eliminación de datos antiguos). | Requiere más esfuerzo de mantenimiento, ya que cada tabla debe ser gestionada individualmente. |
| **Complejidad de Implementación** | Requiere una planificación cuidadosa y una configuración inicial más compleja¹. | Más sencillo de implementar inicialmente, pero puede volverse complejo a medida que aumenta el número de tablas. |
| **Flexibilidad**           | Muy flexible para manejar grandes volúmenes de datos y permite operaciones eficientes en subconjuntos de datos². | Menos flexible, ya que cada tabla es independiente y no se benefician de las optimizaciones de particionamiento. |
| **Espacio en Disco**       | Puede requerir más espacio en disco debido a la necesidad de mantener múltiples particiones activas². | Puede ser más eficiente en términos de espacio si las tablas separadas se gestionan adecuadamente. |
| **Escalabilidad**          | Altamente escalable, ideal para sistemas con crecimiento continuo de datos². | Escalable, pero puede requerir ajustes frecuentes y una gestión más compleja a medida que crece el número de tablas. |
| **Disponibilidad de Datos** | Los datos están siempre disponibles en la tabla principal, lo que facilita el acceso a datos recientes y antiguos². | Los datos están distribuidos en múltiples tablas, lo que puede complicar el acceso y la gestión de datos históricos. |
| **Ejemplo de Uso**         | Ideal para aplicaciones que requieren acceso rápido a datos recientes y un manejo eficiente de grandes volúmenes de datos². | Adecuado para aplicaciones donde los datos pueden ser fácilmente segmentados y no se requiere acceso frecuente a datos históricos. |


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

**Para este ejemplo se utilizó una versión 16**
```sql
postgres@postgres# select version();
+---------------------------------------------------------------------------------------------------------+
|                                                 version                                                 |
+---------------------------------------------------------------------------------------------------------+
| PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit |
+---------------------------------------------------------------------------------------------------------+
(1 row)
Time: 0.450 ms
``` 

> [!IMPORTANT]
> En el caso de que quieras particionar una tabla que ya existe, es necesario crear nueva tabla particionada, migrar todos los datos a la tabla particionada y renombrar las tablas una vez migrados los datos 


### Beneficios del Uso de Tablespaces

- **Distribución de Carga**: Puedes distribuir los datos en diferentes discos para mejorar el rendimiento.
- **Gestión de Almacenamiento**: Facilita la gestión del almacenamiento y el mantenimiento de la base de datos.

### Consideraciones

- **Planificación**: Asegúrate de planificar bien la distribución de los tablespaces para evitar problemas de rendimiento.
- **Mantenimiento**: Realiza mantenimiento regular en cada tablespace para asegurar un rendimiento óptimo.

 
### Paso 1:. **Crear las carpetas de los Tablespaces en linux**:
Se pueden guardar en diferentes discos si asi se requiere 
   ```sh
	mkdir /tmp/particion_psql
	mkdir /tmp/particion_psql/ventas_2020
	mkdir /tmp/particion_psql/ventas_2021
	mkdir /tmp/particion_psql/ventas_2022
	mkdir /tmp/particion_psql/ventas_2023
	mkdir /tmp/particion_psql/ventas_2024
   ```

### Paso 2: **Crear Tablespaces en la base de datos**:
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

-- Sirve para conectarnos o usar el esquema
-- set search_path to   "prttb";
```
### Paso 5: **Crear Particiones  y Asignar Tablespaces**:
Creamos las particiones de la tabla ventas en el esquema prttb, con su rango de fecha por año y le asignamos el Tablespaces 
```sql
--- Particion Anual
CREATE TABLE prttb.ventas_2020 PARTITION OF public.ventas FOR VALUES FROM ('2020-01-01') TO ('2021-01-01') TABLESPACE  ts_2020;
CREATE TABLE prttb.ventas_2021 PARTITION OF public.ventas FOR VALUES FROM ('2021-01-01') TO ('2022-01-01') TABLESPACE  ts_2021;
CREATE TABLE prttb.ventas_2022 PARTITION OF public.ventas FOR VALUES FROM ('2022-01-01') TO ('2023-01-01') TABLESPACE  ts_2022;
CREATE TABLE prttb.ventas_2023 PARTITION OF public.ventas FOR VALUES FROM ('2023-01-01') TO ('2024-01-01') TABLESPACE  ts_2023;
CREATE TABLE prttb.ventas_2024 PARTITION OF public.ventas FOR VALUES FROM ('2024-01-01') TO ('2025-01-01') TABLESPACE  ts_2024;

-- [NOTA] -> Cuando llega un nuevo año, necesitas crear una nueva partición para ese año en tu tabla particionada,
-- Tabién puedes crear JOBS para que cree las particiones automaticamente o usar la extension pg_partman.

/* -- En caso de no querer Anual puedes ayudarte con estos ejemplos de Mensual y Diario
----  Particion Mensual 
CREATE TABLE prttb.ventas_2024_01 PARTITION OF public.ventas FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

--- Particion Diario
CREATE TABLE prttb.ventas_2024_01_01 PARTITION OF public.ventas FOR VALUES FROM ('2024-01-01') TO ('2024-01-02');
*/

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

**[NOTA]** Si creas un index y despues creas una particion nueva, este index se creara de manera automatica en la nueva partición.

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



# Extras 
```SQL

--- /*****  Ver todas las particiones y sus esquemas  *****\
SELECT 
		npar.nspname AS schema_name_partitioned,
		cpar.relname AS table_partitioned,
		nrel.nspname AS schema_name_partition,
		crel.relname AS tables_partition
FROM pg_inherits i
INNER JOIN pg_class crel ON i.inhrelid = crel.oid and not crel.oid in(select conindid from pg_constraint)
INNER JOIN pg_class cpar ON i.inhparent = cpar.oid and not cpar.oid in(select conindid from pg_constraint)
INNER JOIN pg_namespace nrel ON crel.relnamespace = nrel.oid
INNER JOIN pg_namespace npar ON cpar.relnamespace = npar.oid
ORDER BY inhparent ,inhrelid 
;

+-------------------------+-------------------+-----------------------+------------------+
| schema_name_partitioned | table_partitioned | schema_name_partition | tables_partition |
+-------------------------+-------------------+-----------------------+------------------+
| public                  | ventas            | prttb                 | ventas_2020      |
| public                  | ventas            | prttb                 | ventas_2021      |
| public                  | ventas            | prttb                 | ventas_2022      |
| public                  | ventas            | prttb                 | ventas_2023      |
| public                  | ventas            | prttb                 | ventas_2024      |
+-------------------------+-------------------+-----------------------+------------------+
(4 rows)


--- /***** se utiliza para separar una partición de su tabla particionada principal.  *****\
postgres@postgres# ALTER TABLE public.ventas DETACH PARTITION prttb.ventas_2022;
ALTER TABLE

```





---
---

El **hash sharding** en PostgreSQL es una técnica de particionamiento que distribuye los datos entre múltiples nodos o particiones utilizando una función hash.  

### ¿Qué es el hash sharding?
El hash sharding implica dividir una tabla en varias subtablas (shards) basándose en el valor hash de una o más columnas clave. Cada fila se asigna a una partición específica según el resultado de la función hash aplicada a su clave de partición.

### ¿Cómo funciona?
1. **Definición de la clave de partición**: Se elige una columna o combinación de columnas como clave de partición.
2. **Aplicación de la función hash**: Se aplica una función hash a la clave de partición para determinar en qué shard se almacenará cada fila.
3. **Distribución de datos**: Los datos se distribuyen uniformemente entre los shards, lo que ayuda a balancear la carga y mejorar el rendimiento.


### Cuándo usar hash sharding
- **Grandes volúmenes de datos**: Cuando necesitas manejar grandes cantidades de datos y tráfico.
- **Balanceo de carga**: Cuando es crucial distribuir la carga de trabajo de manera uniforme entre varios nodos.
- **Escalabilidad**: Cuando necesitas una solución que pueda escalar fácilmente añadiendo más nodos.

### Cuándo no usar hash sharding
- **Consultas complejas**: Si tus consultas requieren unir datos de múltiples shards frecuentemente, el rendimiento puede verse afectado.
- **Datos pequeños**: Si el volumen de datos es pequeño, el overhead de gestionar múltiples shards puede no justificar los beneficios.


### Ventajas del hash sharding
- **Balanceo de carga**: Distribuye los datos de manera uniforme, evitando que un solo nodo se sobrecargue.
- **Escalabilidad**: Permite añadir más nodos fácilmente para manejar mayores volúmenes de datos y tráfico.
- **Rendimiento**: Mejora el rendimiento de las consultas al reducir la cantidad de datos que cada nodo necesita procesar.

 

### Desventajas de usar hash sharding

1. **Complejidad en la configuración y administración**:
   - **Configuración inicial**: Implementar hash sharding puede ser complejo y requiere una planificación cuidadosa para definir las claves de partición y la distribución de los datos.
   - **Mantenimiento**: Administrar una base de datos shardada puede ser más complicado que una base de datos monolítica, especialmente cuando se trata de balancear la carga y manejar fallos.

2. **Consultas complejas**:
   - **Uniones entre shards**: Las consultas que requieren unir datos de múltiples shards pueden ser lentas y consumir muchos recursos, ya que el sistema necesita acceder a varias particiones para obtener los datos necesarios.
   - **Consultas globales**: Realizar consultas que abarcan todos los shards, como agregaciones globales, puede ser ineficiente y lento.

3. **Rebalanceo de datos**:
   - **Escalabilidad dinámica**: Añadir o remover shards puede requerir un rebalanceo de datos, lo cual puede ser un proceso costoso y disruptivo.
   - **Redistribución**: Cambiar la distribución de los datos entre shards puede ser complicado y puede afectar el rendimiento durante el proceso.

4. **Consistencia y transacciones**:
   - **Transacciones distribuidas**: Mantener la consistencia de las transacciones a través de múltiples shards puede ser difícil y puede requerir mecanismos adicionales como coordinadores de transacciones distribuidas.
   - **Latencia**: Las transacciones que abarcan múltiples shards pueden introducir latencia adicional debido a la necesidad de coordinar entre diferentes nodos.

5. **Sobrecarga de almacenamiento**:
   - **Metadatos adicionales**: Cada shard puede requerir almacenamiento adicional para metadatos y estructuras de índice, lo que puede aumentar el uso total de almacenamiento.

6. **Dependencia de la función hash**:
   - **Colisiones de hash**: Aunque las funciones hash están diseñadas para distribuir los datos uniformemente, pueden ocurrir colisiones que resulten en una distribución desigual de los datos.
   - **Rigidez**: Cambiar la función hash o la clave de partición puede ser complicado y puede requerir una reestructuración significativa de la base de datos.



### Desafíos de unir datos de múltiples shards

1. **Rendimiento**: Las uniones entre tablas particionadas pueden ser más lentas porque el sistema necesita acceder a múltiples shards para obtener los datos necesarios.
2. **Complejidad**: La lógica de la consulta puede volverse más compleja, especialmente si las particiones están distribuidas en diferentes nodos físicos.
3. **Consistencia**: Asegurar la consistencia de los datos puede ser más difícil en un entorno distribuido.

### Cuándo es problemático

- **Consultas frecuentes**: Si tus aplicaciones realizan muchas consultas que requieren unir datos de múltiples shards, el rendimiento puede verse afectado.
- **Grandes volúmenes de datos**: Cuanto más grandes sean los datos y más shards estén involucrados, más tiempo y recursos se necesitarán para completar la consulta.



### Propósito del MODULUS

1. **Distribución de datos**: El MODULUS define el número total de particiones en las que se dividirán los datos. Por ejemplo, si el MODULUS es 4, los datos se distribuirán en 4 particiones.
2. **Cálculo del resto**: Cuando se inserta un dato, PostgreSQL calcula el valor hash de la clave de partición y luego aplica la operación de módulo (resto) para determinar en qué partición almacenar el dato. El resto de esta operación debe coincidir con el REMAINDER especificado en la partición.
 
### ¿Se puede cambiar el MODULUS?

El MODULUS se define al crear las particiones y no se puede cambiar directamente una vez que las particiones están creadas. Si necesitas cambiar el número de particiones (MODULUS), tendrías que rediseñar la partición de la tabla


### Ejemplo de ajuste

Si decides que necesitas más particiones, podrías hacer algo como esto:

```sql
-- Crear nuevas particiones con un MODULUS de 8
CREATE TABLE users_part_5 PARTITION OF users FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE users_part_6 PARTITION OF users FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE users_part_7 PARTITION OF users FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE users_part_8 PARTITION OF users FOR VALUES WITH (MODULUS 8, REMAINDER 7);
```
 
# Como postgresql decide en que particion insertar la fila 
1. **Generación del `user_id`**:
   - PostgreSQL genera un `user_id` para el nuevo registro, por ejemplo, `user_id = 1`.

2. **Aplicación de la función hash**:
   - PostgreSQL aplica una función hash al valor `1`. Supongamos que el valor hash resultante es `12345`.

3. **Cálculo del módulo**:
   - PostgreSQL calcula `12345 % 4`, lo que da un resto de `1`.

4. **Determinación de la partición**:
   - El resto `1` indica que el registro se almacenará en la partición `users_part_2` (que tiene `REMAINDER 1`).

 
 

### Paso 1: Crear la tabla principal y las particiones
En este ejemplo, la tabla `users` se particiona en cuatro shards basados en el valor hash de la columna `id`.

Primero, creamos una tabla principal que se particionará por hash y luego definimos las particiones.

```sql
-- Crear la tabla principal con particionamiento por hash
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL
) PARTITION BY HASH (user_id);

-- Crear las particiones
CREATE TABLE users_part_1 PARTITION OF users FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE users_part_2 PARTITION OF users FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE users_part_3 PARTITION OF users FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE users_part_4 PARTITION OF users FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```




### Paso 2: Insertar datos en la tabla

Ahora, insertamos algunos datos en la tabla `users`. PostgreSQL automáticamente distribuirá los datos entre las particiones basándose en el valor hash de `user_id`.

```sql
-- Insertar datos
INSERT INTO users (username, email) VALUES
('alice', 'alice@example.com'),
('bob', 'bob@example.com'),
('carol', 'carol@example.com'),
('dave', 'dave@example.com'),
('eve', 'eve@example.com'),
('frank', 'frank@example.com');
```


### Paso 3: Consultar datos

Podemos realizar consultas en la tabla `users` como si fuera una tabla única. PostgreSQL se encargará de acceder a las particiones correspondientes.

```sql
-- Consultar todos los usuarios
SELECT * FROM users;

-- Consultar un usuario específico
SELECT * FROM users WHERE user_id = 3;

-- Contar el número de usuarios
SELECT COUNT(*) FROM users;
```

### Paso 4: Verificar la distribución de datos

Podemos verificar cómo se han distribuido los datos entre las particiones.

```sql
-- Contar el número de registros en cada partición
SELECT COUNT(*) FROM users_part_1;
SELECT COUNT(*) FROM users_part_2;
SELECT COUNT(*) FROM users_part_3;
SELECT COUNT(*) FROM users_part_4;




SELECT 
    user_id, 
    username, 
    email, 
     abs(hashtext(user_id::text)) AS hash_value, 
    abs(hashtext(user_id::text)) % 4 AS partition
FROM 
    users;
+---------+----------+-------------------+------------+-----------+
| user_id | username |       email       | hash_value | partition |
+---------+----------+-------------------+------------+-----------+
|       1 | alice    | alice@example.com |  631133447 |         3 |
|       3 | carol    | carol@example.com | 1895345704 |         0 |
|       5 | eve      | eve@example.com   | 1343054358 |         2 |
|       2 | bob      | bob@example.com   |   95190526 |         2 |
|       4 | dave     | dave@example.com  |  238146292 |         0 |
|       6 | frank    | frank@example.com |    9041812 |         0 |
+---------+----------+-------------------+------------+-----------+
(6 rows)
	

	
postgres@postgres# explain analyze select * from users;
+------------------------------------------------------------------------------------------------------------------------+
|                                                       QUERY PLAN                                                       |
+------------------------------------------------------------------------------------------------------------------------+
| Append  (cost=0.00..91.00 rows=3400 width=68) (actual time=0.011..0.024 rows=6 loops=1)                                |
|   ->  Seq Scan on users_part_1 users_1  (cost=0.00..18.50 rows=850 width=68) (actual time=0.011..0.011 rows=1 loops=1) |
|   ->  Seq Scan on users_part_2 users_2  (cost=0.00..18.50 rows=850 width=68) (actual time=0.004..0.004 rows=2 loops=1) |
|   ->  Seq Scan on users_part_3 users_3  (cost=0.00..18.50 rows=850 width=68) (actual time=0.002..0.003 rows=1 loops=1) |
|   ->  Seq Scan on users_part_4 users_4  (cost=0.00..18.50 rows=850 width=68) (actual time=0.003..0.003 rows=2 loops=1) |
| Planning Time: 0.127 ms                                                                                                |
| Execution Time: 0.053 ms                                                                                               |
+------------------------------------------------------------------------------------------------------------------------+
(7 rows)


```


### Saber el rango de fechas de cada particion
```sql
SELECT
	b.nspname as parent_schema ,
    p.relname AS parent_table,
    pg_get_expr(c.relpartbound, c.oid) AS partition_range 
FROM
    pg_class c
inner JOIN
    pg_inherits i ON c.oid = i.inhrelid
JOIN
    pg_class p ON i.inhparent = p.oid
INNER JOIN 
	pg_namespace as b ON c.relnamespace = b.oid

WHERE
    c.relpartbound is not null;

```


### Saber el rango de fechas de cada particion
```sql

SELECT 
	current_database() as db_name,
	npar.nspname AS parent_schema,
	cpar.relname AS parent_table,
	nrel.nspname AS child_schema,
	crel.relname AS child_table  
FROM pg_inherits i
	INNER JOIN pg_class cpar ON i.inhparent = cpar.oid    and cpar.relkind = 'p'
	INNER JOIN pg_namespace npar ON cpar.relnamespace = npar.oid
	INNER JOIN pg_class crel ON i.inhrelid = crel.oid   and  crel.relkind = 'r'
	INNER JOIN pg_namespace nrel ON crel.relnamespace = nrel.oid 
ORDER BY npar.nspname   ;

```

### Explicación

1. **Tabla principal y particiones**: La tabla `users` se particiona en cuatro subtablas (`users_part_1`, `users_part_2`, `users_part_3`, `users_part_4`) utilizando el valor hash de `user_id`.
2. **Inserción de datos**: Los datos se insertan en la tabla principal y PostgreSQL los distribuye automáticamente entre las particiones.
3. **Consultas**: Las consultas se realizan en la tabla principal y PostgreSQL maneja la distribución de datos internamente.
4. **Verificación**: Podemos verificar la distribución de datos contando los registros en cada partición.

 








# Ensuring Unique IDs in Partitioned PostgreSQL Tables 
```

ONLY  :se utiliza para especificar la tabla ,   sin afectar a sus tablas hijas
CREATE INDEX index_name ON ONLY parent_table (column_name);


https://medium.com/@andriikrymus/ensuring-unique-ids-in-partitioned-postgresql-tables-84b0fa4cf814
```

