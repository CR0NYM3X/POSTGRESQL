 

### 🍔 La Analogía: El Restaurante de Hamburguesas

Imagina dos formas de diseñar este restaurante:

#### Diseño SIN Cola (Arquitectura Síncrona)

El cajero toma tu pedido de una hamburguesa. En lugar de pasarlo a la cocina, el cajero camina él mismo, enciende la parrilla, cocina la carne, tuesta el pan, envuelve la hamburguesa, regresa y te la entrega. Mientras hace todo eso, **la fila de clientes en la caja no avanza**. Si la cocina se satura o se acaba el gas, el cajero se queda congelado esperando y todo el restaurante se detiene.

#### Diseño CON Cola (Arquitectura Asíncrona)

Aquí es donde entra la magia de la ingeniería de software:

```
[ Cliente ] ──> ( Cajero / Productor ) ──> [ Tablero de Pedidos / COLA ] ──> ( Cocineros / Consumidores )

```

1. **El Cajero (Productor / Producer):** Recibe tu pedido, lo anota en un ticket en menos de 2 segundos, te cobra y te dice: *"Aquí está tu número, espera allá"*. Su único trabajo es meter el ticket al sistema. El cajero nunca cocina; por eso atiende a cientos de personas sin detenerse.
2. **El Tablero de Pedidos (La Cola / Message Queue):** Es un riel de metal donde el cajero cuelga el ticket. Los tickets se organizan por orden de llegada (FIFO: *First In, First Out*). El riel "guarda" el trabajo pendiente. Si llegan 50 clientes de golpe, el riel simplemente se llena de papeles, pero **ningún pedido se pierde ni se olvida**.
3. **Los Cocineros (Consumidores / Workers):** Están en la parte de atrás. No hablan con los clientes. Su único trabajo es mirar el tablero, tomar el ticket que sigue, preparar la comida a su propio ritmo y marcarlo como "terminado". Si hay demasiado trabajo, el dueño del restaurante simplemente contrata a otro cocinero para que tome tickets del mismo tablero (Escalabilidad).

 
### 🏛️ Mecanismo de Arquitectura: Los 3 Componentes Clave

En el software, la lógica es exactamente la misma. Una arquitectura de colas se divide siempre en tres partes independientes (*desacopladas*):

* **El Productor (Producer):** Es tu aplicación web (el backend que ve el usuario). Cuando un usuario hace clic en "Comprar", el productor no procesa la compra completa; solo escribe un mensaje rápido (un archivo JSON con los datos del pedido) y lo "arroja" a la cola. Luego le responde al usuario inmediatamente: *"Recibimos tu pedido, te avisaremos por email"*.
* **La Cola (Queue / Broker):** Es el almacenamiento intermedio (que en el caso de **PgQue** vive dentro de Postgres). Su única misión en la vida es recibir mensajes, asegurar que no se borren si la luz se corta y entregarlos en orden a quienes los soliciten.
* **El Consumidor (Consumer / Worker):** Son programas que corren en segundo plano (pueden estar en otros servidores). No atienden peticiones web del usuario. Solo hacen bucles infinitos preguntándole a la cola: *¿Hay trabajo para mí? ¿Hay trabajo para mí?*. Si hay un mensaje, lo toman, hacen el trabajo pesado (procesar el pago, generar el PDF de la factura, enviar el correo) y le avisan a la cola: *"Listo, ya terminé, bórralo o avanza al siguiente"*.
 
### 🔄 El Flujo Paso a Paso (Explicado con el restaurante)

Para ver el mecanismo en acción, sigamos el viaje de un proceso común: **un usuario sube un video a una plataforma y el sistema tiene que procesarlo y cambiarle el tamaño**.

1. **Paso 1: La Petición:** El Cliente y el Cajero.
El usuario sube su video en la app. El **Productor** (servidor web) recibe el archivo, lo guarda en el disco duro e inmediatamente mete un mensaje a la **Cola**: `{"video_id": 99, "tarea": "optimizar_video"}`.


2. **Paso 2: Respuesta Inmediata:** Liberar la Caja.
El servidor web le responde al usuario en milisegundos: *"¡Video subido con éxito! Estamos procesándolo, verás una barra de carga"*. El usuario no se queda esperando a que el video se convierta (lo cual tardaría minutos). El servidor web queda libre para atender a otra persona.


3. **Paso 3: El Almacenamiento:** El ticket en el riel.
El mensaje se queda guardado de forma segura en la **Cola** (ej: mediante las tablas de **PgQue**). Si en ese momento el servidor de conversión de video se apaga o se actualiza, no pasa nada; el ticket sigue colgado esperando en el riel.


4. **Paso 4: El Procesamiento:** El cocinero toma el ticket.
El **Consumidor** (el worker encargado de procesar videos) ve el mensaje libre, lo toma y empieza a transformar el video. Durante este tiempo, la cola marca ese mensaje como "en proceso" para que ningún otro cocinero intente hacer lo mismo.


5. **Paso 5: Confirmación:** Tirar el ticket a la basura.
Cuando el video termina de optimizarse con éxito, el consumidor le envía una confirmación (*ACK / Acknowledge*) a la cola. La cola elimina el mensaje de sus pendientes porque el trabajo ya está hecho. El sistema actualiza la base de datos y le manda una notificación push al usuario: *"Tu video está listo"*.

 

