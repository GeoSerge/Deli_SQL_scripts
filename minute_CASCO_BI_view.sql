-- CREATING P&L ACCIDENT REPAIRS TABLE
create table public.sg_pl_repairs_by_month(
year_month timestamp,
repairs_sum int,
compensation_from_ins int)

insert into public.sg_pl_repairs_by_month (year_month, repairs_sum, compensation_from_ins)
values ('2020-12-01 00:00:00', 83058236, 22095047)

SELECT
	*
FROM public.sg_pl_repairs_by_month

-- CALCULATING ORDER SUM BY MONTH W/O OTHER FILTERS
DROP public.sg_report_test

CREATE TABLE public.sg_minute_CASCO_BI_view AS
WITH order_sum_by_month AS
(
SELECT
	DATE_TRUNC('month', dr2."Start") AS year_month
	, SUM(CASE
			WHEN ac2.guilty in ('Виновен', 'Обоюдная вина') THEN ac2.order_sum 
			ELSE 0 
		  END) AS monthly_guilty_order_sum
    , SUM(CASE
    		WHEN ac2.order_sum < 30000 THEN 0
    		WHEN ac2.order_sum >= 30000 AND ac2.guilty in('Виновен', 'Обоюдная вина') THEN ac2.order_sum
    		ELSE 0
    	  END) monthly_guilty_order_sum_to_be_compensated
FROM DMA.delimobil_rent dr2 
LEFT JOIN DMA.accidents_1c ac2 on ac2.Rent_id = dr2.rent_id 
WHERE dr2."Start" BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY DATE_TRUNC('month', dr2."Start")
),
-- P&L REPAIRS COST BY MONTH
pl_repairs_by_month AS
(
SELECT
	year_month
	, repairs_sum-compensation_from_ins AS pl_guilty_repairs
FROM public.sg_pl_repairs_by_month
)
-- GATHERING REPORT
SELECT
	DATE_TRUNC('month', dr."Start") AS year_month
	, dr.Brand 
	, (CASE
		WHEN dr.Model in ('320i', '320i Premium') THEN '3-Series'
		WHEN dr.Model in ('Cooper 3D', 'Cooper 5D') THEN 'Cooper'
		WHEN dr.Model in ('Solaris ECO', 'Solaris') THEN 'Solaris'
		WHEN dr.Model in ('Polo ECO', 'Polo', 'Polo VI') THEN 'Polo'
		WHEN dr.Model in ('Rio X', 'Rio X-Line') THEN 'Rio X-Line'
		ELSE dr.Model
	  END) AS Model
	, (CASE
		WHEN dr.rent_region_en in ('Krasnoyarsk', 'Rostov-on-Don', 'Grozny', 'Ufa') THEN 'closed_regions'
		ELSE dr.rent_region_en 
	  END) AS Region
	, drt.is_skazka
	, SUM(dr.ride_time) AS ride_time 
	, SUM(CASE
			WHEN ac.guilty in ('Виновен', 'Обоюдная вина') THEN ac.order_sum 
			ELSE 0 
		  END) AS guilty_order_sum
    , SUM(CASE
    		WHEN ac.order_sum < 30000 THEN 0
    		WHEN ac.order_sum >= 30000 AND ac.guilty in('Виновен', 'Обоюдная вина') THEN ac.order_sum
    		ELSE 0
    	  END) guilty_order_sum_to_be_compensated
    , AVG(osm.monthly_guilty_order_sum) AS monthly_guilty_order_sum
    , AVG(osm.monthly_guilty_order_sum_to_be_compensated) AS monthly_guilty_order_sum_to_be_compensated
    , AVG(pl.pl_guilty_repairs) AS pl_monthly_repairs_sum
FROM DMA.delimobil_rent dr 
LEFT JOIN DMA.accidents_1c ac on ac.Rent_id = dr.rent_id 
LEFT JOIN DMA.delimobil_rent_tariff drt on drt.rent_id = dr.rent_id
LEFT JOIN order_sum_by_month osm on osm.year_month = DATE_TRUNC('month', dr."Start")
LEFT JOIN pl_repairs_by_month pl on pl.year_month = DATE_TRUNC('month', dr."Start")
LEFT JOIN DMA.delimobil_vehicle dv on dv.vehicle_id = dr.vehicle_id 
WHERE dr."Start" BETWEEN '2020-01-01' AND '2020-12-31' AND dv.is_pool = FALSE AND dv.is_prime = FALSE
GROUP BY 1, 2, 3, 4, 5