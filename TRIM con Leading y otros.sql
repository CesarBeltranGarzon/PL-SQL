/* TRIM
TRIM( [ [ LEADING | TRAILING | BOTH ] trim_character FROM ] string1 )
Parameters or Arguments

LEADING
The function will remove trim_character from the front of string1.
TRAILING
The function will remove trim_character from the end of string1.
BOTH
The function will remove trim_character from the front and end of string1.
trim_character
The character that will be removed from string1. If this parameter is omitted, the TRIM function will remove space characters from string1.
string1
The string to trim.
*/

SELECT TRIM('   tech   ') FROM DUAL;
--Result: 'tech'

SELECT TRIM(' '  FROM  '   tech   ') FROM DUAL;
--Result: 'tech'

SELECT TRIM(LEADING '0' FROM '000123') FROM DUAL;
--Result: '123'

SELECT TRIM(TRAILING '1' FROM 'Tech1') FROM DUAL;
--Result: 'Tech'

SELECT TRIM( '1' FROM '123Tech111') FROM DUAL;
--Result: '23Tech'
