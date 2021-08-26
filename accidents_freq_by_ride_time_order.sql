SELECT dr.user_id, rent_id, "Start", "End", ride_time,
	FLOOR((SUM(ride_time) OVER(PARTITION BY dr.user_id ORDER BY dr."Start"))/300) AS _order
	, SUM(CASE WHEN ac.accident_timestamp IS NOT NULL THEN 1 ELSE 0 END)
	, SUM(dr.ride_time)
FROM DMA.delimobil_rent dr 
LEFT JOIN DMA.delimobil_user du on du.user_id = dr.user_id
LEFT JOIN DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
WHERE dr."Start" >= '2020-01-01' AND du.rides_count > 0 AND du.login = '79775886029'
ORDER BY dr.user_id, dr."Start";

SELECT dr.user_id, dr."Start", dr.ride_time, ac.accident_timestamp, ac.guilty
	, FLOOR((SUM(ride_time) OVER(PARTITION BY dr.user_id ORDER BY dr."Start"))/300) AS _order
FROM DMA.delimobil_rent dr 
LEFT JOIN DMA.delimobil_user du on du.user_id = dr.user_id
LEFT JOIN DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
WHERE dr."Start" >= '2020-01-01' AND du.rides_count > 0