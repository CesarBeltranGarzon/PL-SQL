/*
Database Supplied Packages es una funcionalidad introducida en Oracle Database 21c que permite a las bases de datos proporcionar paquetes de software (librerías y herramientas) que los desarrolladores y administradores pueden utilizar directamente desde el entorno de base de datos.

Características principales
Instalación simplificada:

Las bases de datos proporcionan un conjunto de librerías (como pandas, numpy o cx_Oracle) directamente disponibles sin necesidad de que los usuarios las instalen manualmente en el servidor de base de datos.
Estas librerías están preempaquetadas y optimizadas para ejecutarse junto con Oracle Database.
Uso en lenguajes soportados:

Principalmente diseñadas para ser utilizadas con Oracle Database Multilingual Engine (MLE), que soporta lenguajes como JavaScript y Python dentro de la base de datos.
Beneficios de seguridad:

Al ser suministradas directamente por la base de datos, estas librerías son verificadas y controladas por Oracle, reduciendo riesgos de vulnerabilidades o problemas de compatibilidad.
Actualizaciones gestionadas:

Oracle se encarga de actualizar los paquetes de manera centralizada, garantizando que los usuarios siempre tengan acceso a versiones confiables y recientes.

Casos de uso
-Análisis de datos: Usar librerías como pandas directamente en consultas SQL o PL/SQL.
-Desarrollo de aplicaciones avanzadas: Incorporar lógica compleja en lenguajes como Python dentro de la base de datos sin necesidad de infraestructura adicional.
-Automatización: Ejecutar scripts y procesos automatizados que interactúen con la base de datos usando herramientas preconfiguradas.

Aquí tienes algunos ejemplos prácticos del uso de Database Supplied Packages en Oracle Database 21c, utilizando el motor Multilingual Engine (MLE) para ejecutar lenguajes como Python y JavaScript directamente dentro de la base de datos.
*/    

/*
1. Uso de Python con pandas para análisis de datos
Supongamos que tienes una tabla llamada sales_data:
*/
CREATE TABLE sales_data (
    product_id NUMBER,
    region VARCHAR2(50),
    sales_amount NUMBER
);

-- Insertamos algunos datos
INSERT INTO sales_data VALUES (1, 'North', 1000);
INSERT INTO sales_data VALUES (2, 'South', 1500);
INSERT INTO sales_data VALUES (3, 'East', 2000);
INSERT INTO sales_data VALUES (1, 'West', 1700);
COMMIT;

-- Script Python usando pandas para agrupar datos y calcular la suma de ventas:
import pandas as pd

def process_sales_data(input_data):
    # Convertir la entrada (lista de diccionarios) a un DataFrame
    df = pd.DataFrame(input_data)
    # Agrupar por región y calcular la suma de ventas
    summary = df.groupby('region').agg({'sales_amount': 'sum'})
    # Convertir a formato JSON para devolver el resultado
    return summary.to_json()

/*
Cómo ejecutarlo en Oracle:
Carga el script Python en la base de datos.
Ejecuta el script directamente en Oracle, obteniendo los datos con una consulta SQL como entrada:
*/
SELECT MLE_EVAL(
    LANGUAGE => 'PYTHON',
    SOURCE => 'process_sales_data',
    ARGUMENTS => JSON_ARRAYAGG(JSON_OBJECT(
        'product_id' VALUE product_id,
        'region' VALUE region,
        'sales_amount' VALUE sales_amount
    ))
) FROM sales_data;

/*
Cargar un script Python en Oracle Database para usarlo con Database Supplied Packages y la Multilingual Engine (MLE) implica algunos pasos básicos. Aquí te detallo cómo hacerlo:

1. Habilitar la Multilingual Engine (MLE)
Verifica si MLE está habilitado:
*/
SHOW PARAMETER mlimpl;

