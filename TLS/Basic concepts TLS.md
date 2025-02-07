 
### ¿Qué es TLS?
TLS (Transport Layer Security) es un protocolo criptográfico diseñado para proporcionar seguridad en las comunicaciones a través de redes informáticas. Este protocolo cifra los datos para que no puedan ser leídos ni modificados por terceros durante su transmisión.

### ¿Para qué sirve TLS?
TLS garantiza tres aspectos fundamentales de la seguridad en línea:
1. **Confidencialidad**: Los datos transmitidos están cifrados, lo que impide que sean leídos por personas no autorizadas.
2. **Integridad**: Asegura que los datos no sean alterados durante su transmisión.
3. **Autenticación**: Verifica la identidad de las partes involucradas en la comunicación, asegurando que los datos se envían y reciben de manera segura.

### Usos comunes de TLS
TLS se utiliza en una variedad de aplicaciones para proteger la información sensible:
- **Navegación web segura**: Asegura las conexiones HTTPS, protegiendo la información que se envía entre el navegador y el servidor web.
- **Correo electrónico**: Protege los correos electrónicos durante su transmisión entre servidores de correo.
- **Transacciones en línea**: Asegura las transacciones financieras y compras en línea, protegiendo los datos de tarjetas de crédito y otra información sensible.
- **Transferencia de archivos**: Protege la transferencia de archivos a través de redes, asegurando que los datos no sean interceptados ni modificados.
 
 
### Tipos de certificados emitidos por una Autoridad de Certificación (CA) y sus usos comunes:

1. **Certificados DV (Domain Validation)**:
   - **Uso**: Blogs, sitios web personales.
   - **Validación**: Verificación de control sobre el dominio.Solo si no hay requisitos estrictos de compliance y los servidores son internos.

2. **Certificados OV (Organization Validation)**:
   - **Uso**: Sitios web comerciales, organizaciones.
   - **Validación**: Verifican la propiedad del dominio y la existencia de la empresa.  Ideal para entornos críticos, ya que valida la identidad de la empresa y es aceptado en auditorías.

3. **Certificados EV (Extended Validation)**:
   - **Uso**: Bancos, tiendas en línea. (es para páginas web públicas).
   - **Validación**: Verificación exhaustiva de la identidad del solicitante.  Ofrecen el mayor nivel de verificación y seguridad.

4. **Certificados Wildcard**:
   - **Uso**: Protección de un dominio y todos sus subdominios.
   - **Ejemplo**: `*.example.com` protege `www.example.com`, `mail.example.com`, etc.

5. **Certificados Multi-Dominio (SAN [Subject Alternative Name])**:
   - **Uso**: Protección de múltiples dominios con un solo certificado.
   - **Ejemplo**: `example.com`, `example.net`, `example.org`.

6. **Certificados de Firma de Código**:
   - **Uso**: Garantizar la autenticidad e integridad del software.
   - **Ejemplo**: Firmar aplicaciones y software.

7. **Certificados de Correo Electrónico (S/MIME)**:
   - **Uso**: Seguridad en correos electrónicos, asegurando que los mensajes no sean alterados y verificando la identidad del remitente.
   - **Ejemplo**: Comunicaciones seguras por correo electrónico en entornos corporativos.

 

 
## **Estructura de un Certificado TLS (X.509)**
Un certificado TLS contiene información técnica y metadatos que permiten autenticar un servidor o entidad. Su estructura se divide en secciones clave:


### 1. **Versión del Certificado**
   - Indica la versión del estándar X.509 usado (ej: v3, la más común).
   
   
### 2. **Número de Serie**
   - Identificador único asignado por la CA para distinguir certificados.

### 3. **Algoritmo de Firma**
   - Algoritmo usado por la CA para firmar el certificado (ej: `SHA256-RSA`, `ECDSA`).

### 4. **Emisor (Issuer)**
   - Información de la CA que emitió el certificado, en formato **DN (Distinguished Name)**:
     - `CN` (Common Name): Nombre de la CA (ej: `DigiCert Global Root CA`).
     - `O` (Organization): Organización emisora.
     - `C` (Country): País.
     - `L` (Locality): Localidad.

### 5. **Validez**
   - Período de vigencia del certificado:
     - `Not Before`: Fecha de inicio.
     - `Not After`: Fecha de expiración.

### 6. **Sujeto (Subject)**
   - Información de la entidad propietaria del certificado (ej: un dominio):
     - `CN`: Nombre común (ej: `*.example.com` para certificados wildcard).
     - `O`, `C`, `L`: Datos de la organización.

### 7. **Clave Pública del Sujeto**
   - Contiene:
     - **Algoritmo de clave pública** (ej: RSA, ECDSA).
     - **Clave pública** del servidor (en formato PEM o DER).



### 8. **Extensiones (X.509 v3)**
   - Campos adicionales críticos para seguridad y funcionalidad:
     - **Subject Alternative Names (SAN)**: Lista de dominios cubiertos (ej: `DNS:example.com`, `DNS:www.example.com`).
     - **Key Usage**: Uso permitido de la clave (ej: `Digital Signature`, `Key Encipherment`).
     - **Extended Key Usage**: Casos específicos (ej: `TLS Web Server Authentication`).
     - **Basic Constraints**: Indica si el certificado es de una CA (generalmente `CA:FALSE` para certificados de servidor).
     - **CRL Distribution Points**: URL para listas de revocación (CRL).
     - **Authority Key Identifier**: Identificador de la CA que lo firmó.
     - **Certificate Policies**: Políticas de la CA (ej: `2.23.140.1.2.1` para certificados validados por dominio).
	 
	 
