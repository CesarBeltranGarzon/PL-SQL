SELECT  JSON_ARRAYAGG( 
                       JSON_OBJECT ( 'event' VALUE JSON_OBJECT( 'id' VALUE ev.evn_id,
                                                                'type' VALUE ev.evn_type,
                                                                'status' VALUE st.evs_type,
                                                                'partnerId' VALUE PRD.PRT_ID,
                                                                'notification' VALUE NVL(evnn.ENT_STATUS,0) ),
                                     'emission' VALUE JSON_OBJECT( 'productId' VALUE emi.prd_id,
                                                                   'additionalInfo' VALUE emi.eem_additional_info,
                                                                   'newPolicy' VALUE emi.eem_new_policy,
                                                                   'productType' VALUE col.PRODUCT_TYPE, 
                                                                   'netPremium' VALUE emi.EEM_NET_PREMIUM,
                                                                   'date' VALUE TO_CHAR(emi.EEM_EMISSION, 'yyyy-mm-dd') ),
                                     'person' VALUE JSON_OBJECT( 'id' VALUE pe.PRS_ID,
                                                                 'idType' VALUE ti.tid_short,
                                                                 'identification' VALUE pe.PRS_NID )
                                    RETURNING CLOB )
                    ORDER BY ev.evn_id DESC RETURNING CLOB ), COUNT(1)
                        FROM   events_co.evn_events ev
                        INNER JOIN events_co.evn_emission emi 
                        ON emi.evn_id = ev.evn_id
                        INNER JOIN pers_co.prt_persons pe
                        ON pe.prs_id = ev.prs_id
                        INNER JOIN pers_co.prt_persons_individual pei
                        ON pei.prs_id = pe.prs_id
                        INNER JOIN PERS_CO.PRT_PRM_TYPE_ID ti
                        ON pe.PRS_ID_TYPE = ti.tid_id
                        INNER JOIN events_co.evn_prm_status st
                        ON st.evs_id = ev.evn_status
                        INNER JOIN PARAMS_CO.PRM_PRODUCTS PRD 
                        ON (emi.PRD_ID = PRD.PRD_ID)
                        LEFT JOIN EVENTS_CO.EVN_COLLECTION_INFO col
                        ON (col.EEM_ID = emi.EEM_ID)
                        LEFT JOIN EVENTS_CO.EVN_NOTIFICATION evnn
                        ON (evnn.EVN_ID = ev.EVN_ID)
                        WHERE 1=1 
                        AND NVL(TRIM(evnn.ent_status),0) in(select regexp_substr('1,4,0', '[^,]+', 1, level) from dual  connect BY regexp_substr('1,4,0', '[^,]+', 1, level) is not null)