  METHOD /bobf/if_frw_determination~execute.

    DATA: lt_root        TYPE /scmtms/t_tor_root_k,
          lt_exec        TYPE /scmtms/t_tor_exec_k,
          lt_com_yms     TYPE /tenr/t_tmcomunyms_in,
          lo_proxy       TYPE REF TO /tenr/co_ws_oa_send_freight_or,
          ls_output      TYPE /tenr/ws_send_freight_order1,
          lt_root_key    TYPE /bobf/t_frw_key,
          lt_root_fo_key TYPE /bobf/t_frw_key,
          lt_root_fu_key TYPE /bobf/t_frw_key,
          lt_item_fo_key TYPE /bobf/t_frw_key,
          lt_item_fu_key TYPE /bobf/t_frw_key,
          status_d       TYPE char1.

    DATA: lo_srv_tor  TYPE REF TO /bobf/if_tra_service_manager.

    lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).

    CALL METHOD io_read->retrieve
      EXPORTING
        iv_node      = /scmtms/if_tor_c=>sc_node-root
        it_key       = it_key
        iv_fill_data = abap_true
      IMPORTING
        et_data      = lt_root.

    DELETE lt_root WHERE tor_cat NE 'TO'.

    CALL METHOD io_read->retrieve_by_association
      EXPORTING
        iv_node        = /scmtms/if_tor_c=>sc_node-root
        it_key         = it_key
        iv_fill_data   = abap_true
        iv_association = /scmtms/if_tor_c=>sc_association-root-exec
      IMPORTING
        et_data        = lt_exec.


    LOOP AT lt_root INTO DATA(ls_root) WHERE lifecycle = '10'.

      lt_root_fo_key = VALUE #( ( key = ls_root-key ) ).

*     Busca si la FO tiene asignada una FU
      lo_srv_tor->retrieve_by_association(
      EXPORTING
        iv_node_key = /scmtms/if_tor_c=>sc_node-root
        it_key = lt_root_fo_key
        iv_association = /scmtms/if_tor_c=>sc_association-root-assigned_fus
      IMPORTING
        et_target_key = lt_root_fu_key ).

*     Busca el item de la FU que esta asignado
      lo_srv_tor->retrieve_by_association(
      EXPORTING
        iv_node_key = /scmtms/if_tor_c=>sc_node-root
        it_key = lt_root_fu_key
        iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr_fu_item
      IMPORTING
        et_target_key = lt_item_fu_key ).

*     Busca con el item de la FU el item de la FO que esta asignada a la FU
      lo_srv_tor->retrieve_by_association(
      EXPORTING
        iv_node_key = /scmtms/if_tor_c=>sc_node-item_tr
        it_key = lt_item_fu_key
        iv_association = /scmtms/if_tor_c=>sc_association-item_tr-ref_item_tr
      IMPORTING
         et_target_key = lt_item_fo_key ).

      status_d   = 'D'.
      EXPORT status_d = status_d TO MEMORY ID 'STATUS_D'.

      lt_root_key = VALUE #( ( key = ls_root-key ) ).

      TRY.

          NEW zcl_tm_val_com_yms( )->send_data_yms(
            EXPORTING
              i_key     = ls_root-root_key
              i_torid   = ls_root-tor_id
              i_status  = status_d
              i_exec    = lt_exec
              i_ttor    = lt_root
            IMPORTING
              e_com_yms =  lt_com_yms ).

          IF NOT lt_com_yms IS INITIAL.

