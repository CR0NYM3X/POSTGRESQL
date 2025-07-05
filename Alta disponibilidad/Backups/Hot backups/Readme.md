# **respaldo en caliente** 
en PostgreSQL es una técnica que te permite hacer una **copia completa y consistente del clúster de datos mientras el servidor está en funcionamiento**, sin detener el servicio ni interrumpir a los usuarios.
Cuando quieres hacer un respaldo manual del sistema de archivos del clúster, por ejemplo con rsync, tar o un snapshot LVM/ZFS, sin detener PostgreSQL.
 
###  ¿Qué lo hace “en caliente”?

Porque se realiza **con el servidor encendido**, atendiendo conexiones, ejecutando consultas y procesando transacciones.
 
###  ¿Qué se respalda?

- **Todo el directorio de datos** (`/var/lib/postgresql/X/main/` o el que corresponda).
- Los **archivos WAL archivados**, necesarios para recuperar el estado exacto del respaldo.
- El **archivo `backup_label`**, que marca la posición de inicio del respaldo.
 

### 🛠 ¿Cómo se hace correctamente?

1. Se ejecuta `pg_backup_start('mi_respaldo')` para iniciar el respaldo.
2. Se copia el directorio de datos manualmente (ej. con `rsync`, `tar`, snapshot).
3. Se ejecuta `pg_backup_stop()` cuando ya terminó la copia.
4. Se guardan los WAL desde el momento del respaldo hasta el punto final.
 

### ✅ Ventajas

- No requiere detener el servidor.
- Ideal para sistemas en producción 24/7.
- Puede combinarse con técnicas como Point-in-Time Recovery (PITR).
 
### ⚠️ Consideraciones

- No es lo mismo que un respaldo automático con `pg_basebackup` o herramientas como `pgBackRest`.
- Requiere cuidado: si copias sin las funciones `pg_backup_start()` / `stop()`, podrías tener inconsistencias.


### ️ ¿Cómo se usa en la práctica?

1. **Ejecutas**:

```sql
SELECT pg_backup_start('respaldo_manual', true);
```

 Esto marca el inicio del respaldo y fuerza un checkpoint.

2. **Copias tú mismo el directorio de datos**:

```bash
rsync -a --exclude pg_wal /var/lib/postgresql/15/main/ /backups/cliente/
```

 Aquí estás respaldando **todo el clúster**, no solo los WAL.

3. **Finalizas**:

```sql
SELECT pg_backup_stop();
```

Esto marca el final del respaldo y PostgreSQL sabe que ese conjunto de archivos es consistente.

4. **Copias los WAL archivados**:

```bash
rsync -a /pg_wal/pg_backup/ /backups/cliente/wal/
```

 Estos se usan para restaurar el estado exacto (por ejemplo, para PITR).





--- 
### ✅ Recomendación segura

Cuando haces un respaldo en caliente con `pg_backup_start()`, lo ideal es:

1. **Excluir `pg_wal/` del rsync**:

```bash
rsync -a --exclude pg_wal /var/lib/postgresql/15/main/ /backups/cliente/
```

2. **Copiar los WAL archivados aparte**:

```bash
rsync -a /pg_wal/pg_backup/ /backups/cliente/wal/
```

Así tienes:
- El respaldo del clúster consistente.
- Los WAL necesarios para recuperación (PITR).

###  ¿Por qué excluir `pg_wal/`?

- Porque contiene archivos temporales y en uso.
- Porque los WAL archivados son más seguros y estables.
- Porque durante restauración, PostgreSQL usará `restore_command` para leer los WAL archivados, no los activos.

### 🧾 ¿Por qué se hace así?

- El respaldo base debe ser **consistente**, por eso se usa `pg_backup_start()` y `stop()`.
- Los WAL archivados son **independientes** y se pueden copiar después, incluso mientras el servidor sigue funcionando.
- El archivo `backup_label` generado por `pg_backup_stop()` indica **desde qué WAL se debe comenzar la recuperación**.

--- 

### ️ ¿Qué pasa si usas `rsync` sin `pg_backup_start()`?

Si haces:

```bash
rsync -a /var/lib/postgresql/15/main/ /backups/cliente/
```

**sin ejecutar `pg_backup_start()`**, corres el riesgo de:

- Copiar archivos **mientras están siendo modificados**.
- Obtener un respaldo **inconsistente o corrupto**.
- Que los archivos WAL no coincidan con el estado de los datos copiados.

Esto es especialmente peligroso si hay mucha actividad en la base de datos durante el respaldo.

###  ¿Qué hace `pg_backup_start()`?

- Le dice a PostgreSQL: “Voy a hacer un respaldo, por favor estabiliza el estado”.
- Fuerza un **checkpoint** para que los datos estén sincronizados en disco.
- Crea un archivo `backup_label` que marca el inicio del respaldo.
- Permite que el respaldo sea **consistente y recuperable**.

Luego tú haces el `rsync`, y al final ejecutas `pg_backup_stop()` para cerrar el respaldo correctamente.
