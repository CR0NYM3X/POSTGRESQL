
### 📜 ¿Qué son los certificados?
Los certificados digitales son documentos electrónicos que utilizan criptografía para asegurar la identidad de una entidad (como un servidor, un usuario o un dispositivo) y proteger la información transmitida en una red. Estos certificados emplean varios tipos de protocolos criptográficos para garantizar la seguridad.


### 🔑 Componentes de un certificado

1. **Clave Pública**: Utilizada para cifrar datos que solo pueden ser descifrados por la clave privada correspondiente.
2. **Clave Privada**: Mantenida en secreto y utilizada para descifrar datos cifrados con la clave pública.
3. **Firma Digital**: Garantiza la autenticidad del certificado y que no ha sido alterado.
 
### 🎯 ¿Para qué sirven?

Los certificados son esenciales para:
- **Seguridad**: Protegen la información sensible durante la transmisión.
- **Confianza**: Aseguran a los usuarios que están comunicándose con la entidad correcta.
- **Integridad**: Garantizan que los datos no han sido alterados durante la transmisión.



### 🛡️ Tipos de Certificados de Seguridad

1. **🔒 Certificados X.509**:

   - **🔐 Certificados TLS/SSL**:
     - **Uso**: Navegación web segura (HTTPS).
     - **Modelo**: Basados en el estándar X.509 para autenticar y cifrar la comunicación entre el navegador y el servidor.
	 
   - **📧 Certificados S/MIME**:
     - **Uso**: Cifrado y firma de correos electrónicos.
     - **Modelo**: Utilizan el estándar X.509 para asegurar la autenticidad y privacidad de los correos electrónicos.
	 
   - **🖊️ Certificados de Firma de Código**:
     - **Uso**: Firmar digitalmente software y scripts.
     - **Modelo**: Basados en X.509 para garantizar que el código no ha sido alterado desde su firma.
	 
   - **👤 Certificados de Autenticación de Cliente**:
     - **Uso**: Autenticar usuarios en aplicaciones y servicios.
     - **Modelo**: Pueden estar basados en X.509 para verificar la identidad del usuario.

2. **🔑 Certificados PGP (Pretty Good Privacy)**:
   - **Uso**: Utilizados principalmente para cifrar y firmar correos electrónicos.
   - **Modelo**: Basados en un modelo de confianza de red de confianza.

3. **🔐 Certificados SSH (Secure Shell)**:
   - **Uso**: Utilizados para autenticar y cifrar conexiones SSH.
   - **Modelo**: No siguen el estándar X.509, sino que utilizan su propio formato.

 

### 🔐 [Tipos de Certificados para TLS](https://www.ssldragon.com/es/blog/tipos-certificados-ssl)

1. **🌐 Certificados DV (Domain Validation)**:
   - **Uso**: Blogs, sitios web personales.
   - **Validación**: Verificación de control sobre el dominio. Solo si no hay requisitos estrictos de compliance y los servidores son internos.

2. **🏢 Certificados OV (Organization Validation)**:
   - **Uso**: Sitios web comerciales, organizaciones.
   - **Validación**: Verifican la propiedad del dominio y la existencia de la empresa. Ideal para entornos críticos, ya que valida la identidad de la empresa y es aceptado en auditorías.

3. **🏦 Certificados EV (Extended Validation)**:
   - **Uso**: Bancos, tiendas en línea (es para páginas web públicas).
   - **Validación**: Verificación exhaustiva de la identidad del solicitante. Ofrecen el mayor nivel de verificación y seguridad.

4. **🌟 Certificados Wildcard**:
   - **Uso**: Protección de un dominio y todos sus subdominios.
   - **Ejemplo**: `*.example.com` protege `www.example.com`, `mail.example.com`, etc.

5. **🌐 Certificados Multi-Dominio (SAN [Subject Alternative Name])**:
   - **Uso**: Protección de múltiples dominios con un solo certificado.
   - **Ejemplo**: `example.com`, `example.net`, `example.org`.

6. **🖊️ Certificados de Firma de Código**:
   - **Uso**: Garantizar la autenticidad e integridad del software.
   - **Ejemplo**: Firmar aplicaciones y software.

7. **📧 Certificados de Correo Electrónico (S/MIME)**:
   - **Uso**: Seguridad en correos electrónicos, asegurando que los mensajes no sean alterados y verificando la identidad del remitente.
   - **Ejemplo**: Comunicaciones seguras por correo electrónico en entornos corporativos.

8. **🌐 Certificados de IP**:
   - **Uso**: Protegen direcciones IP Publicas en lugar de nombres de dominio.
   - **Ejemplo**: Útiles para servidores que se acceden directamente por IP y no por un dominio.

 
