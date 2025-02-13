 
## Manual de Creación de Certificados TLS y Jerarquía de Archivos PKI

### Descripción
Este manual proporciona una guía completa para la creación y gestión de certificados TLS y la configuración de una infraestructura de clave pública (PKI). Aprenderás a generar y utilizar los certificados y claves necesarios para asegurar las comunicaciones en redes y aplicaciones. La estructura de archivos PKI que cubriremos incluye certificados y claves para la CA raíz, CA intermedia, servidores y clientes.
 

# Estructura de PKI 
``` 
	pki/
	├─── Root/ 
	│ ├── root.crt 
	│ └── root.key
	├─── Intermediate/  
	│ ├── intermediate.crt
	│ └── intermediate.key 
	├─── Server/ 
	│ ├── server.crt 
	│ ├── server.key 
	│ └── server.crl 
	└─── Client/ 
	  ├── client.crt
	  └── client.key
``` 

# Requisitos 
Se recomienda usar openssl 1.1.1 en adelante ya que es compatible con tls 1.2 y 1.3 
``` 
[postgres@SERV ejem]$ openssl version
OpenSSL 1.1.1k  FIPS 25 Mar 2021
[postgres@SERV ejem]$ openssl version -d
OPENSSLDIR: "/etc/pki/tls"
``` 




 
### Escenario simulado
- **IP del Servidor**: 127.0.0.1
- **IP del Cliente**: 192.168.1.20
- **Nombre de Usuario**: conssl

### Paso 1: Crear el Certificado y la Clave Privada de la CA Raíz

1. **Generar la Clave Privada de la CA Raíz**:
   ```bash
   openssl genpkey -algorithm RSA -out root.key -aes256
   ```
   - `openssl genpkey`: Comando para generar una clave privada.
   - `-algorithm RSA`: Especifica el algoritmo RSA para la clave.
   - `-out root.key`: Nombre del archivo de salida para la clave privada.
   - `-aes256`: Cifra la clave privada con el algoritmo AES-256.

2. **Generar el Certificado de la CA Raíz**:
   ```bash
   openssl req -x509 -new -nodes -key root.key  -out root.crt -subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=Root CA" -sha512 -days 3650
   ```
   - `openssl req`: Comando para generar una solicitud de certificado (CSR) o un certificado autofirmado.
   - `-x509`: Indica que se debe generar un certificado autofirmado en lugar de una CSR.
   - `-new`: Genera una nueva solicitud de certificado.
   - `-nodes`: No cifra la clave privada (no se usa en este caso porque la clave ya está cifrada).
   - `-key root.key`: Especifica la clave privada a usar.
   - `-out root.crt`: Nombre del archivo de salida para el certificado.
   - `-subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=Example Root CA"`: Proporciona los detalles del Distinguished Name (DN) directamente en la línea de comandos.
   - `-sha512`: Utiliza el algoritmo SHA-512 para la firma.
   - `-days 3650`: Validez del certificado en días (10 años).


### Paso 2: Crear el Certificado y la Clave Privada de la CA Intermedia

1. **Generar la Clave Privada de la CA Intermedia**:
   ```bash
   openssl genpkey -algorithm RSA -out intermediate.key 
   ```
   - Igual que en el paso 1.

2. **Generar la Solicitud de Certificado (CSR) para la CA Intermedia**:
   ```bash
   openssl req -new -key intermediate.key -out intermediate.csr -subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=Example Intermediate CA"
   ```
   - `openssl req`: Comando para generar una solicitud de certificado (CSR).
   - `-new`: Genera una nueva solicitud de certificado.
   - `-key intermediate.key`: Especifica la clave privada a usar.
   - `-out intermediate.csr`: Nombre del archivo de salida para la CSR.
   - `-subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=Example Intermediate CA"`: Proporciona los detalles del Distinguished Name (DN) directamente en la línea de comandos.

3. **Firmar el Certificado de la CA Intermedia con la CA Raíz**:
   ```bash
   openssl x509 -req -in intermediate.csr -CA root.crt -CAkey root.key -CAcreateserial -out intermediate.crt -days 3650 -sha512
   ```
   - `openssl x509`: Comando para gestionar certificados X.509.
   - `-req`: Indica que se está procesando una CSR.
   - `-in intermediate.csr`: Especifica la CSR a usar.
   - `-CA root.crt`: Certificado de la CA que firmará la CSR.
   - `-CAkey root.key`: Clave privada de la CA que firmará la CSR.
   - `-CAcreateserial`: Crea un número de serie para el certificado.
   - `-out intermediate.crt`: Nombre del archivo de salida para el certificado firmado.
   - `-days 3650`: Validez del certificado en días (10 años).
   - `-sha512`: Utiliza el algoritmo SHA-512 para la firma.

