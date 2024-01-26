METHOD /bobf/if_frw_action~execute.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""$"$\SE:(1) Clase /SCMTMS/CL_TOR_A_ROOT_CANCEL, Interface /BOBF/IF_FRW_ACTION, Método EXECUTE, Inicio                                                         A
*$*$-Start: (1)---------------------------------------------------------------------------------$*$*
ENHANCEMENT 1  /TENR/EH_TOR_ROOT_CANCEL.    "active version
    DATA: lt_tor_root   TYPE /scmtms/t_tor_root_k,
          lt_trq_root   TYPE /scmtms/t_trq_root_k,
          ra_trq_type_p TYPE RANGE OF /scmtms/trq_type,
          lo_fpm        TYPE REF TO if_fpm,
          lo_fpm_ref    TYPE REF TO cl_fpm,
          lv_del_fo     TYPE char1.

    DATA: lt_exec     TYPE /scmtms/t_tor_exec_k,
          lt_root_key TYPE /bobf/t_frw_key,
          lo_proxy    TYPE REF TO /tenr/co_ws_oa_send_freight_or,
          ls_output   TYPE /tenr/ws_send_freight_order1,
          status_d    TYPE char1,
          lt_com_yms  TYPE /tenr/t_tmcomunyms_in.
*          lv_tabix    TYPE sy-tabix.

    FIELD-SYMBOLS: <fs_key_tor>  TYPE /bobf/t_frw_key,
                   <lfs_com_yms> TYPE /tenr/s_tmcomunyms_in.

    ASSIGN it_key TO <fs_key_tor>.

    lo_fpm = cl_fpm_factory=>get_instance( ).
    IF lo_fpm IS BOUND.
      lo_fpm_ref ?= lo_fpm.
      IF lo_fpm_ref->mo_current_event IS BOUND.
        DATA(ucomm) = lo_fpm_ref->mo_current_event->mv_event_id.
      ENDIF.
    ENDIF.

    DATA(lo_srvmgr_tor) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_tor_c=>sc_bo_key ).
    lo_srvmgr_tor->retrieve(
      EXPORTING
        iv_node_key             = /scmtms/if_tor_c=>sc_node-root
        it_key                  = <fs_key_tor>
        iv_fill_data            = abap_true
        iv_before_image         = abap_true
      IMPORTING
        et_data                 = lt_tor_root ).

    IF ucomm EQ 'TM_CANCEL_DOCUMENT' OR  ucomm EQ 'FPM_CLOSE_DIALOG' OR ucomm EQ 'AID_TOR_LIST_DELETE'.

      IF ucomm EQ 'FPM_CLOSE_DIALOG' OR ucomm EQ 'AID_TOR_LIST_DELETE'.

        LOOP AT it_key INTO DATA(ls_capa_key).
*          clear lv_tabix.
*          lv_tabix = sy-tabix.

          REFRESH: lt_root_key.
          lt_root_key = VALUE #( ( key = ls_capa_key-key ) ).

          CALL METHOD io_read->retrieve_by_association
            EXPORTING
              iv_node        = /scmtms/if_tor_c=>sc_node-root
              it_key         = lt_root_key
              iv_fill_data   = abap_true
              iv_association = /scmtms/if_tor_c=>sc_association-root-exec
            IMPORTING
              et_data        = lt_exec.

          status_d   = 'D'.
          EXPORT status_d = status_d TO MEMORY ID 'STATUS_D'.

          NEW zcl_tm_val_com_yms( )->send_data_yms(
            EXPORTING
              i_key     = lt_tor_root[ key = ls_capa_key-key ]-root_key
              i_torid   = lt_tor_root[ key = ls_capa_key-key ]-tor_id
              i_status  = status_d
              i_exec    = lt_exec
              i_ttor    = lt_tor_root
            IMPORTING
              e_com_yms = lt_com_yms ).

          IF NOT lt_com_yms IS INITIAL.
*       APPEND VALUE #( key = ls_capa_key-key ) TO lt_root_fo_key.
            CALL FUNCTION '/TENR/FM_INT_SICRAM_OUT'
              EXPORTING
                i_tor_key  = lt_root_key
                i_upd_flag = status_d.
          ENDIF.

          LOOP AT lt_com_yms ASSIGNING <lfs_com_yms>.
            ls_output-send_freight_order-freight_order = CORRESPONDING #( <lfs_com_yms> ).
            ls_output-send_freight_order-freight_order-consignee_desc = <lfs_com_yms>-consignee_descr.

** FO_NUMBER a 20 posiciones con ceros a la izquierda
            ls_output-send_freight_order-freight_order-fo_number = CONV char20( |{ ls_output-send_freight_order-freight_order-fo_number ALPHA = IN }| ).
** SALES_ORDER_ITEM a 6 posisiones con ceros a la izquierda
            ls_output-send_freight_order-freight_order-sales_order_item = CONV char6( |{ ls_output-send_freight_order-freight_order-sales_order_item ALPHA = IN }| ).
** BUSSINES_TR_DOC_ID a 10 posiciones con ceos a la iquierda
            ls_output-send_freight_order-freight_order-bussines_tr_doc_id = CONV char10( |{ ls_output-send_freight_order-freight_order-bussines_tr_doc_id ALPHA = IN }| ).

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
                CATCH cx_ai_system_fault INTO DATA(g_system_fault).
*                  DATA(r_error) = abap_true.
              ENDTRY.
            ENDIF.

          ENDLOOP.

          REFRESH lt_com_yms.
          CLEAR lt_com_yms.

        ENDLOOP.

      ENDIF.

    ELSE.

*      lo_srvmgr_tor->retrieve_by_association(
*              EXPORTING
*                iv_node_key = /scmtms/if_tor_c=>sc_node-root
*                it_key = <fs_key_tor>
*                iv_association = /scmtms/if_tor_c=>sc_association-root-bo_trq_root_all
*                iv_fill_data = abap_true
*                iv_before_image     = abap_true
*              IMPORTING
*                et_data = lt_trq_root ).
*
*      IF lt_trq_root IS INITIAL.
*        lo_srvmgr_tor->retrieve_by_association(
*          EXPORTING
*            iv_node_key = /scmtms/if_tor_c=>sc_node-root
*            it_key = <fs_key_tor>
*            iv_association = /scmtms/if_tor_c=>sc_association-root-bo_trq_root_all
*            iv_fill_data = abap_true
*          IMPORTING
*            et_data = lt_trq_root ).
*      ENDIF.

*    SELECT * FROM tvarvc
*     INTO TABLE @DATA(lt_tvarvc_p)
*     WHERE name = '/TENR/ASSING_OD_TO_FO_PADRES'.
*    CLEAR ra_trq_type_p.
*
*    IF sy-subrc EQ 0.
*      ra_trq_type_p = VALUE #( FOR <fs_trq_type_p> IN lt_tvarvc_p
*                          (
*                            sign = 'I'
*                            option = 'EQ'
*                            low = <fs_trq_type_p>-low
*                            high = ''
*                           ) ).
*
*    ENDIF.

