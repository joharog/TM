FUNCTION /TENR/FM_WF_APROB_FO_IN .
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_DOC_STATUS) TYPE  /TENR/S_STATUS_DOC
*"     REFERENCE(I_MESSAGE) TYPE  /TENR/S_ITEM_STATUS_DOC
*"  EXPORTING
*"     REFERENCE(E_MESSAGE) TYPE  /TENR/S_ITEM_STATUS_DOC
*"--------------------------------------------------------------------

  DATA: lt_fag_id       TYPE /scmtms/t_fag_id,
        lt_fag_root_key TYPE /bobf/t_frw_key,
        lt_selpar       TYPE /bobf/t_frw_query_selparam,
        lo_message      TYPE REF TO  /bobf/if_frw_message,
        lo_tra          TYPE REF TO /bobf/if_tra_transaction_mgr,
        ls_message      TYPE string,
        lt_failed_key   TYPE /bobf/t_frw_key.

*  FIELD-SYMBOLS: <ls_key> LIKE LINE OF lt_key.

*  CLEAR ls_key.
*  ls_key–key = /scmtms/cl__helper_root=>( iv_torid =  i_eai–event_msg–hdr–trxid ).
*  INSERT ls_key INTO TABLE lt_key.

  DATA(lo_srv_fag) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_fag_c=>sc_bo_key ).

*  i_doc_status-ebeln
*  i_doc_status-status
*  i_doc_status-desicion

  APPEND VALUE #( fagrmntid044 = |{ CONV /scmtms/fag_id( i_doc_status-ebeln ) ALPHA = IN }|   ) TO lt_fag_id.

  "convertir de llave externa a llave interna
  lo_srv_fag->convert_altern_key(
       EXPORTING
         iv_node_key = /scmtms/if_fag_c=>sc_node-root
         iv_altkey_key = /scmtms/if_fag_c=>sc_alternative_key-root-fagrmntid044
         it_key = lt_fag_id
       IMPORTING
         et_key = lt_fag_root_key ).

  CHECK lt_fag_root_key IS NOT INITIAL.


  IF lt_fag_root_key[ 1 ]-key NE '00000000000000000000000000000000'.

    CASE i_doc_status-decision.
      WHEN 'approve'.

        TRY.
            CALL METHOD lo_srv_fag->do_action
              EXPORTING
                iv_act_key    = /scmtms/if_fag_c=>sc_action-root-set_released
                it_key        = lt_fag_root_key
                is_parameters = NEW /scmtms/t_fag_status( ( status = '02' key = /scmtms/if_fag_c=>sc_node-root ) )
              IMPORTING
                eo_message    = lo_message
                et_failed_key = lt_failed_key.
          CATCH /bobf/cx_frw_contrct_violation.
        ENDTRY.


      WHEN 'reject'.

        TRY.
            CALL METHOD lo_srv_fag->do_action
              EXPORTING
                iv_act_key    = /scmtms/if_fag_c=>sc_action-root-set_in_process
                it_key        = lt_fag_root_key
                is_parameters = NEW /scmtms/t_fag_status( ( status = '01' key = /scmtms/if_fag_c=>sc_node-root ) )
              IMPORTING
                eo_message    = lo_message
                et_failed_key = lt_failed_key.
          CATCH /bobf/cx_frw_contrct_violation.
        ENDTRY.

    ENDCASE.

    IF lo_message IS BOUND.

      lo_message->get_messages(
            IMPORTING
              et_message              = DATA(lt_message) ).

      LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<lfs_message>).
        CASE <lfs_message>-severity.
          WHEN 'E'.
            APPEND VALUE #( message = |{ <lfs_message>-severity } { <lfs_message>-message->get_text( ) }| ) TO e_message-item .
            EXIT.
          WHEN 'S'.
            APPEND VALUE #( message = |{ <lfs_message>-severity } { <lfs_message>-message->get_text( ) }| ) TO e_message-item .
            EXIT.
        ENDCASE.
      ENDLOOP.

*      IF  e_message-item[] IS INITIAL.
*        CASE i_doc_status-desicion.
*          WHEN 'approve'.
*         e_message-item = VALUE #( ( message = |Documento { i_doc_status-ebeln  } liberacion exitosa| ) ).
*           WHEN 'reject'.
*              e_message-item = VALUE #( ( message = |Documento { i_doc_status-ebeln  } actualizado| ) ).
*        ENDCASE.
*      ENDIF.

      IF <lfs_message>-severity NE 'E'.
        lo_tra = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).
        lo_tra->save(
        IMPORTING
        eo_message = lo_message ).
      ENDIF.
    ENDIF.

  ELSE.
    e_message-item = VALUE #( ( message = |Documento { i_doc_status-ebeln  } no encontrado| ) ).
  ENDIF.

*      IF  e_message-item[] IS INITIAL.
*        CASE i_doc_status-desicion.
*          WHEN 'approve'.
*         e_message-item = VALUE #( ( message = |Documento { i_doc_status-ebeln  } liberacion exitosa| ) ).
*           WHEN 'reject'.
*         e_message-item = VALUE #( ( message = |Documento { i_doc_status-ebeln  } actualizado| ) ).
*        ENDCASE.
*      ENDIF.

ENDFUNCTION.
