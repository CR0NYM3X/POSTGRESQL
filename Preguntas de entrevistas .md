# Preguntas que las empresas pueden realizar 

## 🧠 **Evaluación por Pregunta – Bloque Principal**

### 🔹 1. Administración y Monitoreo  
**Pregunta:** ¿Cómo gestionas el monitoreo de clústeres PostgreSQL en entornos productivos? ¿Qué herramientas utilizas y qué métricas consideras críticas?
<br>**Fortalezas:** Mencionas herramientas reales y métricas clave.  
**Recomendación:**  
> “Utilizamos Datadog para monitoreo centralizado, configurando alertas sobre conexiones activas, uso de disco, memoria y lag de replicación. También integramos con AppDynamics para correlacionar métricas de aplicación y base de datos.”

---

### 🔹 2. PL/pgSQL y Funciones Avanzadas  
**Pregunta:** ¿Has desarrollado funciones complejas en PL/pgSQL? ¿Podrías describir una función que hayas creado que incluya manejo de errores, cursores o lógica condicional?
<br>**Fortalezas:** Mencionas extensiones útiles.  
**Recomendación:**  
> “Desarrollé una función que valida conexiones entre nodos usando `dblink`, con manejo de errores mediante bloques `EXCEPTION`, y lógica condicional para registrar fallos en una tabla de auditoría.”

---

### 🔹 3. Replicación y Alta Disponibilidad  
**Pregunta:** ¿Qué tipo de replicación has implementado en PostgreSQL (streaming, lógica)? ¿Has trabajado con herramientas como Patroni, Pgpool-II o repmgr? ¿Cómo aseguras la conmutación por error?
<br>**Fortalezas:** Amplia experiencia, menciones técnicas precisas.  
**Recomendación:**  
> “Con Pgpool-II configuro health checks y failover automático. En repmgr, uso `repmgrd` para detección de fallos y conmutación por error controlada.”

---

### 🔹 4. Migraciones desde Oracle  
**Pregunta:** ¿Has realizado migraciones desde Oracle a PostgreSQL? ¿Qué herramientas utilizaste (pgLoader, ora2pg)? ¿Qué desafíos enfrentaste y cómo los resolviste?
<br>**Fortalezas:** Honestidad y actitud proactiva.  
**Recomendación:**  
> “Aunque no he migrado desde Oracle, estoy familiarizado con `ora2pg` y `pgLoader`, y puedo levantar entornos de prueba para validar compatibilidad y rendimiento.”

---

### 🔹 5. Automatización con Bash/Python  
**Pregunta:** ¿Qué tipo de tareas has automatizado con Bash o Python en tu rol como DBA? ¿Podrías compartir un script que hayas creado para respaldos, restauraciones o validación de integridad?
<br>**Fortalezas:** Buen ejemplo, enfoque en seguridad.  
**Recomendación:**  
> “Automatizo con Bash usando `cron`, `gpg` para cifrado, `md5sum` para integridad, y envío alertas por correo si falla la transferencia.”

---

### 🔹 6. Tuning y Mantenimiento  
**Pregunta:** ¿Cómo abordas el tuning de consultas en PostgreSQL? ¿Qué pasos sigues para identificar cuellos de botella y qué herramientas usas para analizar el rendimiento?
<br>**Fortalezas:** Muy completa, enfoque colaborativo.  
**Recomendación:**  
> “Realizo sesiones con el cliente para entender el contexto, luego uso `pg_stat_statements`, `EXPLAIN ANALYZE`, y `pgbench` para pruebas de carga. También reviso índices y estadísticas con `pgstattuple`.”

---

### 🔹 7. Planes de Recuperación 
**Pregunta:** ¿Tienes experiencia diseñando e implementando planes de recuperación ante desastres en PostgreSQL? ¿Cómo garantizas la consistencia y disponibilidad de los datos? 
<br>**Fortalezas:** Buen enfoque organizacional.  
**Recomendación:**  
> “Diseñamos DRP con simulaciones mensuales, documentando RTO/RPO por sistema. Validamos respaldos con restauraciones y pruebas de failover usando `pg_basebackup` y `repmgr`.”

