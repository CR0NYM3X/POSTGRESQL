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

# Vacuum valida fila por fila ?

Para que PostgreSQL pueda decir con total seguridad que una página (un bloque de 8KB) es "All-Visible", no tiene más remedio que inspeccionar lo que hay dentro, fila por fila.

Aquí te explico cómo ocurre esa "inspección" técnica y por qué es necesaria:

### 1. El escaneo de los IDs de Transacción ( y )

Cada fila (tuple) en Postgres tiene dos etiquetas ocultas fundamentales para la visibilidad:

* : El ID de la transacción que **creó** la fila.
* : El ID de la transacción que **borró o actualizó** la fila (si está en 0, la fila no ha sido borrada).

Cuando el `VACUUM` entra en una página, actúa como un auditor de impuestos:

1. Mira la **Fila A**: "¿Quién te creó? ¿La transacción que te creó ya terminó y es visible para todos?".
2. Mira la **Fila B**: "¿Alguien te borró? Si te borraron, ¿esa transacción ya es tan vieja que nadie te necesita?".
3. **La Condición:** Si el `VACUUM` termina de revisar todas las filas de la página y confirma que **absolutamente todas** son visibles para cualquier transacción actual o futura (y no hay "basura" o versiones muertas), entonces marca la página en el mapa.

### 2. El "Sello" en el Visibility Map

Solo cuando ese escaneo fila por fila termina con éxito para esa página, el `VACUUM` hace dos cosas:

* En la **cabecera de la página física** (`PageHeader`), activa el bit `pd_all_visible`.
* En el **archivo del Visibility Map** (`_vm`), activa el bit correspondiente a ese bloque.

### 3. ¿Por qué es tan importante que sea fila por fila?

Imagina que en una página de 80 filas, 79 son visibles para todos, pero hay **una sola fila** que acaba de ser insertada por una transacción que aún no hace `COMMIT`.

* Si Postgres marcara la página como "All-Visible" sin revisar esa fila, otra consulta podría intentar un **Index-Only Scan**, ver la página marcada como "segura" y leer esa fila que aún no debería ser visible, rompiendo la integridad de la base de datos (**Lectura Sucia**).

### 4. La gran excepción: ¿Cuándo NO valida fila por fila?

Aquí es donde el Visibility Map se vuelve "mágico". En los **siguientes** procesos de `VACUUM` (después del primero que hiciste en tu laboratorio):

* El `VACUUM` llega a la tabla.
* Primero lee el Visibility Map.
* Si el mapa dice que el Bloque #1 es `all_visible`, el `VACUUM` **se salta ese bloque por completo**.
* **¡Ya no valida fila por fila!** Confía en el mapa y ahorra muchísimo trabajo de disco y CPU.

--- 


# Hacer una modificacion despues del primer vacuum que pasa? 

Esa es la pregunta clave que revela la genialidad detrás del diseño de PostgreSQL. Si el `VACUUM` saltara bloques a ciegas sin importar que los datos cambiaron, la base de datos se corrompería rápidamente.

La respuesta es: **El Visibility Map (VM) no es estático; se "ensucia" (se resetea) en tiempo real.**

Aquí te explico el proceso exacto de qué pasa cuando modificas un dato después de que el mapa ya estaba en `true`.
 

### 1. El mecanismo de "Limpieza de Bits" (Bit Clearing)

En el momento exacto en que tú ejecutas un `UPDATE` o un `DELETE` en una fila, PostgreSQL realiza una operación interna crítica:

1. **Localización:** El motor identifica en qué bloque (página) vive la fila que vas a modificar.
2. **Reset inmediato:** Antes de escribir el cambio, el motor **apaga los bits** `all_visible` y `all_frozen` de ese bloque específico en el Visibility Map.
3. **Cambio a False:** El estado del bloque en el mapa pasa de `t` (true) a `f` (false) instantáneamente.
 
### 2. ¿Por qué ocurre esto al modificar?

Recuerda que en PostgreSQL, un `UPDATE` no sobrescribe el dato viejo. Lo que hace es:

* Marcar la fila vieja como **muerta** (invisible para futuras transacciones).
* Insertar una **fila nueva** con los datos actualizados.

