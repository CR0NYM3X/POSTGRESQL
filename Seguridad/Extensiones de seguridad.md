
 
### 1. Validación de Repositorios (Enfoque Seguridad)

* **[dev-sec/chef-postgres-hardening](https://github.com/dev-sec/chef-postgres-hardening)**
* **¿Para qué sirve?** Es un libro de recetas (cookbook) de Chef diseñado para endurecer (*hardening*) automáticamente la configuración de PostgreSQL. Aplica configuraciones seguras en el `postgresql.conf` y `pg_hba.conf` siguiendo estándares de la industria.


* **[dev-sec/puppet-postgres-hardening](https://github.com/dev-sec/puppet-postgres-hardening)**
* **¿Para qué sirve?** Similar al anterior, pero para Puppet. Automatiza el despliegue de políticas de seguridad, asegurando que los privilegios de archivos y las configuraciones de red de la base de datos no sean vulnerables.


* **[dev-sec/postgres-baseline](https://github.com/dev-sec/postgres-baseline)**
* **¿Para qué sirve?** Es un perfil de **InSpec**. Sirve para *auditar* (no configurar) si tu instancia de PostgreSQL cumple con las mejores prácticas de seguridad. Es ideal para procesos de Compliance (cumplimiento).


* **[ansible-lockdown/POSTGRES-12-CIS](https://github.com/ansible-lockdown/POSTGRES-12-CIS)**
* **¿Para qué sirve?** Un rol de Ansible que aplica el **Benchmark del CIS (Center for Internet Security)** para Postgres 12. Es de lo más robusto que hay para llevar una base de datos a un nivel de seguridad empresarial/gubernamental.

* **[ibarwick/config_log](https://github.com/ibarwick/config_log)**
* **¿Para qué sirve?** Una extensión que permite rastrear cambios en la configuración de la base de datos a través de tablas. Es una herramienta de **auditoría de integridad**: si alguien cambia un parámetro crítico de seguridad, queda registrado.


* **[gist.github.com/neverinfamous/...](https://www.google.com/search?q=https://github.com/neverinfamous/a432070ab2e3c31a766fea58dddd0574)**
* **¿Para qué sirve?** Es un script/guía rápida de **Hardening**. Contiene configuraciones específicas para `pg_hba.conf` y parámetros de cifrado SSL/TLS. Es útil como referencia rápida.



# Links
```

PostgreSQL database penetration testing -> https://github.com/JFR-C/Database-Security-Audit/blob/master/PostgreSQL%20database%20penetration%20testing

pghostile -> herramienta de seguridad y auditoría diseñada para automatizar la explotación de vulnerabilidades específicas en PostgreSQL que pueden permitir la escalada de privilegios. https://github.com/Aiven-Open/pghostile

pgdsat ->  herramienta más específica y potente hoy en día. Evalúa más de 70 controles de seguridad, incluyendo recomendaciones de CIS Benchmark. Genera informes detallados en HTML sobre permisos de archivos, usuarios con privilegios elevados y configuraciones críticas. https://github.com/klouddb/klouddbshield

klouddbshield ->  Además de los benchmarks de CIS, incluye un escáner de PII (Información de Identificación Personal) para detectar datos sensibles expuestos, auditoría de SSL y escaneo de archivos pg_hba.conf. https://github.com/klouddb/klouddbshield 
pg_gather -> se usa mucho para performance, es excelente para seguridad porque no requiere instalar binarios en el servidor (es solo SQL). Recopila información de roles, privilegios y estados del clúster que puedes auditar externamente. https://github.com/jobinau/pg_gather 

pgaudit -> https://github.com/pgsty/pigsty

postgres-baseline -> https://github.com/dev-sec/postgres-baseline

HashiCorp Vault: Herramienta para la gestión segura de secretos (credenciales, claves API) e integración con PostgreSQL para credenciales dinámicas
```
