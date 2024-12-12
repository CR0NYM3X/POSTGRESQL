
# Error \#1 (not create shared memory)

```BASH

********** CUANDO SALE EL ERROR **********
Al intentar iniciar el servicio postgres con el comando "pg_Ctl start -D /sysd/data -o -i" salia el error "not create shared memory"

El error que estás viendo en PostgreSQL se debe a que la solicitud de un segmento de memoria compartida excede el parámetro SHMMAX del kernel de tu sistema operativo. 

### Causa del Error
El mensaje de error indica que PostgreSQL no pudo crear un segmento de memoria compartida porque la solicitud excedió el límite configurado en el parámetro SHMMAX del kernel. Este parámetro define el tamaño máximo de un segmento de memoria compartida que el sistema operativo permite.

### Solución
Tienes dos opciones principales para resolver este problema:

1. **Reducir el tamaño de la solicitud de memoria compartida**:
   - **shared_buffers**: Este parámetro controla la cantidad de memoria que PostgreSQL utiliza para el almacenamiento en caché de datos. Reducir este valor disminuirá la cantidad de memoria compartida que PostgreSQL solicita.
   - **max_connections**: Este parámetro define el número máximo de conexiones simultáneas que PostgreSQL permite. Reducir este valor también puede ayudar a disminuir la solicitud de memoria compartida.

2. **Aumentar el valor de SHMMAX en el kernel**:
   - Para aumentar el valor de SHMMAX, necesitas modificar la configuración del kernel. Esto generalmente se hace editando el archivo `/etc/sysctl.conf` y añadiendo o modificando la línea:
     kernel.shmmax = <nuevo_valor>

   - Después de hacer este cambio, aplica la nueva configuración ejecutando:
     sudo sysctl -p

### Objetivo del Parámetro SHMMAX
El parámetro SHMMAX está diseñado para limitar el tamaño de los segmentos de memoria compartida que pueden ser creados por cualquier proceso en el sistema. Esto ayuda a prevenir que un solo proceso consuma toda la memoria compartida disponible, lo cual podría afectar negativamente a otros procesos en el sistema 
 

********** ERROR ***************
<2024-01-02 11:41:35 CST    6547 65944acf.1993 >FATAL:  could not create shared memory segment: Invalid argument
<2024-01-02 11:41:35 CST    6547 65944acf.1993 >DETAIL:  Failed system call was shmget(key=5432001, size=4412637184, 03600).
<2024-01-02 11:41:35 CST    6547 65944acf.1993 >HINT:  This error usually means   that PostgreSQL's request for a shared memory segment exceeded your kernel's SHMMAX parameter.
You can either reduce the request size or reconfigure the kernel    with larger SHMMAX.  To reduce the request size (currently 4412637184 bytes),
 reduce PostgreSQL's shared_buffers parameter (currently 524288) and/or its max_connections parameter (currently 603). If the request size is already small, it's
possible that it is less than  your kernel's SHMMIN parameter, in which case raising the request size or recon   figuring SHMMIN is called for.
The PostgreSQL documentation contains more information about shared memo  ry configuration.

********** La memoria compartida sirve para :  **********
1.- Mejora el rendimiento:
2.- Soporte para múltiples conexiones:
3.- Optimización de consultas:
4.-  Mantenimiento de consistencia:
5.- Gestión de recursos 

********** Ver info de la memorio ram **********
free -m

********** para ver cuanto es lo que se esta usando de memoria compartida y el limite de conexiones  en postgres **********
cat /sysd/data/postgres.conf | grep shared_buffers
cat /sysd/data/postgres.conf | grep max_connections

SHOW shared_buffers;
SHOW max_connections;


********** para configurar el tamaño maximo y minimo en bytes  **********
sysctl -w kernel.shmmax=4412637184
sysctl -w kernel.shmall=4194304

********** Para ver el detalle  **********
sysctl kernel.shmmax
sysctl kernel.shmall

********** para ver la información  **********
/etc/sysctl.conf
/proc/sys/kernel/shmall
/proc/sys/kernel/shmmax
/proc/sys/kernel/shmmni


getconf PAGE_SIZE


********** SOLUCION RAPIDA **********
bajar la memoria compartida del /sysd/data/postgres.conf

```





# Error \#2  (LOG:  invalid primary checkpoint record, PANIC:  could not locate a valid checkpoint record)


