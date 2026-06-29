 

# 6. Anatomía de Bajo Nivel: La Estructura de una Transacción (`xact`)

Cuando ejecutas un comando `BEGIN`, PostgreSQL no altera el disco duro de inmediato. En su lugar, el proceso backend asigna una estructura interna en la memoria compartida llamada **`xact`** (abreviación de *Transaction Space* o Espacio Transaccional).

---

## 🪪 La Asignación del ID de Transacción (`XID` o `txid`)

Uno de los mayores secretos de rendimiento de PostgreSQL es que **no todas las transacciones reciben un número identificador oficial**.

* **Transacciones Virtuales (`VXID`):** Si abres un `BEGIN` y solo ejecutas instrucciones `SELECT` (Lecturas), Postgres te asigna un identificador virtual ligero (`Virtual XID`). Esto evita consumir espacio en las tablas del sistema y optimiza la concurrencia.
* **Transacciones Reales (`XID` / `txid`):** En el microsegundo exacto en que tu transacción ejecuta su primera operación de escritura (`INSERT`, `UPDATE`, `DELETE` o `LOCK TABLE`), el motor le asigna un **ID de Transacción Real**. Este es un número entero secuencial de 32 bits (por ejemplo, `XID 49090505`).

---

## 🗺️ El Mapa de Bits Global: `pg_xact` (Antiguamente `pg_clog`)

¿Cómo sabe una terminal concurrente si el cambio que hizo tu transacción ya es válido o debe ignorarse? A través del subcomponente arquitectónico **`pg_xact`** (*Transaction Status Log*).

`pg_xact` es un mapa de bits extremadamente optimizado y residente en la memoria RAM (dentro de los buffers de Postgres) que se vuelca al disco duro de forma secuencial. Para cada `XID` del universo, Postgres reserva exactamente **2 bits** de memoria para almacenar su estado actual.

Existen cuatro estados posibles en los transistores de `pg_xact`:

1. `00` — **IN_PROGRESS:** La transacción se está ejecutando actualmente. Sus cambios son invisibles para el resto del mundo.
2. `01` — **COMMITTED:** La transacción terminó con éxito. Sus cambios son oficialmente parte de la realidad de la base de datos.
3. `10` — **ABORTED (ROLLBACK):** La transacción falló o el usuario se arrepintió. Sus cambios deben ser ignorados para siempre.
4. `11` — **SUB_COMMITTED:** Estado especial utilizado para transacciones secundarias o puntos de control (`SAVEPOINT`).

> ⚡ **El secreto del COMMIT instantáneo:** Cuando escribes `COMMIT`, Postgres no va a buscar todas las filas que modificaste para cambiarles el estado individualmente (eso tardaría minutos en tablas gigantes). Lo único que hace Postgres es cambiar los 2 bits de tu `XID` en el archivo `pg_xact` de `00` (`IN_PROGRESS`) a `01` (`COMMITTED`). Ese cambio de 2 bits toma nanosegundos y vuelve tus datos visibles al mundo instantáneamente.

---

## 🏷️ Los Metadatos Invisibles de la Fila: `xmin` y `xmax`

Cada vez que creas o modificas un registro, Postgres añade a la fila física (la tupla) un encabezado oculto de metadatos de control. Los dos campos más importantes de esta cabecera son los punteros de transacción:

### A. `xmin` (El creador)

Almacena el `XID` de la transacción que **insertó** la fila en el disco duro.

```sql
-- Si la transacción 5000 inserta un usuario, la tupla se guarda en el disco con:
xmin = 5000

```

### B. `xmax` (El destructor o bloqueador)

Almacena el `XID` de la transacción que **eliminó o modificó** la fila. Si la fila está intacta y viva en el presente, su valor por defecto es `0`.

```sql
-- Si la transacción 6000 ejecuta un DELETE sobre esa fila, Postgres no la borra del disco de inmediato. 
-- Solo estampa el metadato:
xmax = 6000

```

### 🔁 ¿Cómo se representa un `UPDATE` bajo esta arquitectura?

En PostgreSQL, un `UPDATE` es físicamente la combinación de un `DELETE` seguido de un `INSERT`. Si modificas el nombre de un usuario:

1. La fila original se marca en su cabecera con `xmax = [Tu_XID]` (indicando que esa versión de la fila "murió" para el futuro).
2. Se escribe una fila completamente nueva a un lado en el disco con los nuevos datos y una cabecera `xmin = [Tu_XID]` (indicando que esta es la versión viva).

---

## 📸 Las entrañas del Snapshot: Las tres variables lógicas

En el módulo anterior vimos que ejecutas `SELECT pg_current_snapshot()` y obtienes una cadena como `125:130:126,128`. Ahora que entiendes los identificadores `XID`, podemos descifrar exactamente la matemática que utiliza el motor para calcular la visibilidad en milisegundos:

Un snapshot se compone internamente de tres límites rígidos:

1. **`xmin` (Límite Inferior del Snapshot):** El ID de la transacción más antigua que sigue activa en el sistema. Cualquier transacción con un `XID` menor a este número ya hizo `COMMIT` antes de tu fotografía, por lo tanto, sus cambios son **100% visibles** para ti.
2. **`xmax` (Límite Superior del Snapshot):** El siguiente identificador secuencial de transacción que Postgres va a asignar en el futuro. Ninguna transacción con un `XID` igual o mayor a este número existía al momento de tu foto, por lo tanto, sus cambios son **100% invisibles** para ti.
3. **`xip_list` (Lista de Excepciones):** Las transacciones que se encuentran en el limbo (con estado `IN_PROGRESS` en `pg_xact`) en el instante preciso en el que tomaste la foto. Aunque sus IDs sean menores que tu límite superior, tu snapshot las ignorará activamente porque aún no se ha consolidado su información.

---

## 🧹 El Vacuador (`VACUUM`) y el peligro del desbordamiento (*XID Wraparound*)

Dado que el `XID` es un número de 32 bits, el motor solo tiene disponibles un máximo de **4,294,967,295 (4 mil millones)** de identificadores de transacciones únicos. ¿Qué pasa cuando una base de datos en producción alcanza la transacción número 4,000 millones? El contador vuelve a cero (`0`).

Si esto ocurriera sin control, la transacción `1` del futuro miraría una fila creada en el pasado por la transacción `3,000,000,000` y, por pura matemática de snapshots (`1 < 3,000,000,000`), Postgres pensaría que esa fila pertenece al futuro y la volvería **invisible**, corrompiendo y desapareciendo bases de datos enteras de la noche a la mañana.

### Cómo lo previene la arquitectura de Postgres:

Para evitar esta catástrofe lúdica, la memoria compartida divide el espacio de transacciones a la mitad: 2 mil millones de transacciones están en el "pasado" y 2 mil millones en el "futuro".

El proceso en segundo plano llamado **`VACUUM`** recorre continuamente las tablas buscando filas viejas cuyas transacciones creadoras (`xmin`) ya sean extremadamente antiguas. El vacuador congela estas filas cambiando su cabecera interna a una bandera especial llamada **`FrozenXID`**.

Una fila marcada como congelada es tratada por la arquitectura de Postgres como una fila "ancestral", volviéndose permanentemente visible para todas las transacciones presentes y futuras, reiniciando de forma segura el ciclo de vida del contador de la base de datos sin interrumpir las operaciones en producción.
