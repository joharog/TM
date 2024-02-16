*&---------------------------------------------------------------------*
*& Report ZTEST_JSL10
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl10.

DATA: lo_srv_dri    TYPE REF TO /bobf/if_tra_service_manager,
      lo_srv_tor    TYPE REF TO /bobf/if_tra_service_manager,
      lo_tra        TYPE REF TO /bobf/if_tra_transaction_mgr,
      lt_driver_key TYPE /bobf/t_frw_key,
      ls_driver_key TYPE /bobf/s_frw_key,
      lt_driver     TYPE /scmtms/t_lres_q_result,
      ls_selpar     TYPE /bobf/s_frw_query_selparam,
      lt_selpar     TYPE /bobf/t_frw_query_selparam,
      lt_mod        TYPE /bobf/t_frw_modification,
      ls_mod        TYPE /bobf/s_frw_modification,
      lo_change     TYPE REF TO /bobf/if_tra_change,
      lo_message    TYPE REF TO /bobf/if_frw_message.

FIELD-SYMBOLS: <fs_item_tr>      TYPE /scmtms/s_tor_item_tr_k.

lo_srv_dri = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_res_labour_c=>sc_bo_key ).
lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).


***Fijamos los parametros del query
**ls_selpar-attribute_name = /scmtms/if_res_labour_c=>sc_query_attribute-root-qu_by_attributes_all-labourres_id.
**ls_selpar-option = 'EQ'.
**ls_selpar-sign = 'I'.
**ls_selpar-low = '0000000038'.
**APPEND ls_selpar TO lt_selpar.
**
**"Hacemos el query para obtener el key del conductor
**lo_srv_dri->query(
**EXPORTING
**iv_query_key = /scmtms/if_res_labour_c=>sc_query-root-qu_by_attributes_all
**it_selection_parameters = lt_selpar
**iv_fill_data = abap_true
**IMPORTING
**et_key     = lt_driver_key
**et_data    = lt_driver ).
**
**IF lt_driver_key  IS NOT INITIAL.
**  READ TABLE lt_driver_key INTO ls_driver_key INDEX 1.
**ENDIF.


CREATE DATA ls_mod-data TYPE /scmtms/s_tor_item_tr_k.
ASSIGN ls_mod-data->* TO <fs_item_tr>.

"aqui solo consideramos creacion no actualizacion de los conductores
ls_mod-node = /scmtms/if_tor_c=>sc_node-item_tr.
ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_create.
ls_mod-key = lo_srv_tor->get_new_key( ).
ls_mod-root_key = '0050568C06951EDE8C95654AE6DC41C3'.
ls_mod-source_key = '0050568C06951EDE8C95654AE6DC41C3'.
ls_mod-source_node = /scmtms/if_tor_c=>sc_node-root.
ls_mod-association = /scmtms/if_tor_c=>sc_association-root-item_tr.

"<fs_item_tr>-res_key = lt_driver_key[ 1 ]-key.
<fs_item_tr>-item_cat = 'DRI'.
<fs_item_tr>-item_descr = 'PRUEBA DE DRIVER'.
<fs_item_tr>-res_adhoc = abap_true.

"APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-res_key TO ls_mod-changed_fields.
APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-item_cat TO ls_mod-changed_fields.
APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-item_descr TO ls_mod-changed_fields.
APPEND /scmtms/if_tor_c=>sc_node_attribute-item_tr-res_adhoc TO ls_mod-changed_fields.

APPEND ls_mod TO lt_mod.


lo_srv_tor->modify(
EXPORTING
it_modification = lt_mod
IMPORTING
eo_change = lo_change
eo_message = lo_message ).

* Save transaction to get data persisted (NO COMMIT WORK!)
lo_tra = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

"guardamos los cambios
lo_tra->save(
IMPORTING
eo_change = lo_change
eo_message = lo_message ).
