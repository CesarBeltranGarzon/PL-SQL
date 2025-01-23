SELECT *
  FROM xmltable('for $i in 1 to xs:int(A) return $i' passing
                xmlelement(a, 31) columns i integer path '.');
                
SELECT TO_CHAR(sysdate + datos.i, 'dd/mm/yyyy') fecha
  FROM xmltable('for $i in 1 to xs:int(A) return $i' passing
                xmlelement(a, sysdate - (sysdate - 31)) columns i integer path '.') datos
  
SELECT * FROM xmltable('"CESAR B","AAA"' COLUMNS i VARCHAR2(100) path '.');

select to_number(column_value) as IDs from xmltable('106138250,106138256,106138252');	      
