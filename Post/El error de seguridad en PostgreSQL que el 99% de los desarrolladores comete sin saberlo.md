# El error de seguridad en PostgreSQL que el 99% de los desarrolladores comete sin saberlo al gestionar permisos. 

 
### 1. Escalada de Privilegios y la Trampa de los Roles

El sistema de roles en PostgreSQL es increíblemente flexible, pero esa flexibilidad es un arma de doble filo si no dominas cómo se delegan los permisos.

* **El Peligro de `WITH GRANT OPTION` (y `admin_option`):** * **El problema:** Le das a un usuario permisos sobre una tabla con `WITH GRANT OPTION`, o lo haces miembro de un grupo con `ADMIN OPTION`. Acabas de descentralizar la seguridad. Ese usuario ahora puede otorgar esos mismos accesos a quien él quiera, creando "administradores en la sombra" que escapan del control del DBA principal.
* **La solución:** La delegación de permisos debe estar centralizada en el usuario administrador o en el pipeline de infraestructura (IaC). Nunca delegues la capacidad de dar permisos a usuarios de aplicación o analistas.

### Los cuidados que debes de tener al asignar un miembro a un role
* **La Confusión entre `INHERIT` y `SET ROLE`:**
* **El problema:** Históricamente, si un rol tenía el atributo `INHERIT` (que viene por defecto), heredaba silenciosamente todos los poderes de los grupos a los que pertenecía. Si metías a un usuario en un grupo con permisos de superusuario, se volvía superusuario automáticamente al conectarse.
* **El cambio magistral en PostgreSQL 16:** Como bien señalas, la vista `pg_auth_members` cambió. Antes (versiones <= 15) la herencia era un atributo global del rol. A partir de la versión 16, la herencia y la capacidad de asumir un rol se controlan **por membresía** (`inherit_option` y `set_option`).
* **Por qué es vital:** Ahora puedes decir: "Juan pertenece al grupo `admin_esquema`, pero no hereda los permisos automáticamente (`inherit_option = FALSE`). Si quiere usar esos poderes, tiene que ejecutar explícitamente `SET ROLE admin_esquema` en su sesión (`set_option = TRUE`)". Esto obliga a una escalada de privilegios consciente y auditable, igual que usar `sudo` en Linux.



### 2. Autenticación y el Terror del `pg_hba.conf`

Este archivo es la puerta de entrada a tu base de datos. Un error aquí anula cualquier permiso interno que hayas configurado.

* **El Suicidio de `HOST 0.0.0.0/0 TRUST`:**
* **El problema:** Esto significa "acepta conexiones desde cualquier IP de internet sin pedir contraseña". Es el error #1 por el que miles de bases de datos son secuestradas por ransomware cada año.
* **La solución:** Jamás uses `trust` fuera de un socket local de Unix. En redes, siempre restringe el bloque de IP a la subred de tu VPC y exige `scram-sha-256`.


* **Local Trust vs. Peer/Ident:**
* **El problema:** Dejar `local all all trust` permite que cualquier usuario del sistema operativo (incluso un atacante que vulneró el servidor web) entre a PostgreSQL como superusuario `postgres` sin contraseña.
* **La solución:** Como mencionas, usar `ident` (o su equivalente moderno y más seguro para sockets locales en Linux, `peer`). Esto obliga a que el usuario del sistema operativo coincida exactamente con el usuario de la base de datos, mapeando la seguridad del OS con la de PostgreSQL.



### 3. El Eslabón Perdido: PgBouncer

* **El problema de omitir la seguridad en el Pooler:**
* Muchos equipos configuran PostgreSQL como una fortaleza, pero ponen PgBouncer enfrente para manejar las conexiones y dejan la autenticación de PgBouncer en `auth_type = any` o `trust`, o no configuran su propio archivo `pg_hba.conf` virtual (disponible en versiones recientes de PgBouncer).
* **Por qué es crítico:** PgBouncer se convierte en un proxy que "lava" las conexiones maliciosas. El atacante se autentica sin problemas contra el PgBouncer (que está mal configurado), y luego el PgBouncer, usando sus propias credenciales legítimas, le pasa la conexión a la base de datos. Toda la seguridad de tu motor fue evadida en la capa superior.
* **La solución:** PgBouncer debe replicar estrictamente las reglas de autenticación (`auth_type = scram-sha-256`) y requerir los hashes de contraseñas de los usuarios en su archivo `userlist.txt` o mediante la función de consulta `auth_query` directa a la base de datos.


