
### 🎯 Objetivo 

Este documento tiene como objetivo establecer un conjunto de buenas prácticas, planes estratégicos y lineamientos técnicos para llevar a cabo migraciones eficientes, seguras y sostenibles desde cualquier motor de base de datos hacia PostgreSQL. Está dirigido a arquitectos de datos, administradores de bases de datos, desarrolladores y responsables de TI que buscan una guía estructurada para planificar, ejecutar y validar procesos de migración, minimizando riesgos y maximizando la compatibilidad, el rendimiento y la mantenibilidad del entorno PostgreSQL resultante.

Se abordan aspectos clave como la evaluación del origen, análisis de compatibilidad, diseño de esquemas, estrategias de migración de datos y lógica de negocio, pruebas, validación, automatización, monitoreo post-migración y recomendaciones para asegurar la continuidad operativa.

 

## ⏳ **Duración estimada de un proyecto de migración**

La duración depende del tamaño, complejidad y criticidad de la base de datos. Aquí una guía general:

| Tipo de migración | Tiempo estimado |
|-------------------|-----------------|
| Pequeña (1-5 GB, pocos objetos) | 2-4 semanas |
| Mediana (5-100 GB, lógica moderada) | 1-2 meses |
| Crítica / grande (100+ GB, lógica compleja, alta disponibilidad) | 3-6 meses o más |

> ⚠️ **Importante**: Esto incluye análisis, pruebas, migración, validación y puesta en producción.

 

## 👥 **Equipo mínimo recomendado**

Para una base crítica, se recomienda al menos **5 roles clave**:

### 1. **Líder de proyecto / Arquitecto de migración**
- **Responsabilidades**: Planificación, coordinación, decisiones técnicas.
- **Conocimientos**:
  - Arquitectura de Oracle y PostgreSQL.
  - Migraciones empresariales.
  - Alta disponibilidad, seguridad, rendimiento.

### 2. **DBA Oracle**
- **Responsabilidades**: Exportar datos, entender la lógica actual, colaborar en la conversión.
- **Conocimientos**:
  - PL/SQL, paquetes, triggers, tipos de datos.
  - Seguridad, backups, monitoreo.

### 3. **DBA PostgreSQL**
- **Responsabilidades**: Crear estructuras, importar datos, adaptar lógica.
- **Conocimientos**:
  - PL/pgSQL, funciones, roles, tuning.
  - Herramientas como `ora2pg`, `pgloader`, `oracle_fdw`.

### 4. **Desarrollador backend / integrador**
- **Responsabilidades**: Adaptar aplicaciones que consumen la base de datos.
- **Conocimientos**:
  - Conexión a PostgreSQL desde lenguajes como Java, Python, PHP.
  - Validación de queries, ORM, APIs.

### 5. **QA / Tester funcional**
- **Responsabilidades**: Validar que todo funcione igual que en Oracle.
- **Conocimientos**:
  - Pruebas de regresión, validación de datos.
  - Comparación de resultados entre Oracle y PostgreSQL.

---

## 🧩 Estrategia  y Recomendación de buenas prácticas que pueden servir 
- **Hacer pruebas de rendimiento antes y después**  
- **Usar herramientas como Ora2Pg en modo análisis primero**  
- **Documentar todo el proceso**  
- **Migrar primero entornos no productivos (Desarrollo → QA/Staging → Producción)**  
- **Mantener Oracle en modo lectura durante la migración.**
- **Habilitar CDC o triggers en PostgreSQL para registrar cambios.**
- **No abrir PostgreSQL a producción hasta pasar todas las validaciones.**
- **Tener una ventana de validación antes de las operaciones reales.**
- **Capacitar al equipo en PostgreSQL antes de la migración**  
- **Tener un plan de sincronización inversa documentado.**
- **Antes de abrir PostgreSQL a producción**, tener una **ventana de validación funcional y técnica**.
- **Habilitar triggers de auditoría** en PostgreSQL para registrar todos los cambios desde el momento del corte.
- Si decides hacer rollback, usar esos registros para **reinsertar los datos en Oracle**, con validación.
- Para futuras migraciones, considerar **CDC o doble escritura** si el negocio no tolera downtime o pérdida de datos.


