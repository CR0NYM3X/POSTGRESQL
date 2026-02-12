# El fantasma de los permisos y auditores (INHERIT y SET ROLE):  ¿Por qué tus usuarios tienen permisos que no deberían (o al revés)?


## **¿Qué significa "Herencia" en Postgres?**
Muchos se confunden: ¿Es otorgar o recibir? Es **recibir**. Cuando un rol "Hereda" de otro, está absorbiendo los poderes del rol superior. El padre otorga, el hijo recibe. Así de simple.


### 1. Funcionamiento de PostgreSQL

En el ecosistema de PostgreSQL, la seguridad se gestiona mediante **Roles**. Olvídate de la distinción rígida entre "Usuarios" y "Grupos" de otros motores; aquí, un Rol es un camaleón que puede ser ambos.  no hay diferencia técnica real entre un "usuario" y un "grupo"; ambos son **Roles**. La única diferencia es que un rol con `LOGIN` se suele llamar usuario y con NOLOGIN es un rol o grupo.

La **Herencia** es el mecanismo mediante el cual un rol adquiere los privilegios de otro de forma automática. Es una funcionalidad core, Open Source (Licencia PostgreSQL), diseñada para escalar la gestión de permisos en infraestructuras complejas sin morir en el intento de dar `GRANT` uno por uno.


###   ¿Analogía de del tio rico?

Imagina que tu tío rico, el **"Rol de Lectura"**, tiene una mansión con piscina (acceso a las tablas de producción). Él te invita a ser parte de su familia.

En el mundo real, si heredas, las llaves de la mansión te llegan por correo y entras cuando quieras (**`INHERIT`**). Pero a veces, tu tío es desconfiado y te dice: "Eres de la familia, pero si quieres entrar a la piscina, tienes que llamarme y pedirme permiso cada vez que vayas a entrar" (**`NOINHERIT`** o **`SET ROLE`**).


 
### 3. El "Deep Dive": Lo bueno, lo malo y lo feo

* **Ventajas (Power-ups):** La herencia permite una administración limpia. Si tienes 500 analistas, no les das permisos a los 500; creas un rol `analista`, le das permisos a él, y haces que los 500 hereden de él. ¡Magia!
* **Casos de uso reales:** Úsalo siempre para roles de lectura (`read_only`) o roles de aplicación. Evítalo (o úsalo con `SET ROLE`) para roles de mantenimiento o superusuario, donde quieres que el humano sea consciente de que está a punto de ejecutar un comando peligroso.
* **Consideraciones de experto:** Con la llegada de **Postgres 16**, el control se volvió quirúrgico. Ahora puedes ser miembro de un grupo pero tener prohibido heredar sus permisos automáticamente (`WITH INHERIT FALSE`), obligándote a "pedir el cambio de sombrero" explícitamente.



### 5. La Verdad Desnuda (Lo que nadie te cuenta)

* **El "Gotcha" del Performance:** Si tienes una cadena de herencia de 15 niveles (un rol que hereda de otro, que hereda de otro...), Postgres tiene que resolver ese árbol cada vez que verificas un permiso. No suele matar el servidor, pero es un diseño sucio que complica la auditoría.
* **La mentira del `SET ROLE`:** Cuando haces `SET ROLE`, pierdes temporalmente tus permisos originales. Eres el grupo o eres tú, pero no ambos al mismo tiempo (a menos que uses una jerarquía bien diseñada).
* **El peligro del DEFAULT:** Por defecto, los roles son `INHERIT`. Si no tienes cuidado, alguien podría terminar con permisos de `DROP TABLE` solo porque un DBA distraído lo metió en un grupo equivocado.


#### "Bajo el Capó": La magia de la versión 16

Antes de Postgres 16, esto era como un interruptor de luz: encendido o apagado. Ahora, es como una consola de mezcla de DJ.

* **`INHERIT`**: Es el ADN. Si tu ADN dice que eres alto, lo eres y ya. Los permisos fluyen hacia ti automáticamente.
* **`SET`**: Es la ropa. Puedes "vestirte" como el otro rol si lo necesitas usando el comando `SET ROLE`.
* **`ADMIN`**: Es el derecho a dar el apellido. Puedes invitar a otros a la familia.

 
### 🎭 Las Dos Caras de la Moneda

**Ventajas:**

* **Orden Mental:** No tienes que darle permisos a 100 usuarios uno por uno. Se los das al "Grupo" y listo.
* **Seguridad Granular:** Con las novedades de PG16, puedes ser tan específico como un cirujano.
* **Auditoría Limpia:** Es fácil saber quién tiene permiso de qué mirando el árbol genealógico.

