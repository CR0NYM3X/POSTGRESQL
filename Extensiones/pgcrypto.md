
## Referencias: 

	- Doc oficiales 
		* https://www.postgresql.org/docs/17/pgcrypto.html
		* https://www.postgresql.org/docs/current/encryption-options.html
  		* RFC 4880: OpenPGP  https://www.rfc-editor.org/rfc/rfc4880.html

	- Doc apoyo
		* https://stackoverflow.com/questions/29189154/issue-with-pgcrypto-pgp-pub-encrypt
		* https://docs.yugabyte.com/preview/secure/column-level-encryption/
		* https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html
 

### Notas Importantes

- **Seguridad**: Las funciones de `pgcrypto` están diseñadas para ser seguras y confiables. Utilizan algoritmos criptográficos estándar y son consideradas "de confianza", lo que significa que pueden ser instaladas por usuarios no superusuarios que tengan privilegios de `CREATE` en la base de datos.
- **Requisitos**: `pgcrypto` requiere OpenSSL. No se instalará si el soporte de OpenSSL no fue seleccionado al construir PostgreSQL.

### Consideraciones


### Ventajas

- **Flexibilidad**: `pgcrypto` soporta una amplia gama de algoritmos criptográficos, lo que permite a los desarrolladores elegir el más adecuado para sus necesidades específicas.
- **Seguridad Mejorada**: El uso de sal y la capacidad de ajustar la velocidad de los algoritmos proporciona una defensa robusta contra ataques de fuerza bruta y otros intentos de comprometer la seguridad.
- **Integración Sencilla**: Las funciones de `pgcrypto` se integran fácilmente con PostgreSQL, permitiendo a los desarrolladores añadir capacidades criptográficas sin necesidad de herramientas externas.




### Funciones de Hash General

Estas funciones se utilizan para calcular hashes binarios de datos, lo cual es útil para verificar la integridad de los datos y para almacenar contraseñas de manera segura.

Ventajas 
	Los algoritmos de hash son rápidos y eficientes, lo que los hace ideales para aplicaciones que requieren procesamiento rápido de datos.

Aplicaciones de los Hashes 
	- Verificación de Integridad de Datos: Asegura que los datos no han sido alterados durante la transmisión o almacenamiento.
    - Almacenamiento Seguro de Contraseñas:  Almacena contraseñas de manera segura en bases de datos. En lugar de guardar la contraseña en texto plano, se guarda su hash.
	- Firma Digital: Verifica la autenticidad y la integridad de un mensaje o documento.


1. **`digest(data, type)`**:
   - **Casos de uso**: Calcula un hash binario del dato proporcionado.
   - **Algoritmos**: `md5`, `sha1`, `sha224`, `sha256`, `sha384`, `sha512`.
   
   - **Ejemplo de uso**:
     ```sql
     SELECT digest('mi_dato', 'sha256');
     ```
   

2. **`hmac(data, key, type)`**:
   - **Casos de uso**: Calcula un HMAC (Hashed Message Authentication Code) de los datos, utilizando una clave unica.
   - **Beneficio**: resistente a ataques de fuerza bruta y ataques de colisión, ya que utiliza una combinación de un hash criptográfico y una clave secreta.
   - **Algoritmos**: `md5`, `sha1`, `sha224`, `sha256`, `sha384`, `sha512`.
   - **Ejemplo de uso**:
     ```sql
     SELECT hmac('mi_dato', 'mi_clave', 'sha512');
     ```
   - **Nota adicional**: El HMAC es útil para asegurar que los datos no han sido alterados, ya que el hash solo puede ser recalculado conociendo la clave.



### Funciones de Hash de Contraseñas

Estas funciones están diseñadas específicamente para el hashing de contraseñas, proporcionando seguridad adicional mediante el uso de sal y algoritmos adaptativos.

