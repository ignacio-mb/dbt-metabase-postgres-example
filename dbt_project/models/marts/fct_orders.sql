{{ config(materialized='table') }}

with customer_orders as (
    select * from {{ ref('int_customer_orders') }}
),

payments as (
    select
        order_id,
        max(payment_method) as payment_method,
        max(payment_status) as payment_status
    from {{ ref('stg_payments') }}
    group by 1
),

payment_methods as (
    select * from {{ ref('payment_methods') }}
),

order_items_enriched as (
    select
        order_id,
        count(distinct category_name) as category_count,
        count(distinct case when price_type = 'discounted' then order_item_id end) as discounted_items,
        sum(line_cost)   as total_cost,
        sum(line_margin) as gross_margin
    from {{ ref('int_order_items_enriched') }}
    group by 1
)

select
    co.order_id,
    co.customer_id,
    co.order_status,
    co.order_date,
    co.shipping_date,
    co.days_to_ship,
    co.item_count,
    co.total_quantity,
    co.order_total,
    co.amount_paid,
    co.amount_outstanding,

    p.payment_method,
    pm.payment_method_label,
    pm.is_digital         as is_digital_payment,
    p.payment_status,

    coalesce(oie.category_count, 0)    as category_count,
    coalesce(oie.discounted_items, 0)  as discounted_items,
    coalesce(oie.total_cost, 0)        as total_cost,
    coalesce(oie.gross_margin, 0)      as gross_margin,
    {{ safe_divide('oie.gross_margin', 'nullif(co.order_total, 0)') }} as margin_pct,

    co.created_at
from customer_orders co
left join payments p                on co.order_id = p.order_id
left join payment_methods pm        on p.payment_method = pm.payment_method
left join order_items_enriched oie  on co.order_id = oie.order_id
where co.order_total >= {{ var('min_order_amount') }}
