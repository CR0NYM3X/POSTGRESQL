

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


## Números primos
un número primo es un número natural mayor que 1 que tiene únicamente dos divisores positivos y solo es divisible entre 1 y sí mismo Los primos son la base de algoritmos como **RSA** (cifrado asimétrico). 
 
### **¿Por qué son importantes en criptografía?**  
Imagina que los números primos son como **candados únicos**:  
1. Si multiplicas dos primos grandes (ej. `61 × 53 = 3233`), es fácil calcular el resultado.  
2. Pero si solo te dan el **resultado (3233)**, es muy difícil adivinar los primos originales (61 y 53).  

🔐 **Así funciona el cifrado (ej. RSA):**  
- La **clave pública** usa el resultado (`3233`).  
- La **clave privada** necesita los primos originales (`61` y `53`).  
- Sin los primos, **no se puede descifrar el mensaje**.  


⚠️ **Sin los primos originales**, nadie puede abrir el candado fácilmente (¡incluso si saben que `n = 15`!).  

### **¿Por qué usamos primos ENORMES en criptografía?**  
- **Ejemplo con primos pequeños**:  
  - Si `n = 15`, es fácil adivinar que `p = 3` y `q = 5`.  
- **Ejemplo con primos gigantes**:  
  - Si `n = 2,048 bits` (un número de **617 dígitos**), ¡ni las supercomputadoras pueden factorizarlo en años!  


### Criptografía Simétrica (AES)
El algoritmo AES (Advanced Encryption Standard) no utiliza números primos. En cambio, AES utiliza una única clave para cifrar y descifrar datos:
1. **Clave única**: Se utiliza la misma clave para cifrar y descifrar la información.
2. **Bloques de datos**: AES trabaja con bloques de datos y aplica varias rondas de transformación para asegurar la información.
 




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

 



# PKCS (Public Key Cryptography Standards)
es un conjunto de estándares de criptografía de clave pública desarrollados por RSA Security LLC a principios de los años 90. Estos estándares están diseñados para promover el uso de técnicas criptográficas, como el algoritmo RSA, y garantizar la seguridad en la comunicación y el intercambio de datos.

Algunos de los estándares PKCS más conocidos incluyen:

- **PKCS #1**: Define las propiedades matemáticas y el formato de las claves públicas y privadas RSA, así como los algoritmos básicos para realizar cifrado y descifrado RSA.
- **PKCS #7**: También conocido como Cryptographic Message Syntax (CMS), se utiliza para firmar y/o cifrar mensajes bajo una infraestructura de clave pública (PKI). Es la base de S/MIME, que se usa para el correo electrónico seguro.
- **PKCS #11**: Define una interfaz de programación en C para crear y manipular tokens criptográficos que pueden contener claves secretas. Se utiliza a menudo para comunicarse con módulos de seguridad de hardware o tarjetas inteligentes.
 
 


---
# **Modos de operación de cifrado simétrico**
Son técnicas que indican **cómo aplicar un algoritmo de cifrado de bloque (como AES o DES) sobre datos más grandes que el tamaño del bloque**. Un algoritmo como AES cifra bloques de 128 bits, pero los datos reales suelen ser mucho más grandes, por lo que se necesita un modo de operación para manejar esto.

 principales modos y sus características:

	* GCM (Galois/Counter Mode)
	* CCM (Counter with CBC-MAC)
	* CBC (Cipher Block Chaining)
	* ECB (Electronic Codebook)
	* CFB (Cipher Feedback)
	* OFB (Output Feedback)
	* CTR (Counter Mode)


#### **¿Por qué te piden esto?**

Porque quieren saber **qué modo se usa en la conexión SSL/TLS hacia la base de datos**, ya que afecta la seguridad:

*   **GCM o CCM → Muy seguro (TLS 1.2/1.3)**
*   **CBC → Seguro pero menos recomendado (TLS antiguo)**
 

###  **1. GCM (Galois/Counter Mode)**

*   **Cómo funciona:** Basado en CTR, pero añade autenticación (integridad) mediante un código Galois.
*   **Ventajas:** Cifrado + autenticación, muy seguro, rápido.
*   **Uso:** TLS moderno, HTTPS, bases de datos seguras.


###  **2. CCM (Counter with CBC-MAC)**

*   **Cómo funciona:** Combina CTR para cifrado y CBC-MAC para autenticación.
*   **Ventajas:** Seguridad completa (confidencialidad + integridad).
*   **Desventajas:** Más lento que GCM.
*   **Uso:** IoT, protocolos seguros.


###  **3. CBC (Cipher Block Chaining)**

*   **Cómo funciona:** Cada bloque se combina (XOR) con el bloque cifrado anterior antes de cifrarlo.
*   **Ventajas:** Oculta patrones, más seguro que ECB.
*   **Desventajas:** No permite paralelismo en cifrado, vulnerable a ataques si el IV no es aleatorio.
*   **Uso:** Común en TLS antiguas y cifrado de discos.




 
 


