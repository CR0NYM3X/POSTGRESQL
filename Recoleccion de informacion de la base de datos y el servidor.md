
# Objetivo

Es recopilar información del servidor y la base de datos en caso de requerirse, por lo que enseñaremos los comandos necesarios para realizar esta recopilación de información.


#
```SQL
Test-NetConnection -ComputerName 192.168.5.100 -Port  1433
```

## Comandos:


#  info del cliente: 
```SQL
 select * from inet_server_addr(),inet_server_port(),inet_client_addr(),inet_client_port();
```

### En caso de no tener top o htop
```sh
-- Este comando muestra una lista de procesos ordenados por el uso de CPU. 
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head
ps -eo pid,user,comm,size --sort=-size | head -n 10
ps aux --sort=-%cpu | head
ps -C postgres -o pid=,%mem= --sort=-%mem | awk '{print $1","$2}'
ps -p <PID> -o %cpu,%mem,cmd

# USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
ps -auxww 

vmstat -S m 1 5


Este comando muestra estadísticas del sistema, incluyendo el uso de CPU, cada segundo.
vmstat 1


### **Resumen de cómo separar memoria en componentes**  
| **Componente**       | **Comando**                          | **Campo clave** |  
|----------------------|--------------------------------------|----------------|  
| Memoria Virtual (VSZ)| `ps -o size` o `/proc/[pid]/status`  | `VmSize`       |  
| Memoria RAM (RSS)    | `ps -o rss` o `smem -c rss`         | `VmRSS`        |  
| Memoria Swap         | `smem -c swap` o `/proc/[pid]/status` | `VmSwap`      |  
| Bibliotecas mapeadas | `pmap -x [pid]`                     | Modo `r-x--`   |  
 

```

### recopilar información de archivos 
```SQL
ldd  /usr/local/pgsql/bin/pg_dump
file  /usr/local/pgsql/bin/pg_dump
readelf /usr/local/pgsql/bin/pg_dump

locate postgres -- con esto encuentras todos los archivos que digan ese postgres
which postgres  -- encontraras la ruta binario 

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
```sh
    hostname
    cat /proc/sys/kernel/hostname
```

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
htop (MEM):

Verde: Memoria usada por procesos.
Azul: Memoria usada por buffers.
Amarillo/Naranja: Memoria usada por caché.
Rojo: Memoria usada por el kernel.
Rosa: Memoria de intercambio (swap).

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

sudo iotop
dstat -d --disk-util
iostat -dx 1
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
 grep "model name"


Número de procesadores físicos:
grep physical.id /proc/cpuinfo | sort -u | wc -l

Número de núcleos por procesador:
grep cpu.cores /proc/cpuinfo | sort -u

Número de procesadores lógicos:
grep processor /proc/cpuinfo | wc -l

El tamaño de la cache 
grep 'cache size' /proc/cpuinfo |  sort -u


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

# Todos los objetos de postgresql 
```sql 
select * from 
(


SELECT 
	nspname as schema
    ,relname AS object_name
    ,CASE 
		--WHEN (nc.oid = pg_my_temp_schema()) THEN 'LOCAL TEMPORARY'::text
        WHEN relkind= 'r' THEN 'table'
		WHEN relkind= 'p' THEN 'table'
        WHEN relkind= 'i' THEN 'index'
        WHEN relkind= 'S' THEN 'sequence'
        WHEN relkind= 'v' THEN 'view'
        WHEN relkind= 'm' THEN 'materialized view'
        WHEN relkind= 'c' THEN 'type'
        WHEN relkind= 't' THEN 'TOAST table'
        WHEN relkind= 'f' THEN 'foreign table'
        WHEN relkind= 'p' THEN 'partitioned table'
        WHEN relkind= 'I' THEN 'partitioned index'
        ELSE 'other'
    END AS object_type
	,CASE WHEN typacl is not null and relkind= 'c'  then   typacl  else relacl end as privileges 
	--,relacl
FROM pg_class as cl
left join pg_type as pty on  cl.oid = pty.typrelid 
left join pg_namespace as nc on   cl.relnamespace= nc.oid

 WHERE not nspname in( 'information_schema','pg_catalog','pg_toast')  and not nspname ilike 'pg_temp%' 
 and relkind in('r' ,'p' ,'i' ,'S' ,'v' ,'m' ,'t' ,'f' ,'p' ,'I')
 
 union all 
 
 
  SELECT 
			--p.oid,
			n.nspname as  schema,
            p.proname as object_name ,

			(
			CASE p.prokind
				WHEN 'f'::"char" THEN 'FUNCTION'::text
				WHEN 'p'::"char" THEN 'PROCEDURE'::text
				ELSE NULL::text
			END)::information_schema.character_data AS object_type,
			p.proacl as privileges
   FROM pg_proc as p
   left join pg_namespace as n on    p.pronamespace = n.oid where  not nspname in( 'information_schema','pg_catalog','pg_toast')  and not nspname ilike 'pg_temp%'
 
 
 
 ) as a  order by schema,object_type,object_name;
 

