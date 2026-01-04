# Objetivo
Es aprender todo lo que podemos hacer solo con la base de datos 

# Ejemplos 

### Ver a que base de datos estoy conectado
          select  current_database();

### Consutar los nombres de las base de datos:
     \l  
     select datname from pg_database;

### Crear una base de datos:
```sql
createdb -p 5432 mytestdba -E "UTF8" -O postgres -T template0

-- [NOTA] si no especificas el template, se basara en el template1 para crear la nueva Base de datos.
    CREATE DATABASE "mytestdba" WITH TEMPLATE = template0 ENCODING = 'SQL_ASCII' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US';
    
    **Parametros adicionales que le puedes agregar en el with**
       OWNER = postgesql
       ENCODING = 'UTF8'    Define el conjunto de caracteres que se usa para almacenar datos en la base de datos. Afecta cómo se
          convierten los caracteres a bytes y viceversa.

       LC_CTYPE = 'en_US.UTF-8'; especifica las reglas de clasificación de caracteres (mayúsculas/minúsculas) se consideran
                    letras, números, espacios, puntuación, etc. y afecta a las operaciones de búsqueda y comparación.

       LC_COLLATE = 'en_US.UTF-8'  determina cómo se ordenan y comparan las cadenas de caracteres en consultas y
                    operaciones de ordenamiento. ORDER BY , Comparaciones (<, >, =) , Funciones de texto (MIN, MAX, DISTINCT, etc.)

       TABLESPACE = pg_default
       CONNECTION LIMIT = -1;  --- El -1 quiere decir que son conexiones elimitadas

********************************

 
## 2. Encoding (Codificación): ¿Cómo se guarda en el disco?

El **Encoding** es el mapa que dice: "Este número binario equivale a este glifo (letra)".

* **UTF-8 (El estándar de facto en Postgres):** Es una codificación de longitud variable. Los caracteres básicos ocupan 1 byte, pero los complejos (emojis, japonés) pueden ocupar hasta 4.
* **Importancia en Arquitectura:** Si el `client_encoding` (lo que envía la aplicación) no coincide con el `server_encoding` (lo que guarda la base de datos), los datos se corromperán.
 
## 3. LC_CTYPE: La Identidad de los Caracteres

Este concepto suele confundirse con el encoding, pero es distinto. **CTYPE** (Character Classification) define las propiedades de los caracteres.

* **¿Para qué sirve?** Determina qué es una letra, qué es un número, qué es una mayúscula y qué es una minúscula.
* **Impacto en Postgres:** Funciones como `UPPER(texto)`, `LOWER(texto)` o expresiones regulares dependen de CTYPE. Sin un CTYPE correcto (por ejemplo, configurado como `C` o `POSIX`), Postgres podría no saber que la "Á" es la mayúscula de la "á".
 
## 4. Collation (Colación): La Regla de Ordenamiento

Si el Encoding define cómo se guarda, la **Collation** define cómo se **compara** y se **ordena**.

* **El Problema:** ¿La "CH" va después de la "C" o después de la "H"? ¿La "ñ" va después de la "n" o al final del alfabeto? ¿"A" es igual a "a" (Case Insensitive)?
* **En Postgres:** La colación es crítica para los índices. Si cambias la colación de una columna, el orden del índice cambia por completo.
* **Ejemplo:** En una colación `es_ES` (España), el orden será distinto a una colación `C` (orden binario por número de código).


 

/******************** TIPOS DE ENCODING ********************\
### ❌ Desventajas de usar `SQL_ASCII`:

#### 1. **Sin validación de caracteres**
- PostgreSQL **no valida los datos de texto** que se insertan. Puedes guardar cualquier byte, incluso si no representa un carácter válido.
- Esto puede provocar **datos corruptos** o ilegibles si se mezclan codificaciones (por ejemplo, UTF-8 y Latin1).

#### 2. **Incompatibilidad con funciones de texto**
- Funciones como `LIKE`, `ILIKE`, `REGEXP`, `to_tsvector`, `to_tsquery`, `substring`, etc., pueden comportarse de forma errática o incorrecta.
- No se puede hacer búsqueda semántica ni ordenamiento correcto si hay caracteres especiales.

#### 3. **Problemas con clientes JDBC, Python, etc.**
- Los drivers modernos (JDBC, psycopg2, etc.) esperan codificaciones como UTF-8. Si la base está en `SQL_ASCII`, **pueden fallar al conectarse** o mostrar errores de codificación.

#### 4. **No se puede cambiar la codificación**
- PostgreSQL **no permite cambiar la codificación de una base de datos existente**. La única solución es crear una nueva base con codificación adecuada y migrar los datos.

#### 5. **Riesgo de errores silenciosos**
- Puedes insertar datos con codificación incorrecta sin que el sistema lo detecte, lo que puede causar errores al exportar, visualizar o procesar los datos.

#### 6. **No apto para aplicaciones multilingües**
- Si tu aplicación maneja nombres, descripciones o textos en varios idiomas, `SQL_ASCII` no es viable.


1. **UTF-8**:
   - **Recomendado**: Es ampliamente utilizado y compatible con una amplia gama de caracteres.
   - Almacena caracteres Unicode y es eficiente en términos de espacio.
   - Adecuado para aplicaciones multilingües y sitios web internacionales.

2. **LATIN1 (ISO 8859-1)**:
   - Utilizado principalmente en Europa occidental.
   - Compatible con caracteres en inglés, alemán, francés, español, etc.
   - No admite caracteres Unicode.

3. **LATIN2 (ISO 8859-2)**:
   - Utilizado en Europa central y del este.
   - Incluye caracteres adicionales como letras acentuadas y diacríticas.
   - No admite caracteres Unicode.

4. **EUC_JP**:
   - Codificación extendida UNIX para japonés.
   - Adecuada para almacenar texto en japonés.

5. **KOI8R**:
   - Utilizado para el ruso (cirílico).
   - No admite caracteres Unicode.


************** COLLATE *****
LC_COLLATE = 'C'
Ordenamiento rápido: Usa el orden binario de los bytes, lo que es más rápido que aplicar reglas lingüísticas. Sin sensibilidad lingüística: No respeta reglas de idioma. Por ejemplo, en español, 'ñ' debería ir después de 'n', pero con 'C' no se respeta. No distingue mayúsculas/minúsculas como lo haría un collation regional. Ideal para datos técnicos o identificadores, pero no recomendado para texto en idiomas naturales.
Cuándo usar 'C' -> Bases de datos técnicas (logs, identificadores, claves). Cuando el rendimiento es más importante que el orden lingüístico. Cuando no se necesita ordenamiento por idioma.



```

