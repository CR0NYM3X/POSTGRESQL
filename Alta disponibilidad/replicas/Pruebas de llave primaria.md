

## 🏗️ Fase 0: Creación del Laboratorio (Simulación de Producción)

Ejecuta este bloque para crear la tabla original (sin la columna `idx`) e insertar los datos masivos iniciales.

```sql
-- 1. Creamos la tabla tal como la tenías, sin la columna de Clave Primaria aún.
CREATE TABLE public.his_articulos (
    numarea smallint NOT NULL DEFAULT 0,
    numdepto smallint NOT NULL DEFAULT 0,
    numclase smallint NOT NULL DEFAULT 0,
    numfamilia smallint NOT NULL DEFAULT 0,
    numcodigo integer NOT NULL DEFAULT 0,
    modelo character varying(35) NOT NULL DEFAULT 0,
    nummarca smallint NOT NULL DEFAULT 0,
    nomarticulo character varying(120) NOT NULL DEFAULT ''::character varying,
    descarticulo text NOT NULL DEFAULT ''::text,
    fechaalta timestamp without time zone NOT NULL DEFAULT '1900-01-01 00:00:00'::timestamp without time zone,
    preciovntaint integer NOT NULL DEFAULT 0,
    preciovntafrontera integer NOT NULL DEFAULT 0,
    exclusivo smallint NOT NULL DEFAULT 0,
    publicar smallint NOT NULL DEFAULT 0,
    nuevo smallint NOT NULL DEFAULT 0
);

-- 2. Insertamos 100,000 registros ficticios para simular una tabla de producción activa
INSERT INTO public.his_articulos (
    numarea, numdepto, numclase, numfamilia, numcodigo, 
    modelo, nummarca, nomarticulo, descarticulo, 
    fechaalta, preciovntaint, preciovntafrontera, exclusivo, publicar, nuevo
)
SELECT 
    (random() * 9)::smallint, 
    (random() * 99)::smallint, 
    (random() * 50)::smallint, 
    (random() * 20)::smallint, 
    (g.id)::integer, 
    'Mod-' || (random() * 1000)::int, 
    (random() * 10)::smallint, 
    'Articulo de Prueba Nro ' || g.id, 
    'Descripcion detallada para el articulo de prueba con identificador unico ' || g.id, 
    NOW() - (random() * INTERVAL '365 days'), 
    (random() * 5000 + 100)::integer, 
    (random() * 4500 + 100)::integer, 
    0, 1, 0
FROM generate_series(1, 100000) AS g(id);

```

---

## 📋 Estrategia Base: Las 3 Reglas de Oro en Producción

1. **Evitar el `ACCESS EXCLUSIVE LOCK`:** Este bloqueo (provocado por `ALTER TABLE ... ADD COLUMN NOT NULL` o `CREATE INDEX` normal) congela las lecturas y escrituras. Usaremos alternativas concurrentes o en fases.
2. **Controlar los Tiempos de Bloqueo (`lock_timeout`):** Si una sentencia de alteración se queda esperando en la cola de bloqueos, bloqueará todas las consultas que vengan detrás de ella. Configuraremos un límite de espera estricto.
3. **Controlar el Historial de Transacciones:** Las transacciones largas de otros procesos (como reportes o backups) impiden que las alteraciones concurrentes finalicen. Hay que monitorearlas.

---

## 🔄 El Flujo Profesional de 5 Fases (Ejecución del Plan Estratégico)

### Fase 1: Preparación de la Sesión y Columna Segura

Primero, nos aseguramos de que el script no tumbe la base de datos si se queda esperando un bloqueo. Creamos la columna permitiendo valores nulos. Como la tabla ya tiene los registros del laboratorio, **hacerlo con `NULL` toma menos de 1 milisegundo** y no bloquea a los usuarios.

```sql
-- 1. Si el comando no consigue el bloqueo en 2 segundos, aborta en lugar de encolar y congelar la app.
SET lock_timeout = '2s';

-- 2. Habilitamos el cronómetro de psql para medir tiempos exactos
\timing on

-- 3. Agregamos la columna permitiendo NULL (Operación instantánea en tablas con millones de registros)
ALTER TABLE public.his_articulos ADD COLUMN idx BIGINT;

```

