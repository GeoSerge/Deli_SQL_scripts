/* Users distribution by pricing coef */
select (case when DrivingStyle_preScore <= 0.15 then 1.3 else DrivingStyle_coefficient end)
	   , (case when timestampdiff('day', du.license_set_date, ducp.from_dtime)/365.25 < 1 then '18-0'
	   		when du.age < 21 or timestampdiff('day', du.license_set_date, ducp.from_dtime)/365.25 < 2 then '21-2' else 'others' end) as category
	   , count(*)
from DMA.delimobil_user_coefficient_pricing ducp 
left join DMA.delimobil_user du on du.user_id = ducp.user_id 
where status = 'active' and ducp.from_dtime < '2021-06-29'
group by 1, 2
order by 1 desc, 2 desc

/* Closer look at 18-0 users with 1.15 pricing coef */
select DrivingStyle_preScore
	   , (case when timestampdiff('day', du.license_set_date, ducp.from_dtime)/365.25 < 1 then '18-0'
	   		when du.age < 21 or timestampdiff('day', du.license_set_date, ducp.from_dtime)/365.25 < 2 then '21-2' else 'others' end) as category
	   , count(*)
from DMA.delimobil_user_coefficient_pricing ducp 
left join DMA.delimobil_user du on du.user_id = ducp.user_id 
where status = 'active' and ducp.from_dtime < '2021-06-29' and DrivingStyle_coefficient = 1.15
group by 1, 2
order by 1 desc, 2 desc

/* Ride time distribution by pricing coefs */
select (case when DrivingStyle_preScore <= 0.15 then 1.3 else DrivingStyle_coefficient end)
	   , (case when timestampdiff('day', du.license_set_date, dr."Start")/365.25 < 1 then '18-0'
	   		when du.age < 21 or timestampdiff('day', du.license_set_date, dr."Start")/365.25 < 2 then '21-2' else 'others' end) as category
	   , sum(dr.ride_time)
from DMA.delimobil_rent dr 
left join DMA.delimobil_rent_scoring drs on drs.Rent_id = dr.rent_id
left join DMA.delimobil_user du on du.user_id = dr.user_id 
where dr."Start" BETWEEN '2021-06-01' and '2021-06-29'
group by 1, 2
order by 1 desc, 2 desc

/* New deli score distribution by pricing coefs */
DROP TABLE public.sg_pricing_map 

CREATE TABLE public.sg_pricing_map (
Pricing_coef DECIMAL(5,2),
from_ DECIMAL(7,4),
to_ DECIMAL(7,4)
)

INSERT INTO public.sg_pricing_map
VALUES (1.3, 0.0, 0.09)

INSERT INTO public.sg_pricing_map
VALUES	(1.2, 0.0901, 0.15)

INSERT INTO public.sg_pricing_map
VALUES	(1.15, 0.1501, 0.1775)

INSERT INTO public.sg_pricing_map
VALUES	(1.12, 0.1776, 0.24)

INSERT INTO public.sg_pricing_map
VALUES	(1.05, 0.2401, 0.3405)

INSERT INTO public.sg_pricing_map
VALUES	(1.0, 0.3406, 0.65)

INSERT INTO public.sg_pricing_map
VALUES	(0.95, 0.6501, 0.87)

INSERT INTO public.sg_pricing_map
VALUES	(0.85, 0.8701, 0.968)

INSERT INTO public.sg_pricing_map
VALUES	(0.8, 0.9681, 1.001)

SELECT 
--pm_old.Pricing_coef AS pricing_old
	pm_new.Pricing_coef AS pricing_new
	, (case when timestampdiff('day', du.license_set_date, CURRENT_DATE())/365.25 < 1 then '18-0'
	   		when du.age < 21 or timestampdiff('day', du.license_set_date, CURRENT_DATE())/365.25 < 2 then '21-2' else 'others' end) as category
	, COUNT(tam.user_id) AS 'Users count'
FROM public.tn_accidents_modelcheck2 tam 
LEFT JOIN public.sg_pricing_map pm_old ON tam.score_oldmodel BETWEEN pm_old.from_ AND pm_old.to_
LEFT JOIN public.sg_pricing_map pm_new ON tam.score_newboost3 BETWEEN pm_new.from_ AND pm_new.to_
LEFT JOIN DMA.delimobil_user du on du.user_id = tam.user_id
GROUP BY 1, 2
ORDER BY 1 DESC

/* Ride time distribution by pricing coefs */
select *
--pm_old.Pricing_coef
--	   , (case when timestampdiff('day', du.license_set_date, dr."Start")/365.25 < 1 then '18-0'
--	   		when du.age < 21 or timestampdiff('day', du.license_set_date, dr."Start")/365.25 < 2 then '21-2' else 'others' end) as category
--	   , sum(dr.ride_time)
from DMA.delimobil_rent dr  
left join DMA.delimobil_user du on du.user_id = dr.user_id 
left join public.tn_accidents_modelcheck tam on tam.user_id = dr.user_id 
left join public.sg_pricing_map pm_old ON tam.score_old BETWEEN pm_old.from_ AND pm_old.to_
where dr."Start" BETWEEN '2021-06-01' and '2021-06-29' AND dr.user_id IN (SELECT user_id FROM public.tn_accidents_modelcheck)
--group by 1, 2
--order by 1 desc, 2 desc

select count(*)
from public.tn_accidents_modelcheck tam 