En ese instante, la página ya no es "totalmente visible para todos" porque contiene una "fila muerta" (basura/bloat) que solo el `VACUUM` puede ver y limpiar. Por seguridad, Postgres marca el bloque como "sucio" en el mapa para avisarle al siguiente `VACUUM`: *"Oye, aquí pasó algo, ya no puedes saltarte esta página; tienes que entrar y revisar fila por fila"*.
 

### 3. El ciclo de vida del bloque (Ejemplo práctico)

Imagina tu tabla `produccion_diaria` con sus 6 bloques:

| Evento | Estado del Bloque #1 en el VM | Comportamiento del VACUUM |
| --- | --- | --- |
| **Después del 1er VACUUM** | `t` (All-Visible) | El siguiente VACUUM lo saltaría. |
| **Haces un UPDATE en el Bloque #1** | **`f` (Sucio)** | El bit se apaga automáticamente al modificar. |
| **Llega el 2do VACUUM** | `f` (False) | **Entra al bloque**, limpia la fila muerta del UPDATE. |
| **Al terminar ese 2do VACUUM** | **`t` (All-Visible)** | Vuelve a poner el bit en `true` porque ya limpió. |

 
### 4. ¿Qué pasa con las lecturas (Index-Only Scans)?

Esto también afecta a las consultas. Si el bit en el VM es `false`:

* Postgres ya no puede confiar solo en el índice.
* La consulta se ve obligada a ir a la tabla física (el Heap) para verificar si la fila que encontró es la versión nueva o la vieja.

Por eso, una base de datos con muchas actualizaciones constantes suele tener un Visibility Map con muchos `false`, lo que hace que las consultas sean un poco más pesadas que en una tabla que es solo de lectura (donde casi todo es `true`).

 

### Resumen: La seguridad ante todo

PostgreSQL prefiere **ser lento pero seguro**. En cuanto hay una mínima sospecha de que una página ha cambiado (un `INSERT`, `UPDATE` o `DELETE`), el bit del Visibility Map se apaga. Solo el `VACUUM` (manual o automático) tiene el "poder" de volver a encenderlo después de inspeccionar la página fila por fila.

 ---

# Laboratorio revisando la visibilidad de otra forma 
```sql

postgres@test# CREATE EXTENSION pageinspect;
ERROR:  extension "pageinspect" already exists
Time: 0.962 ms
postgres@test# drop table ventas ;
DROP TABLE
Time: 11.493 ms
postgres@test#
postgres@test#
postgres@test# CREATE TABLE ventas (
test(#     id SERIAL PRIMARY KEY,
test(#     producto TEXT
test(# );
CREATE TABLE
Time: 6.114 ms
postgres@test#
postgres@test# INSERT INTO ventas (producto) VALUES ('Producto A'), ('Producto B');
INSERT 0 2
Time: 1.535 ms
postgres@test#
postgres@test#
postgres@test# SELECT lp, t_xmin, t_xmax, t_ctid
test-# FROM heap_page_items(get_raw_page('ventas', 0));
+----+--------+--------+--------+
| lp | t_xmin | t_xmax | t_ctid |
+----+--------+--------+--------+
|  1 |   2822 |      0 | (0,1)  |
|  2 |   2822 |      0 | (0,2)  |
+----+--------+--------+--------+
(2 rows)

Time: 1.133 ms
postgres@test#
postgres@test#
postgres@test# BEGIN;
BEGIN
Time: 0.180 ms
postgres@test#* DELETE FROM ventas WHERE id = 1;
DELETE 1
Time: 0.334 ms
postgres@test#* -- No hacemos COMMIT todavía
postgres@test#*
postgres@test#*
postgres@test#* SELECT lp, t_xmin, t_xmax, t_ctid
test-*# FROM heap_page_items(get_raw_page('ventas', 0));
+----+--------+--------+--------+
| lp | t_xmin | t_xmax | t_ctid |
+----+--------+--------+--------+
|  1 |   2822 |   2823 | (0,1)  |
|  2 |   2822 |      0 | (0,2)  |
+----+--------+--------+--------+
(2 rows)

Time: 0.353 ms
postgres@test#*
postgres@test#*
postgres@test#*
postgres@test#*
postgres@test#* SELECT lp,
test-*#        pg_visible_in_snapshot(t_xmin::text::xid8, pg_current_snapshot()) AS xmin_visible,
test-*#        pg_visible_in_snapshot(t_xmax::text::xid8, pg_current_snapshot()) AS xmax_visible
test-*# FROM heap_page_items(get_raw_page('ventas', 0));
+----+--------------+--------------+
| lp | xmin_visible | xmax_visible |
+----+--------------+--------------+
|  1 | t            | f            |
|  2 | t            | t            |
+----+--------------+--------------+
(2 rows)

Time: 0.465 ms
postgres@test#* commit;
COMMIT
Time: 1.399 ms
postgres@test#
postgres@test# SELECT lp,
test-#        pg_visible_in_snapshot(t_xmin::text::xid8, pg_current_snapshot()) AS xmin_visible,
test-#        pg_visible_in_snapshot(t_xmax::text::xid8, pg_current_snapshot()) AS xmax_visible
test-# FROM heap_page_items(get_raw_page('ventas', 0));
+----+--------------+--------------+
| lp | xmin_visible | xmax_visible |
+----+--------------+--------------+
|  1 | t            | t            |
|  2 | t            | t            |
+----+--------------+--------------+
(2 rows)

Time: 0.442 ms
postgres@test#

```
---


