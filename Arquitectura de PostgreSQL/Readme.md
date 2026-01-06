 


 
### **Extensiones para análisis interno y diagnóstico en PostgreSQL**

| **Tecnología**        | **Propósito**                                     | **Diferencias / Comentarios**                                                         |
| --------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [pageinspect](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pageinspect.md)      | Inspecciona el contenido físico de páginas        | Permite ver detalles internos de páginas (heap, índices, etc.).                       |
| [pg_visibility](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_visibility.md)       | Examina el mapa de visibilidad (VM) y páginas     | Permite ver qué páginas tienen tuples visibles/invisibles.                            |
| [pg_freespacemap](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_freespacemap.md)     | Examina el mapa de espacio libre (FSM)            | Complementa pg_visibility; muestra espacio libre por página.                        |
| [pg_buffercache](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_buffercache.md)      | Muestra el contenido actual del buffer cache      | Permite analizar qué bloques están en memoria y su uso.                               |
| [pg_prewarm](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_prewarm.md)          | Precarga datos en el buffer cache                 | Útil para optimizar el rendimiento tras reinicios; complementa pg_buffercache.      |
| [pgstattuple](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pgstattuple.md)         | Muestra estadísticas de ocupación y fragmentación | Ideal para ver espacio ocupado y tuples muertas; menos detallado que pg_visibility. |
| [auto_explain](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/auto_explain.md)        | Registra automáticamente planes de ejecución      | Útil para diagnosticar consultas lentas; no analiza almacenamiento físico.            |
| [pg_stat_statements](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_stat_statements.md)  | Estadísticas de ejecución de consultas            | Muy usado para identificar consultas más costosas; no analiza almacenamiento.         |


### **Vistas para analisis interno y diagnóstico**

| **Tecnología**        | **Propósito**                                     | **Diferencias / Comentarios**                                                         |
| --------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------- |
| pg_stat_user_tables | Esta es una Vista que muestra Estadísticas generales por tabla                  | No muestra visibilidad a nivel de página; más orientado a métricas globales.          |

 





