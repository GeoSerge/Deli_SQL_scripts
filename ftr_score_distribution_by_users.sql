WITH all_data AS
(SELECT
	cp.user_id 
	, DrivingStyle_coefficient
	, ps_map.preScore AS DrivingStyle_coefficient_AS_IS
	, ps_map2.preScore AS DrivingStyle_coefficient_TO_BE
	, DrivingStyle_ftrScore
	, ftr_map.score AS ftr_score_AS_IS
	, ftr_map2.score AS ftr_score_TO_BE
	, AGE_IN_YEARS(cp.from_dtime, du.birthday) AS age
--	, LEAST(AGE_IN_YEARS(cp.from_dtime, du.license_set_date), AGE_IN_YEARS(cp.from_dtime, du.birthday) - 18) AS exp
	, AGE_IN_YEARS(cp.from_dtime, du.license_set_date) AS exp
	, du.sex
	, kbm.kbm
	, IFNULL(ae.K, 1.16) AS K_age_exp
	, kbm1.k AS K_kbm_AS_IS
	, kbm2.k AS K_kbm_TO_BE
	, (CASE
		WHEN aus.Sex = 2 THEN 1.1
		ELSE 1.0
	  END) AS K_sex
	, LEAST(GREATEST((CASE
		WHEN aus.Sex = 2 THEN 1.1
		ELSE 1.0
	  END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) AS K_ftr_AS_IS
	, LEAST(GREATEST((CASE
		WHEN aus.Sex = 2 THEN 1.1
		ELSE 1.0
	  END)*IFNULL(ae.K, 1.16)*kbm2.k, 0.7), 1.3) AS K_ftr_TO_BE
FROM DMA.delimobil_user_coefficient_pricing cp
LEFT JOIN DMA.delimobil_user du ON du.user_id = cp.user_id 
LEFT JOIN CDDS.A_User_Sex aus on aus.User_id = du.user_id 
LEFT JOIN public.sg_kbm_coefs_02_03_2021 kbm ON kbm.user_ext = du.user_ext
--LEFT JOIN public.sg_k_age_exp_extended ae ON AGE_IN_YEARS(cp.from_dtime, du.birthday) = ae.age AND LEAST(AGE_IN_YEARS(cp.from_dtime, du.license_set_date), AGE_IN_YEARS(cp.from_dtime, du.birthday) - 18) = ae.exper
LEFT JOIN public.sg_k_age_exp_extended ae ON AGE_IN_YEARS(cp.from_dtime, du.birthday) = ae.age AND AGE_IN_YEARS(cp.from_dtime, du.license_set_date) = ae.exper
LEFT JOIN public.sg_k_kbm kbm1 ON IFNULL(kbm.kbm, 0) = IFNULL(kbm1.kbm, 0)
LEFT JOIN public.sg_k_kbm_to_be_ideal kbm2 ON IFNULL(kbm.kbm, 0) = IFNULL(kbm2.kbm, 0)
LEFT JOIN public.aafonin_scoring_score_ftr_final ftr_map ON LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) >= ftr_map.from AND LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) < ftr_map.to
LEFT JOIN public.sg_ftr_map_to_be3 ftr_map2 ON LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) >= ftr_map2.from_v AND LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) < ftr_map2.to_v
--LEFT JOIN public.aafonin_scoring_score_ftr_final ftr_map2 ON LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm2.k, 0.7), 1.3) BETWEEN ftr_map2.from AND ftr_map2.to
LEFT JOIN public.sg_preScore_map ps_map ON ftr_map.score >= ps_map.from_v AND ftr_map.score < ps_map.to_v 
LEFT JOIN public.sg_preScore_map ps_map2 ON ftr_map2.score >= ps_map2.from_v AND ftr_map2.score < ps_map2.to_v 
WHERE status = 'active' AND DrivingStyle_ftrCoefficient = 1 AND cp.from_dtime <'2021-03-01'),
---------------
AS_IS AS
(SELECT
	DrivingStyle_coefficient_AS_IS
	, count(DISTINCT(all_data.user_id)) AS count_AS_IS
FROM all_data
GROUP BY DrivingStyle_coefficient_AS_IS),
--
TO_BE AS
(SELECT
	DrivingStyle_coefficient_TO_BE
	, count(DISTINCT(all_data.user_id)) AS count_TO_BE
FROM all_data
GROUP BY DrivingStyle_coefficient_TO_BE),
-- STATS --
stats AS
(SELECT
	SUM(CASE
			WHEN k_kbm_TO_BE < k_kbm_AS_IS THEN 1
			ELSE 0
		END) AS K_kbm_reduced
	, SUM(CASE
			WHEN k_kbm_TO_BE > k_kbm_AS_IS THEN 1
			ELSE 0
		  END) AS K_kbm_increased
	, SUM(CASE
			WHEN k_kbm_TO_BE = k_kbm_AS_IS THEN 1
			ELSE 0
		  END) AS K_kbm_didnt_change
FROM all_data)
-- RESULT --
--SELECT
--	all_data.user_id
--	, all_data.K_ftr_AS_IS
--	, all_data.ftr_score_AS_IS
--	, all_data.DrivingStyle_coefficient_AS_IS
--FROM all_data
--SELECT
--	ftr_score_AS_IS-DrivingStyle_ftrScore
--	, count(*)
--FROM all_data
--GROUP BY ftr_score_AS_IS-DrivingStyle_ftrScore
--ORDER BY count DESC
--
SELECT
K_ftr_AS_IS
, count(*)
FROM all_data
WHERE DrivingStyle_coefficient_AS_IS IS NULL
GROUP BY K_ftr_AS_IS
--SELECT
--	AS_IS.DrivingStyle_coefficient_AS_IS AS DrivingStyle_coefficient
--	, AS_IS.count_AS_IS
--	, TO_BE.count_TO_BE
--FROM AS_IS
--LEFT JOIN TO_BE on IFNULL(AS_IS.DrivingStyle_coefficient_AS_IS, 0) = IFNULL(TO_BE.DrivingStyle_coefficient_TO_BE, 0)
--ORDER BY AS_IS.DrivingStyle_coefficient_AS_IS ASC

