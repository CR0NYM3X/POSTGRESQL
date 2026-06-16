



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

 

### ¿Para que sirve el archivo ?

**Sí y no.** No es un archivo que venga "de fábrica" en una instalación limpia de Linux, pero es la **convención estándar** recomendada por expertos y utilizada por scripts de automatización (como Ansible, Puppet o instaladores avanzados) para gestionar PostgreSQL.

El directorio `/etc/sysctl.d/` permite segmentar la configuración del kernel. En lugar de meter todo en el archivo principal `sysctl.conf`, se crean "snippets" (fragmentos). El número **`40-`** es simplemente un orden de prioridad: los archivos se cargan por orden alfanumérico.

 
### ¿Para qué sirve? (El contenido "Potente")

Su propósito es centralizar los ajustes del Sistema Operativo que mencionamos antes para que PostgreSQL "explote" el hardware. Si encuentras o creas este archivo, normalmente contiene estos parámetros críticos:

#### 1. Gestión de Memoria y Swap

* **`vm.swappiness = 1`**: (Lo que ya discutimos) Evita que el SO mande a Postgres al disco.
* **`vm.overcommit_memory = 2`**: Es vital en servidores críticos. Evita que el kernel "prometa" más RAM de la que tiene, lo que previene que el **OOM Killer** mate a Postgres de forma inesperada.
* **`vm.overcommit_ratio = 80`**: Define qué porcentaje de la RAM se puede asignar.

#### 2. Rendimiento de Escritura (Disk Flush)

* **`vm.dirty_background_ratio = 5`**: Le dice al kernel que empiece a escribir datos al disco en segundo plano muy pronto. Esto evita que se acumule mucha "basura" en RAM y que luego el sistema se congele al intentar escribir gigabytes de golpe.
* **`vm.dirty_ratio = 15`**: El límite máximo antes de que el sistema obligue a todas las aplicaciones a detenerse para escribir en disco.

#### 3. Conectividad (Ideal para tu duda de PgBouncer)

* **`net.core.somaxconn = 4096`**: Aumenta el límite de la cola de conexiones que el SO puede aceptar. Si tienes miles de usuarios intentando entrar a PgBouncer, necesitas que este número sea alto para que el SO no rechace los paquetes "TCP SYN".


### 1. `kernel.shmmax` (El límite de un solo segmento)

* **Para qué sirve:** Define el tamaño máximo de un **único** segmento de memoria compartida que un proceso puede solicitar al kernel.
* **Riesgo:** Si es menor que tus `shared_buffers`, Postgres fallará al iniciar.
* **Recomendación Pro:** Antiguamente se calculaba con pinzas, pero hoy, para "explotar" el rendimiento, lo ideal es configurarlo para que pueda albergar casi toda la RAM si fuera necesario.

### 2. `kernel.shmall` (El límite total del sistema)

* **Para qué sirve:** Define la cantidad **total** de memoria compartida (en páginas, no en bytes) que se puede usar en todo el sistema.
* **Cálculo:** Se obtiene dividiendo los bytes totales entre el tamaño de página (normalmente 4096 bytes).


 
### ¿Por qué usar este archivo en lugar de `sysctl.conf`?

1. **Orden y Limpieza:** Si un día decides desinstalar Postgres o moverlo, simplemente borras el archivo `40-postgresql.conf` y el resto del sistema queda intacto.
2. **Persistencia:** Al estar en `/etc/sysctl.d/`, te aseguras de que cada vez que el servidor se reinicie, estos ajustes "agresivos" se apliquen automáticamente.
3. **Prioridad:** El prefijo `40` asegura que tus cambios se apliquen después de los parámetros básicos del sistema (que suelen ser `10-` o `20-`), pero permiten que ajustes de red específicos (como un `60-networking.conf`) tengan la última palabra si fuera necesario.
 
### Cómo crear uno de "Alto Rendimiento" ahora mismo

Si quieres llevar tu servidor al máximo como lo hemos platicado, podrías crear este archivo con este comando:

```bash
sudo nano /etc/sysctl.d/40-postgresql.conf

```

