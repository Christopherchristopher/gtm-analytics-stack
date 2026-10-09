-- Funnel conversion by stage, using closed deals only so open deals
-- don't drag the rates down before they've had a chance to finish.
--   stage_to_next_rate:  of closed deals that reached this stage, share that went further
--   win_rate_from_stage: of closed deals that reached this stage, share that were won
-- win_rate_from_stage drives the weighted forecast.
with closed as (
    select deal_id, is_won from {{ ref('stg_deals') }} where is_closed
),

reached as (
    select
        h.deal_id,
        c.is_won,
        h.stage,
        h.stage_order,
        max(h.stage_order) over (partition by h.deal_id) as furthest_order
    from {{ ref('stg_stage_history') }} h
    join closed c on c.deal_id = h.deal_id
    where h.stage_order <= 5
)

select
    stage,
    stage_order,
    count(*)                                                    as closed_deals_reached,
    sum(case when furthest_order > stage_order or is_won then 1 else 0 end)
                                                                as advanced,
    sum(case when is_won then 1 else 0 end)                     as won,
    round(safe_divide(
        sum(case when furthest_order > stage_order or is_won then 1 else 0 end),
        count(*)), 3)                                           as stage_to_next_rate,
    round(safe_divide(sum(case when is_won then 1 else 0 end), count(*)), 3)
                                                                as win_rate_from_stage
from reached
group by stage, stage_order
order by stage_order
