
# Objetivo

Es recopilar información del servidor y la base de datos en caso de requerirse, por lo que enseñaremos los comandos necesarios para realizar esta recopilación de información.


## Comandos:

### versión de sistema Operativo linux
```sh
lsb_release -d
uname -a
cat /etc/os-release
cat /etc/redhat-release
```

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
