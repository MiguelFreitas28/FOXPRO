*** SBO - Tecla ctrl-f6 ExportDocsToPDF
*** Botão no ecrã de encomendas de cliente
*** 06/02/2026 - Miguel Freitas

Select BO

** Verificar o ndos do dossier
IF BO.ndos = 10

    LcBONumber = BO.obrano
    lcBOAno = BO.boano
    m.escolheu = .F.
    lcStamps = ""

    * Criação dos cursores
    Create Cursor xDocs (ftstamp C(25), nmdoc C(30), fno N(18,2), nome C(70), etotal N(18,2), fdata D, sel L)
    Create Cursor xDocsfiltered (ftstamp C(25), nmdoc C(30), fno N(18,2), nome C(70), etotal N(18,2), fdata D, sel L)

    Select BI
    GO TOP
    Scan
        IF empty(lcStamps)
            lcStamps = "'"+BI.bistamp+"'"
        else
            lcStamps = lcStamps + "," + "'"+BI.bistamp+"'"
        ENDIF
    EndScan

    * Pesquisa das diferentes guias associadas à encomenda
    TEXT TO MselcheckFT TEXTMERGE NOSHOW 
        Select 
            FT.ftstamp
            , FT.nmdoc
            , FT.fno
            , convert(varchar, no) + ' | ' + nome as nome
            , FT.etotal
            , FT.fdata 
        from FI(Nolock)
        inner join FT(Nolock) on FT.ftstamp = FI.ftstamp
        where FI.bistamp in (<<alltrim(lcStamps)>>) and FT.anulado = 0
        group by FT.ftstamp, FT.nmdoc, FT.fno, FT.no, Ft.nome, FT.etotal, FT.fdata

        union all

        Select 
            b.ftstamp
            , b.nmdoc
            , b.fno
            , convert(varchar, c.no) + ' | ' + c.nome as cnome
            , c.etotal
            , c.fdata
        from FI(Nolock)
        inner join FT(Nolock) on FT.ftstamp = FI.ftstamp
        inner join FI(Nolock) b on b.ofistamp = FI.fistamp
        inner join FT(Nolock) c on c.ftstamp = b.ftstamp
        where FI.bistamp in (<<alltrim(lcStamps)>>) and FT.anulado = 0
        group by b.ftstamp, b.nmdoc, b.fno, c.no, c.nome, c.etotal, c.fdata
    ENDTEXT

    if m.ch_userno=1
        msg(MselcheckFT)
    endif 

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
            regua(0,mntotal,"A exportar os documentos selecionados")

            Scan FOR xDocs.sel = .T.
                * a régua apresenta um subtitulo com dados de um campo do cursor e apresenta o registo actual que está a ser processado.
                regua(1,recno(),"Exportando o documento Nº "+astr(xDocsfiltered.fno))
                * Função para exportar PDF do registo em questão
                EXPORTPDF()
            EndScan

            * fecha a régua
            regua(2)
            msg("Extração de documentos concluida. Consulte-os em 'C:\PHCCS\PDFDocs\'")
        ENDIF
    else
        msg("Não existem documentos associados à encomenda selecionada.")
    ENDIF
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
    u_path = "C:\PHCCS\PDFDocs\EncomendaCliente_"+astr(LcBONumber)+"_"+astr(LcBOAno)+"\"
        
    if not empty(u_path)
        * Criação da diretoria se esta não existir
        IF !Directory(u_path,1)
            MKDIR (u_path)
        endif
        

        * Guarda-se o stamp do IDU por defeito          
        u_sqlexec("select top 1 idustamp, titulo from ftiduc(nolock) where ndos = " + alltrim(str(NFT)),"idudef")
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