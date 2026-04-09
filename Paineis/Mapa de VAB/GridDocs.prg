** Grid Docs

SET DATE DMY
SET MARK TO "."

lcDataI    = PDU_7EZ0QTRJD.flddatai.value
lcDataF    = PDU_7EZ0QTRJD.flddataf.value
lcOP       = PDU_7EZ0QTRJD.fldproducao.value
lcEncomenda = PDU_7EZ0QTRJD.fldencomenda.value
lcVendedor = PDU_7EZ0QTRJD.fldvendedor.value
lcCliente  = PDU_7EZ0QTRJD.fldcliente.value

IF USED('CrsLinhasDocs')
    USE IN CrsLinhasDocs
ENDIF
SELECT 0

TEXT TO MselDocs TEXTMERGE NOSHOW
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
    SET @VENDEDOR = '%<<ALLTRIM(lcVendedor)>>%';

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
        SELECT CONVERT(varchar, a.documento) AS documento,
            CASE 
                    WHEN b.nmdoc IS NOT NULL AND b.fno IS NOT NULL AND b.ftano IS NOT NULL
                    THEN b.nmdoc + ' ' + CONVERT(varchar,b.fno) + '/' + CONVERT(varchar,b.ftano)
                    ELSE NULL
                END AS ftdoc,
            a.encomenda, a.opno, a.Design, a.lote, a.Acabamento,
            b.unidade, a.CorAcabamento, a.epv,
            b.u_epvun, b.unidad2, b.uni2qtt, a.etiliquido,
            b.u_epvun * b.uni2qtt AS etiliquidoun,
            a.Custo_Lote, a.Custo_Acabamento, a.perda,
            a.Real_PercPerda, a.Real_ProduzidaKG, a.Real_EnviadaKG,
            b.qtt, a.Real_Custo_perda, a.custos_perda,
            a.custos_fio, a.custo_total, a.u_vabPercentagem, a.u_vabValor,
            (Select ftstamp from FI(nolock) where FI.fistamp = a.fistamp) as 'fistamp', b.ftstamp, a.bistamp,
            CAST((b.u_epvun * b.uni2qtt) - custo_total AS decimal(12,2)) AS ValorVABFt,
            CAST((((b.u_epvun * b.uni2qtt) - custo_total) * 100) / (b.u_epvun * b.uni2qtt) AS decimal(12,2)) AS ValorVABPercFt
        FROM Vab a LEFT JOIN Fts b ON b.ofistamp = a.fistamp
    )
    SELECT ISNULL(ftdoc, documento) AS documento,
        isnull(ftstamp, fistamp) as 'ftstamp', (Select bostamp from BI(Nolock) where BI.bistamp = QFinal.bistamp) as bostamp,
        encomenda, opno, design, lote, CorAcabamento,
        ISNULL(u_epvun, epv) AS epv,
        ISNULL(etiliquidoun, etiliquido) AS total,
        custo_lote, Custo_Acabamento, perda,
        Real_PercPerda, Real_ProduzidaKG, Real_EnviadaKG,
        Real_Custo_perda, custos_perda, custos_fio, custo_total,
        ISNULL(valorvabpercft, u_vabPercentagem) AS percvab,
        ISNULL(ValorVABFt, u_vabValor) AS valorvab
    FROM QFinal
    ORDER BY documento, CorAcabamento
ENDTEXT

IF !u_sqlexec(MselDocs, "CrsLinhasDocs")
    MSG("Erro no cursor Docs.")
    RETURN
ENDIF

IF USED('CrsLinhasDocs')
    SELECT CrsLinhasDocs
    GO TOP
ENDIF