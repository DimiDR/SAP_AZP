CLASS zcl_zazp_validation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_zazp_validation.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS add_message
      IMPORTING
        severity TYPE symsgty
        field    TYPE string
        text     TYPE string
        msgno    TYPE symsgno OPTIONAL
      CHANGING
        messages TYPE zif_zazp_validation=>ty_messages.

    METHODS check_timeframe
      IMPORTING
        dws      TYPE zif_zazp_validation=>ty_daily
      CHANGING
        messages TYPE zif_zazp_validation=>ty_messages.

    TYPES:
      ty_t551a TYPE STANDARD TABLE OF t551a WITH EMPTY KEY,
      ty_t550a TYPE STANDARD TABLE OF t550a WITH EMPTY KEY,
      ty_t550p TYPE STANDARD TABLE OF t550p WITH EMPTY KEY.

    METHODS check_target_hours
      IMPORTING
        dws      TYPE zif_zazp_validation=>ty_daily
        breaks   TYPE ty_t550p OPTIONAL
      CHANGING
        messages TYPE zif_zazp_validation=>ty_messages.

    METHODS check_break_exists
      IMPORTING
        dws_grouping TYPE t550a-motpr
        break_id     TYPE t550a-pamod
        breaks       TYPE ty_t550p OPTIONAL
      CHANGING
        messages     TYPE zif_zazp_validation=>ty_messages.

    METHODS check_dws_exists
      IMPORTING
        dws_grouping  TYPE t550a-motpr
        code          TYPE t550a-tprog
        dailies       TYPE ty_t550a OPTIONAL
      RETURNING
        VALUE(exists) TYPE abap_bool.

    METHODS sum_week_hours
      IMPORTING
        dws_grouping TYPE t551a-motpr
        period_id    TYPE t551a-zmodn
        weeks        TYPE ty_t551a OPTIONAL
        dailies      TYPE ty_t550a OPTIONAL
      RETURNING
        VALUE(hours) TYPE t508a-wostd.

    METHODS hours_from_times
      IMPORTING
        start_time   TYPE t550a-sobeg
        end_time     TYPE t550a-soend
      RETURNING
        VALUE(hours) TYPE t550a-sollz.

    METHODS map_daily
      IMPORTING
        row           TYPE t550a
      RETURNING
        VALUE(result) TYPE zif_zazp_validation=>ty_daily.

    METHODS map_break
      IMPORTING
        row           TYPE t550p
      RETURNING
        VALUE(result) TYPE zif_zazp_validation=>ty_break.

ENDCLASS.