## 📜 Certificados X.509

Los certificados **X.509** son un estándar internacional definido por la ITU (International Telecommunication Union) y normalizados para su uso en Infraestructuras de Clave Pública (PKI) que especifica el formato de los certificados de clave pública. Son ampliamente utilizados en muchos protocolos de Internet, incluyendo **TLS/SSL** 
 


## 🔍 **Estructura y Características de un Certificado TLS (X.509)**
Un certificado TLS contiene información técnica y metadatos que permiten autenticar un servidor o entidad. Su estructura se divide en secciones clave:


  **1. Versión del Certificado**
   - Indica la versión del estándar X.509 usado (ej: v3, la más común).
   
   
  **2. Número de Serie**
   - Identificador único asignado por la CA para distinguir certificados.

  **3. Algoritmo de Firma**
   - Algoritmo usado por la CA para firmar el certificado (ej: `SHA256-RSA`, `ECDSA`).

  **4. Emisor (Issuer)**
   - Información de la CA que emitió el certificado, en formato **DN (Distinguished Name)**:
     - **C (Country)**:  Especifica el país de la entidad estándar ISO 3166 (por ejemplo, "US" para Estados Unidos, "MX" para México).
     - **ST (State or Province)**:  Indica el estado o provincia de la entidad. Nombre completo del estado o provincia (por ejemplo, "California").
     - **L (Locality)**: Especifica la localidad o ciudad de la entidad. Nombre completo de la ciudad (por ejemplo, "San Francisco").
     - **O (Organization)**:  Indica el nombre de la organización a la que pertenece la entidad. Nombre completo de la organización (por ejemplo, "Example Corp").
     - **OU (Organizational Unit)**: Especifica la unidad organizativa dentro de la organización. Nombre de la unidad organizativa (por ejemplo, "IT Department").
     - **CN (Common Name)**: Es el nombre común de la entidad y suele ser el nombre del servidor o el dominio para el cual se emite el certificado.  Nombre completo del dominio o servidor (por ejemplo, "www.example.com").

  **5. Validez**
   - Período de vigencia del certificado:
     - `Not Before`: Fecha de inicio.
     - `Not After`: Fecha de expiración.

  **6. Sujeto (Subject)**
   - Información de la entidad propietaria del certificado (ej: un dominio):
     - `CN`: Nombre común (ej: `*.example.com` para certificados wildcard).
     - `O`, `C`, `L`: Datos de la organización.


  **7. Clave Pública del Sujeto**
   - Contiene:
     - **Algoritmo de clave pública** (ej: RSA, ECDSA).
     - **Clave pública** del servidor (en formato PEM o DER).

 
  **8. Extensiones (X.509 v3)**
   - Campos adicionales críticos para seguridad y funcionalidad:
     - **Subject Alternative Names (SAN)**: Lista de dominios cubiertos (ej: `DNS:example.com`, `DNS:www.example.com`).
     - **Key Usage**: identificas  el propósito de un certificado.  (ej:  `Server Authentication para aplicaciones como postgresql`, `Digital Signature`, `Key Encipherment`). 
     - **Extended Key Usage**: Casos específicos (ej: `TLS Web Server Authentication`).
     - **Basic Constraints**: Indica si el certificado es de una CA (generalmente `CA:FALSE` para certificados de servidor).
     - **CRL Distribution Points**: URL para listas de revocación (CRL).
     - **Authority Key Identifier**: Identificador de la CA que lo firmó.
     - **Certificate Policies**: Políticas de la CA (ej: `2.23.140.1.2.1` para certificados validados por dominio).
 
  **9. Firma de la CA**
   - Firma digital generada con la clave privada de la CA para validar la autenticidad del certificado.
   
 
### Ejemplo de Estructura con OpenSSL
Para inspeccionar un certificado:
```bash
openssl x509 -in example_com.crt -text -noout
```
Salida relevante:

