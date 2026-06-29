
# Transacciones

En el mundo de las bases de datos, una **transacción** es **una sola unidad de trabajo que contiene múltiples operaciones, las cuales deben ejecutarse bajo la premisa de "todo o nada"**.
en postgresql para iniciar con una transaccion empaquetada puede hacerlo con `BEGIN` o `START TRANSACTION` que es lo mismo.
 

## 1. La Analogía Clásica: Una Compra en Línea

Imagina que entras a una tienda de ropa en línea y decides comprar una playera de $20 dólares. Cuando haces clic en "Confirmar Pago", el sistema tiene que hacer tres cosas en su base de datos:

1. **Operación 1:** Verificar que haya stock y restar 1 playera del inventario (`UPDATE inventario...`).
2. **Operación 2:** Restar $20 dólares del saldo de tu tarjeta de crédito (`UPDATE cuentas...`).
3. **Operación 3:** Crear una orden de envío para el equipo de paquetería (`INSERT INTO envios...`).

### ¿Qué pasa si el sistema falla a la mitad?

Imagina que la Operación 1 y la Operación 2 ocurren con éxito, pero justo cuando el sistema va a crear la orden de envío (Operación 3), el servidor se queda sin luz.

Si no existieran las transacciones, te quedarías sin tus $20 dólares, la tienda tendría una playera menos, pero nadie te enviaría nada. El sistema habría quedado en un estado corrupto e inconsistente.

Una **transacción** es la caja de seguridad que envuelve a esas tres operaciones. Si la operación 3 falla, la transacción entera se cancela y la base de datos mágicamente "rebobina" el tiempo, devolviéndote tus $20 dólares y regresando la playera al inventario.



## 2. El Estándar de Oro: Las Propiedades ACID

Para que un motor de bases de datos (como PostgreSQL, Oracle o MySQL) pueda decir que soporta transacciones reales, debe garantizar estrictamente cuatro propiedades matemáticas y lógicas, conocidas por el acrónimo **ACID**:

### 🅰️ Atomaticidad (*Atomicity*)

La transacción es un "átomo": no se puede dividir. O se ejecutan todas las operaciones dentro de ella con éxito (**`COMMIT`**), o no se ejecuta absolutamente ninguna (**`ROLLBACK`**). No existen los puntos medios.

### 🇨 Consistencia (*Consistency*)

Una transacción solo puede llevar a la base de datos de un estado válido a otro estado válido. Si tienes una regla (restricción) que dice que el saldo de un usuario nunca puede ser negativo, y una transacción intenta dejar a alguien con -$5 dólares, la base de datos romperá la transacción por completo para defender la integridad de los datos.

### 🇮 Aislamiento (*Isolation*)

Cuando miles de usuarios usan la aplicación al mismo tiempo, sus transacciones se ejecutan de forma concurrente. El aislamiento garantiza que la transacción del Usuario A no se entere ni se ensucie con los cambios temporales que está haciendo la transacción del Usuario B, hasta que ambos hayan terminado (aquí es donde entran los famosos niveles de aislamiento que experimentamos antes, como *Read Committed* o *Repeatable Read*).

### 🇩 Durabilidad (*Durability*)

Una vez que la base de datos te responde que la transacción se completó con éxito (`COMMIT`), esos datos quedan grabados de forma permanente en un medio no volátil (el disco duro o SSD). Si el servidor explota un milisegundo después, al encenderlo de nuevo, tus datos tienen que seguir ahí.



## 3. El Ciclo de Vida de una Transacción en Código

En SQL, una transacción tiene tres estados muy claros controlados por comandos específicos:

```sql
-- 1. Se abre la caja de seguridad. El sistema operativo congela una vista temporal para ti.
BEGIN; 

-- 2. Ejecutas el trabajo. Estos cambios están en el "limbo", solo tú los puedes ver.
UPDATE cuentas SET saldo = saldo - 20 WHERE usuario_id = 42;
INSERT INTO envios (usuario_id, producto) VALUES (42, 'Playera');

-- 3. La hora de la verdad:
COMMIT;   -- Opción A: "Todo salió bien, guárdalo permanentemente en el disco".
-- O...
ROLLBACK; -- Opción B: "Algo falló, borra todo lo que hice desde el BEGIN y olvida que existió".

```

En resumen: Una transacción es el mecanismo que inventaron los ingenieros de software para poder programar sin miedo a que los fallos eléctricos, las caídas de internet o la concurrencia de los usuarios destruyan la veracidad de los datos de una empresa.

 

---
---


# Niveles de aislamiento


 
## El Tablero de Control de Anomalías (Estándar ANSI SQL vs. PostgreSQL)

En las bases de datos relacionales, un nivel de aislamiento se define por las anomalías que **permite** o **previene**.

* **Lectura Sucia (*Dirty Read*):** Leer datos modificados por otra transacción que aún **no** ha hecho `COMMIT`.
* **Lectura No Repetible (*Non-Repeatable Read*):** Leer un registro, que otra transacción lo modifique/confirme, y que al volverlo a leer haya cambiado.
* **Lectura Fantasma (*Phantom Read*):** Ejecutar una consulta con un filtro (ej. `WHERE saldo > 100`), que otra transacción inserte un registro nuevo que cumpla esa condición, y que al volver a consultar aparezca ese registro "fantasma".




 

## 1. Lectura Sucia (*Dirty Read*)

**¿Por qué pasa?** En teoría, ocurre en sistemas que permiten a una transacción leer modificaciones hechas por otros usuarios **antes de que estos hagan un `COMMIT**`. Si el otro usuario se arrepiente y hace un `ROLLBACK`, tú te quedas con datos falsos que nunca existieron oficialmente.
*(Nota: Como aprendimos, en PostgreSQL esta anomalía es físicamente imposible debido a los mapas de bits de MVCC, incluso si intentas forzar el nivel `READ UNCOMMITTED`).*

### 💾 El Ejemplo en la Base de Datos (Simulado en otros motores)

Tenemos la tabla `cuentas_bancarias` con un usuario que tiene $100.

1. **Tu Transacción (Terminal 1):** Inicia el proceso para evaluar si le apruebas un crédito.
```sql
BEGIN;
SELECT saldo FROM cuentas_bancarias WHERE id = 42; -- ──> Devuelve $100

```


2. **Interferencia (Terminal 2):** El usuario deposita un cheque de $500, pero la transacción se queda pausada **sin hacer COMMIT**.
```sql
UPDATE cuentas_bancarias SET saldo = 600 WHERE id = 42; -- En progreso...

```


3. **Tu Transacción (Terminal 1):** Vuelves a consultar el saldo mientras el cheque se procesa.
```sql
SELECT saldo FROM cuentas_bancarias WHERE id = 42; -- ──> Devuelve $600 (Lectura Sucia)

```


4. **Interferencia (Terminal 2):** El cheque rebota por falta de fondos. La Terminal 2 cancela todo.
```sql
ROLLBACK;

```



* **La Anomalía:** Tu transacción leyó y procesó un saldo de $600 que **jamás se consolidó**. Es un dato "sucio" porque el dinero real nunca existió.

### 💡 La Analogía: El mensaje borrado de WhatsApp

Estás leyendo un chat de grupo (`BEGIN`). Un amigo escribe un mensaje que dice: *"Voy a pagar la cena de todos esta noche"*, pero **no bloquea el mensaje (no hace commit)**, lo deja ahí. Tú lees el mensaje (`SELECT`) y te pones feliz. Al cabo de un minuto, tu amigo se arrepiente de su generosidad y decide **"Eliminar el mensaje para todos" (`ROLLBACK`)**.

Tú te quedaste con una información falsa en tu cabeza. Leíste un mensaje "sucio" (un borrador) antes de que fuera una confirmación definitiva del emisor.
 

## 2. Lectura No Repetible (*Non-Repeatable Read*)

**¿Por qué pasa?** Porque en este nivel, cada vez que haces un `SELECT`, Postgres destruye tu foto anterior y toma una foto nueva del presente. Si otra persona cambia un dato entre tus consultas, tu segunda foto verá el cambio.

