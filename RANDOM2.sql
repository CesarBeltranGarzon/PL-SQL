WITH
 tarjetas_activas1 AS
 ( SELECT 'tarjeta_' || ROWNUM ide, activa1
     FROM ( SELECT car_id activa1
                    FROM metro.cartao
                    WHERE SCA_ID = 3
                    OFFSET (SELECT dbms_random.value(1,1000) FROM DUAL) ROWS FETCH NEXT 5 ROWS ONLY )
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY )
 ,tarjetas_activas2 AS
 ( SELECT 'tarjeta_' || ROWNUM ide, activa2
   FROM ( SELECT car_id activa2
                    FROM metro.cartao
                    WHERE SCA_ID = 3
                    AND NOT EXISTS ( SELECT 1 FROM tarjetas_activas1 ta1 WHERE activa1 = car_id )
                    OFFSET (SELECT dbms_random.value(1,1000) FROM DUAL) ROWS FETCH NEXT 5 ROWS ONLY )
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY )
  ,tarjetas_activas3 AS
 ( SELECT 'tarjeta_' || ROWNUM ide, activa3
    FROM ( SELECT car_id activa3
                    FROM metro.cartao
                    WHERE SCA_ID = 3
                    AND NOT EXISTS ( SELECT 1 FROM tarjetas_activas1 ta1 WHERE activa1 = car_id )
                    AND NOT EXISTS ( SELECT 1 FROM tarjetas_activas2 ta2 WHERE activa2 = car_id )
                    OFFSET (SELECT dbms_random.value(1,1000) FROM DUAL) ROWS FETCH NEXT 5 ROWS ONLY )
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY )
SELECT activa1, activa2, activa3
  FROM tarjetas_activas1 a
      ,tarjetas_activas2 b
      ,tarjetas_activas3 c
WHERE a.ide = b.ide
  AND a.ide = c.ide