 

# 2.- Anatomía de una Transacción: Modos de Lectura, Cursores y la Matriz de Bloqueos en Base de Datos

En la primera parte analizamos el ciclo de vida básico de una transacción y cómo los niveles de aislamiento controlan la visibilidad del tiempo a través de snapshots. Sin embargo, en entornos de producción con alta concurrencia y volúmenes masivos de datos, un arquitecto de software debe controlar tres herramientas críticas para evitar el colapso del sistema: el modo de la transacción, la transmisión eficiente de registros y el uso quirúrgico de la matriz de bloqueos (*Locks*).

---

## 1. Transacciones de Solo Lectura (`SET TRANSACTION READ ONLY`)

### Funcionamiento y Realidad Técnica

Cuando declaras una transacción como `READ ONLY`, le informas explícitamente al planificador de consultas de PostgreSQL que este bloque transaccional no realizará ninguna operación de escritura (`INSERT`, `UPDATE`, `DELETE` o modificaciones de esquema DDL).

```sql
BEGIN;
SET TRANSACTION READ ONLY;

-- Operaciones puras de lectura
SELECT * FROM reportes_financieros;

```

**¿Qué optimización ocurre internamente?**
PostgreSQL utiliza esta bandera para desactivar ciertos mecanismos de seguimiento de modificaciones en memoria y optimizar la sincronización de buffers. Además, si estás utilizando el nivel de aislamiento `SERIALIZABLE`, marcar la transacción como `READ ONLY` permite al motor SSI (*Serializable Snapshot Isolation*) omitir la verificación de ciertos conflictos de escritura, reduciendo drásticamente la probabilidad de que tu transacción sea abortada por dependencias cruzadas.

### 💡 La Analogía: El pase de visitante en el archivo nacional

Entras a una biblioteca histórica con un pase que te prohíbe estrictamente portar plumas o marcadores. El guardia de seguridad sabe de antemano que solo vas a consultar libros. Como no representas un riesgo de alteración física para los documentos, no es necesario que un supervisor vigile tu espalda en cada segundo; puedes moverte con mayor agilidad por los pasillos porque tu intención está pre-declarada como inofensiva.

---

## 2. Paginación Eficiente y Control de Memoria con Cursores (`DECLARE CURSOR`)

### Funcionamiento

Cuando ejecutas un `SELECT` tradicional sobre una tabla con millones de filas, PostgreSQL intenta empaquetar y enviar todo el conjunto de resultados al cliente de un solo golpe. Si la tabla es masiva, esto puede saturar la memoria RAM del servidor de aplicaciones (provocando errores de *Out of Memory*) o estrangular el ancho de banda de la red.

Un **Cursor** es un puntero transaccional que te permite segmentar la extracción de los datos. En lugar de descargar todo, dejas la consulta abierta en el servidor y vas "jalando" los registros en bloques controlados.

```sql
START TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- 1. Declaramos el cursor apuntando a la consulta masiva
DECLARE c1 CURSOR FOR 
    SELECT id, fecha, cliente_id, producto_id, cantidad, precio 
    FROM public.ventas;

-- 2. Extraemos las filas en bloques controlados (Paginación por streaming)
FETCH 10000 FROM c1; -- Recupera las primeras 10,000 líneas y mueve el puntero
FETCH 10000 FROM c1; -- Recupera las siguientes 10,000 líneas

COMMIT TRANSACTION;

```

> ⚠️ **Nota de Arquitectura:** El cursor está íntimamente ligado a la vida de la transacción. Si haces `COMMIT` o `ROLLBACK`, el cursor se destruye automáticamente (a menos que se declare explícitamente como `WITH HOLD`). Por ello, se recomienda usar el aislamiento `REPEATABLE READ` para asegurar que el universo de datos no mute entre cada ejecución de un `FETCH`.

### 💡 La Analogía: El dispensador de agua de garrafón

Si tienes sed y necesitas 20 litros de agua, no intentas voltear el garrafón entero sobre tu boca porque te ahogarías y derramarías el líquido (Saturación de RAM). En su lugar, instalas una llave despachadora **(El Cursor)**. El agua permanece segura en el contenedor principal del servidor, y tú vas llenando vasos controlados de 250ml **(`FETCH 10000`)** conforme tu cuerpo es capaz de procesarlos.

---

## 3. La Matriz de Bloqueos Explícitos en PostgreSQL (`LOCK TABLE`)

Cuando los niveles de aislamiento estándar de MVCC no son suficientes para prevenir condiciones de carrera complejas en la lógica de tu negocio, PostgreSQL te permite invocar bloqueos explícitos a nivel de tabla mediante el comando `LOCK TABLE`.

