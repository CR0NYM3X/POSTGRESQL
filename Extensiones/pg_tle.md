
# pg_tle 
**pg_tle** (*Trusted Language Extensions*).

Para ponerte en contexto: tradicionalmente, si querías extender PostgreSQL con C, necesitabas acceso al sistema de archivos del servidor, lo cual es un riesgo de seguridad y un dolor de cabeza en entornos administrados (como AWS RDS o Google Cloud SQL). **pg_tle** te permite escribir extensiones utilizando lenguajes seguros (como SQL o PL/pgSQL) y cargarlas directamente a través de la API de la base de datos.

---

## Caso de Uso: El Validador de Complejidad de Passwords

Imagina que tienes una aplicación SaaS. Quieres forzar a que todos los usuarios guarden contraseñas que no solo tengan cierta longitud, sino que no contengan el nombre del usuario y que cumplan con un patrón específico.

Vamos a crear una extensión llamada `password_check_tle` que registre un **hook** (un gancho) en el motor de PostgreSQL para validar contraseñas cada vez que alguien intente cambiarlas.

### 1. Requisitos previos

Primero, asegúrate de tener la extensión instalada y disponible en tu `shared_preload_libraries`. Si estás en un entorno local de pruebas:

```sql
CREATE EXTENSION pg_tle;

```

---

### 2. Desarrollo de la Extensión (El Código)

Usaremos la función `pg_tle.install_extension` para registrar nuestro código. Fíjate cómo definimos la lógica en PL/pgSQL.

```sql
SELECT pg_tle.install_extension(
  'password_check_tle', -- Nombre de la extensión
  '1.0.0',              -- Versión
  'Validación de complejidad de passwords', -- Descripción
  $_pg_tle_$
    -- Esta función será nuestro "hook"
    CREATE FUNCTION check_password_complexity(username text, password text, password_type pgtle.password_types, valid_until timestamptz, valid_now boolean)
    RETURNS void AS $$
    BEGIN
        -- Regla 1: Mínimo 10 caracteres
        IF length(password) < 10 THEN
            RAISE EXCEPTION 'La contraseña es muy corta. Mínimo 10 caracteres.';
        END IF;

        -- Regla 2: No puede contener el nombre de usuario
        IF password ~* username THEN
            RAISE EXCEPTION 'La contraseña no puede contener el nombre de usuario.';
        END IF;

        -- Regla 3: Debe contener al menos un número y un carácter especial
        IF NOT (password ~ '[0-9]' AND password ~ '[!@#$%^&*()]') THEN
            RAISE EXCEPTION 'La contraseña debe incluir al menos un número y un carácter especial.';
        END IF;
    END;
    $$ LANGUAGE plpgsql;

    -- Registramos la función como un hook de verificación de passwords
    SELECT pgtle.register_feature('check_password_complexity', 'passcheck');
  $_pg_tle_$
);

```

---

### 3. Instalación en la base de datos

Una vez que el paquete de la extensión está "instalado" en el catálogo de `pg_tle`, debes activarlo en tu base de datos actual:

```sql
CREATE EXTENSION password_check_tle;

```

---

### 4. La Prueba de Fuego (Testing)

Ahora vamos a intentar crear usuarios que rompan nuestras reglas para ver si la extensión realmente "muerde".

| Intento | Comando SQL | Resultado Esperado |
| --- | --- | --- |
| **Pass corta** | `CREATE ROLE u1 PASSWORD '123';` | **Error:** La contraseña es muy corta. |
| **Contiene usuario** | `CREATE ROLE u2 PASSWORD 'usuario_u2_2024!';` | **Error:** No puede contener el nombre de usuario. |
| **Sin especiales** | `CREATE ROLE u3 PASSWORD 'PasswordSegura123';` | **Error:** Debe incluir número y carácter especial. |
| **Correcta** | `CREATE ROLE u4 PASSWORD 'Estructura#2026';` | **ÉXITO:** Role created. |

**Ejecuta esto para probarlo tú mismo:**

```sql
-- Esto debería fallar
ALTER ROLE postgres WITH PASSWORD '123'; 

```

---

## ¿Por qué es esto genial?

1. **Seguridad:** Si tu código tiene un error infinito o intenta acceder a memoria prohibida, el motor lo detiene porque corre en un lenguaje seguro (PL/pgSQL), a diferencia de una extensión en C que podría tumbar el servidor (`segfault`).
2. **Portabilidad:** Puedes exportar este script y correrlo en cualquier nube que soporte `pg_tle` sin pedirle permiso al administrador del sistema para subir archivos `.so` o `.dll`.


---


 
## 1. ¿Qué es un "Hook"?

En programación, un **Hook** (gancho) es un punto específico en el código fuente de un software donde se permite "colgar" código externo para modificar el comportamiento estándar.

Imagina que el proceso de crear un usuario en PostgreSQL es una línea de ensamblaje en una fábrica:

1. El motor recibe el comando `CREATE ROLE`.
2. El motor verifica permisos.
3. **[Aquí está el Hook de Password]**: El motor se detiene y pregunta: *"¿Hay alguna función externa que quiera revisar esta contraseña antes de que yo la guarde?"*
4. Si hay una, se ejecuta. Si la función lanza un error, la fábrica se detiene y cancela todo.

