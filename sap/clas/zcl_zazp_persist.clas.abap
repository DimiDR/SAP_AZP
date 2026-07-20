CLASS zcl_zazp_persist DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_rule_data,
        rule      TYPE t508a,
        rule_txt  TYPE t508s,
        weeks     TYPE STANDARD TABLE OF t551a WITH EMPTY KEY,
        dailies   TYPE STANDARD TABLE OF t550a WITH EMPTY KEY,
        daily_txt TYPE STANDARD TABLE OF t550s WITH EMPTY KEY,
        breaks    TYPE STANDARD TABLE OF t550p WITH EMPTY KEY,
      END OF ty_rule_data.

    METHODS save_rule
      IMPORTING
        data            TYPE ty_rule_data
        trkorr          TYPE e070-trkorr
      RETURNING
        VALUE(messages) TYPE zif_zazp_validation=>ty_messages
      RAISING
        cx_sy_file_io.

    METHODS delete_rule
      IMPORTING
        rule            TYPE t508a
        trkorr          TYPE e070-trkorr
      RETURNING
        VALUE(messages) TYPE zif_zazp_validation=>ty_messages
      RAISING
        cx_sy_file_io.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_transport  TYPE REF TO zcl_zazp_transport.
    DATA mo_validation TYPE REF TO zif_zazp_validation.

    METHODS ensure_deps.

    METHODS build_keys
      IMPORTING
        data        TYPE ty_rule_data
      RETURNING
        VALUE(keys) TYPE zcl_zazp_transport=>ty_tabkeys.

    METHODS key_t508a
      IMPORTING
        row           TYPE t508a
      RETURNING
        VALUE(tabkey) TYPE e071k-tabkey.

    METHODS key_t508s
      IMPORTING
        row           TYPE t508s
      RETURNING
        VALUE(tabkey) TYPE e071k-tabkey.

    METHODS key_t551a
      IMPORTING
        row           TYPE t551a
      RETURNING
        VALUE(tabkey) TYPE e071k-tabkey.

    METHODS key_t550a
      IMPORTING
        row           TYPE t550a
      RETURNING
        VALUE(tabkey) TYPE e071k-tabkey.

    METHODS key_t550p
      IMPORTING
        row           TYPE t550p
      RETURNING
        VALUE(tabkey) TYPE e071k-tabkey.

ENDCLASS.


