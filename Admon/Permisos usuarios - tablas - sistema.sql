SELECT * FROM DBA_ROLE_PRIVS WHERE grantee = 'USERWEB';
SELECT * FROM DBA_ROLE_PRIVS WHERE grantee = 'SQL_SOFKA';
--
SELECT * FROM DBA_SYS_PRIVS WHERE grantee = 'USERWEB';
SELECT * FROM DBA_SYS_PRIVS WHERE grantee = 'SQL_SOFKA' ORDER BY 2;
--
SELECT * 
  FROM DBA_TAB_PRIVS 
 WHERE LOWER(table_name) IN ('pessoa','pessoa_fisica','pessoa_juridica','persona_sarlaft') 
   --AND PRIVILEGE = 'SELECT' 
   AND grantee = 'USERWEB';

GRANT SELECT ON metro.persona_sarlaft TO USERWEB;
GRANT INSERT ON metro.persona_sarlaft TO USERWEB;
GRANT DELETE ON metro.persona_sarlaft TO USERWEB;
GRANT UPDATE ON metro.persona_sarlaft TO USERWEB;