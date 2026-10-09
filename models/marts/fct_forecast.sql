-- Weighted pipeline forecast, one row per open deal.
-- weighted_amount = deal value x historical win rate from the deal's current stage.
-- Group by expected_close_quarter in the dashboard for the quarterly forecast.
select
    d.deal_id,
    d.company_name,
    d.owner,
    d.segment,
    d.source_channel,
    d.stage,
    d.amount_gbp,
    d.age_days,
    d.expected_close_date,
    format_date('%Y-Q%Q', d.expected_close_date)          as expected_close_quarter,
    c.win_rate_from_stage,
    round(d.amount_gbp * c.win_rate_from_stage, 0)        as weighted_amount_gbp
from {{ ref('stg_deals') }} d
join {{ ref('fct_stage_conversion') }} c on c.stage = d.stage
where not d.is_closed
