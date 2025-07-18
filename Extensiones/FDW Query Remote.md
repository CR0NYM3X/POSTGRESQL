

![Logo de FDW](https://www.interdb.jp/pg/img/fig-4-fdw-1.png)

# Objetivo
Aprender a consultar información de otros servidores como si la tabla estuviera de manera local, FDW es mas nuevo, antes se usaba dblink <br>
[Doc Oficial ](https://www.postgresql.org/docs/current/postgres-fdw.html )

# Descripcion rápida FDW
Los Foreign Data Wrappers (FDW) en PostgreSQL son una característica que permite a los usuarios acceder y consultar datos de otros servidores como si fueran tablas locales en su base de datos PostgreSQL

Estos son los servidores de Base de datos que se puede conectar con porsgresql y sus extensiones 
- **`Postgresql`**: Puedes usar la extensión `postgres_fdw` para conectarte a bases de datos PostgreSQL desde otro PostgreSQL.
- **`MySQL`**: Puedes usar la extensión `mysql_fdw` para conectarte a bases de datos MySQL desde PostgreSQL.
- **`SQL Server:`** Para conectarte a bases de datos Microsoft SQL Server, puedes utilizar la extensión `tds_fdw` o `sqlserver_fdw`, dependiendo de tu configuración.
- **`Oracle:`** La extensión `oracle_fdw` te permite acceder a bases de datos Oracle desde PostgreSQL.
- **`SQLite:`** PostgreSQL admite la extensión `sqlite_fdw` para acceder a bases de datos SQLite.
- **`MongoDB:`** Existe una extensión llamada `mongodb_fdw` que permite a PostgreSQL conectarse a bases de datos MongoDB.
- **`Cassandra:`** Si deseas acceder a bases de datos Apache Cassandra, puedes utilizar la extensión `cassandra_fdw`.
- **`Hadoop HDFS:`** Para acceder a datos almacenados en Hadoop HDFS, puedes usar la extensión `hadoop_fdw`.
- **`Amazon Redshift:`** PostgreSQL puede conectarse a Amazon Redshift utilizando la extensión `redshift_fdw`.
- **`Google BigQuery:`** Si deseas acceder a Google BigQuery desde PostgreSQL, puedes utilizar la extensión `multicorn` junto con un adaptador específico para BigQuery.
- **`ODBC:`** PostgreSQL también admite el uso de ODBC (Open Database Connectivity) para conectarse a diversas fuentes de datos mediante la extensión `odbc_fdw`.

![Logo de FDW](https://www.postgresql.fastware.com/hs-fs/hubfs/Images/PI/img-pi-dgm-fdw-ove-use-scenario-providing-new-services.png?width=547&name=img-pi-dgm-fdw-ove-use-scenario-providing-new-services.png)



> [!IMPORTANT]
> **no puedes crear índices directamente en una tabla remota:**
En una tabla remota (utilizada a través de FDW), los datos no se almacenan localmente. Cada vez que consultas la tabla remota, la consulta se envía al servidor remoto a través de la red, y los resultados se devuelven sin almacenarlos localmente.


# Ejemplo de uso: 
**`Problema:`**
Queremos permitir que `Servidor remoto` acceda a la tabla "log_monitor" del `Servidor central` para realizar consultas

**`Solución:`**
Para resolver este problema, vamos a configurar un Foreign Data Wrapper en `Servidor remoto` que nos permita acceder a la tabla "log_monitor" en  `Servidor central`


- **`Server Remoto : `** <br>
IP: 10.0.0.100  <br>
User: "user_local" <br>
DB: log_monitor
tb: log_files_local

- **`Server Central:`** <br>
IP: 10.0.0.200  <br>
User:  user_central <br> 
DB: log_monitor <br>
tb: log_files_central

 <br> <br>
**Consulta Información de FDW**<br>
\deu -- ver Usuarios  fdw<br>
\det -- ver Tablas  fdw<br>
\des -- ver Servidores fdw


### Configuración del Server Central IP 10.0.0.200:


### Paso 1 - Verificar que permita conexiones Remotas 
Asegurémonos de que Servidor central permita conexiones remotas, Modifiquemos el archivo postgresql.conf del servidor central ip  10.0.0.200
```
listen_addresses = '*'
```

### Paso 2 - Crear Usuario remoto

- Nos conectamos a postgresql  
```
psql -U postgres 
```

- Creamos el usuario user_central  se usaran los servidores remotos para conectarse al servidor central
```
CREATE USER user_central WITH ENCRYPTED PASSWORD '123123';
```

### Paso 3 - le damos permisos de insert y select al usuario central
```sh
grant select,insert on table logs_files_central  to "user_central";
GRANT CONNECT ON DATABASE "log_monitor" TO "user_central"; --- no se ocupa
ALTER user  "user_central" WITH SUPERUSER;   --- no se ocupa
```


### Paso 4 - Agregar el usuario al archivo PG_HBA 
- Agregarmos el usuario al pg_gba para especificar la ip del servidor que se va conectar y consultar la información
```sh
host    log_monitor      user_central            10.0.0.100/32            scram-sha-256
```

### Paso 5 -  Recargar las configuraciones postgresql
- Realizamos el reinicio para que el postgres detecte los cambios en el archivo pg_hba
```sh
/usr/pgsql-13/bin/pg_ctl reload -D /sysm/data
```



### Paso 7 - Obtener la estructura de la tabla que vamos a compartir 
- La estructura la vamos ocupar en el servidor remoto , en caso de que ya exista la tabla usamos el pg_dump, también podemos crear la tabla si queremos
  
```
 pg_dump -s -t log_files_central -d log_monitor  --no-owner --no-reconnect  --no-privileges  --no-comments  > /tmp/struct.sql


CREATE TABLE logs_files_central (
    id bigserial PRIMARY KEY,
    ip inet NOT NULL,
    nombrelog varchar(255) NOT NULL,
    md5 char(32) NOT NULL,
    fecha timestamp default current_timestamp
);

 ```
 






<!-- ############################### SEUNDA PARTE ###############################  -->

---



## Configuración del Server Remoto  :  


### Paso 1 - Verificar acceso acceso al puerto:
- Tenemos que verificar que en el servidor#1 tengamos acceso al puerto del servidor#2 ya que si no se tiene acceso no se podrá realizar la conexión entre servidores 
```sh
  telnet 10.0.0.200 5432
  psql -U user_central -h 10.0.0.200 -d log_monitor -p 5432
```


### Paso 2 - Crear la base de datos :  dbaplicaciones  
- En este ejemplo vamos a crear la base de datos  `dbaplicaciones` 

```
#crear dba
CREATE DATABASE "dbaplicaciones" WITH TEMPLATE = template0 ENCODING = 'SQL_ASCII' LC_COLLATE = 'C' LC_CTYPE = 'en_US';

o podemos usar:
createdb dbaplicaciones -p 5432
 
```




### Paso 3 - Crear la extensión
- Con la siguiente Query validamos si tenemos instalada en postgresql la extensión 'postgres_fdw' , en caso de no estar instalada se tiene que instalar 
 ```
 select * from pg_available_extensions where name ilike '%fdw%'; 
```

-  Creamos la extension 
```
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
```

- Consultar si se agrego la extensión
```
select * from pg_extension;
```


### Paso 4 - Creamos el server


--- Creamos el server al que nos vamos a conectar 

```
CREATE SERVER "Server_de_logs"
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host '10.0.0.200', port '5432', dbname 'log_monitor');
```

- Verificamos que si se haya creado
```
\des

select * from (select  
		srvname
		,replace(replace(srvoptions[1], 'servername=',''), 'host=','') as servername 
		,replace(srvoptions[2], 'port=','') as port 
		,replace(replace(srvoptions[3], 'database=',''), 'dbname=','') as database  
	FROM pg_foreign_server ) as a  
		where servername = '192.168.2.100';

```

### CAMBIAR LA CONTRASEÑA EN CASO DE ASI REQUERIRLO 
```sql
select * from pg_user_mapping where umserver in(select oid from  pg_foreign_server where srvname = 'test_server');

 --- DOS FORMAS DE CAMBIAR LA PASSWORD 
 UPDATE pg_user_mapping SET umoptions= '{username=USER_TEXT,password=Mi_contra_123}'::text[]  where umserver in(select oid from  pg_foreign_server where srvname = 'test_server');
 UPDATE pg_user_mapping SET umoptions= array['username=USER_TEXT','password=Mi_contra_123']  where umserver in(select oid from  pg_foreign_server where srvname = 'test_server');
```

### Paso 5 - Creamos el usuario local 
- Aqui vamos a crear el usuario local 
```sql 
create user user_local  with login  password '321321';


```

- Le damos permisos al usuario: user_local
```sql
grant SELECT,INSERT on table logs_files_local  to "user_local";
GRANT CONNECT ON DATABASE "mydb_fdw" TO "user_local"; --  no se ocupa
 
```


### Paso 6 - Creamos el user mapping
- Aqui mapeamos el usuario, con esto le decimos que solo el user_local va poder usar las tablas del servidor central
```
CREATE USER MAPPING FOR user_local
    SERVER "Server_de_logs"
    OPTIONS (user 'user_central', password '123123');
```

- Verificamos que si se haya creado 
```
\deu
select   oid ,umuser, usename , umserver ,umoptions from pg_user_mapping left join pg_user on usesysid= umuser;
```

Info Extra  
```
Performance Tips for Postgres FDW
-- Por default FDW usa fetch para recorrer en lineas de 100, modificamos las lineas recorridas y mejoramos el tiempo 

ALTER SERVER server_de_logs  OPTIONS (SET fetch_size '20000');
ALTER SERVER server_de_logs  OPTIONS (SET connect_timeout '10000'); -- establece el tiempo de espera para la conexion 

https://www.ongres.com/blog/boost-query-performance-using-fdw-with-minimal-changes/
https://www.crunchydata.com/blog/performance-tips-for-postgres-fdw#increasing-fetch-count


/****************** SI COLOCAS FALSE EN LA PASSWORD DEL USER MAPPING ********************/
---> TE VA SOLICITAR QUE EL USER_LOCAL SEA SUPERUSER YA QUE TE VA SALIR ESTE ERROR 
 
DETAIL:  Non-superuser cannot connect if the server does not request a password.
HINT:  Target server's authentication method must be changed or password_required=false set in the user mapping attributes.

-- OTROGAR PERMISOS DE SUPERUSER, NO SE RECOMIENDA
ALTER user  "user_local" WITH SUPERUSER;  

--- > TE SALDRA ESTE MENSAJE , ES MEJOR USAR EL DROP USER MAPPING 
ERROR:  could not connect to server "Server_de_logs"
DETAIL:  connection to server at "127.0.0.1", port 5416 failed: fe_sendauth: no password supplied


/****************** EN CASO DE UN ERROR DE PERMISO USAR  ********************/
GRANT USAGE ON FOREIGN SERVER "Server_de_logs" TO user_local; --- no se realizó

```




### Paso 7 -  agregamos la ip del cliente al PG_HBA.conf 
- Agregamos al cliente para especificar la IP que se va conectar al servidor#1 y va consultar la informacion al servidor#2
```
host    dbaplicaciones      user_local            127.0.0.1/32            SCRAM-SHA-256
```


### Paso 8 -  Recargar las configuraciones postgresql
- Realizamos el reinicio para que el postgres detecte los cambios en el archivo pg_hba
```sh
/usr/pgsql-13/bin/pg_ctl reload -D /sysm/data
``` 


### Paso 9 -  Crear la tabla local

- Crear la tabla local manualmente , nosotros le podemos dar el nomre que quremos 
```
CREATE FOREIGN TABLE logs_files_local (
    id bigserial ,
    ip inet NOT NULL,
    nombrelog varchar(255) NOT NULL,
    md5 char(32) NOT NULL,
    fecha timestamp default current_timestamp
) SERVER "Server_de_logs"
OPTIONS (schema_name 'public', table_name 'logs_files_central');
```

- En caso de no contar con la tabla, se puede Crear la tabla remota automaticamente, aqui especificamos que tabla queremos crear y automaticamente la crea con los tipos 
```
IMPORT FOREIGN SCHEMA public LIMIT TO (logs_files_central) FROM SERVER "Server_de_logs" INTO public;
```

- Crea todas las tablas del esquema public
```
IMPORT FOREIGN SCHEMA public FROM SERVER "Server_de_logs" INTO public;
```



### Paso 10 - Validar las tablas  FDW 

- Consultamos cuantas tablas se estan compartiendo
```
\det
select * from information_schema.foreign_tables;
```

### Paso 10 - Validar las tablas  FDW 

- Verificar la información de la tabla
```
select * from logs_files_local;
```


### Paso 11 - Nos conectamos como el usuario 
- Nos conectamos con el usuario que creamos ya que con ese se pueden hacer los movimientos siguientes
```
  psql -U "user_serv1_fdw" -h 10.0.0.100 -d mydb_fdw -p 5432
```



# Dropear todo 
	
	DROP SERVER Server_de_logs CASCADE; -- al borrrar el server se borra todo
	DROP OWNED BY user_local;
	DROP EXTENSION IF EXISTS user_local CASCADE; 
	DROP USER MAPPING FOR user_local SERVER "Server_de_logs";
  	REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "user_local";
	DROP user user_local;
	DROP FOREIGN TABLE logs_files_local;
    
  
 

### consultar informacion de los FDW

``` sh
#Tambien sirve para ver los server FDW
 \des
 
# Verificar los usuarios user fdw 
select   oid ,umuser, usename , umserver ,umoptions from pg_user_mapping left join pg_user on usesysid= umuser;


# Validar si esta instalada en los binarios y se puede usar la extension postgres_fdw
 select * from pg_available_extensions where name ilike '%fdw%'; 
 
#Ver si se creo la extension
 select * from pg_extension;
 
# saber las tablas tienen FDW
 select * from information_schema.foreign_tables;
 select * FROM information_schema.tables WHERE table_schema = 'public'  AND table_type ilike '%FOREIGN%'; 
 
#saber los nombres de los servidores
 select * FROM information_schema.foreign_servers;
 
#Saber las DBA_remota a la que se conecta el servidor 
 select srvname, unnest(srvoptions) AS option FROM pg_foreign_server:

SELECT * FROM postgres_fdw_get_connections() ORDER BY 1;
SELECT * FROM postgres_fdw_get_connections() ORDER BY 1;
 SELECT postgres_fdw_disconnect_all();


 select * from information_schema.foreign_tables;                        
 select * from information_schema.foreign_table_options;                 
 select * from information_schema.foreign_servers;                       
 select * from information_schema.foreign_server_options;                
 select * from information_schema.foreign_data_wrappers;                 
 select * from information_schema.foreign_data_wrapper_options;
| select * from pg_catalog.pg_foreign_table;                              |
| select * from pg_catalog.pg_foreign_server;                             |
| select * from pg_catalog.pg_foreign_data_wrapper;                       |




----- puedes ver los servidores , ips , puerto, db , usermapping, user_remote,

select a.srvname , host , port ,  database, usename ,regexp_replace(regexp_replace(umoptions::text,  '.*username=([^,}]+).*', '\1' )  ,  '.*user=([^,}]+).*', '\1' ) as user , regexp_replace(umoptions::text,    '.*password=([^,}]+).*', '\1') as password 
from ( 	 select  
		oid
		,srvname
		,regexp_replace(regexp_replace(srvoptions::text, '.*host=([^,]+),.*', '\1')  , '.*servername=([^,]+),.*', '\1') as host 
		,regexp_replace(srvoptions::text,    '.*port=([^,}]+).*', '\1') as port 
		,regexp_replace(regexp_replace(srvoptions::text,  '.*database=([^,}]+).*', '\1' )  ,  '.*dbname=([^,}]+).*', '\1' ) as database 
	FROM pg_foreign_server ) as a
	left join pg_user_mapping as b on  b.umserver = a.oid 
	left join pg_user as c on c.usesysid= b.umuser;




---- EJEMPLO MODIFICAR LA QUERY DE UNA TABLA  
update pg_foreign_table set   
ftoptions  =  array[ftoptions[1]] || 
array[
	CASE WHEN ftoptions[2]::text ILIKE '%OFFSET%' THEN
		regexp_replace(ftoptions[2]::text, 'OFFSET .*? ROWS ONLY', ' OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY ;')
	ELSE  
		replace(ftoptions[2]::text,';',' OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY ;')
	END
	]
where ftrelid = 402503 





    

```



### Implementar FDW para SQL SERVER 
**Primero tenemos que tener instalado FreeTDS**
FreeTDS es una biblioteca de programación de software libre que implementa el protocolo Tabular Data Stream (TDS).
No es un programa en sí mismo, sino una colección de bibliotecas que los desarrolladores pueden usar para que sus aplicaciones se conecten a bases de datos SQL Server y Sybase1.
Compatibilidad: Funciona con varios lenguajes de programación como Perl, PHP, y C/C++

```sql
-- ver si esta isntalado 
rpm -qa | grep -Ei FreeTDS

--- ver las configuraciones 
vim /etc/freetds.conf

-- parametros importantes 
grep -Ei "text size|timeout" /etc/freetds.conf
        # Command and connection timeouts
;       timeout = 10 # Tiempo máximo en segundos para recibir respuesta luego de conectado
;       connect timeout = 10 # Tiempo máximo en segundos para establecer una conexión
        # IMAGE) try setting 'text size' to a reasonable limit
;       text size = 64512


```

```sql 
 tsql -S MYSERVER
	CREATE EXTENSION IF NOT EXISTS tds_fdw;

	 
	CREATE SERVER mssql_dms_sample FOREIGN DATA WRAPPER tds_fdw OPTIONS (servername '192.29.230.122', port '1422', database 'test_db');
		
	--  EXTRA -- GRANT USAGE ON FOREIGN SERVER mssql_dms_sample TO dms_user;  
	
	
	-- MAPEAR EL USUARIO 
	 CREATE USER MAPPING FOR postgres  SERVER mssql_dms_sample OPTIONS (username 'systest', password '123123');

	 
 
	-- CREAR LA TABLA MANUALMENTE 
	 CREATE FOREIGN TABLE mssql_dms_sample (
		id INT ,
		nombre VARCHAR(50),
		apellido VARCHAR(50),
		email VARCHAR(100))
	 SERVER mssql_dms_sample
	 OPTIONS (	schema_name 'dbo' ,
			table_name 'clientes',
			row_estimate_method 'showplan_all'  --- puede usar Required: No  Default: execute
			/* , query 'SELECT * FROM sys.database_permissions' */   --- con esto puedes consultar tablas del sistema 
		);


	 -- IMPORTAR TABLA DE MANERA AUTOMATICA 
	IMPORT FOREIGN SCHEMA dbo 
	EXCEPT ("clientess")  /* AQUI COLOCAMOS TABLAS QUE NO QUEREMOS IMPORTAR */
	FROM SERVER mssql_dms_sample 
	INTO PUBLIC /* Esquema de postgresql */
	OPTIONS (import_default 'true');
	 
	--- Opciones:  servername, language, character_set, port, database, dbuse, sqlserver_ansi_mode, tds_version, msg_handler, row_estimate_method, use_remote_estimate, fdw_startup_cost, fdw_tuple_cost
	ALTER SERVER nombre_del_servidor OPTIONS (SET port '555');

	--- Ref https://github.com/tds-fdw/tds_fdw/blob/master/ForeignServerCreation.md
	ALTER SERVER nombre_del_servidor OPTIONS (ADD msg_handler 'notice');
	ALTER SERVER nombre_del_servidor OPTIONS (DROP msg_handler);
	ALTER FOREIGN TABLE nombre_de_la_tabla OPTIONS (SET row_estimate_method 'execute');


 	https://www.sobyte.net/post/2022-03/postgresql-foreign-data-wrappers/
	 https://vishalsinghji.medium.com/how-to-get-mssql-data-in-postgresql-using-foreign-data-wrapper-tds-fdw-30b3ae71b66a
	 https://www.alibabacloud.com/help/en/rds/apsaradb-rds-for-postgresql/use-the-tds-fdw-extension-to-query-data-of-sql-server-instances
	 https://aws.amazon.com/es/blogs/database/use-the-tds_fdw-extension-to-migrate-data-from-sql-server-to-postgresql/
	https://github.com/tds-fdw/tds_fdw/tree/master
	https://pgxn.org/dist/tds_fdw/1.0.2/

```




### Implementar DBLINK
Esta opción es muy vieja y cada vez que se realiza una session tienes que hacer una conexion nueva 
```SQL 
select * from pg_available_extensions where name ilike '%link%';

create extension dblink;

-- dblink_connect : Establece una conexión y hasta que no uses la funcion dblink_disconnect  se va cerrar la conexion 
SELECT dblink_connect('myconn','hostaddr=127.0.0.1 port=5415 dbname=postgres user=user_central password=123123 options=-csearch_path=');

----- aqui puedes usar el SERVER   FOREIGN DATA WRAPPER  para conectarse con dblink 
SELECT dblink_connect('myconn_fdw', 'Server_test_psql');


SELECT * FROM 
	dblink(
		'myconn_fdw' --  dbname=postgres port=5415 host=192.168.1.100 user=user_central password=123123
		,'select * from information_schema.tables;'
	) 
	as (table_catalog                varchar(255),
		table_schema                 varchar(255),
		table_name                   varchar(255),
		table_type                   varchar(255),
		self_referencing_column_name varchar(255),
		reference_generation         varchar(255),
		user_defined_type_catalog    varchar(255),
		user_defined_type_schema     varchar(255),
		user_defined_type_name       varchar(255),
		is_insertable_into           varchar(255),
		is_typed                     varchar(255),
		commit_action                varchar(255)
		);



---- ver las conexiones abiertas 
select * from  dblink_get_connections();

---- para desconectar 
select * from dblink_disconnect('myconn_fdw');

SELECT * FROM 
	dblink('myconn', 'SELECT    pg_reload_conf();') 
as (pg_reload_conf boolean);

--- esto  esta pensado para realizar insert , update, etc 
SELECT dblink_exec('myconn', 'SELECT pg_reload_conf();');

https://www.postgresql.org/docs/current/dblink.html
https://www.postgresql.org/docs/current/contrib-dblink-function.html
```

### BIBLIOGRAFIAS:
```
[Documentación Oficial FDW](https://www.postgresql.org/docs/current/sql-createforeigndatawrapper.html)  
https://www.postgresql.fastware.com/postgresql-insider-fdw-ove  
[FDW English #1](https://dbsguru.com/steps-to-setup-a-foreign-data-wrapperpostgres_fdw-in-postgresql) 
[FDW English #2](https://towardsdatascience.com/how-to-set-up-a-foreign-data-wrapper-in-postgresql-ebec152827f3) 
[FDW Español](https://blogvisionarios.com/articulos-data/virtualizacion-datos-postgresql-foreign-data-wrappers/) 
 mysql_fdw https://dbsguru.com/access-mysql-database-from-postgresql-using-mysql-foreign-data-wrapper-mysql_fdw/
```