Para que PostgreSQL marque una página como **All-Visible**, el proceso de `VACUUM` debe realizar una auditoría técnica basada en el **MVCC (Multiversion Concurrency Control)**.

No basta con que los datos estén "ahí"; el motor debe garantizar que **ninguna** transacción (actual o futura) verá algo distinto en esa página. Aquí tienes el proceso paso a paso:

 
## 1. El Horizonte de Visibilidad (`OldestXmin`)

Antes de empezar, PostgreSQL calcula un valor llamado **`OldestXmin`**.

* Este es el ID de la transacción más antigua que todavía está activa en la base de datos.
* Cualquier transacción con un ID menor a este ya terminó (se hizo `COMMIT` o `ROLLBACK`) y es considerada "pasado histórico" para todos.

## 2. Las 3 Reglas de Oro en la Página

Cuando el `VACUUM` escanea una página de 8KB, revisa cada **Tuple** (fila) y valida que cumpla simultáneamente estas tres condiciones:

1. **Inserción Confirmada:** El  (quien creó la fila) debe estar marcado como **completado** en el CLOG (*Commit Log*) y debe ser **menor** que el `OldestXmin`.
2. **Sin Borrados Pendientes:** El  (quien borró la fila) debe ser **cero** o estar marcado como **abortado**. Si hay un  de una transacción que hizo `COMMIT`, esa fila es "basura" (dead tuple), y la página **no** puede ser All-Visible hasta que el `VACUUM` elimine físicamente ese espacio.
3. **Sin Versiones Intermedias:** No debe haber ninguna fila en la página que sea una "versión vieja" de un `UPDATE` que todavía sea necesaria para alguna transacción lenta.

## 3. La consulta al CLOG (Commit Log)

Postgres no confía solo en lo que dice la tabla. Para cada  y  que encuentra, hace una búsqueda ultrarrápida en el **CLOG** (ubicado en `pg_xact`).

* El CLOG es un mapa de bits que le dice: `Transacción 101 -> COMMIT`, `Transacción 102 -> ABORT`.
* Si todas las filas de la página apuntan a transacciones con `COMMIT` y son más antiguas que el horizonte de visibilidad, la página es "segura".



## 4. El Sello Final: `PD_ALL_VISIBLE`

Si la página pasa la auditoría de todas sus filas, PostgreSQL realiza dos acciones de escritura:

1. **En el Header de la página:** En los primeros bytes del bloque físico (el `PageHeaderData`), activa un bit llamado `PD_ALL_VISIBLE`. Este bit es la fuente de verdad física.
2. **En el Visibility Map (VM):** Actualiza el archivo auxiliar `_vm` poniendo un `1` en la posición de ese bloque. Esto es lo que permite que los **Index-Only Scans** funcionen sin leer la tabla.

> **Dato Clave:** Si una página está vacía (no tiene filas), PostgreSQL también la marca como **All-Visible**, ya que, técnicamente, "todo lo que hay" (nada) es visible para todos.



## ¿Qué pasa si una sola fila falla?

Si en una página de 200 filas, **199 son visibles** pero **1 fila** fue insertada hace un milisegundo por una transacción que sigue abierta:

