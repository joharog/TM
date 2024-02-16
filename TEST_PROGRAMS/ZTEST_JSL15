*&---------------------------------------------------------------------*
*& Report ZTEST_JSL15
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl15.


FIELD-SYMBOLS: <ls_root> TYPE /scmtms/s_tor_root_k,
               <ls_item> TYPE /scmtms/s_tor_item_tr_k.

DATA: lo_srv_tor      TYPE REF TO /bobf/if_tra_service_manager,
      lt_mod          TYPE /bobf/t_frw_modification,
      ls_mod          TYPE /bobf/s_frw_modification,
      lo_chg          TYPE REF TO /bobf/if_tra_change,
      lo_message      TYPE REF TO /bobf/if_frw_message,
      lo_msg_all      TYPE REF TO /bobf/if_frw_message,
      lo_tra          TYPE REF TO /bobf/if_tra_transaction_mgr,
      lv_rejected     TYPE abap_bool,
      lt_rej_bo_key   TYPE /bobf/t_frw_key2,
      ls_selpar       TYPE /bobf/s_frw_query_selparam,
      lt_selpar       TYPE /bobf/t_frw_query_selparam,
      lt_tor_root     TYPE /scmtms/t_tor_root_k,
      lt_tor_root_k   TYPE /scmtms/t_tor_root_k,
      lt_tor_rank     TYPE /scmtms/t_tor_rl_k,
      lt_key_tor_root TYPE /bobf/t_frw_key.

* Get instance of service manager for TOR
lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).



APPEND VALUE #( key = '0050568C06951EDEB1D0A968ED7B41C3' ) TO lt_key_tor_root.

lo_srv_tor->retrieve(
EXPORTING
iv_node_key = /scmtms/if_tor_c=>sc_node-root
it_key = lt_key_tor_root
iv_fill_data = abap_true
IMPORTING
*eo_message = lo_message
et_data = lt_tor_root ).


BREAK-POINT.

REFRESH lt_key_tor_root.
APPEND VALUE #( key = '0050568C06951EDEB1D0A968ED7B41CX' ) TO lt_key_tor_root.

lo_srv_tor->retrieve(
EXPORTING
iv_node_key = /scmtms/if_tor_c=>sc_node-root
it_key = lt_key_tor_root
iv_fill_data = abap_true
IMPORTING
*eo_message = lo_message
et_data = lt_tor_root ).


BREAK-POINT.
