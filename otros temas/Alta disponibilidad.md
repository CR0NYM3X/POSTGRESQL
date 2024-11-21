# Tipos de Alta Disponibilidad en PostgreSQL

## 1. Replicación por Streaming (Streaming Replication)

### Descripción
- Método nativo de PostgreSQL que replica continuamente los cambios del WAL (Write-Ahead Log)
- Mantiene una copia exacta bit a bit del cluster primario
- Soporta replicación síncrona y asíncrona

### Ventajas
- Configuración relativamente simple
- Bajo impacto en el rendimiento
- Solución nativa sin software adicional
- Ideal para disaster recovery
- Soporta replicación en cascada

### Desventajas
- Los standby son de solo lectura
- Requiere replicar toda la instancia
- Mayor uso de ancho de banda
- Latencia en replicación síncrona

## 2. Replicación Lógica (Logical Replication)

### Descripción
- Replica los cambios a nivel de datos utilizando un formato lógico
- Permite replicación selectiva de tablas y bases de datos
- Compatible entre diferentes versiones de PostgreSQL

### Ventajas
- Replicación selectiva de datos
- Soporta upgrade entre versiones
- Permite modificaciones en standby
- Menor uso de ancho de banda

### Desventajas
- No replica todos los tipos de objetos (ej: secuencias)
- Mayor complejidad de configuración
- Puede requerir resolución manual de conflictos
- Mayor overhead en el servidor primario

## 3. Clustering Bi-Direccional (Multi-Master)

### Descripción
- Permite escrituras en múltiples nodos simultáneamente
- Implementado mediante soluciones como BDR o Postgres-XL
- Distribuye la carga entre varios nodos

### Ventajas
- Escrituras en cualquier nodo
- Escalabilidad horizontal real
- Balanceo de carga nativo
- Sin punto único de fallo

### Desventajas
- Alta complejidad de implementación
- Posibles conflictos de escritura
- Mayor latencia en transacciones
- Costo elevado de mantenimiento

## 4. Patroni (Failover Automático)

### Descripción
- Framework de alta disponibilidad para PostgreSQL
- Gestiona automáticamente failover y failback
- Utiliza DCS (Distributed Configuration Store)

### Ventajas
- Failover automático
- Altamente configurable
- Integración con HAProxy/keepalived
- Gestión robusta del cluster

### Desventajas
- Requiere infraestructura adicional (etcd/Consul)
- Complejidad operativa
- Necesidad de expertise específico
- Overhead de monitorización

## 5. Shared Disk Failover

### Descripción
- Utiliza almacenamiento compartido entre nodos
- Failover rápido sin necesidad de sincronización
- Basado en hardware especializado

### Ventajas
- Failover muy rápido
- Sin necesidad de replicación
- Menor complejidad de datos
- Ideal para bases grandes

### Desventajas
- Costo elevado del hardware
- Punto único de fallo en storage
- Limitado por distancia física
- Dependencia del fabricante

## 6. Trigger-Based Replication

### Descripción
- Replicación basada en triggers personalizados
- Permite lógica de replicación compleja
- Flexible y personalizable

### Ventajas
- Alta flexibilidad
- Control granular
- Permite transformaciones
- Compatible con sistemas legacy

### Desventajas
- Alto impacto en rendimiento
- Mantenimiento complejo
- Propenso a errores
- No escala bien

## 7. pgPool-II

### Descripción
- Middleware que proporciona pooling, replicación y balanceo
- Puede realizar particionamiento de datos
- Ofrece funcionalidades de proxy SQL

### Ventajas
- Connection pooling eficiente
- Balanceo de carga
- Paralelización de queries
- Caché de queries

### Desventajas
- Punto único de fallo si no está en cluster
- Complejidad de configuración
- Overhead de proxy
- Puede afectar la latencia

## 8. Replicación por Log Shipping

### Descripción
- Envío periódico de archivos WAL
- Método más básico de replicación
- Útil para backups punto en el tiempo

### Ventajas
- Simple de implementar
- Bajo overhead
- Útil para backup
- Funciona en redes lentas

### Desventajas
- Mayor RPO/RTO
- Proceso manual de failover
- No tiempo real
- Gestión de archivos compleja

