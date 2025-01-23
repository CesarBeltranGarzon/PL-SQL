/*
PL / SQL permite definir un tipo de objeto, lo que ayuda en el diseño de la base de datos orientada a objetos 
en Oracle. Un tipo de objeto que permite a los tipos compuestos caja. Uso de objetos permiten la implementación 
de objetos del mundo real con la estructura específica de los datos y métodos para el funcionamiento de la misma. 
Los objetos tienen atributos y métodos. Los atributos son propiedades de un objeto y se utilizan para almacenar 
el estado de un objeto; y los métodos se utilizan para el modelado de sus comportamientos.

Los objetos se crean utilizando la opción CREATE [OR REPLACE] Declaración TIPO. A continuación se muestra 
un ejemplo para crear un objeto de dirección simple que consiste en unos atributos:
*/

CREATE OR REPLACE TYPE address AS OBJECT
(house_no varchar2(10),
 street varchar2(30),
 city varchar2(20),
 state varchar2(10),
 pincode varchar2(10)
);

/*
Creación de una instancia de objeto
La definición de un tipo de objeto proporciona un plan para el objeto. Para utilizar este objeto, es necesario 
crear instancias de este objeto. Puede acceder a los atributos y métodos del objeto usando el nombre de 
instancia y el operador de acceso de la siguiente manera (.):
*/

DECLARE
   residence address;
BEGIN
   residence := address('103A', 'M.G.Road', 'Jaipur', 'Rajasthan','201301');
   dbms_output.put_line('House No: '|| residence.house_no);
   dbms_output.put_line('Street: '|| residence.street);
   dbms_output.put_line('City: '|| residence.city);
   dbms_output.put_line('State: '|| residence.state);
   dbms_output.put_line('Pincode: '|| residence.pincode);
END;

