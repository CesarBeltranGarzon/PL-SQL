/*
Una colección es un grupo ordenado de elementos que tienen el mismo tipo de datos. Cada elemento se identifica 
por un subíndice único que representa su posición en la colección.

PL / SQL proporciona tres tipos de colecciones:
•  Associative array (or index-by table)
•  Nested table
•  VARRAY (variable-size array)

El índice por tablas y tablas anidadas tienen la misma estructura y sus filas se accede usando la notación 
de subíndice. Sin embargo, estos dos tipos de tablas difieren en un aspecto; las tablas anidadas se pueden 
almacenar en una columna de base de datos y el índice de por tablas no pueden.

-------------------------------
1. Associative array (or index-by table)
-------------------------------
An associative array (formerly called PL/SQL table or index-by table) is a set of key-value pairs. Each key is a unique index, used to locate the associated value with the syntax variable_name(index).

Una tabla de índices por (también llamada una matriz asociativa) es un conjunto de pares de clave y valor. 
Cada tecla es único y se utiliza para localizar el valor correspondiente. La clave puede ser un número entero 
o una cadena.

Una tabla de índices por se crea utilizando la siguiente sintaxis. Aquí, estamos creando una tabla denominada 
nombre_tabla índice de cuyas claves serán de Ejemplo:

Siguiendo el ejemplo se muestra cómo crear una tabla para almacenar valores enteros junto con los nombres y 
luego se imprime la misma lista de nombres.
*/

-- Ejemplo 1
----------------
DECLARE
  TYPE salary IS TABLE OF NUMBER INDEX BY VARCHAR2(20);
  salary_list salary;
  name        VARCHAR2(20);
BEGIN
  -- adding elements to the table
  salary_list('Rajnish') := 62000;
  salary_list('Minakshi') := 75000;
  salary_list('Martin') := 100000;
  salary_list('James') := 78000;

  -- printing the table
  name := salary_list.FIRST;
  WHILE name IS NOT null LOOP
    DBMS_OUTPUT.PUT_LINE('Salary of ' || name || ' is ' || TO_CHAR(salary_list(name)));
    name := salary_list.NEXT(name);
  END LOOP;
END;

/* 
Cuando el código anterior se ejecuta en el intérprete de SQL, se produce el siguiente resultado:

Salary of Rajnish is 62000
Salary of Minakshi is 75000
Salary of Martin is 100000
Salary of James is 78000
*/

-- Ejemplo 2
----------------
DECLARE
   CURSOR c_customers is
      SELECT name FROM customers;
   
   TYPE c_list IS TABLE of customers.name%type INDEX BY binary_integer;
   name_list c_list;
   counter integer :=0;
BEGIN
   FOR n IN c_customers LOOP
      counter := counter +1;
      name_list(counter)  := n.name;
      DBMS_OUTPUT.PUT_LINE('Customer('||counter|| '):'||name_list(counter));
  END LOOP;
END;

/*
Cuando el código anterior se ejecuta en el intérprete de SQL, se produce el siguiente resultado:

Customer(1): Ramesh 
Customer(2): Khilan 
Customer(3): kaushik    
Customer(4): Chaitali 
Customer(5): Hardik 
Customer(6): Komal
*/

/*
-------------------------------
2 - Varrays (Variable-Size Arrays)
-------------------------------
A varray (variable-size array) is an array whose number of elements can vary from zero (empty) to the declared maximum size.

To access an element of a varray variable, use the syntax variable_name(index). The lower bound of index is 1; the upper bound is the current number of elements. The upper bound changes as you add or delete elements, but it cannot exceed the maximum size. When you store and retrieve a varray from the database, its indexes and element order remain stable.

-- Example:
----------
*/

