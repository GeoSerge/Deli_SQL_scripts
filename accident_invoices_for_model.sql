grant select on public.sg_accident_invoices_sample access to powerbi

DROP TABLE public.sg_accident_invoices_sample

--CREATE TABLE public.sg_accident_invoices_sample AS
WITH minmax AS
(
SELECT
	user_id
	, MIN(first_creation) AS min_creation
	, MAX(first_creation) AS max_creation
	, MIN(invoice_id_primordial) AS min_primordial
	, MAX(invoice_id_primordial) AS max_primordial
FROM DMA.delimobil_invoice_current
WHERE penalty_type = 'accident' AND amount > 1000
GROUP BY user_id
),
users_to_exclude AS
(
SELECT
	minmax.user_id
FROM minmax
WHERE minmax.min_primordial<>minmax.max_primordial AND TIMESTAMPDIFF('day', minmax.min_creation, minmax.max_creation) > 10
),
inv AS
(
SELECT	
	ic.user_id
	, SUM
	(
	CASE
		WHEN status = 'error' THEN amount 
		ELSE 0
	END
	) AS error_amount
	, SUM
	(
	CASE
		WHEN status = 'error' THEN 1 
		ELSE 0
	END
	) AS error_counr
	, SUM
	(
	CASE
		WHEN status = 'waiting' THEN amount 
		ELSE 0
	END
	) AS waiting_amount
	, SUM
	(
	CASE
		WHEN status = 'waiting' THEN 1 
		ELSE 0
	END
	) AS waiting_count
	, SUM
	(
	CASE
		WHEN status = 'success' THEN amount
		ELSE 0
	END
	) AS success_amount
	, SUM
	(
	CASE
		WHEN status = 'success' THEN 1
		ELSE 0
	END
	) AS success_count
	, MIN(first_creation) AS earliest_creation
	, MAX(last_process) AS last_process
	, MAX(last_creation) AS latest_creation
FROM DMA.delimobil_invoice_current ic
LEFT JOIN DMA.delimobil_user usr on usr.user_id = ic.user_id 
WHERE penalty_type = 'accident' AND amount > 1000 AND ic.user_id NOT IN (SELECT * FROM users_to_exclude)
GROUP BY ic.user_id
ORDER BY ic.user_id
)
SELECT
	inv.user_id
	, inv.earliest_creation AS invoice_creation_dt
	, COALESCE(inv.last_process, inv.latest_creation) AS invoice_close_dt
	, inv.error_amount
	, inv.waiting_amount
	, inv.success_amount
	, (CASE
		WHEN TIMESTAMPDIFF('minute', inv.earliest_creation, CURRENT_TIMESTAMP)/60/24 < 30 THEN 'not applicable'
		WHEN inv.success_amount > 0 AND inv.waiting_amount = 0 AND TIMESTAMPDIFF('minute', inv.earliest_creation, COALESCE(inv.last_process, inv.latest_creation))/60/24 <= 30 THEN 'paid'
		ELSE 'not_paid'
	  END) AS invoice_status
	, (CASE
		WHEN TIMESTAMPDIFF('minute', inv.earliest_creation, CURRENT_TIMESTAMP)/60/24 < 30 THEN 'not applicable'
		WHEN inv.success_amount > 0 AND inv.waiting_amount = 0 AND TIMESTAMPDIFF('minute', inv.earliest_creation, COALESCE(inv.last_process, inv.latest_creation))/60/24 <= 30 THEN 'fully_paid_on_time'
		WHEN inv.success_amount > 0 AND inv.waiting_amount = 0 AND TIMESTAMPDIFF('minute', inv.earliest_creation, COALESCE(inv.last_process, inv.latest_creation))/60/24 > 30 THEN 'fully_paid_past_due'
		WHEN inv.success_amount > 0 AND inv.waiting_amount > 0 AND TIMESTAMPDIFF('minute', inv.earliest_creation, COALESCE(inv.last_process, inv.latest_creation))/60/24 <= 30 THEN 'partially_paid_on_time'
		WHEN inv.success_amount > 0 AND inv.waiting_amount > 0 AND TIMESTAMPDIFF('minute', inv.earliest_creation, COALESCE(inv.last_process, inv.latest_creation))/60/24 > 30 THEN 'partially_paid_past_due'
		ELSE 'not_paid'
	  END) AS invoice_status_detailed
	, ROUND(TIMESTAMPDIFF('minute', inv.earliest_creation, COALESCE(inv.last_process, inv.earliest_creation))/60/24,2) AS invoice_life_length
	, ROUND(TIMESTAMPDIFF('minute', inv.earliest_creation, CURRENT_TIMESTAMP)/60/24,2) AS invoice_start_to_current_date
FROM inv
WHERE inv.waiting_amount + inv.success_amount > 0

DROP TABLE public.sg_qiwi_experiment_v2 

--CREATE TABLE public.sg_qiwi_experiment_v2 AS
SELECT	
	ais.user_id 
	, md5(du.login||'deli19022021') AS phone
	, (CASE
		WHEN invoice_status = 'not_paid' THEN 1
		ELSE 0
	   END) AS target
	, (CASE
		WHEN (success_amount + waiting_amount) >= 25000 THEN -1
		WHEN (success_amount + waiting_amount) < 25000 AND invoice_status = 'not_paid' THEN 1
		ELSE 0
	   END) AS target0
	, (CASE
		WHEN (success_amount + waiting_amount) >= 50000 OR (success_amount + waiting_amount) < 25000 THEN -1
		WHEN (success_amount + waiting_amount) >= 25000 AND (success_amount + waiting_amount) < 50000 AND invoice_status = 'not_paid' THEN 1
		ELSE 0
	   END) AS target25
	, (CASE
		WHEN (success_amount + waiting_amount) >= 100000 OR (success_amount + waiting_amount) < 50000 THEN -1
		WHEN (success_amount + waiting_amount) >= 50000 AND (success_amount + waiting_amount) < 100000 AND invoice_status = 'not_paid' THEN 1
		ELSE 0
	   END) AS target50
	, (CASE
		WHEN (success_amount + waiting_amount) < 100000 THEN -1
		WHEN (success_amount + waiting_amount) >= 100000 AND invoice_status = 'not_paid' THEN 1
		ELSE 0
	   END) AS target100
	, (CASE
		WHEN random() <= 0.666666666 THEN 'train'
		ELSE 'test'
	   END) AS group_name
FROM public.sg_accident_invoices_sample ais
LEFT JOIN DMA.delimobil_user du on du.user_id = ais.user_id 
WHERE invoice_status <> 'not applicable'

/*ADDING THRESHOLD TIMESTAMP TO THE QIWI DATASET*/
DROP TABLE public.sg_qiwi_experiment_v2_1

CREATE TABLE public.sg_qiwi_experiment_v2_1 AS
SELECT
	q.user_id 
	, date_trunc('day', ais.threshold_timestamp) AS threshold_dt
	, q.phone
	, q.target
	, q.target0
	, q.target25
	, q.target50 
	, q.target100
	, q.group_name 
FROM public.sg_qiwi_experiment_v2 q
LEFT JOIN public.sg_accident_invoices_sample_w_ts ais on ais.user_id = q.user_id
WHERE ais.threshold_timestamp IS NOT NULL