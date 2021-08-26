-- QUERY
select COUNT(*), COUNT(DISTINCT(slct.user_ext)) from
(with pre_score as
	(select user_id, DrivingStyle_preScore, ROW_NUMBER() over (partition by user_id order by to_dtime desc) as rn
	from dma.delimobil_user_coefficient_pricing
	where DrivingStyle_delimobilScore is not NULL),
	penalty_rate as
	(select user_id, 4*penalty_rate_rude+ 2*penalty_rate_usual + penalty_rate_light as penalty_rate,
	ROW_NUMBER() OVER (PARTITION BY user_id order by report_date desc) as rn
	from dma.delimobil_user_metrics)
select usr.user_id, pre_score.DrivingStyle_preScore, penalty_rate.penalty_rate, usr.*
from dma.delimobil_user usr
left join pre_score on pre_score.user_id = usr.user_id
left join penalty_rate on penalty_rate.user_id = usr.user_id
where usr.activation_dtime is not null
	  and pre_score.DrivingStyle_preScore >= 0.4
	  and penalty_rate.penalty_rate <= 0.7
	  and pre_score.rn = 1
	  and penalty_rate.rn = 1
	  and usr.is_deleted = FALSE
	  and usr.status_ext = 2) slct