### Paso 3: Crear el Certificado y la Clave Privada del Servidor

1. **Generar la Clave Privada del Servidor**:
   ```bash
   openssl genpkey -algorithm RSA -out server.key  
   ```
   - Igual que en el paso 1.

2. **Generar la Solicitud de Certificado (CSR) para el Servidor**:
   ```bash
   openssl req -new -key server.key -out server.csr -subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=127.0.0.1"
   ```
   - Igual que en el paso 2.

3. **Firmar el Certificado del Servidor con la CA Intermedia**:
   ```bash
   openssl x509 -req -in server.csr -CA intermediate.crt -CAkey intermediate.key -CAcreateserial -out server.crt -days 825 -sha512
   ```
   - Igual que en el paso 2, pero usando el certificado y la clave de la CA intermedia.





### Paso 4: Crear el Certificado y la Clave Privada del Cliente

1. **Generar la Clave Privada del Cliente**:
   ```bash
   openssl genpkey -algorithm RSA -out client.key  
   ```
   - Igual que en el paso 1.

2. **Generar la Solicitud de Certificado (CSR) para el Cliente**:
   ```bash
   openssl req -new -key client.key -out client.csr -subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=conssl"
   ```
   - Igual que en el paso 2.

3. **Firmar el Certificado del Cliente con la CA Intermedia**:
   ```bash
   openssl x509 -req -in client.csr -CA intermediate.crt -CAkey intermediate.key -CAcreateserial -out client.crt -days 825 -sha512
   ```
   - Igual que en el paso 2, pero usando el certificado y la clave de la CA intermedia.




### Paso 5: Crear la Lista de Revocación de Certificados (CRL)
[NOTA] -> Para esto ocupas permisos en la ruta de /etc/pki de lo contrario no podras generar el crl

1. **Generar la CRL con la CA Intermedia**:
   ```bash
   openssl ca -gencrl -keyfile intermediate.key -cert intermediate.crt -out intermediate.crl
   ```
   - `openssl ca`: Comando para gestionar una CA.
   - `-gencrl`: Genera una lista de revocación de certificados (CRL).
   - `-keyfile intermediate.key`: Especifica la clave privada de la CA intermedia.
   - `-cert intermediate.crt`: Especifica el certificado de la CA intermedia.
   - `-out intermediate.crl`: Nombre del archivo de salida para la CRL.




### Paso 6: Otorgar permisos de lectura a certificados
- **Comando**: `chmod 400 *.{key,crt}`
  - **Qué hace**: Cambia los permisos de los archivos de clave (.key) y certificado (.crt) para que solo el propietario pueda leerlos.
  - **Explicación**: Es como poner una cerradura en los archivos para que nadie más pueda acceder a ellos.
 


### 7: Verificar la autenticidad de los certificados
- **Comando**: `openssl verify -CAfile root.crt client.crt` o `openssl verify -CAfile root.crt server.crt` o  `openssl verify -CAfile root.crt -untrusted intermediate.crt server.crt`
  - **Explicación**: Es como comprobar que los permisos del cliente y del servidor son auténticos y aprobados por la autoridad.
  [NOTA] si todo esta bien retorna esto "server.crt: OK" o "client.crt: OK"
  
  
  
## **Validar si TLS esta activado**
- Validar si esta tls activado y retorna la información del certificado
- **Comando**: openssl s_client -connect 127.0.0.1:5432 -starttls postgres


## **Ver los detalles de los certificados**
- **Comando**:  openssl x509 -in server.crt -text -noout

 
## Simular cliente y servidor con Certificados

- **iniciar un servidor TLS/SSL simple para pruebas **
	- **Comando:** openssl s_server -key server.key -cert server.crt -tls1_2 -accept 4433 
	

- **iniciar un servidor TLS/SSL simple para pruebas **
	- **Comando:** openssl s_client -connect 127.0.0.1:4433 -tls1_2

















