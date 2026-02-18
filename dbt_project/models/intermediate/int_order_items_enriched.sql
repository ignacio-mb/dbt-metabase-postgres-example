with order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

categories as (
    select * from {{ ref('stg_categories') }}
),

enriched as (
    select
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        p.product_name,
        p.category_id,
        c.category_name,
        c.parent_category_id,
        p.supplier_id,
        oi.quantity,
        oi.unit_price,
        p.price    as current_price,
        p.cost     as unit_cost,
        oi.line_total,
        oi.quantity * p.cost as line_cost,
        oi.line_total - (oi.quantity * p.cost) as line_margin,
        case
            when oi.unit_price < p.price then 'discounted'
            when oi.unit_price = p.price then 'full_price'
            else 'premium'
        end as price_type
    from order_items oi
    left join products p   on oi.product_id = p.product_id
    left join categories c on p.category_id = c.category_id
)

select * from enriched
