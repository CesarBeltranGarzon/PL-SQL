-- Objetos que referencian una columna de una tabla
SELECT d.type, d.name, s.line as line_number, s.text
  FROM dba_dependencies d
  LEFT JOIN dba_source s
    ON s.name = d.name
 WHERE d.referenced_name = 'MYTABLE'
   AND upper(s.text) like '%COL0%'
 ORDER BY d.type, d.name