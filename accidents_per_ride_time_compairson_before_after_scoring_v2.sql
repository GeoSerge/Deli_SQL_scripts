grant select on public.sg_acc_freq_before_vs_after_scoring to powerbi
create table public.sg_acc_freq_before_vs_after_scoring as

create or replace view bi.v_acc_freq_before_vs_after_scoring as
select acc.region
	, acc.time_period
	, acc.insurance_company
	, acc.gruppa_razbora
	, acc.ne_ustanovlen
	, acc.vinoven
	, acc.ne_vinoven
	, acc.fake
	, acc.rozysk
	, acc.oboyudnaya_vina
	, acc.repair_cost
	, acc.gruppa_razbora_repair_cost
	, acc.ne_ustanovlen_repair_cost
	, acc.vinoven_repair_cost
	, acc.ne_vinoven_repair_cost
	, acc.fake_repair_cost
	, acc.rozysk_repair_cost
	, acc.oboyudnaya_vina_repair_cost
	, rent_stats.rents
	, rent_stats.users
	, rent_stats.ride_time
from (
-- creating pivot of accidents by region, time_period and responsibility
	select mp.region_en as region
		,date_trunc('month', accident_timestamp) as time_period
		,ins_n.Name as insurance_company
		,COUNT(
			case when c1.guilty = 'Группа разбора' then c1.accident_timestamp end
		) as gruppa_razbora
		,COUNT(
			case when c1.guilty = 'Не установлен' or c1.guilty is NULL then c1.accident_timestamp end
		) as ne_ustanovlen
		,COUNT(
			case when c1.guilty = 'Виновен' then c1.accident_timestamp end
		) as vinoven
		,COUNT(
			case when c1.guilty = 'Не виновен' then c1.accident_timestamp end
		) as ne_vinoven
		,COUNT(
			case when c1.guilty = 'Фейк' then c1.accident_timestamp end
		) as fake
		,COUNT(
			case when c1.guilty = 'Розыск' then c1.accident_timestamp end
		) as rozysk
		,COUNT(
			case when c1.guilty = 'Обоюдная вина' then c1.accident_timestamp end
		) as oboyudnaya_vina
		,SUM(order_sum) as repair_cost
		,SUM(
			case when c1.guilty = 'Группа разбора' then order_sum end
		) as gruppa_razbora_repair_cost
		,SUM(
			case when c1.guilty = 'Не установлен' or c1.guilty is NULL then order_sum end
		) as ne_ustanovlen_repair_cost
		,SUM(
			case when c1.guilty = 'Виновен' then order_sum end
		) as vinoven_repair_cost
		,SUM(
			case when c1.guilty = 'Не виновен' then order_sum end
		) as ne_vinoven_repair_cost
		,SUM(
			case when c1.guilty = 'Фейк' then order_sum end
		) as fake_repair_cost
		,SUM(
			case when c1.guilty = 'Розыск' then order_sum end
		) as rozysk_repair_cost
		,SUM(
			case when c1.guilty = 'Обоюдная вина' then order_sum end
		) as oboyudnaya_vina_repair_cost
	from dma.accidents_1c c1
	left join public.sg_regions_map mp on c1.region = mp.region_rus
	left join dma.delimobil_vehicle vhcl on vhcl.Vehicle_id = c1.Vehicle_id
	left join dds.T_Vehicle_InsuranceCompany ins_id on ins_id.Vehicle_id = vhcl.vehicle_id
	left join dds.A_InsuranceCompany_Name ins_n on ins_n.InsuranceCompany_id = ins_id.InsuranceCompany_id
	where c1.guilty <> 'Угон' and c1.pool = 'Нет' and accident_timestamp between '2019-01-01' and CURRENT_TIMESTAMP
	group by mp.region_en, date_trunc('month', accident_timestamp), ins_n.Name
) acc
-- joining rent stats
left join (
	select rnt.rent_region_en as rent_region_en
		,date_trunc('month',rnt."Start") as time_period
		,ins_n.Name as insurance_company
		,COUNT(rnt.rent_id) as rents
		,COUNT(DISTINCT(rnt.user_id)) as users
		,SUM(rnt.ride_time) as ride_time
	from dma.delimobil_rent rnt
	left join dma.delimobil_vehicle vhcl on vhcl.vehicle_id = rnt.vehicle_id
	left join dds.T_Vehicle_InsuranceCompany ins_id on ins_id.Vehicle_id = vhcl.vehicle_id
	left join dds.A_InsuranceCompany_Name ins_n on ins_n.InsuranceCompany_id = ins_id.InsuranceCompany_id
	where rnt."Start" >= '2019-01-01 00:00:00'
		and rnt.cost > 0
		and rnt.is_ride = TRUE
		and vhcl.is_pool = FALSE
		-- setting rent stats max date on the last accident report datetime
		and rnt."Start" < LEAST(
			CURRENT_TIMESTAMP, (
				select max(accident_timestamp) from dma.accidents_1c)
				)
	-- ???and is_prime = FALSE
	-- ???and is_b2b = FALSE
	group by rnt.rent_region_en, date_trunc('month',rnt."Start"), ins_n.Name
) rent_stats on rent_stats.rent_region_en = acc.region and rent_stats.time_period = acc.time_period and rent_stats.insurance_company = acc.insurance_company
;