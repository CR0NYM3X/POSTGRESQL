
# Técnicas de vulnerabilidad 

### 1. **`disable`**
- **Técnica vulnerable**: **"Escuchar como un espía"**  
  - **¿Qué pasa?**: Los datos viajan **sin cifrado** (como texto plano).  
  - **Ataque**: Cualquiera en la misma red (Wi-Fi, internet) puede **leer todo lo que envías o recibes** (contraseñas, datos sensibles).  
  - **Ejemplo**: Es como enviar una carta escrita en un postal: cualquiera que la intercepte puede leerla.

---

### 2. **`allow` / `prefer`**
- **Técnica vulnerable**: **"Engañar para no usar cifrado"**  
  - **¿Qué pasa?**: El cliente dice: *"Prefiero no usar cifrado, pero si el servidor me obliga, lo usaré"*.  
  - **Ataque**: Un atacante puede **hacer creer al cliente que el servidor no soporta cifrado**, forzando una conexión sin SSL.  
  - **Ejemplo**: Es como si un intermediario le dijera a dos personas: *"Háblenme en español, no en su código secreto"*, y ellos obedecen.



### 3. **`require`**
- **Técnica vulnerable**: **"Fingir ser el servidor"**  
  - **¿Qué pasa?**: La conexión **está cifrada**, pero el cliente **no verifica la identidad del servidor**.  
  - **Ataque**: Un atacante puede **crear un servidor falso**, establecer una conexión cifrada con el cliente y otra con el servidor real, actuando como intermediario.  
  - **Ejemplo**: Es como recibir una carta cifrada, pero no verificar quién te la envió. Podría ser tu amigo... o un impostor.



### 4. **`verify-ca`**
- **Técnica vulnerable**: **"Usar un certificado falso de la misma fábrica"**  
  - **¿Qué pasa?**: El cliente verifica que el certificado del servidor está firmado por una **autoridad de confianza (CA)**, pero **no verifica el nombre del servidor**.  
  - **Ataque**: Si un atacante obtiene un certificado válido de la misma CA para otro servidor, puede suplantar al servidor real.  
  - **Ejemplo**: Es como aceptar un documento de identidad falso porque está firmado por una entidad real, aunque el nombre no coincida.



### 5. **`verify-full`**
- **Técnica vulnerable**: **Ninguna (si la CA es de confianza)**  
  - **¿Qué pasa?**: El cliente verifica **dos cosas**:  
    1. El certificado está firmado por una CA confiable.  
    2. El nombre en el certificado **coincide exactamente** con el servidor al que te conectas (ej: `bd.miempresa.com`).  
  - **Protección**: Un atacante necesitaría un certificado válido para el nombre exacto del servidor, lo que es casi imposible si la CA es seria.  
  - **Ejemplo**: Es como verificar no solo que un pasaporte es real, sino también que la foto coincide con la persona que lo tiene.



### **Resumen visual**

| Modo         | Tipo de Ataque                         | ¿Qué aprovecha el atacante?                                 |
|--------------|----------------------------------------|-------------------------------------------------------------|
| `disable`    | Espiar datos en texto plano.           | La falta de cifrado.                                        |
| `allow`/`prefer` | Engañar para no usar cifrado.      | La voluntad del cliente de aceptar conexiones sin SSL.      |
| `require`    | Suplantar al servidor con cifrado.     | La falta de verificación de identidad del servidor.         |
| `verify-ca`  | Usar un certificado válido pero incorrecto. | La CA confiable pero permisiva.                     |
| `verify-full`| **Ninguno** (si todo está bien configurado). | -                                           |




### **¿Por qué algunos modos son vulnerables a MITM?**
La clave está en si el cliente **verifica la identidad del servidor** mediante su certificado SSL/TLS. Si no hay validación, un atacante puede suplantar al servidor.

#### 1. **Modos sin validación de certificado**  
   (`disable`, `allow`, `prefer`, `require`):
   - **No se verifica el certificado del servidor**, aunque la conexión esté cifrada (en `require`).
   - **Riesgo MITM**: Un atacante puede interceptar la conexión y presentar un certificado falso (auto-firmado o de una CA no confiable).  
   - Ejemplo en `require`:  
     Aunque el canal está cifrado, si no validas el certificado, **no sabes si el servidor es legítimo**. Un MITM podría actuar como "proxy" entre tú y el servidor real, descifrando y re-cifrando los datos.

#### 2. **Modos con validación parcial**  
   (`verify-ca`):
   - Verifica que el certificado del servidor está firmado por una **CA de confianza**, pero **no valida el nombre del host** (por ejemplo, `servidor.com`).
   - **Riesgo MITM**: Si un atacante obtiene un certificado válido de la misma CA para otro dominio, podría suplantar al servidor.  
   - Ejemplo: Si tu CA emite certificados para `*.example.com`, un certificado para `atacante.example.com` sería aceptado aunque te conectes a `bd.example.com`.

