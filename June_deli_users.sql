grant select on public.sg_July_users_w_deli_score to tnurlygayanov

CREATE TABLE public.sg_July_users_w_deli_score AS
SELECT DISTINCT(user_id)
FROM DMA.delimobil_rent dr
LEFT JOIN DMA.delimobil_rent_scoring drs on drs.Rent_id = dr.rent_id 
WHERE "Start" BETWEEN '2021-07-01' AND '2021-07-30' AND ride_time > 0 AND drs.DrivingStyle_delimobilCoefficient = 0.85

select count(*)
from public.sg_July_users_w_deli_score sjuwds 