*     Esta clase y la hice y su funcion es desasignar la FU
*            NEW zcl_assing_od_to_fo( )->unassign_from_tor(
*               EXPORTING
*                 it_item_key = lt_item_fo_key
*               IMPORTING
*                 e_message = DATA(e_message) ).

            LOOP AT lt_com_yms ASSIGNING FIELD-SYMBOL(<lfs_com_yms>).
              ls_output-send_freight_order-freight_order = CORRESPONDING #( <lfs_com_yms> ).
              ls_output-send_freight_order-freight_order-consignee_desc = <lfs_com_yms>-consignee_descr.
              ls_output-send_freight_order-freight_order-fo_number = CONV char20( |{ ls_output-send_freight_order-freight_order-fo_number ALPHA = IN }| ).
              ls_output-send_freight_order-freight_order-sales_order_item = CONV char6( |{ ls_output-send_freight_order-freight_order-sales_order_item ALPHA = IN }| ).
              ls_output-send_freight_order-freight_order-bussines_tr_doc_id = CONV char10( |{ ls_output-send_freight_order-freight_order-bussines_tr_doc_id ALPHA = IN }| ).

              "Envio a YMS SGT
              SET UPDATE TASK LOCAL.
              CALL FUNCTION '/TENR/FM_TM_CARRIER_PROXY' STARTING NEW TASK '/TENR/FM_TM_CARRIER_PROXY'
                EXPORTING
                  ls_output = ls_output.

            ENDLOOP.

            "Envio a SICRAM
            SET UPDATE TASK LOCAL.
            CALL FUNCTION '/TENR/FM_INT_SICRAM_OUT' STARTING NEW TASK '/TENR/FM_INT_SICRAM_OUT'
              EXPORTING
                i_tor_key  = lt_root_key
                i_upd_flag = status_d.

          ENDIF.
          REFRESH lt_com_yms.
          CLEAR lt_com_yms.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
    ENDLOOP.

  ENDMETHOD.

*    DATA: lt_tor_root_fu_bef     TYPE /scmtms/t_tor_root_k,
*          lt_tor_root_fu_bef_key TYPE /bobf/t_frw_key,
*          lt_tor_root_fo_bef     TYPE /scmtms/t_tor_root_k,
*          lt_tor_root_fo_bef_key TYPE /bobf/t_frw_key,
*          lt_mod                 TYPE /bobf/t_frw_modification,
*          ls_mod                 TYPE /bobf/s_frw_modification,
*          lt_trq_root            TYPE /scmtms/t_trq_root_k,
*          lo_change              TYPE REF TO /bobf/if_frw_change,
*          lo_message             TYPE REF TO /bobf/if_frw_message,
*          ra_trq_type            TYPE RANGE OF /scmtms/trq_type.
*
*    FIELD-SYMBOLS:      <fs_root> TYPE /scmtms/s_tor_root_k.
*
*    DATA(lo_srv_tor) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_tor_c=>sc_bo_key ).
*
*    io_read->retrieve(
*    EXPORTING
*      iv_node = /scmtms/if_tor_c=>sc_node-root
*      it_key = it_key
*      iv_fill_data = abap_true
*      iv_before_image = abap_true
*    IMPORTING
*      et_data = lt_tor_root_fo_bef ).
*
*    SELECT * FROM tvarvc
*      INTO TABLE @DATA(lt_tvarvc)
*      WHERE name = '/TENR/DELETION_FOS'.
*    IF sy-subrc EQ 0.
*      ra_trq_type = VALUE #( FOR <fs_trq_type> IN lt_tvarvc
*                          (
*                            sign = 'I'
*                            option = 'EQ'
*                            low = <fs_trq_type>-low
*                            high = ''
*                           ) ).
*
*    ENDIF.
*
*    CLEAR: lt_mod, ls_mod.
*
**       io_modify
*
*    LOOP AT lt_tor_root_fo_bef INTO DATA(ls_tor_root_fo_bef) WHERE tor_cat = 'TO' AND delete_ind = abap_true.
*
*      REFRESH lt_tor_root_fo_bef_key.
*      APPEND VALUE #( key = ls_tor_root_fo_bef-key ) TO lt_tor_root_fo_bef_key.
*
*      lo_srv_tor->retrieve_by_association(
*          EXPORTING
*            iv_node_key = /scmtms/if_tor_c=>sc_node-root
*            it_key = lt_tor_root_fo_bef_key
*            iv_association = /scmtms/if_tor_c=>sc_association-root-assigned_fus
*            iv_before_image = abap_true
*          IMPORTING
*            et_data       = lt_tor_root_fu_bef
*            et_target_key = lt_tor_root_fu_bef_key  ).
*
*      "buscamos el nodo TRQ ROOT para validar el tipo DTR u OTR
*      lo_srv_tor->retrieve_by_association(
*          EXPORTING
*            iv_node_key = /scmtms/if_tor_c=>sc_node-root
*            it_key = lt_tor_root_fu_bef_key
*            iv_association = /scmtms/if_tor_c=>sc_association-root-bo_trq_root_all
*            iv_fill_data = abap_true
*          IMPORTING
*            et_data = lt_trq_root  ).
*
*      IF lt_trq_root IS INITIAL.
*        "buscamos el nodo TRQ ROOT para validar el tipo DTR u OTR
*        lo_srv_tor->retrieve_by_association(
*            EXPORTING
*              iv_node_key = /scmtms/if_tor_c=>sc_node-root
*              it_key = lt_tor_root_fu_bef_key
*              iv_association = /scmtms/if_tor_c=>sc_association-root-bo_trq_root_all
*              iv_fill_data = abap_true
*              iv_before_image = abap_true
*            IMPORTING
*              et_data = lt_trq_root  ).
*
*      ENDIF.
*
*      LOOP AT lt_trq_root INTO DATA(ls_trq_root) WHERE trq_type IN ra_trq_type.
*
*        ls_mod-node = /scmtms/if_tor_c=>sc_node-root.
*        ls_mod-key = ls_tor_root_fo_bef-key.
*        ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_update.
*
*        CREATE DATA ls_mod-data TYPE /scmtms/s_tor_root_k.
*        ASSIGN ls_mod-data->* TO <fs_root>.
*
*        <fs_root>-delete_ind = abap_false.
*        APPEND /scmtms/if_tor_c=>sc_node_attribute-root-delete_ind TO ls_mod-changed_fields.
*
*        APPEND ls_mod TO lt_mod.
*        CLEAR ls_mod.
*      ENDLOOP.
*
*    ENDLOOP.
*
*    IF lt_mod IS NOT INITIAL.
*
*      SORT lt_mod BY key.
*      DELETE ADJACENT DUPLICATES FROM lt_mod COMPARING key.
*
*      io_modify->do_modify(
*      EXPORTING
*      it_modification = lt_mod ).
*
*      io_modify->end_modify(
*      EXPORTING
*        iv_process_immediately = abap_true
*      IMPORTING
*        eo_change = lo_change
*        eo_message = lo_message ).
*
*      IF lo_message IS BOUND.
*        lo_message->get_messages(
*          IMPORTING
*            et_message              = DATA(lt_message) ).
*
*        LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<lfs_message>).
*          DATA(e_message) = <lfs_message>-message->get_text( ).
*          EXIT.
*        ENDLOOP.
*      ENDIF.
*
*    ENDIF.

