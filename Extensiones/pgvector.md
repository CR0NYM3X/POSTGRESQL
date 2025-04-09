
     
### Extensión pgvector

La extensión **pgvector** en PostgreSQL permite almacenar y buscar datos vectorizados directamente en la base de datos. Esto es útil para aplicaciones como:
- **Búsqueda de similitud**: Encontrar elementos similares basados en métricas como la distancia euclidiana o la similitud de coseno.
- **Análisis de datos**: Realizar análisis eficientes de datos vectoriales sin necesidad de herramientas externas.

 

### Paso a paso: Cálculo de la distancia euclidiana

La distancia euclidiana entre dos vectores \(A\) y \(B\) se calcula usando la fórmula:

$$
\text{distancia}(A, B) = \sqrt{(A_1 - B_1)^2 + (A_2 - B_2)^2 + \ldots + (A_n - B_n)^2}
$$

Donde \(A_i\) y \(B_i\) son las dimensiones de los vectores \(A\) y \(B\).



### ¿Qué son los datos vectorizados?

Los datos vectorizados son representaciones matemáticas de información en forma de listas de números. Imagina que cada dato es un punto en un espacio multidimensional. Por ejemplo, una imagen de un gato puede ser convertida en una lista de números que representan características como el color, la textura, y la forma.


### Ejemplos reales

1. **Búsqueda de imágenes similares**: Si tomas una foto de un gato y quieres encontrar imágenes similares en una base de datos, cada imagen se convierte en un vector. Luego, se comparan estos vectores para encontrar las imágenes más parecidas.
2. **Recomendaciones de productos**: En una tienda online, los productos pueden ser representados como vectores basados en sus características. Esto permite recomendar productos similares a los que has visto o comprado.

### Ventajas y desventajas

**Ventajas**:
- **Precisión**: Los vectores pueden representar datos con gran exactitud.
- **Compactos**: Los datos vectoriales suelen ocupar menos espacio.
- **Análisis eficiente**: Facilitan el análisis de proximidad y similitud.

**Desventajas**:
- **Complejidad**: La estructura de datos vectoriales puede ser más compleja de manejar.
- **Requisitos de procesamiento**: Manipular y analizar grandes conjuntos de datos vectoriales puede requerir mucho procesamiento.

### Cuándo usarlos y cuándo no

**Usarlos**:
- **Búsqueda semántica**: Para encontrar documentos o imágenes similares basados en el contenido.
- **Recomendaciones**: En sistemas de recomendación de productos o contenido.
- **Detección de anomalías**: Para identificar comportamientos fuera de lo común en datos de series temporales.

**No usarlos**:
- **Datos continuos**: Como elevaciones o temperaturas, que se representan mejor con datos ráster.
- **Análisis espacial detallado**: Cuando se necesita una representación tridimensional precisa.



### ¿Qué es una dimensión en un vector?

Una dimensión en un vector es una característica específica que estamos midiendo o representando. Piensa en cada dimensión como una columna en una tabla de datos, donde cada fila es un vector.

### Ejemplo detallado

Imaginemos que estamos trabajando con datos de frutas. Queremos representar cada fruta con un vector que tenga tres dimensiones: **dulzura**, **acidez** y **tamaño**.

1. **Manzana**:
   - **Vector**: `[7, 5, 3]`
   - **Dimensiones**:
     - 7: Dulzura (en una escala de 1 a 10)
     - 5: Acidez (en una escala de 1 a 10)
     - 3: Tamaño (en una escala de 1 a 5)

2. **Naranja**:
   - **Vector**: `[6, 8, 4]`
   - **Dimensiones**:
     - 6: Dulzura
     - 8: Acidez
     - 4: Tamaño

3. **Plátano**:
   - **Vector**: `[9, 2, 5]`
   - **Dimensiones**:
     - 9: Dulzura
     - 2: Acidez
     - 5: Tamaño


### Visualización de las dimensiones

Para visualizar mejor, imagina que cada fruta es un punto en un espacio tridimensional donde cada eje representa una dimensión:

- **Eje X**: Dulzura
- **Eje Y**: Acidez
- **Eje Z**: Tamaño

Cada fruta (manzana, naranja, plátano) se puede ubicar en este espacio según sus valores en cada dimensión.


### Uso en PostgreSQL con pgvector

Vamos a ver cómo se pueden usar estos vectores en PostgreSQL:

1. **Crear la tabla**:
   ```sql
   CREATE TABLE frutas (
       id SERIAL PRIMARY KEY,
       nombre TEXT,
       vector VECTOR(3) -- Tres dimensiones: dulzura, acidez, tamaño
   );
   ```

2. **Insertar datos**:
   ```sql
   INSERT INTO frutas (nombre, vector) VALUES
   ('manzana', '[7, 5, 3]'),
   ('naranja', '[6, 8, 4]'),
   ('plátano', '[9, 2, 5]');
   ```

3. **Buscar frutas similares**:
   Supongamos que tienes un vector de consulta `[8, 4, 3]` y quieres encontrar las frutas más similares.
   ```sql
   SELECT nombre, vector <-> '[8, 4, 3]' AS distancia
   FROM frutas
   ORDER BY distancia
   LIMIT 5;
   ```
   
   
## Resultados 
 
la búsqueda de similitud utilizando la distancia euclidiana, **el valor más bajo indica mayor similitud**. Esto se debe a que la distancia euclidiana mide cuán "lejos" están dos vectores en un espacio multidimensional. Cuanto menor sea la distancia, más cerca están los vectores y, por lo tanto, más similares son.

