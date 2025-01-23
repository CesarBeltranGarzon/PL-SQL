/*--------------------------------------------------------------------
  Consultas SQL útiles para obtener información sobre Oracle Database
---------------------------------------------------------------------*/
-- COnstraint Oracle
Type Code Type Description  Acts On Level
C Check on a table  Column
O Read Only on a view Object
P Primary Key Object
R Referential AKA Foreign Key Column

select *
                  from all_constraints a
                          ,sys.all_cons_columns b
                  where a.constraint_name = b.constraint_name
                     and a.owner = 'AXIOMDATA'
                    and a.table_name IN ('TEMP429570', 'CITI_EXT_TAP406843')

-- Indices
SELECT TABLE_NAME TABLA, INDEX_NAME NOMBRE_INDICE, COLUMN_NAME COLUMNA, COLUMN_POSITION POSICION 
FROM USER_IND_COLUMNS
ORDER BY TABLE_NAME, INDEX_NAME, COLUMN_POSITION;

SELECT a.*, 'ESPACIO', b.*
FROM USER_IND_COLUMNS a
            ,all_ind_columns b
WHERE a.table_name = b.table_name
  AND a.index_name = b.index_name
  AND a.table_name IN ('TEMP429570', 'CITI_EXT_TAP406843')
ORDER BY a.TABLE_NAME, a.INDEX_NAME, a.COLUMN_POSITION;

--Vista que muestra el estado de la base de datos:
select * from v$instance

--Consulta que muestra si la base de datos está abierta:
select status from v$instance

--Vista que muestra los parámetros generales de Oracle:
select * from v$system_parameter

--Versión de Oracle:
select value 
from v$system_parameter 
where name = 'compatible'

--Ubicación y nombre del fichero spfile:
select value 
from v$system_parameter 
where name = 'spfile'

--Ubicación y número de ficheros de control:
select value 
from v$system_parameter 
where name = 'control_files'

--Nombre de la base de datos
select value 
from v$system_parameter 
where name = 'db_name'

--Vista que muestra las conexiones actuales a Oracle:
select osuser, username, machine, program 
  from v$session 
  order by osuser
  
--Vista que muestra el número de conexiones actuales a Oracle agrupado por aplicación que realiza la conexión
select program Aplicacion, count(program) Numero_Sesiones
from v$session
group by program 
order by Numero_Sesiones desc

--Vista que muestra los usuarios de Oracle conectados y el número de sesiones por usuario
select username Usuario_Oracle, count(username) Numero_Sesiones
from v$session
group by username
order by Numero_Sesiones desc

--Propietarios de objetos y número de objetos por propietario
select owner, count(owner) Numero 
  from dba_objects 
  group by owner 
  order by Numero desc
  
--Diccionario de datos (incluye todas las vistas y tablas de la Base de Datos):
select * from dictionary

select table_name from dictionary
  
--Muestra los datos de una tabla especificada (en este caso todas las tablas que lleven la cadena "EMPLO"):
select * 
from ALL_ALL_TABLES 
where upper(table_name) like '%EMPLO%'

--Muestra los disparadores (triggers) de la base de datos Oracle Database:
 select *
from ALL_TRIGGERS 

--Tablas propiedad del usuario actual:
select * from user_tables

--Todos los objetos propiedad del usuario conectado a Oracle:
select * from user_catalog

--Consulta SQL para el DBA de Oracle que muestra los tablespaces, el espacio utilizado, el espacio libre y los ficheros de datos de los mismos:
Select t.tablespace_name  "Tablespace",  t.status "Estado",  
    ROUND(MAX(d.bytes)/1024/1024,2) "MB Tamaño",
    ROUND((MAX(d.bytes)/1024/1024) - 
    (SUM(decode(f.bytes, NULL,0, f.bytes))/1024/1024),2) "MB Usados",   
    ROUND(SUM(decode(f.bytes, NULL,0, f.bytes))/1024/1024,2) "MB Libres", 
    t.pct_increase "% incremento", 
    SUBSTR(d.file_name,1,80) "Fichero de datos"  
