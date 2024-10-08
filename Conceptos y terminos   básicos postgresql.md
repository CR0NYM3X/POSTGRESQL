 


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
PostgreSQL utiliza automáticamente la compresión para datos grandes almacenados en columnas de tipo `TEXT`, `BYTEA` y `VARCHAR` mediante el mecanismo TOAST (The Oversized-Attribute Storage Technique). Este mecanismo utiliza el algoritmo de compresión pglz para comprimir datos que exceden un cierto tamaño⁴.
```
show default_toast_compression;
+---------------------------+
| default_toast_compression |
+---------------------------+
| pglz                      |
+---------------------------+

```

 
1. **Compresión**: Los valores grandes se comprimen para reducir su tamaño.
2. **Almacenamiento fuera de línea**: Si la compresión no es suficiente, los valores se dividen en múltiples filas físicas y se almacenan en una tabla TOAST asociada.
3. **Transparencia**: Todo esto ocurre de manera transparente para el usuario, lo que significa que no necesitas hacer nada especial para manejar estos datos grandes; PostgreSQL se encarga de todo automáticamente¹².

### Detalles Técnicos

- **Tamaño de página fijo**: PostgreSQL utiliza un tamaño de página fijo (normalmente 8 kB), y no permite que las tuplas abarquen múltiples páginas.
- **Representación varlena**: Los tipos de datos que soportan TOAST deben tener una representación de longitud variable (varlena), donde la primera palabra de cuatro bytes de cualquier valor almacenado contiene la longitud total del valor en bytes¹².

 
### Tipos de Compresión en PostgreSQL

1. **Compresión PGLZ**
   - **Nivel**: Columna
   - **Ventajas**:
     - Es el método de compresión predeterminado en PostgreSQL.
     - Reduce significativamente el tamaño de los datos almacenados.
   - **Desventajas**:
     - Puede ser más lento en comparación con otros métodos de compresión más modernos.
     - No es tan eficiente para datos que ya están parcialmente comprimidos.
   - **Cuándo usarlo**:
     - Cuando se necesita una compresión básica y no se requiere un rendimiento extremadamente alto.
     - Ideal para datos de texto y otros tipos de datos de longitud variable.

2. **Compresión LZ4**
   - **Nivel**: Columna
   - **Ventajas**:
     - Más rápida que PGLZ.
     - Ofrece una buena relación entre velocidad y tasa de compresión.
   - **Desventajas**:
     - Puede no comprimir tan eficientemente como otros algoritmos en ciertos tipos de datos.
   - **Cuándo usarlo**:
     - Cuando se necesita una compresión rápida y se puede sacrificar algo de eficiencia en la tasa de compresión.
     - Útil para aplicaciones donde la velocidad de acceso a los datos es crítica¹¹.
 
  
- **Compresión PGLZ**: Podrías usar PGLZ para comprimir las descripciones de productos, ya que estas pueden ser bastante largas y la compresión ayudará a reducir el espacio en disco utilizado.
- **Compresión LZ4**: Para las reseñas de clientes, donde la velocidad de acceso es más importante debido a la frecuencia con la que se consultan, podrías optar por LZ4 para obtener una compresión rápida y eficiente.
 
 
- **lz4**: Un método de compresión más reciente y eficiente que puede ser utilizado si está habilitado en tu instalación de PostgreSQL².

```sql
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    descripcion TEXT COMPRESSION pglz,
    reseñas TEXT COMPRESSION lz4
);

ALTER TABLE clientes ALTER COLUMN nombre SET COMPRESSION lz4;
ALTER TABLE clientes ALTER COLUMN nombre SET COMPRESSION zstd;
ALTER TABLE clientes ALTER COLUMN nombre SET COMPRESSION pglz;
```



--- 
 

### ¿Qué es el método de acceso heap?

