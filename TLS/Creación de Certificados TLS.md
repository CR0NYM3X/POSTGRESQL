 
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
--- version 
[postgres@SERV ejem]$ openssl version
OpenSSL 1.1.1k  FIPS 25 Mar 2021

-- Directorio original del todo el sitema PKI 
[postgres@SERV ejem]$ openssl version -d
OPENSSLDIR: "/etc/pki/tls"
``` 


En este ejemplo nosotros crearemos nuestro propio sistema PKI con las configuraciones y archivos necesarios para no manipular las carpetas originales y intervenir en los registros que ya existentes
 ```BASH

  mkdir -p  /tmp/pki/CA #Subdirectorio que puede contener archivos de la Autoridad Certificadora, como certificados de la CA, claves privadas y listas de revocación de certificados (CRL).
  mkdir -p  /tmp/pki/tls  #Subdirectorio que contiene archivos de configuración y certificados relacionados con TLS (Transport Layer Security).
  mkdir -p  /tmp/pki/certs # Subdirectorio para almacenar certificados públicos.
  mkdir -p  /tmp/pki/private #Subdirectorio para almacenar claves privadas.

  mkdir -p /tmp/pki/CA/newcerts # Guarda certificados nuevos en caso de no indicar la ruta de salida.
  touch   /tmp/pki/CA/index.txt # Este archivo actúa como una base de datos que registra todos los certificados emitidos y revocados por la CA. ermite a la CA llevar un seguimiento de todos los certificados, incluyendo su estado (válido, revocado, caducado).
  echo 01 > /tmp/pki/CA/serial # Contiene el número de serie que se asignará al próximo certificado emitido y Garantiza que cada certificado tenga un número de serie único.
  echo 01 > /tmp/pki/CA/crlnumber # Contiene el número de serie que se asignará a la próxima Lista de Revocación de Certificados (CRL) y Asegura que cada CRL generada tenga un número de serie único.

 ``` 

**Generar el archivo openssl.conf** 
 ```BASH
#El archivo `openssl.conf` es crucial para la configuración de OpenSSL, ya que define los parámetros y opciones que se utilizarán en diversas operaciones, ese se usa por default en caso de no especificarlo con `-config` y se recomienda siempre usarlo para todas las operaciones relacionadas con la CA (solicitudes, emisión de certificados, firmas, revocaciones, etc.).
vim /tmp/pki/tls/openssl.conf
``` 

**Pegamos el contenido en el archivo /tmp/pki/openssl.conf**
```ini
[ ca ]
default_ca = CA_default  # Define la CA predeterminada

[ CA_default ]
dir               = /tmp/pki/CA  # Directorio base para la CA
database          = $dir/index.txt  # Archivo de base de datos de certificados emitidos y revocados
serial            = $dir/serial  # Archivo que contiene el número de serie del próximo certificado
crlnumber         = $dir/crlnumber  # Archivo que contiene el número de serie de la próxima CRL
new_certs_dir     = $dir/newcerts  # Directorio para almacenar nuevos certificados emitidos
#crl               = $dir/crl.pem  # Archivo de la CRL (No se usara )
#certificate       = $dir/ca.crt  # Certificado de la CA  (No se usara ya que especificaremos la ruta)
#private_key       = $dir/ca.key  # Clave privada de la CA  (No se usara ya que especificaremos la ruta)
default_days      = 365  # Días de validez predeterminados para los certificados emitidos
default_md        = sha512  # Algoritmo de hash predeterminado para firmar certificados
policy            = policy_any  # Política de emisión de certificados
default_crl_days  = 30  # Días de validez predeterminados para la CRL


[ policy_any ]
countryName             = optional  # El nombre del país es opcional
stateOrProvinceName     = optional  # El estado o provincia es opcional
organizationName        = optional  # El nombre de la organización es opcional
organizationalUnitName  = optional  # El nombre de la unidad organizativa es opcional
commonName              = supplied  # El nombre común debe ser proporcionado
emailAddress            = optional  # La dirección de correo electrónico es opcional

