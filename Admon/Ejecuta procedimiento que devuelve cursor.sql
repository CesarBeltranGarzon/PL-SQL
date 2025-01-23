SET SERVEROUTPUT ON;
--SET autoprint on;
DECLARE
  v_cur   SYS_REFCURSOR;
  v_ses_id  VARCHAR2(10);
  v_estado VARCHAR2(10);
BEGIN
  
  PCK_0191_TRANSACCIONES_RECARGAS.SEL_EXISTE_SESION2(P_SES_ID => '106136273,106138250,106138256,106138252,106139249,12345612',
                                                    p_cursor => v_cur);
  
  LOOP
    FETCH v_cur INTO v_ses_id, v_estado;
    EXIT WHEN v_cur%notfound;
    dbms_output.put_line(v_ses_id || '  ' || v_estado);
  END LOOP;
  
END;