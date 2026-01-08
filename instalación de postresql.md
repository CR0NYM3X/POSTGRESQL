



### Valida la versión de tu sistema operativo S.O 
```bash
cat /etc/redhat-release
cat /etc/os-release
lsb_release -d
uname -a
```

## 🧩 ¿Qué son los repositorios en Ubuntu?

Los **repositorios** son ubicaciones (generalmente servidores en Internet) que contienen paquetes de software, actualizaciones y dependencias que el servidor puede instalar o actualizar mediante el sistema de gestión de paquetes `APT`.


## 🎯 ¿Para qué sirven?

1. **Instalación de software confiable**: Permiten instalar programas con un solo comando (`apt install nombre_paquete`).
2. **Actualizaciones automáticas**: Aseguran que el software se mantenga actualizado.
3. **Gestión de dependencias**: Resuelven automáticamente los paquetes necesarios para que un programa funcione.
4. **Seguridad**: Los repositorios oficiales incluyen parches de seguridad validados por Canonical.
 
## 🛡️ Consejos de seguridad para servidores productivos

Aquí van buenas prácticas que deberías seguir:

### Definir tus rutas personalizadas
```bash
sudo mkdir -p /mi_disco/pg_data /mi_disco/pg_logs
sudo chown -R postgres:postgres /mi_disco/
sudo chmod 700 /mi_disco/pg_data
```

### ✅ 1. **Usa solo repositorios oficiales o confiables**
Evita agregar repositorios de terceros sin verificar su autenticidad. Prefiere:

- `http://archive.ubuntu.com/ubuntu`
- `http://security.ubuntu.com/ubuntu`

### ✅ 2. **Verifica la firma GPG de los repositorios**
Esto asegura que los paquetes no han sido modificados maliciosamente.

```bash
apt-key list
```

> ⚠️ Nota: `apt-key` está en desuso. Usa `signed-by` en archivos `.sources`.

### ✅ 3. **Evita actualizaciones automáticas sin control**
En servidores productivos, es mejor revisar y aplicar actualizaciones manualmente o mediante scripts controlados.

```bash
sudo apt update
sudo apt list --upgradable
```

### Formas de ver los repositorios

```bash
### 🧭 Opción 1: Usar el archivo `sources.list`
Este archivo contiene la mayoría de los repositorios principales.
	cat /etc/apt/sources.list


### 🧭 Opción 2: Ver los repositorios en `/etc/apt/sources.list.d/`
Este directorio contiene archivos adicionales de repositorios, generalmente agregados por software de terceros.
  ls /etc/apt/sources.list.d/

### 🧭 Opción 3: Usar comandos APT
Para listar todos los repositorios activos:
	apt-cache policy
```


--- 

# Como instalar postgresql
```bash

---------------- Manual ------------------
# Import the repository signing key:
sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Create the repository configuration file:
. /etc/os-release
sudo sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"

# Update the package lists:
sudo apt update

sudo apt install postgresql-18

---------------- Automatico ------------------
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh



---------------- Instalar tool de red ------------------
# Herramientas ifconfig, netstat , route, arp
sudo apt install -y  net-tools 

pg_ctl start -D /tmp/datay -l /tmp/datay/logfile 
```

###  Rutas 

```plaintext
-- Solo en algunos Red Hat
-- /usr/pgsql-16/bin

/usr/lib/postgresql/17/bin/         → binarios del motor (Ejecutables como psql, vaccum etc)
/var/lib/postgresql/17/main/        → datos del cluster (DATA)
/etc/postgresql/17/main/            → configuración del cluster (postgresql.conf, pg_hba.conf , etc)
/var/log/postgresql/                → logs del servicio  (postgresql-16-main.log)
/usr/share/postgresql/17/           → Ejemplos


-- Ver el service 
ls /usr/lib/systemd/system/ | grep postgres

-- Reiniciar Postgresql
systemctl restart postgresql.service



```
--- 

