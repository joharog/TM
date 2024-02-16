*&---------------------------------------------------------------------*
*& Report ZTEST_JSL2
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl4.

FIELD-SYMBOLS: <ls_root> TYPE /scmtms/s_tor_root_k.

DATA: lo_srv_tor     TYPE REF TO /bobf/if_tra_service_manager,
      lt_mod         TYPE /bobf/t_frw_modification,
      ls_mod         TYPE /bobf/s_frw_modification,
      lo_chg         TYPE REF TO /bobf/if_tra_change,
      lo_message     TYPE REF TO /bobf/if_frw_message,
      lo_msg_all     TYPE REF TO /bobf/if_frw_message,
      lo_tra         TYPE REF TO /bobf/if_tra_transaction_mgr,
      lv_rejected    TYPE abap_bool,
      lt_rej_bo_key  TYPE /bobf/t_frw_key2,
      ls_selpar      TYPE /bobf/s_frw_query_selparam,
      lt_selpar      TYPE /bobf/t_frw_query_selparam,
      lt_tor_root    TYPE /scmtms/t_tor_root_k,
      lt_block       TYPE /scmtms/t_tor_root_k,
      lt_resh_key_t  TYPE /bobf/t_frw_key,
      lt_block_key   TYPE /bobf/t_frw_key,
      lt_attach_root TYPE /bobf/t_atf_root_k,
      lt_attach_fol  TYPE /bobf/t_atf_document_k,
      lt_data        TYPE REF TO data,
      lt_document    TYPE /bobf/t_atf_document_k,
      lt_file        TYPE /bobf/t_atf_file_content_k.

FIELD-SYMBOLS <fs_block> TYPE INDEX TABLE.
FIELD-SYMBOLS <chg_block> TYPE /scmtms/s_tor_block_k.
* Get instance of service manager for TOR
lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).


* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100000301'.
APPEND ls_selpar TO lt_selpar.
* find a TOR instance to be deleted

lo_srv_tor->query(
EXPORTING
iv_query_key = /scmtms/if_tor_c=>sc_query-root-root_elements
it_selection_parameters = lt_selpar
iv_fill_data = abap_true
IMPORTING
et_data    = lt_tor_root
et_key     = lt_resh_key_t ).


*lo_srv_tor->retrieve_by_association(
*  EXPORTING
*    iv_node_key = /scmtms/if_tor_c=>sc_node-root
*    it_key  = lt_resh_key_t
*    iv_association = /scmtms/if_tor_c=>sc_association-root-attachmentfolder
*    iv_fill_data = abap_true
*    IMPORTING
*      et_key_link  = DATA(lt_key_link)
*      et_target_key = DATA(lt_target_key)
*      eo_message    = lo_message
*      et_data       = lt_attach_root ).

*/scmtms/cl_common_helper=>get_do_keys_4_rba( EXPORTING
*                                            iv_host_bo_key = /scmtms/if_tor_c=>sc_bo_key
*                                            iv_host_do_node_key = /scmtms/if_tor_c=>sc_node-attachmentfolder
*                                            iv_do_assoc_key = /bobf/if_attachment_folder_c=>sc_association-root-document_list
*                                            IMPORTING
*                                            ev_assoc_key = DATA(lv_attach_assoc_key) ).
*
*
*lo_srv_tor->retrieve_by_association( EXPORTING
*                                        iv_node_key = /scmtms/if_tor_c=>sc_node-attachmentfolder
*                                        it_key = lt_target_key
*                                        iv_association = lv_attach_assoc_key
*                                        iv_fill_data   = abap_true
*                                        IMPORTING
*                                        eo_message = lo_message
*                                        et_key_link = DATA(lt_link_txctext)
*                                        et_target_key = DATA(lt_txc_text_key)
*                                        et_data        = lt_attach_fol ).

CALL METHOD lo_srv_tor->retrieve_by_association
  EXPORTING
    iv_node_key    = /scmtms/if_tor_c=>sc_node-root
    it_key         = lt_resh_key_t
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

BREAK t20703.
