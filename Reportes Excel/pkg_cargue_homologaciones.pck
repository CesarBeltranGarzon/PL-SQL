CREATE OR REPLACE PACKAGE pkg_cargue_homologaciones IS
  -----------------------------------------------------------------------------------
  --  Autor:        Cesar Beltrán
  --  Fecha:        20-Agosto-2010
  --  Descripción:  Proceso de cargue de homologaciones y reportes de verificación
  -----------------------------------------------------------------------------------

  PROCEDURE prc_cargue_homologacion(p_accion VARCHAR2);
  PROCEDURE prc_reporte_homologaciones;

END pkg_cargue_homologaciones;
/
CREATE OR REPLACE PACKAGE BODY pkg_cargue_homologaciones IS

  -------------------------------------------------------------------------------
  -- PROCESO PRINCIPAL DE  CARGUE DE HOMOLOGACIONES
  -- Acciones posibles como parámetro de entrada:
  -- HOMOLOGAR, REPROCESAR y RETENER
  -------------------------------------------------------------------------------
  PROCEDURE prc_cargue_homologacion(p_accion VARCHAR2) IS
  
    CURSOR tablas_cargadas IS
      SELECT UNIQUE NVL(hc.objeto, 'COMUN - VARIOS OBJETOS'),
             hc.atributo,
             hc.fuente,
             hc.tabla_homologada,
             hc.tabla_codigos,
             hc.version_plantilla
        FROM homologacion.homologaciones_cargue hc
       WHERE hc.tabla_homologada IS NOT NULL
         AND Upper(hc.tabla_homologada) <> 'NO APLICA';
  
    CURSOR truncado_tablas IS
      SELECT UNIQUE hc.tabla_homologada
        FROM homologacion.homologaciones_cargue hc
       WHERE hc.tabla_homologada IS NOT NULL
         AND Upper(hc.accion) = 'HOMOLOGAR'
         AND Upper(hc.tabla_homologada) <> 'NO APLICA';
  
    CURSOR homologaciones(acc VARCHAR2) IS
      SELECT ROWID,
             objeto,
             atributo,
             fuente,
             codigo1_fuente,
             codigo2_fuente,
             descripcion_fuente,
             codigo_homologado,
             tabla_homologada,
             tabla_codigos,
             version_plantilla,
             homologa_estado
        FROM homologacion.homologaciones_cargue
       WHERE accion = acc;
  
    TYPE CUR_TYP IS REF CURSOR;
    reg_sentencia_cursor   CUR_TYP;
    sentencia_cursor       VARCHAR2(2000);
    sentencia              VARCHAR2(1000);
    sentencia2             VARCHAR2(500);
    sentencia3             VARCHAR2(500);
    sentencia4             VARCHAR2(500);
    sentencia5             VARCHAR2(500);
    sentencia6             VARCHAR2(500);
    sentencia7             VARCHAR2(500);
    sentencia_fecha        VARCHAR2(500);
    sentencia_fecha2       VARCHAR2(500);
    consulta               VARCHAR2(500);
    v_comprueba_codigo     VARCHAR2(500);
    v_indica_err_codigo    VARCHAr2(1);
    codigos_cod            VARCHAR2(60);
    codigos_cod2           VARCHAR2(60);
    codigos_desc           VARCHAR2(60);
    codigos_desc2          VARCHAR2(60);
    codigos_dest_desc      VARCHAR2(60);
    valor_dest_desc        VARCHAR2(500);
    valor_dest_desc2       VARCHAr2(500);
    codigos_fuente         VARCHAR2(60);
    codigos_dest           VARCHAR2(60);
    codigos_plant          VARCHAR2(60);
    codigos_producto       VARCHAR2(60);
    codigos_fecha_carga    VARCHAR2(60);
    v_observacion          VARCHAR2(500);
    existe_tablaCodigos    VARCHAR2(5);
    v_fuente               VARCHAR2(50);
    v_codigo               VARCHAR2(250);
    v_codigo2              VARCHAR2(250);
    v_desc                 VARCHAR2(500);
    v_desc2                VARCHAR2(500);
    v_cod_homologa         VARCHAR2(500);
    v_plantilla            VARCHAR2(5);
    v_comprueba_existentes NUMBER;
    v_contador             NUMBER;
    v_cont_errores         NUMBER;
    v_error                VARCHAR2(3);
    v_accion               VARCHAR2(10);
    campo_destino          VARCHAR2(60);
    campo_atributo         VARCHAR2(60);
    campo_fuente           VARCHAR2(60);
    fecha_carga            DATE;
    v_join                 VARCHAR2(500);
    cod_dest_cod           VARCHAR2(500);
    codigos_dest_cod       VARCHAR2(500);
    campo_descripcion      VARCHAR2(500);
    campo_descripcion2     VARCHAR2(500);
    descripcion_destino    VARCHAR2(500);
    codigo_novacio         VARCHAR2(500);
    codigo_novacio2        VARCHAR2(500);
  
  BEGIN
  
    -- Fecha a ingresar en las homologaciones, fecha de ejecución del proceso
    fecha_carga := to_date(SYSDATE, 'dd/mm/yyyy');
  
    IF Upper(p_accion) = 'HOMOLOGAR' THEN
      -- Borra estados y descripciones de procesos anteriores
      UPDATE homologacion.homologaciones_cargue
         SET homologa_estado = NULL, homologa_descripcion = NULL
       WHERE Upper(accion) = 'HOMOLOGAR'
         AND (homologa_estado IS NOT NULL OR
              homologa_descripcion IS NOT NULL);
    
      -- Validar este.
      UPDATE homologacion.homologaciones_cargue
         SET codigo_homologado = '-1'
       WHERE codigo_homologado IS NULL
         AND codigo1_fuente IS NOT NULL;
    
      -- Las homologaciones de rdsi tienen los nombres de objeto y atributos en minúsculas
      UPDATE homologacion.homologaciones_cargue
         SET objeto = Lower(objeto), atributo = Lower(atributo)
       WHERE Upper(tabla_homologada) = 'HOMOLOGACION.HOM_ENLACE_RDSI';
    
      COMMIT;
    
      -- Trunca tablas de homologaciones para luego cargarlas
      FOR reg_truncado IN truncado_tablas LOOP
        EXECUTE IMMEDIATE ('TRUNCATE TABLE ' ||
                          reg_truncado.tabla_homologada);
      END LOOP;
    
      -- Tablas que se copian de copias_homologacion
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_arboles';
      INSERT INTO homologacion.hom_arboles
        (hri_sist_fuente,
         hri_desc_fuente,
         hri_cod_dest_relacion,
         hri_cod_dest_tipo,
         hri_vers_plantilla,
         hri_prod,
         hri_fecha_carga)
        SELECT hri_sist_fuente,
               hri_desc_fuente,
               hri_cod_dest_relacion,
               hri_cod_dest_tipo,
               hri_vers_plantilla,
               hri_prod,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_arboles;
    
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_ciud_arboles_800';
      INSERT INTO homologacion.hom_ciud_arboles_800
        (hca_sist_fuente,
         hca_desc_fuente,
         hca_cod_dest,
         hca_vers_plantilla,
         hca_prod,
         hca_fecha_carga,
         cod_dane)
        SELECT hca_sist_fuente,
               hca_desc_fuente,
               hca_cod_dest,
               hca_vers_plantilla,
               hca_prod,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga,
               cod_dane
          FROM copias_homologacion.hom_ciud_arboles_800;
    
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_estado_cli';
      INSERT INTO homologacion.hom_estado_cli
        (hec_sist_fuente,
         hec_cod_fuente,
         hec_desc_fuente,
         hec_cod_destino,
         hec_desc_destino,
         hec_vers_plantilla,
         hec_fecha_carga)
        SELECT hec_sist_fuente,
               hec_cod_fuente,
               hec_desc_fuente,
               hec_cod_destino,
               hec_desc_destino,
               hec_vers_plantilla,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_estado_cli
         WHERE hec_cod_fuente not like '-%';
    
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_num_dir_ip';
      INSERT INTO homologacion.hom_num_dir_ip
        (hor_sist_fuente,
         hor_cod_fuente,
         hor_desc_fuente,
         hor_cod_destino,
         hor_vers_plantilla,
         hor_prod,
         hor_fecha_carga)
        SELECT hor_sist_fuente,
               hor_cod_fuente,
               hor_desc_fuente,
               hor_cod_destino,
               hor_vers_plantilla,
               hor_prod,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_num_dir_ip;
    
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_subtipo_pedido';
      INSERT INTO homologacion.hom_subtipo_pedido
        (hpl_sist_fuente,
         hpl_cod_fuente,
         hpl_desc_fuente,
         hpl_cod_destino,
         hpl_vers_plantilla,
         hpl_prod,
         hpl_fecha_carga)
        SELECT hpl_sist_fuente,
               hpl_cod_fuente,
               hpl_desc_fuente,
               hpl_cod_destino,
               hpl_vers_plantilla,
               hpl_prod,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_subtipo_pedido;
    
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_tecnologia_bar';
      INSERT INTO homologacion.hom_tecnologia_bar
        (htb_sist_fuente,
         htb_cod_fuente,
         htb_desc_fuente,
         htb_cod_destino,
         htb_vers_plantilla,
         htb_fecha_carga)
        SELECT htb_sist_fuente,
               htb_cod_fuente,
               htb_desc_fuente,
               htb_cod_destino,
               htb_vers_plantilla,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_tecnologia_bar;
    
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_tipo_organizacion';
      INSERT INTO homologacion.hom_tipo_organizacion
        (to_sist_fuente,
         to_cod_fuente,
         to_desc_fuente,
         to_cod_destino,
         to_vers_plantilla,
         to_prod,
         to_fecha_carga)
        SELECT to_sist_fuente,
               to_cod_fuente,
               to_desc_fuente,
               to_cod_destino,
               to_vers_plantilla,
               to_prod,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_tipo_organizacion;
    
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_tipo_pedido';
      INSERT INTO homologacion.hom_tipo_pedido
        (hpl_sist_fuente,
         hpl_cod_fuente,
         hpl_desc_fuente,
         hpl_pts_fte_lanza,
         hpl_cod_destino,
         hpl_vers_plantilla,
         hpl_prod,
         hpl_fecha_carga)
        SELECT hpl_sist_fuente,
               hpl_cod_fuente,
               hpl_desc_fuente,
               hpl_pts_fte_lanza,
               hpl_cod_destino,
               hpl_vers_plantilla,
               hpl_prod,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_tipo_pedido;
    
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_tipo_vivienda';
      INSERT INTO homologacion.hom_tipo_vivienda
        (htv_sist_fuente,
         htv_cod_fuente,
         htv_desc_fuente,
         htv_cod_destino,
         htv_desc_destino,
         htv_vers_plantilla,
         htv_fecha_carga)
        SELECT htv_sist_fuente,
               htv_cod_fuente,
               htv_desc_fuente,
               htv_cod_destino,
               htv_desc_destino,
               htv_vers_plantilla,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_tipo_vivienda;
    
      EXECUTE IMMEDIATE 'TRUNCATE TABLE homologacion.hom_tecnologia_bar';
      INSERT INTO homologacion.hom_tecnologia_bar
        (htb_sist_fuente,
         htb_cod_fuente,
         htb_desc_fuente,
         htb_cod_destino,
         htb_vers_plantilla,
         htb_fecha_carga)
        SELECT htb_sist_fuente,
               htb_cod_fuente,
               htb_desc_fuente,
               htb_cod_destino,
               htb_vers_plantilla,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_tecnologia_bar;
    
      -- Copiadas solo lo faltante
      INSERT INTO homologacion.hom_ciudad
        (hci_sist_fuente,
         hci_cod_fuente,
         hci_desc_fuente,
         hci_cod_destino,
         hci_vers_plantilla,
         fecha_carga)
        SELECT hci_sist_fuente,
               hci_cod_fuente,
               hci_desc_fuente,
               hci_cod_destino,
               hci_vers_plantilla,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_ciudad
         WHERE Upper(hci_sist_fuente) = 'REGIS'
           AND hci_cod_fuente not like '-%';
    
      INSERT INTO homologacion.hom_depto
        (hde_sist_fuente,
         hde_cod_fuente,
         hde_desc_fuente,
         hde_cod_destino,
         hde_vers_plantilla,
         fecha_carga)
        SELECT hde_sist_fuente,
               hde_cod_fuente,
               hde_desc_fuente,
               hde_cod_destino,
               hde_vers_plantilla,
               (SELECT To_char(SYSDATE, 'dd/mm/yyyy') FROM dual) fecha_carga
          FROM copias_homologacion.hom_depto
         WHERE Upper(hde_sist_fuente) = 'REGIS'
           AND hde_cod_fuente NOT LIKE '-%';
    
      INSERT INTO homologacion.hom_sector_econ
        (hse_sist_fuente,
         hse_cod_fuente,
         hse_desc_fuente,
         hse_cod_destino,
         hse_vers_plantilla)
        SELECT hse_sist_fuente,
               hse_cod_fuente,
               hse_desc_fuente,
               hse_cod_destino,
               hse_vers_plantilla
          FROM copias_homologacion.hom_sector_econ
         WHERE (Upper(hse_sist_fuente) = 'MKDEOREL' OR
               Upper(hse_sist_fuente) = 'SERVICDESK' OR
               Upper(hse_sist_fuente) = 'SIC' OR
               Upper(hse_sist_fuente) = 'TDAVIRTUAL')
           AND hse_cod_fuente NOT LIKE '-%';
    
      COMMIT;
    
    ELSIF Upper(p_accion) = 'REPROCESAR' THEN
    
      -- Borra descripciones de estados error
      UPDATE homologacion.homologaciones_cargue
         SET homologa_estado = NULL, homologa_descripcion = NULL
       WHERE Upper(homologa_estado) = 'ERR';
      COMMIT;
    END IF;
  
    --Proceso de cargue de homologaciones
    FOR reg_homologaciones IN homologaciones(Upper(p_accion)) LOOP
    
      v_comprueba_codigo := NULL;
      sentencia          := NULL;
      v_cont_errores     := 0;
      v_contador         := 0;
      campo_destino      := NULL;
      campo_fuente       := NULL;
      sentencia_fecha    := NULL;
      codigos_cod        := NULL;
      codigos_cod2       := NULL;
      codigos_desc       := NULL;
      codigos_desc2      := NULL;
      codigos_dest       := NULL;
      codigos_dest_desc  := NULL;
      valor_dest_desc    := NULL;
    
      -- Si no existe tabla de homologacion actualiza con el mensaje.
      IF reg_homologaciones.tabla_homologada IS NULL THEN
        UPDATE homologacion.homologaciones_cargue hc
           SET hc.homologa_estado      = 'ERR',
               hc.homologa_descripcion = 'No existe tabla de Homologación para este atributo.',
               hc.accion               = 'REPROCESAR'
         WHERE hc.rowid = reg_homologaciones.rowid;
      
        COMMIT;
      
        -- Tablas que se copian de copias_homologacion
      ELSIF Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_ARBOLES' OR
            Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_CIUD_ARBOLES_800' OR
            Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_ESTADO_CLI' OR Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_NUM_DIR_IP' OR
            Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_SUBTIPO_PEDIDO' OR
            Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_TECNOLOGIA_BAR' OR
            Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_TIPO_ORGANIZACION' OR
            Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_TIPO_PEDIDO' OR
            Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_TIPO_VIVIENDA' OR
            Upper(reg_homologaciones.tabla_homologada) =
            'HOMOLOGACION.HOM_TECNOLOGIA_BAR' THEN
      
        UPDATE homologacion.homologaciones_cargue hc
           SET hc.homologa_estado      = 'OK',
               hc.homologa_descripcion = 'Esta tabla se cargó de la copia de homologación.',
               hc.accion               = NULL
         WHERE hc.rowid = reg_homologaciones.rowid;
      
        COMMIT;
      
        -- Si existe tabla de Homologación ejecuta el proceso.
      ELSE
      
        BEGIN
          SELECT DISTINCT column_name
            INTO codigos_fecha_carga
            FROM all_tab_columns
           WHERE table_name =
                 Substr(reg_homologaciones.tabla_homologada,
                        Instr(reg_homologaciones.tabla_homologada, '.') + 1)
             AND Upper(owner) =
                 Substr(reg_homologaciones.tabla_homologada,
                        1,
                        Instr(reg_homologaciones.tabla_homologada, '.') - 1)
             AND Upper(column_name) LIKE '%FECHA_CARGA';
        
          sentencia_fecha  := ', ' || codigos_fecha_carga;
          sentencia_fecha2 := ', ''' || fecha_carga || '''';
        
        EXCEPTION
          WHEN OTHERS THEN
            sentencia_fecha  := NULL;
            sentencia_fecha2 := NULL;
        END;
      
        IF reg_homologaciones.tabla_homologada =
           'HOMOLOGACION.HOM_ENLACE_RDSI' THEN
        
          campo_atributo := 'HOM_ENL_ATRIBUTO';
          sentencia2     := ' AND ' || campo_atributo || '= ''' ||
                            reg_homologaciones.atributo || '''';
          sentencia3     := ', ' || campo_atributo;
          sentencia4     := ', ''' || reg_homologaciones.atributo || '''';
          sentencia5     := NULL;
          sentencia6     := NULL;
          sentencia7     := NULL;
        
        ELSIF upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_MERCADO_CLI' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_ESTADO_CIVIL' THEN
        
          BEGIN
            SELECT DISTINCT column_name
              INTO descripcion_destino
              FROM all_tab_columns
             WHERE table_name =
                   Substr(reg_homologaciones.tabla_homologada,
                          Instr(reg_homologaciones.tabla_homologada, '.') + 1)
               AND Upper(owner) =
                   Substr(reg_homologaciones.tabla_homologada,
                          1,
                          Instr(reg_homologaciones.tabla_homologada, '.') - 1)
               AND (column_name LIKE '%_DESC_DESTINO');
          
          EXCEPTION
            WHEN OTHERS THEN
              descripcion_destino := NULL;
          END;
        
          sentencia2 := NULL;
          sentencia3 := NULL;
          sentencia4 := NULL;
          --sentencia5 := ', HMC_DESC_DESTINO ';
          sentencia5 := ', ' || descripcion_destino;
          sentencia6 := ',''' || reg_homologaciones.codigo_homologado || '''';
          sentencia7 := sentencia5 || ' = ''' ||
                        reg_homologaciones.codigo_homologado || '''';
        
          /*ELSIF upper(reg_homologaciones.tabla_homologada) = 'HOM_ESTADO_CIVIL' THEN
          
          sentencia2 := NULL;
          sentencia3 := NULL;
          sentencia4 := NULL;
          sentencia5 := ', HEC_DESC_DESTINO ';
          sentencia6 := ',''' || reg_homologaciones.codigo_homologado || '''';
          sentencia7 := sentencia5 || ' = ''' || reg_homologaciones.codigo_homologado || '''';*/
        
          -- Tablas que filtran por producto
        ELSIF upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_PLAN_PROD' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_PLAN_LB_PBX' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_CUPOS_PROD' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_ESTADO_PROD' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_EQUIPO_PROD' OR upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_EQUIPO' OR upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_DIAS_DEMO' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_VELOCIDADES' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_FRANJAS_PROD' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_PLAN_BAR' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_TECNOLOGIA_BAR' OR
              upper(reg_homologaciones.tabla_homologada) =
              'PRODUCTOS.HOMOLOGACION_PROD_SACC' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_COMP_EXTEN_1' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_SUBTIPO_PEDIDO' OR
              upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_BANDA_LDH' OR upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_CATEGORIA' OR upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_HORAS' OR upper(reg_homologaciones.tabla_homologada) =
              'HOMOLOGACION.HOM_PLAN_ESPECIAL' THEN
          -- Verificar cuales mas diferencian por producto
        
          BEGIN
            SELECT DISTINCT column_name
              INTO codigos_producto
              FROM all_tab_columns
             WHERE table_name =
                   Substr(reg_homologaciones.tabla_homologada,
                          Instr(reg_homologaciones.tabla_homologada, '.') + 1)
               AND Upper(owner) =
                   Substr(reg_homologaciones.tabla_homologada,
                          1,
                          Instr(reg_homologaciones.tabla_homologada, '.') - 1)
               AND (column_name LIKE '%_PROD' OR
                   column_name LIKE '%_PRODUCTO');
          
          EXCEPTION
            WHEN OTHERS THEN
              codigos_producto := NULL;
          END;
        
          /*sentencia2 := ' AND ' || codigos_producto || '= ''' ||
          reg_homologaciones.objeto || '''';*/
          sentencia3 := ', ' || codigos_producto;
          sentencia5 := NULL;
          sentencia6 := NULL;
          sentencia7 := NULL;
        
          IF upper(reg_homologaciones.tabla_homologada) =
             'HOMOLOGACION.HOM_CATEGORIA' THEN
            sentencia2 := ' AND ' || codigos_producto || '= ''' || '142' || '''';
            sentencia4 := ', ''' || '142' || '''';
          ELSE
            sentencia2 := ' AND ' || codigos_producto || '= ''' ||
                          reg_homologaciones.objeto || '''';
            sentencia4 := ', ''' || reg_homologaciones.objeto || '''';
          END IF;
        
        ELSE
          sentencia2 := NULL;
          sentencia3 := NULL;
          sentencia4 := NULL;
          sentencia5 := NULL;
          sentencia6 := NULL;
          sentencia7 := NULL;
        END IF;
      
        IF Upper(reg_homologaciones.tabla_homologada) =
           'HOMOLOGACION.HOM_PLAN_BAR' AND
           (Upper(reg_homologaciones.atributo) = 'PLAN ESPECIAL' OR
            Upper(reg_homologaciones.atributo) = 'PLAN - PLAN ESPECIAL') THEN
        
          campo_destino := 'HVL_PLN_ESP';
        END IF;
      
        -- Columnas de la tabla de homologacion
        BEGIN
          SELECT DISTINCT case
                            when exists (select DISTINCT COLUMN_NAME
                                    from all_tab_columns
                                   WHERE TABLE_NAME =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') + 1)
                                     AND Upper(owner) =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                1,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') - 1)
                                     AND Upper(column_name) LIKE
                                         '%SIST_FUENTE') then
                             (select DISTINCT COLUMN_NAME
                                from all_tab_columns
                               WHERE TABLE_NAME =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') + 1)
                                 AND Upper(owner) =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            1,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') - 1)
                                 AND Upper(column_name) LIKE '%SIST_FUENTE')
                            else
                             NULL
                          end a,
                          case
                            when exists
                             (select DISTINCT COLUMN_NAME
                                    from all_tab_columns
                                   WHERE TABLE_NAME =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') + 1)
                                     AND Upper(owner) =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                1,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') - 1)
                                     AND (Upper(column_name) LIKE
                                         '%COD_FUENTE' OR Upper(column_name) LIKE
                                         '%CO_FUENTE')) then
                             (select DISTINCT COLUMN_NAME
                                from all_tab_columns
                               WHERE TABLE_NAME =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') + 1)
                                 AND Upper(owner) =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            1,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') - 1)
                                 AND (Upper(column_name) LIKE '%COD_FUENTE' OR
                                     Upper(column_name) LIKE '%CO_FUENTE'))
                            else
                             NULL
                          end AS cr,
                          case
                            when exists (select DISTINCT COLUMN_NAME
                                    from all_tab_columns
                                   WHERE TABLE_NAME =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') + 1)
                                     AND Upper(owner) =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                1,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') - 1)
                                     AND Upper(column_name) LIKE
                                         '%DESC_FUENTE') then
                             (select DISTINCT COLUMN_NAME
                                from all_tab_columns
                               WHERE TABLE_NAME =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') + 1)
                                 AND Upper(owner) =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            1,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') - 1)
                                 AND Upper(column_name) LIKE '%DESC_FUENTE')
                            else
                             NULL
                          end AS cr,
                          case
                            when exists (select DISTINCT COLUMN_NAME
                                    from all_tab_columns
                                   WHERE TABLE_NAME =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') + 1)
                                     AND Upper(owner) =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                1,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') - 1)
                                     AND Upper(column_name) LIKE
                                         '%COD_DESTINO'
                                     AND ROWNUM = 1) then
                             (select DISTINCT COLUMN_NAME
                                from all_tab_columns
                               WHERE TABLE_NAME =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') + 1)
                                 AND Upper(owner) =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            1,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') - 1)
                                 AND Upper(column_name) LIKE '%COD_DESTINO'
                                 AND ROWNUM = 1)
                            else
                             (select DISTINCT COLUMN_NAME
                                from all_tab_columns
                               WHERE TABLE_NAME =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') + 1)
                                 AND Upper(owner) =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            1,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') - 1)
                                 AND Upper(column_name) LIKE '%DESC_DESTINO')
                          end AS cr,
                          case
                            when exists (select DISTINCT COLUMN_NAME
                                    from all_tab_columns
                                   WHERE TABLE_NAME =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') + 1)
                                     AND Upper(owner) =
                                         Substr(reg_homologaciones.tabla_homologada,
                                                1,
                                                Instr(reg_homologaciones.tabla_homologada,
                                                      '.') - 1)
                                     AND Upper(column_name) LIKE
                                         '%_PLANTILLA') then
                             (select DISTINCT COLUMN_NAME
                                from all_tab_columns
                               WHERE TABLE_NAME =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') + 1)
                                 AND Upper(owner) =
                                     Substr(reg_homologaciones.tabla_homologada,
                                            1,
                                            Instr(reg_homologaciones.tabla_homologada,
                                                  '.') - 1)
                                 AND Upper(column_name) LIKE '%_PLANTILLA')
                            else
                             NULL
                          end AS cr
            INTO codigos_fuente,
                 codigos_cod,
                 codigos_desc,
                 codigos_dest,
                 codigos_plant
            FROM DUAL;
        
        EXCEPTION
          WHEN OTHERS THEN
            codigos_plant  := NULL;
            codigos_dest   := NULL;
            codigos_fuente := NULL;
            codigos_desc   := NULL;
            codigos_cod    := NULL;
        END;
      
        IF campo_destino IS NOT NULL THEN
          codigos_dest := campo_destino;
        END IF;
      
        -- Tabla HOMOLOGACION_PROD_SACC la cual es diferente a las demás
        IF Upper(reg_homologaciones.tabla_homologada) =
           'PRODUCTOS.HOMOLOGACION_PROD_SACC' THEN
        
          IF Upper(reg_homologaciones.atributo) = 'PLAN' THEN
            codigos_dest := 'hpl_cod_destino';
          ELSIF Upper(reg_homologaciones.atributo) = 'CUPO' OR
                Upper(reg_homologaciones.atributo) =
                'CUPO PARA PLAN VALOR UNICO' OR
                Upper(reg_homologaciones.atributo) =
                'CUPO PARA PLAN 7 SIN LIMITES' OR
                Upper(reg_homologaciones.atributo) =
                'CUPO PARA PLAN VALOR UNICO RESERVA' THEN
            codigos_dest := 'hcp_cod_destino';
          ELSIF Upper(reg_homologaciones.atributo) = 'TIPO' OR
                Upper(reg_homologaciones.atributo) = 'PLAN - TIPO' THEN
            codigos_dest := 'htl_cod_destino';
          ELSIF Upper(reg_homologaciones.atributo) = 'FACTURACION' OR
                Upper(reg_homologaciones.atributo) = 'FACTURACIÓN' OR
                Upper(reg_homologaciones.atributo) = 'PLAN - FACTURACIÓN' OR
                Upper(reg_homologaciones.atributo) = 'PLAN - FACTURACION' THEN
            codigos_dest := 'hpl_cod_destino_fact';
          ELSIF Upper(reg_homologaciones.atributo) = 'TIPO CONVENIO' OR
                Upper(reg_homologaciones.atributo) = 'TIPO DE CONVENIO' OR
                Upper(reg_homologaciones.atributo) = 'PLAN - TIPO CONVENIO' OR
                Upper(reg_homologaciones.atributo) =
                'PLAN - TIPO DE CONVENIO' THEN
            codigos_dest := 'htc_tipo_convenio';
          END IF;
        
        END IF;
        ------------------------------------------------------------------------------------
        -- CASO 1.  solo tiene una descripción de la fuente y se debe buscar código en tablas de copias.
        ------------------------------------------------------------------------------------
        IF reg_homologaciones.codigo1_fuente IS NOT NULL AND
           reg_homologaciones.codigo2_fuente IS NULL AND
           reg_homologaciones.tabla_codigos IS NOT NULL THEN
        
          -- Arma Join casos general
          v_join := ' LEFT OUTER JOIN ' || reg_homologaciones.tabla_codigos ||
                    ' tc ON Upper(NVL(TRIM(tc.' || codigos_desc ||
                    '),TRIM(' || codigos_cod ||
                    '))) = Upper(TRIM(REPLACE(hc.codigo1_fuente,'' '','' ''))) AND Upper(hc.fuente) = Upper(' ||
                    codigos_fuente || ')' || sentencia2 ||
                    '  WHERE hc.ROWID = ' || '''' ||
                    reg_homologaciones.rowid || '''';
        
          -- Arma Join tabla HOMOLOGACION.HOM_MDT_TIPO_DESC es diferente a las otras
          IF reg_homologaciones.tabla_homologada =
             'HOMOLOGACION.HOM_MDT_TIPO_DESC' OR
             reg_homologaciones.tabla_homologada =
             'HOMOLOGACION.HOM_DESC_MDT' OR reg_homologaciones.tabla_homologada =
             'HOMOLOGACION.HOM_MDT_CARGO' OR
             reg_homologaciones.tabla_homologada =
             'HOMOLOGACION.HOM_VIGENCIA_DOC' OR
             reg_homologaciones.tabla_homologada = 'HOMOLOGACION.HOM_CANAL' OR
             reg_homologaciones.tabla_homologada =
             'HOMOLOGACION.HOM_ESTADO_PROD' OR
             reg_homologaciones.tabla_homologada =
             'HOMOLOGACION.HOM_TIPO_CLIENTE' OR
             reg_homologaciones.tabla_homologada =
             'HOMOLOGACION.HOM_BANDA_LDH' THEN
          
            --codigos_dest := 'hmd_desc_destino';
          
            IF (reg_homologaciones.fuente = 'SGS' AND
               reg_homologaciones.descripcion_fuente IS NOT NULL) OR
               reg_homologaciones.fuente = 'BUV' OR
               (reg_homologaciones.fuente = 'SGS' AND
               reg_homologaciones.tabla_homologada =
               'HOMOLOGACION.HOM_TIPO_CLIENTE') OR
               reg_homologaciones.tabla_homologada =
               'HOMOLOGACION.HOM_BANDA_LDH' THEN
              v_join := ' LEFT OUTER JOIN ' ||
                        reg_homologaciones.tabla_codigos ||
                        ' tc ON Upper(NVL(TRIM(tc.' || codigos_cod ||
                        '),TRIM(' || codigos_desc ||
                        '))) = Upper(TRIM(hc.codigo1_fuente))AND Upper(hc.fuente) = Upper(' ||
                        codigos_fuente || ')' || sentencia2 ||
                        '  WHERE hc.ROWID = ' || '''' ||
                        reg_homologaciones.rowid || '''';
            END IF;
          
          END IF;
        
          -- Join para PRODUCTOS.HOMOLOGACION_PROD_SACC que es diferente
          IF reg_homologaciones.tabla_homologada =
             'PRODUCTOS.HOMOLOGACION_PROD_SACC' THEN
            v_join := ' LEFT OUTER JOIN ' ||
                      reg_homologaciones.tabla_codigos ||
                      ' tc ON Upper(NVL(TRIM(tc.' || codigos_desc ||
                      '),TRIM(' || codigos_cod ||
                      '))) = Upper(NVL(TRIM(hc.descripcion_fuente), TRIM(hc.codigo1_fuente))) AND Upper(hc.fuente) = Upper(' ||
                      codigos_fuente || ')' || sentencia2 ||
                      '  WHERE hc.ROWID = ' || '''' ||
                      reg_homologaciones.rowid || '''';
          END IF;
        
          -- Se hace un cursor ya que puede tener varios códigos a insertar con la misma descripción
          IF reg_homologaciones.tabla_homologada =
             'HOMOLOGACION.HOM_BANDA_LDH' THEN
            sentencia_cursor := ' SELECT ''' || reg_homologaciones.fuente ||
                                ''', TO_CHAR(NVL(TO_CHAR(tc.' ||
                                codigos_cod ||
                                '),''ERROR'')), NVL(hc.descripcion_fuente, tc.' ||
                                codigos_desc ||
                                '), hc.codigo_homologado, hc.version_plantilla ' ||
                                ' FROM homologacion.homologaciones_cargue hc ' ||
                                v_join;
          ELSE
            sentencia_cursor := ' SELECT ''' || reg_homologaciones.fuente ||
                                ''', TO_CHAR(NVL(TO_CHAR(tc.' ||
                                codigos_cod ||
                                '),''ERROR'')), NVL(hc.descripcion_fuente, hc.codigo1_fuente), hc.codigo_homologado, hc.version_plantilla ' ||
                                ' FROM homologacion.homologaciones_cargue hc ' ||
                                v_join;
          END IF;
        
          OPEN reg_sentencia_cursor FOR sentencia_cursor;
        
          LOOP
          
            v_fuente               := NULL;
            v_codigo               := NULL;
            v_desc                 := NULL;
            v_cod_homologa         := NULL;
            v_plantilla            := NULL;
            v_comprueba_existentes := 0;
            v_contador             := v_contador + 1;
          
            BEGIN
              FETCH reg_sentencia_cursor
                into v_fuente, v_codigo, v_desc, v_cod_homologa, v_plantilla;
            EXCEPTION
              WHEN OTHERS THEN
                v_codigo := 'ERROR-INSERT';
            END;
            EXIT WHEN reg_sentencia_cursor%NOTFOUND;
          
            IF v_codigo = 'ERROR' THEN
            
              v_cont_errores := v_cont_errores + 1;
              sentencia      := '. No se encontró código fuente con esa descripción.';
            
            ELSIF v_codigo = 'ERROR-INSERT' THEN
              v_cont_errores := v_cont_errores + 1;
              sentencia      := 'Falló la inserción en la tabla: ' ||
                                reg_homologaciones.tabla_homologada ||
                                ' - Posible error de datos.';
            
            ELSE
              -- Se valida que no se haya ingresado ya esta homologación.
              consulta := 'SELECT COUNT(1) FROM ' ||
                          reg_homologaciones.tabla_homologada ||
                          ' WHERE Upper(' || codigos_fuente ||
                          ') = Upper(''' || v_fuente || ''') AND Upper(' ||
                          codigos_cod || ') = Upper(''' || v_codigo ||
                          ''') AND TRIM(Upper(' || codigos_desc ||
                          ')) = TRIM(Upper(''' || v_desc || '''))' ||
                          'AND Upper(' || codigos_plant || ') = Upper(''' ||
                          v_plantilla || ''')' || sentencia2;
            
              BEGIN
                EXECUTE IMMEDIATE consulta
                  INTO v_comprueba_existentes;
              EXCEPTION
                WHEN OTHERS THEN
                  v_comprueba_existentes := NULL;
              END;
            
              -- se arma sentencia que ingresa homologación o describe el error.
              IF v_comprueba_existentes = 0 THEN
              
                -- Tablas que tienen el campo desc_destino
                IF reg_homologaciones.tabla_homologada =
                   'HOMOLOGACION.HOM_MDT_TIPO_DESC' OR
                   reg_homologaciones.tabla_homologada =
                   'HOMOLOGACION.HOM_DESC_MDT' OR
                   reg_homologaciones.tabla_homologada =
                   'HOMOLOGACION.HOM_MDT_CARGO' THEN
                
                  codigos_dest     := 'hmd_desc_destino';
                  cod_dest_cod     := ''',''' || v_codigo;
                  codigos_dest_cod := ',hmd_cod_destino';
                ELSIF reg_homologaciones.tabla_homologada =
                      'HOMOLOGACION.HOM_VIGENCIA_DOC' THEN
                  codigos_dest     := 'hvd_desc_destino';
                  cod_dest_cod     := ''',''' || v_codigo;
                  codigos_dest_cod := ',hvd_cod_destino';
                
                ELSIF reg_homologaciones.tabla_homologada =
                      'HOMOLOGACION.HOM_CANAL' THEN
                  codigos_dest     := 'hca_desc_destino';
                  cod_dest_cod     := ''',''' || v_cod_homologa;
                  codigos_dest_cod := ',hca_cod_destino';
                
                ELSIF reg_homologaciones.tabla_homologada =
                      'HOMOLOGACION.HOM_NIVEL_ACAD' THEN
                  codigos_dest     := 'hna_desc_destino';
                  cod_dest_cod     := ''',''' || v_cod_homologa;
                  codigos_dest_cod := ',hna_cod_destino';
                
                ELSIF reg_homologaciones.tabla_homologada =
                      'HOMOLOGACION.HOM_OCUP_PPAL' THEN
                  codigos_dest     := 'hop_desc_destino';
                  cod_dest_cod     := ''',''' || v_cod_homologa;
                  codigos_dest_cod := ',hop_cod_destino';
                
                ELSIF reg_homologaciones.tabla_homologada =
                      'HOMOLOGACION.HOM_PROFESION' THEN
                  codigos_dest     := 'hpr_desc_destino';
                  cod_dest_cod     := ''',''' || v_cod_homologa;
                  codigos_dest_cod := ',hpr_cod_destino';
                
                ELSIF reg_homologaciones.tabla_homologada =
                      'HOMOLOGACION.HOM_FORMA_CONTACTO' THEN
                  codigos_dest     := 'hfc_desc_destino';
                  cod_dest_cod     := ''',''' || v_cod_homologa;
                  codigos_dest_cod := ',hfc_cod_destino';
                
                ELSE
                  cod_dest_cod     := NULL;
                  codigos_dest_cod := NULL;
                END IF;
              
                sentencia := 'INSERT INTO ' ||
                             reg_homologaciones.tabla_homologada || '(' ||
                             codigos_fuente || ',' || codigos_cod || ',' ||
                             codigos_desc || codigos_dest_cod || ',' ||
                             codigos_dest || ',' || codigos_plant ||
                             sentencia3 || sentencia_fecha || sentencia5 || ')' ||
                             ' VALUES(''' || v_fuente || ''',''' ||
                             v_codigo || ''',''' || v_desc || cod_dest_cod ||
                             ''',''' || v_cod_homologa || ''',''' ||
                             v_plantilla || '''' || sentencia4 ||
                             sentencia_fecha2 || sentencia6 || ')';
              
              ELSIF v_comprueba_existentes > 0 THEN
              
                -- Para retenciones, si ya existe lo actualiza con el codigo destino acordado
                IF Upper(p_accion) = 'RETENER' OR
                   (Upper(reg_homologaciones.tabla_homologada) =
                    'HOMOLOGACION.HOM_PLAN_BAR' AND
                    (Upper(reg_homologaciones.atributo) = 'PLAN ESPECIAL' OR
                     Upper(reg_homologaciones.atributo) =
                     'PLAN - PLAN ESPECIAL') OR
                    TRIM(Upper(reg_homologaciones.atributo)) = 'PLAN') OR
                   Upper(reg_homologaciones.tabla_homologada) =
                   'PRODUCTOS.HOMOLOGACION_PROD_SACC' THEN
                  sentencia := 'UPDATE ' ||
                               reg_homologaciones.tabla_homologada ||
                               ' SET ' || codigos_dest || ' = ''' ||
                               v_cod_homologa || '''' || sentencia7 ||
                               ' WHERE ' || codigos_fuente || ' = ''' ||
                               v_fuente || ''' AND ' || codigos_cod ||
                               ' = ''' || v_codigo || ''' AND ' ||
                               codigos_desc || ' = ''' || v_desc || '''' ||
                               sentencia2;
                  --
                ELSE
                  v_cont_errores := v_cont_errores + 1;
                  sentencia      := 'Homologación ya ingresada.';
                END IF;
              
              ELSIF v_comprueba_existentes IS NULL THEN
                v_cont_errores := v_cont_errores + 1;
                sentencia      := 'Error en la sentencia al verificar la existencia de la homologación.';
              END IF;
            
            END IF;
          
            -- Inserta estos registros y actualiza el estado en tabla original.
            BEGIN
            
              IF v_cont_errores > 0 THEN
                v_observacion := 'Registro: ' || v_contador || ' Código: ' ||
                                 v_codigo || ' - ' || sentencia;
                v_error       := 'ERR';
                v_accion      := 'REPROCESAR';
              ELSE
                v_observacion := 'Registro: ' || v_contador || ' Código: ' ||
                                 v_codigo || ' - OK.';
                v_error       := 'OK';
                v_accion      := NULL;
              END IF;
            
              EXECUTE IMMEDIATE (sentencia);
            
              UPDATE homologacion.homologaciones_cargue hc
                 SET hc.homologa_estado      = v_error,
                     hc.homologa_descripcion = hc.homologa_descripcion ||
                                               v_observacion,
                     hc.accion               = v_accion
               WHERE hc.rowid = reg_homologaciones.rowid;
            
              COMMIT;
            
            EXCEPTION
              WHEN OTHERS THEN
              
                IF v_cont_errores = 0 THEN
                  sentencia := '. Falló la inserción en la tabla: ' ||
                               reg_homologaciones.tabla_homologada ||
                               ' - Posible error de datos.';
                  v_error   := 'ERR';
                  v_accion  := 'REPROCESAR';
                ELSE
                  IF sentencia = 'Homologación ya ingresada.' AND
                     (reg_homologaciones.homologa_estado <> 'ERR' OR
                     reg_homologaciones.homologa_estado IS NULL) THEN
                    v_error  := 'OK';
                    v_accion := NULL;
                  ELSE
                    v_error  := 'ERR';
                    v_accion := 'REPROCESAR';
                  END IF;
                END IF;
              
                v_observacion := 'Registro: ' || v_contador || ' Código: ' ||
                                 v_codigo || ' ' || sentencia;
              
                UPDATE homologacion.homologaciones_cargue hc
                   SET hc.homologa_estado      = v_error,
                       hc.homologa_descripcion = hc.homologa_descripcion ||
                                                 v_observacion,
                       hc.accion               = v_accion
                 WHERE hc.rowid = reg_homologaciones.rowid;
              
                COMMIT;
            END;
          
          END LOOP;
        
          CLOSE reg_sentencia_cursor;
          ------------------------------------------------------------------------------------
          -- CASO 2.  No necesita buscar código en copias y tiene solo una descripción.
          -- Aca solo se ingresaría un registro y no se necesita cursor.
          ------------------------------------------------------------------------------------
        ELSIF reg_homologaciones.codigo1_fuente IS NOT NULL AND
              reg_homologaciones.codigo2_fuente IS NULL AND
              reg_homologaciones.tabla_codigos IS NULL THEN
        
          v_contador := v_contador + 1;
        
          IF reg_homologaciones.tabla_homologada IS NULL OR
             Upper(reg_homologaciones.tabla_homologada) = 'NO APLICA' THEN
            v_cont_errores := v_cont_errores + 1;
            sentencia      := 'No existe tabla de Homologación para este atributo.';
          
            -- PRODUCTOS 800, CNV, LDE tabla PRODUCTOS.HOMOLOGACION_PROD_SACC
          ELSIF Upper(reg_homologaciones.tabla_homologada) =
                'PRODUCTOS.HOMOLOGACION_PROD_SACC' THEN
          
            /*IF Upper(reg_homologaciones.atributo) = 'PLAN' THEN
              codigos_dest := 'hpl_cod_destino';
            ELSIF Upper(reg_homologaciones.atributo) = 'CUPO' OR
                  Upper(reg_homologaciones.atributo) =
                  'CUPO PARA PLAN VALOR UNICO' OR
                  Upper(reg_homologaciones.atributo) =
                  'CUPO PARA PLAN 7 SIN LIMITES' OR
                  Upper(reg_homologaciones.atributo) =
                  'CUPO PARA PLAN VALOR UNICO RESERVA' THEN
              codigos_dest := 'hcp_cod_destino';
            ELSIF Upper(reg_homologaciones.atributo) = 'TIPO' OR
                  Upper(reg_homologaciones.atributo) = 'PLAN - TIPO' THEN
              codigos_dest := 'htl_cod_destino';
            ELSIF Upper(reg_homologaciones.atributo) = 'FACTURACION' OR
                  Upper(reg_homologaciones.atributo) = 'FACTURACIÓN' OR
                  Upper(reg_homologaciones.atributo) = 'PLAN - FACTURACIÓN' OR
                  Upper(reg_homologaciones.atributo) = 'PLAN - FACTURACION' THEN
              codigos_dest := 'hpl_cod_destino_fact';
            ELSIF Upper(reg_homologaciones.atributo) = 'TIPO CONVENIO' OR
                  Upper(reg_homologaciones.atributo) = 'TIPO DE CONVENIO' OR
                  Upper(reg_homologaciones.atributo) = 'PLAN - TIPO CONVENIO' OR
                  Upper(reg_homologaciones.atributo) =
                  'PLAN - TIPO DE CONVENIO' THEN
              codigos_dest := 'htc_tipo_convenio';
            END IF;*/
          
            -- Se valida que no se haya ingresado ya esta homologación.
            consulta := 'SELECT COUNT(1) FROM ' ||
                        reg_homologaciones.tabla_homologada ||
                        ' WHERE Upper(' || codigos_fuente || ') = Upper(''' ||
                        reg_homologaciones.fuente || ''') AND Upper(' ||
                        codigos_cod || ') = Upper(''' ||
                        reg_homologaciones.codigo1_fuente ||
                        ''') AND Upper(' || codigos_desc || ') = Upper(''' ||
                        reg_homologaciones.descripcion_fuente || ''')';
          
            BEGIN
              EXECUTE IMMEDIATE consulta
                INTO v_comprueba_existentes;
            EXCEPTION
              WHEN OTHERS THEN
                v_comprueba_existentes := NULL;
            END;
          
            -- se arma sentencia que ingresa homologación o describe el error.
            IF v_comprueba_existentes = 0 THEN
            
              sentencia := 'INSERT INTO ' ||
                           reg_homologaciones.tabla_homologada || '(' ||
                           codigos_fuente || ',' || codigos_cod || ',' ||
                           codigos_desc || ',' || codigos_dest || ',' ||
                           codigos_producto || ',' || codigos_plant ||
                           sentencia_fecha || ') VALUES(''' ||
                           reg_homologaciones.fuente || ''',''' ||
                           reg_homologaciones.codigo1_fuente || ''',''' ||
                           reg_homologaciones.descripcion_fuente || ''',''' ||
                           reg_homologaciones.codigo_homologado || ''',''' ||
                           reg_homologaciones.objeto || ''',''' ||
                           reg_homologaciones.version_plantilla || '''' ||
                           sentencia_fecha2 || ')';
            
            ELSIF v_comprueba_existentes > 0 THEN
            
              -- Para retenciones, si ya existe lo actualiza con el codigo destino acordado
              sentencia := 'UPDATE ' || reg_homologaciones.tabla_homologada ||
                           ' SET ' || codigos_dest || ' = ''' ||
                           reg_homologaciones.codigo_homologado || '''
                           WHERE ' ||
                           codigos_fuente || ' = ''' ||
                           reg_homologaciones.fuente || ''' AND ' ||
                           codigos_cod || ' = ''' ||
                           reg_homologaciones.codigo1_fuente || ''' AND ' ||
                           codigos_desc || ' = ''' ||
                           reg_homologaciones.descripcion_fuente || '''';
            
            ELSIF v_comprueba_existentes IS NULL THEN
              v_cont_errores := v_cont_errores + 1;
              sentencia      := 'Error en la sentencia al verificar la existencia de la homologación.';
            END IF;
          
            -- Para este Objeto existen diferencias en formato del campo código.
          ELSIF Upper(reg_homologaciones.tabla_homologada) =
                'HOMOLOGACION.HOM_DEPTO' AND
                (Upper(reg_homologaciones.fuente) = 'DATAMUNDO' OR
                 Upper(reg_homologaciones.fuente) = 'SGS' OR
                 Upper(reg_homologaciones.fuente) = 'REGIS') THEN
          
            -- Se valida que no se haya ingresado ya esta homologación.
            consulta := 'SELECT COUNT(1) FROM ' ||
                        reg_homologaciones.tabla_homologada || ' WHERE ' ||
                        codigos_fuente || ' = ''' ||
                        reg_homologaciones.fuente || ''' AND ' ||
                        codigos_cod || ' = Lpad(''' ||
                        reg_homologaciones.codigo1_fuente ||
                        ''',2,''0'') AND ' || codigos_desc || ' = ''' ||
                        reg_homologaciones.descripcion_fuente || '''';
          
            BEGIN
              EXECUTE IMMEDIATE consulta
                INTO v_comprueba_existentes;
            EXCEPTION
              WHEN OTHERS THEN
                v_comprueba_existentes := NULL;
            END;
          
            -- se arma sentencia que ingresa homologación o describe el error.
            IF v_comprueba_existentes = 0 THEN
            
              sentencia := 'INSERT INTO ' ||
                           reg_homologaciones.tabla_homologada || '(' ||
                           codigos_fuente || ',' || codigos_cod || ',' ||
                           codigos_desc || ',' || codigos_dest || ',' ||
                           codigos_plant || sentencia_fecha ||
                           ') VALUES(''' || reg_homologaciones.fuente ||
                           ''', Lpad(''' ||
                           reg_homologaciones.codigo1_fuente ||
                           ''',2,''0''),''' ||
                           reg_homologaciones.descripcion_fuente || ''',''' ||
                           reg_homologaciones.codigo_homologado || ''',''' ||
                           reg_homologaciones.version_plantilla || '''' ||
                           sentencia_fecha2 || ')';
            
            ELSIF v_comprueba_existentes > 0 THEN
            
              -- Para retenciones, si ya existe lo actualiza con el codigo destino acordado
              IF Upper(p_accion) = 'RETENER' THEN
                sentencia := 'UPDATE ' ||
                             reg_homologaciones.tabla_homologada || ' SET ' ||
                             codigos_dest || ' = ' ||
                             reg_homologaciones.codigo_homologado || '
                           WHERE ' ||
                             codigos_fuente || ' = ''' ||
                             reg_homologaciones.fuente || ''' AND ' ||
                             codigos_cod || ' = ''' || 'Lpad(''' ||
                             reg_homologaciones.codigo1_fuente ||
                             ''',2,''0''),''' || ''' AND ' || codigos_desc ||
                             ' = ''' ||
                             reg_homologaciones.descripcion_fuente || '''';
                --
              ELSE
                v_cont_errores := v_cont_errores + 1;
                sentencia      := 'Homologación ya ingresada.';
              END IF;
            
            ELSIF v_comprueba_existentes IS NULL THEN
              v_cont_errores := v_cont_errores + 1;
              sentencia      := 'Error en la sentencia al verificar la existencia de la homologación.';
            END IF;
          
            -- Para este Objeto existen diferencias en formato del campo código.
          ELSIF Upper(reg_homologaciones.tabla_homologada) =
                'HOMOLOGACION.HOM_CIUDAD' AND
                Upper(reg_homologaciones.fuente) = 'SGS' THEN
          
            -- Se valida que no se haya ingresado ya esta homologación.
            consulta := 'SELECT COUNT(1) FROM ' ||
                        reg_homologaciones.tabla_homologada ||
                        ' WHERE Upper(' || codigos_fuente || ') = Upper(''' ||
                        reg_homologaciones.fuente || ''') AND Upper(' ||
                        codigos_cod || ') = Upper(' || 'Ltrim(''' ||
                        reg_homologaciones.codigo1_fuente || ''',''0'')' ||
                        ') AND Upper(' || codigos_desc || ') = Upper(''' ||
                        reg_homologaciones.descripcion_fuente || ''')';
          
            BEGIN
              EXECUTE IMMEDIATE consulta
                INTO v_comprueba_existentes;
            EXCEPTION
              WHEN OTHERS THEN
                v_comprueba_existentes := NULL;
            END;
          
            -- se arma sentencia que ingresa homologación o describe el error.
            IF v_comprueba_existentes = 0 THEN
            
              sentencia := 'INSERT INTO ' ||
                           reg_homologaciones.tabla_homologada || '(' ||
                           codigos_fuente || ',' || codigos_cod || ',' ||
                           codigos_desc || ',' || codigos_dest || ',' ||
                           codigos_plant || sentencia_fecha || ')' ||
                           ' VALUES(''' || reg_homologaciones.fuente ||
                           ''', Ltrim(''' ||
                           reg_homologaciones.codigo1_fuente ||
                           ''',''0''),''' ||
                           reg_homologaciones.descripcion_fuente || ''',''' ||
                           reg_homologaciones.codigo_homologado || ''',''' ||
                           reg_homologaciones.version_plantilla || '''' ||
                           sentencia_fecha2 || ')';
            
            ELSIF v_comprueba_existentes > 0 THEN
            
              -- Para retenciones, si ya existe lo actualiza con el codigo destino acordado
              IF Upper(p_accion) = 'RETENER' THEN
                sentencia := 'UPDATE ' ||
                             reg_homologaciones.tabla_homologada || ' SET ' ||
                             codigos_dest || ' = ' ||
                             reg_homologaciones.codigo_homologado || '
                           WHERE ' ||
                             codigos_fuente || ' = ''' ||
                             reg_homologaciones.fuente || ''' AND ' ||
                             codigos_cod || ' = ''' || 'Ltrim(''' ||
                             reg_homologaciones.codigo1_fuente ||
                             ''',''0''),''' || ''' AND ' || codigos_desc ||
                             ' = ''' ||
                             reg_homologaciones.descripcion_fuente || '''';
                --
              ELSE
                v_cont_errores := v_cont_errores + 1;
                sentencia      := 'Homologación ya ingresada.';
              END IF;
            
            ELSIF v_comprueba_existentes IS NULL THEN
              v_cont_errores := v_cont_errores + 1;
              sentencia      := 'Error en la sentencia al verificar la existencia de la homologación.';
            END IF;
          
          ELSE
            codigo_novacio  := ' = Upper(''' ||
                               reg_homologaciones.codigo1_fuente || ''') ';
            codigo_novacio2 := reg_homologaciones.codigo1_fuente;
          
            IF reg_homologaciones.tabla_homologada =
               'HOMOLOGACION.HOM_ENLACE_RDSI' THEN
              campo_fuente := reg_homologaciones.objeto;
            ELSE
              campo_fuente := reg_homologaciones.fuente;
            END IF;
          
            -- Tablas que no llenan cod_fuente y si desc_fuente
            IF Upper(reg_homologaciones.tabla_homologada) =
               'HOMOLOGACION.HOM_PERIODI_FACT' OR
               Upper(reg_homologaciones.tabla_homologada) =
               'HOMOLOGACION.HOM_TMPO_PERMANENCIA' OR
               Upper(reg_homologaciones.tabla_homologada) =
               'HOMOLOGACION.HOM_TRA_DET_FACTOR_MULT' OR
               Upper(reg_homologaciones.tabla_homologada) =
               'HOMOLOGACION.HOM_TRA_DET_MESES_FINAN' OR
               Upper(reg_homologaciones.tabla_homologada) =
               'HOMOLOGACION.HOM_TRA_DET_USOS' THEN
              codigo_novacio  := ' IS NULL ';
              codigo_novacio2 := NULL;
            END IF;
          
            IF reg_homologaciones.tabla_homologada =
               'HOMOLOGACION.HOM_BANDA_LDH' THEN
              campo_descripcion  := reg_homologaciones.codigo_homologado;
              campo_descripcion2 := reg_homologaciones.codigo_homologado;
            ELSE
              campo_descripcion  := reg_homologaciones.descripcion_fuente;
              campo_descripcion2 := reg_homologaciones.codigo1_fuente;
            END IF;
          
            IF reg_homologaciones.tabla_homologada =
               'HOMOLOGACION.HOM_MESES_FINAN' THEN
              reg_homologaciones.codigo1_fuente := NULL;
            END IF;
          
            -- Se valida que no se haya ingresado ya esta homologación.
            consulta := 'SELECT COUNT(1) FROM ' ||
                        reg_homologaciones.tabla_homologada ||
                        ' WHERE Upper(' || codigos_fuente || ') = Upper(''' ||
                        campo_fuente || ''') AND Upper(' || codigos_cod || ') ' ||
                        codigo_novacio || 'AND Upper(' || codigos_desc ||
                        ') = Upper(Nvl(''' || campo_descripcion || ''',''' ||
                        campo_descripcion2 || '''))' || sentencia2;
          
            BEGIN
              EXECUTE IMMEDIATE consulta
                INTO v_comprueba_existentes;
            EXCEPTION
              WHEN OTHERS THEN
                v_comprueba_existentes := NULL;
            END;
          
            -- se arma sentencia que ingresa homologación o describe el error.
            IF v_comprueba_existentes = 0 THEN
            
              sentencia := 'INSERT INTO ' ||
                           reg_homologaciones.tabla_homologada || '(' ||
                           codigos_fuente || ',' || codigos_cod || ',' ||
                           codigos_desc || ',' || codigos_dest || ',' ||
                           codigos_plant || sentencia3 || sentencia_fecha ||
                           sentencia5 || ')' || ' VALUES(''' ||
                           campo_fuente || ''',''' || codigo_novacio2 ||
                           ''',' || 'NVL(''' ||
                           reg_homologaciones.descripcion_fuente || ''',''' ||
                           campo_descripcion2 || ''')' || ',''' ||
                           reg_homologaciones.codigo_homologado || ''',''' ||
                           reg_homologaciones.version_plantilla || '''' ||
                           sentencia4 || sentencia_fecha2 || sentencia6 || ')';
            
            ELSIF v_comprueba_existentes > 0 THEN
            
              -- Para retenciones, si ya existe lo actualiza con el codigo destino acordado
              IF Upper(p_accion) = 'RETENER' THEN
                sentencia := 'UPDATE ' ||
                             reg_homologaciones.tabla_homologada || ' SET ' ||
                             codigos_dest || ' = ' ||
                             reg_homologaciones.codigo_homologado ||
                             sentencia7 || '
                           WHERE ' ||
                             codigos_fuente || ' = ''' ||
                             reg_homologaciones.fuente || ''' AND ' ||
                             codigos_cod || ' = ''' || codigo_novacio2 ||
                             ''' AND ' || codigos_desc || ' = ''' ||
                             reg_homologaciones.descripcion_fuente || '''';
                --
              ELSE
                v_cont_errores := v_cont_errores + 1;
                sentencia      := 'Homologación ya ingresada.';
              END IF;
            
            ELSIF v_comprueba_existentes IS NULL THEN
              v_cont_errores := v_cont_errores + 1;
              sentencia      := 'Error en la sentencia al verificar la existencia de la homologación.';
            END IF;
          
          END IF;
        
          -- Inserta estos registros y actualiza el estado en tabla original.
          BEGIN
          
            IF v_cont_errores > 0 THEN
              v_observacion := sentencia;
              v_error       := 'ERR';
              v_accion      := 'REPROCESAR';
            ELSE
              v_observacion := 'Registro - OK.';
              v_error       := 'OK';
              v_accion      := NULL;
            END IF;
          
            EXECUTE IMMEDIATE (sentencia);
          
            UPDATE homologacion.homologaciones_cargue hc
               SET hc.homologa_estado      = v_error,
                   hc.homologa_descripcion = v_observacion,
                   hc.accion               = v_accion
             WHERE hc.rowid = reg_homologaciones.rowid;
          
            COMMIT;
          
          EXCEPTION
            WHEN OTHERS THEN
            
              IF v_cont_errores = 0 THEN
                sentencia := '. Falló la inserción en la tabla: ' ||
                             reg_homologaciones.tabla_homologada ||
                             ' - Posible error de datos.';
              END IF;
            
              IF sentencia = 'Homologación ya ingresada.' THEN
                v_error  := 'OK';
                v_accion := NULL;
              ELSE
                v_error  := 'ERR';
                v_accion := 'REPROCESAR';
              END IF;
            
              UPDATE homologacion.homologaciones_cargue hc
                 SET hc.homologa_estado      = v_error,
                     hc.homologa_descripcion = v_observacion,
                     hc.accion               = v_accion
               WHERE hc.rowid = reg_homologaciones.rowid;
            
              COMMIT;
          END;
          ------------------------------------------------------------------------------------
          -- CASO 3.  Viene con dos códigos de la fuente.
          ------------------------------------------------------------------------------------
        ELSIF reg_homologaciones.codigo1_fuente IS NOT NULL AND
              reg_homologaciones.codigo2_fuente IS NOT NULL THEN
        
          v_contador := v_contador + 1;
        
          -- Datamundo concatena los codigos fuentes y los formatea para ingresar la homologación.
          IF Upper(reg_homologaciones.fuente) = 'DATAMUNDO' AND
             Upper(reg_homologaciones.tabla_homologada) =
             'HOMOLOGACION.HOM_CIUDAD' THEN
          
            -- Se valida que no se haya ingresado ya esta homologación.
            consulta := 'SELECT COUNT(1) FROM ' ||
                        reg_homologaciones.tabla_homologada ||
                        ' WHERE Upper(' || codigos_fuente || ') = Upper(''' ||
                        reg_homologaciones.fuente || ''') AND Upper(' ||
                        codigos_cod || ') = Upper(Lpad(''' ||
                        reg_homologaciones.codigo2_fuente ||
                        ''',2,''0'')|| Lpad(''' ||
                        reg_homologaciones.codigo1_fuente || ''',3,''0'')' ||
                        ') AND Upper(' || codigos_desc || ') = Upper(''' ||
                        reg_homologaciones.descripcion_fuente || ''')' ||
                        sentencia2;
          
            BEGIN
              EXECUTE IMMEDIATE consulta
                INTO v_comprueba_existentes;
            EXCEPTION
              WHEN OTHERS THEN
                v_comprueba_existentes := NULL;
            END;
          
            -- se arma sentencia que ingresa homologación o describe el error.
            IF v_comprueba_existentes = 0 THEN
            
              sentencia := 'INSERT INTO ' ||
                           reg_homologaciones.tabla_homologada || '(' ||
                           codigos_fuente || ',' || codigos_cod || ',' ||
                           codigos_desc || ',' || codigos_dest || ',' ||
                           codigos_plant || sentencia3 || sentencia_fecha ||
                           ') VALUES(''' || reg_homologaciones.fuente ||
                           ''', Lpad(''' ||
                           reg_homologaciones.codigo2_fuente ||
                           ''',2,''0'')|| Lpad(''' ||
                           reg_homologaciones.codigo1_fuente ||
                           ''',3,''0''),''' ||
                           reg_homologaciones.descripcion_fuente || ''',''' ||
                           reg_homologaciones.codigo_homologado || ''',''' ||
                           reg_homologaciones.version_plantilla || '''' ||
                           sentencia4 || sentencia_fecha2 || ')';
            
            ELSIF v_comprueba_existentes > 0 THEN
            
              -- Para retenciones, si ya existe lo actualiza con el codigo destino acordado
              IF Upper(p_accion) = 'RETENER' THEN
                sentencia := 'UPDATE ' ||
                             reg_homologaciones.tabla_homologada || ' SET ' ||
                             codigos_dest || ' = ' ||
                             reg_homologaciones.codigo_homologado || '
                           WHERE ' ||
                             codigos_fuente || ' = ''' ||
                             reg_homologaciones.fuente || ''' AND ' ||
                             codigos_cod || ' = Lpad(''' ||
                             reg_homologaciones.codigo2_fuente ||
                             ''',2,''0'')|| Lpad(''' ||
                             reg_homologaciones.codigo1_fuente ||
                             ''',3,''0'')' || ''' AND ' || codigos_desc ||
                             ' = ''' ||
                             reg_homologaciones.descripcion_fuente || '''';
                --
              ELSE
                v_cont_errores := v_cont_errores + 1;
                sentencia      := 'Homologación ya ingresada.';
              END IF;
            
            ELSIF v_comprueba_existentes IS NULL THEN
              v_cont_errores := v_cont_errores + 1;
              sentencia      := 'Error en la sentencia al verificar la existencia de la homologación.';
            END IF;
          
            BEGIN
            
              IF v_cont_errores > 0 THEN
                v_observacion := 'Registro: ' || v_contador || ' Código: ' ||
                                 v_codigo || ' - ' || sentencia;
                v_error       := 'ERR';
                v_accion      := 'REPROCESAR';
              ELSE
                v_observacion := 'Registro: ' || v_contador || ' Código: ' ||
                                 v_codigo || ' - OK.';
                v_error       := 'OK';
                v_accion      := NULL;
              END IF;
            
              EXECUTE IMMEDIATE (sentencia);
            
              UPDATE homologacion.homologaciones_cargue hc
                 SET hc.homologa_estado      = v_error,
                     hc.homologa_descripcion = hc.homologa_descripcion ||
                                               v_observacion,
                     hc.accion               = v_accion
               WHERE hc.rowid = reg_homologaciones.rowid;
            
              COMMIT;
            
            EXCEPTION
              WHEN OTHERS THEN
              
                IF v_cont_errores = 0 THEN
                  sentencia := '. Falló la inserción en la tabla: ' ||
                               reg_homologaciones.tabla_homologada ||
                               ' - Posible error de datos.';
                END IF;
              
                v_observacion := sentencia;
              
                IF sentencia = 'Homologación ya ingresada.' THEN
                  v_error  := 'OK';
                  v_accion := NULL;
                ELSE
                  v_error  := 'ERR';
                  v_accion := 'REPROCESAR';
                END IF;
              
                UPDATE homologacion.homologaciones_cargue hc
                   SET hc.homologa_estado      = v_error,
                       hc.homologa_descripcion = hc.homologa_descripcion ||
                                                 v_observacion,
                       hc.accion               = v_accion
                 WHERE hc.rowid = reg_homologaciones.rowid;
              
                COMMIT;
            END;
          
            -- Caso especial plan y tipo soporte Dr ETB
          ELSIF reg_homologaciones.tabla_homologada =
                'HOMOLOGACION.HOM_TIPO_SOPORTE' THEN
          
            codigos_cod   := 'hts_cod_plan_fte';
            codigos_cod2  := 'hts_cod_fuente';
            codigos_desc  := 'hts_desc_plan_fte';
            codigos_desc2 := 'hts_desc_fuente';
          
            IF Upper(reg_homologaciones.atributo) = 'PLAN' THEN
            
              codigos_dest      := 'hts_cod_plan_dest';
              codigos_dest_desc := NULL;
            
            ELSIF Upper(reg_homologaciones.atributo) = 'TIPO DE SOPORTE' THEN
            
              codigos_dest      := 'hts_cod_destino';
              codigos_dest_desc := ',' || 'hts_desc_destino';
              --valor_dest_desc   := ',' || v_cod_homologa;
            
            END IF;
          
            sentencia2 := ' AND ' || codigos_desc || ' = ''' ||
                          reg_homologaciones.codigo1_fuente || ''' AND ' ||
                          codigos_desc2 || ' = ''' ||
                          reg_homologaciones.codigo2_fuente || '''';
          
            sentencia3 := ', ' || codigos_cod || ', ' || codigos_desc || ', ' ||
                          codigos_cod2 || ', ' || codigos_desc2 || ', ' ||
                          codigos_dest || codigos_dest_desc;
          
            sentencia4 := ' Upper(TRIM(tc.' || codigos_desc ||
                          ')) = Upper(TRIM(''' ||
                          reg_homologaciones.codigo1_fuente ||
                          ''')) AND Upper(TRIM(tc.' || codigos_desc2 ||
                          ')) = Upper(TRIM(''' ||
                          reg_homologaciones.codigo2_fuente || '''))';
          
            sentencia_cursor := ' SELECT ''' || reg_homologaciones.fuente ||
                                ''', TO_CHAR(NVL(TO_CHAR(tc.' ||
                                codigos_cod ||
                                '),''ERROR'')), hc.codigo1_fuente, TO_CHAR(NVL(TO_CHAR(tc.' ||
                                codigos_cod2 ||
                                '),''ERROR'')), hc.codigo2_fuente, hc.codigo_homologado, hc.version_plantilla ' ||
                                ' FROM homologacion.homologaciones_cargue hc ' ||
                                ' LEFT OUTER JOIN ' ||
                                reg_homologaciones.tabla_codigos ||
                                ' tc ON ' || sentencia4 ||
                                ' AND Upper(hc.fuente) = Upper(' ||
                                codigos_fuente || ')' ||
                                '  WHERE hc.ROWID = ''' ||
                                reg_homologaciones.rowid || '''';
          
            OPEN reg_sentencia_cursor FOR sentencia_cursor;
          
            LOOP
            
              v_fuente               := NULL;
              v_codigo               := NULL;
              v_desc                 := NULL;
              v_cod_homologa         := NULL;
              v_plantilla            := NULL;
              v_comprueba_existentes := 0;
              v_contador             := v_contador + 1;
            
              BEGIN
                FETCH reg_sentencia_cursor
                  into v_fuente, v_codigo, v_desc, v_codigo2, v_desc2, v_cod_homologa, v_plantilla;
              EXCEPTION
                WHEN OTHERS THEN
                  v_codigo := 'ERROR-INSERT';
              END;
              EXIT WHEN reg_sentencia_cursor%NOTFOUND;
            
              IF v_codigo = 'ERROR' THEN
              
                v_cont_errores := v_cont_errores + 1;
                sentencia      := 'No se encontró código fuente con esa descripción.';
              
              ELSIF v_codigo = 'ERROR-INSERT' THEN
                v_cont_errores := v_cont_errores + 1;
                sentencia      := 'Falló la inserción en la tabla: ' ||
                                  reg_homologaciones.tabla_homologada ||
                                  ' - Posible error de datos.';
              
              ELSIF reg_homologaciones.tabla_homologada IS NULL OR
                    reg_homologaciones.tabla_homologada = 'NO APLICA' THEN
                v_cont_errores := v_cont_errores + 1;
                sentencia      := 'No existe tabla de Homologación para este atributo.';
              
              ELSE
              
                -- Se valida que no se haya ingresado ya esta homologación.
                consulta := 'SELECT COUNT(1) FROM ' ||
                            reg_homologaciones.tabla_homologada ||
                            ' WHERE Upper(' || codigos_fuente ||
                            ') = Upper(''' || reg_homologaciones.fuente ||
                            ''')' || sentencia2 || ' AND Upper(' ||
                            codigos_cod || ') = Upper(''' || v_codigo ||
                            ''') AND Upper(' || codigos_cod2 ||
                            ') = Upper(''' || v_codigo2 || ''')';
              
                BEGIN
                  EXECUTE IMMEDIATE consulta
                    INTO v_comprueba_existentes;
                EXCEPTION
                  WHEN OTHERS THEN
                    v_comprueba_existentes := NULL;
                END;
              
                IF Upper(reg_homologaciones.atributo) = 'TIPO DE SOPORTE' THEN
                  valor_dest_desc  := ''',''' || v_cod_homologa;
                  valor_dest_desc2 := '=NVL(''' || v_cod_homologa || '''' ||
                                      codigos_dest_desc || ')';
                ELSE
                  valor_dest_desc  := NULL;
                  valor_dest_desc2 := NULL;
                END IF;
              
                -- se arma sentencia que ingresa homologación o describe el error.
                IF v_comprueba_existentes = 0 THEN
                
                  sentencia := 'INSERT INTO ' ||
                               reg_homologaciones.tabla_homologada || '(' ||
                               codigos_fuente || sentencia3 || ', ' ||
                               codigos_plant || sentencia_fecha || ')' ||
                               ' VALUES(''' || v_fuente || ''',''' ||
                               v_codigo || ''',''' || v_desc || ''',''' ||
                               v_codigo2 || ''',''' || v_desc2 || ''',''' ||
                               v_cod_homologa || valor_dest_desc || ''',''' ||
                               v_plantilla || '''' || sentencia_fecha2 || ')';
                ELSIF v_comprueba_existentes > 0 THEN
                
                  -- Para retenciones, si ya existe lo actualiza con el codigo destino acordado
                
                  sentencia := 'UPDATE ' ||
                               reg_homologaciones.tabla_homologada ||
                               ' SET ' || codigos_dest || ' = ''' ||
                               v_cod_homologa || '''' || codigos_dest_desc ||
                               valor_dest_desc2 || ' WHERE ' ||
                               codigos_fuente || ' = ''' || v_fuente || '''' ||
                               sentencia2;
                
                ELSIF v_comprueba_existentes IS NULL THEN
                  v_cont_errores := v_cont_errores + 1;
                  sentencia      := 'Error en la sentencia al verificar la existencia de la homologación.';
                END IF;
              
              END IF;
            
              -- Inserta estos registros y actualiza el estado en tabla original.
              BEGIN
              
                IF v_cont_errores > 0 THEN
                  v_observacion := 'Registro: ' || v_contador ||
                                   ' Código: ' || v_codigo || ' - ' ||
                                   sentencia;
                  v_error       := 'ERR';
                  v_accion      := 'REPROCESAR';
                ELSE
                  v_observacion := 'Registro: ' || v_contador ||
                                   ' Código: ' || v_codigo || ' - OK.';
                  v_error       := 'OK';
                  v_accion      := NULL;
                END IF;
              
                EXECUTE IMMEDIATE (sentencia);
              
                UPDATE homologacion.homologaciones_cargue hc
                   SET hc.homologa_estado      = v_error,
                       hc.homologa_descripcion = hc.homologa_descripcion ||
                                                 v_observacion,
                       hc.accion               = v_accion
                 WHERE hc.rowid = reg_homologaciones.rowid;
              
                COMMIT;
              
              EXCEPTION
                WHEN OTHERS THEN
                
                  IF v_cont_errores = 0 THEN
                    sentencia := '. Falló la inserción en la tabla: ' ||
                                 reg_homologaciones.tabla_homologada ||
                                 ' - Posible error de datos.';
                  END IF;
                
                  v_observacion := sentencia;
                  IF sentencia = 'Homologación ya ingresada.' THEN
                    v_error  := 'OK';
                    v_accion := NULL;
                  ELSE
                    v_error  := 'ERR';
                    v_accion := 'REPROCESAR';
                  END IF;
                
                  UPDATE homologacion.homologaciones_cargue hc
                     SET hc.homologa_estado      = v_error,
                         hc.homologa_descripcion = hc.homologa_descripcion ||
                                                   v_observacion,
                         hc.accion               = v_accion
                   WHERE hc.rowid = reg_homologaciones.rowid;
                
                  COMMIT;
              END;
            
            END LOOP;
          
            CLOSE reg_sentencia_cursor;
            ---------------------
          
          ELSE
            -- Por si existe algún caso no contemplado.
            -- A la fecha estan contemplados todos los casao pero se deja abierta.
            NULL;
          END IF;
        
        END IF;
      
      END IF;
    
    END LOOP;
  
    COMMIT;
  
  END prc_cargue_homologacion;

  -------------------------------------------------------------------------------
  -- Genera:
  -- Reporte de comparación con conteos entre las tablas de
  -- homologaciones cargadas en depura versus las de prod.
  -- Genera reporte de resultados del proceso de Homologaciones.
  -------------------------------------------------------------------------------
  PROCEDURE prc_reporte_homologaciones IS
  
    CURSOR base IS
      SELECT tabla FROM migracion.tablas_homologacion ORDER BY 1;
  
    CURSOR tipologias_error IS
      select hc.homologa_descripcion tipologia, count(*) cantidad
        from homologacion.homologaciones_cargue hc
       WHERE hc.homologa_estado = 'ERR'
       group by hc.homologa_descripcion;
  
    CURSOR desc_tipologias(descripcion VARCHAR2) IS
      SELECT *
        FROM homologacion.homologaciones_cargue hc
       WHERE hc.homologa_descripcion = descripcion;
  
    TYPE CUR_TYP IS REF CURSOR;
    reg_cur_est         CUR_TYP;
    reglas              VARCHAR2(2000);
    sql_str             VARCHAR2(2000);
    sql_str2            VARCHAR2(2000);
    cantidad            VARCHAR2(50);
    cantidad2           VARCHAR2(50);
    conteo              NUMBER := 0;
    diferencia          VARCHAR2(50);
    fecha               VARCHAR2(16);
    total_registros     NUMBER;
    total_registros_ok  NUMBER;
    total_registros_err NUMBER;
    total_tipologias    NUMBER;
    cant                NUMBER := 0;
  
  BEGIN
    SELECT to_char(SYSDATE, '_ddmmyyyy') INTO fecha FROM DUAL;
  
    --Abre el archivo
    pkg_genera_excel.abre_excel('EXT_DIR_PRODUCTOS',
                                'Reporte_homologaciones' || fecha);
  
    -------------------------------------------------------------------------------------
    -- Pestaña con el reporte de conteos de comparación de Homologaciones depura vs prod
    -------------------------------------------------------------------------------------
    --Abre Hoja de trabajo y le asigna nombre
    pkg_genera_excel.abre_hoja('Conteos', 9);
  
    --Encabezado.  Nombres de fila
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('', 'TituloColumnas', 0, 'String');
    pkg_genera_excel.escribe_celda('TABLA', 'TituloColumnas', 0, 'String');
    pkg_genera_excel.escribe_celda('PROD', 'TituloColumnas', 0, 'String');
    pkg_genera_excel.escribe_celda('DEPURA', 'TituloColumnas', 0, 'String');
    pkg_genera_excel.escribe_celda('DIFERENCIA','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda('RESPONSABLE','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda('ESTADO', 'TituloColumnas', 0, 'String');
    pkg_genera_excel.escribe_celda('ACCION', 'TituloColumnas', 0, 'String');
    pkg_genera_excel.escribe_celda('DESCRIPCION','TituloColumnas',0,'String');
    pkg_genera_excel.cierra_fila;
  
    FOR reg_base IN base LOOP
      cantidad  := 0;
      cantidad2 := 0;
      conteo    := conteo + 1;
    
      -- Esto se debe ajustar cuando se ejecute desde prod........ por los dblink
      sql_str  := 'SELECT COUNT(1) FROM ' || reg_base.tabla;
      sql_str2 := 'SELECT COUNT(1) FROM ' || reg_base.tabla || '@prod';
    
      -- DEPURA
      BEGIN
        EXECUTE IMMEDIATE sql_str
          INTO cantidad;
      EXCEPTION
        WHEN OTHERS THEN
          cantidad := 'No existe';
      END;
      -- PROD
      BEGIN
        EXECUTE IMMEDIATE sql_str2
          INTO cantidad2;
      EXCEPTION
        WHEN OTHERS THEN
          cantidad2 := 'No existe';
      END;
    
      IF cantidad <> 'No existe' AND cantidad2 <> 'No existe' THEN
        diferencia := cantidad2 - cantidad;
      ELSE
        diferencia := 'Error';
      END IF;
    
      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda(conteo, 'Normal', 0, 'String');
      pkg_genera_excel.escribe_celda(reg_base.tabla, 'Normal', 0, 'String');
      pkg_genera_excel.escribe_celda(cantidad2, 'Normal', 0, 'String');
      pkg_genera_excel.escribe_celda(cantidad, 'Normal', 0, 'String');
      pkg_genera_excel.escribe_celda(diferencia, 'Normal', 0, 'String');
      pkg_genera_excel.escribe_celda('', 'Normal', 0, 'String');
      pkg_genera_excel.escribe_celda('', 'Normal', 0, 'String');
      pkg_genera_excel.escribe_celda('', 'Normal', 0, 'String');
      pkg_genera_excel.escribe_celda('', 'Normal', 0, 'String');
      pkg_genera_excel.cierra_fila;
    
    END LOOP;
  
    --Cierra hoja de trabajo
    pkg_genera_excel.cierra_hoja;
  
    -------------------------------------------------------------------------------------
    -- Pestaña con el reporte de resultados de Cargue de Homologaciones
    -------------------------------------------------------------------------------------
    --Abre Hoja de trabajo y le asigna nombre
    pkg_genera_excel.abre_hoja('Resultados General', 2);
    total_tipologias := 0;
  
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('', 'Normal', 1, 'String');
    pkg_genera_excel.cierra_fila;
  
    --Titulo
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('RESULTADOS PROCESO HOMOLOGACION','TituloColumnas',1,'String');
    pkg_genera_excel.cierra_fila;
  
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('', 'Normal', 1, 'String');
    pkg_genera_excel.cierra_fila;
  
    -- Cantidad total de registros
    BEGIN
      select count(1)
        INTO total_registros
        from homologacion.homologaciones_cargue hc;
    EXCEPTION
      WHEN OTHERS THEN
        total_registros := 0;
    END;
    -- Cantidad total de registros OK
    BEGIN
      select count(1)
        INTO total_registros_ok
        from homologacion.homologaciones_cargue hc
       WHERE hc.homologa_estado = 'OK';
    EXCEPTION
      WHEN OTHERS THEN
        total_registros_ok := 0;
    END;
    -- Catindad de registros con error
    total_registros_err := total_registros - total_registros_ok;
  
    --
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('Registros a Homologar','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda(total_registros,'TituloColumnasnumerico',0,'Number');
    pkg_genera_excel.cierra_fila;
    --
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('Homologados OK', 'Normal', 0, 'String');
    pkg_genera_excel.escribe_celda(total_registros_ok,'CampoNumero',0,'Number');
    pkg_genera_excel.cierra_fila;
    --
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('Fallas en homologación','Normal',0,'String');
    pkg_genera_excel.escribe_celda(total_registros_err,'CampoNumero',0,'Number');
    pkg_genera_excel.cierra_fila;
  
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('', 'Normal', 1, 'String');
    pkg_genera_excel.cierra_fila;
  
    -- Tipologías
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('Tipologías - Fallas en Homologación','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda('Cantidad','TituloColumnas',0,'String');
    pkg_genera_excel.cierra_fila;
  
    FOR reg_tipologias_err IN tipologias_error LOOP
    
      total_tipologias := total_tipologias + reg_tipologias_err.cantidad;
    
      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda(reg_tipologias_err.tipologia,'Normal',0,'String');
      pkg_genera_excel.escribe_celda(reg_tipologias_err.cantidad,'CampoNumero',0,'Number');
      pkg_genera_excel.cierra_fila;
    
    END LOOP;
    -- Totales
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('Total', 'TituloColumnas', 0, 'String');
    pkg_genera_excel.escribe_celda(total_tipologias,'TituloColumnasnumerico',0,'Number');
    pkg_genera_excel.cierra_fila;
  
    --Cierra hoja de trabajo
    pkg_genera_excel.cierra_hoja;
  
    -------------------------------------------------------------------------------------
    -- Pestañas de tipologías
    -------------------------------------------------------------------------------------
    FOR reg_tipologias_err IN tipologias_error LOOP    
    
    cant := cant + 1;
    
      --Abre Hoja de trabajo y le asigna nombre
      pkg_genera_excel.abre_hoja('Tipología ' || cant, 8);
    
      --Titulos
      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda('OBJETO','TituloColumnas',0,'String');
      pkg_genera_excel.escribe_celda('ATRIBUTO','TituloColumnas',0,'String');
      pkg_genera_excel.escribe_celda('FUENTE','TituloColumnas',0,'String');
      pkg_genera_excel.escribe_celda('CODIGO1_FUENTE','TituloColumnas',0,'String');
      pkg_genera_excel.escribe_celda('DESCRIPCION_FUENTE','TituloColumnas',0,'String');
      pkg_genera_excel.escribe_celda('CODIGO_HOMOLOGADO','TituloColumnas',0,'String');
      pkg_genera_excel.escribe_celda('TABLA_HOMOLOGADA','TituloColumnas',0,'String');
      pkg_genera_excel.escribe_celda('TABLA_CODIGOS','TituloColumnas',0,'String');
      pkg_genera_excel.cierra_fila;
    
      FOR reg_registros IN desc_tipologias(reg_tipologias_err.tipologia) LOOP
        pkg_genera_excel.abre_fila(13);
        pkg_genera_excel.escribe_celda(reg_registros.objeto,'Normal',0,'String');
        pkg_genera_excel.escribe_celda(reg_registros.atributo,'Normal',0,'String');
        pkg_genera_excel.escribe_celda(reg_registros.fuente,'Normal',0,'String');
        pkg_genera_excel.escribe_celda(reg_registros.codigo1_fuente,'Normal',0,'String');
        pkg_genera_excel.escribe_celda(reg_registros.descripcion_fuente,'Normal',0,'String');
        pkg_genera_excel.escribe_celda(reg_registros.codigo_homologado,'Normal',0,'String');
        pkg_genera_excel.escribe_celda(reg_registros.tabla_homologada,'Normal',0,'String');
        pkg_genera_excel.escribe_celda(reg_registros.tabla_codigos,'Normal',0,'String');
        pkg_genera_excel.cierra_fila;
        
      END LOOP;
      
      --Cierra hoja de trabajo
    pkg_genera_excel.cierra_hoja;
    
    END LOOP;    
    
    -- Cierra Archivo Excel
    pkg_genera_excel.cierra_excel;
  
  END prc_reporte_homologaciones;

END pkg_cargue_homologaciones;
/
