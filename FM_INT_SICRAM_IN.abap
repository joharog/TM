FUNCTION /tenr/fm_int_sicram_in.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(T_HEADER) TYPE  /TENR/T_TMSICRAM_IN
*"     VALUE(T_ITEM) TYPE  /TENR/T_TMSICRAM_ITEM
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------
  CONSTANTS co_et TYPE char1 VALUE '&'.

  DATA: lt_header    TYPE /scmtms/t_tor_actual_em_data,
        ls_header    TYPE /scmtms/s_tor_actual_em_data,
        lt_item      TYPE STANDARD TABLE OF /scmtms/s_tor_item_tr_k,
        lv_msg_text  TYPE string,
        lv_fecha     TYPE string,
        lv_date      TYPE d,
        lv_tiem      TYPE sy-uzeit,
        lv_timestamp TYPE timestamp,
        lv_time      TYPE t.
*BEGIN: RGS: Actualizar nodo ITEM_TR
  DATA: lt_selpar  TYPE /bobf/t_frw_query_selparam,
        lt_tor_qdb TYPE /scmtms/t_tor_root_k,
        ls_mod     TYPE /bobf/s_frw_modification,
        lt_mod     TYPE /bobf/t_frw_modification,
        lt_key     TYPE /bobf/t_frw_key.

*  DATA: header_sicram_in    TYPE char1,
*        item_sicram_in      TYPE char1,
*        departure_sicram_in TYPE char1,
*        clear_isin          TYPE char1,
*        clear_hsin          TYPE char1.

  FIELD-SYMBOLS: <chg_node>  TYPE /scmtms/s_tor_item_tr_k,
                 <chg_node2> TYPE /scmtms/s_tor_item_tr_k.
*end: RGS: Actualizar nodo ITEM_TR

*  DATA: lo_srv_tor TYPE REF TO /bobf/if_tra_service_manager,
*        ls_selpar  TYPE /bobf/s_frw_query_selparam,
*        lt_selpar  TYPE /bobf/t_frw_query_selparam.

*  DATA: lt_key     TYPE /bobf/t_frw_key.

*  DATA: io_read TYPE REF TO /bobf/if_frw_read,
*        lt_exec TYPE /scmtms/t_tor_exec_k,
*        lt_root TYPE /scmtms/t_tor_root_k.

* Get instance of service manager for TOR
*  lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).


** Se invirtio el proceso header->item a item-header.

*BEGIN: RGS: Actualizar nodo ITEM_TR

*  IF et_return[] IS INITIAL.

  DATA(lr_trq_srvmgr) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_tor_c=>sc_bo_key ).

  DATA(lo_tra) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

  LOOP AT t_item ASSIGNING FIELD-SYMBOL(<fs_item>).


    READ TABLE t_header INTO DATA(lw_header) WITH KEY tor_id = <fs_item>-tor_id.
    IF sy-subrc EQ 0.

      IF lw_header-stop_loc_id       IS NOT INITIAL AND
         lw_header-event_code        IS NOT INITIAL AND
         lw_header-event_source      IS NOT INITIAL AND
         lw_header-event_status      IS NOT INITIAL AND
         <fs_item>-platenumber       IS NOT INITIAL AND
         <fs_item>-zitem_descr_truck IS NOT INITIAL AND
         <fs_item>-pkgun_wei_val     IS NOT INITIAL.


        lt_selpar = VALUE #( ( sign           = 'I'
                               option         = 'EQ'
                               low            = <fs_item>-tor_id
                               attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id ) ).


        TRY.

            lr_trq_srvmgr->query(
              EXPORTING
                iv_query_key            = /scmtms/if_tor_c=>sc_query-root-root_elements
                it_selection_parameters = lt_selpar
                iv_fill_data            = abap_true
              IMPORTING
                eo_message              = DATA(lo_message)
                et_data                 = lt_tor_qdb
            ).

          CATCH /bobf/cx_frw INTO DATA(lx_frw).

        ENDTRY.

        IF lt_tor_qdb[] IS NOT INITIAL.


          IF ( <fs_item>-platenumber IS NOT INITIAL AND <fs_item>-zitem_descr_truck IS NOT INITIAL AND <fs_item>-pkgun_wei_val IS NOT INITIAL ).

            lt_key = VALUE #( ( key = lt_tor_qdb[ 1 ]-key ) ).