### Fase 2: Creación de la Secuencia y Vinculación

Simulamos el comportamiento de un `BIGSERIAL` manualmente para tener control absoluto. En este punto, la secuencia empieza en `1`, pero los 100,000 registros existentes siguen teniendo valor `NULL`. Los nuevos `INSERT` que hagan tus usuarios a partir de este segundo ya empezarán a tomar números autoincrementales automáticamente.

```sql
-- 1. Creamos la secuencia de forma independiente
CREATE SEQUENCE public.his_articulos_idx_seq;

-- 2. Asociamos la secuencia como valor por defecto para los futuros INSERTS
ALTER TABLE public.his_articulos ALTER COLUMN idx SET DEFAULT nextval('public.his_articulos_idx_seq');

-- 3. Hacemos que la secuencia pertenezca a la columna (para borrados en cascada limpios)
ALTER SEQUENCE public.his_articulos_idx_seq OWNED BY public.his_articulos.idx;

```

### Fase 3: Poblado de Datos del Pasado en Lotes (Batches)

Aquí es donde manejamos los registros que ya existían. Para evitar bloquear la tabla completa por mucho tiempo, actualizamos en **bloques pequeños (ej. de 5,000 en 5,000)** utilizando el identificador físico `ctid` de Postgres. Esto permite que la aplicación siga operando normalmente entre lote y lote.

```sql
DO $$
DECLARE
    filas_afectadas INT;
    iteracion INT := 1;
BEGIN
    LOOP
        -- Actualiza solo un bloque de 5,000 registros que tengan el valor NULL del pasado
        UPDATE public.his_articulos 
        SET idx = nextval('public.his_articulos_idx_seq')
        WHERE idx IS NULL
        AND ctid IN (
            SELECT ctid FROM public.his_articulos WHERE idx IS NULL LIMIT 5000
        );
        
        -- Obtenemos cuántas filas se actualizaron en este lote
        GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
        
        -- Si ya no quedan filas con NULL (ya se actualizaron los 100,000), salimos del bucle
        IF filas_afectadas = 0 THEN
            RAISE NOTICE '¡Finalizado! Todos los registros antiguos fueron poblados.';
            EXIT;
        END IF;
        
        -- Mensaje de progreso cada 5 lotes
        IF iteracion % 5 = 0 THEN
            RAISE NOTICE 'Lote % completado...', iteracion;
        END IF;
        
        iteracion := iteracion + 1;
        
        -- Dejamos respirar a la base de datos 1 segundo entre lotes para evitar saturar el disco
        PERFORM pg_sleep(1);
    END LOOP;
END $$;

```

### Fase 4: Indexación Concurrente (Cero Bloqueo de Escritura)

Ahora que todos los registros viejos y los nuevos tienen un número asignado, creamos el índice único de fondo. Usamos `CONCURRENTLY`. **Tu terminal se quedará esperando (parecerá congelada)** mientras lee las filas y valida transacciones, pero la base de datos sigue respondiendo al 100% en otras conexiones.

```sql
-- ¡Ojo! CREATE INDEX CONCURRENTLY no puede ejecutarse dentro de un bloque de transacción (BEGIN/COMMIT). 
-- Ejecútalo suelto en tu consola de psql.
CREATE UNIQUE INDEX CONCURRENTLY his_articulos_pk_idx ON public.his_articulos (idx);

```

### Fase 5: Aplicar Restricciones Finales de Forma Segura

Ya tenemos los datos al día y el índice creado sin interrumpir el servicio. Ahora convertimos ese índice en la Llave Primaria oficial (operación instantánea porque el índice ya está construido) y aplicamos el `NOT NULL` usando una restricción de tipo `CHECK` con `NOT VALID` para que Postgres no tenga que volver a bloquear la tabla para validar los registros del pasado.

