-- Open pipeline snapshot: what is in each stage right now.
with open_deals as (
    select d.*, h.stage_order
    from {{ ref('stg_deals') }} d
    join {{ ref('stg_stage_history') }} h
      on h.deal_id = d.deal_id and h.stage = d.stage
    where not d.is_closed
)

select
    stage,
    stage_order,
    count(*)                    as open_deals,
    sum(amount_gbp)             as open_pipeline_gbp,
    round(avg(amount_gbp), 0)   as avg_deal_size_gbp,
    round(avg(age_days), 1)     as avg_age_days
from open_deals
group by stage, stage_order
order by stage_order