### 💾 El Ejemplo en la Base de Datos

Tenemos la tabla `productos` con un PlayStation 5 que cuesta $500.

1. **Tu Transacción (Terminal 1):** Inicia y consulta el precio.

```sql
BEGIN;
SELECT precio FROM productos WHERE id = 123; -- ──> Devuelve $500


```

2. **Interferencia (Terminal 2):** Un administrador sube los precios por la inflación y hace `COMMIT`.

```sql
UPDATE productos SET precio = 600 WHERE id = 123;
COMMIT;


```

3. **Tu Transacción (Terminal 1):** Vuelves a consultar el precio dentro del mismo `BEGIN`.

```sql
SELECT precio FROM productos WHERE id = 123; -- ──> Devuelve $600


```

* **La Anomalía:** Ejecutaste el mismo comando dos veces en la misma transacción y obtuviste valores diferentes. La lectura **no se pudo repetir**.

### 💡 La Analogía: El menú del restaurante

Entras a un restaurante y abres el menú (`BEGIN`). Lees que la hamburguesa cuesta $10 dólares. Te distraes hablando con el mesero. Mientras hablas, el dueño del restaurante cambia el precio en la pizarra del sistema central a $12 dólares. Vuelves a mirar el menú para ordenar (`SELECT`) y ahora dice $12 dólares.

Tu lectura **no fue repetible** porque cada vez que miras el menú, estás viendo el estado en tiempo real del restaurante, no una copia congelada de cuando entraste.
 
## 3. Lectura Fantasma (*Phantom Read*)

**¿Por qué pasa?** A diferencia de la anterior (que modifica un registro que ya existía), la lectura fantasma ocurre cuando otra transacción **inserta filas completamente nuevas** que cumplen con un filtro que tú estás usando. Como tu nivel toma fotos nuevas en cada comando, los registros nuevos aparecen de la nada.

### 💾 El Ejemplo en la Base de Datos

Tienes la tabla `usuarios_VIP`. Al inicio solo hay 2 usuarios registrados.

1. **Tu Transacción (Terminal 1):** Cuentas cuántos VIP existen para darles un bono.

```sql
BEGIN;
SELECT COUNT(*) FROM usuarios_VIP; -- ──> Devuelve 2 usuarios


```

2. **Interferencia (Terminal 2):** Un nuevo usuario se suscribe a la plataforma y el sistema hace `COMMIT`.

```sql
INSERT INTO usuarios_VIP (nombre) VALUES ('Mariana');
COMMIT;


```

3. **Tu Transacción (Terminal 1):** Vuelves a contar para imprimir los reportes.

```sql
SELECT COUNT(*) FROM usuarios_VIP; -- ──> Devuelve 3 usuarios


```

* **La Anomalía:** El número de filas cambió. Apareció un registro **fantasma** ('Mariana') que no existía en tu primera fotografía del universo.

### 💡 La Analogía: Contar personas en una sala

Entras a una sala de juntas con los ojos vendados. Te quitas la venda (`SELECT`) y cuentas a las personas: hay **5 personas**. Te vuelves a poner la venda. Mientras no ves, una sexta persona entra sigilosamente a la sala y se sienta. Te quitas la venda otra vez (`SELECT`) y cuentas: ahora hay **6 personas**.

Esa sexta persona es un **fantasma**: no modificó a las 5 personas originales, simplemente apareció de la nada en tu segunda mirada porque la puerta de la sala estaba abierta para caras nuevas.
 
## ¿Cómo se soluciona esto? (`REPEATABLE READ`)

Si en los laboratorios anteriores cambias el nivel a `REPEATABLE READ`, Postgres le tomará una fotografía al menú del restaurante o a la sala de juntas **en el segundo exacto en el que escribes `BEGIN**`.

No importa si el dueño cambia el precio a $12 o si entran 100 personas fantasmas a la sala; tu transacción se mantendrá leyendo la foto original donde la hamburguesa costaba $10 y solo había 5 personas, protegiéndote al 100% de ambas anomalías.










---
---

### Tabla de Mitigación Real en PostgreSQL

> ⚠️ **Nota Crítica de Arquitectura:** Las palomitas (**✅**) significan que el nivel **SÍ PROTEGE** contra la anomalía. Los niveles en PostgreSQL se comportan de forma más estricta que el estándar gracias a su arquitectura MVCC.

| Nivel de Aislamiento | Protege de Lectura Sucia | Protege de Lectura No Repetible | Protege de Lectura Fantasma | Comportamiento Real en Postgres |
| --- | --- | --- | --- | --- |
| **Read Uncommitted** | ✅ | ❌ | ❌ | Se ejecuta internamente como *Read Committed*. |
| **Read Committed** | ✅ | ❌ | ❌ | Nivel por defecto. Snapshot nuevo por comando. |
| **Repeatable Read** | ✅ | ✅ | ✅ | **Postgres previene fantasmas aquí** (superior a ANSI). |
| **Serializable** | ✅ | ✅ | ✅ | Evita anomalías de desalineación de escritura (*Write Skew*). |
 

## 1. READ UNCOMMITTED (El nivel fantasma)

### Funcionamiento y Realidad Técnica

En el estándar ANSI SQL, este nivel permite leer datos en el limbo sin confirmar (*Dirty Reads*). Sin embargo, **en PostgreSQL este nivel no existe de manera nativa.** Si lo configuras, Postgres lo acepta por compatibilidad sintáctica, pero internamente mapea la transacción como un **Read Committed**. El motor MVCC jamás permite leer punteros de datos en estado "In Progress" en el mapa de bits `pg_xact`.

* **Ventajas:** Compatibilidad con scripts legados de otras bases de datos (como SQL Server).
* **Desventajas:** Ninguna en Postgres, ya que opera de forma segura como *Read Committed*.

### 💡 La Analogía: El borrador en el pizarrón

Imagina que estás escribiendo una fórmula en un pizarrón. En otras bases de datos, *Read Uncommitted* permite que alguien entre a la sala, le tome foto a tu fórmula a medio escribir y se vaya, aunque tú termines borrándola porque estaba mal. En PostgreSQL, el guardia de la puerta **(MVCC)** no deja entrar a nadie a la sala hasta que dejes de escribir y guardes el gis.

### 🛠️ Laboratorio Práctico (`READ UNCOMMITTED`)

```sql
-- Conectarse a la base de datos
\c test

-- Crear tabla única para este experimento
CREATE TABLE datos_uncommitted (
    id INT PRIMARY KEY,
    saldo DECIMAL(10,2)
);
INSERT INTO datos_uncommitted VALUES (1, 100.00);

-- TERMINAL #1: Intentamos forzar el aislamiento
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT pg_current_snapshot(); -- Verás que crea un snapshot normal

-- TERMINAL #2: Hacemos un cambio sin confirmar
BEGIN;
UPDATE datos_uncommitted SET saldo = 999.00 WHERE id = 1;

-- TERMINAL #1: Intentamos hacer la lectura sucia
SELECT saldo FROM datos_uncommitted WHERE id = 1;
-- RESULTADO: Verás $100.00. Postgres demostró que NO permite lecturas sucias.

-- Limpieza
COMMIT; -- Terminal 1
COMMIT; -- Terminal 2

```
 
## 2. READ COMMITTED (El estándar de alta concurrencia)

### Funcionamiento

Cada instrucción individual (`SELECT`, `UPDATE`, etc.) toma una **fotografía fresca** de los datos confirmados en ese preciso microsegundo. Si la Terminal B confirma un cambio mientras la Terminal A está a la mitad de su bloque transaccional, la Terminal A verá el nuevo valor en su siguiente consulta.

* **Ventajas:** Altísimo rendimiento. Minimiza la contención y los bloqueos. Es ideal para el 90% de las aplicaciones web como e-commerce o inventarios generales.
* **Desventajas:** Sufre de **Lecturas No Repetibles**. Los datos pueden mutar bajo tus pies entre una consulta y otra dentro del mismo bloque.

### 💡 La Analogía: La pantalla de salidas del aeropuerto

