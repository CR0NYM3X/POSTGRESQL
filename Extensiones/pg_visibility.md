## 🧠 Análisis estructurado: `pg_visibility`

### 🎯 Objetivo

`pg_visibility` es una extensión oficial de PostgreSQL que permite inspeccionar la visibilidad de las filas en las páginas de disco de una tabla. Su propósito principal es ayudar a los administradores y desarrolladores a entender cómo se comporta el sistema de almacenamiento interno, especialmente en relación con:

*   Tuplas visibles/invisibles
*   Espacio muerto (dead tuples)
*   Eficiencia de VACUUM y autovacuum
*   Fragmentación interna
 



### ✅ Ventajas

*   **Diagnóstico profundo**: Permite ver qué tuplas están visibles, muertas o congeladas directamente en el nivel de página.
*   **Optimización de mantenimiento**: Ayuda a decidir cuándo ejecutar `VACUUM`, `ANALYZE` o `CLUSTER`.
*   **Auditoría de espacio**: Identifica páginas con alto porcentaje de tuplas muertas.
*   **Complemento ideal para debugging**: Útil cuando el rendimiento de consultas se degrada por falta de mantenimiento.
 

### ❌ Desventajas

*   **No es para producción**: Está pensado para entornos análisis, no para uso continuo en sistemas en vivo.
*   **Lectura técnica avanzada**: Requiere conocimientos sobre el almacenamiento interno de PostgreSQL (MVCC, páginas, tuplas).
*   **No modifica datos**: Solo inspecciona; no corrige ni limpia.
 

### 📌 Casos de uso reales

*   **Auditoría de tablas con alto volumen de escritura**: Por ejemplo, logs, eventos o métricas.
*   **Análisis post-mortem de rendimiento**: Cuando una consulta se vuelve lenta y se sospecha de fragmentación.
*   **Validación de VACUUM**: Para verificar si realmente está limpiando tuplas muertas.
*   **Evaluación de estrategias de autovacuum**: Ajuste de parámetros como `autovacuum_vacuum_threshold`.

 

### 📅 Cuándo usarlo

*   Antes de aplicar estrategias de mantenimiento intensivo.
*   Cuando se sospecha que el autovacuum no está funcionando correctamente.
*   En entornos de desarrollo para entender el comportamiento de MVCC.
*   Para validar el impacto de operaciones como `DELETE`, `UPDATE` y `VACUUM`.

 

### 🚫 Cuándo no usarlo

*   En sistemas en producción con alta concurrencia.
*   Como herramienta de monitoreo continuo.
*   Para modificar datos o corregir problemas directamente.

 

 


***

## . ¿Qué es el Visibility Map (VM)?

El Visibility Map es un archivo auxiliar (con sufijo `_vm`) que PostgreSQL mantiene para cada tabla. Tiene dos objetivos principales:

1. **Index-Only Scans:** Permite saber si todas las filas de una página son visibles para todos. Si es así, el motor puede obtener datos directamente del índice sin ir a la tabla (Heap).
2. **Optimización de VACUUM:** Permite que el proceso de VACUUM salte páginas donde no hay nada que limpiar.


## 🧭 1. Índice

1.  Objetivo
2.  Requisitos
3.  Ventajas y Desventajas
4.  Casos de Uso
5.  Simulación empresarial
6.  Estructura Semántica
7.  Visualizaciones
8.  Procedimientos
    *   Instalación
    *   Creación de datos
    *   Uso de `pg_visibility`
    *   Interpretación de resultados
    *   Mantenimiento
9.  Consideraciones
10. Buenas prácticas
11. Recomendaciones
12. Otros tipos
13. Tabla comparativa
14. Bibliografía

 

## 🎯 2. Objetivo

Este manual tiene como propósito enseñar el uso de la extensión `pg_visibility`, que permite inspeccionar la visibilidad de las páginas de datos en PostgreSQL. Es útil para detectar páginas con espacio libre, páginas completamente visibles o parcialmente visibles, y para tareas de mantenimiento como VACUUM o tuning de autovacuum.
 

## 🧰 3. Requisitos

