--create or replace view bi.v_accident_frequency_by_pricing as
drop table public.sg_report_test 

create table public.sg_report_test 
with rnt as (
    select rent.*
    	   , trf.tariff_group
    	   , (case when rent."End"::date = du.first_ride_end::date then 'FTR'
				  when rent."End"::date > du.first_ride_end::date then 'NTR'
			  end) as ftr_category
    	   , (case
    	   		when du.age < 18 or dr.age > 65 then NULL
    	   	  else du.age end) AS age
    	   , (case
    	   		when AGE_IN_YEARS(rent."Start", du.license_set_date) < 0 or AGE_IN_YEARS(rent."Start", du.license_set_date) > 47 then NULL
    	   		when du.age - AGE_IN_YEARS(rent."Start", du.license_set_date) < 18 then 0
    	   	  else AGE_IN_YEARS(rent."Start", du.license_set_date) end) AS exp
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
       , COALESCE(rnt.rent_region_en, c1.region) as acc_region
       , rnt.ftr_category
       , rnt.age
       , rnt.exp
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
       , sum(case when c1.c1_guilty = '???????' or c1.c1_guilty = '???????? ????' then 1 else 0 end) as guilty
       , sum(case when c1.c1_guilty = '?? ???????' then 1 else 0 end) as non_guilty
       , sum(case when c1.c1_guilty = '?? ??????????' or (c1.c1_guilty is null and c1.accident_timestamp is not null) then 1 else 0 end) as guilt_not_established
       , sum(case when c1.c1_guilty = '??????' then 1 else 0 end) as wanted
       , sum(case when c1.c1_guilty = '????' then 1 else 0 end) as fake
       , sum(case when c1.c1_guilty = '?????? ???????' then 1 else 0 end) as review_group
       , sum(c1.order_sum) as accidents_repair_cost
       , sum(case when c1.c1_guilty = '???????' or c1.c1_guilty = '???????? ????' then c1.order_sum else 0 end) as guilty_repair_cost
       , sum(case when c1.c1_guilty = '?? ???????' then c1.order_sum else 0 end) as non_guilty_repair_cost
       , sum(case when c1.c1_guilty = '?? ??????????' or c1.c1_guilty is null then c1.order_sum else 0 end) as guilt_not_established_repair_cost
       , sum(case when c1.c1_guilty = '??????' then c1.order_sum else 0 end) as wanted_repair_cost
       , sum(case when c1.c1_guilty = '????' then c1.order_sum else 0 end) as fake_repair_cost
       , sum(case when c1.c1_guilty = '?????? ???????' then c1.order_sum else 0 end) as review_group_repair_cost
from rnt
full outer join c1 
    on c1.Rent_id = rnt.rent_id
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
left join dma.delimobil_user_coefficient_pricing coef on coef.user_id = rnt.user_id and rnt."Start" BETWEEN coef.from_dtime and coef.to_dtime
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
group by 1,2,3,4,5,6,7,8
;