Estás en la terminal aérea mirando la pantalla a las 10:00 AM y tu vuelo dice *"A tiempo"*. Te distraes un segundo, otro operador actualiza el estado en el sistema central a *"Retrasado"*, y cuando vuelves a mirar la pantalla a las 10:05 AM, el estado cambió. No hubo error, simplemente viste la realidad del presente en cada mirada.

### 🛠️ Laboratorio Práctico (`READ COMMITTED`)

```sql
-- Crear tabla única para este experimento
CREATE TABLE datos_committed (
    id INT PRIMARY KEY,
    saldo DECIMAL(10,2)
);
INSERT INTO datos_committed VALUES (1, 100.00);

-- TERMINAL #1: Inicia análisis
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT saldo FROM datos_committed WHERE id = 1; -- Resultado: $100.00

-- TERMINAL #2: Interferencia externa con COMMIT instantáneo
UPDATE datos_committed SET saldo = 150.00 WHERE id = 1;

-- TERMINAL #1: Segunda lectura en el mismo bloque
SELECT saldo FROM datos_committed WHERE id = 1; 
-- RESULTADO: $150.00. Ocurrió una "Lectura No Repetible" porque el dato cambió bajo tus pies.

COMMIT;

```
 

## 3. REPEATABLE READ (El congelador del tiempo)

### Funcionamiento

El snapshot se genera **exactamente al ejecutar la primera consulta** de la transacción y se queda blindado en roca. Pase lo que pase afuera, tus lecturas son idénticas.

> 🌐 **Diferencia de Postgres:** En el estándar ANSI, este nivel permite registros fantasmas. En PostgreSQL, gracias a que el snapshot MVCC define límites superiores (`XMAX`) rígidos, **las lecturas fantasmas también quedan completamente bloqueadas.**

* **Ventajas:** Consistencia perfecta para reportes financieros, auditorías complejas o trading de acciones. Sabes que tu universo de datos no se moverá.
* **Desventajas:** Si intentas modificar una fila que otra transacción modificó y confirmó mientras tú estabas congelado, Postgres abortará tu transacción inmediatamente con el error: `ERROR: could not serialize access due to concurrent update`.

### 💡 La Analogía: El archivo PDF

Generas un informe en PDF del estado de las cuentas a las 10:00 AM. Aunque los clientes sigan depositando dinero en el mundo real, tu documento PDF no va a cambiar sus letras mágicamente. Tienes una copia exacta del pasado.

### 🛠️ Laboratorio Práctico (`REPEATABLE READ`)

```sql
-- Crear tabla única para este experimento
CREATE TABLE datos_repeatable (
    id INT PRIMARY KEY,
    saldo DECIMAL(10,2)
);
INSERT INTO datos_repeatable VALUES (1, 100.00);

-- TERMINAL #1: Congelamos el tiempo
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT saldo FROM datos_repeatable WHERE id = 1; -- Resultado: $100.00

-- TERMINAL #2: Modificamos y confirmamos afuera
UPDATE datos_repeatable SET saldo = 200.00 WHERE id = 1;

-- TERMINAL #1: Volvemos a consultar
SELECT saldo FROM datos_repeatable WHERE id = 1;
-- RESULTADO: Sigue siendo $100.00. Protegido contra lecturas no repetibles.

COMMIT;

```
 

## 4. SERIALIZABLE (El simulador secuencial)

### Funcionamiento

Es el nivel más estricto. No usa bloqueos masivos destructivos de tablas (como en motores antiguos), sino un algoritmo llamado **SSI (Serializable Snapshot Isolation)**. Permite que las transacciones corran concurrentemente de forma optimista, pero monitorea activamente si hay dependencias cruzadas de lectura y escritura (Anomalías de *Write Skew*). Si detecta que el resultado final rompería la lógica de haber corrido una transacción estrictamente detrás de la otra, aborta una de ellas con un fallo de serialización.

* **Ventajas:** Seguridad matemática absoluta. Previene fallos lógicos complejos donde dos transacciones se aprueban mutuamente sin saber el resultado de la otra. Ideal para transferencias bancarias interbancarias y libros mayores (ERPs contables).
* **Desventajas:** Alta tasa de transacciones abortadas bajo entornos con mucha escritura concurrente. Tu código de aplicación **debe** implementar reintentos automáticos (*retry logic*).

### 💡 La Analogía: La reserva de asientos en el cine

Dos personas intentan comprar los dos últimos asientos juntos en una fila a la vez. Ambos ven los asientos libres en sus teléfonos. Si el sistema fuera permisivo, ambos pagarían y se generaría un conflicto al llegar a la sala. *Serializable* actúa como un supervisor invisible que, al momento de pagar, le dice a uno de ellos: *"Lo siento, otra persona ejecutó el proceso un milisegundo antes, tu transacción fue cancelada, intenta de nuevo"*.

### 🛠️ Laboratorio Práctico (`SERIALIZABLE`)

Para este laboratorio usaremos el famoso caso de la anomalía de desalineación de escritura (*Write Skew*), la cual sobrepasa la protección de *Repeatable Read*.

```sql
-- Crear tabla única para este experimento
CREATE TABLE medicos_guardia (
    id INT PRIMARY KEY,
    nombre VARCHAR(50),
    en_guardia BOOLEAN
);
-- Regla del hospital: Siempre debe quedar al menos UN médico de guardia
INSERT INTO medicos_guardia VALUES (1, 'Dr. Perez', true), (2, 'Dr. Gomez', true);

-- =======================================================
-- PASO EN PARALELO (Ejecuta el BEGIN en ambas terminales)
-- =======================================================
-- TERMINAL #1
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- TERMINAL #2
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Ambos médicos consultan si hay suficientes médicos activos (Ambos ven que hay 2, así que creen que pueden salir)
-- TERMINAL #1
SELECT COUNT(*) FROM medicos_guardia WHERE en_guardia = true; -- Ve 2
-- TERMINAL #2
SELECT COUNT(*) FROM medicos_guardia WHERE en_guardia = true; -- Ve 2

-- TERMINAL #1: El Dr. Perez pide salir de guardia
UPDATE medicos_guardia SET en_guardia = false WHERE id = 1;

-- TERMINAL #2: El Dr. Gomez pide salir de guardia al mismo tiempo
UPDATE medicos_guardia SET en_guardia = false WHERE id = 2;

-- TERMINAL #1: Hace commit primero (Se guarda con éxito)
COMMIT;

-- TERMINAL #2: Intenta hacer commit (Postgres detecta el conflicto lógico)
COMMIT;
-- ❌ RESULTADO ESPERADO EN TERMINAL 2:
-- ERROR: could not serialize access due to read/write dependencies among transactions
-- HINT: The transaction might succeed if retried.

```
 
## Resumen Ejecutivo de Aplicación en Arquitectura de Producción

1. **`READ COMMITTED`:** Úsalo por defecto. Es el motor de alta velocidad para la navegación general, registros de actividad, carritos de compra y microservicios tradicionales.
2. **`REPEATABLE READ`:** Úsalo exclusivamente en servicios dedicados a la generación de reportes masivos, conciliaciones nocturnas o exportaciones de datos hacia almacenes analíticos (Data Warehouses) donde los números no deben cambiar mientras se procesan.
3. **`SERIALIZABLE`:** Úsalo con pinzas y de forma quirúrgica en operaciones financieras críticas (movimientos de saldos de cuentas de alta prioridad, asignación de inventario único en ofertas relámpago). **Obligatorio:** Tu código de Backend debe atrapar el código de error `40001` y reintentar la operación.





---



 

## 2. El experimento científico: Cómo ver la recreación en vivo

Para demostrar que en `READ COMMITTED` (o *Read Uncommitted*) cada comando toma una foto fresca e independiente, necesitamos inyectar ruido (actividad) en el sistema desde otra terminal *mientras* tu transacción está abierta.

Abre **dos terminales** concurrentes conectadas a tu base de datos:

### Terminal #1 (Tu sesión de análisis)

Inicia tu transacción e inspecciona tu primer snapshot:

