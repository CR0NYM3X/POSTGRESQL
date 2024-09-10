 


### Archivos de configuración 
```sql
\du [usuarios]
\l+ --> base de datos | SELECT * FROM pg_database limit 10;
\c -- conectarse a la bse de datos 
\dt Tablas --- SELECT * FROM pg_tables limit 10; --  SELECT * FROM information_schema.tables WHERE table_schema='public'  ;
\du [nombre usuario] --- saber si existe un usuario 

\d nombre_tabla -> Describir una tabla específica para ver sus columnas y tipos de datos
\di nombre_tabla -> Mostrar información sobre los índices en una tabla:
\dv -> Mostrar información sobre las vistas en la base de datos actual:
\df -> Mostrar información sobre las funciones almacenadas en la base de datos actual:
\dn -> Mostrar información sobre los esquemas en la base de datos actual:

select * from information_schema.sql_sizing; -- indica los tamaños maximos permitidos como columna y cantidad de caracteres 
```

### Archivos de configuración 
```sql
select pg_reload_conf(); -- con esto puede reiniciar el archivo de configuración
select pg_conf_load_time() ; devuelve la última vez que se cargó el archivo de configuración del servidor (con información de zona horaria).
```


#ejecutar varias cosas con psql
```sql 
PGPASSWORD="$password" psql -h "$host" -U "$user" -d "$database" <<EOF
-- Consulta 1
SELECT 1;

-- Consulta 2
SELECT 2;

-- Puedes agregar más consultas aquí
EOF
```

## configurar parametros a nivel usuario : 
esto sirve cuando solo quieres que los parametros se configuren a nivel usuario , puedes modificar algunos parametros postgresql.conf 
```sql 
Ejemplo 
SET log_statement= 'none';
set TimeZone = 'America/Mexico_City' ;

show log_statement;
show TimeZone;

select now();
```

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
psql "port=5416 dbname=postgres user=user_central host=127.0.0.1  password=123123"
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

### Postgressql.conf y Postgressql.auto.conf
```
postgresql.conf es el archivo principal de configuración estática
que requiere reinicios del servidor para aplicar cambios, 

postgresql.auto.conf : cuando se reinicia el servicio, pone como prioridad este archivo de configuración,
aqui se guardan los parametros modificados con el ALTER SYSTEM y
permite ajustes dinámicos y persistentes sin  necesidad de reiniciar el servidor PostgreSQL.
  Se puede modificar a través de comandos SQL  

Ejemplo:
ALTER SYSTEM SET password_encryption = 'md5';

```

### Base de datos y esquemas del sistema

--- Base de datos: <br>
**`postgres:`** Esta es la base de datos principal del sistema. Contiene información sobre todos los demás objetos de la base de datos, como tablas, esquemas y usuarios. No es recomendable almacenar datos de aplicaciones en esta base de datos, pero se utiliza para administrar el entorno de PostgreSQL.

**`template0 y template1:`** Estas bases de datos son plantillas para crear nuevas bases de datos. template0 es una plantilla de solo lectura que no debería modificarse, mientras que template1 es una plantilla que puedes modificar para crear nuevas bases de datos con una estructura específica. Cuando creas una nueva base de datos en PostgreSQL, se clona a partir de template1 por defecto.

--- Esquemas: <br>
**`information_schema:`** Esta base de datos contiene vistas que proporcionan información sobre la estructura de las bases de datos y sus objetos. Es útil para realizar consultas y obtener información sobre tablas, columnas, restricciones, índices, etc.

**`pg_catalog:`** Almacena información sobre el catálogo del sistema de PostgreSQL. Contiene tablas y vistas que son esenciales para el funcionamiento interno de PostgreSQL. No se recomienda realizar modificaciones directas en esta base de datos.


**`pg_temp:`** se utiliza para almacenar tablas temporales. Cada sesión de usuario tiene su propio esquema temporal, como pg_temp_8, para asegurar que las tablas temporales sean visibles solo para esa sesión

**`pg_toast:`** Este esquema se usa para almacenar datos de tablas que son demasiado grandes para caber en una sola fila. PostgreSQL automáticamente mueve estos datos a tablas TOAST (The Oversized-Attribute Storage Technique) para manejar eficientemente grandes cantidades de datos

