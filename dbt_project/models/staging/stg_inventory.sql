with source as (
    select * from {{ source('raw', 'inventory') }}
),

renamed as (
    select
        id                                          as inventory_id,
        product_id,
        warehouse_location,
        quantity_on_hand,
        quantity_reserved,
        quantity_on_hand - quantity_reserved         as quantity_available,
        reorder_point,
        quantity_on_hand <= reorder_point            as is_below_reorder_point,
        last_restocked_at,
        updated_at
    from source
)

select * from renamed
