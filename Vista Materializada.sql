/*
https://www.adictosaltrabajo.com/tutoriales/vistas-materializadas/

Una vista es una consulta almacenada que representa un conjunto
de tablas (posiblemente de diferentes esquemas) a la que le vamos a poner
un nombre y vamos a tratarla como si fuese una tabla más de nuestro
esquema, pero sin llegar a ser realmente una tabla. 
No guarda datos sino la consulta.

Ventajas:  Seguridad y facilidad de acceso a los datos.

A diferencia de las vistas «normales» una vista materializada
---------------------------------------------------------------
almacena físicamente los datos resultantes de ejecutar
la consulta definida en la vista. Este tipo de vistas materializadas realizan
una carga inicial de los datos cuando se definen y posteriormente con una
frecuencia establecida se actualizan los datos de la misma.

Ventaja:
--------
logramos aumentar el rendimiento de las consultas
SQL además de ser un método de optimización
a nivel físico en modelos de datos muy complejos y/o con muchos datos.


Formas de refresco
-------------------
Refresco manual : mediante el paquete de PL/SQL
DBMS_MVIEW podemos forzar a realizar un refresco usando para ello
la función REFRESH.
 
         DBMS_MVIEW.REFRESH ('nombre_vista');
    
Con la función REFRESH_DEPENDENT se refrescarán
todas las vistas materializadas que tengan algunas de sus «tablas base»
en la lista de tablas pasada como parámetro de entrada.

  DBMS_MVIEW.REFRESH_DEPENDENT ('tabla1, tabla2, tabla3, ... , tablaN');
Con la función REFRESH_ALL_MVIEWS se refrescarán
todas las vistas materializadas de nuestra base de datos.

Refresco automático : este refresco automático
podemos hacerlo usando la palabra ON COMMIT, con la que se fuerza
al refresco de la vista en el momento en el que se haga un commit
sobre una de las «tablas base» de dicha vista. Otro tipo de refresco
automático es el llamado refresco programado, en el cual podemos definir
el momento exacto en el que queremos que se refresque nuestra vista. Para
ello tenemos que definir la fecha del refresco en formate datetime
y el intervalo de este.






CREATE MATERIALIZED VIEW nombre_vista
      [TABLESPACE nombre_ts]
      [PARALELL (DEGREE n)]
      [BUILD {INMEDIATE|DEFERRED}]
      [REFRESH {FAST|COMPLETE|FORCE|NEVER}|{ON COMMIT|ON DEMAND|[START WITH fecha_inicio] NEXT intervalo}]
      [{ENABLE|DISABLE} QUERY REWRITE]
      AS SELECT ... FROM ... WHERE ...

*Con la palabra BUILD establecemos la forma de carga de datos en la vista. Con la opción INMEDIATE (opción por defecto) se cargarán los datos justo 
 después de crear la vista, mientras que con la opción DEFERRED se definirá la vista cuando se ejecute la sentencia SQL sin cargar ningún dato, que 
 se cargarán cuando se realize el primer refresco de la vista.

*Con la palabra REFRESH definimos el método y la frecuencia de refresco de los datos.

    *COMPLETE : se borrarán todos los datos de la vista y se volverá a ejecutar la consulta definida en la vista por lo que se recargarán fisicamente 
       los datos de las “tablas base”.   
    *FAST : podemos decir que este tipo de refresco es una actualización incremental, es decir, solo se refrescarán aquellos datos que se hayan modificado 
       desde el último refresco. Evidentemente este tipo de refresco es mucho más fast 😉 que el complete. Pero, ¿cómo sabe la base de datos que datos se han 
       modificado desde el último refresco? lo sabe gracias a que previamente hemos tenido que crear unos determinados log de la vista (VIEW LOG) sobre cada 
       una de las “tablas base” de la vista materializada.

           CREATE MATERIALIZED VIEW LOG ON tabla_base
           WITH PRIMARY KEY
           INCLUDING NEW VALUES;

       Hay que decir que si usamos funciones sum, avg, max, min, etcétera, no vamos a poder usar este tipo de refresco.

    *FORCE : si se puede realizar el refresco tipo FAST se ejecuta, y sino se realiza el refresco COMPLETE. Es el valor por defecto del tipo de refresco.
    *NEVER : nunca se realizará un refresco de la vista.

*La palabra QUERY REWRITE establece si queremos que el optimizador de nuestra base de datos pueda reescribir las consultas. El optimizador, sabiendo 
 que ya existe una determinada vista materializada, puede modificar internamente nuestra consulta sobre una determinada tabla, de tal forma que se 
 mejore el rendimiento de la consulta devolviendo los mismos datos que la consulta original.

Formas de refresco
---------------------
*Refresco manual : mediante el paquete de PL/SQL DBMS_MVIEW podemos forzar a realizar un refresco usando para ello la función REFRESH.

         DBMS_MVIEW.REFRESH ('nombre_vista');

    Con la función REFRESH_DEPENDENT se refrescarán todas las vistas materializadas que tengan algunas de sus “tablas base” en la lista de tablas pasada 
    como parámetro de entrada.

      DBMS_MVIEW.REFRESH_DEPENDENT ('tabla1, tabla2, tabla3, ... , tablaN');

    Con la función REFRESH_ALL_MVIEWS se refrescarán todas las vistas materializadas de nuestra base de datos.

*Refresco automático : este refresco automático podemos hacerlo usando la palabra ON COMMIT, con la que se fuerza al refresco de la vista en el momento en 
 el que se haga un commit sobre una de las “tablas base” de dicha vista. Otro tipo de refresco automático es el llamado refresco programado, en el cual podemos 
 definir el momento exacto en el que queremos que se refresque nuestra vista. Para ello tenemos que definir la fecha del refresco en formate datetime y el 
 intervalo de este.

*/

--crear log si elegimos REFRESH FAST
CREATE MATERIALIZED VIEW LOG ON empleados
           WITH PRIMARY KEY
           INCLUDING NEW VALUES;

--Crear vista
CREATE MATERIALIZED VIEW vw_materializada_prueba
      BUILD IMMEDIATE -- Se cargan los datos justo después de crear la vista
      REFRESH COMPLETE ON COMMIT --Se actualiza cuando se haga commit sobre tabla
      AS SELECT * FROM empleados
