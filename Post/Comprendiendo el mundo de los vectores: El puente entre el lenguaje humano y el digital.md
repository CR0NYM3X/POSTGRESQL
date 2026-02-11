

# Comprendiendo el mundo de los vectores: El puente entre el lenguaje humano y el digital 🌉

Imagina que entramos en una sala gigante. Olvida por un momento las tablas de Excel aburridas y los datos rígidos. Entra conmigo en el **Universo de las Ideas**.

## 🌌 El "Google Maps" de los Conceptos

Imagina que cada palabra, frase o imagen que existe tiene una ubicación exacta en un mapa infinito. Los expertos llaman a esto **Embedding**, pero para nosotros será simplemente una **"Dirección GPS"**.

### 1. ¿Cómo se ve un Vector? 📍

Un vector es solo una lista de coordenadas que ubica una idea en ese mapa:

* **Perro:** (Latitud 10, Longitud 5, Altitud 2)
* **Lobo:** (Latitud 10, Longitud 5, Altitud 3)
* **Plátano:** (Latitud -50, Longitud 80, Altitud -10)

¿Ves que el **Perro** y el **Lobo** tienen números casi iguales? Es porque están "cerca" en el mapa. El **Plátano**, en cambio, está en otro continente numérico porque no tiene nada que ver con ellos.

### 2. ¿Cómo funciona la búsqueda? 🔍

Cuando buscas algo, el sistema lanza una "flecha" desde el centro del mapa hacia tu búsqueda. Luego, simplemente mira qué hay alrededor de la punta de esa flecha:

* **Si el ángulo es pequeño:** Las ideas se parecen mucho (como "Pizza" y "Calzone").
* **Si el ángulo es grande:** No tienen relación (como "Pizza" y "Neumático").

---

## 🤔 La pregunta del millón...

**¿Y esto cómo se aplica en una base de datos real como PostgreSQL?** Aquí es donde ocurre la magia.

Para que nuestra base de datos no sea solo una caja donde guardamos texto, existe una extensión brillante llamada `pgvector`. Esta herramienta le da a Postgres **ojos y sentimientos**, permitiéndole guardar esas "direcciones GPS" y buscarlas en tiempo récord.

### 🚀 El Superpoder de `pgvector`

* **Búsqueda por "Vibra":** Puedes buscar "atardeceres felices" y la IA encontrará las fotos aunque nadie les haya puesto esa etiqueta.
* **Recomendaciones Inteligentes:** "Si te gustó esta canción, te gustará esta otra porque sus vectores están a pocos milímetros de distancia".
* **Cerebro para IAs:** Es el lugar donde IAs como ChatGPT guardan sus recuerdos para no olvidarlos.

---

## 🛠️ Los dos "Trucos de Magia" que debes conocer

### 1. El Índice HNSW (La Autopista) 🧠

Seguro piensas: *"Si el mapa tiene millones de puntos, ¿tarda mucho en buscar?"*. ¡Para nada! Usamos algo llamado **HNSW**.
Imagina que el mapa tiene **autopistas elevadas**. El sistema salta de una ciudad a otra, luego a un barrio y finalmente a la calle exacta. Encuentra lo que buscas en milisegundos sin revisar todo el mapa.

### 2. El Súper Combo: Búsqueda Híbrida 🤝

Lo mejor es que no tienes que elegir entre lo "nuevo" y lo "viejo". Puedes combinarlos:

* **Ejemplo:** Buscas *"Un vestido elegante"* (**Vibra/Vector**) que además *"Sea rojo y cueste menos de $100"* (**Filtro tradicional**).
Es como tener un bibliotecario que entiende el alma del libro, pero también sabe exactamente en qué estante está y cuánto cuesta.

---

## ⚖️ El Lado Humano (Ventajas y Retos)

### **Lo que nos encanta ✅**

* **Entiende el contexto:** Si buscas "reparar auto", te traerá resultados de "arreglar vehículo". ¡Te entiende!
* **Multimodal:** Puedes comparar un texto con una imagen. ¡Hablan el mismo idioma numérico!
* **Todo en casa:** No necesitas bases de datos raras. Usas el Postgres de siempre, seguro y confiable.

### **El reto ⚠️**

* **Memoria:** Necesitas una computadora con buena RAM (una mesa grande para desplegar el mapa).
* **Casi Exacto:** A veces el GPS te deja en la casa de al lado. Es muy raro que falle, pero busca ser "parecido", no "exacto".