## ⚠️ **Errores comunes que pueden comprometer el proyecto**
-  ❌ 1. **No considerar el volumen de datos históricos**
-  ❌ 2. **No medir la carga real (lecturas/escrituras/conexiones)**
-  ❌ 3. **No validar funciones y procedimientos convertidos**
-  ❌ 4. **No considerar diferencias en el manejo de transacciones**
-  ❌ 5. **No usar staging con datos reales**
-  ❌ 6. **No considerar diferencias en tipos de datos**
-  ❌ 7. **No planear rollback o contingencia**
-  ❌ 8. **No considerar diferencias en la gestión de usuarios y roles**

---

### 🧠 **Lo retos que enfrentaras:**

1. **Adaptar la lógica de negocio**:
   - Oracle usa **PL/SQL**, PostgreSQL usa **PL/pgSQL**.
   - Hay diferencias en cómo se manejan cursores, excepciones, paquetes, etc.

2. **Convertir tipos de datos**:
   - Oracle tiene tipos como `NUMBER`, `VARCHAR2`, `CLOB`, `BLOB`, `DATE` que no tienen equivalentes exactos en PostgreSQL.

3. **Reescribir funciones y procedimientos**:
   - No se migran automáticamente si son complejos.
   - Hay que entender bien la lógica y reescribirla.

4. **Migrar datos grandes sin perder integridad**:
   - Validar claves primarias, foráneas, unicidad, etc.
   - Verificar encoding, formatos de fecha, nulos.

5. **Cambios en la seguridad y roles**:
   - PostgreSQL maneja roles y privilegios de forma distinta.
   - Hay que rediseñar el modelo de seguridad.

6. **Testing y validación**:
   - Comparar resultados entre Oracle y PostgreSQL.
   - Validar que todo funcione igual (consultas, procesos, reportes).

---


### **Herramientas para la migración**
Estas te ayudarán a automatizar y validar el proceso:

- **Oracle_fdw**: extensión para acceder a Oracle desde PostgreSQL.
- **ora2pg**: herramienta muy usada para migrar esquemas, datos y funciones.
- **pgloader**: útil para migraciones de datos.
- **SQLines**: convierte SQL de Oracle a PostgreSQL.
- **ETL**: herramienta que te puedan servir para pasar los datos.
- **pg_bulkload**  Herramienta para cargas masivas de datos de manera eficiente.

---

# 🧠 **Checklist de Evaluación Estratégica Pre-Migración**

Aquí tienes una lista completa de **preguntas clave** que debes realizar antes de definir la arquitectura y configuración del nuevo entorno PostgreSQL:
 
### 🗂️ **Inventario de Bases de Datos**
- ¿Cuántas bases de datos existen en Oracle?
- ¿Qúe tipos de base de datos son historicas?
- ¿Cuántos esquemas por base de datos?
- ¿Cuántas tablas, vistas, funciones, triggers, paquetes?
- ¿Qué tamaño tiene cada base de datos (en GB/TB)?
- ¿Qué porcentaje de los datos es histórico vs activo?

 
### 📈 **Carga y Uso**
- ¿Cuántas conexiones simultáneas se han registrado en picos?
- ¿Cuál es el promedio de conexiones activas por hora/día?
- ¿Cuántas transacciones se realizan por mes?
- ¿Cuál es el volumen de lecturas vs escrituras?
- ¿Hay operaciones masivas (batch, ETL, informes pesados)?
- ¿Qué procesos generan mayor carga (consultas, jobs, APIs)?

 

### 🕒 **Disponibilidad y Rendimiento**
- ¿Cuál es el SLA actual (tiempo de disponibilidad)?
- ¿Se requiere alta disponibilidad (HA)?
- ¿Se necesita replicación (streaming, lógica)?
- ¿Qué tiempos de respuesta se esperan en las consultas críticas?
- ¿Hay ventanas de mantenimiento definidas?

 

