** Funções em singular

Function GiveExtraDays
    Select mCrsValores

    IF PDU_7ED0YCK3Z.Pageframe1.Page1.LblNomeFuncionario.Caption <> "."

        Create Cursor xvars ( no N(5), tipo c(1), Nome c(40), Pict c(100), lordem n(10), tbval m, nvalor N(18,5), cvalor c(250), mvalor m, lvalor l, dvalor d)

        Select xVars
        Append Blank
        Replace xVars.no With 1
        Replace xVars.tipo With "C"
        Replace xVars.Nome With "Nº de dias a conceder:"
        Replace xVars.Pict With ""
        Replace xVars.lOrdem With 1
        Replace xVars.cValor With ""


        m.mCaption = "Preencha os campos por favor:"
        m.escolheu = .f.
        docomando("do form usqlvar with 'xvars',m.mCaption,.t.")

        if m.escolheu = .T.
            
            SELECT xvars
            LOCATE FOR no = 1
            lc_dias = xVars.cValor

            If PERGUNTA("Pretende prosseguir?",2,"Irá conceder " + alltrim(lc_dias) + " dia(s) extra de férias a " + mCrsValores.colaborador,.T.) = .T.
                TEXT TO MSELUPDATEPE2 TEXTMERGE NOSHOW 
                    DECLARE @FUNCIONARIO VARCHAR(100) = '<<alltrim(mCrsValores.colaborador)>>'
                    DECLARE @NUMERO INT
                    SET @NUMERO = LEFT(@FUNCIONARIO, CHARINDEX('.', @FUNCIONARIO) - 1);

                    UPDATE PE2
                    set PE2.diasextra = '<<alltrim(lc_dias)>>'
                    from PE2(Nolock)
                    inner join PE(nolock) on PE.pestamp = PE2.pe2stamp
                    where PE.no = @NUMERO
                ENDTEXT
                *msg(MSELUPDATEPE2)
                
                If U_SQLEXEC(MSELUPDATEPE2)
                    msg("Dias extra concedidos com sucesso.")
                    PDU_7ED0YCK3Z.MainGrid.Refresh()
                    CheckFerias()
                else
                    msg("ERROR: " + MSELUPDATEPE2)
                    Return .f.
                ENDIF
            ENDIF
        else
            Return .F.
        Endif

        If empty(lc_dias)
            return .f.
        ENDIF
    else
        msg("Não tem nenhum colaborador selecionado")
    ENDIF

Endfunc

Function MarcarFerias
    Select mCrsValores

    IF PDU_7ED0YCK3Z.Pageframe1.Page1.LblNomeFuncionario.Caption <> "."
        lcColaborador = mCrsValores.colaborador
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

            If PERGUNTA("Pretende prosseguir?",2,"Irá registar dia(s) de férias a " + lcColaborador,.T.) = .T.
            
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
                
                If U_SQLEXEC(MSELINSERTFP)
                    msg("Dias de férias registados com sucesso.")
                    PDU_7ED0YCK3Z.MainGrid.Refresh()
                    PDU_7ED0YCK3Z.Pageframe1.Page1.Procurar.click()
                    CheckFerias()
                else
                    msg("Erro ao registar férias.")
                    Return .F.
                ENDIF
            else
                Return .f.
            ENDIF
        else
            Return .F.
        Endif
    else
        msg("Não tem nenhum colaborador selecionado")
    ENDIF
Endfunc