## 9. Slony-I

### Descripción
- Sistema de replicación asíncrona por triggers
- Soporta replicación selectiva
- Permite topologías complejas

### Ventajas
- Muy flexible
- No requiere shared storage
- Soporta upgrade rolling
- Replicación selectiva

### Desventajas
- Performance impact significativo
- Complejo de configurar
- Overhead considerable
- Mantenimiento demandante




#############

# Tipos de Alta Disponibilidad y Clustering en PostgreSQL

[Contenido anterior se mantiene igual hasta Slony-I...]

## 10. Citus

### Descripción
- Extensión de PostgreSQL para clustering distribuido
- Permite sharding horizontal transparente
- Distribuye tablas entre múltiples nodos
- Soporta queries distribuidos y paralelos
- Ideal para cargas de trabajo analíticas y multi-tenant

### Ventajas
- Escalabilidad horizontal masiva
- Mantiene características de PostgreSQL
- Sharding transparente
- Soporte para tiempo real analytics
- Procesamiento paralelo de queries
- Compatible con extensiones PostgreSQL

### Desventajas
- Complejidad en el diseño de sharding
- Limitaciones en joins distribuidos
- Costo de licenciamiento enterprise
- Requiere planificación cuidadosa del modelo de datos
- No todos los features de PostgreSQL funcionan en modo distribuido

## 11. Postgres-XL

### Descripción
- Fork de PostgreSQL para clustering masivamente paralelo
- Arquitectura MPP (Massively Parallel Processing)
- Coordinadores múltiples y datanodes
- Soporte ACID completo en ambiente distribuido
- Sharding transparente y replicación integrada

### Ventajas
- Escalabilidad lineal
- Procesamiento paralelo real
- Consistencia global
- Soporta OLTP y OLAP
- Multiple-coordinator para alta disponibilidad

### Desventajas
- Fork separado de PostgreSQL
- Retraso respecto a versiones oficiales
- Complejidad operacional alta
- Curva de aprendizaje pronunciada
- Limitaciones en algunas extensiones

## 12. PGGrid

### Descripción
- Solución de clustering para PostgreSQL
- Enfoque en particionamiento de datos
- Balanceo de carga incorporado
- Soporte para sharding automático

### Ventajas
- Arquitectura flexible
- Facilidad de escalamiento
- Balanceo automático
- Gestión centralizada

### Desventajas
- Proyecto menos maduro
- Documentación limitada
- Comunidad más pequeña
- Menor soporte empresarial

## 13. Stado Enterprise

### Descripción
- Plataforma de clustering empresarial
- Basado en PostgreSQL-XL
- Incluye herramientas de administración
- Soporte para automatización y monitoreo

### Ventajas
- Solución empresarial completa
- Herramientas de gestión incluidas
- Soporte profesional
- Automatización avanzada

### Desventajas
- Costo elevado
- Dependencia del proveedor
- Requiere expertise específico
- Overhead operacional

## Comparativa de Soluciones de Sharding

### Para OLTP (Online Transaction Processing):
- **Citus**: Mejor opción para aplicaciones multi-tenant y cargas de trabajo mixtas
- **Postgres-XL**: Ideal para consistencia global y transacciones distribuidas
- **PGGrid**: Bueno para casos de uso más simples con sharding básico

### Para OLAP (Online Analytical Processing):
- **Citus**: Excelente para análisis en tiempo real y cargas mixtas
- **Postgres-XL**: Superior para queries analíticos complejos
- **Stado**: Mejor para entornos empresariales con necesidades analíticas

### Factores de Selección:
1. **Volumen de Datos**
   - < 1TB: Soluciones tradicionales pueden ser suficientes
   - 1-10TB: Considerar Citus o PGGrid
   - > 10TB: Postgres-XL o Stado pueden ser necesarios

2. **Tipo de Workload**
   - OLTP puro: Citus o PGGrid
   - OLAP puro: Postgres-XL o Stado
   - Mixto: Citus es generalmente la mejor opción

3. **Requisitos de Consistencia**
   - Consistencia fuerte: Postgres-XL
   - Consistencia eventual: Cualquier opción
   - Transacciones distribuidas: Postgres-XL o Citus

