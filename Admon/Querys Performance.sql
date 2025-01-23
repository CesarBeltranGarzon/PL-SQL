-- DB Health
-- ---------------------------------------------------
-- Created    :   2010.06.17
-- Function   :   Script para chequear el estado general de una base de datos
-- http://oramdq.blogspot.com/2009/06/chequeo-general-de-una-base-de-datos.html
-- http://www.oracle-base.com/dba/DBACategories.php

-- 1 - Usuarios con tablespace SYSTEM como temporary tablespace (exceptuando users SYS y SYSTEM)
-- ---------------------------------------------------------------------------------------------

select username,default_tablespace
from dba_users
where default_tablespace = 'SYSTEM'
  and username not in ('SYS','SYSTEM');

-- 2 - Usuarios con tablespace SYSTEM como default tablespace (exceptuando users SYS y SYSTEM)
-- -----------------------------------------------------------------------------------------

select username,temporary_tablespace
from dba_users
where temporary_tablespace = 'SYSTEM'
  and username not in ('SYS','SYSTEM');


-- 3 - Indices UNUSABLES
-- ---------------------

select owner,count(1)
from dba_indexes
where status = 'INVALID'
group by owner;

select owner,
       index_name,
       index_type,
       table_owner,
       table_name,
       table_type,
       tablespace_name
from dba_indexes
where status = 'INVALID';


-- 4 - Objetos invalidos
-- ---------------------

select owner,object_type,count(1)
from dba_objects
where status = 'INVALID'
group by owner,object_type
order by 1,2;

select owner,
       object_type,
       object_name,
       created,
       last_ddl_time
from dba_objects
where status = 'INVALID'
order by 1,2;


-- 5 - Paquetes con bodies sin que no tengan sus correspondientes headers
-- ----------------------------------------------------------------------

select unique owner,name
from dba_source a
where type = 'PACKAGE BODY'
  and not exists (select null
                  from dba_source b
                  where a.owner = b.owner
                    and a.name = b.name
                    and b.type = 'PACKAGE');


-- 6 - Constraints deshabilitadas
-- ------------------------------

select owner,
       case constraint_type
          when 'P' then 'PRIMARY_KEY'
          when 'R' then 'FOREIGN_KEY'
          when 'U' then 'UNIQUE'
          when 'C' then 'CHECK'
       end constraint_type,  
       count(1)
from dba_constraints
where status = 'DISABLED'
group by owner,constraint_type
order by 1,2;

select owner,
       constraint_name,
       constraint_type,
       table_name
from dba_constraints
where status = 'DISABLED'
order by 1,2;

-- 7 - Triggers deshabilitados
-- ---------------------------

select owner,
       trigger_name,
       trigger_type,
       triggering_event,
       table_owner,
       table_name
from dba_triggers
where status = 'DISABLED'
order by 1,2;


-- 8 - Controlar que sys.aud$ no este en tablespace SYSTEM
-- -------------------------------------------------------

select name,
       value,
       display_value,
       description
from v$parameter
where name like 'audit%';

select owner,
       segment_name,
       tablespace_name
from dba_segments
where segment_name = 'AUD$';


-- 9 - Jobs en estado broken
-- -------------------------

select * from dba_jobs
where broken = 'Y';


-- 10 - Jobs con next_date menor a sysdate
-- ---------------------------------------

select *
from dba_jobs
where sysdate > next_date;


-- 11 - Jobs con fallas
------------------------

select *
from dba_jobs
where failures > 0;


-- 12 - Roles no otorgados a ningun rol o user
-- -------------------------------------------

select role from dba_roles
minus
select granted_role from dba_role_privs;

-- 13 - Sinonimos publicos que apuntan a objetos inexistentes
-- ----------------------------------------------------------

select * from dba_synonyms a
where owner = 'PUBLIC'
  and not exists (select null
                  from dba_objects b
                  where a.table_owner = b.owner
                    and a.table_name  = b.object_name);


