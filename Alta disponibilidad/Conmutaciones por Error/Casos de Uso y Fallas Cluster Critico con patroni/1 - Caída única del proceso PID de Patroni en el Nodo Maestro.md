

### Incidente: Caída única del proceso PID de Patroni en el Nodo Maestro
* **Condición inicial:** El sistema operativo, la interfaz de red y el proceso nativo de PostgreSQL en el nodo Maestro **siguen en ejecución**. Únicamente el demonio/proceso de Patroni se detiene de forma abrupta.


Como especialista en sistemas distribuidos, alta disponibilidad (HA) y ciberseguridad en entornos críticos (Fintech/Banca), entiendo perfectamente la criticidad de tu consulta. En un sistema donde el "Downtime" no es una opción, cada componente debe fallar de forma segura (*fail-safe*).

Si **únicamente el proceso PID de Patroni** muere en el nodo Maestro (Primary), pero el sistema operativo y el proceso de PostgreSQL siguen vivos, se desencadena una secuencia de eventos automatizada en cuestión de segundos.

A continuación, te detallo el comportamiento cronológico del clúster y el impacto en cada una de las tecnologías de tu stack:

## 1. Cronología del Fallo y Comportamiento del Clúster

### Fase 1: Aislamiento Inmediato del Tráfico (Capa de Red y Ruteo)

* **HAProxy:** Los nodos de HAProxy están constantemente monitoreando la API REST de Patroni (usualmente en el puerto `8008`, endpoint `/primary` o `/master`). Al caer el proceso de Patroni, este puerto deja de responder inmediatamente.
* **Mitigación del Riesgo:** HAProxy detecta la caída en el siguiente *health check* (configurado típicamente cada 1-2 segundos) y **remueve de inmediato al viejo maestro** de su pool de escrituras. El tráfico de la aplicación (que pasa por **PgBouncer** hacia HAProxy) deja de enviarse a este nodo, evitando escrituras huérfanas.
* **Keepalived:** Si el Keepalived estaba corriendo en el mismo nodo maestro gestionando una IP Virtual (VIP) para los componentes de aplicación, Keepalived **no se inmuta** inicialmente porque el nodo y el servicio de HAProxy/Red siguen vivos. La VIP solo se movería si el nodo completo fallara o si tienes un script de *track* monitoreando a Patroni.

### Fase 2: Expiración del Bloqueo en el DCS (etcd)

* **etcd:** Patroni mantiene su condición de líder renovando periódicamente una llave en `etcd` con un tiempo de vida definido (TTL) (parámetros `loop_wait` y `ttl` en Patroni, por defecto 10s y 30s respectivamente).
* **Expiración:** Como el PID de Patroni está muerto, nadie renueva la llave en `etcd`. Al expirar el TTL, `etcd` libera la llave de líder. El clúster se queda oficialmente sin maestro en el plano de control.

### Fase 3: Elección del Nuevo Maestro y Preferencia Síncrona

* **Elección:** Los Patroni de las réplicas (Asíncrona y Síncrona) detectan que la llave de líder está libre e inician una votación.
* **Preferencia del Nodo Síncrono:** Por diseño de Patroni y consistencia bancaria (cero pérdida de datos / *RPO = 0*), **el nodo síncrono tiene total prioridad**. Patroni evaluará la posición del WAL (Log de transacciones). Dado que la réplica síncrona está garantizada a estar al día con el maestro, esta ganará la elección, se promoverá a sí misma como nuevo Maestro (`Read-Write`) y tomará la llave en `etcd`.
* **Actualización de HAProxy:** Los HAProxy del clúster detectarán que el endpoint `/primary` ahora responde en el nodo que era la réplica síncrona. El tráfico de PgBouncer se redirige automáticamente al nuevo maestro.



## 2. El Riesgo Crítico: Split-Brain y el rol del Watchdog

Aquí entra tu rol como experto en seguridad y arquitectura. Dado que el proceso de PostgreSQL en el viejo maestro **sigue vivo** (porque solo murió el PID de Patroni), existe un riesgo teórico de *Split-Brain* si un cliente lograra saltarse a HAProxy y conectarse directamente a la IP real del viejo maestro.

