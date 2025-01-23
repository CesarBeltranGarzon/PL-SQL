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
       d.tablespace_name = f.tablespace_name(+)
ORDER BY 6 DESC