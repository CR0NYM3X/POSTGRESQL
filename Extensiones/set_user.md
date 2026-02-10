# set_user

Esta es una de las herramientas más potentes para la seguridad en PostgreSQL. Como experto, te explico que `set_user` es una extensión diseñada para manejar la **escalada de privilegios controlada y auditada**.

En un entorno estándar, si un usuario necesita permisos de superusuario, se le tiene que dar el rol `superuser`, lo cual es un riesgo porque ese usuario puede hacer lo que quiera sin dejar rastro claro de quién hizo qué. `set_user` resuelve esto.

### ¿Para qué sirve?

Permite que un usuario cambie su identidad a otro rol (incluso a superusuario) pero con tres condiciones críticas que no tiene el comando `SET ROLE` estándar:

1. **Auditoría Total:** Todo lo que haga el usuario mientras está "disfrazado" queda marcado en los logs con un tag (por defecto `[AUDIT]`).
2. **Restricciones de Seguridad:** Puedes bloquear comandos peligrosos como `ALTER SYSTEM` o `COPY PROGRAM` incluso si el usuario escaló a superusuario.
3. **Control de Retorno:** Puedes obligar al usuario a usar un "token" (contraseña temporal) para poder regresar a su identidad original.

---

### Casos de Uso Reales

#### 1. Mantenimiento por DBA con cuenta personal

En lugar de que todos los DBAs compartan la contraseña del usuario `postgres`, cada uno entra con su propio usuario (ej. `juan_dba`). Cuando necesitan hacer algo crítico:

* **Caso:** Juan necesita crear una extensión que requiere superusuario.
* **Acción:** Ejecuta `SELECT set_user('postgres');`.
* **Resultado:** Juan hace el mantenimiento, pero en los logs de Red Hat/PostgreSQL aparecerá exactamente que fue `juan_dba` quien activó el modo superusuario y qué comandos ejecutó.

#### 2. Prevención de "Puertas Traseras"

* **Caso:** Quieres evitar que alguien use `COPY PROGRAM` para ejecutar comandos a nivel de sistema operativo (RHEL) desde la base de datos.
* **Acción:** Configuras `set_user.block_copy_program = on`.
* **Resultado:** Aunque el usuario escale a superusuario mediante `set_user`, la extensión le impedirá tocar el sistema operativo.

---

### Ejemplo Práctico de cómo se usa

Imagina que tienes un usuario llamado `soporte_tecnico` que no tiene permisos de superusuario, pero a veces necesita arreglar tablas de sistema.

**1. Configuración (en postgresql.conf):**

```ini
shared_preload_libraries = 'set_user'
set_user.superuser_allowlist = 'soporte_tecnico'

```

**2. El usuario entra a la base de datos y escala:**

```sql
-- El usuario 'soporte_tecnico' quiere ser superusuario temporalmente
SELECT set_user('postgres', 'mi_token_secreto');

-- Ahora puede hacer tareas de mantenimiento...
-- Todo lo que escriba aquí se guardará en el log con el tag AUDIT.

-- Cuando termina, regresa a su usuario normal usando el token
SELECT reset_user('mi_token_secreto');

```

### ¿Por qué usar esto y no `SET ROLE`?

El comando `SET ROLE` de PostgreSQL es "silencioso". Si un usuario tiene permiso de `SET ROLE`, puede cambiar de identidad y en los logs los comandos parecerán ejecutados por el nuevo rol, perdiendo la trazabilidad de quién fue el autor original. `set_user` **rompe ese anonimato**, lo cual es vital para certificaciones de seguridad como PCI-DSS o SOC2.


# Tocken 

El token no es una contraseña que esté guardada en la base de datos; es una **cadena de texto que tú inventas en el momento** para "bloquear" tu sesión actual.

Aquí te explico las dos razones principales de por qué un experto lo usaría:

### 1. Evitar que una aplicación "se quede" como superusuario

Imagina que tienes un script o una aplicación que usa `set_user` para hacer una tarea administrativa rápida.

* Si el script tiene un error y se detiene a la mitad, podría dejar la conexión abierta con permisos de superusuario (`postgres`).
* Al usar un **token**, obligas a que la aplicación solo pueda volver a ser un usuario normal si conoce la "llave" que ella misma inventó al principio. Es un seguro de vida para que nadie más use esa conexión que quedó "escalada".

### 2. Protección en consolas compartidas (Prevención de Secuestro de Sesión)

Si estás trabajando en una terminal y te levantas de tu lugar, o si alguien más tiene acceso a tu sesión de base de datos:

* **Sin token:** Alguien podría simplemente ejecutar `SELECT reset_user();` y volver a tu usuario original, o peor aún, si la sesión se quedó en `postgres`, usarla libremente.
* **Con token:** Para ejecutar `reset_user()`, la extensión te va a exigir el token exacto que usaste al entrar. Si no lo tienes, **te quedas atrapado** en el rol actual o no puedes revertir el cambio.

 
### Ejemplo de la diferencia:

**Escenario A (Sin Token - Inseguro):**

1. Tú: `SELECT set_user('postgres');` (Ahora eres Dios en la DB).
2. Un proceso malicioso o un error: `SELECT reset_user();` (Regresa a tu usuario pero habiendo dejado cambios sin que te des cuenta).

**Escenario B (Con Token - Seguro):**

1. Tú: `SELECT set_user('postgres', 'XyZ_123');`
2. Si alguien intenta salir del modo superusuario con un simple `SELECT reset_user();`, PostgreSQL lanzará un **ERROR** diciendo: *"Para resetear el usuario, debes proveer el token correcto"*.

> **En resumen:** El token sirve para asegurar que **la misma persona (o proceso) que subió de nivel, sea la única que pueda bajar de nivel.** Es como una pulsera de seguridad en un club: solo sales si traes la pulsera que te pusieron al entrar.
 

# Links
```
https://github.com/pgaudit/set_user
```
