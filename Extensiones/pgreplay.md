# pgreplay

**pgreplay** tiene un nicho muy específico y poderoso: la "máquina del tiempo" de carga de trabajo.

A diferencia de un simple benchmark (como `pgbench`), que genera tráfico sintético, **pgreplay** toma el tráfico **real** que ocurrió en tu base de datos y lo "reproduce" contra otro servidor, manteniendo exactamente el mismo ritmo y orden de las consultas.

> **Advertencia de Seguridad:** `pgreplay` reproducirá **INSERTs, UPDATEs y DELETEs**. Nunca lo ejecutes contra una base de datos de producción activa a menos que quieras duplicar datos o causar un desastre. Siempre úsalo contra un **mirror** o una copia reciente.

 
---

## ¿Para qué sirve realmente? (Escenarios clave)

El propósito principal es el **Análisis de Impacto**. Te sirve cuando necesitas saber: *"¿Qué pasará con mis usuarios reales si cambio X cosa?"*

* **Migraciones de Versión:** ¿PostgreSQL 17 manejará mi carga actual igual que la versión 13?
* **Cambios de Hardware:** ¿Este nuevo servidor con menos RAM pero discos NVMe soportará la hora pico?
* **Ajuste de Parámetros (`postgresql.conf`):** ¿Si cambio el `shared_buffers`, realmente mejorará el rendimiento bajo estrés real?
* **Pruebas de Índices:** ¿Este nuevo índice que creé realmente acelera las consultas de producción o solo ocupa espacio?

---

## Un Caso Real de Uso

Imagina una tienda de e-commerce que sufre caídas cada vez que hay un "Cyber Monday". El equipo de infraestructura decide migrar de un servidor local a una instancia potente en la nube.

1. **El miedo:** No saben si la latencia de la red o la configuración de la nube afectará las transacciones críticas.
2. **La solución:** Graban el tráfico de un día normal de ventas usando los logs de Postgres.
3. **La prueba:** Usan **pgreplay** para lanzar ese mismo tráfico contra el nuevo servidor en la nube.
4. **El resultado:** Descubren que ciertas consultas tardan el doble debido a la configuración de almacenamiento, permitiéndoles corregirlo **antes** de salir a producción.

---

## Configuración y Uso Paso a Paso

Para que esto funcione, primero debes "grabar" lo que pasa en tu base de datos.

### 1. Preparar el Servidor de Origen (Grabación)

Debes configurar tu archivo `postgresql.conf` para que registre todo con el detalle necesario:

```ini
log_destination = 'stderr'
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'all'
log_min_duration_statement = 0
log_line_prefix = '%m|%u|%d|%c|'  # Formato vital para pgreplay

```

*Nota: Esto generará muchos archivos de log, asegúrate de tener espacio en disco.*

### 2. Procesar los Logs

Una vez que tengas los archivos de log, usas `pgreplay` para convertirlos en un formato que él entienda:

```bash
pgreplay -p /ruta/a/tus/logs/postgresql-*.log > replay.outfile

```

### 3. Ejecutar la Reproducción

Ahora, lanzas esa carga contra tu servidor de prueba (Target):

```bash
pgreplay -h servidor-prueba.com -d mi_base_datos -U mi_usuario replay.outfile

```

---

## Resultados Esperados y Qué Analizar

Cuando termine la ejecución, `pgreplay` te dará un resumen estadístico. Lo más importante que debes observar es:

| Métrica | Significado |
| --- | --- |
| **Elapsed Time** | Si el replay tardó más que el tiempo real grabado, tu servidor destino es más lento. |
| **Maximum Lag** | Indica cuánto se "atrasó" el servidor al intentar seguirle el ritmo al tráfico original. |
| **Errors** | Si aparecen errores que no estaban en el log original, hay problemas de integridad o configuración. |

