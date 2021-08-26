-- OSAGO ACCIDENTS FOR RENAISSANCE
grant select on public.sg_osago_policies_26_03_2021 to powerbi

SELECT 
	UPPER(vhcl.VIN) AS VIN
	, osg.policy_number AS OSAGO_policy_number
	, c1.accident_timestamp
	, c1.region
	, vhcl.brand
	, vhcl.model
--	, vhcl.platform
	, c1.accident_type
	, c1.guilty
	, c1.accident_registration_type
--	, usr.first_name
--	, usr.patronymic_name
--	, usr.last_name
FROM dma.accidents_1c c1
LEFT JOIN dds.T_Vehicle_InsuranceCompany ins ON ins.Vehicle_id = c1.Vehicle_id
LEFT JOIN dds.A_InsuranceCompany_Name ins_comp ON ins_comp.InsuranceCompany_id = ins.InsuranceCompany_id
LEFT JOIN dma.delimobil_vehicle vhcl ON vhcl.Vehicle_id = c1.Vehicle_id
LEFT JOIN dma.delimobil_user usr ON usr.user_id = c1.User_id
LEFT JOIN public.sg_osago_policies_26_03_2021 osg ON UPPER(osg.VIN) = UPPER(vhcl.VIN) AND c1.accident_timestamp BETWEEN osg.start_date AND COALESCE(osg.end_date, osg.termination_date)
WHERE (guilty = 'Виновен' OR guilty = 'Обоюдная вина') AND accident_type<>'Наезд на препятствие' /*AND accident_timestamp BETWEEN '2021-02-01' AND '2021-02-28'*/ AND osg.ins_comp = 'Ренессанс' AND c1.accident_type <> 'ДТП со скрытием'
ORDER BY accident_timestamp ASC