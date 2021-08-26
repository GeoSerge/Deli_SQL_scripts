--create or replace view additional_revenue_from_scoring
select date_trunc('day', rnt."End")
	   ,SUM(((case when rnt."End" <= '2020-10-01 14:00:00' then scr.Pricing_coefficient else coef.DrivingStyle_coefficient end)-1)*rnt.bill_amount) as additional_revenue_from_scoring
from dma.delimobil_rent rnt
left join dma.delimobil_rent_scoring scr on scr.rent_id = rnt.rent_id
left join dma.delimobil_user_coefficient_pricing coef on coef.user_id = rnt.user_id and rnt."Start" BETWEEN coef.from_dtime and coef.to_dtime
where rnt."End" > '2020-04-30' --CURRENT_DATE()-63
	  and not rnt.is_b2b
	  and 0<rnt.cost
group by date_trunc('day', rnt."End")
order by date_trunc('day', rnt."End") asc
;