
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


# Error \#3 (ERROR:  invalid byte sequence for encoding "UTF8": 0xbf) [link](https://www.postgresql.org/docs/current/multibyte.html)
Este detalle se presenta ya que se ingreso un caracter no valido 

```SQL

SET client_encoding TO 'LATIN1';

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


 db_test=# SHOW SERVER_ENCODING; SHOW CLIENT_ENCODING;
server_encoding
-----------------
 SQL_ASCII
(1 row)

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



---------------

DO $$
DECLARE
    rec RECORD;
	query text;
BEGIN
	set client_min_messages = notice ; 
	
	query := E'select row_number() OVER () as row_number, * from cat_proveedor ' ;
	
    FOR rec IN execute query  LOOP
        --row_number := row_number + 1;
        BEGIN
            -- Aquí puedes poner la lógica que podría causar un error
            -- Por ejemplo, una conversión de codificación
            PERFORM pg_catalog.convert_from(rec.direccion::bytea, 'UTF8');
        EXCEPTION
            WHEN OTHERS THEN
				 RAISE NOTICE 'Error  fila %  -> select * from ( % ) as a where row_number = % ; ',   rec.row_number ,query ,   rec.row_number  ;
	 
        END;
    END LOOP;
 
END $$;

### Resumen del error `0xe1 0x6c 0x6f`

Lo que intentabas leer era probablemente la palabra **"álo"** (como en "catálogo").

* En **LATIN1**: Se guarda como `e1` (á) + `6c` (l) + `6f` (o). **(3 bytes)**.
* En **UTF8**: La "á" se debería guardar como `c3 a1`. La palabra completa sería `c3 a1 6c 6f`. **(4 bytes)**.

Como tu base de datos `SQL_ASCII` tiene guardada la versión de 3 bytes (Latin1), cuando tu cliente intentó leerla como si fuera UTF8, se confundió al ver que a la "á" le faltaban piezas.

> **Nota:** Si planeas seguir trabajando con esta base de datos, te recomiendo dejar tu configuración de conexión o driver siempre en `LATIN1` (o `WIN1252`) para evitar que estos errores interrumpan tus reportes.



```


 

### 1. El problema: Dos manuales diferentes
Imagina que los datos en tu base de datos son como piezas de un rompecabezas y el "Encoding" (codificación) es el manual de instrucciones para armarlas.
En tu base de datos hay una palabra guardada (probablemente una que lleva la letra **á**).

* **En el manual LATIN1 (lo que tienes guardado):** Para escribir la letra **á**, solo necesitas **1 pieza** (el byte `0xe1`).
* **En el manual UTF8 (lo que tu programa quería leer):** Para escribir la letra **á**, el manual dice que necesitas **2 piezas obligatoriamente** (`0xc3` y `0xa1`).

### 2. ¿Qué vio la computadora? (Paso a paso)

Tu programa (que usa UTF8) empezó a leer los bytes que encontró en la base de datos:

1. **Encuentra el primer byte: `0xe1**`
* **Regla de UTF8:** "Si un grupo empieza con `0xe1`, significa que es una letra especial que debe tener **3 piezas en total**".
* **Computadora dice:** "Ok, espero las otras 2 piezas para formar la letra".


2. **Encuentra el segundo byte: `0x6c` (que es la letra "l")**
* **Regla de UTF8:** "La segunda pieza de un grupo de tres **DEBE** empezar con un código específico (un bit 1 seguido de un 0)".
* **Computadora revisa el `0x6c`:** "¡Un momento! Esta pieza (`0x6c`) no sigue la regla. No encaja con la primera".


3. **El Choque (Error):**
* Como la segunda pieza no es lo que el manual de UTF8 esperaba, la computadora se confunde, se detiene y te lanza el error: **"Secuencia de bytes no válida"**. Es como si intentaras meter una pieza de DUPLO en un set de LEGO técnico; simplemente no cierran.

 

