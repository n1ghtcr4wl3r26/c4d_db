CREATE OR REPLACE 
PACKAGE carpetas2
/* Formatted on 20-sep.-2017 10:29:49 (QP5 v5.126) */
IS
    TYPE cursortype IS REF CURSOR;

    FUNCTION valida_fecha (prm_fecha IN VARCHAR2)
        RETURN NUMBER;

    FUNCTION valida_fechas (prm_fechaini   IN VARCHAR2,
                            prm_fechafin   IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION numeros_generados
        RETURN cursortype;

    FUNCTION devuelve_secuencia (numero IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION devuelve_asociado (numero IN VARCHAR2)
        RETURN VARCHAR2;

    PROCEDURE verifica_asignacion (inicio       IN     VARCHAR2,
                                   fin          IN     VARCHAR2,
                                   res             OUT VARCHAR2,
                                   vsecini         OUT VARCHAR2,
                                   vsecfin         OUT VARCHAR2,
                                   cant_asig       OUT VARCHAR2,
                                   cant_desh       OUT VARCHAR2,
                                   cant_total      OUT VARCHAR2);

    PROCEDURE asignacion_aduana (inicio    IN     VARCHAR2,
                                 fin       IN     VARCHAR2,
                                 aduana    IN     VARCHAR2,
                                 usuario   IN     VARCHAR2,
                                 res          OUT VARCHAR2);

    FUNCTION asigna_aduana (numero    IN VARCHAR2,
                            aduana    IN VARCHAR2,
                            usuario   IN VARCHAR2)
        RETURN BOOLEAN;

    FUNCTION es_despacho_directo (nit IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION asocia_carpeta (numero    IN VARCHAR2,
                             nit       IN VARCHAR2,
                             recibo    IN VARCHAR2,
                             usuario   IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION encripta_carpetas (usuario IN VARCHAR2)
        RETURN NUMBER;

    FUNCTION devuelve_maximo
        RETURN NUMBER;

    FUNCTION inserta_parametros (maximo IN NUMBER, usuario IN VARCHAR2)
        RETURN NUMBER;

    FUNCTION devuelve_valido (numero IN VARCHAR2)
        RETURN NUMBER;

    FUNCTION carpeta_estado (numero IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION carpeta_asociada (numero IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION devuelve_estado (numero IN VARCHAR2)
        RETURN NUMBER;

    FUNCTION bajar_tablas
        RETURN NUMBER;

    FUNCTION dar_baja (numero        IN VARCHAR2,
                       usuario       IN VARCHAR2,
                       observacion   IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION rehabilitar (numero        IN VARCHAR2,
                          usuario       IN VARCHAR2,
                          observacion   IN VARCHAR2)
        RETURN VARCHAR2;
END;
/

CREATE OR REPLACE 
PACKAGE BODY carpetas2
/* Formatted on 20-sep.-2017 10:29:53 (QP5 v5.126) */
IS
    FUNCTION valida_fecha (prm_fecha IN VARCHAR2)
        RETURN NUMBER
    IS
        res   NUMBER;
        fec   DATE;
    BEGIN
        fec := TO_DATE (prm_fecha, 'dd/mm/yyyy');
        RETURN 0;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            RETURN 1;
    END;

    FUNCTION valida_fechas (prm_fechaini   IN VARCHAR2,
                            prm_fechafin   IN VARCHAR2)
        RETURN VARCHAR2
    IS
        res      VARCHAR2(5);
        fecini   DATE;
        fecfin   DATE;
    BEGIN
        IF valida_fecha (prm_fechaini) = 1
        THEN
            RETURN '2';
        END IF;

        IF valida_fecha (prm_fechafin) = 1
        THEN
            RETURN '3';
        END IF;

        IF TO_DATE (prm_fechafin, 'dd/mm/yyyy') <
               TO_DATE (prm_fechaini, 'dd/mm/yyyy')
        THEN
            RETURN '1';
        END IF;

        RETURN '0';
    END;

    FUNCTION numeros_generados
        RETURN cursortype
    IS
        ct   cursortype;
    BEGIN
        OPEN ct FOR
              SELECT   a.cad_maximo, a.cad_usuario, a.cad_fecha
                FROM   ops$asy.corr_parametros a
               WHERE   a.lst_ope = 'U'
            ORDER BY   cad_fecha DESC;

        RETURN ct;
    END;


    FUNCTION devuelve_secuencia (numero IN VARCHAR2)
        RETURN VARCHAR2
    IS
        secuencia   VARCHAR2 (50) := '';
    BEGIN
        SELECT   cad_secuencial
          INTO   secuencia
          FROM   ops$asy.corr_carpetas
         WHERE   cad_secuencial || cad_encriptado = numero AND lst_ope = 'U';


        RETURN secuencia;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;


    FUNCTION devuelve_asociado (numero IN VARCHAR2)
        RETURN VARCHAR2
    IS
        secuencia   VARCHAR2 (50) := '';
    BEGIN
        SELECT   cad_nit
          INTO   secuencia
          FROM   ops$asy.corr_carpetas
         WHERE   cad_secuencial || cad_encriptado = numero AND lst_ope = 'U';

        RETURN secuencia;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;


    PROCEDURE verifica_asignacion (inicio       IN     VARCHAR2,
                                   fin          IN     VARCHAR2,
                                   res             OUT VARCHAR2,
                                   vsecini         OUT VARCHAR2,
                                   vsecfin         OUT VARCHAR2,
                                   cant_asig       OUT VARCHAR2,
                                   cant_desh       OUT VARCHAR2,
                                   cant_total      OUT VARCHAR2)
    IS
        ct            cursortype;
        vini          VARCHAR2 (30) := NULL;
        vfin          VARCHAR2 (30) := NULL;
        msg           VARCHAR (300) := '';
        rcant_asig    VARCHAR2 (30) := '0';
        rcant_desh    VARCHAR2 (30) := '0';
        rcant_total   VARCHAR2 (30) := '0';
    BEGIN
        SELECT   a.cad_secuencial
          INTO   vini
          FROM   ops$asy.corr_carpetas a
         WHERE   a.cad_secuencial || a.cad_encriptado = inicio
                 AND a.lst_ope = 'U';

        vsecini := vini;

        IF (vini IS NOT NULL)
        THEN
            SELECT   a.cad_secuencial
              INTO   vfin
              FROM   ops$asy.corr_carpetas a
             WHERE   a.cad_secuencial || a.cad_encriptado = fin
                     AND a.lst_ope = 'U';

            vsecfin := vfin;

            IF (vfin IS NOT NULL)
            THEN
                SELECT   COUNT (1)
                  INTO   rcant_asig
                  FROM   ops$asy.corr_carpetas a
                 WHERE   a.cad_cuo IS NOT NULL
                         AND a.cad_secuencial BETWEEN CAST (vini AS number)
                                                  AND  CAST (vfin AS number)
                         AND a.lst_ope = 'U';

                cant_asig := rcant_asig;

                SELECT   COUNT (1)
                  INTO   rcant_desh
                  FROM   ops$asy.corr_carpetas a
                 WHERE   a.cad_secuencial BETWEEN CAST (vini AS number)
                                              AND  CAST (vfin AS number)
                         AND NOT (a.lst_ope = 'U');

                cant_desh := rcant_desh;

                SELECT   COUNT (1)
                  INTO   rcant_total
                  FROM   ops$asy.corr_carpetas a
                 WHERE   a.cad_secuencial BETWEEN CAST (vini AS number)
                                              AND  CAST (vfin AS number)
                         AND a.lst_ope = 'U';

                cant_total := rcant_total;
            ELSE
                msg :=
                    'El N&uacute;mero de Final no corresponde a un n&uacute;mero de carpeta valido';
            END IF;
        ELSE
            msg :=
                'El N&uacute;mero de Inicial no corresponde a un n&uacute;mero de carpeta valido';
        END IF;

        res := msg;
    END;


    PROCEDURE asignacion_aduana (inicio    IN     VARCHAR2,
                                 fin       IN     VARCHAR2,
                                 aduana    IN     VARCHAR2,
                                 usuario   IN     VARCHAR2,
                                 res          OUT VARCHAR2)
    IS
        CURSOR ct
        IS
            SELECT   a.cad_cuo,
                     a.cad_secuencial,
                     a.cad_encriptado,
                     a.lst_ope
              FROM   ops$asy.corr_carpetas a
             WHERE   a.cad_secuencial BETWEEN inicio AND fin;

        msg      VARCHAR2 (4000) := '';
        cont     NUMBER := 0;
        casig    NUMBER := 0;
        cerror   NUMBER := 0;
    BEGIN
        FOR rs IN ct
        LOOP
            cont := cont + 1;

            IF (rs.lst_ope = 'U')
            THEN
                IF (ops$asy.carpetas.asigna_aduana (
                        rs.cad_secuencial || rs.cad_encriptado,
                        aduana,
                        usuario))
                THEN
                    casig := casig + 1;
                ELSE
                    cerror := cerror + 1;
                    msg :=
                           msg
                        || ' - error la carpeta '
                        || rs.cad_secuencial
                        || rs.cad_encriptado
                        || ' no pudo ser asignada.<br>';
                END IF;
            ELSE
                cerror := cerror + 1;
                msg :=
                       msg
                    || ' - la carpeta '
                    || rs.cad_secuencial
                    || rs.cad_encriptado
                    || ' esta deshabilitada.<br>';
            END IF;
        END LOOP;

        msg :=
               msg
            || '<br>Se asign&oacute; correctamente '
            || CAST (casig AS varchar2)
            || ' carpetas.';

        INSERT INTO ops$asy.corr_asignaciones a (a.cad_nro_carpeta_ini,
                                                 a.cad_nro_carpeta_fin,
                                                 a.cad_aduana,
                                                 a.cad_usuario,
                                                 a.cad_fecha)
          VALUES   (inicio,
                    fin,
                    aduana,
                    usuario,
                    SYSDATE);

        COMMIT;
        res := msg;
    END;

    FUNCTION asigna_aduana (numero    IN VARCHAR2,
                            aduana    IN VARCHAR2,
                            usuario   IN VARCHAR2)
        RETURN BOOLEAN
    IS
        res    BOOLEAN := TRUE;
        aux    VARCHAR2 (10);
        cont   NUMBER;
    BEGIN
        aux := '0';

        UPDATE   ops$asy.corr_carpetas
           SET   cad_cuo_usuario = usuario,
                 cad_cuo = aduana,
                 cad_cuo_fecha = SYSDATE
         WHERE   cad_secuencial || cad_encriptado = numero;

        RETURN res;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN FALSE;
    END;

    FUNCTION es_despacho_directo (nit IN VARCHAR2)
        RETURN VARCHAR2
    IS
        res   VARCHAR2 (10);
    BEGIN
        /*
                SELECT count(1)
                  INTO res
                  FROM bo_new_regope a
                 WHERE a.ope_numerodoc = nit
                   AND a.sad_num=0
                   AND a.ope_estado='H'
                   AND a.ope_tipooperador='IMP';
        */
        SELECT   COUNT (1)
          INTO   res
          FROM   ops$asy.bo_oce_opecab c, ops$asy.bo_oce_opetipo t
         WHERE       c.ope_numerodoc = t.ope_numerodoc
                 AND c.ope_num = 0
                 AND c.ope_num = t.tip_num
                 AND t.tip_lst_ope = 'U'
                 AND t.tip_estado = 'H'
                 AND t.tip_tipooperador = 'IMP'
                 AND c.ope_numerodoc = nit
                 AND t.tip_despachodirecto = 'S';

        IF res = 0
        THEN
            SELECT   COUNT ( * )
              INTO   res
              FROM   operador.olopetab o, operador.olopetip t
             WHERE       o.ope_nit = nit
                     AND o.emp_cod = t.emp_cod
                     AND o.ult_ver = 0
                     AND o.ult_ver = t.ult_ver
                     AND t.tbl_sta = 'H'
                     AND t.ope_tip = 'IMP'
                     AND t.ope_remp = 1
                     AND t.des_dir = 'S';
        END IF;

        RETURN res;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN '0';
    END;


    FUNCTION asocia_carpeta (numero    IN VARCHAR2,
                             nit       IN VARCHAR2,
                             recibo    IN VARCHAR2,
                             usuario   IN VARCHAR2)
        RETURN VARCHAR2
    IS
        res    VARCHAR2 (10) := 'OK';
        aux    VARCHAR2 (10);
        cont   NUMBER;
    BEGIN
        aux := '0';

        UPDATE   ops$asy.corr_carpetas
           SET   cad_nit = nit,
                 cad_recibo = recibo,
                 cad_nit_usuario = usuario,
                 cad_nit_fecha = SYSDATE
         WHERE   cad_secuencial || cad_encriptado = numero;

        RETURN res;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 'ERROR';
    END;

    FUNCTION algoritmo_encripta_carpetas (inicio    IN NUMBER,
                                          fin       IN NUMBER,
                                          usuario   IN VARCHAR2)
        RETURN BOOLEAN
    IS
        num      CHAR (1);
        i        NUMBER;
        j        NUMBER;
        suma     NUMBER;
        valor    VARCHAR2 (100);
        cadena   VARCHAR2 (20);
    BEGIN
        IF inicio > fin
        THEN
            RETURN FALSE;
        END IF;

        FOR i IN inicio .. fin
        LOOP
            cadena := TO_CHAR (i);
            valor := '';

            WHILE LENGTH (cadena) != 0
            LOOP
                num := SUBSTR (cadena, LENGTH (cadena));

                IF num = '0'
                THEN
                    valor := valor || '0000';
                ELSIF num = '1'
                THEN
                    valor := valor || '0001';
                ELSIF num = '2'
                THEN
                    valor := valor || '0010';
                ELSIF num = '3'
                THEN
                    valor := valor || '0011';
                ELSIF num = '4'
                THEN
                    valor := valor || '0100';
                ELSIF num = '5'
                THEN
                    valor := valor || '0101';
                ELSIF num = '6'
                THEN
                    valor := valor || '0110';
                ELSIF num = '7'
                THEN
                    valor := valor || '0111';
                ELSIF num = '8'
                THEN
                    valor := valor || '1000';
                ELSIF num = '9'
                THEN
                    valor := valor || '1001';
                END IF;

                cadena := SUBSTR (cadena, 1, LENGTH (cadena) - 1);
            END LOOP;

            suma := 0;
            j := 0;

            WHILE LENGTH (valor) != 0
            LOOP
                num := SUBSTR (valor, LENGTH (valor));
                suma := suma + TO_NUMBER (num) * POWER (2, j);
                valor := SUBSTR (valor, 1, LENGTH (valor) - 1);
                j := j + 1;
            END LOOP;

            DBMS_OUTPUT.put_line (' suma ' || suma);

            INSERT INTO ops$asy.corr_carpetas (cad_secuencial,
                                               cad_encriptado,
                                               cad_usuario,
                                               cad_fecha,
                                               lst_ope,
                                               cad_observacion)
              VALUES   (i,
                        suma,
                        usuario,
                        SYSDATE,
                        'U',
                        '');
        END LOOP;

        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'SQL Error Msg=' || SUBSTR (SQLERRM, 1, 230));
            -- Typical usage
            DBMS_OUTPUT.put_line ('SQL Code=' || TO_CHAR (SQLCODE));
            -- Typical usage
            RETURN FALSE;
    END;

    FUNCTION encripta_carpetas (usuario IN VARCHAR2)
        RETURN NUMBER
    IS
        inicio   NUMBER;
        fin      NUMBER;
    BEGIN
        SELECT   cad_minimo, cad_maximo
          INTO   inicio, fin
          FROM   ops$asy.corr_parametros
         WHERE   lst_ope = 'U';

        IF algoritmo_encripta_carpetas (inicio, fin, usuario)
        THEN
            INSERT INTO ops$asy.corr_usuarios
              VALUES   (inicio,
                        fin,
                        usuario,
                        SYSDATE);

            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END;

    FUNCTION devuelve_maximo
        RETURN NUMBER
    IS
        maximo   NUMBER;
    BEGIN
        SELECT   cad_maximo
          INTO   maximo
          FROM   ops$asy.corr_parametros
         WHERE   lst_ope = 'U';

        RETURN maximo;
    END;

    FUNCTION inserta_parametros (maximo IN NUMBER, usuario IN VARCHAR2)
        RETURN NUMBER
    IS
        maximoa   NUMBER;
    BEGIN
        maximoa := devuelve_maximo;

        IF maximoa < maximo
        THEN
            UPDATE   ops$asy.corr_parametros
               SET   lst_ope = 'D'
             WHERE   lst_ope = 'U';

            INSERT INTO ops$asy.corr_parametros
              VALUES   (maximo,
                        'U',
                        usuario,
                        SYSDATE,
                        maximoa + 1);

            IF encripta_carpetas (usuario) = 1
            THEN
                RETURN 1;
            ELSE
                RETURN 0;
            END IF;
        ELSE
            RETURN 0;
        END IF;
    END;

    FUNCTION devuelve_valido (numero IN VARCHAR2)
        RETURN NUMBER
    IS
        cantidad   NUMBER;
    BEGIN
        SELECT   COUNT (1)
          INTO   cantidad
          FROM   ops$asy.corr_carpetas
         WHERE   cad_secuencial || cad_encriptado = numero AND lst_ope = 'U';

        IF cantidad > 0
        THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END;

    FUNCTION carpeta_estado (numero IN VARCHAR2)
        RETURN VARCHAR2
    IS
        res    VARCHAR2 (2);
        cont   NUMBER;
    BEGIN
        res := '0';

        SELECT   COUNT (1)
          INTO   cont
          FROM   corr_carpetas
         WHERE   cad_secuencial || cad_encriptado = numero;

        IF cont = 0
        THEN
            RETURN '0';
        ELSE
            SELECT   lst_ope
              INTO   res
              FROM   corr_carpetas
             WHERE   cad_secuencial || cad_encriptado = numero;

            IF res = 'U'
            THEN
                RETURN '1';
            ELSE
                IF res = 'D'
                THEN
                    RETURN '2';
                ELSE
                    RETURN '3';
                END IF;
            END IF;
        END IF;
    END;

    FUNCTION dar_baja (numero        IN VARCHAR2,
                       usuario       IN VARCHAR2,
                       observacion   IN VARCHAR2)
        RETURN VARCHAR2
    IS
        res    VARCHAR2 (200);
        aux    VARCHAR2 (10);
        cont   NUMBER;
    BEGIN
        aux := '0';

        UPDATE   corr_carpetas
           SET   cad_usuario = usuario,
                 lst_ope = 'D',
                 cad_observacion = observacion,
                 cad_fecha = SYSDATE
         WHERE   cad_secuencial || cad_encriptado = numero;

        SELECT   COUNT (1)
          INTO   aux
          FROM   corr_carpetas
         WHERE   cad_secuencial || cad_encriptado = numero AND lst_ope = 'D';

        IF aux = '0'
        THEN
            res := 'ERROR';
        ELSE
            res := 'OK';
        END IF;

        RETURN res;
    END;

    FUNCTION rehabilitar (numero        IN VARCHAR2,
                          usuario       IN VARCHAR2,
                          observacion   IN VARCHAR2)
        RETURN VARCHAR2
    IS
        res    VARCHAR2 (200);
        aux    VARCHAR2 (10);
        cont   NUMBER;
    BEGIN
        aux := '0';

        UPDATE   corr_carpetas
           SET   cad_usuario = usuario,
                 lst_ope = 'U',
                 cad_observacion = observacion,
                 cad_fecha = SYSDATE
         WHERE   cad_secuencial || cad_encriptado = numero;

        SELECT   COUNT (1)
          INTO   aux
          FROM   corr_carpetas
         WHERE   cad_secuencial || cad_encriptado = numero AND lst_ope = 'U';

        IF aux = '0'
        THEN
            res := 'ERROR';
        ELSE
            res := 'OK';
        END IF;

        RETURN res;
    END;

    FUNCTION carpeta_asociada (numero IN VARCHAR2)
        RETURN VARCHAR2
    IS
        res    VARCHAR2 (800);
        cont   NUMBER;
    BEGIN
        res := '0';

        SELECT   COUNT (1)
          INTO   cont
          FROM   sad_trr s, sad_gen g
         WHERE       s.sad_att_cod = 'C44'
                 AND s.sad_att_ref = TO_CHAR (numero)
                 AND s.key_year = g.key_year
                 AND s.key_cuo = g.key_cuo
                 AND s.key_dec = g.key_dec
                 AND s.key_nber = g.key_nber
                 AND s.sad_num = g.sad_num
                 AND g.lst_ope = 'U'
                 AND g.sad_num = 0
                 AND g.sad_reg_serial IS NOT NULL
                 AND g.sad_reg_nber IS NOT NULL;

        --cast(numero as varchar2(14));
        IF cont = 0
        THEN
            RETURN '0';
        ELSE
            SELECT   '<table class="table table-striped table-hover">'
                     || '<thead><tr><td colspan="3" align="center"><b>DUI ASOCIADA DEL DOCUMENTO</b></td></tr></thead>'
                     || '<tbody><tr><th align="center">N&Uacute;MERO CARPETA</th><th align="center">DUI</th><th align="center">ADUANA</th><th align="center">FECHA</th></tr>'
                     || '<tr><td>'
                     || s.sad_att_ref
                     || '</td><td>'
                     || g.sad_reg_serial
                     || '-'
                     || g.sad_reg_nber
                     || '</td><td>'
                     || g.key_cuo
                     || '-'
                     || u.cuo_nam
                     || '</td><td>'
                     || TO_CHAR (g.sad_reg_date, 'dd/mm/yyyy')
                     || '</td></tr></tbody></table>'
              INTO   res
              FROM   sad_trr s, sad_gen g, uncuotab u
             WHERE       s.sad_att_cod = 'C44'
                     AND s.sad_att_ref = TO_CHAR (numero)
                     AND s.sad_num = 0
                     AND s.key_year = g.key_year
                     AND s.key_cuo = g.key_cuo
                     AND s.key_dec = g.key_dec
                     AND s.key_nber = g.key_nber
                     AND s.sad_num = g.sad_num
                     AND g.lst_ope = 'U'
                     AND g.sad_num = 0
                     AND g.key_cuo = u.cuo_cod
                     AND u.lst_ope = 'U'
                     AND g.sad_reg_serial IS NOT NULL
                     AND g.sad_reg_nber IS NOT NULL;

            RETURN res;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN '<center><div id="msgerror">Error Inesperado</div></center>';
    END;

    FUNCTION devuelve_estado (numero IN VARCHAR2)
        RETURN NUMBER
    IS
        cantidad   NUMBER;
    BEGIN
        SELECT   COUNT (1)
          INTO   cantidad
          FROM   corr_carpetas
         WHERE   cad_secuencial || cad_encriptado = numero AND lst_ope = 'U';

        IF cantidad > 0
        THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END;

    FUNCTION bajar_tablas
        RETURN NUMBER
    IS
        inicio   NUMBER;
        fin      NUMBER;
        output   UTL_FILE.file_type;
        nombre   VARCHAR2 (30);
        direct   VARCHAR2 (100);
    BEGIN
        SELECT   cad_minimo, cad_maximo
          INTO   inicio, fin
          FROM   corr_parametros
         WHERE   lst_ope = 'U';

        nombre := 'carpetas.txt';
        direct := 'CARPETAS';
        output :=
            UTL_FILE.fopen (direct,
                            nombre,
                            'w',
                            32000);
        owa_sylk.show (
            p_file            => output,
            p_query           => 'select CAD_SECUENCIAL||CAD_ENCRIPTADO Correlativos '
                                || 'from corr_carpetas '
                                || 'where CAD_SECUENCIAL between :inicio and :fin and lst_ope=:lst',
            p_parm_names      => owa_sylk.owasylkarray ('inicio', 'fin', 'lst'),
            p_parm_values     => owa_sylk.owasylkarray (inicio, fin, 'U'),
            p_sum_column      => owa_sylk.owasylkarray ('N'),
            p_show_grid       => 'YES',
            p_strip_html      => 'NO',
            p_max_rows        => 100000,
            p_show_cantidad   => 1);
        UTL_FILE.fclose (output);
        RETURN 1;
    END;
END;
/