**Copia y pega este contenido (Ajustado para 2026):**

```text
# --- Memoria Compartida (System V) ---
# Permitir segmentos de hasta 48GB (75% de la RAM)
kernel.shmmax = 51539607552

# Total de páginas permitidas (shmmax / 4096)
kernel.shmall = 12582912

# --- Gestión de Memoria y Swap ---
vm.swappiness = 1
vm.overcommit_memory = 2
vm.overcommit_ratio = 80
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.nr_hugepages = 1300

# --- Red de Alta Concurrencia (Miles de usuarios) ---
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_timestamps = 0

# -- Otros 
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 250


```

Luego, aplicas los cambios con:

```bash
sudo sysctl --system

```

 

### 🧠 Explicación de parámetros clave:

- **`vm.swappiness = 1`**  
  Reduce el uso de SWAP. Por defecto es 60, lo que significa que el sistema empieza a usar SWAP cuando se ha ocupado el 60% de la RAM. SWAP es lento, así que lo ideal es usar más RAM.

	- cat /proc/sys/vm/swappiness
	- sysctl vm.swappiness

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



## Nivel 1: El Sistema Operativo (Linux Tuning)

Antes de tocar Postgres, debes preparar la pista de aterrizaje. Sin esto, el SO limitará a la base de datos.

* **Límites de Archivos (`ulimit`):** Postgres abre un archivo por cada tabla e índice, y un socket por cada conexión.
* *Configuración:* En `/etc/security/limits.conf`, sube `nofile` a **65535** o más para el usuario `postgres`.


* **Huge Pages (Páginas Gigantes):** Por defecto, Linux usa páginas de 4KB. Para bases de datos grandes, esto satura el "TLB cache" de la CPU.
* **Inteligencia:** Configura `huge_pages = try` en Postgres y reserva las páginas en el kernel (`vm.nr_hugepages`). Esto puede darte un **10-15%** de mejora de rendimiento bruto en CPU.


* **Swappiness:** No querrás que Postgres use el disco como RAM.
* *Configuración:* `vm.swappiness = 1`. No lo pongas en 0, para permitir que el SO mueva procesos secundarios, pero proteja a Postgres.


* **Transparent Huge Pages (THP):** **¡Apágalo!** Es el enemigo #1 de las bases de datos OLTP porque causa latencias aleatorias.


### ¿Por qué "1" para sistemas supercríticos?

Cuando tienes una base de datos de alto rendimiento, el peor enemigo es la **latencia impredecible**. Si el `swappiness` es alto, ocurre lo siguiente:

1. **Disk Thrashing:** El sistema operativo empieza a mover páginas de la memoria de PostgreSQL (que están en RAM) al disco para hacer espacio para el caché del sistema de archivos.
2. **El "Lag" del Swap:** Cuando Postgres necesita esos datos "swapeados", tiene que esperar a que el disco (que es órdenes de magnitud más lento que la RAM) los devuelva. Esto genera picos de latencia (spikes) que pueden hacer que las aplicaciones fallen por *timeout*.
3. **Predictibilidad:** Con `swappiness = 1`, garantizas que casi el 100% de las consultas de Postgres se resuelvan en RAM o en el caché del procesador.

 

### Comparativa de Valores en Escenarios Críticos

| Valor | Nivel de Riesgo | Comportamiento |
| --- | --- | --- |
| **60 (Default)** | **Alto** | El SO prioriza el caché de archivos sobre la memoria de la BD. Causa latencias aleatorias. |
| **10** | **Bajo / Seguro** | Recomendado para la mayoría de servidores de producción. Es conservador y estable. |
| **1** | **Mínimo / Performance** | **Ideal para sistemas supercríticos.** Prioriza la memoria de los procesos sobre todo lo demás. |
| **0** | **Peligroso** | Puede causar que el OOM Killer mate a Postgres incluso si hay Swap disponible. |

---



### El Riesgo Real: El OOM Killer 💀

El riesgo de configurar un `swappiness` muy bajo en un servidor crítico es que **quitas la "válvula de escape"**.

Si tu servidor se queda sin RAM física (por ejemplo, por una fuga de memoria o una consulta mal optimizada que consume gigas de `work_mem`):

