with order_items as (
    select * from {{ ref('int_order_items_enriched') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

reviews as (
    select * from {{ ref('stg_reviews') }}
),

inventory as (
    select * from {{ ref('stg_inventory') }}
),

order_items_with_status as (
    select
        oi.*,
        o.order_status,
        o.order_date
    from order_items oi
    inner join orders o on oi.order_id = o.order_id
),

product_sales as (
    select
        product_id,
        product_name,
        category_name,
        count(distinct order_id)          as total_orders,
        sum(quantity)                      as total_units_sold,
        sum(line_total)                    as total_revenue,
        sum(line_cost)                     as total_cost,
        sum(line_margin)                   as total_margin,
        avg(unit_price)                    as avg_selling_price,
        sum(case when order_status = 'completed' then line_total else 0 end) as completed_revenue,
        sum(case when price_type = 'discounted' then line_total else 0 end)  as discounted_revenue,
        {{ safe_divide(
            "sum(case when order_status = 'returned' then quantity else 0 end)",
            "nullif(sum(quantity), 0)"
        ) }} as return_rate
    from order_items_with_status
    group by 1, 2, 3
),

product_reviews as (
    select
        product_id,
        count(*)                                            as review_count,
        avg(rating)                                         as avg_rating,
        sum(case when rating >= 4 then 1 else 0 end)       as positive_reviews,
        sum(case when rating <= 2 then 1 else 0 end)       as negative_reviews,
        sum(case when is_verified_purchase then 1 else 0 end) as verified_reviews
    from reviews
    group by 1
),

product_inventory as (
    select
        product_id,
        sum(quantity_available)  as total_available,
        sum(quantity_reserved)   as total_reserved,
        bool_or(is_below_reorder_point) as needs_reorder
    from inventory
    group by 1
),

final as (
    select
        ps.product_id,
        ps.product_name,
        ps.category_name,
        ps.total_orders,
        ps.total_units_sold,
        ps.total_revenue,
        ps.total_cost,
        ps.total_margin,
        ps.avg_selling_price,
        ps.completed_revenue,
        ps.discounted_revenue,
        ps.return_rate,
        coalesce(pr.review_count, 0)       as review_count,
        pr.avg_rating,
        coalesce(pr.positive_reviews, 0)   as positive_reviews,
        coalesce(pr.negative_reviews, 0)   as negative_reviews,
        coalesce(pr.verified_reviews, 0)   as verified_reviews,
        coalesce(pi.total_available, 0)    as inventory_available,
        coalesce(pi.total_reserved, 0)     as inventory_reserved,
        coalesce(pi.needs_reorder, false)  as needs_reorder
    from product_sales ps
    left join product_reviews pr   on ps.product_id = pr.product_id
    left join product_inventory pi on ps.product_id = pi.product_id
)

select * from final
