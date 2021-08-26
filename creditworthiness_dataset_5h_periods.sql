/* GATHERING TRAINING DATASET FOR THE CREDITWORTHINESS MODEL */
explain
WITH last_5h AS 
(
SELECT
	last_5h_ranked.user_id
	, last_5h_ranked.invoice_id
	, last_5h_ranked.End AS threshold_timestamp
	, last_5h_end_rank
FROM
	(
	SELECT
		nearest_rent.*
		, ROW_NUMBER() OVER (PARTITION BY nearest_rent.invoice_id ORDER BY nearest_rent.ride_time_agg ASC) AS last_5h_end_rank
	FROM
		(
		SELECT 
			inv.user_id
			, COALESCE(inv.invoice_id_primordial, inv.invoice_id_first) AS invoice_id
			, NULLIF(GREATEST(SUM(rnt.ride_time) OVER (PARTITION BY inv.invoice_id_last ORDER BY NULLIF(GREATEST(TIMESTAMPDIFF('minute', rnt."End", inv.first_creation),0),0) ASC)-300,0),0) AS ride_time_agg
			, ROW_NUMBER() OVER (PARTITION BY inv.invoice_id_last ORDER BY NULLIF(GREATEST(TIMESTAMPDIFF('minute', rnt."End", inv.first_creation),0),0) ASC) closest_rent_rank
			, rnt.rent_id
			, rnt."Start"
			, rnt."End" 
		FROM DMA.delimobil_invoice_current inv
		JOIN DMA.delimobil_rent rnt on rnt.user_id = inv.user_id 
		WHERE penalty_type = 'accident' AND inv.user_id IS NOT NULL-- AND inv.user_id = 19512565
		) AS nearest_rent
	) AS last_5h_ranked
WHERE last_5h_ranked.last_5h_end_rank = 1
),
promo AS
(SELECT
	*
	, SUM(promo_grouped.bonus_requests_sum) OVER (PARTITION BY promo_grouped.user_id order by promo_grouped.dt) AS sum_agg
	, SUM(promo_grouped.bonus_requests_count) OVER (PARTITION BY promo_grouped.user_id order by promo_grouped.dt) AS count_agg
	, SUM(promo_grouped.success_bonus_requests_count) OVER (PARTITION BY promo_grouped.user_id order by promo_grouped.dt) AS success_count_agg
	, SUM(promo_grouped.failure_bonus_requests_count) OVER (PARTITION BY promo_grouped.user_id order by promo_grouped.dt) AS failure_count_agg
	, SUM(promo_grouped.other_promo_requests_count) OVER (PARTITION BY promo_grouped.user_id order by promo_grouped.dt) AS other_count_agg
FROM
	(
	SELECT
		User_id
		, dt::timestamp+'0ms'::interval dt
		, SUM(bonus_total) AS bonus_requests_sum
		, COUNT(*) AS bonus_requests_count
		, COUNT(CASE
					WHEN dt >= '2020-01-01' AND COALESCE(bonus_total,0) > 0 THEN launch_id END) AS success_bonus_requests_count
		, COUNT(CASE
					WHEN dt >= '2020-01-01' AND COALESCE(bonus_total,0) = 0 THEN launch_id END) AS failure_bonus_requests_count
		, COUNT(CASE
					WHEN dt < '2020-01-01' THEN launch_id END) AS other_promo_requests_count
	FROM DMA.delimobil_promo_code_input
	GROUP BY User_id, dt
	) promo_grouped
),
devices AS
(
SELECT 
	ae.user_id
	, ae.device_type
	, MIN(ae.timestamp_msk)
	, MAX(ae.timestamp_msk)
FROM
DMA.appsflyer_event ae
WHERE event_name = 'e_rent_to_end_button'
GROUP BY ae.user_id, ae.device_type
)
SELECT *
FROM last_5h AS l5h
LEFT OUTER JOIN devices ON l5h.user_id = devices.user_id AND l5h.threshold_timestamp INTERPOLATE PREVIOUS VALUE devices.MIN
LEFT OUTER JOIN promo ON l5h.user_id = promo.user_id AND l5h.threshold_timestamp INTERPOLATE PREVIOUS VALUE promo.dt

------------------------------------------------------------------------

/* BASE FUNCTION RETURNING INVOICES ORDERED BY USER ID  */
SELECt user_id, invoice_id_first, invoice_id_primordial, first_creation, amount, status, *
from DMA.delimobil_invoice_current dic 
where penalty_type = 'accident' and user_id is not null-- and user_id = 19508661
order by user_id, first_creation asc

