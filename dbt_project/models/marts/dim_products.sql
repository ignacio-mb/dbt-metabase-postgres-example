{{ config(materialized='table') }}

with products as (
    select * from {{ ref('stg_products') }}
),

categories as (
    select * from {{ ref('stg_categories') }}
),

parent_categories as (
    select
        category_id,
        category_name as parent_category_name
    from {{ ref('stg_categories') }}
),

suppliers as (
    select * from {{ ref('stg_suppliers') }}
),

product_performance as (
    select * from {{ ref('int_product_performance') }}
),

product_inventory as (
    select
        product_id,
        sum(quantity_available)  as total_available,
        sum(quantity_on_hand)    as total_on_hand,
        sum(quantity_reserved)   as total_reserved
    from {{ ref('stg_inventory') }}
    group by 1
),

final as (
    select
        p.product_id,
        p.product_name,
        p.price               as current_price,
        p.cost                as unit_cost,
        p.margin              as unit_margin,

        c.category_id,
        c.category_name,
        pc.parent_category_name,

        s.supplier_id,
        s.supplier_name,
        s.country             as supplier_country,
        s.is_active           as supplier_is_active,

        coalesce(pp.total_orders, 0)       as lifetime_orders,
        coalesce(pp.total_units_sold, 0)   as lifetime_units_sold,
        coalesce(pp.total_revenue, 0)      as lifetime_revenue,
        coalesce(pp.total_margin, 0)       as lifetime_margin,
        pp.avg_selling_price,
        coalesce(pp.completed_revenue, 0)  as completed_revenue,
        pp.return_rate,

        coalesce(pp.review_count, 0)       as review_count,
        pp.avg_rating,
        coalesce(pp.positive_reviews, 0)   as positive_reviews,
        coalesce(pp.negative_reviews, 0)   as negative_reviews,

        coalesce(inv.total_available, 0)   as inventory_available,
        coalesce(inv.total_on_hand, 0)     as inventory_on_hand,
        coalesce(inv.total_reserved, 0)    as inventory_reserved,

        case
            when coalesce(inv.total_available, 0) = 0 then 'out_of_stock'
            when coalesce(inv.total_available, 0) < 10 then 'low_stock'
            else 'in_stock'
        end as stock_status,

        case
            when pp.avg_rating >= 4.5 then 'excellent'
            when pp.avg_rating >= 4.0 then 'good'
            when pp.avg_rating >= 3.0 then 'average'
            when pp.avg_rating is not null then 'poor'
            else 'no_reviews'
        end as rating_tier,

        p.created_at as product_created_at
    from products p
    left join categories c                on p.category_id = c.category_id
    left join parent_categories pc        on c.parent_category_id = pc.category_id
    left join suppliers s                 on p.supplier_id = s.supplier_id
    left join product_performance pp      on p.product_id  = pp.product_id
    left join product_inventory inv       on p.product_id  = inv.product_id
)

select * from final