CLASS zcl_zazp_persist IMPLEMENTATION.

  METHOD ensure_deps.
    IF mo_validation IS NOT BOUND.
      mo_validation = NEW zcl_zazp_validation( ).
    ENDIF.
    IF mo_transport IS NOT BOUND.
      mo_transport = NEW zcl_zazp_transport( ).
    ENDIF.
  ENDMETHOD.


  METHOD save_rule.
    DATA ls_ctx TYPE zif_zazp_validation=>ty_rule_ctx.

    ensure_deps( ).
    CLEAR messages.

    IF trkorr IS INITIAL OR mo_transport->is_request_modifiable( trkorr ) = abap_false.
      APPEND VALUE #(
        severity = zif_zazp_validation=>c_severity-error
        field    = 'Transport'
        text     = 'Gueltiger offener Customizing-Auftrag erforderlich'
        msgid    = zif_zazp_validation=>c_msgid
        msgno    = '030'
      ) TO messages.
      RETURN.
    ENDIF.

    ls_ctx-rule    = data-rule.
    ls_ctx-weeks   = data-weeks.
    ls_ctx-dailies = data-dailies.
    ls_ctx-breaks  = data-breaks.

    messages = mo_validation->validate_rule_ctx( ls_ctx ).

    LOOP AT messages TRANSPORTING NO FIELDS WHERE severity = 'E'.
      RETURN.
    ENDLOOP.

    IF data-rule IS NOT INITIAL.
      MODIFY t508a FROM data-rule.
    ENDIF.
    IF data-rule_txt IS NOT INITIAL.
      MODIFY t508s FROM data-rule_txt.
    ENDIF.
    IF data-weeks IS NOT INITIAL.
      MODIFY t551a FROM TABLE data-weeks.
    ENDIF.
    IF data-dailies IS NOT INITIAL.
      MODIFY t550a FROM TABLE data-dailies.
    ENDIF.
    IF data-daily_txt IS NOT INITIAL.
      MODIFY t550s FROM TABLE data-daily_txt.
    ENDIF.
    IF data-breaks IS NOT INITIAL.
      MODIFY t550p FROM TABLE data-breaks.
    ENDIF.

    mo_transport->record_table_keys(
      trkorr = trkorr
      keys   = build_keys( data ) ).
  ENDMETHOD.


  METHOD delete_rule.
    DATA ls_data TYPE ty_rule_data.

    ensure_deps( ).
    CLEAR messages.

    IF rule-schkz IS INITIAL OR rule-zeity IS INITIAL OR rule-endda IS INITIAL.
      APPEND VALUE #(
        severity = zif_zazp_validation=>c_severity-error
        field    = 'RuleId'
        text     = 'Loeschung erfordert vollstaendigen T508A-Schluessel'
        msgid    = zif_zazp_validation=>c_msgid
        msgno    = '031'
      ) TO messages.
      RETURN.
    ENDIF.

    IF trkorr IS INITIAL OR mo_transport->is_request_modifiable( trkorr ) = abap_false.
      APPEND VALUE #(
        severity = zif_zazp_validation=>c_severity-error
        field    = 'Transport'
        text     = 'Gueltiger offener Customizing-Auftrag erforderlich'
        msgid    = zif_zazp_validation=>c_msgid
        msgno    = '030'
      ) TO messages.
      RETURN.
    ENDIF.

    DELETE FROM t508a
      WHERE zeity = @rule-zeity
        AND mofid = @rule-mofid
        AND mosid = @rule-mosid
        AND schkz = @rule-schkz
        AND endda = @rule-endda.

    IF sy-subrc <> 0.
      APPEND VALUE #(
        severity = zif_zazp_validation=>c_severity-warning
        field    = 'RuleId'
        text     = 'Kein T508A-Satz zum Loeschen gefunden'
        msgid    = zif_zazp_validation=>c_msgid
        msgno    = '032'
      ) TO messages.
      RETURN.
    ENDIF.

    ls_data-rule = rule.
    mo_transport->record_table_keys(
      trkorr = trkorr
      keys   = build_keys( ls_data ) ).
  ENDMETHOD.


  METHOD build_keys.
    IF data-rule IS NOT INITIAL.
      APPEND VALUE #( tabname = 'T508A' tabkey = key_t508a( data-rule ) ) TO keys.
    ENDIF.
    IF data-rule_txt IS NOT INITIAL.
      APPEND VALUE #( tabname = 'T508S' tabkey = key_t508s( data-rule_txt ) ) TO keys.
    ENDIF.
    LOOP AT data-weeks INTO DATA(ls_w).
      APPEND VALUE #( tabname = 'T551A' tabkey = key_t551a( ls_w ) ) TO keys.
    ENDLOOP.
    LOOP AT data-dailies INTO DATA(ls_d).
      APPEND VALUE #( tabname = 'T550A' tabkey = key_t550a( ls_d ) ) TO keys.
    ENDLOOP.
    LOOP AT data-breaks INTO DATA(ls_b).
      APPEND VALUE #( tabname = 'T550P' tabkey = key_t550p( ls_b ) ) TO keys.
    ENDLOOP.
  ENDMETHOD.


  METHOD key_t508a.
    tabkey = |{ row-mandt }{ row-zeity }{ row-mofid }{ row-mosid }{ row-schkz }{ row-endda }|.
  ENDMETHOD.


  METHOD key_t508s.
    tabkey = |{ row-mandt }{ row-zeity }{ row-mofid }{ row-mosid }{ row-schkz }{ row-sprsl }|.
  ENDMETHOD.


  METHOD key_t551a.
    tabkey = |{ row-mandt }{ row-motpr }{ row-zmodn }{ row-wonum }|.
  ENDMETHOD.


  METHOD key_t550a.
    tabkey = |{ row-mandt }{ row-motpr }{ row-tprog }{ row-varia }{ row-seqno }{ row-endda }|.
  ENDMETHOD.


  METHOD key_t550p.
    tabkey = |{ row-mandt }{ row-motpr }{ row-pamod }{ row-seqno }|.
  ENDMETHOD.

ENDCLASS.