/* SELECTING INVOICES SAMPLE */
--CREATE TABLE public.sg_accident_invoices_sample_w_ts AS
WITH last_5h AS 
(
SELECT
	last_5h_ranked.*
FROM
	(
	SELECT
		nearest_rent.*
		, ROW_NUMBER() OVER (PARTITION BY nearest_rent.user_id ORDER BY nearest_rent.ride_time_agg ASC) AS last_5h_end_rank
	FROM
		(
		SELECT 
			ais.*
			, NULLIF(GREATEST(SUM(rnt.ride_time) OVER (PARTITION BY ais.user_id ORDER BY NULLIF(GREATEST(TIMESTAMPDIFF('minute', rnt."End", ais.invoice_creation_dt),0),0) ASC)-300,0),0) AS ride_time_agg
--			, ROW_NUMBER() OVER (PARTITION BY ais.user_id ORDER BY NULLIF(GREATEST(TIMESTAMPDIFF('minute', rnt."End", ais.invoice_creation_dt),0),0) ASC) closest_rent_rank
			, rnt."End"  as threshold_timestamp
		FROM public.sg_accident_invoices_sample ais
		JOIN DMA.delimobil_rent rnt on rnt.user_id = ais.user_id 
		) AS nearest_rent
	) AS last_5h_ranked
WHERE last_5h_ranked.last_5h_end_rank = 1
),
psp_data AS
(
SELECT
	pn.User_id 
	, pn.PassportNumber 
	, pn.Actual_dtime 
	, pbp.PassportBirthPlace 
	, pdc.PassportDepartmentCode 
	, pid.PassportIssueDate 
	, pr.PassportRegistration 
FROM DDS.A_User_PassportNumber pn
LEFT JOIN DDS.A_User_PassportBirthPlace pbp on pbp.User_id = pn.User_id 
LEFT JOIN DDS.A_User_PassportDepartmentCode pdc on pdc.User_id = pn.User_id 
LEFT JOIN DDS.A_User_PassportIssueDate pid on pid.User_id = pn.User_id 
LEFT JOIN DDS.A_User_PassportRegistration pr on pr.User_id = pn.User_id
),
devices AS
(
SELECT 
	ae.user_id
	, ae.device_type
	, MIN(ae.timestamp_msk) AS min_device_ts
	, MAX(ae.timestamp_msk) AS max_device_ts
FROM
DMA.appsflyer_event ae
GROUP BY ae.user_id, ae.device_type 
)
SELECT
	l5h.user_id
	, du.login 
	, TIMESTAMPDIFF('day', du.birthday, l5h.threshold_timestamp)/365.25 AS age
	, TIMESTAMPDIFF('day', du.license_set_date, l5h.threshold_timestamp)/365.25 AS exp
	, du.birth_place -- CATEGORIZE!
	, kbm.kbm
	, du.sex
	, dev.device_type
	, du.region_name_en
	, RIGHT(LEFT(du.login,4),3) AS mobile_code
	, du.license_category -- CATEGORIZE
	, pd.PassportDepartmentCode
	, pd.PassportRegistration
	, du.first_name -- CATEGORIZE
	, du.patronymic_name -- CATEGORIZE
	, du.last_name  -- CATEGORIZE
--	, appsflyer features
--	, promocodes
--	, coordinates from ae	
	, l5h.*
FROM last_5h l5h
LEFT JOIN DMA.delimobil_user du on du.user_id = l5h.user_id
LEFT JOIN DDS.A_User_PassportDepartmentCode pdc on pdc.User_id = du.user_id
LEFT JOIN psp_data pd on pd.user_id = l5h.user_id AND l5h.threshold_timestamp INTERPOLATE PREVIOUS VALUE pd.Actual_dtime
LEFT JOIN devices dev on dev.user_id = l5h.user_id AND l5h.threshold_timestamp INTERPOLATE PREVIOUS VALUE dev.min_device_ts
LEFT JOIN public.sg_kbm_coefs_02_03_2021 kbm on kbm.user_ext = du.user_ext


---------------------------------------------------------------------------------------

/* SELECTING INVOICES SAMPLE */
--CREATE TABLE public.sg_accident_invoices_sample_w_ts AS
WITH last_5h AS 
(
SELECT
	last_5h_ranked.*
FROM
	(
	SELECT
		nearest_rent.*
		, ROW_NUMBER() OVER (PARTITION BY nearest_rent.user_id ORDER BY nearest_rent.ride_time_agg ASC) AS last_5h_end_rank
	FROM
		(
		SELECT 
			ais.*
			, NULLIF(GREATEST(SUM(rnt.ride_time) OVER (PARTITION BY dd.id ORDER BY NULLIF(GREATEST(TIMESTAMPDIFF('minute', rnt."End", ais.invoice_creation_dt),0),0) ASC)-300,0),0) AS ride_time_agg
--			, ROW_NUMBER() OVER (PARTITION BY ais.user_id ORDER BY NULLIF(GREATEST(TIMESTAMPDIFF('minute', rnt."End", ais.invoice_creation_dt),0),0) ASC) closest_rent_rank
			, rnt."End"  as threshold_timestamp
		FROM public.sg_datadev_sample_ids dd
		LEFT JOIN public.sg_accident_invoices_sample ais on ais.user_id = dd.id
		JOIN DMA.delimobil_rent rnt on rnt.user_id = ais.user_id 
		) AS nearest_rent
	) AS last_5h_ranked
WHERE last_5h_ranked.last_5h_end_rank = 1
)
SELECT
	*
FROM last_5h l5h
