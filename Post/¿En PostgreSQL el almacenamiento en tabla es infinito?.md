 
# 🚀 ¿Por qué PostgreSQL tiene un límite de 32 TB por tabla?

Muchos desarrolladores creen que las bases de datos son infinitas, pero PostgreSQL tiene reglas físicas grabadas en su código fuente. Si alguna vez te preguntaste de dónde sale el famoso número de **32 Terabytes**, aquí te desvelamos el misterio de la "Matemática del Almacenamiento".

## 1. La unidad fundamental: El Bloque (Page)

Postgres no escribe datos de uno en uno. Lo hace en trozos llamados **Blocks** (o Pages). Por defecto, cada bloque mide **8 KB**.

Todo lo que guardas —filas, índices, metadatos— vive dentro de estos bloques de 8 KB.

## 2. El sistema de direccionamiento (Punteros)

Aquí es donde ocurre la magia (y la limitación). Para que Postgres sepa dónde está una fila, utiliza un sistema de punteros.

En el código interno de PostgreSQL, el número de bloques que una sola tabla puede manejar está limitado por el tamaño de los números enteros que usa para "contar" esos bloques. Postgres usa un **entero de 32 bits** para direccionar los bloques dentro de una tabla.

## 3. La matemática del límite

Hagamos el cálculo:

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

## Conclusión 

El límite de 32 TB no es un error de diseño, sino un **compromiso de eficiencia**. Usar 32 bits para direccionar bloques mantiene los índices compactos y el rendimiento alto. Para el 99.9% de las aplicaciones, 32 TB es un océano de datos; para el otro 0.1%, el particionamiento es el mejor aliado.

--- 




### Escenario 1: Primary Key con BIGINT

El tipo **BIGINT** es un entero de 8 bytes con signo.

* **Rango de valores:** De **$-9,223,372,036,854,775,808$** a **$9,223,372,036,854,775,807$.**.
* **Capacidad lógica:** Aproximadamente **9 trillones** ($2^{63}-1$) de registros.
* **Almacenamiento:** Ocupa **8 bytes** fijos.
* **Comportamiento:** Generalmente se usa con `GENERATED ALWAYS AS IDENTITY`. Esto garantiza que los datos se inserten de forma secuencial.

**Ventajas técnicas:**

* **Índices compactos:** Al ser pequeño (8 bytes), el índice **B-Tree** resultante es muy eficiente y cabe más fácilmente en la memoria RAM (Buffer Cache).
* **Localidad de datos:** Como los insertos son secuenciales, se reduce la fragmentación del índice y se mejora la velocidad de escritura física en disco.
* **Rendimiento de Join:** Las comparaciones entre enteros son extremadamente rápidas a nivel de CPU comparadas con tipos de datos de texto o UUID.

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

 
---


 
## 1. El concepto de "Direccionamiento"

Imagina que una tabla es un libro gigante. Para que PostgreSQL encuentre información, cada "página" (bloque) del libro debe tener un **número de página único**.

En el código fuente de PostgreSQL, el tipo de dato que se usa para asignar estos números de página es un **entero de 32 bits** (específicamente llamado `BlockNumber`).

### ¿Por qué 32 bits equivalen a esa cifra?

En computación, un bit puede ser 0 o 1. Un sistema de 32 bits permite crear combinaciones de ceros y unos hasta alcanzar el valor máximo de:


```
11111111 11111111 11111111 11111111 (2^32) = 4,294,967,296
```

Es decir, PostgreSQL solo tiene "nombres" o "números de serie" para identificar un máximo de **4,294 millones de bloques**. Si intentaras agregar el bloque número 4,294,967,297, el sistema no tendría un número de 32 bits para identificarlo.


## 2. La matemática del límite de 32 TB

Una vez que sabemos cuántos bloques podemos tener, simplemente multiplicamos por el tamaño de cada bloque (que por defecto es **8 KB**):

1. **Total de bloques:** 
2. **Tamaño por bloque:**  bytes ( KB)
3. **Cálculo:**  bytes.

Si convertimos esos bytes a Terabytes (usando base 1024):

* 
 
## 3. ¿Es este un límite insuperable?

No es un límite absoluto de la tecnología, sino una decisión de diseño para equilibrar el rendimiento. Sin embargo, en el mundo real, rara vez llegas a chocar con esto por dos razones:

* **Particionamiento:** Puedes dividir una tabla gigante en varias tablas más pequeñas (particiones). Cada partición tendrá su propio límite de 32 TB.
* **Configuración al compilar:** Si alguien realmente necesitara tablas más grandes, podría cambiar el tamaño del bloque (a 16 KB o 32 KB) al momento de compilar PostgreSQL desde el código fuente, aunque esto no es lo habitual.

---

# Otros limites

PostgreSQL es una bestia en cuanto a escalabilidad, pero como todo sistema basado en arquitectura de archivos, tiene límites físicos definidos por su estructura de bloques.


## 1. Límites de Capacidad y Almacenamiento

| Concepto | Límite | Observaciones |
| --- | --- | --- |
| **Tamaño máximo de tabla** | **32 TB** | Como vimos, es el límite de direccionar  bloques de 8 KB. |
| **Tamaño máximo de fila** | **1.6 TB** | Una fila no puede ser más grande que la tabla, pero gracias a TOAST puede ser enorme. |
| **Tamaño máximo de un campo/celda** | **1 GB** | El límite técnico para un solo valor (un `TEXT` o `BYTEA` muy largo). |
| **Filas por tabla** | **Ilimitado** | No hay un número fijo de filas; el límite lo pone el espacio de 32 TB. |

 

## 2. Límites de Columnas e Índices

* **Columnas por tabla:** Entre **250 y 1,600**.
* *¿Por qué varía?* Depende de los tipos de datos. Cada columna ocupa un espacio en el encabezado de la fila; si usas tipos de datos muy "pesados", el límite se acerca a 250.


* **Columnas en un Índice:** Máximo **32**.
* Si intentas crear un índice compuesto (que cubra varias columnas), no puedes pasar de 32. Este límite se puede aumentar si recompilas PostgreSQL.


* **Índices por tabla:** **Ilimitado**.
* Puedes crear tantos como quieras, pero recuerda que cada índice ralentiza las inserciones (`INSERT`).

 

## 3. ¿Cómo cabe una fila de 1.6 TB en un bloque de 8 KB? (TOAST)

Esta es la pregunta del millón. Si el bloque (la unidad mínima de lectura) mide solo 8 KB, ¿cómo es posible que un campo de texto mida 1 GB o una fila 1.6 TB?

PostgreSQL usa una técnica llamada **TOAST** (*The Oversized-Attribute Storage Technique*):

1. **Compresión:** Si una fila supera los 2 KB, PostgreSQL intenta comprimirla.
2. **Almacenamiento "Fuera de línea":** Si aun comprimida es muy grande, PostgreSQL saca ese valor de la tabla principal y lo mueve a una **tabla secundaria (tabla TOAST)**.
3. **Puntero:** En la tabla original, solo deja un "puntero" (una dirección) de unos cuantos bytes que dice: *"El resto del contenido está en la tabla TOAST"*.

 
## 4. Otros límites importantes

* **Identificadores (Nombres):** Los nombres de tablas, columnas o índices tienen un límite de **63 caracteres** por defecto.
* **Particiones:** Aunque una tabla "hija" tiene el límite de 32 TB, puedes tener miles de particiones, lo que permite bases de datos de **Petabytes**.
* **Conexiones simultáneas:** Depende de tu RAM, pero usualmente se configura entre 100 y 1000. Para más que eso, se usan "Poolers" como PgBouncer.

 
### Un dato curioso sobre los 32 TB

Si alguna vez llegas a llenar una tabla con 32 Terabytes, no necesitas borrar datos. La solución estándar es el **Particionamiento**. Al particionar por fecha (por ejemplo, una tabla por cada año), cada año vuelve a tener su propio límite de 32 TB, extendiendo la vida de tu base de datos indefinidamente.

 

 

# links 
```
https://www.postgresql.org/docs/current/limits.html
https://www.postgresql.org/docs/current/storage-toast.html

https://stormatics.tech/blogs/postgresql-column-limits
https://www.dbi-services.com/blog/what-is-the-maximum-number-of-columns-for-a-table-in-postgresql/
https://www.enterprisedb.com/blog/postgresql-maximum-table-size
https://www.postgresql.org/docs/current/storage.html

```



