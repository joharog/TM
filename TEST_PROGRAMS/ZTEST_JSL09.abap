*&---------------------------------------------------------------------*
*& Report ZTEST_JSL9
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl9.
DATA: lo_srv_tor      TYPE REF TO /bobf/if_tra_service_manager,
      lt_mod_e        TYPE /bobf/t_frw_modification,
      ls_mod_e        TYPE /bobf/s_frw_modification,
      lo_chg          TYPE REF TO /bobf/if_tra_change,
      lo_message_enh  TYPE REF TO /bobf/if_frw_message,
      lo_tra          TYPE REF TO /bobf/if_tra_transaction_mgr,
      lt_block        TYPE /scmtms/t_tor_block_k,
      lt_root         TYPE /scmtms/t_tor_root_k,
      lt_item         TYPE /scmtms/t_tor_item_tr_k,
      lt_exec_tmp     TYPE /scmtms/t_tor_exec_k,
      lt_execution    TYPE /scmtms/t_tor_exec_k,
      lt_attachment   TYPE /bobf/t_atf_root_k,
      lt_document     TYPE /bobf/t_atf_document_k,
      lt_file         TYPE /bobf/t_atf_file_content_k,
      lv_rejected     TYPE abap_bool,
      lt_rej_bo_key   TYPE /bobf/t_frw_key2,
      lt_key2         TYPE /bobf/t_frw_key2,
      lt_key_root     TYPE /bobf/t_frw_key,
      lt_key_item     TYPE /bobf/t_frw_key,
      ls_key_block    TYPE /bobf/conf_key,
      lt_key_attach   TYPE /bobf/t_frw_key_link,
      lt_data         TYPE REF TO data,
      ls_data         TYPE REF TO data,
      lt_selpar       TYPE /bobf/t_frw_query_selparam,
      ls_selpar       TYPE /bobf/s_frw_query_selparam,
      lv_run          TYPE c,
      io_read         TYPE REF TO /bobf/if_frw_read,
      lr_action_param TYPE REF TO /scmtms/s_tor_a_item_delete.

FIELD-SYMBOLS <chg_block> TYPE /scmtms/s_tor_block_k.

APPEND VALUE #( key = '0050568C06951EDE878592233769C1C3' ) TO lt_key_root.

lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).

CALL METHOD lo_srv_tor->retrieve
  EXPORTING
    iv_node_key = /scmtms/if_tor_c=>sc_node-root
    it_key      = lt_key_root
  IMPORTING
    eo_message  = lo_message_enh
    et_data     = lt_root.

CALL METHOD lo_srv_tor->retrieve_by_association
  EXPORTING
    iv_node_key    = /scmtms/if_tor_c=>sc_node-root
    it_key         = lt_key_root
    iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr
    iv_fill_data   = abap_true
  IMPORTING
    eo_message     = lo_message_enh
    et_data        = lt_item.

TRY.
    DATA(ls_item) = lt_item[ item_type = 'PRD' ].
    APPEND VALUE #( key = ls_item-key ) TO lt_key_item.
  CATCH cx_sy_itab_line_not_found.
ENDTRY.
BREAK t20703.

CREATE DATA lr_action_param.

lr_action_param->unassign_with_pln = abap_true.
lr_action_param->consider_mult_itm_childs = abap_true.
lr_action_param->dlv_failed_strat = 0.

CALL METHOD lo_srv_tor->do_action(
  EXPORTING
    iv_act_key    = /scmtms/if_tor_c=>sc_action-item_tr-delete_cargo_item
    it_key        = lt_key_item
    is_parameters = lr_action_param
  IMPORTING
    eo_change     = lo_chg
    eo_message    = lo_message_enh ).


BREAK t20703.

lo_message_enh->get_messages(
    IMPORTING
      et_message              = DATA(lt_message) ).

LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<lfs_message>).
  DATA(message) = <lfs_message>-message->get_text( ).
ENDLOOP.

DATA(lr_tra_mgr) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

CALL METHOD lr_tra_mgr->save
  EXPORTING
    iv_transaction_pattern = /bobf/if_tra_c=>gc_tp_save_and_continue
  IMPORTING
    eo_change              = lo_chg
    eo_message             = lo_message_enh.


lo_message_enh->get_messages(
  IMPORTING
    et_message              = DATA(lt_message2) ).

LOOP AT lt_message2 ASSIGNING FIELD-SYMBOL(<lfs_message2>).
  DATA(message2) = <lfs_message2>-message->get_text( ).
ENDLOOP.


BREAK t20703.