### ¿Cómo funciona TOAST?
PostgreSQL utiliza automáticamente la compresión para datos grandes almacenados en columnas de tipo `TEXT`, `BYTEA` y `VARCHAR` mediante el mecanismo TOAST (The Oversized-Attribute Storage Technique). Este mecanismo utiliza el algoritmo de compresión LZ4 para comprimir datos que exceden un cierto tamaño⁴.
 
1. **Compresión**: Los valores grandes se comprimen para reducir su tamaño.
2. **Almacenamiento fuera de línea**: Si la compresión no es suficiente, los valores se dividen en múltiples filas físicas y se almacenan en una tabla TOAST asociada.
3. **Transparencia**: Todo esto ocurre de manera transparente para el usuario, lo que significa que no necesitas hacer nada especial para manejar estos datos grandes; PostgreSQL se encarga de todo automáticamente¹².

### Detalles Técnicos

- **Tamaño de página fijo**: PostgreSQL utiliza un tamaño de página fijo (normalmente 8 kB), y no permite que las tuplas abarquen múltiples páginas.
- **Representación varlena**: Los tipos de datos que soportan TOAST deben tener una representación de longitud variable (varlena), donde la primera palabra de cuatro bytes de cualquier valor almacenado contiene la longitud total del valor en bytes¹².
 

### ¿Qué es el método de acceso heap?

El método de acceso **heap** es el método de almacenamiento de datos por defecto en PostgreSQL. Organiza los datos en páginas de tamaño fijo (normalmente 8 KB), donde cada página puede contener varias filas (tuplas). Este método es muy versátil y adecuado para una amplia variedad de aplicaciones.

### ¿Para qué sirve el método heap?
El método heap sirve para almacenar y gestionar los datos de las tablas en PostgreSQL. Es el método más común y se utiliza en la mayoría de las bases de datos debido a su simplicidad y eficiencia.

### ¿Qué función tiene?

- **Almacenamiento de datos**: Los datos se almacenan en páginas, y cada página puede contener múltiples filas.
- **Gestión de espacio**: Maneja el espacio libre dentro de las páginas para insertar nuevas filas y actualizar las existentes.
- **MVCC (Control de Concurrencia Multiversión)**: Permite que múltiples transacciones lean y escriban en la base de datos simultáneamente sin bloquearse entre sí.

### ¿Qué pasa si no lo uso?

Si no usas el método heap, puedes optar por otros métodos de acceso que podrían estar más optimizados para casos de uso específicos. Sin embargo, el método heap es el más general y versátil, por lo que es adecuado para la mayoría de las aplicaciones.

### ¿Cuándo debo usarlo?

Debes usar el método heap cuando:

- Necesitas un método de almacenamiento general y versátil.
- No tienes requisitos específicos que necesiten un método de acceso especializado.
- Quieres aprovechar las características de MVCC para manejar múltiples transacciones concurrentes.

### Ventajas y desventajas

**Ventajas**:
- **Simplicidad**: Fácil de entender y usar.
- **Versatilidad**: Adecuado para una amplia variedad de aplicaciones.
- **Soporte MVCC**: Permite transacciones concurrentes sin bloqueos.

**Desventajas**:
- **Fragmentación**: Puede haber fragmentación de espacio con el tiempo.
- **Rendimiento**: En algunos casos, otros métodos de acceso pueden ser más eficientes.

### Tipos de métodos de acceso en PostgreSQL

Además del método heap, PostgreSQL permite definir otros métodos de acceso a tablas. Algunos ejemplos incluyen:

1. **Columnar**: Optimizado para operaciones de lectura intensiva, como en aplicaciones OLAP.
2. **In-Memory**: Almacena datos en memoria para acceso ultrarrápido.
3. **Custom**: Los desarrolladores pueden crear sus propios métodos de acceso para necesidades específicas³.

### Diferencias entre los métodos

- **Heap**: General y versátil, adecuado para la mayoría de las aplicaciones.
- **Columnar**: Optimizado para consultas analíticas y operaciones de lectura intensiva.
- **In-Memory**: Ideal para aplicaciones que requieren acceso rápido a los datos.
 
 
### métodos de acceso
    SELECT *  FROM pg_am;

 
### ¿Qué es una página en PostgreSQL?

