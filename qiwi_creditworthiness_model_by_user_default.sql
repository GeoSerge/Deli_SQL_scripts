-- ENRICHING QIWI TEST USER DEFAULT DATA WITH FEATURES FOR ML MODEL
create table public.sg_qiwi_exp_w_features as
with devices as (
select dd.user_id, dd.device_type from 
	(select *, ROW_NUMBER() over (PARTITION by d.user_id ORDER by d.MIN asc) AS rn from
		(select ae.user_id, ae.device_type, MIN(timestamp_msk)
		from DMA.appsflyer_event ae
		left join DMA.delimobil_user du on du.user_id = ae.user_id 
		where date_trunc('day', du.activation_dtime) = date_trunc('day', ae.timestamp_msk) and ae.user_id is not null
		group by ae.user_id, ae.device_type
		order by ae.user_id, MIN(timestamp_msk) asc) d) dd
where dd.rn = 1)
select qe.*
	   , devices.device_type
	   , kbm.kbm
	   , RIGHT(LEFT(usr.login,4),3) as mobile_operator
	   , usr.sex
	   , AGE_IN_YEARS(usr.activation_dtime, usr.birthday) as age
	   , license_category
	   , birth_place
	   , AGE_IN_YEARS(usr.activation_dtime, usr.license_set_date) as exp
from public.qiwi_experiment qe
left join devices on devices.user_id = qe.id
left join DMA.delimobil_user usr on usr.user_id = qe.id
left join public.sg_kbm_coefs_10_09_2020 kbm on usr.user_ext = kbm.user_ext 

select *
from public.sg_qiwi_exp_w_features