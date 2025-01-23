-- Consultas basicas
SELECT dbms_xmlgen.getxml('SELECT * FROM customers') xml
  FROM dual;
  
SELECT XMLElement("Age", age)
  FROM customers

SELECT e.id, 
       XMLELEMENT ("Cust", e.name ||' '|| e.age) AS "RESULT"
   FROM customers e
-------------------
-- TAG BASED XML
-------------------
-- Tabla trabajo
CREATE TABLE xml_tab (
  Tipo     VARCHAR2(20),
  xml_data XMLTYPE
);
-- Proceso que genera XML en base a una tabla e inserta registro en otra tabla
DECLARE
  l_xmltype XMLTYPE;
BEGIN
  SELECT XMLELEMENT("customers",
           XMLAGG(
                  XMLELEMENT("customer",
                    XMLFOREST(
                               c.id AS "id",
                               c.name AS "name",
                               c.age AS "age",
                               c.salary AS "salary"
                             )
                            )
                 ) 
                   )
  INTO   l_xmltype
  FROM   customers c;

  INSERT INTO xml_tab VALUES ('TAG BASED XML', l_xmltype);
  COMMIT;
END;
-- Consulta de registro insertado
SELECT x.xml_data.getClobVal()
FROM   xml_tab x;
-- Consulta la info XML como si fuera tabla
SELECT xt.*
FROM   xml_tab x,
       XMLTABLE('/customers/customer'
         PASSING x.xml_data
         COLUMNS 
           "ID"     NUMBER  PATH 'id',
           "NAME"   VARCHAR2(50) PATH 'name',
           "AGE"    NUMBER  PATH 'age',
           "SALARY" NUMBER PATH 'salary'
         ) xt;

-----------------------
-- Attribute-Based XML
-----------------------
TRUNCATE TABLE xml_tab;
-- Consulta de registro insertado
DECLARE
  l_xmltype XMLTYPE;
BEGIN
  SELECT XMLELEMENT("customers",
           XMLAGG(
             XMLELEMENT("customer",
               XMLATTRIBUTES(
                 e.id AS "id",
                 e.name AS "name",
                 e.age AS "age",
                 e.salary AS "salary"
               )
             )
           ) 
         )
  INTO   l_xmltype
  FROM   customers e;

  INSERT INTO xml_tab VALUES ('Attribute-Based XML', l_xmltype);
  COMMIT;
END;
--
SELECT x.xml_data.getClobVal()
FROM   xml_tab x;
-- Consulta la info XML como si fuera tabla
SELECT xt.*
FROM   xml_tab x,
       XMLTABLE('/customers/customer'
         PASSING x.xml_data
         COLUMNS
           "ID"     NUMBER  PATH '@id',
           "NAME"   VARCHAR2(50) PATH '@name',
           "AGE"    NUMBER  PATH '@age',
           "SALARY" NUMBER  PATH '@salary'
         ) xt;
         
---------------------------
-- XML Data in Variables
---------------------------
-- No todos los datos XML que desea procesar ya están almacenados en una tabla. En algunos casos, el XML se 
-- almacena en una variable PL/SQL. El operador XMLTABLE puede trabajar con esto también.
--
-- Proceso que lee XML de una variable
DECLARE
  l_xml VARCHAR2(32767);
BEGIN
  l_xml := '<employees>
  <employee>
    <empno>7369</empno>
    <ename>SMITH</ename>
    <job>CLERK</job>
    <hiredate>17-DEC-1980</hiredate>
  </employee>
  <employee>
    <empno>7499</empno>
    <ename>ALLEN</ename>
    <job>SALESMAN</job>
    <hiredate>20-FEB-1981</hiredate>
  </employee>
</employees>';

  FOR cur_rec IN (
    SELECT xt.*
    FROM   XMLTABLE('/employees/employee'
             PASSING XMLTYPE(l_xml)
             COLUMNS 
               "EMPNO"    VARCHAR2(4)  PATH 'empno',
               "ENAME"    VARCHAR2(10) PATH 'ename',
               "JOB"      VARCHAR2(9)  PATH 'job',
               "HIREDATE" VARCHAR2(11) PATH 'hiredate'
             ) xt)
  LOOP
    DBMS_OUTPUT.put_line('empno=' || cur_rec.empno ||
                         '  ename=' || cur_rec.ename ||
                         '  job=' || cur_rec.job||
                         '  hiredate=' || cur_rec.hiredate);
  END LOOP;
END;

-- Ejemplo 2
-- He aquí un ejemplo más complicado de un servicio web OBIEE
DECLARE
  l_xml     VARCHAR2(32767);
  l_xmltype XMLTYPE;
BEGIN
  l_xml := '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:sawsoap="urn://oracle.bi.webservices/v6">
   <soap:Body>
      <sawsoap:executeSQLQueryResult>
         <sawsoap:return xsi:type="sawsoap:QueryResults">
            <sawsoap:rowset>
<![CDATA[<rowset xmlns="urn:schemas-microsoft-com:xml-analysis:rowset">
<Row><Column0>1000</Column0><Column1>East Region</Column1></Row>
<Row><Column0>2000</Column0><Column1>West Region</Column1></Row>
<Row><Column0>1500</Column0><Column1>Central Region</Column1></Row>
</rowset>]]>
</sawsoap:rowset>
            <sawsoap:queryID/>
            <sawsoap:finished>true</sawsoap:finished>
         </sawsoap:return>
      </sawsoap:executeSQLQueryResult>
   </soap:Body>
</soap:Envelope>';
         
  FOR cur_rec IN (
    SELECT a.mydata, xt.*
    FROM   (
            -- Pull out just the CDATA value.
            SELECT EXTRACTVALUE(XMLTYPE(l_xml), '//sawsoap:rowset/text()','xmlns:sawsoap="urn://oracle.bi.webservices/v6"') AS mydata
            FROM dual
           ) a,
           -- Specify the path that marks a new row, remembering to use the correct namespace.
           XMLTABLE(XMLNAMESPACES(default 'urn:schemas-microsoft-com:xml-analysis:rowset'), '/rowset/Row'
             PASSING XMLTYPE(a.mydata)
             COLUMNS 
               "COLUMN0"  NUMBER(4)    PATH 'Column0',
               "COLUMN1"  VARCHAR2(20) PATH 'Column1'
             ) xt)
  LOOP
    DBMS_OUTPUT.put_line('column0=' || cur_rec.column0 || '  column1=' || cur_rec.column1);
  END LOOP;
END;

/*
PERFORMANCE
El operador XMLTABLE funciona muy bien con pequeños documentos XML, o tablas con muchas filas, cada una de las 
cuales contiene un pequeño documento XML. A medida que los documentos XML crecen, el rendimiento empeora en 
comparación con el método de análisis manual. Al tratar con documentos XML grandes puede que tenga que renunciar 
a la conveniencia para el operador XMLTABLE a favor de una solución manual.
*/
