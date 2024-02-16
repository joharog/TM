FUNCTION /tenr/fm_send_tor_attach_sgt.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IT_KEY) TYPE  /BOBF/T_FRW_KEY
*"  EXPORTING
*"     REFERENCE(E_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------
  DATA lo_srv_tor   TYPE REF TO /bobf/if_tra_service_manager.
  DATA lo_srv_trq   TYPE REF TO /bobf/if_tra_service_manager.

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

  lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).
  lo_srv_trq = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_trq_c=>sc_bo_key ).

  "con la llave de atachment buscamos el nodo root
  CALL METHOD lo_srv_tor->retrieve_by_association
    EXPORTING
      iv_node_key    = /scmtms/if_tor_c=>sc_node-attachmentfolder
      it_key         = it_key
      iv_association = /scmtms/if_tor_c=>sc_association-attachmentfolder-to_root
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_root_tor
      et_target_key  = lt_key_root_tor.

  CHECK lt_key_root_tor IS NOT INITIAL.

  "buscamos el nodo item para buscar el key de tor root
  CALL METHOD lo_srv_tor->retrieve_by_association
    EXPORTING
      iv_node_key    = /scmtms/if_tor_c=>sc_node-root
      it_key         = lt_key_root_tor
      iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_item_tor.

  CHECK lt_item_tor IS NOT INITIAL.

  READ TABLE lt_item_tor INTO DATA(ls_item_tor) WITH KEY item_cat = 'PRD' main_cargo_item = abap_true.

  APPEND VALUE #( key = ls_item_tor-orig_ref_root ) TO lt_key_root_trq.

  "traemos el nodo root de trq
  CALL METHOD lo_srv_trq->retrieve
    EXPORTING
      iv_node_key  = /scmtms/if_trq_c=>sc_node-root
      it_key       = lt_key_root_trq
      iv_fill_data = abap_true
    IMPORTING
      et_data      = lt_root_trq.

  "traemos el nodo item de trq
  CALL METHOD lo_srv_trq->retrieve_by_association
    EXPORTING
      iv_node_key    = /scmtms/if_trq_c=>sc_node-root
      it_key         = lt_key_root_trq
      iv_association = /scmtms/if_trq_c=>sc_association-root-item
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_item_trq.

*  SELECT * FROM /TENR/T_TMTRQRIG
*    INTO TABLE lt_zig_trq
*    WHERE parent_key = ls_item_tor-orig_ref_root.

  CALL METHOD lo_srv_trq->retrieve_by_association(
    EXPORTING
      iv_node_key    = /scmtms/if_trq_c=>sc_node-root
      it_key         = lt_key_root_trq
      iv_association = /tenr/if_trq_c=>sc_association-root-zrig_direct
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_trq_zrig ).


  CALL METHOD lo_srv_tor->retrieve_by_association
    EXPORTING
      iv_node_key    = /scmtms/if_tor_c=>sc_node-root
      it_key         = lt_key_root_tor
      iv_association = /scmtms/if_tor_c=>sc_association-root-attachmentfolder
    IMPORTING
      eo_message     = lo_message
      et_key_link    = DATA(lt_link_attach)
      et_target_key  = DATA(lt_target_key_attach).

  /scmtms/cl_common_helper=>get_do_keys_4_rba( EXPORTING
                                              iv_host_bo_key = /scmtms/if_tor_c=>sc_bo_key
                                              iv_host_do_node_key = /scmtms/if_tor_c=>sc_node-attachmentfolder
                                              iv_do_assoc_key = /bobf/if_attachment_folder_c=>sc_association-root-document
                                              IMPORTING
                                              ev_assoc_key = DATA(lv_attach_assoc_key) ).


  CALL METHOD lo_srv_tor->retrieve_by_association
    EXPORTING
      iv_node_key    = /scmtms/if_tor_c=>sc_node-attachmentfolder
      it_key         = lt_target_key_attach
      iv_association = lv_attach_assoc_key
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_document
      et_key_link    = DATA(lt_link_folder)
      et_target_key  = DATA(lt_target_key_folder).

  /scmtms/cl_common_helper=>get_do_keys_4_rba( EXPORTING
                                              iv_host_bo_key = /scmtms/if_tor_c=>sc_bo_key
                                              iv_host_do_node_key = /scmtms/if_tor_c=>sc_node-attachmentfolder
                                              iv_do_node_key = /bobf/if_attachment_folder_c=>sc_node-document
                                              IMPORTING
                                              ev_node_key = DATA(lv_document_node_key) ).

  /scmtms/cl_common_helper=>get_do_keys_4_rba( EXPORTING
                                iv_host_bo_key = /scmtms/if_tor_c=>sc_bo_key
                                iv_host_do_node_key = /scmtms/if_tor_c=>sc_node-attachmentfolder
                                iv_do_node_key = /bobf/if_attachment_folder_c=>sc_node-file_content
                                iv_do_assoc_key = /bobf/if_attachment_folder_c=>sc_association-document-file_content
                                IMPORTING
                                ev_node_key = DATA(lv_content_node_key)
                                ev_assoc_key = DATA(lv_content_assoc_key) ).


  CALL METHOD lo_srv_tor->retrieve_by_association
    EXPORTING
      iv_node_key    = lv_document_node_key
      it_key         = lt_target_key_folder
      iv_association = lv_content_assoc_key
      iv_fill_data   = abap_true
    IMPORTING
      et_data        = lt_file.

  IF lt_file IS NOT INITIAL AND lt_document IS NOT INITIAL.

*** Executes la conversion de xstring a base64
**CALL FUNCTION 'SSFC_BASE64_ENCODE'
**  EXPORTING
**    bindata = lt_file[ 1 ]-content
**  IMPORTING
**    b64data = lv_file
**  EXCEPTIONS
**    OTHERS = 1. " Over simplifying exception handling

    TRY.
        lo_sgt_out-service_req_doc_mrqs-document-take_out = lt_trq_zrig[ 1 ]-service_request.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
    TRY.
        lo_sgt_out-service_req_doc_mrqs-document-take_out_item = lt_item_trq[ 1 ]-zser_req_item_num.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
*  lo_sgt_out-service_req_doc_mrqs-document-shipment_document =

    IF ls_item_tor-base_btd_tco = 73.
      lo_sgt_out-service_req_doc_mrqs-document-outbound_delivery = ls_item_tor-base_btd_id.
    ENDIF.
    TRY.
        lo_sgt_out-service_req_doc_mrqs-document-document_type = lt_document[ 1 ]-attachment_type.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
    TRY.
        lo_sgt_out-service_req_doc_mrqs-document-document_name = lt_document[ 1 ]-description.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
    TRY.
        lo_sgt_out-service_req_doc_mrqs-document-file =  lt_file[ 1 ]-content. "lv_file
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

      IF lo_fault IS NOT BOUND AND lt_return IS INITIAL.
        COMMIT WORK.
      ELSE.
        e_message = lt_return-service_req_doc_mrsp-result-response_status && lt_return-service_req_doc_mrsp-result-response_desc.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFUNCTION.
