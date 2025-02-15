En este documento, encontrarás todo lo que necesitas saber sobre TLS (Transport Layer Security). Desde los conceptos básicos hasta los detalles técnicos más avanzados, te guiaremos para que entiendas y domines todos los aspectos relacionados con TLS. Además, aprenderás cómo implementar TLS en PostgreSQL, asegurando que tus bases de datos estén protegidas y cumplan con los más altos estándares de seguridad.

 
 
# 📘 #1: Introducción a TLS
```markdown
	- **🔍 ¿Qué es TLS (Transport Layer Security)?**
	- Características y Propósitos Principales de TLS

	- **🔒 ¿Qué es SSL (Secure Sockets Layer)?**
	- Ejemplo de TLS en la vida real
	  - ❌ Sin TLS (sin cifrado):
	  - ✅ Con TLS (con cifrado):

	- **🌐 Aplicaciones Comunes de TLS**
	- **🛡️ Beneficios de Usar TLS y Por Qué Deberíamos Utilizarlo**
	- **⚙️ Resumen Rápido del Funcionamiento de TLS**
	- **📊 Diagrama en PlantUML**
	- **⚠️ Desventajas de Implementar TLS**
 ```

# 📘 #2: Introducción a Certificados
```markdown
	- **🔍 ¿Qué son los certificados?**
	- **🔧 Componentes de un certificado**
	- **🎯 ¿Para qué sirven?**
	- **🔒 Tipos de Certificados de Seguridad**
	- **🌐 Tipos de Certificados para TLS**
	- **📜 Certificados X.509**
	- **🧾 Estructura y Características de un Certificado TLS (X.509)**
	- **🔍 Ejemplo de Estructura con OpenSSL**
 	- **Mejores proveedores de certificados SSL**
```

# 📘 #3: Introducción a Criptografía
```markdown
	- **🔐 ¿Qué es un Protocolo Criptográfico?**
	- **📜 ¿Qué es un protocolo?**
	- **🔍 Características Clave de un Protocolo**
	- **🔄 Diferencia entre un algoritmo de cifrado y un algoritmo criptográfico**
	- **🔑 Criptografía Asimétrica y Simétrica**
	- **🌐 Protocolos que usan criptografía**
	- **🔒 Tipos de cifrados más utilizados en criptografía**
 ```

# 📘 #4 Introducción a la Gestión de Certificados
```markdown
	- 📜 **¿Qué es la gestión de certificados?**
	- 🎯 **¿Para qué sirve la gestión de certificados?**
	- 🌟 **Ventajas de la gestión de certificados**
	- 🕒 **¿Cuándo usar la gestión de certificados?**
	- 🚫 **¿Cuándo no usar la gestión de certificados?**
	- 🔑 **¿Qué es PKI y para qué sirve?**
	- 🌟 **Ventajas**
	- 🚫 **Desventajas**
	- 🕒 **¿Cuándo considerar implementar una PKI?**
	- 🚫 **¿Cuándo no es ideal?**
	- 📋 **Componentes de PKI**
	- 🔒 **PKI Privada vs. PKI Pública**
	- 💼 **Sistemas de Gestión de PKI (De paga)**
	- 🛠️ **Herramientas de Gestión de Certificados**
	- ⚖️ **Herramientas de Gestión vs. Sistemas PKI**
	- 📂 **Formatos de certificados SSL y extensiones de archivos de certificados**
	- **¿Qué son los archivos PEM?**
			Ventajas
			Ventajas
			Ejemplo de Contenido:
			Ejemplo de Configuración en PostgreSQL
	- **Archivos PEM por Separados (CRT y KEY)**
			Ventajas
			Desventajas
			Ejemplo de Configuración en PostgreSQL
	- 🏢 **Jerarquía típica**
	- 🔒 **Métodos de revocación o validación de certificados**
	- 📜 **Método de revocación CRL**
	  - ✅ **Ventajas de CRL**
	  - ❌ **Desventajas de CRL**
	- 🌐 **Método de revocación OCSP**
	  - ❓ **¿Para qué sirve OCSP?**
	  - ✅ **Ventajas de OCSP**
	  - ❌ **Desventajas de OCSP**
 ```
 
# 📘 #5  Creación de Certificados TLS
 