*    IF line_exists( lt_tor_root[ tor_cat = 'TO' ] ).
*      IF line_exists( lt_tor_root[ confirmation = '10' ] ) OR line_exists( lt_tor_root[ confirmation = '04' ] ) OR line_exists( lt_tor_root[ confirmation = '05' ] ).
*        EXIT.
*      ENDIF.
*    ENDIF.
      IMPORT var1 = lv_del_fo FROM MEMORY ID 'TENR_FO_DELE'.
      IF line_exists( lt_tor_root[ tor_cat = 'TO' ] ).
        IF lv_del_fo EQ abap_false.
          EXIT.
        ELSE.

          FREE MEMORY ID 'TENR_FO_DELE'.

          LOOP AT it_key INTO DATA(ls_capa_key2).

            REFRESH: lt_root_key.
            lt_root_key = VALUE #( ( key = ls_capa_key2-key ) ).

            CALL METHOD io_read->retrieve_by_association
              EXPORTING
                iv_node        = /scmtms/if_tor_c=>sc_node-root
                it_key         = lt_root_key
                iv_fill_data   = abap_true
                iv_association = /scmtms/if_tor_c=>sc_association-root-exec
              IMPORTING
                et_data        = lt_exec.

            status_d   = 'D'.
            EXPORT status_d = status_d TO MEMORY ID 'STATUS_D'.

            NEW zcl_tm_val_com_yms( )->send_data_yms(
              EXPORTING
                i_key     = lt_tor_root[ key = ls_capa_key2-key ]-root_key
                i_torid   = lt_tor_root[ key = ls_capa_key2-key ]-tor_id
                i_status  = status_d
                i_exec    = lt_exec
                i_ttor    = lt_tor_root
              IMPORTING
                e_com_yms = lt_com_yms ).

            IF NOT lt_com_yms IS INITIAL.
*       APPEND VALUE #( key = ls_capa_key-key ) TO lt_root_fo_key.
              CALL FUNCTION '/TENR/FM_INT_SICRAM_OUT'
                EXPORTING
                  i_tor_key  = lt_root_key
                  i_upd_flag = status_d.
            ENDIF.

            LOOP AT lt_com_yms ASSIGNING <lfs_com_yms>.
              ls_output-send_freight_order-freight_order = CORRESPONDING #( <lfs_com_yms> ).
              ls_output-send_freight_order-freight_order-consignee_desc = <lfs_com_yms>-consignee_descr.

** FO_NUMBER a 20 posiciones con ceros a la izquierda
              ls_output-send_freight_order-freight_order-fo_number = CONV char20( |{ ls_output-send_freight_order-freight_order-fo_number ALPHA = IN }| ).
** SALES_ORDER_ITEM a 6 posisiones con ceros a la izquierda
              ls_output-send_freight_order-freight_order-sales_order_item = CONV char6( |{ ls_output-send_freight_order-freight_order-sales_order_item ALPHA = IN }| ).
** BUSSINES_TR_DOC_ID a 10 posiciones con ceos a la iquierda
              ls_output-send_freight_order-freight_order-bussines_tr_doc_id = CONV char10( |{ ls_output-send_freight_order-freight_order-bussines_tr_doc_id ALPHA = IN }| ).

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
                  CATCH cx_ai_system_fault INTO DATA(g_system_fault_2).
*                    DATA(r_error_2) = abap_true.
                ENDTRY.
              ENDIF.

            ENDLOOP.

            REFRESH lt_com_yms.
            CLEAR lt_com_yms.

          ENDLOOP.

        ENDIF.
      ENDIF.


***      "valida el estatus de la FO
***      IF line_exists( lt_tor_root[ tor_type = 'ZF04' ] ). "OR line_exists( lt_tor_root[ tor_type = 'ZFRD' ] ).
***        EXIT.
***      ENDIF.
    ENDIF.
ENDENHANCEMENT.
*$*$-End:   (1)---------------------------------------------------------------------------------$*$*

  DATA:
    lv_output_option         TYPE /scmtms/tend_output_option,
    lv_deletion_allowed      TYPE abap_bool,
    ls_key                   TYPE /bobf/s_frw_key,
    lt_key                   TYPE /bobf/t_frw_key,
    lt_k_wh_door_stat_reset  TYPE /bobf/t_frw_key,
    lt_canc_key              TYPE /bobf/t_frw_key,
    lt_canc_key_filtered     TYPE /bobf/t_frw_key,
    lt_upd_trq               TYPE /bobf/t_frw_key,
    lt_key_lc_update         TYPE /bobf/t_frw_key,
    lt_key_lc_cancel         TYPE /bobf/t_frw_key,
    lt_key_delete            TYPE /bobf/t_frw_key,
    lt_key_delete2           TYPE /bobf/t_frw_key,
    lt_key_initial_fus       TYPE /bobf/t_frw_key,
    lt_k_mawb_return         TYPE /bobf/t_frw_key,
    lv_lc_status             TYPE /scmtms/tor_lc_status,
    lo_message               TYPE REF TO /bobf/if_frw_message,
    lv_act_key               TYPE /bobf/act_key,
    lt_lifecycle_key         TYPE /bobf/t_frw_key,
    ls_symsg                 TYPE symsg,
    lv_mtext                 TYPE string,
    lr_root                  TYPE REF TO /scmtms/s_tor_root_k,
    lt_mod                   TYPE /bobf/t_frw_modification,
    ls_mod                   TYPE /bobf/s_frw_modification,
    lt_root_data             TYPE /scmtms/t_tor_root_k,
    ls_root_data             TYPE /scmtms/s_tor_root_k,
    lt_tor_identifier        TYPE /scmtms/t_key_identifier,
    ls_tor_identifier        TYPE /scmtms/s_key_identifier,
    lv_dummy                 TYPE string,
    lo_change                TYPE REF TO /bobf/if_frw_change,
    lt_stop_tender_key       TYPE /bobf/t_frw_key,
    lt_cancel_customs        TYPE /bobf/t_frw_key,
    lt_failed_key            TYPE /bobf/t_frw_key,
    lt_confhist_key          TYPE /bobf/t_frw_key,
    lt_confhist_data         TYPE /scmtms/t_tor_root_k,
    lt_root_confhist_link    TYPE /bobf/t_frw_key_link,
    lt_trq_root_key          TYPE /bobf/t_frw_key,
    lt_kl_tor_trq            TYPE /bobf/t_frw_key_link,
    lr_act_param             TYPE REF TO /scmtms/s_ays_popup_param,
    lr_act_param_mawb_return TYPE REF TO /scmtms/s_tor_a_root_mawb_ret,
    lr_set_wh_door_status    TYPE REF TO /scmtms/s_tor_a_set_door_stat,
    lr_confhist_parm         TYPE REF TO /scmtms/s_tor_a_crt_subhist,
    lo_srvmgr                TYPE REF TO /bobf/if_tra_service_manager,
    lv_detlvl                TYPE ballevel,
    lv_probclass             TYPE balprobcl,
    ls_tor_tsp               TYPE /scmtms/s_tor_tsp,
    lr_tal_bs_param          TYPE REF TO /scmtms/s_tor_a_talbs_reload,
    lt_k_revoke_triang       TYPE /bobf/t_frw_key,
    lt_k_rebuild_prov        TYPE /bobf/t_frw_key,
    lt_item_tr               TYPE /scmtms/t_tor_item_tr_k,
    lt_ref_capa_itm          TYPE /scmtms/t_tor_item_tr_k,
    lt_itm_key               TYPE /bobf/t_frw_key,
    lt_d_stop                TYPE /scmtms/t_tor_stop_k,
    lr_param_folup           TYPE REF TO /scmtms/s_tor_a_root_followup,
    lv_cancel_confirmed      TYPE abap_bool,
    lt_d_event               TYPE /scmtms/t_tor_exec_k,
    lo_message_req           TYPE REF TO /bobf/if_frw_message,
    lt_kl_cap_req            TYPE /bobf/t_frw_key_link,
    ls_kl_cap_req            TYPE /bobf/s_frw_key_link,
    lt_k_req_tor             TYPE /bobf/t_frw_key,
    lt_k_req_stop            TYPE /bobf/t_frw_key,
    lt_d_req_stop            TYPE /scmtms/t_tor_stop_k,
    lt_locked_req_st_k       TYPE /bobf/t_frw_key,
    ls_locked_req_st_k       TYPE /bobf/s_frw_key,
    ls_d_req_stop            TYPE /scmtms/s_tor_stop_k,
    lt_d_req_tor             TYPE /scmtms/t_tor_root_k,
    lv_skip_upd_conn_cache   TYPE abap_bool.

  FIELD-SYMBOLS:
    <ls_param_lc_cancel> TYPE /scmtms/s_tor_a_root_cancel,
    <ls_failed_key>      TYPE /bobf/s_frw_key,
    <ls_ref_capa_itm>    TYPE /scmtms/s_tor_item_tr_k,
    <ls_stop>            TYPE /scmtms/s_tor_stop_k.