```sql
BEGIN;

-- Primer snapshot
SELECT pg_current_snapshot(); 
-- Supongamos que devuelve: 5000:5000:

```

### Terminal #2 (La interferencia del mundo real)

Sin cerrar la Terminal #1, ve a otra ventana y ejecuta un cambio real que consuma un ID de transacción definitivo (`XID`):

```sql
-- Forzamos la creación de una nueva transacción confirmada
VACUUM; -- Limpieza opcional para asegurar sincronía
CREATE TABLE test_interferencia (id INT);
DROP TABLE test_interferencia;

```

### Terminal #1 (De vuelta a tu sesión)

Vuelve a ejecutar la consulta del snapshot dentro de la **misma transacción que dejaste abierta**:

```sql
-- Segundo snapshot dentro del mismo BEGIN
SELECT pg_current_snapshot();

```

#### 🤯 El Resultado Real:

Tu snapshot ahora habrá cambiado por completo (por ejemplo, a `5002:5002:`).

Si estuviéramos en `REPEATABLE READ`, el valor se mantendría estrictamente congelado en `5000:5000:` sin importar lo que hiciera la Terminal #2. Pero como estás en `READ COMMITTED`, el comando anterior destruyó la foto vieja y calculó una nueva que capturó los cambios de la Terminal #2.
 


## 1. La Regla de Oro: Solo se fotografía lo "Confirmado"

El nivel se llama *Read **Committed*** por una razón: Tu snapshot se recalcula en cada comando, sí, pero esa foto tiene un filtro estricto de seguridad: **solo captura los datos de transacciones que ya hayan hecho `COMMIT` en el disco duro.**

Cuando tu Terminal #1 ejecuta un `UPDATE`:

1. Postgres genera una nueva versión de la fila en el disco.
2. Le estampa a esa fila un metadato invisible llamado `xmin` con el ID de tu transacción actual (ej. `49090505`).
3. El estado global de tu transacción `49090505` en los mapas de bits de Postgres (`pg_xact`) es **"IN_PROGRESS" (En Progreso)**.

Cuando la Terminal #2 ejecuta un `SELECT`, genera su propio snapshot. Su snapshot mira la fila que modificaste, lee que fue creada por la transacción `49090505`, va a revisar el estado de esa transacción y ve que está *"En Progreso"*. Por lo tanto, las reglas del aislamiento le prohíben mostrarte ese dato porque sería una **Lectura Sucia (*Dirty Read*)**. La Terminal #2 ignora tu cambio y te muestra la versión anterior de la fila.



## 2. El Flujo de Comportamiento Paso a Paso

Imaginemos este escenario con datos reales para ver cómo interactúan los snapshots y los estados en el tiempo:

Tenemos una tabla `usuarios` con un registro: `(id=1, nombre='Carlos')`.

### Fase 1: El Inicio

* **Terminal #1:** Ejecuta `BEGIN;`. (Su nivel es `READ COMMITTED`).
* **Terminal #2:** Está en modo normal (autocommit).

### Fase 2: La Modificación Oculta

* **Terminal #1:** Ejecuta `UPDATE usuarios SET nombre = 'Jose' WHERE id = 1;`.
* *¿Qué pasa internamente?* Postgres crea una nueva versión de la fila con el nombre `'Jose'`. Tu transacción ahora tiene un ID oficial (ej. `XID 999`). Esa fila está marcada como propiedad de `XID 999`.


* **Terminal #2:** Ejecuta `SELECT nombre FROM usuarios WHERE id = 1;`.
* *¿Qué pasa internamente?* La Terminal #2 calcula un snapshot fresco en tiempo real. Ese snapshot ve la fila `'Jose'`, pero detecta que pertenece a `XID 999` (que sigue activa/sin commit). El snapshot **no la incluye** y prefiere leer la versión anterior.
* *Resultado en Terminal #2:* Sigue viendo `'Carlos'`.



### Fase 3: La Recreación del Snapshot en la Terminal #1

* **Terminal #1:** Ejecuta `SELECT nombre FROM usuarios WHERE id = 1;`.
* *¿Qué pasa internamente?* La Terminal #1 destruye su snapshot anterior y genera uno nuevo en tiempo real. Este nuevo snapshot ve la fila `'Jose'` propiedad de `XID 999`. Como **tú eres el dueño** de `XID 999`, las reglas de visibilidad dicen: *"Tú sí puedes ver tus propios cambios no confirmados"*.
* *Resultado en Terminal #1:* Ve `'Jose'`.



### Fase 4: El Punto de Sincronización Global (`COMMIT`)

* **Terminal #1:** Ejecuta `COMMIT;`.
* *¿Qué pasa internamente?* Postgres cambia el estado de `XID 999` en el archivo `pg_xact` de *"En Progreso"* a **"COMMITTED" (Confirmado)**. Esto toma un milisegundo.


* **Terminal #2:** Ejecuta `SELECT nombre FROM usuarios WHERE id = 1;`.
* *¿Qué pasa internamente?* Al dar enter, la Terminal #2 destruye su foto vieja y toma una **nueva foto en tiempo real**. Este nuevo snapshot pasa por la fila `'Jose'`, ve que pertenece a `XID 999`, revisa el mapa de bits y dice: *"Ah, XID 999 ya hizo COMMIT"*. Por lo tanto, la fila se vuelve visible para todo el mundo.
* *Resultado en Terminal #2:* Ahora ve `'Jose'`.

 

## Resumen de la Arquitectura

* En `READ COMMITTED`, el tiempo exterior avanza para ti en cada comando (ves los `COMMIT` de los demás en tiempo real).
* Pero tú no avanzas para el resto del mundo exterior hasta que tú hagas tu propio `COMMIT`.
* **Tu transacción es una burbuja unilateral:** Puedes ver el presente del mundo exterior en cada `SELECT`, pero el mundo exterior tiene prohibido ver tu presente hasta que rompas la burbuja con un `COMMIT`.






 ---

# Laboratorio Práctico: Puntos de Control con `SAVEPOINT`

Los **`SAVEPOINT`** son como los puntos de control (*checkpoints*) en un videojuego: te permiten guardar tu progreso *dentro* de una transacción activa para que, si cometes un error más adelante, puedas regresar a ese punto específico sin tener que abortar y perder todo lo que ya habías hecho bien.

Aquí tienes la analogía bancaria corta y el laboratorio práctico paso a paso.

## La Analogía Corta: El depósito de fajos de billetes en el banco

Imagina que eres un cajero humano en un banco y un cliente llega a la ventanilla con una mochila llena de dinero para depositar. El proceso completo es una sola transacción.

* **El Proceso sin Savepoints (El riesgo):** Empiezas a contar los billetes uno por uno. Llevas **$9,000** contados perfectamente. En el último fajo de **$1,000**, te equivocas en la cuenta o detectas un billete falso. Como no tienes puntos de control, te estresas, te confundes, metes todo el dinero de vuelta a la mochila y le dices al cliente: *"Lo siento, tenemos que empezar a contar todo desde cero ($0)"*. Perdiste tiempo y trabajo.
* **El Proceso con Savepoints:** 1. Cuentas los primeros $5,000. Como están perfectos, los amarras con una liga y los pones en la caja fuerte. **(Creas el `SAVEPOINT fajo_1`)**.
2. Cuentas los siguientes $4,000. Están perfectos, los amarras y los guardas. **(Creas el `SAVEPOINT fajo_2`)**.
3. Empiezas a contar los últimos $1,000, pero te equivocas. En lugar de tirar todo el trabajo, simplemente dejas esos $1,000 de lado y dices: *"Regresemos a como estábamos en el fajo 2"*. **(Haces un `ROLLBACK TO fajo_2`)**. Los primeros $9,000 siguen estando seguros y contados en la caja fuerte; solo vuelves a contar el último fajo.

 

## Laboratorio Práctico: Control de Errores con `SAVEPOINT`

Para este laboratorio solo necesitas **una sola terminal**, ya que los `SAVEPOINT` viven y se gestionan estrictamente dentro de la misma conexión y sesión de una transacción.