1. **Tamaño Fijo**: Las páginas tienen un tamaño fijo, que normalmente es de 8 kB, aunque este tamaño puede ser configurado al compilar el servidor¹.
2. **Estructura de Almacenamiento**: Cada tabla e índice en PostgreSQL se almacena como una matriz de estas páginas. Dentro de una tabla, una página contiene varias filas de datos; en un índice, contiene entradas de índice¹.
3. **Gestión de Datos**: PostgreSQL utiliza estas páginas para gestionar y organizar los datos en el disco de manera eficiente. Cada vez que se necesita leer o escribir datos, se hace en unidades de páginas completas¹.

### ¿Por qué usar páginas?

- **Eficiencia**: Trabajar con páginas de tamaño fijo permite a PostgreSQL optimizar las operaciones de lectura y escritura en disco.
- **Manejo de Datos Grandes**: Las técnicas como TOAST (The Oversized-Attribute Storage Technique) dependen de este concepto de páginas para manejar datos que no caben en una sola página¹.
 
 
  
### ¿Cómo se generan las tuplas muertas?

1. **Eliminación (DELETE)**: Cuando eliminas una fila, PostgreSQL no la borra físicamente de inmediato. En su lugar, marca la fila como eliminada, pero sigue ocupando espacio en la tabla¹.
2. **Actualización (UPDATE)**: Al actualizar una fila, PostgreSQL crea una nueva versión de la fila con los datos actualizados y marca la versión antigua como eliminada. Esto también genera una tupla muerta¹.

### ¿Por qué se hace esto?

1. **MVCC (Control de Concurrencia Multiversión)**: PostgreSQL utiliza un sistema llamado MVCC para manejar la concurrencia. Esto permite que múltiples transacciones lean y escriban en la base de datos al mismo tiempo sin bloquearse entre sí. Las tuplas muertas son esenciales para este sistema, ya que permiten que las transacciones vean versiones consistentes de los datos¹.
2. **Rendimiento**: Eliminar físicamente las filas inmediatamente podría ser costoso en términos de rendimiento, especialmente en sistemas con alta concurrencia. Al marcar las filas como eliminadas y manejarlas posteriormente con `VACUUM`, PostgreSQL puede optimizar mejor el uso de recursos¹.


### Objetivo de las tuplas muertas

El objetivo principal de las tuplas muertas es **mantener la consistencia y el rendimiento** de la base de datos. Permiten que las transacciones lean versiones consistentes de los datos sin interferir con otras operaciones y optimizan el uso de recursos al diferir la eliminación física de las filas hasta que sea más eficiente hacerlo¹.
 
