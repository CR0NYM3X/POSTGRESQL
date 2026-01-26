# **Single-User**

El modo **Single-User** es, esencialmente, el "botón de pánico" o la "herramienta de cirugía profunda" de PostgreSQL. Se utiliza cuando el servidor está tan dañado que no puede arrancar normalmente, o cuando necesitas hacer cambios que requieren que **nadie más** esté tocando la base de datos.

Aquí tienes una lista de escenarios reales y críticos donde este modo es el único camino:

### 1. Recuperación de archivos de configuración corruptos

Si cometiste un error catastrófico en el archivo `pg_hba.conf` (el que controla quién entra) y te bloqueaste a ti mismo de todas las conexiones, el modo single-user ignora por completo las reglas de red y te deja entrar directamente para resetear permisos.

### 2. Reparación de Catálogos del Sistema

A veces, debido a un fallo de hardware o un apagón, las tablas internas de Postgres (donde se guarda la lista de tablas, columnas y tipos) se corrompen.

* **Ejemplo:** No puedes borrar una base de datos porque el sistema cree que hay conexiones activas que no existen. En modo monousuario puedes forzar la limpieza de los catálogos.

### 3. El error "Transaction ID Wraparound"

Este es uno de los problemas más temidos. Ocurre cuando el contador de transacciones de la base de datos llega a su límite. En este punto, Postgres **se apaga y se niega a arrancar** para proteger la integridad de los datos.

* **Uso real:** Debes entrar en modo single-user para ejecutar un `VACUUM` manual sobre la base de datos para "limpiar" los IDs de transacción y permitir que el servidor vuelva a la vida.

### 4. Cambiar configuraciones que impiden el arranque

Si configuraste un parámetro en el archivo `postgresql.conf` que consume demasiada memoria (como un `shared_buffers` más grande que la RAM disponible), el servidor no encenderá.

* **Uso real:** Entras en modo single-user para reducir esos valores desde adentro o para permitir que el motor ejecute comandos mínimos de limpieza.

### 5. Reindexación de índices críticos

Si el índice de una tabla del sistema (como `pg_class`) se corrompe, el servidor no puede funcionar.

* **Uso real:** Puedes usar el comando `REINDEX` sobre tablas del sistema que normalmente están bloqueadas o en uso constante durante la operación normal.

 

### Resumen de casos de uso

| Situación | ¿Por qué Single-User? |
| --- | --- |
| **Resetear Password de Superusuario** | Si perdiste la clave y el acceso por `peer` está desactivado. |
| **Mantenimiento de Emergencia** | Cuando el servidor no inicia por falta de recursos o logs dañados. |
| **Limpieza de Bloqueos Fantasma** | Para eliminar bases de datos que "parecen" estar en uso. |
| **Scripts de migración masiva** | Cuando necesitas velocidad absoluta y riesgo cero de interferencia externa. |

 

> **Dato curioso:** En este modo, el motor **no carga** la mayoría de los procesos de fondo (como el autovacuum o el escritor de estadísticas), lo que lo hace muy ligero pero también muy manual.

 
### ⚠️ Advertencia de seguridad

Cuando estás en modo single-user, tienes **privilegios totales** de superusuario sin que se verifique el archivo `pg_hba.conf`. Es una herramienta de administración potente, pero peligrosa si se usa en un entorno de producción activo.

--- 
# consideraciones clave

Entrar en el **modo Single-User** de PostgreSQL es como entrar en "modo seguro" o de recuperación. Es extremadamente útil cuando el sistema de catálogos está dañado, necesitas realizar un mantenimiento profundo o si accidentalmente bloqueaste todos los accesos.

Aquí tienes los pasos y consideraciones clave para hacerlo:

 
## 1. Detener el servicio

No puedes entrar en modo monousuario si el servidor principal (el demonio `postgres`) ya se está ejecutando sobre la misma carpeta de datos.

* **Linux (Systemd):** `sudo systemctl stop postgresql`
* **Windows:** Detén el servicio desde `services.msc`.

