

# 🛡️ PostgreSQL Security Ecosystem: Guía de Arquitectura de Seguridad

Esta guía consolida las herramientas esenciales para blindar PostgreSQL, organizadas bajo el modelo de **Defensa en Profundidad**.

---

## 1. Seguridad de Red y Perímetro (Network Security)

*Control de tráfico, prevención de intrusiones y balanceo seguro.*

### 🛡️ IPS/IDS y Protección contra Ataques

* **[Fail2Ban](https://github.com/fail2ban/fail2ban):** Bloqueo automático de IPs tras múltiples intentos fallidos de login.
* **[CrowdSec](https://github.com/crowdsecurity/crowdsec):** Detección colaborativa de comportamientos maliciosos a nivel de red.
* **[pg_snakeoil](https://github.com/df7cb/pg_snakeoil):** Escaneo de firmas de malware directamente dentro de las tablas (el "antivirus" de Postgres).

### 🔄 Proxies y Middlewares de Seguridad

* **[PgBouncer](https://github.com/pgbouncer/pgbouncer):** Pooling de conexiones para mitigar ataques DoS por agotamiento de recursos.
* **[ProxySQL](https://github.com/sysown/proxysql):** Firewall de consultas y balanceo de carga de capa 7.
* **[HAProxy](https://github.com/haproxy/haproxy):** Distribución de tráfico segura y alta disponibilidad.
* **[PSQLProxy](https://github.com/dajudge/psqlproxy):** Capa intermedia para inspección y filtrado de tráfico SQL.
* **[Rate Limit PostgreSQL](https://github.com/express-rate-limit/rate-limit-postgresql):** Control de tasa de peticiones persistido en Postgres para aplicaciones Express.

---

## 2. Gestión de Identidades y Accesos (IAM)

*Quién puede entrar y qué privilegios mínimos necesita.*

### 🔑 Autenticación y Gestión de Secretos

* **Infisical:**    Gestión centralizada y rotación dinámica de credenciales. más simple que Vault.  El "Vault" para Desarrolladores
* **OpenBao (El "Fork" Comunitario):**   Gestión centralizada y rotación dinámica de credenciales. totalmente open source  Es 100% compatible con los comandos, APIs y plugins de Vault. Si ya sabes usar Vault
* **[HashiCorp Vault](https://github.com/hashicorp/vault):** Gestión centralizada y rotación dinámica de credenciales.
* **[Security Vault Credential Broker](https://github.com/padok-team/security-vault-credential-broker):** Intermediario para inyectar credenciales dinámicas de Vault.
* **[Ldap2pg](https://github.com/dalibo/ldap2pg):** Sincronización automática de roles y permisos con LDAP/Active Directory.
* **[pg_auth_mon](https://github.com/RafiaSabih/pg_auth_mon):** Monitor de eventos de login para detectar anomalías.


### 📜 Políticas de Contraseñas y Ejecución

* **[credcheck](https://github.com/MigOpsRepos/credcheck):** Definición de políticas de complejidad y reutilización de claves.
* **[passwordpolicy](https://github.com/eendroroy/passwordpolicy):** Extensión para forzar expiración y robustez de contraseñas.
* **[passwordcheck](https://www.postgresql.org/docs/current/passwordcheck.html):** Módulo nativo para validación de fuerza de claves.
* **[session_exec](https://github.com/okbob/session_exec):** Ejecución de funciones al inicio de sesión para validaciones extra.

### 🛂 Control de Privilegios (Least Privilege)

* **[Supautils](https://github.com/supabase/supautils):** Permite tareas administrativas a roles no-superusuarios de forma segura.
* **[Aiven PG Security](https://github.com/Aiven-Open/aiven-pg-security):** Filtro que previene escalada de privilegios durante la creación de extensiones.
* **[pgextwlist](https://github.com/dimitri/pgextwlist):** Whitelist de extensiones permitidas para usuarios regulares.
* **[pg_permissions](https://github.com/markokortelainen/pg_permissions):** Vistas simplificadas para auditar la matriz de privilegios.
* **[monitoring_role](https://github.com/frost242/monitoring_role):** Roles de solo lectura para herramientas de monitoreo en versiones legacy.

---

## 3. Protección de Datos (Data Protection)

*Cifrado en reposo, en tránsito y técnicas de anonimización.*

### 🔒 Cifrado (Encryption)

* **[pg_tde](https://github.com/cybertec-postgresql/pg_tde):** Cifrado de datos transparente (TDE) a nivel de archivos de disco.
* **[pgcrypto](https://www.postgresql.org/docs/current/pgcrypto.html):** Funciones core para hashing y cifrado de columnas mediante SQL.
* **[pgsodium](https://github.com/michelp/pgsodium):** Criptografía moderna basada en libsodium (firmas y sellado).
* **[Let's Encrypt](https://letsencrypt.org/):** Certificados SSL/TLS gratuitos para cifrado en tránsito.
* **[sslutils](https://github.com/shuber2/sslutils):** Herramientas para gestión de certificados y CRLs dentro del motor.

### 🎭 Privacidad y Enmascaramiento (Masking & RLS)

* **[PostgreSQL Anonymizer](https://postgresql-anonymizer.readthedocs.io/):** Anonimización de datos sensibles basada en reglas.
* **[pg_datamask (Cybertec)](https://www.cybertec-postgresql.com/en/products/data-masking-for-postgresql/):** Enmascaramiento dinámico según el rol del usuario.
* **[PG_RLS](https://github.com/Dandush03/pg_rls):** Facilitador para implementar Row Level Security (RLS).
* **[Doctrine PostgreSQL RLS](https://github.com/77web/doctrine-postgresql-row-level-security):** Integración de RLS para aplicaciones PHP/Doctrine.

---

## 4. Auditoría, Forense y Observabilidad

*Registro de actividad y respuesta ante incidentes.*

### 📋 Auditoría de Actividad (Logging)

* **[pgaudit](https://github.com/pgaudit/pgaudit):** Estándar de oro para auditoría detallada (cumplimiento SOC2/HIPAA).
* **[pgaudit_analyze](https://github.com/pgaudit/pgaudit_analyze):** Analizador de logs de pgAudit para inserción en DB.
* **[pgauditlogtofile](https://github.com/df7cb/pgauditlogtofile):** Redirección de logs de auditoría a archivos dedicados.
* **[ELK Stack](https://www.elastic.co/elastic-stack):** Centralización y visualización avanzada de logs.

### 🔎 Integridad y Análisis Forense

* **[pg_track_settings](https://github.com/voppman/pg_track_settings):** Histórico de cambios en la configuración del servidor.
* **[config_log](https://github.com/ibarwick/config_log):** Registro de cambios de parámetros en tablas internas.
* **[pg_filedump](https://github.com/df7cb/pg_filedump):** Herramienta de bajo nivel para examinar archivos de datos (forense).
* **[OSSEC](https://github.com/ossec/ossec-hids):** HIDS para monitorear integridad de archivos en el host.

---

## 5. Seguridad Ofensiva y Evaluación (Security Testing)

*Herramientas para encontrar debilidades antes que los atacantes.*

* **[pghostile](https://github.com/Aiven-Open/pghostile):** Automatización de explotación de configuraciones débiles.
* **[PGSpot](https://github.com/timescale/pgspot):** Escaneo estático (linter) para detectar vulnerabilidades en scripts SQL.
* **[ESLint Plugin PostgreSQL](https://github.com/baseballyama/eslint-plugin-postgresql):** Análisis de consultas SQL en código JavaScript.
* **[pg_gather](https://github.com/jobinau/pg_gather):** Recolección de estado de seguridad y roles sin agentes.
* **[PostgreSQL Security Toolkit](https://github.com/sendtoshailesh/postgresql-security-toolkit):** Scripts de auditoría rápida para red y cifrado.
* **[PostgreSQL Penetration Testing Guide](https://github.com/JFR-C/Database-Security-Audit/blob/master/PostgreSQL%20database%20penetration%20testing):** Guía metodológica de Pentesting.

---

## 6. Hardening y Cumplimiento (Compliance as Code)

*Automatización del endurecimiento según estándares internacionales.*

### 🏗️ Automatización e IaC (Ansible/Chef/Puppet)

* **[PostgreSQL STIG Ansible Playbook](https://github.com/dokuhebi/postgresql_stig_ansible_playbook):** Aplicación automática de controles DISA STIG.
* **[Ansible-Lockdown (POSTGRES-12-CIS)](https://github.com/ansible-lockdown/POSTGRES-12-CIS):** Hardening basado en el benchmark CIS.
* **[Chef Postgres Hardening](https://github.com/dev-sec/chef-postgres-hardening) / [Puppet Postgres Hardening](https://github.com/dev-sec/puppet-postgres-hardening):** Módulos de endurecimiento para infraestructura gestionada.
* **[Reference Hardening Script](https://gist.github.com/neverinfamous/a432070ab2e3c31a766fea58dddd0574):** Gist de referencia para configuración TLS y red.

### ✅ Evaluación de Cumplimiento (Assessment)

* **[pgdsat](https://github.com/klouddb/klouddbshield):** Evaluación de +70 controles basados en CIS Benchmark.
* **[klouddbshield](https://github.com/klouddb/klouddbshield):** Escaneo de PII y validación profunda de `pg_hba.conf`.
* **[pgstigcheck-inspec](https://github.com/CrunchyData/pgstigcheck-inspec):** Auditoría InSpec para cumplimiento DISA STIG.
* **[Crunchy Data STIG Baseline](https://github.com/mitre/crunchy-data-postgresql-stig-baseline):** Perfil de InSpec para normativas gubernamentales.
* **[CIS Hardening PostgreSQL 15](https://github.com/sglusnevs/cis-hardening-pgsql-15):** Scripts específicos para la versión 15.
* **[RDS PostgreSQL Hardening Check](https://github.com/jithinkelakam-hue/RDS-PostgresSQL-Hardening-Check):** Auditoría específica para entornos AWS RDS.
* **[Postgres-baseline (InSpec)](https://github.com/dev-sec/postgres-baseline):** Verificación de mejores prácticas "DevSec".
* **[Postgres Baseline (EasyAppSecurity)](https://github.com/EasyAppSecurity/postgres-baseline):** Guía de referencia rápida para entornos productivos.

---

## 7. Hardening del Motor y Sistema Operativo

*Seguridad a nivel de código y Kernel.*

* **[plpgsql_check](https://github.com/okbob/plpgsql_check):** Análisis estático para detectar vulnerabilidades en código PL/pgSQL.
* **[sepgsql](https://www.postgresql.org/docs/current/sepgsql.html):** Control de acceso obligatorio (MAC) mediante SELinux.
* **[edb_block_commands](https://github.com/vibhorkum/edb_block_commands):** Prevención de desastres bloqueando comandos como `DROP` o `TRUNCATE`.
* **SE-PostgreSQL:** Políticas integradas con el Kernel de Linux para seguridad obligatoria.

* **Auditd (Linux Audit Framework):** Sistema de auditoría del kernel para rastrear accesos y modificaciones de archivos críticos (`pg_hba.conf`, `postgresql.conf`). Permite identificar el **AUID** (ID de usuario real) incluso tras una escalada de privilegios con `sudo`.
* **AppArmor (PostgreSQL Profile):** Control de Acceso Obligatorio (MAC) basado en rutas para confinar el proceso de Postgres, limitando su capacidad de lectura/escritura únicamente a directorios autorizados por el perfil.
* **SELinux (Postgres Policy):** Implementación de seguridad de grano fino mediante etiquetas de contexto, asegurando que solo procesos con el tipo `postgresql_t` puedan interactuar con los sockets y archivos de datos.

### ⏱️ Monitoreo de Integridad en Tiempo Real

* **inotify-tools:** Subsistema del kernel para el monitoreo inmediato de eventos en el sistema de archivos (modificaciones, aperturas o borrados de archivos de configuración).
* **incron (inotify cron):** Programador de tareas basado en eventos de archivos que permite disparar scripts de reacción (alertas, rollbacks o backups) al detectarse cambios en el entorno de Postgres.

### 🔍 Evaluación de Configuración y SO

* **Lynis (PostgreSQL Audit Module):** Escáner de seguridad para sistemas Unix que audita la configuración del sistema operativo, permisos de archivos de datos y parámetros de red específicos para nodos de base de datos.