* clear export parameters
  CLEAR:
    eo_message,
    et_failed_key.

**********************************************************************
* Cancelation and deletion is not allowed if the stops are locked
**********************************************************************

  lt_canc_key = it_key.
  lo_srvmgr = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_tor_c=>sc_bo_key ).
  lo_srvmgr->retrieve_by_association(
    EXPORTING
      iv_node_key             = /scmtms/if_tor_c=>sc_node-root
      it_key                  = it_key
      iv_association          = /scmtms/if_tor_c=>sc_association-root-stop
      iv_edit_mode            = /bobf/if_conf_c=>sc_edit_exclusive
      iv_fill_data            = abap_true
    IMPORTING
      eo_message              = lo_message
      et_target_key           = lt_key
      et_data                 = lt_d_stop   ).

* get events for EWM outbound stops sent to the warehouse
  LOOP AT lt_d_stop ASSIGNING <ls_stop>
    WHERE wh_transm_status IS NOT INITIAL AND
          wh_transm_status <> /scmtms/if_tor_status_c=>sc_stop-wh_transm_status-v_cancel_confirmed AND
          handling_exec = /scmtms/if_tor_status_c=>sc_stop-handling_exec-v_not_loaded.
    ls_key-key = <ls_stop>-key.
    APPEND ls_key TO lt_key.
  ENDLOOP.
  IF lt_key IS NOT INITIAL.
    lo_srvmgr->retrieve_by_association(
      EXPORTING
        iv_node_key             = /scmtms/if_tor_c=>sc_node-stop
        it_key                  = lt_key
        iv_association          = /scmtms/if_tor_c=>sc_association-stop-executioninformation
        iv_fill_data            = abap_true
     IMPORTING
        et_data                 = lt_d_event  ).
  ENDIF.

  /scmtms/cl_common_helper=>analyze_messages(
    EXPORTING
      it_lock_key   = it_key
      io_message    = lo_message
    IMPORTING
      et_locked_key = lt_key  ).

  IF lo_message IS BOUND.
    /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
    FREE lo_message.
  ENDIF.
  IF NOT lt_key IS INITIAL.

* there are locked stops
    io_read->get_root_key(
      EXPORTING
        iv_node         = /scmtms/if_tor_c=>sc_node-stop
        it_key          = lt_key
     IMPORTING
        et_target_key   = et_failed_key  ).
    LOOP AT et_failed_key INTO ls_key.
      DELETE lt_canc_key WHERE key = ls_key-key.
    ENDLOOP.
  ENDIF.

  lo_srvmgr->retrieve_by_association(
  EXPORTING
    iv_node_key             = /scmtms/if_tor_c=>sc_node-root
    it_key                  = it_key
    iv_association          = /scmtms/if_tor_c=>sc_association-root-req_tor
    iv_fill_data            = abap_true
  IMPORTING
    et_key_link             = lt_kl_cap_req
    et_target_key           = lt_k_req_tor
    et_data                 = lt_d_req_tor ).

  IF lt_k_req_tor IS NOT INITIAL.

    lo_srvmgr->retrieve_by_association(
      EXPORTING
        iv_node_key             = /scmtms/if_tor_c=>sc_node-root
        it_key                  = lt_k_req_tor
        iv_association          = /scmtms/if_tor_c=>sc_association-root-stop
        iv_edit_mode            = /bobf/if_conf_c=>sc_edit_exclusive
        iv_fill_data            = abap_true
      IMPORTING
        eo_message              = lo_message_req
        et_target_key           = lt_k_req_stop
        et_data                 = lt_d_req_stop  ).

    /scmtms/cl_common_helper=>analyze_messages(
     EXPORTING
       it_lock_key   = lt_k_req_stop
       io_message    = lo_message_req
     IMPORTING
       et_locked_key = lt_locked_req_st_k  ).

    LOOP AT lt_locked_req_st_k INTO ls_locked_req_st_k.
      READ TABLE lt_d_req_stop INTO ls_d_req_stop WITH KEY key = ls_locked_req_st_k-key.
      IF sy-subrc = 0.
        READ TABLE lt_kl_cap_req INTO ls_kl_cap_req WITH TABLE KEY target_key COMPONENTS target_key = ls_d_req_stop-root_key.
        IF sy-subrc = 0.
          DELETE lt_canc_key WHERE key = ls_kl_cap_req-source_key.
          CALL METHOD /scmtms/cl_common_helper=>insert_key
            EXPORTING
              iv_key = ls_kl_cap_req-source_key
            CHANGING
              ct_key = et_failed_key.
        ENDIF.
      ENDIF.
    ENDLOOP.

    "Check for extracted PU
    DATA(lv_pu_num) = 0.
    LOOP AT lt_d_req_tor TRANSPORTING NO FIELDS WHERE creation_type = /scmtms/if_tor_const=>sc_creation_type-req_crtd_from_capa.
      lv_pu_num = lv_pu_num + 1.
    ENDLOOP.
    IF /scmtms/cl_om_upd_request=>sv_business_context NE /scmtms/if_common_c=>c_business_context-cancel_req_merge_with_capa.
      "In case of 'Cancel&Merge' the completeness check was done before and does not need to be executed again
      chk_multiassgn_complete(
        EXPORTING
          io_read           = io_read
          is_parameters     = is_parameters
        IMPORTING
          et_k_missing_root = DATA(lt_k_missing_root)
          eo_message        = eo_message
        CHANGING
          ct_k_cancel_root  = lt_canc_key
      ).
      IF lt_k_missing_root IS NOT INITIAL.
        DATA(lv_count_missing_root) = lines( lt_k_missing_root ).
      ENDIF.
    ENDIF.

  ENDIF.
