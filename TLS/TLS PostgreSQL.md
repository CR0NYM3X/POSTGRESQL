 

# Pasos para implementar TLS en Postgresql


##  Paso 1: generar certificados para PostgreSQL 
```Markdown

### 1: Crear un certificado raíz
1. **Comando**: `openssl req -new -x509 -nodes -out root.crt -keyout root.key -subj "/CN=CA Root"`
   - **Qué hace**: Este comando crea un certificado raíz (root.crt) y una clave privada (root.key).
   - **Explicación**: Piensa en el certificado raíz como la "autoridad" que va a firmar otros certificados. La clave privada es como una contraseña que solo la autoridad conoce. 
   - **root.crt**: Este es el **certificado raíz** de la autoridad certificadora (CA). Se utiliza para verificar la autenticidad de los certificados emitidos por la CA.
   - **root.key**: Esta es la **clave privada** de la CA. Se utiliza para firmar los certificados que la CA emite, asegurando que son auténticos y confiables.
  	 
	----- segunda opcion/ aqui tu generas una paswd para el root ---
   
  	 openssl genrsa -aes128  -out root.key 2048 -- Genera una clave privada para tu CA | . Si no generas una clave privada   La clave privada es esencial para la firma de certificados,
  	 openssl rsa -in root.key -out root.key
  	 chmod 400 root.key
  	 openssl req -new -x509 -key root.key -out root.crt -subj '/CN=CA Root' --- Crea un certificado autofirmado para tu CA:
  	  
  	
 
### 2: Crear un certificado para el servidor

2.1 **Generar una solicitud de certificado para el servidor**
   - **Comando**: `openssl req -new -nodes -out server.csr -keyout server.key -subj "/C=US/ST=California/L=Los Angeles/O=Mi Organización/OU=Mi Unidad/CN=127.0.0.1"`
   - **Qué hace**: Crea una solicitud de certificado (server.csr) y una clave privada (server.key) para el servidor.
   - **Explicación**: La solicitud de certificado es como pedir un permiso para que el servidor sea reconocido como seguro. La clave privada es la contraseña del servidor.
   - **server.csr**: Este es el **Certificate Signing Request** (Solicitud de Firma de Certificado). Es un archivo que contiene información sobre el servidor y se envía a la CA para solicitar un certificado.
   - **server.key**: Esta es la **clave privada** del servidor. Se utiliza para cifrar la comunicación entre el servidor y los clientes.

	### Información Solicitada en un CSR
	
	1. **Nombre Común (Common Name)**: El nombre de dominio completo (FQDN) para el cual se emitirá el certificado, por ejemplo, `www.tusitio.com`.
	2. **Organización (Organization)**: El nombre legal completo de tu organización.
	3. **Unidad Organizativa (Organizational Unit)**: El departamento dentro de la organización que solicita el certificado, como "IT" o "Seguridad".
	4. **Ciudad o Localidad (Locality)**: La ciudad donde se encuentra tu organización.
	5. **Estado o Provincia (State or Province)**: El estado o provincia donde se encuentra tu organización.
	6. **País (Country)**: El código de dos letras del país donde se encuentra tu organización, por ejemplo, "MX" para México.
 

2.2 **Firmar la solicitud del servidor con el certificado raíz**
   - **Comando**: `openssl x509 -req -in server.csr -CA root.crt -CAkey root.key -CAcreateserial -out server.crt`
   - **Qué hace**: Firma la solicitud del servidor (server.csr) con el certificado raíz (root.crt) y la clave privada del certificado raíz (root.key), creando el certificado del servidor (server.crt).
   - **Explicación**: Es como si la autoridad (certificado raíz) aprobara y firmara el permiso del servidor, diciendo "este servidor es seguro".
   - **server.crt**: Este es el **(Clave pública) certificado del servidor**. Es emitido por la CA y  Se usa para descifrar la información.

  
### 3: Crear un certificado para el cliente
3.1 **Generar una solicitud de certificado para el cliente**
   - **Comando**: `openssl req -new -nodes -out client.csr -keyout client.key -subj "/CN=sys_user_test"`
   - **Qué hace**: Crea una solicitud de certificado (client.csr) y una clave privada (client.key) para el cliente.
   - **Explicación**: Similar al servidor, pero esta vez es para el cliente. La solicitud de certificado es el permiso y la clave privada es la contraseña del cliente.

3.2 **Firmar la solicitud del cliente con el certificado raíz**
   - **Comando**: `openssl x509 -req -in client.csr -CA root.crt -CAkey root.key -CAcreateserial -out client.crt`
   - **Qué hace**: Firma la solicitud del cliente (client.csr) con el certificado raíz (root.crt) y la clave privada del certificado raíz (root.key), creando el certificado del cliente (client.crt).
   - **Explicación**: La autoridad (certificado raíz) aprueba y firma el permiso del cliente, diciendo "este cliente es seguro".



### 4: Limpiar archivos temporales
- **Comando**: `rm *.csr` y `rm *.srl`
  - **Qué hace**: Elimina los archivos de solicitud de certificado (.csr) y los archivos de serial (.srl) utilizada para llevar un registro de los certificados emitidos y revocados. que ya no son necesarios.
  
 
### 5: Otorgar permisos de lectura a certificados
- **Comando**: `chmod 400 *.{key,crt}`
  - **Qué hace**: Cambia los permisos de los archivos de clave (.key) y certificado (.crt) para que solo el propietario pueda leerlos.
  - **Explicación**: Es como poner una cerradura en los archivos para que nadie más pueda acceder a ellos.


### 6: Verificar los certificados
- **Comando**: `openssl verify -CAfile root.crt client.crt` y `openssl verify -CAfile root.crt server.crt`
  - **Qué hace**: Verifica que los certificados del cliente (client.crt) y del servidor (server.crt) sean válidos y estén firmados por el certificado raíz (root.crt).
  - **Explicación**: Es como comprobar que los permisos del cliente y del servidor son auténticos y aprobados por la autoridad.
  [NOTA] si todo esta bien retorna esto "server.crt: OK" o "client.crt: OK"


## **Verifica el certificado del servidor**
- Validar si un servidor esta f
- **Comando**: openssl s_client -connect db.example.com:5432 -starttls postgres

## **Ver los detalles de los certificados**
- **Comando**:  openssl x509 -in server.crt -text -noout

 ```



