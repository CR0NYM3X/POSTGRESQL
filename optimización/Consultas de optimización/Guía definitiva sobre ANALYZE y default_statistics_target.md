 

# Dominando PostgreSQL: Guía definitiva sobre ANALYZE y default_statistics_target

Para optimizar bases de datos en PostgreSQL, primero hay que entender cómo "piensa" el motor. Antes de ejecutar una consulta, el **Query Planner** (optimizador de consultas) tiene que decidir el mejor camino para buscar tus datos: ¿Usa un índice? ¿Escanea toda la tabla? ¿Cómo une dos tablas distintas?

Para tomar esa decisión, el Planner no mira los datos reales en ese momento, sino que consulta un "resumen" estadístico de los datos. El parámetro `default_statistics_target` controla el nivel de detalle de ese resumen, y el comando `ANALYZE` es el encargado de construirlo.

## La Analogía: Las Encuestas Electorales

Imagina que eres un candidato político y quieres saber qué opina el país para planear tu estrategia (el Query Planner armando su plan de ejecución). Mandas a un mismo equipo a hacer encuestas (el comando `ANALYZE`).

* **Target bajo (ej. 100 - el valor por defecto en Postgres):** Pides encuestar a 100 personas en cada ciudad. El equipo termina rapidísimo y es barato de hacer. Si la ciudad es muy homogénea, esos 100 bastan. Pero si la ciudad tiene barrios muy distintos, tu encuesta será imprecisa y tu estrategia de campaña (el plan de ejecución) fracasará.
* **Target alto (ej. 1000):** Pides encuestar a 1,000 personas por ciudad. Tomas encuestas mucho más detalladas. Tu equipo **tardará mucho más tiempo** en recopilar los datos, pero ahora tu estrategia será perfecta porque conoces exactamente la realidad de cada barrio.

**El Trade-off (Intercambio):**
Aumentar el target estadístico no hace que el análisis sea más rápido; lo hace más lento, pero mucho más preciso.

* **Recopilación de estadísticas (`ANALYZE`):** Se vuelve lenta y pesada.
* **Tus consultas reales (`SELECT`):** Se vuelven muy rápidas en escenarios complejos, porque el motor sabe exactamente dónde buscar y no comete errores de cálculo.

---

## ¿Cómo recopila PostgreSQL esta información?

Es común pensar que cuando uno ejecuta `ANALYZE mi_tabla;`, PostgreSQL procesa la tabla como un solo bloque. Sin embargo, el comportamiento real es que escanea las filas, pero **guarda un "expediente" independiente para cada columna.**

Piensa en la tabla como un paciente y en las columnas como sus órganos: el médico evalúa a la persona completa, pero si la vista está perfecta, hace un examen rápido de 1 minuto. Si hay una condición cardíaca, a ese órgano le dedica un estudio profundo de 2 horas.

PostgreSQL lo hace así porque las columnas tienen naturalezas distintas. En una tabla de usuarios de 10 millones de filas:

* **Columna `id`:** Perfectamente uniforme. Con 10 muestras, Postgres sabe que son valores únicos.
* **Columna `pais`:** Quizás el 90% son de México y el 10% del resto del mundo. Es una distribución desigual (*Data Skew*). Aquí se necesita un histograma detallado.

### ¿Qué se guarda exactamente?

Si consultas la vista del sistema `pg_stats` (`SELECT * FROM pg_stats WHERE tablename = 'tu_tabla';`), verás que Postgres calcula cosas como:

* `null_frac`: Porcentaje de valores nulos.
* `n_distinct`: Cantidad de valores distintos.
* `most_common_vals`: Los valores que más se repiten.
* `histogram_bounds`: Rangos de división de datos.

El `statistics_target` define qué tan grandes serán esas listas de valores comunes y los rangos del histograma.

---

## ¿Cuándo modificar el target estadístico?

### Cuándo SÍ aumentarlo (a 500 o 1000)

1. **Planes de ejecución erráticos:** Tienes una consulta que antes era rápida y de repente se volvió lentísima, a pesar de tener índices. Al usar `EXPLAIN ANALYZE` notas una diferencia masiva entre las filas estimadas (`rows=10`) y las reales (`actual rows=50000`).
2. **Sistemas Multi-Tenant o Data Skew:** Tienes clientes gigantes (millones de registros) conviviendo con clientes pequeños (decenas de registros).
3. **Fechas históricas:** Días con picos de transacciones masivos (como un Black Friday) que quedan "diluidos" si el histograma es muy pequeño.

