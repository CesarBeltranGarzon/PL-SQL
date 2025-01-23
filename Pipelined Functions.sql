/*
la funcionalidad pipelined fue introducida por primera vez en la versión 9i de las bases de datos Oracle. 
Básicamente, el uso de la cláusula PIPELINED resulta de gran utilidad y es prácticamente imprescindible 
cuando necesitamos que en lugar de una tabla sea una rutina PL/SQL la que nos sirva como fuente de datos.

sys.odciNumberList no es nada más que un tipo de dato que viene definido por defecto en lás últimas releases 
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

-- En el ejemplo la cláusula PIPELINED permite que la función generador_numeros funcione exactamente 
-- como una tabla. Veamos como.

SELECT * FROM TABLE(generador_numeros(7));

/*
la excepción NO_DATA_NEEDED aparece cuando una función que utiliza la cláusula PIPELINED puede devolver 
más datos pero la sentencia SQL que invoca dicha función no los ha solicitado.
*/

SELECT * FROM TABLE(generador_numeros(4)) WHERE rownum < 3;

/*
COLUMN_VALUE
------------
1
2

Aparentemente la función PL/SQL generador_numeros ha funcionado correctamente, pero si nos fijamos bien, 
la salida por pantalla que yo había incluido al final de la función no se ha ejecutado, es decir, 
en la pantalla no aparece por ningún lado el esperado "Ejecutando Return". Simplemente esa parte del código 
no se ha ejecutado porque la sentencia SQL con la que hemos invocado la función generador_numeros no lo 
necesitaba. Ciertamente todo parece haber funcionado correctamente, sin embargo, aunque haya permanecido 
oculto a nuestros ojos, se ha generado una excepción NO_DATA_NEEDED. En este sentido, la excepción 
NO_DATA_NEEDED se trata de una excepción totalmente diferente a todas las demás, ya que si ésta no se trata 
dentro del código, simplemente es ignorada (por contra, el resto de excepciones, en caso de no ser tratadas, 
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

Utilizando la sentencia WHEN OTHERS en lugar de WHEN NO_DATA_NEEDED, habríamos conseguido el mismo resultado, 
sin embargo no sería la manera correcta de hacerlo ya que estaríamos enmascarando otros errores que podrían 
generarse por otros motivos. La excepción NO_DATA_NEEDED está especialmente diseñada para tratar este tipo 
de situaciones y debe ser utilizada de forma apropiada cuando estemos escribiendo una función PL/SQL que 
utilice la cláusula PIPELINED.
*/
