 
---

# **ISO/IEC 9075** 

El estándar de SQL más ampliamente reconocido es el **SQL ANSI (American National Standards Institute)**, también conocido como **ISO/IEC 9075**. Este conjunto de normas define cómo debe funcionar el lenguaje de consulta estructurado (SQL) para asegurar interoperabilidad entre diferentes sistemas de bases de datos.

Desde su primera versión en 1986, el estándar ha evolucionado con múltiples actualizaciones importantes, como:
- **SQL-92**: estableció muchas de las características básicas que hoy son comunes.
- **SQL:1999 (SQL3)**: introdujo programación orientada a objetos, expresiones recursivas y más.
- **SQL:2003**: incluyó XML y secuencias.
- **SQL:2008** y **SQL:2011**: añadieron soporte para funciones como `TRUNCATE`, mejoras a tipos de datos y nuevas expresiones.
- **SQL:2016** y versiones más recientes: integraron soporte para JSON, funciones analíticas mejoradas y otras modernizaciones.

Aunque muchos sistemas como MySQL, PostgreSQL, SQL Server y Oracle implementan partes del estándar, **cada uno tiene extensiones propias** que pueden no ser compatibles entre sí.

--- 
 


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



# Aumentar el tamaño de las páginas 
Las páginas gigantes son una técnica de administración de memoria utilizada por el sistema operativo (principalmente en Linux) para trabajar con bloques de memoria más grandes que el tamaño de página predeterminado (que suele ser de 4 KB). afectan principalmente a la memoria RAM (memoria física). 💾


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



huge_page_size = '2MB' -- https://tomasz-gintowt.medium.com/postgresql-and-huge-pages-boosting-database-performance-the-right-way-32a27b25a819


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



# **homologar** 
Se refiere al proceso de verificar y certificar que un producto, sistema o componente cumple con los estándares, normativas o especificaciones técnicas requeridas para su uso en un determinado mercado.
### 📄 **Proceso típico de homologación**  
1. **Pruebas técnicas** (en laboratorios autorizados).  
2. **Documentación** (informes de cumplimiento).  
3. **Certificación** (sellos como CE, FCC, ISO).


---



# Comparación de Codificaciones: ASCII, ANSI y Unicode 

### **ASCII (American Standard Code for Information Interchange)**
- Fue el primer estándar para representar texto en computadoras.
- Utiliza **7 bits** para codificar 128 caracteres (incluye letras en inglés, números, símbolos básicos y caracteres de control).
- Ejemplo: 
  - `A` en ASCII es **65**.
  - `B` es **66**.

**Limitación:** Solo soporta caracteres en inglés y unos pocos símbolos, por lo que no es útil para otros idiomas o caracteres más complejos.

 

### **ANSI (American National Standards Institute)**
- Es una extensión de ASCII que utiliza **8 bits** para codificar hasta **256 caracteres**.
- Incluye más caracteres, como los acentos en español (`á, é, í`) y símbolos adicionales.
- Ejemplo: 
  - `ñ` en ANSI es **241**.

**Limitación:** A pesar de ampliar ASCII, sigue siendo insuficiente para cubrir todos los idiomas y caracteres del mundo.

 

### **Unicode**
- Es un estándar universal que busca representar **todos los caracteres de todos los idiomas** y símbolos, con millones de combinaciones posibles.
- Usa diferentes formas de codificación, como **UTF-8**, **UTF-16** y **UTF-32**.
- Ejemplo:
  - `A` en Unicode es **U+0041**.
  - `ñ` es **U+00F1**.
  - El emoji 😊 es **U+1F60A**.

**Ventaja:** Es compatible con cualquier idioma, símbolos y emojis, lo que lo convierte en el estándar actual más utilizado.

 
### Comparación rápida:
| Tipo    | Bits usados | Caracteres soportados                | Ejemplo               |
|---------|-------------|---------------------------------------|-----------------------|
| ASCII   | 7 bits      | 128 caracteres (inglés básico)       | `A` = 65             |
| ANSI    | 8 bits      | 256 caracteres (acentos, algunos idiomas) | `ñ` = 241           |
| Unicode | Variable    | Millones (todos los idiomas y símbolos) | 😊 = U+1F60A        |



Las diferencias entre **UTF-8**, **UTF-16** y **UTF-32**  


### **1. UTF-8**
- **Variable**: Usa entre **1 y 4 bytes** para representar cada carácter.
- **Ventaja**: Es eficiente para textos en idiomas que usan caracteres ASCII (como inglés), porque los caracteres básicos solo ocupan 1 byte.
- **Ejemplo**:
  - El carácter **A** (U+0041) ocupa 1 byte: `41`.
  - El emoji 😊 (U+1F60A) ocupa 4 bytes: `F0 9F 98 8A`.

**Uso común**: Es la codificación más utilizada en la web debido a su compatibilidad y eficiencia.

 

### **2. UTF-16**
- **Variable**: Usa **2 o 4 bytes**.
- **Ventaja**: Es más eficiente que UTF-8 para textos que contienen muchos caracteres no ASCII, como los chinos o japoneses, ya que estos suelen ocupar 2 bytes.
- **Ejemplo**:
  - El carácter **A** (U+0041) ocupa 2 bytes: `00 41`.
  - El emoji 😊 (U+1F60A) ocupa 4 bytes: `D8 3D DE 0A` (usa "pares sustitutos").

**Uso común**: Es utilizado en sistemas como Windows y muchas aplicaciones internas.

 

### **3. UTF-32**
- **Fijo**: Cada carácter ocupa siempre **4 bytes**, sin importar qué tan sencillo o complejo sea.
- **Ventaja**: Es simple, ya que cada carácter tiene la misma longitud, pero ocupa más espacio en comparación con UTF-8 y UTF-16.
- **Ejemplo**:
  - El carácter **A** (U+0041) ocupa 4 bytes: `00 00 00 41`.
  - El emoji 😊 (U+1F60A) ocupa también 4 bytes: `00 01 F6 0A`.

