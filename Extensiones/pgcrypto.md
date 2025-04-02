
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

