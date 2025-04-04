
## Referencias: 
```
	- Doc oficiales 
		* https://www.postgresql.org/docs/17/pgcrypto.html
		* https://www.postgresql.org/docs/current/encryption-options.html
  		* RFC 4880: OpenPGP  https://www.rfc-editor.org/rfc/rfc4880.html

	- Doc apoyo
		* https://stackoverflow.com/questions/29189154/issue-with-pgcrypto-pgp-pub-encrypt
		* https://docs.yugabyte.com/preview/secure/column-level-encryption/
		* https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html
  
	- **NIST SP 800-57**: Recomienda el uso de **HSMs** para proteger claves criptográficas (Sección 5.6.1) .  
	- **PCI DSS v4.0**: Requiere que las claves privadas estén en **HSMs o dispositivos certificados** (Req. 3.5.1)  .  
	- **OWASP Key Management**: Advierte sobre riesgos de claves en código o bases de datos .  
```
    
 

### Notas Importantes

- **Seguridad**: Las funciones de `pgcrypto` están diseñadas para ser seguras y confiables. Utilizan algoritmos criptográficos estándar y son consideradas "de confianza", lo que significa que pueden ser instaladas por usuarios no superusuarios que tengan privilegios de `CREATE` en la base de datos.
- **Requisitos**: `pgcrypto` requiere OpenSSL. No se instalará si el soporte de OpenSSL no fue seleccionado al construir PostgreSQL.