```sql
SET lock_timeout = '2s';

-- 1. Vinculamos el índice concurrente como la PRIMARY KEY (Operación de milisegundos)
ALTER TABLE public.his_articulos 
    ADD CONSTRAINT his_articulos_cnst_pkey PRIMARY KEY USING INDEX his_articulos_pk_idx;

-- 2. Forzamos el NOT NULL mediante un CHECK que no bloquee los datos del pasado
ALTER TABLE public.his_articulos 
    ADD CONSTRAINT idx_not_null CHECK (idx IS NOT NULL) NOT VALID;

-- 3. Validamos el CHECK en segundo plano (Recorre las filas validando, pero de forma segura sin bloquear lecturas/escrituras)
ALTER TABLE public.his_articulos VALIDATE CONSTRAINT idx_not_null;

```

---

## 🛠️ ¿Cómo monitorear el progreso del laboratorio?

Mientras ejecutas la **Fase 4** en tu terminal principal, puedes abrir una segunda consola de `psql` conectada a `tiendavirtual` y correr la siguiente query para comprobar cómo el proceso avanza en segundo plano:

```sql

--- 
SELECT 
    p.pid,
    a.query_start AS inicio,
    age(clock_timestamp(), a.query_start) AS tiempo_corriendo,
    p.phase AS fase_actual,
    p.blocks_done,
    p.blocks_total,
    round(100.0 * p.blocks_done / nullif(p.blocks_total, 0), 2) AS porcentaje_progreso,
    a.query
FROM 
    pg_stat_progress_create_index p
JOIN 
    pg_stat_activity a ON p.pid = a.pid;


--- Ver el espacio
SELECT 
    nspname AS esquema,
    relname AS tabla,
    pg_size_pretty(pg_table_size(c.oid)) AS espacio_datos_y_toast,
    pg_size_pretty(pg_indexes_size(c.oid)) AS espacio_indices,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS espacio_total,
    pg_relation_size(c.oid) AS bytes_datos_puros -- Util para ordenamiento numerico
FROM 
    pg_class c
JOIN 
    pg_namespace n ON n.oid = c.relnamespace
WHERE 
    c.relkind = 'r' 
    AND c.relname = 'his_articulos' -- Aqui filtras tu tabla
    AND n.nspname = 'public';


```


# Pruebas 
 
### Prueba 1: Intentar saltarse la restricción `NOT NULL`

Este `INSERT` intenta forzar un valor `NULL` en la columna `idx`. La base de datos debe rechazarlo inmediatamente gracias a la restricción `CHECK (idx IS NOT NULL)` que validamos en la Fase 5.

```sql
INSERT INTO public.his_articulos (
    numarea, numdepto, numclase, numfamilia, numcodigo, 
    modelo, nummarca, nomarticulo, descarticulo, 
    fechaalta, idx
) VALUES (
    1, 10, 5, 2, 999999, 
    'Mod-Test-Null', 1, 'Articulo Intento Null', 'Debe fallar por restriccion NOT NULL', 
    NOW(), NULL -- <-- Aquí forzamos el NULL
);

```

**Resultado esperado:**

> `ERROR: new row for relation "his_articulos" violates check constraint "idx_not_null"`

---

### Prueba 2: Intentar insertar un valor duplicado

Este caso simula un escenario donde intentamos insertar manualmente un `idx` que ya existe (por ejemplo, el número `1`, que ya fue asignado a los registros del pasado en la Fase 3). La base de datos debe bloquearlo gracias al índice único que asociamos a la `PRIMARY KEY`.

```sql
INSERT INTO public.his_articulos (
    numarea, numdepto, numclase, numfamilia, numcodigo, 
    modelo, nummarca, nomarticulo, descarticulo, 
    fechaalta, idx
) VALUES (
    1, 10, 5, 2, 888888, 
    'Mod-Test-Dup', 1, 'Articulo Intento Duplicado', 'Debe fallar por llave primaria duplicada', 
    NOW(), 1 -- <-- Forzamos el ID 1 que ya existe
);

```

**Resultado esperado:**

> `ERROR: duplicate key value violates unique constraint "his_articulos_pk_idx"`
> `DETAIL: Key (idx)=(1) already exists.`

---

### Prueba 3: Probar el comportamiento normal (Autoincremental exitoso)

Para confirmar que el comportamiento tipo `BIGSERIAL` funciona de manera transparente para tu aplicación o para **pglogical**, haz un insert **omitiendo por completo** la columna `idx`. El sistema debe asignarle el siguiente número de secuencia disponible sin rechistar.