1. **`crypt(password, salt)`**:
   - **Casos de uso**: Calcula un hash estilo `crypt(3)` de la contraseña.
   - **Algoritmos**: `bf`, `md5`, `xdes`, `des`.
   - 
   - **Ejemplo de uso**:
     ```sql
     
	 -- Generar HASH 
	 SELECT crypt('mi_contraseña_segura', gen_salt('bf'));
	 
	 -- Validar un hash
	 select (passwd = crypt('mi_contraseña_segura', passwd)) AS pswmatch , passwd from ( select crypt('mi_contraseña_segura', gen_salt('bf')) as passwd) as a ; 
     ```
   - **Nota adicional**: Utiliza un valor aleatorio llamado "salt" para asegurar que contraseñas iguales tengan hashes diferentes.
   

2. **`gen_salt(type)`**:
   - **Casos de uso**: Genera parámetros de algoritmo para `crypt`.
   - **Algoritmos**: `bf`, `md5`, `xdes`, `des`.
   - **Ejemplo de uso**:
     ```sql
     SELECT gen_salt('bf', 6 );
     ```
   - **Nota adicional**:  el segundo parámetro especificar el número de iteraciones para los algoritmos que lo tienen. Cuanto mayor sea el número, más tiempo se tarda en generar el hash de la contraseña y, por lo tanto, más tiempo se tarda en descifrarla.
 


### Funciones de Encriptación PGP (Simétrico)

Estas funciones permiten encriptar y desencriptar datos utilizando el estándar PGP (Pretty Good Privacy).


1. **`pgp_sym_encrypt(data, key)`**:
   - **Casos de uso**: Encripta datos utilizando una clave simétrica.
   - **Algoritmos**: bf, aes128, aes192, aes256, 3des, cast5
   - **Ejemplo de uso**:
     ```sql
     SELECT pgp_sym_encrypt('mi_dato', 'mi_clave', 'cipher-algo=aes256');
     ```
   - **Nota adicional**: Puede comprimir los datos antes de encriptarlos si PostgreSQL fue compilado con soporte para zlib.



2. **`pgp_sym_decrypt(data, key)`**:
   - **Casos de uso**: Desencripta datos encriptados con una clave simétrica.
   - **Algoritmos**: bf, aes128, aes192, aes256, 3des, cast5
   - **Ejemplo de uso**:
     ```sql
     SELECT pgp_sym_decrypt(pgp_sym_encrypt('mi_dato', 'mi_clave', 'cipher-algo=aes256'), 'mi_clave', 'cipher-algo=aes256');
     ```

### Funciones de Encriptación PGP (Asimétrico)

Aunque pgp_pub_encrypt utiliza algoritmos simétricos como AES para la encriptación de los datos, lo que la hace asimétrica es el uso de un par de claves (pública y privada) para la gestión de la encriptación y desencriptación.
 
1.- Generamos las claves publica y privada como se enseño en este documento.

```sql

-- Crear tabla ejemplo
-- drop table clientes;
CREATE TABLE clientes(
	id_cliente int,
	telefono bytea
);
--  select * from clientes;



-- Crear tabla para leer los datos 
-- drop table pgp_keys;
CREATE TABLE pgp_keys (
    id uuid DEFAULT gen_random_uuid(),
    name varchar(20),
    value text, 
    date timestamp without time zone DEFAULT clock_timestamp()::timestamp without time zone
);
-- select * from pgp_keys;

-- importar clave publica
insert into pgp_keys(name,value) 
select 'public_key', '-----BEGIN PGP PUBLIC KEY BLOCK-----
..
..
-----END PGP PUBLIC KEY BLOCK-----';

-- importar clave privada
insert into pgp_keys(name,value) 
select 'private_key', '-----BEGIN PGP PRIVATE KEY BLOCK-----
..
..
-----END PGP PRIVATE KEY BLOCK-----';


-- Cifrar los datos 
insert into clientes(id_cliente, telefono) select 123456, PGP_PUB_ENCRYPT('6672-65-98-46', (select dearmor(value) from pgp_keys where name = 'public_key') , 'cipher-algo=aes256' );

-- Decifrar los datos 
select id_cliente,PGP_PUB_DECRYPT( 
	telefono::bytea,  
	(select dearmor(value) from pgp_keys where name = 'private_key'),
	'123qweqwe' , 
	'cipher-algo=aes256'
) as telefono from clientes	;
```