### 3. ¿Por qué con LATIN1 sí funciona?

Cuando cambiaste a `LATIN1`, le diste a la computadora el manual correcto para esos datos.

* En el manual **LATIN1**, no hay "grupos de piezas". Cada pieza es una letra independiente.
* `0xe1` = **á**
* `0x6c` = **l**
* `0x6f` = **o**
* **Resultado:** La computadora lee **"álo"** sin problemas porque no busca reglas complejas de combinación.

 ---


# Errores en el  archivo s.pgsql.5432.lock

Si el servidor PostgreSQL se cierra inesperadamente y deja un archivo de bloqueo, podrías necesitar eliminarlo manualmente antes de reiniciar el servidor:
Si intentas iniciar otra instancia de PostgreSQL que intente usar el mismo puerto, esta verificará la existencia del archivo de bloqueo. Si el archivo existe y el PID en el archivo corresponde a un proceso en ejecución, la nueva instancia no se iniciará y se generará un error.

```
sudo rm /var/run/postgresql/.s.PGSQL.5432.lock
```

# Error #4 PQgetCurrentTimeUSec
Esto ocurre porque estas ejecutando el psql con librerias de una version antigua y la funcion PQgetCurrentTimeUSec es nueva en la lib libpq

```markdown
# 0 - Ver la ruta de donde se ejecuta el binario
[postgres@server_test ~]$ which  psql
/usr/pgsql-17/bin/psql



# 1 - Nos conectamos a psql 17 
[postgres@server_test ~]$ $PGBIN17/psql -p 5417

 🐘 Current Host Server Date Time : Thu Feb 20 14:37:00 MST 2025

psql (17.2)
Type "help" for help.

postgres@postgres#  \c test 
/usr/pgsql-17/bin/psql: symbol lookup error: /usr/pgsql-17/bin/psql: undefined symbol: PQgetCurrentTimeUSec
[postgres@server_test ~]$



# 2 - Revisamos dependencias 
[postgres@server_test ~]$ ldd  /usr/pgsql-17/bin/psql | grep libpq
        libpq.so.5 => /usr/pgsql-16/lib/libpq.so.5 (0x00007f325f928000)

#  Quí esta el problema el binario de psql  esta intentando cargar libreria libpq.so de la version 16 "/usr/pgsql-16/lib/libpq.so.5"



# 3 -  Revisamos la variable de entorno donde indica las librerias/bibliotecas compartidas .so a linux 
[postgres@server_test ~]$ echo $LD_LIBRARY_PATH
:/usr/pgsql-16/lib



# 4 -  Modificamos las variables de entorno 
vim /home/postgres/.bash_profile
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/pgsql-17/lib
	export PATH=/usr/pgsql-16/bin:$PATH
	

# 5 - Con esto ya debe de quedar 
```

---
 
# Error #5 el client_encoding  no se cambia 

```bash
jdbc:postgresql://host:5432/test?charSet=LATIN1
```

### 1. La solución definitiva: Variable de entorno

En Linux, la forma más poderosa de forzar a `psql` es definiendo la variable `PGCLIENTENCODING` antes de entrar. Haz la prueba con esto:

```bash
export PGCLIENTENCODING=latin1
psql -p 5414 -d test

```

Una vez dentro, ejecuta `show client_encoding;`. Debería mostrar **LATIN1**.

*Si esto funciona, puedes agregar ese `export` al final de tu archivo `~/.bash_profile` o `~/.bashrc` para que sea permanente.*

### 2. ¿Por qué falló el `ALTER ROLE`?

El orden de prioridad en PostgreSQL es este:

1. **Parámetros de conexión del cliente** (Lo que `psql` negocia al inicio) **<-- AQUÍ ESTÁ TU PROBLEMA.**
2. `ALTER ROLE ... SET ...`
3. `ALTER DATABASE ... SET ...`
4. `postgresql.conf`

