select
	date_trunc('day', dr."Start")
	, dr.user_ext 
	, du.first_name
	, du.patronymic_name 
	, du.last_name 
	, sum(fuel_rub) as fuel_cost
	, sum(ride_time) as ride_time
from DMA.delimobil_rent dr 
left join DMA.delimobil_user du on du.user_id = dr.user_id 
where dr.user_ext in (24287022, 22525785, 25262, 30603484) and dr."Start" > '2021-01-01'
group by 2,3,4,5,1
order by 2,1