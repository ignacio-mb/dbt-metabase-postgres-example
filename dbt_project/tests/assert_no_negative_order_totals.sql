-- No order should have a negative total after aggregation
select
    order_id,
    order_total
from {{ ref('fct_orders') }}
where order_total < 0
