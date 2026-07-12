# El Chef y su Recetario: Comprendiendo el Caché de Planes en PostgreSQL

**Guía Experta de Arquitectura y Optimización**

La forma en que PostgreSQL maneja la memoria caché de los planes de ejecución es una obra de ingeniería fascinante. Para comprenderlo, imagina una **cocina de alta gastronomía**. Cuando envías una consulta SQL, el *Parser* (el mesero) anota la orden. Luego, el *Planner/Optimizer* (el Chef Ejecutivo) evalúa los ingredientes (índices), el tamaño de las porciones (estadísticas) y decide la receta exacta para preparar tu plato en el menor tiempo posible. Esa receta es el **Plan de Ejecución**.

Crear esa receta desde cero consume CPU. ¿Por qué el Chef debería pensar la receta desde cero si le piden el mismo plato cien veces? Aquí es donde entra la magia del caché de planes.

## 1. Arquitectura: La Regla de las 5 Ejecuciones

A diferencia de otros motores, PostgreSQL tiene una arquitectura basada en **procesos**. La caché de planes en PostgreSQL es **local por sesión**. Para que el "Chef" memorice la receta, usamos *Prepared Statements*.

> **La heurística inteligente de Postgres:**
> 1. **Las primeras 5 veces:** Se crea un *Custom Plan* (Plan Personalizado) optimizado para los valores exactos enviados.
> 2. **A la 6ª vez:** Si un *Generic Plan* (Plan Genérico) es igual de eficiente que el promedio de los personalizados, se guarda en caché y se reutiliza, ahorrando tiempo de planificación.

## 2. PostgreSQL vs. SQL Server: Choque de Filosofías

SQL Server es como una enorme cocina industrial donde todos los chefs comparten el mismo recetario gigante (Plan Cache global). Postgres es más como un mercado con cocinas independientes.

| Característica | PostgreSQL | SQL Server |
| :--- | :--- | :--- |
| **Ubicación** | Memoria local por conexión (Session-level). | Memoria compartida global. |
| **Consultas Ad-hoc** | No se cachean automáticamente. Requiere Prepared Statements. | Se cachean automáticamente. |
| **Parameter Sniffing**| Mitigado por la regla de las 5 ejecuciones. | Problema severo y común (el primer parámetro define todo). |

## 3. Código y Ejemplos de Optimización

### A. Aprovechando el Caché con Sentencias Preparadas
A nivel de aplicación, usar `PREPARE` ahorra valiosos milisegundos en consultas repetitivas.

```sql
-- 1. Preparamos la consulta (El Chef anota la estructura de la receta)
PREPARE buscar_cliente (int) AS
    SELECT id, nombre, email FROM clientes WHERE id = $1;

-- 2. Ejecutamos pasándole los "ingredientes" (parámetros)
EXECUTE buscar_cliente(105);
EXECUTE buscar_cliente(210);

-- 3. Verificamos los planes en caché en nuestra sesión actual
SELECT name, statement, generic_plans, custom_plans 
FROM pg_prepared_statements;
```

### B. El Superpoder de PL/pgSQL (y su trampa)
Todo código SQL **estático** dentro de una función de Postgres se trata automáticamente como un Prepared Statement. Sin embargo, si usas SQL **dinámico**, destruyes esta ventaja.

```sql
-- ✅ BUENA PRÁCTICA: SQL Estático (Usa la caché de planes)
CREATE OR REPLACE FUNCTION obtener_ventas_mes(p_mes INT) 
RETURNS SETOF ventas AS $$
BEGIN
    -- Postgres cacheará el plan de esta consulta automáticamente
    RETURN QUERY SELECT * FROM ventas WHERE extract(month from fecha) = p_mes;
END;
$$ LANGUAGE plpgsql;

-- ❌ MALA PRÁCTICA (si no es estrictamente necesario): SQL Dinámico
CREATE OR REPLACE FUNCTION obtener_ventas_dinamico(p_mes INT) 
RETURNS SETOF ventas AS $$
BEGIN
    -- EXECUTE obliga a planificar desde cero CADA VEZ
    RETURN QUERY EXECUTE format(
        'SELECT * FROM ventas WHERE extract(month from fecha) = %L', p_mes
    );
END;
$$ LANGUAGE plpgsql;
```

### C. Forzando el Comportamiento del Planificador (Postgres 12+)
A veces, la regla de las 5 ejecuciones falla (ej. distribuciones de datos muy irregulares). Podemos forzar al Chef a **siempre** pensar desde cero (Custom) o **siempre** usar la receta estándar (Generic).

```sql
-- Forzar siempre un Custom Plan a nivel de sesión (adiós caché para sentencias preparadas)
SET plan_cache_mode = 'force_custom_plan';

-- O mejor aún, forzarlo solo para una función específica que sufre de Parameter Sniffing
ALTER FUNCTION obtener_ventas_mes(INT) SET plan_cache_mode = 'force_custom_plan';
```

### D. Invalidación Automática de Caché
¿Qué pasa si la tabla crece masivamente o le agregas un índice? Postgres es inteligente. Las actualizaciones de estadísticas invalidan el caché.

```sql
-- Si notas que una consulta preparada de repente es lenta, 
-- puede que el plan genérico en caché esté desactualizado.
-- Actualizar las estadísticas invalida automáticamente el caché:
ANALYZE clientes;

-- El próximo EXECUTE obligará al planificador a crear un plan 
-- nuevo basado en la nueva realidad de los datos.
```

---
**Conclusión:** Entender el caché de PostgreSQL te permite escribir código más inteligente. Aprovecha el SQL estático en funciones, usa Prepared Statements desde tu backend (como pgx en Go o asyncpg en Python), y mantén tus estadísticas actualizadas mediante un Autovacuum bien afinado.
