FUNCTION /tenr/fm_wf_liberar_rates .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_EBELN) TYPE  EBELN
*"  EXPORTING
*"     REFERENCE(E_MESSAGE_ACT) TYPE  /TENR/S_ITEM_STATUS_DOC
*"     REFERENCE(E_MESSAGE_CHG) TYPE  /TENR/S_ITEM_STATUS_DOC
*"----------------------------------------------------------------------

  DATA: iv_target_status  TYPE /scmtms/status_code,
        lt_fag_id         TYPE /scmtms/t_fag_id,
        lt_fag_root_key   TYPE /bobf/t_frw_key,
        lt_tccs_item      TYPE /scmtms/t_tccs_item_k,
        ls_tccs_item      LIKE LINE OF lt_tccs_item,
        lt_tccs_item_key  TYPE /bobf/t_frw_key,
        lt_rates_root     TYPE /scmtms/t_tcrates_root_k,
        lt_validity_data  TYPE /scmtms/t_tcrate_vld_prd_k,
        ls_validity_data  LIKE LINE OF lt_validity_data,
        lr_validity_data  TYPE REF TO /scmtms/s_tcrate_vld_prd_k,
        lt_changed_fields TYPE /bobf/t_frw_name,
        lt_modify         TYPE /bobf/t_frw_modification,
        ls_modify         LIKE LINE OF lt_modify,
        lo_message_act    TYPE REF TO /bobf/if_frw_message,
        lo_message_chg    TYPE REF TO /bobf/if_frw_message,
        lo_message_sve    TYPE REF TO /bobf/if_frw_message.

  IF NOT i_ebeln IS INITIAL.

    iv_target_status = /scmtms/if_tc_rates_status=>sc_validity-lifecyclestatus-v_released.

    DATA(lo_srv_freightagreement) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_fag_c=>sc_bo_key ).
    DATA(lo_srv_tccs)             = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_tccs_c=>sc_bo_key ).
    DATA(lo_srv_rates)            = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_tcrates_c=>sc_bo_key ).
    DATA(lo_tra)                  = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

    APPEND VALUE #( fagrmntid044 = |{ CONV /scmtms/fag_id( i_ebeln ) ALPHA = IN }| ) TO lt_fag_id.

*   Convertir de llave externa a llave interna
    lo_srv_freightagreement->convert_altern_key(
         EXPORTING
           iv_node_key   = /scmtms/if_fag_c=>sc_node-root
           iv_altkey_key = /scmtms/if_fag_c=>sc_alternative_key-root-fagrmntid044
           it_key        = lt_fag_id
         IMPORTING
           et_key        = lt_fag_root_key ).

    IF NOT lt_fag_root_key IS INITIAL.

      CALL METHOD lo_srv_freightagreement->retrieve_by_association
        EXPORTING
          iv_node_key    = /scmtms/if_fag_c=>sc_node-root
          it_key         = lt_fag_root_key
          iv_association = /scmtms/if_fag_c=>sc_association-root-items
        IMPORTING
          et_target_key  = DATA(lt_fag_items_key).

      IF NOT lt_fag_items_key IS INITIAL.

        CALL METHOD lo_srv_freightagreement->retrieve_by_association
          EXPORTING
            iv_node_key    = /scmtms/if_fag_c=>sc_node-items
            it_key         = lt_fag_items_key
            iv_association = /scmtms/if_fag_c=>sc_association-items-tccs_bo
          IMPORTING
            et_target_key  = DATA(lt_fag_tccs_bo_key).

        IF NOT lt_fag_tccs_bo_key IS INITIAL.

          CALL METHOD lo_srv_tccs->retrieve_by_association
            EXPORTING
              iv_node_key    = /scmtms/if_tccs_c=>sc_node-root
              it_key         = lt_fag_tccs_bo_key
              iv_association = /scmtms/if_tccs_c=>sc_association-root-item
              iv_fill_data   = abap_true
            IMPORTING
              et_data        = lt_tccs_item.

          LOOP AT lt_tccs_item INTO ls_tccs_item WHERE tccalcresins040 EQ 'STND' AND rate_tab_type EQ '1000'.

            APPEND VALUE #( key = ls_tccs_item-key ) TO lt_tccs_item_key.

            CALL METHOD lo_srv_tccs->retrieve_by_association
              EXPORTING
                iv_node_key    = /scmtms/if_tccs_c=>sc_node-item
                it_key         = lt_tccs_item_key
                iv_association = /scmtms/if_tccs_c=>sc_association-item-rates_root
              IMPORTING
                et_target_key  = DATA(lt_rates_root_key).

            CLEAR: ls_tccs_item.
          ENDLOOP.

          IF lt_rates_root_key IS NOT INITIAL.

            CALL METHOD lo_srv_rates->retrieve
              EXPORTING
                iv_node_key = /scmtms/if_tcrates_c=>sc_node-root
                it_key      = lt_rates_root_key
              IMPORTING
                et_data     = lt_rates_root.

            CALL METHOD lo_srv_rates->retrieve_by_association
              EXPORTING
                iv_node_key    = /scmtms/if_tcrates_c=>sc_node-root
                it_key         = lt_rates_root_key
                iv_association = /scmtms/if_tcrates_c=>sc_association-root-validity
                iv_fill_data   = abap_true
              IMPORTING
                et_data        = lt_validity_data
                et_target_key  = DATA(lt_validity_key).
          ENDIF.

