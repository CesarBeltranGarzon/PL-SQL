-- JSON Valor
SELECT eem_new_policy, 
       json_value(
                  eem_additional_info,
                  '$.product.coverage[0].value' 
                 ) dato
FROM events_co.evn_emission WHERE EEM_NEW_POLICY = '702710435542238121'

-- JSON QUERY
SELECT eem_new_policy, 
       json_query(
                  eem_additional_info,
                  '$.product[*]'--PRETTY
                 ) dato
FROM events_co.evn_emission WHERE EEM_NEW_POLICY = '702710435542238121'

--JSON_TABLE
SELECT ee.eem_new_policy
      ,json_value(ee.eem_additional_info,'$.product.prdId') producto, json_value(ee.eem_additional_info,'$.product.productTypesTprId') tipo
      ,ai.cobertura, ai.nombre, ai.valor, ai.fragment, ee.eem_additional_info
      ,json_value(ee.eem_additional_info,'$.personalInformation.documentType') tipo_documento
      ,json_value(ee.eem_additional_info,'$.personalInformation.documentNumber') documento
      ,SUBSTR(ee.eem_additional_info,INSTR(ee.eem_additional_info,'"id":"' || ai.cobertura || '"'),INSTR(SUBSTR(ee.eem_additional_info,INSTR(ee.eem_additional_info,'"id":"' || ai.cobertura || '"')),'}'))
  FROM events_co.evn_emission ee
      ,json_table(ee.eem_additional_info,
                  '$.product.coverage[*]' columns (
                                  cobertura VARCHAR2(5) PATH '$.id',
                                  nombre VARCHAR2(100) PATH '$.name', 
                                  valor NUMBER PATH '$.value',
                                  fragment VARCHAR2(2000) FORMAT JSON PATH '$'
                                  ) 
                 )AS ai
WHERE ee.eem_id = 4544

SELECT eem_additional_info, REPLACE(REPLACE(ai.cobertura,'[',''),']','') coverage
  FROM events_co.evn_emission ee
      ,json_table(ee.eem_additional_info,
                  '$.product.coverage[*]' columns ( cobertura VARCHAR2(2000) FORMAT JSON WITH WRAPPER PATH '$[*]') 
                 )AS ai
WHERE ee.eem_id = 4504

--
-- JSON QUERY
SELECT eem_new_policy, enum_rows, eem_additional_info,
       json_transform (
                       eem_additional_info, 
                       --remove '$.product.coverage.coverageCodeOds'
                       replace '$.product.coverage' = fragmento_nuevo
                      )
FROM events_co.tmp_emission_coverages_ok WHERE eem_id = 4544