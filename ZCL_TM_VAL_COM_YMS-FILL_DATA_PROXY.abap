  METHOD fill_data_proxy.
    TYPES: lr_confirm_t TYPE RANGE OF /scmtms/tor_confirm_status.

    DATA: lt_selpar TYPE /bobf/t_frw_query_selparam,
          lt_key    TYPE /bobf/t_frw_key.

    DATA: lt_key_stop      TYPE /bobf/t_frw_key,
          ls_key_stop      TYPE /bobf/s_frw_key,
          lt_key_item      TYPE /bobf/t_frw_key,
          lt_item_key      TYPE /bobf/t_frw_key,

          lt_tor_stop_data TYPE /scmtms/t_tor_stop_k,
          lt_tor_item_data TYPE /scmtms/t_tor_item_tr_k,
          lt_fu_root_data  TYPE /scmtms/t_tor_root_k,
          lt_text_collect  TYPE /bobf/t_txc_root_k,
          lt_text          TYPE /bobf/t_txc_txt_k,
          lt_text_content  TYPE /bobf/t_txc_con_k,
          lo_message       TYPE REF TO /bobf/if_frw_message.

    DATA: lt_quantity TYPE zten_t_dats_adic_to.

    DATA: lt_key2       TYPE /bobf/t_frw_key,
          lt_text_key   TYPE /bobf/t_frw_key,
*          lo_message    TYPE REF TO /bobf/if_frw_message,
          lt_node_text  TYPE /bobf/t_txc_txt_k,
          lt_node_text2 TYPE /bobf/t_txc_txt_k,
          lt_content    TYPE /bobf/t_txc_con_k.

    DATA(lr_trq_srvmgr) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_tor_c=>sc_bo_key ).


    DATA: lv_sales_order TYPE char35.
    DATA: status_d  TYPE char1,
          fo_status TYPE char1.
    DATA: lt_proxy TYPE /tenr/t_tmcomunyms_in.


    DATA:
      "lt_data_sgt TYPE TABLE OF /tenr/t_vlcomsgt,
      "lt_data_yms TYPE TABLE OF /tenr/t_vlcomsgt,
      lt_data_sgt TYPE STANDARD TABLE OF st_tbsgt,
      lt_data_yms TYPE STANDARD TABLE OF st_tbyms,
      ls_vlcomsgt TYPE /tenr/t_vlcomsgt,
      ls_tmymspl  TYPE /tenr/t_tmymspl1,
      lt_tmymspl  TYPE TABLE OF /tenr/t_tmymspl1,
      lt_tmymspl1 TYPE TABLE OF /tenr/t_tmymspl1,
      lr_confirm  TYPE RANGE OF /scmtms/tor_confirm_status.

    TRY.
        DATA(lv_created) = i_troot[ 1 ]-created_on.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    IMPORT status_d = status_d FROM MEMORY ID 'STATUS_D'.   "status_d memory id from ZCL_DELETE_METHODS->CANCEL_CAPA_TOR
    IMPORT fo_status = fo_status FROM MEMORY ID 'FO_STATUS'. "Envio desde /TENR/FO_NOTIFICATION_STATUS

    REFRESH lt_tmymspl1.

    SELECT * FROM /tenr/t_tmymspl1
      FOR ALL ENTRIES IN @i_data
      WHERE tor_id = @i_data-tor_id
        AND sales_order = @i_data-base_btd_id
        AND sales_order_item = @i_data-base_btditem_id
      INTO TABLE @lt_tmymspl1.

    IF sy-subrc NE 0.
      SELECT * FROM /tenr/t_tmymspl1
       FOR ALL ENTRIES IN @i_data
       WHERE tor_id = @i_data-tor_id
         AND sales_order = @i_data-orig_btd_id
         AND sales_order_item = @i_data-orig_btditem_id
       INTO TABLE @lt_tmymspl1.
    ENDIF.

    "Forwarding order FWO
    IF sy-subrc NE 0.
      LOOP AT i_data INTO DATA(ls_data).

        lv_sales_order = |{ ls_data-trq_id ALPHA = IN }|.

        SELECT * FROM /tenr/t_tmymspl1
         WHERE tor_id = @ls_data-tor_id
           AND sales_order = @lv_sales_order
           AND sales_order_item = @ls_data-trq_item_id
         APPENDING TABLE @lt_tmymspl1.

        CLEAR: lv_sales_order.

      ENDLOOP.

    ENDIF.

    IF lt_tmymspl1 IS NOT INITIAL.
      DATA(ls_tmymspl1) = lt_tmymspl1[ 1 ].
      IF fo_status IS INITIAL.
        IF ls_tmymspl1-zstatus = '01'.
          EXIT.
        ENDIF.
      ENDIF.

    ELSE. "Cancela proceso de borrado si no existe registro de creacion en lt_tmymspl1
      IF status_d EQ 'D'.
        EXIT.
      ENDIF.
    ENDIF.