* check if anything left to do
  IF lt_canc_key IS INITIAL.
    /scmtms/cl_d_superclass=>clear_delkeys( it_key ).
    /scmtms/cl_d_superclass=>clear_cancelkeys( ).
    RETURN.
  ENDIF.

**********************************************************************
* turn off validation for the follow up actions. If the cancelation as such is allowed, the follow up checks
* must not partially prevent the e.g. unassignment

  /scmtms/cl_tor_validations=>turn_off_vals( ).
  /scmtms/cl_tor_fc=>gv_disable_properties = abap_true.

**********************************************************************
  " AYS-popup sould be triggered at the beginning...we do not need any data...
  IF is_ctx-act_key = /scmtms/if_tor_c=>sc_action-root-cancel OR
     is_ctx-act_key = /scmtms/if_tor_c=>sc_action-root-hard_delete.

    " only if the parameter is passed to the action
    IF is_parameters IS NOT INITIAL AND is_parameters IS BOUND.
      ASSIGN is_parameters->* TO <ls_param_lc_cancel>.
      " issue AYS only if the no_check-flag is not set!
      IF <ls_param_lc_cancel>-no_check = abap_false.
        IF lv_pu_num > 0.
          " raise additional message on AYS popup if extracted PUs exist
          MESSAGE w036(/scmtms/ays_popup) WITH lv_pu_num INTO lv_dummy.
          READ TABLE it_key INTO ls_key INDEX 1.
          CALL METHOD /scmtms/cl_common_helper=>msg_helper_add_symsg(
            EXPORTING
              iv_node_key = /scmtms/if_tor_c=>sc_node-root
              iv_key      = ls_key-key
            CHANGING
              co_message  = lo_message ).
          IF lo_message IS BOUND.
            /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
            FREE lo_message.
          ENDIF.
        ENDIF.
        IF lv_count_missing_root > 0.
          " raise additional message on AYS popup if extracted PUs exist
          MESSAGE w037(/scmtms/ays_popup) WITH lv_count_missing_root INTO lv_dummy.
          READ TABLE it_key INTO ls_key INDEX 1.
          CALL METHOD /scmtms/cl_common_helper=>msg_helper_add_symsg(
            EXPORTING
              iv_node_key = /scmtms/if_tor_c=>sc_node-root
              iv_key      = ls_key-key
            CHANGING
              co_message  = lo_message ).
          IF lo_message IS BOUND.
            /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
            FREE lo_message.
          ENDIF.
        ENDIF.
        " issue the AYS popup
        MESSAGE w007(/scmtms/ays_popup) INTO lv_dummy.
        READ TABLE it_key INTO ls_key INDEX 1.
        CALL METHOD /scmtms/cl_common_helper=>msg_helper_add_symsg(
          EXPORTING
            iv_node_key = /scmtms/if_tor_c=>sc_node-root
            iv_key      = ls_key-key
          CHANGING
            co_message  = lo_message ).
        IF lo_message IS BOUND.
          /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
          FREE lo_message.
        ENDIF.
        et_failed_key = it_key.
        " turn on validations
        /scmtms/cl_tor_validations=>turn_on_vals( ).
        /scmtms/cl_tor_fc=>gv_disable_properties = abap_false.
        /scmtms/cl_d_superclass=>clear_delkeys( it_key ).
        /scmtms/cl_d_superclass=>clear_cancelkeys( ).
        RETURN.
      ENDIF.
    ENDIF.
  ENDIF.



*--------------------------------------------------------------------*
* Get settings from tor type
*--------------------------------------------------------------------*
  CALL METHOD io_read->retrieve
    EXPORTING
      iv_node = is_ctx-root_node_key
      it_key  = lt_canc_key
    IMPORTING
      et_data = lt_root_data.

  IF is_ctx-act_key <> /scmtms/if_tor_c=>sc_action-root-hard_delete.
    "Filter the tor keys for which invoice already exists
    CALL METHOD /scmtms/cl_tor_helper_root=>filter_tor_with_invoice
      EXPORTING
        io_read       = io_read
      CHANGING
        ct_root_data  = lt_root_data
        ct_failed_key = et_failed_key
        co_message    = lo_message
        ct_root_key   = lt_canc_key.

    IF lo_message IS BOUND.
      /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
      FREE lo_message.
    ENDIF.

    IF lt_canc_key IS INITIAL .
      " turn on validations
      /scmtms/cl_tor_validations=>turn_on_vals( ).
      /scmtms/cl_tor_fc=>gv_disable_properties = abap_false.
      /scmtms/cl_d_superclass=>clear_delkeys( it_key ).
      /scmtms/cl_d_superclass=>clear_cancelkeys( ).
      RETURN.
    ENDIF.
  ENDIF.

  " filter the inital FUs and add those keys to the "to-be-deleted"-keys
  CALL METHOD /scmtms/cl_tor_helper_common=>filter_keys
    EXPORTING
      io_read                  = io_read
      it_key                   = lt_canc_key
      iv_filter_tor_fu_initial = abap_true
    IMPORTING
      et_key_filtered          = lt_canc_key_filtered
      et_key_filtered_out      = lt_key_initial_fus.

  lt_canc_key = lt_canc_key_filtered.
  CLEAR lt_canc_key_filtered.

  IF <ls_param_lc_cancel> IS ASSIGNED AND <ls_param_lc_cancel>-cancel_confirmed IS NOT INITIAL.
    lv_cancel_confirmed = <ls_param_lc_cancel>-cancel_confirmed.
  ENDIF.

*--------------------------------------------------------------------*
* Check which action has called the status update
*--------------------------------------------------------------------*

  " get the description of the TOR
  CALL METHOD /scmtms/cl_tor_helper_root=>return_ident_fortor_key_mass(
    EXPORTING
      it_tor_key         = lt_canc_key
    IMPORTING
      et_tor_description = lt_tor_identifier
  ).

  CALL METHOD filter_triang_tu
    EXPORTING
      io_read            = io_read
      it_d_root          = lt_root_data
    IMPORTING
      et_k_revoke_triang = lt_k_revoke_triang
    CHANGING
      ct_k_cancel        = lt_canc_key.

  CASE is_ctx-act_key.
      " Lifecycle
    WHEN /scmtms/if_tor_c=>sc_action-root-cancel OR
         /scmtms/if_tor_c=>sc_action-root-hard_delete.

      lv_lc_status = /scmtms/if_tor_status_c=>sc_root-lifecycle-v_canceled.

* The to be canceled TORs must be unfixed first to allow freight unit removal etc.
      CALL METHOD io_modify->do_action
        EXPORTING
          iv_act_key    = /scmtms/if_tor_c=>sc_action-root-unfix_tor
          it_key        = lt_canc_key
        IMPORTING
          eo_change     = lo_change
          eo_message    = lo_message
          et_failed_key = et_failed_key.
      IF lo_message IS BOUND.
        /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
        FREE lo_message.
      ENDIF.

