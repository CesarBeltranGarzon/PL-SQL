CREATE OR REPLACE PACKAGE pkg_reportes_automaticos IS
  ---------------------------------------------------------------------
  --  Autor:        Cesar Beltrán
  --  Fecha:        20-Agosto-2010
  --  Descripción:  Genera el reprote de Retenidos de la extracción y lo
  --                deja en el directorio EXT_DIR_PRODUCTOS
  --                Nombre archivo: Reporte_retenidos_INDRA+fecha.xml
  ---------------------------------------------------------------------
  PROCEDURE prc_reporte_general_retenidos;

END pkg_reportes_automaticos;
/
CREATE OR REPLACE PACKAGE BODY pkg_reportes_automaticos IS

  -------------------------------------------------------------------------------
  -- Procedimiento usado para escribir el reporte general de cada producto
  -- Es usado por el procedimiento principal prc_reporte_general_retenidos
  -------------------------------------------------------------------------------
  PROCEDURE pr_reporte_general(p_producto      in out Varchar2,
                               p_tabla         in Varchar2,
                               p_campo_flag    in Varchar2,
                               p_descripcion   in Varchar2,
                               p_campo_filtro  in Varchar2 DEFAULT null,
                               p_regla_negocio IN VARCHAR2,
                               p_suma_ret      IN OUT NUMBER) IS

    CURSOR cur_codigos(prod VARCHAR2) IS
      select cod_error, descripcion, tipo
        from migracion.validacion_datos
       where UPPER(producto) = prod
       order by 1;

    TYPE CUR_TYP         IS REF CURSOR;
    reg_cur_est          CUR_TYP;
    reglas               VARCHAR2(2000);
    sql_str              VARCHAR2(2000);
    d_regla              VARCHAR2(2000);
    d_cantidad           NUMBER;
    v_producto           VARCHAR2(12);
    tipo_est             VARCHAR2(12);
    fecha                VARCHAR2(9);
    nulo                 VARCHAR2(50);
    v_filtro             VARCHAR2(50);

  BEGIN

    IF upper(p_producto) = 'CLIEX' THEN
      v_producto := 'CLI';
    ELSIF upper(p_producto) = 'E1' THEN
      p_producto := 'EN1';
      v_producto := 'ENLACE_E1PRI';
    ELSIF upper(p_producto) = 'PRI' THEN
      v_producto := 'ENLACE_E1PRI';
    ELSE
      v_producto := upper(p_producto);
    END IF;

    IF Upper(p_producto) = 'LIB' OR Upper(p_producto) = 'PBX' OR Upper(p_producto) = 'BAB' OR Upper(p_producto) = 'BAR'
     OR Upper(p_producto) = 'LDH' OR Upper(p_producto) = 'IC' OR Upper(p_producto) = 'VIP' OR Upper(p_producto) = 'VISP'
     OR Upper(p_producto) = 'DTV' OR Upper(p_producto) = 'MCA' OR Upper(p_producto) = 'DOE' OR Upper(p_producto) = 'TEP'
     THEN
       nulo := ' OR ' || p_campo_flag || ' IS NULL ';
    ELSIF Upper(p_producto) = 'PROM' THEN
       nulo := ' AND descripcion_migrar IS NOT NULL ';
    ELSE
       nulo := NULL;
    END IF;

    /*IF Upper(p_producto) = 'E1' OR Upper(p_producto) = 'PRI' THEN
      v_filtro := p_campo_filtro || ' = ' || p_producto || ' AND ';
    ELSE
      v_filtro := NULL;
    END IF;*/

    IF p_campo_filtro is null THEN
      tipo_est := 'GENERAL';
      sql_str  := 'SELECT Nvl(' || p_descripcion || ',''Error de datos'') ,' ||
                  ' COUNT(1) FROM ' || p_tabla || ' WHERE (('||p_campo_flag ||
                  ' = ''N'' OR '||p_campo_flag ||' = ''0'')' || nulo || ') AND Nvl('||p_descripcion ||
                  ',''Error de datos'') NOT LIKE ''%' || p_regla_negocio || '%'' GROUP BY ' ||
                  p_descripcion ||
                  ' ORDER BY 2 DESC';
    ELSE
      tipo_est := 'FILTRADO';
      sql_str  := 'SELECT Nvl(' || p_descripcion || ',''Error de datos'') ,' ||
                  ' COUNT(1) FROM ' || p_tabla ||
                  ' WHERE ' || p_campo_filtro || ' = ''' || p_producto ||
                  ''' AND (('||p_campo_flag || ' = ''N'' OR '||p_campo_flag ||
                  ' = ''0'')' || nulo || ') AND Nvl('||p_descripcion || ',''Error de datos'') NOT LIKE ''%' ||
                  p_regla_negocio || '%'' GROUP BY ' || p_descripcion ||
                  ' order by 2 DESC';
    END IF;

    OPEN reg_cur_est FOR sql_str;

    LOOP
      reglas     := null;
      d_regla    := null;
      d_cantidad := null;


      FETCH reg_cur_est
      INTO d_regla, d_cantidad;

      EXIT WHEN reg_cur_est%NOTFOUND;

      FOR reg_cur_codigos IN cur_codigos(v_producto) LOOP
        IF d_regla like '%' || reg_cur_codigos.cod_error || '%' THEN
          reglas := reglas || '; ' || '(' || reg_cur_codigos.tipo || ')' || '-' ||
                    reg_cur_codigos.descripcion;
        END IF;
      END LOOP;

      IF reglas IS NULL THEN
        reglas := reglas || '; ' || 'Error de datos';
      END IF;

      p_suma_ret := p_suma_ret + d_cantidad;

      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda(reglas,'Normal',3,'String');
      pkg_genera_excel.escribe_celda(d_cantidad,'CampoNumero',0,'Number');
      pkg_genera_excel.cierra_fila;

    END LOOP;
    COMMIT;
  END pr_reporte_general;

  ---------------------------------------------------------------------------------
  -- Procedimiento usado para escribir el reporte por código de cada producto
  -- Es usado por el procedimiento principal prc_reporte_general_retenidos
  ---------------------------------------------------------------------------------
  PROCEDURE pr_reporte_codigos(p_producto     in out Varchar2,
                               p_tabla        in Varchar2,
                               p_campo_flag   in Varchar2,
                               p_descripcion  in Varchar2,
                               p_campo_filtro in varchar2 DEFAULT null,
                               p_regla_negocio IN VARCHAR2) is

    CURSOR cur_codigos(prod VARCHAR2) IS
      select cod_error, descripcion, tipo
        from migracion.validacion_datos
       where UPPER(producto) = prod
       order by 1;

    TYPE CUR_TYP IS REF CURSOR;
    reg_cur_est CUR_TYP;
    sql_str     VARCHAR2(2000);
    v_flag      VARCHAR2(1);
    v_producto  VARCHAR2(12);
    tipo_est    VARCHAR2(12);
    v_cant      number(10) := 0;
    v_campo     varchar2(50);
    nulo        VARCHAR2(50);

  BEGIN

    IF upper(p_producto) = 'CLIEX' THEN
      v_producto := 'CLI';
    ELSIF upper(p_producto) = 'E1' THEN
      p_producto := 'EN1';
      v_producto := 'ENLACE_E1PRI';
    ELSIF upper(p_producto) = 'PRI' THEN
      v_producto := 'ENLACE_E1PRI';
    ELSE
      v_producto := upper(p_producto);
    END IF;

    IF p_campo_filtro is null THEN
      tipo_est := 'GENERAL';
    ELSE
      tipo_est := 'FILTRADO';
    END IF;

    IF Upper(p_producto) = 'LIB' OR Upper(p_producto) = 'PBX' OR Upper(p_producto) = 'BAB' OR Upper(p_producto) = 'BAR'
     OR Upper(p_producto) = 'LDH' OR Upper(p_producto) = 'IC' OR Upper(p_producto) = 'VIP' OR Upper(p_producto) = 'VISP'
     OR Upper(p_producto) = 'DTV' OR Upper(p_producto) = 'MCA' OR Upper(p_producto) = 'DOE' OR Upper(p_producto) = 'TEP'
     THEN
       nulo := ' OR ' || p_campo_flag || ' IS NULL ';
    ELSIF Upper(p_producto) = 'PROM' THEN
       nulo := ' AND descripcion_migrar IS NOT NULL ';
    ELSE
       nulo := NULL;
    END IF;

    FOR reg_cur_codigos IN cur_codigos(v_producto) LOOP

      IF p_campo_filtro is null THEN
        tipo_est := 'GENERAL';
        sql_str  := 'Select count (1) From ' || p_tabla || ' Where ' ||
                    p_descripcion || ' like ' || chr(39) || '%' || chr(39) || '||' ||
                    chr(39) || reg_cur_codigos.cod_error || chr(39) || '||' ||
                    chr(39) || '%' || chr(39) || ' AND (('|| p_campo_flag ||
                    ' = ''N'' OR '||p_campo_flag ||' = ''0'')' || nulo || ') AND '||p_descripcion ||
                    ' NOT LIKE ''%' || p_regla_negocio || '%''';
      ELSE
        tipo_est := 'FILTRADO';
        sql_str  := 'Select count (1) From ' || p_tabla || ' Where ' ||
                    p_campo_filtro || ' = ''' || p_producto || ''' AND ' ||
                    p_descripcion || ' like ' || chr(39) || '%' || chr(39) || '||' ||
                    chr(39) || reg_cur_codigos.cod_error || chr(39) || '||' ||
                    chr(39) || '%' || chr(39) || ' AND (('|| p_campo_flag ||
                    ' = ''N'' OR '||p_campo_flag ||' = ''0'')' || nulo || ') AND '||p_descripcion ||
                    ' NOT LIKE ''%' || p_regla_negocio || '%''';
      END IF;
      OPEN reg_cur_est FOR sql_str;
      LOOP

        FETCH reg_cur_est
        INTO v_cant;

        EXIT WHEN reg_cur_est%NOTFOUND;

        IF v_cant > 0 THEN

          pkg_genera_excel.abre_fila(13);
          pkg_genera_excel.escribe_celda(reg_cur_codigos.descripcion,'Normal',2,'String');
          pkg_genera_excel.escribe_celda(reg_cur_codigos.tipo,'Normal',0,'String');
          pkg_genera_excel.escribe_celda(v_cant,'CampoNumero',0,'Number');
          pkg_genera_excel.cierra_fila;

        End If;

      END LOOP;

    end loop;
  end pr_reporte_codigos;

  ---------------------------------------------------------------------------------
  -- Procedimiento usado para escribir el reporte por código de cada producto
  -- Es usado por el procedimiento principal prc_reporte_general_retenidos
  ---------------------------------------------------------------------------------
  PROCEDURE pr_reporte_codigos_det(p_producto      IN OUT VARCHAR2,
                                   p_tabla         IN VARCHAR2,
                                   p_campo_flag    IN VARCHAR2,
                                   p_descripcion   IN VARCHAR2,
                                   p_campo_filtro  IN VARCHAR2 DEFAULT NULL,
                                   p_regla_negocio IN VARCHAR2) IS
    CURSOR cur_codigos(prod VARCHAR2) IS
      select cod_error, descripcion, tipo
        from migracion.validacion_datos
       where UPPER(producto) = prod
       order by 1;
    TYPE CUR_TYP IS REF CURSOR;
    reg_cur_est CUR_TYP;
    sql_str     VARCHAR2(2000);
    v_flag      VARCHAR2(1);
    v_producto  VARCHAR2(12);
    tipo_est    VARCHAR2(12);
    v_cant      VARCHAR2(2000);
    v_campo     varchar2(50);
    nulo        VARCHAR2(50);
    v_file      UTL_FILE.FILE_TYPE;
    v_archivo   VARCHAR2(200);
    v_fecha     VARCHAR2(10) := TO_CHAR(SYSDATE,'YYYYMMDD');
    l_sw        NUMBER := 0;  
  BEGIN
    IF upper(p_producto) = 'CLIEX' THEN
      v_producto := 'CLI';
    ELSIF upper(p_producto) = 'E1' THEN
      p_producto := 'EN1';
      v_producto := 'ENLACE_E1PRI';
    ELSIF upper(p_producto) = 'PRI' THEN
      v_producto := 'ENLACE_E1PRI';
    ELSE
      v_producto := upper(p_producto);
    END IF;
    IF p_campo_filtro is null THEN
      tipo_est := 'GENERAL';
    ELSE
      tipo_est := 'FILTRADO';
    END IF;
    IF Upper(p_producto) = 'LIB' OR Upper(p_producto) = 'PBX' OR Upper(p_producto) = 'BAB' OR Upper(p_producto) = 'BAR'
     OR Upper(p_producto) = 'LDH' OR Upper(p_producto) = 'IC' OR Upper(p_producto) = 'VIP' OR Upper(p_producto) = 'VISP'
     OR Upper(p_producto) = 'DTV' OR Upper(p_producto) = 'MCA' OR Upper(p_producto) = 'DOE' OR Upper(p_producto) = 'TEP'
     THEN
       nulo := ' OR ' || p_campo_flag || ' IS NULL ';
    ELSIF Upper(p_producto) = 'PROM' THEN
       nulo := ' AND descripcion_migrar IS NOT NULL ';
    ELSE
       nulo := NULL;
    END IF;
    FOR reg_cur_codigos IN cur_codigos(v_producto) LOOP
      IF p_campo_filtro is null THEN
         tipo_est := 'GENERAL';
         sql_str  := 'Select id_migracion||'||chr(39)||';'||chr(39)||'||'||p_campo_flag||' From ' || p_tabla || ' Where ' ||
                     p_descripcion || ' like ' || chr(39) || '%' || chr(39) || '||' ||
                     chr(39) || reg_cur_codigos.cod_error || chr(39) || '||' ||
                     chr(39) || '%' || chr(39) || ' AND '||p_descripcion ||
                     ' IS NOT NULL';
      ELSE
        tipo_est := 'FILTRADO';
        sql_str  := 'Select id_migracion||'||chr(39)||';'||chr(39)||'||'||p_campo_flag||' From '  || p_tabla || ' Where ' ||
                    p_campo_filtro || ' = ''' || p_producto || ''' AND ' ||
                    p_descripcion || ' like ' || chr(39) || '%' || chr(39) || '||' ||
                    chr(39) || reg_cur_codigos.cod_error || chr(39) || '||' ||
                    chr(39) || '%' || chr(39) || ' AND '||p_descripcion ||
                    ' IS NOT NULL';
      END IF;
      ------------------------------------------
      --    dbms_output.put_line(sql_str);    --
      ------------------------------------------
      OPEN reg_cur_est FOR sql_str;
--    v_file := UTL_FILE.FOPEN ('EXT_DIR_PRODUCTOS',p_producto||'-'||reg_cur_codigos.cod_error||'-'||v_fecha,'W');
      l_sw := 0;
      LOOP
        FETCH reg_cur_est
        INTO v_cant;              
        EXIT WHEN reg_cur_est%NOTFOUND;
          IF l_sw = 0 THEN
             v_file := UTL_FILE.FOPEN ('EXT_DIR_PRODUCTOS',p_producto||'-'||reg_cur_codigos.cod_error||'-'||v_fecha,'W');          
             l_sw := 1;
          END IF;          
          UTL_FILE.PUT_LINE (v_file,v_cant);         
      END LOOP;
      IF l_sw = 1 THEN    
         UTL_FILE.FCLOSE(v_file);
      END IF;            
    END LOOP;      
  END pr_reporte_codigos_det;  
  -------------------------------------------------------------------------------
  -- PROCEDIMIENTO PRINCIPAL DE GENERACION REPORTE DE RETENIDOS
  -------------------------------------------------------------------------------
  PROCEDURE prc_reporte_general_retenidos IS
    CURSOR direcciones IS
    SELECT 'DIRECCIONES' objeto,
         (SELECT COUNT(1)
            FROM integracion.direcciones) cantidad,
         (SELECT COUNT(1)
            FROM integracion.direcciones
           WHERE descri_regla like '%|037%'
             and flag_ENVIAR = 'N') negocio,
         (SELECT COUNT(1)
            FROM integracion.direcciones
           WHERE descri_regla NOT LIKE '%|037%'
             and flag_ENVIAR = 'N') retenciones,
         (SELECT COUNT(1)
            FROM integracion.direcciones
           WHERE flag_ENVIAR IS NULL) entregados,
         NULL observaciones
    FROM dual;

CURSOR clientes IS
SELECT 'CLIENTES' objeto,
       (SELECT COUNT(1)
          FROM integracion.clientes) cantidad,
       (SELECT COUNT(1)
          FROM integracion.clientes
         WHERE descri_regla like '%|074%'
           and flag_ENVIAR = 'N') negocio,
       (SELECT COUNT(1)
          FROM integracion.clientes
         WHERE descri_regla NOT LIKE '%|074%'
           and flag_ENVIAR = 'N') retenciones,
       (SELECT COUNT(1)
          FROM integracion.clientes
         WHERE flag_ENVIAR IS NULL) entregados,
       NULL observaciones
  FROM dual;

CURSOR cuentas IS
SELECT 'CUENTAS' objeto,
       (SELECT COUNT(1)
          FROM homologacion.hom_cuentas_enlace enl) cantidad,
       ((SELECT COUNT(1) FROM homologacion.hom_cuentas_enlace enl) -
                    (SELECT SUM(a.cuentas)
                       FROM (SELECT COUNT(1) cuentas
                               FROM integracion.cuentas
                             UNION
                             SELECT COUNT(1) cuentas
                               FROM integracion.cuentas_hijas) a)) negocio,
       (SELECT SUM(a.retenidos)
          FROM (Select count(1) retenidos
                  From integracion.cuentas
                 where flag_enviar = '0'
                UNION
                Select count(1) retenidos
                  From integracion.cuentas_hijas
                 where flag_enviar = '0') a) retenciones,
       (SELECT SUM(a.cuentas)
          FROM (SELECT COUNT(1) cuentas
                  FROM integracion.cuentas
                 where flag_enviar = '1'
                UNION
                SELECT COUNT(1) cuentas
                  FROM integracion.cuentas_hijas
                 where flag_enviar = '1') a) entregados,
       NULL observaciones
  FROM dual;

  CURSOR contactos IS
  SELECT 'CONTACTOS' objeto,
       (SELECT COUNT(1)
          FROM integracion.contactos) cantidad,
       (SELECT COUNT(1)
          FROM integracion.contactos
         WHERE descripcion_migrar like '%001%') negocio,
       (SELECT COUNT(1)
          FROM integracion.contactos
         WHERE descripcion_migrar not like '%001%'
           AND descripcion_migrar IS NOT NULL
           AND flag_migrar = 'N') retenciones,
       (SELECT COUNT(1)
          FROM integracion.contactos
         WHERE flag_migrar = 'S') entregados,
       NULL observaciones
  FROM dual;


  CURSOR productos IS
  SELECT 'LINEA BASICA' objeto,
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = '142') cantidad,
       '0' negocio,
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_lib
           WHERE flag_enviar IN ('N','V')
           OR flag_enviar IS NULL) +
         ((SELECT COUNT(1)
             FROM migracion.crm_tabla_maestro tm
             WHERE tm.servicio_id = '142') -
           (SELECT COUNT(1) FROM homologacion.hom_prod_lib))) retenciones,
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_lib
         WHERE flag_enviar = 'S') entregados,
       NULL observaciones
  FROM dual
  UNION ALL
  SELECT 'PBX',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = '206'),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_pbx
           WHERE flag_enviar = 'N'
           OR flag_enviar IS NULL) +
         ((SELECT COUNT(1)
             FROM migracion.crm_tabla_maestro tm
             WHERE tm.servicio_id = '206') -
          (SELECT COUNT(1) FROM homologacion.hom_prod_pbx))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_pbx
         WHERE flag_enviar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Larga Dist.Hogares' objeto,
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id in (442, 10183)) cantidad,
       '0' negocio,
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_ldh
           WHERE flag_enviar = 'N'
           OR flag_enviar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id in (442, 10183)) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_ldh))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_ldh
         WHERE flag_enviar = 'S') entregados,
       NULL observaciones
  FROM dual
  UNION ALL
  SELECT 'Banda Ancha Bogotá',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = 282),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_bab
           WHERE flag_enviar = 'N'
           OR flag_enviar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id = 282) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_bab))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_bab
         WHERE flag_enviar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Banda Ancha Regional',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = 16000),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_bar
           WHERE flag_enviar = 'N'
           OR flag_enviar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id = 16000) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_bar))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_bar
         WHERE flag_enviar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Internet Conmutado',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id IN
               (10370, 10371, 10372, 10365, 10367, 10369, 14500, 17)),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_ic
           WHERE flag_migrar = 'N'
           OR flag_migrar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id IN (10370, 10371, 10372, 10365,
              10367, 10369, 14500, 17)) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_ic))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_ic
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Voz IP',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = 10444),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_vip
           WHERE flag_migrar = 'N'
           OR flag_migrar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id = 10444) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_vip))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_vip
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'VISP',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = 15000),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_visp
           WHERE flag_migrar = 'N'
           OR flag_migrar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id = 15000) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_visp))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_visp
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'DirecTV',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = 100),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_dir
           WHERE flag_enviar = 'N'
           OR flag_enviar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id = 100) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_dir))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_dir
         WHERE flag_enviar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'McAfee',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = 18000),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_mca
           WHERE flag_migrar = 'N'
           OR flag_migrar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id = 18000) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_mca))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_mca
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Doctor ETB',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id =19000),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_doe
           WHERE flag_migrar = 'N'
           OR flag_migrar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id =19000) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_doe))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_doe
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'BUV',
       (SELECT COUNT(1)
        FROM productos.buzon_virtual),
       '0',
       (SELECT COUNT(1)
        FROM homologacion.hom_prod_buv
        WHERE flag_enviar = 'N'),
       (SELECT COUNT(1)
        FROM homologacion.hom_prod_buv
        WHERE flag_enviar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Telefonia Publica',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = 208),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_tep
           WHERE flag_migrar = 'N'
           OR flag_migrar IS NULL) +
        ((SELECT COUNT(1)
            FROM migracion.crm_tabla_maestro tm
            WHERE tm.servicio_id = 208) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_tep))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_tep
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT '18000' objeto,
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_800) cantidad,
       '0' negocio,
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_800
         WHERE flag_migrar = 'N') retenciones,
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_800
         WHERE flag_migrar = 'S') entregados,
       NULL observaciones
  FROM dual
  UNION ALL
  SELECT '900',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_900),
       '0',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_900
         WHERE flag_migrar = 'N'),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_900
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'RDSI BRI',
       (SELECT COUNT(1)
          FROM homologacion.Enlace_Rdsi_Bri),
       '0',
       (SELECT COUNT(1)
          FROM homologacion.Enlace_Rdsi_Bri
         WHERE flag_migrar = 'N'),
       (SELECT COUNT(1)
          FROM homologacion.Enlace_Rdsi_Bri
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Tarjeta Postpago',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_tar),
       '0',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_tar
         WHERE flag_migrar = 'N'),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_tar
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Larga Distancia Empresas',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_lde),
       '0',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_lde
         WHERE flag_migrar = 'N'),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_lde
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'RDSI PRI',
       (SELECT COUNT(1)
          FROM homologacion.Enlace_Rdsi_E1pri
          WHERE producto='PRI'),
       '0',
       (SELECT COUNT(1)
          FROM homologacion.Enlace_Rdsi_E1pri
         WHERE flag_migrar = 'N'
         AND producto='PRI'),
       (SELECT COUNT(1)
          FROM homologacion.Enlace_Rdsi_E1pri
         WHERE flag_migrar = 'S'
         AND producto='PRI'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Citofonia Virtual',
       (SELECT COUNT(1)
          FROM migracion.crm_tabla_maestro tm
         WHERE tm.servicio_id = 1426),
       '0',
       ((SELECT COUNT(1)
           FROM homologacion.hom_prod_ctv
           WHERE flag_migrar = 'N') +
        ((SELECT COUNT(1)
             FROM migracion.crm_tabla_maestro tm
             WHERE tm.servicio_id = 1426) -
         (SELECT COUNT(1) FROM homologacion.hom_prod_ctv))),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_ctv
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'E1',
       (SELECT COUNT(1)
          FROM homologacion.Enlace_Rdsi_E1pri
          WHERE producto='EN1'),
       '0',
       (SELECT COUNT(1)
          FROM homologacion.Enlace_Rdsi_E1pri
         WHERE flag_migrar = 'N'
         AND producto='EN1'),
       (SELECT COUNT(1)
          FROM homologacion.Enlace_Rdsi_E1pri
         WHERE flag_migrar = 'S'
         AND producto='EN1'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Eventos Futuros',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_evf),
       '0',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_evf
         WHERE flag_migrar = 'N'),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_evf
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT 'Convenios',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_cnv),
       '0',
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_cnv
         WHERE flag_mig_cnv = 'N'),
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_cnv
         WHERE flag_mig_cnv = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT '800ANU' objeto,
       (SELECT COUNT(1)
          FROM productos.rel_800anu) cantidad,
       '0' negocio,
       (SELECT COUNT(1)
          FROM productos.rel_800anu
         WHERE flag_migrar = 'N') retenciones,
       (SELECT COUNT(1)
          FROM productos.rel_800anu
         WHERE flag_migrar = 'S') entregados,
       NULL observaciones
  FROM dual
  UNION ALL
  SELECT '800CEN',
       (SELECT COUNT(1)
          FROM productos.rel_800cen),
       '0',
       (SELECT COUNT(1)
          FROM productos.rel_800cen
         WHERE flag_migrar = 'N'),
       (SELECT COUNT(1)
          FROM productos.rel_800cen
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT '800LIN',
       (SELECT COUNT(1)
          FROM productos.rel_800lin),
       '0',
       (SELECT COUNT(1)
          FROM productos.rel_800lin
         WHERE flag_migrar = 'N'),
       (SELECT COUNT(1)
          FROM productos.rel_800lin
         WHERE flag_migrar = 'S'),
       NULL
  FROM dual
  UNION ALL
  SELECT '800ENR' ,
       (SELECT COUNT(1)
          FROM productos.rel_800enr) ,
       '0' ,
       (SELECT COUNT(1)
          FROM productos.rel_800enr
         WHERE flag_migrar = 'N') ,
       (SELECT COUNT(1)
          FROM productos.rel_800enr
         WHERE flag_migrar = 'S') ,
       NULL
  FROM dual;

  CURSOR promociones IS
  SELECT 'Promociones' objeto,
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_promo) cantidad,
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_promo
         WHERE flag_migrar = 'N'
           AND descripcion_migrar IS NULL) negocio,
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_promo
         WHERE flag_migrar = 'N'
           AND descripcion_migrar IS NOT NULL) retenciones,
       (SELECT COUNT(1)
          FROM homologacion.hom_prod_promo
         WHERE flag_migrar = 'S') entregados,
       NULL observaciones
  FROM dual;

  CURSOR parametros IS
   SELECT tabla_final tabla, tabla_final2 tabla2, objeto, campo_flag flag, campo_descripcion descripcion, filtro,
     tabla_base, servicio_id
   FROM migracion.parametros_estadisticas
   order by id;

    fecha                       VARCHAR2(16);
    v_cant_migrar               NUMBER;
    v_suma_fuente               NUMBER := 0;
    v_suma_negocio              NUMBER := 0;
    v_suma_migrar               NUMBER := 0;
    v_suma_retenidos            NUMBER := 0;
    v_suma_entregados           NUMBER := 0;
    v_rete_inter                NUMBER;
    v_continua                  NUMBER;
    v_pestana                   VARCHAR2(20);
    v_reglaNegocio              VARCHAR2(60);
    v_sentencia                 VARCHAR2(250);
    v_quedados_entre_tablas     NUMBER;
    v_sum_ret                   NUMBER;

  BEGIN
    SELECT to_char(SYSDATE, '_ddmmyyyyHH24MISS') INTO fecha FROM DUAL;
    --Abre el archivo
    pkg_genera_excel.abre_excel('EXT_DIR_PRODUCTOS','Reporte_retenidos_INDRA'||fecha);

    -----------------------------------------------------------------------
    --               REPORTE GENERAL - HOJA 1
    -----------------------------------------------------------------------
    --Abre Hoja de trabajo y le asigna nombre
    pkg_genera_excel.abre_hoja('General', 7);

    -- Titulo Hoja
    pkg_genera_excel.abre_fila(45);
    pkg_genera_excel.escribe_celda('ETB', 'Logo', 0, 'String');
    pkg_genera_excel.escribe_celda('REPORTE ENTREGA A INDRA','TituloHoja',4,'String');
    pkg_genera_excel.escribe_celda('TCS', 'Logo', 0, 'String');
    pkg_genera_excel.cierra_fila;
    -- fila en blanco
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('', 'Normal', 6, 'String');
    pkg_genera_excel.cierra_fila;

    --Encabezado.  Nombres de fila
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('Objeto','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda('# Reg Fuente','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda('No migrados por Reglas de Negocio','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda('Registros a Migrar','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda('Retenidos por Reglas validacion','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda('# Registros','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda('Observaciones','TituloColumnas',0,'String');
    pkg_genera_excel.cierra_fila;

    -------------------------------
    -- Objetos
    -------------------------------
    --Direcciones
    FOR reg_direcciones IN direcciones LOOP
    v_cant_migrar := 0;
    v_cant_migrar := reg_direcciones.cantidad-reg_direcciones.negocio;
    v_suma_fuente := v_suma_fuente + reg_direcciones.cantidad;
    v_suma_negocio := v_suma_negocio + reg_direcciones.negocio;
    v_suma_migrar := v_suma_migrar + v_cant_migrar;
    v_suma_retenidos := v_suma_retenidos + reg_direcciones.retenciones;
    v_suma_entregados := v_suma_entregados + reg_direcciones.entregados;

      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda(reg_direcciones.objeto,'Normal',0,'String');
      pkg_genera_excel.escribe_celda(reg_direcciones.cantidad,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_direcciones.negocio,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(v_cant_migrar,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_direcciones.retenciones,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_direcciones.entregados,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_direcciones.observaciones, 'Normal', 0, 'String');
      pkg_genera_excel.cierra_fila;

    END LOOP;
    --Clientes
    FOR reg_clientes IN clientes LOOP
    v_cant_migrar := 0;
    v_cant_migrar := reg_clientes.cantidad-reg_clientes.negocio;
    v_suma_fuente := v_suma_fuente + reg_clientes.cantidad;
    v_suma_negocio := v_suma_negocio + reg_clientes.negocio;
    v_suma_migrar := v_suma_migrar + v_cant_migrar;
    v_suma_retenidos := v_suma_retenidos + reg_clientes.retenciones;
    v_suma_entregados := v_suma_entregados + reg_clientes.entregados;

      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda(reg_clientes.objeto,'Normal',0,'String');
      pkg_genera_excel.escribe_celda(reg_clientes.cantidad,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_clientes.negocio,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(v_cant_migrar,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_clientes.retenciones,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_clientes.entregados,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_clientes.observaciones, 'Normal', 0, 'String');
      pkg_genera_excel.cierra_fila;

    END LOOP;
    --Cuentas
    FOR reg_cuentas IN cuentas LOOP
    v_cant_migrar := 0;
    v_cant_migrar := reg_cuentas.cantidad-reg_cuentas.negocio;
    v_suma_fuente := v_suma_fuente + reg_cuentas.cantidad;
    v_suma_negocio := v_suma_negocio + reg_cuentas.negocio;
    v_suma_migrar := v_suma_migrar + v_cant_migrar;
    v_suma_retenidos := v_suma_retenidos + reg_cuentas.retenciones;
    v_suma_entregados := v_suma_entregados + reg_cuentas.entregados;

      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda(reg_cuentas.objeto,'Normal',0,'String');
      pkg_genera_excel.escribe_celda(reg_cuentas.cantidad,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_cuentas.negocio,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(v_cant_migrar,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_cuentas.retenciones,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_cuentas.entregados,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_cuentas.observaciones, 'Normal', 0, 'String');
      pkg_genera_excel.cierra_fila;

    END LOOP;
    --Contactos
    FOR reg_contactos IN contactos LOOP
    v_cant_migrar := 0;
    v_cant_migrar := reg_contactos.cantidad-reg_contactos.negocio;
    v_suma_fuente := v_suma_fuente + reg_contactos.cantidad;
    v_suma_negocio := v_suma_negocio + reg_contactos.negocio;
    v_suma_migrar := v_suma_migrar + v_cant_migrar;
    v_suma_retenidos := v_suma_retenidos + reg_contactos.retenciones;
    v_suma_entregados := v_suma_entregados + reg_contactos.entregados;

      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda(reg_contactos.objeto,'Normal',0,'String');
      pkg_genera_excel.escribe_celda(reg_contactos.cantidad,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_contactos.negocio,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(v_cant_migrar,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_contactos.retenciones,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_contactos.entregados,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_contactos.observaciones, 'Normal', 0, 'String');
      pkg_genera_excel.cierra_fila;

    END LOOP;
    --Productos
    FOR reg_productos IN productos LOOP
    v_cant_migrar := 0;
    v_cant_migrar := reg_productos.cantidad-reg_productos.negocio;
    v_suma_fuente := v_suma_fuente + reg_productos.cantidad;
    v_suma_negocio := v_suma_negocio + reg_productos.negocio;
    v_suma_migrar := v_suma_migrar + v_cant_migrar;
    v_suma_retenidos := v_suma_retenidos + reg_productos.retenciones;
    v_suma_entregados := v_suma_entregados + reg_productos.entregados;

      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda(reg_productos.objeto,'Normal',0,'String');
      pkg_genera_excel.escribe_celda(reg_productos.cantidad,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_productos.negocio,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(v_cant_migrar,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_productos.retenciones,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_productos.entregados,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_productos.observaciones, 'Normal', 0, 'String');
      pkg_genera_excel.cierra_fila;

    END LOOP;
    --Promociones
    FOR reg_promociones IN promociones LOOP
    v_cant_migrar := 0;
    v_cant_migrar := reg_promociones.cantidad-reg_promociones.negocio;
    v_suma_fuente := v_suma_fuente + reg_promociones.cantidad;
    v_suma_negocio := v_suma_negocio + reg_promociones.negocio;
    v_suma_migrar := v_suma_migrar + v_cant_migrar;
    v_suma_retenidos := v_suma_retenidos + reg_promociones.retenciones;
    v_suma_entregados := v_suma_entregados + reg_promociones.entregados;

      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda(reg_promociones.objeto,'Normal',0,'String');
      pkg_genera_excel.escribe_celda(reg_promociones.cantidad,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_promociones.negocio,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(v_cant_migrar,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_promociones.retenciones,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_promociones.entregados,'CampoNumero',0,'Number');
      pkg_genera_excel.escribe_celda(reg_promociones.observaciones, 'Normal', 0, 'String');
      pkg_genera_excel.cierra_fila;

    END LOOP;

    --Totalizador
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('TOTAL','TituloColumnas',0,'String');
    pkg_genera_excel.escribe_celda(v_suma_fuente,'TituloColumnasnumerico',0,'Number');
    pkg_genera_excel.escribe_celda(v_suma_negocio,'TituloColumnasnumerico',0,'Number');
    pkg_genera_excel.escribe_celda(v_suma_migrar,'TituloColumnasnumerico',0,'Number');
    pkg_genera_excel.escribe_celda(v_suma_retenidos,'TituloColumnasnumerico',0,'Number');
    pkg_genera_excel.escribe_celda(v_suma_entregados,'TituloColumnasnumerico',0,'Number');
    pkg_genera_excel.escribe_celda('', 'Normal', 0, 'String');
    pkg_genera_excel.cierra_fila;

    --Cierra hoja de trabajo
    pkg_genera_excel.cierra_hoja;

  -----------------------------------------------------------------------
  --               REPORTE DETALLADO - HOJAS SIGUIENTES
  -----------------------------------------------------------------------
  -- Cursor tablas parametrizadas
  FOR reg_parametros IN parametros LOOP

    v_rete_inter := 0;
    v_continua   := 0;
    v_sum_ret    := 0;

    IF Upper(reg_parametros.tabla) ='INTEGRACION.DIRECCIONES' THEN
      v_reglaNegocio := '|037';
    ELSIF Upper(reg_parametros.tabla) ='INTEGRACION.CLIENTES' THEN
      v_reglaNegocio := '|074';
    ELSIF Upper(reg_parametros.tabla) ='INTEGRACION.CONTACTOS' THEN
      v_reglaNegocio := '001';
    ELSE
      v_reglaNegocio := '9999999999999';
    END IF;

    IF Upper(reg_parametros.objeto) = 'UNICO' THEN
      v_pestana := 'CONTACTOS';
    ELSE
      v_pestana := reg_parametros.objeto;
    END IF;

    -- Abre hoja nueva
    pkg_genera_excel.abre_hoja(v_pestana, 5);
    pkg_genera_excel.abre_fila(13);
    pkg_genera_excel.escribe_celda('', 'Normal', 4, 'String');
    pkg_genera_excel.cierra_fila;

    IF reg_parametros.tabla IS NULL OR reg_parametros.objeto IS NULL OR
       reg_parametros.flag IS NULL OR reg_parametros.descripcion IS NULL THEN

      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda('ERROR AL PARAMETRIZAR OBJETOS  -  REVISAR PRODUCTO.','TituloColumnas',4,'String');
      pkg_genera_excel.cierra_fila;

    ELSE

      --Reporte con Intersecciones
      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda('RETENIDOS ' ||reg_parametros.objeto ||
                                      ' - INTERSECCION DE ERRORES Y WARNINGS','TituloColumnas',
                                      4,'String');
      pkg_genera_excel.cierra_fila;
      pkg_genera_excel.abre_fila(13);
      pkg_genera_excel.escribe_celda('DESCRIPCION','Normal',3,'String');
      pkg_genera_excel.escribe_celda('CANTIDAD','Normal',0,'String');
      pkg_genera_excel.cierra_fila;

      BEGIN
        pr_reporte_general(reg_parametros.objeto,
                           reg_parametros.tabla,
                           reg_parametros.flag,
                           reg_parametros.descripcion,
                           reg_parametros.filtro,
                           v_reglaNegocio,
                           v_sum_ret);
      EXCEPTION
        WHEN OTHERS THEN
          v_continua := 1;
      END;

      -- Si no existen errores al ejecutar el paquete continua
      IF v_continua = 0 THEN

        -- Si no existen errores al ejecutar el paquete continua
          IF reg_parametros.tabla2 IS NOT NULL THEN

            pkg_genera_excel.abre_fila(13);
            pkg_genera_excel.escribe_celda(Substr(reg_parametros.tabla2,Instr(reg_parametros.tabla2,'.')+1),'Normal',3,'String');
            pkg_genera_excel.cierra_fila;

            BEGIN
              pr_reporte_general(reg_parametros.objeto,
                           reg_parametros.tabla2,
                           reg_parametros.flag,
                           reg_parametros.descripcion,
                           reg_parametros.filtro,
                           v_reglaNegocio,
                           v_sum_ret);
            EXCEPTION
            WHEN OTHERS THEN
              v_continua := 1;
            END;
          END IF;

          IF reg_parametros.tabla_base IS NOT NULL THEN

            v_sentencia:= 'SELECT ((SELECT COUNT(1)
                                    FROM '|| reg_parametros.tabla_base ||
                                    ' WHERE servicio_id IN (' || reg_parametros.servicio_id ||
                                    ')) - (SELECT COUNT(1) FROM ' || reg_parametros.tabla ||
                                    ')) FROM DUAL';
            BEGIN
              EXECUTE IMMEDIATE v_sentencia INTO v_quedados_entre_tablas;
            EXCEPTION
             WHEN OTHERS THEN
               v_quedados_entre_tablas := 0;
            END;

            IF v_quedados_entre_tablas != 0 THEN

            v_sum_ret := v_sum_ret + v_quedados_entre_tablas;

              pkg_genera_excel.abre_fila(13);
              pkg_genera_excel.escribe_celda('Error de datos.','Normal',3,'String');
              pkg_genera_excel.escribe_celda(v_quedados_entre_tablas,'CampoNumero',0,'Number');
              pkg_genera_excel.cierra_fila;

            END IF;

          END IF;

          pkg_genera_excel.abre_fila(13);
          pkg_genera_excel.escribe_celda('TOTAL','TituloColumnas',3,'String');
          pkg_genera_excel.escribe_celda(v_sum_ret,'TituloColumnasnumerico',0,'Number');
          pkg_genera_excel.cierra_fila;

          pkg_genera_excel.abre_fila(13);
          pkg_genera_excel.escribe_celda('', 'Normal', 4, 'String');
          pkg_genera_excel.cierra_fila;

          --Reporte por codigos
          pkg_genera_excel.abre_fila(13);
          pkg_genera_excel.escribe_celda('', 'Normal', 4, 'String');
          pkg_genera_excel.cierra_fila;

          pkg_genera_excel.abre_fila(13);
          pkg_genera_excel.escribe_celda('RETENIDOS - REPORTE POR ERROR Y WARNING','TituloColumnas',4,'String');
          pkg_genera_excel.cierra_fila;

          pkg_genera_excel.abre_fila(13);
          pkg_genera_excel.escribe_celda('DESCRIPCION','Normal',2,'String');
          pkg_genera_excel.escribe_celda('TIPO ALERTA','Normal',0,'String');
          pkg_genera_excel.escribe_celda('CANTIDAD','Normal',0,'String');
          pkg_genera_excel.cierra_fila;

          BEGIN
            pr_reporte_codigos(reg_parametros.objeto,
                               reg_parametros.tabla,
                               reg_parametros.flag,
                               reg_parametros.descripcion,
                               reg_parametros.filtro,
                               v_reglaNegocio);
          EXCEPTION
            WHEN OTHERS THEN
              v_continua := 1;
          END;
          
          BEGIN
            pr_reporte_codigos_det(reg_parametros.objeto,
                                   reg_parametros.tabla,
                                   reg_parametros.flag,
                                   reg_parametros.descripcion,
                                   reg_parametros.filtro,
                                   v_reglaNegocio);
          EXCEPTION
            WHEN OTHERS THEN
              v_continua := 1;
          END;          
          
          

          IF v_continua = 0 THEN

            IF reg_parametros.tabla2 IS NOT NULL THEN

              pkg_genera_excel.abre_fila(13);
              pkg_genera_excel.escribe_celda(Substr(reg_parametros.tabla2,Instr(reg_parametros.tabla2,'.')+1),'Normal',4,'String');
              pkg_genera_excel.cierra_fila;

              BEGIN
                pr_reporte_codigos(reg_parametros.objeto,
                                   reg_parametros.tabla2,
                                   reg_parametros.flag,
                                   reg_parametros.descripcion,
                                   reg_parametros.filtro,
                                   v_reglaNegocio);
              EXCEPTION
              WHEN OTHERS THEN
                v_continua := 1;
              END;

           END IF;

          END IF;

        END IF;

        -- Si existieron errores en la ejecución de paquetes informa
        IF v_continua = 1 THEN
          pkg_genera_excel.abre_fila(13);
          pkg_genera_excel.escribe_celda('ERROR AL EJECUTAR PROCESOS DE ESTADISTICAS  -  REVISAR PRODUCTO.',
                                          'TituloColumnas',2,'String');
          pkg_genera_excel.cierra_fila;
        END IF;

      END IF;

    --Cierra hoja de trabajo
    pkg_genera_excel.cierra_hoja;

  END LOOP;

  -- Cierra Archivo Excel
  pkg_genera_excel.cierra_excel;

  END prc_reporte_general_retenidos;



END pkg_reportes_automaticos;
/
