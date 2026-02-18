{{ config(materialized='table', tags=['daily', 'reporting']) }}

with orders as (
    select * from {{ ref('fct_orders') }}
    where order_status = 'completed'
)

select
    date_trunc('month', order_date)::date as month,
    count(order_id)                       as total_orders,
    count(distinct customer_id)           as unique_customers,
    sum(order_total)                      as gross_revenue,
    sum(amount_paid)                      as collected_revenue,
    sum(gross_margin)                     as total_margin,
    avg(order_total)                      as avg_order_value,
    sum(total_quantity)                   as items_sold,
    {{ safe_divide('sum(gross_margin)', 'nullif(sum(order_total), 0)') }} as margin_pct
from orders
group by 1
order by 1
