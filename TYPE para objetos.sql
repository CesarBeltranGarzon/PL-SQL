/*
PL / SQL permite definir un tipo de objeto, lo que ayuda en el dise�o de la base de datos orientada a objetos 
en Oracle. Un tipo de objeto que permite a los tipos compuestos caja. Uso de objetos permiten la implementaci�n 
de objetos del mundo real con la estructura espec�fica de los datos y m�todos para el funcionamiento de la misma. 
Los objetos tienen atributos y m�todos. Los atributos son propiedades de un objeto y se utilizan para almacenar 
el estado de un objeto; y los m�todos se utilizan para el modelado de sus comportamientos.

Los objetos se crean utilizando la opci�n CREATE [OR REPLACE] Declaraci�n TIPO. A continuaci�n se muestra 
un ejemplo para crear un objeto de direcci�n simple que consiste en unos atributos:
*/

CREATE OR REPLACE TYPE address AS OBJECT
(house_no varchar2(10),
 street varchar2(30),
 city varchar2(20),
 state varchar2(10),
 pincode varchar2(10)
);

/*
Creaci�n de una instancia de objeto
La definici�n de un tipo de objeto proporciona un plan para el objeto. Para utilizar este objeto, es necesario 
crear instancias de este objeto. Puede acceder a los atributos y m�todos del objeto usando el nombre de 
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