### Valida si tiene paquete instalados de postgresql
```bash
lista todos los paquetes instalados. Para filtrar solo los de PostgreSQL:
	dpkg -l | grep postgresql

 
##  **Ver detalles de un paquete específico**
	apt show postgresql-17

##  **Ver si un paquete está instalado**
	dpkg -s postgresql-17

##  **Ver archivos instalados por un paquete**
	dpkg -L postgresql-17
```

---


## Datos Extra 
```
select name,setting from pg_settings where name in('data_directory','log_filename','unix_socket_directories');

grep -Ei "data_directory|hba_file|ident_file|external_pid_file|unix_socket_directories|log_directory" /etc/postgresql/17/main/postgresql.conf

-- SOLO SI QUIERES INSTALAR EL PSQL 
sudo apt update
sudo apt install postgresql-client -y
```

## 🐘 Optimización de Ubuntu/Debian para Servidores PostgreSQL

### 🧠 TL;DR
Aquí encontrarás recomendaciones para ajustar parámetros del sistema operativo Linux (Ubuntu/Debian) con el fin de mejorar el rendimiento de PostgreSQL. **No se trata de configurar PostgreSQL directamente**, sino de preparar el entorno del sistema operativo.

---

## 🔧 Configuración del sistema con `sysctl`

Puedes modificar parámetros del kernel usando:

- `/etc/sysctl.conf` (archivo principal)
- `/etc/sysctl.d/40-postgresql.conf` (archivo personalizado)

> Si instalaste PostgreSQL desde los repositorios, probablemente ya exista `/etc/sysctl.d/30-postgresql-shm.conf`, que ajusta parámetros de memoria compartida.

### 📄 Ejemplo de configuración recomendada (`40-postgresql.conf`):

```conf
vm.swappiness = 1
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 250
vm.dirty_ratio = 10
vm.dirty_background_ratio = 3
vm.overcommit_memory = 2
net.ipv4.tcp_timestamps = 0
vm.overcommit_ratio = 85
vm.nr_hugepages = 1300
```

### 🧠 Explicación de parámetros clave:

- **`vm.swappiness = 1`**  
  Reduce el uso de SWAP. Por defecto es 60, lo que significa que el sistema empieza a usar SWAP cuando se ha ocupado el 60% de la RAM. SWAP es lento, así que lo ideal es usar más RAM.

- **`vm.dirty_expire_centisecs` y `vm.dirty_writeback_centisecs`**  
  Controlan cuándo los datos modificados en memoria se consideran "suficientemente viejos" para ser escritos en disco. Se expresan en centésimas de segundo.

- **`vm.overcommit_memory = 2` y `vm.overcommit_ratio = 85`**  
  Controlan cómo el sistema permite asignar más memoria de la que realmente tiene. El ratio se calcula como:  
  $$\text{(RAM - SWAP) / RAM} \times 100$$

- **`vm.nr_hugepages = 1300`**  
  Define cuántas páginas enormes se reservan. Esto mejora el rendimiento de PostgreSQL, pero debe ajustarse según la RAM disponible.

---

## 📊 Aplicar y monitorear cambios

### Aplicar cambios:
```bash
sudo sysctl --system
```

### Verificar estado de memoria:
```bash
cat /proc/meminfo | egrep -i "write|cache|dirty"
cat /proc/vmstat | egrep -i "dirty|writeback|cache"
```

---

## 🚫 Desactivar Transparent Huge Pages (THP)

THP puede causar problemas de rendimiento en bases de datos. Para desactivarlo:

1. Edita `/etc/default/grub`:
   ```bash
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash transparent_hugepage=never"
   ```

2. Aplica cambios y reinicia:
   ```bash
   sudo update-grub
   sudo systemctl reboot
   ```

---

## 📁 Sistema de archivos recomendado

Usa **XFS** con las opciones `noatime,nodiratime` para reducir escrituras innecesarias:

```fstab
/dev/sdb /var/lib/postgresql xfs defaults,noatime,nodiratime 0 1
```

Puedes aplicar esto en caliente:
```bash
sudo mount -o remount,noatime,nodiratime /var/lib/postgresql
```

---

## 📐 Cálculo de páginas enormes necesarias

