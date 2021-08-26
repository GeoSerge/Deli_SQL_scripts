with money as (
select usr.user_id
	   , MAX(usr.first_ride) as first_ride
	   , MAX(usr.last_ride) as last_ride
	   , SUM(bill_success) as revenue
	   , COUNT(rnt.rent_id) as rents_count
	   , SUM(case when (rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' or rnt.Brand = 'BMW' or rnt.Brand = 'Fiat' or rnt.Brand = 'MINI') then bill_success else 0 end) as business_rev
	   , SUM(case when (rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' or rnt.Brand = 'BMW' or rnt.Brand = 'Fiat' or rnt.Brand = 'MINI') then 1 else 0 end) as business_rents
from dma.delimobil_rent rnt
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
where rnt."Start" BETWEEN '2020-06-09' and '2020-10-01'
group by usr.user_id)
select * from
(select rnt.user_id
	   , wl.user_ext
	   , ROW_NUMBER() over (PARTITION by rnt.user_id order by rnt."Start" asc) as rn
	   , scr.DrivingStyle_ftrScore
	   , scr.DrivingStyle_delimobilScore
from dma.delimobil_rent rnt
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
left join public.sg_white_list wl on wl.user_ext = rnt.user_ext
where rnt."Start" BETWEEN '2020-06-09' and '2020-10-01' and scr.DrivingStyle_delimobilScore is not null) slct
left join money m on m.user_id = slct.user_id
where slct.rn = 1 and slct.user_ext is not null

select usr.user_id, MAX(usr.first_ride), MIN(usr.first_ride), SUM(bill_success)
from dma.delimobil_rent rnt
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
where rnt."Start" BETWEEN '2020-06-09' and '2020-10-01'
group by usr.user_id

-- WHITE LIST
select rnt.user_id
	   , ROW_NUMBER() OVER (PARTITION BY rnt.user_id ORDER BY scr.to_)
from dma.delimobil_rent rnt
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
from public.sg_white_list

with money as (
select usr.user_id
	   , MAX(usr.activation_dtime) as activation_dtime
	   , MAX(usr.first_ride) as first_ride
	   , MAX(usr.last_ride) as last_ride
	   , SUM(rnt.rated_time_paid+rnt.reserved_time_paid+rnt.park_time+rnt.ride_time) as paid_time
	   , SUM(rnt.ride_time) as ride_time
	   , SUM(bill_success) as revenue
	   , COUNT(rnt.rent_id) as rents_count
	   , SUM(acc.order_sum) as repair_cost
	   , COUNT(acc.accident_timestamp) as accidents_count
	   , SUM(case when (rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' or rnt.Brand = 'BMW' or rnt.Brand = 'Fiat' or rnt.Brand = 'MINI') then rnt.ride_time else 0 end) as business_ride_time
	   , SUM(case when (rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' or rnt.Brand = 'BMW' or rnt.Brand = 'Fiat' or rnt.Brand = 'MINI') then rnt.rated_time_paid+rnt.reserved_time_paid+rnt.park_time+rnt.ride_time else 0 end) as business_paid_time
	   , SUM(case when (rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' or rnt.Brand = 'BMW' or rnt.Brand = 'Fiat' or rnt.Brand = 'MINI') then bill_success else 0 end) as business_rev
	   , SUM(case when (rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' or rnt.Brand = 'BMW' or rnt.Brand = 'Fiat' or rnt.Brand = 'MINI') then 1 else 0 end) as business_rents
	   , SUM(case when (rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' or rnt.Brand = 'BMW' or rnt.Brand = 'Fiat' or rnt.Brand = 'MINI') then acc.order_sum else 0 end) as business_repair_cost
	   , SUM(case when (rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' or rnt.Brand = 'BMW' or rnt.Brand = 'Fiat' or rnt.Brand = 'MINI') and acc.accident_timestamp is not null then 1 else 0 end) as business_accidents 
from dma.delimobil_rent rnt
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
left join dma.accidents_1c acc on acc.Rent_id = rnt.rent_id
where rnt."Start" BETWEEN '2020-06-09' and '2020-11-01'
group by usr.user_id)
select * from
(select wl.user_ext
	   , coef.user_id
	   , ROW_NUMBER() OVER (PARTITION BY coef.user_id ORDER BY coef.to_dtime desc) as rn
	   , coef.DrivingStyle_preScore
	   , coef.DrivingStyle_ftrScore
	   , coef.DrivingStyle_delimobilScore
from public.sg_white_list wl
left join dma.delimobil_user usr on usr.user_ext = wl.user_ext
-- »—œŒÀ‹«”≈Ã DMA.DELIMOBIL_USER_COEFFICIENT_PRICING “. . Õ¿Ã Õ”∆≈Õ Õ¿»¡ŒÀ≈≈ ¿ “”¿À‹Õ€… — Œ–-¡¿ÀÀ œŒÀ‹«Œ¬¿“≈À≈…, œ–≈ƒ”ƒ”Ÿ»≈ — Œ–€ ¬ ƒ¿ÕÕŒÃ ¿Õ¿À»«≈ Õ≈ »Õ“≈–≈—”ﬁ“
left join dma.delimobil_user_coefficient_pricing coef on coef.user_id = usr.user_id) slct
left join money m on m.user_id = slct.user_id
where slct.rn = 1