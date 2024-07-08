

![Logo de FDW](https://www.interdb.jp/pg/img/fig-4-fdw-1.png)

# Objetivo
Aprender a consultar información de otros servidores como si la tabla estuviera de manera local, FDW es mas nuevo, antes se usaba dblink 

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
# Ejemplo de uso: 
**`Problema:`**
Queremos permitir que `Servidor#1` acceda a la tabla "cat_plazos" del `Servidor#2` para realizar consultas y operaciones en esa tabla desde Servidor#1.

**`Solución:`**
Para resolver este problema, vamos a configurar un Foreign Data Wrapper en Servidor#1 que nos permita acceder a la tabla "empleados" en Servidor#2. 


- **`Server#1 Postgresql Local : `** <br>
IP: 10.0.0.100  <br>
User: "user_serv1_fdw" <br>
DB: mydb_fdw

- **`Server#2 Postgresql Remoto :`** <br>
IP: 10.0.0.200  <br>
User:  user_serv2_fdw <br> 
DB: sanatudeuda <br>
tb: cat_plazos

 <br> <br>
**Consulta Información de FDW**<br>
\deu -- ver Usuarios  fdw<br>
\det -- ver Tablas  fdw<br>
\des -- ver Servidores fdw





### Configuración del Server#2 Postgresql Remoto :

### Paso 1 - Verificar acceso acceso al puerto:
- Tenemos que verificar que en el servidor#2 tengamos acceso al puerto del servidor#1 ya que si no se tiene acceso no se podrá realizar la conexión entre servidores 
```sh
telnet 10.0.0.100 5432
```
### Paso 2 - Verificar que permita conexiones Remotas 
Asegurémonos de que Servidor#2 permita conexiones remotas, Modifiquemos el archivo postgresql.conf en Servidor#2 esté de esta manera :
```
listen_addresses = '*'
```

### Paso 3 - Crear Usuario remoto

- Nos conectamos a la base de datos que compartira la información:
```
psql -U postgres -d sanatudeuda
```

- Creamos el usuario remoto que se va conectar al servidor#2 a extraer la información
```
CREATE USER user_serv2_fdw WITH ENCRYPTED PASSWORD '1234567890';
```

Info Extra
```sh
grant SELECT  on all tables in schema public to "user_serv2_fdw"; 
GRANT CONNECT ON DATABASE "sanatudeuda" TO "user_serv2_fdw"; --- no se agrego
ALTER user  "user_serv2_fdw" WITH SUPERUSER;   --- no se agrego
```

### Paso 4 - Agregar el usuario al archivo PG_HBA 
- Agregarmos el usuario al pg_gba para especificar la ip del servidor que se va conectar y consultar la información
```sh
host    sanatudeuda      user_serv2_fdw            10.0.0.100/32            md5
```

### Paso 5 -  Recargar las configuraciones postgresql
- Realizamos el reinicio para que el postgres detecte los cambios en el archivo pg_hba
```sh
/usr/pgsql-13/bin/pg_ctl reload -D /sysm/data
``` 

### Paso 6 - Obtener la estructura de una tabla en caso de requerirse
- Con la estructura de la tabla la usaremos al momento de configurar el servidor#1
```
 pg_dump -s -t cat_plazos -d sanatudeuda  --no-owner --no-reconnect  --no-privileges  --no-comments  > /tmp/struct.sql
 ```
 






<!-- ############################### SEUNDA PARTE ###############################  -->





## Configuración del Server#1 Postgresql Local :  


### Paso 1 - Verificar acceso acceso al puerto:
- Tenemos que verificar que en el servidor#1 tengamos acceso al puerto del servidor#2 ya que si no se tiene acceso no se podrá realizar la conexión entre servidores 
```sh
  telnet 10.0.0.200 5432
  psql -U user_serv2_fdw -h 10.0.0.200 -d sanatudeuda -p6432
```


### Paso 2 - Crear la DBA_fdw de prueba 
- En este ejemplo vamos a crear la base de datos  `mydb_fdw` pero en un ambiente real se puede usar una db que ya exista

```
#crear dba
CREATE DATABASE "mydb_fdw" WITH TEMPLATE = template0 ENCODING = 'SQL_ASCII' LC_COLLATE = 'C' LC_CTYPE = 'en_US';

#Conectarnos a la db
\c mydb_fdw
```


### Paso 3 - Creamos el usuario local 
- Aqui vamos a crear el usuario que se va conectar al servidor#1 para realizar las consultas en el servidor#2
```
create user user_serv1_fdw  with login  password '9876543120';
GRANT CONNECT ON DATABASE "mydb_fdw" TO "user_serv1_fdw";
```

Info Extra
```
grant SELECT  on all tables in schema public to "user_serv1_fdw"; --- no se agrego

# Agregar super usuario:
Si no agregar como super usuario a user_serv1_fdw te dira esto
DETAIL:  Non-superuser cannot connect if the server does not request a password.
HINT:  Target server's authentication method must be changed or password_required=false set in the user mapping attributes.

ALTER user  "user_serv1_fdw" WITH SUPERUSER; ---

# esto es si no lo agregamos como super user
UPDATE pg_user_mapping SET umoptions='{user=user_serv2_fdw , password_required=false}' where umuser=667623;

```


### Paso 4 - Crear la extensión
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
CREATE SERVER "Server#2"
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host '192.0.0.200', port '6432', dbname 'my_db_fwd');
```

- Verificamos que si se haya creado
```
\des
select srvname, unnest(srvoptions) AS option FROM pg_foreign_server;
```



### Paso 5 - Creamos el user mapping
- Aqui mapeamos el usuario, esto quiere decir que le indicamos al user_serv1_fdw con que user se va conectar al servidor#2 Remoto
```
CREATE USER MAPPING FOR user_serv1_fdw
    SERVER "Server#2"
    OPTIONS (user 'user_serv2_fdw', password '1234567890');
