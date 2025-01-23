SELECT LISTAGG(table_name, ',') WITHIN GROUP(ORDER BY table_name) nombre
FROM all_tables
WHERE owner = 'AXIOMDATA'
AND ROWNUM <= 100


SELECT LISTAGG(DISTINCT table_name, ',') WITHIN GROUP(ORDER BY table_name) nombre
FROM all_tables
WHERE owner = 'AXIOMDATA'
AND ROWNUM <= 100