*      WHERE parent_key EQ @i_data-orig_ref_root
    lt_data_yms  = VALUE #( FOR ls_item IN i_data
                          ( tor_id  = ls_item-tor_id
                            btd_id  = COND #( WHEN VALUE #( gt_rig[ parent_key = ls_item-orig_ref_root ]-net_invoicing DEFAULT '' ) IS NOT INITIAL
                                      THEN |{ CONV char20( |{ VALUE #( gt_docref_data[ parent_key = ls_item-orig_ref_root ]-btd_id DEFAULT '' ) ALPHA = OUT }| ) ALPHA = IN }|
                                      ELSE '' )
                                      "|{ CONV char20( |{ VALUE #( gt_docref_data[ parent_key = ls_item-orig_ref_root ]-btd_id DEFAULT '' ) ALPHA = OUT }| ) ALPHA = IN }|
                            btd_tco = COND #( WHEN VALUE #( gt_rig[ parent_key = ls_item-orig_ref_root ]-net_invoicing DEFAULT '' ) IS NOT INITIAL
                                      THEN VALUE #( gt_docref_data[ parent_key = ls_item-orig_ref_root ]-btd_tco DEFAULT '' ) "gv_btd_tco "AD. SB 01.09.23
                                      ELSE '' )
                                      "VALUE #( gt_docref_data[ parent_key = ls_item-orig_ref_root ]-btd_tco DEFAULT '' )
                            btditem_id  = COND #( WHEN VALUE #( gt_rig[ parent_key = ls_item-orig_ref_root ]-net_invoicing DEFAULT '' ) IS NOT INITIAL
                                          THEN |{ CONV char6( |{ VALUE #( gt_docref_data[ parent_key = ls_item-orig_ref_root ]-btditem_id DEFAULT '' ) ALPHA = OUT }| ) ALPHA = IN }| "gv_btditem_id "AD. SB 01.09.23
                                          ELSE '' )
                                          "|{ VALUE #( gt_docref_data[ parent_key = ls_item-orig_ref_root ]-btditem_id DEFAULT '' ) ALPHA = OUT }|
                            execution         = ls_item-execution "AD. SB 01.09.23
                            zwerks            = i_werks  "get_werks( i_btd_id = ls_item-base_btd_id i_btditem_id = ls_item-base_btditem_id i_btd_tco = ls_item-base_btd_tco )
                            sales_order  = COND #( WHEN  ls_item-trq_cat = '01' OR ls_item-trq_cat = '05' THEN |{ ls_item-base_btd_id ALPHA = IN  }|
                                                   WHEN  ls_item-trq_cat = '02' OR ls_item-trq_cat = '06' THEN |{ ls_item-orig_btd_id ALPHA = IN }|
                                                   WHEN  ls_item-trq_cat = '03' THEN |{ ls_item-trq_id ALPHA = IN }|
                                                    )
                            sales_order_item = COND #( WHEN  ls_item-trq_cat = '01' OR ls_item-trq_cat = '05' THEN |{ ls_item-base_btditem_id ALPHA = IN }|
                                                       WHEN  ls_item-trq_cat = '02' OR ls_item-trq_cat = '06' THEN |{ ls_item-orig_btditem_id ALPHA = IN }|
                                                       WHEN  ls_item-trq_cat = '03' THEN |{ ls_item-trq_item_id ALPHA = IN }|
                                                        )
                            num_od = |{ COND #( WHEN  ls_item-trq_cat = '02' OR ls_item-trq_cat = '06' THEN ls_item-base_btd_id ) ALPHA = IN }|
                            item_od  = |{ COND #( WHEN ls_item-trq_cat = '02' OR ls_item-trq_cat = '06' THEN ls_item-base_btditem_id ) ALPHA = IN }|
                            zlgort            = i_lgort  "get_lgort( i_btd_id = ls_item-base_btd_id i_btditem_id = ls_item-base_btditem_id i_btd_tco = ls_item-base_btd_tco )
                            tspid             = ls_item-tspid
                            consignee_id      = ls_item-consignee_id
                            created_on        = lv_created
                            "vbeln             = ls_item-
                            zoperation        = COND #( WHEN lt_tmymspl1 IS INITIAL THEN 'C'
                                                        ELSE i_status )
                            zstatus           = ls_item-status
                            zfecha            = COND #( WHEN strlen( ls_item-aggr_assgn_start_l ) >= 8
                                                        THEN ls_item-aggr_assgn_start_l(8)
                                                        ELSE '' )
                                                "ls_item-aggr_assgn_start_l(8)
                            zhora             = COND #( WHEN strlen( ls_item-aggr_assgn_start_l ) >= 8
                                                        THEN convert_date( CONV char6( ls_item-aggr_assgn_start_l+8(6) ) )
                                                        ELSE '' )
                                                "convert_date( CONV char6( ls_item-aggr_assgn_start_l+8(6) ) )
                            zplan             = abap_true
                            consignee_descr    = ls_item-descr40
                            trq_cat            = ls_item-trq_cat
                            platenumber        = ls_item-platenumber
                            item_descr         = ls_item-item_descr
                             ) ).

    lt_data_sgt = VALUE #( FOR ls_itemsgt IN i_data ( tor_id        = ls_itemsgt-tor_id
                                                    zwerks            = i_werks "get_werks( i_btd_id = ls_itemsgt-base_btd_id i_btditem_id = ls_itemsgt-base_btditem_id i_btd_tco = ls_itemsgt-base_btd_tco )
                                                    sales_order  = COND #( WHEN  ls_itemsgt-trq_cat = '01' OR ls_itemsgt-trq_cat = '05' THEN  |{ ls_itemsgt-base_btd_id ALPHA = OUT } |
                                                                           WHEN  ls_itemsgt-trq_cat = '02' OR ls_itemsgt-trq_cat = '06' THEN  |{ ls_itemsgt-orig_btd_id ALPHA = OUT }|
                                                                           WHEN  ls_itemsgt-trq_cat = '03' THEN |{ ls_itemsgt-trq_id ALPHA = IN }|
                                                                           )
                                                    sales_orderitem = COND #( WHEN  ls_itemsgt-trq_cat = '01' OR ls_itemsgt-trq_cat = '05' THEN  |{ ls_itemsgt-base_btditem_id ALPHA = OUT } |
                                                                              WHEN  ls_itemsgt-trq_cat = '02' OR ls_itemsgt-trq_cat = '06' THEN  |{ ls_itemsgt-orig_btditem_id ALPHA = OUT } |
                                                                              WHEN  ls_itemsgt-trq_cat = '03' THEN |{ ls_itemsgt-trq_item_id ALPHA = IN }|
                                                                              )
                                                    num_od = COND #( WHEN  ls_itemsgt-trq_cat = '02' OR ls_itemsgt-trq_cat = '06' THEN |{ ls_itemsgt-base_btd_id ALPHA = OUT } | )
                                                    item_od  = COND #( WHEN  ls_itemsgt-trq_cat = '02' OR ls_itemsgt-trq_cat = '06' THEN  |{ ls_itemsgt-base_btditem_id ALPHA = OUT } | )
