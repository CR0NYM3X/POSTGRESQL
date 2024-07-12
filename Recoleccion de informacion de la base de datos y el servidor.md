
# Objetivo

Es recopilar información del servidor y la base de datos en caso de requerirse, por lo que enseñaremos los comandos necesarios para realizar esta recopilación de información.


## Comandos:


#  info del cliente: 
```SQL
 select * from inet_server_addr(),inet_server_port(),inet_client_addr(),inet_client_port();
```



### recopilar información de archivos 
```SQL
ldd  /usr/local/pgsql/bin/pg_dump
file  /usr/local/pgsql/bin/pg_dump
readelf /usr/local/pgsql/bin/pg_dump

```

### Validar el soporte de DBMS "Database Management System" (Sistema de Gestión de Bases de Datos)
information_schema.sql_features es una herramienta útil para consultar y comprender las capacidades de SQL soportadas, Por ejemplo, un desarrollador puede utilizar esta tabla para verificar si una característica específica de SQL está soportada antes de escribir código que dependa de ella. 
```SQL
select feature_name, is_supported  from information_schema.sql_features limit 1;
```

## Lista de parametros
**List of non-default configuration parameters** <br>
```SQL
\dconfig+
```

### SABER LOS OBJETOS DE LA BASE DE DATOS 
```SQL 
select * from (select nsp.nspname as Esquema ,cls.relname as Nombre, cls.relkind as Tipo_Objecto
,case cls.relkind 
when 'r' then 'TABLE'
when 'm' then 'MATERIALIZED_VIEW'
when 'i' then 'INDEX'
when 'S' then 'SEQUENCE'
when 'v' then 'VIEW'
when 'c' then 'TYPE'
--when 'r' then 'TABLE'

else cls.relkind::text end as Descripcion_Tipo_Objeto, NULL as Fecha_Creacion, NULL as Fecha_Modificacion, NULL as Parametros
from pg_class cls
join pg_roles rol on rol.oid = cls.relowner
join pg_namespace nsp on nsp.oid = cls.relnamespace
where nsp.nspname not in ('information_schema', 'pg_catalog') and nsp.nspname not like 'pg_toast%'

union all

select n.nspname as Esquema, p.proname as Nombre, 'f' as Tipo_Objecto, 'FUNCTION' as Descripcion_Tipo_Objeto, NULL as Fecha_Creacion, NULL as Fecha_Modificacion, PROARGNAMES AS Parametros
from pg_proc p
left join pg_namespace n on p.pronamespace = n.oid
left join pg_language l on p.prolang = l.oid
left join pg_type t on t.oid = p.prorettype 
where n.nspname not in ('pg_catalog', 'information_schema')
order by 1, 2)a  where nombre ilike '%stat%';
```

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

### Obtener collate del servidor
```sql
locale | grep -i collate
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
df -lh --total
lsblk
cat /etc/fstab
mount
```

Monitorear discos 
```
vmstat 1
iostat -d -x 1  o iostat -d -x -k 1 3
sar -d 1
```


### Espacios de archivos 
```SQL
du -chal /etc/

/* ** PARÁMETROS 
-l: Muestra solo el tamaño acumulado de cada directorio.
-h: Human-readable, muestra tamaños en formato legible para humanos.
-c: Muestra el total al final del informe.
-a: Incluye la información de todos los archivos, no solo directorios.
*/

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
