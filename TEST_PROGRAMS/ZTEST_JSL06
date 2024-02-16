*&---------------------------------------------------------------------*
*& Report ZTEST_ROD6
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl6.

DATA lt_trq_root     TYPE /scmtms/t_trq_root_k.
DATA lt_trq_item     TYPE /scmtms/t_trq_item_k.
DATA lr_trq_root     TYPE REF TO /scmtms/s_trq_root_k.
DATA lr_trq_item     TYPE REF TO /scmtms/s_trq_item_k.
DATA lt_modify       TYPE /bobf/t_frw_modification.
DATA ls_modify       TYPE /bobf/s_frw_modification.
FIELD-SYMBOLS <fs_root>       TYPE /scmtms/s_trq_root_k.
FIELD-SYMBOLS <fs_item>       TYPE /scmtms/s_trq_item_k.


* Get BO Service Manager - /SCMTMS/TRQ Business Object
DATA(lr_trq_srvmgr) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( iv_bo_key = /scmtms/if_trq_c=>sc_bo_key ).


***************************** Create ***********************************
*&---> Create Root Node Instance

* Fill Modification Structure
ls_modify-node        = /scmtms/if_trq_c=>sc_node-root.
ls_modify-key         = lr_trq_srvmgr->get_new_key( ).
ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
CREATE DATA ls_modify-data TYPE /scmtms/s_trq_root_k.

DATA(lv_root_key) = ls_modify-key.

ASSIGN ls_modify-data->* TO <fs_root>.
<fs_root>-trq_cat = '03'.
<fs_root>-qua_pcs2_uni = 'TON'.
<fs_root>-TRQ_TYPE = 'FWO'.

APPEND ls_modify TO lt_modify.


*Fill Modification Structure
CLEAR ls_modify.
ls_modify-node        = /scmtms/if_trq_c=>sc_node-item.
ls_modify-key         = lr_trq_srvmgr->get_new_key( ).
ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
ls_modify-source_node = /scmtms/if_trq_c=>sc_node-root.
ls_modify-association = /scmtms/if_trq_c=>sc_association-root-item.
ls_modify-source_key  = lv_root_key.
ls_modify-root_key    = lv_root_key.
ls_modify-data        = lr_trq_item.
CREATE DATA ls_modify-data TYPE /scmtms/s_trq_item_k.

ASSIGN ls_modify-data->* TO <fs_item>.
<fs_item>-item_cat   = 'PRD'. " Product
<fs_item>-item_descr = 'demo'.
APPEND ls_modify TO lt_modify.

IF lt_modify IS NOT INITIAL.
  CALL METHOD lr_trq_srvmgr->modify
    EXPORTING
      it_modification = lt_modify    " Changes
    IMPORTING
      eo_change       = DATA(lo_change)    " Interface of Change Object
      eo_message      = DATA(lo_message).    " Interface of Message Object
ENDIF.


*Save
IF lo_change IS BOUND AND lo_change->has_failed_changes( ) EQ abap_false.
  DATA(lr_tra_mgr) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).


  CALL METHOD lr_tra_mgr->save
*    EXPORTING
*      iv_transaction_pattern = /bobf/if_tra_c=>gc_tp_save_and_continue
    IMPORTING
*     ev_rejected            = DATA(lv_rejected)
*     eo_change  = lo_change
      eo_message = lo_message.

  lo_message->get_messages(
    IMPORTING
      et_message              = DATA(lt_message) ).


  LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<lfs_message>).
    DATA(message) = <lfs_message>-message->get_text( ).
*            EXIT.
  ENDLOOP.
ENDIF.
