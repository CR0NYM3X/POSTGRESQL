
--- pg_dump -p 5416 -d auditoria   --no-comments --no-privileges  --no-toast-compression --encoding UTF8 --schema-only > /tmp/structure.sql
--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cdc; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA cdc;


ALTER SCHEMA cdc OWNER TO postgres;

--
-- Name: fdw_conf; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA fdw_conf;


ALTER SCHEMA fdw_conf OWNER TO postgres;

--
-- Name: mssql; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA mssql;


ALTER SCHEMA mssql OWNER TO postgres;

--
-- Name: prttb; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA prttb;


ALTER SCHEMA prttb OWNER TO postgres;

--
-- Name: psql; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA psql;


ALTER SCHEMA psql OWNER TO postgres;

--
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: tds_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tds_fdw WITH SCHEMA public;


--
-- Name: estado_civil; Type: TYPE; Schema: psql; Owner: postgres
--

CREATE TYPE psql.estado_civil AS ENUM (
    'Soltero',
    'Casado',
    'Divorciado'
);


ALTER TYPE psql.estado_civil OWNER TO postgres;

--
-- Name: mi_tipo; Type: TYPE; Schema: psql; Owner: postgres
--

CREATE TYPE psql.mi_tipo AS (
	columna1 integer,
	columna2 text
);


ALTER TYPE psql.mi_tipo OWNER TO postgres;

--
-- Name: register_change_cat_server(); Type: FUNCTION; Schema: cdc; Owner: postgres
--

CREATE FUNCTION cdc.register_change_cat_server() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    cambios_anterior JSONB := '{}';
    cambios_nuevo JSONB := '{}';
    columna TEXT;
    valor_anterior TEXT;
    valor_nuevo TEXT;
BEGIN
    -- Para operaciones de DELETE
    IF TG_OP = 'DELETE' THEN
        cambios_anterior := to_jsonb(OLD);
        INSERT INTO cdc.cat_server (operacion, valor_anterior, valor_nuevo, usuario, ip_cliente,query)
        VALUES ('DELETE', cambios_anterior, NULL, current_user, inet_client_addr(),current_query());
        RETURN OLD;
    END IF;

    -- Para operaciones de INSERT
    IF TG_OP = 'INSERT' THEN
        cambios_nuevo := to_jsonb(NEW);
        INSERT INTO cdc.cat_server (operacion, valor_anterior, valor_nuevo, usuario, ip_cliente,query)
        VALUES ('INSERT', NULL, cambios_nuevo, current_user, inet_client_addr(),current_query());
        RETURN NEW;
    END IF;

    -- Para operaciones de UPDATE
    IF TG_OP = 'UPDATE' THEN
        FOR columna IN
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'cat_server' and table_schema='public'
        LOOP
            EXECUTE 'SELECT ($1).' || columna INTO valor_anterior USING OLD;
            EXECUTE 'SELECT ($1).' || columna INTO valor_nuevo USING NEW;
            IF valor_anterior IS DISTINCT FROM valor_nuevo THEN
                cambios_anterior := jsonb_set(cambios_anterior, ARRAY[columna], to_jsonb(valor_anterior));
                cambios_nuevo := jsonb_set(cambios_nuevo, ARRAY[columna], to_jsonb(valor_nuevo));
            END IF;
        END LOOP;

-- row_to_json(NEW)

        INSERT INTO cdc.cat_server (operacion, valor_anterior, valor_nuevo, usuario, ip_cliente,query)
        VALUES ('UPDATE', cambios_anterior, cambios_nuevo, current_user, inet_client_addr(),current_query());
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$_$;


ALTER FUNCTION cdc.register_change_cat_server() OWNER TO postgres;

--
-- Name: registrar_ddl(); Type: FUNCTION; Schema: cdc; Owner: postgres
--

CREATE FUNCTION cdc.registrar_ddl() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- obj record;
var_object_identity varchar;
BEGIN


SELECT object_identity INTO var_object_identity FROM pg_catalog.pg_event_trigger_ddl_commands();


IF --tg_tag in('DROP TABLE','ALTER TABLE') AND 
var_object_identity = 'public.cat_server' then

INSERT INTO cdc.cat_server(operacion, valor_anterior, valor_nuevo, usuario, ip_cliente, fecha,query)
VALUES (TG_TAG, NULL, NULL, current_user, inet_client_addr(), CURRENT_TIMESTAMP,current_query());

END IF;


END;
$$;


ALTER FUNCTION cdc.registrar_ddl() OWNER TO postgres;

--
-- Name: exec_query_server(character varying, integer, character varying, character varying, integer, character varying, integer, integer); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.exec_query_server(ip character varying, par_port integer, par_db_name character varying, par_dbms character varying, id_remote_user integer, par_query_name character varying, par_id_exec integer DEFAULT 0, par_vers integer DEFAULT 0) RETURNS TABLE(status integer, error text)
    LANGUAGE plpgsql
    AS $$

DECLARE

var_id_exec int  := par_id_exec;
var_vers int := par_vers;
    query_remote text;
var_db_name varchar(255) := lower(par_db_name);
var_query_name varchar(255) := lower(par_query_name);
var_remote_user varchar(50);
passwd varchar(250); 
valor_query int;
ip_sin_punto varchar(50) := replace(ip, '.','');
VAR_ERROR INT := 0;
var_query_select text;
var_query_insert text;
var_regular_expression text;
var_query_result_ip text;
var_query_result_data text;
var_columns_type text;
var_lvl_exec_query varchar(100);
var_id_ctl_querys int;

clm_scn_rl RECORD;

otro text;

BEGIN

IF var_vers=0 THEN
IF par_dbms='PSQL' THEN

var_vers=8;

ELSIF par_dbms='MSSQL' THEN

var_vers=10;

END IF;
END IF;


IF var_id_exec =0 THEN
var_id_exec :=  -((RANDOM() * 9000 + 1000)::int);
END IF;

select  id,query_select,query_insert,regular_expression, columns_type,lvl_exec_query into var_id_ctl_querys,var_query_select,var_query_insert,var_regular_expression,var_columns_type,var_lvl_exec_query  from  fdw_conf.ctl_querys 
where query_name = var_query_name and dbms=  par_dbms and min_vers_compatibility <= var_vers  and max_vers_compatibility >= var_vers order by  min_vers_compatibility desc limit 1 ;




IF  var_query_select IS  NULL  THEN

VAR_ERROR := 1 ;
RETURN QUERY select 0::int,('ESTAS INTENTANDO EJECUTAR ' || var_query_name || ' UNA QUERY QUE NO EXISTE ' )::text   ;
ELSE
 

IF  var_regular_expression IS not NULL  THEN
BEGIN

EXECUTE 'select replace(query_select, ' || var_regular_expression || '  )   from  fdw_conf.ctl_querys where query_name = '''  || var_query_name  || ''' and dbms= ''' || par_dbms ||'''    and min_vers_compatibility <= ''' || var_vers ||'''   and max_vers_compatibility >= ''' || var_vers ||'''   order by  min_vers_compatibility desc limit 1 '  into var_query_select  ;  
 
EXCEPTION
  WHEN OTHERS THEN
-- RAISE NOTICE 'Este es el error : %', SQLERRM::text;

IF  (select  1  from fdw_conf.log_exec_failed_query WHERE ip_server = ip and port =  par_port and db= par_db_name and query_name =  var_query_name limit 1)  THEN
update fdw_conf.log_exec_failed_query set attempted_exec = attempted_exec +1, msg = SQLERRM::text, id_exec = par_id_exec  where   ip_server = ip and port =  par_port and db= par_db_name and query_name = var_query_name  ;

ELSE
insert into fdw_conf.log_exec_failed_query(ip_server,port,db,query_name,attempted_exec,msg,id_exec) select ip,par_port,par_db_name,var_query_name,1,SQLERRM::text,par_id_exec;
END IF;


VAR_ERROR := 1 ;
RETURN QUERY select 0::int,SQLERRM::text    ;

END;
END IF;


IF  var_lvl_exec_query = 'SERVER'   THEN

IF par_dbms='PSQL'   THEN
var_db_name := 'postgres';
ELSIF par_dbms='MSSQL' THEN
var_db_name := 'master';
END IF;

END IF;




IF par_dbms='PSQL' THEN
select remote_user, pg_down_html(password)  into var_remote_user,passwd  from  fdw_conf.ctl_remote_users WHERE  id= id_remote_user ; 
query_remote := 'SELECT *, ' || var_id_exec ||  '::int as id_exec from  public.dblink(''application_name=centraldata_dba_sec  dbname='|| var_db_name || ' port='|| par_port || ' host=' || ip || ' user='|| var_remote_user ||' password='|| passwd ||''', ';

 




BEGIN

 
 otro :=  replace(var_query_insert ,')' , ',id_exec)' )   ||  query_remote  || '''' || var_query_select || ''') as ('  || var_columns_type || ');' ;
--  RAISE NOTICE E'***** : \n %', otro;



--var_id_ctl_querys 


IF (select 1 from fdw_conf.scan_rules_query where id_query =  var_id_ctl_querys LIMIT 1) 
THEN

 
IF (select 1 from fdw_conf.scan_rules_query where (id_query =  var_id_ctl_querys ) and 
   ((ip_server = ip and port = par_port  and   db = var_db_name   ) 
or(ip_server = ip and  port  is null and db  is null  ) 
or(ip_server = ip and port = par_port and  db is null  ) 
or(ip_server = ip and port is null and   db =  var_db_name  ) 
or(ip_server is null and port =  par_port   and  db is null  ) 
or(ip_server is null and port =  par_port   and  db = var_db_name  ) 
or(ip_server is null and port is null  and   db = var_db_name  )
or(ip_server is null and port =  par_port and   db = var_db_name   ) ) limit 1 )
THEN
 
VAR_ERROR := 0 ;
EXECUTE otro; 

else 
return QUERY select 0::int, ('NO CUMPLE CON LA CONDICIONES:  select * from fdw_conf.scan_rules_query where id_query=  ' || var_id_ctl_querys|| ';')::text ;
VAR_ERROR := 1 ;
END IF;
 


else 
VAR_ERROR := 0 ;
-- RAISE NOTICE  'NOOOOO TIENE REGLAS LA QUERY !!!';
EXECUTE otro;

END IF;




EXCEPTION
  WHEN OTHERS THEN
 -- RAISE NOTICE '------------- : %', otro;
IF  (select  1  from fdw_conf.log_exec_failed_query WHERE ip_server = ip and port =  par_port and db= par_db_name and query_name =  var_query_name limit 1)  THEN
update fdw_conf.log_exec_failed_query set attempted_exec = attempted_exec +1, msg = SQLERRM::text, id_exec = par_id_exec where   ip_server = ip and port =  par_port and db= par_db_name and query_name = var_query_name  ;

ELSE
insert into fdw_conf.log_exec_failed_query(ip_server,port,db,query_name,attempted_exec,msg,id_exec) select ip,par_port,par_db_name,var_query_name,1,SQLERRM::text,par_id_exec;
END IF;


VAR_ERROR := 1 ;
RETURN QUERY select 0::int,SQLERRM::text    ;
 
END;
 
 

IF  VAR_ERROR = 0   THEN
 return QUERY select 1::int,''::text    ;
END IF;






ELSIF par_dbms='MSSQL' THEN
 

select remote_user, pg_down_html(password) into var_remote_user,passwd  from  fdw_conf.ctl_remote_users WHERE  id= id_remote_user ; 

 


IF ((SELECT 1 FROM pg_foreign_server where srvname = 'mssql_'||ip_sin_punto|| '_' || par_port || '_'  || var_db_name ) IS NULL) 
THEN

 
 

