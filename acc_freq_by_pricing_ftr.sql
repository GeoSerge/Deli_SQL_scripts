select ps_map2.preScore
	   , SUM(ride_time) ride_time
	   , SUM(case when ac.guilty = 'Виновен' then 1 else 0 end) acc
	   , SUM(case when ac.guilty = 'Виновен' then 1 else 0 end)*1000000/SUM(ride_time) acc_freq
from DMA.delimobil_rent dr 
left join DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
LEFT JOIN DMA.delimobil_user du ON du.user_id = dr.user_id 
LEFT JOIN CDDS.A_User_Sex aus on aus.User_id = du.user_id 
LEFT JOIN public.sg_kbm_coefs_02_03_2021 kbm ON kbm.user_ext = du.user_ext
--LEFT JOIN public.sg_k_age_exp_extended ae ON AGE_IN_YEARS(cp.from_dtime, du.birthday) = ae.age AND LEAST(AGE_IN_YEARS(cp.from_dtime, du.license_set_date), AGE_IN_YEARS(cp.from_dtime, du.birthday) - 18) = ae.exper
LEFT JOIN public.sg_k_age_exp_extended ae ON AGE_IN_YEARS(dr."Start" , du.birthday) = ae.age AND AGE_IN_YEARS(dr."Start" , du.license_set_date) = ae.exper
LEFT JOIN public.sg_k_kbm kbm1 ON IFNULL(kbm.kbm, 0) = IFNULL(kbm1.kbm, 0)
--LEFT JOIN public.sg_k_kbm_to_be_ideal kbm2 ON IFNULL(kbm.kbm, 0) = IFNULL(kbm2.kbm, 0)
LEFT JOIN public.aafonin_scoring_score_ftr_final ftr_map ON LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) BETWEEN ftr_map.from AND ftr_map.to
LEFT JOIN public.sg_ftr_map_to_be2 ftr_map2 ON LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) BETWEEN ftr_map2.from_v AND ftr_map2.to_v
--LEFT JOIN public.aafonin_scoring_score_ftr_final ftr_map2 ON LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm2.k, 0.7), 1.3) BETWEEN ftr_map2.from AND ftr_map2.to
LEFT JOIN public.sg_preScore_map ps_map ON ftr_map.score BETWEEN ps_map.from_v AND ps_map.to_v 
LEFT JOIN public.sg_preScore_map ps_map2 ON ftr_map2.score BETWEEN ps_map2.from_v AND ps_map2.to_v
where dr."Start" >= '2020-07-01' and dr."End" < '2021-03-01'
group by ps_map2.preScore