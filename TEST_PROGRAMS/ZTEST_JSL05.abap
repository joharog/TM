*&---------------------------------------------------------------------*
*& Report ZTEST_JSL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_rod.

*INICIO
******************************************************************************************************************************
*DATA lt_trq_root     TYPE /scmtms/t_trq_root_k.
*DATA lt_trq_item     TYPE /scmtms/t_trq_item_k.
*DATA lr_trq_root     TYPE REF TO /scmtms/s_trq_root_k.
*DATA lr_trq_item     TYPE REF TO /scmtms/s_trq_item_k.
*DATA lt_modify       TYPE /bobf/t_frw_modification.
*DATA ls_modify       TYPE /bobf/s_frw_modification.

*DATA mo_bo_conf  TYPE REF TO /bobf/if_frw_configuration.

*DATA lt_modify       TYPE /bobf/t_frw_modification.
*DATA ls_modify       TYPE /bobf/s_frw_modification.

"create object mo_bo_conf .

*      <ls_mod>-node  =      lo_driver->mo_bo_conf->query_node( iv_proxy_node_name = 'ROOT_LONG_TXT.CONTENT' ).

*
" DATA lo_driver   TYPE REF TO lcl_demo.
*DATA lt_mod      TYPE /bobf/t_frw_modification.
*    DATA lo_change   TYPE REF TO /bobf/if_tra_change.
*    DATA lo_message  TYPE REF TO /bobf/if_frw_message.
*    DATA lv_rejected TYPE boole_d.
DATA lx_bopf_ex  TYPE REF TO /bobf/cx_frw.
DATA lv_err_msg  TYPE string.
DATA: lt_fields_dtl  TYPE /bobf/t_frw_name.

"DATA lr_s_root     TYPE REF TO /bobf/s_demo_customer_hdr_k.
"DATA lr_s_txt      TYPE REF TO /bobf/s_demo_short_text_k.
DATA lr_s_txt_hdr  TYPE REF TO /bobf/s_txc_root_k.
DATA lr_s_txt_cont TYPE REF TO /bobf/s_txc_txt_k.
DATA lr_text_content     TYPE REF TO /bobf/s_txc_con_k.

*FIELD-SYMBOLS:
*  <ls_mod> LIKE LINE OF lt_mod.
*
DATA: lt_trq_root    TYPE /scmtms/t_trq_root_k,
      lt_trq_item    TYPE /scmtms/t_trq_item_k,
      lt_trq_itemDOC TYPE /scmtms/t_trq_docref_k,
      lr_trq_root    TYPE REF TO /scmtms/s_trq_root_k,
      lr_trq_item    TYPE REF TO /scmtms/s_trq_item_k,
      lr_trq_itemdoc TYPE REF TO /scmtms/s_trq_docref_k,
      lr_trq_textro  TYPE REF TO /bobf/s_txc_root_k,
      lr_trq_text    TYPE REF TO /bobf/s_txc_txt_k.

DATA lt_modify       TYPE /bobf/t_frw_modification.
DATA ls_modify       TYPE /bobf/s_frw_modification.

* Get BO Service Manager - /SCMTMS/TRQ Business Object
DATA(lr_trq_srvmgr) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager(
                                iv_bo_key = /scmtms/if_trq_c=>sc_bo_key ).

DATA(mo_bo_conf) = /bobf/cl_frw_factory=>get_configuration( /scmtms/if_trq_c=>sc_bo_key ).

DATA(lv_txt_key) = mo_bo_conf->get_content_key_mapping( iv_content_cat      = /bobf/if_conf_c=>sc_content_nod
                                                         iv_do_content_key   = /bobf/if_txc_c=>sc_node-text
                                                         iv_do_root_node_key = /scmtms/if_trq_c=>sc_node-textcollection ).


DATA(lv_txt_assoc) = mo_bo_conf->get_content_key_mapping( iv_content_cat      = /bobf/if_conf_c=>sc_content_ass
                                                          iv_do_content_key   = /bobf/if_txc_c=>sc_association-root-text
                                                          iv_do_root_node_key = /scmtms/if_trq_c=>sc_node-textcollection ).




