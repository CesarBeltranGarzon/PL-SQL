DECLARE

  CURSOR cinicial IS
  SELECT aso.owner, aso.name, aso.line, aso.text
    FROM all_source aso
   WHERE (upper(REPLACE(REPLACE(UPPER(aso.text),'ADMINBDP.',''),'  ',' ')) like upper('%UPDATE PDEN_VOL_SUMMARY%')
      OR upper(REPLACE(REPLACE(UPPER(aso.text),'ADMINBDP.',''),'  ',' ')) like upper('%UPDATE PDEN_VOL_SUMM_OTHER%'))
   ORDER BY  aso.owner, aso.name, aso.line;
   
  CURSOR cfinal(v_owner VARCHAR2, v_name VARCHAR2, v_line NUMBER) IS
  SELECT line
    FROM all_source aso
   WHERE aso.text like '%;%'
     AND owner = v_owner 
     AND name  = v_name 
     AND line >= v_line
  ORDER BY line;
  
  v_final         NUMBER;
  v_texto         VARCHAR2(32767);
  v_control       NUMBER := 0;
  v_leidos        NUMBER := 0;
  v_actualizar    NUMBER := 0;
  v_no_actualizar NUMBER := 0;
  v_estado        VARCHAR2(50);
  v_tipo          VARCHAR2(50);
  --v_sentencia     VARCHAR2(32767);

BEGIN
  
  -- Lee objetos en BD con el texto 
  FOR csr_inicial IN cinicial LOOP
    
    v_leidos := v_leidos + 1; -- cuenta registros leidos del cursor
         
     -- Busca linea final de la sentencia
     FOR reg_final IN cfinal(csr_inicial.owner, csr_inicial.name, csr_inicial.line) LOOP
       
       v_final := reg_final.line;
       EXIT;
     
     END LOOP;
     
     -- Busca el estado y tipo de objeto
     BEGIN
     SELECT ao.status, ao.object_type INTO v_estado, v_tipo
       FROM all_objects ao
      WHERE ao.owner = csr_inicial.owner AND ao.object_name = csr_inicial.name 
        AND (ao.object_type = 'PROCEDURE' OR ao.object_type = 'PACKAGE BODY' OR ao.object_type = 'TRIGGER');
     EXCEPTION
       WHEN OTHERS THEN
         v_estado := 'NO ENCONTRADO';
     END;
     
     -- Valida si esta actualizando el campo ROW_CHANGED_DATE en la sentencia
     SELECT COUNT(*) into v_control
      FROM dba_source
     WHERE owner = csr_inicial.owner AND name = csr_inicial.name AND line between csr_inicial.line AND v_final
       AND UPPER(text) LIKE '%ROW_CHANGED_DATE%';
     
     -- Si no existe
     IF v_control = 0 THEN
       v_actualizar := v_actualizar + 1;       
       DBMS_OUTPUT.PUT_LINE(csr_inicial.owner || '.' || csr_inicial.name || ';S;Linea[' || csr_inicial.line || '];' || v_estado || ';' || v_tipo);
     -- Si existe
     ELSE
       v_no_actualizar := v_no_actualizar + 1;
       DBMS_OUTPUT.PUT_LINE(csr_inicial.owner || '.' || csr_inicial.name || ';N;;' || v_estado || ';' || v_tipo);
     END IF;
        
  END LOOP;  
  
  -- Imprime conteos generales del proceso
  DBMS_OUTPUT.NEW_LINE();
  DBMS_OUTPUT.PUT_LINE('---- TOTAL LEIDOS     : ' || v_leidos);  
  DBMS_OUTPUT.PUT_LINE('---- REG. ACTUALIZAR  : ' || v_actualizar);
  DBMS_OUTPUT.PUT_LINE('---- REG NO ACTUALIZAR: ' || v_no_actualizar);

END;
