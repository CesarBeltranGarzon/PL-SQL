/*
la funcionalidad pipelined fue introducida por primera vez en la versi�n 9i de las bases de datos Oracle. 
B�sicamente, el uso de la cl�usula PIPELINED resulta de gran utilidad y es pr�cticamente imprescindible 
cuando necesitamos que en lugar de una tabla sea una rutina PL/SQL la que nos sirva como fuente de datos.

sys.odciNumberList no es nada m�s que un tipo de dato que viene definido por defecto en l�s �ltimas releases 
de las bases de datos Oracle.

Es equivalente a definir un tipo de la siguiente manera:

CREATE OR REPLACE TYPE ListaNumeros AS TABLE OF NUMBER;

En este caso el tipo ListaNumeros y el tipo sys.odciNumberList son equivalentes.
*/

CREATE OR REPLACE FUNCTION generador_numeros(n IN NUMBER DEFAULT NULL)
  RETURN sys.odciNumberList
  PIPELINED AS
BEGIN
  FOR i IN 1 .. NVL(n, 100) LOOP
    PIPE ROW(i);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Ejecutando return');
  RETURN;
END;

-- En el ejemplo la cl�usula PIPELINED permite que la funci�n generador_numeros funcione exactamente 
-- como una tabla. Veamos como.

SELECT * FROM TABLE(generador_numeros(7));

/*
la excepci�n NO_DATA_NEEDED aparece cuando una funci�n que utiliza la cl�usula PIPELINED puede devolver 
m�s datos pero la sentencia SQL que invoca dicha funci�n no los ha solicitado.
*/

SELECT * FROM TABLE(generador_numeros(4)) WHERE rownum < 3;

/*
COLUMN_VALUE
------------
1
2

Aparentemente la funci�n PL/SQL generador_numeros ha funcionado correctamente, pero si nos fijamos bien, 
la salida por pantalla que yo hab�a incluido al final de la funci�n no se ha ejecutado, es decir, 
en la pantalla no aparece por ning�n lado el esperado "Ejecutando Return". Simplemente esa parte del c�digo 
no se ha ejecutado porque la sentencia SQL con la que hemos invocado la funci�n generador_numeros no lo 
necesitaba. Ciertamente todo parece haber funcionado correctamente, sin embargo, aunque haya permanecido 
oculto a nuestros ojos, se ha generado una excepci�n NO_DATA_NEEDED. En este sentido, la excepci�n 
NO_DATA_NEEDED se trata de una excepci�n totalmente diferente a todas las dem�s, ya que si �sta no se trata 
dentro del c�digo, simplemente es ignorada (por contra, el resto de excepciones, en caso de no ser tratadas, 
generan un error).
*/

CREATE OR REPLACE FUNCTION generador_numeros(n IN NUMBER DEFAULT NULL)
  RETURN sys.odciNumberList
  PIPELINED AS
BEGIN
  FOR i IN 1 .. NVL(n, 100) LOOP
    PIPE ROW(i);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Ejecutando return');
  RETURN;
EXCEPTION
  WHEN NO_DATA_NEEDED THEN
    DBMS_OUTPUT.PUT_LINE('Ejecutando excepcion');
    RETURN;
END;

--Ahora si ejecutamos nuestra sentencia SQL obtendremos lo siguiente: 

SELECT * FROM TABLE(generador_numeros(4)) WHERE rownum < 3;

/*
COLUMN_VALUE
------------
1
2
 
Ejecutando excepcion

Utilizando la sentencia WHEN OTHERS en lugar de WHEN NO_DATA_NEEDED, habr�amos conseguido el mismo resultado, 
sin embargo no ser�a la manera correcta de hacerlo ya que estar�amos enmascarando otros errores que podr�an 
generarse por otros motivos. La excepci�n NO_DATA_NEEDED est� especialmente dise�ada para tratar este tipo 
de situaciones y debe ser utilizada de forma apropiada cuando estemos escribiendo una funci�n PL/SQL que 
utilice la cl�usula PIPELINED.
*/
