/*
El comando "create global temporary tables" crea una tabla temporal para cada sesi�n.  Eso significa que los datos no se comparten 
entre sesiones y se eliminan al final de la misma.
Todos los usuarios que tengan permisos sobre la tabla podr�n realizar operaciones DML sobre la misma.
*/

--Creaci�n tabla
CREATE GLOBAL TEMPORARY TABLE prueba (ID INT) ON COMMIT DELETE ROWS;--SE REMUEVEN DATOS ANTE COMMIT O ROLLBACK
CREATE GLOBAL TEMPORARY TABLE prueba (ID INT) ON COMMIT PRESERVE ROWS;--SE CONSERVAN DATOS HASTA QUE SESI�N FINALICE

--INSERCIONES
INSERT INTO prueba VALUES (1);
INSERT INTO prueba VALUES (2);
INSERT INTO prueba VALUES (3);

-- CONSULTA TABLA
SELECT * FROM prueba

--
COMMIT;
