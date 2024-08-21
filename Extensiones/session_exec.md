### Descripción
La extensión `session_exec` introduce una función de inicio de sesión que se ejecuta automáticamente cuando un usuario se conecta. Esto es útil para realizar tareas como auditorías, inicialización de variables de sesión, o cualquier otra lógica que necesites ejecutar al inicio de cada sesión.

### Configuración




1. **Descarga la extensión**:
    Primero, asegúrate de descargar la extensión `session_exec`  . Puedes encontrarla en el repositorio de GitHub [okbob/session_exec](https://github.com/okbob/session_exec) o
    [reedstrm/session_exec](https://github.com/reedstrm/session_exec/tree/master).

2. **Requisitos antes de instalar la extensin** :
    En mi caso yo use el S.O "Red Hat 8.5.0-22), 64-bit" y tuve que instalar los paquetes :
       .- postgresql16-devel
       .- gcc
       .- clang
       .- redhat-rpm-config

make USE_PGXS=1
sudo make USE_PGXS=1 install


4. **Modificar el archivo `postgresql.conf`**:
    Añade la siguiente línea para cargar la biblioteca de la extensión al inicio de cada sesión:

    ```plaintext
    session_preload_libraries = 'session_exec'
    ```

5. **Configurar la función de inicio de sesión**:
    Define el nombre de la función que deseas ejecutar al inicio de cada sesión:

    ```plaintext
    session_exec.login_name = 'nombre_de_tu_funcion'
    ```

6. **Crear la función de inicio de sesión**:
    Asegúrate de que la función que deseas ejecutar esté definida en tu base de datos. Por ejemplo:

    ```sql
 
    CREATE OR REPLACE FUNCTION verificar_aplicacion() RETURNS void AS $$
    BEGIN
        IF current_setting('application_name') != 'sistema tienda' THEN
            RAISE NOTICE 'Conexión desde aplicación no autorizada: %', current_setting('application_name');
        END IF;
    END;
    $$ LANGUAGE plpgsql;
    
    
    En este caso, en lugar de usar RAISE EXCEPTION, utilizamos RAISE NOTICE,
    que solo genera un mensaje de aviso y permite que la conexión continúe

    
    ```

7. **Reiniciar el servidor PostgreSQL**:
    Para aplicar los cambios, reinicia el servidor PostgreSQL:

    ```sh
    sudo systemctl restart postgresql
    ```

### Comportamiento
- Si la función especificada no existe, se generará una advertencia.
- Si la función de inicio de sesión falla, se impedirá la conexión del usuario.


 