***************************** Create ***********************************
*&---> Create Root Node Instance


* Fill Root Data
CREATE DATA lr_trq_root.
lr_trq_root->key            = lr_trq_srvmgr->get_new_key( ).
lr_trq_root->trq_cat        = '03'. " Forwarding Order
lr_trq_root->trq_type       = 'ZWPT'.
lr_trq_root->order_date     = '20230410'.
lr_trq_root->sales_org_id   = '50000031'.
lr_trq_root->src_loc_ID     = 'SPBAY'.
lr_trq_root->des_loc_id     = 'C001'.
lr_trq_root->sales_org_id   = '50000031'.
lr_trq_root->mot            = '01'.
lr_trq_root->del_lat_req    = '30042023'.
lr_trq_root->base_btd_id    = 'TEST 1'.
lr_trq_root->resp_person    = 'T20789'.
lr_trq_root->consignee_id   = '5'.
lr_trq_root->order_party_id = '5'.
lr_trq_root->qua_pcs2_val   = '1'.
* Fill Other Attributes
*


* Fill Modification Structure
ls_modify-node        = /scmtms/if_trq_c=>sc_node-root.
ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
ls_modify-data        = lr_trq_root.
ls_modify-key         = lr_trq_root->key.
INSERT ls_modify INTO TABLE lt_modify.

*
**&---> Create Item Node Instance ( Subnode )
** Fill Item Data
CREATE DATA lr_trq_item.
lr_trq_item->key        = lr_trq_srvmgr->get_new_key( ).
lr_trq_item->item_cat   = 'PRD'. " Product
lr_trq_item->item_descr = 'demo'.
lr_trq_item->item_type  = 'PRD'.
*lr_trq_item->length     = '10'.
*lr_trq_item->width      = '20'.
*lr_trq_item->height     = '30'.
*lr_trq_item->measuom    = 'FOT'.
lr_trq_item->mot        = '01'.
"lr_trq_item->product_id = 'PRO'.
* Fill Other Attributes
*

* Fill Modification Structure
CLEAR ls_modify.
ls_modify-node        = /scmtms/if_trq_c=>sc_node-item.
ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
ls_modify-source_node = /scmtms/if_trq_c=>sc_node-root.
ls_modify-association = /scmtms/if_trq_c=>sc_association-root-item.
ls_modify-source_key  = lr_trq_root->key.
ls_modify-root_key    = lr_trq_root->root_key.
ls_modify-data        = lr_trq_item.
ls_modify-key         = lr_trq_item->key.
INSERT ls_modify INTO TABLE lt_modify.

*&---> Create Item Node Instance ( Subnode )
*Fill Item Data
CREATE DATA lr_trq_itemdoc.
lr_trq_itemdoc->key        = lr_trq_srvmgr->get_new_key( ).
lr_trq_itemdoc->btd_id     = 'TEST 3'.
lr_trq_itemdoc->btd_tco    = '114'.
lr_trq_itemdoc->btditem_id = 'TEST 4'.
* Fill Other Attributes
*
* Fill Modification Structure
CLEAR ls_modify.
ls_modify-node        = /scmtms/if_trq_c=>sc_node-itemdocreference.
ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
ls_modify-source_node = /scmtms/if_trq_c=>sc_node-item.
ls_modify-association = /scmtms/if_trq_c=>sc_association-item-itemdocreference.
ls_modify-source_key  = lr_trq_item->key."lr_trq_root->key.
ls_modify-root_key    = lr_trq_root->root_key.
ls_modify-data        = lr_trq_itemdoc.
ls_modify-key         = lr_trq_itemdoc->key.
INSERT ls_modify INTO TABLE lt_modify.


**
CREATE DATA lr_s_txt_hdr.
lr_s_txt_hdr->key = /bobf/cl_frw_factory=>get_new_key( ).


" APPEND INITIAL LINE TO lt_mod ASSIGNING <ls_mod>.
ls_modify-node            = /scmtms/if_trq_c=>sc_node-textcollection.
ls_modify-change_mode     = /bobf/if_frw_c=>sc_modify_create.
ls_modify-source_node     = /scmtms/if_trq_c=>sc_node-root.
ls_modify-association     = /scmtms/if_trq_c=>sc_association-root-textcollection.
ls_modify-source_key      = lr_trq_root->key.
ls_modify-key             = lr_s_txt_hdr->key.
ls_modify-data            = lr_s_txt_hdr.