**Uso común**: Es poco utilizado debido a su ineficiencia en el uso de memoria.


### 2. LATIN1 (ISO-8859-1): El estándar europeo

* **Qué es:** Una codificación de **un solo byte** (8 bits). Puede representar hasta 256 caracteres.
* **Comportamiento:** Los primeros 127 caracteres son iguales al ASCII (inglés básico). Del 128 al 255 se usan para tildes, eñes y caracteres europeos.
* **Por qué funcionó:** Tu base de datos tiene guardado el byte `0xe1`. En `LATIN1`, ese byte significa exactamente **"á"**. Como es un solo byte, no hay reglas complejas; el servidor simplemente dice: "Aquí hay un `0xe1`, envíaselo al usuario como una `á`".
 

### Comparación rápida:
| Codificación | Tamaño por carácter | Ventaja                       | Desventaja               |
|--------------|---------------------|-------------------------------|--------------------------|
| **UTF-8**    | 1 a 4 bytes         | Eficiente con ASCII           | Menos eficiente con texto complejo. |
| **UTF-16**   | 2 o 4 bytes         | Eficiente con idiomas asiáticos | Requiere pares sustitutos para caracteres mayores. |
| **UTF-32**   | 4 bytes             | Simplicidad (tamaño fijo)     | Consume mucho espacio.   |

 
### ¿Cómo elegir?
- Si estás trabajando con aplicaciones web o datos internacionales, **UTF-8** es la mejor opción por su compatibilidad.
- Si necesitas mayor eficiencia con caracteres no latinos, considera **UTF-16**.
- **UTF-32** es ideal solo en casos donde la simplicidad sea crítica y el almacenamiento no sea un problema.



  
**1. Identificadores y sensibilidad de mayúsculas/minúsculas**
- Cuando usas nombres sin comillas (por ejemplo, `foo` o `FOO`), PostgreSQL los convierte automáticamente a minúsculas (`foo`).
- Si usas comillas dobles alrededor de un nombre (por ejemplo, `"Foo"`), PostgreSQL hace que sea **sensible a mayúsculas/minúsculas**. Esto significa que `"Foo"` es diferente de `foo`, `FOO` y `"foo"`.
- Esto no sigue el estándar SQL, que convierte nombres sin comillas a **mayúsculas**. Por lo tanto, para portabilidad entre sistemas, es recomendable **usar comillas siempre o nunca**, pero no alternar.



**2. Identificadores con caracteres Unicode**
- Si necesitas usar caracteres Unicode en los nombres, puedes usar el prefijo `U&` seguido de comillas dobles, por ejemplo: `U&"foo"`.
- Dentro de estas comillas, puedes representar caracteres Unicode mediante secuencias de escape:
  - **Forma de 4 dígitos**: `\` seguido de 4 dígitos hexadecimales. Ejemplo: `d\0061t` (representa "dat").
  - **Forma de 6 dígitos**: `\+` seguido de 6 dígitos hexadecimales. Ejemplo: `d\+000061t` (también representa "dat").


 Escapar caracteres Unicode y usando Hex
-- Crear una tabla con caracteres especiales
-- Tabla: data

```sql
-- SELECT to_hex(ascii('a')); --> 61 -> 0061 
-- U&"\0048\004f\004c\0041"
-- U&"d\+000061ta"
-- U&"d\0061ta"

CREATE TABLE U&"\0441\043B\043E\043D" (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50)
);

-- Insertar datos
INSERT INTO U&"d\0061ta" (id, nombre) VALUES (1, 'Prueba');

-- Consultar datos
SELECT * FROM U&"d\0061ta";
```


**3. Cambiar el carácter de escape**
- Por defecto, el carácter de escape es `\`. Puedes cambiarlo usando la cláusula `UESCAPE`. Ejemplo: `U&"d!0061t!+000061" UESCAPE '!'`, donde el carácter de escape es ahora `!`.


 Cambiar el carácter de escape
```sql
-- Usar un carácter de escape personalizado (!)  
-- Tabla: data
CREATE TABLE U&"d!0061ta" UESCAPE '!' ( 
    id SERIAL PRIMARY KEY,
    descripcion TEXT
);

-- Insertar datos
INSERT INTO U&"d!0061ta" (id, descripcion) VALUES (1, 'Ejemplo con escape personalizado');

-- Consultar datos
SELECT * FROM U&"d!0061ta";


postgres@test# select U&'\0063' as alfabeto_latino,  U&'\0441' as alfabeto_cirílico;
+-----------------+-------------------+
| alfabeto_latino | alfabeto_cirílico |
+-----------------+-------------------+
| c               | с                 |
+-----------------+-------------------+
(1 row)


Aunque "с" (cirílico) y "c" (latino) son caracteres completamente diferentes en términos de codificación, ¡se ven casi idénticos en muchas fuentes tipográficas! Esto genera la ilusión de que son el mismo carácter.
 