*   PostgreSQL 12 o superior
*   Acceso como superusuario
*   Extensión `pg_visibility` instalada
*   Conocimientos básicos de SQL y administración de PostgreSQL

 

## ⚖️ 4. Ventajas y Desventajas

| Ventajas                               | Desventajas                                  |
| -------------------------------------- | -------------------------------------------- |
| Permite inspección granular de páginas | Solo accesible por superusuarios             |
| Útil para tuning de autovacuum         | No es amigable para usuarios sin experiencia |
| Ayuda a detectar bloat                 | No modifica datos, solo inspecciona          |

 

## 🧪 5. Casos de Uso

*   Diagnóstico de bloat en tablas
*   Validación de efectividad de VACUUM
*   Auditoría de visibilidad de datos
*   Optimización de autovacuum

 

## 🏢 6. Simulación empresarial

**Empresa ficticia:** AgroData S.A.\
**Problema:** La tabla `produccion_diaria` está creciendo rápidamente y el rendimiento de las consultas ha disminuido. Se sospecha de bloat.\
**Solución:** Usar `pg_visibility` para inspeccionar visibilidad de páginas y decidir si se requiere VACUUM FULL.



## 🧠 7. Estructura Semántica

*   Extensión: `pg_visibility`
*   Funciones clave:
    *   `pg_visibility_map(regclass)`
    *   `pg_visibility(regclass, block_number)`
    *   `pg_visibility_map_summary(regclass)`
*   Objetos inspeccionables: Tablas y sus páginas físicas

 

## 🛠️ 9. Procedimientos

### 🔧 Instalación

```sql
CREATE EXTENSION pg_visibility;

postgres@test# \dx+ pg_visibility
      Objects in extension "pg_visibility"
+-----------------------------------------------+
|              Object description               |
+-----------------------------------------------+
| function pg_check_frozen(regclass)            |
| function pg_check_visible(regclass)           |
| function pg_truncate_visibility_map(regclass) |
| function pg_visibility_map(regclass)          |
| function pg_visibility_map(regclass,bigint)   |
| function pg_visibility_map_summary(regclass)  |
| function pg_visibility(regclass)              |
| function pg_visibility(regclass,bigint)       |
+-----------------------------------------------+


```

### 🧪 Creación de datos

