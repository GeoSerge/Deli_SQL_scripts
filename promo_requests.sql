CREATE TABLE public.sg_promo_requests AS
SELECT 
	User_id
	, SUM(bonus_total) AS bonus_requests_sum
	, COUNT(*) AS bonus_requests_count
	, COUNT(CASE
				WHEN dt >= '2020-01-01' AND COALESCE(bonus_total,0) > 0 THEN launch_id END) AS success_bonus_requests_count
	, COUNT(CASE
				WHEN dt >= '2020-01-01' AND COALESCE(bonus_total,0) = 0 THEN launch_id END) AS failure_bonus_requests_count
	, COUNT(CASE
				WHEN dt < '2020-01-01' THEN launch_id END) AS other_promo_requests_count
FROM DMA.delimobil_promo_code_input
WHERE dt < '2020-01-01'
GROUP BY User_id
ORDER BY SUM(bonus_total) DESC

/* SELECTING USERS WITH MORE THAN ONE PROMO AND MORE THAN ONE ACCIDENT INVOICE */
with promo as 
(
select promo.User_id, count(*) as promo_count
from DMA.delimobil_promo_code_input promo
group by User_id
),
inv as
(
select dic.user_id, count(*) as inv_count
from DMA.delimobil_invoice_current dic
where penalty_type = 'accident'
group by dic.user_id
)
select inv.*, promo.promo_count
from inv
left join promo on inv.user_id = promo.user_id
where promo_count >1 and inv_count BETWEEN 2 and 4