```


 
# Dirty
1. **Dirty read** se refiere a una situación en la que una transacción lee datos modificados por otra transacción que aún no ha sido comprometida

2. **Dirty Blocks**: Los bloques "dirty" son aquellos que han sido modificados pero aún no han sido escritos en disco. Esto puede ocurrir durante operaciones de lectura y escritura, donde los datos en memoria se marcan como "dirty" hasta que se sincronizan con el almacenamiento persistente.

3. **Dirty Pages**: Similar a los bloques "dirty", las páginas "dirty" son partes de la memoria que contienen datos modificados que aún no se han escrito en disco.



# Niveles de aislamiento en bases de datos:

### Read Uncommitted
- **Descripción**: segun esto permite lecturas sucias pero no es verdad, aunque pongas este valor no tendra efectos, en realidad  estara red committed ; 


### Read Committed
- **Descripción**: Las transacciones solo pueden ver los cambios realizados por otras transacciones una vez que esos cambios han sido confirmados. No permite lecturas sucias.
- **Ventajas**: Previene lecturas sucias y es más seguro.
- **Limitaciones**: Permite lecturas no repetibles, donde los datos pueden cambiar si otra transacción los modifica y confirma.

### Repeatable Read
- **Descripción**:  una transacción puede leer los mismos datos múltiples veces y siempre verá los mismos valores, incluso si otras transacciones han modificado esos datos entre lecturas.
- **Ventajas**: Previene lecturas sucias y lecturas no repetibles.
- **Limitaciones**: No previene las anomalías de escritura fantasma.

### Serializable
- **Descripción**: Este es el nivel más estricto de aislamiento. Hace que las transacciones se ejecuten de manera que el resultado sea el mismo que si se hubieran ejecutado secuencialmente, una tras otra.
- **Ventajas**: Previene todas las anomalías de concurrencia, incluyendo lecturas sucias, lecturas no repetibles y escrituras fantasma.
- **Limitaciones**: Puede ser más lento y menos eficiente debido a la necesidad de bloquear más recursos para asegurar la integridad.

 
| Nivel de Aislamiento | Lecturas Sucias | Lecturas No Repetibles | Escrituras Fantasma |
|----------------------|-----------------|------------------------|---------------------|
| Read Uncommitted     | ❌              | ❌                     | ❌                  |
| Read Committed       | ✅              | ❌                     | ❌                  |
| Repeatable Read      | ✅              | ✅                     | ❌                  |
| Serializable         | ✅              | ✅                     | ✅                  |

 
 
## Ejemplo Practico de niveles de aislamiento

### Read Uncommitted
1. **Transacción A** lee el saldo de la cuenta a las 10:00 AM y ve $100.
2. **Transacción B** deposita $50 en la cuenta a las 10:05 AM, pero aún no confirma (commit).
3. **Transacción A** lee el saldo nuevamente a las 10:10 AM y ve $150, aunque Transacción B aún no ha confirmado.
4. **Transacción B** decide revertir (rollback) el depósito a las 10:15 AM.
5. **Transacción A** ha leído datos incorrectos ($150) que no deberían haber sido visibles.

### Read Committed
1. **Transacción A** lee el saldo de la cuenta a las 10:00 AM y ve $100.
2. **Transacción B** deposita $50 en la cuenta y confirma (commit) a las 10:05 AM.
3. **Transacción A** lee el saldo nuevamente a las 10:10 AM y ve $150.
4. **Transacción B** deposita otros $50 y confirma a las 10:15 AM.
5. **Transacción A** lee el saldo nuevamente a las 10:20 AM y ve $200.
6. **Transacción A** puede ver diferentes saldos en cada lectura debido a las confirmaciones de Transacción B.

### Repeatable Read
1. **Transacción A** lee el saldo de la cuenta a las 10:00 AM y ve $100.
2. **Transacción B** deposita $50 en la cuenta y confirma (commit) a las 10:05 AM.
3. **Transacción A** lee el saldo nuevamente a las 10:10 AM y sigue viendo $100.
4. **Transacción B** deposita otros $50 y confirma a las 10:15 AM.
5. **Transacción A** lee el saldo nuevamente a las 10:20 AM y sigue viendo $100.
6. **Transacción A** no verá los cambios realizados por Transacción B hasta que termine su propia transacción.
- **Visibilidad de Cambios**: Los cambios realizados por **Transacción B** (los depósitos de $50) no serán visibles para **Transacción A** hasta que **Transacción A** termine. Una vez que **Transacción A** termina y confirma, cualquier nueva transacción que lea el saldo verá el saldo actualizado.

### Serializable
1. **Transacción A** lee el saldo de la cuenta a las 10:00 AM y ve $100.
2. **Transacción B** intenta depositar $50 en la cuenta a las 10:05 AM.
3. **Transacción A** lee el saldo nuevamente a las 10:10 AM y sigue viendo $100.
4. **Transacción B** no puede confirmar (commit) hasta que Transacción A termine.
5. **Transacción A** termina y confirma a las 10:15 AM.
6. **Transacción B** ahora puede confirmar su depósito y el saldo se actualiza a $150 a las 10:20 AM.

### Resumen Visual del Comportamiento con Tiempos

| Nivel de Aislamiento | Lectura Inicial (10:00 AM) | Acción de Transacción B (10:05 AM) | Lectura Final de Transacción A (10:10 AM) |
|----------------------|---------------------------|------------------------------------|------------------------------------------|
| Read Uncommitted     | $100                      | Deposita $50 (sin commit)          | $150                                    |
| Read Committed       | $100                      | Deposita $50 (commit)              | $150                                    |
| Repeatable Read      | $100                      | Deposita $50 (commit)              | $100                                    |
| Serializable         | $100                      | Deposita $50 (espera commit)       | $100                                    |
 
 
### Resumen Visual de Aplicaciones

| Nivel de Aislamiento | Escenarios Reales |
|----------------------|-------------------|
| Read Uncommitted     | Análisis de datos en tiempo real |
| Read Committed       | Comercio electrónico, gestión de inventario |
| Repeatable Read      | Trading de acciones, sistemas CRM |
| Serializable         | Transacciones bancarias, sistemas ERP |



# ¿Qué es ACID?

**ACID** es un acrónimo que representa cuatro propiedades fundamentales que deben cumplir las transacciones en una base de datos para garantizar su integridad y confiabilidad. Estas propiedades son:

1. **Atomicidad (Atomicity)**: Asegura que todas las operaciones dentro de una transacción se completen con éxito o ninguna lo haga. Si una parte de la transacción falla, toda la transacción se revierte.
2. **Consistencia (Consistency)**: La consistencia garantiza que cada vez que se realiza una transacción en la base de datos, esta cumpla con todas las reglas y restricciones definidas (como claves primarias, relaciones entre tablas, tipos de datos, etc.). Es decir, la base de datos siempre pasa de un estado válido a otro estado válido. Si una transacción las rompe, no se guarda nada y la base de datos sigue como estaba antes.
3. **Aislamiento (Isolation)**: Asegura que las operaciones de una transacción sean invisibles para otras transacciones hasta que se completen, evitando interferencias.
4. **Durabilidad (Durability)**: Garantiza que una vez que una transacción se ha completado, los cambios realizados son permanentes, incluso en caso de fallos del sistema..


### Aplicaciones y Estándares
- **ISO/IEC 9075**: El estándar SQL, que es utilizado por la mayoría de los RDBMS, incorpora principios ACID para asegurar la integridad de las transacciones.
- **ANSI SQL**: La American National Standards Institute (ANSI) también incluye principios ACID en sus estándares para SQL.


### ¿Por Qué es un Estándar?
- **Consistencia**: ACID proporciona un marco consistente para manejar transacciones, lo que es crucial para aplicaciones críticas donde la precisión de los datos es esencial.
- **Confiabilidad**: Asegura que las transacciones se completen correctamente o no se realicen en absoluto, lo que es vital para mantener la integridad de los datos.
- **Interoperabilidad**: La mayoría de los sistemas de gestión de bases de datos relacionales (RDBMS) como PostgreSQL, MySQL, Oracle y SQL Server implementan el modelo ACID, lo que facilita la interoperabilidad entre diferentes sistemas.


### Importancia de ACID

El modelo ACID es crucial para mantener la integridad, consistencia y confiabilidad de los datos en sistemas de bases de datos. Es especialmente importante en aplicaciones donde los datos son valiosos y los errores pueden ser costosos, como en sistemas financieros, de comercio electrónico y de gestión empresarial.

### Ventajas y Desventajas

#### Ventajas:
- **Integridad de Datos**: Asegura que los datos sean precisos y consistentes.
- **Confiabilidad**: Garantiza que las transacciones se completen correctamente o no se realicen en absoluto.
- **Seguridad**: Protege contra fallos del sistema y garantiza que los datos se mantengan seguros.
- **Consistencia**: Mantiene las reglas de integridad de la base de datos.

#### Desventajas:
- **Rendimiento**: Puede ser menos eficiente en términos de rendimiento en comparación con otros modelos, como BASE (utilizado en bases de datos NoSQL).

### Ejemplos Reales

1. **Bancos y Finanzas**: Las transacciones bancarias, como depósitos y retiros, deben ser precisas y consistentes. ACID asegura que estas operaciones se realicen correctamente.
2. **Comercio Electrónico**: En plataformas de comercio electrónico, las operaciones de compra y actualización de inventario deben ser confiables y consistentes.
3. **Sistemas de Gestión Empresarial (ERP)**: Las aplicaciones ERP utilizan ACID para manejar datos de múltiples departamentos, asegurando que las actualizaciones sean consistentes y no se interfieran entre sí

 
# Que es CI/CD 
CI/CD significa Integración Continua (CI) y Entrega/Despliegue Continuo (CD). Es una práctica fundamental en el desarrollo moderno de software que automatiza y agiliza el proceso de construcción, prueba y despliegue de aplicaciones.


### **PoC (Proof of Concept, o Prueba de Concepto)**
Es un **prototipo o demostración** que se desarrolla para comprobar si una idea, tecnología o solución es viable antes de invertir tiempo y recursos en su implementación completa. 

### 🔧 ¿Qué es CI (Integración Continua)?
La **Integración Continua** consiste en:

- Integrar cambios de código frecuentemente (varias veces al día).
- Ejecutar pruebas automáticas cada vez que se hace un cambio.
- Detectar errores rápidamente.
- Mantener el código siempre en un estado funcional.

**Herramientas comunes**: Jenkins, GitHub Actions, GitLab CI, CircleCI.

 
### 🚀 ¿Qué es CD (Entrega/Despliegue Continuo)?
Hay dos variantes:

1. **Entrega Continua** (*Continuous Delivery*):
   - El código pasa por pruebas automáticas y queda listo para ser desplegado manualmente.
   - Ideal cuando se requiere aprobación antes de ir a producción.

2. **Despliegue Continuo** (*Continuous Deployment*):
   - El código se despliega automáticamente a producción si pasa todas las pruebas.
   - No requiere intervención humana.

**Herramientas comunes**: ArgoCD, Spinnaker, Octopus Deploy, GitOps.


### 📈 Beneficios de CI/CD
- Reducción de errores humanos.
- Mayor velocidad en el desarrollo.
- Mejor calidad del software.
- Feedback rápido.
- Automatización de tareas repetitivas.

 

### 🧠 Ejemplo práctico
Imagina que estás desarrollando una API en Python:

1. Subes tu código a GitHub.
2. GitHub Actions ejecuta pruebas unitarias automáticamente en un entorno de desarrollo.
3. Si todo pasa, se genera un contenedor Docker.
4. Se despliega a un servidor en Azure o AWS sin intervención manual.

--- 


## 🧩 CQRS (Command Query Responsibility Segregation)

**¿Qué es?**  
Es un patrón que **separa las operaciones de lectura (queries)** de las **de escritura (commands)** en un sistema.

### 🛠️ ¿Por qué hacerlo?
Porque leer y escribir datos tienen necesidades distintas. Las lecturas suelen ser muchas, rápidas y optimizadas para mostrar información. Las escrituras pueden ser más complejas, con validaciones, reglas de negocio, etc.

### 🎯 Ejemplo:
Imagina una app de pedidos:

- Cuando un cliente **consulta su historial de compras**, eso es una **query**.
- Cuando **hace un nuevo pedido**, eso es un **command**.

Con CQRS, puedes tener una base de datos optimizada para lecturas (por ejemplo, una base NoSQL como Redis o Elasticsearch) y otra para escrituras (como PostgreSQL).



## 🧾 Event Sourcing

**¿Qué es?**  
En lugar de guardar solo el **estado actual** de los datos, guardas **todos los eventos que llevaron a ese estado**.

### 🛠️ ¿Por qué hacerlo?
Porque te da un historial completo de lo que ha pasado. Es como tener un "registro contable" de cada cambio.

### 🎯 Ejemplo:
En vez de guardar solo el saldo actual de una cuenta bancaria, guardas eventos como:

- "Depósito de \$100"
- "Retiro de \$50"
- "Transferencia de \$20"

Y si quieres saber el saldo, simplemente **reproduces los eventos**.


## 🧠 ¿Y si los combinas?
¡Boom! 💥 Puedes usar **Event Sourcing para las escrituras** (commands) y **una base optimizada para lecturas** (queries). Así tienes lo mejor de ambos mundos: historial completo + rendimiento en consultas.



-----

## 🔧 ¿Qué procesos en segundo plano (background) usa PostgreSQL?


| Proceso | Función principal |
|--------|-------------------|
| **Background Writer** | Escribe buffers sucios desde `shared_buffers` al disco de forma gradual. |
| **Checkpointer** | Realiza checkpoints: sincroniza todos los buffers sucios y archivos WAL al disco. |
| **WAL Writer** | Escribe los registros WAL desde `wal_buffers` al archivo WAL en disco. |
| **Autovacuum Launcher** | Inicia procesos de autovacuum para limpiar y analizar tablas. |
| **Autovacuum Worker** | Ejecuta el autovacuum en tablas específicas. |
| **Stats Collector** *(hasta PG 14)* | Recopilaba estadísticas de uso (ahora integrado en otros procesos). |
| **Logical Replication Launcher** | Maneja la replicación lógica. |
| **Archiver** | Copia los archivos WAL a un destino externo si `archive_mode` está activado. |
| **Background Worker** | Procesos personalizados que puedes definir (por ejemplo, extensiones como `pg_cron`). |


# lift-and-shift
Es una estrategia que consiste en mover una base de datos o aplicación desde su entorno actual (on-premise o local) a la nube sin realizar cambios significativos en su arquitectura o código.


--- 
# **`fillfactor`** 
Es una configuración que controla **qué porcentaje de espacio se llena en cada página de datos cuando se insertan filas**.

### **¿Cómo funciona?**
- Las tablas y los índices en PostgreSQL se almacenan en páginas de 8 KB.
- Por defecto, el **fillfactor** es **100**, lo que significa que la página se llena completamente.
- Si reduces el fillfactor (por ejemplo, a 70), PostgreSQL **deja un 30% de espacio libre** en cada página para futuras actualizaciones.

### **¿Por qué es útil?**
- Cuando actualizas una fila y esta crece (por ejemplo, por un `UPDATE` que aumenta el tamaño de la fila), si no hay espacio libre en la página, PostgreSQL debe **mover la fila a otra página**, lo que genera **fragmentación y más I/O**.
- Con un fillfactor menor, hay espacio reservado para que las filas crezcan sin moverse.

### **Valores típicos**:
- **100**: máximo aprovechamiento del espacio (bueno para tablas que casi no se actualizan).
- **70-90**: recomendado para tablas con muchas actualizaciones.

### **Cómo se configura**:
```sql
-- Al crear la tabla
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre TEXT
) WITH (fillfactor = 80);

