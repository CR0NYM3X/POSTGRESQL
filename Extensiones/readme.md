
## Buscar extensiones centralizadas de postgres 
```
https://pgxn.org/
https://ext.pigsty.io/list/cate/#sec
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


### Herramientas de Operador o Administracion automatica kubernetes, desplegar proyectos grandes con pocas configuraciones ####
stackgres  -> https://github.com/ongres/stackgres - https://stackgres.io/blog/stackgres-1-0-0-open-source-postgres-aas-with-120-extensions/
Zalado postgres-operator : https://github.com/zalando/postgres-operator
CloudNativePG : es un "Operador" de código abierto diseñado específicamente para PostgreSQL. Un operador es un software que extiende la funcionalidad de Kubernetes para que sepa cómo manejar aplicaciones complejas que tienen "estado" (como una base de datos). Su propósito principal es que no tengas que configurar manualmente la alta disponibilidad, los respaldos o las actualizaciones de Postgres. Tú solo le dices "quiero un clúster de 3 nodos" en un archivo de configuración, y el operador hace todo el trabajo sucio.
pgsty/pigsty ->  cumple funciones similares de automatización, Está diseñado para instalarse directamente sobre el sistema operativo Linux (Ubuntu, RHEL, Debian). Utiliza Ansible  -> https://github.com/pgsty/pigsty

https://autobase.tech/ ->  Autobase es un "robot administrador" gratuito (Open Source) que instalas en tus propios servidores para gestionar bases de datos PostgreSQL de forma automática.
Sirve para que no tengas que ser un experto en programación de servidores: el software se encarga de que tu base de datos sea rápida, tenga copias de seguridad y nunca se caiga, dándote la misma calidad que los servicios caros de Amazon o Google, pero a una fracción del costo.

### Herramientas de migracion ####
ora2pg
pgLoader
Babelfish for PostgreSQL :es una capa de traducción de código abierto que permite que PostgreSQL entienda y ejecute consultas escritas originalmente para Microsoft SQL Server. https://babelfishpg.org/  



############ Herramientas de Seguridad para PostgreSQL #####################

2. Protección Contra Ataques

	Fail2Ban: Bloquea IPs tras varios intentos fallidos.
	pg_tde :  TDE significa Transparent Data Encryption (Cifrado de Datos Transparente).  Es una extensión diseñada para PostgreSQL que protege los datos "en reposo" (cuando están guardados en el disco duro), asegurando que si alguien roba físicamente los archivos del servidor o los respaldos, no pueda leer la información.



	Crowdsec: Plataforma colaborativa contra ataques de fuerza bruta.


3. Hardening y Gestión de Conexiones

	PgBouncer: Proxy ligero para limitar conexiones y prevenir abusos.
	proxysql -> https://github.com/sysown/proxysql




4. Cifrado y Protección de Datos

	Vault: Gestión dinámica de secretos y claves de cifrado.
	Let's Encrypt: Certificados SSL/TLS gratuitos para asegurar conexiones.


5. Análisis de Logs y Vulnerabilidades

	ELK Stack: Visualización y análisis avanzado de logs.
	OSSEC: Detección de intrusiones y monitoreo de cambios no autorizados.

* **pgextwlist (Extensions Whitelist):** Permite a los administradores definir una **"lista blanca"** de extensiones que los usuarios normales (que no son superusuarios) pueden instalar. Es vital en entornos de nube para mantener la seguridad sin bloquear a los desarrolladores.

6.- Validaciones
- ** plpgsql_check:** Extiende el lenguaje PL/pgSQL con herramientas de validación y optimización, detectando posibles problemas de rendimiento en funciones y procedimientos almacenados.

pgstigcheck-inspec -> https://github.com/CrunchyData/pgstigcheck-inspec ->   herramienta de automatización para auditoría y cumplimiento) diseñado específicamente para verificar si tu base de datos PostgreSQL cumple con la STIG (Security Technical Implementation Guide) de la DISA (Defense Information Systems Agency) de los Estados Unidos.



https://github.com/okbob/session_exec
pg_datamask  --- Enmascaramiento en postgresql  https://www.cybertec-postgresql.com/en/products/data-masking-for-postgresql/
PostgreSQL Anonymizer --- postgresql_anonymizer_16.x86_64  Enmascaramiento en postgresql   https://postgresql-anonymizer.readthedocs.io/en/stable/ 

--------------------------------------------------------------------------------------

### **5. Ejecucion de tareas programadas :**
- **  pgAgent:** Ejecucion de tareas programadas , Propia de postgresq, y puedes administrarla desde pgAdmin
- **  pg_cron:** Ejecucion de tareas programadas , Planifica y ejecuta tareas dentro de PostgreSQL, como vacuums o análisis, en horarios programados, lo que ayuda a mantener el rendimiento de la base de datos de forma automática y sin intervención manual.

- **pg_timetable:** Herramienta para la planificación y ejecución de tareas cron en la base de datos.

 
**adminpack :**
proporciona una serie de funciones de soporte que herramientas de administración y gestión, como pgAdmin, pueden utilizar para ofrecer funcionalidades adicionales1
. Algunas de las funcionalidades incluyen la gestión remota de archivos de registro del servidor,  Debes usarlo cuando necesitas acceso remoto a ciertos archivos del sistema operativo desde tu base de datos, sin necesidad de acceso SSH

Gestión de Archivos de Registro:
	pg_file_write: Escribir contenido en un archivo.
	pg_file_rename: Renombrar archivos.
	pg_file_unlink: Eliminar archivos.
 


Prometheus es una herramienta de monitoreo y alerta de código abierto que se utiliza ampliamente para recopilar y analizar métricas de sistemas y aplicaciones. Para monitorear PostgreSQL con Prometheus, se utiliza un componente llamado Postgres Exporter.


pg_snakeoil - El antivirus PostgreSQL -> https://github.com/df7cb/pg_snakeoil

pgauditlogtofile -> complemento de pgaudit para no contaminar el log de postgresql -> https://github.com/df7cb/pgauditlogtofile
 

2. **PostgreSQL TDE (Transparent Data Encryption)**:
   - **Descripción**: TDE proporciona cifrado de datos en reposo para PostgreSQL, asegurando que los datos almacenados en disco estén protegidos.
   - **Características**: Cifrado de tablas y columnas, gestión de claves de cifrado, integración con módulos de seguridad de hardware (HSM).

3. **pgaudit**:
	https://supabase.com/docs/guides/database/extensions/pgaudit
   - **Descripción**: Herramienta de auditoría que permite registrar y analizar eventos de seguridad en PostgreSQL.
   - **Características**: Registro de eventos de seguridad, análisis de logs, generación de informes de auditoría.

 
5. **Data Masking**:
   - **Descripción**: Herramienta que permite enmascarar datos sensibles en PostgreSQL para proteger la privacidad y cumplir con regulaciones de protección de datos.
   - **Características**: Enmascaramiento dinámico y estático, soporte para múltiples tipos de datos, configuración flexible.

6. **PostgreSQL Security Extensions**:
   - **Descripción**: Conjunto de extensiones que mejoran la seguridad de PostgreSQL, incluyendo autenticación avanzada y control de acceso.
   - **Características**: Autenticación basada en certificados, control de acceso granular, integración con sistemas de gestión de identidades.
 
pg_filedump ->  pg_filedump es para auditoría física: entender por qué un archivo de la base de datos está roto o qué datos quedan en un archivo después de un fallo catastrófico. -> https://github.com/df7cb/pg_filedump
	https://devopsideas.com/postgresql-internals-a-practical-guide-to-pg_filedump/
	https://es.slideshare.net/slideshow/data-recovery-using-pgfiledump/77757640
	La base de datos no arranca: Si el motor está caído y necesitas ver qué hay dentro de los archivos de datos.
	Corrupción de datos: Es la herramienta número uno para investigar "Data Corruption". Permite ver exactamente qué byte está mal en una página de disco.
	Recuperación forense: Permite intentar extraer datos de tablas que han sido dañadas y que herramientas como pg_dump no pueden leer porque el motor de Postgres falla al intentar acceder a ellas.


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

- pgjwt
Un JWT (JSON Web Token) es un formato compacto y seguro para transmitir información entre partes como un objeto JSON firmado digitalmente. Se usa comúnmente para:

Autenticación de usuarios.
Autorización de acceso a recursos.
Comunicación segura entre servicios.

************ SEGURIDAD EN AUDITORIAS  ************
- ** pgaudit** Ofrece un sistema de auditoría detallada para registrar eventos de autenticación y otras actividades en la base de datos.
   **Uso:** Configura `pgaudit` para registrar y auditar intentos de inicio de sesión y otras acciones de usuario.


************ SEGURIDAD EN S.O ************
- ** sepgsql:** Integra PostgreSQL con SELinux para aplicar políticas de seguridad a nivel de sistema operativo. Esto añade una capa adicional de control de acceso basada en roles de seguridad de SELinux.
SE-PostgreSQL: Implementa políticas de seguridad obligatoria (MAC) basadas en SELinux

 




### **1. Monitoreo y Métricas:**


************ MONITOREO DE LOGS ************

pg_proctab ---> consultar información del sistema operativo directamente mediante comandos SQL, sin necesidad de salir de la terminal de Postgres  https://github.com/markwkm/pg_proctab/tree/main
OPM -> https://opm.readthedocs.io/index.html
temboard  -> es una herramienta de código abierto y gratuita para monitorear, Alertas y notificaciones y administrar instancias de PostgreSQL  https://github.com/dalibo/temboard/?tab=readme-ov-file
pgwatch2 -> Monitoreo general 
pgAudit: Registra operaciones sensibles como DDL y DML.
pganalyze-> Monitoreo de Rendimiento: ,Análisis de Consultas ,Asesor de Índices: ,Asesor de VACUUM ,Alertas y Notificaciones ,Visualización de Datos 
pgDash -> es una solución de monitoreo integral diseñada específicamente para despliegues de PostgreSQL. (Monitoreo en Profundidad,Informes y Visualización ,Alertas ,Monitoreo de Replicación ,Integraciones)
pgBadger -> es una herramienta de análisis de logs para PostgreSQL que genera informes detallados y gráficos a partir de los archivos de log de PostgreSQL
Prometheus ->  Prometheus es una herramienta de monitoreo de código abierto que se centra en la recopilación y el análisis de datos basados en series de tiempo.
Zabbix -> es una herramienta de monitoreo de código abierto que ofrece una amplia gama de características, incluyendo la supervisión de bases de datos PostgreSQL.
Nagios -> Con plugins específicos para PostgreSQL, Nagios puede monitorear el rendimiento y la seguridad de tu base de datos
Grafana -> Aunque se utiliza principalmente para la visualización de datos, Grafana se puede integrar con Prometheus y otras herramientas para proporcionar un monitoreo completo de PostgreSQL
pgNow -> pgNow es una herramienta gratuita para diagnóstico de rendimiento en PostgreSQL. Fue desarrollada por Redgate y permite obtener información en tiempo real sobre la salud, configuración y rendimiento de la base de datos.
Checkmk ->  herramienta de monitoreo de código abierto que ofrece monitoreo integral para bases de datos PostgreSQ
pgreplay ->  es una utilidad que reproduce el tráfico de consultas SQL registrado en los logs de PostgreSQL. Su propósito principal es simular una carga de trabajo real
powa (PostgreSQL Workload Analyzer):**  Un sistema de monitoreo que proporciona análisis detallados y gráficos sobre el rendimiento de las consultas, el uso de índices, y otras métricas clave, ayudando a los administradores a identificar y resolver problemas de rendimiento.

SIEM  detección de amenazas
Wazuh es una plataforma de seguridad de código abierto que ofrece una amplia gama de funcionalidades para la detección de amenazas, el monitoreo de integridad y la respuesta a incidente


pgmonitor -> https://github.com/CrunchyData/pgmonitor

| **[check_postgres](https://github.com/bucardo/check_postgres)** | Script de monitoreo basado en Nagios que automatiza la verificación de salud de la DB (bloqueos, replicación, espacio). | **Para Alertas:** Es el "perro guardián". Se integra con sistemas como Zabbix o Nagios para disparar correos o alarmas cuando algo sale de los parámetros normales. |

| **[PgHero](https://github.com/ankane/pghero)** | Dashboard gráfico de rendimiento que identifica de forma persistente consultas lentas, falta de índices y espacio desperdiciado. | **Para Optimización:** Es la favorita de los desarrolladores. Te da sugerencias claras de qué arreglar (como "crea este índice") sin que tengas que ser un experto en bases de datos. |

| **[pgCenter](https://github.com/lesovsky/pgcenter)** | Consola de administración en tiempo real que organiza las estadísticas de Postgres en una interfaz tipo `top` de Linux. | **Para Emergencias:** Es la herramienta de "guerra" del DBA. Te permite ver exactamente qué está pasando en el servidor en este segundo y "matar" procesos o ver bloqueos rápidamente. |

 libzbxpgsql -> zabbix tools postgresql -> https://github.com/zabbix-tools/libzbxpgsql


************ MONITOREO EN INICIO DE SESION ************
- **pgBouncer:** Pool de conexiones ligero para optimizar el manejo de conexiones.

************ MONITOREO DE ESPACIO ************

* **bg_mon (Background Monitor):** Es una herramienta de monitoreo en tiempo real que recolecta estadísticas del sistema (CPU, memoria, I/O) directamente desde el proceso de fondo de Postgres. Te permite ver qué está pasando con los recursos del servidor sin salir de la base de datos.

- **pg_stat_kcache:**  Complementa a la famosa `pg_stat_statements`. Mientras que la estándar te dice cuántas veces se ejecutó una consulta, esta te dice cuánta **CPU** y cuánto **uso de disco real** (a nivel de kernel) consumió esa consulta específicamente.

- **pg_stat_statements:** Rastrea y acumula estadísticas sobre el rendimiento de las consultas SQL. Permite identificar consultas lentas o que consumen muchos recursos.

- **pg_stat_user_tables:** Ofrece estadísticas sobre el uso de tablas por usuario, incluyendo conteo de accesos, cantidad de inserts, updates, deletes, y bloqueos. Es útil para entender el impacto de cada usuario en la base de datos.

- **pg_stat_activity:** Muestra la actividad actual en la base de datos, incluyendo las consultas que se están ejecutando, el tiempo que llevan ejecutándose, y el estado de las conexiones.

- **pg_stat_bgwriter:** Monitorea las actividades del background writer, un proceso de PostgreSQL que ayuda a escribir datos modificados en disco, lo que es esencial para mantener un rendimiento óptimo.

- **pg_stat_replication:** Proporciona información sobre el estado de la replicación, incluyendo detalles sobre los servidores en standby, el atraso de replicación, y la latencia. Es clave para garantizar la integridad y sincronización de los datos en entornos replicados.

- **pgmetrics:** Herramienta de línea de comandos que recopila una amplia gama de métricas sobre el estado de PostgreSQL, incluyendo información sobre el sistema operativo, conexiones, caché, I/O, entre otros. 

- **pg_top:** Similar al comando `top` de Linux, `pg_top` muestra el uso de recursos de PostgreSQL en tiempo real, permitiendo a los administradores identificar procesos que consumen muchos recursos.


 pgrowlocks en PostgreSQL se utiliza para mostrar información sobre los bloqueos de filas en una tabla específica. Aquí tienes un resumen de su funcionalidad: --> SELECT * FROM pgrowlocks('mi_tabla');


 . **pg_wait_sampling**:
   - **Descripción**: Esta extensión recopila Eventos estadísticas basadas en muestreo de eventos de espera en PostgreSQL. Permite obtener un historial de eventos de espera y un perfil de espera acumulado para todos los procesos, incluyendo los trabajadores en segundo plano⁵⁶.
   - **Uso**: Es útil para diagnosticar problemas de rendimiento y analizar qué procesos están esperando y por cuánto tiempo. Para habilitarla, debes agregar `pg_wait_sampling` a la variable `shared_preload_libraries` en el archivo `postgresql.conf` y reiniciar el servidor⁵.

 

************ MANTENIMIENTOS o análisis  ************
- **pg_repack:** Reorganiza tablas e índices sin bloquear operaciones.

- ** pg_squeeze:** Automatiza la compactación de tablas y sus índices para eliminar bloat sin necesidad de bloquear las tablas, mejorando el rendimiento en entornos de alta concurrencia.

- ** pg_ivm :**  permite actualizar vistas materializadas de manera incremental, lo que significa que solo se actualizan las partes que han cambiado

 pg_freespacemap en PostgreSQL se utiliza para examinar el mapa de espacio libre (FSM) de una relación (tabla o índice). Aquí tienes un resumen de su funcionalidad: --> SELECT * FROM pg_freespace('mi_tabla');
- **pg_visibility:** Permite investigar la visibilidad de las tuplas en las tablas y detectar problemas con vacuum.

- **pgstattuple:** Proporciona estadísticas detalladas sobre la ocupación de espacio en las tablas e índices, incluyendo tuplas muertas y espacio desperdiciado.

pageinspect  -> es una extensión de PostgreSQL que permite examinar el contenido de las páginas de la base de datos a bajo nivel. Mostrar información detallada sobre tuplas (filas) individuales

pg_surgery -> es una extensión oficial de PostgreSQL (introducida en la versión 14) diseñada para realizar operaciones de bajo nivel en las filas (tuplas) de una tabla e se utiliza para intervenir directamente en la salud de los datos cuando los mecanismos normales del motor (como DELETE o VACUUM) no funcionan debido a corrupción de datos.

- **pg_buffercache**: Permite monitorear el uso del buffer cache para entender mejor cómo se está utilizando la memoria y ajustar configuraciones en consecuencia(https://www.youtube.com/watch?v=prbF4O0d-7M).

- ** pgfincore:** Permite analizar qué partes de las tablas y los índices están en caché en la memoria del sistema operativo, ayudando a optimizar el uso de la caché.


************ BACKUP ************
Postgresus 2.0 --> Es una herramienta de copia de seguridad de PostgreSQL de código abierto con interfaz de usuario. Ejecuta copias de seguridad programadas de múltiples bases de datos, las guarda localmente o en almacenamientos externos, y notifica cuando las copias de seguridad se completan o fallan.

- **pg_dirtyread** Recuperar datos eliminados: Puedes acceder a las tuplas que han sido marcadas como eliminadas pero aún no han sido físicamente removidas. Auditoría y análisis: Permite realizar auditorías y análisis forenses de datos  https://github.com/df7cb/pg_dirtyread 

- **barman:** Herramienta de gestión de backups y recuperación para PostgreSQL Soporta la replicación en caliente y la recuperación ante desastres, ofreciendo una solución completa para la protección de datos.

- **pgBackRest:** Herramienta de backup y restauración que ofrece soporte para backups incrementales y diferenciales, así como recuperación punto en el tiempoCompatible con entornos de replicación para asegurar la coherencia de los datos.

- **wal-g:** Herramienta de backup y recuperación que soporta múltiples métodos de almacenamiento en la nube Ofrece soporte para backups completos y diferenciales, y está diseñada para trabajar en entornos con replicación.

### **2. Replicación y Alta Disponibilidad:**

pg_receivewal -> se utiliza para transmitir en tiempo real los registros de escritura anticipada (WAL) desde un servidor PostgreSQL a un directorio local o remoto
https://www.postgresql.org/docs/current/app-pgreceivewal.html
https://philipmcclarence.com/mastering-continuous-archiving-with-pg_receivewal/
https://www.cybertec-postgresql.com/en/never-lose-a-postgresql-transaction-with-pg_receivewal/

- **wal2json:** Genera datos en formato JSON a partir de los registros de WAL (Write-Ahead Logging), útil para replicación lógica y para aplicaciones que necesitan consumir los cambios en un formato legible.  https://github.com/eulerto/wal2json

**pgstream**  herramienta de captura de datos de cambios (CDC) de código abierto, Su función principal es "escuchar" los cambios que ocurren en tu base de datos (INSERTs, UPDATEs, DELETEs) y transmitirlos en tiempo real a otros destinos.


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

- **pgactive**  es una extensión para PostgreSQL que permite la replicación activa-activa, lo que significa que múltiples instancias de la base de datos pueden aceptar escrituras simultáneamente y sincronizar los cambios entre ellas desarrollada y mantenida por Amazon Web Services (AWS). Está disponible en Amazon RDS para PostgreSQL a partir de la versión 15.4-R2

- **pglogical:** Proporciona replicación lógica para PostgreSQL, permitiendo replicar cambios entre diferentes bases de datos y transformarlos en el proceso. https://github.com/2ndQuadrant/pglogical

Stolon: Un orquestador de PostgreSQL HA basado en Kubernetes, aunque también puede funcionar fuera de él. Utiliza etcd para el almacenamiento distribuido y la elección de líder.

 **pg_auto_failover**: Esta extensión y servicio para PostgreSQL gestiona la conmutación por error automatizada para un clúster de PostgreSQL, asegurando alta disponibilidad y consistencia de datos¹.
 
 **pg_failover_slots**: Hace que las ranuras de replicación lógica sean utilizables en una conmutación por error física, sincronizando las ranuras de replicación entre el nodo primario y el de respaldo¹¹.
 

************ BALANCEO DE CARGA EN REPLICAS ************
Keepalived -- Se usa para configurar direcciones IP virtuales en entornos de alta disponibilidad con VRRP.

- **pgpool-II:** Middleware que proporciona balanceo de carga y failover automático para PostgreSQL Permite la replicación en modo maestro-esclavo y distribuye las consultas entre las réplicas para mejorar el rendimiento.
Slony-I: Un sistema de replicación maestro-esclavo para PostgreSQL que permite replicar datos entre múltiples servidores.

HAProxy --> es un balanceador de carga y proxy inverso de código abierto. Se utiliza para distribuir el tráfico de red entre múltiples servidores, mejorando la disponibilidad y el rendimiento de los servicios web

PgCat es un proxy especializado para PostgreSQL, diseñado para mejorar el rendimiento y la escalabilidad.
Consul como servicio de descubrimiento y chequeo de salud de nodos PostgreSQL.

************  sistema distribuido ************ 
Citus es una extensión de código abierto para **PostgreSQL** que convierte la base de datos en un sistema distribuido mediante sharding y replicación, permitiendo escalar horizontalmente y mejorar el rendimiento en cargas de trabajo intensivas. Algunas de sus principales funciones incluyen:
 

- **Sharding automático**: Distribuye datos en múltiples nodos para mejorar la escalabilidad.
- **Consultas paralelas**: Ejecuta consultas en varios servidores simultáneamente, acelerando el procesamiento.
- **Soporte para multi-tenancy**: Ideal para aplicaciones SaaS con múltiples clientes.
- **Almacenamiento columnar**: Optimiza el rendimiento en análisis de datos y consultas agregadas.

multigres :  Es una capa de infraestructura (un proxy inteligente y un orquestador) que se coloca frente a tus instancias de PostgreSQL. Su objetivo es que puedas tener decenas o cientos de servidores de base de datos trabajando juntos, pero que tu aplicación los vea y los use como si fueran una sola base de datos Postgres estándar. y sirve para Sharding Horizontal,Enrutamiento de Consultas, Alta Disponibilidad y Failover, Pooling de Conexiones  https://multigres.com/docs

PgDog : actúa como middleware (capa intermedia) entre la aplicación y PostgreSQL. No necesitas cambiar el esquema ni el código de la aplicación: intercepta las consultas, decide a qué shard enviarlas, balancea carga y gestiona conexiones. Además, incluye pooling, failover y health checks, cosas que Citus no hace por sí mismo.

Escalar PostgreSQL horizontalmente vía sharding.
Mejorar rendimiento con balanceo de carga y pooling de conexiones.
Asegurar alta disponibilidad mediante health checks y failover automático.
Gestionar replicación lógica para mantener consistencia y facilitar reconfiguraciones.


 
### **7. Rendimiento y Optimización:**

pg_gather : Scan and collect the minimal amount of data needed to identify potential problems in your PostgreSQL database, and then generate an analysis report using that data. This project provides two SQL scripts for users:  
 https://github.com/jobinau/pg_gather
pgtune ->  calcula valores basados en reglas fijas de hardware y Ajusta parametro 
pg_tuner ->es una herramienta de optimización automática de parámetros de PostgreSQL que utiliza técnicas de Optimización Bayesiana a través de la librería Optuna  https://github.com/s-hironobu/pg_tuner

 pgbench : herramienta de benchmarking para probar el rendimiento de PostgreSQL. Ejecuta una serie de comandos SQL repetidamente en múltiples sesiones concurrentes y calcula la tasa promedio de transacciones (transacciones por segundo).
 pgingester : herramienta de benchmarking para evaluar diferentes métodos de ingestión de datos en lotes en PostgreSQL2. Mide el rendimiento de métodos como INSERT, COPY, Binary COPY, y UNNEST en términos de filas por segundo y duración de la ingestión.
- ** pg_partman:** Gestiona la partición de tablas de forma automática, lo cual es fundamental para mejorar el rendimiento en bases de datos con grandes volúmenes de datos, especialmente en tablas de series temporales.



- ** pg_prewarm:** Pre-carga tablas o índices en la memoria compartida de PostgreSQL al inicio del servidor, mejorando el rendimiento de las consultas que acceden frecuentemente a estos datos. (https://www.youtube.com/watch?v=prbF4O0d-7M).
 
- ** pg_hint_plan:** Permite a los administradores influir directamente en el planificador de consultas sugiriendo (hinting) cómo ejecutar consultas SQL, lo cual es útil para optimizar casos específicos donde el planificador no elige el mejor plan por defecto.

- ** auto_explain:** es una extensión de PostgreSQL que permite registrar automáticamente el plan de ejecución de las consultas que exceden un tiempo determinado en el log. Es útil para detectar cuellos de botella sin necesidad de modificar el código SQL.

- ** hypopg:** Permite simular la creación de índices sin necesidad de materializarlos físicamente, ayudando a evaluar el impacto de nuevos índices en el rendimiento antes de su creación.


- ** pl/profiler:** Proporciona un perfilador para PL/pgSQL, permitiendo medir el tiempo de ejecución de cada línea de código en las funciones almacenadas, lo cual es útil para identificar y optimizar cuellos de botella.

- ** pg_bulkload:** Optimiza la carga masiva de datos en PostgreSQL, permitiendo insertar grandes volúmenes de datos de manera eficiente, minimizando el impacto en el 
rendimiento general de la base de datos.

- ** timescaledb:** Una extensión optimizada para manejar series temporales de manera eficiente, mejorando el rendimiento en consultas que involucran grandes volúmenes de datos temporales.

- **pg_stat_monitor:** Extensión avanzada para monitoreo de consultas.




### **3. Índices y Búsqueda:**

- **pg_trgm:** Búsqueda de similitudes de texto mediante índices GIN/GIST.
- **btree_gin:** Extiende índices GIN para tipos de datos adicionales.
- **tsvector:** Permite búsqueda de texto completo.
- **rum:** Extensión para índices GIN avanzados, optimizados para búsquedas complejas.
- **GIN:** Optimiza la búsqueda en datos complejos, como arrays o textos largos.
- **pg_qualstats:** Permite recopilar estadísticas sobre las cláusulas WHERE utilizadas en las consultas, ayudando a identificar posibles mejoras en los índices.
- **amcheck:** Herramienta para verificar la integridad de los índices B-tree, útil para detectar y corregir corrupción de datos.




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


### **Migraciones **
pgTAP ->  te ayuda a comprobar que tus funciones SQL hacen lo que deberían hacer, antes de que las pongas en producción. Es como tener un "verificador automático" que te dice si tu lógica está bien o mal.
pg_comparator: comparar datos entre dos bases de datos o esquemas, ideal en escenarios de migración, sincronización o validación de integridad de datos. 

pg_comparator \
  --source "dbname=origen host=localhost user=postgres" \
  --target "dbname=destino host=localhost user=postgres" \
  --table public.clientes



### **9. Otros:**
- **dblink:** Ejecuta consultas en bases de datos remotas desde PostgreSQL.
-**tds_fdw ** Conecta y consulta otras bases SQL server de manera remota.
- **postgres_fdw:** Conecta y consulta otras bases PostgreSQL de manera remota.
- **plv8:** Extensión que permite escribir funciones en JavaScript.




 **pg_background**: Permite ejecutar comandos SQL en segundo plano, lo que es útil para tareas como `VACUUM` o `CREATE INDEX CONCURRENTLY` desde un lenguaje procedimental⁷.
 
 **pg_bigm**: Proporciona capacidad de búsqueda de texto completo mediante la creación de índices bigram (2-gram), lo que acelera las búsquedas de texto completo en PostgreSQL¹⁶.
 
 
 
 **pg_filedump**: Utilidad para formatear archivos de heap, índice o control de PostgreSQL en una forma legible para humanos, útil para la inspección de bajo nivel de tablas e índices²³.
 

 **pg_readonly**: Permite establecer todas las bases de datos de un clúster en modo solo lectura, útil para situaciones donde se requiere asegurar que no se realicen modificaciones[^20^].
 
 

 
 ### Tipos de Eventos Capturados
 

- **LWLock**: Bloqueos ligeros utilizados internamente por PostgreSQL.
- **Lock**: Bloqueos de nivel SQL, como bloqueos de filas o tablas.
- **BufferPin**: Esperas relacionadas con la fijación de buffers en memoria.
- **Activity**: Esperas relacionadas con la actividad del proceso, como `ClientRead`, `ClientWrite`, etc.
- **IPC**: Esperas de comunicación entre procesos.
- **Timeout**: Esperas relacionadas con tiempos de espera configurados.
 



### Replicación y Datos

* **decoderbufs:** Es una extensión lógica de decodificación que utiliza **Protocol Buffers (Protobuf)**. Sirve principalmente para enviar cambios de la base de datos a herramientas de terceros como **Debezium**, facilitando la arquitectura de *Change Data Capture* (CDC).
* **pgq (PostgreSQL Queue):** Un sistema de **colas genérico** de alto rendimiento. Se usa cuando necesitas procesar eventos de forma asíncrona dentro de la base de datos (por ejemplo, "enviar un correo después de que se inserte un usuario").


* **pgfaceting:** Diseñada para implementar **búsquedas por facetas** de manera ultra rápida (como los filtros de "Talla", "Color" o "Marca" en Amazon). Optimiza la computación de estos filtros sobre grandes volúmenes de datos.
 

### Funciones Avanzadas y Big Data

* **plproxy:** Es un lenguaje de procedimientos que actúa como un **proxy**. Permite distribuir consultas entre múltiples bases de datos (sharding). La aplicación le pide algo a "Postgres A" y `plproxy` sabe que debe ir a buscarlo a "Postgres B" o "C".

* **roaringbitmap:** Implementa un tipo de dato llamado "Roaring Bitmaps". Se usa para realizar operaciones de conjuntos (Intersección, Unión, Diferencia) de forma **increíblemente rápida** sobre millones de registros. Es muy común en sistemas de análisis de audiencia o segmentación de usuarios.




CREATE EXTENSION cstore_fdw; --> permite almacenar datos en formato columnar en lugar del formato tradicional de filas.
CREATE SERVER cstore_server FOREIGN DATA WRAPPER cstore_fdw;
CREATE FOREIGN TABLE nombre_tabla (
    columna1 tipo,
    columna2 tipo
) SERVER cstore_server OPTIONS (compression 'pglz');

shared_preload_libraries = 'cstore_fdw'
https://github.com/citusdata/cstore_fdw


```

