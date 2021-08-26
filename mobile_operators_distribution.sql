/*LOADING MOBILE CODES TO DATABASE*/
DROP TABLE public.sg_mobile_codes

CREATE TABLE public.sg_mobile_codes(
mobile_code varchar(255),
mobile_operator varchar(255))

COPY public.sg_mobile_codes
FROM LOCAL 'C:/Users/sgulbin/Work/Analysis/Платежеспособность/data_lib/mobile_codes_lib.csv'
PARSER fcsvparser(haeder = 'true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

SELECT
	*
FROM public.sg_mobile_codes

/*DISTRIBUTION OF USERS BY MOBILE CODES*/
WITH users AS
(SELECT
	du.user_id 
	, (CASE
		WHEN LEFT(du.login, 2) = '77' THEN RIGHT(LEFT(du.login, 5), 3)
		ELSE RIGHT(LEFT(du.login, 4), 3)
	  END) AS mobile_code
	, du.*
FROM DMA.delimobil_user du)
SELECT
	mc.mobile_operator
	, SUM(CASE
			WHEN users.last_ride >= '2021-01-01' THEN 1
			ELSE 0
		  END) AS count_active
	, SUM(CASE
			WHEN users.activation_dtime is not null THEN 1
			ELSE 0
		  END) AS count_activated
	, COUNT(*) AS count_total
FROM users
LEFT JOIN public.sg_mobile_codes mc on users.mobile_code = mc.mobile_code
GROUP BY mc.mobile_operator
ORDER BY count_activated DESC
