-- Uso de EXECUTE IMMEDIATE y SQL%ROWCOUNT
DECLARE
  ret NUMBER;
  
  FUNCTION fn_execute RETURN NUMBER IS
    sql_str VARCHAR2(1000);
  BEGIN
    sql_str := 'UPDATE DATOS SET NOMBRE = ''NUEVO NOMBRE'' 
                WHERE CODIGO = 1';
    EXECUTE IMMEDIATE sql_str;
    RETURN SQL%ROWCOUNT;
  END fn_execute;
  
BEGIN
  ret := fn_execute();
  dbms_output.put_line(TO_CHAR(ret));
END;

-- El siguiente ejemplo muestra el uso de variables host con USING para parametrizar una sentencia SQL dinamica.
DECLARE
  ret NUMBER;
  
  FUNCTION fn_execute (nombre VARCHAR2, codigo NUMBER) RETURN NUMBER 
  IS
    sql_str VARCHAR2(1000);
  BEGIN
    sql_str := 'UPDATE DATOS SET NOMBRE = :new_nombre WHERE CODIGO = :codigo';    
    EXECUTE IMMEDIATE sql_str USING nombre, codigo;   
    RETURN SQL%ROWCOUNT;
  END fn_execute ;
  
BEGIN
     ret := fn_execute('Devjoker',1);
     dbms_output.put_line(TO_CHAR(ret));
END;

-------------------------------
-- Cursores con SQL dinámico
-------------------------------
-- Implicito
--    Para utilizar un cursor implicito solo debemos construir nuestra sentencia SELECT en una variable de tipo 
--    caracter y ejecutarla con EXECUTE IMMEDIATE utilizando la palabra clave INTO.
DECLARE
       str_sql VARCHAR2(255);
       l_cnt   VARCHAR2(20);
BEGIN
     str_sql := 'SELECT count(*) FROM PAISES';
     EXECUTE IMMEDIATE str_sql INTO l_cnt;
     dbms_output.put_line(l_cnt);
END; 

-- Explicito
--    Trabajar con cursores explicitos es también muy fácil. Únicamente destacar el uso de REF CURSOR para 
--    declarar una variable para referirnos al cursor generado con SQL dinamico. 
DECLARE
  TYPE CUR_TYP IS REF CURSOR;
  c_cursor   CUR_TYP;
  fila PAISES%ROWTYPE;
  v_query     VARCHAR2(255);
BEGIN
  v_query := 'SELECT * FROM PAISES';
 
  OPEN c_cursor FOR v_query;
  LOOP
    FETCH c_cursor INTO fila;
    EXIT WHEN c_cursor%NOTFOUND;
    dbms_output.put_line(fila.DESCRIPCION);
  END LOOP;
  CLOSE c_cursor;
END; 

-- Las varibles host tambien se pueden utilizar en los cursores.
DECLARE
  TYPE cur_typ IS REF CURSOR;
  c_cursor    CUR_TYP;
  fila PAISES%ROWTYPE;
  v_query     VARCHAR2(255);
  codigo_pais VARCHAR2(3) := 'ESP';
BEGIN

  v_query := 'SELECT * FROM PAISES WHERE CO_PAIS = :cpais';
  OPEN c_cursor FOR v_query USING codigo_pais;
  LOOP
    FETCH c_cursor INTO fila;
    EXIT WHEN c_cursor%NOTFOUND;
    dbms_output.put_line(fila.DESCRIPCION);
  END LOOP;
  CLOSE c_cursor;
END;
 


 
