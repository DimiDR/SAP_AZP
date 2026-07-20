*&---------------------------------------------------------------------*
*& Include LZAZP_SM30F01
*& SM30 Event 01 Routinen - in SE54 an Views anbinden:
*&   V_T508A -> ZAZP_VALIDATE_T508A
*&   V_T550A -> ZAZP_VALIDATE_T550A
*&   V_T550P -> ZAZP_VALIDATE_T550P
*&   V_T551A -> ZAZP_VALIDATE_T551A
*& Form-Routinen liegen in Funktionsgruppe ZAZP_SM30 (INCLUDE).
*&---------------------------------------------------------------------*

FORM zazp_validate_t508a.
  DATA lo_val TYPE REF TO zcl_zazp_validation.
  DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
  DATA ls_ctx TYPE zif_zazp_validation=>ty_rule_ctx.
  FIELD-SYMBOLS <total> TYPE ANY TABLE.
  FIELD-SYMBOLS <row> TYPE any.

  lo_val = NEW #( ).
  ASSIGN ('TOTAL[]') TO <total>.
  IF <total> IS NOT ASSIGNED.
    ASSIGN ('TOTAL') TO <total>.
  ENDIF.
  IF <total> IS NOT ASSIGNED.
    RETURN.
  ENDIF.

  LOOP AT <total> ASSIGNING <row>.
    CLEAR: ls_ctx, lt_msg.
    MOVE-CORRESPONDING <row> TO ls_ctx-rule.
    IF ls_ctx-rule-schkz IS INITIAL.
      CONTINUE.
    ENDIF.
    IF ls_ctx-rule-mandt IS INITIAL.
      ls_ctx-rule-mandt = sy-mandt.
    ENDIF.
    lt_msg = lo_val->zif_zazp_validation~validate_rule_ctx( ls_ctx ).
    LOOP AT lt_msg INTO DATA(ls_msg).
      IF ls_msg-severity = 'E'.
        MESSAGE ID 'ZAZP' TYPE 'E' NUMBER '000' WITH ls_msg-text.
      ELSEIF ls_msg-severity = 'W'.
        MESSAGE ID 'ZAZP' TYPE 'W' NUMBER '000' WITH ls_msg-text.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

FORM zazp_validate_t550a.
  DATA lo_val TYPE REF TO zcl_zazp_validation.
  DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
  DATA ls_dws TYPE zif_zazp_validation=>ty_daily.
  DATA ls_row TYPE t550a.
  FIELD-SYMBOLS <total> TYPE ANY TABLE.
  FIELD-SYMBOLS <row> TYPE any.

  lo_val = NEW #( ).
  ASSIGN ('TOTAL[]') TO <total>.
  IF <total> IS NOT ASSIGNED.
    RETURN.
  ENDIF.

  LOOP AT <total> ASSIGNING <row>.
    MOVE-CORRESPONDING <row> TO ls_row.
    ls_dws = VALUE #(
      dws_grouping = ls_row-motpr
      code         = ls_row-tprog
      variant      = ls_row-varia
      target_hours = ls_row-sollz
      work_start   = ls_row-sobeg
      work_end     = ls_row-soend
      normal_start = ls_row-nobeg
      normal_end   = ls_row-noend
      tol_beg_from = ls_row-btbeg
      tol_beg_to   = ls_row-btend
      tol_end_from = ls_row-etbeg
      tol_end_to   = ls_row-etend
      core_start   = ls_row-k1beg
      core_end     = ls_row-k1end
      break_id     = ls_row-pamod ).
    lt_msg = lo_val->zif_zazp_validation~validate_daily( ls_dws ).
    LOOP AT lt_msg INTO DATA(ls_msg).
      IF ls_msg-severity = 'E'.
        MESSAGE ID 'ZAZP' TYPE 'E' NUMBER '000' WITH ls_msg-text.
      ELSEIF ls_msg-severity = 'W'.
        MESSAGE ID 'ZAZP' TYPE 'W' NUMBER '000' WITH ls_msg-text.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

FORM zazp_validate_t550p.
  DATA lo_val TYPE REF TO zcl_zazp_validation.
  DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
  DATA ls_brk TYPE zif_zazp_validation=>ty_break.
  DATA ls_row TYPE t550p.
  FIELD-SYMBOLS <total> TYPE ANY TABLE.
  FIELD-SYMBOLS <row> TYPE any.

  lo_val = NEW #( ).
  ASSIGN ('TOTAL[]') TO <total>.
  IF <total> IS NOT ASSIGNED.
    RETURN.
  ENDIF.

  LOOP AT <total> ASSIGNING <row>.
    MOVE-CORRESPONDING <row> TO ls_row.
    ls_brk = VALUE #(
      dws_grouping = ls_row-motpr
      break_id     = ls_row-pamod
      seq_no       = ls_row-seqno
      start_time   = ls_row-pabeg
      end_time     = ls_row-paend
      paid_hours   = ls_row-pdbez
      unpaid_hours = ls_row-pdunb
      after_hours  = ls_row-stdaz ).
    lt_msg = lo_val->zif_zazp_validation~validate_break( ls_brk ).
    LOOP AT lt_msg INTO DATA(ls_msg).
      IF ls_msg-severity = 'E'.
        MESSAGE ID 'ZAZP' TYPE 'E' NUMBER '000' WITH ls_msg-text.
      ELSEIF ls_msg-severity = 'W'.
        MESSAGE ID 'ZAZP' TYPE 'W' NUMBER '000' WITH ls_msg-text.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

FORM zazp_validate_t551a.
  DATA lo_val TYPE REF TO zcl_zazp_validation.
  DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
  DATA ls_ctx TYPE zif_zazp_validation=>ty_rule_ctx.
  DATA ls_row TYPE t551a.
  FIELD-SYMBOLS <total> TYPE ANY TABLE.
  FIELD-SYMBOLS <row> TYPE any.

  lo_val = NEW #( ).
  ASSIGN ('TOTAL[]') TO <total>.
  IF <total> IS NOT ASSIGNED.
    RETURN.
  ENDIF.

  LOOP AT <total> ASSIGNING <row>.
    CLEAR: ls_ctx, lt_msg.
    MOVE-CORRESPONDING <row> TO ls_row.
    APPEND ls_row TO ls_ctx-weeks.
    SELECT SINGLE * FROM t508a INTO @ls_ctx-rule
      WHERE motpr = @ls_row-motpr
        AND zmodn = @ls_row-zmodn
        AND endda >= @sy-datum
        AND begda <= @sy-datum.
    IF sy-subrc <> 0.
      SELECT SINGLE * FROM t508a INTO @ls_ctx-rule
        WHERE motpr = @ls_row-motpr
          AND zmodn = @ls_row-zmodn.
    ENDIF.
    IF ls_ctx-rule IS INITIAL.
      CONTINUE.
    ENDIF.
    lt_msg = lo_val->zif_zazp_validation~validate_rule_ctx( ls_ctx ).
    LOOP AT lt_msg INTO DATA(ls_msg).
      IF ls_msg-severity = 'E'.
        MESSAGE ID 'ZAZP' TYPE 'E' NUMBER '000' WITH ls_msg-text.
      ELSEIF ls_msg-severity = 'W'.
        MESSAGE ID 'ZAZP' TYPE 'W' NUMBER '000' WITH ls_msg-text.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.