-- O modificar una existente
ALTER TABLE clientes SET (fillfactor = 80);
```

### **Importante**:
- Cambiar el fillfactor **no afecta inmediatamente**; debes hacer un `VACUUM FULL` o `CLUSTER` para reorganizar las páginas.
- También se aplica a **índices**:
```sql
CREATE INDEX idx_clientes_nombre ON clientes(nombre) WITH (fillfactor = 90);
```





 
---
# cardinalidad
En bases de datos, **cardinalidad** se refiere al **número de elementos (filas) que existen en un conjunto o relación**. Es un concepto que se utiliza en varios contextos:

### **1. Cardinalidad en una tabla**

*   Es la cantidad total de registros que contiene una tabla.
*   Ejemplo: Si la tabla `clientes` tiene 10,000 filas, su cardinalidad es **10,000**.

### **2. Cardinalidad en relaciones (Modelo Entidad-Relación)**

*   Describe **cuántas instancias de una entidad pueden asociarse con instancias de otra entidad**.
*   Tipos comunes:
    *   **Uno a uno (1:1)**: Un registro de la tabla A se relaciona con un solo registro de la tabla B.
    *   **Uno a muchos (1:N)**: Un registro de la tabla A se relaciona con varios registros de la tabla B.
    *   **Muchos a muchos (M:N)**: Varios registros de la tabla A se relacionan con varios registros de la tabla B.

### **3. Cardinalidad en índices**

*   Indica **cuántos valores distintos hay en una columna**.
*   Ejemplo: Si en la columna `estado` solo hay 5 valores distintos (Activo, Inactivo, Pendiente, etc.), su cardinalidad es baja.
*   **Alta cardinalidad**: Muchos valores únicos (ej. columna `id_cliente`).
*   **Baja cardinalidad**: Pocos valores únicos (ej. columna `sexo`).
 
---

##   ¿Qué es la memoria compartida?

La **memoria compartida** es un mecanismo que permite que **dos o más procesos** accedan **a la misma región de memoria RAM** al mismo tiempo, **sin hacer copias** de los datos.

En lugar de que cada proceso tenga su propia copia de la información, **todos trabajan sobre los mismos datos en memoria**.


##   ¿Para qué sirve la memoria compartida?

Sirve para:

*   **Compartir datos grandes entre procesos**
*   **Reducir el uso de memoria RAM**
*   **Evitar copias innecesarias de datos**
*   **Mejorar el rendimiento y la velocidad**
*   **Permitir procesamiento paralelo eficiente**

Es especialmente útil cuando los datos son grandes y el rendimiento es crítico.

***

## ✅ ¿Por qué se usa?

Porque sin memoria compartida:

*   Cada proceso duplica los datos
*   Se usa más RAM
*   Hay más carga de CPU y disco
*   El sistema escala peor

Con memoria compartida:

*   Los datos se cargan **una sola vez**
*   Todos los procesos los reutilizan
*   El sistema es **más rápido y eficiente**


---


# DAG

## 1. ¿Qué es un DAG exactamente?

Para que un sistema sea considerado un DAG, debe cumplir con tres propiedades fundamentales:

1. **Grafo (Graph):** Es un conjunto de nodos (tareas o datos) conectados por aristas (relaciones).
2. **Dirigido (Directed):** Las conexiones tienen un sentido único. Si vas de la Tarea A a la Tarea B, hay una flecha que indica el orden. No es una relación ambigua.
3. **Acíclico (Acyclic):** Esta es la clave. **No existen ciclos o bucles.** Si empiezas en el punto A y sigues las flechas, es imposible volver al punto A.



## 2. ¿Para qué sirve una "Estrategia DAG"?

En el mundo de la ingeniería de datos y el desarrollo de software, un DAG sirve principalmente para **gestionar dependencias**.

### A. Orquestación de Datos (ETL/ELT)

Es el uso más común hoy en día (herramientas como **Apache Airflow**, **Prefect** o **dbt**).

* **Problema:** Tienes 100 tablas que transformar. La Tabla C depende de la Tabla A y la B.
* **Estrategia DAG:** El sistema dibuja el mapa de dependencias. Sabe que puede ejecutar A y B en paralelo, pero debe esperar a que ambas terminen para iniciar C. Si hubiera un ciclo (A depende de B y B depende de A), el sistema se bloquearía; el DAG evita esto por definición.

### B. Planificación de Consultas (Query Plans) en Postgres/SQL

Cuando lanzas un `EXPLAIN` en PostgreSQL, lo que ves es básicamente un árbol (que es un tipo simple de DAG).

* El motor decide: "Primero hago un *Index Scan* (Nodo 1), luego un *Hash Join* (Nodo 2)".
* El flujo de datos va desde las hojas (tablas) hacia la raíz (el resultado final) sin retroceder.

### C. Control de Versiones (Git)

Git utiliza un DAG para representar la historia de los commits. Cada commit apunta a su "padre". Las ramas y los *merges* crean una estructura de grafo dirigida hacia atrás en el tiempo, pero nunca verás un commit que sea su propio antepasado.

### D. Criptomonedas (Alternativa a Blockchain)

Sistemas como **IOTA** o **Nano** no usan una cadena lineal (Blockchain), sino un DAG. Esto permite que las transacciones se validen en paralelo, mejorando drásticamente la escalabilidad y eliminando la necesidad de "mineros" tradicionales.



## 3. Ventajas de implementar sistemas basados en DAG

| Ventaja | Descripción |
| --- | --- |
| **Paralelismo** | El sistema identifica qué nodos no tienen dependencias mutuas y los ejecuta al mismo tiempo. |
| **Recuperación de errores** | Si una tarea falla, el DAG sabe exactamente qué ramas se ven afectadas y cuáles pueden seguir ejecutándose. |
| **Trazabilidad (Linaje)** | Puedes ver exactamente de dónde viene un dato y por qué procesos pasó. |
| **Eficiencia** | No hay procesos redundantes ni esperas innecesarias si la ruta crítica está despejada. |



## 4. Ejemplo Práctico: Un Pipeline de Datos

Imagina que estás procesando logs de PostgreSQL para un reporte:

1. **Nodo A:** Extraer logs de `/var/lib/postgresql/data/log`.
2. **Nodo B:** Filtrar errores 500.
3. **Nodo C:** Contar conexiones por IP.
4. **Nodo D (Depende de B y C):** Generar reporte PDF.
5. **Nodo E (Depende de D):** Enviar por email al DBA.

El sistema sabe que si **B** falla, no tiene sentido intentar **D**, pero **C** podría terminar su trabajo.

 
---- 

# Tipo de conexiones 

## 2️⃣ Conexión usando `psql` (CLI oficial)

### 🔹 2.1 Con parámetros explícitos

```bash
# Variables de entorno (libpq)
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=appdb
export PGUSER=appuser
export PGPASSWORD=secret
export PGCLIENTENCODING=UTF8