El método de acceso **heap**  es el método de almacenamiento por defecto en PostgreSQL para las tablas. En este método, los datos se almacenan en páginas de 8 KB en el disco. Cada fila se almacena en una página y las páginas se agrupan en bloques. Este método es flexible y adecuado para la mayoría de los casos de uso, permitiendo actualizaciones y eliminaciones eficientes.


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

### 1. **Storage**
El parámetro **Storage**  métodos de almacenamiento se aplican a nivel de columna y determinan cómo se almacenan los datos dentro de las tablas que utilizan heap storage. Las opciones disponibles son:

- **PLAIN**: Almacena los datos sin compresión ni almacenamiento externo. Es la opción por defecto para tipos de datos pequeños.
- **MAIN**: Intenta almacenar los datos en la tabla principal, pero puede moverlos a almacenamiento externo si son demasiado grandes.
- **EXTERNAL**: Almacena los datos fuera de la tabla principal, sin compresión.
- **EXTENDED**: Almacena los datos fuera de la tabla principal y los comprime. Esta es la opción por defecto para tipos de datos grandes como `TEXT` y `BYTEA`².


```sql
CREATE TABLE medios (
    id SERIAL PRIMARY KEY,
    articulo TEXT STORAGE EXTENDED,
    comentario TEXT STORAGE MAIN
);

ALTER TABLE mi_tabla ALTER COLUMN mi_columna SET STORAGE EXTENDED;
```



 
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
  





En PostgreSQL, los "snapshots" son una parte fundamental del sistema de control de concurrencia multiversión (MVCC, por sus siglas en inglés). 

### ¿Qué es un Snapshot en PostgreSQL?

Un snapshot en PostgreSQL es una vista consistente de la base de datos en un momento específico. Los snapshots permiten a las transacciones ver un estado de la base de datos que no cambia, incluso si otras transacciones están realizando modificaciones. Esto es esencial para mantener la consistencia y el aislamiento de las transacciones.

### ¿Para Qué Sirve un Snapshot?

1. **Consistencia de Lectura**:
   - Los snapshots aseguran que una transacción puede leer datos consistentes sin ser afectada por otras transacciones concurrentes que están realizando escrituras.

2. **Aislamiento de Transacciones**:
   - Permiten diferentes niveles de aislamiento de transacciones, como `READ COMMITTED` y `REPEATABLE READ`, proporcionando un control granular sobre cómo las transacciones interactúan entre sí.

3. **Recuperación de Datos**:
   - Los snapshots pueden ser utilizados en procesos de recuperación y replicación para asegurar que los datos se restauren a un estado consistente.

### ¿Cómo se Configura un Snapshot?

Los snapshots se gestionan automáticamente en PostgreSQL, pero puedes influir en su comportamiento a través de la configuración de transacciones y niveles de aislamiento.

#### Configuración de Niveles de Aislamiento

1. **READ COMMITTED**:
   - Este es el nivel de aislamiento por defecto. Cada comando dentro de una transacción ve un snapshot consistente de la base de datos en el momento en que se ejecuta el comando.
   ```sql
   SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
   ```

2. **REPEATABLE READ**:
   - Todas las consultas dentro de una transacción ven el mismo snapshot, asegurando que los datos no cambien durante la duración de la transacción.
   ```sql
   SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
   ```

3. **SERIALIZABLE**:
   - Este nivel de aislamiento asegura que las transacciones se ejecuten de manera que el resultado sea el mismo que si se hubieran ejecutado secuencialmente.
   ```sql
   SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
   ```

#### Ejemplo de Uso de Snapshots

1. **Iniciar una Transacción con un Nivel de Aislamiento Específico**:
   ```sql
   BEGIN;
   SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
   SELECT * FROM my_table;
   -- Realiza operaciones de lectura/escritura
   COMMIT;
   ```

2. **Verificar el Snapshot Actual**:
   - Puedes usar la función `txid_current_snapshot()` para ver el snapshot actual de una transacción.
   ```sql
   SELECT txid_current_snapshot();
   select * from pg_current_snapshot();
   ```