1. Obtén el PID del proceso de PostgreSQL:
   ```bash
   head -n 1 /var/lib/postgresql/*/main/postmaster.pid
   ```

2. Consulta el pico de memoria:
   ```bash
   grep -i vmpeak /proc/<PID>/status
   ```

3. Verifica el tamaño de página enorme:
   ```bash
   grep -i hugepagesize /proc/meminfo
   ```

4. Calcula:
   $$\text{VmPeak} / \text{HugePageSize} = \text{Cantidad necesaria}$$  
   Añade un margen de seguridad (por ejemplo, usa 1300 si el cálculo da 1102).

---

## 🐘 Configuración en PostgreSQL

En `postgresql.conf`:

```conf
huge_pages = on
```

Reinicia PostgreSQL para aplicar.

---

# Tipo de instalaciones 

Para tener el control total y evitar que PostgreSQL haga cosas "a tus espaldas", tienes dos caminos. El primero es **configurar `apt` para que no automatice nada**, y el segundo es **instalar desde el código fuente** (la opción definitiva si quieres mover los binarios de sitio).

Aquí tienes cómo hacerlo de ambas formas:
 

## Opción A: Usar `apt` pero bloqueando la automatización

Esta es la mejor opción si quieres recibir actualizaciones de seguridad pero tú quieres decidir cuándo y dónde crear la base de datos.

### 1. Preparar el sistema (Antes de instalar Postgres)

Instala primero las herramientas comunes. Esto creará la carpeta de configuración donde le diremos a Linux que "se detenga".

```bash
sudo apt update
sudo apt install postgresql-common -y

```

### 2. Desactivar la creación automática de clusters
Solo ya 
Edita el archivo de configuración global de PostgreSQL en Debian/Ubuntu:

```bash

sudo nano /etc/postgresql-common/createcluster.conf

# Busca la línea que dice `create_main_cluster` y cámbiala a **false**:
create_main_cluster = false

```

*Esto evita que al instalar `postgresql-18`, el sistema cree y levante el servicio automáticamente.*

### 3. Instalar PostgreSQL 18

Ahora sí, instala el paquete. Verás que termina la instalación, pero **no habrá ningún proceso corriendo ni carpetas de datos creadas**.

```bash
sudo apt install postgresql-18 -y

```

### 4. Inicialización Manual (Tú tienes el control)

Ahora tú decides las rutas. Supongamos que quieres tus datos en `/custom/data` y logs en `/custom/logs`:

```bash
# Crear carpetas y dar permisos al usuario postgres
sudo mkdir -p /custom/data /custom/logs
sudo chown -R postgres:postgres /custom
sudo chmod 700 /custom/data

# Inicializar manualmente el cluster con initdb
sudo -u postgres /usr/lib/postgresql/18/bin/initdb -D /custom/data

```

---

## Opción B: Instalar desde el Código Fuente (Control Total de Binarios)


```bash
# Crear directorios para instalación y datos
mkdir -p /opt/postgresql/bin
mkdir -p /opt/postgresql/log
mkdir -p /opt/postgresql/data
mkdir -p /home/postgres
```

### 1. Instalar dependencias de compilación

```bash
# Instalar dependencias necesarias
sudo apt install build-essential libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev libssl-dev  pkg-config libicu-dev -y

```


### Explicación de paquetes necesarios
Para compilar PostgreSQL desde el código fuente, necesitas estas herramientas que actúan como "los ingredientes y las herramientas de cocina" para transformar el código en texto a un programa funcional.

### Herramientas de Construcción

* **`build-essential`**: Es el paquete más importante. Contiene el compilador de C (`gcc`), el enlazador y la herramienta `make`. Sin esto, no puedes transformar código fuente en un programa ejecutable.
* **`flex` y `bison**`: Son generadores de analizadores. Sirven para que PostgreSQL pueda **entender y procesar el lenguaje SQL**. `flex` lee el texto y `bison` analiza la estructura de las consultas.
 

### Librerías de Funcionalidad (Headers)