*          TRY.
*              CALL METHOD lo_srv_rates->do_action
*                EXPORTING
*                  iv_act_key    = /scmtms/if_tcrates_c=>sc_action-validity-release
*                  it_key        = lt_validity_key
*                  is_parameters = NEW /scmtms/t_rate_validity( ( release_with_rates = 'X' rate_keys = /scmtms/if_tcrates_c=>sc_node-root ) )
*                IMPORTING
*                  eo_change     = DATA(lo_change_act)
*                  eo_message    = lo_message_act.
**                  et_failed_key = DATA(lt_failed_key_act) ).
*            CATCH /bobf/cx_frw_contrct_violation.
*          ENDTRY.

          "Habilitar accion de cambio en Nodo VALIDITY
            CALL METHOD lo_srv_rates->do_action
                EXPORTING
                  iv_act_key    = /scmtms/if_tcrates_c=>sc_action-validity-release
                  it_key        = lt_validity_key
                IMPORTING
                  eo_change     = DATA(lo_change_act)
                  eo_message    = lo_message_act
                  et_failed_key = DATA(lt_failed_key_act).


          IF lo_message_act IS BOUND.
            lo_message_act->get_messages( IMPORTING et_message = DATA(lt_message_act) ).

            LOOP AT lt_message_act ASSIGNING FIELD-SYMBOL(<fs_message_act>).
              APPEND VALUE #( message = |{ <fs_message_act>-severity } { <fs_message_act>-message->get_text( ) }| ) TO e_message_act-item.
            ENDLOOP.
          ENDIF.


          APPEND /scmtms/if_tc_rates_status=>sc_validity-lifecyclestatus-field TO lt_changed_fields.

          LOOP AT lt_validity_data INTO ls_validity_data.

            CREATE DATA lr_validity_data.
            MOVE-CORRESPONDING ls_validity_data TO lr_validity_data->*.

            lr_validity_data->lifecyclestatus = iv_target_status.

            ls_modify-key = ls_validity_data-key.
            ls_modify-node = /scmtms/if_tcrates_c=>sc_node-validity. "Llave base nodo validity 80E0ED0A0C2F1DDBA5CE9ED3417F0267
            ls_modify-data = lr_validity_data.
            ls_modify-changed_fields = lt_changed_fields.
            ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_update.
            APPEND ls_modify TO lt_modify.
            CLEAR: ls_validity_data.
          ENDLOOP.


          lo_srv_rates->modify( EXPORTING
                                  it_modification = lt_modify
                                IMPORTING
                                  eo_change  = DATA(lo_chg)
                                  eo_message = lo_message_chg ).


          IF lo_message_chg IS BOUND.
            lo_message_chg->get_messages(
                IMPORTING
                  et_message = DATA(lt_message_chg) ).

            LOOP AT lt_message_chg ASSIGNING FIELD-SYMBOL(<fs_message_chg>).
              APPEND VALUE #( message = |{ <fs_message_chg>-severity } { <fs_message_chg>-message->get_text( ) }| ) TO e_message_chg-item.
            ENDLOOP.

          ENDIF.

          lo_tra->save( IMPORTING
                         ev_rejected = DATA(lv_rejected)
                         eo_change   = lo_chg
                         eo_message  = lo_message_sve ).


        ENDIF.

      ENDIF.

    ENDIF.

    REFRESH: lt_fag_items_key,
             lt_fag_tccs_bo_key,
             lt_tccs_item,
             lt_tccs_item_key,
             lt_rates_root_key,
             lt_rates_root,
             lt_validity_data,
             lt_validity_key,
             lt_failed_key_act,
             lt_changed_fields,
             lt_message_act,
             lt_message_chg.

    UNASSIGN: <fs_message_act>,
              <fs_message_chg>.

  ENDIF.


ENDFUNCTION.
