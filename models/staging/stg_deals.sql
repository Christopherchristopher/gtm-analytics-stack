-- One row per deal, cleaned and typed, with helper flags.
select
    deal_id,
    company_name,
    industry,
    segment,
    owner,
    cast(amount_gbp as numeric)                         as amount_gbp,
    stage,
    stage in ('Closed Won', 'Closed Lost')              as is_closed,
    stage = 'Closed Won'                                as is_won,
    source_channel,
    cast(created_date as date)                          as created_date,
    cast(expected_close_date as date)                   as expected_close_date,
    cast(close_date as date)                            as close_date,
    date_diff(
        coalesce(cast(close_date as date), date('{{ var("as_of_date") }}')),
        cast(created_date as date),
        day
    )                                                   as age_days
from {{ ref('raw_deals') }}
