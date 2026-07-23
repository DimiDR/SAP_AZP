CLASS lhc_rule DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR rule
      RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR rule
      RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR rule
      RESULT result.
    METHODS valweeksum FOR VALIDATE ON SAVE
      IMPORTING keys FOR rule~valweeksum.
    METHODS valtimeframe FOR VALIDATE ON SAVE
      IMPORTING keys FOR rule~valtimeframe.
    METHODS valbreaks FOR VALIDATE ON SAVE
      IMPORTING keys FOR rule~valbreaks.
    METHODS copyastemplate FOR MODIFY
      IMPORTING keys FOR ACTION rule~copyastemplate
      RESULT result.
    METHODS simulatemonth FOR MODIFY
      IMPORTING keys FOR ACTION rule~simulatemonth
      RESULT result.
    METHODS createtransportrequest FOR MODIFY
      IMPORTING keys FOR ACTION rule~createtransportrequest
      RESULT result.
    METHODS setpreferredtransport FOR MODIFY
      IMPORTING keys FOR ACTION rule~setpreferredtransport.
    METHODS listtransportrequests FOR MODIFY
      IMPORTING keys FOR ACTION rule~listtransportrequests
      RESULT result.
    METHODS reademployeeassignment FOR MODIFY
      IMPORTING keys FOR ACTION rule~reademployeeassignment
      RESULT result.
    METHODS assignemployee FOR MODIFY
      IMPORTING keys FOR ACTION rule~assignemployee
      RESULT result.
ENDCLASS.

