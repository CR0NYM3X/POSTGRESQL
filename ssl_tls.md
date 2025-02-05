
 
 
# Versiones de TLS que se pueden configurar

Documentación de PostgreSQL sobre SSL  
Configuración de conexión en PostgreSQL    
Configuración de versiones de protocolo SSL/TLS en PostgreSQL  

## Parámetro `ssl_min_protocol_version` (El valor predeterminado es TLSv1)

| Versión de PostgreSQL | Valores posibles para `ssl_min_protocol_version` |
|-----------------------|--------------------------------------------------|
| 10                    | No disponible                                    |
| 11                    | No disponible (puedes activar TLS pero no usa)   |
| 12                    | TLSv1.0, TLSv1.1, TLSv1.2, TLSv1.3               |
| 13                    | TLSv1.0, TLSv1.1, TLSv1.2, TLSv1.3               |
| 14                    | TLSv1.0, TLSv1.1, TLSv1.2, TLSv1.3               |
| 15                    | TLSv1.0, TLSv1.1, TLSv1.2, TLSv1.3               |
| 16                    | TLSv1.0, TLSv1.1, TLSv1.2, TLSv1.3               |
| 17                    | TLSv1.0, TLSv1.1, TLSv1.2, TLSv1.3               |

## Versiones compatibles de TLS para diferentes versiones de PostgreSQL (El valor predeterminado es TLSv1)

- **PostgreSQL 8.x**: Soporta TLS 1.0.
- **PostgreSQL 9.x**: Soporta TLS 1.0 y TLS 1.1.
- **PostgreSQL 10.x**: Soporta TLS 1.0, TLS 1.1.
- **PostgreSQL 11.x**: Soporta TLS 1.0, TLS 1.1.
- **PostgreSQL 12.x**: Soporta TLS 1.0, TLS 1.1, TLS 1.2 y TLS 1.3.
- **PostgreSQL 13.x**: Soporta TLS 1.0, TLS 1.1, TLS 1.2 y TLS 1.3.
- **PostgreSQL 14.x**: Soporta TLS 1.0, TLS 1.1, TLS 1.2 y TLS 1.3.
- **PostgreSQL 15.x**: Soporta TLS 1.0, TLS 1.1, TLS 1.2 y TLS 1.3.
- **PostgreSQL 16.x**: Soporta TLS 1.0, TLS 1.1, TLS 1.2 y TLS 1.3.
- **PostgreSQL 17.x**: Soporta TLS 1.0, TLS 1.1, TLS 1.2 y TLS 1.3.
 


# Pasos para implementar TLS en Postgresql


##  Paso 1: generar certificados para PostgreSQL 
```Markdown

### 1: Crear un certificado raíz
1. **Comando**: `openssl req -new -x509 -nodes -out root.crt -keyout root.key -subj "/CN=CA Root"`
   - **Qué hace**: Este comando crea un certificado raíz (root.crt) y una clave privada (root.key).
   - **Explicación**: Piensa en el certificado raíz como la "autoridad" que va a firmar otros certificados. La clave privada es como una contraseña que solo la autoridad conoce. 
   
  	 
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

2.2 **Firmar la solicitud del servidor con el certificado raíz**
   - **Comando**: `openssl x509 -req -in server.csr -CA root.crt -CAkey root.key -CAcreateserial -out server.crt`
   - **Qué hace**: Firma la solicitud del servidor (server.csr) con el certificado raíz (root.crt) y la clave privada del certificado raíz (root.key), creando el certificado del servidor (server.crt).
   - **Explicación**: Es como si la autoridad (certificado raíz) aprobara y firmara el permiso del servidor, diciendo "este servidor es seguro".

  
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
  - **Qué hace**: Elimina los archivos de solicitud de certificado (.csr) y los archivos de serial (.srl) que ya no son necesarios.
  


### 5: Proteger los archivos de clave y certificado
- **Comando**: `chmod 400 *.{key,crt}`
  - **Qué hace**: Cambia los permisos de los archivos de clave (.key) y certificado (.crt) para que solo el propietario pueda leerlos.
  - **Explicación**: Es como poner una cerradura en los archivos para que nadie más pueda acceder a ellos.

  
### 6: Verificar los certificados
- **Comando**: `openssl verify -CAfile root.crt client.crt` y `openssl verify -CAfile root.crt server.crt`
  - **Qué hace**: Verifica que los certificados del cliente (client.crt) y del servidor (server.crt) sean válidos y estén firmados por el certificado raíz (root.crt).
  - **Explicación**: Es como comprobar que los permisos del cliente y del servidor son auténticos y aprobados por la autoridad.
  [NOTA] si todo esta bien retorna esto "server.crt: OK" o "client.crt: OK"

## **Verifica el certificado del servidor**
- Deberías ver los detalles del certificado y la cadena de confianza.
- **Comando**: openssl s_client -connect db.example.com:5432 -starttls postgres
 ```