-----------------------------------------------------------------------------------------------------------------------------
/*REPLACE KBM TO BE VALUES*/
UPDATE public.sg_k_kbm_to_be SET k = 1.07 WHERE kbm is null

UPDATE public.sg_k_kbm_to_be SET k = 0.95 WHERE kbm = 0.9

UPDATE public.sg_k_kbm_to_be SET k = 0.8 WHERE kbm < 0.6

UPDATE public.sg_k_kbm_to_be SET k = 0.85 WHERE kbm = 0.6

SELECT
	*
FROM public.sg_k_kbm_to_be skktb 

------------------------------------------------------------------------------------------------------------------------------
/*IDEAL KBM COEFS*/
DROP TABLE public.sg_k_kbm_to_be_ideal

CREATE TABLE public.sg_k_kbm_to_be_ideal(
kbm DECIMAL(10,2),
k   DECIMAL(10,2))

INSERT INTO public.sg_k_kbm_to_be_ideal(kbm, k)
SELECT 0.5, 0.8
UNION
SELECT 0.55, 0.81
UNION
SELECT 0.6, 0.82
UNION
SELECT 0.65, 0.83
UNION
SELECT 0.7, 0.84
UNION
SELECT 0.75, 0.85
UNION
SELECT 0.8, 0.87
UNION
SELECT 0.85, 0.9
UNION
SELECT 0.9, 0.95
UNION
SELECT 0.95, 1.0
UNION
SELECT 1.0, 1.1
UNION
SELECT 1.4, 1.0
UNION
SELECT 1.55, 1.0
UNION
SELECT 2.3, 1.06
UNION
SELECT 2.45, 1.06
UNION
SELECT NULL, 1.07

SELECT
	*
FROM public.sg_k_kbm_to_be_ideal
ORDER BY kbm ASC

-------------------------------------------------------------------------------------------------------------------------------
/*HOW MANY FTRS W/O KBM*/
select count(*)
from DMA.delimobil_user_coefficient_pricing ducp 
left join DMA.delimobil_user du on du.user_id = ducp.user_id 
left join public.sg_kbm_coefs_02_03_2021 kbm on kbm.user_ext = du.user_ext 
WHERE status = 'active' AND DrivingStyle_ftrCoefficient = 1 and  kbm.kbm is null and ducp.from_dtime < '2021-03-01'

-------------------------------------------------------------------------------------------------------------------------------
/*DISTRIBUTION OF FTRS BY AGE AND EXPERIENCE*/
SELECT
	AGE_IN_YEARS(ducp.from_dtime, du.birthday) AS age
	, AGE_IN_YEARS(ducp.from_dtime, du.license_set_date) AS exp
	, COUNT(*)
FROM DMA.delimobil_user_coefficient_pricing ducp 
LEFT JOIN DMA.delimobil_user du on du.user_id = ducp.user_id 
WHERE status = 'active' AND DrivingStyle_ftrCoefficient = 1 AND AGE_IN_YEARS(ducp.from_dtime, du.birthday) BETWEEN 18 AND 70 AND AGE_IN_YEARS(ducp.from_dtime, du.license_set_date) BETWEEN 0 AND 52
GROUP BY AGE_IN_YEARS(ducp.from_dtime, du.birthday), AGE_IN_YEARS(ducp.from_dtime, du.license_set_date)

-------------------------------------------------------------------------------------------------------------------------------
/*CHECHKING HOW CDDS.A_USER_SEX DIFFER FROM SEX IN DMA.DELIMOBIL_USER*/
select du.user_id, du.sex, aus.Sex 
from DMA.delimobil_user du 
left join CDDS.A_User_Sex aus on aus.User_id = du.user_id 
where aus.Sex is not null

