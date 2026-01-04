PostgreSQL tiene soporte nativo para usar conexiones SSL para cifrar las comunicaciones entre cliente y servidor
para mayor seguridad. Esto requiere que OpenSSL esté instalado tanto en los sistemas cliente como servidor y
que el soporte en PostgreSQL esté habilitado en el momento de la compilación.



 TLS en PostgreSQL utiliza una combinación de criptografía asimétrica y simétrica para proporcionar una comunicación segura. La criptografía asimétrica se utiliza para el intercambio seguro de claves y la autenticación, mientras que la criptografía simétrica se emplea para el cifrado rápido de los datos transmitidos.
 

## Proceso de TLS en PostgreSQL

1. **Intercambio de Claves (Criptografía Asimétrica)**:
   - El cliente y el servidor utilizan criptografía asimétrica para intercambiar una clave de sesión de manera segura.
   - Este proceso asegura que la clave de sesión no pueda ser interceptada por terceros.

2. **Cifrado de Datos (Criptografía Simétrica)**:
   - Una vez que se ha intercambiado la clave de sesión, se utiliza criptografía simétrica para cifrar los datos transmitidos entre el cliente y el servidor.
   - Esto garantiza que los datos sean transmitidos de manera segura y eficiente.
 
 
 
 

# Fase #1 Pre-Implementación 

### Requisitos

#### #1 En el servidor Tener Instalado igual o mayo OpenSSL 1.1.1
```BASH
    openssl version  # --> OpenSSL igual o mayo a 1.1.1 
    openssl version -d  # --> OPENSSLDIR: "/etc/pki/tls"  Establece valores predeterminados para varios campos en los certificados.
```
 
#### Versiones compatibles de SSL/TLS con OpenSSL
| **Versión de OpenSSL** | **SSLv2** | **SSLv3** | **TLS 1.0** | **TLS 1.1** | **TLS 1.2** | **TLS 1.3** |
|------------------------|-----------|-----------|-------------|-------------|-------------|-------------|
| **OpenSSL 1.0.x**      | disable   | disable   | true        | true        | true        | false       |
| **OpenSSL 1.1.x**      | false     | false     | true        | true        | true        | false       |
| **OpenSSL 1.1.1**      | false     | false     | true        | true        | true        | true        |
| **OpenSSL 3.0.x**      | false     | false     | true        | true        | true        | true        |


 
#### #2 En el Servidor tener instalado [PostgreSQL con soporte](https://www.postgresql.org/support/versioning/) y compatible con tls 1.2. y 1.3
```SQL
postgres@postgres# select version();
+---------------------------------------------------------------------------------------------------------+
|                                                 version                                                 |
+---------------------------------------------------------------------------------------------------------+
| PostgreSQL 16.6 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit |
+---------------------------------------------------------------------------------------------------------+
(1 row)

Time: 0.557 ms
```


#### Versiones compatibles de SSL/TLS con PostgreSQL 

| **Versión de PostgreSQL** | **SSLv2** | **SSLv3** | **TLS 1.0** | **TLS 1.1** | **TLS 1.2** | **TLS 1.3** | **ssl_min_protocol_version** | **ssl_max_protocol_version** |
|---------------------------|-----------|-----------|-------------|-------------|-------------|-------------|-----------------------------|-----------------------------|
| **9.4**                   | false     | false     | true        | true        | true        | false       | N/A                         | N/A                         |
| **12**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **13**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **14**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **15**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **16**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **17**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |


#### Validar si esta disponible la extension sslinfo
    select * from pg_available_extensions where name = 'sslinfo';


#### Crear el usuario `conssl` para este ejemplo
    create user conssl with password '123123' superuser;


### Información importante 
Hay varias opciones de configurar los parámetros  ssl_ca_file y sslrootcert . esto depende como generaste tu certificado.
 ```markdown
****** Crear archivo combined.crt a veces tambien lo llaman full_chain.crt ********
 (cat /tmp/pki/CA/intermediate.crt /tmp/pki/CA/root.crt > /tmp/pki/CA/combined.crt)

  ### Opción #1 Si el archivo server.crt fue emitido por un intermediate.crt puedes usar esta tipo de configuración:
 	# ssl_ca_file = /tmp/pki/CA/combined.crt  y  sslrootcert = /tmp/pki/CA/root.crt

  ### Opción #2 Si el archivo server.crt fue emitido por un intermediate.crt puedes usar esta tipo de configuración:
        # ssl_ca_file = root.crt  Y sslrootcert = combined.crt

  ###  Si el server.crt fue emitido por el root.crt 
        # ssl_ca_file = root.crt  -> sslrootcert = root.crt

	### ** Verificación de la Cadena de Certificados:**   `root.crt`  → `intermedio.crt` →   `server.crt`



 ```


