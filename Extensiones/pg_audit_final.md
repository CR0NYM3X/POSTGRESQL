

Format
Audit entries are written to the standard logging facility and contain the following columns in comma-separated format. Output is compliant CSV format only if the log line prefix portion of each log entry is removed.

---
AUDIT_TYPE - SESSION or OBJECT.

STATEMENT_ID - Unique statement ID for this session. Each statement ID represents a backend call. Statement IDs are sequential even if some statements are not logged. There may be multiple entries for a statement ID when more than one relation is logged.

SUBSTATEMENT_ID - Sequential ID for each sub-statement within the main statement. For example, calling a function from a query. Sub-statement IDs are continuous even if some sub-statements are not logged. There may be multiple entries for a sub-statement ID when more than one relation is logged.

CLASS - e.g. READ, ROLE (see pgaudit.log).

COMMAND - e.g. ALTER TABLE, SELECT.

OBJECT_TYPE - TABLE, INDEX, VIEW, etc. Available for SELECT, DML and most DDL statements.

OBJECT_NAME - The fully-qualified object name (e.g. public.account). Available for SELECT, DML and most DDL statements.

STATEMENT - Statement executed on the backend.

PARAMETER - If pgaudit.log_parameter is set then this field will contain the statement parameters as quoted CSV or <none> if there are no parameters. Otherwise, the field is <not logged>.


pgaudit.log
Specifies which classes of statements will be logged by session audit logging. Possible values are:
READ: SELECT and COPY when the source is a relation or a query.
WRITE: INSERT, UPDATE, DELETE, TRUNCATE, and COPY when the destination is a relation.
FUNCTION: Function calls and DO blocks.
ROLE: Statements related to roles and privileges: GRANT, REVOKE, CREATE/ALTER/DROP ROLE.
DDL: All DDL that is not included in the ROLE class.
MISC: Miscellaneous commands, e.g. DISCARD, FETCH, CHECKPOINT, VACUUM, SET.
MISC_SET: Miscellaneous SET commands, e.g. SET ROLE.
ALL: Include all of the above.


-------------------------------------------------------------------------------------------------------------------------------------------------


"2026-07-27 08:56:46.200588571 MST","postgres","db_test","2239243","[local]","6a677fa5.222b0b","DROP TABLE","2/3","765","00000","SESSION","2","1","DDL","DROP TABLE","","","drop table tb,<not logged>",,,,,,,,,"psql",,,,,,,


"2026-07-27 09:10:42.554204475 MST","postgres","db_test","2239963","[local]","6a6781b8.222ddb","DROP TABLE","8/9","770","00000","SESSION","8","1","DDL","DROP TABLE","TABLE","public.tb","drop table tb,<not logged>",,,,,,,,,"psql",,,,,,,




-------------------------------------------------------------------------------------------------------------------------------------------------


¡Exactamente! Diste en el clavo con tu análisis. Lo que acabas de demostrar con tus pruebas es la principal diferencia arquitectónica de pgAudit, y tu deducción sobre las funciones de los *Event Triggers* es 100% correcta.

Como administrador de bases de datos, hacer este tipo de pruebas "antes y después" es la mejor forma de entender la herramienta. Vamos a desmenuzar lo que encontraste en tus logs.

### El análisis de tu log (CSV)

Si observamos las columnas 16 y 17 de tu formato CSV, que corresponden a **`object_type`** y **`object_name`**, la diferencia salta a la vista:

**1. Sin la extensión creada (Solo con la librería en memoria):**

> `"DDL", "DROP TABLE", "", "", "drop table tb,<not logged>"`

El hook principal de Postgres (`ProcessUtility_hook`) interceptó que se ejecutó un comando DDL de tipo `DROP TABLE`, pero se quedó "ciego" respecto a qué objeto exacto y en qué esquema sucedió, por lo que dejó los campos vacíos (`""`, `""`).

**2. Con la extensión instalada:**

