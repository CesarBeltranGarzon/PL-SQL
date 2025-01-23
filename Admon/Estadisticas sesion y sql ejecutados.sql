SELECT a.username,
       c.name,
       CASE c.name
         WHEN 'user I/O wait time' THEN
          to_char(b.value / 100 / 60, '999,999,999,999.00') || ' Minutos'
         WHEN 'session connect time' THEN
          to_char(b.value / 1000000 / 60, '999,999,999,999.00') || ' Minutos'
         ELSE
          TO_CHAR(b.value, '999,999,999,999')
       END,
       a.sql_id,
       d.sql_text,
       e.LAST_ACTIVE_TIME,
       e.LAST_ACTIVE_CHILD_ADDRESS,
       e.ROWS_PROCESSED,
       e.EXECUTIONS,
       e.CPU_TIME / 1000000 / 60,
       e.ELAPSED_TIME / 1000000 / 60
  FROM v$session a, v$sesstat b, v$statname c, v$sql d, V$SQLSTATS e
 WHERE a.sid = b.sid
   AND a.SQL_ID = d.SQL_ID
   AND a.sql_id = e.sql_id
   AND a.osuser = 'oracle'
   AND a.username = 'SYSTEM'
   AND a.status = 'ACTIVE'
      --AND a.sid = 971
   AND b.statistic# = c.statistic#
   AND b.statistic# IN (246, 4, 17);