### 🔐 **Seguridad y Auditoría**
- ¿Qué usuarios y roles existen?
- ¿Qué políticas de acceso y privilegios están definidas?
- ¿Se requiere cifrado en reposo o en tránsito?
- ¿Hay auditoría de operaciones (DML/DDL)?
- ¿Se usan funciones de seguridad  RLS, etc.?
 
### 🔗 **Integraciones y Dependencias**
- ¿Qué aplicaciones se conectan a Oracle?
- ¿Qué drivers usan (ODBC, JDBC, etc.)?
- ¿Hay procesos ETL, APIs, reportes conectados?
- ¿Qué sistemas externos dependen de la base de datos?
 

### 🧮 **Requisitos Técnicos para PostgreSQL**
Con base en las respuestas anteriores, podrás definir:

#### 🔧 Configuración del servidor:
- CPU: ¿Cuántos núcleos se necesitan?
- RAM: ¿Cuánta memoria para `shared_buffers`, `work_mem`, etc.?
- Disco: ¿SSD, NVMe, RAID? ¿Qué IOPS se requieren?
- Red: ¿Qué ancho de banda para replicación o acceso remoto?

#### 📦 Arquitectura:
- ¿Servidor único, clúster, contenedores, cloud?
- ¿PostgreSQL nativo, RDS, Aurora, Cloud SQL, etc.?
- ¿Backup y recuperación (pgBackRest, Barman, WAL-G)?



---


#  🧭 **Plan Completo de Migración de Oracle a PostgreSQL**

### 🔍 **Fase 1: Evaluación y Planeación**
Antes de migrar, es fundamental entender el entorno actual.

#### ✅ Auditoría del entorno Oracle
- solicitar Diagrama de Entidad-Relación (ERD) - Te permite entender la estructura lógica de la base de datos y cómo están conectadas las entidades.
- solicitar Diagrama de Arquitectura del Sistema -  Te ayuda a identificar puntos de integración, dependencias y posibles impactos de la migración.
- solicitar Diagrama de Flujos de Datos (DFD) - Te permite entender qué procesos leen/escriben en la base de datos y cómo se transforman los datos.
- Versiones de Oracle y PostgreSQL objetivo.
- Número de bases de datos, esquemas, tablas, vistas, funciones, paquetes, triggers.
- Uso de características específicas de Oracle: PL/SQL, paquetes, secuencias, sinónimos, tipos definidos por el usuario, etc.
- Tamaño total de la base de datos.
- Dependencias externas (APIs, ETLs, aplicaciones conectadas).
- Requisitos de rendimiento, disponibilidad y seguridad.

#### ✅ Definición de objetivos
- ¿Migración completa o parcial?
- Se tienen ventanas de tiempo de manetnimiento ? 
- ¿Downtime permitido?
- ¿Migración en caliente o en frío?
- ¿Migración manual o automatizada?

#### ✅ Selección de herramientas
- Ora2Pg
- SQLines
- pgloader
- Herramientas propias o scripts personalizados.

 

### 🧪 **Fase 2: Pruebas de conversión**
#### ✅ Conversión de objetos
- Convertir estructuras con Ora2Pg: tablas, índices, constraints, secuencias.
- Convertir funciones PL/SQL a PL/pgSQL (requiere revisión manual).
- Validar tipos de datos incompatibles (ej. `NUMBER`, `VARCHAR2`, `CLOB`, `BLOB`, `DATE`, `TIMESTAMP`).
- Revisar funciones específicas de Oracle (`SYSDATE`, `NVL`, `DECODE`, `ROWNUM`, etc.) y mapearlas a equivalentes en PostgreSQL.

