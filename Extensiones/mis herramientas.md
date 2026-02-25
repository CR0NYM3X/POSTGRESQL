
# Script Terminados 


[pg_hash_generate](https://github.com/CR0NYM3X/pg_hash_generate) : Verifica y Genera hashes SCRAM-SHA-256 y MD5  compatibles con el motor de autenticación de PostgreSQL mediante pgcrypto.

[pg_auto_hardening](https://github.com/CR0NYM3X/pg_auto_hardening) : Funcion anonima para hardenizar el servidor de manera automatica modificando el postgresql.conf .

[pgAuditSimple](https://github.com/CR0NYM3X/pgAuditSimple): Te permite hacer auditorias DML y DDL  de forma rapida y sencilla con una línea.

[pgTLSCheck](https://github.com/CR0NYM3X/pgTLSCheck) :  Bash diseñada para realizar pentesting específico sobre la capa TLS/SSL de servidores PostgreSQL. Perfecta para administradores, auditores de seguridad, equipos DevSecOps y profesionales que buscan reforzar la postura criptográfica de su infraestructura de datos. Permite detectar configuraciones inseguras, cipher suites vulnerables, conexiones cifradas


[pgTLSinfo](https://github.com/CR0NYM3X/pgTLSinfo) :  función de PostgreSQL diseñada para inspeccionar certificados X.509 y servidores PostgreSQL con SSL/TLS habilitado, obteniendo información técnica completa del entorno de seguridad y conexión.


[pg_tcpcheck](https://github.com/CR0NYM3X/pg_tcpcheck) :  funcion  de diagnóstico de red diseñada para ejecutarse directamente desde PostgreSQL. Permite verificar la disponibilidad de servicios TCP (puertos) en servidores remotos de forma masiva, segura y eficiente.

[pg_auto_revoke_exec](https://github.com/CR0NYM3X/pg_auto_revoke_exec) :  Función y trigger de seguridad para PostgreSQL que supervisa la creación de funciones y procedimientos, revocando automáticamente el permiso EXECUTE del rol PUBLIC si está presente en la funcion. Esto refuerza la protección contra accesos no autorizados en entornos multiusuario o productivos.



[pg_stat_monitor](https://github.com/CR0NYM3X/pg_stat_monitor) : función avanzada para PostgreSQL que fusiona estadísticas internas de sesión (pg_stat_activity) con métricas de procesos extraídas directamente del sistema operativo. Permite visualizar en tiempo real el uso de recursos y comportamiento de cada proceso backend del servidor.


[pg_logify](https://github.com/CR0NYM3X/pg_logify) : es una función (framework) para PostgreSQL que sirve para mejorar el sistema de logs y auditoría en funciones PL/pgSQL.  imprimir mensajes en sistemas que soporten colores ANSI. Guarda los mensajes automáticamente tanto en una tabla o archivo externo del sistema.


[pg_pie](https://github.com/CR0NYM3X/pg_pie) :  función de PostgreSQL que permite "dibujar" gráficos circulares y medidores de porcentaje directamente en tu terminal usando psql.

[pg_progress](https://github.com/CR0NYM3X/pg_progress) :  funcion ligera para PostgreSQL escrita en PL/pgSQL que permite renderizar barras de progreso dinámicas, coloridas y personalizables directamente en la consola de psql

[pg_logSearcher](https://github.com/CR0NYM3X/pg_logSearcher) :  Bash que te permite buscar actividad de un usuario en un log compreso de postgresql con una estructura especifica. 


# Scripts en DESARROLLO
```
pg_background_mgr  -> https://github.com/CR0NYM3X/pg_background_mgr

pg_dblinkv2        ->
  Tabla donde guardara -  usuario y contraseña cifrado
  Tabla donde guardara - ip_servidor , port y base de datos
  Tabla donde guardara la query y la forma de que se ejecuta, configuraciones  (fetch limite row o all)  , exec o consulta
en el dblink ejecutaras el id de usuarios y contraseña , id del servidor, id de la query 

pg_setting_visual -> plataforma que te permitirá aprender para que sirve cada parámetro, te mostrará sus dependencias con otros parametros con efecto desbanecido con los que no son dependientes, los clasificará (Seguridad, optimiazacion, rendimiento, escritura, lectura, disco, replicas) , Te dirá los paraemtros que dependen de configuraciones del S.O , Te dará una descripción corta , te dirá casos de usos, cuando usarlo, ventajas y desventajas Y recomendaciones

pg_architecture_game ->  Algo que nos permita estudiar la arquitectura de PostgreSQL de forma de juego te enseña las cosas mas importantes.

pg_appkiller       -> https://github.com/CR0NYM3X/pg_appkiller
pg_privileges      -> https://github.com/CR0NYM3X/pg_privileges
pg_prttb           -> https://github.com/CR0NYM3X/pg_prttb

pg_partition_logic -> https://github.com/CR0NYM3X/pg_partition_logic

pgVaultLog         -> https://github.com/CR0NYM3X/pgVaultLog
SQLMeta-Tracker    -> https://github.com/CR0NYM3X/SQLMeta-Tracker
```