```sql
--  drop table produccion_diaria ;
CREATE TABLE produccion_diaria (
    id SERIAL PRIMARY KEY,
    fecha DATE,
    cantidad INT
);

INSERT INTO produccion_diaria (fecha, cantidad)
SELECT CURRENT_DATE - i, (random() * 100)::int
FROM generate_series(1, 1000) AS i;

postgres@test# SELECT * FROM pg_visibility_map_summary('produccion_diaria');
+-------------+------------+
| all_visible | all_frozen |
+-------------+------------+
|           0 |          0 |
+-------------+------------+
(1 row)

Time: 1.322 ms
postgres@test# SELECT * FROM pg_visibility_map('produccion_diaria') LIMIT 10;
+-------+-------------+------------+
| blkno | all_visible | all_frozen |
+-------+-------------+------------+
|     0 | f           | f          |
|     1 | f           | f          |
|     2 | f           | f          |
|     3 | f           | f          |
|     4 | f           | f          |
|     5 | f           | f          |
+-------+-------------+------------+
(6 rows)

Time: 0.585 ms
postgres@test# SELECT * FROM pg_visibility('produccion_diaria') LIMIT 10;
+-------+-------------+------------+----------------+
| blkno | all_visible | all_frozen | pd_all_visible |
+-------+-------------+------------+----------------+
|     0 | f           | f          | f              |
|     1 | f           | f          | f              |
|     2 | f           | f          | f              |
|     3 | f           | f          | f              |
|     4 | f           | f          | f              |
|     5 | f           | f          | f              |
+-------+-------------+------------+----------------+
(6 rows)

Time: 0.550 ms
postgres@test# VACUUM produccion_diaria;
VACUUM
Time: 12.165 ms
postgres@test# SELECT * FROM pg_visibility_map_summary('produccion_diaria');
+-------------+------------+
| all_visible | all_frozen |
+-------------+------------+
|           6 |          0 |
+-------------+------------+
(1 row)

Time: 1.117 ms
postgres@test# VACUUM FULL produccion_diaria;
VACUUM
Time: 23.539 ms
postgres@test# SELECT * FROM pg_visibility_map_summary('produccion_diaria');
+-------------+------------+
| all_visible | all_frozen |
+-------------+------------+
|           0 |          0 |
+-------------+------------+
(1 row)

Time: 0.523 ms
postgres@test# VACUUM produccion_diaria;
VACUUM
Time: 12.099 ms
postgres@test# SELECT * FROM pg_visibility_map_summary('produccion_diaria');
+-------------+------------+
| all_visible | all_frozen |
+-------------+------------+
|           6 |          6 |
+-------------+------------+
(1 row)

Time: 0.523 ms
postgres@test# SELECT * FROM pg_visibility_map('produccion_diaria') LIMIT 10;
+-------+-------------+------------+
| blkno | all_visible | all_frozen |
+-------+-------------+------------+
|     0 | t           | t          |
|     1 | t           | t          |
|     2 | t           | t          |
|     3 | t           | t          |
|     4 | t           | t          |
|     5 | t           | t          |
+-------+-------------+------------+
(6 rows)

Time: 0.409 ms
postgres@test# SELECT * FROM pg_visibility('produccion_diaria') LIMIT 10;
+-------+-------------+------------+----------------+
| blkno | all_visible | all_frozen | pd_all_visible |
+-------+-------------+------------+----------------+
|     0 | t           | t          | t              |
|     1 | t           | t          | t              |
|     2 | t           | t          | t              |
|     3 | t           | t          | t              |
|     4 | t           | t          | t              |
|     5 | t           | t          | t              |
+-------+-------------+------------+----------------+
(6 rows)

Time: 0.250 ms
postgres@test# SELECT * FROM pg_check_frozen('produccion_diaria');
+--------+
| t_ctid |
+--------+
+--------+
(0 rows)

Time: 0.539 ms
postgres@test# SELECT * FROM pg_check_visible('produccion_diaria');
+--------+
| t_ctid |
+--------+
+--------+
(0 rows)

Time: 0.516 ms
postgres@test#
postgres@test# SELECT * FROM pg_truncate_visibility_map('produccion_diaria');
+----------------------------+
| pg_truncate_visibility_map |
+----------------------------+
|                            |
+----------------------------+
(1 row)

Time: 8.081 ms
postgres@test#
postgres@test# SELECT * FROM pg_visibility_map_summary('produccion_diaria');
+-------------+------------+
| all_visible | all_frozen |
+-------------+------------+
|           0 |          0 |
+-------------+------------+
(1 row)

Time: 1.034 ms


```
 

##  Explicación de Funciones y Columnas

### Funciones Utilizadas

```sql

-- Da un conteo total de cuántas páginas (bloques) en la tabla están marcadas como "totalmente visibles" o "totalmente congeladas".
SELECT * FROM pg_visibility_map_summary('produccion_diaria');

-- Muestra el estado de cada bloque individual según el archivo VM.
-- puedes agregar un segundo parametro para especificar el numero de la pagina
SELECT * FROM pg_visibility_map('produccion_diaria') LIMIT 10; 

-- Es más profunda; muestra lo que dice el VM y lo compara con el bit `pd_all_visible` que está físicamente en la cabecera de la página de datos.
-- puedes agregar un segundo parametro para especificar el numero de la pagina 
SELECT * FROM pg_visibility('produccion_diaria') LIMIT 10;       


--  Verifican la integridad, buscando filas que NO deberían estar ahí si la página se supone que está congelada o es visible. Si devuelven 0 filas, todo está correcto.
SELECT * FROM pg_check_frozen('produccion_diaria');
SELECT * FROM pg_check_visible('produccion_diaria');

-- No recomendado - Borra el mapa de visibilidad de la tabla (útil para pruebas o si sospechas de corrupción).
SELECT * FROM pg_truncate_visibility_map('produccion_diaria');


```
 
