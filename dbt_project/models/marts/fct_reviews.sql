{{ config(materialized='table') }}

with reviews as (
    select * from {{ ref('stg_reviews') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

categories as (
    select * from {{ ref('stg_categories') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

customer_product_orders as (
    select distinct
        o.customer_id,
        oi.product_id,
        min(o.order_date) as first_purchase_date
    from {{ ref('stg_orders') }} o
    inner join {{ ref('stg_order_items') }} oi on o.order_id = oi.order_id
    group by 1, 2
),

final as (
    select
        r.review_id,
        r.product_id,
        p.product_name,
        c.category_name as product_category,
        r.customer_id,
        cu.full_name    as customer_name,
        r.rating,
        r.review_title,
        r.review_body,
        r.is_verified_purchase,
        r.reviewed_at,

        case
            when r.rating >= 4 then 'positive'
            when r.rating = 3  then 'neutral'
            else 'negative'
        end as sentiment,

        case
            when r.rating = 5           then 'promoter'
            when r.rating in (4, 3)     then 'passive'
            else 'detractor'
        end as nps_category,

        length(r.review_body) as review_length,

        case
            when length(r.review_body) > 500 then 'detailed'
            when length(r.review_body) > 100 then 'moderate'
            else 'brief'
        end as review_depth,

        cpo.first_purchase_date,
        case
            when cpo.first_purchase_date is not null
            then {{ days_between('cpo.first_purchase_date', 'r.reviewed_at') }}
        end as days_since_purchase

    from reviews r
    left join products p                  on r.product_id  = p.product_id
    left join categories c                on p.category_id = c.category_id
    left join customers cu                on r.customer_id = cu.customer_id
    left join customer_product_orders cpo
        on  r.customer_id = cpo.customer_id
        and r.product_id  = cpo.product_id
)

select * from final