### Cambiar el nombre a una base de datos:
    ALTER DATABASE "mytestdba" RENAME TO "myoldtestdba";

## Borrar una base de datos 
**Es importante que cuando se borre una base de datos no este nadie conectado, y para esto puede usar metodos de monitoreo para validar primero que no este nadie conectado**

        Drop databases "mydbatest"

### Ver el limite de conexiones que se permiten por Base de datos:
        select datname,datconnlimit from pg_database; -- si es -1 es ilimitado, si tiene algún número se especificó un límite  

### Ver el tamaño de la base de datos:

-  **ver el tamaño y una descripción más completa de la base de datos**
    - \l+ 

- **ver el tamaño de todas las base de datos :**
    - select * from (SELECT  datname, pg_size_pretty(pg_database_size( datname)) AS size, (pg_stat_file('base/'||oid ||'/PG_VERSION')).modification as Fecha_Creacion FROM pg_database)a order by size;

- **ver especificamente una base de datos :**
    - SELECT  datname, pg_size_pretty(pg_database_size( datname)) AS size FROM pg_database where datname = 'mydbatest' ;
 

### Cambiar la ruta de archivo, donde se guarda la base de datos:
        ALTER DATABASE mydbatest SET TABLESPACE my_tablespace_test;

 ## saber el tipo de encoding 
        select datname, pg_encoding_to_char(encoding)  from pg_database;
        SHOW server_encoding;
        show client_encoding;
        SHOW lc_messages;