----


### Resumen para tu repositorio:

Si estás armando un ecosistema de herramientas, podrías agruparlas así:

1. **Seguridad:** `edb_block_commands`, `monitoring_role`.
2. **Búsqueda avanzada:** `zombodb`, `pg_search`.
3. **Análisis de datos masivos (Big Data):** `pipelinedb`, `pg-strom`.
4. **Geospatial:** `dumppoints`.


### 1. [edb_block_commands](https://github.com/vibhorkum/edb_block_commands)

**¿Qué es?**
Es una extensión diseñada para bloquear comandos SQL específicos a nivel de base de datos. Permite a los administradores prohibir el uso de comandos peligrosos (como `DROP TABLE` o `TRUNCATE`) incluso para usuarios que normalmente tendrían permiso para ejecutarlos.

* **Caso de uso real:** En un entorno de **Producción Crítico**, quieres evitar que un administrador, por un error de dedo o un script mal configurado, borre una tabla importante. Configuras la extensión para bloquear `DROP TABLE` y `TRUNCATE` en horario laboral, obligando a que cualquier cambio estructural pase por un proceso manual de desbloqueo.
 
 
 

### 2. [monitoring_role](https://github.com/frost242/monitoring_role)

**¿Qué es?**
Es un script/herramienta de ayuda para versiones antiguas de PostgreSQL (anteriores a la 10) que facilita la creación de un usuario con permisos de "solo monitoreo". En versiones modernas de Postgres esto ya viene incluido (`pg_monitor`), pero este repo soluciona el problema de dar acceso a métricas sin dar acceso a los datos.

