
![back](https://img.freepik.com/premium-vector/vector-icon-backup-restore-cloud-web-app_901408-682.jpg)

- Comando --Help
	- [Pg_dump](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Respaldo%20y%20Restauraci%C3%B3n.md#pg_dump---help)
	- [Pg_dumpall](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Respaldo%20y%20Restauraci%C3%B3n.md#pg_dumpall---help)
	- [pg_restore](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Respaldo%20y%20Restauraci%C3%B3n.md#pg_restore---help)
 	- [Copy](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Respaldo%20y%20Restauraci%C3%B3n.md#copy)
  	- [como hacer un RollBack en la base de datos](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Respaldo%20y%20Restauraci%C3%B3n.md#como-hacer-un-rollback-en-la-base-de-datos) 

   
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
que realiza un respaldo lógico generando consultas SQL
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


## trucos 
```
....................... Calcular cuanto se va comprimir  con gzip................
Los respaldos de las base de datos cuando se comprimen con gzip, se comprimen un 12% , ejemplo
si pesa la db 150GB el archivo compreso va pesar 18GB


....................... Calcular cuanto va tardar un archivo en comprimir ................
ejemplo 150GB pesa la base de datos entonces hacemos el calculo 2.666666666666667 * 150 / 100 = 4 hrs
esto dependera de los recursos del servidor, esto se puede calcular respaldando por ejemplo 1GB y ver cuanto tardo
 y hacer una regla de 3

.......................... dividir archivos ...........................
split -b 5G /sysx/respalddi.sql.gz

--- 
Podemos indicar que en vez de una letra añada un número con el comando:
split -b -d 100m prueba.log salida

En lugar de especificar el tamaño de cada parte, podemos especificar el número de partes en las que queremos dividir el archivo. Por ejemplo, para dividir en cinco partes, el comando sería:
split -d -n 2 back_merca360.gz back_merca360_partes

--- restaurar
cat salida_* > prueba.log



zcat -f /sysx/respalddi.sql.gz | grep complete    # esto lee todos los archivos que estan dentro del  compreso



..........

Para comprimir .gz, debemos utilizar:
gzip -q archivo
209.8 - cartera en linea 

-- descomprimir  gzip
gzip -d archivo.gz


-------------- respaldar en segundo plano,  por si se cierrra la terminal  -------------------
nohup pg_dump -d mi_dba_test | gzip -c9 > mi_dba_test.sql.gz &

```

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

<br> Puedes validar la documentacion oficial para validar todos los tipos de encoding 
[24.3.4. Available Character Set Conversion](https://www.postgresql.org/files/documentation/pdf/15/postgresql-15-A4.pdf)
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


### Ejemplo #8:  
Copiar la información de una tabla cliente, pero sólo los que se llamen manuel

**`Copiar tabla`**
```
psql -d banco -p5432 
COPY (select * from clientes where nombre = 'manuel') TO '/tmp/tabla_clientes.csv' WITH (FORMAT CSV);
```

**`Restaurar tabla`**
```
psql -d banco -p5432 
COPY clientes FROM /tmp/tabla_clientes.csv' WITH (FORMAT CSV);
```

### Ejemplo #9:  
Copiar la información de la tabla cliente, pero sólo los que se llamen manuel y sólo guarda los campos nombre y apellido, pero sin usar la función Copy, ni la herramienta pg_dump

**`Copiar tabla`**
`#[NOTA]` en este ejemplo si un campo de la tabla Cliente tiene tipo Varchar o datetime, entonces tiene que escribir el campo y colocarle las comillas simples con CHR(39), si los campos de la tabla son numero entonces no necesita comillas

```
 psql -d banco -c "select 'insert into clientes select ', CHR(39) || nombre || CHR(39) , CHR(39) ||  apellido ||  CHR(39)  from clientes where nombre = 'manuel'" -p5432  --csv --tuples-only --output /tmp/tb_clientes.csv --log-file /tmp/log_test.txt &&  sed -i 's/select ,/select /g' /tmp/tb_clientes.csv
```

**`Restaurar tabla`**
```
psql -d banco -p5432 -f /tmp/tb_clientes.csv
```

---

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

# como hacer un RollBack en la base de datos
**`[NOTA]`** Cada sesión puede tener su propia transacción independiente. Por lo tanto, si ejecutas un BEGIN en una sesión y no lo cierras, solo afectará a esa sesión específica. Otras sesiones no se verán afectadas por la transacción no cerrada en la primera sesión. <br><br>



El **begin** Permite que las transacciones/operaciones sean aisladas y transparentes unas de otras, esto quiere decir que si una sesion nueva se abre, no va detectar los cambios realizados en el cuando se incia el begin como son los insert,update,delete etc, 
 ```
BEGIN TRANSACTION;
 ```
El **commit**  se usa para guardar los cambios que se realizaron, como los insert,detelete, etc y estas seguro de que todo salio bien
 ```
COMMIT:
 ```
el **rollback** se usa en caso de que algo salio mal  y no quieres que se guarden los cambios entonces puedes hacer los rollback completo o un un rollback punto de guardado
 ```
rollback;
rollback my_name_savepoint;
 ```

el **savepoint** sirve para hacer un punto de guardado, en caso de realizar varios cambios en un begin 
 ```
savepoint my_name_savepoint;
 ```


# Info Extra

 # Alternativa del COPY
 ```
 psql -d my_dba_test -c "select 'insert into cat_usuarios select ',* from clientes" -p6432  --csv --tuples-only --output /tmp/tb_clientes.csv --log-file /tmp/log_test.txt &&  sed -i 's/select ,/select /g' /tmp/tb_clientes.csv
 ```


 # Hacer copy  stdin

 ```
 1)- Obtener las columnas 
 psql -d my_dba -t -c "select column_name || ',' from information_schema.columns where table_name=  'my_tabla' order by ordinal_position" |    tr -d ' ' | | sed 's/.$// 
 

2)- Meter las columnas y hacer el archivo copy.sql
echo "COPY my_tabla ( columna1,columna2,columan3 ) FROM stdin;" > copy.sql


3)- Obtener la data 
COPY my_tabla  TO '/tmp/data.csv' WITH CSV  DELIMITER '|';


4)-limpiamos la data , quitando los tabuladores extras
tr "\t" "" < data.sql > data_clean.sql


5)- remplazamos los caracteres "|" por tabuladores 
  tr "|" "\t" < data_clean.sql > data.sql

6)- combinamos el copy + data + \. 
 cat data.sql  >> copy.sql && echo "\." >> copy.sql


7)- saber la codicacion del archivo
file -i copy.sql

8)- convertir a utf8  
iconv -f iso-8859-1 -t UTF-8 copy.sql -o copy_clean.sql

9)- Restarurar el en el servidor destino 
 psql -d my_dba  -p5434 -f copy_clean.sql
 ```


# hacer un Copy en psql 8.1.23
En estas versiones de copy no permite realizar el copiado de un select con condicion por lo que se necesita hacer una tabla temporal y despues realizar el copy
 ```
CREATE TEMPORARY TABLE mitmp2 AS  select  * from my_tabla where nombre = 'luis';

 COPY mitmp2 TO '/tmp/registros_tb_mitmp2.csv' WITH CSV;
 ```

--- ejemplos de copy
 ```
COPY bringas TO STDOUT (DELIMITER '&');

COPY country TO PROGRAM 'gzip > /usr1/proj/bray/sql/country_data.gz';

COPY my_tabla  TO PROGRAM 'rm /tmp/list.txt && echo "aaa" > /tmp/lista.txt' WITH CSV DELIMITER ',' ;
 ```


# copiar la información de una tabla en un archivo 

Esto lo que hace es que ingresara el contenido de la tabla pg_shadow en el archivo test2323s.txt, si el archivo no existe lo crea 
 ```
postgres=# \o /tmp/test2323s.txt
postgres=# select * from pg_shadow;
postgres=# \o

--- consultar la informacion del archivo
postgres=#\! /tmp/test2323s.txt
 ```

\! /tmp/test2323s.txt



# Futuros temas 
pg_basebackup y pg_waldump 
<br>
--- Ver la información de los wal 
pg_waldump  /pg_wal/000000010000006600000003


 ```
******* habilitar los wal ******* 
https://it-inzhener.com/en/articles/detail/postgresql-enable-archive-mode
https://www.opsdash.com/blog/postgresql-wal-archiving-backup.html
 ```

# pg_basebackup

pg_basebackup proporciona una copia física de todos los datos y archivos necesarios para restaurar una instancia de PostgreSQL. Esta copia incluye la carpeta de datos y los archivos WAL, lo que permite una restauración completa y coherente de la base de datos en caso de necesidad. En comparación con pg_dump, que crea un script SQL para recrear la base de datos, pg_basebackup es más rápido y es especialmente útil para grandes conjuntos de datos, ya que no involucra la generación de consultas SQL.
 ```
pg_basebackup -U tu_usuario -D /ruta/del/destino -F t -Xs -P -v


-U tu_usuario: Aquí pones tu nombre de usuario de PostgreSQL.
-D /ruta/del/destino: Esto es donde quieres guardar la copia de seguridad. Puedes elegir una carpeta en tu computadora.
-F t: Le dice a pg_basebackup que use el formato de archivo TAR, que es como un contenedor para tus datos.
-Xs: Hace que pg_basebackup haga un respaldo en caliente, lo que significa que puedes seguir usando tu base de datos mientras se está haciendo la copia de seguridad.
-P: Muestra el progreso mientras se realiza la copia de seguridad.
-v: Activa el modo detallado, así verás exactamente lo que está haciendo pg_basebackup.

 ```