```BASH
********** CUANDO SALE EL ERROR **********
Al intentar iniciar el servicio postgres con el comando "pg_Ctl start -D /sysd/data -o -i" salia el error "LOG:  invalid primary checkpoint record, PANIC:  could not locate a valid checkpoint record"

********** ERROR **********
LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
<2024-01-02 11:53:19 MST     2291249 65945b9f.22f631 > LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
<2024-01-02 11:53:19 MST     2291251 65945b9f.22f633 > LOG:  database system was shut down at 2023-03-10 18:06:07 MST
<2024-01-02 11:53:19 MST     2291251 65945b9f.22f633 > LOG:  invalid primary checkpoint record
<2024-01-02 11:53:19 MST     2291251 65945b9f.22f633 > PANIC:  could not locate a valid checkpoint record
<2024-01-02 11:53:20 MST     2291249 65945b9f.22f631 > LOG:  startup process (PID 2291251) was terminated by signal 6: Aborted
<2024-01-02 11:53:20 MST     2291249 65945b9f.22f631 > LOG:  aborting startup due to startup process failure
<2024-01-02 11:53:20 MST     2291249 65945b9f.22f631 > LOG:  database system is shut down


********** SOLUCION RAPIDA **********
# pg_resetwal :  partir de PostgreSQL 10 , se utiliza para restablecer los archivos WAL, borrando los archivos wall, Este comando es útil en situaciones
# específicas donde los archivos WAL se han corrompido o  Es una herramienta de último recurso para intentar que un servidor de base de datos dañado vuelva a arrancar
# pg_resetxlog : hasta la versión 9.6 tiene el mismo objetivo que pg_resetwal

pg_resetwal -f -D /sysx/data
pg_resetxlog -f -D  /sysx/data


********** Alternativa **********
1.- Se ejecuta este comando para validar el el utimo archivo wal en uso
/rutabinario/bin/pg_controldata -D /rutadata/data | grep "REDO WAL"
 
 
2.- (A partir de que se le indica el último wal utilizado, hace la depuración de forma
regresiva para los archivos ya leídos pero que seguían conservando.) 
Una vez que se obtiene el dato se ejecuta el siguiente comando:

/rutabinario/bin/pg_archivecleanup /RUTADIRECTORIOWAL/0000000100000440000000E9
```


# Error \#3 (ERROR:  invalid byte sequence for encoding "UTF8": 0xbf)
Este detalle se presenta ya que se ingreso un caracter no valido 

```SQL

********** CUANDO SALE EL ERROR **********
Al realizar una consulta "select * from mytabla_test limit 10" salia el error "ERROR:  invalid byte sequence for encoding "UTF8": 0xbf"

# 1.- Encontrar la columna que presenta el detalle.
select 'select ' || column_name|| 'from mytabla_test limit 1;' from information_schema.columns
where  table_name = 'mytabla_test' order by ordinal_position ;


# 2.- intentar convertir a utf8 o latin1 la columna que popresenta el detalle:
Select convert_from(column_text::bytea, 'utf8')  from mytabla_test limit 1;
select convert_from(convert_to('TESTµTEST','utf-8'),'latin-1');
select * from mytabla_test where nom_rol !~ '^[[:ascii:]]*$' ;


#3.- Encontrar las filas que presentan el detalle para al final modifcarlas con un update
SELECT * FROM tu_tabla WHERE convert_from(convert_to(tu_columna, 'UTF8'), 'UTF8') IS NULL;



4).- Detectar el id que genera el error

DO $$
DECLARE
    rec RECORD;
    row_number INTEGER := 0;
    error_lines TEXT := '';
	error_oid int[];
	query text;
BEGIN
	set client_min_messages = notice ; 
	query := E'SELECT oid,relname AS table_name FROM pg_class WHERE relkind = \'r\'  ' ;
	
    FOR rec IN execute query  LOOP
        row_number := row_number + 1;
        BEGIN
            -- Aquí puedes poner la lógica que podría causar un error
            -- Por ejemplo, una conversión de codificación
            PERFORM pg_catalog.convert_from(rec.table_name::bytea, 'UTF8');
        EXCEPTION
            WHEN OTHERS THEN
				RAISE NOTICE 'Error en el OID : %  | fila % | Error MSG  --> %',   rec.oid , row_number ,  SQLERRM;
                		-- error_lines := error_lines || 'Error en la fila ' || row_number || E'\n';
				
				error_oid := array_append(error_oid, rec.oid);
				 
        END;
    END LOOP;

    IF error_lines = '' THEN
        RAISE NOTICE E'\n\nNo se encontraron errores';
    ELSE
		query := FORMAT( '%s and not oid in(%s) ; ' ,  query, array_to_string(error_oid,','));
		
        RAISE NOTICE E'\n\nErrores encontrados:\n %', query;
		
		 
    END IF;
END $$;


\l db_test
                                         List of databases
     Name     |      Owner      | Encoding  | Collate | Ctype |          Access privileges
--------------+-----------------+-----------+---------+-------+-------------------------------------
 db_test 		| user_test		 | SQL_ASCII | C       | en_US


 db_test=# show client_encoding;
 client_encoding
-----------------
 UTF8
(1 row)


db_test=# set client_encoding = SQL_ASCII;
SET


db_test=#  SELECT oid,relname AS table_name FROM pg_class WHERE relkind = 'r'   and  oid in(11502328,11502322) ;
   oid    | table_name
----------+------------
 11502328 | tg▒
 11502322 | tgy▒




```

# Errores en el  archivo s.pgsql.5432.lock

Si el servidor PostgreSQL se cierra inesperadamente y deja un archivo de bloqueo, podrías necesitar eliminarlo manualmente antes de reiniciar el servidor:
Si intentas iniciar otra instancia de PostgreSQL que intente usar el mismo puerto, esta verificará la existencia del archivo de bloqueo. Si el archivo existe y el PID en el archivo corresponde a un proceso en ejecución, la nueva instancia no se iniciará y se generará un error.

```
sudo rm /var/run/postgresql/.s.PGSQL.5432.lock
```






