-- Channel attribution under three models:
--   first touch: all credit to the channel that started the journey
--   last touch:  all credit to the final touch before the deal was created
--   linear:      credit split equally across every touch
-- "pipeline" = value of all deals created; "won" = value of Closed Won deals.
with credited as (
    select
        t.channel,
        d.deal_id,
        d.amount_gbp,
        d.is_won,
        case when t.touch_number = 1 then 1.0 else 0.0 end      as first_credit,
        case when t.touch_number_desc = 1 then 1.0 else 0.0 end as last_credit,
        1.0 / t.touches_on_deal                                 as linear_credit
    from {{ ref('stg_touches') }} t
    join {{ ref('stg_deals') }} d on d.deal_id = t.deal_id
)

select
    channel,
    count(distinct deal_id)                                                as deals_touched,
    round(sum(first_credit), 1)                                            as first_touch_deals,
    round(sum(first_credit * amount_gbp), 0)                               as first_touch_pipeline_gbp,
    round(sum(case when is_won then first_credit * amount_gbp else 0 end), 0)
                                                                           as first_touch_won_gbp,
    round(sum(last_credit * amount_gbp), 0)                                as last_touch_pipeline_gbp,
    round(sum(case when is_won then last_credit * amount_gbp else 0 end), 0)
                                                                           as last_touch_won_gbp,
    round(sum(linear_credit * amount_gbp), 0)                              as linear_pipeline_gbp,
    round(sum(case when is_won then linear_credit * amount_gbp else 0 end), 0)
                                                                           as linear_won_gbp
from credited
group by channel
order by linear_won_gbp desc