* Con un `swappiness` alto, el sistema se pondría muy lento (pero seguiría vivo).
* Con `swappiness = 1`, el kernel tiene tan poco margen de maniobra que el **OOM Killer** entrará en acción casi de inmediato y **matará el proceso que más RAM use** (probablemente tu instancia de PostgreSQL).


#### Cómo mitigar este riesgo en sistemas supercríticos:

1. **Monitoreo agresivo:** Debes tener alertas cuando el uso de RAM supere el 80-85%.
2. **Ajuste de `oom_score_adj`:** Puedes configurar Linux para que, en caso de emergencia, prefiera matar otros procesos (como logs, agentes de monitoreo, ssh) antes que a PostgreSQL.
3. **Cálculo estricto de Memoria:** Asegúrate de que `shared_buffers` + (`max_connections` * `work_mem`) nunca exceda la RAM física disponible.
 

### Cómo aplicar el cambio "Supercrítico"

Para asegurar que esto persista y sea efectivo ahora mismo:

1. **Aplicar de inmediato:**
```bash
sudo sysctl -w vm.swappiness=1
sudo sysctl -w vm.vfs_cache_pressure=50
```


2. **Hacerlo permanente:**
Edita `/etc/sysctl.conf` y asegúrate de tener:
```text
vm.swappiness = 1
vm.vfs_cache_pressure = 50 
```
 
*(Bajar el cache_pressure a 50 ayuda a que el kernel no "olvide" los metadatos de los archivos de la BD tan rápido).*

---

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
#### En caso de que ya existe el usuario postgresql y no se asigno un home 

-- 1 .- Cambiar la ruta en el sistema
sudo usermod -d /home/postgres -m postgres

-d: Define la nueva ruta.
-m: Mueve el contenido del home actual al nuevo (si es que había algo).

-- 2.- Crear la carpeta manualmente (si no existe) 
sudo mkdir -p /var/lib/postgresql
sudo chown postgres:postgres /var/lib/postgresql



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

 

## 1. Protección mediante `systemd` (La forma más fácil)

Si usas una distribución moderna de Linux (Ubuntu 22.04+, Debian 12, RHEL 9, etc.), puedes usar las capacidades de **Cgroups v2** a través de systemd para blindar a Postgres.

Puedes editar el servicio de PostgreSQL para que el sistema operativo "garantice" su RAM:

1. Ejecuta: `sudo systemctl edit postgresql`
2. Agrega estas líneas:

```ini
[Service]
# Protege la memoria de Postgres hasta este límite (ej. 16GB)
# El kernel no swapeará este proceso a menos que sea crítico
MemoryLow=16G
# Prohibe terminantemente que el kernel swapee este proceso
MemoryMin=8G

```

* **`MemoryLow`:** Es una "promesa" suave. El kernel intentará no tocar esta RAM.
* **`MemoryMin`:** Es una protección dura. El kernel **nunca** moverá esa cantidad de RAM al swap.

 

## 2. Bloqueo de Memoria con `huge_pages` (La forma recomendada)

Esta es la forma "nativa" de Postgres para evitar el swap en su área más crítica: los **Shared Buffers**.

En Linux, las "páginas" normales de memoria son de 4KB. Las **Huge Pages** son de 2MB o más. Lo más importante es que **las Huge Pages no pueden ser enviadas al Swap por diseño del Kernel**.

**Pasos para activarlo:**

1. En `postgresql.conf`:
```text
huge_pages = on  # En lugar de 'try'

```


2. Debes calcular y reservar las páginas en el SO (usando `vm.nr_hugepages` en `/etc/sysctl.conf`).

**Ventaja:** Te aseguras de que el 25%-40% de tu RAM (lo que asignaste a `shared_buffers`) sea **totalmente inmune** al swap, mejorando además el rendimiento de la CPU.


---

 
# Archivos de configuracion linux

### 1. La Válvula Principal (El Kernel de Linux)