-- 14 - Sinonimos privados que apuntan a objetos inexistentes
-- ----------------------------------------------------------

select * from dba_synonyms a
where owner != 'PUBLIC'
  and not exists (select null
                  from dba_objects b
                  where a.table_owner = b.owner
                    and a.table_name  = b.object_name);

-- 15 - Database links que son inaccesibles
-- ----------------------------------------

begin
    for i in (select decode(owner,'PUBLIC',user,owner) owner,db_link from dba_db_links)
    loop
       begin
           execute immediate 'create view '||i.owner||'.TEST as select count(1) c from dual@'||i.db_link;
           dbms_output.put_line('OWNER: '||i.owner||'; DB_LINK: '||i.db_link||' --> ACCESIBLE');
           execute immediate 'drop view '||i.owner||'.TEST';
           exception
             when others then
                 dbms_output.put_line('OWNER: '||i.owner||'; DB_LINK: '||i.db_link||' --> NO ACCESIBLE');
       end;
    end loop;
end;

-- 16 - Segmentos con mas de 100 extents (excluir sys y system)
-- ----------------------------------------------------------------

select * from dba_segments
where extents > 100
  and owner not in ('SYS','SYSTEM');


-- 17 - Tablas no analizadas con mas de 1000 registros
-------------------------------------------------------
-- Salida es demasiado grande toca crear spool
set serveroutput on size 100000000
spool 'C:\Documents and Settings\cbeltran\My Documents\Performance\tablas_grandes_no_analizadas.txt'
declare
  l_cnt int;
begin
  for i in (select *
              from dba_tables
             where last_analyzed is null
               and owner not in ('SYS', 'SYSTEM', 'DBSNMP', 'OUTLN', 'SYSMAN',
                    'TSMSYS', 'WMSYS', 'ADMON', 'PRUEBAS')
               and Upper(table_name) not like '%EXT'
             order by 1) loop
    begin
      execute immediate 'select count(1) from ' || i.owner || '.' ||
                        i.table_name
        into l_cnt;
    exception
      when others then
        dbms_output.put_line('Tabla: ' || i.owner || '.' || i.table_name ||
                             ' Presento error al accesarla.  Puede ser tabla externa.');
    end;
    if (l_cnt > 1000) then
      dbms_output.put_line(i.owner || '.' || i.table_name);
    end if;
  end loop;
end;
/
spool off

-- 18 - Tablas con mas del 1% de chained rows
-- ------------------------------------------

select owner,table_name,num_rows,chain_cnt from dba_tables
where owner not in ('SYS','SYSTEM')
  and chain_cnt/num_rows > 0.01
  and num_rows > 0;


-- 19 - Tablas con mas de 5 indices
-- --------------------------------

select owner,table_name,count(1)
from dba_indexes
where owner not in ('SYS','SYSTEM')
group by owner,table_name
having count(1) > 5
order by 3 desc, 1, 2;


-- 20 - Tablas con indices superfluos
-- ----------------------------------

select a.index_name || '(' || a.cols || ')' cols,
       b.index_name || '(' || b.cols || ')' cols
