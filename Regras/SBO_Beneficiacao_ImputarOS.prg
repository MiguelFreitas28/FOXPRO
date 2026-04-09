
Select BO
IF BO.ndos = 23
	Select BI
	GO TOP
	TEXT TO MSELCheckNDOS TEXTMERGE NOSHOW 
		SELECT 
			MAX(SUBSTRING(design, CHARINDEX('nº', design) + 3, 
				PATINDEX('%[^0-9]%', SUBSTRING(design, CHARINDEX('nº', design) + 3, LEN(design)) + ' ') - 1)
			) AS FNO,
			MAX(oobistamp) AS oobistamp
		FROM BI (NOLOCK)
		where BI.bostamp = '<<alltrim(BI.bostamp)>>'
	ENDTEXT
	**msg(MSELCheckNDOS)
	If U_SQLEXEC(MSELCheckNDOS,"CrsNDOS") And Reccount("CrsNDOS") > 0
		Select CrsNDOS
		LcOBRANO = CrsNDOS.FNO
		LcStamp = CrsNDOS.oobistamp

		TEXT TO MSELCheckOS TEXTMERGE NOSHOW 
			SELECT
			top 1
				bi.ForRef as 'OS'
				, LTRIM(STR(boEnc.obrano))+'/'+LTRIM(STR(BoEnc.boAno)) as 'encomenda'
			from u_OprodRevAcab (NOLOCK)
			Inner join bi  (NOLOCK) on bi.bistamp =u_OprodRevAcab.RecStamp
			Left outer join bi biEnc (NOLOCK) on biEnc.bistamp = u_OprodRevAcab.bistamp
			Left outer join bo boEnc (NOLOCK) on biEnc.bostamp = boEnc.bostamp 
			where 
			u_OprodRevAcab.u_Oprodbistamp='<<alltrim(LcStamp)>>'
			and bi.obrano = '<<LcOBRANO>>'
		ENDTEXT
		**msg(MSELCheckOS)
		If U_SQLEXEC(MSELCheckOS,"CrsOS") And Reccount("CrsOS") > 0
			Select CrsOS
			LcOS = CrsOS.OS

			Select BI
			GO TOP
			Scan
				IF !empty(BI.ref)
					Replace BI.u_OS with alltrim(LcOS)
				ENDIF
			EndScan
		ENDIF
	ENDIF
ENDIF