****    DATA : lt_root_fo_key TYPE /bobf/t_frw_key,
****           lt_root_fu_key TYPE /bobf/t_frw_key,
****           lt_root_fu     TYPE /scmtms/t_tor_root_k,
****           lt_root_fo     TYPE /scmtms/t_tor_root_k,
****           lt_item_fu     TYPE /scmtms/t_tor_item_tr_k,
****           lt_item_fo     TYPE /scmtms/t_tor_item_tr_k,
****           lt_root_trq    TYPE /scmtms/t_trq_root_k,
****           ls_message     TYPE string.
****
****    DATA(lo_srv_tor) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_tor_c=>sc_bo_key ).
****
*****    IMPORT var1 = lt_root_fo_key FROM MEMORY ID 'TENR_ASSING_FO'.
*****    IMPORT var2 = lt_root_fu FROM MEMORY ID 'TENR_ASSING_FU'.
*****     IMPORT var2 = lt_root_fu FROM MEMORY ID 'TENR_ASSING_FU'.
****
****    io_read->retrieve_by_association(
****    EXPORTING
****      iv_node = /scmtms/if_tor_c=>sc_node-root
****      it_key = it_key
****      iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr_fu_item
****      iv_fill_data = abap_true
****    IMPORTING
****      et_data = lt_item_fu ).
****    io_read->retrieve(
****    EXPORTING
****      iv_node = /scmtms/if_tor_c=>sc_node-root
****      it_key = it_key
****      iv_fill_data = abap_true
****    IMPORTING
****      et_data = lt_root_fu ).
****
*****    IF line_exists( lt_root_fo[ tor_cat = 'TO' ] ).
****    IF NOT line_exists( lt_root_fu[ tor_id = '$1' ] ).
****      IF line_exists( lt_root_fu[ tor_cat = 'FU' ] ).
****
*****      READ TABLE lt_root_fo INTO DATA(ls_root_fo) WITH KEY tor_cat = 'TO'.
****        LOOP AT lt_root_fu INTO DATA(ls_root_fu) WHERE tor_cat = 'FU'.
****          CLEAR lt_root_fu_key.
****          APPEND VALUE #( key = ls_root_fu-key ) TO lt_root_fu_key.
****
****          lo_srv_tor->retrieve_by_association(
****            EXPORTING
****              iv_node_key = /scmtms/if_tor_c=>sc_node-root
****              it_key = lt_root_fu_key
****              iv_association =  /scmtms/if_tor_c=>sc_association-root-bo_trq_root_all
****              iv_fill_data = abap_true
****            IMPORTING
****              eo_message = DATA(lo_message)
****              et_failed_key = DATA(lt_root_trq_key_f)
****              et_key_link = DATA(lt_root_trq_key_l)
****              et_data = lt_root_trq
****              et_target_key = DATA(lt_root_trq_key) ).
****
****          IF line_exists( lt_root_trq[ trq_type = 'YZ01' ] ) OR line_exists( lt_root_trq[ trq_type = 'YZ02' ] ).
****
****            IF ls_root_fu IS NOT INITIAL.
****
****              io_read->retrieve_by_association(
****                  EXPORTING
****                    iv_node = /scmtms/if_tor_c=>sc_node-root
****                    it_key = lt_root_fu_key
****                    iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr_fu_item
*****                iv_fill_data = abap_true
****                    iv_before_image = abap_true
****                  IMPORTING
*****                et_data = lt_item_fu_h
****                    et_target_key = DATA(lt_item_fu_key)  ).
****
****              io_read->retrieve_by_association(
****                 EXPORTING
****                   iv_node = /scmtms/if_tor_c=>sc_node-item_tr
****                   it_key = lt_item_fu_key
****                   iv_association = /scmtms/if_tor_c=>sc_association-item_tr-ref_item_tr
*****                   iv_fill_data = abap_true
****                   iv_before_image = abap_true
****                 IMPORTING
****                   et_target_key = DATA(lt_item_fo_key)
*****                   et_data = lt_item_fo
****                   ).
****
****
****              IF lt_item_fo_key IS NOT INITIAL.
****                CLEAR lt_root_fo_key.
*****                APPEND VALUE #( key = lt_item_fo[ 1 ]-root_key ) TO lt_root_fo_key.
****
*****                io_read->retrieve_by_association(
*****                   EXPORTING
*****                     iv_node = /scmtms/if_tor_c=>sc_node-item_tr
*****                     it_key = lt_item_fo_key
*****                     iv_association = /scmtms/if_tor_c=>sc_association-item_tr-to_root
******                   iv_fill_data = abap_true
******                   iv_before_image = abap_true
*****                   IMPORTING
*****                     et_target_key = lt_root_fo_key ).
*****
*****                IF lt_root_fo_key IS NOT INITIAL.
*****                  NEW zcl_assing_od_to_fo( )->unassign_from_tor(
*****                    EXPORTING
*****                      it_item_key = lt_item_fo_key
*****                    IMPORTING
*****                      e_message = ls_message ).
*****
*****                  wait up to 1 SECONDS.
*****                  NEW zcl_assing_od_to_fo( )->assign_fu_to_tor(
*****                   EXPORTING
*****                     i_tor_key = lt_root_fo_key
*****                     i_fu_id = lt_root_fu[ 1 ]-tor_id
*****                     i_fu_key = lt_root_fu[ 1 ]-key
*****                   IMPORTING
*****                     e_message = ls_message ).
*****                ENDIF.
****
****                SELECT * FROM /tenr/t_tmp_fus
****                  WHERE tor_fu_key = @ls_root_fu-key
****                    AND procesado IS INITIAL
****                  INTO TABLE @DATA(lt_tmp_fus) UP TO 1 ROWS.
****
****                IF lt_tmp_fus IS NOT INITIAL.
****                  CLEAR lt_root_fo_key.
****                  APPEND VALUE #( key = lt_tmp_fus[ 1 ]-tor_fo_key ) TO lt_root_fo_key.
****
****                  NEW zcl_assing_od_to_fo( )->assign_fu_to_tor(
****                   EXPORTING
****                     i_tor_key = lt_root_fo_key
****                     i_fu_id = lt_tmp_fus[ 1 ]-tor_fu_id
****                     i_fu_key = lt_tmp_fus[ 1 ]-tor_fu_key
****                   IMPORTING
****                     e_message = DATA(e_message) ).
*****          IF e_message IS INITIAL.
*****            DELETE FROM /tenr/t_tmp_fus WHERE tor_fo_key = ls_root_fo-key AND tor_fu_key = ls_root_fu-key.
*****          ENDIF.
****                ENDIF.
****              ENDIF.
****            ENDIF.
****          ENDIF.
****        ENDLOOP.
****      ENDIF.
****    ENDIF.
