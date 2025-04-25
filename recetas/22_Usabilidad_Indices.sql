-- --------------------------------------------------------------------------------------------------------- --
-- Script para conocer el uso de los indices de la BBDD.
-- Fecha de creacion: septiembre 2024.
-- --------------------------------------------------------------------------------------------------------- --

WITH index_usage AS (
    SELECT
        schemaname,
        relname AS table_name,
        indexrelname AS index_name,
        idx_scan,
        idx_tup_read,
        idx_tup_fetch,
        pg_relation_size(indexrelid) AS index_size_bytes
    FROM
        pg_stat_user_indexes
    WHERE
        schemaname = 'public'
),
table_stats AS (
    SELECT
        schemaname,
        relname,
        seq_scan,
        seq_tup_read,
        n_live_tup
    FROM
        pg_stat_user_tables
    WHERE
        schemaname = 'public'
)
SELECT
    iu.schemaname,
    iu.table_name,
    iu.index_name,
    iu.idx_scan,
    iu.idx_tup_read,
    iu.idx_tup_fetch,
    ts.seq_scan,
    ts.seq_tup_read,
    ts.n_live_tup,
    pg_size_pretty(iu.index_size_bytes) AS index_size,
    CASE
        WHEN iu.idx_scan = 0 THEN 'Nunca usado'
        WHEN iu.idx_scan < ts.seq_scan THEN 'Poco usado'
        ELSE 'Usado frecuentemente'
    END AS usage_status
FROM
    index_usage iu
JOIN
    table_stats ts ON iu.schemaname = ts.schemaname AND iu.table_name = ts.relname
ORDER BY
    iu.idx_scan ASC,
    iu.index_size_bytes DESC;
 