from (select index_name,  table_name,
      rtrim(
            max(decode(column_position,1,column_name,null)) || ',' ||
                    max(decode(column_position,2,column_name,null)) || ',' ||
                    max(decode(column_position,3,column_name,null)) || ',' ||
                    max(decode(column_position,4,column_name,null)) || ',' ||
                    max(decode(column_position,5,column_name,null)) || ',' ||
                    max(decode(column_position,6,column_name,null)) || ',' ||
                    max(decode(column_position,7,column_name,null)) || ',' ||
                    max(decode(column_position,8,column_name,null)) || ',' ||
                    max(decode(column_position,9,column_name,null)) || ',' ||
                    max(decode(column_position,10,column_name,null)) , ',' ) cols
           from user_ind_columns
          group by table_name, index_name ) a,
          (select index_name,  table_name,
                  rtrim(
                        max(decode(column_position,1,column_name,null)) || ',' ||
                    max(decode(column_position,2,column_name,null)) || ',' ||
                    max(decode(column_position,3,column_name,null)) || ',' ||
                    max(decode(column_position,4,column_name,null)) || ',' ||
                    max(decode(column_position,5,column_name,null)) || ',' ||
                    max(decode(column_position,6,column_name,null)) || ',' ||
                    max(decode(column_position,7,column_name,null)) || ',' ||
                    max(decode(column_position,8,column_name,null)) || ',' ||
                    max(decode(column_position,9,column_name,null)) || ',' ||
                    max(decode(column_position,10,column_name,null)) , ',' ) cols
           from user_ind_columns
          group by table_name, index_name ) b
    where a.table_name = b.table_name
      and a.index_name <> b.index_name
      and a.cols like '%'
      and b.cols like '%';


-- 21 - Tablas que no poseean primary key y que no esten vacias
-- ------------------------------------------------------------

select owner,table_name
from dba_tables a
where owner not in ('SYS','SYSTEM')
  and num_rows > 0
  and not exists (select null
                  from dba_constraints b
                  where a.owner = b.owner
                    and a.table_name = b.table_name
                    and b.constraint_type = 'P')
order by 1,2;


-- 22 - Tablas que no tengan los parametros de storage defaults
-- ------------------------------------------------------------


select a.owner,a.table_name,a.pct_increase,a.initial_extent,a.next_extent,
       a.max_extents,a.min_extents,b.tablespace_name
from dba_tables a,
     dba_tablespaces b
where a.tablespace_name = b.tablespace_name
  and a.owner not in ('SYS','SYSTEM')
  and (a.pct_increase != b.pct_increase
       or a.initial_extent != b.initial_extent
       or a.next_extent != b.next_extent
       or a.max_extents != b.max_extents
       or a.min_extents != b.min_extents);


-- 23 - Tablas con valores pct_free o pct_used no defaults
-- -------------------------------------------------------


select owner,table_name
from dba_tables
where  owner not in ('SYS','SYSTEM')
  and (pct_free != 10
       or pct_used != 40);


-- 24 - Indices no analizados
-- --------------------------

select owner,index_name,table_name
from dba_indexes
where owner not in ('SYS','SYSTEM')
  and last_analyzed is null;


-- 25 - Foreign keys sin indices asociados (Analizar a nivel usuario)
-- ---------------------------------------


select decode( b.table_name, NULL, '****', 'ok' ) Status,
     a.table_name, a.columns, b.columns
from
( select substr(a.table_name,1,30) table_name,
     substr(a.constraint_name,1,30) constraint_name,
       max(decode(position, 1,     substr(column_name,1,30),NULL))
       max(decode(position, 2,', 'substr(column_name,1,30),NULL))
       max(decode(position, 3,', 'substr(column_name,1,30),NULL))
       max(decode(position, 4,', 'substr(column_name,1,30),NULL))
       max(decode(position, 5,', 'substr(column_name,1,30),NULL))
       max(decode(position, 6,', 'substr(column_name,1,30),NULL))
       max(decode(position, 7,', 'substr(column_name,1,30),NULL))
       max(decode(position, 8,', 'substr(column_name,1,30),NULL))
       max(decode(position, 9,', 'substr(column_name,1,30),NULL))
       max(decode(position,10,', 'substr(column_name,1,30),NULL))
       max(decode(position,11,', 'substr(column_name,1,30),NULL))
       max(decode(position,12,', 'substr(column_name,1,30),NULL))
       max(decode(position,13,', 'substr(column_name,1,30),NULL))
       max(decode(position,14,', 'substr(column_name,1,30),NULL))
       max(decode(position,15,', 'substr(column_name,1,30),NULL))
       max(decode(position,16,', 'substr(column_name,1,30),NULL)) columns
    from user_cons_columns a, user_constraints b
   where a.constraint_name = b.constraint_name
     and b.constraint_type = 'R'
   group by substr(a.table_name,1,30), substr(a.constraint_name,1,30) ) a,
