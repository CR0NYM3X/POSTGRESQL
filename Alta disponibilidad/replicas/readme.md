 

## 🎯 ¿Para qué sirve hacer réplicas en PostgreSQL?

### ✅ 1. **Alta disponibilidad (High Availability)**
- La replicación permite que una base de datos esté disponible incluso si el servidor principal falla. Los datos se copian a uno o más servidores de réplica, que pueden asumir el rol del servidor principal en caso de fallo.


### ✅ 2. **Balanceo de carga (Load Balancing)**
- Las réplicas pueden ser utilizadas para distribuir la carga de trabajo, permitiendo que las consultas de solo lectura se ejecuten en los servidores de réplica, aliviando la carga del servidor principal.

### ✅ 3. **Recuperación ante desastres (Disaster Recovery)**
- En caso de un desastre, las réplicas pueden ser utilizadas para restaurar rápidamente los datos y minimizar el tiempo de inactividad.

### ✅ 4. **Análisis sin afectar producción**
- Puedes hacer análisis pesados o pruebas en una réplica sin afectar el rendimiento del servidor principal.

### ✅ 5. **Migraciones o actualizaciones**
- Puedes usar una réplica lógica para migrar datos entre versiones diferentes de PostgreSQL o hacia otro sistema.

### ✅ 6. **Integración con otros sistemas**
- La replicación lógica permite enviar cambios en tiempo real a sistemas como Kafka, Elasticsearch, BigQuery, etc.

---

## 🔄 ¿Cuándo usar cada tipo?

| Objetivo | Tipo de réplica recomendada | ¿Por qué? |
|---------|------------------------------|-----------|
| Alta disponibilidad | **Streaming (física)** | Réplica exacta del servidor, lista para tomar el control. |
| Balanceo de carga | **Streaming (física)** | Ideal para consultas de solo lectura. |
| Análisis o BI | **Lógica** | Puedes replicar solo ciertas tablas. |
| Integración con otros sistemas | **Lógica** | Permite enviar cambios en formato JSON o eventos. |
| Migración entre versiones | **Lógica** | Compatible entre versiones distintas. |


 
### 🔹 **Failover**
El **failover** ocurre cuando el **nodo primario** falla inesperadamente y un nodo **standby** se convierte automáticamente en el nuevo **nodo primario**.  
✅ Se activa de manera automática en sistemas configurados con monitoreo y failover.  
✅ Evita la caída total del servicio.  
✅ Se usa en escenarios de emergencia cuando el servidor principal deja de funcionar.  
Ejemplo de comando manual:
 
### 🔹 **Switchover**
El **switchover** es un proceso planificado en el que el nodo **primario** y uno **standby** intercambian roles de forma controlada.  
✅ Se realiza sin que haya fallos en el sistema.  
✅ Se usa para mantenimiento o actualizaciones del nodo primario.  
✅ Permite cambiar de líder sin interrupciones.  
 

💡 **Diferencia clave:**  
- **Failover** = Evento inesperado, ocurre por una falla.  
- **Switchover** = Cambio intencional y programado.


---

## ⚠️ Consideraciones

- La **replicación física** es más simple y rápida, pero menos flexible.
- La **replicación lógica** es más flexible (puedes elegir tablas), pero requiere más configuración.
- Ambas pueden coexistir si configuras `wal_level = logical`.

 

## 🔍 Niveles de `wal_level` en PostgreSQL

### 1. `minimal`
- **¿Qué hace?**  
  Registra solo lo estrictamente necesario para la recuperación ante fallos.
- **Uso típico:**  
  Operaciones de carga masiva (`COPY`, `INSERT`) cuando no se necesita replicación ni puntos de recuperación avanzados.
- **Ventajas:**  
  - Menor volumen de WAL.
  - Mejor rendimiento en operaciones masivas.
- **Desventajas:**  
  - No permite replicación.
  - No se puede usar para backups PITR (Point-In-Time Recovery).

---

### 2. `replica` (antes llamado `archive`)
- **¿Qué hace?**  
  Registra suficiente información para replicación física y recuperación PITR.
- **Uso típico:**  
  Replicación física entre servidores PostgreSQL (standby).
