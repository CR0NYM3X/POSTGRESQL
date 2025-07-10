
## 🧱 TIPOS DE RESPALDOS EN POSTGRESQL

# 1. 🧠 **Backup lógico**
Realiza una copia de los datos en formato SQL o personalizado.

#### Herramientas:
- `pg_dump : solo una base de datos`
- `pg_dumpall : Todas las base de datos`

#### Características:
- Puedes respaldar **una base de datos o una tabla específica**.
- El resultado es un archivo `.sql` o `.custom` que puedes restaurar con `psql` o `pg_restore`.

#### ¿Para qué sirve?
- Migraciones entre versiones.
- Respaldos selectivos (solo ciertas tablas).
- Fácil de mover entre servidores.

#### Ejemplo:
```bash
pg_dump -U usuario -d mibasedatos -f respaldo.sql
```

---

# 2. 💽 **Backup físico**


### 2.1 Respaldo Completo del DATA 
Copia **todo el directorio de datos** de PostgreSQL.

#### Herramientas:
- `pg_basebackup`
- Copia manual del directorio de datos (con precaución)

#### Características:
- Es una copia exacta del estado del servidor.
- Se usa para **replicación física** o recuperación total.

#### ¿Para qué sirve?
- Restaurar el servidor completo en caso de fallo.
- Crear réplicas físicas (streaming).

#### Ejemplo:
```bash
pg_basebackup -h localhost -D /ruta/destino -U replicador -Fp -Xs -P
```

---

### 2.2. ⏳ **Backup incremental / PITR (Point-In-Time Recovery)**
Permite restaurar la base de datos a un punto exacto en el tiempo.

#### Requiere:
- Backup físico inicial
- Archivar los WALs (`archive_mode = on`)

#### ¿Para qué sirve?
- Recuperarse de errores humanos (ej. borrar datos por accidente).
- Restaurar a un estado anterior sin perder todo.

---

## 🧠 ¿Cómo ayudan los respaldos?

- **Prevención de pérdida de datos** por fallos, errores humanos o corrupción.
- **Migraciones seguras** entre versiones o servidores.
- **Auditoría y análisis** de datos históricos.
- **Pruebas y desarrollo** con datos reales sin afectar producción.

---


 
 

### 🔄 Respaldo Incremental

- **¿Qué guarda?** Solo los *cambios* realizados desde el último respaldo (sea completo o incremental).
- **Ventajas**:
  - Usa menos espacio.
  - Es más rápido de generar.
- **Desventajas**:
  - La restauración requiere *toda la cadena* de respaldos (completo + cada incremental siguiente).
- **Ejemplo**:
  - Día 1: respaldo completo.
  - Día 2: respaldo incremental (solo cambios desde Día 1).
  - Día 3: respaldo incremental (solo cambios desde Día 2).
 

### 📈 Respaldo Diferencial

- **¿Qué guarda?** Todos los *cambios* hechos desde el último respaldo **completo**, sin importar cuántos diferenciales haya en el medio.
- **Ventajas**:
  - Restaurar es más simple (solo el completo + el último diferencial).
- **Desventajas**:
  - Tamaño crece con el tiempo si no se hace respaldo completo con frecuencia.
- **Ejemplo**:
  - Día 1: respaldo completo.
  - Día 2: respaldo diferencial (cambios desde Día 1).
  - Día 3: respaldo diferencial (cambios desde Día 1 nuevamente).

 

### 🆚 Comparación rápida

| Característica            | Incremental             | Diferencial             |
|---------------------------|--------------------------|--------------------------|
| Base de comparación       | Último respaldo (cualquiera) | Último respaldo **completo** |
| Espacio usado             | 🟢 Menos                 | 🟡 Más (va creciendo)     |
| Restauración              | 🔴 Más compleja          | 🟢 Más sencilla           |
| Velocidad de respaldo     | 🟢 Rápido                | 🟡 Intermedio             |

 

---

## 🧰 ¿Cómo se aplican en PostgreSQL?

PostgreSQL **no tiene respaldo incremental o diferencial nativo** como tal, pero puedes implementarlos con herramientas como:

- **Barman** o **pgBackRest**: soportan respaldos incrementales y diferenciales.
- **WAL Archiving + PITR**: puedes simular incrementales al guardar los WALs entre respaldos completos.
 




---

## Bibliografía 
```
https://dbsguru.com/physical-postgresql-backup/
https://www.mafiree.com/readBlog/incremental-backup-in-postgresql-17
https://www.mydbops.com/blog/postgresql-17-incremental-backup-pg-basebackup-pg-combinebackup
```
