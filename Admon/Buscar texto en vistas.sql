DECLARE

  lncount  NUMBER;
  lvsearch VARCHAR2(100) := upper('POOL_COMPONENT');
  CURSOR cur_views IS
    SELECT * FROM dba_views t;-- where owner = 'ADMONFUNC' AND text_length < 30000;
  lrow_views cur_views%ROWTYPE;
  v_line     VARCHAR2(30000);
BEGIN

  lncount := 0;
  OPEN cur_views;

  LOOP
  
    BEGIN
    
      FETCH cur_views
        INTO lrow_views;
      EXIT WHEN cur_views%NOTFOUND;
      --Convert LONG to VARCHAR2
      v_line := substr(lrow_views.text, 1, 30000);
      IF UPPER(v_line) LIKE '%' || lvsearch || '%' THEN
        dbms_output.put('Owner:' || lrow_views.owner);
        dbms_output.put_line(' ViewName:' || lrow_views.view_name);
        --   dbms_output.put(' Text:' || v_line);
        --   dbms_output.put_line('');
        lncount := lncount + 1;
      END IF;
    
    EXCEPTION
      WHEN OTHERS THEN
      --dbms_output.put_line(SQLCODE);dbms_output.put_line(SQLERRM);
        dbms_output.put_line('ERROR ViewName:' || lrow_views.view_name);
    END;
  END LOOP;

  dbms_output.put_line('');
  dbms_output.put_line(lncount ||
                       ' record(s) was found in ALL_VIEWS table.');

  CLOSE cur_views;

END;
