### Descripción
La extensión `session_exec` introduce una función de inicio de sesión que se ejecuta automáticamente cuando un usuario se conecta. Esto es útil para realizar tareas como auditorías, inicialización de variables de sesión, o cualquier otra lógica que necesites ejecutar al inicio de cada sesión.

### Configuración

1. **Instalar la extensión**:
    Primero, asegúrate de tener la extensión `session_exec` instalada. Puedes encontrarla en el repositorio de GitHub [okbob/session_exec](https://github.com/okbob/session_exec).

2. **Modificar el archivo `postgresql.conf`**:
    Añade la siguiente línea para cargar la biblioteca de la extensión al inicio de cada sesión:

    ```plaintext
    session_preload_libraries = 'session_exec'
    ```

3. **Configurar la función de inicio de sesión**:
    Define el nombre de la función que deseas ejecutar al inicio de cada sesión:

    ```plaintext
    session_exec.login_name = 'nombre_de_tu_funcion'
    ```

4. **Crear la función de inicio de sesión**:
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

5. **Reiniciar el servidor PostgreSQL**:
    Para aplicar los cambios, reinicia el servidor PostgreSQL:

    ```sh
    sudo systemctl restart postgresql
    ```

### Comportamiento
- Si la función especificada no existe, se generará una advertencia.
- Si la función de inicio de sesión falla, se impedirá la conexión del usuario.
 
### Bibliografía
https://github.com/okbob/session_exec
