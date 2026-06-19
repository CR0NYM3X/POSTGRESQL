
# Puntos importantes que debes revisar y planear cuando se usan replicas sincronas

 

## 1. `off` vs `local`: La diferencia entre la vida y la muerte de tus datos [Link](https://www.postgresql.org/docs/current/runtime-config-wal.html#GUC-SYNCHRONOUS-COMMIT)

Ambos ignoran a las réplicas, pero la diferencia radica en **qué tan seguro está el dato dentro del propio servidor Maestro**.

* **`synchronous_commit = off` (Asíncrono total):**
Cuando tu aplicación hace `COMMIT`, Postgres guarda el cambio únicamente en la **memoria RAM** (en los buffers del WAL) y de inmediato le dice a tu aplicación: *"¡Listo, guardado!"*.
* **El riesgo:** Si un milisegundo después se corta la luz en el servidor Maestro, ese dato se evaporó porque nunca tocó el disco duro.


* **`synchronous_commit = local` (Síncrono en casa, asíncrono afuera):**
Cuando haces `COMMIT`, Postgres obliga al servidor Maestro a escribir el WAL en su **disco duro real** (`fsync`) y, hasta que el disco no confirma que el archivo se grabó físicamente, no le responde al cliente.
* **La seguridad:** Si se corta la luz en el Maestro, no pasa nada. Al reiniciar, el dato estará ahí seguro en el disco. Sin embargo, no le importa si las réplicas recibieron el dato o no.



> 💡 **En resumen:** `off` arriesga tus datos ante un apagón del Maestro a cambio de máxima velocidad. `local` protege tus datos en el Maestro, pero no le avisa a las réplicas.

---

## 2. Entendiendo `remote_apply` con un caso real bancario

Para entender `remote_apply`, primero debes saber que la replicación en Postgres tiene dos pasos en la réplica:

1. **Recibir el WAL y guardarlo en disco** (Eso es lo que valida el modo `on`).
2. **Leer ese WAL y aplicar los cambios en las tablas** para que los usuarios puedan verlos (Eso es lo que valida `remote_apply`).

### El Caso de Uso Bancario: "El misterio del saldo fantasma"

Imagina un banco que tiene esta arquitectura para soportar millones de usuarios:

* **1 Nodo Maestro:** Donde se procesan los retiros, depósitos y transferencias (Escrituras).
* **1 Réplica de Lectura:** De donde la aplicación móvil del usuario lee el saldo para no saturar al Maestro (Lecturas).

### ¿Qué pasa si NO usas `remote_apply` (y usas el valor por defecto `on`)?

1. Un usuario entra a un cajero automático y deposita **$1,000 USD**.
2. El cajero envía la transacción al **Maestro**.
3. El Maestro le manda el WAL a la **Réplica**. La Réplica recibe el archivo, lo guarda en su disco y dice: *"¡Ya lo tengo en disco!"*.
4. Como usas `synchronous_commit = on`, el Maestro se da por satisfecho, libera la transacción y el cajero le dice al usuario: *"Depósito exitoso"*.
5. El usuario, emocionado, saca su teléfono celular en ese mismo segundo y abre la app del banco para ver su saldo.
6. La app móvil hace una consulta de lectura (READ) apuntando a la **Réplica**.
7. **EL DESASTRE:** La réplica tiene el dato guardado en su disco duro, pero su procesador interno está ocupado y **aún no ha tenido tiempo de "aplicar" (escribir) el cambio en las tablas**.
8. El usuario ve su saldo en la app y... **¡No aparecen los $1,000 USD!** Sigue viendo su saldo viejo.

El usuario entra en pánico, piensa que el cajero le robó el dinero, le da un infarto, llama furioso a soporte técnico o vuelve a intentar el depósito duplicando la operación. Esto se conoce en ingeniería de software como **falta de consistencia de lectura inmediata**.

### ¿Cómo lo soluciona `remote_apply`?