## Paso 2: Configurar los parámetros en postgresql.conf 
```Markdown
## Editar los parámetros en `postgresql.conf`
 

ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_min_protocol_version = 'TLSv1.2'
ssl_max_protocol_version = 'TLSv1.3'
ssl_prefer_server_ciphers = on
ssl_ciphers = 'HIGH:!aNULL:!MD5:!3DES:!RC4:!DES:!IDEA:!RC2' # Este para entornos Criticos
###  ssl_ciphers = 'HIGH:MEDIUM:!aNULL:!MD5:!RC4' # Este para entornos Normales

```




## Paso 3: Configurar los parámetros en pg_hba.conf
```Markdown
## Parámetros de configuración en `pg_hba.conf`
hostssl -> Forza al cliente a usar una conexión cifrada en caso de que no rechaza la conexión
cert -> Esto es para que el cliente pueda usar un certificado para autenticarse en vez de una contraseña


### Opciones para clientes que autentican con certificado 

clientcert=1: solo verifica que el certificado del cliente esté firmado por una CA de confianza.
clientcert=verify-ca: proporciona un nivel adicional de seguridad al verificar toda la cadena de certificados.
clientcert=verify-full: Además de requerir un certificado válido, verifica que el nombre del cliente en el certificado coincida con el nombre esperado.

 
### Editar el archivo `pg_hba.conf`

# TYPE  DATABASE        USER            ADDRESS                 METHOD
hostssl   all           sys_user_test   0.0.0.0/0               scram-sha-256 

# Clientes con autenticación por certificado y no por contraseña
hostssl   all           sys_user_test   all                     cert
hostssl   all           sys_user_test   0.0.0.0/0               cert    clientcert=1
```

