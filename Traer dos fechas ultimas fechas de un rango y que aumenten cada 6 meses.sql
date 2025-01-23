SELECT *
    FROM
(
SELECT fecha, ROW_NUMBER() OVER (order by fecha DESC) reg 
   FROM (SELECT ADD_MONTHS(TO_DATE('01-Dec-2015'),datos.i * 6) fecha
                  FROM xmltable('for $i in 1 to 100 return $i' columns i integer path '.') datos
                ORDER BY 1)
WHERE fecha <= SYSDATE
)
WHERE reg <= 2