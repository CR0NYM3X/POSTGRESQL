
# 🛡️ Ecosistema Profesional de Seguridad para PostgreSQL

Este catálogo clasifica las herramientas esenciales para garantizar la tríada de la seguridad (Confidencialidad, Integridad y Disponibilidad) en entornos PostgreSQL.

## 1. Protección Perimetral y Contra Ataques (IPS/IDS)

Herramientas diseñadas para detectar y bloquear intentos de intrusión o abusos antes de que comprometan el motor de la base de datos.

* **Fail2Ban:** Sistema de prevención de intrusiones que monitoriza los logs de PostgreSQL y bloquea IPs que muestran comportamientos sospechosos (múltiples intentos fallidos).
* [Repositorio/Web](https://github.com/fail2ban/fail2ban)


* **CrowdSec:** Plataforma de seguridad colaborativa que utiliza inteligencia colectiva para bloquear ataques de fuerza bruta y escaneos maliciosos a nivel de red y aplicación.
* [Repositorio/Web](https://github.com/crowdsecurity/crowdsec)


* **pg_snakeoil:** Denominado el "Antivirus para PostgreSQL", es una extensión que permite escanear datos dentro de la base de datos en busca de firmas de malware.
* [Repositorio/Web](https://github.com/df7cb/pg_snakeoil)



## 2. Proxies y Middleware de Seguridad

Optimización del tráfico y control del flujo de conexiones para prevenir ataques de Denegación de Servicio (DoS) y asegurar la continuidad.

* **PgBouncer:** Proxy ligero de pooling de conexiones. Vital para limitar el número de conexiones simultáneas y prevenir el agotamiento de recursos por sesiones abusivas.
* [Repositorio/Web](https://github.com/pgbouncer/pgbouncer)


* **ProxySQL:** Protocolo de capa 7 diseñado para bases de datos que permite balanceo de carga, segregación de lectura/escritura y firewalls de consultas.
* [Repositorio/Web](https://github.com/sysown/proxysql)


* **HAProxy:** Balanceador de carga de alto rendimiento que actúa como proxy inverso para distribuir tráfico entre nodos de bases de datos, garantizando alta disponibilidad.
* [Repositorio/Web](https://github.com/haproxy/haproxy)


14. **[PSQLProxy](https://github.com/dajudge/psqlproxy)**
* **Descripción:** Un proxy de red que se sitúa entre el cliente y el servidor PostgreSQL.
* **Objetivo:** Proporcionar una capa adicional de control, permitiendo inspeccionar o filtrar el tráfico SQL por razones de seguridad.


15. **[Security Vault Credential Broker](https://github.com/padok-team/security-vault-credential-broker)**
* **Descripción:** Intermediario para gestionar credenciales dinámicas de bases de datos utilizando HashiCorp Vault.
* **Objetivo:** Eliminar el uso de contraseñas estáticas, rotando credenciales automáticamente para cada sesión o aplicación.


16. **[Rate Limit PostgreSQL](https://github.com/express-rate-limit/rate-limit-postgresql)**
* **Descripción:** Almacén para el middleware `express-rate-limit` que utiliza Postgres para persistir límites de tasa de peticiones.
* **Objetivo:** Mitigar ataques de fuerza bruta o denegación de servicio (DoS) contra aplicaciones que interactúan con Postgres.






## 3. Cifrado y Protección de Datos (Data at Rest & In Transit)

Mecanismos para asegurar que la información sea ilegible para actores no autorizados, tanto en disco como en la red.

* **pg_tde (Transparent Data Encryption):** Extensión que cifra los archivos de datos en el disco duro. Protege contra el robo físico de discos o backups.
* [Repositorio/Web](https://www.google.com/search?q=https://github.com/cybertec-postgresql/pg_tde)


* **HashiCorp Vault:** Gestión centralizada de secretos. Permite la rotación dinámica de credenciales de PostgreSQL y la gestión de claves de cifrado externas.
* [Repositorio/Web](https://github.com/hashicorp/vault)


* **Let's Encrypt:** Autoridad de certificación que permite implementar certificados SSL/TLS gratuitos para cifrar el tráfico entre el cliente y el servidor PostgreSQL.
* [Repositorio/Web](https://letsencrypt.org/)


* **pgcrypto:** Biblioteca core que proporciona funciones criptográficas (hashing, cifrado AES, PGP) directamente desde SQL para proteger columnas sensibles.
* [Repositorio/Web](https://www.postgresql.org/docs/current/pgcrypto.html)


* **pgsodium:** Extensión de criptografía moderna basada en libsodium, ideal para firmas digitales y cifrado de alta seguridad.
* [Repositorio/Web](https://github.com/michelp/pgsodium)


* **sslutils:** Herramientas de soporte para gestionar certificados SSL y CRLs (listas de revocación) dentro de PostgreSQL.
* [Repositorio/Web](https://www.google.com/search?q=https://github.com/shuber2/sslutils)



## 4.  Control de Acceso y Privilegios y Políticas (IAM)

Control estricto sobre quién puede entrar y qué puede hacer dentro de la instancia. Herramientas que modifican o restringen el comportamiento interno de Postgres para evitar escalada de privilegios.


* **credcheck:** Permite definir políticas de complejidad para credenciales, como longitud mínima y reutilización de contraseñas.
* [Repositorio/Web](https://github.com/MigOpsRepos/credcheck)


* **passwordpolicy:** Extensión para forzar políticas de contraseñas robustas y gestionar la expiración de las mismas.
* [Repositorio/Web](https://github.com/eendroroy/passwordpolicy)


* **passwordcheck:** Módulo nativo de PostgreSQL que realiza validaciones básicas de fortaleza de contraseñas durante su creación.
* [Repositorio/Web](https://www.postgresql.org/docs/current/passwordcheck.html)


* **pg_auth_mon:** Monitoriza y registra eventos de autenticación, permitiendo analizar patrones de login exitosos y fallidos.
* [Repositorio/Web](https://github.com/RafiaSabih/pg_auth_mon)


* **session_exec:** Permite ejecutar funciones personalizadas al inicio de una sesión, útil para auditoría inmediata o bloqueo de aplicaciones específicas.
* [Repositorio/Web](https://github.com/okbob/session_exec)


* **pg_permissions:** Proporciona una interfaz de vistas para auditar de forma sencilla qué usuarios tienen qué privilegios sobre los objetos de la base de datos.
* [Repositorio/Web](https://www.google.com/search?q=https://github.com/markokortelainen/pg_permissions)


* **pgextwlist (Extensions Whitelist):** Permite a los DBAs definir qué extensiones pueden instalar los usuarios que no son superusuarios, mitigando riesgos de elevación de privilegios.
* [Repositorio/Web](https://github.com/dimitri/pgextwlist)


* **PostgreSQL Security Extensions:** Conjunto de herramientas enfocadas en autenticación avanzada y controles de acceso granulares.
* [Repositorio/Web](https://www.postgresql.org/docs/current/external-extensions.html)



* **[Supautils](https://github.com/supabase/supautils)**
* **Descripción:** Extensión que permite desbloquear funciones avanzadas (como crear eventos o publicaciones) a roles que no son superusuarios, de forma controlada.
* **Objetivo:** Implementar el principio de "mínimo privilegio" permitiendo gestionar la base de datos sin otorgar permisos de `SUPERUSER`.


* **[Aiven PG Security](https://github.com/Aiven-Open/aiven-pg-security)**
* **Descripción:** Filtro de seguridad que previene ataques comunes de escalada de privilegios al momento de crear extensiones.
* **Objetivo:** Blindar la base de datos contra el uso malicioso de funciones privilegiadas que podrían comprometer el host.


* **[PG_RLS](https://github.com/Dandush03/pg_rls)**
* **Descripción:** Herramienta o utilitario para facilitar la implementación de Seguridad a Nivel de Fila (Row Level Security).
* **Objetivo:** Garantizar que los usuarios solo puedan ver o modificar los datos que les corresponden según su rol.


* **[Doctrine PostgreSQL RLS](https://github.com/77web/doctrine-postgresql-row-level-security)**
* **Descripción:** Integración para el ORM Doctrine que permite manejar RLS de Postgres desde la aplicación PHP.
* **Objetivo:** Asegurar que la lógica de seguridad a nivel de datos se mantenga consistente entre la aplicación y la base de datos.


* **[Ldap2pg](https://github.com/dalibo/ldap2pg)**
* **Descripción:** Herramienta de sincronización que gestiona roles y privilegios en Postgres basándose en un directorio LDAP/Active Directory.
* **Objetivo:** Centralizar la gestión de identidades y accesos, evitando cuentas huérfanas o permisos manuales inconsistentes.





## 5. Auditoría, Cumplimiento y Análisis Forense

Registro detallado de actividades y validación de la integridad del sistema frente a normativas internacionales.

* **pgaudit (PostgreSQL Audit Extension):** Proporciona auditoría detallada de sesiones y objetos. Es el estándar para cumplimiento normativo (SOC2, HIPAA, PCI).
* [Repositorio/Web](https://github.com/pgaudit/pgaudit)


* **pgaudit_analyze:** Este es el compañero más directo. Es un script diseñado específicamente para leer los logs generados por pgAudit e insertarlos en una base de datos para su análisis posterior.
* [Repositorio/Web](https://github.com/pgaudit/pgaudit_analyze)


* **pgauditlogtofile:** Complemento para pgaudit que redirige los logs de auditoría a archivos independientes, evitando saturar el log principal de PostgreSQL.
* [Repositorio/Web](https://github.com/df7cb/pgauditlogtofile)


* **pgstigcheck-inspec:** Automatización de auditoría basada en InSpec para verificar el cumplimiento con las guías de seguridad STIG de la DISA.
* [Repositorio/Web](https://github.com/CrunchyData/pgstigcheck-inspec)


* **pg_track_settings:** Registra históricamente cualquier cambio en los parámetros de configuración de PostgreSQL, permitiendo detectar modificaciones no autorizadas.
* [Repositorio/Web](https://www.google.com/search?q=https://github.com/voppman/pg_track_settings)

* **config_log:** Extensión que registra cualquier cambio en los parámetros de configuración en tablas de la base de datos, facilitando la auditoría de integridad operativa.
* [Repositorio](https://github.com/ibarwick/config_log)

* **pg_filedump:** Herramienta esencial para análisis forense y recuperación. Permite leer archivos de datos directamente del disco para investigar corrupción o extraer datos de motores caídos.
* [Repositorio/Web](https://github.com/df7cb/pg_filedump)


* **ELK Stack (Elasticsearch, Logstash, Kibana):** Suite para la centralización, visualización y análisis avanzado de logs de base de datos.
* [Repositorio/Web](https://www.elastic.co/elastic-stack)


* **OSSEC:** Sistema de monitoreo de integridad de archivos y detección de intrusiones a nivel de host (HIDS).
* [Repositorio/Web](https://github.com/ossec/ossec-hids)



## 6. Privacidad y Enmascaramiento de Datos

Técnicas para proteger la información sensible en entornos de desarrollo o analítica sin exponer datos reales.

* **PostgreSQL Anonymizer:** Potente extensión para enmascarar o anonimizar datos sensibles basándose en reglas declarativas.
* [Repositorio/Web](https://postgresql-anonymizer.readthedocs.io/)


* **pg_datamask (Cybertec):** Solución para el enmascaramiento dinámico de datos, asegurando que los usuarios solo vean lo que su rol les permite.
* [Repositorio/Web](https://www.cybertec-postgresql.com/en/products/data-masking-for-postgresql/)


* **Data Masking (General):** Concepto de protección mediante enmascaramiento estático y dinámico para cumplimiento de regulaciones como GDPR.

## 7. Validación y Seguridad del Sistema Operativo

Endurecimiento (Hardening) a nivel de lenguaje de programación y sistema base.

* **plpgsql_check:** Herramienta de análisis estático para código PL/pgSQL que detecta errores y posibles vulnerabilidades en funciones y procedimientos.
* [Repositorio/Web](https://github.com/okbob/plpgsql_check)


* **sepgsql:** Implementación de SELinux (Security-Enhanced Linux) para PostgreSQL. Aplica control de acceso obligatorio (MAC) a nivel de objetos de base de datos.
* [Repositorio/Web](https://www.postgresql.org/docs/current/sepgsql.html)


* **SE-PostgreSQL:** Proyecto de seguridad basado en políticas de seguridad obligatorias integradas con el kernel de Linux.



----

 

# 🛡️ Ecosistema Profesional de Seguridad para PostgreSQL (Parte 2)

Esta sección se enfoca en la validación ofensiva (Pentesting), la automatización del endurecimiento (Infrastructure as Code) y el cumplimiento de estándares internacionales (CIS/STIG).

## 1. Pentesting y Auditoría de Vulnerabilidades (Seguridad Ofensiva)

Herramientas utilizadas por auditores y especialistas en seguridad para encontrar debilidades y simular ataques controlados.

* **pghostile:** Herramienta de auditoría diseñada para automatizar la explotación de configuraciones débiles. Su objetivo es identificar vectores que permitan la escalada de privilegios dentro del motor.
* [Repositorio](https://github.com/Aiven-Open/pghostile)


* **PostgreSQL Penetration Testing Guide:** Recurso técnico que detalla metodologías para realizar pruebas de penetración específicas en bases de datos PostgreSQL, desde el descubrimiento hasta la exfiltración.
* [Repositorio](https://github.com/JFR-C/Database-Security-Audit/blob/master/PostgreSQL%20database%20penetration%20testing)


* **pg_gather:** Aunque se asocia al rendimiento, es vital para la seguridad "sin agentes". Recopila el estado de roles y privilegios mediante SQL puro, permitiendo auditorías externas sin instalar software adicional.
* [Repositorio](https://github.com/jobinau/pg_gather)

* **[PGSpot](https://github.com/timescale/pgspot)**
* **Descripción:** Herramienta de escaneo estático (linter) para scripts SQL que busca vulnerabilidades de seguridad, especialmente ataques basados en `search_path`.
* **Objetivo:** Detectar fallos de seguridad en el código SQL de extensiones o funciones antes de que se ejecuten en producción.


* **[ESLint Plugin PostgreSQL](https://github.com/baseballyama/eslint-plugin-postgresql)**
* **Descripción:** Plugin para ESLint que analiza consultas SQL incrustadas en código JavaScript.
* **Objetivo:** Identificar malas prácticas y posibles riesgos de seguridad en las consultas enviadas desde el backend.


* **[PostgreSQL Security Toolkit](https://github.com/sendtoshailesh/postgresql-security-toolkit)**
* **Descripción:** Colección de scripts diseñados para auditar configuraciones de red, autenticación y cifrado.
* **Objetivo:** Realizar auditorías rápidas de salud de seguridad en entornos Postgres existentes.

* **[Crunchy Data PostgreSQL STIG Baseline](https://github.com/mitre/crunchy-data-postgresql-stig-baseline)**
* **Descripción:** Perfil de InSpec diseñado para automatizar la auditoría de cumplimiento con la Guía de Implementación Técnica de Seguridad (STIG) del Departamento de Defensa (DoD) para PostgreSQL.
* **Objetivo:** Facilitar la verificación automática de configuraciones de seguridad, asegurando que la base de datos cumpla con normativas gubernamentales estrictas.


* **[CIS Hardening PostgreSQL 15](https://github.com/sglusnevs/cis-hardening-pgsql-15)**
* **Descripción:** Un conjunto de scripts o guías (basadas en Ansible/Shell) para aplicar las recomendaciones del CIS (Center for Internet Security) específicamente para la versión 15 de Postgres.
* **Objetivo:** Reducir la superficie de ataque configurando parámetros críticos del sistema operativo y de la base de datos siguiendo las mejores prácticas de la industria.


* **[PostgreSQL STIG Ansible Playbook](https://www.google.com/search?q=https://github.com/dokuhebi/postgresql_stig_ansible_playbook)**
* **Descripción:** Playbook de Ansible para automatizar la implementación de los controles de seguridad STIG en servidores PostgreSQL.
* **Objetivo:** Lograr una configuración repetible y segura ("Security as Code") en despliegues masivos de bases de datos.


* **[RDS PostgreSQL Hardening Check](https://www.google.com/search?q=https://github.com/jithinkelakam-hue/RDS-PostgresSQL-Hardening-Check)**
* **Descripción:** Herramienta enfocada en entornos gestionados (AWS RDS) para verificar si las instancias siguen las configuraciones de seguridad recomendadas.
* **Objetivo:** Auditar la seguridad de bases de datos en la nube donde el acceso al sistema operativo es limitado.


* **[Postgres Baseline (EasyAppSecurity)](https://github.com/EasyAppSecurity/postgres-baseline)**
* **Descripción:** Repositorio que define una línea base de configuración segura para entornos de producción.
* **Objetivo:** Servir como guía de referencia rápida para hardening inicial.


 

 

## 2. Hardening Automatizado y Cumplimiento (Compliance as Code)

Herramientas que aplican automáticamente configuraciones de seguridad siguiendo estándares como CIS (Center for Internet Security) y DISA STIG.

* **pgdsat (PostgreSQL Database Security Assessment Tool):** Evalúa más de 70 controles de seguridad basados en CIS Benchmark. Genera informes profesionales en HTML sobre permisos críticos y configuraciones de riesgo.
* [Repositorio](https://github.com/klouddb/klouddbshield)


* **klouddbshield:** Suite integral que incluye escaneo de PII (Información de Identificación Personal), auditoría de certificados SSL y validación profunda del archivo de acceso `pg_hba.conf`.
* [Repositorio](https://github.com/klouddb/klouddbshield)


* **Ansible-Lockdown (POSTGRES-12-CIS):** Rol de Ansible que automatiza la aplicación del Benchmark CIS para PostgreSQL 12, garantizando un nivel de seguridad empresarial.
* [Repositorio](https://github.com/ansible-lockdown/POSTGRES-12-CIS)


* **Chef & Puppet Postgres Hardening:** Libros de recetas y módulos diseñados para endurecer automáticamente `postgresql.conf` y `pg_hba.conf` en infraestructuras gestionadas por Chef o Puppet.
* [Repo Chef](https://github.com/dev-sec/chef-postgres-hardening) | [Repo Puppet](https://github.com/dev-sec/puppet-postgres-hardening)


* **Postgres-baseline (InSpec):** Perfil de auditoría que verifica si una instancia cumple con las mejores prácticas de seguridad de la comunidad "DevSec".
* [Repositorio](https://github.com/dev-sec/postgres-baseline)


* **pgstigcheck-inspec:** Herramienta específica para el cumplimiento con la guía STIG de la DISA, requisito indispensable para entornos gubernamentales y militares.
* [Repositorio](https://github.com/CrunchyData/pgstigcheck-inspec)



## 3. Control de Comandos y Gestión de Configuración

Mecanismos para prevenir errores humanos críticos y rastrear cambios en el comportamiento del clúster.

* **edb_block_commands:** Permite bloquear comandos SQL específicos (como `DROP TABLE` o `TRUNCATE`) incluso para usuarios privilegiados, ideal para evitar desastres en producción.
* [Repositorio](https://github.com/vibhorkum/edb_block_commands)




* **monitoring_role:** Facilita la creación de roles de solo lectura para herramientas de monitoreo (Zabbix/Prometheus) en versiones antiguas de PostgreSQL, protegiendo la privacidad de los datos.
* [Repositorio](https://github.com/frost242/monitoring_role)


* **Reference Hardening Script (Gist):** Guía rápida y scripts de referencia para la configuración óptima de parámetros de red y cifrado TLS.
* [Repositorio](https://gist.github.com/neverinfamous/a432070ab2e3c31a766fea58dddd0574)



 
