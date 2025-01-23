/*  WITH
La versión 9i de las bases de datos Oracle permite el uso de la claúsula WITH en SQL y PLSQL. 
Este comando permite reusar una consulta SELECT cuando esta hay que utilizarla más de una vez en una sentencia 
o consulta SQL compleja. Los resultados de la consulta definida en la claúsula WITH son almacenados en una tabla 
temporal pudiendo de esta forma mejorar el rendimiento de la sentencia principal.

Aunque no siempre conseguiremos mejorar el rendimiento utilizando la claúsula WITH, lo que sin duda facilitaremos 
es la lectura y el mantenimiento del código PL/SQL o SQL. Dentro de la claúsula WITH daremos un nombre a las 
consultas SELECT a reutilizar (WITH admite la definición de múltiples consultas con sólo separarlas por comas), 
dicho nombre será visible para todas las consultas definidas posteriormente dentro del mismo WITH. Obviamente, 
también será visible para la sentencia o consulta principal.
*/


WITH Log_Caja AS
       (SELECT DISTINCT Tps.Rowid AS Rowid_Log,
                        Tps.Oficina AS Centro_Exp,
                        Trunc(Tps.Fec_Efectividad) AS Fecha_Transaccion,
                        Thb.Franquicia AS Nom_Franquicia,
                        TRIM(Leading '0' FROM Tps.Cod_Autoriza) AS Numero_Autorizacion,
                        TRIM(Leading '0' FROM Tps.Num_Tarjeta) AS Numero_Tarjeta,
                        Tps.Importe_Pago AS Valor_Total
          FROM Tbl_Proc_Scl Tps
          LEFT OUTER JOIN Tbl_Homologa_Bancos Thb
            ON (Tps.Des_Tiptarjeta = Thb.Tipo_Tar_Log_Cajas)
         WHERE Tps.Flag_Movimiento = c_Logcajas
           AND Tps.Des_Movcaja = c_Pago
           AND Tps.Des_Valor LIKE '%TARJETA%'
           AND Tps.Tipologia IS NULL),
      Detalle AS
       (SELECT DISTINCT Tdt.Rowid AS Rowid_Detalle,
                        Cu.Nombre_Punto AS Centro_Exp,
                        Tdt.Fecha_Transaccion,
                        Tdt.Nom_Franquicia AS Nom_Franquicia,
                        TRIM(Leading '0' FROM Tdt.Numero_Autorizacion) AS Numero_Autorizacion,
                        TRIM(Leading '0' FROM Tdt.Numero_Tarjeta) AS Numero_Tarjeta,
                        Tdt.Valor_Total
          FROM Tbl_Detallado_Tarjetas Tdt
          LEFT OUTER JOIN Tbl_Ce_Codigo_Unico Cu
            ON (To_Char(To_Number(Tdt.Codigo_Comercio)) = Cu.Codigo_Unico)
         WHERE Tdt.Tipologia IS NULL)
      SELECT a.Rowid_Log, b.Rowid_Detalle
        FROM Log_Caja a
        JOIN Detalle b
          ON a.Centro_Exp = b.Centro_Exp
            --AND a.Fecha_Transaccion = b.Fecha_Transaccion
         AND a.Nom_Franquicia <> b.Nom_Franquicia
         AND a.Numero_Autorizacion = b.Numero_Autorizacion
         AND a.Numero_Tarjeta = b.Numero_Tarjeta
         AND a.Valor_Total = b.Valor_Total;
