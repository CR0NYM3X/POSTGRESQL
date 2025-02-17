PostgreSQL tiene soporte nativo para usar conexiones SSL para cifrar las comunicaciones entre cliente y servidor
para mayor seguridad. Esto requiere que OpenSSL esté instalado tanto en los sistemas cliente como servidor y
que el soporte en PostgreSQL esté habilitado en el momento de la compilación.


 

# Fase #1 Pre-Implementación 

### Requisitos

#### #1 En el servidor Tener Instalado igual o mayo OpenSSL 1.1.1
```BASH
    openssl version  # --> OpenSSL igual o mayo a 1.1.1 
    openssl version -d  # --> OPENSSLDIR: "/etc/pki/tls"  Establece valores predeterminados para varios campos en los certificados.
```
 
#### Versiones compatibles de SSL/TLS con OpenSSL
| **Versión de OpenSSL** | **SSLv2** | **SSLv3** | **TLS 1.0** | **TLS 1.1** | **TLS 1.2** | **TLS 1.3** |
|------------------------|-----------|-----------|-------------|-------------|-------------|-------------|
| **OpenSSL 1.0.x**      | disable   | disable   | true        | true        | true        | false       |
| **OpenSSL 1.1.x**      | false     | false     | true        | true        | true        | false       |
| **OpenSSL 1.1.1**      | false     | false     | true        | true        | true        | true        |
| **OpenSSL 3.0.x**      | false     | false     | true        | true        | true        | true        |


 
#### #2 En el Servidor tener instalado [PostgreSQL con soporte](https://www.postgresql.org/support/versioning/) y compatible con tls 1.2. y 1.3
```SQL
postgres@postgres# select version();
+---------------------------------------------------------------------------------------------------------+
|                                                 version                                                 |
+---------------------------------------------------------------------------------------------------------+
| PostgreSQL 16.6 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit |
+---------------------------------------------------------------------------------------------------------+
(1 row)

Time: 0.557 ms
```


#### Versiones compatibles de SSL/TLS con PostgreSQL 

| **Versión de PostgreSQL** | **SSLv2** | **SSLv3** | **TLS 1.0** | **TLS 1.1** | **TLS 1.2** | **TLS 1.3** | **ssl_min_protocol_version** | **ssl_max_protocol_version** |
|---------------------------|-----------|-----------|-------------|-------------|-------------|-------------|-----------------------------|-----------------------------|
| **9.4**                   | false     | false     | true        | true        | true        | false       | N/A                         | N/A                         |
| **12**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **13**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **14**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **15**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **16**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |
| **17**                    | false     | false     | true        | true        | true        | true        | TLSv1.0                     | TLSv1.3                     |


#### Validar si esta disponible la extension sslinfo
    select * from pg_available_extensions where name = 'sslinfo';


#### Crear el usuario `conssl` para este ejemplo
    create user conssl with password '123123' superuser;


### Información importante 
 ```markdown

  ### Opción #1 (Recomendada de Validación Mutua )  Si el archivo server.crt fue emitido por un intermediate.crt puedes usar esta tipo de configuración:
	# ssl_cert_file = server_combined.crt ( cat /tmp/pki/certs/server.crt /tmp/pki/CA/intermediate.crt > /tmp/pki/certs/server_combined.crt)
	# ssl_ca_file = root.crt  -> sslrootcert = root.crt


  ### Opción #2 Si el archivo server.crt fue emitido por un intermediate.crt puedes usar esta tipo de configuración:
        # ssl_ca_file = root.crt  -> sslrootcert = combined.crt (cat /tmp/pki/CA/intermediate.crt /tmp/pki/CA/root.crt > /tmp/pki/CA/combined.crt)  




  ###  Si el server.crt fue emitido por el root.crt 
        # ssl_ca_file = root.crt  -> sslrootcert = root.crt

	
 ```


### [32.19.1. Verificación de certificados de servidor por parte del cliente](https://www.postgresql.org/docs/current/libpq-ssl.html#LIBQ-SSL-CERTIFICATES)
De forma predeterminada, PostgreSQL no realizará ninguna verificación del certificado del servidor. Esto significa que es posible falsificar la identidad del servidor (por ejemplo, modificando un registro DNS o apropiándose de la dirección IP del servidor) sin que el cliente lo sepa. Para evitar la suplantación, el cliente debe poder verificar la identidad del servidor a través de una cadena de confianza. Una cadena de confianza se establece colocando un certificado raíz (autofirmado) de una autoridad de certificación ( CA ) en una computadora y un certificado de hoja firmado por el certificado raíz en otra computadora. También es posible utilizar un certificado " intermedio " que esté firmado por el certificado raíz y firme los certificados de hoja.





