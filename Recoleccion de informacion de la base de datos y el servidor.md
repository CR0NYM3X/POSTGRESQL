
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

### Total de conexiones a la base de datos, Activas, inactivas pero conectadas


