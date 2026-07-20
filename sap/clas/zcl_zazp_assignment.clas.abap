CLASS zcl_zazp_assignment DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_assignment,
        pernr           TYPE pa0007-pernr,
        rule_id         TYPE pa0007-schkz,
        valid_from      TYPE pa0007-begda,
        valid_to        TYPE pa0007-endda,
        employment_pct  TYPE pa0007-empct,
        weekly_hours    TYPE pa0007-wostd,
      END OF ty_assignment.

    METHODS read_current
      IMPORTING
        pernr             TYPE pa0007-pernr
        key_date          TYPE d DEFAULT sy-datum
      RETURNING
        VALUE(assignment) TYPE ty_assignment.

    METHODS assign_rule
      IMPORTING
        assignment      TYPE ty_assignment
      RETURNING
        VALUE(messages) TYPE zif_zazp_validation=>ty_messages.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_zazp_assignment IMPLEMENTATION.

  METHOD read_current.
    DATA: lv_schkz TYPE pa0007-schkz,
          lv_begda TYPE pa0007-begda,
          lv_endda TYPE pa0007-endda,
          lv_empct TYPE pa0007-empct,
          lv_wostd TYPE pa0007-wostd.

    CLEAR assignment.
    assignment-pernr = pernr.
    SELECT SINGLE schkz, begda, endda, empct, wostd
      FROM pa0007
      INTO ( @lv_schkz, @lv_begda, @lv_endda, @lv_empct, @lv_wostd )
      WHERE pernr = @pernr
        AND begda <= @key_date
        AND endda >= @key_date.
    IF sy-subrc = 0.
      assignment-rule_id        = lv_schkz.
      assignment-valid_from     = lv_begda.
      assignment-valid_to       = lv_endda.
      assignment-employment_pct = lv_empct.
      assignment-weekly_hours   = lv_wostd.
    ENDIF.
  ENDMETHOD.


  METHOD assign_rule.
    DATA: lt_proposed TYPE STANDARD TABLE OF pprop WITH EMPTY KEY,
          ls_return   TYPE bapireturn,
          ls_return1  TYPE bapireturn1,
          lv_actio    TYPE c LENGTH 3,
          lv_exists   TYPE abap_bool.

    CLEAR messages.

    IF assignment-pernr IS INITIAL OR assignment-rule_id IS INITIAL.
      APPEND VALUE #(
        severity = zif_zazp_validation=>c_severity-error
        field    = 'Pernr'
        text     = 'Personalnummer und AZP-Regel sind Pflicht'
        msgid    = zif_zazp_validation=>c_msgid
        msgno    = '040'
      ) TO messages.
      RETURN.
    ENDIF.

    SELECT SINGLE schkz FROM t508a INTO @DATA(lv_schkz)
      WHERE schkz = @assignment-rule_id.
    IF sy-subrc <> 0.
      APPEND VALUE #(
        severity = zif_zazp_validation=>c_severity-error
        field    = 'RuleId'
        text     = |Arbeitszeitplanregel { assignment-rule_id } existiert nicht|
        msgid    = zif_zazp_validation=>c_msgid
        msgno    = '002'
      ) TO messages.
      RETURN.
    ENDIF.

    SELECT SINGLE pernr FROM pa0007 INTO @DATA(lv_pernr)
      WHERE pernr = @assignment-pernr.
    lv_exists = xsdbool( sy-subrc = 0 ).
    lv_actio = COND #( WHEN lv_exists = abap_true THEN 'MOD' ELSE 'INS' ).

    APPEND VALUE #(
      infty = '0007'
      fname = 'SCHKZ'
      fval  = assignment-rule_id
    ) TO lt_proposed.

    IF assignment-employment_pct IS NOT INITIAL.
      APPEND VALUE #(
        infty = '0007'
        fname = 'EMPCT'
        fval  = |{ assignment-employment_pct }|
      ) TO lt_proposed.
    ENDIF.

    IF assignment-weekly_hours IS NOT INITIAL.
      APPEND VALUE #(
        infty = '0007'
        fname = 'WOSTD'
        fval  = |{ assignment-weekly_hours }|
      ) TO lt_proposed.
    ENDIF.

    CALL FUNCTION 'HR_MAINTAIN_MASTERDATA'
      EXPORTING
        pernr              = assignment-pernr
        actio              = lv_actio
        begda              = COND #( WHEN assignment-valid_from IS NOT INITIAL
                                     THEN assignment-valid_from ELSE sy-datum )
        endda              = COND #( WHEN assignment-valid_to IS NOT INITIAL
                                     THEN assignment-valid_to ELSE '99991231' )
        no_existence_check = abap_false
      IMPORTING
        return             = ls_return
        return1            = ls_return1
      TABLES
        proposed_values    = lt_proposed
      EXCEPTIONS
        OTHERS             = 1.

    IF sy-subrc <> 0
       OR ls_return-type CA 'EA'
       OR ls_return1-type CA 'EA'.
      DATA(lv_text) = COND string(
        WHEN ls_return1-message IS NOT INITIAL THEN ls_return1-message
        WHEN ls_return-message IS NOT INITIAL THEN ls_return-message
        ELSE 'HR_MAINTAIN_MASTERDATA fehlgeschlagen' ).
      APPEND VALUE #(
        severity = zif_zazp_validation=>c_severity-error
        field    = 'Assignment'
        text     = lv_text
        msgid    = zif_zazp_validation=>c_msgid
        msgno    = '041'
      ) TO messages.
    ELSE.
      APPEND VALUE #(
        severity = zif_zazp_validation=>c_severity-info
        field    = 'Assignment'
        text     = |IT0007 fuer { assignment-pernr } auf Regel { assignment-rule_id } gesetzt|
        msgid    = zif_zazp_validation=>c_msgid
        msgno    = '042'
      ) TO messages.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