```markdown
	📜 **Estructura de PKI**
	
	📋 **Requisitos**
		- version openssl
		- Generar el archivo openssl.conf
	🚀 **Implementación**
		1. 🛠️ **Paso 1**: Crear el Certificado y la Clave Privada de la CA Raíz
		2. 🛠️ **Paso 2**: Crear el Certificado y la Clave Privada de la CA Intermedia
		3. 🛠️ **Paso 3**: Crear el Certificado y la Clave Privada del Servidor
		4. 🛠️ **Paso 4**: Crear el Certificado y la Clave Privada del Cliente
		5. 🛠️ **Paso 5**: Generar una lista de revocación de certificados (CRL)
		6. 🛠️ **Paso 6**: Verificar la autenticidad de los certificados
	
	🔧 **Post-Implementación**
		- 🔍 Ver los detalles de los certificados
		- 🖥️ Simular cliente y servidor con Certificados
		- ✅ Validar si el TLS está activado en un servidor
		- 🔑 Identificar el Certificado Raíz (Root CA)
		- 🔑 Identificar el Certificado Intermedio (si existe)
		- 🔑 Identificar el Certificado del server.crt o client.crt
		- 🔑 Verificar de quién es la clave privada (.key)
		- 📅 Verificar la fecha de expiración de un certificado
		- 📅 Verificar la fecha de expiración de un certificado Servidor remoto
	
	❓ **Preguntas frecuentes**
```
 

# 📘 #6  Implementacion de TLS en postgresql 
# 📘 #7  Medidas de seguridad y recomendaciones
# 📘 #8  Preguntas comunes
# 📘 #9  Aprendiendo usar TCPDump (Extra)

 
# Referencias extras.
```
  - **Documentation PostgreSQL**  https://www.postgresql.org/docs/
  - **Transport Layer** Security (TLS) Parameters https://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml
  - **Qué es TLS** https://www.cloudflare.com/es-es/learning/ssl/transport-layer-security-tls/
  - **Qué es x.509 Certificado y cómo funciona** https://www.ssldragon.com/es/blog/que-es-certificado-x-509/
  - **GDPR**  https://www.powerdata.es/gdpr-proteccion-datos
  - **¿Qué es la PKI?** https://www.digicert.com/es/what-is-pki

## Manuales
https://postgresconf.org/system/events/document/000/001/285/PostgreSQL_and_SSL.pdf

### El mejor:
https://gist.github.com/achesco/b893fb55b90651cf5f4cc803b78e19fd

### Recursos adicionales

19.3. Connections and Authentication  https://www.postgresql.org/docs/current/runtime-config-connection.html
32.19. SSL Support  https://www.postgresql.org/docs/current/libpq-ssl.html
20.1. The pg_hba.conf File  https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
18.9. Secure TCP/IP Connections with SSL https://www.postgresql.org/docs/current/ssl-tcp.html

https://www.highgo.ca/2024/01/06/how-to-setup-tls-connection-for-postgresql/
https://access.redhat.com/documentation/fr-fr/red_hat_enterprise_linux/9/html/configuring_and_using_database_servers/proc_configuring-tls-encryption-on-a-postgresql-server_using-postgresql
https://www.cherryservers.com/blog/how-to-configure-ssl-on-postgresql
https://docs.cloudera.com/cdp-private-cloud-base/7.1.9/installation/topics/cdpdc-enable-tls-12-postgresql.html
 

## Referencias
https://docs.aws.amazon.com/es_es/cloudhsm/latest/userguide/ssl-offload-windows-create-csr-and-certificate.html
https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA10g000000Cm1eCAC&lang=es
https://docs.vmware.com/es/VMware-Horizon-7/7.13/horizon-scenarios-ssl-certificates/GUID-3A8CFE07-0A1A-4AB1-B2B6-41DA8E592EFB.html
https://www.nominalia.com/asistencia/como-instalar-un-certificado-ssl-en-windows-server-2016/
https://www.cisco.com/c/es_mx/support/docs/unified-communications/unified-communications-manager-callmanager/215534-create-windows-ca-certificate-templates.pdf
https://documentation.meraki.com/General_Administration/Other_Topics/Creating_an_Offline_Certificate_Request_in_Windows_Server
https://docs.citrix.com/es-es/xenmobile/server/authentication/client-certificate.html
```
