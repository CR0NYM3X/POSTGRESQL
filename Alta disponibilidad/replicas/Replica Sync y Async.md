 
 # **El verdadero HADR en PostgreSQL: ¿Sincronía y Asincronía bajo el mismo techo?**


Imagínate que eres el dueño de una pizzería que nunca cierra. Tienes un chef principal (el **Nodo Primario**) que es un genio, pero es humano: le puede dar gripe, se puede quedar atrapado en el tráfico o, peor, se le puede quemar el horno.

Si el chef se va, la pizzería cierra y tú pierdes dinero. Para evitarlo, contratas a un segundo chef (la **Réplica**) que está justo detrás de él, mirando cada movimiento, cada gramo de harina y cada pepperoni que el primero pone. Si el primero se desmaya, el segundo salta al mostrador en segundos. ¡Eso es **HA (Alta Disponibilidad)**!

Pero, ¿qué pasa si se inunda la calle de la pizzería? Ahí necesitas otra pizzería en la ciudad vecina, con los ingredientes listos para abrir en 30 minutos. ¡Eso es **DR (Recuperación ante Desastres)**!

#### La Historia de Terror: El efecto dominó 😱

Trabajé con una empresa de seguros que tenía una réplica "espejo". Muy bonita. Pero un día, el becario (sí, nuestro viejo amigo) ejecutó un `DELETE` masivo sin `WHERE` en el servidor principal.

¿Qué crees que hizo la réplica? Como era una réplica perfecta y veloz, ¡borró todo en 0.5 segundos! No tenían una estrategia de **"Point-in-Time Recovery" (PITR)** ni un retraso configurado. Tenían **Alta Disponibilidad**, sí, ¡pero disponible para el error! Estuvieron fuera de línea 12 horas recuperando cintas de respaldo viejas. Casi pierden la licencia de operación.

#### Bajo el Capó: El motor de la continuidad

PostgreSQL no hace HADR "solo" apretando un botón, es un ensamble de piezas:

1. **Streaming Replication:** Es el flujo constante de registros **WAL** (nuestra libretita de la que hablamos antes) viajando del Primario al Secundario.
2. **Slots de Replicación:** Es como si el Primario le dijera al Secundario: "No te preocupes, yo te espero, no voy a borrar el diario hasta que me confirmes que ya lo leíste".
3. **Gestores de Failover (Patroni/Keepalived):** Postgres por sí solo no sabe que "murió". Necesitas un software externo que actúe como árbitro, detecte que el primario no respira y le diga a la réplica: "¡Tu turno, ahora tú eres el jefe!".



### ¿Alguna vez te has detenido a pensar si PostgreSQL es capaz de manejar réplicas **Síncronas** y **Asíncronas** simultáneamente en la misma topología?

Muchos administradores creen que la replicación es un interruptor global: o todos van al paso del líder, o todos corren por su cuenta. **Spoiler alert: No es así.** PostgreSQL es lo suficientemente robusto para permitirte tener un "guardaespaldas" que nunca se separa de ti (Réplica Síncrona) y un "mensajero" que viaja a su propio ritmo (Réplica Asíncrona), ambos conectados al mismo servidor primario.

### ¿Cómo es esto posible?

La magia no está en un botón mágico en el archivo de configuración, sino en el parámetro `synchronous_standby_names`.

Imagina que tienes al **Servidor A** (tu Primario). Si en tu configuración defines que solo el **Servidor C** es síncrono, el Primario se detendrá a esperar que C le confirme que recibió los datos. Mientras tanto, el **Servidor B** puede seguir conectado, recibiendo los mismos datos de forma asíncrona sin que el Primario se preocupe por su velocidad. Es el equilibrio perfecto entre **Integridad de Datos** y **Disponibilidad Geográfica**.

---

## Las Ventajas: El lado brillante de la fuerza

Implementar una arquitectura mixta es como tener un seguro de vida con beneficios extra:

* **Cero pérdida de datos (RPO = 0):** Con tu réplica síncrona, tienes la certeza de que, si el primario explota, los datos están a salvo en el nodo C.
* **Lecturas escalables sin lag:** Puedes usar la réplica asíncrona para reportes pesados o BI sin afectar el rendimiento de la transacción principal.
* **Flexibilidad geográfica:** Puedes tener la réplica síncrona en la misma zona de disponibilidad (baja latencia) y la asíncrona en otro continente para recuperación ante desastres (DRP).
* **Control total:** Tú decides qué aplicación es "crítica" y cuál puede permitirse unos milisegundos de desfase.

---

## Los Desafíos: ¿Apoco pensaste que todo era tan bonito como en los cuentos?

No todo es color de rosa en el mundo de la alta disponibilidad. Aquí te muestro los retos y desafíos que puedes enfrentar al gestionar una infraestructura híbrida:

1. **El "Efecto Ancla":** Si tu réplica síncrona (Nodo C) tiene un problema de red o se apaga, **tu base de datos principal dejará de procesar escrituras.** El Primario se queda esperando una confirmación que nunca llega.
2. **Latencia de Escritura:** Tu base de datos ahora es tan rápida como lo sea tu red hacia la réplica síncrona. Si el enlace es lento, tus usuarios lo sentirán.
3. **Complejidad en el Failover:** Si el primario cae, decidir a quién promover (¿a la síncrona que está al día o a la asíncrona que quizás tiene más recursos?) requiere una lógica de orquestación muy clara (como usar Repmgr o Patroni).
4. **Monitoreo Doble:** Tienes que vigilar dos métricas distintas: el *flushing lag* de la síncrona y el *replay lag* de la asíncrona.

---


## 1. El Fundamento: ¿Cómo se define la sincronía?

Contrario a lo que se cree, el parámetro que define si una réplica es síncrona no es solo un booleano en el `postgresql.conf` del primario, sino el parámetro **`synchronous_standby_names`**.

* **Réplicas Asíncronas:** Son el comportamiento por defecto. Cualquier nodo que se conecte vía streaming replication y **no** esté listado en `synchronous_standby_names` será asíncrono.
* **Réplicas Síncronas:** Son aquellas cuyo `application_name` (definido en el `primary_conninfo` de la réplica) aparece en la lista del parámetro mencionado arriba en el servidor A.

---

## 2. Configuración en el Servidor A (Primario)

Para lograr que **C** sea síncrona y **B** sea asíncrona, debes configurar lo siguiente en el `postgresql.conf` del Servidor A:

```ini
# postgresql.conf en Servidor A

# 1. Habilitar el modo de replicación
wal_level = logical # o replica
max_wal_senders = 10 

# 2. Definir quién es síncrono
# Aquí especificamos que solo el nodo llamado 'replica_c' es síncrono
synchronous_standby_names = 'FIRST 1 (replica_c)'

# 3. Nivel de compromiso (Controla qué espera el primario)
synchronous_commit = on 

```

### ¿Por qué esto funciona?

* Cuando el Servidor B se conecta con `application_name = replica_b`, PostgreSQL ve que no está en la lista de `synchronous_standby_names` y lo trata como **asíncrono**.
* Cuando el Servidor C se conecta con `application_name = replica_c`, PostgreSQL lo obliga a confirmar la recepción del WAL antes de darle el "OK" al commit en el primario.


 

## Conclusión

PostgreSQL te da las herramientas para construir una arquitectura de clase mundial. La mezcla de replicación síncrona y asíncrona es la base de un verdadero esquema de **High Availability & Disaster Recovery (HADR)**. Solo recuerda: con gran poder, viene una gran responsabilidad de configuración.
 
