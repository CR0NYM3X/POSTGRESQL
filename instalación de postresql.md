



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

# Instalación manual

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

make
sudo make install

ls -l /opt/postgresql/bin
```

### 3. Inicialización manual

Ahora todos tus binarios (`psql`, `postgres`, `initdb`) están exclusivamente en `/opt/postgres18/bin`. El sistema no sabe que existen, así que nada se ejecutará solo. Tú tendrías que inicializar así:

```bash
/opt/postgresql/bin/initdb -D /opt/postgresql/data
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

| Comando | Para qué sirve |
|  |  |
| **`pg_lsclusters`** | Muestra todos los clusters instalados, su estado, puerto y rutas. |
| **`pg_createcluster`** | Configura automáticamente las carpetas de datos, logs y sockets. |
| **`pg_dropcluster`** | Borra un cluster y limpia todos sus archivos de configuración. |
| **`pg_ctlcluster`** | Es el comando que usa Systemd para arrancar/parar versiones específicas. |
| **`pg_upgradecluster`** | Automatiza la migración de datos de una versión vieja a una nueva. |



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


### Links de referenicias 
```bash
https://tomasz-gintowt.medium.com/tuning-ubuntu-debian-pod-postgresql-ea1bb71633d8
Install and configure PostgreSQL Ubuntu - https://documentation.ubuntu.com/server/how-to/databases/install-postgresql/
https://wiki.postgresql.org/wiki/Apt
https://www.postgresql.org/download/linux/ubuntu/

Instalar postgresql agregando el repositorio de psotgresql - https://www.hostinger.com/mx/tutoriales/instalar-postgresql-ubuntu
```
