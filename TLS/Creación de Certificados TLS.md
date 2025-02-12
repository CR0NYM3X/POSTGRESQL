 
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