CLASS lhc_rule IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%action-edit = if_abap_behv=>mk-on.
      result-%action-edit = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #(
        %tky    = ls_key-%tky
        %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed
        %action-edit           = if_abap_behv=>auth-allowed
        %action-copyastemplate = if_abap_behv=>auth-allowed
        %action-simulatemonth  = if_abap_behv=>auth-allowed
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #(
        %tky = ls_key-%tky
        %action-copyastemplate = if_abap_behv=>fc-o-enabled
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD valweeksum.
    DATA lo_val TYPE REF TO zcl_zazp_validation.
    DATA ls_ctx TYPE zif_zazp_validation=>ty_rule_ctx.
    DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
    DATA ls_week TYPE t551a.

    lo_val = NEW #( ).
    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY rule
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_rules).

    LOOP AT lt_rules INTO DATA(ls_rule).
      CLEAR: ls_ctx, lt_msg.
      ls_ctx-rule-mandt = sy-mandt.
      ls_ctx-rule-zeity = ls_rule-esgrouping.
      ls_ctx-rule-mofid = ls_rule-holidaycalendarid.
      ls_ctx-rule-mosid = ls_rule-psgrouping.
      ls_ctx-rule-schkz = ls_rule-ruleid.
      ls_ctx-rule-endda = ls_rule-validto.
      ls_ctx-rule-begda = ls_rule-validfrom.
      ls_ctx-rule-motpr = ls_rule-dwsgrouping.
      ls_ctx-rule-zmodn = ls_rule-periodid.
      ls_ctx-rule-wostd = ls_rule-avgweekhours.

      READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
        ENTITY rule BY \_weeks
        ALL FIELDS WITH VALUE #( ( %tky = ls_rule-%tky ) )
        RESULT DATA(lt_weeks).

      LOOP AT lt_weeks INTO DATA(ls_w).
        CLEAR ls_week.
        ls_week-motpr = COND #( WHEN ls_w-dwsgrouping IS NOT INITIAL THEN ls_w-dwsgrouping ELSE ls_rule-dwsgrouping ).
        ls_week-zmodn = COND #( WHEN ls_w-periodid IS NOT INITIAL THEN ls_w-periodid ELSE ls_rule-periodid ).
        ls_week-wonum = ls_w-weeknumber.
        ls_week-tprg1 = ls_w-monday.
        ls_week-tprg2 = ls_w-tuesday.
        ls_week-tprg3 = ls_w-wednesday.
        ls_week-tprg4 = ls_w-thursday.
        ls_week-tprg5 = ls_w-friday.
        ls_week-tprg6 = ls_w-saturday.
        ls_week-tprg7 = ls_w-sunday.
        APPEND ls_week TO ls_ctx-weeks.
      ENDLOOP.

      IF ls_ctx-weeks IS INITIAL.
        SELECT * FROM t551a INTO TABLE @ls_ctx-weeks
          WHERE motpr = @ls_ctx-rule-motpr
            AND zmodn = @ls_ctx-rule-zmodn
          ORDER BY wonum.
      ENDIF.

      lt_msg = lo_val->zif_zazp_validation~validate_rule_ctx( ls_ctx ).
      LOOP AT lt_msg INTO DATA(ls_msg) WHERE severity = 'E'.
        APPEND VALUE #( %tky = ls_rule-%tky ) TO failed-rule.
        APPEND VALUE #(
          %tky = ls_rule-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = ls_msg-text )
        ) TO reported-rule.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD valtimeframe.
    DATA lo_val TYPE REF TO zcl_zazp_validation.
    DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
    DATA ls_daily TYPE zif_zazp_validation=>ty_daily.

    lo_val = NEW #( ).
    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY rule
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_rules).

    LOOP AT lt_rules INTO DATA(ls_rule).
      READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
        ENTITY rule BY \_dailyschedules
        ALL FIELDS WITH VALUE #( ( %tky = ls_rule-%tky ) )
        RESULT DATA(lt_dailies).

      IF lt_dailies IS INITIAL.
        SELECT * FROM t550a INTO TABLE @DATA(lt_t550a)
          WHERE motpr = @ls_rule-dwsgrouping.
        LOOP AT lt_t550a INTO DATA(ls_t550a).
          ls_daily = VALUE #(
            dws_grouping = ls_t550a-motpr
            code         = ls_t550a-tprog
            variant      = ls_t550a-varia
            target_hours = ls_t550a-sollz
            work_start   = ls_t550a-sobeg
            work_end     = ls_t550a-soend
            normal_start = ls_t550a-nobeg
            normal_end   = ls_t550a-noend
            tol_beg_from = ls_t550a-btbeg
            tol_beg_to   = ls_t550a-btend
            tol_end_from = ls_t550a-etbeg
            tol_end_to   = ls_t550a-etend
            core_start   = ls_t550a-k1beg
            core_end     = ls_t550a-k1end
            break_id     = ls_t550a-pamod ).
          lt_msg = lo_val->zif_zazp_validation~validate_daily( ls_daily ).
          LOOP AT lt_msg INTO DATA(ls_msg) WHERE severity = 'E'.
            APPEND VALUE #( %tky = ls_rule-%tky ) TO failed-rule.
            APPEND VALUE #(
              %tky = ls_rule-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = ls_msg-text )
            ) TO reported-rule.
          ENDLOOP.
        ENDLOOP.
      ELSE.
        LOOP AT lt_dailies INTO DATA(ls_d).
          ls_daily = VALUE #(
            dws_grouping = COND #( WHEN ls_d-dwsgrouping IS NOT INITIAL THEN ls_d-dwsgrouping ELSE ls_rule-dwsgrouping )
            code         = ls_d-code
            variant      = ls_d-variant
            target_hours = ls_d-targethours
            work_start   = ls_d-workstart
            work_end     = ls_d-workend
            normal_start = ls_d-normalstart
            normal_end   = ls_d-normalend
            tol_beg_from = ls_d-tolbegfrom
            tol_beg_to   = ls_d-tolbegto
            tol_end_from = ls_d-tolendfrom
            tol_end_to   = ls_d-tolendto
            core_start   = ls_d-corestart
            core_end     = ls_d-coreend
            break_id     = ls_d-breakid ).
          lt_msg = lo_val->zif_zazp_validation~validate_daily( ls_daily ).
          LOOP AT lt_msg INTO ls_msg WHERE severity = 'E'.
            APPEND VALUE #( %tky = ls_rule-%tky ) TO failed-rule.
            APPEND VALUE #(
              %tky = ls_rule-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = ls_msg-text )
            ) TO reported-rule.
          ENDLOOP.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD valbreaks.
    DATA lo_val TYPE REF TO zcl_zazp_validation.
    DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
    DATA ls_brk TYPE zif_zazp_validation=>ty_break.

    lo_val = NEW #( ).
    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY rule
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_rules).

    LOOP AT lt_rules INTO DATA(ls_rule).
      READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
        ENTITY rule BY \_breakschedules
        ALL FIELDS WITH VALUE #( ( %tky = ls_rule-%tky ) )
        RESULT DATA(lt_breaks).

      IF lt_breaks IS INITIAL.
        SELECT * FROM t550p INTO TABLE @DATA(lt_t550p)
          WHERE motpr = @ls_rule-dwsgrouping.
        LOOP AT lt_t550p INTO DATA(ls_t550p).
          ls_brk = VALUE #(
            dws_grouping = ls_t550p-motpr
            break_id     = ls_t550p-pamod
            seq_no       = ls_t550p-seqno
            start_time   = ls_t550p-pabeg
            end_time     = ls_t550p-paend
            paid_hours   = ls_t550p-pdbez
            unpaid_hours = ls_t550p-pdunb
            after_hours  = ls_t550p-stdaz ).
          lt_msg = lo_val->zif_zazp_validation~validate_break( brk = ls_brk ).
          LOOP AT lt_msg INTO DATA(ls_msg) WHERE severity = 'E'.
            APPEND VALUE #( %tky = ls_rule-%tky ) TO failed-rule.
            APPEND VALUE #(
              %tky = ls_rule-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = ls_msg-text )
            ) TO reported-rule.
          ENDLOOP.
        ENDLOOP.
      ELSE.
        LOOP AT lt_breaks INTO DATA(ls_b).
          ls_brk = VALUE #(
            dws_grouping = COND #( WHEN ls_b-dwsgrouping IS NOT INITIAL THEN ls_b-dwsgrouping ELSE ls_rule-dwsgrouping )
            break_id     = ls_b-breakid
            seq_no       = ls_b-seqno
            start_time   = ls_b-starttime
            end_time     = ls_b-endtime
            paid_hours   = ls_b-paidhours
            unpaid_hours = ls_b-unpaidhours
            after_hours  = ls_b-afterhours ).
          lt_msg = lo_val->zif_zazp_validation~validate_break( brk = ls_brk ).
          LOOP AT lt_msg INTO ls_msg WHERE severity = 'E'.
            APPEND VALUE #( %tky = ls_rule-%tky ) TO failed-rule.
            APPEND VALUE #(
              %tky = ls_rule-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = ls_msg-text )
            ) TO reported-rule.
          ENDLOOP.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD copyastemplate.
    DATA lo_persist TYPE REF TO zcl_zazp_persist.
    DATA lo_tr TYPE REF TO zcl_zazp_transport.
    DATA ls_data TYPE zcl_zazp_persist=>ty_rule_data.
    DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
    DATA lv_trkorr TYPE e070-trkorr.

    lo_persist = NEW #( ).
    lo_tr = NEW #( ).

    TRY.
        lv_trkorr = lo_tr->ensure_customizing_request(
          description      = 'AZP Copy Work Schedule'
          preferred_trkorr = zcl_zazp_transport=>get_preferred_request( ) ).
      CATCH cx_sy_file_io.
        LOOP AT keys INTO DATA(ls_fail).
          APPEND VALUE #( %tky = ls_fail-%tky ) TO failed-rule.
          APPEND VALUE #(
            %tky = ls_fail-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Kein offener Customizing-Auftrag verfuegbar' )
          ) TO reported-rule.
        ENDLOOP.
        RETURN.
    ENDTRY.

    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY rule
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_rules).

    LOOP AT keys INTO DATA(ls_key).
      READ TABLE lt_rules INTO DATA(ls_rule)
        WITH KEY esgrouping = ls_key-esgrouping
                 holidaycalendarid = ls_key-holidaycalendarid
                 psgrouping = ls_key-psgrouping
                 ruleid = ls_key-ruleid
                 validto = ls_key-validto.
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-rule.
        CONTINUE.
      ENDIF.

      IF ls_key-%param-newruleid IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-rule.
        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Neue Regel-ID ist Pflicht' )
        ) TO reported-rule.
        CONTINUE.
      ENDIF.

      CLEAR: ls_data, lt_msg.
      ls_data-rule-mandt = sy-mandt.
      ls_data-rule-zeity = ls_rule-esgrouping.
      ls_data-rule-mofid = ls_rule-holidaycalendarid.
      ls_data-rule-mosid = ls_rule-psgrouping.
      ls_data-rule-schkz = ls_key-%param-newruleid.
      ls_data-rule-endda = COND #(
        WHEN ls_key-%param-newvalidto IS NOT INITIAL
        THEN ls_key-%param-newvalidto
        ELSE ls_rule-validto ).
      ls_data-rule-begda = COND #(
        WHEN ls_key-%param-newvalidfrom IS NOT INITIAL
        THEN ls_key-%param-newvalidfrom
        ELSE ls_rule-validfrom ).
      ls_data-rule-motpr = ls_rule-dwsgrouping.
      ls_data-rule-zmodn = ls_rule-periodid.
      ls_data-rule-tgstd = ls_rule-avgdayhours.
      ls_data-rule-wostd = ls_rule-avgweekhours.
      ls_data-rule-m1std = ls_rule-avgmonthhours.
      ls_data-rule-jrstd = ls_rule-avgyearhours.
      ls_data-rule-wkwdy = ls_rule-workdaysperweek.
      ls_data-rule-bzpkt = ls_rule-referencedate.
      ls_data-rule-offbz = ls_rule-offsetdays.

      SELECT * FROM t551a INTO TABLE @ls_data-weeks
        WHERE motpr = @ls_data-rule-motpr
          AND zmodn = @ls_data-rule-zmodn.
      SELECT * FROM t550a INTO TABLE @ls_data-dailies
        WHERE motpr = @ls_data-rule-motpr.
      SELECT * FROM t550p INTO TABLE @ls_data-breaks
        WHERE motpr = @ls_data-rule-motpr.

      TRY.
          lt_msg = lo_persist->save_rule( data = ls_data trkorr = lv_trkorr ).
        CATCH cx_sy_file_io.
          APPEND VALUE #( %tky = ls_key-%tky ) TO failed-rule.
          APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Kopieren/Transport fehlgeschlagen' )
          ) TO reported-rule.
          CONTINUE.
      ENDTRY.

      LOOP AT lt_msg INTO DATA(ls_msg) WHERE severity = 'E'.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-rule.
        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = ls_msg-text )
        ) TO reported-rule.
      ENDLOOP.
      IF line_exists( lt_msg[ severity = 'E' ] ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %cid = ls_key-%cid_ref
        esgrouping        = ls_data-rule-zeity
        holidaycalendarid = ls_data-rule-mofid
        psgrouping        = ls_data-rule-mosid
        ruleid            = ls_data-rule-schkz
        validto           = ls_data-rule-endda
      ) TO mapped-rule.

      APPEND VALUE #(
        %tky-esgrouping        = ls_data-rule-zeity
        %tky-holidaycalendarid = ls_data-rule-mofid
        %tky-psgrouping        = ls_data-rule-mosid
        %tky-ruleid            = ls_data-rule-schkz
        %tky-validto           = ls_data-rule-endda
        %param-esgrouping        = ls_data-rule-zeity
        %param-holidaycalendarid = ls_data-rule-mofid
        %param-psgrouping        = ls_data-rule-mosid
        %param-ruleid            = ls_data-rule-schkz
        %param-validto           = ls_data-rule-endda
        %param-dwsgrouping       = ls_data-rule-motpr
        %param-periodid          = ls_data-rule-zmodn
        %param-validfrom         = ls_data-rule-begda
        %param-avgdayhours       = ls_data-rule-tgstd
        %param-avgweekhours      = ls_data-rule-wostd
        %param-avgmonthhours     = ls_data-rule-m1std
        %param-avgyearhours      = ls_data-rule-jrstd
        %param-workdaysperweek   = ls_data-rule-wkwdy
        %param-referencedate     = ls_data-rule-bzpkt
        %param-offsetdays        = ls_data-rule-offbz
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD simulatemonth.
    DATA lo_gen TYPE REF TO zcl_zazp_generation.
    DATA lt_days TYPE zcl_zazp_generation=>ty_sim_days.
    DATA ls_result TYPE zcl_zazp_generation=>ty_sim_result.
    DATA lv_year TYPE numc4.
    DATA lv_month TYPE numc2.

    lo_gen = zcl_zazp_generation=>create( ).

    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY rule
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_rules).

    LOOP AT keys INTO DATA(ls_key).
      READ TABLE lt_rules INTO DATA(ls_rule)
        WITH KEY esgrouping = ls_key-esgrouping
                 holidaycalendarid = ls_key-holidaycalendarid
                 psgrouping = ls_key-psgrouping
                 ruleid = ls_key-ruleid
                 validto = ls_key-validto.
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-rule.
        CONTINUE.
      ENDIF.

      lv_year  = ls_key-%param-simyear.
      lv_month = ls_key-%param-simmonth.
      IF lv_year IS INITIAL OR lv_month IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-rule.
        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Jahr und Monat sind Pflicht' )
        ) TO reported-rule.
        CONTINUE.
      ENDIF.

      CLEAR: lt_days, ls_result.
      lo_gen->simulate_month(
        EXPORTING
          rule_id        = ls_rule-ruleid
          year           = lv_year
          month          = lv_month
          dws_grouping   = ls_rule-dwsgrouping
          es_grouping    = ls_rule-esgrouping
          holiday_cal_id = ls_rule-holidaycalendarid
          ps_grouping    = ls_rule-psgrouping
        IMPORTING
          days           = lt_days
          result         = ls_result ).

      IF lt_days IS INITIAL.
        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-warning
                   text     = 'Keine Simulationstage ermittelt' )
        ) TO reported-rule.
      ENDIF.

      LOOP AT lt_days INTO DATA(ls_day).
        APPEND VALUE #(
          %tky   = ls_key-%tky
          %param = VALUE #(
            calendarday  = ls_day-calendar_day
            weeknumber   = ls_day-week_number
            weekday      = ls_day-weekday
            dwscode      = ls_day-dws_code
            targethours  = ls_day-target_hours
            isholiday    = xsdbool( ls_day-is_holiday = abap_true )
            daytype      = ls_day-day_type )
        ) TO result.
      ENDLOOP.

      APPEND VALUE #(
        %tky = ls_key-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Simulation { lv_year }/{ lv_month }: { ls_result-month_hours } h (Ø { ls_result-avg_month_hours }, Diff { ls_result-variance })| )
      ) TO reported-rule.
    ENDLOOP.
  ENDMETHOD.

  METHOD createtransportrequest.
    DATA lo_tr TYPE REF TO zcl_zazp_transport.
    DATA lv_trkorr TYPE e070-trkorr.
    DATA lv_text TYPE e07t-as4text.

    lo_tr = NEW #( ).

    LOOP AT keys INTO DATA(ls_key).
      lv_text = ls_key-%param-transportdescription.
      IF lv_text IS INITIAL.
        lv_text = 'AZP Customizing'.
      ENDIF.

      TRY.
          lv_trkorr = lo_tr->create_customizing_request( lv_text ).
          zcl_zazp_transport=>set_preferred_request( lv_trkorr ).
          APPEND VALUE #(
            %cid   = ls_key-%cid
            %param = VALUE #(
              transportrequest     = lv_trkorr
              transportdescription = lv_text
              transportowner       = sy-uname )
          ) TO result.
          APPEND VALUE #(
            %cid = ls_key-%cid
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-success
                     text     = |Transportauftrag { lv_trkorr } angelegt| )
          ) TO reported-rule.
        CATCH cx_sy_file_io.
          APPEND VALUE #( %cid = ls_key-%cid ) TO failed-rule.
          APPEND VALUE #(
            %cid = ls_key-%cid
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Transportauftrag konnte nicht angelegt werden' )
          ) TO reported-rule.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD setpreferredtransport.
    DATA lo_tr TYPE REF TO zcl_zazp_transport.
    DATA lv_trkorr TYPE e070-trkorr.

    lo_tr = NEW #( ).

    LOOP AT keys INTO DATA(ls_key).
      lv_trkorr = ls_key-%param-transportrequest.
      IF lv_trkorr IS INITIAL OR lo_tr->is_request_modifiable( lv_trkorr ) = abap_false.
        APPEND VALUE #( %cid = ls_key-%cid ) TO failed-rule.
        APPEND VALUE #(
          %cid = ls_key-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Gueltiger offener Customizing-Auftrag erforderlich' )
        ) TO reported-rule.
        CONTINUE.
      ENDIF.

      zcl_zazp_transport=>set_preferred_request( lv_trkorr ).
      APPEND VALUE #(
        %cid = ls_key-%cid
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = |Transportauftrag { lv_trkorr } ausgewaehlt| )
      ) TO reported-rule.
    ENDLOOP.
  ENDMETHOD.

  METHOD listtransportrequests.
    DATA lo_tr TYPE REF TO zcl_zazp_transport.
    DATA lt_req TYPE zcl_zazp_transport=>ty_requests.

    lo_tr = NEW #( ).
    lt_req = lo_tr->list_open_customizing_requests( ).

    LOOP AT keys INTO DATA(ls_key).
      LOOP AT lt_req INTO DATA(ls_req).
        APPEND VALUE #(
          %cid   = ls_key-%cid
          %param = VALUE #(
            transportrequest     = ls_req-trkorr
            transportdescription = ls_req-as4text
            transportowner       = ls_req-as4user )
        ) TO result.
      ENDLOOP.
      IF lt_req IS INITIAL.
        APPEND VALUE #(
          %cid = ls_key-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-information
                   text     = 'Keine offenen Customizing-Auftraege' )
        ) TO reported-rule.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD reademployeeassignment.
    DATA lo_asg TYPE REF TO zcl_zazp_assignment.
    DATA ls_asg TYPE zcl_zazp_assignment=>ty_assignment.
    DATA lv_key_date TYPE d.

    lo_asg = NEW #( ).

    LOOP AT keys INTO DATA(ls_key).
      lv_key_date = ls_key-%param-keydate.
      IF lv_key_date IS INITIAL.
        lv_key_date = sy-datum.
      ENDIF.

      IF ls_key-%param-pernr IS INITIAL.
        APPEND VALUE #( %cid = ls_key-%cid ) TO failed-rule.
        APPEND VALUE #(
          %cid = ls_key-%cid
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Personalnummer ist Pflicht' )
        ) TO reported-rule.
        CONTINUE.
      ENDIF.

      ls_asg = lo_asg->read_current(
        pernr    = ls_key-%param-pernr
        key_date = lv_key_date ).

      APPEND VALUE #(
        %cid   = ls_key-%cid
        %param = VALUE #(
          pernr         = ls_asg-pernr
          ruleid        = ls_asg-rule_id
          validfrom     = ls_asg-valid_from
          validto       = ls_asg-valid_to
          employmentpct = ls_asg-employment_pct
          weeklyhours   = ls_asg-weekly_hours
          success       = xsdbool( ls_asg-rule_id IS NOT INITIAL )
          messagetext   = COND #(
            WHEN ls_asg-rule_id IS INITIAL
            THEN |Keine IT0007-Zuordnung fuer { ls_key-%param-pernr } am { lv_key_date DATE = USER }|
            ELSE |Aktuell: Regel { ls_asg-rule_id }| ) )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD assignemployee.
    DATA lo_asg TYPE REF TO zcl_zazp_assignment.
    DATA ls_asg TYPE zcl_zazp_assignment=>ty_assignment.
    DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
    DATA lv_ok TYPE abap_bool.
    DATA lv_text TYPE c LENGTH 255.

    lo_asg = NEW #( ).

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: ls_asg, lt_msg, lv_ok, lv_text.
      ls_asg-pernr          = ls_key-%param-pernr.
      ls_asg-rule_id        = ls_key-%param-ruleid.
      ls_asg-valid_from     = ls_key-%param-validfrom.
      ls_asg-valid_to       = ls_key-%param-validto.
      ls_asg-employment_pct = ls_key-%param-employmentpct.
      ls_asg-weekly_hours   = ls_key-%param-weeklyhours.

      lt_msg = lo_asg->assign_rule( ls_asg ).

      LOOP AT lt_msg INTO DATA(ls_msg).
        DATA(lv_sev) = COND #(
          WHEN ls_msg-severity = zif_zazp_validation=>c_severity-error
            THEN if_abap_behv_message=>severity-error
          WHEN ls_msg-severity = zif_zazp_validation=>c_severity-warning
            THEN if_abap_behv_message=>severity-warning
          ELSE if_abap_behv_message=>severity-success ).
        APPEND VALUE #(
          %cid = ls_key-%cid
          %msg = new_message_with_text(
                   severity = lv_sev
                   text     = CONV string( ls_msg-text ) )
        ) TO reported-rule.
        IF ls_msg-severity = zif_zazp_validation=>c_severity-error.
          lv_ok = abap_false.
          lv_text = ls_msg-text.
        ELSEIF lv_text IS INITIAL.
          lv_ok = abap_true.
          lv_text = ls_msg-text.
        ENDIF.
      ENDLOOP.

      IF line_exists( lt_msg[ severity = zif_zazp_validation=>c_severity-error ] ).
        lv_ok = abap_false.
        APPEND VALUE #( %cid = ls_key-%cid ) TO failed-rule.
      ELSE.
        lv_ok = abap_true.
      ENDIF.

      APPEND VALUE #(
        %cid   = ls_key-%cid
        %param = VALUE #(
          pernr         = ls_asg-pernr
          ruleid        = ls_asg-rule_id
          validfrom     = COND #( WHEN ls_asg-valid_from IS NOT INITIAL
                                  THEN ls_asg-valid_from ELSE sy-datum )
          validto       = COND #( WHEN ls_asg-valid_to IS NOT INITIAL
                                  THEN ls_asg-valid_to ELSE '99991231' )
          employmentpct = ls_asg-employment_pct
          weeklyhours   = ls_asg-weekly_hours
          success       = lv_ok
          messagetext   = lv_text )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_week DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS fillweekfromparent FOR DETERMINE ON MODIFY
      IMPORTING keys FOR week~fillweekfromparent.
