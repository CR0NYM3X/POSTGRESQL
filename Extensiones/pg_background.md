
`pg_background` es una extensión para PostgreSQL que permite ejecutar comandos SQL de manera asíncrona en procesos en segundo plano, utiliza el mismo usuario que ejecuto las funciones para ejecutar las querys en segundo plano.

https://github.com/vibhorkum/pg_background

### Usos de `pg_background`:



 **Mantenimiento de Bases de Datos:**
- **VACUUM y ANALYZE**: Ejecutar comandos de mantenimiento como `VACUUM` y `ANALYZE` en segundo plano para mantener el rendimiento y la eficiencia de las tablas sin bloquear las operaciones diarias.
 

 **Indexación y Reindexación:**
- **CREATE INDEX y REINDEX**: Crear índices o reindexar tablas grandes para mejorar las consultas sin interrumpir el acceso a la base de datos.
 
  **Carga y Procesamiento de Datos:**
- **ETL (Extracción, Transformación y Carga)**: Realizar tareas de carga de datos y procesamiento intensivo en segundo plano para mejorar el rendimiento del sistema.
 

 **Tareas Programadas y Automatización:**
- **Tareas Periódicas**: Ejecutar tareas programadas periódicas como informes y agregaciones en segundo plano sin afectar las operaciones en tiempo real.
 

 **Monitoreo y Reportes:**
- **Generación de Reportes**: Generar reportes extensos o consultas analíticas en segundo plano para evitar el bloqueo de operaciones interactivas.
  


### Ejemplo de Uso:

# Limite de procesos 	
Tienes un limite de procesos para abrir y esto depende como tienes configurado tu servidor, en caso de querer abrir mas procesos de lo permitido aparecera este mensaje, 
- `**max_worker_processes**` controla el número total de procesos que pueden ejecutarse en segundo plano. Es recomendable ajustar este parámetro en función del hardware disponible, especialmente la cantidad de núcleos de CPU. Aumentar demasiado este valor puede causar competencia por recursos y degradar el rendimiento. reserva un número de estos procesos para tareas críticas del sistema.

Otros procesos que puedes ajustar 
 
- `**max_parallel_workers**`    #máximo de trabajadores paralelos en el servidor. Ajusta según tus necesidades
- `**shared_buffers**`    # Tamaño de memoria compartida. Ajusta según la cantidad de RAM disponible
- `**work_mem**`   # : Memoria disponible por proceso.  Ajusta según la carga de trabajo
  
   ```sql
	postgres@postgres# SELECT * FROM lanzar_y_validar_procesos(15);
	ERROR:  could not register background process
	HINT:  You may need to increase max_worker_processes.
	CONTEXT:  PL/pgSQL function lanzar_y_validar_procesos(integer) line 9 at assignment
	Time: 7.471 ms

	postgres@postgres# set max_worker_processes = 30 ;
	ERROR:  parameter "max_worker_processes" cannot be changed without restarting the server
	Time: 0.868 ms

   ```




