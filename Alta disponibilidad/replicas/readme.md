 

## 🎯 ¿Para qué sirve hacer réplicas en PostgreSQL?

### ✅ 1. **Alta disponibilidad (High Availability)**
- Si el servidor principal falla, puedes cambiar rápidamente a una réplica.
- Muy útil en sistemas críticos donde el tiempo de inactividad no es aceptable.

### ✅ 2. **Balanceo de carga (Load Balancing)**
- Puedes enviar consultas de solo lectura (como reportes o dashboards) a una réplica.
- Esto reduce la carga en el servidor principal.

### ✅ 3. **Recuperación ante desastres (Disaster Recovery)**
- Tener una réplica en otra ubicación geográfica permite restaurar el servicio en caso de fallos graves.

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

 
