FUNCTION /tenr/fm_send_tor_attach_sgt_s.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IT_KEY) TYPE  /BOBF/T_FRW_KEY
*"     REFERENCE(IO_SRV_TOR) TYPE REF TO  /BOBF/IF_TRA_SERVICE_MANAGER
*"     REFERENCE(IT_KEY_SOURCE) TYPE  /BOBF/T_FRW_KEY
*"     REFERENCE(IO_READ) TYPE REF TO  /BOBF/IF_FRW_READ
*"     REFERENCE(IS_CTX) TYPE  /BOBF/S_FRW_CTX_DET
*"     REFERENCE(IT_ROOT) TYPE  /SCMTMS/T_TOR_ROOT_K
*"  EXPORTING
*"     REFERENCE(E_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------
  CONSTANTS: lc_base_btd TYPE /scmtms/base_btd_tco VALUE '73',
             lc_item_cat TYPE /scmtms/item_category VALUE 'PRD'.

  DATA: lo_proxy        TYPE REF TO /tenr/co_ws_os_upload_service,
        lo_sgt_out      TYPE /tenr/ws_service_req_doc_mrqs,
        lo_out_tab      TYPE /tenr/ws_shipment_document_tab,
        lo_out          TYPE /tenr/ws_shipment_documents_sh,
        lo_message      TYPE REF TO /bobf/if_frw_message,
        lt_root_tor     TYPE /scmtms/t_tor_root_k,
        lt_item_tor     TYPE /scmtms/t_tor_item_tr_k,
        lt_root_trq     TYPE /scmtms/t_trq_root_k,
        lt_item_trq     TYPE /scmtms/t_trq_item_k,
        lt_trq_zrig     TYPE /tenr/t_trq_rig_direct_k,
        lt_attachment   TYPE /bobf/t_atf_root_k,
        lt_document     TYPE /bobf/t_atf_document_k,
        lt_file         TYPE /bobf/t_atf_file_content_k,
        lt_key_root_tor TYPE /bobf/t_frw_key,
        lt_key_root_trq TYPE /bobf/t_frw_key,
        lt_key_zrig_trq TYPE /bobf/t_frw_key,
        lt_key_item_tor TYPE /bobf/t_frw_key,
        lt_selpar       TYPE /bobf/t_frw_query_selparam,
        ls_selpar       TYPE /bobf/s_frw_query_selparam,
        lt_return       TYPE /tenr/ws_service_req_doc_mrsp,
        lo_fault        TYPE REF TO cx_root. " Generic Fault

  DATA lv_file TYPE string.

  DATA(lo_srv_tor) = io_srv_tor.
  DATA(lo_srv_trq) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_trq_c=>sc_bo_key ).

  "buscamos el nodo item para buscar el key de tor root
  CALL METHOD lo_srv_tor->retrieve_by_association
    EXPORTING
      iv_node_key    = /scmtms/if_tor_c=>sc_node-root
      it_key         = it_key
      iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_item_tor.

  CHECK lt_item_tor IS NOT INITIAL.

  READ TABLE lt_item_tor INTO DATA(ls_item_tor) WITH KEY item_cat = lc_item_cat main_cargo_item = abap_true.

  APPEND VALUE #( key = ls_item_tor-orig_ref_root ) TO lt_key_root_trq.

  "traemos el nodo root de trq
  CALL METHOD lo_srv_trq->retrieve
    EXPORTING
      iv_node_key  = /scmtms/if_trq_c=>sc_node-root
      it_key       = lt_key_root_trq
      iv_fill_data = abap_true
    IMPORTING
      et_data      = lt_root_trq.

***** traemos el nodo item de trq
  CALL METHOD lo_srv_trq->retrieve_by_association
    EXPORTING
      iv_node_key    = /scmtms/if_trq_c=>sc_node-root
      it_key         = lt_key_root_trq
      iv_association = /scmtms/if_trq_c=>sc_association-root-item
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_item_trq.

***** Buscar Service request TOR
  CALL METHOD lo_srv_trq->retrieve_by_association(
    EXPORTING
      iv_node_key    = /scmtms/if_trq_c=>sc_node-root
      it_key         = lt_key_root_trq
      iv_association = /tenr/if_trq_c=>sc_association-root-zrig_direct
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_trq_zrig ).