# Fase #2 Implementación 

1. **Crear la extension en la Db postgres** 
   ```sql
   CREATE EXTENSION IF NOT EXISTS sslinfo ;
   ```

2. **Primera capa de seguridad nivel configuración ( Habilitar TLS en `postgresql.conf`)** 
   ```Markdown
   ssl = on
   ssl_cert_file = '/tmp/pki/certs/server.crt'
   ssl_key_file = '/tmp/pki/private/server.key'
   ```


3. **Segunda capa de seguridad nivel configuración ( Establecer version Minima y Máximo de TLS en  `postgresql.conf`)**

   ```Markdown
    ssl_min_protocol_version = 'TLSv1.2'
    ssl_max_protocol_version = 'TLSv1.3'   
   ```

4. **Segunda capa de seguridad nivel configuración ( forzar el uso de TLS en  `pg_hba.conf` )** 
   ```Markdown

   ## Parámetros de configuración en `pg_hba.conf`
     # hostssl -> Forza al cliente a usar una conexión cifrada en caso de que no rechaza la conexión
     # cert -> Esto es para que el cliente pueda usar un certificado para autenticarse en vez de una contraseña
     
   ### Opciones para clientes que autentican con certificado    
     # clientcert=1: solo verifica que el certificado del cliente esté firmado por una CA de confianza.
     # clientcert=verify-full: Además de requerir un certificado válido, verifica que el nombre del cliente en el certificado coincida con el nombre esperado.

   
   # TYPE  DATABASE        USER            ADDRESS                 METHOD
   hostssl   all           conssl        0.0.0.0/0               scram-sha-256 
   
   # Clientes con autenticación por certificado y no por contraseña
   hostssl   all           conssl        0.0.0.0/0               cert    clientcert=verify-full
   
   ```



5. **Tercera capa de seguridad nivel configuración ( Restringir los cifrados inseguros en  `postgresql.conf`)** 
   ```sql
   ssl_prefer_server_ciphers = on
   ssl_ciphers = 'HIGH:!aNULL:!MD5:!3DES:!RC4:!DES:!IDEA:!RC2' # Este para entornos Criticos (Bancos, Tiendas, Etc)
      # ssl_ciphers = 'HIGH:MEDIUM:!aNULL:!MD5:!RC4' # Este para entornos Normales 
   ```
   
 
6. **Cuarta capa de seguridad nivel configuración ( Restringir los cifrados inseguros en  `postgresql.conf`)** 
   ```sql
   # Esto se habilita cuando del lado del cliente se usaran las opciones sslmode=verify-ca o verify-full  
    ssl_ca_file = /tmp/pki/CA/intermediate.crt
   ```

   
7. Validar si configuramos el archivo  `postgresql.conf`
   ```sql
     # En caso de arrojar algun registro , el archivo postgresql.conf quedo mal 
    select * from pg_catalog.pg_file_settings where error is not null;
   ```
 
 

8. Recargar archivo de configuración 
   ```sql
   /usr/pgsql-16/bin/pg_ctl reload -D /sysx/data
   ```

9. Validar si el log arroja algun error 
   ```sql
    # En caso de encontrar algun error hay que corregir 
   grep -A 14 -Ei "SIGHUP|reload" postgresql-250214.log
   ```


1. **Preparar el entorno del cliente para su conexion** 
   ```sql
    # Tienes que enviarle los archivos 
    scp  /tmp/pki/certs/client.crt   /tmp/pki/private/client.key  /tmp/pki/CA/root.crt  192.100.8.162:/tmp

   # esto lo puedes hacer en caso de que no quieras colocar los parametros de sslrootcert sslcert ,  sslkey 
   mkdir ~/.postgresql
   cp client.crt client.key root.crt .postgresql/
   cd ~/.postgresql	
   mv client.crt postgresql.crt
   mv client.key postgresql.key
   ```

   `[NOTA] -> En nuestro caso realizaremos las pruebas en el mismo servidor donde tenemos postgresql`

1. **Primera capa de seguridad nivel Usuario ( Conexión con sslmode=verify-ca )**
   
   ```sql
    psql "host=127.0.0.1  port=5416  user=conssl dbname=postgres sslmode=verify-ca  sslrootcert=/tmp/pki/CA/combined.crt"
   
     ### Resultado esperado ->  SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off
   ```
 