PostgreSQL maneja **8 modos de bloqueo en tablas**, ordenados de menor a mayor restricción. La regla de oro de la concurrencia dicta: *Dos modos de bloqueo colisionan si pertenecen a categorías que intentan modificar o leer la misma estructura al mismo tiempo.*

### Análisis Detallado de los Modos de Bloqueo

#### 1. `ACCESS SHARE`

* **Activación automática:** Por consultas de lectura pura (`SELECT`).
* **Comportamiento:** Es el modo más permisivo. Solo entra en conflicto con el nivel destructivo máximo (`ACCESS EXCLUSIVE`). Permite que miles de usuarios lean la tabla simultáneamente de forma concurrente.

#### 2. `ROW SHARE`

* **Activación automática:** Al ejecutar un `SELECT ... FOR SHARE` o `SELECT ... FOR UPDATE`.
* **Comportamiento:** Indica que la transacción tiene la intención de bloquear filas específicas dentro de la tabla en los siguientes pasos.

#### 3. `ROW EXCLUSIVE`

* **Activación automática:** Por comandos de manipulación de datos (`INSERT`, `UPDATE`, `DELETE`).
* **Comportamiento:** Informa al sistema que se están modificando filas internamente. Permite lecturas concurrentes de otros usuarios (`ACCESS SHARE`), pero bloquea operaciones que intenten alterar la estructura de la tabla al mismo tiempo.

#### 4. `SHARE UPDATE EXCLUSIVE`

* **Activación automática:** Por comandos de mantenimiento como `VACUUM` (sin full), `ANALYZE`, o creación de índices en modo concurrente (`CREATE INDEX CONCURRENTLY`).
* **Comportamiento:** Protege a la tabla contra modificaciones concurrentes de esquema o tareas de mantenimiento duplicadas, pero permite inserciones y actualizaciones normales de datos.

#### 5. `SHARE`

* **Activación automática:** Por la creación de índices tradicionales (`CREATE INDEX`).
* **Comportamiento:** Permite que otros usuarios sigan leyendo la tabla de forma masiva, pero bloquea instantáneamente cualquier intento de modificación de datos (`INSERT`, `UPDATE`, `DELETE`).

#### 6. `SHARE ROW EXCLUSIVE`

* **Activación explícita:** Invocado manualmente.
* **Comportamiento:** Permite lecturas concurrentes, pero solo una transacción a la vez puede mantener este bloqueo para realizar modificaciones secuenciales, evitando la concurrencia de escrituras.

#### 7. `EXCLUSIVE`

* **Activación explícita:** Invocado manualmente.
* **Comportamiento:** Permite únicamente lecturas puras (`ACCESS SHARE`). Bloquea absolutamente todo lo demás, incluyendo inserciones concurrentes y bloqueos de tipo `SHARE`.

#### 8. `ACCESS EXCLUSIVE`

* **Activación automática:** Por comandos destructivos o de alteración estructural pesada (`DROP TABLE`, `ALTER TABLE`, `TRUNCATE`, `VACUUM FULL`).
* **Comportamiento:** **El bloqueo absoluto.** Garantiza que la transacción actual es la dueña única y exclusiva de la tabla. Nadie puede escribir, y crucialmente, **nadie puede leer** (bloquea incluso un `SELECT` ordinario).

---

## 4. Estudio de Caso en Producción: Evitando la Corrupción de Datos con Bloqueos Absolutos

Imagina que tienes una tabla crítica de configuración de reglas de escaneo de seguridad llamada `fdw_conf.scan_rules_query`. Necesitas ejecutar una purga y limpieza de IDs obsoletos, pero requieres la garantía matemática absoluta de que **ningún microservicio intente leer o inyectar una regla intermedia** mientras realizas el borrado, ya que un procesamiento parcial rompería las políticas de seguridad de la infraestructura.

Para resolver este problema de alta criticidad, se aplica un bloqueo pesimista en el nivel máximo de restricción:

```sql
BEGIN;

-- 1. Tomamos el control absoluto de la tabla.
-- Si hay microservicios ejecutando SELECTs o INSERTs en este segundo, 
-- esta consulta esperará pacientemente a que ellos terminen. 
-- Una vez adquirido el candado, todos los demás procesos del ecosistema se congelarán.
LOCK TABLE fdw_conf.scan_rules_query IN ACCESS EXCLUSIVE MODE;

-- 2. Ejecutamos la operación de depuración con la tabla aislada del universo
DELETE FROM fdw_conf.scan_rules_query WHERE id = 1042;

-- 3. Al hacer COMMIT, los datos se salvan y el candado ACCESS EXCLUSIVE se destruye automáticamente,
-- permitiendo que las conexiones en cola reanuden sus lecturas y escrituras al milisegundo.
COMMIT;

```