---

## 🌟 ¿Por qué es emocionante?

Antes, las computadoras eran calculadoras rígidas. Con `pgvector`, PostgreSQL se convierte en un bibliotecario que **entiende de qué tratan los libros**. Estamos pasando de la era de "buscar datos" a la era de **"encontrar significados"**.

**¿Y tú, qué 'mapa de ideas' construirías? ¡Te leo en los comentarios! 👇**

---


 

# Tockens 

En pocas palabras, el **token** es el **"ladrillo"** de información. Es la unidad mínima en la que la IA divide un texto para poder procesarlo.

Si lo vemos desde tu perspectiva de **Bases de Datos**:

* **El Texto** es el registro completo (el `string`).
* **El Token** es la "normalización" de ese registro: el proceso de romperlo en piezas atómicas (pedazos de palabras, sílabas o signos) que tienen un ID único en un catálogo.

**En resumen:**
El token es el **traductor**. La IA no sabe leer letras, y los vectores son demasiado complejos para crearlos de la nada. El token es el paso intermedio: convierte el lenguaje humano en una lista de IDs numéricos que la máquina sí puede operar matemáticamente.

> **Sin tokens no hay IDs, sin IDs no hay matemáticas, y sin matemáticas no hay vectores.**





## 1. El Flujo: De Texto a Vector (El "Pipeline")

Imagina que este es tu proceso de **ETL** (Extract, Transform, Load) para meter datos en tu base de datos vectorial:

1. **Texto Plano (Input):** `"El perro corre"` (Dato crudo).
2. **Tokenización (Transformación 1):** El sistema lo pica en pedazos: `["El", "per", "ro", "corre"]`.
3. **Conversión a ID (Transformación 2):** Cada pedazo se busca en un "catálogo" (vocabulario) y se le asigna un número: `[102, 45, 89, 210]`.
4. **Embedding (Transformación 3):** Esos IDs pasan por una fórmula matemática que genera el **Vector**: `[[0.12, -0.5], [...], ...]`.
5. **Almacenamiento (Load):** Guardas ese vector en tu columna tipo `vector` de **PostgreSQL**.
 

## 2. La Analogía: El Inventario de la Ferretería 🛠️

Imagina que eres dueño de una ferretería. Un cliente te pide una **"Carretilla reforzada de construcción"**.

* **Sin Tokens (Palabra completa):** Tendrías que tener en tu base de datos una entrada exacta para cada producto posible del mundo. Si alguien pide "Carretilla ligera", y no la tienes registrada así, tu sistema diría: "No sé qué es eso".
* **Con Tokens (Piezas):** Tu inventario se basa en piezas básicas: `[Rueda]`, `[Manubrio]`, `[Tolva]`, `[Reforzado]`.

Cuando llega el pedido "Carretilla reforzada", el sistema identifica los **tokens**: `[Rueda] + [Manubrio] + [Tolva] + [Reforzado]`.
**La IA entiende el concepto porque sabe combinar las piezas, aunque nunca haya visto ese modelo exacto de carretilla.**

 

## 3. Ejemplo claro: "Des-composición"

Mira cómo el modelo "pica" estas dos frases:

* **Frase A:** `"Caminaba"` → Se convierte en 2 tokens: `["Camin", "aba"]`.
* `Camin`: Indica la acción (caminar).
* `aba`: Indica el tiempo (pasado).


* **Frase B:** `"Caminando"` → Se convierte en 2 tokens: `["Camin", "ando"]`.
* `ando`: Indica que está pasando ahora.



**¿Ves la magia?** El modelo no tiene que aprenderse 20,000 verbos. Solo se aprende la raíz `Camin` y los sufijos. Esto ahorra un espacio brutal en la "memoria" de la IA.

 

## 4. Ventajas y Desventajas (Lo que te interesa como DBA)

### ✅ Ventajas

* **Eficiencia de Vocabulario:** Con solo 50,000 tokens (piezas de Lego), el modelo puede entender millones de palabras combinándolas.
* **Manejo de Errores:** Si escribes "PostgreSQLL" (con una L de más), el tokenizador lo cortará en `["Postgre", "SQL", "L"]`. El modelo reconocerá las primeras dos piezas y sabrá de qué hablas.

### ❌ Desventajas (Las letras chiquitas)

