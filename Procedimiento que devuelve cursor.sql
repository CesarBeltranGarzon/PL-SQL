-- Procedimiento
CREATE OR REPLACE PROCEDURE proc_devuelve_cursor(par1    IN VARCHAR2,
                                                 par2    IN NUMBER,
                                                 cursor1 OUT SYS_REFCURSOR) AS
BEGIN
  OPEN cursor1 FOR
    SELECT *
      FROM customers
     WHERE name = NVL(par1, name)
       AND age = NVL(par2, age);
END proc_devuelve_cursor;

-- Ejecutar test y se observa el cursor devuelto

-- ó imprimirlo por pantalla
/*DECLARE
  v_cursor SYS_REFCURSOR;
  c_cursor SYS_REFCURSOR;
BEGIN
  proc_devuelve_cursor('Khilan',25,v_cursor);
  
  FOR r_cursor IN c_cursor LOOP
    dbms_output.put_line(v_cursor.id || ' ' || v_cursor.name || ' ' || v_cursor.age || ' ' || v_cursor.address || ' ' || v_cursor.salary);
  END LOOP;
  
  \*OPEN v_cursor;
  LOOP
    FETCH v_cursor
    BULK COLLECT INTO c_cursor;
    EXIT WHEN v_cursor%NOTFOUND;
  END LOOP;
  CLOSE v_cursor;*\

END;*/
