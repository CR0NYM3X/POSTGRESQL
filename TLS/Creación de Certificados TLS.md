 
## Manual de Creación de Certificados TLS y Jerarquía de Archivos PKI

### Descripción
Este manual proporciona una guía completa para la creación y gestión de certificados TLS y la configuración de una infraestructura de clave pública (PKI). Aprenderás a generar y utilizar los certificados y claves necesarios para asegurar las comunicaciones en redes y aplicaciones. La estructura de archivos PKI que cubriremos incluye certificados y claves para la CA raíz, CA intermedia, servidores y clientes.
 

# Estructura de PKI 
``` 
[postgres@server_test pki]$ tree /tmp/pki
	/tmp/pki
	├── CA
	│   ├── crlnumber
	│   ├── index.txt
	│   ├── intermediate.crt
	│   ├── intermediate.csr
	│   ├── intermediate.srl
	│   ├── newcerts
	│   ├── root.crt
	│   ├── root.srl
	│   └── serial
	├── certs
	│   ├── client.crt
	│   ├── client.csr
	│   ├── server.crt
	│   └── server.csr
	├── private
	│   ├── client.key
	│   ├── intermediate.key
	│   ├── root.key
	│   └── server.key
	└── tls
	    └── openssl.conf
	
	5 directories, 17 files

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
[archivo github Openssl.conf](https://github.com/openssl/openssl/blob/master/apps/openssl.cnf)
 ```BASH
#El archivo `openssl.conf` es crucial para la configuración de OpenSSL, ya que define los parámetros y opciones que se utilizarán en diversas operaciones, ese se usa por default en caso de no especificarlo con `-config` y se recomienda siempre usarlo para todas las operaciones relacionadas con la CA (solicitudes, emisión de certificados, firmas, revocaciones, etc.).
vim /tmp/pki/tls/openssl.conf

``` 

**Pegamos el contenido en el archivo /tmp/pki/openssl.conf**

```ini
[ ca ] #  Define la configuración general para la autoridad certificadora (CA).
default_ca = CA_default  # Define la CA predeterminada

[ CA_default ] #  Configuración predeterminada para la CA, incluyendo directorios, archivos de base de datos, y políticas de emisión de certificados.
dir               = /tmp/pki/CA  # Directorio base para la CA
database          = $dir/index.txt  # Archivo de base de datos de certificados emitidos y revocados
serial            = $dir/serial  # Archivo que contiene el número de serie del próximo certificado
crlnumber         = $dir/crlnumber  # Archivo que contiene el número de serie de la próxima CRL
new_certs_dir     = $dir/newcerts  # Directorio para almacenar nuevos certificados emitidos
default_days      = 365  # Días de validez predeterminados para los certificados emitidos
default_md        = sha512  # Algoritmo de hash predeterminado para firmar certificados
policy            = policy_any  # Política de emisión de certificados
default_crl_days  = 30  # Días de validez predeterminados para la CRL
x509_extensions	= usr_cert

[ policy_any ]  #  Define una política de emisión de certificados que requiere que ciertos campos coincidan con los valores esperados.
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ] #  Configuración para la generación de solicitudes de certificados (CSR), incluyendo el tamaño de la clave y el algoritmo de hash.
default_bits        = 2048
default_md          = sha512
default_keyfile     = root.key
prompt              = no
distinguished_name  = req_distinguished_name
x509_extensions     = v3_ca_root

[ req_distinguished_name ] #  Define los campos del nombre distinguido (DN) que se incluirán en las solicitudes de certificados.
C                   = US
ST                  = California
L                   = San Francisco
O                   = Example Corp
OU                  = IT Department
CN                  = Example Root CA


