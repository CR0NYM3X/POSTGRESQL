


### 📘 Tabla: `diccionario`

```sql
DROP TABLE diccionario;
CREATE TABLE diccionario (
    palabra TEXT NOT NULL
);

INSERT INTO diccionario (palabra)
VALUES 
    ('buscar'),
    ('buscado'),
    ('buscador'),
    ('buscando'),
    ('busca'),
    ('búsqueda'),
    ('buscón'),
    ('buscaba'),
    ('busqué'),
    ('busquemos'),
    ('buscáis'),
    ('busquen'),
    ('busco'),
    ('busquéis'),
    ('buscaste'),
    ('buscamos'),
    ('buscaban'),
    ('buscador'),
    ('buscadores'),
    ('buscadora'),
    ('buscadoras');

select * FROM diccionario;
```



# 🔍 1. Usar `ILIKE` 

Se usa para coincidencia parcial (búsqueda básica)

```sql

-- Obtendran 0 resultados ya que no hay ninguna palabra que dentro de su texto diga buscada
SELECT palabra FROM diccionario WHERE palabra ILIKE '%buscada%';

```

Esto busca cualquier palabra que contenga la cadena `"buscada"` sin importar mayúsculas/minúsculas.




# 🧠 2. Usar `SIMILARITY()`
requiere de  la extensión `pg_trgm` y sirve para (búsqueda por similitud)

### 🔍 ¿Cómo funciona `similarity`?

Internamente, PostgreSQL:
1. **Divide cada texto en trigramas** (grupos de 3 caracteres).
2. **Calcula la intersección y la unión** de los trigramas de ambos textos.
3. **Aplica la fórmula de similitud**:

$$
\text{similarity}(A, B) = \frac{|\text{trigramas comunes}|}{|\text{trigramas totales (unión)}|}
$$

Este valor retorna un decimal entre **0** (nada en común) y **1** (idénticos).

### ¿Cómo interpretar los resultados?

| Similitud | Interpretación |
|-----------|----------------|
| 0.9 - 1.0 | Muy similares o casi iguales |
| 0.7 - 0.9 | Bastante similares |
| 0.4 - 0.7 | Algo similares |
| 0.0 - 0.4 | Poco o nada similares |

### Paso 1: Activar la extensión
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### Paso 2: Buscar palabras similares
```sql
SELECT palabra, similarity(palabra, 'buscada') AS similitud
FROM diccionario
WHERE palabra % 'buscada'  -- operador de similitud
ORDER BY similitud DESC
LIMIT 5;

+----------+------------+
| palabra  | similitud  |
+----------+------------+
| buscado  |        0.6 |
| busca    |  0.5555556 |
| buscador | 0.54545456 |
| buscador | 0.54545456 |
| buscar   |        0.5 |
+----------+------------+
```

Esto te da las palabras más parecidas a lo que el usuario escribió, ordenadas por similitud.

### Puedes ajustar el umbral mínimo para que el operador % funcione:
```
SET pg_trgm.similarity_threshold = 

postgres@postgres# select name,setting from pg_settings where name ilike '%trgm%';
+------------------------------------------+---------+
|                   name                   | setting |
+------------------------------------------+---------+
| pg_trgm.similarity_threshold             | 0.3     |
| pg_trgm.strict_word_similarity_threshold | 0.5     |
| pg_trgm.word_similarity_threshold        | 0.6     |
+------------------------------------------+---------+
(3 rows)
```




## 🧪 3. Usar `LEVENSHTEIN()` 

## 🔢 ¿Qué es la distancia de Levenshtein?

Es una **medida de diferencia** entre dos cadenas de texto. Representa el **número mínimo de operaciones necesarias** para transformar una cadena en otra. Las operaciones permitidas son:

1. **Inserción** de un carácter.
2. **Eliminación** de un carácter.
3. **Sustitución** de un carácter.



### 📊 Ejemplo práctico

Comparando `'gato'` con `'pato'`:

- Cambiar `'g'` por `'p'` → 1 sustitución.

**Distancia de Levenshtein = 1**



### 🔁 Flujo de la función

La función sigue estos pasos:

1. **Inicializa una matriz** de tamaño `(longitud de cadena A + 1) x (longitud de cadena B + 1)`.
2. **Llena la primera fila y columna** con valores incrementales (representan inserciones o eliminaciones).
3. **Compara cada carácter** de ambas cadenas.
4. **Calcula el costo mínimo** entre:
   - Insertar un carácter.
   - Eliminar un carácter.
   - Sustituir un carácter (si son diferentes).
5. **Llena la matriz** con los valores mínimos en cada paso.
6. **El valor final** en la esquina inferior derecha de la matriz es la distancia de Levenshtein.



### 🧠 ¿Para qué sirve o Cuándo usar levenshtein?

- **Corrección ortográfica**: sugerir palabras similares.
- **Búsqueda difusa o Sugerencias de texto**: encontrar coincidencias aproximadas.
- **Comparación de nombres, direcciones, etc.** en bases de datos.


### Paso 1: Activar la extensión
```sql
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
```

### Paso 2: Buscar por distancia de edición
```sql
SELECT palabra, levenshtein(palabra, 'buscada') AS distancia
FROM diccionario
ORDER BY distancia ASC
LIMIT 5;
```
 
 
La forma **más avanzada y precisa** de hacer búsqueda de palabras similares en PostgreSQL —ideal para una página web tipo buscador






--- 

# Usar soundex o Metaphone
Estos utiliza la Comparación fonética y requiere de la extensión fuzzystrmatch


## 🔊 ¿Cómo funciona?

En lugar de comparar letras o trigramas como en la comparación léxica, la comparación fonética convierte las palabras en **códigos fonéticos** que representan cómo suenan. Luego compara esos códigos.

 

### 🧰 Algoritmos comunes

1. **Soundex**
   - Convierte palabras en un código de 4 caracteres basado en su sonido.
   - Ejemplo: `'Ruiz'` y `'Ruis'` → mismo código Soundex.
   - Muy usado en bases de datos como SQL Server y también disponible en PostgreSQL.

2. **Metaphone / Double Metaphone**
   - Más avanzado que Soundex.
   - Considera reglas fonéticas del inglés.
   - Puede generar dos códigos por palabra (por ejemplo, para nombres extranjeros).

3. **Cologne Phonetic (Kölner Phonetik)**
   - Adaptado para el idioma alemán.

 

### 📘 Ejemplo en PostgreSQL con `Soundex`

```sql
SELECT palabra
FROM diccionario
WHERE soundex(palabra) = soundex('ruis');
```

Esto devolvería palabras que suenan como `'ruis'`, aunque estén escritas diferente.

 

### 🧠 ¿Cuándo usar comparación fonética?

- Búsqueda de nombres en bases de datos (por ejemplo, `'Jon'`, `'John'`, `'Jhon'`).
- Corrección de errores de escritura por pronunciación.
- Sistemas de búsqueda que deben tolerar errores humanos.

 
 
 
La diferencia entre **Metaphone** y **Soundex** radica en la **precisión fonética**, el **idioma para el que fueron diseñados**, y la **forma en que codifican las palabras**. Aquí te explico cada uno:


## 🔍 Soundex

### ✅ Características:
- **Diseñado para inglés**.
- Convierte palabras en un código de 4 caracteres:
  - La primera letra se conserva.
  - Las siguientes letras se convierten en números según grupos fonéticos.
  - Se eliminan vocales y letras repetidas.

### 📊 Ejemplo:
- `'Ruiz'` → `R200`
- `'Ruis'` → `R200`  
  → **Coinciden**, porque suenan igual.

### ⚠️ Limitaciones:
- Muy básico.
- No distingue bien entre sonidos similares complejos.
- No funciona bien con nombres no ingleses.

 

## 🔍 Metaphone

### ✅ Características:
- **Más avanzado que Soundex**.
- Considera reglas fonéticas más precisas del inglés.
- Codifica sonidos como `'F'`, `'K'`, `'S'`, `'X'`, etc.
- Elimina letras mudas y agrupa sonidos similares.