[ req ]
default_bits        = 2048  # Tamaño de la clave predeterminado en bits
default_md          = sha512  # Algoritmo de hash predeterminado para solicitudes de certificados
default_keyfile     = intermediate.key  # Archivo de clave predeterminado para solicitudes
prompt              = no  # No solicitar información al usuario durante la generación de la solicitud
distinguished_name  = req_distinguished_name  # Sección que define el nombre distinguido
x509_extensions     = v3_ca  # Extensiones X.509 para certificados de CA

[ req_distinguished_name ]
C                   = US  # País
ST                  = California  # Estado o provincia
L                   = San Francisco  # Localidad
O                   = Example Corp  # Organización
OU                  = IT Department  # Unidad organizativa
CN                  = Example Intermediate CA  # Nombre común

[ v3_ca ]
subjectKeyIdentifier = hash  # Identificador de clave del sujeto
authorityKeyIdentifier = keyid:always,issuer  # Identificador de clave de la autoridad
basicConstraints = critical, CA:true, pathlen:0  # Restricciones básicas para certificados de CA
keyUsage = critical, digitalSignature, cRLSign, keyCertSign  # Uso de clave
extendedKeyUsage = serverAuth, clientAuth  # Uso extendido de clave
certificatePolicies = @pol_section  # Políticas de certificado

[ pol_section ]
policyIdentifier = 2.16.840.1.114412.2.1  # Identificador de política 1
policyIdentifier = 2.23.140.1.1  # Identificador de política 2
policyIdentifier = 2.23.140.1.2.1  # Identificador de política 3
policyIdentifier = 2.23.140.1.2.2  # Identificador de política 4
policyIdentifier = 2.23.140.1.2.3  # Identificador de política 5
```
 

 







 
### Escenario simulado
- **IP del Servidor**: 127.0.0.1
- **IP del Cliente**: 192.168.1.20
- **Nombre de Usuario**: conssl


# Implementación

### Paso 1: Crear el Certificado y la Clave Privada de la CA Raíz

1. **Generar la Clave Privada con contraseña para la CA Raíz**:
   ```bash
   openssl genpkey -algorithm RSA -out /tmp/pki/private/root.key -aes256
   ```
   - `openssl genpkey`: Comando para generar una clave privada.
   - `-algorithm RSA`: Especifica el algoritmo RSA para la clave.
   - `-out root.key`: Nombre del archivo de salida para la clave privada.
   - `-aes256`: Cifra la clave privada con el algoritmo AES-256.


2. **Generar el Certificado de la CA Raíz**:
   ```bash
   openssl req -x509 -new -nodes \
     -config /tmp/pki/tls/openssl.conf \
     -key /tmp/pki/private/root.key \
     -out /tmp/pki/CA/root.crt \
     -subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=Root CA" \
     -sha512 -days 3650 
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

1.- **Generar un archivo mi_openssl.cnf**
Puedes generar tu propio archivo de configuración de manera independiente. Si prefieres no modificar el archivo `/etc/pki/tls/openssl.cnf`, esta  ruta la encuentras con el comando: **openssl version -d**

   ```bash
   vim /tmp/mi_openssl.cnf
   ```

2.- **Pegar lo siguiente en el archivo mi_openssl.conf**
Este archivos de configuración lo puedes usar para definir varios parámetros y opciones cuando se generan y gestionan certificados y claves. 
   ```bash
   [ req ]
   default_bits        = 2048
   default_md          = sha512
   default_keyfile     = intermediate.key
   prompt              = no
   distinguished_name  = req_distinguished_name
   x509_extensions     = v3_ca
   
   [ req_distinguished_name ]
   C                   = US
   ST                  = California
   L                   = San Francisco
   O                   = Example Corp
   OU                  = IT Department
   CN                  = Example Intermediate CA
   
   [ v3_ca ]
   subjectKeyIdentifier = hash
   authorityKeyIdentifier = keyid:always,issuer
   basicConstraints = critical, CA:true, pathlen:0
   keyUsage = critical, digitalSignature, cRLSign, keyCertSign
   extendedKeyUsage = serverAuth, clientAuth
   certificatePolicies = @pol_section
   
   [ pol_section ]
   policyIdentifier = 2.16.840.1.114412.2.1
   policyIdentifier = 2.23.140.1.1
   policyIdentifier = 2.23.140.1.2.1
   policyIdentifier = 2.23.140.1.2.2
   policyIdentifier = 2.23.140.1.2.3
   ```

