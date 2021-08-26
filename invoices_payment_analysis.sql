--with device as (
--select * from
--	(select ROW_NUMBER() OVER (PARTITION BY ae.user_id ORDER BY ae.last_usage_timestamp DESC) as rn, ae.* from
--		(select user_id
--	   	 		, device_type
--	   			, MIN(timestamp_msk) as first_usage_timestamp
--	   			, MAX(timestamp_msk) as last_usage_timestamp
--		from DMA.appsflyer_event 
--		where user_id is not null
--		group by user_id , device_type) ae) ae_rn
--	where ae_rn.rn = 1)
select inv.user_id --1
	   , RIGHT(LEFT(usr.login,4),3) as mobile_code --2
	   , AVG(AGE_IN_YEARS(CURRENT_DATE, usr.birthday)) as age --3
	   , AVG(AGE_IN_YEARS(CURRENT_DATE, usr.license_set_date)) as exp --4
	   , usr.birth_place --5
	   , l.city --6
	   , l.country --7
	   , usr.sex --8
	   , usr.region_name_en --9
	   , usr.license_category --10
--	   , device.device_type --11
	   , reg.PassportRegistration --12
	   , pdc.PassportDepartmentCode --13
	   , AVG(DATEDIFF(day, usr.registration_dtime, CURRENT_DATE)/365.25) as years_since_registration --14
	   , AVG(DATEDIFF(day, usr.activation_dtime, CURRENT_DATE)/365.25) as years_since_activation --15
	   , AVG(DATEDIFF(day, usr.last_ride, CURRENT_DATE)/365.25) as years_since_last_ride --16
	   , AVG(usr.rents_count) as rents_count --17
	   , AVG(usr.bill_total) as bill_total --18
	   , AVG(usr.bonus_total) as bonus_total --19
	   , AVG(usr.last_month_ride) as last_month_ride --20
	   , AVG(usr.avg_week_rents) as avg_week_rents --21
	   , usr.region_name_en as rent_region --22
	   , usr.country_ext --23
	   , usr.tariff --24
	   -- sum of invoices by type
	   -- sum of total invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) then inv.amount else 0 end) as total_invoices_sum
	   -- sum of rent invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and invoice_type_name = 'Аренда' then inv.amount else 0 end) as rent_invoices_sum
	   -- sum of camera invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and invoice_type_name in ('Штрафы с камер (скидка 50)', 'Штраф с камер')
	   		then inv.amount else 0 end) as camera_invoices_sum
	   -- sum of agreement invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and invoice_type_name = 'Штраф по договору'
	   		then inv.amount else 0 end) as agreement_invoices_sum	
	   -- sum of accident invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and invoice_type_name = 'Возмещение убытков ДТП'
	   		then inv.amount else 0 end) as accident_invoices_sum
	   -- sum of other invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and invoice_type_name not in ('Возмещение убытков ДТП', 'Аренда',
	   		'Штрафы с камер (скидка 50)', 'Штраф с камер', 'Штраф по договору') then inv.amount else 0 end) as other_invoices_sum
	   -- count of invoices by type
