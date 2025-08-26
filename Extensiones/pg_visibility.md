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

*   **No es para producción**: Está pensado para entornos de prueba o análisis, no para uso continuo en sistemas en vivo.
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

 

### 🔄 Competencias o tecnologías alternativas

| Tecnología            | Propósito                 | Diferencias                       |
| --------------------- | ------------------------- | --------------------------------- |
| `pgstattuple`         | Estadísticas de ocupación | Más amigable, menos detallado     |
| `auto_explain`        | Diagnóstico de planes     | No inspecciona almacenamiento     |
| `pg_freespacemap`     | Espacio libre por página  | Complementa `pg_visibility`       |
| `pg_stat_user_tables` | Estadísticas generales    | No muestra visibilidad por página |

 

### ⚠️ Consideraciones antes y después de la implementación

*   Requiere instalación manual: `CREATE EXTENSION pg_visibility;`
*   Solo funciona con tablas normales (no vistas ni foreign tables).
*   Puede generar carga de lectura si se usa en tablas grandes.
 

### 📝 Notas importantes

*   Compatible desde PostgreSQL 9.6 en adelante.
*   No requiere reinicio del servidor.
*   No necesita privilegios de superusuario, pero sí permisos sobre la tabla.


### 💬 Opinión de la comunidad

*   Muy valorado por DBAs avanzados.
*   Poco conocido por desarrolladores, pero útil para entender MVCC.
*   Recomendado en cursos de PostgreSQL de nivel intermedio/avanzado.
 
***

 

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
```

### 🧪 Creación de datos

```sql
CREATE TABLE produccion_diaria (
    id SERIAL PRIMARY KEY,
    fecha DATE,
    cantidad INT
);

INSERT INTO produccion_diaria (fecha, cantidad)
SELECT CURRENT_DATE - i, (random() * 100)::int
FROM generate_series(1, 1000) AS i;
```

### 🔍 Uso de `pg_visibility`

#### Ver resumen de visibilidad

```sql
SELECT * FROM pg_visibility_map_summary('produccion_diaria');
```

**Simulación de salida:**

| all\_visible | all\_frozen | total\_pages |
| ------------ | ----------- | ------------ |
| 800          | 0           | 1000         |

#### Ver visibilidad por página

```sql
SELECT * FROM pg_visibility_map('produccion_diaria') LIMIT 10;
```

**Simulación de salida:**

| blkno | all\_visible | all\_frozen |
| ----- | ------------ | ----------- |
| 0     | true         | false       |
| 1     | false        | false       |
| ...   | ...          | ...         |

#### Ver detalles de una página específica

```sql
SELECT * FROM pg_visibility('produccion_diaria', 1);
```

**Simulación de salida:**

| blkno | tuple\_offset | is\_visible |
| ----- | ------------- | ----------- |
| 1     | 0             | true        |
| 1     | 1             | false       |



## 🧼 Mantenimiento

Si se detecta bloat:

```sql
VACUUM FULL produccion_diaria;
```

***

## 🧠 10. Consideraciones

*   No usar en producción sin pruebas previas
*   Requiere permisos elevados
*   Puede afectar rendimiento si se usa en tablas grandes



## ✅ 11. Buenas prácticas

*   Usar en conjunto con `pgstattuple` para análisis más profundo
*   Automatizar inspección en tablas críticas
*   Documentar resultados y acciones tomadas



## 💡 12. Recomendaciones

*   Integrar en rutinas de mantenimiento mensual
*   Usar antes de aplicar `VACUUM FULL`
*   Comparar con estadísticas de `pg_stat_user_tables`



## 🔄 13. Otros tipos

*   `pgstattuple`: muestra estadísticas de ocupación
*   `pg_freespacemap`: muestra espacio libre por página



## 📊 14. Tabla comparativa

| Extensión        | Visibilidad | Espacio libre | Estadísticas |
| ---------------- | ----------- | ------------- | ------------ |
| pg\_visibility   | ✅           | ❌             | ❌            |
| pgstattuple      | ❌           | ✅             | ✅            |
| pg\_freespacemap | ❌           | ✅             | ❌            |



## 📚 15. Bibliografía

*   <https://www.postgresql.org/docs/current/pgvisibility.html>
*   <https://www.cybertec-postgresql.com/en/pg_visibility-extension/>