### 9. **Firma de la CA**
   - Firma digital generada con la clave privada de la CA para validar la autenticidad del certificado.
   
   
   
   
   
   
   
   
## **¿Qué entrega el proveedor CA?**
Cuando solicitas un certificado TLS, la CA te entrega los siguientes elementos:


### 1. **Certificado del Servidor**
   - **Formato común**: `.crt`, `.pem`, o `.cer`.
   - **Contenido**: Certificado firmado que incluye:
     - Clave pública del servidor.
     - Metadatos (emisor, sujeto, SAN, etc.).
     - Firma de la CA.
	 
### 2. **Certificados Intermedios (Chain)**
   - **Formato**: `.ca-bundle`, `.chain.crt`.
   - **Contenido**: Certificados intermedios necesarios para completar la cadena de confianza desde tu certificado hasta la **CA raíz**. Sin ellos, algunos clientes no validarán el certificado.
   
   

### 3. **Clave Privada (NO la entrega la CA)**
   - **Importante**: La clave privada (`.key`) se genera localmente al crear el CSR (Certificate Signing Request) y **nunca es compartida con la CA**. Debes protegerla.

### 4. **Archivo PKCS#12 (Opcional)**
   - **Formato**: `.pfx` o `.p12`.
   - **Contenido**: Empaqueta el certificado, la clave privada y los certificados intermedios en un archivo protegido por contraseña (útil para servidores como IIS).
   
   
## **Extensiones de Archivos Comunes**
| Extensión | Descripción |
|-----------|-------------|
| `.crt`, `.cer`, `.pem` | Certificado público (texto Base64 o binario). |
| `.key` | Clave privada del servidor (¡nunca compartir!). |
| `.csr` | Solicitud de firma de certificado (Certificate Signing Request). |
| `.p12`, `.pfx` | Contenedor PKCS#12 con certificado, clave privada e intermedios. |
| `.der` | Certificado en formato binario (no textual). |



## **Proceso de Obtención**
1. **Generar CSR**: 
   ```bash
   openssl req -new -newkey rsa:2048 -nodes -keyout example_com.key -out example_com.csr
   ```
2. **Enviar CSR a la CA**: Proporcionas el CSR para que la CA firme el certificado.
3. **Validación**: La CA verifica la propiedad del dominio (DV, OV, EV).
4. **Entrega**: Recibes el certificado firmado y los intermedios.




## **Ejemplo de Estructura con OpenSSL**
Para inspeccionar un certificado:
```bash
openssl x509 -in example_com.crt -text -noout
```

Salida relevante:
```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 12:34:56:78:9a:bc:de:f0
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, O = DigiCert Inc, CN = DigiCert TLS RSA SHA256 2020 CA1
        Validity
            Not Before: Jan 1 00:00:00 2024 GMT
            Not After : Jan 1 00:00:00 2025 GMT
        Subject: CN = example.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus: ...
        X509v3 extensions:
            X509v3 Subject Alternative Name:
                DNS:example.com, DNS:www.example.com
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value: ...
```


# Herramientas para automatizar la certificación de servidores
| **Herramienta** | **Uso** |
|-----------------------|-------------------------------------------------------------------------|
| **HashiCorp Vault** | Emite certificados bajo demanda via API con PKI dinámica. |
| **Ansible/Puppet** | Despliega certificados, claves y configuración en masa. |
| **OpenSSL Scripts** | Scripts personalizados para generar CSRs y firmar en lote. |
| **Certbot (Let’s Encrypt)** | Solo aplica si los servidores tienen DNS público y pueden validarse automáticamente. |
| **Ansible/Puppet/Chef** | Para despliegue automatizado de certificados. |

## **Consejos Clave**
- **SAN (Subject Alternative Name)**: Esencial para certificados multi-dominio.
- **Cadena de Confianza**: Instala siempre los certificados intermedios.
- **Formato PEM vs DER**: PEM es textual (comienza con `-----BEGIN CERTIFICATE-----`), DER es binario.

 
### ¿Qué es un CRL?

Un **CRL (Lista de Revocación de Certificados)** es como una lista negra de certificados que ya no son confiables. Imagina que tienes una tarjeta de identificación, y si alguien la pierde o se la roban, esa tarjeta se pone en una lista para que nadie más pueda usarla.

### ¿Por qué es importante?

Es importante porque ayuda a asegurar que las conexiones entre tu computadora y el servidor de la base de datos sean seguras. Si alguien intenta usar un certificado que está en la lista negra, la conexión no se permitirá.

### ¿Cuándo lo necesitas?

- **Lo necesitas** si estás manejando información sensible y quieres asegurarte de que todas las conexiones sean seguras.
- **No lo necesitas** si estás trabajando en un proyecto pequeño o en un entorno donde la seguridad no es una gran preocupación.



 
