
# 🚀 ¿Por qué PostgreSQL tiene un límite de 32 TB por tabla?

Muchos desarrolladores creen que las bases de datos son infinitas, pero PostgreSQL tiene reglas físicas grabadas en su código fuente. Si alguna vez te preguntaste de dónde sale el famoso número de **32 Terabytes**, aquí te desvelamos el misterio de la "Matemática del Almacenamiento".

## 1. La unidad fundamental: El Bloque (Page)

Postgres no escribe datos de uno en uno. Lo hace en trozos llamados **Blocks** (o Pages). Por defecto, cada bloque mide **8 KB**.

Todo lo que guardas —filas, índices, metadatos— vive dentro de estos bloques de 8 KB.

## 2. El sistema de direccionamiento (Punteros)

Aquí es donde ocurre la magia (y la limitación). Para que Postgres sepa dónde está una fila, utiliza un sistema de punteros.

En el código interno de PostgreSQL, el número de bloques que una sola tabla puede manejar está limitado por el tamaño de los números enteros que usa para "contar" esos bloques. Postgres usa un **entero de 32 bits** para direccionar los bloques dentro de una tabla.

## 3. La matemática del límite

Hagamos el cálculo que define el post:

* **Capacidad de direccionamiento:** Un entero de 32 bits permite un máximo de  combinaciones.
* **Total de bloques:** Eso significa que una tabla puede tener hasta **4,294,967,296 bloques**.
* **Tamaño del bloque:** Cada bloque mide **8 KB**.

Si multiplicamos:


Al convertir esos bytes a unidades binarias (Terabytes):
**35,184,372,088,832 / 1,024⁴ ≈ 32 TB.**

---

## 4. ¿Se puede superar este límite?

¡Sí! Pero no es tan simple como cambiar un ajuste en un archivo `.conf`. Tienes tres caminos:

1. **Recompilar Postgres:** Podrías cambiar el tamaño del bloque a 32 KB al compilar el motor desde el código fuente. Esto elevaría el límite a **128 TB**, pero perderías compatibilidad con muchas herramientas estándar.
2. **Particionamiento de tablas:** Esta es la solución profesional. En lugar de una tabla gigante de 100 TB, creas 4 particiones de 25 TB cada una. Para Postgres, cada partición es un archivo distinto, por lo que el límite de los 32 TB se aplica a cada partición individualmente, permitiéndote crecer casi infinitamente.
3. **Tablespaces:** Puedes distribuir la carga en diferentes discos físicos, aunque el límite lógico por tabla (si no está particionada) seguirá existiendo.

---

## Conclusión para tu post

El límite de 32 TB no es un error de diseño, sino un **compromiso de eficiencia**. Usar 32 bits para direccionar bloques mantiene los índices compactos y el rendimiento alto. Para el 99.9% de las aplicaciones, 32 TB es un océano de datos; para el otro 0.1%, el particionamiento es el mejor aliado.

--- 




## Escenario 1: Primary Key con `BIGINT`

El tipo `BIGINT` es un entero de 8 bytes con signo.

* **Rango de valores:** De  a .
* **Capacidad lógica:** Aproximadamente **9 trillones** () de registros.
* **Almacenamiento:** Ocupa **8 bytes** fijos.
* **Comportamiento:** Generalmente se usa con `GENERATED ALWAYS AS IDENTITY`. Esto garantiza que los datos se inserten de forma secuencial.

### Ventajas técnicas:

1. **Índices compactos:** Al ser pequeño (8 bytes), el índice B-Tree resultante es muy eficiente y cabe más fácilmente en la memoria RAM (Buffer Cache).
2. **Localidad de datos:** Como los insertos son secuenciales, se reduce la fragmentación del índice.
3. **Rendimiento de Join:** Las comparaciones entre enteros son extremadamente rápidas a nivel de CPU.

---

## Escenario 2: Primary Key con `UUID`

El tipo `UUID` (Universally Unique Identifier) también ocupa un espacio fijo, pero es mayor.

* **Rango de valores:** Prácticamente infinito ( combinaciones). No te lo vas a acabar ni en mil vidas.
* **Almacenamiento:** Ocupa **16 bytes** (el doble que un `BIGINT`).
* **Comportamiento:** Generalmente se generan de forma aleatoria (v4).

### Ventajas y Desventajas técnicas:

1. **Escalabilidad distribuida:** Son perfectos para sistemas distribuidos donde no quieres que dos bases de datos colisionen al generar IDs.
2. **Maldición de la aleatoriedad:** Al insertar UUIDs aleatorios, el índice B-Tree se vuelve "caótico". Esto provoca que Postgres tenga que mover páginas de datos constantemente (**index leaf splitting**), lo que degrada el rendimiento de escritura cuando la tabla es muy grande.
3. **Hinchazón (Bloat):** Los índices de UUID suelen ser mucho más grandes y menos densos que los de BIGINT.

---

## Comparativa de Impacto en Almacenamiento

| Característica | `BIGINT` | `UUID` |
| --- | --- | --- |
| **Tamaño en disco (PK)** | 8 bytes | 16 bytes |
| **Límite de registros** | ~9 quintillones (Suficiente para casi todo) | Prácticamente ilimitado |
| **Rendimiento de Inserción** | Alto (Secuencial) | Menor (Aleatorio, genera fragmentación) |
| **Uso de Memoria (RAM)** | Muy eficiente | Menos eficiente (Índices más grandes) |

> **Nota de experto:** Si eliges `UUID` por necesidad de diseño pero te preocupa el rendimiento, te recomiendo usar **UUID v7**. Este estándar es "ordenable por tiempo" (time-sortable), lo que combina la unicidad del UUID con la eficiencia de inserción secuencial del BIGINT.

 
### Resumen

El límite de datos de tu tabla seguirá siendo **32 TB** en ambos casos. Sin embargo, con `BIGINT` llegarás a ese límite con un rendimiento de consulta y escritura superior, mientras que con `UUID` (especialmente v4) notarás que los índices consumen el doble de espacio y la base de datos trabaja más para mantenerlos organizados.



---
# Mitos y sugerencias  


### 1. El mito de los archivos de 1 GB (Segmentation)

Mucha gente cree que si una tabla mide 32 TB, existe un archivo de 32 TB en el disco duro. **Error.**
A nivel de sistema operativo, PostgreSQL divide las tablas en segmentos de **1 GB** (llamados *relfilenodes*).

* **Dato para el post:** "Aunque tu tabla sea un gigante de 32 TB, en realidad es un ejército de 32,768 archivos de 1 GB trabajando en equipo. Esto se hace para que la base de datos sea compatible con sistemas de archivos antiguos que no soportan archivos masivos."

### 2. El "Impuesto" del Header (El costo oculto de cada fila)

No todo el espacio es para tus datos. Cada fila en Postgres tiene un **Header** (encabezado) de unos **24 bytes**.

* **El gancho:** Si usas un `INT` (4 bytes) pero el encabezado ocupa 24 bytes, ¡estás gastando más en metadatos que en el dato mismo!
* **Relación con tu duda inicial:** Si usas `UUID` (16 bytes) frente a `BIGINT` (8 bytes), la diferencia parece pequeña, pero cuando sumas los 24 bytes del header, la eficiencia de almacenamiento por página cambia drásticamente.

### 3. El fenómeno del "Alignment Padding" (Espacios vacíos)

Postgres guarda los datos en múltiplos de 8 bytes para que la CPU los lea más rápido.

* **Lo curioso:** Si diseñas mal el orden de tus columnas (ej. mezclas un `smallint` con un `bigint`), Postgres añade "espacio vacío" (padding) para alinear los datos.
* **Tip de experto:** "El orden de tus columnas importa. Podrías estar llegando al límite de los 32 TB antes de tiempo simplemente por tener columnas mal ordenadas que desperdician bits en cada fila."

### 4. ¿Por qué 32 bits y no 64 bits para los bloques?

Alguien te preguntará: *"¿Por qué Postgres no usa punteros de 64 bits para que el límite sea de Petabytes?"*

* **La respuesta técnica:** Usar punteros de 64 bits haría que los **índices** crecieran masivamente en tamaño. Esto llenaría la memoria RAM más rápido y haría la base de datos más lenta. Los 32 TB son el "punto dulce" entre capacidad inmensa y rendimiento óptimo.

 

### Cómo cerrar el post con "broche de oro":

Podrías añadir una sección llamada **"¿Cuándo deberías preocuparte?"**:

> "Si tu tabla está llegando a los 10 TB, no esperes a los 32 TB. El problema no será el límite físico, sino que procesos como el `VACUUM` (la limpieza automática) o la creación de índices tardarán días en completarse. El particionamiento no es solo para el espacio, es para la cordura del administrador."

 
