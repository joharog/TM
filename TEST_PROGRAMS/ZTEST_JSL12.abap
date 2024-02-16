*&---------------------------------------------------------------------*
*& Report ZTEST_JSL2
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl12.

FIELD-SYMBOLS: <ls_root> TYPE /scmtms/s_tor_root_k,
               <ls_item> TYPE /scmtms/s_tor_item_tr_k.

DATA: lo_srv_tor        TYPE REF TO /bobf/if_tra_service_manager,
      lt_mod            TYPE /bobf/t_frw_modification,
      ls_mod            TYPE /bobf/s_frw_modification,
      lo_chg            TYPE REF TO /bobf/if_tra_change,
      lo_message        TYPE REF TO /bobf/if_frw_message,
      lo_msg_all        TYPE REF TO /bobf/if_frw_message,
      lo_tra            TYPE REF TO /bobf/if_tra_transaction_mgr,
      lv_rejected       TYPE abap_bool,
      lt_rej_bo_key     TYPE /bobf/t_frw_key2,
      ls_selpar         TYPE /bobf/s_frw_query_selparam,
      lt_selpar         TYPE /bobf/t_frw_query_selparam,
      lt_tor_qdb        TYPE /scmtms/t_tor_root_k,
      lt_item_qdb       TYPE /scmtms/t_tor_item_tr_k,
      lt_keys_fu        TYPE /bobf/t_frw_key,
      lt_last_tendering TYPE /scmtms/t_tor_tend_k.
* Get instance of service manager for TOR
lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000004100008515'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000004100008516'.
APPEND ls_selpar TO lt_selpar.


lo_srv_tor->query(
EXPORTING
iv_query_key = /scmtms/if_tor_c=>sc_query-root-planning_attributes
it_selection_parameters = lt_selpar
iv_fill_data = abap_true
IMPORTING
*eo_message = lo_message
et_data = lt_tor_qdb
et_key = DATA(lt_tor_key) ).


LOOP AT lt_tor_key INTO DATA(ls_tor_key).
  refresh lt_keys_fu.
  APPEND VALUE #( key = ls_tor_key-key ) TO lt_keys_fu.

  lo_srv_tor->retrieve_by_association(
EXPORTING
iv_node_key = /scmtms/if_tor_c=>sc_node-root
it_key = lt_keys_fu
iv_association = /scmtms/if_tor_c=>sc_association-root-item_tr_fu_item
iv_fill_data = abap_true
IMPORTING
*eo_message = lo_message
et_data = lt_item_qdb
et_target_key = DATA(lt_item_key) ).

  LOOP AT lt_item_key INTO DATA(ls_item_key).

    CLEAR ls_mod.
*--- Update the new instance with a Status Complete ---*
    ls_mod-node = /scmtms/if_tor_c=>sc_node-root.
    ls_mod-key = ls_item_key-key.
    ls_mod-root_key = ls_tor_key-key.
    ls_mod-source_key = ls_tor_key-key.
    ls_mod-association = /scmtms/if_tor_c=>sc_association-root-item_tr.
    ls_mod-source_node = /scmtms/if_tor_c=>sc_node-root.
    ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_update.

    CREATE DATA ls_mod-data TYPE /scmtms/s_tor_item_tr_k.
    ASSIGN ls_mod-data->* TO <ls_item>.

    <ls_item>-upd_prop_indicator = 'N'.
    APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-upd_prop_indicator TO ls_mod-changed_fields.

    APPEND ls_mod TO lt_mod.

  ENDLOOP.

ENDLOOP.

lo_srv_tor->modify(
EXPORTING
it_modification = lt_mod
IMPORTING
eo_change = lo_chg
eo_message = lo_message ).

* Save transaction to get data persisted (NO COMMIT WORK!)
lo_tra = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).
* Call the SAVE method of the transaction manager
lo_tra->save(
IMPORTING
ev_rejected = lv_rejected
eo_change = lo_chg
eo_message = lo_message
et_rejecting_bo_key = lt_rej_bo_key ).

lo_message->get_messages(
    IMPORTING
      et_message              = DATA(lt_message) ).

LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<lfs_message>).
  DATA(e_message) = <lfs_message>-message->get_text( ).
  EXIT.
ENDLOOP.

BREAK-POINT.
