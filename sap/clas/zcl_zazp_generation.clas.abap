CLASS zcl_zazp_generation DEFINITION
  PUBLIC
  CREATE PRIVATE .

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_sim_day,
        calendar_day TYPE dats,
        week_number  TYPE t551a-wonum,
        weekday      TYPE i,
        dws_code     TYPE t550a-tprog,
        target_hours TYPE t550a-sollz,
        is_holiday   TYPE abap_bool,
        day_type     TYPE c LENGTH 1,
      END OF ty_sim_day.
    TYPES ty_sim_days TYPE STANDARD TABLE OF ty_sim_day WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_sim_result,
        month_hours     TYPE t508a-m1std,
        avg_month_hours TYPE t508a-m1std,
        variance        TYPE t508a-m1std,
      END OF ty_sim_result.

    CLASS-METHODS create
      RETURNING
        VALUE(result) TYPE REF TO zcl_zazp_generation.

    METHODS simulate_month
      IMPORTING
        rule_id       TYPE t508a-schkz
        year          TYPE numc4
        month         TYPE numc2
        dws_grouping  TYPE t508a-motpr OPTIONAL
        es_grouping   TYPE t508a-zeity OPTIONAL
        holiday_cal_id TYPE t508a-mofid OPTIONAL
        ps_grouping   TYPE t508a-mosid OPTIONAL
      EXPORTING
        days          TYPE ty_sim_days
        result        TYPE ty_sim_result.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS is_holiday
      IMPORTING
        date          TYPE dats
        calendar_id   TYPE t508a-mofid
      RETURNING
        VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_zazp_generation IMPLEMENTATION.

  METHOD create.
    result = NEW #( ).
  ENDMETHOD.


  METHOD simulate_month.
    DATA ls_rule TYPE t508a.
    DATA lv_first TYPE dats.
    DATA lv_last TYPE dats.
    DATA lv_day TYPE dats.
    DATA ls_sim TYPE ty_sim_day.
    DATA lv_sum TYPE t550a-sollz.
    DATA lt_weeks TYPE STANDARD TABLE OF t551a WITH DEFAULT KEY.
    DATA ls_week TYPE t551a.
    DATA lv_days TYPE i.
    DATA lv_week_i TYPE i.
    DATA lv_wday TYPE i.
    DATA lv_idx TYPE i.
    DATA lv_max_w TYPE i.
    DATA lv_code TYPE t550a-tprog.
    DATA lv_offset TYPE i.
    DATA lv_ref TYPE dats.
    DATA lv_hours TYPE t550a-sollz.

    CLEAR: result, days.
    IF month < 1 OR month > 12.
      RETURN.
    ENDIF.

    IF es_grouping IS NOT INITIAL
       AND holiday_cal_id IS NOT INITIAL
       AND ps_grouping IS NOT INITIAL.
      SELECT SINGLE * FROM t508a INTO @ls_rule
        WHERE schkz = @rule_id
          AND zeity = @es_grouping
          AND mofid = @holiday_cal_id
          AND mosid = @ps_grouping
          AND endda >= @sy-datum
          AND begda <= @sy-datum.
    ELSEIF dws_grouping IS NOT INITIAL.
      SELECT SINGLE * FROM t508a INTO @ls_rule
        WHERE schkz = @rule_id
          AND motpr = @dws_grouping
          AND endda >= @sy-datum
          AND begda <= @sy-datum.
    ENDIF.
    IF ls_rule IS INITIAL.
      SELECT SINGLE * FROM t508a INTO @ls_rule
        WHERE schkz = @rule_id
          AND endda >= @sy-datum
          AND begda <= @sy-datum.
    ENDIF.
    IF ls_rule IS INITIAL.
      SELECT SINGLE * FROM t508a INTO @ls_rule
        WHERE schkz = @rule_id.
    ENDIF.
    IF ls_rule IS INITIAL.
      RETURN.
    ENDIF.

    CONCATENATE year month '01' INTO lv_first.
    CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
      EXPORTING
        day_in            = lv_first
      IMPORTING
        last_day_of_month = lv_last
      EXCEPTIONS
        day_in_no_date    = 1
        OTHERS            = 2.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SELECT * FROM t551a INTO TABLE @lt_weeks
      WHERE motpr = @ls_rule-motpr
        AND zmodn = @ls_rule-zmodn.
    SORT lt_weeks BY wonum.
    IF lt_weeks IS INITIAL.
      RETURN.
    ENDIF.
    lv_max_w = lines( lt_weeks ).

    lv_offset = ls_rule-offbz.
    lv_ref = ls_rule-bzpkt.
    IF lv_ref IS INITIAL.
      lv_ref = ls_rule-begda.
    ENDIF.

    lv_day = lv_first.
    WHILE lv_day <= lv_last.
      CLEAR ls_sim.
      ls_sim-calendar_day = lv_day.
      lv_days = lv_day - lv_ref + lv_offset.
      IF lv_days < 0.
        lv_days = 0.
      ENDIF.
      lv_week_i = lv_days DIV 7.
      lv_wday = ( lv_days MOD 7 ) + 1.
      lv_idx = ( lv_week_i MOD lv_max_w ) + 1.
      READ TABLE lt_weeks INTO ls_week INDEX lv_idx.
      ls_sim-week_number = ls_week-wonum.
      ls_sim-weekday = lv_wday.
      CASE lv_wday.
        WHEN 1. lv_code = ls_week-tprg1.
        WHEN 2. lv_code = ls_week-tprg2.
        WHEN 3. lv_code = ls_week-tprg3.
        WHEN 4. lv_code = ls_week-tprg4.
        WHEN 5. lv_code = ls_week-tprg5.
        WHEN 6. lv_code = ls_week-tprg6.
        WHEN 7. lv_code = ls_week-tprg7.
      ENDCASE.
      ls_sim-dws_code = lv_code.
      CLEAR lv_hours.
      SELECT SINGLE sollz FROM t550a INTO @lv_hours
        WHERE motpr = @ls_rule-motpr
          AND tprog = @lv_code
          AND endda >= @sy-datum
          AND begda <= @sy-datum.
      IF sy-subrc <> 0.
        SELECT SINGLE sollz FROM t550a INTO @lv_hours
          WHERE motpr = @ls_rule-motpr
            AND tprog = @lv_code.
      ENDIF.
      ls_sim-target_hours = lv_hours.
      ls_sim-is_holiday = is_holiday(
        date        = lv_day
        calendar_id = ls_rule-mofid ).
      IF ls_sim-is_holiday = abap_true.
        ls_sim-day_type = '2'.
        ls_sim-target_hours = 0.
      ELSEIF ls_sim-target_hours = 0.
        ls_sim-day_type = '0'.
      ELSE.
        ls_sim-day_type = '1'.
      ENDIF.
      lv_sum = lv_sum + ls_sim-target_hours.
      APPEND ls_sim TO days.
      lv_day = lv_day + 1.
    ENDWHILE.

    result-month_hours = lv_sum.
    result-avg_month_hours = ls_rule-m1std.
    result-variance = lv_sum - ls_rule-m1std.
  ENDMETHOD.


  METHOD is_holiday.
    DATA lv_found TYPE c LENGTH 1.

    result = abap_false.
    IF calendar_id IS INITIAL OR date IS INITIAL.
      RETURN.
    ENDIF.

    CALL FUNCTION 'HOLIDAY_CHECK_AND_GET_INFO'
      EXPORTING
        date                = date
        holiday_calendar_id = calendar_id
      IMPORTING
        holiday_found       = lv_found
      EXCEPTIONS
        OTHERS              = 1.
    IF sy-subrc = 0 AND lv_found = 'X'.
      result = abap_true.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
