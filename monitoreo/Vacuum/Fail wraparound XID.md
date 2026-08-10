## 🔄 ¿Qué es el "wraparound"?

El **wraparound** ocurre cuando el contador de XID **llega al límite máximo** y vuelve a empezar desde cero (como un odómetro que da la vuelta) y tiene un limite de .


$$
2^{32} = 4,294,967,296
$$

### ¿Por qué es peligroso?

Cuando el XID se reinicia:
- Las transacciones nuevas pueden tener un XID **menor** que las antiguas.
- PostgreSQL **ya no puede determinar correctamente la antigüedad de las filas**.
- Esto puede causar que el sistema **muestre datos incorrectos o incluso corrompa la base de datos y no utilice los datos en consultas**.

---

## 🧊 ¿Cómo se previene el wraparound?

PostgreSQL previene el wraparound mediante:

1. **Autovacuum con FREEZE**  
   Congela filas antiguas para que no necesiten ser comparadas con XIDs futuros.

2. **VACUUM FREEZE manual**  
   Se usa para congelar filas de forma proactiva, especialmente en tablas que no se actualizan.

3. **Monitoreo del `relfrozenxid` y su edad**  
   Cada tabla tiene un `relfrozenxid` que indica el XID más antiguo que ha sido congelado. Si su edad se acerca al límite, PostgreSQL lanza un `autovacuum` forzado.

---

## 📊 Ejemplo visual (simplificado)

Imagina que el XID es un reloj de 12 horas:

- Transacción 1 → XID 1  
- Transacción 2 → XID 2  
- ...  
- Transacción 12 → XID 12  
- Transacción 13 → XID 1 (¡wraparound!)

Ahora, si una fila fue creada por XID 10, y la transacción actual es XID 1 (después del wraparound), el sistema **cree erróneamente que XID 10 es más reciente**, lo cual **rompe la lógica de visibilidad**.

### 🔄 ¿Por qué se recomienda `VACUUM FREEZE` tanto en tablas que **no cambian frecuentemente** como en sistemas con **alta carga de escritura**?

La clave está en **el objetivo del `VACUUM FREEZE`**, que es **evitar el wraparound del Transaction ID (XID)**. Este problema puede ocurrir en **cualquier tipo de tabla**, pero los motivos para usar `FREEZE` varían según el contexto:

---

### 🧊 1. **Tablas que no cambian frecuentemente**
Estas tablas:
- No reciben escrituras nuevas.
- No se actualizan ni eliminan filas.
- Por lo tanto, **las filas nunca se congelan automáticamente**, porque no hay actividad que dispare un `VACUUM` regular.

➡️ **Riesgo**: Si no se ejecuta `VACUUM FREEZE`, esas filas pueden acumular XIDs antiguos y eventualmente causar problemas de wraparound.

✅ **Solución**: Ejecutar `VACUUM FREEZE` manualmente para congelar esas filas y evitar que el sistema tenga que revisarlas en el futuro.

---

### 🔥 2. **Sistemas con alta carga de escritura**
Estas tablas:
- Se actualizan y escriben constantemente.
- PostgreSQL ejecuta `autovacuum` frecuentemente para limpiar y congelar filas.

➡️ **Riesgo**: El sistema puede estar tan ocupado que el `autovacuum` no alcance a congelar todas las filas a tiempo, especialmente si hay picos de carga o si el `autovacuum` está mal configurado.

✅ **Solución**: Ejecutar `VACUUM FREEZE` de forma proactiva en momentos de baja carga para ayudar al sistema a mantenerse al día y evitar el wraparound.




Excelente pregunta. Vamos a desglosar qué es el **XID (Transaction ID)** y el problema del **wraparound** en PostgreSQL de forma clara y técnica.

---

## 🧾 ¿Qué es el XID (Transaction ID)?

En PostgreSQL, cada transacción recibe un **identificador único llamado XID** (Transaction ID). Este número se usa para:

- Controlar la visibilidad de las filas (MVCC).
- Saber qué transacción creó, modificó o eliminó una fila.
- Determinar si una fila es visible para una transacción actual.

El XID es un número entero de 32 bits, por lo tanto, tiene un **límite de aproximadamente 4,294,967,296 transacciones**.

 
 

## 🛡️ ¿Cómo saber si estás en riesgo?

Puedes ejecutar:

