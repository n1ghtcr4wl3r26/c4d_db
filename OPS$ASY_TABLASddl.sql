CREATE TABLE corr_asignaciones
    (cad_nro_carpeta_ini            NUMBER,
    cad_nro_carpeta_fin            NUMBER,
    cad_aduana                     VARCHAR2(5 BYTE),
    cad_usuario                    VARCHAR2(15 BYTE),
    cad_fecha                      DATE)
  NOPARALLEL
  LOGGING
/

CREATE TABLE corr_carpetas
    (cad_secuencial                 NUMBER NOT NULL,
    cad_encriptado                 VARCHAR2(10 BYTE) NOT NULL,
    cad_usuario                    VARCHAR2(15 BYTE),
    cad_fecha                      DATE,
    lst_ope                        CHAR(1 BYTE),
    cad_observacion                VARCHAR2(100 BYTE),
    cad_nit                        VARCHAR2(20 BYTE),
    cad_recibo                     VARCHAR2(20 BYTE),
    cad_nit_usuario                VARCHAR2(15 BYTE),
    cad_nit_fecha                  DATE,
    cad_cuo                        VARCHAR2(5 BYTE),
    cad_cuo_usuario                VARCHAR2(15 BYTE),
    cad_cuo_fecha                  DATE)
  NOPARALLEL
  LOGGING
/

CREATE UNIQUE INDEX enc_index01 ON corr_carpetas
  (
    cad_secuencial                  ASC,
    cad_encriptado                  ASC
  )
NOPARALLEL
LOGGING
/


CREATE TABLE corr_parametros
    (cad_maximo                     NUMBER NOT NULL,
    lst_ope                        CHAR(1 BYTE) NOT NULL,
    cad_usuario                    VARCHAR2(15 BYTE) NOT NULL,
    cad_fecha                      DATE NOT NULL,
    cad_minimo                     NUMBER)
  NOPARALLEL
  LOGGING
/

CREATE TABLE corr_usuarios
    (cad_secuencial_inicial         NUMBER NOT NULL,
    cad_secuencial_final           NUMBER NOT NULL,
    cad_usuario                    VARCHAR2(15 BYTE) NOT NULL,
    cad_fecha                      DATE NOT NULL)
  NOPARALLEL
  LOGGING
/

