-- Ver sesiones activas
select sid,username,status,osuser,process,machine,program,action,logon_time from v$session
where username is not null and status = 'ACTIVE'
--and osuser = '814832'
order by logon_time, sid;

-- Ver items especificos de la estadistica para un usuario activo
SELECT a.username,
       c.name, b.value, a.sql_id,
       CASE c.name
         WHEN 'user I/O wait time' THEN to_char(b.value / 100 / 60) --|| ' Minutos'
         WHEN 'session connect time' THEN to_char(b.value / 1000000 / 60) 
         ELSE
          TO_CHAR(b.value, '999,999,999,999')
       END,
       d.sql_text
  FROM v$session a, v$sesstat b, v$statname c, v$sql d
 WHERE a.sid = b.sid
   AND a.SQL_ID = d.SQL_ID
   AND a.osuser = 'facturacion'
   AND a.username = 'BILLCOLPER'
   AND a.status = 'ACTIVE'
   AND b.statistic# = c.statistic#
   AND b.statistic# IN (246, 4, 251, 52, 17,18); --  17 Tiempo Trascurrido, 4 User Commits

-- Ver sql de sesiones activas
select a.sid,a.username,a.status,a.osuser,a.program,a.action,b.sql_id,b.sql_text,a.logon_time
from v$session a, v$sql b
where a.SQL_ID = b.SQL_ID 
and a.username is not null and a.status = 'ACTIVE'
--and a.osuser = '814832'
order by a.logon_time, a.sid;

-- Ver objetos bloqueados
SELECT c.owner, c.object_name, c.object_type, b.SID, b.serial#, b.status,
       b.osuser, b.machine
  FROM v$locked_object a, v$session b, dba_objects c
 WHERE b.SID = a.session_id AND a.object_id = c.object_id;