4. **Presupuesto y Soporte**
   - Open Source: PGGrid o Postgres-XL
   - Empresarial con soporte: Citus o Stado
   - Mixto: Citus Community Edition


###################


# Topologías de Alta Disponibilidad y Clustering en PostgreSQL

## 1. Streaming Replication

### Topologías Soportadas
1. **Primary-Standby Simple**
   ```
   Primary → Standby
   ```
2. **Primary con Múltiples Standby**
   ```
   Primary → Standby 1
         ↘ Standby 2
         ↘ Standby N
   ```
3. **Replicación en Cascada**
   ```
   Primary → Standby 1 → Standby 2
                     ↘ Standby 3
   ```

## 2. Replicación Lógica

### Topologías Soportadas
1. **Publicación-Suscripción Simple**
   ```
   Publisher → Subscriber
   ```
2. **Multi-Suscriptor**
   ```
   Publisher → Subscriber 1
           ↘ Subscriber 2
           ↘ Subscriber N
   ```
3. **Cascada de Publicaciones**
   ```
   Pub/Sub 1 → Pub/Sub 2 → Pub/Sub 3
   ```

## 3. BDR (Bi-Directional Replication)

### Topologías Soportadas
1. **Malla Completa**
   ```
   Node 1 ⟷ Node 2
     ⟷ ⟷
   Node 3 ⟷ Node 4
   ```
2. **Anillo**
   ```
   Node 1 → Node 2 → Node 3 → Node 1
   ```
3. **Estrella**
   ```
       Node 2
         ↕
   Node 1 ↔ Node 3
         ↕
       Node 4
   ```

## 4. Patroni

### Topologías Soportadas
1. **Básica con DCS**
   ```
   DCS (etcd/Consul/ZooKeeper)
           ↕
   Leader ⟷ Replica 1
         ⟷ Replica 2
   ```
2. **Multi-DC con Witness**
   ```
   DC1: Leader + Replica
           ↕
   Witness Node
           ↕
   DC2: Standby Leader + Replica
   ```

## 5. Citus

### Topologías Soportadas
1. **Básica**
   ```
   Coordinator
        ↓
   Worker 1 Worker 2 Worker N
   ```
2. **Alta Disponibilidad**
   ```
   Coordinator + Standby
        ↓ ↓
   Worker 1 + Standby 1
   Worker 2 + Standby 2
   ```
3. **Multi-Coordinator**
   ```
   Coordinator 1 Coordinator 2
        ↓ ↓
   Worker Pool (Shared Workers)
   ```

## 6. Postgres-XL

### Topologías Soportadas
1. **Básica**
   ```
   GTM → Coordinator
         ↓
   Datanode 1 Datanode 2
   ```
2. **Multi-Coordinator**
   ```
   GTM → Coordinator 1
     ↘ Coordinator 2
         ↓ ↓
   Datanode Pool (Shared)
   ```

## 7. PgPool-II

### Topologías Soportadas
1. **Watchdog con Virtual IP**
   ```
   VIP
    ↓
   PgPool-II 1 ⟷ PgPool-II 2
       ↓ ↓
   Primary + Standby
   ```
2. **Multi-Backend**
   ```
   PgPool-II
       ↓
   Server 1 Server 2 Server N
   ```

## 8. Nuevas Soluciones

### Greenplum DB
- **Descripción**: Fork de PostgreSQL para data warehousing
- **Topología**:
  ```
  Master → Standby Master
     ↓
  Segment 1 → Mirror 1
  Segment 2 → Mirror 2
  Segment N → Mirror N
  ```
- **Ventajas**:
  - Procesamiento MPP
  - Escalabilidad masiva
  - Optimizado para OLAP
- **Desventajas**:
  - Complejidad operacional
  - Fork específico
  - Limitaciones OLTP

### EDB Postgres Distributed

- **Descripción**: Solución empresarial de EnterpriseDB
- **Topología**:
  ```
  Manager Node
       ↓
  Primary Cluster → Remote Cluster
  ```
- **Ventajas**:
  - Soporte empresarial
  - Herramientas integradas
  - Multi-master
- **Desventajas**:
  - Costo alto
  - Dependencia del proveedor
  - Complejidad

