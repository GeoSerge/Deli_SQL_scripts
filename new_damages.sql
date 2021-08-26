create table public.sg_new_damages (
fine_timestamp timestamp,
fine_type varchar(255),
license_plate_number varchar(255),
user_ext int,
status varchar(255),
fine_sum decimal(10,2),
paid_timestamp timestamp,
owner varchar(255),
region varchar(255))

drop table public.sg_new_damages

copy public.sg_new_damages
FROM local 'C:\Users\sgulbin\Work\Analysis\Skazka\new_damages.csv' 
PARSER fcsvparser(header='true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

select COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) as pricing
	   , sum(dmg.fine_sum) as total_new_damages
	   , sum(case when dmg.region = 'Москва' then dmg.fine_sum else 0 end) as new_damages_Msc
	   , sum(case when dmg.region = 'СПб' then dmg.fine_sum else 0 end) as new_damages_Spb
	   , sum(case when dmg.region not in ('Москва', 'СПб') then dmg.fine_sum else 0 end) as new_damages_others
from public.sg_new_damages dmg
left join dma.delimobil_rent rnt on dmg.user_ext = rnt.user_ext and date_trunc('day', rnt."End") = date_trunc('day', dmg.fine_timestamp)
left join cdds.A_Rent_ScoringFlex scr on scr.rent_id = rnt.rent_id
where dmg.fine_timestamp > '2020-06-09 00:00:00' and dmg.fine_type = 'Повреждение ТС'
group by COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6)
order by COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) asc