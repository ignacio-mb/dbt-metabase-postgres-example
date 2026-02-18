with source as (
    select * from {{ source('raw', 'customers') }}
),

renamed as (
    select
        id          as customer_id,
        first_name,
        last_name,
        first_name || ' ' || last_name as full_name,
        email,
        country,
        created_at
    from source
)

select * from renamed