#### ✅ Pruebas de compatibilidad
- Ejecutar scripts convertidos en entorno de prueba.
- Validar integridad de datos y lógica de negocio.
- Comparar resultados entre Oracle y PostgreSQL.

 
### 📦 **Fase 3: Migración de datos**
#### ✅ Estrategia de migración
- Exportación con `Ora2Pg`, `SQL Developer`, `Data Pump`, o scripts personalizados.
- Importación con `COPY`, `pgloader`, `psql`, o herramientas ETL.
- Validación de datos: conteo de registros, checksums, comparaciones.

#### ✅ Consideraciones especiales
- Migración de datos binarios (BLOBs).
- Codificación de caracteres (UTF-8 vs otros).
- Fechas y zonas horarias.

 

### 🔐 **Fase 4: Seguridad y permisos**
- Migrar usuarios, roles y privilegios.
- Implementar políticas de seguridad en PostgreSQL.
- Validar acceso desde aplicaciones y servicios.

 
### 🧩 **Fase 5: Integración y pruebas finales**
- Conectar aplicaciones a PostgreSQL.
- Validar funcionamiento completo.
- Pruebas de rendimiento y carga.
- Pruebas de recuperación ante fallos.

 

### 🚀 **Fase 6: Puesta en producción**
- Plan de corte (downtime, sincronización final).
- Backup completo antes del corte.
- Monitoreo post-migración.
- Documentación de cambios.
 

### 🛠️ **Fase 7: Optimización post-migración**
- Plan de Rollback
- Ajuste de parámetros de PostgreSQL (`work_mem`, `shared_buffers`, etc.).
- Revisión de índices y estadísticas.
- Implementación de mantenimiento automático (vacuum, analyze).
- Auditoría y logging.
- Configura `pg_stat_statements`, `auto_explain`, `pgBadger`.
- Usa herramientas como Prometheus + Grafana.
- Revisa logs, errores y métricas de rendimiento.
- Pruebas de rendimientos 


### ** Fase 8: Capacitación del Equipo**
No olvides el factor humano:

- ¿El equipo sabe administrar PostgreSQL?
- ¿Conocen las diferencias en backup, recuperación, tuning?
- ¿Saben usar herramientas como `pgAdmin`, `psql`, `EXPLAIN`?

🔧 *Acción:* Plan de capacitación y documentación interna.



### ** Fase 9: Documentación Técnica y Funcional**
Toda migración debe dejar trazabilidad:

- Documentar cambios en estructuras, funciones, lógica.
- Registrar decisiones técnicas y justificaciones.
- Crear manuales de operación y recuperación.

--- 
# Preguntas que pueden servir


#  🎯 ¿Por qué es importante un plan de rollback en una migración?
 
Un plan de rollback **no es opcional**  Porque **una migración es un punto de no retorno si no se planifica bien**. 
Estás cambiando la base de datos que sustenta procesos críticos del negocio. Si algo falla y no puedes volver atrás, puedes:

- Perder datos.
- Interrumpir operaciones.
- Afectar la experiencia del usuario.
- Generar pérdidas económicas y reputacionales.

# 🔎 ¿Por qué es importante conocer lecturas y escrituras?

### 📊 **1. Dimensionamiento del servidor**
- Si hay muchas **escrituras**, necesitas buen rendimiento de disco (SSD, NVMe). Si hay muchas escrituras, la replicación lógica puede ser más adecuada.
- Si hay muchas **lecturas**, necesitas más **memoria RAM** para `shared_buffers`, `work_mem`. Si hay muchas lecturas, puedes usar réplicas en modo lectura (`hot standby`).

---

### 🕐 **1. ¿En un entorno donde realizaron una migración, cuál es el tiempo que le dan al servidor migrado para las pruebas?**

**Respuesta profesional:**
> El tiempo de pruebas en un servidor migrado depende del **nivel de criticidad del sistema**, pero en entornos reales se recomienda un periodo de **entre 1 y 4 semanas** para pruebas funcionales, de rendimiento, seguridad y validación de datos.