****************Node ITEM TRUC
            lr_trq_srvmgr->retrieve_by_association(
              EXPORTING
                iv_node_key    = /scmtms/if_tor_c=>sc_node-root
                it_key         = lt_key
                iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr
                iv_fill_data = abap_true
                IMPORTING
                  et_target_key = DATA(lt_block_key)
                  et_data       = lt_item
                  eo_message    = lo_message ).

            IF lt_block_key[] IS NOT INITIAL.

              IF line_exists(  lt_item[ item_type = 'TRUC' ] ).

                CREATE DATA ls_mod-data TYPE /scmtms/s_tor_item_tr_k.
                ASSIGN ls_mod-data->* TO <chg_node2>.

                DATA(ls_item) = lt_item[ item_type = 'TRUC' ] .

                ls_mod-node        = /scmtms/if_tor_c=>sc_node-item_tr.
                ls_mod-key         = lt_block_key[ key = ls_item-key ]-key.                              "
                ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_update.  " para actualizar


                <chg_node2>-platenumber = <fs_item>-platenumber.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-platenumber TO ls_mod-changed_fields.

                <chg_node2>-pkgun_wei_val = <fs_item>-pkgun_wei_val.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-pkgun_wei_val TO ls_mod-changed_fields.

                IF <fs_item>-zitem_descr_driver IS NOT INITIAL.
                  <chg_node2>-item_descr = <fs_item>-zitem_descr_truck.
                  APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-item_descr TO ls_mod-changed_fields.
                ENDIF.

                APPEND ls_mod TO lt_mod.
                CLEAR:ls_mod.

              ENDIF.

              CLEAR:ls_item.

              IF line_exists(  lt_item[ item_cat = 'DRI' ] ).

                CREATE DATA ls_mod-data TYPE /scmtms/s_tor_item_tr_k.
                ASSIGN ls_mod-data->* TO <chg_node>.

                ls_item = lt_item[ item_cat = 'DRI' ] .

                ls_mod-node        = /scmtms/if_tor_c=>sc_node-item_tr.
                ls_mod-key         = lt_block_key[ key = ls_item-key ]-key.                              "
                ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_update.  " para actualizar


                <chg_node>-platenumber = <fs_item>-platenumber.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-platenumber TO ls_mod-changed_fields.

                <chg_node>-pkgun_wei_val = <fs_item>-pkgun_wei_val.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-pkgun_wei_val TO ls_mod-changed_fields.

                IF <fs_item>-zitem_descr_driver IS NOT INITIAL.
                  <chg_node>-item_descr = <fs_item>-zitem_descr_driver.
                  APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-item_descr TO ls_mod-changed_fields.
                ENDIF.

                APPEND ls_mod TO lt_mod.
                CLEAR:ls_mod.

              ELSE.

*  lt_selpar = VALUE #( ( sign           = c_i
*                           option         = c_eq
*                           low            = wa_cancel-trq_id
*                           attribute_name = /scmtms/if_trq_c=>sc_query_attribute-root-root_elements-trq_id ) ).
** find a TRQ instance to be deleted
*
*    TRY.
*
*        lr_trq_srvmgr->query(
*          EXPORTING
*            iv_query_key            = /scmtms/if_trq_c=>sc_query-root-root_elements
*            it_selection_parameters = lt_selpar
*            iv_fill_data            = abap_true
*          IMPORTING
*            eo_message              = lo_message
*            et_data                 = lt_trq_qdb
*        ).
*
*      CATCH /bobf/cx_frw INTO DATA(lx_frw).
*
*    ENDTRY.
*
*    IF lt_trq_qdb[] IS NOT INITIAL.

