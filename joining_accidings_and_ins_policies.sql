create table public.sg_osago_policies (
insurance_company varchar(255),
policy_number varchar(255),
policy_start date,
policy_end date,
policy_termination date,
policy_end_fact date,
brand varchar(255),
model varchar(255),
VIN varchar(255))

copy public.sg_osago_policies
FROM local 'C:\Users\sgulbin\Work\Analysis\Insurance\osago.csv' 
PARSER fcsvparser(header='true')
DIRECT
ABORT ON ERROR
REJECTED DATA 'C:\Users\sgulbin\Desktop\Rejections.txt'
EXCEPTIONS 'C:\Users\sgulbin\Desktop\Exceptions.txt'

-- ACCIDENTS FOR JAN, FEB, MARCH
with acc as
(select  vhcl.VIN
	    , c1.accident_timestamp
	    , c1.region
	    , vhcl.brand
	    , vhcl.model
	    , vhcl.platform
	    , vhcl.is_pool
	    , c1.accident_type
	    , c1.guilty
	    , c1.accident_registration_type
	    , c1.order_sum
from dma.accidents_1c c1
left join dma.delimobil_vehicle vhcl on vhcl.Vehicle_id = c1.Vehicle_id
where accident_timestamp BETWEEN '2020-01-01'
	  and '2020-03-31'
	  and guilty = 'Виновен'
	  and (accident_type='Наезд на препятствие' or accident_type='Наезд на пешехода')
	  and vhcl.is_pool = FALSE
order by c1.accident_timestamp asc)
select acc.*, osg.insurance_company, osg.policy_number, osg.policy_start, osg.policy_end_fact
from acc
left join public.sg_osago_policies osg on UPPER(osg.VIN) = UPPER(acc.VIN) and acc.accident_timestamp BETWEEN osg.policy_start and osg.policy_end_fact

-- LOADING ACCIDENTS DATA FOR ONE FLOATING YEAR
select vhcl.is_prime, vhcl.brand, vhcl.model, (case when guilty = 'Не виновен' then guilty else 'Виновен' end) as responsibility, count(*)
from dma.accidents_1c c1
left join dma.delimobil_vehicle vhcl on vhcl.vehicle_id = c1.Vehicle_id
where accident_timestamp BETWEEN '2019-07-01' and '2020-06-30'
group by vhcl.is_prime, vhcl.brand, vhcl.model, (case when guilty = 'Не виновен' then guilty else 'Виновен' end)
order by vhcl.is_prime, brand, model, (case when guilty = 'Не виновен' then guilty else 'Виновен' end), count desc