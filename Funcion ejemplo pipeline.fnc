CREATE OR REPLACE FUNCTION fn_scr_prueba
  RETURN fetch_detalle
  PIPELINED AS

  /* crear estos tipos:
  
  CREATE OR REPLACE TYPE tp_detalle as OBJECT
  (
  id_detalle NUMBER,
  detalle    VARCHAR2(2000)
  );
  
  CREATE OR REPLACE TYPE fetch_detalle AS TABLE OF tp_detalle;
  
  Al final hacer el select:
  SELECT * FROM TABLE(fn_scr_prueba());
  */

  CURSOR cur_unicos IS -- 142810 duplicados, 71290 unicos
    SELECT * FROM tbl_wrk_gesrec g1
    WHERE g1.id_pago IN (SELECT g.id_pago
                        FROM tbl_wrk_gesrec g
                       GROUP BY g.id_pago
                      HAVING COUNT(*) > 1)
      AND g1.archivo_cargado IN (SELECT MIN(g2.ARCHIVO_CARGADO)
                                  FROM tbl_wrk_gesrec g2
                                 WHERE g2.id_pago = g1.id_pago);

  CURSOR cur_duplicados(v_id_pago NUMBER) IS
   SELECT * FROM tbl_wrk_gesrec g WHERE g.id_pago = v_id_pago;
  
  v_campo_diferente  VARCHAR2(32000);
  i                  NUMBER := 0;