## Paso 2: Configurar los parámetros en postgresql.conf 
```Markdown
## Editar los parámetros en `postgresql.conf`

### Parámetros SSL

- **ssl**: Este parámetro determina si se habilita o no la capa de sockets seguros (SSL).
- **ssl_ca_file**: Especifica la ubicación del archivo de autoridad de certificación (CA) que se utilizará para verificar los certificados SSL presentados por los clientes.
- **ssl_cert_file**: Especifica la ubicación del archivo de certificado del servidor PostgreSQL. Este certificado se presenta a los clientes durante el proceso de autenticación SSL.
- **ssl_crl_file**: Especifica la ubicación del archivo de lista de revocación de certificados (CRL), si se utiliza, para verificar si los certificados SSL presentados por los clientes han sido revocados.
- **ssl_key_file**: Especifica la ubicación del archivo de clave privada del servidor PostgreSQL. Esta clave se utiliza para el intercambio de claves durante el proceso de autenticación SSL.
- **ssl_min_protocol_version**: Especifica la versión mínima del protocolo SSL/TLS que se aceptará para la comunicación segura.
- **ssl_max_protocol_version**: Especifica la versión máxima del protocolo SSL/TLS que se aceptará para la comunicación segura.
- **ssl_prefer_server_ciphers = on**: El servidor elige el cifrador preferido. Esto es útil si deseas que el servidor tenga control sobre la selección de cifradores para mejorar la seguridad.
- **ssl_prefer_server_ciphers = off**: El cliente elige el cifrador preferido. Esto puede ser útil si deseas que el cliente tenga control sobre la selección de cifradores, por ejemplo, para cumplir con requisitos específicos de seguridad del cliente.

### Ejemplo de configuración en `postgresql.conf`

 
listen_addresses = '*'
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_ca_file = 'root.crt'
ssl_min_protocol_version = 'TLSv1.3'
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL' # allowed SSL ciphers
ssl_prefer_server_ciphers = on
```




## Paso 3: Configurar los parámetros en pg_hba.conf
```Markdown
## Parámetros de configuración en `pg_hba.conf`

### Opciones de `clientcert`

- **clientcert=1**: Exige que el cliente presente un certificado válido y que este sea verificado por el servidor. Ideal para escenarios donde se requiere alta seguridad y autenticación mutua.
- **Sin clientcert=1**: Solo asegura que la conexión sea cifrada, sin requerir la verificación del certificado del cliente. Útil en escenarios donde el cifrado de la conexión es suficiente.

### Editar el archivo `pg_hba.conf`

 
# TYPE  DATABASE        USER            ADDRESS                 METHOD
hostssl   all           sys_user_test   all                      cert
hostssl   all           sys_user_test   0.0.0.0/0               scram-sha-256
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
```
https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION

-- Preparar el entorno del cliente
mkdir ~/.postgresql
cp client.crt client.key root.crt .postgresql/
cd ~/.postgresql	
mv client.crt postgresql.crt
mv client.key postgresql.key

-- Modos de SSL
sslmode=require   : Esto significa que la conexión debe ser cifrada, pero no se comprueba si el certificado del servidor es válido.  se recomienda solo para entornos de desarrollo o pruebas 
sslmode=verify-ca  :  verifica que el certificado del servidor esté firmado por una autoridad de certificación (CA) confiable. Sin embargo, no verifica que el nombre del servidor coincida con el nombre en el certificado 
sslmode=verify-full: verifica que el certificado del servidor esté firmado por una autoridad de certificación (CA) confiable y también verifica que el nombre del servidor coincida con el nombre en el certificado. 

-- Ejemplos de conexión
psql "sslmode=verify-full host=192.100.68.94 user=sys_user_test dbname=postgres"
psql "sslmode=verify-full host=192.100.68.94 user=sys_user_test dbname=postgres sslrootcert=root.crt sslcert=client.crt sslkey=client.key"
psql -d postgres -U alejandro -p 5432 -h 192.100.68.94


-- Resultado esperado
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
```

## Paso 7: Validar que todo este configurado y funcionando correctamente

```
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


## INFO EXTRA
```
https://www.postgresql.org/docs/current/sslinfo.html


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


 
 -------- Empresan que emiten Certificados C.A 
 Let's Encrypt: Es una autoridad de certificación gratuita y automatizada que emite certificados SSL/TLS de forma gratuita. Es ampliamente utilizada para proporcionar certificados SSL/TLS en sitios web.

Comodo CA (ahora Sectigo): Es una de las mayores autoridades de certificación del mundo, que ofrece una amplia gama de certificados SSL/TLS y servicios de seguridad en línea.

DigiCert: Es otra de las principales autoridades de certificación, que ofrece certificados SSL/TLS de alta calidad y soluciones de seguridad de confianza.

GoDaddy: Aunque es conocido principalmente como un registrador de dominios, GoDaddy también ofrece servicios de certificados SSL/TLS.

GlobalSign: Es una autoridad de certificación global que proporciona una variedad de certificados SSL/TLS y soluciones de seguridad en línea.

 
-*-*-*-*-*-*-*-*-*--*-*-*-*-*-*-*-*-*-  opciones secundarias para generar certificados firmados   : -*-*-*-*-*-*-*-*-*- -*-*-*-*-*-*-*-*-*- 

######### opcion #1 #########
 ------------------------------------- server  -------------------------------------
 
  openssl req -days 3650 -new -text -nodes -subj '/C=US/ST=Massachusetts/L=Bedford/O=Personal/OU=Personal/emailAddress=example@example.com/CN=10.30.68.94' -keyout server.key -out server.csr
  openssl req -days 3650 -x509 -text -in server.csr -key server.key -out server.crt
  cp server.crt root.crt
 rm server.csr

chmod 400 ca.key
 
 ------------------------------------- cliente  -------------------------------------
 
  openssl req -days 3650 -new -nodes -subj '/C=US/ST=Massachusetts/L=Bedford/O=Personal/OU=Personal/emailAddress=example@example.com/CN=alejandro' -keyout client.key -out client.csr
  openssl x509 -days 3650 -req  -CAcreateserial -in client.csr -CA root.crt -CAkey server.key -out client.crt
 rm client.csr
 
 
 ***************************************************************************
 
 

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

https://www.postgresql.org/docs/current/ssl-tcp.html
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