CLASS zcl_zazp_validation IMPLEMENTATION.

  METHOD zif_zazp_validation~validate_rule.
    DATA ls_ctx TYPE zif_zazp_validation=>ty_rule_ctx.

    CLEAR messages.

    IF rule_id IS INITIAL.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'RuleId'
                  text     = 'Arbeitszeitplanregel (SCHKZ) ist leer'
                  msgno    = '001'
        CHANGING  messages = messages ).
      RETURN.
    ENDIF.

    IF es_grouping IS NOT INITIAL
       AND holiday_cal_id IS NOT INITIAL
       AND ps_grouping IS NOT INITIAL
       AND valid_to IS NOT INITIAL.
      SELECT SINGLE * FROM t508a INTO @ls_ctx-rule
        WHERE zeity = @es_grouping
          AND mofid = @holiday_cal_id
          AND mosid = @ps_grouping
          AND schkz = @rule_id
          AND endda = @valid_to.
    ELSEIF es_grouping IS NOT INITIAL
       AND holiday_cal_id IS NOT INITIAL
       AND ps_grouping IS NOT INITIAL.
      SELECT SINGLE * FROM t508a INTO @ls_ctx-rule
        WHERE zeity = @es_grouping
          AND mofid = @holiday_cal_id
          AND mosid = @ps_grouping
          AND schkz = @rule_id
          AND endda >= @sy-datum
          AND begda <= @sy-datum.
    ELSEIF dws_grouping IS NOT INITIAL.
      SELECT SINGLE * FROM t508a INTO @ls_ctx-rule
        WHERE schkz = @rule_id
          AND motpr = @dws_grouping
          AND endda >= @sy-datum
          AND begda <= @sy-datum.
    ENDIF.

    IF ls_ctx-rule IS INITIAL.
      SELECT SINGLE * FROM t508a INTO @ls_ctx-rule
        WHERE schkz = @rule_id
          AND endda >= @sy-datum
          AND begda <= @sy-datum.
    ENDIF.
    IF ls_ctx-rule IS INITIAL.
      SELECT SINGLE * FROM t508a INTO @ls_ctx-rule
        WHERE schkz = @rule_id.
    ENDIF.

    IF ls_ctx-rule IS INITIAL.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'RuleId'
                  text     = |Arbeitszeitplanregel { rule_id } nicht gefunden|
                  msgno    = '002'
        CHANGING  messages = messages ).
      RETURN.
    ENDIF.

    messages = zif_zazp_validation~validate_rule_ctx( ls_ctx ).
  ENDMETHOD.


  METHOD zif_zazp_validation~validate_rule_ctx.
    DATA: lt_weeks TYPE STANDARD TABLE OF t551a WITH EMPTY KEY,
          lv_motpr TYPE t508a-motpr,
          lv_week  TYPE t508a-wostd,
          lv_diff  TYPE t508a-wostd,
          lv_day   TYPE t550a-tprog,
          lv_idx   TYPE i,
          lt_msg   TYPE zif_zazp_validation=>ty_messages.

    CLEAR messages.

    IF ctx-rule-schkz IS INITIAL.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'RuleId'
                  text     = 'Arbeitszeitplanregel (SCHKZ) ist leer'
                  msgno    = '001'
        CHANGING  messages = messages ).
      RETURN.
    ENDIF.

    IF ctx-rule-begda > ctx-rule-endda.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'ValidFrom'
                  text     = 'Gueltig-ab muss kleiner/gleich Gueltig-bis sein'
                  msgno    = '003'
        CHANGING  messages = messages ).
    ENDIF.

    IF ctx-rule-wostd < zif_zazp_validation=>c_week_hours_min
       OR ctx-rule-wostd > zif_zazp_validation=>c_week_hours_max.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-warning
                  field    = 'AvgWeekHours'
                  text     = |Durchschnittswochenstunden { ctx-rule-wostd } ausserhalb Bereich|
                  msgno    = '004'
        CHANGING  messages = messages ).
    ENDIF.

    lv_motpr = ctx-rule-motpr.
    IF ctx-weeks IS NOT INITIAL.
      lt_weeks = ctx-weeks.
    ELSE.
      SELECT * FROM t551a INTO TABLE @lt_weeks
        WHERE motpr = @lv_motpr
          AND zmodn = @ctx-rule-zmodn
        ORDER BY wonum.
    ENDIF.

    IF lt_weeks IS INITIAL.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'PeriodId'
                  text     = |Periodenarbeitszeitplan { ctx-rule-zmodn } nicht gefunden|
                  msgno    = '005'
        CHANGING  messages = messages ).
      RETURN.
    ENDIF.

    LOOP AT lt_weeks ASSIGNING FIELD-SYMBOL(<week>).
      DO 7 TIMES.
        lv_idx = sy-index.
        CASE lv_idx.
          WHEN 1. lv_day = <week>-tprg1.
          WHEN 2. lv_day = <week>-tprg2.
          WHEN 3. lv_day = <week>-tprg3.
          WHEN 4. lv_day = <week>-tprg4.
          WHEN 5. lv_day = <week>-tprg5.
          WHEN 6. lv_day = <week>-tprg6.
          WHEN 7. lv_day = <week>-tprg7.
        ENDCASE.
        IF lv_day IS INITIAL.
          CONTINUE.
        ENDIF.
        IF check_dws_exists(
             dws_grouping = lv_motpr
             code         = lv_day
             dailies      = ctx-dailies ) = abap_false.
          add_message(
            EXPORTING severity = zif_zazp_validation=>c_severity-error
                      field    = |WeekPattern[{ <week>-wonum }].Day{ lv_idx }|
                      text     = |Tagesplan { lv_day } existiert nicht (MOTPR { lv_motpr })|
                      msgno    = '006'
            CHANGING  messages = messages ).
        ENDIF.
      ENDDO.
    ENDLOOP.

    lv_week = sum_week_hours(
      dws_grouping = lv_motpr
      period_id    = ctx-rule-zmodn
      weeks        = lt_weeks
      dailies      = ctx-dailies ).
    lv_diff = lv_week - ctx-rule-wostd.
    IF lv_diff < 0.
      lv_diff = 0 - lv_diff.
    ENDIF.
    IF lv_diff > zif_zazp_validation=>c_week_tol_hours.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'AvgWeekHours'
                  text     = |Wochensumme { lv_week } weicht von Ø-Wochenwert { ctx-rule-wostd } ab|
                  msgno    = '007'
        CHANGING  messages = messages ).
    ENDIF.

    LOOP AT ctx-dailies INTO DATA(ls_daily_row).
      lt_msg = zif_zazp_validation~validate_daily( map_daily( ls_daily_row ) ).
      APPEND LINES OF lt_msg TO messages.
    ENDLOOP.

    LOOP AT ctx-breaks INTO DATA(ls_break_row).
      lt_msg = zif_zazp_validation~validate_break( brk = map_break( ls_break_row ) ).
      APPEND LINES OF lt_msg TO messages.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_zazp_validation~validate_daily.
    CLEAR messages.

    IF dws-code IS INITIAL.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'Code'
                  text     = 'Tagesplan-Code (TPROG) ist leer'
                  msgno    = '010'
        CHANGING  messages = messages ).
      RETURN.
    ENDIF.

    check_timeframe( EXPORTING dws = dws CHANGING messages = messages ).
    check_target_hours( EXPORTING dws = dws CHANGING messages = messages ).

    IF dws-break_id IS NOT INITIAL.
      check_break_exists(
        EXPORTING dws_grouping = dws-dws_grouping
                  break_id     = dws-break_id
        CHANGING  messages     = messages ).
    ENDIF.

    IF dws-target_hours = 0.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-warning
                  field    = 'TargetHours'
                  text     = |Tagesplan { dws-code } hat 0 Sollstunden (Frei-Tag)|
                  msgno    = '011'
        CHANGING  messages = messages ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_zazp_validation~validate_break.
    CLEAR messages.

    IF brk-break_id IS INITIAL.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'BreakId'
                  text     = 'Pausenplan (PAMOD) ist leer'
                  msgno    = '020'
        CHANGING  messages = messages ).
      RETURN.
    ENDIF.

    IF brk-start_time > brk-end_time AND brk-end_time IS NOT INITIAL.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'StartTime'
                  text     = 'Pausenbeginn muss vor Pausenende liegen'
                  msgno    = '021'
        CHANGING  messages = messages ).
    ENDIF.

    IF work_start IS NOT INITIAL AND work_end IS NOT INITIAL.
      IF brk-start_time < work_start OR brk-end_time > work_end.
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-error
                    field    = 'StartTime'
                    text     = 'Pause liegt ausserhalb des Arbeitszeitrahmens'
                    msgno    = '022'
          CHANGING  messages = messages ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD add_message.