### PASO 1: Creación de la Estructura Propia del Laboratorio

Nos conectaremos a la base de datos `test` y crearemos una tabla única y exclusiva llamada `log_transacciones`.

```sql
-- Conectarse a la base de datos
\c test

-- Crear la tabla exclusiva para este laboratorio
CREATE TABLE IF NOT EXISTS log_transacciones (
    id INT PRIMARY KEY,
    concepto VARCHAR(100) NOT NULL,
    monto DECIMAL(10, 2),
    estado VARCHAR(20) DEFAULT 'Pendiente'
);

-- Insertar el registro base del laboratorio
INSERT INTO log_transacciones (id, concepto, monto, estado) 
VALUES (1, 'Depósito Inicial Base', 5000.00, 'Consolidado');

```

 

### PASO 2: El Flujo de la Transacción con Puntos de Control

Ejecuta los siguientes comandos línea por línea en tu consola y observa cómo controlamos el flujo del tiempo dentro de la base de datos:

```sql
-- 1. Iniciamos la transacción principal
BEGIN;

-- 2. Hacemos la primera modificación válida (Fajo 1)
UPDATE log_transacciones SET monto = 6000.00 WHERE id = 1;

-- 3. CREAMOS EL PRIMER PUNTO DE CONTROL
SAVEPOINT punto_fajo_1;

-- 4. Hacemos una segunda modificación válida (Fajo 2)
INSERT INTO log_transacciones (id, concepto, monto, estado) 
VALUES (2, 'Segundo Depósito', 4000.00, 'Pendiente');

-- 5. CREAMOS EL SEGUNDO PUNTO DE CONTROL
SAVEPOINT punto_fajo_2;

-- 6. SIMULAMOS UN ERROR CRÍTICO (Un update erróneo sin WHERE que corrompe la tabla)
UPDATE log_transacciones SET concepto = 'SISTEMA CORRUPTO / ERROR DE BASE DE DATOS';

```

Si haces un `SELECT * FROM log_transacciones;` en este milisegundo, verás el caos: toda tu tabla exclusiva se ha modificado con el texto del error.

En una transacción normal sin checkpoints, tu única opción sería hacer un `ROLLBACK;` general y perder tanto el *Segundo Depósito* como la actualización del *id = 1*. Pero gracias al savepoint, podemos solucionar el error volviendo al punto exacto anterior:

```sql
-- 7. VIAJAMOS AL PASADO INMEDIATO (Justo antes del error, al punto_fajo_2)
ROLLBACK TO punto_fajo_2;

```

#### 🛠️ Verificación del Estado Intermedio

Si consultas la tabla justo ahora:

```sql
SELECT * FROM log_transacciones ORDER BY id;

```

**Resultado esperado:**
Verás que el error destructivo desapareció por completo. El `id = 1` conservó su monto de `6000.00` y el `id = 2` (`Segundo Depósito`) sigue existiendo a salvo en la tabla.

 

### PASO 3: Consolidación Final

Una vez que rescatamos la transacción del error, podemos cerrar el bloque de manera segura escribiendo los datos correctos permanentemente en el disco duro:

```sql
-- 8. Confirmamos y consolidamos la transacción en el disco
COMMIT;

```

Si haces una consulta final definitiva para verificar:

```sql
SELECT * FROM log_transacciones ORDER BY id;

```

Verás que tus datos quedaron guardados de forma impecable y el error masivo nunca llegó a guardarse.
 

## ❓ SECCIÓN DE RESPUESTAS TÉCNICAS (Preguntas Frecuentes sobre Savepoints)

### ¿Se pueden liberar los savepoints para ahorrar memoria si ya sé que voy bien?

**Respuesta:** **Sí.** Existe el comando `RELEASE SAVEPOINT nombre;`. Esto no guarda los datos en el disco duro (eso solo lo hace el `COMMIT`), sino que destruye el punto de control de la memoria interna de Postgres porque ya no planeas regresar a él. Ayuda a liberar recursos en transacciones gigantescas con miles de operaciones de escritura.

### ¿Qué pasa si hago un `ROLLBACK` normal (sin especificar el savepoint)?

**Respuesta:** El comando `ROLLBACK;` a secas destruye la transacción completa desde el `BEGIN`. Ignorará todos los savepoints que hayas creado en el camino y regresará la base de datos a como estaba al inicio de todo (en este laboratorio, el `id = 2` desaparecería y el `id = 1` volvería a valer `5000.00`).

### ¿Puedo sobreescribir un savepoint usando el mismo nombre?

**Respuesta:** **Sí.** Si ejecutas `SAVEPOINT punto_fajo_1;` dos veces, Postgres creará un nuevo punto de control con el mismo nombre y "ocultará" el anterior bajo una pila interna. Si haces un `ROLLBACK TO punto_fajo_1`, regresarás al *último* que creaste con ese nombre específico.

 

---
---

# Laboratorio Práctico: Transacciones en Dos Fases con `PREPARE TRANSACTION`

El comando `PREPARE TRANSACTION` implementa el mecanismo de **Two-Phase Commit (2PC)** en PostgreSQL. Te permite asegurarte de que las operaciones críticas que involucran múltiples sistemas se completen de manera coherente, reduciendo a cero el riesgo de que una parte se ejecute y otra no, lo que llevaría a inconsistencias graves de datos.

### ¿Dónde Aplicarlo en el Mundo Real?

* **Transacciones Bancarias:** Transferencias de fondos entre cuentas alojadas en diferentes bancos o cores financieros.
* **Sistemas Distribuidos:** Coordinación de estados y datos a través de múltiples bases de datos independientes o microservicios.
* **Aplicaciones con Middleware:** Coordinadores transaccionales (motores XA, Saga, etc.) que requieren confirmar o deshacer operaciones en múltiples fuentes de datos de forma atómica.
* **Transacciones Complejas:** Procesos que necesitan ser validados y "pre-salvados" antes de su confirmación final.


 
## La Analogía **El cajero automático (ATM) interbancario**:

Imagina que eres cliente del **Banco A** y vas a un cajero físico del **Banco B** a retirar $100 dólares en efectivo. Aquí hay dos sistemas independientes que deben actualizarse en tiempo real.
 

### ❌ El riesgo de NO usar `PREPARE TRANSACTION`

Si los bancos intentaran hacer esto con una transacción normal (sin coordinar en dos fases), dependes del orden en que tiren los cables:

* **Riesgo 1 (Resta primero el Banco A):** El sistema del Banco A te descuenta los $100 de tu saldo. Justo en ese milisegundo, se corta el internet del cajero del Banco B. **Resultado:** Te quedaste sin dinero en la cuenta y el cajero nunca te entregó los billetes.
* **Riesgo 2 (Entrega primero el Banco B):** El cajero del Banco B te escupe los $100 billetes en la mano. Justo ahí, la base de datos del Banco A se cae por mantenimiento y no recibe la notificación del cobro. **Resultado:** Tienes los $100 en la mano y tu saldo bancario sigue intacto. El banco perdió dinero.
 
### Cómo lo soluciona `PREPARE TRANSACTION` (Las Dos Fases)

Para evitar que el dinero quede flotando o se duplique, el software del cajero actúa como el **coordinador global**:

* **Fase 1: El PREPARE (La reserva)**
1. El cajero le dice al Banco A: *"¿Tienes los $100 de este usuario? Si es así, congélalos en el limbo, ponles un candado y asegúrame que no los vas a perder si te da un apagón"*. El Banco A lo hace, guarda el cambio en el disco (WAL) y responde: **"PREPARADO"**.
2. El cajero revisa sus propios rodillos mecánicos internos: *"¿Tengo billetes físicos de $100 disponibles y listos para salir?"*. El hardware responde: **"PREPARADO"**.


* **Fase 2: El COMMIT (La entrega definitiva)**
* Como ambas partes respondieron **"PREPARADO"**, el cajero da la orden final: `COMMIT PREPARED`. El Banco A descuenta el saldo definitivamente de la cuenta del cliente y el cajero expulsa los billetes a la ranura de salida. Todo ocurrió de forma atómica.