### Funciones de Encriptación Cruda

Estas funciones permiten encriptar y desencriptar datos utilizando algoritmos específicos.

1. **`encrypt(data, key, type)`**:
   - **Casos de uso**: Encripta datos utilizando un algoritmo específico.
   - **Algoritmos**: `aes`, `bf`, `des`.
   - **Ejemplo de uso**:
     ```sql
     SELECT encrypt('mi_dato', 'mi_clave', 'aes');
     ```

2. **`decrypt(data, key, type)`**:
   - **Casos de uso**: Desencripta datos encriptados.
   - **Algoritmos**: Igual que `encrypt()`.
   - **Ejemplo de uso**:
     ```sql
     SELECT convert_from(decrypt(encrypt('mi_dato_sensible', 'mi_clave', 'aes'), 'mi_clave', 'aes'), 'UTF8') AS texto_legible;
     ```


 






---
---
---



# ¿Qué es GPG y para qué sirve?

**GnuPG (GPG) GNU Privacy Guard** es una herramienta de cifrado y firma digital de datos desarrollada como una alternativa Comercial y costo a PGP (Pretty Good Privacy) . GPG cumple con el estándar OpenPGP y permite a los usuarios cifrar y firmar digitalmente mensajes, archivos y correos electrónicos.

### Ventajas de GPG

1. **Seguridad en la Comunicación**:
   - **Descripción**: Proporciona un alto nivel de seguridad para la comunicación digital mediante el cifrado de mensajes y archivos.
   - **Impacto**: Protege la privacidad y la integridad de los datos durante la transmisión.

2. **Firma Digital**:
   - **Descripción**: Permite a los usuarios firmar digitalmente mensajes y archivos para garantizar su autenticidad.
   - **Impacto**: Ayuda a prevenir la suplantación de identidad y asegura que el mensaje no ha sido alterado.

3. **Código Abierto**:
   - **Descripción**: GPG es software libre y de código abierto, lo que permite su auditoría por la comunidad.
   - **Impacto**: Contribuye a la confianza en su seguridad y transparencia.

4. **Multiplataforma**:
   - **Descripción**: Compatible con la mayoría de los sistemas operativos, incluyendo Linux, Windows y macOS.
   - **Impacto**: Facilita su uso en diferentes entornos y aplicaciones.


### Desventajas de GPG

1. **Complejidad**:
   - **Descripción**: La configuración y gestión de claves puede ser complicada para usuarios menos experimentados.
   - **Impacto**: Requiere conocimientos técnicos para su correcta implementación y uso.

2. **Velocidad**:
   - **Descripción**: La encriptación y desencriptación pueden ser más lentas en comparación con otros métodos de cifrado.
   - **Impacto**: Puede no ser adecuada para aplicaciones que requieren procesamiento rápido de datos.

3. **Gestión de Claves**:
   - **Descripción**: La administración de claves incluye la creación, distribución, revocación y recertificación de claves.
   - **Impacto**: Requiere un sistema robusto para manejar la seguridad y la integridad de las claves.


### Cuándo Usar GPG

1. **Protección de Datos Sensibles**:
   - **Descripción**: Cuando necesitas proteger información confidencial durante la transmisión, como correos electrónicos y archivos.
   - **Impacto**: Asegura que solo el destinatario autorizado pueda acceder a los datos.

2. **Firma Digital**:
   - **Descripción**: Para garantizar la autenticidad y la integridad de los mensajes y archivos.
   - **Impacto**: Previene la suplantación de identidad y asegura que los datos no han sido alterados.

3. **Verificación de Software**:
   - **Descripción**: Para verificar la autenticidad de paquetes de software descargados.
   - **Impacto**: Asegura que el software no ha sido modificado por terceros durante la descarga.


 
### Consideraciones