## 2. Ejecutar el comando de conexión

Debes llamar directamente al binario `postgres` (no a `psql`) usando el flag `--single`. Generalmente, debes ejecutarlo como el usuario del sistema `postgres`.

### Estructura del comando:

```bash
postgres --single -D /ruta/a/tus/datos/ nombre_de_la_base_de_datos
```

* **`-D`**: Especifica la ruta del directorio de datos (Data Directory).
* **`nombre_de_la_base_de_datos`**: El nombre de la DB a la que quieres entrar (ej. `postgres` o `template1`).

### Ejemplo real en Linux:

```bash
sudo -u postgres postgres --single -D /var/lib/postgresql/15/main postgres

```


## 3. Cómo trabajar en este modo

Una vez dentro, notarás que el prompt es diferente (suele ser solo un `backend>`). Aquí hay reglas especiales:

* **El separador es el Enter:** A diferencia de `psql`, no necesitas el punto y coma (`;`) para ejecutar una instrucción, basta con presionar **Enter**.
* **Línea por línea:** Solo se procesa una línea a la vez. Si quieres escribir un comando largo, ten cuidado.
* **Para salir:** Presiona `Ctrl + D` o escribe `EOF`.

 

## Diferencias clave con una sesión normal

| Característica | Modo Normal (`psql`) | Modo Single-User |
| --- | --- | --- |
| **Conexiones** | Múltiples usuarios | Solo **uno** |
| **Daemon** | Requiere que el servidor esté activo | El servidor **no** debe estar activo |
| **Autenticación** | Valida roles y contraseñas | No hay validación (acceso total) |
| **Uso principal** | Operación diaria | Recuperación y desastre |

---

# 4 cosas críticas de las que debes cuidarte:

### 1. El peligro del "Enter" (No hay confirmación)

En `psql` normal, escribes un comando, pones `;` y presionas Enter. Si te olvidas del `;`, no pasa nada.

* **En Single-User:** Cada vez que presionas **Enter**, el comando se envía al backend. No necesitas el punto y coma (`;`).
* **El riesgo:** Si escribes un comando por error y le das a Enter, se ejecuta inmediatamente. No hay un "ay, me faltó el WHERE".

### 2. No hay protección contra errores de usuario (Privilegios)

Este modo ignora las reglas de `pg_hba.conf` y los permisos de roles normales.

* **El riesgo:** Entras con poder absoluto sobre el diccionario de datos. Puedes borrar tablas del sistema o catálogos críticos que dejarían la base de datos inservible permanentemente si no sabes exactamente qué registro estás tocando.

### 3. Falta de procesos de fondo (Background Workers)

En modo normal, Postgres tiene "ayudantes" corriendo (como el *Checkpointer* o el *Writer*). En modo Single-User, **tú eres el único proceso**.

* **El riesgo:** Si realizas cambios masivos y la sesión se cierra de forma inesperada (un crash o desconexión forzada), podrías perder datos o dejar los archivos en un estado inconsistente porque no hay un proceso de fondo asegurándose de que todo se escriba correctamente en el disco de la forma habitual.

### 4. Bloqueo de archivos (Data Corruption)

**Nunca, bajo ninguna circunstancia**, intentes entrar en modo Single-User mientras el servicio de PostgreSQL normal está corriendo.

* **El riesgo:** Aunque Postgres intenta bloquear los archivos para que esto no pase, si logras saltarte esa protección (por ejemplo, borrando el archivo de lock manualmente), dos procesos escribiendo en los mismos archivos de datos al mismo tiempo **destruirán la base de datos** por completo.


### Recomendaciones de seguridad:

1. **Haz un respaldo físico antes:** Si vas a hacer algo drástico, copia la carpeta `data` a otro lugar.
2. **Escribe tus comandos en un Bloc de Notas:** No los escribas directamente en la terminal. Cópialos y pégalos para evitar errores de dedo.
3. **Usa `template1` si es posible:** Si vas a hacer reparaciones globales, entra a la base de datos `template1` en lugar de la base de datos de producción para minimizar riesgos.

