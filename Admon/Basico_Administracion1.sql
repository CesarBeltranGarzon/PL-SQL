-- Crear Tablespace
CREATE TABLESPACE trabajo DATAFILE 'C:\app\Cesar\oradata\orcl\TRABAJO.DBF' SIZE 2G;
-- Aumentar el tamaño del Tablespace. 
--Alter database tablespace trabajo add datafile 'C:\app\Cesar\oradata\orcl\TRABAJO.DBF' size 1G; 
Alter database datafile 'C:\app\Cesar\oradata\orcl\TRABAJO.DBF' resize 3G; 
-- Borrar Tablespace
DROP TABLESPACE trabajo;

--Crear Usuario
CREATE USER CESAR IDENTIFIED BY cesar DEFAULT TABLESPACE trabajo;
GRANT DBA, CONNECT, RESOURCE to Cesar;

-- Ver tablespace
SELECT rpad(a.TABLESPACE_NAME,10) tablespace,rpad(a.FILE_NAME,40) fichero,
to_char(a.BYTES/1024/1024,'999.99') MB,
to_char(a.increment_by*b.value/1024/1024,'99.99') nextmb,
to_char(a.MAXBYTES/1024/1024,'9999.99') maxmb
FROM DBA_DATA_FILES a, v$parameter b
where b.name='db_block_size';