**Archivos:** `/etc/sysctl.conf` o `/etc/sysctl.d/99-max-files.conf`
**Nivel de Prioridad: Altamente Recomendado (Requisito previo).** Debes hacerlo para asegurar que la máquina virtual, en su totalidad, tenga un "techo" lo suficientemente alto para soportar a todos los servicios juntos.

Estos dos archivos pertenecen a la **misma capa**. Son la llave de paso principal de la calle que deja entrar el agua a todo el edificio.

* **¿Qué hacen?** Le dicen al "cerebro" de Linux (el Kernel) cuál es el número máximo de archivos que puede abrir **toda la máquina en total**, sumando a todos los usuarios y todos los procesos.
* **¿Por qué te mencioné los dos?** `/etc/sysctl.conf` es el archivo viejo y general. La buena práctica moderna es no tocar ese archivo y, en su lugar, crear un archivo nuevo dentro de la carpeta `/etc/sysctl.d/` (por eso le pusimos `99-max-files.conf`). Así, si actualizas tu sistema operativo, tus configuraciones personalizadas no se borran.
* **En la analogía:** "El edificio completo solo puede consumir 1,000,000 de litros de agua al día. Ni una gota más".

* **Número recomendado:** **1048576** (Un poco más de 1 millón).
* **¿Por qué?** Es un estándar en servidores de bases de datos. Al darle un millón de capacidad total a la máquina virtual, te aseguras matemáticamente de que el sistema operativo en sí nunca será el cuello de botella, sin importar cuánto crezca el tráfico o cuántos servicios nuevos instales en el futuro.

**Ejemplo de cómo se modifica:**
Crea o edita el archivo de configuración personalizado:

```bash
sudo nano /etc/sysctl.d/99-max-files.conf

```

Agrega la siguiente línea con el límite global:

```ini
fs.file-max = 1000000

```

Aplica los cambios inmediatamente (sin necesidad de reiniciar el servidor):

```bash
sudo sysctl -p /etc/sysctl.d/99-max-files.conf

```


### 2. Las Reglas para los Inquilinos (Capa de Usuarios)

**Archivo:** `/etc/security/limits.conf`
**Nivel de Prioridad: Opcional (Buena Práctica Administrativa).** No afecta a los servicios automáticos, pero evitará que tus comandos manuales de mantenimiento (como hacer un backup masivo) fallen cuando te conectes al servidor por SSH.

Una vez que el agua ya entró al edificio, tienes que ponerle reglas a los inquilinos para que uno solo no se gaste el agua de los demás.

* **¿Qué hace?** Establece un límite individual por cada **usuario humano o de sistema** (ej. el usuario `postgres` o el usuario `root`). Estos límites solo aplican cuando un usuario inicia una sesión (por ejemplo, cuando entras por SSH o usas el comando `su - postgres`).
* **En la analogía:** "El inquilino del apartamento 1 (el usuario `postgres`) solo puede consumir un máximo de 65,536 litros de agua por día".

**Ejemplo de cómo se modifica:**
Abre el archivo de límites de seguridad:

```bash
sudo nano /etc/security/limits.conf

```

* **Número recomendado:** **65536**
* **¿Por qué?** Simplemente para mantener la simetría con los servicios. Si tus servicios tienen 65,536, tus usuarios de administración (`postgres`, `pgbouncer`) deben tener exactamente el mismo límite para que los comandos manuales de mantenimiento no fallen por falta de capacidad.

Ve al final del documento y agrega los límites *soft* (blandos) y *hard* (duros) para los usuarios que necesites:

```ini
postgres   soft    nofile    65536
postgres   hard    nofile    65536

pgbouncer  soft    nofile    65536
pgbouncer  hard    nofile    65536

```

*(Los cambios se aplican automáticamente la próxima vez que el usuario inicie sesión).*



### 3. Las Reglas para las Máquinas Automáticas (Capa Systemd)

**Archivo:** El que editamos con `systemctl edit <servicio>`
**Nivel de Prioridad: ABSOLUTAMENTE OBLIGATORIO.** Si no configuras esta capa, no importa qué hayas puesto en las otras dos; tus servicios colapsarán bajo estrés porque recibirán el límite predeterminado del sistema (usualmente 1024).

