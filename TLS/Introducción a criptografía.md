

 ### ¿Qué es un Protocolo Criptográfico? 🔐
 Un **protocolo criptográfico** es un conjunto de reglas que permiten la comunicación segura entre dos o más partes a través de una red. Estos protocolos utilizan técnicas de criptografía para proteger la confidencialidad, integridad y autenticación de los datos transmitidos.


## ¿Qué es un protocolo?
Un **protocolo** es un conjunto de reglas y convenciones que permiten la comunicación entre dispositivos o sistemas. En el contexto de las redes y la informática, los protocolos definen cómo se deben transmitir y recibir los datos para asegurar que la información se intercambie de manera eficiente y segura.

### Características Clave de un Protocolo:
- **Estandarización**: Los protocolos son estándares que aseguran la interoperabilidad entre diferentes dispositivos y sistemas.
- **Formato de Datos**: Definen cómo se estructuran los datos para su transmisión.
- **Secuencia de Comunicación**: Especifican el orden en que se deben enviar y recibir los mensajes.
- **Manejo de Errores**: Incluyen mecanismos para detectar y corregir errores en la transmisión de datos.
- **Seguridad**: Algunos protocolos incorporan medidas para proteger la confidencialidad e integridad de los datos.


## Diferencia entre un **algoritmo de cifrado** y un **algoritmo criptográfico** 
Todos los algoritmos de cifrado son algoritmos criptográficos, pero no todos los algoritmos criptográficos son algoritmos de cifrado. Los algoritmos criptográficos incluyen una gama más amplia de funciones y aplicaciones dentro de la seguridad de la información.
 
### Algoritmo de Cifrado
- **Definición**: Es un tipo específico de algoritmo criptográfico que se utiliza para transformar datos en un formato ilegible para proteger su confidencialidad.
- **Función Principal**: Convertir texto plano en texto cifrado (y viceversa) para asegurar que solo las partes autorizadas puedan leer los datos.
- **Ejemplos**: 
  - **AES (Advanced Encryption Standard)**: Un algoritmo de cifrado simétrico.
  - **RSA (Rivest-Shamir-Adleman)**: Un algoritmo de cifrado asimétrico.

### Algoritmo Criptográfico
- **Definición**: Es un término más amplio que incluye todos los algoritmos utilizados en criptografía para asegurar la información.
- **Función Principal**: Abarca una variedad de funciones criptográficas, no solo el cifrado, sino también la autenticación, la integridad y la generación de claves.
- **Ejemplos**:
  - **Algoritmos de Cifrado**: Como AES y RSA.
  - **Algoritmos de Hash**: Como SHA-256, que se utilizan para asegurar la integridad de los datos.
  - **Algoritmos de Firma Digital**: Como DSA (Digital Signature Algorithm), que se utilizan para autenticar la identidad de los remitentes.

 

## Criptografía Asimétrica y Simétrica

**Criptografía Asimétrica**

- **Uso**: La criptografía asimétrica se utiliza durante el **intercambio de claves** y la **autenticación**.
- **Funcionamiento**: Utiliza un par de claves (pública y privada). La clave pública cifra los datos, y solo la clave privada correspondiente puede descifrarlos.
- **Ejemplo**: RSA es un algoritmo comúnmente utilizado para este propósito.

**Criptografía Simétrica**

- **Uso**: Una vez que se ha establecido una conexión segura y se ha intercambiado una clave de sesión, se utiliza criptografía simétrica para **cifrar los datos** transmitidos.
- **Funcionamiento**: Utiliza la misma clave para cifrar y descifrar los datos, lo que permite un cifrado y descifrado rápido.
- **Ejemplo**: AES (Advanced Encryption Standard) es un algoritmo comúnmente utilizado para el cifrado simétrico.


 
## Protocolos que usan  criptografía :
Los protocolos criptográficos son fundamentales para garantizar la seguridad en las comunicaciones digitales. Cada tipo de protocolo tiene su propio propósito y aplicación, contribuyendo a la protección de datos en diferentes contextos.

