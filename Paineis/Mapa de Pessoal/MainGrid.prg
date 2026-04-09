**Força preenchimento de alguns campos 
if empty(m.ObjRecebido.Janela.pageframe1.page1.FldAno.value)
    m.ObjRecebido.Janela.pageframe1.page1.FldAno.value=year(date())
endif 

if empty(m.ObjRecebido.Janela.pageframe1.page1.FldMes.value)
    m.ObjRecebido.Janela.pageframe1.page1.FldMes.value=month(date())
endif 

**Guarda em variávies valores dos filtros 

mDepartamento = m.ObjRecebido.Janela.pageframe1.page1.FldDepartamento.value
mLocal = m.ObjRecebido.Janela.pageframe1.page1.FldLocalTrabalho.value

mAno = m.ObjRecebido.Janela.pageframe1.page1.FldAno.value
mMes = m.ObjRecebido.Janela.pageframe1.page1.FldMes.value

musername = m.m_chnome
mUsnoopen = alltrim(astr(m.ch_userno))

text to MselCheckValores textmerge noshow 
    DECLARE @Ano int = <<mAno>>;
    DECLARE @Mes int = <<mMes>>;
    DECLARE @Departamento VARCHAR(100) = '<<alltrim(mDepartamento)>>';
    DECLARE @Local VARCHAR(100) = '<<alltrim(mLocal)>>';

    DECLARE @DtIni date = DATEFROMPARTS(@Ano,@Mes,1);
    DECLARE @DtFim date = EOMONTH(@DtIni);
    DECLARE @Dias int = DAY(@DtFim);

    DECLARE @cols nvarchar(max) = '';
    DECLARE @cols_isnull nvarchar(max) = '';
    DECLARE @sql  nvarchar(max) = '';

    ;WITH d AS (
        SELECT TOP (31)
            RIGHT('00'+CAST(ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS varchar),2) dia
        FROM sys.all_objects
    )
    SELECT @cols = STRING_AGG(QUOTENAME('D' + dia), ',')
    FROM d;

    ;WITH d AS (
        SELECT TOP (31)
            RIGHT('00'+CAST(ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS varchar),2) dia
        FROM sys.all_objects
    )
    SELECT @cols_isnull = STRING_AGG(
        'ISNULL(' + QUOTENAME('D' + dia) + ', ''NE'') AS ' + QUOTENAME('D' + dia),
        ','
    )
    FROM d;

    SET @sql = '
    SELECT Colaborador, Departamento, Local, ' + @cols_isnull + '
    FROM (
        SELECT
            Colaborador,
            Departamento,
            Local,
            ''D'' + RIGHT(''00''+CAST(DAY(data) AS varchar),2) AS Dia,
            LabelHTML
        FROM dbo.fn_MapaFaltas(@Ano,@Mes)
        WHERE (@Departamento = '''' OR Departamento LIKE ''%'' + @Departamento + ''%'')
        AND (@Local = '''' OR Local LIKE ''%'' + @Local + ''%'')
    ) src
    PIVOT (
        MAX(LabelHTML)
        FOR Dia IN (' + @cols + ')
    ) p
    ORDER BY TRY_CONVERT(int,
            LEFT(Colaborador, CHARINDEX(''.'', Colaborador + ''.'') - 1));
    ';

    EXEC sp_executesql
        @sql,
        N'@Ano int, @Mes int, @Departamento varchar(100), @Local varchar(100)',
        @Ano, @Mes, @Departamento, @Local;
endtext

if m.ch_userno=1
    *msg(MselCheckValores)
endif 

if !u_sqlexec(MselCheckValores,"mCrsValores")
    msg("Erro na instrução do select. Pff contacte a assistência técnica.")
    return 
endif 

mTotal = 0
LcNumMovimentos = 0

Go top
mContador=reccount()

if mContador=0
    msg("Não encontrei registos para apresentar.")
    return 
endif

Select mCrsValores
GO BOTTOM

SELECT mCrsValores
GO TOP

PintarGridAuto()

FUNCTION PintarGridAuto
    LOCAL oGrid, oCol, i, cCampo
    oGrid = PDU_7ED0YCK3Z.MainGrid
    oGrid.SetAll("Sparse", .F., "Column")

    FOR i = 1 TO 31
        cCampo = "D" + RIGHT("00" + ALLTRIM(STR(i)), 2)
        oCol = oGrid.Columns(i + 4)
        TRY
            oCol.DynamicBackColor = ;
                "IIF(AT('NE', NVL(mCrsValores." + cCampo + ",''))>0, RGB(0,0,0), " + ;
                "IIF(AT('FS', NVL(mCrsValores." + cCampo + ",''))>0, RGB(200,200,200), " + ;
                "IIF(AT('FR', NVL(mCrsValores." + cCampo + ",''))>0, RGB(173,216,230), " + ;
                "IIF(AT('FE', NVL(mCrsValores." + cCampo + ",''))>0, RGB(100,255,100), " + ;
                "IIF(AT('FA', NVL(mCrsValores." + cCampo + ",''))>0, RGB(255,100,100), " + ;
                "RGB(255,255,255))))))"
            oCol.DynamicForeColor = ;
                "IIF(AT('NE', NVL(mCrsValores." + cCampo + ",''))>0, RGB(0,0,0), RGB(0,0,0))"
        CATCH TO oErr
            msg("Erro " + cCampo + ": " + oErr.Message)
        ENDTRY
    NEXT

    oGrid.Refresh()
ENDFUNC

Function CheckFerias
    Select mCrsValores

    TEXT TO CheckFeriasFaltas TEXTMERGE NOSHOW 
        DECLARE @ANO INT = <<mAno>>
        DECLARE @FUNCIONARIO VARCHAR(100) = '<<alltrim(mCrsValores.colaborador)>>'
        DECLARE @NUMERO INT

        SET @NUMERO = LEFT(@FUNCIONARIO, CHARINDEX('.', @FUNCIONARIO) - 1);

        WITH Func AS
        (
            SELECT
                PE.no,
                PE2.holidays,
                PE2.diasextra,
                YEAR(PE.dataadm)  AS AnoAdmissao,
                MONTH(PE.dataadm) AS MesAdmissao
            FROM PE2 (NOLOCK)
            JOIN PE  (NOLOCK) ON PE.pestamp = PE2.pe2stamp
            WHERE PE.no = @NUMERO
        ),

        Direitos AS
        (
            SELECT
                *,
                -- férias do ano atual
                CASE
                    WHEN AnoAdmissao = @ANO THEN
                        CASE 
                            WHEN (12 - MesAdmissao + 1) * 2 > 20 THEN 20
                            ELSE (12 - MesAdmissao + 1) * 2
                        END
                    ELSE holidays
                END AS FeriasAtual,

                -- limite do ano anterior (CORRIGIDO)
                CASE
                    WHEN AnoAdmissao >= @ANO THEN 0   -- ainda não trabalhava
                    WHEN AnoAdmissao = @ANO - 1 THEN
                        CASE 
                            WHEN (12 - MesAdmissao + 1) * 2 > 20 THEN 20
                            ELSE (12 - MesAdmissao + 1) * 2
                        END
                    ELSE 22
                END AS LimiteAnoAnterior
            FROM Func
        ),

        Faltas AS
        (
            SELECT COUNT(*) AS numfaltas
            FROM HS (NOLOCK)
            WHERE no = @NUMERO
            AND YEAR(data) = @ANO
            AND ntipo = 2
        ),

        FeriasGozadas AS
        (
            SELECT
                SUM(CASE WHEN ano = @ANO     THEN dias ELSE 0 END) AS GozadasAtual,
                SUM(CASE WHEN ano = @ANO - 1 THEN dias ELSE 0 END) AS GozadasAnterior
            FROM FP (NOLOCK)
            WHERE no = @NUMERO
        )

        SELECT
            ISNULL(F.numfaltas,0) AS Faltas,

            ISNULL(
                CASE
                    WHEN FG.GozadasAnterior >= D.LimiteAnoAnterior THEN 0
                    ELSE D.LimiteAnoAnterior - FG.GozadasAnterior
            END,0) AS AnoAnteriorPorMarcar,

            ISNULL(D.FeriasAtual,0) AS Atual,

            ISNULL(D.diasextra,0) AS Extra,

            ISNULL(FG.GozadasAtual,0) AS Marcados,

            ISNULL(
                D.FeriasAtual
                + D.diasextra
                + CASE
                    WHEN FG.GozadasAnterior >= D.LimiteAnoAnterior THEN 0
                    ELSE D.LimiteAnoAnterior - FG.GozadasAnterior
                END
                - FG.GozadasAtual
                ,0) AS PorMarcar
        FROM Direitos D
        CROSS JOIN Faltas F
        CROSS JOIN FeriasGozadas FG;
    ENDTEXT
    if m.ch_userno=1
        *msg(CheckFeriasFaltas)
    endif 
    
    If U_SQLEXEC(CheckFeriasFaltas,"CrsFFH") And Reccount("CrsFFH") > 0
        Select CrsFFH
        PDU_7ED0YCK3Z.Pageframe1.Page1.LblNomeFuncionario.Caption = alltrim(mCrsValores.colaborador)

        PDU_7ED0YCK3Z.Pageframe1.Page1.LblFaltas.Caption = astr(CrsFFH.Faltas)
        PDU_7ED0YCK3Z.Pageframe1.Page1.LBLDIASFERIASANTERIORES.Caption = astr(CrsFFH.AnoAnteriorPorMarcar)
        PDU_7ED0YCK3Z.Pageframe1.Page1.LblDiasFeriasAtual.Caption = astr(CrsFFH.Atual)
        PDU_7ED0YCK3Z.Pageframe1.Page1.LBLDIASFERIASEXTRA.Caption = astr(CrsFFH.Extra)
        PDU_7ED0YCK3Z.Pageframe1.Page1.LblMarcados.Caption = astr(CrsFFH.Marcados)
        PDU_7ED0YCK3Z.Pageframe1.Page1.LblPorMarcar.Caption = astr(CrsFFH.PorMarcar)
    ENDIF
EndFunc