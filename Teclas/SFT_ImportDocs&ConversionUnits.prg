**Tecla para calcular Metros para Yards

Select FT

IF FT.ndoc = 23
    IF PERGUNTA("Deseja inserir linhas a partir de uma encomenda?",2,"",.T.) = .T.
        ImportDoc()
    else
        ConverterUnits()
    ENDIF
ENDIF

Function ImportDoc
    Create Cursor xvars (no N(5), tipo c(1), Nome c(40), Pict c(100), lordem n(10), tbval m, nvalor N(18,5), cvalor c(250), mvalor m, lvalor l, dvalor d)
    Create Cursor LinhasFT (bistamp c(25), hscode c(30), Sel n(1), Ref c(18), lote c(30), Design c(60), Cor c(60), QttP n(18,2), QttF n(18,2), QttE n(18,2), Epv n(18,5), unidade c(4))
    Select xVars
    Append Blank
    Replace xVars.no With 1
    Replace xVars.tipo With "C"
    Replace xVars.Nome With "Nº da Encomenda:"
    Replace xVars.Pict With ""
    Replace xVars.lOrdem With 1
    Replace xVars.cValor With ""

    Select xVars
    Append Blank
    Replace xVars.no With 2
    Replace xVars.tipo With "C"
    Replace xVars.Nome With "Ano:"
    Replace xVars.Pict With "####"
    Replace xVars.lOrdem With 2
    Replace xVars.cValor With ""

    Select xVars
    Append Blank
    Replace xVars.no With 3
    Replace xVars.tipo With "C"
    Replace xVars.Nome With "Cliente: (Contido)"
    Replace xVars.Pict With ""
    Replace xVars.lOrdem With 3
    Replace xVars.cValor With ""

    m.mCaption = "Preencha os campos por favor:"
    m.escolheu = .f.
    docomando("do form usqlvar with 'xvars',m.mCaption,.t.")

    if m.escolheu
        SELECT xvars
        LOCATE FOR no = 1
        LcObraNo = xVars.cValor

        SELECT xvars
        LOCATE FOR no = 2
        LcAno = xVars.cValor

        SELECT xvars
        LOCATE FOR no = 3
        LcCliente = xVars.cValor

        TEXT TO MSELCheckDoc TEXTMERGE NOSHOW 
            DECLARE @OBRANO as VARCHAR(20) = '<<alltrim(LcObraNo)>>'
            DECLARE @ANO as VARCHAR(6) = '<<alltrim(LcAno)>>'
            DECLARE @CLIENTE as VARCHAR(100) = '<<alltrim(LcCliente)>>'

            SET @OBRANO = '%'+@OBRANO+'%'
            SET @ANO = '%'+@ANO+'%'
            SET @CLIENTE = '%'+@CLIENTE+'%'

            Select 
                cast(0 as bit) as sel
                , bostamp
                , Bo.dataobra
                , convert(varchar, obrano) + '/' + convert(varchar, boano) as 'Numero'
                , convert(varchar, no) + ' | ' + nome as 'Cliente'
            from BO(nolock)
            where ndos = 10
            and convert(varchar, BO.obrano) like @OBRANO 
            and convert(varchar, BO.boano) like @ANO 
            and BO.nome like @CLIENTE

            order by BO.obrano, BO.boano 
        ENDTEXT
        If U_SQLEXEC(MSELCheckDoc,"CrsDocs") And Reccount("CrsDocs") > 0
            Select CrsDocs
            i = 4

            DECLARE LIST_TIT(i),LIST_CAM(i),LIST_TAM(i),LIST_PIC(i),LIST_RONLY(i),LIST_ROT(i),List_DyCurrControl(i)
            =CURSORSETPROP("BUFFERING",5,"CrsDocs")

            i = 0

            i = i + 1
            LIST_TIT(i) = "Seleção"
            LIST_CAM(i) = "CrsDocs.sel"
            LIST_RONLY(i) = .F.
            LIST_PIC(i) = "LOGIC"
            LIST_TAM(i) = 8*10

            i = i + 1    
            LIST_TIT(i) = "Data do Dossier"
            LIST_CAM(i) = "CrsDocs.dataobra"
            LIST_RONLY(i) = .F.	
            LIST_PIC(i) = ""
            LIST_TAM(i) = 8*10

            i = i + 1
            LIST_TIT(i) = "Número do Doc."
            LIST_CAM(i) = "CrsDocs.Numero"
            LIST_RONLY(i) = .T.
            LIST_PIC(i) = ""
            LIST_TAM(i) = 8*12

            i = i + 1
            LIST_TIT(i) = "Cliente"
            LIST_CAM(i) = "CrsDocs.Cliente"
            LIST_RONLY(i) = .T.
            LIST_PIC(i) = ""
            LIST_TAM(i) = 8*10


            BROWLIST("Lista de Encomendas a selecionar","CrsDocs","CrsDocs",.T.,.F.,.F.,.T.,.F.,"",.T.,.T.)
            IF m.escolheu
                Select CrsDocs
                GO TOP
                Select bostamp from CrsDocs where CrsDocs.sel = .T. into Cursor CrsSelDocs

                Select CrsSelDocs
                GO TOP
                Scan
                    TEXT TO MSELCheckDoc TEXTMERGE NOSHOW 
                        DECLARE @BOSTAMP as VARCHAR(25) = 'CP25100757451,603000002  ';

                        WITH
                        DadosPrincipais as
                        (
                            Select 
                                1 as sel
                                , '' as Ref
                                , BO.nmdos + ' no. ' + convert(varchar, BO.obrano) + ' de ' + convert(varchar, BO.dataobra, 104) as 'Design'
                                , '' as CorAcabamento
                                , 0 as QttProduzida
                                , 0 as Preco
                                , 0 as QttExpedida
                                , 0 as QttFaturar
                                , '' as bistamp
                                , '' as lote
                                , 1 as ordem
                            from BO(nolock)
                            where BO.bostamp = @BOSTAMP

                            union all

                            Select 
                                cast(0 as bit) as sel
                                , u_OprodBI.Ref
                                , (Select design from ST(nolock) where ref = u_OProdBI.Ref) as Design
                                , CorAcabamento
                                , SUM(u_OprodBI.Qtt) as 'QttProduzida'
                                , AVG(Cast(Epv as decimal(12,2))) as 'Preco'
                                , 0 as 'QttExpedida'
                                , 0 as 'QttFaturar'
                                , BI.bistamp as 'bistamp'
                                , isnull((Select top 1 lote from SE(Nolock) where SE.u_ltmalha = (Select top 1 uLoteMalha from u_pl(nolock) where bistamp = BI.Bistamp) order by stock desc), '') as 'Lote'
                                , 2 as ordem
                            from u_OprodBI(nolock)
                            inner join BI(Nolock) on u_OprodBI.Bistamp = BI.bistamp
                            inner join BO(Nolock) on BO.bostamp = BI.bostamp
                            where BO.bostamp = @BOSTAMP
                            group by u_OprodBI.Ref, u_OprodBI.CorAcabamento, BI.bistamp 
                        )
                        , Expedicoes as 
                        (
                            Select
                                FI.fistamp
                                , FI.ref
                                , FI.design
                                , FI.lobs2
                                , IIF(FI.ndoc = 23, FI.uni2qtt, FI.qtt) as qtt
                                , IIF(FI.ndoc = 23, FI.unidad2, FI.unidade) as unidade
                            from SL(nolock) 
                            inner join FI(Nolock) on FI.fistamp = SL.slstamp
                            where SL.cm > 50 and SL.origem in ('FT') and FI.ref in (Select ref from DadosPrincipais)
                        )

                        Select 
                            sel
                            , a.Ref
                            , a.Design
                            , CorAcabamento
                            , QttProduzida
                            , isnull((Select SUM(qtt) from Expedicoes where Expedicoes.ref = a.ref and Expedicoes.lobs2 = a.CorAcabamento),0) as 'QttExpedida'
                            , QttFaturar
                            , Preco
                            , bistamp
                            , lote
                            , (Select usr6 from ST(nolock) where ST.ref = a.Ref) as 'HSCode'
                        from DadosPrincipais a
                        order by ordem asc, CorAcabamento desc
                    ENDTEXT
                    If U_SQLEXEC(MSELCheckDoc,"CrsLinhas") And Reccount("CrsLinhas") > 0
                        Select CrsLinhas
                        GO TOP
                        Scan
                            Select LinhasFT
                            Append blank
                            Replace LinhasFt.bistamp with CrsLinhas.bistamp
                            Replace LinhasFt.sel with CrsLinhas.sel
                            Replace LinhasFt.Ref with CrsLinhas.Ref
                            Replace LinhasFt.design with CrsLinhas.design
                            Replace LinhasFt.Cor with CrsLinhas.CorAcabamento
                            Replace LinhasFt.QttP with CrsLinhas.QttProduzida
                            Replace LinhasFt.QttE with CrsLinhas.QttExpedida
                            Replace LinhasFt.QttF with 0
                            Replace LinhasFt.EPV with CrsLinhas.Preco
                            IF !empty(LinhasFt.ref)
                                Replace LinhasFt.Unidade with 'MT'
                                Replace LinhasFt.lote with CrsLinhas.lote
                                Replace LinhasFt.hscode with CrsLinhas.HSCode
                            ENDIF

                            Select CrsLinhas
                        EndScan
                    ENDIF
                EndScan

                Select LinhasFt
                i = 9

                DECLARE LIST_TIT(i),LIST_CAM(i),LIST_TAM(i),LIST_PIC(i),LIST_RONLY(i),LIST_ROT(i),List_DyCurrControl(i)
                =CURSORSETPROP("BUFFERING",5,"LinhasFt")

                i = 0
                i = i + 1
                LIST_TIT(i) = "Seleção"
                LIST_CAM(i) = "LinhasFt.sel"
                LIST_RONLY(i) = .F.
                LIST_PIC(i) = "LOGIC"
                LIST_TAM(i) = 8*10

                i = i + 1    
                LIST_TIT(i) = "Refª"
                LIST_CAM(i) = "LinhasFt.ref"
                LIST_RONLY(i) = .T.	
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10

                i = i + 1    
                LIST_TIT(i) = "Designação"
                LIST_CAM(i) = "LinhasFt.design"
                LIST_RONLY(i) = .T.	
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10

                i = i + 1    
                LIST_TIT(i) = "Cor/Rapport"
                LIST_CAM(i) = "LinhasFt.cor"
                LIST_RONLY(i) = .T.	
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10

                i = i + 1    
                LIST_TIT(i) = "Qtt. Produzida"
                LIST_CAM(i) = "LinhasFt.QttP"
                LIST_RONLY(i) = .T.	
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10

                i = i + 1    
                LIST_TIT(i) = "Qtt. a faturar"
                LIST_CAM(i) = "LinhasFt.QttF"
                LIST_RONLY(i) = .F.	
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10

                i = i + 1    
                LIST_TIT(i) = "Qtt. já expedida"
                LIST_CAM(i) = "LinhasFt.QttE"
                LIST_RONLY(i) = .F.	
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10

                i = i + 1    
                LIST_TIT(i) = "Preço Médio de Venda"
                LIST_CAM(i) = "LinhasFt.EPV"
                LIST_RONLY(i) = .T.	
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10

                i = i + 1    
                LIST_TIT(i) = "Unidade"
                LIST_CAM(i) = "LinhasFt.Unidade"
                LIST_RONLY(i) = .F.	
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10


                BROWLIST("Selecione as linhas e quantidades a faturar","LinhasFt","LinhasFt",.T.,.F.,.F.,.T.,.F.,"",.T.,.T.)
                IF m.escolheu
                    Select LinhasFt
                    
                    Select ref, design, cor, qttf, unidade, bistamp, lote, hscode from LinhasFt where LinhasFt.sel = 1 into Cursor CrsLinhasFt

                    Select CrsLinhasFt
                    GO TOP

                    Scan
                        Select FI
                        
                        Replace FI.Ref with CrsLinhasFT.ref
                        Replace FI.design with CrsLinhasFT.design
                        Replace FI.qtt with CrsLinhasFT.qttf
                        Replace FI.unidade with CrsLinhasFT.unidade
                        Replace FI.lobs2 with CrsLinhasFT.cor
                        replace fi.armazem with 1
                        replace fi.tabiva with 4
                        replace fi.iva with 0
                        replace fi.bistamp with CrsLinhasFT.bistamp
                        replace fi.lote with CrsLinhasFt.lote
                        Replace fi.litem2 with CrsLinhasFt.hscode

                        sft.Pageframe1.Page1.Cont1.Linserir.click()
                        *Do u_ftiliq

                        Select CrsLinhasFt
                    EndScan

                    Select FI
                    SFT.refrescar

                    ConverterUnits()

                ENDIF
            ENDIF

            else
                msg("Sem Resultados")
                Return .f.
            ENDIF
    Endif