```sql
INSERT INTO public.his_articulos (
    numarea, numdepto, numclase, numfamilia, numcodigo, 
    modelo, nummarca, nomarticulo, descarticulo, 
    fechaalta
) VALUES (
    2, 20, 8, 4, 777777, 
    'Mod-OK', 3, 'Articulo Correcto Autoincremental', 'Debe insertarse correctamente', 
    NOW()
) RETURNING idx, nomarticulo; -- Nos devuelve el ID generado automáticamente

```

**Resultado esperado:**

> La fila se inserta con éxito y te devolverá el `idx` correspondiente (ej. `100001` si tenías 100k registros previos).

---

### Prueba 4: Inserción manual permitida (Crucial para pglogical)

Durante la replicación con **pglogical**, los datos llegarán desde el nodo origen incluyendo su propio `idx`. Debemos comprobar que la tabla acepta valores manuales siempre y cuando **no estén duplicados**.

```sql
INSERT INTO public.his_articulos (
    numarea, numdepto, numclase, numfamilia, numcodigo, 
    modelo, nummarca, nomarticulo, descarticulo, 
    fechaalta, idx
) VALUES (
    3, 30, 9, 5, 666666, 
    'Mod-Manual', 4, 'Articulo con ID forzado no duplicado', 'Util para migraciones pglogical', 
    NOW(), 999999 -- <-- ID muy alto para no colisionar con la secuencia actual
);

```

**Resultado esperado:**

> `INSERT 0 1` (Se inserta correctamente conservando el ID `999999`).


---


¡Por supuesto! Vamos a estructurar esto como una sección formal de **Preguntas y Respuestas (Q&A)** técnica, recopilando los escenarios clave que hemos analizado para tu laboratorio y futura migración en producción.

---

## 📑 Sección de Preguntas y Respuestas: Operaciones Concurrentes en PostgreSQL

### 1. Si estoy haciendo un `UPDATE` masivo a la columna `idx` mediante un script o bloque `DO`, ¿puedo hacer modificaciones a OTRA columna de la misma tabla al mismo tiempo?

**Respuesta corta:** **Sí, pero con una condición crítica:** no puedes modificar las *mismas filas* que el proceso masivo tenga bloqueadas en ese instante.

**Explicación detallada:**
En PostgreSQL (y la mayoría de bases de datos relacionales), **los bloqueos por escritura se aplican a la fila completa (el registro), no a columnas individuales.**

* **Si intentas modificar una fila diferente:** Si tu aplicación hace un `UPDATE` en el precio de un artículo que el script masivo ya procesó (o que aún no ha tocado), la base de datos lo permitirá de inmediato.
* **Si intentas modificar la misma fila:** Si tu aplicación intenta actualizar cualquier columna de una fila que el script masivo está modificando en ese preciso milisegundo, la aplicación se quedará congelada (esperando) a que la transacción del script masivo termine y libere el registro.

> **⚠️ El peligro del bloque `DO`:** Como el bloque `DO $$` ejecuta todo en una sola transacción gigante, todas las filas que va modificando se quedan bloqueadas por *todo* el tiempo que dure el script (pueden ser minutos u horas). Por eso se recomienda usar scripts externos con commits cortos por cada lote.

---

### 2. Al ejecutar un `CREATE UNIQUE INDEX CONCURRENTLY`, ¿por qué PostgreSQL me permite hacer `UPDATE` en otras columnas mientras el comando corre?

**Respuesta corta:** Porque cambia radicalmente el tipo de bloqueo que solicita al motor, pasando de un bloqueo total a uno de fondo y de convivencia.

**Explicación detallada:**
Cuando creas un índice de forma normal (sin la palabra `CONCURRENTLY`), PostgreSQL cierra la tabla por completo usando un bloqueo exclusivo (`ShareLock`). Nadie puede modificar nada hasta que termine. Sin embargo, al usar `CONCURRENTLY`, las reglas del juego cambian:

