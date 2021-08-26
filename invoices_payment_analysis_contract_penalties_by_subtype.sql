select inv.user_id --1
	   -- sum of agreement accident invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and penalty_type = 'accident'
	   		then inv.amount else 0 end) as agreement_accident_invoices_sum
	   -- sum of agreement smoking, trash, dirty invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and penalty_type = 'smoking, trash, dirty'
	   		then inv.amount else 0 end) as agreement_STD_invoices_sum
	   -- sum of agreement evacuation invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and penalty_type = 'evacuation'
	   		then inv.amount else 0 end) as agreement_evacuation_invoices_sum
	   -- sum of agreement new injuries invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and penalty_type = 'contract_new_injuries'
	   		then inv.amount else 0 end) as agreement_new_injuries_invoices_sum
	   -- sum of agreement other invoices
	   , sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) and penalty_type = 'contract_other'
		    then inv.amount else 0 end) as agreement_other_invoices_sum
	   -- agreement invoices by penalty type
	   , sum(case when inv.status = 'success' and penalty_type = 'accident' then inv.amount else 0 end) as paid_agreement_accident_invoices_sum
	   , sum(case when inv.status = 'success' and penalty_type = 'smoking, trash, dirty' then inv.amount else 0 end) as paid_agreement_STD_invoices_sum
	   , sum(case when inv.status = 'success' and penalty_type = 'evacuation' then inv.amount else 0 end) as paid_agreement_evacuation_invoices_sum
	   , sum(case when inv.status = 'success' and penalty_type = 'contract_new_injuries' then inv.amount else 0 end) as paid_agreement_new_injuries_invoices_sum
	   , sum(case when inv.status = 'success' and penalty_type = 'contract_other' then inv.amount else 0 end) as paid_agreement_other_invoices_sum
from dma.delimobil_invoice_current inv
left join dma.delimobil_user usr on usr.user_id = inv.user_id
left join DDS.A_User_PassportDepartmentCode pdc on pdc.user_id = usr.user_id
left join public.locations l on l.PassportBirthPlace = usr.birth_place
left join public.sg_kbm_coefs_10_09_2020 kbm on kbm.user_ext = usr.user_ext
left join CDDS.A_User_PassportRegistration reg on reg.User_id = usr.user_id
where inv.first_creation BETWEEN '2020-03-01' and '2020-08-31'
	  and inv.invoice_type_name<>'Привязка карты' 
	  and inv.invoice_type_name <> 'Возврат' 
	  and usr.activation_dtime is not NULL
group by inv.user_id
HAVING sum(case when (invoice_id_primordial is null or invoice_id_primordial = invoice_id_first) then inv.amount else 0 end) > 100

-- SAVING DELIMOBIL SCORE
select prtition.user_id
	   , prtition.DrivingStyle_delimobilScore
	   from
(select dr.user_id
	   , scr.DrivingStyle_delimobilScore
	   , ROW_NUMBER() OVER (PARTITION BY dr.user_id ORDER BY dr."Start" DESC) as rn
from DMA.delimobil_rent dr 
left join DMA.delimobil_rent_scoring scr on scr.Rent_id = dr.rent_id 
where scr.DrivingStyle_delimobilScore is not NULL and dr."Start" BETWEEN '2019-01-01' and '2020-08-31') prtition
where prtition.rn = 1