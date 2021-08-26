-- EASY APPROACH. CONSIDERING ONLY ACCIDENTS WITH RENT_ID AND RENTS WITH SCORING
select (case when COALESCE(rnt."End",acc.accident_timestamp) <= '2020-10-01 14:00:00' then scr.DrivingStyle_preScore else coef.DrivingStyle_preScore end) as scoring
	   -- paid time
	   , count(DISTINCT(acc.accident_number))
	   , sum(rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid) as total_paid_time
--	   , sum(case when rnt.rent_region_en = 'Moscow' then rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid else 0 end) as paid_time_sum_Msc
--	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid else 0 end) as paid_time_sum_Spb
--	   , sum(case when rnt.rent_region_en not in ('St. Petersburg', 'Moscow') then rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid else 0 end) as paid_time_sum_others
	   -- ride time
	   , sum(rnt.ride_time) as total_ride_time
--	   , sum(case when rnt.rent_region_en = 'Moscow' then rnt.ride_time else 0 end) as ride_time_sum_Msc
--	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then rnt.ride_time else 0 end) as ride_time_sum_Spb
--	   , sum(case when rnt.rent_region_en not in ('St. Petersburg', 'Moscow') then rnt.ride_time else 0 end) as ride_time_sum_others
	   -- rev
	   , sum(rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0)) as total_revenue
--	   , sum(case when rnt.rent_region_en = 'Moscow' then rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0) else 0 end) as revenue_Msc
--	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0) else 0 end) as revenue_Spb
--	   , sum(case when rnt.rent_region_en not in ('Moscow', 'St. Petersburg') then rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0) else 0 end) as revenue_others
	   -- repair cost
	   , sum(acc.order_sum) as total_repair_cost
	   , sum(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end) as guilty_repair_cost
--	   , sum(case when rnt.rent_region_en = 'Moscow' then acc.order_sum else 0 end) as repair_cost_Msc
--	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then acc.order_sum else 0 end) as repair_cost_Spb
--	   , sum(case when rnt.rent_region_en not in ('St. Petersburg', 'Moscow') then acc.order_sum else 0 end) as repair_others
	   -- other losses
	   , sum(rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid)*5.43 as other_losses
	   -- EBITDA
	   , sum((rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0))/1.2-(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end)-(rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid)*5.93) as EBITDA_est
from dma.delimobil_rent rnt
left join dma.delimobil_user_coefficient_pricing coef on coef.user_id = rnt.user_id
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
--left join dma.delimobil_rent_tariff trf on trf.rent_id = rnt.rent_id
left join dma.accidents_1c acc on acc.Rent_id = rnt.rent_id
where rnt."Start" BETWEEN '2020-09-02 00:00:00' and '2020-10-22' and rnt.is_b2b = FALSE -- trf.is_skazka = TRUE and rnt.is_b2b = FALSE
group by (case when COALESCE(rnt."End",acc.accident_timestamp) <= '2020-10-01 14:00:00' then scr.DrivingStyle_preScore else coef.DrivingStyle_preScore end)
order by (case when COALESCE(rnt."End",acc.accident_timestamp) <= '2020-10-01 14:00:00' then scr.DrivingStyle_preScore else coef.DrivingStyle_preScore end) asc

-- SHORT VERSION. EBITDA PER SCORING
select scr.DrivingStyle_preScore as scoring
	   -- accidents
	   , count(DISTINCT(acc.accident_number))
	   -- paid time
	   , sum(rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid) as total_paid_time
	   -- ride time
	   , sum(rnt.ride_time) as total_ride_time
	   -- rev
	   , sum(rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0)) as total_revenue
	   -- repair cost
	   , sum(acc.order_sum) as total_repair_cost
	   , sum(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end) as guilty_repair_cost
	   -- other losses
	   , sum(rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid)*6.0 as other_losses
	   -- EBITDA
	   , sum((rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0))/1.2-(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end)-(rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid)*6.0) as EBITDA_est