*                                                    zfecha          = sy-datum
                                                    tspid           = ls_itemsgt-tspid
                                                    name            = get_name_carrier( i_tspid = ls_itemsgt-tspid )
*                                                    zcontact = space
                                                    tel_number      = get_telnumber_carrier( i_tspid = ls_itemsgt-tspid )
                                                    zserreq         = VALUE #( gt_rig[ parent_key = ls_itemsgt-orig_ref_root ]-service_request DEFAULT '' )"gv_service_request
                                                    zsritrq         = gv_req_item_num
                                                    zfecha  = COND #( WHEN strlen( ls_itemsgt-aggr_assgn_start_l ) >= 8
                                                        THEN ls_itemsgt-aggr_assgn_start_l(8)
                                                        ELSE '' )
                                                    "ls_itemsgt-aggr_assgn_start_l(8)
                                                    zhora             = COND #( WHEN strlen( ls_itemsgt-aggr_assgn_start_l ) >= 8
                                                        THEN convert_date( CONV char6( ls_itemsgt-aggr_assgn_start_l+8(6) ) )
                                                        ELSE '' )
                                                    "convert_date( CONV char6( ls_itemsgt-aggr_assgn_start_l+8(6) ) )
                                                    trq_cat            = ls_itemsgt-trq_cat
                                                    ) ).

*    lr_confirm = VALUE lr_confirm_t(
*              LET s = 'I'
*                  o = 'EQ'
*              IN sign   = s
*                 option = o
*                 ( low = '01' )
*                 ( low = '02' )
*                 ( low = '03' )
*                 ( low = '06' )
*                 ( low = '11' ) ).

