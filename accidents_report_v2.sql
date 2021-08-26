create table public.sg_accidents_view_test_v2 as
select 
	slct.acc_region
	,slct.acc_date
	,SUM(slct.ride_time) ride_time_sum
	,SUM(slct.cost) cost_sum
	,SUM(case when slct.bill_status = 'success' then slct.bill_amount else 0 end) bill_amount_sum
	,SUM(accident) accidents_count
	,COUNT(case when slct.c1_guilty = 'Виновен' then slct.time_stamp end) as vinoven
	,COUNT(case when slct.c1_guilty = 'Не виновен' then slct.time_stamp end) as ne_vinoven
	,COUNT(case when slct.c1_guilty = 'Не установлен' or slct.guilty is null then slct.time_stamp end) as ne_ustanovlen
	,COUNT(case when slct.c1_guilty = 'Обоюдная вина' then slct.time_stamp end) as oboyudnaya_vina
	,COUNT(case when slct.c1_guilty = 'Фейк' then slct.time_stamp end) as fake
	,COUNT(case when slct.c1_guilty = 'Розыск' then slct.time_stamp end) as rozysk
	,COUNT(case when slct.c1_guilty = 'Группа разбора' then slct.time_stamp end) as gruppa_razbora
	,COUNT(case when slct.c1_guilty = 'Виновен' then replace(slct.c1_order_sum,',','')::NUMERIC else 0 end) as vinoven_order_sum
	,SUM(case when slct.c1_guilty = 'Не виновен' then replace(slct.c1_order_sum,',','')::NUMERIC else 0 end) as ne_vinoven_order_sum
	,SUM(case when slct.c1_guilty = 'Не установлен' or slct.c1_guilty is NULL then replace(slct.c1_order_sum,',','')::NUMERIC else 0 end) as ne_ustanovlen_order_sum
	,SUM(case when slct.c1_guilty = 'Обоюдная вина' then replace(slct.c1_order_sum,',','')::NUMERIC else 0 end) as oboyudnaya_vina_order_sum
	,SUM(case when slct.c1_guilty = 'Фейк' then replace(slct.c1_order_sum,',','')::NUMERIC else 0 end) as fake_order_sum
	,SUM(case when slct.c1_guilty = 'Розыск' then replace(slct.c1_order_sum,',','')::NUMERIC else 0 end) as rozysk_order_sum
	,SUM(case when slct.c1_guilty = 'Группа разбора' then replace(slct.c1_order_sum,',','')::NUMERIC else 0 end) as gruppa_razbora_order_sum
	,SUM(replace(slct.c1_order_sum,',','')::NUMERIC) as total_order_sum
from
(with
rnt as (
	select r.*, t.tariff_type, AGE_IN_YEARS(r."End", usr.birthday) age, AGE_IN_YEARS(r."End", sd.LicenseSetDate) exp
	from dma.delimobil_rent r
	left join dma.delimobil_rent_tariff t on t.rent_id = r.rent_id
	left join dma.delimobil_user usr on usr.user_id = r.user_id
	left join cdds.A_User_LicenseSetDate sd on sd.user_id = usr.user_id
	where "End" >= '2020-06-09 00:00:00'-- and "End" < '2020-07-15 23:59:59'
	and is_b2b = FALSE
	and cost > 0
),
c1 as (
	select
		c1.accident_id::!int as accident_id
	   ,c1.time_stamp
	   ,c1.guilty as c1_guilty
	   ,c1.region
	   ,c1.order_sum as c1_order_sum
	from dma.accidents_1c c1
	where c1.accident_id::!int is not null and to_timestamp(c1.time_stamp,'MM/DD/YYYY HH12:MI:SS AM') >= '2020-06-09 00:00:00'
	order by accident_id
),
--scr as (
--	select f.rent_id, COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) as pricing
--	from dds.A_Rent_ScoringFlex f
--	join rent r ON r.rent_id = f.rent_id
--	limit 1 over(partition by f.rent_id order by f.actual_dtime desc)
--),
hd as (
	select case when LEFT(ticket_id,3) = 'HDE' then RIGHT(ticket_id, LENGTH(ticket_id)-4) ELSE ticket_id END as hde_ticket_id
		,*
	from dma.hde_road_accident_tickets
	where accident_date >= '2020-06-09'
)
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
	   ,hd.*
	   ,case when hd.ticket_id is not null or c1.time_stamp is not null then 1 else 0 end as accident
	   ,c1.time_stamp
	   ,c1.accident_id
	   ,c1.region
	   ,c1.c1_guilty
	   ,c1.c1_order_sum
	   ,COALESCE(rnt.rent_region_en, rg1.region_en, rg2.region_en) as acc_region
	   ,date_trunc('day',COALESCE(to_timestamp(c1.time_stamp, 'MM/DD/YYYY HH12:MI:SS AM'),hd.accident_date, rnt."End")) as acc_date
from rnt
--left join scr on scr.Rent_id = rnt.rent_id
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
full outer join hd on rnt.rent_ext = LEFT(right(hd.link, 14),8)::! int
full outer join c1 on c1.accident_id = hd.hde_ticket_id
left join public.sg_regions_map rg1 on rg1.region_rus = c1.region
left join public.sg_regions_map rg2 on rg2.region_rus = hd.city) slct
group by slct.acc_region, slct.acc_date