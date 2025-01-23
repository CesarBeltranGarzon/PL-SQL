/*
PL / SQL permite crear objetos a partir de objetos de base existentes. Para implementar la herencia, 
los objetos de la base deben ser declarados como no definitivo. El valor por defecto es final.

Los siguientes programas ilustran herencia en objetos PL / SQL. Vamos a crear otro objeto denominado 
TableTop, que se hereda del objeto Rectangle. Creación del objeto rectángulo base:
*/

CREATE OR REPLACE TYPE rectangle AS OBJECT
(length number,
 width number,
 member function enlarge( inc number) return rectangle,
 NOT FINAL member procedure display) NOT FINAL;
 
-- Crear el cuerpo de tipo base:

CREATE OR REPLACE TYPE BODY rectangle AS
   MEMBER FUNCTION enlarge(inc number) return rectangle IS
   BEGIN
      return rectangle(self.length + inc, self.width + inc);
   END enlarge;

   MEMBER PROCEDURE display IS
   BEGIN
      dbms_output.put_line('Length: '|| length);
      dbms_output.put_line('Width: '|| width);
   END display;
END;

-- Nuevo objeto que hereda del anterior
-- La creación de la mesa objeto secundario:

CREATE OR REPLACE TYPE tabletop UNDER rectangle
(  
   material varchar2(20);
   OVERRIDING member procedure display
)

-- La creación del cuerpo de tipo para el tablero de la mesa objeto secundario:

CREATE OR REPLACE TYPE BODY tabletop AS
OVERRIDING MEMBER PROCEDURE display IS
BEGIN
   dbms_output.put_line('Length: '|| length);
   dbms_output.put_line('Width: '|| width);
   dbms_output.put_line('Material: '|| material);
END display;

-- Utilizando el objeto mesa y sus funciones miembro:

DECLARE
   t1 tabletop;
   t2 tabletop;
BEGIN
   t1:= tabletop(20, 10, 'Wood');
   t2 := tabletop(50, 30, 'Steel');
   t1.display;
   t2.display;
END;
