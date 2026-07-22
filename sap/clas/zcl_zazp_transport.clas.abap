CLASS zcl_zazp_transport DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_request,
        trkorr   TYPE e070-trkorr,
        as4text  TYPE e07t-as4text,
        as4user  TYPE e070-as4user,
        trstatus TYPE e070-trstatus,
      END OF ty_request,
      ty_requests TYPE STANDARD TABLE OF ty_request WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_tabkey,
        tabname TYPE tabname,
        tabkey  TYPE e071k-tabkey,
      END OF ty_tabkey,
      ty_tabkeys TYPE STANDARD TABLE OF ty_tabkey WITH EMPTY KEY.

    METHODS list_open_customizing_requests
      IMPORTING
        for_user        TYPE syuname DEFAULT sy-uname
      RETURNING
        VALUE(requests) TYPE ty_requests.

    METHODS create_customizing_request
      IMPORTING
        description   TYPE e07t-as4text
      RETURNING
        VALUE(trkorr) TYPE e070-trkorr
      RAISING
        cx_sy_file_io.

    METHODS ensure_customizing_request
      IMPORTING
        VALUE(description)      TYPE e07t-as4text DEFAULT 'AZP Customizing'
        VALUE(preferred_trkorr) TYPE e070-trkorr OPTIONAL
      RETURNING
        VALUE(trkorr) TYPE e070-trkorr
      RAISING
        cx_sy_file_io.

    METHODS record_table_keys
      IMPORTING
        trkorr TYPE e070-trkorr
        keys   TYPE ty_tabkeys
      RAISING
        cx_sy_file_io.

    METHODS is_request_modifiable
      IMPORTING
        trkorr    TYPE e070-trkorr
      RETURNING
        VALUE(ok) TYPE abap_bool.

    CLASS-METHODS set_preferred_request
      IMPORTING
        trkorr TYPE e070-trkorr.

    CLASS-METHODS get_preferred_request
      RETURNING
        VALUE(trkorr) TYPE e070-trkorr.

    CLASS-METHODS clear_preferred_request.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA gv_preferred_trkorr TYPE e070-trkorr.

    CLASS-METHODS _pref_id
      RETURNING
        VALUE(id) TYPE indx_srtfd.
ENDCLASS.