* The to be canceled TORs must reset the exec status, e.g. to enable removing the Freight Units
      CALL METHOD io_modify->do_action
        EXPORTING
          iv_act_key    = /scmtms/if_tor_c=>sc_action-root-set_exm_status_not_started
          it_key        = lt_canc_key
        IMPORTING
          eo_change     = lo_change
          eo_message    = lo_message
          et_failed_key = et_failed_key.
      IF lo_message IS BOUND.
        /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
        FREE lo_message.
      ENDIF.
      IF et_failed_key IS NOT INITIAL.
        LOOP AT et_failed_key ASSIGNING FIELD-SYMBOL(<fs_key>).
          DELETE TABLE lt_canc_key WITH TABLE KEY key = <fs_key>-key.
        ENDLOOP.
      ENDIF.

      IF is_ctx-act_key <> /scmtms/if_tor_c=>sc_action-root-hard_delete AND
          lt_canc_key IS NOT INITIAL AND
          /scmtms/cl_fu_builder_helper=>is_in_fub_posting( ) EQ abap_false.
        DATA(lt_d_root_cancel) = FILTER #( lt_root_data IN lt_canc_key USING KEY key_sort WHERE key = key ).
        check_ewm_execution(
          EXPORTING
            io_read              = io_read
            it_d_stop            = lt_d_stop
            it_d_root            = lt_d_root_cancel
            iv_cancel_confirmed  = lv_cancel_confirmed
            it_event             = lt_d_event
          IMPORTING
            et_k_cancel_ewm_for  = DATA(lt_k_cancel_ewm_for)
            et_d_stop_cancel_ewm = DATA(lt_d_stop_cancel_ewm)
            et_k_failed          = lt_failed_key
          CHANGING
            ct_k_root_cancel     = lt_canc_key
            co_message           = lo_message ).
        IF lt_failed_key IS NOT INITIAL.
          INSERT LINES OF lt_failed_key INTO TABLE et_failed_key.
        ENDIF.
        IF lo_message IS BOUND.
          /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
          FREE lo_message.
        ENDIF.
      ENDIF.

* START Remove this TOR from requirement and capacity TORs

      " end_modify shall execute -> UPDATE_FROM_RELATED_TORS -> UPDATE_ITEM_TR (This is not desired for canceled documents!)
      " -> it needs to know the cancel keys received via cl_d_superclass->GET_DEL_AND_CANCELKEYS
      /scmtms/cl_d_superclass=>register_cancelkeys( it_key = lt_canc_key ).

      CALL METHOD io_modify->do_action
        EXPORTING
          iv_act_key    = /scmtms/if_tor_c=>sc_action-root-remove_tor_assignments
          it_key        = lt_canc_key
        IMPORTING
          eo_change     = lo_change
          eo_message    = lo_message
          et_failed_key = et_failed_key.
      IF lo_message IS BOUND.
        /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
        FREE lo_message.
      ENDIF.
      IF et_failed_key IS NOT INITIAL.
        LOOP AT et_failed_key ASSIGNING FIELD-SYMBOL(<fs_failed_key>).
          DELETE TABLE lt_canc_key WITH TABLE KEY key = <fs_failed_key>-key.
        ENDLOOP.
      ENDIF.

      " ensure that the changes are merged immediately to avoid issues in deletion strategy
      io_modify->end_modify( iv_process_immediately = abap_true ).

      /scmtms/cl_d_superclass=>clear_cancelkeys( ).

* END Remove this TOR from requirement and capacity TORs

      IF lt_canc_key IS INITIAL AND lt_key_initial_fus IS INITIAL AND lt_k_cancel_ewm_for IS INITIAL.
        " turn on validations
        /scmtms/cl_tor_validations=>turn_on_vals( ).
        /scmtms/cl_tor_fc=>gv_disable_properties = abap_false.
        /scmtms/cl_d_superclass=>clear_delkeys( it_key ).
        /scmtms/cl_d_superclass=>clear_cancelkeys( ).
        RETURN.
      ELSEIF lt_canc_key IS INITIAL AND lt_key_initial_fus IS INITIAL AND lt_k_cancel_ewm_for IS NOT INITIAL.
        DATA(lv_cancel_ewm_only) = abap_true.
      ENDIF.
      IF lv_cancel_ewm_only <> abap_true.

* Get confirmation history node data
        CALL METHOD io_read->retrieve_by_association
          EXPORTING
            iv_node        = /scmtms/if_tor_c=>sc_node-root
            it_key         = lt_canc_key
            iv_association = /scmtms/if_tor_c=>sc_association-root-confirmationhistory
          IMPORTING
            et_key_link    = lt_root_confhist_link.

        LOOP AT lt_canc_key INTO ls_key.
          READ TABLE lt_root_data INTO ls_root_data
            WITH KEY key = ls_key-key.
          ASSERT sy-subrc = 0.

* Can the TOR be deleted or only be canceled ?
          " tbd: also FUs should be canceled!
          IF is_ctx-act_key = /scmtms/if_tor_c=>sc_action-root-hard_delete.
            INSERT ls_key INTO TABLE lt_key_delete.
          ELSE.
            " Check if the deletion is allowed at all?!
            CALL METHOD deletion_allowed(
              EXPORTING
                is_tor_root           = ls_root_data
                io_read               = io_read
                it_root_confhist_link = lt_root_confhist_link
              IMPORTING
                ev_deletion_allowed   = lv_deletion_allowed
              CHANGING
                co_message            = eo_message
            ).

            IF lv_deletion_allowed = abap_false.
              INSERT ls_key INTO TABLE lt_key_lc_update.
              INSERT ls_key INTO TABLE lt_key_lc_cancel.
            ELSE.
              INSERT ls_key INTO TABLE lt_key_delete.
            ENDIF.
          ENDIF.

          IF  ls_root_data-subcontracting = /scmtms/if_tor_status_c=>sc_root-subcontracting-v_in_tendering.
            ls_key-key = ls_root_data-key.
            INSERT ls_key INTO TABLE lt_stop_tender_key.
          ENDIF.

          " check if we have a MAWB-ID which has to be returned
          IF ls_root_data-partner_mbl_id IS NOT INITIAL. " Change the MBL Number Stock status when corresponding FO is cancelled (Note 3058972) irrespective of the TOR category
            CALL METHOD /scmtms/cl_common_helper=>insert_key
              EXPORTING
                iv_key = ls_root_data-key
              CHANGING
                ct_key = lt_k_mawb_return.
          ENDIF.

          " in case the TOR is relevant for customs the TOR should always be cancelled
          IF ls_root_data-customs <> /scmtms/if_gt_const=>cs_customs_status-initial.
            INSERT ls_key INTO TABLE lt_cancel_customs.
          ENDIF.

        ENDLOOP.

        " adapt all resource items where item_check_relevant flag is set to exclude them from
        " resource checks or context determination
        CALL METHOD io_read->retrieve_by_association
          EXPORTING
            iv_node        = /scmtms/if_tor_c=>sc_node-root
            it_key         = lt_canc_key
            iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr
            iv_fill_data   = abap_true
          IMPORTING
            et_data        = lt_item_tr
            et_target_key  = lt_itm_key.

        LOOP AT lt_item_tr ASSIGNING FIELD-SYMBOL(<ls_item_tr>) WHERE res_time_check_rel = /scmtms/if_tor_const=>sc_item_time_check_relevant-relevant.
          <ls_item_tr>-res_time_check_rel = /scmtms/if_tor_const=>sc_item_time_check_relevant-not_relevant.
          /scmtms/cl_mod_helper=>mod_update_single(
            EXPORTING
              is_data            = <ls_item_tr>
              iv_node            = /scmtms/if_tor_c=>sc_node-item_tr
              iv_bo_key          = /scmtms/if_tor_c=>sc_bo_key
              iv_autofill_fields = abap_false
            CHANGING
              ct_mod             = lt_mod ).
        ENDLOOP.

        IF lt_k_revoke_triang IS NOT INITIAL.
          io_modify->do_action(
            EXPORTING
              iv_act_key    = /scmtms/if_tor_c=>sc_action-root-cancel_triangulation
              it_key        = lt_k_revoke_triang ).
        ENDIF.
      ENDIF.
    WHEN OTHERS.
  ENDCASE.