---

## 1. Errores Implícitos (El Peligro de los Valores por Defecto)

Estos son los errores que cometes al **no especificar nada**. PostgreSQL, por razones históricas de compatibilidad, tiene configuraciones predeterminadas que en un entorno moderno son un riesgo de seguridad inaceptable.

### A. Dejar el esquema `public` abierto a todos

* **El error:** No hacer nada con el esquema `public`. Hasta la versión 14 de PostgreSQL, el rol especial `PUBLIC` (que incluye a todos los usuarios) tiene el permiso `CREATE` en el esquema `public` por defecto.
* **Por qué es un problema:** Cualquier usuario con acceso de solo lectura (como un analista de datos) puede crear tablas o funciones en tu esquema principal. Un atacante podría crear una tabla falsa o una función troyana que, cuando sea ejecutada por un superusuario, escale sus privilegios.
* **La solución (Mejor Práctica):** Revocar este acceso inmediatamente al crear la base de datos.
```sql
REVOKE ALL ON SCHEMA public FROM PUBLIC;

```


*(Nota: A partir de PostgreSQL 15, esto ya viene revocado por defecto, pero debes asegurarte en bases de datos migradas).*

### B. Olvidar que las funciones se pueden ejecutar por `PUBLIC`

* **El error:** Creas una función PL/pgSQL para tareas administrativas y no especificas quién puede ejecutarla.
* **Por qué es un problema:** Por defecto, PostgreSQL otorga el privilegio `EXECUTE` sobre las funciones recién creadas al rol `PUBLIC`. Si tu función interactúa con tablas sensibles o usa `SECURITY DEFINER` (ejecutarse con los privilegios del creador), acabas de dejar una puerta trasera abierta para cualquier usuario de la base de datos.
* **La solución:** Alterar los privilegios por defecto o revocar explícitamente.
```sql
REVOKE EXECUTE ON FUNCTION mi_funcion_sensible() FROM PUBLIC;

```



### C. Confiar ciegamente en `pg_hba.conf` con `trust` o `ident`

* **El error:** Dejar el método de autenticación por defecto (`trust` en conexiones locales o redes internas).
* **Por qué es un problema:** `trust` significa "si lograste llegar al puerto 5432, asumo que eres quien dices ser". No pide contraseña. Si un atacante entra a la red interna o al servidor de aplicaciones, tiene acceso total a la base de datos sin necesidad de credenciales.
* **La solución:** Exigir siempre `scram-sha-256` para conexiones locales y de red.



## 2. Errores Activos (Malas Prácticas al Otorgar Privilegios)

Aquí es donde los administradores y desarrolladores toman decisiones activas para "hacer que las cosas funcionen rápido", sacrificando la seguridad.

### A. Otorgar `SUPERUSER` a aplicaciones o usuarios comunes

* **El error:** Darle permisos de `SUPERUSER` al usuario que usa tu API web o aplicación para conectarse a la base de datos, porque "había errores de permisos y esto lo arregló".
* **Por qué es un problema:** Un `SUPERUSER` ignora todas las verificaciones de permisos. Si tu aplicación sufre una inyección SQL (SQLi), el atacante no solo puede leer tus datos; puede ejecutar comandos en el sistema operativo del servidor subyacente (usando `COPY ... TO PROGRAM`), instalar extensiones maliciosas o borrar la base de datos completa. Nunca, bajo ninguna circunstancia, una aplicación debe ser superusuario.

### B. El abuso de `GRANT ALL PRIVILEGES`

* **El error:** Ejecutar `GRANT ALL PRIVILEGES ON DATABASE mi_bd TO usuario_app;`.
* **Por qué es un problema:** Otorga permisos que el usuario probablemente no necesita (como crear esquemas o funciones temporales). Si el usuario es comprometido, el radio de explosión (blast radius) es masivo.
* **La solución:** Otorgar solo lo estrictamente necesario (DML básico).
```sql
GRANT CONNECT ON DATABASE mi_bd TO usuario_app;
GRANT USAGE ON SCHEMA public TO usuario_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO usuario_app;

```



### C. Asignar permisos a usuarios directamente (Sin usar RBAC)

