# Roadmap de Aprendizaje
 **Roadmap de Aprendizaje** estructurado lógicamente. Este plan va desde lo físico (cómo se guardan los bytes) hasta lo lógico (cómo el motor "entiende" y ejecuta tu SQL), cubriendo la arquitectura semántica y estructural.

Aquí tienes tu ruta de estudio recomendada:

### Nivel 1: La Base Física (Archivos y Directorios)
Antes de entender la lógica, debes entender dónde vive la información. PostgreSQL no es magia, es un sistema organizado de archivos.

1.  **Estructura del Directorio de Datos (`$PGDATA`):**
    *   Todo comienza en el directorio base. Debes familiarizarte con subdirectorios clave como `base/` (donde viven las bases de datos), `global/` (metadatos del clúster) y `pg_wal/` (logs de transacciones).
    *   Comprende que cada base de datos y tabla tiene un identificador numérico llamado OID y que los archivos físicos se nombran usando estos números (por ejemplo, `25153` podría ser tu tabla de usuarios),.
2.  **Segmentación de Archivos:**
    *   Aprende que PostgreSQL escribe datos secuencialmente en archivos "Heap". Cuando un archivo alcanza 1GB, se crea uno nuevo (ej. `25156.1`), dividiendo la tabla en segmentos manejables.

# Segmentos 

## Tamaños base en PostgreSQL

*   **Tamaño de página (block)**: **8 KB**  
    (valor por defecto y el más común)
*   **Tamaño de segmento**: **1 GB**  
    (valor fijo a nivel de código del motor, no configurable)

 
 **Un segmento de PostgreSQL contiene exactamente:**

### **131,072 páginas de 8 KB**

 

## Cómo se refleja en la práctica

*   Cada archivo físico de una tabla o índice (`base/…/relfilenode`, `relfilenode.1`, `relfilenode.2`, etc.)
*   Tiene **máximo 1 GB**
*   Cuando se llena, PostgreSQL crea automáticamente el siguiente segmento

Ejemplo:

```text
16384        → hasta 1 GB (131,072 páginas)
16384.1      → siguiente 1 GB
16384.2      → siguiente 1 GB
```
 
---

### Nivel 2: La Unidad Atómica (Páginas y Bloques)
Este es el "ladrillo" fundamental de la arquitectura. Si no dominas la "Página", no dominarás PostgreSQL.

1.  **El Concepto de Página (Page/Block):**
    *   PostgreSQL divide sus archivos en bloques de tamaño fijo, normalmente de **8KB (8192 bytes)**.
    *   Tanto la lectura como la escritura se hacen a nivel de página, no fila por fila. Esto es crucial para entender el rendimiento de I/O.
2.  **Diseño de la Página (Slotted Page Layout):**
    *   Estudia la anatomía interna de una página:
        *   **PageHeader:** 24 bytes con metadatos y punteros al espacio libre,.
        *   **Item Pointer Array:** Un arreglo al inicio que apunta a la ubicación exacta de las filas al final de la página.
        *   **Tuplas (Filas):** Los datos reales crecen desde el final de la página hacia el centro, mientras que los punteros crecen desde el inicio hacia el centro. El espacio libre queda en medio.
    *   Entiende el **CTID**: Es el identificador físico de una fila, compuesto por `(número_de_página, índice_de_tupla)`.

### Nivel 3: Métodos de Acceso (Índices)
Una vez que sabes cómo se guardan los datos, debes estudiar cómo encontrarlos sin leerlo todo.

1.  **Índices B-Tree y B+ Tree:**
    *   PostgreSQL utiliza principalmente árboles B+ (B-Plus Trees). A diferencia de un árbol binario, estos son anchos y poco profundos para minimizar las lecturas de disco,.
    *   **Diferencia Clave:** En un B+ Tree, solo las "hojas" (leaf nodes) tienen punteros a los datos reales (CTIDs); los nodos internos solo sirven para navegar.