### Columnas Retornadas

| Columna | Significado |
| --- | --- |
| **`blkno`** | El número del bloque (página) de 8KB en el archivo de la tabla. |
| **`all_visible`** | Según el mapa de visibilidad, ¿son todas las filas de este bloque visibles para todos? |
| **`all_frozen`** | Según el mapa de visibilidad, ¿están todas las filas de este bloque "congeladas" (protegidas contra el wraparound de XID)? |
| **`pd_all_visible`** | El bit de visibilidad real guardado en el encabezado de la página física (`PageHeader`). |



 


---




## 3. Análisis del Flujo del Laboratorio

### Paso 1: CREATE e INSERT (`all_visible = 0`)

Al insertar las 1000 filas, PostgreSQL escribe los datos en las páginas. Sin embargo, aunque las filas ya están ahí, el **Visibility Map aún no se ha actualizado**. El VM no se actualiza en tiempo real con cada `INSERT` por razones de rendimiento; se actualiza principalmente durante un `VACUUM`.

### Paso 2: El primer `VACUUM` (`all_visible = 6`)

Ejecutaste un `VACUUM` estándar.

* **¿Qué pasó?** El proceso escaneó la tabla y se dio cuenta de que las transacciones que insertaron los datos ya terminaron. Por lo tanto, todas las filas en esos 6 bloques son visibles para cualquier transacción futura.
* **Resultado:** Marcó los 6 bloques como `all_visible = t`.

### Paso 3: El misterio del `VACUUM FULL` (`all_visible = 0`)

Aquí notaste que al hacer `VACUUM FULL`, los contadores volvieron a cero.

* **Razonamiento:** `VACUUM FULL` no limpia la tabla vieja; **crea una tabla completamente nueva** y mueve los datos ahí, eliminando la vieja. Al ser un archivo nuevo, el Visibility Map se descarta y se crea uno nuevo vacío. Hasta que no corra un `VACUUM` normal o el `autovacuum` pase por la "nueva" tabla, el mapa no se poblará.

### Paso 4: Segundo `VACUUM` (`all_frozen = 6`)

Aquí es donde se pone interesante: ahora aparecen como **congeladas (frozen)**.

* **¿Qué pasó?** En PostgreSQL, las filas tienen un ID de transacción (`xmin`). Cuando las filas son "viejas" (nadie las va a borrar o modificar y han pasado suficientes transacciones), `VACUUM` las "congela" cambiando su ID por uno especial llamado `FrozenXID`.
* **Por qué ahora sí:** Probablemente al repetir el proceso y ejecutar `VACUUM` sobre la tabla recién creada por el `FULL`, el motor determinó que los datos eran candidatos perfectos para congelar (ya que son datos estáticos de un laboratorio). Una página `all_frozen` es automáticamente `all_visible`.

### Paso 5: `pg_truncate_visibility_map`

Finalmente, usaste la "bomba nuclear" de la extensión. Esta función truncó el archivo del mapa. Por eso, aunque los datos seguían en la tabla, el resumen volvió a mostrar **0**, porque simplemente borraste el mapa que contenía esa información.

 
---

 
## 1. ¿Por qué es BUENO tener páginas Visibles y Congeladas?

### El beneficio de "All-Visible" (Rendimiento)

Cuando una página es "All-Visible", PostgreSQL puede realizar un **Index-Only Scan**.

* **Sin VM:** Si haces una consulta que solo pide columnas que están en el índice, Postgres de todos modos tiene que ir al archivo de la tabla (el Heap) para ver si esa fila es visible para tu transacción. Esto genera mucho **I/O (lectura de disco)**.
* **Con VM:** Postgres mira el Visibility Map. Si el bit dice "t" (true), confía en el mapa y devuelve el dato del índice directamente. Es órdenes de magnitud más rápido.

### El beneficio de "All-Frozen" (Mantenimiento)

Cuando una página está "All-Frozen", PostgreSQL sabe que los datos allí son tan antiguos que ya no necesitan ser revisados nunca más para temas de mantenimiento de IDs de transacción.

