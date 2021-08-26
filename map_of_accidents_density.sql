grant select on public.sg_bi_accidents_map_view to powerbi
create table public.sg_bi_accidents_map_view as
select ac.Rent_id, dr.latitude_end, dr.longitude_end 
from DMA.accidents_1c ac 
left join DMA.delimobil_rent dr on dr.rent_id = ac.Rent_id 
where ac.accident_timestamp >= '2020-06-09'
	  and ac.order_sum BETWEEN 10000 and 150000
	  and (ac.guilty = 'Виновен' or ac.guilty = 'Обоюдная вина')
	  and dr.rent_region_en = 'Moscow'
	  and dr.rent_id is not null

-- WHEN THE MOST ACCIDENTS OCCUR DURING THE DAY  
select HOUR(ac.accident_timestamp), count(*)
from DMA.accidents_1c ac 
where ac.accident_timestamp >= '2020-06-09'
	  and ac.order_sum BETWEEN 10000 and 150000
	  and (ac.guilty = 'Виновен' or ac.guilty = 'Обоюдная вина')
	  and ac.region = 'Москва'
group by HOUR(ac.accident_timestamp)

-- FINDING VEHICLES IN MOSCOW WITH THE HIGHEST MILEAGE
with mlg as (
select dv.mileage, *
from DMA.delimobil_vehicle dv 
where region_name_en = 'Moscow' and dv.mileage > 100000
and (brand = 'Kia' or brand = 'Hyundai' or brand = 'Nissan')),
rents as (
select ROW_NUMBER() OVER (PARTITION BY dr.vehicle_id ORDER BY dr."Start" desc) as rn, dr."Start", dr."End", dr.latitude_end, dr.longitude_end, mlg.*
from DMA.delimobil_rent dr 
left join mlg on mlg.vehicle_id = dr.vehicle_id 
left join CDDS.A_Vehicle_Status vs on vs.Vehicle_id = dr.vehicle_id 
where dr."Start" > '2020-11-16' and mlg.vehicle_id is not null and vs.Status <> 'service' and dr.latitude_end is not null)
select ABS(rents.latitude_end-55.791074)+ ABS(rents.longitude_end-37.707253) as dist, rents.vehicle_ext, rents.*
from rents
where rn = 1
order by dist asc