*    IF lt_data_yms IS NOT INITIAL.
*      READ TABLE lt_data_yms INTO DATA(ls_data_yms) INDEX 1.
*      ls_tmymspl = CORRESPONDING #( ls_data_yms ).
*      MODIFY /tenr/t_tmymspl1 FROM ls_tmymspl.
*    ENDIF.
    LOOP AT lt_data_yms INTO DATA(ls_data_yms).
      ls_tmymspl = CORRESPONDING #( ls_data_yms ).
      MODIFY /tenr/t_tmymspl1 FROM ls_tmymspl.
    ENDLOOP.


*    IF lt_data_sgt IS NOT INITIAL.
*      READ TABLE lt_data_sgt INTO DATA(ls_data_sgt) INDEX 1.
*      ls_vlcomsgt = CORRESPONDING #( ls_data_sgt ).
*      MODIFY /tenr/t_vlcomsgt FROM ls_vlcomsgt.
*    ENDIF.


    LOOP AT lt_data_sgt INTO DATA(ls_data_sgt).
      ls_vlcomsgt = CORRESPONDING #( ls_data_sgt ).
      ls_vlcomsgt-zfecha_appoint = ls_data_sgt-zfecha.
      ls_vlcomsgt-zhora_appoint = ls_data_sgt-zhora.
      ls_vlcomsgt-zoperation = COND #( WHEN lt_tmymspl1 IS INITIAL THEN 'C'
                                                        ELSE i_status ).
      "COMMENT 05.01.2024 - Se movio al final del codigo
*      MODIFY /tenr/t_vlcomsgt FROM ls_vlcomsgt.
    ENDLOOP.

**  Obtener nodo STOP
    LOOP AT i_troot INTO DATA(ls_troot).
      ls_key_stop-key = ls_troot-key.
      APPEND ls_key_stop TO lt_key_stop.
    ENDLOOP.

    lr_trq_srvmgr->retrieve_by_association(
       EXPORTING
         iv_node_key       = /scmtms/if_tor_c=>sc_node-root
         it_key            = lt_key_stop
         iv_association    = /scmtms/if_tor_c=>sc_association-root-stop
         iv_fill_data      = abap_true
       IMPORTING
         et_data           = lt_tor_stop_data
         et_target_key     = DATA(lt_tor_stop_key) ).

** Obtener nodo ITEM_TR
    IF status_d NE 'D'.
      lr_trq_srvmgr->retrieve_by_association(
        EXPORTING
          iv_node_key    = /scmtms/if_tor_c=>sc_node-root
          it_key         = lt_key_stop
          iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr
          iv_fill_data = abap_true
          IMPORTING
            et_data       = lt_tor_item_data
            et_target_key = lt_item_key
            eo_message    = lo_message ).

* Obtener nodo FU_ROOT
      lr_trq_srvmgr->retrieve_by_association(
        EXPORTING
          iv_node_key    = /scmtms/if_tor_c=>sc_node-item_tr
          it_key         = lt_item_key
          iv_association = /scmtms/if_tor_c=>sc_association-item_tr-fu_root
          iv_fill_data   = abap_true
          IMPORTING
            et_data       = lt_fu_root_data
            eo_message    = lo_message ).

    ELSE.

      lr_trq_srvmgr->retrieve_by_association(
     EXPORTING
       iv_node_key    = /scmtms/if_tor_c=>sc_node-root
       it_key         = lt_key_stop
       iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr
       iv_fill_data   = abap_true
       iv_before_image = abap_true
       IMPORTING
         et_data       = lt_tor_item_data
         et_target_key = lt_item_key
         eo_message    = lo_message ).

      lr_trq_srvmgr->retrieve_by_association(
        EXPORTING
          iv_node_key    = /scmtms/if_tor_c=>sc_node-item_tr
          it_key         = lt_item_key
          iv_association = /scmtms/if_tor_c=>sc_association-item_tr-fu_root
          iv_fill_data   = abap_true
          iv_before_image = abap_true
          IMPORTING
            et_data       = lt_fu_root_data
            eo_message    = lo_message ).
    ENDIF.


    IF ls_tmymspl IS NOT INITIAL AND ls_vlcomsgt IS NOT INITIAL.
      LOOP AT lt_data_yms INTO ls_data_yms.
        ls_tmymspl = CORRESPONDING #( ls_data_yms ).
        TRY .
            ls_data_sgt = lt_data_sgt[ tor_id = ls_tmymspl-tor_id ].
            ls_vlcomsgt = CORRESPONDING #( ls_data_sgt ).
          CATCH cx_sy_itab_line_not_found.
        ENDTRY.
        INSERT INITIAL LINE INTO TABLE lt_proxy ASSIGNING FIELD-SYMBOL(<lfs_proxy>).

        <lfs_proxy>-fo_number = |{ ls_tmymspl-tor_id ALPHA = OUT }| .
