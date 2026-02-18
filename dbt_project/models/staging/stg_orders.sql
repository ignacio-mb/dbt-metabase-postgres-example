with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed as (
    select
        id            as order_id,
        customer_id,
        status        as order_status,
        order_date,
        shipping_date,
        case
            when shipping_date is not null
            then {{ days_between('order_date', 'shipping_date') }}
        end as days_to_ship,
        created_at
    from source
)

select * from renamed
