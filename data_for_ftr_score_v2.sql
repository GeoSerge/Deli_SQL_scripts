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
	   , SUM(rnt.ride_time) as ride_time
	   , SUM(rnt.ride_time+rnt.reserved_time_paid+rnt.rated_time_paid+rnt.park_time) as paid_time
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') then 1 else 0 end) as accidents_count
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') and acc.order_sum <= 20000 then 1 else 0 end) as count_0_20
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') and acc.order_sum BETWEEN 20001 and 40000 then 1 else 0 end) as count_20_40
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') and acc.order_sum BETWEEN 40001 and 100000 then 1 else 0 end) as count_40_100
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') and acc.order_sum > 100000 then 1 else 0 end) as count_100
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') then acc.order_sum else 0 end) as accidents_order_sum
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') and acc.order_sum <= 20000 then acc.order_sum else 0 end) as cost_0_20
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') and acc.order_sum BETWEEN 20001 and 40000 then acc.order_sum else 0 end) as cost_20_40
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') and acc.order_sum BETWEEN 40001 and 100000 then acc.order_sum else 0 end) as cost_40_100
	   , SUM(case when acc.accident_timestamp is not null and (acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина') and acc.order_sum > 100000 then acc.order_sum else 0 end) as cost_100	   
--	   , devices.platform
--	   , devices.device_type
--	   , LEFT(inv.card_mask,6) as BIN
from dma.delimobil_rent rnt
left join dma.accidents_1c acc on acc.rent_id = rnt.rent_id
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
left join cdds.A_User_PassportDepartmentCode pdc on pdc.User_id = usr.user_id
left join cdds.A_User_PassportNumber pn on pn.User_id = usr.user_id
left join cdds.A_User_PassportRegistration reg on reg.User_id = usr.user_id
left join public.sg_kbm_coefs_10_09_2020 kbm on kbm.user_ext = usr.user_ext
--left join devices on devices.user_id = usr.user_id
--left join dma.delimobil_invoice_current inv on inv.user_id = usr.user_id
where rnt."Start" > '2020-06-09' and rnt.is_b2b = FALSE and usr.last_ride > '2020-06-09'
group by usr.user_id
	   , RIGHT(LEFT(login,4),3)
	   , region_name_en
	   , sex
	   , age
	   , license_category
	   , birth_place
	   , AGE_IN_YEARS(CURRENT_DATE, usr.license_set_date)
	   , pdc.PassportDepartmentCode
	   , pn.PassportNumber
	   , reg.PassportRegistration
	   , kbm.kbm