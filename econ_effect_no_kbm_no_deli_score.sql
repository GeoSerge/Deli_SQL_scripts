-- RENTS AND ACCIDENTS BY USERS WITH NO DELI SCORE AND NO KBM
select rnt.user_ext
	   , avg(usr_scr.rents_w_ftr_score_only) as rents_w_ftr_score_only
	   , avg(usr_scr.rents_w_deli_score) as rents_w_deli_score
	   , avg(AGE_IN_YEARS(CURRENT_DATE, usr.birthday)) as age
	   , avg(AGE_IN_YEARS(CURRENT_DATE, usr.license_set_date)) as exp
	   , avg(case when sex = 'М' then 1 else 0 end) as sex
	   , avg(kbm.kbm) as kbm
	   , sum(ride_time) as ride_time
	   , sum(ride_time+reserved_time_paid+park_time+rated_time_paid) as paid_time
	   , sum(ride_time+reserved_time_paid+park_time+rated_time_paid)*6.81 as other_losses
	   , sum(bill_success) as revenue
	   , sum(case when acc.accident_timestamp is not null then 1 else 0 end) total_accidents
	   , sum(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then 1 else 0 end) guilty_accidents
	   , sum(case when acc.accident_timestamp is not null then acc.order_sum else 0 end) total_accidents_repair_cost
	   , sum(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end) guilty_accidents_repair_cost
	   , sum(bill_success/1.2-(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end)-(ride_time+reserved_time_paid+park_time+rated_time_paid)*6.81) as EBITDA_est
from dma.delimobil_rent rnt
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
left join public.sg_kbm_coefs kbm on kbm.user_ext = rnt.user_ext
left join dma.accidents_1c acc on acc.Rent_id = rnt.rent_id
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
left join (select rnt.user_id
	   , SUM(case when scr.drivingstyle_prescoreFormula = '(1 * ftr_score)' then 1 else 0 end) as rents_w_ftr_score_only
	   , SUM(case when scr.drivingstyle_prescoreFormula <> '(1 * ftr_score)' then 1 else 0 end) as rents_w_deli_score
from dma.delimobil_rent_scoring scr
left join dma.delimobil_rent rnt on scr.Rent_id = rnt.rent_id
group by rnt.user_id) usr_scr on usr_scr.user_id = rnt.user_id
where kbm.kbm is null and (usr_scr.rents_w_deli_score = 0 or usr_scr.rents_w_deli_score is null) and rnt."Start" >= '2020-06-09'
group by rnt.user_ext