
## ¿Qué es un “timeline” en PostgreSQL?

Cada vez que ocurre un **cambio de línea de tiempo** (por ejemplo, cuando **promocionas** un standby a primary, o cuando terminas una recuperación y promueves), PostgreSQL crea una **nueva timeline** (TLI: Timeline ID). Eso genera **ramas** en la historia del cluster: imagina que el sistema tenía la historia original (timeline 1) y luego, tras una promoción, se crea timeline 2; si luego vuelves a restaurar y promover, creas timeline 3, etc. Durante una restauración, debes decidir **a cuál rama** seguir para leer los WAL correctos.

***

## Valores posibles de `recovery_target_timeline`

1.  **`latest`** *(por defecto)*
    *   **Significado:** Sigue siempre la **timeline más reciente** que exista a partir del backup/base de la restauración.
    *   **Cuándo usarlo:**
        *   Restauraciones estándar donde quieres alcanzar “lo más nuevo posible” de la historia, **incluso si hubo promociones** que cambiaron de timeline.
        *   Escenarios de recuperación tras fallas en producción donde simplemente quieres llegar al estado más actual que permitan tus archivos WAL.
    *   **Cuándo no usarlo:**
        *   Cuando necesitas **limitar** la recuperación a una timeline específica (por motivos de auditoría, pruebas reproducibles, o para evitar avanzar hacia una rama creada por una promoción que no deseas seguir).
    *   **Ventajas:** Menos riesgo de “quedarte corto” si hubo cambios de timeline; es la opción más simple y segura para la mayoría de PITR.

2.  **`current`**
    *   **Significado:** Mantente en la **timeline del backup base** (es decir, **no cruces** a timelines posteriores).
    *   **Cuándo usarlo:**
        *   Quieres reproducir exactamente hasta un punto dentro de la **misma** historia del backup, **sin atravesar** una promoción que generó una nueva timeline.
        *   Pruebas de laboratorio donde necesitas validar un comportamiento en la rama original sin involucra la rama creada por una promoción.
    *   **Cuándo no usarlo:**
        *   Si tu objetivo de recuperación (por ejemplo, una hora reciente) **solo existe** en una timeline posterior (p. ej., tras una promoción). Con `current`, te quedarías corto y no llegarías a ese punto.
    *   **Ventajas:** Control estricto: evita seguir ramas no deseadas.
    *   **Riesgo:** Si el punto de recuperación está más allá de un cambio de timeline, no lo alcanzarás.

3.  **Un **ID numérico** de timeline (por ejemplo, `2`, `3`, `4`, …)**
    *   **Significado:** Especifica **exactamente** qué TLI usar.
    *   **Cuándo usarlo:**
        *   **Auditorías/forense:** necesitas restaurar en una rama específica para reconstruir un estado concreto.
        *   **Reproducción de bugs**: quieres rehacer el estado exacto que ocurrió en una rama específica.
        *   **Entornos con múltiples promociones** donde la ruta correcta es conocida y controlada.
    *   **Cuándo no usarlo:**
        *   Si no estás seguro de los números de timeline o no tienes WAL y archivos `*.history` que soporten esa TLI.
    *   **Ventajas:** Máximo control y reproducibilidad.
    *   **Riesgo:** Si el ID no existe en tu set de WAL/archivos de historia, la recuperación fallará.

***

## Escenarios comunes y cómo decidir

### 1) Recuperación “hasta lo último posible” tras un incidente

*   **Objetivo:** llegar al estado más nuevo con los WAL disponibles.
*   **Usa:** `recovery_target_timeline = 'latest'`.
*   **Complemento típico:** `recovery_target = 'immediate'` (o no establecer un target específico), o usar `recovery_target_time` para una hora reciente.
*   **Por qué:** si hubo promociones o múltiples restauraciones, “latest” te garantiza seguir la rama más actual.

### 2) PITR controlado sin cruzar promociones

*   **Objetivo:** restaurar hasta una hora/XID/LSN **previo** a una promoción para analizar el sistema antes de que cambiara de timeline.
*   **Usa:** `recovery_target_timeline = 'current'` + `recovery_target_time` (o `recovery_target_xid`, `recovery_target_lsn`, `recovery_target_name`).
*   **Por qué:** impide que la recuperación brinque a una rama nueva que podría tener cambios que no te interesan.

### 3) Auditoría/forense en una rama concreta

*   **Objetivo:** reconstruir exactamente el estado de una **timeline específica** (p. ej., TLI=3).
*   **Usa:** `recovery_target_timeline = 3` (o el número que corresponda) + el target que necesites (tiempo, XID, marca).
*   **Por qué:** total precisión en qué historia sigues; ideal para entornos regulados o pruebas exactas.

### 4) Restauraciones en entornos con múltiples promociones y ramas complejas

*   **Objetivo:** evitar confusiones y restaurar siempre lo más actual en producción.
*   **Usa:** `latest` por defecto en producción; en **staging** o **lab**, usa `current` o numérico para reproducir escenarios.

***

## Interacciones importantes con otros parámetros de recuperación

*   **`restore_command`**: debe poder localizar y extraer los WAL (desde archivos .wal, S3, un archivador externo, etc.).
*   **`recovery_target_time` / `recovery_target_xid` / `recovery_target_lsn` / `recovery_target_name`**: definen el **punto exacto** donde quieres que la recuperación se detenga.
*   **`recovery_target_action`**: qué hacer al alcanzar el target (por ejemplo, `promote` para convertir el servidor recuperado en primary, `pause` para inspeccionar).
*   **Archivos de señal**: en versiones modernas (≥12), se usa `recovery.signal` para iniciar recuperación; `standby.signal` para modo réplica.
*   **Archivos `.history`**: cuando cambias de timeline, PostgreSQL escribe un archivo `x.history` que describe el linaje; es esencial para que “latest” o un TLI numérico funcionen.

***

## Ejemplos de configuración

### A) Llegar a lo más reciente posible (incluyendo cambios de timeline)

```ini
# postgresql.conf
restore_command = 'cp /ruta/archive/%f %p'
recovery_target_timeline = 'latest'   # por defecto
# Opcional: recuperar hasta un momento concreto
# recovery_target_time = '2025-12-16 13:20:00-07'
# recovery_target_action = 'promote'
```

### B) Mantenerse en la timeline del backup (no cruzar promociones)

```ini
restore_command = 'cp /ruta/archive/%f %p'
recovery_target_timeline = 'current'
recovery_target_time = '2025-12-15 10:00:00-07'
recovery_target_action = 'pause'      # inspecciona antes de promover
```

### C) Forzar una timeline específica

```ini
restore_command = 'cp /ruta/archive/%f %p'
recovery_target_timeline = 3          # usar timeline ID 3
recovery_target_name = 'marcado_fin_cierre'
recovery_target_action = 'promote'
```

> **Nota:** Asegúrate de que tus WAL y archivos `.history` correspondientes estén disponibles; de lo contrario, la recuperación fallará o se quedará corta.

***

## Recomendaciones prácticas

*   **Producción:** usa `latest` salvo que tengas una razón clara para no hacerlo.
*   **Laboratorio/Staging:** usa `current` o el TLI numérico para reproducibilidad y auditoría.
*   **Documenta promociones:** guarda registro de cuándo promoviste réplicas; facilita elegir timeline.
*   **Verifica WAL y `.history`:** sin ellos, no podrás seguir la historia deseada.
*   **Combina con `recovery_target_*`:** el timeline te dice **qué rama**, el target te dice **dónde** detenerte.

 
