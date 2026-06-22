 
## ¿Qué son los Advisory Locks (Bloqueos Consultivos)?

Los **Advisory Locks** son **bloqueos a nivel de aplicación gestionados por la base de datos** (en este caso, PostgreSQL).

A diferencia de los bloqueos tradicionales que protegen datos físicos (como "bloquear la tabla de usuarios" o "bloquear la fila del saldo"), los Advisory Locks **bloquean números arbitrarios o "ideas"**. La base de datos no sabe qué significan esos números; simplemente actúa como un árbitro imparcial que se asegura de que solo un proceso a la vez pueda "poseer" ese número.

Se llaman "consultivos" (advisory) porque la base de datos no los impone por la fuerza sobre tus tablas. Es tu aplicación la que *consulta* si el bloqueo está libre y, por convención y buena programación, respeta esa regla antes de proceder.
 

## ¿Para qué sirven principalmente?

Su propósito central es **coordinar el tráfico y la concurrencia** cuando tienes múltiples servidores, contenedores o procesos trabajando al mismo tiempo, utilizando tu base de datos central como la única "fuente de la verdad".

Sirven para evitar choques operativos sin tener que bloquear las tablas reales (lo cual haría tu sistema extremadamente lento).

Aquí tienes sus **tres usos maestros**:

### 1. Evitar Tareas Duplicadas (Cron Jobs)

Si tienes 5 servidores y todos tienen programado ejecutar un reporte diario a las 12:00 a.m., los 5 intentarán hacerlo a la vez.

* **Para qué sirve el bloqueo:** Haces que el reporte sea la "llave 500". El primer servidor toma la llave y trabaja. Los otros 4 ven que la llave está ocupada y cancelan su ejecución. Evitas enviar el mismo reporte 5 veces.

### 2. Prevención de Condiciones de Carrera (Race Conditions) y Doble Clic

Cuando un usuario impaciente hace clic tres veces en "Pagar" en menos de un segundo, tu backend recibe tres peticiones simultáneas.

* **Para qué sirve el bloqueo:** Antes de tocar el saldo, el código pide la llave transaccional exclusiva para ese usuario. El primer clic pasa, los otros dos clics son rechazados instantáneamente en la puerta (usando la variante `try`). Evitas cobrarle tres veces.

### 3. Coordinar Migraciones de Código o Base de Datos

Cuando actualizas tu sistema, a veces necesitas alterar la estructura de las tablas, pero no quieres que los usuarios escriban datos mientras eso ocurre.

* **Para qué sirve el bloqueo:** Tu script de migración toma un Advisory Lock global. Las peticiones de los usuarios se quedan "en pausa" pacientemente por unos segundos mientras se hace la actualización, y en cuanto termina, se liberan y continúan sin notar el corte de servicio.

 
### Resumen de tu Arsenal

Para lograr estos propósitos, PostgreSQL te da cuatro herramientas principales que ahora ya conoces:

| Función | ¿Espera si está ocupado? | ¿Cómo se libera? | Ideal para... |
| --- | --- | --- | --- |
| **`pg_advisory_lock`** | Sí, espera infinitamente. | Manualmente (`unlock`). | Tareas largas y manuales de mantenimiento. |
| **`pg_try_advisory_lock`** | No, devuelve `false` al instante. | Manualmente (`unlock`). | Descartar servidores redundantes en cron jobs. |
| **`pg_advisory_xact_lock`** | Sí, espera infinitamente. | **Automático** (al hacer COMMIT). | Encolar tareas críticas de negocio en orden estricto. |
| **`pg_try_advisory_xact_lock`** | No, devuelve `false` al instante. | **Automático** (al hacer COMMIT). | Bloquear el doble clic y rechazar clonaciones al instante. |

---


# Ejercicio
imagina que tienes dos ventanas de comandos abiertas en tu computadora, conectadas a la misma base de datos.

* **Terminal A:** Representa a tu Servidor 1 (o al Usuario 1).
* **Terminal B:** Representa a tu Servidor 2 (o al Usuario 2).

Vamos a ejecutar dos laboratorios paso a paso.

---

## Laboratorio 1: El uso de `pg_try_advisory_lock` (Intenta y no espera)

**El Escenario en la vida real:** Tienes un *script* que limpia archivos basura de la base de datos todos los días a las 3:00 AM. Tienes dos servidores (A y B) y ambos tienen este *script* programado a la misma hora. Si ambos lo ejecutan al mismo tiempo, la base de datos se va a saturar y fallar. Queremos que **solo el que llegue primero lo haga**, y el segundo se rinda y se vaya.

