--Creación type varray en base de datos
CREATE OR REPLACE TYPE ARRAY_PRUEBA AS VARRAY(3) OF VARCHAR2(10);

--Uso Varray en bloque PL/SQL
DECLARE
   TYPE namesarray IS VARRAY(5) OF VARCHAR2(10);
   TYPE grades IS VARRAY(5) OF INTEGER;
   names namesarray;
   marks grades;
   total INTEGER;
BEGIN
   names := namesarray('Kavita', 'Pritam', 'Ayan', 'Rishav', 'Aziz');
   marks:= grades(98, 97, 78, 87, 92);
   total := names.COUNT;
   DBMS_OUTPUT.PUT_LINE('Total '|| total || ' Students');
   FOR i IN 1 .. total LOOP
      DBMS_OUTPUT.PUT_LINE('Student: ' || names(i) || ' Marks: ' || marks(i));
   END LOOP;
END;

/*
•	En el entorno de Oracle, el índice de partida para varrays es siempre 1.
•	Puede inicializar los elementos VARRAY utilizando el método constructor del tipo VARRAY, que tiene el mismo nombre que el VARRAY.
•	Varrays son matrices unidimensionales.
•	Un VARRAY es nulo cuando se declara y debe ser inicializado antes puede hacer referencia a sus elementos.
*/

--Elementos de un VARRAY también podría ser una ROWTYPE% de cualquier tabla de base de datos 
--o TIPO% de cualquier campo de la tabla de base de datos. El siguiente ejemplo ilustra el concepto:
DECLARE
   CURSOR c_customers IS
     SELECT  name FROM customers;
   TYPE c_list IS VARRAY(6) OF customers.name%TYPE;
   name_list c_list := c_list();
   counter INTEGER  := 0;
BEGIN
   FOR n IN c_customers LOOP
      counter := counter + 1;
      name_list.EXTEND;
      name_list(counter) := n.name;
      DBMS_OUTPUT.PUT_LINE   ('Customer('||counter ||'):'||name_list(counter));
   END LOOP;
END;
