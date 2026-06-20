# Parámetros Críticos de Integridad y Seguridad para Réplicas (PostgreSQL + Patroni)

la **integridad de los datos** y la **consistencia estricta** son el pilar fundamental. Un error de divergencia de datos entre nodos (*data drift*) o un retraso mal gestionado puede resultar en saldos duplicados o transacciones fantasma.

No basta con activar la replicación; se deben configurar parámetros específicos para blindar el flujo de datos. A continuación, analizamos las directivas clave en `postgresql.conf` y `patroni.yml` que garantizan que tus réplicas sean espejos matemáticamente íntegros y seguros.



## 1. Configuración Avanzada en PostgreSQL (`postgresql.conf`)

### A. `synchronous_commit` (Más allá de solo activarlo)

Este parámetro define qué tan "seguro" es el acuerdo de confirmación antes de responder `SUCCESS` a la aplicación. Para la banca, el valor por defecto `on` a veces queda corto. Los niveles recomendados son:

* **`remote_apply` (El Estándar de Oro Fintech):** El Maestro congela el `COMMIT` hasta que la réplica síncrona confirma que el WAL ha sido recibido, escrito en disco **y aplicado en el motor de datos**.
* *¿Por qué es vital?:* Evita el efecto de "lectura inconsistente". Si un cliente transfiere dinero en el maestro e inmediatamente consulta su saldo en la réplica, con `remote_apply` se garantiza que verá el saldo actualizado. Elimina el desfase de visibilidad.


* **`on`:** El Maestro espera a que el WAL se escriba en el disco de la réplica, pero no a que se aplique. Es seguro contra pérdida de datos, pero puede haber micro-lag en las consultas de lectura.
* **Prohibidos en Banca:** `local`, `remote_write` (riesgo de pérdida si el OS de la réplica muere) u `off`.

### B. `hot_standby_feedback = on`

* **El Problema:** El Maestro ejecuta el proceso de limpieza (`VACUUM`) para eliminar filas muertas. Si el Maestro borra filas que una réplica todavía está usando para generar un reporte financiero largo, la replicación se congela o la réplica cancela brutalmente la consulta del usuario (*Replication Conflict*).
* **La Solución de Integridad:** Al activarlo, la réplica le avisa constantemente al Maestro qué transacciones de lectura tiene activas. El Maestro pospone el `VACUUM` de esas filas específicas. Garantiza la **integridad de las consultas de auditoría y reportes** en las réplicas sin corromper la sesión.

### C. `data_checksums = on` (Protección contra el "Bit Rot")

* **Nota Crítica:** Este parámetro **no se puede activar en el archivo de texto**; debe habilitarse durante la creación del clúster (`initdb --data-checksums`) o en frío mediante `pg_checksums`.
* **Función de Ciberseguridad:** Añade un código de verificación a cada bloque de datos en disco. Si un disco NVMe/SSD falla silenciosamente y corrompe un bit (degradación física), PostgreSQL lo detecta inmediatamente al leer el bloque en el maestro o la réplica, lanzando un pánico antes de propagar datos corruptos a través de la red de replicación.



## 2. Orquestación de Integridad en Patroni (`patroni.yml`)

Patroni gestiona el plano de control. Si las reglas de consistencia de Patroni son laxas, el clúster priorizará la disponibilidad sobre la verdad de los datos.

### A. `synchronous_mode: true` y `synchronous_mode_strict: true`

Este binomio es el escudo definitivo para garantizar **RPO = 0**.

```yaml
postgresql:
  synchronous_mode: true
  synchronous_mode_strict: true

```

* **`synchronous_mode: true`:** Le ordena a Patroni que configure dinámicamente el parámetro `synchronous_standby_names` en PostgreSQL usando los nodos sanos del clúster.
* **`synchronous_mode_strict: true` (Modo Estricto Bancario):** Si ocurre el Escenario #3 (todas las réplicas síncronas mueren), Patroni **prohíbe que el Maestro degrade el clúster a modo asíncrono**. El Maestro bloqueará por completo las escrituras.
* *Filosofía Financiera:* Es preferible denegar el servicio temporalmente (afectar disponibilidad) antes que permitir que se procesen transacciones en un solo nodo sin respaldo síncrono.



### B. `maximum_lag_on_failover: 0` (o valores extremadamente bajos)

* **Función:** Especifica el máximo número de bytes de retraso en el WAL que una réplica puede tener para ser elegible como nuevo Maestro durante un failover imprevisto.
* **Enfoque Bancario:** En tu arquitectura con Quórum Dinámico, este valor debe ser muy estricto para asegurar que Patroni jamás promueva a una réplica que no esté perfectamente sincronizada con la última transacción del viejo líder.



## 3. Seguridad en el Canal de Comunicación (Capa de Red)

La integridad de la réplica también depende de que nadie altere o intercepte los WALs en tránsito (*Man-in-the-Middle*).

* **`ssl = on` y Replicación por mTLS:** En `postgresql.conf`, la replicación debe exigir certificados TLS mutuos. Las réplicas deben autenticarse ante el maestro mediante certificados firmados por una Entidad Certificadora (CA) interna de la institución financiera:
```ini
ssl = on
ssl_ca_file = '/etc/postgresql/certs/ca.crt'
ssl_cert_file = '/etc/postgresql/certs/server.crt'
ssl_key_file = '/etc/postgresql/certs/server.key'

```


* **Restricción Estricta en `pg_hba.conf`:** Patroni administra este archivo. Se debe auditar que el usuario especializado de replicación (`replicator`) solo pueda conectarse desde las IPs privadas exactas de los otros nodos del clúster y obligatoriamente usando encriptación SSL y certificados válidos:
```text
hostssl replication replicator 10.0.1.12/32 cert clientcert=verify-ca
hostssl replication replicator 10.0.1.13/32 cert clientcert=verify-ca

```





## Matriz de Resumen para Políticas Corporativas

| Parámetro | Ubicación | Valor Recomendado | Objetivo de Integridad |
|  |  |  |  |
| `synchronous_commit` | `postgresql.conf` | `remote_apply` | Garantiza consistencia de lectura inmediata post-escritura (*Read-after-Write*). |
| `hot_standby_feedback` | `postgresql.conf` | `on` | Evita la caída de consultas analíticas y conflictos de MVCC en réplicas. |
| `data_checksums` | `initdb` (Core) | `on` | Detecta corrupción física de almacenamiento y evita su propagación. |
| `synchronous_mode_strict` | `patroni.yml` | `true` | Bloquea el sistema si pierde la redundancia síncrona; protege el RPO=0. |
| `ssl / clientcert` | `pg_hba.conf` | `verify-ca` | Cifra el WAL en tránsito y valida la identidad criptográfica de las réplicas. |



## Resumen Ejecutivo para tu Cliente

> "Para blindar la integridad en un entorno Fintech, no basta con tener réplicas activas; configuramos el motor bajo la política de **Consistencia Estricta**. Al aplicar `synchronous_commit = remote_apply`, nos aseguramos de que ninguna transacción se dé por buena hasta que esté visible en la réplica síncrona. Esto, en combinación con el **Modo Estricto de Patroni (`synchronous_mode_strict`)** y la encriptación por **mTLS**, garantiza que el plano de datos sea inalterable, esté protegido contra fallas físicas de disco (*checksums*) y sea inmune a la pérdida de información ante cualquier escenario catastrófico."

Para complementar esta configuración de seguridad, ¿te interesaría revisar cómo configurar las directivas de retención de WALs y slots de replicación en Patroni para evitar que el almacenamiento del maestro colapse si una réplica se desconecta prolongadamente?
