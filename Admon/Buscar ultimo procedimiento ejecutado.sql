-- Ultimos Procesos ejecutados
-- Puede realizar acción en civica y reviar acá que paquete llama
SELECT sql_id, SQL_FULLTEXT, PARSING_SCHEMA_NAME, service, module, object_status, last_active_time, LAST_LOAD_TIME, first_load_time, hash_value
FROM SYS.V_$SQL 
WHERE last_active_time IS NOT NULL
  AND module = 'w3wp.exe'
  AND UPPER(sql_fulltext) LIKE '%BEGIN%'
ORDER BY last_active_time DESC, last_load_time DESC