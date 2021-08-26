SELECT
	r.passp_country 
	, SUM(dr.ride_time) ride_time
	, SUM(CASE WHEN ac.accident_timestamp IS NOT NULL AND ac.guilty IN ('Виновен', 'Обоюдная вина') THEN 1 ELSE 0 END) guilty_accidents
FROM DMA.delimobil_rent dr 
LEFT JOIN DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
LEFT JOIN SAEO.requests r on r.id = dr.user_ext
WHERE dr."Start" > '2020-07-01'
GROUP BY 1
ORDER BY 2 DESC

with accidents as 
(select
	r.passp_country 
	, sum(case when guilty in ('Виновен', 'Обоюдная вина') then 1 else 0 end)
from DMA.accidents_1c ac 
left join SAEO.requests r on r.id = ac.user_ext 
where ac.accident_timestamp > '2020-01-01'
group by 1),
rents as
(select 
	r.passp_country
	, sum(dr.ride_time)
from DMA.delimobil_rent dr 
left join saeo.requests r on r.id = dr.user_ext 
where dr."Start" > '2020-01-01'
group by 1)
select
	rents.passp_country
	, rents.sum
	, accidents.sum
from rents
left join accidents on accidents.passp_country = rents.passp_country
order by rents.sum desc