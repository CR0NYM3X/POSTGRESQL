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

```
