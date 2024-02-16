FUNCTION /tenr/fm_tm_carrier_proxy.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     VALUE(LS_OUTPUT) TYPE  /TENR/WS_SEND_FREIGHT_ORDER1 OPTIONAL
*"----------------------------------------------------------------------
  DATA:           lo_proxy    TYPE REF TO /tenr/co_ws_oa_send_freight_or.

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

ENDFUNCTION.