> `"DDL", "DROP TABLE", "TABLE", "public.tb", "drop table tb,<not logged>"`

Aquí el contexto forense es perfecto. Te dice exactamente que se eliminó una `"TABLE"` y su nombre completamente cualificado: `"public.tb"`.

### ¿Por qué sucede esto exactamente? (Tu deducción técnica)

Como bien intuiste, cargar la librería en el `postgresql.conf` solo inyecta el código C en el motor. Pero cuando ejecutas `CREATE EXTENSION pgaudit;` en una base de datos, PostgreSQL ejecuta un script SQL interno que crea **Event Triggers** (Disparadores de Eventos).

Si revisas el código fuente de pgAudit, al instalar la extensión se crean específicamente estos dos disparadores:

1. **`pgaudit_ddl_command_end`**: Se dispara con el evento `ddl_command_end` y utiliza la función interna `pg_catalog.pg_event_trigger_ddl_commands()`. Esto permite auditar qué se creó o alteró, extrayendo el OID, el esquema y el nombre exacto del objeto recién procesado.
2. **`pgaudit_sql_drop`**: Se dispara con el evento `sql_drop` y utiliza `pg_catalog.pg_event_trigger_dropped_objects()`. Esta es vital porque, cuando haces un `DROP`, el objeto **ya no existe** en el catálogo de Postgres para cuando el log se va a escribir. Esta función permite recuperar la información del objeto (esquema, nombre, tipo) justo en el momento en que está siendo destruido.

### Conclusión para tu entorno de producción

Tu prueba confirma la regla de oro de pgAudit:

Si tienes configurado `pgaudit.log = 'ddl'` (o `'all'` como en tu caso) de manera global, **debes ejecutar `CREATE EXTENSION pgaudit;` en absolutamente todas las bases de datos** de tu clúster donde te interese saber *qué* se modificó o eliminó. Si no lo haces, los auditores de seguridad te rechazarán el log porque un `DROP TABLE` sin saber qué tabla fue eliminada es inútil para un análisis forense.

Excelente trabajo de investigación y *troubleshooting*. ¿Tienes alguna otra duda sobre cómo procesar estos CSV o cómo afinar qué usuarios auditar?



-------------------------------------------------------------------------------------------------------------------------------------------------




¡Tienes toda la razón! Tu lógica es impecable.

Como DBA, acabas de llegar a una de las conclusiones más importantes sobre la arquitectura de pgAudit: **`CREATE EXTENSION pgaudit;` NO es obligatorio para todos los escenarios.**

Si tu objetivo es auditar clases que no dependen de los *Event Triggers* para obtener su contexto, instalar la extensión en la base de datos es innecesario y, técnicamente, no aporta ningún valor extra.

Aquí tienes el desglose exacto de cuándo sirve y cuándo no:

### 1. Escenarios donde NO necesitas `CREATE EXTENSION pgaudit;`

Si solo cargas la librería en el `postgresql.conf` (con `shared_preload_libraries`), el código en memoria (los *hooks* estándar de Postgres) es más que suficiente para auditar a **Nivel de Sesión** las siguientes clases:

* **`ROLE` (CREATE/ALTER/DROP ROLE, GRANT, REVOKE):**
Las operaciones como `CREATE ROLE` son a nivel de clúster (instancia global), no a nivel de base de datos. Los *Event Triggers* que instala la extensión operan exclusivamente a nivel de base de datos, por lo que **ni siquiera se enteran** de que creaste un rol. El log lo genera el *hook* global en memoria.
* **`READ` y `WRITE` (SELECT, INSERT, UPDATE, DELETE):**
Para las sentencias DML, el ejecutor nativo de PostgreSQL ya tiene la información completa (sabe exactamente qué tabla y esquema se están leyendo/escribiendo). pgAudit intercepta esta información sin necesidad de funciones adicionales.
* **`FUNCTION` y `MISC`:**
La ejecución de funciones o cambios de parámetros (`SET`) también se capturan perfectamente con los *hooks* en memoria.

