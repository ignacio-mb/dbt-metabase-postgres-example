with source as (
    select * from {{ source('raw', 'reviews') }}
),

renamed as (
    select
        id                    as review_id,
        product_id,
        customer_id,
        rating,
        title                 as review_title,
        body                  as review_body,
        is_verified_purchase,
        created_at            as reviewed_at
    from source
)

select * from renamed
