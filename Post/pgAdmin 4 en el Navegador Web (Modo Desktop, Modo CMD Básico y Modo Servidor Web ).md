# El Guía Definitiva: Cómo usar pgAdmin 4 en el Navegador Web (Modo Desktop, Modo CMD Básico y Modo Servidor Web )

Cuando instalamos pgAdmin 4 en  Windows, el instalador por defecto inicializa la herramienta en **Modo Escritorio (Desktop Mode)**. Sin embargo, bajo el capó, pgAdmin es una aplicación web robusta escrita en Python sobre el framework Flask.

Si analizamos detenidamente el código fuente de utilidades como `setup.py`, descubrimos que pgAdmin cuenta con una potente interfaz de línea de comandos (CLI) basada en la librería **Typer**. Esto nos permite abstraer por completo la interfaz gráfica de escritorio y desplegar pgAdmin como un servidor web tradicional y persistente.


### El secreto del archivo `pgadmin4.exe`

Cuando abres `pgAdmin4.exe` desde tu escritorio, no estás abriendo un programa tradicional de Windows. En realidad, estás detonando tres pasos automáticos en cadena:

1. **Enciende un servidor oculto:** El `.exe` arranca un servidor web interno en tu computadora ejecutando silenciosamente el código de Python que está en tu carpeta `AppData` (`pgAdmin4.py`).
2. **Carga el motor de base de datos:** Ese servidor de Python activa de inmediato las librerías nativas en lenguaje **C** (como `libpq.dll`) para quedar listo y poder conectar tus servidores de PostgreSQL.
3. **Abre un navegador disfrazado:** Finalmente, el `.exe` abre una ventana gráfica flotante (llamada *NW.js* o *Electron*). Esta ventana no es un programa, es un navegador web recortado y programado en HTML/Javascript que apunta en secreto a la dirección local de tu servidor de Python (`http://127.0.0.1`).

 
 



Si prefieres usar tu navegador favorito (Chrome, Edge, Firefox) por comodidad o rendimiento, existen tres métodos infalibles para lograrlo. ¡Aquí te enseñamos cómo!

---

# Método 1: El truco rápido (Con el ejecutable de pgAdmin abierto)

Este método aprovecha que pgAdmin ya está corriendo en tu barra de tareas y extrae la "llave secreta" temporal que el sistema genera por seguridad.

### Pasos a seguir:

1. Abre tu aplicación **pgAdmin 4** de escritorio de la manera convencional.
2. En el menú superior, dirígete a: **File** (Archivo) >  **View Log** (Ver Registro).
3. Se abrirá una ventana de texto. Desplázate hasta las últimas líneas y busca dos valores clave:

`Application Server URL: http://127.0.0.1:PUERTO/?key=TU_LLAVE_SECRETA`
<br> Ejemplo: <br>
`http://127.0.0.1:5059/?key=ecec4ba3-a627-7859-ac6e-9e14aabc4fab`
5. **Copia esa URL completa**, pégala en tu navegador favorito y ¡listo! Ya estarás dentro de la interfaz web.

> ⚠️ **Nota:** Esta llave secreta cambia cada vez que cierras y vuelves a abrir la aplicación de escritorio.

---

# Método 2: El modo Experto (Arrancar pgAdmin Web directo desde CMD)

Si no quieres abrir la interfaz de escritorio para nada y prefieres arrancar directamente el servidor web con `pgAdmin4.py` desde la consola de Windows, notarás que el comando clásico falla lanzando un error de librerías (`ImportError: no pq wrapper available`). Esto ocurre porque a Python le falta conocer la ruta de las librerías nativas de PostgreSQL.

Para solucionarlo de golpe, puedes inyectar la ruta del entorno (`PATH`) y ejecutar el script en una sola línea de comandos.

### Pasos a seguir:

1. Presiona la tecla `Windows`, escribe **`cmd`** y abre la **Símbolo del sistema**.
2. Copia y pega el siguiente comando unificado (asegúrate de reemplazar `TU_USUARIO_WINDOWS` por tu nombre de usuario real de Windows):

