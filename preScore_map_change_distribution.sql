with prcng as 
(select ps.preScore AS DrivingStyle_coefficient_TO_BE, cp.*
from DMA.delimobil_user_coefficient_pricing cp
left join public.sg_preScore_map_TO_BE ps on cp.DrivingStyle_preScore BETWEEN ps.from_v and ps.to_v
where status = 'active'),
asis as
(select prcng.DrivingStyle_coefficient, count(DISTINCT(prcng.user_id))
from prcng
group by prcng.DrivingStyle_coefficient),
tobe as
(select prcng.DrivingStyle_coefficient_TO_BE, count(DISTINCT(prcng.user_id))
from prcng
group by prcng.DrivingStyle_coefficient_TO_BE)
select a.DrivingStyle_coefficient, t.DrivingStyle_coefficient_TO_BE, a.count, t.count
from asis a
full outer join tobe t on a.DrivingStyle_coefficient = t.DrivingStyle_coefficient_TO_BE
order by a.DrivingStyle_coefficient asc, t.DrivingStyle_coefficient_TO_BE asc

select *
from public.sg_preScore_map spsm 
order by from_v asc

CREATE TABLE public.sg_preScore_map_TO_BE(
from_v decimal(10,4),
to_v decimal(10,4),
preScore decimal(10,2)
)

COPY public.sg_preScore_map_TO_BE
FROM LOCAL'C:/Users/sgulbin/Work/Analysis/FTR_score_v2/preScore_map/preScore_map_TO_BE.csv'
PARSER FCSVPARSER(header = 'true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'