--	   , count(inv.invoice_amount) as total_invoices_count
--	   , sum(case when inv.invoice_type_name = 'Аренда' then 1 else 0 end) as rent_invoices_count
--	   , sum(case when inv.invoice_type_name = 'Холдирование' or inv.invoice_type_name = 'Холдирование для fix тарифа' then 1 else 0 end) as hold_invoices_count
--	   , sum(case when inv.invoice_type_name = 'Штраф с камер' then 1 else 0 end) as camera_invoices_count
--	   , sum(case when inv.invoice_type_name = 'Штраф с камер (Скидка 50)' then 1 else 0 end) as camera50_invoices_count
--	   , sum(case when inv.invoice_type_name = 'Штраф по договору' then 1 else 0 end) as agreement_invoices_count
--	   , sum(case when inv.invoice_type_name = 'Возмещение убытков ДТП' then 1 else 0 end) as accident_invoices_count
	   -- sum of paid invoices by type
	   -- total invoices
	   , sum(case when status = 'success' and DATEDIFF('day', first_creation, last_process) <=3 then inv.amount else 0 end) as total_paid_invoices_3_days_sum
	   , sum(case when status = 'success' and DATEDIFF('day', first_creation, last_process) <=7 then inv.amount else 0 end) as total_paid_invoices_7_days_sum
	   , sum(case when status = 'success' and DATEDIFF('day', first_creation, last_process) <=30 then inv.amount else 0 end) as total_paid_invoices_30_days_sum
	   , sum(case when status = 'success' and DATEDIFF('day', first_creation, last_process) <=60 then inv.amount else 0 end) as total_paid_invoices_60_days_sum
	   , sum(case when status = 'success' and DATEDIFF('day', first_creation, last_process) <=90 then inv.amount else 0 end) as total_paid_invoices_90_days_sum
	   , sum(case when status = 'success' and DATEDIFF('day', first_creation, last_process) <=180 then inv.amount else 0 end) as total_paid_invoices_180_days_sum
	   , sum(case when status = 'success' then inv.amount else 0 end) as total_paid_invoices_sum
	   -- rent invoices
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Аренда' and DATEDIFF('day', first_creation, last_process) <=3 
	   		then inv.amount else 0 end) as paid_rent_invoices_3_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Аренда' and DATEDIFF('day', first_creation, last_process) <=7 
	   		then inv.amount else 0 end) as paid_rent_invoices_7_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Аренда' and DATEDIFF('day', first_creation, last_process) <=30 
	   		then inv.amount else 0 end) as paid_rent_invoices_30_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Аренда' and DATEDIFF('day', first_creation, last_process) <=60 
	   		then inv.amount else 0 end) as paid_rent_invoices_60_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Аренда' and DATEDIFF('day', first_creation, last_process) <=90 
	   		then inv.amount else 0 end) as paid_rent_invoices_90_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Аренда' and DATEDIFF('day', first_creation, last_process) <=180 
	   		then inv.amount else 0 end) as paid_rent_invoices_180_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Аренда' then inv.amount else 0 end) as paid_rent_invoices_sum
	   -- camera invoices
	   , sum(case when inv.status = 'success' and invoice_type_name in ('Штрафы с камер (скидка 50)', 'Штраф с камер') and DATEDIFF('day', first_creation, last_process) <=3 
	   		then inv.amount else 0 end) as paid_camera_invoices_3_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name in ('Штрафы с камер (скидка 50)', 'Штраф с камер') and DATEDIFF('day', first_creation, last_process) <=7 
	   		then inv.amount else 0 end) as paid_camera_invoices_7_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name in ('Штрафы с камер (скидка 50)', 'Штраф с камер') and DATEDIFF('day', first_creation, last_process) <=30 
	   		then inv.amount else 0 end) as paid_camera_invoices_30_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name in ('Штрафы с камер (скидка 50)', 'Штраф с камер') and DATEDIFF('day', first_creation, last_process) <=60 
	   		then inv.amount else 0 end) as paid_camera_invoices_60_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name in ('Штрафы с камер (скидка 50)', 'Штраф с камер') and DATEDIFF('day', first_creation, last_process) <=90 
	   		then inv.amount else 0 end) as paid_camera_invoices_90_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name in ('Штрафы с камер (скидка 50)', 'Штраф с камер') and DATEDIFF('day', first_creation, last_process) <=180 
	   		then inv.amount else 0 end) as paid_camera_invoices_180_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name in ('Штрафы с камер (скидка 50)', 'Штраф с камер') then inv.amount else 0 end) as paid_camera_invoices_sum
	   -- agreement invoices
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Штраф по договору' and DATEDIFF('day', first_creation, last_process) <=3 
	   		then inv.amount else 0 end) as paid_agreement_invoices_3_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Штраф по договору' and DATEDIFF('day', first_creation, last_process) <=7 
	   		then inv.amount else 0 end) as paid_agreement_invoices_7_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Штраф по договору' and DATEDIFF('day', first_creation, last_process) <=30 
	   		then inv.amount else 0 end) as paid_agreement_invoices_30_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Штраф по договору' and DATEDIFF('day', first_creation, last_process) <=60 
	   		then inv.amount else 0 end) as paid_agreement_invoices_60_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Штраф по договору' and DATEDIFF('day', first_creation, last_process) <=90 
	   		then inv.amount else 0 end) as paid_agreement_invoices_90_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Штраф по договору' and DATEDIFF('day', first_creation, last_process) <=180 
	   		then inv.amount else 0 end) as paid_agreement_invoices_180_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Штраф по договору' then inv.amount else 0 end) as paid_agreement_invoices_sum
	   -- accident invoices
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Возмещение убытков ДТП' and DATEDIFF('day', first_creation, last_process) <=3 
	   		then inv.amount else 0 end) as paid_accident_invoices_3_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Возмещение убытков ДТП' and DATEDIFF('day', first_creation, last_process) <=7 
	   		then inv.amount else 0 end) as paid_accident_invoices_7_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Возмещение убытков ДТП' and DATEDIFF('day', first_creation, last_process) <=30 
	   		then inv.amount else 0 end) as paid_accident_invoices_30_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Возмещение убытков ДТП' and DATEDIFF('day', first_creation, last_process) <=60 
	   		then inv.amount else 0 end) as paid_accident_invoices_60_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Возмещение убытков ДТП' and DATEDIFF('day', first_creation, last_process) <=90 
	   		then inv.amount else 0 end) as paid_accident_invoices_90_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Возмещение убытков ДТП' and DATEDIFF('day', first_creation, last_process) <=180 
	   		then inv.amount else 0 end) as paid_accident_invoices_180_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name = 'Возмещение убытков ДТП' then inv.amount else 0 end) as paid_accident_invoices_sum
	   -- other invoices
	   , sum(case when inv.status = 'success' and invoice_type_name not in ('Возмещение убытков ДТП', 'Аренда', 'Штрафы с камер (скидка 50)', 'Штраф с камер',
	   		'Штраф по договору') and DATEDIFF('day', first_creation, last_process) <=3 then inv.amount else 0 end) as paid_other_invoices_3_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name not in ('Возмещение убытков ДТП', 'Аренда', 'Штрафы с камер (скидка 50)', 'Штраф с камер',
	   		'Штраф по договору') and DATEDIFF('day', first_creation, last_process) <=7 then inv.amount else 0 end) as paid_other_invoices_7_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name not in ('Возмещение убытков ДТП', 'Аренда', 'Штрафы с камер (скидка 50)', 'Штраф с камер',
	   		'Штраф по договору') and DATEDIFF('day', first_creation, last_process) <=30 then inv.amount else 0 end) as paid_other_invoices_30_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name not in ('Возмещение убытков ДТП', 'Аренда', 'Штрафы с камер (скидка 50)', 'Штраф с камер',
	   		'Штраф по договору') and DATEDIFF('day', first_creation, last_process) <=60 then inv.amount else 0 end) as paid_other_invoices_60_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name not in ('Возмещение убытков ДТП', 'Аренда', 'Штрафы с камер (скидка 50)', 'Штраф с камер',
	   		'Штраф по договору') and DATEDIFF('day', first_creation, last_process) <=90 then inv.amount else 0 end) as paid_other_invoices_90_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name not in ('Возмещение убытков ДТП', 'Аренда', 'Штрафы с камер (скидка 50)', 'Штраф с камер',
	   		'Штраф по договору') and DATEDIFF('day', first_creation, last_process) <=180 then inv.amount else 0 end) as paid_other_invoices_180_days_sum
	   , sum(case when inv.status = 'success' and invoice_type_name not in ('Возмещение убытков ДТП', 'Аренда', 'Штрафы с камер (скидка 50)', 'Штраф с камер',
	   		'Штраф по договору') then inv.amount else 0 end) as paid_other_invoices_sum
	   -- count of paid invoices by type
