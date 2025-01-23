-- La cláusula FORALL permite sin cambio de contexto realizar una sentencia DML de manera masiva.
-- Insert
DECLARE
 CURSOR s_cur IS
 SELECT *
 FROM servers;
 
 TYPE fetch_array IS TABLE OF s_cur%ROWTYPE;
 s_array fetch_array;
BEGIN
  OPEN s_cur;
  LOOP
    FETCH s_cur BULK COLLECT INTO s_array LIMIT 1000;
 
    FORALL i IN 1..s_array.COUNT
    INSERT INTO servers2 VALUES s_array(i);
 
    EXIT WHEN s_cur%NOTFOUND;
  END LOOP;
  CLOSE s_cur;
  COMMIT;
END;
/
 
 
--FORALL Update      
SELECT DISTINCT srvr_id
FROM servers2
ORDER BY 1;
 
DECLARE
 TYPE myarray IS TABLE OF servers2.srvr_id%TYPE
 INDEX BY BINARY_INTEGER;
 
 d_array myarray;
BEGIN
  d_array(1) := 608;
  d_array(2) := 610;
  d_array(3) := 612;
 
  FORALL i IN d_array.FIRST .. d_array.LAST
  UPDATE servers2
  SET srvr_id = 0
  WHERE srvr_id = d_array(i);
 
  COMMIT;
END;
/
 
SELECT srvr_id
FROM servers2
WHERE srvr_id = 0;
 
 
--FORALL Delete       
SET serveroutput ON
 
DECLARE
 TYPE myarray IS TABLE OF servers2.srvr_id%TYPE
 INDEX BY BINARY_INTEGER;
 
 d_array myarray;
BEGIN
  d_array(1) := 614;
  d_array(2) := 615;
  d_array(3) := 616;
 
  FORALL i IN d_array.FIRST .. d_array.LAST
  DELETE servers2
  WHERE srvr_id = d_array(i);
 
  COMMIT;
 
  FOR i IN d_array.FIRST .. d_array.LAST LOOP
    DBMS_OUTPUT.put_line('Iteration #' || i || ' deleted ' ||
    SQL%BULK_ROWCOUNT(i) || ' rows.');
  END LOOP;
END;
/
 
SELECT srvr_id
FROM servers2
WHERE srvr_id IN (614, 615, 616);

-- Delete 2
DECLARE
  TYPE NumList IS VARRAY(20) OF NUMBER;
  depts NumList := NumList(10, 30, 70);  -- department numbers
BEGIN
  FORALL i IN depts.FIRST..depts.LAST
    DELETE FROM employees_temp
    WHERE department_id = depts(i);
  
   COMMIT;

   FOR i IN depts.FIRST..depts.LAST LOOP
     dbms_output.put_line('Iteration #' || i || ' deleted ' ||
     SQL%BULK_ROWCOUNT(i) || ' rows.');
   END LOOP;

END;

----------------------------------------------------------------
-- Test Bulk binds usando records - INSERTS
----------------------------------------------------------------
-- tabla ejemplo
CREATE TABLE forall_test (
  id           NUMBER(10),
  code         VARCHAR2(10),
  description  VARCHAR2(50));

ALTER TABLE forall_test ADD (
  CONSTRAINT forall_test_pk PRIMARY KEY (id));

ALTER TABLE forall_test ADD (
  CONSTRAINT forall_test_uk UNIQUE (code));
--

DECLARE
  TYPE t_forall_test_tab IS TABLE OF forall_test%ROWTYPE;

  l_tab    t_forall_test_tab := t_forall_test_tab();
  l_start  NUMBER;
  l_size   NUMBER            := 10000;
