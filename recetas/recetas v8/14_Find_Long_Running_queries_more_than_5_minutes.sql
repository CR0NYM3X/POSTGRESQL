SELECT
procpid,
usename,
pg_stat_activity.query_start,
now() - pg_stat_activity.query_start AS query_time,
current_query
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';