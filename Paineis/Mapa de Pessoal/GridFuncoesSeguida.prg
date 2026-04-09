** Registos de Seguida

Function FeriasSeguida
    Select mCrsValores

    Select .F. as sel, colaborador from mCrsValores into Cursor mCrsFerias READWRITE

    Select mCrsFerias

    i = 2

    DECLARE LIST_TIT(i),LIST_CAM(i),LIST_TAM(i),LIST_PIC(i),LIST_RONLY(i),LIST_ROT(i),List_DyCurrControl(i)
    =CURSORSETPROP("BUFFERING",5,"mCrsFerias")

    i = 0
    i = i + 1    
    LIST_TIT(i) = "Selecionar"
    LIST_CAM(i) = "mCrsFerias.sel"
    LIST_RONLY(i) = .F.	
    LIST_PIC(i) = "LOGIC"
    LIST_TAM(i) = 8*10

    i = i + 1
    LIST_TIT(i) = "Nome do Dossier"
    LIST_CAM(i) = "mCrsFerias.Colaborador"
    LIST_RONLY(i) = .T.
    LIST_PIC(i) = ""
    LIST_TAM(i) = 8*30


    m.escolheu = .F.
    BROWLIST("Selecione os colaboradores","mCrsFerias","mCrsFerias",.T.,.F.,.F.,.T.,.F.,"",.T.,.T.)

    if m.escolheu = .T.
        LcUsrinis = m.m_chinis

        Create Cursor xvars ( no N(5), tipo c(1), Nome c(40), Pict c(100), lordem n(10), tbval m, nvalor N(18,5), cvalor c(250), mvalor m, lvalor l, dvalor d)

        Select xVars
        Append Blank
        Replace xVars.no With 1
        Replace xVars.tipo With "D"
        Replace xVars.Nome With "Data Inicial"
        Replace xVars.Pict With "##.##.####"
        Replace xVars.lOrdem With 1
        Replace xVars.dValor With DATE()

        Select xVars
        Append Blank
        Replace xVars.no With 2
        Replace xVars.tipo With "D"
        Replace xVars.Nome With "Data Final"
        Replace xVars.Pict With "##.##.####"
        Replace xVars.lOrdem With 2
        Replace xVars.dValor With DATE()

        m.mCaption = "Insira o período de férias a registar:"
        m.escolheu = .f.
        docomando("do form usqlvar with 'xvars',m.mCaption,.t.")

        if m.escolheu = .T.
            
            SELECT xvars
            LOCATE FOR no = 1
            LcDataI = xVars.dValor

            SELECT xvars
            LOCATE FOR no = 2
            LcDataF = xVars.dValor


            If PERGUNTA("Pretende prosseguir?",2,"",.T.) = .T.

                Select mCrsFerias
                GO TOP

                Scan for mCrsFerias.sel = .T.

                    lcColaborador = mCrsFerias.colaborador

                    TEXT TO MSELINSERTFP TEXTMERGE NOSHOW 
                        DECLARE @DATAI  DATE = '<<DTOC(LcDataI, 1)>>'
                        DECLARE @DATAF  DATE = '<<DTOC(LcDataF, 1)>>'
                        DECLARE @FUNCIONARIO VARCHAR(100) = '<<alltrim(lcColaborador)>>'
                        DECLARE @NUMERO INT
                        SET @NUMERO = LEFT(@FUNCIONARIO, CHARINDEX('.', @FUNCIONARIO) - 1);

                        ;WITH DiasUteis AS (
                            SELECT 
                                CAST(DATEADD(DAY, n, @DATAI) AS DATE) AS Dia
                            FROM (
                                SELECT TOP (DATEDIFF(DAY, @DATAI, @DATAF) + 1)
                                    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
                                FROM sys.all_objects
                            ) nums
                            WHERE 
                                DATEPART(WEEKDAY, DATEADD(DAY, n, @DATAI)) NOT IN (1, 7)
                                AND CAST(DATEADD(DAY, n, @DATAI) AS DATE) NOT IN (
                                    SELECT CAST(data AS DATE) 
                                    FROM FF
                                    WHERE 
                                        -- Feriado fixo: compara apenas mês e dia
                                        (fixo = 1 
                                            AND MONTH(data) = MONTH(DATEADD(DAY, n, @DATAI))
                                            AND DAY(data)   = DAY(DATEADD(DAY, n, @DATAI))
                                        )
                                        OR
                                        -- Feriado variável: compara data completa no(s) ano(s) em causa
                                        (fixo = 0 
                                            AND CAST(data AS DATE) = CAST(DATEADD(DAY, n, @DATAI) AS DATE)
                                            AND YEAR(data) IN (YEAR(@DATAI), YEAR(@DATAF))
                                        )
                                )
                        ),

                        PorMes AS (
                            SELECT
                                MONTH(Dia) AS pmes,
                                YEAR(Dia)  AS pano,
                                COUNT(*)   AS dias,
                                MIN(Dia)   AS datai_mes,
                                MAX(Dia)   AS dataf_mes
                            FROM DiasUteis
                            GROUP BY YEAR(Dia), MONTH(Dia)
                        )

                        INSERT INTO FP (fpstamp, no, datai, dataf, ano, dias, pmes, pano, pestamp, ousrinis, ousrdata, ousrhora, usrinis, usrdata, usrhora)
                        SELECT
                            LEFT(NEWID(), 25),
                            @NUMERO,
                            datai_mes,
                            dataf_mes,
                            YEAR(datai_mes),
                            dias,
                            pmes,
                            pano,
                            (SELECT pestamp from PE(nolock) where Pe.no = @NUMERO),
                            '<<LcUsrinis>>',
                            CAST(GETDATE() AS DATE),
                            CONVERT(VARCHAR(8), GETDATE(), 108),
                            '<<LcUsrinis>>',
                            CAST(GETDATE() AS DATE),
                            CONVERT(VARCHAR(8), GETDATE(), 108)
                        FROM PorMes
                        ORDER BY pano, pmes;
                    ENDTEXT
                    **msg(MSELINSERTFP)
                    
                    If !U_SQLEXEC(MSELINSERTFP)
                        msg("Erro ao registar férias do colaborador " + lcColaborador)
                        Return .F.
                    ENDIF
                    
                    Select mCrsFerias
                Endscan

                msg("Férias registadas com sucesso!")
                PDU_7ED0YCK3Z.MainGrid.Refresh()
                PDU_7ED0YCK3Z.Pageframe1.Page1.Procurar.click()
            else
                Return .f.
            ENDIF
        else
            Return .F.
        EndiF
    ENDIF
EndFunc