### Postgres-BDR Enterprise

- **Descripción**: Versión empresarial de BDR
- **Topología**:
  ```
  Node 1 ⟷ Node 2 ⟷ Node 3
    ⟷ ⟷ ⟷
  Node 4 ⟷ Node 5 ⟷ Node 6
  ```
- **Ventajas**:
  - Replicación multi-master
  - Soporte geográfico
  - Conflict resolution
- **Desventajas**:
  - Costo licenciamiento
  - Complejidad configuración
  - Overhead replicación

## Consideraciones Generales para Topologías

1. **Factor Geográfico**
   - Latencia entre nodos
   - Ancho de banda disponible
   - Requisitos legales por región

2. **Escalabilidad**
   - Vertical vs Horizontal
   - Límites de nodos por topología
   - Capacidad de crecimiento

3. **Alta Disponibilidad**
   - RPO (Recovery Point Objective)
   - RTO (Recovery Time Objective)
   - Automatización de failover

4. **Mantenimiento**
   - Facilidad de upgrades
   - Monitorización
   - Backup/Restore
 

 
-- Escenario: Pérdida de conexión entre Master y Standby por 10 minutos
-- Configuración típica en postgresql.conf del Master
wal_level = replica
max_wal_senders = 10
wal_keep_segments = 64 -- Retiene segmentos WAL (importante para reconexión)
archive_mode = on
archive_command = 'cp %p /archive/%f' -- Ejemplo de comando de archivado

-- En recovery.conf del Standby
primary_conninfo = 'host=master port=5432 user=replication password=xxx'
restore_command = 'cp /archive/%f %p' -- Comando para recuperar WAL archivados
recovery_target_timeline = 'latest'

-- Verificar estado de replicación en Master
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn 
FROM pg_stat_replication;

-- Verificar retraso de replicación
SELECT now() - pg_last_xact_replay_timestamp() AS replication_delay;

-- Script de monitoreo post-reconexión
SELECT 
    CASE WHEN pg_is_in_recovery() THEN 'STANDBY'
         ELSE 'MASTER' 
    END AS server_role,
    pg_current_wal_lsn() AS current_wal_position,
    pg_wal_lsn_diff(
        pg_current_wal_lsn(),
        pg_last_wal_replay_lsn()
    ) AS replication_lag_bytes;
</antArtifact>

Cuando ocurre una desconexión temporal entre el maestro y el standby, esto es lo que sucede:

1. Durante la desconexión (10 minutos):
   - El maestro continúa operando normalmente y generando WAL (Write-Ahead Logs)
   - Los WAL se acumulan en el directorio pg_wal del maestro
   - Si está configurado, los WAL también se guardan en el archivo WAL

2. En el servidor standby:
   - Detecta la pérdida de conexión
   - Entra en estado "desconectado" pero mantiene los datos sincronizados hasta el último WAL recibido
   - Espera la reconexión mientras mantiene su estado actual

3. Cuando se restablece la conexión:
   - El standby automáticamente intenta reconectarse al maestro
   - Identifica el último LSN (Log Sequence Number) que procesó
   - Solicita al maestro los WAL faltantes desde ese punto

4. Proceso de recuperación:
   - Si todos los WAL necesarios están disponibles en el maestro (en pg_wal o archivo):
     * La recuperación es automática
     * El standby comenzará a aplicar los WAL faltantes
     * Eventualmente alcanzará al maestro
   
   - Si faltan algunos WAL:
     * El standby intentará obtenerlos del archivo WAL si está configurado
     * Si no están disponibles, la recuperación fallará

Recomendaciones importantes:

1. Configuración preventiva:
   - Aumentar wal_keep_segments para retener más WAL
   - Implementar archivo WAL como respaldo
   - Monitorear el lag de replicación

2. Monitoreo post-reconexión:
   - Verificar el estado de replicación
   - Medir el retraso de replicación
   - Confirmar que los datos están sincronizados

3. Mejores prácticas:
   - Tener configurado archive_mode = on
   - Implementar monitoreo proactivo
   - Documentar procedimientos de recuperación


# Bibliografia 


https://youtu.be/kW8xT_cgEMM?si=K-ETKkKPuYXB8aSl