ENDCLASS.

CLASS lhc_week IMPLEMENTATION.
  METHOD fillweekfromparent.
    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY week
      FIELDS ( dwsgrouping periodid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_weeks).

    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY week BY \_rule
      FIELDS ( dwsgrouping periodid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_rules)
      LINK DATA(lt_link).

    LOOP AT lt_weeks INTO DATA(ls_week).
      READ TABLE lt_link INTO DATA(ls_link) WITH KEY source-%tky = ls_week-%tky.
      CHECK sy-subrc = 0.
      READ TABLE lt_rules INTO DATA(ls_rule) WITH KEY %tky = ls_link-target-%tky.
      CHECK sy-subrc = 0.
      MODIFY ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
        ENTITY week
        UPDATE FIELDS ( dwsgrouping periodid )
        WITH VALUE #( (
          %tky         = ls_week-%tky
          dwsgrouping  = ls_rule-dwsgrouping
          periodid     = ls_rule-periodid ) ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_daily DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS filldailyfromparent FOR DETERMINE ON MODIFY
      IMPORTING keys FOR daily~filldailyfromparent.
ENDCLASS.

CLASS lhc_daily IMPLEMENTATION.
  METHOD filldailyfromparent.
    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY daily
      FIELDS ( dwsgrouping )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_dailies).

    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY daily BY \_rule
      FIELDS ( dwsgrouping )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_rules)
      LINK DATA(lt_link).

    LOOP AT lt_dailies INTO DATA(ls_daily).
      READ TABLE lt_link INTO DATA(ls_link) WITH KEY source-%tky = ls_daily-%tky.
      CHECK sy-subrc = 0.
      READ TABLE lt_rules INTO DATA(ls_rule) WITH KEY %tky = ls_link-target-%tky.
      CHECK sy-subrc = 0.
      MODIFY ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
        ENTITY daily
        UPDATE FIELDS ( dwsgrouping )
        WITH VALUE #( (
          %tky        = ls_daily-%tky
          dwsgrouping = ls_rule-dwsgrouping ) ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_break DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS fillbreakfromparent FOR DETERMINE ON MODIFY
      IMPORTING keys FOR break~fillbreakfromparent.