--	   , sum(case when inv.invoice_status = 'success'then 1 else 0 end) as total_paid_invoices_count
--	   , sum(case when inv.invoice_status = 'success' and inv.invoice_type_name = 'Аренда' then 1 else 0 end) as paid_rent_invoices_count
--	   , sum(case when inv.invoice_status = 'success' and (inv.invoice_type_name = 'Холдирование' or inv.invoice_type_name = 'Холдирование для fix тарифа') then 1 else 0 end) as paid_hold_invoices_count
--	   , sum(case when inv.invoice_status = 'success' and inv.invoice_type_name = 'Штраф с камер' then 1 else 0 end) as paid_camera_invoices_count
--	   , sum(case when inv.invoice_status = 'success' and inv.invoice_type_name = 'Штраф с камер (Скидка 50)' then 1 else 0 end) as paid_camera50_invoices_count
--	   , sum(case when inv.invoice_status = 'success' and inv.invoice_type_name = 'Штраф по договору' then 1 else 0 end) as paid_agreement_invoices_count
--	   , sum(case when inv.invoice_status = 'success' and inv.invoice_type_name = 'Возмещение убытков ДТП' then 1 else 0 end) as paid_accident_invoices_count
from dma.delimobil_invoice_current inv
left join dma.delimobil_user usr on usr.user_id = inv.user_id
left join DDS.A_User_PassportDepartmentCode pdc on pdc.user_id = usr.user_id
left join public.locations l on l.PassportBirthPlace = usr.birth_place
left join public.sg_kbm_coefs_10_09_2020 kbm on kbm.user_ext = usr.user_ext
--left join device on device.user_id = usr.user_id
left join CDDS.A_User_PassportRegistration reg on reg.User_id = usr.user_id
where inv.first_creation BETWEEN '2020-03-01' and '2020-08-31'
	  and inv.invoice_type_name<>'Привязка карты' 
	  and inv.invoice_type_name <> 'Возврат' 
	  and usr.activation_dtime is not NULL