```sql
 
SELECT 
	datname, 	
	
FROM pg_database;

SELECT 
    datname AS db_name,
	txid_current()::int - datfrozenxid::text::int as edad_xid,  -- esto es lo mismo que hacer esto  age(datfrozenxid)    Si se acerca a 2,000,000,000 → riesgo de wraparound.
    ROUND(age(datfrozenxid) * 100.0 / 2000000000, 2) AS porcentaje_riesgo
FROM pg_database
ORDER BY porcentaje_riesgo DESC;




SELECT 
    c.oid::regclass AS tabla,
    age(c.relfrozenxid) AS edad_xid,
    ROUND(age(c.relfrozenxid) * 100.0 / 2000000000, 2) AS porcentaje_riesgo
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r' -- solo tablas
ORDER BY porcentaje_riesgo DESC
LIMIT 20;



SELECT xmin, xmax, pg_visible_in_snapshot(xmin, pg_current_snapshot()) AS visible
FROM cat_servidores
WHERE xmin IS NOT NULL
LIMIT 10;



-- datfrozenxid -> XID más antiguo que ha sido congelado en toda la base de datos.
-- txid_current() -> es un identificador que cada vez que haces una transacción, PostgreSQL te asigna un nuevo txid_current().

```
 

 
 ## ✅ ¿Qué hacer si el porcentaje es alto?

Si el porcentaje de riesgo supera el 70%, considera ejecutar:

```sql
VACUUM FREEZE nombre_tabla;
```

O para toda la base:

```bash
vacuumdb --freeze --all --verbose
```


 
## 🧠 ¿Por qué es importante el wraparound?

Porque si no se controla, puede llevar a **corrupción de datos**, **errores de visibilidad**, o incluso que PostgreSQL **detenga la base de datos** para protegerla.

 

## 🔥 ¿Qué problema puede causar el wraparound?

### 1. **Visibilidad incorrecta de datos**
PostgreSQL usa el XID para saber si una fila es visible para una transacción. Si el XID se reinicia (wraparound) y no se han congelado las filas antiguas:

- Las transacciones nuevas pueden tener XIDs **menores** que las antiguas.
- PostgreSQL **ya no puede saber si una fila es vieja o nueva**.
- Resultado: **datos incorrectos o inconsistentes**.

 

### 2. **Error crítico: "database is not accepting commands to avoid wraparound data loss"**

Si el sistema detecta que está cerca del límite y no se han congelado suficientes filas, PostgreSQL **entra en modo de emergencia**:

- Bloquea escrituras.
- Requiere un `VACUUM FREEZE` urgente.
- Puede afectar la disponibilidad de tu sistema.

 

### 3. **Corrupción silenciosa**

En el peor de los casos, si el wraparound ocurre sin protección:

- PostgreSQL puede **mostrar datos que no debería**.
- O **ocultar datos que sí deberían ser visibles**.
- Esto rompe el modelo MVCC y puede causar **pérdida de integridad**.

 

## 🧊 ¿Cómo se previene?

1. **Autovacuum con congelación automática**  
   Se activa cuando el `age(datfrozenxid)` se acerca a 200 millones.

2. **VACUUM FREEZE manual**  
   Útil en tablas que no se actualizan o en entornos de solo lectura.

3. **Monitoreo proactivo**  
   Revisar regularmente el `age(datfrozenxid)` y `relfrozenxid` en tablas grandes.



 

## 🧠 ¿Qué significa “visible” en términos técnicos?

Cada fila en PostgreSQL tiene dos campos internos:

- `xmin`: el XID de la transacción que **creó o modificó** la fila.
- `xmax`: el XID de la transacción que **eliminó o actualizó** la fila (si aplica).

Cuando una transacción intenta leer una fila, PostgreSQL **compara el XID actual con esos valores** para decidir si la fila debe ser visible o no.

---

## 📌 Ejemplo de visibilidad

Supón que:

- Fila A tiene `xmin = 100`
- Fila B tiene `xmin = 200`
- Tu transacción actual tiene `XID = 150`

### ¿Qué pasa?

- Fila A fue creada por una transacción **anterior** → ✅ **Visible**
- Fila B fue creada por una transacción **futura** → ❌ **No visible**

Esto es porque tu transacción **no debe ver cambios hechos por transacciones que aún no han sido confirmadas**.

---

## 🔍 ¿Cómo afecta esto a la lectura?

- Si una fila **no es visible**, PostgreSQL **la ignora** en la consulta.
- Esto garantiza **aislamiento** entre transacciones concurrentes.
- También permite **lecturas consistentes** sin bloquear escrituras.

