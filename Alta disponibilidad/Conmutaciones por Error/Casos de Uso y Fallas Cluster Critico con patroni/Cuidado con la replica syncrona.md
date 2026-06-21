
# Puntos importantes que debes revisar y planear cuando se usan replicas sincronas



### Todas las variantes de configuración  synchronous_commit  (De menor a mayor seguridad)

Aquí tienes la matriz completa de comportamiento si tienes réplicas síncronas activas:

| Valor | ¿Qué hace exactamente? | Riesgo / Rendimiento | ¿Cuándo usarlo? |
| --- | --- | --- | --- |
| **`off`** | **Asíncrono puro.** Postgres da el "OK" al cliente en cuanto la transacción se procesa en la memoria caché (búfer), sin esperar a que se escriba en el disco del maestro ni de las réplicas. | **Máximo rendimiento.** Riesgo de perder los últimos milisegundos de datos si el maestro sufre un apagón repentino. | Logs de auditoría no críticos, métricas, ingesta masiva de datos (IoT). |
| **`local`** | El cliente recibe el "OK" solo cuando los datos se han escrito y **flusado a los discos locales del Maestro**. Ignora por completo lo que pase en las réplicas. | **Rendimiento medio-alto.** Los datos están seguros en el servidor principal, pero si este explota físicamente antes de replicar, los perderás en el failover. | Operaciones del sistema, cachés internas de la app, datos que puedes regenerar. |
| **`remote_write`** | El maestro escribe en su disco y espera a que la réplica confirme que **recibió el WAL y lo guardó en su memoria interna (OS caché)**, pero la réplica aún no lo escribe en su disco duro. | **Seguridad intermedia.** Si el proceso de Postgres en la réplica se cae, los datos no se pierden. Si todo el servidor de la réplica se apaga de golpe por falta de luz, podrías perder datos. | Sistemas que necesitan buena velocidad pero toleran fallos catastróficos muy raros en las réplicas. |
| **`on`** |  *(Por defecto)* El maestro escribe en su disco y espera a que la réplica confirme que **recibió el WAL memoria cache y lo flusó físicamente a su disco duro con fsync**. | **Alta seguridad, latencia estándar.** Los datos están protegidos contra caídas de energía en ambos servidores. | El estándar para transacciones comerciales habituales, perfiles de usuario, etc. |
| **`remote_apply`** | El nivel militar. El maestro espera a que la réplica no solo guarde el WAL en disco, sino que **aplique los cambios en su base de datos**. | **Máxima seguridad, mayor latencia.** Garantiza consistencia de lectura inmediata (*Read-After-Write Consistency*) en las réplicas. | Transferencias bancarias, pasarelas de pago, o si tu app escribe en el maestro y lee de la réplica inmediatamente después. |

 ---

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

 

# Casos de Uso Avanzados de `synchronous_standby_names`
[NOTA] - Si nunca metes una replica al synchronous_standby_names este jamas sera canditato a ser sincrona y siempre sera asicrona.

### asi debe estar configurado Patroni.yml
```
tags:
  nofailover: true  # Jamás será promovido a Primario
  nosync: true      # Jamás será candidato a ser síncron
```

### 1. Esquema de Prioridad (`FIRST N`)

**Sintaxis:** `synchronous_standby_names = 'FIRST 2 (replica_a, replica_b, replica_c)'`

* **¿Para qué sirve?:** Garantiza que la transacción se guarde en las primeras `N` réplicas disponibles, siguiendo un **orden estricto de prioridad de izquierda a derecha**.
* **¿Todos los nodos son síncronos al mismo tiempo? No.** Basado en la documentación oficial, Postgres asigna estados individuales visibles en la vista `pg_stat_replication` (`sync_state`):
* Las primeras `N` réplicas vivas de la lista toman el estado **`sync`** (síncronas activas).
* Las réplicas sobrantes quedan en estado **`potential`** (potenciales / asíncronas de reserva). El primario no espera por ellas para confirmar el *commit*.


