 

**PostgreSQL 17**, ya existe **soporte nativo para respaldos incrementales**


## 🆕 ¿Qué cambia en PostgreSQL 17?

### ✅ **Respaldo incremental nativo**
a partir de la versión 17 (lanzada a finales de 2024), PostgreSQL admite respaldos incrementales de forma nativa.

Antes de esta versión, la única forma "nativa" de lograr algo similar era mediante el archivado de registros WAL (Write-Ahead Logging) para realizar Point-In-Time Recovery (PITR), o utilizando herramientas externas muy populares como pgBackRest, Barman o WAL-G.

---

## 🔧 ¿Cómo funciona?

1. **Primero haces un respaldo completo** con `pg_basebackup`.
2. Luego, puedes hacer respaldos incrementales que solo copian los **cambios desde el último respaldo** (ya sea completo o incremental).
3. Se usa un nuevo parámetro:  
   ```bash
   pg_basebackup --incremental=PATH_TO_MANIFEST
   ```
4. También se puede usar la herramienta nueva `pg_combinebackup` para **reconstruir el respaldo completo** a partir del respaldo base + incrementales.

---

 


##  **ÍNDICE DEL LABORATORIO**

1.  Objetivo
2.  Requisitos previos
3.  ¿Qué es el respaldo incremental en PostgreSQL v17?
4.  Caso de uso real (Simulación empresarial)
5.  Arquitectura y flujo del proceso
6.  Procedimiento paso a paso
    *   6.1 Instalación y preparación
    *   6.2 Configuración del entorno
    *   6.3 Creación de datos simulados
    *   6.4 Respaldo completo inicial
    *   6.5 Respaldo incremental con `pg_basebackup --incremental`
    *   6.6 Combinación de respaldos con `pg_combinebackup`
    *   6.7 Restauración completa
7.  Validación
8.  Buenas prácticas
9.  Visualización del flujo
10. Conclusiones
11. Bibliografía



## **1. Objetivo**

Implementar un laboratorio que demuestre cómo realizar **respaldos incrementales en PostgreSQL v17** usando las nuevas capacidades de `pg_basebackup --incremental` y `pg_combinebackup`, asegurando la restauración completa.

 

## **2. Requisitos previos**

*   **SO:** Ubuntu 22.04 LTS
*   **PostgreSQL:** v17 instalado
*   **Herramientas:** `pg_basebackup`, `pg_combinebackup`
*   **Permisos:** usuario `postgres` con privilegios
*   **Espacio en disco:** mínimo 3 GB
*   **Conocimientos:** básicos de PostgreSQL y shell



## **3. ¿Qué es el respaldo incremental en PostgreSQL v17?**

PostgreSQL 17 introduce la opción `--incremental` en `pg_basebackup`, que permite crear respaldos que contienen **solo los bloques modificados desde el último respaldo base**, reduciendo espacio y tiempo.\
`pg_combinebackup` permite **fusionar respaldos incrementales con el respaldo base** para obtener un backup completo restaurable.



## **4. Caso de uso real**

**Empresa:** *RetailMX S.A.*\
**Escenario:** Base de datos de ventas (50 GB). Necesitan **full backup semanal + incrementales diarios** para optimizar almacenamiento y tiempo.


 



## **6. Procedimiento paso a paso**

### **6.1 Instalación**

```bash
sudo apt update && sudo apt install postgresql-17 postgresql-client-17
```

### **6.2 Configuración**

Activar WAL y parámetros necesarios:

```bash
sudo -u postgres psql -c "ALTER SYSTEM SET wal_level = replica;
ALTER SYSTEM SET  summarize_wal = on;"
sudo systemctl restart postgresql
```

### **6.3 Crear datos simulados**

```bash
sudo -u postgres psql <<EOF
CREATE DATABASE retail;
\c retail
CREATE TABLE ventas(id SERIAL, producto TEXT, cantidad INT, fecha DATE);
INSERT INTO ventas(producto,cantidad,fecha)
SELECT 'Producto-'||generate_series(1,10000), (random()*100)::INT, CURRENT_DATE;
EOF
```

### **6.4 Respaldo completo inicial**

```bash
pg_basebackup -D /backups/full -Fp -Xs -P -U postgres
```

**Salida simulada:**

    pg_basebackup: starting base backup
    pg_basebackup: transferring data
    pg_basebackup: base backup completed

### **6.5 Respaldo incremental**

Modificar datos:

```bash
sudo -u postgres psql -d retail -c "INSERT INTO ventas(producto,cantidad,fecha) VALUES('Producto-Nuevo',50,CURRENT_DATE);"
```

Crear incremental:

```bash
pg_basebackup -D /backups/inc1 --incremental=/backups/full/backup_manifest -Fp -Xs -P -U postgres
```

**Salida simulada:**

    pg_basebackup: starting incremental backup
    pg_basebackup: transferring changed blocks
    pg_basebackup: incremental backup completed

### **6.6 Combinar respaldos**

```bash
pg_combinebackup --incremental-path=/backups/inc1 --base-path=/backups/full --output-path=/backups/combined
```

**Salida simulada:**

    pg_combinebackup: combining base and incremental backups
    pg_combinebackup: combined backup ready at /backups/combined

### **6.7 Restauración**

Detener PostgreSQL:

```bash
sudo systemctl stop postgresql
```

Restaurar:

```bash
rm -rf /var/lib/postgresql/17/main/*
cp -R /backups/combined/* /var/lib/postgresql/17/main/
sudo systemctl start postgresql
```



## **7. Validación**

```bash
sudo -u postgres psql -d retail -c "SELECT COUNT(*) FROM ventas;"
```

**Salida esperada:**

     count
    -------
     10001



## **8. Buenas prácticas**

*   Automatizar con cron.
*   Verificar integridad con `pg_verifybackup`.
*   Probar restauración periódicamente.

 


## **10. Conclusiones**

Este laboratorio demuestra cómo usar las nuevas funciones de PostgreSQL 17 para respaldos incrementales y restauración eficiente.
 
