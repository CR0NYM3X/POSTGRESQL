

 # Ver retraso de replica standby en KB
 ```
---  Esto te da el retraso en bytes de una replica, que puedes dividir entre 1024 para obtener KB.
 SELECT application_name,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS delay_bytes
FROM pg_stat_replication;
```
