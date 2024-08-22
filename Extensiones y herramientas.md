
```SQL

### **5. Seguridad:**  
 
************ SEGURIDAD EN INICIO DE SESIONES ************
- ** pg_auth_mon** Monitorea y registra eventos de autenticación, como intentos de inicio de sesión exitosos y fallidos.
- ** session_exec** Te permite ejecutar una funcion cuando se este iniciando una sesion, utilizado para monitorear y bloquear aplicaciones 

************ SEGURIDAD EN AUTENTICACIÓN ************
- ** ldap_fdw:** Permite la integración con LDAP para autenticar usuarios directamente contra un servidor LDAP, centralizando la gestión de credenciales y permisos.

- ** pg_sasl** Proporciona soporte para autenticación SASL (Simple Authentication and Security Layer) en PostgreSQL.
   **Uso:** Integra PostgreSQL con mecanismos de autenticación SASL para una mayor seguridad en el proceso de autenticación.

- ** pg_pam** Permite la autenticación a través de PAM (Pluggable Authentication Modules) en PostgreSQL.
   **Uso:** Configura `pg_pam` para autenticar usuarios mediante PAM, integrándose con sistemas de autenticación externos. 

- ** pam_auth:** Permite la autenticación de usuarios de PostgreSQL a través de PAM (Pluggable Authentication Modules), integrando la autenticación con los mecanismos de seguridad del sistema operativo.

************ SEGURIDAD EN CONTRASEÑAS ************
- ** pg_password** Gestiona y valida contraseñas de usuario en PostgreSQL, con soporte para políticas de seguridad.
   **Uso:** Implementa validaciones de contraseñas y gestiona la seguridad de contraseñas de usuario.

- ** pg_password_policy** Implementa políticas de contraseñas, como expiración y complejidad, en PostgreSQL.
   **Uso:** Configura políticas para gestionar la expiración de contraseñas y asegurarte de que cumplan con los estándares de seguridad.

- ** check_password** Implementa políticas de seguridad para validar contraseñas, asegurando que cumplan con los requisitos establecidos.
   **Uso:** Configura políticas de contraseñas como longitud mínima y complejidad para mejorar la seguridad de las contraseñas de usuario.


************ SEGURIDAD EN PRIVILEGIOS ************
- ** pg_authz** Proporciona una interfaz para la gestión de permisos y roles, facilitando la administración de acceso y seguridad.
   **Uso:** Permite administrar permisos y roles de usuario de manera más granular.

- ** pg_roleaudit** Audita y reporta sobre cambios en los roles y permisos de los usuarios en PostgreSQL.
   **Uso:** Utiliza `pg_roleaudit` para rastrear y auditar cambios en roles y permisos de usuario.


************ SEGURIDAD EN LA CAPA DE TRANSPORTE ************
- ** sslutils:** Facilita la gestión de certificados SSL/TLS en PostgreSQL, mejorando la seguridad de las conexiones cifradas entre clientes y el servidor.

************ SEGURIDAD EN DATOS SENSIBLES ************
- ** pgcrypto** Proporciona funciones criptográficas para cifrado, descifrado y hashing de datos, incluyendo contraseñas.
   **Uso:** Puedes usar `pgcrypto` para encriptar contraseñas y datos sensibles antes de almacenarlos.

- ** row_security:** Aunque no es una extensión, sino una característica incorporada en PostgreSQL, permite definir políticas de seguridad a nivel de fila, controlando el acceso a los datos basado en atributos del usuario.

************ SEGURIDAD EN AUDITORIAS  ************
- ** pgaudit** Ofrece un sistema de auditoría detallada para registrar eventos de autenticación y otras actividades en la base de datos.
   **Uso:** Configura `pgaudit` para registrar y auditar intentos de inicio de sesión y otras acciones de usuario.


************ SEGURIDAD EN S.O ************
- ** sepgsql:** Integra PostgreSQL con SELinux para aplicar políticas de seguridad a nivel de sistema operativo. Esto añade una capa adicional de control de acceso basada en roles de seguridad de SELinux.







### **1. Monitoreo y Métricas:**


************ MONITOREO DE LOGS ************
- **pgBadger:** Una herramienta externa que analiza los logs de PostgreSQL para generar informes detallados de rendimiento. Es especialmente útil para entender cómo las consultas y la actividad del sistema afectan el rendimiento a lo largo del tiempo.


************ MONITOREO EN CONSULTAS ************
- **pg_stat_statements:** Rastrea y acumula estadísticas sobre el rendimiento de las consultas SQL. Permite identificar consultas lentas o que consumen muchos recursos.
- **pg_stat_monitor:** Extensión avanzada para monitoreo de consultas.
-  **powa (PostgreSQL Workload Analyzer):**  Un sistema de monitoreo que proporciona análisis detallados y gráficos sobre el rendimiento de las consultas, el uso de índices, y otras métricas clave, ayudando a los administradores a identificar y resolver problemas de rendimiento.

************ MONITOREO EN INICIO DE SESION ************
- **pgBouncer:** Pool de conexiones ligero para optimizar el manejo de conexiones.

************ MONITOREO DE ESPACIO ************
- **pgstattuple:** Proporciona estadísticas detalladas sobre la ocupación de espacio en las tablas e índices, incluyendo tuplas muertas y espacio desperdiciado.


- **pg_stat_kcache:**  Extiende el monitoreo para incluir estadísticas del sistema operativo, como lecturas y escrituras de disco a nivel de bloque, ayudando a correlacionar el rendimiento de la base de datos con el uso de recursos a nivel del sistema.
 

- **pg_stat_user_tables:** Ofrece estadísticas sobre el uso de tablas por usuario, incluyendo conteo de accesos, cantidad de inserts, updates, deletes, y bloqueos. Es útil para entender el impacto de cada usuario en la base de datos.

- **pg_stat_activity:** Muestra la actividad actual en la base de datos, incluyendo las consultas que se están ejecutando, el tiempo que llevan ejecutándose, y el estado de las conexiones.

- **pg_stat_bgwriter:** Monitorea las actividades del background writer, un proceso de PostgreSQL que ayuda a escribir datos modificados en disco, lo que es esencial para mantener un rendimiento óptimo.

- **pg_stat_replication:** Proporciona información sobre el estado de la replicación, incluyendo detalles sobre los servidores en standby, el atraso de replicación, y la latencia. Es clave para garantizar la integridad y sincronización de los datos en entornos replicados.

- **pgmetrics:** Herramienta de línea de comandos que recopila una amplia gama de métricas sobre el estado de PostgreSQL, incluyendo información sobre el sistema operativo, conexiones, caché, I/O, entre otros. 

- **pg_top:** Similar al comando `top` de Linux, `pg_top` muestra el uso de recursos de PostgreSQL en tiempo real, permitiendo a los administradores identificar procesos que consumen muchos recursos.

- **pganalyze:** Una herramienta externa que proporciona monitoreo avanzado, análisis de rendimiento y recomendaciones de optimización, basada en las estadísticas y configuraciones de tu instancia de PostgreSQL.



### **2. Replicación y Alta Disponibilidad:**

************ MANTENIMIENTOS ************
- **pg_repack:** Reorganiza tablas e índices sin bloquear operaciones.

************ BACKUP ************
- **barman:** Herramienta de gestión de backups y recuperación para PostgreSQL Soporta la replicación en caliente y la recuperación ante desastres, ofreciendo una solución completa para la protección de datos.

- **pgBackRest:** Herramienta de backup y restauración que ofrece soporte para backups incrementales y diferenciales, así como recuperación punto en el tiempoCompatible con entornos de replicación para asegurar la coherencia de los datos.

- **wal-g:** Herramienta de backup y recuperación que soporta múltiples métodos de almacenamiento en la nube Ofrece soporte para backups completos y diferenciales, y está diseñada para trabajar en entornos con replicación.


************ REPLICA ************
- **repmgr:** Una herramienta para la gestión de replicación y failover en PostgreSQL Facilita la configuración de replicación, supervisa los servidores y realiza failover automático en caso de fallo del maestro.

- **pglogical:** Proporciona replicación lógica para PostgreSQL, permitiendo replicar cambios entre diferentes bases de datos y transformarlos en el proceso.
 
************ BALANCEO DE CARGA EN REPLICAS ************
- **pgpool-II:** Middleware que proporciona balanceo de carga y failover automático para PostgreSQL Permite la replicación en modo maestro-esclavo y distribuye las consultas entre las réplicas para mejorar el rendimiento.

************ TRANSFORMACION DE WAL EN JSON ************
- **wal2json:** Genera datos en formato JSON a partir de los registros de WAL (Write-Ahead Logging), útil para replicación lógica y para aplicaciones que necesitan consumir los cambios en un formato legible.
 

 
### **7. Rendimiento y Optimización:**  

- **  pg_cron:** Planifica y ejecuta tareas dentro de PostgreSQL, como vacuums o análisis, en horarios programados, lo que ayuda a mantener el rendimiento de la base de datos de forma automática y sin intervención manual.

- ** pg_partman:** Gestiona la partición de tablas de forma automática, lo cual es fundamental para mejorar el rendimiento en bases de datos con grandes volúmenes de datos, especialmente en tablas de series temporales.


- **pg_timetable:** Herramienta para la planificación y ejecución de tareas cron en la base de datos.

- ** pg_prewarm:** Pre-carga tablas o índices en la memoria compartida de PostgreSQL al inicio del servidor, mejorando el rendimiento de las consultas que acceden frecuentemente a estos datos.

- ** pg_repack:** Reorganiza y compacta tablas e índices sin bloquear las escrituras, lo que ayuda a reducir el bloat y mejorar el rendimiento sin afectar la disponibilidad del sistema.

- ** pg_hint_plan:** Permite a los administradores influir directamente en el planificador de consultas sugiriendo (hinting) cómo ejecutar consultas SQL, lo cual es útil para optimizar casos específicos donde el planificador no elige el mejor plan por defecto.

- ** auto_explain:** Genera automáticamente los planes de ejecución de las consultas que exceden un umbral de tiempo de ejecución, lo que facilita la identificación de consultas mal optimizadas.

- ** hypopg:** Permite simular la creación de índices sin necesidad de materializarlos físicamente, ayudando a evaluar el impacto de nuevos índices en el rendimiento antes de su creación.

- ** plpgsql_check:** Extiende el lenguaje PL/pgSQL con herramientas de validación y optimización, detectando posibles problemas de rendimiento en funciones y procedimientos almacenados.

- ** pg_squeeze:** Automatiza la compactación de tablas y sus índices para eliminar bloat sin necesidad de bloquear las tablas, mejorando el rendimiento en entornos de alta concurrencia.

- ** pgfincore:** Permite analizar qué partes de las tablas y los índices están en caché en la memoria del sistema operativo, ayudando a optimizar el uso de la caché.

- ** pl/profiler:** Proporciona un perfilador para PL/pgSQL, permitiendo medir el tiempo de ejecución de cada línea de código en las funciones almacenadas, lo cual es útil para identificar y optimizar cuellos de botella.

- ** pg_bulkload:** Optimiza la carga masiva de datos en PostgreSQL, permitiendo insertar grandes volúmenes de datos de manera eficiente, minimizando el impacto en el 
rendimiento general de la base de datos.

- ** timescaledb:** Una extensión optimizada para manejar series temporales de manera eficiente, mejorando el rendimiento en consultas que involucran grandes volúmenes de datos temporales.




### **3. Índices y Búsqueda:**

- **pg_trgm:** Búsqueda de similitudes de texto mediante índices GIN/GIST.
- **btree_gin:** Extiende índices GIN para tipos de datos adicionales.
- **tsvector:** Permite búsqueda de texto completo.
- **rum:** Extensión para índices GIN avanzados, optimizados para búsquedas complejas.
- **GIN:** Optimiza la búsqueda en datos complejos, como arrays o textos largos.
- **pg_qualstats:** Permite recopilar estadísticas sobre las cláusulas WHERE utilizadas en las consultas, ayudando a identificar posibles mejoras en los índices.
- **amcheck:** Herramienta para verificar la integridad de los índices B-tree, útil para detectar y corregir corrupción de datos.
- **pg_visibility:** Permite investigar la visibilidad de las tuplas en las tablas y detectar problemas con vacuum.



### **4. Datos Geoespaciales:**
- **PostGIS:** Soporte completo para datos geoespaciales.
- **pgRouting:** Algoritmos de enrutamiento para datos espaciales.
- **address_standardizer:** Normaliza y estandariza direcciones postales, generalmente utilizada junto con PostGIS.



### **6. Datos y Transformación:**
- **hstore:** Almacena pares clave-valor en una sola columna.
- **uuid-ossp:** Generación de UUIDs únicos.
- **citext:** Comparación de texto sin distinción entre mayúsculas y minúsculas.
- **pg_bulkload:** Herramienta para cargas masivas de datos de manera eficiente.
- **tablefunc:** Proporciona funciones como crosstab para pivotar tablas.
- **pg_similarity:** Ofrece funciones de comparación de cadenas utilizando diferentes métricas de similitud, útiles para la limpieza de datos.
- **intarray:** Proporciona funciones adicionales para manipular y buscar en arrays de enteros, mejorando la eficiencia en consultas que involucren estos tipos de datos.


### **8. Análisis y Ciencia de Datos:**
- **MADlib:** Biblioteca de algoritmos de aprendizaje automático.
- **cstore_fdw:** Soporte para almacenamiento en formato columna.
- **timescaledb:** Extensión para manejo eficiente de series temporales.
- **PL/R:** Permite ejecutar código R dentro de PostgreSQL para análisis estadístico.
- **PL/Python:** Extensión para ejecutar funciones en Python dentro de PostgreSQL.
- **cube:** Introduce un tipo de datos multidimensional que facilita el manejo y análisis de datos en múltiples dimensiones.


### **9. Otros:**
- **dblink:** Ejecuta consultas en bases de datos remotas desde PostgreSQL.
-**tds_fdw ** Conecta y consulta otras bases SQL server de manera remota.
- **postgres_fdw:** Conecta y consulta otras bases PostgreSQL de manera remota.
- **plv8:** Extensión que permite escribir funciones en JavaScript.



```




## Blibliografía
```SQL
https://www.timescale.com/blog/top-8-postgresql-extensions/

--- Extensiones
https://postgres.ai/docs/database-lab/supported-databases
https://github.com/dhamaniasad/awesome-postgres

https://www.postgresql.org/download/products/6-postgresql-extensions/
https://www.timescale.com/blog/top-8-postgresql-extensions/

--- Forma de hacer un trigger para login
https://www.dbi-services.com/blog/postgresql-17-login-event-triggers/



https://github.com/okbob/session_exec
```
