

https://www.postgresql.org/docs/current/encryption-options.html


######## Ejemplo de encriptación con encriptado simétrico ########

El encriptado simétrico se basa en una clave secreta compartida entre el Cliente  y el servidor para cifrar y descifrar los datos sensibles.


Ventajas: 
Fácil implementación.

Desventajas :
Se expone la clave en la aplicación, transmisión y  terceras personas.



CREATE EXTENSION pgcrypto ;


********* crea una tabla donde almacenaremos información encriptada: *********
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre_cliente TEXT,
    NSS BYTEA
);



********* encriptar y almacenar datos en la tabla  ********* 
INSERT INTO clientes (nombre_cliente, NSS)
VALUES (
    'Jose Rodriguez',
    pgp_sym_encrypt('123456', 'PASSWORD_PARA_ENCRIPTAR')
),
(
    'Roberto Gomez',
    pgp_sym_encrypt('8989898', 'PASSWORD_PARA_ENCRIPTAR')
),
(
    'Alberto Sanchez',
    pgp_sym_encrypt('456789', 'PASSWORD_PARA_ENCRIPTAR')
);




********* desencriptar datos   ********* 
SELECT id, nombre_cliente, pgp_sym_decrypt(NSS, 'PASSWORD_PARA_ENCRIPTAR') AS datos_desencriptados
FROM clientes;









######## Ejemplo de encriptación con encriptado Asimétrico ########


El encriptado asimétrico ofrece una mayor seguridad debido a la utilización de un par de claves generadas con la herramienta de  OpenPGP y se requiere de 2 claves para poder desencriptar

Clave pública: sirve para cifrar los datos, esta clave se comparte al cliente.
Clave privada: está en posesión exclusiva del servidor y sirve para descifrar.
Clave secreta/ contraseña: nos ayuda a descifrar los datos. 

Ventajas:
1.- Mayor seguridad.
2.- No expone la contraseña ante terceras personas. 

Desventaja:
Mayor complejidad de implementación


@ paso #1 
CREATE EXTENSION pgcrypto ;


@ paso #2 
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre_cliente TEXT,
    NSS BYTEA
);


@ paso #3
CREATE TABLE rsa_keys (
    id SERIAL PRIMARY KEY,
    public_key TEXT
);

@ paso #4
mkdir /sysx/data/keys-psql 
cd /sysx/data/keys-psql 

@ paso #5
Generar keys: Colocamos el comando gpg --gen-key en la terminal de linux para  generar las claves públicas y privadas, nos solicitará colocar una identificación de usuario para identificar su clave, nosotros colocamos psql-encript-tabla-clientes , también solicitará un correo, nosotros colocamos test-encript-data@coppel.com, despues nos solicitará ingresar una clave secreta/contraseña nosotros colocamos test123123 para este ejemplo.


@ paso #6
 Validar listado de claves: Colocamos el comando gpg --list-secret-keys  para ver la lista de las claves generadas, esto nos ayudará a confirmar que nuestras claves si se hayan generado
 
@ paso #7 
 Con el comando  gpg -a --export psql-encript-tabla-clientes > public.key  exportamos la clave pública.
 
 
@ paso #8
Con el comando gpg -a --export-secret-keys psql-encript-tabla-clientes > secret.key exportamos la clave privada, este comando nos solicitará colocar la clave secreta/contraseña para obtener la clave privada en el archivo secret.key.

@ paso #9
Validar claves: Validamos que ya sí se hayan generado los archivos con las claves public.key y secret.key.
ls -lhtra 

@ paso #10
Importar clave pública: Pasamos la clave pública a la tabla gpg_keys y consultamos para validar que si se haya insertado.
 
 
@ paso #11
copy rsa_keys(public_key) FROM '/sysx/data/keys-psql/public.key ';

@ paso #12
 Encriptar:  Encriptamos con la función  pgp_pub_encrypt colocando como primer parámetro el texto que quiero encriptar y como segundo parámetro la clave pública, la cual la extrae de la tabla gpg_keys.
 
 select pgp_pub_encrypt('sensitive data to encrypt',(SELECT dearmor(string_agg(public_key, E'\n'))  FROM rsa_keys));
 
 
CREATE OR REPLACE FUNCTION public.fun_encrypt(texto text)
RETURNS bytea
LANGUAGE plpgsql
AS $function$
DECLARE
    key text;
    cifrado bytea;