/*Si no está habilitado, asegúrate de que la base de datos esté configurada correctamente. Esto puede requerir permisos de administrador y modificar parámetros en el archivo de inicialización.
Habilitar MLE (si es necesario):
Configura la opción adecuada en tu servidor. Si estás usando Oracle Autonomous Database o una versión compatible de Oracle 21c+, normalmente ya está habilitado.

2. Cargar el script Python como un objeto en la base de datos
En Oracle, puedes almacenar el script Python como una función o procedimiento PL/SQL que invoca el código Python usando DBMS_MLE.

Ejemplo: Crear un script Python como objeto almacenado
Paso 1: Define tu script Python
Guarda el script en una variable PL/SQL o pásalo como un archivo al procedimiento. Por ejemplo:
*/

--# Script Python: process_sales_data
import pandas as pd

def process_sales_data(input_data):
    df = pd.DataFrame(input_data)
    summary = df.groupby('region').agg({'sales_amount': 'sum'})
    return summary.to_dict()

/*Paso 2: Crear el procedimiento PL/SQL para invocar el script
Usa el paquete DBMS_MLE para ejecutar tu script directamente.
*/

CREATE OR REPLACE FUNCTION process_sales_data_py(input_json CLOB) RETURN CLOB
AS
    LANGUAGE JAVA
    NAME 'oracle.dbtools.mle.MLE.evalScript(java.lang.String, java.lang.String)';
BEGIN
    RETURN DBMS_MLE.EVAL_SCRIPT(
        LANGUAGE  => 'PYTHON',
        SOURCE    => 'import pandas as pd
                      def process_sales_data(input_data):
                          df = pd.DataFrame(input_data)
                          summary = df.groupby("region").agg({"sales_amount": "sum"})
                          return summary.to_dict()',
        ARGUMENTS => input_json
    );
END;
/

/*
3. Ejecutar el Script desde SQL
Con el script cargado como una función o procedimiento, puedes ejecutarlo directamente desde SQL usando la tabla como entrada.

Ejemplo:
Supongamos que tienes la tabla sales_data con esta estructura:
*/

SELECT JSON_OBJECT(
           'product_id' VALUE product_id,
           'region' VALUE region,
           'sales_amount' VALUE sales_amount
       ) AS data
FROM sales_data;

--Ejecuta la función:
DECLARE
    input_data CLOB;
    result CLOB;
BEGIN
    SELECT JSON_ARRAYAGG(JSON_OBJECT(
               'product_id' VALUE product_id,
               'region' VALUE region,
               'sales_amount' VALUE sales_amount
           ))
    INTO input_data
    FROM sales_data;

    result := process_sales_data_py(input_data);
    DBMS_OUTPUT.PUT_LINE(result);
END;
/

/*
4. Guardar y reutilizar el script (opcional)
Si necesitas reutilizar el script con diferentes tablas o datos, puedes almacenarlo como un objeto Python independiente en la base de datos utilizando stored scripts. Sin embargo, esto depende del soporte específico de MLE para tu versión de Oracle Database.

Notas importantes
Versión de Oracle Database: La funcionalidad MLE y los paquetes preinstalados están disponibles desde Oracle Database 21c.
Permisos requeridos: Asegúrate de que tu usuario tenga privilegios para ejecutar DBMS_MLE.
Multilingual Engine: Está optimizado para lenguajes como Python y JavaScript, pero requiere configuración adecuada en algunos entornos.
*/


/*
Si no deseas almacenar el script Python como una función o procedimiento PL/SQL utilizando DBMS_MLE, puedes ejecutarlo de manera más directa desde SQL o mediante herramientas externas que interactúan con Oracle Database, como SQLcl, SQL*Plus, o cualquier cliente compatible con Oracle. Esto se hace usando la funcionalidad de MLE eval directamente en una consulta SQL.

A continuación, te explico cómo hacerlo.

1. Ejecutar el Script Directamente con DBMS_MLE.EVAL_SCRIPT
El paquete DBMS_MLE permite ejecutar scripts Python directamente sin necesidad de almacenarlos como procedimientos o funciones.

Ejemplo: Ejecutar un Script Python Directo
Supongamos que tienes una tabla llamada sales_data con esta estructura:
*/
CREATE TABLE sales_data (
    product_id NUMBER,
    region VARCHAR2(50),
    sales_amount NUMBER
);