### Conclusión

Los snapshots en PostgreSQL son esenciales para mantener la consistencia y el aislamiento de las transacciones. Aunque se gestionan automáticamente, puedes configurar los niveles de aislamiento de las transacciones para controlar cómo se utilizan los snapshots. Esto te permite asegurar que tus transacciones se ejecuten de manera consistente y segura.

 

# Escalamientos 

### Escalado Horizontal
El **escalado horizontal** (también conocido como "scale-out") implica añadir más máquinas o nodos al sistema para distribuir la carga de trabajo. Cada nodo adicional maneja una parte de las transacciones o datos. En lugar de depender de un solo servidor potente, puedes distribuir la carga entre varios servidores. Esto es especialmente útil para aplicaciones que necesitan manejar grandes volúmenes de datos y usuarios.

- **Distribución de datos**: Los datos se dividen en fragmentos y se almacenan en diferentes nodos¹.
- **Redundancia y tolerancia a fallos**: Si un nodo falla, otros nodos pueden asumir su carga.
- **Escalabilidad**: Es más fácil añadir capacidad incrementalmente².

### Escalado Vertical
El **escalado vertical** (también conocido como "scale-up") implica aumentar la capacidad de una sola máquina añadiendo más recursos, como CPU, RAM o almacenamiento. Este enfoque es común en bases de datos relacionales tradicionales. Algunas características incluyen:

- **Aumento de recursos**: Se mejora el hardware de una sola máquina para manejar más carga².
- **Simplicidad**: No requiere cambios significativos en la arquitectura del sistema.
- **Límites físicos**: Hay un límite en cuanto a cuánto se puede mejorar una sola máquina².

### Comparación
- **Escalado Horizontal**: Ideal para aplicaciones que pueden distribuir su carga de trabajo y requieren alta disponibilidad y tolerancia a fallos.
- **Escalado Vertical**: Adecuado para aplicaciones que necesitan más potencia de procesamiento en una sola máquina y donde la simplicidad es una prioridad¹².
 

### Resiliencia incorporada
La resiliencia se refiere a la capacidad de la base de datos para seguir funcionando incluso si algunos de sus componentes fallan. diseñada para ser altamente disponible y resistente a fallos, lo que significa que puede seguir operando sin interrupciones incluso si uno o más nodos dejan de funcionar. 


# DB  colocada y no colocada
1. **Base de datos colocada**: Una base de datos colocada (también conocida como "on-premises") es aquella que se encuentra físicamente en las instalaciones de la organización. Esto significa que la organización es responsable de la gestión, mantenimiento y seguridad del hardware y software de la base de datos. Las ventajas incluyen un mayor control sobre los datos y la infraestructura, pero también implica mayores costos y responsabilidades de mantenimiento.

2. **Base de datos no colocada**: Una base de datos no colocada (o "en la nube") es aquella que se aloja en servidores de terceros, generalmente proveedores de servicios en la nube como AWS, Azure o Google Cloud. En este caso, el proveedor de servicios se encarga de la gestión, mantenimiento y seguridad de la infraestructura. Las ventajas incluyen escalabilidad, reducción de costos de infraestructura y facilidad de acceso desde cualquier lugar, aunque puede haber preocupaciones sobre la seguridad y el control de los datos.

# OLTP
Una **base de datos OLTP (Online Transaction Processing)** es un tipo de base de datos diseñada para gestionar transacciones en tiempo real. Estas bases de datos son utilizadas en aplicaciones que requieren un procesamiento rápido y preciso de un gran número de transacciones, como cajeros automáticos, banca en línea, comercio electrónico y sistemas de reservas¹. Las características principales de los sistemas OLTP incluyen:

- **Procesamiento rápido**: Las transacciones se completan en milisegundos.
- **Acceso multiusuario**: Permiten que múltiples usuarios accedan y modifiquen los datos simultáneamente.
- **Integridad de datos**: Utilizan algoritmos de concurrencia para asegurar que las transacciones se realicen en el orden correcto y sin conflictos.
- **Disponibilidad continua**: Están diseñadas para estar disponibles 24/7, minimizando el tiempo de inactividad¹².

 


# On-Premises y Retail

### On-Premises
**On-premises** (o "on-prem") se refiere a bases de datos y software que se instalan y ejecutan en los servidores físicos de una organización, en lugar de en la nube. Esto significa que la organización es responsable de la gestión, mantenimiento y seguridad de la infraestructura. Algunas características incluyen:

- **Control total**: La organización tiene control completo sobre el hardware y software.
- **Seguridad**: Puede ser más fácil cumplir con ciertos requisitos de seguridad y privacidad.
- **Costos**: Puede implicar mayores costos iniciales debido a la compra de hardware y licencias¹.

### Retail
En el contexto de bases de datos, **retail** generalmente se refiere a aplicaciones y sistemas utilizados en el sector minorista. Estos sistemas suelen manejar grandes volúmenes de transacciones y datos de clientes. Algunas características incluyen:

- **Gestión de inventarios**: Control y seguimiento de productos en stock.
- **Procesamiento de transacciones**: Manejo de ventas, devoluciones y pagos.
- **Análisis de datos**: Recopilación y análisis de datos de ventas para mejorar la toma de decisiones².
 


# Cuadrante Mágico de Gartner 
El **Cuadrante Mágico de Gartner** es una herramienta de análisis desarrollada por la firma de investigación y consultoría Gartner. Se utiliza para proporcionar una representación gráfica de la posición relativa de los proveedores de tecnología en un mercado específico¹².

### ¿Cómo funciona?
El Cuadrante Mágico se basa en dos ejes:
- **Eje X (horizontal)**: Representa la **integridad de la visión** del proveedor, es decir, su capacidad para entender las tendencias del mercado y planificar a largo plazo.
- **Eje Y (vertical)**: Representa la **capacidad de ejecución**, que mide la habilidad del proveedor para llevar a cabo su visión y cumplir con sus promesas¹².

### Los Cuatro Cuadrantes
El gráfico se divide en cuatro cuadrantes, cada uno representando un tipo de proveedor:
1. **Líderes**: Proveedores que tienen una visión completa y una alta capacidad de ejecución.
2. **Visionarios**: Proveedores con una visión innovadora pero que aún no han demostrado una alta capacidad de ejecución.
3. **Jugadores de nicho**: Proveedores que se especializan en un segmento específico del mercado.
4. **Retadores**: Proveedores que tienen una alta capacidad de ejecución pero una visión menos completa¹².

### Aplicaciones
El Cuadrante Mágico es utilizado por empresas para evaluar y comparar diferentes proveedores de tecnología, ayudándoles a tomar decisiones informadas sobre inversiones y adquisiciones de tecnología¹².
 




```sql
SELECT a.attname,
          pg_catalog.format_type(a.atttypid, a.atttypmod),
          (SELECT pg_catalog.pg_get_expr(d.adbin, d.adrelid, true)
           FROM pg_catalog.pg_attrdef d
           WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef),
          a.attnotnull,
          (SELECT c.collname FROM pg_catalog.pg_collation c, pg_catalog.pg_type t
           WHERE c.oid = a.attcollation AND t.oid = a.atttypid AND a.attcollation <> t.typcollation) AS attcollation,
          a.attidentity,
          a.attgenerated,
          a.attstorage,
          a.attcompression AS attcompression,
          CASE WHEN a.attstattarget=-1 THEN NULL ELSE a.attstattarget END AS attstattarget,
          pg_catalog.col_description(a.attrelid, a.attnum)
        FROM pg_catalog.pg_attribute a
        WHERE     a.attnum > 0 AND NOT a.attisdropped
        ORDER BY a.attnum;
```