**Factores que determinan el tiempo:**
- Complejidad del sistema (número de objetos, funciones, integraciones).
- Volumen de datos migrados.
- Cantidad de usuarios y procesos concurrentes.
- Disponibilidad de ambientes de QA y equipos de testing.

**Buenas prácticas:**
- Usar **datos reales anonimizados** para pruebas.
- Incluir **pruebas automatizadas** y **pruebas manuales** de negocio.
- Validar **consultas críticas, reportes, procesos batch y triggers**.
- Hacer pruebas de **carga y estrés** si es un sistema de alto tráfico.
 

### 🗑️ **2. Una vez que el servidor que migraron pasó el periodo de pruebas, ¿eliminan el servidor origen?**

**Respuesta profesional:**
> **No se elimina inmediatamente.** El servidor origen (Oracle) se mantiene **en modo de solo lectura** durante un periodo de gracia que puede ir de **1 a 3 meses**, dependiendo del riesgo y la criticidad del sistema.

**¿Por qué se conserva?**
- Para tener un **respaldo inmediato** en caso de rollback.
- Para **consultas históricas** o validaciones cruzadas.
- Para cumplir con **auditorías o regulaciones**.

**Buenas prácticas:**
- Cambiar Oracle a **modo read-only** después del corte.
- Documentar claramente la fecha de **desmantelamiento definitivo**.
- Asegurar que los **backups estén verificados** antes de eliminar.
 

### 🔁 **3. En caso de un error, ¿cómo es su plan de rollback? ¿Ustedes sincronizan los datos insertados en el servidor nuevo al servidor origen?**

**Respuesta profesional:**
> El plan de rollback depende del tipo de error y del tiempo transcurrido. Si ya se insertaron datos en PostgreSQL, **no se sincronizan automáticamente a Oracle**, a menos que se haya planificado una **estrategia de doble escritura o CDC**.


--- 
# 🧠 ¿Por qué importa el tipo de base de datos?

### 1. **Define el propósito y la carga**
- Una base de datos **OLTP (Online Transaction Processing)** tiene muchas transacciones pequeñas y frecuentes (ej. sistemas de ventas, ERP).
- Una base de datos **OLAP (Online Analytical Processing)** realiza consultas complejas y pesadas (ej. BI, reportes, análisis histórico).
- Una base de datos **mixta** combina ambos tipos.

👉 Saber esto te ayuda a:
- Elegir el tipo de almacenamiento (SSD vs HDD).
- Configurar parámetros como `work_mem`, `maintenance_work_mem`, `effective_cache_size`.
- Decidir si necesitas particiones, índices especiales, o réplicas de solo lectura.

--- 
# 🧭 Tipos de Base de Datos según su propósito o naturaleza

Aquí te presento una clasificación útil para tu proyecto:
 
 
## ✅ ¿Por qué es importante identificar el tipo?

Porque te permite:

- **Elegir la mejor estrategia de migración** (por ejemplo, migrar primero las bases históricas que no cambian).
- **Configurar PostgreSQL correctamente** (por ejemplo, ajustar `autovacuum` según el tipo de carga).
- **Optimizar recursos** (RAM, CPU, disco).
- **Definir políticas de retención, backup y seguridad**.

 

### 🕰️ **1. Históricas**
- **Descripción**: Contienen datos antiguos, usados para análisis, auditoría o cumplimiento.
- **Características**:
  - Gran volumen de datos.
  - Baja frecuencia de escritura.
  - Alta frecuencia de lectura (consultas analíticas).
- **Recomendaciones en PostgreSQL**:
  - Uso de **particiones** por fecha.
  - Compresión con `pg_partman`, `zstd`, o `timescaledb`.
  - Archivos de solo lectura o réplicas dedicadas.

 
### 📦 **2. Operacionales (OLTP)**
- **Descripción**: Bases activas que soportan operaciones del día a día.
- **Características**:
  - Muchas transacciones concurrentes.
  - Escrituras y lecturas constantes.