* **`libreadline-dev`**: Permite que cuando uses la terminal de Postgres (`psql`), puedas usar las **flechas del teclado** para ver el historial de comandos o mover el cursor. Sin esto, la terminal sería muy primitiva.
* **`zlib1g-dev`**: Proporciona algoritmos de **compresión**. Es vital para que PostgreSQL pueda comprimir datos y reducir el tamaño de las copias de seguridad.
* **`libssl-dev`**: Habilita la **seguridad y el cifrado**. Es lo que permite que las conexiones a tu base de datos viajen protegidas mediante SSL/TLS.
* **`libxml2-dev`**: Permite que PostgreSQL maneje tipos de datos **XML** y funciones relacionadas con este formato.
* **`libxslt-dev`**: Añade soporte para transformaciones XSLT sobre documentos XML dentro de la base de datos.

 

### 2. Descargar y Compilar

```bash
wget https://ftp.postgresql.org/pub/source/v18.1/postgresql-18.1.tar.gz   # Verifica la versión exacta
tar -xvf postgresql-18.1.tar.gz
cd postgresql-18.1

#  Configurar compilación - Aquí es donde decides dónde van los BINARIOS
./configure --prefix=/opt/postgresql --with-openssl

make # Crea los binarios y los deja dentro de la carpeta donde descargaste el código 
sudo make install # Es el paso que toma esos archivos recién creados y los copia a la ruta que definiste en el prefix (/opt/postgresql).

ls -l /opt/postgresql/bin
```





###   Recomendación profesional:
Nunca permitas login remoto para postgres en producción.


*   **Crear usuario `postgres` con shell**, pero **sin contraseña**.
*   Usar `sudo -u postgres` para ejecutar comandos.
*   Bloquear login SSH para `postgres` (en `/etc/ssh/sshd_config`):
        DenyUsers postgres
*   Mantener permisos correctos en `/opt/postgresql`:
  
--- 


### 1. El requisito real: No usar "root"

PostgreSQL tiene una restricción de seguridad estricta: **no puede ser ejecutado por el usuario root**. Por lo tanto, crear un usuario dedicado es obligatorio, pero el nombre es totalmente a tu elección (puedes llamarlo `dbadmin`, `pgdata`, `pg_service`, etc.).

### 2. Implicaciones de cambiar el nombre

Al usar un usuario distinto a `postgres`, debes tener en cuenta que El directorio de datos (`PGDATA`) y el directorio donde instalaste los binarios deben pertenecer al usuario que creaste.
 

* **Usuario Superuser por Defecto:** Cuando ejecutes el comando `initdb` para inicializar la base de datos, PostgreSQL creará automáticamente un **superuser de base de datos** con el mismo nombre que el **usuario del sistema operativo** que ejecutó el comando.
* Si el usuario de Linux es `dbadmin`, tu superusuario de Postgres será `dbadmin`.


* **Conexiones Locales:** Por defecto, Postgres intenta conectar usando el nombre del usuario actual del shell. Si entras como `dbadmin`, el comando `psql` intentará entrar a la base de datos `dbadmin` con el rol `dbadmin`.
 

### ¿Por qué la gente usa siempre "postgres"?

Principalmente por **estandarización y soporte**. Muchos scripts de automatización (como Ansible o Terraform), herramientas de monitoreo y extensiones de terceros asumen que el usuario se llama `postgres`. Si trabajas en un equipo grande, usar el nombre estándar facilita que otros administradores entiendan el entorno rápidamente.

> **Tip de experto:** Si decides usar un nombre personalizado, asegúrate de documentarlo bien en tu equipo o en el archivo `README` del servidor, y no olvides configurar la variable de entorno `$PGUSER` en el `.bashrc` de ese usuario para facilitar las tareas administrativas.
 

Una medida de seguridad fundamental de PostgreSQL. **Nunca** se permite inicializar o ejecutar la base de datos como el usuario `root`, ya que si alguien lograra hackear la base de datos, tendría acceso total a todo tu servidor.
 el sistema no creó automáticamente el usuario `postgres`. Vamos a hacerlo manualmente y a dejar todo listo con tus rutas personalizadas.



