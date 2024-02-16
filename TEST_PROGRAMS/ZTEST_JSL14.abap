*&---------------------------------------------------------------------*
*& Report ZTEST_JSL13
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl13.

DATA lt_key TYPE /bobf/t_frw_key.
DATA ls_parameters     TYPE /scmtms/s_trq_a_cancel.
DATA lo_change         TYPE REF TO /bobf/if_tra_change.
DATA lo_message        TYPE REF TO  /bobf/if_frw_message.
DATA lr_s_parameters   TYPE REF TO /scmtms/s_trq_a_cancel.
DATA lt_failed_key     TYPE /bobf/t_frw_key.
DATA: lt_failed_act_key TYPE /bobf/t_frw_key,
      lt_selpar         TYPE /bobf/t_frw_query_selparam,
      ls_selpar         TYPE /bobf/s_frw_query_selparam,
      lt_trq_otr        TYPE /SCMTMS/T_trq_ROOT_K,
      ls_trq_dtr        TYPE /SCMTMS/S_trq_ROOT_K,
      lt_trq_dtr        TYPE /SCMTMS/T_trq_ROOT_K.

DATA(lr_trq_srvmgr) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_trq_c=>sc_bo_key ).

DATA(lo_tra) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).
* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_trq_c=>sc_query_attribute-root-root_elements-trq_id.
ls_selpar-sign = 'I'.
ls_selpar-option = 'EQ'.
ls_selpar-low = '00000000003100001755'.
APPEND ls_selpar TO lt_selpar.
* find a TOR instance to be deleted

lr_trq_srvmgr->query(
  EXPORTING
    iv_query_key            = /scmtms/if_trq_c=>sc_query-root-root_elements
*        it_filter_key           = /scmtms/if_trq_c=>sc_query-root
    it_selection_parameters = lt_selpar
*        is_query_options        =
    iv_fill_data            = abap_true
*        it_requested_attributes =
  IMPORTING
    eo_message              = lo_message
*        es_query_info           =
    et_data                 = lt_trq_otr
    et_key                  = DATA(lt_trq_otr_key) ).



CALL METHOD lr_trq_srvmgr->retrieve_by_association
  EXPORTING
    iv_node_key    = /scmtms/if_trq_c=>sc_node-root
    it_key         = lt_trq_otr_key
    iv_association = /scmtms/if_trq_c=>sc_association-root-trq_dtr_root
    iv_fill_data   = abap_true
  IMPORTING
    et_data        = lt_trq_dtr.
BREAK-POINT.

clear ls_trq_dtr.
TRY.
    ls_trq_dtr = lt_trq_dtr[ trq_type = 'YZ02' ].
  CATCH cx_sy_itab_line_not_found.
ENDTRY.

TRY.
    ls_trq_dtr = lt_trq_dtr[ trq_type = 'YZ01' ].
  CATCH cx_sy_itab_line_not_found .
ENDTRY.



BREAK-POINT.
