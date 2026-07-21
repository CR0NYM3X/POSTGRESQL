 

# Cómo agregar una Clave Primaria (PK) a una tabla gigante en PostgreSQL con CERO Downtime

Agregar una columna clave primaria (`PRIMARY KEY`) a una tabla de base de datos pequeña es trivial: un simple `ALTER TABLE` resuelve el problema en milisegundos. Sin embargo, cuando la tabla tiene **decenas o cientos de millones de registros**, un `ALTER TABLE ADD COLUMN id BIGSERIAL PRIMARY KEY;` ejecutará un **bloqueo exclusivo (`AccessExclusiveLock`)**, paralizando lecturas y escrituras por minutos u horas, provocando el colapso de tus aplicaciones.

En este artículo aprenderás la estrategia definitiva para agregar una PK autonumerada a una tabla masiva de manera progresiva y **sin interrumpir el tráfico en producción**.

---

## El Enfoque Tradicional vs. El Enfoque Zero-Downtime

* **El camino riesgoso:** Ejecutar un solo `ALTER TABLE` gigante. Bloquea la tabla por completo, genera bloat masivo y puede agotar la memoria swap o el tiempo de espera (timeout) de las conexiones.
* **El camino profesional (En lotes + Concurrente):**
1. Crear la columna como `NULLABLE` (operación instantánea).
2. Vincular la secuencia para nuevos registros en tiempo real.
3. Llenar los registros antiguos de forma pausada mediante lotes (batches).
4. Crear un índice único de forma concurrente en segundo plano.
5. Convertir el índice en la Clave Primaria formal.



---

## Guía Paso a Paso

### Paso 1: Activar el temporizador (Opcional)

Si estás ejecutando el script desde la CLI de `psql`, habilita la medición de tiempo para controlar el rendimiento de cada bloque.

```sql
\timing on

```

---

### Paso 2: Crear la columna vacía

Añadir una columna que permite valores `NULL` no reescribe la tabla en disco ni valida datos antiguos; es una modificación puramente de metadatos en la catálogos de Postgres que tarda milisegundos.

```sql
ALTER TABLE public.ordenes_venta ADD COLUMN id_orden BIGINT;

```

---

### Paso 3: Crear la secuencia e integrarla para nuevos datos

Creamos el generador de IDs y lo asociamos como valor por defecto (`DEFAULT`) en la columna. A partir de este microsegundo, **todo nuevo `INSERT` que llegue a producción recibirá automáticamente su ID único**.

```sql
-- 1. Crear la secuencia independiente
CREATE SEQUENCE public.ordenes_venta_id_seq;

-- 2. Asignar la secuencia como valor por defecto a la columna
ALTER TABLE public.ordenes_venta 
    ALTER COLUMN id_orden SET DEFAULT nextval('public.ordenes_venta_id_seq');

-- 3. Vincular la secuencia a la columna para limpiezas en cascada 
ALTER SEQUENCE public.ordenes_venta_id_seq 
    OWNED BY public.ordenes_venta.id_orden;

```

---

### Paso 4: Poblar los datos pasados en lotes (Batching)

Ahora tenemos una tabla donde los registros nuevos ya tienen ID, pero los antiguos son `NULL`. Para actualizarlos sin bloquear filas de forma masiva ni saturar el disco (I/O), utilizamos un bloque procedimiento almacenado que actualiza de 5,000 en 5,000 registros apoyándose en la dirección física de la fila (`ctid`).

```sql
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

    -- OPTIMIZACIÓN DE LA QUERY: Usamos JOIN directo por ctid mediante FROM, es más rápido en actualizaciones masivas
    v_query_update := format(
        'UPDATE %s t
         SET idx = nextval(%L)
         FROM (
             SELECT ctid FROM %s WHERE idx IS NULL LIMIT %L FOR UPDATE SKIP LOCKED
         ) sub
         WHERE t.ctid = sub.ctid;',
        p_tabla_esquema, p_secuencia, p_tabla_esquema, p_tamano_lote
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
        -- Ejecutamos el lote dinámico optimizado
        EXECUTE v_query_update;
        
        -- Capturamos las filas afectadas por el UPDATE dinámico
        GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;
        
        -- Si ya no hay filas afectadas, terminamos el proceso
        IF v_filas_afectadas = 0 THEN
            EXIT;
        END IF;

        -- Guardamos los cambios de este lote inmediatamente en disco
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

> **Tip de optimización:** Ajusta el tamaño del `LIMIT` (5,000 - 10,000) y el tiempo del `pg_sleep()` según la potencia de tu servidor y la tolerancia del motor de base de datos.

### Ejecutar el por bloques
```
CALL public.poblar_idx_por_lotes(
    p_tabla_esquema    => 'public.tbl_prueba_masiva', 
    p_secuencia        => 'public.tbl_prueba_idx_seq', 
    p_tamano_lote      => 5000, 
    p_segundos_sleep   => 0.5, 
    p_mostrar_progreso => TRUE
);
```
---

### Paso 5: Construir el índice de forma concurrente

No podemos declarar una `PRIMARY KEY` sin un índice. La palabra clave `CONCURRENTLY` le ordena a PostgreSQL construir el índice escaneando la tabla sin adquirir un bloqueo de escritura (`AccessExclusiveLock`). Las aplicaciones continuarán insertando, actualizando y leyendo datos normalmente mientras se construye.

```sql
CREATE UNIQUE INDEX CONCURRENTLY ordenes_venta_pk_idx 
ON public.ordenes_venta (id_orden);

```

---

### Paso 6: Promover el índice a PRIMARY KEY

Una vez que el índice único ha terminado de construirse en segundo plano de manera segura, el paso final es asociarlo formalmente como la restricción de Clave Primaria. Dado que el índice ya existe y contiene todos los datos validados, esta instrucción toma fracciones de segundo.

```sql
ALTER TABLE public.ordenes_venta 
    ADD CONSTRAINT ordenes_venta_pkey PRIMARY KEY USING INDEX ordenes_venta_pk_idx;

```

---

## Conclusión

Aplicar cambios estructurales a bases de datos de alto volumen requiere pasar de comandos destructivos a patrones progresivos. Dividir la migración en creación de metadatos, actualización asíncrona en segundo plano e indexación concurrente es el estándar de la industria para mantener disponibilidad del **99.99%** sin degradar la experiencia de tus usuarios.
