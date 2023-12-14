/*SELECT   relname, seq_scan, seq_tup_read, 
      idx_scan, idx_tup_fetch, 
      seq_tup_read / seq_scan 
  FROM   pg_stat_user_tables 
  WHERE   seq_scan > 0 
  ORDER BY seq_tup_read DESC;
  
  
  */
  
  
  
  
  COPY (SELECT   relname, seq_scan, seq_tup_read, 
      idx_scan, idx_tup_fetch, 
      seq_tup_read / seq_scan 
  FROM   pg_stat_user_tables 
  WHERE   seq_scan > 0 
  ORDER BY seq_tup_read DESC) TO '/tmp/receta/15_Missing_Indexes.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER);
  
  /*
  
  psql -c "SELECT   relname, seq_scan, seq_tup_read,       idx_scan, idx_tup_fetch,       seq_tup_read / seq_scan   FROM   pg_stat_user_tables   WHERE   seq_scan > 0   ORDER BY seq_tup_read DESC " | grep -v "+" | tr "|" "," > /tmp/receta/15_Missing_Indexes.csv
 
 
 */