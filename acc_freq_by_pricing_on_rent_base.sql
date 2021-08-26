grant select on public.sg_acc_freq_by_pricing_v2 to powerbi

--create or replace view bi.v_daily_accidents_count_by_guilty_report_by_dt as
--create table public.sg_acc_freq_by_pricing_v2 as
with rnt as (
    select *
    from dma.delimobil_rent
    where "End" >= '2020-08-01'
        and not is_b2b 
        and 0 < ride_cost 
),
c1 as (
    select c1.accident_id::!int as accident_id
       , c1.accident_timestamp
       , c1.guilty as c1_guilty
       , rg.region_en as region
       , c1.order_sum as order_sum
       , c1.Rent_id
       , c1.driver_drunk
    from dma.accidents_1c c1  
    left join public.sg_regions_map rg on rg.region_rus = c1.region
    where c1.accident_id::!int is not null 
        and c1.accident_timestamp >= '2020-08-01'
        and c1.guilty <> 'Угон'
)
select 
	   date_trunc('day',COALESCE(c1.accident_timestamp, rnt."End")) as acc_date
	   , CAST(COALESCE(c1.accident_timestamp, rnt."End") AS TIME) as acc_time
       , COALESCE(rnt.rent_region_en, c1.region) as acc_region
       , COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) as pricing
	   , COALESCE("preScore"['preScoreMemberList']['0']['score'],  "coefficients"['0']['data']['preScoreMemberList']['1']['score']) as ftr_score
	   , COALESCE("preScore"['preScoreMemberList']['1']['score'],  "coefficients"['0']['data']['preScoreMemberList']['0']['score']) as deli_score
	   , COALESCE("preScore"['score'], "coefficients"['0']['data']['score'] ) as final_score
	   , rnt.ride_time
	   , AGE_IN_YEARS(rnt."Start", usr.birthday) as drivers_age
	   , trf.rent_type
	   , (case when trf.tariff_type in ('Базовый', 'Basic', 'БАЗОВЫЙ ДЛЯ СОТРУДНИКОВ', 'Basic_bank') then 'Basic'
	   		  when trf.tariff_type in ('Сказка', 'fairy_tale', 'fairy_staff') then 'Fairy Tale'
	   		  when left(trf.tariff_type,3) = 'B2B' or left(trf.tariff_type,3) = 'b2b' then 'B2B'
	   		  when trf.tariff_type = 'Динамический' then 'Dynamic' else 'Other' end) as tariff_type
	   , trf.tariff_group
       , (case when c1.accident_timestamp is not null then 1 else 0 end) as accidents_count
       , c1.c1_guilty
       , c1.order_sum
       , c1.driver_drunk
       , (case when c1.c1_guilty = 'Виновен' or c1.c1_guilty = 'Обоюдная вина' then 1 else 0 end) as guilty
       , (case when c1.c1_guilty = 'Не виновен' then 1 else 0 end) as non_guilty
       , (case when c1.c1_guilty = 'Не установлен' or (c1.c1_guilty is null and c1.accident_timestamp is not null) then 1 else 0 end) as guilt_not_established
       , (case when c1.c1_guilty = 'Розыск' then 1 else 0 end) as wanted
       , (case when c1.c1_guilty = 'Фейк' then 1 else 0 end) as fake
       , (case when c1.c1_guilty = 'Группа разбора' then 1 else 0 end) as review_group       
       , (case when c1.c1_guilty = 'Виновен' or c1.c1_guilty = 'Обоюдная вина' then c1.order_sum else 0 end) as guilty_repair_cost
       , (case when c1.c1_guilty = 'Не виновен' then c1.order_sum else 0 end) as non_guilty_repair_cost
       , (case when c1.c1_guilty = 'Не установлен' or c1.c1_guilty is null then c1.order_sum else 0 end) as guilt_not_established_repair_cost
       , (case when c1.c1_guilty = 'Розыск' then c1.order_sum else 0 end) as wanted_repair_cost
       , (case when c1.c1_guilty = 'Фейк' then c1.order_sum else 0 end) as fake_repair_cost
       , (case when c1.c1_guilty = 'Группа разбора' then c1.order_sum else 0 end) as review_group_repair_cost
from rnt
left join cdds.A_Rent_ScoringFlex scr on scr.rent_id = rnt.rent_id
left join dma.delimobil_rent_tariff trf on trf.rent_id = rnt.rent_id
left join dma.delimobil_user usr on usr.user_id = rnt.rent_id
full outer join c1 
    on c1.Rent_id = rnt.rent_id
;