INSERT INTO sales_data VALUES (1, 'North', 1000);
INSERT INTO sales_data VALUES (2, 'South', 1500);
INSERT INTO sales_data VALUES (3, 'East', 2000);
INSERT INTO sales_data VALUES (1, 'West', 1700);
COMMIT;

-- Puedes ejecutar el script directamente con DBMS_MLE.EVAL_SCRIPT en un bloque PL/SQL, como sigue:
DECLARE
    input_data CLOB;
    result CLOB;
BEGIN
    -- Crear un JSON con los datos de la tabla
    SELECT JSON_ARRAYAGG(JSON_OBJECT(
               'product_id' VALUE product_id,
               'region' VALUE region,
               'sales_amount' VALUE sales_amount
           ))
    INTO input_data
    FROM sales_data;

    -- Ejecutar el script Python directamente
    result := DBMS_MLE.EVAL_SCRIPT(
        LANGUAGE => 'PYTHON',
        SOURCE   => 'import pandas as pd
                     def process_sales_data(input_data):
                         df = pd.DataFrame(input_data)
                         summary = df.groupby("region").agg({"sales_amount": "sum"})
                         return summary.to_dict()
                     process_sales_data(input_data)',
        ARGUMENTS => input_data
    );

    -- Mostrar el resultado
    DBMS_OUTPUT.PUT_LINE(result);
END;
/

/*
2. Usar Herramientas Externas para Ejecutar el Script
Si prefieres no usar directamente DBMS_MLE, puedes ejecutar scripts en Python utilizando herramientas externas como cx_Oracle o SQLAlchemy para interactuar con la base de datos.
*/

-- Ejemplo: Ejecutar desde un Script Python Externo
import cx_Oracle
import json

# Conexión a la base de datos
connection = cx_Oracle.connect("user/password@localhost/XEPDB1")
cursor = connection.cursor()

# Crear el script Python en SQL
script = '''
import pandas as pd
def process_sales_data(input_data):
    df = pd.DataFrame(input_data)
    summary = df.groupby("region").agg({"sales_amount": "sum"})
    return summary.to_dict()
'''

# Crear la entrada JSON desde la tabla
cursor.execute("""
    SELECT JSON_ARRAYAGG(JSON_OBJECT(
               'product_id' VALUE product_id,
               'region' VALUE region,
               'sales_amount' VALUE sales_amount
           )) FROM sales_data
""")
input_data = cursor.fetchone()[0]

# Ejecutar el script Python directamente en la base de datos
result = cursor.callfunc("DBMS_MLE.EVAL_SCRIPT", cx_Oracle.CLOB, [
    'PYTHON',  # Lenguaje
    script,    # Código fuente
    input_data # Datos de entrada
])

# Imprimir el resultado
print(json.loads(result.read()))

/*
3. Pasar el Script Inline en Consultas SQL
Si quieres mayor flexibilidad, puedes pasar el script Python directamente como texto en una consulta SQL, sin almacenarlo como función. Aquí tienes un ejemplo:

-- Este enfoque es útil si solo necesitas usar el script de manera temporal o para pruebas rápidas.
*/

SELECT DBMS_MLE.EVAL_SCRIPT(
    LANGUAGE => 'PYTHON',
    SOURCE => 'import pandas as pd
               def process_sales_data(input_data):
                   df = pd.DataFrame(input_data)
                   summary = df.groupby("region").agg({"sales_amount": "sum"})
                   return summary.to_dict()
               process_sales_data(input_data)',
    ARGUMENTS => JSON_ARRAYAGG(JSON_OBJECT(
        'product_id' VALUE product_id,
        'region' VALUE region,
        'sales_amount' VALUE sales_amount
    ))
) AS result
FROM sales_data;