Si en la Fase 1 el cajero se hubiera dado cuenta de que no tenía billetes físicos, le envía un `ROLLBACK PREPARED` al Banco A. El Banco A quita el candado al saldo congelado del cliente y el dinero vuelve a estar disponible en su cuenta de inmediato. Nadie pierde un solo centavo.

 

## REQUISITO OBLIGATORIO: Habilitar las Transacciones Preparadas

Por defecto, PostgreSQL tiene esta característica desactivada. Si intentas usarla directamente, obtendrás errores de configuración.

### El error común:

Si ejecutas el comando sin configurar el servidor, verás lo siguiente:

```sql
postgres@postgres# PREPARE TRANSACTION 'transaccion_123';
ERROR:  prepared transactions are disabled
HINT:  Set max_prepared_transactions to a nonzero value.

```

Si intentas activarlo en caliente (en la sesión de la consola):

```sql
postgres@postgres# set max_prepared_transactions = 50;
ERROR:  parameter "max_prepared_transactions" cannot be changed without restarting the server

```

### La Solución Correcta:

1. Debes abrir el archivo de configuración `postgresql.conf`.
2. Modificar o añadir la línea: `max_prepared_transactions = 50`.
3. **Reiniciar por completo el servicio de PostgreSQL.**

Una vez reiniciado, puedes verificar que esté activo ejecutando:

```sql
postgres@postgres# show max_prepared_transactions;
+---------------------------+
| max_prepared_transactions |
+---------------------------+
| 50                        |
+---------------------------+

```

---

## LABORATORIO PASO A PASO (Multi-Terminal)

Para este ejercicio, abre **dos terminales de comando independientes** conectadas a tu base de datos (conéctate a una base de datos llamada `test`).

### 1. Configuración Inicial (Terminal #1)

Conéctate a la base de datos `test`, crea la tabla e inserta los datos iniciales que utilizaremos para la prueba de bloqueo:

```sql
-- Conectarse a la base de datos
\c test

-- Crear la tabla de pruebas
CREATE TABLE IF NOT EXISTS important_data (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT clock_timestamp()
);

-- Insertar registros iniciales
INSERT INTO important_data (name, description) VALUES
('First Item', 'important item.'),
('Second Item', 'important item.'),
('Third Item', 'important item.'),
('Fourth Item', 'important item.');

```

### 2. Fase de Preparación (Terminal #1)

Abriremos un bloque transaccional, identificaremos nuestro identificador de proceso (`PID`), realizaremos una modificación y **congelaremos** la transacción en el disco usando un identificador global único.

```sql
BEGIN;

-- Consultamos nuestro PID actual para el monitoreo (Ej: 24571)
SELECT pg_backend_pid(), current_database(), clock_timestamp();

-- Modificamos el primer registro
UPDATE important_data SET name = 'Jose Maria' WHERE id = 1;

-- Preparamos y sellamos la transacción de forma global
PREPARE TRANSACTION 'transferencia_prepare_db_test';

```

> 💡 **Nota de comportamiento:** En cuanto ejecutas `PREPARE TRANSACTION`, tu bloque de transacción actual se cierra y tu terminal queda libre para hacer consultas normales. Si haces un `SELECT * FROM important_data;` **en esta misma Terminal #1**, notarás que los cambios aún no se ven reflejados (verás el registro original `'First Item'`) porque la transacción está en el limbo, esperando confirmación.

 

### 3. Fase de Monitoreo y Resolución (Terminal #2)

Abre tu segunda terminal para analizar el estado interno de PostgreSQL mientras la transacción sigue congelada.

```sql
-- Conectarse a la misma base de datos
\c test

-- Consultamos nuestro PID (Verás que es diferente al de la Terminal #1, Ej: 24519)
SELECT pg_backend_pid(), current_database(), clock_timestamp();

```

#### Monitorear las transacciones preparadas:

Si revisas la vista local de statements normales, estará vacía:

```sql
SELECT * FROM pg_catalog.pg_prepared_statements;
-- (0 rows)

```

Pero si consultas la vista global de transacciones preparadas (`pg_prepared_xacts`), verás la nuestra custodiada por el sistema:

```sql
SELECT * FROM pg_catalog.pg_prepared_xacts;
+-------------+-------------------------------+-------------------------------+----------+----------+
| transaction |              gid              |           prepared            |  owner   | database |
+-------------+-------------------------------+-------------------------------+----------+----------+
|        2464 | transferencia_prepare_db_test | 2026-06-29 11:35:00.842792-07 | postgres | test     |
+-------------+-------------------------------+-------------------------------+----------+----------+

```

#### Intentar resolverla erróneamente:

Los comandos `COMMIT PREPARED` o `ROLLBACK PREPARED` se consideran instrucciones de control global de infraestructura, por lo tanto, **no pueden correr dentro de bloques de transacciones ordinarias**. Intenta esto para ver el error:

```sql
BEGIN;

COMMIT PREPARED 'transferencia_prepare_db_test';
-- ERROR: COMMIT PREPARED cannot run inside a transaction block

ROLLBACK;

```

#### Aplicación definitiva de los cambios (Commit):

Ejecuta el comando de manera directa en la consola para consolidar los datos que modificó la Terminal #1:

```sql
COMMIT PREPARED 'transferencia_prepare_db_test';
-- COMMIT PREPARED

```

Si realizas una consulta final a los datos, comprobarás que el registro `id = 1` ahora se guardó exitosamente y se liberaron todos los bloqueos:

```sql
SELECT * FROM important_data;
+----+-------------+-----------------+----------------------------+
| id |    name     |   description   |         created_at         |
+----+-------------+-----------------+----------------------------+
|  2 | Second Item | important item. | 2026-06-29 11:34:09.267833 |
|  3 | Third Item  | important item. | 2026-06-29 11:34:09.267839 |
|  4 | Fourth Item | important item. | 2026-06-29 11:34:09.267841 |
|  1 | Jose Maria  | important item. | 2026-06-29 11:34:09.267672 |
+----+-------------+-----------------+----------------------------+

```

 

## ❓ SECCIÓN DE RESPUESTAS TÉCNICAS (Preguntas Frecuentes)

A raíz de este comportamiento, surgen dudas críticas sobre la arquitectura interna de Postgres:

### ¿Si cierro la sesión una vez que realizo el `PREPARE TRANSACTION`, se cancela?

**Respuesta:** **No.** A diferencia de una transacción normal con `BEGIN` (que hace `ROLLBACK` automático si la sesión muere o se cae el internet), una transacción preparada se desacopla por completo de la sesión que la originó. Se vuelve una entidad global controlada por el servidor, lo que te permite hacerle `COMMIT` o `ROLLBACK` desde cualquier otra sesión o terminal sin problemas.

### ¿Se abre otro proceso en el sistema operativo al momento de hacer el `PREPARE`?

**Respuesta:** **No.** Al monitorear las conexiones activas en la tabla interna de PostgreSQL (`pg_stat_activity`), no se detecta ningún incremento en la cantidad de hilos de ejecución o procesos del backend. El motor simplemente marca un bloque transaccional existente en memoria y en los registros del disco (WAL) como "preparado", liberando el hilo del backend para otras conexiones.

### ¿Esto genera bloqueos (*Locks*) en las tablas?

**Respuesta:** **Sí, y de forma estricta.** Aunque salgas de la Terminal #1 y parezca que la transacción terminó, todas las filas modificadas (en este caso, el registro `id = 1`) permanecen bloqueadas bajo un cerrojo exclusivo en la base de datos. Cualquier otra consulta externa que intente modificar (`UPDATE` / `DELETE`) ese mismo registro se quedará congelada en un estado de **contención** esperando a que se ejecute el `COMMIT PREPARED` o el `ROLLBACK PREPARED`.

### ¿Si cuando realizo el `PREPARE TRANSACTION` se reinicia o se recarga PostgreSQL, pierdo la transacción?