###  1. Crear el usuario del sistema `postgres`

Este usuario será el propietario del binario y del directorio de datos:

```bash

------------------ [Opcion #1 ]  ------------------

# Crear el usuario postgres (sin contraseña y como usuario de sistema para mayor seguridad)
sudo adduser --system --home /home/postgres --shell /bin/bash --group postgres


  --system: crea un usuario del sistema.
  --home /opt/postgresql: define el home (puedes usar `/var/lib/postgresql` si prefieres).
  --shell /bin/bash → Se pueda conectar con bash
  --group postgres: crea el grupo con el mismo nombre.

------------------ [Opcion #2 ] -  Tambien se puede asi ------------------

# Crear el grupo y el usuario postgres
groupadd postgres
useradd -r -g postgres -d /home/postgres -s /bin/bash postgres


-r (system account) : dica que el usuario será del sistema, no un usuario normal. Se usa para cuentas de servicio (como postgres).
-g postgres : Asigna el grupo primario del usuario. esto permite que el usuario comparta permisos con otros miembros del grupo si es necesario.

-d /opt/postgresql : Define el directorio home del usuario. este será el directorio donde el usuario tendrá sus archivos personales
-s /bin/bash :  Define la shell por defecto para el usuario. Aquí le das acceso a Bash, útil si necesitas entrar como postgres para ejecutar comandos. Si no quieres que tenga shell interactiva, podrías usar /usr/sbin/nologin.


------------- Opcional pero no recomendado ------------

# Asignarle contraseña 
passwd postgres


```



###   **Método seguridad : bloquear solo SSH (más granular**

1.  Abre el archivo de configuración:
   ```bash
    sudo vim /etc/ssh/sshd_config
   ```

2.  Agrega esta línea:
   ```
        DenyUsers postgres
   ```
Esto prohíbe que `postgres` se conecte por SSH.

4.  Reinicia el servicio SSH:
    ```bash
    sudo systemctl restart ssh
     ```

---


## Paso 3: Configurar privilegios específicos con `sudo` a un usuario
Ahora configuraremos el archivo **sudoers** para que **únicamente** el usuario `dbadmin` pueda convertirse en `postgres` y por seguridad no se use el usuario postgres para iniciar session 

1. Ejecuta el editor seguro para el archivo sudoers:
```bash
sudo visudo

```

2. Añade la siguiente línea al final del archivo:
```text
dbadmin ALL=(postgres) ALL

```

* **dbadmin**: El usuario que recibe el permiso.
* **ALL**: En cualquier host.
* **(postgres)**: Puede ejecutar comandos **como** el usuario postgres.
* **ALL**: Puede ejecutar cualquier comando.

Si prefieres que no le pida la contraseña de `dbadmin` cada vez que cambie a `postgres`, usa:
`dbadmin ALL=(postgres) NOPASSWD: ALL`

---
 

### Prueba B: Acceso desde `dbadmin` (Correcto)

Entra como `dbadmin` y prueba el cambio de usuario:

```bash


# Intentamos entrar como postgres usando sudo
sudo -u -i postgres 

-u El sistema busca en el archivo sudoers si tú tienes permiso para actuar específicamente como postgres.
-i Se cargan todas las variables de entorno de postgres (como su $PATH, sus alias y configuraciones de base de datos).
``` 


 

## Para que sirve `NOPASSWD: ALL`  

Aquí hay un concepto de `sudo` que es vital entender: **Sudo no te pide la contraseña del usuario al que quieres entrar, te pide TU propia contraseña.**

### ¿Cómo funciona el flujo de contraseñas?

Cuando `dbadmin` ejecuta `sudo -u postgres -i`:

1. **Sin NOPASSWD:** El sistema dice: *"Hola dbadmin, para dejarte ser postgres, primero demuéstrame que tú eres realmente dbadmin"*. Entonces te pide la **contraseña de dbadmin**.
2. **Con NOPASSWD:** El sistema dice: *"Hola dbadmin, ya sé quién eres y confío en ti para este comando específico. Pasa directamente"*.
 
 
---
###  2. Asignar permisos al directorio de instalación

