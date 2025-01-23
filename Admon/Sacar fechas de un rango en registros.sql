-- Fechas que no existen de un rango
WITH datos as
 (SELECT ev.well_id,
         ev.event_id,
         w.wellbore_id,
         ws.datum,
         ev.event_code,
         TO_DATE(TO_CHAR(ev.date_ops_start, 'dd/mm/yyyy'), 'dd/mm/yyyy') fecini,
         TO_DATE(TO_CHAR(ev.date_ops_end, 'dd/mm/yyyy'), 'dd/mm/yyyy') fecfin
    FROM ow_dm_event_t ev, ow_cd_wellbore_t w, ow_cd_well_source ws
   WHERE ev.well_id = w.well_id
     AND ev.well_id = ws.well_id
     AND ev.well_id = '&wellid'
     AND ev.event_code IN ('ODR', 'REN'))
SELECT datos.well_id, datos.event_id, fecini, fecfin, fecini + i dias_rango, datos.wellbore_id, datos.datum, datos.event_code
  FROM datos, ow_dm_daily_t d, xmltable('for $i in 0 to xs:int(D) return $i' passing xmlelement(d, datos.fecfin - datos.fecini) columns i integer path '.')
  WHERE datos.well_id = d.well_id
  AND   datos.event_id = d.event_id
  AND   datos.fecini + i <> d.date_report

-- 
INSERT INTO ow_dm_daily_t(well_id, event_id, daily_id, wellbore_id, date_report, report_no, md_current, datum )
WITH datos as
 (SELECT ev.well_id,
         ev.event_id,
         w.wellbore_id,
         ws.datum,
         ev.event_code,
         TO_DATE(TO_CHAR(ev.date_ops_start, 'dd/mm/yyyy'), 'dd/mm/yyyy') fecini,
         TO_DATE(TO_CHAR(ev.date_ops_end, 'dd/mm/yyyy'), 'dd/mm/yyyy') fecfin
    FROM ow_dm_event_t ev, ow_cd_wellbore_t w, ow_cd_well_source ws
   WHERE ev.well_id = w.well_id
     AND ev.well_id = ws.well_id
     AND ev.well_id = '&wellid'
     AND ev.event_code IN ('ODR', 'REN'))
SELECT datos.well_id, datos.event_id, EDMADMIN.GENERATE_KEY@BD_OW_PRUEBAS(5), datos.wellbore_id, fecini + i, 
       RJC_NO(datos.well_id,'DAILY',datos.event_code), 0, datos.datum
  FROM datos, ow_dm_daily_t d, xmltable('for $i in 0 to xs:int(D) return $i' passing xmlelement(d, datos.fecfin - datos.fecini) columns i integer path '.')
  WHERE datos.well_id = d.well_id
  AND   datos.event_id = d.event_id
  AND   datos.fecini + i <> d.date_report

--VALUES (reg_base.well_id, reg_base.event_id, vDailyid,reg_base.wellbore_id, vFechaentre, RJC_NO(reg_base.well_id,'DAILY',reg_base.event_code), 0, reg_base.datum);

