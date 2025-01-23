-- Revisar si contiene letras o caracteres diferentes a numeros
SELECT 1
FROM DUAL
WHERE REGEXP_LIKE('0123450la','[^0-9]')