### [32.19.1. Verificación de certificados de servidor por parte del cliente](https://www.postgresql.org/docs/current/libpq-ssl.html#LIBQ-SSL-CERTIFICATES)
De forma predeterminada, PostgreSQL no realizará ninguna verificación del certificado del servidor. Esto significa que es posible falsificar la identidad del servidor (por ejemplo, modificando un registro DNS o apropiándose de la dirección IP del servidor) sin que el cliente lo sepa. Para evitar la suplantación, el cliente debe poder verificar la identidad del servidor a través de una cadena de confianza. Una cadena de confianza se establece colocando un certificado raíz (autofirmado) de una autoridad de certificación ( CA ) en una computadora y un certificado de hoja firmado por el certificado raíz en otra computadora. También es posible utilizar un certificado " intermedio " que esté firmado por el certificado raíz y firme los certificados de hoja.





# Fase #2 Implementación 

1. **Crear la extension en la Db postgres** 
   ```sql
   CREATE EXTENSION IF NOT EXISTS sslinfo ;
   ```

2. **Primera capa de seguridad nivel configuración ( Habilitar TLS en `postgresql.conf`)** 
   ```Markdown
   ssl = on
   ssl_cert_file = '/tmp/pki/certs/server.crt'
   ssl_key_file = '/tmp/pki/private/server.key'
   ```


3. **Segunda capa de seguridad nivel configuración ( forzar el uso de TLS en  `pg_hba.conf` )** 
   ```Markdown

   ## Parámetros de configuración en `pg_hba.conf`
     # hostssl -> Forza al cliente a usar una conexión cifrada en caso de que no rechaza la conexión
     # cert -> Esto es para que el cliente pueda usar un certificado para autenticarse en vez de una contraseña
     
   ### Opciones para clientes que autentican con certificado    
     # clientcert=1: solo verifica que el certificado del cliente esté firmado por una CA de confianza.
     # clientcert=verify-full: Además de requerir un certificado válido, verifica que el nombre del cliente en el certificado coincida con el nombre esperado.

   
   # TYPE  DATABASE        USER            ADDRESS                 METHOD
   hostssl   all           conssl        0.0.0.0/0               scram-sha-256 
   
   # Clientes con autenticación por certificado y no por contraseña
   hostssl   all           conssl        0.0.0.0/0               cert    clientcert=verify-full
   
   ```


4. **Tercera capa de seguridad nivel configuración ( Establecer version Minima y Máximo de TLS en  `postgresql.conf`)**
   ```Markdown
    ssl_min_protocol_version = 'TLSv1.2'
    ssl_max_protocol_version = 'TLSv1.3'   
   ```


5. **Cuarta capa de seguridad nivel configuración ( Restringir los cifrados inseguros en  `postgresql.conf`)**
 En entorno crítico como el bancario, donde se deben cumplir estrictas políticas de seguridad, es fundamental configurar el parámetro ssl_ciphers en PostgreSQL para asegurar el uso de suites de cifrado fuertes y seguras permitidas para las conexiones SSL.
   ```sql
   ssl_prefer_server_ciphers = on
   ssl_ciphers = 'HIGH:!aNULL:!MD5:!3DES:!RC4:!DES:!IDEA:!RC2' # Este para entornos Criticos (Bancos, Tiendas, Etc)
      # ssl_ciphers =  'HIGH:!MD5:!RC4:!3DES:!DES:!IDEA:!RC2:!SHA1:!NULL:!aNULL:!EXP' # aun mas exigentes que el primero
      # ssl_ciphers = 'HIGH:MEDIUM:!aNULL:!MD5:!RC4' # Este para entornos Normales

   	Explicación de la Configuración:
	HIGH: Incluye suites de cifrado de alta seguridad, como AES y Camellia.
	MEDIUM: Incluye suites de cifrado de seguridad media, como SEED.
	!aNULL: Excluye las suites de cifrado anónimas que no realizan autenticación.
	!MD5: Excluye las suites de cifrado que utilizan el algoritmo MD5, que es considerado inseguro.
	!RC4: Excluye RC4, ya que es un cifrado obsoleto y vulnerable.

   ```
   
 
7. **Quinta capa de seguridad nivel configuración ( Habilitar la revocación de certificados con crl en  `postgresql.conf` )**
   ```sql
   ssl_crl_file = '/tmp/pki/CA/combined.crl'
   ```

8. **Sexta capa de seguridad nivel configuración ( Verficiación de Certificados  `postgresql.conf` )** 
   ```sql
   #  Verifica que el certificado presentado por el cliente ha sido emitido por una CA de confianza. 
   # Esto se habilita si el cliente se autentica con certificados y usara las opciones sslmode=verify-ca o verify-full, para aumenta la seguridad, en caso de que el cliente no use certificado para autenticar no se ocupa configurar en este ejemplo si lo usaremos.
    ssl_ca_file = '/tmp/pki/CA/combined.crt' # Incluye Root + Intermedia
   ```
   