BEGIN
    -- Declaración de variables locales
    -- key: Almacena la clave pública concatenada
    -- cifrado: Almacena el texto cifrado
    
    -- Concatenar todas las claves en una única cadena
    -- Se utiliza la función string_agg() para concatenar las claves en una sola cadena separada por saltos de línea
    SELECT string_agg(llave, E'\n') INTO key FROM public;
    
    -- Verificar si se encontró alguna clave
    -- Si no se encontraron claves públicas, se genera una excepción y se detiene la ejecución
    IF key IS NULL THEN
        RAISE EXCEPTION 'No se encontraron claves públicas en la tabla public';
    END IF;
    
    -- Cifrar el texto utilizando la clave combinada
    -- Se utiliza la función pgp_pub_encrypt() para cifrar el texto utilizando la clave pública combinada
    cifrado := pgp_pub_encrypt(texto, dearmor(key));
    
    -- Devolver el texto cifrado
    RETURN cifrado;
    
EXCEPTION
    -- Manejo de excepciones
    -- Si se produce un error durante la ejecución de la función, se captura y se muestra un mensaje descriptivo
    WHEN others THEN
        RAISE EXCEPTION 'Error al cifrar el texto: %', SQLERRM;
END;
$function$;



 
@ paso #13
Desencriptar:   Para desencriptar la columna y visualizar la información, usamos la función pgp_pub_decrypt colocando como primer parámetro la columna que queremos desencriptar, segundo parámetro la clave privada que se encuentra en una ruta segura y tercer parámetro la clave secreta ya que sin la clave secreta no nos permitirá leer los datos sensibles.


select fun_decrypt((select pgp_pub_encrypt('sensitive data to encrypt',(SELECT dearmor(string_agg(public_key, E'\n'))  FROM rsa_keys))));
 
CREATE OR REPLACE FUNCTION  public.fun_decrypt(texto bytea, paswd text)
RETURNS text
LANGUAGE plpgsql
AS $function$
DECLARE
    --key text;
    descifrado text;
BEGIN
    -- Declaración de variables locales
    -- key: Almacena la clave pública concatenada
    -- descifrado: Almacena el texto descifrado
    
    -- Concatenar todas las claves en una única cadena
    -- Se utiliza la función string_agg() para concatenar las claves en una sola cadena separada por saltos de línea
    --SELECT string_agg(private_key, E'\n') INTO key FROM rsa_keys;
    
    -- Verificar si se encontró alguna clave
    -- Si no se encontraron claves públicas, se genera una excepción y se detiene la ejecución
    /*IF key IS NULL THEN
        RAISE EXCEPTION 'No se encontraron claves públicas en la tabla public';
    END IF;*/
    
    -- descifrado el texto utilizando la clave combinada
    -- Se utiliza la función pgp_pub_decrypt() para descifrado el texto utilizando la clave pública combinada
    descifrado := pgp_pub_decrypt(texto, dearmor(pg_read_file('/tmp/priv_test.txt')) ,paswd);
    
    -- Devolver el texto cifrado
    RETURN descifrado;
    
EXCEPTION
    -- Manejo de excepciones
    -- Si se produce un error durante la ejecución de la función, se captura y se muestra un mensaje descriptivo
    WHEN others THEN
        RAISE EXCEPTION 'Error al descifrado el texto: %', SQLERRM;
END;
$function$;



select fun_decrypt(fun_encrypt('hola mundo'),'/tmp/priv_test.txt','As123456');







######## PASOS PARA IMPLEMENTAR EN PRODUCCION ########



Fase #1 Recopilación de la información y analisis de la base de datos 
Validar la disponibilidad de la extensión
Identificar tablas y columnas sensibles por parte del centro dueño
Validación y clasificación de nivel de criticidad de las columnas sensibles no encriptadas
Identificar objetos que hacen uso de la tablas y sus columnas
Analizar y clasificación el nivel de complejidad cada objeto

Fase #2 Evaluación del Impacto de la Encriptación en la base de datos
Creación de documento donde se evalúa el Impacto de la Encriptación

Fase #3  Evaluación del Impacto de la Encriptación en la base de datos
Respaldo de las tablas y objetos
Agregar columnas extras
Pasar los datos sensibles a las nueva columna
Consultas de validación
Eliminación de las columnas sin encriptar
Renombrar las columnas
Modificación de objetos con apoyo de desarrollo 
Testing de los objetos 


