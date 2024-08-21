### Descripción
La extensión `session_exec` introduce una función de inicio de sesión que se ejecuta automáticamente cuando un usuario se conecta. Esto es útil para realizar tareas como auditorías, inicialización de variables de sesión, o cualquier otra lógica que necesites ejecutar al inicio de cada sesión.

### Configuración

1. **Requisitos y posibles errores que puedes presentar durante la instalación de la extension** :
    En mi caso yo use el S.O "Red Hat 8.5.0-22), 64-bit" y tuve que instalar los siguientes paquetes :<br>
     ```sh
    
    ####### postgresql-devel #######
    -> Incluye las bibliotecas y encabezados necesarios para desarrollar tus aplicaciones en postgresql
    
    --- Validar si esta intalado: 
    rpm -qa | grep -Ei postgresql | grep -Ei devel
    
    --- Comando ejecutado:
    make
    
    --- Mensaje Error:
    Makefile:16: /usr/pgsql-16/lib/pgxs/src/makefiles/pgxs.mk: No such file or directory
    make: *** No rule to make target '/usr/pgsql-14/lib/pgxs/src/makefiles/pgxs.mk'.  Stop.
    
    --- Solucion: [Instalar paquete]
    postgresql16-devel-16.4-1PGDG.rhel8.x86_64
    
    -- Referencia:
    https://stackoverflow.com/questions/71200455/makefile10-usr-pgsql-14-lib-pgxs-src-makefiles-pgxs-mk-no-such-file-or-direc
    
    
    ####### gcc #######
    ->  Es un conjunto de compiladores para varios lenguajes de programación como C, C++, Fortran, Ada, Go, y
     más. Es ampliamente utilizado para compilar software en sistemas Unix y Linux2.  
    
    --- Validar si esta intalado: 
     rpm -qa | grep -Ei gcc
     gcc --version
    
    --- Comando ejecutado:
    make
    
    --- Mensaje Error:
    make: gcc: Command not found
    
    --- Solucion: [Instalar paquete]
    gcc-8.5.0-22.el8_10.x86_64
    gcc-c++-8.5.0-22.el8_10.x86_64
    gcc-toolset-13
    
    -- Referencia:
    https://ioflood.com/blog/install-gcc-command-linux/
    
    
    ####### clang #######
    -> Es un front-end de compilador para los lenguajes de la familia C (C, C++, Objective-C, etc.) que utiliza LLVM como back-end. Ofrece diagnósticos expresivos, compatibilidad con GCC y MSVC 
    --- Validar si esta intalado: 
     rpm -qa | grep -Ei clang
     gcc --version
    
    --- Comando ejecutado:
    make
    
    --- Mensaje Error:
    make: /usr/bin/clang: command not foun
    
    --- Solucion: [Instalar paquete]
    clang-libs-17.0.6-1.module+el8.10.0+20808+e12784c0.x86_64
    clang-resource-filesystem-17.0.6-1.module+el8.10.0+20808 
    clang-17.0.6-1.module+el8.10.0+20808+e12784c0.x86_64
    
     
    ####### redhat-rpm-config #######
    Este paquete proporciona macros personalizadas de Red Hat utilizadas durante la construcción de paquetes RPM  
    
    --- Validar si esta intalado: 
     rpm -qa | grep -Ei redhat-rpm-config
     gcc --version
    
    --- Comando ejecutado:
    make
    
    --- Mensaje Error:
    gcc: error: /usr/lib/rpm/redhat/redhat-hardened-cc1: no souch file or directory
    
    --- Solucion: [Instalar paquete]
    redhat-rpm-config-131-1.el8
    
    -- Referencia:
    https://stackoverflow.com/questions/34624428/g-error-usr-lib-rpm-redhat-redhat-hardened-cc1-no-such-file-or-directory
    
     ```