### 📊 Ejemplo:
- `'Ruiz'` → `RS`
- `'Ruis'` → `RS`  
  → También coinciden, pero con mejor precisión fonética.

### 🧠 Ventajas:
- Más preciso para nombres y palabras con sonidos complejos.
- Mejora la búsqueda fonética en bases de datos.

 

## 🆚 Comparación directa

| Característica        | Soundex         | Metaphone        |
|-----------------------|------------------|------------------|
| Precisión fonética    | Baja              | Alta              |
| Longitud del código   | Fija (4 caracteres) | Variable         |
| Idioma principal      | Inglés            | Inglés            |
| Manejo de letras mudas| No                | Sí                |
| Uso en bases de datos | SQL Server, PostgreSQL | PostgreSQL, NLP |


### 🔊 Soundex
Esto busca palabras que **suenan como** `'buscada'` según el algoritmo Soundex.

```sql
SELECT palabra, soundex(palabra) AS soundex_code
FROM diccionario
WHERE soundex(palabra) = soundex('buscada');
```
 
### 🧠 Metaphone
Esto busca palabras con **códigos fonéticos similares** usando Metaphone (hasta 10 caracteres).

```sql
SELECT palabra, metaphone(palabra, 10) AS metaphone_code
FROM diccionario
WHERE metaphone(palabra, 10) = metaphone('buscada', 10);
```

---



----

# **Full Text Search (FTS)** en PostgreSQL; 


## ⚙️ 2. Crear columna para `tsvector` (opcional pero recomendado)

```sql

-- Existe la opcion de no agregar una columna extra como palabra_vector y mejor dejarle el trabajo a el index para que  guardar toda la información.
-- ALTER TABLE diccionario ADD COLUMN palabra_vector tsvector GENERATED ALWAYS AS ( to_tsvector('spanish', palabra) ) STORED;

```



## 🚀 3. Crear índice para búsqueda rápida

```sql
CREATE INDEX idx_diccionario_tsv ON diccionario USING GIN (to_tsvector('spanish', palabra));

-- Esta se usa en caso de de generar columna extra con GENERATED
-- CREATE INDEX idx_diccionario_tsv ON diccionario USING GIN (palabra_vector);

```

Este índice permite búsquedas eficientes con `@@`.



## 🔍 4. Consultas con Full Text Search

### A. Búsqueda básica con `@@`

```sql
SELECT palabra
FROM diccionario
WHERE to_tsvector('spanish', palabra) @@ to_tsquery('spanish', 'buscado');
```

### B. Búsqueda con operadores lógicos

```sql
SELECT palabra
FROM diccionario
WHERE to_tsvector('spanish', palabra) @@ to_tsquery('spanish', 'buscar & rápido');
```

### C. Búsqueda con prefijos (`:*`)

```sql
SELECT palabra
FROM diccionario
WHERE to_tsvector('spanish', palabra) @@ to_tsquery('spanish', 'busc:*');
```

Esto encuentra palabras que **empiezan con "busc"**.



## 🧠 Funciones más usadas en FTS

| Función | Descripción |
|--------|-------------|
| `to_tsvector('spanish', texto)` | Convierte texto en vector de búsqueda. |
| `to_tsquery('spanish', query)` | Convierte texto en consulta de búsqueda. |
| `plainto_tsquery('spanish', texto)` | Similar a `to_tsquery`, pero más simple. |
| `ts_rank(tsvector, tsquery)` | Calcula relevancia de coincidencias. |
| `ts_headline('spanish', texto, tsquery)` | Resalta coincidencias en el texto. |



### 📊 Ejemplo con `ts_rank`

```sql
SELECT palabra, ts_rank(to_tsvector('spanish', palabra), to_tsquery('spanish', 'buscador')) AS relevancia
FROM diccionario
WHERE to_tsvector('spanish', palabra) @@ to_tsquery('spanish', 'buscador')
ORDER BY relevancia DESC;
```
 
 
  

## 🔄 Flujo semántico de `to_tsvector` y `to_tsquery`

