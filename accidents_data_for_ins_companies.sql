-- DATA FOR ROSENERGO (COUNT OF ACCIDENTS BY TYPE BY MODEL)
select date_trunc('month', c1.accident_timestamp)
--	   , vhcl.is_prime as Prime
	   , vhcl.brand
	   , vhcl.model
--	   , c1.accident_type 
	   , SUM(case when c1.guilty = 'Виновен' or c1.guilty = 'Обоюдная вина' then 1 ELSE 0 END) as count_guilty
	   , SUM(case when c1.guilty = 'Не виновен' then 1 ELSE 0 END) as count_not_guilty
	   , SUM(case when c1.guilty not in ('Виновен', 'Обоюдная вина', 'Не виновен') THEN 1 ELSE 0 END) AS count_others
from DMA.accidents_1c c1
left join DMA.delimobil_vehicle vhcl on vhcl.vehicle_id = c1.vehicle_id
where accident_timestamp BETWEEN  '2020-10-01' and '2020-11-30' and vhcl.is_prime = FALSE and c1.accident_type not in ('Иное', 'Наезд на препятствие', 'Наезд на пешехода')
group by 1,2,3
order by date_trunc('month', c1.accident_timestamp) asc, vhcl.brand, SUM(case when c1.guilty = 'Виновен' or c1.guilty = 'Обоюдная вина' then 1 ELSE 0 END) desc

-- DATA FOR RENAISSANCE (ALL ACCIDENTS INFO: VEHICLE, DRIVER ETC FOR SEPTEMBER AND OCTOBER)
select sop.ins_company
	   , c1.accident_timestamp 
	   , c1.region 
	   , REPLACE(UPPER(vhcl.VIN),' ','') as VIN
	   , vhcl.brand
	   , vhcl.model
	   , c1.guilty 
	   , c1.accident_registration_type 
	   , c1.accident_type 
	   , du.first_name 
	   , du.patronymic_name 
	   , du.last_name 
	   , du.sex 
	   , du.age 
	   , AGE_IN_YEARS(c1.accident_timestamp, du.license_set_date) as exp
from DMA.accidents_1c c1
left join DMA.delimobil_vehicle vhcl on vhcl.vehicle_id = c1.vehicle_id
left join DMA.delimobil_user du on du.user_id = c1.User_id 
left join public.sg_osago_policies sop on REPLACE(UPPER(sop.VIN),' ','') = REPLACE(UPPER(vhcl.VIN),' ','') and c1.accident_timestamp BETWEEN sop.policy_start and sop.policy_end 
where accident_timestamp BETWEEN  '2020-01-01' and '2020-03-31' and (c1.guilty = 'Виновен' or c1.guilty = 'Обоюдная вина') and (sop.ins_company = 'Ренессанс' or sop.ins_company is NULL)
order by c1.accident_timestamp

select date_trunc('month', accident_timestamp), insurance_type, count(*) 
from DMA.accidents_1c ac
where accident_timestamp BETWEEN '2020-01-01' and '2020-10-31' and guilty = 'Виновен'
group by date_trunc('month', accident_timestamp), insurance_type
order by date_trunc('month', accident_timestamp) asc, insurance_type
