-- Every stage each deal entered, with a numeric order for the funnel.
select
    deal_id,
    stage,
    cast(entered_date as date) as entered_date,
    case stage
        when 'Prospecting' then 1
        when 'Discovery'   then 2
        when 'Demo'        then 3
        when 'Proposal'    then 4
        when 'Negotiation' then 5
        when 'Closed Won'  then 6
        when 'Closed Lost' then 6
    end as stage_order
from {{ ref('raw_stage_history') }}