( select substr(table_name,1,30) table_name, substr(index_name,1,30) index_name,
       max(decode(column_position, 1,     substr(column_name,1,30),NULL))
       max(decode(column_position, 2,', 'substr(column_name,1,30),NULL))
       max(decode(column_position, 3,', 'substr(column_name,1,30),NULL))
       max(decode(column_position, 4,', 'substr(column_name,1,30),NULL))
       max(decode(column_position, 5,', 'substr(column_name,1,30),NULL))
       max(decode(column_position, 6,', 'substr(column_name,1,30),NULL))
       max(decode(column_position, 7,', 'substr(column_name,1,30),NULL))
       max(decode(column_position, 8,', 'substr(column_name,1,30),NULL))
       max(decode(column_position, 9,', 'substr(column_name,1,30),NULL))
       max(decode(column_position,10,', 'substr(column_name,1,30),NULL))
       max(decode(column_position,11,', 'substr(column_name,1,30),NULL))
       max(decode(column_position,12,', 'substr(column_name,1,30),NULL))
       max(decode(column_position,13,', 'substr(column_name,1,30),NULL))
       max(decode(column_position,14,', 'substr(column_name,1,30),NULL))
       max(decode(column_position,15,', 'substr(column_name,1,30),NULL))
       max(decode(column_position,16,', 'substr(column_name,1,30),NULL)) columns
    from user_ind_columns
   group by substr(table_name,1,30), substr(index_name,1,30) ) b
where a.table_name = b.table_name (+)
  and b.columns (+) like a.columns  '%';


-- 26 - Tablespaces con Manejo de Extents por Diccionario
-- ------------------------------------------------------

select tablespace_name
from dba_tablespaces
where extent_management = 'DICTIONARY';


-- 27 - Tablespaces con Manejo de Segmentos Manual
-- ------------------------------------------------------

select tablespace_name
from dba_tablespaces
where segment_space_management = 'MANUAL'
  and contents = 'PERMANENT';

-- 28 - Tablas con mas de 100 columnas
-- -------------------------------------------------------------------

select owner,table_name,count(1)
from dba_tab_columns
where owner not in ('SYS','SYSTEM')
group by owner,table_name
having count(1) > 100;

-- 29 - Owners que comparten tablespaces
-- ------------------------------------------------------------------

select a.owner,b.owner,
       a.tablespace_name,
       a.cantseg,
       b.cantseg
from (select owner,tablespace_name,count(1) cantseg
      from dba_segments
      where owner not in ('SYS','SYSTEM','SYSMAN','OUTLN','DBSNMP','SYSAUX')
      group by owner,tablespace_name) a,
      (select owner,tablespace_name,count(1) cantseg
      from dba_segments
      where owner not in ('SYS','SYSTEM','SYSMAN','OUTLN','DBSNMP','SYSAUX')
      group by owner,tablespace_name) b
where a.tablespace_name = b.tablespace_name
  and a.owner != b.owner
order by a.cantseg+b.cantseg desc;

-- 30 -Tablas Candidatas para Particionar
-- ------------------------------------------------------------------

select unique a.object_owner Esquema,a.object_name Tabla, trim(to_char(b.num_rows,'999G999G999')) Registros ,a.options Acceso
from dba_hist_sql_plan a,
     dba_tab_statistics b
where a.object_owner = b.owner
  and a.object_name = b.table_name
  and a.options = 'FULL'
  and b.num_rows > 10000000;

