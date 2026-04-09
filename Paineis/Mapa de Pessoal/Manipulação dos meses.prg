*** Grelha de funções de barra superior

Function DataMais
    LcMes = 0
    LcAno = 0

    LcAno = PDU_7ED0YCK3Z.Pageframe1.Page1.Fldano.Value
    LcMes = PDU_7ED0YCK3Z.Pageframe1.Page1.FldMes.Value

    IF astr(LcMes) == "12"
        LcAno = LcAno + 1
        PDU_7ED0YCK3Z.Pageframe1.Page1.Fldano.Value = LcAno
        PDU_7ED0YCK3Z.Pageframe1.Page1.FldMes.Value = 1
    else
        LcMes = LcMes + 1
        PDU_7ED0YCK3Z.Pageframe1.Page1.FldMes.Value = LcMes
    ENDIF

    PDU_7ED0YCK3Z.Actualizartot.Nossobutton1.click()
EndFunc

Function DataMenos
    LcMes = 0
    LcAno = 0

    LcAno = PDU_7ED0YCK3Z.Pageframe1.Page1.Fldano.Value
    LcMes = PDU_7ED0YCK3Z.Pageframe1.Page1.FldMes.Value

    IF astr(LcMes) == "1"
        LcAno = LcAno - 1
        PDU_7ED0YCK3Z.Pageframe1.Page1.Fldano.Value = LcAno
        PDU_7ED0YCK3Z.Pageframe1.Page1.FldMes.Value = 12
    else
        LcMes = LcMes - 1
        PDU_7ED0YCK3Z.Pageframe1.Page1.FldMes.Value = LcMes
    ENDIF

    PDU_7ED0YCK3Z.Actualizartot.Nossobutton1.click()
EndFunc