FROM DBA_FREE_SPACE f, DBA_DATA_FILES d,  DBA_TABLESPACES t  
WHERE t.tablespace_name = d.tablespace_name  AND 
    f.tablespace_name(+) = d.tablespace_name    
    AND f.file_id(+) = d.file_id GROUP BY t.tablespace_name,   
    d.file_name,   t.pct_increase, t.status ORDER BY 1,3 DESC
    
--Productos Oracle instalados y la versión:
select * from product_component_version

--Roles y privilegios por roles:
select * from role_sys_privs

--Reglas de integridad y columna a la que afectan:
select constraint_name, column_name 
from sys.all_cons_columns

--Tablas de las que es propietario un usuario, en este caso "HR":
SELECT table_owner, table_name 
from sys.all_synonyms 
where table_owner like 'HR'

--Otra forma más efectiva (tablas de las que es propietario un usuario):
SELECT DISTINCT TABLE_NAME 
FROM ALL_ALL_TABLES 
WHERE OWNER LIKE 'HR' 

--Parámetros de Oracle, valor actual y su descripción:
SELECT v.name, v.value value, decode(ISSYS_MODIFIABLE, 'DEFERRED', 
     'TRUE', 'FALSE') ISSYS_MODIFIABLE,  decode(v.isDefault, 'TRUE', 'YES',
     'FALSE', 'NO') "DEFAULT",  DECODE(ISSES_MODIFIABLE,  'IMMEDIATE',  
     'YES','FALSE',  'NO',  'DEFERRED', 'NO', 'YES') SES_MODIFIABLE,   
     DECODE(ISSYS_MODIFIABLE, 'IMMEDIATE', 'YES',  'FALSE', 'NO',  
     'DEFERRED', 'YES','YES') SYS_MODIFIABLE ,  v.description  
FROM V$PARAMETER v 
WHERE name not like 'nls%'   ORDER BY 1
  
--Usuarios de Oracle y todos sus datos (fecha de creación, estado, id, nombre, tablespace temporal,...):
Select  * FROM dba_users

--Tablespaces y propietarios de los mismos:
select owner, decode(partition_name, null, segment_name, 
   segment_name || ':' || partition_name) name, 
   segment_type, tablespace_name,bytes,initial_extent, 
   next_extent, PCT_INCREASE, extents, max_extents 
from dba_segments 
Where 1=1 And extents > 1 order by 9 desc, 3 

--Últimas consultas SQL ejecutadas en Oracle y usuario que las ejecutó:
select distinct vs.sql_text, vs.sharable_mem, 
  vs.persistent_mem, vs.runtime_mem,  vs.sorts,
  vs.executions, vs.parse_calls, vs.module,  
  vs.buffer_gets, vs.disk_reads, vs.version_count, 
  vs.users_opening, vs.loads,  
  to_char(to_date(vs.first_load_time,
  'YYYY-MM-DD/HH24:MI:SS'),'MM/DD  HH24:MI:SS') first_load_time,  
  rawtohex(vs.address) address, vs.hash_value hash_value , 
  rows_processed  , vs.command_type, vs.parsing_user_id  , 
  OPTIMIZER_MODE  , au.USERNAME parseuser  
from v$sqlarea vs , all_users au   
where (parsing_user_id != 0)  AND 
(au.user_id(+)=vs.parsing_user_id)  
and (executions >= 1) order by   buffer_gets/executions desc 

--Todos los ficheros de datos y su ubicación:
select * from V$DATAFILE

--Ficheros temporales:
select * from V$TEMPFILE

--Tablespaces:
select * from V$TABLESPACE

--Otras vistas muy interesantes:
select * from V$BACKUP

select * from V$ARCHIVE   

select * from V$LOG   

select * from V$LOGFILE    

select * from V$LOGHIST          

select * from V$ARCHIVED_LOG    

select * from V$DATABASE

--Memoria Share_Pool libre y usada:
select name,to_number(value) bytes 
from v$parameter where name ='shared_pool_size'
union all
select name,bytes 
from v$sgastat where pool = 'shared pool' and name = 'free memory'
  
