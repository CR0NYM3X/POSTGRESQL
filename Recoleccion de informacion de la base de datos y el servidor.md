
# Objetivo

El objetivo es recopilar información del servidor y la base de datos en caso de requerirse y enseñaremos los comandos necesarios para realizar este procedimiento 


## Ejecución

### Version de sistema Operativo linux
```sh
 lsb_release -d  || uname -a  | cat /etc/os-release | cat /etc/redhat-release
```

### Memoria Ram

```sh
 vmstat -s -S M  | cat  /proc/meminfo 	| free -h | free -m  | lshw -short (Descripcion general)
```

### Discos 
```sh
--info discos mas claro df -H:
--info discos conectados lsblk
```

### Version de la base de datos 
```sh
psql -c "select version()"
psql -V
```

### CPU / Procesador
```sh
 htop | 	list cpu  | lscpu | cat /proc/cpuinfo  | sudo lshw -class CPU  | cat /proc/cpuinfo | grep "model name"
```

### Tamaño de las base de datos 
```sh
SELECT  datname, pg_size_pretty(pg_database_size( datname)) AS size FROM pg_database; 
```