CLASS zcl_zazp_transport IMPLEMENTATION.

  METHOD list_open_customizing_requests.
    SELECT e070~trkorr,
           e07t~as4text,
           e070~as4user,
           e070~trstatus
      FROM e070
      INNER JOIN e07t ON e07t~trkorr = e070~trkorr
                     AND e07t~langu  = @sy-langu
      WHERE e070~trfunction = 'W'
        AND e070~trstatus   = 'D'
        AND ( @for_user = @space OR e070~as4user = @for_user )
      INTO CORRESPONDING FIELDS OF TABLE @requests.
    SORT requests BY trkorr DESCENDING.
  ENDMETHOD.


  METHOD create_customizing_request.
    DATA: lv_request TYPE trkorr,
          lt_tasks   TYPE STANDARD TABLE OF e070 WITH EMPTY KEY,
          ls_e07t    TYPE e07t.

    CALL FUNCTION 'TR_INSERT_REQUEST_WITH_TASKS'
      EXPORTING
        wi_trkorr     = space
        wi_trfunction = 'W'
        iv_username   = sy-uname
        iv_client     = sy-mandt
      IMPORTING
        we_trkorr     = lv_request
      TABLES
        wt_e070       = lt_tasks
      EXCEPTIONS
        OTHERS        = 1.
    IF sy-subrc <> 0 OR lv_request IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_file_io.
    ENDIF.

    IF description IS NOT INITIAL.
      ls_e07t-trkorr  = lv_request.
      ls_e07t-langu   = sy-langu.
      ls_e07t-as4text = description.
      MODIFY e07t FROM ls_e07t.
    ENDIF.

    trkorr = lv_request.
  ENDMETHOD.


  METHOD ensure_customizing_request.
    IF preferred_trkorr IS NOT INITIAL
       AND is_request_modifiable( preferred_trkorr ) = abap_true.
      trkorr = preferred_trkorr.
      RETURN.
    ENDIF.

    DATA(lv_pref) = get_preferred_request( ).
    IF lv_pref IS NOT INITIAL
       AND is_request_modifiable( lv_pref ) = abap_true.
      trkorr = lv_pref.
      RETURN.
    ENDIF.

    DATA(lt_req) = list_open_customizing_requests( ).
    IF lt_req IS NOT INITIAL.
      trkorr = lt_req[ 1 ]-trkorr.
      RETURN.
    ENDIF.

    trkorr = create_customizing_request( description ).
  ENDMETHOD.


  METHOD is_request_modifiable.
    DATA: lv_status TYPE e070-trstatus,
          lv_func   TYPE e070-trfunction.

    SELECT SINGLE trstatus, trfunction FROM e070
      INTO ( @lv_status, @lv_func )
      WHERE trkorr = @trkorr.
    ok = xsdbool( sy-subrc = 0 AND lv_status = 'D' AND lv_func = 'W' ).
  ENDMETHOD.


  METHOD record_table_keys.
    DATA: lt_e071  TYPE STANDARD TABLE OF e071 WITH EMPTY KEY,
          lt_e071k TYPE STANDARD TABLE OF e071k WITH EMPTY KEY,
          ls_e071  TYPE e071,
          ls_e071k TYPE e071k,
          lv_obj   TYPE e071-obj_name,
          lv_pos   TYPE i.

    IF is_request_modifiable( trkorr ) = abap_false.
      RAISE EXCEPTION TYPE cx_sy_file_io.
    ENDIF.

    LOOP AT keys INTO DATA(ls_key).
      lv_obj = ls_key-tabname.
      READ TABLE lt_e071 WITH KEY obj_name = lv_obj TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CLEAR ls_e071.
        ls_e071-trkorr   = trkorr.
        ls_e071-pgmid    = 'R3TR'.
        ls_e071-object   = 'TABU'.
        ls_e071-obj_name = lv_obj.
        ls_e071-objfunc  = 'K'.
        APPEND ls_e071 TO lt_e071.
      ENDIF.

      lv_pos = lv_pos + 1.
      CLEAR ls_e071k.
      ls_e071k-trkorr     = trkorr.
      ls_e071k-pgmid      = 'R3TR'.
      ls_e071k-object     = 'TABU'.
      ls_e071k-objname    = lv_obj.
      ls_e071k-as4pos     = lv_pos.
      ls_e071k-mastertype = 'TABU'.
      ls_e071k-mastername = lv_obj.
      ls_e071k-tabkey     = ls_key-tabkey.
      APPEND ls_e071k TO lt_e071k.
    ENDLOOP.

    CALL FUNCTION 'TR_OBJECTS_CHECK'
      TABLES
        wt_ko200 = lt_e071
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
      " soft check — insert trotzdem versuchen
    ENDIF.

    CALL FUNCTION 'TR_OBJECTS_INSERT'
      EXPORTING
        wi_order = trkorr
      TABLES
        wt_ko200 = lt_e071
        wt_e071k = lt_e071k
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_file_io.
    ENDIF.
  ENDMETHOD.


  METHOD set_preferred_request.
    DATA: lv_trkorr TYPE e070-trkorr,
          lv_id     TYPE indx_srtfd.
    gv_preferred_trkorr = trkorr.
    lv_trkorr = trkorr.
    lv_id = _pref_id( ).
    EXPORT trkorr FROM lv_trkorr TO DATABASE indx(za) ID lv_id.
  ENDMETHOD.


  METHOD get_preferred_request.
    DATA: lv_trkorr TYPE e070-trkorr,
          lv_id     TYPE indx_srtfd.
    IF gv_preferred_trkorr IS NOT INITIAL.
      trkorr = gv_preferred_trkorr.
      RETURN.
    ENDIF.
    lv_id = _pref_id( ).
    IMPORT trkorr TO lv_trkorr FROM DATABASE indx(za) ID lv_id.
    IF sy-subrc = 0.
      gv_preferred_trkorr = lv_trkorr.
      trkorr = lv_trkorr.
    ENDIF.
  ENDMETHOD.


  METHOD clear_preferred_request.
    DATA lv_id TYPE indx_srtfd.
    CLEAR gv_preferred_trkorr.
    lv_id = _pref_id( ).
    DELETE FROM DATABASE indx(za) ID lv_id.
  ENDMETHOD.


  METHOD _pref_id.
    id = |ZAZP{ sy-uname }|.
  ENDMETHOD.

ENDCLASS.