Endfunc

Function ConverterUnits
    Select FT
    If PERGUNTA("Pretende continuar?",2,"A fatura irá ser convertida e calculada automaticamente na unidade preferencial do cliente",.T.) = .T.
        IF FT.no > 0
            TEXT TO MSELCheckCliente TEXTMERGE NOSHOW 
                Select u_unitpref, u_fatorc from CL(nolock) where CL.no = <<FT.no>>
            ENDTEXT
            If U_SQLEXEC(MSELCheckCliente,"CrsConversao") And Reccount("CrsConversao") > 0
                Select CrsConversao
                LcUnit = CrsConversao.u_unitpref
                LcFator = CrsConversao.u_fatorc
                
                IF !empty(LcUnit)

                    Select FI
                    GO TOP


                    Scan
                        lcRef = FI.ref
                        IF !empty(FI.bistamp)
                            TEXT TO MSELCheckEpv TEXTMERGE NOSHOW 
                                SELECT 
                                    isnull(SUM(QttEnc * Epv) / SUM(QttEnc),0) AS Epv_Medio
                                FROM u_OprodBI
                                WHERE bistamp = '<<alltrim(FI.bistamp)>>';
                            ENDTEXT
                            If U_SQLEXEC(MSELCheckEpv,"CrsPrice") And Reccount("CrsPrice") > 0
                                Select CrsPrice
                                LcPreco = CrsPrice.Epv_Medio

                                Select FI
                                IF UPPER(FI.unidade) = 'MT'
                                    Do ftactref with '', .t.

                                    IF LcPreco > 0
                                        REPLACE FI.pvmoeda with LcPreco*1.18
                                        *REPLACE FI.tmoeda with (LcPreco*FI.qtt)*1.18
                                        REPLACE FI.epv with LcPreco
                                        *REPLACE FI.etiliquido with LcPreco*FI.qtt
                                        REPLACE FI.u_qttun with FI.qtt
                                        REPLACE FI.u_epvun with LcPreco*LcFator
                                    ENDIF


                                    REPLACE FI.uni2qtt with FI.qtt
                                    REPLACE FI.unidad2 with 'MT'
                                    REPLACE FI.qtt with FI.qtt*LcFator
                                    REPLACE FI.unidade with alltrim(lcunit)

                                    TEXT TO MSELCheckHSCode TEXTMERGE NOSHOW 
                                        SELECT 
                                            usr6
                                        FROM ST(Nolock)
                                        WHERE ST.ref = '<<alltrim(lcRef)>>';
                                    ENDTEXT
                                    If U_SQLEXEC(MSELCheckHSCode,"CrsHSCode")
                                        Select CrsHSCode
                                        Select FI
                                        REPLACE FI.litem2 with CrsHSCode.usr6
                                    ENDIF
                                ENDIF
                            ENDIF
                        else
                            IF UPPER(FI.unidade) = 'MT'
                                Do ftactref with '', .t.

                                REPLACE FI.uni2qtt with FI.qtt
                                REPLACE FI.unidad2 with 'MT'
                                REPLACE FI.qtt with FI.qtt*LcFator
                                REPLACE FI.unidade with alltrim(lcunit)

                                TEXT TO MSELCheckHSCode TEXTMERGE NOSHOW 
                                    SELECT 
                                        usr6
                                    FROM ST(Nolock)
                                    WHERE ST.ref = '<<alltrim(lcRef)>>';
                                ENDTEXT
                                If U_SQLEXEC(MSELCheckHSCode,"CrsHSCode")
                                    Select CrsHSCode
                                    Select FI
                                    REPLACE FI.litem2 with CrsHSCode.usr6
                                ENDIF
                            ENDIF
                        ENDIF
                        *DO Ftactref('',.F.,'OKPRECOS','FT','FI',.F.,'')

                        Do u_ftiliq
                        Do FTTOTS With .t.
                        SFT.refrescar
                    EndScan
                    
                    *
                else
                    msg("O cliente inserido não tem unidade preferencial definida. Por favor, preencha a unidade e o respetivo fator de conversão na ficha.")
                    Return .f.
                ENDIF
            ENDIF
        else
            msg("Não tem o cliente preenchido, por favor corrija")
            Return .f.
        ENDIF
    else
        Return .f.
    ENDIF
EndFunc