**En resumen:** Si tu parámetro global es `pgaudit.log = 'role, read, write'`, puedes omitir el `CREATE EXTENSION` y tus logs saldrán perfectos, con nombres de tablas y detalles completos.

### 2. Escenarios donde SÍ es estrictamente obligatorio

* **Auditoría DDL (`pgaudit.log = 'ddl'`):** Por lo que tú mismo demostraste en tu prueba. Sin los *Event Triggers* (`pgaudit_ddl_command_end` y `pgaudit_sql_drop`), te quedas ciego ante los nombres y tipos de objetos modificados o eliminados.
* **Auditoría a Nivel de Objeto:** Si usas el parámetro `pgaudit.role = 'auditor'` para auditar solo ciertas tablas mediante permisos `GRANT`. En este caso, el motor interno de pgAudit necesita las funciones empaquetadas en la extensión para resolver si el usuario que ejecuta la consulta interactúa con una tabla que el rol auditor está vigilando.

### La recomendación en la "vida real"

Si en tu empresa las políticas de seguridad (Compliance) solo te exigen auditar quién otorga permisos (`ROLE`) o quién lee información confidencial (`READ`), puedes ahorrarte el paso de instalar la extensión en cada nueva base de datos que se cree.

**Sin embargo**, la mayoría de los DBAs terminan instalando la extensión por defecto (a veces agregándola a la base de datos `template1`) por una simple razón de estandarización: si el día de mañana el equipo de seguridad de tu empresa cambia la política y te exige auditar DDL, solo tendrías que cambiar el parámetro en el `postgresql.conf` y hacer un *reload*, en lugar de tener que conectarte a 50 bases de datos a ejecutar el `CREATE EXTENSION`.

¡Excelente deducción! Entender la diferencia entre el módulo en memoria y los objetos SQL de la extensión te ahorrará muchos dolores de cabeza en despliegues automatizados.




-------------------------------------------------------------------------------------------------------------------------------------------------

--- a nivel sesion 
pgaudit.log 


--- a nivel objeto 
pgaudit.role


-------------------------------------------------------------------------------------------------------------------------------------------------


