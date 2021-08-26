/*FOREIGNERS*/
CREATE TABLE public.sg_passport_citizenship AS
SELECT  
		du.user_id
		, (CASE
			WHEN pn.PassportNumber IS NOT NULL AND pn.PassportNumber <> '' AND LENGTH(REPLACE(REPLACE(pn.PassportNumber, ' ', ''), '╧', '')) <> 10 AND POSITION ('тля' IN pd.PassportDepartment) < 1 THEN 'foreign'
			WHEN pn.PassportNumber IS NULL OR pn.PassportNumber = '' THEN 'NA'
			ELSE 'Russian'
		  END) AS passport_citizenship
FROM DMA.delimobil_user du 
LEFT JOIN CDDS.A_User_PassportNumber pn on pn.User_id = du.user_id 
LEFT JOIN CDDS.A_User_PassportDepartment pd on pd.User_id = du.user_id 
LEFT JOIN CDDS.A_User_PassportDepartmentCode pdc on pdc.User_id = du.user_id