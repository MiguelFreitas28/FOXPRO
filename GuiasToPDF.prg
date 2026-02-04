*** SBO - Tecla ctrl-f6 ExportDocsToPDF
*** Botão no ecrã de encomendas de cliente
*** 04/02/2026 - Miguel Freitas

Select BO

** Verificar o ndos do dossier
IF BO.ndos = 10

    LcBONumber = ""
    lcBOAno = ""

    * Criação dos cursores
    Create Cursor xDocs (ftstamp C(25), nmdoc C(30), fno N(18,2), nome C(70), etotal N(18,2), fdata D, sel L)
    Create Cursor xDocsfiltered (ftstamp C(25), nmdoc C(30), fno N(18,2), nome C(70), etotal N(18,2), fdata D, sel L)
    Create Cursor xvars (no N(5), tipo c(1), Nome c(40), Pict c(100), lordem n(10), tbval m, nvalor N(18,5), cvalor c(250), mvalor m, lvalor l, dvalor d)

    * Solicitação do nº da encomenda
    Select xVars
    Append Blank
    Replace xVars.no With 1
    Replace xVars.tipo With "C"
    Replace xVars.Nome With "Nº da Encomenda:"
    Replace xVars.Pict With ""
    Replace xVars.lOrdem With 1
    Replace xVars.cValor With ""

    * Solicitação do ano correspondente
    Select xVars
    Append Blank
    Replace xVars.no With 2
    Replace xVars.tipo With "C"
    Replace xVars.Nome With "Ano:"
    Replace xVars.Pict With ""
    Replace xVars.lOrdem With 2
    Replace xVars.cValor With ""

    m.mCaption = "Preencha os campos por favor:"
    m.escolheu = .f.
    docomando("do form usqlvar with 'xvars',m.mCaption,.t.")

    if m.escolheu
        SELECT xvars
        LOCATE FOR no = 1
        LcBONumber = xVars.cValor

        SELECT xvars
        LOCATE FOR no = 2
        lcBOAno = xVars.cValor

        * Pesquisa do stamp da encomenda solicitada
        TEXT TO MselcheckStamp TEXTMERGE NOSHOW 
            Select bistamp from BI(Nolock)
            inner join BO(Nolock) on BO.bostamp = BI.bostamp
            where BO.obrano = '<<alltrim(LcBONumber)>>' and year(BO.dataobra) = '<<alltrim(LcBOAno)>>'
            and BO.ndos = 10
        ENDTEXT
        If U_SQLEXEC(MselcheckStamp,"CrsStamps") And Reccount("CrsStamps") > 0
            Select CrsStamps
            GO TOP
            Scan
                * Pesquisa das diferentes guias associadas à encomenda
                TEXT TO MselcheckFT TEXTMERGE NOSHOW 
                    Select FT.ftstamp, FT.nmdoc, FT.fno, convert(varchar, no) + ' | ' + nome as nome, FT.etotal, FT.fdata from FI(Nolock)
                    inner join FT(Nolock) on FT.ftstamp = FI.ftstamp
                    where FI.bistamp in ('<<alltrim(CrsStamps.bistamp)>>') and FT.ndoc = 2
                ENDTEXT
                If U_SQLEXEC(MselcheckFT,"CrsFts") And Reccount("CrsFts") > 0
                    Select CrsFts
                    GO TOP
                    Scan
                        Select xDocs
                        Append Blank
                        Replace xDocs.ftstamp with CrsFts.ftstamp
                        Replace xDocs.nmdoc with CrsFts.nmdoc
                        Replace xDocs.fno with CrsFts.fno
                        Replace xDocs.nome with CrsFts.nome
                        Replace xDocs.etotal with CrsFts.etotal
                        Replace xDocs.fdata with CrsFts.fdata

                        Select CrsFts
                    EndScan
                ENDIF
            EndScan

            * Abrir listagem para seleção das guias a extrair para pdf
            IF Reccount("xDocs") > 0
                Select xDocs

                i = 7

                DECLARE LIST_TIT(i),LIST_CAM(i),LIST_TAM(i),LIST_PIC(i),LIST_RONLY(i),LIST_ROT(i),List_DyCurrControl(i)
                =CURSORSETPROP("BUFFERING",5,"xDocs")

                i = 0
                i = i + 1    
                LIST_TIT(i) = "Sel."
                LIST_CAM(i) = "xDocs.sel"
                LIST_RONLY(i) = .F.	
                LIST_PIC(i) = "LOGIC"
                LIST_TAM(i) = 8*10

                i = i + 1
                LIST_TIT(i) = "Data do Doc."
                LIST_CAM(i) = "xDocs.fdata"
                LIST_RONLY(i) = .T.
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*12

                i = i + 1
                LIST_TIT(i) = "Nome do Doc."
                LIST_CAM(i) = "xDocs.nmdoc"
                LIST_RONLY(i) = .T.
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10

                i = i + 1
                LIST_TIT(i) = "Nº do Doc"
                LIST_CAM(i) = "xDocs.fno"
                LIST_RONLY(i) = .T.
                LIST_PIC(i) = "########"
                LIST_TAM(i) = 8*10

                i = i + 1
                LIST_TIT(i) = "Cliente"
                LIST_CAM(i) = "xDocs.nome"
                LIST_RONLY(i) = .T.
                LIST_PIC(i) = ""
                LIST_TAM(i) = 8*10

                i = i + 1
                LIST_TIT(i) = "Total do Doc."
                LIST_CAM(i) = "xDocs.etotal"
                LIST_RONLY(i) = .T.
                LIST_PIC(i) = "###,###,###,###.## €"
                LIST_TAM(i) = 8*10

                i = i + 1
                LIST_TIT(i) = "Consultar"
                LIST_CAM(i) = ""
                LIST_RONLY(i) = .T.
                LIST_PIC(i) = "BOTAO IMG: quiklook.bmp"
                LIST_TAM(i) = 8*10       
                LIST_ROT(i) = "Do ConsultarDocumento"

                MsgBrow = "Lista de Documentos para Exportação"
                BROWLIST(MsgBrow,"xDocs","xDocs",.T.,.F.,.F.,.T.,.F.,"",.T.,.T.)

                IF m.escolheu = .T.
                    Select xDocs

                    * Passagem dos documentos escolhidos para um segundo cursor
                    Select * from xDocs where xDocs.sel = .T. into cursor xDocsfiltered
                    
                    Select xDocsfiltered
                    * a variável guarda o total de registos do cursor tempcursor
                    mntotal=reccount()

                    * inicializa a régua apresentando um título e o nº total de registos
                    regua(0,mntotal,"A extrair as guias selecionadas")

                    Scan FOR xDocs.sel = .T.
                        * a régua apresenta um subtitulo com dados de um campo do cursor e apresenta o registo actual que está a ser processado.
                        regua(1,recno(),"Extraindo a guia Nº"+astr(xDocsfiltered.fno))
                        * Função para exportar PDF do registo em questão
                        EXPORTPDF()
                    EndScan

                    * fecha a régua
                    regua(2)
                    msg("Extração de guias concluida. Consulte-as em 'C:\PHCCS\Guias\'")
                ENDIF
            else
                msg("Não existem guias associadas à encomenda selecionada.")
            ENDIF
        else
            msg("Não existe qualquer encomenda com o nº " + astr(LcBONumber) + " referente ao ano " + astr(lcBOAno) + ".")
        Endif
    Endif