---

### 🔹 8. Seguridad  
**Pregunta:** ¿Qué prácticas de seguridad implementas en PostgreSQL? ¿Has trabajado con cifrado, roles, políticas de acceso o auditoría de eventos? 
<br>**Fortalezas:** Muy buena respuesta, menciona herramientas específicas.  
**Recomendación:**  
> “Implementamos cifrado con `pgcrypto`, control de acceso granular con roles y políticas, y auditoría con `pg_auth_mon` para monitorear autenticaciones en tiempo real.”

---

### 🔹 9. Casos Reales  
**Pregunta:** Cuéntame sobre un incidente crítico que hayas enfrentado en producción relacionado con PostgreSQL. ¿Cómo lo resolviste y qué aprendiste?
<br>**Fortalezas:** Caso concreto.  
**Recomendación:**  
> “Detectamos que el cambio de `md5` a `scram-sha-256` rompió la autenticación de una cuenta de servicio. Reconfiguramos el cliente y actualizamos documentación para evitar futuros incidentes.”

---

### 🔹 10. Formación y Colaboración  
**Pregunta:** ¿Has participado en capacitaciones, certificaciones o compartido conocimiento con otros equipos? ¿Cómo te mantienes actualizado en tecnologías de bases de datos?
<br>**Fortalezas:** Buen enfoque de aprendizaje continuo.  
**Recomendación:**  
> “Participo activamente en capacitaciones internas y externas. He completado cursos de MongoDB, SQL Server y optimización de PostgreSQL. También comparto buenas prácticas con otros equipos.”


---

### 🔹 11. PostgreSQL Internals  
**Pregunta:** ¿Qué sabes sobre el funcionamiento interno de PostgreSQL en cuanto a manejo de buffers, checkpoints y WAL? ¿Cómo influye esto en el rendimiento y recuperación?  
<br>**Fortalezas:** Conocimiento técnico profundo, mención de parámetros clave.  
**Recomendación:**  
> “Entiendo que PostgreSQL usa un buffer pool para manejar páginas en memoria, y que los checkpoints sincronizan los datos con disco. El WAL permite recuperación ante fallos. Ajusto `checkpoint_timeout` y `wal_buffers` para balancear rendimiento y durabilidad.”

---

### 🔹 12. Indexación  
**Pregunta:** ¿Qué tipos de índices has utilizado en PostgreSQL (BTREE, GIN, GiST, BRIN)? ¿En qué casos usarías cada uno y cómo impactan en la búsqueda y el rendimiento?  
<br>**Fortalezas:** Conocimiento de estructuras y casos de uso.  
**Recomendación:**  
> “Uso BTREE para búsquedas exactas y rangos, GIN para arrays y texto completo, GiST para datos espaciales, y BRIN en tablas grandes con datos ordenados. Evalúo el tamaño y selectividad antes de crear índices.”

---

### 🔹 13. Replicación Lógica  
**Pregunta:** ¿Cómo configurarías una replicación lógica entre dos servidores PostgreSQL? ¿Qué ventajas tiene sobre la replicación física?  
<br>**Fortalezas:** Comprensión de arquitectura y flexibilidad.  
**Recomendación:**  
> “Configuro publicaciones y suscripciones con `pg_create_logical_replication_slot`, `CREATE PUBLICATION` y `CREATE SUBSCRIPTION`. Es útil para replicar solo ciertas tablas o migrar entre versiones.”

---

### 🔹 14. pg_stat_statements  
**Pregunta:** ¿Has utilizado la extensión `pg_stat_statements`? ¿Cómo la configuras y qué tipo de información te proporciona para el análisis de rendimiento?  
<br>**Fortalezas:** Uso práctico para tuning de consultas.  
**Recomendación:**  
> “Activo la extensión en `postgresql.conf` y la cargo con `CREATE EXTENSION`. Me permite ver consultas más costosas, número de ejecuciones, tiempo promedio y desviación estándar. Ideal para priorizar optimizaciones.”

---