EXECUTE ' CREATE SERVER mssql_' || ip_sin_punto || '_' || par_port || '_'  || var_db_name || ' FOREIGN DATA WRAPPER tds_fdw OPTIONS (servername ''' ||  ip || ''', port ''' || par_port || ''', database ''' || var_db_name || '''); ';
EXECUTE ' CREATE USER MAPPING FOR postgres  SERVER mssql_'|| ip_sin_punto || '_' || par_port || '_'  || var_db_name || ' OPTIONS (username '''|| var_remote_user || ''', password '''|| passwd ||'''); ';
 

END IF;
 
IF NOT EXISTS ( select 1 from information_schema.tables where table_type='FOREIGN' and table_schema = 'fdw_conf' and table_name= var_query_name || '_'  || ip_sin_punto|| '_' || par_port  || '_' || var_db_name ) THEN
 

BEGIN
 otro :=  'CREATE FOREIGN TABLE  "fdw_conf".'|| var_query_name || '_'  || ip_sin_punto  || '_' || par_port  || '_' || var_db_name || ' ( ' || var_columns_type || ' )  SERVER mssql_'|| ip_sin_punto  || '_' || par_port || '_' || var_db_name ||' OPTIONS (  row_estimate_method ''showplan_all''   , query '' ' ||  var_query_select || ' '');';
EXECUTE otro;

EXCEPTION
  WHEN OTHERS THEN
    -- RAISE NOTICE 'ERROR AL CREAR LA FOREIGN TABLE: %', SQLERRM::text;
IF  (select  1  from fdw_conf.log_exec_failed_query WHERE ip_server = ip and port =  par_port and db= par_db_name and query_name =  var_query_name limit 1)  THEN
update fdw_conf.log_exec_failed_query set attempted_exec = attempted_exec +1, msg = SQLERRM::text, id_exec = par_id_exec where   ip_server = ip and port =  par_port and db= par_db_name and query_name = var_query_name  ;

ELSE
insert into fdw_conf.log_exec_failed_query(ip_server,port,db,query_name,attempted_exec,msg,id_exec) select ip,par_port,par_db_name,var_query_name,1,SQLERRM::text,par_id_exec;
END IF;  
VAR_ERROR := 1 ;
RETURN QUERY select 0::int,SQLERRM::text;
 
END;
END IF;


 
BEGIN


otro :=   replace(var_query_insert ,')' , ',id_exec)' ) || ' select *, ' || var_id_exec  || '::int as id_exec  from "fdw_conf".'|| var_query_name || '_'  || ip_sin_punto || '_' || par_port || '_' || var_db_name   ;



IF (select 1 from fdw_conf.scan_rules_query where id_query =  var_id_ctl_querys LIMIT 1) 
THEN

 
IF (select 1 from fdw_conf.scan_rules_query where (id_query =  var_id_ctl_querys ) and 
   ((ip_server = ip and port = par_port  and   db = var_db_name   ) 
or(ip_server = ip and  port  is null and db  is null  ) 
or(ip_server = ip and port = par_port and  db is null  ) 
or(ip_server = ip and port is null and   db =  var_db_name  ) 
or(ip_server is null and port =  par_port   and  db is null  ) 
or(ip_server is null and port =  par_port   and  db = var_db_name  ) 
or(ip_server is null and port is null  and   db = var_db_name  )
or(ip_server is null and port =  par_port and   db = var_db_name   ) ) limit 1 )
THEN
 
VAR_ERROR := 0 ;
EXECUTE otro; 

else 
return QUERY select 0::int, ('NO CUMPLE CON LA CONDICIONES:  select * from fdw_conf.scan_rules_query where id_query=  ' || var_id_ctl_querys|| ';')::text ;
VAR_ERROR := 1 ;
END IF;
 


else 
VAR_ERROR := 0 ;
--RAISE NOTICE  'NOOOOO TIENE REGLAS LA QUERY !!!';
EXECUTE otro;

END IF;




EXCEPTION
  WHEN OTHERS THEN
IF  (select  1  from fdw_conf.log_exec_failed_query WHERE ip_server = ip and port =  par_port and db= par_db_name and query_name =  var_query_name limit 1)  THEN
update fdw_conf.log_exec_failed_query set attempted_exec = attempted_exec +1, msg = SQLERRM::text, id_exec = par_id_exec where   ip_server = ip and port =  par_port and db= par_db_name and query_name = var_query_name  ;

ELSE
insert into fdw_conf.log_exec_failed_query(ip_server,port,db,query_name,attempted_exec,msg,id_exec) select ip,par_port,par_db_name,var_query_name,1,SQLERRM::text,par_id_exec;
END IF;
 
 VAR_ERROR := 1 ;
RETURN QUERY select 0::int,SQLERRM::text;
 
 
END;

   
 
IF VAR_ERROR = 0 THEN

RETURN QUERY  select 1::int,''::text;
END IF;


    ELSE
        
        RETURN QUERY select  0::int,'NO SE ENCONTRO EL DBMS'::text;
    END IF;

END IF;
 



END;
$$;


ALTER FUNCTION fdw_conf.exec_query_server(ip character varying, par_port integer, par_db_name character varying, par_dbms character varying, id_remote_user integer, par_query_name character varying, par_id_exec integer, par_vers integer) OWNER TO postgres;

--
-- Name: fun_biweekly_task(); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.fun_biweekly_task() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN

END;
$$;


ALTER FUNCTION fdw_conf.fun_biweekly_task() OWNER TO postgres;

--
-- Name: fun_daily_task(); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.fun_daily_task() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
   PERFORM  fdw_conf.gather_server_data( 'fun_daily_task'  );
END;
$$;


ALTER FUNCTION fdw_conf.fun_daily_task() OWNER TO postgres;

--
-- Name: fun_monthly_task(); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.fun_monthly_task() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN

PERFORM  fdw_conf.gather_server_data( 'fun_monthly_task'  );

END;
$$;


ALTER FUNCTION fdw_conf.fun_monthly_task() OWNER TO postgres;

--
-- Name: fun_test_connection(integer, integer); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.fun_test_connection(verbose_msj integer DEFAULT 0, timeout_telnet integer DEFAULT 1) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
var_fun_parameter  varchar(255) := 'fdw_conf.fun_test_connection(' || verbose_msj || ',' || timeout_telnet || ')';
 var_query_exception text;
var_id_exec  int;
var_clock_start TIMESTAMP;
var_port int;
var_ip_server text;
var_dbms text;
var_id_remote_user int;
var_test_telnet int;
var_status_connection_sql  int;
var_msg_notice text;
var_msg_notice_tb text;
insert_conection varchar;
otro text;
    nombre_cur CURSOR FOR
 select ip_server,port,a.dbms ,id_remote_user from public.cat_server  as a 
 left join fdw_conf.ctl_remote_users as b on a.id_remote_user= b.id
 where a.dbms in('MSSQL','PSQL')  and a.id_remote_user is not null
 /*and ip_server in('10.28.230.122','10.28.230.123')*/ order by a.dbms    ;

 
BEGIN

var_id_exec :=  nextval('fdw_conf.seq_id_exec'::regclass);
   
    var_clock_start := clock_timestamp();

    OPEN nombre_cur; -- Abrir el cursor
    
    LOOP
        FETCH nombre_cur INTO var_ip_server, var_port,var_dbms, var_id_remote_user; 
        
        EXIT WHEN NOT FOUND;  
        
 
          

 --perform pg_sleep(2);

var_ip_server := replace(var_ip_server,' ','') ;

var_test_telnet := fdw_conf.test_telnet(var_ip_server, var_port, timeout_telnet)   ;




IF ( var_test_telnet ) THEN

var_msg_notice := 'CONNECTIONS: ( TELNET SUCCESSFUL ';






IF  var_id_remote_user is not null  THEN

BEGIN

var_query_exception := 'select *   from fdw_conf.exec_query_server(''' || var_ip_server || ''', '|| var_port || ', null, ''' || var_dbms || ''' ,' || var_id_remote_user || ',  ''cat_versions'', ' || var_id_exec || ' ); ';
EXECUTE   var_query_exception into var_status_connection_sql , var_msg_notice_tb; 

EXCEPTION
  WHEN OTHERS THEN
  
insert into   fdw_conf.log_msg_error(original_obj_name, type_object , query_error , msg_error ) select  var_fun_parameter,  'FUNCTION' , var_query_exception, SQLERRM;

END;



IF ( var_status_connection_sql ) THEN
var_msg_notice := var_msg_notice || ', SQL SUCCESSFUL )';

BEGIN
var_query_exception := 'select *   from fdw_conf.exec_query_server(''' || var_ip_server || ''', '|| var_port || ', null, ''' || var_dbms || ''' ,' || var_id_remote_user || ',  ''cat_dbs'', ' || var_id_exec || ' ); ';
EXECUTE   var_query_exception into var_status_connection_sql , var_msg_notice_tb;


EXCEPTION
  WHEN OTHERS THEN

insert into   fdw_conf.log_msg_error(original_obj_name, type_object , query_error , msg_error )  select  var_fun_parameter,  'FUNCTION' , var_query_exception, SQLERRM;

END;

else 
var_msg_notice := var_msg_notice || ', SQL FAILED )';
END IF;  


END IF;  
   


 
else 
 

var_msg_notice := 'CONNECTION: ( TELNET FAILED )';
var_status_connection_sql := 0;
 
END IF;  


IF ( verbose_msj ) THEN
RAISE NOTICE ' % [%] - %:%   ',var_msg_notice,var_dbms , var_ip_server ,var_port ;
END IF;





insert into fdw_conf.details_connection(ip_server,port,dbms,connection_telnet,connection_sql,msg_log,id_exec) select var_ip_server,var_port,var_dbms, var_test_telnet , var_status_connection_sql , var_msg_notice || ' -- ' || var_msg_notice_tb , var_id_exec;
 

    END LOOP;
    
    CLOSE nombre_cur; -- Cerrar el cursor
   
 

 

insert into  fdw_conf.report_connection( dbms,cnt_total_serv , cnt_connection_telnet, cnt_connection_sql  ,missing_connection_telnet, missing_connection_sql,execution_timems_func,id_exec)
select 
a.dbms
,cnt_total_serv
,COALESCE(cnt_connection_telnet,0) as cnt_connection_telnet
,COALESCE(cnt_connection_sql,0) as cnt_connection_sql
, (cnt_total_serv - COALESCE(cnt_connection_telnet,0))   as missing_connection_telnet
,((cnt_total_serv - COALESCE(cnt_connection_sql,0)) ) as missing_connection_sql
--,EXTRACT(MILLISECOND FROM ( var_clock_end  - var_clock_start ) )::NUMERIC(50,4)
, round(1000 * EXTRACT(epoch FROM clock_timestamp() - var_clock_start), 3)
,var_id_exec
from
(select dbms,count(*) as cnt_total_serv from public.cat_server  group by dbms ) as a 
left join 
(select dbms,sum(connection_telnet) as cnt_connection_telnet , sum(connection_sql)  as cnt_connection_sql from 
(select ROW_NUMBER() OVER ( PARTITION BY ip_server,port ORDER BY date_insert desc ) AS row,date_insert ,* 
from  fdw_conf.details_connection   where date_insert::date = now()::date ) as a where row=1  
group by dbms) as b
on a.dbms=b.dbms
order by  cnt_total_serv  desc;
 
 
 
END;
$$;


ALTER FUNCTION fdw_conf.fun_test_connection(verbose_msj integer, timeout_telnet integer) OWNER TO postgres;

--
-- Name: fun_update_sequences_ctl_querys(); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.fun_update_sequences_ctl_querys() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
var_query_exception TEXT;
BEGIN

 BEGIN
   var_query_exception := 'select setval(''fdw_conf.ctl_querys2_id_seq'', (SELECT coalesce(  max(id) , 1) FROM  fdw_conf.ctl_querys ));';
   EXECUTE var_query_exception;
   EXCEPTION
    WHEN OTHERS THEN   
insert into   fdw_conf.log_msg_error(original_obj_name, type_object , query_error , msg_error ) select   'public.fun_update_sequences_ctl_querys()' , 'TRIGGER FUNCTION',var_query_exception ,SQLERRM;
   END;
  
   RETURN NULL;
END;
$$;


ALTER FUNCTION fdw_conf.fun_update_sequences_ctl_querys() OWNER TO postgres;

--
-- Name: fun_update_sequences_details_connection(); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.fun_update_sequences_details_connection() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE

var_query_exception text;

BEGIN

   
   BEGIN
   var_query_exception := '
	select setval(''fdw_conf.details_connection_id_seq'', (SELECT  coalesce(  max(id) , 1) FROM  fdw_conf.details_connection)); 
	select setval(''fdw_conf.seq_id_exec'', (SELECT  coalesce(  max(id_exec) , 1) FROM  fdw_conf.details_connection));
   ';   
	execute var_query_exception;

EXCEPTION
  WHEN OTHERS THEN
  
insert into   fdw_conf.log_msg_error(original_obj_name, type_object , query_error , msg_error ) select  'fdw_conf.fun_update_sequences_details_connection()' , 'TRIGGER FUNCTION',var_query_exception ,SQLERRM;

END;
   
    RETURN NULL;
   
END;
$$;


ALTER FUNCTION fdw_conf.fun_update_sequences_details_connection() OWNER TO postgres;

--
-- Name: fun_update_sequences_report_connection(); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.fun_update_sequences_report_connection() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
var_query_exception TEXT;

BEGIN

   
   BEGIN
   var_query_exception := '
	select setval(''fdw_conf.report_connection_id_seq'', (SELECT  coalesce(  max(id) , 1) FROM  fdw_conf.report_connection)); 
	select setval(''fdw_conf.seq_id_exec'', (SELECT  coalesce(  max(id_exec) , 1) FROM  fdw_conf.report_connection));
   ';
	execute var_query_exception;

EXCEPTION
 WHEN OTHERS THEN
insert into   fdw_conf.log_msg_error(original_obj_name, type_object , query_error , msg_error ) select  'fdw_conf.fun_update_sequences_report_connection()' , 'FUNCTION',var_query_exception ,SQLERRM;
END;
   
    RETURN NULL;
   
END;
$$;


ALTER FUNCTION fdw_conf.fun_update_sequences_report_connection() OWNER TO postgres;

--
-- Name: fun_weekly_task(); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.fun_weekly_task() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
PERFORM fdw_conf.gather_server_data( 'fun_weekly_task'  );
END;
$$;


ALTER FUNCTION fdw_conf.fun_weekly_task() OWNER TO postgres;

--
-- Name: gather_server_data(character varying, boolean, character varying); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.gather_server_data(par_fun_task_name character varying, par_msg_cliente boolean DEFAULT false, par_ip_server character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$

DECLARE
var_fun_parameter varchar := 'fdw_conf.gather_server_data(' || par_fun_task_name::varchar || ',' || par_msg_cliente::varchar || ','|| par_ip_server ;

    var_query text;
var_error_status boolean := false;

var_fun_task_name varchar(100) := replace(par_fun_task_name,' ', '');

var_date_insert  date;
var_id_exec int;

var_status_exec_query_server int := 0;
var_error_exec_query_server text := '';

otro text;

var_query_clm_dls_cnt text;
clm_dls_cnt RECORD;
clm_query_name_db RECORD;
clm_query_name_srv RECORD;

var_ip_status_exec_server varchar(100) := '';
var_port_status_exec_server int := 0;
BEGIN




select date_insert::Date,id_exec into var_date_insert,var_id_exec from fdw_conf.report_connection where date_insert::Date =  current_date and cnt_connection_sql != 0 order by id_exec desc limit 1 ;

IF var_id_exec is null THEN 

var_error_status := true; 
IF par_msg_cliente  THEN RAISE NOTICE 'LA TABLA fdw_conf.report_connection NO TIENE REGISTROS O NO SE ENCONTRARON SERVIDORES CON CONEXIÓN SQL,  DÍA %',current_date  ; END IF;


insert into   fdw_conf.log_msg_error(original_obj_name, type_object , query_error , msg_error ) select  var_fun_parameter,  'FUNCTION' , 'LA TABLA fdw_conf.report_connection NO TIENE REGISTROS O NO SE ENCONTRARON SERVIDORES CON CONEXIÓN SQL,  DÍA '|| current_date, SQLERRM;


RETURN;

END IF;


IF par_msg_cliente  THEN RAISE NOTICE '### ### ### REGISTROS DEL ESCANEO, DÍA [%]  ID_EXEC [%] ### ### ### ' ,var_date_insert , var_id_exec ; END IF;


var_query_clm_dls_cnt := '
select 
a.ip_server
,a.port
,a.dbms
,d.id_remote_user
,SPLIT_PART(c.version, ''.'', 1) as version
,b.db_name
,a.id_exec
,a.date_insert::date 
from fdw_conf.details_connection as a
INNER JOIN  fdw_conf.cat_dbs as b 
on a.id_exec = b.id_exec and  a.date_insert::date =  b.date_insert::date and a.ip_server= b.ip_server and a.port = b.port
INNER JOIN  fdw_conf.cat_versions as c
on a.id_exec = c.id_exec and  a.date_insert::date =  c.date_insert::date  and a.ip_server= c.ip_server and a.port = c.port
INNER JOIN public.cat_server as d on a.ip_server= d.ip_server and a.port = d.port and id_remote_user is not null
where   a.connection_sql =1  
AND a.id_exec = ' || var_id_exec || ' 
AND b.db_name not in(''model'',''msdb'',''tempdb'')';

IF par_ip_server is null THEN
var_query_clm_dls_cnt := var_query_clm_dls_cnt || 'order by a.ip_server,a.port,b.db_name';
else 
var_query_clm_dls_cnt := var_query_clm_dls_cnt || 'and a.ip_server = ''' || par_ip_server || ''' order by a.ip_server,a.port,b.db_name';
END IF;



FOR clm_dls_cnt IN execute var_query_clm_dls_cnt

LOOP

   
IF (SELECT 1 FROM  fdw_conf.ctl_querys  where dbms = clm_dls_cnt.dbms  and fun_task_name= var_fun_task_name limit 1)  THEN


IF (var_ip_status_exec_server != clm_dls_cnt.ip_server) or (var_port_status_exec_server != clm_dls_cnt.port ) THEN 


IF par_msg_cliente  THEN RAISE NOTICE E'\n****** IP: % - Puerto: % - Version: % - DBMS : %  - DB: % - ID_EXEC: %' , clm_dls_cnt.ip_server , clm_dls_cnt.port , clm_dls_cnt.version, clm_dls_cnt.dbms, clm_dls_cnt.db_name, clm_dls_cnt.id_exec ; END IF;

var_port_status_exec_server := clm_dls_cnt.port ;
var_ip_status_exec_server := clm_dls_cnt.ip_server;

FOR clm_query_name_srv IN  SELECT query_name,lvl_exec_query,fun_task_name  FROM  fdw_conf.ctl_querys  where lvl_exec_query =  'SERVER'  and verbose_query = true and   dbms = clm_dls_cnt.dbms   and   fun_task_name= var_fun_task_name  GROUP BY query_name, lvl_exec_query,fun_task_name order by lvl_exec_query desc
LOOP
  


select * into var_status_exec_query_server , var_error_exec_query_server  from  fdw_conf.exec_query_server(clm_dls_cnt.ip_server, clm_dls_cnt.port, clm_dls_cnt.db_name, clm_dls_cnt.dbms , clm_dls_cnt.id_remote_user , clm_query_name_srv.query_name ,clm_dls_cnt.id_exec  ,clm_dls_cnt.version::int );

IF var_status_exec_query_server  THEN 
IF par_msg_cliente  THEN RAISE NOTICE '-> [SUCCESSFUL] lvl_exec: % - Task_name: % - Query: %   ',  clm_query_name_srv.lvl_exec_query , clm_query_name_srv.fun_task_name , clm_query_name_srv.query_name ; END IF;
else 

IF par_msg_cliente  THEN RAISE NOTICE '-> [FAILED] lvl_exec: % - Task_name: % - Query: %   - MSG ERROR :  %' , clm_query_name_srv.lvl_exec_query , clm_query_name_srv.fun_task_name, clm_query_name_srv.query_name  , var_error_exec_query_server; END IF;
 

END IF;

 
END LOOP; 
END IF;
 
-- perform pg_sleep(5);


IF  not clm_dls_cnt.db_name in('postgres','master','model','msdb','tempdb') and (SELECT 1::boolean FROM  fdw_conf.ctl_querys where  lvl_exec_query =  'DATABASE' and   dbms =  clm_dls_cnt.dbms   and   fun_task_name=  var_fun_task_name  limit 1 ) THEN 

IF par_msg_cliente  THEN RAISE NOTICE E'\n****** IP: % - Puerto: % - Version: % - DBMS : %  - DB: % - ID_EXEC: %' , clm_dls_cnt.ip_server , clm_dls_cnt.port , clm_dls_cnt.version, clm_dls_cnt.dbms, clm_dls_cnt.db_name, clm_dls_cnt.id_exec ; END IF;

FOR clm_query_name_db IN  SELECT query_name,lvl_exec_query ,fun_task_name FROM  fdw_conf.ctl_querys  where  lvl_exec_query =  'DATABASE' and   verbose_query = true and   dbms = clm_dls_cnt.dbms   and   fun_task_name=  var_fun_task_name  GROUP BY query_name, lvl_exec_query,fun_task_name order by lvl_exec_query desc
LOOP
 

select * into var_status_exec_query_server , var_error_exec_query_server  from  fdw_conf.exec_query_server(clm_dls_cnt.ip_server, clm_dls_cnt.port, clm_dls_cnt.db_name, clm_dls_cnt.dbms , clm_dls_cnt.id_remote_user , clm_query_name_db.query_name ,clm_dls_cnt.id_exec  ,clm_dls_cnt.version::int );

IF var_status_exec_query_server  THEN 
IF par_msg_cliente  THEN RAISE NOTICE E'-> [SUCCESSFUL] lvl_exec: % - Task_name: %  - Query: % ', clm_query_name_db.lvl_exec_query , clm_query_name_db.fun_task_name, clm_query_name_db.query_name ; END IF;
else 
IF par_msg_cliente  THEN RAISE NOTICE E'-> [FAILED] lvl_exec: % - Task_name: %  - Query: % - MSG ERROR :  %' , clm_query_name_db.lvl_exec_query  , clm_query_name_db.fun_task_name , clm_query_name_db.query_name  , var_error_exec_query_server; END IF;


END IF;


END LOOP;
END IF;



else 

IF par_msg_cliente  THEN RAISE NOTICE 'NO SE ENCONTRARON QUERY PARA EL DBMS: %', clm_dls_cnt.dbms; END IF;

insert into   fdw_conf.log_msg_error(original_obj_name, type_object , query_error , msg_error ) select  var_fun_parameter,  'FUNCTION' , ' NO SE ENCONTRARON QUERY PARA EL DBMS: '|| clm_dls_cnt.dbms, SQLERRM;


END IF;


END LOOP;



IF par_msg_cliente  THEN RAISE NOTICE E'\nFINALIZÓ EL SCRIPT!!! ' ; END IF;
RETURN;

END;
$$;


ALTER FUNCTION fdw_conf.gather_server_data(par_fun_task_name character varying, par_msg_cliente boolean, par_ip_server character varying) OWNER TO postgres;

--
-- Name: test_con_sql(character varying, integer, character varying, integer); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.test_con_sql(ip character varying, port integer, dbms character varying, id_remote_user integer) RETURNS TABLE(connection integer, error text)
    LANGUAGE plpgsql
    AS $$

DECLARE
    query text;
var_remote_user varchar(50);
passwd varchar(250);
valor_query int;
ip_sin_punto varchar(50) := replace(ip, '.','');
VAR_ERROR INT := 0;
otro text;
BEGIN



IF dbms='PSQL' THEN
select remote_user, pg_down_html(password)  into var_remote_user,passwd  from  fdw_conf.ctl_remote_users WHERE  id= id_remote_user ; 
query := 'SELECT * from  public.dblink(''application_name=centraldata_dba_sec dbname=postgres port='|| port || ' host=' || ip || ' user='|| var_remote_user ||' password='|| passwd ||''', ''select 1 as test_con;'') as (test_con int);';

 -- RAISE NOTICE ' ############## %', query;


BEGIN
EXECUTE query ;

EXCEPTION
  WHEN OTHERS THEN
-- RAISE NOTICE 'Este es el error : %', SQLERRM;

VAR_ERROR := 1 ;
RETURN QUERY select 0,SQLERRM    ;
 
END;

 IF VAR_ERROR = 0 THEN
RETURN QUERY  select 1,''::text;
 END IF;

ELSIF dbms='MSSQL' THEN



select remote_user, pg_down_html(password) into var_remote_user,passwd  from  fdw_conf.ctl_remote_users WHERE  id= id_remote_user ; 

IF NOT EXISTS (SELECT 1 FROM pg_foreign_server where srvname = 'mssql_'||ip_sin_punto|| '_' || port  ) 
THEN


 EXECUTE ' CREATE SERVER mssql_' || ip_sin_punto || '_' || port ||' FOREIGN DATA WRAPPER tds_fdw OPTIONS (servername ''' ||  ip || ''', port ''' || port || ''', database ''master''); ';

 EXECUTE ' CREATE USER MAPPING FOR postgres  SERVER mssql_'|| ip_sin_punto || '_' || port ||' OPTIONS (username '''|| var_remote_user || ''', password '''|| passwd ||'''); ';
 
 
END IF;
 
IF NOT EXISTS ( select 1 from information_schema.tables where table_type='FOREIGN' and table_schema = 'fdw_conf' and table_name= 'test_conection_'||ip_sin_punto|| '_' || port  ) THEN


BEGIN
EXECUTE 'CREATE FOREIGN TABLE  "fdw_conf".test_conection_'||ip_sin_punto  || '_' || port || ' ( connection int )  SERVER mssql_'|| ip_sin_punto  || '_' || port ||' OPTIONS (  row_estimate_method ''showplan_all''   , query '' select   1 as connection '');';

EXCEPTION
  WHEN OTHERS THEN
  -- RAISE NOTICE 'ERROR AL CREAR LA FOREIGN TABLE: %', SQLERRM;
  
VAR_ERROR := 1 ;
RETURN QUERY select 0,SQLERRM;
 
END;
END IF;


 
BEGIN
EXECUTE 'select connection from "fdw_conf".test_conection_' || ip_sin_punto || '_' || port   into valor_query ;

EXCEPTION
  WHEN OTHERS THEN
   

 
 VAR_ERROR := 1 ;
RETURN QUERY select 0,SQLERRM;
 
 
END;

   
 
IF VAR_ERROR = 0 THEN

RETURN QUERY  select 1,''::text;
END IF;

    ELSE
        
        RETURN QUERY select 0,'NO SE ENCONTRO EL DBMS';
    END IF;

 



END;
$$;


ALTER FUNCTION fdw_conf.test_con_sql(ip character varying, port integer, dbms character varying, id_remote_user integer) OWNER TO postgres;

--
-- Name: test_telnet(character varying, integer, integer); Type: FUNCTION; Schema: fdw_conf; Owner: postgres
--

CREATE FUNCTION fdw_conf.test_telnet(ip character varying, port integer, timeout integer DEFAULT 2) RETURNS integer
    LANGUAGE plpgsql
    AS $_$

DECLARE
    query text;
var_connection int;
BEGIN


query := 'COPY tmp_test_telnet from  PROGRAM ''echo "'  || ip || '",$(if [ -z "$(echo -e "quit" | timeout ' || timeout || '  telnet ' || ip || ' ' ||  port  || ' 2>/dev/null | grep "Escape character")" ]; then echo  0;  else        echo  1;  fi)'' WITH (FORMAT CSV); ';
 
 
IF ip IS  NULL or port IS  NULL THEN
RAISE NOTICE ' SALIENDO YA QUE NO COLOCO ALGUN PARAMETRO';
        RETURN 0;
    END IF;



IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE  tablename = 'tmp_test_telnet') THEN
CREATE TEMP TABLE tmp_test_telnet (
ip varchar(50),
connection  INT
);
    END IF;




BEGIN
EXECUTE query ;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Este es el error : %', SQLERRM;
return 0;
 
END;

SELECT connection into var_connection FROM tmp_test_telnet;
drop TABLE tmp_test_telnet;

return var_connection;


END;
$_$;


ALTER FUNCTION fdw_conf.test_telnet(ip character varying, port integer, timeout integer) OWNER TO postgres;

--
-- Name: replicate_to_datos_generales(); Type: FUNCTION; Schema: psql; Owner: postgres
--

CREATE FUNCTION psql.replicate_to_datos_generales() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   INSERT INTO datos_generales (cliente_id, nombre, apellido, telefono)
   VALUES (NEW.id, NEW.nombre, NEW.apellido, NEW.telefono);
   RETURN NEW;
END;
$$;


ALTER FUNCTION psql.replicate_to_datos_generales() OWNER TO postgres;

--
-- Name: error(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.error() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Intenta ejecutar una operación que genere un error (división por cero)
    PERFORM 1 / 0; -- Esto generará un error de división por cero
EXCEPTION
    WHEN division_by_zero THEN
        -- Captura la excepción específica de división por cero
        RAISE NOTICE 'Error de división por cero capturado: %', SQLERRM;
END $$;


ALTER FUNCTION public.error() OWNER TO postgres;

--
-- Name: fun_update_sequences_public_cat_server(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fun_update_sequences_public_cat_server() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE

var_query_exception text;

BEGIN

   
   BEGIN
   var_query_exception := '
	select setval(''ctl_server_id_seq'', (SELECT  coalesce(  max(id) , 1) FROM  public.cat_server)); 
   ';   
	execute var_query_exception;

EXCEPTION
  WHEN OTHERS THEN
  
insert into   fdw_conf.log_msg_error(original_obj_name, type_object , query_error , msg_error ) select  'public.fun_update_sequences_public_cat_server()' , 'TRIGGER FUNCTION',var_query_exception ,SQLERRM;

END;
   
    RETURN NULL;
   
END;
$$;


ALTER FUNCTION public.fun_update_sequences_public_cat_server() OWNER TO postgres;

--
-- Name: pg_crypt(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pg_crypt(dato text) RETURNS bytea
    LANGUAGE plpgsql
    AS $$
DECLARE
xcvxcvbnhbr text := '4z5K+4[gzTq]7aq&2^';
nkhioasd9548asd text := dato;
varcasdasdasdasd text := 'enc';
uytre text := chr(95);
varcvvff text := 'i>OT!kyANA/05X@';
nascrgd text := 'ry';
byhfascac text := ''');';
s5f564b864rg_ text := ''',''';
ndf_5hsdf text ; 
adsdasdasc text;
va8pijfv text := chr(95);
    sinosinolasino BYTEA;