1. **Seguridad de Claves**:
   - **Descripción**: Mantén las claves privadas seguras y utiliza certificados de revocación para claves comprometidas.
   - **Impacto**: Asegura la integridad y la seguridad de tus sistemas criptográficos.

2. **Rotación de Claves**:
   - **Descripción**: Implementa políticas de rotación de claves para mantener la seguridad.
   - **Impacto**: Asegura que las claves no se utilicen indefinidamente y se renueven periódicamente.

3. **Auditoría y Monitoreo**:
   - **Descripción**: Realiza auditorías y monitoreo del uso de claves para detectar cualquier actividad sospechosa.
   - **Impacto**: Mantiene la seguridad y la integridad de los datos.

### Casos de Uso Comunes

1. **Envío de Correos Electrónicos Cifrados**:
   - **Descripción**: Utiliza GPG para cifrar correos electrónicos y asegurar que solo el destinatario pueda leerlos.
   - **Impacto**: Protege la privacidad de la comunicación electrónica.

2. **Firma de Documentos**:
   - **Descripción**: Firma digitalmente documentos para garantizar su autenticidad e integridad.
   - **Impacto**: Asegura que los documentos no han sido alterados durante la transmisión.

3. **Cifrado de Archivos**:
   - **Descripción**: Cifra archivos antes de almacenarlos en la nube o enviarlos por medios electrónicos.
   - **Impacto**: Protege la información sensible contra accesos no autorizados.


# Ejemplos de uso

### Generación de Claves con GPG
	
	- Generar claves 
		gpg --full-generate-key

			* Seleccionar RSA 3072 o DSA 2048
			* Especificar tamaño de clave: 3072
			* Establecer fecha de expiración: 2 años o 0 para que no tenga expiracion
			* Proporcionar información del usuario: John Doe, john.doe@example.com, Test Key
			* Confirmar y crear la clave
			
	- Listar claves públicas:
		gpg --list-keys

	
	- Listar claves privadas:
		gpg --list-secret-keys

	- Exportar la clave publica
	gpg  --armor --export KEYID > public.key
	
	- Exportar la clave privada 
	gpg  --armor --export-secret-keys KEYID > secret.key
	


### Comando para Extender la Fecha de Expiración:

	- Validar ID claves publicas 
		gpg --list-keys

	- Validar ID claves privadas  	
		gpg --list-secret-keys
		
	- Editar las llaves
		gpg --edit-key <ID_de_la_clave>
		gpg> expire


### Pasos para Eliminar una Clave Específica

	- Validar ID claves publicas 
		gpg --list-keys

	- Validar ID claves privadas  	
		gpg --list-secret-keys

	- Eliminar la Clave Privada
		gpg --delete-secret-keys <ID_de_la_clave>

	- Eliminar la Clave Pública
		gpg --delete-keys <ID_de_la_clave>


### Revocar claves por temas de expiracion o compremetidos.
	- Revocación de Claves:
		gpg --gen-revoke <ID_de_la_clave>
	
	
### Importar y Verificar Claves en el Nuevo Servidor
	
	- Importar clave secreta 
		gpg --import  secret.key
	
	- Importar clave publica
		gpg --import  public.key
	
	- Validar ID claves publicas 
		gpg --list-keys

	- Validar ID claves privadas  	
		gpg --list-secret-keys
		
	 
### Cifrar y Descifrar un Archivo
	- Cifrar un Archivo
		gpg --encrypt --recipient destinatario@example.com archivo.txt

	- Descifrar un Archivo
		gpg --decrypt archivo.txt.gpg


### Cifrado Simétrico  usando una contraseña en lugar de claves públicas/privadas
	
	- Cifrar un Archivo
	gpg --symmetric archivo.txt
	
	- Descifrar un Archivo
	gpg --decrypt archivo.txt.gpg


### Firmar Digitalmente un Archivo
	- Firmar Digitalmente un Archivo
		gpg --sign archivo.txt
	
	- Verificar una Firma Digital
		gpg --verify archivo.txt.gpg
	


 