9. Validar si configuramos el archivo  `postgresql.conf y pg_hba.conf`
   ```sql
     # En caso de arrojar algun registro , es porque algo esta mal configurado
    select * from pg_catalog.pg_file_settings where error is not null; -- postgresql.conf
    select * from pg_hba_file_rules where error is not null;  -- pg_hba.conf 
   ```
 
 

10. Recargar archivo de configuración 
   ```sql
   /usr/pgsql-16/bin/pg_ctl reload -D /sysx/data
   ```

1. Validar si el log arroja algun error 
   ```sql
    # En caso de encontrar algun error hay que corregir 
   grep -A 14 -Ei "SIGHUP|reload" postgresql-250214.log
   ```


1. **Preparar el entorno del cliente para su conexion**
   `[NOTA] -> En nuestro caso realizaremos las pruebas en el mismo servidor donde tenemos postgresql`
   ```sql
    # Tienes que enviarle los archivos 
    scp  /tmp/pki/certs/client.crt   /tmp/pki/private/client.key  /tmp/pki/CA/root.crt  192.100.8.162:/tmp

   # esto lo puedes hacer en caso de que no quieras colocar los parametros de sslrootcert sslcert ,  sslkey , postgresql lo detecta de manera auotmatica 
   mkdir ~/.postgresql
   cp client.crt client.key root.crt .postgresql/
   cd ~/.postgresql
   mv client.crt postgresql.crt
   mv client.key postgresql.key

   	sudo chown postgres:postgres  postgresql.crt
	sudo chown postgres:postgres  postgresql.key
	sudo chmod 600 postgresql.key
	sudo chmod 600 postgresql.crt
   ```

 

1. **Primera capa de seguridad nivel Usuario ( Conexión con sslmode=verify-ca )**
   [32.1.1. Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)
   ```sql
    psql "host=127.0.0.1  port=5416  user=conssl dbname=postgres sslmode=verify-ca  sslrootcert=/tmp/pki/CA/combined.crt"
   
     ### Resultado esperado ->  SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off
   ```
 

1. **Segunda capa de seguridad nivel Usuario ( Conexión con sslmode=verify-full )** 
   ```sql
   psql "host=127.0.0.1  port=5416  user=conssl dbname=postgres sslmode=verify-full  sslrootcert=/tmp/pki/CA/combined.crt"

      ### Resultado esperado ->  SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off

   ## En caso de colocar otra ip o otro dominio/subdominio diferente al que se coloco en el Common Name (CN) o Subject Alternative Names (SAN) del certificado server.crt :
   ## psql: error: connection to server at "192.168.0.100", port 5416 failed: server certificate for "127.0.0.1" does not match host name "192.168.0.100"
   
   ```

1. **Tercera capa de seguridad nivel Usuario ( Usar Certificado para autenticarse )**
El Mutual Transport Layer Security (mTLS) es un protocolo de seguridad que extiende el TLS tradicional para requerir autenticación bidireccional
   ```sql
    # Se conectara directo  
   psql "host=127.0.0.1  port=5416  user=conssl dbname=postgres sslmode=verify-full  sslrootcert=/tmp/pki/CA/combined.crt  sslcert=/tmp/pki/certs/client.crt sslkey=/tmp/pki/private/client.key"

   # Si colocas otros usuario aparecera esto : 
      #psql: error: connection to server at "127.0.0.1", port 5416 failed: FATAL:  certificate authentication failed for user "otros"

   # En caso de quererte conectatar usando un certificado revocado aparecera este mensaje al cliente : 
      # psql: error: connection to server at "127.0.0.1", port 5416 failed: SSL error: sslv3 alert certificate revoked

   ```


# **Fase #3 Post-Implementación.** 

1. **Concideraciones entornos de productivos.** 
   ```markdown
   	--> Si el cliente no puede conectarse puedes ver considerar lo siguiente : 
	El cifrado utilizado en una conexión TLS depende de la versión de TLS que se esté utilizando. Con cada nueva versión de TLS, se introducen mejoras en seguridad y rendimiento, y a menudo se eliminan cifrados inseguros.
	
	### TLS 1.2
	- **Cifrados soportados**: TLS 1.2 soporta una amplia variedad de cifrados, incluyendo algunos que ya no se consideran seguros, como RC4 y AES-CBC.
	- **Configuración**: Es posible configurar TLS 1.2 para excluir cifrados inseguros y utilizar solo cifrados modernos y seguros, como AES-GCM.
	
	### TLS 1.3
	- **Cifrados soportados**: TLS 1.3 ha eliminado muchos de los cifrados inseguros y solo soporta cifrados modernos y seguros. Algunos de los cifrados eliminados incluyen RC4, AES-CBC y cualquier cifrado que no soporte AEAD (Authenticated Encryption with 			Associated Data).
	- **Mejoras**: TLS 1.3 también introduce un proceso de "handshake" más rápido y seguro, reduciendo la latencia y mejorando el rendimiento.
	
	### ¿Qué debe hacer el área de desarrollo en caso de conflictos?
	1. **Actualizar la Biblioteca de TLS**: Asegúrate de que la biblioteca de TLS utilizada por el cliente esté actualizada y sea compatible con TLS 1.2 o 1.3.
	3. **Verificar la Conexión**: Después de realizar las actualizaciones y configuraciones necesarias, verifica que el cliente pueda conectarse correctamente al servidor utilizando cifrados seguros.

 
   ```