INSERT ls_modify INTO TABLE lt_modify.


*-- Details of Dependent Object TEXT Node
CREATE DATA  lr_trq_text.
lr_trq_text->key           = /bobf/cl_frw_factory=>get_new_key( ).
lr_trq_text->root_key      = lr_trq_root->key.
lr_trq_text->parent_key    = lr_trq_root->key.
lr_trq_text->user_id_ch    = sy-uname.
lr_trq_text->language_code = 'EN'.
lr_trq_text->text_type     = 'Z01'.
lr_trq_text->datetime_ch   = sy-datum.
lr_trq_text->datetime_cr   = sy-datum.

ls_modify-node         = lv_txt_key."/scmtms/if_trq_c=>sc_node-textcollection.  "TEXT Node Key
ls_modify-change_mode  = /bobf/if_frw_c=>sc_modify_create.
ls_modify-source_node  = /scmtms/if_trq_c=>sc_node-textcollection.
ls_modify-association  = lv_txt_assoc.  " ROOT -> TEXT Node Association
ls_modify-source_key   = lr_s_txt_hdr->key.
ls_modify-root_key     = lr_trq_root->root_key.
ls_modify-data         = lr_trq_text.
ls_modify-key          = lr_trq_text->key.
APPEND ls_modify TO lt_modify.

* Modify
IF lt_modify IS NOT INITIAL.
  CALL METHOD lr_trq_srvmgr->modify
    EXPORTING
      it_modification = lt_modify    " Changes
    IMPORTING
      eo_change       = DATA(lo_change)    " Interface of Change Object
      eo_message      = DATA(lo_message).    " Interface of Message Object
ENDIF.

DATA(lv_chaNGES) = lo_change->has_failed_changes( ).
*Save
IF lo_change IS BOUND AND lo_change->has_failed_changes( ) EQ abap_false.
  DATA(lr_tra_mgr) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).


  CALL METHOD lr_tra_mgr->save
    EXPORTING
      iv_transaction_pattern = /bobf/if_tra_c=>gc_tp_save_and_continue
    IMPORTING
      ev_rejected            = DATA(lv_rejected)
      eo_change              = lo_change
      eo_message             = lo_message.
  lo_message->get_messages(
    IMPORTING
      et_message              = DATA(lt_message) ).

  LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<lfs_message>).
    DATA(message) = <lfs_message>-message->get_text( ).
*            EXIT.
  ENDLOOP.

ENDIF.
BREAK-POINT.
****************************************************************************************************************************************
* FIN

