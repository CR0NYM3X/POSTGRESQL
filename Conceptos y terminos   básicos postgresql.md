## Terminos 
```
1. **SQL**: Structured Query Language (Lenguaje de Consulta Estructurado).
 Es el lenguaje estándar utilizado para interactuar con bases de datos relacionales.

2. **ETL**: Extract, Transform, Load (Extraer, Transformar, Cargar).
Es un proceso utilizado para mover datos desde fuentes externas a una base de datos y
transformarlos en un formato adecuado para su análisis.
```

## que es  ODBC (Open databse connectivity 
```
Es un estándar que permite a las aplicaciones acceder y manipular datos almacenados en diferentes
tipos de bases de datos a través de un conjunto común de interfaces. Algunas de las funciones y propósitos principales de ODBC son:

1. **Interoperabilidad:** ODBC proporciona una interfaz estándar que permite a las
 aplicaciones comunicarse con una amplia variedad de bases de datos, independientemente del proveedor de la base de datos o del sistema operativo utilizado.

2. **Acceso a datos:** ODBC permite a las aplicaciones realizar consultas, insertar,
actualizar y eliminar datos en bases de datos externas de manera uniforme, sin necesidad de conocer los detalles específicos de cada base de datos subyacente.

3. **Flexibilidad:** ODBC permite a las aplicaciones cambiar fácilmente entre diferentes
 bases de datos sin necesidad de modificar el código de la aplicación. Esto facilita la
migración de datos entre diferentes sistemas de bases de datos o la integración de múltiples sistemas de bases de datos en una aplicación.

4. **Desarrollo de aplicaciones multiplataforma:** ODBC es compatible con múltiples
sistemas operativos, lo que permite el desarrollo de aplicaciones que pueden ejecutarse
en diferentes plataformas y acceder a bases de datos de manera consistente.

```

 # sistema gestor de base de datos o SGBD (del inglés: Relational  Data Base Management System o DBMS o RDBMS) 

```
 es un software que permite administrar una base de datos. Proporciona el método de
 organización necesario para el almacenamiento y recuperación flexible de grandes cantidades de datos
```

### Diferencia de DDL Y DML 
**Lenguaje de Definición de Datos (DDL):**

`Propósito:` El DDL se utiliza para definir la estructura y las características de la base de datos. <br>
`Operaciones típicas:` Crear, modificar y eliminar objetos de la base de datos, como tablas, índices, vistas, esquemas, etc. <br>
`Ejemplos de sentencias DDL:` CREATE TABLE, ALTER TABLE, DROP TABLE, CREATE INDEX, CREATE VIEW, etc. <br>
`Efecto en los datos:` Las sentencias DDL no afectan directamente a los datos almacenados en la base de datos, sino a la estructura y definición de cómo se almacenan y organizan esos datos.


**Lenguaje de Manipulación de Datos (DML):** <br>
`Propósito:` El DML se utiliza para manipular y trabajar con los datos almacenados en la base de datos. <br>
`Operaciones típicas:` Insertar, recuperar, actualizar y eliminar datos dentro de las tablas de la base de datos. <br>
`Ejemplos de sentencias DML:` SELECT, INSERT, UPDATE, DELETE, etc. <br>
`Efecto en los datos:` Las sentencias DML sí afectan directamente a los datos almacenados en la base de datos, cambiando su contenido, añadiendo nuevos datos o eliminando datos existentes.

**Lenguaje de Control de Datos (DCL)**
Estos comandos permiten al Administrador del sistema gestor de base de datos, controlar el acceso a los objetos<br>
GRANT, permite otorgar permisos.<br>
REVOKE, elimina los permisos que previamente se han concedido.


# Descripción Rápida:
Aqui aprenderemos a como realizar una conexion con la base de datos 

# Ejemplos de uso:

# ver los comanetarios de los objetos
```
SELECT * FROM pg_description;
```

# Ver rutas de postgresql 
```
SHOW password_encryption;
SHOW config_file;
SHOW hba_file;
SHOW data_directory;

SELECT * FROM pg_stat_file(current_setting('data_directory') || '/global/pg_control');

```

#Explicacion de esto:
```
  psql (15.3, server 12.15)
  psql ([es la version de Binarios del psql que estas ejecutando ], server [versión de data])
```

### Conectarse  a la base de datos 
```
 psql -d my_dba_test  -h 10.44.1.155 -p 5432 -U postgres

 psql "dbname=my_dba_test host=10.44.1.155 user=postgres sslmode=disable"
```

### ejecutar querys en la base de datos
```
PGPASSWORD=micontraseña psql -p5433 -h 127.0.0.1 -d aplicativo_test -U postgres <<EOF
select now();
select version();
EOF
```

### Guardar los resultados de una consulta en un csv 
```
 psql -d my_dba_test  -h 10.44.1.155 -p 5432 -U postgres -c "select * from clientes"  --csv -o /tmp/data_clientes.csv
```

### Ejecutar un script en la base de datos 
```
 psql -d my_dba_test  -h 10.44.1.155 -p 5432 -U postgres -f /tmp/my_script.sql
```

### Detener el servicio forzosamete 
```
/usr/pqsql-12/bin/pg_ctl stop -D /sysd/data/ -mf
```