```cmd


# ------------------------------------------------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------- CMD  --------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------

# ejecutar scripts de Python en segundo plano con pythonw
cmd /v:on /c "set PATH=%PATH%;C:\Users\%USERNAME%\AppData\Local\Programs\pgAdmin 4\runtime&& start "" "C:\Users\%USERNAME%\AppData\Local\Programs\pgAdmin 4\python\pythonw.exe" "C:\Users\%USERNAME%\AppData\Local\Programs\pgAdmin 4\web\pgAdmin4.py""


# Este trae %USERNAME% 
cmd /v:on /c "set PATH=%PATH%;C:\Users\%USERNAME%\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\%USERNAME%\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\%USERNAME%\AppData\Local\Programs\pgAdmin 4\web\pgAdmin4.py""

# Este lo puedes ejecutar desde cmd y se ejecuta en segudno plano y seguiras interactuando con la terminal, pero no la puedes cerrar porque finaliza el servicio
start /B "" cmd /v:on /c "set PATH=%PATH%;C:\Users\%USERNAME%\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\%USERNAME%\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\%USERNAME%\AppData\Local\Programs\pgAdmin 4\web\pgAdmin4.py""


# ------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------ POWERSHELL      ----------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------
$argumentos = '/c set "PATH=%PATH%;C:\Users\francisco.rodriguezt\AppData\Local\Programs\pgAdmin 4\runtime" && "C:\Users\francisco.rodriguezt\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\francisco.rodriguezt\AppData\Local\Programs\pgAdmin 4\web\pgAdmin4.py"'
Start-Process -FilePath "cmd.exe" -ArgumentList $argumentos -WindowStyle Hidden


```

3. Deja la ventana negra de la consola abierta (es la que mantiene vivo el servidor).
4. Abre tu navegador web e ingresa a la dirección local con el puerto correspondiente:
> **`http://127.0.0.1:5050`** *(o el puerto asignado que indique tu consola)*



Si el sistema te solicita credenciales web y es la primera vez que lo corres de forma aislada, el mismo CMD te pedirá definir rápidamente un correo y contraseña para proteger tu sitio.

---



# Método 3:  Server pgAdmin 4 WEB: Despliegue en Modo Servidor, Gestión de Usuarios y Resolución de Errores con Typer


A continuación, consolidamos todo el conocimiento técnico acumulado para inicializar la base de datos local, crear usuarios administradores o convencionales, actualizar credenciales, eliminar registros y solucionar los errores típicos de colisión de sesiones.

---

## Mapeo General de Rutas de la Aplicación

Para que los comandos unificados de este artículo funcionen correctamente, es vital tener ubicadas las rutas por defecto que utiliza el entorno de ejecución empaquetado de pgAdmin 4 en Windows:

* **Python Nativo de la App:** `C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe`
* **Librerías y DLLs de soporte (`runtime`):** `C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime`
* **Scripts Web y CLI (`setup.py` / `pgAdmin4.py`):** `C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\`

---

## Parte 1: Inicialización y Despliegue del Modo Servidor Paso a Paso

Para forzar el uso de credenciales fijas y un comportamiento multiusuario tradicional, debemos migrar la base de datos de configuraciones de pgAdmin a un estado limpio de producción local.

### Paso 1: Forzar el Modo Servidor (`SERVER_MODE = True`)

Antes de invocar los scripts de inicialización, debemos anular el comportamiento de escritorio dinámico. Creamos un archivo de configuración local ejecutando este comando en el Símbolo del Sistema (CMD):

```cmd
echo SERVER_MODE = True > "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\config_local.py"

```

### Paso 2: Inicializar la Base de Datos de la Aplicación (`setup-db`)

La función `setup_db()` de `setup.py` es la encargada de estructurar el directorio de datos corporativos de la herramienta y ejecutar las migraciones iniciales de SQLite (`db_upgrade(app)`). Sin este paso, el motor web no tendrá un almacenamiento mapeado para persistir cuentas.

Ejecutamos el comando inyectando las DLLs del runtime al `PATH` en una sola línea:

```cmd
cmd /v:on /c "set PATH=%PATH%;C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\setup.py" setup-db"

