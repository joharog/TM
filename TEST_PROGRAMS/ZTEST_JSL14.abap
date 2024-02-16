*&---------------------------------------------------------------------*
*& Report ZTEST_JSL15
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl15.


FIELD-SYMBOLS: <ls_root> TYPE /scmtms/s_tor_root_k,
               <ls_item> TYPE /scmtms/s_tor_item_tr_k.

DATA: lo_srv_tor    TYPE REF TO /bobf/if_tra_service_manager,
      lt_mod        TYPE /bobf/t_frw_modification,
      ls_mod        TYPE /bobf/s_frw_modification,
      lo_chg        TYPE REF TO /bobf/if_tra_change,
      lo_message    TYPE REF TO /bobf/if_frw_message,
      lo_msg_all    TYPE REF TO /bobf/if_frw_message,
      lo_tra        TYPE REF TO /bobf/if_tra_transaction_mgr,
      lv_rejected   TYPE abap_bool,
      lt_rej_bo_key TYPE /bobf/t_frw_key2,
      ls_selpar     TYPE /bobf/s_frw_query_selparam,
      lt_selpar     TYPE /bobf/t_frw_query_selparam,
      lt_tor_root   TYPE /scmtms/t_tor_root_k,
      lt_tor_root_k TYPE /scmtms/t_tor_root_k,
      lt_tor_rank   TYPE /scmtms/t_tor_rl_k.

* Get instance of service manager for TOR
lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004759'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004760'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004761'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004762'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004763'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004764'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004765'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004766'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004767'.
APPEND ls_selpar TO lt_selpar.

* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100004768'.
APPEND ls_selpar TO lt_selpar.


lo_srv_tor->query(
EXPORTING
iv_query_key = /scmtms/if_tor_c=>sc_query-root-planning_attributes
it_selection_parameters = lt_selpar
iv_fill_data = abap_true
IMPORTING
*eo_message = lo_message
et_data = lt_tor_root
et_key = DATA(lt_tor_key) ).


lo_srv_tor->retrieve_by_association(
EXPORTING
iv_node_key = /scmtms/if_tor_c=>sc_node-root
iv_association = /scmtms/if_tor_c=>sc_association-root-rankinglist
it_key = lt_tor_key
iv_fill_data = abap_true
iv_edit_mode   = /bobf/if_conf_c=>sc_edit_read_only
IMPORTING
*eo_message = lo_message
et_data = lt_tor_rank ).

****CALL METHOD /scmtms/cl_pln_bo_data=>get_tor_data
****  EXPORTING
****    it_key           = lt_tor_key
****    io_message       = lo_message
****    iv_no_param_init = abap_true
****  CHANGING
****    ct_tor_root      = lt_tor_root_k
****    ct_tor_rl        = lt_tor_rank.

BREAK-POINT.
