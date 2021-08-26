grant select on public.sg_repair_cost_by_age_exp_score to powerbi

drop table public.sg_repair_cost_by_age_exp_score 

create table public.sg_repair_cost_by_age_exp_score as
with rents as 
(
select 
	rnt.*
	, usr.birthday 
	, usr.license_set_date 
from dma.delimobil_rent rnt
left join DMA.delimobil_user usr on usr.user_id = rnt.user_id
where "Start" BETWEEN '2020-06-09' and CURRENT_DATE-1
)
select  
--	date_trunc('day', rnt.Start)
	ROUND(scr.DrivingStyle_preScore, 2.0) as preScore
	, TIMESTAMPDIFF('year', birthday, rnt.Start) as age
	, TIMESTAMPDIFF('year', license_set_date, rnt.Start) as exp 
	, rnt.rent_region_en as region
	, (case when left(trf.tariff_type,3) = 'B2B' then 'B2B'
	        when trf.tariff_type = 'БАЗОВЫЙ' or trf.tariff_type = 'Basic' then 'Базовый'
	        when trf.tariff_type = 'Динамический' then 'Динамический'
	        when trf.tariff_type = 'СКАЗКА' then 'Сказка'
            when trf.tariff_type = 'СКАЗКА ДЛЯ СОТРУДНИКОВ' then 'Сказка для сотрудников' 
            when trf.tariff_type = 'БАЗОВЫЙ ДЛЯ СОТРУДНИКОВ' then 'Базовый для сотрудников' else 'Другие' end) as tariff
	, SUM(case when coalesce(rnt.bill_success,0)+coalesce(rnt.bill_waiting,0) > 0
    		   then coalesce(rnt.ride_time,0)+coalesce(rnt.park_time,0)+coalesce(rnt.reserved_time_paid,0)+coalesce(rnt.rated_time_paid,0)
    		   else 0 end) as paid_time
    , SUM(rnt.ride_time) as ride_time
	, SUM(coalesce(rnt.bill_amount,0)+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0)-coalesce(rnt.bonus_amount,0)) as revenue
    , SUM(coalesce(rnt.bill_success,0)+coalesce(rnt.bill_waiting,0)-coalesce(rnt.bonus_amount,0)) as revenue_v2
    , SUM(acc.order_sum) as repair_cost
    , SUM(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end) as guilty_repair_cost
    , SUM(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then 1 else 0 end) as guilty_accidents_count
    , SUM(case when acc.guilty <> 'Виновен' and acc.guilty <> 'Обоюдная вина' then acc.order_sum else 0 end) as not_guilty_repair_cost
    , COUNT(DISTINCT(rnt.user_id)) as distinct_users
	  --, SUM(compensation)  
from rents rnt
left join dma.delimobil_rent_tariff trf on trf.rent_id = rnt.rent_id
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
left join dma.accidents_1c acc on acc.Rent_id = rnt.rent_id
where TIMESTAMPDIFF('year', birthday, rnt.Start) between 18 and 70 and TIMESTAMPDIFF('year', license_set_date, rnt.Start) between 0 and 52 and  TIMESTAMPDIFF('year', birthday, rnt.Start) - TIMESTAMPDIFF('year', license_set_date, rnt.Start) >= 16
group by 1,2,3,4,5