```

*El sistema devolverá el encabezado:* `pgAdmin 4 - Application Initialisation`.

### Paso 3: Configurar el Usuario Administrador Fijo (`add-user`)

La firma del comando en el CLI de Typer requiere argumentos posicionales iniciales. Al incluir la bandera `--admin`, se asigna el nivel de rol más alto de la jerarquía.

```cmd
cmd /v:on /c "set PATH=%PATH%;C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\setup.py" add-user admin@empresa.com contraseñaSegura123 --admin"

```

### Paso 4: Levantar el Servidor Web Dedicado

Con las migraciones aplicadas y el superusuario inyectado en SQLite, procedemos a inicializar el backend HTTP de Flask:

```cmd
cmd /v:on /c "set PATH=%PATH%;C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\pgAdmin4.py""

```

La consola quedará en modo escucha (normalmente en el puerto `5050` o `5059`). No se debe cerrar esta ventana de comandos.

---

## Parte 2: Resolución del Error `KeyError: 'auth_source_manager'`

Al alternar de forma abrupta entre el Modo Escritorio y el Modo Servidor, es sumamente común que la pantalla del navegador se quede congelada de manera indefinida mostrando el mensaje de carga: **"Loading pgAdmin 4 vX.XX..."**.

### Causa Raíz

El motor web de pgAdmin utiliza cookies de sesión cifradas mediante Flask. Si previamente utilizaste la aplicación de escritorio, el navegador conserva una cookie vieja que carece del diccionario `auth_source_manager`. Al intentar procesar el renderizado en Modo Servidor, el backend lee la cookie mutada, no localiza la clave interna de autenticación, arroja un `KeyError` en consola y detiene la renderización del frontend.

### Solución Inmediata

1. **Limpieza del Almacenamiento:** En la pestaña del navegador afectada, presione **`F12`** para abrir las Herramientas de Desarrollador. Vaya a **Application** (Aplicación) -> **Cookies** / **Local Storage**, haga clic derecho sobre la IP `http://127.0.0.1` y seleccione **Clear** (Borrar todo).
*(Nota: Abrir una pestaña en modo incógnito logra el mismo efecto aislado).*
2. **Forzar Origen de Autenticación:** Si el conflicto persiste, edite el archivo `config_local.py` agregando de forma estricta el arreglo de origen interno escribiendo en consola:
```cmd
echo AUTHENTICATION_SOURCES = ['internal'] >> "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\config_local.py"

```


3. **Reiniciar el Proceso:** Cierre el servidor en el CMD con `Ctrl + C` y vuelva a ejecutar el Paso 4 de la sección anterior.

---

## Parte 3: Administración Avanzada de Usuarios vía CLI

Gracias a que `setup.py` procesa los parámetros mediante la librería Typer, las variables declaradas al inicio sin una definición explícita de opción se consideran **Argumentos posicionales obligatorios**. Esto implica que valores como correos o nombres de usuario no deben anteponerse con guiones largos (`--email` o `--username`), sino enviarse puros inmediatamente después del subcomando.

### 1. Agregar Usuarios Convencionales (Rol Estándar)

En el código de `setup.py`, si la bandera `--admin` se evalúa como falsa, el backend mapea el string del argumento `--role`. Si se omite por completo, el script se cae arrojando la excepción `Role 'None' does not exists.`. Por ende, es mandatorio declarar el rol nativo llamado `User`.

```cmd
cmd /v:on /c "set PATH=%PATH%;C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\setup.py" add-user empleado@empresa.com claveUsuario123 --role User"

```

### 2. Modificar Contraseñas sin Interfaz Gráfica (`update-user`)

Para evitar excepciones del tipo `KeyError: 'role'` causadas por la falta de un valor por defecto en los diccionarios de actualización del script, es obligatorio reafirmar el rol del usuario (`--admin` o `--role User`) junto con el paso de la nueva contraseña:

* **Para actualizar a un Administrador:**
```cmd
cmd /v:on /c "set PATH=%PATH%;C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\setup.py" update-user admin@empresa.com --password nuevaClaveSuperAdmin --admin"

```


* **Para actualizar a un Usuario Convencional:**
```cmd
cmd /v:on /c "set PATH=%PATH%;C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\setup.py" update-user empleado@empresa.com --password nuevaClaveEmpleado --role User"

```



### 3. Eliminar Usuarios de la Plataforma (`delete-user`)