### 🧠 ¿Cuál es la lógica profunda de esto? (Los Beneficios)

* **Desacoplamiento:** El cajero no sabe cocinar, el cocinero no sabe cobrar. Si la cocina cambia sus parrillas por unas eléctricas (cambias tu código de conversión de video), al cajero no le importa; él sigue anotando tickets igual.
* **Tolerancia a fallos:** Si la cocina se incendia (el servidor de video se cae), los tickets se acumulan en el riel. Cuando la cocina abre de nuevo, los cocineros retoman el trabajo justo donde se quedaron. **Ningún cliente pierde su pedido**.
* **Control de flujo (Resistencia a picos):** Si 1,000 personas piden comida al mismo tiempo, el restaurante no explota. Simplemente el riel se llena y los cocineros van sacando los pedidos uno por uno de forma organizada. La aplicación no se cae por exceso de tráfico.



---

# laboratorio

Para este laboratorio, vamos a crear un entorno controlado directamente en tu consola de base de datos (`psql` o pgAdmin). Vamos a simular nuestro "restaurante" de la analogía anterior: un sistema de e-commerce donde se generan órdenes y un servicio en segundo plano las procesa.

Lo haremos paso a paso usando SQL puro para que veas el flujo completo de **PgQue** sin necesidad de escribir código en Node.js o Python todavía.

1. **Paso 1: Instalar PgQue:** Requisito previo: Postgres 14+.
En un entorno real, descargarías el archivo `pgque.sql` del repositorio de GitHub de NikolayS y lo ejecutarías en tu base de datos para crear el esquema y las funciones base.

```bash
# Desde tu terminal
curl -O https://raw.githubusercontent.com/NikolayS/PgQue/main/sql/pgque.sql
psql -U postgres -d mi_base_datos -f pgque.sql

```


2. **Paso 2: Registrar la Cola y el Consumidor:** Crear la infraestructura.
Ahora vamos a inicializar el sistema de mensajería en Postgres. Entramos a la consola SQL y ejecutamos esto:

```sql
-- 1. Creamos la cola llamada 'ecommerce_orders' (El riel de tickets)
SELECT pgque.create_queue('ecommerce_orders');

-- 2. Registramos a nuestro consumidor (El cocinero)
SELECT pgque.register_consumer('ecommerce_orders', 'worker_facturacion');

```


3. **Paso 3: Producir Eventos (El Cajero):** Simular tráfico web.
Imagina que tres clientes compran en tu tienda casi al mismo tiempo. Tu backend solo hace estos tres inserts ultra rápidos y les devuelve la pantalla de éxito.

```sql
-- Insertamos 3 eventos tipo 'orden_pagada' en la cola
SELECT pgque.insert_event('ecommerce_orders', 'orden_pagada', '{"orden_id": 101, "cliente": "Ana"}'::jsonb);
SELECT pgque.insert_event('ecommerce_orders', 'orden_pagada', '{"orden_id": 102, "cliente": "Juan"}'::jsonb);
SELECT pgque.insert_event('ecommerce_orders', 'orden_pagada', '{"orden_id": 103, "cliente": "Luis"}'::jsonb);

```


4. **Paso 4: Forzar el Tick (La Imprenta):** El mecanismo snapshot de PgQ.
A diferencia de otras colas, PgQue usa lotes (batches) basados en el tiempo. En producción, un proceso (como `pg_cron`) hace esto automáticamente cada 100 milisegundos. En este laboratorio, lo ejecutaremos manualmente para crear el "corte" y hacer que los eventos estén disponibles para ser consumidos.

```sql
-- Forzamos la creación del lote de eventos
SELECT pgque.force_next_tick();

```


5. **Paso 5: Consumir el Lote (El Cocinero):** Leer y confirmar.
Ahora el `worker_facturacion` se despierta y pregunta a la base de datos si hay trabajo.

```sql
-- 1. Pedir el siguiente lote asignado a nuestro consumidor
-- Esto te devolverá un número, por ejemplo: batch_id = 1
SELECT batch_id FROM pgque.next_batch('ecommerce_orders', 'worker_facturacion');

```

Una vez que tienes el ID del lote, lees los eventos que contiene:

```sql
-- 2. Leer los eventos del lote 1 (Reemplaza el 1 con tu batch_id real)
SELECT event_id, event_type, event_data 
FROM pgque.get_batch_events(1);

```

*(Aquí verías las 3 órdenes de Ana, Juan y Luis. Tu código generaría las facturas).*

```sql
-- 3. Marcar el lote como terminado exitosamente.
-- Esto mueve el cursor del consumidor, asegurando que no vuelva a leer estos eventos.
SELECT pgque.finish_batch(1);

```

 

> **El superpoder del Fan-Out:** Si en el Paso 2 hubieras registrado a un segundo consumidor llamado `worker_emails`, y repites el Paso 5 usando ese nombre, ¡este consumidor **también recibiría** las mismas 3 órdenes exactas! No tuviste que duplicar la información; cada consumidor tiene su propio marcapáginas en el registro principal.
