** Grid Vendedores

SET DATE DMY
SET MARK TO "."

lcDataI    = PDU_7EZ0QTRJD.flddatai.value
lcDataF    = PDU_7EZ0QTRJD.flddataf.value
lcOP       = PDU_7EZ0QTRJD.fldproducao.value
lcEncomenda = PDU_7EZ0QTRJD.fldencomenda.value
lcVendedor = PDU_7EZ0QTRJD.fldvendedor.value
lcCliente  = PDU_7EZ0QTRJD.fldcliente.value
lcordem    = PDU_7EZ0QTRJD.Pageframe1.Page1.Ordenacao.Value

IF USED('mCrsValoresCM3')
    USE IN mCrsValoresCM3
ENDIF
SELECT 0

TEXT TO MselTotaisVendedor TEXTMERGE NOSHOW
    DECLARE @DATAI as DATE
    DECLARE @DATAF as DATE
    SET @DATAI = CONVERT(date,'<<lcDataI>>',104)
    SET @DATAF = CONVERT(date,'<<lcDataF>>',104)

    DECLARE @CLIENTE as VARCHAR(60)
    SET @CLIENTE = '%<<ALLTRIM(lcCliente)>>%'

    DECLARE @ENCOMENDA as VARCHAR(60)
    SET @ENCOMENDA = '%<<ALLTRIM(lcEncomenda)>>%'

    DECLARE @OP as VARCHAR(60)
    SET @OP = '%<<ALLTRIM(lcOP)>>%'

    DECLARE @VENDEDOR as VARCHAR(60)
    SET @VENDEDOR = '%<<ALLTRIM(lcVendedor)>>%'

    DECLARE @ORDEM AS VARCHAR(1)
    SET @ORDEM = '<<ASTR(lcordem)>>';

    WITH Vab AS (
        SELECT * FROM u_Vab_2026
        WHERE fdata >= @DATAI AND fdata <= @DATAF
        AND nome LIKE @CLIENTE
        AND encomenda LIKE @ENCOMENDA
        AND obrano LIKE @OP
        AND VendNM LIKE @VENDEDOR
    )
    , Fts AS (
        SELECT ft.ftstamp, ft.nmdoc, ft.fno, ft.ftano, ft.fdata,
               fi.fistamp, fi.design, fi.ref, fi.unidade, fi.qtt,
               fi.epv, fi.etiliquido, fi.ofistamp,
               fi.u_epvun, fi.uni2qtt, fi.unidad2
        FROM FI (NOLOCK)
        INNER JOIN FT (NOLOCK) ON FT.ftstamp = FI.ftstamp
        WHERE FT.ndoc = 23
        AND FT.fdata >= @DATAI AND FT.fdata <= @DATAF
        AND ofistamp IN (SELECT fistamp FROM Vab)
    )
    , QFinal AS (
        SELECT a.documento, a.nome,
               b.nmdoc + ' ' + CONVERT(varchar,b.fno) + '/' + CONVERT(varchar,b.ftano) AS ftdoc,
               a.encomenda, a.opno, a.Design, a.lote, a.Acabamento,
               b.unidade, a.vendedor, a.VendNm, a.CorAcabamento, a.epv,
               b.u_epvun, b.unidad2, b.uni2qtt, a.etiliquido,
               b.u_epvun * b.uni2qtt AS etiliquidoun,
               a.Custo_Lote, a.Custo_Acabamento, a.perda,
               a.Real_PercPerda, a.Real_ProduzidaKG, a.Real_EnviadaKG,
               b.qtt, a.Real_Custo_perda, a.custos_perda,
               a.custos_fio, a.custo_total, a.u_vabPercentagem, a.u_vabValor,
               CAST((b.u_epvun * b.uni2qtt) - custo_total AS decimal(12,2)) AS ValorVABFt,
               CAST((((b.u_epvun * b.uni2qtt) - custo_total) * 100) / (b.u_epvun * b.uni2qtt) AS decimal(12,2)) AS ValorVABPercFt
        FROM Vab a LEFT JOIN Fts b ON b.ofistamp = a.fistamp
    )
    SELECT * FROM (
        SELECT CAST(SUM(Real_EnviadaKG) AS DECIMAL(12,2)) AS QuantidadeKG,
               CAST(SUM(ISNULL(etiliquidoun, etiliquido)) AS DECIMAL(12,2)) AS ValorTotal,
               CAST((SUM(ISNULL(ValorVABFt, u_vabValor)) * 100.0) /
                    NULLIF(SUM(ISNULL(etiliquidoun, etiliquido)), 0) AS DECIMAL(12,2)) AS PercentagemVAB,
               SUM(ISNULL(ValorVABFt, u_vabValor)) AS EuroVAB,
               VendNm AS Vendedor
        FROM QFinal GROUP BY VendNm
    ) x
    ORDER BY
        CASE WHEN @ORDEM = '1' THEN PercentagemVAB END DESC,
        CASE WHEN @ORDEM = '2' THEN EuroVAB END DESC,
        CASE WHEN @ORDEM = '3' THEN QuantidadeKG END DESC,
        CASE WHEN @ORDEM = '4' THEN ValorTotal END DESC
ENDTEXT

**msg(MselTotaisVendedor)

IF !u_sqlexec(MselTotaisVendedor, "mCrsValoresCM3")
    MSG("Erro no cursor Vendedor.")
    RETURN
ENDIF

IF USED('mCrsValoresCM3')
    SELECT mCrsValoresCM3
    GO TOP
ENDIF