```bash

# Asegurarnos de que las carpetas existan
mkdir -p /opt/postgresql/data /opt/postgresql/log

# Cambiar el dueño de toda la carpeta a 'postgres'
sudo chown -R postgres:postgres /opt/postgresql 

# Dar permisos estrictos a la carpeta de datos (Postgres lo exige)
chmod 700 /opt/postgresql/data
```

Esto asegura que el usuario `postgres` tenga control sobre los binarios y el directorio de datos.



###  3. Cambiar al usuario `postgres` para inicializar (cuando decidas)

Cuando quieras inicializar el cluster (más adelante), haz:

```bash
sudo -i -u postgres
/opt/postgresql/bin/initdb -E UTF-8 -D /opt/postgresql/data --data-checksums 
```

> Si tu objetivo es **no inicializar todavía**, simplemente no ejecutes `initdb`.

 

###  4. Verificar

```bash
id postgres
```

Debe mostrar el UID y GID del usuario y grupo `postgres`.
 



### 5. Configurar el Log (Donde tú querías)

Como mencionaste que querías controlar dónde se guardan los logs, vamos a configurar el archivo que se acaba de crear:

```bash
# (Aún como usuario postgres)
nano /opt/postgresql/data/postgresql.conf

```

Busca y cambia estas líneas (están comentadas por defecto):

```text
sudo mkdir -p /var/run/postgresql
sudo chown -R postgres:postgres /var/run/postgresql

---------------

logging_collector = on
log_directory = '/opt/postgresql/log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'all'  # Opcional: para ver todas las consultas en el log

unix_socket_directories = '/tmp,/var/run/postgresql' # /var/run/postgresql es más “limpio” en sistemas con systemd




```

---

### 6. Arrancar el servidor manualmente

Para probar que todo funciona bien, levanta el servidor con este comando:

```bash
/opt/postgresql/bin/pg_ctl -D /opt/postgresql/data  start

--  Si no defines el log en postgresql.conf lo puedes hacer con pg_ctl con :
-l /opt/postgresql/log/startup.log

```

### 7. ¿Cómo saber si funcionó?

Ejecuta:

```bash
/opt/postgresql/bin/psql -d postgres

```

 










 
###  **. Verificar instalación**

```bash
/opt/postgresql/bin/postgres --version
```
 

###  **. Variables de entorno (opcional)**

Para usar los binarios sin escribir la ruta completa:

```bash
echo 'export PATH=/opt/postgresql/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```
 



## Resumen de diferencias

| Característica | Con APT (Configurado) | Desde Fuente (Compilado) |
| --- | --- | --- |
| **Binarios** | En `/usr/lib/postgresql/18/bin` | **Donde tú quieras** (ej. `/opt/pg18`) |
| **Actualizaciones** | `sudo apt upgrade` (Automático) | Manual (Re-compilar) |
| **Facilidad** | Alta | Media |
| **Control** | Total sobre Datos y Logs | **Total sobre TODO** |

 
---


#  `postgresql-common` 
es el **"Director de Orquesta"**. Es un paquete de herramientas que no forma parte del código oficial de PostgreSQL (desarrollado por PGDG), sino que es una capa añadida por los empaquetadores de Linux para facilitar la vida... o complicarla, si prefieres el control manual. 

### 1. Gestión de Multiversión (La joya de la corona)

A diferencia de otras distribuciones (como CentOS/RHEL) o Windows, donde instalar una versión pisa a la otra, `postgresql-common` permite que convivan **múltiples versiones** de PostgreSQL y **múltiples instancias** (clusters) en el mismo servidor sin conflictos.

### 2. Los Wrappers (`pg_wrapper`)

Si escribes `psql` en la terminal, ¿cómo sabe el sistema si debe abrir la versión 14 o la 18?
`postgresql-common` instala enlaces simbólicos. Cuando ejecutas un comando:

