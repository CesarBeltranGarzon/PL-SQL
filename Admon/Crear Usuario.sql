CREATE USER pruebas IDENTIFIED BY pruebas DEFAULT TABLESPACE USERS;

--GRANT CONNECT TO laboratorio;--Permite conectar a BD
--GRANT RESOURCE TO laboratorio;--Permite crear tablas y objetos
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE MATERIALIZED VIEW, DEBUG CONNECT SESSION, DBA TO pruebas;
