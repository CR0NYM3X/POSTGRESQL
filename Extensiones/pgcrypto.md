

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
	


 

--- 
--- 
--- 

 ### Encriptación en PostgreSQL

#### Crear la Extensión `pgcrypto`

```sql
CREATE EXTENSION pgcrypto;
```

#### Crear una Tabla para Almacenar Información Encriptada

```sql
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre_cliente TEXT,
    NSS BYTEA
);
```

#### Encriptar y Almacenar Datos en la Tabla

```sql
INSERT INTO clientes (nombre_cliente, NSS)
VALUES 
    ('Jose Rodriguez', pgp_sym_encrypt('123456', 'PASSWORD_PARA_ENCRIPTAR')),
    ('Roberto Gomez', pgp_sym_encrypt('8989898', 'PASSWORD_PARA_ENCRIPTAR')),
    ('Alberto Sanchez', pgp_sym_encrypt('456789', 'PASSWORD_PARA_ENCRIPTAR'));
```

#### Desencriptar Datos

```sql
SELECT id, nombre_cliente, pgp_sym_decrypt(NSS, 'PASSWORD_PARA_ENCRIPTAR') AS datos_desencriptados
FROM clientes;
```

### Ejemplo de Encriptación Asimétrica

El encriptado asimétrico ofrece una mayor seguridad debido a la utilización de un par de claves generadas con la herramienta OpenPGP. Se requiere de dos claves para poder desencriptar:

- **Clave pública**: Sirve para cifrar los datos y se comparte con el cliente.
- **Clave privada**: Está en posesión exclusiva del servidor y sirve para descifrar.
- **Clave secreta/contraseña**: Ayuda a descifrar los datos.

**Ventajas**:
1. Mayor seguridad.
2. No expone la contraseña ante terceras personas.

**Desventaja**:
- Mayor complejidad de implementación.

#### Pasos para Implementar Encriptación Asimétrica

1. **Crear la Extensión `pgcrypto`**

    ```sql
    CREATE EXTENSION pgcrypto;
    ```

2. **Crear la Tabla `clientes`**

    ```sql
    CREATE TABLE clientes (
        id SERIAL PRIMARY KEY,
        nombre_cliente TEXT,
        NSS BYTEA
    );
    ```

3. **Crear la Tabla `rsa_keys`**

    ```sql
    CREATE TABLE rsa_keys (
        id SERIAL PRIMARY KEY,
        public_key TEXT
    );
    ```

4. **Generar Claves**

    ```sh
    mkdir /sysx/data/keys-psql
    cd /sysx/data/keys-psql
    gpg --gen-key
    ```

    - Identificación de usuario: `psql-encript-tabla-clientes`
    - Correo: `test-encript-data@coppel.com`
    - Clave secreta/contraseña: `test123123`

5. **Validar Listado de Claves**

    ```sh
    gpg --list-secret-keys
    ```

6. **Exportar Clave Pública**

    ```sh
    gpg -a --export psql-encript-tabla-clientes > public.key
    ```

7. **Exportar Clave Privada**

    ```sh
    gpg -a --export-secret-keys psql-encript-tabla-clientes > secret.key
    ```

8. **Validar Claves**

    ```sh
    ls -lhtra
    ```

9. **Importar Clave Pública**

    ```sql
    COPY rsa_keys(public_key) FROM '/sysx/data/keys-psql/public.key';
    ```

10. **Encriptar Datos**

    ```sql
    SELECT pgp_pub_encrypt('sensitive data to encrypt', (SELECT dearmor(string_agg(public_key, E'\n')) FROM rsa_keys));
    ```

11. **Función para Encriptar**

    ```sql
    CREATE OR REPLACE FUNCTION public.fun_encrypt(texto text)
    RETURNS bytea
    LANGUAGE plpgsql
    AS $function$
    DECLARE
        key text;
        cifrado bytea;
    BEGIN
        SELECT string_agg(public_key, E'\n') INTO key FROM rsa_keys;
        IF key IS NULL THEN
            RAISE EXCEPTION 'No se encontraron claves públicas en la tabla rsa_keys';
        END IF;
        cifrado := pgp_pub_encrypt(texto, dearmor(key));
        RETURN cifrado;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error al cifrar el texto: %', SQLERRM;
    END;
    $function$;
    ```

12. **Desencriptar Datos**

    ```sql
    SELECT fun_decrypt((SELECT pgp_pub_encrypt('sensitive data to encrypt', (SELECT dearmor(string_agg(public_key, E'\n')) FROM rsa_keys))));
    ```

13. **Función para Desencriptar**

    ```sql
    CREATE OR REPLACE FUNCTION public.fun_decrypt(texto bytea, paswd text)
    RETURNS text
    LANGUAGE plpgsql
    AS $function$
    DECLARE
        descifrado text;
    BEGIN
        descifrado := pgp_pub_decrypt(texto, dearmor(pg_read_file('/tmp/priv_test.txt')), paswd);
        RETURN descifrado;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'Error al descifrar el texto: %', SQLERRM;
    END;
    $function$;
    ```

    ```sql
    SELECT fun_decrypt(fun_encrypt('hola mundo'), '/tmp/priv_test.txt', 'As123456');
    ```

### Pasos para Implementar en Producción

**Fase #1: Recopilación de la Información y Análisis de la Base de Datos**
- Validar la disponibilidad de la extensión.
- Identificar tablas y columnas sensibles.
- Validar y clasificar el nivel de criticidad de las columnas sensibles no encriptadas.
- Identificar objetos que hacen uso de las tablas y sus columnas.
- Analizar y clasificar el nivel de complejidad de cada objeto.

**Fase #2: Evaluación del Impacto de la Encriptación en la Base de Datos**
- Crear un documento donde se evalúe el impacto de la encriptación.

**Fase #3: Implementación de la Encriptación en la Base de Datos**
- Respaldo de las tablas y objetos.
- Agregar columnas extras.
- Pasar los datos sensibles a las nuevas columnas.
- Realizar consultas de validación.
- Eliminar las columnas sin encriptar.
- Renombrar las columnas.
- Modificar objetos con apoyo de desarrollo.
- Realizar pruebas de los objetos.

