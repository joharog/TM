*&---------------------------------------------------------------------*
*& Report ZTEST_JSL8
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl8.

DATA: lo_srv_trq     TYPE REF TO /bobf/if_tra_service_manager,
      lo_srv_tor     TYPE REF TO /bobf/if_tra_service_manager,
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
      lt_tor_zrig    TYPE /tenr/t_tor_rig_direct_k,
      lt_trq_zrig    TYPE /tenr/t_trq_rig_direct_k,
      lt_data        TYPE REF TO data.

FIELD-SYMBOLS <fs_block> TYPE INDEX TABLE.
FIELD-SYMBOLS <chg_block> TYPE /scmtms/s_tor_block_k.
* Get instance of service manager for TOR
lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).
lo_srv_trq = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_trq_c=>sc_bo_key ).

DATA: lt_key_tor_root TYPE /bobf/t_frw_key,
      lt_key_trq_root TYPE /bobf/t_frw_key.


APPEND VALUE #( key = '0050568C06951EDE9484C585931C41C3' ) TO lt_key_tor_root.
APPEND VALUE #( key = '0050568C06951EDE9484C585931E81C3' ) TO lt_key_tor_root.
APPEND VALUE #( key = '0050568C06951EDE9484C585931EC1C3' ) TO lt_key_tor_root.
APPEND VALUE #( key = '0050568C06951EDE9484C585931F01C3' ) TO lt_key_tor_root.
APPEND VALUE #( key = '0050568C06951EDE9484CAC9C7E1E1C3' ) TO lt_key_tor_root.
APPEND VALUE #( key = '0050568C06951EDE9484CAC9C7E221C3' ) TO lt_key_tor_root.
APPEND VALUE #( key = '0050568C06951EDE94B1F5D31CB181C3' ) TO lt_key_tor_root.


lo_srv_tor->retrieve_by_association(
  EXPORTING
    iv_node_key = /scmtms/if_tor_c=>sc_node-root
    it_key  = lt_key_tor_root
    iv_association = /tenr/if_tor_c=>sc_association-root-zrig_direct
    iv_fill_data = abap_true
    IMPORTING
      et_data       = lt_tor_zrig
      eo_message    = lo_message ).


APPEND VALUE #( key = '0050568C06951EDE81B107454F56C1C3' ) TO lt_key_trq_root.

lo_srv_trq->retrieve_by_association(
  EXPORTING
    iv_node_key = /scmtms/if_trq_c=>sc_node-root
    it_key  = lt_key_trq_root
    iv_association = /tenr/if_trq_c=>sc_association-root-zrig_direct
    iv_fill_data = abap_true
    IMPORTING
      et_data       = lt_trq_zrig
      eo_message    = lo_message ).
