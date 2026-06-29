
Que es una transaccion 

- tipos de transacciones o niveles de ailamiento.
- comit, rollback



- SAVEPOINT
- PREPARE TRANSACTION
- pg_export_snapshot

 

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
