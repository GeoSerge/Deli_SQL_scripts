select sum(case when ac.order_sum < 30000 then 0 when ac.order_sum >= 30000 and ac.guilty = 'Виновен' then ac.order_sum else 0 end) guilty_order_sum_to_be_compensated
	   , sum(case when guilty = 'Виновен' then order_sum else 0 end) guilty_order_sum
	   , sum(ride_time) ride_time
	   , sum(ride_time)*1.05 CASCO_cost
from DMA.delimobil_rent dr 
left join DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
where dr."Start" >= '2020-06-09'

select drt.is_skazka 
	   , sum(case when ac.order_sum < 30000 then 0 when ac.order_sum >= 30000 and ac.guilty = 'Виновен' then ac.order_sum else 0 end) guilty_order_sum_to_be_compensated
	   , sum(case when guilty = 'Виновен' then order_sum else 0 end) guilty_order_sum
	   , sum(ride_time) ride_time
	   , sum(ride_time)*1.05 CASCO_cost
from DMA.delimobil_rent dr 
left join DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
left join DMA.delimobil_vehicle dv on dv.vehicle_id = dr.vehicle_id 
left join DMA.delimobil_rent_tariff drt on drt.rent_id = dr.rent_id 
where dr."Start" BETWEEN '2020-07-01' and '2020-12-31' and dv.model in ('Polo', 'Solaris', 'Polo ECO', 'Polo VI')
group by drt.is_skazka 

select *
from DMA.delimobil_rent_tariff drt 
where is_skazka = FALSE-- and tariff_group = 'СКАЗКА'