* **¿Qué pasa si se cae una réplica?:** Si `replica_a` (que estaba en estado `sync`) se desconecta, Postgres recorre la lista hacia la derecha en caliente. Promueve inmediatamente a `replica_c` de estado `potential` a `sync`. **El sistema NO se detiene** mientras existan nodos suficientes conectados para cubrir el número `N`. Si `replica_a` revive, recupera su prioridad de inmediato y `replica_c` vuelve a ser degradada a `potential`.
* **¿Dónde se recomienda usar?:** En infraestructuras locales (Bare-metal) o híbridas con nodos secundarios "VIP" (mejor hardware, cableado directo, menor latencia) y otros nodos de menor rendimiento relegados a la reserva.
* **¿Cuándo NO se usa?:** Cuando tus réplicas tienen latencias de red inestables. Si la primera réplica de la lista sufre un microcorte o degradación, ralentizará los *commits* del primario, aunque las de la derecha estén totalmente libres.


Aquí el orden importa. `replica_a` tiene la prioridad 1, `replica_b` la prioridad 2, y `replica_c` la prioridad 3. PostgreSQL necesita que **las primeras dos réplicas de la lista que estén vivas y conectadas** confirmen la transacción.

* **Caso A: Todo funciona normal (Las 3 réplicas están online)**
* **¿Quiénes son síncronos?:** **`replica_a` y `replica_b**`. El maestro esperará obligatoriamente a estas dos. No importa si `replica_b` es más lenta que `replica_c`; el maestro esperará a `b`.
* **¿Quién es asíncrono?:** **`replica_c`**. Actúa como una réplica de respaldo (standby latente). Recibe los datos, pero el maestro no la espera para hacer el commit.


* **Caso B: Se cae la réplica con mayor prioridad (`replica_a` se desconecta)**
* **¿Quiénes son síncronos ahora?:** Automáticamente, la prioridad corre hacia la derecha. Las dos primeras vivas ahora son **`replica_b` y `replica_c**`. El maestro empezará a esperar a `replica_c` de forma síncrona.
* **¿Qué pasa si `replica_a` revive?:** En cuanto `replica_a` se vuelva a conectar y se ponga al día, recupera su máxima prioridad. El maestro volverá a exigir a `replica_a` y `replica_b`, y `replica_c` volverá a ser asíncrona.


* **Riesgo de bloqueo:** Si se caen dos réplicas cualesquiera (por ejemplo, A y B, o B y C), el maestro se bloqueará. Solo te queda una réplica viva y la regla exige estrictamente "FIRST 2".

 

### 2. Esquema de Quórum (`ANY N`)

**Sintaxis:** `synchronous_standby_names = 'ANY 2 (replica_a, replica_b, replica_c)'`

* **¿Para qué sirve?:** Libera la transacción en cuanto **cualesquiera** `N` réplicas de la lista respondan. Es un modelo democrático: las más veloces en ese milisegundo liberan el *commit*.
* **¿Dónde se recomienda usar?:** En despliegues en la nube (AWS, GCP, Azure) distribuidos en múltiples Zonas de Disponibilidad (Multi-AZ) o Multi-región donde la latencia de red entre zonas puede fluctuar de forma impredecible.
* **¿Cuándo se usa?:** Cuando buscas **Alta Disponibilidad sin cuellos de botella**. Si un nodo sufre un pico de I/O, no frena al nodo principal porque el resto de las réplicas absorben el quórum.
* **¿Cuándo NO se usa?:** Cuando por regulaciones de cumplimiento (como GDPR o PCI-DSS) o asimetría de hardware necesitas garantizar que un servidor específico (ej. un nodo local vs. uno de Disaster Recovery geográfico lejano) contenga los datos sí o sí.

* **¿Quiénes son elegibles?:** Las tres réplicas.
* **¿Cómo funciona en el día a día?:** Cuando haces un `COMMIT`, el maestro envía los datos a las tres. Las dos réplicas que tengan la conexión de red más rápida o el disco más veloz y respondan primero, se convertirán en las **réplicas síncronas de esa transacción**.
* **¿Quién es asíncrono aquí?:** La réplica que llegó en "tercer lugar" (la más lenta) actúa como **asíncrona para esa transacción específica**. Por ejemplo, si en la Transacción #1 responden primero A y B, ellas fueron síncronas y C fue asíncrona. Si en la Transacción #2 responden primero B y C, ellas son síncronas y A actúa como asíncrona.
* **Riesgo de bloqueo:** Es mucho más seguro. Si `replica_a` se muere, tu base de datos sigue funcionando normalmente porque el maestro todavía tiene a `replica_b` y `replica_c` vivas para cumplir con la regla de "ANY 2". Solo se bloqueará si se caen dos réplicas al mismo tiempo.
 
 