3. **Generar la Clave Privada sin contraseña para la CA Intermedia**:
   ```bash
   openssl genpkey -algorithm RSA -out /tmp/pki/private/intermediate.key
   ```

4. **Generar la Solicitud de Certificado (CSR) para la CA Intermedia**:
   ```bash
    openssl req -new \
	 -config /tmp/pki/tls/openssl.conf \
	 -key /tmp/pki/private/intermediate.key \
	 -out /tmp/pki/CA/intermediate.csr \
   	 -subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=Example Intermediate CA" 
   ```
   - **`openssl req`**: Utiliza el comando `req` de OpenSSL para generar una solicitud de certificado (CSR).
   - **`-new`**: Indica que se está generando una nueva solicitud de certificado.
   - **`-key intermediate.key`**: Especifica el archivo de clave privada que se utilizará para generar la CSR. En este caso, `intermediate.key`.
   - **`-out intermediate.csr`**: Especifica el archivo de salida donde se guardará la CSR generada. En este caso, `intermediate.csr`.
   - **`-config /tmp/mi_openssl.cnf`**: Especifica el archivo de configuración de OpenSSL que contiene los detalles necesarios para generar la CSR. En este caso, `/tmp/mi_openssl.cnf`.

 
5. **Firmar el Certificado de la CA Intermedia con la CA Raíz**:
   ```bash
   openssl x509 -req \
	   -extfile  /tmp/pki/tls/openssl.conf \
	   -CA /tmp/pki/CA/root.crt \
	   -CAkey /tmp/pki/private/root.key \
	   -in /tmp/pki/CA/intermediate.csr \
	   -out /tmp/pki/CA/intermediate.crt \
	   -CAcreateserial -days 3650 -sha512 -extensions v3_ca 
   ```
   - **`openssl x509`**: Utiliza el comando `x509` de OpenSSL para gestionar certificados X.509.
   - **`-req`**: Indica que se está procesando una CSR.
   - **`-in intermediate.csr`**: Especifica el archivo de entrada que contiene la CSR. En este caso, `intermediate.csr`.
   - **`-CA root.crt`**: Especifica el archivo del certificado de la CA que firmará la CSR. En este caso, `root.crt`.
   - **`-CAkey root.key`**: Especifica el archivo de clave privada de la CA que firmará la CSR. En este caso, `root.key`.
   - **`-CAcreateserial`**: Crea un número de serie para el certificado si no existe uno. Genera un archivo `root.srl` que contiene el número de serie.
   - **`-out intermediate.crt`**: Especifica el archivo de salida donde se guardará el certificado firmado. En este caso, `intermediate.crt`.
   - **`-days 3650`**: Especifica la validez del certificado en días. En este caso, 3650 días (10 años).
   - **`-sha512`**: Utiliza el algoritmo SHA-512 para firmar el certificado.
   - **`-extensions v3_ca`**: Especifica las extensiones que se deben aplicar al certificado. Estas extensiones están definidas en el archivo de configuración.
   - **`-extfile /tmp/mi_openssl.cnf`**: Especifica el archivo de configuración que contiene las extensiones y otros detalles necesarios para generar el certificado. En este caso, `/tmp/mi_openssl.cnf`.

### Paso 3: Crear el Certificado y la Clave Privada del Servidor

1. **Generar la Clave Privada sin contraseña del Servidor**:
   ```bash
   openssl genpkey -algorithm RSA -out /tmp/pki/private/server.key
   ```


2. **Generar la Solicitud de Certificado (CSR) para el Servidor**:
   ```bash
   openssl req -new \
	-config /tmp/pki/tls/openssl.conf \
	-key /tmp/pki/private/server.key \
	-out /tmp/pki/certs/server.csr \
	-subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=127.0.0.1"
   ```
   - Igual que en el paso 2.