ENDIF

Function ConsultarDocumento
    Select xDocs
    LcFtstamp = xDocs.ftstamp

    * Navega para o ecrã do registo
    doread("FT","SFT")
    navega("FT",LcFtstamp)
EndFunc

Function ExportPDF
    Select xDocsfiltered
    LcFtstamp = xDocsfiltered.ftstamp

    * Navega para o ecrã do registo
    doread("FT","SFT")
    navega("FT",LcFtstamp)

    xFile = ''
                                 
    select ft
    NFT = ft.ndoc
    
    * Define o caminho para o destino dos ficheiros                
    u_path = "C:\PHCCS\Guias\"
        
    if not empty(u_path)
        * Criação da diretoria se esta não existir
        IF !Directory(u_path,1)
            MKDIR (u_path)
        endif
        

        * Guarda-se o stamp do IDU por defeito          
        u_sqlexec("select idustamp, titulo from ftiduc(nolock) where ndos = " + alltrim(str(NFT)),"idudef")
        select idudef
        mcstamp = alltrim(idudef.idustamp)
        esteiduf = alltrim(idudef.titulo)

        * Criar PDF
                    
        xCaminho = u_path
        select ft
        xFile = xCaminho + alltrim(ft.nmdoc) + "_" + alltrim(str(ft.fno)) + "_" + alltrim(dtos(ft.fdata))
        xFile = xFile + "_" + alltrim(str(SECONDs())) + ".pdf"

        **msg(xFile)
                            
        SELECT ft
        SELECT fI

        * Cria o ficheiro PDF
            
        idutopdf("FT","FI","FTCAMPOS","FICAMPOS","FTIDUC","FTIDUL",ft.ndoc,esteiduf,upper(xFile),"","NO",.f.,"ONETOMANY")
    ENDIF

    SFT.hide
EndFunc