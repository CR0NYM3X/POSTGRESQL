 


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
PostgreSQL utiliza automáticamente la compresión para datos grandes almacenados en columnas de tipo `TEXT`, `BYTEA` y `VARCHAR` mediante el mecanismo TOAST (The Oversized-Attribute Storage Technique). Este mecanismo utiliza el algoritmo de compresión pglz para comprimir datos que exceden un cierto tamañ. TOAST permite almacenar valores grandes fuera de la fila principal de la tabla. Esto significa que, en lugar de almacenar todo el valor dentro de la fila, PostgreSQL almacena una referencia al valor que se encuentra en una tabla especial de TOAST.

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



#### Aumentar el tamaño de las páginas 
en una base de datos puede tener varias ventajas y desventajas.


### **Consideraciones:**
1. **Compatibilidad del sistema**: Verifica que tu sistema operativo y hardware soporten páginas grandes. No todos los sistemas tienen esta capacidad, y puede requerir configuraciones adicionales.
2. **Memoria disponible**: Asegúrate de que tu servidor tenga suficiente memoria física para manejar las páginas grandes sin afectar otras aplicaciones.
3. **Pruebas exhaustivas**: Realiza pruebas en un entorno de desarrollo o pruebas antes de implementar en producción. Esto te ayudará a identificar posibles problemas y ajustar la configuración según sea necesario.
4. **Impacto en el rendimiento**: Aunque las páginas grandes pueden mejorar el rendimiento, también pueden causar degradación en ciertas aplicaciones, especialmente aquellas que realizan muchas operaciones de fork().
5. **Monitoreo y ajuste**: Después de la implementación, monitorea el rendimiento del sistema y ajusta la configuración según sea necesario. Es posible que necesites realizar ajustes adicionales para optimizar el uso de páginas grandes.



### Ventajas de aumentar el tamaño de las páginas
1. **Reducción de E/S (Entrada/Salida):** Al tener páginas más grandes, se pueden almacenar más datos en cada página, lo que reduce la cantidad de operaciones de E/S necesarias para leer o escribir datos,
2. **Mejor uso de la memoria:** Las páginas más grandes pueden mejorar la eficiencia del uso de la memoria caché, ya que se reduce la fragmentación y se aumenta la probabilidad de que los datos necesarios estén en la memoria,
3. **Optimización de consultas:** Para consultas que acceden a grandes volúmenes de datos secuenciales, las páginas más grandes pueden mejorar el rendimiento al reducir la cantidad de páginas que deben ser leídas,

### Desventajas de aumentar el tamaño de las páginas
1. **Mayor uso de memoria:** Las páginas más grandes pueden consumir más memoria, lo que puede ser un problema si la memoria es limitada,
2. **Impacto en el rendimiento de acceso aleatorio:** Si las consultas acceden a datos de manera aleatoria, las páginas más grandes pueden reducir el rendimiento, ya que se leerán más datos de los necesarios,
3. **Mayor tiempo de recuperación:** En caso de fallos, la recuperación de páginas más grandes puede tomar más tiempo debido a la mayor cantidad de datos que deben ser procesados,

### Cuándo usar páginas más grandes
- **Consultas secuenciales:** Si tu aplicación realiza muchas consultas secuenciales que acceden a grandes volúmenes de datos, aumentar el tamaño de las páginas puede mejorar el rendimiento,
- **Carga de trabajo de lectura intensiva:** Si la carga de trabajo es principalmente de lectura y los datos se acceden de manera secuencial, las páginas más grandes pueden ser beneficiosas,

### Cuándo no usar páginas más grandes
- **Acceso aleatorio:** Si tu aplicación realiza muchas consultas que acceden a datos de manera aleatoria, es mejor mantener un tamaño de página más pequeño para reducir el impacto en el rendimiento,
- **Memoria limitada:** Si el sistema tiene restricciones de memoria, aumentar el tamaño de las páginas puede no ser recomendable debido al mayor uso de memoria,

### Escenario real
Imagina que tienes una base de datos que almacena registros de transacciones financieras. La mayoría de las consultas son informes que analizan grandes volúmenes de datos de manera secuencial para generar estadísticas diarias, semanales y mensuales. En este caso, aumentar el tamaño de las páginas puede mejorar el rendimiento de las consultas, ya que se reduce la cantidad de operaciones de E/S necesarias para leer los datos.

### Ventajas y desventajas de diferentes tamaños de página