ENDCLASS.

CLASS lhc_break IMPLEMENTATION.
  METHOD fillbreakfromparent.
    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY break
      FIELDS ( dwsgrouping )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_breaks).

    READ ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
      ENTITY break BY \_rule
      FIELDS ( dwsgrouping )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_rules)
      LINK DATA(lt_link).

    LOOP AT lt_breaks INTO DATA(ls_break).
      READ TABLE lt_link INTO DATA(ls_link) WITH KEY source-%tky = ls_break-%tky.
      CHECK sy-subrc = 0.
      READ TABLE lt_rules INTO DATA(ls_rule) WITH KEY %tky = ls_link-target-%tky.
      CHECK sy-subrc = 0.
      MODIFY ENTITIES OF zi_zazp_workschedulerule IN LOCAL MODE
        ENTITY break
        UPDATE FIELDS ( dwsgrouping )
        WITH VALUE #( (
          %tky        = ls_break-%tky
          dwsgrouping = ls_rule-dwsgrouping ) ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_zazp_workschedulerule DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zi_zazp_workschedulerule IMPLEMENTATION.

  METHOD save_modified.
    DATA lo_persist TYPE REF TO zcl_zazp_persist.
    DATA lo_tr TYPE REF TO zcl_zazp_transport.
    DATA ls_data TYPE zcl_zazp_persist=>ty_rule_data.
    DATA lv_trkorr TYPE e070-trkorr.
    DATA lt_msg TYPE zif_zazp_validation=>ty_messages.
    DATA lv_transport_ok TYPE abap_bool VALUE abap_true.
    DATA ls_week TYPE t551a.
    DATA ls_daily TYPE t550a.
    DATA ls_break TYPE t550p.

    lo_persist = NEW #( ).
    lo_tr = NEW #( ).

    TRY.
        lv_trkorr = lo_tr->ensure_customizing_request(
          description      = 'AZP Work Schedule Customizing'
          preferred_trkorr = zcl_zazp_transport=>get_preferred_request( ) ).
      CATCH cx_sy_file_io.
        lv_transport_ok = abap_false.
    ENDTRY.

    IF lv_transport_ok = abap_false.
      LOOP AT create-rule INTO DATA(ls_c_fail).
        APPEND VALUE #(
          %key = ls_c_fail-%key
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Kein offener Customizing-Auftrag verfuegbar' )
        ) TO reported-rule.
      ENDLOOP.
      RETURN.
    ENDIF.

    " Collect child changes into rule payloads / direct MODIFY
    LOOP AT create-week INTO DATA(ls_cw).
      CLEAR ls_week.
      ls_week-mandt = sy-mandt.
      ls_week-motpr = ls_cw-dwsgrouping.
      ls_week-zmodn = ls_cw-periodid.
      ls_week-wonum = ls_cw-weeknumber.
      ls_week-tprg1 = ls_cw-monday.
      ls_week-tprg2 = ls_cw-tuesday.
      ls_week-tprg3 = ls_cw-wednesday.
      ls_week-tprg4 = ls_cw-thursday.
      ls_week-tprg5 = ls_cw-friday.
      ls_week-tprg6 = ls_cw-saturday.
      ls_week-tprg7 = ls_cw-sunday.
      MODIFY t551a FROM ls_week.
      lo_tr->record_table_keys(
        trkorr = lv_trkorr
        keys   = VALUE #( ( tabname = 'T551A' tabkey = |{ sy-mandt }{ ls_week-motpr }{ ls_week-zmodn }{ ls_week-wonum }| ) ) ).
    ENDLOOP.

    LOOP AT update-week INTO DATA(ls_uw).
      CLEAR ls_week.
      ls_week-mandt = sy-mandt.
      ls_week-motpr = ls_uw-dwsgrouping.
      ls_week-zmodn = ls_uw-periodid.
      ls_week-wonum = ls_uw-weeknumber.
      ls_week-tprg1 = ls_uw-monday.
      ls_week-tprg2 = ls_uw-tuesday.
      ls_week-tprg3 = ls_uw-wednesday.
      ls_week-tprg4 = ls_uw-thursday.
      ls_week-tprg5 = ls_uw-friday.
      ls_week-tprg6 = ls_uw-saturday.
      ls_week-tprg7 = ls_uw-sunday.
      IF ls_week-motpr IS INITIAL OR ls_week-zmodn IS INITIAL.
        SELECT SINGLE motpr, zmodn FROM t508a INTO ( @ls_week-motpr, @ls_week-zmodn )
          WHERE zeity = @ls_uw-esgrouping
            AND mofid = @ls_uw-holidaycalendarid
            AND mosid = @ls_uw-psgrouping
            AND schkz = @ls_uw-ruleid
            AND endda = @ls_uw-validto.
      ENDIF.
      MODIFY t551a FROM ls_week.
      lo_tr->record_table_keys(
        trkorr = lv_trkorr
        keys   = VALUE #( ( tabname = 'T551A' tabkey = |{ sy-mandt }{ ls_week-motpr }{ ls_week-zmodn }{ ls_week-wonum }| ) ) ).
    ENDLOOP.

    LOOP AT delete-week INTO DATA(ls_dw).
      DATA lv_motpr TYPE t551a-motpr.
      DATA lv_zmodn TYPE t551a-zmodn.
      CLEAR: lv_motpr, lv_zmodn.
      SELECT SINGLE motpr, zmodn FROM t508a INTO ( @lv_motpr, @lv_zmodn )
        WHERE zeity = @ls_dw-esgrouping
          AND mofid = @ls_dw-holidaycalendarid
          AND mosid = @ls_dw-psgrouping
          AND schkz = @ls_dw-ruleid
          AND endda = @ls_dw-validto.
      DELETE FROM t551a
        WHERE motpr = @lv_motpr
          AND zmodn = @lv_zmodn
          AND wonum = @ls_dw-weeknumber.
      lo_tr->record_table_keys(
        trkorr = lv_trkorr
        keys   = VALUE #( ( tabname = 'T551A' tabkey = |{ sy-mandt }{ lv_motpr }{ lv_zmodn }{ ls_dw-weeknumber }| ) ) ).
    ENDLOOP.

    LOOP AT create-daily INTO DATA(ls_cd).
      CLEAR ls_daily.
      ls_daily-mandt = sy-mandt.
      ls_daily-motpr = ls_cd-dwsgrouping.
      ls_daily-tprog = ls_cd-code.
      ls_daily-varia = ls_cd-variant.
      ls_daily-endda = ls_cd-validto.
      ls_daily-begda = ls_cd-validfrom.
      ls_daily-sollz = ls_cd-targethours.
      ls_daily-sobeg = ls_cd-workstart.
      ls_daily-soend = ls_cd-workend.
      ls_daily-nobeg = ls_cd-normalstart.
      ls_daily-noend = ls_cd-normalend.
      ls_daily-btbeg = ls_cd-tolbegfrom.
      ls_daily-btend = ls_cd-tolbegto.
      ls_daily-etbeg = ls_cd-tolendfrom.
      ls_daily-etend = ls_cd-tolendto.
      ls_daily-k1beg = ls_cd-corestart.
      ls_daily-k1end = ls_cd-coreend.
      ls_daily-pamod = ls_cd-breakid.
      IF ls_daily-motpr IS INITIAL.
        SELECT SINGLE motpr FROM t508a INTO @ls_daily-motpr
          WHERE zeity = @ls_cd-esgrouping
            AND mofid = @ls_cd-holidaycalendarid
            AND mosid = @ls_cd-psgrouping
            AND schkz = @ls_cd-ruleid
            AND endda = @ls_cd-rulevalidto.
      ENDIF.
      MODIFY t550a FROM ls_daily.
    ENDLOOP.

    LOOP AT update-daily INTO DATA(ls_ud).
      CLEAR ls_daily.
      ls_daily-mandt = sy-mandt.
      ls_daily-motpr = ls_ud-dwsgrouping.
      ls_daily-tprog = ls_ud-code.
      ls_daily-varia = ls_ud-variant.
      ls_daily-endda = ls_ud-validto.
      ls_daily-begda = ls_ud-validfrom.
      ls_daily-sollz = ls_ud-targethours.
      ls_daily-sobeg = ls_ud-workstart.
      ls_daily-soend = ls_ud-workend.
      ls_daily-nobeg = ls_ud-normalstart.
      ls_daily-noend = ls_ud-normalend.
      ls_daily-btbeg = ls_ud-tolbegfrom.
      ls_daily-btend = ls_ud-tolbegto.
      ls_daily-etbeg = ls_ud-tolendfrom.
      ls_daily-etend = ls_ud-tolendto.
      ls_daily-k1beg = ls_ud-corestart.
      ls_daily-k1end = ls_ud-coreend.
      ls_daily-pamod = ls_ud-breakid.
      IF ls_daily-motpr IS INITIAL.
        SELECT SINGLE motpr FROM t508a INTO @ls_daily-motpr
          WHERE zeity = @ls_ud-esgrouping
            AND mofid = @ls_ud-holidaycalendarid
            AND mosid = @ls_ud-psgrouping
            AND schkz = @ls_ud-ruleid
            AND endda = @ls_ud-rulevalidto.
      ENDIF.
      MODIFY t550a FROM ls_daily.
    ENDLOOP.

    LOOP AT delete-daily INTO DATA(ls_dd).
      DATA lv_d_motpr TYPE t550a-motpr.
      CLEAR lv_d_motpr.
      SELECT SINGLE motpr FROM t508a INTO @lv_d_motpr
        WHERE zeity = @ls_dd-esgrouping
          AND mofid = @ls_dd-holidaycalendarid
          AND mosid = @ls_dd-psgrouping
          AND schkz = @ls_dd-ruleid
          AND endda = @ls_dd-rulevalidto.
      DELETE FROM t550a
        WHERE motpr = @lv_d_motpr
          AND tprog = @ls_dd-code
          AND varia = @ls_dd-variant
          AND endda = @ls_dd-validto.
    ENDLOOP.

    LOOP AT create-break INTO DATA(ls_cb).
      CLEAR ls_break.
      ls_break-mandt = sy-mandt.
      ls_break-motpr = ls_cb-dwsgrouping.
      ls_break-pamod = ls_cb-breakid.
      ls_break-seqno = ls_cb-seqno.
      ls_break-pabeg = ls_cb-starttime.
      ls_break-paend = ls_cb-endtime.
      ls_break-pdbez = ls_cb-paidhours.
      ls_break-pdunb = ls_cb-unpaidhours.
      ls_break-stdaz = ls_cb-afterhours.
      IF ls_break-motpr IS INITIAL.
        SELECT SINGLE motpr FROM t508a INTO @ls_break-motpr
          WHERE zeity = @ls_cb-esgrouping
            AND mofid = @ls_cb-holidaycalendarid
            AND mosid = @ls_cb-psgrouping
            AND schkz = @ls_cb-ruleid
            AND endda = @ls_cb-rulevalidto.
      ENDIF.
      MODIFY t550p FROM ls_break.
    ENDLOOP.

    LOOP AT update-break INTO DATA(ls_ub).
      CLEAR ls_break.
      ls_break-mandt = sy-mandt.
      ls_break-motpr = ls_ub-dwsgrouping.
      ls_break-pamod = ls_ub-breakid.
      ls_break-seqno = ls_ub-seqno.
      ls_break-pabeg = ls_ub-starttime.
      ls_break-paend = ls_ub-endtime.
      ls_break-pdbez = ls_ub-paidhours.
      ls_break-pdunb = ls_ub-unpaidhours.
      ls_break-stdaz = ls_ub-afterhours.
      IF ls_break-motpr IS INITIAL.
        SELECT SINGLE motpr FROM t508a INTO @ls_break-motpr
          WHERE zeity = @ls_ub-esgrouping
            AND mofid = @ls_ub-holidaycalendarid
            AND mosid = @ls_ub-psgrouping
            AND schkz = @ls_ub-ruleid
            AND endda = @ls_ub-rulevalidto.
      ENDIF.
      MODIFY t550p FROM ls_break.
    ENDLOOP.

    LOOP AT delete-break INTO DATA(ls_db).
      DATA lv_b_motpr TYPE t550p-motpr.
      CLEAR lv_b_motpr.
      SELECT SINGLE motpr FROM t508a INTO @lv_b_motpr
        WHERE zeity = @ls_db-esgrouping
          AND mofid = @ls_db-holidaycalendarid
          AND mosid = @ls_db-psgrouping
          AND schkz = @ls_db-ruleid
          AND endda = @ls_db-rulevalidto.
      DELETE FROM t550p
        WHERE motpr = @lv_b_motpr
          AND pamod = @ls_db-breakid
          AND seqno = @ls_db-seqno.
    ENDLOOP.

    LOOP AT create-rule INTO DATA(ls_create).
      CLEAR: ls_data, lt_msg.
      ls_data-rule-mandt = sy-mandt.
      ls_data-rule-zeity = ls_create-esgrouping.
      ls_data-rule-mofid = ls_create-holidaycalendarid.
      ls_data-rule-mosid = ls_create-psgrouping.
      ls_data-rule-schkz = ls_create-ruleid.
      ls_data-rule-endda = ls_create-validto.
      ls_data-rule-begda = ls_create-validfrom.
      ls_data-rule-motpr = ls_create-dwsgrouping.
      ls_data-rule-zmodn = ls_create-periodid.
      ls_data-rule-tgstd = ls_create-avgdayhours.
      ls_data-rule-wostd = ls_create-avgweekhours.
      ls_data-rule-m1std = ls_create-avgmonthhours.
      ls_data-rule-jrstd = ls_create-avgyearhours.
      ls_data-rule-wkwdy = ls_create-workdaysperweek.
      ls_data-rule-bzpkt = ls_create-referencedate.
      ls_data-rule-offbz = ls_create-offsetdays.
      SELECT * FROM t551a INTO TABLE @ls_data-weeks
        WHERE motpr = @ls_data-rule-motpr
          AND zmodn = @ls_data-rule-zmodn.
      SELECT * FROM t550a INTO TABLE @ls_data-dailies
        WHERE motpr = @ls_data-rule-motpr.
      SELECT * FROM t550p INTO TABLE @ls_data-breaks
        WHERE motpr = @ls_data-rule-motpr.
      TRY.
          lt_msg = lo_persist->save_rule( data = ls_data trkorr = lv_trkorr ).
        CATCH cx_sy_file_io.
          APPEND VALUE #(
            %key = ls_create-%key
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Speichern/Transport fehlgeschlagen' )
          ) TO reported-rule.
          CONTINUE.
      ENDTRY.
      LOOP AT lt_msg INTO DATA(ls_msg) WHERE severity = 'E'.
        APPEND VALUE #(
          %key = ls_create-%key
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = ls_msg-text )
        ) TO reported-rule.
      ENDLOOP.
    ENDLOOP.

    LOOP AT update-rule INTO DATA(ls_update).
      CLEAR: ls_data, lt_msg.
      ls_data-rule-mandt = sy-mandt.
      ls_data-rule-zeity = ls_update-esgrouping.
      ls_data-rule-mofid = ls_update-holidaycalendarid.
      ls_data-rule-mosid = ls_update-psgrouping.
      ls_data-rule-schkz = ls_update-ruleid.
      ls_data-rule-endda = ls_update-validto.
      ls_data-rule-begda = ls_update-validfrom.
      ls_data-rule-motpr = ls_update-dwsgrouping.
      ls_data-rule-zmodn = ls_update-periodid.
      ls_data-rule-tgstd = ls_update-avgdayhours.
      ls_data-rule-wostd = ls_update-avgweekhours.
      ls_data-rule-m1std = ls_update-avgmonthhours.
      ls_data-rule-jrstd = ls_update-avgyearhours.
      ls_data-rule-wkwdy = ls_update-workdaysperweek.
      ls_data-rule-bzpkt = ls_update-referencedate.
      ls_data-rule-offbz = ls_update-offsetdays.
      SELECT * FROM t551a INTO TABLE @ls_data-weeks
        WHERE motpr = @ls_data-rule-motpr
          AND zmodn = @ls_data-rule-zmodn.
      SELECT * FROM t550a INTO TABLE @ls_data-dailies
        WHERE motpr = @ls_data-rule-motpr.
      SELECT * FROM t550p INTO TABLE @ls_data-breaks
        WHERE motpr = @ls_data-rule-motpr.
      TRY.
          lt_msg = lo_persist->save_rule( data = ls_data trkorr = lv_trkorr ).
        CATCH cx_sy_file_io.
          APPEND VALUE #(
            %key = ls_update-%key
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Speichern/Transport fehlgeschlagen' )
          ) TO reported-rule.
          CONTINUE.
      ENDTRY.
      LOOP AT lt_msg INTO ls_msg WHERE severity = 'E'.
        APPEND VALUE #(
          %key = ls_update-%key
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = ls_msg-text )
        ) TO reported-rule.
      ENDLOOP.
    ENDLOOP.

    LOOP AT delete-rule INTO DATA(ls_delete).
      CLEAR lt_msg.
      DATA(ls_del) = VALUE t508a(
        mandt = sy-mandt
        zeity = ls_delete-esgrouping
        mofid = ls_delete-holidaycalendarid
        mosid = ls_delete-psgrouping
        schkz = ls_delete-ruleid
        endda = ls_delete-validto ).
      TRY.
          lt_msg = lo_persist->delete_rule( rule = ls_del trkorr = lv_trkorr ).
        CATCH cx_sy_file_io.
          APPEND VALUE #(
            esgrouping          = ls_delete-esgrouping
            holidaycalendarid   = ls_delete-holidaycalendarid
            psgrouping          = ls_delete-psgrouping
            ruleid              = ls_delete-ruleid
            validto             = ls_delete-validto
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Loeschen/Transport fehlgeschlagen' )
          ) TO reported-rule.
          CONTINUE.
      ENDTRY.
      LOOP AT lt_msg INTO ls_msg WHERE severity = 'E'.
        APPEND VALUE #(
          esgrouping          = ls_delete-esgrouping
          holidaycalendarid   = ls_delete-holidaycalendarid
          psgrouping          = ls_delete-psgrouping
          ruleid              = ls_delete-ruleid
          validto             = ls_delete-validto
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = ls_msg-text )
        ) TO reported-rule.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
