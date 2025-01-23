-- http://www.oracle.com/technetwork/es/articles/sql/caracteristicas-database11g-2108415-esa.html

-- UNPIVOT
select a1,value
from
(
    (
        select
            '123445' a1,
            'a' v1,
            'e' v2,
            'i' v3,
            'o' v4,
            'u' v5
        from dual
    )
    unpivot
    (
        value
        for value_type in
            (v1,v2,v3,v4,v5)
    )
)

-- PIVOT
SELECT * FROM (
SELECT 1 llave, 55 exri, 'N' valor1 FROM DUAL
UNION ALL
SELECT 1 llave, 44 exri, '1125' FROM DUAL
UNION ALL
SELECT 1 llave, 33 exri, 'c' FROM DUAL
UNION ALL
SELECT 1 llave, 55 exri, '8888' FROM DUAL
)
PIVOT
(
  MAX(valor1)
  FOR (exri)
  IN (55 vis_novis,44 tipo_credito,33 otro)
)


--
SELECT  dat.fuente
       ,dat.id_clase_recaudo
       ,dat.des_clase_recaudo
       ,TO_CHAR(dat.registros_total,'999,999,999')           AS registros_total
       ,TO_CHAR(dat.importe_total,'999,999,999,999,999')     AS importe_total
       ,TO_CHAR(dat.conciliado_cantidad,'999,999,999')        AS registros_conciliados
       ,TO_CHAR(ROUND(((conciliado_cantidad * 100)/ Registros_total),2),'990D99') || '%' por_registros_conciliado
       ,TO_CHAR(dat.conciliado_importe, '999,999,999,999,999')       AS importe_conciliado
       ,TO_CHAR(ROUND(((conciliado_importe * 100) / importe_total),2),'990D99') || '%' por_importe_conciliado
       ,TO_CHAR(dat.no_conciliado_cantidad,'999,999,999')        AS registros_no_conciliados
       ,TO_CHAR(ROUND(((no_conciliado_cantidad * 100)/ Registros_total),2),'990D99') || '%' por_registros_no_conciliado
       ,TO_CHAR(dat.no_conciliado_importe, '999,999,999,999,999')       AS importe_no_conciliado
       ,TO_CHAR(ROUND(((no_conciliado_importe * 100) / importe_total),2),'990D99') || '%' por_importe_no_conciliado
FROM 
((
SELECT 'SCL' fuente
      ,id_clase_recaudo
      ,(SELECT des_clase_recaudo FROM scr_datos.scr_clase_recaudos WHERE id_clase_recaudo = dat.id_clase_recaudo) des_clase_recaudo
      ,DECODE(flag_conciliacion_contable,1,'CONCILIADO','NO CONCILIADO') concilia
      ,Registros_total
      ,importe
      ,importe_total
  FROM (SELECT a.id_clase_recaudo
              ,a.flag_conciliacion_contable
              ,a.importe
              ,COUNT(1) OVER (PARTITION BY a.id_clase_recaudo) Registros_total
              ,SUM(a.importe) OVER (PARTITION BY a.id_clase_recaudo) importe_total
         FROM SCR_DATOS.SCR_MAESTRA A
        WHERE a.id_tipo_fuente = 3
          AND a.id_clase_recaudo = 3
          AND a.id_tipo_movimiento = 1
          AND a.cod_tipdocum_sc IN (83, 88, 8)
          AND TO_CHAR(a.fecha_efectividad_scl,'mm/yyyy') = '10/2016'
       ) dat    
) a
PIVOT
(
   SUM(importe) importe,
   COUNT(1)     cantidad
   FOR 
      (concilia) 
   IN 
      ('CONCILIADO' conciliado,'NO CONCILIADO' no_conciliado)
)) dat


-- UNPIVOT multiples columnas
SELECT tra_id, poi_id, per_id, tit_id, tra_tot_usos, osi_id, codigo, ruta, vlr_cobrado, vlr_liquidado
  FROM metro.trayecto tr 
UNPIVOT ( (ruta, vlr_cobrado, vlr_liquidado)
          FOR codigo
           IN ( (rot_id1, tra_val_cobra1, tra_val_liq1) AS 1, 
                (rot_id2, tra_val_cobra2, tra_val_liq2) AS 2, 
                (rot_id3, tra_val_cobra3, tra_val_liq3) AS 3, 
                (rot_id4, tra_val_cobra4, tra_val_liq4) AS 4, 
                (rot_id5, tra_val_cobra5, tra_val_liq5) AS 5, 
                (rot_id6, tra_val_cobra6, tra_val_liq6) AS 6
              )
        )