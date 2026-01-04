# Crear certificados de varias opciones
Sin  necesidad de crear un KPI
``` 
####################  Opcion #1: Generar Certificados #################### 


 
1.- Generación del certificado raíz (CA): 

	1.1 Genera un certificado autofirmado para la autoridad de certificación (CA) -  
	Este certificado es utilizado para firmar digitalmente otros certificados, incluidos los certificados de servidor y de cliente.
	
	openssl req -new -x509   -nodes -out root.crt -keyout root.key -subj "/CN=CA Root"
	
	----- segunda opcion/ aqui tu generas una paswd para el root ---
	
	 openssl genrsa -aes128  -out root.key 2048 -- Genera una clave privada para tu CA | . Si no generas una clave privada   La clave privada es esencial para la firma de certificados,
	 openssl rsa -in root.key -out root.key
	 chmod 400 root.key
	 openssl req -new -x509 -key root.key -out root.crt -subj '/CN=CA Root' --- Crea un certificado autofirmado para tu CA:
	--------------------
	

2.- Generación del certificado del servidor:

	2.1  Genera una solicitud de certificado para el servidor con una clave privada
	openssl req -new -nodes -out server.csr -keyout server.key \
    -subj "/C=US/ST=California/L=Los Angeles/O=Mi Organización/OU=Mi Unidad/CN=127.0.0.1"
	
	2.2 Firma la solicitud de certificado del servidor con el certificado raíz y su clave privada.
	openssl x509 -req   -in server.csr -CA root.crt -CAkey root.key -CAcreateserial -out server.crt 



3.- Generación del certificado del cliente: 

	3.1 - Genera una solicitud de certificado para el cliente con una clave privada 
	openssl req -new -nodes -out client.csr -keyout client.key -subj "/CN=sys_user_test"

	3.2 - Firma la solicitud de certificado del cliente con el certificado raíz y su clave privada.
	openssl x509 -req   -in client.csr -CA root.crt -CAkey root.key -CAcreateserial -out client.crt


4.- Eliminar los archivos que no se ocupan 
 rm *.csr
rm *.srl

5.- dar permisos de lectura 
chmod 400 *.{key,crt}


6.- Validar que los certificados funcionen correctamente 
 openssl verify -CAfile root.crt client.crt
 openssl verify -CAfile root.crt server.crt

[NOTA] si todo esta bien retorna esto "server.crt: OK" o "client.crt: OK"



####################  Opcion #2: Generar Certificados #################### 
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
 
 
####################  Opcion #3: Generar Certificados #################### 
 
 
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
		
``` 
