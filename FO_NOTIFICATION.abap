*&---------------------------------------------------------------------*
*& Report /TENR/FO_NOTIFICATION
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT /tenr/fo_notification.

TABLES: /scmtms/d_torrot, bkpf.

DATA: lo_srv_tor    TYPE REF TO /bobf/if_tra_service_manager,
      lo_message    TYPE REF TO /bobf/if_frw_message,
      ls_selpar     TYPE /bobf/s_frw_query_selparam,
      lt_selpar     TYPE /bobf/t_frw_query_selparam,

      lt_root       TYPE /scmtms/t_tor_root_k,
      lt_root_bef   TYPE /scmtms/t_tor_root_k,
      lt_exec       TYPE /scmtms/t_tor_exec_k,
      lt_stop       TYPE /scmtms/t_tor_stop_k,
      lt_itemtr     TYPE /scmtms/t_tor_item_tr_k,
      lt_com_yms    TYPE /tenr/t_tmcomunyms_in,
      lo_proxy      TYPE REF TO /tenr/co_ws_oa_send_freight_or,
      ls_output     TYPE /tenr/ws_send_freight_order1,

      it_key_sicram TYPE /bobf/t_frw_key.

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS s_id FOR /scmtms/d_torrot-tor_id.
*  SELECT-OPTIONS s_date FOR bkpf-budat.
SELECTION-SCREEN: END OF BLOCK b1.

START-OF-SELECTION.

*  Get instance of service manager for TOR
  lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).

  LOOP AT s_id INTO DATA(ls_id).
    ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
    ls_selpar-sign = 'I'.
    ls_selpar-low = ls_id-low.
    ls_selpar-high = ls_id-high.
    IF ls_id-high IS NOT INITIAL.
      ls_selpar-option = 'BT'.
    ELSE.
      ls_selpar-option = 'EQ'.
    ENDIF.
    APPEND ls_selpar TO lt_selpar.
  ENDLOOP.


  lo_srv_tor->query(
  EXPORTING
    iv_query_key = /scmtms/if_tor_c=>sc_query-root-root_elements
    it_selection_parameters = lt_selpar
  IMPORTING
    et_key = DATA(lt_key) ).


  lo_srv_tor->retrieve(
          EXPORTING
            iv_node_key  = /scmtms/if_tor_c=>sc_node-root
            it_key       = lt_key
            iv_fill_data = abap_true
          IMPORTING
            et_data      = lt_root ).

  lo_srv_tor->retrieve(
    EXPORTING
      iv_node_key     = /scmtms/if_tor_c=>sc_node-root
      it_key          = lt_key
      iv_fill_data    = abap_true
      iv_before_image = abap_true
    IMPORTING
      et_data         = lt_root_bef ).

  lo_srv_tor->retrieve_by_association(
    EXPORTING
      iv_node_key    = /scmtms/if_tor_c=>sc_node-root
      it_key         = lt_key
      iv_fill_data   = abap_true
      iv_association = /scmtms/if_tor_c=>sc_association-root-exec
    IMPORTING
      et_data        = lt_exec ).

  lo_srv_tor->retrieve_by_association(
     EXPORTING
       iv_node_key       = /scmtms/if_tor_c=>sc_node-root
       it_key            = lt_key
       iv_association    = /scmtms/if_tor_c=>sc_association-root-stop
       iv_fill_data      = abap_true
     IMPORTING
       et_data           = lt_stop ).

*  lo_srv_tor->retrieve_by_association(
*     EXPORTING
*       iv_node_key     = /scmtms/if_tor_c=>sc_node-root
*       it_key          = lt_key
*       iv_association  = /scmtms/if_tor_c=>sc_association-root-item_tr
*       iv_fill_data    = abap_true
*       iv_before_image = abap_true
*       IMPORTING
*       et_data         =  lt_itemtr ).

  IF lt_root IS NOT INITIAL AND lt_root_bef IS NOT INITIAL.
    LOOP AT lt_root INTO DATA(ls_root).
*      TRY.

*          NEW zcl_tm_val_com_yms( )->send_data_yms(
*            EXPORTING
*              i_key     = ls_root-root_key
*              i_torid   = ls_root-tor_id
*              i_status  = 'U'
*              i_exec    = lt_exec
*              i_ttor    = lt_root
*            IMPORTING
*              e_com_yms =  lt_com_yms ).
*
*          READ TABLE lt_com_yms INTO DATA(ls_com_yms) INDEX 1.
*          IF sy-subrc EQ 0.

      DATA: lt_tmymspl1 TYPE TABLE OF /tenr/t_tmymspl1,
            ls_tmymspl1 TYPE /tenr/t_tmymspl1,
            lt_vlcomsgt TYPE TABLE OF /tenr/t_vlcomsgt,
            ls_vlcomsgt TYPE /tenr/t_vlcomsgt.

      ls_root-tor_id = |{ ls_root-tor_id ALPHA = IN }|.

