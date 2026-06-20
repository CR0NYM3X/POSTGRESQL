# Procedimiento de Mantenimiento (Runbook): Parcheo Seguro de Nodos (Rolling Upgrade)

En un entorno Fintech de misión crítica, la aplicación de parches (ya sean actualizaciones de seguridad del Sistema Operativo, parches de Kernel o actualizaciones menores de PostgreSQL de tipo *Minor Version Upgrade*) nunca debe realizarse deteniendo todo el sistema.

Para cumplir con un **RTO ≈ 0** y **RPO = 0**, se aplica estrictamente el método de **Mantenimiento Progresivo (Rolling Upgrade)**. La regla de oro de la alta disponibilidad dicta que **los parches se aplican siempre desde el nodo menos crítico hacia el más crítico**, dejando al Maestro para el final.

A continuación, se presenta el flujo paso a paso avalado por las mejores prácticas de documentación oficial para ejecutar el mantenimiento en tus réplicas síncronas y asíncronas.

---

## Pasos Previos Obligatorios (Fase de Preparación)

Antes de tocar cualquier nodo, el equipo de DBA y SecOps debe certificar la red de seguridad:

1. **Validación de Respaldos:** Verificar en **pgBackRest** que el último backup completo (*Full*) y los respaldos incrementales estén en estado `OK` y que el archivado de WALs no tenga retrasos.
2. **Chequeo de Salud del Clúster:** Ejecutar `patronictl -c /etc/patroni/patroni.yml list` para confirmar que todos los nodos están en estado `running` y con `Lag = 0`.
3. **Modo Silencio en Monitoreo:** Colocar el clúster en modo de mantenimiento en tus herramientas de monitoreo (Datadog, Prometheus/Grafana) para evitar falsas alarmas de severidad 1.

---

## Fase 1: Parcheo del Nodo Asíncrono (Menor Riesgo)

El nodo asíncrono es el candidato ideal para iniciar, ya que su salida no afecta la validación de transacciones síncronas en el maestro.

1. **Aislamiento del Tráfico:** Detener el servicio de Patroni en el nodo asíncrono:
```bash
systemctl stop patroni

```


*Nota: Al detener Patroni, este cerrará PostgreSQL de forma segura. HAProxy detectará la caída del puerto `8008` en 1 segundo y removerá el nodo del pool de lecturas de PgBouncer.*
2. **Aplicación de Parches:** Ejecutar la actualización de paquetes del sistema operativo o binarios de Postgres (ej. en RHEL/Rocky):
```bash
yum update -y postgresql16-server kernel
# O en Ubuntu/Debian: apt-get upgrade

```


3. **Reinicio de Seguridad:** Si el parche incluyó actualizaciones de Kernel, reiniciar el servidor físico/virtual (`reboot`).
4. **Reincorporación al Clúster:** Una vez encendido el sistema, iniciar Patroni:
```bash
systemctl start patroni

```


5. **Verificación:** Monitorear con `patronictl list` hasta que el nodo aparezca nuevamente como `Replica`, su estado sea `running` y el *Lag* de replicación retorne a cero.

---

## Fase 2: Parcheo del Nodo Síncrono

Bajo la arquitectura recomendada de **Quórum Dinámico (`FIRST 1`)**, el parcheo del nodo síncrono no provocará caídas ni congelamientos en el maestro, ya que el nodo asíncrono (recién parcheado) asumirá el rol síncrono de respaldo inmediatamente.

1. **Aislamiento del Tráfico:** Detener Patroni en el nodo síncrono:
```bash
systemctl stop patroni

```


*Mecánica interna:* El Maestro detecta la salida de este nodo a través de `etcd`. Como la otra réplica (asíncrona) está viva y al día, PostgreSQL transiciona el flujo síncrono hacia ella sin detener las escrituras de la aplicación. HAProxy remueve este nodo del pool de consultas.
2. **Aplicación de Parches y Reinicio:** Repetir el proceso de actualización de software y reiniciar el servidor si es requerido por el Kernel.
3. **Reincorporación:** Iniciar el servicio de Patroni:
```bash
systemctl start patroni

```