* **Ahorro en VACUUM:** En los siguientes procesos de `VACUUM`, el motor simplemente **salta** estas páginas. No las lee, no consume CPU ni disco con ellas.
 

## 2. ¿Qué pasa si NO se marcan páginas (Consecuencias)?

Si tu laboratorio siempre mostrara `0` en `all_visible` y `all_frozen`, tu base de datos entraría en un estado de degradación:

### A. Degradación del Rendimiento (I/O excesivo)

Tus índices dejarían de ser tan eficientes. Incluso si tienes índices perfectos, PostgreSQL se vería obligado a leer el archivo de la tabla para cada fila encontrada para verificar visibilidad, aumentando la latencia de las consultas.

### B. El riesgo del Transaction ID Wraparound (El "Apocalipsis")

PostgreSQL usa números de 32 bits para las transacciones. Si llegas a ~2 mil millones de transacciones sin "congelar" los datos viejos, la base de datos **entrará en modo de solo lectura o se apagará** para evitar la pérdida de datos (porque los IDs nuevos empezarían a solaparse con los viejos y los datos viejos "desaparecerían").

> Las páginas **Frozen** son la cura contra este problema.

### C. "Vacuum Bloat" y fatiga de disco

Si el `VACUUM` no puede marcar páginas como visibles, cada vez que pase tendrá que escanear la tabla completa de principio a fin.

* En una tabla de 1 GB no importa.
* En una tabla de 1 TB, el `VACUUM` nunca terminaría, consumiendo todo el ancho de banda de tus discos constantemente.

 

## 3. Resumen: Comparativa de consecuencias

| Situación | Consecuencia en Consultas | Consecuencia en Almacenamiento |
| --- | --- | --- |
| **Mucho All-Visible** | Consultas ultra rápidas (Index-Only Scans). | Menor desgaste de disco (menos I/O). |
| **Poco All-Visible** | Consultas lentas (siempre van al Heap). | Alto consumo de recursos por VACUUM constante. |
| **Mucho All-Frozen** | Rendimiento estable. | Protección total contra Wraparound. |
| **Cero All-Frozen** | Riesgo de parada total del servicio. | VACUUMs extremadamente pesados y largos. |

 

## Razonamiento de tu laboratorio

En tu laboratorio, cuando hiciste el `VACUUM` y viste que pasó de **0 a 6**, estabas viendo a PostgreSQL "optimizándose a sí mismo".

1. Al principio (0), Postgres no sabía si los datos eran para todos.
2. Tras el `VACUUM` (6 visibles), Postgres dijo: "Listo, esto ya es estable, puedo usar los índices rápido".
3. Tras el segundo `VACUUM` (6 congelados), Postgres dijo: "Estos datos no van a cambiar en mucho tiempo, los marco como permanentes (frozen) para no volver a leer este bloque en el próximo mantenimiento".

---

## 1. La solución inmediata: El encadenamiento de comandos

Dado que `VACUUM FULL` crea una tabla nueva "ciega", la solución es ejecutar un `VACUUM` estándar (sin FULL) inmediatamente después. El flujo ideal en un script de mantenimiento debería ser:

```sql
-- 1. Compactar la tabla (bloqueo total, crea archivo nuevo)
VACUUM FULL produccion_diaria;

-- 2. Poblar el Visibility Map (rápido, no bloquea lecturas)
VACUUM produccion_diaria;

-- 3. Actualizar estadísticas para el optimizador de consultas
ANALYZE produccion_diaria;

```

### ¿Por qué hacer esto?

* El **`VACUUM FULL`** recupera espacio en disco.
* El **`VACUUM`** (normal) recorre la nueva tabla y marca las páginas como `all_visible`. Como la tabla acaba de ser creada y no tiene "basura" (bloat), este segundo Vacuum es extremadamente rápido.
* El **`ANALYZE`** asegura que Postgres sepa cuántas filas hay exactamente en la nueva estructura para elegir los mejores planes de ejecución.
---


# Por qué VACUUM  si llena el mapa de visibilidad ?

 Para entenderlo, hay que ver al **`VACUUM`** no solo como un "limpiador", sino como un **"auditor"**.

