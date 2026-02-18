{{ config(materialized='table') }}

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

customer_metrics as (
    select
        customer_id,
        count(order_id)                        as lifetime_orders,
        coalesce(sum(order_total), 0)          as lifetime_revenue,
        coalesce(sum(gross_margin), 0)         as lifetime_margin,
        coalesce(avg(order_total), 0)          as avg_order_value,
        min(order_date)                        as first_order_date,
        max(order_date)                        as last_order_date,
        sum(total_quantity)                    as lifetime_items,
        count(distinct date_trunc('month', order_date)) as active_months
    from orders
    group by 1
),

final as (
    select
        c.customer_id,
        c.full_name,
        c.email,
        c.country,
        c.created_at                           as customer_since,

        coalesce(m.lifetime_orders, 0)         as lifetime_orders,
        coalesce(m.lifetime_revenue, 0)        as lifetime_revenue,
        coalesce(m.lifetime_margin, 0)         as lifetime_margin,
        coalesce(m.avg_order_value, 0)         as avg_order_value,
        coalesce(m.lifetime_items, 0)          as lifetime_items,
        coalesce(m.active_months, 0)           as active_months,
        m.first_order_date,
        m.last_order_date,

        case
            when m.lifetime_orders is null or m.lifetime_orders = 0 then 'prospect'
            when m.lifetime_orders = 1 then 'new'
            when m.lifetime_orders between 2 and 3 then 'returning'
            else 'loyal'
        end as customer_segment,

        case
            when m.lifetime_revenue >= 2000 then 'high'
            when m.lifetime_revenue >= 500  then 'medium'
            when m.lifetime_revenue > 0     then 'low'
            else 'none'
        end as revenue_tier,

        case
            when m.last_order_date is null then null
            else current_date - m.last_order_date
        end as days_since_last_order

    from customers c
    left join customer_metrics m on c.customer_id = m.customer_id
)

select * from final
