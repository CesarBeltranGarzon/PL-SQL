DECLARE

  CURSOR c_campos IS
    SELECT utc.TABLE_NAME, utc.COLUMN_NAME
      FROM user_tab_columns utc
     WHERE utc.TABLE_NAME IN ('TBL_PROC_SAP',
                              'TBL_PROC_GESREC',
                              'TBL_PROC_ATIS',
                              'TBL_PROC_DAVOX',
                              'TBL_PROC_SCL')
     ORDER BY table_name, column_id;
  
  v_Encontrado  NUMBER;

BEGIN

  FOR reg_datos IN c_campos LOOP
    
    SELECT COUNT(*) INTO v_Encontrado
      FROM user_source us
     WHERE UPPER(us.text) LIKE '%' || reg_datos.column_name || '%'
       AND UPPER(us.name) NOT LIKE '%_CARGA_%';

    IF v_Encontrado = 0 THEN
      
      Dbms_Output.Put_Line(reg_datos.table_name || ';' || reg_datos.column_name || ';No Usado');
    
    ELSE
      
      Dbms_Output.Put_Line(reg_datos.table_name || ';' || reg_datos.column_name || ';Usado');
    
    END IF;
  
  END LOOP;

END;
