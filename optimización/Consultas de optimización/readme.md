Aquí tienes la tabla actualizada con las dos entradas agregadas y organizadas en formato Markdown.

A diferencia del resto de elementos de la lista, **Cache Hit Ratio** es una consulta/métrica de optimización en lugar de una extensión, por lo que queda claramente diferenciada en la descripción.

---

## 🛠️ Extensiones y Herramientas para Análisis Interno y Diagnóstico en PostgreSQL

* 📄 **[Documentación Principal: Extensiones para Análisis Interno y Diagnóstico](https://github.com/CR0NYM3X/POSTGRESQL/blob/6ea6d24c132757bea70dea761fd51290d812b52d/Arquitectura%20de%20PostgreSQL/Extensiones%20para%20an%C3%A1lisis%20interno%20y%20diagn%C3%B3stico%20en%20PostgreSQL.md)**

### 🔌 Lista de Extensiones y Consultas de Optimización

| Extensión / Métrica | Descripción Rápida | Enlace a Documentación |
| --- | --- | --- |
| **`pg_buffercache`** | Inspecciona en tiempo real la memoria compartida (`shared_buffers`). | [Ver Guía](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_buffercache.md) |
| **`pg_prewarm`** | Carga datos de tablas/índices a la RAM proactivamente. | [Ver Guía](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_prewarm.md) |
| **`auto_explain`** | Registra automáticamente los planes de ejecución de consultas lentas. | [Ver Guía](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/auto_explain.md) |
| **`pgstattuple`** | Analiza el espacio desperdiciado (bloat) e hinchazón de tuplas. | [Ver Guía](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pgstattuple.md) |
| **`pageinspect`** | Inspecciona el contenido a bajo nivel (a nivel de byte) de las páginas de disco. | [Ver Guía](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pageinspect.md) |
| **`pg_freespacemap`** | Examina el mapa de espacio libre (FSM) de las relaciones. | [Ver Guía](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_freespacemap.md) |
| **`pg_visibility`** | Examina el mapa de visibilidad (VM) y el estado de VACUUM. | [Ver Guía](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/Extensiones/pg_visibility.md) |
| **`pg_hint_plan`** | Permite forzar o sugerir planes de ejecución específicos mediante comentarios SQL (*hints*). | [Ver Guía]() |
| **Cache Hit Ratio** | Consulta para medir la tasa de efectividad y aciertos del uso de memoria RAM vs. disco. | [Ver Guía](https://github.com/CR0NYM3X/POSTGRESQL/blob/main/optimizaci%C3%B3n/Consultas%20de%20optimizaci%C3%B3n/Cache%20Hit%20Ratio.md) |

---


-----------------
Disco. 
CPU.
Memoria.



Tamaño de base de datos.
Tamaño de tablas.

Ver bloat


Detectar tablas que no tienen index
Index que no se usan
Detectar index duplicados
Detectar index que faltan/ columna sin index
Detectar index basura
Detectar index compuestos
         *** Estos solo son útiles solo si la consulta utiliza las columnas que agregaste al index compuestos que son más de una columna 
Índices GIN y GiST
Índices Bloat (Fragmentados)

¿Qué es un Page Split? 


SELECT
  checkpoint_sync_time / NULLIF(checkpoints_timed + checkpoints_req, 0) AS avg_sync_time_per_checkpoint
FROM pg_stat_bgwriter;


https://github.com/CR0NYM3X/POSTGRESQL/blob/6ea6d24c132757bea70dea761fd51290d812b52d/monitoreo/Monitoreo%2C%20optimizaci%C3%B3n%20y%20mantenimientos.md


https://github.com/CR0NYM3X/POSTGRESQL/blob/284c2f3de0d7c3d38847cf59ec6c287c14419f1d/Memorias%20de%20postgresql.md



postgres@centraldata# select table_schema,table_name from information_schema.tables where table_name ilike '%io\_%' and table_schema in('information_schema','pg_catalog');
+--------------+--------------------------+
| table_schema |        table_name        |
+--------------+--------------------------+
| pg_catalog   | pg_statio_user_tables    |
| pg_catalog   | pg_statio_all_sequences  |
| pg_catalog   | pg_statio_sys_sequences  |
| pg_catalog   | pg_statio_user_sequences |
| pg_catalog   | pg_statio_sys_indexes    |
| pg_catalog   | pg_statio_user_indexes   |
| pg_catalog   | pg_statio_all_indexes    |
| pg_catalog   | pg_statio_all_tables     |
| pg_catalog   | pg_statio_sys_tables     |
+--------------+--------------------------+




