

```

wal_level = 'minimal'
max_wal_senders = 0

fsync = off                 # No espera confirmación del disco físico (ultra rápido, pero fatal si hay apagón).
synchronous_commit = off    # Confirma los INSERTs sin esperar a que el log (WAL) toque el disco.
full_page_writes = off      # Evita escribir bloques de seguridad extra por cada modificación.
autovacuum = off            # Apaga el proceso de limpieza automático que competiría por CPU y disco.
archive_mode = off          # Detiene el envío continuo de copias de seguridad (logs) por red/disco.

# Como solo usaremos 1 hilo, podemos darle mucha más memoria a ese hilo 
# para que cree los índices rapidísimo.
maintenance_work_mem = 32GB # RAM masiva asignada exclusivamente para acelerar la creación de índices.

max_wal_size = 64GB         # Permite acumular muchos cambios antes de forzar una escritura masiva al disco.
checkpoint_timeout = 1h     # Alarga el tiempo de espera entre cada volcado obligatorio al disco.

max_parallel_maintenance_workers 

nohup bash -c 'zcat db_test_fast_gzip.sql.gz | psql -U postgres -d db_test2 -q' > restore_errores.log 2>&1 &


```
