 
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

3. **Generar la Clave Privada de la CA Intermedia**:
   ```bash
   openssl genpkey -algorithm RSA -out intermediate.key 
   ```
   - Igual que en el paso 1.

4. **Generar la Solicitud de Certificado (CSR) para la CA Intermedia**:
   ```bash
   openssl req -new -key intermediate.key -out intermediate.csr -config /tmp/mi_openssl.cnf
   ```
   - **`openssl req`**: Utiliza el comando `req` de OpenSSL para generar una solicitud de certificado (CSR).
   - **`-new`**: Indica que se está generando una nueva solicitud de certificado.
   - **`-key intermediate.key`**: Especifica el archivo de clave privada que se utilizará para generar la CSR. En este caso, `intermediate.key`.
   - **`-out intermediate.csr`**: Especifica el archivo de salida donde se guardará la CSR generada. En este caso, `intermediate.csr`.
   - **`-config /tmp/mi_openssl.cnf`**: Especifica el archivo de configuración de OpenSSL que contiene los detalles necesarios para generar la CSR. En este caso, `/tmp/mi_openssl.cnf`.

 
5. **Firmar el Certificado de la CA Intermedia con la CA Raíz**:
   ```bash
   openssl x509 -req -in intermediate.csr -CA root.crt -CAkey root.key -CAcreateserial -out intermediate.crt -days 3650 -sha512 -extensions v3_ca -extfile /tmp/mi_openssl.cnf
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
  