## Paso 4: Reiniciar las configuraciones de postgresql 
```
# Realizar un reinicio.
 /usr/pgsql-15/bin/pg_ctl reload  -D /sysx/data
```


##   Paso 5: pasar los archivos al clientes   
```
 scp client.crt   client.key root.crt  192.100.8.162:/tmp/encript
```



## Paso 6: Ejemplo de conexión del cliente
```Markdown
https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION

-- Preparar el entorno del cliente
mkdir ~/.postgresql
cp client.crt client.key root.crt .postgresql/
cd ~/.postgresql	
mv client.crt postgresql.crt
mv client.key postgresql.key



-- Ejemplos de conexión
psql "sslmode=verify-full host=192.100.68.94 port=5432  user=sys_user_test dbname=postgres"
psql "sslmode=verify-full host=192.100.68.94 port=5432  user=sys_user_test dbname=postgres sslrootcert=root.crt sslcert=client.crt sslkey=client.key"
psql -d postgres -U alejandro -p 5432 -h 192.100.68.94

--- Ejemplo intentando conectarme de forma insegura
psql "sslmode=disable host=192.100.68.94  port=5432  user=sys_user_test dbname=postgres"
psql: error: connection to server at "127.0.0.1", port 5416 failed: FATAL:  no pg_hba.conf entry for host "127.0.0.1", user "otheruser", database "centraldata", no encryption


-- Resultado esperado
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)



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
  - **Cuándo usar**: En entornos mixtos donde no todos soportan SSL.
  - **Cuándo NO usar**: Cuando se requiera seguridad garantizada.

- **`require`**: **Obliga SSL**, pero **no verifica el certificado del servidor** (sin autenticación).
  - **Cuándo usar**: Para conexiones rápidas con cifrado básico.
  - **Cuándo NO usar**: Si el servidor usa certificados autofirmados no confiables.

- **`verify-ca`**: Obliga SSL y **valida que el certificado del servidor está firmado por una CA confiable**, pero no verifica el nombre del host.
  - **Cuándo usar**: Cuando se confía en la CA pero el host puede variar (ej: IP dinámica).
  - **Cuándo NO usar**: Si el nombre del host debe coincidir exactamente (ej: dominio específico).

- **`verify-full`**: Obliga SSL, **valida la CA y el nombre del host** en el certificado. Máxima seguridad.
  - **Cuándo usar**: En entornos productivos (ej: servidores en la nube).
  - **Cuándo NO usar**: Nunca evitarlo en casos críticos.

```

## Paso 7: Validar si las conexiones estan usando TLS

```sql
1.- Validar las configuraciones si se hayan realizado los cambios 
SELECT name, setting FROM pg_settings WHERE name LIKE '%ssl%';
 
2.- Validar que esten clientes conectados 
select   datname ,pg_ssl.ssl, pg_ssl.version,  pg_sa.backend_type, pg_sa.usename, pg_sa.client_addr , application_name from pg_stat_ssl pg_ssl  join pg_stat_activity pg_sa  on pg_ssl.pid = pg_sa.pid;

-- Ejemplo de resultado esperado
 datname  | ssl | version |  backend_type  |  usename  | client_addr | application_name
----------+-----+---------+----------------+-----------+-------------+------------------
 postgres | t   | TLSv1.3 | client backend | alejandro | 192.100.8.162 | psql
 postgres | f   |         | client backend | postgres  |             | psql
```

## Paso 8: Capturar el trafico para validar si esta cifrado
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


 ### **5.  Análisis del tráfico crifrado **
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

 	7.- conclusion con el TLS activo no podemos analizar el trafico

```



## INFO EXTRA
```
https://www.postgresql.org/docs/current/sslinfo.html



 
Parámetros y sus usos:

1. ssl

	¿Para qué sirve? Habilita o deshabilita SSL en PostgreSQL.
	Uso recomendado: Si deseas encriptar las conexiones entre clientes y el servidor para mayor seguridad.

2. ssl_ca_file
	¿Para qué sirve? Especifica la ubicación del archivo de la Autoridad de Certificación (CA) que se usa para verificar los certificados de los clientes.
	Uso recomendado: solo cuando usar el sslmode verify-full  o verify-ca

