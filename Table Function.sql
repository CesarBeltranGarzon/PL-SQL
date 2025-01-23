/*
Returning a 'table' from a PL/SQL function 
With collections, it is possible to return a table from a pl/sql function. 
First, we need to create a new object type that contains the fields that are going to be returned: 
*/

CREATE OR REPLACE TYPE t_col AS OBJECT (
  i NUMBER,
  n VARCHAR2(30)
);

-- Then, out of this new type, a nested table type must be created. 

CREATE OR REPLACE TYPE t_nested_table AS TABLE OF t_col;

-- Now, we're ready to actually create the function: 

CREATE OR REPLACE FUNCTION return_table RETURN t_nested_table AS
  v_ret   t_nested_table;
BEGIN
  v_ret  := t_nested_table();

  v_ret.extend;
  v_ret(v_ret.count) := t_col(1, 'one');

  v_ret.extend;
  v_ret(v_ret.count) := t_col(2, 'two');

  v_ret.extend;
  v_ret(v_ret.count) := t_col(3, 'three');

  RETURN v_ret;
END return_table;

-- Here's how the function is used: 

SELECT * FROM TABLE(return_table);

---------------------------------------------------------------
-- Returning a dynamic set
---------------------------------------------------------------
-- Now, the function is extended so as to return a dynamic set. 

-- The function will return the object_name and the object_id from user_objects whose object_id is in 
-- the range that is passed to the function. 

CREATE OR REPLACE FUNCTION return_objects(
  p_min_id IN NUMBER,
  p_max_id IN NUMBER
)
RETURN t_nested_table AS
  v_ret   t_nested_table;
BEGIN
  SELECT 
  CAST(
  MULTISET(
    SELECT 
      object_id, object_name
    FROM 
      user_objects
    WHERE
      object_id BETWEEN p_min_id AND p_max_id) 
      AS t_nested_table)
    INTO
      v_ret
    FROM 
      dual;

  RETURN v_ret;
  
END return_objects;

-- And here's how the function is called. 

SELECT * FROM TABLE(return_objects(37900,38000));


---------------------------------------------------------------
-- Otros Ejemplos
---------------------------------------------------------------
CREATE OR REPLACE TYPE TEST_CLASS_TYPE AS OBJECT (      
      id_record   number(4),
      desc_record varchar2(20),
      date_record date,
      
      constructor function test_class_TYPE return self as result            
);

CREATE OR REPLACE TYPE BODY TEST_CLASS_TYPE AS
   constructor function test_class_TYPE return self as result is
   BEGIN
      RETURN;
   END;
END;

-- Ahora creamos el tipo colección en base al tipo registro previamente definido.

CREATE OR REPLACE TYPE TEST_TABLE_TYPE IS TABLE OF test_class_TYPE;

-- Creamos el package donde se alojará la función de ejemplo.

CREATE OR REPLACE PACKAGE TEST_COLLECTION IS
   
   FUNCTION get_table(p_max_records in number) RETURN test_table_TYPE;
      
END;

CREATE OR REPLACE PACKAGE BODY test_collection IS
  
   FUNCTION get_table(p_max_records in number) RETURN test_table_TYPE IS
      itab test_table_TYPE;      
      
   BEGIN
      
      itab := NEW test_table_TYPE();
      IF NVL(p_max_records,0) > 0 THEN
         FOR i IN 1..p_max_records LOOP
            itab.extend;
            itab(itab.last) := new test_class_TYPE();            
            itab(itab.last).id_record := i;
            itab(itab.last).desc_record := 'Registro '||i;
            itab(itab.last).date_record := trunc(sysdate + i - 1);
         END LOOP;
      END IF;
      
      RETURN itab;
   END;
 
END; 

-- Y ahora viene lo interesante, como acceder a esta colección como si de una tabla física se tratase:
select * from TABLE( test_collection.get_table(12) );

/*Resultado:
ID_RECORD DESC_RECORD          DATE_RECORD       
--------- -------------------- ------------------
        1 Registro 1           17/06/2013        
        2 Registro 2           18/06/2013        
        3 Registro 3           19/06/2013        
        4 Registro 4           20/06/2013        
        5 Registro 5           21/06/2013        
        6 Registro 6           22/06/2013        
        7 Registro 7           23/06/2013        
        8 Registro 8           24/06/2013        
        9 Registro 9           25/06/2013        
       10 Registro 10          26/06/2013        
       11 Registro 11          27/06/2013        
       12 Registro 12          28/06/2013 

Observe como con este recurso pueden realizar agrupación de datos, filtros en la cláusula WHERE... y en 
definitiva operar con la colección que devuelve la función como si de una tabla física se tratase:

select * from TABLE( test_collection.get_table(31) )
 where id_record > 20
 order by id_record desc
 
En un caso real los parámetros de la función serían los filtros que el usuario web indica en los formulario 
de acceso a datos, y los datos retornados por la función mediante la colección los reuniría la lógica 
programada dentro de la función, donde internamente se puede realizar acceso a un gran número de tablas, 
realizar operaciones, conversiones, comparaciones, etc.. todo lo necesario para ir llenando la colección y 
retornar los datos que espera la aplicación Java para mostrarlos en la web.

Con ello conseguimos las siguientes ventajas destacables.

1. - Toda la lógica para reunir los datos queda encapsulada en el núcleo de Oracle.
2. - El desarrollador Java no es necesario que conozca la lógica de negocio, solo debe conocer la interfece 
     (package Oracle)
3. - Solo será necesario mapear en Hibernate las estructuras dinámicas, y no las múltiples tablas de la capa 
     de negocio que forman la fuente de datos.
4. - Todos los accesos a tablas físicas se realizan en PL/SQL siendo menos costoso su implementación que en la 
     parte Java.
5. - Permite dividir la implementación por capas, la interface la desarrolla el programador Oracle y la página 
     web el desarrollador Java.
6. - Tan solo es necesario otorgar privilegios de ejecución sobre el package que aloja las funciones, y no 
     sobre las múltiples tablas que forman la fuente de datos.

El único inconveniente que le veo es que al ser lógica la que al fin y al cabo se acaba ejecutando, podemos 
tener problemas de rendimiento si no cuidamos la eficiencia del código que contienen las funciones.

*/