- **Ventajas:**  
  - Permite replicación física.
  - Compatible con herramientas de backup como `pg_basebackup`.
- **Desventajas:**  
  - No permite replicación lógica.
  - Más volumen de WAL que `minimal`.

---

### 3. `logical`
- **¿Qué hace?**  
  Registra todos los cambios necesarios para replicación lógica (como `wal2json`, `pgoutput`, etc.).
- **Uso típico:**  
  - Replicación lógica.
  - Integración con sistemas externos (Kafka, Debezium, etc.).
  - Captura de datos en cambio (CDC).
- **Ventajas:**  
  - Permite replicación lógica y física.
  - Ideal para arquitecturas orientadas a eventos.
- **Desventajas:**  
  - Mayor volumen de WAL.
  - Puede impactar el rendimiento si no se gestiona bien.

 

# Conceptos que se usan en las replicas 
```sql

Maestro/Primario
Esclavo/secundario/standby

- **Activo-Activo**:  En PostgreSQL 16, se ha mejorado la replicación lógica para permitir una configuración Activo-Activo, donde dos instancias de PostgreSQL pueden recibir escrituras simultáneamente y sincronizar los cambios entre ellas.
En este modelo, todos los nodos están operativos y procesan solicitudes y cambios simultáneamente. Esto permite distribuir la carga de trabajo entre múltiples servidores, mejorando el rendimiento y la disponibilidad. Si un nodo falla, los demás continúan funcionando sin interrupciones.

- **Activo-Pasivo**: Aquí, solo un nodo está activo y maneja las solicitudes, mientras que otro nodo permanece en espera (pasivo). Si el nodo activo falla, el pasivo puede toma el control mediante failover. Este enfoque es más simple y garantiza estabilidad, pero no aprovecha los recursos del nodo pasivo hasta que sea necesario.

El **split-brain** es un problema que ocurre en sistemas de alta disponibilidad y replicación, cuando dos nodos **pierden comunicación entre sí**, pero **ambos creen que son el primario** al mismo tiempo.
----------------------------------------------------------------------------------------------------------------------------------------------------------------
El **quórum** es el número mínimo de nodos que deben estar **de acuerdo** para tomar decisiones dentro de un clúster distribuido, como el failover en PostgreSQL con **Repmgr**, **Patroni**, o sistemas como **etcd/Consul**.  

  **¿Cómo funciona el quórum en alta disponibilidad?**  
  **1. Se requiere mayoría (más del 50%)**  
- Si tienes 5 nodos en total, **al menos 3 deben estar activos y en consenso** para tomar decisiones.  
- Evita que un solo nodo pueda decidir unilateralmente.  

  **2. Impide problemas de split-brain**  
- Si un primario falla y no hay quórum, **no se elige un nuevo primario** hasta que haya consenso.  
- Protege contra la promoción accidental de múltiples primarios.  


  **Ejemplo real de quórum en PostgreSQL con 3 nodos**  
  *Si tienes 3 nodos (`pgmaster`, `pgslave1`, `pgslave2`) y `pgmaster` falla:*  
-  Si **solo `pgslave1` sigue activo**, no hay quórum y no ocurre failover.  
-  Si **`pgslave1` y `pgslave2` siguen activos**, hay quórum y uno de ellos se promueve a primario.  
----------------------------------------------------------------------------------------------------------------------------------------------------------------

¿Qué significa el consenso en términos generales?  Es un acuerdo entre múltiples participantes → Un grupo debe tomar una decisión colectiva basada en reglas claras.  Evita que haya decisiones individuales incorrectas → Por ejemplo, en replicación de bases de datos, un nodo no puede decidir solo convertirse en primario sin confirmación de los demás.  Se usa en algoritmos de failover y gestión de sistemas distribuidos → Como Raft, Paxos y Etcd, que permiten que los servidores acuerden quién es el líder.
----------------------------------------------------------------------------------------------------------------------------------------------------------------

CAP Theorem → En bases de datos distribuidas, puedes tener Consistencia (C), Disponibilidad (A) o Tolerancia a Particiones (P), pero nunca las tres simultáneamente.
----------------------------------------------------------------------------------------------------------------------------------------------------------------


## Bibliografía 
```
https://www.youtube.com/watch?v=kW8xT_cgEMM
```