3. ssl_cert_file
	¿Para qué sirve? Define la ruta del certificado SSL del servidor PostgreSQL.
	Uso recomendado: Siempre que uses SSL para conexiones seguras.


4. ssl_ciphers
	¿Para qué sirve? Permite definir qué conjuntos de cifrados (cipher suites) se pueden usar en las conexiones SSL.
	Uso recomendado: Para restringir los cifrados inseguros y mejorar la seguridad.
	Ejemplo: HIGH:!aNULL:!MD5 (solo cifrados fuertes).

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
	¿Para qué sirve? Si está en on, el servidor define qué cifrado usar en lugar del cliente.
	Uso recomendado: Para asegurar que se usen cifrados seguros definidos por el servidor.



******************************************************************************************************************

CREATE EXTENSION IF NOT EXISTS sslinfo ;

1.- Información sobre la Conexión SSL:
	select ssl_is_used(): Devuelve verdadero si la conexión actual utiliza SSL.

2.- Información sobre Certificados:
	ssl_client_cert_present(): Indica si el cliente actual presentó un certificado SSL válido al servidor.
	ssl_client_serial(): Devuelve el número de serie del certificado del cliente.
	ssl_client_dn_field(fieldname text): Proporciona un campo específico del nombre del cliente 

3.- Información sobre la Conexión del Servidor:
	select ssl_version(): Retorna el nombre del protocolo utilizado para la conexión SSL (por ejemplo, TLSv1.2).
	ssl_cipher(): Proporciona el nombre del cifrado utilizado (por ejemplo, DHE-RSA-AES256-SHA).
	ssl_issuer_dn(): Retorna el nombre completo del emisor del certificado del cliente.
	ssl_client_dn(): Ofrece el nombre completo del sujeto del certificado del cliente.

******************************************************************************************************************
 
 -------- Empresan que emiten Certificados C.A 
 Let's Encrypt: Es una autoridad de certificación gratuita y automatizada que emite certificados SSL/TLS de forma gratuita. Es ampliamente utilizada para proporcionar certificados SSL/TLS en sitios web.

Comodo CA (ahora Sectigo): Es una de las mayores autoridades de certificación del mundo, que ofrece una amplia gama de certificados SSL/TLS y servicios de seguridad en línea.

DigiCert: Es otra de las principales autoridades de certificación, que ofrece certificados SSL/TLS de alta calidad y soluciones de seguridad de confianza.

GoDaddy: Aunque es conocido principalmente como un registrador de dominios, GoDaddy también ofrece servicios de certificados SSL/TLS.

GlobalSign: Es una autoridad de certificación global que proporciona una variedad de certificados SSL/TLS y soluciones de seguridad en línea.




-*-*-*-*-*-*-*-*-*--*-*-*-*-*-*-*-*-*-  opciones secundarias para generar certificados firmados   : -*-*-*-*-*-*-*-*-*- -*-*-*-*-*-*-*-*-*- 

 

 ######### LINUX CA (CERTIFICADOS ) #########
 
 
# Paso 1: Generar la CA (autoridades de certificación de confianza.) 
	 - Genera una clave privada para la CA:
			openssl genpkey -algorithm RSA -out ca.key
	 - Crea un certificado autofirmado para la CA:
			openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt -subj "/CN=Root CA"

Paso 2: Generar certificados confianza para el servidor y el cliente

	- Genera una clave privada para el servidor:
		openssl genpkey -algorithm RSA -out server.key
	- Crea una solicitud de firma de certificado (CSR) para el servidor:
		openssl req -new -key server.key -out server.csr -subj "/CN=127.0.0.1"
	- Firma el certificado del servidor con la CA:
		openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -sha256
		
		
	- Genera una clave privada para el cliente:
		openssl genpkey -algorithm RSA -out client.key
	- Crea una solicitud de firma de certificado (CSR) para el cliente  
		openssl req -new -key client.key -out client.csr -subj "/CN=endy"
	- Firma el certificado del cliente con la CA:
		openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365 -sha256



	- Eliminar los archivos que no se ocupan 
		rm *.csr
		rm *.srl
		
		
		[(Certificate Signing Request - Solicitud de Firma de Certificado)]  contiene la solicitud de firma de certificado generada a partir de la clave privada , Esta solicitud incluye información como el nombre común (CN), organización, país, etc. que será incluida en el certificado.
		
		[SRL (Serial - Serie):] - contiene el número de serie utilizado por la CA para firmar certificados. Este archivo se genera automáticamente por OpenSSL cuando se firma un certificado y se utiliza para mantener un registro de los números de serie utilizados.

	- dar permisos de lectura 
		chmod 400 *.{key,crt}


	- Validar que los certificados funcionen correctamente 
		 openssl verify -CAfile ca.crt client.crt
		 openssl verify -CAfile ca.crt server.crt
		




