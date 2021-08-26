create table public.sg_accidents_by_tod AS
select HOUR(accident_timestamp), COUNT(*)
from DMA.accidents_1c ac 
where HOUR(accident_timestamp) <> 0 and DAYOFWEEK(accident_timestamp) in (7,1)
GROUP BY HOUR(accident_timestamp)
ORDER BY HOUR(accident_timestamp) ASC