PGCLIENTENCODING=UTF8 psql -h localhost -U appuser -d appdb
 psql -d my_dba_test  -h 10.44.1.155 -p 5432 -U postgres

```


### 🔹 2.1 Con conexion string
```bash
https://www.postgresql.org/docs/current/app-psql.html
psql "host=localhost port=5432 dbname=appdb user=appuser password=secret options='-c client_encoding=UTF8'"
 psql "dbname=my_dba_test host=10.44.1.155 user=postgres sslmode=disable"
```
 

## 3️⃣ URI / URL de conexión (`libpq` compatible)

Formato general:

```text
https://www.postgresql.org/docs/current/libpq-connect.html
postgresql://user:password@host:port/dbname?param=value
postgresql://appuser:secret@localhost:5432/appdb?options=-cclient_encoding=UTF8
```

  

## 5️⃣ JDBC (Java / Spring / Microservicios)

### 🔹 5.1 JDBC URL básica
PostgreSQL JDBC usa UTF-8 por defecto

```text

jdbc:postgresql://localhost:5432/appdb?user=appuser&password=secret
jdbc:postgresql://localhost:5432/appdb?options=-c%20client_encoding=UTF8
jdbc:postgresql://localhost:5432/nombre_bd?client_encoding=UTF8
jdbc:postgresql://localhost:5432/appdb?charSet=UTF8
```
 
 
### 🔹 6.1 Connection string ODBC

```text
Driver={PostgreSQL Unicode};
Server=localhost;
Port=5432;
Database=appdb;
Uid=appuser;
Pwd=secret;
ClientEncoding=UTF8;
```

 


----



# pg_tem_ y pg_toast_temp_

## 1. ¿Por qué tienen números (`pg_temp_N` / `pg_toast_temp_N`)?

PostgreSQL es un sistema multi-proceso. Cada vez que una aplicación se conecta a la base de datos, el proceso principal (`postmaster`) le asigna un **Backend ID** único a esa sesión.

* **`pg_temp_54`**: Es el esquema temporal privado para la sesión con el ID 54. Solo esa sesión puede ver y usar las tablas ahí creadas.
* **`pg_toast_temp_54`**: Si una tabla temporal en la sesión 54 tiene columnas muy grandes (como el `TEXT` o `BYTEA` que mencionaste), PostgreSQL necesita usar la técnica **TOAST**. Como la tabla es temporal, su "almacén de desbordamiento" (TOAST) también debe ser temporal y privado para esa sesión.

**Resumen:** Los números corresponden al ID del proceso que los creó para evitar colisiones entre cientos de usuarios conectados simultáneamente.

---

## 2. El proceso de limpieza: ¿Es automático?

**Teóricamente, sí.** En condiciones normales:

1. Cuando la sesión termina (el usuario se desconecta), PostgreSQL ejecuta un comando interno de limpieza.
2. Borra las tablas dentro de esos esquemas.
3. El esquema se queda vacío y "marcado" para ser reutilizado por el siguiente proceso que herede ese ID.

### El problema: ¿Por qué no se borran?

Si tu base de datos se **cayó por falta de espacio** o si hubo cierres forzados (`kill -9` a procesos de Postgres), los procesos no tuvieron oportunidad de limpiar su basura. Esto genera **"Temporary File Orphans"** (archivos huérfanos).

* **Los esquemas no desaparecen:** Ver los esquemas en `information_schema.schemata` es normal; PostgreSQL prefiere mantener la estructura del esquema vacía para reutilizarla luego.
* **Lo que importa es el contenido:** Si el disco está lleno, no es por el "nombre" del esquema, sino por los archivos físicos en el disco dentro de `/sysx/data/base/[DB_ID]/`.

---

## 3. Estrategia de depuración para `/sysx/data`

Si sospechas que estos esquemas temporales están devorando tu espacio tras la caída, sigue estos pasos como experto:

### A. Identificar el espacio real en temporales

No mires solo el nombre del esquema, mira cuánto pesan en disco. Ejecuta esto para ver qué base de datos tiene más "basura" temporal:

```sql
SELECT datname, pg_size_pretty(pg_database_size(datname)) 
FROM pg_database ORDER BY pg_database_size(datname) DESC;