BEGIN

  FOR reg_unicos IN cur_unicos LOOP

    v_campo_diferente := NULL;
    i := i + 1;

    FOR reg_duplicados IN cur_duplicados(reg_unicos.id_pago) LOOP

      IF reg_duplicados.tipo_registro <> reg_unicos.tipo_registro THEN
        v_campo_diferente := v_campo_diferente ||'tipo_registro,';
      END IF;

      IF reg_duplicados.clase_documento <> reg_unicos.clase_documento THEN
        v_campo_diferente := v_campo_diferente ||'clase_documento,';
      END IF;

      IF reg_duplicados.fecha_documento <> reg_unicos.fecha_documento THEN
        v_campo_diferente := v_campo_diferente ||'fecha_documento,';
      END IF;

      IF reg_duplicados.fecha_contabilizacion <> reg_unicos.fecha_contabilizacion THEN
        v_campo_diferente := v_campo_diferente ||'fecha_contabilizacion,';
      END IF;

      IF reg_duplicados.cabecera_documento <> reg_unicos.cabecera_documento THEN
        v_campo_diferente := v_campo_diferente ||'cabecera_documento,';
      END IF;

      IF reg_duplicados.documento_referencia <> reg_unicos.documento_referencia THEN
        v_campo_diferente := v_campo_diferente ||'documento_referencia,';
      END IF;

      IF reg_duplicados.clave_contabilizacion <> reg_unicos.clave_contabilizacion THEN
        v_campo_diferente := v_campo_diferente ||'clave_contabilizacion,';
      END IF;

      IF reg_duplicados.indicador_cuenta <> reg_unicos.indicador_cuenta THEN
        v_campo_diferente := v_campo_diferente ||'indicador_cuenta,';
      END IF;

      IF reg_duplicados.importe <> reg_unicos.importe THEN
        v_campo_diferente := v_campo_diferente ||'importe,';
      END IF;

      IF reg_duplicados.indicador_iva <> reg_unicos.indicador_iva THEN
        v_campo_diferente := v_campo_diferente ||'indicador_iva,';
      END IF;

      IF reg_duplicados.numero_asignacion <> reg_unicos.numero_asignacion THEN
        v_campo_diferente := v_campo_diferente ||'numero_asignacion,';
      END IF;

      IF reg_duplicados.texto_posicion <> reg_unicos.texto_posicion THEN
        v_campo_diferente := v_campo_diferente ||'texto_posicion,';
      END IF;

      IF reg_duplicados.cuenta_deudor <> reg_unicos.cuenta_deudor THEN
        v_campo_diferente := v_campo_diferente ||'cuenta_deudor,';
      END IF;

      IF reg_duplicados.subsegmento <> reg_unicos.subsegmento THEN
        v_campo_diferente := v_campo_diferente ||'subsegmento,';
      END IF;

      IF reg_duplicados.servicio <> reg_unicos.servicio THEN
        v_campo_diferente := v_campo_diferente ||'servicio,';
      END IF;

      IF reg_duplicados.region <> reg_unicos.region THEN
        v_campo_diferente := v_campo_diferente ||'region,';
      END IF;

      IF reg_duplicados.tipo_trafico <> reg_unicos.tipo_trafico THEN
        v_campo_diferente := v_campo_diferente ||'tipo_trafico,';
      END IF;

      IF reg_duplicados.tipo_empresa <> reg_unicos.tipo_empresa THEN
        v_campo_diferente := v_campo_diferente ||'tipo_empresa,';
      END IF;

      IF reg_duplicados.valor_dist_davox <> reg_unicos.valor_dist_davox THEN
        v_campo_diferente := v_campo_diferente ||'valor_dist_davox,';
      END IF;

      IF reg_duplicados.valor_dist_scl <> reg_unicos.valor_dist_scl THEN
        v_campo_diferente := v_campo_diferente ||'valor_dist_scl,';
      END IF;

      IF reg_duplicados.fk_incs_cod <> reg_unicos.fk_incs_cod THEN
        v_campo_diferente := v_campo_diferente ||'fk_incs_cod,';
      END IF;

      IF reg_duplicados.campo_2 <> reg_unicos.campo_2 THEN
        v_campo_diferente := v_campo_diferente ||'campo_2,';
      END IF;

      IF reg_duplicados.dpg_f_sol_inc <> reg_unicos.dpg_f_sol_inc THEN
        v_campo_diferente := v_campo_diferente ||'dpg_f_sol_inc,';
      END IF;

      IF reg_duplicados.lcd_desc <> reg_unicos.lcd_desc THEN
        v_campo_diferente := v_campo_diferente ||'lcd_desc,';
      END IF;

      IF reg_duplicados.fecha_ingreso <> reg_unicos.fecha_ingreso THEN
        v_campo_diferente := v_campo_diferente ||'fecha_ingreso,';
      END IF;

      IF reg_duplicados.fecha_efectividad_scl <> reg_unicos.fecha_efectividad_scl THEN
        v_campo_diferente := v_campo_diferente ||'fecha_efectividad_scl,';
      END IF;

      IF reg_duplicados.fecha_efectividad_davox <> reg_unicos.fecha_efectividad_davox THEN
        v_campo_diferente := v_campo_diferente ||'fecha_efectividad_davox,';
      END IF;

      IF reg_duplicados.fecha_efectividad_atis <> reg_unicos.fecha_efectividad_atis THEN
        v_campo_diferente := v_campo_diferente ||'fecha_efectividad_atis,';
      END IF;

      IF reg_duplicados.referencia <> reg_unicos.referencia THEN
        v_campo_diferente := v_campo_diferente ||'referencia,';
      END IF;

      IF reg_duplicados.id_pago <> reg_unicos.id_pago THEN
        v_campo_diferente := v_campo_diferente ||'id_pago,';
      END IF;

      IF reg_duplicados.medio_pago <> reg_unicos.medio_pago THEN
        v_campo_diferente := v_campo_diferente ||'medio_pago,';
      END IF;

      IF reg_duplicados.fecha_carga <> reg_unicos.fecha_carga THEN
        v_campo_diferente := v_campo_diferente ||'fecha_carga,';
      END IF;

      IF reg_duplicados.usuario_carga <> reg_unicos.usuario_carga THEN
        v_campo_diferente := v_campo_diferente ||'usuario_carga,';
      END IF;

      IF reg_duplicados.archivo_cargado <> reg_unicos.archivo_cargado THEN
        v_campo_diferente := v_campo_diferente ||'archivo_cargado,';
      END IF;

      IF reg_duplicados.id_catalogo_fuen <> reg_unicos.id_catalogo_fuen THEN
        v_campo_diferente := v_campo_diferente ||'id_catalogo_fuen,';
      END IF;

    END LOOP;

    --c_detalle.extend;
    --c_detalle(i).id_pago := reg_unicos.id_pago;
    --c_detalle(i).detalle := v_campo_diferente;
    --DBMS_OUTPUT.PUT_LINE(reg_unicos.id_pago || ' [' || v_campo_diferente || ']');
    PIPE ROW(tp_detalle(reg_unicos.id_pago,v_campo_diferente));

  END LOOP;

  RETURN;

END;
/
