


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



### Bibliografía
```
https://medium.com/the-table-sql-and-devtalk/mastering-postgresql-full-text-search-a-definitive-guide-a794b47dfcbf
pgvector -> https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pgvector.md
```