BEGIN
  -- Populate collection.
  FOR i IN 1 .. l_size LOOP
    l_tab.extend;

    l_tab(l_tab.last).id          := i;
    l_tab(l_tab.last).code        := TO_CHAR(i);
    l_tab(l_tab.last).description := 'Description: ' || TO_CHAR(i);
  END LOOP;

  EXECUTE IMMEDIATE 'TRUNCATE TABLE forall_test';

  -- Time regular inserts.
  l_start := DBMS_UTILITY.get_time;

  FOR i IN l_tab.first .. l_tab.last LOOP
    INSERT INTO forall_test (id, code, description)
    VALUES (l_tab(i).id, l_tab(i).code, l_tab(i).description);
    --INSERT INTO forall_test VALUES l_tab(i);
  END LOOP;

  DBMS_OUTPUT.put_line('Normal Inserts: ' || (DBMS_UTILITY.get_time - l_start));
  
  EXECUTE IMMEDIATE 'TRUNCATE TABLE forall_test';

  -- Time bulk inserts.  
  l_start := DBMS_UTILITY.get_time;

  FORALL i IN l_tab.first .. l_tab.last
    INSERT INTO forall_test VALUES l_tab(i);

  DBMS_OUTPUT.put_line('Bulk Inserts  : ' || (DBMS_UTILITY.get_time - l_start));

  COMMIT;
END;
/* Normal Inserts: 305
   Bulk Inserts  : 14 */

----------------------------------------------------------------
-- Test Bulk binds usando records - UPDATES
----------------------------------------------------------------
DECLARE
  TYPE t_id_tab IS TABLE OF forall_test.id%TYPE;
  TYPE t_forall_test_tab IS TABLE OF forall_test%ROWTYPE;

  l_id_tab  t_id_tab          := t_id_tab();
  l_tab     t_forall_test_tab := t_forall_test_tab ();
  l_start   NUMBER;
  l_size    NUMBER            := 10000;
BEGIN
  -- Populate collections.
  FOR i IN 1 .. l_size LOOP
    l_id_tab.extend;
    l_tab.extend;

    l_id_tab(l_id_tab.last)       := i;
    l_tab(l_tab.last).id          := i;
    l_tab(l_tab.last).code        := TO_CHAR(i);
    l_tab(l_tab.last).description := 'Description: ' || TO_CHAR(i);
  END LOOP;

  -- Time regular updates.
  l_start := DBMS_UTILITY.get_time;

  FOR i IN l_tab.first .. l_tab.last LOOP
    UPDATE forall_test
    SET    ROW = l_tab(i)
    WHERE  id  = l_tab(i).id;
  END LOOP;
  
  DBMS_OUTPUT.put_line('Normal Updates : ' || 
                       (DBMS_UTILITY.get_time - l_start));

  l_start := DBMS_UTILITY.get_time;

  -- Time bulk updates.
  FORALL i IN l_tab.first .. l_tab.last
    UPDATE forall_test
    SET    ROW = l_tab(i)
    WHERE  id  = l_id_tab(i);
  
  DBMS_OUTPUT.put_line('Bulk Updates   : ' || 
                       (DBMS_UTILITY.get_time - l_start));

  COMMIT;
END;

-- Normal Updates : 235
-- Bulk Updates   : 20

/*---------------------------------------------------------------
-- SQL%BULK_ROWCOUNT
----------------------------------------------------------------
El atributo SQL% BULK_ROWCOUNT del cursor proporciona información granular sobre las filas afectadas por cada 
iteración de la instrucción FORALL. Cada fila de la colección tiene una fila correspondiente en 
el atributo de cursor SQL%BULK_ROWCOUNT.

El código siguiente crea una tabla de prueba como una copia de la vista ALL_USERS. A continuación, intenta 
eliminar 5 filas de la tabla basándose en el contenido de una colección. A continuación, realiza un bucle a 
través del atributo de cursor SQL% BULK_ROWCOUNT mirando el número de filas afectadas por cada eliminación.*/

-- Tabla de trabajo
CREATE TABLE bulk_rowcount_test AS
SELECT *
FROM   all_users;

