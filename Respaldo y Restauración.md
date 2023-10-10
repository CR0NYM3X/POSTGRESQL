
![back](https://img.freepik.com/premium-vector/vector-icon-backup-restore-cloud-web-app_901408-682.jpg)

- Comando --Help
	- [Pg_dump]()
	- [Pg_dumpall]()
	- [pg_restore]()

   
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


# Ejemplos de uso:
**`[Nota]`** = Al usar `pg_dump` en automatico te genera el create de los objetos almenos que tu especifiques que no ocupas el create


**Descripción de Servidores para ejemplos**
```
Servidor: 10.44.1.55 | Postgresql 
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
```





### Ejemplo #1:  
Respaldar toda la base de datos "Banco", junto con su usuarios, que que solo respalde las tablas del schema sch_tienda y no respalde las tablas del schema sch_tienda_respaldo100 y que use el encoding "UTF8" 


### Ejemplo #2:  
Generar un respaldo que contenga solo los CREATE de los objetos de la base de datos "Banco", las tablas deben de estar vacias 

### Ejemplo #3:  
Respaldar toda la base de datos "Banco", excepto la tabla Ciudades y Estados, también comprimir el archivo para que pese menos


### Ejemplo #4: 
Respaldar  la Estructura y Información de la tabla Clientes de la base de datos  Banco, y que en el archivo tenga el create de la base de datos, la tabla y que al restaurar borre la tabla si ya existe y inserte la información nueva 

### Ejemplo #5:  
Respaldar  solo la Estructura de  las tabla Clientes de la base de datos  Banco
### Ejemplo #6:  
Respaldar  solo la informacion las tabla Clientes de la base de datos  Banco

### Ejemplo #7:  
Respaldar  solo la informacion las tabla Clientes de la base de datos  Banco pero para pasarlo a una tabla que ya existe pero en un servidor sql server 







### pg_dump --help
```
$ pg_dump --help
pg_dump dumps a database as a text file or to other formats.

Usage:
  pg_dump [OPTION]... [DBNAME]

General options:
  -f, --file=FILENAME         output file or directory name
  -F, --format=c|d|t|p        output file format (custom, directory, tar, plain text)
  -v, --verbose               verbose mode
  -Z, --compress=0-9          compression level for compressed formats
  --lock-wait-timeout=TIMEOUT fail after waiting TIMEOUT for a table lock
  --help                      show this help, then exit
  --version                   output version information, then exit

Options controlling the output content:
  -a, --data-only             dump only the data, not the schema
  -b, --blobs                 include large objects in dump
  -c, --clean                 clean (drop) database objects before recreating
  -C, --create                include commands to create database in dump
  
  -E, --encoding=ENCODING     dump the data in encoding ENCODING
  -n, --schema=SCHEMA         dump the named schema(s) only
  -N, --exclude-schema=SCHEMA do NOT dump the named schema(s)
  
  -o, --oids                  include OIDs in dump
  -O, --no-owner              skip restoration of object ownership in
                              plain-text format
  
  -s, --schema-only           dump only the schema, no data
  -S, --superuser=NAME        superuser user name to use in plain-text format
  
  
  -t, --table=TABLE           dump the named table(s) only
  -T, --exclude-table=TABLE   do NOT dump the named table(s)
  
  
  -x, --no-privileges         do not dump privileges (grant/revoke)
  --binary-upgrade            for use by upgrade utilities only
  --column-inserts            dump data as INSERT commands with column names
  --disable-dollar-quoting    disable dollar quoting, use SQL standard quoting
  --disable-triggers          disable triggers during data-only restore
  --inserts                   dump data as INSERT commands, rather than COPY
  --no-security-labels        do not dump security label assignments
  --no-tablespaces            do not dump tablespace assignments
  --no-unlogged-table-data    do not dump unlogged table data
  --quote-all-identifiers     quote all identifiers, even if not key words
  --serializable-deferrable   wait until the dump can run without anomalies
  --use-set-session-authorization
                              use SET SESSION AUTHORIZATION commands instead of
                              ALTER OWNER commands to set ownership

Connection options:
  -h, --host=HOSTNAME      database server host or socket directory
  -p, --port=PORT          database server port number
  -U, --username=NAME      connect as specified database user
  -w, --no-password        never prompt for password
  -W, --password           force password prompt (should happen automatically)
  -d database
  --role=ROLENAME          do SET ROLE before dump
```



### pg_dumpall --help
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