-------------------------------------------------------------------------------------------------------------------------------
/*LOADING FTR MAP TO BE v2*/
CREATE TABLE public.sg_ftr_map_to_be2 (
score decimal(10,2),
from_v decimal(10,4),
to_v decimal(10,4))

copy public.sg_ftr_map_to_be2
FROM LOCAL 'C:/Users/sgulbin/Work/Analysis/FTR_score_v2/ftr_map_to_be_v2.csv'
parser fcsvparser(header = 'true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

---------------------------------------------------------------------------------------------------------------------------------
/*LOADING FTR MAP TO BE v3*/
DROP TABLE public.sg_ftr_map_to_be3 

CREATE TABLE public.sg_ftr_map_to_be3 (
score decimal(10,2),
from_v decimal(10,4),
to_v decimal(10,4))

copy public.sg_ftr_map_to_be3
FROM LOCAL 'C:/Users/sgulbin/Work/Analysis/FTR_score_v2/ftr_map_to_be_v3.csv'
parser fcsvparser(header = 'true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

---------------------------------------------------------------------------------------------------------------------------------
/*LOADING FTR MAP TO BE v4*/
DROP TABLE public.sg_ftr_map_to_be4 

CREATE TABLE public.sg_ftr_map_to_be4 (
score decimal(10,2),
from_v decimal(10,4),
to_v decimal(10,4))

copy public.sg_ftr_map_to_be4
FROM LOCAL 'C:/Users/sgulbin/Work/Analysis/FTR_score_v2/ftr_map_to_be_v4.csv'
parser fcsvparser(header = 'true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

select *
from public.sg_ftr_map_to_be4 sfmtb 
order by score asc

select * from public.sg_preScore_map order by preScore asc

---------------------------------------------------------------------------------------------------------------------------------
/*CALCULATING ACCIDENTS FREQUENCY*/
SELECT
	ps_map2.preScore 
	, SUM(CASE
			WHEN ac.guilty = 'Виновен' THEN 1
		  	ELSE 0
		  END)
	, SUM(dr.ride_time)
	, SUM(CASE WHEN ac.guilty = 'Виновен' THEN 1 ELSE 0 END)*1000000/SUM(dr.ride_time)
FROM DMA.delimobil_rent dr
LEFT JOIN DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
LEFT JOIN DMA.delimobil_user du ON du.user_id = dr.user_id 
LEFT JOIN CDDS.A_User_Sex aus on aus.User_id = du.user_id 
LEFT JOIN public.sg_kbm_coefs_02_03_2021 kbm ON kbm.user_ext = du.user_ext
--LEFT JOIN public.sg_k_age_exp_extended ae ON AGE_IN_YEARS(cp.from_dtime, du.birthday) = ae.age AND LEAST(AGE_IN_YEARS(cp.from_dtime, du.license_set_date), AGE_IN_YEARS(cp.from_dtime, du.birthday) - 18) = ae.exper
LEFT JOIN public.sg_k_age_exp_extended ae ON AGE_IN_YEARS(dr."Start" , du.birthday) = ae.age AND AGE_IN_YEARS(dr."Start" , du.license_set_date) = ae.exper
LEFT JOIN public.sg_k_kbm kbm1 ON IFNULL(kbm.kbm, 0) = IFNULL(kbm1.kbm, 0)
LEFT JOIN public.sg_k_kbm_to_be_ideal kbm2 ON IFNULL(kbm.kbm, 0) = IFNULL(kbm2.kbm, 0)
LEFT JOIN public.aafonin_scoring_score_ftr_final ftr_map ON LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) >= ftr_map.from LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) < ftr_map.to
LEFT JOIN public.sg_ftr_map_to_be3 ftr_map2 ON LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) >= ftr_map2.from_v AND LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm1.k, 0.7), 1.3) < ftr_map2.to_v
--LEFT JOIN public.aafonin_scoring_score_ftr_final ftr_map2 ON LEAST(GREATEST((CASE WHEN aus.sex = 2 THEN 1.1 ELSE 1.0 END)*IFNULL(ae.K, 1.16)*kbm2.k, 0.7), 1.3) BETWEEN ftr_map2.from AND ftr_map2.to
LEFT JOIN public.sg_preScore_map ps_map ON ftr_map.score >= ps_map.from_v AND ftr_map.score < ps_map.to_v 
LEFT JOIN public.sg_preScore_map ps_map2 ON ftr_map2.score >= ps_map2.from_v AND ftr_map2.score < ps_map2.to_v 
WHERE dr."Start" BETWEEN '2020-07-01' and '2021-03-01'
GROUP BY ps_map2.preScore
ORDER BY ps_map2.preScore 

select *
from public.sg_preScore_map

INSERT INTO public.sg_preScore_map(from_v, to_v, preScore)
SELECT 0, 0, 1.35
UNION
SELECT 1, 1, 0.8

select * from
public.aafonin_scoring_score_ftr_final

SELECT *
FROM DMA.delimobil_user_coefficient_pricing ducp 