2. **Descarga la extensión**:
    Puedes encontrarla en el repositorio de GitHub [okbob/session_exec](https://github.com/okbob/session_exec) o
    [reedstrm/session_exec](https://github.com/reedstrm/session_exec/tree/master).


3. **Instalar la extensión con PGXS**:
    `PGXS (PostgreSQL Extension Building Infrastructure):` PGXS es una infraestructura de construcción proporcionada por PostgreSQL para facilitar la compilación y la instalación de extensiones. 
    ``

    ```sh
    # Ingresa al proyecto/carpeta  session_exec
    cd session_exec 
    
    # Este comando indica al sistema de construcción make que utilice la infraestructura PGXS para compilar la extensiónUSE_PGXS=1 es una variable que activa el uso de PGXS en el archivo Makefile de la extensión
    make USE_PGXS=1    
    
    # Después de compilar la extensión, este comando instala la extensión en el sistema PostgreSQL.
    sudo make USE_PGXS=1 install
     ```


4. **Crear la función de inicio de sesión**:
    Asegúrate de que la función que deseas ejecutar esté definida en cada base de datos que quieres validar.

    ```sql

    CREATE OR REPLACE FUNCTION check_app() RETURNS void AS $$
    BEGIN
         IF 
    		/*    USUARIOS QUE QUIERES QUE VALIDE  */ 
    		  current_user in('ale','user_test','user_app')
    		
    		and
    	 
    		/*    APLICACIONES QUE QUIERES RESTRINGIR  */ 
    		(
    		(current_setting('application_name') ilike  '%pg%' and current_setting('application_name') ilike  '%admin%'  )  or  
    		(current_setting('application_name') ilike  '%DB%' and  current_setting('application_name') ilike  '%eaver%' )  or  
    		(current_setting('application_name') ilike  '%psqlC%' )
    		)
    	 
    		 THEN
    	   
    	    --- realiza el registro de los usuarios bloqueados en el archivo unauthorized_app_users.csv
    	    COPY (select md5(now()::text),coalesce(inet_server_addr()::text,'unix_socket'),current_setting('port') , current_database() , current_user , coalesce(inet_client_addr()::text,'unix_socket') , current_setting('application_name'),current_TIMESTAMP, 'Se detecto el uso de una aplicación no autorizada') TO PROGRAM 'cat >> /tmp/unauthorized_app_users.csv' WITH (FORMAT CSV);
    	   
    	   
    	   -- select pg_terminate_backend(pg_backend_pid()); -- Esta query cierra la session
    	   
    	   --- Este genera una EXCEPTION y le mostrara un mensaje en la aplicacion al cliente 
    	     RAISE EXCEPTION '  El usuario: [%] esta realizando una conexión a la base de datos [%] desde la aplicación [%] no autorizada,  en caso de  que este mensaje sea un error, favor de ponerse en contacto con el área de DBA seguridad.  ',    current_user , current_database(),  current_setting('application_name') ;
    	
    	ELSE 

            RAISE NOTICE 'Usuario conectado con exito';
    		--- realiza el registro de los usuarios conectados en el archivo authorized_app_users.csv
    	    COPY (select md5(now()::text),coalesce(inet_server_addr()::text,'unix_socket'), current_setting('port') , current_database() , current_user ,coalesce(inet_client_addr()::text,'unix_socket') , current_setting('application_name'),current_TIMESTAMP, 'usuario conectado') TO PROGRAM 'cat >> /tmp/authorized_app_users.csv' WITH (FORMAT CSV);
    	   
    	
        END IF;
    
    END;
    $$ LANGUAGE plpgsql   ;

    ```


5. **Monitorear los usuarios**:
    ```SQL
    \c postgres 
    CREATE EXTENSION file_fdw;
    
    CREATE SERVER csv_server
    FOREIGN DATA WRAPPER file_fdw;
    
    -- drop FOREIGN TABLE unauthorized_app_users;
    
    CREATE FOREIGN TABLE unauthorized_app_users (
        id_md5 varchar(50)  ,
    	ip_server  VARCHAR(100),
    	port_server VARCHAR(100),
    	db VARCHAR(100),
        username VARCHAR(100) NOT NULL,
    	ip_client VARCHAR(100)  ,
        app_name VARCHAR(100)  ,
        detected_at TIMESTAMP  ,-- DEFAULT CURRENT_TIMESTAMP,
        details TEXT
    )
    SERVER csv_server
    OPTIONS (filename '/tmp/unauthorized_app_users.csv', format 'csv', header 'false');
    
    
    -- drop FOREIGN TABLE authorized_app_users;
    
    CREATE FOREIGN TABLE authorized_app_users (
        id_md5 varchar(50)  ,
    	ip_server  VARCHAR(100),
    	port_server VARCHAR(100),
    	db VARCHAR(100),
        username VARCHAR(100) NOT NULL,
    	ip_client VARCHAR(100)  ,
        app_name VARCHAR(100)  ,
        detected_at TIMESTAMP  ,-- DEFAULT CURRENT_TIMESTAMP,
        details TEXT
    )
    SERVER csv_server
    OPTIONS (filename '/tmp/authorized_app_users.csv', format 'csv', header 'false');
    
    
    ---- hacer un truncate al archivo 
    copy (select '') to program  'cat /dev/null > /tmp/authorized_app_users.csv';
    copy (select '') to program  'cat /dev/null > /tmp/unauthorized_app_users.csv';
    
    ----  consultar archivo como si fuera una tabla 
    select * from authorized_app_users ; 
    select * from unauthorized_app_users ; 

    
    ```    


6. **Modificar el archivo `postgresql.conf`**:
    

    ```plaintext
    # Añade la siguiente línea para cargar la biblioteca de la extensión al inicio de cada sesión:
    session_preload_libraries = 'session_exec'

    # **Configurar la función de inicio de sesión** 
    session_exec.login_name = 'nombre_de_tu_funcion'
    ```



7. **Reiniciar el servidor PostgreSQL**:
    Para aplicar los cambios, con un reload 

    ```sh
    pg_ctl reload -D $PGDATA16 
    ```

### Comportamiento
- Si la función especificada no existe, se generará una advertencia.
- Si la función de inicio de sesión falla, se impedirá la conexión del usuario.


 