2.  **Índices "No Agrupados" (Non-Clustered):**
    *   Es vital entender que en PostgreSQL, **todos** los índices son secundarios. El índice no contiene la tabla; contiene un puntero (CTID) que dice "ve a la página X, ítem Y" para buscar el dato en el "Heap",.
3.  **Estrategias de Indexación:**
    *   Estudia cómo funcionan los índices compuestos, los índices parciales (con cláusula `WHERE`) y los "Index-Only Scans" (donde no hace falta ir a la tabla principal si el índice tiene todos los datos necesarios),.

### Nivel 4: El Cerebro Semántico (El Ciclo de Vida de una Consulta)
Aquí es donde entras en la "arquitectura semántica" pura: ¿Cómo convierte PostgreSQL un texto SQL en acciones?

1.  **Tokenización y Parsing (Análisis Gramatical):**
    *   El sistema rompe tu consulta en "tokens" (palabras clave, identificadores) y crea un **Árbol de Análisis (Parse Tree)** basado en reglas gramaticales,. Aquí se detectan errores de sintaxis (como una coma faltante).
2.  **Análisis Semántico (Semantic Analysis):**
    *   **Punto Crítico:** Aquí el motor verifica si la consulta tiene sentido. ¿Existen las tablas? ¿Los tipos de datos coinciden (ej. comparar texto con números)? ¿Tienes permisos?,.
    *   El "Parse Tree" se convierte en un "Query Tree" enriquecido con información del catálogo del sistema.
3.  **Reescritura (Rewriting):**
    *   Aprende cómo el sistema transforma tu consulta si usas Vistas (Views) o reglas. Por ejemplo, si consultas una vista, el reescritor sustituye el nombre de la vista por la subconsulta real que la define.
4.  **Planificación (Planning):**
    *   El optimizador decide *cómo* ejecutar la consulta (Scan Secuencial vs. Index Scan) basándose en estadísticas y costos. Es el cerebro que busca la ruta más eficiente,.

### Nivel 5: Gestión de Memoria y Consistencia (El Sistema Vivo)
Finalmente, domina cómo PostgreSQL maneja los datos en movimiento para asegurar que no se pierdan.

1.  **Shared Buffers y Dirty Pages:**
    *   PostgreSQL no escribe en disco inmediatamente. Modifica las páginas en memoria (Shared Buffers), marcándolas como "sucias" (Dirty Pages).
2.  **El Ciclo de Escritura (WAL y Checkpoints):**
    *   **WAL (Write-Ahead Log):** Antes de tocar los archivos de datos, el cambio se registra en el WAL para asegurar durabilidad ante fallos.
    *   **Background Writer y Checkpointer:** Procesos que bajan las páginas sucias al disco de forma controlada para evitar picos de I/O,.
3.  **Mantenimiento (VACUUM):**
    *   Entiende que `DELETE` en PostgreSQL no borra datos, solo los marca como "invisibles". Necesitas procesos como `VACUUM` para reclamar ese espacio y limpiar punteros muertos en los índices,.

### Analogía para Consolidar
Para entender la **arquitectura semántica** (Nivel 4), imagina una biblioteca antigua:
1.  **Parser:** El bibliotecario escucha tu petición y verifica que hables el idioma correcto (Sintaxis).
2.  **Análisis Semántico:** Verifica en el catálogo si el libro existe y si tienes carnet de socio (Validación).
3.  **Planner:** Decide si busca en el índice de tarjetas o camina pasillo por pasillo (Planificación).
4.  **Executor:** Camina físicamente, saca el libro y te lo entrega (Ejecución).

Te sugiero comenzar explorando tu directorio de datos local (`ls -l $PGDATA/base`) como se menciona en tus fuentes, y luego usar extensiones como `pageinspect` para ver el interior de una página real.  




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
		.- (Share Buffer [MMAP vs POSIX] , Paginas Gigantes, CLOG Buffers, WAL Buffer)
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

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
https://postgreshelp.com/postgresql-dynamic-shared-memory-posix-vs-mmap/


```


