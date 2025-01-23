-- Consulta SQL Recursiva
CREATE TABLE empleados(
  empleado_id  NUMBER(10) NOT NULL,
  nombre       VARCHAR2(80) NOT NULL,
  jefe_id      NUMBER(10),
  PRIMARY KEY (empleado_id)
);

--
INSERT INTO empleados(empleado_id, nombre, jefe_id) VALUES(1,'Cesar Fernando Beltran',4);
INSERT INTO empleados(empleado_id, nombre, jefe_id) VALUES(2,'Catalina Quiroga',4);
INSERT INTO empleados(empleado_id, nombre, jefe_id) VALUES(3,'Samuel Esteban Beltran',1);
INSERT INTO empleados(empleado_id, nombre, jefe_id) VALUES(4,'Dios',0);
INSERT INTO empleados(empleado_id, nombre, jefe_id) VALUES(5,'Andres Beltran',1);
COMMIT;
/*
  La idea es recuperar en una sola consulta, todos los empleados asociados a Pepe, quiz�s respondiendo algo como ��Quien es el jefe principal de Pepe?� 
  Con una consulta normal, tendr�amos que ejecutar tres sentencias, una para recuperar el jefe_id de Pepe, otra para recuperar a Juan y una �ltima para 
  recuperar a Mar�a. Extrapolad esto a una relaci�n donde hayan cientos de elementos y tendr�is un mont�n de conexiones a la BBDD innecesarias o algo peor. 
  Con una consulta recursiva (Oracle la llama jer�rquica) podr�amos hacerlo todo de una vez.
*/

SELECT empleado_id, nombre, jefe_id, LEVEL
  FROM empleados
 START WITH empleado_id = 3
 CONNECT BY empleado_id = PRIOR jefe_id
 ORDER BY LEVEL;  
