FUNCTION /tenr/fm_int_sicram_out.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_TOR) TYPE  /SCMTMS/TOR_ID OPTIONAL
*"     VALUE(I_UPD_FLAG) TYPE  CHAR1
*"     VALUE(I_TOR_KEY) TYPE  /BOBF/T_FRW_KEY
*"----------------------------------------------------------------------
  CONSTANTS: co_01  TYPE char2 VALUE '01',
             co_02  TYPE char2 VALUE '02',
             co_03  TYPE char2 VALUE '03',
             co_04  TYPE char2 VALUE '04',
             co_001 TYPE char3 VALUE '001',
             co_002 TYPE char3 VALUE '002',
             co_003 TYPE char3 VALUE '003',
             co_004 TYPE char3 VALUE '004',
             co_prd TYPE char3 VALUE 'PRD',
             co_fo  TYPE char2 VALUE 'FO',
             co_x   TYPE char1 VALUE 'X',
             index1 TYPE i VALUE 1.

  DATA: lo_srv_tor  TYPE REF TO /bobf/if_tra_service_manager,
        ls_selpar   TYPE /bobf/s_frw_query_selparam,
        lt_selpar   TYPE /bobf/t_frw_query_selparam,
        lt_tor_root TYPE /scmtms/t_tor_root_k,
        lt_tor_item TYPE /scmtms/t_tor_item_tr_k,
        lt_tor_stop TYPE /scmtms/t_tor_stop_k,
        lt_key_root TYPE /bobf/t_frw_key,
        lt_key_item TYPE /bobf/t_frw_key,
        s_data      TYPE /tenr/s_tmsicram_out,
        lo_message  TYPE REF TO /bobf/if_frw_message,
        lv_msg_text TYPE string.

  DATA: lo_proxy      TYPE REF TO /tenr/co_ws_oa_freight_order,
        lo_sicram_out TYPE /tenr/ws_shipment_documents1,
        lo_out_tab    TYPE /tenr/ws_shipment_document_tab,
        lo_out        TYPE /tenr/ws_shipment_documents_sh,
        lo_fault      TYPE REF TO cx_root. " Generic Fault


  FIELD-SYMBOLS <fs_root> TYPE /scmtms/s_tor_root_k.
  FIELD-SYMBOLS <fs_item> TYPE /scmtms/s_tor_item_tr_k.
  FIELD-SYMBOLS <fs_stop> TYPE /scmtms/s_tor_stop_k.


  lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).

**** set an example query parameter
***  ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
***  ls_selpar-option = 'EQ'.
***  ls_selpar-sign = 'I'.
***  ls_selpar-low = |{ i_tor ALPHA = IN }|.
***  APPEND ls_selpar TO lt_selpar.
***
***  "validamos la FO existe
***  lo_srv_tor->query(
***  EXPORTING
***  iv_query_key = /scmtms/if_tor_c=>sc_query-root-planning_attributes
***  it_selection_parameters = lt_selpar
***  iv_fill_data = abap_true
***  IMPORTING
***  et_data    = lt_tor_root
***  et_key     = lt_key_root ).}

  lo_srv_tor->retrieve(
  EXPORTING
    iv_node_key = /scmtms/if_tor_c=>sc_node-root
    it_key = i_tor_key
    iv_fill_data = abap_true
  IMPORTING
    et_data = lt_tor_root ).

  lo_srv_tor->retrieve_by_association(
  EXPORTING
    iv_node_key = /scmtms/if_tor_c=>sc_node-root
    it_key = i_tor_key
    iv_association = /scmtms/if_tor_c=>sc_association-root-stop
    iv_fill_data = abap_true
  IMPORTING
    et_data = lt_tor_stop ).

  IF lt_tor_root IS NOT INITIAL.

    "Si existe traemos el nodo item
    lo_srv_tor->retrieve_by_association(
    EXPORTING
    iv_node_key = /scmtms/if_tor_c=>sc_node-root
*    it_key  = lt_key_root
    it_key  = i_tor_key
    iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr
    iv_fill_data = abap_true
    IMPORTING
    et_data       = lt_tor_item
    et_target_key =  lt_key_item
    eo_message    = lo_message ).

    "Llenado de la tabla interna
    LOOP AT lt_tor_root ASSIGNING <fs_root>.
      "pendiente definir evento que lanzara esta funcion para determinar el campo upd_flag
