*&---------------------------------------------------------------------*
*& Report ZAZP01
*& AZP: Validierung und Monatssimulation einer Arbeitszeitplanregel
*& Transaktion: ZAZP01 (SE93, Startobjekt Report)
*&---------------------------------------------------------------------*
REPORT zazp01.

PARAMETERS:
  p_schkz TYPE t508a-schkz OBLIGATORY,
  p_zeity TYPE t508a-zeity,
  p_mofid TYPE t508a-mofid,
  p_mosid TYPE t508a-mosid,
  p_motpr TYPE t508a-motpr,
  p_year  TYPE numc4 DEFAULT sy-datum+0(4),
  p_month TYPE numc2 DEFAULT sy-datum+4(2).

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE titl_opt.
PARAMETERS:
  p_valid AS CHECKBOX DEFAULT 'X',
  p_simul AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  " Selektionstexte zur Laufzeit (ADT-Textpool auf diesem System nicht erreichbar)
  titl_opt                 = 'Funktionen'.
  %_p_schkz_%_app_%-text   = 'Arbeitszeitplanregel'.
  %_p_zeity_%_app_%-text   = 'Grpg Mitarbeiterkreis'.
  %_p_mofid_%_app_%-text   = 'Feiertagskalender'.
  %_p_mosid_%_app_%-text   = 'Grpg Personalteilbereich'.
  %_p_motpr_%_app_%-text   = 'Grpg Tagesarbeitszeitplan'.
  %_p_year_%_app_%-text    = 'Jahr'.
  %_p_month_%_app_%-text   = 'Monat'.
  %_p_valid_%_app_%-text   = 'Regel validieren'.
  %_p_simul_%_app_%-text   = 'Monat simulieren'.

START-OF-SELECTION.
  DATA(lo_val) = NEW zcl_zazp_validation( ).
  DATA(lo_gen) = zcl_zazp_generation=>create( ).

  IF p_valid = abap_true.
    DATA(lt_msg) = lo_val->zif_zazp_validation~validate_rule(
      rule_id        = p_schkz
      dws_grouping   = p_motpr
      es_grouping    = p_zeity
      holiday_cal_id = p_mofid
      ps_grouping    = p_mosid ).
    WRITE: / '=== Validierung ==='.
    IF lt_msg IS INITIAL.
      WRITE: / 'Keine Beanstandungen'.
    ELSE.
      LOOP AT lt_msg INTO DATA(ls_msg).
        WRITE: / ls_msg-severity, ls_msg-field, ls_msg-text.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF p_simul = abap_true.
    DATA lt_days TYPE zcl_zazp_generation=>ty_sim_days.
    DATA ls_res  TYPE zcl_zazp_generation=>ty_sim_result.
    lo_gen->simulate_month(
      EXPORTING
        rule_id        = p_schkz
        year           = p_year
        month          = p_month
        dws_grouping   = p_motpr
        es_grouping    = p_zeity
        holiday_cal_id = p_mofid
        ps_grouping    = p_mosid
      IMPORTING
        days           = lt_days
        result         = ls_res ).
    WRITE: / '=== Monatssimulation ==='.
    WRITE: / 'Monatssumme:', ls_res-month_hours,
           / 'Ø Monat:   ', ls_res-avg_month_hours,
           / 'Abweichung:', ls_res-variance.
    LOOP AT lt_days INTO DATA(ls_day).
      WRITE: / ls_day-calendar_day,
             ls_day-dws_code,
             ls_day-target_hours,
             ls_day-day_type,
             ls_day-is_holiday.
    ENDLOOP.
  ENDIF.
