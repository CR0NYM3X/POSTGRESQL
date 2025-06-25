**pg_basebackup** – Utilizado para respaldos físicos en entornos de alta disponibilidad. Soporta:  
- Respaldos completos del clúster
- Replicación de WAL  
- Restauración rápida en otro servidor
- respaldos y Restaurar incrementales introducida en PostgreSQL 17

pg_combinebackup 
 

```
## en la version >= 15 agregaron el tipo de compres cliente o server
## - Si tu **servidor está sobrado de CPU y tienes red limitada**, usa compresión en el servidor.
### - Si tu **cliente tiene buena CPU** y la red es rápida, deja la compresión en el cliente.

postgres@pruebas-dba ~ $ $PGBIN15/pg_basebackup  --help | grep -i "\-z"
  -z, --gzip             compress tar output
  -Z, --compress=[{client|server}-]METHOD[:DETAIL]
  -Z, --compress=none    do not compress tar output
  
postgres@pruebas-dba ~ $ $PGBIN14/pg_basebackup  --help | grep -i "\-z"
  -z, --gzip             compress tar output
  -Z, --compress=0-9     compress tar output with given compression level


------------------------------------------------------------
 

```

### ¿Para qué sirve `pg_combinebackup`?  
Es una herramienta nueva introducida en PostgreSQL 17 que permite reconstruir una copia de seguridad completa a partir de respaldos incrementales.  
 Cuando haces respaldos incrementales con pg_basebackup, cada uno depende del anterior. pg_combinebackup toma esa cadena de respaldos (el completo + los incrementales) y los fusiona en una copia de seguridad completa “sintética”, lista para restaurar directamente.
 
 
 
###   ¿Qué es el **listado en el `manifiesto`**?

Cuando haces un respaldo físico con `pg_basebackup`, PostgreSQL puede generar un archivo llamado `backup_manifest`. Este archivo contiene un **listado detallado de todos los archivos incluidos en el respaldo**, junto con:

- Sus rutas relativas.
- Tamaños.
- Checksums (sumas de verificación).
- Tiempos de modificación.

Es como un inventario digital del respaldo, que permite saber exactamente qué se respaldó y cómo verificarlo después.

---

###   ¿Para qué sirve `pg_verifybackup`?

Es una herramienta que **verifica la integridad de un respaldo físico** usando ese manifiesto.   te dice si tu respaldo está completo, sin corrupción y listo para usarse. . Hace varias comprobaciones:

1. **Lee el `backup_manifest`** y valida su formato y checksum interno.
2. **Compara los archivos reales del respaldo** con los listados en el manifiesto:
   - Detecta archivos faltantes o extra.
3. **Recalcula los checksums** de los archivos y los compara con los del manifiesto.
4. **Verifica que los archivos WAL necesarios** para recuperar el respaldo estén presentes y legibles.


### Checksum 
sirve para  Detectar corrupción a tiempo y puede salvarte de un desastre. PostgreSQL calcula una suma de verificación para cada bloque de datos que escribe en disco. Luego, al leer ese bloque, verifica que la suma coincida. Si no coincide, detecta corrupción silenciosa (por ejemplo, por fallos de hardware o discos defectuosos).  Puedes usarla como parte de un proceso de mantenimiento o verificación periódica.
```
--- Cuando usarlo pg_checksums---
- Antes o después de una migración.
- Antes de hacer un pg_basebackup o un pg_upgrade.
- Después de un fallo de hardware o corte de energía.
- Como parte de un mantenimiento programado. 
- Verificaciones periódicas en entornos críticos.

# el servidor debe estar apagado completamente, ya que necesita acceso exclusivo a los archivos de datos para usar la herramienta pg_checksums.
 $PGBIN16/pg_ctl stop -D /sysx/data16/DATANEW/data_maestro
 

# Verificar integridad
$PGBIN16/pg_checksums -D /sysx/data16/DATANEW/data_maestro --check --progress

45/45 MB (100%) computed
Checksum operation completed
Files scanned:   1857
Blocks scanned:  5826
Bad checksums:  0
Data checksum version: 1

# Activar o desactivar checksum
$PGBIN16/pg_checksums -D /sysx/data16/DATANEW/data_esclavo62 --enable --progress 
$PGBIN16/pg_checksums -D /sysx/data16/DATANEW/data_esclavo62 --disable --progress
```
