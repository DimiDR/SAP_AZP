REPORT zazp_odata_search_test.

CLASS lcl_test DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS:
      search_norm FOR TESTING,
      filter_ruleid_eq FOR TESTING,
      filter_ruleid_contains FOR TESTING,
      filter_psgrouping FOR TESTING,
      filter_holidaycal FOR TESTING,
      filter_validfrom FOR TESTING,
      filter_combined FOR TESTING,
      search_and_filter FOR TESTING,
      draft_all_active FOR TESTING,
      vh_holidaycal FOR TESTING.
    METHODS get
      IMPORTING iv_path TYPE string
      EXPORTING ev_code TYPE i
                ev_body TYPE string
                ev_count TYPE i.
    METHODS assert_hits
      IMPORTING iv_label  TYPE string
                iv_code   TYPE i
                iv_body   TYPE string
                iv_count  TYPE i
                iv_needle TYPE string OPTIONAL.
    METHODS base RETURNING VALUE(rv) TYPE string.
ENDCLASS.

CLASS lcl_test IMPLEMENTATION.
  METHOD base.
    rv = `/sap/opu/odata4/sap/zui_zazp_rule_ui/srvd_a2x/` &&
         `sap/zui_zazp_workschedulerule/0001/WorkScheduleRule`.
  ENDMETHOD.

  METHOD get.
    DATA lo_client TYPE REF TO if_http_client.
    DATA lv_reason TYPE string.
    DATA lv_pos    TYPE i.
    DATA lv_tail   TYPE string.
    DATA lv_num    TYPE string.

    CLEAR: ev_code, ev_body, ev_count.
    cl_http_client=>create_internal(
      IMPORTING client = lo_client
      EXCEPTIONS OTHERS = 1 ).
    cl_abap_unit_assert=>assert_equals( act = sy-subrc exp = 0 msg = 'create_internal' ).
    lo_client->request->set_method( 'GET' ).
    lo_client->request->set_header_field( name = '~request_uri' value = iv_path ).
    lo_client->request->set_header_field( name = 'Accept' value = 'application/json' ).
    lo_client->send( EXCEPTIONS OTHERS = 1 ).
    lo_client->receive( EXCEPTIONS OTHERS = 1 ).
    lo_client->response->get_status( IMPORTING code = ev_code reason = lv_reason ).
    ev_body = lo_client->response->get_cdata( ).
    lo_client->close( ).

    FIND '"@odata.count":' IN ev_body MATCH OFFSET lv_pos.
    IF sy-subrc = 0.
      lv_tail = ev_body+lv_pos.
      FIND REGEX '"@odata\.count":\s*([0-9]+)' IN lv_tail SUBMATCHES lv_num.
      IF sy-subrc = 0.
        ev_count = lv_num.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD assert_hits.
    cl_abap_unit_assert=>assert_equals(
      act = iv_code exp = 200
      msg = |{ iv_label }: HTTP { iv_code } { iv_body }| ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( iv_count > 0 )
      msg = |{ iv_label }: count={ iv_count } { iv_body }| ).
    IF iv_needle IS SUPPLIED AND iv_needle IS NOT INITIAL.
      cl_abap_unit_assert=>assert_true(
        act = xsdbool( iv_body CS iv_needle )
        msg = |{ iv_label }: missing '{ iv_needle }' { iv_body }| ).
    ENDIF.
  ENDMETHOD.

  METHOD search_norm.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    lv_path = base( ) &&
      `?$count=true&$search="NORM"` &&
      `&$filter=IsActiveEntity%20eq%20true&$top=20`.
    get( EXPORTING iv_path = lv_path
         IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    assert_hits( iv_label = 'SEARCH' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count iv_needle = 'NORM' ).
  ENDMETHOD.

  METHOD filter_ruleid_eq.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    lv_path = base( ) &&
      `?$count=true&$filter=IsActiveEntity%20eq%20true` &&
      `%20and%20RuleId%20eq%20'NORM'&$top=20`.
    get( EXPORTING iv_path = lv_path
         IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    assert_hits( iv_label = 'RuleId EQ' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count iv_needle = 'NORM' ).
  ENDMETHOD.

  METHOD filter_ruleid_contains.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    lv_path = base( ) &&
      `?$count=true&$filter=IsActiveEntity%20eq%20true` &&
      `%20and%20contains(RuleId,'GLZ')&$top=20`.
    get( EXPORTING iv_path = lv_path
         IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    assert_hits( iv_label = 'RuleId CONTAINS' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count iv_needle = 'GLZ' ).
  ENDMETHOD.

  METHOD filter_psgrouping.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    lv_path = base( ) &&
      `?$count=true&$filter=IsActiveEntity%20eq%20true` &&
      `%20and%20PsGrouping%20eq%20'01'&$top=20`.
    get( EXPORTING iv_path = lv_path
         IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    assert_hits( iv_label = 'PsGrouping EQ 01' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count ).
  ENDMETHOD.

  METHOD filter_holidaycal.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    lv_path = base( ) &&
      `?$count=true&$filter=IsActiveEntity%20eq%20true` &&
      `%20and%20HolidayCalendarId%20eq%20'08'&$top=20`.
    get( EXPORTING iv_path = lv_path
         IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    assert_hits( iv_label = 'HolidayCalendarId EQ 08' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count
                 iv_needle = '"HolidayCalendarId":"08"' ).
  ENDMETHOD.

  METHOD filter_validfrom.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    lv_path = base( ) &&
      `?$count=true&$filter=IsActiveEntity%20eq%20true` &&
      `%20and%20ValidFrom%20ge%201990-01-01&$top=20`.
    get( EXPORTING iv_path = lv_path
         IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    assert_hits( iv_label = 'ValidFrom GE 1990-01-01' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count ).
  ENDMETHOD.

  METHOD filter_combined.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    lv_path = base( ) &&
      `?$count=true&$filter=IsActiveEntity%20eq%20true` &&
      `%20and%20RuleId%20eq%20'NORM'` &&
      `%20and%20HolidayCalendarId%20eq%20'08'` &&
      `%20and%20PsGrouping%20eq%20'01'&$top=20`.
    get( EXPORTING iv_path = lv_path
         IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    assert_hits( iv_label = 'COMBINED' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count iv_needle = 'NORM' ).
  ENDMETHOD.

  METHOD search_and_filter.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    lv_path = base( ) &&
      `?$count=true&$search="NORM"` &&
      `&$filter=IsActiveEntity%20eq%20true` &&
      `%20and%20HolidayCalendarId%20eq%20'08'&$top=20`.
    get( EXPORTING iv_path = lv_path
         IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    assert_hits( iv_label = 'SEARCH+Cal' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count iv_needle = 'NORM' ).
  ENDMETHOD.

  METHOD draft_all_active.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    lv_path = base( ) &&
      `?$count=true&$filter=IsActiveEntity%20eq%20true&$top=5`.
    get( EXPORTING iv_path = lv_path
         IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    assert_hits( iv_label = 'ALL ACTIVE' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count ).
  ENDMETHOD.

  METHOD vh_holidaycal.
    DATA lv_code TYPE i.
    DATA lv_body TYPE string.
    DATA lv_count TYPE i.
    DATA lv_path TYPE string.
    DATA lv_reason TYPE string.
    DATA lo_client TYPE REF TO if_http_client.
    DATA lv_pos TYPE i.
    DATA lv_tail TYPE string.
    DATA lv_num TYPE string.

    lv_path = `/sap/opu/odata4/sap/zui_zazp_rule_ui/srvd_a2x/` &&
              `sap/zui_zazp_workschedulerule/0001/HolidayCalendar` &&
              `?$count=true&$top=20`.
    cl_http_client=>create_internal(
      IMPORTING client = lo_client
      EXCEPTIONS OTHERS = 1 ).
    cl_abap_unit_assert=>assert_equals( act = sy-subrc exp = 0 ).
    lo_client->request->set_method( 'GET' ).
    lo_client->request->set_header_field( name = '~request_uri' value = lv_path ).
    lo_client->request->set_header_field( name = 'Accept' value = 'application/json' ).
    lo_client->send( EXCEPTIONS OTHERS = 1 ).
    lo_client->receive( EXCEPTIONS OTHERS = 1 ).
    lo_client->response->get_status( IMPORTING code = lv_code reason = lv_reason ).
    lv_body = lo_client->response->get_cdata( ).
    lo_client->close( ).
    FIND '"@odata.count":' IN lv_body MATCH OFFSET lv_pos.
    IF sy-subrc = 0.
      lv_tail = lv_body+lv_pos.
      FIND REGEX '"@odata\.count":\s*([0-9]+)' IN lv_tail SUBMATCHES lv_num.
      IF sy-subrc = 0.
        lv_count = lv_num.
      ENDIF.
    ENDIF.
    assert_hits( iv_label = 'VH HolidayCalendar' iv_code = lv_code
                 iv_body = lv_body iv_count = lv_count ).
  ENDMETHOD.
ENDCLASS.
