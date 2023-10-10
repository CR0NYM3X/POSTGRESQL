
![back](https://img.freepik.com/premium-vector/vector-icon-backup-restore-cloud-web-app_901408-682.jpg)

- Comando --Help
	- [Pg_dump](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Respaldo%20y%20Restauraci%C3%B3n.md#pg_dump---help)
	- [Pg_dumpall](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Respaldo%20y%20Restauraci%C3%B3n.md#pg_dumpall---help)
	- [pg_restore](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Respaldo%20y%20Restauraci%C3%B3n.md#pg_restore---help)
 	- [Copy](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Respaldo%20y%20Restauraci%C3%B3n.md#copy)

   
# Objetivo:
aprenderemos hacer respaldos y a restaurarlos 

# Descripcion rápida :
Los respaldos son fundamentales para garantizar la disponibilidad y la integridad de los datos en una base de datos. Aquí te muestro un ejemplo de configuración de respaldos en PostgreSQL basado en mejores prácticas:

**`Elección de Herramientas de Respaldo:`**
PostgreSQL ofrece herramientas nativas como pg_dump y pg_basebackup para realizar respaldos.
Se pueden utilizar herramientas de terceros como Barman o pgBackRest que ofrecen características avanzadas de respaldo y recuperación.

**`Frecuencia de Respaldos:`**
Define la frecuencia de respaldos según la criticidad de tus datos y la cantidad de cambios. Los respaldos diarios son comunes para muchas aplicaciones

**`Tipo de Respaldos:`**
Puedes realizar respaldos completos (full backups), incrementales o diferenciales, según tus necesidades.

**`Almacenamiento de Respaldos:`**
Almacena los respaldos en ubicaciones seguras y fuera del servidor de la base de datos para evitar la pérdida de datos en caso de falla del servidor.

**`Automatización:`**
Configura scripts o programaciones para ejecutar automáticamente los respaldos en los horarios planificados.

**`Documentación:`**
Mantén registros detallados de tu política de respaldo, horarios y procedimientos.


**`Herramintas de respaldo`** 
pg_dump : Puedes respaldar solo una base de datos
pg_dumpall : aquí se respalda todas las base de datos
copy

**`Herramintas de restauración`** 
psql : restauras respaldos en texto plano 
pg_restore : restauras respaldos con formatos custom o directory, pero es mejor, porque puedes especificar que es lo que quieres restaurar, en caso de solo querer restaurar una tabla se puede realizar 
copy

# Ejemplos de uso:
**`[Nota]`** - Al usar `pg_dump` en Automática te genera el create de los objetos<br>
**`[Nota]`** - Antes de realizar un respaldo debemos de corroborar que los 2 servidores como el origen y destino tengan la misma versión de sql. <br>
**`[Nota]`** - Verificar que tengan el espacio suficiente para pasar el respaldo .<br>
**`[Nota]`** - Verificar que el servidor destino cuenta ya con esa información y sí ya tiene información, preguntar al usuario que hacer con la información, si se borra o también se respalda.<br>
**`[Nota]`** - No se puede restaurar con `PSQL` los respaldos con formato custom o Directory, sólo se puede respaldar con PSQL los respaldos en texto plano, esto quiere decir que cuando abres el respaldo se ve el código de los create, funciones etc.
**`[Nota]`** - Con pg_restore solo se pueden restaurar los respaldos con formato Custom y directory 


**Descripción de Servidores para ejemplos**
```
Servidor Origen: 10.44.1.55 | Postgresql 15
DBA: 
Banco 	| Tamaño: 500GB
Tienda	| Tamaño: 100GB 

SCHEMA Banco:
sch_tienda
sch_tienda_backup55

Tablas Banco: 
Clientes  	|  Tamaño: 50GB
Direccion 	| Tamaño: 20GB
Ciudades  	| Tamaño: 10GB
Estados   	| Tamaño: 5GB
Formas_pago	| Tamaño: 2.5GB


SCHEMA Tienda: 
sch_tienda
sch_tienda_respaldo100

Tablas Tienda: 
Productos	| 50GB
Inventario	| 25GB
Precios		| 10GB


Servidor Destino: 10.44.1.55 | Postgresql 15


```


### Ejemplo #1:  

**`Respaldar`** toda la base de datos "Banco", junto con su usuarios y que solo respalde las tablas del schema sch_tienda, public y no respalde las tablas del schema sch_tienda_respaldo100 y que use el encoding "UTF8" , tambien intentar comprimirlo al máximo


```

pg_dump -p5432 -d banco -n sch_tienda -n public -N sch_tienda_respaldo100 -E UTF8 -F c -Z 9 -f /tmp/bckup_banco.sql.gz &
pg_dumpall -g -f /tmp/usuarios.sql  


#Descripción de los parámetros pg_dump
-p  	--> Aquí especificamos el puerto
-d	--> Aquí especificamos la base de datos 
-n	--> Aquí especificamos el schema que queremos respaldar 
-N	--> Aquí especificamos el schema que no queremos respaldar 
-E	--> Aquí especificamos el Encoding
-F c    --> Indicamos que sea formato Custom
-Z 9	--> Indicamos que se comprima al máximo
-f	--> Aquí especificamos la ruta donde queremos que se guarde el respaldo 
&	--> esto nos ayuda a que podamos seguir utilizando la terminal de linux y no se quede atorado realizando el respaldo

#Descripción de los parámetros pg_dumpall
-g --> Guarda todo los usuarios con sus contraseñas 

```
**`Verificar que si se está realizando el respaldo`**
```
Opción #1 - Validar los procesos
ps -fea | grep pg_dump

Opción #2 - Validar el tamaño del archivo, cuando deje de imcrementar esto quiere decir que ya termino
watch " echo "" && echo "" && echo  -e  "------ Procesos del PG_DUMP---- " && ps -fea | grep pg_dump && echo "" && echo "" && echo  -e " ------Tamaño del archivo---- " &&  ls -lhtr /tmp | grep bckup_banco.sql.gz"

Opción #3 - Verificar el tamaño de la base de datos
psql -c "\l+"
 
```

**`Restaurar`**

```
psql -d Banco -f  /tmp/usuarios.sql
pg_restore -d Banco  /tmp/mydb_fdw bckup_banco.sql.gz

#Descripción de los parámetros
-d --> Colocamos la base de datos

```




### Ejemplo #2:  
Generar un respaldo que contenga solo los CREATE de los objetos de la base de datos "Banco", las tablas deben de estar vacias 

**`Respaldar`**
```
pg_dump -d Banco -s -f /tmp/bck_banco_struc.sql

#Descripción de los parámetros
-d --> colocas la base de datos a respaldar
-s --> sólo respalda los CREATE de los objetos, esto quiere decir que no tiene información por ejemplo las tablas 

```
**`Restaurar`**
```
psql -d Banco -f /tmp/bck_banco_struc.sql
```

### Ejemplo #3:  
Respaldar toda la base de datos "Banco" en texto plano, excepto la tabla Ciudades y Estados,  que este compreso con gzip, que al restaurar borre la base de datos, si ya existe y inserte la información nueva

```
pg_dump -d Banco -T Ciudades -T Estados -C -c | gzip -c9 > /tmp/bck_banco.sql &

#Descripción de los parámetros
-d --> colocas la base de datos a respaldar
-T --> colocas la tabla que no quieres respaldar
-C -->  grega el CREATE de la base de datos
-c -->  Agrega el drop de los objetos

```
**`Restaurar`**
```
# Esto lo que hace es que no genera un archivo descomprimido del archivo bck_banco.sql si no que lo va ingresando directamente a la base de datos

gzip -dc /tmp/bck_banco.sql | psql -d Banco 
```



### Ejemplo #5:  
Respaldar  solo la Estructura de  las tabla Clientes de la base de datos  Banco

```
pg_dump -d Banco -s -t Clientes -f /tmp/bck_banco_truc.sql 

#Descripción de los parámetros
-d --> colocas la base de datos a respaldar
-s --> Respalda solo la extructura de la tabla solo guarda el CREATE
-t --> colocas sólo las tablas que quieres respaldar
```
**`Restaurar`**
```
# Esto lo que hace es que no genera un archivo descomprimido del archivo bck_banco.sql si no que lo va ingresando directamente a la base de datos

psql -d Banco -f /tmp/bck_banco_truc.sql
```



### Ejemplo #6:  
Respaldar  solo la informacion las tabla Clientes de la base de datos  Banco
```
pg_dump -d Banco -a -f /tmp/bck_banco.sql 

#Descripción de los parámetros
-d --> colocas la base de datos a respaldar
-a --> sólo respalda la información de las tablas 
```
**`Restaurar`**
```
psql -d Banco -f /tmp/bck_banco.sql
```



### Ejemplo #7:  
Respaldar  solo la informacion las tabla Clientes de la base de datos  Banco pero para pasarlo a una tabla que ya existe pero en un servidor sql server 

```
pg_dump -d Banco -a --inserts -t Clientes -f /tmp/bck_banco.sql 

#Descripción de los parámetros
-d --> colocas la base de datos a respaldar
-a --> sólo respalda la información de las tablas
--inserts  --> esto remplaza el copy y coloca  insert
```
**`Restaurar`**
```
se copia la información y se pasa en texto plano al sql server 
```





### pg_dump --help
Sólo respaldas una base de datos 
```
$ pg_dump --help
pg_dump dumps a database as a text file or to other formats.

Usage:
  pg_dump [OPTION]... [DBNAME]

[General options:]
  -f, --file=FILENAME         Especificar la ruta y el nombre del archivo como se llamara el respaldo 
  -F, --format=c|d|t|p        Especificas un formato como:  (custom 	= Para Restaurar este formato se usa pg_restore
                                                             directory	= Para Restaurar este formato se usa pg_restore
                                                             tar	= Para Restaurar este formato se usa psql
                                                             plain text	= Para Restaurar este formato se usa psql )
  -v, --verbose               Con esta opción al realizar el respaldo te muestra en la terminal, todo el detallado de lo que va haciendo el pg_dump 
  -Z, --compress=0-9          colocas el nivel de compresion y se comprime en Gzip, solo para formatos custo y texto plano
  

[Options controlling the output content:]
  -a, --data-only             Solo respalda la informacion de las tablas
  -s, --schema-only           Solo respalda los CREATE de los objetos, esto quiere decir que no tiene información por ejemplo las tablas 

  -b, --blobs                 include large objects in dump
  -c, --clean                 Agrega el drop de los objetos: [Tablas,dba,funciones,etc]  en el respaldo, para que cuando se restaure,  se borre y se creé el nuevo objeto
      --if-exists             Esta opción agrega en el respaldo "IF EXISTS" y se puede usar cuando se agrega la opcion -c valida si existe el objeti y si existe lo borra si no existe no lo borra  
   -C, --create                Agrega el CREATE de la base de datos
      
  
  -E, --encoding=ENCODING     Agrega el Ecnoding al comprimir como  'UTF8' , 'windows-1251' o LATIN1 
  -n, --schema=SCHEMA         Especificas sólo el esquema que quieres respaldar , esto en caso de que existan varios esquemas en la base de datos
  -N, --exclude-schema=SCHEMA Excluye el eschema que no quieres respaldar

  -t, --table=TABLE           dump the named table(s) only
  -T, --exclude-table=TABLE   do NOT dump the named table(s)
  

  -x, --no-privileges         No agrega los (grant/revoke)
  -O, --no-owner              No agrega los owner en los objetos
      --no-comments 	      No agrega los comentarios de los objetos 

[En caso de restaurar en otra dba por ejemplo SQL server]
   --column-inserts            Esta opcion remplaza el copy por el insert y agrega el nombre de las columnas generando que pese mas el respaldo 
    --inserts                 Esta opcion remplaza el copy por el inser pero no agrega el nombre de las columnas 


[Connection options:]
  -h, --host=HOSTNAME      database server host or socket directory
  -p, --port=PORT          database server port number
  -U, --username=NAME      connect as specified database user
  -w, --no-password        never prompt for password
  -W, --password           force password prompt (should happen automatically)
  -d database
  --role=ROLENAME          do SET ROLE before dump


[casi no se usan]
  --lock-wait-timeout=TIMEOUT fail after waiting TIMEOUT for a table lock
  --version                   Solo muestra la version de pg_dump
  -S, --superuser=NAME        superuser user name to use in plain-text format  
  -o, --oids                  include OIDs in dump
  --binary-upgrade            for use by upgrade utilities only
  --disable-dollar-quoting    disable dollar quoting, use SQL standard quoting
  --disable-triggers          disable triggers during data-only restore
  --no-security-labels        do not dump security label assignments
  --no-tablespaces            do not dump tablespace assignments
  --no-unlogged-table-data    do not dump unlogged table data
  --quote-all-identifiers     quote all identifiers, even if not key words
  --serializable-deferrable   wait until the dump can run without anomalies
  --use-set-session-authorization
                              use SET SESSION AUTHORIZATION commands instead of
                              ALTER OWNER commands to set ownership
```



### pg_dumpall --help
Respaldas todas las base de datos / Cluster

```
pg_dumpall --help
pg_dumpall extracts a PostgreSQL database cluster into an SQL script file.

Usage:
  pg_dumpall [OPTION]...

General options:
  -f, --file=FILENAME          output file name
  -v, --verbose                verbose mode
  -V, --version                output version information, then exit
  --lock-wait-timeout=TIMEOUT  fail after waiting TIMEOUT for a table lock
  -?, --help                   show this help, then exit

Options controlling the output content:
  -a, --data-only              dump only the data, not the schema
  -c, --clean                  clean (drop) databases before recreating
  -E, --encoding=ENCODING      dump the data in encoding ENCODING
  -g, --globals-only           dump only global objects, no databases
  -O, --no-owner               skip restoration of object ownership
  -r, --roles-only             dump only roles, no databases or tablespaces
  -s, --schema-only            dump only the schema, no data, saca todos las funciones y types 
  -S, --superuser=NAME         superuser user name to use in the dump
  -t, --tablespaces-only       dump only tablespaces, no databases or roles
  -x, --no-privileges          do not dump privileges (grant/revoke)
  --binary-upgrade             for use by upgrade utilities only
  --column-inserts             dump data as INSERT commands with column names
  --disable-dollar-quoting     disable dollar quoting, use SQL standard quoting
  --disable-triggers           disable triggers during data-only restore
  --exclude-database=PATTERN   exclude databases whose name matches PATTERN
  --extra-float-digits=NUM     override default setting for extra_float_digits
  --if-exists                  use IF EXISTS when dropping objects
  --inserts                    dump data as INSERT commands, rather than COPY
  --load-via-partition-root    load partitions via the root table
  --no-comments                do not dump comments
  --no-publications            do not dump publications
  --no-role-passwords          do not dump passwords for roles
  --no-security-labels         do not dump security label assignments
  --no-subscriptions           do not dump subscriptions
  --no-sync                    do not wait for changes to be written safely to disk
  --no-tablespaces             do not dump tablespace assignments
  --no-unlogged-table-data     do not dump unlogged table data
  --on-conflict-do-nothing     add ON CONFLICT DO NOTHING to INSERT commands
  --quote-all-identifiers      quote all identifiers, even if not key words
  --rows-per-insert=NROWS      number of rows per INSERT; implies --inserts
  --use-set-session-authorization
                               use SET SESSION AUTHORIZATION commands instead of
                               ALTER OWNER commands to set ownership

Connection options:
  -d, --dbname=CONNSTR     connect using connection string
  -h, --host=HOSTNAME      database server host or socket directory
  -l, --database=DBNAME    alternative default database
  -p, --port=PORT          database server port number
  -U, --username=NAME      connect as specified database user
  -w, --no-password        never prompt for password
  -W, --password           force password prompt (should happen automatically)
  --role=ROLENAME          do SET ROLE before dump

```




### pg_restore --help
Puedes especificar que quieres restaurar
```
pg_restore restores a PostgreSQL database from an archive created by pg_dump.

Usage:
  pg_restore [OPTION]... [FILE]

General options:
  -d, --dbname=NAME        connect to database name
  -f, --file=FILENAME      output file name (- for stdout)
  -F, --format=c|d|t       backup file format (should be automatic)
  -l, --list               print summarized TOC of the archive
  -v, --verbose            verbose mode
  -V, --version            output version information, then exit
  -?, --help               show this help, then exit

Options controlling the restore:
  -a, --data-only              restore only the data, no schema
  -c, --clean                  clean (drop) database objects before recreating
  -C, --create                 create the target database
  -e, --exit-on-error          exit on error, default is to continue
  -I, --index=NAME             restore named index
  -j, --jobs=NUM               use this many parallel jobs to restore
  -L, --use-list=FILENAME      use table of contents from this file for
                               selecting/ordering output
  -n, --schema=NAME            restore only objects in this schema
  -N, --exclude-schema=NAME    do not restore objects in this schema
  -O, --no-owner               skip restoration of object ownership
  -P, --function=NAME(args)    restore named function
  -s, --schema-only            restore only the schema, no data
  -S, --superuser=NAME         superuser user name to use for disabling triggers
  -t, --table=NAME             restore named relation (table, view, etc.)
  -T, --trigger=NAME           restore named trigger
  -x, --no-privileges          skip restoration of access privileges (grant/revoke)
  -1, --single-transaction     restore as a single transaction
  --disable-triggers           disable triggers during data-only restore
  --enable-row-security        enable row security
  --if-exists                  use IF EXISTS when dropping objects
  --no-comments                do not restore comments
  --no-data-for-failed-tables  do not restore data of tables that could not be
                               created
  --no-publications            do not restore publications
  --no-security-labels         do not restore security labels
  --no-subscriptions           do not restore subscriptions
  --no-tablespaces             do not restore tablespace assignments
  --section=SECTION            restore named section (pre-data, data, or post-data)
  --strict-names               require table and/or schema include patterns to
                               match at least one entity each
  --use-set-session-authorization
                               use SET SESSION AUTHORIZATION commands instead of
                               ALTER OWNER commands to set ownership

Connection options:
  -h, --host=HOSTNAME      database server host or socket directory
  -p, --port=PORT          database server port number
  -U, --username=NAME      connect as specified database user
  -w, --no-password        never prompt for password
  -W, --password           force password prompt (should happen automatically)
  --role=ROLENAME          do SET ROLE before restore

```


### COPY
**`Copiar tabla`**
```
COPY (select * from clientes where nombre = 'manuel') TO '/tmp/tabla_clientes.csv' WITH (FORMAT CSV);
```

**`Restaurar tabla`**
```
COPY clientes FROM /tmp/tabla_clientes.csv' WITH (FORMAT CSV);
```

**`Parametros para usar despues del WITH`**
```
    1. FORMAT: Define el formato de los datos que estás copiando. Los valores más comunes son "CSV" (valores separados por comas), "TEXT" (texto sin formato) y "BINARY" (formato binario PostgreSQL).
       Ejemplo:
       COPY mi_tabla FROM 'archivo.csv' WITH (FORMAT CSV);

    2. DELIMITER: Especifica el carácter utilizado como delimitador en un archivo CSV.
       Ejemplo:

       COPY mi_tabla FROM 'archivo.csv' WITH (DELIMITER ',');

    3. NULL: Indica cómo manejar los valores nulos en el archivo. Puedes usar palabras clave como "NULL" o "NONE".
       Ejemplo:
     
       COPY mi_tabla FROM 'archivo.csv' WITH (NULL 'NA');

    4. HEADER: Indica si la primera línea del archivo contiene nombres de columnas.
	Ejemplo:

       COPY mi_tabla FROM 'archivo.csv' WITH (FORMAT CSV, HEADER true);

    5. ENCODE: Especifica la codificación de caracteres utilizada en el archivo, se puede usar 'windows-1251' y 'latin1' o 'UTF8'
       Ejemplo:

       COPY mi_tabla FROM 'archivo.csv' WITH (ENCODE 'UTF8');

    6. FORCE_QUOTE: Obliga a poner comillas alrededor de los valores, incluso si no es necesario.
       Ejemplo:

       COPY mi_tabla FROM 'archivo.csv' WITH (FORMAT CSV, FORCE_QUOTE column_name);

    7. ESCAPE: Define el carácter de escape utilizado en el archivo.
       Ejemplo:

       COPY mi_tabla FROM 'archivo.csv' WITH (FORMAT CSV, ESCAPE '\');

    8. PROGRAM: Permite ejecutar un programa externo para generar o procesar los datos antes de copiarlos.
       Ejemplo:

       COPY mi_tabla FROM PROGRAM 'cat archivo.csv' WITH (FORMAT CSV);

```



# Futuros temas 
pg_basebackup y pg_waldump 