```

### B. Limpieza Manual Segura

Si la base de datos ya arrancó, **no borres archivos a mano** todavía. Usa las herramientas del motor:

1. **Reiniciar el servicio:** Al iniciar, PostgreSQL intenta detectar archivos temporales huérfanos de la sesión anterior y los marca para eliminación.
2. **DROP CASCADE (Cuidado):** Si ves esquemas numerados de sesiones que sabes que ya no existen (por ejemplo, de hace días), podrías intentar borrarlos, pero **PostgreSQL generalmente no te deja borrar `pg_temp_n**` si el sistema cree que el ID podría estar activo.
3. **Localizar archivos `t_` en el sistema de archivos:**
Ve a tu directorio de datos y busca archivos que empiecen con `t` seguido de números. Estos son los archivos físicos de tablas temporales.
```bash
find /sysx/data/base/ -name "t*_*"

```


* Si Postgres está **detenido**, es seguro mover o borrar estos archivos.
* Si Postgres está **encendido**, solo bórralos si estás seguro de que no hay sesiones activas.



### C. El comando mágico para el espacio "fantasma"

A veces el espacio no se libera porque el sistema operativo mantiene el archivo abierto aunque Postgres lo haya borrado. Si después de borrar archivos `df -h` sigue marcando 100%, ejecuta:

```bash
lsof +L1 | grep delete