group by 1,2,5,6,7,8,9,10,11,12,21,22,23--,13,22,23,24
HAVING sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) then inv.amount else 0 end) > 100

select dfr.User_id
--	   , lbl.DestLabel
	   , (case when lbl.DestLabel = 'home' then fa.FullAddress else null end) as home_address
	   , (case when lbl.DestLabel = 'work' then fa.FullAddress else null end) as work_address 
--	   , lat_to
--	   , lon_to
--	   , ROUND(dfr.lat_to,2) as lat_to
--	   , ROUND(dfr.lon_to,2) as lon_to
	   , MIN(dfr.request_created_at)
	   , MAX(dfr.request_created_at)
from DMA.delimobil_fix_request dfr
left join CDDS.A_FixRequest_DestLabel lbl on lbl.FixRequest_id = dfr.request_id
left join CDDS.T_FixSuggestion_FixRequest sgst on sgst.FixRequest_id = dfr.request_id 
left join CDDS.A_FixSuggestion_FullAddress fa on sgst.FixSuggestion_id = fa.FixSuggestion_id 
left join CDDS.A_FixSuggestion_MainAddress ma on sgst.FixSuggestion_id = ma.FixSuggestion_id 
left join CDDS.A_FixSuggestion_SecondaryAddress sa on sgst.FixSuggestion_id = sa.FixSuggestion_id 
left join CDDS.T_FixSuggestion_Region reg on sgst.FixSuggestion_id = reg.FixSuggestion_id 
left join CDDS.A_FixSuggestion_Final fin on sgst.FixSuggestion_id = fin.FixSuggestion_id
where (lbl.DestLabel = 'work' or lbl.DestLabel = 'home') and dfr.User_id is not null and fa.FullAddress is not NULL 
group by 1,2,3
order by dfr.User_id , MAX(dfr.request_created_at) desc

select penalty_type, SUM(penalty_amount), AVG(penalty_amount), COUNT(*) 
from DMA.delimobil_invoice_current dic
where invoice_type_name = 'Штраф по договору'
GROUP BY penalty_type
ORDER BY SUM(penalty_amount)

select DISTINCT (invoice_type_name)
from DMA.delimobil_invoice_current dic 
where penalty_type  = 'cameras'