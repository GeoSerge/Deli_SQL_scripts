create table public.sg_kbm_coefs (
user_ext int,
kbm decimal(10,2))

copy public.sg_kbm_coefs
FROM local 'C:\Users\sgulbin\Work\Analysis\RefusedRegistration\KBM_coefs.csv' 
PARSER fcsvparser(header='true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

select kbm.user_ext
	   , avg(AGE_IN_YEARS(CURRENT_DATE, usr.birthday)) as age
	   , avg(AGE_IN_YEARS(CURRENT_DATE, usr.license_set_date)) as exp
	   , avg(case when sex = 'М' then 1 else 0 end) as sex
	   , avg(kbm.kbm) as kbm
	   , sum(ride_time) as ride_time
	   , sum(ride_time+reserved_time_paid+park_time+rated_time_paid) as paid_time
	   , sum(ride_time+reserved_time_paid+park_time+rated_time_paid)*6.37 as other_losses
	   , sum(bill_success) as revenue
	   , sum(case when acc.accident_timestamp is not null then 1 else 0 end) total_accidents
	   , sum(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then 1 else 0 end) guilty_accidents
	   , sum(case when acc.accident_timestamp is not null then acc.order_sum else 0 end) total_accidents_repair_cost
	   , sum(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end) guilty_accidents_repair_cost
	   , sum(bill_success/1.2-(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end)-(ride_time+reserved_time_paid+park_time+rated_time_paid)*6.37) as EBITDA_est
from dma.delimobil_rent rnt
left join public.sg_kbm_coefs kbm on rnt.user_ext = kbm.user_ext
left join dma.delimobil_user usr on rnt.user_id = usr.user_id
full outer join dma.accidents_1c acc on acc.rent_id = rnt.rent_id
where kbm.kbm = 1.0 and rnt."Start" >= '2020-06-09'
group by kbm.user_ext