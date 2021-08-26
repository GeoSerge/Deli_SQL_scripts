grant select on public.sg_acc_freq_by_pricing_v3 to powerbi

--create or replace view bi.v_daily_accidents_count_by_guilty_report_by_dt as
create table public.sg_acc_freq_by_pricing_v4 as
with rnt as (
    select *
    from dma.delimobil_rent
    where "End" >= '2020-06-09'
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
    from dma.accidents_1c c1  
    left join public.sg_regions_map rg on rg.region_rus = c1.region
    where c1.accident_id::!int is not null 
        and c1.accident_timestamp >= '2020-06-09'
)
select date_trunc('day',COALESCE(c1.accident_timestamp, rnt."End")) as acc_date
       , COALESCE(rnt.rent_region_en, c1.region) as acc_region
       , (case when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is not null then -2.0
       		   when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is null then -1.0
       		   else COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) end) as pricing
	   , COALESCE("preScore"['preScoreMemberList']['0']['score'],  "coefficients"['0']['data']['preScoreMemberList']['1']['score']) as ftr_score
	   , COALESCE("preScore"['preScoreMemberList']['1']['score'],  "coefficients"['0']['data']['preScoreMemberList']['0']['score']) as deli_score
	   , COALESCE("preScore"['score'], "coefficients"['0']['data']['score'] ) as final_score
       , sum(rnt.ride_time) as ride_time_sum
       , sum(case when c1.accident_timestamp is not null then 1 else 0 end) as accidents_count
       , sum(case when c1.c1_guilty = '�������' then 1 else 0 end) as guilty
       , sum(case when c1.c1_guilty = '�� �������' then 1 else 0 end) as non_guilty
       , sum(case when c1.c1_guilty = '�� ����������' or (c1.c1_guilty is null and c1.accident_timestamp is not null) then 1 else 0 end) as guilt_not_established
       , sum(case when c1.c1_guilty = '�������� ����' then 1 else 0 end) as mutual_guilt
       , sum(case when c1.c1_guilty = '������' then 1 else 0 end) as wanted
       , sum(case when c1.c1_guilty = '����' then 1 else 0 end) as fake
       , sum(case when c1.c1_guilty = '������ �������' then 1 else 0 end) as review_group
       , sum(c1.order_sum) as accidents_repair_cost
       , sum(case when c1.c1_guilty = '�������' then c1.order_sum else 0 end) as guilty_repair_cost
       , sum(case when c1.c1_guilty = '�� �������' then c1.order_sum else 0 end) as non_guilty_repair_cost
       , sum(case when c1.c1_guilty = '�� ����������' or c1.c1_guilty is null then c1.order_sum else 0 end) as guilt_not_established_repair_cost
       , sum(case when c1.c1_guilty = '�������� ����' then c1.order_sum else 0 end) as mutual_guilt_repair_cost
       , sum(case when c1.c1_guilty = '������' then c1.order_sum else 0 end) as wanted_repair_cost
       , sum(case when c1.c1_guilty = '����' then c1.order_sum else 0 end) as fake_repair_cost
       , sum(case when c1.c1_guilty = '������ �������' then c1.order_sum else 0 end) as review_group_repair_cost
from rnt
full outer join c1 
    on c1.Rent_id = rnt.rent_id
left join cdds.A_Rent_ScoringFlex scr on scr.Rent_id = rnt.rent_id
group by date_trunc('day',COALESCE(c1.accident_timestamp, rnt."End"))
    , COALESCE(rnt.rent_region_en, c1.region)
    , (case when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is not null then -2.0
       		   when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is null then -1.0
       		   else COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) end)
    , COALESCE("preScore"['preScoreMemberList']['0']['score'],  "coefficients"['0']['data']['preScoreMemberList']['1']['score'])
	, COALESCE("preScore"['preScoreMemberList']['1']['score'],  "coefficients"['0']['data']['preScoreMemberList']['0']['score'])
	, COALESCE("preScore"['score'], "coefficients"['0']['data']['score'] )
;