---



## Help de postgres
```
postgres@server-test ~ $ /usr/pgsql-17/bin/postgres  --help
postgres is the PostgreSQL server.

Usage:
  postgres [OPTION]...

Options:
  -B NBUFFERS        number of shared buffers
  -c NAME=VALUE      set run-time parameter
  -C NAME            print value of run-time parameter, then exit
  -d 1-5             debugging level
  -D DATADIR         database directory
  -e                 use European date input format (DMY)
  -F                 turn fsync off
  -h HOSTNAME        host name or IP address to listen on
  -i                 enable TCP/IP connections (deprecated)
  -k DIRECTORY       Unix-domain socket location
  -l                 enable SSL connections
  -N MAX-CONNECT     maximum number of allowed connections
  -p PORT            port number to listen on
  -s                 show statistics after each query
  -S WORK-MEM        set amount of memory for sorts (in kB)
  -V, --version      output version information, then exit
  --NAME=VALUE       set run-time parameter
  --describe-config  describe configuration parameters, then exit
  -?, --help         show this help, then exit

Developer options:
  -f s|i|o|b|t|n|m|h forbid use of some plan types
  -O                 allow system table structure changes
  -P                 disable system indexes
  -t pa|pl|ex        show timings after each query
  -T                 send SIGABRT to all backend processes if one dies
  -W NUM             wait NUM seconds to allow attach from a debugger

Options for single-user mode:
  --single           selects single-user mode (must be first argument)
  DBNAME             database name (defaults to user name)
  -d 0-5             override debugging level
  -E                 echo statement before execution
  -j                 do not use newline as interactive query delimiter
  -r FILENAME        send stdout and stderr to given file

Options for bootstrapping mode:
  --boot             selects bootstrapping mode (must be first argument)
  --check            selects check mode (must be first argument)
  DBNAME             database name (mandatory argument in bootstrapping mode)
  -r FILENAME        send stdout and stderr to given file

Please read the documentation for the complete list of run-time
configuration settings and how to set them on the command line or in
the configuration file.

Report bugs to <pgsql-bugs@lists.postgresql.org>.
PostgreSQL home page: <https://www.postgresql.org/>
```

## Ejemplo

```
 pg_ctl start -D $PGDATA17


postgres@server-test ~ $ /usr/pgsql-17/bin/postgres  --single  -D $PGDATA17 template1 -F -c exit_on_error=true -d 0
2026-01-26 11:25:32.520 MST [3583362] NOTICE:  database system was shut down at 2026-01-26 11:25:30 MST

PostgreSQL stand-alone backend 17.7
backend> select current_database();
         1: current_database    (typeid = 19, len = 64, typmod = -1, byval = f)
        ----
         1: current_database = "template1"    (typeid = 19, len = 64, typmod = -1, byval = f)
        ----
backend>
backend> select now();
         1: now (typeid = 1184, len = 8, typmod = -1, byval = t)
        ----
         1: now = "2026-01-26 11:25:53.185064-07"       (typeid = 1184, len = 8, typmod = -1, byval = t)
        ----
backend> select datname from pg_database;
         1: datname     (typeid = 19, len = 64, typmod = -1, byval = f)
        ----
         1: datname = "template1"       (typeid = 19, len = 64, typmod = -1, byval = f)
        ----
         1: datname = "template0"       (typeid = 19, len = 64, typmod = -1, byval = f)
        ----
         1: datname = "testdb1"     (typeid = 19, len = 64, typmod = -1, byval = f)
        ----
         1: datname = "postgres"        (typeid = 19, len = 64, typmod = -1, byval = f)
        ----
         1: datname = "testdb2"  (typeid = 19, len = 64, typmod = -1, byval = f)
        ----
backend>

```



# Links
```
-- https://fluca1978.github.io/2019/06/27/PostgreSQLSingleMode.html
```