Para dar de baja una cuenta de la base de datos interna de la aplicación (incluyendo la cuenta automatizada `pgadmin4@pgadmin.org` autogenerada por Windows), pasamos el correo como parámetro directo. Añadir el flag `--yes` inyecta un estado de confirmación positiva automática a la terminal.

```cmd
cmd /v:on /c "set PATH=%PATH%;C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\setup.py" delete-user pgadmin4@pgadmin.org --yes"

```

### 4. Auditoría y Listado de Cuentas Activas (`get-users`)

Para validar en tiempo real el éxito de las operaciones de inserción, actualización o borrado en nuestro entorno de pruebas, podemos invocar el generador de vistas en consola:

```cmd
cmd /v:on /c "set PATH=%PATH%;C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\setup.py" get-users"

```

Esto nos pintará en la consola una tabla con el estado lógico actual de los accesos:

| Campo (Field) | Valor (Value) |
| --- | --- |
| **Username** | `admin@empresa.com` |
| **Email** | `admin@empresa.com` |
| **auth_source** | `internal` |
| **role** | `Administrator` |
| **active** | `True` |

---

## Tabla de Matriz de Permisos: Administrator vs. User

| Acción dentro de pgAdmin 4 | Rol Administrator | Rol User (Convencional) |
| --- | --- | --- |
| Conectar a bases de datos PostgreSQL externas | Sí | Sí |
| Cambiar preferencias de interfaz (Temas, Query Tool) | Sí | Sí |
| Crear y dar de baja otros usuarios web | Sí | No |
| Mapear e inyectar servidores compartidos globales | Sí | No |
| Ver estadísticas y sesiones activas del aplicativo | Sí | No |

> 💡 **Buenas Prácticas para Pruebas en Windows:** Debido a que pgAdmin utiliza SQLite como motor transaccional de configuración interna, las lecturas y escrituras simultáneas en Windows pueden provocar bloqueos de archivo (`Database is locked`). Cuando manipules usuarios a través del CLI de `setup.py`, detén un momento el servidor web con `Ctrl + C`, realiza los cambios pertinentes en los registros y vuelve a levantarlo.




# Tips

## Cambiar puertos 

Para especificar un puerto propio (por ejemplo, el `8080` o el `9000`) en lugar de usar el puerto dinámico o el `5050` que viene por defecto, debes indicárselo a pgAdmin antes de levantar el servidor.


### Dejarlo grabado en el archivo de configuración

Si prefieres que se quede guardado de forma permanente dentro de tu archivo `config_local.py`, la propiedad interna correcta que debes escribir es `DEFAULT_SERVER_PORT`.

1. Ejecuta este comando para añadir la línea correcta al archivo:

```cmd
echo DEFAULT_SERVER_PORT = 8080 >> "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\config_local.py"

```

2. Vuelve a arrancar tu servidor con la línea convencional:

```cmd
cmd /v:on /c "set PATH=%PATH%;C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\runtime&& "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe" "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\pgAdmin4.py""

```

---

### 💡 Un pequeño consejo de limpieza

Como en el intento anterior agregamos la línea errónea `CONFIG_PORT = 8080` al archivo, no pasa nada malo (Python simplemente la ignorará), pero para mantener tu entorno de pruebas impecable, puedes abrir el archivo `config_local.py` con el bloc de notas y borrar esa línea sobrante, dejando únicamente:

```python
SERVER_MODE = True
AUTHENTICATION_SOURCES = ['internal']
DEFAULT_SERVER_PORT = 8080

```



## Borrar el servidor 

Para apagar o desactivar el servidor web por completo y que pgAdmin vuelva a la normalidad, **el método correcto y más limpio es borrar el archivo `config_local.py**`, no cambiar el valor a `False`.

Aquí te explico técnicamente por qué:

### ¿Por qué no debes poner `SERVER_MODE = False`?

Si dejas el archivo y solo cambias la línea a `SERVER_MODE = False`, obligarás a pgAdmin a correr en **Modo Escritorio**, pero al ejecutarse de manera aislada te exigirá la famosa "llave secreta" dinámica (`PGADMIN_INT_KEY`) de la que hablamos al principio. Entrar desde el navegador se volverá muy molesto porque esa clave cambia a cada rato.

