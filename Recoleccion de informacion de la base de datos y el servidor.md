
# Objetivo

Es recopilar información del servidor y la base de datos en caso de requerirse, por lo que enseñaremos los comandos necesarios para realizar esta recopilación de información.


## Comandos:

### Ver zona horaria y fecha 
```sh
ls -l /etc/localtime
file /etc/localtime
timedatectl
cat /etc/timezone
ls /usr/share/zoneinfo

timedatectl | grep "Time zone"
``` 

### versión de sistema Operativo linux
```sh
cat /etc/redhat-release
cat /etc/os-release
lsb_release -d
uname -a
```
### Modelo  del servidor
```
---- Ver el modelo del servidor 
 cat /sys/devices/virtual/dmi/id/{sys_vendor,product_{family,version,name},bios_version}

hostnamectl 
lshw -class system
dmidecode -t system | grep "Product Name"
dmidecode | grep -A3 '^System Information'
 
sudo dmidecode -s system-version
sudo dmidecode -s baseboard-version
sudo dmidecode -s system-manufacturer
sudo dmidecode -s baseboard-manufacturer

-- link: https://unix.stackexchange.com/questions/75750/how-can-i-find-the-hardware-model-in-linux
```

## Obtener el hostname del servidor:
    hostname 


### versión de la base de datos 
```sh
psql -c "select version()"
psql -V
```

### Memoria Ram

```sh
 htop
 vmstat -s -S M 
 cat  /proc/meminfo
 free -h
 free -m
 lshw -short
```

### Discos 
```sh
df -lh:
lsblk
```

Monitorear discos 
```
vmstat 1
iostat -d -x 1  o iostat -d -x -k 1 3
sar -d 1
```


### Espacios de archivos 
```sh
du -lh /etc/
```


### CPU / Procesador
```sh
 htop
 list cpu
 lscpu 
 cat /proc/cpuinfo 
 sudo lshw -class CPU  
 cat /proc/cpuinfo 
 grep "model name"
```

### Tamaño de las base de datos 
```sh
psql -c "SELECT  datname, pg_size_pretty(pg_database_size( datname)) AS size FROM pg_database"
```

### Maximas conexiones permitidas
```sh
 cat postgresql.conf | grep max_connections
 psql -c "show max_connections"
```

### Total de conexiones a la base de datos, Activas, inactivas 
```sh
*- Total de conexiones: 
SELECT count(*) pid FROM pg_stat_activity

*- Total de conexion inactivas pero que no estan realizando ninguna consulta o movimiento
SELECT count(*) pid FROM pg_stat_activity WHERETRIM(state)='idle';

*- Solo conexiones Activa
SELECT count(*) pid FROM pg_stat_activity WHERE query != '<IDLE>' AND TRIM(state)!='idle';


```

### Saber el puerto de la base de datos 
```sh
psql -xc "SELECT * FROM pg_settings WHERE name = 'port'"
cat  postgresql.conf | grep "port ="
```
