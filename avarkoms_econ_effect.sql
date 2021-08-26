with a as
(select
	*
	, (case
		when dv.brand in ('Nissan', 'Mini', 'MINI', 'BMW', 'Mercedes', 'Mercedes-Benz') or dv.model = 'Sportage' then 75000
		else 50000
	  end) as deductible
	, (case
		when dv.brand in ('Nissan', 'Mini', 'MINI', 'BMW', 'Mercedes', 'Mercedes-Benz') or dv.model = 'Sportage' then 100000
		else 70000
	  end) as loss_threshold
	, RANDOM() as rand
from DMA.accidents_1c ac
left join DMA.delimobil_vehicle dv on dv.vehicle_id = ac.Vehicle_id 
where accident_timestamp BETWEEN '2020-07-01' and '2020-12-31' and ac.guilty in ('Виновен', 'Обоюдная вина') and tariff <> 'Сказка')
select 	date_trunc('month', accident_timestamp)
		, region
		, count(*) as count
		, sum(case
			when rand <= 0.77 then 1
			else 0
		  end) as count_w_conversion
		, sum(order_sum_client_presented) as order_sum_client_presented
	   	, sum(order_sum) as total_order_sum
	   	, sum(case
	   		when order_sum > loss_threshold then 0.25*(order_sum-loss_threshold) + least(order_sum, deductible)
	   		when order_sum_client_presented >= order_sum and client_agreement_violation_json is not null and order_sum > 300000 then order_sum
	   		else least(order_sum, deductible)
	   	 end) as order_sum_client_presented_model
	   , sum(case
	   		when order_sum > loss_threshold and rand <= 0.77 then 0.25*(order_sum-loss_threshold) + least(order_sum, deductible)
	   		when order_sum_client_presented >= order_sum and client_agreement_violation_json is not null and order_sum > 300000 and rand <= 0.77 then order_sum
	   		when rand <= 0.77 then least(order_sum, deductible)
	   	 end) as order_sum_client_presented_model_w_conversion
from a
group by 1, 2
order by 1 asc


select client_agreement_violation_json, order_sum, order_sum_auto_service, order_sum_client_presented, *--count(*)
from DMA.accidents_1c
where order_sum > 500000







-- checking rents w ftr score that was canceled
select
	dr.av_gmv_cost_ride_min 
	, dr.av_net_cost_ride_min 
	, (dr.cost -dr.park_cost - dr.reserved_cost)/dr.ride_time 
	, drs.*
from DMA.delimobil_rent dr 
left join DMA.delimobil_rent_scoring drs on drs.Rent_id = dr.rent_id 
where dr."Start" BETWEEN '2021-04-24 12:01:00' and '2021-04-24 14:00:00' and DrivingStyle_ftrCoefficient = 1 and dr.Model = 'Polo' and dr.is_b2b = FALSE and dr.is_package = FALSE and dr.is_fix = FALSE and dr.is_24h_rent = FALSE and dr.ride_time > 0

select user_id, amount, first_creation, last_creation, *
from DMA.delimobil_invoice_current dic 
where invoice_type_name = 'Возмещение убытков ДТП'
order by user_id, first_creation asc