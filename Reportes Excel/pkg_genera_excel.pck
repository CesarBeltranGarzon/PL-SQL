CREATE OR REPLACE PACKAGE pkg_genera_excel IS
  ---------------------------------------------------------------------
  --  Autor:        Cesar Beltrán
  --  Fecha:        02-Agosto-2010
  --  Descripción:  Genera archivos Excel .xml y lo guarda en el directorio
  --                que se especifique de Oracle.
  --
  --  abre_hoja(Nombre_hoja, No_Columnas)
  --  abre_fila(alto_fila);
  --  escribe_celda(texto_escribir,Estilo,Columnas_a_combinar, tipo_dato);
  ---------------------------------------------------------------------

  PROCEDURE abre_excel(p_directorio IN VARCHAR2 DEFAULT NULL,
                       p_nombre     IN VARCHAR2 DEFAULT NULL);
  PROCEDURE cierra_excel;

  PROCEDURE abre_hoja(p_worksheetname  IN VARCHAR2,
                      v_numerocolumnas IN NUMBER);

  PROCEDURE cierra_hoja;

  PROCEDURE abre_fila(v_tamanofila NUMBER);
  PROCEDURE cierra_fila;

  PROCEDURE escribe_celda(v_contenido    IN VARCHAR2,
                          v_estilocelda  IN VARCHAR2,
                          v_union_celdas IN NUMBER,
                          v_tipo         IN VARCHAR2);

END pkg_genera_excel;
/
CREATE OR REPLACE PACKAGE BODY pkg_genera_excel IS

  l_file utl_FILE.file_type;
  ---------------------------------------------------------------------
  --  Crea y abre el archivo excel
  ---------------------------------------------------------------------
  PROCEDURE abre_excel(p_directorio IN VARCHAR2 DEFAULT NULL,
                       p_nombre     IN VARCHAR2 DEFAULT NULL) IS

    Cabecera VARCHAR2(4000);

  BEGIN
    IF (p_directorio IS NULL OR p_nombre IS NULL) THEN
      raise_application_error(-20001,
                              'Debe ingresar el directorio y nombre de archivo');
    END IF;

    Cabecera := '<?xml version="1.0" encoding="ISO-8859-9"?>' || chr(10) ||
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

    BEGIN
      --Abre el archivo
      l_file := utl_file.fopen(p_directorio, p_nombre || '.xml', 'w');
      utl_file.put_line(l_file, Cabecera);

    EXCEPTION
      WHEN utl_file.write_error THEN
        raise_application_error(-20101,
                                'Error de escritura del archivo, verifique si el archivo ya esta abierto o si tiene acceso al directorio.');
      WHEN utl_file.INVALID_OPERATION THEN
        raise_application_error(-20101,
                                'No se pudo abrir u operar el archivo, Verifique si el archivo ya esta abierto.');
      WHEN utl_file.invalid_path THEN
        raise_application_error(-20101,
                                'Ruta inválida, Verifique si el directorio es el correcto.');
      WHEN others THEN
        raise_application_error(-20101, 'Se generó otra excepción.');
    END;

  END;

  ---------------------------------------------------------------------
  --  Cierra el archivo Excel
  ---------------------------------------------------------------------
  PROCEDURE cierra_excel IS
  BEGIN
    utl_file.put_line(l_file, '</Workbook>');
    utl_file.fclose_all;
  END cierra_excel;

  ---------------------------------------------------------------------
  --  Abre una pestaña u hoja del archivo excel
  ---------------------------------------------------------------------
  PROCEDURE abre_hoja(p_worksheetname  IN VARCHAR2,
                      v_numerocolumnas IN NUMBER) IS

    columna CLOB;
  BEGIN
    -- Crea la hoja y columnas
    FOR i IN 1 .. v_numerocolumnas LOOP
      columna := columna || '<Column ss:Index="' || i ||
                 '" ss:AutoFitWidth="1" ss:Width="120"/>';
    END LOOP;

    utl_file.put_line(l_file,
                      '<Worksheet ss:Name="' || p_worksheetname ||
                      '"><Table ss:ExpandedColumnCount="' ||
                      v_numerocolumnas ||
                      '" x:FullColumns="1" x:FullRows="1">' || columna);
  END abre_hoja;

  ---------------------------------------------------------------------
  --  Cierra una pestaña u hoja del archivo excel
  ---------------------------------------------------------------------
  PROCEDURE cierra_hoja IS
  BEGIN
    utl_file.put_line(l_file, '</Table></Worksheet>');
  END cierra_hoja;

  ---------------------------------------------------------------------
  --  Abre una fila de la hoja
  ---------------------------------------------------------------------
  PROCEDURE abre_fila(v_tamanofila NUMBER) IS
  BEGIN
    utl_file.put_line(l_file,
                      '<Row ss:AutoFitHeight="1" ss:Height="' ||
                      v_tamanofila || '">');
  END abre_fila;

  ---------------------------------------------------------------------
  --  Cierra una fila de la hoja
  ---------------------------------------------------------------------
  PROCEDURE cierra_fila IS
  BEGIN
    utl_file.put_line(l_file, '</Row>');
  END cierra_fila;

  ---------------------------------------------------------------------
  --  Escribe una celda de la fila, si la quiere dejar vacia escriba ''
  ---------------------------------------------------------------------
  PROCEDURE escribe_celda(v_contenido    IN VARCHAR2,
                          v_estilocelda  IN VARCHAR2,
                          v_union_celdas IN NUMBER,
                          v_tipo         IN VARCHAR2) IS
  BEGIN
    utl_file.put_line(l_file,
                      '<Cell ss:StyleID="' || v_estilocelda ||
                      '" ss:MergeAcross="' || v_union_celdas ||
                      '"><Data ss:Type="' || v_tipo || '">' || v_contenido ||
                      '</Data></Cell>');
  END escribe_celda;

END pkg_genera_excel;
/
