

# Arquitectura de almacenamiento de PostgreSQL

## Visibilidad
 La Visibilidad es el proceso por el cual PostgreSQL decide si una transacción específica tiene permitido ver una fila determinada, basándose en el estado de esas transacciones (xmin y xmax).

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

 
