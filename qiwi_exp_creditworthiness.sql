select 
  du.user_id id,
  du.login phone,
  du.activation_dtime appl_date,
  row_number() over() rn,
  count(*) over() qty,
  coalesce(sum(case when ic.status = 'success' then ic.amount end),0)/sum(ic.amount) target_1_payment_rate,
  coalesce(count(case when ic.last_creation - ic.first_creation>'3days'::interval then ic.invoice_id_first end),0)>0 target_2_def_3_days,
  coalesce(count(case when ic.last_creation - ic.first_creation>'30days'::interval then ic.invoice_id_first end),0)>0 target_3_def_30_days,
  coalesce(count(case when ic.last_creation - ic.first_creation>'90days'::interval then ic.invoice_id_first end),0)>0 target_4_def_90_days,
  coalesce(count(case when ic.status <> 'success'
  					   and ic.last_creation - ic.first_creation>'90days'::interval
  					   and ic.penalty_type in ('contract_other','smoking, trash, dirty','evacuation','accidents','cameras','contract_new_injuries')
  					  then ic.invoice_id_first end),0)>0 target_5_def_90days,
  -- CAMERAS
  coalesce(count(case when ic.penalty_type = 'cameras' and ic.last_creation - ic.first_creation>'90days'::interval then ic.invoice_id_first end),0)>0 target_cam_90days,
  -- CONTRACT NEW INJURIES
  coalesce(count(case when ic.penalty_type = 'contract_new_injuries' and ic.last_creation - ic.first_creation>'90days'::interval then ic.invoice_id_first end),0)>0 target_new_inj_90days,
  -- CONTRACT OTHER
  coalesce(count(case when ic.penalty_type = 'contract_other' and ic.last_creation - ic.first_creation>'90days'::interval then ic.invoice_id_first end),0)>0 target_contract_other_90days,
  -- SMOKING, TRASH, DIRTY
  coalesce(count(case when ic.penalty_type = 'smoking, trash, dirty' and ic.last_creation - ic.first_creation>'90days'::interval then ic.invoice_id_first end),0)>0 target_std_90days,
  -- EVACUATION
  coalesce(count(case when ic.penalty_type = 'evacuation' and ic.last_creation - ic.first_creation>'90days'::interval then ic.invoice_id_first end),0)>0 target_evac_90days,
  -- ACCIDENT
  coalesce(count(case when ic.penalty_type = 'accident' and ic.last_creation - ic.first_creation>'90days'::interval then ic.invoice_id_first end),0)>0 target_acc_90days
from DMA.delimobil_user du 
join DMA.delimobil_invoice_current ic on ic.user_id = du.user_id and ic.amount>0
left join public.qiwi_experiment qe on qe.id = du.user_id 
where du.activation_dtime>='2019-01-01' and qe.for_exp = 'for_experiment'
and du.login~*'^7\d{10}$'
group by 1,2,3