- **Recomendaciones en PostgreSQL**:
  - Configuración optimizada para concurrencia (`max_connections`, `work_mem`).
  - Replicación para alta disponibilidad.
  - Monitoreo activo (`pg_stat_statements`, `pgBadger`).

 

### 📊 **3. Analíticas (OLAP)**
- **Descripción**: Usadas para reportes, BI, minería de datos.
- **Características**:
  - Consultas complejas y pesadas.
  - Datos agregados o transformados.
- **Recomendaciones en PostgreSQL**:
  - Uso de **materialized views**.
  - Índices especializados (GIN, BRIN).
  - Configuración de `work_mem` y `effective_cache_size`.

 

### 🔐 **4. Auditoría / Seguridad**
- **Descripción**: Registra eventos, accesos, cambios, logs.
- **Características**:
  - Escrituras constantes (logs).
  - Lecturas ocasionales.
- **Recomendaciones en PostgreSQL**:
  - Uso de `jsonb` para flexibilidad.
  - Triggers y funciones de auditoría (`pgAudit`, funciones personalizadas).
  - Retención y archivado automático.

 

### 🔄 **5. Temporal / Cache**
- **Descripción**: Datos que se usan por poco tiempo (ej. sesiones, tokens, caché).
- **Características**:
  - Alta rotación.
  - No requieren persistencia larga.
- **Recomendaciones en PostgreSQL**:
  - Tablas no persistentes (`UNLOGGED`).
  - Limpieza automática (`cron`, `pg_cron`).
  - Posible uso de Redis como complemento.
 

### 🌐 **6. Distribuidas / Multi-tenant**
- **Descripción**: Bases que sirven a múltiples clientes o regiones.
- **Características**:
  - Separación lógica o física por cliente.
  - Requiere escalabilidad.
- **Recomendaciones en PostgreSQL**:
  - Uso de esquemas por cliente.
  - Multitenencia con RLS (Row Level Security).
  - Posible uso de Citus para distribución horizontal.
 
----

**Escenarios comunes:**

#### ✅ **Rollback inmediato (sin datos nuevos)**
- Se cambia la conexión de la aplicación de vuelta a Oracle.
- PostgreSQL se descarta.
- No se necesita sincronización.

#### ⚠️ **Rollback con datos nuevos en PostgreSQL**
- Si se insertaron datos válidos, se debe:
  - **Exportar los datos nuevos** desde PostgreSQL (por timestamp, usuario, etc.).
  - **Transformarlos** al formato Oracle.
  - **Cargarlos manualmente o con scripts** en Oracle.
- Esto **solo es posible si se implementó auditoría o CDC**.

#### ❌ **Sin auditoría ni sincronización previa**
- El rollback es **muy riesgoso**.
- Puede requerir **restaurar Oracle desde backup** y **perder datos recientes**.
- En este caso, muchas empresas **optan por corregir el error en PostgreSQL** en lugar de volver atrás.

**Buenas prácticas:**
- Implementar **triggers de auditoría** en PostgreSQL antes del corte.
- Tener un **plan de sincronización inversa documentado**.
- Definir **criterios claros para activar rollback** (ej. errores críticos, pérdida de datos, fallos funcionales).


---


 

## 🧪 Escenario técnico realista: migración sin rollback

### 🏢 **Contexto**
Una empresa de retail migra su sistema de ventas de Oracle a PostgreSQL.  
La migración se hace durante la madrugada para minimizar el impacto.

### 🔄 **Estrategia**
- Se hace un dump de Oracle con `Data Pump`.
- Se convierte el esquema con `Ora2Pg`.
- Se importan los datos a PostgreSQL.
- Se cambia la conexión de la aplicación a PostgreSQL.

### ⚠️ **Problema**
Al iniciar operaciones a las 8:00 AM:
- Los usuarios reportan errores al guardar ventas.
- Algunas funciones de negocio no devuelven los resultados esperados.
- Se detecta que una función PL/SQL fue mal convertida y está calculando mal los descuentos.