1. **Ejecutar una consulta en segundo plano**:
   ```sql
create EXTENSION pg_background;
   
-- Crear tabla básica
-- DROP TABLE empleados;
CREATE TABLE empleados (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100),
  puesto VARCHAR(50),
  salario DECIMAL(10,2)
);


-- Insertar registros
INSERT INTO empleados (nombre, puesto, salario) VALUES
('Ana Gómez', 'Desarrolladora', 85000.00),
('Luis Martínez', 'Administrador', 72000.00),
('Carla Ruiz', 'Analista de datos', 79000.00);

postgres@postgres# SELECT * FROM empleados;
+----+---------------+-------------------+----------+
| id |    nombre     |      puesto       | salario  |
+----+---------------+-------------------+----------+
|  1 | Ana Gómez     | Desarrolladora    | 85000.00 |
|  2 | Luis Martínez | Administrador     | 72000.00 |
|  3 | Carla Ruiz    | Analista de datos | 79000.00 |




postgres@postgres#   SELECT pg_background_launch('VACUUM VERBOSE public.empleados');
+----------------------+
| pg_background_launch |
+----------------------+
|              3848023 |
+----------------------+
(1 row)

Time: 1.394 ms
postgres@postgres# SELECT * FROM pg_background_result(3848023) foo(result TEXT);
INFO:  vacuuming "postgres.public.empleados"
INFO:  finished vacuuming "postgres.public.empleados": index scans: 0
pages: 0 removed, 1 remain, 1 scanned (100.00% of total)
tuples: 0 removed, 3 remain, 0 are dead but not yet removable
removable cutoff: 55947, which was 0 XIDs old when operation ended
index scan not needed: 0 pages from table (0.00% of total) had 0 dead item identifiers removed
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 43 hits, 0 misses, 0 dirtied
WAL usage: 0 records, 0 full page images, 0 bytes
system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
+--------+
| result |
+--------+
| VACUUM |
+--------+
(1 row)

Time: 0.374 ms


postgres@postgres# select * from pg_background_launch($$  INSERT INTO empleados (nombre, puesto, salario) VALUES ('JOSE Gómez', 'Desarrolladora', 85000.00); $$);
+----------------------+
| pg_background_launch |
+----------------------+
|              3848356 |
+----------------------+
(1 row)

Time: 1.279 ms
postgres@postgres# SELECT * FROM pg_background_result(3848356) foo(result TEXT);
+------------+
|   result   |
+------------+
| INSERT 0 1 |
+------------+
(1 row)

Time: 0.707 ms
postgres@postgres# SELECT * FROM pg_background_result(3848356) foo(result TEXT);
ERROR:  PID 3848356 is not attached to this session
Time: 1.002 ms

postgres@postgres# SELECT * FROM empleados;
+----+---------------+-------------------+----------+
| id |    nombre     |      puesto       | salario  |
+----+---------------+-------------------+----------+
|  1 | Ana Gómez     | Desarrolladora    | 85000.00 |
|  2 | Luis Martínez | Administrador     | 72000.00 |
|  3 | Carla Ruiz    | Analista de datos | 79000.00 |
|  4 | JOSE Gómez    | Desarrolladora    | 85000.00 |
+----+---------------+-------------------+----------+
(4 rows)


--- esta forma espera a que el proceso retorne el resultado y luego te muestra el resultado
postgres@postgres# SELECT * FROM pg_background_result(pg_background_launch($$ SELECT 5555::INT AS count WHERE pg_sleep(2) IS NOT NULL $$)) AS foo(count INT);
+-------+
| count |
+-------+
|  5555 |
+-------+
(1 row)

Time: 2007.009 ms (00:02.007)



postgres@postgres# SELECT * FROM pg_background_result(pg_background_launch($$ SELECT * FROM empleados; $$)) AS foo(  id INT,nombre VARCHAR(100),puesto VARCHAR(50),salario DECIMAL(10,2));
+----+---------------+-------------------+----------+
| id |    nombre     |      puesto       | salario  |
+----+---------------+-------------------+----------+
|  1 | Ana Gómez     | Desarrolladora    | 85000.00 |
|  2 | Luis Martínez | Administrador     | 72000.00 |
|  3 | Carla Ruiz    | Analista de datos | 79000.00 |
|  4 | JOSE Gómez    | Desarrolladora    | 85000.00 |
+----+---------------+-------------------+----------+
(4 rows)

Time: 6.548 ms

   
   ```

2. **Obtener el resultado de un proceso en segundo plano**:
   Hay que tener cuidado con los type ya que esto puede generar errores 
   ```sql
   SELECT pg_background_result(pid);
   
   -- De esta forma se ejecuta en segundo plano , pero espera a que termine la ejecucion para mostrar el resultado
	SELECT pg_background_result(pg_background_launch('SELECT count(*) FROM your_table'))  AS (result TEXT);
   ```

4. **desvincular un trabajador en segundo plano que fue lanzado con pg_background_launch**:
   ```sql
   
   -- desvincular un trabajador en segundo plano que fue lanzado con pg_background_launch, practicamente ya no podras usar la funcion pg_background_result desde la funcion principal 
   SELECT pg_background_detach(pid);
   ```

5. **Validar los procesos** 
   ```sql
   select pid from pg_stat_activity where backend_type !~* 'launcher' and pid <> pg_backend_pid() and not backend_type in('walwriter','checkpointer','background writer') and pid <> 976760 and state = 'active' ;

   select * from pg_stat_activity where  PID = 972751;
   ```

# Extra ejemplos 
```sql
CREATE TABLE t(id integer);

SELECT * FROM pg_background_result(pg_background_launch('INSERT INTO t SELECT 1')) AS (result TEXT);
SELECT * FROM t;
truncate table t;
```
 
