create table public.sg_accidents_view_rent_to_acc as
with
rent as (
	select r.*, t.tariff_type, AGE_IN_YEARS(r."End", usr.birthday) age, AGE_IN_YEARS(r."End", sd.LicenseSetDate) exp
	from dma.delimobil_rent r
	left join dma.delimobil_rent_tariff t on t.rent_id = r.rent_id
	left join dma.delimobil_user usr on usr.user_id = r.user_id
	left join cdds.A_User_LicenseSetDate sd on sd.user_id = usr.user_id
	where "End" > '2020-06-08 00:00:00'-- and "End" < '2020-07-15 23:59:59'
	and is_b2b = FALSE
	and cost > 0
),
c1 as (
	select
		c1.accident_id::!int as accident_id
	   ,c1.time_stamp
	   ,c1.guilty as c1_guilty
	   ,c1.region
	   ,replace(c1.order_sum, ',', '')::decimal as order_sum
	   ,c1.Rent_id
	from dma.accidents_1c c1
	where c1.accident_id::!int is not null and to_timestamp(c1.time_stamp, 'MM/DD/YYYY HH12:MI:SS AM') > current_date() - interval '1 month'
)
--scr as (
--	select f.rent_id, COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) as pricing
--	from dds.A_Rent_ScoringFlex f
--	join rent r ON r.rent_id = f.rent_id
--	limit 1 over(partition by f.rent_id order by f.actual_dtime desc)
--),
--hd as (
--	select case when LEFT(ticket_id,3) = 'HDE' then RIGHT(ticket_id, LENGTH(ticket_id)-4) ELSE ticket_id END as hde_ticket_id
--		,*
--	from dma.hde_road_accident_tickets
--)
select rnt.rent_id
	   ,rnt.rent_ext
	   ,rnt."Start"
	   ,rnt."End"
	   ,rnt.tariff_type
	   ,rnt.is_completed
	   ,rnt.cost
	   ,rnt.bill_amount
	   ,rnt.bonus_amount
	   ,rnt.bill_status
	   ,rnt.bill_waiting
	   ,rnt.bill_error
	   ,rnt.is_hold
	   ,rnt.is_b2b
	   ,rnt.is_package
	   ,rnt.is_fix
	   ,rnt.is_24h_rent
	   ,rnt.user_id
	   ,rnt.vehicle_id
	   ,rnt.owner_name
	   ,rnt.Brand
	   ,rnt.Model
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
--	   ,case when scr.pricing is NULL and rnt.rent_id is NULL then -1
--	   	     when scr.pricing is NULL and rnt.rent_id is not NULL then -2
--	    else scr.pricing end as pricing
--	   ,hd.*
	   ,case when c1.time_stamp is not null then 1 else 0 end as accident
	   ,c1.time_stamp
	   ,c1.accident_id
	   ,c1.region
	   ,c1.c1_guilty
	   ,c1.order_sum
	   ,COALESCE(rnt.rent_region_en, rg_1c.region_en) as acc_region
	   ,date_trunc('day',COALESCE(to_timestamp(c1.time_stamp, 'MM/DD/YYYY HH12:MI:SS AM'), rnt."End")) as acc_date
from (
	select * from rent
) rnt
--left join scr on scr.Rent_id = rnt.rent_id
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
--full outer join hd on rnt.rent_ext = LEFT(right(hd.link, 14),8)::! int
--full outer join c1 on c1.accident_id = hd.hde_ticket_id
full outer join c1 on c1.Rent_id = rnt.rent_id
--left join public.sg_regions_map rg_hd on rg_hd.region_rus = hd.city
left join public.sg_regions_map rg_1c on rg_1c.region_rus = c1.region