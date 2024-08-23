SELECT
	idx.indrelid::regclass AS Nombre_tabla,
    idx.indexrelid::regclass AS Nombre_Indice,
    pg_get_indexdef(idx.indexrelid) AS Script_Index,
    (
        SELECT string_agg(att.attname, ', ' ORDER BY att.attnum)
        FROM pg_attribute AS att
        WHERE att.attrelid = idx.indrelid
        AND att.attnum = ANY(idx.indkey)
    ) AS Columnas,
    idx.indisunique AS is_unique,
    idx.indisprimary AS is_primary_key,
    idx.indisclustered AS is_clustered,
    idx.indnatts AS Numero_Columnas,
    idx.indexprs IS NOT NULL OR idx.indkey::int[] @> ARRAY[0] AS is_functional,
    CASE
        WHEN pg_size_pretty(pg_relation_size(idx.indexrelid)) <> '0 bytes' THEN pg_size_pretty(pg_relation_size(idx.indexrelid))
        ELSE 'N/A'
    END AS Tamano_Indice,
    CASE
        WHEN idx.indexrelid IN (
            SELECT indexrelid
            FROM pg_stat_user_indexes
        ) THEN 'Usado'
        ELSE 'No Usado'
    END AS uso_Indice
FROM
    pg_index AS idx
WHERE
    NOT idx.indisprimary
    AND NOT idx.indisunique
    AND idx.indisvalid
    AND idx.indpred IS NULL
    AND NOT EXISTS (
        SELECT 1
        FROM pg_stat_user_indexes AS stat
        WHERE idx.indexrelid = stat.indexrelid
    );