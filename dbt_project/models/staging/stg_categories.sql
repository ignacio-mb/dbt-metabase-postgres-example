with source as (
    select * from {{ source('raw', 'categories') }}
),

renamed as (
    select
        id                  as category_id,
        name                as category_name,
        parent_category_id,
        description         as category_description,
        created_at
    from source
)

select * from renamed