### 🔸 `to_tsvector('idioma', texto)`
**¿Qué hace?**
1. **Tokeniza** el texto (lo divide en palabras).
2. **Normaliza** las palabras (quita acentos, convierte a minúsculas).
3. **Elimina stopwords** (palabras comunes como “el”, “de”, “y”).
4. **Devuelve un vector** con las palabras significativas y sus posiciones.

**Ejemplo:**
```sql
SELECT to_tsvector('spanish', 'La búsqueda de datos es importante');
-- Resultado: 'busqueda':2 'dato':3 'importante':5
```



### 🔸 `to_tsquery('idioma', consulta)`
**¿Qué hace?**
1. **Interpreta la consulta** como una expresión lógica de búsqueda.
2. **Tokeniza y normaliza** igual que `to_tsvector`.
3. **Devuelve una estructura de búsqueda** que puede usarse con `@@`.

**Ejemplo:**
```sql
SELECT to_tsquery('spanish', 'busqueda & datos');
-- Resultado: 'busqueda' & 'dato'
```



### 🔁 ¿Cómo se conectan?

```sql
SELECT texto
FROM tabla
WHERE to_tsvector('spanish', texto) @@ to_tsquery('spanish', 'busqueda & datos');

  
  SELECT to_tsvector('spanish', 'buscando'); -> 'busc':1 
  SELECT to_tsvector('spanish', 'buscando palabras en el texto'); --> 'busc':1 'palabr':2 'text':5
  
  select to_tsquery('spanish', 'buscado & biscado'); --> 'busc' & 'bisc' 
  SELECT plainto_tsquery('spanish', 'traducter'); -->  'traduct' 
 
  
  -- el numero que esta aun lado de la palabra es la posición 
  1.- buscando
  2.- palabras
  3.- en
  4.- el
  5.- texto
  
```

- `to_tsvector(...)` convierte el texto de la tabla en un vector.
- `to_tsquery(...)` convierte la consulta en una expresión lógica.
- El operador `@@` verifica si el vector **cumple la condición semántica** de la consulta.



  

 --- 
 
 
  
### 🛠️ Script SQL: Crear tabla e insertar registros

```sql
CREATE TABLE articulos (
    id SERIAL PRIMARY KEY,
    titulo TEXT,
    resumen TEXT,
    contenido TEXT
);

INSERT INTO articulos (titulo, resumen, contenido) VALUES
('Seguridad en bases de datos', 'Técnicas de protección de datos', 'La configuración de seguridad en bases de datos es esencial para proteger la información confidencial.'),
('Configuración avanzada de PostgreSQL', 'Ajuste de parámetros de rendimiento', 'La configuración de PostgreSQL permite optimizar el rendimiento y la seguridad del sistema.'),
('Introducción a la seguridad informática', 'Conceptos básicos de ciberseguridad', 'La seguridad informática incluye prácticas como el uso de firewalls, antivirus y políticas de acceso.'),
('Bases de datos distribuidas', 'Distribución de datos y seguridad', 'Las bases de datos distribuidas requieren una configuración cuidadosa para garantizar la seguridad y la integridad.'),
('Auditoría de seguridad en sistemas', 'Auditoría en entornos críticos', 'Una auditoría de seguridad permite identificar vulnerabilidades en la configuración de sistemas.'),
('Optimización de consultas SQL', 'Mejorar el rendimiento de las consultas', 'La optimización de consultas SQL puede reducir el tiempo de respuesta y mejorar la eficiencia del sistema.'),
('Seguridad en redes empresariales', 'Protección de infraestructura de red', 'La seguridad en redes empresariales incluye segmentación, monitoreo y control de acceso.'),
('Configuración de firewalls', 'Uso de firewalls en seguridad', 'Los firewalls permiten controlar el tráfico de red y proteger los sistemas contra accesos no autorizados.'),
('Gestión de usuarios en bases de datos', 'Control de acceso y privilegios', 'La gestión de usuarios en bases de datos es clave para mantener la seguridad y evitar accesos indebidos.'),
('Cifrado de datos en tránsito', 'Protección de datos durante la transmisión', 'El cifrado de datos en tránsito asegura que la información no sea interceptada por terceros.'),
('Seguridad en aplicaciones web', 'Prevención de ataques comunes', 'La seguridad en aplicaciones web incluye protección contra inyecciones SQL, XSS y CSRF.'),
('Monitoreo de sistemas', 'Supervisión continua de seguridad', 'El monitoreo de sistemas permite detectar actividades sospechosas y responder rápidamente a incidentes.'),
('Configuración de roles en PostgreSQL', 'Asignación de permisos y roles', 'La configuración de roles en PostgreSQL permite definir permisos específicos para cada usuario.'),
('Auditoría de accesos', 'Registro de actividades de usuarios', 'La auditoría de accesos permite rastrear quién accede a qué recursos y cuándo.'),
('Seguridad en la nube', 'Protección de datos en entornos cloud', 'La seguridad en la nube requiere cifrado, autenticación fuerte y monitoreo constante.'),
('Configuración de backups seguros', 'Respaldo y recuperación de datos', 'Los backups seguros garantizan la disponibilidad de datos ante fallos o ataques.'),
('Seguridad en dispositivos móviles', 'Protección de datos en smartphones', 'La seguridad en dispositivos móviles incluye cifrado, autenticación y control remoto.'),
('Pruebas de penetración', 'Evaluación de vulnerabilidades', 'Las pruebas de penetración permiten identificar debilidades en la configuración de seguridad.'),
('Seguridad en entornos virtualizados', 'Protección de máquinas virtuales', 'La seguridad en entornos virtualizados requiere aislamiento, monitoreo y control de acceso.'),
('Configuración de autenticación multifactor', 'Mejorar la seguridad de acceso', 'La autenticación multifactor agrega una capa adicional de seguridad al proceso de inicio de sesión.');
```
 
 
 

