*&---------------------------------------------------------------------*
*& Report ZTEST_JSL11
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl11.

DATA: lo_srv_trq      TYPE REF TO /bobf/if_tra_service_manager,
      lt_key_root     TYPE /bobf/t_frw_key,
      lt_otr_root     TYPE /scmtms/t_trq_root_k,
      lt_dtr_root     TYPE /scmtms/t_trq_root_k,
      lt_selpar       TYPE /bobf/t_frw_query_selparam,
      ls_selpar       TYPE /bobf/s_frw_query_selparam,
      lt_root_trq     TYPE /scmtms/t_trq_root_k,
      lt_root_trq_key TYPE /bobf/t_frw_key.

lo_srv_trq = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_trq_c=>sc_bo_key ).


APPEND VALUE #( key = '0050568C06951EDE949737BA5E83E1C3' ) TO lt_key_root.

CALL METHOD lo_srv_trq->retrieve
  EXPORTING
    iv_node_key  = /scmtms/if_trq_c=>sc_node-root
    it_key       = lt_key_root
    iv_fill_data = abap_true
  IMPORTING
    et_data      = lt_dtr_root.

APPEND VALUE #( sign           = 'I'
                      option         = 'EQ'
                      low            = '35010709'
                      attribute_name = /scmtms/if_trq_c=>sc_query_attribute-root-root_elements-base_btd_id )  TO lt_selpar.

*APPEND VALUE #( sign           = 'I'
*                      option         = 'EQ'
*                      low            = '02'
*                      attribute_name = /scmtms/if_trq_c=>sc_query_attribute-root-root_elements-trq_cat ) TO lt_selpar.
*
*APPEND VALUE #( sign           = 'I'
*                    option         = 'EQ'
*                    low            = '73'
*                    attribute_name = /scmtms/if_trq_c=>sc_query_attribute-root-root_elements-base_btd_tco ) TO lt_selpar.

"obtenemos la FWO de OD
TRY.
    lo_srv_trq->query(
      EXPORTING
        iv_query_key            = /scmtms/if_trq_c=>sc_query-root-root_elements
        it_selection_parameters = lt_selpar
        iv_fill_data            = abap_true
      IMPORTING
"        eo_message              = lo_message
        et_data                 = lt_root_trq
        et_key                  = lt_root_trq_key ).
  CATCH /bobf/cx_frw INTO DATA(lx_frw_trq).
ENDTRY.

CALL METHOD lo_srv_trq->retrieve_by_association
  EXPORTING
    iv_node_key    = /scmtms/if_trq_c=>sc_node-root
    it_key         = lt_root_trq_key
    iv_association = /scmtms/if_trq_c=>sc_association-root-trq_otr_root
    iv_fill_data   = abap_true
  IMPORTING
    et_data        = lt_otr_root.



BREAK t20703.
