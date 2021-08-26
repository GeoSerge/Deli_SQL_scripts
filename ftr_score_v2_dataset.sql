with loc as
	(select * from
		(select
			*
			, ROW_NUMBER() OVER(PARTITION BY PassportBirthPlace ORDER BY region asc) as rn
		from public.locations) cte
	where rn = 1)
select
	du.user_id 
	, du.user_ext 
	, TIMESTAMPDIFF('day', birthday, du.first_ride)/365.25 as age
	, TIMESTAMPDIFF('day', du.license_set_date, du.first_ride)/365.25 as exp
	, du.sex
	, RIGHT(LEFT(du.login,4),3) as phone_code
	, du.license_category 
	, du.birth_place
	, l.country
	, l.region 
	, l.city
	, (CASE
			WHEN aupn.PassportNumber IS NOT NULL AND aupn.PassportNumber <> '' AND LENGTH(REPLACE(REPLACE(aupn.PassportNumber, ' ', ''), '№', '')) <> 10 AND POSITION ('ФМС' IN aupd.PassportDepartment) < 1 THEN 'foreign'
			WHEN aupn.PassportNumber IS NULL OR aupn.PassportNumber = '' THEN 'NA'
			ELSE 'Russian'
	   END) AS passport_citizenship
	, aupn.PassportNumber
	, aupdc.PassportDepartmentCode 
	, aupr.PassportRegistration
from DMA.delimobil_user du
left join CDDS.A_User_PassportNumber aupn on aupn.User_id = du.user_id 
left join CDDS.A_User_PassportRegistration aupr on aupr.User_id = du.user_id
left join CDDS.A_User_PassportDepartmentCode aupdc on aupdc.User_id = du.user_id
left join CDDS.A_User_PassportDepartment aupd on aupd.User_id = du.user_id
left join loc l on l.PassportBirthPlace = du.birth_place 
where du.rides_count > 0 and du.first_ride < '2021-05-01'

-- Target data
select
	User_id
	, count(*)
from DMA.accidents_1c ac
left 
where guilty in ('Виновен', 'Обоюдная вина') and accident_timestamp < '2021-05-01'
group by 1