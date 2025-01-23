--SET SERVEROUTPUT ON;
DECLARE
      CURSOR c_obj
      IS
         SELECT owner, object_name, object_type
           FROM all_objects
          WHERE owner = 'METRO' AND STATUS = 'INVALID';

      r_obj      c_obj%ROWTYPE;
      plsql      VARCHAR2 (1000);
      err_code   VARCHAR2 (1000);
      err_msg    VARCHAR2 (1000);
      contador   INTEGER := 0;
   BEGIN
      DBMS_OUTPUT.PUT_LINE  ('Inicio compilaObjetos');

      OPEN c_obj;

      LOOP
         FETCH c_obj INTO r_obj;

         EXIT WHEN c_obj%NOTFOUND;

         IF (r_obj.object_type = 'PACKAGE BODY')
         THEN
            plsql :=
                  'alter PACKAGE '
               || r_obj.owner
               || '.'
               || r_obj.object_name
               || ' compile debug';
         ELSE
            plsql :=
                  'alter '
               || r_obj.object_type
               || ' '
               || r_obj.owner
               || '.'
               || r_obj.object_name
               || ' compile';
         END IF;

         BEGIN
            EXECUTE IMMEDIATE plsql;

            DBMS_OUTPUT.PUT_LINE (
               r_obj.owner || '.' || r_obj.object_name || ' Compilado');
            contador := contador + 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               err_code := SQLCODE;
               err_msg := SUBSTR (SQLERRM, 1, 200);
               DBMS_OUTPUT.PUT_LINE (
                  plsql || ' ' || err_code || ' Error: ' || err_msg);
         END;
      END LOOP;

      CLOSE c_obj;

      DBMS_OUTPUT.PUT_LINE (contador || ' Objetos compilados');
      DBMS_OUTPUT.PUT_LINE ('Fin Objetos Compilados');
   END;