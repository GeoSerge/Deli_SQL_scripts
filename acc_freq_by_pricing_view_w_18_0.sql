create or replace view bi.v_accident_frequency_by_pricing as
with rnt as (
    select rent.*, trf.tariff_group
    from dma.delimobil_rent rent
    left join dma.delimobil_rent_tariff trf on trf.rent_id = rent.rent_id
    where "End" >= '2020-06-09'
        and not is_b2b 
        and 0 < cost 
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
       , (case when rnt.tariff_group = 'tariff180+30.17.08.2020' then '18-0' else '19-1+' end) as age_group
       , (case when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is not null then -2.0
       		   when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is null then -1.0
       		   else COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) end) as pricing
	   , COALESCE("preScore"['preScoreMemberList']['0']['score'],  "coefficients"['0']['data']['preScoreMemberList']['1']['score']) as ftr_score
	   , COALESCE("preScore"['preScoreMemberList']['1']['score'],  "coefficients"['0']['data']['preScoreMemberList']['0']['score']) as deli_score
	   , COALESCE("preScore"['score'], "coefficients"['0']['data']['score'] ) as final_score
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
left join cdds.A_Rent_ScoringFlex scr on scr.Rent_id = rnt.rent_id
group by date_trunc('day',COALESCE(c1.accident_timestamp, rnt."End"))
    , COALESCE(rnt.rent_region_en, c1.region)
    , (case when rnt.tariff_group = 'tariff180+30.17.08.2020' then '18-0' else '19-1+' end)
    , (case when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is not null then -2.0
       		   when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is null then -1.0
       		   else COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) end)
    , COALESCE("preScore"['preScoreMemberList']['0']['score'],  "coefficients"['0']['data']['preScoreMemberList']['1']['score'])
	, COALESCE("preScore"['preScoreMemberList']['1']['score'],  "coefficients"['0']['data']['preScoreMemberList']['0']['score'])
	, COALESCE("preScore"['score'], "coefficients"['0']['data']['score'] )
;

-- TESTING TARIFF GROUP 
select (case when tariff_group = 'tariff180+30.17.08.2020' then '18-0' else '19-1+' end) as age_group, trf.*, rnt.*
from dma.delimobil_rent rnt
left join dma.delimobil_rent_tariff trf on trf.rent_id = rnt.rent_id
where tariff_group is not null and rnt."Start" > '2020-09-01' and rent_region_en <> 'Moscow'