### 1. **Protocolos de Cifrado de Datos**

- **AES (Advanced Encryption Standard)**: Utilizado para cifrar datos en bloques de 128 bits.
- **DES (Data Encryption Standard)**: Un estándar más antiguo, ahora considerado inseguro.
- **RSA (Rivest-Shamir-Adleman)**: Utilizado para cifrado y firma digital, basado en la factorización de números grandes.

### 2. **Protocolos de Intercambio de Claves**

- **Diffie-Hellman**: Permite a dos partes generar una clave compartida de manera segura.
- **ECDH (Elliptic Curve Diffie-Hellman)**: Una variante de Diffie-Hellman que utiliza curvas elípticas para mayor seguridad.

### 3. **Protocolos de Autenticación**

- **Kerberos**: Utilizado para la autenticación en redes informáticas.
- **OAuth**: Protocolo de autorización que permite el acceso seguro a recursos protegidos.

### 4. **Protocolos de Firma Digital**

- **DSA (Digital Signature Algorithm)**: Utilizado para la autenticación y la integridad de los datos.
- **ECDSA (Elliptic Curve Digital Signature Algorithm)**: Una variante de DSA que utiliza curvas elípticas.

### 5. **Protocolos de Seguridad de la Red**

- **TLS (Transport Layer Security)**: Proporciona comunicaciones seguras a través de redes.
- **IPsec (Internet Protocol Security)**: Protocolo para asegurar las comunicaciones a nivel de red.
- **TLS (Transport Layer Security)**: Proporciona seguridad en las comunicaciones a través de redes informáticas, como Internet.
- **SSL (Secure Sockets Layer)**: Predecesor de TLS, utilizado para asegurar las conexiones web.
- **IPsec (Internet Protocol Security)**: Protocolo para asegurar las comunicaciones a través de redes IP.
- **SSH (Secure Shell)**: Protocolo para acceder de manera segura a dispositivos remotos.

### 6. **Protocolos de Integridad**
   - **HMAC (Hash-based Message Authentication Code)**: Utiliza una función hash junto con una clave secreta para verificar la integridad y autenticidad de un mensaje.
   - **CRC (Cyclic Redundancy Check)**: Método de verificación de errores utilizado para detectar cambios accidentales en los datos.


 
## **Tipos de cifrados más utilizados en criptografía**  [[1]](https://www.ibm.com/mx-es/think/topics/cryptography-types) [[2]](https://www.sealpath.com/es/blog/tipos-de-cifrado-guia/):
 

### Cifrado Simétrico
- **Definición**: Utiliza la misma clave para cifrar y descifrar los datos.
- **Ejemplos**:
  - **AES (Advanced Encryption Standard)**: Muy seguro y ampliamente utilizado en aplicaciones modernas, cifrar los datos transmitidos una vez que se ha establecido una conexión segura .
  - **DES (Data Encryption Standard)**: Antiguo estándar, ahora considerado inseguro.
  - **3DES (Triple DES)**: Mejora de DES, pero menos eficiente que AES.

### Cifrado Asimétrico
- **Definición**: Utiliza un par de claves, una pública para cifrar y una privada para descifrar.
- **Ejemplos**:
  - **RSA (Rivest-Shamir-Adleman)**: Muy utilizado para el intercambio seguro de claves y firmas digitales.
  - **ECC (Elliptic Curve Cryptography)**: Ofrece la misma seguridad que RSA pero con claves más pequeñas y mayor eficiencia.

### Funciones Hash
- **Definición**: Convierte datos de cualquier tamaño en un valor fijo, utilizado para verificar la integridad de los datos.
- **Ejemplos**:
  - **SHA-256 (Secure Hash Algorithm 256-bit)**: Parte de la familia SHA-2, ampliamente utilizado en seguridad informática.
  - **MD5 (Message Digest Algorithm 5)**: Antiguo estándar, ahora considerado inseguro para aplicaciones críticas.

 





 