Function VerFerias

    Select mCrsValores
    
    IF PDU_7ED0YCK3Z.Pageframe1.Page1.LblNomeFuncionario.Caption <> "."
        TEXT TO MSELCheckFerias TEXTMERGE NOSHOW 
            DECLARE @colaborador VARCHAR(200) = '<<alltrim(mCrsValores.Colaborador)>>'

            SELECT 
                Convert(varchar, datai, 105) AS datai,
                Convert(varchar, dataf, 105) AS dataf,
                Convert(varchar, dias) as dias
            FROM FP(NOLOCK) 
            WHERE ano = 2026
            AND no = REPLACE(LTRIM(RTRIM(LEFT(@colaborador, CHARINDEX('.', @colaborador) - 1))), ' ', '')

            UNION ALL SELECT '', '', ''  -- linha em branco

            UNION ALL
            SELECT 
                'TOTAL',
                '',
                convert(varchar, SUM(dias)) as dias
            FROM FP(NOLOCK) 
            WHERE ano = 2026
            AND no = REPLACE(LTRIM(RTRIM(LEFT(@colaborador, CHARINDEX('.', @colaborador) - 1))), ' ', '')
        ENDTEXT

        If U_SQLEXEC(MSELCheckFerias,'CrsFerias')
            Select CrsFerias
            i = 3

            DECLARE LIST_TIT(i),LIST_CAM(i),LIST_TAM(i),LIST_PIC(i),LIST_RONLY(i),LIST_ROT(i),List_DyCurrControl(i)
            =CURSORSETPROP("BUFFERING",5,"CrsFerias")

            i = 0
            i = i + 1    
            LIST_TIT(i) = "Data Inicial"
            LIST_CAM(i) = "CrsFerias.datai"
            LIST_RONLY(i) = .F.	
            LIST_PIC(i) = ""
            LIST_TAM(i) = 8*10

            i = i + 1
            LIST_TIT(i) = "Data Final"
            LIST_CAM(i) = "CrsFerias.dataf"
            LIST_RONLY(i) = .T.
            LIST_PIC(i) = ""
            LIST_TAM(i) = 8*12

            i = i + 1
            LIST_TIT(i) = "Nº de Dias"
            LIST_CAM(i) = "CrsFerias.Dias"
            LIST_RONLY(i) = .T.
            LIST_PIC(i) = ""
            LIST_TAM(i) = 8*10

            BROWLIST("Registo de Férias de " + astr(mAno) + " do colaborador " + alltrim(mCrsValores.Colaborador),"CrsFerias","CrsFerias",.T.,.F.,.F.,.T.,.F.,"",.T.,.T.)
            
        else
            msg("ERROR: " + MSELCheckFerias)
            Return .f.
        ENDIF
    else
        msg("Não tem nenhum colaborador selecionado")
    ENDIF    
EndFunc

