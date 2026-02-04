
### El escenario: El borrado masivo

Cuando ejecutas un `DELETE` de un millón de filas en el **Primario**, lo que realmente sucede es que PostgreSQL marca esas filas como "muertas" (dead tuples). Esto genera **Bloat** (espacio desperdiciado).

### 1. ¿Qué pasa exactamente en las réplicas?

En PostgreSQL, las réplicas (Standard Hot Standby) son réplicas **físicas**. Esto significa que no ejecutan sentencias SQL, sino que aplican los cambios byte a byte que les llegan a través de los registros de transacciones (**WAL** - Write Ahead Log).

* **El VACUUM NO corre en las réplicas:** Tienes razón. El proceso de `VACUUM` (tanto el manual como el autovacuum) es una operación de escritura que modifica los mapas de visibilidad y limpia las páginas de datos. Como la réplica es de **solo lectura**, no puede iniciar su propio proceso de limpieza.
* **La réplica "reproduce" el mantenimiento:** Cuando el `VACUUM` se ejecuta en el **Primario** y limpia ese millón de registros, esas acciones de limpieza se graban en el WAL. La réplica simplemente recibe las instrucciones: *"Oye, en la página X, estas filas ya no sirven, límpialas"*.

---

### 2. El gran peligro: El Conflicto de Consulta (Query Conflicts)

Aquí es donde la cosa se pone interesante. Si el `VACUUM` en el primario elimina versiones de filas que **una consulta larga en la réplica todavía necesita ver**, surge un conflicto.

* **¿Qué hace la réplica?** Por defecto, intentará esperar un tiempo (`max_standby_streaming_delay`). Si la consulta en la réplica tarda demasiado y el primario exige que se aplique la limpieza del WAL, la réplica **cancelará tu consulta** con un error similar a:
> *FATAL: canceling statement due to conflict with recovery.*



---

### 3. ¿Qué mantenimientos SÍ se hacen o afectan a la réplica?

Aunque no haya un Autovacuum local, como arquitecto te sugiero vigilar estos tres puntos:

| Concepto | Comportamiento en la Réplica |
| --- | --- |
| **Index Bloat** | Si el índice se infla en el primario por el borrado, se inflará igual en la réplica. La única forma de sanarlo es un `REINDEX` en el primario (que se replicará). |
| **Hot Standby Feedback** | Puedes activar este parámetro (`hot_standby_feedback = on`) en la réplica. Esto le avisa al primario: *"No borres todavía esas filas muertas, porque mis consultas aún las usan"*. **Ojo:** Esto evita errores en la réplica, pero causa que el **Bloat crezca en el Primario**. |
| **Monitoring** | En la réplica debes monitorear el **Replication Lag**. Un borrado de un millón de registros genera mucho WAL; si el disco o la red de la réplica son lentos, podrías tener un retraso importante. |

---

### Resumen de Consultor

1. **¿El Vacuum corre en réplicas?** No de forma independiente. Solo "imita" lo que hizo el primario.
2. **¿Qué mantenimiento haces tú?** Tu foco debe ser que el **Autovacuum en el primario** sea agresivo y rápido para que el WAL fluya eficientemente.
3. **Riesgo principal:** El borrado masivo de un millón de filas disparará el Vacuum en el primario, lo cual puede saturar el ancho de banda hacia tus 2 réplicas y cancelar consultas largas en ellas.
 