Para evitar esto en entornos Fintech bancarios, la documentación oficial de Patroni exige implementar un **Watchdog (STONITH / Shoot The Other Node In The Head)**.

### ¿Cómo actúa el Watchdog en este escenario?

1. Patroni abre el dispositivo de Watchdog del Kernel de Linux (ej. `/dev/watchdog`) y le envía un "ping" constante.
2. Al morir el PID de Patroni, se interrumpe este ping.
3. El hardware/kernel detecta que Patroni ya no responde. Antes de que expire el TTL en `etcd`, el Watchdog **fuerza un reinicio de hardware inmediato (Hard Reset / Panic)** del viejo nodo maestro.
4. Esto garantiza al 100% que el viejo PostgreSQL está apagado antes de que la réplica síncrona asuma el rol de nuevo maestro.



## 3. Estado de los Componentes Periféricos

* **PgBouncer:** Sufrirá una breve interrupción de conexiones (aprox. entre 5 y 30 segundos dependiendo de tus parámetros de `ttl` y `timeouts`). Al reconectarse a través de HAProxy, las aplicaciones volverán a operar normalmente sobre el nuevo maestro. Las transacciones en vuelo en el momento exacto de la caída recibirán un error y la aplicación deberá reintentarlas (*Retry logic*).
* **pgAudit:** Como el proceso de PostgreSQL en el maestro original se detiene (ya sea por el Watchdog o por intervención manual posterior), `pgAudit` dejará de escribir logs locales en ese nodo. Sin embargo, el nuevo maestro ya tiene `pgAudit` activo, por lo que la trazabilidad y el cumplimiento normativo (PCI-DSS / SOX) continúan ininterrumpidos en el nuevo nodo primario.
* **pgBackRest:** No se ve afectado. `pgBackRest` debe estar configurado idealmente apuntando a una réplica para los respaldos, o configurado con la directiva `pg1-host`, `pg2-host`, etc. Al cambiar el maestro, `pgBackRest` interactúa con la arquitectura según su configuración de estrofas, garantizando que los backups no se rompan.

### Paso 4: Restablecer la Política de Alta Disponibilidad Síncrona

En una arquitectura Fintech con 3 nodos, perder un nodo significa que el nuevo maestro se ha quedado temporalmente con una sola réplica (la asíncrona).

* Si la configuración de Patroni define un esquema dinámico (`synchronous_mode: true`), Patroni ascenderá automáticamente la réplica disponible al estado **Síncrono** para mantener el *RPO=0*.
* El DBA debe cerciorarse de que, al reincorporar el tercer nodo, el estado de la replicación síncrona regrese a la normalidad según la prioridad definida en el archivo de configuración, garantizando nuevamente la redundancia geográfica o de zona ante un segundo fallo.

### Paso 5: Auditoría y Cumplimiento de Seguridad

* Revisar los logs de `pgAudit` del maestro anterior (si el almacenamiento local sobrevivió) y del nuevo maestro para asegurar que la caída del proceso no estuvo vinculada a un intento de denegación de servicio (DoS) o manipulación no autorizada a nivel de sistema operativo.


## Resumen Ejecutivo para tu Cliente

> "Si el proceso de Patroni muere en el Maestro, el sistema se auto-recuperará sin pérdida de datos (RPO=0) y con un tiempo de interrupción mínimo (RTO < 30 segundos). HAProxy cortará el tráfico de inmediato al viejo maestro, etcd liberará el liderazgo por timeout, y la réplica síncrona será promovida a nuevo Maestro. Si seguimos las buenas prácticas bancarias y tenemos el Watchdog activo, el nodo viejo se reiniciará agresivamente por hardware para garantizar que no existan escrituras dobles (Split-Brain), manteniendo la integridad absoluta de los datos financieros. Posteriormente, el DBA podrá reintegrar el nodo de forma 100% automatizada y segura mediante pg_rewind sin afectar la continuidad del negocio."


