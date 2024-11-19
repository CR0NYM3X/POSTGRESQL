### Descripción
La extensión `session_exec` Te permite ejecutar una funcion al iniciar una session. Esto es útil para realizar tareas como auditorías, inicialización de variables de sesión, o cualquier otra lógica que necesites ejecutar al inicio de cada sesión.


### Ejemplo: Configuración para bloquear usuarios que usan pgadmin y DBeaver y Obteniendo un reporte de los usuarios

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
    
    
    ####### llvm #######
    -> herramientas y bibliotecas para el desarrollo de compiladores y lenguajes de programación
     
    --- Validar si esta intalado:
     rpm -qa |grep llvm

     --- Solucion: [Instalar paquete]
    llvm-libs-17.0.6-2.module+el8.10.0+21256+978ccea6.x86_64
    llvm-17.0.6-2.module+el8.10.0+21256+978ccea6.x86_64

     
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


1. **Descarga la extensión**:
    Puedes encontrarla en el repositorio de GitHub [okbob/session_exec](https://github.com/okbob/session_exec) o
    [reedstrm/session_exec](https://github.com/reedstrm/session_exec/tree/master).


2. **Instalar la extensión con PGXS**:
    `PGXS (PostgreSQL Extension Building Infrastructure):` PGXS es una infraestructura de construcción proporcionada por PostgreSQL para facilitar la compilación y la instalación de extensiones. 
    ``

    ```sh
    # Ingresa al proyecto/carpeta  session_exec
    cd session_exec 
    
    # Este comando indica al sistema de construcción make que utilice la infraestructura PGXS para compilar la extensiónUSE_PGXS=1 es una variable que activa el uso de PGXS en el archivo Makefile de la extensión
    make USE_PGXS=1    
    
    # Después de compilar la extensión, este comando instala la extensión en el sistema PostgreSQL.
    sudo make USE_PGXS=1 install

    ------ Cuando se instala genera estos archivos
    /usr/pgsql-16/lib/session_exec.so
    /usr/pgsql-16/lib/bitcode/session_exec/session_exec.bc
    /usr/pgsql-16/lib/bitcode/session_exec.index.bc
    
     ```


3. **Crear la función de inicio de sesión**:
    Crear el archivo  "/tmp/script_fun.txt" y guarda el la query en el archivo, nota la funcion debe de estar en todas la base de datos donde quieres que se valide 

    ```sql
    --- Crea el esquema nuevo para que la funcion no se mescle con la información del esquema public
    CREATE SCHEMA IF NOT EXISTS sec_dba AUTHORIZATION postgres;
    grant usage  on schema sec_dba to PUBLIC;

    --- Creando la funcion 
    CREATE OR REPLACE FUNCTION sec_dba.check_app() RETURNS void AS $$
    BEGIN
         IF 
    		/*    USUARIOS QUE QUIERES QUE VALIDE  */ 
    		  session_user in('ale','user_test','user_app')
    		
    		and
    	 
    		/*    APLICACIONES QUE QUIERES RESTRINGIR  */ 
    		(
    		(current_setting('application_name') ilike  '%pg%' and current_setting('application_name') ilike  '%admin%'  )  or  
    		(current_setting('application_name') ilike  '%DB%' and  current_setting('application_name') ilike  '%eaver%' )  or  
    		(current_setting('application_name') ilike  '%psqlC%' )
    		)
    	 
    		 THEN
    	   
    	    --- realiza el registro de los usuarios bloqueados en el archivo unauthorized_app_users.csv
    	    COPY (select md5(now()::text),coalesce(inet_server_addr()::text,'unix_socket'),current_setting('port') , current_database() , session_user , coalesce(inet_client_addr()::text,'unix_socket') , current_setting('application_name'),current_TIMESTAMP, 'Se detecto el uso de una aplicación no autorizada') TO PROGRAM 'cat >> /tmp/unauthorized_app_users.csv' WITH (FORMAT CSV);
    	   
    	   
    	   -- select pg_terminate_backend(pg_backend_pid()); -- Esta query cierra la session
    	   
    	   --- Este genera una EXCEPTION y le mostrara un mensaje en la aplicacion al cliente 
    	      RAISE EXCEPTION E' \n\n El usuario: [%] esta realizando una conexión a la base de datos [%] desde la aplicación [%] no autorizada. Esta acción está en violación de nuestras políticas de seguridad y no corresponde al propósito para el cual se creó el usuario. Si crees que este mensaje es un error, por favor contacta al equipo de seguridad de DBA inmediatamente. \n\n ',    session_user , current_database(),  current_setting('application_name') ;
    	
    	ELSE 

            --- Si quieres que aparezca un mensaje cuando se conectan exitosamente en la terminal descomenta el RAISE NOTICE
            --- RAISE NOTICE E'\n ****** Usuario % conectado con exito ****** ', session_user ;

    		--- realiza el registro de los usuarios conectados en el archivo authorized_app_users.csv
    	    COPY (select md5(now()::text),coalesce(inet_server_addr()::text,'unix_socket'), current_setting('port') , current_database() , session_user ,coalesce(inet_client_addr()::text,'unix_socket') , current_setting('application_name'),current_TIMESTAMP, 'usuario conectado') TO PROGRAM 'cat >> /tmp/authorized_app_users.csv' WITH (FORMAT CSV);
    	   
    	
        END IF;
    
    END;
    $$ LANGUAGE plpgsql
    SECURITY DEFINER ; --- Se agrega SECURITY DEFINER para que se ejecute la funcion con permisos del postgres ya que usa la funcion copy y requere de privilegios 

    --- Asignamos como owner el rol pg_execute_server_program para que no quede como owner el postgres por seguridad 
    ALTER FUNCTION  sec_dba.check_app()  OWNER TO pg_execute_server_program;

    ```

4. **Automatizar la creacion de la funcion en todas las base de datos**:
    ```SQL
    # [NOTA] Este tambien instalara la Funcion en la DB  template1 para cuando creen una nueva DB la funcion ya este instalada
    # , esto evita estar instalando la fun en cada DB cada vez que se cree una nueva 
    
    # Guarda todas las base de datos en la variable result
    result=$(psql -p5416  -tAX -c "select datname  from pg_database where not datname in('template1','template0');" )

    # Recorre la lista de base de datos 
    for base in $result
    do
        # Instala la funcion
        echo   $(psql -p 5416 -tAX -f /tmp/script_fun.txt -d $base) " - Base de datos: " $base 
    done
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
    
    
    ---- Con esto podemos limpiar los archivos donde se guardan los registros de los usuarios
    ---- Tambien sirve para que se creen los archivs en caso de que no existan 
    copy (select '') to program  'cat /dev/null > /tmp/authorized_app_users.csv';
    copy (select '') to program  'cat /dev/null > /tmp/unauthorized_app_users.csv';
    
    ----  consultar archivo como si fuera una tabla 
    select * from authorized_app_users ; 
    select * from unauthorized_app_users ; 

    
    ```    


6. **Modificar el archivo `postgresql.conf`**:
    

    ```sql
    # Añade la siguiente línea para cargar la biblioteca de la extensión al inicio de cada sesión:
    session_preload_libraries = 'session_exec'

    # **Configurar la función de inicio de sesión** 
    session_exec.login_name = 'sec_dba.check_app'
    ```



7. **Reiniciar el servidor PostgreSQL**:
    Para aplicar los cambios, con un reload 

    ```sh
    pg_ctl reload -D $PGDATA16 
    ```


### Segunda opción para visualizar la información de los usuarios  
```sql
    CREATE TEMP TABLE tmp_authorized_app_users (
    	id serial PRIMARY KEY,
        id_md5 varchar(50)  ,
    	ip_server  VARCHAR(100),
    	port_server VARCHAR(100),
    	db VARCHAR(100),
        username VARCHAR(100) NOT NULL,
    	ip_client VARCHAR(100)  ,
        app_name VARCHAR(100)  ,
        detected_at TIMESTAMP  , 
        details TEXT
    	,date_insert timestamp default now()::timestamp
    );

    copy tmp_authorized_app_users(id_md5,ip_server,port_server,db,username,ip_client,app_name,detected_at,details) from  '/tmp/authorized_app_users.csv'  WITH (FORMAT CSV);

    select * from tmp_authorized_app_users;
```






### Info Extra
```sh
    En caso de que quieras tener un monitoreo en tiempo real, puedes utilizar la extension postgres_fdw
    para mandar la información de manera inmediata a un servidor central y detectar al instante los
     usuarios que estan intentando logearse con aplicaciones restringidas  
    
    # En caso de querer pasar la extension en otra instancia puedes hacer lo siguiente
    cp /usr/pgsql-16/lib/session_exec.so /usr/pgsql-15
    cp /usr/pgsql-16/lib/bitcode/session_exec.index.bc /usr/pgsql-15
    cp -r /usr/pgsql-16/lib/bitcode/session_exec /usr/pgsql-15
```



### Comportamiento
- Si la función especificada no existe, se generará una advertencia.
- Si la función de inicio de sesión falla, se impedirá la conexión del usuario.


 