**  Se toma del parámetro de entrada
      lo_out-upd_flag = i_upd_flag.
      lo_out-sap_process = <fs_root>-execution.

      DATA(lv_execution) = COND #( WHEN lo_out-sap_process EQ co_02 THEN co_002
                                     WHEN lo_out-sap_process EQ co_03 THEN co_003
                                     WHEN lo_out-sap_process EQ co_04 THEN co_004 ).

      CALL FUNCTION 'FORMAT_MESSAGE'
        EXPORTING
          id        = '/TENR/SICRAM'    " Application Area
          lang      = sy-langu
          no        = lv_execution
        IMPORTING
          msg       = lv_msg_text
        EXCEPTIONS
          not_found = 1.
      IF sy-subrc NE 0.
        "tratamiento de mensajes de error de la funcion
      ENDIF.

      lo_out-sap_process_desc = lv_msg_text.

      lo_out-shipment_doc = |{ <fs_root>-tor_id ALPHA = OUT }|.

      CONDENSE lo_out-shipment_doc NO-GAPS.

      lo_out-transp_type = <fs_root>-trmodcod.

      lo_out-transp_type_desc = COND #( WHEN lo_out-transp_type EQ co_01 THEN 'ROAD'
                                        WHEN lo_out-transp_type EQ co_02 THEN 'RAIL' ).

      lo_out-vendor = <fs_root>-tspid.

      SELECT * FROM but000 UP TO 1 ROWS
        INTO TABLE @DATA(lt_but000)
        WHERE partner = @<fs_root>-tspid.

      IF lt_but000 IS NOT INITIAL.
        lo_out-vendor_desc = lt_but000[ index1 ]-name_org1.
      ENDIF.

      TRY.
          DATA(ls_tor_stop) = lt_tor_stop[ stop_cat = 'O' ].
*          CONVERT TIME STAMP ls_tor_stop-aggr_assgn_start_l TIME ZONE sy-zonlo INTO DATE DATA(lv_fecha) TIME DATA(lv_hora).
*          lo_out-eda = lv_fecha && lv_hora.
          IF ls_tor_stop-stop_seq_pos = 'F'.          "Agregado 15.12.2023
            CONVERT TIME STAMP ls_tor_stop-plan_trans_time TIME ZONE 'CST' INTO DATE DATA(lv_fecha) TIME DATA(lv_hora). "sy-zonlo
            lo_out-eda = lv_fecha && lv_hora.
          ENDIF.


        CATCH cx_sy_itab_line_not_found.
      ENDTRY.



      "pendientes de deficion
      "lo_out-eha

      IF lt_tor_stop IS NOT INITIAL.                                        "Agregado 08.12.2023
        LOOP AT lt_tor_stop ASSIGNING <fs_stop> WHERE stop_seq_pos = 'L'.
          lo_out-shipto = <fs_stop>-log_locid.
        ENDLOOP.
      ENDIF.


      IF lt_tor_item IS NOT INITIAL.
        "      ASSIGN lt_tor_item[ item_type = 'PRD' ] TO <fs_item> .
        LOOP AT lt_tor_item ASSIGNING <fs_item> WHERE item_type = co_prd.
          IF <fs_item>-main_cargo_item EQ co_x.               "Agregado 01.12.2023