* **Caso de uso real:** Tienes un servidor de **Zabbix o Prometheus** que necesita conectarse a tu base de datos para medir el uso de CPU y el tamaño de las tablas, pero no quieres que el usuario del monitor pueda ver los saldos de las cuentas de tus clientes por razones de privacidad.

 
### 3. [pipelinedb](https://github.com/pipelinedb/pipelinedb)

**¿Qué es?**
Es una extensión (antiguamente una base de datos propia) para **Streaming de Datos**. Permite ejecutar consultas continuas sobre flujos de datos en tiempo real. En lugar de guardar los datos y luego consultarlos, PipelineDB calcula los resultados (agregaciones) a medida que los datos entran y solo guarda el resultado final.

* **Caso de uso real:** Una aplicación de **Internet de las Cosas (IoT)** que recibe 10,000 lecturas de temperatura por segundo. No quieres guardar millones de filas; solo quieres saber el "promedio por minuto". PipelineDB procesa el flujo en memoria y solo guarda una fila por minuto con el promedio calculado.

 

### 4. [zombodb](https://github.com/zombodb/zombodb)

**¿Qué es?**
Es una integración profunda entre **PostgreSQL y Elasticsearch**. Permite que los índices de tus tablas en Postgres sean en realidad índices de Elasticsearch. Esto te da la potencia de búsqueda "Full-Text" (borrosa, por relevancia, autocompletado) de Elasticsearch usando SQL estándar.

