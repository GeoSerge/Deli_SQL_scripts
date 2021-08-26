SELECT
	(CASE
		WHEN dr."Start" >= '2021-04-09 16:20:00' THEN 'test'
		ELSE 'before_test'
	 END) AS period
	, (CASE
		WHEN MOD(dr.user_ext, 2) = 0 THEN 'control'
		WHEN MOD(dr.user_ext, 2) = 1 THEN 'test'
	   END) AS test_group
	, SUM(CASE
			WHEN ac.accident_timestamp IS NOT NULL AND ac.guilty IN ('Виновен', 'Обоюдная вина') THEN 1
		    ELSE 0
	  	  END) AS guilty_accidents
	, SUM(dr.ride_time) AS ride_time
	, COUNT(DISTINCT(dr.user_ext)) AS distinct_users
FROM DMA.delimobil_rent dr
LEFT JOIN DMA.accidents_1c ac on ac.Rent_id = dr.rent_id
LEFT JOIN DMA.delimobil_rent_scoring scr on scr.Rent_id = dr.rent_id 
WHERE dr."Start" >= '2021-01-01 00:00:00' AND scr.DrivingStyle_ftrCoefficient = 1
GROUP BY 1,2
ORDER BY 1,2

SELECT
	dr.user_ext 
	, (CASE
		WHEN MOD(dr.user_ext, 2) = 0 THEN 'control'
		WHEN MOD(dr.user_ext, 2) = 1 THEN 'test'
	   END) AS test_group
	, SUM(CASE
			WHEN ac.accident_timestamp IS NOT NULL AND ac.guilty IN ('Виновен', 'Обоюдная вина') THEN 1
		    ELSE 0
	  	  END) AS guilty_accidents
	, SUM(dr.ride_time) AS ride_time
FROM DMA.delimobil_rent dr
LEFT JOIN DMA.accidents_1c ac on ac.Rent_id = dr.rent_id
LEFT JOIN DMA.delimobil_rent_scoring scr on scr.Rent_id = dr.rent_id 
WHERE dr."Start" >= '2021-04-09 16:20:00' AND dr."Start" < '2021-04-18 00:00:00' AND scr.DrivingStyle_ftrCoefficient = 1
GROUP BY 1,2
ORDER BY 1,2