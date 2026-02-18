with source as (
    select * from {{ source('raw', 'suppliers') }}
),

renamed as (
    select
        id              as supplier_id,
        name            as supplier_name,
        contact_email,
        country,
        is_active,
        created_at
    from source
)

select * from renamed