* **Caso de uso real:** Tienes una **Tienda Online** con millones de productos. Quieres que cuando un usuario busque "zapato azul", el sistema devuelva resultados incluso si hay errores tipográficos o sinónimos. Usas ZomboDB para buscar en Elasticsearch desde Postgres con un simple `SELECT * FROM productos WHERE nombre ==> 'zapato azul'`.

 

### 5. [pg_search (de ParadeDB)](https://github.com/paradedb/paradedb/tree/main/pg_search)

**¿Qué es?**
Es el sucesor moderno e interno de ParadeDB para búsquedas. Utiliza el motor **Tantivy** (escrito en Rust) para dar capacidades de búsqueda rápida tipo Elasticsearch pero *dentro* de PostgreSQL, sin necesidad de un servidor externo de Elasticsearch.

* **Caso de uso real:** Quieres la velocidad de búsqueda de un motor dedicado (como Algolia o Elasticsearch) pero **no quieres gestionar otro servidor**. Instalas esta extensión y tus búsquedas de texto en documentos legales o artículos de blog se vuelven 100 veces más rápidas que el `LIKE` o `tsvector` tradicional.

 

### 6. [pg-strom](https://github.com/heterodb/pg-strom)

**¿Qué es?**
Es una extensión de alto rendimiento que permite a PostgreSQL utilizar la **GPU (tarjeta gráfica)** y el almacenamiento NVME directo para procesar consultas. Está diseñada para Big Data y analítica pesada.

