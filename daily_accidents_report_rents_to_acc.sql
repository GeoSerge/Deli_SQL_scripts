--create or replace view bi.v_daily_accidents_count_by_guilty_report as
with
rent as (
	select *
	from dma.delimobil_rent
	where "End" > current_date() - interval '1 month'
	and is_b2b = FALSE
	and cost > 0
),
c1 as (
	select
		c1.accident_id::!int as accident_id
	   ,c1.accident_timestamp
	   ,c1.guilty as c1_guilty
	   ,rg.region_en as region
	   ,replace(c1.order_sum, ',', '')::decimal as order_sum
	   ,c1.Rent_id
	from dma.accidents_1c c1
	left join public.sg_regions_map rg on rg.region_rus = c1.region
	where c1.accident_id::!int is not null and to_timestamp(c1.accident_timestamp, 'MM/DD/YYYY HH12:MI:SS AM') > current_date() - interval '1 month'
)
select rnt.rent_id
	   ,rnt.rent_ext
	   ,rnt."Start"
	   ,rnt."End"
	   ,rnt.cost
	   ,rnt.bill_amount
	   ,rnt.bonus_amount
	   ,rnt.bill_status
	   ,rnt.bill_waiting
	   ,rnt.bill_error
	   ,rnt.user_id
	   ,rnt.vehicle_id
	   ,rnt.rent_region_en
	   ,rnt.is_ride
	   ,rnt.reserved_time
	   ,rnt.rated_time
	   ,rnt.ride_time
	   ,rnt.park_time
	   ,rnt.ride_cost
	   ,rnt.park_cost
	   ,rnt.reserved_cost
	   ,rnt.rated_cost
	   ,case when c1.accident_timestamp is not null then 1 else 0 end as accident
	   ,c1.accident_timestamp
	   ,c1.accident_id
	   ,c1.region
	   ,c1.c1_guilty
	   ,c1.order_sum
	   ,COALESCE(rnt.rent_region_en, c1.region) as acc_region
	   ,date_trunc('day',COALESCE(to_timestamp(c1.accident_timestamp, 'MM/DD/YYYY HH12:MI:SS AM'), rnt."End")) as acc_date
from (
	select * from rent
) rnt
full outer join c1 on c1.Rent_id = rnt.rent_id
;