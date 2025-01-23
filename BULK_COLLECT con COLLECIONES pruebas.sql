DECLARE
  
  CURSOR cur IS
   SELECT * FROM customers;
   
  TYPE t_bulk_collect_test_tab IS TABLE OF customers%ROWTYPE;

  l_tab   t_bulk_collect_test_tab := t_bulk_collect_test_tab();
  l_start NUMBER;
    
BEGIN
  --------------------------------
  -- Time a regular population.
  --------------------------------
  l_start := DBMS_UTILITY.get_time;

  FOR cur_rec IN cur LOOP
    l_tab.extend;
    l_tab(l_tab.last) := cur_rec;
  END LOOP;

  DBMS_OUTPUT.put_line('Regular (' || l_tab.count || ' rows): ' ||
                       (DBMS_UTILITY.get_time - l_start));
  
  FOR i IN l_tab.first .. l_tab.last LOOP    
    dbms_output.put_line(l_tab(i).name || ' ' ||l_tab(i).fuente || ' ' ||l_tab(i).marca);  
  END LOOP;
  --------------------------------
  -- Time bulk population.  
  --------------------------------
  l_start := DBMS_UTILITY.get_time;

  SELECT * BULK COLLECT INTO l_tab FROM customers;

  DBMS_OUTPUT.put_line('Bulk    (' || l_tab.count || ' rows): ' ||
                       (DBMS_UTILITY.get_time - l_start));
  
  FOR i IN l_tab.first .. l_tab.last LOOP    
    dbms_output.put_line(l_tab(i).name || ' ' ||l_tab(i).fuente || ' ' ||l_tab(i).marca);  
  END LOOP;
  --------------------------------
  -- Time bulk population Cursor.  
  --------------------------------
  l_start := DBMS_UTILITY.get_time;
  
  OPEN cur;
  LOOP
    
    FETCH cur BULK COLLECT
      INTO l_tab LIMIT 5;
    
    -- Asigna valores segun campos
    FOR i IN 1 .. l_tab.count LOOP
      
      IF l_tab(i).name IN ('Khilan','Chaitali') THEN
        l_tab(i).fuente := 'SI';
        l_tab(i).marca := 'COLOMBIA';
      ELSE 
        l_tab(i).fuente := 'NO';
        l_tab(i).marca := 'ITALIA';
      END IF;
      
    END LOOP;
    
    -- Actualiza tabla
    FORALL i IN 1 .. l_tab.count
      UPDATE customers
        SET fuente = l_tab(i).fuente,
            marca = l_tab(i).marca
        WHERE id = l_tab(i).id;
        
    EXIT WHEN cur%NOTFOUND;
  END LOOP;
  
  CLOSE cur;
  COMMIT;

  DBMS_OUTPUT.put_line('Bulk    (' || l_tab.count || ' rows): ' ||
                       (DBMS_UTILITY.get_time - l_start));
  
  FOR i IN l_tab.first .. l_tab.last LOOP    
    dbms_output.put_line(l_tab(i).name || ' ' ||l_tab(i).fuente || ' ' ||l_tab(i).marca);  
  END LOOP;  
  
END;
