
Function NavegaDocumento
    Select CrsLinhasDocs
    *msg(CrsLinhasDocs.ftstamp)
    navega("FT",CrsLinhasDocs.ftstamp)
endfunc

Function NavegaEncomenda
    Select CrsLinhasDocs
    *msg(CrsLinhasDocs.bostamp)
    navega("BO",CrsLinhasDocs.bostamp)
endfunc