---

## 🧊 ¿Y qué pasa con filas congeladas?

Cuando una fila es **congelada** (`xmin = FrozenTransactionId`), PostgreSQL **ya no necesita comparar XIDs**. La fila es **siempre visible** para cualquier transacción.

---

## ✅ En resumen

| Estado de la fila | ¿Es visible para la transacción actual? |
|-------------------|------------------------------------------|
| `xmin < XID actual` | ✅ Sí |
| `xmin > XID actual` | ❌ No |
| `xmin = FrozenTransactionId` | ✅ Siempre |

---

# Analogía  claras

### El Reloj Único vs. Los Múltiples Cronómetros

* **El Reloj Global:** PostgreSQL tiene un único contador (XID) que avanza con cada transacción en toda la instancia. El límite absoluto de este reloj es de **2,147,483,648** transacciones (2 mil millones). Si el reloj avanza 2 mil millones de tics desde tu transacción más antigua sin congelar, ocurre el desastre.
* **Los Cronómetros Individuales:** Como no puedes congelar la instancia entera de golpe, PostgreSQL le pone un "cronómetro" a cada tabla y a cada base de datos. Ese cronómetro guarda un "marcador": *"¿En qué número iba el reloj global cuando se modificó la fila no congelada más antigua de esta tabla?"*.

**La diferencia (`age`):** Lo que PostgreSQL vigila no es el número actual del reloj global, sino **la diferencia (la edad)** entre el número actual del reloj global y el marcador más antiguo de tus tablas.

*Ejemplo:*

* El reloj global va en la transacción **3,000,000,000**.
* El marcador de tu base de datos más vieja apunta a la transacción **2,800,000,000**.
* La edad (la diferencia) es de **200,000,000**. Estás lejos de los 2 mil millones. ¡Estás a salvo!

### ¿Cómo veo el límite y qué tan cerca estoy del colapso global?

Para ver exactamente cuánto "espacio" te queda antes de que tu instancia entera alcance el límite de los 2 mil millones de transacciones de diferencia, usa esta consulta:

```sql
SELECT 
    datname AS base_de_datos_con_tabla_mas_antigua,
    age(datfrozenxid) AS edad_maxima_actual,
    2147483648 AS limite_absoluto_wraparound,
    2147483648 - age(datfrozenxid) AS transacciones_restantes_hasta_colapso,
    round((age(datfrozenxid)::numeric / 2147483648::numeric) * 100, 2) AS porcentaje_consumido_del_limite
FROM pg_database
ORDER BY edad_maxima_actual DESC
LIMIT 1;

```

**Cómo leer el resultado:**

* **`edad_maxima_actual`:** La diferencia de transacciones entre el reloj actual de la instancia y la fila más vieja (no congelada) de todo tu servidor.
* **`limite_absoluto_wraparound`:** Los temidos 2 mil millones (límite físico de PostgreSQL).
* **`transacciones_restantes_hasta_colapso`:** Cuántas transacciones `INSERT`/`UPDATE`/`DELETE` puedes hacer en **cualquier** base de datos de esta instancia antes de que el servidor se apague por seguridad.
* **`porcentaje_consumido_del_limite`:**
* **0% a 10%:** Estado normal y saludable. El *AutoVacuum* hará su trabajo de emergencia mucho antes de que esto suba.
* **> 95%:** Tienes un problema grave. El *AutoVacuum* probablemente esté atorado, fallando o bloqueado por consultas largas, impidiendo el proceso de congelamiento.



### ¿Por qué la instancia colapsa por culpa de una sola tabla?

Imagina que el *AutoVacuum* falla y nunca logra limpiar la tabla de "Países" en la Base de Datos B, que tiene un marcador en la transacción **1,000,000**.

La Base de Datos A (tu tienda online) sigue operando y haciendo millones de transacciones diarias. El reloj global avanza: **2,000,000,000**, luego **2,100,000,000**...

La distancia (la edad) entre el reloj actual y la tabla de "Países" de la Base de Datos B empieza a acercarse a los 2 mil millones.

Si el reloj global llega a la transacción **2,147,483,648** (los 2 mil millones exactos de diferencia), la instancia **completa** dejará de aceptar comandos de escritura. **No importará si el 99% de tus bases de datos están limpias.** Una sola tabla sucia con una edad al límite detendrá toda la instancia de PostgreSQL, porque si el motor permite que el reloj global dé un paso más, los datos de la tabla "Países" desaparecerían.