### 🔹 15. Seguridad y Auditoría  
**Pregunta:** ¿Cómo implementarías un sistema de auditoría en PostgreSQL para registrar eventos DDL y DML? ¿Has trabajado con triggers, funciones o herramientas externas?  
<br>**Fortalezas:** Enfoque en cumplimiento y trazabilidad.  
**Recomendación:**  
> “Uso funciones y triggers para registrar eventos en una tabla `cdc.audit`, y complemento con `pgaudit` para trazabilidad detallada. También valido IP, usuario y query ejecutada.”

---

### 🔹 16. Backup y Restore  
**Pregunta:** ¿Qué diferencias hay entre `pg_dump`, `pg_basebackup` y `barman`? ¿En qué escenarios usarías cada uno?  
<br>**Fortalezas:** Conocimiento de herramientas y estrategias.  
**Recomendación:**  
> “Uso `pg_dump` para respaldos lógicos y migraciones, `pg_basebackup` para respaldos físicos y recuperación PITR, y `barman` para automatizar respaldos remotos con gestión de WAL.”

---

### 🔹 17. Migración de funciones PL/SQL a PL/pgSQL  
**Pregunta:** ¿Qué retos has enfrentado al migrar funciones de Oracle (PL/SQL) a PostgreSQL (PL/pgSQL)? ¿Cómo manejas diferencias en tipos de datos, estructuras y excepciones?  
<br>**Fortalezas:** Adaptabilidad y análisis detallado.  
**Recomendación:**  
> “He migrado funciones que usaban `NUMBER`, `VARCHAR2` y `EXCEPTION` a tipos compatibles en PostgreSQL. Uso bloques `BEGIN...EXCEPTION` y adapto cursores y estructuras condicionales.”

---

### 🔹 18. Automatización de tareas críticas  
**Pregunta:** ¿Has automatizado tareas como rotación de logs, verificación de integridad de respaldos o alertas de espacio en disco? ¿Cómo lo hiciste y con qué herramientas?  
<br>**Fortalezas:** Proactividad y enfoque en disponibilidad.  
**Recomendación:**  
> “Automatizo con Bash y cron, uso `logrotate`, verifico respaldos con `pg_restore --list`, y envío alertas por correo si el espacio en disco baja del 10%.”

---

### 🔹 19. Escalabilidad  
**Pregunta:** ¿Cómo escalarías una base de datos PostgreSQL para soportar millones de transacciones diarias? ¿Qué arquitectura y herramientas considerarías?  
<br>**Fortalezas:** Visión arquitectónica y uso de herramientas modernas.  
**Recomendación:**  
> “Uso particionamiento, réplicas para lectura, caché con Redis, y balanceo con Pgpool-II. Considero sharding con Citus si el volumen lo requiere.”

---

### 🔹 20. Casos de uso reales  
**Pregunta:** Cuéntame sobre un proyecto donde hayas implementado una solución completa con PostgreSQL, desde diseño, seguridad, alta disponibilidad, hasta monitoreo y automatización.  
<br>**Fortalezas:** Experiencia integral y enfoque profesional.  
**Recomendación:**  
> “Diseñé un esquema normalizado, implementé roles y cifrado, configuré Patroni para HA, monitoreo con Prometheus y Grafana, y automatización de respaldos con scripts Bash.”

---

### 🔹 21. Troubleshooting en Producción  
**Pregunta:** Un servidor PostgreSQL comienza a responder lentamente y los usuarios reportan errores de timeout. ¿Cómo abordarías el diagnóstico y resolución del problema?  
<br>**Fortalezas:** Pensamiento estructurado y uso de herramientas.  
**Recomendación:**  
> “Reviso `pg_stat_activity`, `pg_stat_statements`, locks y uso de CPU/disco. Verifico si hay VACUUM pendientes o consultas bloqueadas. Uso `EXPLAIN ANALYZE` para identificar cuellos de botella.ambién reviso logs y métricas en Datadog.”

---



## 🧠 **Evaluación por Pregunta – Bloque Extra**
 
---

