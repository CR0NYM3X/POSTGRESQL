DO $_fn_anonima_$ 
DECLARE
	v_query_hardening RECORD;
	v_query_exe TEXT; 
	v_query_exe_backup TEXT; 
BEGIN

	-- Habilita los mensajes en el cliente 
	set client_min_messages = notice	;


	
	BEGIN
		 
		 -- Se hace un backup del archivo postgresql.conf y lo guarda en la ruta /sysx/archivos/dbas/backup_psql_conf
		 v_query_exe_backup := FORMAT( E'COPY (select 1) to  PROGRAM  \'mkdir -p /sysx/archivos/dbas/backup_psql_conf && cp %s/postgresql.conf /sysx/archivos/dbas/backup_psql_conf/postgresql.conf_$(date +"%%Y%%m%%d")\' ; ' ,   current_setting('data_directory') );
		 
		 EXECUTE v_query_exe_backup ;
		 
	EXCEPTION WHEN OTHERS THEN
	
		RAISE EXCEPTION 'Error - No se pudo hacer el backup del archivo CONF [%] ',  SQLERRM;
	
	END;


	-- Se recorre una query que valida que parametros faltan por hardenizar 
	FOR v_query_hardening IN
          SELECT  
            a.name
			-- ,setting as current_setting_incorrect 
			-- ,coalesce(b.correct_setting,c.correct_setting) as correct_setting
            ,case when a.name != 'server_version' then format('sed -i %s/^[[:space:]]*#*[[:space:]]*%s[[:space:]]*=/ s/.*/%s = %s%s%s  #&/%s %s/postgresql.conf ',chr(34) , a.name  , a.name , chr(39) ,replace(replace(replace(coalesce(b.correct_setting),'/','\/'),'.','\.'),'!','\!'),chr(39),chr(34),  current_setting('data_directory')   )  end as command_modify 
			
			FROM pg_settings  as a             
               left join (select * from (VALUES 
               ('data_directory', '/sysx/data')
               ,('log_filename', 'postgresql-%y%m%d.log')
               ,('client_min_messages', 'warning')
               ,('log_min_messages', 'warning')
               ,('log_min_error_statement', 'warning')
               ,('log_connections', 'on')
               ,('log_disconnections', 'on')
               ,('log_hostname', 'off')
               ,('log_rotation_age', '1440')
               ,('log_rotation_size', '0')
               ,('log_truncate_on_rotation', 'on')
               ,('password_encryption', 'scram-sha-256')
               ,('debug_print_parse', 'off')
               ,('debug_print_rewritten', 'off')
               ,('debug_print_plan', 'off')
               ,('debug_pretty_print', 'on')
               ,('log_file_mode', '0600')
               ,('log_error_verbosity', 'default')
               ,('log_directory', 'pg_log')
               ,('log_statement', 'all')
               ,('log_line_prefix', '<%t %r %a %d %u %p %c %i>' )
               ,('ssl', 'on' )
               ,('ssl_cert_file', '/sysx/data/certificados/server.crt'  )
               ,('ssl_key_file', '/sysx/data/certificados/server.key'  )
               ,('ssl_ciphers', 'HIGH:!aNULL:!MD5:!3DES:!RC4:!DES:!IDEA:!RC2' )
               ,('ssl_prefer_server_ciphers', 'on' )
               ,('ssl_min_protocol_version', 'TLSv1.2' )
			   ,('ssl_max_protocol_version', 'TLSv1.3' )
               ) AS acl_privs(name, correct_setting)) as b on a.name = b.name

			  -- Versiones actualizadas 		
              left join (
              select * from (VALUES 
                  ('server_version', '17.5')
                 ,('server_version', '16.9')
                 ,('server_version', '15.13')
                 ,('server_version', '14.18')
                 ,('server_version', '13.21')
                 ,('server_version', '12.22')
                 ,('server_version', '11.22')
                 ,('server_version', '10.23')
              ) AS acl_privs(name, correct_setting)) as c  on a.name = c.name and split_part(setting,'.',1) = split_part(c.correct_setting,'.',1) and a.name = 'server_version'
			  
          
          where 
          (
              (a.name = 'log_filename' and not setting= 'postgresql-%y%m%d.log')
          or  (a.name = 'client_min_messages' and not setting = 'warning')
          or  (a.name = 'log_min_messages' and not setting = 'warning')
          or  (a.name = 'log_min_error_statement' and not setting = 'warning' )	
          or  (a.name = 'log_connections' and not setting = 'on' )	
          or  (a.name = 'log_disconnections' and not setting = 'on' )	
          or  (a.name = 'log_hostname' and not setting = 'off' )	
          or  (a.name = 'log_rotation_age'  and not setting = '1440')
          or  (a.name = 'log_rotation_size'  and not  setting = '0')
          or  (a.name = 'log_truncate_on_rotation' and not setting= 'on')
          --or  (a.name = 'data_directory' and not setting ilike '/sysx%')
		  
		  -- Deshabilitada para Tiendas 
          or  (a.name = 'password_encryption'  and not setting= 'scram-sha-256')
          or  (a.name = 'debug_print_parse'  and not setting = 'off')
          or  (a.name = 'debug_print_rewritten'  and not setting = 'off')
          or  (a.name = 'debug_print_plan'  and not setting = 'off')
          or  (a.name = 'debug_pretty_print'  and not setting = 'on')
          or  (a.name = 'log_file_mode'  and not setting = '0600')
          or  (a.name = 'log_error_verbosity'  and not setting = 'default')
          or  (a.name = 'log_directory'  and not setting = 'pg_log')
          or  (a.name = 'log_statement'  and not setting = 'all')	
          or  (a.name = 'log_line_prefix'   and replace(setting,' ','') != '<%t%r%a%d%u%p%c%i>' )	
		  
		  -- Este filtro de deshabilita ya que solo valida el tema de versión y no realiza cambios solo es visual
          -- or  (a.name = 'server_version' and not setting in( '10.23','11.22','12.22','13.21','14.18','15.13','16.9','17.5' ))
          
		  -- Habilitando validación de TLS en Hardening 
		  or  (a.name = 'ssl'  and not setting = 'on')			  
		  or  (a.name = 'ssl_cert_file'  and not setting = '/sysx/data/certificados/server.crt')	
		  or  (a.name = 'ssl_key_file'  and not setting = '/sysx/data/certificados/server.key')	
		  or  (a.name = 'ssl_ciphers'  and not setting = 'HIGH:!aNULL:!MD5:!3DES:!RC4:!DES:!IDEA:!RC2')	
		  or  (a.name = 'ssl_prefer_server_ciphers'  and not setting = 'on')				 
		  or  (a.name = 'ssl_min_protocol_version'  and not (setting = 'TLSv1.2' or setting = 'TLSv1.3'))
		  or  (a.name = 'ssl_max_protocol_version'  and not (setting = 'TLSv1.2' or setting = 'TLSv1.3')))
			
	LOOP
			
		-- Preparando el copy para que modifique el postgresql.conf 
		v_query_exe := FORMAT( E'COPY (select 1) to  PROGRAM  %L ; ' ,  v_query_hardening.command_modify );
		
		
		BEGIN
			
			-- Ejecutnado el sed con el copy 
			EXECUTE v_query_exe;
			
			-- Insertar los valores en la tabla destino
			--RAISE NOTICE ' Parametro modificado:  %', v_query_hardening.name ; 
		
		EXCEPTION WHEN OTHERS THEN
		
			RAISE NOTICE 'Error - parametro : % | Msg Error [%] ', v_query_hardening.name, SQLERRM;
		
		END;
		
	END LOOP;

	
	-- Se realiza reload 
	PERFORM  pg_reload_conf() ;
 
 
END $_fn_anonima_$;
