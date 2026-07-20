INTERFACE zif_zazp_validation
  PUBLIC.

  TYPES:
    BEGIN OF ty_message,
      severity TYPE symsgty,
      field    TYPE string,
      text     TYPE string,
      msgid    TYPE symsgid,
      msgno    TYPE symsgno,
    END OF ty_message,
    ty_messages TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_daily,
      dws_grouping TYPE t550a-motpr,
      code         TYPE t550a-tprog,
      variant      TYPE t550a-varia,
      target_hours TYPE t550a-sollz,
      work_start   TYPE t550a-sobeg,
      work_end     TYPE t550a-soend,
      normal_start TYPE t550a-nobeg,
      normal_end   TYPE t550a-noend,
      tol_beg_from TYPE t550a-btbeg,
      tol_beg_to   TYPE t550a-btend,
      tol_end_from TYPE t550a-etbeg,
      tol_end_to   TYPE t550a-etend,
      core_start   TYPE t550a-k1beg,
      core_end     TYPE t550a-k1end,
      break_id     TYPE t550a-pamod,
    END OF ty_daily.

  TYPES:
    BEGIN OF ty_break,
      dws_grouping TYPE t550p-motpr,
      break_id     TYPE t550p-pamod,
      seq_no       TYPE t550p-seqno,
      start_time   TYPE t550p-pabeg,
      end_time     TYPE t550p-paend,
      paid_hours   TYPE t550p-pdbez,
      unpaid_hours TYPE t550p-pdunb,
      after_hours  TYPE t550p-stdaz,
    END OF ty_break,
    ty_breaks TYPE STANDARD TABLE OF ty_break WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_rule_ctx,
      rule    TYPE t508a,
      weeks   TYPE STANDARD TABLE OF t551a WITH EMPTY KEY,
      dailies TYPE STANDARD TABLE OF t550a WITH EMPTY KEY,
      breaks  TYPE STANDARD TABLE OF t550p WITH EMPTY KEY,
    END OF ty_rule_ctx.

  CONSTANTS:
    BEGIN OF c_severity,
      error   TYPE symsgty VALUE 'E',
      warning TYPE symsgty VALUE 'W',
      info    TYPE symsgty VALUE 'I',
    END OF c_severity,
    c_week_hours_min TYPE t508a-wostd VALUE '20.00',
    c_week_hours_max TYPE t508a-wostd VALUE '48.00',
    c_week_tol_hours TYPE t508a-wostd VALUE '0.50',
    c_msgid          TYPE symsgid VALUE 'ZAZP'.

  METHODS validate_rule
    IMPORTING
      rule_id         TYPE t508a-schkz
      dws_grouping    TYPE t508a-motpr OPTIONAL
      es_grouping     TYPE t508a-zeity OPTIONAL
      holiday_cal_id  TYPE t508a-mofid OPTIONAL
      ps_grouping     TYPE t508a-mosid OPTIONAL
      valid_to        TYPE t508a-endda OPTIONAL
    RETURNING
      VALUE(messages) TYPE ty_messages.

  METHODS validate_rule_ctx
    IMPORTING
      ctx             TYPE ty_rule_ctx
    RETURNING
      VALUE(messages) TYPE ty_messages.

  METHODS validate_daily
    IMPORTING
      dws             TYPE ty_daily
    RETURNING
      VALUE(messages) TYPE ty_messages.

  METHODS validate_break
    IMPORTING
      brk             TYPE ty_break
      work_start      TYPE t550a-sobeg OPTIONAL
      work_end        TYPE t550a-soend OPTIONAL
    RETURNING
      VALUE(messages) TYPE ty_messages.

ENDINTERFACE.