DECLARE
  TYPE Foursome IS VARRAY(4) OF VARCHAR2(15);  -- VARRAY type
 
  -- varray variable initialized with constructor:
 
  team Foursome := Foursome('John', 'Mary', 'Alberto', 'Juanita');
 
  PROCEDURE print_team (heading VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(heading);
 
    FOR i IN 1..4 LOOP
      DBMS_OUTPUT.PUT_LINE(i || '.' || team(i));
    END LOOP;
 
    DBMS_OUTPUT.PUT_LINE('---'); 
  END;
  
BEGIN 
  print_team('2001 Team:');
 
  team(3) := 'Pierre';  -- Change values of two elements
  team(4) := 'Yvonne';
  print_team('2005 Team:');
 
  -- Invoke constructor to assign new values to varray variable:
 
  team := Foursome('Arun', 'Amitha', 'Allan', 'Mae');
  print_team('2009 Team:');
END;
/

/*
-- Result:
----------

Copy
2001 Team:
1.John
2.Mary
3.Alberto
4.Juanita
---
2005 Team:
1.John
2.Mary
3.Pierre
4.Yvonne
---
2009 Team:
1.Arun
2.Amitha
3.Allan
4.Mae
---

-------------------------------
3. Nested Tables
-------------------------------
In the database, a nested table is a column type that stores an unspecified number of rows in no particular order.

When you retrieve a nested table value from the database into a PL/SQL nested table variable, PL/SQL gives the rows consecutive indexes, starting at 1. Using these indexes, you can access the individual rows of the nested table variable. The syntax is variable_name(index). The indexes and row order of a nested table might not remain stable as you store and retrieve the nested table from the database.

The amount of memory that a nested table variable occupies can increase or decrease dynamically, as you add or delete elements.

An uninitialized nested table variable is a null collection. You must initialize it, either by making it empty or by assigning a non-NULL value to it.


Una tabla anidada es como una matriz unidimensional con un número arbitrario de elementos. Sin embargo, 
una tabla anidada se diferencia de una matriz en los siguientes aspectos:

•	Una matriz tiene un número declarado de elementos, pero una tabla anidada no lo hace. El tamaño de una 
tabla anidada puede aumentar de forma dinámica.
•	Una matriz es siempre densa, es decir, siempre tiene subíndices consecutivos. Una matriz anidada es denso 
en un principio, pero puede llegar a ser escasa cuando los elementos se eliminan de ella.

Esta declaración es similar a la declaración de una tabla de índices-by, pero no existe un índice BY.

Una tabla anidada se puede almacenar en una columna de base de datos y por lo que podría ser utilizado 
para simplificar las operaciones de SQL donde se une a una tabla de una sola columna con una tabla más grande. 
Una matriz asociativa no se puede almacenar en la base de datos.
*/

-- Ejemplo 1:
-------------
DECLARE
   TYPE names_table IS TABLE OF VARCHAR2(10);
   TYPE grades IS TABLE OF INTEGER;
   names names_table;
   marks grades;
   total INTEGER;
BEGIN
   names := names_table('Kavita', 'Pritam', 'Ayan', 'Rishav', 'Aziz');
   marks:= grades(98, 97, 78, 87, 92);
   total := names.count;
   DBMS_OUTPUT.PUT_LINE('Total '|| total || ' Students');
   FOR i IN 1 .. total LOOP
      DBMS_OUTPUT.PUT_LINE('Student:'||names(i)||', Marks:' || marks(i));
   END LOOP;
END;

-- Cuando el código anterior se ejecuta en el intérprete de SQL, se produce el siguiente resultado:

/*Total 5 Students
Student:Kavita, Marks:98
Student:Pritam, Marks:97
Student:Ayan, Marks:78
Student:Rishav, Marks:87
Student:Aziz, Marks:92*/

-- Ejemplo 2
-------------
-- Elementos de una tabla anidada también podría ser una ROWTYPE% de cualquier tabla de base de datos o 
-- TIPO% de cualquier campo de la tabla de base de datos. El siguiente ejemplo ilustra el concepto. 
-- Vamos a utilizar la tabla CLIENTES almacenada en nuestra base de datos como:

--Select * from customers;

/*----+----------+-----+-----------+----------+
| ID | NAME     | AGE | ADDRESS   | SALARY   |
+----+----------+-----+-----------+----------+
|  1 | Ramesh   |  32 | Ahmedabad |  2000.00 |
|  2 | Khilan   |  25 | Delhi     |  1500.00 |
|  3 | kaushik  |  23 | Kota      |  2000.00 |
|  4 | Chaitali |  25 | Mumbai    |  6500.00 |
|  5 | Hardik   |  27 | Bhopal    |  8500.00 |
|  6 | Komal    |  22 | MP        |  4500.00 |
+----+----------+-----+-----------+---------*/

-- Tabla de trabajo
CREATE TABLE customers(
id NUMBER PRIMARY KEY,
name VARCHAR2(50) NOT NULL,
age NUMBER,
ADDRESS VARCHAR2(100),
SALARY NUMBER)

-- Registros
INSERT INTO customers(id,name,age,address,salary) VALUES(1,'Ramesh',32,'Ahmedabad',  2000.00 );
INSERT INTO customers(id,name,age,address,salary) VALUES(2,'Khilan',25,'Delhi',  1500.00 );
INSERT INTO customers(id,name,age,address,salary) VALUES(3,'kaushik',23,'Kota',  2000.00 );
INSERT INTO customers(id,name,age,address,salary) VALUES(4,'Chaitali',25,'Mumbai',  6500.00 );
INSERT INTO customers(id,name,age,address,salary) VALUES(5,'Hardik',27,'Bhopal',  8500.00 );
INSERT INTO customers(id,name,age,address,salary) VALUES(6,'Komal',22,'MP',  4500.00 );
COMMIT;
--

DECLARE
   CURSOR c_customers is 
      SELECT name FROM customers;

   TYPE c_list IS TABLE of customers.name%type;
   name_list c_list := c_list();
   counter integer :=0;
BEGIN
   FOR n IN c_customers LOOP
      counter := counter +1;
      name_list.extend;
      name_list(counter)  := n.name;
      dbms_output.put_line('Customer('||counter||'):'||name_list(counter));
   END LOOP;
END;

-- Cuando el código anterior se ejecuta en el intérprete de SQL, se produce el siguiente resultado:

/*Customer(1): Ramesh 
Customer(2): Khilan 
Customer(3): kaushik    
Customer(4): Chaitali 
Customer(5): Hardik 
Customer(6): Komal*/