**Lo que nadie te cuenta (Desafíos):**

* **La Trampa del `NOINHERIT`:** Si creas un rol con `NOINHERIT`, los permisos de los objetos que ese rol **cree** no serán accesibles fácilmente por sus "padres" sin configurar `DEFAULT PRIVILEGES`.
* **Rendimiento en Jerarquías Gigantes:** Si tienes 10 niveles de herencia (roles que heredan de roles que heredan de roles...), Postgres tiene que trabajar extra para calcular si puedes ver esa tabla de `ventas`. No abuses del árbol genealógico.
* **Confusión de Identidad:** Al hacer `SET ROLE`, tu usuario "deja de ser él mismo" para los ojos de algunas funciones de sesión, lo que puede arruinar tus logs de auditoría si no sabes lo que haces.

### 3. Verificación de las Pruebas

| Usuario | ¿Hereda Directo? | ¿Puede hacer `SET ROLE`? | Explicación |
| --- | --- | --- | --- |
| **user_hereda** | **SÍ** | SÍ | Es el comportamiento estándar. |
| **user_no_hereda** | **NO** | SÍ | Su atributo `NOINHERIT` lo obliga a usar `SET ROLE`. |
| **user_restringido** | **NO** | **SÍ** | El `GRANT` específico sobreescribe su capacidad de heredar. |
| **user_bloqueado** | **NO** | **NO** | Está unido al grupo, pero no puede usar sus privilegios de ninguna forma. |


#### A. Atributos del Rol (`INHERIT` vs `NOINHERIT`)

Este atributo se define al crear el rol. Determina si el rol, **por defecto**, heredará los permisos de los roles a los que sea asignado.

* **`INHERIT` (Default):** El usuario adquiere automáticamente los permisos de sus grupos.
* **`NOINHERIT`:** El usuario **no** adquiere permisos automáticamente; debe usar `SET ROLE` para "convertirse" en el grupo y usar sus permisos.

#### B. Atributos del GRANT (`WITH INHERIT`, `WITH SET`, `WITH ADMIN`)

A partir de PostgreSQL 16, el comando `GRANT` se volvió mucho más granular:

* **`INHERIT TRUE/FALSE`:** Controla si esta membresía específica permite heredar permisos.
* **`SET TRUE/FALSE`:** Controla si el usuario puede "suplantar" al rol mediante `SET ROLE`.
* **`ADMIN TRUE/FALSE`:** Controla si el usuario puede otorgar este rol a otros.



### 4. Explicación de los Metadatos (`pg_auth_members`)

Tu consulta a las tablas de sistema es correcta para auditar. Aquí te explico qué significa cada columna en la tabla `pg_auth_members`:

* **`inherit_option`**: Si es `t` (true), los permisos fluyen hacia el miembro. Si es `f`, el miembro está "sordo" a los permisos del grupo a menos que use `SET ROLE`.
* **`set_option`**: Si es `t`, el usuario puede usar `SET ROLE grupo`. Si es `f`, el usuario es miembro del grupo (útil para auditoría) pero no puede actuar como él.

 

### 5. ¿Por qué existe `INHERIT FALSE` y `SET FALSE`?

1. **Seguridad (Principio de Menor Privilegio):** Puedes querer que un usuario pertenezca a un grupo "Admin" para que aparezca en los reportes, pero no quieres que herede esos permisos peligrosos por accidente mientras navega. Quieres que el usuario diga explícitamente: "Ahora quiero actuar como Admin" (`SET ROLE`).
2. **Jerarquías complejas:** `SET FALSE` sirve para crear membresías puramente informativas o para revocar temporalmente la capacidad de un usuario de escalar privilegios sin quitarle la membresía.

# Laboratorio 

