with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

order_totals as (
    select
        order_id,
        count(*)        as item_count,
        sum(quantity)    as total_quantity,
        sum(line_total)  as order_total
    from order_items
    group by 1
),

successful_payments as (
    select
        order_id,
        sum(amount)  as amount_paid,
        count(*)     as payment_count
    from payments
    where payment_status = 'success'
    group by 1
),

customer_orders as (
    select
        o.customer_id,
        o.order_id,
        o.order_status,
        o.order_date,
        o.shipping_date,
        o.days_to_ship,
        coalesce(ot.item_count, 0)      as item_count,
        coalesce(ot.total_quantity, 0)   as total_quantity,
        coalesce(ot.order_total, 0)      as order_total,
        coalesce(sp.amount_paid, 0)      as amount_paid,
        coalesce(ot.order_total, 0)
            - coalesce(sp.amount_paid, 0) as amount_outstanding,
        o.created_at
    from orders o
    left join order_totals ot         on o.order_id = ot.order_id
    left join successful_payments sp  on o.order_id = sp.order_id
)

select * from customer_orders