### 🔥 **Consecuencias**
- Se pierden ventas durante 2 horas.
- El equipo intenta corregir el error en caliente, pero no lo logra.
- No hay plan de rollback, y volver a Oracle implicaría restaurar un backup de hace 12 horas, perdiendo datos.

 

## ✅ ¿Cómo habría ayudado un plan de rollback?

Un buen plan habría incluido:

1. **Backup completo de Oracle justo antes del corte.**
2. **Registro de cambios durante la migración (CDC o triggers).**
3. **Pruebas de validación post-migración antes de abrir a usuarios.**
4. **Criterios claros para activar el rollback (ej. errores críticos, pérdida de datos).**
5. **Procedimiento documentado para volver a Oracle en minutos.**

Con esto, el equipo habría podido:
- Detectar el error en pruebas.
- Activar el rollback antes de abrir a usuarios.
- Restaurar Oracle y mantener la operación sin pérdida de datos.

 

## 🧪 Escenario: Migración programada durante la madrugada

### 🕐 **Plan original**
- **Horario de migración**: 2:00 AM a 6:00 AM.
- **Hora de apertura de operaciones**: 8:00 AM.
- **Objetivo**: Tener todo listo y validado antes de que los usuarios comiencen a trabajar.

---

## ❗ ¿Qué pasa si algo falla entre las 6:00 AM y las 8:00 AM?

Supongamos que:
- A las 6:30 AM detectas que algunas funciones críticas no están devolviendo resultados correctos.
- A las 7:00 AM intentas corregir el código.
- A las 7:45 AM te das cuenta de que no llegas a tiempo para tener todo listo a las 8:00 AM.

### 🔁 ¿Qué opciones tienes?

#### ✅ **Si tienes un plan de rollback:**
- A las 7:00 AM decides **activar el rollback**.
- Cambias las conexiones de la aplicación de vuelta a Oracle.
- Restauras el estado de Oracle con los datos sincronizados hasta el último momento (idealmente con CDC o sincronización incremental).
- A las 8:00 AM, los usuarios siguen trabajando como si nada hubiera pasado.

#### ❌ **Si no tienes plan de rollback:**
- No puedes volver a Oracle porque los datos nuevos ya no están sincronizados.
- Restaurar Oracle desde un backup de las 2:00 AM implicaría perder datos.
- No puedes abrir el sistema a las 8:00 AM.
- El negocio se detiene, los usuarios no pueden trabajar, y el equipo entra en crisis.

 

## 🎯 Entonces, ¿qué implica un rollback en este contexto?

1. **Cambiar conexiones de la aplicación de PostgreSQL a Oracle.**
2. **Restaurar Oracle al estado más reciente posible.**
3. **Asegurar que los datos que llegaron entre el backup y el corte estén sincronizados (CDC, logs, etc.).**
4. **Reiniciar servicios y validar que todo funcione.**
5. **Notificar a los usuarios que se sigue operando en Oracle.**
 

## ✅ Conclusión

La idea de que el rollback puede ser tan simple como **cambiar las conexiones de vuelta a Oracle** es **válida**, **siempre y cuando**:

- Oracle siga operativo y actualizado.
- Tengas sincronizados los datos que llegaron después del backup.
- No hayas hecho cambios irreversibles en la aplicación o en los datos.

De lo contrario, el rollback puede ser **más complejo** y requerir restauraciones, reprocesamiento de datos o incluso intervención manual.



```
https://medium.com/engineering-on-the-incline/unit-testing-functions-in-postgresql-with-pgtap-in-5-simple-steps-beef933d02d3
https://medium.com/@daily_data_prep/how-can-i-test-postgressql-database-objects-using-pgtap-9541caf5e85a
https://medium.com/engineering-on-the-incline/unit-testing-postgres-with-pgtap-af09ec42795
https://lebedana21.medium.com/parametric-sql-testing-with-pgtap-find-my-way-from-toy-examples-to-practical-application-a09bd8ae549a

```