# Extensiones para el certificado raíz
[ v3_ca_root ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, keyCertSign, cRLSign

# Extensiones para el certificado intermedio
[ v3_ca_intermediate ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, keyCertSign, cRLSign
certificatePolicies = 2.16.840.1.114412.2.1, 2.23.140.1.1, 2.23.140.1.2.1, 2.23.140.1.2.2, 2.23.140.1.2.3

# Extensiones para los certificados de servidor y cliente
[ usr_cert ]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
certificatePolicies = 2.23.140.1.2.2
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
	  -config /tmp/pki/tls/openssl.conf -extensions v3_ca_root \
	  -key /tmp/pki/private/root.key \
	  -out /tmp/pki/CA/root.crt \
	  -subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=Root CA" \
	  -sha512 -days 3650 
   ```tre
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


1. **Generar la Clave Privada sin contraseña para la CA Intermedia**:
   ```bash
   openssl genpkey -algorithm RSA -out /tmp/pki/private/intermediate.key
   ```

2. **Generar la Solicitud de Certificado (CSR) para la CA Intermedia**:
   ```bash
    openssl req -new \
	 -config /tmp/pki/tls/openssl.conf -extensions v3_ca_intermediate \
	 -key /tmp/pki/private/intermediate.key \
	 -out /tmp/pki/CA/intermediate.csr \
   	 -subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=Example Intermediate CA" 
   ```
   - **`openssl req`**: Utiliza el comando `req` de OpenSSL para generar una solicitud de certificado (CSR).
   - **`-new`**: Indica que se está generando una nueva solicitud de certificado.
   - **`-key intermediate.key`**: Especifica el archivo de clave privada que se utilizará para generar la CSR. En este caso, `intermediate.key`.
   - **`-out intermediate.csr`**: Especifica el archivo de salida donde se guardará la CSR generada. En este caso, `intermediate.csr`.
   - **`-config /tmp/mi_openssl.cnf`**: Especifica el archivo de configuración de OpenSSL que contiene los detalles necesarios para generar la CSR. En este caso, `/tmp/mi_openssl.cnf`.

 
3. **Firmar el Certificado de la CA Intermedia con la CA Raíz**:
   ```bash
   openssl x509 -req \
	   -extfile  /tmp/pki/tls/openssl.conf  -extensions v3_ca_intermediate \
	   -CA /tmp/pki/CA/root.crt \
	   -CAkey /tmp/pki/private/root.key \
	   -in /tmp/pki/CA/intermediate.csr \
	   -out /tmp/pki/CA/intermediate.crt \
	   -CAcreateserial -days 3650 -sha512  
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
	-config /tmp/pki/tls/openssl.conf -extensions usr_cert \
	-key /tmp/pki/private/server.key \
	-out /tmp/pki/certs/server.csr \
	-subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=127.0.0.1"
   ```


3. **Firmar el Certificado del Servidor con la CA Intermedia**:
   ```bash
    openssl x509 -req \
	 -extfile  /tmp/pki/tls/openssl.conf -extensions usr_cert \
	 -CA /tmp/pki/CA/intermediate.crt \
	 -CAkey /tmp/pki/private/intermediate.key \
	 -in /tmp/pki/certs/server.csr  \
	 -out /tmp/pki/certs/server.crt  \
	 -CAcreateserial -days 825 -sha512
   ```



### Paso 4: Crear el Certificado y la Clave Privada del Cliente

1. **Generar la Clave Privada sin contraseña para el Cliente**:
   ```bash
	openssl genpkey -algorithm RSA -out /tmp/pki/private/client.key  
   ```

2. **Generar la Solicitud de Certificado (CSR) para el Cliente**:
   ```bash
   openssl req -new \
	-config /tmp/pki/tls/openssl.conf  -extensions usr_cert \
	-key /tmp/pki/private/client.key \
	-out /tmp/pki/certs/client.csr \
	-subj "/C=US/ST=California/L=San Francisco/O=Example Corp/OU=IT Department/CN=conssl"
   ```

3. **Firmar el Certificado del Cliente con la CA Intermedia**:
   ```bash
	  openssl x509 -req \
		  -CA /tmp/pki/CA/intermediate.crt  -extensions usr_cert \
		  -CAkey /tmp/pki/private/intermediate.key \
		  -in /tmp/pki/certs/client.csr \
		  -out /tmp/pki/certs/client.crt  \
		  -CAcreateserial -days 825 -sha512
   ```




### Paso 5: **Genera una lista de revocación de certificados (CRL)**

1. **Primero, revoca un certificado (por ejemplo, `cert.crt`):**
     ```bash
     openssl ca -verbose \
	-config /tmp/pki/tls/openssl.conf  \
	-cert /tmp/pki/CA/intermediate.crt \
	-keyfile /tmp/pki/private/intermediate.key \
	-revoke /tmp/pki/certs/client.crt
     ```


2. **Generar la CRL con la CA Intermedia**:
   - Finalmente, genera la CRL:
     ```bash
	     openssl ca -gencrl  -verbose \
		-config /tmp/pki/tls/openssl.conf \
		-cert /tmp/pki/CA/intermediate.crt \
		-keyfile /tmp/pki/private/intermediate.key \
		-out /tmp/pki/CA/revoke.crl 
     ```
     
   - `openssl ca`: Comando para gestionar una CA.
   - `-gencrl`: Genera una lista de revocación de certificados (CRL).
   - `-keyfile intermediate.key`: Especifica la clave privada de la CA intermedia.
   - `-cert intermediate.crt`: Especifica el certificado de la CA intermedia.
   - `-out intermediate.crl`: Nombre del archivo de salida para la CRL.


3. **Verifica la CRL**:
   ```bash
   openssl crl -in /tmp/pki/CA/revoke.crl  -noout -text
   ```

 

### Paso 6: Verificar la autenticidad de los certificados
- **Comando**: `openssl verify -CAfile /tmp/pki/CA/root.crt  -untrusted /tmp/pki/CA/intermediate.crt /tmp/pki/certs/server.crt`
- **Comando**:  `openssl verify -CAfile /tmp/pki/CA/root.crt /tmp/pki/CA/intermediate.crt` 
- **Explicación**: Es como comprobar que los permisos del cliente y del servidor son auténticos y aprobados por la autoridad.
  [NOTA] Salida esperada "/tmp/pki/CA/intermediate.crt: OK"






# Post-Implementación

## **Ver los detalles de los certificados**
- **Comando**:  `openssl x509 -in /tmp/pki/certs/server.crt -text -noout`

 
## Simular cliente y servidor con Certificados

- **iniciar un servidor TLS/SSL simple para pruebas **
	- **Comando:** `openssl s_server -key server.key -cert server.crt -tls1_2 -accept 4433 `
	

- **iniciar un servidor TLS/SSL simple para pruebas **
	- **Comando:** `openssl s_client -connect 127.0.0.1:4433 -tls1_2`




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
  




## **Identificar el Certificado Raíz (Root CA):**
- Si `Issuer` y `Subject` son iguales, es el **certificado raíz (root.crt)**.
- Ejecuta este comando para cada `.crt`:
- **comando:**  openssl x509 -in /tmp/pki/CA/root.crt -text -noout | grep -E "Issuer:|Subject:"
	 
	 
## **Identificar el Certificado Intermedio (si existe):**
   - El `Issuer` y `Subject` son diferentes, y su `Issuer` coincidirá con el `Subject` del root CA.
   - Tiene la extensión **CA:TRUE**:
   - **comando:** openssl x509 -in /tmp/pki/CA/intermediate.crt -text -noout | grep -E "CA:TRUE|Issuer:|Subject:"
 


## **Identificar el Certificado del server.crt o client.crt:**
- Verifica si su `Issuer` coincide con el `Subject` de otro certificado (el *intermediate.crt* el root.crt, si existe).
- Busca la extensión **X509v3 Extended Key Usage**:
**comando:**  openssl x509 -in /tmp/pki/certs/server.crt -text -noout | grep -Ei "TLS Web|Issuer|Subject"
	 
	 
## **Verificar de quien es la clave privada (.key):**
   - La clave privada debe coincidir con el archivo (root.crt, intermediate.crt, server.crt o client.crt) 
   - Compara el módulo público de la clave y el certificado:
     ``` 
		 openssl rsa -in /tmp/pki/private/server.key -modulus -noout | openssl sha256 # Obtener hash del módulo de la clave privada

		 openssl x509 -in /tmp/pki/certs/server.crt -modulus -noout | openssl sha256 # Obtener hash del módulo de cada certificado (.crt)
     ```

 

## **Verificar la fecha de expiración de un certificado**
``` 
openssl x509 -in /tmp/pki/certs/server.crt -noout -dates  #  Salida esperada:   notBefore=Fecha y hora de inicio  , notAfter=Fecha y hora de expiración
openssl x509 -in /tmp/pki/certs/server.crt -noout -enddate  #  Salida esperada: `notAfter=Dec 31 23:59:59 2025 GMT`
``` 
	
## **Verificar la fecha de expiración de un certificado Servidor remoto**
``` 
openssl s_client -connect dominio.com:443 -servername dominio.com 2>/dev/null | openssl x509 -noout -dates 
openssl s_client -connect 192.168.1.100:5416 -starttls postgres 2>/dev/null | openssl x509 -noout -dates 
``` 


# Preguntas frecuentes 

¿Se puede invalidar todos los certificados emitidos por un intermediario , simplemente revocando el intermediario?
Revocar el certificado intermedio invalida los certificados emitidos por él, pero es recomendable revocar explícitamente todos sus  certificados emitidos por el intermediario para asegurar una mayor seguridad y confianza en tu infraestructura de clave pública 



¿Se pueden firmar solicitudes de certificados (csr) solo con una KEY?
Sí, pero tiene sus ventajas y deventajas 
 
### Comando 2: Firmar con una Clave Privada
```bash
openssl x509 -req -days 365 -in server.csr -signkey private.key -out server.crt
```

#### Ventajas
- **Simplicidad**: No requiere una CA, lo que simplifica el proceso.
- **Costo**: No hay costos asociados con el uso de una CA pública.

#### Desventajas
- **Confianza Limitada**: Los certificados autofirmados no son confiados por navegadores y clientes sin configuración adicional.
- **Seguridad**: Menos seguro que un certificado firmado por una CA, ya que no hay una cadena de confianza.

#### Cuándo Usarlo
- **Entornos de Desarrollo**: Ideal para pruebas y desarrollo donde la confianza del navegador no es crítica.
- **Aplicaciones Internas**: Para servicios internos donde puedes configurar manualmente la confianza en los certificados.