*      <lfs_proxy>-plant = COND #( WHEN ls_tmymspl-zoperation = 'D' THEN ''
*                                  ELSE 'TTS4' ).  "ls_tmymspl-zwerks.
*      <lfs_proxy>-sales_order = COND #( WHEN ls_tmymspl-zoperation = 'D' THEN ''
*                                        ELSE |{ CONV vbeln( |{ ls_tmymspl-sales_order ALPHA = OUT  }| ) ALPHA = IN }| ).
*      <lfs_proxy>-sales_order_item = COND #( WHEN ls_tmymspl-zoperation = 'D' THEN ''
*                                        ELSE |{ CONV char4( |{ ls_tmymspl-sales_order_item ALPHA = OUT  }| ) ALPHA = IN }| ).
*      <lfs_proxy>-werehaouse = COND #( WHEN ls_tmymspl-zoperation = 'D' THEN ''
*                                       ELSE 'TTS4' ).  " ls_tmymspl-zlgort.
        <lfs_proxy>-plant = ls_tmymspl-zwerks. "'TTS4'.
        <lfs_proxy>-sales_order = |{ CONV vbeln( |{ ls_tmymspl-sales_order ALPHA = OUT  }| ) ALPHA = IN }| .
        <lfs_proxy>-sales_order_item = |{ CONV char6( |{ ls_tmymspl-sales_order_item ALPHA = OUT  }| ) ALPHA = IN }|.
        <lfs_proxy>-werehaouse = ls_tmymspl-zlgort. "'TTS4'
        <lfs_proxy>-carrier = ls_tmymspl-tspid.
        <lfs_proxy>-name = ls_vlcomsgt-name.
        <lfs_proxy>-zcontac = ls_vlcomsgt-zcontact.
        <lfs_proxy>-tel_number = ls_vlcomsgt-tel_number.
*      <lfs_proxy>-consignee = COND #( WHEN ls_tmymspl-zoperation = 'D' THEN ''
*                                      ELSE ls_tmymspl-consignee_id ).
        <lfs_proxy>-consignee = ls_tmymspl-consignee_id.
        <lfs_proxy>-consignee_descr = ls_tmymspl-consignee_descr.
        <lfs_proxy>-zserrreq = ls_vlcomsgt-zserreq.
        <lfs_proxy>-zritrq = ls_vlcomsgt-zsritrq.
*      <lfs_proxy>-bussines_tr_doc_id = COND #( WHEN ls_tmymspl-zoperation = 'D' THEN ''
*                                       ELSE |{ CONV char10( |{ ls_tmymspl-btd_id ALPHA = OUT  }| ) ALPHA = IN }| ).
*      <lfs_proxy>-doc_type = COND #( WHEN ls_tmymspl-zoperation = 'D' THEN ''
*                                     ELSE ls_tmymspl-btd_tco ).
*      <lfs_proxy>-item = COND #( WHEN ls_tmymspl-zoperation = 'D' THEN ''
*                                 ELSE |{ CONV char6( |{ ls_tmymspl-btditem_id ALPHA = OUT  }| ) ALPHA = IN }| ).
        <lfs_proxy>-bussines_tr_doc_id = |{ CONV char10( |{ ls_tmymspl-btd_id ALPHA = OUT  }| ) ALPHA = IN }|.
        <lfs_proxy>-doc_type = ls_tmymspl-btd_tco.
        <lfs_proxy>-item = |{ CONV char6( |{ ls_tmymspl-btditem_id ALPHA = OUT  }| ) ALPHA = IN }|. "jsl 230124 cambio a 6 caracteres CHAR3
        <lfs_proxy>-acc_assig = ls_tmymspl-vbeln.
        <lfs_proxy>-operation = ls_tmymspl-zoperation.
        <lfs_proxy>-creacion_date = ls_tmymspl-created_on.
        <lfs_proxy>-status = ls_tmymspl-zstatus.