## 🧠 Explicación detallada de funciones clave

### 🔹 `phraseto_tsquery()`
**¿Qué hace?**  
Busca **frases exactas** en el texto, es decir, que las palabras aparezcan **juntas y en el mismo orden**.

**¿Cuándo usarla?**  
Cuando necesitas precisión, por ejemplo: `"configuración de seguridad"` debe aparecer como una frase, no solo como palabras separadas.

**¿Con qué se combina?**  
- `to_tsvector()` para convertir el texto a formato buscable.
- `@@` para aplicar la búsqueda.
- `ts_rank()` para medir relevancia.
- `ts_headline()` para mostrar resultados resaltados.

**Ejemplo:**
```sql
SELECT * 
FROM articulos 
WHERE to_tsvector(contenido) @@ phraseto_tsquery('configuración de seguridad');
```

---

### 🔹 `ts_headline()`
**¿Qué hace?**  
Resalta los términos encontrados en el texto, útil para mostrar fragmentos como en un buscador.

**¿Cuándo usarla?**  
Cuando presentas resultados al usuario y quieres mostrar **dónde** se encontró la coincidencia.

**¿Con qué se combina?**  
- `to_tsquery()` o `phraseto_tsquery()` para definir la búsqueda.
- `to_tsvector()` para preparar el texto.
- `@@` para filtrar resultados.

**Ejemplo:**
```sql
SELECT ts_headline('spanish', contenido, phraseto_tsquery('configuración de seguridad')) 
FROM articulos 
WHERE to_tsvector(contenido) @@ phraseto_tsquery('configuración de seguridad');
```

---

### 🔹 `setweight()`
**¿Qué hace?**  
Asigna **prioridad** a diferentes columnas en el `tsvector`. Por ejemplo, el título puede tener más peso que el contenido.

**¿Cuándo usarla?**  
Cuando combinas varias columnas en la búsqueda y quieres que algunas influyan más en la relevancia.

**¿Con qué se combina?**  
- `to_tsvector()` para cada columna.
- `ts_rank()` para que el peso influya en el cálculo de relevancia.

**Ejemplo:**
```sql
SELECT setweight(to_tsvector(titulo), 'A') || 
       setweight(to_tsvector(resumen), 'B') || 
       setweight(to_tsvector(contenido), 'C') AS documento
FROM articulos;
```

---

### 🔹 `ts_rank()`
**¿Qué hace?**  
Calcula un **puntaje de relevancia** para cada documento según qué tan bien coincide con la consulta.

