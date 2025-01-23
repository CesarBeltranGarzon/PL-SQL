-- Sesiones de un usuario
SELECT count(*) as connections,username FROM v$session where username='SQL_WEBSERVICES_SOFKA' GROUP BY username;

-- Perfil asociado y limite de sesiones
select a.username,b.PROFILE,b.RESOURCE_NAME,b.limit 
  from dba_users a , dba_profiles b 
 where a.profile=b.profile 
   and b.RESOURCE_NAME='SESSIONS_PER_USER'
   and a.username='SQL_WEBSERVICES_SOFKA';

-- Aumentar numero sesiones
ALTER PROFILE PROFILE_USER_SOFKA LIMIT SESSIONS_PER_USER 100;