*        <lfs_proxy>-shipping_date = ls_tmymspl-zfecha.
*        <lfs_proxy>-shipping_time = ls_tmymspl-zhora.
        DATA(ls_tor_stop_data) = lt_tor_stop_data[ stop_cat = 'O' ].    "Agregado 15.12.2023
        IF ls_tor_stop_data-stop_seq_pos = 'F'.
          CONVERT TIME STAMP ls_tor_stop_data-plan_trans_time TIME ZONE 'CST' INTO DATE DATA(lv_fecha) TIME DATA(lv_hora). "sy-zonlo
          <lfs_proxy>-shipping_date = lv_fecha.
          <lfs_proxy>-shipping_time = lv_hora.
        ENDIF.

        <lfs_proxy>-num_od  = |{ CONV char10( |{ ls_tmymspl-num_od ALPHA = OUT  }| ) ALPHA = IN }|.
        <lfs_proxy>-item_od = |{ CONV char6( |{ ls_tmymspl-item_od ALPHA = OUT  }| ) ALPHA = IN }|.
        <lfs_proxy>-trq_cat = ls_data_yms-trq_cat.
        <lfs_proxy>-plate   = ls_data_yms-platenumber.
        <lfs_proxy>-driver_desc = ls_data_yms-item_descr.

**************************************************************************************************************************
*     NUEVOS CAMPOS SGT YMS
**************************************************************************************************************************
*      Mail Carrier
        SELECT * FROM adr6 INTO TABLE @DATA(lt_adr6) WHERE addrnumber EQ ( SELECT addrnumber FROM but020 WHERE partner EQ @ls_tmymspl-tspid ).
        LOOP AT lt_adr6 INTO DATA(ls_adr6).
          IF ls_adr6-smtp_addr IS NOT INITIAL.
            IF sy-tabix EQ 1.
              <lfs_proxy>-mail_carrier = ls_adr6-smtp_addr.
            ELSE.
              CONCATENATE <lfs_proxy>-mail_carrier ls_adr6-smtp_addr INTO <lfs_proxy>-mail_carrier SEPARATED BY ';'.
            ENDIF.
          ENDIF.
          CLEAR: ls_adr6.
        ENDLOOP.
        REFRESH: lt_adr6.

        CLEAR: ls_tor_stop_data.
        IF line_exists( lt_tor_stop_data[ stop_seq_pos = 'F' ] ).
          ls_tor_stop_data = lt_tor_stop_data[ stop_seq_pos = 'F' ].
          IF ls_tor_stop_data-stop_seq_pos EQ 'F'.
*      Origin Addres
            SELECT SINGLE * FROM /sapapo/v_locadr INTO @DATA(ls_locadr) WHERE locno EQ @ls_tor_stop_data-log_locid.
            CONCATENATE ls_locadr-street ls_locadr-house_number INTO <lfs_proxy>-origin_address.

*      Storage Location Origin
            SELECT SINGLE descr40 FROM /sapapo/loct INTO <lfs_proxy>-source_log_locid WHERE locid EQ
              ( SELECT locid FROM /sapapo/loc WHERE locno EQ ls_tor_stop_data-log_locid ).

          ENDIF.
          CLEAR: ls_locadr.
        ENDIF.

        CLEAR: ls_tor_stop_data.
        IF line_exists( lt_tor_stop_data[ stop_seq_pos = 'L' ] ).
          ls_tor_stop_data = lt_tor_stop_data[ stop_seq_pos = 'L' ].
          IF ls_tor_stop_data-stop_seq_pos = 'L'.
*      Destination Address
            SELECT SINGLE * FROM /sapapo/v_locadr INTO ls_locadr WHERE locno EQ ls_tor_stop_data-log_locid.
            CONCATENATE ls_locadr-street ls_locadr-house_number INTO <lfs_proxy>-destination_address.

*      Destination City
            <lfs_proxy>-destination_city = ls_locadr-city.

*      Region (destination)
            <lfs_proxy>-destination_region = ls_locadr-region.

*      Zip Code (destination)
            <lfs_proxy>-destination_zip_code = ls_locadr-code.

*      Country destination
            <lfs_proxy>-destination_country = ls_locadr-country.

*     Storage Location Destination
            SELECT SINGLE descr40 FROM /sapapo/loct INTO <lfs_proxy>-destination_log_locid WHERE locid EQ
              ( SELECT locid FROM /sapapo/loc WHERE locno EQ ls_tor_stop_data-log_locid ).

            CLEAR: ls_locadr.
          ENDIF.
        ENDIF.

        IF line_exists( lt_tor_item_data[ item_cat = 'PRD' main_cargo_item = 'X' ] ).

          DATA(ls_tor_item_data) = lt_tor_item_data[ item_cat = 'PRD' main_cargo_item = 'X' ].