*DATA mo_bo_conf  TYPE REF TO /bobf/if_frw_configuration.
*
*"create object mo_bo_conf .
*
**      <ls_mod>-node  =      lo_driver->mo_bo_conf->query_node( iv_proxy_node_name = 'ROOT_LONG_TXT.CONTENT' ).
*
**
*" DATA lo_driver   TYPE REF TO lcl_demo.
*DATA lt_mod      TYPE /bobf/t_frw_modification.
**    DATA lo_change   TYPE REF TO /bobf/if_tra_change.
**    DATA lo_message  TYPE REF TO /bobf/if_frw_message.
**    DATA lv_rejected TYPE boole_d.
*DATA lx_bopf_ex  TYPE REF TO /bobf/cx_frw.
*DATA lv_err_msg  TYPE string.
*
*
*"DATA lr_s_root     TYPE REF TO /bobf/s_demo_customer_hdr_k.
*"DATA lr_s_txt      TYPE REF TO /bobf/s_demo_short_text_k.
*DATA lr_s_txt_hdr  TYPE REF TO /bobf/s_txc_root_k.
*DATA lr_s_txt_cont TYPE REF TO /bobf/s_txc_txt_k.
*
*
**FIELD-SYMBOLS:
**  <ls_mod> LIKE LINE OF lt_mod.
**
*DATA: lt_trq_root    TYPE /scmtms/t_trq_root_k,
*      lt_trq_item    TYPE /scmtms/t_trq_item_k,
*      lt_trq_itemDOC TYPE /scmtms/t_trq_docref_k,
*      lr_trq_root    TYPE REF TO /scmtms/s_trq_root_k,
*      lr_trq_item    TYPE REF TO /scmtms/s_trq_item_k,
*      lr_trq_itemdoc TYPE REF TO /scmtms/s_trq_docref_k,
*      lr_trq_text    TYPE REF TO /bobf/s_txc_txt_k.
*
*DATA lt_modify       TYPE /bobf/t_frw_modification.
*DATA ls_modify       TYPE /bobf/s_frw_modification.
*
*
*START-OF-SELECTION.
** Get BO Service Manager - /SCMTMS/TRQ Business Object
*  DATA(lr_trq_srvmgr) = /bobf/cl_tra_serv_mgr_factory=>get_service_manager(
*                                  iv_bo_key = /scmtms/if_trq_c=>sc_bo_key ).
*
*mo_bo_conf = /bobf/cl_frw_factory=>get_configuration( /scmtms/if_trq_c=>sc_bo_key ).
*
****************************** Create ***********************************
**&---> Create Root Node Instance
*
*
** Fill Root Data
*  CREATE DATA lr_trq_root.
*  lr_trq_root->key          = lr_trq_srvmgr->get_new_key( ).
*  lr_trq_root->trq_cat        = '03'. " Forwarding Order
*  lr_trq_root->trq_type       = 'ZWPT'.
*  lr_trq_root->order_date     = '20.04.2024'.
*  lr_trq_root->sales_org_id   = '50000031'.
*  lr_trq_root->src_loc_id     = 'SPBAY'.
*  lr_trq_root->des_loc_id     = 'C001'.
*  lr_trq_root->del_lat_req    = '20230512170000'.
*  lr_trq_root->base_btd_id    = 'TEST 1'.
*  lr_trq_root->resp_person    = 'T20310'.
*  lr_trq_root->consignee_id   = '5'.
*  lr_trq_root->order_party_id = '5'.
*  lr_trq_root->qua_pcs_uni    = 'ZU1'.
*  lr_trq_root->qua_pcs_val    = '1'.
** Fill Other Attributes
**
*
*
** Fill Modification Structure
*  ls_modify-node        = /scmtms/if_trq_c=>sc_node-root.
*  ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
*  ls_modify-data        = lr_trq_root.
*  ls_modify-key         = lr_trq_root->key.
*  INSERT ls_modify INTO TABLE lt_modify.
*
**   CLEAR: ls_modify.
**
***&---> Create Item Node Instance ( Subnode )
*** Fill Item Data
**  CREATE DATA lr_trq_item.
**  lr_trq_item->key          = lr_trq_srvmgr->get_new_key( ).
**  lr_trq_item->item_cat     = 'PRD'. " Product
**  lr_trq_item->item_descr   = 'test 2'.
**  lr_trq_item->length       = '10'.
**  lr_trq_item->width        = '20'.
**  lr_trq_item->height       = '30'.
**  lr_trq_item->measuom      = 'FT'.
**  lr_trq_item->product_id   = 'PRO'.
**  lr_trq_item->item_descr   = 'test 2'.
**
** " lr_trq_item->qua_pcs2_val = '1'.
** " lr_trq_item->qua_pcs2_val = 'ZU1'.
*** Fill Other Attributes
***
**
**
*** Fill Modification Structure
**  CLEAR ls_modify.
**  ls_modify-node        = /scmtms/if_trq_c=>sc_node-item.
**  ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
**  ls_modify-source_node = /scmtms/if_trq_c=>sc_node-root.
**  ls_modify-association = /scmtms/if_trq_c=>sc_association-root-item.
**  ls_modify-source_key  = lr_trq_root->key.
**  ls_modify-root_key    = lr_trq_root->root_key.
**  ls_modify-data        = lr_trq_item.
**  ls_modify-key         = lr_trq_item->key.
**  INSERT ls_modify INTO TABLE lt_modify.
**
**   CLEAR: ls_modify.
***&---> Create Item Node Instance ( Subnode )
***Fill Item Data
**  CREATE DATA lr_trq_itemdoc.
**  lr_trq_itemdoc->key        = lr_trq_srvmgr->get_new_key( ).
**  lr_trq_itemdoc->btd_id     = 'TEST 3'.
**  lr_trq_itemdoc->btd_tco    = '114'.
**  lr_trq_itemdoc->btditem_id = 'TEST 4'.
*** Fill Other Attributes
***
*** Fill Modification Structure
**  CLEAR ls_modify.
**  ls_modify-node        = /scmtms/if_trq_c=>sc_node-itemdocreference.
**  ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
**  ls_modify-source_node = /scmtms/if_trq_c=>sc_node-root.
**  ls_modify-association = /scmtms/if_trq_c=>sc_association-item-itemdocreference.
**  ls_modify-source_key  = lr_trq_root->key.
**  ls_modify-root_key    = lr_trq_root->root_key.
**  ls_modify-data        = lr_trq_itemdoc.
**  ls_modify-key         = lr_trq_itemdoc->key.
**  INSERT ls_modify INTO TABLE lt_modify.
*
**   CLEAR: ls_modify.
**************************************************************************************
**
**  CREATE DATA lr_s_txt_hdr.
**  lr_s_txt_hdr->key = /bobf/cl_frw_factory=>get_new_key( ).
**
**
** " APPEND INITIAL LINE TO lt_mod ASSIGNING <ls_mod>.
**  ls_modify-node            = /scmtms/if_trq_c=>sc_node-textcollection.
**  ls_modify-change_mode     = /bobf/if_frw_c=>sc_modify_create.
**  ls_modify-source_node     = /scmtms/if_trq_c=>sc_node-root.
**  ls_modify-association     = /scmtms/if_trq_c=>sc_association-root-textcollection.
**  ls_modify-source_key      = lr_trq_root->key.
**  ls_modify-key             = lr_s_txt_hdr->key.
**  ls_modify-data            = lr_s_txt_hdr.
**
**  INSERT ls_modify INTO TABLE lt_modify.
**
**   CLEAR: ls_modify.
**  "Create the CONTENT node:
**  CREATE DATA lr_s_txt_cont.
**  lr_s_txt_cont->key          = /bobf/cl_frw_factory=>get_new_key( ).
**  lr_s_txt_cont->language_code     = sy-langu.
**  lr_s_txt_cont->text_type    = 'Z01'.
**  "lr_s_txt_cont->text_content = 'Demo customer created via BOPF API.'.
**
**
**  "APPEND INITIAL LINE TO lt_mod ASSIGNING <ls_mod>.
**  ls_modify-node        = mo_bo_conf->query_node( iv_proxy_node_name = 'TEXTCOLLECTION.ROOT_TXC' ).
**  ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
**  ls_modify-source_node = /scmtms/if_trq_c=>sc_node-textcollection.
**  ls_modify-source_key  = lr_s_txt_hdr->key.
**  ls_modify-key         = lr_s_txt_cont->key.
**  ls_modify-data        = lr_s_txt_cont.
**
**  ls_modify-association = mo_bo_conf->query_assoc( iv_node_key   = /scmtms/if_trq_c=>sc_node-textcollection
**                                                  iv_assoc_name = 'TEXT' ).
**
**  INSERT ls_modify INTO TABLE lt_modify.
***
**   CLEAR: ls_modify.
************************************************************************************
**CREATE DATA lr_trq_text.
**lr_trq_text->key        = lr_trq_srvmgr->get_new_key( ).
**lr_trq_text->text_type  = 'Z01'.
**
**
**ls_modify-node        = /scmtms/if_trq_c=>sc_node-textcollection.
**ls_modify-change_mode = /bobf/if_frw_c=>sc_modify_create.
**ls_modify-source_node = /scmtms/if_trq_c=>sc_node-root.
**ls_modify-association = /scmtms/if_trq_c=>sc_association-textcollection-to_root.
**ls_modify-source_key  = lr_trq_root->key.
**ls_modify-root_key    = lr_trq_root->root_key.
**ls_modify-data        = lr_trq_text.
**ls_modify-key         = lr_trq_text->key.
**INSERT ls_modify INTO TABLE lt_modify.
*
*  "ls_modify-node        = /scmtms/if_trq_c=>sc_node-textcollection.
** Modify
*  IF lt_modify IS NOT INITIAL.
*    CALL METHOD lr_trq_srvmgr->modify
*      EXPORTING
*        it_modification = lt_modify    " Changes
*      IMPORTING
*        eo_change       = DATA(lo_change)    " Interface of Change Object
*        eo_message      = DATA(lo_message).    " Interface of Message Object
*  ENDIF.
*
*
**Save
*  IF lo_change IS BOUND AND lo_change->has_failed_changes( ) EQ abap_false.
*    DATA(lr_tra_mgr) = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).
*
*
*    CALL METHOD lr_tra_mgr->save
*      EXPORTING
*        iv_transaction_pattern = /bobf/if_tra_c=>gc_tp_save_and_continue
*      IMPORTING
*        ev_rejected            = DATA(lv_rejected)
*        eo_change              = lo_change
*        eo_message             = lo_message.
*    lo_message->get_messages(
*      IMPORTING
*        et_message              = DATA(lt_message) ).
*
*
*    LOOP AT lt_message ASSIGNING FIELD-SYMBOL(<lfs_message>).
*      DATA(message) = <lfs_message>-message->get_text( ).
**            EXIT.
*    ENDLOOP.
*
*  ENDIF.
*
*  BREAK-POINT.
*
*CLASS lcl_demo DEFINITION CREATE PUBLIC.
*  PUBLIC SECTION.
*    METHODS:
*      create_customer IMPORTING iv_customer_id
*                                  TYPE /bobf/demo_customer_id.
*    ...
*ENDCLASS.
*
*CLASS lcl_demo IMPLEMENTATION.
*  METHOD create_customer.
*    "Method-Local Data Declarations:
*    DATA lo_driver   TYPE REF TO /bobf/if_tra_service_manager."lcl_demo.
*    DATA lt_mod      TYPE /bobf/t_frw_modification.
*    DATA lo_change   TYPE REF TO /bobf/if_tra_change.
*    DATA lo_message  TYPE REF TO /bobf/if_frw_message.
*    DATA lv_rejected TYPE boole_d.
*    DATA lx_bopf_ex  TYPE REF TO /bobf/cx_frw.
*    DATA lv_err_msg  TYPE string.
*
*
*
*    DATA lr_s_root     TYPE REF TO /bobf/s_demo_customer_hdr_k.
*    DATA lr_s_txt      TYPE REF TO /bobf/s_demo_short_text_k.
*    DATA lr_s_txt_hdr  TYPE REF TO /bobf/s_demo_longtext_hdr_k.
*    DATA lr_s_txt_cont TYPE REF TO /bobf/s_demo_longtext_item_k.
*
*
*
*    FIELD-SYMBOLS:
*      <ls_mod> LIKE LINE OF lt_mod.
*
*
*
*    "Use the BOPF API to create a new customer record:
*    TRY.
*        "Instantiate the driver class:
*        CREATE OBJECT lo_driver.
*
*
*
*        "Build the ROOT node:
*        CREATE DATA lr_s_root.
*        lr_s_root->key = /bobf/cl_frw_factory=>get_new_key( ).
*        lr_s_root->customer_id    = iv_customer_id.
*        lr_s_root->sales_org      = 'AMER'.
*        lr_s_root->cust_curr      = 'USD'.
*        lr_s_root->address_contry = 'US'.
*        lr_s_root->address        = '1234 Any Street'.
*
*
*
*        APPEND INITIAL LINE TO lt_mod ASSIGNING <ls_mod>.
*        <ls_mod>-node        = /bobf/if_demo_customer_c=>sc_node-root.
*        <ls_mod>-change_mode = /bobf/if_frw_c=>sc_modify_create.
*        <ls_mod>-key         = lr_s_root->key.
*        <ls_mod>-data        = lr_s_root.
*
*
*
*        "Build the ROOT_TEXT node:
*        CREATE DATA lr_s_txt.
*        lr_s_txt->key      = /bobf/cl_frw_factory=>get_new_key( ).
*        lr_s_txt->text     = 'Sample Customer Record'.
*        lr_s_txt->language = sy-langu.
*
*
*
*        APPEND INITIAL LINE TO lt_mod ASSIGNING <ls_mod>.
*        <ls_mod>-node        = /bobf/if_demo_customer_c=>sc_node-root_text.
*        <ls_mod>-change_mode = /bobf/if_frw_c=>sc_modify_create.
*        <ls_mod>-source_node = /bobf/if_demo_customer_c=>sc_node-root.
*        <ls_mod>-association =
*
*          /bobf/if_demo_customer_c=>sc_association-root-root_text.
*        <ls_mod>-source_key  = lr_s_root->key.
*        <ls_mod>-key         = lr_s_txt->key.
*        <ls_mod>-data        = lr_s_txt.
*
*
*
*        "Build the ROOT_LONG_TEXT node:
*        "If you look at the node type for this node, you'll notice that
*        "it's a "Delegated Node". In other words, it is defined in terms
*        "of the /BOBF/DEMO_TEXT_COLLECTION business object. The following
*        "code accounts for this indirection.
*        CREATE DATA lr_s_txt_hdr.
*        lr_s_txt_hdr->key = /bobf/cl_frw_factory=>get_new_key( ).
*
*
*
*        APPEND INITIAL LINE TO lt_mod ASSIGNING <ls_mod>.
*        <ls_mod>-node            = /bobf/if_demo_customer_c=>sc_node-root_long_text.
*        <ls_mod>-change_mode     = /bobf/if_frw_c=>sc_modify_create.
*        <ls_mod>-source_node     = /bobf/if_demo_customer_c=>sc_node-root.
*        <ls_mod>-association     =
*
*          /bobf/if_demo_customer_c=>sc_association-root-root_long_text.
*        <ls_mod>-source_key      = lr_s_root->key.
*        <ls_mod>-key             = lr_s_txt_hdr->key.
*        <ls_mod>-data            = lr_s_txt_hdr.
*
*
*
*        "Create the CONTENT node:
*        CREATE DATA lr_s_txt_cont.
*        lr_s_txt_cont->key          = /bobf/cl_frw_factory=>get_new_key( ).
*        lr_s_txt_cont->language     = sy-langu.
*        lr_s_txt_cont->text_type    = 'MEMO'.
*        lr_s_txt_cont->text_content = 'Demo customer created via BOPF API.'.
*
*
*
*        APPEND INITIAL LINE TO lt_mod ASSIGNING <ls_mod>.
*
*        <ls_mod>-node        =  lo_driver->query_node( iv_proxy_node_name = 'ROOT_LONG_TXT.CONTENT' ).
*        <ls_mod>-change_mode = /bobf/if_frw_c=>sc_modify_create.
*        <ls_mod>-source_node = /bobf/if_demo_customer_c=>sc_node-root_long_text.
*        <ls_mod>-source_key  = lr_s_txt_hdr->key.
*        <ls_mod>-key         = lr_s_txt_cont->key.
*        <ls_mod>-data        = lr_s_txt_cont.
*
*        <ls_mod>-association =
*          lo_driver->mo_bo_conf->query_assoc(
*            iv_node_key   = /bobf/if_demo_customer_c=>sc_node-root_long_text
*            iv_assoc_name = 'CONTENT' ).
*
*
**
**        "Create the customer record:
**        CALL METHOD lo_driver->mo_svc_mngr->modify
**          EXPORTING
**            it_modification = lt_mod
**          IMPORTING
**            eo_change       = lo_change
**            eo_message      = lo_message.
**
**
**
**        "Check for errors:
**        IF lo_message IS BOUND.
**          IF lo_message->check( ) EQ abap_true.
**            lo_driver->display_messages( lo_message ).
**            RETURN.
**          ENDIF.
**        ENDIF.
**
**
**
**        "Apply the transactional changes:
**        CALL METHOD lo_driver->mo_txn_mngr->save
**          IMPORTING
**            eo_message  = lo_message
**            ev_rejected = lv_rejected.
**
**
**
**        IF lv_rejected EQ abap_true.
**          lo_driver->display_messages( lo_message ).
**          RETURN.
**        ENDIF.
**
**
**
**        "If we get to here, then the operation was successful:
**        WRITE: / 'Customer', iv_customer_id, 'created successfully.'.
**      CATCH /bobf/cx_frw INTO lx_bopf_ex.
**        lv_err_msg = lx_bopf_ex->get_text( ).
**        WRITE: / lv_err_msg.
*    ENDTRY.
*  ENDMETHOD.                 " METHOD create_customer
*ENDCLASS.
*
*START-OF-SELECTION.
*
*  NEW lcl_demo( )->create_customer( iv_customer_id = '00000000001100000048' ).
*








