```bash

se usa Quieres activar funcionalidades que requieren archive_mode = on, como pg_rewind o pg_basebackup, pero no necesitas archivar WALs. Es una forma segura de "engañar" a PostgreSQL para que crea que está archivando, sin hacerlo realmente.
 Cuando usas streaming replication con replication slots, los WALs ya se retienen automáticamente mientras el standby los consume. No necesitas archive_command, pero pg_rewind sí requiere archive_mode = on. Para cumplir con esa dependencia sin copiar los WALs, se usa /bin/true.

archive_mode = on
archive_command = '/bin/true'

```
 