* **El Costo Oculto:** En las bases de datos tradicionales pagas por GB. En IA pagas por **cantidad de tokens**. Un texto con muchas palabras técnicas o raras genera más tokens y, por lo tanto, la consulta es más cara y lenta.
* **Límites de Ventana:** Como en un `VARCHAR(255)`, los modelos tienen un límite de tokens (ej. 8,192). Si le pasas un PDF de 500 páginas, el modelo "olvidará" el principio porque ya no le caben más tokens en su memoria de corto plazo.
 
## 5. Lo que "no te cuentan": El espacio cuenta

En una base de datos, un espacio extra en un `TEXT` no cambia mucho. En el mundo de los tokens, un espacio al principio de una palabra puede generar un **token ID completamente distinto**.

Ejemplo:

* `"pájaro"` -> ID: 5432
* `" pájaro"` (con espacio) -> ID: 9821

Esto significa que si no limpias tus datos antes de tokenizarlos, tus **vectores serán diferentes** y tus búsquedas semánticas en PostgreSQL empezarán a fallar.


---



## 1. El eslabón perdido: Los Tokens

Antes de que una palabra se convierta en un vector (una lista de números), el modelo necesita "trocear" el texto. Ese proceso es la **Tokenización**.

* **¿Qué son?** No siempre son palabras completas. Un token puede ser una palabra entera (`Gato`), una sílaba (`Ga-`), o incluso un solo carácter.
* **¿Por qué importa?** Los modelos tienen un "límite de contexto" (un máximo de tokens que pueden leer a la vez). Si no entiendes los tokens, no entiendes por qué una consulta larga en PostgreSQL con `pgvector` puede fallar o salir muy cara.

 
## 2. Lo que "no te cuentan" (The Dirty Secrets)

Para que tu post sea realmente valioso, añade estos puntos que la mayoría de los tutoriales omiten:

### El Problema de la "Caja Negra"

Los vectores capturan relaciones semánticas, pero **no sabemos exactamente qué significa cada dimensión**. Si un vector tiene 1536 dimensiones, no podemos decir "la dimensión 5 es el género y la 12 es el color". Es pura estadística multidimensional, lo que hace difícil "debuguear" por qué el modelo cree que una "manzana" se parece a una "empresa tecnológica".

### La Maldición de la Dimensinalidad

A más dimensiones, más precisión... ¿cierto? No siempre.

* **Realidad:** Entre más dimensiones tenga tu vector, más lenta será la búsqueda y más memoria RAM consumirá tu base de datos PostgreSQL. El reto es encontrar el *sweet spot* entre precisión y rendimiento.

### La Pérdida de Contexto Local

Los embeddings son geniales para el significado general, pero pésimos para detalles exactos. Si buscas "No quiero pizza", el modelo podría darte resultados de "Pizza" porque el vector de "Pizza" es muy fuerte, ignorando el "No".

 

## 3. Ventajas y Desventajas: Tabla Comparativa

| Ventaja | Desventaja |
| --- | --- |
| **Búsqueda Semántica:** Encuentra "Doctor" cuando buscas "Médico". | **Costo Computacional:** Generar y comparar vectores requiere GPUs o CPUs potentes. |
| **Multimodalidad:** Puedes comparar un texto con una imagen si usas el mismo espacio vectorial. | **Alucinaciones:** Un vector cercano no siempre significa una respuesta correcta, solo una relación estadística. |
| **Reducción de Ambigüedad:** Diferencia entre "Banco" (asiento) y "Banco" (dinero) según el contexto. | **Dependencia del Modelo:** Si cambias tu modelo de embedding, tienes que re-generar TODA tu base de datos de vectores. |

---



## 1. ¿Cómo se asigna el ID a un Token?

Antes de llegar a los vectores (embeddings), pasamos por la **tokenización**. No hay "magia" ni un significado intrínseco aquí; es puramente administrativo.

* **El Vocabulario:** Cuando se entrena un modelo (como GPT o BERT), se crea un diccionario gigante de todas las palabras o sub-palabras que el modelo conoce.
* **Asignación Arbitraria:** A cada palabra se le asigna un número entero basado simplemente en su posición en ese diccionario.
* `perro` -> ID 452
* `pitbull` -> ID 8901
* `gato` -> ID 453



Este ID es solo una **etiqueta**. En este punto, el modelo no sabe qué significa "perro", solo sabe que es el concepto número 452.