* **Pide un bloqueo ultra ligero (`ShareUpdateExclusiveLock`):** Este bloqueo es tan amigable que no choca contra los `UPDATE`, `INSERT` o `DELETE`. Su única función es impedir que otra persona intente hacer otra alteración estructural en la tabla al mismo tiempo (como crear otro índice o borrar la tabla).
* **Trabaja con dos lecturas:** En lugar de adueñarse de la tabla, Postgres la recorre con calma dos veces para armar el índice de fondo, permitiendo que las consultas de producción sigan su curso normal.

En resumen, para tu aplicación y tus clientes, la base de datos seguirá respondiendo al 100%. Puedes modificar precios, nombres, textos o lo que quieras en cualquier fila y columna mientras el índice se construye en segundo plano.

---

### 3. ¿Qué es lo único que NO te dejará hacer la tabla mientras el índice `CONCURRENTLY` se está construyendo?

**Respuesta corta:** Cualquier operación que intente alterar la estructura física o lógica global de la tabla.

**Explicación detallada:**
Mientras tu terminal esté esperando a que finalice el `CREATE UNIQUE INDEX CONCURRENTLY` (es normal que se quede congelada temporalmente en primer plano), los siguientes comandos se quedarán encolados en espera absoluta:

* ❌ No podrás ejecutar un `ALTER TABLE` para agregar, renombrar o borrar columnas.
* ❌ No podrás ejecutar otro `CREATE INDEX` en la misma tabla.
* ❌ No podrás hacer un `DROP TABLE` o un `VACUUM FULL`.

---

### 4. ¿Qué sucede si cancelo con `Ctrl + C` el índice concurrente o el script de `UPDATE` a mitad del proceso?

**Respuesta corta:** El sistema garantiza la integridad de los datos, pero deja tareas de limpieza pendientes.

**Explicación detallada:**

* **En el `UPDATE` masivo (Bloque `DO`):** Como todo corre en una sola transacción, el `Ctrl + C` fuerza un `ROLLBACK`. La base de datos vuelve instantáneamente al estado exacto en el que estaba antes de que iniciaras el script (ningún `idx` se habrá guardado).
* **En el `CREATE INDEX CONCURRENTLY`:** Al cancelarlo, el índice no se borra solo; se queda guardado en los catálogos pero marcado como **`INVALID`**. Un índice inválido no sirve para tus consultas pero consume espacio. Si lo cancelas, debes ejecutar manualmente:
```sql
DROP INDEX CONCURRENTLY nombre_del_indice_pkey;

```


Y posteriormente volver a iniciar la creación.



----
---

