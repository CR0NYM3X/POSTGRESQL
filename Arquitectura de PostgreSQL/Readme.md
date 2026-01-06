 


 
### **Extensiones para análisis interno y diagnóstico en PostgreSQL**

| **Tecnología**        | **Propósito**                                     | **Diferencias / Comentarios**                                                         |
| --------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [pageinspect](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pageinspect.md)      | Inspecciona el contenido físico de páginas        | Permite ver detalles internos de páginas (heap, índices, etc.).                       |
| [pg_visibility](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_visibility.md)       | Examina el mapa de visibilidad (VM) y páginas     | Permite ver qué páginas tienen tuples visibles/invisibles.                            |
| [pg_freespacemap](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_freespacemap.md)     | Examina el mapa de espacio libre (FSM)            | Complementa pg_visibility; muestra espacio libre por página.                        |
| [pg_buffercache](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_buffercache.md)      | Muestra el contenido actual del buffer cache      | Permite analizar qué bloques están en memoria y su uso.                               |
| pgfincore      | caché en la memoria del sistema operativo      | Permite analizar qué partes de las tablas y los índices están en caché en la memoria del sistema operativo, ayudando a optimizar el uso de la caché.                               |
| [pg_prewarm](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_prewarm.md)          | Precarga datos en el buffer cache                 | Útil para optimizar el rendimiento tras reinicios; complementa pg_buffercache.      |
| [pgstattuple](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pgstattuple.md)         | Muestra estadísticas de ocupación y fragmentación | Ideal para ver espacio ocupado y tuples muertas; menos detallado que pg_visibility. |
| [auto_explain](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/auto_explain.md)        | Registra automáticamente planes de ejecución      | Útil para diagnosticar consultas lentas; no analiza almacenamiento físico.            |
| [pg_stat_statements](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_stat_statements.md)  | Estadísticas de ejecución de consultas            | Muy usado para identificar consultas más costosas; no analiza almacenamiento.         |

 
### **Tabla, Vistas o Funciones para análisis interno y diagnóstico**

| **Tecnología** | **Propósito** | **Diferencias / Comentarios** |
| --- | --- | --- |
| **pg_stat_user_tables** | Muestra estadísticas generales de actividad por tabla (escaneos, inserts, updates). | No muestra visibilidad a nivel de página; más orientado a métricas de uso lógico. |
| **pg_stat_database** | Proporciona métricas agregadas por base de datos (commits, rollbacks, bloques leídos). | Ideal para detectar archivos temporales (`temp_bytes`) y conflictos de sesiones. |
| **pg_stat_wal** | Registra estadísticas sobre la generación de Write Ahead Logs (WAL). | **Crítica para tu caso:** Permite ver cuántos registros y bytes de WAL se generan y cuántos `fsync` se realizan. |
| **pg_stat_bgwriter** | Monitorea la actividad del Background Writer y del Checkpointer. | Ayuda a saber si los checkpoints se disparan por tiempo o por llenado de buffers (`checkpoints_req`). |
| **pg_stat_io** | Estadísticas detalladas de I/O por tipo de proceso, objeto y contexto. | **Nota:** Esta vista se introdujo en **Postgres 16**. En tu versión (15.14) aún no está disponible. |
| **pg_statio_user_tables** | Muestra estadísticas de entrada/salida (I/O) físicas de las tablas. | A diferencia de la vista lógica, esta te dice cuántos bloques se leyeron de disco vs. cuántos se leyeron de la RAM (caché). |
| **pg_control_checkpoint()** |  Muestra el estado exacto del último checkpoint en el archivo de control. |  Es una función. No es estadística acumulada; muestra el LSN y la línea de tiempo (timeline) actual. |
 