------------------ WINDOWS CA (CERTIFICADOS )  -------------


Paso 1: Generar la CA (Autoridad de Certificación de Confianza)
	- Generar una clave privada para la CA:
		certutil -generateKey -key "ca.key"

	- Crear un certificado autofirmado para la CA:
	certreq -new -x509 -key "ca.key" -out "ca.crt" -subj "/CN=Root CA" -config "ca.inf"


Paso 2: Generar certificados para el servidor  

	- Generar una clave privada para el servidor:
		certutil -generateKey -key "server.key"

	- Crear una solicitud de firma de certificado (CSR) para el servidor:
		certreq -new -key "server.key" -out "server.csr" -subj "/CN=10.30.68.94" -config "server.inf"


	- Firmar el certificado del servidor con la CA:
		certutil -sign "server.csr" -cert "ca.crt" -key "ca.key" -out "server.crt"



Paso 3: Generar certificados para  el cliente

	- Generar una clave privada para el cliente:
		certutil -generateKey -key "client.key"

	- Crear una solicitud de firma de certificado (CSR) para el cliente:
		certreq -new -key "client.key" -out "client.csr" -subj "/CN=alejandro" -config "client.inf"


	- Firmar el certificado del cliente con la CA:
		certutil -sign "client.csr" -cert "ca.crt" -key "ca.key" -out "client.crt"



```


## Bibliografias
```
## Manuales
https://postgresconf.org/system/events/document/000/001/285/PostgreSQL_and_SSL.pdf

### El mejor:
https://gist.github.com/achesco/b893fb55b90651cf5f4cc803b78e19fd

### Recursos adicionales

32.19. SSL Support  https://www.postgresql.org/docs/current/libpq-ssl.html
20.1. The pg_hba.conf File  https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
18.9. Secure TCP/IP Connections with SSL https://www.postgresql.org/docs/current/ssl-tcp.html

https://www.highgo.ca/2024/01/06/how-to-setup-tls-connection-for-postgresql/
https://access.redhat.com/documentation/fr-fr/red_hat_enterprise_linux/9/html/configuring_and_using_database_servers/proc_configuring-tls-encryption-on-a-postgresql-server_using-postgresql
https://www.cherryservers.com/blog/how-to-configure-ssl-on-postgresql
https://docs.cloudera.com/cdp-private-cloud-base/7.1.9/installation/topics/cdpdc-enable-tls-12-postgresql.html



## Referencias
https://docs.aws.amazon.com/es_es/cloudhsm/latest/userguide/ssl-offload-windows-create-csr-and-certificate.html
https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA10g000000Cm1eCAC&lang=es
https://docs.vmware.com/es/VMware-Horizon-7/7.13/horizon-scenarios-ssl-certificates/GUID-3A8CFE07-0A1A-4AB1-B2B6-41DA8E592EFB.html
https://www.nominalia.com/asistencia/como-instalar-un-certificado-ssl-en-windows-server-2016/
https://www.cisco.com/c/es_mx/support/docs/unified-communications/unified-communications-manager-callmanager/215534-create-windows-ca-certificate-templates.pdf
https://documentation.meraki.com/General_Administration/Other_Topics/Creating_an_Offline_Certificate_Request_in_Windows_Server
https://docs.citrix.com/es-es/xenmobile/server/authentication/client-certificate.html


```
