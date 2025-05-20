
## Buscar extensiones centralizadas de postgres 
```
https://pgxn.org/
```

### Buscar extensiones disponibles para instalar en el servidor 
```SQL
dnf search pg_cron
 ```

### Validar extensiones que puedo instalar 
```SQL
select * from pg_available_extensions where name ilike '%fdw%'; 
 ```
### Ver extensiones instaladas 
```SQL
select * from pg_extension;
```

```SQL
# Graficas :
Power By
Grafana 


### Herramientas de Seguridad para PostgreSQL



2. Protección Contra Ataques

	Fail2Ban: Bloquea IPs tras varios intentos fallidos.
	



	Crowdsec: Plataforma colaborativa contra ataques de fuerza bruta.


3. Hardening y Gestión de Conexiones

	PgBouncer: Proxy ligero para limitar conexiones y prevenir abusos.
	OPM: Monitoreo especializado para PostgreSQL con alertas avanzadas.


4. Cifrado y Protección de Datos

	Vault: Gestión dinámica de secretos y claves de cifrado.
	Let's Encrypt: Certificados SSL/TLS gratuitos para asegurar conexiones.


5. Análisis de Logs y Vulnerabilidades

	ELK Stack: Visualización y análisis avanzado de logs.
	OSSEC: Detección de intrusiones y monitoreo de cambios no autorizados.


### **5. Ejecucion de tareas programadas :**
- **  pgAgent:** Ejecucion de tareas programadas , Propia de postgresq, y puedes administrarla desde pgAdmin
- **  pg_cron:** Ejecucion de tareas programadas , Planifica y ejecuta tareas dentro de PostgreSQL, como vacuums o análisis, en horarios programados, lo que ayuda a mantener el rendimiento de la base de datos de forma automática y sin intervención manual.



**adminpack :**
proporciona una serie de funciones de soporte que herramientas de administración y gestión, como pgAdmin, pueden utilizar para ofrecer funcionalidades adicionales1
. Algunas de las funcionalidades incluyen la gestión remota de archivos de registro del servidor,  Debes usarlo cuando necesitas acceso remoto a ciertos archivos del sistema operativo desde tu base de datos, sin necesidad de acceso SSH

Gestión de Archivos de Registro:
	pg_file_write: Escribir contenido en un archivo.
	pg_file_rename: Renombrar archivos.
	pg_file_unlink: Eliminar archivos.
 


Prometheus es una herramienta de monitoreo y alerta de código abierto que se utiliza ampliamente para recopilar y analizar métricas de sistemas y aplicaciones. Para monitorear PostgreSQL con Prometheus, se utiliza un componente llamado Postgres Exporter.

2. **PostgreSQL TDE (Transparent Data Encryption)**:
   - **Descripción**: TDE proporciona cifrado de datos en reposo para PostgreSQL, asegurando que los datos almacenados en disco estén protegidos.
   - **Características**: Cifrado de tablas y columnas, gestión de claves de cifrado, integración con módulos de seguridad de hardware (HSM).

3. **pgauditlog**:
   - **Descripción**: Herramienta de auditoría que permite registrar y analizar eventos de seguridad en PostgreSQL.
   - **Características**: Registro de eventos de seguridad, análisis de logs, generación de informes de auditoría.

 
5. **Data Masking**:
   - **Descripción**: Herramienta que permite enmascarar datos sensibles en PostgreSQL para proteger la privacidad y cumplir con regulaciones de protección de datos.
   - **Características**: Enmascaramiento dinámico y estático, soporte para múltiples tipos de datos, configuración flexible.

6. **PostgreSQL Security Extensions**:
   - **Descripción**: Conjunto de extensiones que mejoran la seguridad de PostgreSQL, incluyendo autenticación avanzada y control de acceso.
   - **Características**: Autenticación basada en certificados, control de acceso granular, integración con sistemas de gestión de identidades.
 

### **5. Seguridad:**

- ** pg_track_settings** Esta extensión permite rastrear cambios en configuraciones y podría adaptarse para monitorear roles y permisos.

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

************ SEGURIDAD EN CONTRASEÑAS, aplica politicas  ************
credcheck       https://github.com/MigOpsRepos/credcheck/tree/master

passwordpolicy  https://github.com/eendroroy/passwordpolicy/tree/master

- ** passwordcheck ** password basica



************ SEGURIDAD EN PRIVILEGIOS ************
- ** pg_authz** Proporciona una interfaz para la gestión de permisos y roles, facilitando la administración de acceso y seguridad.
   **Uso:** Permite administrar permisos y roles de usuario de manera más granular.
 
 **pg_permissions**: Proporciona vistas para revisar los permisos de objetos en una base de datos PostgreSQL, facilitando la gestión y auditoría de permisos³³.
 

************ SEGURIDAD EN LA CAPA DE TRANSPORTE ************
- ** sslutils:** Facilita la gestión de certificados SSL/TLS en PostgreSQL, mejorando la seguridad de las conexiones cifradas entre clientes y el servidor.

************ SEGURIDAD EN DATOS SENSIBLES ************
- ** pgcrypto** Proporciona funciones criptográficas para cifrado, descifrado y hashing de datos, incluyendo contraseñas.
   **Uso:** Puedes usar `pgcrypto` para encriptar contraseñas y datos sensibles antes de almacenarlos.

- **Pgsodium** es como pgcrypto
- ** row_security:** Aunque no es una extensión, sino una característica incorporada en PostgreSQL, permite definir políticas de seguridad a nivel de fila, controlando el acceso a los datos basado en atributos del usuario.

************ SEGURIDAD EN AUDITORIAS  ************
- ** pgaudit** Ofrece un sistema de auditoría detallada para registrar eventos de autenticación y otras actividades en la base de datos.
   **Uso:** Configura `pgaudit` para registrar y auditar intentos de inicio de sesión y otras acciones de usuario.


************ SEGURIDAD EN S.O ************
- ** sepgsql:** Integra PostgreSQL con SELinux para aplicar políticas de seguridad a nivel de sistema operativo. Esto añade una capa adicional de control de acceso basada en roles de seguridad de SELinux.
SE-PostgreSQL: Implementa políticas de seguridad obligatoria (MAC) basadas en SELinux






### **1. Monitoreo y Métricas:**


************ MONITOREO DE LOGS ************

pg_proctab ---> https://github.com/markwkm/pg_proctab/tree/main

temboard  -> es una herramienta de código abierto y gratuita para monitorear, Alertas y notificaciones y administrar instancias de PostgreSQL  https://github.com/dalibo/temboard/?tab=readme-ov-file

pgAudit: Registra operaciones sensibles como DDL y DML.
pganalyze-> Monitoreo de Rendimiento: ,Análisis de Consultas ,Asesor de Índices: ,Asesor de VACUUM ,Alertas y Notificaciones ,Visualización de Datos 
pgDash -> es una solución de monitoreo integral diseñada específicamente para despliegues de PostgreSQL. (Monitoreo en Profundidad,Informes y Visualización ,Alertas ,Monitoreo de Replicación ,Integraciones)
pgBadger -> es una herramienta de análisis de logs para PostgreSQL que genera informes detallados y gráficos a partir de los archivos de log de PostgreSQL
Prometheus ->  Prometheus es una herramienta de monitoreo de código abierto que se centra en la recopilación y el análisis de datos basados en series de tiempo.
Zabbix -> es una herramienta de monitoreo de código abierto que ofrece una amplia gama de características, incluyendo la supervisión de bases de datos PostgreSQL.
Nagios -> Con plugins específicos para PostgreSQL, Nagios puede monitorear el rendimiento y la seguridad de tu base de datos
Grafana -> Aunque se utiliza principalmente para la visualización de datos, Grafana se puede integrar con Prometheus y otras herramientas para proporcionar un monitoreo completo de PostgreSQL
Checkmk ->  herramienta de monitoreo de código abierto que ofrece monitoreo integral para bases de datos PostgreSQ

SIEM  detección de amenazas
Wazuh es una plataforma de seguridad de código abierto que ofrece una amplia gama de funcionalidades para la detección de amenazas, el monitoreo de integridad y la respuesta a incidente

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




 

************ MANTENIMIENTOS ************
- **pg_repack:** Reorganiza tablas e índices sin bloquear operaciones.

- ** pg_squeeze:** Automatiza la compactación de tablas y sus índices para eliminar bloat sin necesidad de bloquear las tablas, mejorando el rendimiento en entornos de alta concurrencia.

- ** pg_ivm :**  permite actualizar vistas materializadas de manera incremental, lo que significa que solo se actualizan las partes que han cambiado

************ BACKUP ************
- **pg_dirtyread** Recuperar datos eliminados: Puedes acceder a las tuplas que han sido marcadas como eliminadas pero aún no han sido físicamente removidas. Auditoría y análisis: Permite realizar auditorías y análisis forenses de datos  https://github.com/df7cb/pg_dirtyread 

- **barman:** Herramienta de gestión de backups y recuperación para PostgreSQL Soporta la replicación en caliente y la recuperación ante desastres, ofreciendo una solución completa para la protección de datos.

- **pgBackRest:** Herramienta de backup y restauración que ofrece soporte para backups incrementales y diferenciales, así como recuperación punto en el tiempoCompatible con entornos de replicación para asegurar la coherencia de los datos.

- **wal-g:** Herramienta de backup y recuperación que soporta múltiples métodos de almacenamiento en la nube Ofrece soporte para backups completos y diferenciales, y está diseñada para trabajar en entornos con replicación.

### **2. Replicación y Alta Disponibilidad:**

- **wal2json:** Genera datos en formato JSON a partir de los registros de WAL (Write-Ahead Logging), útil para replicación lógica y para aplicaciones que necesitan consumir los cambios en un formato legible.  https://github.com/eulerto/wal2json


PGProfiler: es una extensión para PostgreSQL que ayuda a identificar las actividades más intensivas en recursos dentro de tus bases de datos rea un repositorio histórico en tu base de datos que almacena "muestras" de estadísticas, permitiéndote analizar el rendimiento y los problemas de carga en períodos específicos2. Es útil para monitorear y resolver problemas de rendimiento.

 **pg_rewind** es una herramienta de PostgreSQL que se usa para **sincronizar un directorio de datos con otro que se haya bifurcado de él**. Su propósito principal es ayudar en escenarios de recuperación tras fallos, especialmente cuando un servidor primario ha sido reemplazado por otro y se necesita volver a poner en línea el antiguo primario como un servidor de respaldo.

### **¿Cómo funciona?**
- **Detecta el punto de divergencia** entre dos servidores PostgreSQL.
- **Copia solo los bloques modificados**, en lugar de hacer una copia completa de la base de datos.
- **Restaura el estado del servidor antiguo** para que pueda seguir al nuevo primario sin necesidad de una nueva copia de seguridad completa.

### **Casos de uso**
- **Recuperación tras un failover**: Si un servidor primario falla y otro toma su lugar, `pg_rewind` permite que el antiguo primario vuelva a ser un servidor de respaldo sin necesidad de una reinstalación completa.
- **Optimización de la replicación**: Evita la necesidad de hacer una copia de seguridad completa cuando los cambios entre servidores son mínimos.
- **Reducción del tiempo de recuperación**: Es mucho más rápido que volver a clonar una base de datos desde cero.
 

************ REPLICA Failover Automático  ************
- **repmgr:** Una herramienta para la gestión de replicación y failover en PostgreSQL Facilita la configuración de replicación, supervisa los servidores y realiza failover automático en caso de fallo del maestro.

Patroni: es una herramienta que facilita la implementación de soluciones de alta disponibilidad (HA)  soporta varios almacenes de configuración distribuidos como ZooKeeper, etcd, Consul o Kubernetes permite configurar y gestionar clusters de PostgreSQL con replicación y failover automáticos, asegurando que tu base de datos esté siempre disponible incluso en caso de fallos

- **pglogical:** Proporciona replicación lógica para PostgreSQL, permitiendo replicar cambios entre diferentes bases de datos y transformarlos en el proceso.

Stolon: Un orquestador de PostgreSQL HA basado en Kubernetes, aunque también puede funcionar fuera de él. Utiliza etcd para el almacenamiento distribuido y la elección de líder.

 **pg_auto_failover**: Esta extensión y servicio para PostgreSQL gestiona la conmutación por error automatizada para un clúster de PostgreSQL, asegurando alta disponibilidad y consistencia de datos¹.
 
 **pg_failover_slots**: Hace que las ranuras de replicación lógica sean utilizables en una conmutación por error física, sincronizando las ranuras de replicación entre el nodo primario y el de respaldo¹¹.
 

************ BALANCEO DE CARGA EN REPLICAS ************
- **pgpool-II:** Middleware que proporciona balanceo de carga y failover automático para PostgreSQL Permite la replicación en modo maestro-esclavo y distribuye las consultas entre las réplicas para mejorar el rendimiento.
Slony-I: Un sistema de replicación maestro-esclavo para PostgreSQL que permite replicar datos entre múltiples servidores.

HAProxy --> es un balanceador de carga y proxy inverso de código abierto. Se utiliza para distribuir el tráfico de red entre múltiples servidores, mejorando la disponibilidad y el rendimiento de los servicios web

************  sistema distribuido ************ 
Citus es una extensión de código abierto para **PostgreSQL** que convierte la base de datos en un sistema distribuido, permitiendo escalar horizontalmente y mejorar el rendimiento en cargas de trabajo intensivas. Algunas de sus principales funciones incluyen:

- **Sharding automático**: Distribuye datos en múltiples nodos para mejorar la escalabilidad.
- **Consultas paralelas**: Ejecuta consultas en varios servidores simultáneamente, acelerando el procesamiento.
- **Soporte para multi-tenancy**: Ideal para aplicaciones SaaS con múltiples clientes.
- **Almacenamiento columnar**: Optimiza el rendimiento en análisis de datos y consultas agregadas.

 



 
### **7. Rendimiento y Optimización:**

pageinspect  -> es una extensión de PostgreSQL que permite examinar el contenido de las páginas de la base de datos a bajo nivel. Mostrar información detallada sobre tuplas (filas) individuales

 pgbench : herramienta de benchmarking para probar el rendimiento de PostgreSQL. Ejecuta una serie de comandos SQL repetidamente en múltiples sesiones concurrentes y calcula la tasa promedio de transacciones (transacciones por segundo).
 pgingester : herramienta de benchmarking para evaluar diferentes métodos de ingestión de datos en lotes en PostgreSQL2. Mide el rendimiento de métodos como INSERT, COPY, Binary COPY, y UNNEST en términos de filas por segundo y duración de la ingestión.
- ** pg_partman:** Gestiona la partición de tablas de forma automática, lo cual es fundamental para mejorar el rendimiento en bases de datos con grandes volúmenes de datos, especialmente en tablas de series temporales.


- **pg_timetable:** Herramienta para la planificación y ejecución de tareas cron en la base de datos.

- ** pg_prewarm:** Pre-carga tablas o índices en la memoria compartida de PostgreSQL al inicio del servidor, mejorando el rendimiento de las consultas que acceden frecuentemente a estos datos.
 
- ** pg_hint_plan:** Permite a los administradores influir directamente en el planificador de consultas sugiriendo (hinting) cómo ejecutar consultas SQL, lo cual es útil para optimizar casos específicos donde el planificador no elige el mejor plan por defecto.

- ** auto_explain:** Genera automáticamente los planes de ejecución de las consultas que exceden un umbral de tiempo de ejecución, lo que facilita la identificación de consultas mal optimizadas.

- ** hypopg:** Permite simular la creación de índices sin necesidad de materializarlos físicamente, ayudando a evaluar el impacto de nuevos índices en el rendimiento antes de su creación.

- ** plpgsql_check:** Extiende el lenguaje PL/pgSQL con herramientas de validación y optimización, detectando posibles problemas de rendimiento en funciones y procedimientos almacenados.

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


### **8. análisis de datos  y Ciencia de Datos:**
ParadeDB es una extensión para PostgreSQL que mejora las capacidades analíticas de la base de datos, permitiendo consultas más eficientes sobre grandes volúmenes de datos.
pg_analytics es una extensión que integra DuckDB dentro de PostgreSQL, permitiendo que Postgres pueda consultar almacenes de datos externos como AWS S3 y formatos de tabla como Iceberg o Delta Lake
- **MADlib:** Biblioteca de algoritmos de aprendizaje automático.
- **cstore_fdw:** Soporte para almacenamiento en formato columna.
- **PL/R:** Permite ejecutar código R dentro de PostgreSQL para análisis estadístico.
- **PL/Python:** Extensión para ejecutar funciones en Python dentro de PostgreSQL.
- **cube:** Introduce un tipo de datos multidimensional que facilita el manejo y análisis de datos en múltiples dimensiones.


### Extensiones y Herramientas
- **pg_prewarm**: Esta extensión permite precargar tablas o índices en el buffer cache, lo que puede mejorar el rendimiento al reducir la necesidad de lecturas desde el disco³(https://www.youtube.com/watch?v=prbF4O0d-7M).
- **pg_buffercache**: Permite monitorear el uso del buffer cache para entender mejor cómo se está utilizando la memoria y ajustar configuraciones en consecuencia³(https://www.youtube.com/watch?v=prbF4O0d-7M).


### **9. Otros:**
- **dblink:** Ejecuta consultas en bases de datos remotas desde PostgreSQL.
-**tds_fdw ** Conecta y consulta otras bases SQL server de manera remota.
- **postgres_fdw:** Conecta y consulta otras bases PostgreSQL de manera remota.
- **plv8:** Extensión que permite escribir funciones en JavaScript.




 **pg_background**: Permite ejecutar comandos SQL en segundo plano, lo que es útil para tareas como `VACUUM` o `CREATE INDEX CONCURRENTLY` desde un lenguaje procedimental⁷.
 
 **pg_bigm**: Proporciona capacidad de búsqueda de texto completo mediante la creación de índices bigram (2-gram), lo que acelera las búsquedas de texto completo en PostgreSQL¹⁶.
 
 
 **pg_comparator**: Compara bases de datos de servicios de prueba y producción en PostgreSQL, generando SQL para corregir diferencias⁵.
 
 
 **pg_filedump**: Utilidad para formatear archivos de heap, índice o control de PostgreSQL en una forma legible para humanos, útil para la inspección de bajo nivel de tablas e índices²³.
 

 **pg_readonly**: Permite establecer todas las bases de datos de un clúster en modo solo lectura, útil para situaciones donde se requiere asegurar que no se realicen modificaciones[^20^].
 
 
 . **pg_wait_sampling**:
   - **Descripción**: Esta extensión recopila Eventos estadísticas basadas en muestreo de eventos de espera en PostgreSQL. Permite obtener un historial de eventos de espera y un perfil de espera acumulado para todos los procesos, incluyendo los trabajadores en segundo plano⁵⁶.
   - **Uso**: Es útil para diagnosticar problemas de rendimiento y analizar qué procesos están esperando y por cuánto tiempo. Para habilitarla, debes agregar `pg_wait_sampling` a la variable `shared_preload_libraries` en el archivo `postgresql.conf` y reiniciar el servidor⁵.
 
 ### Tipos de Eventos Capturados
 

- **LWLock**: Bloqueos ligeros utilizados internamente por PostgreSQL.
- **Lock**: Bloqueos de nivel SQL, como bloqueos de filas o tablas.
- **BufferPin**: Esperas relacionadas con la fijación de buffers en memoria.
- **Activity**: Esperas relacionadas con la actividad del proceso, como `ClientRead`, `ClientWrite`, etc.
- **IPC**: Esperas de comunicación entre procesos.
- **Timeout**: Esperas relacionadas con tiempos de espera configurados.
 





CREATE EXTENSION cstore_fdw; --> permite almacenar datos en formato columnar en lugar del formato tradicional de filas.
CREATE SERVER cstore_server FOREIGN DATA WRAPPER cstore_fdw;
CREATE FOREIGN TABLE nombre_tabla (
    columna1 tipo,
    columna2 tipo
) SERVER cstore_server OPTIONS (compression 'pglz');

shared_preload_libraries = 'cstore_fdw'
https://github.com/citusdata/cstore_fdw


```




