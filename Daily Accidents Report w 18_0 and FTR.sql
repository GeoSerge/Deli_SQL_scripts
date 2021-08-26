--create or replace view bi.v_daily_accidents_count_by_guilty_report_by_dt as
drop table public.sg_report_test

--create table public.sg_report_test as
with rnt as (
    select dr.*
    	   , (case when AGE_IN_YEARS(dr."Start", du.birthday) < 26 and AGE_IN_YEARS(dr."Start", du.license_set_date) = 0 then '18+/0'
    	   		   when AGE_IN_YEARS(dr."Start", du.birthday) >= 26 and AGE_IN_YEARS(dr."Start", du.license_set_date) = 0 then '26+/0'
    	   		   else 'others' end) as age_category
    	   , (case when scr.DrivingStyle_ftrCoefficient = 1 then 'FTR'
    	   		   else 'NTR' end) as ftr_category
    from dma.delimobil_rent dr
    left join DMA.delimobil_user du on du.user_id = dr.user_id
    left join DMA.delimobil_rent_scoring scr on scr.Rent_id = dr.rent_id
    where "End" > current_date() - 63
        and not is_b2b 
),
c1 as (
    select c1.accident_timestamp
       , c1.guilty as c1_guilty
       , rg.region_en as region
       , c1.order_sum as order_sum
       , c1.Rent_id
    from dma.accidents_1c c1
    left join public.sg_regions_map rg on rg.region_rus = c1.region
    where c1.accident_timestamp > current_date() - 63
)
select date_trunc('day',COALESCE(c1.accident_timestamp, rnt."End")) as acc_date
       , COALESCE(rnt.rent_region_en, c1.region) as acc_region
       , rnt.age_category as age_category
       , rnt.ftr_category
       , sum(rnt.ride_time) as ride_time_sum
       , sum(case when c1.accident_timestamp is not null then 1 else 0 end) as accidents_count
       , sum(case when c1.c1_guilty = 'Виновен' then 1 else 0 end) as guilty
       , sum(case when c1.c1_guilty = 'Не виновен' then 1 else 0 end) as non_guilty
       , sum(case when c1.c1_guilty = 'Не установлен' or (c1.c1_guilty is null and c1.accident_timestamp is not null) then 1 else 0 end) as guilt_not_established
       , sum(case when c1.c1_guilty = 'Обоюдная вина' then 1 else 0 end) as mutual_guilt
       , sum(case when c1.c1_guilty = 'Розыск' then 1 else 0 end) as wanted
       , sum(case when c1.c1_guilty = 'Фейк' then 1 else 0 end) as fake
       , sum(case when c1.c1_guilty = 'Группа разбора' then 1 else 0 end) as review_group
       , sum(c1.order_sum) as accidents_repair_cost
       , sum(case when c1.c1_guilty = 'Виновен' then c1.order_sum else 0 end) as guilty_repair_cost
       , sum(case when c1.c1_guilty = 'Не виновен' then c1.order_sum else 0 end) as non_guilty_repair_cost
       , sum(case when c1.c1_guilty = 'Не установлен' or c1.c1_guilty is null then c1.order_sum else 0 end) as guilt_not_established_repair_cost
       , sum(case when c1.c1_guilty = 'Обоюдная вина' then c1.order_sum else 0 end) as mutual_guilt_repair_cost
       , sum(case when c1.c1_guilty = 'Розыск' then c1.order_sum else 0 end) as wanted_repair_cost
       , sum(case when c1.c1_guilty = 'Фейк' then c1.order_sum else 0 end) as fake_repair_cost
       , sum(case when c1.c1_guilty = 'Группа разбора' then c1.order_sum else 0 end) as review_group_repair_cost
from rnt
full outer join c1 
    on c1.Rent_id = rnt.rent_id
group by acc_date
    , acc_region
    , rnt.age_category
    , rnt.ftr_category