## Configurar los datos que guarda en el LOG

Por ejemplo, si solo deseas registrar consultas de modificación de datos, puedes configurar log_statement de la siguiente manera en tu archivo postgresql.conf:
```
log_statement = 'mod'
```
Otras opciones
```
none: No se registra ninguna consulta.
ddl: Solo se registran las consultas de definición de datos (DDL), como CREATE, ALTER, DROP, etc.
mod: Solo se registran las consultas de modificación de datos (DML), como INSERT, UPDATE, DELETE, etc.
all: Se registran todas las consultas, tanto DDL como DML.
```