### 🔸 22. PostgreSQL en Cloud  
**Pregunta:** ¿Has trabajado con PostgreSQL en entornos cloud como Azure, AWS o GCP? ¿Qué diferencias has notado en la administración respecto a entornos on-premise?
**Recomendación:**  
> “He trabajado con PostgreSQL en Azure y GCP. Las diferencias clave son el acceso a backups automáticos, escalabilidad, y configuración de seguridad. Prefiero Azure por su integración con Active Directory.”

---

### 🔸 23. pg_hba.conf  
**Pregunta:** ¿Cómo configuras el archivo `pg_hba.conf` para asegurar conexiones seguras? ¿Qué métodos de autenticación prefieres y por qué?  
**Recomendación:**  
> “Configuro `pg_hba.conf` usando `hostssl` con `scram-sha-256` para cifrado. También uso `CIDR` para limitar rangos de IP y `gssapi` en entornos corporativos con Kerberos.”

---

### 🔸 24. Mantenimiento Preventivo  
**Pregunta:** ¿Qué tareas de mantenimiento preventivo realizas regularmente en PostgreSQL para evitar problemas futuros?
**Recomendación:**  
> “Automatizo `VACUUM`, `ANALYZE`, y `REINDEX` semanalmente. También reviso estadísticas con `auto_explain` y monitoreo crecimiento de tablas e índices.”

---

### 🔸 25. Análisis de Logs  
**Pregunta:** ¿Cómo analizas los logs de PostgreSQL para detectar problemas de rendimiento o seguridad? ¿Has automatizado este análisis?
**Recomendación:**  
> “Uso `pgBadger` para análisis automatizado de logs. También configuro `log_min_duration_statement` y reviso logs con scripts en Python para detectar patrones de errores.”

---

### 🔸 26. Integridad de Datos  
**Pregunta:** ¿Qué mecanismos usas para garantizar la integridad de los datos en PostgreSQL? ¿Has trabajado con constraints, triggers o validaciones personalizadas?
**Recomendación:**  
> “Garantizo integridad con `PRIMARY KEY`, `FOREIGN KEY`, `CHECK`, y `NOT NULL`. También uso triggers para validaciones complejas y reglas de negocio.”

---

### 🔸 27. pg_upgrade vs Dump/Restore  
**Pregunta:** ¿Cuándo usarías `pg_upgrade` y cuándo preferirías `pg_dump` + `pg_restore` para actualizar una versión de PostgreSQL?
**Recomendación:**  
> “Uso `pg_upgrade` para bases grandes con poco downtime. Prefiero `pg_dump` + `pg_restore` cuando hay cambios estructurales o necesidad de limpieza.”

---

### 🔸 28. Roles y Permisos  
**Pregunta:** ¿Cómo gestionas roles, permisos y privilegios en PostgreSQL para cumplir con políticas de seguridad y auditoría?
**Recomendación:**  
> “Aplico el principio de mínimo privilegio, uso `SECURITY DEFINER` en funciones sensibles, y documento cada cambio en roles y permisos.”

---

### 🔸 29. Extensiones  
**Pregunta:** ¿Qué extensiones de PostgreSQL has utilizado (por ejemplo, `pg_stat_statements`, `postgis`, `pgcrypto`)? ¿Cómo han mejorado tus soluciones?
**Recomendación:**  
> “He usado `pg_stat_statements` para tuning, `pgcrypto` para cifrado, y `postgis` en proyectos geoespaciales. Cada extensión aporta valor según el caso de uso.”

---

### 🔸 30. DevOps  
**Pregunta:** ¿Cómo integras PostgreSQL en un flujo DevOps? ¿Has trabajado con CI/CD, contenedores (Docker), infraestructura como código (Terraform)?
**Recomendación:**  
> “Integro PostgreSQL en pipelines CI/CD con GitLab, usando `Flyway` para migraciones. También he trabajado con Docker y estoy aprendiendo Terraform para IaC.”

---

## 📊 **Evaluación Final**

