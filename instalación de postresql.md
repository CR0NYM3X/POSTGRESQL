



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

###  Rutas si usars el systemctl por default 

```plaintext
-- Solo en algunos Red Hat
-- /usr/pgsql-16/bin

/usr/lib/postgresql/17/bin/         → binarios del motor (Ejecutables como psql, vaccum etc)
/var/lib/postgresql/17/main/        → datos del cluster (DATA)
/etc/postgresql/17/main/            → configuración del cluster (postgresql.conf, pg_hba.conf , etc)
/var/log/postgresql/                → logs del servicio  (postgresql-16-main.log)
/usr/share/postgresql/17/           → Ejemplos

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

### Links de referenicias 
```bash
https://tomasz-gintowt.medium.com/tuning-ubuntu-debian-pod-postgresql-ea1bb71633d8
Install and configure PostgreSQL Ubuntu - https://documentation.ubuntu.com/server/how-to/databases/install-postgresql/
https://wiki.postgresql.org/wiki/Apt
https://www.postgresql.org/download/linux/ubuntu/

Instalar postgresql agregando el repositorio de psotgresql - https://www.hostinger.com/mx/tutoriales/instalar-postgresql-ubuntu
```
