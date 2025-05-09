 

## 🧱 TIPOS DE RESPALDOS EN POSTGRESQL

### 1. 🧠 **Backup lógico**
Realiza una copia de los datos en formato SQL o personalizado.

#### Herramientas:
- `pg_dump`
- `pg_dumpall`

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

### 2. 💽 **Backup físico**
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

### 3. ⏳ **Backup incremental / PITR (Point-In-Time Recovery)**
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

## 📌 Comparación rápida

| Tipo de respaldo | Nivel | Flexible | Rápido | Ideal para |
|------------------|-------|----------|--------|------------|
| Lógico (`pg_dump`) | Tabla/BD | ✅ Sí | 🟡 Medio | Migraciones, respaldo parcial |
| Físico (`pg_basebackup`) | Servidor completo | ❌ No | ✅ Rápido | Recuperación total, réplicas |
| PITR | Servidor completo + tiempo | 🟡 Parcial | 🟡 Medio | Recuperación ante errores |


 
## 🧱 1. **Respaldo completo (Full Backup)**

### 📌 ¿Qué es?
- Copia **todo** el contenido de la base de datos (o del sistema) en un solo respaldo.

### ✅ Ventajas:
- Restauración rápida y directa.
- Independiente de otros respaldos.

### ❌ Desventajas:
- Consume más espacio.
- Toma más tiempo en bases de datos grandes.

### 🧠 ¿Cuándo usarlo?
- Como respaldo base.
- Antes de actualizaciones importantes.

---

## 🔁 2. **Respaldo diferencial**

### 📌 ¿Qué es?
- Copia **solo los cambios** realizados desde el **último respaldo completo**.

### ✅ Ventajas:
- Más rápido que un respaldo completo.
- Restauración más rápida que con incrementales (solo necesitas el respaldo completo + el último diferencial).

### ❌ Desventajas:
- Aumenta de tamaño con el tiempo hasta el próximo respaldo completo.

### 🧠 ¿Cuándo usarlo?
- Cuando necesitas un equilibrio entre velocidad de respaldo y velocidad de restauración.

---

## 🔄 3. **Respaldo incremental**

### 📌 ¿Qué es?
- Copia **solo los cambios** desde el **último respaldo (ya sea completo o incremental)**.

### ✅ Ventajas:
- Muy eficiente en espacio y tiempo de respaldo.
- Ideal para respaldos frecuentes (cada hora, por ejemplo).

### ❌ Desventajas:
- Restauración más lenta (necesitas el respaldo completo + todos los incrementales hasta el punto deseado).

### 🧠 ¿Cuándo usarlo?
- En entornos con muchos cambios y necesidad de respaldos frecuentes.

---

## 📊 Comparación rápida

| Tipo         | Tamaño | Velocidad de respaldo | Velocidad de restauración | Dependencias |
|--------------|--------|------------------------|----------------------------|--------------|
| Completo     | Grande | Lento                  | Rápido                     | Ninguna      |
| Diferencial  | Medio  | Medio                  | Medio                      | Completo     |
| Incremental  | Pequeño| Rápido                 | Lento                      | Completo + todos los incrementales |

---

## 🧰 ¿Cómo se aplican en PostgreSQL?

PostgreSQL **no tiene respaldo incremental o diferencial nativo** como tal, pero puedes implementarlos con herramientas como:

- **Barman** o **pgBackRest**: soportan respaldos incrementales y diferenciales.
- **WAL Archiving + PITR**: puedes simular incrementales al guardar los WALs entre respaldos completos.
 