**¿Cuándo usarla?**  
Cuando quieres **ordenar los resultados** por relevancia, como en un motor de búsqueda.

**¿Con qué se combina?**  
- `setweight()` para ponderar columnas.
- `to_tsquery()` o `phraseto_tsquery()` para definir la búsqueda.
- `@@` para filtrar resultados.

**Ejemplo completo:**
```sql
SELECT titulo,
       ts_rank(
         setweight(to_tsvector(titulo), 'A') || 
         setweight(to_tsvector(resumen), 'B') || 
         setweight(to_tsvector(contenido), 'C'),
         phraseto_tsquery('configuración de seguridad')
       ) AS relevancia,
       ts_headline('spanish', contenido, phraseto_tsquery('configuración de seguridad')) AS resumen_destacado
FROM articulos
WHERE to_tsvector(titulo || ' ' || resumen || ' ' || contenido) @@ phraseto_tsquery('configuración de seguridad')
ORDER BY relevancia DESC;
```



--- 

# Extra ejemplo  Búsqueda avanzada semántica y fonética 

### 1. **Extensiones necesarias**
Activa estas extensiones en PostgreSQL:

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
```



### 2. **Crear índice para acelerar búsquedas**
Esto mejora el rendimiento de búsquedas por similitud:

```sql
CREATE INDEX idx_palabra_trgm ON diccionario USING gin (palabra gin_trgm_ops);
```

### 3. **Consulta avanzada combinando similitud y fonética**

```sql
SELECT palabra,
       similarity(palabra, 'buscada') AS similitud,
       levenshtein(lower(palabra), lower('buscada')) AS distancia,
       soundex(palabra) = soundex('buscada') AS foneticamente_similar
