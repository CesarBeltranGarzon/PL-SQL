create or replace FUNCTION                               PRUEBA_LIST_BASIC_GENERAL3 (

    pi_PRS_ID_TYPE IN VARCHAR2,  -- Document type
    pi_PRS_NID IN VARCHAR2,  -- Document number
    pi_PRT_ID IN VARCHAR2,  -- Partner Id
    pi_EVN_TYPE IN VARCHAR2, -- Event type
    pi_EVS_TYPE IN VARCHAR2,  -- Event status
    pi_EVN_ID IN VARCHAR2, -- Event id
    pi_Initial_Search_Date IN VARCHAR2,  -- Initial date
    pi_final_Search_Date IN VARCHAR2, -- Final date
    pi_ENT_STATUS IN VARCHAR2,  -- Notification
    po_error_code OUT VARCHAR2, 
    po_error_msg OUT VARCHAR2) 
    RETURN CLOB is
        
        v_customer_clob1         CLOB;
        v_customer_clob          CLOB;
        v_query                  CLOB;
        v_counter                NUMBER;

        v_evnid                  events_co.evn_events.evn_id%TYPE;
        v_evntype                events_co.evn_events.evn_type%TYPE;
        v_evstype                events_co.evn_prm_status.evs_type%TYPE;
        v_partnerId              PARAMS_CO.PRM_PRODUCTS.PRT_ID%TYPE;
        v_prdid                  events_co.evn_emission.prd_id%TYPE;
        v_eemadditionalinfo      events_co.evn_emission.eem_additional_info%TYPE;
        v_eemnewpolicy           events_co.evn_emission.eem_new_policy%TYPE;
        v_EEMEMISSION            events_co.evn_emission.EEM_EMISSION%TYPE;
        v_productType            VARCHAR2(500);
        v_EEMNETPREMIUM          events_co.evn_emission.EEM_NET_PREMIUM%TYPE;
        v_PRSID                  pers_co.prt_persons.PRS_ID%TYPE;
        v_PRSIDTYPE              PERS_CO.PRT_PRM_TYPE_ID.tid_short%TYPE;
        v_PRSNID                 pers_co.prt_persons.PRS_NID%TYPE;
        v_PINGENDER              pers_co.prt_persons_individual.PIN_GENDER%TYPE;
        v_StatusNotif            EVENTS_CO.EVN_NOTIFICATION.ENT_STATUS%TYPE;
        
    BEGIN

        v_query  := '  SELECT JSON_ARRAYAGG( 
                       JSON_OBJECT ( ''event'' VALUE JSON_OBJECT(''id'' VALUE ev.evn_id,
                                                                ''type'' VALUE ev.evn_type,
                                                                ''status'' VALUE st.evs_type,
                                                                ''partnerId'' VALUE PRD.PRT_ID,
                                                                ''notification'' VALUE NVL(evnn.ENT_STATUS,0) ),
                                     ''emission'' VALUE JSON_OBJECT( ''productId'' VALUE emi.prd_id,
                                                                   ''additionalInfo'' VALUE emi.eem_additional_info,
                                                                   ''newPolicy'' VALUE emi.eem_new_policy,
                                                                   ''productType'' VALUE col.PRODUCT_TYPE, 
                                                                   ''netPremium'' VALUE emi.EEM_NET_PREMIUM,
                                                                   ''date'' VALUE TO_CHAR(emi.EEM_EMISSION, ''yyyy-mm-dd'') ),
                                     ''person'' VALUE JSON_OBJECT( ''id'' VALUE pe.PRS_ID,
                                                                 ''idType'' VALUE ti.tid_short,
                                                                 ''identification'' VALUE pe.PRS_NID )
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
                        WHERE 1=1';

        IF ( pi_PRT_ID IS NOT NULL ) THEN
            v_query   := v_query || ' AND PRD.PRT_ID = ''' || pi_PRT_ID || '''';
        END IF;

        IF ( pi_EVN_TYPE IS NOT NULL ) THEN
                        v_query   := v_query
                        || ' AND TRIM(ev.evn_type)  in(select regexp_substr(''' || pi_EVN_TYPE || ''', ''[^,]+'', 1, level) from dual '
                        || ' connect BY regexp_substr(''' || pi_EVN_TYPE || ''', ''[^,]+'', 1, level) is not null)';
        END IF;

        IF ( pi_EVS_TYPE IS NOT NULL ) THEN
                        v_query   := v_query
                        || ' AND TRIM(st.evs_type)  in(select regexp_substr(''' || pi_EVS_TYPE || ''', ''[^,]+'', 1, level) from dual '
                        || ' connect BY regexp_substr(''' || pi_EVS_TYPE || ''', ''[^,]+'', 1, level) is not null)';
        END IF;

        IF ( pi_ENT_STATUS IS NOT NULL ) THEN
                        v_query   := v_query
                        || ' AND NVL(TRIM(evnn.ent_status),0)  in(select regexp_substr(''' || pi_ENT_STATUS || ''', ''[^,]+'', 1, level) from dual '
                        || ' connect BY regexp_substr(''' || pi_ENT_STATUS || ''', ''[^,]+'', 1, level) is not null)';
        END IF;

        IF ( pi_EVN_ID IS NOT NULL ) THEN
            v_query   := v_query || ' AND ev.evn_id IN (' || pi_EVN_ID || ')';
        END IF;  

        IF ( pi_Initial_Search_Date IS NOT NULL AND pi_final_Search_Date IS NOT NULL) THEN
            v_query   := v_query
                        || ' and trunc(emi.EEM_CREATED) BETWEEN TO_DATE ('''
                        || pi_Initial_Search_Date
                        || ''', ''yyyy-mm-dd'') AND TO_DATE ('''
                        || pi_final_Search_Date
                        || ''', ''yyyy-mm-dd'')';
        end if;

        v_query := v_query || ' order by ev.evn_id desc';
        dbms_output.put_line('Consulta query ' || v_query);
        dbms_output.new_line();

        dbms_lob.createtemporary(v_customer_clob, true);
        EXECUTE IMMEDIATE v_query INTO v_customer_clob, v_counter;
        
        dbms_output.put_line('Cantidad Registros ' || v_counter);
        dbms_output.new_line();

        po_error_code   := '200';
        po_error_msg    := 'Success';

        if v_counter = 0 then
            po_error_code   := '204';
            po_error_msg    := 'No Data Found';
        end if;

        RETURN v_customer_clob;
        EXCEPTION
            WHEN OTHERS THEN
                po_error_code   := '500';
                --po_error_msg    := sqlerrm;
                po_error_msg    := DBMS_UTILITY.FORMAT_ERROR_STACK  || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ;
                RETURN '500';
                
END PRUEBA_LIST_BASIC_GENERAL3;