Normalmente, para usar estos hooks, tendrías que programar en C y compilar. **`pg_tle`** actúa como un "traductor" que permite que PostgreSQL use funciones de PL/pgSQL en esos puntos críticos.
 

## 2. ¿Cómo sabe PostgreSQL qué función usar?

Aquí es donde entra el comando que usamos en el ejemplo anterior:

```sql
SELECT pgtle.register_feature('check_password_complexity', 'passcheck');

```

* **`'check_password_complexity'`**: Es el nombre de la función que tú escribiste.
* **`'passcheck'`**: Este es un **identificador de característica** (feature ID) predefinido por `pg_tle`.

Al registrarla bajo el nombre `passcheck`, `pg_tle` le dice al núcleo de PostgreSQL: *"Oye, cada vez que llegues al hook de revisión de contraseñas, ejecuta esta función de mi catálogo"*.
 
## 3. ¿Cómo sabe qué parámetros pasarle? (El Contrato)

PostgreSQL no adivina. Cada tipo de hook tiene una **firma de función** (un contrato) obligatoria. Si tu función no tiene exactamente los argumentos que el hook espera, fallará.

Para el caso de `passcheck`, el contrato definido en la documentación de PostgreSQL (y que `pg_tle` respeta) es el siguiente:

| Parámetro | Tipo | Descripción |
| --- | --- | --- |
| `username` | `text` | El nombre del usuario que se está creando o modificando. |
| `password` | `text` | La contraseña en texto plano (antes de ser encriptada). |
| `password_type` | `pgtle.password_types` | Indica si la clave es `PASSWORD` o `ENCRYPTED PASSWORD`. |
| `valid_until` | `timestamptz` | La fecha de expiración de la clave (si existe). |
| `valid_now` | `boolean` | Indica si la clave debe ser válida inmediatamente. |

**¿Cómo sabe qué poner en cada uno?**
El motor de PostgreSQL ya tiene esos datos en memoria en el momento que ejecutas el comando. Por ejemplo, si tú escribes:
`ALTER ROLE "juan" VALID UNTIL '2027-01-01' PASSWORD 'Secreta#123';`

El motor automáticamente mapea:

* `username`  'juan'
* `password`  'Secreta#123'
* `valid_until`  '2027-01-01 00:00:00'

 

## 4. ¿Dónde puedo ver qué otros "Hooks" existen?

`pg_tle` soporta varios puntos de integración. Puedes ver los "feature IDs" disponibles consultando la tabla de configuración de la extensión:

```sql
SELECT * FROM pgtle.feature_info;

```

Los más comunes que puedes practicar son:

* **`passcheck`**: Validación de contraseñas.
* **`clientauth`**: Para decidir si permites que un usuario se conecte según su IP o base de datos.
* **`rewrite`**: Para modificar una consulta SQL antes de que se ejecute (muy avanzado).

---

# Dónde se especifica el hook?
 
PostgreSQL es como un edificio con muchas puertas. Cada puerta es un **Hook**.

* Puerta 1: `passcheck` (cuando alguien cambia una contraseña).
* Puerta 2: `clientauth` (cuando alguien intenta iniciar sesión).
* Puerta 3: `post_parse_analyze` (cuando el motor termina de leer una consulta SQL).

### El secreto está en el registro

Cuando instalas la extensión `pg_tle`, ella le dice a PostgreSQL: *"Oye, yo me voy a encargar de vigilar esas puertas por ti"*. A esto se le llama **registrar los callbacks**.

Aquí está el paso a paso de cómo sabe exactamente dónde disparar tu función:

#### 1. La "Etiqueta" (Feature ID)

Cuando ejecutamos esta línea:
`SELECT pgtle.register_feature('mi_funcion', 'passcheck');`

Estamos guardando un registro en una tabla interna de la extensión `pg_tle`. Esa tabla dice algo como:

> *"Si el motor de base de datos toca la puerta de tipo **passcheck**, busca y ejecuta la función llamada **mi_funcion**"*.

#### 2. La coincidencia de tipos

PostgreSQL no va disparando funciones al azar. Cada Hook tiene un identificador único en el código fuente de C. Cuando tú usas la palabra clave `'passcheck'`, le estás dando a `pg_tle` la **llave exacta** que abre la puerta de validación de contraseñas.

Si tú intentaras registrar una función de password en un hook de autenticación de red (`clientauth`), `pg_tle` te daría un error o simplemente la función no se ejecutaría porque **los parámetros no coincidirían**.

#### 3. El flujo de ejecución

Cuando tú escribes `ALTER USER...`:

1. **PostgreSQL (Core)** llega al punto de revisión de seguridad.
2. **PostgreSQL (Core)** pregunta: *¿Hay algún "manejador" (handler) activo para el hook de password?*
3. **pg_tle** levanta la mano y dice: *"¡Sí, yo! Y tengo una lista de funciones de PL/pgSQL que el usuario registró con la etiqueta 'passcheck'"*.
4. **pg_tle** toma los datos (el username, el password, etc.), los traduce de formato C a formato SQL, y llama a tu función.
 
