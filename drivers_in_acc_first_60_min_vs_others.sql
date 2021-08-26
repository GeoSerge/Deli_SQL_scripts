select
	agg_ride_time <= 60
	, exp
--	, count(*)
from
	(select
		*
		, ROW_NUMBER() over(PARTITION by user_id order by accident_timestamp asc) as acc_order
	from
		(select 
			du.user_id 
			, du.age 
			, age_in_years(ac.accident_timestamp, du.license_set_date) as exp
			, sum(dr.ride_time) over (PARTITION by dr.User_id order by dr."Start" asc) as agg_ride_time
			, ac.Rent_id as ac_rent_id
			, dr.rent_id as dr_rent_id
			, guilty 
			, ac.accident_timestamp 
		from DMA.accidents_1c ac
		join DMA.delimobil_rent dr on dr.user_id = ac.User_id 
		left join DMA.delimobil_user du on du.user_id = ac.User_id) slct
	where ac_rent_id = dr_rent_id and guilty in ('Виновен', 'Обоюдная вина')) slct2
where acc_order = 1
--group by 1, 2
order by 1--, 2