--Cursores abiertos por usuario:
select b.sid, a.username, b.value Cursores_Abiertos
      from v$session a,
           v$sesstat b,
           v$statname c
      where c.name in ('opened cursors current')
      and   b.statistic# = c.statistic#
      and   a.sid = b.sid 
      and   a.username is not null
      and   b.value >0
      order by 3
      
--Aciertos de la caché (no debe superar el 1 por ciento):
select sum(pins) Ejecuciones, sum(reloads) Fallos_cache,
  trunc(sum(reloads)/sum(pins)*100,2) Porcentaje_aciertos 
from v$librarycache
where namespace in ('TABLE/PROCEDURE','SQL AREA','BODY','TRIGGER');

--Sentencias SQL completas ejecutadas con un texto determinado en el SQL:
SELECT c.sid, d.piece, c.serial#, c.username, d.sql_text 
FROM v$session c, v$sqltext d 
WHERE  c.sql_hash_value = d.hash_value 
  and upper(d.sql_text) like '%WHERE CAMPO LIKE%'
ORDER BY c.sid, d.piece

--Una sentencia SQL concreta (filtrado por sid):
SELECT c.sid, d.piece, c.serial#, c.username, d.sql_text 
FROM v$session c, v$sqltext d 
WHERE  c.sql_hash_value = d.hash_value and sid = 105
ORDER BY c.sid, d.piece

--Tamaño ocupado por la base de datos
select sum(BYTES)/1024/1024 MB 
from DBA_EXTENTS  

--Tamaño de los ficheros de datos de la base de datos:
select sum(bytes)/1024/1024 MB 
from dba_data_files

--Tamaño ocupado por una tabla concreta sin incluir los índices de la misma
select sum(bytes)/1024/1024 MB 
from user_segments
where segment_type='TABLE' and segment_name='NOMBRETABLA'

--Tamaño ocupado por una tabla concreta incluyendo los índices de la misma
select sum(bytes)/1024/1024 Table_Allocation_MB 
from user_segments
where segment_type in ('TABLE','INDEX') and
  (segment_name='NOMBRETABLA' or segment_name in
    (select index_name 
     from user_indexes 
     where table_name='NOMBRETABLA'))
     
--Tamaño ocupado por una columna de una tabla:
select sum(vsize('NOMBRECOLUMNA'))/1024/1024 MB 
from NOMBRETABLA

--Espacio ocupado por usuario:
SELECT owner, SUM(BYTES)/1024/1024 
FROM DBA_EXTENTS MB
GROUP BY owner

--Espacio ocupado por los diferentes segmentos (tablas, índices, undo, rollback, cluster, ...):
SELECT SEGMENT_TYPE, SUM(BYTES)/1024/1024 
FROM DBA_EXTENTS MB
GROUP BY SEGMENT_TYPE

--Espacio ocupado por todos los objetos de la base de datos, muestra los objetos que más ocupan primero:
SELECT SEGMENT_NAME, SUM(BYTES)/1024/1024 
FROM DBA_EXTENTS MB
GROUP BY SEGMENT_NAME
ORDER BY 2 DESC

--Obtener todas las funciones de Oracle: NVL, ABS, LTRIM, ...:
SELECT distinct object_name 
FROM all_arguments 
WHERE package_name = 'STANDARD'
order by object_name

--Obtener los roles existentes en Oracle Database:
select * from DBA_ROLES

--Obtener los privilegios otorgados a un rol de Oracle:
select privilege 
from dba_sys_privs 
where grantee = 'NOMBRE_ROL'

--Obtener la IP del servidor de la base de datos Oracle Database:
select utl_inaddr.get_host_address IP
from dual 

--Mostrar datos de auditoría de la base de datos Oracle (inicio y desconexión de sesiones):
select username, action_name, priv_used, returncode
from dba_audit_trail

--Comprobar si la auditoría de la base de datos Oracle está activada:
select name, value
from v$parameter
where name like 'audit_trail'