### Un ejemplo para comparar

Es como configurar las notificaciones de tu celular:

* **El Hook:** Es el evento del sistema (Llega un mensaje, se acaba la batería, suena la alarma).
* **El Registro:** Es cuando tú vas a configuración y dices: *"Para el evento 'Llegada de mensaje' (passcheck), quiero que suene 'Sonido_1' (tu_funcion)"*.
* **La ejecución:** El sistema sabe que debe sonar 'Sonido_1' y no la alarma del despertador porque tú vinculaste ese sonido específicamente al **ID de evento** de mensajes.

### Hagamos una prueba de "metadatos"

Para que lo veas con tus propios ojos en tu base de datos, ejecuta esto:

```sql
-- Mira todas las funciones que están "colgadas" de algún hook ahora mismo
SELECT * FROM pgtle.feature_info;

```


---

# Tipos de Hooks

Para ser un experto en `pg_tle`, debes saber que aunque PostgreSQL tiene cientos de hooks internos, **`pg_tle`** ha seleccionado y "expuesto" los más útiles y seguros para que podamos usarlos desde SQL.

Aquí tienes el top de los hooks más utilizados, ordenados por su impacto en la seguridad y administración de la base de datos:

 

### 1. `passcheck` (Password Check Hook)

Es el "rey" de los hooks en `pg_tle`. Se dispara cada vez que ejecutas `CREATE ROLE` o `ALTER ROLE` con una contraseña.

* **¿Para qué sirve?**: Forzar políticas de complejidad (longitud, caracteres especiales), evitar que usen su nombre de usuario en la clave, o comparar la contraseña contra una "lista negra" de claves comunes.
* **Firma esperada**:
```sql
check_func(username text, password text, password_type pgtle.password_types, valid_until timestamptz, valid_now boolean)

```



### 2. `clientauth` (Client Authentication Hook)

Este es extremadamente potente. Se ejecuta **antes** de que PostgreSQL permita que una conexión se establezca completamente.

* **¿Para qué sirve?**:
* Bloquear conexiones por horario (ej. nadie entra los domingos).
* Limitar conexiones simultáneas por usuario de forma dinámica.
* Auditar quién intenta entrar y desde qué IP (logging avanzado).


* **Firma esperada**:
```sql
auth_func(port pgtle.clientauth_port_details)

```


*(Nota: El objeto `port` contiene la IP, la base de datos a la que quiere entrar, el usuario, etc.)*

### 3. Hooks de Tipos de Datos (Custom Data Types)

Aunque no es un "hook" de evento único como los anteriores, `pg_tle` te permite crear tipos de datos base.

* **¿Para qué sirve?**: Definir cómo se almacena y se lee un dato que no existe en Postgres (ej. un tipo `Distancia` que acepte "10km" y lo convierta internamente).
* **Funciones necesarias**: Debes registrar funciones de entrada (`in`) y salida (`out`).

 
### Tabla Comparativa: ¿Cuál usar?

| Hook | Nombre en `register_feature` | Cuándo se dispara | Nivel de Riesgo |
| --- | --- | --- | --- |
| **Password** | `'passcheck'` | Al cambiar/crear claves. | **Bajo** (Solo afecta comandos de usuario). |
| **Autenticación** | `'clientauth'` | En cada intento de login. | **Alto** (Un error aquí bloquea todo el acceso). |

 

### Cómo ver cuáles tienes disponibles en tu versión

Como experto, siempre debes verificar qué "puertas" tiene abiertas tu versión de `pg_tle`, ya que AWS y la comunidad añaden nuevos constantemente. Ejecuta esto:

```sql
-- Consultar los "slots" disponibles para hooks
SELECT * FROM pgtle.available_features();

-- Consultar qué funciones tienes "colgadas" actualmente
SELECT * FROM pgtle.feature_info;

```

### Un pequeño "Tip" Pro:

Si vas a practicar con `clientauth`, **¡ten mucho cuidado!**. Si escribes una función que da error (`RAISE EXCEPTION`), podrías quedarte fuera de tu propia base de datos. Asegúrate siempre de tener una sesión de superusuario abierta en una terminal aparte antes de activar un hook de autenticación.

 
```SQL
https://hey-dba.com/articles/trusted-language-extensions-pgtle-setup-the-quick-reference-guide/
https://medium.com/@mbrqttm/how-to-create-a-password-policy-in-amazon-rds-for-postgresql-cb7e70b2e1ed
https://repost.aws/knowledge-center/rds-postgresql-password-policy
https://docs.aws.amazon.com/es_es/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_trusted_language_extension.overview.tles-and-hooks.html
https://www.youtube.com/watch?v=UJQQdSGK5ZY
https://supabase.com/blog/pg-tle
https://pages.awscloud.com/rs/112-TZM-766/images/2023_0210-VW-DAT_Slide-Deck.pdf

https://github.com/taminomara/psql-hooks?tab=readme-ov-file#security-hooks
https://github.com/aws/pg_tle/tree/main/docs
```