from dma.delimobil_rent rnt
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
left join dma.accidents_1c acc on acc.Rent_id = rnt.rent_id
where rnt."Start" BETWEEN '2020-10-15' and '2020-11-15' and rnt.is_b2b = FALSE
group by scr.DrivingStyle_preScore
order by scr.DrivingStyle_preScore asc

-- BUSINESS CLASS
select (case when COALESCE(rnt."End",acc.accident_timestamp) <= '2020-10-01 14:00:00' then scr.DrivingStyle_ftrScore else coef.DrivingStyle_ftrScore end) as scoring
	   -- paid time
	   , sum(rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid) as total_paid_time
--	   , sum(case when rnt.rent_region_en = 'Moscow' then rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid else 0 end) as paid_time_sum_Msc
--	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid else 0 end) as paid_time_sum_Spb
--	   , sum(case when rnt.rent_region_en not in ('St. Petersburg', 'Moscow') then rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid else 0 end) as paid_time_sum_others
	   -- ride time
	   , sum(rnt.ride_time) as total_ride_time
--	   , sum(case when rnt.rent_region_en = 'Moscow' then rnt.ride_time else 0 end) as ride_time_sum_Msc
--	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then rnt.ride_time else 0 end) as ride_time_sum_Spb
--	   , sum(case when rnt.rent_region_en not in ('St. Petersburg', 'Moscow') then rnt.ride_time else 0 end) as ride_time_sum_others
	   -- rev
	   , sum(rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0)) as total_revenue
--	   , sum(case when rnt.rent_region_en = 'Moscow' then rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0) else 0 end) as revenue_Msc
--	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0) else 0 end) as revenue_Spb
--	   , sum(case when rnt.rent_region_en not in ('Moscow', 'St. Petersburg') then rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0) else 0 end) as revenue_others
	   -- repair cost
	   , sum(acc.order_sum) as total_repair_cost
	   , sum(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end) as guilty_repair_cost
--	   , sum(case when rnt.rent_region_en = 'Moscow' then acc.order_sum else 0 end) as repair_cost_Msc
--	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then acc.order_sum else 0 end) as repair_cost_Spb
--	   , sum(case when rnt.rent_region_en not in ('St. Petersburg', 'Moscow') then acc.order_sum else 0 end) as repair_others
	   -- other losses
	   , sum((rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid)*(case when rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' then 6.92
	   																					   when rnt.Brand = 'BMW' then 6.28
	   																					   when rnt.Brand = 'MINI' then 5.41
	   																					   when rnt.Brand = 'FIAT' then 6.99 end)) as other_losses
	   -- EBITDA
--	   , sum((rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0))/1.2-(case when acc.guilty = 'Виновен' or acc.guilty = 'Обоюдная вина' then acc.order_sum else 0 end)-(rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid)*5.93) as EBITDA_est
from dma.delimobil_rent rnt
left join dma.delimobil_user_coefficient_pricing coef on coef.user_id = rnt.user_id
left join dma.delimobil_rent_scoring scr on scr.Rent_id = rnt.rent_id
--left join dma.delimobil_rent_tariff trf on trf.rent_id = rnt.rent_id
left join dma.accidents_1c acc on acc.Rent_id = rnt.rent_id
where rnt."Start" BETWEEN '2020-09-02 00:00:00' and '2020-10-22'
	  and rnt.is_b2b = FALSE
	  and (rnt.Brand = 'Mercedes' or rnt.Brand = 'Mercedes-Benz' or rnt.Brand = 'BMW' or rnt.Brand = 'MINI' or rnt.Brand = 'FIAT')-- trf.is_skazka = TRUE and rnt.is_b2b = FALSE
group by (case when COALESCE(rnt."End",acc.accident_timestamp) <= '2020-10-01 14:00:00' then scr.DrivingStyle_ftrScore else coef.DrivingStyle_ftrScore end)
order by (case when COALESCE(rnt."End",acc.accident_timestamp) <= '2020-10-01 14:00:00' then scr.DrivingStyle_ftrScore else coef.DrivingStyle_ftrScore end) asc

-- A MORE CORRECT APPROACH: CONSIDERING ALL ACCIDENTS EVEN THOSE WITH NO RENT_ID, ALSO CONSIDERING RENTS WITH NO SCORING