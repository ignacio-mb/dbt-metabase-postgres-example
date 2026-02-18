{{ config(materialized='table', tags=['daily', 'reporting']) }}

with dates as (
    select date_key from {{ ref('dim_dates') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
    where order_status = 'completed'
),

daily_orders as (
    select
        order_date,
        count(order_id)            as orders_count,
        count(distinct customer_id) as unique_customers,
        sum(order_total)            as gross_revenue,
        sum(amount_paid)            as collected_revenue,
        sum(gross_margin)           as gross_margin,
        sum(total_quantity)         as items_sold,
        avg(order_total)            as avg_order_value
    from orders
    group by 1
),

final as (
    select
        d.date_key                                  as sale_date,
        coalesce(da.orders_count, 0)                as orders_count,
        coalesce(da.unique_customers, 0)            as unique_customers,
        coalesce(da.gross_revenue, 0)               as gross_revenue,
        coalesce(da.collected_revenue, 0)            as collected_revenue,
        coalesce(da.gross_margin, 0)                as gross_margin,
        coalesce(da.items_sold, 0)                  as items_sold,
        coalesce(da.avg_order_value, 0)             as avg_order_value,

        -- rolling 7-day metrics
        sum(coalesce(da.gross_revenue, 0)) over (
            order by d.date_key
            rows between 6 preceding and current row
        ) as rolling_7d_revenue,

        avg(coalesce(da.orders_count, 0)::numeric) over (
            order by d.date_key
            rows between 6 preceding and current row
        ) as rolling_7d_avg_orders,

        -- cumulative metrics
        sum(coalesce(da.gross_revenue, 0)) over (
            order by d.date_key
        ) as cumulative_revenue

    from dates d
    left join daily_orders da on d.date_key = da.order_date
)

select * from final