### 3. El Comodín Dinámico (`*` con método)

**Sintaxis:** `synchronous_standby_names = 'ANY 2 (*)'` o `'FIRST 2 (*)'`

* **¿Para qué sirve?:** Aplica la regla de quórum o prioridad a **cualquier nodo secundario que logre conectarse al primario**, ignorando por completo el nombre de la aplicación (`application_name`). PostgreSQL esperará a que cualesquiera 2 réplicas confirmen que han recibido y escrito el WAL (Write-Ahead Log) antes de dar la transacción por confirmada (commit) al cliente.
* **¿Dónde se recomienda usar?:** En entornos hiperdinámicos y contenerizados, específicamente orquestados por **Kubernetes** mediante operadores avanzados como **CloudNativePG** o Zalando.
* **¿Cuándo se usa?:** Cuando los nodos secundarios escalan automáticamente de forma elástica (*Auto-scaling*). Como sus nombres e IPs cambian constantemente creados por el orquestador, el asterisco evita tener que modificar el `postgresql.conf` del primario cada vez que nace o muere una réplica.
* **¿Cuándo NO se usa?:** Si mezclas en el mismo clúster réplicas destinadas a Alta Disponibilidad con réplicas dedicadas a reportes analíticos pesados (BI). Si el comodín otorga estado síncrono a una réplica analítica lenta, destruirá el rendimiento transaccional del primario.


* **¿Quiénes son elegibles?:** **Cualquier** nodo que se conecte al maestro, sin importar el nombre que tenga.
* **¿Cómo funciona en el día a día?:** Es idéntico al esquema quorum 2 en cuanto a rendimiento: las dos réplicas más rápidas en responder serán las síncronas para esa transacción, y la tercera (o cuarta, si agregas más en el futuro) será asíncrona.
* **La gran diferencia teórica/operativa:** No estás limitado a los nombres de tu lista.
* Si mañana decides crear una cuarta réplica llamada `replica_d` para escalar tu lectura, **automáticamente entra en el juego síncrono** sin necesidad de que reinicies o recargues la configuración del nodo maestro.
* Cualquiera de las 4 réplicas que responda primero servirá para liberar el commit en el maestro.

 
### 4. La Sintaxis de Asterisco Puro (Atajo Absoluto)

**Sintaxis:** `synchronous_standby_names = '*'`

* **¿Cómo lo interpreta Postgres?:** Si colocas únicamente el asterisco sin especificar un método, el motor lo traduce internamente como **`FIRST 1 (*)`**.
* **El Comportamiento Real:** El primer servidor réplica que logre establecer conexión con el primario tomará el estado **`sync`** (síncrono activo). Cualquier otra réplica que se conecte después quedará relegada a estado **`potential`** (asíncrona de reserva). Si la réplica activa se cae, la siguiente en la fila es promovida de inmediato.
* **¿Cuándo se usa?:** En arquitecturas sencillas de escalado horizontal donde solo te interesa garantizar que al menos un nodo en cualquier parte tenga una copia exacta de respaldo en tiempo real.
* **¿Por qué evitarlo en Fintech?:** Porque depender de un quórum de tan solo `1` (`FIRST 1`) te deja expuesto ante fallos simultáneos. Si el primario y esa única réplica síncrona fallan al mismo tiempo, rompes el RPO=0 y te arriesgas a pérdida de datos, violando las normativas bancarias estrictas.
* **El riesgo que corres con Cumplimiento / Regulación (GDPR / PCI-DSS):** si una replica que esta en otro pais se coloca como maestro, aqui es donde la regulaciones bancarias o leyes de privacidad (como GDPR), los datos financieros de tus usuarios locales no pueden ser procesados ni ser la matriz principal fuera de las fronteras de tu país. Al haber permitido que ANY 2 eligiera la réplica lejana para salvar el quórum, terminaste mudando la operación bancaria a una jurisdicción ilegal para tu negocio.