### Cuándo NO aumentarlo

1. **A nivel global (`postgresql.conf`):** Es una mala práctica subir el valor por defecto para *todas* las tablas.
2. **Columnas uniformes:** Estados booleanos, géneros o estatus simples.
3. **Entornos OLTP puros:** Tablas transaccionales pequeñas con consultas simples por ID.

### Cómo cambiar el target de forma quirúrgica (Solo en la columna problemática)

El truco de los expertos es no tocar la configuración global, sino ajustar únicamente la columna que causa problemas.

1. **Cambiar el target de la columna:** Define el nivel de detalle deseado.
Aplica el comando `ALTER TABLE` especificando la columna problemática. Puedes elegir un valor entre 1 y 10000 (el por defecto es 100):

```sql
ALTER TABLE nombre_tabla 
ALTER COLUMN columna_problematica 
SET STATISTICS 500;

```


2. **Recalcular las estadísticas:** Obligatorio para aplicar los cambios.
Cambiar la regla no actualiza los datos en ese instante. Debes ejecutar `ANALYZE`:

```sql
ANALYZE nombre_tabla (columna_problematica);

```


3. **Verificar la configuración:** Consulta pg_attribute.
Confirma el cambio consultando el catálogo interno:

```sql
SELECT attname, attstattarget 
FROM pg_attribute 
WHERE attrelid = 'nombre_tabla'::regclass 
  AND attname = 'columna_problematica';

```


*(Nota: Para revertir esto al valor global por defecto, simplemente ejecuta el mismo `ALTER TABLE` pero usando el valor `-1`).*

---

## Estrategias de Ejecución de ANALYZE

Cuando lanzas un `ANALYZE;` global, PostgreSQL analiza el esquema `public`, tus esquemas de usuario y las tablas del sistema (`pg_catalog`). Ignora vistas sin datos físicos como el `information_schema` y las tablas donde no tienes permisos.

Sin embargo, **no se recomienda ejecutar un `ANALYZE` global manual en el día a día**. La estrategia ideal se divide en tres niveles:

| Escenario | Estrategia Recomendada | Cómo hacerlo |
| --- | --- | --- |
| **Día a Día (Operación normal)** | **Dejar actuar al AutoVacuum.** Es tu mejor aliado. Analiza automáticamente las tablas cuando cambian un porcentaje significativo de sus filas. | No hagas scripts manuales. Si una tabla se degrada rápido, ajusta las reglas de AutoVacuum *solo para esa tabla*. |
| **Cargas Masivas (ETL / Backups)** | **Multiprocesamiento manual.** El AutoVacuum tarda en reaccionar tras insertar millones de registros de golpe. | Al terminar la carga masiva, usa el binario desde la terminal: `vacuumdb --analyze-only --jobs=4 -d tu_base --table='tu_tabla'` |
| **Emergencias (Consultas lentas súbitas)** | **Intervención Quirúrgica.** Restaura el rendimiento refrescando la memoria del optimizador sin bloquear transacciones. | Ejecuta desde SQL solo en las tablas o columnas afectadas: `ANALYZE ventas (id_cliente);` |


### Ventajas de ejecutar ANALYZE

| Ventaja | Descripción |
| --- | --- |
| **Planes de ejecución óptimos** | Es la única forma de garantizar que consultas complejas con múltiples `JOIN`s usen los índices correctos y no escaneen tablas completas por error. |
| **No bloquea operaciones** | `ANALYZE` solo toma un bloqueo de lectura compartida. Esto significa que **puedes ejecutarlo mientras tu aplicación funciona con normalidad**: tus usuarios pueden seguir haciendo `SELECT`, `INSERT`, `UPDATE` y `DELETE` sin interrupciones. |
| **Previene la degradación silenciosa** | A medida que insertas o borras datos masivamente, el rendimiento puede caer en picada de un día para otro. Un `ANALYZE` preventivo estabiliza el rendimiento. |
| **Ayuda a índices parciales** | Si usas índices condicionales (ej. `WHERE estado = 'activo'`), `ANALYZE` le dice al motor exactamente cuántas filas cumplen esa condición hoy. |


 
### ⚠️ AVISO TÉCNICO  

A diferencia de un simple `SELECT` o `UPDATE`, los comandos de mantenimiento profundo (`VACUUM` y `ANALYZE`) **no pueden ejecutarse dentro de un bloque transaccional explícito** (como un `DO $$ ... BEGIN ... END; $$`). El motor bloquea esto por seguridad para evitar inconsistencias en el mapa de memoria.

