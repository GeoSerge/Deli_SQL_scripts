-- ACCIDENTS BY PLATFORM, REGION, VEHICLE MODEL, RESPONSIBILITY
select vhcl.is_prime, (case when vhcl.region_name_en = 'Moscow' then vhcl.region_name_en else 'Other' end) as region, vhcl.brand, vhcl.model
	   ,  sum(case when c1.guilty = 'Виновен' or c1.guilty = 'Обоюдная вина' then 1 else 0 end) as guilty
	   ,  sum(case when c1.guilty = 'Не виновен' then 1 else 0 end) as not_guilty
from dma.accidents_1c c1
left join dma.delimobil_vehicle vhcl on vhcl.Vehicle_id = c1.Vehicle_id
where accident_timestamp between '2019-07-01' and '2020-06-30' and vhcl.is_pool = FALSE
group by vhcl.is_prime, (case when vhcl.region_name_en = 'Moscow' then vhcl.region_name_en else 'Other' end), vhcl.brand, vhcl.model
order by vhcl.is_prime, (case when vhcl.region_name_en = 'Moscow' then vhcl.region_name_en else 'Other' end), vhcl.brand, vhcl.model