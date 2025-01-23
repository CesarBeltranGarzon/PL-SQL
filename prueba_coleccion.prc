CREATE OR REPLACE PROCEDURE prueba_coleccion IS

    TYPE fetch_inconsistencias IS TABLE OF customers%ROWTYPE;
    c_inconsistencias fetch_inconsistencias;

  BEGIN
    -- Carga coleccion
    SELECT * BULK COLLECT INTO c_inconsistencias FROM customers;
    
    -- Lee Coleccion y asigna valores
    FOR i IN c_inconsistencias.first .. c_inconsistencias.last LOOP    
      
      IF c_inconsistencias(i).name = 'Hardik' THEN
        c_inconsistencias(i).fuente := 'INDIA';
        c_inconsistencias(i).marca := 'NO';
      ELSIF c_inconsistencias(i).name = 'Khilan' THEN
        c_inconsistencias(i).fuente := 'IRAK';
        c_inconsistencias(i).marca := 'NO';
      ELSE
        c_inconsistencias(i).fuente := 'COLOMBIA';
        c_inconsistencias(i).marca := 'SI';
      END IF;
      
    END LOOP;
    
    -- Imprime valores
    FOR i IN c_inconsistencias.first .. c_inconsistencias.last LOOP
      dbms_output.put_line(c_inconsistencias(i).name || ' ' ||c_inconsistencias(i).fuente || ' ' ||c_inconsistencias(i).marca);  
    END LOOP;
    
END;
/
