.
📘 ¡Perfecto! Vamos a construir un **manual integral y profesional** sobre **PITR (Point-In-Time Recovery)** y **WAL Archiving** en **PostgreSQL**, tomando como base los 6 laboratorios que me compartiste. Este manual está orientado a administradores de bases de datos (DBAs) y técnicos que necesiten implementar, probar y dominar estas técnicas de recuperación.

---

## 🛠️ Índice

1. [Introducción a WAL y PITR](#1)
2. [Configuración inicial del entorno PostgreSQL](#2)
3. [Respaldo base: `pg_basebackup`](#3)
4. [Configuración de archivado continuo](#4)
5. [Generación y gestión de datos para laboratorio](#5)
6. [Recuperación por LSN, timestamp y timeline](#6)
7. [Simulación de fallos y restauración total](#7)
8. [Archivos clave y estructuras involucradas](#8)
9. [Recomendaciones de prácticas avanzadas](#9)
10. [Conclusión](#10)

---

<a name="1"></a>
## 1. 🔁 Introducción a WAL y PITR

- **WAL (Write-Ahead Logging)**: mecanismo que registra toda modificación antes de aplicarla a disco. Garantiza durabilidad y consistencia.
- **PITR (Point-In-Time Recovery)**: permite restaurar una base de datos a un punto específico en el tiempo, útil para recuperar datos borrados o revertir errores.
- **LSN (Log Sequence Number)**: dirección lógica dentro de los WALs. Puede usarse como marcador de recuperación.

---

<a name="2"></a>
## 2. ⚙️ Configuración inicial de PostgreSQL

### En `postgresql.conf`:

```conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /ruta/de/archivos_wal/%f'
restore_command = 'cp /ruta/de/archivos_wal/%f %p'
max_wal_senders = 5
wal_keep_size = 512MB
```

- Asegúrate de crear los directorios correspondientes y tener permisos correctos (`chown postgres:postgres`).
- Reinicia el servicio para aplicar cambios.

---

<a name="3"></a>
## 3. 📦 Respaldos base con `pg_basebackup`

```bash
pg_basebackup -D /ruta/backup_base -Ft -z -P -Xs -U postgres -h localhost -p 5432
```

- `-Ft`: formato TAR
- `-z`: comprimido (gzip)
- `-P`: progreso
- `-Xs`: método WAL = streaming

> 📌 Este respaldo incluye todo el clúster y una copia de los WALs actuales.

---

<a name="4"></a>
## 4. 🗂️ Archivado continuo de WALs

- Se activa automáticamente cuando `archive_mode = on`.
- WALs rotan cuando alcanzan 16MB o se invoca `pg_switch_wal()`.

#### Comando útil:

```sql
SELECT pg_switch_wal();  -- fuerza rotación del WAL
```

- Archivos con extensión `.ready` → pendientes
- Archivos con `.done` → archivados con éxito

> ✅ Herramientas como `xz` se pueden usar para comprimir los WALs en tiempo real.

---

<a name="5"></a>
## 5. 🧪 Generación y gestión de datos

### Inserciones simuladas:

```sql
CREATE TABLE empleados (...);
-- Funciones para generar registros aleatorios
SELECT insert_record() FROM generate_series(1, 1000000);
```

- Usar `SELECT now()` antes y después de operaciones críticas.
- Guardar el LSN con `SELECT pg_current_wal_insert_lsn();`.

> 🕒 Estos valores ayudan a definir el punto exacto para restaurar luego.

---

<a name="6"></a>
## 6. 🧭 Métodos de recuperación: LSN, tiempo y línea de tiempo

### 📍 A. Por Timestamp

```conf
recovery_target_time = '2025-07-08 08:00:00'
```

- Puede ser exacto o ligeramente anterior al cambio deseado.
- Cuidado: si la hora excede los WALs disponibles → error fatal.

### 📍 B. Por LSN

```conf
recovery_target_lsn = '0/13DAC308'
```

- Más preciso que la hora.
- Requiere que el LSN esté registrado manualmente antes de fallo.

### 📍 C. Por Timeline

```conf
recovery_target_timeline = '1'
```

- Útil si hubo promociones o cambios de réplica.
- Requiere archivo `.history`.

---

<a name="7"></a>
## 7. 💥 Restauración ante fallos

### 🧹 Pasos clave

1. Detener el servicio: `pg_ctl stop`
2. Borrar o renombrar el clúster: `rm -rf /data/*`
3. Restaurar desde backup base.
4. Crear archivo `recovery.signal`.
5. Configurar `postgresql.conf` con parámetros de recuperación.
6. Iniciar PostgreSQL: `pg_ctl start`
7. Monitorear logs para confirmar recuperación.

### 📌 Finalizar recuperación

```sql
SELECT pg_wal_replay_resume();  -- Promueve el servidor
```

- Esto borra `recovery.signal`.
- Inicia nueva timeline.

---

<a name="8"></a>
## 8. 📁 Archivos y estructuras involucradas

| Archivo/directorio         | Descripción                                         |
|---------------------------|-----------------------------------------------------|
| `pg_wal/`                 | WALs activos                                        |
| `archive_status/`         | Marca archivos como `.ready` o `.done`              |
| `recovery.signal`         | Activa modo recuperación al iniciar                 |
| `postgresql.auto.conf`    | Configuración persistente aplicada vía `ALTER SYSTEM` |
| `.history`                | Información de timeline si hubo promociones         |
| `pg_basebackup`           | Respaldos físicos de clúster completo               |

---

<a name="9"></a>
## 9. 🎯 Recomendaciones y buenas prácticas

- 🔄 Ejecutar `pg_switch_wal()` antes y después de operaciones críticas.
- 💾 Respaldar WALs en almacenamiento externo confiable.
- 🧪 Probar los planes de recuperación de forma periódica.
- 🛡️ Usar herramientas como `pgBackRest`, `Barman` o `Patroni` en producción.
- 🧭 Registrar LSNs y timestamps durante cambios de alto impacto.
- 📋 Documentar cada recuperación realizada para trazabilidad.

---

<a name="10"></a>
## 10. 🏁 Conclusión

Este manual recoge todos los aprendizajes de los 6 laboratorios que ejecutaste. Ahora tienes un documento completo que te permitirá:

- Configurar archivado WAL correctamente
- Realizar respaldos base y entender su estructura
- Ejecutar múltiples tipos de recuperación puntual
- Restaurar bases de datos completas incluso ante fallos graves
- Garantizar la integridad de datos en PostgreSQL

---

¿Te gustaría que empaquetemos este contenido en una guía paso a paso estilo "playbook de DBA"? También puedo ayudarte a transformarlo en una presentación para entrenar a tu equipo. 💼📊