FROM diccionario
WHERE palabra % 'buscada'  -- operador de similitud
ORDER BY similitud DESC, distancia ASC
LIMIT 5;
```

### ¿Qué hace esto?

- `similarity()`: mide qué tan parecida es la palabra.
- `levenshtein()`: mide cuántos cambios se necesitan para convertir una palabra en otra.
- `soundex()`: compara cómo suenan las palabras (útil para errores de escritura fonética).
- `palabra % 'buscada'`: usa el operador de similitud de `pg_trgm`.


---


## 🔍 Tabla Comparativa de Herramientas de Búsqueda de Texto

| Tecnología         | ¿Qué hace?                          | ¿Cuándo usarla?                     | Precisión | Velocidad | Ideal para                        |
|-------------------|-------------------------------------|-------------------------------------|-----------|-----------|-----------------------------------|
| `pg_trgm`         | Búsqueda por similitud de texto     | Corrección ortográfica, sugerencias | Alta      | Muy alta  | Errores ortográficos, sugerencias |
| `LIKE` / `ILIKE`  | Coincidencia exacta o parcial       | Búsqueda simple                     | Media     | Muy alta  | Filtros rápidos y directos        |
| `tsvector`        | Indexación semántica                | Búsqueda contextual                 | Alta      | Alta      | Búsqueda semántica contextual     |
| `tsquery`         | Consulta semántica avanzada         | Filtros por significado             | Alta      | Alta      | Búsqueda con operadores lógicos   |
| `fuzzystrmatch`   | Comparación fonética                | Nombres mal escritos                | Media     | Media     | Comparación léxica y fonética     |

---

## 🧠 Glosario de términos técnicos

### 1. **Similitud**
- **Definición**: Medida que indica qué tan parecidos son dos textos.
- **Ejemplo**: `'buscado'` y `'buscador'` tienen alta similitud porque comparten muchas letras en el mismo orden.
- **En PostgreSQL**: La función `similarity(text1, text2)` devuelve un valor entre 0 y 1.

---

### 2. **Distancia**
- **Definición**: Medida de cuán diferentes son dos textos.
- **Tipos comunes**:
  - **Levenshtein**: Número mínimo de ediciones (inserciones, eliminaciones, sustituciones) para transformar un texto en otro.
  - **Jaccard**: Basada en la intersección y unión de conjuntos de trigramas.
- **Relación con similitud**: A mayor distancia, menor similitud.

---

### 3. **Trigrama**
- **Definición**: Secuencia de tres caracteres consecutivos en un texto.
- **Ejemplo**: Para `'buscada'`, los trigramas son `bus`, `usc`, `sca`, `cad`, `ada`.
- **Uso en `pg_trgm`**: PostgreSQL compara trigramas para calcular similitud.

---

### 4. **Operador `%`**
- **Definición**: Operador de similitud en PostgreSQL.
- **Función**: Filtra registros que son "suficientemente similares" al texto buscado.
- **Ejemplo**: `palabra % 'buscada'` devuelve palabras con similitud mayor al umbral.

---

### 5. **Búsqueda semántica**
- **Definición**: Busca entender el significado del texto, no solo su forma.
- **Ejemplo**: `'auto'` y `'vehículo'` pueden considerarse similares aunque no compartan letras.
- **Nota**: PostgreSQL no hace búsqueda semántica nativa, pero se puede integrar con herramientas como embeddings o modelos NLP.

### La **comparación fonética** 
es una técnica que busca determinar si dos palabras **suenan parecido**, 
aunque estén escritas de forma diferente. Es muy útil en sistemas de búsqueda, corrección ortográfica o bases de datos donde los nombres pueden tener errores de escritura pero conservar una pronunciación similar.


---

### 6. **Comparación léxica**
- **Definición**: Comparación basada en la forma textual (letras, orden, longitud).
- **Ejemplo**: `'casa'` y `'casas'` son léxicamente similares.
- **Uso**: Es la base de `pg_trgm`, `LIKE`, `ILIKE`, y operadores de texto.

---

### 7. **Umbral de similitud (`pg_trgm.similarity_threshold`)**
- **Definición**: Valor mínimo para que el operador `%` considere dos textos como similares.
- **Ejemplo**: Si el umbral es `0.4`, solo se consideran similares los textos con `similarity >= 0.4`.

----

### 🔹 **Vector (tsvector)**
- En FTS, un **vector** es una estructura que representa un texto como un conjunto de **tokens indexables**.
- Cada token es una palabra significativa (sin stopwords) y puede incluir su **posición** en el texto.
- Ejemplo:  
  ```sql
  SELECT to_tsvector('spanish', 'buscando palabras en texto');
  ```
  Resultado:
  ```
  'buscando':1 'palabra':2 'texto':4
  ```

--- 

### 🔹 **Dimensiones**
- En el contexto de FTS, cada **palabra indexada** puede considerarse una **dimensión** del espacio vectorial.
- El texto se transforma en un vector que vive en un espacio donde cada dimensión representa una palabra.
- Esto permite comparar vectores (textos) usando operaciones como `@@` o `ts_rank`.


### 🔹 **calcular la relevancia** 
de las coincidencias en una búsqueda de texto completo. Es decir, **asigna un puntaje** que indica qué tan bien un documento (o texto) coincide con una consulta de búsqueda.

### ¿Qué significa "relevancia de coincidencias"?

Cuando haces una búsqueda de texto completo con `to_tsvector` y `to_tsquery`, puedes encontrar varios documentos que contienen las palabras buscadas. Pero no todos los documentos son igual de relevantes. Por ejemplo:

- Un documento que contiene todas las palabras buscadas varias veces puede ser más relevante.
- Un documento donde las palabras aparecen cerca unas de otras también puede ser más relevante.
- Un documento que solo contiene una palabra buscada una vez puede ser menos relevante.


### Bibliografía
```

pg_textsearch  -> https://www.tigerdata.com/blog/pg-textsearch-bm25-full-text-search-postgres
pg_search      -> https://github.com/paradedb/paradedb/tree/main/pg_search
pg_rum


https://www.paradedb.com/blog/personalized-search-in-postgresql
https://medium.com/the-table-sql-and-devtalk/mastering-postgresql-full-text-search-a-definitive-guide-a794b47dfcbf
pgvector -> https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pgvector.md
https://rendiment.io/postgresql/2026/01/21/pgtrgm-pgvector-music.html
```