```

# tamaños 
```
| pg_catalog      | pg_column_size         |
| pg_catalog      | pg_tablespace_size     |
| pg_catalog      | pg_tablespace_size     |
| pg_catalog      | pg_database_size       |
| pg_catalog      | pg_database_size       |
| pg_catalog      | pg_relation_size       |
| pg_catalog      | pg_total_relation_size |
| pg_catalog      | pg_size_pretty         |
| pg_catalog      | pg_size_pretty         |
| pg_catalog      | pg_size_bytes          |
| pg_catalog      | pg_table_size          |
| pg_catalog      | pg_indexes_size        |
| pg_catalog      | pg_relation_size       |
```


# comandos  de recoleccion extras 
```sh
################## IP ##################
--- te proporciona información sobre la ruta predeterminada y el próximo salto 
ip route get 1.2.3.4

################## NOMBRE ##################
hostname ;

################## S.O y Kernel ##################
 cat /etc/redhat-release ; uname -a | awk '{print $3}' ; 

##################MEMORIA en Megas ##################
vmstat -s -S M | head -n1 ;

##################Procesadores ##################
grep "model name" /proc/cpuinfo | head -n1


##################CPUs ##################
 grep "processor" /proc/cpuinfo | wc -l ;


##################DISCO DURO ##################.
 df -h ;

##################GCC ##################.
 gcc --version | head -n1
 
 
##################APACHE ##################
httpd -v 


################## PHP ##################
php -v | head -n1 



################## NODE ##################
node -v ; 


################## PM2 ##################." 
 pm2 -v ;


################## Java ##################." 
 which java ; java -version ; 


################## Python ##################
 python --version 
 
################## POSTGRES ##################.
psql --version

################## MONGOD ##################.
 mongod --version | head -n1 ; 
 

################## MySQL ##################." 
 mysql --version 

################## NGINX ##################
nginx -V
```

## Conexiones en linux
```

-- "network statistics" Monitorear el estado de la red y las conexiones activas, estadísticas de red,  tablas de enrutamiento, interfaces de red
netstat -tuln | grep postgres

-- "socket statistics" Obtener información rápida y detallada sobre conexiones de red, incluyendo TCP, UDP, y más
ss -tuln | grep postgres

-- "list open files" Muestra información sobre archivos abiertos  o socket y los procesos que los tienen abiertos.
lsof -i -P -n | grep postgres
```



# Validar conexiones 
```sh


##### USANDO TELNET #####
Telnet 10.28.231.4 5432


##### USANDO sockets TCP de bash #####
#!/bin/bash
HOST="10.28.231.4"
PORT=5433

# Intentar conectar con timeout y telnet
if timeout 5 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
    echo "Conexión exitosa al servidor $HOST:$PORT"
else
    echo "No se pudo conectar al servidor $HOST:$PORT"
fi



##### USANDO NETCAT #####
#!/bin/bash

HOST="10.28.231.4"
PORT=5433

# Intentar conectar
if nc -z -v -w5 $HOST $PORT 2>&1 | grep -q 'Connected'; then
    echo "Conexión exitosa al servidor $HOST:$PORT"
else
    echo "No se pudo conectar al servidor $HOST:$PORT"
fi




```




###  **1. Ver idioma del sistema **


```bash
********************** LINUX **********************

# configuración regional del sistema
localectl status

# Ver variable de entorno 
echo $LANG


# El idioma del sistema 
cat /etc/locale.conf


# todos los idiomas instalados y disponibles 
locale -a


********************** POSTGRESQL **********************
SHOW lc_messages; -- idioma de los mensajes del sistema.
SHOW lc_monetary; -- formato monetario.
SHOW lc_numeric; --  formato de números.
SHOW lc_time; -- formato de fechas y horas.


```

### Revisar si es una maquina virtual
```
systemd-detect-virt
lscpu | grep -Ei "Hypervisor vendor|Virtualization type"
```

### Ver conf de kernel y limites 
```
sysctl -a | grep -Ei "crypto.fips_name|semmns|shmmax " # todas las configuraciones del kernel 
ulimit -a # los límites actuales del usuario en cuanto a recursos del sistema. 
```