DATA lv_text TYPE string.

    IF msgno IS NOT INITIAL.
      MESSAGE ID zif_zazp_validation=>c_msgid
              TYPE severity
              NUMBER msgno
              INTO lv_text.
    ENDIF.

    IF lv_text IS INITIAL.
      lv_text = text.
    ENDIF.

    APPEND VALUE #(
      severity = severity
      field    = field
      text     = lv_text
      msgid    = zif_zazp_validation=>c_msgid
      msgno    = msgno
    ) TO messages.
  ENDMETHOD.


  METHOD check_timeframe.
    IF dws-work_start IS NOT INITIAL AND dws-work_end IS NOT INITIAL.
      IF dws-work_start > dws-work_end.
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-error
                    field    = 'WorkStart'
                    text     = 'Arbeitsbeginn muss vor Arbeitsende liegen'
                    msgno    = '012'
          CHANGING  messages = messages ).
      ENDIF.
    ENDIF.

    IF dws-core_start IS NOT INITIAL AND dws-core_end IS NOT INITIAL.
      IF dws-core_start > dws-core_end.
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-error
                    field    = 'CoreStart'
                    text     = 'Kernzeitbeginn muss vor Kernzeitende liegen'
                    msgno    = '013'
          CHANGING  messages = messages ).
      ENDIF.
      IF dws-work_start IS NOT INITIAL AND dws-core_start < dws-work_start.
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-error
                    field    = 'CoreStart'
                    text     = 'Kernzeit muss innerhalb des Sollrahmens liegen'
                    msgno    = '014'
          CHANGING  messages = messages ).
      ENDIF.
      IF dws-work_end IS NOT INITIAL AND dws-core_end > dws-work_end.
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-error
                    field    = 'CoreEnd'
                    text     = 'Kernzeit muss innerhalb des Sollrahmens liegen'
                    msgno    = '014'
          CHANGING  messages = messages ).
      ENDIF.
      IF dws-normal_start IS NOT INITIAL AND dws-core_start < dws-normal_start.
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-error
                    field    = 'CoreStart'
                    text     = 'Kernzeit muss innerhalb der Normalzeit liegen'
                    msgno    = '015'
          CHANGING  messages = messages ).
      ENDIF.
      IF dws-normal_end IS NOT INITIAL AND dws-core_end > dws-normal_end.
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-error
                    field    = 'CoreEnd'
                    text     = 'Kernzeit muss innerhalb der Normalzeit liegen'
                    msgno    = '015'
          CHANGING  messages = messages ).
      ENDIF.
    ENDIF.

    IF dws-normal_start IS NOT INITIAL AND dws-normal_end IS NOT INITIAL.
      IF dws-work_start IS NOT INITIAL AND dws-normal_start < dws-work_start.
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-error
                    field    = 'NormalStart'
                    text     = 'Normalzeit muss innerhalb des Sollrahmens liegen'
                    msgno    = '016'
          CHANGING  messages = messages ).
      ENDIF.
      IF dws-work_end IS NOT INITIAL AND dws-normal_end > dws-work_end.
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-error
                    field    = 'NormalEnd'
                    text     = 'Normalzeit muss innerhalb des Sollrahmens liegen'
                    msgno    = '016'
          CHANGING  messages = messages ).
      ENDIF.
    ENDIF.

    IF dws-tol_beg_from IS NOT INITIAL AND dws-work_start IS NOT INITIAL.
      IF dws-tol_beg_from < dws-work_start
         OR ( dws-tol_beg_to IS NOT INITIAL AND dws-tol_beg_to > dws-work_end ).
        add_message(
          EXPORTING severity = zif_zazp_validation=>c_severity-warning
                    field    = 'TolBegFrom'
                    text     = 'Anfangstoleranz liegt ausserhalb des Sollrahmens'
                    msgno    = '017'
          CHANGING  messages = messages ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD check_target_hours.
    DATA: lv_frame  TYPE t550a-sollz,
          lv_unpaid TYPE t550p-pdunb,
          lv_net    TYPE t550a-sollz,
          lv_diff   TYPE t550a-sollz.

    IF dws-work_start IS INITIAL OR dws-work_end IS INITIAL OR dws-target_hours IS INITIAL.
      RETURN.
    ENDIF.

    lv_frame = hours_from_times( start_time = dws-work_start end_time = dws-work_end ).

    IF dws-break_id IS NOT INITIAL.
      IF breaks IS NOT INITIAL.
        LOOP AT breaks INTO DATA(ls_b)
          WHERE motpr = dws-dws_grouping AND pamod = dws-break_id.
          lv_unpaid = lv_unpaid + ls_b-pdunb.
        ENDLOOP.
      ELSE.
        SELECT SUM( pdunb ) FROM t550p INTO @lv_unpaid
          WHERE motpr = @dws-dws_grouping
            AND pamod = @dws-break_id.
      ENDIF.
    ENDIF.

    lv_net = lv_frame - lv_unpaid.
    lv_diff = lv_net - dws-target_hours.
    IF lv_diff < 0.
      lv_diff = 0 - lv_diff.
    ENDIF.
    IF lv_diff > '0.50'.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-warning
                  field    = 'TargetHours'
                  text     = |Sollstunden { dws-target_hours } plausibel zu Rahmen-Pausen { lv_net }?|
                  msgno    = '018'
        CHANGING  messages = messages ).
    ENDIF.
  ENDMETHOD.


  METHOD check_break_exists.
    DATA lv_pamod TYPE t550p-pamod.

    IF break_id IS INITIAL.
      RETURN.
    ENDIF.

    IF breaks IS NOT INITIAL.
      READ TABLE breaks WITH KEY motpr = dws_grouping pamod = break_id
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        RETURN.
      ENDIF.
    ENDIF.

    SELECT SINGLE pamod FROM t550p INTO @lv_pamod
      WHERE motpr = @dws_grouping
        AND pamod = @break_id.
    IF sy-subrc <> 0.
      add_message(
        EXPORTING severity = zif_zazp_validation=>c_severity-error
                  field    = 'BreakId'
                  text     = |Pausenplan { break_id } existiert nicht|
                  msgno    = '023'
        CHANGING  messages = messages ).
    ENDIF.
  ENDMETHOD.


  METHOD check_dws_exists.
    DATA lv_tprog TYPE t550a-tprog.

    IF dailies IS NOT INITIAL.
      READ TABLE dailies WITH KEY motpr = dws_grouping tprog = code
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        exists = abap_true.
        RETURN.
      ENDIF.
    ENDIF.

    SELECT SINGLE tprog FROM t550a INTO @lv_tprog
      WHERE motpr = @dws_grouping
        AND tprog = @code.
    exists = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.


  METHOD sum_week_hours.
    DATA: lt_weeks TYPE STANDARD TABLE OF t551a WITH EMPTY KEY,
          lt_codes TYPE STANDARD TABLE OF t550a-tprog WITH EMPTY KEY,
          lv_day   TYPE t550a-tprog,
          lv_sum   TYPE t550a-sollz,
          lv_hours TYPE t550a-sollz,
          ls_week  TYPE t551a.

    IF weeks IS NOT INITIAL.
      lt_weeks = weeks.
    ELSE.
      SELECT * FROM t551a INTO TABLE @lt_weeks
        WHERE motpr = @dws_grouping
          AND zmodn = @period_id
        ORDER BY wonum.
    ENDIF.
    IF lt_weeks IS INITIAL.
      RETURN.
    ENDIF.

    READ TABLE lt_weeks INTO ls_week INDEX 1.
    APPEND ls_week-tprg1 TO lt_codes.
    APPEND ls_week-tprg2 TO lt_codes.
    APPEND ls_week-tprg3 TO lt_codes.
    APPEND ls_week-tprg4 TO lt_codes.
    APPEND ls_week-tprg5 TO lt_codes.
    APPEND ls_week-tprg6 TO lt_codes.
    APPEND ls_week-tprg7 TO lt_codes.

    LOOP AT lt_codes INTO lv_day WHERE table_line IS NOT INITIAL.
      DATA(lv_found) = abap_false.
      CLEAR lv_hours.
      IF dailies IS NOT INITIAL.
        READ TABLE dailies INTO DATA(ls_d)
          WITH KEY motpr = dws_grouping tprog = lv_day.
        IF sy-subrc = 0.
          lv_hours = ls_d-sollz.
          lv_found = abap_true.
        ENDIF.
      ENDIF.
      IF lv_found = abap_false.
        SELECT SINGLE sollz FROM t550a INTO @lv_hours
          WHERE motpr = @dws_grouping
            AND tprog = @lv_day
            AND endda >= @sy-datum
            AND begda <= @sy-datum.
        IF sy-subrc <> 0.
          SELECT SINGLE sollz FROM t550a INTO @lv_hours
            WHERE motpr = @dws_grouping
              AND tprog = @lv_day.
        ENDIF.
      ENDIF.
      lv_sum = lv_sum + lv_hours.
    ENDLOOP.

    hours = lv_sum.
  ENDMETHOD.


  METHOD hours_from_times.
    DATA: lv_start TYPE i,
          lv_end   TYPE i,
          lv_secs  TYPE i.

    lv_start = start_time.
    lv_end   = end_time.
    IF lv_end < lv_start.
      lv_end = lv_end + 86400.
    ENDIF.
    lv_secs = lv_end - lv_start.
    hours = lv_secs / 3600.
  ENDMETHOD.


  METHOD map_daily.
    result = VALUE #(
      dws_grouping = row-motpr
      code         = row-tprog
      variant      = row-varia
      target_hours = row-sollz
      work_start   = row-sobeg
      work_end     = row-soend
      normal_start = row-nobeg
      normal_end   = row-noend
      tol_beg_from = row-btbeg
      tol_beg_to   = row-btend
      tol_end_from = row-etbeg
      tol_end_to   = row-etend
      core_start   = row-k1beg
      core_end     = row-k1end
      break_id     = row-pamod ).
  ENDMETHOD.


  METHOD map_break.
    result = VALUE #(
      dws_grouping = row-motpr
      break_id     = row-pamod
      seq_no       = row-seqno
      start_time   = row-pabeg
      end_time     = row-paend
      paid_hours   = row-pdbez
      unpaid_hours = row-pdunb
      after_hours  = row-stdaz ).
  ENDMETHOD.

ENDCLASS.