#### Tamaño de página pequeño (4KB, 8KB)
**Ventajas:**
- **Acceso aleatorio eficiente:** Ideal para aplicaciones OLTP (Online Transaction Processing) que realizan muchas operaciones de lectura y escritura aleatorias.
- **Menor uso de memoria:** Menos espacio de agrupación de almacenamiento intermedio con filas no deseadas.

**Desventajas:**
- **Mayor número de operaciones de E/S:** Puede aumentar el número de operaciones de E/S necesarias para leer grandes volúmenes de datos.


#### Tamaño de página grande (16KB, 32KB)
**Ventajas:**
- **Optimización de consultas secuenciales:** Ideal para aplicaciones DSS (Decision Support Systems) que acceden a grandes volúmenes de datos de manera secuencial.
- **Reducción de E/S:** Menor número de operaciones de E/S necesarias para leer grandes volúmenes de datos.

**Desventajas:**
- **Mayor uso de memoria:** Puede consumir más memoria, lo que puede ser un problema si la memoria es limitada.
- **Impacto en el rendimiento de acceso aleatorio:** Puede reducir el rendimiento para consultas que acceden a datos de manera aleatoria.


 Ejemplo de modificación de las paginas 
```sql
-- Consultar todos los parámetros importantes de las paginas y costos 
select name,setting, context  from  pg_settings where name ~* 'page|cost|tuple' order by name;
+----------------------------------+---------+------------+
|               name               | setting |  context   |
+----------------------------------+---------+------------+
| autovacuum_vacuum_cost_delay     | 100     | sighup     |
| autovacuum_vacuum_cost_limit     | -1      | sighup     |
| bgwriter_lru_maxpages            | 100     | sighup     |
| cpu_index_tuple_cost             | 0.005   | user       |
| cpu_operator_cost                | 0.0025  | user       |
| cpu_tuple_cost                   | 0.01    | user       |
| cursor_tuple_fraction            | 0.1     | user       |
| full_page_writes                 | on      | sighup     |
| huge_pages                       | try     | postmaster |
| huge_page_size                   | 0       | postmaster |
| ignore_invalid_pages             | off     | postmaster |
| jit_above_cost                   | 100000  | user       |
| jit_inline_above_cost            | 500000  | user       |
| jit_optimize_above_cost          | 500000  | user       |
| jit_tuple_deforming              | on      | user       |
| max_pred_locks_per_page          | 2       | sighup     |
| parallel_setup_cost              | 1000    | user       |
| parallel_tuple_cost              | 0.1     | user       |
| random_page_cost                 | 4       | user       |
| seq_page_cost                    | 1       | user       |
| shared_memory_size_in_huge_pages | 4214    | internal   |
| vacuum_cost_delay                | 20      | user       |
| vacuum_cost_limit                | 200     | user       |
| vacuum_cost_page_dirty           | 20      | user       |
| vacuum_cost_page_hit             | 1       | user       |
| vacuum_cost_page_miss            | 2       | user       |
| zero_damaged_pages               | off     | superuser  |
+----------------------------------+---------+------------+



huge_page_size = '2MB'


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

- **PLAIN**: Almacena los datos sin compresión ni almacenamiento externo. Es la opción por defecto para tipos de datos pequeños.  como enteros
- **MAIN**: Intenta almacenar los datos en la tabla principal, pero puede moverlos a almacenamiento externo si son demasiado grandes.
- **EXTERNAL**: Almacena los datos fuera de la tabla principal, sin compresión . lo que puede reducir el tamaño de la tabla principal
- **EXTENDED**: Almacena los datos fuera de la tabla principal y los comprime. Esta es la opción por defecto para tipos de datos grandes como `TEXT` y `BYTEA`².


<br> Cuando se dice que los datos se  Almacenan fuera de la tabla principal, esto se refiere a que los datos grandes se almacenan fuera de la fila principal y se guardan en una estructura llamada TOAST (The Oversized-Attribute Storage Technique). Esto permite que solo las partes necesarias del valor se recuperen cuando se accede a los datos, optimizando las operaciones de subcadena y reduciendo la cantidad de datos que deben ser leídos



```sql
CREATE TABLE medios (
    id SERIAL PRIMARY KEY,
    articulo TEXT STORAGE EXTENDED,
    comentario TEXT STORAGE MAIN
);