*"FIELD-SYMBOLS: <ls_root> TYPE /scmtms/t_trq_root_k.
*
*DATA: lo_srv_tor    TYPE REF TO /bobf/if_tra_service_manager,
*      lt_mod        TYPE /bobf/t_frw_modification,
*      ls_mod        TYPE /bobf/s_frw_modification,
*      lo_chg        TYPE REF TO /bobf/if_tra_change,
*      lo_message    TYPE REF TO /bobf/if_frw_message,
*      lo_msg_all    TYPE REF TO /bobf/if_frw_message,
*      lo_tra        TYPE REF TO /bobf/if_tra_transaction_mgr,
*      lv_rejected   TYPE abap_bool,
*      lt_rej_bo_key TYPE /bobf/t_frw_key2,
*      ls_selpar     TYPE /bobf/s_frw_query_selparam,
*      lt_selpar     TYPE /bobf/t_frw_query_selparam,
*      lt_tor_qdb    TYPE /scmtms/t_trq_root_k.
** Get instance of service manager for TOR
*lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_trq_c=>sc_bo_key ).
*
** set an example query parameter
*ls_selpar-attribute_name = /scmtms/if_trq_c=>sc_query_attribute-root-root_elements-trq_id."tor_id.
*ls_selpar-option = 'EQ'.
*ls_selpar-sign = 'I'.
*ls_selpar-low = '00000000001100000048'.
*APPEND ls_selpar TO lt_selpar.
** find a TOR instance to be deleted
*
*lo_srv_tor->query(
*EXPORTING
*iv_query_key = /scmtms/if_trq_c=>sc_query-root-root_elements  "qdb_trqid
*it_selection_parameters = lt_selpar
*iv_fill_data = abap_true
*IMPORTING
*eo_message = lo_message
*et_data = lt_tor_qdb ).
*
*
*READ TABLE lt_tor_qdb ASSIGNING FIELD-SYMBOL(<ls_root>) INDEX 1.
** Save transaction to get data persisted (NO COMMIT WORK!)
*lo_tra = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).
** Call the SAVE method of the transaction manager
*lo_tra->save(
*IMPORTING
*ev_rejected = lv_rejected
*eo_change = lo_chg
*eo_message = lo_message
*et_rejecting_bo_key = lt_rej_bo_key ).
*
*--- Update the new instance with a Status Complete ---*
*CLEAR lt_mod.
*ls_mod-node = /scmtms/if_tor_c=>sc_node-root.
*ls_mod-key = <ls_root>-key.
*ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_update.
*
*CREATE DATA ls_mod-data TYPE /scmtms/s_tor_root_k.
*ASSIGN ls_mod-data->* TO <ls_root>.
*
*<ls_root>-lifecycle = '05'.
*APPEND /scmtms/if_tor_c=>sc_node_attribute-root-lifecycle
*TO ls_mod-changed_fields.
*
*APPEND ls_mod TO lt_mod.

***************************************GUARDADO****************************************
*lo_srv_tor->modify(
*EXPORTING
*it_modification = lt_mod
*IMPORTING
*eo_change = lo_chg
*eo_message = lo_message ).
*
*lo_tra->save(
*IMPORTING
*ev_rejected = lv_rejected
*eo_change = lo_chg
*eo_message = lo_message
*et_rejecting_bo_key = lt_rej_bo_key ).
***************************************GUARDADO****************************************