*--------------------------------------------------------------------*
* Stop started and published tendering processes
*--------------------------------------------------------------------*

* Send EWM cancellation message if needed
  IF lt_k_cancel_ewm_for IS NOT INITIAL AND lines( lt_d_stop_cancel_ewm ) > 0.
    " send stop based cancel requests
    READ TABLE lt_d_stop_cancel_ewm ASSIGNING FIELD-SYMBOL(<ls_stop_cancel_ewm>) INDEX 1.
    ASSERT sy-subrc = 0.

    io_modify->do_action(
      EXPORTING
        iv_act_key    = /scmtms/if_tor_c=>sc_action-stop-cancel_loading_appointment
        it_key        = VALUE #( ( key = <ls_stop_cancel_ewm>-key ) )
      IMPORTING
        eo_message    = lo_message
        et_failed_key = lt_failed_key ).

    IF lo_message IS BOUND.
      /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
      FREE lo_message.
    ENDIF.

    LOOP AT lt_failed_key ASSIGNING <ls_failed_key>.
      DELETE lt_d_stop_cancel_ewm USING KEY parent_key WHERE parent_key = <ls_failed_key>-key.
    ENDLOOP.

    IF <ls_stop_cancel_ewm> IS ASSIGNED.
*    IF lt_d_stop_cancel_ewm IS NOT INITIAL.
*      LOOP AT lt_d_stop_cancel_ewm ASSIGNING FIELD-SYMBOL(<stop>).
        <ls_stop_cancel_ewm>-wh_transm_status = /scmtms/if_tor_status_c=>sc_stop-wh_transm_status-v_tor_cancel_requested.
        MESSAGE s814(/scmtms/tor) INTO lv_mtext.
        CALL METHOD /scmtms/cl_msg_helper=>msg_helper_add_symsg
          EXPORTING
            iv_key       = <ls_stop_cancel_ewm>-root_key
            iv_node_key  = /scmtms/if_tor_c=>sc_node-root
            iv_probclass = '1'
          CHANGING
            co_message   = eo_message.

*      ENDLOOP.
      /scmtms/cl_mod_helper=>mod_update_multi(
        EXPORTING
          iv_node            = /scmtms/if_tor_c=>sc_node-stop
          it_data            = VALUE /scmtms/t_tor_stop_k( ( <ls_stop_cancel_ewm> ) )
          iv_bo_key          = /scmtms/if_tor_c=>sc_bo_key
        CHANGING
          ct_mod             = lt_mod ).
    ENDIF.

    " In case only EWM cancellation request left do not perform the other cancellation steps
    IF lv_cancel_ewm_only = abap_true.
      CALL METHOD io_modify->do_modify
        EXPORTING
          it_modification = lt_mod.

      " ensure that the changes are merged immediately
      io_modify->end_modify( iv_process_immediately = abap_true ).
      " turn on validations
      /scmtms/cl_tor_validations=>turn_on_vals( ).
      /scmtms/cl_tor_fc=>gv_disable_properties = abap_false.
      /scmtms/cl_d_superclass=>clear_delkeys( it_key ).
      /scmtms/cl_d_superclass=>clear_cancelkeys( ).
      RETURN.
    ENDIF.
  ENDIF.

  IF lt_stop_tender_key IS NOT INITIAL.
    CREATE DATA lr_act_param.
    lr_act_param->no_check = abap_true.

    " Call action STOP_TENDERING
    CALL METHOD io_modify->do_action
      EXPORTING
        iv_act_key    = /scmtms/if_tor_c=>sc_action-root-stop_tender
        it_key        = lt_stop_tender_key
        is_parameters = lr_act_param
      IMPORTING
        et_failed_key = lt_failed_key.

    IF lt_failed_key IS NOT INITIAL.
      LOOP AT lt_failed_key ASSIGNING <ls_failed_key>.
        INSERT LINES OF lt_failed_key INTO TABLE et_failed_key.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF lt_k_mawb_return IS NOT INITIAL.
    CREATE DATA lr_act_param_mawb_return.
    IF is_parameters IS NOT INITIAL AND is_parameters IS BOUND.
      ASSIGN is_parameters->* TO <ls_param_lc_cancel>.
      IF <ls_param_lc_cancel>-mawb_back_to_stock IS INITIAL.
        lr_act_param_mawb_return->mawb_void = abap_true.
      ENDIF.
    ENDIF.
    CALL METHOD io_modify->do_action
      EXPORTING
        iv_act_key    = /scmtms/if_tor_c=>sc_action-root-mawb_nr_return
        is_parameters = lr_act_param_mawb_return
        it_key        = lt_k_mawb_return
      IMPORTING
        eo_message    = lo_message.
    IF lo_message IS BOUND.
      /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
      FREE lo_message.
    ENDIF.
  ENDIF.

  LOOP AT lt_d_stop ASSIGNING <ls_stop> WHERE wh_door_status = /scmtms/if_tor_status_stop_c=>sc_wh_door_status-arrived_at_door.
    READ TABLE lt_canc_key WITH KEY key_sort COMPONENTS key = <ls_stop>-root_key TRANSPORTING NO FIELDS.
    CHECK sy-subrc = 0.
    INSERT VALUE #( key = <ls_stop>-key ) INTO TABLE lt_k_wh_door_stat_reset.
  ENDLOOP.

  IF lt_k_wh_door_stat_reset IS NOT INITIAL.
    " reset warehouse door status for stops
    CREATE DATA lr_set_wh_door_status.
    CALL METHOD io_modify->do_action
      EXPORTING
        iv_act_key    = /scmtms/if_tor_c=>sc_action-stop-set_wh_door_status
        it_key        = lt_k_wh_door_stat_reset
        is_parameters = lr_set_wh_door_status.
  ENDIF.

* Get the trq root keys to trigger lc and confirmation update
  lt_upd_trq = lt_canc_key.
  INSERT LINES OF lt_key_initial_fus INTO TABLE lt_upd_trq.
  CALL METHOD io_read->retrieve_by_association(
    EXPORTING
      iv_node        = /scmtms/if_tor_c=>sc_node-root
      it_key         = lt_upd_trq
      iv_association = /scmtms/if_tor_c=>sc_association-root-bo_trq_root
    IMPORTING
      et_target_key  = lt_trq_root_key
      et_key_link    = lt_kl_tor_trq
  ).