Si configuras `synchronous_commit = remote_apply`:

1. El usuario deposita los **$1,000 USD**.
2. El Maestro le manda el WAL a la Réplica.
3. El Maestro **se queda congelado esperando**. No le responde al cajero todavía.
4. La Réplica recibe el WAL, lo guarda en disco y **procede a ejecutar el cambio en sus tablas internas**. Cuando el nuevo saldo ya es visible en la Réplica, esta le avisa al Maestro: *"Listo, ya actualicé mis tablas"*.
5. El Maestro se desbloquea y el cajero dice: *"Depósito exitoso"*.
6. Cuando el usuario abre la app móvil (que lee de la réplica), el saldo de **$1,000 USD** está ahí matemáticamente garantizado. No hay retrasos visuales.

### ¿Cuándo usarlo entonces?

Úsalo **únicamente** cuando tu aplicación necesite una arquitectura de "Lectura después de Escritura" (*Read-After-Write Consistency*) inmediata en sistemas financieros, pasarelas de pago o inventarios críticos (donde comprar un producto debe verse reflejado en todas las pantallas del mundo al mismo milisegundo). Para todo lo demás, `on` es más que suficiente y no penaliza la latencia de tu Maestro.

---

### Todas las variantes de configuración (De menor a mayor seguridad)

Aquí tienes la matriz completa de comportamiento si tienes réplicas síncronas activas:

| Valor | ¿Qué hace exactamente? | Riesgo / Rendimiento | ¿Cuándo usarlo? |
| --- | --- | --- | --- |
| **`off`** | **Asíncrono puro.** Postgres da el "OK" al cliente en cuanto la transacción se procesa en la memoria caché (búfer), sin esperar a que se escriba en el disco del maestro ni de las réplicas. | **Máximo rendimiento.** Riesgo de perder los últimos milisegundos de datos si el maestro sufre un apagón repentino. | Logs de auditoría no críticos, métricas, ingesta masiva de datos (IoT). |
| **`local`** | El cliente recibe el "OK" solo cuando los datos se han escrito y **flusado a los discos locales del Maestro**. Ignora por completo lo que pase en las réplicas. | **Rendimiento medio-alto.** Los datos están seguros en el servidor principal, pero si este explota físicamente antes de replicar, los perderás en el failover. | Operaciones del sistema, cachés internas de la app, datos que puedes regenerar. |
| **`remote_write`** | El maestro escribe en su disco y espera a que la réplica confirme que **recibió el WAL y lo guardó en su memoria interna (OS caché)**, pero la réplica aún no lo escribe en su disco duro. | **Seguridad intermedia.** Si el proceso de Postgres en la réplica se cae, los datos no se pierden. Si todo el servidor de la réplica se apaga de golpe por falta de luz, podrías perder datos. | Sistemas que necesitan buena velocidad pero toleran fallos catastróficos muy raros en las réplicas. |
| **`on`**<br>

<br>*(Por defecto)* | El maestro escribe en su disco y espera a que la réplica confirme que **recibió el WAL y lo flusó físicamente a su disco duro**. | **Alta seguridad, latencia estándar.** Los datos están protegidos contra caídas de energía en ambos servidores. | El estándar para transacciones comerciales habituales, perfiles de usuario, etc. |
| **`remote_apply`** | El nivel militar. El maestro espera a que la réplica no solo guarde el WAL en disco, sino que **aplique los cambios en su base de datos**. | **Máxima seguridad, mayor latencia.** Garantiza consistencia de lectura inmediata (*Read-After-Write Consistency*) en las réplicas. | Transferencias bancarias, pasarelas de pago, o si tu app escribe en el maestro y lee de la réplica inmediatamente después. |


---

## Casos de uso synchronous_standby_names

### 1. Esquema de Prioridad (`FIRST N`)

**Sintaxis:** `synchronous_standby_names = 'FIRST 2 (replica_a, replica_b, replica_c)'`