Como tu terminal Linux está configurada en `en_US.UTF-8` (lo vimos en tu tabla de bases de datos), el cliente `psql` toma el nivel 1 de prioridad y aplasta tus configuraciones de los niveles 2, 3 y 4.

### 3. Verifica tu Localización (Locale)

Ejecuta este comando en tu terminal Linux (fuera de postgres):

```bash
locale

```

Probablemente verás que `LANG` o `LC_CTYPE` dicen `en_US.UTF-8`. Mientras eso esté así, `psql` siempre intentará conectar en UTF8 a menos que uses el `export` que te puse arriba.
 

### 4. Otra opción: Forzar desde el `.psqlrc`

Veo que tienes un archivo `.psqlrc` bastante personalizado (por el emoji del elefante 🐘 y los mensajes de tiempo). Puedes forzar la codificación agregando esta línea al principio de tu archivo `/home/postgres/.psqlrc`:

```sql
\encoding latin1
```

-----


# Error #6 -  Espacio Lleno del disco  DATA


Si `/sysx/data` está al 100%, estamos en el escenario más delicado porque aquí reside la estructura física de tus tablas e índices. Al estar lleno, PostgreSQL no puede realizar operaciones de escritura mínimas ni siquiera para arrancar el proceso de recuperación.

Como experto, aquí tienes las tres rutas de acción técnica, de la más segura a la más agresiva:


## 1. Limpieza de archivos temporales (La "vía rápida")

Cuando una consulta pesada (un `SORT` o `JOIN` masivo) falla o el sistema se apaga inesperadamente, PostgreSQL puede dejar archivos temporales huérfanos que ocupan gigabytes.

* **Identifica y borra `pgsql_tmp`:**
Busca dentro de las carpetas de las bases de datos. Estos archivos son seguros de borrar **si la base de datos está apagada**.
```bash
# Buscar carpetas de temporales
find /sysx/data/base -name "pgsql_tmp" -type d

# Entrar y borrar su contenido (no la carpeta en sí, solo el contenido)
rm -rf /sysx/data/base/*/pgsql_tmp/*

```

 

## 2. Expansión de Volumen (La vía recomendada)

Si tu infraestructura lo permite (LVM, AWS EBS, GCP Disk, VMware), esta es la solución que garantiza la integridad total de los datos.

1. **Aumenta el disco** desde tu hipervisor o panel de control.
2. **Extiende el sistema de archivos** (ejemplo para LVM y XFS/Ext4):
```bash
# Para LVM
lvextend -l +100%FREE /dev/mapper/vg_sysx-lv_data

# Para Ext4
resize2fs /dev/mapper/vg_sysx-lv_data

# Para XFS
xfs_growfs /sysx/data

```



Una vez que tengas aunque sea 100MB libres, el servicio arrancará.


## 3. El truco del "Enlace Simbólico" (Emergencia extrema)

Si no puedes ampliar el disco y no hay temporales que borrar, necesitamos "engañar" a PostgreSQL para que crea que tiene espacio.

> [!WARNING]
> Realiza esto con precaución. Es solo para que la base de datos inicie y puedas ejecutar un `DROP TABLE` o `VACUUM`.

1. Identifica un archivo de índice o tabla muy grande dentro de `/sysx/data/base/...`.
2. **Mueve** ese archivo físico a otro disco que tenga espacio (por ejemplo, a `/pg_log` temporalmente).
3. Crea un **enlace simbólico** (symlink) apuntando de vuelta a la ubicación original.
```bash
mv /sysx/data/base/12345/67890 /pg_log/archivo_temporal_67890
ln -s /pg_log/archivo_temporal_67890 /sysx/data/base/12345/67890
chown postgres:postgres /sysx/data/base/12345/67890

```

4. Inicia PostgreSQL. Ahora que tiene espacio "virtual", podrás entrar y borrar datos antiguos de forma controlada.

 
## 4. Acciones post-recuperación (Una vez que inicie)