2. **Monitoreo conexiónes que usan tls.** 
   ```sql
	1.- Validar las configuraciones si se hayan realizado los cambios 
	SELECT name, setting FROM pg_settings WHERE name LIKE '%ssl%';

	   2.- Validar que esten clientes conectados 
	   select
	        -- pg_sa.pid,
			pg_sa.state 
	    	,datname
	    	,pg_ssl.ssl
	    	,pg_ssl.version
	    	,pg_ssl.cipher
	    	--,pg_sa.backend_type
	    	,pg_sa.usename
	    	,pg_sa.client_addr
	    	,application_name
			--,backend_start
			--,query_start
	    from pg_stat_ssl pg_ssl
	    LEFT JOIN pg_stat_activity AS pg_sa ON pg_ssl.pid = pg_sa.pid
		where pg_sa.backend_type = 'client backend' 
			  AND pg_sa.pid <> pg_backend_pid()
			 --  AND ssl = false 
		order by pg_ssl.ssl,pg_sa.usename;

	+-------------+-----+---------+------------------------+----------------+----------+---------------+----------------------------+
	|   datname   | ssl | version |         cipher         |  backend_type  | usename  |  client_addr  |      application_name      |
	+-------------+-----+---------+------------------------+----------------+----------+---------------+----------------------------+
	| postgres    | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 | client backend | sysdbas  | 192.168.1.101 | pgAdmin 4 - DB:postgres   |
	| postgres    | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 | client backend | postgres | 192.168.1.102 | pgAdmin 4 - DB:postgres   |
	| postgres    | t   | TLSv1.3 | TLS_AES_256_GCM_SHA384 | client backend | postgres | 192.168.1.103 | pgAdmin 4 - CONN:7509538   |

   ```
   
3. **Validar la información de tls del lado del cliente** 
   ```sql

	select 
		ssl_is_used()
		,ssl_version() 
		,ssl_cipher()
		,ssl_client_cert_present()
		,ssl_client_serial()
	 	--,ssl_issuer_dn()
	 	,ssl_client_dn();

	+-[ RECORD 1 ]------------+-----------------------------------------------------------------+
	| ssl_is_used             | t                                                               |
	| ssl_version             | TLSv1.3                                                         |
	| ssl_cipher              | TLS_AES_256_GCM_SHA384                                          |
	| ssl_client_cert_present | t                                                               |
	| ssl_client_serial       | 94996677583678954084741597939484696981543727840                 |
	| ssl_client_dn           | /C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Depart |
	+-------------------------+-----------------------------------------------------------------+

   
   ```
 

