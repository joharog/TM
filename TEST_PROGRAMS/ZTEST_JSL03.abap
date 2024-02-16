*&---------------------------------------------------------------------*
*& Report ZTEST_JSL2
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl3.

FIELD-SYMBOLS: <ls_root> TYPE /scmtms/s_tor_root_k.

DATA: lo_srv_tor    TYPE REF TO /bobf/if_tra_service_manager,
      lt_mod        TYPE /bobf/t_frw_modification,
      ls_mod        TYPE /bobf/s_frw_modification,
      lo_chg        TYPE REF TO /bobf/if_tra_change,
      lo_message    TYPE REF TO /bobf/if_frw_message,
      "lo_msg_all    TYPE REF TO /bobf/if_frw_message,
      lo_tra        TYPE REF TO /bobf/if_tra_transaction_mgr,
      lv_rejected   TYPE abap_bool,
      lt_rej_bo_key TYPE /bobf/t_frw_key2,
      ls_selpar     TYPE /bobf/s_frw_query_selparam,
      lt_selpar     TYPE /bobf/t_frw_query_selparam,
      lt_tor_root   TYPE /scmtms/t_tor_root_k,
      lt_block      TYPE /scmtms/t_tor_block_k,
      lt_resh_key_t TYPE /bobf/t_frw_key,
      lt_block_key  TYPE /bobf/t_frw_key,
      lt_data       TYPE REF TO data.

FIELD-SYMBOLS <fs_block> TYPE INDEX TABLE.
FIELD-SYMBOLS <chg_block> TYPE /scmtms/s_tor_block_k.

* Get instance of service manager for TOR
lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).


* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '6100000162'.
APPEND ls_selpar TO lt_selpar.
* find a TOR instance to be deleted

lo_srv_tor->query(
EXPORTING
iv_query_key = /scmtms/if_tor_c=>sc_query-root-planning_attributes
it_selection_parameters = lt_selpar
iv_fill_data = abap_true
IMPORTING
et_data    = lt_tor_root
et_key     = lt_resh_key_t ).

"READ TABLE lt_tor_root ASSIGNING <ls_root> INDEX 1.
* Save transaction to get data persisted (NO COMMIT WORK!)
lo_tra = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

lo_srv_tor->retrieve_by_association(
  EXPORTING
    iv_node_key = /scmtms/if_tor_c=>sc_node-root
    it_key  = lt_resh_key_t
    iv_association = /scmtms/if_tor_c=>sc_association-root-block
    iv_fill_data = abap_true
    IMPORTING
      et_target_key =  lt_block_key
      eo_message    = lo_message
      et_data       = lt_block  ).

READ TABLE lt_block INTO DATA(ls_block) WITH KEY block_rc = 'Z1' blk_invo = abap_true.

"realizamos la modificacion del nodo BLOCK ahora
ls_mod-node = /scmtms/if_tor_c=>sc_node-block.
ls_mod-key = lo_srv_tor->get_new_key( ).    "para crear
*ls_mod-key = ls_block-key.                     "para borrar
ls_mod-source_key = lt_resh_key_t[ 1 ]-key.
ls_mod-association = /scmtms/if_tor_c=>sc_association-root-block. "
ls_mod-source_node = /scmtms/if_tor_c=>sc_node-root.
*ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_delete.       "para borrar
ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_create.     " para crear

CREATE DATA ls_mod-data TYPE /scmtms/s_tor_block_k.
ASSIGN ls_mod-data->* TO <chg_block>.

<chg_block>-block_rc = 'Z1'.        "para crear
<chg_block>-blk_invo = abap_true.   "para crear

APPEND ls_mod TO lt_mod.

lo_srv_tor->modify(
EXPORTING
it_modification = lt_mod
IMPORTING
eo_change = lo_chg
eo_message = lo_message ).

lo_tra->save(
IMPORTING
ev_rejected = lv_rejected
eo_change = lo_chg
eo_message = lo_message
et_rejecting_bo_key = lt_rej_bo_key ).
