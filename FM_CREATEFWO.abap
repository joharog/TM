  FUNCTION /tenr/fm_createfwo.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     VALUE(I_DATA) TYPE  ZTEN_S_TMCREATEFWO OPTIONAL
*"  EXPORTING
*"     VALUE(E_MESS) TYPE  ZTEN_TT_TMMESS
*"----------------------------------------------------------------------
*------------------------------------------------------------
*ABAP Name  : /TENR/Rodolfo Gonzalez
*Created by : T20789
*Created on : 14/04/2023
*Version    : V.1
*Description: Interfaz ( Funcion para creacion de FWO )
*------------------------------------------------------------
*Modification Log:
*Date  Programmer   Correction  Description
*mm/dd/yyyy Txxxxx ó SIDTxxx  TEDK000001  Added……
*------------------------------------------------------------

*    IF i_data-item[] IS NOT INITIAL.
*
*      LOOP AT i_data-item INTO DATA(wa_data).

    e_mess = COND #( WHEN i_data-trq_id IS INITIAL THEN  NEW zcl_tm_interfazfwo( )->create_fwo( i_data = i_data )  "Creacion FWO
                     WHEN i_data-trq_id IS NOT INITIAL THEN  NEW zcl_tm_interfazfwo( )->modify_fwo( i_data = i_data  ) ). "Modify FWO

*        APPEND LINES OF e_mess1 TO e_mess.
*        CLEAR: wa_data.
**
*
*      ENDLOOP.

*  ENDIF.

ENDFUNCTION.