1. El comando pasa por un "wrapper" (envoltorio).
2. Este revisa qué clusters tienes activos.
3. Te conecta automáticamente al de la versión más reciente o al que esté en el puerto por defecto (5432).

### 3. Herramientas de Administración (`pg_` commands)

Este paquete te regala comandos exclusivos que no existen en otras distros y que simplifican tareas complejas:


| **Comando**         | **Para qué sirve**                                                       |
| ------------------- | ------------------------------------------------------------------------ |
| `pg_lsclusters`     | Muestra todos los clusters instalados, su estado, puerto y rutas.        |
| `pg_createcluster`  | Configura automáticamente las carpetas de datos, logs y sockets.         |
| `pg_dropcluster`    | Borra un cluster y limpia todos sus archivos de configuración.           |
| `pg_ctlcluster`     | Es el comando que usa Systemd para arrancar/parar versiones específicas. |
| `pg_upgradecluster` | Automatiza la migración de datos de una versión vieja a una nueva.       |

 


### 4. Estandarización de Rutas

`postgresql-common` impone una estructura de archivos muy organizada para que el sistema no sea un caos:

* **Configuración:** Siempre en `/etc/postgresql/{versión}/{cluster}/`
* **Datos:** Por defecto en `/var/lib/postgresql/{versión}/{cluster}/`
* **Logs:** Por defecto en `/var/log/postgresql/`



### ¿Por qué te "molestó" al principio?

Cuando instalaste `postgresql-18`, este paquete tiene un **"trigger" (disparador)**. Su lógica es:

> *"Si el usuario instala un paquete de servidor y no hay ningún cluster creado, yo crearé uno llamado 'main' automáticamente para que pueda usarlo de inmediato".*

Es por esto que se inicializó solo. Como vimos antes, esto se desactiva cambiando `create_main_cluster = false` en `/etc/postgresql-common/createcluster.conf`.

### ¿Es recomendable borrarlo?

**No.** Si lo borras, perderás la integración con `systemctl`, los comandos de gestión rápida y la capacidad de actualizar parches de seguridad de forma sencilla. Lo ideal es dejarlo instalado pero "domado", configurándolo para que no haga nada sin tu permiso.



---


###  **Instalación manual (compilación desde código fuente)**

*   **Ventajas:**
    *   Control total sobre la versión exacta y las opciones de compilación (`--with-openssl`, `--prefix`, etc.).
    *   Puedes instalar en cualquier ruta (ej. `/opt/postgresql`) sin depender de la estructura del sistema.
    *   Ideal para entornos donde necesitas personalización extrema o versiones no disponibles en repositorios.
*   **Desventajas:**
    *   Más trabajo: descargar, compilar, resolver dependencias.
    *   No se actualiza automáticamente con `apt update && apt upgrade`.
    *   Debes gestionar manualmente el servicio (systemd), usuario, permisos, variables de entorno.

 

###  **Instalación desde repositorio PGDG (APT)**

*   **Ventajas:**
    *   Rápida y sencilla: `apt install postgresql-18`.
    *   Incluye scripts para crear el usuario `postgres`, inicializar el cluster y configurar el servicio.
    *   Se actualiza automáticamente con el sistema.
    *   Integración con systemd (servicio `postgresql` listo).
*   **Desventajas:**
    *   Menos control sobre opciones de compilación.
    *   Instala en rutas estándar (`/usr/lib/postgresql/`, `/var/lib/postgresql/`).
    *   Inicializa automáticamente un cluster (aunque puedes evitarlo si sabes cómo).
 

---

### Links de referenicias 
```bash
https://tomasz-gintowt.medium.com/tuning-ubuntu-debian-pod-postgresql-ea1bb71633d8
Install and configure PostgreSQL Ubuntu - https://documentation.ubuntu.com/server/how-to/databases/install-postgresql/
https://wiki.postgresql.org/wiki/Apt
https://www.postgresql.org/download/linux/ubuntu/

Instalar postgresql agregando el repositorio de psotgresql - https://www.hostinger.com/mx/tutoriales/instalar-postgresql-ubuntu
```
