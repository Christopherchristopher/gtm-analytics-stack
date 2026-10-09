-- One row per marketing/sales touch, numbered in time order within each deal.
select
    touch_id,
    deal_id,
    channel,
    cast(touch_date as date) as touch_date,
    row_number() over (partition by deal_id order by touch_date, touch_id)      as touch_number,
    row_number() over (partition by deal_id order by touch_date desc, touch_id desc) as touch_number_desc,
    count(*) over (partition by deal_id)                                       as touches_on_deal
from {{ ref('raw_touches') }}
