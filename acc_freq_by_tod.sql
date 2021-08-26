grant select on public.sg_acc_freq_by_tod to powerbi

create table public.sg_acc_freq_by_tod as
select (case when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is not null then -2.0
       		   when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is null then -1.0
       		   else COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) end) as pricing
	   , AGE_IN_YEARS(rnt."End", usr.birthday) as age
	   , AGE_IN_YEARS(rnt."End"
	   		, case when MONTH(st.LicenseSetDate) = 1 and DAY(st.LicenseSetDate) = 1 THEN
	   			st.LicenseSetDate+(strt.LicenseStartDate-TO_DATE(YEAR(strt.LicenseStartDate)||'-01-01', 'YYYY-MM-DD'))
	   				ELSE st.LicenseSetDate END) as driving_experience
--	   , AGE_IN_YEARS(rnt."End", lsd.LicenseSetDate) as driving_experience
	   , hour(COALESCE(rnt."End",c1.accident_timestamp))
	   , SUM(case when c1.guilty = 'Виновен' then 1 else 0 end) as guilty
	   , SUM(case when c1.guilty = 'Не виновен' then 1 else 0 end) as not_guilty
	   , COUNT(c1.accident_timestamp) as all_accidents
	   , SUM(rnt.ride_time) as ride_time
from dma.delimobil_rent rnt
left join dma.delimobil_user usr on usr.user_id = rnt.user_id
left join CDDS.A_Rent_ScoringFlex scr on scr.Rent_id = rnt.rent_id
left join cdds.A_User_LicenseSetDate st on st.user_id = usr.user_id
left join cdds.A_User_LicenseStartDate strt on strt.user_id = usr.user_id
full outer join dma.accidents_1c c1 on c1.rent_id = rnt.rent_id
where COALESCE(rnt."Start",c1.accident_timestamp) >= '2020-08-01'
group by (case when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is not null then -2.0
       		   when COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) is null and rnt.rent_id is null then -1.0
       		   else COALESCE("pricing","pricingCoefficient")::NUMERIC(18,6) end)
	   , AGE_IN_YEARS(rnt."End", usr.birthday)
	   , AGE_IN_YEARS(rnt."End"
	   		, case when MONTH(st.LicenseSetDate) = 1 and DAY(st.LicenseSetDate) = 1 THEN
	   			st.LicenseSetDate+(strt.LicenseStartDate-TO_DATE(YEAR(strt.LicenseStartDate)||'-01-01', 'YYYY-MM-DD'))
	   				ELSE st.LicenseSetDate END)
	   , hour(COALESCE(rnt."End",c1.accident_timestamp))
--order by hour(COALESCE(rnt."End",c1.accident_timestamp)) asc