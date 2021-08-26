with pre_t as  (
  select tt.rent_id, tt.is_24h_rent, tt."Type", tt.Cost, tt."Start", tt."End", tt.bonus_amount
      , r24t.Start24h, r24t.End24h
    from (
      select d.rent_id, d.is_24h_rent, rp."Type", rp.Cost, rp."Start", rp."End",  d.bonus_amount
      from dma.delimobil_rent d left join dma.rent_period rp on d.rent_id = rp.rent_id
      where true 
      and date_trunc('month',d."End")::date = '2020-09-01'
      --
      UNION ALL
      select d.rent_id, d.is_24h_rent, 'advance' as "Type", d.advance_24h as Cost, d."Start", null as "End", d.bonus_amount 
      from dma.delimobil_rent d 
      where true 
      and date_trunc('month',d."End")::date = '2020-09-01'
      and d.is_24h_rent 
      --
      UNION ALL
      select d.rent_id
        , d.is_24h_rent
        , 'overmileage' as "Type"
        , greatest(coalesce(d.bill_amount + d.bonus_amount - d.advance_24h - rp.sumcost, 0), 0) as Cost
        , greatest(rp.maxend, d."End") as "Start",  null as "End"
        , d.bonus_amount 
      from dma.delimobil_rent d 
      left join 
        (select rent_id, sum(Cost) as sumcost, max("End") as maxend 
          from dma.rent_period group by 1) rp on d.rent_id = rp.rent_id
      where true 
        and d.is_24h_rent
        and date_trunc('month',d."End")::date = '2020-09-01'
         ) tt 
    left join  
      ( select d.rent_id, min(rp."Start") as Start24H, TIMESTAMPADD('hour', 24, min(rp."Start")) as End24H
        from dma.delimobil_rent d left join dma.rent_period rp on d.rent_id = rp.rent_id
        where d.is_24h_rent and rp."Type" not in ('reserved', 'rate', 'rated')
        group by 1) r24t on tt.rent_id = r24t.rent_id
)
,  t as (
select p.rent_id
    , p.is_24h_rent
    , p."Type"
    , sum(p.Cost) over (partition by p.rent_id order by p."Start", p."Type") as cum_sum
    , p.Cost 
    , p.bonus_amount
    , (case when p.End24h is not null and p.End24h > p."End" and p."Type" in ('park', 'taken')
        then extract('epoch' from p."End" - p."Start")/60 
        when p.End24h is not null and (p.End24h between p."Start" and p."End") and p."Type" in ('park', 'taken')
        then extract('epoch' from p.End24h - p."Start")/60
        when p.End24h is not null and (p.End24h < p."Start") and p."Type" in ('park', 'taken')
        then null
        else null end) as in24htime
    , (case when p.End24h is not null and p.End24h > p."End" and p."Type" in ('park', 'taken')
        then null 
        when p.End24h is not null and (p.End24h between p."Start" and p."End") and p."Type" in ('park', 'taken')
        then extract('epoch' from p."End"- p.End24h)/60
        when p.End24h is not null and (p.End24h < p."Start") and p."Type" in ('park', 'taken')
        then extract('epoch' from p."End" - p."Start")/60
        else null end) as overtime
from pre_t p
) 
, m_statuses as  --- statuses for counting rent\minutes in reports
( 
select rent_id, max(case when is_24h_rent and transfer_type in (31, 21) and close_period_status = 'error' 
               then null
               when amount_returned_12 < 0 
                and return_dtime::date <= last_day("End") + 5
                and transfer_type in (31,21)
               then null
                 when amount_returned_12 < 0 
                and return_dtime::date <= last_day("End") + 5
               then -1 
                 when transfer_type = 70 then 2
            else decode(close_period_status, 'error', -1, 'refunded', 1, 'canceled', 1, 'approved', 1, 'success', 1, null, 2, 'waiting', 3) 
            end) as close_period_status
from dma.delimobil_rent_finance
where date_trunc('month',"End")::date = '2020-09-01'
and transfer_type <> 80
group by 1
)
, b_statuses as
(
select rent_id, transfer_type
      , case when is_24h_rent and transfer_type in (21,31) and close_period_status = 'error' then 0 
           when amount_returned_12 < 0 
            and return_dtime::date <= last_day("End")+ 5
           then -1 
           when transfer_type = 70 then 2
else decode(close_period_status, 'refunded', -1, 'canceled', -1, 'approved', -1, 'success', 1, 'error', -1, 'waiting', 3, null, 2)
        end as close_period_status
      , bill_amount
      , bonus_amount
from  dma.delimobil_rent_finance
where date_trunc('month',"End")::date = '2020-09-01'
--and transfer_type <> 80
)
, b_statuses_aggr as
(
select rent_id
  , sum(case when close_period_status < 0 then bill_amount end) as bill_error 
  , sum(case when close_period_status  = 3 then bill_amount end) as bill_waiting
  , sum(case when close_period_status in (1,2) then bill_amount end) as bill_success
  , sum(case when close_period_status < 0 then bonus_amount end) as bonus_error 
  , sum(case when close_period_status  = 3 then bonus_amount end) as bonus_waiting
  , sum(case when close_period_status in (1,2) then bonus_amount end) as bonus_success
from  b_statuses
group by 1
)
, x as (
select date_trunc('month', dr."End")::date as month_
  , trim(to_char(date_trunc('month', dr."End"), 'Month'))as month_desc_
  , dr.owner_name
  --, case when dr.owner_name in ('Delimobil', 'Anytime') then false else true end as is_pool
  --, dr.rent_ext
  , (case when dr.type_ext = 1 and cr.rent_id is null then 'b2c'
      when dr.type_ext = 10 and (cr.B2bCompany_id  not in (271750001, 12500002, 74500001, 1, 258250001, 265500001, 345250001, 285750001)  
                    or cr.B2bCompany_id is null)
                then 'b2b' 
      when cr.B2bCompany_id in (12500002, 74500001, 1)
                then 'smm b2b' 
      when cr.B2bCompany_id in (271750001, 258250001, 265500001, 345250001, 285750001)  
                then 'smm delivery' 
      else 'smm' end) as type_ext
  , dr.is_24h_rent
  , dr.rent_region_en
  , trim(lower(dr.brand))||' '||trim(lower(dr.model)) as model
  , decode(ms.close_period_status, -1, 'error', 1, 'success', 2, 'success', 3, 'waiting', null, 'success') as status_rm
  , count(*) as total_reservations
  , count(case when dr.cost>0 then dr.rent_id end) as total_costed_reservations 
  , count(case when dr.is_ride then dr.rent_id end) as total_rides
  , sum(coalesce(bs.bill_error,0)) as bill_error 
  , sum(coalesce(bs.bill_waiting,0)) as bill_waiting
  , sum(coalesce(bs.bill_success,0))+ sum(coalesce(dr.bill_package, 0)) as bill_success
  , sum(coalesce(bs.bonus_error,0)) as bonus_error
  , sum(coalesce(bs.bonus_waiting,0)) as bonus_waiting
  , sum(coalesce(bs.bonus_success,0)) + sum(coalesce(dr.bonus_package, 0)) as bonus_success
  , sum(coalesce(dr.reserved_time_free,0)) as unpaid_reserved_time
  , sum(coalesce(dr.reserved_time_paid,0)) as paid_reserved_minutes
  , sum(dr.reserved_time) as total_reserved_time
  , sum(coalesce(dr.rated_time_free,0)) as unpaid_rated_time
  , sum(coalesce(dr.rated_time_paid,0)) as paid_rated_time
  , sum(case when not dr.is_24h_rent then dr.ride_time 
         when dr.is_24h_rent then x.overtime_ride_time 
         else 0 end) as paid_ride_time
  , sum(case when dr.is_24h_rent then x.advanced_ride_time
         else 0 end) as advanced_ride_time
  , sum(case when not dr.is_24h_rent then dr.park_time
         when dr.is_24h_rent then x.overtime_park_time
         else 0 end) as paid_park_time
  , sum(case when dr.is_24h_rent then x.advanced_park_time
         else 0 end) as advaced_park_time
from dma.delimobil_rent dr 
left join b_statuses_aggr bs on dr.rent_id = bs.rent_id
left join m_statuses ms on dr.rent_id = ms.rent_id
left join CDDS.T_Vehicle_Owner vo on dr.vehicle_id = vo.Vehicle_id
left join dma.delimobil_rent_tariff tr on dr.rent_id = tr.rent_id
left join dma.delimobil_corporate_rent cr on cr.rent_id = dr.rent_id
left join 
  (select t.rent_id
      , sum(case when t."Type" = 'park' then t.in24htime else 0 end) as advanced_park_time
      , sum(case when t."Type" = 'taken' then t.in24htime else 0 end) as advanced_ride_time
      , sum(case when t."Type" = 'park' then t.overtime else 0 end) as overtime_park_time
      , sum(case when t."Type" = 'taken' then t.overtime else 0 end) as overtime_ride_time
	  , sum(case when t."Type" = 'advance' then t.cost else 0 end) as advanced_cost
      , sum(case when t."Type" = 'overmileage' then t.cost else 0 end) as overmileage_cost
   from t 
   group by 1) x  on dr.rent_id = x.rent_id
where true 
--and dr.owner_name in ('Anytime', 'Delimobil')
and date_trunc('month',dr."End")::date  = '2020-09-01'
and not dr.is_fix
group by 1,2,3,4,5,6,7,8
order by 1,3,4
)
select * from x

select *
from 