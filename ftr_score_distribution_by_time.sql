select date_trunc('day', rnt."Start")
--	   , case when scr.DrivingStyle_ftrCoefficient -- users
	   , SUM(case when scr.DrivingStyle_ftrCoefficient =1 THEN 1 else 0 end) as no_deli_score -- rents with no deli_score
	   , SUM(case when scr.DrivingStyle_ftrScore <= 0.1 THEN 1 else 0 end) as ftr_01 -- rents with ftr_score<=0.1
	   , SUM(case when scr.DrivingStyle_ftrScore <= 0.2 and scr.DrivingStyle_ftrScore > 0.1 THEN 1 else 0 end) as ftr_02
	   , SUM(case when scr.DrivingStyle_ftrScore <= 0.3 and scr.DrivingStyle_ftrScore > 0.2 THEN 1 else 0 end) as ftr_03
	   , SUM(case when scr.DrivingStyle_ftrScore <= 0.4 and scr.DrivingStyle_ftrScore > 0.3 THEN 1 else 0 end) as ftr_04
	   , SUM(case when scr.DrivingStyle_ftrScore <= 0.5 and scr.DrivingStyle_ftrScore > 0.4 THEN 1 else 0 end) as ftr_05
	   , SUM(case when scr.DrivingStyle_ftrScore <= 0.6 and scr.DrivingStyle_ftrScore > 0.5 THEN 1 else 0 end) as ftr_06
	   , SUM(case when scr.DrivingStyle_ftrScore <= 0.7 and scr.DrivingStyle_ftrScore > 0.6 THEN 1 else 0 end) as ftr_07
	   , SUM(case when scr.DrivingStyle_ftrScore <= 0.8 and scr.DrivingStyle_ftrScore > 0.7 THEN 1 else 0 end) as ftr_08
	   , SUM(case when scr.DrivingStyle_ftrScore <= 0.9 and scr.DrivingStyle_ftrScore > 0.8 THEN 1 else 0 end) as ftr_09
	   , SUM(case when scr.DrivingStyle_ftrScore <= 1.0 and scr.DrivingStyle_ftrScore > 0.9 THEN 1 else 0 end) as ftr_10
	   , SUM(case when scr.DrivingStyle_ftrScore is NULL THEN 1 else 0 end) as ftr_null
	   , COUNT(*) as total_rents
from dma.delimobil_rent rnt
left join dma.delimobil_rent_scoring scr on scr.rent_id = rnt.rent_id
where rnt.cost > 0 and rnt.is_b2b = FALSE and rnt."Start" >= '2020-06-09'
group by date_trunc('day', rnt."Start")
order by date_trunc('day', rnt."Start") asc

select rnt.rent_id, rnt."Start", usr.user_id, usr.age, age_in_years(CURRENT_DATE, usr.license_set_date) as exp, sx.Sex, kbm, scr.DrivingStyle_ftrScore, scr.DrivingStyle_ftrCoefficient
from dma.delimobil_rent rnt
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
left join dds.A_User_Sex sx on usr.user_id = sx.User_id
left join public.sg_kbm_coefs_10_09_2020 kbm on kbm.user_ext = rnt.user_ext
where rnt.cost > 0 and rnt.is_b2b = FALSE and rnt."Start" BETWEEN '2020-10-01' and '2020-10-07' and scr.DrivingStyle_ftrScore <= 0.1

select rnt."Start", usr.user_ext, sx.Sex, kbm.kbm, scr.*
from dma.delimobil_rent rnt
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
left join dds.A_User_Sex sx on sx.user_id = rnt.user_id
left join public.sg_kbm_coefs_10_09_2020 kbm on kbm.user_ext = usr.user_ext
where usr.login = '79775886029'
order by rnt."Start" desc

select *
from dma.delimobil_vehicle
where license_plates_number = ''