* El `VACUUM` detecta que esa fila tiene un  mayor al `OldestXmin`.
* Por seguridad, **toda la página** se queda con el bit en `false`.
* El Visibility Map mostrará `f` para ese bloque.

---


PostgreSQL utiliza un sistema llamado **MVCC (Multiversion Concurrency Control)** para gestionar la visibilidad. A diferencia de otros motores que bloquean filas para lectura/escritura, Postgres mantiene múltiples versiones de una misma fila simultáneamente.

Aquí tienes el flujo detallado de cómo determina la visibilidad y cómo esto alimenta al **Visibility Map (VM)**.

---

## 1. Los metadatos de la fila (Heap Tuple Header)

Cada fila (tuple) en PostgreSQL tiene campos ocultos en su encabezado que son cruciales para la visibilidad:

* **`xmin`:** El ID de la transacción () que insertó la fila.
* **`xmax`:** El ID de la transacción que eliminó o actualizó la fila (si es `0`, la fila no ha sido tocada).
* **`t_ctid`:** Un puntero a la versión más reciente de la fila.
* **Hint Bits:** Marcadores que indican si la transacción `xmin` o `xmax` ya ha sido confirmada (`COMMITTED`) o abortada (`ABORTED`).

---

## 2. El proceso de verificación: Snapshot de Transacción

Cuando realizas una consulta, Postgres genera un **Snapshot** (una "foto" del estado de la base de datos). Este snapshot contiene:

1. **`xmin` (bajo):** Todas las transacciones menores a este ID ya están terminadas (visibles).
2. **`xmax` (alto):** Cualquier transacción igual o mayor a este ID aún no ha comenzado (invisible).
3. **`xip_list`:** Una lista de transacciones que están "en curso" en el momento del snapshot.

### Reglas lógicas de visibilidad:

Para que una fila sea visible para tu consulta, debe cumplir:

* El `xmin` debe estar **COMMITTED** (confirmado).
* El `xmin` no debe estar en la lista de transacciones activas (`xip_list`).
* El `xmax` debe ser **0**, estar **ABORTED**, o ser una transacción que aún no se confirma.

 

## 3. El Mapa de Visibilidad (Visibility Map - VM)

El **Visibility Map** es una estructura separada del archivo de datos principal (el *heap*). Almacena dos bits por cada página de datos:

1. **All-visible bit:** Si está activo, significa que todas las filas de esa página son visibles para todas las transacciones actuales y futuras (no hay versiones antiguas ni transacciones sin confirmar).
2. **All-frozen bit:** Si está activo, significa que todas las filas de la página están "congeladas" (ya fueron procesadas para evitar el *XID wraparound*).

 

## 4. El Flujo: ¿Cómo se llena el Visibility Map?

El llenado del mapa de visibilidad no ocurre en tiempo real durante cada `INSERT` o `UPDATE`, sino que es un proceso delegado principalmente al **VACUUM**.

### El proceso paso a paso:

1. **Operaciones de Escritura:** Cuando insertas o borras filas, Postgres marca los `xmin/xmax` en el heap. En este momento, el bit en el VM para esa página se **apaga** (se pone en 0), ya que la página ahora contiene cambios que no todos pueden ver.
2. **Ejecución de VACUUM (o Autovacuum):**
* El VACUUM escanea las páginas del heap.
* Comprueba si hay filas muertas (*dead tuples*) que puedan ser eliminadas.
* **Verificación de Visibilidad:** Si después de la limpieza, el VACUUM detecta que **todas** las filas de una página son lo suficientemente antiguas como para ser visibles para cualquier transacción activa (basándose en el *OldestXmin*), entonces...


3. **Actualización del VM:** El VACUUM marca el bit **All-visible** en el Visibility Map para esa página específica.
 

## 5. ¿Para qué sirve este flujo? (El beneficio real)

La razón principal por la que Postgres se esfuerza en mantener este mapa es el **Index-Only Scan**.

* **Sin VM:** Los índices no guardan información de visibilidad (`xmin/xmax`). Para saber si una fila encontrada en el índice es válida, Postgres tendría que ir siempre al *heap* (disco) a comprobar los headers.
* **Con VM:** Si el índice apunta a una página que en el VM está marcada como **All-visible**, Postgres confía en que la fila es visible y **no lee el heap**, ahorrando muchísimas operaciones de entrada/salida (I/O).
 

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