```plaintext
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            04:92:4b:7e:8b:6a:2e:3d:1a:2b:3c:4d:5e:6f:7a:8b
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=US, O=DigiCert Inc, CN=DigiCert Global Root CA
        Validity
            Not Before: Jan  1 00:00:00 2023 GMT
            Not After : Dec 31 23:59:59 2025 GMT
        Subject: C=US, ST=California, L=San Francisco, O=Example Inc, CN=*.example.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:af:82:3b:4c:5d:6e:7f:8a:9b:ac:bd:ce:df:ef:
                    00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:
                    ...
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Alternative Name: 
                DNS:example.com, DNS:www.example.com
            X509v3 Key Usage: 
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 CRL Distribution Points: 
                URI:http://crl3.digicert.com/ExampleRootCA.crl
            Authority Information Access: 
                OCSP - URI:http://ocsp.digicert.com
                CA Issuers - URI:http://cacerts.digicert.com/ExampleRootCA.crt
            X509v3 Authority Key Identifier: 
                keyid:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
            X509v3 Certificate Policies: 
                Policy: 2.23.140.1.2.1
    Signature Algorithm: sha256WithRSAEncryption
         00:ab:cd:ef:12:34:56:78:90:ab:cd:ef:12:34:56:78:
         90:ab:cd:ef:12:34:56:78:90:ab:cd:ef:12:34:56:78:
         ...
```
 
# [Mejores proveedores de certificados SSL ](https://www.ssldragon.com/es/blog/mejores-proveedores-certificados-ssl/)

1. **Sectigo (anteriormente Comodo)**: Es uno de los mayores proveedores de certificados SSL, conocido por su asequibilidad y amplia gama de productos.
2. **DigiCert**: Reconocido por sus certificados de alta garantía, es una opción popular entre grandes empresas e instituciones financieras.
3. **Thawte**: Ofrece certificados SSL de bajo coste y tiene una reputación mundialmente reconocida por la seguridad de sitios web.
4. **GeoTrust**: Con más de 100,000 clientes en 150 países, es una de las marcas de seguridad web más confiables.
5. **RapidSSL**: Especializado en certificados SSL económicos y con un proceso de emisión ultrarrápido.
6. **GlobalSign**: Una Autoridad de Certificación consolidada y un reconocido distribuidor de certificados digitales.
 



# Info extra

```Markdown
La extensión extendedKeyUsage (EKU) en los certificados X.509 define los propósitos específicos para los cuales se puede utilizar la clave pública del certificado.

	1. **serverAuth**: Autenticación de servidor. Utilizado en certificados de servidores web para establecer conexiones HTTPS seguras.
	2. **clientAuth**: Autenticación de cliente. Utilizado en certificados de clientes para autenticarse ante servidores.
	3. **codeSigning**: Firma de código. Utilizado para firmar software y asegurar que no ha sido alterado.
	4. **emailProtection**: Protección de correo electrónico. Utilizado para firmar y cifrar correos electrónicos.
	5. **timeStamping**: Sellado de tiempo. Utilizado para firmar sellos de tiempo que prueban la existencia de un documento en un momento específico.
	6. **OCSPSigning**: Firma de respuestas OCSP (Online Certificate Status Protocol). Utilizado por servidores OCSP para firmar respuestas que verifican el estado de los certificados.
	7. **ipsecEndSystem**: Utilizado en sistemas finales IPsec para asegurar comunicaciones IP.
	8. **ipsecTunnel**: Utilizado en túneles IPsec para asegurar comunicaciones IP.
	9. **ipsecUser**: Utilizado en usuarios IPsec para asegurar comunicaciones IP.
	10. **smartcardLogon**: Utilizado para autenticación de inicio de sesión con tarjetas inteligentes.

 
 
La extensión **keyUsage** en los certificados X.509 define los usos específicos permitidos para la clave criptográfica asociada con el certificado. 

	1. **digitalSignature**: Permite el uso de la clave para firmar digitalmente datos, como documentos o transacciones. Es común en certificados de servidor y cliente.
	2. **nonRepudiation**: Permite el uso de la clave para firmar datos de manera que el firmante no pueda negar haber realizado la firma. Es importante para la autenticidad y la integridad de los datos.
	3. **keyEncipherment**: Permite el uso de la clave para cifrar claves de sesión, que luego se utilizan para cifrar datos. Es común en certificados de servidor para establecer conexiones seguras.
	4. **dataEncipherment**: Permite el uso de la clave para cifrar datos directamente, en lugar de claves de sesión.
	5. **keyAgreement**: Permite el uso de la clave para acordar claves de sesión con otros participantes, como en el protocolo Diffie-Hellman.
	6. **keyCertSign**: Permite el uso de la clave para firmar otros certificados. Es esencial para certificados de autoridad certificadora (CA).
	7. **cRLSign**: Permite el uso de la clave para firmar listas de revocación de certificados (CRL), que se utilizan para revocar certificados emitidos previamente.
	8. **encipherOnly**: Permite el uso de la clave solo para cifrar datos, en combinación con keyAgreement.
	9. **decipherOnly**: Permite el uso de la clave solo para descifrar datos, en combinación con keyAgreement.

 ```