* **El error:** Ejecutar `GRANT SELECT ON tabla TO juan; GRANT SELECT ON tabla TO maria;`.
* **Por qué es un problema:** Cuando Juan se va de la empresa, es casi imposible rastrear qué permisos tenía para revocarlos limpiamente (el problema de los permisos huérfanos). Además, es inescalable y propenso a errores.
* **La solución:** Usar Control de Acceso Basado en Roles (RBAC). Creas un "Rol de Grupo" (sin permiso de login) y metes a los usuarios ahí.
```sql
-- 1. Crear el grupo y darle permisos
CREATE ROLE grupo_lectura NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grupo_lectura;

-- 2. Crear al usuario y meterlo al grupo
CREATE ROLE juan LOGIN PASSWORD 'Fuerte123';
GRANT grupo_lectura TO juan;

```



### D. Ignorar el `ALTER DEFAULT PRIVILEGES`

* **El error:** Le das permisos de lectura a un usuario sobre todas las tablas de un esquema. Mañana creas una nueva tabla. El usuario de repente ya no tiene acceso a esa nueva tabla y la aplicación falla.
* **Por qué es un problema:** Para "arreglarlo", los administradores a menudo terminan corriendo scripts diarios que hacen `GRANT ALL` o, peor aún, deciden darle `SUPERUSER` a la aplicación para dejar de lidiar con el problema.
* **La solución:** Especificar qué pasará con los objetos creados *en el futuro*.
```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO grupo_lectura;

```





### Resumen de la Arquitectura Segura

Para diseñar un entorno PostgreSQL a prueba de balas, debes interiorizar esta filosofía: **Todo está prohibido a menos que se autorice explícitamente.** 1.  Usa siempre roles de grupo (RBAC).
2.  Desactiva o revoca los permisos de `PUBLIC` en esquemas y funciones clave.
3.  Usa políticas de seguridad a nivel de filas (RLS - Row Level Security) si tienes entornos multi-inquilino (multi-tenant).
4.  Cifra las contraseñas con SCRAM-SHA-256, nunca MD5.







## 1. Principios de seguridad en Bases de Datos

Estos principios son la filosofía que debes aplicar *antes* de teclear cualquier comando en la terminal.

* **Principio de Privilegio Mínimo (PoLP):** Ningún usuario, aplicación o microservicio debe tener más permisos de los estrictamente necesarios para cumplir su función. Si una aplicación solo lee reportes, no debe tener permisos de `UPDATE` o `DELETE`, y absolutamente nunca debe ser `SUPERUSER`.
* **Confianza Cero (Zero Trust):** Nunca asumas que una conexión es segura solo porque proviene de tu propia red interna o de localhost. En PostgreSQL, esto significa no confiar en las IPs a ciegas y exigir siempre autenticación fuerte (contraseñas o certificados).
* **Seguridad por Defecto (Secure by Default):** Los sistemas deben ser seguros desde el momento en que se encienden, sin necesidad de configuración adicional. Como PostgreSQL históricamente no fue diseñado así (debido a los permisos abiertos a `PUBLIC`), es tu responsabilidad como arquitecto "cerrar" el motor apenas se instala.
* **Defensa en Profundidad (Defense in Depth):** No dependas de una sola capa de seguridad. Si el backend de tu aplicación falla en validar a un usuario, la base de datos debe tener sus propias barreras (como Seguridad a Nivel de Filas - RLS) para detener el ataque.
* **Trazabilidad y Responsabilidad:** Debes poder auditar de forma inequívoca quién hizo qué. Las cuentas compartidas destruyen este principio.

**La Regla de Oro antes de ejecutar cualquier script:**

* **Entiende:** Si no puedes explicar qué hace exactamente cada instrucción SQL, no la ejecutes.
* **Mide el Impacto:** Analiza el "radio de explosión". Pregúntate qué otros sistemas o datos colapsarán si el comando falla, bloquea una tabla o borra de más.
* **Asegura el Código:** Asume que al código de internet siempre le faltan capas de seguridad. Tu trabajo es adaptarlo aplicando el Principio de Menor Privilegio.
* **Prueba Siempre:** El código ajeno es un borrador. Valídalo siempre en un entorno de pruebas (*staging*) antes de siquiera acercarlo a producción.


```
    admin_option: Tiene permiso para decidir quién más entra en este grupo
    inherit_option:  Si es TRUE, el usuario tiene automáticamente todos los permisos del grupo
    set_option: Tiene permiso para  cambiar mi identidad a este rol si lo necesito
    pg_auth_members : En la versión <= 15 solo tiene admin_option, 
    de la versión >= 16 ya se integro las columnas inherit_option y set_option
```
