SELECT
decode(L.TYPE,'TM','TABLE','TX','Record(s)') TYPE_LOCK,
decode(L.REQUEST,0,'NO','YES') WAIT,
S.OSUSER OSUSER_LOCKER,
S.PROCESS PROCESS_LOCKER,
S.USERNAME DBUSER_LOCKER,
O.OBJECT_NAME OBJECT_NAME,
O.OBJECT_TYPE OBJECT_TYPE,
concat(' ',s.PROGRAM) PROGRAM,
O.OWNER OWNER
FROM v$lock l,dba_objects o,v$session s
WHERE l.ID1 = o.OBJECT_ID
AND s.SID =l.SID
AND l.TYPE in ('TM','TX');
