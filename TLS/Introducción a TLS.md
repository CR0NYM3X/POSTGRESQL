
# Secure TCP/IP Connections with SSL/TLS 

### ¿Qué es TLS (Transport Layer Security)? !🔒
 Versión mejorada de SSL Es un protocolo criptográfico de seguridad que proporciona **privacidad** y **integridad** en las comunicaciones entre aplicaciones y usuarios en Internet. TLS asegura que los datos transmitidos entre un cliente (como un navegador web) y un servidor no puedan ser interceptados o alterados por terceros. **TLS** utiliza **certificados X.509** para autenticar la identidad del servidor (y opcionalmente del cliente) antes de establecer una conexión segura.
- Los **certificados** son una parte esencial del proceso de **autenticación** en el protocolo **TLS**.  [las versiones permitidas son 1.2 y 1.3](https://documentation.meraki.com/General_Administration/Privacy_and_Security/TLS_Protocol_and_Compliance_Standards).

**⚠️ Advertencias**
  - **Vulnerabilidades de TLS 1.0 y 1.1**: Las versiones antiguas de TLS (1.0 y 1.1) tienen múltiples vulnerabilidades conocidas y no deben utilizarse.  [Windows deshabilita 1.0 y 1.1 ](https://learn.microsoft.com/es-es/lifecycle/announcements/transport-layer-security-1x-disablement)

 
## Características y Propósitos Principales de TLS

- **Confidencialidad** 🔐: TLS cifra los datos transmitidos para que solo el destinatario previsto pueda leerlos. Esto protege la información sensible, como contraseñas, datos personales y transacciones financieras, de ser interceptada por terceros.
- **Integridad de los Datos** 🛡️: TLS asegura que los datos no sean alterados durante la transmisión. Utiliza funciones hash criptográficas para verificar que los datos recibidos son los mismos que los enviados, sin modificaciones.
- **Autenticación** ✅: TLS verifica la identidad de las partes que se comunican. Utiliza certificados digitales emitidos por autoridades de certificación (CA) confiables para autenticar la identidad del servidor (y a veces del cliente), evitando ataques de suplantación de identidad.


### ¿Qué es SSL (Secure Sockets Layer) ? 🔒
Es un protocolo criptográfico desarrollado para proporcionar comunicaciones seguras entre un cliente y un servidor. Fue pionero en la seguridad de las comunicaciones en línea. Con el tiempo, SSL evolucionó a TLS, mejorando significativamente tanto la seguridad como la eficiencia. Debido a las vulnerabilidades conocidas en SSL, ya no se recomienda su uso."

**⚠️ Advertencias**
  - **Vulnerabilidades de SSL**: Las versiones antiguas de SSL (1.0, 2.0 y 3.0) tienen múltiples vulnerabilidades conocidas y no deben utilizarse. [vulnerabilidades de SSL](https://nicolascoolman.eu/es/2024/10/17/openssl-securite-2/)


### Motivo de migación de ssl a tls 
El cambio de SSL a TLS fue una evolución necesaria para abordar fallas de seguridad, establecer un protocolo estandarizado bajo el IETF y alinearse con las prácticas criptográficas modernas. TLS continúa evolucionando, lo que garantiza una protección sólida para las comunicaciones por Internet, mientras que SSL sigue obsoleto debido a sus riesgos inherentes.
TLS: Rendimiento y compatibilidad, Mejoras continuas, Estandarización por parte de la IETF

 
## Ejemplo de TLS en la vida real

**Escenario: Envío de Cartas**

Imagina que tienes que enviar una carta importante a tu amigo que vive en otra ciudad. Esta carta contiene información personal y confidencial.

**📬 Sin TLS (sin cifrado):**

En este caso, decides enviar la carta en un sobre transparente. Cualquiera que maneje la carta, desde el cartero hasta cualquier persona que la vea en el camino, puede leer su contenido. Aunque la carta puede llegar a su destino, existe un alto riesgo de que alguien más lea la información confidencial antes de que llegue a tu amigo.

**🔒 Con TLS (con cifrado):**

Ahora, decides enviar la carta en un sobre opaco y sellado. Solo tu amigo, que tiene la llave para abrir el sobre, puede leer el contenido de la carta. Durante el trayecto, nadie más puede ver lo que hay dentro del sobre, asegurando que la información permanezca privada y segura hasta que llegue a su destino.

 
 
## Aplicaciones Comunes de TLS
- **Bases de Datos** 🗄️: Protege las conexiones a bases de datos como PostgreSQL, garantizando que los datos transmitidos entre el cliente y el servidor estén cifrados y autenticados.
- **Autenticación** 🔑: TLS se utiliza en sistemas de autenticación para verificar la identidad de los usuarios y asegurar que las credenciales no sean interceptadas durante la transmisión.
- **Navegadores Web** 🌐: Protege las conexiones HTTPS, asegurando que la comunicación entre el navegador y el servidor web sea segura.
- **Correo Electrónico** 📧: Asegura la transmisión de correos electrónicos entre servidores.
- **Mensajería Instantánea** 💬: Protege los mensajes enviados a través de aplicaciones de chat.
- **VPNs (Redes Privadas Virtuales)** 🔒: Asegura las conexiones entre dispositivos y redes privadas.



## Beneficios de Usar TLS y Por Qué Deberíamos Utilizarlo

- **Seguridad Mejorada**: Protege contra ataques como la interceptación de datos  y la manipulación conocida como (MITM).
- **Confianza del Usuario**: Los usuarios confían más en sitios web o servicios que utilizan TLS.
- **Cumplimiento Normativo**: TLS ayuda a cumplir normativas de seguridad  y estándares aplicables, como : 
    1. **PCI DSS**: El Consejo de Normas de Seguridad de la Industria de Tarjetas de Pago (PCI SSC) proporciona información sobre los requisitos de seguridad para proteger los datos de las cuentas de pago. Puedes visitar su sitio oficial [aquí](https://www.pcisecuritystandards.org/faq/articles/Frequently_Asked_Question/does-pci-dss-define-which-versions-of-tls-must-be-used/).
    
    2. **HIPAA**: El Departamento de Salud y Servicios Humanos de los Estados Unidos (HHS) ofrece información sobre la Ley de Portabilidad y Responsabilidad de Seguros de Salud (HIPAA), incluyendo las reglas de seguridad y privacidad. Puedes acceder a su sitio oficial [aquí](https://www.hhs.gov/hipaa/for-professionals/breach-notification/guidance/index.html).
    
    3. **NIST**: El Instituto Nacional de Estándares y Tecnología (NIST) desarrolla y mantiene estándares, incluyendo los relacionados con la ciberseguridad y el uso de TLS. Puedes visitar su sitio oficial [aquí](https://csrc.nist.gov/pubs/sp/800/52/r2/final).

    4. **GDPR**: El Reglamento General de Protección de Datos (GDPR, por sus siglas en inglés) es una ley de la Unión Europea que entró en vigor el 25 de mayo de 2018. Su objetivo principal es proteger los datos personales de los ciudadanos de la UE y garantizar su privacidad. El GDPR establece normas estrictas sobre cómo las organizaciones deben manejar y proteger los datos personales, y otorga a los individuos varios derechos sobre sus datos, como el derecho al acceso, rectificación, supresión y portabilidad  [Reglamento general de protección de datos (GDPR)](https://eur-lex.europa.eu/ES/legal-content/summary/general-data-protection-regulation-gdpr.html).

 
## Resumen Rápido del Funcionamiento de TLS

1. **Negociación de la Conexión** 🔄: El cliente y el servidor inician la conexión acordando los parámetros de seguridad, como la versión de TLS y los algoritmos de cifrado a utilizar.
2. **Intercambio de Claves** 🔑: Se realiza un intercambio de claves criptográficas mediante un protocolo seguro, como el intercambio de claves Diffie-Hellman, para establecer una conexión segura.
3. **Cifrado de Datos** 🔒: Una vez establecida la conexión segura, los datos se cifran y se transmiten de manera segura entre el cliente y el servidor, protegiendo la información contra interceptaciones y manipulaciones.

**Diagrama en PlantUML**
```plantuml
@startuml
title Proceso Básico de TLS

actor Cliente
actor Servidor

Cliente -> Servidor: Solicitud de Conexión (ClientHello)
Servidor -> Cliente: Respuesta de Conexión (ServerHello)
Servidor -> Cliente: Certificado del Servidor
Servidor -> Cliente: Solicitud de Clave Pública
Cliente -> Servidor: Clave Pública del Cliente
Cliente -> Cliente: Genera Clave Simétrica
Cliente -> Servidor: Clave Simétrica Cifrada
Servidor -> Servidor: Desencripta Clave Simétrica
Cliente -> Servidor: Mensaje Cifrado
Servidor -> Cliente: Mensaje Cifrado

note right of Cliente
  1. Negociación de la Conexión
  2. Intercambio de Claves
  3. Cifrado de Datos
end note

@enduml
```


## Desventajas de Implementar TLS

- **⚙️ Complejidad de Configuración**: Configurar TLS correctamente puede ser complicado y requiere conocimientos técnicos avanzados. Esto incluye la generación y gestión de certificados, la configuración de los parámetros de seguridad y la actualización regular de estos certificados.
- **📉 Rendimiento**: El cifrado y descifrado de datos puede introducir una sobrecarga en el rendimiento del sistema. Esto puede ser especialmente notable en sistemas con alta carga de trabajo o en aquellos que manejan grandes volúmenes de datos.
- **🔧 Mantenimiento Adicional**: TLS requiere un mantenimiento continuo, como la renovación de certificados y la actualización de las versiones de TLS para asegurar que se utilizan las versiones más seguras y actualizadas.
- **🔄 Administración de Certificados**: La rotación automática de certificados, el monitoreo constante y la validación por personal especializado son necesarios para mantener la seguridad. Esto puede requerir recursos adicionales y personal capacitado.
- **🔗 Compatibilidad**: No todos los clientes o aplicaciones pueden ser compatibles con las versiones más recientes de TLS. Esto puede requerir actualizaciones o modificaciones adicionales en el software cliente.
- **💰 Costos**: Aunque TLS en sí mismo es gratuito, los certificados SSL/TLS emitidos por autoridades de certificación (CA) pueden tener un costo que varía dependiendo del tipo de certificado. Además, el tiempo y los recursos necesarios para implementar y mantener TLS también pueden representar un costo significativo.



 




---

# conjunto de **cipher suites** (algoritmos de cifrado) 
los cipher suites Están **ligado directamente a la versión de TLS**. Cada versión del protocolo define qué algoritmos son compatibles, seguros y recomendados.


## 🔐 Comparativa de versiones TLS y sus características criptográficas

| 🧾 **Versión TLS** | ⚙️ **Características Criptográficas**                                                                 | 🔑 **Cipher Suites Representativos**                                    | 🚨 **Estado Actual / Compatibilidad**                  |
|-------------------|--------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------|--------------------------------------------------------|
| **TLS 1.0 / 1.1** | Utiliza algoritmos considerados inseguros como `RC4`, `3DES`, `MD5`. No soporta cifrado AEAD moderno.  | `TLS_RSA_WITH_3DES_EDE_CBC_SHA`<br>`TLS_RSA_WITH_RC4_128_MD5`          | ⚠️ Obsoletos — deshabilitados por defecto en sistemas modernos |
| **TLS 1.2**       | Introduce soporte para `AES-GCM`, `SHA256`, `SHA384`, `ECDHE`. Permite mayor flexibilidad en cifrado.  | `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256`<br>`TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384` | ✅ Amplio uso, pero algunos cipher suites han sido desaprobados |
| **TLS 1.3**       | Simplifica el handshake y elimina ciphers inseguros. Solo permite cifrado AEAD moderno con autenticación integrada. | `TLS_AES_128_GCM_SHA256`<br>`TLS_AES_256_GCM_SHA384`<br>`TLS_CHACHA20_POLY1305_SHA256` | 🔒 Recomendado — cipher suites modernizados y más seguros |
 

##   ¿Por qué se eliminan ciphers?

Porque algunos algoritmos han demostrado ser inseguros con el tiempo. TLS 1.3 fue diseñado para:

- Simplificar el handshake
- Eliminar vulnerabilidades conocidas
- Usar solo cifrado moderno y robusto


### Ver los ciphers de openssl
Aunque OpenSSL lo clasifica como un cipher , en realidad algunos  cipher suite pueden ser compatible con TLS 1.0, 1.1 y 1.2. OpenSSL agrupa los cipher suites según la versión mínima del protocolo que los introdujo, no la máxima en la que pueden usarse.
```
### Ver todos los algoritmos que se pueden usar 
openssl ciphers -v | column -t

### Ver version de openssl y las rutas kpi 
openssl version -a 

### Excluyes algoritmos 
openssl ciphers -v '!MD5:!RC4:!3DES:!DES:!IDEA:!RC2:!SHA1:!NULL:!aNULL:!EXP' | column -t

### Ver algoritmos vulnerables para algun TEST no para colocar en producion 
openssl ciphers -v 'MD5:RC4:3DES:DES:IDEA:RC2:SHA1:NULL:aNULL:EXP'
openssl ciphers -v 'RC4-MD5:RC4-SHA:DES-CBC3-SHA:IDEA-CBC-SHA:RC2-CBC-MD5:EXP-RC4-MD5:EXP-DES-CBC-SHA:NULL-MD5:NULL-SHA:MD5'

```



###   **Estructura típica de un cipher suite (TLS 1.2)**

Un cipher suite suele tener esta forma:

```
TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
```

Y se divide así:

| Componente         | ¿Qué hace?                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| `TLS`              | Indica el protocolo (TLS o SSL).                                            |
| `ECDHE`            | Algoritmo de **intercambio de claves** (aquí, Diffie-Hellman efímero con curvas elípticas). |
| `RSA`              | Algoritmo de **autenticación** (firma digital del servidor).                |
| `AES_256_CBC`      | Algoritmo de **cifrado simétrico** (AES de 256 bits en modo CBC).           |
| `SHA`              | Algoritmo de **integridad** (HMAC con SHA-1).                              |

 

### 🔐 ¿Para qué sirve cada parte?

1. **Intercambio de claves**:  
   Permite que cliente y servidor acuerden una clave secreta sin que nadie más pueda interceptarla.

2. **Autenticación**:  
   Verifica que el servidor (y a veces el cliente) es quien dice ser, usando certificados digitales.

3. **Cifrado simétrico**:  
   Protege los datos transmitidos usando la clave compartida. Solo cliente y servidor pueden leerlos.

4. **Integridad (MAC)**:  
   Asegura que los datos no hayan sido modificados en tránsito.

 

###   Ejemplo visual

```text
TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
│   │     │           │             │
│   │     │           │             └──→ Algoritmo de integridad (SHA-1)
│   │     │           └────────────────→ Cifrado simétrico (AES 256 bits, modo CBC)
│   │     └────────────────────────────→ Autenticación (RSA)
│   └──────────────────────────────────→ Intercambio de claves (ECDHE)
└──────────────────────────────────────→ Protocolo (TLS)
```

---

###   Notas importantes

- En **TLS 1.3**, esta estructura se simplifica: ya no se negocian por separado todos estos algoritmos, sino que se usan suites predefinidas más seguras como `TLS_AES_128_GCM_SHA256`.
- Algunos algoritmos como `SHA-1` o `CBC` ya no se consideran seguros y deben evitarse.

  
### 📚 **Fuentes oficiales y técnicas para consultar cipher suites**

| Sitio web | Descripción |
|-----------|-------------|
| [IANA Cipher Suites Registry](https://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml#tls-parameters-4) | Mantenido por la IANA, contiene la lista oficial de *cipher suites* registrados para TLS. Es la fuente más formal y estandarizada. |
| [CipherSuite.info](https://ciphersuite.info/) | Base de datos interactiva con más de 300 cipher suites. Puedes buscar por nombre, protocolo, seguridad, etc. Muy útil para administradores. |
| [Wikipedia - Cipher Suite](https://en.wikipedia.org/wiki/Cipher_suite) | Buena introducción con explicaciones claras sobre la estructura y propósito de cada parte del cipher. |
| [Stellastra Cipher Suite Database](https://stellastra.com/cipher-suite/) | Lista extensa con descripciones técnicas de cada cipher suite, ideal para análisis de seguridad. |
 

---



 

### 🔍 ¿Qué es SNI (Server Name Indication)?

- Es una **extensión del protocolo TLS**, **no** del certificado.
- Permite que un cliente (como `psql`, navegadores, etc.) **indique el nombre del host** al que quiere conectarse **durante el handshake TLS**.
- Esto ayuda al servidor a presentar el **certificado SSL correcto** si aloja varios dominios en una misma IP.
- **No está dentro del certificado X.509**, se transmite aparte como parte del protocolo TLS.

---

### ⚙️ ¿Qué es el parámetro `sslsni` en PostgreSQL?

- Es un **parámetro de conexión** que se puede usar desde **PostgreSQL 14 en adelante**.
- Cuando está activado (`sslsni=1` o `sslsni=true`), **el cliente incluye el hostname** como parte del handshake TLS (usando SNI).
- Es útil si:
  - El servidor tiene certificados distintos por dominio.
  - Hay un **proxy o balanceador SSL** que requiere esa información.

---

### 🧪 ¿Dónde se configura?

- Se coloca como parte de la **cadena de conexión** o en **variables de entorno** del cliente (como `psql`, `libpq`, drivers JDBC, etc.).
- **Ejemplo básico usando `psql`:**

```bash
psql "host=db.miempresa.com port=5432 dbname=miapp user=usuario password=secreto sslmode=require sslsni=1"
```

- **En variables de entorno (UNIX):**

```bash
export PGHOST=db.miempresa.com
export PGDATABASE=miapp
export PGUSER=usuario
export PGPASSWORD=secreto
export PGSSLMODE=require
export PGSSLSNI=1
psql
```
 

