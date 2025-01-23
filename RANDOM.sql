SELECT ciudad, pais
                      FROM ciudades
                    WHERE UPPER(pais) = 'COLOMBIA'
					  AND NOT EXISTS ( SELECT 1 FROM destinos
                                               WHERE des_ciudad = ciudad
                                                 AND des_pais = pais
                                     )
                   ORDER BY DBMS_RANDOM.VALUE FETCH NEXT p_cant_ciudades_col ROWS ONLY