### Efectos del  MVCC
 ```sql
CREATE TABLE ventas (
     id SERIAL PRIMARY KEY ,
     fecha DATE,
     cliente_id INTEGER,
     producto_id INTEGER,
     cantidad INTEGER,
     precio NUMERIC
 );
CREATE TABLE
Time: 5.745 ms


postgres@postgres#   INSERT INTO ventas ( fecha, cliente_id, producto_id, cantidad, precio)
SELECT
    NOW() - INTERVAL '1 day' * (RANDOM() * 1000)::int,
    (RANDOM() * 1000)::int,
    (RANDOM() * 100)::int,
    (RANDOM() * 10)::int,
    (RANDOM() * 100)::numeric
FROM generate_series(1, 5);
INSERT 0 20
Time: 1.959 ms


postgres@postgres# select * from ventas;
+----+------------+------------+-------------+----------+------------------+
| id |   fecha    | cliente_id | producto_id | cantidad |      precio      |
+----+------------+------------+-------------+----------+------------------+
|  1 | 2022-08-06 |        905 |          54 |        3 |  67.525051208213 |
|  2 | 2022-01-30 |         89 |          73 |        7 | 84.1188056394458 |
|  3 | 2024-04-02 |        375 |          28 |        7 | 13.6253997683525 |
|  4 | 2023-03-23 |        646 |          82 |        5 | 66.7211717925966 |
|  5 | 2022-08-12 |        744 |          68 |        7 | 91.8418753426522 |
+----+------------+------------+-------------+----------+------------------+
(5 rows)


postgres@postgres# update ventas set cliente_id = 2020 where id = 2 ;
UPDATE 1
Time: 1.115 ms
postgres@postgres# select * from ventas;
+----+------------+------------+-------------+----------+------------------+
| id |   fecha    | cliente_id | producto_id | cantidad |      precio      |
+----+------------+------------+-------------+----------+------------------+
|  1 | 2022-08-06 |        905 |          54 |        3 |  67.525051208213 |
|  3 | 2024-04-02 |        375 |          28 |        7 | 13.6253997683525 |
|  4 | 2023-03-23 |        646 |          82 |        5 | 66.7211717925966 |
|  5 | 2022-08-12 |        744 |          68 |        7 | 91.8418753426522 |
|  2 | 2022-01-30 |       2020 |          73 |        7 | 84.1188056394458 | <--- Efecto de MVCC, te coloca la fila al final ya que no la actualiza, crea una nueva
+----+------------+------------+-------------+----------+------------------+
(5 rows)

postgres@postgres# \d ventas
                                Table "public.ventas"
+-------------+---------+-----------+----------+------------------------------------+
|   Column    |  Type   | Collation | Nullable |              Default               |
+-------------+---------+-----------+----------+------------------------------------+
| id          | integer |           | not null | nextval('ventas_id_seq'::regclass) |
| fecha       | date    |           |          |                                    |
| cliente_id  | integer |           |          |                                    |
| producto_id | integer |           |          |                                    |
| cantidad    | integer |           |          |                                    |
| precio      | numeric |           |          |                                    |
+-------------+---------+-----------+----------+------------------------------------+
Indexes:
    "ventas_pkey" PRIMARY KEY, btree (id)

postgres@postgres# CLUSTER ventas USING ventas_pkey;
CLUSTER
Time: 29.171 ms


postgres@postgres# select * from ventas ;
+----+------------+------------+-------------+----------+------------------+
| id |   fecha    | cliente_id | producto_id | cantidad |      precio      |
+----+------------+------------+-------------+----------+------------------+
|  1 | 2022-08-06 |        905 |          54 |        3 |  67.525051208213 |
|  2 | 2022-01-30 |       2020 |          73 |        7 | 84.1188056394458 |
|  3 | 2024-04-02 |        375 |          28 |        7 | 13.6253997683525 |
|  4 | 2023-03-23 |        646 |          82 |        5 | 66.7211717925966 |
|  5 | 2022-08-12 |        744 |          68 |        7 | 91.8418753426522 |
+----+------------+------------+-------------+----------+------------------+
(5 rows)

Time: 0.617 ms


postgres@postgres# update ventas set cliente_id = 2020 where id = 2 ;
UPDATE 1
Time: 1.364 ms

postgres@postgres# select * from ventas ;
+----+------------+------------+-------------+----------+------------------+
| id |   fecha    | cliente_id | producto_id | cantidad |      precio      |
+----+------------+------------+-------------+----------+------------------+
|  1 | 2022-08-06 |        905 |          54 |        3 |  67.525051208213 |
|  3 | 2024-04-02 |        375 |          28 |        7 | 13.6253997683525 |
|  4 | 2023-03-23 |        646 |          82 |        5 | 66.7211717925966 |
|  5 | 2022-08-12 |        744 |          68 |        7 | 91.8418753426522 |
|  2 | 2022-01-30 |       2020 |          73 |        7 | 84.1188056394458 |
+----+------------+------------+-------------+----------+------------------+
(5 rows)

Time: 0.499 ms

postgres@postgres# cluster;
CLUSTER
Time: 25.964 ms

postgres@postgres# select * from ventas ;
+----+------------+------------+-------------+----------+------------------+
| id |   fecha    | cliente_id | producto_id | cantidad |      precio      |
+----+------------+------------+-------------+----------+------------------+
|  1 | 2022-08-06 |        905 |          54 |        3 |  67.525051208213 |
|  2 | 2022-01-30 |       2020 |          73 |        7 | 84.1188056394458 |
|  3 | 2024-04-02 |        375 |          28 |        7 | 13.6253997683525 |
|  4 | 2023-03-23 |        646 |          82 |        5 | 66.7211717925966 |
|  5 | 2022-08-12 |        744 |          68 |        7 | 91.8418753426522 |
+----+------------+------------+-------------+----------+------------------+
(5 rows)



```
  
  
 



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