-- 30 - Tablas con fullscan
-- ------------------------------------------------------------------
select dhsp.object_owner Esquema, dhsp.object_name Objeto, count(*) num, sum(dhsp.cpu_cost) sum_cpu_cost, min(timestamp) primera_ejecucion, max(timestamp) ultima_ejecucion
from Dba_Hist_Sql_Plan dhsp
where dhsp.operation = 'TABLE ACCESS'
and dhsp.options='FULL'
and dhsp.object_owner!='SYS'
and dhsp.object_owner!='SYSTEM'
and dhsp.object_owner!='SYSMAN'
group by dhsp.object_owner, dhsp.object_name
order by count(*) desc, sum(dhsp.cpu_cost) desc;

-- 30 - Querys que hacen que se haga fullscan en tablas
-- ------------------------------------------------------------------
select to_char(substr(dhst.sql_text, 1, 3000)) sql,
       dhsp.object_owner Esquema,
       dhsp.object_name Objeto,
       count(*) Cantidad
  from dba_hist_sqltext dhst, Dba_Hist_Sql_Plan dhsp
 where dhsp.operation = 'TABLE ACCESS'
   and dhsp.options = 'FULL'
   and dhsp.object_owner != 'SYS'
   and dhsp.object_owner != 'SYSTEM'
   and dhsp.object_owner != 'SYSMAN'
   and dhsp.sql_id = dhst.sql_id
 group by to_char(substr(dhst.sql_text, 1, 3000)),
          dhsp.object_owner,
          dhsp.object_name
 order by count(*) desc

-- 30 - Bloqueos
-- ------------------------------------------------------------------
select t.SQL_TEXT, t.LAST_ACTIVE_TIME, c.owner Esquema, c.object_name Objetos
, DECODE(l.block, 0, 'Not Blocking', 1, 'Blocking', 2, 'Global') STATUS
, DECODE(a.locked_mode, 0, 'None', 1, 'Null', 2, 'Row-S (SS)', 3, 'Row-X (SX)', 4, 'Share', 5, 'S/Row-X (SSX)', 6, 'Exclusive', TO_CHAR(lmode)) MODE_HELD
, DECODE(l.type, 'RT','Redo Log Buffer', 'TD','Dictionary', 'TM','DML', 'TS','Temp Segments', 'TX','Transaction', 'UL','User', 'RW','Row Wait', l.type) LOCK_TYPE
, c.object_type, s.sid, s.serial#, s.status, s.osuser, s.machine, s.logon_time
from gv$sqlarea t
, gv$process p
, gv$lock l
, gv$locked_object a
, gv$session s
, dba_objects c
where s.sid = a.session_id
and a.object_id = c.object_id
and p.addr = s.paddr
and t.ADDRESS=s.SQL_ADDRESS
and (a.object_id = l.id1)
order by s.inst_id, s.username, s.logon_time;

-- 31 - Espacio libre y ocupado en Tablespaces
-- ------------------------------------------------------------------
SELECT d.status "Status", d.tablespace_name "Name", d.contents "Type",
       TO_CHAR(NVL(nvl(a.bytes,b.bytes) / 1024 / 1024, 0),'99G999G990D900') "Size (M)",
       TO_CHAR(NVL(nvl(a.bytes,b.bytes) - NVL(f.bytes, 0),0)/1024/1024, '99G999G990D900') "Used (M)",
       TO_CHAR(NVL((nvl(a.bytes,b.bytes) - NVL(f.bytes, 0)) / nvl(a.bytes,b.bytes) * 100, 0), '990D00') "Used %"
FROM   sys.dba_tablespaces d,
       (select tablespace_name, sum(bytes) bytes
        from dba_data_files group by tablespace_name) a,
        (select tablespace_name, sum(bytes) bytes
        from dba_temp_files group by tablespace_name) b,
       (select tablespace_name, sum(bytes) bytes
        from dba_free_space group by tablespace_name) f
WHERE  d.tablespace_name = a.tablespace_name(+) AND
       d.tablespace_name = b.tablespace_name(+) AND
       d.tablespace_name = f.tablespace_name(+);
       
-- 32 - Consulta Oracle SQL para obtener todas las funciones de Oracle: NVL, ABS, LTRIM, ...
-- ------------------------------------------------------------------      
SELECT distinct object_name
  FROM all_arguments
 WHERE package_name = 'STANDARD'
 order by object_name;
 