----


**Una vez que congelas (`FREEZE`) una tabla que nunca más va a recibir cambios, NO necesitas volver a hacerlo nunca más en la vida de esa tabla.** No importa si el contador se reinicia una, dos o cien veces.

Vamos a ver por qué ocurre esta "magia" y por qué una tabla estática congelada se vuelve verdaderamente inmortal.

 
### La Magia del "Frozen XID" (El número mágico)

Cuando ejecutas `VACUUM FREEZE` en una tabla estática, PostgreSQL no le pone a las filas el número de transacción actual de la instancia. Hace algo mucho más inteligente.

Reemplaza el número de transacción (XID) original de esas filas por un identificador especial llamado **`FrozenTransactionId`** (que internamente en el código de PostgreSQL siempre es el número `2`).

**¿Por qué el número 2 es tan especial?**
Las reglas internas de visibilidad de PostgreSQL tienen una excepción programada en el núcleo del motor:

* *"Si la fila tiene el número 2 (`FrozenTransactionId`), esta fila es **infinitamente antigua**."*
* *"No importa en qué número vaya el reloj actual. No importa si el reloj global acaba de reiniciarse por un Wraparound. Cualquier transacción, en cualquier línea temporal, SIEMPRE debe poder ver las filas con el número 2."*

### El Ciclo de Vida de tu Tabla Estática

Para que quede clarísimo en tu artículo, este es el flujo exacto de lo que ocurre:

1. **Año 2023:** Creas la tabla `historico_2023`, insertas 10 millones de filas. Esas filas reciben los números de transacción (ej. del `50,000` al `60,000`).
2. **Año 2024:** Sabes que nadie modificará jamás esa tabla. Ejecutas `VACUUM FREEZE historico_2023;` en un mantenimiento dominical.
3. **El Efecto:** PostgreSQL recorre las 10 millones de filas y les borra el XID original, estampándoles a todas el número mágico `2` (`FrozenTransactionId`).
4. **Año 2026:** Tu instancia está muy ocupada. El reloj global llega a los 2 mil millones de transacciones.
5. **El Reinicio (Wraparound):** El reloj global de tu instancia se reinicia y vuelve a empezar desde el principio.
6. **¿Qué pasa con `historico_2023`?** Absolutamente nada. Como sus filas tienen el número `2`, PostgreSQL sabe que siempre deben ser visibles. El *AutoVacuum* de emergencia revisa la tabla, ve que todo está marcado con `2`, la ignora en un milisegundo y sigue de largo.

### La Única Excepción (Cuándo SÍ tendrías que volver a congelar)

La inmortalidad de la tabla se rompe **si modificas los datos**.

Si en el año 2027 llega un requerimiento de negocio y ejecutas un `UPDATE` masivo o un `INSERT` sobre esa tabla `historico_2023`, las nuevas filas o las filas modificadas recibirán el número de transacción *actual* de la instancia (perdiendo su marca de `2`).

En ese momento, la tabla vuelve a estar sujeta al envejecimiento normal. Si no la vuelves a tocar, el *AutoVacuum* de emergencia eventualmente tendrá que despertar (quizás años después) para volver a congelar esas filas nuevas/modificadas.

### Conclusión para tu estrategia:

El `VACUUM FREEZE` manual en tablas históricas masivas y estáticas es **una vacuna de una sola dosis**. Lo aplicas una vez y el motor de base de datos puede dar la vuelta al reloj infinitas veces sin que esa tabla vuelva a causarte un problema de rendimiento o de Wraparound.



---


**"Si AutoVacuum se dispara por los cambios, y esta tabla estática tiene 0 cambios, entonces AutoVacuum nunca la tocará y mi servidor morirá por Wraparound"*.


### La doble personalidad del AutoVacuum

El demonio de *AutoVacuum* en realidad tiene dos modos de operar, con reglas completamente distintas:

1. **El modo "Limpieza" (Normal):** Se dispara por el volumen de cambios (`autovacuum_vacuum_scale_factor`). Aquí tienes razón, en tu tabla estática este modo **nunca** se va a ejecutar.
2. **El modo "Emergencia" (Anti-Wraparound):** Este modo **ignora por completo si la tabla tuvo cambios o no**. Su único disparador es la edad de la tabla (`autovacuum_freeze_max_age`, que por defecto son 200 millones de transacciones).