**Respuesta:** **No.** Las transacciones preparadas son completamente resilientes. Al ejecutarse el comando, Postgres vuelca el estado y las estructuras de datos necesarias directamente en el almacenamiento persistente (en la carpeta `pg_twophase` dentro del directorio de datos). Si el servidor sufre un corte de energía o se reinicia deliberadamente, al volver a encender leerá estos archivos y colocará la transacción exactamente en el mismo estado en el que estaba antes del fallo.

### ¿Qué pasa si ejecuto el mismo identificador de `PREPARE` dos veces?

**Respuesta:** Los identificadores de texto (`String GID`) de las transacciones preparadas actúan como llaves primarias globales dentro del clúster de la base de datos. Si intentas registrar un nombre que ya está activo en el limbo, el sistema lanzará un error para evitar colisiones:

```sql
ERROR: transaction identifier "transferencia_prepare_db_test" is already in use

```







---

# Laboratorio Práctico snapshot: **La videollamada de revisión para un plano arquitectónico.**

Imagina que eres un arquitecto (**Terminal A**) y estás rediseñando los planos de una casa dentro de tu estudio. Mientras tanto, tu cliente (**Terminal B**) quiere ver exactamente cómo va el diseño en este preciso segundo para calcular los costos de los materiales, pero tú vas a seguir haciendo trazos y modificaciones en el plano real.

### ¿Qué es un Snapshot en PostgreSQL?

Un snapshot en PostgreSQL es una vista consistente de la base de datos en un momento específico. Los snapshots permiten a las transacciones ver un estado de la base de datos que no cambia, incluso si otras transacciones están realizando modificaciones. Esto es esencial para mantener la consistencia y el aislamiento de las transacciones.

 
### ❌ El riesgo de NO usar `pg_export_snapshot` (Trabajar en el "Presente")

Si no congelas la vista para tu cliente, dependes del nivel por defecto (*Read Committed*):

* Cada vez que el cliente mire el plano (haga un `SELECT`), verá tus líneas en tiempo real. Si tú borras una pared para probar un diseño y justo en ese segundo el cliente mira, calculará mal los ladrillos.
* Peor aún: si una constructora externa (**Terminal C**) entra al estudio y cambia el color de la fachada en el plano maestro, tu cliente verá ese cambio a mitad de su revisión, generando una **inconsistencia de lectura** (Lectura no repetible). El cliente no puede trabajar sobre un objetivo móvil.
 

### 📸 Cómo lo soluciona `pg_export_snapshot` (La captura de pantalla compartida)

Para que tu cliente pueda trabajar sobre datos firmes mientras el mundo real sigue avanzando, tú aplicas el protocolo del snapshot:

1. **Fase de Captura (Terminal A):** Abres tu sesión de diseño protegida (`REPEATABLE READ`). Antes de seguir, le tomas una foto digital exacta a tu pantalla en este milisegundo y el sistema te genera un código de descarga (El Token del Snapshot: `'00000003-0000002B-1'`). Tu Terminal A sigue trabajando en su universo.
2. **Fase de Sincronización (Terminal B):** Le pasas ese código por chat a tu cliente. Tu cliente abre su propia computadora, inicia una sesión (`REPEATABLE READ`) y mete el código (`SET TRANSACTION SNAPSHOT`).

**El Resultado:** Tu cliente ahora tiene una copia exacta de la pantalla congelada en su monitor. Él puede pasar horas analizando los cuartos, midiendo y calculando costos con la total seguridad de que **nada va a cambiar en su pantalla**, incluso si tú en la Terminal A sigues borrando paredes o si la Terminal C entra y modifica los datos del presente en el disco duro. El cliente está trabajando en un "universo paralelo" idéntico al momento exacto de la foto.

 

## PASO 1: Preparación del Entorno (Terminal Única)

Antes de abrir múltiples terminales, vamos a crear una tabla de prueba e insertar un registro inicial. Ejecuta esto en tu base de datos:

```sql
-- 1. Crear la tabla de cuentas
CREATE TABLE cuentas (
    usuario_id INT PRIMARY KEY,
    nombre VARCHAR(50),
    saldo DECIMAL(10, 2)
);

-- 2. Insertar el registro inicial del laboratorio
INSERT INTO cuentas (usuario_id, nombre, saldo) 
VALUES (42, 'Carlos Mendoza', 1000.00);

```

 

## PASO 2: El Escenario del Laboratorio

Para este experimento, abre **dos terminales diferentes** conectadas a la misma base de datos. Las llamaremos **Terminal A** y **Terminal B**.

 

### 🛠️ FASE 1: Congelar y Exportar el Tiempo (En la Terminal A)

En la primera terminal, iniciaremos una transacción con el aislamiento adecuado para congelar el tiempo y exportar nuestro token.

**Ejecuta en la TERMINAL A:**

```sql
-- Comenzamos la transacción congelando el universo de datos
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Verificamos el saldo inicial de Carlos (Verás 1000.00)
SELECT * FROM cuentas WHERE usuario_id = 42;

-- Exportamos el identificador único de esta foto del tiempo
SELECT pg_export_snapshot();

```

* **Resultado esperado:** PostgreSQL te devolverá un texto similar a este: `'00000003-0000002B-1'` (el número exacto cambiará en tu máquina).
* 📋 **ACCIÓN:** Copia ese ID de snapshot. Lo usaremos en el paso 4.
* ⚠️ **IMPORTANTE:** Deja la Terminal A completamente quieta. **No hagas** `COMMIT` ni `ROLLBACK`.

 

### 🛠️ FASE 2: Interferencia en el Mundo Real (En la Terminal B... por ahora)

Para demostrar la potencia de esto, antes de que la Terminal B use el snapshot, vamos a simular que el mundo real siguió avanzando y que otra persona modificó el saldo de Carlos.

**Ejecuta en la TERMINAL B:**

```sql
-- Simulamos una actualización del sistema en el "presente"
-- (Esto se ejecuta como una consulta suelta, fuera de transacciones largas)
UPDATE cuentas 
SET saldo = 5000.00 
WHERE usuario_id = 42;

-- Si consultas el saldo ahora en esta Terminal B:
SELECT saldo FROM cuentas WHERE usuario_id = 42;
-- El resultado es 5000.00. El saldo cambió en el mundo real.

```
 

### 🛠️ FASE 3: Viaje al pasado (En la Terminal B)

Ahora haremos que la Terminal B abra una transacción y, en lugar de ver el presente (los 5000.00), utilice el token de la Terminal A para mirar el pasado.

**Ejecuta en la TERMINAL B (Asegúrate de reemplazar el ID con el que te dio tu consola en el paso 2):**

```sql
-- 1. Abrimos una nueva transacción repetible
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- 2. Nos enganchamos al snapshot que exportó la Terminal A
-- (REEMPLAZA EL STRING POR EL TUYO)
SET TRANSACTION SNAPSHOT '00000003-0000002B-1';

-- 3. Consultamos el saldo de Carlos de nuevo
SELECT * FROM cuentas WHERE usuario_id = 42;

```

#### 🤯 El Resultado Mágico:

A pesar de que en el paso anterior modificamos el saldo a **5000.00** en el disco duro, la **Terminal B ahora te devolverá `1000.00**`.

Ha ignorado por completo el `UPDATE` que ocurrió en el presente de la base de datos y se ha sincronizado exactamente con el "universo" que la Terminal A está custodiando.
 

## PASO 3: Limpieza y Cierre del Laboratorio

Para no dejar transacciones abiertas en el limbo (lo que causaría problemas de rendimiento en un entorno real), debemos cerrar ambas sesiones de forma ordenada:

1. Ve a la **Terminal A** y escribe: `COMMIT;` (o `ROLLBACK;`).
2. Ve a la **Terminal B** y escribe: `COMMIT;` (o `ROLLBACK;`).

Si abres una terminal limpia ahora y haces un `SELECT * FROM cuentas WHERE usuario_id = 42;`, verás que el saldo final consolidado en el disco duro quedó en `5000.00`.

 

### 🧠 ¿Qué acabamos de demostrar con este laboratorio?

