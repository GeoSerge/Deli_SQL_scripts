grant select on public.sg_accidents_frequency_by_pricing to powerbi

create table public.sg_accidents_frequency_by_pricing as
with rnt as (
    select rent.*
    	   , trf.tariff_group
    	   , (case when rent."Start" > du.first_ride then 'NTR' when rent."Start" = du.first_ride then 'FTR' else NULL end) as ftr_ntr
    from DMA.delimobil_rent rent
    left join DMA.delimobil_rent_tariff trf on trf.rent_id = rent.rent_id
    left join DMA.delimobil_user du on du.user_ext = rent.user_ext
    where "End" >= '2020-06-09'
        and not is_b2b 
        and rent.is_ride = True
),
c1 as (
    select c1.accident_id::!int as accident_id
       , c1.accident_timestamp
       , c1.guilty as c1_guilty
       , rg.region_en as region
       , c1.order_sum as order_sum
       , c1.Rent_id
    from dma.accidents_1c c1  
    left join public.sg_regions_map rg on rg.region_rus = c1.region
    where c1.accident_id::!int is not null 
        and c1.accident_timestamp >= '2020-06-09'
)
select date_trunc('day',COALESCE(c1.accident_timestamp, rnt."End")) as acc_date
	   , rnt.ftr_ntr
       , COALESCE(rnt.rent_region_en, c1.region) as acc_region
       , (case when (AGE_IN_YEARS(rnt."Start", usr.birthday) = 18 or AGE_IN_YEARS(rnt."Start", usr.license_set_date) = 0) and rnt."Start" >= '2020-08-18' then '18-0' else '19-1+' end) as age_group
       , (case when (case when COALESCE(rnt."End",c1.accident_timestamp) <= '2020-10-01 14:00:00' then scr.Pricing_coefficient else coef.DrivingStyle_coefficient end) is null and rnt.rent_id is not null then -2.0
       		   when (case when COALESCE(rnt."End",c1.accident_timestamp) <= '2020-10-01 14:00:00' then scr.Pricing_coefficient else coef.DrivingStyle_coefficient end) is null and rnt.rent_id is null then -1.0
       		   else (case when COALESCE(rnt."End",c1.accident_timestamp) <= '2020-10-01 14:00:00' then scr.Pricing_coefficient else coef.DrivingStyle_coefficient end) end) as pricing
	   , scr.DrivingStyle_ftrScore as ftr_score
	   , scr.DrivingStyle_delimobilScore as deli_score
	   , scr.DrivingStyle_preScore as final_score
	   , COUNT(rnt.rent_id) as rents_count
	   , COUNT(DISTINCT(rnt.user_id)) as users_count
       , sum(rnt.ride_time) as ride_time_sum
       , sum(case when c1.accident_timestamp is not null then 1 else 0 end) as accidents_count
       , sum(case when c1.c1_guilty = 'Виновен' or c1.c1_guilty = 'Обоюдная вина' then 1 else 0 end) as guilty
       , sum(case when c1.c1_guilty = 'Не виновен' then 1 else 0 end) as non_guilty
       , sum(case when c1.c1_guilty = 'Не установлен' or (c1.c1_guilty is null and c1.accident_timestamp is not null) then 1 else 0 end) as guilt_not_established
       , sum(case when c1.c1_guilty = 'Розыск' then 1 else 0 end) as wanted
       , sum(case when c1.c1_guilty = 'Фейк' then 1 else 0 end) as fake
       , sum(case when c1.c1_guilty = 'Группа разбора' then 1 else 0 end) as review_group
       , sum(c1.order_sum) as accidents_repair_cost
       , sum(case when c1.c1_guilty = 'Виновен' or c1.c1_guilty = 'Обоюдная вина' then c1.order_sum else 0 end) as guilty_repair_cost
       , sum(case when c1.c1_guilty = 'Не виновен' then c1.order_sum else 0 end) as non_guilty_repair_cost
       , sum(case when c1.c1_guilty = 'Не установлен' or c1.c1_guilty is null then c1.order_sum else 0 end) as guilt_not_established_repair_cost
       , sum(case when c1.c1_guilty = 'Розыск' then c1.order_sum else 0 end) as wanted_repair_cost
       , sum(case when c1.c1_guilty = 'Фейк' then c1.order_sum else 0 end) as fake_repair_cost
       , sum(case when c1.c1_guilty = 'Группа разбора' then c1.order_sum else 0 end) as review_group_repair_cost
from rnt
full outer join c1 
    on c1.Rent_id = rnt.rent_id
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
left join dma.delimobil_user_coefficient_pricing coef on coef.user_id = rnt.user_id and rnt."Start" BETWEEN coef.from_dtime and coef.to_dtime
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
group by 1,2,3,4,5,6,7,8

select scr.DrivingStyle_preScore, count(*)
from DMA.delimobil_rent dr 
left join DMA.delimobil_user du on du.user_ext = dr.user_ext 
left join DMA.delimobil_rent_scoring scr on scr.Rent_id = dr.rent_id 
where (du.age = 18 or AGE_IN_YEARS(dr."Start", du.license_set_date) = 0) and dr."Start" > du.first_ride and dr.is_ride = True and dr."Start" > '2020-06-09'
group by scr.DrivingStyle_preScore
order by scr.DrivingStyle_preScore asc