-- Proceso
DECLARE
  TYPE t_array_tab IS TABLE OF VARCHAR2(30);
  l_array t_array_tab := t_array_tab('SCOTT', 'SYS',
                                     'SYSTEM', 'DBSNMP', 'BANANA'); 
BEGIN
  -- Perform bulk delete operation.
  FORALL i IN l_array.first .. l_array.last 
    DELETE FROM bulk_rowcount_test
    WHERE username = l_array(i);

  -- Report affected rows.
  FOR i IN l_array.first .. l_array.last LOOP
    DBMS_OUTPUT.put_line('Element: ' || RPAD(l_array(i), 15, ' ') ||
      ' Rows affected: ' || SQL%BULK_ROWCOUNT(i));
  END LOOP;
END;

--Element: SCOTT           Rows affected: 1
--Element: SYS             Rows affected: 1
--Element: SYSTEM          Rows affected: 1
--Element: DBSNMP          Rows affected: 1
--Element: BANANA          Rows affected: 0

/*------------------------------------------------------------------------------
-- SAVE EXCEPTIONS and SQL%BULK_EXCEPTION
-------------------------------------------------------------------------------
Vimos cómo la sintaxis de FORALL nos permite realizar operaciones DML masivas, pero ¿qué sucede si una de 
esas operaciones individuales da como resultado una excepción? Si no hay un manejador de excepciones, todo 
el trabajo realizado por la operación de granel actual se deshace. Si hay un manejador de excepciones, se 
mantiene el trabajo realizado antes de la excepción, pero no se procesa más. Ninguna de estas situaciones 
es muy satisfactoria, por lo que en su lugar debemos usar la cláusula SAVE EXCEPTIONS para capturar las 
excepciones y permitirnos continuar más allá de ellas. Posteriormente, podemos ver las excepciones haciendo 
referencia al atributo de cursor SQL% BULK_EXCEPTION. Para ver esto en acción, cree la tabla siguiente.*/

-- Tabla de trabajo
CREATE TABLE exception_test (
  id  NUMBER(10) NOT NULL
);

/* El código siguiente crea una colección con 100 filas, pero establece el valor de las filas 50 y 51 en NULL. 
Dado que la tabla anterior no permite valores nulos, estas filas resultarán en una excepción. La cláusula 
SAVE EXCEPTIONS permite que la operación masiva continúe más allá de las excepciones, pero si se generaron 
excepciones en toda la operación, saltará al manejador de excepciones una vez que se complete la operación. 
En este caso, el manejador de excepción sólo realiza un bucle a través del atributo SQL% BULK_EXCEPTION para 
ver qué errores se produjeron.*/

DECLARE
  TYPE t_tab IS TABLE OF exception_test%ROWTYPE;

  l_tab          t_tab := t_tab();
  l_error_count  NUMBER;
  
  ex_dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors, -24381);
BEGIN
  -- Fill the collection.
  FOR i IN 1 .. 100 LOOP
    l_tab.extend;
    l_tab(l_tab.last).id := i;
  END LOOP;

  -- Cause a failure.
  l_tab(50).id := NULL;
  l_tab(51).id := NULL;
  
  EXECUTE IMMEDIATE 'TRUNCATE TABLE exception_test';

  -- Perform a bulk operation.
  BEGIN
    FORALL i IN l_tab.first .. l_tab.last SAVE EXCEPTIONS
      INSERT INTO exception_test
      VALUES l_tab(i);
  EXCEPTION
    WHEN ex_dml_errors THEN
      l_error_count := SQL%BULK_EXCEPTIONS.count;
      DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count);
      FOR i IN 1 .. l_error_count LOOP
        DBMS_OUTPUT.put_line('Error: ' || i || 
          ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index ||
          ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
      END LOOP;
  END;
END;

--Number of failures: 2
--Error: 1 Array Index: 50 Message: ORA-01400: cannot insert NULL into ()
--Error: 2 Array Index: 51 Message: ORA-01400: cannot insert NULL into ()
