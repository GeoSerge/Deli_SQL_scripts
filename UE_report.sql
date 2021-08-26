grant select on public.sg_bi_UE_view to powerbi

drop table public.sg_bi_UE_view 

create table public.sg_bi_UE_view as
with rents as 
(
select 
	r.*
	, (case
		when du.age < 18 or du.age > 65 or du.age is NULL then -1
    	else du.age
       end) AS age
    , (case
    	when AGE_IN_YEARS(r."Start", du.license_set_date) < 0 or AGE_IN_YEARS(r."Start", du.license_set_date) > 47 or du.license_set_date is null then -1
    	when du.age - AGE_IN_YEARS(r."Start", du.license_set_date) < 18 then 0
    	else AGE_IN_YEARS(r."Start", du.license_set_date)
       end) AS exp
from dma.delimobil_rent r
left join DMA.delimobil_user du on du.user_id = r.user_id
--left join DMA.delimobil_package pck on pck.Package_id = r.package_id
where "Start" BETWEEN '2020-06-09' and CURRENT_DATE-1
)
select  
	date_trunc('day', rnt.Start)
	, ROUND(scr.DrivingStyle_preScore, 2.0) as preScore
	, rnt.rent_region_en as region
	, rnt.age
	, rnt.exp
	, (case when left(trf.tariff_type,3) = 'B2B' then 'B2B'
	        when trf.tariff_type = 'БАЗОВЫЙ' or trf.tariff_type = 'Basic' then 'Базовый'
	        when trf.tariff_type = 'Динамический' then 'Динамический'
	        when trf.tariff_type = 'СКАЗКА' then 'Сказка'
            when trf.tariff_type = 'СКАЗКА ДЛЯ СОТРУДНИКОВ' then 'Сказка для сотрудников' 
            when trf.tariff_type = 'БАЗОВЫЙ ДЛЯ СОТРУДНИКОВ' then 'Базовый для сотрудников' else 'Другие' end) as tariff
	, SUM(case when coalesce(rnt.bill_success,0)+coalesce(rnt.bill_waiting,0) > 0
    		   then coalesce(rnt.ride_time,0)+(case when rnt.is_24h_rent = FALSE then coalesce(rnt.park_time,0) else 0 end)+coalesce(rnt.reserved_time_paid,0)+coalesce(rnt.rated_time_paid,0)
    		   else 0 end) as paid_time
	, SUM(coalesce(rnt.bill_amount,0)+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0)-coalesce(rnt.bonus_amount,0)) as revenue
    , SUM(coalesce(rnt.bill_success,0)+coalesce(rnt.bill_waiting,0)-coalesce(rnt.bonus_amount,0)) as revenue_v2
    , SUM(acc.order_sum) as repair_cost
    , SUM(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end) as guilty_repair_cost
    , SUM(case when acc.guilty <> 'Виновен' and acc.guilty <> 'Обоюдная вина' then acc.order_sum else 0 end) as not_guilty_repair_cost
from rents rnt
left join dma.delimobil_rent_tariff trf on trf.rent_id = rnt.rent_id
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
left join dma.accidents_1c acc on acc.Rent_id = rnt.rent_id
group by 1,2,3,4,5,6

/* CHECK ACCIDENTS REPAIR COST  */
SELECT
	COUNT(*)
	, SUM(repair_cost)
FROM DMA.accidents_1c ac 
WHERE region = 'Краснодар' AND accident_timestamp BETWEEN '2020-12-29' AND '2021-02-03'

select  SUM(case when coalesce(bill_success,0)+coalesce(bill_waiting,0) > 0
    		   then coalesce(ride_time,0)+coalesce(park_time,0)+coalesce(reserved_time_paid,0)+coalesce(rated_time_paid,0)
    		   else 0 end) as paid_time
    	, SUM(ride_time+park_time+reserved_time_paid+rated_time_paid) paid_time2
    	, SUM(coalesce(bill_amount,0)+coalesce(bill_refund_12,0)-coalesce(bill_error,0)-coalesce(bonus_amount,0)) as revenue
    	, SUM(cost) rev2
from DMA.delimobil_rent dr 
where rent_region_en = 'Krasnodar' and "Start" BETWEEN '2021-01-10' AND '2021-02-03'

select *
from DMA.delimobil_rent dr 
left join DMA.delimobil_package dp on dp.Package_id = dr.package_id 
left join DMA.delimobil_rent_package drp on drp.Rent_id = dr.rent_id 
where "Start" > '2021-01-15' and dr.ride_cost > dr.cost 

select *
from DMA.delimobil_rent dr 
where is_24h_rent = True and "Start"  > '2021-01-01'

select sum(ac.order_sum)
from DMA.accidents_1c ac 
where region = 'Краснодар' and accident_timestamp BETWEEN '2020-11-01' and '2020-11-30' and guilty = 'Виновен'