4.-  Capturar el trafico para validar si esta cifrado
   ```bash
verificar si la comunicación de PostgreSQL está cifrada usando **Tcpdump**:

---

### **1 Crear una tabla de prueba**
	- Abrir una terminal  #1 creamos y insertamos y no nos salimos de la conexión
		[postgres@hostname_serv ~]$ psql -X  "sslmode=disable host=127.0.0.1  port=5416  user=sinssl dbname=postgres"
		Password for user sinssl:
		psql (17.2, server 16.6)
		Type "help" for help.
		
		db_test=# create temp table  clientes(numcli int,password text);
		CREATE TABLE
		db_test=# insert into clientes select 12345,'Passw0rd';
		INSERT 0 1
 
### **2. Capturar tráfico de red con Tcpdump**
Abrir otra terminal #2 y Ejecuta el siguiente comando para capturar el tráfico en el puerto de PostgreSQL (`5432` por defecto):
 
	sudo /sbin/tcpdump -i any -s 0 -A 'host 127.0.0.1 && tcp port 5416' 

1. **`sudo`**: Ejecuta el comando con privilegios de superusuario.
2. **`/sbin/tcpdump`**: Ejecuta la herramienta `tcpdump`, que captura y analiza el tráfico de red.
3. **`-i any`**: Captura paquetes en todas las interfaces de red.
4. **`-s 0`**: Captura el tamaño completo de cada paquete.
5. **`-A`**: Muestra los datos del paquete en formato ASCII.
6. **`'host 127.0.0.1 && tcp port 5416'`**: Filtra los paquetes para capturar solo aquellos que provienen o van hacia el host `127.0.0.1` (localhost) y que utilizan el puerto TCP `5416`.
7. **`| grep -Ei Passw0rd`**: Pasa la salida de `tcpdump` a `grep`, que busca de manera insensible a mayúsculas y minúsculas (`-i`) cualquier línea que contenga la palabra "Passw0rd".


---

### **3. Consultamos los datos**
	- Abrimos la terminal #1

	db_test=# select * from clientes; /*ESTE ES UN COMENTARIO*/
	 numcli | password
	--------+----------
	  12345 | Passw0rd



### **4.  Análisis del tráfico sin crifrar **
- Como vemos se expone la contraseña 
	[postgres@hostname_serv ~]$ sudo /sbin/tcpdump -i any -s 0 -A 'host 127.0.0.1 && tcp && port 5416'
	dropped privs to tcpdump
	tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
	listening on lo, link-type EN10MB (Ethernet), capture size 262144 bytes
	
	14:51:13.301877 IP localhost.58094 > localhost.sns-gateway: Flags [P.], seq 3141752243:3141752272, ack 2227224492, win 88, options [nop,nop,TS val 2307337496 ecr 2307293188], length 29
	E..Qwt@.@..0...........(.CU........X.E.....
	..-.....Q....select * from clientes;.
	14:51:13.302510 IP localhost.sns-gateway > localhost.58094: Flags [P.], seq 1:108, ack 29, win 86, options [nop,nop,TS val 2307337497 ecr 2307337496], length 107
	E...@h@.@............(.......CU....V.......
	..-...-.T...:..numcli..A.N..............password..A.N..............D..........12345....Passw0rdC....SELECT 1.Z....I
	14:51:13.302531 IP localhost.58094 > localhost.sns-gateway: Flags [.], ack 108, win 88, options [nop,nop,TS val 2307337497 ecr 2307337497], length 0
	E..4wu@.@..L...........(.CU........X.(.....
	..-...-.
	^C
	3 packets captured
	6 packets received by filter
	0 packets dropped by kernel


 ### **5.  Análisis del tráfico crifrado con tls activo **
	1.- En este caso nos conectamos de esta forma:
		psql "sslmode=prefer host=127.0.0.1  port=5416  user=conssl dbname=postgres"  
	2.- Creamos la tabla temporal
		create temp table  clientes(numcli int,password text);
	3.- Insertamos el registro
		insert into clientes select 12345,'Passw0rd';

	4.- sudo /sbin/tcpdump -i any -s 0 -A 'host 127.0.0.1 && tcp && port 5416'

	5.- Consultamos la tabla 
		select * from clientes; /*ESTE ES UN COMENTARIO*/
	6.- Analisamos el trafico.
		listening on any, link-type LINUX_SLL (Linux cooked v1), capture size 262144 bytes
		14:58:01.093659 IP localhost.5588 > localhost.sns-gateway: Flags [P.], seq 702641659:702641710, ack 539927623, win 351, options [nop,nop,TS val 2307745288 ecr 2307737001], length 51
		E..g..@.@._............().u. ..G..._.[.....
		..f...E........>.=......~....p~yn.O..k.V.....K.k3K|.{...."f
		14:58:01.094236 IP localhost.sns-gateway > localhost.5588: Flags [P.], seq 1:130, ack 51, win 92, options [nop,nop,TS val 2307745289 ecr 2307745288], length 129
		E...iV@.@............(.. ..G).v....\.......
		..f     ..f.....|.~by....E..G ..uc...]X.;|..........F.!....;t.#...K...7........Y........O.BT.`....s.>k......q...hX./y.7.v.....Y.d.....%\.Y...
		14:58:01.094249 IP localhost.5588 > localhost.sns-gateway: Flags [.], ack 130, win 360, options [nop,nop,TS val 2307745289 ecr 2307745289], length 0
		E..4..@.@._............().v. ......h.(.....
		..f     ..f
		^C

 	7.- conclusion con el TLS activo no podemos ver la comunicación entre el cliente y servidor en texto plano
   ```

5.- Pruebas de cambio de certificado sin hacer reload 
   ```bash
	pg_ctl reload -D $PGDATA16
	
	### Cambios de nuevo Certificado 
	mv /tmp/pki/certs/server.crt  /tmp/pki/certs/server_ant.crt 
	mv /tmp/pki/private/server.key  /tmp/pki/private/server_ant.key
	
	mv /tmp/pki/certs/server2.crt  /tmp/pki/certs/server.crt 
	mv /tmp/pki/private/server2.key  /tmp/pki/private/server.key
	
	psql "host=127.0.0.1  port=5416  user=conssl dbname=postgres sslmode=verify-full  sslrootcert=/tmp/pki/CA/intermediate_root.crt  sslcert=/tmp/pki/certs/client_new.crt sslkey=/tmp/pki/private/client_new.key"
	
	
	
	pg_ctl reload -D $PGDATA16
	
	### Regresando como estaba
	mv /tmp/pki/certs/server.crt  /tmp/pki/certs/server2.crt 
	mv /tmp/pki/private/server.key  /tmp/pki/private/server2.key
	
	mv /tmp/pki/certs/server_ant.crt  /tmp/pki/certs/server.crt 
	mv /tmp/pki/private/server_ant.key  /tmp/pki/private/server.key
	 
	psql "host=127.0.0.1  port=5416  user=conssl dbname=postgres sslmode=verify-full  sslrootcert=/tmp/pki/CA/intermediate_root.crt  sslcert=/tmp/pki/certs/client_new.crt sslkey=/tmp/pki/private/client_new.key"

   ```



# Conceptos información extra


### Mensajes de Error 
```markdown
#1 El error del cliente **`tlsv1 alert unknown ca`** 
indica que el servidor PostgreSQL no reconoce la CA (Autoridad de Certificación) que emitió el certificado del cliente. Esto suele ocurrir cuando la cadena de confianza no está correctamente configurada. Aquí está la solución paso a paso:
 

### **1. Verificar la cadena de certificados (Root e Intermedia)**
- **Error común**: Si tu servidor solo tiene el certificado de la **CA raíz** (`root.crt`) en `ssl_ca_file`, pero el certificado del cliente fue emitido por una **CA intermedia**, el servidor no reconocerá al cliente porque falta el certificado de la CA intermedia en su cadena de confianza.

#### **Solución**:
   - Crea un archivo que combine el certificado de la **CA raíz** y la **CA intermedia**:
     ```bash
     cat /tmp/pki/CA/root.crt /tmp/pki/CA/intermediate.crt > /tmp/pki/CA/combined.crt
     ```
   - Configura `ssl_ca_file` en `postgresql.conf` para usar este archivo combinado:
     ```ini
     ssl_ca_file = '/tmp/pki/CA/ca-chain.crt' # Incluye Root + Intermedia
     ```

 
#2 Error en log **`certificate verify failed at depth 1`**  
 
En una arquitectura de PKI (Public Key Infrastructure) con CA intermedio, necesitas manejar la revocación en ambos niveles por una razón importante:


1. Cuando usas un CA intermedio, tienes una cadena de confianza:
   Root CA -> Intermediate CA -> Client/Server Certificates

2. Cuando PostgreSQL verifica un certificado, verifica toda la cadena de confianza, y necesita comprobar:
   - Que el certificado del cliente no está revocado (usando el CRL del CA intermedio)
   - Que el certificado del CA intermedio no está revocado (usando el CRL del Root CA)


Por eso ves el error "certificate verify failed at depth 1" - está fallando en el nivel del CA intermedio (depth 1), porque PostgreSQL está intentando verificar si el propio certificado intermedio está revocado.



#3   **Error: "certificate verify failed"**
- **Causa**: El cliente no reconoce la CA que firmó el certificado del servidor.  
- **Solución**: Asegúrate de que el cliente tenga el `root.crt` correcto y que la ruta en `sslrootcert` sea válida.

#4 **Error: "hostname does not match certificate"**
- **Causa**: Te conectas usando un nombre (ej: IP) que no está en el certificado.  
- **Solución**:  
  - Conéctate usando el **hostname exacto** del certificado.  
  - O emite un certificado con el nombre/IP correcto en el campo **SAN (Subject Alternative Name)**.

	Validar que el nombre del servidor coincide**
	- Asegúrate de que el **nombre del servidor** (hostname) al que te conectas (ej: `mi-servidor-postgres.com`) coincida exactamente con el **Common Name (CN)** o **Subject Alternative Names (SAN)** del certificado del servidor.  
	  - Si el certificado está emitido para `mi-servidor-postgres.com`, pero te conectas usando la dirección IP (ej: `192.168.1.100`), la validación fallará.
	


```





### [Parámetros del lado del cliente ](https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION)

```sql

sslrootcert -> Para verificar que el certificado que proporciona el servidor fue emitido por una CA confiable. Protege contra servidores falsos. por ejemplo esto lo hace comparando el certificado "server.crt"  que  proporcionado por el servidor  con el root.crt que tiene el cliente y se especifico en este parámetro

sslcert -> Para identificarse con certificado si se usa autenticación por certificado.
sslkey -> Clave privada que acompaña al sslcert para probar que el cliente es el dueño del certificado.

-------------------------------------------------

El modo define el nivel de seguridad y verificación de certificados durante la conexión SSL/TLS.

### **Diagrama de Seguridad**

	Seguridad Baja → Alta
	disable → allow → prefer → require → verify-ca → verify-full
 
- **`disable`**: Conexión **sin cifrado**. Ignora SSL/TLS.
  - **Cuándo usar**: En entornos locales sin datos sensibles (ej: testing).
  - **Cuándo NO usar**: En redes públicas o con datos críticos.

- **`allow`**: Intenta conexión sin SSL primero. Si falla, intenta con SSL.
  - **Cuándo usar**: En migraciones o para compatibilidad con clientes antiguos.
  - **Cuándo NO usar**: Casi nunca, ya que es un modo inseguro por defecto.

- **`prefer`**: Intenta conexión **con SSL** primero. Si falla, usa sin cifrado.
  - **Página oficial (libpq-ssl) dice:** El valor predeterminado sslmode es  prefer.  esto no tiene sentido desde el punto de vista de la seguridad y solo promete una sobrecarga de rendimiento si es posible. Solo se proporciona como valor predeterminado para compatibilidad con versiones anteriores y no se recomienda en implementaciones seguras.

  - **Cuándo usar**: En entornos mixtos donde no todos soportan SSL.
  - **Cuándo NO usar**: Cuando se requiera seguridad garantizada.

- **`require`**: **Obliga SSL**, pero **no verifica el certificado del servidor** (sin autenticación).
  - **Cuándo usar**: Para conexiones rápidas con cifrado básico.
  - **Cuándo NO usar**: Si el servidor usa certificados autofirmados no confiables.

- **`verify-ca`**: Obliga SSL y **valida que el certificado del servidor está firmado por una CA confiable**, pero no verifica el nombre del dominio o ip al que se conecta.
  - **Cuándo usar**: Cuando se confía en la CA pero el host puede variar (ej: IP dinámica).


- **`verify-full`**: Obliga SSL, **valida la CA y el nombre del host** en el certificado. Máxima seguridad.
  - **Cuándo usar**: En entornos productivos (ej: servidores en la nube).
	
	1. **Verificación de la cadena de certificados**: El cliente verifica que el certificado del servidor esté firmado por una autoridad certificadora (CA) de confianza. Esto se hace utilizando el archivo especificado en `sslrootcert`, que contiene el certificado 	raíz de la CA. Esta verificación asegura que el certificado del servidor es auténtico y no ha sido emitido por una entidad no confiable.
	
	2. **Verificación del nombre del servidor**: El cliente también verifica que el nombre del servidor (hostname) al que se está conectando coincida con el nombre común (Common Name, CN) o uno de los nombres alternativos del sujeto (Subject Alternative Names, SAN) 	en el certificado del servidor. Esto asegura que el cliente se está conectando al servidor correcto y no a un servidor malicioso.

```


 
### [Parámetros del lado del servidor](https://www.postgresql.org/docs/current/runtime-config-connection.html#RUNTIME-CONFIG-CONNECTION-SSL)
```sql
1. ssl

	¿Para qué sirve? Habilita o deshabilita SSL en PostgreSQL.
	Uso recomendado: Si deseas encriptar las conexiones entre clientes y el servidor para mayor seguridad.

2. ssl_ca_file
	¿Para qué sirve? Especifica la ubicación del archivo de la Autoridad de Certificación (CA) y el servidor lo utiliza para verificar el certificado de autenticacion que le proporciona el cliente y validar que sea valido, es como hacer esto "openssl verify -CAfile /tmp/pki/CA/root.crt /tmp/pki/CA/intermediate.crt"
	Uso recomendado: solo cuando usar el sslmode verify-full  o verify-ca

3. ssl_cert_file
	¿Para qué sirve? Define la ruta del certificado SSL del servidor PostgreSQL.
	Uso recomendado: Siempre que uses SSL para conexiones seguras.


4. ssl_ciphers
	¿Para qué sirve?  Define qué algoritmos de cifrado (cipher suites) están permitidos para conexiones SSL/TLS.
			  Filtra los cipher suites que el servidor está dispuesto a usar.
	Uso recomendado: Para restringir los cifrados inseguros y mejorar la seguridad.
	Ejemplo: HIGH:!aNULL:!MD5 (solo cifrados fuertes).

	# TLS 1.3 
	TLS_AES_256_GCM_SHA384
	
	# TLS 1.2 
	ECDHE-RSA-AES256-GCM-SHA384

5. ssl_crl_dir
	¿Para qué sirve? Especifica un directorio donde se almacenan listas de revocación de certificados (CRL).
	Uso recomendado: Si manejas muchas CRL en un entorno de certificados que expiran o pueden ser revocados.
	¿Cuándo se usa?:  se usa cuando los clientes utilizan certificados SSL para autenticarse, no contraseñas.
			Este archivo contiene una lista de certificados que han sido revocados por la autoridad
			certificadora (CA) antes de su fecha de expiración, generalmente porque se han comprometido
			 o ya no son confiables.

6. ssl_crl_file
	¿Para qué sirve? Especifica un archivo con la lista de revocación de certificados (CRL).
	Uso recomendado: Si necesitas invalidar certificados que han sido comprometidos o revocados.

7. ssl_dh_params_file
	¿Para qué sirve? Especifica un archivo con parámetros de Diffie-Hellman personalizados para mejorar la seguridad de las claves compartidas.
	Uso recomendado: Cuando necesitas un mayor control sobre el intercambio de claves en SSL.


8. ssl_ecdh_curve
	¿Para qué sirve? Define la curva elíptica usada para el intercambio de claves ECDH.	
	Uso recomendado: Cuando usas cifrados basados en curvas elípticas (como ECDHE).
	Valor por defecto: prime256v1.


9. ssl_key_file
	¿Para qué sirve? Especifica la ruta del archivo de clave privada del servidor SSL.
	Uso recomendado: Siempre que uses SSL en PostgreSQL.


10. ssl_library
	¿Para qué sirve? Indica qué biblioteca SSL está en uso (OpenSSL por defecto).
	Uso recomendado: Solo si quieres asegurarte de qué implementación de SSL está activa.

11. ssl_max_protocol_version
	¿Para qué sirve? Especifica la versión máxima de SSL/TLS permitida en las conexiones.
	Uso recomendado: Para evitar el uso de versiones no compatibles o vulnerables.
	Ejemplo: TLSv1.3.

12. ssl_min_protocol_version
	¿Para qué sirve? Define la versión mínima de SSL/TLS permitida.
	Uso recomendado: Para obligar a los clientes a usar protocolos seguros (ejemplo: evitar TLSv1.0).
	Ejemplo recomendado: TLSv1.2.

13. ssl_passphrase_command
	¿Para qué sirve? Especifica un comando que se ejecutará para obtener la contraseña de la clave privada SSL.
	Uso recomendado: Si la clave privada está protegida con contraseña.


14. ssl_passphrase_command_supports_reload
	¿Para qué sirve? Indica si PostgreSQL puede recargar la clave privada sin reiniciar el servidor.
	Uso recomendado: Para minimizar interrupciones al actualizar certificados.


15. ssl_prefer_server_ciphers
	¿Para qué sirve? Indica quién tiene prioridad al elegir el cipher suite durante el handshake TLS:
			 Si está en on: el servidor impone su orden de preferencia de ciphers (según ssl_ciphers).
			 Si está en off: el cliente puede elegir el cipher suite que prefiera, siempre que esté permitido.
	Uso recomendado: Para asegurar que se usen cifrados seguros definidos por el servidor.
```

### Funciones de la extension sslinfo
```
1.- Información sobre la Conexión SSL:
	 select ssl_is_used(): Devuelve verdadero si la conexión actual utiliza SSL.

2.- Información sobre Certificados:
 	select ssl_client_cert_present(): Indica si el cliente actual presentó un certificado SSL válido al servidor.
 	select ssl_client_serial(): Devuelve el número de serie del certificado del cliente.
 	select ssl_client_dn_field(fieldname text): Proporciona un campo específico del nombre del cliente 

3.- Información sobre la Conexión del Servidor:
 	select  ssl_version(): Retorna el nombre del protocolo utilizado para la conexión SSL (por ejemplo, TLSv1.2).
 	select ssl_cipher(): Proporciona el nombre del cifrado utilizado (por ejemplo, DHE-RSA-AES256-SHA).
 	select ssl_issuer_dn(): Retorna el nombre completo del emisor del certificado del cliente.
 	select ssl_client_dn(): Ofrece el nombre completo del sujeto del certificado del cliente.
```

### Configuración extra en postgresql
En caso de que la llave privada este protegida con una contraseña , es necesario que cuando reinicien el servidor el administrador tenga que colocar la contraseña , por lo que esto puede ser algo tedioso cuando se administran varios servidores por lo que se pueden habilitar estos parametros para que obtenga la contraseña de alguna parte segura como un la coloque de ser necesario.
```
	ssl_passphrase_command_supports_reload = on
	ssl_passphrase_command = '/path/to/get_passphrase.sh'	
```


## Mensajes de error en el log
```
*************** Mensaje de postgresql cuando usas una version no permitida  *****************


<2025-07-07 14:17:30 MST 127.0.0.1(63686) [unknown] [unknown] [unknown] 1777790 686c396a.1b207e >LOG:  connection received: host=127.0.0.1 port=63686
<2025-07-07 14:17:30 MST 127.0.0.1(63686) [unknown] [unknown] [unknown] 1777790 686c396a.1b207e >LOG:  could not accept SSL connection: unsupported protocol
<2025-07-07 14:17:30 MST 127.0.0.1(63686) [unknown] [unknown] [unknown] 1777790 686c396a.1b207e >HINT:  This may indicate that the client does not support any SSL protocol version between TLSv1.2 and TLSv1.3.

*************** Mensaje de postgresql cuando usas cipher ecluido  *****************

<2025-07-07 14:19:12 MST 127.0.0.1(3152) [unknown] [unknown] [unknown] 1778672 686c39d0.1b23f0 >LOG:  connection received: host=127.0.0.1 port=3152
<2025-07-07 14:19:12 MST 127.0.0.1(3152) [unknown] [unknown] [unknown] 1778672 686c39d0.1b23f0 >LOG:  could not accept SSL connection: no shared cipher
```

