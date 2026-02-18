with source as (
    select * from {{ source('raw', 'payments') }}
),

renamed as (
    select
        id      as payment_id,
        order_id,
        amount,
        method  as payment_method,
        status  as payment_status,
        created_at
    from source
)

select * from renamed