Aquí es donde la mayoría de los administradores fallan. En los Linux modernos, los servicios que arrancan solos en segundo plano (como PostgreSQL, Patroni o PgBouncer) **no inician sesión como un inquilino normal**, son como las bombas de agua automáticas en el sótano del edificio. Por lo tanto, **ignoran por completo el archivo `limits.conf**`.

* **¿Qué hace?** Le dice al administrador de servicios (Systemd) qué límite específico tiene ese programa en particular cuando arranca automáticamente con el servidor.

* **Número recomendado:** **65536**
* **¿Por qué?** 65,536 (que es $2^{16}$) es el "número de oro" en infraestructura. Le permite a PgBouncer manejar miles de conexiones simultáneas y a PostgreSQL abrir miles de archivos de tablas/índices sin asfixiarse. Poner un número exageradamente más alto (como 1 millón por servicio) es una mala práctica porque obligaría al sistema operativo a reservar estructuras de memoria innecesarias para procesos que nunca usarán tantos archivos.


**Ejemplo de cómo se modifica:**
Utiliza el comando de edición de Systemd para crear una sobrescritura (override) segura para cada servicio (ej. PgBouncer):

```bash
sudo systemctl edit pgbouncer

```

Esto abrirá un editor. Debes agregar exactamente estas dos líneas en la parte superior:

```ini
[Service]
LimitNOFILE=65536

```

Guarda y sal del editor. Luego, repite el proceso para los demás servicios (`sudo systemctl edit patroni`, `sudo systemctl edit etcd`).
Finalmente, recarga Systemd y reinicia los servicios para aplicar el cambio:

```bash
sudo systemctl daemon-reload
sudo systemctl restart pgbouncer

```
 
###  Cómo comprobar que funcionó (Verificación)

Como experto, nunca asumas que la configuración se aplicó. Siempre verifícalo.

Una vez que los servicios estén corriendo, puedes mirar exactamente cuántos archivos tiene permitidos abrir el proceso. Busca el PID (ID del proceso) de PgBouncer o PostgreSQL y lee sus límites en caliente.

Por ejemplo, para ver el límite real de PgBouncer:

```bash
# 1. Obtén el PID del proceso principal
pgrep -x pgbouncer

# 2. Lee los límites de ese proceso (reemplaza 12345 por el PID que te dio el comando anterior)
cat /proc/12345/limits | grep "Max open files"

```
 
 
### Resumen Visual

Para que lo tengas como guía de referencia rápida, así es como interactúan:

| Archivo / Comando | ¿A quién controla? | ¿Cuándo aplica? | Prioridad | Límite Recomendado |
| --- | --- | --- | --- | --- |
| `/etc/sysctl.d/*.conf` | A **toda** la máquina (El límite global). | Siempre, desde que enciendes el servidor. | **Recomendado** | `1000000` |
| `/etc/security/limits.conf` | A los **usuarios** (ej. `postgres`). | Cuando un usuario se loguea en la terminal. | **Opcional** | `65536` |
| `systemctl edit <servicio>` | A los **servicios** (ej. `pgbouncer`). | Cuando el servicio arranca en segundo plano. | **Obligatorio** | `65536` |

En conclusión: Necesitas configurar las tres capas porque si la válvula principal (sysctl) es muy pequeña, no importa qué le pongas a los usuarios; y si configuras a los usuarios (limits.conf) pero te olvidas de los servicios (systemd), tu base de datos colapsará de todos modos al arrancar. Cada archivo cubre un punto ciego diferente del sistema operativo.


### Links de referenicias 
```bash
https://github.com/howtomgr/databases

https://tomasz-gintowt.medium.com/tuning-ubuntu-debian-pod-postgresql-ea1bb71633d8
Install and configure PostgreSQL Ubuntu - https://documentation.ubuntu.com/server/how-to/databases/install-postgresql/
https://wiki.postgresql.org/wiki/Apt
https://www.postgresql.org/download/linux/ubuntu/

Instalar postgresql agregando el repositorio de psotgresql - https://www.hostinger.com/mx/tutoriales/instalar-postgresql-ubuntu
```