Function RegistarFaltas
    Select mCrsValores
    
    IF PDU_7ED0YCK3Z.Pageframe1.Page1.LblNomeFuncionario.Caption <> "."
        lcColaborador = mCrsValores.colaborador
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

        Select xVars
        Append Blank
        Replace xVars.no With 3
        Replace xVars.tipo With "Q"
        Replace xVars.Nome With "Tipo de Falta"
        Replace xVars.Pict With ""
        Replace xVars.lOrdem With 3
        Replace xVars.tbval With "Select distinct(tydescricao) from HS(nolock) where ntipo = 2 and tyfalta in (2,3,5,6,4,1,7) order by tydescricao"

        Select xVars
        Append Blank
        Replace xVars.no With 4
        Replace xVars.tipo With "L"
        Replace xVars.Nome With "Falta Justificada"
        Replace xVars.Pict With ""
        Replace xVars.lOrdem With 4
        Replace xVars.lvalor With .F.

        Select xVars
        Append Blank
        Replace xVars.no With 5
        Replace xVars.tipo With "L"
        Replace xVars.Nome With "Perde Subs. Refeição"
        Replace xVars.Pict With ""
        Replace xVars.lOrdem With 5
        Replace xVars.lvalor With .F.

        m.mCaption = "Preencha os dados da falta:"
        m.escolheu = .f.
        docomando("do form usqlvar with 'xvars',m.mCaption,.t.")

        if m.escolheu = .T.
            
            SELECT xvars
            LOCATE FOR no = 1
            LcDataI = xVars.dValor

            SELECT xvars
            LOCATE FOR no = 2
            LcDataF = xVars.dValor

            SELECT xvars
            LOCATE FOR no = 3
            LcTipo = xVars.cValor

            SELECT xvars
            LOCATE FOR no = 4
            LcJust = xVars.lValor

            SELECT xvars
            LOCATE FOR no = 5
            LcSubs = xVars.lValor

            If PERGUNTA("Pretende prosseguir?",2,"Irá registar faltas ao colaborador " + lcColaborador,.T.) = .T.
            
                TEXT TO MSELINSERTHS TEXTMERGE NOSHOW 
                    DECLARE @DATAI DATE = '<<DTOC(LcDataI, 1)>>'
                    DECLARE @DATAF DATE = '<<DTOC(LcDataF, 1)>>'
                    DECLARE @TIPO VARCHAR(100) = '<<alltrim(LcTipo)>>'
                    DECLARE @TYFALTA INT
                    DECLARE @JUST INT = IIF('<<LcJust>>' = '.T.', 1, 0)
                    DECLARE @PERDESR INT = IIF('<<LcSubs>>' = '.T.', 1, 0)
                    DECLARE @FUNCIONARIO VARCHAR(100) = '<<alltrim(lcColaborador)>>'
                    DECLARE @NUMERO INT
                    SET @NUMERO = LEFT(@FUNCIONARIO, CHARINDEX('.', @FUNCIONARIO) - 1);

                    Select top 1 @TYFALTA = tyfalta from HS(Nolock) where tydescricao = @TIPO

                    ;WITH TodosOsDias AS (
                        SELECT 
                            CAST(DATEADD(DAY, n, @DATAI) AS DATE) AS Dia
                        FROM (
                            SELECT TOP (DATEDIFF(DAY, @DATAI, @DATAF) + 1)
                                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
                            FROM sys.all_objects
                        ) nums
                    )
                    INSERT INTO HS (hsstamp, no, nome, data, ntipo1, ntipo, desconta, just, refe, fdia, ccusto, tyfalta, tydescricao, pctdia, ousrinis, ousrdata, ousrhora, usrinis, usrdata, usrhora)
                    SELECT
                        LEFT(NEWID(), 25)                                           AS hsstamp,
                        @NUMERO                                                     AS no,
                        (SELECT nome FROM PE (NOLOCK) WHERE PE.no = @NUMERO)        AS nome,
                        Dia                                                         AS data,
                        'Faltas'                                                    AS ntipo1,
                        2                                                           AS ntipo,
                        1                                                           AS desconta,
                        @JUST                                                       AS just,
                        @PERDESR                                                    AS refe,
                        1                                                           AS fdia,
                        'TEC_PESSOAL'                                               AS ccusto,
                        @TYFALTA                                                    AS tyfalta,
                        @TIPO                                                       AS tydescricao,
                        100                                                         AS pctdia,
                        '<<LcUsrinis>>'                                             AS ousrinis,
                        CAST(GETDATE() AS DATE)                                     AS ousrdata,
                        CONVERT(VARCHAR(8), GETDATE(), 108)                         AS ousrhora,
                        '<<LcUsrinis>>'                                             AS usrinis,
                        CAST(GETDATE() AS DATE)                                     AS usrdata,
                        CONVERT(VARCHAR(8), GETDATE(), 108)                         AS usrhora
                    FROM TodosOsDias
                    ORDER BY Dia;
                ENDTEXT

                If U_SQLEXEC(MSELINSERTHS)
                    msg("Faltas registadas com sucesso.")
                    PDU_7ED0YCK3Z.MainGrid.Refresh()
                    PDU_7ED0YCK3Z.Pageframe1.Page1.Procurar.click()
                    CheckFerias()
                else
                    msg("Erro ao registar faltas.")
                    Return .F.
                ENDIF
            else
                Return .f.
            ENDIF
        else
            Return .F.
        Endif
    else
        msg("Não tem nenhum colaborador selecionado")
    ENDIF

EndFunc