ALTER TABLE mi_tabla ALTER COLUMN mi_columna SET STORAGE EXTENDED;
```


### ¿Qué es una página en PostgreSQL?

1. **Tamaño Fijo**: Las páginas tienen un tamaño fijo, que normalmente es de 8 kB, aunque este tamaño puede ser configurado al compilar el servidor¹..
2. **Gestión de Datos**: PostgreSQL utiliza estas páginas para gestionar y organizar los datos en el disco de manera eficiente. Cada vez que se necesita leer o escribir datos, se hace en unidades de páginas completas.
3. **Páginas**: Los datos en PostgreSQL se almacenan en bloques de disco llamados páginas. El tamaño de una página es típicamente de 8 kB, aunque puede ser configurado a otros tamaños.
4. **Filas y Columnas**: Cada fila de una tabla se almacena en una página. Si una fila es demasiado grande para caber en una sola página, se divide en varias partes y se almacena en múltiples páginas.
5. **Gestión de Páginas**: PostgreSQL utiliza un gestor de almacenamiento que se encarga de administrar las páginas. Este gestor decide en qué página se almacenará cada fila y cómo se distribuirán las columnas.
6. **Índices**: Los índices también se almacenan en páginas y ayudan a acelerar la búsqueda de datos dentro de las tablas.
7. **Optimización**: Para mejorar el rendimiento, PostgreSQL puede comprimir datos y utilizar técnicas de almacenamiento eficientes.

Ref:  https://wiki.postgresql.org/images/4/43/Postgresql_como_funciona_una_dbms_por_dentro.pdf


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
---

# Tipos de sistemas de procesamiento de datos



### **OLTP (Procesamiento de Transacciones en Línea)**

* **Qué es:** Los sistemas OLTP están diseñados para manejar un gran volumen de **aplicaciones orientadas a transacciones** en tiempo real.  
* **Dónde se aplica:** Cualquier sistema que requiera el procesamiento en tiempo real de numerosas transacciones concurrentes.
* **Propósito:** Procesar y gestionar eficientemente transacciones individuales a medida que ocurren. El enfoque está en la velocidad, la fiabilidad y la integridad de los datos.
* **Usos:**
    * Procesamiento de pedidos en línea (comercio electrónico)
    * Transacciones en cajeros automáticos y banca en línea
    * Sistemas de punto de venta (POS) en el comercio minorista
    * Sistemas de reserva de hoteles y aerolíneas
    * Sistemas de gestión de relaciones con el cliente (CRM) para actualizar la información del cliente
    * Sistemas de gestión de inventario para rastrear los niveles de stock

* **Ventajas:**
    * **Alta velocidad y eficiencia:** Optimizado para procesar un gran número de transacciones simples rápidamente.
    * **Integridad de los datos:** Garantiza la precisión y coherencia de los datos mediante mecanismos como las propiedades ACID (Atomicidad, Consistencia, Aislamiento, Durabilidad).
    * **Concurrencia:** Admite que múltiples usuarios accedan y modifiquen los datos simultáneamente sin comprometer la integridad.
    * **Operaciones en tiempo real:** Permite actualizaciones y respuestas inmediatas para las tareas transaccionales.
    * **Alta disponibilidad:** Diseñado para un funcionamiento continuo con un tiempo de inactividad mínimo.
* **Desventajas:**
    * **No optimizado para análisis complejos:** Tiene dificultades con las consultas analíticas que involucran grandes volúmenes de datos y agregaciones complejas.
    * **Datos históricos limitados:** A menudo se centra en los datos actuales, y los datos históricos pueden archivarse o eliminarse por motivos de rendimiento, lo que dificulta el análisis de tendencias a largo plazo.
    * **Desafíos de escalabilidad para consultas analíticas:** Escalar el sistema para manejar cargas de trabajo analíticas complejas puede ser difícil e impactar el rendimiento transaccional.


###  **OLAP (Procesamiento Analítico en Línea)**

* **Qué es:** Los sistemas OLAP están diseñados para el **análisis de datos e inteligencia empresarial**. Se centran en proporcionar información a partir de grandes volúmenes de datos históricos y agregados.
* **Dónde se aplica:** Inteligencia empresarial, almacenamiento de datos y aplicaciones analíticas en diversas industrias.
* **Propósito:** Permitir consultas analíticas complejas, identificar tendencias y respaldar la toma de decisiones.
* **Usos:**
    * Generación de informes empresariales (ventas, financieros, marketing)
    * Análisis de tendencias de ventas a lo largo del tiempo y en diferentes regiones o productos
    * Previsión de ventas o demanda futuras
    * Realización de análisis "qué pasaría si" para comprender el impacto de diferentes escenarios comerciales
    * Minería de datos para descubrir patrones y relaciones en los datos
    * Paneles de control e visualizaciones de inteligencia empresarial
* **Ventajas:**
    * **Optimizado para análisis complejos:** Diseñado para manejar consultas y agregaciones complejas de manera eficiente.
    * **Análisis de datos multidimensional:** Permite a los usuarios analizar datos desde diferentes perspectivas (por ejemplo, por producto, región, tiempo).
    * **Respuesta de consulta más rápida para tareas analíticas:** Precalcula y estructura los datos para una recuperación rápida de la información agregada.
    * **Admite el análisis de tendencias y la previsión:** Permite el análisis de datos históricos para identificar patrones y predecir resultados futuros.
    * **Mejora la toma de decisiones:** Proporciona información que respalda las decisiones estratégicas y operativas.
* **Desventajas:**
    * **Más lento para actualizaciones transaccionales:** No está diseñado para el procesamiento frecuente de transacciones en tiempo real. Los datos generalmente se cargan en lotes.
    * **Latencia de datos:** Los datos pueden no ser completamente en tiempo real, ya que a menudo se cargan periódicamente desde los sistemas OLTP.
    * **Complejidad:** Puede implicar modelado de datos e infraestructura complejos.
    * **Potencial de alto costo:** La implementación y el mantenimiento de los sistemas OLAP pueden ser costosos debido al hardware y software especializados.



 
---

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




---

# Comparación entre HDD y SSD:

# **HDD (Disco Duro)**:
- **Funcionamiento**: Utiliza platos giratorios y un brazo mecánico para leer y escribir datos. Los platos están recubiertos de material magnético.
- **Velocidad**: Generalmente más lento debido a las partes mecánicas. La velocidad de lectura/escritura suele estar entre 50-150 MB/s.
- **Durabilidad**: Más susceptible a daños físicos debido a las partes móviles.
- **Capacidad**: Suelen ofrecer más capacidad de almacenamiento a un costo menor.
- **Costo**: Más económico por gigabyte comparado con los SSD.

- **Escritura de datos**: Los datos se escriben mediante una cabeza magnética que se encuentra en el extremo de un brazo mecánico. Esta cabeza magnetiza pequeñas áreas del plato para representar bits de datos.
- **Lectura de datos**: Para leer los datos, la cabeza magnética detecta las áreas magnetizadas del plato mientras este gira. La velocidad de lectura y escritura depende de la velocidad de rotación del plato y la densidad de los datos.



### Conceptos

- **Platos**: Discos circulares recubiertos de material magnético donde se almacenan los datos.
- **Cabezal de lectura/escritura**: Brazo mecánico que se mueve sobre los platos para leer y escribir datos.
- **Sectores**: Las superficies de los platos se dividen en sectores, que son las unidades básicas de almacenamiento. Cada sector suele tener 512 bytes.
- **Pistas**: Cada plato se divide en pistas concéntricas, que son círculos completos en los que se almacenan los datos.
- **Cilindros**: Conjunto de pistas alineadas verticalmente a través de los platos.
- **Clusters**: Conjunto de sectores que el sistema operativo trata como una unidad de almacenamiento.

 
### **Fragmentación**:
- **HDD**: La fragmentación ocurre cuando los archivos se dividen en múltiples fragmentos que se almacenan en diferentes partes del disco. Esto sucede porque los archivos se escriben en los primeros espacios disponibles, y con el tiempo, los archivos se dividen en partes más pequeñas debido a la eliminación y creación de nuevos archivos. La fragmentación puede ralentizar el rendimiento del disco porque el cabezal de lectura/escritura tiene que moverse a diferentes ubicaciones para acceder a todas las partes de un archivo.


### **Mantenimiento para HDD**:
1. **Desfragmentación**: Reorganiza los fragmentos de archivos en sectores contiguos para mejorar la velocidad de acceso.
2. **Limpieza de disco**: Elimina archivos temporales y otros datos innecesarios para liberar espacio.
3. **Revisión de errores**: Utiliza herramientas como CHKDSK para detectar y corregir errores en el disco.
4. **Optimización de unidades**: Activa la caché de escritura y la indización de archivos para mejorar el rendimiento.
5. **Evitar llenarlo completamente**: Mantén al menos un 15-20% de espacio libre para asegurar un funcionamiento óptimo.



# **SSD (Unidad de Estado Sólido)**:
- **Funcionamiento**: Utiliza memoria flash para almacenar datos, sin partes móviles. Los datos se almacenan en chips de memoria.
- **Velocidad**: Mucho más rápido, con velocidades de lectura/escritura que pueden superar los 500 MB/s.
- **Durabilidad**: Menos susceptible a daños físicos ya que no tiene partes móviles.
- **Capacidad**: Aunque los precios han bajado, suelen ser más caros por gigabyte comparado con los HDD.
- **Costo**: Más caro por gigabyte, pero los precios están disminuyendo con el tiempo.

- **Escritura de datos**: Los datos se escriben en celdas de memoria mediante la carga eléctrica. Cada celda puede almacenar uno o más bits de datos, dependiendo del tipo de memoria.
- **Lectura de datos**: Para leer los datos, el controlador del SSD selecciona las celdas de memoria y lee la carga eléctrica almacenada en ellas. Esto permite una lectura rápida y eficiente.


### Conceptos
- **Memoria Flash**: Utiliza chips de memoria NAND para almacenar datos. No tiene partes móviles.
- **Bloques**: La memoria flash se organiza en bloques, que son conjuntos de páginas.
- **Páginas**: Subdivisiones dentro de los bloques. Cada página suele tener 4 KB.
- **Controlador**: Gestiona la lectura y escritura de datos, así como la distribución de los datos en los chips de memoria.
- **Wear leveling**: Técnica utilizada para distribuir uniformemente las escrituras en los chips de memoria, prolongando la vida útil del SSD.
- **TRIM**: Comando que ayuda a mantener el rendimiento del SSD al permitir que el sistema operativo informe al SSD qué bloques de datos ya no son necesarios y pueden ser borrados.


### **Fragmentación**:
- **SSD**: Aunque los SSD también pueden experimentar fragmentación, no afecta el rendimiento de la misma manera que en los HDD. Los SSD acceden a los datos directamente en la memoria flash, por lo que la ubicación física de los fragmentos no influye en la velocidad de acceso. Sin embargo, la desfragmentación en SSD no es recomendable porque genera escrituras innecesarias que pueden reducir la vida útil del dispositivo.



### **Mantenimiento para SSD**:
1. **TRIM**: Asegúrate de que el comando TRIM esté habilitado para optimizar el espacio disponible y mantener el rendimiento.
2. **Actualización de firmware**: Mantén el firmware del SSD actualizado para aprovechar las mejoras y correcciones de errores.
3. **Evitar escrituras innecesarias**: Minimiza las operaciones de escritura para prolongar la vida útil del SSD.
4. **Desactivar la desfragmentación**: No es necesario desfragmentar un SSD y puede reducir su vida útil.
5. **Monitoreo de salud**: Utiliza herramientas como SMART para monitorear el estado del SSD y detectar problemas a tiempo.
 



# Columnas del sistema ocultas en PostgreSQL

En PostgreSQL, todas las tablas tienen varias columnas del sistema que no son visibles en un `SELECT *` normal, pero que puedes consultar explícitamente. Estas columnas proporcionan metadatos y características internas de cada fila.

## Columnas del sistema principales

1. **`oid`** - Identificador de objeto (solo en tablas con OIDs habilitados)
2. **`tableoid`** - OID de la tabla que contiene esta fila (útil para herencia)
3. **`xmin`** - Identificador de transacción que insertó la fila (versión)
4. **`xmax`** - Identificador de transacción que eliminó/marcó para eliminar la fila
5. **`cmin`** - Identificador de comando dentro de la transacción (de inserción)
6. **`cmax`** - Identificador de comando dentro de la transacción (de eliminación)
7. **`ctid`** - Identificador físico de la ubicación de la fila (Num. página + posición de la fila dentro de esa página)

## Ejemplo de consulta

```sql
-- Consultar las columnas ocultas explícitamente
SELECT tableoid, xmin, xmax, cmin, cmax, ctid, * FROM mi_tabla LIMIT 5;
```
 
Estas columnas son particularmente útiles para:
- Depuración avanzada
- Entender el funcionamiento interno de PostgreSQL
- Solucionar problemas de concurrencia
- Optimizar consultas complejas



# **Semántica en PostgreSQL**

En PostgreSQL, la **semántica** se refiere al significado, reglas lógicas y comportamiento de los elementos del sistema cómo se interpretan y ejecutan las operaciones,  como consultas, operaciones y estructuras de datos. A diferencia de la **sintaxis** (que define cómo se escriben las consultas), la semántica define **qué hacen** y cómo interactúan con los datos.
 
La **semántica en PostgreSQL** define:
✅ **Cómo se comportan las consultas** (ej: `JOIN`, `NULL`).  
✅ **Cómo se manejan las transacciones** (ACID).  
✅ **Cómo funcionan los tipos de datos** (ej: fechas, texto).  
✅ **Cómo se optimizan las operaciones** (índices, planificación).  

