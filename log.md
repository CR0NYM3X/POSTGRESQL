
cat /sysd/datad/postgresql.conf | grep log_

#  SYSLOG
```sql
https://documentation.solarwinds.com/en/success_center/loggly/content/admin/postgresql-logs.htm
https://gist.github.com/ceving/4eae4437d793ae4752b8582253872067

```

# Habilita el recolector de logs.
logging_collector = on


log_statement = 'all'

'none': No se registrarán declaraciones SQL (por defecto).
'ddl': Solo se registrarán declaraciones que modifican la estructura de la base de datos, como CREATE, ALTER, DROP, etc.
'mod': Se registrarán declaraciones que modifican datos, como INSERT, UPDATE y DELETE.
'read': Se registrarán declaraciones SELECT y COPY FROM.


# Configura la carpeta donde se almacenarán los logs.
log_directory = '/ruta/a/la/carpeta/pg_log'

# Configura el formato del nombre del archivo de log.
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'    # Nombre del archivo de registro

# Retención de logs basada en el tamaño.
log_rotation_size = 10MB  # Ajusta el tamaño según tus necesidades.

# Define la zona horaria utilizada para registrar la fecha y la hora en los archivos de log
log_timezone = 'America/Mazatlan'

# Establece los permisos del archivo de log. En este caso, se establece en 0600, 
log_file_mode = 0600

# Cuando esta opción está activada (on), indica que los archivos de log deben truncarse (vaciar) al realizar una rotación. La rotación ocurre cuando se alcanza un tamaño máximo (configurado por log_rotation_size) o después de un cierto período
log_truncate_on_rotation = on


Auditorias:
 https://github.com/pgaudit/pgaudit/tree/master
 https://www.crunchydata.com/blog/pgaudit-auditing-database-operations-part-1
 https://severalnines.com/blog/how-to-audit-postgresql-database/
