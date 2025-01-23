DECLARE
  
  CURSOR csr_programa IS
  SELECT TRIM(UPPER(text)) texto 
    FROM all_source aso
   WHERE aso.owner = '&pr_esquema'
     AND aso.name  = '&pr_nombre';
  
  v_sentencia   VARCHAR2(500); 
  v_inicial     NUMBER;
  v_longitud    NUMBER;
  v_longitud2   NUMBER;
  v_espacios    VARCHAR2(500) := NULL;
  v_instruccion VARCHAR2(50);
  v_iniciado    VARCHAR2(1) := 'N';

BEGIN
  -- Lee el codigo del objeto
  FOR reg_programa IN csr_programa LOOP
    
    -- interpreta Inicio
    IF reg_programa.texto like '%BEGIN%' AND v_iniciado = 'N' THEN
      
      v_instruccion := 'BEGIN';
      v_iniciado    := 'S';
      DBMS_OUTPUT.PUT_LINE('INICIO PROGRAMA ' || '&pr_nombre'); 
        
    -- interpreta condicional END IF
    ELSIF reg_programa.texto like '%END IF%' THEN
      
      -- Identacion
      v_espacios := SUBSTR(v_espacios,1,LENGTH(v_espacios)-2);
      
      v_instruccion := 'END IF';      
      v_sentencia := 'FIN SI';
      DBMS_OUTPUT.PUT_LINE(v_espacios || v_sentencia); 
    
    -- interpreta condicional IF
    ELSIF reg_programa.texto like '%IF%' THEN
      
      -- Identacion
      IF v_instruccion = 'IF' OR v_instruccion = 'FOR' OR v_instruccion = 'BEGIN' OR v_instruccion = 'ELSE' OR v_instruccion = 'EXCEPTION' THEN
        v_espacios := v_espacios || '  ';
      END IF;
      
      v_longitud := INSTR(reg_programa.texto,'THEN',1);
      
      IF v_longitud = 0 THEN
        v_longitud := LENGTH(reg_programa.texto)-3;
      END IF;
      
      v_instruccion := 'IF';
      v_sentencia := SUBSTR(reg_programa.texto,INSTR(reg_programa.texto,'IF',1)+2,v_longitud);
      DBMS_OUTPUT.PUT_LINE(v_espacios ||'SI ' || v_sentencia); 
    
    -- interpreta condicional ELSE
    ELSIF reg_programa.texto like '%ELSE%' THEN
      
      -- Identacion
      v_espacios := SUBSTR(v_espacios,1,LENGTH(v_espacios)-2);
    
      v_instruccion := 'ELSE';
      v_sentencia := 'SINO';
      DBMS_OUTPUT.PUT_LINE(v_espacios || v_sentencia); 
    
    -- interpreta insercion
    ELSIF reg_programa.texto like '%INSERT INTO%' THEN
      
      -- Identacion
      IF v_instruccion = 'IF' OR v_instruccion = 'FOR' OR v_instruccion = 'BEGIN' OR v_instruccion = 'ELSE' OR v_instruccion = 'EXCEPTION' THEN
        v_espacios := v_espacios || '  ';
      END IF;
      
      v_instruccion := 'INSERT';
      v_longitud := INSTR(reg_programa.texto,' ',1,3)-11;
      v_sentencia := SUBSTR(reg_programa.texto,INSTR(reg_programa.texto,'INSERT INTO',1)+11,v_longitud);
      DBMS_OUTPUT.PUT_LINE(v_espacios ||'INSERTA EN' || v_sentencia); 
    
    -- interpreta actualizacion
    ELSIF reg_programa.texto like '%UPDATE%' THEN
      
      -- Identacion
      IF v_instruccion = 'IF' OR v_instruccion = 'FOR' OR v_instruccion = 'BEGIN' OR v_instruccion = 'ELSE' OR v_instruccion = 'EXCEPTION' THEN
        v_espacios := v_espacios || '  ';
      END IF;
      
      v_longitud := INSTR(reg_programa.texto,' ',1,2)-6;
      
      IF v_longitud = 0 THEN
        v_longitud := 50;
      END IF;
      
      v_instruccion := 'UPDATE';
      v_sentencia := SUBSTR(reg_programa.texto,INSTR(reg_programa.texto,'UPDATE',1)+6,v_longitud);
      DBMS_OUTPUT.PUT_LINE(v_espacios || 'ACTUALIZA TABLA' || v_sentencia); 
          
    -- interpreta condicional ELSE
    ELSIF reg_programa.texto like '%RAISE_APPLICATION_ERROR%' THEN
      
      -- Identacion
      IF v_instruccion = 'IF' OR v_instruccion = 'FOR' OR v_instruccion = 'BEGIN' OR v_instruccion = 'ELSE' OR v_instruccion = 'EXCEPTION' THEN
        v_espacios := v_espacios || '  ';
      END IF;
      
      v_longitud    := INSTR(reg_programa.texto,';',1)-24;    
      v_instruccion := 'RAISE_APPLICATION_ERROR';
      v_sentencia   := 'ERROR GENERADO DELIBERADAMENTE' || SUBSTR(reg_programa.texto,24,v_longitud);
      DBMS_OUTPUT.PUT_LINE(v_espacios || v_sentencia); 
      
    -- interpreta condicional EXCEPTION
    ELSIF reg_programa.texto like '%EXCEPTION%' THEN
            
      v_longitud    := INSTR(reg_programa.texto,';',1)-24;    
      v_instruccion := 'EXCEPTION';
      v_sentencia   := 'SECCION DE EXCEPCIONES';
      DBMS_OUTPUT.PUT_LINE(v_espacios || v_sentencia); 
      
    -- interpreta condicional WHEN OTHERS
    ELSIF reg_programa.texto like '%WHEN OTHERS%' THEN
            
      -- Identacion
      IF v_instruccion = 'IF' OR v_instruccion = 'FOR' OR v_instruccion = 'BEGIN' OR v_instruccion = 'ELSE' OR v_instruccion = 'EXCEPTION' THEN
        v_espacios := v_espacios || '  ';
      END IF;
            
      v_instruccion := 'EXCEPTION';
      v_sentencia   := 'WHEN OTHERS';
      DBMS_OUTPUT.PUT_LINE(v_espacios || v_sentencia); 
    
    -- interpreta consultas SELECT
    ELSIF reg_programa.texto like '%SELECT%' THEN
            
      -- SELECT
      -- Identacion
      IF v_instruccion = 'IF' OR v_instruccion = 'FOR' OR v_instruccion = 'BEGIN' OR v_instruccion = 'ELSE' OR v_instruccion = 'EXCEPTION' THEN
        v_espacios := v_espacios || '  ';
      END IF;         
            
      v_instruccion := 'SELECT';
      v_sentencia   := 'CONSULTA';
      DBMS_OUTPUT.PUT_LINE(v_espacios || v_sentencia);      
      
      -- CAMPOS 
      v_longitud := INSTR(reg_programa.texto,'INTO',1);
      
      IF v_longitud = 0 THEN
        v_longitud := 50;
      END IF;
            
      v_sentencia   := 'Campos' || SUBSTR(reg_programa.texto,7,v_longitud-7);
      DBMS_OUTPUT.PUT_LINE(v_espacios || v_sentencia); 
      
      -- INTO 
      v_inicial  := INSTR(reg_programa.texto,'INTO',1)+5;
      v_longitud := INSTR(reg_programa.texto,'FROM',1);
      
      IF v_longitud = 0 THEN
        v_longitud := 50;
      END IF;
            
      v_sentencia   := 'En variables ' || SUBSTR(reg_programa.texto,v_inicial,v_longitud-v_inicial);
      DBMS_OUTPUT.PUT_LINE(v_espacios || v_sentencia); 
      
      -- TABLAS
      v_inicial  := INSTR(reg_programa.texto,'FROM',1)+5;
      v_longitud := INSTR(reg_programa.texto,'WHERE',1);
      
      IF v_longitud = 0 THEN
        v_longitud := 50;
      END IF;
            
      v_sentencia   := 'Tablas ' || SUBSTR(reg_programa.texto,v_inicial,v_longitud-v_inicial);
      DBMS_OUTPUT.PUT_LINE(v_espacios || v_sentencia); 
      DBMS_OUTPUT.NEW_LINE(); 
      
    END IF;
  
  END LOOP;
  
  DBMS_OUTPUT.PUT_LINE('FINAL PROGRAMA'); 

END;