La razón técnica es que el **Visibility Map (VM)** es, por definición, un **producto del escaneo de limpieza**. Aquí te explico el porqué paso a paso:
 

## 1. El `VACUUM` es el único que "revisa" toda la página

Cuando ejecutas un `VACUUM` estándar, el motor recorre cada página (bloque) de la tabla buscando "filas muertas" (dead tuples). Durante ese recorrido, Postgres aprovecha para hacer una validación lógica:

1. **Analiza cada fila:** Mira los identificadores de transacción ( y ) de cada registro en el bloque.
2. **Pregunta:** "¿Hay alguna fila aquí que sea invisible para alguien o que sea basura?"
3. **Conclusión:** Si la respuesta es **"No, todas las filas son visibles para todas las transacciones actuales y futuras"**, entonces el `VACUUM` tiene la autoridad para decir: *"He auditado este bloque y está limpio"*.
4. **Acción:** En ese preciso momento, escribe un **bit** en el archivo `.vm` (el Visibility Map) marcando esa página como `all_visible`.

 
 
## 2. ¿Por qué otros procesos NO lo llenan?

### El caso del `INSERT`

Cuando insertas datos, Postgres solo escribe. No puede marcar la página como "All-Visible" porque:

* **Transacciones concurrentes:** La fila que acabas de insertar **no es visible** para las transacciones que empezaron antes que la tuya. Por lo tanto, el bloque *no es* "visible para todos".
* **Rendimiento:** Sería carísimo que cada `INSERT` tuviera que bloquear y actualizar un archivo auxiliar (el VM).

### El caso del `VACUUM FULL`

Aunque `VACUUM FULL` lee y escribe los datos, su objetivo es la **compactación física**.

* Internamente, `VACUUM FULL` mueve filas de un lugar a otro para eliminar huecos.
* Postgres está diseñado de forma modular: el código que "mueve y compacta" (Full) es distinto al código que "audita visibilidad" (estándar).
* Al terminar el `FULL`, la tabla es técnicamente "nueva". Postgres prefiere que sea el proceso de `VACUUM` normal el que haga la auditoría oficial de visibilidad una vez que la tabla ya está asentada.
 

## 3. El VM es una herramienta "PARA" el VACUUM

Aquí está el secreto mejor guardado: **El Visibility Map se creó principalmente para que el `VACUUM` trabaje menos en el futuro.**

Es un círculo virtuoso:

1. El **primer `VACUUM**` hace el trabajo pesado: escanea todo y llena el mapa.
2. El **segundo `VACUUM**` consulta el mapa antes de empezar.
3. Si el mapa dice que el bloque es `all_visible`, el `VACUUM` **se salta ese bloque** y no gasta recursos leyéndolo.

> **En resumen:** El `VACUUM` llena el mapa porque es el único proceso que tiene la tarea de verificar la visibilidad de cada fila vieja. Es como un inspector que pone un sello de "Aprobado" en la puerta de una habitación; hasta que el inspector no entra y revisa, no se puede poner el sello.

 

### Un dato curioso para tu laboratorio:

Si haces un `INSERT` y esperas a que el **`autovacuum`** (el proceso automático de Postgres) pase por la tabla, verás que el mapa de visibilidad se llena "solo" sin que tú lances el comando. Esto es porque el `autovacuum` es, en esencia, un `VACUUM` estándar corriendo en segundo plano.
 
---

## 📊 14. Otros tipos de tools 

| Extensión        | Visibilidad | Espacio libre | Estadísticas |
| ---------------- | ----------- | ------------- | ------------ |
| pg\_visibility   | ✅           | ❌             | ❌            |
| pgstattuple      | ❌           | ✅             | ✅            |
| pg\_freespacemap | ❌           | ✅             | ❌            |
| pg_stat_user_tables |            |              |             |


 

## 📚 15. Bibliografía

*   <https://www.postgresql.org/docs/current/pgvisibility.html>
*   <https://www.cybertec-postgresql.com/en/pg_visibility-extension/>