*      FU_Number
          <lfs_proxy>-fu_root = VALUE #( lt_fu_root_data[ key = ls_tor_item_data-fu_root_key ]-tor_id  OPTIONAL ).

*      Material Description
          <lfs_proxy>-item_descr = VALUE #( lt_tor_item_data[ item_cat = 'PRD' main_cargo_item = 'X' ]-item_descr OPTIONAL ).

*      Weight (FU)
          <lfs_proxy>-gro_wei_val = VALUE #( lt_tor_item_data[ item_cat = 'PRD' main_cargo_item = 'X' ]-gro_wei_val OPTIONAL ).

*      Number of PZA
          <lfs_proxy>-qua_pcs_val = VALUE #( lt_tor_item_data[ item_cat = 'PRD' main_cargo_item = 'X' ]-qua_pcs_val OPTIONAL ).

*      Length
          lt_key_item = VALUE #( FOR ls_item_tr IN lt_tor_item_data WHERE ( item_cat = 'PRD' AND main_cargo_item = 'X' )
                               ( key = ls_item_tr-ref_root_key ) ).

          CALL FUNCTION '/TENR/FM_GET_QUANTITY_FT'
            EXPORTING
              it_key      = lt_key_item
            IMPORTING
              et_quantity = lt_quantity.

          READ TABLE lt_quantity INTO DATA(ls_quantity) INDEX 1.
          IF sy-subrc EQ 0.
            IF status_d NE'D'.
              <lfs_proxy>-quantity = ls_quantity-gro_wei_val.
            ELSE.
              <lfs_proxy>-quantity = '0.00000000000000'.
            ENDIF.
            CLEAR: ls_quantity.
            REFRESH: lt_quantity.
          ENDIF.

        ENDIF.
**      Special Instructions/Notes