```SQL

### Paso 1: Crear la base de datos y las tablas
Primero, creamos una base de datos y una tabla simple para nuestros ejemplos:

CREATE DATABASE ejemplo_inherit;
\c ejemplo_inherit

CREATE TABLE datos (
    id SERIAL PRIMARY KEY,
    info TEXT
);

INSERT INTO datos (info) VALUES ('Registro 1'), ('Registro 2'), ('Registro 3');


### Paso 2: Crear roles y usuarios
Creamos varios roles y usuarios con diferentes configuraciones de `INHERIT`:

-- Crear roles
CREATE ROLE rol_inherit INHERIT;
CREATE ROLE rol_noinherit NOINHERIT;
CREATE ROLE rol_inherit_false;
CREATE ROLE rol_set_true;
CREATE ROLE rol_set_false;

-- Crear usuarios
CREATE ROLE usuario_inherit LOGIN INHERIT;
CREATE ROLE usuario_noinherit LOGIN NOINHERIT;
CREATE ROLE usuario_inherit_false LOGIN NOINHERIT;
CREATE ROLE usuario_set_true LOGIN NOINHERIT;
CREATE ROLE usuario_set_false LOGIN NOINHERIT;


### Paso 3: Otorgar permisos y roles
Otorgamos permisos y roles a los usuarios con diferentes configuraciones:

-- Otorgar permisos a los roles
GRANT SELECT ON datos TO rol_inherit;
GRANT SELECT ON datos TO rol_noinherit;
GRANT SELECT ON datos TO rol_inherit_false;
GRANT SELECT ON datos TO rol_set_true;
GRANT SELECT ON datos TO rol_set_false;

-- Otorgar roles a los usuarios
GRANT rol_inherit TO usuario_inherit;
GRANT rol_noinherit TO usuario_noinherit;
GRANT rol_inherit_false TO usuario_inherit_false WITH INHERIT FALSE;
GRANT rol_set_true TO usuario_set_true WITH INHERIT FALSE SET TRUE;
GRANT rol_set_false TO usuario_set_false WITH INHERIT FALSE SET FALSE;


### Paso 4: Verificar los privilegios
Ahora verificamos cómo afectan estas configuraciones a los privilegios de los usuarios.

#### Usuario con `INHERIT`

\c - usuario_inherit
SELECT * FROM datos;  -- Debería funcionar porque hereda los privilegios de rol_inherit


#### Usuario con `NOINHERIT`

\c - usuario_noinherit
SELECT * FROM datos;  -- No debería funcionar porque no hereda los privilegios de rol_noinherit


#### Usuario con `WITH INHERIT FALSE`

\c - usuario_inherit_false
SELECT * FROM datos;  -- No debería funcionar porque no hereda los privilegios de rol_inherit_false


#### Usuario con `WITH INHERIT FALSE SET TRUE`

\c - usuario_set_true
SELECT * FROM datos;  -- No debería funcionar porque no hereda los privilegios de rol_set_true

SET ROLE rol_set_true;
SELECT * FROM datos;  -- Debería funcionar porque ahora tiene los privilegios de rol_set_true


#### Usuario con `WITH INHERIT FALSE SET FALSE`

\c - usuario_set_false
SELECT * FROM datos;  -- No debería funcionar porque no hereda los privilegios de rol_set_false

SET ROLE rol_set_false;
SELECT * FROM datos;  -- No debería funcionar porque no puede usar SET ROLE para adquirir los privilegios de rol_set_false


### Resumen
- **usuario_inherit**: Hereda automáticamente los privilegios de `rol_inherit`.
- **usuario_noinherit**: No hereda automáticamente los privilegios de `rol_noinherit`.
- **usuario_inherit_false**: No hereda automáticamente los privilegios de `rol_inherit_false`.
- **usuario_set_true**: No hereda automáticamente los privilegios de `rol_set_true`, pero puede usar `SET ROLE` para adquirirlos.
- **usuario_set_false**: No hereda automáticamente los privilegios de `rol_set_false` y no puede usar `SET ROLE` para adquirirlos.




SELECT 
    r.rolname AS role_name,
    m.member AS member_oid,
    u.rolname AS member_name,
    m.admin_option,
    m.inherit_option,
    m.set_option
FROM 
    pg_auth_members m
JOIN 
    pg_roles r ON m.roleid = r.oid
JOIN 
    pg_roles u ON m.member = u.oid;
	


- **admin_option**: Le otorga el permiso al miembro poder hacer grant o revoke sobre el rol.
- **inherit_option**: Indica si el miembro hereda automáticamente los privilegios del rol.
- **set_option**: Indica si el miembro puede usar `SET ROLE` para adquirir los privilegios del rol .

SELECT rolname, rolinherit FROM pg_roles WHERE rolname = 'postgres'; 


```

# Links 
```
1. PostgreSQL Docs: Role Membership - https://www.postgresql.org/docs/current/role-membership.html
2. PostgreSQL 16 Release Notes: Security Improvements - https://www.postgresql.org/docs/16/release-16.html
3. The "Grant" Command Reference - https://www.postgresql.org/docs/current/sql-grant.html
.  Diferencia entre atributos de rol y membresías. - https://www.postgresql.org/docs/current/user-manag.html

```