## Blibliografía
```SQL

Software Catalogue - Product Categories  https://www.postgresql.org/download/product-categories/
---- https://www.postgresql.org/ftp/projects/ 

https://www.timescale.com/blog/top-8-postgresql-extensions/

--- Extensiones
https://postgres.ai/docs/database-lab/supported-databases
https://github.com/dhamaniasad/awesome-postgres


https://www.timescale.com/blog/top-8-postgresql-extensions/

--- Forma de hacer un trigger para login
https://www.dbi-services.com/blog/postgresql-17-login-event-triggers/

https://github.com/okbob/session_exec


La extensión pgrowlocks en PostgreSQL se utiliza para mostrar información sobre los bloqueos de filas en una tabla específica. Aquí tienes un resumen de su funcionalidad: --> SELECT * FROM pgrowlocks('mi_tabla');
s
La extensión pg_freespacemap en PostgreSQL se utiliza para examinar el mapa de espacio libre (FSM) de una relación (tabla o índice). Aquí tienes un resumen de su funcionalidad: --> SELECT * FROM pg_freespace('mi_tabla');



pg_datamask  --- Enmascaramiento en postgresql  https://www.cybertec-postgresql.com/en/products/data-masking-for-postgresql/
PostgreSQL Anonymizer --- postgresql_anonymizer_16.x86_64  Enmascaramiento en postgresql   https://postgresql-anonymizer.readthedocs.io/en/stable/ 
 
---- crear extensiones: https://postgresconf.org/system/events/document/000/001/158/pg-extensions.pdf 


Extension List https://autobase.tech/docs/extensions/list

https://www.postgresql.org/ftp/projects/

-- Mas de 1000 extensiones para postgresql
https://gist.github.com/joelonsql/e5aa27f8cc9bd22b8999b7de8aee9d47

```