1. **Consistencia garantizada:** Dos procesos independientes pueden analizar la base de datos viendo exactamente la misma fotografía del tiempo.
2. **Utilidad real:** Herramientas como `pg_dump` abren una Terminal A para coordinar un respaldo masivo. Si el respaldo es muy grande, Postgres puede abrir hilos esclavos (Terminal B, C, D) usando el mismo snapshot para descargar diferentes tablas en paralelo, asegurando que el archivo final de respaldo no tenga inconsistencias de datos aunque la aplicación siga recibiendo miles de compras en vivo.




## Se puede usar otro nivel de aislamiento? 
 
La respuesta corta es: **No se puede con el nivel por defecto (que en Postgres es *Read Committed*), y en el caso específico de *Read Uncommitted*, en PostgreSQL ese nivel directamente no existe.**

Aquí te explico detalladamente las razones técnicas de por qué los snapshots requieren niveles estrictos y cómo maneja Postgres el aislamiento.

 
## ❓ SECCIÓN DE RESPUESTAS TÉCNICAS (Ampliación sobre Snapshots)

## 1. El gran secreto de Postgres: *Read Uncommitted* es un fantasma

Aunque el estándar SQL define cuatro niveles de aislamiento, **PostgreSQL no implementa *Read Uncommitted***.

Si tú ejecutas en Postgres:

```sql
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

```

Postgres lo aceptará sin dar error, pero internamente **lo mapeará automáticamente a *Read Committed*** (su nivel por defecto).

### ¿Por qué hace esto?

Porque Postgres utiliza un motor basado en **MVCC** (*Multi-Version Concurrency Control*). Cuando modificas una fila, Postgres no escribe encima, sino que crea una *nueva versión* de esa fila en el disco. Como las versiones no consolidadas (cambios sin `COMMIT`) no son visibles para otras transacciones por diseño del motor, es físicamente imposible para Postgres hacer una "Lectura Sucia" (*Dirty Read*), que es la característica principal de *Read Uncommitted*.

 

## 2. ¿Por qué no funciona con *Read Committed* (El nivel por defecto)?

Para poder exportar un snapshot con `pg_export_snapshot()`, PostgreSQL te exige obligatoriamente que estés en `REPEATABLE READ` o `SERIALIZABLE`. Si lo intentas en *Read Committed*, el sistema te lanzará un error inmediato al momento de importar **`ERROR:  a snapshot-importing transaction must have isolation level SERIALIZABLE or REPEATABLE READ`**.

La razón técnica es la **esperanza de vida del Snapshot**:

* **En *Read Committed*:** La transacción **no tiene un único snapshot**. Cada vez que ejecutas una nueva consulta (`SELECT`) dentro de la misma transacción, Postgres destruye el snapshot anterior y **crea uno nuevo** para asegurarse de leer lo último que se haya guardado en la base de datos en ese preciso milisegundo. Como el snapshot cambia en cada query, no tiene sentido "exportarlo", porque caducaría inmediatamente.
* **En *Repeatable Read* o *Serializable*:** El snapshot se crea **una sola vez** al inicio de la transacción y se congela. No importa cuántas consultas hagas ni cuántos datos cambien otras terminales afuera; tu transacción siempre verá exactamente la misma foto del pasado. Como esta foto es estática y permanente, Postgres **sí puede asignarle un ID único y exportarla** para que otra terminal la use.

 
## Resumen de Comportamiento

| Nivel de Aislamiento | Comportamiento del Snapshot | ¿Permite exportar snapshot? |
| --- | --- | --- |
| **Read Uncommitted** | No existe en Postgres (se convierte en *Read Committed*). | ❌ No |
| **Read Committed** (Default) | Se destruye y se recrea **en cada consulta**. | ❌ No (Daría error) |
| **Repeatable Read** | Se crea **una vez** al inicio y se congela. | Sí |
| **Serializable** | Se crea **una vez** y monitorea conflictos de escritura. | Sí |

Para lograr que la Terminal B vea exactamente el mismo "universo" que la Terminal A, necesitas una foto estática del tiempo. Por eso, las reglas de la arquitectura de Postgres exigen obligatoriamente congelar el aislamiento en `REPEATABLE READ` como mínimo.


 

### ¿Para Qué Sirve Realmente un Snapshot en Producción?

1. **Consistencia de Lectura Absoluta (*Read Consistency*):**
Garantiza que una transacción analice un "bloque congelado en el tiempo". El proceso puede realizar lecturas complejas durante horas con la certeza de que ninguna escritura concurrente de otros usuarios alterará sus resultados a mitad del camino.
2. **Estrategias de Replicación y Respaldos Lógicos:**
Es la tecnología base para herramientas como `pg_dump` y sistemas de Cambio de Datos en Tiempo Real (CDC) como *PeerDB/Debezium*. Permite extraer datos masivos o sincronizar nodos secundarios asegurando que la base de datos se restaure o replique en un estado idéntico y consistente.

 

### ¿Cómo se Configura y Gestiona un Snapshot?

PostgreSQL gestiona los snapshots de forma interna y automática mediante su motor **MVCC**. Sin embargo, como ingenieros, influimos directamente en el ciclo de vida y la persistencia de ese snapshot a través de los **Niveles de Aislamiento**.

#### 1. Configuración de Niveles de Aislamiento

Puedes alterar el comportamiento del snapshot usando las siguientes directivas según tu caso de uso:

* **`READ COMMITTED` (Nivel por Defecto):**
El snapshot es efímero. Cada consulta (`SELECT`) dentro de la misma transacción destruye el snapshot anterior y genera uno nuevo. Ve únicamente lo que ya fue confirmado (*committed*) en ese microsegundo.
```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

```


* **`REPEATABLE READ` (Recomendado para Reportes/Snapshots globales):**
El snapshot nace al ejecutar la primera consulta de la transacción y se congela hasta el `COMMIT` o `ROLLBACK`. Protege al sistema de lecturas no repetibles.
```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

```


* **`SERIALIZABLE` (Aislamiento Estricto):**
Mantiene el mismo snapshot congelado de `REPEATABLE READ`, pero añade un algoritmo de control de concurrencia optimista (SSI) que bloquea activamente la transacción si detecta que otra escritura concurrente rompe la linealidad secuencial de los datos.
```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

```


 
### Ejemplo Práctico: Monitoreo e Inspección de Snapshots Internos

Para auditar y ver los metadatos de qué "foto del tiempo" tiene asignada tu sesión actual, puedes utilizar las funciones del catálogo de Postgres en el siguiente orden:

#### Paso 1: Iniciar el entorno controlado

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Ejecutamos una lectura para que Postgres genere el Snapshot oficial de la transacción
SELECT * FROM cuentas WHERE usuario_id = 42;

```

#### Paso 2: Inspeccionar las entrañas del Snapshot

Ejecuta la siguiente consulta para obtener los identificadores reales del motor interno:

```sql
SELECT 
    pg_backend_pid() AS pid_proceso,
    txid_current() AS xid_transaccion_actual,
    pg_current_snapshot() AS snapshot_activo_mvcc,
    txid_current_snapshot() AS snapshot_legacy_format;

```

#### 🧠 Guía de lectura del resultado:

Cuando ejecutes el comando anterior, verás una estructura de texto en la columna `snapshot_activo_mvcc` similar a esta: `125:130:126,128`. Este formato se interpreta de la siguiente manera:

* **`125` (XMIN):** Cualquier transacción con un ID menor a este ya está confirmada y es visible para tu snapshot.
* **`130` (XMAX):** Cualquier transacción con un ID igual o mayor a este aún no se ha confirmado o inició después de tu foto, por lo que es completamente invisible para ti.
* **`126,128` (Lista de Excepciones):** Transacciones que estaban activas (en el limbo) justo cuando tomaste la foto; tu sesión las ignorará hasta que se resuelvan.

#### Paso 3: Cerrar el ciclo de vida

```sql
COMMIT;

```

> ⚠️ **Nota de compatibilidad moderna:** La función `txid_current_snapshot()` pertenece al formato antiguo de Postgres. En versiones modernas (PostgreSQL 13 en adelante), la norma estándar de la industria es utilizar la familia de funciones `pg_current_snapshot()`.
