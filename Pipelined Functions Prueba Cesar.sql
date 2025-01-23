DECLARE

  v_funcion VARCHAR2(32767);
  v_tipo1   VARCHAR2(32767);
  v_tipo2   VARCHAR2(32767);

BEGIN
  
  v_tipo1 := 'CREATE OR REPLACE TYPE scr_datos.tp_detalle as OBJECT
  (
   id_relacion NUMBER,
   importe_scl NUMBER,
   importe_sap NUMBER
  )';

  v_tipo2 := 'CREATE OR REPLACE TYPE scr_datos.fetch_detalle AS TABLE OF tp_detalle';

  v_funcion := 'CREATE OR REPLACE FUNCTION SCR_DATOS.fn_scr_prueba
  RETURN fetch_detalle
  PIPELINED AS

  CURSOR c_scl IS
    SELECT sl.id_relacion, SUM(importe) valor
      FROM usr_batch_scr.SCL_SCL_CONCILIA sl
     GROUP BY sl.id_relacion
     ORDER BY sl.id_relacion;

  CURSOR c_sap IS
    select sp.id_relacion, SUM(importe) valor
      from usr_batch_scr.SCL_SAP_CONCILIA sp
     GROUP BY sp.id_relacion
     ORDER BY sp.id_relacion;
    
  /*TYPE tp_detalle IS RECORD
  (
   id_relacion NUMBER,
   importe_scl NUMBER,
   importe_sap NUMBER
  );
  
  TYPE fetch_detalle IS TABLE OF tp_detalle;*/
  
  /* crear estos tipos:
  
  CREATE OR REPLACE TYPE scr_datos.tp_detalle as OBJECT
  (
   id_relacion NUMBER,
   importe_scl NUMBER,
   importe_sap NUMBER
  );
  
  CREATE OR REPLACE TYPE scr_datos.fetch_detalle AS TABLE OF tp_detalle;
  
  Al final hacer el select:
  SELECT * FROM TABLE(scr_datos.fn_scr_prueba());
  */

  v_encontrado NUMBER;

BEGIN

  FOR dat_scl IN c_scl LOOP

    v_encontrado := 0;

    FOR dat_sap IN c_sap LOOP

      IF dat_scl.id_relacion = dat_sap.id_relacion THEN

        v_encontrado := 1;

        IF dat_scl.valor + dat_sap.valor <> 0 THEN
          PIPE ROW(tp_detalle(dat_scl.id_relacion,dat_scl.valor,dat_sap.valor));         
        END IF;

        EXIT;

      END IF;

    END LOOP;

  END LOOP;

  RETURN;

END;';

  -- Si existen los objetos los borra
  BEGIN
  
    EXECUTE IMMEDIATE 'DROP TYPE scr_datos.fetch_detalle';
    EXECUTE IMMEDIATE 'DROP TYPE scr_datos.tp_detalle';
  
  EXCEPTION
  
    WHEN OTHERS THEN
      NULL;
    
  END;
  
  -- Crea objetos
  EXECUTE IMMEDIATE v_tipo1;
  EXECUTE IMMEDIATE v_tipo2;
  EXECUTE IMMEDIATE v_funcion;

END;

/* Ejecucion
SELECT * FROM TABLE(scr_datos.fn_scr_prueba());
*/

/* Borrado de objetos

BEGIN
  -- Si existen los objetos los borra
  EXECUTE IMMEDIATE 'DROP TYPE scr_datos.fetch_detalle';
  EXECUTE IMMEDIATE 'DROP TYPE scr_datos.tp_detalle';
  EXECUTE IMMEDIATE 'DROP FUNCTION scr_datos.fn_scr_prueba';
END;
*/