### Consideraciones
  - Las claves privadas RSA deben almacenarse en un [HSM](https://github.com/CR0NYM3X/POSTGRESQL/edit/main/Extensiones/pgcrypto.md#1-qu%C3%A9-es-un-hardware-security-module-hsm). Las claves públicas pueden estar en archivos restringidos, pero nunca en la BD o código.
  - Opciones de Almacenamiento de Claves.
### Ventajas

- **Flexibilidad**: `pgcrypto` soporta una amplia gama de algoritmos criptográficos, lo que permite a los desarrolladores elegir el más adecuado para sus necesidades específicas.
- **Seguridad Mejorada**: El uso de sal y la capacidad de ajustar la velocidad de los algoritmos proporciona una defensa robusta contra ataques de fuerza bruta y otros intentos de comprometer la seguridad.
- **Integración Sencilla**: Las funciones de `pgcrypto` se integran fácilmente con PostgreSQL, permitiendo a los desarrolladores añadir capacidades criptográficas sin necesidad de herramientas externas.
 
### **Desventajas de Encriptar en PostgreSQL**
  -  **`Revisión de Índices`** Las columnas cifradas pueden afectar los índices existentes, requiriendo una revisión y posible reconfiguración para mantener el rendimiento de las consultas. Esto puede ser complejo y consumir tiempo.
  -  **`Restricciones de Foreign Keys`** No se pueden establecer claves foráneas en columnas cifradas, lo que limita la integridad referencial y las relaciones entre tablas. Esto puede complicar la estructura de la base de datos.
  -  **`Modificación de querys`** Las consultas que utilizan columnas cifradas en sus cláusulas `WHERE` deben ser modificadas para manejar la encriptación, lo que puede complicar el desarrollo y mantenimiento de la aplicación.
  -  **`Modificación de Objetos`** Los objetos de la base de datos que retornan columnas cifradas en sus consultas deben ser ajustados para manejar la desencriptación, es un proceso extenso .
  -  **`Aumento del Tamaño en Disco`** Los datos cifrados ocupan más espacio en disco que los datos sin cifrar, lo que puede aumentar los costos de almacenamiento y requerir más capacidad de disco.
  -  **`Rendimiento y Escalabilidad`** La encriptación puede afectar el rendimiento y la escalabilidad de la base de datos, especialmente en sistemas con alto volumen de transacciones. Esto puede llevar a tiempos de respuesta más lentos y mayor carga en el servidor.
  -  **`Complejidad de Backup y Restore`** Realizar copias de seguridad y restauraciones de datos cifrados puede ser más complejo y requerir procedimientos adicionales para asegurar que los datos se mantengan seguros durante estos procesos.

### **Ventajas del Encriptado Asimétrica
  -  **Eliminación del intercambio seguro de claves**: No es necesario intercambiar una clave secreta compartida, lo que reduce el riesgo de que la clave sea interceptada durante la transmisión.
  -  **Seguridad mejorada**: Utiliza dos claves diferentes (una pública y una privada), lo que proporciona una capa adicional de seguridad. Incluso si alguien obtiene la clave pública, no puede descifrar la información sin la clave privada.
  -  **Autenticación y firmas digitales**: Permite la verificación de la autenticidad de los participantes en una comunicación mediante firmas digitales, garantizando que los mensajes provienen de una fuente confiable y no han sido alterados.
  -  **Confidencialidad**: Asegura que solo el destinatario con la clave privada puede descifrar los mensajes cifrados con la clave pública, protegiendo así la información sensible.
  -  **Escalabilidad**: Es eficaz para sistemas con un gran número de usuarios, ya que cada entidad puede tener su par de claves, facilitando la gestión de la seguridad en entornos grandes.
 

### **Desventajas de Encriptación Asimétrica**
  -  **`Gestión de Claves`** Si las claves privadas son comprometidas o expiran, es necesario reencriptar todas las columnas que usaron esa clave, lo que es costoso en tiempo y recursos. Además, la gestión de múltiples claves puede ser complicada.  Las claves deben ser almacenadas de manera segura y protegidas contra accesos no autorizados. y no se recomienda tenerlas dentro del mismo servidor , La pérdida o compromiso de la clave privada puede comprometer la seguridad de los datos. se pueden usar HashiCorp Vault o GnuPG gratuito , Microsoft Azure Key Vault: Ideal para la gestión de claves en la nube.
  -  **`Lentitud del Cifrado Asimétrico`** El cifrado asimétrico (como RSA) es más lento que el cifrado simétrico (como AES), lo que puede afectar el rendimiento de las operaciones de encriptación y desencriptación, especialmente en grandes volúmenes de datos.
  -  **`Complejidad de Implementación`** Implementar encriptación asimétrica puede ser más complejo que la encriptación simétrica, requiriendo más configuración y gestión de claves.
  - **`Pérdida de la clave privada`**: Si pierdes la clave privada, no podrás descifrar los datos encriptados con la clave pública correspondiente. Esto puede resultar en la pérdida permanente de la información.
  - **`Corrupción de la clave privada`**: Si el archivo que contiene la clave privada se corrompe, también perderás acceso a los datos encriptados. Es crucial mantener copias de seguridad de las claves privadas en lugares seguros.

### **Ventajas del Encriptado Simétrico**
 - **Velocidad**: Es generalmente más rápido que el encriptado asimétrico porque utiliza operaciones matemáticas menos complejas.
 - **Eficiencia**: Requiere menos recursos computacionales, lo que lo hace ideal para sistemas con limitaciones de rendimiento.
 - **Facilidad de implementación**: Los algoritmos de encriptado simétrico son más sencillos de implementar y gestionar.
 - **Cifrado de grandes cantidades de datos**: Es eficaz para cifrar grandes volúmenes de datos sin comprometer significativamente el rendimiento del sistema.
 - **Seguridad**: Puede ofrecer un nivel de seguridad comparable al encriptado asimétrico cuando se utilizan claves suficientemente largas.
 - 

### **Desventajas del Encriptado Simétrico**
  -  **`Gestión de Claves`** La gestión de claves puede ser complicada, especialmente en entornos distribuidos. Mantener la seguridad de las claves y asegurarse de que solo las partes autorizadas tengan acceso puede ser un desafío.
  -  **`Seguridad`** La seguridad del cifrado simétrico depende completamente de la protección de la clave. Si la clave se revela, cualquier persona puede descifrar los datos, lo que representa un riesgo significativo.


# Funciones de PGCRYPTO

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
  El hash es irreversibles lo que no es posible descifrar y obtener el dato original.

### **1. Blowfish (bf)**
- **Max Password Length**: 72 caracteres.
- **Adaptive?**: Sí, el algoritmo Blowfish es adaptable, lo que significa que puedes ajustar la complejidad del hashing para hacerlo más lento y resistente a ataques de fuerza bruta.
- **Salt Bits**: 128 bits. El salt es un valor aleatorio que se añade a la contraseña antes de encriptarla para asegurar que incluso las mismas contraseñas generen hashes diferentes.
- **Output Length**: 60 caracteres. Este es el tamaño del hash resultante.
- **Description**: Blowfish-based, variant 2a. Blowfish es un algoritmo de cifrado robusto y seguro.


Estas funciones están diseñadas específicamente para el hashing de contraseñas, proporcionando seguridad adicional mediante el uso de sal y algoritmos adaptativos.

1. **`crypt(password, salt)`**:
   - **Casos de uso**: Calcula un hash estilo `crypt(3)` de la contraseña.
   - **Algoritmos**: `bf`, `md5`, `xdes`, `des`.
   - 
   - **Ejemplo de uso**:
     ```sql
     
	 -- Generar HASH 
	 SELECT crypt('mi_contraseña_segura', gen_salt('bf', 8 ));
	 
	 -- Validar un hash
	 select (passwd = crypt('mi_contraseña_segura', passwd)) AS pswmatch , passwd from ( select crypt('mi_contraseña_segura', gen_salt('bf', 8 )) as passwd) as a ; 
     ```
   - **Nota adicional**: Utiliza un valor aleatorio llamado "salt" para asegurar que contraseñas iguales tengan hashes diferentes.
   

2. **`gen_salt(type)`**:
   - **Casos de uso**: Genera parámetros de algoritmo para `crypt`.
   - **Algoritmos**: `bf`, `md5`, `xdes`, `des`.
   - **Ejemplo de uso**:
     ```sql
     SELECT gen_salt('bf', 8 );
     ```
   - **Nota adicional**:  ofrece mayor seguridad ya que el segundo parámetro especificar el número de iteraciones para los algoritmos que lo tienen. Cuanto mayor sea el número, más tiempo se tarda en generar el hash de la contraseña y, por lo tanto, más tiempo se tarda en descifrarla.
 


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
	


# Extra info  




## **Opciones de Almacenamiento de Claves**


 
#### **Opción 1: Mejor Opción HSM o Servicio de Gestión de Claves (✅✅✅ Ideal)**
**Ejemplo con AWS KMS + PostgreSQL**:  
1. **Generar clave maestra (CMK)** en AWS KMS.  
2. **Integrar con PostgreSQL** usando extensiones como `pg_kmip` o middleware de la aplicación.  

```sql
-- Ejemplo teórico (AWS KMS)
SELECT PGP_PUB_ENCRYPT(
   '6672-65-98-46',
   aws_kms_get_public_key('alias/mi-clave'),  -- Función hipotética
   'cipher-algo=aes256'
);
```
**Ventajas**:  
- Las claves **nunca salen del HSM** (ni en memoria).  
- **Rotación automática** sin impacto en la BD.  
- **Auditoría centralizada** (ej: AWS CloudTrail).

### **1. ¿Qué es un Hardware Security Module (HSM)?`**  
Un **HSM`** es un dispositivo físico o servicio en la nube diseñado para **manejar claves criptográficas de forma segura**. Proporciona:  
- **Almacenamiento protegido**: Las claves nunca salen del HSM en texto plano.  
- **Operaciones criptográficas**: Encriptación/desencriptación se realizan dentro del HSM, evitando exposiciones en memoria.  
- **Certificaciones de cumplimiento**: Cumple con estándares como FIPS 140-2, PCI DSS, etc.  

**Uso con PostgreSQL**:  
- Puedes integrar un HSM (ej: AWS CloudHSM, Azure Key Vault) para gestionar las claves maestras usadas por `pgcrypto`.  
- **Ventaja**: Reduce el riesgo de robo de claves privadas, crítico cuando usas `PGP_PUB_DECRYPT`. 



#### **Opción 2: Claves dentro de funciones de PostgreSQL (❌ NO recomendado)**
```sql
-- Función de ejemplo (¡Insegura!)
CREATE OR REPLACE FUNCTION fun_encrypt(texto TEXT) RETURNS BYTEA AS $$
DECLARE
   clave_publica TEXT := '-----BEGIN PGP PUBLIC KEY BLOCK-----...';
BEGIN
   RETURN PGP_PUB_ENCRYPT(texto, dearmor(clave_publica), 'cipher-algo=aes256');
END;
$$ LANGUAGE plpgsql;
```
**Problemas**:  
- La clave pública/privada queda expuesta en texto plano en la definición de la función.  
- Cualquier usuario con acceso a `pg_proc` o permisos de lectura en la BD puede extraerla.  
- **Imposible rotar claves** sin modificar la función (riesgo en tablas con billones de registros).  

---

#### **Opción 3: Claves en el código de la aplicación (⚠️ Riesgoso)**
```python
# Ejemplo en Python (clave en variable)
clave_publica = """-----BEGIN PGP PUBLIC KEY BLOCK-----..."""
query = f"INSERT INTO tabla (secreto) VALUES (PGP_PUB_ENCRYPT('{dato}', dearmor('{clave_publica}')));"
```
**Problemas**:  
- Las claves quedan en repositorios de código, logs, o memoria durante la ejecución.  
- **Rotación de claves requiere redeploys**, lo que es inviable a gran escala.  

---

#### **Opción 4: Claves en archivos del servidor (✅ Recomendado con ajustes)**
```sql
-- Encriptación usando pg_read_file
SELECT PGP_PUB_ENCRYPT(
   '6672-65-98-46',
   dearmor(pg_read_file('/ruta/segura/clave_publica.asc')),
   'cipher-algo=aes256'
);
```
**Configuración necesaria**:  
1. **Permisos de archivo**: Solo el usuario de PostgreSQL debe tener acceso al directorio.  
   ```bash
   chmod 700 /ruta/segura
   chown postgres:postgres /ruta/segura/clave_publica.asc
   ```
2. **PostgreSQL**: Habilitar `pg_read_file` solo para rutas específicas (configura `data_directory` en `postgresql.conf`).  

**Ventajas**:  
- Las claves no están en la BD ni en el código.  
- Rotación de claves es más fácil (reemplazar archivos).  

**Riesgos**:  
- Si el servidor es comprometido, las claves pueden ser robadas.  


## Números primos
un número primo es un número natural mayor que 1 que tiene únicamente dos divisores positivos y solo es divisible entre 1 y sí mismo. Los primos son la base de algoritmos como **RSA** y **ECC** (cifrado asimétrico). 


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
 

 
### NIST (National Institute of Standards and Technology)
1. **Publicación Especial 800-57**: "Recommendation for Key Management" - Esta guía proporciona recomendaciones sobre la gestión de claves criptográficas, incluyendo la generación, distribución, almacenamiento y destrucción de claves. Puedes encontrarla en la sección de publicaciones del NIST
2. **Publicación Especial 800-175B**: "Guide to Cryptographic Standards and Key Management" - Esta guía ofrece una visión general de los estándares criptográficos aceptados por NIST, incluyendo AES y otros algoritmos de cifrado. Disponible en la sección de publicaciones del NIST 
 
 
 
### PCI DSS (Payment Card Industry Data Security Standard)
1. **Requisito 3**: "Protect Stored Cardholder Data" - Este requisito detalla las prácticas recomendadas para el cifrado de datos almacenados, incluyendo el uso de algoritmos como AES y RSA. Puedes encontrarlo en el documento oficial de PCI DSS.
2. **Requisito 4**: "Encrypt Transmission of Cardholder Data Across Open, Public Networks" - Este requisito especifica las recomendaciones para el cifrado de datos en tránsito, asegurando que los datos sensibles estén protegidos durante la transmisión. Disponible en el documento oficial de PCI DSS



--- 
### Proceso de Cifrado PGP_PUB_ENCRYPT

1. **Generación de la clave de sesión**:
   - Se genera una clave de sesión aleatoria (clave simétrica) que se utilizará para cifrar los datos.

2. **Cifrado de la clave de sesión**:
   - La clave de sesión se cifra utilizando la clave pública del destinatario. Esto asegura que solo el destinatario con la clave privada correspondiente pueda descifrar la clave de sesión.

3. **Cifrado de los datos**:
   - Los datos reales se cifran utilizando la clave de sesión simétrica.

4. **Creación del paquete de datos cifrados**:
   - El paquete contiene la clave de sesión cifrada y los datos cifrados. Este paquete se almacena en la base de datos.
 
### Proceso de Descifrado

1. **Descifrado de la clave de sesión**:
   - La clave privada del destinatario se utiliza para descifrar la clave de sesión que fue cifrada con la clave pública.

2. **Descifrado de los datos**:
   - Una vez que la clave de sesión ha sido descifrada, se utiliza para descifrar los datos reales que fueron cifrados con esta clave simétrica.
 
 

## Referencias adicionales: 
```
https://csrc.nist.gov/CSRC/media/Presentations/standards-research-and-applications-in-cryptograph/images-media/20191007-uchile--slides-nist-pec-pqc--rev-oct-14.pdf
https://listings.pcisecuritystandards.org/documents/PCI-DSS-v4_0-LA.pdf
https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-175Br1.pdf

https://www.reddit.com/r/PostgreSQL/comments/1fhz832/customer_asks_if_the_postgresql_database_can_be/?rdt=39185
Alternativas pgsodium https://github.com/michelp/pgsodium/releases
pg_tde (aún no está diseñada para producción.)   https://percona.github.io/pg_tde/main/ 
https://www.cybertec-postgresql.com/en/products/postgresql-transparent-data-encryption/
```