varcasdasdasdasd0   text; 
cbnmhfce text :=  chr(112) ||  chr(103)  || chr(112);
njsdcascasd text := '(''';
fafgvhbhb text := chr(115) ||  chr(121)  || chr(109);
ojhgfd text := '0}qgf5Iw3p0.q=6J';
hgft6j3 text := 'pt';
BEGIN 
 varcasdasdasdasd0 := cbnmhfce || uytre || fafgvhbhb || va8pijfv || varcasdasdasdasd || nascrgd || hgft6j3 || njsdcascasd || nkhioasd9548asd || s5f564b864rg_   ;
xcvxcvbnhbr :=  encode(encode( varcvvff::bytea || ojhgfd::bytea || xcvxcvbnhbr::bytea , 'hex')::bytea, 'base64');
 varcasdasdasdasd := convert_from(decode('73656c', 'hex'), 'UTF8');
cbnmhfce :=  replace(substring(xcvxcvbnhbr, 1, 10) || va8pijfv || varcasdasdasdasd  || substring(xcvxcvbnhbr, 10) || nascrgd  , 'E' ,'*-*')  ;
njsdcascasd :=   convert_from(decode('65637420', 'hex'), 'UTF8');
hgft6j3 := SPLIT_PART(cbnmhfce, '*-*', 2) || '*-*' ||  SPLIT_PART(cbnmhfce, '*-*', 1);
fafgvhbhb := varcasdasdasdasd0 || hgft6j3   || byhfascac  ;
cbnmhfce := varcasdasdasdasd || njsdcascasd ;
execute  cbnmhfce || fafgvhbhb into sinosinolasino;
    RETURN sinosinolasino ;
END;
$$;


ALTER FUNCTION public.pg_crypt(dato text) OWNER TO postgres;

--
-- Name: pg_down_html(bytea); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pg_down_html(dato bytea) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
xcvxcvbnhbr text := '4z5K+4[gzTq]7aq&2^';
nkhioasd9548asd text := dato;
varcasdasdasdasd text := chr(100) ||  chr(101)  || chr(99);
uytre text := chr(95);
varcvvff text := 'i>OT!kyANA/05X@';
nascrgd text := 'ry';
byhfascac text := ''');';
s5f564b864rg_ text := ''',''';
ndf_5hsdf text ; 
adsdasdasc text;
va8pijfv text := chr(95);
    sinosinolasino text;
varcasdasdasdasd0   text; 
cbnmhfce text :=  chr(112) ||  chr(103)  || chr(112);
njsdcascasd text := '(''';
fafgvhbhb text := chr(115) ||  chr(121)  || chr(109);
ojhgfd text := '0}qgf5Iw3p0.q=6J';
hgft6j3 text := 'pt';
BEGIN 
varcasdasdasdasd0 := cbnmhfce || uytre || fafgvhbhb || va8pijfv || varcasdasdasdasd || nascrgd || hgft6j3 || njsdcascasd || nkhioasd9548asd || s5f564b864rg_   ;
xcvxcvbnhbr :=  encode(encode( varcvvff::bytea || ojhgfd::bytea || xcvxcvbnhbr::bytea , 'hex')::bytea, 'base64');
 varcasdasdasdasd := convert_from(decode('73656c', 'hex'), 'UTF8');
cbnmhfce :=  replace(substring(xcvxcvbnhbr, 1, 10) || va8pijfv || varcasdasdasdasd  || substring(xcvxcvbnhbr, 10) || nascrgd  , 'E' ,'*-*')  ;
njsdcascasd :=   convert_from(decode('65637420', 'hex'), 'UTF8');
hgft6j3 := SPLIT_PART(cbnmhfce, '*-*', 2) || '*-*' ||  SPLIT_PART(cbnmhfce, '*-*', 1);
fafgvhbhb := varcasdasdasdasd0 || hgft6j3   || byhfascac  ;
cbnmhfce := varcasdasdasdasd || njsdcascasd ;
    execute  cbnmhfce || fafgvhbhb into sinosinolasino;
    RETURN sinosinolasino ;
END;
$$;


ALTER FUNCTION public.pg_down_html(dato bytea) OWNER TO postgres;