*      lt_key = VALUE #( ( key = lt_trq_qdb[ 1 ]-key ) ).
*
*      CREATE DATA lr_s_parameters .
*      lr_s_parameters->no_check      = abap_true.
*      " lr_s_parameters->cncl_rsn_code = '01'.
*
*      DATA(lr_tra_mgr) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).
*
*      lr_trq_srvmgr->do_action(
*        EXPORTING
*          iv_act_key              = /scmtms/if_trq_c=>sc_action-root-cancel
*          it_key                  = lt_key
*          is_parameters           = lr_s_parameters
*        IMPORTING
*          eo_change               = lo_change
*          eo_message              = lo_message
*          et_failed_key           = lt_failed_key
*          et_failed_action_key    = lt_failed_act_key
*          ev_static_action_failed = DATA(failed)
*      ).
*
                CREATE DATA ls_mod-data TYPE /scmtms/s_tor_item_tr_k.
                ASSIGN ls_mod-data->* TO <chg_node>.

                "aqui solo consideramos creacion no actualizacion de los conductores
                ls_mod-node = /scmtms/if_tor_c=>sc_node-item_tr.
                ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_create.
                ls_mod-key = lr_trq_srvmgr->get_new_key( ).
                " ls_mod-root_key = '0050568C06951EDE8C95654AE6DC41C3'.
                ls_mod-source_key = lt_tor_qdb[ 1 ]-key.
                ls_mod-source_node = /scmtms/if_tor_c=>sc_node-root.
                ls_mod-association = /scmtms/if_tor_c=>sc_association-root-item_tr.

                "<fs_item_tr>-res_key = lt_driver_key[ 1 ]-key.
                <chg_node>-item_parent_key = lr_trq_srvmgr->get_new_key( ).
                <chg_node>-item_cat     = 'DRI'.
                <chg_node>-item_descr   = <fs_item>-zitem_descr_driver.
                <chg_node>-res_seq      = 1.
                <chg_node>-pkgun_wei_val = <fs_item>-pkgun_wei_val.
                <chg_node>-res_adhoc    = abap_true.
                <chg_node>-src_stop_key = lt_item[ 1 ]-src_stop_key.
                <chg_node>-des_stop_key = lt_item[ 1 ]-des_stop_key.

                "APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-res_key TO ls_mod-changed_fields.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-item_cat TO ls_mod-changed_fields.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-pkgun_wei_val TO ls_mod-changed_fields.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-item_descr TO ls_mod-changed_fields.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-res_adhoc TO ls_mod-changed_fields.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-res_seq TO ls_mod-changed_fields.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-item_parent_key TO ls_mod-changed_fields.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-src_stop_key TO ls_mod-changed_fields.
                APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-des_stop_key TO ls_mod-changed_fields.

                APPEND ls_mod TO lt_mod.


              ENDIF.

*              IF clear_isin EQ abap_true OR clear_hsin EQ abap_true.
*                CLEAR: header_sicram_in, item_sicram_in.
*                FREE MEMORY ID 'HSIN'.
*                FREE MEMORY ID 'ISIN'.
*              ELSEIF clear_isin EQ abap_false.
*                item_sicram_in = 'X'.
*                EXPORT item_sicram_in = item_sicram_in TO MEMORY ID 'ISIN'.
*                FREE MEMORY ID 'HSIN'.
*              ENDIF.



              lr_trq_srvmgr->modify( EXPORTING
                      it_modification = lt_mod
                      IMPORTING
                      eo_change  = DATA(lo_chg)
                      eo_message = lo_message ).


              lo_tra->save( IMPORTING
                            ev_rejected = DATA(lv_rejected)
                            eo_change = lo_chg
                            eo_message = lo_message
                            "et_rejecting_bo_key = lt_rej_bo_key
                            ).


              lo_message->get_messages( IMPORTING et_message = DATA(lt_message) )."Extraccion de mensajes


              IF lt_message IS NOT INITIAL.
                LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<ls_mess>).
                  DATA(lv_type) = <ls_mess>-message->get_text( ).
                ENDLOOP.
                et_return = VALUE #( type    = 'E'
                                     message = lt_message[ 1 ]-message->get_text( ) ). "Envio de mensajes de errores

              ELSE.

                et_return = VALUE #(  type   = 'S'
                                      message = |{ <fs_item>-tor_id } se actualizo exitosamente| ) .

              ENDIF.

            ELSE.
              APPEND VALUE #( type = 'E' message = |No existen registro TRUC para actualizar'| ) TO et_return.
              EXIT.
            ENDIF.

          ELSE.
            APPEND VALUE #( type = 'E' message = |Campos necesarios vacios para actualizar| ) TO et_return.
            EXIT.

          ENDIF.

        ENDIF.

      ELSE.

        APPEND VALUE #( type = 'E' message = |Campos necesarios vacios para actualizar| ) TO et_return.
        EXIT.

      ENDIF.

    ENDIF.

  ENDLOOP.

