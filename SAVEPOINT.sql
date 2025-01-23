/* SAVEPOINT
Sirve para marca un punto de referencia en la transacci�n para hacer un ROLLBACK parcial
*/

-- Objetos trabajo
CREATE TABLE emp_name AS SELECT employee_id, last_name, salary FROM employees;
CREATE UNIQUE INDEX empname_ix ON emp_name (employee_id);

-- Proceso
-- Marca un Savepoint antes de realizar una inserci�n. Si la instrucci�n INSERT intenta almacenar un valor 
-- duplicado en la columna employee_id, se genera la excepci�n predefinida DUP_VAL_ON_INDEX. En ese caso, 
-- volver� al punto de salvaguarda, deshaciendo s�lo la inserci�n.
DECLARE
   emp_id        employees.employee_id%TYPE;
   emp_lastname  employees.last_name%TYPE;
   emp_salary    employees.salary%TYPE;
BEGIN
   SELECT employee_id, last_name, salary INTO emp_id, emp_lastname,emp_salary 
    FROM employees 
    WHERE employee_id = 120;
   
   UPDATE emp_name SET salary = salary * 1.1 WHERE employee_id = emp_id;
   
   DELETE FROM emp_name WHERE employee_id = 130;
   
   SAVEPOINT do_insert;
   
   INSERT INTO emp_name VALUES (emp_id, emp_lastname, emp_salary);
EXCEPTION
  
   WHEN DUP_VAL_ON_INDEX THEN
      ROLLBACK TO do_insert;
      DBMS_OUTPUT.PUT_LINE('Insert has been rolled back');
END;

------------------------------------------------------------
-- SET TRANSACTION
------------------------------------------------------------
/*  Utilice la instrucci�n SET TRANSACTION para iniciar una transacci�n de solo lectura o 
lectura-escritura, establecer un nivel de aislamiento o asignar la transacci�n actual a un segmento de 
retroceso especificado. Las transacciones de s�lo lectura son �tiles para ejecutar varias consultas 
mientras otros usuarios actualizan las mismas tablas.

Durante una transacci�n de solo lectura, todas las consultas se refieren a la misma instant�nea de la base 
de datos, proporcionando una vista de varias tablas, consulta m�ltiple y coherente de lectura. Otros usuarios
pueden continuar consultando o actualizando datos como de costumbre. Una confirmaci�n o anulaci�n finaliza la 
transacci�n. En el ejemplo 6-40, un administrador de tienda usa una transacci�n de s�lo lectura para recopilar 
totales de orden para el d�a, la semana pasada y el mes pasado. Los totales no se ven afectados por otros 
usuarios que actualizan la base de datos durante la transacci�n.*/

DECLARE
   daily_order_total   NUMBER(12,2);
   weekly_order_total  NUMBER(12,2); 
   monthly_order_total NUMBER(12,2);
BEGIN
   COMMIT; -- ends previous transaction
   
   SET TRANSACTION READ ONLY NAME 'Calculate Order Totals';
   
   SELECT SUM (order_total) INTO daily_order_total FROM orders
     WHERE order_date = SYSDATE;
     
   SELECT SUM (order_total) INTO weekly_order_total FROM orders
     WHERE order_date = SYSDATE - 7;
     
   SELECT SUM (order_total) INTO monthly_order_total FROM orders
     WHERE order_date = SYSDATE - 30;
     
   COMMIT; -- ends read-only transaction
END;

/* La instrucci�n SET TRANSACTION debe ser la primera instrucci�n SQL en una transacci�n de s�lo lectura y 
s�lo puede aparecer una vez en una transacci�n. Si establece una transacci�n en READ ONLY, las consultas 
posteriores solo ver�n los cambios realizados antes de que se inicie la transacci�n. El uso de READ ONLY no 
afecta a otros usuarios o transacciones.

Restricciones en SET TRANSACTION
----------------------------------
S�lo se permiten las sentencias SELECT INTO, OPEN, FETCH, CLOSE, LOCK TABLE, COMMIT y ROLLBACK en una 
transacci�n de s�lo lectura. Las consultas no pueden ser FOR UPDATE.*/


