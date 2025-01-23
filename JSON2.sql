create or replace FUNCTION                     PRUEBA_LIST_BASIC_GENERAL (
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
        TYPE ref_cursor   IS REF CURSOR;
        crs_query                ref_cursor;

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
        counter number := -1;
    BEGIN
        
        dbms_lob.createtemporary(v_customer_clob, true);

        v_query  := '  SELECT  
                        ev.evn_id,
                        ev.evn_type,
                        st.evs_type,
                        PRD.PRT_ID partnerId,

                        emi.prd_id,
                        emi.eem_additional_info,
                        emi.eem_new_policy,
                        col.PRODUCT_TYPE AS productType, 
                        emi.EEM_NET_PREMIUM,
                        emi.EEM_EMISSION,

                        pe.PRS_ID,
                        ti.tid_short as PRS_ID_TYPE,
                        pe.PRS_NID,
                        NVL(evnn.ENT_STATUS,0)

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
        

        OPEN crs_query FOR v_query;
        LOOP
            counter := counter + 1;

            v_evnid := null;
            v_evntype := null;
            v_evstype := null;
            v_partnerId := null;
            v_prdid := null;
            v_eemadditionalinfo := null;
            v_eemnewpolicy := null;
            v_productType := null;
            v_EEMNETPREMIUM := null;
            v_PRSID := null;
            v_PRSIDTYPE := null;
            v_PRSNID := null;
            v_StatusNotif := null;
            v_EEMEMISSION := null;

            FETCH crs_query INTO
                v_evnid,
                v_evntype,
                v_evstype,
                v_partnerId,

                v_prdid,
                v_eemadditionalinfo,
                v_eemnewpolicy,
                v_productType,
                v_EEMNETPREMIUM,
                v_EEMEMISSION,
                v_PRSID,
                v_PRSIDTYPE,
                v_PRSNID,

                v_StatusNotif;

            EXIT WHEN crs_query%notfound;
              
              -- Arma JSON
              SELECT DECODE(counter,0,'[',',') || '{"event":{"id":' || v_evnid || ',"type":"' || v_evntype || '","status":"' || v_evstype || '","partnerId":' || v_partnerId || ',"notification":"' || v_StatusNotif || '"},'
                     || '"emission":{"productId":' || v_prdid || ',"additionalInfo":"' || v_eemadditionalinfo ||  '","newPolicy":"' || v_eemnewpolicy || '","productType":"' || v_productType || '","netPremium":"' || v_EEMNETPREMIUM || '","date":"' || v_EEMEMISSION || '"},'
                     || '"person":{"id":' || v_PRSID || ',"idType":"' || v_PRSIDTYPE || '","identification":"' || v_PRSNID || '"}}'
                INTO v_customer_clob1
                FROM DUAL;
            
            -- Arma salida CLOB  
            dbms_lob.append(v_customer_clob, v_customer_clob1);  
            
        END LOOP;

        CLOSE crs_query;
        
        dbms_lob.append(v_customer_clob, ']');
        dbms_output.put_line(counter);

        po_error_code   := '200';
        po_error_msg    := 'Success';

        if counter = 0 then
            po_error_code   := '204';
            po_error_msg    := 'No Data Found';
        end if;

        RETURN v_customer_clob;
        EXCEPTION
            WHEN OTHERS THEN
                po_error_code   := '500';
                --po_error_msg    := sqlerrm;
                po_error_msg    := DBMS_UTILITY.FORMAT_ERROR_STACK  || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ;
                CLOSE crs_query;
                RETURN '500';
END PRUEBA_LIST_BASIC_GENERAL;