*  ENDIF.

*  FREE MEMORY ID 'HSIN'.
*  FREE MEMORY ID 'ISIN'.
*  FREE MEMORY ID 'DSIN'.
*  CLEAR: header_sicram_in, item_sicram_in, lw_item, s_header, ls_tvarvc.

*end: RGS: Actualizar nodo ITEM_TR

  IF et_return[] IS INITIAL.

    LOOP AT t_header INTO DATA(s_header).

      READ TABLE t_item INTO DATA(lw_item) WITH KEY tor_id = s_header-tor_id.
      IF sy-subrc EQ 0.

        IF s_header-stop_loc_id      IS NOT INITIAL AND
           s_header-event_code       IS NOT INITIAL AND
           s_header-event_source     IS NOT INITIAL AND
           s_header-event_status     IS NOT INITIAL AND
           lw_item-platenumber       IS NOT INITIAL AND
           lw_item-zitem_descr_truck IS NOT INITIAL AND
           lw_item-pkgun_wei_val     IS NOT INITIAL.


*          SELECT SINGLE * FROM tvarvc INTO @DATA(ls_tvarvc)
*            WHERE type EQ 'S'
*              AND low EQ @s_header-event_code.
*
*          CASE ls_tvarvc-low.
*            WHEN 'ARRIVAL_DOOR'.
*              clear_hsin = abap_true.
*              header_sicram_in = abap_true.
*              EXPORT header_sicram_in = header_sicram_in TO MEMORY ID 'HSIN'.
*            WHEN 'CHECK_IN'.
*              clear_isin = abap_true.
*              header_sicram_in = abap_true.
*              EXPORT header_sicram_in = header_sicram_in TO MEMORY ID 'HSIN'.
*            WHEN 'CHECK_OUT'.
*
*        clear_hsin = abap_true.
*        header_sicram_in = abap_true.
*        EXPORT header_sicram_in = header_sicram_in TO MEMORY ID 'HSIN'.

*        clear_isin = abap_true.
*        header_sicram_in = abap_true.
*        item_sicram_in = abap_true.
*        EXPORT header_sicram_in = header_sicram_in TO MEMORY ID 'HSIN'.
*        EXPORT item_sicram_in = item_sicram_in TO MEMORY ID 'ISIN'.
*            WHEN 'DEPARTURE'.
*        clear_isin = abap_true.
*        header_sicram_in = abap_true.
*        item_sicram_in = abap_true.
*        EXPORT header_sicram_in = header_sicram_in TO MEMORY ID 'HSIN'.
*        EXPORT item_sicram_in = item_sicram_in TO MEMORY ID 'ISIN'.
*            WHEN OTHERS.
*        ARRIVAL_DOOR
*        ARRIV_DEST
*        CHECK_IN
*        CHECK_OUT
*        DEPARTURE
*        DEPARTURE_DOOR
*        LOAD_BEGIN
*        LOAD_END
*        OTHER
*        OUT_FOR_DELIVERY
*        POD
*        POPU
*        UNLOAD_BEGIN
*        UNLOAD_END
*          ENDCASE.


*    DATA(lt_trq_srvmgr) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_tor_c=>sc_bo_key ).