# Script para insertar el valor de las secuencias
```SQL

CREATE OR REPLACE PROCEDURE public.poblar_idx_por_lotes(
    p_tabla_esquema TEXT,      -- Ejemplo: 'public.ctl_mensajeriaresponse'
    p_secuencia TEXT,          -- Ejemplo: 'public.ctl_mensajeriaresponse_idx_seq'
    p_tamano_lote INT,         -- Cantidad de filas por lote (ej. 5000)
    p_segundos_sleep NUMERIC,  -- Tiempo de espera entre lotes en segundos (ej. 1 o 0.5)
    p_mostrar_progreso BOOLEAN -- TRUE para ver RAISE NOTICE detallados, FALSE para modo silencioso
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_filas_afectadas INT;
    v_iteracion INT := 1;
    v_query_update TEXT;
    
    -- Variables para el control de tiempo
    v_tiempo_inicio TIMESTAMP;
    v_tiempo_fin TIMESTAMP;
    v_duracion INTERVAL;
    v_timestamp_lote TIMESTAMP;
    
    -- Variables para extraer esquema y tabla limpiamente
    v_esquema TEXT;
    v_tabla TEXT;
    v_pos_punto INT;
    
    -- Variables para almacenar tamaños de la tabla
    v_size_datos_ini TEXT;  v_size_datos_fin TEXT;
    v_size_idx_ini TEXT;    v_size_idx_fin TEXT;
    v_size_tot_ini TEXT;    v_size_tot_fin TEXT;
BEGIN
     set client_min_messages = NOTICE; 

    -- Validaciones iniciales de parámetros
    IF p_tamano_lote <= 0 THEN
        RAISE EXCEPTION 'El tamaño del lote debe ser mayor a 0.';
    END IF;
    
    IF p_segundos_sleep < 0 THEN
        RAISE EXCEPTION 'El tiempo de pg_sleep no puede ser negativo.';
    END IF;

    -- Extraemos el esquema y la tabla a partir del punto '.'
    v_pos_punto := position('.' in p_tabla_esquema);
    IF v_pos_punto > 0 THEN
        v_esquema := substring(p_tabla_esquema from 1 for v_pos_punto - 1);
        v_tabla := substring(p_tabla_esquema from v_pos_punto + 1);
    ELSE
        v_esquema := 'public';
        v_tabla := p_tabla_esquema;
    END IF;

    -- 1. CAPTURA DE TAMAÑO INICIAL
    SELECT 
        pg_size_pretty(pg_table_size(c.oid)),
        pg_size_pretty(pg_indexes_size(c.oid)),
        pg_size_pretty(pg_total_relation_size(c.oid))
    INTO v_size_datos_ini, v_size_idx_ini, v_size_tot_ini
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r' AND c.relname = v_tabla AND n.nspname = v_esquema;

    -- Construimos la query dinámica de forma segura usando format()
    v_query_update := format(
        'WITH batch AS (
            SELECT ctid FROM %s WHERE idx IS NULL LIMIT %L
         )
         UPDATE %s 
         SET idx = nextval(%L)
         WHERE ctid IN (SELECT ctid FROM batch);',
        p_tabla_esquema, p_tamano_lote, p_tabla_esquema, p_secuencia
    );

    -- Registramos el inicio del tiempo y del proceso
    v_tiempo_inicio := clock_timestamp();

    IF p_mostrar_progreso THEN
        RAISE NOTICE '==================================================';
        RAISE NOTICE 'Iniciando poblado masivo en la tabla %', p_tabla_esquema;
        RAISE NOTICE 'Hora de inicio del proceso: %', to_char(v_tiempo_inicio, 'YYYY-MM-DD HH24:MI:SS.MS');
        RAISE NOTICE 'Configuración: Lotes de % filas | Pausa de % seg.', p_tamano_lote, p_segundos_sleep;
        RAISE NOTICE 'TAMAÑO INICIAL -> Datos+TOAST: % | Índices: % | Total: %', 
                     v_size_datos_ini, v_size_idx_ini, v_size_tot_ini;
        RAISE NOTICE '==================================================';
    END IF;

    LOOP
        -- Ejecutamos el lote dinámico
        EXECUTE v_query_update;
        
        -- Capturamos las filas afectadas por el UPDATE dinámico
        GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;
        
        -- Si ya no hay filas afectadas, terminamos el proceso
        IF v_filas_afectadas = 0 THEN
            EXIT;
        END IF;

        -- ¡LA SUPER VENTAJAS! Guardamos los cambios de este lote inmediatamente en disco
        COMMIT;
        
        -- Capturamos la hora exacta en la que el lote se guardó en disco exitosamente
        v_timestamp_lote := clock_timestamp();

        -- Si el usuario activó el parámetro de progreso, le mostramos la info en tiempo real
        IF p_mostrar_progreso THEN
            RAISE NOTICE '[% (Hora Lote)] Lote % completado. Filas procesadas: %. Cambios guardados.', 
                         to_char(v_timestamp_lote, 'HH24:MI:SS.MS'), v_iteracion, v_filas_afectadas;
        END IF;

        v_iteracion := v_iteracion + 1;
        
        -- Pausa dinámica controlada por el nuevo parámetro
        IF p_segundos_sleep > 0 THEN
            PERFORM pg_sleep(p_segundos_sleep);
        END IF;
    END LOOP;

    -- Registramos fin del tiempo
    v_tiempo_fin := clock_timestamp();
    v_duracion := v_tiempo_fin - v_tiempo_inicio;

    -- 2. CAPTURA DE TAMAÑO FINAL
    SELECT 
        pg_size_pretty(pg_table_size(c.oid)),
        pg_size_pretty(pg_indexes_size(c.oid)),
        pg_size_pretty(pg_total_relation_size(c.oid))
    INTO v_size_datos_fin, v_size_idx_fin, v_size_tot_fin
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r' AND c.relname = v_tabla AND n.nspname = v_esquema;

    -- Reporte final detallado
    IF p_mostrar_progreso THEN
        RAISE NOTICE '==================================================';
        RAISE NOTICE '¡FINALIZADO! Todos los registros antiguos fueron poblados con éxito.';
        RAISE NOTICE 'Hora de finalización: %', to_char(v_tiempo_fin, 'YYYY-MM-DD HH24:MI:SS.MS');
        RAISE NOTICE 'Duración total de la ejecución: %', v_duracion;
        RAISE NOTICE '--------------------------------------------------';
        RAISE NOTICE 'COMPARATIVA DE TAMAÑOS EN DISCO:';
        RAISE NOTICE ' > Datos+TOAST:  [Antes: %] -> [Ahora: %]', v_size_datos_ini, v_size_datos_fin;
        RAISE NOTICE ' > Índices:      [Antes: %] -> [Ahora: %]', v_size_idx_ini, v_size_idx_fin;
        RAISE NOTICE ' > Total Tabla:  [Antes: %] -> [Ahora: %]', v_size_tot_ini, v_size_tot_fin;
        RAISE NOTICE '==================================================';
    ELSE
        -- Si el modo es silencioso, enviamos una alerta mínima con el tiempo final
        RAISE NOTICE 'Poblado finalizado. Duración: %', v_duracion;
    END IF;

END;
$$; 
```


