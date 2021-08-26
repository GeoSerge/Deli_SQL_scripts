select date_trunc('month', c1.accident_timestamp)
	   , COALESCE(trf.tariff_type, c1.tariff) as tariff
--	   , (case when LEFT(trf.tariff_type,3) = 'B2B' then 'b2b'
--	         when trf.tariff_type = 'Basic' then 'Базовый'
--	         when trf.tariff_type = 'Динамический' then 'Базовый'
--	         when trf.tariff_type = 'БАЗОВЫЙ' then 'Базовый'
--	         when trf.tariff_type = 'СКАЗКА' then 'Сказка' else trf.tariff_type end) as rent_tariff
--	   , (case when c1.tariff  = 'Корпоративный' then 'b2b' else c1.tariff end) as acc_tariff
	   , (case when guilty = 'Виновен' or guilty = 'Обоюдная вина' or guilty = 'Не виновен' then guilty else 'Другое' end) as acc_guilty
	   , sum(order_sum) as acc_order_sum
	   , sum(order_sum_client_presented) as vystavleno
	   , sum(case when vhcl.brand in ('BMW','Mercedes','Mercedes-Benz','MINI','Nissan','KIA') and vhcl.model not in ('Rio', 'Rio X-Line') and c1.order_sum >= 100000 then 75000+(c1.order_sum-100000)*0.25
	   	     when vhcl.brand in ('BMW','Mercedes','Mercedes-Benz','MINI','Nissan','KIA') and vhcl.model not in ('Rio', 'Rio X-Line') and c1.order_sum < 100000 then least(75000.0, c1.order_sum)
	   	     when vhcl.brand not in ('BMW','Mercedes','Mercedes-Benz','MINI','Nissan') and vhcl.model<>'Sportage' and c1.order_sum >= 70000 then 50000+(c1.order_sum-70000)*0.25
	   		 when vhcl.brand not in ('BMW','Mercedes','Mercedes-Benz','MINI','Nissan') and vhcl.model<>'Sportage' and c1.order_sum < 70000 then least(50000.0, c1.order_sum) else 0 end) as synthetic_vystavleno
	   , count(*) as count
from dma.accidents_1c c1
--left join dma.delimobil_rent rnt on rnt.rent_id = c1.Rent_id
left join dma.delimobil_rent_tariff trf on trf.rent_id = c1.Rent_id
left join dma.delimobil_vehicle vhcl on vhcl.Vehicle_id = c1.Vehicle_id
where accident_timestamp BETWEEN '2020-07-01' and '2020-09-30'
group by date_trunc('month', c1.accident_timestamp), COALESCE(trf.tariff_type, c1.tariff), acc_guilty
order by date_trunc('month', c1.accident_timestamp), COALESCE(trf.tariff_type, c1.tariff), acc_guilty

-- CHECKING WHY IN SOME CASES CLIENTS WITH FAIRY TALE TARIFF RECEIVE BILL FOR REPAIR
select trf.tariff_type, c1.tariff, c1.order_sum, c1.order_sum_client_presented, c1.*
--	   , c1.tariff
--	   , sum(c1.order_sum) as repair_cost
--	   , sum(c1.order_sum_client_presented) as vystavleno
from dma.accidents_1c c1
left join dma.delimobil_rent_tariff trf on trf.rent_id = c1.Rent_id
where c1.accident_timestamp BETWEEN '2020-07-01' and '2020-09-30' and trf.tariff_type = 'СКАЗКА' and c1.tariff = 'Сказка'--(trf.tariff_type = 'fairy_tale' or trf.tariff_type = 'СКАЗКА' or c1.tariff = 'Сказка')
--group by trf.tariff_type, c1.tariff
--order by trf.tariff_type, c1.tariff