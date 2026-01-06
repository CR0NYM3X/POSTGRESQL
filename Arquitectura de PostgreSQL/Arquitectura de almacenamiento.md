

# Arquitectura de almacenamiento de PostgreSQL


## 1. ¿Qué es el Visibility Map?

Es un archivo físico independiente que acompaña a cada tabla (relación). Se identifica en el directorio de datos con el sufijo `_vm` (ej. si tu tabla es el archivo `12345`, el mapa es `12345_vm`).

Físicamente, es un mapa de bits muy ligero: utiliza solo **2 bits por cada página** (bloque de 8KB) de la tabla.

### Los 2 bits mágicos:

1. **Bit de "All-visible" (Todo visible):** Indica que todas las filas (tuplas) de esa página son visibles para todas las transacciones actuales y futuras. Es decir, **no hay "filas muertas"** (bloat) en esa página.
2. **Bit de "All-frozen" (Todo congelado):** Indica que todas las filas de la página han sido "congeladas" (viejas de forma permanente), lo que ayuda a evitar el problema del *Transaction ID Wraparound*.


## 2. ¿Para qué sirve? (Objetivos principales)

El VM tiene dos funciones vitales para el rendimiento:

### A. Optimización del VACUUM (El "Salto Inteligente")

Sin el VM, el proceso de `VACUUM` tendría que escanear cada una de las páginas de una tabla para buscar basura.

* **Con el VM:** El `VACUUM` consulta el mapa de bits. Si ve que una página está marcada como "all-visible", **se la salta**. Esto reduce drásticamente el I/O del sistema, permitiendo que el mantenimiento sea mucho más rápido en tablas grandes.

### B. Habilitar el Index-Only Scan

Como vimos antes, Postgres necesita verificar si una fila es visible antes de entregarla (por el MVCC).

* **El Problema:** El índice no tiene información de visibilidad.
* **La Solución:** El ejecutor consulta el Visibility Map. Si el bit de la página es "all-visible", Postgres sabe que los datos del índice son seguros y **no necesita leer la tabla**. Sin VM, los *Index-Only Scans* no existirían.



## 3. Otros mecanismos al mismo nivel

En la arquitectura de archivos de Postgres, el Visibility Map no está solo. Existen otros archivos complementarios que operan al mismo nivel de la "capa de almacenamiento":

### A. Free Space Map (FSM)

Es el "hermano" del VM (archivo con sufijo `_fsm`).

* **Función:** Mantiene un registro de cuánto espacio libre hay en cada página de la tabla.
* **Objetivo:** Cuando haces un `INSERT`, Postgres consulta el FSM para encontrar rápidamente una página donde quepa el nuevo dato, en lugar de escanear toda la tabla o simplemente añadirlo al final, lo cual evita que el archivo crezca innecesariamente.

### B. The Main Fork (La horquilla principal)

Es el archivo que contiene los datos reales de la tabla. El VM y el FSM son "forks" (ramas) auxiliares que sirven para gestionar la eficiencia del Main Fork.

### C. WAL (Write Ahead Log)

Aunque vive en un directorio diferente (`pg_wal`), opera al mismo nivel lógico de persistencia. Cualquier cambio en el VM o en las páginas de datos debe registrarse primero en el WAL para garantizar que, si el servidor se apaga, la base de datos sea consistente.


### Resumen comparativo para tus alumnos:

| Mecanismo | ¿Qué rastrea? | Objetivo Principal |
| --- | --- | --- |
| **Visibility Map (VM)** | Páginas sin filas muertas. | Acelerar VACUUM e Index-Only Scans. |
| **Free Space Map (FSM)** | Espacio disponible en páginas. | Acelerar los INSERTs y reutilizar espacio. |
| **Main Fork** | Los datos reales (tuplas). | Almacenamiento de la información. |

---


# Visibilidad
 
 La Visibilidad es el proceso por el cual PostgreSQL decide si una transacción específica tiene permitido ver una fila determinada, basándose en el estado de esas transacciones (xmin y xmax).



Para entender **cómo** PostgreSQL toma esta decisión en tiempo real, debemos entrar en las tripas del **MVCC (Multi-Version Concurrency Control)**.

No es solo mirar los números `xmin` y `xmax`, sino compararlos contra algo llamado **Snapshot (Instantánea)** y consultar un registro de estados llamado **CLOG**.

Aquí tienes el paso a paso técnico de cómo ocurre esa "magia":

 

### 1. Los protagonistas: `xmin` y `xmax`

Cada vez que insertas o modificas una fila, Postgres guarda ocultamente:

* **`xmin`:** El ID de la transacción que **creó** la fila.
* **`xmax`:** El ID de la transacción que **borró o modificó** la fila. Si la fila está vigente, el `xmax` es `0`.

### 2. El "Snapshot" (La foto del momento)

Cuando inicias una consulta (o una transacción, dependiendo del nivel de aislamiento), PostgreSQL toma una "foto" del estado del sistema. Este snapshot contiene:

* **Xmin del snapshot:** El ID de la transacción más antigua que aún está activa.
* **Xmax del snapshot:** El ID de la próxima transacción que se asignará (cualquier ID igual o mayor a este es el "futuro" y no es visible).
* **Lista de transacciones activas:** Una lista de IDs que están trabajando justo ahora pero no han terminado (no han hecho `COMMIT`).

### 3. El CLOG (Commit Log)

Los números `xmin` y `xmax` por sí solos no dicen si la transacción tuvo éxito. Postgres consulta el **CLOG**, un área de memoria que guarda el estado de cada transacción: ¿Está en curso?, ¿Hizo Commit?, ¿Hizo Rollback?

---

### 4. El Algoritmo de Visibilidad (Simplificado)

Cuando tu consulta llega a una fila, aplica estas reglas lógicas para decidir si la "ve" o la ignora:

#### Para el `xmin` (¿Quién la creó?):

1. **¿El `xmin` abortó?** (Vía CLOG). Si la transacción que la creó falló, la fila es **invisible**.
2. **¿El `xmin` todavía no hace commit?** Si la transacción sigue activa, la fila es **invisible** (a menos que seas tú mismo quien la creó).
3. **¿El `xmin` es "el futuro"?** Si el ID es mayor al límite de tu snapshot, la fila es **invisible**.
4. **¿El `xmin` hizo commit?** Si el CLOG dice que sí y el ID es "pasado" para tu snapshot, pasamos a revisar el `xmax`.

#### Para el `xmax` (¿Quién la borró?):

1. **¿El `xmax` es 0?** Significa que nadie la ha borrado. **¡La fila es VISIBLE!**
2. **¿El `xmax` abortó?** La transacción que intentó borrarla falló. **¡La fila es VISIBLE!**
3. **¿El `xmax` hizo commit?** La fila fue borrada definitivamente por alguien más antes de tu foto. **Fila INVISIBLE**.
4. **¿El `xmax` está activo o es el futuro?** Alguien la está borrando ahora mismo o después de tu foto, pero para ti, sigue existiendo. **¡La fila es VISIBLE!**

 
### Ejemplo Práctico: El Update

Cuando haces un `UPDATE` de una fila, PostgreSQL no cambia los datos ahí mismo. Hace esto:

1. **En la fila vieja:** Marca el `xmax` con el ID de tu transacción actual. (Para otros, sigue siendo visible hasta que tú hagas commit).
2. **Crea una fila nueva:** Con los datos nuevos y pone tu ID actual en el `xmin`. (Nadie la verá hasta que tú hagas commit).

**Resultado:** Dependiendo de cuándo "tomaron la foto" las demás transacciones, algunas verán la versión vieja y otras (las que lleguen después de tu commit) verán la nueva. **Esto es lo que permite que Postgres lea y escriba al mismo tiempo sin bloquearse.**

### ¿Por qué esto es importante?

Este proceso explica por qué PostgreSQL necesita el **VACUUM**. Como las filas "borradas" (con un `xmax` válido y comprometido) siguen físicamente en el disco, el VACUUM debe pasar eventualmente para ver qué filas ya no son visibles para **nadie** en el sistema y liberar ese espacio.
 
----
----
----
----
### Arquitectura de PostgreSQL  #3
```
-- Explicar y tambien enseñar los parámetros que controlan el comportamiento.


 .- Estructura del Directorio de Datos
		.- pg_wal
		.- pg_global
		.- pg_default
		.- DATA
 .- Arquitectura de almacenamiento. 
		.- método de acceso Tablas heap y Indice B-Tree (el sistema que utiliza para organizar, almacenar y recuperar datos de manera eficiente dentro de la base de datos)
		.- (Page, archivos, vistas )
		.- Toast
		.- método de acceso heap
		.- Storage
		.- HOT
		.- Tipos de Compresión en PostgreSQL
 .- WALs
 .- Memoria 
		.- (Buffer, Paginas Gigantes)
 .- MVCC 
 .- Mantimiento
 .- Ciclo de vida de consultas y Escritura (UPD,INS,DEL)

 .- ACID 
 .- Aislamiento (READ COMMITTED, SERIALIZABLE)
 .- Metadatos 
 .- 
 .- fillfactor
 .- 
 .- 
 .- 
 .- 
 .- 
 .- 
```
