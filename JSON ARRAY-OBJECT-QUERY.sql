SELECT * FROM (
SELECT
            NVL( JSON_ARRAYAGG(json_object(
            key 'PRM_ID' VALUE PV.PRM_ID,
            key 'PRM_NAME' VALUE PV.PRM_NAME,            
            key 'PRM_DESCRIPTION' VALUE PV.PRM_DESCRIPTION,
            key 'PRM_CODE' VALUE PV.PRM_CODE,
            key 'PRM_STATE' VALUE PV.PRM_STATE,
            key 'values' VALUE ( 
                SELECT NVL(JSON_QUERY(json_object(
                key 'prmId' VALUE PVV.PRM_ID,
                key 'prmVariableId' VALUE PVV.PRM_VALUE_ID,
                key 'prmValue' VALUE PVV.PRM_VALUE
                 FORMAT JSON)
                ,'$'),'{}') 
                FROM PARAMS_CO.PRM_VARIABLE_VALUE PVV 
                WHERE PV.PRM_ID = PVV.PRM_ID
                AND PVV.PRM_STATE = 'A'
           ) FORMAT JSON
          ) 
         ),'{}') JSON
        FROM PARAMS_CO.PRM_VARIABLE PV
        WHERE 
        PV.PRM_STATE = 'A'
        AND (PV.PRM_CODE = 'Product_AvVillas')
        )A 
        WHERE A.JSON IS JSON        ;