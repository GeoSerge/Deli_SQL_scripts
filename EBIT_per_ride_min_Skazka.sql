-- EASY APPROACH. CONSIDERING ONLY ACCIDENTS WITH RENT_ID AND RENTS WITH SCORING
select COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) as pricing
	   -- paid time
	   , sum(rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid) as total_paid_time
	   , sum(case when rnt.rent_region_en = 'Moscow' then rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid else 0 end) as paid_time_sum_Msc
	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid else 0 end) as paid_time_sum_Spb
	   , sum(case when rnt.rent_region_en not in ('St. Petersburg', 'Moscow') then rnt.ride_time+rnt.park_time+rnt.reserved_time_paid+rnt.rated_time_paid else 0 end) as paid_time_sum_others
	   -- ride time
	   , sum(rnt.ride_time) as total_ride_time
	   , sum(case when rnt.rent_region_en = 'Moscow' then rnt.ride_time else 0 end) as ride_time_sum_Msc
	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then rnt.ride_time else 0 end) as ride_time_sum_Spb
	   , sum(case when rnt.rent_region_en not in ('St. Petersburg', 'Moscow') then rnt.ride_time else 0 end) as ride_time_sum_others
	   -- rev
	   , sum(rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0)) as total_revenue
	   , sum(case when rnt.rent_region_en = 'Moscow' then rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0) else 0 end) as revenue_Msc
	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0) else 0 end) as revenue_Spb
	   , sum(case when rnt.rent_region_en not in ('Moscow', 'St. Petersburg') then rnt.bill_amount+coalesce(rnt.bill_refund_12,0)-coalesce(rnt.bill_error,0) else 0 end) as revenue_others
	   , sum(acc.order_sum) as total_repair_cost
	   , sum(case when rnt.rent_region_en = 'Moscow' then acc.order_sum else 0 end) as repair_cost_Msc
	   , sum(case when rnt.rent_region_en = 'St. Petersburg' then acc.order_sum else 0 end) as repair_cost_Spb
	   , sum(case when rnt.rent_region_en not in ('St. Petersburg', 'Moscow') then acc.order_sum else 0 end) as repair_cost_Spb
	   , sum(case when acc.order_sum > 30000 then 30000 else acc.order_sum end) as total_repair_cost_TO_BE
	   , sum(case when acc.order_sum > 30000 and rnt.rent_region_en = 'Moscow' then 30000 when acc.order_sum <= 30000 and rnt.rent_region_en = 'Moscow' then acc.order_sum else 0 end) as repair_cost_Msc_TO_BE
	   , sum(case when acc.order_sum > 30000 and rnt.rent_region_en = 'St. Petersburg' then 30000 when acc.order_sum <= 30000 and rnt.rent_region_en = 'St. Petersburg' then acc.order_sum else 0 end) as repair_cost_Spb_TO_BE
	   , sum(case when acc.order_sum > 30000 and rnt.rent_region_en not in ('Moscow', 'St. Petersburg') then 30000 when acc.order_sum <= 30000 and rnt.rent_region_en not in ('Moscow', 'St. Petersburg') then acc.order_sum else 0 end) as repair_cost_others_TO_BE
from dma.delimobil_rent rnt
left join cdds.A_Rent_ScoringFlex scr on scr.Rent_id = rnt.rent_id
left join dma.delimobil_rent_tariff trf on trf.rent_id = rnt.rent_id
left join dma.accidents_1c acc on acc.Rent_id = rnt.rent_id
where rnt."Start" BETWEEN '2020-06-09 00:00:00' and '2020-08-31' and trf.is_skazka = TRUE and rnt.is_b2b = FALSE
group by COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6)
order by COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) asc

-- A MORE CORRECT APPROACH: CONSIDERING ALL ACCIDENTS EVEN THOSE WITH NO RENT_ID, ALSO CONSIDERING RENTS WITH NO SCORING