*    REFRESH: lt_selpar, lt_tor_qdb.
*    CLEAR: ls_selpar.
*
*    ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
*    ls_selpar-option = 'EQ'.
*    ls_selpar-sign = 'I'.
*    ls_selpar-low = s_header-tor_id.
*    APPEND ls_selpar TO lt_selpar.
*
*    lo_srv_tor->query(
*    EXPORTING
*    iv_query_key = /scmtms/if_tor_c=>sc_query-root-root_elements
*    it_selection_parameters = lt_selpar
*    IMPORTING
*    eo_message = DATA(lo_message_root)
*    et_key     = lt_key  ).
*
*    IF lt_key[] IS NOT INITIAL.
*
*      SELECT * FROM /scmtms/d_torexe INTO TABLE @DATA(lt_torexe)
*        FOR ALL ENTRIES IN @lt_key
*        WHERE parent_key EQ @lt_key-key.
*
*      IF sy-subrc NE 0.
*        clear_hsin = abap_true.
*        header_sicram_in = abap_true.
*        EXPORT header_sicram_in = header_sicram_in TO MEMORY ID 'HSIN'.
*
*      ENDIF.
*
*    ENDIF.

*    IF header_sicram_in IS INITIAL.
*      clear_isin = abap_true.
*      header_sicram_in = abap_true.
*      EXPORT header_sicram_in = header_sicram_in TO MEMORY ID 'HSIN'.
*    ENDIF.


*    IF s_header-event_code EQ 'DEPARTURE'.
*
*      departure_sicram_in = abap_true.
*      EXPORT departure_sicram_in = departure_sicram_in TO MEMORY ID 'DSIN'.
*
*    ENDIF.



          "quito validaciones de campo y dejo todo a la funcion
*    CHECK s_header-tor_id IS NOT INITIAL.
*    CHECK s_header-actual_date IS NOT INITIAL.
*    CHECK s_header-stop_loc_id IS NOT INITIAL.
*    CHECK s_header-event_code IS NOT INITIAL.
*    CHECK s_header-event_source IS NOT INITIAL.
*    CHECK s_header-event_status IS NOT INITIAL.

          "se quitaron y se usa el move corresponding
*    ls_header-tor_id = t_header-tor_id.
*    ls_header-actual_date = t_header-actual_date.
*    ls_header-actual_tzone = t_header-actual_tzone.
*    ls_header-stop_loc_id = t_header-stop_loc_id.
*    ls_header-event_code = t_header-event_code.
*    ls_header-evnt_reason = t_header-evnt_reason.
*    ls_header-event_status = t_header-event_status.
          lv_fecha = s_header-actual_date.
          lv_date  = lv_fecha+0(8).
          lv_time  = lv_fecha+8(6).
          "lv_time = |{ lv_date+0(2) }{ lv_date+3(2) }00|.
          CONVERT DATE lv_date TIME lv_time INTO TIME STAMP lv_timestamp TIME ZONE 'UTC-5'.
          CLEAR: s_header-actual_date.
          s_header-actual_date = lv_timestamp.

          MOVE-CORRESPONDING s_header TO ls_header.

          ls_header-tor_id = |{ ls_header-tor_id ALPHA = IN }|.

          APPEND ls_header TO lt_header.

          CALL FUNCTION '/SCMTMS/EXECINFO_PROCESS'
            EXPORTING
              it_tor_actual_em_data = lt_header
            TABLES
              et_return             = et_return
            EXCEPTIONS
              not_processed         = 1
              OTHERS                = 2.

          IF sy-subrc NE 0.
            CALL FUNCTION 'FORMAT_MESSAGE'
              EXPORTING
                id   = '/TENR/SICRAM'    " Application Area
                lang = sy-langu
                no   = '006'
              IMPORTING
                msg  = lv_msg_text
                       EXCEPTIONS
                       not_found.

            REPLACE FIRST OCCURRENCE OF co_et IN lv_msg_text WITH ls_header-tor_id.
            REPLACE FIRST OCCURRENCE OF co_et IN lv_msg_text WITH ls_header-event_code.

            "'Evento: ' && ' ' && ls_header-event_code && ' ' && 'de Orden: ' && ' ' && ls_header-tor_id && ' ' && 'No actualizado'
            APPEND VALUE #( type = 'E' message = lv_msg_text ) TO et_return.
          ENDIF.

        ELSE.

          APPEND VALUE #( type = 'E' message = |Campos necesarios vacios para actualizar| ) TO et_return.
          EXIT.

        ENDIF.
      ENDIF.

    ENDLOOP.

  ENDIF.


ENDFUNCTION.
