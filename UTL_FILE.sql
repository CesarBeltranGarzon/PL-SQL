/*
https://es.wikibooks.org/wiki/Oracle/PL/SQL/UTL_FILE

Para leer o escribir archivos es necesario crear un objeto directory desde SQL:

 create directory dir_tmp as 'c:\temp';
 grant read, write on directory dir_tmp to usuario;
 
El paquete (package) UTL_FILE nos va a permitir leer o escribir en ficheros del sistema operativo (Linux, Unix, Window, etc.) desde los programas 
que hagamos en PL/SQL en la base de datos Oracle.

Las funciones que voy a utilizar del paquete ULT_FILE son:

UTL_FILE.FOPEN() – Abrir un fichero
UTL_FILE.PUT() – Escribir en un fichero
UTL_FILE.GET_LINE() – Leer una línea de un fichero.
UTL_FILE.FCLOSE() – Cerrar un fichero.
Con el modo de apertura W si el fichero no existe lo crea y si existe lo sobrescribe.

SELECT * FROM all_directories;
SELECT * FROM all_tab_privs WHERE table_name = 'DIR_TMP';
*/
--Permisos uso paquete. Se ejecuta con usuario SYS
GRANT EXECUTE ON SYS.UTL_FILE TO laboratorio;

--Creamos directorio
CREATE DIRECTORY dir_tmp AS 'B:\Cesar\Estudio\Varios Oracle\Mios\Refuerzo\temp_utl_file';
 GRANT READ, WRITE ON DIRECTORY dir_tmp TO laboratorio;

----------------------------------
--Procedimiento que escribe archivo
----------------------------------
CREATE OR REPLACE PROCEDURE pr_escribir_archivo IS
  cadena VARCHAR2(32767);
  file   UTL_FILE.FILE_TYPE;
BEGIN
  -- En este ejemplo escribo una cadena de caracteres en el fichero prueba.txt
  
  -- Cadena a escribir
  cadena := 'Prueba de escritura en fichero usando el paquete utl_file';

  -- Abro fichero para escritura (Write)
  file := UTL_FILE.FOPEN('DIR_TMP','prueba.txt','W',256);
  
  -- Escribo en el fichero
  UTL_FILE.PUT(file,cadena);
  
  -- Cierro fichero 
  UTL_FILE.FCLOSE(file);
  
  DBMS_OUTPUT.PUT_LINE('Escritura correcta');
END;

----------------------------------
--Procedimiento que lee archivo
----------------------------------
CREATE OR REPLACE PROCEDURE pr_leer_archivo IS
  v_archivo UTL_FILE.FILE_TYPE;
  v_linea   VARCHAR2(32767);
BEGIN
  v_archivo := UTL_FILE.FOPEN('DIR_TMP','prueba.txt','R');
  LOOP
   UTL_FILE.GET_LINE(v_archivo, v_linea);
   DBMS_OUTPUT.PUT_LINE(v_linea);
  END LOOP; 
EXCEPTION
  WHEN no_data_found THEN
    --Debemos cerrar el archivo aqui ya que en el momento que no encuentre lineas salta directamente a la la execpción y no lo cerraría.
    utl_file.fclose(v_archivo);
    DBMS_OUTPUT.PUT_LINE('****Fin del archivo');
  WHEN utl_file.access_denied THEN
    DBMS_OUTPUT.PUT_LINE('Error: utl_file.access_denied');
  WHEN utl_file.invalid_operation THEN
    DBMS_OUTPUT.PUT_LINE('Error: utl_file.invalid_operation');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: Otros');
END;