### Ejemplo con los resultados ordenado por similitud

- **Manzana**: 1.41 (más similar)
- **Plátano**: 3.00
- **Naranja**: 4.58 (menos similar)

En este caso, la **manzana** es la fruta más similar al vector de consulta `[8, 4, 3]` porque tiene la menor distancia (1.41). La **naranja** es la menos similar porque tiene la mayor distancia (4.58).

# Calcular con consulta 
```
select sqrt( POWER(7-8,2) + POWER(5-4,2) + POWER(3-3,2) ); --- 1.414213562373095
```
 
   

### Ejemplo con los datos de frutas

#### Vectores:
- **Manzana**: `[7, 5, 3]`
- **Naranja**: `[6, 8, 4]`
- **Plátano**: `[9, 2, 5]`
- **Vector de consulta**: `[8, 4, 3]`

#### Cálculo de la distancia:

1. **Manzana**:
   - Vector: `[7, 5, 3]`
   - Consulta: `[8, 4, 3]`
   - Distancia:
   
$$
\sqrt{(7 - 8)^2 + (5 - 4)^2 + (3 - 3)^2} = \sqrt{(-1)^2 + 1^2 + 0^2} = \sqrt{1 + 1 + 0} = \sqrt{2} \approx 1.41
$$

2. **Naranja**:
   - Vector: `[6, 8, 4]`
   - Consulta: `[8, 4, 3]`
   - Distancia:
   
$$
\sqrt{(6 - 8)^2 + (8 - 4)^2 + (4 - 3)^2} = \sqrt{(-2)^2 + 4^2 + 1^2} = \sqrt{4 + 16 + 1} = \sqrt{21} \approx 4.58
$$

3. **Plátano**:
   - Vector: `[9, 2, 5]`
   - Consulta: `[8, 4, 3]`
   - Distancia:
   
$$
\sqrt{(9 - 8)^2 + (2 - 4)^2 + (5 - 3)^2} = \sqrt{1^2 + (-2)^2 + 2^2} = \sqrt{1 + 4 + 4} = \sqrt{9} = 3
$$
 

# Index HNSW y IVFFlat
Para optimizar la consulta de búsqueda de vecinos más cercanos (KNN) en PostgreSQL con el tipo `VECTOR`, debes utilizar un índice especializado.  
 

 **Crea un índice HNSW (recomendado para alta performance)**:
   ```sql
   CREATE INDEX frutas_vector_hnsw_idx
   ON frutas USING hnsw (vector vector_l2_ops)
   WITH (m = 16, ef_construction = 64);
   ```

   *Este índice es óptimo para consultas KNN con operadores como `<->` (distancia euclidiana).*

**Si prefieres un índice IVFFlat (más rápido para creación)**:
   ```sql
   CREATE INDEX frutas_vector_ivfflat_idx
   ON frutas USING ivfflat (vector vector_l2_ops)
   WITH (lists = 1000);  -- Ajusta según cardinalidad (√número_de_filas)
   ```

**Explicación**:
- **HNSW**: Índice de grafos jerárquico para alta velocidad en grandes volúmenes de datos.
- **IVFFlat**: Divide el espacio en clusters (listas) para búsquedas aproximadas rápidas.
- `vector_l2_ops`: Clase de operador para distancia euclidiana (L2).


# Index GIN
los índices **GIN** (Generalized Inverted Index) **no son adecuados** para búsquedas por similitud en vectores (KNN, ANN) como las que realizas con operadores `<->`, `<#>` (cosine similarity) o `<=>` (inner product) en PostgreSQL con la extensión `pgvector`.  

### ¿Por qué GIN no sirve para vectores?
1. **Diseñado para datos discretos**:  
   - GIN es óptimo para búsquedas en arrays, JSON, full-text search o datos con elementos discretos (ej.: `WHERE vector @> '[1,0,0]'`).  
   - **No soporta búsqueda por distancia** (L2, cosine, etc.), que es fundamental para comparar vectores en espacios continuos.  

2. **pgvector usa índices especializados**:  
   - **IVFFlat**: Divide el espacio vectorial en clusters (listas) para búsqueda aproximada.  
   - **HNSW**: Grafos jerárquicos para alta eficiencia en altas dimensiones.  
   - Estos índices están optimizados para operadores como `<->` y algoritmos de similitud.  

### Ejemplo de índices válidos para vectores:
```sql
-- Índice HNSW (recomendado para precisión y velocidad)
CREATE INDEX idx_frutas_hnsw ON frutas USING hnsw (vector vector_l2_ops);

-- Índice IVFFlat (más rápido para creación, requiere ajuste de 'lists')
CREATE INDEX idx_frutas_ivfflat ON frutas USING ivfflat (vector vector_l2_ops) WITH (lists = 100);
```

### Caso donde GIN *podría* usarse (pero no es lo que necesitas):
Si tu columna `vector` fuese un **array tradicional** (no tipo `VECTOR`) y buscaras elementos exactos:
```sql
-- Esto NO es una búsqueda de similitud, sino exacta:
CREATE INDEX idx_frutas_gin ON frutas USING gin (vector);
SELECT * FROM frutas WHERE vector @> '[7,5,3]';  -- Solo coincidencias exactas
```


 
Referencias: 
```sql
https://www.mongodb.com/es/resources/basics/databases/vector-databases/vector-databases
```
