drop table public.sg_agg_ride_hours_distribution

create table public.sg_agg_ride_hours_distribution as
with a as
(select
	dr.user_id
	, LEAST(FLOOR(sum(ride_time)/60),100) as cum_ride_hours
	, sum(ride_time) as ride_time 
	, sum(cost) as cost
from DMA.delimobil_rent dr
where ride_time >= 0
group by dr.user_id)
select
	cum_ride_hours
	, count(user_id) as users
	, sum(ride_time) as ride_time
	, sum(cost) as cost
from a
group by 1
order by 1

create table public.sg_agg_ride_hours_before_first_acc_distribution as
with a as
(select
	ac.user_id 
	, min(ac.accident_timestamp) first_acc
from DMA.accidents_1c ac
group by 1),
b as
(select
	dr.user_id 
	, LEAST(FLOOR(sum(ride_time)/60),100) as cum_ride_hours_until_acc
from DMA.delimobil_rent dr 
left join a on a.user_id = dr.user_id 
where date_trunc('day', a.first_acc) >= date_trunc('day', dr."Start")
group by 1)
select
	cum_ride_hours_until_acc
	, count(user_id)
from b
group by 1
order by 1