1. **Segunda capa de seguridad nivel Usuario ( Conexión con sslmode=verify-full )** 
   ```sql
   psql "host=127.0.0.1  port=5416  user=conssl dbname=postgres sslmode=verify-full  sslrootcert=/tmp/pki/CA/combined.crt"

      ### Resultado esperado ->  SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off

   ## En caso de colocar otra ip o otro dominio/subdominio diferente al que se coloco en el Common Name (CN) o Subject Alternative Names (SAN) del certificado server.crt :
   ## psql: error: connection to server at "192.168.0.100", port 5416 failed: server certificate for "127.0.0.1" does not match host name "192.168.0.100"
   
   ```

1. **Tercera capa de seguridad nivel Usuario ( Usar Certificado para autenticarse )** 
   ```sql
    # Se conectara directo  
   psql "host=127.0.0.1  port=5416  user=conssl dbname=postgres sslmode=verify-full  sslrootcert=/tmp/pki/CA/combined.crt  sslcert=/tmp/pki/certs/client.crt sslkey=/tmp/pki/private/client.key"

   # Si colocas otros usuario aparecera esto : 
   #psql: error: connection to server at "127.0.0.1", port 5416 failed: FATAL:  certificate authentication failed for user "otros"


   ```


# **Post-Implementación.** 

1. **Concideraciones y Posibles errores en entornos de productivos.** 
   ```sql
   versiones de postgresql, incompatibilidad con los cifrados fuertes 
   ```



1. **Monitoreo y validacion de conexiónes.** 
   ```sql
   select   datname ,pg_ssl.ssl, pg_ssl.version,  pg_sa.backend_type, pg_sa.usename, pg_sa.client_addr , application_name from pg_stat_ssl pg_ssl  join pg_stat_activity pg_sa  on pg_ssl.pid = pg_sa.pid;
   ```
1. **Validar que se este usando TLS** 
   ```sql
   ```

1. **Entrega de documentación y metricas de resultados..** 
   ```sql
   ```






# Conceptos 

### [Tipos de sslmode](https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION)

