COPY (
select t0.tgname as Nombre_Trigger,  t2.relname as Tabla_Relacionada, prosrc as Codigo
from pg_trigger t0
inner join pg_proc t1 on t1.oid = t0.tgfoid
inner join pg_class t2 on t0.tgrelid = t2.oid
 )TO '/tmp/recetas/triggers.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);
 