/*
M�todo Mapa: El m�todo Mapa es una funci�n implementada de tal manera que su valor depende del valor 
de los atributos. Por ejemplo, para un objeto de cliente, si el c�digo de cliente es el mismo para dos 
clientes, tanto los clientes podr�an ser los mismos y uno. As� la relaci�n entre estos dos objetos depender�a 
del valor de c�digo.
*/
CREATE OR REPLACE TYPE rectangle AS OBJECT
(length number,
 width number,
 member function enlarge( inc number) return rectangle,
 member procedure display,
 map member function measure return number
);

--Crear el tipo de cuerpo:

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

   MAP MEMBER FUNCTION measure return number IS
   BEGIN
      return (sqrt(length*length + width*width));
   END measure;
END;

-- Ahora, utilizando el objeto rect�ngulo y sus funciones miembro:

DECLARE
   r1 rectangle;
   r2 rectangle;
   r3 rectangle;
   inc_factor number := 5;
BEGIN
   r1 := rectangle(3, 4);
   r2 := rectangle(5, 7);
   r3 := r1.enlarge(inc_factor);
   r3.display;

   IF (r1 > r2) THEN -- calling measure function
      r1.display;
   ELSE
      r2.display;
   END IF;
END;
