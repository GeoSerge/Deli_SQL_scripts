with devices as (
select user_id, platform, device_type, min(timestamp_msk), MAX(timestamp_msk) 
from dma.appsflyer_event
where user_id is not null
group by user_id, platform, device_type
order by user_id, MAX(timestamp_msk) desc)
select usr.user_id
	   , RIGHT(LEFT(login,4),3) as mobile_operator
	   , region_name_en
	   , sex
	   , age
	   , license_category
	   , birth_place
	   , AGE_IN_YEARS(CURRENT_DATE, usr.license_set_date) as exp
	   , pdc.PassportDepartmentCode
	   , pn.PassportNumber as citizenship
	   , reg.PassportRegistration as compare_reg_vs_loc
	   , kbm.kbm
	   , devices.platform
	   , devices.device_type
--	   , LEFT(inv.card_mask,6) as BIN
from dma.delimobil_user usr
left join cdds.A_User_PassportDepartmentCode pdc on pdc.User_id = usr.user_id
left join cdds.A_User_PassportNumber pn on pn.User_id = usr.user_id
left join cdds.A_User_PassportRegistration reg on reg.User_id = usr.user_id
left join public.sg_kbm_coefs_10_09_2020 kbm on kbm.user_ext = usr.user_ext
left join devices on devices.user_id = usr.user_id
--left join dma.delimobil_invoice_current inv on inv.user_id = usr.user_id

select *
from dma.appsflyer_event app
left join dma.delimobil_user usr on usr.user_id = app.user_id
where usr.login = '79775886029'
order by timestamp_msk desc

--explain
select user_id, platform, device_type, min(timestamp_msk), MAX(timestamp_msk) 
from dma.appsflyer_event
where user_id is not null
group by user_id, platform, device_type
order by user_id, MAX(timestamp_msk) desc--, platform, device_type

explain
with app as (
select *
from dma.appsflyer_event
order by timestamp_msk desc)
select *
from dma.delimobil_user usr
left join app on app.user_id = usr.user_id
where usr.login = '79775886029'