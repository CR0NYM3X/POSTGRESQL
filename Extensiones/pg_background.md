
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
 
- `**max_parallel_workers**` = 8  #máximo de trabajadores paralelos en el servidor. Ajusta según tus necesidades
- `**shared_buffers**` = 2GB  # Tamaño de memoria compartida. Ajusta según la cantidad de RAM disponible
- `**work_mem**` = 4MB # : Memoria disponible por proceso.  Ajusta según la carga de trabajo
  
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
   SELECT pg_background_launch('VACUUM FULL my_table');

   select * from pg_background_launch($$ insert into t  select round(random()*10) where  pg_sleep(20) is not null $$);

   select pg_background_launch($$ select 5555,(current_user || '-' ||session_user|| '-' || random()::text)::text as jajaa   where  pg_sleep(20) is not null  $$);

   
   ```

2. **Obtener el resultado de un proceso en segundo plano**:
   ```sql
   SELECT pg_background_result(pid);
   
   -- De esta forma se ejecuta en segundo plano , pero espera a que termine la ejecucion para mostrar el resultado
	SELECT pg_background_result(pg_background_launch('SELECT count(*) FROM your_table'));
   ```

3. **desvincular un trabajador en segundo plano que fue lanzado con pg_background_launch**:
   ```sql
   
   -- desvincular un trabajador en segundo plano que fue lanzado con pg_background_launch, practicamente ya no podras usar la funcion pg_background_result desde la funcion principal 
   SELECT pg_background_detach(pid);
   ```

4. **Validar los procesos** 
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
 