Cuando el reloj de tu instancia avanza y la distancia con esa tabla histórica llega a 200 millones, el AutoVacuum entra en modo emergencia. Dirá: *"No me importa que nadie haya modificado un solo registro aquí en 5 años. Esta tabla ya es demasiado vieja"*.

En ese momento, AutoVacuum iniciará automáticamente un proceso en segundo plano que escaneará esos millones de registros y los "congelará" (*freeze*). **No necesitas ejecutar un `VACUUM` manual para que esto suceda; PostgreSQL lo hace solo.**

 

### El verdadero problema de las tablas gigantes estáticas

Aunque PostgreSQL te salva la vida automáticamente, el escenario que describes tiene un efecto secundario muy doloroso.

Imagina que esa tabla tiene 500 millones de registros. Un martes a las 3:00 PM (hora pico de tu negocio), el contador llega a los 200 millones de diferencia. El AutoVacuum de emergencia se despierta y **comienza a leer 500 millones de filas de tu disco duro para congelarlas**.

Tu servidor sufrirá un pico masivo de lectura/escritura (I/O), los discos se saturarán y tu aplicación se volverá lentísima durante horas, todo porque el AutoVacuum decidió que era el momento de congelar la tabla histórica.

 

### Recomendaciones para este escenario (Como un DBA Senior)

Para lidiar con tablas históricas masivas, la estrategia no es rezar para que el AutoVacuum no impacte el rendimiento, sino **tomar el control**.

Aquí tienes las dos estrategias recomendadas:

#### Estrategia 1: El "Freeze" Proactivo (La Mejor Opción)

Si tú sabes como arquitecto que una tabla ya no va a recibir más cambios (por ejemplo, una tabla particionada llamada `ventas_2023` o un histórico de logs de hace 2 años), no esperes a que el AutoVacuum de emergencia se despierte en un mal momento.

En tu ventana de mantenimiento de fin de semana (domingo en la madrugada), ejecuta **una sola vez** este comando manualmente:

```sql
VACUUM FREEZE public.ventas_2023;

```

**¿Qué logras con esto?**
Le dices al motor que congele absolutamente todas las filas de esa tabla *ahora mismo*. Como lo haces en la madrugada, el impacto masivo en disco no afectará a los usuarios. Una vez que la tabla está 100% congelada, su "edad" baja a cero y el AutoVacuum de emergencia **no volverá a molestarla en la vida** (o al menos hasta dentro de 2 mil millones de transacciones).

#### Estrategia 2: Afinar el impacto del AutoVacuum

Si no quieres hacerlo manual y prefieres que PostgreSQL se encargue, debes asegurarte de que cuando el AutoVacuum de emergencia despierte, no asfixie tus discos.

Para eso, debes ajustar el "acelerador/freno" del AutoVacuum en tu archivo `postgresql.conf`:

```ini
# Hace que el AutoVacuum trabaje más lento, tomando pausas, 
# para no consumir todo el I/O del disco y dejar que tus SELECTs fluyan.
autovacuum_vacuum_cost_delay = 20ms 

```

### En resumen para tu artículo

* **¿El AutoVacuum olvida las tablas estáticas?** No. Tiene un límite de seguridad (por defecto 200 millones) donde obligatoriamente las escanea y congela para evitar el colapso, sin importar que no tengan cambios.
* **¿Necesitas ejecutar `VACUUM` manual diario?** No.
* **La mejor práctica:** Si sabes que una tabla gigante es un archivo histórico inmutable, adelántate. Ejecuta `VACUUM FREEZE` manual durante una ventana de mantenimiento. Es un esfuerzo pesado de una sola vez que te garantiza paz mental y estabilidad en el servidor por años.








### Links 
```

Anatomía de Bajo Nivel #3 : La Estructura de una Transacción (xact).md -> https://github.com/CR0NYM3X/POSTGRESQL/blob/f08bb3b5536af160eae9b84846ff6f5a1c582f61/Post/Anatom%C3%ADa%20de%20Bajo%20Nivel%20%233%20%3A%20La%20Estructura%20de%20una%20Transacci%C3%B3n%20(xact).md

3. Peligro de Wraparound (Edad de Transacciones) -> https://github.com/CR0NYM3X/POSTGRESQL/blob/f08bb3b5536af160eae9b84846ff6f5a1c582f61/monitoreo/Mantenimientos.md#3-peligro-de-wraparound-edad-de-transacciones


https://medium.com/@pawanpg0963/what-is-transaction-wraparound-in-postgresql-91c972266780
```