---

### El Método de Desactivación Correcto (Paso a Paso)

Para revertir todo y dejar la aplicación impecable como venía de fábrica, ejecuta estos pasos rápidos en tu CMD:

#### Paso 1: Matar el proceso actual

Si el servidor sigue corriendo en la pantalla negra, presiona **`Ctrl + C`** en tu teclado para apagar el servicio HTTP.

#### Paso 2: Borrar el archivo de configuración local

Ejecuta este comando para eliminar el archivo que creamos para las pruebas. Al no existir este archivo, pgAdmin olvida los puertos fijos, el login obligatorio y las fuentes de autenticación:

```cmd
del "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\config_local.py"

```

#### Paso 3: Limpiar el rastro de la base de datos de pruebas (Opcional pero recomendado)

Si quieres que no quede rastro de los usuarios de prueba (`jose@coppel.com` o `empleado@coppel.com`), borra el archivo SQLite de almacenamiento ejecutando:

Cuando ejecutas el comando `del pgadmin4.db`, no estás tocando ni dañando tus bases de datos reales de PostgreSQL (las tablas de tu empresa o tus datos productivos están a salvo en el motor de Postgres).

Solo estás borrando la "agenda de contactos" de pgAdmin. Al eliminarlo, pgAdmin se inicializa en un estado de amnesia total: olvida qué servidores tenías agregados y qué usuarios web habías creado.

```cmd
del "C:\Users\TU_USUARIO_WINDOWS\AppData\Roaming\pgAdmin\pgadmin4.db"

```

---

### ¿Cómo verificar que se desactivó con éxito?

No vuelvas a tocar la consola CMD. Simplemente ve al menú de Inicio de Windows, escribe **pgAdmin 4** y dale doble clic al icono azul de la aplicación.

El programa se abrirá de forma nativa en su ventana de escritorio convencional, administrando sus propios tokens de seguridad en memoria y sin pedirte nunca más correos ni contraseñas.

---

## Resumen de directorios 
comienza  con `C:\Users\TU_USUARIO_WINDOWS\`

---

### 1. `...\AppData\Roaming\pgAdmin`

* **El Corazón de tus Datos:** Aquí se guarda tu información personal y de trabajo.
* **¿Qué contiene?:** El archivo **`pgadmin4.db`** (la base de datos SQLite con tus usuarios creados y la lista de servidores guardados), los logs de errores (`pgadmin4.log`) y las sesiones activas.

### 2. `...\AppData\Roaming\pgadmin4`

* **La Mente del Modo Escritorio:** Controla cómo se comporta la ventana flotante del programa en Windows.
* **¿Qué contiene?:** El archivo `config.json` con las coordenadas de la pantalla (ancho, alto, posición) y el puerto dinámico asignado para esa sesión.

### 3. `...\AppData\Local\Programs\pgAdmin 4`
``
* **El Cuerpo de la Aplicación:** Es la carpeta principal donde se instala el programa y contiene todo el código que lo hace funcionar. Se divide en tres subcarpetas clave:
* `\python`: El entorno aislado de Python que usa pgAdmin para correr sus scripts.
* `\runtime`: Las librerías nativas, binarios  y archivos DLL de PostgreSQL (como `libpq.dll` o `pgAdmin4.exe`) necesarios para conectar las bases de datos.
* `\web`: El código fuente real de la página web, incluyendo el archivo ejecutable principal `pgAdmin4.py` y el CLI de configuración `setup.py`.

----

## Datos extras de rutas
```cmd
pgAdmin Runtime Environment
--------------------------------------------------------
Python Path: "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\python\python.exe"
Runtime Config File: "C:\Users\TU_USUARIO_WINDOWS\AppData\Roaming\pgadmin4\config.json"
Webapp Path: "C:\Users\TU_USUARIO_WINDOWS\AppData\Local\Programs\pgAdmin 4\web\pgAdmin4.py"
type "C:\Users\TU_USUARIO_WINDOWS\AppData\Roaming\pgadmin4\config.json"
```


## Links 
```
https://medium.com/@jaimemartinagui/pgadmin-on-raspberry-pi-857872e6f3b2
https://github.com/pgadmin-org/pgadmin4/blob/master/web/setup.py
```