## 2. ¿Cómo sabe que "perro" está cerca de "pitbull"?

Aquí es donde entran los **Embeddings** y el entrenamiento. La cercanía no se define manualmente, se **aprende** mediante el contexto.

### La Hipótesis Distribucional

La clave es una frase famosa en lingüística: *"Conocerás a una palabra por las compañías que mantiene"*.

1. **Contexto:** Durante el entrenamiento, el modelo lee billones de frases. Nota que "perro" y "pitbull" suelen aparecer rodeados de palabras similares como: *ladrar, veterinario, correa, mascota, pasear*.
2. **Ajuste Matemático:** Al principio, los vectores de todas las palabras apuntan a direcciones aleatorias en un espacio de cientos de dimensiones.
3. **Optimización:** Si el modelo ve que "pitbull" aparece en contextos donde usualmente aparece "perro", el algoritmo ajusta sus coordenadas matemáticas para que sus vectores apunten en direcciones similares.

### La cercanía matemática

Para la IA, la "cercanía" es la **Similitud de Coseno**. No es que el modelo "entienda" qué es un animal, es que matemáticamente sus coordenadas en el espacio multidimensional son casi las mismas.

Si usamos una fórmula simplificada de similitud:


Donde si el resultado es cercano a **1**, significa que las palabras son semánticamente similares porque comparten "vecindario" estadístico.


## Resumen rápido

* **El ID:** Es una placa de identificación (como el DNI o CURP) asignada al azar al inicio.
* **La cercanía:** Es el resultado de haber leído todo internet y darse cuenta de que esas dos palabras "se juntan con la misma gente".


---
---



# Embeddings

Si el **Token** es el "nombre" o "ID" de una palabra, el **Embedding** es su "personalidad" o "significado" convertido en números.

En términos simples: **Un embedding es una representación numérica de un concepto en un espacio de muchas dimensiones.**


 
## 1. El concepto: ¿Cómo cuantificar un significado?

Imagina que quieres describir una fruta usando solo números. Podrías crear "dimensiones" como:

* ¿Qué tan **dulce** es?
* ¿Qué tan **grande** es?
* ¿Qué tan **roja** es?

Entonces, una **Manzana** podría ser un vector como: `[0.9, 0.2, 0.8]`.
Mientras que un **Limón** sería: `[0.1, 0.1, 0.1]`.

En la IA, no usamos 3 dimensiones, sino cientos (como 768 o 1536). El modelo no decide "esta dimensión es para el color", sino que mediante el entrenamiento descubre patrones complejos que los humanos ni siquiera podemos nombrar.
 

## 2. La diferencia entre el ID y el Embedding

Es común confundirlos, pero son procesos distintos:

* **El Token (ID):** Es como el número de asiento en un estadio. El asiento 452 y el 453 están juntos, pero las personas sentadas ahí pueden no conocerse de nada. Es solo una **posición**.
* **El Embedding (Vector):** Es como un perfil psicológico. Personas con gustos similares (vectores similares) se agrupan en el mismo sector del estadio, sin importar qué número de asiento tengan.
 

## 3. ¿Para qué sirven? (El superpoder de la IA)

Gracias a los embeddings, las computadoras pueden hacer "matemáticas de palabras". El ejemplo clásico es:

$$Vector(\text{"Rey"}) - Vector(\text{"Hombre"}) + Vector(\text{"Mujer"}) \approx Vector(\text{"Reina"})$$

Esto es posible porque el embedding capturó la esencia de "realeza", "género masculino" y "género femenino" como coordenadas geográficas.



## 4. ¿Cómo se usan en  PostgreSQL?

Cuando guardas un embedding en `pgvector`, estás guardando ese "perfil numérico". Cuando un usuario busca "comida rápida", la base de datos no busca la palabra exacta, busca qué vectores están "cerca" del vector de esa frase. Por eso encuentra "hamburguesa" aunque la palabra "comida" no esté en el texto.

### En resumen:

* **Input:** "Perro"
* **Tokenización:** ID 452.
* **Embedding:** `[0.12, -0.59, 0.88, ...]` (un vector de 1536 números).
* **Resultado:** Ahora la máquina puede comparar ese vector contra otros y saber que "Pitbull" está a milímetros de distancia.
 




**Links y recursos:** `https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pgvector.md`
