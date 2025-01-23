SELECT *
FROM 
(
    SELECT
      s.*,
      row_number() OVER ( PARTITION BY flag_movimiento ORDER BY flag_movimiento NULLS LAST ) RANK
    FROM tbl_proc_scl s
)
WHERE RANK < 11