*--------------------------------------------------------------------*
* Update LC Status and set output options for sending of B2B
* cancellation message
*--------------------------------------------------------------------*
  LOOP AT lt_key_lc_update INTO ls_key.
    " issue a message
    CASE lv_lc_status.
      WHEN /scmtms/if_tor_status_c=>sc_root-lifecycle-v_canceled.
        READ TABLE lt_tor_identifier
          INTO ls_tor_identifier
          WITH TABLE KEY key = ls_key-key.

        MESSAGE i011(/scmtms/tor) WITH ls_tor_identifier-identifier INTO lv_dummy.
        CALL METHOD /scmtms/cl_common_helper=>msg_helper_add_symsg(
          EXPORTING
            iv_key       = ls_key-key
            iv_probclass = /scmtms/cl_applog_helper=>sc_al_probclass_important "message shall be send always
          CHANGING
            co_message   = lo_message ).

        IF lo_message IS BOUND.
          /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
          FREE lo_message.
        ENDIF.
    ENDCASE.

    CLEAR ls_mod.
    ls_mod-node        = is_ctx-root_node_key.
    ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_update.
    ls_mod-key         = ls_key-key.
    CREATE DATA lr_root.
    lr_root->key              = ls_key-key.
    lr_root->lifecycle        = lv_lc_status.

    INSERT /scmtms/if_tor_c=>sc_node_attribute-root-lifecycle     INTO TABLE ls_mod-changed_fields.
    INSERT /scmtms/if_tor_c=>sc_node_attribute-root-datetime_chlc INTO TABLE ls_mod-changed_fields.
    INSERT /scmtms/if_tor_c=>sc_node_attribute-root-user_id_chlc  INTO TABLE ls_mod-changed_fields.

    READ TABLE lt_root_data INTO ls_root_data
         WITH KEY key = ls_key-key.

    IF sy-subrc EQ 0.

*     Check if a B2B cancellation message has to be triggered, and determine the correct output option
      CASE ls_root_data-tor_cat.
        WHEN /scmtms/if_tor_const=>sc_tor_category-booking.  "Booking
          lv_output_option = /scmtms/if_tend_c=>sc_tend_output_options-cnc_b2b_msg_booking. " 15
        WHEN /scmtms/if_tor_const=>sc_tor_category-active.   "Freight Order
          lv_output_option = /scmtms/if_tend_c=>sc_tend_output_options-cnc_b2b_msg_fo.      " 16
        WHEN OTHERS.                                         "Skip
          CLEAR lv_output_option.
      ENDCASE.

*     set output options "Send B2B cancellation message", if freight order or freight booking has been sent
      IF  ( ls_root_data-subcontracting = /scmtms/if_tor_status_c=>sc_root-subcontracting-v_sent OR
            ls_root_data-subcontracting = /scmtms/if_tor_status_c=>sc_root-subcontracting-v_changes_after_sending OR
            ls_root_data-confirmation = /scmtms/if_tor_status_c=>sc_root-confirmation-v_doc_changed_after_conf OR
            ls_root_data-confirmation = /scmtms/if_tor_status_c=>sc_root-confirmation-v_accepted OR
            ls_root_data-confirmation = /scmtms/if_tor_status_c=>sc_root-confirmation-v_accepted_with_changes )
       AND lv_output_option IS NOT INITIAL.

        CALL METHOD /scmtms/cl_tend_tools=>set_output_option
          EXPORTING
            iv_node_key             = lr_root->key
            iv_single_output_option = lv_output_option
          CHANGING
            cs_output_options       = lr_root->s_output_options.

        INSERT /scmtms/if_tor_c=>sc_node_attribute-root-output_options          INTO TABLE ls_mod-changed_fields.
        INSERT /scmtms/if_tor_c=>sc_node_attribute-root-output_opt_chg_datetime INTO TABLE ls_mod-changed_fields.

*     and collect key for confirmation history
        INSERT ls_root_data INTO TABLE lt_confhist_data.

      ENDIF.

*     set output option "Send shipment cancellation" (A2A), if a shipment has already been sent
      IF ls_root_data-shpm_transm NE /scmtms/if_tor_status_c=>sc_root-shpm_transm-v_new.

        CALL METHOD /scmtms/cl_tend_tools=>set_output_option
          EXPORTING
            iv_node_key             = lr_root->key
            iv_single_output_option = /scmtms/if_tend_c=>sc_tend_output_options-cnc_a2a_msg_shp
          CHANGING
            cs_output_options       = lr_root->s_output_options.

        INSERT /scmtms/if_tor_c=>sc_node_attribute-root-output_options          INTO TABLE ls_mod-changed_fields.
        INSERT /scmtms/if_tor_c=>sc_node_attribute-root-output_opt_chg_datetime INTO TABLE ls_mod-changed_fields.

*     and collect key for confirmation history
        INSERT ls_root_data INTO TABLE lt_confhist_data.

      ENDIF.

    ENDIF.


*   set dates and times of change
    lr_root->user_id_chlc    = sy-uname.
    GET TIME STAMP FIELD lr_root->datetime_chlc.

    ls_mod-data        = lr_root.
    INSERT ls_mod INTO TABLE lt_mod.
  ENDLOOP.

*    prepare data for history record of messages
  prepare_confhist_node(
    EXPORTING
      it_root_data          =  lt_confhist_data
    IMPORTING
      er_act_param_confhist =   lr_confhist_parm
      et_root_confhist_key  =   lt_confhist_key  ).

  IF lt_confhist_key IS NOT INITIAL.
* create history record
    CALL METHOD io_modify->do_action
      EXPORTING
        iv_act_key    = /scmtms/if_tor_c=>sc_action-root-confhist_create_entry
        it_key        = lt_confhist_key
        is_parameters = lr_confhist_parm
      IMPORTING
        eo_message    = lo_message
        et_failed_key = lt_failed_key.
    IF lo_message IS BOUND.
      /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
      FREE lo_message.
    ENDIF.

    APPEND LINES OF lt_failed_key TO et_failed_key.

  ENDIF.


*--------------------------------------------------------------------*
* Synchronous Execution of the Deletion Strategy
*--------------------------------------------------------------------*
  CALL METHOD execute_del_strat_proc
    EXPORTING
      it_key     = lt_canc_key
    IMPORTING
      eo_message = lo_message.

  IF lo_message IS BOUND.
    /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
    FREE lo_message.
  ENDIF.


*--------------------------------------------------------------------*
* Special handling only for canceled TORs
*--------------------------------------------------------------------*

  IF lt_canc_key IS NOT INITIAL.
    "Prepare TAL action -> perform only unassign
    CREATE DATA lr_tal_bs_param.
    ls_tor_tsp-unassign_only = abap_true.

    LOOP AT lt_canc_key INTO ls_key.
      ls_tor_tsp-tor_key = ls_key-key.
      INSERT ls_tor_tsp INTO TABLE lr_tal_bs_param->t_tsp_key.
    ENDLOOP.

    "unload all relevant TALs and BSs
    io_modify->do_action(
      EXPORTING
        iv_act_key    = /scmtms/if_tor_c=>sc_action-root-tal_bs_reassign
        it_key        = lt_canc_key
        is_parameters = lr_tal_bs_param
      IMPORTING
        eo_message    = lo_message  ).

    IF lo_message IS BOUND.
      /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
      FREE lo_message.
    ENDIF.
  ENDIF.


  "--------------------------------------------------------------------------"
  " handle customs
  CALL METHOD handle_customs(
    EXPORTING
      it_key     = lt_cancel_customs
      io_read    = io_read
      io_modify  = io_modify
    CHANGING
      co_message = eo_message
  ).

  "--------------------------------------------------------------------------"
  " Handle Product Compliance
  CALL METHOD handle_product_compliance(
      it_key  = lt_cancel_customs
      io_read = io_read ).

