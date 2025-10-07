 

## 📘 1. Índice

1.  Objetivo
2.  Requisitos
3.  ¿Qué es `auto_explain`?
4.  Ventajas y desventajas
5.  Casos de uso
6.  Simulación empresarial
7.  Estructura semántica
8.  Visualización
9.  Procedimientos
    *   Activación de la extensión
    *   Configuración de parámetros
    *   Simulación de consultas lentas
    *   Revisión de logs
10. Consideraciones
11. Buenas prácticas
12. Recomendaciones
13. Otros tipos
14. Tabla comparativa
15. Bibliografía

***

## 🎯 2. Objetivo

Este manual tiene como objetivo enseñar cómo habilitar y utilizar la extensión `auto_explain` en PostgreSQL para registrar automáticamente planes de ejecución de consultas lentas, facilitando el análisis de rendimiento sin necesidad de modificar el código de la aplicación.

***

## 🧰 3. Requisitos

*   PostgreSQL 9.0 o superior
*   Acceso al archivo `postgresql.conf` o privilegios para modificar parámetros vía `ALTER SYSTEM`
*   Permisos para reiniciar el servidor o recargar configuración
*   Conocimiento básico de SQL y EXPLAIN

***

## ❓ 4. ¿Qué es `auto_explain`?

`auto_explain` es una extensión de PostgreSQL que permite registrar automáticamente el plan de ejecución de las consultas que exceden un umbral de tiempo definido. Es útil para detectar cuellos de botella sin necesidad de modificar el código fuente.

***

## ⚖️ 5. Ventajas y Desventajas

**Ventajas:**

*   No requiere modificar el código de la aplicación
*   Permite identificar consultas lentas en producción
*   Compatible con logging estándar

**Desventajas:**

*   Puede generar muchos logs si no se configura correctamente
*   Requiere cuidado en entornos con alto volumen de consultas

***

## 🧪 6. Casos de Uso

*   Auditoría de rendimiento en producción
*   Diagnóstico de consultas lentas en sistemas legacy
*   Optimización de bases de datos sin acceso directo al código

***

## 🏢 7. Simulación empresarial

**Empresa ficticia:** *LogiTrack S.A.*\
**Problema:** Los usuarios reportan lentitud en el módulo de reportes. No se tiene acceso al código fuente.\
**Solución:** Activar `auto_explain` para registrar automáticamente los planes de ejecución de las consultas que superen los 500 ms.
 

***

## 🛠️ 9. Procedimientos

### 🔹 Activación de la extensión

1.  Edita el archivo `postgresql.conf`:
    ```conf
    shared_preload_libraries = 'auto_explain'
    ```

2.  Reinicia el servidor PostgreSQL:
    ```bash
    sudo systemctl restart postgresql
    ```

3.  Verifica que la extensión esté cargada:
    Esta extension no requiere instalarse solo precargar la libreria en postgresql.conf 
    ```sql
    ls $(psql -XAt  -c "select setting from pg_config where name = 'LIBDIR';")  | grep auto_explain
    ```

### 🔹 Configuración de parámetros

Puedes hacerlo en `postgresql.conf`, vía `ALTER SYSTEM`, o en sesión:

```sql
-- Configurar parámetros
SET auto_explain.log_min_duration = '500ms';  -- Solo loguea si la consulta tarda más de 500ms
SET auto_explain.log_analyze = on;            -- Incluye tiempos reales
SET auto_explain.log_buffers = on;            -- Incluye uso de buffers
SET auto_explain.log_verbose = on;            -- Muestra detalles adicionales
SET auto_explain.log_timing = on;
SET auto_explain.log_nested_statements = on;  -- Incluye funciones y subconsultas


-- Ver los parametros que se pueden configurar
select name,setting,context from pg_settings where name ilike '%auto_explain%' order by  name;
```

### 🔹 Simulación de consulta lenta

Creamos una tabla ficticia:

```sql
CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    producto TEXT,
    cantidad INT,
    fecha TIMESTAMP
);

INSERT INTO ventas (producto, cantidad, fecha)
SELECT 'Producto ' || i, i % 100, NOW() - (i || ' minutes')::interval
FROM generate_series(1, 100000) AS i;
```

Ejecutamos una consulta lenta:

```sql
SELECT producto, SUM(cantidad)
FROM ventas
GROUP BY producto
ORDER BY SUM(cantidad) DESC;
```

### 🔹 Revisión de logs

Busca en el archivo de logs de PostgreSQL (por ejemplo `/var/log/postgresql/postgresql.log`) una salida como:

    LOG:  duration: 812.345 ms  plan:
    Query Text: SELECT producto, SUM(cantidad) ...
    Aggregate  (cost=... rows=... width=...)
      ->  GroupAggregate
            ->  Sort
                  ->  Seq Scan on ventas

***

## 📌 10. Consideraciones

*   No uses `auto_explain` con valores muy bajos en producción sin filtros
*   Asegúrate de tener espacio en disco para los logs
*   Puedes combinarlo con `log_statement_stats` para mayor detalle

***

## ✅ 11. Buenas prácticas

*   Usar `auto_explain.log_min_duration` con valores razonables (300ms–1000ms)
*   Activar solo en sesiones específicas si es necesario
*   Monitorear el tamaño de los logs

***

## 💡 12. Recomendaciones

*   Complementa con herramientas como `pg_stat_statements`
*   Usa `auto_explain` en entornos de staging antes de producción
*   Automatiza la rotación de logs

***

## 🔄 13. Otros tipos

*   `pg_stat_statements`: para estadísticas acumuladas
*   `EXPLAIN (ANALYZE, BUFFERS)`: para análisis manual
*   `pgBadger`: para visualización de logs

***

## 📊 14. Tabla comparativa

| Herramienta          | Automático | Detalle | Impacto en rendimiento | Ideal para            |
| -------------------- | ---------- | ------- | ---------------------- | --------------------- |
| auto\_explain        | ✅          | Medio   | Bajo-Medio             | Producción controlada |
| EXPLAIN manual       | ❌          | Alto    | Bajo                   | Desarrollo            |
| pg\_stat\_statements | ✅          | Alto    | Bajo                   | Producción            |
| pgBadger             | ✅          | Medio   | Bajo                   | Auditoría             |

***

## 📚 15. Bibliografía

*   <https://www.postgresql.org/docs/current/auto-explain.html>
*   <https://www.cybertec-postgresql.com/en/auto_explain-postgresql/>
*   <https://wiki.postgresql.org/wiki/Performance_Optimization>

