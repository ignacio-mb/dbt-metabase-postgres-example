with source as (
    select * from {{ source('raw', 'products') }}
),

renamed as (
    select
        id            as product_id,
        name          as product_name,
        category_id,
        supplier_id,
        price,
        cost,
        price - cost  as margin,
        created_at
    from source
)

select * from renamed
