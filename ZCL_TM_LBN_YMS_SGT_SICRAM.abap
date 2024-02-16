  METHOD /bobf/if_frw_determination~execute.

    DATA: lt_root     TYPE /scmtms/t_tor_root_k,
          lt_root_bef TYPE /scmtms/t_tor_root_k,
          lt_exec     TYPE /scmtms/t_tor_exec_k,
          lt_com_yms  TYPE /tenr/t_tmcomunyms_in,
          ls_tmymspl  TYPE /tenr/t_tmymspl1,
          lt_tmymspl  TYPE TABLE OF /tenr/t_tmymspl1,
          lo_proxy    TYPE REF TO /tenr/co_ws_oa_send_freight_or,
          ls_output   TYPE /tenr/ws_send_freight_order1,
          lt_key      TYPE /bobf/t_frw_key.
*          lo_srv_tor TYPE REF TO /bobf/if_tra_service_manager.

**    lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).
*    lt_key = VALUE #( ( key = i_key ) ).

    IF sy-uname EQ 'LBNCONEXION'.

      CALL METHOD io_read->retrieve
        EXPORTING
          iv_node      = /scmtms/if_tor_c=>sc_node-root
          it_key       = it_key
          iv_fill_data = abap_true
        IMPORTING
          et_data      = lt_root.

      CALL METHOD io_read->retrieve
        EXPORTING
          iv_node         = /scmtms/if_tor_c=>sc_node-root
          it_key          = it_key
          iv_fill_data    = abap_true
          iv_before_image = abap_true
        IMPORTING
          et_data         = lt_root_bef.

      CALL METHOD io_read->retrieve_by_association
        EXPORTING
          iv_node        = /scmtms/if_tor_c=>sc_node-root
          it_key         = it_key
          iv_fill_data   = abap_true
          iv_association = /scmtms/if_tor_c=>sc_association-root-exec
        IMPORTING
          et_data        = lt_exec.

      IF lt_root IS NOT INITIAL AND lt_root_bef IS NOT INITIAL.
        LOOP AT lt_root INTO DATA(ls_root).
          TRY.
*          DATA(ls_root) = lt_root[ 1 ].
              DATA(ls_root_bef) = lt_root_bef[ key = ls_root-key ].
            CATCH cx_sy_itab_line_not_found.
          ENDTRY.

          IF ls_root_bef-tspid NE ls_root-tspid OR ls_root_bef-confirmation NE ls_root-confirmation AND ls_root-lifecycle NE '10'. "Diferente de Canceled (10)

            NEW zcl_tm_val_com_yms( )->send_data_yms(
              EXPORTING
                i_key     = ls_root-root_key
                i_torid   = ls_root-tor_id                 " Documento
                i_status  = 'U'                  " Indicador de una posición carrier asignado
                i_exec    = lt_exec  "                                                           blt_exec "lt_d_exec_tr
                i_ttor    = lt_root              "Ad. T21255 Datos de comumicación integración YMS SGT
              IMPORTING
                e_com_yms =  lt_com_yms ).               " Comunicación con YMS (Planificado)

*** llamado de proxy *Begin T21255
            LOOP AT lt_com_yms ASSIGNING FIELD-SYMBOL(<lfs_com_yms>).
              ls_output-send_freight_order-freight_order = CORRESPONDING #( <lfs_com_yms> ).
              ls_output-send_freight_order-freight_order-consignee_desc = <lfs_com_yms>-consignee_descr.
**  FO_NUMBER a 20 posiciones con ceros a la izquierda
              ls_output-send_freight_order-freight_order-fo_number = CONV char20( |{ ls_output-send_freight_order-freight_order-fo_number ALPHA = IN }| ).
** SALES_ORDER_ITEM a 6 posisiones con ceros a la izquierda
              ls_output-send_freight_order-freight_order-sales_order_item = CONV char6( |{ ls_output-send_freight_order-freight_order-sales_order_item ALPHA = IN }| ).
** BUSSINES_TR_DOC_ID a 10 posiciones con ceos a la iquierda
              ls_output-send_freight_order-freight_order-bussines_tr_doc_id = CONV char10( |{ ls_output-send_freight_order-freight_order-bussines_tr_doc_id ALPHA = IN }| ).

              TRY.
                  CREATE OBJECT lo_proxy.
                CATCH cx_ai_system_fault.
              ENDTRY.
              IF lo_proxy IS BOUND.
                TRY .
                    CALL METHOD lo_proxy->oa_send_freight_order
                      EXPORTING
                        output = ls_output.

                    COMMIT WORK.

                  CATCH cx_ai_system_fault INTO DATA(g_system_fault).
                    DATA(r_error) = abap_true.
                ENDTRY.
              ENDIF.

            ENDLOOP.
            REFRESH lt_com_yms.
            CLEAR lt_com_yms.
          ENDIF.
        ENDLOOP.
      ENDIF.


      "Envio de datos a SICRAM.
      LOOP AT lt_root INTO ls_root.
        TRY.
            ls_root_bef = lt_root_bef[ key = ls_root-key ].

            SELECT SINGLE * FROM /tenr/t_comunyms
              INTO @DATA(ls_comunyms)
              WHERE tor_type EQ @ls_root-tor_type
                AND blk_plan EQ @ls_root-blk_plan
                AND subcontracting EQ @ls_root-subcontracting
                AND confirmation   EQ @ls_root-confirmation.

            IF sy-subrc EQ 0.

              IF ls_root_bef-confirmation NE ls_root-confirmation AND ls_root-lifecycle NE '10'.

                lt_key = VALUE #( ( key = ls_root-key ) ).
                CALL FUNCTION '/TENR/FM_INT_SICRAM_OUT'
                  EXPORTING
                    i_tor_key  = lt_key
                    i_upd_flag = 'I'.

                REFRESH: lt_key.

              ENDIF.

            ENDIF.

          CATCH cx_sy_itab_line_not_found.
        ENDTRY.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