* **Caso de uso real:** Una empresa de **Telecomunicaciones** que analiza billones de registros de llamadas (CDR) para detectar fraude. En lugar de que la CPU del servidor se sature procesando millones de sumas, pg-strom envía la carga a una tarjeta NVIDIA, reduciendo el tiempo de consulta de horas a segundos.

 

### 7. [dumppoints](https://github.com/nmandery/dumppoints)

**¿Qué es?**
Es una herramienta muy específica para **PostGIS** (geografía en Postgres). Sirve para extraer los puntos individuales de geometrías complejas (como líneas o polígonos) de forma eficiente.

* **Caso de uso real:** Tienes un mapa de una **red de carreteras** (líneas) y necesitas extraer cada coordenada (latitud/longitud) de las curvas para enviarlas a un GPS que solo entiende puntos simples. Esta herramienta "desarma" la carretera en sus puntos constituyentes de forma masiva.
 


## Blibliografía
```SQL

https://ext.pigsty.io/ -- Instala extensiones con pig un gestor de paquetes grande 

PostgreSQL: ¡La inyección de dependencia definitiva! -> https://medium.com/@sbaitmangalkar/postgresql-the-ultimate-dependency-injection-fcad7f103bbc

Software Catalogue - Product Categories  https://www.postgresql.org/download/product-categories/
---- https://www.postgresql.org/ftp/projects/ 

https://wener.me/notes/db/relational/postgresql/extension

https://www.timescale.com/blog/top-8-postgresql-extensions/

--- Extensiones
https://postgres.ai/docs/database-lab/supported-databases
https://github.com/dhamaniasad/awesome-postgres


https://www.timescale.com/blog/top-8-postgresql-extensions/

 
 
---- crear extensiones: https://postgresconf.org/system/events/document/000/001/158/pg-extensions.pdf 


Extension List https://autobase.tech/docs/extensions/list

https://www.postgresql.org/ftp/projects/

-- Mas de 1000 extensiones para postgresql
https://gist.github.com/joelonsql/e5aa27f8cc9bd22b8999b7de8aee9d47
-----------------------------------------------------------
 						IA 
----------------------------------------------------


https://docs.pgedge.com/?_gl=1*1vi3im3*_gcl_au*MTQ0ODEyNTYxMC4xNzY1ODI4ODQy#pgedge-tools-and-utilities
pgEdge Postgres MCP Server : https://dbhub.ai/ O https://github.com/FreePeak/db-mcp-server
pgEdge RAG Server
pgEdge Vectorizer
postgresml -> convierte a tu base de datos PostgreSQL en una plataforma de ML completa. https://github.com/postgresml/postgresml

-- Trabajo con Vectores
- vectorchord
- pgvector
- pg_vectorize

```
