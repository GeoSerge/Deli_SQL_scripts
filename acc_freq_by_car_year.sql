/*CAR YEAR ANALYSIS*/
select avcy.ConstructionYear
	, sum(case when ac.accident_timestamp is not null and ac.guilty in ('Виновен', 'Обоюдная вина') then 1 else 0 end)*1000000/sum(ride_time) as acc_freq
	, sum(case when ac.accident_timestamp is not null and ac.guilty in ('Виновен', 'Обоюдная вина') then order_sum else 0 end)/sum(ride_time) as repairs_per_min
	, sum(ride_time) as ride_time
	, count(DISTINCT(dr.vehicle_id))
from DMA.delimobil_rent dr 
left join DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
left join CDDS.A_Vehicle_ConstructionYear avcy on avcy.Vehicle_id = dr.vehicle_id 
where dr.rent_region_en = 'Moscow' and dr.Model in ('Polo', 'Polo VI', 'Polo ECO') and avcy.ConstructionYear is not null and dr."Start" BETWEEN '2020-07-01' and '2021-01-01'
group by 1
order by 1 asc

/*DISTRIBUTION OF CARS BY REGIONS*/
select region_name_en, model, count(*)
from DMA.delimobil_vehicle dv 
group by 1,2
order by 1,2 desc

/**/
WITH slct AS
(select 
	ROW_NUMBER() OVER (PARTITION by Vehicle_id ORDER BY Actual_dtime asc) rn
	,*
from DDS.T_Vehicle_Region tvr),
vhcl_rgn as
(select
	Actual_dtime as from_dtime
	, IFNULL(LEAD(Actual_dtime) over (PARTITION by Vehicle_id order by Actual_dtime asc), CURRENT_DATE()) as to_dtime
	, Region_id 
from DDS.T_Vehicle_Region tvr 
order by Vehicle_id, Actual_dtime asc)
select slct.Vehicle_id, slct.rn, min(actual_dtime), max(actual_dtime), LAG(Actual_dtime) over (PARTITION by slct.vehicle_id
from slct
group by slct.Vehicle_id, slct.rn
order by slct.vehicle_id, slct.rn asc

select *
from public.sg_osago_policies_26_03_2021 sop 

----------------------------------------------------
-- GATHERING REPORT
drop table public.sg_construction_year_BI_view

create table public.sg_construction_year_BI_view as
select 
	dr.Brand 
	, dr.Model
	,(CASE
		WHEN dr.Model in ('320i', '320i Premium') THEN '3-Series'
		WHEN dr.Model in ('Cooper 3D', 'Cooper 5D') THEN 'Cooper'
		WHEN dr.Model in ('Solaris ECO', 'Solaris') THEN 'Solaris'
		WHEN dr.Model in ('Polo ECO', 'Polo', 'Polo VI') THEN 'Polo'
		WHEN dr.Model in ('Rio X', 'Rio X-Line') THEN 'Rio X-Line'
		ELSE dr.Model
	 END) AS Model_grouped 
	, avcy.ConstructionYear
	, dr.rent_region_en
	, sum(dr.ride_time) as ride_time
	, sum(case when ac.accident_timestamp is not null and ac.guilty in ('Виновен', 'Обоюдная вина') then 1 else 0 end)	as guilty_accidents
	, count(DISTINCT(dr.vehicle_ext)) as cars_count
from DMA.delimobil_rent dr
left join DMA.accidents_1c ac on ac.rent_id = dr.rent_id
left join DMA.delimobil_vehicle dv on dv.vehicle_id = dr.vehicle_id 
left join CDDS.A_Vehicle_ConstructionYear avcy on avcy.Vehicle_id = dr.vehicle_id 
where dr."Start" > '2020-07-01' and dv.is_pool = FALSE and dv.is_prime = FALSE  and avcy.ConstructionYear is not null
group by 1,2,3,4,5

select 
(CASE
		WHEN dr.Model in ('320i', '320i Premium') THEN '3-Series'
		WHEN dr.Model in ('Cooper 3D', 'Cooper 5D') THEN 'Cooper'
		WHEN dr.Model in ('Solaris ECO', 'Solaris') THEN 'Solaris'
		WHEN dr.Model in ('Polo ECO', 'Polo', 'Polo VI') THEN 'Polo'
		WHEN dr.Model in ('Rio X', 'Rio X-Line') THEN 'Rio X-Line'
		ELSE dr.Model
	 END) AS Model_grouped 
	, dr.rent_region_en
	, sum(dr.ride_time) as ride_time
	, sum(case when ac.accident_timestamp is not null and ac.guilty in ('Виновен', 'Обоюдная вина') then 1 else 0 end)	as guilty_accidents
--	, count(DISTINCT(dr.vehicle_ext)) as cars_count
from DMA.delimobil_rent dr
left join DMA.accidents_1c ac on ac.rent_id = dr.rent_id
left join DMA.delimobil_vehicle dv on dv.vehicle_id = dr.vehicle_id 
left join CDDS.A_Vehicle_ConstructionYear avcy on avcy.Vehicle_id = dr.vehicle_id 
where dr."Start" > '2020-07-01' and dv.is_pool = FALSE and dv.is_prime = FALSE  and avcy.ConstructionYear = 2019 and dv.Model in ('Polo', 'Polo ECO', 'Polo VI', 'Solaris', 'Solaris ECO')
group by 1,2