*--------------------------------------------------------------------*
* Delete TORs
*--------------------------------------------------------------------*
* check that the TORs still exist (maybe the got already deleted in delete strategy)
  CALL METHOD io_read->get_root_key
    EXPORTING
      it_key        = lt_key_delete
      iv_node       = /scmtms/if_tor_c=>sc_node-root
    IMPORTING
      et_target_key = lt_key_delete2.

  LOOP AT lt_key_delete2 INTO ls_key.
    READ TABLE lt_tor_identifier
      INTO ls_tor_identifier
      WITH TABLE KEY key = ls_key-key.
    READ TABLE lt_root_data REFERENCE INTO lr_root WITH TABLE KEY key = ls_key-key.
    IF sy-subrc = 0 AND
       lr_root->tor_cat = /scmtms/if_tor_const=>sc_tor_cat_fu.
      lv_detlvl     = /scmtms/cl_applog_helper=>sc_al_detlev_detail. "Freight unit deletion is more a technial detail
      lv_probclass  = /scmtms/cl_applog_helper=>sc_al_probclass_add_info.
    ELSE.
      lv_detlvl = /scmtms/cl_applog_helper=>sc_al_detlev_default.
      lv_probclass  = /scmtms/cl_applog_helper=>sc_al_probclass_medium.
    ENDIF.

    MESSAGE i010(/scmtms/tor) WITH ls_tor_identifier-identifier INTO lv_dummy.
    CALL METHOD /scmtms/cl_common_helper=>msg_helper_add_symsg(
      EXPORTING
        iv_key      = ls_key-key
        iv_detlevel = lv_detlvl
      CHANGING
        co_message  = lo_message
    ).

    IF lo_message IS BOUND.
      /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
      FREE lo_message.
    ENDIF.
    CLEAR ls_mod.
    ls_mod-node        = is_ctx-root_node_key.
    ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_delete.
    ls_mod-key         = ls_key-key.
    CREATE DATA lr_root.
    ls_mod-data        = lr_root.
    INSERT ls_mod INTO TABLE lt_mod.
  ENDLOOP.

  " additionally add the delete-modifications for the initial FUs
  IF lt_key_initial_fus IS NOT INITIAL.
    CALL METHOD /scmtms/cl_mod_helper=>mod_delete_multi
      EXPORTING
        iv_node = is_ctx-node_key
        it_keys = lt_key_initial_fus
      CHANGING
        ct_mod  = lt_mod.
    INSERT LINES OF lt_key_initial_fus INTO TABLE lt_key_delete2.
  ENDIF.


*--------------------------------------------------------------------*
* Handle Cancellation
*--------------------------------------------------------------------*
  IF lt_key_lc_cancel IS NOT INITIAL.

    /scmtms/cl_d_superclass=>register_cancelkeys( it_key = lt_key_lc_cancel ).

    CALL METHOD handle_cancellation
      EXPORTING
        io_read      = io_read
        it_key       = lt_key_lc_cancel
        it_root_data = lt_root_data
      CHANGING
        ct_mod       = lt_mod
        co_message   = lo_message.
  ENDIF.
  IF lo_message IS BOUND.
    /scmtms/cl_common_helper=>msg_helper_add_mo( EXPORTING io_new_message = lo_message CHANGING co_message = eo_message ).
    FREE lo_message.
  ENDIF.


*--------------------------------------------------------------------*
* Remove obsolete entries from connection cache
*--------------------------------------------------------------------*
  lv_skip_upd_conn_cache = abap_false.
  IF <ls_param_lc_cancel> IS ASSIGNED AND <ls_param_lc_cancel>-skip_upd_conn_cache = abap_true.
    lv_skip_upd_conn_cache = abap_true.
  ENDIF.

  IF lv_skip_upd_conn_cache = abap_false.
    /scmtms/cl_tn_connect_helper=>update_connection_cache(
      EXPORTING
        it_key     = lt_canc_key
        iv_cancel  = abap_true
      CHANGING
        ct_root    = lt_root_data
        co_message = eo_message
    ).
  ENDIF.

*--------------------------------------------------------------------*
* Post changes
*--------------------------------------------------------------------*
  IF lt_mod IS NOT INITIAL.
*    for deleted tor call the update of the follow up documents before the deletion of the nodes
    CREATE DATA lr_param_folup.
    lr_param_folup->called_from_cancel = abap_true.

    IF lt_key_delete2 IS NOT INITIAL.
      " disable the determination which would be run when the TOR is deleted (BOPF loads the complete model via get_subnodes() which can lead to weird things))
      /scmtms/cl_d_superclass=>register_delkeys( EXPORTING it_key = lt_key_delete2 ).
    ENDIF.
    IF lt_key_lc_cancel IS NOT INITIAL.
      /scmtms/cl_d_superclass=>register_cancelkeys( EXPORTING it_key = lt_key_lc_cancel ).
    ENDIF.

    io_modify->do_action(
      EXPORTING
        iv_act_key    = /scmtms/if_tor_c=>sc_action-root-do_follow_up_actions
        it_key        = lt_key_delete2
        is_parameters = lr_param_folup ).

    CALL METHOD io_modify->do_modify
      EXPORTING
        it_modification = lt_mod.

    " ensure that the changes are merged immediately
    io_modify->end_modify( iv_process_immediately = abap_true ).

  ENDIF.

* Send Email/SMS to Awarded Carrier in Direct Tendering
  CALL METHOD send_email_to_carrier
    EXPORTING
      it_root_data = lt_root_data
      io_read      = io_read
    CHANGING
      co_message   = eo_message.

* trigger TRQ aggregated statues and confirmation update
  DATA(lv_skip_trq_update) = abap_false.
  IF <ls_param_lc_cancel> IS ASSIGNED AND <ls_param_lc_cancel>-skip_trq_update = abap_true.
    lv_skip_trq_update = abap_true.
  ENDIF.

  IF lv_skip_trq_update = abap_false.
    CALL METHOD update_trq
      EXPORTING
        it_root         = lt_root_data
        it_trq_root_key = lt_trq_root_key
        it_kl_tor_trq   = lt_kl_tor_trq
        io_modify       = io_modify
      CHANGING
        co_message      = eo_message.
  ENDIF.

  " turn on validations
  /scmtms/cl_tor_validations=>turn_on_vals( ).
  /scmtms/cl_tor_fc=>gv_disable_properties = abap_false.
  /scmtms/cl_d_superclass=>clear_cancelkeys( ).
  IF lt_key_delete2 IS NOT INITIAL.
    " remove the keys again!
    /scmtms/cl_d_superclass=>clear_delkeys( EXPORTING it_key = lt_key_delete2 ).
  ENDIF.

ENDMETHOD.
