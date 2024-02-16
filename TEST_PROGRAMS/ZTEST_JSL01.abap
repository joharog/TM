*&---------------------------------------------------------------------*
*& Report ZTEST_JSL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_jsl.

DATA: lo_srv_tor  TYPE REF TO /bobf/if_tra_service_manager,
      "      lt_mod        TYPE /bobf/t_frw_modification,
      "      ls_mod        TYPE /bobf/s_frw_modification,
      "      lo_chg        TYPE REF TO /bobf/if_tra_change,
      "lo_message TYPE REF TO /bobf/if_frw_message,
      "      lo_msg_all    TYPE REF TO /bobf/if_frw_message,
      "      lo_tra        TYPE REF TO /bobf/if_tra_transaction_mgr,
      "      lv_rejected   TYPE abap_bool,
      "      lt_rej_bo_key TYPE /bobf/t_frw_key2,
      ls_selpar   TYPE /bobf/s_frw_query_selparam,
      lt_selpar   TYPE /bobf/t_frw_query_selparam,
      lt_tor_root TYPE /scmtms/t_tor_root_k,
      lt_root_data TYPE /scmtms/t_cfir_root_node_k.


DATA: lt_data    TYPE REF TO data,
      lo_nodes   TYPE REF TO zcl_tm_get_nodes_subnodes,
      lo_message TYPE REF TO /bobf/if_frw_message.

DATA: it_key  TYPE /bobf/t_frw_key,
      lt_key2  TYPE /bobf/t_frw_key2,
      lt_key_root  TYPE /bobf/t_frw_key.

FIELD-SYMBOLS <lt_block> TYPE INDEX TABLE.
FIELD-SYMBOLS <lt_attach_fol> TYPE INDEX TABLE.
FIELD-SYMBOLS <lt_attach_doc> TYPE INDEX TABLE.


* Get instance of service manager for TOR
lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).

DATA(gv_bo_key) = /scmtms/if_tor_c=>sc_bo_key.
DATA(gv_node_key) = /scmtms/if_tor_c=>sc_node-root.
* set an example query parameter
ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-root_elements-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = '00000000006100000161'.
APPEND ls_selpar TO lt_selpar.
* find a TOR instance to be deleted

lo_srv_tor->query(
EXPORTING
iv_query_key = /scmtms/if_tor_c=>sc_query-root-root_elements
it_selection_parameters = lt_selpar
iv_fill_data = abap_true
IMPORTING
eo_message = lo_message
et_data = lt_tor_root ).

APPEND VALUE #( key = lt_tor_root[ 1 ]-key ) TO it_key.

INSERT it_key[ 1 ]-key INTO TABLE lt_key2.

CREATE OBJECT: lo_nodes.

lo_nodes->get_root_nodes( EXPORTING
                            gv_bo_key = gv_bo_key
                            gt_key = lt_key2
                            gv_node_key = gv_node_key
                          IMPORTING
                            gt_root_node_list = DATA(gt_root_nodes) ).

CLEAR: lt_root_data[].

*        TRY.
*
*            DATA(ls_root_node) = gt_root_nodes[ data_table_type = '/SCMTMS/T_TOR_BLOCK_K' ].
*            CREATE DATA lt_data TYPE (ls_root_node-data_table_type).
*            ASSIGN lt_data->* TO <lt_block>.
*
*            lt_key_root =  VALUE #( ( key = ls_root_node-key ) ).
*
*            lo_nodes->get_list_subnodes( EXPORTING
*                                           gv_node_key = ls_root_node-node_key
*                                           gt_key = lt_key_root
*                                           gv_association = ls_root_node-association "/scmtms/if_tor_c=>sc_association-block-to_root "ls_root_node-association
*                                           gv_bo_key = ls_root_node-bo_key
*                                         IMPORTING
*                                           gt_subnode_list = DATA(gt_subnode_list)
*                                           et_data = <lt_block> ).
*
*          CATCH cx_sy_itab_line_not_found.
*        ENDTRY.

        TRY.

            DATA(ls_root_node) = gt_root_nodes[ data_table_type = '/BOBF/T_ATF_ROOT_K' ].
            CREATE DATA lt_data TYPE (ls_root_node-data_table_type).
            ASSIGN lt_data->* TO <lt_attach_fol> .

            lt_key_root =  VALUE #( ( key = ls_root_node-key ) ).

            lo_nodes->get_list_subnodes( EXPORTING

                                           gv_node_key = ls_root_node-node_key
                                           gt_key = lt_key_root
                                           gv_association = ls_root_node-association
                                           gv_bo_key = ls_root_node-bo_key
                                         IMPORTING
                                           gt_subnode_list = DATA(gt_subnode_list)
                                           et_data = <lt_attach_fol> ).

          CATCH cx_sy_itab_line_not_found.
        ENDTRY.


          TRY.
            DATA(ls_root_subnode) = gt_subnode_list[ data_table_type = '/BOBF/T_ATF_DOCUMENT_K' ].
            CREATE DATA lt_data TYPE (ls_root_subnode-data_table_type).
            ASSIGN lt_data->* TO <lt_attach_doc> .

            lt_key_root =  VALUE #( ( key = ls_root_node-key ) ).

            lo_nodes->get_list_subnodes( EXPORTING

                                           gv_node_key = ls_root_subnode-node_key
                                           gt_key = lt_key_root
                                           gv_association = ls_root_subnode-association
                                           gv_bo_key = ls_root_subnode-bo_key
                                         IMPORTING
                                           gt_subnode_list = DATA(gt_subnode_list_2)
                                           et_data = <lt_attach_doc> ).

          CATCH cx_sy_itab_line_not_found.
        ENDTRY.

          BREAK t20703.
