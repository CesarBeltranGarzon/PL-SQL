SPOOL 'C:\Cesar Beltran\excel2.xml'
SET serveroutput ON SIZE 1000000
set feed off
set feedback off
SET echo OFF

DECLARE

Cabecera VARCHAR2(4000):= '<?xml version="1.0" encoding="ISO-8859-9"?>' || chr(10) ||
                '<?mso-application progid="Excel.Sheet"?>' || chr(10) ||
                '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"' ||
                chr(10) ||
                'xmlns:o="urn:schemas-microsoft-com:office:office"' ||
                chr(10) ||
                'xmlns:x="urn:schemas-microsoft-com:office:excel"' ||
                chr(10) ||
                'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"' ||
                chr(10) || 'xmlns:html="http://www.w3.org/TR/REC-html40">' ||
                chr(10) ||
                '<ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">' ||
                chr(10) || '<WindowHeight>8580</WindowHeight>' || chr(10) ||
                '<WindowWidth>15180</WindowWidth>' || chr(10) ||
                '<WindowTopX>120</WindowTopX>' || chr(10) ||
                '<WindowTopY>45</WindowTopY>' || chr(10) ||
                '<ProtectStructure>False</ProtectStructure>' || chr(10) ||
                '<ProtectWindows>False</ProtectWindows>' || chr(10) ||
                '</ExcelWorkbook>' || chr(10) || '<Styles>' || chr(10) ||
                '<Style ss:ID="Normal" ss:Name="Normal">' || chr(10) ||
                '<Alignment ss:Vertical="Center" ss:WrapText="1"/>' ||
                chr(10) || '<Borders>' || chr(10) ||
                '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) || '</Borders>' || chr(10) || '<Font/>' || chr(10) ||
                '<Interior/>' || chr(10) || '<NumberFormat/>' || chr(10) ||
                '<Protection/>' || chr(10) || '</Style>' || chr(10) ||
                '<Style ss:ID="Underline">' || chr(10) ||
                '<Font x:Family="Swiss" ss:Bold="1" ss:Underline="Single"/>' ||
                chr(10) || '<Interior/>' || chr(10) || '<NumberFormat/>' ||
                chr(10) || '<Protection/>' || chr(10) || '</Style>' ||
                chr(10) || '<Style ss:ID="TituloColumnas">' || chr(10) ||
                '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom" ss:WrapText="1"/>' ||
                chr(10) || '<Borders>' || chr(10) ||
                '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) || '</Borders>' || chr(10) ||
                '<Font ss:FontName="Arial" x:Family="Swiss" ss:Size="10" ss:Color="#FFFFFF" ss:Bold="1"/>' ||
                chr(10) ||
                '<Interior ss:Color="#99CCFF" ss:Pattern="Solid"/>' ||
                chr(10) || '</Style>' || chr(10) ||
                '<Style ss:ID="TituloHoja">' || chr(10) ||
                '<Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>' ||
                chr(10) || '<Borders>' || chr(10) ||
                '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>' ||
                chr(10) ||
                '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>' ||
                chr(10) ||
                '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>' ||
                chr(10) ||
                '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>' ||
                chr(10) || '</Borders>' || chr(10) ||
                '<Font ss:FontName="Arial" x:Family="Swiss" ss:Size="17" ss:Color="#FFFFFF" ss:Bold="1"/>' ||
                chr(10) ||
                '<Interior ss:Color="#99CCFF" ss:Pattern="Solid"/>' ||
                chr(10) || '</Style>' || chr(10) || '<Style ss:ID="Logo">' ||
                chr(10) ||
                '<Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>' ||
                chr(10) || '<Borders>' || chr(10) ||
                '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>' ||
                chr(10) ||
                '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>' ||
                chr(10) ||
                '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>' ||
                chr(10) ||
                '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>' ||
                chr(10) || '</Borders>' || chr(10) ||
                '<Font ss:FontName="Arial Black" x:Family="Swiss" ss:Size="12" ss:Color="#000000" ss:Bold="1"/>' ||
                chr(10) ||
                '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>' ||
                chr(10) || '</Style>' ||

                chr(10) || '<Style ss:ID="CampoNumero">' || chr(10) ||
                '<Borders>' || chr(10) ||
                '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) || '</Borders>' || chr(10) ||
                '<Alignment ss:Horizontal="Right" ss:Vertical="Center" ss:WrapText="1"/>' ||
                chr(10) || '<NumberFormat ss:Format="###,###,##0"/>' ||
                chr(10) || '</Style>' || chr(10) ||
                '<Style ss:ID="TituloColumnasnumerico">' || chr(10) ||
                '<Alignment ss:Horizontal="Right" ss:Vertical="Center" ss:WrapText="1"/>' ||
                chr(10) || '<Borders>' || chr(10) ||
                '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) ||
                '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>' ||
                chr(10) || '</Borders>' || chr(10) ||
                '<Font ss:FontName="Arial" x:Family="Swiss" ss:Size="10" ss:Color="#FFFFFF" ss:Bold="1"/>' ||
                chr(10) ||
                '<Interior ss:Color="#99CCFF" ss:Pattern="Solid"/>' ||
                chr(10) || '<NumberFormat ss:Format="###,###,##0"/>' ||
                chr(10) || '</Style>' || chr(10) || '</Styles>';
 
 columna VARCHAR2(2000);
  hoja VARCHAR2(4000);
   fila VARCHAR2(4000);
    celda VARCHAR2(4000);
     cierra_fila VARCHAR2(4000);
      cierra_hoja VARCHAR2(4000);
      cierra_excel VARCHAR2(4000);
      
BEGIN
  columna := '<Column ss:Index="' || 2 ||'" ss:AutoFitWidth="1" ss:Width="120"/>';
  hoja:= '<Worksheet ss:Name="' || 'hoja Prueba'/*p_worksheetname*/ ||
                      '"><Table ss:ExpandedColumnCount="' ||
                      2 ||
                      '" x:FullColumns="1" x:FullRows="1">' || columna;
 fila:= '<Row ss:AutoFitHeight="1" ss:Height="' || 15 || '">';
 celda:= '<Cell ss:StyleID="' || 'Underline' ||
                      '" ss:MergeAcross="' || 0 ||
                      '"><Data ss:Type="' || 'String' || '">' || 'Celda 12' ||
                      '</Data></Cell>';
 cierra_fila := '</Row>';
 cierra_hoja:= '</Table></Worksheet>';
 cierra_excel:= '</Workbook>';
 
  DBMS_OUTPUT.PUT_LINE(cabecera );
  DBMS_OUTPUT.PUT_LINE(hoja);
  DBMS_OUTPUT.PUT_LINE(fila);
  DBMS_OUTPUT.PUT_LINE(celda);
  DBMS_OUTPUT.PUT_LINE(cierra_fila);
  DBMS_OUTPUT.PUT_LINE(cierra_hoja);
  DBMS_OUTPUT.PUT_LINE(cierra_excel);
END;
/
SPOOL OFF;