**El parámetro que usaremos:** `(777)`.

* **¿De dónde lo saqué?** Me lo acabo de inventar. Yo, como programador, decidí anotar en un post-it en mi escritorio: *"El número 777 significa: Permiso para correr el script de limpieza"*. La base de datos no sabe qué es el 777, solo sabe que es una llave única.

### Secuencia del Laboratorio 1

**Paso 1: Ambos servidores despiertan a las 3:00 AM.**

* **Terminal A escribe y ejecuta:**
```sql
SELECT pg_try_advisory_lock(777);

```


*Resultado en Terminal A:* Devuelve `t` (true). Como A fue un milisegundo más rápido, PostgreSQL le da la llave 777.
* **Terminal B escribe y ejecuta (un instante después):**
```sql
SELECT pg_try_advisory_lock(777);

```


*Resultado en Terminal B:* Devuelve `f` (false) **inmediatamente**. La terminal B no se queda congelada. Al ver el `false`, el código de tu servidor B dice: *"Ok, alguien más está limpiando la base de datos, aborto mi misión y me apago"*.

**Paso 2: El Servidor A trabaja.**

* La Terminal A, que recibió el `t` (true), ejecuta su limpieza pesada. Elimina archivos, optimiza tablas, etc. Esto le toma 5 minutos.

**Paso 3: El Servidor A termina su trabajo (Crucial).**

* **Terminal A escribe y ejecuta:**
```sql
SELECT pg_advisory_unlock(777);

```


*¿Para qué sirve esto?* Como esta función es a "nivel de sesión" (no transaccional), si la Terminal A no suelta la llave manualmente devolviéndola con el `unlock`, mañana a las 3:00 AM cuando intenten correr el script, la llave 777 seguirá marcada como "ocupada" y ningún servidor limpiará la basura.

 

## Laboratorio 2: El uso de `pg_advisory_xact_lock` (Espera pacientemente y se limpia solo)

**El Escenario en la vida real:** Tienes una aplicación de banco. El Cliente con el ID número `88` tiene $100 pesos en su cuenta. La Terminal A (su celular) y la Terminal B (su computadora) intentan hacer una transferencia de $100 al mismo milisegundo. Si no los formas en fila, el banco perderá dinero. Aquí sí queremos que el segundo **se espere en la fila** hasta que el primero termine.

**Los parámetros que usaremos:** `(1000, 88)`.

* **¿De dónde lo saqué?** De una convención de programación. Decidí inventar que el número `1000` significa el "Módulo de Transferencias". El número `88` no me lo inventé, es el ID real del cliente en la tabla de tu base de datos. Juntos `(1000, 88)` crean una llave única que significa *"Operando el dinero del cliente 88"*.

### Secuencia del Laboratorio 2

**Paso 1: Ambos intentan iniciar la operación.**
*Como tiene la palabra `xact` (transacción), es OBLIGATORIO abrir la puerta con un `BEGIN`.*

* **Terminal A escribe:**
```sql
BEGIN;
SELECT pg_advisory_xact_lock(1000, 88);

```


*Resultado en Terminal A:* Se ejecuta con éxito. A toma la llave.
* **Terminal B escribe (un milisegundo después):**
```sql
BEGIN;
SELECT pg_advisory_xact_lock(1000, 88);

```


*Resultado en Terminal B:* **La pantalla se queda congelada. El cursor parpadea pero no hace nada.** La terminal B se ha puesto en pausa automáticamente porque la Terminal A tiene la llave. No hay error, solo está esperando pacientemente su turno.

**Paso 2: Terminal A procesa la transferencia.**

* **Terminal A escribe:**
```sql
UPDATE cuentas SET saldo = saldo - 100 WHERE id_cliente = 88 AND saldo >= 100;

```


*Resultado:* Se descuentan los $100. El saldo queda en $0.

**Paso 3: Terminal A finaliza (La magia del automatismo).**

* **Terminal A escribe:**
```sql
COMMIT;

```


*¿Qué ocurre aquí?* El `COMMIT` guarda los datos permanentemente. Al mismo tiempo, como usamos un bloqueo transaccional (`xact`), PostgreSQL dice: *"Ah, la transacción terminó, suelto la llave (1000, 88) automáticamente"*. No necesitamos hacer ningún `unlock`.

**Paso 4: Terminal B despierta.**