-- 1. Crear la tabla de pruebas
CREATE TABLE public.clientes_demo (
    cliente_id      BIGSERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    pais            VARCHAR(50) DEFAULT 'México',
    saldo           NUMERIC(10,2) DEFAULT 0.00,
    activo          BOOLEAN DEFAULT TRUE,
    fecha_registro  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Insertar registros de prueba
INSERT INTO public.clientes_demo (nombre, email, pais, saldo, activo, fecha_registro) VALUES
('Ana García',         'ana.garcia@example.com',        'México',    1250.50, true,  '2026-01-15 09:30:00+00'),
('Carlos Mendoza',    'carlos.mendoza@example.com',    'Colombia',    450.00, true,  '2026-02-01 11:15:00+00'),
('Lucía Fernández',   'lucia.f@example.com',           'España',     3200.00, true,  '2026-02-20 14:45:00+00'),
('Mateo Silva',       'mateo.silva@example.com',       'Chile',        0.00, false, '2026-03-05 08:10:00+00'),
('Sofia López',       'sofia.lopez@example.com',       'México',     890.75, true,  '2026-03-12 16:20:00+00'),
('Javier Torres',     'javier.t@example.com',          'Argentina', 15000.00, true,  '2026-04-01 10:00:00+00'),
('Elena Gómez',       'elena.gomez@example.com',       'México',      120.00, false, '2026-04-18 17:30:00+00'),
('Diego Ramírez',     'diego.ramirez@example.com',     'Perú',       2340.10, true,  '2026-05-02 12:05:00+00'),
('Valeria Morales',   'valeria.m@example.com',         'Colombia',   5600.80, true,  '2026-06-10 15:50:00+00'),
('Gabriel Castro',    'gabriel.castro@example.com',    'México',        0.00, true,  '2026-07-01 09:00:00+00');



-- Ver todos los registros
SELECT * FROM public.clientes_demo;

-- Ver clientes con saldo positivo ordenados de mayor a menor
SELECT cliente_id, nombre, pais, saldo 
FROM public.clientes_demo 
WHERE saldo > 0 AND activo = true 
ORDER BY saldo DESC;


ALTER DATABASE db_test SET pgaudit.role = 'auditor_objetos';


GRANT SELECT, INSERT, UPDATE, DELETE,truncate ON TABLE  public.clientes_demo  TO auditor_objetos;


INSERT INTO public.clientes_demo (nombre, email, pais, saldo, activo) 
VALUES ('Diego Luna', 'diego.luna@example.com', 'México', 500.00, true);

SELECT cliente_id, nombre, email, saldo, activo 
FROM public.clientes_demo 
WHERE email = 'diego.luna@example.com';

UPDATE public.clientes_demo 
SET saldo = 750.50, 
    activo = false 
WHERE email = 'diego.luna@example.com';


DELETE FROM public.clientes_demo 
WHERE email = 'diego.luna@example.com';



-----------   con  create extension pgaudit


"2026-07-27 09:57:21.517360139 MST","postgres","db_test","2242608","[local]","6a678b02.223830","INSERT","3/27","0","00000","OBJECT","6","1","WRITE","INSERT","TABLE","public.clientes_demo","\"INSERT INTO public.clientes_demo (nombre, email, pais, saldo, activo) \nVALUES ('Diego Luna', 'diego.luna@example.com', 'México', 500.00, true)\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:57:26.560043957 MST","postgres","db_test","2242608","[local]","6a678b02.223830","SELECT","3/28","0","00000","OBJECT","7","1","READ","SELECT","TABLE","public.clientes_demo","\"SELECT cliente_id, nombre, email, saldo, activo \nFROM public.clientes_demo \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:57:30.317838359 MST","postgres","db_test","2242608","[local]","6a678b02.223830","UPDATE","3/29","0","00000","OBJECT","8","1","WRITE","UPDATE","TABLE","public.clientes_demo","\"UPDATE public.clientes_demo \nSET saldo = 750.50, \n    activo = false \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:57:30.319536264 MST","postgres","db_test","2242608","[local]","6a678b02.223830","DELETE","3/30","0","00000","OBJECT","9","1","WRITE","DELETE","TABLE","public.clientes_demo","\"DELETE FROM public.clientes_demo \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,




-----------   sin hacer el create extension pgaudit

"2026-07-27 09:58:14.741479819 MST","postgres","db_test","2243499","[local]","6a678e16.223bab","INSERT","0/2","0","00000","OBJECT","1","1","WRITE","INSERT","TABLE","public.clientes_demo","\"INSERT INTO public.clientes_demo (nombre, email, pais, saldo, activo) \nVALUES ('Diego Luna', 'diego.luna@example.com', 'México', 500.00, true)\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:58:18.699763510 MST","postgres","db_test","2243499","[local]","6a678e16.223bab","SELECT","0/3","0","00000","OBJECT","2","1","READ","SELECT","TABLE","public.clientes_demo","\"SELECT cliente_id, nombre, email, saldo, activo \nFROM public.clientes_demo \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:58:21.627828066 MST","postgres","db_test","2243499","[local]","6a678e16.223bab","UPDATE","0/4","0","00000","OBJECT","3","1","WRITE","UPDATE","TABLE","public.clientes_demo","\"UPDATE public.clientes_demo \nSET saldo = 750.50, \n    activo = false \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,
"2026-07-27 09:58:24.680708170 MST","postgres","db_test","2243499","[local]","6a678e16.223bab","DELETE","0/5","0","00000","OBJECT","4","1","WRITE","DELETE","TABLE","public.clientes_demo","\"DELETE FROM public.clientes_demo \nWHERE email = 'diego.luna@example.com'\",<not logged>",,,,,,,,,"psql",,,,,,,
