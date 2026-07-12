 
## 🧩 herramientas para migración a PostgreSQL


[pgdiff COMPARA ESQUEMAS](https://github.com/joncrlsn/pgdiff)


### 1. **Estuary Flow** – *De pago (con opción gratuita limitada)*
- Migración en tiempo real con CDC (Change Data Capture).
- Compatible con múltiples entornos (AWS, GCP, Azure, Supabase).
- Entrega exacta una sola vez (exactly-once).
- Ideal para migraciones sin tiempo de inactividad y sincronización continua.
- Soporta Snowflake, BigQuery, Redshift, Databricks.

### 2. **AWS DMS (Database Migration Service)** – *De pago (modelo por uso)*
- Migración y replicación continua con CDC.
- Integración nativa con servicios AWS (Aurora, Redshift, RDS).
- Migraciones homogéneas y heterogéneas.
- Ideal para entornos AWS.

### 3. **pg_dump / pg_restore** – *Gratis*
- Herramientas nativas de PostgreSQL.
- Migraciones pequeñas o actualizaciones de versión.
- Requiere tiempo de inactividad.
- No apto para migraciones en tiempo real.

### 4. **Fivetran** – *De pago (modelo por filas activas mensuales)*
- ELT automatizado con conectores preconfigurados.
- Migración por lotes, no en tiempo real.
- Ideal para pipelines de análisis.

### 5. **dbForge Studio for PostgreSQL** – *De pago*
- Herramienta GUI para migración y gestión.
- Comparación de esquemas y datos.
- Ideal para desarrolladores y DBAs.

### 6. **EDB Migration Toolkit** – *Gratis (requiere EDB Postgres)*
- Migración desde Oracle, SQL Server, MySQL.
- Migración de esquemas y datos.
- Enfocado en entornos empresariales.

### 7. **pg_chameleon** – *Gratis*
- Migración y replicación en tiempo real desde MySQL a PostgreSQL.
- Soporte para múltiples esquemas.
- Limitado a MySQL como fuente.

### 8. **Matillion** – *De pago*
- Migración como parte de transformación de datos.
- Arquitectura nativa en la nube.
- Ideal para empresas que modernizan su infraestructura de datos.

### 9. **Ora2Pg** – *Gratis*
- Migración desde Oracle a PostgreSQL.
- Conversión de PL/SQL a PL/pgSQL.
- Informes de validación y estimación de costos.

### 10. **pgLoader** – *Gratis*
- Migración declarativa desde MySQL, SQLite, CSV.
- Limpieza automática de datos.
- Alto rendimiento con paralelización.

### 11. **Flyway** – *Gratis y de pago (edición empresarial)*
- Migración como código (DevOps).
- Control de versiones y scripts repetibles.
- Ideal para cambios incrementales.

### 12. **Liquibase** – *Gratis y de pago (edición empresarial)*
- Migración basada en registros de cambios.
- Compatible con múltiples bases de datos.
- Ideal para equipos grandes y entornos distribuidos.

### 13. **Striim** – *De pago*
- Migración en tiempo real con latencia <1s.
- Transformación de datos en vuelo.
- Ideal para sincronización continua y baja latencia.

### 14. **FDW (Foreign Data Wrappers)** – *Gratis*
- Acceso en tiempo real a fuentes externas.
- Migración incremental.
- Integración nativa con PostgreSQL.

### 15. **Informatica PowerCenter** – *De pago*
- Migración empresarial con transformación avanzada.
- Gestión de calidad de datos y metadatos.
- Ideal para entornos heterogéneos y cumplimiento normativo.

### 16. **CloudQuery** – *Gratis*
- Migración desde servicios en la nube y SaaS.
- Generación automática de esquemas.
- Ideal para sincronización en tiempo real desde APIs.

### 17. **HVR** – *De pago*
- Replicación en tiempo real con CDC.
- Validación y reparación de datos.
- Ideal para arquitecturas distribuidas.

### 18. **Yugabyte** – *Gratis*
- Migración en entornos distribuidos.
- Alta disponibilidad y replicación entre clústeres.
- Ideal para arquitecturas geodistribuidas.

### 19. **Debezium** – *Gratis*
- CDC en tiempo real con Kafka.
- Arquitectura basada en eventos.
- Ideal para microservicios y sincronización continua.

### 20. **Stitch** – *De pago (desde \$100/mes)*
- Migración sin código.
- Escalabilidad automática.
- Ideal para analistas y equipos sin experiencia técnica.

### 21. **SQLWays (Ispirer)** – *De pago (con prueba gratuita)*
- Migración desde múltiples fuentes.
- Conversión automática de esquemas y procedimientos.
- Ideal para proyectos complejos.

### 22. **InsightWays (Ispirer)** – *Gratis*
- Evaluación previa a la migración.
- Reportes detallados de complejidad y costos.
- Ideal para planificación estratégica.

### 23. **Airbyte** – *Gratis (con opción de pago empresarial)*
- Más de 350 conectores.
- CDC y replicación en tiempo real.
- Ideal para consolidación de datos y migraciones flexibles.

### 24. **Aiven-db-migrate** – *Gratis*
- Migración con replicación lógica.
- CLI y métricas integradas.
- Ideal para entornos con Aiven.

---

## 📊 Cuadro comparativo (ordenado de mejor a peor según la comunidad)

| 🏆 Herramienta         | Tipo de Migración       | En Tiempo Real | Gratuita | Ideal Para                                                  | Limitaciones                          |
|------------------------|--------------------------|----------------|----------|-------------------------------------------------------------|---------------------------------------|
| **Estuary Flow**       | CDC en tiempo real        | ✅             | ❌ (prueba) | Migraciones sin downtime, replicación cruzada               | Comercial, complejo para proyectos pequeños |
| **Airbyte**            | CDC + conectores          | ✅             | ✅ (limitado) | Consolidación de datos, replicación                         | Requiere configuración avanzada       |
| **pgLoader**           | Declarativa               | ✅             | ✅        | Migraciones rápidas desde múltiples fuentes                 | Manejo de errores por lotes           |
| **Ora2Pg**             | Oracle → PostgreSQL       | ❌             | ✅        | Migraciones desde Oracle                                    | No soporta otras fuentes              |
| **AWS DMS**            | CDC en la nube            | ✅             | ❌        | Migraciones dentro de AWS                                   | Costoso y complejo                    |
| **Debezium**           | CDC + Kafka               | ✅             | ✅        | Arquitecturas basadas en eventos                            | Requiere Kafka                        |
| **pg_chameleon**       | MySQL → PostgreSQL        | ✅             | ✅        | Migraciones desde MySQL                                     | No soporta otras fuentes              |
| **SQLWays**            | Multifuente empresarial   | ❌             | ❌ (prueba) | Migraciones complejas                                       | Comercial                             |
| **Fivetran**           | ELT por lotes             | ❌             | ❌        | Pipelines analíticos                                        | Costoso a gran escala                 |
| **Stitch**             | ELT por lotes             | ❌             | ❌        | Migraciones sin código                                      | Costoso, no en tiempo real            |
| **dbForge Studio**     | GUI                       | ❌             | ❌        | Migraciones visuales pequeñas                               | Manual, no escalable                  |
| **EDB Toolkit**        | CLI empresarial           | ❌             | ✅        | Migraciones desde Oracle, SQL Server                        | Requiere EDB Postgres                 |
| **Flyway**             | DevOps / CI/CD            | ❌             | ✅        | Cambios incrementales                                       | No apto para migraciones masivas      |
| **Liquibase**          | DevOps / CI/CD            | ❌             | ✅        | Equipos grandes, múltiples entornos                         | Requiere configuración avanzada       |
| **Striim**             | CDC en tiempo real        | ✅             | ❌        | Migraciones con baja latencia                               | Comercial                             |
| **CloudQuery**         | SaaS → PostgreSQL         | ✅             | ✅        | Migraciones desde APIs y servicios cloud                    | Limitado a fuentes SaaS               |
| **Yugabyte**           | Distribuida               | ✅             | ✅        | Migraciones geodistribuidas                                 | Requiere arquitectura distribuida     |
| **HVR**                | CDC empresarial           | ✅             | ❌        | Replicación continua de alto volumen                        | Comercial                             |
| **Informatica**        | Empresarial               | ❌             | ❌        | Migraciones con transformación compleja                     | Costoso y complejo                    |
| **Matillion**          | Transformación + migración| ❌             | ❌        | Modernización de infraestructura                            | Comercial                             |
| **FDW PostgreSQL**     | Acceso externo            | ❌             | ✅        | Migraciones híbridas e incrementales                        | No es una herramienta de migración tradicional |
| **pg_dump / restore**  | Nativo                    | ❌             | ✅        | Migraciones pequeñas y backups                              | Requiere downtime                     |
| **InsightWays**        | Evaluación previa         | ❌             | ✅        | Planificación de migraciones                                | No realiza migraciones                |
| **Aiven-db-migrate**   | Replicación lógica        | ✅             | ✅        | Migraciones con Aiven                                       | Limitado a su ecosistema              |
| **SharePlex**          | Replicación Oracle        | ✅             | ❌        | Migraciones empresariales, alta disponibilidad              | Licencia de pago, solo algunos motores |
| **AWS SCT**            | Conversión de esquemas    | ❌             | ✅        | Migraciones heterogéneas (Oracle → PostgreSQL, etc.)        | No migra datos, solo esquemas         |
| **DBConvert**          | Migración y sincronización| ❌             | ❌ (prueba) | Migraciones entre múltiples motores                         | Limitado en versión gratuita          |


 ### 🏆 Herramientas ETL para ejecutar queries en múltiples motores y consolidar datos

| Herramienta ETL         | Motores soportados | Programación de tareas | ¿Es de paga? | Características clave | Enlace |
|-------------------------|--------------------|-------------------------|--------------|------------------------|--------|
| **Talend Open Studio**  | Oracle, MySQL, PostgreSQL, SQL Server, etc. | Sí (cron, scheduler interno) | **Gratis (Open Source)** | Código abierto, gran comunidad, conectores múltiples | [Talend](https://www.datacamp.com/es/blog/a-list-of-the-16-best-etl-tools-and-why-to-choose-them) |
| **Integrate.io**        | MongoDB, MySQL, PostgreSQL, Redshift, etc. | Sí (basado en nube) | **De paga** | Interfaz visual, seguridad avanzada, integración SaaS | [Integrate.io](https://www.unite.ai/es/best-etl-tools/) |
| **Apache Nifi**         | Casi cualquier fuente | Sí (basado en flujo) | **Gratis (Open Source)** | Flujo visual, muy flexible, ideal para entornos mixtos | [Apache Nifi](https://clickup.com/es-ES/blog/137401/herramientas-etl) |
| **Pentaho Data Integration (Kettle)** | Oracle, SQL Server, PostgreSQL, etc. | Sí | **Gratis con opción de pago** | Interfaz gráfica, transformaciones complejas, comunidad activa | [Pentaho](https://opensistemas.com/herramientas-etl-mas-usadas/) |
| **Astera Centerprise**  | Bases de datos, archivos planos, API | Sí | **De paga** | Sin código, IA integrada, monitoreo, calidad de datos | [Astera](https://www.astera.com/es/knowledge-center/what-is-etl-tool/) |
| **Hevo Data**           | PostgreSQL, MySQL, Redshift, BigQuery, etc. | Sí | **De paga con prueba gratuita** | ETL casi en tiempo real, transformaciones con Python | [Hevo](https://www.astera.com/es/knowledge-center/what-is-etl-tool/) |

# Links
```

peerdb -> https://clickhouse.com/blog/practical-postgres-migrations-at-scale-peerdb

15 Best Postgres Database Migration Tools in 2025 -> https://www.matillion.com/learn/blog/postgres-database-migration-platforms
7 Best Postgres Migration Tools in 2025 for Reliable Database Transfers -> https://estuary.dev/blog/postgres-migration-tools/
7 Best PostgreSQL Database Migration Tools in 2025 -> https://www.ispirer.com/postgresql-database-migration-tools
Best 6 Postgres Database Migration Tools For 2025 -> https://airbyte.com/top-etl-tools-for-sources/postgres-migration-tool


--- Páginas que ayudan en migración -------

https://pgfeaturediff.com/?from=17&to=18
https://www.postgresql.org/about/featurematrix/
https://why-upgrade.depesz.com/show?from=18&to=18.1&keywords=cve

https://github.com/djrobstep/results
https://www.postgrescompare.com/



```