* En el exacto milisegundo que Terminal A hace el `COMMIT`, la **Terminal B** (que estaba congelada) se descongela automáticamente, recibe la llave que A soltó, y avanza a su siguiente línea de código.
* **Terminal B ejecuta su intento de restar dinero:**
```sql
UPDATE cuentas SET saldo = saldo - 100 WHERE id_cliente = 88 AND saldo >= 100;

```


*Resultado:* Como el saldo ya es $0 gracias a la Terminal A, la condición `saldo >= 100` falla. No se roba dinero del banco. La Terminal B hace su propio `COMMIT;` y termina sin causar daño.


 ---




## Laboratorio 3: El Antídoto contra el Doble Clic (`pg_try_advisory_xact_lock`)

**El Escenario:** El usuario número `88` está comprando un producto en tu tienda. Su internet está lento, se desespera, y **hace doble clic rápido** en el botón "Pagar".
Tu servidor recibe las dos peticiones casi al mismo tiempo (Terminal A y Terminal B). Queremos que la primera pase, y la segunda sea rechazada al instante sin quedarse esperando.

**El parámetro:** `(1000, 88)`. `1000` significa "Procesando Pago" y `88` es el ID del usuario.

### Secuencia del Doble Clic

**Paso 1: Llegan los dos clics casi al mismo tiempo.**
Ambos procesos abren la puerta de la transacción.

* **Terminal A (Clic 1) escribe:** `BEGIN;`
* **Terminal B (Clic 2) escribe:** `BEGIN;`

**Paso 2: Ambos piden la llave (SIN ESPERAR).**

* **Terminal A (Clic 1) escribe:** ```sql
SELECT pg_try_advisory_xact_lock(1000, 88);
```
*Resultado:* Devuelve `t` (true). La Terminal A tiene la llave transaccional.


```


* **Terminal B (Clic 2, llega un milisegundo tarde) escribe:**
```sql
SELECT pg_try_advisory_xact_lock(1000, 88);

```


*Resultado:* Devuelve `f` (false) **INMEDIATAMENTE**. No se queda esperando como en el Lab 2.

**Paso 3: El backend de la Terminal B (Clic 2) reacciona al instante.**

* Tu código de programación (PHP, Node, etc.) ve ese `false` y dice: *"Ojo, este usuario ya tiene un pago procesándose en este milisegundo. Aborto la misión"*.
* **Terminal B escribe:** ```sql
ROLLBACK;
```
*Resultado:* El segundo clic se cancela por completo. El usuario ve en su pantalla un mensaje que dice: *"Tranquilo, tu pago ya se está procesando"*. **El riesgo de doble cobro desaparece al instante.**


```



**Paso 4: La Terminal A (Clic 1) procesa su pago tranquilamente.**

* Como la Terminal A sacó `true`, avanza.
* **Terminal A escribe:**
```sql
INSERT INTO pedidos (id_usuario, producto, total) VALUES (88, 'Laptop', 1500);

```


* **Terminal A finaliza:**
```sql
COMMIT;

```


*Resultado:* El pedido se guarda. Al hacer `COMMIT`, PostgreSQL suelta la llave `(1000, 88)` automáticamente. Si el usuario quiere comprar otra cosa 5 minutos después, la llave estará libre y podrá hacerlo sin problemas.
 

### En conclusión

Has dado en el clavo con tu duda.

* Si usas **espera** (`pg_advisory_xact_lock`), tienes que hacer malabares en tu código SQL para no duplicar acciones cuando el proceso que esperaba se despierte.
* Si usas **intento sin espera** (`pg_try_advisory_xact_lock`), matas el problema del doble clic de raíz en la puerta de entrada, abortando el clon de inmediato y ahorrándote problemas.









 ---


## Otros pg_advisory
```
postgres@centraldata# select distinct proname from pg_proc where proname ilike '%advisory%' order by proname;
+----------------------------------+
|             proname              |
+----------------------------------+
| pg_advisory_lock                 |
| pg_advisory_lock_shared          |
| pg_advisory_unlock               |
| pg_advisory_unlock_all           |
| pg_advisory_unlock_shared        |
| pg_advisory_xact_lock            |
| pg_advisory_xact_lock_shared     |
| pg_try_advisory_lock             |
| pg_try_advisory_lock_shared      |
| pg_try_advisory_xact_lock        |
| pg_try_advisory_xact_lock_shared |
+----------------------------------+
(11 rows)

```

