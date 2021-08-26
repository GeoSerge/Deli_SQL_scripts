with rnt as(
select rent_id
	   , "Start"
	   , "End"
	   , cost
	   , ride_time
	   , (park_time + reserved_time + ride_time + rated_time) as rent_time
	   , rent_region_en
	   , Brand
from dma.delimobil_rent
where "Start" BETWEEN '2020-06-09' and '2020-10-01'
	  and cost > 0
	  and is_b2b = FALSE
	  and Brand in ('BMW', 'Mercedes', 'Mercedes-Benz', 'Audi', 'Fiat', 'MINI')),
c1 as (
select c1.rent_id
	   , guilty
	   , order_sum
	   , order_sum_client_presented
	   , driver_drunk
	   , leave_as_is
	   , no_repairs
	   , c1.region
	   , tariff
	   , User_id
	   , c1.Vehicle_id
	   , vhcl.brand
from dma.accidents_1c c1
left join dma.delimobil_vehicle vhcl on vhcl.vehicle_id = c1.Vehicle_id
where c1.accident_timestamp BETWEEN '2020-06-09' and '2020-10-01'
	  and vhcl.brand in ('BMW', 'Mercedes', 'Mercedes-Benz', 'Audi', 'Fiat', 'MINI'))
select rnt.*
	   , c1.*
	   , COALESCE(rnt.Brand, c1.brand) as vehicle_brand
	   , trf.tariff_type
	   , (case when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is not null then -2.0
       		   when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is null then -1.0
       		   else COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) end) as pricing
	   , COALESCE("preScore"['preScoreMemberList']['0']['score'],  "coefficients"['0']['data']['preScoreMemberList']['1']['score']) as ftr_score
	   , COALESCE("preScore"['preScoreMemberList']['1']['score'],  "coefficients"['0']['data']['preScoreMemberList']['0']['score']) as deli_score
	   , COALESCE("preScore"['score'], "coefficients"['0']['data']['score'] ) as final_score
from rnt
left join dma.delimobil_rent_tariff trf on trf.rent_id = rnt.rent_id
left join cdds.A_Rent_ScoringFlex scr on scr.rent_id = rnt.rent_id
full outer join c1 on c1.Rent_id = rnt.rent_id