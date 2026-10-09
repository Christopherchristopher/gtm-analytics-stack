-- Monthly pipeline creation and outcomes by source channel, for trend charts.
select
    date_trunc(created_date, month)                              as created_month,
    source_channel,
    count(*)                                                     as deals_created,
    sum(amount_gbp)                                              as pipeline_created_gbp,
    sum(case when is_won then 1 else 0 end)                      as deals_won,
    sum(case when is_won then amount_gbp else 0 end)             as won_gbp,
    sum(case when is_closed then 1 else 0 end)                   as deals_closed
from {{ ref('stg_deals') }}
group by created_month, source_channel
order by created_month, source_channel