-- 33 - Consulta Oracle SQL para conocer el espacio ocupado por usuario
-- ------------------------------------------------------------------      
SELECT owner, SUM(BYTES)/1024/1024 MB FROM DBA_EXTENTS
group by owner; 

-- 34 - Analizar las tablas por usuario
-- ------------------------------------------------------------------ 
SELECT 'ANALYZE TABLE "' || table_name || '" COMPUTE STATISTICS;'
FROM   all_tables
WHERE  owner = Upper('&1')
ORDER BY 1;

-- 35 - Muestra datos de tablas por usuario
-- ------------------------------------------------------------------ 
SELECT t.table_name AS "Table Name", 
       t.num_rows AS "Rows", 
       t.avg_row_len AS "Avg Row Len", 
       Trunc((t.blocks * p.value)/1024) AS "Size KB", 
       t.last_analyzed AS "Last Analyzed"
FROM   dba_tables t,
       v$parameter p
WHERE t.owner = Decode(Upper('&1'), 'ALL', t.owner, Upper('&1'))
AND   p.name = 'db_block_size'
ORDER by t.table_name;

-- 36 - Muestra informacion de particiones de una tabla y esquema
-- ------------------------------------------------------------------ 
SELECT a.table_name,
       a.partition_name,
       a.tablespace_name,
       a.initial_extent,
       a.next_extent,
       a.pct_increase,
       a.num_rows,
       a.avg_row_len
FROM   dba_tab_partitions a
WHERE  a.table_name  = Decode(Upper('&Tabla'),'ALL',a.table_name,Upper('&Tabla'))
AND    a.table_owner = Upper('&Esquema')
ORDER BY a.table_name, a.partition_name

-- 37 - Objetos que dependen de una tabla u objeto
-- ------------------------------------------------------------------ 
SELECT Substr(ad.referenced_owner, 1, 10) "Esquema",
       ad.referenced_name "Objeto",
       ad.referenced_type "Tipo",
       Substr(ad.referenced_link_name, 1, 20) "Ref Link Name",
       ad.name "Objeto que depende",
       ad.type "Tipo",
       ad.owner "esquema"
  FROM all_dependencies ad
 WHERE ad.referenced_name = Upper('&Objeto_Referenciado')
 and Substr(ad.referenced_owner, 1, 10) = Upper('&Esquema')
 and ad.referenced_type like Upper('%&Tipo_objeto%')
 ORDER BY 1, 2, 3;
 
-- 38 - Objetos que usan DBLINK
-- ------------------------------------------------------------------  
SELECT unique aso.owner || '.' || aso.name, aso.type--, aso.line , dbl.db_link, Trim(aso.text)
  FROM all_source aso, DBA_DB_LINKS dbl
 WHERE Upper(aso.owner) NOT IN ('ADMON',
                                'SYSTEM',
                                'SYS',
                                'SYSMAN',
                                'OUTLN',
                                'PRUEBAS',
                                'ALVEIRO_ORDONEZ',
                                'BRIGITTE_RUEDA',
                                'EDISON_VELANDIA',
                                'JAMES_RIANO',
                                'JAVIER_HUERTAS',
                                'JOHN_CAMARGO',
                                'MONICA_CURE',
                                'SARA_MURCIA',
                                'VIVIAN_MORENO')
   AND Upper(aso.text) LIKE '%@' || Upper(dbl.db_link) || '%'
 order by 1, 2;

-- 39 - Ver todo el código de un objeto
-- ------------------------------------------------------------------  
SELECT *
  FROM all_source
 WHERE Upper(owner) = 'HOMOLOGACION'
   AND Upper(name) = 'FN_ESTADO_CLIENTE'
      --AND type = 'PACKAGE BODY'
   AND text like '%@%'
   AND text not like '  ** %'
   AND text not like '** %';
