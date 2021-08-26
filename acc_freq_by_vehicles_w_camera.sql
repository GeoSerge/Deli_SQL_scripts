create table public.sg_vehicles_w_camera(
license_plates varchar(255))

copy public.sg_vehicles_w_camera
FROM local 'C:\Users\sgulbin\Work\_Ad-hoc_analysis\Делимобиль список СВН.csv' 
PARSER fcsvparser(header='true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

select case when c.license_plates is not null then true else false end as vehicle_w_camera,count(*)
from dma.delimobil_vehicle vhcl
left join public.sg_vehicles_w_camera c on c.license_plates = vhcl.license_plate_number
group by vehicle_w_camera

select acc.vehicle_w_camera 
	, acc.time_period
	, acc.vinoven*1000000/rent_stats.ride_time as acc_freq_vinoven
	, acc.gruppa_razbora
	, acc.ne_ustanovlen
	, acc.vinoven
	, acc.ne_vinoven
	, acc.fake
	, acc.rozysk
	, acc.oboyudnaya_vina
	, rent_stats.rents
	, rent_stats.users
	, rent_stats.ride_time
from (
-- creating pivot of accidents by region, time_period and responsibility
	select case when c.license_plates is not null then true else false end as vehicle_w_camera
		,date_trunc('month', to_timestamp(c1.accident_timestamp, 'MM/DD/YYYY HH12:MI:SS AM')) as time_period
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
	from dma.accidents_1c c1
	left join dma.delimobil_vehicle vhcl on vhcl.Vehicle_id = c1.Vehicle_id
	left join public.sg_vehicles_w_camera c on c.license_plates = vhcl.license_plate_number
	where c1.guilty <> 'Угон' and c1.pool = 'Нет' and to_timestamp(c1.accident_timestamp, 'MM/DD/YYYY HH12:MI:SS AM') between '2019-01-01' and CURRENT_TIMESTAMP
	group by vehicle_w_camera, date_trunc('month', to_timestamp(c1.accident_timestamp, 'MM/DD/YYYY HH12:MI:SS AM'))
) acc
-- joining rent stats
left join (
	select case when c.license_plates is not null then true else false end as vehicle_w_camera
		,date_trunc('month',rnt."Start") as time_period
		,COUNT(rnt.rent_id) as rents
		,COUNT(DISTINCT(rnt.user_id)) as users
		,SUM(rnt.ride_time) as ride_time
	from dma.delimobil_rent rnt
	left join dma.delimobil_vehicle vhcl on vhcl.vehicle_id = rnt.vehicle_id
	left join public.sg_vehicles_w_camera c on c.license_plates = vhcl.license_plate_number
	where rnt."Start" >= '2019-01-01 00:00:00'
		and rnt.cost > 0
		and rnt.is_ride = TRUE
		and vhcl.is_pool = FALSE
		-- setting rent stats max date on the last accident report datetime
		and rnt."Start" < LEAST(
			CURRENT_TIMESTAMP, (
				select max(to_timestamp(accident_timestamp, 'MM/DD/YYYY HH12:MI:SS AM')) from dma.accidents_1c)
				)
	-- ???and is_prime = FALSE
	-- ???and is_b2b = FALSE
	group by vehicle_w_camera, date_trunc('month',rnt."Start")
) rent_stats on rent_stats.vehicle_w_camera = acc.vehicle_w_camera and rent_stats.time_period = acc.time_period
order by acc.time_period asc
;