*** Grelha de funções de barra superior

Function DataInicial
    && variavel local do tipo data 
    m.mvalor = date() 
    m.descolheu=.f.
    && chama o calendário
    docomando("do form qdata with m.mvalor") 
    if m.descolheu
        && atribuição da data escolhida ao campo do tipo data
        PDU_7E10PPENQ.pageframe1.page1.DATADOCINI.value=(m.mvalor) 
    endif
Endfunc

Function DataFinal
    && variavel local do tipo data 
    m.mvalor = date() 
    m.descolheu=.f.
    && chama o calendário
    docomando("do form qdata with m.mvalor") 
    if m.descolheu
        && atribuição da data escolhida ao campo do tipo data
        PDU_7E10PPENQ.pageframe1.page1.DATADOCFIM.value=(m.mvalor) 
    endif
Endfunc
