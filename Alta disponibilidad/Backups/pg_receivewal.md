
**pg_receivewal** – Herramienta de PostgreSQL para la captura en tiempo real de registros WAL. Permite:  
- **Streaming de WAL** desde un servidor PostgreSQL activo.  
- **Almacenamiento local de WAL** para recuperación Point-in-Time Recovery (**PITR**).  
- **Evita la espera de segmentos completos**, mejorando la eficiencia.  
- **Uso en entornos de alta disponibilidad** para mantener réplicas actualizadas.  
- **Compatibilidad con replication slots** para evitar pérdida de datos.  

Más detalles en la [documentación oficial](https://www.postgresql.org/docs/current/app-pgreceivewal.html).

**pg_rewind** – Herramienta para sincronizar servidores PostgreSQL después de una divergencia. Permite:  
- **Restauración rápida de un nodo primario degradado** sin necesidad de un respaldo completo.  
- **Sincronización de datos entre servidores** tras un failover.  
- **Uso eficiente de WAL** para identificar y aplicar cambios mínimos.  
- **Reducción del tiempo de recuperación** en entornos de alta disponibilidad.  
- **Evita la necesidad de reconstrucción completa del clúster**.  

