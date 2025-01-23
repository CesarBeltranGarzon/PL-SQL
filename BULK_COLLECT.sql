/*
En la base de datos Oracle hay dos motores, uno para ejecutar PL/SQL y otro para SQL. Cuando el PL/SQL quiere manipular datos, accede al motor de SQL. 
Esto conlleva muchos recursos. Bulk collect agrupa varias instrucciones y lo realiza en una sola ejecución, optimizando los cambios de contexto. Es 
importante si se trabaja con grandes volumenes de datos. 
Es un elemento básico, para los procedimientos ETL, ya que suelen filtrar y transformar tablas en una misma base de datos.
*/

--EJEMPLO recuperar registros con bulk collect:
DECLARE
   TYPE t_nombres IS TABLE OF empleados.nombre%TYPE;
   nombres t_nombres;
BEGIN
   SELECT nombre BULK COLLECT INTO nombres FROM empleados
      WHERE ROWNUM <= 2;
END;

--EJEMPLO recuperar registros utilizando un cursor:
DECLARE
   TYPE EmpRecTab IS TABLE OF empleados%ROWTYPE;
   emp_recs EmpRecTab;
   CURSOR c IS
      SELECT empleado_id, nombre, jefe_id FROM empleados WHERE empleado_id > 2;
BEGIN
   OPEN c;
   FETCH c BULK COLLECT INTO emp_recs;
END;

--EJEMPLO borrado:
DECLARE
   TYPE t_lista_num IS TABLE OF empleados.empleado_id%TYPE;
   enums t_lista_num;
BEGIN
   -- enums devolvera los id_empleados de los empleados del departamento 25
   DELETE FROM empleados WHERE empleado_id = 5
      RETURNING empleado_id BULK COLLECT INTO enums;
END;

------------------------------------------------------------------------------------------------------
-- El siguiente ejemplo compara el tiempo tomado para poblar una coleccion manualmente y usando Bulk bind.
------------------------------------------------------------------------------------------------------
-- tabla ejemplo
CREATE TABLE bulk_collect_test AS
SELECT owner,
       object_name,
       object_id
FROM   all_objects;
--

DECLARE
  TYPE t_bulk_collect_test_tab IS TABLE OF bulk_collect_test%ROWTYPE;

  l_tab    t_bulk_collect_test_tab := t_bulk_collect_test_tab();
  l_start  NUMBER;
BEGIN
  -- Time a regular population.
  l_start := DBMS_UTILITY.get_time;

  FOR cur_rec IN (SELECT *
                  FROM   bulk_collect_test)
  LOOP
    l_tab.extend;
    l_tab(l_tab.last) := cur_rec;
  END LOOP;

  DBMS_OUTPUT.put_line('Regular (' || l_tab.count || ' rows): ' || 
                       (DBMS_UTILITY.get_time - l_start));
  
  -- Time bulk population.  
  l_start := DBMS_UTILITY.get_time;

  SELECT *
  BULK COLLECT INTO l_tab
  FROM   bulk_collect_test;

  DBMS_OUTPUT.put_line('Bulk    (' || l_tab.count || ' rows): ' || 
                       (DBMS_UTILITY.get_time - l_start));
END;

/* Regular (42578 rows): 66
   Bulk    (42578 rows): 4  
   
---------------------------------------------------------------------------
El código siguiente muestra cómo fragmentar los datos en una tabla grande.
---------------------------------------------------------------------------
Recuerde que las colecciones se llevan a cabo en la memoria, por lo que hacer una recopilación a granel 
de una consulta grande podría causar un considerable problema de rendimiento. De hecho, rara vez haría un Bulk
Collect de esta manera. En su lugar, limitaría las filas devueltas utilizando la cláusula LIMIT y 
se desplazaría a través de los trozos más pequeños de procesamiento de datos. Esto le brinda los beneficios 
de los enlaces masivos, sin acaparar toda la memoria del servidor. 

*/
DECLARE
  TYPE t_bulk_collect_test_tab IS TABLE OF bulk_collect_test%ROWTYPE;

  l_tab t_bulk_collect_test_tab;

  CURSOR c_data IS
    SELECT *
    FROM bulk_collect_test;
BEGIN
  OPEN c_data;
  LOOP
    FETCH c_data
    BULK COLLECT INTO l_tab LIMIT 10000;
    EXIT WHEN l_tab.count = 0;

    -- Process contents of collection here.
    DBMS_OUTPUT.put_line(l_tab.count || ' rows');
  END LOOP;
  CLOSE c_data;
END;
/* 10000 rows
   10000 rows
   10000 rows
   10000 rows
    2578 rows*/
    
/* ----------------------------------------------------------------------------------------------------
   Desde Oracle 10g en adelante, el compilador PL/SQL de optimización convierte el cursor FOR LOOPs en 
   BULK COLLECT con un tamaño de matriz de 100. El ejemplo siguiente compara la velocidad de un cursor 
   regular para LOOP con BULK COLLECT usando tamaños de matriz variables. 
   ----------------------------------------------------------------------------------------------------*/

DECLARE
  TYPE t_bulk_collect_test_tab IS TABLE OF bulk_collect_test%ROWTYPE;

  l_tab    t_bulk_collect_test_tab;

  CURSOR c_data IS
    SELECT *
    FROM   bulk_collect_test;

  l_start  NUMBER;
BEGIN
  -- Time a regular cursor for loop.
  l_start := DBMS_UTILITY.get_time;

  FOR cur_rec IN (SELECT *
                  FROM   bulk_collect_test)
  LOOP
    NULL;
  END LOOP;

  DBMS_OUTPUT.put_line('Regular  : ' || (DBMS_UTILITY.get_time - l_start));

  -- Time bulk with LIMIT 10.
  l_start := DBMS_UTILITY.get_time;

  OPEN c_data;
  LOOP
    FETCH c_data
    BULK COLLECT INTO l_tab LIMIT 10;
    EXIT WHEN l_tab.count = 0;
  END LOOP;
  CLOSE c_data;

  DBMS_OUTPUT.put_line('LIMIT 10 : ' || 
                       (DBMS_UTILITY.get_time - l_start));

  -- Time bulk with LIMIT 100.
  l_start := DBMS_UTILITY.get_time;

  OPEN c_data;
  LOOP
    FETCH c_data
    BULK COLLECT INTO l_tab LIMIT 100;
    EXIT WHEN l_tab.count = 0;
  END LOOP;
  CLOSE c_data;

  DBMS_OUTPUT.put_line('LIMIT 100: ' || 
                       (DBMS_UTILITY.get_time - l_start));

  -- Time bulk with LIMIT 1000.
  l_start := DBMS_UTILITY.get_time;

  OPEN c_data;
  LOOP
    FETCH c_data
    BULK COLLECT INTO l_tab LIMIT 1000;
    EXIT WHEN l_tab.count = 0;
  END LOOP;
  CLOSE c_data;

  DBMS_OUTPUT.put_line('LIMIT 1000: ' || 
                       (DBMS_UTILITY.get_time - l_start));
END;
/* Regular  : 18
   LIMIT 10 : 80
   LIMIT 100: 15
   LIMIT 1000: 10 */