```sql
El modo define el nivel de seguridad y verificación de certificados durante la conexión SSL/TLS.

### **Diagrama de Seguridad**

	Seguridad Baja → Alta
	disable → allow → prefer → require → verify-ca → verify-full
 
- **`disable`**: Conexión **sin cifrado**. Ignora SSL/TLS.
  - **Cuándo usar**: En entornos locales sin datos sensibles (ej: testing).
  - **Cuándo NO usar**: En redes públicas o con datos críticos.

- **`allow`**: Intenta conexión sin SSL primero. Si falla, intenta con SSL.
  - **Cuándo usar**: En migraciones o para compatibilidad con clientes antiguos.
  - **Cuándo NO usar**: Casi nunca, ya que es un modo inseguro por defecto.

- **`prefer`**: Intenta conexión **con SSL** primero. Si falla, usa sin cifrado.
  - **Página oficial (libpq-ssl) dice:** El valor predeterminado sslmode es  prefer.  esto no tiene sentido desde el punto de vista de la seguridad y solo promete una sobrecarga de rendimiento si es posible. Solo se proporciona como valor predeterminado para compatibilidad con versiones anteriores y no se recomienda en implementaciones seguras.

  - **Cuándo usar**: En entornos mixtos donde no todos soportan SSL.
  - **Cuándo NO usar**: Cuando se requiera seguridad garantizada.

- **`require`**: **Obliga SSL**, pero **no verifica el certificado del servidor** (sin autenticación).
  - **Cuándo usar**: Para conexiones rápidas con cifrado básico.
  - **Cuándo NO usar**: Si el servidor usa certificados autofirmados no confiables.

- **`verify-ca`**: Obliga SSL y **valida que el certificado del servidor está firmado por una CA confiable**, pero no verifica el nombre del dominio o ip al que se conecta.
  - **Cuándo usar**: Cuando se confía en la CA pero el host puede variar (ej: IP dinámica).
  - **Cuándo NO usar**: Si el nombre del host debe coincidir exactamente (ej: dominio específico).

- **`verify-full`**: Obliga SSL, **valida la CA y el nombre del host** en el certificado. Máxima seguridad.
  - **Cuándo usar**: En entornos productivos (ej: servidores en la nube).
  - **Cuándo NO usar**: Nunca evitarlo en casos críticos.
```


 
### [Parámetros y sus usos:](https://www.postgresql.org/docs/current/runtime-config-connection.html#RUNTIME-CONFIG-CONNECTION-SSL)
```sql
1. ssl

	¿Para qué sirve? Habilita o deshabilita SSL en PostgreSQL.
	Uso recomendado: Si deseas encriptar las conexiones entre clientes y el servidor para mayor seguridad.

2. ssl_ca_file
	¿Para qué sirve? Especifica la ubicación del archivo de la Autoridad de Certificación (CA) que se usa para verificar los certificados de los clientes.
	Uso recomendado: solo cuando usar el sslmode verify-full  o verify-ca

3. ssl_cert_file
	¿Para qué sirve? Define la ruta del certificado SSL del servidor PostgreSQL.
	Uso recomendado: Siempre que uses SSL para conexiones seguras.


4. ssl_ciphers
	¿Para qué sirve? Permite definir qué conjuntos de cifrados (cipher suites) se pueden usar en las conexiones SSL.
	Uso recomendado: Para restringir los cifrados inseguros y mejorar la seguridad.
	Ejemplo: HIGH:!aNULL:!MD5 (solo cifrados fuertes).

5. ssl_crl_dir
	¿Para qué sirve? Especifica un directorio donde se almacenan listas de revocación de certificados (CRL).
	Uso recomendado: Si manejas muchas CRL en un entorno de certificados que expiran o pueden ser revocados.
	¿Cuándo se usa?:  se usa cuando los clientes utilizan certificados SSL para autenticarse, no contraseñas.
			Este archivo contiene una lista de certificados que han sido revocados por la autoridad
			certificadora (CA) antes de su fecha de expiración, generalmente porque se han comprometido
			 o ya no son confiables.

6. ssl_crl_file
	¿Para qué sirve? Especifica un archivo con la lista de revocación de certificados (CRL).
	Uso recomendado: Si necesitas invalidar certificados que han sido comprometidos o revocados.

7. ssl_dh_params_file
	¿Para qué sirve? Especifica un archivo con parámetros de Diffie-Hellman personalizados para mejorar la seguridad de las claves compartidas.
	Uso recomendado: Cuando necesitas un mayor control sobre el intercambio de claves en SSL.


8. ssl_ecdh_curve
	¿Para qué sirve? Define la curva elíptica usada para el intercambio de claves ECDH.	
	Uso recomendado: Cuando usas cifrados basados en curvas elípticas (como ECDHE).
	Valor por defecto: prime256v1.


9. ssl_key_file
	¿Para qué sirve? Especifica la ruta del archivo de clave privada del servidor SSL.
	Uso recomendado: Siempre que uses SSL en PostgreSQL.


10. ssl_library
	¿Para qué sirve? Indica qué biblioteca SSL está en uso (OpenSSL por defecto).
	Uso recomendado: Solo si quieres asegurarte de qué implementación de SSL está activa.

11. ssl_max_protocol_version
	¿Para qué sirve? Especifica la versión máxima de SSL/TLS permitida en las conexiones.
	Uso recomendado: Para evitar el uso de versiones no compatibles o vulnerables.
	Ejemplo: TLSv1.3.

12. ssl_min_protocol_version
	¿Para qué sirve? Define la versión mínima de SSL/TLS permitida.
	Uso recomendado: Para obligar a los clientes a usar protocolos seguros (ejemplo: evitar TLSv1.0).
	Ejemplo recomendado: TLSv1.2.

13. ssl_passphrase_command
	¿Para qué sirve? Especifica un comando que se ejecutará para obtener la contraseña de la clave privada SSL.
	Uso recomendado: Si la clave privada está protegida con contraseña.


14. ssl_passphrase_command_supports_reload
	¿Para qué sirve? Indica si PostgreSQL puede recargar la clave privada sin reiniciar el servidor.
	Uso recomendado: Para minimizar interrupciones al actualizar certificados.


15. ssl_prefer_server_ciphers
	¿Para qué sirve? Si está en on, el servidor define qué cifrado usar en lugar del cliente.
	Uso recomendado: Para asegurar que se usen cifrados seguros definidos por el servidor.
```

# Funciones de la extension sslinfo
```
1.- Información sobre la Conexión SSL:
	 select ssl_is_used(): Devuelve verdadero si la conexión actual utiliza SSL.

2.- Información sobre Certificados:
 	select ssl_client_cert_present(): Indica si el cliente actual presentó un certificado SSL válido al servidor.
 	select ssl_client_serial(): Devuelve el número de serie del certificado del cliente.
 	select ssl_client_dn_field(fieldname text): Proporciona un campo específico del nombre del cliente 

3.- Información sobre la Conexión del Servidor:
 	select select ssl_version(): Retorna el nombre del protocolo utilizado para la conexión SSL (por ejemplo, TLSv1.2).
 	select ssl_cipher(): Proporciona el nombre del cifrado utilizado (por ejemplo, DHE-RSA-AES256-SHA).
 	select ssl_issuer_dn(): Retorna el nombre completo del emisor del certificado del cliente.
 	select ssl_client_dn(): Ofrece el nombre completo del sujeto del certificado del cliente.
```
