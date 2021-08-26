--Explain
WITH dev as
(
SELECT user_id, device_type, MIN(timestamp_msk), MAX(timestamp_msk) 
FROM DMA.appsflyer_event
WHERE user_id IS NOT NULL and user_id = 19508661
GROUP BY user_id, device_type
ORDER BY user_id, MIN(timestamp_msk) ASC
),
inv as
(
select dic.user_id, dic.invoice_id_first, first_creation, status, amount
from DMA.delimobil_invoice_current dic 
where penalty_type = 'accident' and dic.user_id is not null and dic.user_id = 19508661
order by dic.user_id, invoice_id_first
)
select *
from inv
--left outer join dev on inv.first_creation interpolate previous value dev.

select event_name, COUNT(*) 
from DMA.appsflyer_event ae
left join DMA.delimobil_user du on du.user_id = ae.user_id 
where du.login = '79775886029'
group by event_name 
order by count desc
--order by ae.timestamp_msk desc

select date_trunc('month', ae.timestamp_msk)
from DMA.appsflyer_event ae 
where event_name = 'e_rent_to_end_button'

select count(*)
from DMA.delimobil_rent dr 
left join DMA.delimobil_user du
where du.login = '79775886029'