--
-- Name: trigger_function_cat_server_truncate(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_function_cat_server_truncate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO cdc.cat_server(operacion, valor_anterior, valor_nuevo, usuario, ip_cliente, fecha,query)
    VALUES ('TRUNCATE', NULL, NULL, current_user, inet_client_addr(), CURRENT_TIMESTAMP,current_query());    
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.trigger_function_cat_server_truncate() OWNER TO postgres;

--
-- Name: verificar_filas(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verificar_filas() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    resultado RECORD;
BEGIN
    -- Ejecutar la consulta
    FOR resultado IN
        select id_query,ip_server,port,db from fdw_conf.scan_rules_query where id_query =  44 limit 10
    LOOP
        -- Si se encuentra al menos una fila, devolver TRUE
RAISE NOTICE '----> SI CUMPLEEE LA CONDICION';
        --RETURN TRUE;
    END LOOP;

    -- Si no se encontraron filas, devolver FALSE
    RETURN FALSE;
END;
$$;


ALTER FUNCTION public.verificar_filas() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cat_server; Type: TABLE; Schema: cdc; Owner: postgres
--

CREATE TABLE cdc.cat_server (
    id integer NOT NULL,
    operacion character varying(100),
    usuario character varying(100),
    ip_cliente character varying(100),
    query text,
    valor_anterior jsonb,
    valor_nuevo jsonb,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE cdc.cat_server OWNER TO postgres;

--
-- Name: cat_server_id_seq; Type: SEQUENCE; Schema: cdc; Owner: postgres
--

CREATE SEQUENCE cdc.cat_server_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE cdc.cat_server_id_seq OWNER TO postgres;

--
-- Name: cat_server_id_seq; Type: SEQUENCE OWNED BY; Schema: cdc; Owner: postgres
--

ALTER SEQUENCE cdc.cat_server_id_seq OWNED BY cdc.cat_server.id;


--
-- Name: blacklist_server; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.blacklist_server (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    description text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL
);


ALTER TABLE fdw_conf.blacklist_server OWNER TO postgres;

--
-- Name: blacklist_server_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.blacklist_server_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.blacklist_server_id_seq OWNER TO postgres;

--
-- Name: blacklist_server_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.blacklist_server_id_seq OWNED BY fdw_conf.blacklist_server.id;


--
-- Name: cat_category_querys; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.cat_category_querys (
    id integer NOT NULL,
    category character varying(255) NOT NULL,
    des_cat text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL
);


ALTER TABLE fdw_conf.cat_category_querys OWNER TO postgres;

--
-- Name: cat_category_querys_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.cat_category_querys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.cat_category_querys_id_seq OWNER TO postgres;

--
-- Name: cat_category_querys_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.cat_category_querys_id_seq OWNED BY fdw_conf.cat_category_querys.id;


--
-- Name: ctl_ports; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.ctl_ports (
    id integer NOT NULL,
    dbms character varying(100),
    port integer,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone
);


ALTER TABLE fdw_conf.ctl_ports OWNER TO postgres;

--
-- Name: cat_dbms_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.cat_dbms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.cat_dbms_id_seq OWNER TO postgres;

--
-- Name: cat_dbms_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.cat_dbms_id_seq OWNED BY fdw_conf.ctl_ports.id;


--
-- Name: ctl_dbms; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.ctl_dbms (
    id integer NOT NULL,
    dbms character varying(100) NOT NULL,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL
);


ALTER TABLE fdw_conf.ctl_dbms OWNER TO postgres;

--
-- Name: cat_dbms_id_seq1; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.cat_dbms_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.cat_dbms_id_seq1 OWNER TO postgres;

--
-- Name: cat_dbms_id_seq1; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.cat_dbms_id_seq1 OWNED BY fdw_conf.ctl_dbms.id;


--
-- Name: cat_dbs; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.cat_dbs (
    id integer NOT NULL,
    ip_server character varying(20) NOT NULL,
    port integer NOT NULL,
    db_name character varying(255) NOT NULL,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL,
    id_exec integer
);


ALTER TABLE fdw_conf.cat_dbs OWNER TO postgres;

--
-- Name: cat_dbs_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.cat_dbs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.cat_dbs_id_seq OWNER TO postgres;

--
-- Name: cat_dbs_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.cat_dbs_id_seq OWNED BY fdw_conf.cat_dbs.id;


--
-- Name: cat_lvl_exec_querys; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.cat_lvl_exec_querys (
    id integer NOT NULL,
    level character varying(50) NOT NULL,
    desc_lvl text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL
);


ALTER TABLE fdw_conf.cat_lvl_exec_querys OWNER TO postgres;

--
-- Name: cat_lvl_exec_querys_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.cat_lvl_exec_querys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.cat_lvl_exec_querys_id_seq OWNER TO postgres;

--
-- Name: cat_lvl_exec_querys_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.cat_lvl_exec_querys_id_seq OWNED BY fdw_conf.cat_lvl_exec_querys.id;


--
-- Name: ctl_remote_users; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.ctl_remote_users (
    id integer NOT NULL,
    dbms character varying(50),
    remote_user character varying(255),
    password bytea,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL
);


ALTER TABLE fdw_conf.ctl_remote_users OWNER TO postgres;

--
-- Name: cat_remote_user_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.cat_remote_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.cat_remote_user_id_seq OWNER TO postgres;

--
-- Name: cat_remote_user_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.cat_remote_user_id_seq OWNED BY fdw_conf.ctl_remote_users.id;


--
-- Name: cat_version_mssql_oficial; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.cat_version_mssql_oficial (
    id integer NOT NULL,
    sql_server integer,
    other character varying(100),
    product_version character varying(100),
    service_pack character varying(100),
    update character varying(100),
    knowledge_base_number character varying(100),
    release_date character varying(100),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone
);


ALTER TABLE fdw_conf.cat_version_mssql_oficial OWNER TO postgres;

--
-- Name: cat_version_mssql_oficial_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.cat_version_mssql_oficial_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.cat_version_mssql_oficial_id_seq OWNER TO postgres;

--
-- Name: cat_version_mssql_oficial_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.cat_version_mssql_oficial_id_seq OWNED BY fdw_conf.cat_version_mssql_oficial.id;


--
-- Name: cat_versions; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.cat_versions (
    id integer NOT NULL,
    ip_server character varying(20) NOT NULL,
    port integer NOT NULL,
    version character varying(255) NOT NULL,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL,
    id_exec integer
);


ALTER TABLE fdw_conf.cat_versions OWNER TO postgres;

--
-- Name: cat_versions_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.cat_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.cat_versions_id_seq OWNER TO postgres;

--
-- Name: cat_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.cat_versions_id_seq OWNED BY fdw_conf.cat_versions.id;


--
-- Name: ctl_querys; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.ctl_querys (
    id integer NOT NULL,
    dbms character varying(255) NOT NULL,
    query_name character varying(255) NOT NULL,
    category character varying(255) NOT NULL,
    lvl_exec_query character varying(50) NOT NULL,
    verbose_query boolean NOT NULL,
    desc_query text,
    regular_expression character varying(250),
    min_vers_compatibility integer NOT NULL,
    max_vers_compatibility integer NOT NULL,
    query_select text NOT NULL,
    query_insert text NOT NULL,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL,
    columns_type text NOT NULL,
    fun_task_name character varying(100) DEFAULT 'fun_daily_task'::character varying NOT NULL
);


ALTER TABLE fdw_conf.ctl_querys OWNER TO postgres;

--
-- Name: ctl_querys2_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.ctl_querys2_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.ctl_querys2_id_seq OWNER TO postgres;

--
-- Name: ctl_querys2_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.ctl_querys2_id_seq OWNED BY fdw_conf.ctl_querys.id;


--
-- Name: details_connection; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.details_connection (
    id bigint NOT NULL,
    ip_server character varying(255) NOT NULL,
    port integer NOT NULL,
    dbms character varying(50) NOT NULL,
    connection_telnet integer NOT NULL,
    connection_sql integer NOT NULL,
    msg_log text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL,
    id_exec integer
);


ALTER TABLE fdw_conf.details_connection OWNER TO postgres;

--
-- Name: details_connection_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.details_connection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.details_connection_id_seq OWNER TO postgres;

--
-- Name: details_connection_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.details_connection_id_seq OWNED BY fdw_conf.details_connection.id;


--
-- Name: funs_tanks; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.funs_tanks (
    id integer NOT NULL,
    fun_name character varying(100) NOT NULL,
    fun_desc text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL
);


ALTER TABLE fdw_conf.funs_tanks OWNER TO postgres;

--
-- Name: funs_tanks_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.funs_tanks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.funs_tanks_id_seq OWNER TO postgres;

--
-- Name: funs_tanks_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.funs_tanks_id_seq OWNED BY fdw_conf.funs_tanks.id;


--
-- Name: log_exec_failed_query; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.log_exec_failed_query (
    id integer NOT NULL,
    ip_server character varying(255) NOT NULL,
    port integer NOT NULL,
    db character varying(255),
    query_name character varying(100),
    attempted_exec integer,
    msg text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL,
    id_exec integer
);


ALTER TABLE fdw_conf.log_exec_failed_query OWNER TO postgres;

--
-- Name: log_exec_failed_query_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.log_exec_failed_query_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.log_exec_failed_query_id_seq OWNER TO postgres;

--
-- Name: log_exec_failed_query_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.log_exec_failed_query_id_seq OWNED BY fdw_conf.log_exec_failed_query.id;


--
-- Name: log_msg_error; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.log_msg_error (
    id integer NOT NULL,
    original_obj_name character varying(255),
    type_object character varying(100),
    query_error text,
    msg_error text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone
);


ALTER TABLE fdw_conf.log_msg_error OWNER TO postgres;

--
-- Name: log_msg_error_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.log_msg_error_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.log_msg_error_id_seq OWNER TO postgres;

--
-- Name: log_msg_error_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.log_msg_error_id_seq OWNED BY fdw_conf.log_msg_error.id;


--
-- Name: report_connection; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.report_connection (
    id bigint NOT NULL,
    dbms character varying(100) NOT NULL,
    cnt_total_serv integer NOT NULL,
    cnt_connection_telnet integer NOT NULL,
    cnt_connection_sql integer NOT NULL,
    missing_connection_telnet integer NOT NULL,
    missing_connection_sql integer NOT NULL,
    execution_timems_func numeric(50,4),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL,
    id_exec integer
);


ALTER TABLE fdw_conf.report_connection OWNER TO postgres;

--
-- Name: report_connection_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.report_connection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.report_connection_id_seq OWNER TO postgres;

--
-- Name: report_connection_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.report_connection_id_seq OWNED BY fdw_conf.report_connection.id;


--
-- Name: scan_rules_query; Type: TABLE; Schema: fdw_conf; Owner: postgres
--

CREATE TABLE fdw_conf.scan_rules_query (
    id integer NOT NULL,
    id_query integer,
    ip_server character varying(100),
    port integer,
    db character varying(100),
    description text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    CONSTRAINT cnst_scan_rules_query_idquery CHECK (((id_query IS NOT NULL) AND ((ip_server IS NOT NULL) OR (port IS NOT NULL) OR (db IS NOT NULL))))
);


ALTER TABLE fdw_conf.scan_rules_query OWNER TO postgres;

--
-- Name: scan_rules_query_id_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.scan_rules_query_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.scan_rules_query_id_seq OWNER TO postgres;

--
-- Name: scan_rules_query_id_seq; Type: SEQUENCE OWNED BY; Schema: fdw_conf; Owner: postgres
--

ALTER SEQUENCE fdw_conf.scan_rules_query_id_seq OWNED BY fdw_conf.scan_rules_query.id;


--
-- Name: seq_id_exec; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.seq_id_exec
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.seq_id_exec OWNER TO postgres;

--
-- Name: test_seq; Type: SEQUENCE; Schema: fdw_conf; Owner: postgres
--

CREATE SEQUENCE fdw_conf.test_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE fdw_conf.test_seq OWNER TO postgres;

--
-- Name: dbs; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.dbs (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    user_access_desc character varying(255),
    state_desc character varying(255),
    owner character varying(255),
    total_size_gb numeric(20,2),
    ldf_size_gb numeric(20,2),
    mdf_size_gb numeric(20,2),
    collation_name character varying(255),
    recovery_model_desc character varying(255),
    compatibility_level integer,
    is_trustworthy_on integer,
    is_encrypted integer,
    is_read_only integer,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.dbs OWNER TO postgres;

--
-- Name: dbs_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.dbs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.dbs_id_seq OWNER TO postgres;

--
-- Name: dbs_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.dbs_id_seq OWNED BY mssql.dbs.id;


--
-- Name: funproc; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.funproc (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    schema_name character varying(255),
    object_name character varying(255),
    owner character varying(255),
    md5 character varying(255),
    type character varying(255),
    create_date timestamp without time zone,
    modify_date timestamp without time zone,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.funproc OWNER TO postgres;

--
-- Name: funproc_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.funproc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.funproc_id_seq OWNER TO postgres;

--
-- Name: funproc_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.funproc_id_seq OWNED BY mssql.funproc.id;


--
-- Name: info_backup; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.info_backup (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    name_server character varying(255),
    db character varying(255),
    date_start timestamp without time zone,
    date_finish timestamp without time zone,
    type_backup character varying(255),
    size numeric(20,4),
    physical_route character varying(255),
    name_backup character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.info_backup OWNER TO postgres;

--
-- Name: info_backup_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.info_backup_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.info_backup_id_seq OWNER TO postgres;

--
-- Name: info_backup_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.info_backup_id_seq OWNED BY mssql.info_backup.id;


--
-- Name: info_hardware; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.info_hardware (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    sqlserver_start_time timestamp without time zone,
    cpu_count integer,
    scheduler_count integer,
    hyperthread_ratio integer,
    physical_cpu_count integer,
    cpu_sql integer,
    total_memory_ram_os_mb integer,
    memory_used_os integer,
    percentage_memory_used_os integer,
    percentage_available_memory_ram_os integer,
    available_memory_ram_os_mb integer,
    committed_memory_mb integer,
    max_workers_count integer,
    affinity_type character varying(255),
    virtual_machine_type character varying(255),
    soft_numa_configuration character varying(255),
    total_sql_server_memory_mb integer,
    max_sql_server_memory_ram_mb integer,
    system_memory_state character varying(255),
    page_life_expectancy integer,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.info_hardware OWNER TO postgres;

--
-- Name: info_hardware_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.info_hardware_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.info_hardware_id_seq OWNER TO postgres;

--
-- Name: info_hardware_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.info_hardware_id_seq OWNED BY mssql.info_hardware.id;


--
-- Name: info_job; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.info_job (
    id integer NOT NULL,
    port integer,
    ip_server character varying(255),
    job_name character varying(255),
    job_description character varying(255),
    job_owner character varying(255),
    date_created timestamp without time zone,
    job_enabled integer,
    notify_email_operator_id integer,
    notify_level_email integer,
    categoryname character varying(255),
    sched_enabled character varying(255),
    next_run_date character varying(255),
    next_run_time character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.info_job OWNER TO postgres;

--
-- Name: info_job_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.info_job_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.info_job_id_seq OWNER TO postgres;

--
-- Name: info_job_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.info_job_id_seq OWNED BY mssql.info_job.id;


--
-- Name: info_service_install; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.info_service_install (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    servicename character varying(255),
    process_id integer,
    startup_type_desc character varying(255),
    status_desc character varying(255),
    last_startup_time character varying(255),
    service_account character varying(255),
    is_clustered character varying(255),
    cluster_nodename character varying(255),
    filename text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.info_service_install OWNER TO postgres;

--
-- Name: info_service_install_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.info_service_install_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.info_service_install_id_seq OWNER TO postgres;

--
-- Name: info_service_install_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.info_service_install_id_seq OWNED BY mssql.info_service_install.id;


--
-- Name: instance_properties; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.instance_properties (
    id bigint NOT NULL,
    ip_server character varying(255),
    port integer,
    version_ character varying(255),
    os_version character varying(255),
    machinename character varying(255),
    servername character varying(255),
    instance character varying(255),
    collation_ character varying(255),
    isclustered integer,
    computernamephysicalnetbios character varying(255),
    edition character varying(255),
    productlevel character varying(255),
    productupdatelevel character varying(255),
    productversion character varying(255),
    productmajorversion integer,
    productminorversion integer,
    productbuild integer,
    productbuildtype character varying(255),
    productupdatereference character varying(255),
    processid integer,
    isfulltextinstalled integer,
    isintegratedsecurityonly integer,
    filestreamconfiguredlevel integer,
    ishadrenabled integer,
    hadrmanagerstatus integer,
    instancedefaultdatapath character varying(255),
    instancedefaultlogpath character varying(255),
    instancedefaultbackuppath character varying(255),
    build_clr_version character varying(255),
    isxtpsupported integer,
    ispolybaseinstalled integer,
    isrservicesinstalled integer,
    resourcelastupdatedatetime timestamp without time zone,
    cluster_big_data integer,
    sql_express integer,
    issingleuser integer,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.instance_properties OWNER TO postgres;

--
-- Name: instance_properties2_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.instance_properties2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.instance_properties2_id_seq OWNER TO postgres;

--
-- Name: instance_properties2_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.instance_properties2_id_seq OWNED BY mssql.instance_properties.id;


--
-- Name: logins; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.logins (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    login_ character varying(255),
    setting text,
    rols text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.logins OWNER TO postgres;

--
-- Name: logins_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.logins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.logins_id_seq OWNER TO postgres;

--
-- Name: logins_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.logins_id_seq OWNED BY mssql.logins.id;


--
-- Name: master_files; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.master_files (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    name_db character varying(255),
    owner character varying(255),
    name_file character varying(255),
    size_file_mb numeric(20,2),
    growth_mb numeric(20,2),
    maxsize character varying(20),
    space_used_mb numeric(20,2),
    percentage_space_used numeric(20,2),
    available_space_mb numeric(20,2),
    percentage_available_space numeric(20,2),
    physical_route character varying(500),
    disk_drive character varying(1),
    type_file character varying(3),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.master_files OWNER TO postgres;

--
-- Name: master_files_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.master_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.master_files_id_seq OWNER TO postgres;

--
-- Name: master_files_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.master_files_id_seq OWNED BY mssql.master_files.id;


--
-- Name: parameters_conf; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.parameters_conf (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    name character varying(255),
    value integer,
    value_in_use integer,
    minimum integer,
    maximum integer,
    description character varying(255),
    is_dynamic integer,
    is_advanced integer,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.parameters_conf OWNER TO postgres;

--
-- Name: parameters_conf_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.parameters_conf_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.parameters_conf_id_seq OWNER TO postgres;

--
-- Name: parameters_conf_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.parameters_conf_id_seq OWNED BY mssql.parameters_conf.id;


--
-- Name: privileges_admin; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.privileges_admin (
    id integer NOT NULL,
    ip_server character varying(20),
    port integer,
    db character varying(255),
    class_desc character varying(255),
    type_grantee character varying(255),
    grantee character varying(255),
    grantee_is_disabled integer,
    orphaned_users integer,
    grantor character varying(255),
    permission_name character varying(255),
    state_desc character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.privileges_admin OWNER TO postgres;

--
-- Name: privileges_admin_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.privileges_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.privileges_admin_id_seq OWNER TO postgres;

--
-- Name: privileges_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.privileges_admin_id_seq OWNED BY mssql.privileges_admin.id;


--
-- Name: privileges_gran; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.privileges_gran (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    class_desc character varying(255),
    object_name_ character varying(255),
    type_user character varying(255),
    grantor character varying(255),
    grantee character varying(255),
    grantee_is_disabled character varying(255),
    orphaned_users character varying(255),
    type character varying(255),
    permission_name_ character varying(255),
    state character varying(255),
    state_desc character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.privileges_gran OWNER TO postgres;

--
-- Name: privileges_gran_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.privileges_gran_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.privileges_gran_id_seq OWNER TO postgres;

--
-- Name: privileges_gran_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.privileges_gran_id_seq OWNED BY mssql.privileges_gran.id;


--
-- Name: privileges_roles; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.privileges_roles (
    id integer NOT NULL,
    ip_server character varying(20),
    port integer,
    db character varying(255),
    type_role character varying(255),
    role_predefined integer,
    rolname character varying(255),
    username character varying(255),
    username_is_disabled integer,
    orphaned_users integer,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.privileges_roles OWNER TO postgres;

--
-- Name: privileges_roles_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.privileges_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.privileges_roles_id_seq OWNER TO postgres;

--
-- Name: privileges_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.privileges_roles_id_seq OWNED BY mssql.privileges_roles.id;


--
-- Name: schemas; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.schemas (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    type_obj character varying(255),
    name character varying(255),
    owner character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.schemas OWNER TO postgres;

--
-- Name: schemas_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.schemas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.schemas_id_seq OWNER TO postgres;

--
-- Name: schemas_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.schemas_id_seq OWNED BY mssql.schemas.id;


--
-- Name: sequences; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.sequences (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    schema_name character varying(255),
    name_sequence character varying(255),
    owner character varying(255),
    start_value integer,
    increment integer,
    current_value integer,
    create_date timestamp without time zone,
    modify_date timestamp without time zone,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.sequences OWNER TO postgres;

--
-- Name: sequences_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.sequences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.sequences_id_seq OWNER TO postgres;

--
-- Name: sequences_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.sequences_id_seq OWNED BY mssql.sequences.id;


--
-- Name: sizes_disks; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.sizes_disks (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    disco character varying(2),
    porcentaje_usado numeric(20,2),
    total_gb integer,
    usado_gb integer,
    disponible_gb integer,
    porcentaje_disponible numeric(20,2),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.sizes_disks OWNER TO postgres;

--
-- Name: sizes_disks_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.sizes_disks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.sizes_disks_id_seq OWNER TO postgres;

--
-- Name: sizes_disks_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.sizes_disks_id_seq OWNED BY mssql.sizes_disks.id;


--
-- Name: tables_columns; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.tables_columns (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    schema_name character varying(255),
    table_name character varying(255),
    create_date timestamp without time zone,
    modify_date timestamp without time zone,
    owner character varying(255),
    column_name character varying(255),
    data_type character varying(255),
    max_length integer,
    "precision" integer,
    scale integer,
    is_nullable integer,
    is_identity integer,
    is_foreign_key integer,
    referenced_schema character varying(255),
    referenced_table character varying(255),
    referenced_column character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.tables_columns OWNER TO postgres;

--
-- Name: tables_columns_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.tables_columns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.tables_columns_id_seq OWNER TO postgres;

--
-- Name: tables_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.tables_columns_id_seq OWNED BY mssql.tables_columns.id;


--
-- Name: triggers; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.triggers (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    schema_name character varying(255),
    object_name character varying(255),
    owner character varying(255),
    md5 character varying(255),
    type character varying(255),
    create_date timestamp without time zone,
    modify_date timestamp without time zone,
    is_disabled integer,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.triggers OWNER TO postgres;

--
-- Name: triggers_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.triggers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.triggers_id_seq OWNER TO postgres;

--
-- Name: triggers_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.triggers_id_seq OWNED BY mssql.triggers.id;


--
-- Name: users; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.users (
    id integer NOT NULL,
    ip_server character varying(20),
    port integer,
    name character varying(255),
    type_desc character varying(255),
    is_disabled integer,
    sid bytea,
    create_date timestamp without time zone,
    modify_date timestamp without time zone,
    default_db character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.users_id_seq OWNED BY mssql.users.id;


--
-- Name: views; Type: TABLE; Schema: mssql; Owner: postgres
--

CREATE TABLE mssql.views (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    name character varying(255),
    owner character varying(255),
    md5 character varying(255),
    create_date timestamp without time zone,
    modify_date timestamp without time zone,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE mssql.views OWNER TO postgres;

--
-- Name: views_id_seq; Type: SEQUENCE; Schema: mssql; Owner: postgres
--

CREATE SEQUENCE mssql.views_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE mssql.views_id_seq OWNER TO postgres;

--
-- Name: views_id_seq; Type: SEQUENCE OWNED BY; Schema: mssql; Owner: postgres
--

ALTER SEQUENCE mssql.views_id_seq OWNED BY mssql.views.id;


--
-- Name: dbs; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.dbs (
    id integer NOT NULL,
    ip_server character varying(50),
    port integer,
    name character varying(255),
    owner character varying(255),
    encoding character varying(255),
    collate_ character varying(255),
    ctype character varying(255),
    size integer,
    unit_size character varying(100),
    create_date timestamp without time zone,
    description character varying(500),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.dbs OWNER TO postgres;

--
-- Name: dbs_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.dbs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.dbs_id_seq OWNER TO postgres;

--
-- Name: dbs_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.dbs_id_seq OWNED BY psql.dbs.id;


--
-- Name: files_data_conf; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.files_data_conf (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    md5_postgresql_conf character varying(50),
    md5_pg_hba_conf character varying(50),
    md5_pg_ident_conf character varying(50),
    md5_crontab character varying(50),
    postgresql_conf text,
    pg_hba_conf text,
    pg_ident_conf text,
    crontab text,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.files_data_conf OWNER TO postgres;

--
-- Name: files_data_conf_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.files_data_conf_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.files_data_conf_id_seq OWNER TO postgres;

--
-- Name: files_data_conf_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.files_data_conf_id_seq OWNED BY psql.files_data_conf.id;


--
-- Name: funproc; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.funproc (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    schema character varying(255),
    name character varying(255),
    result_data_type text,
    argument_data_types text,
    type character varying(255),
    volatility character varying(255),
    parallel character varying(255),
    owner character varying(255),
    security character varying(255),
    language character varying(255),
    description character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.funproc OWNER TO postgres;

--
-- Name: funproc_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.funproc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.funproc_id_seq OWNER TO postgres;

--
-- Name: funproc_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.funproc_id_seq OWNED BY psql.funproc.id;


--
-- Name: index_columns; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.index_columns (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    db character varying(255),
    schema_name character varying(255),
    table_name character varying(255),
    index_name character varying(255),
    index_type character varying(255),
    column_names character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.index_columns OWNER TO postgres;

--
-- Name: index_columns_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.index_columns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.index_columns_id_seq OWNER TO postgres;

--
-- Name: index_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.index_columns_id_seq OWNED BY psql.index_columns.id;


--
-- Name: indexs; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.indexs (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    db character varying(255),
    schema character varying(100),
    index_name character varying(255),
    type character varying(100),
    owner character varying(100),
    table_name character varying(100),
    access_method character varying(100),
    size integer,
    unit_size character varying(255),
    create_date timestamp without time zone,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.indexs OWNER TO postgres;

--
-- Name: indexs_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.indexs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.indexs_id_seq OWNER TO postgres;

--
-- Name: indexs_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.indexs_id_seq OWNED BY psql.indexs.id;


--
-- Name: info_hardware; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.info_hardware (
    id integer NOT NULL,
    ip_server character varying(50),
    port integer,
    hostname character varying(255),
    model_so character varying(255),
    architecture character varying(25),
    mem_ram_kb integer,
    model_cpu character varying(255),
    cnt_cpu_physical integer,
    cnt_cpu_logical integer,
    cnt_core integer,
    cache_size_kb integer,
    uptime character varying(255),
    time_zone character varying(255),
    local_time character varying(255),
    ntp_service character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.info_hardware OWNER TO postgres;

--
-- Name: info_hardware_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.info_hardware_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.info_hardware_id_seq OWNER TO postgres;

--
-- Name: info_hardware_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.info_hardware_id_seq OWNED BY psql.info_hardware.id;


--
-- Name: instance_properties; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.instance_properties (
    id bigint NOT NULL,
    ip_server character varying(100),
    port integer,
    dbms character varying(255),
    version character varying(255),
    architecture_sql character varying(255),
    data_directory character varying(255),
    postgresql_conf_directory character varying(255),
    hba_file_directory character varying(255),
    ident_file_directory character varying(255),
    log_directory character varying(255),
    binary_directory text,
    status_systemctl text,
    uptime_psql timestamp without time zone,
    last_time_reload timestamp without time zone,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.instance_properties OWNER TO postgres;

--
-- Name: instance_properties_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.instance_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.instance_properties_id_seq OWNER TO postgres;

--
-- Name: instance_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.instance_properties_id_seq OWNED BY psql.instance_properties.id;


--
-- Name: mi_secuencia; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.mi_secuencia
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.mi_secuencia OWNER TO postgres;

--
-- Name: pg_hba; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.pg_hba (
    id integer NOT NULL,
    ip_server character varying(50),
    port integer,
    line_number integer,
    type text,
    database text[],
    user_name text[],
    address text,
    netmask text,
    auth_method text,
    options text[],
    error text,
    last_time_reload timestamp without time zone,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.pg_hba OWNER TO postgres;

--
-- Name: pg_hba_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.pg_hba_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.pg_hba_id_seq OWNER TO postgres;

--
-- Name: pg_hba_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.pg_hba_id_seq OWNED BY psql.pg_hba.id;


--
-- Name: pg_settings; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.pg_settings (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    name character varying(255),
    setting character varying(255),
    category character varying(255),
    sourcefile character varying(255),
    sourceline character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.pg_settings OWNER TO postgres;

--
-- Name: pg_settings_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.pg_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.pg_settings_id_seq OWNER TO postgres;

--
-- Name: pg_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.pg_settings_id_seq OWNED BY psql.pg_settings.id;


--
-- Name: postgresql_conf; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.postgresql_conf (
    id bigint NOT NULL,
    ip_server character varying(50),
    port integer,
    sourcefile text,
    sourceline integer,
    seqno integer,
    name text,
    setting text,
    applied boolean,
    error text,
    uptime_psql timestamp without time zone,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.postgresql_conf OWNER TO postgres;

--
-- Name: postgresql_conf2_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.postgresql_conf2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.postgresql_conf2_id_seq OWNER TO postgres;

--
-- Name: postgresql_conf2_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.postgresql_conf2_id_seq OWNED BY psql.postgresql_conf.id;


--
-- Name: privileges_gran; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.privileges_gran (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    grantor character varying(255),
    grantee character varying(255),
    type character varying(255),
    schema_name character varying(255),
    object_name character varying(255),
    privilege_type character varying(255),
    is_grantable character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.privileges_gran OWNER TO postgres;

--
-- Name: privileges_gran_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.privileges_gran_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.privileges_gran_id_seq OWNER TO postgres;

--
-- Name: privileges_gran_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.privileges_gran_id_seq OWNED BY psql.privileges_gran.id;


--
-- Name: schemas; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.schemas (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    name character varying(100),
    owner character varying(100),
    description character varying(500),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.schemas OWNER TO postgres;

--
-- Name: schemas_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.schemas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.schemas_id_seq OWNER TO postgres;

--
-- Name: schemas_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.schemas_id_seq OWNED BY psql.schemas.id;


--
-- Name: sequences; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.sequences (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    db character varying(255),
    sequence_schema character varying(255),
    sequence_name character varying(255),
    data_type character varying(255),
    numeric_precision bigint,
    numeric_precision_radix bigint,
    numeric_scale bigint,
    minimum_value bigint,
    maximum_value bigint,
    increment bigint,
    cycle_option character varying(100),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.sequences OWNER TO postgres;

--
-- Name: sequences_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.sequences_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.sequences_id_seq OWNER TO postgres;

--
-- Name: sequences_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.sequences_id_seq OWNED BY psql.sequences.id;


--
-- Name: sizes_disks; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.sizes_disks (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    size integer,
    used integer,
    avail integer,
    use_percentage integer,
    disk_name character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.sizes_disks OWNER TO postgres;

--
-- Name: sizes_disks_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.sizes_disks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.sizes_disks_id_seq OWNER TO postgres;

--
-- Name: sizes_disks_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.sizes_disks_id_seq OWNED BY psql.sizes_disks.id;


--
-- Name: tables_columns; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.tables_columns (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    db character varying(255),
    table_schema character varying(255),
    table_name character varying(255),
    column_name character varying(255),
    ordinal_position integer,
    secuence character varying(255),
    is_nullable boolean,
    data_type character varying(255),
    udt_name character varying(255),
    character_maximum_length bigint,
    numeric_precision bigint,
    numeric_scale bigint,
    column_default character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.tables_columns OWNER TO postgres;

--
-- Name: table_columns_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.table_columns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.table_columns_id_seq OWNER TO postgres;

--
-- Name: table_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.table_columns_id_seq OWNED BY psql.tables_columns.id;


--
-- Name: table_constraint; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.table_constraint (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    db character varying(255),
    table_schema character varying(255),
    table_name character varying(255),
    column_name character varying(255),
    foreign_key_name character varying(255),
    primary_key_name character varying(255),
    unique_name character varying(255),
    check_name character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.table_constraint OWNER TO postgres;

--
-- Name: table_constraint_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.table_constraint_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.table_constraint_id_seq OWNER TO postgres;

--
-- Name: table_constraint_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.table_constraint_id_seq OWNED BY psql.table_constraint.id;


--
-- Name: table_foreign; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.table_foreign (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    db character varying(255),
    table_schema character varying(255),
    table_name character varying(255),
    column_name character varying(255),
    foreign_table_schema character varying(255),
    foreign_table_name character varying(255),
    foreign_column_name character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.table_foreign OWNER TO postgres;

--
-- Name: table_fereign_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.table_fereign_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.table_fereign_id_seq OWNER TO postgres;

--
-- Name: table_fereign_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.table_fereign_id_seq OWNED BY psql.table_foreign.id;


--
-- Name: tables; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.tables (
    id integer NOT NULL,
    ip_server character varying(255),
    port integer,
    db character varying(255),
    schema character varying(255),
    table_name character varying(255),
    type character varying(255),
    owner character varying(255),
    persistence character varying(255),
    access_method character varying(255),
    size integer,
    unit_size character varying(100),
    create_date timestamp without time zone,
    description character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.tables OWNER TO postgres;

--
-- Name: tables_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.tables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.tables_id_seq OWNER TO postgres;

--
-- Name: tables_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.tables_id_seq OWNED BY psql.tables.id;


--
-- Name: triggers; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.triggers (
    id integer NOT NULL,
    ip_server character varying(100),
    port integer,
    db character varying(255),
    trigger_schema character varying(255),
    trigger_name character varying(255),
    owner character varying(255),
    event_object_schema character varying(255),
    event_object_table character varying(255),
    event_manipulation character varying(255),
    action_order character varying(255),
    action_orientation character varying(255),
    action_timing character varying(255),
    action_statement character varying(255),
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.triggers OWNER TO postgres;

--
-- Name: triggers_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.triggers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.triggers_id_seq OWNER TO postgres;

--
-- Name: triggers_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.triggers_id_seq OWNED BY psql.triggers.id;


--
-- Name: users; Type: TABLE; Schema: psql; Owner: postgres
--

CREATE TABLE psql.users (
    id integer NOT NULL,
    ip_server character varying(50),
    port integer,
    rolname name,
    rolsuper boolean,
    rolinherit boolean,
    rolcreaterole boolean,
    rolcreatedb boolean,
    rolcanlogin boolean,
    rolconnlimit integer,
    rolpassword text,
    rolvaliduntil timestamp without time zone,
    date_insert timestamp without time zone DEFAULT (now())::timestamp without time zone,
    id_exec integer
);


ALTER TABLE psql.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: psql; Owner: postgres
--

CREATE SEQUENCE psql.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE psql.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: psql; Owner: postgres
--

ALTER SEQUENCE psql.users_id_seq OWNED BY psql.users.id;


--
-- Name: cat_inv_atencion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_inv_atencion (
    pais character varying,
    ambiente character varying,
    ip character varying,
    bd character varying,
    manejador character varying,
    version_manejador character varying,
    "edición" character varying,
    memoria character varying,
    procesador character varying,
    model character varying,
    centro character varying,
    dueno character varying,
    servicio character varying,
    id_exec integer
);


ALTER TABLE public.cat_inv_atencion OWNER TO postgres;

--
-- Name: cat_server; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_server (
    id integer NOT NULL,
    ip_server character varying(50) NOT NULL,
    port integer NOT NULL,
    dbms character varying(255) NOT NULL,
    centro character varying(255),
    version character varying(255),
    autorizador character varying(255),
    pais character varying(255),
    so character varying(255),
    ambiente character varying(255),
    id_remote_user integer,
    servicio character varying(255)
);


ALTER TABLE public.cat_server OWNER TO postgres;

--
-- Name: cat_zona_cafe_arg; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_zona_cafe_arg (
    prioridad_negocio character varying,
    servicio_macro character varying,
    servicio_de_negocio character varying,
    "servicio_fábrica" character varying,
    estrategia character varying,
    ip_origen character varying,
    ip_original__rojo_ character varying,
    hostname_origen character varying,
    hostname_nuevo character varying,
    tipo_de_servidor character varying,
    so__windows___linux_ character varying,
    "servidor_físico___virtual" character varying,
    servidores_cancelados character varying,
    _tiene_respaldo_ character varying,
    "tipo_de_recuperación" character varying,
    "dueño_de_servicio_sistemas" character varying,
    "_está_encriptado___san_" character varying,
    "instalación_de_agentes_de_seguridad__sin_instalar_nessus_" character varying,
    cambio_de_ip_y_registro_de_nueva_ip character varying,
    registrar_nueva_ip_y_hostname_1 character varying,
    registrar_nueva_ip_y_hostname__de_zona_amarilla_ character varying,
    registrar_nueva_ip_y_hostname character varying,
    "registrar_nueva_ip_y_hostname_microsegmentación_por_servicio_" character varying,
    segmento character varying,
    "instalación_y_alta_de_agentes_de_commvault" character varying,
    estado_actual_de_la_zona character varying,
    "notas_de_última_actualización" character varying,
    id_exec integer
);


ALTER TABLE public.cat_zona_cafe_arg OWNER TO postgres;

--
-- Name: cat_zona_cafe_mx; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cat_zona_cafe_mx (
    id integer NOT NULL,
    empresa character varying,
    "Área_de_negocio" character varying,
    servicio_de_negocio character varying,
    servicio_de_fabrica character varying,
    "dueño_de_servicio_sistemas" character varying,
    champion_de_seguridad character varying,
    nacional_responsable character varying,
    divisional_asignado character varying,
    ip_original character varying,
    ip_cuarentena character varying,
    ip_naranja character varying,
    ip_amarilla character varying,
    "ip_café" character varying,
    hostname_origen character varying,
    hostname_nuevo character varying,
    so_windows_linux character varying,
    tipo_de_servidor character varying,
    "tipo_de_recuperación" character varying,
    "validación_de_servidores_limpios_o_en_remediación" character varying,
    encriptado character varying,
    zona_actual character varying,
    control_1 character varying,
    control_2 character varying,
    control_3 character varying,
    status_2 character varying,
    id_exec integer
);


ALTER TABLE public.cat_zona_cafe_mx OWNER TO postgres;

--
-- Name: cat_zona_cafe_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cat_zona_cafe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cat_zona_cafe_id_seq OWNER TO postgres;

--
-- Name: cat_zona_cafe_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cat_zona_cafe_id_seq OWNED BY public.cat_zona_cafe_mx.id;


--
-- Name: ctl_server_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ctl_server_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ctl_server_id_seq OWNER TO postgres;

--
-- Name: ctl_server_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ctl_server_id_seq OWNED BY public.cat_server.id;


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedidos (
    id integer NOT NULL,
    cliente_id integer,
    producto_id integer,
    cantidad integer,
    precio numeric,
    fecha timestamp without time zone,
    estado character varying(20),
    email character varying(100),
    nombre character varying(100)
);


ALTER TABLE public.pedidos OWNER TO postgres;

--
-- Name: pedidos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pedidos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedidos_id_seq OWNER TO postgres;

--
-- Name: pedidos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pedidos_id_seq OWNED BY public.pedidos.id;


--
-- Name: cat_server id; Type: DEFAULT; Schema: cdc; Owner: postgres
--

ALTER TABLE ONLY cdc.cat_server ALTER COLUMN id SET DEFAULT nextval('cdc.cat_server_id_seq'::regclass);


--
-- Name: blacklist_server id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.blacklist_server ALTER COLUMN id SET DEFAULT nextval('fdw_conf.blacklist_server_id_seq'::regclass);


--
-- Name: cat_category_querys id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_category_querys ALTER COLUMN id SET DEFAULT nextval('fdw_conf.cat_category_querys_id_seq'::regclass);


--
-- Name: cat_dbs id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_dbs ALTER COLUMN id SET DEFAULT nextval('fdw_conf.cat_dbs_id_seq'::regclass);


--
-- Name: cat_lvl_exec_querys id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_lvl_exec_querys ALTER COLUMN id SET DEFAULT nextval('fdw_conf.cat_lvl_exec_querys_id_seq'::regclass);


--
-- Name: cat_version_mssql_oficial id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_version_mssql_oficial ALTER COLUMN id SET DEFAULT nextval('fdw_conf.cat_version_mssql_oficial_id_seq'::regclass);


--
-- Name: cat_versions id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_versions ALTER COLUMN id SET DEFAULT nextval('fdw_conf.cat_versions_id_seq'::regclass);


--
-- Name: ctl_dbms id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_dbms ALTER COLUMN id SET DEFAULT nextval('fdw_conf.cat_dbms_id_seq1'::regclass);


--
-- Name: ctl_ports id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_ports ALTER COLUMN id SET DEFAULT nextval('fdw_conf.cat_dbms_id_seq'::regclass);


--
-- Name: ctl_querys id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_querys ALTER COLUMN id SET DEFAULT nextval('fdw_conf.ctl_querys2_id_seq'::regclass);


--
-- Name: ctl_remote_users id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_remote_users ALTER COLUMN id SET DEFAULT nextval('fdw_conf.cat_remote_user_id_seq'::regclass);


--
-- Name: details_connection id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.details_connection ALTER COLUMN id SET DEFAULT nextval('fdw_conf.details_connection_id_seq'::regclass);


--
-- Name: funs_tanks id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.funs_tanks ALTER COLUMN id SET DEFAULT nextval('fdw_conf.funs_tanks_id_seq'::regclass);


--
-- Name: log_exec_failed_query id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.log_exec_failed_query ALTER COLUMN id SET DEFAULT nextval('fdw_conf.log_exec_failed_query_id_seq'::regclass);


--
-- Name: log_msg_error id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.log_msg_error ALTER COLUMN id SET DEFAULT nextval('fdw_conf.log_msg_error_id_seq'::regclass);


--
-- Name: report_connection id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.report_connection ALTER COLUMN id SET DEFAULT nextval('fdw_conf.report_connection_id_seq'::regclass);


--
-- Name: scan_rules_query id; Type: DEFAULT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.scan_rules_query ALTER COLUMN id SET DEFAULT nextval('fdw_conf.scan_rules_query_id_seq'::regclass);


--
-- Name: dbs id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.dbs ALTER COLUMN id SET DEFAULT nextval('mssql.dbs_id_seq'::regclass);


--
-- Name: funproc id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.funproc ALTER COLUMN id SET DEFAULT nextval('mssql.funproc_id_seq'::regclass);


--
-- Name: info_backup id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.info_backup ALTER COLUMN id SET DEFAULT nextval('mssql.info_backup_id_seq'::regclass);


--
-- Name: info_hardware id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.info_hardware ALTER COLUMN id SET DEFAULT nextval('mssql.info_hardware_id_seq'::regclass);


--
-- Name: info_job id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.info_job ALTER COLUMN id SET DEFAULT nextval('mssql.info_job_id_seq'::regclass);


--
-- Name: info_service_install id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.info_service_install ALTER COLUMN id SET DEFAULT nextval('mssql.info_service_install_id_seq'::regclass);


--
-- Name: instance_properties id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.instance_properties ALTER COLUMN id SET DEFAULT nextval('mssql.instance_properties2_id_seq'::regclass);


--
-- Name: logins id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.logins ALTER COLUMN id SET DEFAULT nextval('mssql.logins_id_seq'::regclass);


--
-- Name: master_files id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.master_files ALTER COLUMN id SET DEFAULT nextval('mssql.master_files_id_seq'::regclass);


--
-- Name: parameters_conf id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.parameters_conf ALTER COLUMN id SET DEFAULT nextval('mssql.parameters_conf_id_seq'::regclass);


--
-- Name: privileges_admin id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.privileges_admin ALTER COLUMN id SET DEFAULT nextval('mssql.privileges_admin_id_seq'::regclass);


--
-- Name: privileges_gran id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.privileges_gran ALTER COLUMN id SET DEFAULT nextval('mssql.privileges_gran_id_seq'::regclass);


--
-- Name: privileges_roles id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.privileges_roles ALTER COLUMN id SET DEFAULT nextval('mssql.privileges_roles_id_seq'::regclass);


--
-- Name: schemas id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.schemas ALTER COLUMN id SET DEFAULT nextval('mssql.schemas_id_seq'::regclass);


--
-- Name: sequences id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.sequences ALTER COLUMN id SET DEFAULT nextval('mssql.sequences_id_seq'::regclass);


--
-- Name: sizes_disks id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.sizes_disks ALTER COLUMN id SET DEFAULT nextval('mssql.sizes_disks_id_seq'::regclass);


--
-- Name: tables_columns id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.tables_columns ALTER COLUMN id SET DEFAULT nextval('mssql.tables_columns_id_seq'::regclass);


--
-- Name: triggers id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.triggers ALTER COLUMN id SET DEFAULT nextval('mssql.triggers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.users ALTER COLUMN id SET DEFAULT nextval('mssql.users_id_seq'::regclass);


--
-- Name: views id; Type: DEFAULT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.views ALTER COLUMN id SET DEFAULT nextval('mssql.views_id_seq'::regclass);


--
-- Name: dbs id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.dbs ALTER COLUMN id SET DEFAULT nextval('psql.dbs_id_seq'::regclass);


--
-- Name: files_data_conf id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.files_data_conf ALTER COLUMN id SET DEFAULT nextval('psql.files_data_conf_id_seq'::regclass);


--
-- Name: funproc id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.funproc ALTER COLUMN id SET DEFAULT nextval('psql.funproc_id_seq'::regclass);


--
-- Name: index_columns id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.index_columns ALTER COLUMN id SET DEFAULT nextval('psql.index_columns_id_seq'::regclass);


--
-- Name: indexs id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.indexs ALTER COLUMN id SET DEFAULT nextval('psql.indexs_id_seq'::regclass);


--
-- Name: info_hardware id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.info_hardware ALTER COLUMN id SET DEFAULT nextval('psql.info_hardware_id_seq'::regclass);


--
-- Name: instance_properties id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.instance_properties ALTER COLUMN id SET DEFAULT nextval('psql.instance_properties_id_seq'::regclass);


--
-- Name: pg_hba id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.pg_hba ALTER COLUMN id SET DEFAULT nextval('psql.pg_hba_id_seq'::regclass);


--
-- Name: pg_settings id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.pg_settings ALTER COLUMN id SET DEFAULT nextval('psql.pg_settings_id_seq'::regclass);


--
-- Name: postgresql_conf id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.postgresql_conf ALTER COLUMN id SET DEFAULT nextval('psql.postgresql_conf2_id_seq'::regclass);


--
-- Name: privileges_gran id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.privileges_gran ALTER COLUMN id SET DEFAULT nextval('psql.privileges_gran_id_seq'::regclass);


--
-- Name: schemas id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.schemas ALTER COLUMN id SET DEFAULT nextval('psql.schemas_id_seq'::regclass);


--
-- Name: sequences id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.sequences ALTER COLUMN id SET DEFAULT nextval('psql.sequences_id_seq'::regclass);


--
-- Name: sizes_disks id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.sizes_disks ALTER COLUMN id SET DEFAULT nextval('psql.sizes_disks_id_seq'::regclass);


--
-- Name: table_constraint id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.table_constraint ALTER COLUMN id SET DEFAULT nextval('psql.table_constraint_id_seq'::regclass);


--
-- Name: table_foreign id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.table_foreign ALTER COLUMN id SET DEFAULT nextval('psql.table_fereign_id_seq'::regclass);


--
-- Name: tables id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.tables ALTER COLUMN id SET DEFAULT nextval('psql.tables_id_seq'::regclass);


--
-- Name: tables_columns id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.tables_columns ALTER COLUMN id SET DEFAULT nextval('psql.table_columns_id_seq'::regclass);


--
-- Name: triggers id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.triggers ALTER COLUMN id SET DEFAULT nextval('psql.triggers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.users ALTER COLUMN id SET DEFAULT nextval('psql.users_id_seq'::regclass);


--
-- Name: cat_server id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_server ALTER COLUMN id SET DEFAULT nextval('public.ctl_server_id_seq'::regclass);


--
-- Name: cat_zona_cafe_mx id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_zona_cafe_mx ALTER COLUMN id SET DEFAULT nextval('public.cat_zona_cafe_id_seq'::regclass);


--
-- Name: pedidos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN id SET DEFAULT nextval('public.pedidos_id_seq'::regclass);


--
-- Name: cat_server cat_server_pkey; Type: CONSTRAINT; Schema: cdc; Owner: postgres
--

ALTER TABLE ONLY cdc.cat_server
    ADD CONSTRAINT cat_server_pkey PRIMARY KEY (id);


--
-- Name: blacklist_server blacklist_server_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.blacklist_server
    ADD CONSTRAINT blacklist_server_pkey PRIMARY KEY (id);


--
-- Name: cat_category_querys cat_category_querys_category_key; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_category_querys
    ADD CONSTRAINT cat_category_querys_category_key UNIQUE (category);


--
-- Name: cat_category_querys cat_category_querys_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_category_querys
    ADD CONSTRAINT cat_category_querys_pkey PRIMARY KEY (id);


--
-- Name: ctl_ports cat_dbms_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_ports
    ADD CONSTRAINT cat_dbms_pkey PRIMARY KEY (id);


--
-- Name: ctl_dbms cat_dbms_pkey1; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_dbms
    ADD CONSTRAINT cat_dbms_pkey1 PRIMARY KEY (id);


--
-- Name: cat_dbs cat_dbs_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_dbs
    ADD CONSTRAINT cat_dbs_pkey PRIMARY KEY (id);


--
-- Name: cat_lvl_exec_querys cat_lvl_exec_querys_level_key; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_lvl_exec_querys
    ADD CONSTRAINT cat_lvl_exec_querys_level_key UNIQUE (level);


--
-- Name: cat_lvl_exec_querys cat_lvl_exec_querys_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_lvl_exec_querys
    ADD CONSTRAINT cat_lvl_exec_querys_pkey PRIMARY KEY (id);


--
-- Name: ctl_remote_users cat_remote_user_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_remote_users
    ADD CONSTRAINT cat_remote_user_pkey PRIMARY KEY (id);


--
-- Name: cat_version_mssql_oficial cat_version_mssql_oficial_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_version_mssql_oficial
    ADD CONSTRAINT cat_version_mssql_oficial_pkey PRIMARY KEY (id);


--
-- Name: cat_versions cat_versions_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.cat_versions
    ADD CONSTRAINT cat_versions_pkey PRIMARY KEY (id);


--
-- Name: ctl_querys ctl_querys2_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_querys
    ADD CONSTRAINT ctl_querys2_pkey PRIMARY KEY (id);


--
-- Name: details_connection details_connection_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.details_connection
    ADD CONSTRAINT details_connection_pkey PRIMARY KEY (id);


--
-- Name: funs_tanks funs_tanks_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.funs_tanks
    ADD CONSTRAINT funs_tanks_pkey PRIMARY KEY (id);


--
-- Name: ctl_dbms idx_unique_ctl_dbms; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_dbms
    ADD CONSTRAINT idx_unique_ctl_dbms UNIQUE (dbms);


--
-- Name: log_exec_failed_query log_exec_failed_query_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.log_exec_failed_query
    ADD CONSTRAINT log_exec_failed_query_pkey PRIMARY KEY (id);


--
-- Name: log_msg_error log_msg_error_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.log_msg_error
    ADD CONSTRAINT log_msg_error_pkey PRIMARY KEY (id);


--
-- Name: report_connection report_connection_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.report_connection
    ADD CONSTRAINT report_connection_pkey PRIMARY KEY (id);


--
-- Name: scan_rules_query scan_rules_query_pkey; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.scan_rules_query
    ADD CONSTRAINT scan_rules_query_pkey PRIMARY KEY (id);


--
-- Name: funs_tanks unique_fun_name; Type: CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.funs_tanks
    ADD CONSTRAINT unique_fun_name UNIQUE (fun_name);


--
-- Name: dbs dbs_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.dbs
    ADD CONSTRAINT dbs_pkey PRIMARY KEY (id);


--
-- Name: funproc funproc_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.funproc
    ADD CONSTRAINT funproc_pkey PRIMARY KEY (id);


--
-- Name: info_backup info_backup_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.info_backup
    ADD CONSTRAINT info_backup_pkey PRIMARY KEY (id);


--
-- Name: info_hardware info_hardware_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.info_hardware
    ADD CONSTRAINT info_hardware_pkey PRIMARY KEY (id);


--
-- Name: info_job info_job_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.info_job
    ADD CONSTRAINT info_job_pkey PRIMARY KEY (id);


--
-- Name: info_service_install info_service_install_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.info_service_install
    ADD CONSTRAINT info_service_install_pkey PRIMARY KEY (id);


--
-- Name: instance_properties instance_properties2_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.instance_properties
    ADD CONSTRAINT instance_properties2_pkey PRIMARY KEY (id);


--
-- Name: logins logins_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.logins
    ADD CONSTRAINT logins_pkey PRIMARY KEY (id);


--
-- Name: master_files master_files_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.master_files
    ADD CONSTRAINT master_files_pkey PRIMARY KEY (id);


--
-- Name: parameters_conf parameters_conf_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.parameters_conf
    ADD CONSTRAINT parameters_conf_pkey PRIMARY KEY (id);


--
-- Name: privileges_admin privileges_admin_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.privileges_admin
    ADD CONSTRAINT privileges_admin_pkey PRIMARY KEY (id);


--
-- Name: privileges_gran privileges_gran_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.privileges_gran
    ADD CONSTRAINT privileges_gran_pkey PRIMARY KEY (id);


--
-- Name: privileges_roles privileges_roles_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.privileges_roles
    ADD CONSTRAINT privileges_roles_pkey PRIMARY KEY (id);


--
-- Name: schemas schemas_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.schemas
    ADD CONSTRAINT schemas_pkey PRIMARY KEY (id);


--
-- Name: sequences sequences_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.sequences
    ADD CONSTRAINT sequences_pkey PRIMARY KEY (id);


--
-- Name: sizes_disks sizes_disks_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.sizes_disks
    ADD CONSTRAINT sizes_disks_pkey PRIMARY KEY (id);


--
-- Name: tables_columns tables_columns_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.tables_columns
    ADD CONSTRAINT tables_columns_pkey PRIMARY KEY (id);


--
-- Name: triggers triggers_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.triggers
    ADD CONSTRAINT triggers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: views views_pkey; Type: CONSTRAINT; Schema: mssql; Owner: postgres
--

ALTER TABLE ONLY mssql.views
    ADD CONSTRAINT views_pkey PRIMARY KEY (id);


--
-- Name: dbs dbs_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.dbs
    ADD CONSTRAINT dbs_pkey PRIMARY KEY (id);


--
-- Name: files_data_conf files_data_conf_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.files_data_conf
    ADD CONSTRAINT files_data_conf_pkey PRIMARY KEY (id);


--
-- Name: funproc funproc_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.funproc
    ADD CONSTRAINT funproc_pkey PRIMARY KEY (id);


--
-- Name: index_columns index_columns_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.index_columns
    ADD CONSTRAINT index_columns_pkey PRIMARY KEY (id);


--
-- Name: indexs indexs_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.indexs
    ADD CONSTRAINT indexs_pkey PRIMARY KEY (id);


--
-- Name: info_hardware info_hardware_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.info_hardware
    ADD CONSTRAINT info_hardware_pkey PRIMARY KEY (id);


--
-- Name: instance_properties instance_properties_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.instance_properties
    ADD CONSTRAINT instance_properties_pkey PRIMARY KEY (id);


--
-- Name: pg_hba pg_hba_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.pg_hba
    ADD CONSTRAINT pg_hba_pkey PRIMARY KEY (id);


--
-- Name: pg_settings pg_settings_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.pg_settings
    ADD CONSTRAINT pg_settings_pkey PRIMARY KEY (id);


--
-- Name: postgresql_conf postgresql_conf2_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.postgresql_conf
    ADD CONSTRAINT postgresql_conf2_pkey PRIMARY KEY (id);


--
-- Name: privileges_gran privileges_gran_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.privileges_gran
    ADD CONSTRAINT privileges_gran_pkey PRIMARY KEY (id);


--
-- Name: schemas schemas_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.schemas
    ADD CONSTRAINT schemas_pkey PRIMARY KEY (id);


--
-- Name: sequences sequences_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.sequences
    ADD CONSTRAINT sequences_pkey PRIMARY KEY (id);


--
-- Name: sizes_disks sizes_disks_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.sizes_disks
    ADD CONSTRAINT sizes_disks_pkey PRIMARY KEY (id);


--
-- Name: tables_columns table_columns_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.tables_columns
    ADD CONSTRAINT table_columns_pkey PRIMARY KEY (id);


--
-- Name: table_constraint table_constraint_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.table_constraint
    ADD CONSTRAINT table_constraint_pkey PRIMARY KEY (id);


--
-- Name: table_foreign table_fereign_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.table_foreign
    ADD CONSTRAINT table_fereign_pkey PRIMARY KEY (id);


--
-- Name: tables tables_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.tables
    ADD CONSTRAINT tables_pkey PRIMARY KEY (id);


--
-- Name: triggers triggers_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.triggers
    ADD CONSTRAINT triggers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: psql; Owner: postgres
--

ALTER TABLE ONLY psql.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: cat_zona_cafe_mx cat_zona_cafe_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_zona_cafe_mx
    ADD CONSTRAINT cat_zona_cafe_pkey PRIMARY KEY (id);


--
-- Name: cat_server ctl_server_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_server
    ADD CONSTRAINT ctl_server_pkey PRIMARY KEY (id);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);

ALTER TABLE public.pedidos CLUSTER ON pedidos_pkey;


--
-- Name: idx_cat_server; Type: INDEX; Schema: cdc; Owner: postgres
--

CREATE INDEX idx_cat_server ON cdc.cat_server USING btree (operacion, usuario, ip_cliente, fecha);


--
-- Name: tables_idx; Type: INDEX; Schema: cdc; Owner: postgres
--

CREATE INDEX tables_idx ON cdc.cat_server USING btree (operacion, usuario, ip_cliente, fecha);


--
-- Name: cat_dbms_idx; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX cat_dbms_idx ON fdw_conf.ctl_dbms USING btree (dbms, date_insert);


--
-- Name: connection_report_idx; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX connection_report_idx ON fdw_conf.report_connection USING btree (dbms, cnt_total_serv, cnt_connection_telnet, cnt_connection_sql, missing_connection_telnet, missing_connection_sql, execution_timems_func, date_insert);

ALTER TABLE fdw_conf.report_connection CLUSTER ON connection_report_idx;


--
-- Name: funs_tanks_idx; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX funs_tanks_idx ON fdw_conf.funs_tanks USING btree (fun_name, fun_desc, date_insert);


--
-- Name: idx_blacklist_server2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE UNIQUE INDEX idx_blacklist_server2 ON fdw_conf.blacklist_server USING btree (ip_server, port);


--
-- Name: idx_blacklist_server3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_blacklist_server3 ON fdw_conf.blacklist_server USING btree (date_insert);


--
-- Name: idx_cat_dbs; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_dbs ON fdw_conf.cat_dbs USING btree (ip_server, port, db_name, date_insert);


--
-- Name: idx_cat_dbs1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_dbs1 ON fdw_conf.cat_dbs USING btree (id_exec);


--
-- Name: idx_cat_dbs2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_dbs2 ON fdw_conf.cat_dbs USING btree (date_insert);


--
-- Name: idx_cat_dbs3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_dbs3 ON fdw_conf.cat_dbs USING btree (date_insert, ip_server, port, db_name);


--
-- Name: idx_cat_dbs4; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_dbs4 ON fdw_conf.cat_dbs USING btree (ip_server, port, date_insert);


--
-- Name: idx_cat_dbs5; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_dbs5 ON fdw_conf.cat_dbs USING btree (db_name, ip_server, port);


--
-- Name: idx_cat_remote_user_username; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_remote_user_username ON fdw_conf.ctl_remote_users USING btree (dbms, remote_user, date_insert);


--
-- Name: idx_cat_version_mssql_oficial1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_version_mssql_oficial1 ON fdw_conf.cat_version_mssql_oficial USING btree (sql_server);


--
-- Name: idx_cat_version_mssql_oficial2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_version_mssql_oficial2 ON fdw_conf.cat_version_mssql_oficial USING btree (product_version);


--
-- Name: idx_cat_version_mssql_oficial3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_version_mssql_oficial3 ON fdw_conf.cat_version_mssql_oficial USING btree (service_pack);


--
-- Name: idx_cat_version_mssql_oficial4; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_version_mssql_oficial4 ON fdw_conf.cat_version_mssql_oficial USING btree (release_date);


--
-- Name: idx_cat_version_mssql_oficial5; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_version_mssql_oficial5 ON fdw_conf.cat_version_mssql_oficial USING btree (date_insert);


--
-- Name: idx_cat_versions; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_versions ON fdw_conf.cat_versions USING btree (ip_server, port, version, date_insert);


--
-- Name: idx_cat_versions1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_versions1 ON fdw_conf.cat_versions USING btree (id_exec);


--
-- Name: idx_cat_versions2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_versions2 ON fdw_conf.cat_versions USING btree (date_insert);


--
-- Name: idx_cat_versions3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_versions3 ON fdw_conf.cat_versions USING btree (date_insert, ip_server, port);


--
-- Name: idx_cat_versions4; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_versions4 ON fdw_conf.cat_versions USING btree (date_insert, version);


--
-- Name: idx_cat_versions5; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_versions5 ON fdw_conf.cat_versions USING btree (id_exec, ip_server, port);


--
-- Name: idx_cat_versions6; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_cat_versions6 ON fdw_conf.cat_versions USING btree (id_exec, version);


--
-- Name: idx_ctl_ports; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_ports ON fdw_conf.ctl_ports USING btree (dbms, port, date_insert);


--
-- Name: idx_ctl_ports2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_ports2 ON fdw_conf.ctl_ports USING btree (date_insert);


--
-- Name: idx_ctl_querys1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_querys1 ON fdw_conf.ctl_querys USING btree (query_name);


--
-- Name: idx_ctl_querys3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_querys3 ON fdw_conf.ctl_querys USING btree (dbms);


--
-- Name: idx_ctl_querys4; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_querys4 ON fdw_conf.ctl_querys USING btree (lvl_exec_query);


--
-- Name: idx_ctl_querys5; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_querys5 ON fdw_conf.ctl_querys USING btree (min_vers_compatibility, max_vers_compatibility);


--
-- Name: idx_ctl_querys6; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_querys6 ON fdw_conf.ctl_querys USING btree (max_vers_compatibility, min_vers_compatibility);


--
-- Name: idx_ctl_remote_users1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_remote_users1 ON fdw_conf.ctl_remote_users USING btree (dbms);


--
-- Name: idx_ctl_remote_users2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_remote_users2 ON fdw_conf.ctl_remote_users USING btree (remote_user);


--
-- Name: idx_ctl_remote_users3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_ctl_remote_users3 ON fdw_conf.ctl_remote_users USING btree (date_insert);


--
-- Name: idx_details_connection; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection ON fdw_conf.details_connection USING btree (ip_server, port, dbms, connection_telnet, connection_sql, msg_log, date_insert);


--
-- Name: idx_details_connection1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection1 ON fdw_conf.details_connection USING btree (id_exec);


--
-- Name: idx_details_connection10; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection10 ON fdw_conf.details_connection USING btree (date_insert, ip_server, port);


--
-- Name: idx_details_connection11; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection11 ON fdw_conf.details_connection USING btree (id_exec, connection_telnet);


--
-- Name: idx_details_connection12; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection12 ON fdw_conf.details_connection USING btree (date_insert, connection_sql);


--
-- Name: idx_details_connection13; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection13 ON fdw_conf.details_connection USING btree (id_exec, dbms);


--
-- Name: idx_details_connection14; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection14 ON fdw_conf.details_connection USING btree (date_insert, dbms);


--
-- Name: idx_details_connection2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection2 ON fdw_conf.details_connection USING btree (date_insert);


--
-- Name: idx_details_connection3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection3 ON fdw_conf.details_connection USING btree (connection_telnet);


--
-- Name: idx_details_connection4; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection4 ON fdw_conf.details_connection USING btree (connection_sql);


--
-- Name: idx_details_connection5; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection5 ON fdw_conf.details_connection USING btree (dbms);


--
-- Name: idx_details_connection6; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection6 ON fdw_conf.details_connection USING btree (ip_server, port);


--
-- Name: idx_details_connection7; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection7 ON fdw_conf.details_connection USING btree (id_exec, ip_server, port);


--
-- Name: idx_details_connection8; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection8 ON fdw_conf.details_connection USING btree (date_insert, ip_server, port);


--
-- Name: idx_details_connection9; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_details_connection9 ON fdw_conf.details_connection USING btree (id_exec, ip_server, port);


--
-- Name: idx_log_exec_failed_query; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query ON fdw_conf.log_exec_failed_query USING btree (ip_server, port, db, query_name, attempted_exec, id_exec, date_insert);


--
-- Name: idx_log_exec_failed_query1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query1 ON fdw_conf.log_exec_failed_query USING btree (id_exec);


--
-- Name: idx_log_exec_failed_query10; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query10 ON fdw_conf.log_exec_failed_query USING btree (date_insert, db);


--
-- Name: idx_log_exec_failed_query11; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query11 ON fdw_conf.log_exec_failed_query USING btree (id_exec, attempted_exec);


--
-- Name: idx_log_exec_failed_query12; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query12 ON fdw_conf.log_exec_failed_query USING btree (date_insert, attempted_exec);


--
-- Name: idx_log_exec_failed_query2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query2 ON fdw_conf.log_exec_failed_query USING btree (date_insert);


--
-- Name: idx_log_exec_failed_query3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query3 ON fdw_conf.log_exec_failed_query USING btree (id_exec, ip_server, port, db);


--
-- Name: idx_log_exec_failed_query4; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query4 ON fdw_conf.log_exec_failed_query USING btree (date_insert, ip_server, port, db);


--
-- Name: idx_log_exec_failed_query6; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query6 ON fdw_conf.log_exec_failed_query USING btree (query_name);


--
-- Name: idx_log_exec_failed_query7; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query7 ON fdw_conf.log_exec_failed_query USING btree (id_exec, query_name);


--
-- Name: idx_log_exec_failed_query8; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query8 ON fdw_conf.log_exec_failed_query USING btree (date_insert, query_name);


--
-- Name: idx_log_exec_failed_query9; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_exec_failed_query9 ON fdw_conf.log_exec_failed_query USING btree (id_exec, db);


--
-- Name: idx_log_msg_error; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_msg_error ON fdw_conf.log_msg_error USING btree (original_obj_name, type_object, date_insert, msg_error);


--
-- Name: idx_log_msg_error1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_log_msg_error1 ON fdw_conf.log_msg_error USING btree (date_insert, original_obj_name, type_object);


--
-- Name: idx_report_connection1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection1 ON fdw_conf.report_connection USING btree (id_exec);


--
-- Name: idx_report_connection10; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection10 ON fdw_conf.report_connection USING btree (date_insert, dbms);


--
-- Name: idx_report_connection11; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection11 ON fdw_conf.report_connection USING btree (date_insert, cnt_connection_telnet);


--
-- Name: idx_report_connection12; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection12 ON fdw_conf.report_connection USING btree (date_insert, cnt_connection_sql);


--
-- Name: idx_report_connection2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection2 ON fdw_conf.report_connection USING btree (date_insert);


--
-- Name: idx_report_connection3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection3 ON fdw_conf.report_connection USING btree (execution_timems_func);


--
-- Name: idx_report_connection4; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection4 ON fdw_conf.report_connection USING btree (dbms);


--
-- Name: idx_report_connection5; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection5 ON fdw_conf.report_connection USING btree (cnt_connection_telnet);


--
-- Name: idx_report_connection6; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection6 ON fdw_conf.report_connection USING btree (cnt_connection_sql);


--
-- Name: idx_report_connection7; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection7 ON fdw_conf.report_connection USING btree (id_exec, dbms);


--
-- Name: idx_report_connection8; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection8 ON fdw_conf.report_connection USING btree (id_exec, cnt_connection_telnet);


--
-- Name: idx_report_connection9; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_report_connection9 ON fdw_conf.report_connection USING btree (id_exec, cnt_connection_sql);


--
-- Name: idx_scan_rules_query; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_scan_rules_query ON fdw_conf.scan_rules_query USING btree (ip_server);


--
-- Name: idx_scan_rules_query_10; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_scan_rules_query_10 ON fdw_conf.scan_rules_query USING btree (port);


--
-- Name: idx_scan_rules_query_11; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_scan_rules_query_11 ON fdw_conf.scan_rules_query USING btree (db);


--
-- Name: idx_scan_rules_query_12; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE INDEX idx_scan_rules_query_12 ON fdw_conf.scan_rules_query USING btree (date_insert);


--
-- Name: idx_unique_scan_rules_query_1; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_scan_rules_query_1 ON fdw_conf.scan_rules_query USING btree (id_query, ip_server, port, db);


--
-- Name: idx_unique_scan_rules_query_2; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_scan_rules_query_2 ON fdw_conf.scan_rules_query USING btree (id_query, ip_server);


--
-- Name: idx_unique_scan_rules_query_3; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_scan_rules_query_3 ON fdw_conf.scan_rules_query USING btree (id_query, port);


--
-- Name: idx_unique_scan_rules_query_4; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_scan_rules_query_4 ON fdw_conf.scan_rules_query USING btree (id_query, db);


--
-- Name: unique_query_name_per_gestor_db; Type: INDEX; Schema: fdw_conf; Owner: postgres
--

CREATE UNIQUE INDEX unique_query_name_per_gestor_db ON fdw_conf.ctl_querys USING btree (dbms, query_name, max_vers_compatibility, min_vers_compatibility);


--
-- Name: dbs_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX dbs_idx ON mssql.dbs USING btree (ip_server, port, db, date_insert);


--
-- Name: funproc_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX funproc_idx ON mssql.funproc USING btree (ip_server, port, db, schema_name, object_name, owner, type, create_date, date_insert);


--
-- Name: idx_msql_dbs_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_dbs_1 ON mssql.dbs USING btree (id_exec);


--
-- Name: idx_msql_dbs_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_dbs_2 ON mssql.dbs USING btree (date_insert);


--
-- Name: idx_msql_dbs_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_dbs_3 ON mssql.dbs USING btree (id_exec, ip_server, port, db, state_desc);


--
-- Name: idx_msql_dbs_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_dbs_4 ON mssql.dbs USING btree (date_insert, ip_server, port, db, state_desc);


--
-- Name: idx_msql_funproc_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_funproc_1 ON mssql.funproc USING btree (id_exec);


--
-- Name: idx_msql_funproc_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_funproc_2 ON mssql.funproc USING btree (date_insert);


--
-- Name: idx_msql_funproc_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_funproc_3 ON mssql.funproc USING btree (id_exec, ip_server, port, db, md5);


--
-- Name: idx_msql_funproc_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_funproc_4 ON mssql.funproc USING btree (date_insert, ip_server, port, db, md5);


--
-- Name: idx_msql_info_backup_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_backup_1 ON mssql.info_backup USING btree (id_exec);


--
-- Name: idx_msql_info_backup_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_backup_2 ON mssql.info_backup USING btree (date_insert);


--
-- Name: idx_msql_info_backup_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_backup_3 ON mssql.info_backup USING btree (id_exec, ip_server, port, db, date_start);


--
-- Name: idx_msql_info_backup_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_backup_4 ON mssql.info_backup USING btree (date_insert, ip_server, port, db, date_start);


--
-- Name: idx_msql_info_hardware_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_hardware_1 ON mssql.info_hardware USING btree (id_exec);


--
-- Name: idx_msql_info_hardware_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_hardware_2 ON mssql.info_hardware USING btree (date_insert);


--
-- Name: idx_msql_info_hardware_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_hardware_3 ON mssql.info_hardware USING btree (id_exec, ip_server, port, sqlserver_start_time);


--
-- Name: idx_msql_info_hardware_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_hardware_4 ON mssql.info_hardware USING btree (date_insert, ip_server, port, sqlserver_start_time);


--
-- Name: idx_msql_info_job_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_job_1 ON mssql.info_job USING btree (id_exec);


--
-- Name: idx_msql_info_job_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_job_2 ON mssql.info_job USING btree (date_insert);


--
-- Name: idx_msql_info_job_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_job_3 ON mssql.info_job USING btree (id_exec, ip_server, port);


--
-- Name: idx_msql_info_job_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_info_job_4 ON mssql.info_job USING btree (date_insert, ip_server, port);


--
-- Name: idx_msql_instance_properties_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_1 ON mssql.instance_properties USING btree (id_exec);


--
-- Name: idx_msql_instance_properties_10; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_10 ON mssql.instance_properties USING btree (date_insert, instancedefaultdatapath);


--
-- Name: idx_msql_instance_properties_11; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_11 ON mssql.instance_properties USING btree (id_exec, instancedefaultbackuppath);


--
-- Name: idx_msql_instance_properties_12; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_12 ON mssql.instance_properties USING btree (date_insert, instancedefaultbackuppath);


--
-- Name: idx_msql_instance_properties_13; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_13 ON mssql.instance_properties USING btree (id_exec, instancedefaultlogpath);


--
-- Name: idx_msql_instance_properties_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_2 ON mssql.instance_properties USING btree (date_insert);


--
-- Name: idx_msql_instance_properties_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_3 ON mssql.instance_properties USING btree (id_exec, ip_server, port, version_);


--
-- Name: idx_msql_instance_properties_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_4 ON mssql.instance_properties USING btree (date_insert, ip_server, version_);


--
-- Name: idx_msql_instance_properties_5; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_5 ON mssql.instance_properties USING btree (id_exec, version_);


--
-- Name: idx_msql_instance_properties_6; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_6 ON mssql.instance_properties USING btree (date_insert, version_);


--
-- Name: idx_msql_instance_properties_7; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_7 ON mssql.instance_properties USING btree (id_exec, productversion);


--
-- Name: idx_msql_instance_properties_8; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_8 ON mssql.instance_properties USING btree (date_insert, productversion);


--
-- Name: idx_msql_instance_properties_9; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_instance_properties_9 ON mssql.instance_properties USING btree (id_exec, instancedefaultdatapath);


--
-- Name: idx_msql_logins_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_logins_2 ON mssql.logins USING btree (date_insert);


--
-- Name: idx_msql_logins_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_logins_3 ON mssql.logins USING btree (id_exec, ip_server, port, login_);


--
-- Name: idx_msql_logins_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_msql_logins_4 ON mssql.logins USING btree (date_insert, ip_server, login_);


--
-- Name: idx_mssql_master_files_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_1 ON mssql.master_files USING btree (id_exec);


--
-- Name: idx_mssql_master_files_10; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_10 ON mssql.master_files USING btree (date_insert, type_file);


--
-- Name: idx_mssql_master_files_11; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_11 ON mssql.master_files USING btree (id_exec, available_space_mb);


--
-- Name: idx_mssql_master_files_12; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_12 ON mssql.master_files USING btree (date_insert, available_space_mb);


--
-- Name: idx_mssql_master_files_14; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_14 ON mssql.master_files USING btree (id_exec, percentage_available_space);


--
-- Name: idx_mssql_master_files_15; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_15 ON mssql.master_files USING btree (id_exec, size_file_mb);


--
-- Name: idx_mssql_master_files_16; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_16 ON mssql.master_files USING btree (date_insert, size_file_mb);


--
-- Name: idx_mssql_master_files_17; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_17 ON mssql.master_files USING btree (date_insert, percentage_available_space);


--
-- Name: idx_mssql_master_files_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_2 ON mssql.master_files USING btree (date_insert);


--
-- Name: idx_mssql_master_files_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_3 ON mssql.master_files USING btree (id_exec, ip_server, port, name_db);


--
-- Name: idx_mssql_master_files_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_4 ON mssql.master_files USING btree (date_insert, ip_server, name_db);


--
-- Name: idx_mssql_master_files_5; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_5 ON mssql.master_files USING btree (id_exec, disk_drive);


--
-- Name: idx_mssql_master_files_6; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_6 ON mssql.master_files USING btree (date_insert, disk_drive);


--
-- Name: idx_mssql_master_files_7; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_7 ON mssql.master_files USING btree (id_exec, physical_route);


--
-- Name: idx_mssql_master_files_8; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_8 ON mssql.master_files USING btree (date_insert, physical_route);


--
-- Name: idx_mssql_master_files_9; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_master_files_9 ON mssql.master_files USING btree (id_exec, type_file);


--
-- Name: idx_mssql_parameters_conf_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_parameters_conf_1 ON mssql.parameters_conf USING btree (id_exec);


--
-- Name: idx_mssql_parameters_conf_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_parameters_conf_2 ON mssql.parameters_conf USING btree (date_insert);


--
-- Name: idx_mssql_parameters_conf_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_parameters_conf_3 ON mssql.parameters_conf USING btree (id_exec, ip_server, port, name, value);


--
-- Name: idx_mssql_parameters_conf_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_parameters_conf_4 ON mssql.parameters_conf USING btree (date_insert, ip_server, port, name, value);


--
-- Name: idx_mssql_parameters_conf_5; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_parameters_conf_5 ON mssql.parameters_conf USING btree (id_exec, name);


--
-- Name: idx_mssql_parameters_conf_6; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_parameters_conf_6 ON mssql.parameters_conf USING btree (date_insert, name);


--
-- Name: idx_mssql_parameters_conf_7; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_parameters_conf_7 ON mssql.parameters_conf USING btree (id_exec, value);


--
-- Name: idx_mssql_parameters_conf_8; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_parameters_conf_8 ON mssql.parameters_conf USING btree (date_insert, value);


--
-- Name: idx_mssql_privileges_admin_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_admin_1 ON mssql.privileges_admin USING btree (id_exec);


--
-- Name: idx_mssql_privileges_admin_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_admin_2 ON mssql.privileges_admin USING btree (date_insert);


--
-- Name: idx_mssql_privileges_admin_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_admin_3 ON mssql.privileges_admin USING btree (id_exec, ip_server, port, db, grantee);


--
-- Name: idx_mssql_privileges_admin_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_admin_4 ON mssql.privileges_admin USING btree (date_insert, ip_server, port, db, grantee);


--
-- Name: idx_mssql_privileges_admin_5; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_admin_5 ON mssql.privileges_admin USING btree (id_exec, permission_name);


--
-- Name: idx_mssql_privileges_admin_6; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_admin_6 ON mssql.privileges_admin USING btree (date_insert, permission_name);


--
-- Name: idx_mssql_privileges_gran_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_gran_1 ON mssql.privileges_gran USING btree (id_exec);


--
-- Name: idx_mssql_privileges_gran_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_gran_2 ON mssql.privileges_gran USING btree (date_insert);


--
-- Name: idx_mssql_privileges_gran_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_gran_3 ON mssql.privileges_gran USING btree (id_exec, ip_server, port, db, grantee);


--
-- Name: idx_mssql_privileges_gran_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_gran_4 ON mssql.privileges_gran USING btree (date_insert, ip_server, port, db, grantee);


--
-- Name: idx_mssql_privileges_gran_5; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_gran_5 ON mssql.privileges_gran USING btree (id_exec, permission_name_);


--
-- Name: idx_mssql_privileges_gran_6; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_gran_6 ON mssql.privileges_gran USING btree (date_insert, permission_name_);


--
-- Name: idx_mssql_privileges_roles_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_roles_1 ON mssql.privileges_roles USING btree (id_exec);


--
-- Name: idx_mssql_privileges_roles_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_roles_2 ON mssql.privileges_roles USING btree (date_insert);


--
-- Name: idx_mssql_privileges_roles_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_roles_3 ON mssql.privileges_roles USING btree (id_exec, ip_server, port, rolname, username);


--
-- Name: idx_mssql_privileges_roles_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_privileges_roles_4 ON mssql.privileges_roles USING btree (date_insert, ip_server, port, rolname, username);


--
-- Name: idx_mssql_schemas_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_schemas_1 ON mssql.schemas USING btree (id_exec);


--
-- Name: idx_mssql_schemas_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_schemas_2 ON mssql.schemas USING btree (date_insert);


--
-- Name: idx_mssql_schemas_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_schemas_3 ON mssql.schemas USING btree (id_exec, ip_server, port, db);


--
-- Name: idx_mssql_schemas_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_schemas_4 ON mssql.schemas USING btree (date_insert, ip_server, port, db);


--
-- Name: idx_mssql_sequences_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sequences_1 ON mssql.sequences USING btree (id_exec);


--
-- Name: idx_mssql_sequences_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sequences_2 ON mssql.sequences USING btree (date_insert);


--
-- Name: idx_mssql_sequences_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sequences_3 ON mssql.sequences USING btree (id_exec, ip_server, port, db);


--
-- Name: idx_mssql_sequences_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sequences_4 ON mssql.sequences USING btree (date_insert, ip_server, port, db);


--
-- Name: idx_mssql_sizes_disks_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_1 ON mssql.sizes_disks USING btree (id_exec);


--
-- Name: idx_mssql_sizes_disks_10; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_10 ON mssql.sizes_disks USING btree (date_insert, usado_gb);


--
-- Name: idx_mssql_sizes_disks_11; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_11 ON mssql.sizes_disks USING btree (id_exec, disponible_gb);


--
-- Name: idx_mssql_sizes_disks_12; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_12 ON mssql.sizes_disks USING btree (date_insert, disponible_gb);


--
-- Name: idx_mssql_sizes_disks_13; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_13 ON mssql.sizes_disks USING btree (id_exec, porcentaje_disponible);


--
-- Name: idx_mssql_sizes_disks_14; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_14 ON mssql.sizes_disks USING btree (date_insert, porcentaje_disponible);


--
-- Name: idx_mssql_sizes_disks_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_2 ON mssql.sizes_disks USING btree (date_insert);


--
-- Name: idx_mssql_sizes_disks_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_3 ON mssql.sizes_disks USING btree (id_exec, ip_server, disco);


--
-- Name: idx_mssql_sizes_disks_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_4 ON mssql.sizes_disks USING btree (date_insert, ip_server, disco);


--
-- Name: idx_mssql_sizes_disks_5; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_5 ON mssql.sizes_disks USING btree (id_exec, disco);


--
-- Name: idx_mssql_sizes_disks_6; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_6 ON mssql.sizes_disks USING btree (date_insert, disco);


--
-- Name: idx_mssql_sizes_disks_7; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_7 ON mssql.sizes_disks USING btree (id_exec, total_gb);


--
-- Name: idx_mssql_sizes_disks_8; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_8 ON mssql.sizes_disks USING btree (date_insert, total_gb);


--
-- Name: idx_mssql_sizes_disks_9; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_sizes_disks_9 ON mssql.sizes_disks USING btree (id_exec, usado_gb);


--
-- Name: idx_mssql_tables_columns_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_tables_columns_1 ON mssql.tables_columns USING btree (id_exec);


--
-- Name: idx_mssql_tables_columns_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_tables_columns_2 ON mssql.tables_columns USING btree (date_insert);


--
-- Name: idx_mssql_tables_columns_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_tables_columns_3 ON mssql.tables_columns USING btree (id_exec, ip_server, db, table_name);


--
-- Name: idx_mssql_tables_columns_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_tables_columns_4 ON mssql.tables_columns USING btree (date_insert, ip_server, db, table_name);


--
-- Name: idx_mssql_triggers_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_triggers_1 ON mssql.triggers USING btree (id_exec);


--
-- Name: idx_mssql_triggers_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_triggers_2 ON mssql.triggers USING btree (date_insert);


--
-- Name: idx_mssql_triggers_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_triggers_3 ON mssql.triggers USING btree (id_exec, ip_server, db, object_name);


--
-- Name: idx_mssql_triggers_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_triggers_4 ON mssql.triggers USING btree (date_insert, ip_server, db, object_name);


--
-- Name: idx_mssql_users_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_users_1 ON mssql.users USING btree (id_exec);


--
-- Name: idx_mssql_users_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_users_2 ON mssql.users USING btree (date_insert);


--
-- Name: idx_mssql_users_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_users_3 ON mssql.users USING btree (id_exec, ip_server, port, name, type_desc);


--
-- Name: idx_mssql_users_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_users_4 ON mssql.users USING btree (date_insert, ip_server, port, name, type_desc);


--
-- Name: idx_mssql_views_1; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_views_1 ON mssql.views USING btree (id_exec);


--
-- Name: idx_mssql_views_2; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_views_2 ON mssql.views USING btree (date_insert);


--
-- Name: idx_mssql_views_3; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_views_3 ON mssql.views USING btree (id_exec, ip_server, port, name);


--
-- Name: idx_mssql_views_4; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX idx_mssql_views_4 ON mssql.views USING btree (date_insert, ip_server, port, name);


--
-- Name: info_backup_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX info_backup_idx ON mssql.info_backup USING btree (ip_server, port, name_server, db, date_start, date_finish, type_backup, size, physical_route, date_insert);


--
-- Name: info_hardware_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX info_hardware_idx ON mssql.info_hardware USING btree (ip_server, port, sqlserver_start_time, cpu_count, total_memory_ram_os_mb, date_insert);


--
-- Name: info_job_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX info_job_idx ON mssql.info_job USING btree (ip_server, port, job_name, job_description, date_created, job_enabled, date_insert);


--
-- Name: info_service_install_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX info_service_install_idx ON mssql.info_service_install USING btree (ip_server, port, servicename, startup_type_desc, status_desc, service_account, filename, date_insert);


--
-- Name: instance_properties2_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX instance_properties2_idx ON mssql.instance_properties USING btree (ip_server, port, version_, os_version, servername, machinename, collation_, edition, productlevel, productupdatelevel, productversion, productmajorversion, productupdatereference, resourcelastupdatedatetime, date_insert);


--
-- Name: logins_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX logins_idx ON mssql.logins USING btree (ip_server, port, login_, date_insert);


--
-- Name: master_files_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX master_files_idx ON mssql.master_files USING btree (ip_server, port, name_db, owner, percentage_space_used, available_space_mb, percentage_available_space, physical_route, disk_drive, type_file, date_insert);


--
-- Name: parameters_conf_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX parameters_conf_idx ON mssql.parameters_conf USING btree (ip_server, port, name, value, minimum, maximum, description, date_insert);


--
-- Name: privileges_admin_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX privileges_admin_idx ON mssql.privileges_admin USING btree (ip_server, port, db, type_grantee, grantee, grantor, permission_name, date_insert);


--
-- Name: privileges_gran_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX privileges_gran_idx ON mssql.privileges_gran USING btree (ip_server, port, db, type_user, grantor, grantee, grantee_is_disabled, orphaned_users, permission_name_, date_insert);


--
-- Name: privileges_roles_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX privileges_roles_idx ON mssql.privileges_roles USING btree (ip_server, port, db, type_role, role_predefined, rolname, username, username_is_disabled, date_insert);


--
-- Name: schemas_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX schemas_idx ON mssql.schemas USING btree (ip_server, port, db, type_obj, name, owner, date_insert);


--
-- Name: sequences_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX sequences_idx ON mssql.sequences USING btree (ip_server, port, db, schema_name, name_sequence, owner, create_date, date_insert);


--
-- Name: sizes_disks_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX sizes_disks_idx ON mssql.sizes_disks USING btree (ip_server, port, disco, porcentaje_usado, total_gb, usado_gb, disponible_gb, porcentaje_disponible, date_insert);


--
-- Name: tables_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX tables_idx ON mssql.tables_columns USING btree (ip_server, port, db, schema_name, table_name, create_date, modify_date, owner, column_name, data_type, date_insert);


--
-- Name: triggers_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX triggers_idx ON mssql.triggers USING btree (ip_server, port, db, schema_name, object_name, owner, type, create_date, is_disabled, date_insert);


--
-- Name: users_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX users_idx ON mssql.users USING btree (ip_server, port, name, type_desc, is_disabled, create_date, modify_date, date_insert);


--
-- Name: views_idx; Type: INDEX; Schema: mssql; Owner: postgres
--

CREATE INDEX views_idx ON mssql.views USING btree (ip_server, port, db, name, owner, create_date, date_insert);


--
-- Name: dbs_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX dbs_idx ON psql.dbs USING btree (ip_server, port, name, owner, size, unit_size, create_date);


--
-- Name: files_data_conf_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX files_data_conf_idx ON psql.files_data_conf USING btree (ip_server, port, md5_postgresql_conf, md5_pg_hba_conf, md5_pg_ident_conf, md5_crontab, date_insert);


--
-- Name: funproc_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX funproc_idx ON psql.funproc USING btree (ip_server, port, db, schema, name, type, volatility, parallel, owner, security, language, description, date_insert);


--
-- Name: idx_psql_dbs1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs1 ON psql.dbs USING btree (id_exec);


--
-- Name: idx_psql_dbs10; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs10 ON psql.dbs USING btree (date_insert, owner);


--
-- Name: idx_psql_dbs11; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs11 ON psql.dbs USING btree (id_exec, encoding);


--
-- Name: idx_psql_dbs12; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs12 ON psql.dbs USING btree (date_insert, encoding);


--
-- Name: idx_psql_dbs2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs2 ON psql.dbs USING btree (date_insert);


--
-- Name: idx_psql_dbs3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs3 ON psql.dbs USING btree (id_exec, size, unit_size);


--
-- Name: idx_psql_dbs4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs4 ON psql.dbs USING btree (date_insert, size, unit_size);


--
-- Name: idx_psql_dbs5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs5 ON psql.dbs USING btree (id_exec, ip_server, port);


--
-- Name: idx_psql_dbs6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs6 ON psql.dbs USING btree (date_insert, ip_server, port);


--
-- Name: idx_psql_dbs7; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs7 ON psql.dbs USING btree (id_exec, ip_server, port, name);


--
-- Name: idx_psql_dbs8; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs8 ON psql.dbs USING btree (date_insert, ip_server, port, name);


--
-- Name: idx_psql_dbs9; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_dbs9 ON psql.dbs USING btree (id_exec, owner);


--
-- Name: idx_psql_files_data_conf1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf1 ON psql.files_data_conf USING btree (id_exec);


--
-- Name: idx_psql_files_data_conf10; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf10 ON psql.files_data_conf USING btree (date_insert, md5_pg_hba_conf);


--
-- Name: idx_psql_files_data_conf11; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf11 ON psql.files_data_conf USING btree (date_insert, md5_pg_ident_conf);


--
-- Name: idx_psql_files_data_conf12; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf12 ON psql.files_data_conf USING btree (date_insert, md5_crontab);


--
-- Name: idx_psql_files_data_conf2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf2 ON psql.files_data_conf USING btree (date_insert);


--
-- Name: idx_psql_files_data_conf3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf3 ON psql.files_data_conf USING btree (id_exec, ip_server, port);


--
-- Name: idx_psql_files_data_conf4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf4 ON psql.files_data_conf USING btree (date_insert, ip_server, port);


--
-- Name: idx_psql_files_data_conf5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf5 ON psql.files_data_conf USING btree (id_exec, md5_postgresql_conf);


--
-- Name: idx_psql_files_data_conf6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf6 ON psql.files_data_conf USING btree (id_exec, md5_pg_hba_conf);


--
-- Name: idx_psql_files_data_conf7; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf7 ON psql.files_data_conf USING btree (id_exec, md5_pg_ident_conf);


--
-- Name: idx_psql_files_data_conf8; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf8 ON psql.files_data_conf USING btree (id_exec, md5_crontab);


--
-- Name: idx_psql_files_data_conf9; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_files_data_conf9 ON psql.files_data_conf USING btree (date_insert, md5_postgresql_conf);


--
-- Name: idx_psql_funproc1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_funproc1 ON psql.funproc USING btree (id_exec);


--
-- Name: idx_psql_funproc2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_funproc2 ON psql.funproc USING btree (date_insert);


--
-- Name: idx_psql_funproc3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_funproc3 ON psql.funproc USING btree (id_exec, ip_server, port, db, schema, name);


--
-- Name: idx_psql_funproc4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_funproc4 ON psql.funproc USING btree (date_insert, ip_server, port, db, schema, name);


--
-- Name: idx_psql_index_columns1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_index_columns1 ON psql.index_columns USING btree (id_exec);


--
-- Name: idx_psql_index_columns2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_index_columns2 ON psql.index_columns USING btree (date_insert);


--
-- Name: idx_psql_index_columns3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_index_columns3 ON psql.index_columns USING btree (id_exec, ip_server, port, db);


--
-- Name: idx_psql_index_columns4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_index_columns4 ON psql.index_columns USING btree (date_insert, ip_server, port, db);


--
-- Name: idx_psql_index_columns5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_index_columns5 ON psql.index_columns USING btree (id_exec, ip_server, port, table_name, index_name);


--
-- Name: idx_psql_index_columns6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_index_columns6 ON psql.index_columns USING btree (id_exec, ip_server, port, index_name, table_name);


--
-- Name: idx_psql_index_columns7; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_index_columns7 ON psql.index_columns USING btree (date_insert, ip_server, port, table_name, index_name);


--
-- Name: idx_psql_index_columns8; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_index_columns8 ON psql.index_columns USING btree (date_insert, ip_server, port, index_name, table_name);


--
-- Name: idx_psql_indexs1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_indexs1 ON psql.indexs USING btree (id_exec);


--
-- Name: idx_psql_indexs2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_indexs2 ON psql.indexs USING btree (date_insert);


--
-- Name: idx_psql_indexs3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_indexs3 ON psql.indexs USING btree (id_exec, ip_server, port, db);


--
-- Name: idx_psql_indexs4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_indexs4 ON psql.indexs USING btree (date_insert, ip_server, port, db);


--
-- Name: idx_psql_indexs5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_indexs5 ON psql.indexs USING btree (id_exec, size, unit_size);


--
-- Name: idx_psql_indexs6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_indexs6 ON psql.indexs USING btree (date_insert, size, unit_size);


--
-- Name: idx_psql_indexs7; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_indexs7 ON psql.indexs USING btree (id_exec, owner);


--
-- Name: idx_psql_indexs8; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_indexs8 ON psql.indexs USING btree (date_insert, owner);


--
-- Name: idx_psql_info_hardware_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_info_hardware_1 ON psql.info_hardware USING btree (id_exec);


--
-- Name: idx_psql_info_hardware_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_info_hardware_2 ON psql.info_hardware USING btree (date_insert);


--
-- Name: idx_psql_info_hardware_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_info_hardware_3 ON psql.info_hardware USING btree (id_exec, ip_server, port, hostname);


--
-- Name: idx_psql_info_hardware_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_info_hardware_4 ON psql.info_hardware USING btree (date_insert, ip_server, port, hostname);


--
-- Name: idx_psql_info_hardware_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_info_hardware_5 ON psql.info_hardware USING btree (id_exec, local_time);


--
-- Name: idx_psql_info_hardware_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_info_hardware_6 ON psql.info_hardware USING btree (date_insert, local_time);


--
-- Name: idx_psql_instance_properties_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_1 ON psql.instance_properties USING btree (id_exec);


--
-- Name: idx_psql_instance_properties_10; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_10 ON psql.instance_properties USING btree (date_insert, ip_server, port, log_directory);


--
-- Name: idx_psql_instance_properties_11; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_11 ON psql.instance_properties USING btree (id_exec, ip_server, port, version);


--
-- Name: idx_psql_instance_properties_12; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_12 ON psql.instance_properties USING btree (id_exec, ip_server, port, data_directory);


--
-- Name: idx_psql_instance_properties_13; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_13 ON psql.instance_properties USING btree (id_exec, ip_server, port, postgresql_conf_directory);


--
-- Name: idx_psql_instance_properties_14; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_14 ON psql.instance_properties USING btree (id_exec, ip_server, port, hba_file_directory);


--
-- Name: idx_psql_instance_properties_15; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_15 ON psql.instance_properties USING btree (id_exec, ip_server, port, ident_file_directory);


--
-- Name: idx_psql_instance_properties_16; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_16 ON psql.instance_properties USING btree (id_exec, ip_server, port, log_directory);


--
-- Name: idx_psql_instance_properties_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_2 ON psql.instance_properties USING btree (date_insert);


--
-- Name: idx_psql_instance_properties_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_3 ON psql.instance_properties USING btree (id_exec, ip_server, port, dbms);


--
-- Name: idx_psql_instance_properties_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_4 ON psql.instance_properties USING btree (date_insert, ip_server, port, dbms);


--
-- Name: idx_psql_instance_properties_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_5 ON psql.instance_properties USING btree (date_insert, ip_server, port, version);


--
-- Name: idx_psql_instance_properties_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_6 ON psql.instance_properties USING btree (date_insert, ip_server, port, data_directory);


--
-- Name: idx_psql_instance_properties_7; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_7 ON psql.instance_properties USING btree (date_insert, ip_server, port, postgresql_conf_directory);


--
-- Name: idx_psql_instance_properties_8; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_8 ON psql.instance_properties USING btree (date_insert, ip_server, port, hba_file_directory);


--
-- Name: idx_psql_instance_properties_9; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_instance_properties_9 ON psql.instance_properties USING btree (date_insert, ip_server, port, ident_file_directory);


--
-- Name: idx_psql_pg_hba_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_hba_1 ON psql.pg_hba USING btree (id_exec);


--
-- Name: idx_psql_pg_hba_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_hba_2 ON psql.pg_hba USING btree (date_insert);


--
-- Name: idx_psql_pg_hba_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_hba_3 ON psql.pg_hba USING btree (id_exec, ip_server, port, address, netmask, auth_method);


--
-- Name: idx_psql_pg_hba_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_hba_4 ON psql.pg_hba USING btree (date_insert, ip_server, port, address, netmask, auth_method);


--
-- Name: idx_psql_pg_hba_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_hba_5 ON psql.pg_hba USING btree (id_exec, error);


--
-- Name: idx_psql_pg_hba_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_hba_6 ON psql.pg_hba USING btree (date_insert, error);


--
-- Name: idx_psql_pg_settings_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_settings_1 ON psql.pg_settings USING btree (id_exec);


--
-- Name: idx_psql_pg_settings_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_settings_2 ON psql.pg_settings USING btree (date_insert);


--
-- Name: idx_psql_pg_settings_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_settings_3 ON psql.pg_settings USING btree (id_exec, ip_server, port, name, setting);


--
-- Name: idx_psql_pg_settings_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_settings_4 ON psql.pg_settings USING btree (date_insert, ip_server, port, name, setting);


--
-- Name: idx_psql_pg_settings_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_settings_5 ON psql.pg_settings USING btree (id_exec, name);


--
-- Name: idx_psql_pg_settings_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_settings_6 ON psql.pg_settings USING btree (date_insert, name);


--
-- Name: idx_psql_pg_settings_7; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_settings_7 ON psql.pg_settings USING btree (id_exec, name, setting);


--
-- Name: idx_psql_pg_settings_8; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_pg_settings_8 ON psql.pg_settings USING btree (date_insert, name, setting);


--
-- Name: idx_psql_postgresql_conf_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_postgresql_conf_1 ON psql.postgresql_conf USING btree (id_exec);


--
-- Name: idx_psql_postgresql_conf_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_postgresql_conf_2 ON psql.postgresql_conf USING btree (date_insert);


--
-- Name: idx_psql_postgresql_conf_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_postgresql_conf_3 ON psql.postgresql_conf USING btree (id_exec, ip_server, port, name, setting);


--
-- Name: idx_psql_postgresql_conf_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_postgresql_conf_4 ON psql.postgresql_conf USING btree (date_insert, ip_server, port, name, setting);


--
-- Name: idx_psql_postgresql_conf_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_postgresql_conf_5 ON psql.postgresql_conf USING btree (id_exec, error);


--
-- Name: idx_psql_postgresql_conf_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_postgresql_conf_6 ON psql.postgresql_conf USING btree (date_insert, error);


--
-- Name: idx_psql_privileges_gran_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_privileges_gran_1 ON psql.privileges_gran USING btree (id_exec);


--
-- Name: idx_psql_privileges_gran_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_privileges_gran_2 ON psql.privileges_gran USING btree (date_insert);


--
-- Name: idx_psql_privileges_gran_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_privileges_gran_5 ON psql.privileges_gran USING btree (id_exec, privilege_type);


--
-- Name: idx_psql_privileges_gran_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_privileges_gran_6 ON psql.privileges_gran USING btree (date_insert, privilege_type);


--
-- Name: idx_psql_schemas_gran_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_schemas_gran_1 ON psql.schemas USING btree (id_exec);


--
-- Name: idx_psql_schemas_gran_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_schemas_gran_2 ON psql.schemas USING btree (date_insert);


--
-- Name: idx_psql_schemas_gran_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_schemas_gran_3 ON psql.schemas USING btree (id_exec, ip_server, port, name, owner);


--
-- Name: idx_psql_schemas_gran_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_schemas_gran_4 ON psql.schemas USING btree (date_insert, ip_server, port, name, owner);


--
-- Name: idx_psql_schemas_gran_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_schemas_gran_5 ON psql.schemas USING btree (id_exec, owner);


--
-- Name: idx_psql_schemas_gran_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_schemas_gran_6 ON psql.schemas USING btree (date_insert, owner);


--
-- Name: idx_psql_sequences_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sequences_1 ON psql.sequences USING btree (id_exec);


--
-- Name: idx_psql_sequences_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sequences_2 ON psql.sequences USING btree (date_insert);


--
-- Name: idx_psql_sequences_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sequences_3 ON psql.sequences USING btree (id_exec, ip_server, port, db, sequence_name);


--
-- Name: idx_psql_sequences_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sequences_4 ON psql.sequences USING btree (date_insert, ip_server, port, db, sequence_name);


--
-- Name: idx_psql_sizes_disks_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_1 ON psql.sizes_disks USING btree (id_exec);


--
-- Name: idx_psql_sizes_disks_10; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_10 ON psql.sizes_disks USING btree (date_insert, use_percentage);


--
-- Name: idx_psql_sizes_disks_11; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_11 ON psql.sizes_disks USING btree (id_exec, avail);


--
-- Name: idx_psql_sizes_disks_12; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_12 ON psql.sizes_disks USING btree (date_insert, avail);


--
-- Name: idx_psql_sizes_disks_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_2 ON psql.sizes_disks USING btree (date_insert);


--
-- Name: idx_psql_sizes_disks_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_3 ON psql.sizes_disks USING btree (id_exec, ip_server, port, size);


--
-- Name: idx_psql_sizes_disks_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_4 ON psql.sizes_disks USING btree (date_insert, ip_server, port, size);


--
-- Name: idx_psql_sizes_disks_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_5 ON psql.sizes_disks USING btree (id_exec, disk_name);


--
-- Name: idx_psql_sizes_disks_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_6 ON psql.sizes_disks USING btree (date_insert, disk_name);


--
-- Name: idx_psql_sizes_disks_7; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_7 ON psql.sizes_disks USING btree (id_exec, size);


--
-- Name: idx_psql_sizes_disks_8; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_sizes_disks_8 ON psql.sizes_disks USING btree (date_insert, size);


--
-- Name: idx_psql_table_constraint_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_table_constraint_1 ON psql.table_constraint USING btree (id_exec);


--
-- Name: idx_psql_table_constraint_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_table_constraint_2 ON psql.table_constraint USING btree (date_insert);


--
-- Name: idx_psql_table_constraint_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_table_constraint_3 ON psql.table_constraint USING btree (id_exec, ip_server, port, db, table_name, column_name);


--
-- Name: idx_psql_table_constraint_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_table_constraint_4 ON psql.table_constraint USING btree (date_insert, ip_server, port, db, table_name, column_name);


--
-- Name: idx_psql_table_foreign_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_table_foreign_1 ON psql.table_foreign USING btree (id_exec);


--
-- Name: idx_psql_table_foreign_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_table_foreign_2 ON psql.table_foreign USING btree (date_insert);


--
-- Name: idx_psql_table_foreign_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_table_foreign_3 ON psql.table_foreign USING btree (id_exec, ip_server, port, db, table_name, column_name);


--
-- Name: idx_psql_table_foreign_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_table_foreign_4 ON psql.table_foreign USING btree (date_insert, ip_server, port, db, table_name, column_name);


--
-- Name: idx_psql_tables_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_1 ON psql.tables USING btree (id_exec);


--
-- Name: idx_psql_tables_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_2 ON psql.tables USING btree (date_insert);


--
-- Name: idx_psql_tables_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_3 ON psql.tables USING btree (id_exec, ip_server, port, db, table_name, type);


--
-- Name: idx_psql_tables_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_4 ON psql.tables USING btree (date_insert, ip_server, port, db, table_name, type);


--
-- Name: idx_psql_tables_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_5 ON psql.tables USING btree (id_exec, owner);


--
-- Name: idx_psql_tables_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_6 ON psql.tables USING btree (date_insert, owner);


--
-- Name: idx_psql_tables_columns_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_columns_1 ON psql.tables_columns USING btree (id_exec);


--
-- Name: idx_psql_tables_columns_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_columns_2 ON psql.tables_columns USING btree (date_insert);


--
-- Name: idx_psql_tables_columns_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_columns_3 ON psql.tables_columns USING btree (id_exec, ip_server, port, db, table_name, column_name);


--
-- Name: idx_psql_tables_columns_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_tables_columns_4 ON psql.tables_columns USING btree (date_insert, ip_server, port, db, table_name, column_name);


--
-- Name: idx_psql_triggers_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_triggers_1 ON psql.triggers USING btree (id_exec);


--
-- Name: idx_psql_triggers_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_triggers_2 ON psql.triggers USING btree (date_insert);


--
-- Name: idx_psql_triggers_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_triggers_3 ON psql.triggers USING btree (id_exec, ip_server, port, db, trigger_name);


--
-- Name: idx_psql_triggers_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_triggers_4 ON psql.triggers USING btree (date_insert, ip_server, port, db, trigger_name);


--
-- Name: idx_psql_triggers_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_triggers_5 ON psql.triggers USING btree (id_exec, ip_server, port, db, owner);


--
-- Name: idx_psql_triggers_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_triggers_6 ON psql.triggers USING btree (date_insert, ip_server, port, db, owner);


--
-- Name: idx_psql_users_1; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_1 ON psql.users USING btree (id_exec);


--
-- Name: idx_psql_users_10; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_10 ON psql.users USING btree (id_exec);


--
-- Name: idx_psql_users_11; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_11 ON psql.users USING btree (date_insert);


--
-- Name: idx_psql_users_12; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_12 ON psql.users USING btree (id_exec, rolsuper);


--
-- Name: idx_psql_users_13; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_13 ON psql.users USING btree (date_insert, rolsuper);


--
-- Name: idx_psql_users_14; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_14 ON psql.users USING btree (id_exec, rolcreaterole);


--
-- Name: idx_psql_users_15; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_15 ON psql.users USING btree (date_insert, rolcreaterole);


--
-- Name: idx_psql_users_16; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_16 ON psql.users USING btree (id_exec, rolcreatedb);


--
-- Name: idx_psql_users_17; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_17 ON psql.users USING btree (date_insert, rolcreatedb);


--
-- Name: idx_psql_users_18; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_18 ON psql.users USING btree (id_exec, rolcanlogin);


--
-- Name: idx_psql_users_19; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_19 ON psql.users USING btree (date_insert, rolcanlogin);


--
-- Name: idx_psql_users_2; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_2 ON psql.users USING btree (date_insert);


--
-- Name: idx_psql_users_20; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_20 ON psql.users USING btree (id_exec, rolconnlimit);


--
-- Name: idx_psql_users_21; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_21 ON psql.users USING btree (date_insert, rolconnlimit);


--
-- Name: idx_psql_users_3; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_3 ON psql.users USING btree (id_exec, ip_server, port, rolname);


--
-- Name: idx_psql_users_4; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_4 ON psql.users USING btree (date_insert, ip_server, port, rolname);


--
-- Name: idx_psql_users_5; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_5 ON psql.users USING btree (id_exec, rolvaliduntil);


--
-- Name: idx_psql_users_6; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_6 ON psql.users USING btree (date_insert, rolvaliduntil);


--
-- Name: idx_psql_users_8; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_8 ON psql.users USING btree (id_exec, rolpassword);


--
-- Name: idx_psql_users_9; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX idx_psql_users_9 ON psql.users USING btree (date_insert, rolpassword);


--
-- Name: index_columns_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX index_columns_idx ON psql.index_columns USING btree (ip_server, port, db, schema_name, table_name, index_name, index_type, column_names, date_insert);


--
-- Name: indexs_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX indexs_idx ON psql.indexs USING btree (ip_server, port, db, schema, index_name, owner, table_name, size, unit_size, create_date, date_insert);


--
-- Name: info_hardware_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX info_hardware_idx ON psql.info_hardware USING btree (ip_server, port, hostname, model_so, mem_ram_kb, uptime, model_cpu, time_zone, ntp_service, date_insert);


--
-- Name: instance_properties_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX instance_properties_idx ON psql.instance_properties USING btree (ip_server, port, dbms, version, architecture_sql, data_directory, log_directory, hba_file_directory, ident_file_directory, binary_directory, status_systemctl, uptime_psql, last_time_reload, date_insert);


--
-- Name: pg_hba_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX pg_hba_idx ON psql.pg_hba USING btree (ip_server, port, line_number, type, database, user_name, address, netmask, auth_method, error, last_time_reload, date_insert);


--
-- Name: pg_settings_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX pg_settings_idx ON psql.pg_settings USING btree (ip_server, port, name, setting, category, date_insert);


--
-- Name: postgresql_conf2_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX postgresql_conf2_idx ON psql.postgresql_conf USING btree (ip_server, port, name, setting, applied, error, uptime_psql, date_insert);


--
-- Name: privileges_gran_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX privileges_gran_idx ON psql.privileges_gran USING btree (ip_server, port, grantor, grantee, type, schema_name, object_name, privilege_type, is_grantable, date_insert);


--
-- Name: schemas_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX schemas_idx ON psql.schemas USING btree (ip_server, port, name, owner, date_insert);


--
-- Name: sequences_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX sequences_idx ON psql.sequences USING btree (ip_server, port, db, sequence_schema, sequence_name, data_type, numeric_precision, numeric_precision_radix, numeric_scale, minimum_value, maximum_value, increment, cycle_option, date_insert);


--
-- Name: sizes_disks_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX sizes_disks_idx ON psql.sizes_disks USING btree (ip_server, port, size, used, avail, use_percentage, disk_name, date_insert);


--
-- Name: table_columns_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX table_columns_idx ON psql.tables_columns USING btree (ip_server, port, db, table_schema, table_name, column_name, ordinal_position, secuence, is_nullable, data_type, date_insert);


--
-- Name: table_constraint_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX table_constraint_idx ON psql.table_constraint USING btree (ip_server, port, db, table_schema, table_name, column_name, date_insert);


--
-- Name: table_fereign_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX table_fereign_idx ON psql.table_foreign USING btree (ip_server, port, db, table_schema, table_name, column_name, foreign_table_schema, foreign_table_name, foreign_column_name, date_insert);


--
-- Name: tables_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX tables_idx ON psql.tables USING btree (ip_server, port, db, schema, table_name, type, owner, size, unit_size, create_date, date_insert);


--
-- Name: triggers_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX triggers_idx ON psql.triggers USING btree (ip_server, port, db, trigger_name, owner, event_object_table, action_statement);


--
-- Name: users_idx; Type: INDEX; Schema: psql; Owner: postgres
--

CREATE INDEX users_idx ON psql.users USING btree (ip_server, port, rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin, rolpassword, rolvaliduntil, date_insert);


--
-- Name: idx_pedidos_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_gin ON public.pedidos USING gin (to_tsvector('spanish'::regconfig, (estado)::text));


--
-- Name: unique_cat_server_ip_server_port_dbms; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_cat_server_ip_server_port_dbms ON public.cat_server USING btree (ip_server, port, dbms);


--
-- Name: details_connection trig_update_sequences_details_connection; Type: TRIGGER; Schema: fdw_conf; Owner: postgres
--

CREATE TRIGGER trig_update_sequences_details_connection AFTER DELETE ON fdw_conf.details_connection FOR EACH STATEMENT EXECUTE FUNCTION fdw_conf.fun_update_sequences_details_connection();


--
-- Name: report_connection trig_update_sequences_report_connection; Type: TRIGGER; Schema: fdw_conf; Owner: postgres
--

CREATE TRIGGER trig_update_sequences_report_connection AFTER DELETE ON fdw_conf.report_connection FOR EACH STATEMENT EXECUTE FUNCTION fdw_conf.fun_update_sequences_report_connection();


--
-- Name: ctl_querys trigger_ajustar_secuencia_ctl_querys; Type: TRIGGER; Schema: fdw_conf; Owner: postgres
--

CREATE TRIGGER trigger_ajustar_secuencia_ctl_querys AFTER DELETE ON fdw_conf.ctl_querys FOR EACH STATEMENT EXECUTE FUNCTION fdw_conf.fun_update_sequences_ctl_querys();


--
-- Name: cat_server trig_update_sequences_public_cat_server; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trig_update_sequences_public_cat_server AFTER DELETE ON public.cat_server FOR EACH STATEMENT EXECUTE FUNCTION public.fun_update_sequences_public_cat_server();


--
-- Name: cat_server trigger_cambios_cat_server; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_cambios_cat_server AFTER INSERT OR DELETE OR UPDATE ON public.cat_server FOR EACH ROW EXECUTE FUNCTION cdc.register_change_cat_server();


--
-- Name: cat_server trigger_name; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_name BEFORE TRUNCATE ON public.cat_server FOR EACH STATEMENT EXECUTE FUNCTION public.trigger_function_cat_server_truncate();


--
-- Name: ctl_remote_users fk_cat_remote_users; Type: FK CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_remote_users
    ADD CONSTRAINT fk_cat_remote_users FOREIGN KEY (dbms) REFERENCES fdw_conf.ctl_dbms(dbms);


--
-- Name: ctl_ports fk_cliente; Type: FK CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_ports
    ADD CONSTRAINT fk_cliente FOREIGN KEY (dbms) REFERENCES fdw_conf.ctl_dbms(dbms);


--
-- Name: ctl_querys fk_ctl_querys_fun_task_name; Type: FK CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.ctl_querys
    ADD CONSTRAINT fk_ctl_querys_fun_task_name FOREIGN KEY (fun_task_name) REFERENCES fdw_conf.funs_tanks(fun_name);


--
-- Name: scan_rules_query fk_scan_rules_query_id_query; Type: FK CONSTRAINT; Schema: fdw_conf; Owner: postgres
--

ALTER TABLE ONLY fdw_conf.scan_rules_query
    ADD CONSTRAINT fk_scan_rules_query_id_query FOREIGN KEY (id_query) REFERENCES fdw_conf.ctl_querys(id);


--
-- Name: cat_server fk_ctl_server; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_server
    ADD CONSTRAINT fk_ctl_server FOREIGN KEY (id_remote_user) REFERENCES fdw_conf.ctl_remote_users(id);


--
-- Name: cat_server fk_ctl_server_port; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cat_server
    ADD CONSTRAINT fk_ctl_server_port FOREIGN KEY (dbms) REFERENCES fdw_conf.ctl_dbms(dbms);


--
-- Name: trigger_ddl_cat_server; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER trigger_ddl_cat_server ON ddl_command_end
         WHEN TAG IN ('DROP TABLE', 'ALTER TABLE')
   EXECUTE FUNCTION cdc.registrar_ddl();


ALTER EVENT TRIGGER trigger_ddl_cat_server OWNER TO postgres;

--
-- PostgreSQL database dump complete
--

