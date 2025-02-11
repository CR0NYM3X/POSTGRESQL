
### 📜 ¿Qué son los certificados?
Los **certificados** son documentos digitales que verifican la identidad de una entidad (como un servidor, un usuario o un dispositivo) en una red. Funcionan como una especie de "pasaporte digital" que asegura que la comunicación entre dos partes es segura y confiable. Utilizan **criptografía de clave pública** para cifrar y firmar digitalmente la información, garantizando así la autenticidad y la integridad de los datos transmitidos.

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

4. **🖊️ Certificados de Firma de Código**:
   - **Uso**: Utilizados para firmar digitalmente software y scripts.
   - **Modelo**: Aseguran que el código no ha sido alterado desde su firma.

5. **👤 Certificados de Autenticación de Cliente**:
   - **Uso**: Utilizados para autenticar usuarios en aplicaciones y servicios.
   - **Modelo**: Pueden estar basados en X.509 o en otros estándares.

### 🔐 Tipos de Certificados para TLS

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
   - **Uso**: Protegen direcciones IP en lugar de nombres de dominio.
   - **Ejemplo**: Útiles para servidores que se acceden directamente por IP.

 
## 📜 Certificados X.509

Los certificados **X.509** son un estándar internacional definido por la ITU (International Telecommunication Union) y normalizados para su uso en Infraestructuras de Clave Pública (PKI) que especifica el formato de los certificados de clave pública. Son ampliamente utilizados en muchos protocolos de Internet, incluyendo **TLS/SSL** 

### 🔍 Características de los certificados X.509

- **Versión**: Indica la versión del estándar X.509.
- **Número de Serie**: Un identificador único para cada certificado emitido por una autoridad de certificación.
- **Algoritmo de Firma**: El algoritmo utilizado por la autoridad de certificación para firmar el certificado.
- **Emisor**: La entidad que emite el certificado.
- **Período de Validez**: Las fechas de inicio y expiración del certificado.
- **Sujeto**: La entidad a la que pertenece el certificado.
- **Clave Pública del Sujeto**: La clave pública utilizada para cifrar datos.
- **Firma Digital del Emisor**: Garantiza la autenticidad del certificado.

Los certificados X.509 son esenciales para establecer una infraestructura de clave pública (PKI) y asegurar las comunicaciones en la red.


### 🏗️ Estructura de un certificado

Un certificado típico contiene:
- **Información del Sujeto**: Datos sobre la entidad a la que pertenece el certificado.
- **Clave Pública del Sujeto**: La clave pública utilizada para cifrar datos.
- **Información del Emisor**: Datos sobre la entidad que emitió el certificado.
- **Período de Validez**: Las fechas de inicio y expiración del certificado.
- **Firma Digital del Emisor**: Garantiza la autenticidad del certificado.
 
 
