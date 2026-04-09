
**Força preenchimento de alguns campos 
if empty(m.ObjRecebido.Janela.pageframe1.page1.dataDocINI.value)
    m.ObjRecebido.Janela.pageframe1.page1.dataDocINI.value=date()-30
endif 

if empty(m.ObjRecebido.Janela.pageframe1.page1.DATADOCFIM.value)
    m.ObjRecebido.Janela.pageframe1.page1.DATADOCFIM.value=date()
endif 

**Guarda em variávies valores dos filtros 

mCtr = alltrim(m.ObjRecebido.Janela.pageframe1.page1.FldCentroAnalitico.value)
mConta = alltrim(m.ObjRecebido.Janela.pageframe1.page1.FldContas.value)

mDocdataIni = m.ObjRecebido.Janela.pageframe1.page1.dataDocINI.value
mDocdataFim = m.ObjRecebido.Janela.pageframe1.page1.DATADOCFIM.value

musername = m.m_chnome
mUsnoopen = alltrim(astr(m.ch_userno))

text to MselCheckValores textmerge noshow 
    DECLARE @DATAI DATE
    DECLARE @DATAF DATE
    DECLARE @CA    VARCHAR(100)
    DECLARE @Conta VARCHAR(100)

    SET @DATAI = convert(date, '<<mDocdataIni>>', 104)
    SET @DATAF = convert(date, '<<mDocdataFim>>', 104)

    SET @CA    = '<<mCtr>>'
    SET @Conta = '<<mConta>>';

    WITH Movimentos AS (
        SELECT
            dinome,
            docnome AS [Nome Doc],
            dostamp,
            adoc as [Número],
            conta   AS [Conta],
            cct     AS [Centro Analítico],
            descricao AS [Descrição],
            edeb,
            ecre,
            data,
            SUM(edeb - ecre) OVER (
                PARTITION BY cct
                ORDER BY data, adoc
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS SaldoCalc
        FROM ML WITH (NOLOCK)
        WHERE data BETWEEN @DATAI AND @DATAF
        AND cct LIKE '%' + @CA + '%'
        AND conta LIKE @Conta + '%'
    ),

    Resultado AS (
        -- Linhas normais
        SELECT
            dostamp,
            dinome,
            [Nome Doc],
            [Número],
            [Conta],
            [Centro Analítico],
            [Descrição],
            edeb      AS [Débito],
            ecre      AS [Crédito],
            SaldoCalc AS Saldo,
            [Centro Analítico] AS _ord_cct,
            0 AS _ord_tipo,
            data AS _ord_data,
            [Número] AS _ord_num
        FROM Movimentos

        UNION ALL

        -- TOTAL por CCT
        SELECT
            '',
            '',
            'TOTAL CCT',
            '',
            '',
            [Centro Analítico],
            '',
            SUM(edeb),
            SUM(ecre),
            SUM(edeb - ecre),
            [Centro Analítico],
            1,
            '',
            ''
        FROM Movimentos
        GROUP BY [Centro Analítico]

        UNION ALL

        -- Linha em branco após TOTAL CCT
        SELECT
            '', '', '', '', '', '', '', 0, 0, 0,
            [Centro Analítico],
            2,
            '',
            ''
        FROM Movimentos
        GROUP BY [Centro Analítico]

        UNION ALL

        -- TOTAL GERAL
        SELECT
            '',
            '',
            'TOTAL GERAL',
            '',
            '',
            '',
            '',
            SUM(edeb),
            SUM(ecre),
            SUM(edeb - ecre),
            'ZZZ',
            3,
            '',
            ''
        FROM Movimentos
    )

    SELECT
        IIF(year(_ord_data)=1900, '', convert(varchar,_ord_data,105)) as data,
        dinome as dinome,
        [Nome Doc] as docnome,
        [Número] as adoc,
        isnull((Select fostamp from FO(Nolock) where FO.dostamp = Resultado.dostamp and Resultado.dostamp != ''), '') as fostamp,
        [Conta] as conta,
        [Centro Analítico] as cct,
        [Descrição] as descricao,
        cast([Débito] as decimal(12,2)) as edeb,
        cast([Crédito] as decimal(12,2)) as ecre,
        cast(Saldo as decimal(12,2)) as saldo,
        dostamp as dostamp,
        IIF([Nome Doc] like ('TOTAL %'), '1', '0') as negrito
    FROM Resultado
    ORDER BY
        _ord_cct,
        _ord_tipo,
        _ord_data,
        _ord_num;
endtext

if m.ch_userno=1
    msg(MselCheckValores)
endif 

if !u_sqlexec(MselCheckValores,"mCrsValores")
    msg("Erro na instrução do select. Pff contacte a assistência técnica.")
    return 
endif 

mTotal = 0
LcNumMovimentos = 0

SELECT mCrsValores
Go top
Scan
    IF !empty(mCrsValores.dinome)
        LcNumMovimentos = LcNumMovimentos + 1
    ENDIF
ENDScan

Go top
mContador=reccount()

if mContador=0
    msg("Não encontrei registos para apresentar.")
    return 
endif
*m.ObjRecebido.Janela.pageframe1.page1.contador.caption=alltrim(astr(mContador)) + " registos."
*m.ObjRecebido.Janela.pageframe1.page1.contadortotais.caption=alltrim(astr(Round(mTotal,2))) + " Euros"

Select mCrsValores
GO BOTTOM

lcTotalCredito = mCrsValores.ecre
lcTotalDebito = mCrsValores.edeb
LcSaldo = mCrsValores.saldo

m.ObjRecebido.Janela.pageframe1.page1.lblRegistos.caption = TRANSFORM(LcNumMovimentos , "999999999")
m.ObjRecebido.Janela.pageframe1.page1.lbltotalcredito.caption = TRANSFORM(lcTotalCredito, "999999999.00") + " €"
m.ObjRecebido.Janela.pageframe1.page1.lbltotaldebito.caption = TRANSFORM(lcTotalDebito, "999999999.00") + " €"
m.ObjRecebido.Janela.pageframe1.page1.lblSaldo.caption = TRANSFORM(LcSaldo , "999999999.00") + " €"

Select mCrsValores
Go TOP
**GridColor()

Function AbrirAnexo
    local ox, linkficheiro

    Select mCrsAprov

    TEXT TO QueryVerAnexo TEXTMERGE NOSHOW 
        Select 
            fname
        from Anexos (nolock) 
        Where anexos.invisivel=0 
        and anexos.lsgq=0 
        and (anexos.oritable='FO' 
        and anexos.recstamp='<<mCrsAprov.fostamp>>' 
        and (anexos.privado=0 or (anexos.privado=1 and anexos.ousrinis='Adm'))) 
        and anexos.oritable='FO'
    ENDTEXT
    If U_SQLEXEC(QueryVerAnexo,"CrsHiperlink") 
        IF Reccount("CrsHiperlink") > 0
            Select CrsHiperlink
            linkficheiro = alltrim(CrsHiperlink.fname)
            ox=newObject("hyperlink")
            ox.navigateto(linkficheiro)
            ox=null
        else
            msg("Esta compra não possui qualquer anexo")
        ENDIF
    ENDIF
EndFunc

function GridColor
    LvForegroundColor='.SetAll("DynamicFontBold"'+',"'+'iif('m.ObjRecebido.Janela.MainGrid'.conta like ,RGB(0,255,0),"mCrsValores")'
*
    For Each myform In _Screen.Forms
        If Alltrim(Upper(myform.Name))== in_painel
            With m.ObjRecebido.Janela.MainGrid
                &LvForegroundColor
            Endwith
            Exit
        Endif
    Endfor
EndFunc

Function NavegarMovimento
    Select mCrsValores
    If !mexendo("DO")
        navega("DO",ALLTRIM(mCrsValores.dostamp))
    Endif
EndFunc

Function NavegarDoc
    Select mCrsValores
    If !mexendo("FO")
        navega("FO",ALLTRIM(mCrsValores.fostamp))
    Endif
EndFunc