### El Riesgo Arquitectónico de este enfoque

El modo `ACCESS EXCLUSIVE` debe usarse con extrema precaución en ambientes productivos. Si la consulta `DELETE` tarda varios minutos en ejecutarse debido a la falta de índices o a un volumen masivo de registros, **toda tu aplicación parecerá caída o congelada**, ya que cualquier consulta ordinaria de lectura quedará encolada detrás de este bloqueo pesado, provocando picos de CPU y saturación en el pool de conexiones (*Contención de recursos*).



---

 

# 5. Control de Concurrencia Fina: Cláusulas de Bloqueo a Nivel de Fila (`FOR`)

Mientras que el comando `LOCK TABLE` paraliza estructuras completas de datos, la verdadera optimización en sistemas de alta concurrencia radica en aplicar **bloqueos quirúrgicos a nivel de fila**. PostgreSQL proporciona la familia de cláusulas `FOR` dentro de las sentencias `SELECT`, permitiendo que una transacción declare su intención sobre un registro específico y obligue a las transacciones concurrentes a alinearse o reaccionar de manera controlada.

---

## 🛠️ Las Cuatro Variantes de Bloqueo Explicito (`FOR`)

Cuando ejecutas un `SELECT ... FOR [MODO]`, el motor de almacenamiento de PostgreSQL coloca un candado directamente en las tuplas (filas) físicas del disco. Estas variantes van desde la restricción absoluta hasta la convivencia óptima en relaciones de clave foránea.

### 1. `FOR UPDATE`

* **Comportamiento:** Es el bloqueo de fila más restrictivo. Bloquea las filas seleccionadas de manera que ninguna otra transacción puede modificarlas, eliminarlas (`DELETE`) ni ejecutar sobre ellas ningún otro bloqueo de tipo `FOR UPDATE`, `FOR NO KEY UPDATE` o `FOR SHARE`.
* **Uso típico:** Operaciones críticas donde se sabe con certeza que la fila va a ser mutada en los siguientes milisegundos (patrón *Read-Modify-Write*).

### 2. `FOR NO KEY UPDATE`

* **Comportamiento:** Un modo más inteligente y optimizado. Bloquea las filas para su modificación, pero **permite que otras transacciones concurrentes actualicen campos que no estén indexados como claves únicas (`UNIQUE`) o claves primarias (`PRIMARY KEY`)**.
* **Uso típico:** Es el bloqueo por defecto que utiliza PostgreSQL internamente cuando ejecutas un `UPDATE` ordinario que no altera las llaves de la tabla.

### 3. `FOR SHARE`

* **Comportamiento:** Modela un bloqueo compartido. Permite que múltiples transacciones concurrentes lean la fila o incluso adquieran su propio `FOR SHARE` simultáneamente, pero **bloquea por completo cualquier intento de mutación o escritura** (`UPDATE`/`DELETE`) por parte de otros usuarios.
* **Uso típico:** Garantizar que un registro maestro no va a desaparecer ni cambiar mientras tú calculas una operación derivada de él.

### 4. `FOR KEY SHARE`

* **Comportamiento:** El nivel más permisivo de la familia. Permite que otras transacciones lean e incluso modifiquen valores de la fila, **siempre y cuando sus actualizaciones no alteren ninguna clave primaria o foránea**.
* **Uso típico:** Es el mecanismo interno que utiliza Postgres para validar la integridad referencial. Si estás insertando un hijo, Postgres ejecuta un `FOR KEY SHARE` en el padre para asegurar que nadie borre al padre a mitad de la inserción.

```sql
-- Sintaxis de Ejecución de las Cláusulas
SELECT * FROM empleados WHERE id = 1 FOR UPDATE;
SELECT * FROM empleados WHERE id = 1 FOR NO KEY UPDATE;
SELECT * FROM empleados WHERE id = 1 FOR SHARE;
SELECT * FROM empleados WHERE id = 1 FOR KEY SHARE;

```

---

## ⚡ Modificadores de Comportamiento: `NOWAIT` y `SKIP LOCKED`

Por defecto, si una Terminal B intenta ejecutar un `FOR UPDATE` sobre una fila que ya está bloqueada por la Terminal A, la Terminal B se quedará congelada haciendo fila (*contención*). PostgreSQL introduce dos modificadores potentes para alterar este comportamiento secuencial:

### A. `NOWAIT` (Fallo Inmediato)

Le ordena a la consulta abortar e lanzar un error de forma inmediata en el backend si la fila objetivo ya está bajo el control de otra transacción.

* **Ventaja:** Evita que tu hilo de ejecución de la aplicación se quede colgado consumiendo recursos del pool de conexiones.