```

- Verificamos que si se haya creado 
```
\deu
select   oid ,umuser, usename , umserver ,umoptions from pg_user_mapping left join pg_user on usesysid= umuser;
```

Info Extra |  Otorgamos permiso USAGE
```
GRANT USAGE ON FOREIGN SERVER "Server#2" TO user_serv1_fdw; --- no se realizó
```


### Paso 6 -  agregamos la ip del cliente al PG_HBA.conf 
- Agregamos al cliente para especificar la IP que se va conectar al servidor#1 y va consultar la informacion al servidor#2
```
host    mydb_fdw      user_ser1_fdw            10.0.0.5/32            md5
```


### Paso 7 -  Recargar las configuraciones postgresql
- Realizamos el reinicio para que el postgres detecte los cambios en el archivo pg_hba
```sh
/usr/pgsql-13/bin/pg_ctl reload -D /sysm/data
``` 




### Paso 7 - Nos conectamos como el usuario 
- Nos conectamos con el usuario que creamos ya que con ese se pueden hacer los movimientos siguientes
```
  psql -U "user_serv1_fdw" -h 10.0.0.100 -d mydb_fdw -p 5432
```

### Paso 8 -  Crear la tabla remota

- Crear la tabla remota manualmente  y especificamos como queremos consultarla de manera local, en este caso se colocó "cat_plazos_local" pero la tabla remota se llama "cat_plazos"
```
CREATE FOREIGN TABLE public.cat_plazos_local (
    idu_plazo integer NOT NULL,
    des_plazo character varying(50) DEFAULT ''::character varying NOT NULL,
    opc_activo integer DEFAULT 1 NOT NULL
) SERVER "Server#2"
OPTIONS (schema_name 'public', table_name 'cat_plazos');
```

- Crear la tabla remota automaticamente, aqui especificamos que tabla queremos crear y automaticamente la crea con los tipos 
```
IMPORT FOREIGN SCHEMA public LIMIT TO (cat_plazos) FROM SERVER "Server#2" INTO public;
```

- Crea todas las tablas del esquema que especifiquemos
```
IMPORT FOREIGN SCHEMA public FROM SERVER "Server#2" INTO public;
```



### Paso 8 - Consultar información

- Consultamos cuantas tablas se estan compartiendo
```
\det
select count(*) from information_schema.foreign_tables;
```

- Verificar la información de la tabla
```
 select * from cat_plazos2 limit 10;
```

# Dropear todo 
	DROP SERVER servidor_fdw CASCADE; -- al borrrar el server se borra todo
	DROP OWNED BY user_serv1_fdw;
	DROP EXTENSION IF EXISTS postgres_fdw CASCADE; 
	DROP USER MAPPING FOR user_serv1_fdw SERVER servidor_fdw;
  	REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM "user_ser2_fdw";
	DROP user user_serv1_fdw;
	DROP FOREIGN TABLE cat_plazos;
    
  
 

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


```







### BIBLIOGRAFIAS:
[Documentación Oficial FDW](https://www.postgresql.org/docs/current/sql-createforeigndatawrapper.html) <br>
https://www.postgresql.fastware.com/postgresql-insider-fdw-ove <br>
[FDW English #1](https://dbsguru.com/steps-to-setup-a-foreign-data-wrapperpostgres_fdw-in-postgresql)<br>
[FDW English #2](https://towardsdatascience.com/how-to-set-up-a-foreign-data-wrapper-in-postgresql-ebec152827f3)<br>
[FDW Español](https://blogvisionarios.com/articulos-data/virtualizacion-datos-postgresql-foreign-data-wrappers/)



