



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
sudo apt install -y postgresql-common
sudo apt -y install postgresql

pg_ctl start -D /tmp/datay -l /tmp/datay/logfile 
```

###  Rutas si usars el systemctl por default 

```plaintext
/usr/lib/postgresql/17/bin/         → binarios del motor
/var/lib/postgresql/17/main/        → datos del cluster
/etc/postgresql/17/main/            → configuración del cluster
/var/log/postgresql/                → logs del servicio
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

---

### Links de referenicias 
```bash
Install and configure PostgreSQL Ubuntu - https://documentation.ubuntu.com/server/how-to/databases/install-postgresql/
https://wiki.postgresql.org/wiki/Apt
https://www.postgresql.org/download/linux/ubuntu/

Instalar postgresql agregando el repositorio de psotgresql - https://www.hostinger.com/mx/tutoriales/instalar-postgresql-ubuntu
```
