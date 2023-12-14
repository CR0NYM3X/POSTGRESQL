SELECT   relname, seq_scan, seq_tup_read, 
      idx_scan, idx_tup_fetch, 
      seq_tup_read / seq_scan 
  FROM   pg_stat_user_tables 
  WHERE   seq_scan > 0 
  ORDER BY seq_tup_read DESC;