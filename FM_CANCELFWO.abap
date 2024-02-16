FUNCTION /tenr/fm_cancelfwo.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     VALUE(I_CANCEL) TYPE  ZTEN_TT_TMDELETEFWO
*"  EXPORTING
*"     VALUE(E_MESS) TYPE  ZTEN_TT_TMDELERESPONSE
*"----------------------------------------------------------------------
*------------------------------------------------------------
*ABAP Name  : /TENR/Rodolfo Gonzalez
*Created by : T20789
*Created on : 20/04/2023
*Version    : V.1
*Description: Interfaz ( Funcion para creacion de FWO )
*------------------------------------------------------------
*Modification Log:
*Date  Programmer   Correction  Description
*mm/dd/yyyy Txxxxx ó SIDTxxx  TEDK000001  Added……
*------------------------------------------------------------

  DATA(lr_trq_srvmgr) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_trq_c=>sc_bo_key ).

* set an example query parameter

  "LOOP AT

  READ TABLE i_cancel INTO DATA(wa_cancel) INDEX 1.


  lt_selpar = VALUE #( ( sign           = c_i
                         option         = c_eq
                         low            = wa_cancel-trq_id
                         attribute_name = /scmtms/if_trq_c=>sc_query_attribute-root-root_elements-trq_id ) ).
* find a TRQ instance to be deleted

  TRY.

      lr_trq_srvmgr->query(
        EXPORTING
          iv_query_key            = /scmtms/if_trq_c=>sc_query-root-root_elements
          it_selection_parameters = lt_selpar
          iv_fill_data            = abap_true
        IMPORTING
          eo_message              = lo_message
          et_data                 = lt_trq_qdb
      ).

    CATCH /bobf/cx_frw INTO DATA(lx_frw).

  ENDTRY.

  IF lt_trq_qdb[] IS NOT INITIAL.

    lt_key = VALUE #( ( key = lt_trq_qdb[ 1 ]-key ) ).

    CREATE DATA lr_s_parameters .
    lr_s_parameters->no_check      = abap_true.
    " lr_s_parameters->cncl_rsn_code = '01'.

    DATA(lr_tra_mgr) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

    lr_trq_srvmgr->do_action(
      EXPORTING
        iv_act_key              = /scmtms/if_trq_c=>sc_action-root-cancel
        it_key                  = lt_key
        is_parameters           = lr_s_parameters
      IMPORTING
        eo_change               = lo_change
        eo_message              = lo_message
        et_failed_key           = lt_failed_key
        et_failed_action_key    = lt_failed_act_key
        ev_static_action_failed = DATA(failed)
    ).

    lo_message->get_messages( IMPORTING et_message = DATA(lt_message) )."Extraccion de mensajes

    LOOP AT lt_message INTO DATA(ls_mess).

      APPEND VALUE #(  trq_id  = wa_cancel-trq_id
                       estatus = c_estatus
                       message = ls_mess-message->get_text( ) ) TO e_mess.

    ENDLOOP.
    lr_tra_mgr->save(
      EXPORTING
        iv_transaction_pattern = /bobf/if_tra_c=>gc_tp_save_and_continue
      IMPORTING
        ev_rejected            = DATA(lv_reject)
        eo_change              = DATA(lv_change)
        eo_message             = DATA(lv_messa)
    ).

  ELSE.

    APPEND  VALUE #(  trq_id  = wa_cancel-trq_id
                        estatus = c_estatus2
                        message = c_error )  TO e_mess.

  ENDIF.

  CLEAR: wa_cancel.
  "  ENDLOOP.

ENDFUNCTION.
