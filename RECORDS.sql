/* RECORDS

Un registro de PL / SQL es una estructura de datos que puede contener elementos de datos de diferentes tipos. 
Registros consisten en diferentes campos, similar a una fila de una tabla de base de datos.

Por ejemplo, desea mantener un registro de sus libros en una biblioteca. Es posible que desee realizar un 
seguimiento de los siguientes atributos acerca de cada libro como, título, autor, tema, libro de identificación. 
Un registro que contiene un campo para cada uno de estos elementos permite tratar un libro como una unidad lógica 
y le permite organizar y representar la información de una manera mejor.

PL / SQL puede contener los siguientes tipos de registros:
•  Tabla-basado
•  registros basados en el cursor
•  registros definidos por el usuario
*/

---------------------------------------
-- Registros basados en tabla
---------------------------------------
/* El atributo% ROWTYPE permite a un programador para crear registros basados en el cursor basado en tablas y.

El siguiente ejemplo ilustra el concepto de registros basados en tablas. Nosotros vamos a usar la tabla de 
CLIENTES que habíamos creado y utilizado en los capítulos anteriores:*/

DECLARE
   customer_rec customers%rowtype;
BEGIN
   SELECT * into customer_rec
   FROM customers
   WHERE id = 5;

   dbms_output.put_line('Customer ID: ' || customer_rec.id);
   dbms_output.put_line('Customer Name: ' || customer_rec.name);
   dbms_output.put_line('Customer Address: ' || customer_rec.address);
   dbms_output.put_line('Customer Salary: ' || customer_rec.salary);
END;

-- Cuando el código anterior se ejecuta en el intérprete de SQL, se produce el siguiente resultado:

/*Customer ID: 5
Customer Name: Hardik
Customer Address: Bhopal
Customer Salary: 9000*/

---------------------------------------
-- Registros basados en cursor
---------------------------------------
-- El siguiente ejemplo ilustra el concepto de registros basados en el cursor. Nosotros vamos a usar la tabla 
-- de CLIENTES que habíamos creado y utilizado en los capítulos anteriores:

DECLARE
   CURSOR customer_cur is
      SELECT id, name, address 
      FROM customers;
   customer_rec customer_cur%rowtype;
BEGIN
   OPEN customer_cur;
   LOOP
      FETCH customer_cur into customer_rec;
      EXIT WHEN customer_cur%notfound;
      DBMS_OUTPUT.put_line(customer_rec.id || ' ' || customer_rec.name);
   END LOOP;
END;

-- Cuando el código anterior se ejecuta en el intérprete de SQL, se produce el siguiente resultado:
/*1 Ramesh
2 Khilan
3 kaushik
4 Chaitali
5 Hardik
6 Komal*/

---------------------------------------
-- Registros definidos por usuario
---------------------------------------
/*PL / SQL proporciona un tipo de registro definido por el usuario que le permite definir diferentes estructuras 
de registro. Registros consisten en diferentes campos. Supongamos que desea realizar un seguimiento de sus 
libros en una biblioteca. Es posible que desee realizar un seguimiento de los siguientes atributos acerca de 
cada libro:

•	Título
•	Autor
•	Tema
•	Identificación libro*/

DECLARE
   type books is record
      (title varchar(50),
       author varchar(50),
       subject varchar(100),
       book_id number);
       
   book1 books;
   book2 books;
BEGIN
   -- Book 1 specification
   book1.title  := 'C Programming';
   book1.author := 'Nuha Ali '; 
   book1.subject := 'C Programming Tutorial';
   book1.book_id := 6495407;

   -- Book 2 specification
   book2.title := 'Telecom Billing';
   book2.author := 'Zara Ali';
   book2.subject := 'Telecom Billing Tutorial';
   book2.book_id := 6495700;

   -- Print book 1 record
   dbms_output.put_line('Book 1 title : '|| book1.title);
   dbms_output.put_line('Book 1 author : '|| book1.author);
   dbms_output.put_line('Book 1 subject : '|| book1.subject);
   dbms_output.put_line('Book 1 book_id : ' || book1.book_id);
  
   -- Print book 2 record
   dbms_output.put_line('Book 2 title : '|| book2.title);
   dbms_output.put_line('Book 2 author : '|| book2.author);
   dbms_output.put_line('Book 2 subject : '|| book2.subject);
   dbms_output.put_line('Book 2 book_id : '|| book2.book_id);
END;

/*Cuando el código anterior se ejecuta en el intérprete de SQL, se produce el siguiente resultado:

Book 1 title : C Programming
Book 1 author : Nuha Ali
Book 1 subject : C Programming Tutorial
Book 1 book_id : 6495407
Book 2 title : Telecom Billing
Book 2 author : Zara Ali
Book 2 subject : Telecom Billing Tutorial
Book 2 book_id : 6495700*/

--Registros como parámetros de subprograma
--------------------------------------------
--Puede pasar un registro como un parámetro de subprograma de manera muy similar a como se pasa a cualquier 
--otra variable. Se podría acceder a los campos de registro en la forma similar a la que ha accedido en el 
--ejemplo anterior:

DECLARE
   type books is record
      (title  varchar(50),
      author  varchar(50),
      subject varchar(100),
      book_id   number);
   book1 books;
   book2 books;

PROCEDURE printbook (book books) IS
BEGIN
   dbms_output.put_line ('Book  title :  ' || book.title);
   dbms_output.put_line('Book  author : ' || book.author);
   dbms_output.put_line( 'Book  subject : ' || book.subject);
   dbms_output.put_line( 'Book book_id : ' || book.book_id);
END;
  
BEGIN
   -- Book 1 specification
   book1.title  := 'C Programming';
   book1.author := 'Nuha Ali '; 
   book1.subject := 'C Programming Tutorial';
   book1.book_id := 6495407;

   -- Book 2 specification
   book2.title := 'Telecom Billing';
   book2.author := 'Zara Ali';
   book2.subject := 'Telecom Billing Tutorial';
   book2.book_id := 6495700;

   -- Use procedure to print book info
   printbook(book1);
   printbook(book2);
END;
