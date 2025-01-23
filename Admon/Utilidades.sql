--- Utilidades ---

-- 1. Busca dependencias de un objeto
-- tipo, esquema, nombre
BEGIN
dbms_utility.get_dependency('TABLE', 'BILLCOLPER', 'BASEXFAC');
END;

-- 2. Errores
--
dbms_output.put_line (DBMS_UTILITY.format_error_backtrace);
dbms_output.put_line (DBMS_UTILITY.format_error_stack);
dbms_output.put_line (DBMS_UTILITY.format_call_stack);

-- 3. Usuario actual
SELECT dbms_utility.old_current_user FROM DUAL;
-- 4. Esquema actual
SELECT dbms_utility.old_current_schema FROM DUAL;
