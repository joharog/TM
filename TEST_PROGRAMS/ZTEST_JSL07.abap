*&---------------------------------------------------------------------*
*& Report ZTEST_JSL7
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl7.

DATA: lo_srv_bp     TYPE REF TO /bobf/if_tra_service_manager,
      lt_driver_key TYPE /bobf/t_frw_key,
      ls_driver_key TYPE /bobf/s_frw_key,
      ls_selpar     TYPE /bobf/s_frw_query_selparam,
      lt_selpar     TYPE /bobf/t_frw_query_selparam,
      lv_bp         TYPE bu_partner VALUE '5',
      lt_data_bp    TYPE /bofu/t_bupa_root_k,
      lt_direcccion TYPE /bofu/t_bupa_adrinfo_k.

lo_srv_bp = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /bofu/if_bupa_constants=>sc_bo_key ). "

*Fijamos los parametros del query
ls_selpar-attribute_name = /bofu/if_bupa_constants=>sc_query_attribute-root-qu_by_names_and_key_wrds-partner.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = |{ lv_bp ALPHA = IN }|.
APPEND ls_selpar TO lt_selpar.

"Hacemos el query para obtener el key del conductor
lo_srv_bp->query(
EXPORTING
iv_query_key = /bofu/if_bupa_constants=>sc_query-root-qu_by_names_and_key_wrds
it_selection_parameters = lt_selpar
iv_fill_data = abap_true
IMPORTING
et_key     = lt_driver_key
et_data    = lt_data_bp ).

lo_srv_bp->retrieve_by_association(
EXPORTING
  iv_node_key =  /bofu/if_bupa_constants=>sc_node-addressinformation
  it_key = lt_driver_key
  iv_association = /bofu/if_bupa_constants=>sc_association-root-addressinformation
  iv_fill_data = abap_true
IMPORTING
  et_data = lt_direcccion ).

BREAK t20703.