* **¿Cómo funciona?:** El maestro tomará como síncrona a **la primera réplica que se haya conectado a él**, sin importar su nombre.
* **¿Quién es síncrono?:** Imaginemos que tras encender el clúster, `replica_b` se conectó unos milisegundos antes que las demás. `replica_b` se convierte en la **única réplica síncrona**. El maestro solo esperará a `replica_b` para confirmar los commits.
* **¿Quiénes son asíncronos?:** `replica_a` y `replica_c`. Aunque estén conectadas y sanas, actúan como asíncronas porque el cupo de "FIRST 1" ya lo llenó `replica_b`.
* **¿Qué pasa si se cae la réplica síncrona (`replica_b`)?:** En el momento en que `replica_b` pierde conexión, el maestro promueve inmediatamente a cualquiera de las otras dos que siga conectada (por ejemplo, `replica_a`) para que sea la nueva réplica síncrona. El sistema no se bloquea.



 
### 5. Sintaxis Implícita (Legacy / Clásica)

**Sintaxis:** `synchronous_standby_names = 'replica_a, replica_b'`

* **¿Para qué sirve?:** Es un atajo heredado de versiones antiguas de Postgres. Funciona exactamente igual que un `FIRST 1 (replica_a, replica_b)`.
* **¿Dónde se recomienda usar?:** Únicamente en entornos obsoletos (PostgreSQL 9.5 o inferior) que no reconozcan la sintaxis declarativa moderna.
* **¿Por qué evitarla hoy?:** En versiones modernas (Postgres 10 en adelante) es considerada una **mala práctica de legibilidad**. Al no especificar explícitamente las palabras `FIRST` o `ANY`, confunde a otros ingenieros o DBAs que hereden la infraestructura, quienes podrían asumir erróneamente que ambas réplicas son síncronas al mismo tiempo cuando en realidad solo una lo es.
  


### Resumen: `ANY` vs `FIRST` con un ejemplo práctico

Imagina que enviamos una transacción pesada:

* Con **`ANY 2 (A, B, C)`**: El maestro le grita a las tres: *"¡Oigan! Las dos primeras que terminen y me avisen, nos vamos"*. Si A y C tienen discos SSD rápidos, responden primero y el cliente recibe su confirmación. B (que tiene un disco mecánico lento) termina después de manera asíncrona.
* Con **`FIRST 2 (A, B, C)`**: El maestro dice: *"No me importa quién sea el más rápido, yo le prometí al jefe que esperaría a A y a B. Así que hasta que A y B no me confirmen, nadie se mueve"*. Si C terminó antes, al maestro no le importa, el cliente tiene que esperar a que A y B procesen la transacción.

---


# Saber si es sync o async
Para saber con total certeza sync o async  el estado de tus réplicas, debes conectarte al **nodo Primario** y ejecutar una consulta a la vista del sistema **`pg_stat_replication`**.
 

```sql
SELECT 
    application_name AS replica_nodo,
    client_addr AS ip_replica,
    state AS estado_conexion,
    sync_state AS tipo_sincronia,
    sync_priority AS prioridad
FROM pg_stat_replication;

```
 

## Cómo interpretar el resultado

La columna clave que define todo es **`sync_state`**. Esto es lo que significa cada valor que te devuelva Postgres:

| Valor en `sync_state` | ¿Qué es realmente? | Comportamiento con el Primario |
| --- | --- | --- |
| **`sync`** | **Síncrono Activo** | El primario está congelando tus transacciones hasta que este nodo confirme recibido. (Aparece con `FIRST N`). |
| **`quorum`** | **Síncrono por Quórum** | Es síncrono. Está participando activamente en la votación para liberar la transacción. (Aparece con `ANY N`). |
| **`potential`** | **Asíncrono de Reserva** | **Hoy opera como asíncrono** (el primario no lo espera), pero si un nodo `sync` muere, Postgres lo promoverá automáticamente a síncrono. |
| **`async`** | **Asíncrono Puro** | Nunca esperará por él. Está totalmente fuera de la lista de `synchronous_standby_names`. Es seguro para reportes o Disaster Recovery geográfico. |

> 💡 **Nota del Experto:** Si la consulta no devuelve ninguna fila, significa que tus réplicas no están conectadas al primario, o que estás ejecutando el comando en el nodo equivocado (en una réplica en lugar del primario).