#### 3. **Modo seguro**  
   (`verify-full`):
   - Verifica **dos cosas**:  
     a) El certificado está firmado por una CA de confianza.  
     b) El nombre en el certificado coincide con el host de conexión (ej: `servidor.com`).  
   - **Protección contra MITM**: Un atacante necesitaría un certificado válido para el nombre exacto del servidor, lo que es casi imposible si la CA es confiable.



### **Resumen de vulnerabilidades por modo**
| `sslmode`     | Cifrado | Valida CA | Valida Hostname | Vulnerable a MITM                         |
|---------------|---------|-----------|-----------------|--------------------------------------------|
| `disable`     | No      | No        | No              | Sí (datos en texto plano).                 |
| `allow`/`prefer` | Quizás | No        | No              | Sí (si se usa SSL, pero sin validación).   |
| `require`     | Sí      | No        | No              | Sí (cifrado, pero servidor no autenticado).|
| `verify-ca`   | Sí      | Sí        | No              | Depende de la política de la CA.           |
| `verify-full` | Sí      | Sí        | Sí              | No (mitigado si la CA es segura).          |



 
  ******************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************
  
  
En PostgreSQL, un ataque **Man-in-the-Middle (MITM)** implica interceptar o manipular la comunicación entre un cliente y el servidor de bases de datos. Aquí explicaré cómo podría realizarse, por qué `verify-full` es una defensa clave, y las posibles formas en que un atacante podría intentar evadir esta protección.

---

### **¿Qué se necesita para realizar un MITM en PostgreSQL?**
1. **Interceptar el tráfico**:  
   - Herramientas como **Wireshark**, **tcpdump**, o **ettercap** pueden capturar paquetes no cifrados.
   - Si la conexión no usa SSL/TLS (o está mal configurada), el tráfico (consultas, credenciales, etc.) se expone.

2. **Redirigir el tráfico**:  
   - Técnicas como **ARP spoofing**, **DNS spoofing**, o **BGP hijacking** para desviar la comunicación hacia un servidor controlado por el atacante.

3. **Suplantar el servidor PostgreSQL**:  
   - Configurar un servidor falso que imite al legítimo.
   - Si el cliente no valida el certificado SSL del servidor (p.ej., usa `sslmode=disable` o `allow`), aceptará conexiones no autenticadas.

4. **Descifrar tráfico SSL (si no hay verificación robusta)**:  
   - Si se usa SSL/TLS con certificados autofirmados y el cliente no valida el certificado (`sslmode=require` en lugar de `verify-full`), el atacante podría inyectar su propio certificado falso.

---

### **¿Por qué `verify-full` es anti-MITM?**
El parámetro `sslmode=verify-full` en PostgreSQL fuerza dos cosas:  
1. **Cifrado obligatorio**: La conexión usa SSL/TLS.  
2. **Validación del certificado**:  
   - El certificado del servidor debe estar firmado por una **CA (Autoridad Certificadora)** de confianza para el cliente.  
   - Se verifica que el nombre del servidor (en el certificado) coincida con el host al que se conecta el cliente (p.ej., `mi-servidor.com`).  

Esto previene MITM porque:  
- Un atacante no podrá presentar un certificado válido y firmado por una CA confiable.  
- El cliente rechazará conexiones si el certificado es inválido o el nombre no coincide.

---

### **¿Cómo podría un atacante evadir `verify-full`?**
Para burlar `verify-full`, el atacante necesitaría:  

1. **Comprometer una CA de confianza**:  
   - Si el atacante controla una CA que el cliente ya confía (p.ej., mediante malware o acceso a sistemas internos), podría emitir un certificado fraudulento para el servidor objetivo.

2. **Robar la clave privada del servidor**:  
   - Si obtiene la clave privada del certificado SSL del servidor legítimo, podría suplantarlo (requiere acceso no autorizado al servidor).

3. **Engañar al usuario para que ignore advertencias**:  
   - Si el cliente ve una advertencia de certificado inválido pero el usuario la ignora manualmente (p.ej., en herramientas gráficas como pgAdmin), se podría establecer la conexión (depende del factor humano).

4. **Ataques a implementaciones de SSL/TLS**:  
   - Explotar vulnerabilidades en OpenSSL o PostgreSQL (p.ej., Heartbleed, errores de validación). Esto requiere parches no aplicados en el cliente/servidor.




### **Mejores prácticas para prevenir MITM**
1. Usar `sslmode=verify-full` en el cliente.  
2. Emplear certificados SSL/TLS emitidos por CAs reconocidas o internamente gestionadas (no autofirmados).  
3. Rotar y proteger las claves privadas del servidor.  
4. Monitorizar el tráfico de red para detectar anomalías (p.ej., uso de herramientas como IDS/IPS).  
5. Educar a los usuarios para que no ignoren advertencias de certificados.  


### **Ejemplo de ataque MITM en modo `require`**
1. Te conectas a `servidor.com` con `sslmode=require`.  
2. Un atacante redirige tu conexión a su propio servidor.  
3. El atacante presenta un certificado SSL auto-firmado.  
4. Como no hay validación, el cliente acepta el certificado.  
5. **Resultado**: La conexión está cifrada, pero **entre tú y el atacante**, no con el servidor real.

 
  ******************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************
  
  