### Iniciar el servicio  
```
/usr/pgsql-14/bin/pg_ctl start -D /sysx/data -o -i
postgres -D /ruta/nueva/DATA -c config_file=/ruta/nueva/postgresql.conf 

postgres -D  /sysx/data
postmaster -D /sysx/data

sudo systemctl start postgresql


pg_ctl:   Se utiliza para iniciar, detener, reiniciar, o verificar el estado del servidor PostgreSQL de manera controlada.
postgres y postmaster : solo se utiliza típicamente para iniciar el servidor
```

### Recargar las configuraciones pg_hba.conf
```
/usr/pqsql-12/bin/pg_ctl reload -D /sysd/data/

/usr/pgsql-15/bin/pg_ctl reload -D /sysd/data -o "-c config_file='/sysd/data/postgresql.conf'"

SELECT pg_reload_conf();
```

### reinicia el servicio | esto tambien sirve para cuando se modifica algo del postgresql.conf
```
/usr/pqsql-12/bin/pg_ctl -o "-F -p 5433" restart

#Opciones
-F: Esta opción indica que el servidor PostgreSQL debe forzar la recuperación
del sistema de archivos en caso de un cierre inesperado
```



### Formas de saber si el postgresql esta corriendo en linux 
```
pg_ctl status
systemctl status postgresql
service postgresql status
pg_isready 
ps aux 
grep postgres 
```



### Base de datos y esquemas del sistema

--- Base de datos: <br>
**`postgres:`** Esta es la base de datos principal del sistema. Contiene información sobre todos los demás objetos de la base de datos, como tablas, esquemas y usuarios. No es recomendable almacenar datos de aplicaciones en esta base de datos, pero se utiliza para administrar el entorno de PostgreSQL.

**`template0 y template1:`** Estas bases de datos son plantillas para crear nuevas bases de datos. template0 es una plantilla de solo lectura que no debería modificarse, mientras que template1 es una plantilla que puedes modificar para crear nuevas bases de datos con una estructura específica. Cuando creas una nueva base de datos en PostgreSQL, se clona a partir de template1 por defecto.

--- Esquemas: <br>
**`information_schema:`** Esta base de datos contiene vistas que proporcionan información sobre la estructura de las bases de datos y sus objetos. Es útil para realizar consultas y obtener información sobre tablas, columnas, restricciones, índices, etc.

**`pg_catalog:`** Almacena información sobre el catálogo del sistema de PostgreSQL. Contiene tablas y vistas que son esenciales para el funcionamiento interno de PostgreSQL. No se recomienda realizar modificaciones directas en esta base de datos.



# psql --help
```
 psql --help
psql is the PostgreSQL interactive terminal.

Usage:
  psql [OPTION]... [DBNAME [USERNAME]]

General options:
  -c, --command=COMMAND    run only single command (SQL or internal) and exit
  -d, --dbname=DBNAME      database name to connect to (default: "postgres")
  -f, --file=FILENAME      execute commands from file, then exit
  -l, --list               list available databases, then exit
  -v, --set=, --variable=NAME=VALUE
                           set psql variable NAME to VALUE
                           (e.g., -v ON_ERROR_STOP=1)
  -V, --version            output version information, then exit
  -X, --no-psqlrc          do not read startup file (~/.psqlrc)
  -1 ("one"), --single-transaction
                           execute as a single transaction (if non-interactive)
  -?, --help[=options]     show this help, then exit
      --help=commands      list backslash commands, then exit
      --help=variables     list special variables, then exit

Input and output options:
  -a, --echo-all           echo all input from script
  -b, --echo-errors        echo failed commands
  -e, --echo-queries       echo commands sent to server
  -E, --echo-hidden        display queries that internal commands generate
  -L, --log-file=FILENAME  send session log to file
  -n, --no-readline        disable enhanced command line editing (readline)
  -o, --output=FILENAME    send query results to file (or |pipe)
  -q, --quiet              run quietly (no messages, only query output)
  -s, --single-step        single-step mode (confirm each query)
  -S, --single-line        single-line mode (end of line terminates SQL command)

Output format options:
  -A, --no-align           unaligned table output mode
      --csv                CSV (Comma-Separated Values) table output mode
  -F, --field-separator=STRING
                           field separator for unaligned output (default: "|")
  -H, --html               HTML table output mode
  -P, --pset=VAR[=ARG]     set printing option VAR to ARG (see \pset command)
  -R, --record-separator=STRING
                           record separator for unaligned output (default: newline)
  -t, --tuples-only        print rows only
  -T, --table-attr=TEXT    set HTML table tag attributes (e.g., width, border)
  -x, --expanded           turn on expanded table output
  -z, --field-separator-zero
                           set field separator for unaligned output to zero byte
  -0, --record-separator-zero
                           set record separator for unaligned output to zero byte

Connection options:
  -h, --host=HOSTNAME      database server host or socket directory (default: "local socket")
  -p, --port=PORT          database server port (default: "5432")
  -U, --username=USERNAME  database user name (default: "postgres")
  -w, --no-password        never prompt for password
  -W, --password           force password prompt (should happen automatically)

```