* Obtener nodo Text Collection
        lr_trq_srvmgr->retrieve_by_association(
          EXPORTING
            iv_node_key    = /scmtms/if_tor_c=>sc_node-root
            it_key         = lt_key_stop
            iv_association = /scmtms/if_tor_c=>sc_association-root-textcollection
            IMPORTING
              et_target_key = DATA(lt_textcoll_key)
              eo_message    = lo_message ).

        /scmtms/cl_common_helper=>get_do_keys_4_rba( EXPORTING
                                                          iv_host_bo_key = /scmtms/if_tor_c=>sc_bo_key
                                                          iv_host_do_node_key = /scmtms/if_tor_c=>sc_node-textcollection
                                                          iv_do_assoc_key = /bobf/if_txc_c=>sc_association-root-text
                                                          IMPORTING
                                                          ev_assoc_key = DATA(lv_text_assoc_key) ).

        lr_trq_srvmgr->retrieve_by_association( EXPORTING
                                                iv_node_key    = /scmtms/if_tor_c=>sc_node-textcollection
                                                it_key         = lt_textcoll_key
                                                iv_association = lv_text_assoc_key
                                                iv_fill_data   = abap_true
                                                IMPORTING
                                                eo_message    = lo_message
                                                et_key_link   = DATA(lt_link_txctext)
                                                et_target_key = DATA(lt_txc_text_key)
                                                et_data       = lt_node_text ).

        IF line_exists( lt_node_text[ text_type = 'AIR03' ] ).

          lt_text_key  = VALUE #( FOR ls_node_text IN lt_node_text WHERE ( text_type = 'AIR03' )
                               ( key = ls_node_text-key ) ).

          "Llaves intermedias
          /scmtms/cl_common_helper=>get_do_keys_4_rba( EXPORTING
                                                        iv_host_bo_key = /scmtms/if_tor_c=>sc_bo_key
                                                        iv_host_do_node_key = /scmtms/if_tor_c=>sc_node-textcollection
                                                        iv_do_node_key = /bobf/if_txc_c=>sc_node-text
                                                        IMPORTING
                                                        ev_node_key = DATA(lv_text_node_key) ).
          "Llaves intermedias
          /scmtms/cl_common_helper=>get_do_keys_4_rba( EXPORTING
                                                      iv_host_bo_key = /scmtms/if_tor_c=>sc_bo_key
                                                      iv_host_do_node_key = /scmtms/if_tor_c=>sc_node-textcollection
                                                      iv_do_node_key = /bobf/if_txc_c=>sc_node-text_content
                                                      iv_do_assoc_key = /bobf/if_txc_c=>sc_association-text-text_content
                                                      IMPORTING
                                                      ev_node_key = DATA(lv_content_node_key)
                                                      ev_assoc_key = DATA(lv_content_assoc_key) ).

          lr_trq_srvmgr->retrieve_by_association(
                                                      EXPORTING
                                                      iv_node_key    = lv_text_node_key
                                                      it_key         = lt_text_key "lt_txc_text_key
                                                      iv_association = lv_content_assoc_key
                                                      iv_fill_data   = abap_true
                                                      IMPORTING
                                                      eo_message     = DATA(lo_messagect)
                                                      et_data        = lt_content ).

          READ TABLE  lt_content INTO DATA(ls_content) INDEX 1.
          IF sy-subrc EQ 0.
            <lfs_proxy>-notes = ls_content-text.
          ENDIF.

        ENDIF.

      ENDLOOP.
    ENDIF.

    LOOP AT lt_proxy INTO DATA(ls_proxy).
      ls_proxy-fo_number         = |{ ls_proxy-fo_number ALPHA = IN }|.
      ls_proxy-sales_order       = |{ ls_proxy-sales_order  ALPHA = OUT }|.
      ls_proxy-sales_order_item  = |{ ls_proxy-sales_order_item  ALPHA = OUT }|.

      READ TABLE lt_data_sgt INTO ls_data_sgt
      WITH KEY tor_id = ls_proxy-fo_number
               sales_order = ls_proxy-sales_order
               sales_orderitem = ls_proxy-sales_order_item.

      "Search Forwarding order FWO
      IF sy-subrc NE 0.
        ls_proxy-fo_number    = |{ ls_proxy-fo_number ALPHA = IN }|.
        DATA(lv_sales_o)      = CONV char35( |{ ls_proxy-sales_order ALPHA = IN }| ).
        DATA(lv_sales_o_item) = CONV char10( |{ ls_proxy-sales_order_item ALPHA = IN }| ).

        READ TABLE lt_data_sgt INTO ls_data_sgt
        WITH KEY tor_id = ls_proxy-fo_number
                 sales_order = lv_sales_o
                 sales_orderitem = lv_sales_o_item.
      ENDIF.


      IF NOT ls_data_sgt IS INITIAL.
        ls_vlcomsgt = CORRESPONDING #( ls_data_sgt ).
        ls_vlcomsgt-zfecha_appoint = ls_data_sgt-zfecha.
        ls_vlcomsgt-zhora_appoint  = ls_data_sgt-zhora.

        IF ls_proxy-fo_number EQ ls_data_sgt-tor_id.
          ls_vlcomsgt-sales_order           = |{ ls_proxy-sales_order ALPHA = OUT }|.
          ls_vlcomsgt-sales_orderitem       = |{ ls_proxy-sales_order_item ALPHA = OUT }|.
          ls_vlcomsgt-zlgort                = ls_proxy-werehaouse.
          ls_vlcomsgt-zoperation            = ls_proxy-operation.
          ls_vlcomsgt-mail_carrier          = ls_proxy-mail_carrier.
          ls_vlcomsgt-origin_address        = ls_proxy-origin_address.
          ls_vlcomsgt-source_log_locid      = ls_proxy-source_log_locid.
          ls_vlcomsgt-destination_address   = ls_proxy-destination_address.
          ls_vlcomsgt-destination_city      = ls_proxy-destination_city.
          ls_vlcomsgt-destination_region    = ls_proxy-destination_region.
          ls_vlcomsgt-destination_zip_code  = ls_proxy-destination_zip_code.
          ls_vlcomsgt-destination_country   = ls_proxy-destination_country.
          ls_vlcomsgt-destination_log_locid = ls_proxy-destination_log_locid.
          ls_vlcomsgt-notes                 = ls_proxy-notes.
          ls_vlcomsgt-qua_pcs_val           = ls_proxy-qua_pcs_val.
          ls_vlcomsgt-quantity              = ls_proxy-quantity.
          ls_vlcomsgt-gro_wei_val           = ls_proxy-gro_wei_val.
          ls_vlcomsgt-item_descr            = ls_proxy-item_descr.
          ls_vlcomsgt-fu_root               = ls_proxy-fu_root.
        ENDIF.

        MODIFY /tenr/t_vlcomsgt FROM ls_vlcomsgt.
      ENDIF.
    ENDLOOP.

*      IF <lfs_proxy> IS ASSIGNED.
*        e_proxy = lt_proxy.
*      ENDIF.

    e_proxy = lt_proxy.

    FREE MEMORY ID status_d.

  ENDMETHOD.