```

Esto te mostrará procesos que tienen "secuestrado" el espacio de archivos ya borrados. Tendrás que reiniciar esos procesos o el servicio de Postgres.

---

## 4. Recomendación de Experto para tu Configuración

Dado que tienes `/sysx/data` separado, para evitar que las tablas temporales de un usuario descuidado (que haga un `SELECT * INTO TEMP ...` de una tabla de 50GB) te llenen el disco principal, te sugiero:

1. **Mover los temporales a otro disco:** Puedes crear un Tablespace en un cuarto disco (o incluso en `/pg_log` si tienes espacio de sobra ahí) y configurar:
```sql
-- En postgresql.conf
temp_tablespaces = 'nombre_de_tu_tablespace_en_otro_disco'

```

### para que sirve el directorio pgsql_tmp ? 

**`pgsql_tmp` es el "desagüe" de la memoria RAM de tu servidor.**

Mientras que los esquemas `pg_temp` que vimos antes guardan **tablas temporales** (datos estructurados que tú creas), la carpeta `pgsql_tmp` guarda **archivos temporales de ejecución**.

Aquí tienes el detalle técnico de por qué existe y por qué puede estar llenando tu disco `/sysx/data`.
 

## 1. ¿Para qué sirve exactamente?

PostgreSQL intenta realizar todas las operaciones (ordenamientos, uniones de tablas, etc.) en la memoria RAM, específicamente en el espacio asignado por el parámetro `work_mem`.

Cuando una consulta es tan grande o compleja que supera el `work_mem` asignado, PostgreSQL no puede detenerse, así que **"desborda" el excedente al disco duro**. Esos archivos de desborde se guardan en la carpeta `pgsql_tmp`.

### Operaciones que generan archivos en `pgsql_tmp`:

* **External Sorts:** Cuando haces un `ORDER BY` de millones de filas que no caben en RAM.
* **Hash Joins:** Al cruzar tablas gigantescas.
* **Materialize:** Operaciones intermedias de consultas muy complejas.
* **Creación de índices:** El proceso de `CREATE INDEX` requiere mucho espacio temporal para ordenar las claves antes de insertarlas en el árbol final.
 

## 2. ¿Por qué es un peligro para tu disco `/sysx/data`?

El problema principal es que estos archivos pueden crecer de forma explosiva:

1. **Consultas ineficientes:** Un programador lanza un `SELECT *` con un `JOIN` mal hecho (producto cartesiano) y Postgres genera un archivo temporal de 200GB intentando resolverlo.
2. **Múltiples conexiones:** Si tienes 50 usuarios haciendo operaciones pesadas al mismo tiempo, cada uno crea sus propios archivos en `pgsql_tmp`.
3. **Archivos Huérfanos:** Si el proceso de la base de datos se cae (como te pasó a ti), PostgreSQL no siempre tiene tiempo de borrar estos archivos. Al reiniciar, esos archivos se quedan ahí ocupando espacio pero ya no sirven para nada.
 

## 3. Diferencia clave: `pg_temp` vs `pgsql_tmp`

Es muy común confundirlos, pero funcionan distinto:

| Característica | Esquema `pg_temp_N` | Carpeta `pgsql_tmp` |
| --- | --- | --- |
| **Contenido** | **Tablas temporales** creadas explícitamente (`CREATE TEMP TABLE`). | **Archivos de trabajo** creados por el motor (Sorts, Joins). |
| **Visibilidad** | Los ves con un `\dt` o consultando esquemas. | Solo los ves a nivel de Sistema Operativo (Linux). |
| **Ubicación** | Dentro de los archivos de datos de la base. | En subcarpetas específicas llamadas `pgsql_tmp`. |
| **Persistencia** | Duran lo que dure la sesión del usuario. | Deberían borrarse en cuanto termine la consulta. |
 

## 4. ¿Cómo limpiar y controlar esto?

### Limpieza de emergencia (Postgres Apagado)

Si tu base de datos está caída y necesitas espacio **YA**, puedes borrar el contenido de estas carpetas con total seguridad:

```bash
# Buscar todas las carpetas pgsql_tmp y vaciarlas
find /sysx/data -name "pgsql_tmp" -type d -exec rm -rf {}/* \;

 
### Prevención (Postgres Encendido)

Para evitar que esto vuelva a llenar tu disco `/sysx/data`, te recomiendo estas dos configuraciones en tu `postgresql.conf`:

1. **Limitar el tamaño de archivos temporales:**
Esto matará cualquier consulta que intente crear un archivo temporal más grande de, por ejemplo, 10GB, protegiendo la salud del disco.
```sql
temp_file_limit = 10GB
 

2. **Moverlos de disco (Tablespace Temporal):**
Como tienes tres discos, si el disco `/pg_log` tiene mucho espacio libre, podrías crear ahí una carpeta para los temporales y decirle a Postgres que los use:
```sql
-- En el SO
mkdir /pg_log/temp_space
chown postgres:postgres /pg_log/temp_space

-- En SQL
CREATE TABLESPACE fast_temp LOCATION '/pg_log/temp_space';
ALTER SYSTEM SET temp_tablespaces = 'fast_temp';
SELECT pg_reload_conf();

```


 
Esto garantiza que si `/sysx/data` se llena, será por **datos reales** y no por procesos temporales mal optimizados.

 
--- 

# postmaster 

### 1. ¿Qué pasó con `postmaster`?

históricamente, `postmaster` era el nombre del binario que actuaba como el proceso "padre" o supervisor. Su función era escuchar nuevas conexiones, hacer el *fork* de procesos hijos para cada cliente y gestionar la memoria compartida.

Sin embargo, desde hace muchas versiones, **`postmaster` y `postgres` son exactamente el mismo binario**. Si te fijas en tus salidas de la versión 11 a la 15:
`postmaster -> postgres`

Es un **enlace simbólico (symlink)**. El software detecta cómo fue invocado:

* Si lo llamas como `postmaster`, asume que quieres levantar el servidor.
* Si lo llamas como `postgres`, hace lo mismo (siempre que pases los parámetros adecuados como `-D`).

### 2. ¿Por qué ya no aparece en la 16 y 17?

A partir de las versiones más recientes (específicamente en los empaquetamientos modernos para RHEL/CentOS/Rocky), la comunidad y los mantenedores de los repositorios PGDG decidieron empezar a **eliminar el enlace simbólico `postmaster**`.

**Las razones son simples:**

1. **Limpieza:** Se quiere estandarizar todo bajo el nombre `postgres`.
2. **Obsolescencia:** El término "postmaster" se considera legado. Toda la documentación oficial ahora apunta a usar `postgres` o `pg_ctl`.
3. **Seguridad/Claridad:** Evita confusiones con otros servicios de correo (como el alias `postmaster` de SMTP).

### 3. ¿Significa esto que el proceso ya no existe?

**No.** El proceso supervisor (el padre de todos) sigue existiendo y funcionando exactamente igual, pero ahora se llama simplemente `postgres`.

Si haces un `ps -fea | grep postgres` en tu versión 17, verás que el proceso principal (el que tiene el PID más bajo y es padre de los demás) aparece así:
`/usr/pgsql-17/bin/postgres -D /ruta/data`

### En resumen:

* **Antes de la v16:** Te creaban el acceso directo `postmaster` por pura compatibilidad histórica.
* **v16 y v17:** Ya no crean el acceso directo; esperan que uses directamente el binario `postgres`.
* **Funcionalidad:** Es idéntica. El binario `postgres` de la versión 17 hace el mismo trabajo de "postmaster" que hacía el de la versión 11.

 