Por lo tanto, la inyección de recursos (`maintenance_work_mem`) y la ejecución se realizan secuencialmente mediante comandos `SET` a nivel de sesión.

Aquí tienes la homologación definitiva de los 3 escenarios:

---

### 1. El equivalente a `--analyze-only`

* **¿Qué hace en Bash?** Solo actualiza las estadísticas del planificador para que el motor sepa cómo elegir los mejores índices. Omite por completo la limpieza de tuplas muertas (`VACUUM`).
* **Caso de uso:** Mantenimiento rutinario nocturno en tablas que reciben muchos `INSERT` o `UPDATE`, pero donde no urge liberar espacio.

**Ejecución Nativa (SQL Puro):**

```sql
-- 1. Inyección temporal de recursos a la sesión
SET maintenance_work_mem = '15GB';
SET max_parallel_maintenance_workers = 8;

-- 2. Ejecución del comando
ANALYZE; 

-- Nota: Si es vía pg_cron, se inyecta así:
-- SELECT cron.schedule('mantenimiento_analyze', '0 2 * * *', 'SET maintenance_work_mem = ''15GB''; ANALYZE;');

```

---

### 2. El equivalente a `--analyze` (Sin el "only")

* **¿Qué hace en Bash?** Es el comportamiento predeterminado del binario. Primero ejecuta un `VACUUM` (limpia y marca el espacio libre dejado por filas borradas/actualizadas) y, al terminar, dispara inmediatamente un `ANALYZE` (recalcula las estadísticas sobre los datos limpios).
* **Caso de uso:** Tareas de limpieza profunda de fin de semana para prevenir el engordamiento de las tablas (*Table Bloat*) y mantener el optimizador afinado.

**Ejecución Nativa (SQL Puro):**

```sql
-- 1. Inyección temporal de recursos a la sesión
SET maintenance_work_mem = '15GB';
SET max_parallel_maintenance_workers = 8;

-- 2. Ejecución del comando combinado
VACUUM ANALYZE;

-- Nota: Si es vía pg_cron, se inyecta así:
-- SELECT cron.schedule('mantenimiento_vac_analyze', '0 3 * * 0', 'SET maintenance_work_mem = ''15GB''; VACUUM ANALYZE;');

```

---

### 3. El equivalente a `--analyze-in-stages`

* **¿Qué hace en Bash?** Es una táctica agresiva de recuperación rápida. Ejecuta `ANALYZE` tres veces seguidas, manipulando internamente el parámetro `default_statistics_target`.
* *Fase 1 (Target 1):* Un escaneo ultra rápido para que el servidor no esté ciego.
* *Fase 2 (Target 10):* Un escaneo medio para afinar los histogramas de datos.
* *Fase 3 (Default):* El escaneo profundo y definitivo.


* **Caso de uso:** Exclusivo para momentos post-restauración, migraciones mayores o cuando se levanta un entorno desde cero y urge que la base de datos comience a responder rápido sin esperar horas a un análisis completo.

**Ejecución Nativa (SQL Puro):**

```sql
-- 1. Inyección de memoria para acelerar el proceso
SET maintenance_work_mem = '15GB';
SET max_parallel_maintenance_workers = 8;

-- FASE 1: Mapa estadístico de emergencia (Target = 1)
SET default_statistics_target = 1;
ANALYZE;

-- FASE 2: Afinación de histogramas (Target = 10)
SET default_statistics_target = 10;
ANALYZE;

-- FASE 3: Estadísticas profundas definitivas (Se resetea al valor del servidor, usualmente 100)
RESET default_statistics_target;
ANALYZE;

```

---

### 🛡️ EL DICTAMEN DE ARQUITECTURA

Al utilizar esta metodología nativa, erradicas la necesidad de tener archivos `.sh`, dependencias de Bash, manejo de contraseñas exportadas en texto plano (`export PGPASSWORD`) y configuraciones de red engañosas (`tcp_keepalives`). Tu base de datos se vuelve un organismo **autosuficiente, auditable y alineado al 100% con los estándares de Grado Diamante** del Escuadrón.


**Conclusión:**
Un motor de base de datos eficiente no es aquel que se analiza manualmente cada hora, sino aquel donde el *Query Planner* tiene la información correcta en las columnas críticas. Invierte tu tiempo en afinar los parámetros de AutoVacuum y en ajustar el `statistics_target` de las columnas con distribuciones irregulares; la base de datos se cuidará sola.