No te confíes. En cuanto el servicio esté arriba, debes liberar espacio real:

* **VACUUM FULL:** Si tienes tablas con mucho espacio muerto (bloat), el `VACUUM FULL` compactará el archivo, pero **ojo**: requiere espacio extra para trabajar.
* **REINDEX:** Si un índice está corrupto o es gigante, `REINDEX TABLE nombre_tabla;` puede ayudar.
* **DROP/TRUNCATE:** Elimina tablas de logs antiguos o tablas temporales que ya no sirvan.



--- 

# Error 7 :   `ERROR:  cache lookup failed for user mapping 9338042 `

 
## Cómo se crean los huérfanos en `pg_shdepend`

Cuando se ejecuta el comando `CREATE USER MAPPING`, PostgreSQL realiza **dos acciones atómicas** en el catálogo del sistema:

1. **Inserción en `pg_user_mapping**`: Se registra la relación usuario/servidor.
2. **Inserción en `pg_shdepend**`: Se registra la dependencia de seguridad (`classid=1418`, `objid=OID` del mapping).

El problema de los "objetos fantasma" ocurre cuando el `DROP USER MAPPING` no se procesa íntegramente, eliminando el registro en la tabla de mapeo pero dejando la referencia de dependencia en `pg_shdepend`.

### Causas más comunes

#### 1. Drop incompleto o interrumpido

Ocurre cuando la ejecución del comando es terminada abruptamente antes de finalizar la limpieza de los catálogos compartidos.

```sql
-- Si el comando se interrumpe por corte de conexión, crash o timeout:
DROP USER MAPPING FOR "user_test333" SERVER foreign_historicocajas;
-- La transacción podría quedar en un estado inconsistente en el catálogo.

```

#### 2. Borrado manual directo en el catálogo (Altamente desaconsejado)

Es la causa principal en entornos donde se intenta "arreglar" problemas mediante DML directo sobre tablas de sistema.

```sql
-- El borrado manual NO dispara los triggers internos de limpieza:
DELETE FROM pg_user_mapping WHERE umuser = 12345;
-- Esto NO limpia pg_shdepend automáticamente.

```

#### 3. Restore parcial o `pg_restore` inconsistente

Si se realiza una restauración desde un respaldo que ya presentaba inconsistencias lógicas entre el catálogo local (`pg_user_mapping`) y el catálogo compartido (`pg_shdepend`).

#### 4. Bugs en versiones específicas

Ciertas versiones de `postgres_fdw` presentan comportamientos documentados donde las operaciones de `DROP` en cascada no barren correctamente todas las referencias en los catálogos globales del clúster.
 

```
SELECT 
    objid, 
    classid::regclass AS object_class, 
    CASE 
        WHEN classid = 'pg_class'::regclass THEN objid::regclass::text
        WHEN classid = 'pg_type'::regclass THEN objid::regtype::text
        WHEN classid = 'pg_namespace'::regclass THEN (SELECT nspname FROM pg_namespace WHERE oid = objid)
        ELSE objid::text
    END AS object_name,
    deptype
FROM pg_shdepend 
WHERE refclassid = 'pg_authid'::regclass 
AND refobjid = (SELECT oid FROM pg_roles WHERE rolname = 'user_test333');



-- Confirmar que efectivamente no existen
SELECT oid FROM pg_user_mapping WHERE oid IN (9338042, 9338043, 9338044);
-- Debe retornar 0 rows

-- Confirmar que siguen en pg_shdepend
SELECT * FROM pg_shdepend
WHERE refobjid = (SELECT oid FROM pg_roles WHERE rolname = 'user_test333');

-- Estando en la base 'riesgos'
SET session_replication_role = 'replica';

DELETE FROM pg_shdepend
WHERE refobjid = (SELECT oid FROM pg_roles WHERE rolname = 'user_test333')
AND classid = 1418;  -- 1418 = pg_user_mapping

SET session_replication_role = 'DEFAULT';


```