4. **Validación de Sincronía:** Ejecutar `patronictl list` y asegurar que el nodo se sincronice por completo. Patroni restablecerá automáticamente las prioridades originales, devolviendo a este nodo su rol síncrono principal.

---

## Fase 3: El Movimiento Maestro (Switchover y Parcheo del Viejo Líder)

Ahora que ambas réplicas están actualizadas y al día, el Maestro original es el único nodo sin parches. Para actualizarlo, debemos forzar un cambio de roles controlado.

### Paso 3.1: Ejecutar el Switchover

Desde cualquier nodo, lanzar la orden de transferencia de liderazgo hacia el nodo síncrono ya parcheado:

```bash
patronictl -c /etc/patroni/patroni.yml switchover

```

* **Qué sucede en la aplicación:** Patroni degrada al maestro viejo. HAProxy corta el tráfico hacia él y redirige todas las conexiones de **PgBouncer** al nuevo maestro en menos de 3 segundos. Las transacciones en vuelo en ese microsegundo se reintentan automáticamente en la capa de aplicación. El sistema sigue en línea.

### Paso 3.2: Parchear el Viejo Maestro (Ahora Réplica)

El viejo maestro ahora aparece en `patronictl list` con el rol de `Replica`. Procedemos a tratarlo como tal:

1. Detener el servicio: `systemctl stop patroni`.
2. Aplicar los parches de seguridad y actualizaciones de PostgreSQL.
3. Reiniciar el servidor si es necesario.
4. Iniciar el servicio: `systemctl start patroni`.
5. **Acción de pg_rewind:** Al arrancar, Patroni detectará que este nodo tiene una línea de tiempo divergente (porque era el antiguo maestro). Ejecutará automáticamente `pg_rewind` para acoplarlo como réplica sin necesidad de reconstruir la base de datos desde cero.

---

## Fase 4: Retorno al Estado de Diseño (Opcional)

Al finalizar la Fase 3, el clúster está 100% parcheado y operando de forma segura, pero los roles quedaron invertidos (la antigua réplica síncrona es el nuevo maestro).

Si por razones de cumplimiento, topología de red o rendimiento en el Data Center prefieres que el Maestro original recupere su trono:

* Esperar a que todos los nodos muestren `Lag = 0`.
* Ejecutar un segundo `patronictl switchover` controlado para devolver el rol de `Leader` al nodo inicial.

---

## Matriz de Estado de Componentes durante el Parcheo

| Componente | Comportamiento durante el flujo | Garantía de Seguridad |
| --- | --- | --- |
| **HAProxy / Keepalived** | Modifican dinámicamente los pools de enrutamiento leyendo las APIs REST locales de Patroni, impidiendo que el tráfico caiga en nodos en mantenimiento. | **RTO Mínimo garantizado.** |
| **pgAudit** | Cada nodo mantiene su configuración de auditoría intacta. Durante el switchover, el nuevo maestro asume la generación de logs de cumplimiento sin dejar huecos de visibilidad. | **Cumplimiento PCI-DSS continuo.** |
| **pgBackRest** | Al realizarse el mantenimiento de forma secuencial, siempre hay al menos una réplica viva disponible para la extracción y resguardo de los archivos WAL logs. | **Estrategia de respaldo ininterrumpida.** |

---

## Resumen Ejecutivo para tu Cliente

> "El proceso de parcheo se ejecuta bajo la metodología de **Rolling Upgrade**, eliminando la necesidad de ventanas de mantenimiento con apagones totales. Al actualizar secuencialmente las réplicas y utilizar un comando de **Switchover controlado** para el Maestro, el sistema financiero se mantiene operativo durante todo el proceso. La combinación de Patroni, etcd y HAProxy garantiza que el tráfico sea redirigido de forma transparente en segundos, manteniendo un **RPO = 0** y un impacto en el usuario final virtualmente imperceptible."
