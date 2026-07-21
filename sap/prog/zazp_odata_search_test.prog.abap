REPORT zazp_odata_search_test.

CLASS lcl_test DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS:
      vh_active_rules FOR TESTING,
      filter_ruleid_eq FOR TESTING,
      search_norm FOR TESTING.
    METHODS get
      IMPORTING iv_path TYPE string
      EXPORTING ev_code TYPE i
                ev_body TYPE string
                ev_count TYPE i.
ENDCLASS.

CLASS lcl_test IMPLEMENTATION.
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

  METHOD vh_active_rules.
    DATA: lv_code TYPE i, lv_body TYPE string, lv_count TYPE i.
    get(
      EXPORTING iv_path = `/sap/opu/odata4/sap/zui_zazp_rule_ui/srvd_a2x/sap/zui_zazp_workschedulerule/0001/` &&
                          `WorkScheduleRule?$filter=IsActiveEntity%20eq%20true` &&
                          `&$select=RuleId,Description,PsGrouping,HolidayCalendarId&$top=5&$count=true`
      IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    cl_abap_unit_assert=>assert_equals( act = lv_code exp = 200 msg = |VH HTTP { lv_code } { lv_body }| ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_count > 0 ) msg = |VH count={ lv_count }| ).
  ENDMETHOD.

  METHOD filter_ruleid_eq.
    DATA: lv_code TYPE i, lv_body TYPE string, lv_count TYPE i.
    get(
      EXPORTING iv_path = `/sap/opu/odata4/sap/zui_zazp_rule_ui/srvd_a2x/sap/zui_zazp_workschedulerule/0001/` &&
                          `WorkScheduleRule?$filter=IsActiveEntity%20eq%20true%20and%20RuleId%20eq%20'NORM'` &&
                          `&$count=true&$top=5`
      IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    cl_abap_unit_assert=>assert_equals( act = lv_code exp = 200 msg = |EQ HTTP { lv_code } { lv_body }| ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_count > 0 ) msg = |EQ count={ lv_count }| ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_body CS 'NORM' ) msg = |EQ missing NORM| ).
  ENDMETHOD.

  METHOD search_norm.
    DATA: lv_code TYPE i, lv_body TYPE string, lv_count TYPE i.
    get(
      EXPORTING iv_path = `/sap/opu/odata4/sap/zui_zazp_rule_ui/srvd_a2x/sap/zui_zazp_workschedulerule/0001/` &&
                          `WorkScheduleRule?$filter=IsActiveEntity%20eq%20true&$search="NORM"&$count=true&$top=5`
      IMPORTING ev_code = lv_code ev_body = lv_body ev_count = lv_count ).
    cl_abap_unit_assert=>assert_equals( act = lv_code exp = 200 msg = |SEARCH HTTP { lv_code } { lv_body }| ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_count > 0 ) msg = |SEARCH count={ lv_count }| ).
  ENDMETHOD.
ENDCLASS.