*            ls_com_yms-fo_number = |{ ls_com_yms-fo_number ALPHA = IN }|.
*            SELECT * FROM /tenr/t_tmymspl1 INTO TABLE lt_tmymspl1 WHERE tor_id EQ ls_com_yms-fo_number.

      SELECT * FROM /tenr/t_tmymspl1 INTO TABLE lt_tmymspl1 WHERE tor_id EQ ls_root-tor_id.

      LOOP AT lt_tmymspl1 INTO ls_tmymspl1.

        ls_tmymspl1-sales_order       = |{ ls_tmymspl1-sales_order  ALPHA = OUT }|.
        ls_tmymspl1-sales_order_item  = |{ ls_tmymspl1-sales_order_item  ALPHA = OUT }|.

        SELECT SINGLE * FROM /tenr/t_vlcomsgt INTO ls_vlcomsgt
          WHERE tor_id          EQ ls_tmymspl1-tor_id
            AND zwerks          EQ ls_tmymspl1-zwerks
            AND sales_order     EQ ls_tmymspl1-sales_order
            AND sales_orderitem EQ ls_tmymspl1-sales_order_item
            AND zoperation      EQ ls_tmymspl1-zoperation.
        IF sy-subrc EQ 0.
          ls_output-send_freight_order-freight_order = CORRESPONDING #( ls_vlcomsgt ).

          IF ls_vlcomsgt-zoperation EQ 'U'.
            ls_vlcomsgt-zoperation = 'C'.
          ENDIF.

          ls_output-send_freight_order-freight_order-werehaouse = CONV char4( |{ ls_tmymspl1-zlgort }| ).
          ls_output-send_freight_order-freight_order-consignee = CONV char10( |{ ls_tmymspl1-consignee_id }| ).
          ls_output-send_freight_order-freight_order-consignee_desc = CONV char40( |{ ls_tmymspl1-consignee_descr }| ).
          ls_output-send_freight_order-freight_order-operation = CONV char1( |{ ls_vlcomsgt-zoperation }| ).
          ls_output-send_freight_order-freight_order-carrier  = CONV char10( |{ ls_vlcomsgt-tspid ALPHA = IN }| ).
          ls_output-send_freight_order-freight_order-zcontac = CONV char40( |{ ls_vlcomsgt-zcontact }| ).
          ls_output-send_freight_order-freight_order-shipping_date = CONV char8( |{ ls_vlcomsgt-zfecha_appoint }| ).
          ls_output-send_freight_order-freight_order-shipping_time = CONV char6( |{ ls_vlcomsgt-zhora_appoint }| ).

          ls_output-send_freight_order-freight_order-fo_number = CONV char20( |{ ls_vlcomsgt-tor_id ALPHA = IN }| ).
          ls_output-send_freight_order-freight_order-plant  = CONV char4( |{ ls_vlcomsgt-zwerks }| ).
          ls_output-send_freight_order-freight_order-sales_order = CONV char10( |{ ls_vlcomsgt-sales_order ALPHA = IN }| ).
          ls_output-send_freight_order-freight_order-sales_order_item = CONV char6( |{ ls_vlcomsgt-sales_orderitem ALPHA = IN }| ).
          ls_output-send_freight_order-freight_order-bussines_tr_doc_id = CONV char10( |{ ls_output-send_freight_order-freight_order-bussines_tr_doc_id ALPHA = IN }| ).
        ENDIF.

        TRY.
            CREATE OBJECT lo_proxy.
          CATCH cx_ai_system_fault.
        ENDTRY.

        IF lo_proxy IS BOUND.
          TRY .
              CALL METHOD lo_proxy->oa_send_freight_order
                EXPORTING
                  output = ls_output.

              COMMIT WORK.

              it_key_sicram = VALUE #( ( key = ls_root-key ) ).
              CALL FUNCTION '/TENR/FM_INT_SICRAM_OUT'
                EXPORTING
                  i_tor_key  = it_key_sicram
                  i_upd_flag = 'I'.

            CATCH cx_ai_system_fault INTO DATA(g_system_fault).
              DATA(r_error) = abap_true.
          ENDTRY.

        ENDIF.
        CLEAR: lo_proxy.
      ENDLOOP.

      DATA: lt_bal_msg TYPE /scmtms/t_bal_s_msg,
            ls_bal_msg TYPE bal_s_msg.

      ls_bal_msg-msgty = 'S'.
      ls_bal_msg-msgid = '/SCMTMS/APPLOG'.
      ls_bal_msg-msgno = '001'.
      APPEND ls_bal_msg TO lt_bal_msg.

      ls_bal_msg-msgty = 'S'.
      ls_bal_msg-msgid = '/SCMTMS/APPLOG'.
      ls_bal_msg-msgno = '005'.
      ls_bal_msg-msgv1 = sy-uname.
      ls_bal_msg-msgv2 = sy-datum.
      ls_bal_msg-msgv3 = sy-uzeit.
      APPEND ls_bal_msg TO lt_bal_msg.


      LOOP AT lt_tmymspl1 INTO ls_tmymspl1.

        ls_bal_msg-msgty = 'I'.
        ls_bal_msg-msgid = '/SCMTMS/BATCH_80'.
        ls_bal_msg-msgno = '011'.

        ls_tmymspl1-tor_id = |{ ls_tmymspl1-tor_id ALPHA = OUT }|.
        ls_tmymspl1-sales_order = |{ ls_tmymspl1-sales_order ALPHA = OUT }|.

        IF ls_tmymspl1-zoperation EQ 'U'.
          ls_tmymspl1-zoperation = 'C'.
        ENDIF.

        CONCATENATE ls_tmymspl1-tor_id ls_tmymspl1-zwerks INTO ls_bal_msg-msgv1 SEPARATED BY space.
        CONCATENATE ls_tmymspl1-sales_order ls_tmymspl1-zoperation INTO ls_bal_msg-msgv2 SEPARATED BY space.
        ls_bal_msg-msgv3 = sy-datum.
        ls_bal_msg-msgv4 = sy-uzeit.
        APPEND ls_bal_msg TO lt_bal_msg.
        CLEAR: ls_bal_msg.

      ENDLOOP.

      CALL METHOD /scmtms/cl_batch_helper_80=>show_application_log_in_popup
        EXPORTING
          it_bal_msg = lt_bal_msg.

      REFRESH: lt_bal_msg.

*          ENDIF.
*        CATCH cx_sy_itab_line_not_found.
*
*      ENDTRY.

    ENDLOOP.

  ENDIF.
