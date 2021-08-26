-- CREATING FIRST DAY OF THE MONTH FUNCTION
CREATE OR REPLACE FUNCTION public.sg_FIRST_DAY(x date) RETURN date
AS
BEGIN
RETURN DATE_TRUNC('MONTH', x)::date;
END;

-- CREATING LAST DAY OF THE MONTH FUNCTION; NOT DECEMBER
CREATE OR REPLACE FUNCTION public.sg_LAST_DAY(x date) RETURN date
AS
BEGIN
	RETURN (EXTRACT(YEAR FROM x)||'-'||(EXTRACT(MONTH FROM x)+1)||'-01')::date-1;
END;

-- CREATING LAST DAY OF THE MONTH FUNCTION; ONLY DECEMBER
CREATE OR REPLACE FUNCTION public.sg_LAST_DAY12(x date) RETURN date
AS
BEGIN
	RETURN ((EXTRACT(YEAR FROM x)+1)||'-01'||'-01')::date-1;
END;

-- CREATING LAST DAY OF THE MONTH FUNCTION; GENERAL FUNCTION
CREATE OR REPLACE FUNCTION public.sg_LAST_DAY(x date) RETURN date
AS
BEGIN
	RETURN (CASE WHEN EXTRACT(MONTH FROM x) <> 12 THEN (EXTRACT(YEAR FROM x)||'-'||(EXTRACT(MONTH FROM x)+1)||'-01')::date-1 ELSE ((EXTRACT(YEAR FROM x)+1)||'-01'||'-01')::date-1 END);
END;


select public.sg_LAST_DAY(policy_start), public.sg_LAST_DAY12(policy_start), *
from public.sg_osago_policies sop


select date_trunc('month', policy_start)
	   , (case when extract(month from date_trunc('month', policy_start)) = 12 
	   		then public.sg_LAST_DAY12(date_trunc('month', policy_start)) 
	   		else public.sg_LAST_DAY(date_trunc('month', policy_start)) end)
	   ,count(*)
from public.sg_osago_policies sop
where policy_start > '2019-01-01'
group by date_trunc('month', policy_start)
	     , (case when extract(month from date_trunc('month', policy_start)) = 12 
	   		then public.sg_LAST_DAY12(date_trunc('month', policy_start)) 
	   		else public.sg_LAST_DAY(date_trunc('month', policy_start)) end)
order by date_trunc('month', policy_start)

select *
from public.sg_osago_policies sop