* **¿Para qué sirve?:** Garantiza que la transacción se guarde en las primeras `N` réplicas disponibles, siguiendo el **orden estricto de izquierda a derecha** en el que fueron escritas.
* **¿Dónde se recomienda usar?:** En infraestructuras con topología local o híbrida donde tienes nodos secundarios "VIP" (mejor hardware, cableado directo, menor latencia) y otros de reserva en un segundo plano.
* **¿Cuándo se usa?:** Cuando el orden de un posible *failover* (promoción a primario) está predefinido por diseño y necesitas que la réplica con mejor hardware esté siempre 100% al día.
* **¿Cuándo NO se usa?:** Cuando tus réplicas tienen latencias de red inestables. Si la primera réplica (`replica_a`) se ralentiza por un proceso interno, ralentizará todos los *commits* del primario, aunque las demás estén libres.

 
### 2. Esquema de Quórum (`ANY N`)

**Sintaxis:** `synchronous_standby_names = 'ANY 2 (replica_a, replica_b, replica_c)'`

* **¿Para qué sirve?:** Libera la transacción en cuanto **cualesquiera** `N` réplicas de la lista respondan. Es una democracia: las réplicas más rápidas en ese milisegundo ganan.
* **¿Dónde se recomienda usar?:** En despliegues en la nube (AWS, GCP, Azure) distribuidos en múltiples Zonas de Disponibilidad (AZ) o Multi-región.
* **¿Cuándo se usa?:** Cuando buscas **Alta Disponibilidad sin cuellos de botella**. Si una réplica sufre un pico de red o está ocupada, no frena al primario porque otra réplica absorberá el *commit*.
* **¿Cuándo NO se usa?:** Cuando tienes réplicas con hardware asimétrico o en geografías lejanas y necesitas asegurar por ley o cumplimiento que los datos se escribieron en un servidor específico (ej. "obligatorio que se guarde en la réplica de Europa por GDPR").

 
### 3. Sintaxis Implícita (Legacy / Clásica)

**Sintaxis:** `synchronous_standby_names = 'replica_a, replica_b'`

* **¿Para qué sirve?:** Es un atajo heredado de versiones viejas de Postgres. Funciona exactamente igual que un `FIRST 1 (replica_a, replica_b)`.
* **¿Dónde se recomienda usar?:** Únicamente en entornos heredados (PostgreSQL 9.5 o inferior) o scripts de automatización antiguos que no toleren la sintaxis moderna.
* **¿Cuándo se usa?:** En arquitecturas ultra-simples de **un solo primario y una sola réplica síncrona** donde no hay complejidad arquitectónica.
* **¿Cuándo NO se usa?:** En cualquier base de datos moderna (Postgres 10 en adelante). Es una mala práctica de legibilidad; confunde a otros administradores de bases de datos (DBAs) que hereden tu configuración.

 

### 4. El Comodín (`*`)

**Sintaxis:** `synchronous_standby_names = 'ANY 2 (*)'` o `'FIRST 1 (*)'`

* **¿Para qué sirve?:** Aplica la regla síncrona a **cualquier nodo secundario** que logre conectarse al primario, ignorando por completo el nombre de la aplicación (`application_name`).
* **¿Dónde se recomienda usar?:** En entornos hiperdinámicos y contenerizados, específicamente orquestados por **Kubernetes** (usando operadores como Zalando PGO, CloudNativePG o Crunchy Data).
* **¿Cuándo se usa?:** Cuando los nodos secundarios nacen, mueren y escalan automáticamente (Auto-scaling), lo que provoca que sus IPs y nombres cambien constantemente y sea imposible listarlos a mano.
* **¿Cuándo NO se usa?:** Cuando mezclas réplicas de propósito general con réplicas para reportes analíticos (BI). Si el comodín atrapa a una réplica analítica lenta, destruirá el rendimiento transaccional de tu base de datos principal.

---