3. **Firmar el Certificado del Servidor con la CA Intermedia**:
   ```bash
    openssl x509 -req \
	 -extfile  /tmp/pki/tls/openssl.conf \
	 -CA /tmp/pki/CA/intermediate.crt \
	 -CAkey /tmp/pki/private/intermediate.key \
	 -in /tmp/pki/certs/server.csr  \
	 -out /tmp/pki/certs/server.crt  \
	 -CAcreateserial -days 825 -sha512
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




### Paso 5: **Genera una lista de revocación de certificados (CRL)**

1. **Primero, revoca un certificado (por ejemplo, `cert.crt`):**
     ```bash
     openssl ca -revoke client.crt -keyfile intermediate.key -cert intermediate.crt -config crl_openssl.conf -verbose
     ```


2. **Generar la CRL con la CA Intermedia**:
   - Finalmente, genera la CRL:
     ```bash
     openssl ca -gencrl -keyfile intermediate.key -cert intermediate.crt -out revoke.crl -config crl_openssl.conf -verbose
     ```
     
   - `openssl ca`: Comando para gestionar una CA.
   - `-gencrl`: Genera una lista de revocación de certificados (CRL).
   - `-keyfile intermediate.key`: Especifica la clave privada de la CA intermedia.
   - `-cert intermediate.crt`: Especifica el certificado de la CA intermedia.
   - `-out intermediate.crl`: Nombre del archivo de salida para la CRL.


3. **Verifica la CRL**:
   ```bash
   openssl crl -in revoke.crl -noout -text
   ```


### Paso 6: Otorgar permisos de lectura a certificados
- **Comando**: `chmod 400 *.{key,crt}`
  - **Qué hace**: Cambia los permisos de los archivos de clave (.key) y certificado (.crt) para que solo el propietario pueda leerlos.
  - **Explicación**: Es como poner una cerradura en los archivos para que nadie más pueda acceder a ellos.
 


### Paso 7: Verificar la autenticidad de los certificados
- **Comando**: `openssl verify -CAfile root.crt client.crt` o `openssl verify -CAfile root.crt server.crt` o  `openssl verify -CAfile root.crt -untrusted intermediate.crt server.crt`
  - **Explicación**: Es como comprobar que los permisos del cliente y del servidor son auténticos y aprobados por la autoridad.
  [NOTA] si todo esta bien retorna esto "server.crt: OK" o "client.crt: OK"
  

# Post-Implementación

## **Ver los detalles de los certificados**
- **Comando**:  openssl x509 -in server.crt -text -noout

 
## Simular cliente y servidor con Certificados

- **iniciar un servidor TLS/SSL simple para pruebas **
	- **Comando:** openssl s_server -key server.key -cert server.crt -tls1_2 -accept 4433 
	

- **iniciar un servidor TLS/SSL simple para pruebas **
	- **Comando:** openssl s_client -connect 127.0.0.1:4433 -tls1_2




## **Validar si el TLS esta activado en un servidor**
 
**Comando:**
```sh
openssl s_client -connect 172.10.10.100:5432 -starttls postgres -tls1_2
```
Salida esperada TLSv1.2:
```plaintext
CONNECTED(00000003)
depth=1 C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
verify return:1
depth=0 CN = example.com
verify return:1
---
Certificate chain
 0 s:CN = example.com
   i:C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
---
Server certificate
-----BEGIN CERTIFICATE-----
MIIF...
-----END CERTIFICATE-----
subject=CN = example.com
issuer=C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: RSA-PSS
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 3051 bytes and written 456 bytes
Verification: OK
---
New, TLSv1.2, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES128-GCM-SHA256
    Session-ID: 3A4B...
    Session-ID-ctx:
    Master-Key: 1A2B...
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    Start Time: 1739407853
    Timeout   : 7200 (sec)
    Verify return code: 0 (ok)
    Extended master secret: yes
---
```


### Puntos Clave:
- **Certificate chain**: Muestra la cadena de certificados.
- **Server certificate**: Detalles del certificado del servidor.
- **SSL handshake**: Información sobre el proceso de handshake SSL.
- **SSL-Session**: Detalles de la sesión SSL, incluyendo el protocolo y el cifrado utilizado.
- **Sin certificado**: si no retorna el texto "-----BEGIN CERTIFICATE-----" hay algun problema con el tls
  