### **Ejemplo de flujo**
1. **Servidor** envía su certificado SSL al cliente.
2. **Cliente** verifica:
   - Que el certificado del servidor esté firmado por una CA presente en su `sslrootcert`.
   - Que el certificado no esté caducado o revocado (si se realiza validación CRL/OCSP).
3. **Si el servidor valida clientes**, entonces:
   - El cliente envía su certificado.
   - El servidor verifica el certificado del cliente usando su `ssl_ca_file`.
 
 
 ### **¿Cómo funciona la negociación TLS?**
El proceso de negociación entre cliente y servidor sigue estos pasos:
1. **Cliente**: Envía un `ClientHello` indicando la versión más alta de TLS que soporta (p.ej., TLS 1.3).
2. **Servidor PostgreSQL**:
   - Verifica si la versión propuesta por el cliente es igual o superior a `ssl_min_protocol_version`.
   - Si la versión del cliente es compatible y cumple con el mínimo configurado, elige la **versión más alta comúnmente soportada**.
   - Si el cliente propone una versión inferior al mínimo configurado, rechaza la conexión.

**Ejemplo**:
- Servidor: Soporta TLS 1.3 y tiene `ssl_min_protocol_version = TLSv1.2`.
- Cliente A: Soporta TLS 1.3 → **Se usa TLS 1.3**.
- Cliente B: Soporta solo TLS 1.2 → **Se usa TLS 1.2**.
- Cliente C: Soporta TLS 1.1 → **Conexión rechazada**.

  
  
  
  
La negociación TLS entre un cliente y un servidor PostgreSQL que utiliza certificados X.509 (como `root.crt`, `intermedio.crt`, `server.crt` y `server.key`) sigue un flujo técnico basado en el protocolo **TLS Handshake**, adaptado a la configuración específica de PostgreSQL. Aquí está el proceso detallado:


### **2. Proceso de Negociación TLS (Handshake)**

#### **Paso 1: Inicio de la conexión (ClientHello)**  
El cliente inicia la conexión al servidor PostgreSQL en el puerto 5432 (o el configurado) y envía un mensaje `ClientHello` con:
- Versiones de TLS soportadas (ej: TLS 1.2 o 1.3).
- Cipher suites soportadas (ej: `ECDHE-RSA-AES256-GCM-SHA384`).
- Un número aleatorio (_Client Random_).

#### **Paso 2: Respuesta del servidor (ServerHello)**  
El servidor responde con un mensaje `ServerHello` que incluye:
- La versión de TLS seleccionada (ej: TLS 1.2).
- El cipher suite acordado.
- Un número aleatorio (_Server Random_).

#### **Paso 3: Envío del certificado del servidor (Certificate)**  
El servidor envía su certificado (`server.crt`) y **toda la cadena de certificados necesaria** para que el cliente valide la confianza:
   - `server.crt` → `intermedio.crt` → `root.crt` (si el cliente ya tiene `root.crt`).

#### **Paso 4: Validación del certificado por el cliente**  
El cliente verifica:
   - Que el certificado `server.crt` está firmado por `intermedio.crt`.
   - Que `intermedio.crt` está firmado por `root.crt` (previamente confiable en el cliente).
   - Que el nombre del servidor (CN/SAN) coincide con el host de conexión.
   - Que el certificado no está expirado ni revocado (si se usa CRL/OCSP).

#### **Paso 5: Autenticación del servidor (ServerKeyExchange)**  
El servidor demuestra posesión de `server.key` mediante:
   - **Firma digital**: Usa `server.key` para firmar un hash de los mensajes anteriores (_Client Random_ + _Server Random_).
   - En TLS 1.3, esto se combina con el proceso de intercambio de claves (ej: ECDHE).

#### **Paso 6: Intercambio de claves (Key Exchange)**  
Según el cipher suite:
- **RSA**: El cliente genera una clave pre-maestra (pre-master secret), la cifra con la clave pública del servidor (extraída de `server.crt`) y la envía.
- **ECDHE**: El servidor envía parámetros Diffie-Hellman firmados con `server.key`, y ambos lados calculan una clave compartida.

#### **Paso 7: Finalización del Handshake (Finished)**  
Ambas partes derivan las claves de sesión para cifrado simétrico (ej: AES-GCM) y envían mensajes `Finished` cifrados para confirmar que el handshake fue exitoso.

   

### **Diagrama del Flujo TLS en PostgreSQL**
```
Cliente Servidor PostgreSQL
------ -------------------
ClientHello (TLS versiones, ciphers)
                                ---> ServerHello (TLS 1.3, cipher)
                                <--- Certificate (server.crt + intermedio.crt)
                                <--- ServerKeyExchange (firma con server.key)
ClientKeyExchange (clave pre-maestra)
[Finished] ---> [Finished]
Conexión cifrada (AES-GCM) <--> Datos cifrados
```
 