```sql
SELECT * FROM empleados WHERE id = 1 FOR UPDATE NOWAIT;
-- Si está bloqueado, Postgres aborta de inmediato con: 
-- ERROR: could not obtain lock on row in relation "empleados"

```

### B. `SKIP LOCKED` (Ignorar Concurrencia - El Motor de Colas)

Es uno de los componentes más potentes de Postgres para la ingeniería de software. Si las filas resultantes de tu consulta están bloqueadas por otra transacción, **Postgres las salta silenciosamente y te devuelve las filas libres que sigan disponibles**.

* **Ventaja:** Permite que múltiples procesos paralelos consuman registros de la misma tabla sin estorbarse ni generar contención pesada.

```sql
SELECT * FROM empleados WHERE estado = 'PENDIENTE' LIMIT 1 FOR UPDATE SKIP LOCKED;

```

---

## 🎯 ¿Por qué usar estas cláusulas? (Objetivos de Arquitectura)

1. **Eliminación Total de Condiciones de Carrera (*Race Conditions*):** Aseguran la linealidad del sistema. Si dos usuarios intentan comprar exactamente el último boleto de un concierto al mismo milisegundo, el `FOR UPDATE` obliga a un proceso a ir detrás del otro.
2. **Blindaje en Operaciones *Read-Modify-Write*:** Evita que el dato cambie entre el momento en que tu Backend lo lee para tomar una decisión de lógica de negocio y el momento en que escribe el resultado final.
3. **Escalabilidad Horizontal en Workers Paralelos:** Mediante `SKIP LOCKED`, se elimina la necesidad de herramientas externas especializadas en mensajería (como RabbitMQ o Redis) para flujos de trabajo medianos, permitiendo usar las tablas nativas de Postgres como colas de tareas ultra eficientes.

---

## 🗺️ Patrones de Diseño en Proyectos Reales

A continuación se detallan los escenarios de producción donde la implementación de estas cláusulas separa a un software ordinario de una arquitectura resiliente:

### 1. Motores Financieros y Transferencias Bancarias

* **Escenario:** Procesamiento de retiros o transferencias entre cuentas corrientes de alta actividad.
* **Solución:** Se aplica un `FOR UPDATE` estricto al consultar el saldo de la cuenta origen antes de validar si tiene fondos suficientes. Esto bloquea cualquier otro cargo en paralelo (como un cobro domiciliado automático) evitando que la cuenta caiga en saldos negativos ilegales.

### 2. Logística, Inventarios y E-Commerce

* **Escenario:** Venta de productos con stock limitado o asignación de unidades físicas en almacenes a camiones repartidores.
* **Solución:** Al momento en que el usuario le da clic a "Pagar", el sistema ejecuta un `SELECT ... FOR UPDATE` sobre la fila del inventario de ese SKU. Si hay existencias, decrementa el stock de forma segura. Ningún otro carrito puede leer ese inventario como disponible mientras dure el pago.

### 3. Sistemas de Reservas de Alta Densidad (Boletos, Asientos y Habitaciones)

* **Escenario:** Dos usuarios eligen exactamente la misma butaca de cine o habitación de hotel al mismo tiempo.
* **Solución:** Al seleccionar el asiento, la transacción ejecuta un `SELECT ... FOR UPDATE NOWAIT`. Si el usuario A llegó un milisegundo antes, el usuario B recibirá un error limpio en su pantalla inmediatamente: *"Este asiento está siendo reservado por otro usuario, elige uno diferente"*, sin congelar la interfaz del usuario B.

### 4. Sistemas de Asignación de Tareas y Colas de Mensajes Nativas

* **Escenario:** Una tabla actúa como bandeja de entrada de trabajos pendientes (`jobs_queue`), y tienes 20 microservices independientes (*workers*) levantados intentando procesar tareas en paralelo.
* **Solución:** Cada *worker* ejecuta de forma continua el siguiente patrón de código de alta velocidad:

```sql
BEGIN;

-- El worker toma un solo trabajo libre, bloqueándolo para sí mismo e ignorando los que ya procesan sus compañeros
DECLARE tarea_asignada CURSOR FOR 
    SELECT id FROM jobs_queue 
    WHERE estado = 'PENDIENTE' 
    ORDER BY creado_at ASC 
    LIMIT 1 
    FOR UPDATE SKIP LOCKED;

FETCH FROM tarea_asignada;

-- Se ejecuta la lógica pesada en el backend...
UPDATE jobs_queue SET estado = 'PROCESADO' WHERE id = [ID_RECUPERADO];

COMMIT;

```

Este diseño garantiza un paralelismo perfecto con **cero contención**, permitiendo que tu base de datos escale horizontalmente el procesamiento por lotes sin que dos bots tomen o dupliquen el mismo trabajo.