*            lo_out-loading_point = <fs_item>-src_loc_idtrq.
            lo_out-loading_point_desc = <fs_item>-src_loc_idtrq.
          ENDIF.
          lo_out-plant = <fs_item>-erp_plant_id.
        ENDLOOP.
      ENDIF.

      IF <fs_item> IS ASSIGNED.
        SELECT loc~locid, loc~adrnummer, loct~descr40
        INTO TABLE @DATA(lt_loct)
        FROM /sapapo/loc AS loc
        INNER JOIN /sapapo/loct AS loct
        ON loc~locid = loct~locid
        WHERE locno = @<fs_item>-erp_plant_id.

        IF lt_loct IS NOT INITIAL.
          LOOP AT lt_loct INTO DATA(ls_loct).
            "            DATA(ls_loct) = lt_loct[ index1 ].
            lo_out-plant_desc = ls_loct-descr40.
            EXIT.
          ENDLOOP.
        ENDIF.

        "pendiente definicion
        "lo_out-LOADING_POINT
        "lo_out-LOADING_POINT_DESC
        "lo_out-UNLOADING_POINT

        SELECT * FROM but000 UP TO 1 ROWS
        INTO TABLE @DATA(lt_but000_2)
        WHERE partner = @<fs_item>-consignee_id.

*        lo_out-shipto = <fs_item>-consignee_id.
        IF lt_tor_stop IS NOT INITIAL.                                        "Agregado 08.12.2023
          LOOP AT lt_tor_stop ASSIGNING <fs_stop> WHERE stop_seq_pos = 'L'.
            lo_out-shipto = <fs_stop>-log_locid.
          ENDLOOP.
        ENDIF.


        IF lt_but000_2 IS NOT INITIAL.
          "lo_out-shipto_desc = lt_but000_2[ index1 ]-name_last && lt_but000_2[ index1 ]-name_first.
          lo_out-shipto_desc = lt_but000_2[ index1 ]-name_org1 && lt_but000_2[ index1 ]-name_org2.
        ENDIF.

        SELECT * FROM /sapapo/loc UP TO 1 ROWS
           INTO TABLE @DATA(lt_loc)
           WHERE locno = @<fs_item>-des_loc_idtrq.

        lo_out-lgort = <fs_item>-lgort.

      ENDIF.

      SELECT * FROM adrc UP TO 1 ROWS
        INTO TABLE @DATA(lt_adrc)
        WHERE addrnumber = @ls_loct-adrnummer
        ORDER BY PRIMARY KEY.

      IF lt_adrc IS NOT INITIAL.
        lo_out-orig_city = lt_adrc[ index1 ]-city1.
        lo_out-orig_region = lt_adrc[ index1 ]-region.
      ENDIF.


      IF lt_loc IS NOT INITIAL.
        LOOP AT lt_loc INTO DATA(ls_loc).
*      DATA(ls_loc) = lt_loc[ index1 ].

          SELECT * FROM adrc UP TO 1 ROWS
          INTO TABLE @DATA(lt_adrc2)
          WHERE addrnumber = @ls_loc-adrnummer
            ORDER BY PRIMARY KEY.

          lo_out-dest_city = lt_adrc2[ index1 ]-city1.
          lo_out-dest_region = lt_adrc2[ index1 ]-region.
          CONTINUE.
        ENDLOOP.
      ENDIF.

      lo_out-total_weight = <fs_root>-gro_wei_val.
      "pendiente
      "lo_out-TOTAL_WEIGHT_OUM
      lo_out-op_code = co_fo.
      "lo_out-OP_CODE_DESC

      "pendiente no se sabe si se implementaran
      "lo_out-LSD
      "lo_out-LSH
      "lo_out-LED
      "lo_out-LEH
      "lo_out-USD
      "lo_out-USH
      "lo_out-UED
      "lo_out-UEH

      "pendiente
      "lo_out-LGOBE

      "no se enviaran
      "lo_out-SOLDTO
      "lo_out-SOLDTO_DESC
      "lo_out-MATNR
      "lo_out-SP_AGR_TXT

      "      APPEND lo_out TO lo_out_tab.
      APPEND lo_out TO lo_sicram_out-shipment_documents-shipment_document.

      CLEAR lo_out.

    ENDLOOP.

    IF lo_sicram_out-shipment_documents-shipment_document IS NOT INITIAL.

      CREATE OBJECT lo_proxy.

      TRY.
          lo_proxy->oa_freight_order( EXPORTING
                                            output = lo_sicram_out ).
        CATCH cx_root INTO lo_fault.

      ENDTRY.
      COMMIT WORK.
    ENDIF.


  ENDIF.

ENDFUNCTION.
