/*
SELECT
pid,
usename,
pg_stat_activity.query_start,
now() - pg_stat_activity.query_start AS query_time,
query,
wait_event_type , wait_event
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

*/
 




COPY (
SELECT
pid , -- procpid, --- pid
usename,
pg_stat_activity.query_start,
now() - pg_stat_activity.query_start AS query_time,
query --current_query,
--waiting
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes') TO '/tmp/receta/14_Find_Long_Running_queries_more_than_5_minutes.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);



 
 
 /*
 

  psql -c "SELECT procpid ,  usename, pg_stat_activity.query_start, now() - pg_stat_activity.query_start AS query_time, current_query FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'" | grep -v "+" | tr "|" "," > /tmp/receta/14_Find_Long_Running_queries_more_than_5_minutes.csv
  
  
  */