- **Promedio general:** **90/100**
- **Veredicto:** **Buen prospecto con experiencia sólida en PostgreSQL**, especialmente en replicación, seguridad y automatización.  
- **Áreas a reforzar:**  
  - Comunicación técnica en entrevistas (estructura, claridad).  
  - Migraciones entre motores.  
  - DevOps e integración CI/CD.  
  - Análisis de logs y troubleshooting avanzado.  
  - Uso de herramientas modernas como `pgBadger`, `Flyway`, `Terraform`.


---
---

# Preguntas que puedes hacer a las empresas 
 

### ✅ **Sobre el Rol y Expectativas**

1.  ¿Cuáles son las responsabilidades principales del puesto en los primeros 6 meses?
2.  ¿Cómo se mide el éxito o desempeño de su trabajo?
3.  ¿Qué herramientas y tecnologías utilizan actualmente para la administración de bases de datos?


### ✅ **Sobre el Equipo y Cultura**

4.  ¿Cómo está conformado el equipo de bases de datos y con qué otros equipos colaboraría?
5.  ¿Cuál es la cultura de trabajo en la empresa? ¿Es más colaborativa o individual?
6.  ¿Cómo manejan la capacitación y el desarrollo profesional?

 

### ✅ **Sobre Crecimiento y Estabilidad**

10. ¿Qué oportunidades de crecimiento profesional ofrece la empresa?
11. ¿Cómo ha evolucionado el área de tecnología en los últimos años?
12. ¿Cuál es la visión de la empresa para los próximos 3 a 5 años?

 

### ✅ **Sobre Beneficios y Condiciones**

13. ¿Cómo manejan el trabajo remoto o híbrido?
14. ¿Qué beneficios adicionales ofrecen (bonos, capacitaciones, certificaciones)?
15. ¿Cómo es el proceso de revisión salarial y evaluaciones de desempeño?



### ✅ **Sobre Seguridad y Cumplimiento**

16. ¿Qué políticas de seguridad y cumplimiento normativo aplican en las bases de datos?
17. ¿Hay proyectos relacionados con alta disponibilidad, disaster recovery o cloud?



### ✅ **Sobre Proyectos y Retos**

7.  ¿Qué proyectos importantes están en curso relacionados con bases de datos?
8.  ¿Cuáles son los mayores retos técnicos que enfrentan actualmente?
9.  ¿Hay planes de migración, modernización o adopción de nuevas tecnologías?
 

--------------------------------------------------------------------------------------------------------

### ✅ **Equipo de trabajo**

*   ¿Cómo está conformado el equipo y cuántas personas lo integran?
*   ¿Cuál es la dinámica de trabajo? ¿Hay roles bien definidos o se trabaja de forma colaborativa?
*   ¿Cada cuánto tiempo se hacen cambios de equipo o rotaciones internas?



### ✅ **Bonos y compensaciones**

*   ¿Existen bonos por desempeño, productividad o certificaciones?
*   ¿Hay incentivos por trabajar en proyectos críticos o fuera de horario?



### ✅ **Horas extras y carga laboral**

*   ¿Cómo manejan las horas extras? ¿Son pagadas, compensadas con tiempo libre o no se contemplan?
*   ¿Cuál es la política para trabajo en fines de semana o días festivos?



### ✅ **Días pendientes y vacaciones**

*   ¿Cuántos días de vacaciones ofrecen y cómo se gestionan?
*   ¿Hay días personales o flexibles adicionales?



### ✅ **Periodo de prueba**

*   ¿Cuál es la duración del periodo de prueba?
*   ¿Qué garantías ofrecen durante ese tiempo? (Por ejemplo, prestaciones desde el primer día, seguridad laboral)
*   ¿Qué criterios utilizan para confirmar la contratación definitiva?



### ✅ **Otros puntos importantes**

*   ¿Cómo manejan revisiones salariales y promociones?
*   ¿Hay plan de carrera definido para este puesto?
*   ¿Ofrecen capacitaciones y certificaciones pagadas por la empresa?

 

💡 **Tip profesional:** Cuando preguntes sobre el periodo de prueba, hazlo con un enfoque positivo, por ejemplo:  
*"Me gustaría entender cómo funciona el periodo de prueba y qué apoyo brinda la empresa para asegurar que el colaborador tenga éxito en ese tiempo."*
 




