*&---------------------------------------------------------------------*
*& Report ZAZP_E2E
*& P2 E2E: Validation (#10), Month Simulation (#11), Transport (#12)
*& IT0007 Assignment (#13) is dry-read only (no write).
*& Run via SE38 /nZAZP_E2E or /nSE38.
*&---------------------------------------------------------------------*
REPORT zazp_e2e.

PARAMETERS:
  p_schkz TYPE t508a-schkz DEFAULT 'NORM' OBLIGATORY,
  p_zeity TYPE t508a-zeity DEFAULT '1',
  p_mofid TYPE t508a-mofid DEFAULT '08',
  p_mosid TYPE t508a-mosid DEFAULT '01',
  p_year  TYPE numc4 DEFAULT '2026',
  p_month TYPE numc2 DEFAULT '07',
  p_pernr TYPE pa0007-pernr.

START-OF-SELECTION.
  PERFORM run_validation.
  PERFORM run_simulation.
  PERFORM run_transport.
  PERFORM run_assignment_read.

FORM run_validation.
  DATA lo_val TYPE REF TO zcl_zazp_validation.
  DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
  DATA lv_err TYPE i.
  DATA lv_warn TYPE i.

  WRITE: / '=== P2#10 Validation ==='.
  lo_val = NEW #( ).
  lt_msg = lo_val->zif_zazp_validation~validate_rule(
    rule_id        = p_schkz
    es_grouping    = p_zeity
    holiday_cal_id = p_mofid
    ps_grouping    = p_mosid
    valid_to       = '99991231' ).

  LOOP AT lt_msg INTO DATA(ls_msg).
    WRITE: / ls_msg-severity, ls_msg-msgno, ls_msg-field, ls_msg-text.
    IF ls_msg-severity = 'E'.
      lv_err = lv_err + 1.
    ELSEIF ls_msg-severity = 'W'.
      lv_warn = lv_warn + 1.
    ENDIF.
  ENDLOOP.
  WRITE: / |Validation: total={ lines( lt_msg ) } E={ lv_err } W={ lv_warn }|.
ENDFORM.

FORM run_simulation.
  DATA lo_gen TYPE REF TO zcl_zazp_generation.
  DATA lt_days TYPE zcl_zazp_generation=>ty_sim_days.
  DATA ls_result TYPE zcl_zazp_generation=>ty_sim_result.
  DATA lv_hol TYPE i.

  WRITE: / '=== P2#11 Month simulation ==='.
  lo_gen = zcl_zazp_generation=>create( ).
  lo_gen->simulate_month(
    EXPORTING
      rule_id        = p_schkz
      year           = p_year
      month          = p_month
      es_grouping    = p_zeity
      holiday_cal_id = p_mofid
      ps_grouping    = p_mosid
    IMPORTING
      days           = lt_days
      result         = ls_result ).

  WRITE: / |month_hours={ ls_result-month_hours } avg={ ls_result-avg_month_hours } variance={ ls_result-variance } days={ lines( lt_days ) }|.
  LOOP AT lt_days INTO DATA(ls_day) WHERE is_holiday = abap_true.
    lv_hol = lv_hol + 1.
    IF lv_hol <= 8.
      WRITE: / |HOLIDAY { ls_day-calendar_day } day_type={ ls_day-day_type } hours={ ls_day-target_hours }|.
    ENDIF.
  ENDLOOP.
  WRITE: / |holiday_days={ lv_hol }|.
  IF lv_hol = 0.
    WRITE: / 'NOTE: no holidays found for calendar/month — check MOFID / THOC'.
  ENDIF.
ENDFORM.

FORM run_transport.
  DATA lo_tr TYPE REF TO zcl_zazp_transport.
  DATA lt_req TYPE zcl_zazp_transport=>ty_requests.
  DATA lv_trkorr TYPE e070-trkorr.

  WRITE: / '=== P2#12 Transport ==='.
  lo_tr = NEW #( ).
  lt_req = lo_tr->list_open_customizing_requests( ).
  WRITE: / |open_customizing_requests={ lines( lt_req ) }|.
  LOOP AT lt_req INTO DATA(ls_req) TO 5.
    WRITE: / ls_req-trkorr, ls_req-trstatus, ls_req-as4user, ls_req-as4text.
  ENDLOOP.

  TRY.
      lv_trkorr = lo_tr->ensure_customizing_request( description = 'AZP E2E Probe' ).
      WRITE: / |ensure_trkorr={ lv_trkorr } modifiable={ lo_tr->is_request_modifiable( lv_trkorr ) }|.
    CATCH cx_root INTO DATA(lx).
      WRITE: / 'TR ERROR:', lx->get_text( ).
  ENDTRY.
ENDFORM.

FORM run_assignment_read.
  DATA lo_asg TYPE REF TO zcl_zazp_assignment.
  DATA ls_asg TYPE zcl_zazp_assignment=>ty_assignment.

  WRITE: / '=== P2#13 IT0007 read (no write) ==='.
  IF p_pernr IS INITIAL.
    WRITE: / 'Skip — set P_PERNR to test read_current'.
    RETURN.
  ENDIF.
  lo_asg = NEW #( ).
  ls_asg = lo_asg->read_current( pernr = p_pernr ).
  WRITE: / |PERNR={ p_pernr } SCHKZ={ ls_asg-rule_id } BEGDA={ ls_asg-valid_from } ENDDA={ ls_asg-valid_to }|.
ENDFORM.