***** attach eventos TOR

  CALL METHOD lo_srv_trq->retrieve_by_association(
    EXPORTING
      iv_node_key    = /scmtms/if_trq_c=>sc_node-root
      it_key         = lt_key_root_trq
      iv_association = /tenr/if_trq_c=>sc_association-root-zrig_direct
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_trq_zrig ).

  DATA tg_document TYPE /bobf/t_atf_document_k.
  DATA lt_root         TYPE /scmtms/t_tor_root_k.

  /scmtms/cl_common_helper=>get_do_keys_4_rba( EXPORTING iv_host_bo_key      = /scmtms/if_tor_c=>sc_bo_key
                                                         iv_host_do_node_key = /scmtms/if_tor_c=>sc_node-attachmentfolder
                                                         iv_do_assoc_key     = /bobf/if_attachment_folder_c=>sc_association-root-document_list
                                              IMPORTING ev_assoc_key        = DATA(lv_attach_assoc_key) ).

  /scmtms/cl_common_helper=>get_do_keys_4_rba(
    EXPORTING
      iv_host_bo_key      = /scmtms/if_tor_c=>sc_bo_key
      iv_host_do_node_key = /scmtms/if_tor_c=>sc_node-executionatf
      iv_do_node_key      = /bobf/if_attachment_folder_c=>sc_node-root
      iv_do_assoc_key     = /bobf/if_attachment_folder_c=>sc_association-root-document_list
    IMPORTING
      ev_node_key         = DATA(lv_do_atf_node_key)
      ev_assoc_key        = DATA(lv_do_atf_root_docs_assoc) ).

  CALL METHOD io_read->retrieve_by_association
    EXPORTING
      iv_node        = /bobf/if_attachment_folder_c=>sc_node-root
      it_key         = it_key_source
      iv_association = /bobf/if_attachment_folder_c=>sc_association-root-document_list
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_document
      et_key_link    = DATA(lt_key_l)
      et_target_key  = DATA(lt_key_folder).

  io_read->retrieve(
    EXPORTING
      iv_node       = /bobf/if_attachment_folder_c=>sc_node-file_content  "'483ED41FA4351B4EE10000000A42172E'
      it_key        = lt_key_folder
      iv_fill_data  = abap_true
    IMPORTING
      et_data       = lt_file ).

  IF lt_document IS NOT INITIAL.
**
    LOOP AT lt_document ASSIGNING FIELD-SYMBOL(<lfs_atf>) WHERE datetime_cr IS INITIAL.

      TRY.
          lo_sgt_out-service_req_doc_mrqs-document-take_out = lt_trq_zrig[ 1 ]-service_request.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
      TRY.
          lo_sgt_out-service_req_doc_mrqs-document-take_out_item = lt_item_trq[ 1 ]-zser_req_item_num.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
      "ShipmentDocument
      TRY.
          lo_sgt_out-service_req_doc_mrqs-document-shipment_document = it_root[ 1 ]-tor_id. "Mo.21.12.23 T21255
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.

      IF ls_item_tor-base_btd_tco = lc_base_btd.
        lo_sgt_out-service_req_doc_mrqs-document-outbound_delivery = ls_item_tor-base_btd_id.
      ENDIF.

      lo_sgt_out-service_req_doc_mrqs-document-document_type = <lfs_atf>-attachment_type.

      lo_sgt_out-service_req_doc_mrqs-document-document_name = <lfs_atf>-description.

      TRY.
          lo_sgt_out-service_req_doc_mrqs-document-file = VALUE #( lt_file[ key = <lfs_atf>-key ]-content DEFAULT '' ).
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
      IF lo_sgt_out-service_req_doc_mrqs-document-take_out IS NOT INITIAL.
        CREATE OBJECT lo_proxy.
        TRY.
            CALL METHOD lo_proxy->os_upload_service_request_docu
              EXPORTING
                output = lo_sgt_out
              IMPORTING
                input  = lt_return.
          CATCH cx_root INTO lo_fault.
        ENDTRY.
        CLEAR  e_message.
        IF lo_fault IS NOT BOUND AND lt_return IS INITIAL.
          COMMIT WORK.
        ELSE.
          e_message      = lt_return-service_req_doc_mrsp-result-response_status && lt_return-service_req_doc_mrsp-result-response_desc.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFUNCTION.
