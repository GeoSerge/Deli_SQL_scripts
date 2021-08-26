select dr.user_id
	   , sum(dr.ride_time)/6 as avg_monthly_ride_time
	   , sum(case when trf.is_skazka = True then ride_time else 0 end)/6 as avg_skazka_monthly_ride_time
	   , avg(drs.DrivingStyle_preScore) as avg_preScore
	   , min(drs.DrivingStyle_preScore) as min_preScore
	   , max(drs.DrivingStyle_preScore) as max_preScore
	   , sum(case when ac.accident_timestamp is not null and ac.guilty in ('Виновен', 'Обоюдная вина') and trf.is_skazka = TRUE then 1 else 0 end) as accidents
from DMA.delimobil_rent dr 
left join DMA.delimobil_rent_tariff trf on trf.rent_id = dr.rent_id
left join DMA.delimobil_rent_scoring drs on drs.rent_id = dr.rent_id
left join DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
where dr."Start" > '2021-01-01'
group by dr.user_id

/* Complicated conditions */
with q as
(select dr.user_id
	   , date_trunc('month', dr."Start")
	   , sum(dr.ride_time) as avg_monthly_ride_time
--	   , sum(case when trf.is_skazka = True then ride_time else 0 end)/6 as avg_skazka_monthly_ride_time
from DMA.delimobil_rent dr 
left join DMA.delimobil_rent_tariff trf on trf.rent_id = dr.rent_id
where dr."Start" > '2021-01-01'
group by 1,2),
q1 as
(select q.user_id
	   , sum(case when q.avg_monthly_ride_time >= 700 then 1 else 0 end) as more_700
from q
group by 1)
select count(DISTINCT(q1.user_id))
from q1
where q1.more_700 >= 3