**Ejemplos de ejecución con el nuevo parámetro**
```SQL
-- Ejemplo 1: Pausa agresiva de medio segundo (0.5) para terminar más rápido si hay poco tráfico
CALL public.poblar_idx_por_lotes('public.ctl_mensajeriaresponse', 'public.ctl_mensajeriaresponse_idx_seq', 5000, 0.5, TRUE);

-- Ejemplo 2: Pausa conservadora de 2 segundos (2) para producción en horas pico
CALL public.poblar_idx_por_lotes('public.ctl_mensajeriaresponse', 'public.ctl_mensajeriaresponse_idx_seq', 100000, 1, TRUE);

-- Ejemplo 3: Sin pausas (0), va a máxima velocidad de disco (úsalo solo si estás en ventana de mantenimiento total)
CALL public.poblar_idx_por_lotes('public.ctl_mensajeriaresponse', 'public.ctl_mensajeriaresponse_idx_seq', 10000, 0, TRUE);
```


**Ejemplo salida**
```SQL
db_test=# CALL public.poblar_idx_por_lotes('public.ctl_mensajeriaresponse', 'public.ctl_mensajeriaresponse_idx_seq', 5000, TRUE);

NOTICE:  ==================================================
NOTICE:  Iniciando poblado masivo en la tabla public.ctl_mensajeriaresponse
NOTICE:  Hora de inicio del proceso: 2026-07-13 16:15:02.345
NOTICE:  TAMAÑO INICIAL -> Datos+TOAST: 97 GB | Índices: 14 GB | Total: 111 GB
NOTICE:  ==================================================
NOTICE:  [16:15:03.789 (Hora Lote)] Lote 1 completado. Filas procesadas en este lote: 5000. Cambios guardados.
NOTICE:  [16:15:05.122 (Hora Lote)] Lote 2 completado. Filas procesadas en este lote: 5000. Cambios guardados.
NOTICE:  [16:15:06.456 (Hora Lote)] Lote 3 completado. Filas procesadas en este lote: 5000. Cambios guardados.
...
NOTICE:  ==================================================
NOTICE:  ¡FINALIZADO! Todos los registros antiguos fueron poblados con éxito.
NOTICE:  Hora de finalización: 2026-07-13 16:18:47.468
NOTICE:  Duración total de la ejecución: 00:03:45.123456
NOTICE:  --------------------------------------------------
NOTICE:  COMPARATIVA DE TAMAÑOS EN DISCO:
NOTICE:   > Datos+TOAST:  [Antes: 97 GB] -> [Ahora: 99 GB]
NOTICE:   > Índices:      [Antes: 14 GB] -> [Ahora: 14 GB]
NOTICE:   > Total Tabla:  [Antes: 111 GB] -> [Ahora: 113 GB]
NOTICE:  ==================================================
CALL
```
